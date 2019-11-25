module srt(
	input clk, resetn, start,
	input [5:0] N,
	input [5:0] D,
	output [5:0] Q,
	output [3:0] R
);

parameter IDLE   = 2'b00,
		  CALC_1 = 2'b01,
		  CALC_2 = 2'b10,
		  STOP   = 2'b11;

reg [1:0] state, next_state;
reg [7:0] count;  // in case we want to increase digit 
reg incr_count;
reg doneq, shiftq, loadP;

wire [8:0] P, P4;
wire [2:0] q; //from 1 time select table
wire [8:0] qd; //product 
wire [8:0] newP; //after sub
wire [8:0] P_reg; //after register 



always @(posedge clk) begin
	if (!resetn) begin
		// reset
		incr_count <= 1'b0;
		state <= IDLE;
	end
	else begin
		state <= next_state;
	end
end

always @(state, count)begin
	case(state)
		IDLE: begin
			incr_count = 1'b0;
			doneq = 1'b0;
			if(start) next_state = CALC_1;
		end
		CALC_1:begin
			incr_count = 1'b1;
			shiftq = 1'b1;
			next_state = CALC_2;
		end
		CALC_2: begin
			loadP = 1'b1;
			incr_count = 1'b1;
			shiftq = 1'b1;

			if (count == 8'h02) next_state = STOP;
			else next_state = CALC_2; 
		end
		STOP: begin
			doneq = 1'b1;
		end
		default: next_state = IDLE;
	endcase	
end

always @(posedge clk)begin
	if (!resetn) begin
		count = 0;
	end
	else begin
		if(incr_count) count = count + 1;
		else count = 0;
	end
end

mux2 p1(
	.input0({3'b000,N}),  // not sure 3'b000 or should be 2'b00
	.input1(P_reg),
	.select(loadP),
	.data_out(P)
	);

//P to 4P
assign P4 = P << 2;

q_select qst(
	.D(D[5:2]),
	.P4(P4),
	.q(q)
	);

shift_reg qreg(
	.clk(clk),
	.resetn(resetn),
	.q(q),
	.shift(shiftq),
	.done(doneq),
	.q_radix4(q_radix4)
	);

product prod(
	.d({3'b000, D}),
	.q(q),
	.qd(qd)
	);

subtractor sub(
	.P4(P4),
	.qd(qd),
	.diff(newP)
	);

register9 m4(
	.clk(clk),
	.resetn(resetn),
	.in(newP),
	.load(1'b1),
	.data_out(P_reg)
	);

endmodule 


//mux for partial remainder 
module mux2(input0, input1, select, data_out);
	input [8:0] input0, input1; 
	input select;
	output [8:0] data_out;

	assign data_out = select? input1 : input0;
endmodule

//q selection table 
module q_select(D, P4, q);
input [3:0] D;
input [8:0] P4;
output [2:0] q;


reg [14:0] temp_row;

	always @(P4)begin
		case(P4)
			9'b000_000_000: temp_row = 15'b000_000_000_000_000;
			9'b000_000_001: temp_row = 15'b000_000_000_000_000;
			9'b000_000_010: temp_row = 15'b000_000_000_000_000;
			9'b000_000_011: temp_row = 15'b000_000_000_000_000;
			9'b000_000_100: temp_row = 15'b001_000_000_000_000;
			9'b000_000_101: temp_row = 15'b001_001_000_000_000;
			9'b000_000_110: temp_row = 15'b001_001_001_000_000;
			9'b000_000_111: temp_row = 15'b001_001_001_001_000;

			9'b000_001_000: temp_row = 15'b010_001_001_001_001;
			9'b000_001_001: temp_row = 15'b010_001_001_001_001;
			9'b000_001_010: temp_row = 15'b010_010_001_001_001;
			9'b000_001_011: temp_row = 15'b010_010_001_001_001;
			9'b000_001_100: temp_row = 15'b011_010_010_001_001;
			9'b000_001_101: temp_row = 15'b011_010_010_001_001;
			9'b000_001_110: temp_row = 15'b011_010_010_010_001;
			9'b000_001_111: temp_row = 15'b011_011_010_010_001;

			9'b000_010_000: temp_row = 15'bxxx_011_010_010_010;
			9'b000_010_001: temp_row = 15'bxxx_011_010_010_010;
			9'b000_010_010: temp_row = 15'bxxx_011_011_010_010;
			9'b000_010_011: temp_row = 15'bxxx_011_011_010_010;
			9'b000_010_100: temp_row = 15'bxxx_xxx_011_010_010;
			9'b000_010_101: temp_row = 15'bxxx_xxx_011_011_010;
			9'b000_010_110: temp_row = 15'bxxx_xxx_011_011_010;
			9'b000_010_111: temp_row = 15'bxxx_xxx_011_011_010;

			9'b000_011_000: temp_row = 15'bxxx_xxx_xxx_011_011;
			9'b000_011_001: temp_row = 15'bxxx_xxx_xxx_011_011;
			9'b000_011_010: temp_row = 15'bxxx_xxx_xxx_011_011;
			9'b000_011_011: temp_row = 15'bxxx_xxx_xxx_011_011;
			9'b000_011_100: temp_row = 15'bxxx_xxx_xxx_xxx_011;
			9'b000_011_101: temp_row = 15'bxxx_xxx_xxx_xxx_011;
			9'b000_011_110: temp_row = 15'bxxx_xxx_xxx_xxx_011;
			9'b000_011_111: temp_row = 15'bxxx_xxx_xxx_xxx_011;
			9'b000_100_000: temp_row = 15'bxxx_xxx_xxx_xxx_xxx;
			default: temp_row = 15'b000_000_000_000_000;
	end

	always @(d, temp_row) begin
	case (d) 
		4'b0100 : q = temp_row[14:12];
		4'b0101 : q = temp_row[11:9];
		4'b0110 : q = temp_row[8:6];
		4'b0111 : q = temp_row[5:3];		
		4'b1000 : q = temp_row[2:0];		
	endcase
	end
endmodule

//shift register 
module shift_reg(clk, resetn, q, shift, done, q_radix4);
	input clk, resetn;
	input [2:0] q;
	input shift, done;
	output [8:0] q_radix4;

	reg [8:0] temp;

	always @(posedge clk) begin
		if (!resetn) begin
			// reset
			temp <= 9'b0;
		end
		else begin
			if (shift) temp <= {temp[5:2], q};
		end
	end

	assign q_radix4 = done? temp : 'hz;

endmodule

//product
module product(d, q, qd);
	input [8:0]d;
	input [2:0]q;
	output qd;

	//product
	reg [8:0] qd;

	wire [8:0] q2d, q_2d, q3d, q_3d;

	assign q2d  = d << 1;
	assign q3d  = (d << 1) + d;

	always @(q, d)begin
		case(q)
			3'b000: qd <= 9'b0;//q=0
			3'b001: qd <= d;//q=1
			3'b010: qd <= q2d;//q=2
			3'b011: qd <= q3d;//q=3
			3'b111: qd <= ~d + 1'b1;//q=-1
			3'b110: qd <= ~q2d + 1'b1;//q=-2
			3'b101: qd <= ~q3d + 1'b1;//q=-3
		endcase
	end
endmodule


//subtractor
module subtractor(P4, qd, diff);
input [8:0] P4, qd;
output [8:0] diff;

assign diff = P4 - qd;

endmodule

//==================================//
//	1 BIT FULL SUBTRACTOR	    //
//==================================//

module fs(input a,b,c, //one bit operands
	  	  output diff,borr
	 );

assign diff = a ^ b ^c ;
assign borr = (~a & b) | (b & c) | (~a & c);

endmodule


//register for the result of sub
module register9(clk, resetn, in, load, data_out);
input clk, resetn, load;
input [8:0] in;
output reg[8:0] data_out;

always @(posedge clk)begin
	if (!resetn) data_out <= 9'b0;
	else begin
		if(load) data_out <= in;
	end
end

endmodule
