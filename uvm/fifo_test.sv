`include "uvm_macros.svh"
import uvm_pkg::*;

class fifo_test extends uvm_test; // BLUEPRINT: The Test Defines specific scenario for this run
	`uvm_component_utils(fifo_test) // FACTORY: Register the Test so UVM can spawn it in the top file
	fifo_env env; 			// DECLIRATION: Handle for enviroment
	virtual fifo_if p_if; 	// Handle for interface signals 
	
	function new(string name, uvm_component parent); // CONSTRUCTOR: Links this component into the UVM hierarchy tree
		super.new(name, parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase); 
		super.build_phase(phase);
		env = fifo_env::type_id::create("env", this); // CONPONENT CREATION: spawning environment using the factory
		if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", p_if)) begin // Retrieve the interface from data base
			`uvm_fatal("TEST", "Virtual interface not found in config_db")
		end
		uvm_top.set_timeout(1ms);			// the simulation cant exceed limit
	endfunction
	
	virtual task run_phase(uvm_phase phase);	// RUN PHASE:
		fifo_w_sequence w_seq; 					// Create Write Sequence Handle
		fifo_r_sequence r_seq;					// Create Read Sequence Handle
		fifo_w_burst_sequence w_burst_seq, w_burst_stress_seq ; 		// Create Write burst Sequence Handle
		fifo_r_drain_sequence r_drain_seq, r_drain_stress_seq;		// Create Read drain Sequence Handle
		w_seq = fifo_w_sequence::type_id::create("w_seq"); // Create Write Sequence
		r_seq = fifo_r_sequence::type_id::create("r_seq"); // Create Read Sequence
		w_burst_seq = fifo_w_burst_sequence::type_id::create("w_burst_seq"); // Create Write Sequence
		r_drain_seq = fifo_r_drain_sequence::type_id::create("r_drain_seq"); // Create Read Sequence
		w_burst_stress_seq = fifo_w_burst_sequence::type_id::create("w_burst_stress_seq"); // Create Write Sequence
		r_drain_stress_seq = fifo_r_drain_sequence::type_id::create("r_drain_stress_seq"); // Create Read Sequence
		phase.raise_objection(this);			// RAISE OBJECTION: Dont stop simulation
		`uvm_info("TEST", "Starting FIFO Test...", UVM_LOW) // Log the Starting of FIFO test
		
		fork	// PHASE 1: PARALLEL EXECUTION: Run Sequences at the same time
			w_seq.start(env.w_sequencer); // Run Write Sequence inside the Environment
			r_seq.start(env.r_sequencer); // Run Read Sequence inside the Environment
		join
		// PHASE 2: burst until full
		`uvm_info("TEST","Writing burst to fill FIFO",UVM_LOW)
		fork
			w_burst_seq.start(env.w_sequencer); // Run Write burst Sequence inside the Environment
			begin
				wait(p_if.wfull === 1'b1); // wait until FIFO is full
				repeat(5) @(posedge p_if.wclk);
			end
		join_any
		disable fork;
		repeat(5) @(posedge p_if.rclk); // let wfull travel through syncronizers to read side  
		// PHASE 3: drain until hardware empties
		`uvm_info("TEST", "DRAINING FIFO to empty", UVM_LOW) 
		fork
			r_drain_seq.start(env.r_sequencer); // Run Read burst Sequence inside the Environment
			begin
				wait(p_if.rempty === 1'b1); // wait until FIFO is full
				repeat(5) @(posedge p_if.rclk);
			end
		join_any
		disable fork;
		repeat(5) @(posedge p_if.wclk); // let rempty travel through syncronizers to write side 
		// PHASE 4: RESET stress test
		fork
			w_burst_stress_seq.start(env.w_sequencer); // Run Write burst Sequence inside the Environment
			r_drain_stress_seq.start(env.r_sequencer); // Run Read burst Sequence inside the Environment
			begin	
				repeat(5) @(posedge p_if.wclk);
				p_if.wrst_n <= 1'b0; // Reset midtraffic
				p_if.rrst_n <= 1'b0; // Reset midtraffic
				repeat(2) @(posedge p_if.wclk);
				p_if.wrst_n <= 1'b1; // deassert Reset 
				p_if.rrst_n <= 1'b1; // deassert Reset 
			end
		join_any
		disable fork;
		`uvm_info("TEST", "Finishing FIFO Test... of both sequences", UVM_LOW)
		phase.drop_objection(this); // DROP OBJECTION: Allow the simulator to shut down
	endtask // finishes the simulation
endclass