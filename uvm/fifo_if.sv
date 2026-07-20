// FIFO interface: Bundles DUT signals into one plug and allows UVM components to access them. 
// DUT signals = hardware pins. UVM driver = software controlling it. interface = a cable grouping all wires. virtual interface = giving software access to that cable
interface fifo_if #(parameter DATA_WIDTH = 8) (	// Parameterized interface cable
	input logic wclk,
	input logic rclk
);
	// DUT signals 
	logic wrst_n, rrst_n;
	logic winc, rinc;
	logic wfull, rempty;
	logic [DATA_WIDTH-1:0] wdata, rdata;
	logic wclken_wire, rclken_wire;
	
	// Write Driver Clocking Block
	clocking w_d_cb @(posedge wclk); 			// Write Clocking Block: synchronizes driver/monitor to wclk and prevents race conditions.
		default input #1step output #1step;		// Sample inputs just before the edge, drive outputs after (avoid race conditions)
		output winc, wdata, wrst_n;				// Control Signals (Driver -> DUT)
		input wfull;							// Status Signals (DUT -> Driver)
	endclocking
	
	// Read Driver Clocking Block
	clocking r_d_cb @(posedge rclk);			// Read Clocking Block: synchronizes driver/monitor to rclk and prevents race conditions.
		default input #1step output #1step; 	// Sample inputs just before the edge, drive outputs after (avoid race conditions)
		output rinc, rrst_n;					// Control Signals (Driver -> DUT)
		input rdata, rempty;					// Status Signals (DUT -> Driver)
	endclocking

	// Write Monitor Clocking Block
	clocking w_m_cb @(posedge wclk); 			// Write Clocking Block: synchronizes driver/monitor to wclk and prevents race conditions.
		default input #1step output #1step;		// Sample inputs just before the edge, drive outputs after (avoid race conditions)
		input winc, wdata, wrst_n, wfull, wclken_wire;// Monitor treats all signals as inputs (DUT -> Monitor)
	endclocking
	
	// Read Monitor Clocking Block
	clocking r_m_cb @(posedge rclk);			// Read Clocking Block: synchronizes driver/monitor to rclk and prevents race conditions.
		default input #1step output #1step; 	// Sample inputs just before the edge, drive outputs after (avoid race conditions)
		input rdata, rempty, rinc, rrst_n, rclken_wire;// Monitor treats all signals as inputs (DUT -> Monitor)
	endclocking
endinterface