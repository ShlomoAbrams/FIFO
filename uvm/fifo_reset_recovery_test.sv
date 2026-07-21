class fifo_reset_recovery_test #(parameter DATA_WIDTH = 8) extends fifo_test#(DATA_WIDTH); // BLUEPRINT: Test case focusing on verifying reset recovery behavior mid-traffic
	`uvm_component_param_utils(fifo_reset_recovery_test#(DATA_WIDTH)) // FACTORY: Register the test case in UVM library so it can be dynamically spawned

	function new(string name, uvm_component parent); // CONSTRUCTOR: Links the test component into the UVM hierarchy tree
		super.new(name, parent);
	endfunction

	virtual task run_phase(uvm_phase phase); // RUN PHASE: Main verification execution thread
		// DECLARATIONS: Handles for pre-reset and post-reset transaction sequences
		fifo_w_burst_sequence#(DATA_WIDTH) w_burst_stress_seq;		// Create Write Burst Sequence handles
		fifo_r_drain_sequence#(DATA_WIDTH) r_drain_stress_seq;		// Create Read Drain Sequence handles
		fifo_w_burst_sequence#(DATA_WIDTH) w_post_reset_seq;			// Create Write Burst Sequence handles
		fifo_r_drain_sequence#(DATA_WIDTH) r_post_reset_seq;			// Create Read Drain Sequence handles

		// COMPONENT CREATION: Spawn sequence instances using the UVM factory
		w_burst_stress_seq = fifo_w_burst_sequence#(DATA_WIDTH)::type_id::create("w_burst_stress_seq");	// Create Write Burst Sequence
		r_drain_stress_seq = fifo_r_drain_sequence#(DATA_WIDTH)::type_id::create("r_drain_stress_seq");	// Create Read Drain Sequence
		w_post_reset_seq = fifo_w_burst_sequence#(DATA_WIDTH)::type_id::create("w_post_reset_seq");		// Create Write Burst Sequence
		r_post_reset_seq = fifo_r_drain_sequence#(DATA_WIDTH)::type_id::create("r_post_reset_seq");		// Create Read Drain Sequence

		phase.raise_objection(this); // RAISE OBJECTION: Keep simulation running for our verification flow
		`uvm_info("RESET_TEST", "Starting FIFO Reset Recovery Test...", UVM_LOW) // Log the Starting of FIFO test

		// PHASE 1: PRE-RESET TRAFFIC SPREE
		`uvm_info("RESET_TEST", "Starting active traffic pre-reset...", UVM_LOW) // Log the Starting of active traffic pre-reset
		fork
			w_burst_stress_seq.start(env.w_agent.w_sequencer); // Start active write stream to stress memory
			r_drain_stress_seq.start(env.r_agent.r_sequencer); // Start active read stream to empty memory
		join_none // Run sequences in parallel as background threads 

		
		repeat(50) @(posedge p_if.wclk); // Wait for active traffic to perform multiple reads and writes
		`uvm_info("RESET_TEST", "Asserting reset mid-traffic...", UVM_LOW) // After 10 clock cycles assert reset

		// PHASE 2: ASYNCHRONOUS RESET ASSERTION MID-TRAFFIC
		p_if.wrst_n <= 1'b0; // Assert write clock domain reset pin
		p_if.rrst_n <= 1'b0; // Assert read clock domain reset pin

		// Keep reset pins low for 5 clock periods to test reset hold safety
		repeat(5) @(posedge p_if.wclk);

		// PHASE 3: DE-ASSERT RESET
		`uvm_info("RESET_TEST", "De-asserting reset...", UVM_LOW) // Log the de-assertion of reset
		p_if.wrst_n <= 1'b1; // De-assert write clock domain reset
		p_if.rrst_n <= 1'b1; // De-assert read clock domain reset

		// Cleanly notify pre-reset sequences to complete their current loops
		w_burst_stress_seq.stop_seq = 1; // Stop pre-reset write sequence
		r_drain_stress_seq.stop_seq = 1; // Stop pre-reset read sequence

		repeat(50) @(posedge p_if.wclk); // Wait for the background sequence threads to terminate cleanly

		// PHASE 4: POST-RESET DATA VERIFICATION (Verify pointers and scoreboard recovered cleanly)
		`uvm_info("RESET_TEST", "Starting post-reset traffic to verify recovery...", UVM_LOW) // Log the start of post-reset traffic
		fork
			w_post_reset_seq.start(env.w_agent.w_sequencer); // Write post-reset data packets
			begin
				wait(p_if.wfull === 1'b1); // Wait until FIFO is full to test bounds recovery
				repeat(5) @(posedge p_if.wclk);
				w_post_reset_seq.stop_seq = 1; // Stop post-reset write sequence
			end
		join
		
		repeat(5) @(posedge p_if.rclk);	// Let wfull flag travel through CDC synchronizers to read side


		// PHASE 5: DRAIN POST-RESET DATA (Verify scoreboard matches all post-reset transactions)
		`uvm_info("RESET_TEST", "Draining FIFO post-reset...", UVM_LOW)
		fork
			r_post_reset_seq.start(env.r_agent.r_sequencer); // Read all data packets post-reset
			begin
				wait(p_if.rempty === 1'b1); // Wait until FIFO is completely empty
				repeat(5) @(posedge p_if.rclk);
				r_post_reset_seq.stop_seq = 1; // Stop post-reset read sequence
			end
		join

		repeat(5) @(posedge p_if.wclk); 		// Let empty flag travel through CDC synchronizers to write side

		`uvm_info("RESET_TEST", "FIFO Reset Recovery Test finished successfully!", UVM_LOW)
		phase.drop_objection(this); // DROP OBJECTION: Let simulation complete
	endtask
endclass
