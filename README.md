# Asynchronous FIFO Design & UVM Verification Environment

> Asynchronous FIFO implemented in VHDL and verified using a SystemVerilog UVM environment with constrained-random testing, assertions, scoreboarding, and functional coverage.

---

# Project Overview

This project implements a parameterized asynchronous FIFO (First-In, First-Out) buffer designed for safe data transfer between independent clock domains.

The design addresses critical clock-domain crossing (CDC) challenges including:
- Metastability mitigation
- Multi-bit synchronization
- Gray-code pointer transfer
- Reliable full/empty flag generation
- Independent asynchronous read/write operation

The verification environment was developed using the Universal Verification Methodology (UVM) and includes:
- Constrained-random stimulus generation
- Assertion-based verification (SVA)
- Functional coverage
- Self-checking scoreboard architecture
- Randomized asynchronous clock behavior

---

# Why Asynchronous FIFOs Matter

Asynchronous FIFOs are widely used in modern digital systems whenever data must safely cross between unrelated clock domains.

Unlike synchronous FIFOs, asynchronous FIFOs must handle:
- Unsynchronized clocks
- Metastability risks
- Safe pointer synchronization
- Correct status flag generation despite CDC latency

To minimize synchronization errors, Gray-code pointers are used because only a single bit changes between adjacent values.

Gray-code conversion used in the design:

f_{gray}=b\oplus(b>>1)

The synchronized Gray pointers are transferred across domains using a 2-stage flip-flop synchronizer chain.

---

# Project Structure

```text
FIFO/
│
├── rtl/                   # Synthesizable VHDL design files
│   ├── fifo.vhd
│   ├── fifo_mem.vhd
│   ├── fifo_r_ptr.vhd
│   ├── fifo_w_ptr.vhd
│   └── fifo_synchronizer.vhd
│
├── uvm/                   # UVM verification environment
│   ├── fifo_env.sv
│   ├── fifo_if.sv
│   ├── fifo_pkg.sv
│   ├── fifo_r_agent.sv
│   ├── fifo_r_drain_sequence.sv
│   ├── fifo_r_driver.sv
│   ├── fifo_r_monitor.sv
│   ├── fifo_r_sequence.sv
│   ├── fifo_scoreboard.sv
│   ├── fifo_sva.sv
│   ├── fifo_tb.sv         # Legacy SV testbench
│   ├── fifo_test.sv
│   ├── fifo_top.sv
│   ├── fifo_transaction.sv
│   ├── fifo_w_agent.sv
│   ├── fifo_w_burst_sequence.sv
│   ├── fifo_w_driver.sv
│   ├── fifo_w_monitor.sv
│   └── fifo_w_sequence.sv
│
└── sim/
    └── run.do
```

---

# Quick Start: Simulation Instructions

This project includes a fully automated simulation and reporting flow using ModelSim/QuestaSim:

1. **Open ModelSim/QuestaSim.**
2. **Change directory** to the `sim` folder:
   ```tcl
   cd sim
   ```
3. **Execute the run script:**
   ```tcl
   do run.do
   ```
4. **View results:** The script will automatically clean, compile VHDL and SystemVerilog files, configure waveform groupings, run the testbench, save UCDB metrics, and automatically launch the **100% hardware coverage HTML report** in your browser.

---

# FIFO Architecture

## Top-Level Architecture

![FIFO Architecture](docs/FIFO_Block_Diagram.jpg)

### Key Design Features
- Dual-clock asynchronous FIFO
- Independent read/write clock domains
- Gray-code pointer generation
- 2FF synchronizer chain
- Parameterized FIFO depth and width
- Dual-port memory architecture
- Safe full/empty detection logic

---

# Pointer Synchronization

## Gray-Code Synchronization Path

![Gray Pointer Synchronization](docs/gray_sync.png)

### Synchronization Strategy
- Binary pointers are converted to Gray-code
- Gray pointers are synchronized across clock domains
- 2-stage flip-flop synchronizers reduce metastability propagation risk
- Full/empty flags are generated using synchronized pointers

### Asynchronous CDC Latency & Flag Pessimism
Because pointers cross independent clock domains through a 2-stage flip-flop (2FF) synchronizer chain, there is a **2-cycle latency** before a pointer value is visible in the opposite clock domain. This latency introduces a safe, pessimistic bias in flag generation:
- **`wfull` Pessimism:** The write pointer is compared against a read pointer that is 2 cycles old. The write side may see the FIFO as "Full" slightly earlier than it physically is. This is structurally safe because it guarantees no data is overwritten (overflow).
- **`rempty` Pessimism:** The read pointer is compared against a write pointer that is 2 cycles old. The read side may see the FIFO as "Empty" slightly earlier than it physically is. This is structurally safe because it guarantees no stale or garbage data is read (underflow).

---

# Verification Environment

## UVM Testbench Architecture

![UVM Environment](docs/UVM_Architecture.png)

## UVM Verification Architecture

The testbench uses industry-standard UVM methodology:
- **Testbench Layer**: Write and Read agents generate transactions
- **TLM & VIF Layer**: Translates UVM transactions to RTL signals
- **Hardware Layer**: DUT includes FIFO memory with CDC synchronizers
- **Scoreboard**: Compares expected vs. actual data with coverage metrics

### Verification Components
- UVM driver
- UVM monitor
- UVM sequencer
- Self-checking scoreboard
- Functional coverage collector
- SystemVerilog assertions
- Constrained-random stimulus generation

---

# Verification Strategy

The DUT was verified using both directed and constrained-random testing methodologies.

## Features Verified (Verification Trace Matrix)

| Verification Scenario | Status | SVA Checker Evidence | Functional Coverage Evidence |
|---|---|---|---|
| **FIFO Full Detection** | ✅ Passed | SVA #8 (Full Flag Generation) | Coverpoint `wfull` |
| **FIFO Empty Detection** | ✅ Passed | SVA #7 (Empty Flag Generation) | Coverpoint `rempty` |
| **Overflow Protection** | ✅ Passed | SVA #3 (Write Pointer Stability), SVA #9 (Write Gating) | Cross `winc` × `wfull` |
| **Underflow Protection** | ✅ Passed | SVA #4 (Read Pointer Stability), SVA #10 (Read Gating) | Cross `rinc` × `rempty` |
| **Simultaneous Read/Write** | ✅ Passed | SVA #11 (Data Integrity Checker) | Crosses `winc` / `rinc` × Occupancy |
| **Pointer Wraparound** | ✅ Passed | SVA #12 (Memory Occupancy Bound Check) | Coverpoints `w_occupancy` / `r_occupancy` |
| **Asynchronous Clock Ratios** | ✅ Passed | SVA #11 (Data Integrity Checker) | Parameterized clock period sweeps |
| **Gray Pointer Correctness** | ✅ Passed | SVA #5, #6 (Gray-Code Integrity) | Coverpoints `wptr_g_cur` / `rptr_g_cur` |
| **Reset Recovery** | ✅ Passed | SVA #1, #2 (Write/Read Domain Reset) | Coverpoints `wrst_n` / `rrst_n` |
| **CDC Synchronization Behavior** | ✅ Passed | SVA #7, #8 (CDC Gray Pointers match) | Synchronized pointer cross tracking |

---

# Assertions (SVA)

The verification environment contains **12 concurrent and immediate SystemVerilog Assertions** to check the safety and correctness of the design protocol in real time:

1. **Write Domain Reset:** Asserts that when the write reset (`wrst_n`) is active, all write pointers (`waddr`, binary, Gray) and the `wfull` flag are correctly initialized to `0`.
2. **Read Domain Reset:** Asserts that when the read reset (`rrst_n`) is active, all read pointers (`raddr`, binary, Gray) are initialized to `0` and `rempty` is asserted (`1`).
3. **Write Pointer Stability (No Overwrite):** Verifies that if `wfull` is asserted, any subsequent write requests (`winc`) will not increment the write pointers (protects against write overflow).
4. **Read Pointer Stability (No Overread):** Verifies that if `rempty` is asserted, any subsequent read requests (`rinc`) will not increment the read pointers (protects against read underflow).
5. **Write Gray-Code Integrity:** Checks that the write Gray-code pointer changes by only one bit per increment step, ensuring CDC safety.
6. **Read Gray-Code Integrity:** Checks that the read Gray-code pointer changes by only one bit per increment step, ensuring CDC safety.
7. **Empty Flag Generation:** Verifies that when the read Gray pointer equals the synchronized write Gray pointer, the `rempty` flag is asserted.
8. **Full Flag Generation:** Verifies that when the write Gray pointer matches the synchronized read Gray pointer (with the two MSBs inverted), the `wfull` flag is asserted.
9. **Write Enable Gating:** Verifies that the internal write memory enable (`wclken`) is only active when `winc = 1` and `wfull = 0`.
10. **Read Enable Gating:** Verifies that the internal read memory enable (`rclken`) is only active when `rinc = 1` and `rempty = 0`.
11. **Data Integrity Checker:** Compares the read data `rdata` against a golden shadow memory array (`fifo_data`) at the read address to check for data corruption.
12. **Memory Occupancy Bound Check:** Verifies that the modular difference between the write pointer and synchronized read pointer (`w_occupancy`) never exceeds the maximum FIFO `DEPTH`.

---

# Functional & Structural Coverage

The verification environment combines **Structural Code Coverage** on the RTL design units with **Functional and Assertion Coverage** defined via SystemVerilog covergroups and SVA.

## Coverage Goals & Coverpoints

The verification plan defines **12 distinct coverpoints and crosses** (split between the write-side and read-side covergroups) to verify correct operation across all FIFO scenarios:

### Write-Side Covergroup (`fifo_w_cg`)
1. **`wfull`**: Coverage of the FIFO Full flag states (Asserted vs. Deasserted).
2. **`w_occupancy`**: Tracks write-side occupancy levels (`empty`, `almost_empty`, `mid_range`, `almost_full`, `full`).
3. **`winc`**: Verifies write command request activation.
4. **`wrst_n`**: Verifies write domain reset states.
5. **Cross `winc` × `wfull`**: Proves write attempts are simulated under both Full and Non-Full conditions (tests overflow protection).
6. **Cross `winc` × `w_occupancy`**: Proves write requests are executed at every possible FIFO fill level.

### Read-Side Covergroup (`fifo_r_cg`)
7. **`rempty`**: Coverage of the FIFO Empty flag states (Asserted vs. Deasserted).
8. **`r_occupancy`**: Tracks read-side occupancy levels (`empty`, `almost_empty`, `mid_range`, `almost_full`, `full`).
9. **`rinc`**: Verifies read command request activation.
10. **`rrst_n`**: Verifies read domain reset states.
11. **Cross `rinc` × `rempty`**: Proves read attempts are simulated under both Empty and Non-Empty conditions (tests underflow protection).
12. **Cross `rinc` × `r_occupancy`**: Proves read requests are executed at every possible FIFO fill level.

## Coverage Results

| Coverage Type | Target | Status | Result |
|---|---|---|---|
| **Functional Coverage** | Covergroups / Coverpoints | ✅ Covered | 100% |
| **Assertion Coverage** | SystemVerilog Assertions | ✅ Covered | 100% |
| **RTL Code Coverage** | VHDL Design Units | ✅ Covered | 100% |

* **Functional Coverage:** Proves the testbench successfully hit all defined design features and edge cases (e.g., full, empty, write while full).
* **Assertion Coverage:** Confirms all safety checkers (SVA) protecting against overflow, underflow, and logic faults were active and passed.
* **RTL Code Coverage (Structural):** Verifies the simulator executed every physical line, branch path, boolean expression, and signal toggle in the hardware code.

### ModelSim Coverage Dashboard
![Coverage Report Summary](docs/coverage.png)

### Detailed Design Units Coverage Breakdown
![Detailed Design Units Coverage](docs/coverage_details.png)

---

# Simulation Waveforms
![Waveform Simulation](docs/Waveform_Simulation.png)
![FIFO Block Diagram](docs/FIFO_Block_Diagram_Black.jpg)

---
## Read & Write Transactions 
This waveform demonstrates standard FIFO data path operations. Data is written into the memory array (`wdata`) on the write clock domain when `winc` is asserted. It is subsequently read out (`rdata`) on the read clock domain in a First-In-First-Out sequence. The integrity of the data stream (e.g., `A7`, `5A`, `AF`) is preserved perfectly as it crosses the asynchronous boundary.

![Read & Write Waveform](docs/read_&_write_waveform.png)

## FIFO Full Condition
The FIFO asserts the full flag when the write pointer catches up to the synchronized read pointer. Because we are using Gray code across clock domains, the `wfull` condition is met when the pointers are equal, but the two Most Significant Bits (MSBs) are inverted.

![FIFO Full Waveform](docs/wfull_waveform.png)

---

## FIFO Empty Condition
The FIFO asserts the empty flag when the read pointer catches up to the synchronized write pointer. This occurs when all bits of the read pointer and the synchronized write pointer perfectly match.

![FIFO Empty Waveform](docs/rempty_waveform.png)

## Clock Domain Crossing (CDC) Synchronization

To safely pass the Gray-coded pointers between the independent read and write clock domains, the design utilizes 2-stage flip-flop synchronizers to mitigate metastability. 

### Read-to-Write Synchronization
The read pointer crosses into the write domain. It is captured by the write clock (`wclk`) through two stages (`q1ptr_g` and `q2ptr_g`) before being evaluated for the full condition.
![Read to Write Sync](docs/r2w_sync_waveform.png)

---

### Write-to-Read Synchronization
The write pointer crosses into the read domain. It is captured by the read clock (`rclk`) through two stages before being evaluated for the empty condition.
![Write to Read Sync](docs/w2r_sync_waveform.png)


# Author

Shlomo Abrams

Electrical Engineering Student  
Digital Design & Verification Enthusiast

GitHub:
https://github.com/ShlomoAbrams
