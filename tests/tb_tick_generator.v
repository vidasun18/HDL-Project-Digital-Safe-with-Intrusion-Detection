`timescale 1ns/1ps
module tb_tick_generator;
    reg clk=1'b0, rst=1'b1;
    wire tick_1hz;
    integer cycle=0;
    integer tick_count=0;
    integer last_tick_cycle=-1;
    always #5 clk=~clk;

    tick_generator #(.CLK_HZ(5)) dut(.clk(clk), .rst(rst), .tick_1hz(tick_1hz));

    always @(posedge clk) begin
        cycle = cycle + 1;
        #1;
        if (!rst && tick_1hz) begin
            if (last_tick_cycle >= 0 && cycle-last_tick_cycle != 5)
                $fatal(1, "tick interval should be five clocks; got %0d", cycle-last_tick_cycle);
            tick_count = tick_count + 1;
            last_tick_cycle = cycle;
        end
    end

    initial begin
        repeat (2) @(posedge clk);
        #1;
        if (tick_1hz !== 1'b0) $fatal(1, "reset must clear tick");
        @(negedge clk); rst=1'b0;
        repeat (16) @(posedge clk);
        #2;
        if (tick_count != 3) $fatal(1, "expected three ticks in 16 clocks, got %0d", tick_count);
        if (tick_1hz !== 1'b0) $fatal(1, "tick must be a one-cycle pulse");
        $display("PASS: CLK_HZ=5 produces one-cycle enables every five clocks");
        $finish;
    end
endmodule
