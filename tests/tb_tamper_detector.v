`timescale 1ns/1ps
module tb_tamper_detector;
    reg clk=1'b0, rst=1'b1, tamper_press_pulse=1'b0, clear_tamper=1'b0;
    wire tamper_latched, tamper_event_pulse;
    always #5 clk=~clk;
    tamper_detector dut(.*);

    initial begin
        repeat (2) @(posedge clk);
        #1;
        if (tamper_latched !== 1'b0 || tamper_event_pulse !== 1'b0)
            $fatal(1, "reset must clear tamper state");
        @(negedge clk); rst=1'b0; tamper_press_pulse=1'b1;
        @(posedge clk); #1;
        if (tamper_latched !== 1'b1 || tamper_event_pulse !== 1'b1)
            $fatal(1, "tamper press must latch and emit an event pulse");
        @(negedge clk); tamper_press_pulse=1'b0;
        @(posedge clk); #1;
        if (tamper_latched !== 1'b1 || tamper_event_pulse !== 1'b0)
            $fatal(1, "evidence must remain latched after the event pulse");

        @(negedge clk); clear_tamper=1'b1;
        @(posedge clk); #1;
        if (tamper_latched !== 1'b0) $fatal(1, "validated clear must clear the latch");
        @(negedge clk); clear_tamper=1'b0;

        // Simultaneous new evidence must not be erased by recovery.
        tamper_press_pulse=1'b1; clear_tamper=1'b1;
        @(posedge clk); #1;
        if (tamper_latched !== 1'b1 || tamper_event_pulse !== 1'b1)
            $fatal(1, "new tamper evidence must win over simultaneous clear");

        @(negedge clk); tamper_press_pulse=1'b0; clear_tamper=1'b0; rst=1'b1;
        @(posedge clk); #1;
        if (tamper_latched !== 1'b0 || tamper_event_pulse !== 1'b0)
            $fatal(1, "reset must clear latched evidence and event");
        $display("PASS: tamper latch, event pulse, validated clear and priority");
        $finish;
    end
endmodule
