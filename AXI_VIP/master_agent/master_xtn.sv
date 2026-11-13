class master_xtn extends uvm_sequence_item;

	`uvm_object_utils(master_xtn)


	bit ARESETn;



//declare write address channel signals


	rand bit [3:0]  AWID;
	rand bit [31:0] AWADDR;
	rand bit [3:0]  AWLEN;
	rand bit [2:0]  AWSIZE;
	rand bit [1:0]  AWBURST;
	bit AWVALID;
	bit AWREADY;


//declare write data signls


	rand bit [3:0]  WID;
	rand bit [31:0] WDATA[];
	bit      [3:0]  WSTRB[];
	bit WLAST;
	bit WVALID;         
	bit WREADY;	


//declare write response signals

	rand bit [3:0] BID;
	bit 	 [1:0] BRESP;
	bit 	BVALID;
	bit 	BREADY;
	

//declaration read address signlas

	rand bit [3:0] ARID;
	rand bit [31:0] ARADDR;
	rand bit [3:0] ARLEN;
	rand bit [2:0] ARSIZE;
	rand bit [1:0] ARBURST;
	bit ARREADY;
	bit ARVALID;



//decalare read data signlas


	rand bit [3:0] RID;
	rand bit [31:0] RDATA[];
	rand bit [1:0] RRESP[];
	bit RLAST;
	bit RREADY;
	bit RVALID;





///calculation part//

	bit [31:0] waddr[];
	int no_wbytes;
	int aligned_waddr;
	int start_waddr;


	bit [31:0] raddr[];
	int no_rbytes;
	int aligned_raddr;
	int start_raddr;




//CONSTRAINTS//




/////////////////////////// CONSTRAINS FOR WRITE //////////////////////////


constraint write_id {AWID==WID;AWID==BID;}//write addr id = wdata and wresponse//
constraint awb {AWBURST dist {0:=10,1:=10,2:=10};}//burst 0 means fixed,inc,wrap for write//

constraint adwr {AWSIZE dist {0:=10,1:=10,2:=10};}//size 2^0=1,2^1=2//

constraint wrap_len1 {if(AWBURST == 2'b10) (AWLEN+1) inside {2,4,8,16};}
constraint wrap_len2 {if(ARBURST == 2'b10) (AWLEN+1) inside {2,4,8,16};}


constraint wlen {AWLEN inside {[0:15]};}


constraint wr_align1{((AWBURST ==2'b10 || AWBURST ==2'b00) && AWSIZE ==1) ->  AWADDR%2 ==0;}	//Allignment for wrap and fixed//
constraint wr_align2{((AWBURST ==2'b10 || AWBURST ==2'b00) && AWSIZE ==1) ->  AWADDR%4 ==0;}	//Allignment for wrap and fixed//

constraint wdata {WDATA.size() ==(AWLEN+1);}
//  constraint wstrobe {WSTRB.size() == (AWLEN+1) ;}
/////////////////////////// CONSTRAINS FOR READ //////////////////////////

constraint read_id {ARID==RID;}
constraint rlen {ARLEN inside {[0:15]};}
constraint rdata {RDATA.size() ==(ARLEN+1);}
constraint arb {ARBURST dist {0:=10,1:=10,2:=10};}//read//
constraint adrs {ARSIZE dist {0:=10,1:=10,2:=10};}

constraint rd_align1{((ARBURST ==2'b10 || ARBURST ==2'b00) && ARSIZE ==1) ->  ARADDR%2 ==0;}	//Allignment for wrap and fixed//
constraint rd_align2{((ARBURST ==2'b10 || ARBURST ==2'b00) && ARSIZE ==1) ->  ARADDR%2 ==0;}	//Allignment for wrap and fixed//


constraint max_wboun {(2**AWSIZE)*(AWLEN+1) < 4096;}
constraint max_rboun {(2**ARSIZE)*(AWLEN+1) < 4096;}




	
	function new(string name="master_xtn");
		super.new(name);
	endfunction

	function void post_randomize();
		
		//write//

		no_wbytes = 2**AWSIZE;
		aligned_waddr = (int'(AWADDR/no_wbytes))*no_wbytes;
		start_waddr = AWADDR;
		WSTRB = new[AWLEN+1];

	//	$display("w addr %p",waddr);
	//	$display("aligned_waddr %d",aligned_waddr);


		//read//
		no_rbytes = 2**ARSIZE;
		aligned_raddr = (int'(ARADDR/no_rbytes))*no_rbytes;
		start_raddr = ARADDR;


		 cal_waddr();

		 strb_cal();

		 cal_raddr();

		

	endfunction	
	


	function void cal_waddr();
		bit wb;  //whether wrap is happend or not//
		int burst_len =AWLEN+1;//how many tranfers it going to happen//
		int N=burst_len;
		int wrap_boundary = (int'(start_waddr/(no_wbytes*burst_len)))*(no_wbytes*burst_len);
		int addr_n = wrap_boundary + (no_wbytes*burst_len);
		waddr = new[AWLEN+1];

		waddr[0] =AWADDR;             
		no_wbytes = 2**AWSIZE;
		aligned_waddr = (int'(AWADDR/no_wbytes))*no_wbytes;


		for(int i=2;i<(burst_len+1);i++) 
			begin
				if(AWBURST==2'b00)
				waddr[i-1]=AWADDR; //fixed 

				if(AWBURST==2'b01)
				waddr[i-1]=aligned_waddr+(i-1)*no_wbytes;  //increment

				if(AWBURST==2'b10)
				begin
					if(wb==0)//wrap
					begin
						waddr[i-1]=aligned_waddr+(i-1)*no_wbytes;
						if(waddr[i-1]==(wrap_boundary+(no_wbytes*burst_len)))
							begin
								waddr[i-1]=wrap_boundary;
								wb++;
							end
					end
				
					else
					waddr[i-1]=start_waddr+((i-1)*no_wbytes)-(no_wbytes*burst_len);
				end
			end
			
	endfunction



	function void cal_raddr();
		bit wb;
		int burst_len = ARLEN+1;
		int N = burst_len;
		int wrap_boundary = (int'(ARADDR/(no_rbytes*burst_len)))*(no_rbytes*burst_len);
		int addr_n = wrap_boundary+(no_rbytes*burst_len);
	
		raddr = new[ARLEN+1];

		raddr[0] = ARADDR;
		no_rbytes = 2**ARSIZE;
		aligned_raddr = (int'(ARADDR/no_rbytes))*no_rbytes;
		start_raddr = ARADDR;

		for(int i = 2; i<(burst_len+1);i++) 
		begin
			if(ARBURST == 0) 
				raddr[i-1]=ARADDR;

			if(ARBURST == 1) 
				raddr[i-1] = aligned_raddr+(i-1)*no_rbytes;
	
			if(ARBURST == 2) 
			begin
				if(wb==0)
				begin
					raddr[i-1] = aligned_raddr + (i-1)*no_rbytes;
					if(raddr[i-1] == (wrap_boundary + (no_rbytes*burst_len)))
					begin
						raddr[i-1] = wrap_boundary;
						wb++;
					end
				end
			end
			else 
				raddr[i-1] = start_raddr + ((i-1)*no_rbytes)-(no_rbytes*burst_len);
		end

	endfunction


	//strobe calculation///
	
	function void strb_cal();
		int data_bus_bytes=4;
		int lower_byte_lane,upper_byte_lane;


		int lower_byte_lane_0 = start_waddr - ((int'(start_waddr/data_bus_bytes))*data_bus_bytes);
		int upper_byte_lane_0 = (aligned_waddr + (no_wbytes-1)) - ((int'(start_waddr/data_bus_bytes))*data_bus_bytes);
	

		for(int j=lower_byte_lane_0;j<=upper_byte_lane_0;j++)
			begin
				WSTRB[0][j]=1;
			end
	
		for(int i=1;i<(AWLEN+1);i++)
			begin
				lower_byte_lane = waddr[i] - (int'(waddr[i]/data_bus_bytes))*data_bus_bytes;
				upper_byte_lane = lower_byte_lane + no_wbytes;
				for(int j=lower_byte_lane;j<=upper_byte_lane;j++)
				begin
					WSTRB[i][j]=1;
				end
			end
	endfunction




	function void do_print(uvm_printer printer);
		super.do_print(printer);

printer.print_field("####################### WRITE ADDRESS SIGNLS#######################",null,0,UVM_DEC);
	printer.print_field("AWID",this.AWID,8,UVM_DEC);
	printer.print_field("AWADDR",this.AWADDR,32,UVM_DEC);
	printer.print_field("AWLEN",this.AWLEN,8,UVM_DEC);
	printer.print_field("AWSIZE",this.AWSIZE,3,UVM_DEC);
	printer.print_field("AWBURST",this.AWBURST,2,UVM_DEC);
	printer.print_field("AWVALID",this.AWVALID,1,UVM_DEC);
	printer.print_field("AWREADY",this.AWREADY,1,UVM_DEC);

printer.print_field("####################### WRITE DATA SIGNLS#######################",null,0,UVM_DEC);



	printer.print_field("WID",this.WID,8,UVM_DEC);
	foreach(WDATA[i])
	printer.print_field($sformatf("WDATA[%0d]",i),this.WDATA[i],32,UVM_DEC);
	foreach(WSTRB[i])
	printer.print_field($sformatf("WSTRB[%0d]",i),this.WSTRB[i],4,UVM_DEC);
	printer.print_field("WLAST",this.WLAST,1,UVM_DEC);
	printer.print_field("WVALID",this.WVALID,1,UVM_DEC);
	printer.print_field("WREADY",this.WREADY,8,UVM_DEC);



printer.print_field("####################### WRITE RESPONSE  SIGNLS#######################",null,0,UVM_DEC);

	printer.print_field("BID",BID,8,UVM_DEC);
	printer.print_field("BRESP",BRESP,2,UVM_DEC);
	printer.print_field("BVALID",BVALID,1,UVM_DEC);	
	printer.print_field("BREADY",BREADY,1,UVM_DEC);


printer.print_field("####################### READ ADDRESS  SIGNLS#######################",null,0,UVM_DEC);

	printer.print_field("ARID",this.ARID,8,UVM_DEC);
	printer.print_field("ARADDR",this.ARADDR,32,UVM_DEC);
	printer.print_field("ARLEN",this.ARLEN,8,UVM_DEC);
	printer.print_field("ARBURST",this.ARBURST,2,UVM_DEC);	
	printer.print_field("ARSIZE",this.ARSIZE,3,UVM_DEC);
	printer.print_field("ARVALID",this.ARVALID,1,UVM_DEC);
	printer.print_field("ARREADY",this.ARREADY,1,UVM_DEC);


printer.print_field("####################### READ DATA SIGNALS#######################",null,0,UVM_DEC);
	
	printer.print_field("RID",this.RID,8,UVM_DEC);
	foreach(RDATA[i])
	printer.print_field($sformatf("RDATA[%0d]",i),RDATA[i],32,UVM_DEC);
	foreach(RRESP[i])
	printer.print_field($sformatf("RRESP[%0d]",i),RRESP[i],2,UVM_DEC);
	printer.print_field("RLAST",this.RLAST,1,UVM_DEC);
	printer.print_field("RVALID",this.RVALID,1,UVM_DEC);
	printer.print_field("RREADY",this.RREADY,1,UVM_DEC);
endfunction

function bit do_compare(uvm_object rhs,uvm_comparer comparer);


	//handle for overriding//
	master_xtn rhs_;

	if(!$cast(rhs_,rhs))
	  begin
		`uvm_fatal("do_compare","cast of rhs is not proper")
		return 0;
	  end


	//comaparing the data//
	//sig_name ==rhs_.sig name//


	return super.do_compare(rhs,comparer) &&
			(AWID==rhs_.AWID)&&
			(AWADDR==rhs_.AWADDR)&&
			(AWLEN==rhs_.AWLEN)&&
			(AWSIZE==rhs_.AWSIZE)&&
			(AWBURST==rhs_.AWBURST)&& 
			(AWVALID==rhs_.AWVALID)&&
			(AWREADY==rhs_.AWREADY)&&
		

			(WID==rhs_.WID) &&
				(WDATA==rhs_.WDATA) &&
				(WSTRB==rhs_.WSTRB) &&
				(WLAST==rhs_.WLAST) &&
				(WVALID==rhs_.WVALID) &&
				(WREADY==rhs_.WREADY) &&
	
				(BID==rhs_.BID) &&
				(BRESP==rhs_.BRESP) &&
				(BVALID==rhs_.BVALID) &&
				(BREADY==rhs_.BREADY) &&

				(ARID==rhs_.ARID) &&
				(ARADDR==rhs_.ARADDR) &&
				(ARLEN==rhs_.ARLEN) &&
				(ARSIZE==rhs_.ARSIZE) &&
				(ARBURST==rhs_.ARBURST) &&
				(ARVALID==rhs_.ARVALID) &&
				(ARREADY==rhs_.ARREADY) &&

				(RID==rhs_.RID) &&
				(RDATA==rhs_.RDATA) &&
				(RRESP==rhs_.RRESP) &&
				(RLAST==rhs_.RLAST) &&
				(RVALID==rhs_.RVALID) &&
				(RREADY==rhs_.RREADY);
	endfunction
	
endclass












/*
class trans extends uvm_sequence_item;
 `uvm_object_utils(trans)
  function new(string name="trans");
     super.new(name);
  endfunction

 //WR ADDR CHANNEL 
  
     rand bit[3:0]   AWID;
     rand bit[31:0]  AWADDR;
     rand bit[3:0]   AWLEN;
     rand bit[2:0]   AWSIZE;
     rand bit[1:0]   AWBURST;

          bit        AWVALID;
          bit        AWREADY;

//   WR DATA CHANNEL
   
    rand bit[3:0]    WID;
    rand bit[31:0]   WDATA[];
    rand bit[3:0]    WSTRB[];
         bit         WLAST;
         bit         WVALID;
         bit         WREADY;

//   WR RESPONSE CHANNEL

     rand bit [3:0]   BID;
          bit [1:0]   BRESP;
          bit         BVALID;
          bit         BREADY;


//   RD ADDR CHANNEL
    rand  bit[3:0]   ARID;
    rand  bit[31:0]  ARADDR;
    rand  bit[3:0]   ARLEN;
    rand  bit[2:0]   ARSIZE;
    rand  bit[1:0]   ARBURST;

          bit        ARVALID;
          bit        ARREADY;

//  RD DATA CHANNEL

    rand bit[3:0]    RID;
    rand bit[31:0]   RDATA[];
         bit[1:0]    RRESP;
         bit         RLAST;
         bit         RVALID;
         bit         RREADY;



         
  /////////////////////////// CONSTRAINS FOR WRITE //////////////////////////


  constraint write_id      {AWID==WID;BID==WID;} // id match for every write channel

  constraint aw_burst      {AWBURST inside {[0:2]};} // types of burst 0,1,2
 
  constraint aw_size       {AWSIZE dist{0:=10,1:=10,2:=10};} // maximum bytes per beat
  
  constraint aw_lenght     {if(AWBURST==2) 
                               (AWLEN+1) inside {2,4,8,16}; } // address of wrap burst must be power of 2 AXI 3 max SUPPORTS 16 beats

  constraint wr_alignment2 {((AWBURST==2'b10 || AWBURST ==2'b00) && AWSIZE ==1 ) -> AWADDR %2==0 ;} // not supported unaligned address so address sholud be fixed to 0,2,4,6,8

  constraint wr_alignment4 {((AWBURST==2'b10 || AWBURST ==2'b00) && AWSIZE ==2 ) -> AWADDR %4==0 ;} // not supported unaligned address so address sholud be fixed to 0,4,8,12,16,

  //constraint max_w         {(AWADDR %4096 + (2**AWSIZE)*(AWLEN+1)) <4096;}

  constraint awlen         {AWLEN inside {[0:15]};}
  
  constraint wdata {WDATA.size() == (AWLEN+1) ;}
  constraint wstrobe {WSTRB.size() == (AWLEN+1) ;}
  
///////////////////////////// CONSTRAINTS FOR READ ////////////////////////////


  constraint read_id       {RID == ARID;}

  constraint ar_burst      {ARBURST inside {[0:2]};}

  constraint ar_size       {ARSIZE dist {0:=10, 1:=10,2:=10}; }
 
  constraint rd_alignment2 {((ARBURST==2'b10 || ARBURST ==2'b00) && ARSIZE ==1 ) -> ARADDR %2==0 ;} // not supported unaligned address so address sholud be fixed to 0,2,4,6,8

  constraint rd_alignment4 {((ARBURST==2'b10 || ARBURST ==2'b00) && ARSIZE ==2 ) -> ARADDR %4==0 ;} // not supported unaligned address so address sholud be fixed to 0,4,8,12,16,

  //constraint max_r         {(ARADDR %4096 + (2**ARSIZE)*(ARLEN+1)) <4096;}

  constraint arlen         {ARLEN inside {[0:15]};}
  
  constraint rdata         {RDATA.size() == (ARLEN+1) ;}
  


 function void post_randomize();
     w_addr_calc();
   
     r_addr_calc();

     strb_calc();     
    
 endfunction

 //////// //////////////////// CALCULATION PART FOR WRITE ADDRESS BASED ON BURST TYPES /////////////////////////////
 
  int unsigned w_addr[];
  
  function void w_addr_calc();
   int unsigned start_address = AWADDR;       // 16                                
   int unsigned no_of_bytes    = 2**AWSIZE;    // 2^2 = 4 
   int unsigned burst_length   = AWLEN+1;      // 7+1 = 8    8 beats will be generated each beat consists of 4 bytes of data,so address should be incremented based on my burst size(no_of_size) and burst type  
   int unsigned aligned_address= (int'(start_address/no_of_bytes))*no_of_bytes; // (16/4)*4 = 16
   int unsigned wrap_boundary  = (int'(aligned_address/(no_of_bytes*burst_length)))*(no_of_bytes*burst_length); // (16/(4*8))*(4*8)=>(16/32)*32=>0*32=> 0

   bit wrapped;
   w_addr = new[burst_length];
   w_addr[0]=start_address;

   if(AWBURST==2'b00)
   begin
    for(int i=2;i<=burst_length;i++)
        w_addr[i-1]=start_address; 
   end
   if(AWBURST==2'b01)
   begin
    for(int i=2;i<=burst_length;i++)
        w_addr[i-1]=aligned_address + ((i-1)*no_of_bytes);
   end
   if(AWBURST==2'b10)
   begin
     for(int i=2;i<=burst_length;i++) 
      begin
        if(!wrapped)
        begin
            w_addr[i-1]=aligned_address + (i-1)*no_of_bytes;
            if(w_addr[i-1]==wrap_boundary+(no_of_bytes*burst_length))
            begin
                w_addr[i-1]=wrap_boundary;
                wrapped++;
            end
        end
        else
           w_addr[i-1] =start_address +((i-1)*no_of_bytes) - (no_of_bytes*burst_length);
     end
      
   end
  endfunction 

 //////////////////////////// CALCULATION PART FOR READ ADDRESS BASED ON BURST TYPES /////////////////////////////
 
  int unsigned r_addr[];
  
  function void r_addr_calc();
   int unsigned start_address = ARADDR;       // 16                                
   int unsigned no_of_bytes    = 2**ARSIZE;    // 2^2 = 4 
   int unsigned burst_length   = ARLEN+1;      // 7+1 = 8    8 beats will be generated each beat consists of 4 bytes of data,so address should be incremented based on my burst size(no_of_size) and burst type  
   int unsigned aligned_address= (int'(start_address/no_of_bytes))*no_of_bytes; // (16/4)*4 = 16
   int unsigned wrap_boundary  = (int'(aligned_address/(no_of_bytes*burst_length)))*(no_of_bytes*burst_length); // (16/(4*8))*(4*8)=>(16/32)*32=>0*32=> 0

   bit wrapped;
   r_addr = new[burst_length];
   r_addr[0]=start_address;
   if(ARBURST==2'b00)
    for(int i=2;i<=burst_length;i++)
        r_addr[i-1]=start_address; 
   if(ARBURST==2'b01)
    for(int i=2;i<=burst_length;i++)
        r_addr[i-1]=aligned_address + ((i-1)*no_of_bytes);
   if(ARBURST==2'b10)
   begin
     for(int i=2;i<=burst_length;i++)
      begin
        if(!wrapped)
        begin
            r_addr[i-1]=aligned_address + (i-1)*no_of_bytes;
            if(r_addr[i-1]==wrap_boundary+(no_of_bytes*burst_length))
            begin
                r_addr[i-1]=wrap_boundary;
                wrapped++;
            end
        end
        else
           r_addr[i-1] =start_address +((i-1)*no_of_bytes) - (no_of_bytes*burst_length);
     end
      
   end
  endfunction 



////////////////////////////// STROBE CALCULATION /////////////////////////////

//  Which byte lane is valid to write/read the data. my starting is 16 in that address it tells which bytelane should be valid


function void strb_calc();
   
   int unsigned start_address = AWADDR; //34 
   int unsigned no_of_bytes   = 2**AWSIZE;//2
   int unsigned burst_length  = AWLEN+1;//13
   int unsigned aligned_address= (int'(start_address/no_of_bytes)) * no_of_bytes ; // 34/2 =17 *2 =34 
  
   int data_bus_bytes = 4;
   int unsigned lower_byte_lane;
   int unsigned upper_byte_lane;

   int unsigned lower_byte_lane_0 = start_address-(int'(start_address/data_bus_bytes))*data_bus_bytes; // 34 - ((34/4)*4) = 34 - 32 = 2 
   int unsigned upper_byte_lane_0 = aligned_address+(no_of_bytes-1)-(int'(start_address/data_bus_bytes))*data_bus_bytes; // 34+1 => 35 -32 = 3 
  
*/
 /*  for(int i=0;i<burst_length;i++)
      for(int j=0;j<4;j++) 
          WSTRB[i][j]=0;
*/
  /* 
   for(int j=lower_byte_lane_0 ; j<=upper_byte_lane_0;j++)  // unaligned first transfer
          WSTRB[0][j]=1; 
        $display(" ***************************************** =%p",WSTRB);
        // WSTRB[0][2]=1
        // WSTRB[0][3]=1          

   for(int N=1;N<burst_length;N++) // aligned remaining transfers
   begin
        lower_byte_lane = w_addr[N]-(int'(w_addr[N]/data_bus_bytes)) * data_bus_bytes; //  34 - (34/4)*4 =  2
        upper_byte_lane = lower_byte_lane+no_of_bytes-1; // 2+2 -1 => 3
   
   for(int j=lower_byte_lane;j<=upper_byte_lane;j++)
         WSTRB[N][j]=1;
       //   WSTRB[1][2]=1;
       //   WSTRB[1][3]=1;


   end

endfunction

function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    trans rhs_;
    if (!$cast(rhs_, rhs)) begin
        `uvm_fatal("do_compare", "Cast to trans failed")
        return 0;
    end

    return super.do_compare(rhs, comparer) &&
           AWID    == rhs_.AWID &&
           AWADDR  == rhs_.AWADDR &&
           AWLEN   == rhs_.AWLEN &&
           AWSIZE  == rhs_.AWSIZE &&
           AWBURST == rhs_.AWBURST &&

           WID     == rhs_.WID &&
           WDATA   == rhs_.WDATA &&
           WSTRB   == rhs_.WSTRB &&
           WLAST   == rhs_.WLAST &&
           BID     == rhs_.BID &&
           BRESP   == rhs_.BRESP &&

           ARID    == rhs_.ARID &&
           ARADDR  == rhs_.ARADDR &&
           ARLEN   == rhs_.ARLEN &&
           ARSIZE  == rhs_.ARSIZE &&
           ARBURST == rhs_.ARBURST &&

           RID     == rhs_.RID &&
           RDATA   == rhs_.RDATA &&
           RRESP   == rhs_.RRESP &&
           RLAST   == rhs_.RLAST;
endfunction


function void do_print(uvm_printer printer);

		super.do_print(printer);

		//Write Address Signals
		printer.print_field(	"AWID",     this.AWID,    $bits(this.AWID),	UVM_DEC);
		printer.print_field(	"AWADDR",   this.AWADDR,  $bits(this.AWADDR),	UVM_HEX);
		
		foreach(w_addr[i])
			begin
			     printer.print_field($sformatf("Write Address[%0d]",i),   this.w_addr[i],   $bits(w_addr[i]) ,UVM_HEX);
			end
			
		printer.print_field(	"AWLEN",    this.AWLEN,   $bits(this.AWLEN), 	UVM_DEC);
		printer.print_field(	"AWSIZE",   this.AWSIZE,  $bits(this.AWSIZE), 	UVM_DEC);			
		printer.print_field(	"AWBURST",  this.AWBURST, $bits(this.AWBURST), 	UVM_DEC);	
		printer.print_field(	"AWVALID",  this.AWVALID, $bits(this.AWVALID), 	UVM_DEC);	
		printer.print_field(	"AWREADY",  this.AWREADY, $bits(this.AWREADY), 	UVM_DEC);	

		//Write Data Channels Signals	
		printer.print_field(	"WID",     this.WID,     $bits(this.WID), 	UVM_DEC);
		
		foreach(WDATA[i])
			begin
	    		     printer.print_field($sformatf("WDATA[%0d]",i),   this.WDATA[i], $bits(this.WDATA[i]), 	UVM_DEC);
			     printer.print_field($sformatf("WSTRB[%0d]",i),   this.WSTRB[i],  $bits(this.WSTRB[i]), 	UVM_DEC);
			end

		printer.print_field(	"WLAST",   this.WLAST,   $bits(this.WLAST), 	UVM_DEC);	
		printer.print_field(	"WREADY",  this.WREADY,  $bits(this.WREADY), 	UVM_DEC);	

		//Write Response Channel Signals		
		printer.print_field(	"BID",     this.BID,     $bits(this.BID), 	UVM_DEC);	
		printer.print_field(	"BRESP",   this.BRESP,   $bits(this.BRESP), 	UVM_DEC);	
		printer.print_field(	"BVALID",  this.BVALID,  $bits(this.BVALID), 	UVM_DEC);	
		printer.print_field(	"BREADY",  this.BREADY,  $bits(this.BREADY), 	UVM_DEC);	

		// Read Address Channel Signals			
		printer.print_field(	"ARID",    this.ARID,    $bits(this.ARID), 	UVM_DEC);	
		printer.print_field(	"ARADDR",  this.ARADDR,  $bits(this.ARADDR),	UVM_HEX);
			
		foreach(r_addr[i])
			begin
			     printer.print_field($sformatf("Read Address[%0d]",i),   this.r_addr[i],   $bits(r_addr[i]), UVM_HEX);
			end
			
		printer.print_field(	"ARLEN",   this.ARLEN,   $bits(this.ARLEN), 	UVM_DEC);	
		printer.print_field(	"ARSIZE",  this.ARSIZE,  $bits(this.ARSIZE), 	UVM_DEC);	
		printer.print_field(	"ARBURST", this.ARBURST, $bits(this.ARBURST), 	UVM_DEC);	
		printer.print_field(	"ARVALID", this.ARVALID, $bits(this.ARVALID), 	UVM_DEC);	
		printer.print_field(	"ARREADY", this.ARREADY, $bits(this.ARREADY), 	UVM_DEC);	
	
		//Read Data Channel Signals			
		printer.print_field(	"RID",     this.RID,     $bits(this.RID), 	UVM_DEC);
		
		foreach(RDATA[i])
			begin
			     printer.print_field("RDATA",   this.RDATA[i],   $bits(this.RDATA[i]),UVM_DEC);
			     printer.print_field("RRESP",   this.RRESP[i],   $bits(this.RRESP[i]), UVM_DEC);
			end
	
		printer.print_field(	"RLAST",   this.RLAST,   $bits(this.RLAST), 	UVM_DEC);	
		printer.print_field(	"RVALID",  this.RVALID,  $bits(this.RVALID), 	UVM_DEC);	
		printer.print_field(	"RREADY",  this.RREADY,  $bits(this.RREADY), 	UVM_DEC);	

	endfunction: do_print
endclass
*/
/*


//////////////////////////////READ STROBE CALCULATION /////////////////////////////

bit[3:0]    RSTRB[];

function void rd_strb_calc();
    int unsigned start_address=ARADDR;
    int unsigned no_of_bytes  = 2**ARSIZE;
    int unsigned burst_length =ARLEN+1;
    int unsigned aligned_address=(int'(start_address/no_of_bytes))*no_of_bytes;
  
    int data_bus_bytes=4;
    int unsigned lower_byte_lane;
    int unsigned upper_byte_lane;
    
    int unsigned lower_byte_lane0=start_address - (int'(start_address/data_bus_bytes))*data_bus_bytes;
    int unsigned upper_byte_lane0=aligned_address+(no_of_bytes-1)- (int'(start_address/data_bus_bytes))*data_bus_bytes;
    
    RSTRB = new [burst_length];
    
    for(int j=lower_byte_lane0;j<=upper_byte_lane0;j++)
         RSTRB[0][j]=1;
    for(int N=1;N<burst_length;N++)
    begin
       lower_byte_lane = r_addr[N]-(int'(r_addr[N]/data_bus_bytes)) * data_bus_bytes;
       upper_byte_lane = lower_byte_lane+no_of_bytes-1;
   
    for(int j=lower_byte_lane;j<=upper_byte_lane;j++)
         RSTRB[N][j]=1;

    end
endfunction





class axi_xtn extends uvm_sequence_item;

	`uvm_object_utils(axi_xtn)
	
	function new(string name="axi_xtn");
		super.new(name);
	endfunction

	//Write Address Signals
	rand bit [7:0] 	AWID;
	rand bit [31:0] AWADDR;
	rand bit [7:0] 	AWLEN;
	rand bit [2:0] 	AWSIZE;
	rand bit [1:0] 	AWBURST;
	
	bit 		AWVALID;
	bit 		AWREADY;
       
	//Write Data Channels Signals
	rand bit [7:0] 	WID;
	rand bit [31:0] WDATA[];
	rand bit 	WLAST;

	bit  	 [3:0] 	WSTRB[];
	bit 		WVALID;
	bit 		WREADY;

	//Write Response Channel Signals
	rand bit [7:0] 	BID;

	bit 	 [1:0] 	BRESP;
	bit 		BVALID;
	bit 		BREADY;
	
	// Read Address Channel Signals
	rand bit [7:0] 	ARID;
	rand bit [31:0] ARADDR;
	rand bit [7:0] 	ARLEN;
	rand bit [2:0] 	ARSIZE;
	rand bit [1:0] 	ARBURST;

	bit 		ARVALID;
	bit 		ARREADY;

	//Read Data Channel Signals
	rand bit [7:0] 	RID;
	rand bit [31:0] RDATA[];

	bit 	 [1:0] 	RRESP;
	bit 		RLAST;
	bit 		RVALID;
	bit 		RREADY;

	//Logic Variables
	bit 	 [31:0]	waddr[];
	int 		no_wbytes;
	int 		aligned_waddr;
	int 		start_waddr;

	bit 	 [31:0]	raddr[];
	int 		no_rbytes;
	int 		aligned_raddr;
	int 		start_raddr;

	constraint wdata		{WDATA.size()==(AWLEN+1);}

	constraint rdata		{RDATA.size()==(ARLEN+1);}

	constraint aw_burst		{AWBURST inside {[0:2]};}

	constraint ar_burst		{ARBURST inside {[0:2]};}

	constraint write_id		{AWID==WID; BID==WID;}

	constraint read_id		{RID==ARID;}

	constraint aw_size		{AWSIZE dist{0:=10, 1:=10, 2:=10};} //Maximum bytes per beat.

	constraint ar_size		{ARSIZE dist{0:=10, 1:=10, 2:=10};}

	constraint aw_length		{if(AWBURST==2) 
			 		   (AWLEN+1) inside {2,4,8,16};} //Addresses of WRAP burst must be powe multiple of 2.

	constraint ar_length		{if(ARBURST==2) 
			 		   (ARLEN+1) inside {2,4,8,16};}

	constraint write_alignment2	{((AWBURST==2'b10 || AWBURST==2'b00) && AWSIZE==1) -> AWADDR%2==0;} //0,2,4,6,8

	constraint write_alignment4	{((AWBURST==2'b10 || AWBURST==2'b00) && AWSIZE==2) -> AWADDR%4==0;} //0,4,8,12,16

	constraint read_alignment2	{((ARBURST==2'b10 || ARBURST==2'b00) && ARSIZE==1) -> ARADDR%2==0;} //0,2,4,6,8

	constraint read_alignment4	{((ARBURST==2'b10 || ARBURST==2'b00) && ARSIZE==2) -> ARADDR%4==0;} //0,4,8,12,16

	constraint max_w		{(AWADDR%4096 + (2**AWSIZE)*(AWLEN+1))<4096;} //In AXI3, every burst is limited to 4kB.

	constraint max_r		{(ARADDR%4096 + (2**ARSIZE)*(ARLEN+1))<4096;}

	constraint awlen		{AWLEN inside {[0:15]};} //Since the AWLEN is 4 bits.

	constraint arlen		{ARLEN inside {[0:15]};}

	function void calc_waddr();

		bit wb; //Which beat within a burst.
		int burst_len		= AWLEN+1;
		int N			= burst_len; 
		int wrap_boundary	= (int'(AWADDR/(no_wbytes*burst_len)))*(no_wbytes*burst_len);
		int next_addr		= (wrap_boundary+(no_wbytes*burst_len)); 

		no_wbytes		= 2**AWSIZE; //Number_bytes. Number of bytes per write beat.
		waddr			= new[AWLEN+1]; //Address_N. This is a static array with element size = burst_length.

		waddr[0]		= AWADDR; //Starting address is AWADDR sent by the master.

		aligned_waddr		= (int'(AWADDR/no_wbytes))*no_wbytes;

		start_waddr		= AWADDR;

		for(int i = 2; i<(burst_len+1); i++)
		   begin
			if(AWBURST==0)
			   waddr[i-1]	= AWADDR; //Every beat starts at the same address in Fixed burst.

			if(AWBURST==1)
			   waddr[i-1]	= aligned_waddr + ((i-1)*no_wbytes); //INCR burst.

			if(AWBURST==2)
			   begin
				if(wb==0) //First beat within a burst.	
				   begin
					waddr[i-1] = aligned_waddr+(i-1)*no_wbytes; //WRAP burst.
	
					if(waddr[i-1]==(wrap_boundary+(no_wbytes*burst_len))) //Reached the maximum range of the WRAP burst.
					   begin
						waddr[i-1] = wrap_boundary;
						wb++;
					   end
				   end
				else	//Subsequent beats within a burst.
				        waddr[i-1] = start_waddr+((i-1)*no_wbytes)-(no_wbytes*burst_len);
			   end

		   end

	endfunction: calc_waddr

	function void strb_calc();

		int lower_byte_lane, upper_byte_lane;
		int data_bus_bytes	= 4;
		int lower_byte_lane_0	= start_waddr-((int'(start_waddr/data_bus_bytes))*data_bus_bytes); //Lower lane for the 1st beat.
		int upper_byte_lane_0	= (aligned_waddr+(no_wbytes-1))-((int'(start_waddr/data_bus_bytes))*data_bus_bytes); //Upper lane for the 1st beat.
	
		for(int j = lower_byte_lane_0; j<= upper_byte_lane_0; j++) //Everything in between the upper and lower lane must be 1.
		    begin
			WSTRB[0][j]=1;
		    end

		for(int i = 1; i<(AWLEN+1); i++)
		    begin
			lower_byte_lane	= waddr[i]-(int'(waddr[i]/data_bus_bytes))*data_bus_bytes;
			upper_byte_lane	= lower_byte_lane+no_wbytes-1;
		
			for(int j = lower_byte_lane; j<=upper_byte_lane; j++)
			    begin
				WSTRB[i][j] = 1;
			    end
		    end

	endfunction: strb_calc
				
	function void calc_raddr();

		bit wb;
		int burst_len 	  	= ARLEN+1;
		int N 		  	= burst_len;
		int wrap_boundary 	= (int'(ARADDR/(no_rbytes*burst_len)))*(no_rbytes*burst_len);
		int next_addr     	= wrap_boundary+(no_rbytes*burst_len);

		raddr		  	= new[ARLEN+1];
 		no_rbytes	  	= 2**ARSIZE;

		raddr[0]	  	= ARADDR;
	
		aligned_raddr	  	= (int'(ARADDR/no_rbytes))*no_rbytes;

		start_raddr	  	= ARADDR;

		for(int i = 2; i<(burst_len+1); i++)
		    begin
			if(ARBURST==0)
			   raddr[i-1]	= ARADDR;

			if(ARBURST==1)
			   raddr[i-1]	= aligned_raddr+(i-1)*no_rbytes;

			if(ARBURST==2)
			   begin
				if(wb==0)	
				   begin
					raddr[i-1] = aligned_raddr+(i-1)*no_rbytes;
	
					if(raddr[i-1]==(wrap_boundary+(no_rbytes*burst_len)))
					   begin
						raddr[i-1] = wrap_boundary;
						wb++;
					   end

				   end
				else	
					raddr[i-1] = start_raddr+((i-1)*no_rbytes)-(no_rbytes*burst_len);
			   end
		     end

	endfunction: calc_raddr
	
	function void post_randomize();

		//------------------For Write.
	 	no_wbytes	= 2**AWSIZE;
           	aligned_waddr	= (int'(AWADDR/no_wbytes))*no_wbytes;
		start_waddr	= AWADDR;
		WSTRB		= new[AWLEN+1];

		//------------------For Read.
		no_rbytes	= 2**ARSIZE;
		aligned_raddr	= (int'(ARADDR/no_rbytes))*no_rbytes;
		start_raddr	= ARADDR;

		calc_waddr();
		strb_calc();
		
		calc_raddr();

	endfunction: post_randomize
		
	function void do_print(uvm_printer printer);

		super.do_print(printer);

		//Write Address Signals
		printer.print_field(	"AWID",     this.AWID,    $bits(this.AWID),	UVM_DEC);
		printer.print_field(	"AWADDR",   this.AWADDR,  $bits(this.AWADDR),	UVM_HEX);
		
		foreach(waddr[i])
			begin
			     printer.print_field($sformatf("Write Address[%0d]",i),   this.waddr[i],   $bits(waddr[i]) ,UVM_HEX);
			end
			
		printer.print_field(	"AWLEN",    this.AWLEN,   $bits(this.AWLEN), 	UVM_DEC);
		printer.print_field(	"AWSIZE",   this.AWSIZE,  $bits(this.AWSIZE), 	UVM_DEC);			
		printer.print_field(	"AWBURST",  this.AWBURST, $bits(this.AWBURST), 	UVM_DEC);	
		printer.print_field(	"AWVALID",  this.AWVALID, $bits(this.AWVALID), 	UVM_DEC);	
		printer.print_field(	"AWREADY",  this.AWREADY, $bits(this.AWREADY), 	UVM_DEC);	

		//Write Data Channels Signals	
		printer.print_field(	"WID",     this.WID,     $bits(this.WID), 	UVM_DEC);
		
		foreach(WDATA[i])
			begin
	    		     printer.print_field($sformatf("WDATA[%0d]",i),   this.WDATA[i], $bits(this.WDATA[i]), 	UVM_DEC);
			     printer.print_field($sformatf("WSTRB[%0d]",i),   this.WSTRB[i],  $bits(this.WSTRB[i]), 	UVM_BIN);
			end

		printer.print_field(	"WLAST",   this.WLAST,   $bits(this.WLAST), 	UVM_DEC);	
		printer.print_field(	"WREADY",  this.WREADY,  $bits(this.WREADY), 	UVM_DEC);	

		//Write Response Channel Signals		
		printer.print_field(	"BID",     this.BID,     $bits(this.BID), 	UVM_DEC);	
		printer.print_field(	"BRESP",   this.BRESP,   $bits(this.BRESP), 	UVM_DEC);	
		printer.print_field(	"BVALID",  this.BVALID,  $bits(this.BVALID), 	UVM_DEC);	
		printer.print_field(	"BREADY",  this.BREADY,  $bits(this.BREADY), 	UVM_DEC);	

		// Read Address Channel Signals			
		printer.print_field(	"ARID",    this.ARID,    $bits(this.ARID), 	UVM_DEC);	
		printer.print_field(	"ARADDR",  this.ARADDR,  $bits(this.ARADDR),	UVM_HEX);
			
		foreach(raddr[i])
			begin
			     printer.print_field($sformatf("Read Address[%0d]",i),   this.raddr[i],   $bits(raddr[i]), UVM_HEX);
			end
			
		printer.print_field(	"ARLEN",   this.ARLEN,   $bits(this.ARLEN), 	UVM_DEC);	
		printer.print_field(	"ARSIZE",  this.ARSIZE,  $bits(this.ARSIZE), 	UVM_DEC);	
		printer.print_field(	"ARBURST", this.ARBURST, $bits(this.ARBURST), 	UVM_DEC);	
		printer.print_field(	"ARVALID", this.ARVALID, $bits(this.ARVALID), 	UVM_DEC);	
		printer.print_field(	"ARREADY", this.ARREADY, $bits(this.ARREADY), 	UVM_DEC);	
	
		//Read Data Channel Signals			
		printer.print_field(	"RID",     this.RID,     $bits(this.RID), 	UVM_DEC);
		
		foreach(RDATA[i])
			begin
			     printer.print_field("RDATA",   this.RDATA[i],   $bits(this.RDATA[i]),UVM_DEC);
			     printer.print_field("RRESP",   this.RRESP[i],   $bits(this.RRESP[i]), UVM_DEC);
			end
	
		printer.print_field(	"RLAST",   this.RLAST,   $bits(this.RLAST), 	UVM_DEC);	
		printer.print_field(	"RVALID",  this.RVALID,  $bits(this.RVALID), 	UVM_DEC);	
		printer.print_field(	"RREADY",  this.RREADY,  $bits(this.RREADY), 	UVM_DEC);	

	endfunction: do_print

endclass: axi_xtn







*/







