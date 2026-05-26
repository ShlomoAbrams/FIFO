`include "uvm_macros.svh"
import uvm_pkg::*;
class fifo_r_driver extends uvm_driver #(fifo_transaction); // Defines "Read Worker" based on UVM Driver template that handles "fifo transaction" packets. 
	`uvm_component_utils(fifo_r_driver) // FACTORY: Register the driver in UVM library so it can be used later
	virtual fifo_if vif; // the "Virtual" Interface is the software handle to the physical fifo interface

	function new(string name, uvm_component parent); // CONSTUCTOR: creates worker
		super.new(name, parent); // establish compunents name and place in hierarchy 
	endfunction 
	
	virtual function void build_phase(uvm_phase phase); // BUILD PHASE: Runs at Time 0 to fetch configuration data before simulation starts
		super.build_phase(phase);
		if(!uvm_config_db#(virtual fifo_if)::get(this, "","vif",vif)) begin 	// Reach into Database for the Virtual Interface
			`uvm_fatal("DRV", "Couldn't find virtual interface in config_db!")	// If "get" fails then there wasn't a Virtual Interface
		end
	endfunction
	
	virtual task run_phase(uvm_phase phase); // WORK SHIFT: this task runs for the duration of the simulation
	vif.r_d_cb.rinc <= 1'b0; // Initialize to 0, so we dont read garbage to fifo in startup
	wait(vif.rrst_n === 1'b1); // wait until reset to turn off to read the data
	`uvm_info("DRV", "Reset released, can read data data", UVM_LOW) 
	forever begin 
		seq_item_port.get_next_item(req); // HANDSHAKE: Ask sequencer (boss) for the request that contains the next transaction
		drive_item(req); // EXECUTION: Translate the transaction object into actual high/low voltage bits
		seq_item_port.item_done(); // FEEDBACK: tell sequencer we finished so it can release next item
		end 
	endtask

	virtual task drive_item(fifo_transaction tr); // TRANSLATOR: Task that turn software into hardware reality.
		repeat (tr.delay) @(vif.r_d_cb); // STRESS TESTING: wait for randomized delay to simulate slow or fast traffic
		
		if (tr.en) begin // if the transaction says "read" drive rinc & rdata
			vif.r_d_cb.rinc <= 1'b1; // READ PROTOCOL: turn rinc high
			@(vif.r_d_cb); // wait for one clock block edge to execute read (it reads 1 step after edge)
			vif.r_d_cb.rinc <= 1'b0; 	// Disable too prevent double read
		end
	endtask
endclass