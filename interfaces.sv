
///////////////////////////////final UVM
interface dut_in;
    logic    	 clk, resetn, enable;
	logic   [7:0] N;
	logic   [5:0] D;
endinterface: dut_in


interface dut_out;
    logic	clk;
 //TODO: Complete the dut_out interface
    logic [9:0] Q;
    logic [7:0] R;
    logic done;
	

	//assert1: assert property (done == 1) $display("Q : %b", Q);
endinterface: dut_out


