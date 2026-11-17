`timescale 1ns/1ps
module tb_recovery_controller;
    reg clk=1'b0, rst=1'b1, sequence_done_pulse=1'b0;
    reg [15:0] switch_value=16'h0000;
    wire admin_recover_pulse;
    always #5 clk=~clk;
    recovery_controller #(.ADMIN_CODE(16'hBEEF)) dut(.*);

    task complete_sequence;
        begin
            @(negedge clk); sequence_done_pulse=1'b1;
            @(posedge clk); #1;
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        #1;
        if (admin_recover_pulse !== 1'b0) $fatal(1, "reset must clear recovery event");
        @(negedge clk); rst=1'b0; switch_value=16'hBEEE;
        complete_sequence();
        if (admin_recover_pulse !== 1'b0)
            $fatal(1, "correct sequence with wrong code must not recover");
        @(negedge clk); sequence_done_pulse=1'b0; switch_value=16'hBEEF;
        @(posedge clk); #1;
        if (admin_recover_pulse !== 1'b0)
            $fatal(1, "correct code without a sequence event must not recover");
        complete_sequence();
        if (admin_recover_pulse !== 1'b1)
            $fatal(1, "sequence and matching code must produce recovery pulse");
        @(negedge clk); sequence_done_pulse=1'b0;
        @(posedge clk); #1;
        if (admin_recover_pulse !== 1'b0)
            $fatal(1, "recovery event must last one cycle");
        $display("PASS: recovery requires sequence and matching admin code");
        $finish;
    end
endmodule
