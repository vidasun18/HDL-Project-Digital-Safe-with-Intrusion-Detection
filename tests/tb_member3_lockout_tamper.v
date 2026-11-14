`timescale 1ns/1ps

module tb_member3_lockout_tamper;
    localparam integer CLK_HZ = 20;
    localparam integer DEBOUNCE_CYCLES = 3;
    localparam integer ALARM_SECONDS = 2;
    localparam integer LOCKOUT_SECONDS = 6;

    localparam [2:0] LOCKED = 3'd0;
    localparam [2:0] UNLOCKED = 3'd2;
    localparam [2:0] ALARM = 3'd3;
    localparam [2:0] LOCKOUT = 3'd4;

    reg clk = 1'b0;
    reg resetn = 1'b1;
    reg [15:0] switches = 16'h0000;
    reg btnc = 1'b0;
    reg btnu = 1'b0;
    reg btnl = 1'b0;
    reg btnr = 1'b0;
    reg btnd = 1'b0;

    wire [15:0] led;
    wire [6:0] seg;
    wire [7:0] an;
    wire dp;

    integer submit_event_count;
    integer tamper_event_count;
    integer submit_before;
    integer tamper_before;

    digital_safe #(
        .CLK_HZ(CLK_HZ),
        .DEBOUNCE_CYCLES(DEBOUNCE_CYCLES),
        .ALARM_SECONDS(ALARM_SECONDS),
        .LOCKOUT_SECONDS(LOCKOUT_SECONDS),
        .MAX_ATTEMPTS(3),
        .USER_PIN(16'hA5C3)
    ) dut (
        .CLK100MHZ(clk),
        .CPU_RESETN(resetn),
        .SW(switches),
        .BTNC(btnc), .BTNU(btnu), .BTNL(btnl), .BTNR(btnr), .BTND(btnd),
        .LED(led), .SEG(seg), .AN(an), .DP(dp)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!resetn) begin
            submit_event_count <= 0;
            tamper_event_count <= 0;
        end else begin
            if (dut.submit_pulse)
                submit_event_count <= submit_event_count + 1;
            if (dut.tamper_pulse)
                tamper_event_count <= tamper_event_count + 1;
        end
    end

    task check_reset_values;
        begin
            if (dut.state !== LOCKED)
                $fatal(1, "reset must return the safe to LOCKED");
            if (dut.attempts !== 2'd0)
                $fatal(1, "reset must clear failed attempts");
            if (dut.tamper_latched !== 1'b0)
                $fatal(1, "reset must clear the tamper latch");
            if (dut.captured_pin !== 16'h0000)
                $fatal(1, "reset must clear the captured PIN");
            if (dut.alarm_elapsed !== 0 || dut.lockout_elapsed !== 0)
                $fatal(1, "reset must clear both elapsed timers");
            if (dut.alarm_done !== 1'b0 || dut.lockout_done !== 1'b0)
                $fatal(1, "reset must clear timer completion signals");
            if (dut.tick_1hz !== 1'b0)
                $fatal(1, "reset must clear the clock-enable pulse");
        end
    endtask

    task apply_reset;
        begin
            @(negedge clk);
            resetn = 1'b0;
            @(posedge clk);
            #1;
            check_reset_values();
            @(negedge clk);
            resetn = 1'b1;
            repeat (2) @(posedge clk);
            #1;
        end
    endtask

    task press_submit;
        begin
            @(negedge clk);
            btnc = 1'b1;
            repeat (DEBOUNCE_CYCLES + 2) @(posedge clk);
            @(negedge clk);
            btnc = 1'b0;
            repeat (DEBOUNCE_CYCLES + 2) @(posedge clk);
            #1;
        end
    endtask

    task press_tamper;
        begin
            @(negedge clk);
            btnr = 1'b1;
            repeat (DEBOUNCE_CYCLES + 2) @(posedge clk);
            @(negedge clk);
            btnr = 1'b0;
            repeat (DEBOUNCE_CYCLES + 2) @(posedge clk);
            #1;
        end
    endtask

    task press_lock;
        begin
            @(negedge clk);
            btnd = 1'b1;
            repeat (DEBOUNCE_CYCLES + 2) @(posedge clk);
            @(negedge clk);
            btnd = 1'b0;
            repeat (DEBOUNCE_CYCLES + 2) @(posedge clk);
            #1;
        end
    endtask

    task trigger_alarm_by_failed_pins;
        begin
            if (dut.state !== LOCKED)
                $fatal(1, "failed-PIN alarm setup requires LOCKED");

            switches = 16'h1111;
            press_submit();
            if (dut.state !== LOCKED || dut.attempts !== 2'd1)
                $fatal(1, "first wrong PIN must leave LOCKED with one attempt");

            switches = 16'h2222;
            press_submit();
            if (dut.state !== LOCKED || dut.attempts !== 2'd2)
                $fatal(1, "second wrong PIN must leave LOCKED with two attempts");

            switches = 16'h3333;
            press_submit();
            repeat (2) @(posedge clk);
            #1;
            if (dut.state !== ALARM || dut.attempts !== 2'd3)
                $fatal(1, "third wrong PIN must enter ALARM at the configured threshold");
        end
    endtask

    task wait_alarm_to_lockout;
        integer cycle_count;
        reg done_seen;
        begin
            cycle_count = 0;
            done_seen = 1'b0;
            while (!done_seen && cycle_count < (CLK_HZ * (ALARM_SECONDS + 1) + 10)) begin
                @(negedge clk);
                cycle_count = cycle_count + 1;

                if (dut.state !== ALARM)
                    $fatal(1, "FSM left ALARM before the registered alarm_done signal");

                if (dut.alarm_done === 1'b1) begin
                    if (dut.alarm_elapsed !== ALARM_SECONDS)
                        $fatal(1, "alarm_done must coincide with the configured elapsed count");
                    done_seen = 1'b1;
                end else if (dut.alarm_elapsed >= ALARM_SECONDS) begin
                    $fatal(1, "alarm elapsed count reached its limit before alarm_done");
                end
            end

            if (!done_seen)
                $fatal(1, "alarm timer did not complete within the bounded wait");

            // safe_timer registers done first; the FSM consumes it on the next posedge.
            @(posedge clk);
            #1;
            if (dut.state !== LOCKOUT)
                $fatal(1, "FSM must enter LOCKOUT on the edge after alarm_done is observed");
        end
    endtask

    task wait_lockout_to_locked;
        integer cycle_count;
        reg done_seen;
        begin
            cycle_count = 0;
            done_seen = 1'b0;
            while (!done_seen && cycle_count < (CLK_HZ * (LOCKOUT_SECONDS + 1) + 10)) begin
                @(negedge clk);
                cycle_count = cycle_count + 1;

                if (dut.state !== LOCKOUT)
                    $fatal(1, "FSM left LOCKOUT before the registered lockout_done signal");

                if (dut.lockout_done === 1'b1) begin
                    if (dut.lockout_elapsed !== LOCKOUT_SECONDS)
                        $fatal(1, "lockout_done must coincide with the configured elapsed count");
                    done_seen = 1'b1;
                end else if (dut.lockout_elapsed >= LOCKOUT_SECONDS) begin
                    $fatal(1, "lockout elapsed count reached its limit before lockout_done");
                end
            end

            if (!done_seen)
                $fatal(1, "lockout timer did not complete within the bounded wait");

            @(posedge clk);
            #1;
            if (dut.state !== LOCKED)
                $fatal(1, "FSM must return to LOCKED on the edge after lockout_done is observed");
            if (dut.attempts !== 2'd0)
                $fatal(1, "timed lockout recovery must clear failed attempts");
        end
    endtask

    initial begin
        submit_event_count = 0;
        tamper_event_count = 0;

        // Establish a known synchronous-reset state.
        apply_reset();
        if (dut.state !== LOCKED || dut.attempts !== 2'd0)
            $fatal(1, "initial reset did not establish the expected baseline");

        // Test A: verify alarm duration and the registered-done/FSM edge relationship.
        trigger_alarm_by_failed_pins();
        wait_alarm_to_lockout();
        $display("PASS: Test A alarm timing and ALARM-to-LOCKOUT transition");

        // Test B: a correct PIN submit event during LOCKOUT must be ignored.
        switches = 16'hA5C3;
        submit_before = submit_event_count;
        press_submit();
        if (submit_event_count !== submit_before + 1)
            $fatal(1, "LOCKOUT test must generate one debounced submit event");
        if (dut.state !== LOCKOUT || dut.attempts !== 2'd3)
            $fatal(1, "correct PIN submit must not bypass LOCKOUT");
        if (dut.lockout_done !== 1'b0 || dut.lockout_elapsed >= LOCKOUT_SECONDS)
            $fatal(1, "PIN-blocking check must occur before lockout timer completion");

        wait_lockout_to_locked();
        if (dut.tamper_latched !== 1'b0)
            $fatal(1, "current lockout-expiry behavior must clear the tamper latch");

        press_submit();
        if (dut.state !== UNLOCKED || dut.attempts !== 2'd0)
            $fatal(1, "a valid PIN after timed recovery must unlock normally");
        $display("PASS: Test B LOCKOUT blocks PIN, then recovers and accepts PIN");

        // Test D: start from reset, authenticate, then verify tamper while UNLOCKED.
        apply_reset();
        switches = 16'hA5C3;
        press_submit();
        if (dut.state !== UNLOCKED)
            $fatal(1, "Test D setup requires a successful PIN authentication");
        tamper_before = tamper_event_count;
        press_tamper();
        if (tamper_event_count !== tamper_before + 1)
            $fatal(1, "UNLOCKED tamper test must generate one debounced tamper event");
        if (dut.state !== UNLOCKED || dut.tamper_latched !== 1'b0 || dut.alarm_request !== 1'b0)
            $fatal(1, "tamper while UNLOCKED must not latch or request an alarm");
        $display("PASS: Test D tamper while UNLOCKED is ignored");

        press_lock();
        if (dut.state !== LOCKED)
            $fatal(1, "manual lock must return UNLOCKED to LOCKED before tamper testing");

        // Test C: reset, latch on locked tamper, survive release, then clear on expiry.
        apply_reset();
        tamper_before = tamper_event_count;
        press_tamper();
        if (tamper_event_count !== tamper_before + 1)
            $fatal(1, "LOCKED tamper test must generate one debounced tamper event");
        if (dut.state !== ALARM || dut.tamper_latched !== 1'b1 || dut.alarm_request !== 1'b1)
            $fatal(1, "tamper while LOCKED must latch and request ALARM after button release");
        wait_alarm_to_lockout();
        if (dut.tamper_latched !== 1'b1)
            $fatal(1, "tamper latch must remain set through ALARM and into LOCKOUT");
        wait_lockout_to_locked();
        if (dut.tamper_latched !== 1'b0)
            $fatal(1, "current RTL must clear the tamper latch when lockout expires");
        $display("PASS: Test C locked tamper latches through release and clears on expiry");

        // Test E1: synchronous reset from ALARM clears attempts, latch and timers.
        switches = 16'h1111;
        press_submit();
        if (dut.attempts !== 2'd1 || dut.state !== LOCKED)
            $fatal(1, "reset-from-ALARM setup requires one counted wrong PIN");
        tamper_before = tamper_event_count;
        press_tamper();
        if (tamper_event_count !== tamper_before + 1 || dut.state !== ALARM ||
            dut.attempts !== 2'd1 || dut.tamper_latched !== 1'b1)
            $fatal(1, "reset-from-ALARM setup must have an attempt and latched tamper");
        apply_reset();
        $display("PASS: Test E1 synchronous reset from ALARM clears state");

        // Test E2: repeat from LOCKOUT with both status flags set.
        switches = 16'h2222;
        press_submit();
        if (dut.attempts !== 2'd1 || dut.state !== LOCKED)
            $fatal(1, "reset-from-LOCKOUT setup requires one counted wrong PIN");
        tamper_before = tamper_event_count;
        press_tamper();
        if (tamper_event_count !== tamper_before + 1 || dut.state !== ALARM ||
            dut.attempts !== 2'd1 || dut.tamper_latched !== 1'b1)
            $fatal(1, "reset-from-LOCKOUT setup must enter ALARM with both status flags set");
        wait_alarm_to_lockout();
        if (dut.attempts !== 2'd1 || dut.tamper_latched !== 1'b1)
            $fatal(1, "LOCKOUT reset setup must retain attempts and tamper until expiry");
        apply_reset();
        $display("PASS: Test E2 synchronous reset from LOCKOUT clears state");

        $display("PASS: Member 3 targeted lockout and tamper verification");
        $finish;
    end
endmodule
