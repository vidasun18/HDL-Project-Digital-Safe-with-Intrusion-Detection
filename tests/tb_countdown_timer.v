`timescale 1ns/1ps
module tb_countdown_timer;
    reg clk=1'b0, rst=1'b1, tick_1hz=1'b0, start_pulse=1'b0, cancel=1'b0;
    reg [7:0] duration_seconds=8'd0;
    wire [7:0] remaining_seconds;
    wire done_pulse;
    always #5 clk=~clk;
    countdown_timer #(.MAX_SECONDS(4)) dut(.*);

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
        if (remaining_seconds !== 0 || done_pulse !== 0) $fatal(1, "reset values");
        @(negedge clk); rst=1'b0; duration_seconds=8'd3; start_pulse=1'b1;
        @(posedge clk); #1;
        if (remaining_seconds !== 3 || done_pulse !== 0) $fatal(1, "start must load duration");
        @(negedge clk); start_pulse=1'b0;
        tick();
        if (remaining_seconds !== 2 || done_pulse !== 0)
            $fatal(1, "first tick must decrement to two without completing");
        tick();
        if (remaining_seconds !== 1 || done_pulse !== 0)
            $fatal(1, "second tick must decrement to one without completing");
        tick();
        if (remaining_seconds !== 0 || done_pulse !== 1) $fatal(1, "last tick must finish once");
        tick();
        if (done_pulse !== 0) $fatal(1, "done must be a one-cycle pulse");

        // A new start replaces an active timer and wins over a coincident tick.
        @(negedge clk); duration_seconds=8'd3; start_pulse=1'b1;
        @(posedge clk); #1;
        if (remaining_seconds !== 3) $fatal(1, "restart setup must load three");
        @(negedge clk); start_pulse=1'b0;
        tick();
        if (remaining_seconds !== 2) $fatal(1, "restart setup must leave an active timer");
        @(negedge clk); duration_seconds=8'd8; start_pulse=1'b1; tick_1hz=1'b1;
        @(posedge clk); #1;
        if (remaining_seconds !== 4) $fatal(1, "restart must load clamped duration before tick");
        @(negedge clk); duration_seconds=8'd1; start_pulse=1'b1; cancel=1'b1;
        @(posedge clk); #1;
        if (remaining_seconds !== 0 || done_pulse !== 0) $fatal(1, "cancel must beat simultaneous start and tick");
        @(negedge clk); cancel=1'b0; start_pulse=1'b0; tick_1hz=1'b0;

        duration_seconds=8'd2; start_pulse=1'b1;
        @(posedge clk); #1;
        @(negedge clk); start_pulse=1'b0; rst=1'b1;
        @(posedge clk); #1;
        if (remaining_seconds !== 0 || done_pulse !== 0) $fatal(1, "reset must cancel timer");
        @(negedge clk); rst=1'b0; duration_seconds=8'd0; start_pulse=1'b1;
        @(posedge clk); #1;
        if (remaining_seconds !== 0 || done_pulse !== 1) $fatal(1, "zero duration must complete immediately");

        $display("PASS: countdown load, decrement, done pulse, clamp, cancel, reset");
        $finish;
    end
endmodule
