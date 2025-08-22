class alu_agent extends uvm_agent;
  alu_driver drv;
  alu_monitor mon;
  alu_sequencer seqr;
  alu_reference alu_ref;
  `uvm_component_utils(alu_agent)

  function new(string name = "agnt", uvm_component parent = null);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(get_is_active() == UVM_ACTIVE)
    begin
      drv = alu_driver::type_id::create("drv",this);
      seqr = alu_sequencer::type_id::create("seqr",this);
    end
    mon = alu_monitor::type_id::create("mon",this);
    alu_ref = alu_reference::type_id::create("alu_ref",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(get_is_active() == UVM_ACTIVE)
    begin
      drv.seq_item_port.connect(seqr.seq_item_export);
      drv.drv_item_collect_port.connect(alu_ref.drv_2_ref);
    end
  endfunction

endclass