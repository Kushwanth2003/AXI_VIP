
class env extends uvm_env;

	`uvm_component_utils(env)

	master_agent_top m_top;
	slave_agent_top s_top;
	scoreboard sb;
	
	env_config e_cfg;

	function new(string name="env",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(env_config)::get(this,"","env_config",e_cfg))
		`uvm_fatal("ENV","cannot get the config")
		
		if(e_cfg.has_master_agt)
			begin
				m_top=master_agent_top::type_id::create("m_top",this);
			end
		if(e_cfg.has_slave_agt)
			begin
				s_top=slave_agent_top::type_id::create("s_top",this);
			end
		if(e_cfg.has_scoreboard)
			begin
				sb=scoreboard::type_id::create("sb",this);
			end

	endfunction

	function void connect_phase(uvm_phase phase);
		m_top.m_agt[0].m_monh.mstr_aport.connect(sb.fifo_mstr[0].analysis_export);
		s_top.s_agt[0].s_monh.slv_aport.connect(sb.fifo_slv[0].analysis_export);
	endfunction

endclass


