`timescale 1ns/1ps
`include "tt_FanCTRL.v"

module tt_FanCTRL_tb;

    // this part dumps the trace to a vcd file that can be viewed with GTKWave
    initial begin
    $dumpfile ("tt_FAN_tb.vcd");
    $dumpvars (0, tt_FanCTRL_tb);
    #1;
end

localparam [16:0] PID_CLK_DIV = 17'd99_999;
localparam [3:0] PWM_CLK_DIV = 4'd13;

reg clk_tb = 0;
reg rstn_tb = 0;
reg configEnable = 0;
reg dataVaild = 0;
reg [7:0] data = 0;

wire [7:0] uio_oe;
wire [7:0] uio_out;
wire [7:0] uo_out;
wire [7:0] uio_in;
wire [7:0] ui_in;

integer i;   

tt_um_FanCTRL #(.PID_CLK_DIV (PID_CLK_DIV), .PWM_CLK_DIV (PWM_CLK_DIV) ) tt_FAN (
    `ifdef GL_TEST
        .VPWR( 1'b1),
        .VGND( 1'b0),
    `endif
    .ui_in (ui_in),      // Dedicated inputs - connected to the input switches
    .uo_out (uo_out),    // Dedicated outputs - connected to the 7 segment display
    .uio_in (uio_in),    // IOs: Bidirectional Input path
    .uio_out (uio_out),  // IOs: Bidirectional Output path
    .uio_oe (uio_oe),    // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    .ena (1'b1),          // will go high when the design is enabled
    .clk (clk_tb),       // clock
    .rst_n (rstn_tb)     // reset_n - low to reset
);

assign ui_in = data;
assign uio_in[0] = dataVaild;
assign uio_in[1] = configEnable;

always #50 clk_tb = ~clk_tb;
always #100 dataVaild = ~dataVaild;

initial begin
    rstn_tb = 0;
    #100;
    rstn_tb = 1;
    #150;
    data = 100;
    configEnable = 1;
    dataVaild = 1;
    #100;
    dataVaild = 0;
    configEnable = 0;
    data = 50;

    #30000 $finish;
end

endmodule









