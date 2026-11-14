`timescale 1ns/1ps

module tb_member2_timing_alarm;
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

    // Use fast scaled parameters for simulation
    localparam integer CLK_HZ = 20;
    localparam integer DEBOUNCE = 2;
    localparam integer ALARM_SEC = 2;
    localparam integer LOCKOUT_SEC = 3;

    digital_safe #(
        .CLK_HZ(CLK_HZ),
        .DEBOUNCE_CYCLES(DEBOUNCE),
        .ALARM_SECONDS(ALARM_SEC),
        .LOCKOUT_SECONDS(LOCKOUT_SEC),
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

    task press_submit;
        begin
            @(negedge clk);
            btnc = 1'b1;
            repeat (DEBOUNCE + 2) @(posedge clk);
            @(negedge clk);
            btnc = 1'b0;
            repeat (DEBOUNCE + 2) @(posedge clk);
            #1;
        end
    endtask

    task press_tamper;
        begin
            @(negedge clk);
            btnr = 1'b1;
            repeat (DEBOUNCE + 2) @(posedge clk);
            @(negedge clk);
            btnr = 1'b0;
            repeat (DEBOUNCE + 2) @(posedge clk);
            #1;
        end
    endtask

    integer blink_seen;

    initial begin
        @(negedge clk);
        resetn = 1'b0;
        @(posedge clk);
        #1;
        resetn = 1'b1;
        repeat (2) @(posedge clk);
        #1;

        if (dut.state !== 3'd0 || dut.attempts !== 2'd0)
            $fatal(1, "initial state must be LOCKED with 0 attempts");

        // 1st wrong attempt
        switches = 16'h1111;
        press_submit();
        if (dut.attempts !== 2'd1 || dut.state !== 3'd0)
            $fatal(1, "attempt 1 must increment attempts to 1 and remain LOCKED");

        // 2nd wrong attempt
        switches = 16'h2222;
        press_submit();
        if (dut.attempts !== 2'd2 || dut.state !== 3'd0)
            $fatal(1, "attempt 2 must increment attempts to 2 and remain LOCKED");

        // 3rd wrong attempt -> three strikes trigger alarm!
        switches = 16'h3333;
        press_submit();
        repeat (2) @(posedge clk);
        #1;
        if (dut.attempts !== 2'd3 || dut.state !== 3'd3)
            $fatal(1, "attempt 3 must trigger limit_violation and transition to ALARM");

        // Verify alarm blinking in ALARM state
        blink_seen = 0;
        repeat (CLK_HZ * ALARM_SEC + 5) begin
            @(posedge clk);
            if (dut.state == 3'd3 && led[2] == 1'b1)
                blink_seen = blink_seen + 1;
        end

        if (blink_seen == 0)
            $fatal(1, "alarm LED must blink during ALARM state");

        // Wait until safe transitions from ALARM to LOCKOUT
        while (dut.state == 3'd3) @(posedge clk);

        if (dut.state !== 3'd4)
            $fatal(1, "safe must transition from ALARM to LOCKOUT after ALARM duration");

        // Wait through LOCKOUT duration
        while (dut.state == 3'd4) @(posedge clk);

        repeat (2) @(posedge clk);
        #1;
        if (dut.state !== 3'd0 || dut.attempts !== 2'd0)
            $fatal(1, "safe must return to LOCKED with attempts cleared after LOCKOUT");

        // Test tamper detection while locked
        press_tamper();
        repeat (2) @(posedge clk);
        #1;
        if (dut.tamper_latched !== 1'b1 || dut.state !== 3'd3)
            $fatal(1, "tamper button while locked must latch tamper and trigger ALARM");

        // Wait through tamper alarm and lockout back to locked
        while (dut.state == 3'd3 || dut.state == 3'd4) @(posedge clk);
        repeat (2) @(posedge clk);
        #1;
        if (dut.state !== 3'd0 || dut.tamper_latched !== 1'b0)
            $fatal(1, "tamper_latched must clear after lockout finishes");

        // Test successful unlock resets attempt count
        switches = 16'h1111;
        press_submit(); // 1 wrong attempt
        if (dut.attempts !== 2'd1)
            $fatal(1, "attempt must be 1 after wrong PIN");

        switches = 16'hA5C3; // correct PIN
        press_submit();
        if (dut.state !== 3'd2 || dut.attempts !== 2'd0)
            $fatal(1, "correct PIN must unlock and clear attempt count");

        $display("PASS: Member 2 failed attempts, timers, tamper intrusion, and alarm blinking");
        $finish;
    end
endmodule
