`include "PWM_controller.v"
`include "PID_core.v"

module FanCTRL_core #(parameter ADC_BITWIDTH=8, REG_BITWIDTH=5, FRAC_BITWIDTH=30)(
    input wire clk_i,
    input wire rstn_i,
    input wire clk_en_PWM_i,
    input wire clk_en_PID_i,
    input wire [ADC_BITWIDTH  :0] periodCounterValue_i,
    input wire [ADC_BITWIDTH-1:0] minCounterValue_i,
    input wire [ADC_BITWIDTH-1:0] ADC_value_i,
    input wire [ADC_BITWIDTH-1:0] SET_value_i,

    input wire signed [REG_BITWIDTH-1:0] a0_i,
    input wire signed [REG_BITWIDTH-1:0] a1_i,
    input wire signed [REG_BITWIDTH-1:0] b0_i,
    input wire signed [REG_BITWIDTH-1:0] b1_i,
    input wire signed [REG_BITWIDTH-1:0] b2_i,

    output wire PWM_pin_o, 
    output wire signed [ADC_BITWIDTH:0] PID_Val_o 
);

localparam [ADC_BITWIDTH-1:0] PWM_OFF = 0;

wire signed [ADC_BITWIDTH:0] PID_Val;
wire [ADC_BITWIDTH-1:0] counterValue;
assign PID_Val_o = PID_Val;
assign counterValue = (PID_Val < 0)? PWM_OFF-PID_Val[ADC_BITWIDTH-1:0] : PWM_OFF;

Fan_PWM_controller #(.COUNTER_BITWIDTH (ADC_BITWIDTH)) PWM(
    .clk_i (clk_i),
    .clk_en_i (clk_en_PWM_i),
    .rstn_i (rstn_i),
    .counterValue_i (counterValue),
    .minCounterValue_i (minCounterValue_i),
    .periodCounterValue_i (periodCounterValue_i),
    .PWM_pin_o (PWM_pin_o)
);

Fan_PID_core #(.ADC_BITWIDTH (ADC_BITWIDTH), .REG_BITWIDTH (REG_BITWIDTH), .FRAC_BITWIDTH (FRAC_BITWIDTH)) PID(

    .clk_i (clk_i),
    .rstn_i (rstn_i),
    .clk_en_PID_i (clk_en_PID_i),
    .ADC_value_i (ADC_value_i),
    .SET_value_i (SET_value_i),

    .a0_reg_i (a0_i),
    .a1_reg_i (a1_i),
    .b0_reg_i (b0_i),
    .b1_reg_i (b1_i),
    .b2_reg_i (b2_i), 

    .out_Val_o (PID_Val)
    );

endmodule


