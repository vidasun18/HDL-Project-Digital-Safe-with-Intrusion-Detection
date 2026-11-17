`timescale 1ns/1ps
// Toggle the indicator on each 1 Hz enable while alarm_active is asserted.
module alarm_blinker(
    input wire clk,
    input wire rst,
    input wire tick_1hz,
    input wire alarm_active,
    output reg blink_led
);
    always @(posedge clk) begin
        if (rst || !alarm_active)
            blink_led <= 1'b0;
        else if (tick_1hz)
            blink_led <= ~blink_led;
    end
endmodule
