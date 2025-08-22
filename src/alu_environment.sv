class alu_environment extends uvm_env;
  alu_agent agnt_a;
  alu_agent agnt_p;
  alu_subscriber subs;
  alu_scoreboard scb;
  alu_reference alu_ref;
  `uvm_component_utils(alu_environment)

  function new(string name = "env", uvm_component parent = null);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agnt_a = alu_agent::type_id::create("agnt_a",this);
    agnt_p = alu_agent::type_id::create("agnt_p",this);
    set_config_int("agnt_a", "is_active", UVM_ACTIVE);
    set_config_int("agnt_p", "is_active", UVM_PASSIVE);
    subs = alu_subscriber::type_id::create("subs",this);
    scb = alu_scoreboard::type_id::create("scb",this);
    alu_ref = alu_reference::type_id::create("alu_ref",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agnt_a.mon.mon_item_collect_port.connect(alu_ref.drv_2_ref);
    agnt_a.mon.mon_item_collect_port.connect(subs.analysis_export);
    agnt_p.mon.mon_item_collect_port.connect(subs.subs_mon_op_item_collect_export);
    agnt_p.mon.mon_item_collect_port.connect(scb.mon_2_scb);
    alu_ref.ref_2_scb.connect(scb.ref_2_scb);
  endfunction

endclass
