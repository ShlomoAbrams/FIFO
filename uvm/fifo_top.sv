`include "uvm_macros.svh"
import uvm_pkg::*;
import fifo_pkg::*;

module fifo_connector ( // bridge between VHDL Signals and SV interface
		input wclken_in,
		input rclken_in
	);
		assign fifo_top.p_if.wclken_wire = wclken_in; // assign internal signal of dut to interface
		assign fifo_top.p_if.rclken_wire = rclken_in; // assign internal signal of dut to interface
	endmodule
module fifo_top; 					// Permanent module to simulate the hardware 
	bind fifo fifo_sva #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) sva_inst (
		.wclk(wclk),	
		.wrst_n	(wrst_n),	
		.winc	(winc),
		.wdata	(wdata),
		.wfull	(wfull),
		.rclk	(rclk),	
		.rrst_n	(rrst_n),	
		.rinc	(rinc),
		.rdata	(rdata),
		.rempty	(rempty),

		.wclken		(wclken_wire),
		.rclken		(rclken_wire),
		.waddr		(waddr_wire),
		.raddr		(raddr_wire),
		.wptr_g_cur	(wptr_wire),
		.rptr_g_cur	(rptr_wire),
		.wptr_b_cur(wptr_full_unit.wptr_b_cur),
		.rptr_b_cur(rptr_empty_unit.rptr_b_cur),
		.r2q_wptr(r2qs_wptr),
		.w2q_rptr(w2q_rptr),
		.wfull_wire(wfull_wire),
		.rempty_wire(rempty_wire)
	);
	bind fifo fifo_connector conn_inst (
		.wclken_in(wclken_wire),
		.rclken_in(rclken_wire)
	);
	bit wclk, rclk;				// Generate clocks
	always #5 wclk = ~wclk; 	// Write Clock: 100Mhz (10 ns period)
	always #7 rclk = ~rclk; 	// Read Clock: slower than write clocks
	fifo_if p_if (wclk, rclk); // connect signals to Physical interface
	fifo dut(				// Connect RTL pins to wires in 'p_if' cable
		.wclk	(p_if.wclk),	// Connect RTL Write Clock to Interface wire
		.wrst_n	(p_if.wrst_n),	// Connect RTL Write Reset to Interface wire
		.winc	(p_if.winc),
		.wdata	(p_if.wdata),
		.wfull	(p_if.wfull),
		.rclk	(p_if.rclk),	// Connect RTL Read Clock to Interface wire
		.rrst_n	(p_if.rrst_n),	// Connect RTL Read Reset to Interface wire
		.rinc	(p_if.rinc),
		.rdata	(p_if.rdata),
		.rempty	(p_if.rempty)
	);
	initial begin 
		wclk = 0;
		rclk =0;
		p_if.wrst_n = 0;
		p_if.rrst_n = 0;
		#30;
		p_if.wrst_n = 1;
		p_if.rrst_n = 1;
	end
	initial begin 
		uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", p_if); // CONFIG DATABASE: publish the physical interface (p_if) so components can find interface using "vif"
		run_test();
	end
endmodule