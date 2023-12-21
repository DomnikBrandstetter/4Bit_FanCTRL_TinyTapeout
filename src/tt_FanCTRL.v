`default_nettype none
`include "FanCTRL.v"
`include "DecoderSEG7.v"
// external clock is 10MHz

module tt_um_FanCTRL #( parameter PID_CLK_DIV = 17'd99_999, PWM_CLK_DIV = 4'd13 ) (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

localparam FRAC_BITWIDTH = 30;
localparam REG_BITWIDTH = 2;
localparam ADC_BITWIDTH = 8;
localparam [ADC_BITWIDTH:0] PWM_PERIOD_COUNTER = 320;
localparam [ADC_BITWIDTH-1:0] PWM_MIN_FAN_SPEED = 65;
//localparam [REG_BITWIDTH+FRAC_BITWIDTH-33 : 0] ZERO_MASK = 0;

//PID Parameter
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b2 = $rtoi(4.458581538461538   * (2 ** FRAC_BITWIDTH));
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b1 = $rtoi(-8.884606153846153  * (2 ** FRAC_BITWIDTH));
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_b0 = $rtoi(4.426043076923077   * (2 ** FRAC_BITWIDTH)); 
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_a1 = $rtoi(-1.9230769230769231 * (2 ** FRAC_BITWIDTH)); 
localparam signed [REG_BITWIDTH+FRAC_BITWIDTH-1:0] PID_a0 = $rtoi(0.9230769230769231  * (2 ** FRAC_BITWIDTH));

wire clk_enPWM;
wire clk_enPID;
wire PWM_pin;
wire dataVaild_STRB;
wire configPin;
wire [3:0] sevenSeg;
wire [6:0] led_out;
reg [7:0] ADC_value;
reg [7:0] SET_value;
reg [16:0] PID_clk_div_counterValue;
reg [3:0] PWM_clk_div_counterValue;

FanCTRL #(.ADC_BITWIDTH (ADC_BITWIDTH), .REG_BITWIDTH (REG_BITWIDTH+FRAC_BITWIDTH), .FRAC_BITWIDTH (FRAC_BITWIDTH)) FAN (

    .clk_i (clk),
    .rstn_i (rst_n),
    .clk_en_PWM_i (clk_enPWM),
    .clk_en_PID_i (clk_enPID),
    .periodCounterValue_i (PWM_PERIOD_COUNTER),
    .minCounterValue_i (PWM_MIN_FAN_SPEED),
    .ADC_value_i (ADC_value),
    .SET_value_i (SET_value),

    .b2_i (PID_b2), 
    .b1_i (PID_b1),
    .b0_i (PID_b0),
    .a1_i (PID_a1),
    .a0_i (PID_a0),
           
    .PWM_pin_o (PWM_pin),
    .PID_Val_o ()
    );
    
    // segment display
DecoderSEG7 #() seg7 (
    .counter(sevenSeg),
    .segments(led_out)
     );

// use bidirectionals as inputs
assign uio_oe = 8'b00000000;
assign uio_out = 8'b00000000;

assign uo_out[6:0] = led_out;
assign uo_out[7] = PWM_pin;
assign sevenSeg = (configPin)? 4'hC : 4'hA;

assign dataVaild_STRB = uio_in[0];
assign configPin = uio_in[1];

//Clk 10 MHz
//Clk Enable PID (100 Hz) / PWM (25kHz kHz)
assign clk_enPID = (PID_clk_div_counterValue == PID_CLK_DIV)? 'b1 : 'b0;
assign clk_enPWM = (PWM_clk_div_counterValue == PWM_CLK_DIV)? 'b1 : 'b0;

always @(posedge clk, rst_n) begin

    if (!rst_n) begin
        PID_clk_div_counterValue <= 0;
    end else if (PID_clk_div_counterValue == PID_CLK_DIV) begin
        PID_clk_div_counterValue <= 0;
    end else begin
        PID_clk_div_counterValue <= PID_clk_div_counterValue + 1;
    end
end

always @(posedge clk, rst_n) begin

    if (!rst_n) begin
        PWM_clk_div_counterValue <= 0;
    end else if (PWM_clk_div_counterValue == PWM_CLK_DIV) begin
        PWM_clk_div_counterValue <= 0;
    end else begin
        PWM_clk_div_counterValue <= PWM_clk_div_counterValue + 1;
    end
end

always @(posedge clk, rst_n) begin

    if (!rst_n) begin
        ADC_value <= 0;
        SET_value <= 0;
    end else if (ena & configPin & dataVaild_STRB) begin
        SET_value <= ui_in;
    end else if (ena & !configPin & dataVaild_STRB) begin
        ADC_value <= ui_in;
    end
end 

endmodule
