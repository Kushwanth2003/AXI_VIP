
class slave_agent_top extends uvm_env;

	`uvm_component_utils(slave_agent_top)

	env_config e_cfg;

	slave_agent s_agt[];


	function new(string name="slave_agent_top",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	
		if(!uvm_config_db#(env_config)::get(this,"","env_config",e_cfg))
		`uvm_fatal("MASTER_AGENT_TOP","cannot get the config ")
		
		s_agt=new[e_cfg.slave_no_of_agents];
		foreach(s_agt[i])
			begin
				s_agt[i]=slave_agent::type_id::create($sformatf("s_agt[%0d]",i),this);
				uvm_config_db#(slave_config)::set(this,$sformatf("s_agt[%0d]*",i),"slave_config",e_cfg.s_cfg[i]);
			end

	endfunction

endclass


				
