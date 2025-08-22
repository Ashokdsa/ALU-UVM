//BASE SEQUENCE TO BE OVERRIDEN
class base_sequence extends uvm_sequence#(alu_sequence_item);
  `uvm_object_utils(base_sequence)
  alu_sequence_item seq;
  bit [`CWIDTH:0]previ[$];

  function new(string name = "base_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_fatal(get_name,"DID NOT OVERRIDE THE BASE")
    `uvm_do(seq)
  endtask

  virtual function void sizing();
  endfunction 
endclass

//NORMAL SEQUENCE 
class alu_sequence extends base_sequence;
  `uvm_object_utils(alu_sequence)

  function new(string name = "seq");
    super.new(name);
  endfunction

  virtual task body();
    while(previ.size > 0)
      void'(previ.pop_front());
      $display("-------------------------------------------------------------NORMAL SEQUENCE STARTED-------------------------------------------------------------");
    repeat(30) begin
      seq = alu_sequence_item::type_id::create("normal_seq_item");
      wait_for_grant();
      seq.exec = 0;
      assert(seq.randomize() with 
      {
        foreach(previ[i]) 
          {seq.mode,seq.cmd} != previ[i];
      })
      else
        `uvm_fatal(get_name,"RANDOMIZATION FAILED")
      previ.push_back({seq.mode,seq.cmd});
      send_request(seq);
      wait_for_item_done();
      sizing();
      `uvm_info(get_name,"SEQUENCE SENT",UVM_DEBUG)
    end
  endtask

  virtual function void sizing();
    if(previ.size >= 23) //give the size for each test
    begin
      while(previ.size > 0)
        void'(previ.pop_front);
    end
  endfunction 

endclass

//GLOBAL SEQUENCE 
class alu_glo_sequence extends base_sequence;
  `uvm_object_utils(alu_glo_sequence)
  
  function new(string name = "glo_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    while(previ.size > 0)
      void'(previ.pop_front());
    seq = alu_sequence_item::type_id::create("glo_seq_item");
    repeat(15) begin
      `uvm_info(get_name,"SEQUENCE SENT",UVM_DEBUG)
      seq.normal_global.constraint_mode(0);
      wait_for_grant();
      seq.exec = 1;
      assert(seq.randomize() with 
      {
        foreach(previ[i])
          {seq.rst,seq.ce} != previ[i];
      })
      else
        `uvm_fatal(get_name,"RANDOMIZATION FAILED")
      previ.push_back({seq.rst,seq.ce});
      send_request(seq);
      wait_for_item_done();
      sizing();
      `uvm_info(get_name,"SEQUENCE SENT",UVM_DEBUG)
    end
  endtask

  virtual function void sizing();
    if(previ.size >= 4) //give the size for each test
    begin
      while(previ.size > 0)
        void'(previ.pop_front);
    end
  endfunction 
endclass

//ERRORNEOUS SEQUENCE 
class alu_err_sequence extends base_sequence;
  `uvm_object_utils(alu_err_sequence)

  function new(string name = "err_seq");
    super.new(name);
  endfunction

  virtual task body();
    while(previ.size > 0)
      void'(previ.pop_front());
      $display("-------------------------------------------------------------ERROR SEQUENCE STARTED-------------------------------------------------------------");
    repeat(20) begin
      seq = alu_sequence_item::type_id::create("err_seq_item");
      seq.normal_cmd_mode.constraint_mode(0);
      seq.normal_inp_val.constraint_mode(0);
      wait_for_grant();
      seq.exec = 2;
      assert(seq.randomize() with 
      {
        if(seq.mode)
        {
          if(seq.cmd == 4 || seq.cmd == 5)
            inp_valid != 2'b11 && inp_valid != 2'b01;
          else if(seq.cmd == 6 || seq.cmd == 7)
            inp_valid != 2'b11 && inp_valid != 2'b10;
          else 
            inp_valid == 2'b00;
        }
        else
        {
          if(seq.cmd == 6 || seq.cmd == 8 || seq.cmd == 9)
            inp_valid != 2'b11 && inp_valid != 2'b01;
          else if(seq.cmd == 7 || seq.cmd == 10 || seq.cmd == 11)
            inp_valid != 2'b11 && inp_valid != 2'b10;
          else 
            inp_valid == 2'b00;
        }
        foreach(previ[i]) 
          {seq.mode,seq.cmd} != previ[i];
      })
      else
        `uvm_fatal(get_name,"RANDOMIZATION FAILED")
      previ.push_back({seq.mode,seq.cmd});
      send_request(seq);
      wait_for_item_done();
      sizing();
      `uvm_info(get_name,"SEQUENCE SENT",UVM_DEBUG)
    end
  endtask

  virtual function void sizing();
    if(previ.size >= 32) //give the size for each test
    begin
      while(previ.size > 0)
        void'(previ.pop_front);
    end
  endfunction 
endclass

//CORNER SEQUENCE 
class alu_corner_sequence extends base_sequence;
  rand int count;
  `uvm_object_utils(alu_corner_sequence)

  function new(string name = "crn_seq");
    super.new(name);
  endfunction

  virtual task body();
    while(previ.size > 0)
      void'(previ.pop_front());
      $display("-------------------------------------------------------------CORNER SEQUENCE STARTED-------------------------------------------------------------");
    repeat(8) begin
      seq = alu_sequence_item::type_id::create("crn_seq_item");
      seq.normal_cmd_mode.constraint_mode(0);
      wait_for_grant();
      seq.exec = 3;
      assert(seq.randomize() with 
      {
        if(seq.mode)
          seq.cmd inside {1,3,[4:7]};
        else
          seq.cmd inside {9,11};
        if(seq.mode)
        {
          if(seq.cmd == 1 || seq.cmd == 3)
            opa < opb;
          else if(seq.cmd == 6 || seq.cmd == 4)
            opa == 8'b11111111 && opb == 8'b11111111;
          else 
            opa == 8'b00000000 && opb == 8'b00000000;
        }
        else
        {
          if(seq.cmd == 9)
            opa == 8'b11111111 || opb == 8'b11111111;
          else
            opa == 8'b10000000;
        }
        foreach(previ[i]) 
          {seq.mode,seq.cmd} != previ[i];
      })
      else
        `uvm_fatal(get_name,"RANDOMIZATION FAILED")
      previ.push_back({seq.mode,seq.cmd});
      send_request(seq);
      wait_for_item_done();
      sizing();
      `uvm_info(get_name,"SEQUENCE SENT",UVM_DEBUG)
    end
  endtask

  virtual function void sizing();
    if(previ.size >= 8) //give the size for each test
    begin
      while(previ.size > 0)
        void'(previ.pop_front);
    end
  endfunction 

endclass

//16 CLK CYCLE SEQUENCE 
class alu_time_sequence extends base_sequence;
  rand int count;
  bit valid_a,valid_b;
  `uvm_object_utils(alu_time_sequence)
  
  function new(string name = "time_seq");
    super.new(name);
    assert(std::randomize(count) with {count inside {[1:15]};}) `uvm_info(get_name,$sformatf("count = %0d",count),UVM_DEBUG) else `uvm_fatal(get_name,"No Delay")
    `uvm_info(get_name,$sformatf("COUNT = %0d",count),UVM_DEBUG)
  endfunction

  virtual task body();
    while(previ.size > 0)
      void'(previ.pop_front());
    seq = alu_sequence_item::type_id::create("time_seq");
      $display("-------------------------------------------------------------TIME SEQUENCE STARTED-------------------------------------------------------------");
    repeat(50) begin
      seq.normal_cmd_mode.constraint_mode(0);
      seq.normal_inp_val.constraint_mode(0);
      wait_for_grant();
      seq.exec = 4;
      assert(seq.randomize() with 
      {
        if(seq.mode)
          seq.cmd inside {[0:3],8};
        else
          seq.cmd inside {[0:5],12,13};

        if(count == 0)
        {
          if(valid_a)
            seq.inp_valid[1] == 1'b1;
          else if(valid_b)
            seq.inp_valid[0] == 1'b1;
        }
        else
          seq.inp_valid inside {[1:2]};

        foreach(previ[i]) 
          {seq.mode,seq.cmd} != previ[i];
      })
      else
        `uvm_fatal(get_name,"RANDOMIZATION FAILED")
      send_request(seq);
      `uvm_info(get_name,"SEQUENCE SENT",UVM_DEBUG)
      wait_for_item_done();
      valid_a = seq.inp_valid[0] ? 1'b1 : valid_a;
      valid_b = seq.inp_valid[1] ? 1'b1 : valid_b;
      /*if(count == 0)
        assert(std::randomize(count) with {count inside {[1:15]}}) else `uvm_fatal(get_name,"No Delay")
      */
      if(valid_a && valid_b)
        previ.push_back({seq.mode,seq.cmd});
      strt();
      sizing();
    end
  endtask

  task strt();
    if(valid_a && valid_b)
    begin
      `uvm_info(get_name,$sformatf("COUNT = %0d",count),UVM_DEBUG)
      seq.cmd.rand_mode(1);
      seq.mode.rand_mode(1);
      seq.inp_valid.rand_mode(1);
      `uvm_info(get_name,"RANDOMIZATION STARTED",UVM_DEBUG)
      count = 0;
      valid_a = 0;
      valid_b = 0;
      assert(std::randomize(count) with {count inside {[1:15]};}) `uvm_info(get_name,$sformatf("count = %0d",count),UVM_DEBUG) else `uvm_fatal(get_name,"No Delay")
    end
    else if(count > 1)
    begin
      `uvm_info(get_name,$sformatf("COUNT = %0d",count),UVM_DEBUG)
      `uvm_info(get_name,"RANDOMIZATION STOPPED",UVM_DEBUG)
      seq.cmd.rand_mode(0);
      seq.mode.rand_mode(0);
      seq.inp_valid.rand_mode(0);
      count--;
    end
    else
    begin
      seq.inp_valid.rand_mode(1);
      `uvm_info(get_name,"RANDOMIZATION STARTED BEFORE",UVM_DEBUG)
      count = 0;
      `uvm_info(get_name,$sformatf("COUNT = %0d",count),UVM_DEBUG)
    end
  endtask

  virtual function void sizing();
    if(previ.size >= 13) //give the size for each test
    begin
      while(previ.size > 0)
        void'(previ.pop_front);
    end
  endfunction 

endclass

//OUTSIDE 16 CLK CYCLE SEQUENCE 
class alu_w_time_sequence extends base_sequence;
  int count;
  bit valid_a,valid_b;
  `uvm_object_utils(alu_w_time_sequence)

  function new(string name = "w_time_seq");
    super.new(name);
    count = 16;
  endfunction

  virtual task body();
    while(previ.size > 0)
      void'(previ.pop_front());
    seq = alu_sequence_item::type_id::create("w_time_seq");
      $display("-------------------------------------------------------------WRONG TIME SEQUENCE STARTED-------------------------------------------------------------");
    repeat(34) begin
      seq.normal_cmd_mode.constraint_mode(0);
      seq.normal_inp_val.constraint_mode(0);
      wait_for_grant();
      seq.exec = 5;
      assert(seq.randomize() with 
      {
        if(seq.mode)
          seq.cmd inside {[0:3],[8:10]};
        else
          seq.cmd inside {[0:5],12,13};

        seq.inp_valid inside {[1:2]};

        foreach(previ[i]) 
          {seq.mode,seq.cmd} != previ[i];
      })
      else
        `uvm_fatal(get_name,"RANDOMIZATION FAILED")
      send_request(seq);
      `uvm_info(get_name,"SEQUENCE SENT",UVM_DEBUG)
      wait_for_item_done();
      valid_a = seq.inp_valid[0] ? 1'b1 : valid_a;
      valid_b = seq.inp_valid[1] ? 1'b1 : valid_b;
      if(count > 0)
      begin
        seq.cmd.rand_mode(0);
        seq.mode.rand_mode(0);
        seq.inp_valid.rand_mode(0);
        count--;
      end
      else if(count == 0)
      begin
        seq.cmd.rand_mode(1);
        seq.mode.rand_mode(1);
        seq.inp_valid.rand_mode(1);
        count = 16;
        previ.push_back({seq.mode,seq.cmd});
      end
      sizing();
    end
  endtask

  virtual function void sizing();
    if(previ.size >= 13) //give the size for each test
    begin
      while(previ.size > 0)
        void'(previ.pop_front);
    end
  endfunction
endclass

//FLAG BASED SEQUENCE 
class alu_flag_sequence extends base_sequence;
  int i; //just to go through all compares
  `uvm_object_utils(alu_flag_sequence)

  function new(string name = "flag_seq");
    super.new(name);
  endfunction

  virtual task body();
    while(previ.size > 0)
      void'(previ.pop_front());
    seq = alu_sequence_item::type_id::create("flag_seq_item");
      $display("-------------------------------------------------------------FLAG SEQUENCE STARTED-------------------------------------------------------------");
    repeat(30) begin
      wait_for_grant();
      seq.exec = 6;
      seq.normal_cmd_mode.constraint_mode(0);
      assert(seq.randomize() with 
      {

        solve seq.cmd before seq.opb;
        solve seq.opb before seq.opa;

        if(seq.mode)
        {
          seq.cmd inside {[0:3],8};
        }
        else
        {
          seq.cmd inside {12,13};
        }

        if(seq.mode)
        {
          if(seq.cmd == 0)
            int'(seq.opa) + int'(seq.opb) > 9'b011111111; 
          else if(seq.cmd == 2)
            int'(seq.opa) + int'(seq.opb) + seq.cin > 9'b011111111; 
          else if(seq.cmd == 1)
            seq.opa < seq.opb;
          else if(seq.cmd == 3)
            seq.opa < (seq.opb + seq.cin);
          else
          {
            if(i == 0)
              seq.opa > seq.opb;
            else if(i == 1)
              seq.opa < seq.opb;
            else
              seq.opa == seq.opb;
          }
        }
        else
          seq.opb > 4'b1111;

        foreach(previ[i]) 
          {seq.mode,seq.cmd} != previ[i];
      })
      else
        `uvm_fatal(get_name,"RANDOMIZATION FAILED")
      if((seq.mode && seq.cmd == 8) && i <= 2)
      begin
        i++;
        seq.mode.rand_mode(0);
        seq.cmd.rand_mode(0);
        seq.inp_valid.rand_mode(0);
        if(i > 2)
        begin
          i = 0;
          previ.push_back({seq.mode,seq.cmd});
          seq.mode.rand_mode(1);
          seq.cmd.rand_mode(1);
          seq.inp_valid.rand_mode(1);
        end
      end
      if(!(seq.mode && seq.cmd == 8))
        previ.push_back({seq.mode,seq.cmd});
      send_request(seq);
      wait_for_item_done();
      sizing();
      `uvm_info(get_name,"SEQUENCE SENT",UVM_DEBUG)
    end
  endtask

  virtual function void sizing();
    if(previ.size >= 7) //give the size for each test
    begin
      while(previ.size > 0)
        void'(previ.pop_front);
    end
  endfunction 

endclass

//NORMAL MULTIPLICATION SEQUENCE 
class alu_mult_sequence extends base_sequence;
  `uvm_object_utils(alu_mult_sequence)
  
  function new(string name = "mult_seq");
    super.new(name);
  endfunction

  virtual task body();
    while(previ.size > 0)
      void'(previ.pop_front());
      $display("-------------------------------------------------------------MULTIPLICATION SEQUENCE STARTED-------------------------------------------------------------");
    seq = alu_sequence_item::type_id::create("mult_seq");
    repeat(6) begin
      seq.normal_cmd_mode.constraint_mode(0);
      wait_for_grant();
      seq.exec = 7;
      assert(seq.randomize() with 
      {
        seq.mode == 1'b1;
        seq.cmd inside {9,10};

        foreach(previ[i]) 
          {seq.mode,seq.cmd} != previ[i];
      })
      else
        `uvm_fatal(get_name,"RANDOMIZATION FAILED")
      send_request(seq);
      `uvm_info(get_name,"SEQUENCE SENT",UVM_DEBUG)
      wait_for_item_done();
      previ.push_back({seq.mode,seq.cmd});
      sizing();
    end
  endtask

  virtual function void sizing();
    if(previ.size >= 2) //give the size for each test
    begin
      while(previ.size > 0)
        void'(previ.pop_front);
    end
  endfunction 

endclass

//MULT WITHIN 16 CLK CYCLE SEQUENCE 
class alu_mult_time_sequence extends base_sequence; //*
  int count;
  bit valid_a,valid_b;
  `uvm_object_utils(alu_mult_time_sequence)
  
  function new(string name = "mult_time_seq");
    super.new(name);
    assert(std::randomize(count) with {count inside {[1:14]};}) `uvm_info(get_name,$sformatf("count = %0d",count),UVM_DEBUG) else `uvm_fatal(get_name,"No Delay")
  endfunction

  virtual task body();
    while(previ.size > 0)
      void'(previ.pop_front());
    seq = alu_sequence_item::type_id::create("mult_time_seq");
      $display("-------------------------------------------------------------DELAY MULTIPLICATION SEQUENCE STARTED-------------------------------------------------------------");
    repeat(40) begin
      seq.normal_cmd_mode.constraint_mode(0);
      seq.normal_inp_val.constraint_mode(0);
      wait_for_grant();
      seq.exec = 7;
      assert(seq.randomize() with 
      {
        seq.mode == 1'b1;
        seq.cmd inside {9,10};

        if(count == 0)
        {
          if(valid_a)
            seq.inp_valid[1] == 1'b1;
          else if(valid_b)
            seq.inp_valid[0] == 1'b1;
        }
        else
          seq.inp_valid inside {[1:2]};

        foreach(previ[i]) 
          {seq.mode,seq.cmd} != previ[i];
      })
      else
        `uvm_fatal(get_name,"RANDOMIZATION FAILED")
      send_request(seq);
      `uvm_info(get_name,"SEQUENCE SENT",UVM_DEBUG)
      wait_for_item_done();
      valid_a = seq.inp_valid[0] ? 1'b1 : valid_a;
      valid_b = seq.inp_valid[1] ? 1'b1 : valid_b;

      if(valid_a && valid_b)
      begin
        valid_a = 0;
        valid_b = 0;
        seq.cmd.rand_mode(1);
        seq.mode.rand_mode(1);
        seq.inp_valid.rand_mode(1);
        previ.push_back({seq.mode,seq.cmd});
      end
      sizing();
      strt();
    end
  endtask

  task strt();
    if(count > 1)
    begin
      seq.cmd.rand_mode(0);
      seq.mode.rand_mode(0);
      seq.inp_valid.rand_mode(0);
      count--;
    end
    else if(valid_a && valid_b)
    begin
      count = 0;
      valid_a = 0;
      valid_b = 0;
      seq.cmd.rand_mode(1);
      seq.mode.rand_mode(1);
      seq.inp_valid.rand_mode(1);
      assert(std::randomize(count) with {count inside {[1:14]};}) `uvm_info(get_name,$sformatf("count = %0d",count),UVM_DEBUG) else `uvm_fatal(get_name,"No Delay")
    end
    else if(count <= 1)
    begin
      seq.inp_valid.rand_mode(1);
      count = 0;
    end
  endtask

  virtual function void sizing();
    if(previ.size >= 2) //give the size for each test
    begin
      while(previ.size > 0)
        void'(previ.pop_front);
    end
  endfunction 

endclass

//CORNER MULTIPLICATION SEQUENCE 
class alu_crn_mult_sequence extends base_sequence; //*
  int count3;
  `uvm_object_utils(alu_crn_mult_sequence) 
  
  function new(string name = "mult_crn_seq");
    super.new(name);
  endfunction

  virtual task body();
    while(previ.size > 0)
      void'(previ.pop_front());
      $display("-------------------------------------------------------------MULTIPLICATION CORNER SEQUENCE STARTED-------------------------------------------------------------");
    seq = alu_sequence_item::type_id::create("mult_seq");
    repeat(6) begin
      seq.normal_cmd_mode.constraint_mode(0);
      wait_for_grant();
      seq.exec = 9;
      assert(seq.randomize() with 
      {
        seq.mode == 1'b1;
        seq.cmd inside {9,10};

        if(seq.cmd == 9)
          seq.opa == 8'b11111111 || seq.opb == 8'b11111111;
        else
          seq.opa == 8'b10000000;

        foreach(previ[i]) 
          {seq.mode,seq.cmd} != previ[i];
      })
      else
        `uvm_fatal(get_name,"RANDOMIZATION FAILED")
      send_request(seq);
      `uvm_info(get_name,"SEQUENCE SENT",UVM_DEBUG)
      wait_for_item_done();
      if(count3 >= 3)
        previ.push_back({seq.mode,seq.cmd});
      sizing();
    end
  endtask

  virtual function void sizing();
    if(previ.size >= 2) //give the size for each test
    begin
      while(previ.size > 0)
        void'(previ.pop_front);
    end
  endfunction 

endclass

class regression_sequence extends base_sequence;
    alu_sequence seq1;
    alu_glo_sequence seq2;
    alu_err_sequence seq3;
    alu_corner_sequence seq4;
    alu_time_sequence seq5;
    alu_w_time_sequence seq6;
    alu_flag_sequence seq7;
    alu_mult_sequence seq8;
    alu_mult_time_sequence seq9;
    alu_crn_mult_sequence seq10;
  `uvm_object_utils(regression_sequence)

  function new(string name = "base_seq");
    super.new(name);
  endfunction

  virtual task body();
    seq = alu_sequence_item::type_id::create("seq_item");
    seq.exec = 10;
    $display("-------------------------------------------------------------REGRESSION SEQUENCE STARTED-------------------------------------------------------------");
    `uvm_do(seq1)
    `uvm_do(seq2)
    `uvm_do(seq3)
    `uvm_do(seq4)
    `uvm_do(seq5)
    `uvm_do(seq6)
    `uvm_do(seq7)
    `uvm_do(seq8)
    `uvm_do(seq9)
    `uvm_do(seq10)
  endtask

endclass
