class fifo_w_driver #(parameter DATA_WIDTH = 8) extends uvm_driver #(fifo_transaction#(DATA_WIDTH)); // Defines the "Write Worker" based on the UVM Driver template that handles "fifo_transaction" packets. 
	`uvm_component_param_utils(fifo_w_driver#(DATA_WIDTH)) // FACTORY: Register the driver in the UVM library so it can be dynamically constructed.
	virtual fifo_if #(DATA_WIDTH) vif; // The virtual interface is the software handle to the physical FIFO interface signals.

	function new(string name, uvm_component parent); // CONSTRUCTOR: Creates the write driver component.
		super.new(name, parent); // Establish component name and place in the testbench hierarchy.
	endfunction 

	virtual function void build_phase(uvm_phase phase); // BUILD PHASE: Runs at Time 0 to fetch configuration data before simulation starts
		super.build_phase(phase);
		if(!uvm_config_db#(virtual fifo_if#(DATA_WIDTH))::get(this, "","vif",vif)) begin 	// Reach into Database for the Virtual Interface
			`uvm_fatal("DRV", "Couldn't find virtual interface in config_db!")	// If "get" fails then there wasn't a Virtual Interface
		end
	endfunction

	virtual task run_phase(uvm_phase phase); // WORK SHIFT: this task runs for the duration of the simulation
		vif.w_d_cb.winc <= 1'b0; // Initialize to 0, so we don't write garbage to fifo in startup
		vif.w_d_cb.wdata <= '0; // Initialize to 0, so we write 0 as default value
		fork	
			forever begin // Thread 1: Drive transactions when reset is not active
				wait(vif.wrst_n === 1'b1); // Wait for reset to be released
				seq_item_port.get_next_item(req);	// HANDSHAKE: Ask sequencer (boss) for next piece of data to process
				drive_item(req); 					// EXECUTION: Translate the transaction object into actual high/low voltage bits
				seq_item_port.item_done(); 			// FEEDBACK: tell sequencer we finished so it can release next item
			end
			
			begin // Thread 2: Asynchronously reset outputs and log transitions.
				wait(vif.wrst_n === 1'b1); // Wait for initial reset release.
				`uvm_info("DRV", "Reset released, can write data", UVM_LOW)
				forever begin
					@(negedge vif.wrst_n);
					`uvm_info("DRV", "Reset asserted, clearing outputs", UVM_LOW)
					vif.w_d_cb.winc <= 1'b0; // Clear write enable.
					vif.w_d_cb.wdata <= '0; // Clear write data.
					@(posedge vif.wrst_n);
					`uvm_info("DRV", "Reset released, can write data", UVM_LOW)
				end
			end
		join
	endtask

	virtual task drive_item(fifo_transaction#(DATA_WIDTH) tr); // TRANSLATOR: Turns transaction fields into physical signal assertions.
		repeat (tr.delay) @(vif.w_d_cb); // STRESS TESTING: Wait for randomized delay to simulate varying traffic rates.
		
		if (tr.en) begin // if the transaction says "Write" drive winc & wdata
			vif.w_d_cb.winc <= 1'b1; 
			vif.w_d_cb.wdata <= tr.data; // transfer data from virtual to physical
			@(vif.w_d_cb); // wait for one clock block edge to execute write (it writes 1 step after edge)
			vif.w_d_cb.winc <= 1'b0; 	// Disable to prevent double write
		end
	endtask
endclass