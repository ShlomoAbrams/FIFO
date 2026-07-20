`include "uvm_macros.svh"
import uvm_pkg::*;
import fifo_pkg::*;

// CONNECTOR MODULE: Serves as a bridge to pass internal VHDL signals into the SystemVerilog interface
module fifo_connector (
	input wclken_in,
	input rclken_in
);
	assign fifo_top.p_if.wclken_wire = wclken_in; // Connect VHDL write clock enable to interface wire
	assign fifo_top.p_if.rclken_wire = rclken_in; // Connect VHDL read clock enable to interface wire
endmodule

// TOP-LEVEL TESTBENCH MODULE
module fifo_top #(
	parameter DUT_DATA_WIDTH = 8,  // Default Data Width: 8 bits
	parameter DUT_ADDR_WIDTH = 4   // Default Address Width: 4 bits (Depth = 2^4 = 16)
); 

	// SVA BIND STATEMENT: Binds SystemVerilog Assertions module to the VHDL DUT instance
	bind fifo fifo_sva #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) sva_inst (
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
		.r2q_wptr(r2q_wptr),
		.w2q_rptr(w2q_rptr),
		.wfull_wire(wfull_wire),
		.rempty_wire(rempty_wire)
	);

	// CONNECTOR BIND STATEMENT: Binds connector module to expose internal VHDL signals to interface
	bind fifo fifo_connector conn_inst (
		.wclken_in(wclken_wire),
		.rclken_in(rclken_wire)
	);

	// DYNAMIC CLOCK GENERATION SYSTEM
	bit wclk, rclk;               // Declare write clock and read clock signals
	int wclk_half_period = 5; 	// Default Write Clock half-period: 5ns (100MHz)
	int rclk_half_period = 7; 	// Default Read Clock half-period: 7ns (~71.4MHz)

	// PLUSARGS PARSING: Allows dynamic clock period sweeping from command-line without re-compiling!
	initial begin
		int user_wclk_half, user_rclk_half;

		// Check if +WCLK_HALF=<val> was passed to vsim
		if ($value$plusargs("WCLK_HALF=%d", user_wclk_half)) wclk_half_period = user_wclk_half;

		// Check if +RCLK_HALF=<val> was passed to vsim
		if ($value$plusargs("RCLK_HALF=%d", user_rclk_half)) rclk_half_period = user_rclk_half;

		// Safety check: ensure clock period cannot be 0 or negative
		if (wclk_half_period < 1) wclk_half_period = 1;
		if (rclk_half_period < 1) rclk_half_period = 1;

		`uvm_info("TOP", $sformatf("Clock Periods Configured: Write Half-Period=%0dns, Read Half-Period=%0dns", wclk_half_period, rclk_half_period), UVM_LOW)
	end

	// Clock toggle loops driven by dynamic half-period variables
	always #(wclk_half_period) wclk = ~wclk;
	always #(rclk_half_period) rclk = ~rclk;

	// Physical Interface Instantiation (Matches DUT_DATA_WIDTH)
	fifo_if #(.DATA_WIDTH(DUT_DATA_WIDTH)) p_if (wclk, rclk); // Connect clock signals to interface bundle

	// DUT (Design Under Test) VHDL Top Instantiation
	fifo #(
		.DATA_WIDTH(DUT_DATA_WIDTH),
		.ADDR_WIDTH(DUT_ADDR_WIDTH)
	) dut (
		.wclk	(p_if.wclk),	// Connect write clock to DUT
		.wrst_n	(p_if.wrst_n),	// Connect write reset to DUT
		.winc	(p_if.winc),    // Connect write enable to DUT
		.wdata	(p_if.wdata),   // Connect write data to DUT
		.wfull	(p_if.wfull),   // Connect full flag to DUT
		.rclk	(p_if.rclk),	// Connect read clock to DUT
		.rrst_n	(p_if.rrst_n),	// Connect read reset to DUT
		.rinc	(p_if.rinc),    // Connect read enable to DUT
		.rdata	(p_if.rdata),   // Connect read data to DUT
		.rempty	(p_if.rempty)   // Connect empty flag to DUT
	);

	initial begin // INITIAL RESET GENERATION BLOCK
		wclk = 0;
		rclk = 0;
		p_if.wrst_n = 0; // Assert write reset at Time 0
		p_if.rrst_n = 0; // Assert read reset at Time 0
		#30;             // Hold reset active for 30ns
		p_if.wrst_n = 1; // Release write reset
		p_if.rrst_n = 1; // Release read reset
	end

	initial begin // UVM STARTUP & CONFIG DATABASE SETUP
		uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", p_if); // Publish virtual interface into UVM configuration database so driver, monitor, and scbd can retrieve it
		run_test(); // Start UVM test specified by +UVM_TESTNAME flag
	end
endmodule