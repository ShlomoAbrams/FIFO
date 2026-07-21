class fifo_w_burst_sequence #(parameter DATA_WIDTH = 8) extends uvm_sequence #(fifo_transaction#(DATA_WIDTH)); // BLUEPRINT: A burst sequence of transactions which the driver will push one by one to fill fifo
	`uvm_object_param_utils(fifo_w_burst_sequence#(DATA_WIDTH)) // FACTORY: Register in UVM library 
	bit stop_seq = 0; // Control flag to stop sequence cleanly

	function new(string name = "fifo_w_burst_sequence"); // CONSTRUCTOR: Sequences are objects (without parents)
		super.new(name); // establish component's name
	endfunction

	virtual task body(); // THE BODY: the main task

		while (!stop_seq) begin 
			fifo_transaction#(DATA_WIDTH) req; // Handle for transaction
			req = fifo_transaction#(DATA_WIDTH)::type_id::create("req");
			start_item(req);
			if(!req.randomize() with {en == 1'b1; delay == 0;}) begin // Create random transactions
				`uvm_error("SEQ", "BURST randomization failed")
			end
			finish_item(req);
		end
	endtask
endclass