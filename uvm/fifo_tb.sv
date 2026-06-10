`timescale 1ns/1ps // cycle time 1ns, precision 1ps.

module fifo_tb();
	parameter DATA_WIDTH = 8;
	parameter ADDR_WIDTH = 4;
	localparam DEPTH = (1 << ADDR_WIDTH); // DEPTH = 2^ADDR_WIDTH by shifting 1 left by ADDR_WIDTH bits.
	logic wclk,wrst_n;
	logic rclk,rrst_n;
	logic winc,rinc;
	logic wfull,rempty;
	logic [DATA_WIDTH-1:0] wdata,rdata;
initial begin wclk = 0; forever #5 wclk = ~wclk; end // toggle wclk every 5 cycles of main clock (period 10ns, 100Mhz)
initial begin rclk = 0; forever #7 rclk = ~rclk; end // toggle rclk every 7 cycles of main clock (period 14ns, ~71Mhz)

fifo #(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH)
	)
	DUT ( // connect testbench signals to the async fifo
	.wclk(wclk), .wrst_n(wrst_n),
	.rclk(rclk), .rrst_n(rrst_n),
	.winc(winc), .rinc(rinc),
	.wfull(wfull), .rempty(rempty),
	.wdata(wdata), .rdata(rdata)
	);

bind fifo fifo_sva #(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH)
	)
	sva_inst (
		.wclk(wclk),	
		.wrst_n	(wrst_n),	
		.winc	(winc),
		.wdata	(wdata),
		.wfull	(wfull),
		.rclk	(rclk),	
		.rrst_n	(rrst_n),	
		.rinc	(rinc),
		.rdata	(rdata),
		.rempty	(rempty),

		.wclken		(wclken_wire),
		.rclken		(rclken_wire),
		.waddr		(waddr_wire),
		.raddr		(raddr_wire),
		.wptr_g_cur	(wptr_wire),
		.rptr_g_cur	(rptr_wire),
		.wptr_b_cur(wptr_full_unit.wptr_b_cur),
		.rptr_b_cur(rptr_empty_unit.rptr_b_cur),
		.r2q_wptr(r2q_wptr),
		.w2q_rptr(w2q_rptr),
		.wfull_wire(wfull_wire),
		.rempty_wire(rempty_wire)
	);

	initial begin
			// 1. Reset
			wrst_n = 0; rrst_n = 0; // apply reset
			winc = 0; rinc = 0; 
			#20; // wait 20 ns
			wrst_n = 1; rrst_n = 1; // release reset
			#20;
			@(posedge wclk); winc = 1; wdata = 8'h11; // write hex 11
			@(posedge wclk); winc = 0; // turn off write command	
			@(posedge rclk); rinc = 1;	
			@(posedge rclk); rinc = 0; // turn off read command
			
			// 2. Constrained Random Traffic
			$display("TIME: %t | Starting 1000 cycles of random traffic...",$time);
			repeat (1000) begin
				@(posedge wclk);
				winc = ($urandom_range(0,99) < 70); // 70% chance to attempt a write
				wdata = $urandom();
				
				@(posedge rclk);
				rinc = ($urandom_range(0,99) < 60); // 60% chance to attempt a read 
			end
			// 3. Synchronizer Delay
			winc = 0;
			rinc = 0;
			#100; // wait 50 ns so rempty will be low
			if (scoreboard_queue.size() == 0)
				$display("SUCCESS: 1000 transactions verified. FIFO is empty.");
			else
				$display("WARNING: Simulation ended with %0d items left in Scoreboard.", scoreboard_queue.size()); 
			// 5. End Simulation
			#100;
			$finish;
	end
	
// Scoreboard: check if data flowing into the FIFO is the data flowing out
	logic [DATA_WIDTH-1:0] scoreboard_queue[$]; // stores all data written to FIFO (infinite)
	logic [DATA_WIDTH-1:0] expected_data; 		// stores the first data in queue
	logic check_data_now = 1'b0; 				// bit to check if rdata is updated after rclk posedge

always @(negedge rrst_n) begin  // Reset:
		scoreboard_queue.delete();	// Reset deletes all data
		check_data_now <= 1'b0;		// check data gets 0
	end

always @(posedge wclk) begin	// Savedata:	
		if (winc && !wfull) begin
			scoreboard_queue.push_back(wdata);	// stores data at the end of the queue
			if (scoreboard_queue.size() > DEPTH) begin 
				$error("TB error: Scoreboard Overflow - FIFO exceeded max capacity");
			end
		end
	end
	
always @(posedge rclk) begin	// Check Scoreboard:				
		if (rinc && !rempty) begin
			expected_data <= scoreboard_queue.pop_front();	// release first in line from queue
			check_data_now <= 1'b1;	// Check Scoreboard next edge
		end else begin 
			check_data_now <= 1'b0; // Don't check on next edge
		end
		if (check_data_now) begin // If read last cycle, check the result now
			if (rdata !== expected_data) begin 				// mismatch
				$error("TIME: %t | MISMATCH! Expected: %h, Got: %h" , $time, expected_data, rdata);
			end else begin 									// match
				$display("TIME: %t | MATCH: %h", $time, rdata);
			end
		end
	end
			
endmodule