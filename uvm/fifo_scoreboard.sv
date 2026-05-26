`include "uvm_macros.svh"
import uvm_pkg::*;

`uvm_analysis_imp_decl(_write)	// DECLARATION: the Implementation Port has two "Inboxes"
`uvm_analysis_imp_decl(_read)	// Read Inbox

class fifo_scoreboard extends uvm_scoreboard;	// BLUEPRINT: Defines Scoreboard based on template
	`uvm_component_utils(fifo_scoreboard) 		// FACTORY: Register the Scoreboard in UVM library so it can be used later

	uvm_analysis_imp_write #(fifo_transaction, fifo_scoreboard) write_export; 	// Write inbox the transaction is dealt by the Scoreboard
	uvm_analysis_imp_read #(fifo_transaction, fifo_scoreboard) read_export;		// Read inbox the transaction is dealt by the Scoreboard
	logic [7:0] expected_queue[$];												// Que to store data entering fifo_scoreboard

	function new(string name, uvm_component parent);// CONSTRUCTOR: build the inboxes
		super.new(name, parent);					// establish compunents name and place in hierarchy 
		write_export = new("write_export", this);	// Create Write Inbox
		read_export = new("read_export",this);		// Create Read Inbox
	endfunction
	
	virtual function void write_write(fifo_transaction tr);	// When Write Monitor calls ap.write() store data
		expected_queue.push_back(tr.data); 					// store incoming data in the back of the queue
		`uvm_info("SCBD", $sformatf("Input Observed: %h. (Items in FIFO: %0d)", tr.data, expected_queue.size()), UVM_LOW) // Log input
	endfunction
	
	virtual function void write_read(fifo_transaction tr);	// When Read Monitor calls ap.write() 
		logic [7:0] expected_val; 							// stores data item exiting queue
		if (expected_queue.size() > 0) begin 				// check if we are exspecting data to come out
			expected_val = expected_queue.pop_front();		// Grab the oldest Item (First Out)
			if (tr.data === expected_val) begin				// Compared values are equal
				`uvm_info("SCBD", $sformatf("MATCH! Data: %h", tr.data), UVM_LOW)
			end else begin 									// Input doesnt equal output of FIFO
				`uvm_error("SCBD", $sformatf("MISMATCH! Expected: %h, Got: %h", expected_val, tr.data)) // Triggers test failure in UVM report.
			end	
		end else begin 
			`uvm_error("SCBD", "UNDERFLOW! Read occurred but Scorboard queue is empty!") // if the FIFO outputs data but the queue is empty (bug)
		end
	endfunction
endclass
			