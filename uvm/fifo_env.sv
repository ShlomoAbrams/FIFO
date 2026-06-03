class fifo_env extends uvm_env; 	// BLUEPRINT: top level container for all the verification components
	`uvm_component_utils(fifo_env)	// FACTORY: Register the Environment so UVM can spawn it in the test
	fifo_w_agent w_agent; // HANDLE: write agent
	fifo_r_agent r_agent; // HANDLE: read agent
	fifo_scoreboard scoreboard; // HANDLE: scoreboard
	
	function new (string name, uvm_component parent); // CONSTRUCTOR: Links this component into the UVM hierarchy tree
		super.new(name, parent); // establish component's name and hierarchy place 
	endfunction
	
	virtual function void build_phase(uvm_phase phase); // BUILD PHASE: builds components from top down
		super.build_phase(phase); // Executes background UVM library setup
		w_agent = fifo_w_agent::type_id::create("w_agent", this); // spawn write agent in hierarchy
		r_agent = fifo_r_agent::type_id::create("r_agent", this); // spawn read agent in hierarchy
		scoreboard = fifo_scoreboard::type_id::create("scoreboard", this); // spawn scoreboard
	endfunction
	
	virtual function void connect_phase(uvm_phase phase); // CONNECT PHASE: connect components
		super.connect_phase(phase);
		w_agent.ap.connect(scoreboard.write_export); // Connect the write agent's analysis port to the Scoreboard's Write Inbox
		r_agent.ap.connect(scoreboard.read_export);  // Connect the read agent's analysis port to the Scoreboard's Read Inbox
	endfunction
endclass