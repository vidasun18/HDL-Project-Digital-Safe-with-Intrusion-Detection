`timescale 1ns/1ps

module tb_top_regression;
  reg clk = 0;
  reg resetn = 0;
  reg [15:0] sw = 0;
  reg btnc = 0, btnu = 0, btnl = 0, btnr = 0, btnd = 0;
  wire [15:0] led;
  wire [6:0] seg;
  wire [7:0] an;
  wire dp;
  integer i;

  always #5 clk = ~clk;
  digital_safe #(.CLK_HZ(4), .DEBOUNCE_CYCLES(2),
      .ALARM_SECONDS(8), .LOCKOUT_SECONDS(3),
      .USER_PIN(16'hA5C3), .ADMIN_CODE(16'hC0DE)) dut (
      .CLK100MHZ(clk), .CPU_RESETN(resetn), .SW(sw),
      .BTNC(btnc), .BTNU(btnu), .BTNL(btnl), .BTNR(btnr), .BTND(btnd),
      .LED(led), .SEG(seg), .AN(an), .DP(dp));

  task clocks(input integer n);
    begin repeat(n) @(posedge clk); #1; end
  endtask

  task press_button(input integer id);
    begin
      @(negedge clk);
      case(id)
        0: btnc=1; 1: btnu=1; 2: btnl=1; 3: btnr=1; 4: btnd=1;
      endcase
      repeat(8) @(negedge clk);
      case(id)
        0: btnc=0; 1: btnu=0; 2: btnl=0; 3: btnr=0; 4: btnd=0;
      endcase
      repeat(8) @(negedge clk);
    end
  endtask

  task submit_pin(input [15:0] value);
    begin
      @(negedge clk); sw=value;
      repeat(4) @(negedge clk);
      press_button(0);
    end
  endtask

  task wait_state(input [2:0] expected_state, input integer limit);
    integer n;
    begin
      n=0;
      while (dut.state !== expected_state && n<limit) begin
        @(posedge clk); #1; n=n+1;
      end
      if (dut.state !== expected_state)
        $fatal(1,"timed out waiting for state %0d; got %0d",expected_state,dut.state);
    end
  endtask

  task wait_attempt_count(input [1:0] expected_count, input integer limit);
    integer n;
    begin
      n=0;
      while (dut.failed_count !== expected_count && n<limit) begin
        @(posedge clk); #1; n=n+1;
      end
      if (dut.failed_count !== expected_count)
        $fatal(1,"timed out waiting for failed_count %0d; got %0d",expected_count,dut.failed_count);
    end
  endtask

  initial begin
    clocks(4);
    if (dut.state !== 0 || led[0] !== 1 || led[1] !== 0)
      $fatal(1,"reset must start locked");
    @(negedge clk); resetn=1;

    submit_pin(16'hA5C3);
    wait_state(2,40);
    if (led[1] !== 1 || led[0] !== 0 || dut.display_digits[31:28] !== 4'h2)
      $fatal(1,"valid PIN must unlock and show UNLOCKED status");
    if (dut.display_digits === 32'h0000A5C3)
      $fatal(1,"display must never expose the submitted PIN");

    press_button(4);
    wait_state(0,20);
    if (led[0] !== 1 || led[1] !== 0) $fatal(1,"BTND must relock");

    for (i=0; i<3; i=i+1) begin
      submit_pin(16'h0001);
      wait_attempt_count(i+1,30);
      if (i<2) wait_state(0,20);
      else if (dut.state !== 3) $fatal(1,"third wrong PIN must enter alarm immediately");
    end
    if (dut.failed_count !== 3) $fatal(1,"third wrong PIN must saturate count at 3");
    wait_state(4,60);
    wait_state(0,60);
    if (dut.failed_count !== 0) $fatal(1,"lockout completion must clear attempt count");

    press_button(3);
    wait_state(3,30);
    if (led[5] !== 1) $fatal(1,"tamper evidence must latch on LED[5]");
    wait_state(4,60);
    wait_state(0,60);
    submit_pin(16'hA5C3);
    clocks(10);
    if (dut.state !== 0 || led[1] !== 0 || led[5] !== 1)
      $fatal(1,"a correct PIN must not clear tamper or unlock");

    @(negedge clk); sw=16'hC0DE;
    repeat(4) @(negedge clk);
    press_button(2); if (led[8:6] !== 3'b001) $fatal(1,"first admin progress LED mismatch");
    press_button(1); if (led[8:6] !== 3'b011) $fatal(1,"second admin progress LED mismatch");
    press_button(2); if (led[8:6] !== 3'b111) $fatal(1,"third admin progress LED mismatch");
    press_button(1);
    clocks(4);
    if (dut.state !== 0 || led[0] !== 1 || led[1] !== 0 || led[5] !== 0)
      $fatal(1,"authorized admin recovery must clear tamper and remain LOCKED");
    if (led[8:6] !== 0) $fatal(1,"admin progress must clear after recovery");

    $display("PASS: top reset, PIN unlock, relock, third-failure alarm, lockout, tamper and admin recovery");
    $finish;
  end

  initial begin #500000; $fatal(1,"top regression timed out"); end
endmodule
