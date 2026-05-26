`include "uvm_macros.svh"
import uvm_pkg::*;
class fifo_r_drain_sequence extends uvm_sequence #(fifo_transaction); // BLUEPRINT: A drain sequence of transactions which the driver will push one by one to fill fifo
	`uvm_object_utils(fifo_r_drain_sequence) // FACTORY: Register in UVM library 
	
	function new(string name = "fifo_r_drain_sequence"); // CONSTUCTOR: Sequences are objects (without parents)
		super.new(name); // establish compunents name
	endfunction
	
	virtual task body(); // THE BODY: the main task
		forever begin 
			fifo_transaction req; // Handle for transaction
			req = fifo_transaction::type_id::create("req");
			start_item(req);
			if(!req.randomize() with {en == 1'b1; delay == 0;}) begin // Create random transactions
				`uvm_error("SEQ", "drain randomization failed")
			end
			finish_item(req);
		end
	endtask
endclass
	