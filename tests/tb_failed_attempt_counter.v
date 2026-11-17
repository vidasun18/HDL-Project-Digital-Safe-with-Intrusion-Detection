`timescale 1ns/1ps
module tb_failed_attempt_counter;
    reg clk=1'b0, rst=1'b1, wrong_pin_pulse=1'b0, clear_attempts=1'b0;
    wire [1:0] failed_count;
    wire third_failure;
    always #5 clk=~clk;
    failed_attempt_counter dut(.*);

    task fail_once;
        begin
            @(negedge clk); wrong_pin_pulse=1'b1;
            @(posedge clk); #1;
            @(negedge clk); wrong_pin_pulse=1'b0;
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        #1;
        if (failed_count !== 2'd0 || third_failure !== 1'b0)
            $fatal(1, "reset must clear count and warning");
        @(negedge clk); rst=1'b0;
        fail_once();
        if (failed_count !== 2'd1 || third_failure !== 1'b0) $fatal(1, "first failure count");
        fail_once();
        if (failed_count !== 2'd2 || third_failure !== 1'b1) $fatal(1, "third warning must precede next failure");
        fail_once();
        if (failed_count !== 2'd3 || third_failure !== 1'b1) $fatal(1, "third failure must saturate at three");
        fail_once();
        if (failed_count !== 2'd3) $fatal(1, "counter must remain saturated");

        @(negedge clk); clear_attempts=1'b1; wrong_pin_pulse=1'b1;
        @(posedge clk); #1;
        if (failed_count !== 2'd0 || third_failure !== 1'b0)
            $fatal(1, "clear must win over simultaneous increment");
        @(negedge clk); clear_attempts=1'b0; wrong_pin_pulse=1'b0;
        $display("PASS: failed counter threshold, saturation, and clear priority");
        $finish;
    end
endmodule
