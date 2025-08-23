typedef enum{NORMAL,GLOBAL,ERR_CASE,CORNER,CLOCK_16,WRONG_CLOCK,FLAG,MULTIPLICATION,MULTIPLICATION_CLOCK,CORNER_MULTIPLICATION,REGRESSION}exec;
typedef enum{FAILED,PASSED}cmp;

`uvm_analysis_imp_decl(_scb_mon_op)
`uvm_analysis_imp_decl(_mon_val)

class alu_scoreboard extends uvm_scoreboard;
  int de;
  int iter;
  int count;
  bit[2:0] count3;
  bit valid_a,valid_b;
  bit cmp,dut;
  logic[`LOG2 - 1 : 0] shft;

  alu_sequence_item ref_item;
  alu_sequence_item actual_op;

  alu_sequence_item temp;

  alu_sequence_item act_store[$];
  alu_sequence_item ref_store[$];

  alu_sequence_item cmp_res[$];

  int MATCH,MISMATCH;

  `uvm_component_utils(alu_scoreboard)

  uvm_analysis_imp_scb_mon_op#(alu_sequence_item,alu_scoreboard)mon_p_scb;
  uvm_analysis_imp_mon_val#(alu_sequence_item,alu_scoreboard)mon_a_scb;

  function new(string name = "scb", uvm_component parent = null);
    super.new(name,parent);
    temp = alu_sequence_item::type_id::create("temp_item");
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_p_scb = new("mon_p_scb_in",this);
    mon_a_scb = new("mon_a_scb_in",this);
  endfunction

  function void write_mon_val(alu_sequence_item seq);
    alu_sequence_item ref_inp = seq;
    ref_store.push_back(ref_inp);
  endfunction

  function void write_scb_mon_op(alu_sequence_item seq);
    alu_sequence_item mon = seq;
    act_store.push_back(mon);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      `uvm_info(get_name,$sformatf("[SCB] INP SIZE = %0d OUT SIZE = %0d",ref_store.size,act_store.size),UVM_DEBUG)
      fork
        begin:REF
          wait(ref_store.size() > 0);
          `uvm_info(get_name,$sformatf("[MON_A]:INPUTS RECIEVED"/*%0s",ref_inp.sprint*/),UVM_MEDIUM)
          ref_item = alu_sequence_item::type_id::create("ref_item");
          ref_item = ref_store.pop_front;
          refer();
        end:REF
        begin:MON
          wait(act_store.size() > 0);
          `uvm_info(get_name,$sformatf("[MON_P]:OUTPUT RECIEVED"/*%0s",mon.sprint*/),UVM_MEDIUM)
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
    $display("----------------------------------------------------------------------%0s EXECUTION COMPLETE----------------------------------------------------------------------\n\n",exec'(ref_item.exec));
  endfunction

  task compare();
    $display("--------------------------------------------------COMPARISON %0d-------------------------------------------------\n",MATCH+MISMATCH+1);
    if($isunknown(ref_item.res))
    begin
      if(actual_op.err === ref_item.err && actual_op.oflow === ref_item.oflow && actual_op.cout === ref_item.cout && actual_op.g === ref_item.g && actual_op.l === ref_item.l && actual_op.e === ref_item.e) begin
        MATCH++;
        `uvm_info(get_name,$sformatf("%0t | CORRECT EXECUTION, OUTPUT MATCHES\n\t RECIEVED\tEXPECTED\nRES(d):  %0d\t\t%0d\nRES(b):  %b\t%b\nOFLOW:    %1b\t\t%1b\nCOUT:\t    %1b\t\t%1b\nG: \t    %1b\t\t%1b\nL: \t    %1b\t\t%1b\nE: \t    %1b\t\t%1b\nERR: \t    %1b\t\t%0b",$time,actual_op.res,ref_item.res,actual_op.res,ref_item.res,actual_op.oflow,ref_item.oflow,actual_op.cout,ref_item.cout,actual_op.g,ref_item.g,actual_op.l,ref_item.l,actual_op.e,ref_item.e,actual_op.err,ref_item.err),UVM_LOW)
      end
      else begin
        MISMATCH++;
        `uvm_error(get_name,$sformatf("%0t | INCORRECT EXECUTION, OUTPUT DOES NOT MATCH\n\t\t\t\t\t\t\tRECIEVED\tEXPECTED\n\t\t\t\t\t\tRES(d): %0d\t\t%0d\n\t\t\t\t\t\tRES(b): %b\t%b\n\t\t\t\t\t\tOFLOW:\t%1b\t\t%1b\n\t\t\t\t\t\tCOUT: \t%1b\t\t%1b\n\t\t\t\t\t\tG: \t%1b\t\t%1b\n\t\t\t\t\t\tL:\t%1b\t\t%1b\n\t\t\t\t\t\tE: \t%1b\t\t%1b\t\n\t\t\t\t\t\tERR: \t%0b\t\t%0b",$time,actual_op.res,ref_item.res,actual_op.res,ref_item.res,actual_op.oflow,ref_item.oflow,actual_op.cout,ref_item.cout,actual_op.g,ref_item.g,actual_op.l,ref_item.l,actual_op.e,ref_item.e,actual_op.err,ref_item.err));
      end
    end
    else
    if(actual_op.err === ref_item.err && actual_op.res === ref_item.res && actual_op.oflow === ref_item.oflow && actual_op.cout === ref_item.cout && actual_op.g === ref_item.g && actual_op.l === ref_item.l && actual_op.e === ref_item.e) begin
      MATCH++;
        `uvm_info(get_name,$sformatf("%0t | CORRECT EXECUTION, OUTPUT MATCHES\n\t RECIEVED\tEXPECTED\nRES(d):  %0d\t\t%0d\nRES(b):  %b\t%b\nOFLOW:    %1b\t\t%1b\nCOUT:\t    %1b\t\t%1b\nG: \t    %1b\t\t%1b\nL: \t    %1b\t\t%1b\nE: \t    %1b\t\t%1b\nERR: \t    %1b\t\t%0b",$time,actual_op.res,ref_item.res,actual_op.res,ref_item.res,actual_op.oflow,ref_item.oflow,actual_op.cout,ref_item.cout,actual_op.g,ref_item.g,actual_op.l,ref_item.l,actual_op.e,ref_item.e,actual_op.err,ref_item.err),UVM_LOW)
    end
    else begin
      MISMATCH++;
        `uvm_error(get_name,$sformatf("%0t | INCORRECT EXECUTION, OUTPUT DOES NOT MATCH\n\t\t\t\t\t\t\tRECIEVED\tEXPECTED\n\t\t\t\t\t\tRES(d): %0d\t\t%0d\n\t\t\t\t\t\tRES(b): %b\t%b\n\t\t\t\t\t\tOFLOW:\t%1b\t\t%1b\n\t\t\t\t\t\tCOUT: \t%1b\t\t%1b\n\t\t\t\t\t\tG: \t%1b\t\t%1b\n\t\t\t\t\t\tL:\t%1b\t\t%1b\n\t\t\t\t\t\tE: \t%1b\t\t%1b\t\n\t\t\t\t\t\tERR: \t%0b\t\t%0b",$time,actual_op.res,ref_item.res,actual_op.res,ref_item.res,actual_op.oflow,ref_item.oflow,actual_op.cout,ref_item.cout,actual_op.g,ref_item.g,actual_op.l,ref_item.l,actual_op.e,ref_item.e,actual_op.err,ref_item.err));
    end
    $display("-------------------------------------------------------------------------------------------------------------------------------------------------------------------------");
  endtask

  task refer();
    cmp = 0;
    if(ref_item.rst)
    begin
      count = 0;
      count3 = 0;
      ref_item.res = 'bz;
      ref_item.err = 1'bz;
      ref_item.cout = 1'bz;
      ref_item.g = 1'bz;
      ref_item.l = 1'bz;
      ref_item.e = 1'bz;
      ref_item.oflow = 1'bz;
      {valid_a,valid_b} = 2'b00;
      cmp = 1;
    end
    else begin
      if(ref_item.ce) begin
        count = (temp.cmd == ref_item.cmd) && (temp.mode == ref_item.mode) ? count : 0;
        count3 = (temp.cmd == ref_item.cmd) && (temp.mode == ref_item.mode) ? count3 : 0;
        temp.cmd = ref_item.cmd;
        temp.mode = ref_item.mode;
        ref_item.res = valid_a && valid_b ? temp.res : 'bz;
        ref_item.err = 1'bz;
        ref_item.cout = 1'bz;
        ref_item.g = 1'bz;
        ref_item.l = 1'bz;
        ref_item.e = 1'bz;
        ref_item.oflow = 1'bz;
        temp.opa = ref_item.inp_valid[0] ? ref_item.opa : temp.opa;
        temp.opb = ref_item.inp_valid[1] ? ref_item.opb : temp.opb;
        if(ref_item.mode) begin
          case(ref_item.cmd)
            4'd0: //ADD
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              de = delay();
              if(de == 2)
              begin
                ref_item.res = temp.opa + temp.opb;
                ref_item.err = 1'bz;
                ref_item.cout = ref_item.res[`DWIDTH];
                cmp = 1;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                ref_item.cout = 1'bz;
                cmp = 1;
              end
            end
            4'd1: //SUB
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              de = delay();
              if(de == 2)
              begin
                ref_item.res = temp.opa - temp.opb;
                ref_item.err = 1'bz;
                ref_item.oflow = ref_item.res[`DWIDTH];
                cmp = 1;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                ref_item.oflow = 1'bz;
                cmp = 1;
              end
            end
            4'd2: //ADD_CIN
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              de = delay();
              if(de == 2)
              begin
                ref_item.res = temp.opa + temp.opb + ref_item.cin;
                ref_item.err = 1'bz;
                ref_item.cout = ref_item.res[`DWIDTH];
                cmp = 1;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                ref_item.cout = 1'bz;
                cmp = 1;
              end
            end
            4'd3: //SUB_CIN
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              de = delay();
              if(de == 2)
              begin
                ref_item.res = temp.opa - temp.opb - ref_item.cin;
                ref_item.err = 1'bz;
                ref_item.oflow = ref_item.res[`DWIDTH];
                cmp = 1;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                ref_item.oflow = 1'bz;
                cmp = 1;
              end
            end
            4'd4: //INC A
            begin
              ref_item.res = ref_item.inp_valid[0] == 1'b1 ? (temp.opa + 1) : 'bz;
              ref_item.err = ref_item.inp_valid[0] == 1'b1 ? 1'bz :1'b1;
              cmp = 1;
            end
            4'd5: //DEC A
            begin
              ref_item.res = ref_item.inp_valid[0] == 1'b1 ? (temp.opa - 1) : 'bz;
              ref_item.err = ref_item.inp_valid[0] == 1'b1 ? 1'bz :1'b1;
              cmp = 1;
            end
            4'd6: //INC B
            begin
              ref_item.res = ref_item.inp_valid[1] == 1'b1 ? (temp.opb + 1) : 'bz;
              ref_item.err = ref_item.inp_valid[1] == 1'b1 ? 1'bz :1'b1;
              cmp = 1;
            end
            4'd7: //DEC B
            begin
              ref_item.res = ref_item.inp_valid[1] == 1'b1 ? (temp.opb - 1) : 'bz;
              ref_item.err = ref_item.inp_valid[1] == 1'b1 ? 1'bz :1'b1;
              cmp = 1;
            end
            4'd8: //CMP
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              de = delay();
              if(de == 2)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'bz;
                ref_item.g = temp.opa > temp.opb ? 1'b1 : 1'bz;
                ref_item.l = temp.opa < temp.opb ? 1'b1 : 1'bz;
                ref_item.e = temp.opa == temp.opb ? 1'b1 : 1'bz;
                cmp = 1;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                ref_item.cout = 1'bz;
                ref_item.g = 1'bz;
                ref_item.l = 1'bz;
                ref_item.e = 1'bz;
                cmp = 1;
              end
            end
            4'd9: //INC_MUL
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              de = delay();
              if(count == 0 && valid_a && valid_b) 
              begin
                cmp = 1;
                ref_item.res = ((temp.opa + 1) & {`DWIDTH{1'b1}}) * ((temp.opb + 1) & {`DWIDTH{1'b1}});
                ref_item.err = 1'bz;
                count = 0;
              end
              else if(de == 2)
              begin
                ref_item.res = ((temp.opa + 1) & {`DWIDTH{1'b1}}) * ((temp.opb + 1) & {`DWIDTH{1'b1}});
                ref_item.err = 1'bz;
                count = 0;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                count3 = 0;
                count = 0;
                cmp = 1;
              end
            end
            4'd10: //SH_MUL
            begin
              if(count == 0)
              begin
                {valid_b,valid_a} = ref_item.inp_valid;
              end
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              de = delay();
              if(count == 0 && valid_a && valid_b) 
              begin
                cmp = 1;
                ref_item.res = ((temp.opa << 1) & {`DWIDTH{1'b1}}) * (temp.opb);
                ref_item.err = 1'bz;
                count = 0;
              end
              if(de == 2)
              begin
                ref_item.res = ((temp.opa << 1) & {`DWIDTH{1'b1}}) * (temp.opb);
                ref_item.err = 1'bz;
                count = 0;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                count3 = 0;
                count = 0;
                cmp = 1;
              end
            end
            default:
            begin
              ref_item.res = 'bz;
              ref_item.err = 1'b1;
              ref_item.cout = 1'bz;
              ref_item.g = 1'bz;
              ref_item.l = 1'bz;
              ref_item.e = 1'bz;
              ref_item.oflow = 1'bz;
              cmp = 1;
            end
          endcase
        end
        else begin
          case(ref_item.cmd)
            4'd0: //AND
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] ? 1'b1 : valid_a;
                valid_b = ref_item.inp_valid[1] ? 1'b1 : valid_b;
              end
              de = delay();
              if(de == 2)
              begin
                ref_item.res = (temp.opa & temp.opb) & ({`DWIDTH{1'b1}});
                ref_item.err = 1'bz;
                cmp = 1;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                cmp = 1;
              end
            end
            4'd1: //NAND
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              de = delay();
              if(de == 2)
              begin
                ref_item.res = (~(temp.opa & temp.opb)) & ({`DWIDTH{1'b1}});
                ref_item.err = 1'bz;
                cmp = 1;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                cmp = 1;
              end
            end
            4'd2: //OR 
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              de = delay();
              if(de == 2)
              begin
                `uvm_info(get_name,"COMPLETED EXECUTION",UVM_DEBUG)
                ref_item.res = (temp.opa | temp.opb) & ({`DWIDTH{1'b1}});
                ref_item.err = 1'bz;
                cmp = 1;
              end
              else if(de == 0)
              begin
                `uvm_info(get_name,"OVERTIME/NO VALID",UVM_DEBUG)
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                cmp = 1;
              end
            end
            4'd3://NOR
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              de = delay();
              if(de == 2)
              begin
                ref_item.res = ~(temp.opa | temp.opb) & ({`DWIDTH{1'b1}});
                ref_item.err = 1'bz;
                cmp = 1;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                cmp = 1;
              end
            end
            4'd4: //XOR
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              de = delay();
              if(de == 2)
              begin
                ref_item.res = (temp.opa ^ temp.opb) & ({`DWIDTH{1'b1}});
                ref_item.err = 1'bz;
                cmp = 1;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                cmp = 1;
              end
            end
            4'd5: //XNOR
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              de = delay();
              if(de == 2)
              begin
                ref_item.res = ~(temp.opa ^ temp.opb) & ({`DWIDTH{1'b1}});
                ref_item.err = 1'bz;
                cmp = 1;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                cmp = 1;
              end
            end
            4'd6: //NOT_A
            begin
              ref_item.res = ref_item.inp_valid[0] == 1'b1 ? ~(ref_item.opa) & ({`DWIDTH{1'b1}}) : 'bz;
              ref_item.err = ref_item.inp_valid[0] == 1'b1 ? 1'bz : 1'b1;
              cmp = 1;
            end
            4'd7: //NOT_B
            begin
              ref_item.res = ref_item.inp_valid[1] == 1'b1 ? ~(ref_item.opb) & ({`DWIDTH{1'b1}}) : 'bz;
              ref_item.err = ref_item.inp_valid[1] == 1'b1 ? 1'bz : 1'b1;
              cmp = 1;
            end
            4'd8: //SHR1_A
            begin
              ref_item.res = ref_item.inp_valid[0] == 1'b1 ? (ref_item.opa >> 1) : 'bz;
              ref_item.err = ref_item.inp_valid[0] == 1'b1 ? 1'bz : 1'b1;
              cmp = 1;
            end
            4'd9: // SHL1_A
            begin
              ref_item.res = ref_item.inp_valid[0] == 1'b1 ? (temp.opa << 1) : 'bz;
              ref_item.err = ref_item.inp_valid[0] == 1'b1 ? 1'bz : 1'b1;
              cmp = 1;
            end
            4'd10: // SHR1_B
            begin
              ref_item.res = ref_item.inp_valid[1] == 1'b1 ? (temp.opb >> 1) : 'bz;
              ref_item.err = ref_item.inp_valid[1] == 1'b1 ? 1'bz : 1'b1;
              cmp = 1;
            end
            4'd11: // SHL1_B
            begin
              ref_item.res = ref_item.inp_valid[1] == 1'b1 ? (ref_item.opb << 1) : 'bz;
              ref_item.err = ref_item.inp_valid[1] == 1'b1 ? 1'bz : 1'b1;
              cmp = 1;
            end
            4'd12: // ROL_A_B
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              shft = valid_b ? temp.opb[`LOG2 - 1 : 0] : 'b0;
              de = delay();
              if(de == 2)
              begin
                ref_item.res = {1'b0,temp.opa << shft | temp.opa >> (`DWIDTH - shft)};
                ref_item.err = temp.opb[`DWIDTH - 1 : `LOG2 + 1] != 0 ? 1'b1 : 1'bz;
                cmp = 1;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                cmp = 1;
              end
            end
            4'd13: // ROR_A_B
            begin
              if(count == 0)
                {valid_b,valid_a} = ref_item.inp_valid;
              else begin
                valid_a = ref_item.inp_valid[0] == 1'b1 ? 1 : valid_a;
                valid_b = ref_item.inp_valid[1] == 1'b1 ? 1 : valid_b;
              end
              shft = valid_b ? temp.opb[`LOG2 - 1 : 0] : 'b0;
              de = delay();
              if(de == 2)
              begin
                ref_item.res = {1'b0,(temp.opa >> shft | temp.opa << (`DWIDTH - shft))};
                ref_item.err = temp.opb[`DWIDTH - 1 : `LOG2 + 1] != 0 ? 1'b1 : 1'bz;
                cmp = 1;
              end
              else if(de == 0)
              begin
                ref_item.res = 'bz;
                ref_item.err = 1'b1;
                cmp = 1;
              end
            end
            default:
            begin
              ref_item.res = 'bz;
              ref_item.err = 1'b1;
              ref_item.cout = 1'bz;
              ref_item.g = 1'bz;
              ref_item.l = 1'bz;
              ref_item.e = 1'bz;
              ref_item.oflow = 1'bz;
              cmp = 1;
            end
          endcase
        end
      end
      else begin
        ref_item.res = temp.res;
        ref_item.err = temp.err;
        ref_item.cout = temp.cout;
        ref_item.g = temp.g;
        ref_item.l = temp.l;
        ref_item.e = temp.e;
        ref_item.oflow = temp.oflow;
        //valid_a = valid_a;
        //valid_b = valid_b;
        cmp = 1;
      end
    end
    //@(vif.ref_cb);
    if(cmp == 1)
    begin
      iter++;
      `uvm_info(get_name,$sformatf("REF: ITERATION: %0d",iter),UVM_MEDIUM)
      if(get_report_verbosity_level() >= UVM_MEDIUM) 
      begin
        if(ref_item.mode)
          $display("CMD = %0s OPA = %0d OPB = %0d CIN = %0b\nRES = %0d ERR = %0b COUT = %0b OFLOW = %0b G,L,E = %3b",arith'(ref_item.cmd),temp.opa,temp.opb,ref_item.cin,ref_item.res,ref_item.err,ref_item.cout,ref_item.oflow,{ref_item.g,ref_item.l,ref_item.e});
        else
          $display("CMD = %0s\nOPA = %b\nOPB = %b\nOUTPUT:\nRES = %b ERR = %0b COUT = %0b OFLOW = %0b G,L,E = %3b",logical'(ref_item.cmd),ref_item.opa,ref_item.opb,ref_item.res,ref_item.err,ref_item.cout,ref_item.oflow,{ref_item.g,ref_item.l,ref_item.e}); 
      end
    end
    temp.err = ref_item.err;
    temp.cout = ref_item.cout;
    temp.g = ref_item.g;
    temp.l = ref_item.l;
    temp.e = ref_item.e;
    temp.oflow = ref_item.oflow;
  endtask
    
  function int delay();
    if({valid_a,valid_b} == 2'b00)
    begin
      count = 0;
      return 0;
    end
    if(count >= 15)
    begin
      count = 0;
      if(valid_a && valid_b)
        return 2;
      else
        return 0;//time passed trigger err
    end
    else if(count < 15)
    begin
      if(valid_a && valid_b)
      begin
        count = 0;
        return 2;//value is true return key
      end
    end
    count++;
    return 1;//time is calculated
  endfunction

endclass
