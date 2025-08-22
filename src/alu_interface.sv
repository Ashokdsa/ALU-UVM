`include "defines.svh"
interface alu_interface(input logic clk);
  logic [`DWIDTH-1:0] opa,opb;
  logic rst,ce,mode,cin;
  logic [`CWIDTH-1:0] cmd;
  logic [1:0] inp_valid;
  logic [`DWIDTH+1:0] res;
  logic cout;
  logic oflow;
  logic g;
  logic e;
  logic l;
  logic err;

  clocking drv_cb @(posedge clk);
    default input #1 output #1;
    output opa;
    output opb;
    output rst;
    output ce;
    output mode;
    output cin;
    output cmd;
    output inp_valid;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1 output #1;
    input opa;
    input opb;
    input rst;
    input ce;
    input mode;
    input cin;
    input cmd;
    input inp_valid;
    input res;
    input cout;
    input oflow;
    input g;
    input e;
    input l;
    input err; 
  endclocking
endinterface