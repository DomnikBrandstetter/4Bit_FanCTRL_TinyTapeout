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

module MUL_ACC #(parameter N = 4, CLK_DIV_MULTIPLIER = 50) (
        input wire clk_i,
        input wire rstn_i,
        input wire MUL_Start_STRB_i,
        output wire MUL_Done_STRB_o,
        input wire signed[(N*2)-1:0] a_i,
        input wire signed[(N*2)-1:0] b_i,
        input wire signed[(N*2)-1:0] acc_i,
        output wire signed[(N*2)-1:0] out_o
	);

//calculate Bitwidth 
localparam CLK_DIV_MULTIPLIER_BITWIDTH = log2(CLK_DIV_MULTIPLIER);
localparam COUNTER_BITWIDTH = log2(2*N+1);

reg MUL_Done_STRB_reg;
reg signed[(N*2)-1:0] out_reg;
reg signed[(N*2)-1:0] a_in_reg;
reg signed[(N*2)-1:0] b_in_reg;
reg [COUNTER_BITWIDTH-1:0] MulCounter;
reg [CLK_DIV_MULTIPLIER_BITWIDTH-1:0] clkCounterValue;

assign out_o = out_reg;
assign MUL_Done_STRB_o = (MUL_Done_STRB_reg == 0 && {{(32-COUNTER_BITWIDTH){1'b0}}, MulCounter} == (2 * N) && clkCounterValue == CLK_DIV_MULTIPLIER[CLK_DIV_MULTIPLIER_BITWIDTH-1:0])? 1'b1 : 1'b0;

// CLK-Divider
always @(posedge clk_i) begin

    if (!rstn_i) begin
        clkCounterValue  <= 0;
    end else if(MUL_Start_STRB_i || clkCounterValue == CLK_DIV_MULTIPLIER[CLK_DIV_MULTIPLIER_BITWIDTH-1:0]) begin
        clkCounterValue <= 0;
    end else begin
       clkCounterValue <= clkCounterValue + 1;
    end
end

// Strobe gen 
always @(posedge clk_i) begin

    if (!rstn_i) begin
        MulCounter  <= 0;
        MUL_Done_STRB_reg <= 0;
    end else if(MUL_Start_STRB_i) begin
        MulCounter  <= 0;
        MUL_Done_STRB_reg <= 0;
    end else if({{(32-COUNTER_BITWIDTH){1'b0}}, MulCounter} != (2 * N) && clkCounterValue == CLK_DIV_MULTIPLIER[CLK_DIV_MULTIPLIER_BITWIDTH-1:0]) begin
        MulCounter <= MulCounter + 1;
        MUL_Done_STRB_reg <= 0;
    end else if({{(32-COUNTER_BITWIDTH){1'b0}}, MulCounter} == (2 * N) && clkCounterValue == CLK_DIV_MULTIPLIER[CLK_DIV_MULTIPLIER_BITWIDTH-1:0]) begin
        MUL_Done_STRB_reg <= 1;
    end 
end

//COMB multiply / accumulate
always @(posedge clk_i) begin

    if (!rstn_i) begin
        out_reg  <= 0;
        a_in_reg <= 0;
		b_in_reg <= 0;
    end else if(MUL_Start_STRB_i) begin
        out_reg  <= acc_i;
        a_in_reg <= a_i;
        b_in_reg <= b_i;

    //multiply / accumulate and shift
    end else if({{(32-COUNTER_BITWIDTH){1'b0}}, MulCounter} != (2 * N) && clkCounterValue == CLK_DIV_MULTIPLIER[CLK_DIV_MULTIPLIER_BITWIDTH-1:0]) begin
        if(b_in_reg[0]==1) begin
        out_reg <= out_reg + a_in_reg;
        end	
        a_in_reg <= a_in_reg <<< 1;
	    b_in_reg <= b_in_reg >>> 1;
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

