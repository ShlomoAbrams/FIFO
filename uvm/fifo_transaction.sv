`include "uvm_macros.svh"
import uvm_pkg::*;

class fifo_transaction extends uvm_sequence_item; // BLUEPRINT: defines fifo_transaction using UVM sequence item template
	rand logic [7:0] data;	// CREATE VARIABLES: Transaction Data can be randomized
	rand int delay;			// Clock cycles before driving Data
	rand bit en;			// Is this a valid operation
	
	`uvm_object_utils_begin(fifo_transaction) // UVM MACROS: tells the UVM how to handle the variables
		`uvm_field_int(data, UVM_ALL_ON)		// resister variables, gives functions like compare() print() copy()
		`uvm_field_int(delay, UVM_ALL_ON)
		`uvm_field_int(en, UVM_ALL_ON)
	`uvm_object_utils_end
	
	function new(string name = "fifo_transaction");	// CONSTRUCTOR: Links this component into the UVM hierarchy tree
		super.new(name); 							// establish compunents name and place in hierarchy 
	endfunction
	
	constraint delay_limit {delay inside {[0:5]}; } // CONSTRAINT: keep the delay short between 0 and 10 cycles
	constraint en_bias { en dist {1 := 90, 0:=10}; } // CONTRRAINT: "en" is 90% of the time 1
endclass