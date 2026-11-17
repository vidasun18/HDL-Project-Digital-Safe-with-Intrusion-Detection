`timescale 1ns/1ps
// Latches a tamper event until reset or validated administrative recovery.
// A new tamper event wins over a coincident clear request.
module tamper_detector(
    input wire clk,
    input wire rst,
    input wire tamper_press_pulse,
    input wire clear_tamper,
    output reg tamper_latched,
    output reg tamper_event_pulse
);
    always @(posedge clk) begin
        if (rst) begin
            tamper_latched <= 1'b0;
            tamper_event_pulse <= 1'b0;
        end else begin
            tamper_event_pulse <= 1'b0;
            if (tamper_press_pulse) begin
                tamper_latched <= 1'b1;
                tamper_event_pulse <= 1'b1;
            end else if (clear_tamper) begin
                tamper_latched <= 1'b0;
            end
        end
    end
endmodule
