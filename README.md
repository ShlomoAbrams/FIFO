# Asynchronous FIFO Design & UVM Verification Environment

## Overview
This repository contains a high-performance **Asynchronous FIFO (First-In, First-Out)** memory buffer design implemented in synthesizable VHDL, alongside a complete, rigorous verification suite using **SystemVerilog and the Universal Verification Methodology (UVM)**. 

The design addresses critical hardware challenges including safe multi-bit data transfer across independent, unsynchronized clock domains (clock domain crossing), metastability mitigation, and robust status flag generation.

## System Architecture

The project structure separates the synthesizable hardware implementation (RTL) from the advanced object-oriented verification components (UVM) and simulation run configurations:

```text
FIFO/
│
├── rtl/                   # Synthesizable VHDL design files
│   ├── fifo.vhd           # Top-level structural design wrapper
│   ├── fifo_mem.vhd       # Dual-port synchronized memory array
│   ├── fifo_ptr.vhd       # Generic pointer tracking logic
│   ├── fifo_r_ptr.vhd     # Read-domain pointer generation & Gray conversion
│   ├── fifo_w_ptr.vhd     # Write-domain pointer generation & Gray conversion
│   └── fifo_synchronizer.vhd # 2-Stage flip-flop synchronizer chain
│
├── uvm/                   # SystemVerilog UVM verification suite
│   ├── fifo_tb.sv         # Top-level hardware testbench test harness
│   ├── fifo_top.sv        # Package wrapper importing components
│   ├── fifo_if.sv         # SystemVerilog Interface with modports and assertions
│   ├── fifo_env.sv        # UVM Environment container
│   ├── fifo_scoreboard.sv # Transaction monitoring and dynamic data comparison
│   ├── fifo_transaction.sv# Verification transaction item definition
│   ├── fifo_test.sv       # Base UVM test and specific test cases
│   └── fifo_sva.sv        # SystemVerilog Assertions (SVA) for protocol checking
│
└── sim/                   # ModelSim automation workspace
    └── run.do             # Tcl automation script for complete simulation execution