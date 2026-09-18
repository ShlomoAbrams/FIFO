// Tiny Tapeout Top Wrapper for Asynchronous Dual-Clock FIFO
// Maps the 8-bit Data and Dual-Clock Control signals to Tiny Tapeout standard pins

`default_nettype none

module tt_um_fifo (
    input  wire [7:0] ui_in,    // Dedicated inputs:  wdata[7:0]
    output wire [7:0] uo_out,   // Dedicated outputs: rdata[7:0]
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // Will go high when design is enabled
    input  wire       clk,      // System clock (can be used as default clock)
    input  wire       rst_n     // Global reset (active low)
);

    // Pin Mapping Strategy:
    // -------------------------------------------------------------
    // ui_in[7:0]   : Write Data (wdata[7:0])
    // uo_out[7:0]  : Read Data  (rdata[7:0])
    //
    // Bidirectional IOs:
    // uio[0] (in)  : winc   (Write Increment / Enable)
    // uio[1] (in)  : wclk   (Write Clock from RPi / external tester)
    // uio[2] (in)  : wrst_n (Write Domain Reset, combined with global rst_n)
    // uio[3] (out) : wfull  (FIFO Full flag)
    // uio[4] (in)  : rinc   (Read Increment / Enable)
    // uio[5] (in)  : rclk   (Read Clock from RPi / external tester)
    // uio[6] (in)  : rrst_n (Read Domain Reset, combined with global rst_n)
    // uio[7] (out) : rempty (FIFO Empty flag)
    // -------------------------------------------------------------

    // Direction control: pins 3 and 7 are outputs (1), all other pins are inputs (0)
    assign uio_oe = 8'b1000_1000;

    // Internal signals
    wire winc   = uio_in[0];
    wire wclk_i = uio_in[1];
    wire wrst_i = rst_n & uio_in[2];
    wire wfull_o;

    wire rinc   = uio_in[4];
    wire rclk_i = uio_in[5];
    wire rrst_i = rst_n & uio_in[6];
    wire rempty_o;

    // Drive bidirectional outputs (unused output drivers tied to 0)
    assign uio_out[0] = 1'b0;
    assign uio_out[1] = 1'b0;
    assign uio_out[2] = 1'b0;
    assign uio_out[3] = wfull_o;
    assign uio_out[4] = 1'b0;
    assign uio_out[5] = 1'b0;
    assign uio_out[6] = 1'b0;
    assign uio_out[7] = rempty_o;

    // Suppress unused input warning for Tiny Tapeout linting
    wire _unused = &{ena, clk, 1'b0};

    // Instantiate Parameterized Asynchronous FIFO (8-bit data, 16-entry depth)
    fifo #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(4)
    ) u_fifo (
        // Write Domain
        .wclk   (wclk_i),
        .wrst_n (wrst_i),
        .winc   (winc),
        .wfull  (wfull_o),
        .wdata  (ui_in),

        // Read Domain
        .rclk   (rclk_i),
        .rrst_n (rrst_i),
        .rinc   (rinc),
        .rempty (rempty_o),
        .rdata  (uo_out)
    );

endmodule
