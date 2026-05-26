`include "uvm_macros.svh"
import uvm_pkg::*;

class fifo_w_monitor extends uvm_monitor; // BLUEPRINT: Defines Write MOnitor based on template
	`uvm_component_utils(fifo_w_monitor) // FACTORY: Register the Monitor in UVM library so it can be used later
	virtual fifo_if vif;  // the "Virtual" Interface is the software handle to the physical fifo interface
	
	uvm_analysis_port #(fifo_transaction) ap; // BROADCAST PORT: sends data to the Scoreboard
	
	function new( string name, uvm_component parent); // CONSTUCTOR: Creates the component and initializes the Broadcaster ap
		super.new(name, parent); // establish compunents name and place in hierarchy 
		ap = new("ap", this); // create the port so it exists as soon as the testbench starts
	endfunction
	
	virtual function void build_phase(uvm_phase phase); // BUILD PHASE: Runs at Time 0 to fetch configuration data before simulation starts
		super.build_phase(phase);
		if(!uvm_config_db#(virtual fifo_if)::get(this, "","vif",vif)) begin 	// Reach into Database for the Virtual Interface
			`uvm_fatal("DRV", "Couldn't find virtual interface in config_db!")	// If "get" fails then there wasn't a Virtual Interface
		end
	endfunction	
	
	virtual task run_phase(uvm_phase phase); // WORK SHIFT: Watches the wires for the duration of the simulation
		fifo_transaction tr; // HANDLE: create a pointer that can point to transaction object
		forever begin
			@(vif.w_m_cb); // wait for clock edge
			if (vif.w_m_cb.wclken_wire === 1'b1) begin // Record if Write is Enabled
				tr = fifo_transaction::type_id::create("tr"); // create a new transaction object named "tr" to sample the data onto
				tr.data = vif.w_m_cb.wdata; // SAMPLING: Record data seen on physical wires to software object
				ap.write(tr); // BROADCAST: Send note to the Scoreboard
				`uvm_info("MON", $sformatf("Obeserve WRITE: Data=%h", tr.data), UVM_MEDIUM) // LOGGING: print messsage to console to see Monitoring
			end
		end
	endtask
endclass