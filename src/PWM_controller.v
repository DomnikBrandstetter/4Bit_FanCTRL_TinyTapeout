module Fan_PWM_controller #(parameter COUNTER_BITWIDTH=8)(
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

assign PWM_pin_o = (counter < counterValue || counter == periodCounterValue ) ? 1 : 0;

endmodule

