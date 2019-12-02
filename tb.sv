/////////////////////////////////////
//final 
////////////////////////////////////
`timescale 1ns / 100ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import modules_pkg::*;
import sequences::*;
import coverage::*;
import scoreboard::*;
import tests::*;

module dut(dut_in _in, dut_out _out);
srt srt0(
    .clk(_in.clk),
    .resetn(_in.resetn),
    .enable(_in.enable),
    .N(_in.N),
    .D(_in.D),
    .done(_out.done),
    .Q(_out.Q),
    .R(_out.R)
);
endmodule: dut

module top;    
dut_in dut_in1();
dut_out dut_out1();

initial begin
    dut_in1.clk<=0;
    forever #50 dut_in1.clk<=~dut_in1.clk;
end

initial begin
    dut_out1.clk<=0;
    forever #50 dut_out1.clk<=~dut_out1.clk;
end

// TODO: Instantiate the dut module as dut1 and use the input as dut_in1 and output as dut_out1
dut dut1(dut_in1, dut_out1);

initial begin
    uvm_config_db #(virtual dut_in)::set(null,"uvm_test_top","dut_vi_in",dut_in1);
    uvm_config_db #(virtual dut_out)::set(null,"uvm_test_top","dut_vi_out",dut_out1);
    uvm_top.finish_on_completion=1;

    //TODO:Modify the test name here
    run_test("test1");
end

endmodule: top
