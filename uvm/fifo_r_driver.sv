class fifo_r_driver extends uvm_driver #(fifo_transaction); // Defines the "Read Worker" based on the UVM Driver template that handles "fifo_transaction" packets.
	`uvm_component_utils(fifo_r_driver) // FACTORY: Register the driver in the UVM library so it can be dynamically constructed.
	virtual fifo_if vif; // The virtual interface is the software handle to the physical FIFO interface signals.

	function new(string name, uvm_component parent); // CONSTRUCTOR: creates worker
		super.new(name, parent); // establish components name and place in hierarchy 
	endfunction 
	
	virtual function void build_phase(uvm_phase phase); // BUILD PHASE: Runs at Time 0 to fetch configuration data before simulation starts
		super.build_phase(phase);
		if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin // Retrieve the Virtual Interface from the database.
			`uvm_fatal("DRV", "Couldn't find virtual interface in config_db!") // Fatal error if the interface is missing.
		end
	endfunction

	virtual task run_phase(uvm_phase phase); // WORK SHIFT: This task runs for the duration of the simulation.
		vif.r_d_cb.rinc <= 1'b0; // Initialize to 0, so we don't perform invalid reads from FIFO at startup.
		fork
			forever begin 			// Thread 1: Drive transactions when reset is not active.
				wait(vif.rrst_n === 1'b1); // Wait for reset to be released
				seq_item_port.get_next_item(req); // HANDSHAKE: Ask sequencer (boss) for the request that contains the next transaction
				drive_item(req); // EXECUTION: Translate the transaction object into actual high/low voltage bits
				seq_item_port.item_done(); // FEEDBACK: tell sequencer we finished so it can release next item
			end
			// Thread 2: Asynchronously reset outputs and log transitions.
			begin
				wait(vif.rrst_n === 1'b1); // Wait for initial reset release
				`uvm_info("DRV", "Reset released, can read data", UVM_LOW)
				forever begin
					@(negedge vif.rrst_n);
					`uvm_info("DRV", "Reset asserted, clearing outputs", UVM_LOW)
					vif.r_d_cb.rinc <= 1'b0; // Clear read enable
					@(posedge vif.rrst_n);
					`uvm_info("DRV", "Reset released, can read data", UVM_LOW)
				end
			end
		join
	endtask

	virtual task drive_item(fifo_transaction tr); // TRANSLATOR: Task that turns software into hardware reality.
		repeat (tr.delay) @(vif.r_d_cb); // STRESS TESTING: wait for randomized delay to simulate slow or fast traffic
		
		if (tr.en) begin // if the transaction says "read" drive rinc
			vif.r_d_cb.rinc <= 1'b1; // READ PROTOCOL: turn rinc high
			@(vif.r_d_cb); // wait for one clock block edge to execute read (it reads 1 step after edge)
			vif.r_d_cb.rinc <= 1'b0; 	// Disable to prevent double read
		end
	endtask
endclass