class slave_monitor extends uvm_monitor;

	`uvm_component_utils(slave_monitor)

	virtual axi_if.SLV_MON_MP vif;

	slave_config s_cfg;
	
	uvm_analysis_port#(master_xtn) slv_aport;

	master_xtn xtn,xtn1;
	master_xtn q1[$],q2[$],q3[$],q4[$],q5[$];

	//for particular master to be worked at a time//
	semaphore sem_wdcd = new();//write data channel dependency//
	semaphore sem_wrcd = new();//write reponse channel dependency//
	semaphore sem_wdc  = new(1);//WRITE data channnel
	semaphore sem_wac  = new(1);//write address channel
	semaphore sem_wrc  = new(1);//write respose


	semaphore sem_rdcd = new();//read data channel dependency
	semaphore sem_rac  = new(1);//read address
	semaphore sem_rdc  = new(1);//read data channel
		
	function new(string name="slave_monitor",uvm_component parent);
		super.new(name,parent);
		slv_aport=new("slv_aport",this);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(slave_config)::get(this,"","slave_config",s_cfg))
		`uvm_fatal("SLAVE_MONITOR","cannot get the config")
	endfunction

	function void connect_phase(uvm_phase phase);
		this.vif=s_cfg.vif;
	endfunction

	task run_phase(uvm_phase phase);
		forever
			collect_data();
		endtask



	task collect_data();
	//	q1.push_back(xtn);
	//	q2.push_back(xtn);
	//	q3.push_back(xtn);
		//q4.push_back(xtn);
		//q5.push_back(xtn);

			fork
				//write address//
				begin
					sem_wac.get(1);
					collect_waddrc();
					sem_wdcd.put(1);
					sem_wac.put(1);
				end


				//write data//
				begin
					sem_wdcd.get(1);
					sem_wdc.get(1);
					collect_wdatac(q1.pop_front());
					sem_wrcd.put(1);
					sem_wdc.put(1);
				end



				//write response//
				begin
					sem_wrcd.get(1);
					sem_wrc.get(1);
					collect_wrspc(q2.pop_front());
					sem_wrc.put(1);
				end



				//read address//
				begin
					sem_rac.get(1);
					collect_raddrc();
					sem_rdcd.put(1);
					sem_rac.put(1);
				end


				//read data//
				begin
					sem_rdcd.get(1);
					sem_rdc.get(1);
					collect_rdatac(q3.pop_front());
					sem_rdc.put(1);
				end
		//		`uvm_info(get_type_name(),$sformatf("sampling data \n %s",xtn.sprint()),UVM_LOW)

			join_any

	endtask


	task collect_waddrc();
		xtn=master_xtn::type_id::create("xtn");
		
		@(vif.slv_mon_cb);

		wait((vif.slv_mon_cb.AWVALID) && (vif.slv_mon_cb.AWREADY))
		xtn.AWID=vif.slv_mon_cb.AWID;
		xtn.AWADDR=vif.slv_mon_cb.AWADDR;
		xtn.AWLEN=vif.slv_mon_cb.AWLEN;
		xtn.AWSIZE=vif.slv_mon_cb.AWSIZE;
		xtn.AWBURST=vif.slv_mon_cb.AWBURST;
		xtn.AWVALID=vif.slv_mon_cb.AWVALID;
		xtn.AWREADY=vif.slv_mon_cb.AWREADY;
		q1.push_back(xtn);

	endtask


	
	task collect_wdatac(master_xtn xtn);
	
		xtn.WDATA = new[xtn.AWLEN+1];
		xtn.WSTRB = new[xtn.AWLEN+1];
			foreach(xtn.WDATA[i])
				begin
					wait(vif.slv_mon_cb.WVALID && vif.slv_mon_cb.WREADY)
						xtn.WSTRB[i] = vif.slv_mon_cb.WSTRB;
							if(vif.slv_mon_cb.WSTRB == 15)
								xtn.WDATA[i] = vif.slv_mon_cb.WDATA;

							if(vif.slv_mon_cb.WSTRB == 8)
								xtn.WDATA[i] = vif.slv_mon_cb.WDATA[31:24];

							if(vif.slv_mon_cb.WSTRB == 4)
								xtn.WDATA[i] = vif.slv_mon_cb.WDATA[23:16];

							if(vif.slv_mon_cb.WSTRB == 2)
								xtn.WDATA[i] = vif.slv_mon_cb.WDATA[15:8];

							if(vif.slv_mon_cb.WSTRB == 1)
								xtn.WDATA[i] = vif.slv_mon_cb.WDATA[7:0];

							if(vif.slv_mon_cb.WSTRB == 14)//unaligned strb 4 bytes 1110//
								xtn.WDATA[i] = vif.slv_mon_cb.WDATA[31:8];

							if(vif.slv_mon_cb.WSTRB == 12)
								xtn.WDATA[i] = vif.slv_mon_cb.WDATA[31:16];

							if(vif.slv_mon_cb.WSTRB == 3)
								xtn.WDATA[i] = vif.slv_mon_cb.WDATA[15:0];

							xtn.WID = vif.slv_mon_cb.WID;	
							xtn.WLAST = vif.slv_mon_cb.WLAST;
							xtn.WVALID = vif.slv_mon_cb.WVALID;
							@(vif.slv_mon_cb);
	
				end

	/*	@(vif.slv_mon_cb);	
		wait(vif.slv_mon_cb.WVALID && vif.slv_mon_cb.WREADY)

	for(int i=0;i<=(xtn.AWLEN+1);i++)
		begin
			xtn.WID=vif.slv_mon_cb.WID;
			xtn.WDATA[i]=vif.slv_mon_cb.WDATA;
			xtn.WSTRB[i]=vif.slv_mon_cb.WSTRB;
			xtn.WLAST=vif.slv_mon_cb.WLAST;
			xtn.WVALID=vif.slv_mon_cb.WVALID;
			xtn.WREADY=vif.slv_mon_cb.WREADY;
		end
	*/
		q2.push_back(xtn);
			
	endtask



		
	task collect_wrspc(master_xtn xtn);

		@(vif.slv_mon_cb);	
		wait(vif.slv_mon_cb.BREADY && vif.slv_mon_cb.BVALID)

			xtn.BREADY=vif.slv_mon_cb.BREADY;
			xtn.BID=vif.slv_mon_cb.BID;
			xtn.BRESP=vif.slv_mon_cb.BRESP;
			xtn.BVALID=vif.slv_mon_cb.BVALID;
	
		//mstr_monport.write(xtn);
		@(vif.slv_mon_cb);
		slv_aport.write(xtn);
		
	endtask

	
			
	task collect_raddrc();
		xtn1=master_xtn::type_id::create("xtn1");
		@(vif.slv_mon_cb);	
		wait(vif.slv_mon_cb.ARVALID && vif.slv_mon_cb.ARREADY)
	
			xtn1.ARID=vif.slv_mon_cb.ARID;
			xtn1.ARADDR=vif.slv_mon_cb.ARADDR;
			xtn1.ARLEN=vif.slv_mon_cb.ARLEN;
			xtn1.ARSIZE=vif.slv_mon_cb.ARSIZE;
			xtn1.ARBURST=vif.slv_mon_cb.ARBURST;
			xtn1.ARVALID=vif.slv_mon_cb.ARVALID;
			xtn1.ARREADY=vif.slv_mon_cb.ARREADY;
		q3.push_back(xtn);

	endtask


	task collect_rdatac(master_xtn xtn1);

		xtn1=master_xtn::type_id::create("xtn1");
		xtn1.RDATA=new[xtn1.ARLEN+1];
		xtn1.RRESP = new[xtn1.ARLEN+1];
		foreach(xtn1.RDATA[i])
			begin
		
		@(vif.slv_mon_cb);
		wait(vif.slv_mon_cb.RVALID && vif.slv_mon_cb.RREADY);

			xtn1.RID=vif.slv_mon_cb.RID;
			xtn1.RVALID=vif.slv_mon_cb.RVALID;
			xtn1.RREADY=vif.slv_mon_cb.RREADY;
			xtn1.RDATA[i]=vif.slv_mon_cb.RDATA;
			xtn1.RRESP[i]=vif.slv_mon_cb.RRESP;

		if(i==xtn1.ARLEN)
			xtn1.RLAST=vif.slv_mon_cb.RLAST;
			end
		slv_aport.write(xtn1);
	endtask
endclass