typedef enum{NORMAL,GLOBAL,ERR_CASE,CORNER,CLOCK_16,WRONG_CLOCK,FLAG,MULTIPLICATION,MULTIPLICATION_CLOCK,CORNER_MULTIPLICATION,REGRESSION}exec;
`uvm_analysis_imp_decl(_scb_mon_op)
`uvm_analysis_imp_decl(_ref_inp)

typedef enum{FAILED,PASSED}cmp;

class alu_scoreboard extends uvm_scoreboard;
  bit cmp,dut;
  alu_sequence_item seq_item;
  alu_sequence_item actual_op;
  alu_sequence_item act_store[$];
  alu_sequence_item ref_store[$];
  alu_sequence_item cmp_res[$];
  int MATCH,MISMATCH;
  `uvm_component_utils(alu_scoreboard)
  uvm_analysis_imp_scb_mon_op#(alu_sequence_item,alu_scoreboard)mon_2_scb;
  uvm_analysis_imp_ref_inp#(alu_sequence_item,alu_scoreboard)ref_2_scb;

  function new(string name = "scb", uvm_component parent = null);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_2_scb = new("mon_2_scb_in",this);
    ref_2_scb = new("ref_2_scb_in",this);
  endfunction

  function void write_ref_inp(alu_sequence_item seq);
    alu_sequence_item drv = seq;
    ref_store.push_back(drv);
    `uvm_info(get_name,$sformatf("[REF]:OUTPUT RECIEVED"/*%0s",drv.sprint*/),UVM_MEDIUM)
  endfunction

  function void write_scb_mon_op(alu_sequence_item seq);
    alu_sequence_item mon = seq;
    act_store.push_back(mon);
    `uvm_info(get_name,$sformatf("[MON]:OUTPUT RECIEVED"/*%0s",mon.sprint*/),UVM_MEDIUM)
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      `uvm_info(get_name,$sformatf("[SCB] REF SIZE = %0d MON SIZE = %0d",ref_store.size,act_store.size),UVM_DEBUG)
      fork
        begin:REF
          wait(ref_store.size() > 0);
          cmp = 1;
          seq_item = alu_sequence_item::type_id::create("seq_item");
          seq_item = ref_store.pop_front;
        end:REF
        begin:MON
          wait(act_store.size() > 0);
          dut = 1;
          actual_op = alu_sequence_item::type_id::create("actual_op");
          actual_op = act_store.pop_front();
        end:MON
      join_any
      if(cmp) 
      begin
        wait(dut);
        compare();
        `uvm_info(get_name,"BEGUN COMPARISON",UVM_DEBUG)
        cmp = 0;
        dut = 0;
      end
      else if(dut) 
      begin
        #5;
        if(cmp)
        begin
          compare();
          `uvm_info(get_name,"BEGUN COMPARISON",UVM_DEBUG)
          cmp = 0;
        end
        dut = 0;
      end
      //cmp_res = 0;//write the results here
    end
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_name,$sformatf("%0d PASSED OUT OF %0d WHICH IS %0f ",MATCH,MATCH + MISMATCH,(real'(MATCH)/(real'(MATCH)+real'(MISMATCH)))*100),UVM_LOW)//print the percentage of PASSES and FAILS
    $display("----------------------------------------------------------------------%0s EXECUTION COMPLETE----------------------------------------------------------------------\n\n",exec'(seq_item.exec));
  endfunction

  task compare();
    $display("--------------------------------------------------COMPARISON %0d-------------------------------------------------\n",MATCH+MISMATCH+1);
    if($isunknown(seq_item.res))
    begin
      if(actual_op.err === seq_item.err && actual_op.oflow === seq_item.oflow && actual_op.cout === seq_item.cout && actual_op.g === seq_item.g && actual_op.l === seq_item.l && actual_op.e === seq_item.e) begin
        MATCH++;
        `uvm_info(get_name,$sformatf("%0t | CORRECT EXECUTION, OUTPUT MATCHES\n\t RECIEVED\tEXPECTED\nRES(d):  %0d\t\t%0d\nRES(b):  %b\t%b\nOFLOW:    %1b\t\t%1b\nCOUT:\t    %1b\t\t%1b\nG: \t    %1b\t\t%1b\nL: \t    %1b\t\t%1b\nE: \t    %1b\t\t%1b\nERR: \t    %1b\t\t%0b",$time,actual_op.res,seq_item.res,actual_op.res,seq_item.res,actual_op.oflow,seq_item.oflow,actual_op.cout,seq_item.cout,actual_op.g,seq_item.g,actual_op.l,seq_item.l,actual_op.e,seq_item.e,actual_op.err,seq_item.err),UVM_LOW)
      end
      else begin
        MISMATCH++;
        `uvm_error(get_name,$sformatf("%0t | INCORRECT EXECUTION, OUTPUT DOES NOT MATCH\n\t\t\t\t\t\t\tRECIEVED\tEXPECTED\n\t\t\t\t\t\tRES(d): %0d\t\t%0d\n\t\t\t\t\t\tRES(b): %b\t%b\n\t\t\t\t\t\tOFLOW:\t%1b\t\t%1b\n\t\t\t\t\t\tCOUT: \t%1b\t\t%1b\n\t\t\t\t\t\tG: \t%1b\t\t%1b\n\t\t\t\t\t\tL:\t%1b\t\t%1b\n\t\t\t\t\t\tE: \t%1b\t\t%1b\t\n\t\t\t\t\t\tERR: \t%0b\t\t%0b",$time,actual_op.res,seq_item.res,actual_op.res,seq_item.res,actual_op.oflow,seq_item.oflow,actual_op.cout,seq_item.cout,actual_op.g,seq_item.g,actual_op.l,seq_item.l,actual_op.e,seq_item.e,actual_op.err,seq_item.err));
      end
    end
    else
    if(actual_op.err === seq_item.err && actual_op.res === seq_item.res && actual_op.oflow === seq_item.oflow && actual_op.cout === seq_item.cout && actual_op.g === seq_item.g && actual_op.l === seq_item.l && actual_op.e === seq_item.e) begin
      MATCH++;
        `uvm_info(get_name,$sformatf("%0t | CORRECT EXECUTION, OUTPUT MATCHES\n\t RECIEVED\tEXPECTED\nRES(d):  %0d\t\t%0d\nRES(b):  %b\t%b\nOFLOW:    %1b\t\t%1b\nCOUT:\t    %1b\t\t%1b\nG: \t    %1b\t\t%1b\nL: \t    %1b\t\t%1b\nE: \t    %1b\t\t%1b\nERR: \t    %1b\t\t%0b",$time,actual_op.res,seq_item.res,actual_op.res,seq_item.res,actual_op.oflow,seq_item.oflow,actual_op.cout,seq_item.cout,actual_op.g,seq_item.g,actual_op.l,seq_item.l,actual_op.e,seq_item.e,actual_op.err,seq_item.err),UVM_LOW)
    end
    else begin
      MISMATCH++;
        `uvm_error(get_name,$sformatf("%0t | INCORRECT EXECUTION, OUTPUT DOES NOT MATCH\n\t\t\t\t\t\t\tRECIEVED\tEXPECTED\n\t\t\t\t\t\tRES(d): %0d\t\t%0d\n\t\t\t\t\t\tRES(b): %b\t%b\n\t\t\t\t\t\tOFLOW:\t%1b\t\t%1b\n\t\t\t\t\t\tCOUT: \t%1b\t\t%1b\n\t\t\t\t\t\tG: \t%1b\t\t%1b\n\t\t\t\t\t\tL:\t%1b\t\t%1b\n\t\t\t\t\t\tE: \t%1b\t\t%1b\t\n\t\t\t\t\t\tERR: \t%0b\t\t%0b",$time,actual_op.res,seq_item.res,actual_op.res,seq_item.res,actual_op.oflow,seq_item.oflow,actual_op.cout,seq_item.cout,actual_op.g,seq_item.g,actual_op.l,seq_item.l,actual_op.e,seq_item.e,actual_op.err,seq_item.err));
    end
    $display("-------------------------------------------------------------------------------------------------------------------------------------------------------------------------");
  endtask

endclass
