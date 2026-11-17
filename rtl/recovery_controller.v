`timescale 1ns/1ps
// Validates the admin code on the cycle the complete button sequence arrives.
module recovery_controller #(
    parameter [15:0] ADMIN_CODE = 16'hC0DE
)(
    input wire clk,
    input wire rst,
    input wire sequence_done_pulse,
    input wire [15:0] switch_value,
    output reg admin_recover_pulse
);
    always @(posedge clk) begin
        if (rst) begin
            admin_recover_pulse <= 1'b0;
        end else begin
            admin_recover_pulse <= sequence_done_pulse && (switch_value == ADMIN_CODE);
        end
    end
endmodule
