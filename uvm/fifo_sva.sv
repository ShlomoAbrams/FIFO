module fifo_sva #(
	parameter DATA_WIDTH = 8,
	parameter ADDR_WIDTH = 4
	)
	(
	input logic wclk,wrst_n,rclk,rrst_n,
	input logic winc,rinc,wclken,rclken,
	input logic wfull, rempty,rempty_wire, wfull_wire,
	input logic [DATA_WIDTH-1:0]wdata, rdata,
	input logic [ADDR_WIDTH-1:0]waddr ,raddr,
	input logic [ADDR_WIDTH:0] wptr_g_cur,wptr_b_cur,rptr_g_cur,rptr_b_cur,
	input logic [ADDR_WIDTH:0] r2q_wptr,w2q_rptr
	);
	
localparam DEPTH = ( 1 << ADDR_WIDTH); // DEPTH = 2^ADDR_WIDTH by shifting 1 left by ADDR_WIDTH bits.

// Gray w2q_rptr -> Binary conversion
logic [ADDR_WIDTH:0] w2q_rptr_bin; 	// contain the binary version of the pointer
always_comb begin					// convert w2q_rptr to binary
	w2q_rptr_bin[ADDR_WIDTH] = w2q_rptr[ADDR_WIDTH];		// first binary bit is identical to gray 
	for (int i = ADDR_WIDTH-1; i>=0; i--) begin			// loop 
		w2q_rptr_bin[i] = w2q_rptr_bin[i+1] ^ w2q_rptr[i]; 	// binary bit is xor of current gray and preveis binary
	end
end

// Gray r2q_wptr -> Binary conversion
logic [ADDR_WIDTH:0] r2q_wptr_bin; 	// contain the binary version of the pointer
always_comb begin					// convert r2q_eptr to binary
	r2q_wptr_bin[ADDR_WIDTH] = r2q_wptr[ADDR_WIDTH];		// first binary bit is identical to gray 
	for (int i = ADDR_WIDTH-1; i>=0; i--) begin			// loop 
		r2q_wptr_bin[i] = r2q_wptr_bin[i+1] ^ r2q_wptr[i]; 	// binary bit is xor of current gray and preveis binary
	end
end

// Write Side Cover Group
logic [ADDR_WIDTH:0] w_occupancy; // how full is the FIFO
assign w_occupancy = wptr_b_cur - w2q_rptr_bin;  // the difference between the write and read pointer
covergroup fifo_w_cg @(posedge wclk); // Captures values in testbench after each cycle. 
	coverpoint wfull{		// captures when FIFO becomes full
	bins full = {1}; 	// FIFO is full
	bins not_full = {0};	// FIFO not full
	}
	coverpoint w_occupancy{
	bins empty = {0};
	bins almost_empty = {[1:2]};
	bins mid_range = {[3:DEPTH-3]};
	bins almost_full = {[DEPTH-2:DEPTH-1]};
	bins full = {DEPTH};
	}
	coverpoint winc;		// captures write increments
	coverpoint wrst_n;		// captures reset
	cross winc, wfull;		// captures write attempt when full
	cross winc, w_occupancy; // captures when read attempt across occupancy levels

endgroup

// Read Side Cover Group
logic [ADDR_WIDTH:0] r_occupancy; 				// how full is the FIFO
assign r_occupancy = r2q_wptr_bin - rptr_b_cur; // the difference between pointers
covergroup fifo_r_cg @(posedge rclk); // Captures values in testbench after each cycle.
	coverpoint rempty{		// captures when FIFO becomes empty
	bins empty = {1};	// FIFO empty
	bins not_empty = {0};	// FIFO is not empty
	}
	coverpoint r_occupancy{
	bins empty = {0};
	bins almost_empty = {[1:2]};
	bins mid_range = {[3:DEPTH-3]};
	bins almost_full = {[DEPTH-2:DEPTH-1]};
	bins full = {DEPTH};
	}
	coverpoint rinc;		// captures read increments
	coverpoint rrst_n;		// captures reset
	cross rinc, rempty;		// captures read attempt when empty
	cross rinc, r_occupancy; // captures when read attempt across occupancy levels
endgroup

fifo_w_cg w_cg = new(); // create an instance
fifo_r_cg r_cg = new(); // create an instance

	always @(posedge wclk) begin 
		if (wrst_n) w_cg.sample(); // samples every cycle write signal values
	end 
	always @(posedge rclk) begin 
		if (rrst_n) r_cg.sample(); // samples every cycle read signal values
	end

// Write side Reset Asserion - pointers and full flag reset
assert property (@(posedge wclk) 
!wrst_n |=> (waddr == '0) && (wptr_g_cur == '0) && (wptr_b_cur == '0) && (wfull == 0) // check one cycle that siganls are reset
);

// Read Side Reset Assertion - pointers and empty flag reset
assert property (@(posedge rclk) 
!rrst_n |=> (raddr == '0) && (rptr_g_cur == '0) && (rptr_b_cur == '0) && (rempty == 1) // check one cycle that siganls are reset
);

// Write Pointer stability - No Overwrite - when full then pointer doesnt increment.
assert property (@(posedge wclk) 
disable iff(!wrst_n)
(wfull && winc) |=> $stable(wptr_g_cur) && $stable(wptr_b_cur)
);

// Read Pointer stability - No Overread - when empty then pointer doesnt increment.
assert property (@(posedge rclk) 
disable iff(!rrst_n)
(rempty && rinc) |=> $stable(rptr_g_cur) && $stable(rptr_b_cur)
);

// Gray Code Integrity (Write pointer) - verify only one bit change every cycle.
assert property (
@(posedge wclk) disable iff(!wrst_n)
$changed(wptr_g_cur) |-> ($countones(wptr_g_cur^($past(wptr_g_cur)))== 1)
);

// Gray Code Integrity (Read pointer) - verify only one bit change every cycle.
assert property (
@(posedge rclk) disable iff(!rrst_n)
$changed(rptr_g_cur) |-> ($countones(rptr_g_cur^($past(rptr_g_cur)))== 1)
);

// Empty Flag Verification - check if empty when write & read pointer are equal.  (rempty is updated one cycle after pointers equal)  
assert property(
@(posedge rclk) disable iff(!rrst_n)
(rptr_g_cur == r2q_wptr)|=> (rempty == 1)
);

// Full Flag Verification - check if full when top 2 msb bits are opposite and lower bits are identical.(if and only if)
assert property (
@(posedge wclk) disable iff(!wrst_n)
((wptr_g_cur[ADDR_WIDTH] != w2q_rptr[ADDR_WIDTH]) &&  (wptr_g_cur[ADDR_WIDTH-1] != w2q_rptr[ADDR_WIDTH-1]) && (wptr_g_cur[ADDR_WIDTH-2:0] == w2q_rptr[ADDR_WIDTH-2:0])) |=> (wfull == 1)
);

// Write Enable Verification - check that we only enable writing if not full and winc is high.
assert property (@(posedge wclk)
disable iff (!wrst_n)
wclken |-> (!wfull && winc)
);

// Read Enable Verification - check that we only enable reading if not empty and rinc is high.
assert property (@(posedge rclk)
disable iff(!rrst_n)
rclken |-> (!rempty && rinc)
);

// Data Integrity - Check that the data that goes in first exits first: 
	logic [DATA_WIDTH-1:0] fifo_data [0:DEPTH-1]; // Array to save data
	logic [ADDR_WIDTH-1:0] w_index; // write address ,increments whenever you write.
	
	always_ff @(posedge wclk or negedge wrst_n) begin
		if (!wrst_n) begin 
			w_index <= 0; // Reset Pointer
			for (int i = 0; i< DEPTH; i++) begin 
				fifo_data[i] <= '0; // initialize shadow Memory
			end
		end
		else if (wclken && !wfull) begin // if writing into fifo
			fifo_data[w_index] <= wdata; // store current wdata at w_index in fifo_data
			w_index <= w_index + 1; // inc w_index
		end
	end
	
	always_ff @(posedge rclk or negedge rrst_n) begin 
		if ($past(rclken) && !$past(rempty)) begin	// if reading fifo
			assert (rdata == fifo_data[$past(raddr)]) // check that data read equals data saved.
			else $error("Data mismatch at read address %0h, expected %0h, got %0h", $past(raddr), fifo_data[$past(raddr)], rdata); // error where the data didnt match.
		end
	end

// Memory manegment: (write_ptr - synchronized read_ptr) <= DEPTH]. 
property memory_management;
	@(posedge wclk) disable iff (!wrst_n)		// Check that write & read pointer arent out of bound. 
												// Uses synchronized read pointer (w2q_rptr_bin), so check is slightly pessimistic but guarantees safety. 
	w_occupancy <= (DEPTH); 	// Counters are ADDR_WIDTH+1 bit long so their difference can exceed DEPTH in case of overflow. Cast result to (ADDR_WIDTH+1) to force modular arithmetic This handles pointer wrap-around correctly by truncating expanded 32-bit signed results to the physical 5-bit pointer distance, preventing false assertion failures

endproperty

assert_memory_management: assert property (memory_management)
	else $error("FIFO pointer out of bounds! Calculated: %0d", (ADDR_WIDTH+1)'(wptr_b_cur - w2q_rptr_bin));

endmodule
