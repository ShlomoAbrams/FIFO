`uvm_analysis_imp_decl(_write)	// DECLARATION: The Implementation Port has two "Inboxes"
`uvm_analysis_imp_decl(_read)	// Read Inbox

class fifo_scoreboard extends uvm_scoreboard;	// BLUEPRINT: Defines the Scoreboard based on template.
	`uvm_component_utils(fifo_scoreboard) 		// FACTORY: Register the Scoreboard in UVM library.

	uvm_analysis_imp_write #(fifo_transaction, fifo_scoreboard) write_export; 	// Write inbox: transaction is handled by the Scoreboard.
	uvm_analysis_imp_read #(fifo_transaction, fifo_scoreboard) read_export;		// Read inbox: transaction is handled by the Scoreboard.
	logic [7:0] expected_queue[$];												// Queue to store data entering fifo_scoreboard.
	virtual fifo_if vif;                                                        // Virtual interface to monitor reset signals.

	function new(string name, uvm_component parent);// CONSTRUCTOR: Builds the inbox exports.
		super.new(name, parent);					// Establish component's name and place in hierarchy.
		write_export = new("write_export", this);	// Create Write Inbox.
		read_export = new("read_export", this);		// Create Read Inbox.
	endfunction

	virtual function void build_phase(uvm_phase phase); // BUILD PHASE: Fetch configuration database information before simulation starts.
		super.build_phase(phase);
		if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin // Fetch the virtual interface.
			`uvm_fatal("SCBD", "Couldn't find virtual interface in config_db!")
		end
	endfunction

	virtual task run_phase(uvm_phase phase); // RUN PHASE: if reset signals are active delete the queue
		forever begin
			@(negedge vif.wrst_n or negedge vif.rrst_n); // if a reset is detected 
			expected_queue.delete(); // delete the queue
			`uvm_info("SCBD", "Reset detected! Scoreboard queue cleared.", UVM_LOW)
		end
	endtask
	
	virtual function void write_write(fifo_transaction tr);	// When Write Monitor calls ap.write() store data
		if (vif.wrst_n === 1'b0) begin
			return; // Ignore writes during reset.
		end
		expected_queue.push_back(tr.data); 					// store incoming data in the back of the queue
		`uvm_info("SCBD", $sformatf("Input Observed: %h. (Items in FIFO: %0d)", tr.data, expected_queue.size()), UVM_LOW) // Log input

	endfunction
	
	virtual function void write_read(fifo_transaction tr);	// When Read Monitor calls ap.write() 
		logic [7:0] expected_val; 							// stores data item exiting queue
		if (vif.rrst_n === 1'b0) begin
			return; // Ignore reads during reset.
		end
		if (expected_queue.size() > 0) begin 				// check if we are expecting data to come out
			expected_val = expected_queue.pop_front();		// Grab the oldest Item (First Out)
			if (tr.data === expected_val) begin				// Compared values are equal
				`uvm_info("SCBD", $sformatf("MATCH! Data: %h.    (Items in FIFO: %0d)", tr.data, expected_queue.size()), UVM_LOW)
			end else begin 									// Input doesn't equal output of FIFO
				`uvm_error("SCBD", $sformatf("MISMATCH! Expected: %h, Got: %h", expected_val, tr.data)) // Triggers test failure in UVM report.
			end	
		end else begin 
			`uvm_error("SCBD", "UNDERFLOW! Read occurred but Scoreboard queue is empty!") // if the FIFO outputs data but the queue is empty (bug)
		end
	endfunction
endclass