class alu_agent extends uvm_agent;
  alu_driver drv;
  alu_monitor mon;
  alu_sequencer seqr;
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
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(get_is_active() == UVM_ACTIVE)
    begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction

endclass
