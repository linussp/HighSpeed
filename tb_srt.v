//testbench for srt

module tb_srt

//input
reg clk, resetn, start;
reg [7:0] N,D;

//output 
wire [7:0] Q,R;

srt srt(clk, resetn, start, N, D, Q, R);

initial begin
	clk = 0;
	resetn = 1;
	#5  resetn = 0;
	#20 resetn = 1;
	#10 start = 1;
		N = 8'b0100_0000;
		D = 8'b0100_0000;
	#200 $stop;
end

always 
#10 clk = ~clk;

endmodule 

