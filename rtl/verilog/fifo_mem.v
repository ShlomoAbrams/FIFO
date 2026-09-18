// Dual-Port RAM Memory for Asynchronous FIFO
// Supports independent write clock (wclk) and read clock (rclk)

`timescale 1ns / 1ps

module fifo_mem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    // Write Interface
    input  wire                  wclk,
    input  wire                  wclken,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire [DATA_WIDTH-1:0] wdata,

    // Read Interface
    input  wire                  rclk,
    input  wire                  rclken,
    input  wire [ADDR_WIDTH-1:0] raddr,
    output reg  [DATA_WIDTH-1:0] rdata
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    // Memory array storage
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Synchronous Write Process
    always @(posedge wclk) begin
        if (wclken) begin
            mem[waddr] <= wdata;
        end
    end

    // Synchronous Read Process
    always @(posedge rclk) begin
        if (rclken) begin
            rdata <= mem[raddr];
        end
    end

endmodule
