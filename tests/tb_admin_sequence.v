`timescale 1ns/1ps
module tb_admin_sequence;
    reg clk=1'b0, rst=1'b1, left_press_pulse=1'b0, up_press_pulse=1'b0;
    wire [1:0] progress;
    wire sequence_done_pulse;
    always #5 clk=~clk;
    admin_sequence dut(.*);

    task press_left;
        begin
            @(negedge clk); left_press_pulse=1'b1;
            @(posedge clk); #1;
            @(negedge clk); left_press_pulse=1'b0;
        end
    endtask
    task press_up;
        begin
            @(negedge clk); up_press_pulse=1'b1;
            @(posedge clk); #1;
            @(negedge clk); up_press_pulse=1'b0;
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        #1;
        if (progress !== 0 || sequence_done_pulse !== 0) $fatal(1, "reset state");
        @(negedge clk); rst=1'b0;

        press_up();
        if (progress !== 0 || sequence_done_pulse !== 0) $fatal(1, "wrong first step must reset");
        press_left();
        if (progress !== 1) $fatal(1, "LEFT prefix");
        press_left();
        if (progress !== 1) $fatal(1, "wrong LEFT must restart at a fresh prefix");
        press_up();
        if (progress !== 2) $fatal(1, "LEFT-UP prefix");
        press_up();
        if (progress !== 0) $fatal(1, "wrong UP after LEFT-UP must reset");

        press_left();
        press_up();
        if (progress !== 2) $fatal(1, "second valid prefix");
        press_left();
        if (progress !== 3) $fatal(1, "LEFT-UP-LEFT prefix");
        press_up();
        if (progress !== 0 || sequence_done_pulse !== 1'b1)
            $fatal(1, "complete sequence must pulse done and clear progress");
        @(posedge clk); #1;
        if (sequence_done_pulse !== 1'b0) $fatal(1, "done event must last one cycle");

        // Simultaneous inputs are rejected, not interpreted as two steps.
        @(negedge clk); left_press_pulse=1'b1; up_press_pulse=1'b1;
        @(posedge clk); #1;
        if (progress !== 0 || sequence_done_pulse !== 0)
            $fatal(1, "simultaneous LEFT and UP must reset sequence");
        $display("PASS: admin sequence order, wrong-step recovery and pulse timing");
        $finish;
    end
endmodule
