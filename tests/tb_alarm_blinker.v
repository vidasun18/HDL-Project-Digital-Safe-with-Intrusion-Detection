`timescale 1ns/1ps
module tb_alarm_blinker;
    reg clk=1'b0, rst=1'b1, tick_1hz=1'b0, alarm_active=1'b0;
    wire blink_led;
    always #5 clk=~clk;
    alarm_blinker dut(.*);

    task tick;
        begin
            @(negedge clk); tick_1hz=1'b1;
            @(posedge clk); #1;
            @(negedge clk); tick_1hz=1'b0;
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        #1;
        if (blink_led !== 1'b0) $fatal(1, "reset must turn alarm LED off");
        @(negedge clk); rst=1'b0; alarm_active=1'b1;
        @(posedge clk); #1;
        if (blink_led !== 1'b0) $fatal(1, "LED must hold without a tick");
        tick();
        if (blink_led !== 1'b1) $fatal(1, "first active tick turns LED on");
        tick();
        if (blink_led !== 1'b0) $fatal(1, "second active tick turns LED off");
        @(negedge clk); alarm_active=1'b0; tick_1hz=1'b1;
        @(posedge clk); #1;
        if (blink_led !== 1'b0) $fatal(1, "outside alarm LED must remain off");
        @(negedge clk); tick_1hz=1'b0;
        $display("PASS: alarm blinker reset, tick toggling, and inactive behavior");
        $finish;
    end
endmodule
