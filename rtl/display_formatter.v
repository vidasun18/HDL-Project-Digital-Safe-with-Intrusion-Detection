`timescale 1ns/1ps
// Display layout: AN7 status, AN6 failed count, AN1:AN0 remaining seconds.
// AN5:AN2 are zero. PIN and admin-code values are never passed to the display.
module display_formatter(
    input wire [2:0] state,
    input wire [1:0] failed_count,
    input wire [7:0] remaining_seconds,
    output reg [31:0] digits
);
    localparam [2:0] LOCKED=3'd0, CHECKING=3'd1, UNLOCKED=3'd2,
                     ALARM=3'd3, LOCKOUT=3'd4;
    reg [3:0] status_nibble;

    always @* begin
        case (state)
            LOCKED:   status_nibble = 4'h1;
            CHECKING: status_nibble = 4'hC;
            UNLOCKED: status_nibble = 4'h2;
            ALARM:    status_nibble = 4'hA;
            LOCKOUT:  status_nibble = 4'hD;
            default:  status_nibble = 4'h1;
        endcase

        digits = 32'h0000_0000;
        digits[31:28] = status_nibble;
        digits[27:24] = {2'b00, failed_count};
        digits[7:0] = remaining_seconds;
    end
endmodule
