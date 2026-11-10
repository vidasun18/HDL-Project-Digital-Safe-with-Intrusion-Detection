`timescale 1ns/1ps

module tb_reset_locked;
    reg clk = 1'b0;
    reg resetn = 1'b1;
    reg [15:0] switches = 16'h0000;
    reg btnc = 1'b0;
    reg btnu = 1'b0;
    reg btnl = 1'b0;
    reg btnr = 1'b0;
    reg btnd = 1'b0;
    wire [15:0] led;
    wire [6:0] seg;
    wire [7:0] an;
    wire dp;

    digital_safe dut (
        .CLK100MHZ(clk),
        .CPU_RESETN(resetn),
        .SW(switches),
        .BTNC(btnc), .BTNU(btnu), .BTNL(btnl), .BTNR(btnr), .BTND(btnd),
        .LED(led), .SEG(seg), .AN(an), .DP(dp)
    );

    always #5 clk = ~clk;

    task check_locked_outputs;
        begin
            if (dut.state !== 3'd0 || led[0] !== 1'b1 || led[1] !== 1'b0)
                $fatal(1, "reset must leave the state locked with LED[0]=1 and LED[1]=0");
        end
    endtask

    initial begin
        @(negedge clk);
        resetn = 1'b0;
        @(posedge clk);
        #1;
        check_locked_outputs();

        resetn = 1'b1;
        @(posedge clk);
        #1;
        check_locked_outputs();

        // Seed representative volatile state to check that reset clears it.
        dut.state = 3'd2;
        dut.captured_pin = 16'hA55A;
        #1;
        if (led[0] !== 1'b0 || led[1] !== 1'b1)
            $fatal(1, "LEDs must reflect the unlocked state");

        @(negedge clk);
        resetn = 1'b0;
        @(posedge clk);
        #1;
        check_locked_outputs();
        if (dut.captured_pin !== 16'h0000)
            $fatal(1, "reset must clear captured PIN state");

        $display("PASS: active-low reset locks the safe and drives the locked indicators");
        $finish;
    end
endmodule
