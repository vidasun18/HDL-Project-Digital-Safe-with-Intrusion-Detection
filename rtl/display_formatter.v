module display_formatter(input wire [2:0] state,input wire [1:0] failed_count,input wire [7:0] remaining_seconds,output reg [31:0] digits);
 reg [3:0] status;
 always @* begin case(state) 0:status=1;1:status=12;2:status=2;3:status=10;default:status=13;endcase digits={status,2'b00,failed_count,16'h0000,remaining_seconds}; end
endmodule
