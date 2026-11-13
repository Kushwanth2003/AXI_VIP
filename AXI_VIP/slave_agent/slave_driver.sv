class slave_driver extends uvm_driver#(master_xtn);

	`uvm_component_utils(slave_driver)

	virtual axi_if.SLV_DRV_MP vif;

	slave_config s_cfg;

	master_xtn xtn;
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

	function new(string name="slave_driver",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(slave_config)::get(this,"","slave_config",s_cfg))
		`uvm_fatal("SLAVE_DRIVER","cannot get the config ")
	endfunction

	function void connect_phase(uvm_phase phase);
		this.vif=s_cfg.vif;
	endfunction

	task run_phase(uvm_phase phase);
		forever
			begin
				//xtn=master_xtn::type_id::create("xtn");
			
				slave_drive();
			end
	endtask


	task slave_drive();
		
		fork
				
			//write address//
			begin
				sem_wac.get(1);
				drive_waddrc();
				sem_wdcd.put(1);
				sem_wac.put(1);
			end
	
			//write data//

			begin
				sem_wdcd.get(1);
				sem_wdc.get(1);
				drive_wdatac(q1.pop_front());
				sem_wrcd.put(1);
				sem_wdc.put(1);
			end
		
			//write response//

			begin
				sem_wrcd.get(1);
				sem_wrc.get(1);
				drive_wrespc(q2.pop_front());
				sem_wrc.put(1);
			end
		

			//read address//
			begin
				sem_rac.get(1);
				drive_raddrc();
				sem_rdcd.put(1);
				sem_rac.put(1);
			end
			

			//read data//


			begin
				sem_rdcd.get(1);
				sem_rdc.get(1);
				drive_rdatac(q3.pop_front());
				sem_rdc.put(1);
			end

	join_any
	//`uvm_info(get_type_name(),$sformatf("sampling data \n %s",xtn.sprint()),UVM_LOW)

endtask	

		
task drive_waddrc();
	//$display("start slave waddr");
	xtn=master_xtn::type_id::create("xtn");
	vif.slv_drv_cb.AWREADY<=1;


	@(vif.slv_drv_cb);
	wait(vif.slv_drv_cb.AWVALID)
		
		xtn.AWID = vif.slv_drv_cb.AWID;
		xtn.AWLEN = vif.slv_drv_cb.AWLEN;
		xtn.AWADDR = vif.slv_drv_cb.AWADDR;
		xtn.AWSIZE = vif.slv_drv_cb.AWSIZE;
		xtn.AWBURST = vif.slv_drv_cb.AWBURST;
		xtn.AWVALID = vif.slv_drv_cb.AWVALID;
		xtn.AWREADY = vif.slv_drv_cb.AWREADY;

	vif.slv_drv_cb.AWREADY<=1'b0;
//xtn.print();
		q1.push_back(xtn);

	repeat($urandom_range(1,5))
	@(vif.slv_drv_cb);

endtask



task drive_wdatac(master_xtn xtn);
//	$display("start of slave wdata");

	for(int i=0;i<xtn.AWLEN+1;i++)
		begin
		
	vif.slv_drv_cb.WREADY<=1;
		@(vif.slv_drv_cb);
		//	$display("333333333333333333333333333333");
	
			wait(vif.slv_drv_cb.WVALID)
	
	//	$display("slave drv wait for valid %0d",vif.slv_drv_cb.WVALID);
	//	xtn.print();
		xtn.WID = vif.slv_drv_cb.WID;
		xtn.WDATA[i] = vif.slv_drv_cb.WDATA;
		xtn.WSTRB[i]  = vif.slv_drv_cb.WSTRB;
		xtn.WLAST = vif.slv_drv_cb.WLAST;
		xtn.WVALID = vif.slv_drv_cb.WVALID;
		xtn.WREADY = vif.slv_drv_cb.WREADY;
		
		vif.slv_drv_cb.WREADY<=0;

		end
	
	//	xtn.print();


		repeat($urandom_range(1,5))
			@(vif.slv_drv_cb);
		q2.push_back(xtn);
	
endtask

		
task drive_wrespc(master_xtn xtn);

	vif.slv_drv_cb.BID <=xtn.WID;
	vif.slv_drv_cb.BRESP <=0;
	vif.slv_drv_cb.BVALID <= 1;
	
	@(vif.slv_drv_cb);
	wait(vif.slv_drv_cb.BREADY)
		
		xtn.BID = vif.slv_drv_cb.WID;
		xtn.BRESP = vif.slv_drv_cb.BRESP;
		xtn.BVALID = vif.slv_drv_cb.BVALID;
		xtn.BREADY = vif.slv_drv_cb.BREADY;

	vif.slv_drv_cb.BVALID <= 0;

	repeat($urandom_range(1,5))
		@(vif.slv_drv_cb);

endtask



task drive_raddrc();
	xtn=master_xtn::type_id::create("xtn");

	vif.slv_drv_cb.ARREADY <=1;
	
	@(vif.slv_drv_cb);
	wait(vif.slv_drv_cb.ARVALID);
	xtn.ARID = vif.slv_drv_cb.ARID;
	xtn.ARLEN = vif.slv_drv_cb.ARLEN;
	xtn.ARADDR = vif.slv_drv_cb.ARADDR;
	xtn.ARSIZE = vif.slv_drv_cb.ARSIZE;
	xtn.ARBURST = vif.slv_drv_cb.ARBURST;
	xtn.ARVALID = vif.slv_drv_cb.ARVALID;
	xtn.ARREADY = vif.slv_drv_cb.ARREADY;

	vif.slv_drv_cb.ARREADY <=0;	
	q3.push_back(xtn);

	repeat($urandom_range(1,5))
		@(vif.slv_drv_cb);
	
endtask




task drive_rdatac(master_xtn xtn);

	xtn.RDATA = new[xtn.ARLEN+1];//	$display(" lenth  %0d",xtn.ARLEN);
	foreach(xtn.RDATA[i])

//	for(int i=0;i<=(xtn.ARLEN+1);i++)
		begin
			vif.slv_drv_cb.RVALID <= 1;
			vif.slv_drv_cb.RRESP <=0;
			vif.slv_drv_cb.RID <=xtn.ARID;
			vif.slv_drv_cb.RDATA <=$urandom_range(1,5);

			if(i==(xtn.ARLEN))
				vif.slv_drv_cb.RLAST <= 1;
			else	
				vif.slv_drv_cb.RLAST <= 0;
				
			@(vif.slv_drv_cb);
			wait(vif.slv_drv_cb.RREADY)
			xtn.RVALID = vif.slv_drv_cb.RVALID;
			xtn.RREADY = vif.slv_drv_cb.RREADY;
			xtn.RDATA[i] = vif.slv_drv_cb.RDATA;
			
				vif.slv_drv_cb.RVALID <= 0;
				vif.slv_drv_cb.RLAST <= 0;
			
			repeat($urandom_range(1,5))
			@(vif.slv_drv_cb);
	
		end

endtask

endclass