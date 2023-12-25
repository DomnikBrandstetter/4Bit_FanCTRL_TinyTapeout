`timescale 1ns/1ps
`default_nettype none
`include "tt_um_FanCTRL.v"

module tt_FanCTRL_tb;

// //PT2-Glied 8-Bit PID 100Hz
// localparam ADC_BITWIDTH = 8;
// localparam real B2_PT2 = 5.76318539197624e-06;   
// localparam real B1_PT2 = 1.152637078395248e-05;  
// localparam real B0_PT2 = 5.76318539197624e-06;  
// localparam real A1_PT2 = -1.9961897885309716;
// localparam real A0_PT2 = 0.9961920938051285;

//PT2-Glied 4-Bit PI 1Hz 
localparam ADC_BITWIDTH = 4;
localparam PT2_FREQ = 5; // 5 Hz
localparam real B2_PT2 = 0.0010627042223499215;   
localparam real B1_PT2 = 0.002125408444699843;  
localparam real B0_PT2 = 0.0010627042223499215;  
localparam real A1_PT2 = -1.8591120801803738;
localparam real A0_PT2 = 0.8599622435582536;

reg clk_tb = 0;
reg rstn_tb = 0;

wire signed [ADC_BITWIDTH:0] PID_Val_tb;
real PID_val[1:0];
real PT2_val[1:0];

wire [ADC_BITWIDTH-1:0]ADC_VAL_sim;
wire [ADC_BITWIDTH-1:0]SET_VAL_sim;
wire [ADC_BITWIDTH-1:0]ADC_PT2_sim;

reg [ADC_BITWIDTH-1:0]SET_PT2_sim = 2;
reg [ADC_BITWIDTH-1:0]ADC_TEST_sim;
reg [ADC_BITWIDTH-1:0]SET_TEST_sim;

reg PT2_enable = 0;
localparam CLK_EN_FREQ = 1e6;
localparam PID_STAGES = 5; // 5 Hz
localparam CLK_DIV_PID = 2;
localparam PT2_CLK_DIV = $rtoi(CLK_EN_FREQ / (PT2_FREQ)) - 1;
localparam PID_COUNTER_BITWIDTH = $rtoi(log2(PT2_CLK_DIV+1)); 
reg [PID_COUNTER_BITWIDTH-1:0] clkCounterValue;

wire [7:0] uio_oe;
wire [7:0] uio_out;
wire [7:0] uo_out;
wire [7:0] uio_in;
wire [7:0] ui_in;

assign PID_Val_tb = uio_out[ADC_BITWIDTH:0];

assign ADC_VAL_sim = (PT2_enable == 1)? ADC_PT2_sim : ADC_TEST_sim;
assign SET_VAL_sim = (PT2_enable == 1)? SET_PT2_sim : SET_TEST_sim; 
assign ADC_PT2_sim = (PT2_val[0] < 0)? 0 : $rtoi(PT2_val[0]/5 + 0.5);

assign ui_in = {SET_VAL_sim, ADC_VAL_sim};  

always @(posedge clk_tb, rstn_tb) begin
    if (!rstn_tb) begin
        PID_val[0] <= 0.0;  
        PID_val[1] <= 0.0;    
        PT2_val[0] <= 50.0;
        PT2_val[1] <= 50.0;
    end else if(clkCounterValue == PT2_CLK_DIV) begin 
        PID_val[0] <= ($itor(PID_Val_tb));  
        PID_val[1] <= PID_val[0];
        PT2_val[0] <= - A1_PT2 * PT2_val[0] - A0_PT2 * PT2_val[1] + B2_PT2 * ($itor(PID_Val_tb)) + B1_PT2 * PID_val[0] + B0_PT2 * PID_val[1]; 
        PT2_val[1] <= PT2_val[0];
    end
end

tt_um_FanCTRL #() tt_um_FAN (
    `ifdef GL_TEST
        .VPWR( 1'b1),
        .VGND( 1'b0),
    `endif
    .ui_in (ui_in),      // Dedicated inputs               - (0-7) ADC 0-3 / SET 7-4 -> DATA IN 
    .uo_out (uo_out),    // Dedicated outputs              - (0-6) = 7 segment display / 7 = PWM-Pin
    .uio_in (uio_in),    // IOs: Bidirectional Input path  - unused
    .uio_out (uio_out),  // IOs: Bidirectional Output path - unused
    .uio_oe (uio_oe),    // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    .ena (1'b1),          // will go high when the design is enabled
    .clk (clk_tb),       // clock - 1 MHz
    .rst_n (rstn_tb)     // reset_n - low to reset
);

always @(posedge clk_tb) begin

    if (!rstn_tb) begin
        clkCounterValue  <= 0;
    end else if (clkCounterValue == PT2_CLK_DIV) begin
        clkCounterValue <= 0;
    end else begin
        clkCounterValue <= clkCounterValue + 1;
    end
end

// always@(*) begin
//     if (!rstn_tb) begin
//          SET_PT2_sim <= 2;
//     end else if(ADC_PT2_sim >= 12) begin
//         SET_PT2_sim <= 2;
//      end else if(ADC_PT2_sim <= 3) begin
//         SET_PT2_sim <= 13;
//     end 
// end 

always #1 clk_tb = ~clk_tb;

initial begin
    ADC_TEST_sim = 7;
    SET_TEST_sim = 5;
    PT2_enable = 0;
    rstn_tb = 0;
    #11;
    rstn_tb = 1;

    #100000000;

    PT2_enable = 1;
    rstn_tb = 0;
    #10;
    rstn_tb = 1; 
    #150000000 $finish;
    //#30000 $finish;
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

