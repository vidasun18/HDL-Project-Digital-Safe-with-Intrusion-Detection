`timescale 1ns/1ps
// Saturating three-strike counter. clear_attempts wins over an increment.
module failed_attempt_counter(
    input wire clk,
    input wire rst,
    input wire wrong_pin_pulse,
    input wire clear_attempts,
    output reg [1:0] failed_count,
    output wire third_failure
);
    assign third_failure = (failed_count >= 2'd2);

    always @(posedge clk) begin
        if (rst || clear_attempts) begin
            failed_count <= 2'd0;
        end else if (wrong_pin_pulse && failed_count < 2'd3) begin
            failed_count <= failed_count + 1'b1;
        end
    end
endmodule
