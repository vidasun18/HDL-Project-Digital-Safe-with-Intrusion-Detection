`timescale 1ns/1ps
// Registered access-control FSM. Event outputs are one-cycle pulses.
module safe_fsm(
    input wire clk,
    input wire rst,
    input wire submit_valid,
    input wire pin_match,
    input wire third_failure,
    input wire tamper_latched,
    input wire tamper_pulse,
    input wire admin_recover_pulse,
    input wire alarm_done,
    input wire lockout_done,
    input wire manual_relock_pulse,
    output reg [2:0] state,
    output reg wrong_pin_pulse,
    output reg correct_pin_pulse,
    output reg start_alarm_pulse,
    output reg start_lockout_pulse
);
    localparam [2:0] LOCKED=3'd0, CHECKING=3'd1, UNLOCKED=3'd2,
                     ALARM=3'd3, LOCKOUT=3'd4;

    always @(posedge clk) begin
        if (rst) begin
            state <= LOCKED;
            wrong_pin_pulse <= 1'b0;
            correct_pin_pulse <= 1'b0;
            start_alarm_pulse <= 1'b0;
            start_lockout_pulse <= 1'b0;
        end else begin
            wrong_pin_pulse <= 1'b0;
            correct_pin_pulse <= 1'b0;
            start_alarm_pulse <= 1'b0;
            start_lockout_pulse <= 1'b0;

            // A new tamper event wins over recovery and all normal transitions.
            if (tamper_pulse) begin
                state <= ALARM;
                start_alarm_pulse <= 1'b1;
            end else if (admin_recover_pulse) begin
                // This input must already represent validated sequence + code.
                state <= LOCKED;
            end else begin
                case (state)
                    LOCKED: begin
                        if (submit_valid)
                            state <= CHECKING;
                    end
                    CHECKING: begin
                        if (pin_match) begin
                            if (tamper_latched) begin
                                // A valid PIN cannot clear or bypass tamper evidence.
                                state <= LOCKED;
                            end else begin
                                state <= UNLOCKED;
                                correct_pin_pulse <= 1'b1;
                            end
                        end else begin
                            wrong_pin_pulse <= 1'b1;
                            if (third_failure) begin
                                state <= ALARM;
                                start_alarm_pulse <= 1'b1;
                            end else begin
                                state <= LOCKED;
                            end
                        end
                    end
                    UNLOCKED: begin
                        if (manual_relock_pulse)
                            state <= LOCKED;
                    end
                    ALARM: begin
                        if (alarm_done) begin
                            state <= LOCKOUT;
                            start_lockout_pulse <= 1'b1;
                        end
                    end
                    LOCKOUT: begin
                        if (lockout_done)
                            state <= LOCKED;
                    end
                    default: state <= LOCKED;
                endcase
            end
        end
    end
endmodule
