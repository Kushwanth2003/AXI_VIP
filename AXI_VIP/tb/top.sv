
//`timescale 1ns/1ps
module top();

	import test_pkg::*;
	import uvm_pkg::*;

	
	bit clk;
	always #5 clk = ~clk;

	axi_if vif(clk);

	initial
		begin
			`ifdef VCS
         		$fsdbDumpvars(0, top);
        		`endif

			uvm_config_db#(virtual axi_if)::set(null,"*","axi_if",vif);
			run_test();
		end

endmodule
