`timescale 1ns/1ps
module tb_button_debounce;
    reg clk=1'b0, rst=1'b1, button_raw=1'b0;
    wire stable_level, press_pulse;
    integer pulse_count=0;
    always #5 clk=~clk;

    button_debounce #(.DEBOUNCE_CYCLES(3)) dut (
        .clk(clk), .rst(rst), .button_raw(button_raw),
        .stable_level(stable_level), .press_pulse(press_pulse)
    );
    always @(posedge clk)
        if (!rst && press_pulse) pulse_count = pulse_count + 1;

    initial begin
        repeat (3) @(posedge clk);
        @(negedge clk); rst=1'b0;

        // A one-cycle glitch must not pass the synchronizer and filter.
        @(negedge clk); button_raw=1'b1;
        @(negedge clk); button_raw=1'b0;
        repeat (8) @(posedge clk);
        #1;
        if (stable_level !== 1'b0 || pulse_count != 0)
            $fatal(1, "short input glitch must not produce a press");

        // A held press produces one pulse only after stable qualification.
        @(negedge clk); button_raw=1'b1;
        repeat (12) @(posedge clk);
        #1;
        if (stable_level !== 1'b1 || pulse_count != 1)
            $fatal(1, "stable press must produce exactly one pulse");
        repeat (8) @(posedge clk);
        #1;
        if (pulse_count != 1)
            $fatal(1, "holding the button must not repeat the pulse");

        @(negedge clk); button_raw=1'b0;
        repeat (8) @(posedge clk);
        #1;
        if (stable_level !== 1'b0 || pulse_count != 1)
            $fatal(1, "release must update stable level without another press pulse");

        @(negedge clk); button_raw=1'b1;
        repeat (12) @(posedge clk);
        #1;
        if (stable_level !== 1'b1 || pulse_count != 2)
            $fatal(1, "a second press after release must produce one new pulse");
        $display("PASS: synchronized debounce, glitch rejection, one pulse per hold");
        $finish;
    end
endmodule
