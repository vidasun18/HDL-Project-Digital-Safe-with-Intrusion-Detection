`timescale 1ns/1ps
// Eight-digit scan using a clock enable; no derived/fabric clock is created.
module sevenseg_mux #(
    parameter integer REFRESH_DIV = 100_000
)(
    input wire clk,
    input wire rst,
    input wire [31:0] digits,
    output wire [6:0] SEG,
    output reg [7:0] AN,
    output wire DP
);
    localparam integer DIVISOR = (REFRESH_DIV < 1) ? 1 : REFRESH_DIV;
    localparam integer COUNT_WIDTH = (DIVISOR < 2) ? 1 : $clog2(DIVISOR);

    reg [COUNT_WIDTH-1:0] refresh_count;
    reg [2:0] digit_index;
    reg [3:0] active_nibble;
    wire [6:0] decoded_segments;

    always @(posedge clk) begin
        if (rst) begin
            refresh_count <= {COUNT_WIDTH{1'b0}};
            digit_index <= 3'd0;
        end else if (refresh_count == DIVISOR - 1) begin
            refresh_count <= {COUNT_WIDTH{1'b0}};
            digit_index <= digit_index + 1'b1;
        end else begin
            refresh_count <= refresh_count + 1'b1;
        end
    end

    always @* begin
        case (digit_index)
            3'd0: active_nibble = digits[3:0];
            3'd1: active_nibble = digits[7:4];
            3'd2: active_nibble = digits[11:8];
            3'd3: active_nibble = digits[15:12];
            3'd4: active_nibble = digits[19:16];
            3'd5: active_nibble = digits[23:20];
            3'd6: active_nibble = digits[27:24];
            default: active_nibble = digits[31:28];
        endcase
        AN = ~(8'b0000_0001 << digit_index);
    end

    hex7seg decode_digit(.hex_digit(active_nibble), .seg_n(decoded_segments));
    assign SEG = decoded_segments;
    assign DP = 1'b1;
endmodule
