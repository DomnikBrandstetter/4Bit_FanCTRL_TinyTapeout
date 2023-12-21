`default_nettype none
`timescale 1ns/1ps
`include "FanCTRL.v"

module FanCTRL_tb();

    // this part dumps the trace to a vcd file that can be viewed with GTKWave
    initial begin
    $dumpfile ("FAN_tb.vcd");
    $dumpvars (0, FanCTRL_tb);
    #1;
end

localparam FRAC_BITWIDTH = 30;
localparam REG_BITWIDTH = 5;
localparam ADC_BITWIDTH = 8;

localparam [ADC_BITWIDTH-1:0] MIN_FAN_SPEED = 65;
localparam [ADC_BITWIDTH:0] PERIOD_COUNTER = 320;

//PT2-Glied
localparam real B2_PT2 = 5.76318539197624e-06;   
localparam real B1_PT2 = 1.152637078395248e-05;  
localparam real B0_PT2 = 5.76318539197624e-06;  
localparam real A1_PT2 = -1.9961897885309716;
localparam real A0_PT2 = 0.9961920938051285;

//PID Parameter
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] b2_reg_tb = $rtoi(4.458581538461538   * (2 ** FRAC_BITWIDTH));
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] b1_reg_tb = $rtoi(-8.884606153846153  * (2 ** FRAC_BITWIDTH));
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] b0_reg_tb = $rtoi(4.426043076923077   * (2 ** FRAC_BITWIDTH)); 
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] a1_reg_tb = $rtoi(-1.9230769230769231 * (2 ** FRAC_BITWIDTH)); 
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] a0_reg_tb = $rtoi(0.9230769230769231  * (2 ** FRAC_BITWIDTH));

reg clk_tb = 0;
reg clk_en_PWM_tb = 0;
reg rstn_tb = 0;
reg dataValid_STRB_tb = 0;

wire signed [ADC_BITWIDTH:0] PID_Val_tb;
real PID_val[1:0];
real PT2_val[1:0];

wire [ADC_BITWIDTH-1:0]ADC_VAL_sim;
wire [ADC_BITWIDTH-1:0]SET_VAL_sim;
wire [ADC_BITWIDTH-1:0]ADC_PT2_sim;
reg [ADC_BITWIDTH-1:0]SET_PT2_sim;
reg [ADC_BITWIDTH-1:0]ADC_TEST_sim;
reg [ADC_BITWIDTH-1:0]SET_TEST_sim;
reg PT2_enable = 0;

wire PWM_pin_tb;

FanCTRL #(.ADC_BITWIDTH (ADC_BITWIDTH), .REG_BITWIDTH (REG_BITWIDTH+FRAC_BITWIDTH), .FRAC_BITWIDTH (FRAC_BITWIDTH)) FAN (

    .clk_i (clk_tb),
    .rstn_i (rstn_tb),
    .clk_en_PWM_i (clk_en_PWM_tb),
    .dataValid_STRB_i (dataValid_STRB_tb),
    .periodCounterValue_i (PERIOD_COUNTER),
    .minCounterValue_i (MIN_FAN_SPEED),
    .ADC_value_i (ADC_VAL_sim),
    .SET_value_i (SET_VAL_sim),

    .a0_i (a0_reg_tb),
    .a1_i (a1_reg_tb),
    .b0_i (b0_reg_tb),
    .b1_i (b1_reg_tb),
    .b2_i (b2_reg_tb), 

    .PWM_pin_o (PWM_pin_tb),
    .PID_Val_o (PID_Val_tb)
    );

assign ADC_VAL_sim = (PT2_enable == 1)? ADC_PT2_sim : ADC_TEST_sim;
assign SET_VAL_sim = (PT2_enable == 1)? SET_PT2_sim : SET_TEST_sim; 
assign ADC_PT2_sim = $rtoi(PT2_val[0]);

always @(posedge clk_tb, rstn_tb) begin
    if (!rstn_tb) begin
        PID_val[0] <= 0.0;  
        PID_val[1] <= 0.0;    
        PT2_val[0] <= 0.0;
        PT2_val[1] <= 0.0;
    end else if(dataValid_STRB_tb) begin 
        PID_val[0] <= ($itor(PID_Val_tb));  
        PID_val[1] <= PID_val[0];
        PT2_val[0] <= - A1_PT2 * PT2_val[0] - A0_PT2 * PT2_val[1] + B2_PT2 * ($itor(PID_Val_tb)) + B1_PT2 * PID_val[0] + B0_PT2 * PID_val[1]; 
        PT2_val[1] <= PT2_val[0];
    end
end

always@(*) begin
    if (!rstn_tb) begin
         SET_PT2_sim <= 210;
    end else if(ADC_PT2_sim >= 200) begin
        SET_PT2_sim <= 50;
     end else if(ADC_PT2_sim <= 50) begin
        SET_PT2_sim <= 210;
    end 
end 

always #5 clk_tb = ~clk_tb;
always #20 clk_en_PWM_tb = ~clk_en_PWM_tb;
always #10 dataValid_STRB_tb = ~dataValid_STRB_tb;

initial begin
    PT2_enable = 0;
    ADC_TEST_sim = 100;
    SET_TEST_sim = 20;
    rstn_tb = 0;
    #10;
    rstn_tb = 1;
    #30000;

    PT2_enable = 1;
    rstn_tb = 0;
    #10;
    rstn_tb = 1; 
    #50000 $finish;
end

endmodule








