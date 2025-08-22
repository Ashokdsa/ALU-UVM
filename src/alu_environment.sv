class alu_environment extends uvm_env;
  alu_agent agnt;
  alu_subscriber subs;
  alu_scoreboard scb;
  `uvm_component_utils(alu_environment)

  function new(string name = "env", uvm_component parent = null);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agnt = alu_agent::type_id::create("agnt",this);
    subs = alu_subscriber::type_id::create("subs",this);
    scb = alu_scoreboard::type_id::create("scb",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agnt.drv.drv_item_collect_port.connect(subs.analysis_export);
    agnt.mon.mon_item_collect_port.connect(subs.subs_mon_op_item_collect_export);
    agnt.mon.mon_item_collect_port.connect(scb.mon_2_scb);
    agnt.alu_ref.ref_2_scb.connect(scb.ref_2_scb);
  endfunction

endclass