module PID_core #(parameter ADC_BITWIDTH=8, REG_BITWIDTH=5, FRAC_BITWIDTH=30)(
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

localparam RESULT_BITWIDTH = ADC_BITWIDTH + 2 * FRAC_BITWIDTH + 5; //4x Additionen + Signed
localparam signed [RESULT_BITWIDTH-1:0]MAX_VALUE = (2 ** (ADC_BITWIDTH + 2 * FRAC_BITWIDTH)) - 1;   //65535;  FRAC = 4
localparam signed [RESULT_BITWIDTH-1:0]MIN_VALUE = -(2 ** (ADC_BITWIDTH + 2 * FRAC_BITWIDTH)); 
localparam [RESULT_BITWIDTH-ADC_BITWIDTH-1:0] ZEROMASK = 0;

wire [RESULT_BITWIDTH-1:0] ADC_Val;
wire [RESULT_BITWIDTH-1:0] SET_Val;
wire signed [RESULT_BITWIDTH-1:0] frac_ADC_Val;
wire signed [RESULT_BITWIDTH-1:0] frac_SET_Val;
wire signed [RESULT_BITWIDTH-1:0] error_Val;
wire signed [RESULT_BITWIDTH-1:0] result_Val;
reg signed  [RESULT_BITWIDTH-1:0] out_Val[1:0];
reg signed  [RESULT_BITWIDTH-1:0] error_Val_sreg[1:0];

assign ADC_Val = {ZEROMASK, ADC_value_i};
assign SET_Val = {ZEROMASK, SET_value_i};
assign frac_ADC_Val = ADC_Val << FRAC_BITWIDTH;//{65'd_0, ADC_value_i} << FRAC_BITWIDTH ;//
assign frac_SET_Val = SET_Val << FRAC_BITWIDTH;//{65'd_0, SET_value_i} << FRAC_BITWIDTH ;//SET_value_i << FRAC_BITWIDTH;
assign error_Val = frac_SET_Val - frac_ADC_Val;

//assign out_Val_o = (out_Val[0] < 0)? (0-out_Val[0] [ADC_BITWIDTH + 2 * FRAC_BITWIDTH - 1 : 2 * FRAC_BITWIDTH]) : 0; //Only negative numbers -> 0 - out?
//assign result_Val = b2_reg_i * error_Val + b1_reg_i * error_Val_sreg[0] + b0_reg_i * error_Val_sreg[1] - a1_reg_i * (out_Val[0] / (2**(FRAC_BITWIDTH))) - a0_reg_i * (out_Val[1] / (2**(FRAC_BITWIDTH)));
assign result_Val = b2_reg_i * error_Val + b1_reg_i * error_Val_sreg[0] + b0_reg_i * error_Val_sreg[1] - a1_reg_i * (out_Val[0] >>> FRAC_BITWIDTH) - a0_reg_i * (out_Val[1] >>> FRAC_BITWIDTH);
assign out_Val_o = out_Val[0][ADC_BITWIDTH + 2*FRAC_BITWIDTH:2*FRAC_BITWIDTH];//[ADC_BITWIDTH:0]; //(out_Val[0] / (2**(2*FRAC_BITWIDTH)));



always @(posedge clk_i, rstn_i) begin

    if (!rstn_i) begin
        error_Val_sreg[0] <= 0;  
        error_Val_sreg[1] <= 0;    
        out_Val[0]        <= 0;
        out_Val[1]        <= 0;
    end else if(clk_en_PID_i) begin
        error_Val_sreg[0] <= error_Val;  
        error_Val_sreg[1] <= error_Val_sreg[0];
        out_Val[1]        <= out_Val[0];

        // if(-a1_reg_i * out_Val[0] - a0_reg_i * out_Val[1] + b2_reg_i * error_Val + b1_reg_i * error_Val_sreg[0] + b0_reg_i * error_Val_sreg[1] >= MAX_VALUE) begin
        //     out_Val[0] <= MAX_VALUE;
        // end else if(-a1_reg_i * out_Val[0] - a0_reg_i * out_Val[1] + b2_reg_i * error_Val + b1_reg_i * error_Val_sreg[0] + b0_reg_i * error_Val_sreg[1] <= MIN_VALUE) begin
        //     out_Val[0] <= MIN_VALUE;
        // end else begin
        //     out_Val[0] <= -a1_reg_i * out_Val[0] - a0_reg_i * out_Val[1] + b2_reg_i * error_Val + b1_reg_i * error_Val_sreg[0] + b0_reg_i * error_Val_sreg[1];
        // end

        // result_Val <= -a1_reg_i * out_Val[0] - a0_reg_i * out_Val[1] + b2_reg_i * error_Val + b1_reg_i * error_Val_sreg[0] + b0_reg_i * error_Val_sreg[1];

        if(result_Val >= MAX_VALUE) begin
            out_Val[0] <= MAX_VALUE;
        end else if(result_Val <= MIN_VALUE) begin
            out_Val[0] <= MIN_VALUE;
        end else begin
            out_Val[0] <= result_Val;
        end

        // if (2*out_Val[0] - out_Val[1] + b2_reg_i * error_Val + b1_reg_i * error_Val_sreg[0] + b0_reg_i * error_Val_sreg[1] <= MAX_VALUE && 2*out_Val[0] - out_Val[1] + b2_reg_i * error_Val + b1_reg_i * error_Val_sreg[0] + b0_reg_i * error_Val_sreg[1] >= MIN_VALUE) begin
        //     out_Val[0] <= 2*out_Val[0] - out_Val[1] + b2_reg_i * error_Val + b1_reg_i * error_Val_sreg[0] + b0_reg_i * error_Val_sreg[1]; 
        // end else begin
        //     out_Val[0] <= MAX_VALUE;
        // end
        
    end
end

endmodule


