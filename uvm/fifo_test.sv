class fifo_test #(parameter DATA_WIDTH = 8) extends uvm_test; // BLUEPRINT: The Test Defines specific scenario for this run
	`uvm_component_param_utils(fifo_test#(DATA_WIDTH)) // FACTORY: Register the Test so UVM can spawn it in the top file
	fifo_env#(DATA_WIDTH) env; 			// DECLARATION: Handle for environment
	virtual fifo_if#(DATA_WIDTH) p_if; 	// Handle for interface signals 
	
	function new(string name, uvm_component parent); // CONSTRUCTOR: Links this component into the UVM hierarchy tree
		super.new(name, parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase); 
		super.build_phase(phase);
		env = fifo_env#(DATA_WIDTH)::type_id::create("env", this); // COMPONENT CREATION: spawning environment using the factory
		if(!uvm_config_db#(virtual fifo_if#(DATA_WIDTH))::get(this, "", "vif", p_if)) begin // Retrieve the interface from database
			`uvm_fatal("TEST", "Virtual interface not found in config_db")
		end
		uvm_top.set_timeout(1ms);			// The simulation cannot exceed this limit
	endfunction
	
	virtual task run_phase(uvm_phase phase); // RUN PHASE:
		fifo_w_sequence#(DATA_WIDTH) w_seq; 					// Create Write Sequence Handle
		fifo_r_sequence#(DATA_WIDTH) r_seq;					// Create Read Sequence Handle
		fifo_w_burst_sequence#(DATA_WIDTH) w_burst_seq, w_burst_stress_seq; 	// Create Write Burst Sequence handles
		fifo_r_drain_sequence#(DATA_WIDTH) r_drain_seq, r_drain_stress_seq;	// Create Read Drain Sequence handles
		w_seq = fifo_w_sequence#(DATA_WIDTH)::type_id::create("w_seq"); // Create Write Sequence
		r_seq = fifo_r_sequence#(DATA_WIDTH)::type_id::create("r_seq"); // Create Read Sequence
		w_burst_seq = fifo_w_burst_sequence#(DATA_WIDTH)::type_id::create("w_burst_seq"); // Create Write Burst Sequence
		r_drain_seq = fifo_r_drain_sequence#(DATA_WIDTH)::type_id::create("r_drain_seq"); // Create Read Drain Sequence
		w_burst_stress_seq = fifo_w_burst_sequence#(DATA_WIDTH)::type_id::create("w_burst_stress_seq"); // Create Write Burst Stress Sequence
		r_drain_stress_seq = fifo_r_drain_sequence#(DATA_WIDTH)::type_id::create("r_drain_stress_seq"); // Create Read Drain Stress Sequence
		
		
		phase.raise_objection(this);			// RAISE OBJECTION: Don't stop simulation
		`uvm_info("TEST", "Starting FIFO Test...", UVM_LOW) // Log the Starting of FIFO test
		
		fork	// PHASE 1: PARALLEL EXECUTION: Run Sequences at the same time
			w_seq.start(env.w_agent.w_sequencer); // Run Write Sequence inside the Agent
			r_seq.start(env.r_agent.r_sequencer); // Run Read Sequence inside the Agent
		join
		// PHASE 2: burst until full
		`uvm_info("TEST","Writing burst to fill FIFO",UVM_LOW)
		fork
			w_burst_seq.start(env.w_agent.w_sequencer); // Run Write burst Sequence inside the Agent
			begin
				wait(p_if.wfull === 1'b1); // wait until FIFO is full
				repeat(5) @(posedge p_if.wclk);
				w_burst_seq.stop_seq = 1; // Stop sequence 
			end
		join
		repeat(5) @(posedge p_if.rclk); // let wfull travel through synchronizers to read side  
		// PHASE 3: drain until hardware empties
		`uvm_info("TEST", "DRAINING FIFO to empty", UVM_LOW) 
		fork
			r_drain_seq.start(env.r_agent.r_sequencer); // Run Read burst Sequence inside the Agent
			begin
				wait(p_if.rempty === 1'b1); // wait until FIFO is empty
				repeat(5) @(posedge p_if.rclk);
				r_drain_seq.stop_seq = 1; // Stop sequence cleanly
			end
		join
		repeat(5) @(posedge p_if.wclk); // let rempty travel through synchronizers to write side 
		// PHASE 4: RESET stress test
		fork
			w_burst_stress_seq.start(env.w_agent.w_sequencer); // Run Write burst Sequence inside the Agent
			r_drain_stress_seq.start(env.r_agent.r_sequencer); // Run Read burst Sequence inside the Agent
			begin	
				repeat(5) @(posedge p_if.wclk);
				p_if.wrst_n <= 1'b0; // Reset mid-traffic
				p_if.rrst_n <= 1'b0; // Reset mid-traffic
				repeat(2) @(posedge p_if.wclk);
				p_if.wrst_n <= 1'b1; // deassert Reset 
				p_if.rrst_n <= 1'b1; // deassert Reset 
				repeat(5) @(posedge p_if.wclk);
				w_burst_stress_seq.stop_seq = 1; // Stop write sequence cleanly
				r_drain_stress_seq.stop_seq = 1; // Stop read sequence cleanly
			end
		join
		`uvm_info("TEST", "Finishing FIFO Test... of both sequences", UVM_LOW)
		phase.drop_objection(this); // DROP OBJECTION: Allow the simulator to shut down
	endtask // finishes the simulation
endclass