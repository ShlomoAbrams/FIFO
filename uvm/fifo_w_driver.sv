class fifo_w_driver extends uvm_driver #(fifo_transaction); // Defines the "Write Worker" based on the UVM Driver template that handles "fifo_transaction" packets. 
	`uvm_component_utils(fifo_w_driver) // FACTORY: Register the driver in the UVM library so it can be dynamically constructed.
	virtual fifo_if vif; // The virtual interface is the software handle to the physical FIFO interface signals.

	function new(string name, uvm_component parent); // CONSTRUCTOR: Creates the write driver component.
		super.new(name, parent); // Establish component name and place in the testbench hierarchy.
	endfunction 

	virtual function void build_phase(uvm_phase phase); // BUILD PHASE: Fetch configuration database information before simulation starts.
		super.build_phase(phase);
		if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin // Retrieve the Virtual Interface from the database.
			`uvm_fatal("DRV", "Couldn't find virtual interface in config_db!") // Fatal error if the interface is missing.
		end
	endfunction

	virtual task run_phase(uvm_phase phase); // WORK SHIFT: This task runs for the duration of the simulation.
		vif.w_d_cb.winc <= 1'b0; // Initialize to 0, so we don't perform invalid writes to FIFO at startup.
		vif.w_d_cb.wdata <= 8'h00; // Initialize to 0, so we write 0 as default value.
		fork	
			forever begin // Thread 1: Drive transactions when reset is not active.
				wait(vif.wrst_n === 1'b1); // Wait for write reset to be released.
				seq_item_port.get_next_item(req); // HANDSHAKE: Get the next transaction item from the sequencer.
				drive_item(req); // EXECUTION: Drive the physical pins based on transaction configuration.
				seq_item_port.item_done(); // FEEDBACK: Complete handshake with the sequencer.
			end
			
			begin // Thread 2: Asynchronously reset outputs and log transitions.
				wait(vif.wrst_n === 1'b1); // Wait for initial reset release.
				`uvm_info("DRV", "Reset released, can write data", UVM_LOW)
				forever begin
					@(negedge vif.wrst_n);
					`uvm_info("DRV", "Reset asserted, clearing outputs", UVM_LOW)
					vif.w_d_cb.winc <= 1'b0; // Clear write enable.
					vif.w_d_cb.wdata <= 8'h00; // Clear write data.
					@(posedge vif.wrst_n);
					`uvm_info("DRV", "Reset released, can write data", UVM_LOW)
				end
			end
		join
	endtask

	virtual task drive_item(fifo_transaction tr); // TRANSLATOR: Turns transaction fields into physical signal assertions.
		repeat (tr.delay) @(vif.w_d_cb); // STRESS TESTING: Wait for randomized delay to simulate varying traffic rates.
		
		if (tr.en) begin // If the transaction represents a valid write operation, enable write control and data.
			vif.w_d_cb.winc <= 1'b1; 
			vif.w_d_cb.wdata <= tr.data; // Transfer data from virtual to physical wires.
			@(vif.w_d_cb); // Wait for the clock edge to register the write.
			vif.w_d_cb.winc <= 1'b0; // Deassert write increment to prevent double writes.
		end
	endtask
endclass