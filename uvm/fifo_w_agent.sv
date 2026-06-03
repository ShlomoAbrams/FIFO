class fifo_w_agent extends uvm_agent; // Defines "Write Agent" to group Write Sequencer, Driver, and Monitor
	`uvm_component_utils(fifo_w_agent) // FACTORY: Register the agent in UVM library 
	
    fifo_w_driver w_driver; // write driver handle
    fifo_w_monitor w_monitor; // write monitor handle
    uvm_sequencer #(fifo_transaction) w_sequencer; // write sequencer handle

    uvm_analysis_port #(fifo_transaction) ap; // BROADCAST PORT: Sends data to the Scoreboard

	function new(string name, uvm_component parent); // CONSTRUCTOR: creates agent
		super.new(name, parent); // establish components name and place in hierarchy 
	endfunction 

	virtual function void build_phase(uvm_phase phase); // BUILD PHASE: Runs at Time 0 to fetch configuration data before simulation starts
		super.build_phase(phase);
		ap = new("ap", this); // Create the analysis port
        w_monitor = fifo_w_monitor::type_id::create("w_monitor", this); // Create Write Monitor
        if(get_is_active() == UVM_ACTIVE) begin
            w_driver = fifo_w_driver::type_id::create("w_driver",this); // Create Write Driver
            w_sequencer = uvm_sequencer#(fifo_transaction)::type_id::create("w_sequencer",this); // Create Write Sequencer
		end
	endfunction

    virtual function void connect_phase(uvm_phase phase); // Connect Phase: Connect components
        super.connect_phase(phase); // Runs connection for agent
        w_monitor.ap.connect(ap); // Connect monitor broadcast port to agent broadcast port
        if(get_is_active() == UVM_ACTIVE) begin
            w_driver.seq_item_port.connect(w_sequencer.seq_item_export); // Connect driver item port to sequencer item port
        end
    endfunction
endclass