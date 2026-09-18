// Dual-Flop Synchronizer for Clock Domain Crossing (CDC)
// Converts asynchronous input pointer into destination clock domain
// Includes Xilinx ASYNC_REG attribute to prevent metastability / optimize slice placement

`timescale 1ns / 1ps

module fifo_synchronizer #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [ADDR_WIDTH:0]   ptr_g,
    output reg  [ADDR_WIDTH:0]   q2ptr_g
);

    // ASYNC_REG attribute ensures both flip-flops are placed in the same slice to reduce MTBF
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] q1ptr_g;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q1ptr_g <= {(ADDR_WIDTH+1){1'b0}};
            q2ptr_g <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            q1ptr_g <= ptr_g;
            q2ptr_g <= q1ptr_g;
        end
    end

endmodule
