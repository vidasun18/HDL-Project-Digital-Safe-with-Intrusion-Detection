`timescale 1ns/1ps
module tb_display;
    reg [3:0] hex_digit;
    wire [6:0] seg_n;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg [31:0] scan_digits = 32'h1234_5678;
    wire [6:0] scan_seg;
    wire [7:0] an;
    wire dp;
    reg [2:0] state;
    reg [1:0] failed_count;
    reg [7:0] remaining_seconds;
    wire [31:0] formatted_digits;
    integer i;
    reg [7:0] expected_an;
    reg [3:0] expected_nibble;
    reg [6:0] expected_seg;

    always #5 clk = ~clk;

    hex7seg decoder(.hex_digit(hex_digit), .seg_n(seg_n));
    sevenseg_mux #(.REFRESH_DIV(1)) mux (
        .clk(clk), .rst(rst), .digits(scan_digits),
        .SEG(scan_seg), .AN(an), .DP(dp)
    );
    display_formatter formatter (
        .state(state), .failed_count(failed_count),
        .remaining_seconds(remaining_seconds), .digits(formatted_digits)
    );

    function [6:0] glyph(input [3:0] digit);
        begin
            case (digit)
                0: glyph=7'b1000000; 1: glyph=7'b1111001;
                2: glyph=7'b0100100; 3: glyph=7'b0110000;
                4: glyph=7'b0011001; 5: glyph=7'b0010010;
                6: glyph=7'b0000010; 7: glyph=7'b1111000;
                8: glyph=7'b0000000; 9: glyph=7'b0010000;
                10: glyph=7'b0001000; 11: glyph=7'b0000011;
                12: glyph=7'b1000110; 13: glyph=7'b0100001;
                14: glyph=7'b0000110; default: glyph=7'b0001110;
            endcase
        end
    endfunction

    initial begin
        for (i=0; i<16; i=i+1) begin
            hex_digit = i[3:0];
            #1;
            if (seg_n !== glyph(i[3:0]))
                $fatal(1, "glyph %h mismatch: got %b expected %b", i[3:0], seg_n, glyph(i[3:0]));
        end

        state=3'd3; failed_count=2'd2; remaining_seconds=8'h1A;
        #1;
        if (formatted_digits !== 32'hA200_001A)
            $fatal(1, "alarm display format mismatch: %h", formatted_digits);
        state=3'd4;
        #1;
        if (formatted_digits !== 32'hD200_001A)
            $fatal(1, "lockout status encoding mismatch: %h", formatted_digits);

        repeat (2) @(posedge clk);
        @(negedge clk); rst=1'b0;
        for (i=0; i<8; i=i+1) begin
            #1;
            expected_an = ~(8'b0000_0001 << i);
            expected_nibble = (scan_digits >> (i*4)) & 4'hF;
            expected_seg = glyph(expected_nibble);
            if (an !== expected_an)
                $fatal(1, "scan digit %0d anode mismatch: %b", i, an);
            if (scan_seg !== expected_seg)
                $fatal(1, "scan digit %0d segment mismatch: %b", i, scan_seg);
            if (dp !== 1'b1)
                $fatal(1, "decimal point must remain off");
            @(posedge clk); #1;
        end
        $display("PASS: hex glyphs, status formatter, and eight-digit scan");
        $finish;
    end
endmodule
