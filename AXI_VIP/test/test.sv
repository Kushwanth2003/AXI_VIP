class test extends uvm_test;

	`uvm_component_utils(test)
	
	master_config m_cfg[];
	slave_config s_cfg[];

	env_config e_cfg;
	env envh;
	

	int master_no_of_agents=2;
	int slave_no_of_agents=2;


	function new(string name="test",uvm_component parent);
		super.new(name,parent);

	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		e_cfg=env_config::type_id::create("e_cfg");

		m_cfg=new[master_no_of_agents];
		s_cfg=new[slave_no_of_agents];
		
		e_cfg.m_cfg=new[master_no_of_agents];
		e_cfg.s_cfg=new[slave_no_of_agents];

		e_cfg.master_no_of_agents=master_no_of_agents;
		e_cfg.slave_no_of_agents=slave_no_of_agents;

		foreach(m_cfg[i])
			begin
				m_cfg[i]=master_config::type_id::create($sformatf("m_cfg[%0d]",i));
				m_cfg[i].is_active=UVM_ACTIVE;
				if(!uvm_config_db#(virtual axi_if)::get(this,"","axi_if",m_cfg[i].vif))
				`uvm_fatal("TEST","config not getting")
				e_cfg.m_cfg[i]=m_cfg[i];
			end

		foreach(s_cfg[i])
			begin
				s_cfg[i]=slave_config::type_id::create($sformatf("s_cfg[%0d]",i));
				s_cfg[i].is_active=UVM_ACTIVE;
				if(!uvm_config_db#(virtual axi_if)::get(this,"","axi_if",s_cfg[i].vif))
				`uvm_fatal("TEST","config not getting")
				e_cfg.s_cfg[i]=s_cfg[i];
			end

		uvm_config_db#(env_config)::set(this,"*","env_config",e_cfg);
		
		envh=env::type_id::create("envh",this);
	endfunction
	
	function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction

endclass


class fixed_trans extends test;

	`uvm_component_utils(fixed_trans)


	function new(string name="fixed_trans",uvm_component parent);
		super.new(name,parent);
	endfunction

	fixed f1;
	

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		f1=fixed::type_id::create("f1");
	endfunction



	task run_phase(uvm_phase phase);
		super.run_phase(phase);

		phase.raise_objection(this);
		f1.start(envh.m_top.m_agt[0].m_seqrh);
		#1000;
		phase.drop_objection(this);
	endtask
endclass



class increment_trans extends test;

	`uvm_component_utils(increment_trans)


	function new(string name="increment_trans",uvm_component parent);
		super.new(name,parent);
	endfunction

	increment inc1;
	

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		inc1=increment::type_id::create("inc1");
	endfunction



	task run_phase(uvm_phase phase);
		super.run_phase(phase);

		phase.raise_objection(this);
		inc1.start(envh.m_top.m_agt[0].m_seqrh);
		phase.drop_objection(this);
	endtask
endclass
