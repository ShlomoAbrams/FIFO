class fifo_w_sequence #(parameter DATA_WIDTH = 8) extends uvm_sequence #(fifo_transaction#(DATA_WIDTH)); // BLUEPRINT: A sequence of transactions which the driver will push one by one
	`uvm_object_param_utils(fifo_w_sequence#(DATA_WIDTH)) // FACTORY: Register the Sequence so UVM can spawn it in the test
	fifo_transaction#(DATA_WIDTH) req; // Handle for transaction
	
	function new(string name = "fifo_w_sequence"); // CONSTRUCTOR: Sequences are objects (without parents)
		super.new(name); // establish component's name
	endfunction
	
	virtual task body(); // THE BODY: the main task
		repeat(40) begin // Create random transactions
			req = fifo_transaction#(DATA_WIDTH)::type_id::create("req"); // create blank transaction
			start_item(req); // Waits for Sequencer's permission, when the Write Driver is ready for a transaction (at the rising edge)
			if(!req.randomize()) begin // GENERATION: Randomize the data
				`uvm_error("SEQ", "Randomization failed!") // if the randomized data cannot satisfy the constraints
			end
			finish_item(req); // EXECUTION: Hand the Transaction to the Driver (arrived at rising edge) 
		end
	endtask
endclass