`include "defines.svh"
//`include "uvm_macros.svh"
class alu_sequence_item extends uvm_sequence_item;
  rand logic [`DWIDTH-1:0] opa,opb;
  rand logic rst,ce,cin;
  rand logic mode;
  rand logic [`CWIDTH-1:0] cmd;
  rand logic [1:0] inp_valid;
  logic  [`DWIDTH:0] res;
  logic  cout;
  logic  oflow;
  logic  g;
  logic  e;
  logic  l;
  logic  err;
  int exec;

  `uvm_object_utils_begin(alu_sequence_item)
    `uvm_field_int(opa,UVM_ALL_ON)
    `uvm_field_int(opb,UVM_ALL_ON)
    `uvm_field_int(rst,UVM_ALL_ON)
    `uvm_field_int(ce,UVM_ALL_ON)
    `uvm_field_int(cin,UVM_ALL_ON)
    `uvm_field_int(mode,UVM_ALL_ON)
    `uvm_field_int(cmd,UVM_ALL_ON)
    `uvm_field_int(inp_valid,UVM_ALL_ON)
    `uvm_field_int(res,UVM_ALL_ON)
    `uvm_field_int(cout,UVM_ALL_ON)
    `uvm_field_int(oflow,UVM_ALL_ON)
    `uvm_field_int(g,UVM_ALL_ON)
    `uvm_field_int(e,UVM_ALL_ON)
    `uvm_field_int(l,UVM_ALL_ON)
    `uvm_field_int(err,UVM_ALL_ON)
    `uvm_field_int(exec,UVM_ALL_ON)
  `uvm_object_utils_end

  constraint normal_cmd_mode
  {
    if(mode)
      cmd inside {[0:8]};
    else
      cmd inside {[0:13]};
  }

  constraint normal_global
  {
    rst == 0;
    ce == 1;
  }

  constraint normal_inp_val
  {
    if(mode)
    {
      if(cmd == 4 || cmd == 5)
         inp_valid == 2'b01;
      else if(cmd == 6 || cmd == 7)
         inp_valid == 2'b10;
      else
         inp_valid == 2'b11;
    }
    else
    {
      if(cmd == 6 || cmd == 8 || cmd == 9)
         inp_valid == 2'b01;
      else if(cmd == 7 || cmd == 10 || cmd == 11)
         inp_valid == 2'b10;
      else
         inp_valid == 2'b11;
    }
  }

  function new(string name = "seq_item");
    super.new(name);
  endfunction

/*  virtual function void do_print(uvm_printer printer);
    printer.print_field("opa",opa,$bits(opa),UVM_DEC);
    printer.print_field("opb",opb,$bits(opb),UVM_DEC);
    printer.print_field("rst",rst,$bits(rst),UVM_DEC);
    printer.print_field("ce",ce,$bits(ce),UVM_DEC);
    printer.print_field("cin",cin,$bits(cin),UVM_DEC);
    printer.print_field("mode",mode,$bits(mode),UVM_DEC);
    printer.print_field("cmd",cmd,$bits(cmd),UVM_DEC);
    printer.print_field("inp_valid",inp_valid,$bits(inp_valid),UVM_DEC);
    printer.print_field("res",res,$bits(res),UVM_DEC);
    printer.print_field("cout",cout,$bits(cout),UVM_DEC);
    printer.print_field("oflow",oflow,$bits(oflow),UVM_DEC);
    printer.print_field("g",g,$bits(g),UVM_DEC);
    printer.print_field("e",e,$bits(e),UVM_DEC);
    printer.print_field("l",l,$bits(l),UVM_DEC);
    printer.print_field("err",err,$bits(err),UVM_DEC);
  endfunction*/
endclass
