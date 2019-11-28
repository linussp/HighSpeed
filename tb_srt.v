//testbench for srt

module tb_srt;

//input
reg clk, resetn, enable;
reg [7:0] N,D;

//output 
wire [7:0] Q,R;

srt srt(clk, resetn, enable, N, D, Q, R);

initial begin
clk = 0;
resetn = 1;
#5  resetn = 0;
#20 resetn = 1;
#10 enable = 1;
	N = 8'b0011_0000;
	D = 8'b0100_0000;
	
#200 resetn = 0;
#20  resetn = 1;
#10  enable = 1;
	N = 8'b0111_0000;
	D = 8'b0100_0000;

#200 $stop;
end

always 
#10 clk = ~clk;

endmodule 

