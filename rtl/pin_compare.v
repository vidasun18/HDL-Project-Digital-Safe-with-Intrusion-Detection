`timescale 1ns/1ps
// Combinational comparison only; authentication sequencing belongs to safe_fsm.
module pin_compare #(
    parameter [15:0] USER_PIN = 16'hA5C3
)(
    input wire [15:0] captured_pin,
    output wire pin_match
);
    assign pin_match = (captured_pin == USER_PIN);
endmodule
