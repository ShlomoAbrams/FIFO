class fifo_r_sequence #(parameter DATA_WIDTH = 8) extends uvm_sequence #(fifo_transaction#(DATA_WIDTH));
	`uvm_object_param_utils(fifo_r_sequence#(DATA_WIDTH))
	fifo_transaction#(DATA_WIDTH) req; // Handle for transaction

	function new(string name = "fifo_r_sequence");
		super.new(name);
	endfunction
	
	virtual task body(); // THE BODY: the main task
		repeat(40) begin // Create 40 random transactions
			req = fifo_transaction#(DATA_WIDTH)::type_id::create("req"); // create blank transaction
			start_item(req); // Waits for Sequencer's permission, when the Read Driver is ready for a transaction (waits for rinc)
			if(!req.randomize()) begin // GENERATION: Randomize the data
				`uvm_error("SEQ", "Randomization failed!") // if the randomized data cannot satisfy the constraints
			end
			finish_item(req); // EXECUTION: Hand the Transaction to the Read Driver  
		end
	endtask
endclass	