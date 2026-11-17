`timescale 1ns/1ps
module tb_pin_capture;
    reg clk=1'b0, rst=1'b1, submit_pulse=1'b0;
    reg [15:0] switch_value=16'h0000;
    wire [15:0] captured_pin;
    wire captured_valid;
    always #5 clk=~clk;

    pin_capture dut (
        .clk(clk), .rst(rst), .submit_pulse(submit_pulse),
        .switch_value(switch_value), .captured_pin(captured_pin),
        .captured_valid(captured_valid)
    );

    initial begin
        repeat (2) @(posedge clk);
        #1;
        if (captured_pin !== 16'h0000 || captured_valid !== 1'b0)
            $fatal(1, "reset must clear captured data and valid");
        @(negedge clk); rst=1'b0; switch_value=16'hA5C3; submit_pulse=1'b1;
        @(posedge clk); #1;
        if (captured_pin !== 16'hA5C3 || captured_valid !== 1'b1)
            $fatal(1, "submit must capture the switch word and pulse valid");
        @(negedge clk); submit_pulse=1'b0; switch_value=16'h1234;
        @(posedge clk); #1;
        if (captured_pin !== 16'hA5C3 || captured_valid !== 1'b0)
            $fatal(1, "capture must hold its value and valid must last one cycle");
        $display("PASS: PIN capture, hold, reset, and one-cycle valid event");
        $finish;
    end
endmodule
