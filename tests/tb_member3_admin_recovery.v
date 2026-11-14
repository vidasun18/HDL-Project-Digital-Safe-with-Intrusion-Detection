`timescale 1ns/1ps

module tb_member3_admin_recovery;
    localparam integer CLK_HZ = 100;
    localparam integer DEBOUNCE_CYCLES = 3;
    localparam integer ALARM_SECONDS = 4;
    localparam integer LOCKOUT_SECONDS = 5;

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

    integer admin_event_count;
    integer admin_high_cycles;
    integer override_event_count;
    integer override_high_cycles;
    integer baseline_admin_events;
    integer baseline_admin_cycles;
    integer baseline_override_events;
    integer baseline_override_cycles;
    integer wait_cycles;

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

    // Count post-NBA event levels to check that both pulses are one clock wide.
    always @(posedge clk) begin
        #1;
        if (resetn) begin
            if (dut.admin_sequence_valid === 1'b1) begin
                admin_event_count = admin_event_count + 1;
                admin_high_cycles = admin_high_cycles + 1;
            end
            if (dut.override_pulse === 1'b1) begin
                override_event_count = override_event_count + 1;
                override_high_cycles = override_high_cycles + 1;
            end
        end
    end

    task apply_reset;
        begin
            @(negedge clk);
            resetn = 1'b0;
            repeat (2) @(posedge clk);
            #1;
            if (dut.state !== LOCKED || dut.attempts !== 2'd0 ||
                dut.tamper_latched !== 1'b0 || dut.override_progress !== 2'd0 ||
                dut.admin_sequence_valid !== 1'b0 || dut.override_pulse !== 1'b0)
                $fatal(1, "reset must lock the safe and clear recovery-related state");
            if (dut.alarm_elapsed !== 0 || dut.lockout_elapsed !== 0 ||
                dut.alarm_done !== 1'b0 || dut.lockout_done !== 1'b0)
                $fatal(1, "reset must clear both existing timers");

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

    task enter_attempt_alarm;
        begin
            if (dut.state !== LOCKED)
                $fatal(1, "failed-attempt alarm setup requires LOCKED");
            switches = 16'h1111;
            press_submit();
            if (dut.state !== LOCKED || dut.attempts !== 2'd1)
                $fatal(1, "first incorrect PIN must set one failed attempt");
            switches = 16'h2222;
            press_submit();
            if (dut.state !== LOCKED || dut.attempts !== 2'd2)
                $fatal(1, "second incorrect PIN must set two failed attempts");
            switches = 16'h3333;
            press_submit();
            repeat (2) @(posedge clk);
            #1;
            if (dut.state !== ALARM || dut.attempts !== 2'd3)
                $fatal(1, "third incorrect PIN must enter ALARM at the existing limit");
        end
    endtask

    task enter_tamper_alarm;
        begin
            if (dut.state !== LOCKED)
                $fatal(1, "tamper alarm setup requires LOCKED");
            press_tamper();
            if (dut.state !== ALARM || dut.tamper_latched !== 1'b1)
                $fatal(1, "locked tamper must latch and enter ALARM");
        end
    endtask

    task enter_tamper_alarm_with_attempt;
        begin
            if (dut.state !== LOCKED)
                $fatal(1, "tamper alarm setup requires LOCKED");
            switches = 16'h1111;
            press_submit();
            if (dut.state !== LOCKED || dut.attempts !== 2'd1)
                $fatal(1, "tamper alarm setup must retain one failed attempt");
            press_tamper();
            if (dut.state !== ALARM || dut.attempts !== 2'd1 ||
                dut.tamper_latched !== 1'b1)
                $fatal(1, "tamper alarm must retain the attempt and latch the intrusion");
        end
    endtask

    task wait_for_lockout_from_alarm;
        begin
            wait_for_state(LOCKOUT, CLK_HZ * (ALARM_SECONDS + 1) + 20);
        end
    endtask

    task send_prefix_three;
        begin
            press_left();
            if (dut.override_progress !== 2'd1 || dut.admin_sequence_valid !== 1'b0)
                $fatal(1, "first LEFT must establish progress 1 without a valid event");
            press_up();
            if (dut.override_progress !== 2'd2 || dut.admin_sequence_valid !== 1'b0)
                $fatal(1, "LEFT-UP must establish progress 2 without a valid event");
            press_left();
            if (dut.override_progress !== 2'd3 || dut.admin_sequence_valid !== 1'b0)
                $fatal(1, "LEFT-UP-LEFT must establish progress 3 without a valid event");
        end
    endtask

    task send_correct_sequence;
        begin
            press_left();
            if (dut.override_progress !== 2'd1 || dut.override_pulse !== 1'b0)
                $fatal(1, "correct sequence must begin with LEFT only");
            press_up();
            if (dut.override_progress !== 2'd2 || dut.override_pulse !== 1'b0)
                $fatal(1, "second correct sequence event must be UP");
            press_left();
            if (dut.override_progress !== 2'd3 || dut.override_pulse !== 1'b0)
                $fatal(1, "third correct sequence event must be LEFT");
            press_up();
            if (dut.override_progress !== 2'd0)
                $fatal(1, "final UP must reset sequence progress");
        end
    endtask

    task check_timers_inactive;
        begin
            repeat (2) @(posedge clk);
            #1;
            if (dut.alarm_elapsed !== 0 || dut.lockout_elapsed !== 0 ||
                dut.alarm_done !== 1'b0 || dut.lockout_done !== 1'b0)
                $fatal(1, "timers must be inactive and reset after state exit");
            if (led[2] !== 1'b0)
                $fatal(1, "alarm LED must be inactive after recovery");
        end
    endtask

    task check_recovered_to_locked;
        begin
            if (dut.state !== LOCKED || dut.attempts !== 2'd0 ||
                dut.tamper_latched !== 1'b0 || dut.alarm_request !== 1'b0 ||
                dut.admin_sequence_valid !== 1'b0 || dut.override_pulse !== 1'b0 ||
                led[0] !== 1'b1 || led[1] !== 1'b0)
                $fatal(1, "admin recovery must clear status and return only to LOCKED");
            check_timers_inactive();
        end
    endtask

    task wait_alarm_preexpiry;
        input integer target_count;
        integer cycles;
        begin
            cycles = 0;
            while (!((dut.alarm_elapsed == ALARM_SECONDS - 1) &&
                     (dut.tick_counter == target_count)) && cycles < 6 * CLK_HZ + 20) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
            if (!((dut.alarm_elapsed == ALARM_SECONDS - 1) &&
                  (dut.tick_counter == target_count)))
                $fatal(1, "alarm alignment timeout: cycles=%0d elapsed=%0d tick_counter=%0d tick=%b state=%0d",
                       cycles, dut.alarm_elapsed, dut.tick_counter, dut.tick_1hz, dut.state);
        end
    endtask

    task wait_lockout_preexpiry;
        input integer target_count;
        integer cycles;
        begin
            cycles = 0;
            while (!((dut.lockout_elapsed == LOCKOUT_SECONDS - 1) &&
                     (dut.tick_counter == target_count)) && cycles < 6 * CLK_HZ + 20) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
            if (!((dut.lockout_elapsed == LOCKOUT_SECONDS - 1) &&
                  (dut.tick_counter == target_count)))
                $fatal(1, "lockout alignment timeout: cycles=%0d elapsed=%0d tick_counter=%0d tick=%b state=%0d",
                       cycles, dut.lockout_elapsed, dut.tick_counter, dut.tick_1hz, dut.state);
        end
    endtask

    task final_up_on_alarm_expiry_done_edge;
        begin
            // Called at the pre-expiry negedge; the physical UP pulse is debounced
            // so admin_sequence_valid and alarm_done rise together after one edge.
            btnu = 1'b1;
            repeat (DEBOUNCE_CYCLES + 1) @(posedge clk);
            #1;
            if (dut.state !== ALARM || dut.alarm_done !== 1'b1 ||
                dut.admin_sequence_valid !== 1'b1 || dut.override_pulse !== 1'b1)
                $fatal(1, "ALARM boundary must present done and authorized recovery together");

            @(posedge clk);
            #1;
            if (dut.state !== LOCKED || dut.state === LOCKOUT)
                $fatal(1, "authorized recovery must take priority over ALARM expiry");
            @(negedge clk);
            btnu = 1'b0;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            #1;
        end
    endtask

    task final_up_on_lockout_expiry_done_edge;
        begin
            // Called at the pre-expiry negedge; both registered events are high
            // together before the FSM's sampling edge.
            btnu = 1'b1;
            repeat (DEBOUNCE_CYCLES + 1) @(posedge clk);
            #1;
            if (dut.state !== LOCKOUT || dut.lockout_done !== 1'b1 ||
                dut.admin_sequence_valid !== 1'b1 || dut.override_pulse !== 1'b1)
                $fatal(1, "LOCKOUT boundary must present done and authorized recovery together");

            @(posedge clk);
            #1;
            if (dut.state !== LOCKED || dut.attempts !== 2'd0 ||
                dut.tamper_latched !== 1'b0 || dut.override_pulse !== 1'b0)
                $fatal(1, "coincident LOCKOUT expiry and recovery must end in clean LOCKED");
            @(negedge clk);
            btnu = 1'b0;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            #1;
        end
    endtask

    task final_up_on_alarm_to_lockout_edge;
        begin
            // The FSM consumes alarm_done and the detector consumes UP's
            // debounced pulse on the same edge. The new LOCKOUT state remains
            // eligible, so the registered valid event is consumed one edge later.
            btnu = 1'b1;
            repeat (DEBOUNCE_CYCLES + 1) @(posedge clk);
            #1;
            if (dut.state !== LOCKOUT || dut.admin_sequence_valid !== 1'b1 ||
                dut.override_pulse !== 1'b1 || dut.attempts !== 2'd3)
                $fatal(1, "final UP recognized on ALARM-to-LOCKOUT edge must remain authorized");

            @(posedge clk);
            #1;
            if (dut.state !== LOCKED || dut.admin_sequence_valid !== 1'b0 ||
                dut.override_pulse !== 1'b0 || dut.attempts !== 2'd0 ||
                dut.tamper_latched !== 1'b0)
                $fatal(1, "pending recovery must be consumed from LOCKOUT and return cleanly to LOCKED");
            @(negedge clk);
            btnu = 1'b0;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            #1;
        end
    endtask

    task final_up_at_lockout_transition;
        begin
            // A later start makes debounce emit up_pulse on the FSM expiry edge.
            btnu = 1'b1;
            repeat (DEBOUNCE_CYCLES + 1) @(posedge clk);
            #1;
            if (dut.state !== LOCKED || dut.admin_sequence_valid !== 1'b1 ||
                dut.override_pulse !== 1'b0)
                $fatal(1, "final UP recognized during expiry must be state-blocked after LOCKED");

            @(posedge clk);
            #1;
            if (dut.state !== LOCKED || dut.admin_sequence_valid !== 1'b0 ||
                dut.override_pulse !== 1'b0 || dut.override_progress !== 2'd0)
                $fatal(1, "pending valid event must clear without a stale override");
            @(negedge clk);
            btnu = 1'b0;
            repeat (DEBOUNCE_CYCLES + 3) @(posedge clk);
            #1;
        end
    endtask

    task check_one_recovery;
        input integer old_admin_events;
        input integer old_admin_cycles;
        input integer old_override_events;
        input integer old_override_cycles;
        begin
            if (admin_event_count != old_admin_events + 1 ||
                admin_high_cycles != old_admin_cycles + 1 ||
                override_event_count != old_override_events + 1 ||
                override_high_cycles != old_override_cycles + 1)
                $fatal(1, "one correct sequence must generate one valid and one override pulse");
        end
    endtask

    initial begin
        admin_event_count = 0;
        admin_high_cycles = 0;
        override_event_count = 0;
        override_high_cycles = 0;

        // Test A: failed-attempt ALARM recovers through the registered sequence.
        apply_reset();
        enter_attempt_alarm();
        baseline_admin_events = admin_event_count;
        baseline_admin_cycles = admin_high_cycles;
        baseline_override_events = override_event_count;
        baseline_override_cycles = override_high_cycles;
        send_correct_sequence();
        check_one_recovery(baseline_admin_events, baseline_admin_cycles,
                           baseline_override_events, baseline_override_cycles);
        check_recovered_to_locked();
        $display("PASS: Test A failed-attempt ALARM recovers to LOCKED");

        // Test B: tamper ALARM clears the latch and the derived alarm request.
        apply_reset();
        enter_tamper_alarm();
        if (dut.attempts !== 2'd0 || dut.tamper_latched !== 1'b1)
            $fatal(1, "tamper recovery setup must start with only the tamper latch set");
        baseline_admin_events = admin_event_count;
        baseline_admin_cycles = admin_high_cycles;
        baseline_override_events = override_event_count;
        baseline_override_cycles = override_high_cycles;
        send_correct_sequence();
        check_one_recovery(baseline_admin_events, baseline_admin_cycles,
                           baseline_override_events, baseline_override_cycles);
        check_recovered_to_locked();
        $display("PASS: Test B tamper ALARM recovery clears tamper and alarm request");

        // Test C: admin recovery is also available before automatic LOCKOUT expiry.
        apply_reset();
        enter_attempt_alarm();
        wait_for_lockout_from_alarm();
        if (dut.attempts !== 2'd3 || dut.tamper_latched !== 1'b0)
            $fatal(1, "LOCKOUT recovery setup must retain its existing attempt status");
        baseline_admin_events = admin_event_count;
        baseline_admin_cycles = admin_high_cycles;
        baseline_override_events = override_event_count;
        baseline_override_cycles = override_high_cycles;
        send_correct_sequence();
        check_one_recovery(baseline_admin_events, baseline_admin_cycles,
                           baseline_override_events, baseline_override_cycles);
        check_recovered_to_locked();
        $display("PASS: Test C LOCKOUT recovers before automatic expiry");

        // Test D: incorrect and incomplete sequences cannot recover or clear status.
        apply_reset();
        enter_tamper_alarm_with_attempt();
        baseline_admin_events = admin_event_count;
        baseline_override_events = override_event_count;
        press_up();
        if (dut.override_progress !== 2'd0)
            $fatal(1, "UP as the first event must not advance recovery");
        press_left();
        press_left();
        if (dut.override_progress !== 2'd0)
            $fatal(1, "LEFT-LEFT must reset recovery progress");
        press_left();
        press_up();
        press_up();
        if (dut.override_progress !== 2'd0)
            $fatal(1, "LEFT-UP-UP must reset recovery progress");
        press_left();
        press_up();
        press_left();
        if (dut.override_progress !== 2'd3)
            $fatal(1, "incomplete sequence must remain partial, not authorize recovery");
        if (dut.state !== ALARM || dut.attempts !== 2'd1 ||
            dut.tamper_latched !== 1'b1 || dut.override_pulse !== 1'b0 ||
            admin_event_count != baseline_admin_events ||
            override_event_count != baseline_override_events)
            $fatal(1, "invalid sequence must preserve ALARM, attempts and tamper status");
        $display("PASS: Test D incorrect and incomplete sequences do not recover");

        // Test E: a correct user PIN remains blocked in LOCKOUT until admin recovery.
        apply_reset();
        enter_attempt_alarm();
        wait_for_lockout_from_alarm();
        switches = 16'hA5C3;
        press_submit();
        if (dut.state !== LOCKOUT || dut.attempts !== 2'd3)
            $fatal(1, "correct normal PIN must not bypass LOCKOUT");
        send_correct_sequence();
        check_recovered_to_locked();
        switches = 16'hA5C3;
        press_submit();
        if (dut.state !== UNLOCKED || dut.attempts !== 2'd0)
            $fatal(1, "normal PIN must work after admin recovery returns to LOCKED");
        $display("PASS: Test E LOCKOUT blocks PIN until recovery; PIN works afterward");

        // Test F: normal states never authorize the admin sequence.
        apply_reset();
        baseline_admin_events = admin_event_count;
        baseline_override_events = override_event_count;
        press_left();
        press_up();
        press_left();
        press_up();
        if (dut.state !== LOCKED || dut.admin_sequence_valid !== 1'b0 ||
            dut.override_pulse !== 1'b0 || dut.override_progress !== 2'd0)
            $fatal(1, "admin sequence must remain disabled while LOCKED");
        switches = 16'hA5C3;
        press_submit();
        if (dut.state !== UNLOCKED)
            $fatal(1, "disabled-state test must enter UNLOCKED through normal PIN checking");
        press_left();
        press_up();
        press_left();
        press_up();
        if (dut.state !== UNLOCKED || dut.admin_sequence_valid !== 1'b0 ||
            dut.override_pulse !== 1'b0 || dut.override_progress !== 2'd0 ||
            admin_event_count != baseline_admin_events ||
            override_event_count != baseline_override_events)
            $fatal(1, "admin sequence must not alter UNLOCKED state or status");
        $display("PASS: Test F recovery is disabled in LOCKED and UNLOCKED");

        // Test G: partial progress remains valid across ALARM-to-LOCKOUT.
        apply_reset();
        enter_attempt_alarm();
        press_left();
        press_up();
        if (dut.override_progress !== 2'd2)
            $fatal(1, "partial sequence must reach progress 2 in ALARM");
        wait_for_lockout_from_alarm();
        if (dut.override_progress !== 2'd2)
            $fatal(1, "partial sequence must survive ALARM-to-LOCKOUT");
        baseline_admin_events = admin_event_count;
        baseline_admin_cycles = admin_high_cycles;
        baseline_override_events = override_event_count;
        baseline_override_cycles = override_high_cycles;
        press_left();
        press_up();
        check_one_recovery(baseline_admin_events, baseline_admin_cycles,
                           baseline_override_events, baseline_override_cycles);
        check_recovered_to_locked();
        $display("PASS: Test G partial sequence crosses into LOCKOUT and recovers");

        // Test H: registered admin-valid and alarm_done coincide before FSM sampling.
        apply_reset();
        enter_attempt_alarm();
        send_prefix_three();
        wait_alarm_preexpiry(CLK_HZ - 3);
        baseline_admin_events = admin_event_count;
        baseline_admin_cycles = admin_high_cycles;
        baseline_override_events = override_event_count;
        baseline_override_cycles = override_high_cycles;
        final_up_on_alarm_expiry_done_edge();
        check_one_recovery(baseline_admin_events, baseline_admin_cycles,
                           baseline_override_events, baseline_override_cycles);
        check_recovered_to_locked();
        $display("PASS: Test H recovery has priority over coincident alarm expiry");

        // Test H2: final UP recognition on ALARM-to-LOCKOUT stays eligible in LOCKOUT.
        apply_reset();
        enter_attempt_alarm();
        send_prefix_three();
        wait_alarm_preexpiry(CLK_HZ - 2);
        baseline_admin_events = admin_event_count;
        baseline_admin_cycles = admin_high_cycles;
        baseline_override_events = override_event_count;
        baseline_override_cycles = override_high_cycles;
        final_up_on_alarm_to_lockout_edge();
        check_one_recovery(baseline_admin_events, baseline_admin_cycles,
                           baseline_override_events, baseline_override_cycles);
        check_recovered_to_locked();
        $display("PASS: Test H2 final UP on ALARM-to-LOCKOUT edge recovers from LOCKOUT");

        // Test I: coincident lockout_done and override clear status and recover once.
        apply_reset();
        enter_tamper_alarm_with_attempt();
        wait_for_lockout_from_alarm();
        send_prefix_three();
        wait_lockout_preexpiry(CLK_HZ - 3);
        baseline_admin_events = admin_event_count;
        baseline_admin_cycles = admin_high_cycles;
        baseline_override_events = override_event_count;
        baseline_override_cycles = override_high_cycles;
        final_up_on_lockout_expiry_done_edge();
        check_one_recovery(baseline_admin_events, baseline_admin_cycles,
                           baseline_override_events, baseline_override_cycles);
        check_recovered_to_locked();
        if (admin_event_count != baseline_admin_events + 1 ||
            override_event_count != baseline_override_events + 1)
            $fatal(1, "coincident recovery must not retrigger after returning LOCKED");
        $display("PASS: Test I coincident lockout expiry and admin recovery clear status once");

        // Test J: final UP recognized on the LOCKOUT-to-LOCKED transition is state-blocked.
        apply_reset();
        enter_attempt_alarm();
        wait_for_lockout_from_alarm();
        send_prefix_three();
        wait_lockout_preexpiry(CLK_HZ - 2);
        baseline_admin_events = admin_event_count;
        baseline_override_events = override_event_count;
        final_up_at_lockout_transition();
        if (admin_event_count != baseline_admin_events + 1 ||
            override_event_count != baseline_override_events)
            $fatal(1, "final UP at expiry must be recognized but blocked after LOCKED");
        switches = 16'hA5C3;
        press_submit();
        if (dut.state !== UNLOCKED)
            $fatal(1, "no stale override may block subsequent normal authentication");
        $display("PASS: Test J final UP at automatic expiry creates no stale override");

        // Test K: reset cancels a pending recovery event before the FSM consumes it.
        apply_reset();
        enter_tamper_alarm_with_attempt();
        send_prefix_three();
        baseline_admin_events = admin_event_count;
        @(negedge clk);
        btnu = 1'b1;
        wait_cycles = 0;
        while (dut.admin_sequence_valid !== 1'b1 && wait_cycles < 12) begin
            @(posedge clk);
            #1;
            wait_cycles = wait_cycles + 1;
        end
        if (dut.admin_sequence_valid !== 1'b1 || dut.override_pulse !== 1'b1)
            $fatal(1, "reset test setup must create a pending authorized recovery");
        @(negedge clk);
        resetn = 1'b0;
        btnu = 1'b0;
        repeat (2) @(posedge clk);
        #1;
        if (dut.state !== LOCKED || dut.attempts !== 2'd0 ||
            dut.tamper_latched !== 1'b0 || dut.override_progress !== 2'd0 ||
            dut.admin_sequence_valid !== 1'b0 || dut.override_pulse !== 1'b0 ||
            admin_event_count != baseline_admin_events + 1)
            $fatal(1, "reset must cancel the pending recovery and clear its stale event");
        if (dut.alarm_elapsed !== 0 || dut.lockout_elapsed !== 0 || led[2] !== 1'b0)
            $fatal(1, "reset during pending recovery must clear timer and alarm outputs");
        @(negedge clk);
        resetn = 1'b1;
        repeat (2) @(posedge clk);
        #1;
        if (dut.override_pulse !== 1'b0 || dut.admin_sequence_valid !== 1'b0)
            $fatal(1, "no recovery event may remain after reset release");
        $display("PASS: Test K reset cancels pending recovery and clears all state");

        // Test L: repeated alarm/recovery cycles do not carry stale status or timers.
        apply_reset();
        enter_attempt_alarm();
        baseline_admin_events = admin_event_count;
        baseline_admin_cycles = admin_high_cycles;
        baseline_override_events = override_event_count;
        baseline_override_cycles = override_high_cycles;
        send_correct_sequence();
        check_one_recovery(baseline_admin_events, baseline_admin_cycles,
                           baseline_override_events, baseline_override_cycles);
        check_recovered_to_locked();

        enter_tamper_alarm();
        if (dut.attempts !== 2'd0 || dut.tamper_latched !== 1'b1 ||
            dut.alarm_done !== 1'b0 || dut.alarm_elapsed >= ALARM_SECONDS)
            $fatal(1, "second alarm must start with fresh timer and status state");
        baseline_admin_events = admin_event_count;
        baseline_admin_cycles = admin_high_cycles;
        baseline_override_events = override_event_count;
        baseline_override_cycles = override_high_cycles;
        send_correct_sequence();
        check_one_recovery(baseline_admin_events, baseline_admin_cycles,
                           baseline_override_events, baseline_override_cycles);
        check_recovered_to_locked();
        switches = 16'hA5C3;
        press_submit();
        if (dut.state !== UNLOCKED || dut.attempts !== 2'd0)
            $fatal(1, "normal PIN must still work after repeated recovery cycles");
        $display("PASS: Test L repeated alarm/recovery cycles restart cleanly");

        $display("PASS: Member 3 Phase 5 admin recovery verification");
        $finish;
    end
endmodule
