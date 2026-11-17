`timescale 1ns/1ps
module tb_safe_fsm;
    reg clk=1'b0, rst=1'b1;
    reg submit_valid=1'b0, pin_match=1'b0, third_failure=1'b0;
    reg tamper_latched=1'b0, tamper_pulse=1'b0, admin_recover_pulse=1'b0;
    reg alarm_done=1'b0, lockout_done=1'b0, manual_relock_pulse=1'b0;
    wire [2:0] state;
    wire wrong_pin_pulse, correct_pin_pulse, start_alarm_pulse, start_lockout_pulse;
    localparam [2:0] LOCKED=3'd0, CHECKING=3'd1, UNLOCKED=3'd2,
                     ALARM=3'd3, LOCKOUT=3'd4;
    always #5 clk=~clk;

    safe_fsm dut (
        .clk(clk), .rst(rst), .submit_valid(submit_valid), .pin_match(pin_match),
        .third_failure(third_failure), .tamper_latched(tamper_latched),
        .tamper_pulse(tamper_pulse), .admin_recover_pulse(admin_recover_pulse),
        .alarm_done(alarm_done), .lockout_done(lockout_done),
        .manual_relock_pulse(manual_relock_pulse), .state(state),
        .wrong_pin_pulse(wrong_pin_pulse), .correct_pin_pulse(correct_pin_pulse),
        .start_alarm_pulse(start_alarm_pulse), .start_lockout_pulse(start_lockout_pulse)
    );

    task submit;
        begin
            @(negedge clk); submit_valid=1'b1;
            @(posedge clk); #1;
            if (state !== CHECKING) $fatal(1, "submit must enter CHECKING");
            @(negedge clk); submit_valid=1'b0;
        end
    endtask

    task wrong_attempt(input reg is_third);
        begin
            submit();
            pin_match=1'b0; third_failure=is_third;
            @(posedge clk); #1;
            if (wrong_pin_pulse !== 1'b1)
                $fatal(1, "wrong submission must pulse failure once");
            if (is_third) begin
                if (state !== ALARM || start_alarm_pulse !== 1'b1)
                    $fatal(1, "third failure must enter ALARM and start timer");
            end else if (state !== LOCKED || start_alarm_pulse !== 1'b0) begin
                $fatal(1, "pre-threshold failure must return to LOCKED");
            end
            @(negedge clk); third_failure=1'b0;
            @(posedge clk); #1;
            if (wrong_pin_pulse !== 1'b0 || start_alarm_pulse !== 1'b0)
                $fatal(1, "failure and timer events must be one-cycle pulses");
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        #1;
        if (state !== LOCKED) $fatal(1, "reset must enter LOCKED");
        @(negedge clk); rst=1'b0;

        // Correct PIN unlocks and emits one success event; manual relock works.
        pin_match=1'b1;
        submit();
        @(posedge clk); #1;
        if (state !== UNLOCKED || correct_pin_pulse !== 1'b1 || wrong_pin_pulse !== 1'b0)
            $fatal(1, "correct PIN must unlock with a single success pulse");
        @(negedge clk); pin_match=1'b0; manual_relock_pulse=1'b1;
        @(posedge clk); #1;
        if (state !== LOCKED) $fatal(1, "manual relock must return to LOCKED");
        @(negedge clk); manual_relock_pulse=1'b0;

        // A tamper latch blocks even a matching PIN.
        tamper_latched=1'b1; pin_match=1'b1;
        submit();
        @(posedge clk); #1;
        if (state !== LOCKED || correct_pin_pulse !== 1'b0)
            $fatal(1, "ordinary PIN must not bypass latched tamper");
        tamper_latched=1'b0; pin_match=1'b0;

        wrong_attempt(1'b0);
        wrong_attempt(1'b0);
        wrong_attempt(1'b1);
        @(negedge clk); alarm_done=1'b1;
        @(posedge clk); #1;
        if (state !== LOCKOUT || start_lockout_pulse !== 1'b1)
            $fatal(1, "alarm completion must start lockout");
        @(negedge clk); alarm_done=1'b0; lockout_done=1'b1;
        @(posedge clk); #1;
        if (state !== LOCKED) $fatal(1, "lockout completion must return to LOCKED");

        // Tamper wins if a validated recovery event arrives on the same edge.
        @(negedge clk); tamper_pulse=1'b1; admin_recover_pulse=1'b1;
        @(posedge clk); #1;
        if (state !== ALARM || start_alarm_pulse !== 1'b1)
            $fatal(1, "tamper must take priority over simultaneous recovery");
        @(negedge clk); tamper_pulse=1'b0; admin_recover_pulse=1'b1;
        @(posedge clk); #1;
        if (state !== LOCKED) $fatal(1, "validated recovery must return to LOCKED");
        @(negedge clk); admin_recover_pulse=1'b0; lockout_done=1'b0;

        $display("PASS: FSM reset, PIN decisions, attempts, timers, tamper and recovery priority");
        $finish;
    end
endmodule
