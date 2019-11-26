module srt(
	input clk, resetn, start,
	input [7:0] N,
	input [7:0] D,
	output [7:0] Q,
	output [7:0] R
);

parameter IDLE   = 2'b00,
		  CALC_1 = 2'b01,
		  CALC_2 = 2'b10,
		  STOP   = 2'b11;

reg [1:0] state, next_state;
reg [7:0] count;  // in case we want to increase digit 
reg incr_count;
reg doneq, shiftq, loadP;

wire [9:0] P, P4;
wire [1:0] q; //from 1 time select table
wire [9:0] qd; //product 
wire [9:0] newP; //after sub
wire [9:0] P_reg; //after register 



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

			if (count == 8'h03) next_state = STOP;
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
	.input0({2'b00,N}),  // not sure 3'b000 or should be 2'b00
	.input1(P_reg),
	.select(loadP),
	.data_out(P)
	);

//P to 4P
assign P4 = P << 2;

q_select qst(
	.D(D[7:4]),
	.P4(P4[9:5]),
	.q(q)
	);

shift_reg qreg(
	.clk(clk),
	.resetn(resetn),
	.q(q),
	.shift(shiftq),
	.done(doneq),
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
input [3:0] D;
input [4:0] P4; //5 msb P4[9:5]
output [1:0] q;


reg [14:0] temp_row;

	always @(P4)begin
		case(P4)
			5'b00_000: temp_row = 15'b000_000_000_000_000;
			5'b00_001: temp_row = 15'b000_000_000_000_000;
			5'b00_010: temp_row = 15'b000_000_000_000_000;
			5'b00_011: temp_row = 15'b000_000_000_000_000;
			5'b00_100: temp_row = 15'b001_000_000_000_000;
			5'b00_101: temp_row = 15'b001_001_000_000_000;
			5'b00_110: temp_row = 15'b001_001_001_000_000;
			5'b00_111: temp_row = 15'b001_001_001_001_000;

			5'b01_000: temp_row = 15'b010_001_001_001_001;
			5'b01_001: temp_row = 15'b010_001_001_001_001;
			5'b01_010: temp_row = 15'b010_010_001_001_001;
			5'b01_011: temp_row = 15'b010_010_001_001_001;
			5'b01_100: temp_row = 15'b011_010_010_001_001;
			5'b01_101: temp_row = 15'b011_010_010_001_001;
			5'b01_110: temp_row = 15'b011_010_010_010_001;
			5'b01_111: temp_row = 15'b011_011_010_010_001;

			5'b10_000: temp_row = 15'bxxx_011_010_010_010;
			5'b10_001: temp_row = 15'bxxx_011_010_010_010;
			5'b10_010: temp_row = 15'bxxx_011_011_010_010;
			5'b10_011: temp_row = 15'bxxx_011_011_010_010;
			5'b10_100: temp_row = 15'bxxx_xxx_011_010_010;
			5'b10_101: temp_row = 15'bxxx_xxx_011_011_010;
			5'b10_110: temp_row = 15'bxxx_xxx_011_011_010;
			5'b10_111: temp_row = 15'bxxx_xxx_011_011_010;

			5'b11_000: temp_row = 15'bxxx_xxx_xxx_011_011;
			5'b11_001: temp_row = 15'bxxx_xxx_xxx_011_011;
			5'b11_010: temp_row = 15'bxxx_xxx_xxx_011_011;
			5'b11_011: temp_row = 15'bxxx_xxx_xxx_011_011;
			5'b11_100: temp_row = 15'bxxx_xxx_xxx_xxx_011;
			5'b11_101: temp_row = 15'bxxx_xxx_xxx_xxx_011;
			5'b11_110: temp_row = 15'bxxx_xxx_xxx_xxx_011;
			5'b11_111: temp_row = 15'bxxx_xxx_xxx_xxx_011;
			default:   temp_row = 15'b000_000_000_000_000;
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
module shift_reg(clk, resetn, q, shift, done, Q);
	input clk, resetn;
	input [1:0] q;
	input shift, done;
	output [7:0] Q;

	reg [7:0] temp;

	always @(posedge clk) begin
		if (!resetn) begin
			// reset
			temp <= 9'b0;
		end
		else begin
			if (shift) temp <= {temp[5:2], q};
		end
	end

	assign Q = done? temp : 'hz;

endmodule

//product
module product(d, q, qd);
	input [9:0]d;
	input [1:0]q;
	output reg[9:0] qd;

	//product
	wire [9:0] q2d, q3d, 
	wire [9:0] q_2d, q_3d;


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
		if(load) data_out <= in;
	end
end

endmodule
