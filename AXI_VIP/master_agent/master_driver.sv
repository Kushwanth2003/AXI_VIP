class master_driver extends uvm_driver#(master_xtn);

	`uvm_component_utils(master_driver)

	virtual axi_if.MSTR_DRV_MP vif;

	master_config m_cfg;

	//master_xtn xtn;

	master_xtn q1[$],q2[$],q3[$],q4[$],q5[$];

	//for particular master to be worked at a time
	semaphore sem_wdcd = new();//write data channel dependency
	semaphore sem_wrcd = new();//write reponse channel dependency
	semaphore sem_wdc = new(1);//write channel
	semaphore sem_wac = new(1);//write address channel
	semaphore sem_wrc =new(1);//write respose

	semaphore sem_rdcd = new();//read data channel dependency
	semaphore sem_rac = new(1);//read address
	semaphore sem_rdc = new(1);//read data channel

	
	function new(string name="master_driver",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(master_config)::get(this,"","master_config",m_cfg))
		`uvm_fatal("MASTER_DRIVER","cannot get the config ")
	endfunction

	function void connect_phase(uvm_phase phase);
		this.vif=m_cfg.vif;
	endfunction

	task run_phase(uvm_phase phase);
		forever
			begin	
				//req=master_xtn::type_id::create("req");
				seq_item_port.get_next_item(req);
				drive(req);
				seq_item_port.item_done();
			//	`uvm_info(get_type_name(),$sformatf("driving data \n %s",req.sprint()),UVM_LOW)
			end
	endtask


	task drive(master_xtn xtn);

		q1.push_back(xtn);
		q2.push_back(xtn);
		q3.push_back(xtn);
		q4.push_back(xtn);
		q5.push_back(xtn);
		
		fork
			begin
				//write address channel
				sem_wac.get(1);
				drive_waddrc(q1.pop_front());
				sem_wdcd.put(1);
				sem_wac.put(1);
			end
			
			begin
				//write data chaannel
				sem_wdcd.get(1);
				sem_wdc.get(1);
				drive_wdatac(q2.pop_front());
				sem_wrcd.put(1);
				sem_wdc.put(1);
			end
		
			begin
				//write reponse channel
				sem_wrcd.get(1);
				sem_wrc.get(1);
				drive_wrspc(q3.pop_front());
				sem_wrc.put(1);
			end
	
			begin
				//read address channel
				sem_rac.get(1);
				drive_raddrc(q4.pop_front());
				sem_rdcd.put(1);
				sem_rac.put(1);
			end
				
			begin	
				//read data channel
				sem_rdcd.get(1);
				sem_rdc.get(1);
				drive_rdatac(q5.pop_front());
				sem_rdc.put(1);
			end
		`uvm_info(get_type_name(),$sformatf("driving data \n %s",xtn.sprint()),UVM_LOW)

		join_any
	endtask


	task drive_waddrc(master_xtn xtn);
		
	//	$display("starting of drive waddrc");

		vif.mst_drv_cb.AWVALID<=1;
		vif.mst_drv_cb.AWADDR<=xtn.AWADDR;
		vif.mst_drv_cb.AWSIZE<=xtn.AWSIZE;
		vif.mst_drv_cb.AWLEN<=xtn.AWLEN;
		vif.mst_drv_cb.AWID<=xtn.AWID;
		vif.mst_drv_cb.AWBURST<=xtn.AWBURST;

		@(vif.mst_drv_cb);
	//	wait(vif.mst_drv_cb.AWREADY)	
		vif.mst_drv_cb.AWVALID<=0;

		repeat($urandom_range(1,5))
			@(vif.mst_drv_cb);
	
	//	$display("end of driver waddrc");
	endtask

	
	task drive_wdatac(master_xtn xtn);
		
	//	$display("start of master driver wdatac ");	
	
		for(int i=0;i<xtn.WDATA.size();i++)
	
	//	foreach(xtn.WDATA[i])
		begin
	//@(vif.mst_drv_cb);
			vif.mst_drv_cb.WVALID<=1'b1;
		//	$display("99999999999999999999999999");
		//	xtn.print();

			vif.mst_drv_cb.WDATA<=xtn.WDATA[i];
			vif.mst_drv_cb.WSTRB<=xtn.WSTRB[i];
			vif.mst_drv_cb.WID<=xtn.WID;
			if(i==(xtn.AWLEN))
				vif.mst_drv_cb.WLAST<=1'b1;
			else
				vif.mst_drv_cb.WLAST<=1'b0;
		
			@(vif.mst_drv_cb);
			//	wait(vif.mst_drv_cb.WREADY)	



				vif.mst_drv_cb.WVALID<=1'b0;

				vif.mst_drv_cb.WLAST<=1'b0;
				
				repeat($urandom_range(1,5))
					@(vif.mst_drv_cb);
		end
		//	$display("end of master driver wdatac ");
	endtask

	task drive_wrspc(master_xtn xtn);

	//	$display("start of master driver wresponse ");
		vif.mst_drv_cb.BREADY<=1;
		@(vif.mst_drv_cb);

	//	wait(vif.mst_drv_cb.BVALID)
			vif.mst_drv_cb.BREADY<=0;

		repeat($urandom_range(1,5))
		@(vif.mst_drv_cb);

	//	$display("end of master driver wresponse ");
	endtask


	task drive_raddrc(master_xtn xtn);
	
	//	$display("start of master driver raddrc ");

		vif.mst_drv_cb.ARID<=xtn.ARID;
		vif.mst_drv_cb.ARADDR<=xtn.ARADDR;
		vif.mst_drv_cb.ARLEN<=xtn.ARLEN;
		vif.mst_drv_cb.ARSIZE<=xtn.ARSIZE;
		vif.mst_drv_cb.ARBURST<=xtn.ARBURST;
		vif.mst_drv_cb.ARVALID<=1;
		
		//@(vif.mst_drv_cb);

	//	wait(vif.mst_drv_cb.ARREADY)
			vif.mst_drv_cb.ARVALID<=0;

		repeat($urandom_range(1,5))
			@(vif.mst_drv_cb);

		//	$display("end of master driver raddrc ");
	endtask


	task drive_rdatac(master_xtn xtn);
	
	//	$display("start of master driver rdatac ");

		for(int i=0;i<=(xtn.ARLEN+1);i++)
			begin
				vif.mst_drv_cb.RREADY<=1;
				@(vif.mst_drv_cb);
			//	wait(vif.mst_drv_cb.RVALID)
					vif.mst_drv_cb.RREADY<=0;

				repeat($urandom_range(1,5))
					@(vif.mst_drv_cb);
			end
		//	$display("end of master driver rdatac ");

	endtask
				
		
endclass