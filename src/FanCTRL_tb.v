`timescale 1ns/1ps

module FanCTRL_tb;

localparam FRAC_BITWIDTH = 30;
localparam REG_BITWIDTH = 5;
localparam ADC_BITWIDTH = 8;

//PDT1-Glied
localparam real B2_PT2 = 5.76318539197624e-06;   //2.3e-17;
localparam real B1_PT2 = 1.152637078395248e-05;  //4.61e-17;
localparam real B0_PT2 = 5.76318539197624e-06;   //2.3e-17;
localparam real A1_PT2 = -1.9961897885309716;
localparam real A0_PT2 = 0.9961920938051285;
localparam real ERROR = 0.05;

reg clk_tb = 0;
reg clk_en_PWM_tb = 0;
reg rstn_tb;
reg dataValid_STRB_tb;
reg [ADC_BITWIDTH-1:0] ADC_value_tb;

wire [ADC_BITWIDTH-1:0] SET_value_tb;
wire signed [ADC_BITWIDTH:0] PID_Val_tb;
wire [ADC_BITWIDTH-1:0] PT2_simVal_tb;

wire signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] a0_reg_tb;
wire signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] a1_reg_tb;
wire signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] b0_reg_tb;
wire signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] b1_reg_tb;
wire signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] b2_reg_tb;
wire PWM_pin_tb;

integer i;
real PID_val[1:0];
real PT2_val[1:0];

FanCTRL #(.ADC_BITWIDTH (ADC_BITWIDTH), .REG_BITWIDTH (REG_BITWIDTH+FRAC_BITWIDTH), .FRAC_BITWIDTH (FRAC_BITWIDTH)) FAN (

    .clk_i (clk_tb),
    .rstn_i (rstn_tb),
    .clk_en_PWM_i (clk_en_PWM_tb),
    .dataValid_STRB_i (dataValid_STRB_tb),
    .periodCounterValue_i (9'd_320),
    .minCounterValue_i (8'd_65),
    .ADC_value_i (PT2_simVal_tb),
    .SET_value_i (SET_value_tb),

    .a0_i (a0_reg_tb),
    .a1_i (a1_reg_tb),
    .b0_i (b0_reg_tb),
    .b1_i (b1_reg_tb),
    .b2_i (b2_reg_tb), 

    .PWM_pin_o (PWM_pin_tb),
    .PID_Val_o (PID_Val_tb)
    );

assign b2_reg_tb = $rtoi(4.458581538461538 * (2 ** FRAC_BITWIDTH));
assign b1_reg_tb = $rtoi(-8.884606153846153 * (2 ** FRAC_BITWIDTH));
assign b0_reg_tb = $rtoi(4.426043076923077 * (2 ** FRAC_BITWIDTH));   // 10'b0001000111;//10'b_00_0100_1010; //4,625
assign a1_reg_tb = $rtoi(-1.9230769230769231 * (2 ** FRAC_BITWIDTH)); //= 10'b1101110010;//10'b_11_0110_1100; //-9,25
assign a0_reg_tb = $rtoi(0.9230769230769231 * (2 ** FRAC_BITWIDTH));  //= 10'b0001000111;//10'b_00_0100_1010;

assign SET_value_tb = 230;

assign PT2_simVal_tb = $rtoi(PT2_val[0]);

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

always #5 clk_tb = ~clk_tb;
always #20 clk_en_PWM_tb = ~clk_en_PWM_tb;

initial begin

    ADC_value_tb = 100;
    dataValid_STRB_tb = 0;
    rstn_tb = 0;
    #10;
    rstn_tb = 1;
    #15;
    forever begin
      dataValid_STRB_tb = 1;
      #10;
      dataValid_STRB_tb = 0;
      #10;
    end
    
end

endmodule








