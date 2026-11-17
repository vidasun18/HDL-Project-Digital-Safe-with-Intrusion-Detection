`timescale 1ns/1ps
module tb_top_smoke;
  reg CLK100MHZ=0;
  always #5 CLK100MHZ = ~CLK100MHZ;
  reg CPU_RESETN=0;
  reg [15:0] SW=16'h0000;
  reg BTNC=0, BTNU=0, BTNL=0, BTNR=0, BTND=0;
  wire [15:0] LED;
  wire [6:0] SEG;
  wire [7:0] AN;
  wire DP;

  digital_safe #(.CLK_HZ(10), .DEBOUNCE_CYCLES(2),
      .ALARM_SECONDS(2), .LOCKOUT_SECONDS(3),
      .USER_PIN(16'hA5C3), .ADMIN_CODE(16'hC0DE)) dut (
      .CLK100MHZ(CLK100MHZ), .CPU_RESETN(CPU_RESETN), .SW(SW),
      .BTNC(BTNC), .BTNU(BTNU), .BTNL(BTNL), .BTNR(BTNR), .BTND(BTND),
      .LED(LED), .SEG(SEG), .AN(AN), .DP(DP));

  task clocks(input integer n); begin repeat(n) @(posedge CLK100MHZ); #1; end endtask
  task submit_press; begin
     @(negedge CLK100MHZ); BTNC=1;
     clocks(15);
     @(negedge CLK100MHZ); BTNC=0;
     clocks(15);
  end endtask
  task down_press; begin
     @(negedge CLK100MHZ); BTND=1;
     clocks(15);
     @(negedge CLK100MHZ); BTND=0;
     clocks(15);
  end endtask

  initial begin
    $display("Test: reset / good PIN / relock / wrong PIN");
    clocks(4);
    if (LED[1] !== 1'b0 || LED[0] !== 1'b1)
       $fatal(1, "FAIL: reset must be locked; LED=%h", LED);
    @(negedge CLK100MHZ); CPU_RESETN=1;
    clocks(12);
    SW=16'hA5C3;
    submit_press();
    clocks(12);
    if (LED[1] !== 1'b1 || LED[0] !== 1'b0)
       $fatal(1, "FAIL: valid PIN must unlock; LED=%h", LED);
    down_press();
    clocks(8);
    if (LED[1] !== 1'b0 || LED[0] !== 1'b1)
       $fatal(1, "FAIL: manual relock must lock; LED=%h", LED);
    SW=16'h0000;
    submit_press();
    clocks(8);
    if (LED[1] !== 1'b0)
       $fatal(1, "FAIL: wrong PIN must not unlock; LED=%h", LED);
    $display("PASS: tb_top_smoke");
    $finish;
  end
  initial begin #300000; $fatal(1, "FAIL: smoke test timed out"); end
endmodule
