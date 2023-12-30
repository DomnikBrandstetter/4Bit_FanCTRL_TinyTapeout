`timescale 1ns/1ps

module MUL_ACC_tb;

localparam N = 4;

reg clk_tb = 0;
reg rstn_tb = 0;
reg MUL_Start_STRB_tb = 0;
reg [2*N-1:0] a = 0;
reg [2*N-1:0] b = 0;
reg [2*N-1:0] acc = 0;
wire [2*N-1:0] out;
wire MUL_Done_STRB_tb; 

MUL_ACC #(.N (N), .CLK_DIV_MULTIPLIER(3)) MUL (

    .clk_i (clk_tb),
    .rstn_i (rstn_tb),
    .MUL_Start_STRB_i (MUL_Start_STRB_tb),
    .MUL_Done_STRB_o (MUL_Done_STRB_tb),
    .a_i (a),
    .b_i (b),
    .acc_i (acc),
    .out_o (out)
    );

always #5 clk_tb = ~clk_tb;

initial begin
    a = 3;
    b = -2;
    rstn_tb = 0;
    #20;
    rstn_tb = 1;
    
    #20;
    MUL_Start_STRB_tb = 1;
    a = -3;
    b = -2;
    #10;
    MUL_Start_STRB_tb = 0;
    #400;
    MUL_Start_STRB_tb = 1;
    acc = 1;
    a = 3;
    b = 2;
    #10;
    MUL_Start_STRB_tb = 0;
    #400;
    MUL_Start_STRB_tb = 1;
    acc = -1;
    a = -3;
    b = 2;
    #10;
    MUL_Start_STRB_tb = 0;
    
end

endmodule










