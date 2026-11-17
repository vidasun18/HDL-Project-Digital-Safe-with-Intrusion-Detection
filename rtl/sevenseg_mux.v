module sevenseg_mux #(parameter integer REFRESH_DIV=100000)(input wire clk,input wire rst,input wire [31:0] digits,output reg [6:0] SEG,output reg [7:0] AN,output wire DP);
 localparam integer W=(REFRESH_DIV<2)?1:$clog2(REFRESH_DIV);
 reg [W-1:0] div_count; reg [2:0] scan; reg [3:0] nibble; wire [6:0] decoded;
 hex7seg dec(.hex_digit(nibble),.seg_n(decoded)); assign DP=1'b1;
 always @(posedge clk) if(rst) begin div_count<=0;scan<=0;end else if(REFRESH_DIV<=1 || div_count>=REFRESH_DIV-1) begin div_count<=0;scan<=scan+1'b1;end else div_count<=div_count+1'b1;
 always @* begin nibble=digits[scan*4 +:4]; AN=~(8'b1<<scan); SEG=decoded; end
endmodule
