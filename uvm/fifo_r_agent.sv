class fifo_r_agent #(parameter DATA_WIDTH = 8) extends uvm_agent; // Defines "Read Agent" to group Read Sequencer, Driver, and Monitor
	`uvm_component_param_utils(fifo_r_agent#(DATA_WIDTH)) // FACTORY: Register the agent in UVM library 
	
    fifo_r_driver#(DATA_WIDTH) r_driver; // read driver handle
    fifo_r_monitor#(DATA_WIDTH) r_monitor; // read monitor handle
    uvm_sequencer #(fifo_transaction#(DATA_WIDTH)) r_sequencer; // read sequencer handle
    uvm_analysis_port #(fifo_transaction#(DATA_WIDTH)) ap; // BROADCAST PORT: Sends data to the Scoreboard

	function new(string name, uvm_component parent); // CONSTRUCTOR: creates agent
		super.new(name, parent); // establish components name and place in hierarchy 
	endfunction 

	virtual function void build_phase(uvm_phase phase); // BUILD PHASE: Runs at Time 0 to fetch configuration data before simulation starts
		super.build_phase(phase);
		ap = new("ap", this); // Create the analysis port
        r_monitor = fifo_r_monitor#(DATA_WIDTH)::type_id::create("r_monitor", this); // Create Read Monitor
        if(get_is_active() == UVM_ACTIVE) begin
            r_driver = fifo_r_driver#(DATA_WIDTH)::type_id::create("r_driver",this); // Create Read Driver
            r_sequencer = uvm_sequencer#(fifo_transaction#(DATA_WIDTH))::type_id::create("r_sequencer",this); // Create Read Sequencer
		end
	endfunction

    virtual function void connect_phase(uvm_phase phase); // Connect Phase: conneect components
        super.connect_phase(phase); // runs connection for agent
        r_monitor.ap.connect(ap); // connect monitor broadcast port to agent broadcast port
        if(get_is_active() == UVM_ACTIVE) begin
            r_driver.seq_item_port.connect(r_sequencer.seq_item_export); // connect driver item port to sequencer item port
        end
    endfunction
endclass