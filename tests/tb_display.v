`timescale 1ns/1ps

module tb_display;
  reg [3:0] hex_digit;
  wire [6:0] seg_n;
  reg clk = 0;
  reg rst = 1;
  reg [31:0] digits = 32'h76543210;
  wire [6:0] seg;
  wire [7:0] an;
  wire dp;
  reg [6:0] expected [0:15];
  reg [7:0] selected;
  integer i;
  reg [2:0] state;
  reg [1:0] failed_count;
  reg [7:0] remaining;
  wire [31:0] formatted;

  always #5 clk = ~clk;
  hex7seg decoder(.hex_digit(hex_digit), .seg_n(seg_n));
  sevenseg_mux #(.REFRESH_DIV(2)) mux(
      .clk(clk), .rst(rst), .digits(digits), .SEG(seg), .AN(an), .DP(dp));
  display_formatter formatter(
      .state(state), .failed_count(failed_count),
      .remaining_seconds(remaining), .digits(formatted));

  initial begin
    expected[0]=7'b1000000; expected[1]=7'b1111001;
    expected[2]=7'b0100100; expected[3]=7'b0110000;
    expected[4]=7'b0011001; expected[5]=7'b0010010;
    expected[6]=7'b0000010; expected[7]=7'b1111000;
    expected[8]=7'b0000000; expected[9]=7'b0010000;
    expected[10]=7'b0001000; expected[11]=7'b0000011;
    expected[12]=7'b1000110; expected[13]=7'b0100001;
    expected[14]=7'b0000110; expected[15]=7'b0001110;

    for (i=0; i<16; i=i+1) begin
      hex_digit=i[3:0]; #1;
      if (seg_n !== expected[i])
        $fatal(1, "hex %h decoded %b, expected %b", hex_digit, seg_n, expected[i]);
    end

    state=0; failed_count=2; remaining=8'h0f; #1;
    if (formatted !== {4'h1,2'b00,2'd2,16'h0000,8'h0f})
      $fatal(1, "LOCKED formatting mismatch: %h", formatted);
    state=1; #1; if (formatted[31:28] !== 4'hc) $fatal(1,"CHECKING status mismatch");
    state=2; #1; if (formatted[31:28] !== 4'h2) $fatal(1,"UNLOCKED status mismatch");
    state=3; #1; if (formatted[31:28] !== 4'ha) $fatal(1,"ALARM status mismatch");
    state=4; #1; if (formatted[31:28] !== 4'hd) $fatal(1,"LOCKOUT status mismatch");
    if (formatted[27:24] !== 4'h2 || formatted[7:0] !== 8'h0f)
      $fatal(1,"attempt count or remaining seconds not in contracted digits");

    repeat (2) @(posedge clk);
    #1 rst=0;
    for (i=0; i<24; i=i+1) begin
      @(posedge clk); #1;
      selected=~an;
      if (mux.scan !== (((i+1)/2) % 8))
        $fatal(1,"scan did not advance once every REFRESH_DIV clocks at cycle %0d",i);
      if (selected == 0 || (selected & (selected-1'b1)) != 0)
        $fatal(1,"anodes are not one-hot active-low: AN=%b",an);
      if (dp !== 1'b1) $fatal(1,"decimal point must remain off");
      if (seg !== expected[digits[mux.scan*4 +: 4]])
        $fatal(1,"scan digit mismatch at scan=%0d",mux.scan);
    end
    $display("PASS: all hex glyphs, formatter fields, active-low scan and DP-off behavior");
    $finish;
  end
endmodule
