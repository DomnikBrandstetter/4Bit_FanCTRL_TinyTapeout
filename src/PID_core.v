// Copyright 2023 Dominik Brandstetter
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE−2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

`include "MUL_ACC.v"

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

localparam PID_STAGES_BITWIDTH = 3;    // 5 multiplications -> 6 Stages
localparam ADDITIONAL_RESULT_BITS = 1; // required if the controller overshoots

//Calculate constants and Bitwidth (add +1 Bit for signed)
localparam MULTIPLIER_BITWIDTH = REG_BITWIDTH + ADC_BITWIDTH + 1; 
localparam RESULT_BITWIDTH = 2 * MULTIPLIER_BITWIDTH;
localparam MAX_VAL_BITWIDTH =  2 * FRAC_BITWIDTH + ADC_BITWIDTH;

//Maximum and minimum values for PID and output
localparam signed [RESULT_BITWIDTH-1:0]MAX_PID_VALUE = (2 ** (MAX_VAL_BITWIDTH + ADDITIONAL_RESULT_BITS)) - 1;  
localparam signed [RESULT_BITWIDTH-1:0]MIN_PID_VALUE = -(2 ** (MAX_VAL_BITWIDTH + ADDITIONAL_RESULT_BITS)) + 1; 
localparam signed [RESULT_BITWIDTH-1:0]MAX_OUT_VALUE = (2 ** (ADC_BITWIDTH)) - 1;  
localparam signed [RESULT_BITWIDTH-1:0]MIN_OUT_VALUE = -(2 ** (ADC_BITWIDTH)) + 1; 

reg  clk_en_PID_buffer;
reg  MUL_Start_STRB;
wire MUL_Done_STRB;
reg [PID_STAGES_BITWIDTH-1:0] pipeStage;
reg signed [ADC_BITWIDTH:0] out_Val;

reg signed  [MULTIPLIER_BITWIDTH-1:0] error_Val_sreg[2:0];
reg signed  [RESULT_BITWIDTH-1:0] out_Val_sreg[1:0];

wire [MULTIPLIER_BITWIDTH-1:0] SET_Val;
wire [MULTIPLIER_BITWIDTH-1:0] ADC_Val;
wire signed [MULTIPLIER_BITWIDTH-1:0] frac_ADC_Val;
wire signed [MULTIPLIER_BITWIDTH-1:0] frac_SET_Val;
wire signed [MULTIPLIER_BITWIDTH-1:0] error_Val;

wire signed [RESULT_BITWIDTH-1:0] result_Val;
wire signed [RESULT_BITWIDTH-1:0] MUL_acc;
wire signed [RESULT_BITWIDTH-1:0] MUL_a;
wire signed [RESULT_BITWIDTH-1:0] MUL_b;

wire signed [RESULT_BITWIDTH-1:0] error_Val_scaled_m0;
wire signed [RESULT_BITWIDTH-1:0] error_Val_scaled_m1;
wire signed [RESULT_BITWIDTH-1:0] error_Val_scaled_m2;

wire signed [RESULT_BITWIDTH-1:0] b2_coeff;
wire signed [RESULT_BITWIDTH-1:0] b1_coeff;
wire signed [RESULT_BITWIDTH-1:0] b0_coeff;
wire signed [RESULT_BITWIDTH-1:0] a1_coeff;
wire signed [RESULT_BITWIDTH-1:0] a0_coeff;

//Module Instantiation of BIT_ACC.v
MUL_ACC #(.N (MULTIPLIER_BITWIDTH), .CLK_DIV_MULTIPLIER(CLK_DIV_MULTIPLIER)) MUL (
    .clk_i (clk_i),
    .rstn_i (rstn_i),
    .MUL_Start_STRB_i (MUL_Start_STRB),
    .MUL_Done_STRB_o (MUL_Done_STRB),
    .a_i (MUL_a),
    .b_i (MUL_b),
    .acc_i (MUL_acc),
    .out_o (result_Val)
    );

//Assignments for shifting and scaling bit-vectors
assign ADC_Val = {{MULTIPLIER_BITWIDTH-ADC_BITWIDTH{1'b0}}, ADC_value_i};
assign frac_ADC_Val = ADC_Val <<< FRAC_BITWIDTH;
assign SET_Val = {{MULTIPLIER_BITWIDTH-ADC_BITWIDTH{1'b0}}, SET_value_i}; 
assign frac_SET_Val = SET_Val <<< FRAC_BITWIDTH;
assign error_Val = frac_SET_Val - frac_ADC_Val;

assign error_Val_scaled_m0 = {{RESULT_BITWIDTH-MULTIPLIER_BITWIDTH{error_Val_sreg[0][MULTIPLIER_BITWIDTH-1]}}, error_Val_sreg[0]};
assign error_Val_scaled_m1 = {{RESULT_BITWIDTH-MULTIPLIER_BITWIDTH{error_Val_sreg[1][MULTIPLIER_BITWIDTH-1]}}, error_Val_sreg[1]};
assign error_Val_scaled_m2 = {{RESULT_BITWIDTH-MULTIPLIER_BITWIDTH{error_Val_sreg[2][MULTIPLIER_BITWIDTH-1]}}, error_Val_sreg[2]};

assign b2_coeff = {{{RESULT_BITWIDTH-REG_BITWIDTH{b2_reg_i[REG_BITWIDTH-1]}}}, b2_reg_i};
assign b1_coeff = {{{RESULT_BITWIDTH-REG_BITWIDTH{b1_reg_i[REG_BITWIDTH-1]}}}, b1_reg_i};
assign b0_coeff = {{{RESULT_BITWIDTH-REG_BITWIDTH{b0_reg_i[REG_BITWIDTH-1]}}}, b0_reg_i};
assign a1_coeff = {{{RESULT_BITWIDTH-REG_BITWIDTH{a1_reg_i[REG_BITWIDTH-1]}}}, a1_reg_i};
assign a0_coeff = {{{RESULT_BITWIDTH-REG_BITWIDTH{a0_reg_i[REG_BITWIDTH-1]}}}, a0_reg_i};

//Result value of the last multiplication will be fed back into the multiplier to achieve accumulation
assign MUL_acc = (pipeStage == 0)? {{RESULT_BITWIDTH{1'b0}}} : result_Val;
assign MUL_a = get_Multiplier(pipeStage, b0_coeff, b1_coeff, b2_coeff, -a0_coeff, -a1_coeff);
assign MUL_b = get_Multiplier(pipeStage, error_Val_scaled_m2, error_Val_scaled_m1, error_Val_scaled_m0, out_Val_sreg[1] >>> FRAC_BITWIDTH, out_Val_sreg[0] >>> FRAC_BITWIDTH); 

assign out_Val_o = out_Val; 

// Clk-Enable-buffer to split/reduce Fanout 
always @(posedge clk_i) begin

    if (!rstn_i) begin
        clk_en_PID_buffer <= 0;
    end else if(clk_en_PID_i) begin
        clk_en_PID_buffer <= 1;
    end else begin
        clk_en_PID_buffer <= 0;
    end
end

//Shift Comb
always @(posedge clk_i) begin

    if (!rstn_i) begin
        error_Val_sreg[0] <= 0;  
        error_Val_sreg[1] <= 0;
        error_Val_sreg[2] <= 0;    
        out_Val_sreg[0]   <= 0;
        out_Val_sreg[1]   <= 0;
        out_Val           <= 0;
        
    //Shift error when Clk-enable is high
    end else if(clk_en_PID_i) begin
        error_Val_sreg[0] <= error_Val;  
        error_Val_sreg[1] <= error_Val_sreg[0];
        error_Val_sreg[2] <= error_Val_sreg[1];
    
    //Shift result of controller when multiplication is done
    end else if(MUL_Done_STRB && pipeStage == 4) begin
        out_Val_sreg[1]   <= out_Val_sreg[0];

        //Limit MAX/MIN result values
        if(result_Val >= MAX_PID_VALUE) begin
            out_Val_sreg[0] <= MAX_PID_VALUE;
        end else if(result_Val <= MIN_PID_VALUE) begin
            out_Val_sreg[0] <= MIN_PID_VALUE;
        end else begin
            out_Val_sreg[0] <= result_Val;
        end

        //Limit MAX/MIN output values
        if(result_Val > 0 && (result_Val >>> (2 * FRAC_BITWIDTH)) > MAX_OUT_VALUE) begin
            out_Val <= MAX_OUT_VALUE[ADC_BITWIDTH:0];
        end else if(result_Val < 0 && (result_Val >>> (2 * FRAC_BITWIDTH)) < MIN_OUT_VALUE) begin
            out_Val <= MIN_OUT_VALUE[ADC_BITWIDTH:0];
        end else begin
            out_Val <= result_Val[MAX_VAL_BITWIDTH:2*FRAC_BITWIDTH];
        end
    end 
end

//5-pipe stages for multiplications
//pipeStage = 0   -> multiply
//pipeStage = 1-4 -> multiply & accumulate
always @(posedge clk_i) begin

    if (!rstn_i) begin
        pipeStage  <= 0;
        MUL_Start_STRB <= 0;
    end else if(clk_en_PID_buffer) begin
        pipeStage  <= 0;
        MUL_Start_STRB <= 1;
    end else if(MUL_Done_STRB && pipeStage != 4) begin
        pipeStage <= pipeStage + 1;
        MUL_Start_STRB <= 1;
    end else begin
        MUL_Start_STRB <= 0;
    end
end

// Function to select the appropriate multiplier based on the pipeline stage
function signed[RESULT_BITWIDTH-1:0] get_Multiplier; 
input [PID_STAGES_BITWIDTH-1:0] x;
input signed[RESULT_BITWIDTH-1:0] Multiplier_1, Multiplier_2, Multiplier_3, Multiplier_4, Multiplier_5;
    begin
        case(x)
            0 : begin 
                get_Multiplier = Multiplier_1;
            end 
            1 : begin 
                get_Multiplier = Multiplier_2;
            end 
            2 : begin 
                get_Multiplier = Multiplier_3;
            end 
            3 : begin 
                get_Multiplier = Multiplier_4;
            end 
            4 : begin 
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



