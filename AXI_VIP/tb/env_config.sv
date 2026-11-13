class env_config extends uvm_object;

	`uvm_object_utils(env_config)

	master_config m_cfg[];
	slave_config s_cfg[];
	virtual axi_if vif;

	bit has_master_agt=1;
	bit has_slave_agt=1;
	bit has_scoreboard=1;

	int master_no_of_agents;
	int slave_no_of_agents;

	function new(string name="env_config");
		super.new(name);
	endfunction

endclass


	