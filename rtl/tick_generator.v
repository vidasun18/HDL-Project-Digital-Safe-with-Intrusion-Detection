`timescale 1ns/1ps
// Single-clock 1 Hz clock-enable generator; tick_1hz is never a clock.
module tick_generator #(
    parameter integer CLK_HZ = 100_000_000
)(
    input wire clk,
    input wire rst,
    output reg tick_1hz
);
    localparam integer TICK_LIMIT = (CLK_HZ < 1) ? 1 : CLK_HZ;
    localparam integer COUNT_WIDTH = (TICK_LIMIT < 2) ? 1 : $clog2(TICK_LIMIT);
    reg [COUNT_WIDTH-1:0] tick_count;

    always @(posedge clk) begin
        if (rst) begin
            tick_count <= {COUNT_WIDTH{1'b0}};
            tick_1hz <= 1'b0;
        end else if (tick_count == TICK_LIMIT - 1) begin
            tick_count <= {COUNT_WIDTH{1'b0}};
            tick_1hz <= 1'b1;
        end else begin
            tick_count <= tick_count + 1'b1;
            tick_1hz <= 1'b0;
        end
    end
endmodule
