class fifo_w_monitor extends uvm_monitor; // BLUEPRINT: Defines Write Monitor based on template
	`uvm_component_utils(fifo_w_monitor) // FACTORY: Register the Monitor in UVM library so it can be used later
	virtual fifo_if vif;  // the "Virtual" Interface is the software handle to the physical fifo interface
	
	uvm_analysis_port #(fifo_transaction) ap; // BROADCAST PORT: sends data to the Scoreboard
	
	function new( string name, uvm_component parent); // CONSTRUCTOR: Creates the component and initializes the Broadcaster ap
		super.new(name, parent); // establish component's name and place in hierarchy 
		ap = new("ap", this); // create the port so it exists as soon as the testbench starts
	endfunction
	
	virtual function void build_phase(uvm_phase phase); // BUILD PHASE: Fetch configuration database information before simulation starts.
		super.build_phase(phase);
		if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin // Retrieve the Virtual Interface from the database.
			`uvm_fatal("MON", "Couldn't find virtual interface in config_db!") // Fatal error if the interface is missing.
		end
	endfunction	
	
	virtual task run_phase(uvm_phase phase); // WORK SHIFT: Watches the wires for the duration of the simulation
		fifo_transaction tr; // HANDLE: create a pointer that can point to transaction object
		forever begin
			@(vif.w_m_cb); // wait for clock edge
			if (vif.w_m_cb.wclken_wire === 1'b1 && vif.wrst_n === 1'b1) begin // Record if Write is Enabled and not in reset.
				tr = fifo_transaction::type_id::create("tr"); // create a new transaction object named "tr" to sample the data onto
				tr.data = vif.w_m_cb.wdata; // SAMPLING: Record data seen on physical wires to software object
				ap.write(tr); // BROADCAST: Send note to the Scoreboard
				`uvm_info("MON", $sformatf("Observe WRITE: Data=%h", tr.data), UVM_MEDIUM) // LOGGING: print message to console to see Monitoring
			end
		end
	endtask
endclass