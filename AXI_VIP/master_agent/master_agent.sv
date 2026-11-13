
class master_agent extends uvm_agent;

	`uvm_component_utils(master_agent)

	master_driver m_drvh;
	master_monitor m_monh;
	master_sequencer m_seqrh;

	master_config m_cfg;

	function new(string name="master_agent",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(!uvm_config_db#(master_config)::get(this,"","master_config",m_cfg))
		`uvm_fatal("MASTER_AGENT","cannot get the config ")

		m_monh=master_monitor::type_id::create("m_monh",this);
		if(m_cfg.is_active==UVM_ACTIVE)
			begin
				m_seqrh=master_sequencer::type_id::create("m_seqrh",this);
				m_drvh=master_driver::type_id::create("m_drvh",this);
			end

	endfunction

	function void connect_phase(uvm_phase phase);
		m_drvh.seq_item_port.connect(m_seqrh.seq_item_export);
	endfunction

endclass


