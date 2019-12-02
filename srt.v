module srt(
	input clk, resetn, enable,
	input [7:0] N,
	input [5:0] D,
	output [9:0] Q,
	output [7:0] R,
	output reg done
);

parameter IDLE   = 2'b00,
		  CALC_1 = 2'b01,
		  CALC_2 = 2'b10,
		  STOP   = 2'b11;

reg [1:0] state, next_state;
reg [7:0] count;  // in case we want to increase digit 
reg shiftq, loadP;

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
	.D(D[5:0]),
	.P4(P4[9:2]),
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
	.d({2'b00, D, 2'b00}),
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
input [5:0] D;
input [7:0] P4; //6 msb P4[9:4]
output reg[1:0] q;


reg [33:0] temp_row;

	always @(P4)begin
		case(P4)
			8'b000_00000: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_00001: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_00010: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_00011: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_00100: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_00101: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_00110: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_00111: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_01000: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_01001: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_01010: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_01011: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_01100: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_01101: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_01110: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_01111: temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
//
			8'b000_10000: temp_row = 34'b01_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_10001: temp_row = 34'b01_01_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_10010: temp_row = 34'b01_01_01_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_10011: temp_row = 34'b01_01_01_01_00_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_10100: temp_row = 34'b01_01_01_01_01_00_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_10101: temp_row = 34'b01_01_01_01_01_01_00_00_00_00_00_00_00_00_00_00_00;
			8'b000_10110: temp_row = 34'b01_01_01_01_01_01_01_00_00_00_00_00_00_00_00_00_00;
			8'b000_10111: temp_row = 34'b01_01_01_01_01_01_01_01_00_00_00_00_00_00_00_00_00;
			8'b000_11000: temp_row = 34'b01_01_01_01_01_01_01_01_01_00_00_00_00_00_00_00_00;
			8'b000_11001: temp_row = 34'b01_01_01_01_01_01_01_01_01_01_00_00_00_00_00_00_00;
			8'b000_11010: temp_row = 34'b01_01_01_01_01_01_01_01_01_01_01_00_00_00_00_00_00;
			8'b000_11011: temp_row = 34'b01_01_01_01_01_01_01_01_01_01_01_01_00_00_00_00_00;
			8'b000_11100: temp_row = 34'b01_01_01_01_01_01_01_01_01_01_01_01_01_00_00_00_00;
			8'b000_11101: temp_row = 34'b01_01_01_01_01_01_01_01_01_01_01_01_01_01_00_00_00;
			8'b000_11110: temp_row = 34'b01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_00_00;
			8'b000_11111: temp_row = 34'b01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_00;

			8'b001_00000: temp_row = 34'b10_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01;
			8'b001_00001: temp_row = 34'b10_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01;
			8'b001_00010: temp_row = 34'b10_10_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01;
			8'b001_00011: temp_row = 34'b10_10_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01;
			8'b001_00100: temp_row = 34'b10_10_10_01_01_01_01_01_01_01_01_01_01_01_01_01_01;
			8'b001_00101: temp_row = 34'b10_10_10_01_01_01_01_01_01_01_01_01_01_01_01_01_01;
			8'b001_00110: temp_row = 34'b10_10_10_10_01_01_01_01_01_01_01_01_01_01_01_01_01;
			8'b001_00111: temp_row = 34'b10_10_10_10_01_01_01_01_01_01_01_01_01_01_01_01_01;
			8'b001_01000: temp_row = 34'b10_10_10_10_10_01_01_01_01_01_01_01_01_01_01_01_01;
			8'b001_01001: temp_row = 34'b10_10_10_10_10_01_01_01_01_01_01_01_01_01_01_01_01;
			8'b001_01010: temp_row = 34'b10_10_10_10_10_10_01_01_01_01_01_01_01_01_01_01_01;
			8'b001_01011: temp_row = 34'b10_10_10_10_10_10_01_01_01_01_01_01_01_01_01_01_01;
			8'b001_01100: temp_row = 34'b10_10_10_10_10_10_10_01_01_01_01_01_01_01_01_01_01;
			8'b001_01101: temp_row = 34'b10_10_10_10_10_10_10_01_01_01_01_01_01_01_01_01_01;
			8'b001_01110: temp_row = 34'b10_10_10_10_10_10_10_10_01_01_01_01_01_01_01_01_01;
			8'b001_01111: temp_row = 34'b10_10_10_10_10_10_10_10_01_01_01_01_01_01_01_01_01;

			8'b001_10000: temp_row = 34'b11_10_10_10_10_10_10_10_10_01_01_01_01_01_01_01_01;
			8'b001_10001: temp_row = 34'b11_10_10_10_10_10_10_10_10_01_01_01_01_01_01_01_01;
			8'b001_10010: temp_row = 34'b11_10_10_10_10_10_10_10_10_10_01_01_01_01_01_01_01;
			8'b001_10011: temp_row = 34'b11_11_10_10_10_10_10_10_10_10_01_01_01_01_01_01_01;
			8'b001_10100: temp_row = 34'b11_11_10_10_10_10_10_10_10_10_10_01_01_01_01_01_01;
			8'b001_10101: temp_row = 34'b11_11_10_10_10_10_10_10_10_10_10_01_01_01_01_01_01;
			8'b001_10110: temp_row = 34'b11_11_11_10_10_10_10_10_10_10_10_10_01_01_01_01_01;
			8'b001_10111: temp_row = 34'b11_11_11_10_10_10_10_10_10_10_10_10_01_01_01_01_01;
			8'b001_11000: temp_row = 34'b11_11_11_10_10_10_10_10_10_10_10_10_10_01_01_01_01;
			8'b001_11001: temp_row = 34'b11_11_11_11_10_10_10_10_10_10_10_10_10_01_01_01_01;
			8'b001_11010: temp_row = 34'b11_11_11_11_10_10_10_10_10_10_10_10_10_10_01_01_01;
			8'b001_11011: temp_row = 34'b11_11_11_11_10_10_10_10_10_10_10_10_10_10_01_01_01;
			8'b001_11100: temp_row = 34'b11_11_11_11_11_10_10_10_10_10_10_10_10_10_10_01_01;
			8'b001_11101: temp_row = 34'b11_11_11_11_11_10_10_10_10_10_10_10_10_10_10_01_01;
			8'b001_11110: temp_row = 34'b11_11_11_11_11_10_10_10_10_10_10_10_10_10_10_10_01;
			8'b001_11111: temp_row = 34'b11_11_11_11_11_11_10_10_10_10_10_10_10_10_10_10_01;

			8'b010_00000: temp_row = 34'bxx_11_11_11_11_11_10_10_10_10_10_10_10_10_10_10_10;
			8'b010_00001: temp_row = 34'bxx_11_11_11_11_11_10_10_10_10_10_10_10_10_10_10_10;
			8'b010_00010: temp_row = 34'bxx_11_11_11_11_11_11_10_10_10_10_10_10_10_10_10_10;
			8'b010_00011: temp_row = 34'bxx_11_11_11_11_11_11_10_10_10_10_10_10_10_10_10_10;
			8'b010_00100: temp_row = 34'bxx_xx_11_11_11_11_11_10_10_10_10_10_10_10_10_10_10;
			8'b010_00101: temp_row = 34'bxx_xx_11_11_11_11_11_11_10_10_10_10_10_10_10_10_10;
			8'b010_00110: temp_row = 34'bxx_xx_11_11_11_11_11_11_10_10_10_10_10_10_10_10_10;
			8'b010_00111: temp_row = 34'bxx_xx_11_11_11_11_11_11_10_10_10_10_10_10_10_10_10;
			8'b010_01000: temp_row = 34'bxx_xx_xx_11_11_11_11_11_11_10_10_10_10_10_10_10_10;
			8'b010_01001: temp_row = 34'bxx_xx_xx_11_11_11_11_11_11_10_10_10_10_10_10_10_10;
			8'b010_01010: temp_row = 34'bxx_xx_xx_11_11_11_11_11_11_10_10_10_10_10_10_10_10;
			8'b010_01011: temp_row = 34'bxx_xx_xx_11_11_11_11_11_11_11_10_10_10_10_10_10_10;
			8'b010_01100: temp_row = 34'bxx_xx_xx_xx_11_11_11_11_11_11_10_10_10_10_10_10_10;
			8'b010_01101: temp_row = 34'bxx_xx_xx_xx_11_11_11_11_11_11_10_10_10_10_10_10_10;
			8'b010_01110: temp_row = 34'bxx_xx_xx_xx_11_11_11_11_11_11_11_10_10_10_10_10_10;
			8'b010_01111: temp_row = 34'bxx_xx_xx_xx_11_11_11_11_11_11_11_10_10_10_10_10_10;

			8'b010_10000: temp_row = 34'bxx_xx_xx_xx_xx_11_11_11_11_11_11_10_10_10_10_10_10;
			8'b010_10001: temp_row = 34'bxx_xx_xx_xx_xx_11_11_11_11_11_11_11_10_10_10_10_10;
			8'b010_10010: temp_row = 34'bxx_xx_xx_xx_xx_11_11_11_11_11_11_11_10_10_10_10_10;
			8'b010_10011: temp_row = 34'bxx_xx_xx_xx_xx_11_11_11_11_11_11_11_10_10_10_10_10;
			8'b010_10100: temp_row = 34'bxx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_10_10_10_10;
			8'b010_10101: temp_row = 34'bxx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_10_10_10_10;
			8'b010_10110: temp_row = 34'bxx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_10_10_10_10;
			8'b010_10111: temp_row = 34'bxx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_11_10_10_10;
			8'b010_11000: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_10_10_10;
			8'b010_11001: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_10_10_10;
			8'b010_11010: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_11_10_10;
			8'b010_11011: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_11_10_10;
			8'b010_11100: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_10_10;
			8'b010_11101: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_11_10;
			8'b010_11110: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_11_10;
			8'b010_11111: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_11_10;

			8'b011_00000: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_11;
			8'b011_00001: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_11;
			8'b011_00010: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_11;
			8'b011_00011: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11_11;
			8'b011_00100: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11;
			8'b011_00101: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11;
			8'b011_00110: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11;
			8'b011_00111: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11_11;
			8'b011_01000: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11;
			8'b011_01001: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11;
			8'b011_01010: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11;
			8'b011_01011: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11_11;
			8'b011_01100: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11;
			8'b011_01101: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11;
			8'b011_01110: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11;
			8'b011_01111: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11_11;

			8'b011_10000: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11;
			8'b011_10001: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11;
			8'b011_10010: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11;
			8'b011_10011: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11_11;
			8'b011_10100: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11;
			8'b011_10101: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11;
			8'b011_10110: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11;
			8'b011_10111: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11_11;
			8'b011_11000: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11;
			8'b011_11001: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11;
			8'b011_11010: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11;
			8'b011_11011: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11_11;
			8'b011_11100: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11;
			8'b011_11101: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11;
			8'b011_11110: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11;
			8'b011_11111: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_11;

			8'b100_00000: temp_row = 34'bxx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx_xx;
			default:      temp_row = 34'b00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
		endcase
	end

	always @(D, temp_row) begin
	case (D) 
		6'b010000 : q = temp_row[33:32];
		6'b010001 : q = temp_row[31:30];
		6'b010010 : q = temp_row[29:28];
		6'b010011 : q = temp_row[27:26];
		6'b010100 : q = temp_row[25:24];
		6'b010101 : q = temp_row[23:22];
		6'b010110 : q = temp_row[21:20];
		6'b010111 : q = temp_row[19:18];
		6'b011000 : q = temp_row[17:16];
		6'b011001 : q = temp_row[15:14];
		6'b011010 : q = temp_row[13:12];
		6'b011011 : q = temp_row[11:10];
		6'b011100 : q = temp_row[9:8];
		6'b011101 : q = temp_row[7:6];
		6'b011110 : q = temp_row[5:4];
		6'b011111 : q = temp_row[3:2];

		6'b100000 : q = temp_row[1:0];
	endcase
	end
endmodule

//shift register 
module shift_reg(clk, resetn, q, shift, done, Q);
	input clk, resetn;
	input [1:0] q;
	input shift, done;
	output [9:0] Q;

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

	assign Q = done? temp : 'hz;

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
