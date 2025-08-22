`include "defines.svh"
interface alu_assertion_cvg(clk,rst,ce,opa,opb,mode,inp_valid,cmd,cin,res);
  input clk;
  input rst;
  input ce;
  input [`DWIDTH - 1 : 0] opa;
  input [`DWIDTH - 1 : 0]opb;
  input mode;
  input [1:0] inp_valid;
  input [`CWIDTH - 1 : 0]cmd;
  input cin;
  input [`DWIDTH : 0]res;

  property ALU_Unknown;
    @(posedge clk)
    !($isunknown({rst,ce,opa,opb,mode,inp_valid,cmd,cin}));
  endproperty
  ALU_UNKNOWN: assert property(ALU_Unknown) else $error("INPUTS ARE UNKNOWN");

  ALU_RESET: assert property(@(posedge clk) !rst) else $info("RESET IS TRIGGERED");

  property ALU_State;
    @(posedge clk)
    !ce |=> res == $past(res);
  endproperty
  ALU_SAME_STATE: assert property(ALU_State) else $error("OUTPUT CHANGED");

  sequence delay_16;
    (inp_valid == 2'b11) or (inp_valid[0] ##[0:16] inp_valid[1]) or (inp_valid[1] ##[0:16] inp_valid[0]);
  endsequence

  property ALU_clk_delay;
    @(posedge clk)
      ((mode && cmd inside {ADD,SUB,ADD_CIN,SUB_CIN,CMP}) |-> ((cmd inside {ADD,SUB,ADD_CIN,SUB_CIN,CMP}) throughout delay_16) or 
      ((cmd inside {AND,NAND,OR,NOR,XOR,XNOR,ROL_A_B,ROR_A_B}) |-> (cmd inside {AND,NAND,OR,NOR,XOR,XNOR,ROL_A_B,ROR_A_B}) throughout delay_16));
  endproperty

  ALU_CLK: assert property(ALU_clk_delay) else $error("INPUTS HAVEN'T BEEN RECIEVED ON TIME");

  property ALU_clk_mult;
    @(posedge clk)
    if(mode) cmd == SH_MUL || cmd == ADD_MUL |-> (cmd == SH_MUL throughout (delay_16 ##3 1)) or (cmd == ADD_MUL throughout (delay_16 ##3 1));
  endproperty
  ALU_CLK_MULT: assert property(ALU_clk_mult) else $error("MULTIPLICATION FAILED");

  INP_VALID_trans: cover property(ALU_clk_delay);

endinterface
