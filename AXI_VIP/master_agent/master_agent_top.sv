
class master_agent_top extends uvm_env;

	`uvm_component_utils(master_agent_top)

	env_config e_cfg;

	master_agent m_agt[];


	function new(string name="master_agent_top",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	
		if(!uvm_config_db#(env_config)::get(this,"","env_config",e_cfg))
		`uvm_fatal("MASTER_AGENT_TOP","cannot get the config ")
		
		m_agt=new[e_cfg.master_no_of_agents];
		foreach(m_agt[i])
			begin
				m_agt[i]=master_agent::type_id::create($sformatf("m_agt[%0d]",i),this);
				uvm_config_db#(master_config)::set(this,$sformatf("m_agt[%0d]*",i),"master_config",e_cfg.m_cfg[i]);
			end

	endfunction

endclass


				
