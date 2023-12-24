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
`include "decoder.v"

module tt_um_FanCTRL (
    input  wire [7:0] ui_in,    // Dedicated inputs               - (0-7) ADC/SET DATA IN 
    output wire [7:0] uo_out,   // Dedicated outputs              - (0-6) = 7 segment display / 7 = PWM-Pin
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path  - 0 = dataVaild_STRB        / 1 = config_en
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path 
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock - 10 MHz
    input  wire       rst_n     // reset_n - low to reset
);

localparam REG_BITWIDTH = 4; // >= 4
localparam ADC_BITWIDTH = 6;

// // PID - Parameter -> 100 Hz -> uses 240% Util
// localparam FRAC_BITWIDTH = 35;
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b2 = 39'd89486590317;
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b1 = 39'd37128568331;
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b0 = 39'd88983914994;
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_a1 = 39'd483077041442;
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_a0 = 39'd32319034078;

//PI - Parameter -> 100 Hz -> uses 150% Util
// localparam FRAC_BITWIDTH = 14;
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b2 = 18'd2326;   //$rtoi(0.14198388365958936   * (2 ** FRAC_BITWIDTH));
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b1 = 18'd1;      //$rtoi(8.92646033898664e-05  * (2 ** FRAC_BITWIDTH));
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b0 = 18'd259820; //$rtoi(-0.1418946190561995   * (2 ** FRAC_BITWIDTH)); 
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_a1 = 18'd0;      //$rtoi(0                     * (2 ** FRAC_BITWIDTH)); 
// localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_a0 = 18'd245760; //$rtoi(-1.0                  * (2 ** FRAC_BITWIDTH));

//PI - Parameter -> 1 Hz -> uses 130% Util
localparam FRAC_BITWIDTH = 6;
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b2 =  10'd9;  
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b1 =  10'd0;    
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b0 = -10'd8; 
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_a1 =  10'd0;     
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_a0 = -10'd64;

//Setup PWM
localparam [ADC_BITWIDTH:0] PWM_PERIOD_COUNTER =  76;//320;
localparam [ADC_BITWIDTH-1:0] PWM_MIN_FAN_SPEED = 12;//65;

wire PWM_pin;
wire dataVaild_STRB;
wire config_en;

wire [3:0] sevenSegState;
wire [6:0] led_out;

FanCTRL #(.ADC_BITWIDTH (ADC_BITWIDTH), .REG_BITWIDTH (REG_BITWIDTH+FRAC_BITWIDTH), .FRAC_BITWIDTH (FRAC_BITWIDTH)) FAN (
    //The module requires a 10 MHz clk_en signal to achieve a 10 ms time step
    .clk_i (clk),
    .rstn_i (rst_n),
    .clk_en_i (clk),
    
    //Data-Interface
    .ADC_value_i (ui_in[ADC_BITWIDTH-1:0]),
    .SET_value_i (ui_in[ADC_BITWIDTH-1:0]),
    .PWM_periodCounterValue_i (PWM_PERIOD_COUNTER),
    .PWM_minCounterValue_i (PWM_MIN_FAN_SPEED),

    //Control-Interface
    .config_en_i (config_en),
    .dataVaild_STRB_i (dataVaild_STRB),

    //PID-Controller coefficients (time step = Ta = 10 ms) 
    //y[k] = x[k]b2 + x[k-1]b1 + x[k-2]b0+ y[k-1]a1 + y[k-2]a0
    .b2_i (PID_b2), 
    .b1_i (PID_b1),
    .b0_i (PID_b0),
    .a1_i (PID_a1),
    .a0_i (PID_a0),
           
    .PWM_pin_o (PWM_pin),
    .PID_Val_o (),
    .state_o (sevenSegState)
    );

// use bidirectionals as inputs
assign uio_oe = 8'b00000000;
assign uio_out = 8'b00000000;
assign dataVaild_STRB = uio_in[0] & ena;
assign config_en = uio_in[1];

assign uo_out[6:0] = led_out;
assign uo_out[7] = PWM_pin;

// segment display -> C for config mode / A for run mode
seg7 seg7(.counter(sevenSegState), .segments(led_out));

endmodule
