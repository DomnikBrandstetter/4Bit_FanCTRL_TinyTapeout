module PID_core #(parameter ADC_BITWIDTH = 8, REG_BITWIDTH = 32, FRAC_BITWIDTH = 30, CLK_DIV_MULTIPLIER = 50)(
    input wire clk_i,
    input wire rstn_i,
    input wire clk_en_PID_i,
    input wire [ADC_BITWIDTH-1:0] ADC_value_i,
    input wire [ADC_BITWIDTH-1:0] SET_value_i,

    input wire signed [REG_BITWIDTH-1:0] a1_reg_i, 
    input wire signed [REG_BITWIDTH-1:0] a0_reg_i, 
    input wire signed [REG_BITWIDTH-1:0] b0_reg_i,
    input wire signed [REG_BITWIDTH-1:0] b1_reg_i,
    input wire signed [REG_BITWIDTH-1:0] b2_reg_i, 

    output wire signed [ADC_BITWIDTH:0] out_Val_o
);

localparam PID_STAGES_BITWIDTH = 3; //5 Multiplications -> 6 Stages

localparam MULTIPLIER_BITWIDTH = FRAC_BITWIDTH + ADC_BITWIDTH + 3; // #2 Add + Signed
localparam RESULT_BITWIDTH = 2*MULTIPLIER_BITWIDTH;//FRAC_BITWIDTH + ADC_BITWIDTH + REG_BITWIDTH + 6;   //+6 = 5 Add + Signed

localparam MAX_VAL_BITWIDTH =  2 * FRAC_BITWIDTH + ADC_BITWIDTH + 1;
localparam signed [RESULT_BITWIDTH-1:0]MAX_VALUE = (2 ** (MAX_VAL_BITWIDTH-1)) - 1;  
localparam signed [RESULT_BITWIDTH-1:0]MIN_VALUE = -(2 ** (MAX_VAL_BITWIDTH-1)); 
//localparam [MULTIPLIER_BITWIDTH-ADC_BITWIDTH-1:0]ZEROMASK = 0;
//localparam RESULT_BITWIDTH = ADC_BITWIDTH + 2 * FRAC_BITWIDTH + 5; //4x Additionen + Signed

reg [PID_STAGES_BITWIDTH-1:0] pipeStage;
wire MUL_Done_STRB;
wire signed[RESULT_BITWIDTH-1:0] MUL_out;
wire signed[MULTIPLIER_BITWIDTH-1:0] MUL_a;
wire signed[MULTIPLIER_BITWIDTH-1:0] MUL_b;

wire [MULTIPLIER_BITWIDTH-1:0] SET_Val;
wire [MULTIPLIER_BITWIDTH-1:0] ADC_Val;
wire signed [MULTIPLIER_BITWIDTH-1:0] frac_ADC_Val;
wire signed [MULTIPLIER_BITWIDTH-1:0] frac_SET_Val;
wire signed [MULTIPLIER_BITWIDTH-1:0] error_Val;
reg signed  [MULTIPLIER_BITWIDTH-1:0] error_Val_sreg[2:0];
reg signed  [RESULT_BITWIDTH-1:0] out_Val_sreg[1:0];
reg signed [RESULT_BITWIDTH-1:0] result_Val;

//localparam constantWithOnes = {RESULT_BITWIDTH{1'b1}};

reg MUL_Start_STRB;
reg MulResult_Flag;

BIT_Multiplier #(.N (MULTIPLIER_BITWIDTH), .CLK_DIV_MULTIPLIER(CLK_DIV_MULTIPLIER)) MUL (
    .clk_i (clk_i),
    .rstn_i (rstn_i),
    .MUL_Start_STRB_i (MUL_Start_STRB),
    .MUL_Done_STRB_o (MUL_Done_STRB),
    .a_i (MUL_a),
    .b_i (MUL_b),
    .out_o (MUL_out)
    );

assign ADC_Val = {{MULTIPLIER_BITWIDTH-ADC_BITWIDTH{1'b0}}, ADC_value_i};
assign frac_ADC_Val = ADC_Val <<< FRAC_BITWIDTH;
assign SET_Val = {{MULTIPLIER_BITWIDTH-ADC_BITWIDTH{1'b0}}, SET_value_i}; 
assign frac_SET_Val = SET_Val <<< FRAC_BITWIDTH;
assign error_Val = frac_SET_Val - frac_ADC_Val;

assign out_Val_o = out_Val_sreg[0][MAX_VAL_BITWIDTH-1:2*FRAC_BITWIDTH]; 

wire [MULTIPLIER_BITWIDTH-1:0] b2_coeff;
wire [MULTIPLIER_BITWIDTH-1:0] b1_coeff;
wire [MULTIPLIER_BITWIDTH-1:0] b0_coeff;
wire [MULTIPLIER_BITWIDTH-1:0] a1_coeff;
wire [MULTIPLIER_BITWIDTH-1:0] a0_coeff;

wire [RESULT_BITWIDTH-1:0] out_Val_shift_m1;
wire [RESULT_BITWIDTH-1:0] out_Val_shift_m2;

assign b2_coeff = {{{MULTIPLIER_BITWIDTH-REG_BITWIDTH{b2_reg_i[REG_BITWIDTH-1]}}}, b2_reg_i};
assign b1_coeff = {{{MULTIPLIER_BITWIDTH-REG_BITWIDTH{b1_reg_i[REG_BITWIDTH-1]}}}, b1_reg_i};
assign b0_coeff = {{{MULTIPLIER_BITWIDTH-REG_BITWIDTH{b0_reg_i[REG_BITWIDTH-1]}}}, b0_reg_i};
assign a1_coeff = {{{MULTIPLIER_BITWIDTH-REG_BITWIDTH{a1_reg_i[REG_BITWIDTH-1]}}}, a1_reg_i};
assign a0_coeff = {{{MULTIPLIER_BITWIDTH-REG_BITWIDTH{a0_reg_i[REG_BITWIDTH-1]}}}, a0_reg_i};

assign out_Val_shift_m1 = out_Val_sreg[0] >>> FRAC_BITWIDTH;
assign out_Val_shift_m2 = out_Val_sreg[1] >>> FRAC_BITWIDTH;  

assign MUL_a = get_Multiplier(pipeStage, b0_coeff, b1_coeff, b2_coeff, -a0_coeff, -a1_coeff);
assign MUL_b = get_Multiplier(pipeStage, error_Val_sreg[2], error_Val_sreg[1], error_Val_sreg[0], out_Val_shift_m2[MULTIPLIER_BITWIDTH-1:0], out_Val_shift_m1[MULTIPLIER_BITWIDTH-1:0]);
//assign MUL_a = get_Multiplier(pipeStage, b0_reg_i, b1_reg_i, b2_reg_i, -a0_reg_i, -a1_reg_i);
//assign MUL_b = get_Multiplier(pipeStage, error_Val_sreg[2], error_Val_sreg[1], error_Val_sreg[0], out_Val_sreg[1] >>> FRAC_BITWIDTH, out_Val_sreg[0] >>> FRAC_BITWIDTH);

always @(posedge clk_i) begin

    if (!rstn_i) begin
        error_Val_sreg[0] <= 0;  
        error_Val_sreg[1] <= 0;
        error_Val_sreg[2] <= 0;    
        out_Val_sreg[0]   <= 0;
        out_Val_sreg[1]   <= 0;
    end else if(clk_en_PID_i && pipeStage == 0) begin
        error_Val_sreg[0] <= error_Val;  
        error_Val_sreg[1] <= error_Val_sreg[0];
        error_Val_sreg[2] <= error_Val_sreg[1];
        out_Val_sreg[1]   <= out_Val_sreg[0];

        if(result_Val >= MAX_VALUE) begin
            out_Val_sreg[0] <= MAX_VALUE;
        end else if(result_Val <= MIN_VALUE) begin
            out_Val_sreg[0] <= MIN_VALUE;
        end else begin
            out_Val_sreg[0] <= result_Val;
        end
    end 
end

always @(posedge clk_i) begin

    if (!rstn_i) begin
        pipeStage  <= 0;
    end else if(pipeStage == 5 && MulResult_Flag) begin
        pipeStage <= 0;
    end else if(clk_en_PID_i && pipeStage != 5) begin
       pipeStage <= pipeStage + 1;
    end
end

always @(posedge clk_i) begin

    if (!rstn_i) begin
        result_Val <= 0;
        MUL_Start_STRB <= 0;
        MulResult_Flag <= 0;
    end else if(clk_en_PID_i) begin
        //result_Val <= (pipeStage == 0)? 0 : result_Val;
        MUL_Start_STRB <= 1;
        MulResult_Flag <= 0;
    end else if (!MulResult_Flag && MUL_Done_STRB && pipeStage == 1) begin
        result_Val <= MUL_out;
        MUL_Start_STRB <= 0;
        MulResult_Flag <= 1;
    end else if (!MulResult_Flag && MUL_Done_STRB && pipeStage != 1) begin
        result_Val <= result_Val + MUL_out;
        MUL_Start_STRB <= 0;
        MulResult_Flag <= 1;
    end else begin
        MUL_Start_STRB <= 0;
    end
end

function signed[MULTIPLIER_BITWIDTH-1:0] get_Multiplier; 
input [PID_STAGES_BITWIDTH-1:0] x;
input signed[MULTIPLIER_BITWIDTH-1:0] Multiplier_1, Multiplier_2, Multiplier_3, Multiplier_4, Multiplier_5;
    begin
        case(x)
            1 : begin 
                get_Multiplier = Multiplier_1;
            end 
            2 : begin 
               get_Multiplier = Multiplier_2;
            end 
            3 : begin 
                get_Multiplier = Multiplier_3;
            end 
            4 : begin 
                get_Multiplier = Multiplier_4;
            end 
            5 : begin 
                get_Multiplier = Multiplier_5;
            end 
            default : begin 
                get_Multiplier = 0;
                get_Multiplier = 0;
            end 
        endcase 
    end 
endfunction

endmodule



