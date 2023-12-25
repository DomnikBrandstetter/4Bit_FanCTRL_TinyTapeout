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

module PWM_controller #(parameter COUNTER_BITWIDTH = 5)(
    input wire clk_i,
    input wire clk_en_i,
    input wire rstn_i,
    input wire [COUNTER_BITWIDTH-1:0] counterValue_i,
    input wire [COUNTER_BITWIDTH-1:0] minCounterValue_i,
    input wire [COUNTER_BITWIDTH  :0] periodCounterValue_i,
    output wire PWM_pin_o
);

reg [COUNTER_BITWIDTH:0] counterValue;
reg [COUNTER_BITWIDTH:0] periodCounterValue;
reg [COUNTER_BITWIDTH:0] counter;

always @(posedge clk_i) begin

    if (!rstn_i) begin
        counter <= 0;
        counterValue <= 0;
        periodCounterValue <= 0;
    end else if (clk_en_i && counter == periodCounterValue) begin
        counter <= 0;
        periodCounterValue <= periodCounterValue_i;
        counterValue <= counterValue_i + minCounterValue_i;
    end else if (clk_en_i) begin
        counter <= counter + 1;
    end
end

assign PWM_pin_o = (counter <= counterValue && counterValue != 0) ? 1 : 0;

endmodule

