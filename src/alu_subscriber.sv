`include "defines.svh"
`uvm_analysis_imp_decl(_mon_op)

class alu_subscriber extends uvm_subscriber#(alu_sequence_item);
  `uvm_component_utils(alu_subscriber)
  uvm_analysis_imp_mon_op#(alu_sequence_item,alu_subscriber)subs_mon_op_item_collect_export;
  alu_sequence_item drv;
  alu_sequence_item mon;
  int unsigned total = {`DWIDTH{1'b1}};
  int unsigned total_high = {`DWIDTH + 1{1'b1}};

  covergroup alu_input_cg;
    RST_cp: coverpoint drv.rst;
    CE_cp: coverpoint drv.ce;
    MODE_cp: coverpoint drv.mode iff(!drv.rst && drv.ce);
    CIN_cp: coverpoint drv.cin iff(!drv.rst && drv.ce && (drv.mode && (drv.cmd == 2 || drv.cmd == 3)));
    INP_VALID_cp: coverpoint drv.inp_valid iff(!drv.rst || drv.ce)
                  {
                    bins valid_3 = {3};
                    bins valid_2 = {2};
                    bins valid_1 = {1};
                    bins failed = {0};
                  }
    CMD_cp: coverpoint drv.cmd iff(!drv.rst || drv.ce)
            {
              bins arith[] = {[0:10]} iff (drv.mode == 1'b1);
              bins logical[] = {[0:13]} iff (drv.mode == 1'b0);
              bins out_of_range_arith = {[11:15]} iff (drv.mode == 1'b1);
              bins out_of_range_logical = {14,15} iff (drv.mode == 1'b0);
            }
    ADD_cp: coverpoint (int'(drv.opa) + int'(drv.opb)) iff(!drv.rst && drv.ce && (drv.mode && (drv.cmd == 0)))
             {
               bins in_range = {[0:total]};
               bins cout_trig = {[total + 1: total_high]};
             }
    ADD_CIN_cp: coverpoint (int'(drv.opa) + int'(drv.opb) + drv.cin) iff(!drv.rst && drv.ce && (drv.mode && (drv.cmd == 2)))
             {
               bins in_range = {[0:total]};
               bins cout_trig = {[total + 1 : total_high]};
             }
    SUB_cp: coverpoint drv.opa < drv.opb iff(!drv.rst && drv.ce && (drv.mode && (drv.cmd == 1 || drv.cmd == 3)))
             {
               bins normal = {0};
               bins oflow_trig = {1};
             }
    DECA_cp: coverpoint drv.opa == 0 iff(!drv.rst && drv.ce && (drv.mode && drv.cmd == 5))
             {
               bins normal = {0};
               bins corner = {1};
             }
    DECB_cp: coverpoint drv.opb == 0 iff(!drv.rst && drv.ce && (drv.mode && drv.cmd == 7))
             {
               bins normal = {0};
               bins corner = {1};
             }
    INCA_cp: coverpoint drv.opa == total iff(!drv.rst && drv.ce && (drv.mode && drv.cmd == 4))
             {
               bins normal = {0};
               bins corner = {1};
             }
    INCB_cp: coverpoint drv.opb == total iff(!drv.rst && drv.ce && (drv.mode && drv.cmd == 6))
             {
               bins normal = {0};
               bins corner = {1};
             }
    SHA_cp: coverpoint drv.opa iff(!drv.rst && drv.ce && (!drv.mode && drv.cmd == 9))
             {
               wildcard bins normal = {8'b0xxxxxxx};
               wildcard bins corner = {8'b1xxxxxxx};
             }
    SHB_cp: coverpoint drv.opb iff(!drv.rst && drv.ce && (!drv.mode && drv.cmd == 11))
             {
               wildcard bins normal = {8'b0xxxxxxx};
               wildcard bins corner = {8'b1xxxxxxx};
             }
    MULT_cp: coverpoint drv.opa iff(!drv.rst && drv.ce && (drv.mode && drv.cmd == 10))
             {
               bins normal = {[0:127],[129:255]};
               bins corner = {255};
             }
    RO_cp: coverpoint drv.opb iff(!drv.rst && drv.ce && (!drv.mode && (drv.cmd == 12 || drv.cmd == 13)))
             {
               wildcard bins normal = {8'b0000xxxx};
               wildcard bins err_trig = {[4'b1000:$]};
             }
    OPA: coverpoint drv.opa
             {
               option.weight = 0;
               bins ign = {[0:total]};
               bins high = {total};
             }
    OPB: coverpoint drv.opb
             {
               option.weight = 0;
               bins ign = {[0:total]};
               bins high = {total};
             }
    CMP_cross: cross OPA,OPB iff(!drv.rst && drv.ce && (drv.mode && drv.cmd == 8))
             {
               bins greater = (binsof(OPA.ign) && binsof(OPB.ign))with(OPA>OPB);
               bins lesser = (binsof(OPA.ign) && binsof(OPB.ign))with(OPA<OPB);
               bins equal = (binsof(OPA.ign) && binsof(OPB.ign))with(OPA==OPB);
             }
    ADD_MULT_cross: cross OPA,OPB iff(!drv.rst && drv.ce && (drv.mode && drv.cmd == 9))
             {
               option.goal = 65;
               bins corner = binsof(OPA.high) || binsof(OPB.high);
               bins all_val = binsof(OPA.ign);
             }
    mode_0_cp: coverpoint drv.inp_valid iff(!drv.rst && drv.ce && !(drv.mode))
             {
               bins valid_logical_3 = {2'b11} iff (drv.cmd inside {[0:5],12,13});
               bins valid_logical_2 = {2'b10} iff (drv.cmd inside {7,10,11});
               bins valid_logical_1 = {2'b01} iff (drv.cmd inside {6,8,9});
               bins invalid_logical_2 = {2'b10} iff (drv.cmd inside {[0:5],6,8,9,12,13});
               bins invalid_logical_1 = {2'b01} iff (drv.cmd inside {[0:5],7,10,11,12,13});
             }
    mode_1_cp: coverpoint drv.inp_valid iff(!drv.rst && drv.ce && (drv.mode))
             {
               bins valid_arith_3 = {2'b11} iff (drv.cmd inside {[0:3],[8:10]});
               bins valid_arith_2 = {2'b10} iff (drv.cmd inside {6,7});
               bins valid_arith_1 = {2'b01} iff (drv.cmd inside {4,5});
               bins invalid_arith_2 = {2'b10} iff (drv.cmd inside {[0:5],8,9,10});
               bins invalid_arith_1 = {2'b01} iff (drv.cmd inside {[0:3],[6:10]});
             }
  endgroup

  covergroup alu_output_cg;
    RES: coverpoint mon.res iff(!mon.rst && mon.ce)
         {
           bins normal = {[0:total]};
           bins out_of_bounds = {[total+1:$]};
         }
    OFLOW: coverpoint mon.oflow iff(!mon.rst && mon.ce)
         {
           bins zero = {0};
           bins trigger = {1};
         }
    COUT: coverpoint mon.cout iff(!mon.rst && mon.ce)
         {
           bins zero = {0};
           bins trigger = {1};
         }
    G: coverpoint mon.g iff(!mon.rst && mon.ce)
         {
           ignore_bins zero = {0};
           bins trigger = {1};
         }
    L: coverpoint mon.l iff(!mon.rst && mon.ce)
         {
           ignore_bins zero = {0};
           bins trigger = {1};
         }
    E: coverpoint mon.e iff(!mon.rst && mon.ce)
         {
           ignore_bins zero = {0};
           bins trigger = {1};
         }
    ERR: coverpoint mon.err iff(!mon.rst && mon.ce)
         {
           bins zero = {0};
           bins trigger = {1};
         }
  endgroup

  function new(string name = "subs", uvm_component parent = null);
    super.new(name,parent);
    alu_input_cg = new();
    alu_output_cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    subs_mon_op_item_collect_export = new("subs_mon_op_item_collect_export",this);
  endfunction

  virtual function void write(alu_sequence_item t);
    drv = t;
    alu_input_cg.sample();
    `uvm_info(get_name,"[DRIVER]:INPUT RECIEVED",UVM_HIGH)
  endfunction

  virtual function void write_mon_op(alu_sequence_item seq);
    mon = seq;
    alu_output_cg.sample();
    `uvm_info(get_name,"[MONITOR]:INPUT RECIEVED",UVM_HIGH)
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_name,$sformatf("INPUT COVERAGE = %0f\nOUTPUT COVERAGE = %0f",alu_input_cg.get_coverage(),alu_output_cg.get_coverage()),UVM_NONE);
  endfunction

endclass
