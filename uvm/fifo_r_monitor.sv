class fifo_r_monitor #(parameter DATA_WIDTH = 8) extends uvm_monitor; // BLUEPRINT: Defines Read Monitor based on template
	`uvm_component_param_utils(fifo_r_monitor#(DATA_WIDTH)) // FACTORY: Register the Monitor in UVM library so it can be used later
	virtual fifo_if #(DATA_WIDTH) vif;  // the "Virtual" Interface is the software handle to the physical fifo interface
	
	uvm_analysis_port #(fifo_transaction#(DATA_WIDTH)) ap; // BROADCAST PORT: sends data to the Scoreboard
	
	function new( string name, uvm_component parent); // CONSTRUCTOR: Creates the component and initializes the Broadcaster ap
		super.new(name, parent); // establish component's name and place in hierarchy 
		ap = new("ap", this); // create the port so it exists as soon as the testbench starts
	endfunction
	
	virtual function void build_phase(uvm_phase phase); // BUILD PHASE: Fetch configuration database information before simulation starts.
		super.build_phase(phase);
		if(!uvm_config_db#(virtual fifo_if#(DATA_WIDTH))::get(this, "", "vif", vif)) begin // Retrieve the Virtual Interface from the database.
			`uvm_fatal("MON", "Couldn't find virtual interface in config_db!") // Fatal error if the interface is missing.
		end
	endfunction
	
	virtual task run_phase(uvm_phase phase); // WORK SHIFT: Watches the wires for the duration of the simulation
		fifo_transaction#(DATA_WIDTH) tr; // HANDLE: create a pointer that can point to transaction object
		bit read_in_progress = 0; // Declaration: previous request to read
		wait(vif.rrst_n === 1'b1); // Initialize: wait for reset to go high before starting
		forever begin
			@(vif.r_m_cb); // wait for clock edge
			if (read_in_progress === 1'b1 && vif.rrst_n === 1'b1) begin // Record if Read is Enabled last cycle and not in reset.
				tr = fifo_transaction#(DATA_WIDTH)::type_id::create("tr"); // create a new transaction object named "tr" to sample the data onto
				tr.data = vif.r_m_cb.rdata; // SAMPLING: Record data seen on physical wires to software object
				ap.write(tr); // BROADCAST: Send note to the Scoreboard
				`uvm_info("MON", $sformatf("Observe READ: Data=%h", tr.data), UVM_MEDIUM) // LOGGING: print message to console to see Monitoring
			end
			read_in_progress = (vif.r_m_cb.rclken_wire === 1'b1 && vif.rrst_n === 1'b1); // Check if read is enabled and not in reset to trigger sample next cycle.
		end
	endtask
endclass