`timescale 1ns/1ps

module tb_member1_pin_fsm;
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
    integer failure_events;

    digital_safe #(
        .DEBOUNCE_CYCLES(4)
    ) dut (
        .CLK100MHZ(clk),
        .CPU_RESETN(resetn),
        .SW(switches),
        .BTNC(btnc), .BTNU(btnu), .BTNL(btnl), .BTNR(btnr), .BTND(btnd),
        .LED(led), .SEG(seg), .AN(an), .DP(dp)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!resetn)
            failure_events <= 0;
        else if (dut.failed_check)
            failure_events <= failure_events + 1;
    end

    task press_submit;
        begin
            @(negedge clk);
            btnc = 1'b1;
            repeat (8) @(posedge clk);
            @(negedge clk);
            btnc = 1'b0;
            repeat (5) @(posedge clk);
            #1;
        end
    endtask

    task press_lock;
        begin
            @(negedge clk);
            btnd = 1'b1;
            repeat (8) @(posedge clk);
            @(negedge clk);
            btnd = 1'b0;
            repeat (5) @(posedge clk);
            #1;
        end
    endtask

    initial begin
        failure_events = 0;

        @(negedge clk);
        resetn = 1'b0;
        @(posedge clk);
        #1;
        if (dut.state !== 3'd0 || dut.captured_pin !== 16'h0000)
            $fatal(1, "reset must clear the captured PIN and leave the safe locked");

        @(negedge clk);
        resetn = 1'b1;
        repeat (2) @(posedge clk);

        // A short bounce must not become a submit event.
        @(negedge clk);
        btnc = 1'b1;
        repeat (2) @(posedge clk);
        @(negedge clk);
        btnc = 1'b0;
        repeat (8) @(posedge clk);
        #1;
        if (dut.state !== 3'd0 || failure_events != 0)
            $fatal(1, "button bounce must not submit a PIN");

        switches = 16'h0000;
        press_submit();
        if (dut.state !== 3'd0 || failure_events != 1)
            $fatal(1, "a wrong PIN must remain locked and report one failure");

        press_submit();
        if (dut.state !== 3'd0 || failure_events != 2)
            $fatal(1, "each separate wrong-PIN press must report one failure");

        switches = 16'hA5C3;
        press_submit();
        if (dut.state !== 3'd2 || led[0] !== 1'b0 || led[1] !== 1'b1 ||
            failure_events != 2)
            $fatal(1, "the configured PIN must unlock the safe");

        switches = 16'h0000;
        press_submit();
        if (dut.state !== 3'd2 || failure_events != 2)
            $fatal(1, "PIN submissions while unlocked must not start another check");

        press_lock();
        if (dut.state !== 3'd0 || led[0] !== 1'b1 || led[1] !== 1'b0)
            $fatal(1, "the manual lock button must return the safe to locked");

        $display("PASS: Member 1 debounce, PIN checking, and main FSM");
        $finish;
    end
endmodule
