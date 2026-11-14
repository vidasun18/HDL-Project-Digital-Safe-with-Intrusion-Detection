`timescale 1ns/1ps

module tb_member3_admin_sequence;
    localparam integer CLK_HZ = 1000;
    localparam integer DEBOUNCE_CYCLES = 3;
    localparam integer ALARM_SECONDS = 5;
    localparam integer LOCKOUT_SECONDS = 8;

    localparam [2:0] LOCKED = 3'd0;
    localparam [2:0] CHECKING = 3'd1;
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

    integer valid_event_count;
    integer valid_high_cycles;
    integer checking_left_event_seen;
    integer baseline_events;
    integer baseline_high_cycles;
    integer saved_alarm_elapsed;

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

    // Count post-NBA high cycles so the test can detect a stretched valid event.
    always @(posedge clk) begin
        #1;
        if (resetn) begin
            if (dut.admin_sequence_valid === 1'b1) begin
                valid_event_count = valid_event_count + 1;
                valid_high_cycles = valid_high_cycles + 1;
            end
            if (dut.state === CHECKING && dut.left_pulse === 1'b1)
                checking_left_event_seen = 1;
        end
    end

    task expect_progress;
        input [1:0] expected;
        begin
            if (dut.override_progress !== expected)
                $fatal(1, "sequence progress mismatch: expected %0d, got %0d",
                       expected, dut.override_progress);
        end
    endtask

    task apply_reset;
        begin
            @(negedge clk);
            resetn = 1'b0;
            repeat (2) @(posedge clk);
            #1;
            if (dut.state !== LOCKED || dut.override_progress !== 2'd0 ||
                dut.admin_sequence_valid !== 1'b0)
                $fatal(1, "reset must lock the safe and clear admin sequence state");
            if (dut.attempts !== 2'd0 || dut.captured_pin !== 16'h0000)
                $fatal(1, "reset must preserve the existing attempt/PIN reset behavior");
            if (dut.alarm_elapsed !== 0 || dut.lockout_elapsed !== 0 ||
                dut.alarm_done !== 1'b0 || dut.lockout_done !== 1'b0)
                $fatal(1, "reset must clear existing timer state");

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
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            @(negedge clk);
            btnc = 1'b0;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            #1;
        end
    endtask

    task press_left;
        begin
            @(negedge clk);
            btnl = 1'b1;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            @(negedge clk);
            btnl = 1'b0;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            #1;
        end
    endtask

    task press_up;
        begin
            @(negedge clk);
            btnu = 1'b1;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            @(negedge clk);
            btnu = 1'b0;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            #1;
        end
    endtask

    task press_both_admin_buttons;
        begin
            @(negedge clk);
            btnl = 1'b1;
            btnu = 1'b1;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            @(negedge clk);
            btnl = 1'b0;
            btnu = 1'b0;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            #1;
        end
    endtask

    task press_lock;
        begin
            @(negedge clk);
            btnd = 1'b1;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            @(negedge clk);
            btnd = 1'b0;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            #1;
        end
    endtask

    task press_tamper;
        begin
            @(negedge clk);
            btnr = 1'b1;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            @(negedge clk);
            btnr = 1'b0;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            #1;
        end
    endtask

    task hold_left;
        input integer hold_cycles;
        integer i;
        begin
            @(negedge clk);
            btnl = 1'b1;
            for (i = 0; i < hold_cycles; i = i + 1)
                @(posedge clk);
            #1;
        end
    endtask

    task release_left;
        begin
            @(negedge clk);
            btnl = 1'b0;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            #1;
        end
    endtask

    task hold_up;
        input integer hold_cycles;
        integer i;
        begin
            @(negedge clk);
            btnu = 1'b1;
            for (i = 0; i < hold_cycles; i = i + 1)
                @(posedge clk);
            #1;
        end
    endtask

    task release_up;
        begin
            @(negedge clk);
            btnu = 1'b0;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            #1;
        end
    endtask

    task bounce_left;
        begin
            @(negedge clk);
            btnl = 1'b1;
            repeat (DEBOUNCE_CYCLES - 1) @(posedge clk);
            @(negedge clk);
            btnl = 1'b0;
            repeat (DEBOUNCE_CYCLES + 5) @(posedge clk);
            #1;
        end
    endtask

    task bounce_up;
        begin
            @(negedge clk);
            btnu = 1'b1;
            repeat (DEBOUNCE_CYCLES - 1) @(posedge clk);
            @(negedge clk);
            btnu = 1'b0;
            repeat (DEBOUNCE_CYCLES + 5) @(posedge clk);
            #1;
        end
    endtask

    task enter_alarm;
        begin
            if (dut.state !== LOCKED)
                $fatal(1, "alarm setup requires the safe to start LOCKED");

            switches = 16'h1111;
            press_submit();
            if (dut.state !== LOCKED || dut.attempts !== 2'd1)
                $fatal(1, "first incorrect PIN must leave one failed attempt");

            switches = 16'h2222;
            press_submit();
            if (dut.state !== LOCKED || dut.attempts !== 2'd2)
                $fatal(1, "second incorrect PIN must leave two failed attempts");

            switches = 16'h3333;
            press_submit();
            repeat (2) @(posedge clk);
            #1;
            if (dut.state !== ALARM || dut.attempts !== 2'd3)
                $fatal(1, "third incorrect PIN must enter ALARM at the existing limit");
        end
    endtask

    task enter_alarm_with_attempt_and_tamper;
        begin
            if (dut.state !== LOCKED)
                $fatal(1, "tamper alarm setup requires the safe to start LOCKED");
            switches = 16'h1111;
            press_submit();
            if (dut.state !== LOCKED || dut.attempts !== 2'd1)
                $fatal(1, "tamper alarm setup must retain one failed attempt");
            press_tamper();
            if (dut.state !== ALARM || dut.attempts !== 2'd1 ||
                dut.tamper_latched !== 1'b1)
                $fatal(1, "locked tamper must enter ALARM with its latch set");
        end
    endtask

    task wait_for_state;
        input [2:0] target_state;
        input integer max_cycles;
        integer cycles;
        begin
            cycles = 0;
            while (dut.state !== target_state && cycles < max_cycles) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
            end
            if (dut.state !== target_state)
                $fatal(1, "timed out waiting for state %0d; current state is %0d",
                       target_state, dut.state);
        end
    endtask

    task send_correct_sequence;
        begin
            press_left();
            expect_progress(2'd1);
            if (dut.admin_sequence_valid !== 1'b0)
                $fatal(1, "LEFT alone must not generate a valid sequence event");

            press_up();
            expect_progress(2'd2);
            if (dut.admin_sequence_valid !== 1'b0)
                $fatal(1, "LEFT-UP must not generate a valid sequence event");

            press_left();
            expect_progress(2'd3);
            if (dut.admin_sequence_valid !== 1'b0)
                $fatal(1, "LEFT-UP-LEFT must not generate a valid sequence event");

            press_up();
            expect_progress(2'd0);
            if (dut.admin_sequence_valid !== 1'b0)
                $fatal(1, "valid event must return low after its registered pulse");
        end
    endtask

    task submit_and_generate_left_during_checking;
        begin
            switches = 16'hA5C3;
            @(negedge clk);
            btnc = 1'b1;
            @(posedge clk);
            @(negedge clk);
            btnl = 1'b1;
            repeat (DEBOUNCE_CYCLES + 5) @(posedge clk);
            @(negedge clk);
            btnc = 1'b0;
            btnl = 1'b0;
            repeat (DEBOUNCE_CYCLES + 5) @(posedge clk);
            #1;
        end
    endtask

    initial begin
        valid_event_count = 0;
        valid_high_cycles = 0;
        checking_left_event_seen = 0;

        // Test A: reset establishes a locked safe and clears detector outputs.
        apply_reset();
        expect_progress(2'd0);
        if (dut.admin_sequence_valid !== 1'b0 || valid_event_count != 0)
            $fatal(1, "reset must leave the valid event inactive");
        $display("PASS: Test A reset clears sequence progress and valid event");

        // Test B: recognize the sequence in ALARM without activating recovery.
        enter_alarm();
        baseline_events = valid_event_count;
        baseline_high_cycles = valid_high_cycles;
        saved_alarm_elapsed = dut.alarm_elapsed;
        send_correct_sequence();
        if (valid_event_count != baseline_events + 1 ||
            valid_high_cycles != baseline_high_cycles + 1)
            $fatal(1, "ALARM sequence must generate exactly one one-cycle valid event");
        if (dut.state !== ALARM || dut.attempts !== 2'd3 ||
            dut.override_pulse !== 1'b0 || dut.clear_counters !== 1'b0 ||
            dut.alarm_elapsed !== saved_alarm_elapsed)
            $fatal(1, "sequence recognition must not recover or restart ALARM in Phase 4");
        $display("PASS: Test B correct sequence in ALARM; recovery remains disabled");

        // Test C: recognize the sequence in LOCKOUT without leaving that state.
        apply_reset();
        enter_alarm();
        wait_for_state(LOCKOUT, CLK_HZ * (ALARM_SECONDS + 1) + 20);
        baseline_events = valid_event_count;
        baseline_high_cycles = valid_high_cycles;
        send_correct_sequence();
        if (valid_event_count != baseline_events + 1 ||
            valid_high_cycles != baseline_high_cycles + 1)
            $fatal(1, "LOCKOUT sequence must generate exactly one one-cycle valid event");
        if (dut.state !== LOCKOUT || dut.attempts !== 2'd3 ||
            dut.override_pulse !== 1'b0 || dut.clear_counters !== 1'b0)
            $fatal(1, "sequence recognition must not recover or clear LOCKOUT in Phase 4");
        $display("PASS: Test C correct sequence in LOCKOUT; timer operation is retained");

        // Test D: wrong events at each progress position reset progress without recognition.
        apply_reset();
        enter_alarm();
        baseline_events = valid_event_count;

        press_up();
        expect_progress(2'd0);

        press_left();
        expect_progress(2'd1);
        press_left();
        expect_progress(2'd0);

        press_left();
        press_up();
        expect_progress(2'd2);
        press_up();
        expect_progress(2'd0);

        press_left();
        press_up();
        press_left();
        expect_progress(2'd3);
        press_left();
        expect_progress(2'd0);

        if (valid_event_count != baseline_events || dut.admin_sequence_valid !== 1'b0)
            $fatal(1, "incorrect sequences must never generate a valid event");
        $display("PASS: Test D incorrect sequence events reset progress at each position");

        // Test E: long holds count once, and sub-debounce button bounce counts zero times.
        apply_reset();
        enter_alarm();
        baseline_events = valid_event_count;
        baseline_high_cycles = valid_high_cycles;

        hold_left(100);
        expect_progress(2'd1);
        release_left();
        expect_progress(2'd1);

        hold_up(100);
        expect_progress(2'd2);
        release_up();
        expect_progress(2'd2);
        if (valid_event_count != baseline_events)
            $fatal(1, "held LEFT or UP must not create repeated sequence steps");

        press_left();
        expect_progress(2'd3);
        press_up();
        expect_progress(2'd0);
        if (valid_event_count != baseline_events + 1 ||
            valid_high_cycles != baseline_high_cycles + 1)
            $fatal(1, "held-button sequence must complete with one valid pulse");

        baseline_events = valid_event_count;
        bounce_left();
        expect_progress(2'd0);
        bounce_up();
        expect_progress(2'd0);
        if (valid_event_count != baseline_events)
            $fatal(1, "short button bounce must not generate sequence events");
        $display("PASS: Test E holds count once and short bounce is rejected");

        // Test F: simultaneous debounced LEFT and UP is rejected from partial progress.
        apply_reset();
        enter_alarm();
        press_left();
        expect_progress(2'd1);
        baseline_events = valid_event_count;
        press_both_admin_buttons();
        expect_progress(2'd0);
        if (valid_event_count != baseline_events || dut.admin_sequence_valid !== 1'b0)
            $fatal(1, "simultaneous LEFT and UP must reset progress without recognition");
        $display("PASS: Test F simultaneous LEFT and UP is rejected");

        // Test G: sequence input is ignored in LOCKED, UNLOCKED and CHECKING.
        apply_reset();
        baseline_events = valid_event_count;
        press_left();
        press_up();
        press_left();
        press_up();
        expect_progress(2'd0);
        if (valid_event_count != baseline_events)
            $fatal(1, "admin sequence must be disabled while LOCKED");

        switches = 16'hA5C3;
        press_submit();
        if (dut.state !== UNLOCKED)
            $fatal(1, "disabled-state test requires normal PIN authentication");
        press_left();
        press_up();
        press_left();
        press_up();
        expect_progress(2'd0);
        if (valid_event_count != baseline_events)
            $fatal(1, "admin sequence must be disabled while UNLOCKED");

        apply_reset();
        checking_left_event_seen = 0;
        submit_and_generate_left_during_checking();
        if (dut.state !== UNLOCKED || checking_left_event_seen != 1)
            $fatal(1, "test must produce a debounced LEFT event during CHECKING");
        expect_progress(2'd0);
        if (valid_event_count != baseline_events)
            $fatal(1, "admin sequence must be disabled while CHECKING");
        $display("PASS: Test G sequence is disabled in LOCKED, CHECKING and UNLOCKED");

        // Test H: partial progress is preserved through ALARM-to-LOCKOUT.
        apply_reset();
        enter_alarm();
        press_left();
        expect_progress(2'd1);
        press_up();
        expect_progress(2'd2);
        wait_for_state(LOCKOUT, CLK_HZ * (ALARM_SECONDS + 1) + 20);
        expect_progress(2'd2);
        baseline_events = valid_event_count;
        baseline_high_cycles = valid_high_cycles;
        press_left();
        expect_progress(2'd3);
        press_up();
        expect_progress(2'd0);
        if (valid_event_count != baseline_events + 1 ||
            valid_high_cycles != baseline_high_cycles + 1 || dut.state !== LOCKOUT)
            $fatal(1, "sequence must complete once in LOCKOUT after ALARM progress");
        $display("PASS: Test H partial sequence continues across ALARM-to-LOCKOUT");

        // Test I: normal lockout expiry disables the detector and clears partial progress.
        apply_reset();
        enter_alarm_with_attempt_and_tamper();
        wait_for_state(LOCKOUT, CLK_HZ * (ALARM_SECONDS + 1) + 20);
        if (dut.attempts !== 2'd1 || dut.tamper_latched !== 1'b1)
            $fatal(1, "LOCKOUT setup must retain attempts and tamper before expiry");
        press_left();
        expect_progress(2'd1);
        baseline_events = valid_event_count;
        wait_for_state(LOCKED, CLK_HZ * (LOCKOUT_SECONDS + 1) + 20);
        if (dut.attempts !== 2'd0 || dut.tamper_latched !== 1'b0)
            $fatal(1, "automatic lockout expiry must keep existing status clearing behavior");
        expect_progress(2'd1);
        @(posedge clk);
        #1;
        expect_progress(2'd0);
        if (valid_event_count != baseline_events || dut.admin_sequence_valid !== 1'b0)
            $fatal(1, "disabled detector must clear partial progress without a valid event");
        $display("PASS: Test I automatic expiry clears partial progress on the next detector edge");

        // Test J: synchronous active-low reset clears a partial sequence in ALARM.
        apply_reset();
        enter_alarm();
        press_left();
        press_up();
        expect_progress(2'd2);
        baseline_events = valid_event_count;
        apply_reset();
        expect_progress(2'd0);
        if (dut.state !== LOCKED || dut.admin_sequence_valid !== 1'b0 ||
            valid_event_count != baseline_events)
            $fatal(1, "reset during partial progress must clear detector without recognition");
        $display("PASS: Test J reset during partial progress clears the detector");

        // Test K: each repeated complete sequence produces exactly one transient event.
        apply_reset();
        enter_alarm();
        baseline_events = valid_event_count;
        baseline_high_cycles = valid_high_cycles;
        send_correct_sequence();
        if (valid_event_count != baseline_events + 1 ||
            valid_high_cycles != baseline_high_cycles + 1 ||
            dut.admin_sequence_valid !== 1'b0)
            $fatal(1, "first complete sequence must produce one non-sticky event");
        send_correct_sequence();
        if (valid_event_count != baseline_events + 2 ||
            valid_high_cycles != baseline_high_cycles + 2 ||
            dut.admin_sequence_valid !== 1'b0)
            $fatal(1, "second complete sequence must produce exactly one additional event");
        repeat (4) @(posedge clk);
        #1;
        if (valid_event_count != baseline_events + 2 || dut.admin_sequence_valid !== 1'b0)
            $fatal(1, "valid event must not remain asserted or retrigger after completion");
        $display("PASS: Test K repeated sequences each produce one transient valid event");

        // Test L: unrelated buttons do not alter partial admin progress in ALARM.
        apply_reset();
        enter_alarm();
        press_left();
        expect_progress(2'd1);
        baseline_events = valid_event_count;
        switches = 16'hA5C3;
        press_submit();
        expect_progress(2'd1);
        press_lock();
        expect_progress(2'd1);
        press_tamper();
        expect_progress(2'd1);
        if (dut.state !== ALARM || valid_event_count != baseline_events)
            $fatal(1, "unrelated button events must not advance or recognize the sequence");
        $display("PASS: Test L unrelated buttons do not affect sequence progress");

        $display("PASS: Member 3 Phase 4 admin sequence verification");
        $finish;
    end
endmodule
