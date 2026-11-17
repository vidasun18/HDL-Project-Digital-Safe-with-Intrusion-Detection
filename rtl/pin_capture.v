`timescale 1ns/1ps
// Captures the already-synchronized switch value when submit_pulse is sampled.
module pin_capture(
    input wire clk,
    input wire rst,
    input wire submit_pulse,
    input wire [15:0] switch_value,
    output reg [15:0] captured_pin,
    output reg captured_valid
);
    always @(posedge clk) begin
        if (rst) begin
            captured_pin <= 16'h0000;
            captured_valid <= 1'b0;
        end else begin
            captured_valid <= 1'b0;
            if (submit_pulse) begin
                captured_pin <= switch_value;
                captured_valid <= 1'b1;
            end
        end
    end
endmodule
