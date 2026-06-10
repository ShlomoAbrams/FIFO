`include "uvm_macros.svh"

package fifo_pkg;
	import uvm_pkg::*;

	`include "fifo_transaction.sv"
	`include "fifo_w_sequence.sv"
	`include "fifo_r_sequence.sv"
	`include "fifo_w_burst_sequence.sv"
	`include "fifo_r_drain_sequence.sv"
	`include "fifo_w_driver.sv"
	`include "fifo_r_driver.sv"
	`include "fifo_w_monitor.sv"
	`include "fifo_r_monitor.sv"
	`include "fifo_w_agent.sv"
	`include "fifo_r_agent.sv"
	`include "fifo_scoreboard.sv"
	`include "fifo_env.sv"
	`include "fifo_test.sv"
	`include "fifo_reset_recovery_test.sv"
endpackage
