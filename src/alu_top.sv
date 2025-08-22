`include "alu_interface.sv"
`include "alu_pkg.sv"
import uvm_pkg::*;
import alu_pkg::*;
`include "ALU_Design_16clock_cycles.v"
module top;
  bit clk;

  always #5 clk = ~clk;

  alu_interface intf(clk);

  ALU_DESIGN#(8,4) DUT(.INP_VALID(intf.inp_valid),.OPA(intf.opa),.OPB(intf.opb),.CIN(intf.cin),.CLK(clk),.RST(intf.rst),.CMD(intf.cmd),.CE(intf.ce),.MODE(intf.mode),.COUT(intf.cout),.OFLOW(intf.oflow),.RES(intf.res),.G(intf.g),.E(intf.e),.L(intf.l),.ERR(intf.err));

  initial begin
    uvm_config_db#(virtual alu_interface)::set(null,"*","vif",intf);
    $dumpfile("wave.vcd");
    $dumpvars();
  end
  initial begin
    @(posedge clk);
    intf.rst = 1;
    @(posedge clk);
    intf.rst = 0;
  end
  initial begin
    run_test("alu_test");
    //#100;
    $finish;
  end
endmodule
