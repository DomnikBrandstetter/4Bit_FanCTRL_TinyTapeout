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

module FanCTRL #(parameter ADC_BITWIDTH = 8, REG_BITWIDTH = 32, FRAC_BITWIDTH = 30)(
    //The module requires a 10 MHz clk_en signal to achieve a 10 ms time step
    input wire clk_i,
    input wire rstn_i,
    input wire clk_en_i,

    //Data-Interface
    input wire [ADC_BITWIDTH-1:0] ADC_value_i,
    input wire [ADC_BITWIDTH-1:0] SET_value_i,
    input wire [ADC_BITWIDTH  :0] PWM_periodCounterValue_i,
    input wire [ADC_BITWIDTH-1:0] PWM_minCounterValue_i,

    //Control-Interface
    input wire config_en_i,
    input wire dataVaild_STRB_i,

    //PID-Controller coefficients (time step = Ta = 10 ms) 
    //y[k] = x[k]b2 + x[k-1]b1 + x[k-2]b0+ y[k-1]a1 + y[k-2]a0
    input wire signed [REG_BITWIDTH-1:0] a0_i,
    input wire signed [REG_BITWIDTH-1:0] a1_i,
    input wire signed [REG_BITWIDTH-1:0] b0_i,
    input wire signed [REG_BITWIDTH-1:0] b1_i,
    input wire signed [REG_BITWIDTH-1:0] b2_i,

    output wire PWM_pin_o, 
    output wire signed [ADC_BITWIDTH:0] PID_Val_o, 
    output wire [3:0] state_o
);

//Clk Enable = 10 MHz
localparam MIN_MUL_TICKS = 30;
localparam PID_STAGES = 5; 

localparam CLK_EN_FREQ = 10e6; // 10 MHz
localparam PID_FREQ    = 1;//100;  // 100 Hz // use 10 kHz for simulation
localparam PWM_FREQ    = 25e3; // 25 kHz

//status FANCTRL
localparam [3:0] MODE_RUN    = 4'hA; 
localparam [3:0] MODE_CONFIG = 4'hC;

//calculate constant
localparam PID_CLK_DIV = $rtoi(CLK_EN_FREQ / (PID_STAGES * PID_FREQ)) - 1;
localparam PID_COUNTER_BITWIDTH = $rtoi(log2(PID_CLK_DIV+1)); 
localparam CLK_DIV_MULTIPLIER = $rtoi((PID_CLK_DIV + 1) / (2 * (REG_BITWIDTH + ADC_BITWIDTH + 1) + MIN_MUL_TICKS));
localparam PWM_CLK_DIV = $rtoi((CLK_EN_FREQ / PWM_FREQ) - 1);
localparam PWM_COUNTER_BITWIDTH = $rtoi(log2(PWM_CLK_DIV+1)); 

reg [PID_COUNTER_BITWIDTH-1:0] PID_clk_div_counterValue;
reg [PWM_COUNTER_BITWIDTH-1:0] PWM_clk_div_counterValue;

reg [ADC_BITWIDTH-1:0] ADC_value;
reg [ADC_BITWIDTH-1:0] SET_value;
wire signed [ADC_BITWIDTH  :0] PID_Val;
wire signed [ADC_BITWIDTH-1:0] PWM_counterValue;
wire clk_en_PID;
wire clk_en_PWM;

assign clk_en_PID = (PID_clk_div_counterValue == PID_CLK_DIV[PID_COUNTER_BITWIDTH-1:0])? 'b1 : 'b0;
assign clk_en_PWM = (PWM_clk_div_counterValue == PWM_CLK_DIV[PWM_COUNTER_BITWIDTH-1:0])? 'b1 : 'b0;
assign state_o = (config_en_i)? MODE_CONFIG : MODE_RUN;

assign PID_Val_o = PID_Val;
assign PWM_counterValue = (PID_Val < 0)? $unsigned(PID_Val[ADC_BITWIDTH-1:0]) : {(ADC_BITWIDTH){1'b0}};

PWM_controller #(.COUNTER_BITWIDTH (ADC_BITWIDTH)) PWM(
    .clk_i (clk_i),
    .clk_en_i (clk_en_PWM),
    .rstn_i (rstn_i),
    .counterValue_i (PWM_counterValue),
    .minCounterValue_i (PWM_minCounterValue_i),
    .periodCounterValue_i (PWM_periodCounterValue_i),
    .PWM_pin_o (PWM_pin_o)
);

PID_core #(.ADC_BITWIDTH (ADC_BITWIDTH), .REG_BITWIDTH (REG_BITWIDTH), .FRAC_BITWIDTH (FRAC_BITWIDTH), .CLK_DIV_MULTIPLIER(CLK_DIV_MULTIPLIER)) PID(

    .clk_i (clk_i),
    .rstn_i (rstn_i),
    .clk_en_PID_i (clk_en_PID),
    .ADC_value_i (ADC_value),
    .SET_value_i (SET_value),

    .a0_reg_i (a0_i),
    .a1_reg_i (a1_i),
    .b0_reg_i (b0_i),
    .b1_reg_i (b1_i),
    .b2_reg_i (b2_i), 

    .out_Val_o (PID_Val)
    );

//CLK-Divider for PID (100 Hz) 
always @(posedge clk_i) begin

    if (!rstn_i) begin
        PID_clk_div_counterValue <= 0;
    end else if (clk_en_i && PID_clk_div_counterValue == PID_CLK_DIV[PID_COUNTER_BITWIDTH-1:0]) begin
        PID_clk_div_counterValue <= 0;
    end else if (clk_en_i) begin
        PID_clk_div_counterValue <= PID_clk_div_counterValue + 1;
    end
end

//CLK-Divider for PWM-controller (25 kHz)
always @(posedge clk_i) begin

    if (!rstn_i) begin
        PWM_clk_div_counterValue <= 0;
    end else if (clk_en_i && PWM_clk_div_counterValue == PWM_CLK_DIV[PWM_COUNTER_BITWIDTH-1:0]) begin
        PWM_clk_div_counterValue <= 0;
    end else if (clk_en_i) begin
        PWM_clk_div_counterValue <= PWM_clk_div_counterValue + 1;
    end
end

//store Values if data is valid
always @(posedge clk_i) begin

    if (!rstn_i) begin
        ADC_value <= 0;
        SET_value <= 0;
    end else if (config_en_i & dataVaild_STRB_i) begin
        SET_value <= SET_value_i;
    end else if (!config_en_i & dataVaild_STRB_i) begin
        ADC_value <= ADC_value_i;
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


