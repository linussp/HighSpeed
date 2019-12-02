//testbench for srt

module tb_srt;

//input
reg clk, resetn, enable;
reg [7:0] N;
reg [5:0] D;

//output 
wire [9:0] Q;
wire [7:0] R;

srt srt(clk, resetn, enable, N, D, Q, R);

initial begin
clk = 0;
resetn = 1;
#5  resetn = 0;
#20 resetn = 1;
#10 enable = 1;
	N = 8'h40;
	D = 6'h10;
	
/*#200 resetn = 0;
#20  resetn = 1;
#10  enable = 1;
	N = 8'b0111_0000;
	D = 8'b0100_0000;
*/
#200 $stop;
end

always 
#10 clk = ~clk;

endmodule 

