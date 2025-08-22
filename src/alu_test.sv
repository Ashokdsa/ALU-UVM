class alu_test extends uvm_test;
  `uvm_component_utils(alu_test)
  alu_environment env;
  base_sequence seq;
  
  function new(string name = "alu_test", uvm_component parent = null);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    //base_sequence::type_id::set_type_override(alu_sequence::get_type());
    //base_sequence::type_id::set_type_override(alu_glo_sequence::get_type());
    //base_sequence::type_id::set_type_override(alu_err_sequence::get_type());
    //base_sequence::type_id::set_type_override(alu_corner_sequence::get_type());
    //base_sequence::type_id::set_type_override(alu_time_sequence::get_type());
    //base_sequence::type_id::set_type_override(alu_w_time_sequence::get_type());
    //base_sequence::type_id::set_type_override(alu_flag_sequence::get_type());
    //base_sequence::type_id::set_type_override(alu_mult_sequence::get_type());
    //base_sequence::type_id::set_type_override(alu_mult_time_sequence::get_type());
    //base_sequence::type_id::set_type_override(alu_crn_mult_sequence::get_type());
    base_sequence::type_id::set_type_override(regression_sequence::get_type());
    env = alu_environment::type_id::create("env",this);
  endfunction

  function void end_of_elaboration();
    uvm_top.print_topology();
  endfunction

  task run_phase(uvm_phase phase);
    uvm_objection phase_done = phase.get_objection();
    super.run_phase(phase);
    phase.raise_objection(this,"DRIVER BEGUN");
      seq = base_sequence::type_id::create("seq");
      seq.start(env.agnt_a.seqr);
    phase.drop_objection(this,"DRIVER ENDED");
    phase_done.set_drain_time(this,20);
  endtask

endclass
