`include "uvm_macros.svh"
import uvm_pkg::*;

class fifo_w_sequence extends uvm_sequence #(fifo_transaction); // BLUEPRINT: A sequence of transactions which the driver will push one by one
	`uvm_object_utils(fifo_w_sequence) // FACTORY: Register the Sequence so UVM can spawn it in the test
	fifo_transaction req; // Handle for transaction
	
	function new(string name = "fifo_w_sequence"); // CONSTUCTOR: Sequences are objects (without parents)
		super.new(name); // establish compunents name
	endfunction
	
	virtual task body(); // THE BODY: the main task
		repeat(40) begin // Create random transactions
			req = fifo_transaction::type_id::create("req"); // create blank transaction
			start_item(req); // Waits for Sequencers permission, when the Write Driver is ready for a transaction (at the rising edge)
			if(!req.randomize()) begin // GENERATION: Randomize the data
				`uvm_error("SEQ", "Randomization failed!") // if the randomized data can not satisfy the constaints
			end
			finish_item(req); // EXECUTION: Hand the Transaction to the Driver (arrived at rising edge) 
		end
	endtask
endclass