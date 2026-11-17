`timescale 1ns/1ps
// Two-flop input synchronizer followed by a stable-level debounce filter.
// rst is synchronous, active high. press_pulse is one clk cycle per press.
module button_debounce #(
    parameter integer DEBOUNCE_CYCLES = 1_000_000
)(
    input wire clk,
    input wire rst,
    input wire button_raw,
    output reg stable_level,
    output reg press_pulse
);
    localparam integer DEBOUNCE_LIMIT = (DEBOUNCE_CYCLES < 1) ? 1 : DEBOUNCE_CYCLES;
    localparam integer COUNT_WIDTH = (DEBOUNCE_LIMIT < 2) ? 1 : $clog2(DEBOUNCE_LIMIT);

    reg sync_meta;
    reg sync_level;
    reg [COUNT_WIDTH-1:0] debounce_count;

    always @(posedge clk) begin
        if (rst) begin
            sync_meta <= 1'b0;
            sync_level <= 1'b0;
            debounce_count <= {COUNT_WIDTH{1'b0}};
            stable_level <= 1'b0;
            press_pulse <= 1'b0;
        end else begin
            sync_meta <= button_raw;
            sync_level <= sync_meta;
            press_pulse <= 1'b0;

            if (sync_level == stable_level) begin
                debounce_count <= {COUNT_WIDTH{1'b0}};
            end else if (debounce_count == DEBOUNCE_LIMIT - 1) begin
                debounce_count <= {COUNT_WIDTH{1'b0}};
                stable_level <= sync_level;
                if (sync_level)
                    press_pulse <= 1'b1;
            end else begin
                debounce_count <= debounce_count + 1'b1;
            end
        end
    end
endmodule
