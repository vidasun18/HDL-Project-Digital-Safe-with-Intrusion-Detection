`timescale 1ns/1ps
// Counts tick enables, not clocks. Priority: reset > cancel > start > tick.
// Durations are 1..MAX_SECONDS; zero completes immediately on start.
module countdown_timer #(
    parameter integer MAX_SECONDS = 15
)(
    input wire clk,
    input wire rst,
    input wire tick_1hz,
    input wire start_pulse,
    input wire cancel,
    input wire [7:0] duration_seconds,
    output reg [7:0] remaining_seconds,
    output reg done_pulse
);
    localparam integer MAX_DURATION =
        (MAX_SECONDS < 0) ? 0 : ((MAX_SECONDS > 255) ? 255 : MAX_SECONDS);
    reg active;
    reg [7:0] load_value;

    always @* begin
        if (duration_seconds > MAX_DURATION)
            load_value = MAX_DURATION[7:0];
        else
            load_value = duration_seconds;
    end

    always @(posedge clk) begin
        if (rst) begin
            remaining_seconds <= 8'd0;
            done_pulse <= 1'b0;
            active <= 1'b0;
        end else begin
            done_pulse <= 1'b0;
            if (cancel) begin
                remaining_seconds <= 8'd0;
                active <= 1'b0;
            end else if (start_pulse) begin
                if (load_value == 8'd0) begin
                    remaining_seconds <= 8'd0;
                    active <= 1'b0;
                    done_pulse <= 1'b1;
                end else begin
                    remaining_seconds <= load_value;
                    active <= 1'b1;
                end
            end else if (tick_1hz && active) begin
                if (remaining_seconds <= 8'd1) begin
                    remaining_seconds <= 8'd0;
                    active <= 1'b0;
                    done_pulse <= 1'b1;
                end else begin
                    remaining_seconds <= remaining_seconds - 1'b1;
                end
            end
        end
    end
endmodule
