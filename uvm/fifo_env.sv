`include "uvm_macros.svh"
import uvm_pkg::*;
class fifo_env extends uvm_env; 	// BLUEPRINT: top level container for all the verification components
	`uvm_component_utils(fifo_env)	// FACTORY: Register the Environment so UVM can spawn it in the test
	
	fifo_w_driver w_driver; // HANDLES: Pointers for the Components.
	fifo_r_driver r_driver;
	fifo_w_monitor w_monitor;
	fifo_r_monitor r_monitor;
	fifo_scoreboard scoreboard;
	
	uvm_sequencer #(fifo_transaction) w_sequencer; // Handle for write sequencer
	uvm_sequencer #(fifo_transaction) r_sequencer; // Handle for read sequencer
	function new (string name, uvm_component parent); // CONSTRUCTOR: Links this component into the UVM hierarchy tree
		super.new(name, parent); // establish compunents name and hierarchy place 
	endfunction
	
	virtual function void build_phase(uvm_phase phase); // BUILD PHASE: builts components from top down
		super.build_phase(phase); // Executes backround UVM library setup
		w_driver = fifo_w_driver::type_id::create("w_driver", this); // spawn component in hierarchy
		r_driver = fifo_r_driver::type_id::create("r_driver", this);
		w_monitor = fifo_w_monitor::type_id::create("w_monitor", this);
		r_monitor = fifo_r_monitor::type_id::create("r_monitor", this);
		scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);
		w_sequencer = uvm_sequencer#(fifo_transaction)::type_id::create("w_sequencer", this); // Spawn sequence
		r_sequencer = uvm_sequencer#(fifo_transaction)::type_id::create("r_sequencer", this); // Spawn sequence
	endfunction
	
	virtual function void connect_phase(uvm_phase phase); // CONNECT PHASE: connect components
		super.connect_phase(phase);
		w_monitor.ap.connect(scoreboard.write_export); // Connect the write monitor "radio station" (ap) to the Scoreboard's Write Inbox (write_export)
		r_monitor.ap.connect(scoreboard.read_export); // Connect the read monitor "radio station" (ap) to the Scoreboard's Read Inbox (read_export)
		w_driver.seq_item_port.connect(w_sequencer.seq_item_export); // Connect the Drivers "Port" to the Sequencers "Export"
		r_driver.seq_item_port.connect(r_sequencer.seq_item_export); // Connect the Drivers "Port" to the Sequencers "Export"
	endfunction
endclass