////////////final  UVM
`include "uvm_macros.svh"
package scoreboard; 
import uvm_pkg::*;
import sequences::*;

class alu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(alu_scoreboard)

    uvm_analysis_export #(alu_transaction_in) sb_in;
    uvm_analysis_export #(alu_transaction_out) sb_out;

    uvm_tlm_analysis_fifo #(alu_transaction_in) fifo_in;
    uvm_tlm_analysis_fifo #(alu_transaction_out) fifo_out;

    alu_transaction_in tx_in;
    alu_transaction_out tx_out;

    function new(string name, uvm_component parent);
        super.new(name,parent);
        tx_in=new("tx_in");
        tx_out=new("tx_out");
    endfunction: new

    function void build_phase(uvm_phase phase);
        sb_in=new("sb_in",this);
        sb_out=new("sb_out",this);
        fifo_in=new("fifo_in",this);
        fifo_out=new("fifo_out",this);
    endfunction: build_phase

    function void connect_phase(uvm_phase phase);
        sb_in.connect(fifo_in.analysis_export);
        sb_out.connect(fifo_out.analysis_export);
    endfunction: connect_phase

    task run();
        forever begin
            fifo_in.get(tx_in);
            fifo_out.get(tx_out);
            compare();
        end
    endtask: run

  //  extern virtual function [7:0] getresultQ; 
    extern virtual function void compare; 
        
endclass: alu_scoreboard

function void alu_scoreboard::compare;
    //TODO: Write this function to check whether the output of the DUT matches
    //the spec.
    //Use the getresult() function to get the spec output.
    //Consider using `uvm_info(ID,MSG,VERBOSITY) in this function to print the
    //results of the comparison.
    //You can use tx_in.convert2string() and tx_out.convert2string() for
    //debugging purposes
	//if(tx_in == tx_out)

 	//logic [7:0] expResultQ = getresultQ();
	logic [9:0] DUTResultQ = tx_out.Q;
	logic 		DUTdone = tx_out.done;	

	//$display("expDUTResult: sign: %b, exponent: %b, fraction %b",expResultQ[64],expResultQ[63:53],expResultQ[52:1]);
	//if(expResultQ[0] == 0)
	//`uvm_info("SCOREBOARD:", $sformatf("expDUTResult: sign: %b, exponent: %b, fraction %b",expResultQ[64],expResultQ[63:53],expResultQ[52:1]), UVM_NONE )
	
	logic [7:0] N = tx_in.N;
	logic [5:0] D = tx_in.D;
	logic [9:0] Q = tx_out.Q;
	//logic [7:0] Ntemp = 0;
	//logic [7:0] Dtemp = 0;
	
	real RN =    N[5] * 1 +  N[4] * 0.5  + N[3]  * 0.5  * 0.5   + N[2] * 0.5  * 0.5  * 0.5  +
				 N[1]  * 0.5  * 0.5  * 0.5  * 0.5  + N[0]  * 0.5  * 0.5  * 0.5  * 0.5  * 0.5 ;
	real RD =    D[5] * 1 +  D[4] * 0.5  + D[3]  * 0.5  * 0.5   + D[2] * 0.5  * 0.5  * 0.5  +
				 D[1]  * 0.5  * 0.5  * 0.5  * 0.5  + D[0]  * 0.5  * 0.5  * 0.5  * 0.5  * 0.5 ;

	real RQ =    Q[9]*2 + Q[8] * 1 +  Q[7] * 0.5  + Q[6]  * 0.5  * 0.5   + Q[5] * 0.5  * 0.5  * 0.5  +
				 Q[4]  * 0.5  * 0.5  * 0.5  * 0.5  + Q[3]  * 0.5  * 0.5  * 0.5  * 0.5  * 0.5 +
				 Q[2] * 0.5  * 0.5  * 0.5  * 0.5  * 0.5  * 0.5 +
				 Q[1] * 0.5  * 0.5  * 0.5  * 0.5  * 0.5  * 0.5  * 0.5 +
				 Q[0] * 0.5  * 0.5  * 0.5  * 0.5  * 0.5  * 0.5  * 0.5 * 0.5;
				 
	real expQ = RN/RD;
	real Qdiff = RQ - expQ;
	///real expResultQ = N/D;
	///real realQ = $bitstoreal(DUTResultQ);
	 //= $realtobits(temp);


	if(tx_out.done == 1'b1)
	begin
	`uvm_info("TESTDONE:", $sformatf("done: %b",tx_out.done), UVM_NONE )
	`uvm_info("INPUT:", $sformatf("N: %b.%b00, D: %b.%b",N[5],N[4:0] ,D[5],D[4:0]), UVM_NONE )
	//`uvm_info("INPUT:", $sformatf("N: %b.%b00, D: %b.%b",N[7],N[6:0] ,D[7],D[6:0]), UVM_NONE )
	`uvm_info("INPUT:", $sformatf("RN: %f, RD: %f, expQ: %f",RN ,RD, expQ), UVM_NONE )  
	`uvm_info("OUTPUT", $sformatf("binaryQ: %b.%b, decimalQ: %f ",Q[7], Q[6:0] ,RQ), UVM_NONE )
	`uvm_info("OUTPUT", $sformatf("Qdiff: %f",RQ-expQ), UVM_NONE )
	//Ntemp = N;
	//Dtemp = D;
	if(expQ >=4.0)
	begin
		`uvm_info("OUTPUT", $sformatf("OVERFLOW"), UVM_NONE )
    end
	if((Qdiff>0.00390125 || Qdiff<-0.00390125)&&expQ<4.0)    //0.0078125
	//if((Qdiff>0.015625 || Qdiff<-0.015625)&&expQ <2.0)
		begin
			`uvm_error("SCOREBOARD:", $sformatf("FAILD"))
		end
	//$display("_______________________________________________________________________________________________________________________________________");
	$display("");
	end
	//$display("_______________________________________________________________________________________________________________________________________");

endfunction


/*function [7:0] alu_scoreboard::getresultQ;
    //TODO: Remove the statement below
    //Modify this function to return a 34-bit result {VOUT, COUT,OUT[31:0]} which is
    //consistent with the given spec.
    //return 34'd0;
	//logic [31:0] expOut;
	//logic expVOUT;
	//logic expCOUT;
	//logic k,l =0;
	logic [7:0] N, D, Q;
	
	N = tx_in.N;
	D = tx_in.D;

	if(tx_in.resetn == 0)
	begin
		Q = 0;
	end
	else
	begin
		Q = N/D;
	end

	return Q;
endfunction*/

endpackage: scoreboard
