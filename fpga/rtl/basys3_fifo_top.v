// Basys 3 FPGA Top-Level Module for Asynchronous Dual-Clock FIFO
// Connects Digilent Basys 3 PMOD headers to the Tiny Tapeout FIFO core
// Also drives onboard LEDs and supports push-button manual reset

`timescale 1ns / 1ps

module basys3_fifo_top (
    // PMOD JA: 8-bit Write Data from Raspberry Pi (Inputs)
    // JA1..JA4, JA7..JA10
    input  wire [7:0] ja,

    // PMOD JB: 8-bit Read Data to Raspberry Pi (Outputs)
    // JB1..JB4, JB7..JB10
    output wire [7:0] jb,

    // PMOD JC: Control & Status Flags
    input  wire       jc_winc,    // JC1  (Pin K17) - Write increment
    input  wire       jc_wclk,    // JC2  (Pin M18) - Write clock from RPi
    input  wire       jc_wrst_n,  // JC3  (Pin N17) - Write reset (active low)
    output wire       jc_wfull,   // JC4  (Pin P18) - FIFO Full flag
    input  wire       jc_rinc,    // JC7  (Pin L17) - Read increment
    input  wire       jc_rclk,    // JC8  (Pin M19) - Read clock from RPi
    input  wire       jc_rrst_n,  // JC9  (Pin P17) - Read reset (active low)
    output wire       jc_rempty,  // JC10 (Pin R18) - FIFO Empty flag

    // On-board Push Button (Center button BTNC: Active-high when pressed)
    input  wire       btnC,

    // On-board 16 LEDs for Visual Debugging
    output wire [15:0] led
);

    // Manual Reset from BTNC (inverted to active-low)
    wire manual_rst_n = ~btnC;

    // Internal Tiny Tapeout IO buses
    wire [7:0] uio_in_bus;
    wire [7:0] uio_out_bus;
    wire [7:0] uio_oe_bus;
    wire [7:0] rdata_bus;

    // Map JC control inputs into the Tiny Tapeout uio_in bus
    assign uio_in_bus[0] = jc_winc;
    assign uio_in_bus[1] = jc_wclk;
    assign uio_in_bus[2] = jc_wrst_n;
    assign uio_in_bus[3] = 1'b0;      // Pin 3 is output (wfull)
    assign uio_in_bus[4] = jc_rinc;
    assign uio_in_bus[5] = jc_rclk;
    assign uio_in_bus[6] = jc_rrst_n;
    assign uio_in_bus[7] = 1'b0;      // Pin 7 is output (rempty)

    // Extract outputs from Tiny Tapeout uio_out bus
    assign jc_wfull  = uio_out_bus[3];
    assign jc_rempty = uio_out_bus[7];

    // Connect PMOD JB to Read Data
    assign jb = rdata_bus;

    // -------------------------------------------------------------
    // On-board LED Status Display:
    // LED[0]     : FIFO Full flag (Lights up red/green when FULL)
    // LED[1]     : FIFO Empty flag (Lights up when EMPTY)
    // LED[7:2]   : Unused (driven low)
    // LED[15:8]  : Shows the 8-bit Read Data byte directly on the board!
    // -------------------------------------------------------------
    assign led[0]    = jc_wfull;
    assign led[1]    = jc_rempty;
    assign led[7:2]  = 6'b000000;
    assign led[15:8] = rdata_bus;

    // Instantiate Tiny Tapeout Top Wrapper (tt_um_fifo)
    // This proves hardware execution of the exact ASIC top module!
    tt_um_fifo u_tt_fifo (
        .ui_in   (ja),             // 8-bit write data from PMOD JA
        .uo_out  (rdata_bus),      // 8-bit read data to PMOD JB
        .uio_in  (uio_in_bus),     // Control inputs
        .uio_out (uio_out_bus),    // Flag outputs
        .uio_oe  (uio_oe_bus),     // Output enables
        .ena     (1'b1),           // Enabled
        .clk     (1'b0),           // Unused (clocks come from wclk/rclk)
        .rst_n   (manual_rst_n)    // Board reset from BTNC
    );

endmodule
