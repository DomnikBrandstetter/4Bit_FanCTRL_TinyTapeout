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

`default_nettype none
`include "FanCTRL.v"
`include "sevenSegDisplay.v"

module tt_um_FanCTRL (
    input  wire [7:0] ui_in,    // Dedicated inputs               - (0-7) ADC 0-3 / SET 7-4 -> DATA IN 
    output wire [7:0] uo_out,   // Dedicated outputs              - (0-6) = 7 segment display / 7 = PWM-Pin
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path  - unused
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path - singed output of controller
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock - 1 MHz
    input  wire       rst_n     // reset_n - low to reset
);

localparam REG_BITWIDTH = 2; // >= 1
localparam ADC_BITWIDTH = 4;

// // PID - Parameter -> 100 Hz -> uses 240% Util / 8 Bit ADC
// localparam FRAC_BITWIDTH = 35;
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b2 = 39'd89486590317;
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b1 = 39'd37128568331;
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b0 = 39'd88983914994;
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_a1 = 39'd483077041442;
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_a0 = 39'd32319034078;

//PI - Parameter -> 1 Hz -> 1 Hz uses 79% Util / 4 Bit ADC
localparam FRAC_BITWIDTH = 6;
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b2 =  8'd94;  
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b1 =  8'd0;    
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b0 = -8'd93; 
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_a1 =  8'd0;     
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_a0 = -8'd64;

//Setup PWM
localparam [ADC_BITWIDTH:0] PWM_PERIOD_COUNTER =  18; 
localparam [ADC_BITWIDTH-1:0] PWM_MIN_FAN_SPEED = 3; 

wire PWM_pin;
wire [ADC_BITWIDTH:0] PID_Val;
wire [ADC_BITWIDTH-1:0] sevenSegVal;

wire [6:0] led_out;

FanCTRL #(.ADC_BITWIDTH (ADC_BITWIDTH), .REG_BITWIDTH (REG_BITWIDTH+FRAC_BITWIDTH), .FRAC_BITWIDTH (FRAC_BITWIDTH)) FAN (
    //The module requires a 1 MHz clk_en signal to achieve a 200 ms time step
    .clk_i (clk),
    .rstn_i (rst_n),
    .clk_en_i (clk),
    
    //Data-Interface
    .ADC_value_i (ui_in[ADC_BITWIDTH-1:0]),
    .SET_value_i (ui_in[ADC_BITWIDTH+ADC_BITWIDTH-1:ADC_BITWIDTH]),
    .PWM_periodCounterValue_i (PWM_PERIOD_COUNTER),
    .PWM_minCounterValue_i (PWM_MIN_FAN_SPEED),

    //PID-Controller coefficients (time step = Ta = 200 ms) 
    //y[k] = x[k]b2 + x[k-1]b1 + x[k-2]b0 - y[k-1]a1 - y[k-2]a0
    .b2_i (PID_b2), 
    .b1_i (PID_b1),
    .b0_i (PID_b0),
    .a1_i (PID_a1),
    .a0_i (PID_a0),
           
    .PWM_pin_o (PWM_pin),
    .PID_Val_o (PID_Val)
    );

//display current controlled variable
sevenSegDisplay #() DECODER (
    .counter(sevenSegVal),
    .segments(led_out)
    );

// use bidirectionals ports as output
assign uio_oe = 8'b11111111;
assign uio_out = {3'b000, PID_Val};

assign sevenSegVal = 4'hA; //(PID_Val[ADC_BITWIDTH] == 1)? (0 - PID_Val[ADC_BITWIDTH-1:0]) : {(ADC_BITWIDTH){1'b0}};

assign uo_out[6:0] = led_out;
assign uo_out[7] = PWM_pin;

endmodule
