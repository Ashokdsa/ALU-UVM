typedef enum{ADD,SUB,ADD_CIN,SUB_CIN,INC_A,DEC_A,INC_B,DEC_B,CMP,ADD_MUL,SH_MUL}arith;
typedef enum{AND,NAND,OR,NOR,XOR,XNOR,NOT_A,NOT_B,SHR1_A,SHL1_A,SHR1_B,SHL1_B,ROL_A_B,ROR_A_B}logical;
class alu_driver extends uvm_driver#(alu_sequence_item);
  bit flag;
  int count;
  bit valid_a,valid_b;
  alu_sequence_item temp;
  int i;
  virtual alu_interface vif;
  `uvm_component_utils(alu_driver)
  
  function new(string name = "drv", uvm_component parent = null);
    super.new(name,parent);
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

      valid_a = flag && (req.inp_valid[0]) ? 1'b1 : (((req.mode == temp.mode)&&(req.cmd == temp.mode)) ? valid_a : 0);

      valid_b = flag && (req.inp_valid[1]) ? 1'b1 : (((req.mode == temp.mode)&&(req.cmd == temp.mode)) ? valid_b : 0);

      `uvm_info(get_name,"INPUT SENT",UVM_MEDIUM)

      `uvm_info(get_name,$sformatf("INPUT VALID = %2b",req.inp_valid),UVM_DEBUG)

      `uvm_info(get_name,$sformatf("1:FLAG = %0b, VALID_A = %0b, VALID_B = %0b",flag,valid_a,valid_b),UVM_MEDIUM)
      `uvm_info(get_name,$sformatf("3:COUNT = %0d",count),UVM_MEDIUM)

      if(flag == 0)
      begin
        $display("%0t | DRV: SINGLE OP",$time);
        valid_a = 0;
        valid_b = 0;
        count = 0;
        repeat(2)@(vif.drv_cb); 
      end
      else if(valid_a && valid_b)
      begin 
        count = 0;
        if(req.mode && (req.cmd == 9 || req.cmd == 10))
        begin
          $display("%0t | ENTERED DRV MULT",$time);
          repeat(1)@(vif.mon_cb);
        end
        valid_a = 0;
        valid_b = 0;
        repeat(2)@(vif.drv_cb);
      end
      else if(count < 15 && (valid_a || valid_b))
      begin
        $display("ENTERED BY MISTAKE");
        count = ((req.cmd == temp.cmd) && (req.mode == temp.mode)) ? count+1:0;
        if(count == 0)
        begin
          repeat(1)@(vif.drv_cb);
        end
      end
      else if(count >= 15) 
      begin
          $display("%0t |DRV: COUNT OUT",$time);
        count = 0;
        valid_a = 0;
        valid_b = 0;
        flag = 0;
        repeat(2)@(vif.drv_cb);
      end
      else
      begin
          $display("%0t |DRV: UNKNOWN",$time);
        repeat(2)@(vif.drv_cb);
      end
    end
    
    temp.cmd = req.cmd;
    temp.mode = req.mode;

    $display("\n--------------------------------------------------------------------------%0d-------------------------------------------------------------------------",i+1);
    `uvm_info(get_name,{"DRIVEN INPUTS"/*,req.sprint*/},UVM_MEDIUM)
    `uvm_info(get_name,$sformatf("FLAG = %0b, VALID_A = %0b, VALID_B = %0b",flag,valid_a,valid_b),UVM_MEDIUM)
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
