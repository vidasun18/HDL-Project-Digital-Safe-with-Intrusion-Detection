`timescale 1ns/1ps
// Recognizes LEFT -> UP -> LEFT -> UP from debounced one-cycle press pulses.
module admin_sequence(
    input wire clk,
    input wire rst,
    input wire left_press_pulse,
    input wire up_press_pulse,
    output reg [1:0] progress,
    output reg sequence_done_pulse
);
    always @(posedge clk) begin
        if (rst) begin
            progress <= 2'd0;
            sequence_done_pulse <= 1'b0;
        end else begin
            sequence_done_pulse <= 1'b0;
            if (left_press_pulse && up_press_pulse) begin
                progress <= 2'd0;
            end else if (left_press_pulse) begin
                case (progress)
                    2'd2: progress <= 2'd3;
                    // A LEFT can begin a fresh prefix after an incorrect step.
                    default: progress <= 2'd1;
                endcase
            end else if (up_press_pulse) begin
                case (progress)
                    2'd1: progress <= 2'd2;
                    2'd3: begin
                        progress <= 2'd0;
                        sequence_done_pulse <= 1'b1;
                    end
                    default: progress <= 2'd0;
                endcase
            end
        end
    end
endmodule
