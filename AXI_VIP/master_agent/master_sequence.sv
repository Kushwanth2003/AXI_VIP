class master_sequence extends uvm_sequence#(master_xtn);

	`uvm_object_utils(master_sequence)

	

	function new(string name="master_sequence");
		super.new(name);
	endfunction


endclass

class fixed extends master_sequence;
	`uvm_object_utils(fixed)

	master_xtn xtn;
	function new(string name= "fixed");
		super.new(name);
	endfunction

	task body();
		repeat(1)
			begin
				xtn=master_xtn::type_id::create("xtn");
				start_item(xtn);
				assert(xtn.randomize() with {AWBURST==2'b00;AWADDR=='d4;AWSIZE==2;});
				finish_item(xtn);
			end
	endtask

endclass




class increment extends master_sequence;
	`uvm_object_utils(increment)


	function new(string name = "increment");
		super.new(name);
	endfunction
	master_xtn xtn; 
	task body();
		repeat(2)
			begin
				xtn=master_xtn::type_id::create("xtn");
				start_item(xtn);
				assert(xtn.randomize() with {AWBURST==2'b01;AWADDR=='d3;});
				finish_item(xtn);
			end

	endtask
endclass




class wrap extends master_sequence;
	`uvm_object_utils(wrap)

	master_xtn xtn; 
	function new(string name="wrap");
		super.new(name);
	endfunction

	task body();
		repeat(2)
			begin
				xtn=master_xtn::type_id::create("xtn");
				start_item(xtn);
				assert(xtn.randomize() with {AWBURST==2'b10;});
				finish_item(xtn);
			end
	endtask

endclass
