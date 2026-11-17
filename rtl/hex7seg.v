module hex7seg(input wire [3:0] hex_digit,output reg [6:0] seg_n);
 always @* case(hex_digit)
 0:seg_n=7'b1000000;1:seg_n=7'b1111001;2:seg_n=7'b0100100;3:seg_n=7'b0110000;
 4:seg_n=7'b0011001;5:seg_n=7'b0010010;6:seg_n=7'b0000010;7:seg_n=7'b1111000;
 8:seg_n=7'b0000000;9:seg_n=7'b0010000;10:seg_n=7'b0001000;11:seg_n=7'b0000011;
 12:seg_n=7'b1000110;13:seg_n=7'b0100001;14:seg_n=7'b0000110;default:seg_n=7'b0001110;
 endcase
endmodule
