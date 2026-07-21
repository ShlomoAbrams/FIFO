class fifo_transaction #(parameter DATA_WIDTH = 8) extends uvm_sequence_item; // BLUEPRINT: defines fifo_transaction using UVM sequence item template
	rand logic [DATA_WIDTH-1:0] data;	// CREATE VARIABLES: Transaction Data can be randomized
	rand int delay;			// Clock cycles before driving Data
	rand bit en;			// Is this a valid operation
	
	`uvm_object_param_utils_begin(fifo_transaction#(DATA_WIDTH)) // UVM MACROS: tells the UVM how to handle the variables
		`uvm_field_int(data, UVM_ALL_ON)		// register variables, gives functions like compare() print() copy()
		`uvm_field_int(delay, UVM_ALL_ON)
		`uvm_field_int(en, UVM_ALL_ON)
	`uvm_object_utils_end
	
	function new(string name = "fifo_transaction");	// CONSTRUCTOR: Links this component into the UVM hierarchy tree
		super.new(name); 							// establish component's name
	endfunction
	
	constraint delay_limit {delay inside {[0:5]}; } // CONSTRAINT: keep the delay short between 0 and 5 cycles
	constraint en_bias { en dist {1 := 90, 0:=10}; } // CONSTRAINT: "en" is 90% of the time 1
endclass