`include "defines.svh"
class alu_reference extends uvm_component;
  `uvm_component_utils(alu_reference)
  int de;
  int iter;
  int count;
  bit[2:0] count3;
  bit valid_a,valid_b;
  semaphore correct = new(1);

  alu_sequence_item ref_item;
  alu_sequence_item temp;

  uvm_analysis_imp#(alu_sequence_item,alu_reference)drv_2_ref;
  uvm_analysis_port#(alu_sequence_item)ref_2_scb;
  
  alu_sequence_item input_store[$];

  virtual alu_interface vif;

  logic[`LOG2 - 1 : 0] shft;

  function new(string name = "alu_ref",uvm_component parent = null);
    super.new(name,parent);
    drv_2_ref = new("drv_2_ref",this);
    ref_2_scb = new("ref_2_scb",this);
    temp = alu_sequence_item::type_id::create("temp");
    temp.res = 'bz;
    temp.err = 1'bz;
    temp.cout = 1'bz;
    temp.g = 1'bz;
    temp.l = 1'bz;
    temp.e = 1'bz;
    temp.oflow = 1'bz;
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual alu_interface)::get(this," ","vif",vif))
      `uvm_fatal(get_name,"INTERFACE NOT SET");
  endfunction
  
  function void write(alu_sequence_item t);
    alu_sequence_item drv = t;
    input_store.push_back(drv);
    `uvm_info(get_name,"[DRV] GOT INPUTS",UVM_MEDIUM)
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      ref_item = alu_sequence_item::type_id::create("ref_item");
      wait(input_store.size>0);
      ref_item = input_store.pop_front();
      `uvm_info(get_name,{"RECIEVED INPUTS"/*,ref_item.sprint*/},UVM_MEDIUM)
      void'(correct.try_get(1));
      $display("STARTED HERE");
      if(ref_item.rst)
      begin
      	//@(vif.drv_cb);
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
        correct.put(1);
      end
      else begin
        if(ref_item.ce) begin
          count = (temp.cmd == ref_item.cmd) && (temp.mode == ref_item.mode) ? count : 0;
          count3 = (temp.cmd == ref_item.cmd) && (temp.mode == ref_item.mode) ? count3 : 0;
          /*if(count3 > 0 || count > 0)
          begin
      	    @(vif.drv_cb);
          end*/
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
                  correct.put(1);
                end
                else if(de == 0)
                begin
                  ref_item.res = 'bz;
                  ref_item.err = 1'b1;
                  ref_item.cout = 1'bz;
                  correct.put(1);
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
                  correct.put(1);
                end
                else if(de == 0)
                begin
                  ref_item.res = 'bz;
                  ref_item.err = 1'b1;
                  ref_item.oflow = 1'bz;
                  correct.put(1);
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
                  correct.put(1);
                end
                else if(de == 0)
                begin
                  ref_item.res = 'bz;
                  ref_item.err = 1'b1;
                  ref_item.cout = 1'bz;
                  correct.put(1);
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
                  correct.put(1);
                end
                else if(de == 0)
                begin
                  ref_item.res = 'bz;
                  ref_item.err = 1'b1;
                  ref_item.oflow = 1'bz;
                  correct.put(1);
                end
              end
              4'd4: //INC A
              begin
                ref_item.res = ref_item.inp_valid[0] == 1'b1 ? (temp.opa + 1) : 'bz;
                ref_item.err = ref_item.inp_valid[0] == 1'b1 ? 1'bz :1'b1;
                correct.put(1);
              end
              4'd5: //DEC A
              begin
                ref_item.res = ref_item.inp_valid[0] == 1'b1 ? (temp.opa - 1) : 'bz;
                ref_item.err = ref_item.inp_valid[0] == 1'b1 ? 1'bz :1'b1;
                correct.put(1);
              end
              4'd6: //INC B
              begin
                ref_item.res = ref_item.inp_valid[1] == 1'b1 ? (temp.opb + 1) : 'bz;
                ref_item.err = ref_item.inp_valid[1] == 1'b1 ? 1'bz :1'b1;
                correct.put(1);
              end
              4'd7: //DEC B
              begin
                ref_item.res = ref_item.inp_valid[1] == 1'b1 ? (temp.opb - 1) : 'bz;
                ref_item.err = ref_item.inp_valid[1] == 1'b1 ? 1'bz :1'b1;
                correct.put(1);
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
                  correct.put(1);
                end
                else if(de == 0)
                begin
                  ref_item.res = 'bz;
                  ref_item.err = 1'b1;
                  ref_item.cout = 1'bz;
                  ref_item.g = 1'bz;
                  ref_item.l = 1'bz;
                  ref_item.e = 1'bz;
                  correct.put(1);
                end
              end
              4'd9: //INC_MUL
              begin
                if(count3 > 0 &&  count3 < 3)
                begin
                  count3++;
                  `uvm_info(get_name,$sformatf("COUNT = %0d",count3),UVM_MEDIUM);
                end
                else if(count3 >= 3)
                begin
                  count3 = 0;
                  count = 0;
                  ref_item.res = ((temp.opa + 1) & {`DWIDTH{1'b1}}) * ((temp.opb + 1) & {`DWIDTH{1'b1}});
                  correct.put(1);
                end
                else
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
                    ref_item.res = ((temp.opa + 1) & {`DWIDTH{1'b1}}) * ((temp.opb + 1) & {`DWIDTH{1'b1}});
                    ref_item.err = 1'bz;
                    count3++;
                    count = 0;
                  end
                  else if(de == 0)
                  begin
                    ref_item.res = 'bz;
                    ref_item.err = 1'b1;
                    count3 = 0;
                    count = 0;
                    correct.put(1);
                  end
                end
              end
              4'd10: //SH_MUL
              begin
                if(count3 > 0 && count3 < 3)
                begin
                  count3++;
                  `uvm_info(get_name,$sformatf("COUNT = %0d",count3),UVM_MEDIUM);
                end
                else if(count3 >= 3)
                begin
                  correct.put(1);
                  count3 = 0;
                  count = 0;
                  ref_item.res = ((temp.opa << 1) & {`DWIDTH{1'b1}}) * (temp.opb);
                end
                else
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
                  if(de == 2)
                  begin
                    ref_item.res = ((temp.opa << 1) & {`DWIDTH{1'b1}}) * (temp.opb);
                    ref_item.err = 1'bz;
                    count3++;
                    count = 0;
                  end
                  else if(de == 0)
                  begin
                    ref_item.res = 'bz;
                    ref_item.err = 1'b1;
                    count3 = 0;
                    count = 0;
                    correct.put(1);
                  end
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
                correct.put(1);
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
                  correct.put(1);
                end
                else if(de == 0)
                begin
                  ref_item.res = 'bz;
                  ref_item.err = 1'b1;
                  correct.put(1);
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
                  correct.put(1);
                end
                else if(de == 0)
                begin
                  ref_item.res = 'bz;
                  ref_item.err = 1'b1;
                  correct.put(1);
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
                  correct.put(1);
                end
                else if(de == 0)
                begin
                  `uvm_info(get_name,"OVERTIME/NO VALID",UVM_DEBUG)
                  ref_item.res = 'bz;
                  ref_item.err = 1'b1;
                  correct.put(1);
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
                  correct.put(1);
                end
                else if(de == 0)
                begin
                  ref_item.res = 'bz;
                  ref_item.err = 1'b1;
                  correct.put(1);
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
                  correct.put(1);
                end
                else if(de == 0)
                begin
                  ref_item.res = 'bz;
                  ref_item.err = 1'b1;
                  correct.put(1);
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
                  correct.put(1);
                end
                else if(de == 0)
                begin
                  ref_item.res = 'bz;
                  ref_item.err = 1'b1;
                  correct.put(1);
                end
              end
              4'd6: //NOT_A
              begin
                ref_item.res = ref_item.inp_valid[0] == 1'b1 ? ~(ref_item.opa) & ({`DWIDTH{1'b1}}) : 'bz;
                ref_item.err = ref_item.inp_valid[0] == 1'b1 ? 1'bz : 1'b1;
                correct.put(1);
              end
              4'd7: //NOT_B
              begin
                ref_item.res = ref_item.inp_valid[1] == 1'b1 ? ~(ref_item.opb) & ({`DWIDTH{1'b1}}) : 'bz;
                ref_item.err = ref_item.inp_valid[1] == 1'b1 ? 1'bz : 1'b1;
                correct.put(1);
              end
              4'd8: //SHR1_A
              begin
                ref_item.res = ref_item.inp_valid[0] == 1'b1 ? (ref_item.opa >> 1) : 'bz;
                ref_item.err = ref_item.inp_valid[0] == 1'b1 ? 1'bz : 1'b1;
                correct.put(1);
              end
              4'd9: // SHL1_A
              begin
                ref_item.res = ref_item.inp_valid[0] == 1'b1 ? (temp.opa << 1) : 'bz;
                ref_item.err = ref_item.inp_valid[0] == 1'b1 ? 1'bz : 1'b1;
                correct.put(1);
              end
              4'd10: // SHR1_B
              begin
                ref_item.res = ref_item.inp_valid[1] == 1'b1 ? (temp.opb >> 1) : 'bz;
                ref_item.err = ref_item.inp_valid[1] == 1'b1 ? 1'bz : 1'b1;
                correct.put(1);
              end
              4'd11: // SHL1_B
              begin
                ref_item.res = ref_item.inp_valid[1] == 1'b1 ? (ref_item.opb << 1) : 'bz;
                ref_item.err = ref_item.inp_valid[1] == 1'b1 ? 1'bz : 1'b1;
                correct.put(1);
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
                  correct.put(1);
                end
                else if(de == 0)
                begin
                  ref_item.res = 'bz;
                  ref_item.err = 1'b1;
                  correct.put(1);
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
                  correct.put(1);
                end
                else if(de == 0)
                begin
                  ref_item.res = 'bz;
                  ref_item.err = 1'b1;
                  correct.put(1);
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
                correct.put(1);
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
          correct.put(1);
        end
      end
      //@(vif.ref_cb);
      if(correct.try_get(1))
      begin
        iter++;
        `uvm_info(get_name,$sformatf("REF: ITERATION: %0d",iter),UVM_MEDIUM)
        ref_2_scb.write(ref_item);
        /*if(get_report_verbosity_level() >= UVM_MEDIUM) 
        begin
          if(ref_item.mode)
            $display("CMD = %0s OPA = %0d OPB = %0d CIN = %0b\nRES = %0d ERR = %0b COUT = %0b OFLOW = %0b G,L,E = %3b",arith'(ref_item.cmd),temp.opa,temp.opb,ref_item.cin,ref_item.res,ref_item.err,ref_item.cout,ref_item.oflow,{ref_item.g,ref_item.l,ref_item.e});
          else
            $display("CMD = %0s\nOPA = %b\nOPB = %b\nOUTPUT:\nRES = %b ERR = %0b COUT = %0b OFLOW = %0b G,L,E = %3b",logical'(ref_item.cmd),ref_item.opa,ref_item.opb,ref_item.res,ref_item.err,ref_item.cout,ref_item.oflow,{ref_item.g,ref_item.l,ref_item.e}); 
        end*/
      end
      temp.err = ref_item.err;
      temp.cout = ref_item.cout;
      temp.g = ref_item.g;
      temp.l = ref_item.l;
      temp.e = ref_item.e;
      temp.oflow = ref_item.oflow;
    end
  endtask

  function int delay();
    if({valid_a,valid_b} == 2'b00)
    begin
      count = 0;
      return 0;
    end
    if(count >= 16)
    begin
      count = 0;
      if(valid_a && valid_b)
        return 2;
      else
        return 0;//time passed trigger err
    end
    else if(count < 16)
    begin
      if(valid_a && valid_b)
      begin
        count = 0;
        return 2;//value is true return key
      end
    end
    count++;
    `uvm_info(get_name,$sformatf("REF: COUNTING = %0d",count),UVM_MEDIUM)
    return 1;//time is calculated
  endfunction
endclass
