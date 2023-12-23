`timescale 1ns / 1ps

module BIT_Multiplier #(parameter N = 4, CLK_DIV_MULTIPLIER = 50) (
        input wire clk_i,
        input wire rstn_i,
        input wire MUL_Start_STRB_i,
        output wire MUL_Done_STRB_o,
        input wire signed[N-1:0] a_i,
        input wire signed[N-1:0] b_i,
        output wire signed[2*N-1:0] out_o
	);

localparam CLK_DIV_MULTIPLIER_BITWIDTH = clogb2(CLK_DIV_MULTIPLIER);
localparam COUNTER_BITWIDTH = clogb2(2*N+1);
localparam [N-1:0]ZEROMASK = 0;
localparam [N-1:0]ONEMASK = (2 ** N) - 1;

reg MUL_Done_STRB_reg;
reg signed[(N*2)-1:0] out_reg;
reg signed[(N*2)-1:0] a_in_reg;
reg signed[(N*2)-1:0] b_in_reg;
reg [COUNTER_BITWIDTH-1:0] MulCounter;
reg [CLK_DIV_MULTIPLIER_BITWIDTH-1:0] clkCounterValue;

assign out_o = out_reg;
assign MUL_Done_STRB_o = (MUL_Done_STRB_reg == 0 && MulCounter == 2 * N && clkCounterValue == CLK_DIV_MULTIPLIER)? 1'b1 : 1'b0; //(MulCounter == 2 * N)

always @(posedge clk_i) begin

    if (!rstn_i) begin
        clkCounterValue  <= 0;
    end else if(MUL_Start_STRB_i || clkCounterValue == CLK_DIV_MULTIPLIER) begin
        clkCounterValue <= 0;
    end else begin
       clkCounterValue <= clkCounterValue + 1;
    end
end

always @(posedge clk_i) begin

    if (!rstn_i) begin
        MulCounter  <= 0;
        MUL_Done_STRB_reg <= 0;
    end else if(MUL_Start_STRB_i) begin
        MulCounter  <= 0;
        MUL_Done_STRB_reg <= 0;
    end else if(MulCounter < 2 * N && clkCounterValue == CLK_DIV_MULTIPLIER) begin
        MulCounter <= MulCounter + 1;
        MUL_Done_STRB_reg <= 0;
    end else if(MulCounter == 2 * N && clkCounterValue == CLK_DIV_MULTIPLIER) begin
        MUL_Done_STRB_reg <= 1;
    end 
end

always @(posedge clk_i) begin

    if (!rstn_i) begin
        out_reg  <= 0;
        a_in_reg <= 0;
		b_in_reg <= 0;
    end else if(MUL_Start_STRB_i) begin
        out_reg  <= 0;
        a_in_reg = {{{N{a_i[N-1]}}}, a_i};
        b_in_reg = {{{N{b_i[N-1]}}}, b_i};
        
        //a_in_reg <= (a_i < 0)? {ONEMASK, a_i} : {ZEROMASK, a_i};
		//b_in_reg <= (b_i < 0)? {ONEMASK, b_i} : {ZEROMASK, b_i};
    end else if(MulCounter < 2 * N && clkCounterValue == CLK_DIV_MULTIPLIER) begin
        if(b_in_reg[0]==1) begin
        out_reg <= out_reg + a_in_reg;
        end	
        a_in_reg = a_in_reg <<< 1;
		b_in_reg = b_in_reg >>> 1;
    end
end

function integer clogb2;
   input [31:0] value;
   integer 	i;
   begin
      clogb2 = 0;
      for(i = 0; 2**i < value; i = i + 1)
	clogb2 = i + 1;
   end
endfunction

endmodule

