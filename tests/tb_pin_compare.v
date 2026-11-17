`timescale 1ns/1ps
module tb_pin_compare;
    reg [15:0] captured_pin=16'h0000;
    wire pin_match;
    pin_compare #(.USER_PIN(16'hA5C3)) dut (
        .captured_pin(captured_pin), .pin_match(pin_match)
    );

    initial begin
        #1;
        if (pin_match !== 1'b0) $fatal(1, "nonmatching PIN must fail");
        captured_pin=16'hA5C2; #1;
        if (pin_match !== 1'b0) $fatal(1, "one-bit-different PIN must fail");
        captured_pin=16'hA5C3; #1;
        if (pin_match !== 1'b1) $fatal(1, "matching PIN must pass");
        captured_pin=16'h0000; #1;
        if (pin_match !== 1'b0) $fatal(1, "comparison must follow the current input");
        $display("PASS: parameterized combinational PIN comparison");
        $finish;
    end
endmodule
