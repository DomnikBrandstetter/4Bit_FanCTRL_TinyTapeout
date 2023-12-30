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

`include "PWM_controller.v"
`include "PID_core.v"

module FanCTRL #(parameter ADC_BITWIDTH = 8, REG_BITWIDTH = 32, FRAC_BITWIDTH = 30, CLK_FREQ = 1e6, PID_FREQ = 5, PWM_FREQ = 25e3)(
    input wire clk_i,
    input wire rstn_i,

    //Data-Interface
    input wire [ADC_BITWIDTH-1:0] ADC_value_i,
    input wire [ADC_BITWIDTH-1:0] SET_value_i,
    input wire [ADC_BITWIDTH  :0] PWM_periodCounterValue_i,
    input wire [ADC_BITWIDTH-1:0] PWM_minCounterValue_i,

    //PID-Controller coefficients 
    //y[k] = x[k]b2 + x[k-1]b1 + x[k-2]b0 - y[k-1]a1 - y[k-2]a0
    input wire signed [REG_BITWIDTH-1:0] a0_i,
    input wire signed [REG_BITWIDTH-1:0] a1_i,
    input wire signed [REG_BITWIDTH-1:0] b0_i,
    input wire signed [REG_BITWIDTH-1:0] b1_i,
    input wire signed [REG_BITWIDTH-1:0] b2_i,

    output wire PWM_pin_o, 
    output wire signed [ADC_BITWIDTH:0] PID_Val_o
);

//Clk Enable 
localparam MIN_MUL_TICKS = 30;
localparam MAX_MUL_TICKS = 100;
localparam PID_STAGES = 5; 

//Calculate constants
localparam PID_CLK_DIV = $rtoi(CLK_FREQ / PID_FREQ) - 1;
localparam PID_COUNTER_BITWIDTH = $rtoi(log2(PID_CLK_DIV+1)); 
localparam MAX_CLK_DIV_MULTIPLIER = $rtoi((PID_CLK_DIV + 1) / (PID_STAGES * 2 * (REG_BITWIDTH + ADC_BITWIDTH + 1) + MIN_MUL_TICKS));
localparam CLK_DIV_MULTIPLIER = (MAX_CLK_DIV_MULTIPLIER > MAX_MUL_TICKS)? MAX_MUL_TICKS : MAX_CLK_DIV_MULTIPLIER;

//------------ PID section --------------//

reg [PID_COUNTER_BITWIDTH-1:0] PID_clk_div_counterValue;
wire signed [ADC_BITWIDTH  :0] PID_Val;
wire clk_en_PID;

assign clk_en_PID = (PID_clk_div_counterValue == PID_CLK_DIV[PID_COUNTER_BITWIDTH-1:0])? 'b1 : 'b0;
assign PID_Val_o = PID_Val;

PID_core #(.ADC_BITWIDTH (ADC_BITWIDTH), .REG_BITWIDTH (REG_BITWIDTH), .FRAC_BITWIDTH (FRAC_BITWIDTH), .CLK_DIV_MULTIPLIER(CLK_DIV_MULTIPLIER)) PID(

    .clk_i (clk_i),
    .rstn_i (rstn_i),
    .clk_en_PID_i (clk_en_PID),
    .ADC_value_i (ADC_value_i),
    .SET_value_i (SET_value_i),

    .a0_reg_i (a0_i),
    .a1_reg_i (a1_i),
    .b0_reg_i (b0_i),
    .b1_reg_i (b1_i),
    .b2_reg_i (b2_i), 

    .out_Val_o (PID_Val)
    );

//CLK-Divider for PID 
always @(posedge clk_i) begin

    if (!rstn_i) begin
        PID_clk_div_counterValue <= 0;
    end else if (PID_clk_div_counterValue == PID_CLK_DIV[PID_COUNTER_BITWIDTH-1:0]) begin
        PID_clk_div_counterValue <= 0;
    end else begin
        PID_clk_div_counterValue <= PID_clk_div_counterValue + 1;
    end
end

//------------ PWM section --------------//

//calculate constants
localparam PWM_CLK_DIV = $rtoi(CLK_FREQ / (PWM_FREQ * (2 ** (ADC_BITWIDTH+1)))); // -> 22 - 33 kHz for MIN fan speed => 0% - 35%
localparam PWM_COUNTER_BITWIDTH = $rtoi(log2(PWM_CLK_DIV+1)); 

reg [PWM_COUNTER_BITWIDTH-1:0] PWM_clk_div_counterValue;
wire signed [ADC_BITWIDTH-1:0] PWM_counterValue;
wire clk_en_PWM;

assign clk_en_PWM = (PWM_clk_div_counterValue == PWM_CLK_DIV[PWM_COUNTER_BITWIDTH-1:0])? 'b1 : 'b0;
assign PWM_counterValue = (PID_Val[ADC_BITWIDTH] == 1)? (0 - PID_Val[ADC_BITWIDTH-1:0]) : {(ADC_BITWIDTH){1'b0}};

PWM_controller #(.COUNTER_BITWIDTH (ADC_BITWIDTH)) PWM(
   .clk_i (clk_i),
   .clk_en_i (clk_en_PWM),
   .rstn_i (rstn_i),
   .counterValue_i (PWM_counterValue),
   .minCounterValue_i (PWM_minCounterValue_i),
   .periodCounterValue_i (PWM_periodCounterValue_i),
   .PWM_pin_o (PWM_pin_o)
);

// CLK-Divider for PWM-controller 
always @(posedge clk_i) begin

   if (!rstn_i) begin
       PWM_clk_div_counterValue <= 0;
   end else if (PWM_clk_div_counterValue == PWM_CLK_DIV[PWM_COUNTER_BITWIDTH-1:0]) begin
       PWM_clk_div_counterValue <= 0;
   end else begin
       PWM_clk_div_counterValue <= PWM_clk_div_counterValue + 1;
   end
end

function integer log2;
   input [31:0] value;
   integer 	i;
   begin
      log2 = 0;
      for(i = 0; 2**i < value; i = i + 1)
	    log2 = i + 1;
   end
endfunction

endmodule


