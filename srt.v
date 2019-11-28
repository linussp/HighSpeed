module srt(
	input clk, resetn, enable,
	input [7:0] N,
	input [7:0] D,
	output [7:0] Q,
	output [7:0] R,
	output done
);

parameter IDLE   = 2'b00,
		  CALC_1 = 2'b01,
		  CALC_2 = 2'b10,
		  STOP   = 2'b11;

reg [1:0] state, next_state;
reg [7:0] count;  // in case we want to increase digit 
reg done, shiftq, loadP;

wire [9:0] P, P4;
wire [1:0] q; //from 1 time select table
wire [9:0] qd; //product 
wire [9:0] newP; //after sub
wire [9:0] P_reg; //after register 

assign R = done? newP:8'hz;

always @(posedge clk) begin
	if (!resetn) begin
		// reset
		state = IDLE;
		count = 0;
		loadP = 1'b0;
		shiftq = 1'b0;
		done = 1'b0;
	end
	else begin
		case(state)
			IDLE: begin
				loadP = 1'b0;
				shiftq = 1'b0;
				done = 1'b0;
				if(enable) state = CALC_1;
			end
			CALC_1:begin
				count = count + 1;
				shiftq = 1'b1;
				state = CALC_2;
				loadP = 1'b1;
			end
			CALC_2: begin
				count = count + 1;
				shiftq = 1'b1;

				if (count == 8'h05) state = STOP;
				else state = CALC_2; 
			end
			STOP: begin
				shiftq = 1'b0;
				done = 1'b1;
			end
			default: state = IDLE;
		endcase	

	end
end


mux2 p1(
	.input0({2'b00,N}),  // not sure 3'b000 or should be 2'b00
	.input1(P_reg),
	.select(loadP),
	.data_out(P4)
	);

//P to 4P
//assign P4 = P << 2;

q_select qst(
	.D(D[7:3]),
	.P4(P4[9:4]),
	.q(q)
	);

shift_reg qreg(
	.clk(clk),
	.resetn(resetn),
	.q(q),
	.shift(shiftq),
	.done(done),
	.Q(Q)
	);

product prod(
	.d({2'b00, D}),
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
	input [9:0] input0, input1; 
	input select;
	output [9:0] data_out;

	assign data_out = select? input1 : input0;
endmodule

//q selection table 
module q_select(D, P4, q);
input [4:0] D;
input [5:0] P4; //6 msb P4[9:4]
output reg[1:0] q;


reg [26:0] temp_row;

	always @(P4)begin
		case(P4)
			6'b000_000: temp_row = 27'b000_000_000_000_000_000_000_000_000;
			6'b000_001: temp_row = 27'b000_000_000_000_000_000_000_000_000;
			6'b000_010: temp_row = 27'b000_000_000_000_000_000_000_000_000;
			6'b000_011: temp_row = 27'b000_000_000_000_000_000_000_000_000;
			6'b000_100: temp_row = 27'b001_000_000_000_000_000_000_000_000;
			6'b000_101: temp_row = 27'b001_001_001_000_000_000_000_000_000;
			6'b000_110: temp_row = 27'b001_001_001_001_001_000_000_000_000;
			6'b000_111: temp_row = 27'b001_001_001_001_001_001_001_000_000;

			6'b001_000: temp_row = 27'b010_001_001_001_001_001_001_001_001;
			6'b001_001: temp_row = 27'b010_010_001_001_001_001_001_001_001;
			6'b001_010: temp_row = 27'b010_010_010_001_001_001_001_001_001;
			6'b001_011: temp_row = 27'b010_010_010_010_001_001_001_001_001;
			6'b001_100: temp_row = 27'b011_010_010_010_010_001_001_001_001;
			6'b001_101: temp_row = 27'b011_010_010_010_010_010_001_001_001;
			6'b001_110: temp_row = 27'b011_011_010_010_010_010_010_001_001;
			6'b001_111: temp_row = 27'b011_011_011_010_010_010_010_010_001;

			6'b010_000: temp_row = 27'bxxx_011_011_010_010_010_010_010_010;
			6'b010_001: temp_row = 27'bxxx_011_011_011_010_010_010_010_010;
			6'b010_010: temp_row = 27'bxxx_xxx_011_011_011_010_010_010_010;
			6'b010_011: temp_row = 27'bxxx_xxx_011_011_011_010_010_010_010;
			6'b010_100: temp_row = 27'bxxx_xxx_xxx_011_011_011_010_010_010;
			6'b010_101: temp_row = 27'bxxx_xxx_xxx_011_011_011_011_010_010;
			6'b010_110: temp_row = 27'bxxx_xxx_xxx_xxx_011_011_011_010_010;
			6'b010_111: temp_row = 27'bxxx_xxx_xxx_xxx_011_011_011_011_010;

			6'b011_000: temp_row = 27'bxxx_xxx_xxx_xxx_xxx_011_011_011_011;
			6'b011_001: temp_row = 27'bxxx_xxx_xxx_xxx_xxx_011_011_011_011;
			6'b011_010: temp_row = 27'bxxx_xxx_xxx_xxx_xxx_xxx_011_011_011;
			6'b011_011: temp_row = 27'bxxx_xxx_xxx_xxx_xxx_xxx_011_011_011;
			6'b011_100: temp_row = 27'bxxx_xxx_xxx_xxx_xxx_xxx_xxx_011_011;
			6'b011_101: temp_row = 27'bxxx_xxx_xxx_xxx_xxx_xxx_xxx_011_011;
			6'b011_110: temp_row = 27'bxxx_xxx_xxx_xxx_xxx_xxx_xxx_xxx_011;
			6'b011_111: temp_row = 27'bxxx_xxx_xxx_xxx_xxx_xxx_xxx_xxx_011;
			6'b100_000: temp_row = 27'bxxx_xxx_xxx_xxx_xxx_xxx_xxx_xxx_xxx;
			default:   temp_row = 27'b000_000_000_000_000_000_000_000_000;
		endcase
	end

	always @(D, temp_row) begin
	case (D) 
		5'b01000 : q = temp_row[26:24];
		5'b01001 : q = temp_row[23:21];
		5'b01010 : q = temp_row[20:18];
		5'b01011 : q = temp_row[17:15];		
		5'b01100 : q = temp_row[14:12];
		5'b01101 : q = temp_row[11:9];
		5'b01110 : q = temp_row[8:6];		
		5'b01111 : q = temp_row[5:3];		
		5'b10000 : q = temp_row[2:0];		
	endcase
	end
endmodule

//shift register 
module shift_reg(clk, resetn, q, shift, done, Q);
	input clk, resetn;
	input [1:0] q;
	input shift, done;
	output [7:0] Q;

	reg [9:0] temp;

	always @(posedge clk) begin
		if (!resetn) begin
			// reset
			temp <= 8'b00;
		end
		else begin
			if (shift) temp <= {temp[7:0], q};
		end
	end

	assign Q = done? temp[8:1] : 'hz;

endmodule

//product
module product(d, q, qd);
	input [9:0]d;
	input [1:0]q;
	output reg[9:0] qd;

	//product
	wire [9:0] q2d, q3d;
	//wire [9:0] q_2d, q_3d;


	assign q2d  = d << 1;
	assign q3d  = (d << 1) + d;

	always @(q, d)begin
		case(q)
			3'b00: qd <= 9'b0;//q=0
			3'b01: qd <= d;//q=1
			3'b10: qd <= q2d;//q=2
			3'b11: qd <= q3d;//q=3
			//3'b111: qd <= ~d + 1'b1;//q=-1
			//3'b110: qd <= ~q2d + 1'b1;//q=-2
			//3'b101: qd <= ~q3d + 1'b1;//q=-3
		endcase
	end
endmodule


//subtractor
module subtractor(P4, qd, diff);
input [9:0] P4, qd;
output [9:0] diff;

assign diff = P4 - qd;

endmodule



//register for the result of sub
module register9(clk, resetn, in, load, data_out);
input clk, resetn, load;
input [9:0] in;
output reg[9:0] data_out;

always @(posedge clk)begin
	if (!resetn) data_out <= 10'b0;
	else begin
		if(load) data_out <= in << 2;
	end
end

endmodule
