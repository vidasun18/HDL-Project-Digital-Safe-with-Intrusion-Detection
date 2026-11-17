`timescale 1ns/1ps

module tb_member3_admin_progress_leds;
    localparam integer CLK_HZ = 100;
    localparam integer DEBOUNCE_CYCLES = 3;
    localparam integer ALARM_SECONDS = 8;
    localparam integer LOCKOUT_SECONDS = 8;

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

    task check_progress;
        input [2:0] expected;
        begin
            #1;
            if (led[8:6] !== expected)
                $fatal(1, "admin progress LEDs: expected LED[8:6]=%03b, got %03b in state %0d",
                       expected, led[8:6], dut.state);
            if (led[15:9] !== 7'b0)
                $fatal(1, "unallocated LED[15:9] must remain zero, got %07b", led[15:9]);
        end
    endtask

    task check_existing_leds;
        begin
            #1;
            if (led[0] !== (dut.state != UNLOCKED) ||
                led[1] !== (dut.state == UNLOCKED) ||
                led[2] !== dut.alarm_led ||
                led[3] !== (dut.state == LOCKOUT) ||
                led[4] !== 1'b0 ||
                led[5] !== dut.tamper_latched)
                $fatal(1, "LED[5:0] contract mismatch in state %0d", dut.state);
            if (led[15:9] !== 7'b0)
                $fatal(1, "LED[15:9] must preserve their existing zero values");
        end
    endtask

    task apply_reset;
        begin
            @(negedge clk);
            resetn = 1'b0;
            repeat (2) @(posedge clk);
            #1;
            if (dut.state !== LOCKED || dut.attempts !== 2'd0 ||
                dut.tamper_latched !== 1'b0 || dut.admin_sequence_valid !== 1'b0 ||
                dut.override_progress !== 2'd0)
                $fatal(1, "reset must return the safe and admin detector to their initial state");
            check_progress(3'b000);
            check_existing_leds();

            @(negedge clk);
            resetn = 1'b1;
            repeat (2) @(posedge clk);
            #1;
            if (dut.state !== LOCKED)
                $fatal(1, "reset release must leave the safe LOCKED");
            check_progress(3'b000);
            check_existing_leds();
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

    task press_simultaneous_left_up;
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

    task hold_left_once;
        begin
            @(negedge clk);
            btnl = 1'b1;
            repeat (30) @(posedge clk);
            #1;
            if (dut.override_progress !== 2'd1)
                $fatal(1, "held LEFT must advance the detector exactly once");
            check_progress(3'b001);
            repeat (20) @(posedge clk);
            #1;
            if (dut.override_progress !== 2'd1)
                $fatal(1, "continued LEFT hold must not repeat the progress event");
            check_progress(3'b001);
            @(negedge clk);
            btnl = 1'b0;
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
                $fatal(1, "failed-attempt setup requires LOCKED");
            switches = 16'h1111;
            press_submit();
            if (dut.state !== LOCKED || dut.attempts !== 2'd1)
                $fatal(1, "first incorrect PIN must produce one attempt");
            switches = 16'h2222;
            press_submit();
            if (dut.state !== LOCKED || dut.attempts !== 2'd2)
                $fatal(1, "second incorrect PIN must produce two attempts");
            switches = 16'h3333;
            press_submit();
            repeat (2) @(posedge clk);
            #1;
            if (dut.state !== ALARM || dut.attempts !== 2'd3)
                $fatal(1, "third incorrect PIN must enter ALARM at the configured limit");
            check_existing_leds();
        end
    endtask

    task enter_tamper_alarm;
        begin
            if (dut.state !== LOCKED)
                $fatal(1, "tamper setup requires LOCKED");
            press_tamper();
            if (dut.state !== ALARM || dut.tamper_latched !== 1'b1)
                $fatal(1, "tamper while LOCKED must latch and enter ALARM");
            check_existing_leds();
        end
    endtask

    task enter_tamper_alarm_with_attempt;
        begin
            if (dut.state !== LOCKED)
                $fatal(1, "combined tamper setup requires LOCKED");
            switches = 16'h1111;
            press_submit();
            if (dut.state !== LOCKED || dut.attempts !== 2'd1)
                $fatal(1, "combined setup must retain one failed attempt");
            press_tamper();
            if (dut.state !== ALARM || dut.attempts !== 2'd1 ||
                dut.tamper_latched !== 1'b1)
                $fatal(1, "tamper ALARM must retain attempts and latch tamper");
            check_existing_leds();
        end
    endtask

    task wait_for_lockout;
        begin
            wait_for_state(LOCKOUT, CLK_HZ * (ALARM_SECONDS + 1) + 50);
            check_existing_leds();
        end
    endtask

    task complete_admin_sequence;
        begin
            press_left();
            check_progress(3'b001);
            press_up();
            check_progress(3'b011);
            press_left();
            check_progress(3'b111);
            if (dut.state !== ALARM && dut.state !== LOCKOUT)
                $fatal(1, "partial sequence must not recover before final UP");
            press_up();
            if (dut.state !== LOCKED || dut.attempts !== 2'd0 ||
                dut.tamper_latched !== 1'b0 || dut.admin_sequence_valid !== 1'b0 ||
                dut.override_pulse !== 1'b0)
                $fatal(1, "successful admin recovery must return to clean LOCKED");
            check_progress(3'b000);
            check_existing_leds();
            if (led[2] !== 1'b0 || led[0] !== 1'b1 || led[1] !== 1'b0)
                $fatal(1, "recovery must show LOCKED and clear the alarm indicator");
        end
    endtask

    initial begin
        apply_reset();

        // Test A: reset, LOCKED, UNLOCKED, and state-disabled admin input.
        press_left();
        check_progress(3'b000);
        press_up();
        press_left();
        press_up();
        if (dut.state !== LOCKED)
            $fatal(1, "admin buttons outside ALARM/LOCKOUT must not leave LOCKED");
        check_progress(3'b000);
        switches = 16'hA5C3;
        press_submit();
        if (dut.state !== UNLOCKED || led[0] !== 1'b0 || led[1] !== 1'b1)
            $fatal(1, "correct PIN must preserve the existing UNLOCKED indicators");
        press_left();
        press_up();
        press_left();
        press_up();
        if (dut.state !== UNLOCKED)
            $fatal(1, "admin sequence must not recover or alter UNLOCKED");
        check_progress(3'b000);
        check_existing_leds();
        $display("PASS: Test A reset and normal states keep progress LEDs off");

        // Test B: cumulative progress indication and immediate clear on recovery.
        apply_reset();
        enter_attempt_alarm();
        check_progress(3'b000);
        complete_admin_sequence();
        $display("PASS: Test B LED sequence is 000 -> 001 -> 011 -> 111 -> 000");

        // Test C: incorrect events at each progress position clear the display.
        apply_reset();
        enter_tamper_alarm_with_attempt();
        press_up();
        check_progress(3'b000);
        press_left();
        check_progress(3'b001);
        press_left();
        check_progress(3'b000);
        press_left();
        press_up();
        check_progress(3'b011);
        press_up();
        check_progress(3'b000);
        press_left();
        press_up();
        press_left();
        check_progress(3'b111);
        press_left();
        if (dut.state !== ALARM || dut.admin_sequence_valid !== 1'b0 ||
            dut.override_pulse !== 1'b0 || dut.attempts !== 2'd1 ||
            dut.tamper_latched !== 1'b1)
            $fatal(1, "incorrect sequence inputs must not recover or clear security status");
        check_progress(3'b000);
        $display("PASS: Test C incorrect sequence events clear progress LEDs");

        // Test D: simultaneous LEFT and UP resets partial progress.
        apply_reset();
        enter_attempt_alarm();
        press_left();
        check_progress(3'b001);
        press_simultaneous_left_up();
        if (dut.state !== ALARM || dut.admin_sequence_valid !== 1'b0 ||
            dut.override_pulse !== 1'b0)
            $fatal(1, "simultaneous buttons must not authorize recovery");
        check_progress(3'b000);
        $display("PASS: Test D simultaneous LEFT and UP clears progress LEDs");

        // Test E: held and unrelated buttons cannot advance the indication.
        apply_reset();
        enter_attempt_alarm();
        hold_left_once();
        switches = 16'hA5C3;
        press_submit();
        press_lock();
        press_tamper();
        if (dut.state !== ALARM || dut.override_progress !== 2'd1 ||
            dut.admin_sequence_valid !== 1'b0)
            $fatal(1, "unrelated inputs must not change admin progress in ALARM");
        check_progress(3'b001);
        check_existing_leds();
        $display("PASS: Test E held LEFT counts once and unrelated buttons do not advance");

        // Test F: partial progress remains visible over ALARM-to-LOCKOUT.
        apply_reset();
        enter_attempt_alarm();
        press_left();
        press_up();
        check_progress(3'b011);
        wait_for_lockout();
        if (dut.override_progress !== 2'd2)
            $fatal(1, "LEFT-UP prefix must survive the state handoff");
        check_progress(3'b011);
        press_left();
        check_progress(3'b111);
        press_up();
        if (dut.state !== LOCKED)
            $fatal(1, "finishing the retained prefix must recover to LOCKED");
        check_progress(3'b000);
        check_existing_leds();
        $display("PASS: Test F partial progress remains visible across ALARM-to-LOCKOUT");

        // Test G: automatic lockout expiry clears partial progress and status.
        apply_reset();
        enter_tamper_alarm_with_attempt();
        wait_for_lockout();
        press_left();
        press_up();
        press_left();
        check_progress(3'b111);
        wait_for_state(LOCKED, CLK_HZ * (LOCKOUT_SECONDS + 1) + 50);
        repeat (2) @(posedge clk);
        #1;
        if (dut.attempts !== 2'd0 || dut.tamper_latched !== 1'b0 ||
            dut.admin_sequence_valid !== 1'b0)
            $fatal(1, "automatic lockout expiry must retain its existing clearing behavior");
        check_progress(3'b000);
        check_existing_leds();
        $display("PASS: Test G automatic lockout expiry clears progress and status LEDs");

        // Test H: active-low reset clears progress while ALARM is active.
        apply_reset();
        enter_attempt_alarm();
        press_left();
        press_up();
        check_progress(3'b011);
        @(negedge clk);
        resetn = 1'b0;
        repeat (2) @(posedge clk);
        #1;
        if (dut.state !== LOCKED || dut.attempts !== 2'd0 ||
            dut.tamper_latched !== 1'b0 || dut.override_progress !== 2'd0)
            $fatal(1, "reset during partial progress must clear the detector and security state");
        check_progress(3'b000);
        check_existing_leds();
        @(negedge clk);
        resetn = 1'b1;
        repeat (2) @(posedge clk);
        #1;
        $display("PASS: Test H reset during partial progress clears LEDs");

        // Test I: LED[0:5] remain mapped and LED[9:15] remain unused.
        apply_reset();
        enter_tamper_alarm_with_attempt();
        if (led[5] !== 1'b1 || dut.attempts !== 2'd1 || led[3] !== 1'b0 || led[4] !== 1'b0)
            $fatal(1, "tamper, attempt count and lockout mapping must match the interface contract");
        press_left();
        press_up();
        check_progress(3'b011);
        check_existing_leds();
        wait_for_lockout();
        check_progress(3'b011);
        check_existing_leds();
        if (led[5] !== 1'b1 || dut.attempts !== 2'd1 || led[15:9] !== 7'b0)
            $fatal(1, "admin LEDs must not disturb attempts, tamper, or unused LED outputs");
        $display("PASS: Test I existing status LEDs and unallocated LEDs are preserved");

        // Test J: separate recovery cycles start and finish with no stale progress.
        apply_reset();
        enter_attempt_alarm();
        check_progress(3'b000);
        complete_admin_sequence();
        enter_tamper_alarm();
        check_progress(3'b000);
        complete_admin_sequence();
        if (led[8:6] !== 3'b000 || dut.state !== LOCKED)
            $fatal(1, "repeated recovery cycle must not retain progress indication");
        $display("PASS: Test J repeated recovery cycles clear stale progress LEDs");

        $display("PASS: Member 3 Phase 6 admin progress LED verification");
        $finish;
    end
endmodule
