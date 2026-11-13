class scoreboard extends uvm_scoreboard;

	`uvm_component_utils(scoreboard)

	uvm_tlm_analysis_fifo#(master_xtn) fifo_mstr[];
	
	uvm_tlm_analysis_fifo#(master_xtn) fifo_slv[];

	env_config e_cfg;
	
	master_xtn m_xtn,s_xtn;

	master_xtn m_cov_data,s_cov_data;


	covergroup write_cg;
	
		option.per_instance=1;
		
		w_addr : coverpoint m_cov_data.AWADDR { bins addr = {[0:'hffff_ffff]};}
		 
		w_len  : coverpoint m_cov_data.AWLEN  { bins len = {[0:15]};}
		
		w_size : coverpoint m_cov_data.AWSIZE { bins wsize = {0,1,2};}

		w_burst : coverpoint m_cov_data.AWBURST { bins wburst = {0,1,2};}

		b_resp : coverpoint m_cov_data.BRESP  { bins bresp = {0};}

	endgroup

	
	covergroup write_cg1 with function sample(int i);
	
		option.per_instance=1;
	
		w_data : coverpoint m_cov_data.WDATA[i] { bins data = {[0:'hffff_ffff]};}
	
		w_strb : coverpoint m_cov_data.WSTRB[i] { bins strb={0};
							  bins strb1={1};
							  bins strb2={2};
							  bins strb3={4};
							  bins strb4={8};
							  bins strb5={12};
						 	  bins strb6={15};}
	endgroup

	
	covergroup read_cg;

		option.per_instance=1;
	
		a_addr : coverpoint s_cov_data.ARADDR { bins raddr = {[0:'hffff_ffff]};}

		r_len  : coverpoint s_cov_data.ARLEN  {bins rlen = {[0:15]};}
	
		r_size : coverpoint s_cov_data.ARSIZE {bins rsize = {0,1,2};}
	
		r_burst : coverpoint s_cov_data.ARBURST {bins rburst = {0,1,2};}
	

	endgroup


		
		

	covergroup read_cg1 with function sample(int i);
		
		option.per_instance=1;
		
		 
       		 r_data : coverpoint s_cov_data.RDATA[i] {bins radata = {[0:'hffff_ffff]};}

       		 r_resp : coverpoint s_cov_data.RRESP[i] {bins rresp = {0};}
	
	endgroup


 
	function new(string name="scoreboard",uvm_component parent);
		super.new(name,parent);

		write_cg=new();
		write_cg1=new();

		read_cg=new();
		read_cg1=new();

	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	if(!uvm_config_db#(env_config)::get(this,"","env_config",e_cfg))
		`uvm_fatal("ENV","is not getting")

		
		fifo_mstr = new[e_cfg.master_no_of_agents];
		foreach(fifo_mstr[i])
			fifo_mstr[i] = new($sformatf("fifo_mstr[%0d]",i),this);

		fifo_slv = new[e_cfg.slave_no_of_agents];
		foreach(fifo_slv[i])
			fifo_slv[i] = new($sformatf("fifo_slv[%0d]",i),this);

	endfunction

/*
	task run_phase(uvm_phase phase);
		forever
			begin
//	$display("==========scoreboard=================");

			
				fifo_mstr[0].get(m_xtn);
		//$display("==========scoreboard12345678=================");

				//`uvm_info(get_type_name(),$sformatf("PRINTING FROM MSTSR %s",m_xtn.sprint()),UVM_LOW)

				fifo_mstr[0].get(s_xtn);


				if(m_xtn.compare(s_xtn))
					$display("===========SCOREBOARD COMPARISION SUCCESS ==============");
					
				`uvm_info(get_type_name(),$sformatf("PRINTING FROM MSTSR %s",m_xtn.sprint()),UVM_LOW)
		`uvm_info(get_type_name(),$sformatf("PRINTING FROM MSTSR %s",m_xtn.sprint()),UVM_LOW)

		m_cov_data = m_xtn;
		s_cov_data = s_xtn;
		
		if(m_xtn.WVALID)
			begin		
				foreach(m_xtn.WDATA[i])
					begin
						write_cg1.sample(i);
					end
			end
		if(s_xtn.RVALID)
			begin		
				foreach(s_xtn.RDATA[i])
					begin
						read_cg1.sample(i);
					end
			end

		else 
			begin
				$display("==========scoreboard failed=================");
					
				`uvm_info(get_type_name(),$sformatf("PRINTING FROM MSTSR %s",m_xtn.sprint()),UVM_LOW)
		`uvm_info(get_type_name(),$sformatf("PRINTING FROM MSTSR %s",m_xtn.sprint()),UVM_LOW)
			end
		end
	endtask*/
endclass