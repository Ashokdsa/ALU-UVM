class alu_monitor extends uvm_monitor;
  bit flag;
  int count;
  bit valid_a,valid_b;
  int i;
  alu_sequence_item temp;
  virtual alu_interface vif;
  uvm_analysis_port#(alu_sequence_item)mon_item_collect_port;
  alu_sequence_item seq_item;

  `uvm_component_utils(alu_monitor)
  
  function new(string name = "mon", uvm_component parent = null);
    super.new(name,parent);
    seq_item = alu_sequence_item::type_id::create("seq_item");
    mon_item_collect_port = new("mon_item_collect_port",this);
    temp = alu_sequence_item::type_id::create("mon_temp_item");
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual alu_interface)::get(this,"","vif",vif))
      `uvm_fatal(get_name,"INTERFACE NOT SET")
  endfunction

  task run_phase(uvm_phase phase);
    repeat(4)@(vif.mon_cb);
    forever begin
      repeat(1)@(vif.mon_cb);
      seq_item.opa = vif.mon_cb.opa;      
      seq_item.opb = vif.mon_cb.opb;      
      seq_item.rst = vif.mon_cb.rst;      
      seq_item.ce = vif.mon_cb.ce; 
      seq_item.mode = vif.mon_cb.mode;
      seq_item.cin = vif.mon_cb.cin;
      seq_item.cmd = vif.mon_cb.cmd;
      seq_item.inp_valid = vif.mon_cb.inp_valid;
      if(seq_item.ce)
      begin
        flag = ((seq_item.mode && (seq_item.cmd == 0 || seq_item.cmd == 1 || seq_item.cmd == 2 || seq_item.cmd == 3 || seq_item.cmd == 8 || seq_item.cmd == 9 || seq_item.cmd == 10)) || (!seq_item.mode && (seq_item.cmd == 0 || seq_item.cmd == 1 || seq_item.cmd == 2 || seq_item.cmd == 3 || seq_item.cmd == 4 || seq_item.cmd == 5  || seq_item.cmd == 12  || seq_item.cmd == 13))) && !seq_item.rst;

        valid_a = flag && (seq_item.inp_valid[0]) ? 1'b1 : valid_a;

        valid_b = flag && (seq_item.inp_valid[1]) ? 1'b1 : valid_b;
        `uvm_info(get_name,"READING INPUTS",UVM_DEBUG)

        `uvm_info(get_name,$sformatf("1:FLAG = %0b, VALID_A = %0b, VALID_B = %0b",flag,valid_a,valid_b),UVM_DEBUG)
        `uvm_info(get_name,$sformatf("3:COUNT = %0d",count),UVM_DEBUG)

        if(flag == 0)
        begin
          $display("%0t | SINGLE OP",$time);
          count = 0;
          valid_a = 0;
          valid_b = 0;
          repeat(2)@(vif.mon_cb);
        end
        else if(valid_a && valid_b)
        begin
          count = 0;
          if(seq_item.mode && (seq_item.cmd == 9 || seq_item.cmd == 10))
          begin
            $display("%0t | ENTERED MON MULT",$time);
            repeat(1)@(vif.mon_cb);
          end
          valid_a = 0;
          valid_b = 0;
          repeat(2)@(vif.mon_cb);
        end
        else if(count < 15 && (valid_a || valid_b))
        begin
          $display("ENTERED BY MISTAKE");
          count = ((seq_item.cmd == temp.cmd) && (seq_item.mode == temp.mode)) ? count+1:0;
          if(count == 0)
          begin
            $display("DELAYED");
            repeat(1)@(vif.mon_cb);
          end
        end
        else if(count >= 15)
        begin
          $display("%0t | COUNT OUT",$time);
          count = 0;
          valid_a = 0;
          valid_b = 0;
          flag = 0;
          repeat(2)@(vif.mon_cb);
        end
        else
        begin
          $display("%0t | UNKNOWN",$time);
          repeat(2)@(vif.mon_cb);
        end
      end

      temp.cmd =seq_item.cmd;
      temp.mode = seq_item.mode;
      seq_item.res = vif.mon_cb.res;
      seq_item.cout = vif.mon_cb.cout;
      seq_item.oflow = vif.mon_cb.oflow;
      seq_item.g = vif.mon_cb.g;
      seq_item.e = vif.mon_cb.e;
      seq_item.l = vif.mon_cb.l;
      seq_item.err = vif.mon_cb.err; 

      i = i + 1;
      `uvm_info(get_name,$sformatf("MON: RECIEVED %0d ITEM",i),UVM_MEDIUM);
      `uvm_info(get_name,$sformatf("FLAG = %0b, VALID_A = %0b, VALID_B = %0b",flag,valid_a,valid_b),UVM_MEDIUM)
      `uvm_info(get_name,$sformatf("COUNT = %0d",count),UVM_MEDIUM)
      if(get_report_verbosity_level() >= UVM_MEDIUM)
      begin
        if(seq_item.mode)
          $display("RESULT = %0d\nOFLOW = %1b COUT = %1b G = %1b L = %1b E = %1b",seq_item.res,seq_item.oflow,seq_item.cout,seq_item.g,seq_item.l,seq_item.e);
        else
          $display("RESULT = %b\nOFLOW = %1b COUT = %1b G = %1b L = %1b E = %1b",seq_item.res,seq_item.oflow,seq_item.cout,seq_item.g,seq_item.l,seq_item.e);
      end
      mon_item_collect_port.write(seq_item);
      `uvm_info(get_name,"SENT TO SCB",UVM_MEDIUM)
    end
  endtask

endclass
