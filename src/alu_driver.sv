typedef enum{ADD,SUB,ADD_CIN,SUB_CIN,INC_A,DEC_A,INC_B,DEC_B,CMP,ADD_MUL,SH_MUL}arith;
typedef enum{AND,NAND,OR,NOR,XOR,XNOR,NOT_A,NOT_B,SHR1_A,SHL1_A,SHR1_B,SHL1_B,ROL_A_B,ROR_A_B}logical;
class alu_driver extends uvm_driver#(alu_sequence_item);
  bit flag;
  int count;
  int count3;
  bit valid_a,valid_b;
  alu_sequence_item temp;
  int i;
  virtual alu_interface vif;
  `uvm_component_utils(alu_driver)
  uvm_analysis_port#(alu_sequence_item)drv_item_collect_port;
  
  function new(string name = "drv", uvm_component parent = null);
    super.new(name,parent);
    drv_item_collect_port = new("drv_item_collect_port",this);
    temp = alu_sequence_item::type_id::create("temp_item");
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual alu_interface)::get(this,"","vif",vif))
      `uvm_fatal(get_name,"INTERFACE NOT SET")
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    repeat(3)@(vif.drv_cb);
    forever begin
      seq_item_port.get_next_item(req);
      drive();
      seq_item_port.item_done();
    end
  endtask

  task drive(); 
    repeat(1)@(vif.drv_cb);
    vif.drv_cb.opa <= req.opa;       
    vif.drv_cb.opb <= req.opb;
    vif.drv_cb.rst <= req.rst;
    vif.drv_cb.ce  <= req.ce;
    vif.drv_cb.mode <= req.mode;
    vif.drv_cb.cin <= req.cin;
    vif.drv_cb.cmd <= req.cmd;
    vif.drv_cb.inp_valid <= req.inp_valid;

    if(req.ce) begin
      flag = ((req.mode && (req.cmd == 0 || req.cmd == 1 || req.cmd == 2 || req.cmd == 3 || req.cmd == 8 || req.cmd == 9 || req.cmd == 10)) || (!req.mode && (req.cmd == 0 || req.cmd == 1 || req.cmd == 2 || req.cmd == 3 || req.cmd == 4 || req.cmd == 5  || req.cmd == 12  || req.cmd == 13))) && !req.rst;

      valid_a = flag && (req.inp_valid[0]) ? 1'b1 : valid_a;

      valid_b = flag && (req.inp_valid[1]) ? 1'b1 : valid_b;

      count3 = ((req.cmd == temp.cmd)&&(req.mode == temp.mode)) ? count3 : 0;

      if(flag == 0)
      begin
        valid_a = 0;
        valid_b = 0;
        count = 0;
        count3 = 0;
        repeat(2)@(vif.drv_cb); 
      end
      else if(count3 > 0)
      begin
        valid_a = 0;
        valid_b = 0;
        count = 0;
        count3++;
        if(count3 >= 3)
        begin
          count3 = 0;
          repeat(1)@(vif.drv_cb);
        end
        repeat(2)@(vif.drv_cb);
      end
      else if(valid_a && valid_b)
      begin 
        valid_a = 0;
        valid_b = 0;
        count = 0;
        if(req.mode && (req.cmd == 9 || req.cmd == 10))
        begin
          count3 = 1;
          //repeat(1)@(vif.drv_cb);
        end
        else
          repeat(2)@(vif.drv_cb);
      end
      else if(count < 16 && (valid_a || valid_b))
      begin
        $display("ENTERED BY MISTAKE");
        if(count == 0)
        begin
          repeat(1)@(vif.drv_cb);
        end
        count3 = 0;
        count++;
      end
      else if(count >= 16) 
      begin
        count = 0;
        valid_a = 0;
        valid_b = 0;
        count3 = 0;
        flag = 0;
        @(vif.drv_cb);
      end
      else
        repeat(2)@(vif.drv_cb);
    end
    else
      @(vif.drv_cb);
    
    temp.cmd = req.cmd;
    temp.mode = req.mode;

    drv_item_collect_port.write(req);

    $display("\n--------------------------------------------------------------------------%0d-------------------------------------------------------------------------",i+1);
    `uvm_info(get_name,{"DRIVEN INPUTS"/*,req.sprint*/},UVM_MEDIUM)
    `uvm_info(get_name,$sformatf("FLAG = %0b, VALID_A = %0b, VALID_B = %0b",flag,valid_a,valid_b),UVM_MEDIUM)
    `uvm_info(get_name,$sformatf("COUNT3 = %0d",count3),UVM_MEDIUM)
    `uvm_info(get_name,$sformatf("COUNT = %0d",count),UVM_MEDIUM)
    i++;
    if(get_report_verbosity_level() >= UVM_MEDIUM)
    begin
      if(req.mode)
        $display("RST = %0b CE = %1b\nINP_VALID = %2b MODE = %1b CMD = %0s\nOPA = %0d OPB = %0d CIN = %0b",req.rst,req.ce,req.inp_valid,req.mode,arith'(req.cmd),req.opa,req.opb,req.cin);
      else
        $display("RST = %0b CE = %1b\nINP_VALID = %2b MODE = %1b CMD = %0s\nOPA = %b\nOPB = %b",req.rst,req.ce,req.inp_valid,req.mode,logical'(req.cmd),req.opa,req.opb);
      $display("DRV: COMPLETED %0d ITERATIONS",i);
    end
  endtask
endclass
