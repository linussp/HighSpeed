/////////////////final UVM
`include "uvm_macros.svh"
package sequences;

    import uvm_pkg::*;

    class alu_transaction_in extends uvm_sequence_item;
         // TODO: Register the  alu_transaction_in object. Hint: Look at other classes to find out what is missing.
		`uvm_object_utils(alu_transaction_in)

        rand logic [7:0]N;
        rand logic [5:0]D;
        //rand logic resetn;
        rand logic enable;
        int resetn;

        //TODO: Add constraints here
       /* constraint c_sub{
			rst == 0;
			if(opcode==5'b10000) A>=B;
			if(opcode==5'b10100 || opcode == 5'b10000) CIN == 1'b1 ;
			opcode != 5'b11011;
			opcode != 5'b11101;
			opcode != 5'b01111;
			opcode != 5'b10110;
			opcode != 5'b00101;
			//opcode != 5'b00010;
			opcode != 5'b10111;
			opcode != 5'b00000;
			opcode != 5'b10001;
			opcode != 5'b10000;
			opcode != 5'b10100;
			opcode != 5'b11001;
			opcode != 5'b01001;
			opcode != 5'b01100;
		}*/
		constraint srt_general{
			
			//resetn == 1;
			enable == 1;
			//fpu_op inside {3'b001}; //sub
			//if(opa[62:52] == 11'b11111111111) opa[51:0] == 0 ;
			//if(opb[62:52] == 11'b11111111111) opb[51:0] == 0 ;
			//fpu_op inside {3'b000}; //add
			//N[7:0] inside {8'h18,8'h04};  //60 = 0110_0000  3/4  1/2  =  3/2
			//N[7:0] == 8'b0001_1100;   //0.875
			//D[5:0] == 6'b01_0000;    //0.5
			
			
			
			N[7:6] ==2'b0;
			
			
			//D's constrant
			if(D[5]==1) D[4:0] == 0;
 			if(D[5]==0) D[4] == 1;
			//D[1:0] ==2'b0; 	
			
			//if(D == 8'b0100_0000) N!=8'b1000_0000;
			
			
			

			
			
			
		
		}
	//constraint unsued{opcode inside{5'b00001,5'b00010,5'b00100,5'b00110,5'b01000,5'b01101,5'b10010,5'b10011,5'b11110,5'b11111};}
	//constraint AeuqB {A==B;}
	//constraint Acorner {A inside {32'hFFFFFFFF,8'h0};}
	//constraint Bcorner {B inside {32'hFFFFFFFF,8'h0};}
	//constraint Acorner2 {A inside {32'h80000000,8'h7FFFFFFF};}
		
        function new(string name = "");
            super.new(name);
        endfunction: new

        function string convert2string;
           // convert2string={$sformatf("Operand A = %b, Operand B = %b, Opcode = %b, CIN = %b",A,B,opcode,CIN)};
        endfunction: convert2string

    endclass: alu_transaction_in


    class alu_transaction_out extends uvm_sequence_item;
        // TODO: Register the  alu_transaction_out object. Hint: Look at other classes to find out what is missing.
		`uvm_object_utils(alu_transaction_out)
		
        logic [9:0] Q;
        logic [7:0] R;
        logic done;
        //logic ready,underflow,overflow,inexact,exception,invalid;
        //logic VOUT;

        function new(string name = "");
            super.new(name);
        endfunction: new;
        
        function string convert2string;
           // convert2string={$sformatf("OUT = %b, COUT = %b, VOUT = %b",OUT,COUT,VOUT)};
        endfunction: convert2string

    endclass: alu_transaction_out

    class simple_seq extends uvm_sequence #(alu_transaction_in);
        `uvm_object_utils(simple_seq)

        function new(string name = "");
            super.new(name);
        endfunction: new

        task body;
            alu_transaction_in tx;
            tx=alu_transaction_in::type_id::create("tx");
            start_item(tx);
			tx.resetn = 0;
            assert(tx.randomize());
            finish_item(tx);
			start_item(tx);
			#300;
			tx.resetn = 1;
			finish_item(tx);
			#8000;//mul 28000 add 23000 sub 25000
	
        endtask: body
    endclass: simple_seq


    class seq_of_commands extends uvm_sequence #(alu_transaction_in);
        `uvm_object_utils(seq_of_commands)
        `uvm_declare_p_sequencer(uvm_sequencer#(alu_transaction_in))

        function new (string name = "");
            super.new(name);
        endfunction: new

        task body;
            repeat(100000)
            begin
                simple_seq seq;
                seq = simple_seq::type_id::create("seq");
                assert( seq.randomize() );
                seq.start(p_sequencer);
            end
        endtask: body

    endclass: seq_of_commands

endpackage: sequences
