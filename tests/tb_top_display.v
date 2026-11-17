`timescale 1ns/1ps
module tb_top_display;
    reg clk=1'b0;
    reg resetn=1'b0;
    reg [15:0] sw=16'h0000;
    reg btnc=1'b0, btnu=1'b0, btnl=1'b0, btnr=1'b0, btnd=1'b0;
    wire [15:0] led;
    wire [6:0] seg;
    wire [7:0] an;
    wire dp;

    always #5 clk=~clk;
    digital_safe #(.CLK_HZ(10), .DEBOUNCE_CYCLES(2),
        .ALARM_SECONDS(2), .LOCKOUT_SECONDS(3)) dut (
        .CLK100MHZ(clk), .CPU_RESETN(resetn), .SW(sw),
        .BTNC(btnc), .BTNU(btnu), .BTNL(btnl), .BTNR(btnr), .BTND(btnd),
        .LED(led), .SEG(seg), .AN(an), .DP(dp)
    );

    initial begin
        repeat (3) @(posedge clk);
        #1;
        if (dut.display_value !== 32'h1000_0000)
            $fatal(1, "reset display must show LOCKED and zeros: %h", dut.display_value);
        if (dp !== 1'b1 || an !== 8'hFE)
            $fatal(1, "top-level display must keep DP off and scan one digit");
        if (led[4] !== 1'b0 || led[3] !== 1'b0)
            $fatal(1, "LED[4] reserved and LED[3] lockout must be clear when locked");

        // Exercise the display integration without depending on alarm timing.
        @(negedge clk);
        dut.state=3'd3;
        dut.attempt_reg=2'd2;
        #1;
        if (dut.display_value !== 32'hA200_0002)
            $fatal(1, "top-level ALARM/countdown format mismatch: %h", dut.display_value);
        dut.state=3'd4;
        #1;
        if (dut.display_value !== 32'hD200_0003)
            $fatal(1, "top-level LOCKOUT/countdown format mismatch: %h", dut.display_value);

        $display("PASS: top-level status, attempt, countdown and display wiring");
        $finish;
    end
endmodule
