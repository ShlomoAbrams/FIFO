#!/usr/bin/env python3
"""
================================================================================
Raspberry Pi Hardware-in-the-Loop Testbench for Basys 3 Dual-Clock FIFO
================================================================================

This script runs on a Raspberry Pi connected via jumper wires to a Digilent Basys 3
FPGA running the Asynchronous FIFO bitstream.

WIRING TABLE (Raspberry Pi 40-Pin Header <---> Basys 3 PMOD Headers):
Parallel Rails Layout (JA -> JC -> JB, with USB ports oriented at TOP):
- OUTER ROW (Even pins 2..40: LEFT column / outer board edge): 5-wire bundles (Signals + GND)
- INNER ROW (Odd pins 1..39: RIGHT column / toward CPU): 4-wire bundles (Signals only)
- Orientation: Top = USB Ports (Pins 39/40), Bottom = MicroSD Slot (Pins 1/2)
- Zone Order: Top = PMOD JB (Read Bus), Middle = PMOD JC (Clocks/Flags), Bottom = PMOD JA (Write Bus)
--------------------------------------------------------------------------------
Signal Name | Direction (from RPi) | Wire Color | RPi BCM GPIO | RPi Physical Pin | Basys 3 PMOD Pin
--------------------------------------------------------------------------------
PMOD JB: Read Data Bus (rdata[7:0] - RPi Inputs from FPGA) [Top Zone]
-- JB Top (5-wire bundle: Pins 40, 38, 36, 34[GND], 32) --
rdata[0]    | Input                | Black      | GPIO 21      | Pin 40           | JB1 (A14)
rdata[1]    | Input                | White      | GPIO 20      | Pin 38           | JB2 (A16)
rdata[2]    | Input                | Gray       | GPIO 16      | Pin 36           | JB3 (B15)
GND         | Ground Reference     | Blue       | GND          | Pin 34           | JB5 (GND)
rdata[3]    | Input                | Purple     | GPIO 12      | Pin 32           | JB4 (B16)
-- JB Bottom (4-wire bundle: Pins 35, 33, 31, 29) --
rdata[4]    | Input                | Brown      | GPIO 19      | Pin 35           | JB7 (A15)
rdata[5]    | Input                | Red        | GPIO 13      | Pin 33           | JB8 (A17)
rdata[6]    | Input                | Orange     | GPIO 6       | Pin 31           | JB9 (C15)
rdata[7]    | Input                | Yellow     | GPIO 5       | Pin 29           | JB10 (C16)
--------------------------------------------------------------------------------
PMOD JC: Control Clocks, Resets & Flags [Middle Zone]
-- JC Top Row (5-wire bundle: Pins 26, 24, 22, 20[GND], 18) --
winc        | Output (Write Enable)| Black      | GPIO 7       | Pin 26           | JC1 (K17)
rinc        | Output (Read Enable) | White      | GPIO 8       | Pin 24           | JC2 (M18)
wrst_n      | Output (Write Reset) | Gray       | GPIO 25      | Pin 22           | JC3 (N17)
GND         | Ground Reference     | Blue       | GND          | Pin 20           | JC5 (GND)
rrst_n      | Output (Read Reset)  | Purple     | GPIO 24      | Pin 18           | JC4 (P18)
-- JC Bottom Row (4-wire bundle: Pins 21, 19, 15, 13) --
wclk        | Output (Write Clock) | Brown      | GPIO 9       | Pin 21           | JC7 (L17)
rclk        | Output (Read Clock)  | Red        | GPIO 10      | Pin 19           | JC8 (M19)
wfull       | Input (Full Flag)    | Orange     | GPIO 22      | Pin 15           | JC9 (P17)
rempty      | Input (Empty Flag)   | Yellow     | GPIO 27      | Pin 13           | JC10 (R18)
--------------------------------------------------------------------------------
PMOD JA: Write Data Bus (wdata[7:0] - RPi Outputs to FPGA) [Bottom Zone]
-- JA Top (5-wire bundle: Pins 16, 14[GND], 12, 10, 8) --
wdata[0]    | Output               | Black      | GPIO 23      | Pin 16           | JA1 (J1)
GND         | Ground Reference     | Blue       | GND          | Pin 14           | JA5 (GND)
wdata[1]    | Output               | White      | GPIO 18      | Pin 12           | JA2 (L2)
wdata[2]    | Output               | Gray       | GPIO 15      | Pin 10           | JA3 (J2)
wdata[3]    | Output               | Purple     | GPIO 14      | Pin 8            | JA4 (G2)
-- JA Bottom (4-wire bundle: Pins 11, 7, 5, 3) --
wdata[4]    | Output               | Brown      | GPIO 17      | Pin 11           | JA7 (H1)
wdata[5]    | Output               | Red        | GPIO 4       | Pin 7            | JA8 (K2)
wdata[6]    | Output               | Orange     | GPIO 3       | Pin 5            | JA9 (H2)
wdata[7]    | Output               | Yellow     | GPIO 2       | Pin 3            | JA10 (G3)
================================================================================
"""

import sys
import time
import argparse
import random

# Check for Raspberry Pi hardware environment
try:
    import RPi.GPIO as GPIO
    HARDWARE_AVAILABLE = True
except (ImportError, RuntimeError):
    HARDWARE_AVAILABLE = False


# ==============================================================================
# Pin Definitions (Broadcom / BCM Numbering) - Clean Parallel Rails (JB -> JC -> JA)
# ==============================================================================
# PMOD JB: Read Data Bus (Top Zone, near Pin 40)
# JB Top (5-wire bundle with GND): Pins 40, 38, 36, 32 (GND on Pin 34)
# JB Bottom (4-wire bundle): Pins 35, 33, 31, 29
PIN_RDATA  = [21, 20, 16, 12, 19, 13, 6, 5]   # rdata[0..7]

# PMOD JC: Control, Resets & Clocks (Middle Zone)
# JC Top (5-wire bundle with GND): Pins 26, 24, 22, 18 (GND on Pin 20)
PIN_WINC   = 7    # JC1: Pin 26 (GPIO 7)
PIN_RINC   = 8    # JC2: Pin 24 (GPIO 8)
PIN_WRST_N = 25   # JC3: Pin 22 (GPIO 25)
PIN_RRST_N = 24   # JC4: Pin 18 (GPIO 24)

# PMOD JC Bottom Row: Clocks & Status Flags (4-wire bundle: Pins 21, 19, 15, 13)
PIN_WCLK   = 9    # JC7:  Pin 21 (GPIO 9)
PIN_RCLK   = 10   # JC8:  Pin 19 (GPIO 10)
PIN_WFULL  = 22   # JC9:  Pin 15 (GPIO 22)
PIN_REMPTY = 27   # JC10: Pin 13 (GPIO 27)

# PMOD JA: Write Data Bus (Bottom Zone, near Pin 1)
# JA Top (5-wire bundle with GND): Pins 16, 12, 10, 8 (GND on Pin 14)
# JA Bottom (4-wire bundle): Pins 11, 7, 5, 3
PIN_WDATA  = [23, 18, 15, 14, 17, 4, 3, 2]  # wdata[0..7]


# ==============================================================================
# Mock Hardware Class (For testing without a physical Raspberry Pi)
# ==============================================================================
class MockFIFO:
    """Simulates the FPGA FIFO in software when running on a PC without GPIOs."""
    def __init__(self, depth=16):
        self.depth = depth
        self.queue = []
        self.wdata = 0
        self.rdata = 0
        self.winc = 0
        self.rinc = 0
        self.wrst_n = 1
        self.rrst_n = 1

    def tick_write(self):
        if not self.wrst_n:
            self.queue.clear()
            return
        if self.winc and len(self.queue) < self.depth:
            self.queue.append(self.wdata)

    def tick_read(self):
        if not self.rrst_n:
            self.rdata = 0
            return
        if self.rinc and len(self.queue) > 0:
            self.rdata = self.queue.pop(0)

    @property
    def wfull(self):
        return 1 if len(self.queue) >= self.depth else 0

    @property
    def rempty(self):
        return 1 if len(self.queue) == 0 else 0


# ==============================================================================
# Hardware Controller Class
# ==============================================================================
class FIFOTester:
    def __init__(self, mock=False, clock_delay=0.0001, step_delay=0.5):
        self.mock = mock
        self.clock_delay = clock_delay  # Half-period delay (seconds)
        self.step_delay = step_delay    # Visual pause between bytes for LEDs (seconds)

        if self.mock:
            print("[INFO] Initialized in MOCK simulation mode (no hardware required).")
            self.sim = MockFIFO(depth=16)
        else:
            print("[INFO] Initialized in REAL HARDWARE mode (RPi.GPIO).")
            GPIO.setmode(GPIO.BCM)
            GPIO.setwarnings(False)

            # Setup Output pins
            for pin in PIN_WDATA:
                GPIO.setup(pin, GPIO.OUT, initial=GPIO.LOW)
            GPIO.setup(PIN_WINC,   GPIO.OUT, initial=GPIO.LOW)
            GPIO.setup(PIN_WCLK,   GPIO.OUT, initial=GPIO.LOW)
            GPIO.setup(PIN_WRST_N, GPIO.OUT, initial=GPIO.HIGH)

            GPIO.setup(PIN_RINC,   GPIO.OUT, initial=GPIO.LOW)
            GPIO.setup(PIN_RCLK,   GPIO.OUT, initial=GPIO.LOW)
            GPIO.setup(PIN_RRST_N, GPIO.OUT, initial=GPIO.HIGH)

            # Setup Input pins (Flags and Read Data)
            for pin in PIN_RDATA:
                GPIO.setup(pin, GPIO.IN)
            GPIO.setup(PIN_WFULL,  GPIO.IN)
            GPIO.setup(PIN_REMPTY, GPIO.IN)

    def cleanup(self):
        if not self.mock:
            GPIO.cleanup()

    # --- Low-Level Bus Operations ---
    def pulse_wclk(self):
        if self.mock:
            self.sim.tick_write()
        else:
            time.sleep(self.clock_delay)
            GPIO.output(PIN_WCLK, GPIO.HIGH)
            time.sleep(self.clock_delay)
            GPIO.output(PIN_WCLK, GPIO.LOW)

    def pulse_rclk(self):
        if self.mock:
            self.sim.tick_read()
        else:
            time.sleep(self.clock_delay)
            GPIO.output(PIN_RCLK, GPIO.HIGH)
            time.sleep(self.clock_delay)
            GPIO.output(PIN_RCLK, GPIO.LOW)

    def read_flags(self):
        if self.mock:
            return self.sim.wfull, self.sim.rempty
        else:
            wfull = GPIO.input(PIN_WFULL)
            rempty = GPIO.input(PIN_REMPTY)
            return wfull, rempty

    def pulse_reset(self, hold_cycles=4):
        """Pulls wrst_n and rrst_n low asynchronously, pulses clocks, and restores high."""
        if self.mock:
            self.sim.wrst_n = 0
            self.sim.rrst_n = 0
            self.sim.tick_write()
            self.sim.tick_read()
            self.sim.wrst_n = 1
            self.sim.rrst_n = 1
        else:
            GPIO.output(PIN_WRST_N, GPIO.LOW)
            GPIO.output(PIN_RRST_N, GPIO.LOW)
            GPIO.output(PIN_WINC, GPIO.LOW)
            GPIO.output(PIN_RINC, GPIO.LOW)
            for _ in range(hold_cycles):
                self.pulse_wclk()
                self.pulse_rclk()
            GPIO.output(PIN_WRST_N, GPIO.HIGH)
            GPIO.output(PIN_RRST_N, GPIO.HIGH)
            for _ in range(hold_cycles):
                self.pulse_wclk()
                self.pulse_rclk()

    def reset_fifo(self):
        """Asserts asynchronous active-low resets, cycles clocks, and releases."""
        print("  -> Asserting Reset (active-low)...")
        self.pulse_reset(hold_cycles=4)

    def write_byte(self, value):
        """Drives wdata bus, pulses winc, clocks wclk, and runs background rclk cycles for CDC."""
        val = value & 0xFF
        if self.mock:
            self.sim.wdata = val
            self.sim.winc = 1
            self.sim.tick_write()
            self.sim.winc = 0
            # Background read clock cycles so CDC synchronizer propagates pointer
            for _ in range(4):
                self.sim.tick_read()
        else:
            for i in range(8):
                bit = (val >> i) & 1
                GPIO.output(PIN_WDATA[i], bit)
            GPIO.output(PIN_WINC, GPIO.HIGH)
            self.pulse_wclk()
            GPIO.output(PIN_WINC, GPIO.LOW)
            # Simulate free-running read clock in the background (4 cycles for 2-stage CDC sync)
            for _ in range(4):
                self.pulse_rclk()
        if self.step_delay > 0:
            time.sleep(self.step_delay)

    def read_byte(self):
        """Pulses rinc, clocks rclk, reads rdata bus, and runs background wclk cycles for CDC."""
        if self.mock:
            self.sim.rinc = 1
            self.sim.tick_read()
            self.sim.rinc = 0
            val = self.sim.rdata
            # Background write clock cycles so CDC synchronizer propagates pointer
            for _ in range(4):
                self.sim.tick_write()
        else:
            GPIO.output(PIN_RINC, GPIO.HIGH)
            self.pulse_rclk()
            GPIO.output(PIN_RINC, GPIO.LOW)
            # Sample rdata bus
            val = 0
            for i in range(8):
                bit = GPIO.input(PIN_RDATA[i])
                val |= (bit << i)
            # Simulate free-running write clock in the background (4 cycles for 2-stage CDC sync)
            for _ in range(4):
                self.pulse_wclk()
        if self.step_delay > 0:
            time.sleep(self.step_delay)
        return val


# ==============================================================================
# Comprehensive Test Suite
# ==============================================================================
# ==============================================================================
# Basic Sanity Test Suite (Tests 1 to 5)
# ==============================================================================
def run_basic_tests(tester):
    print("\n" + "=" * 65)
    print("      ASYNCHRONOUS FIFO BASIC HARDWARE SANITY SUITE")
    print("=" * 65)

    # --------------------------------------------------------------------------
    # TEST 1: Reset and Initial State Check
    # --------------------------------------------------------------------------
    print("\n[TEST 1] Power-On Reset & Initial Flag Verification")
    tester.reset_fifo()
    wfull, rempty = tester.read_flags()
    print(f"  -> Flags observed: wfull={wfull}, rempty={rempty}")
    assert rempty == 1, f"FAIL: FIFO should be EMPTY after reset! (rempty={rempty})"
    assert wfull == 0, f"FAIL: FIFO should NOT be FULL after reset! (wfull={wfull})"
    print("  [PASS] Test 1 passed: FIFO starts cleanly empty.")

    # --------------------------------------------------------------------------
    # TEST 2: Single Write and Single Read
    # --------------------------------------------------------------------------
    print("\n[TEST 2] Single Byte Write & Read Loopback")
    test_byte = 0xA5
    print(f"  -> Writing byte: 0x{test_byte:02X}")
    tester.write_byte(test_byte)

    wfull, rempty = tester.read_flags()
    print(f"  -> Post-write flags: wfull={wfull}, rempty={rempty}")
    assert rempty == 0, "FAIL: FIFO should NOT be empty after write!"

    read_val = tester.read_byte()
    print(f"  -> Read back byte: 0x{read_val:02X}")
    assert read_val == test_byte, f"FAIL: Data mismatch! Expected 0x{test_byte:02X}, got 0x{read_val:02X}"

    wfull, rempty = tester.read_flags()
    print(f"  -> Post-read flags: wfull={wfull}, rempty={rempty}")
    assert rempty == 1, "FAIL: FIFO should be EMPTY after reading last byte!"
    print("  [PASS] Test 2 passed: Single byte loopback verified.")

    # --------------------------------------------------------------------------
    # TEST 3: Burst Write to Full (Depth = 16)
    # --------------------------------------------------------------------------
    print("\n[TEST 3] Burst Write to Capacity (FIFO Depth = 16)")
    test_pattern = [0x10 + i for i in range(16)]
    print(f"  -> Writing 16 bytes: {[hex(b) for b in test_pattern]}")

    for idx, byte_val in enumerate(test_pattern):
        wfull, rempty = tester.read_flags()
        assert wfull == 0, f"FAIL: Premature wfull at byte {idx}!"
        tester.write_byte(byte_val)
        wfull_now, rempty_now = tester.read_flags()
        status_led = " [LED[0] FULL ON!]" if wfull_now else (" [LED[1] EMPTY OFF]" if not rempty_now else "")
        print(f"    [{idx+1:2d}/16] Wrote 0x{byte_val:02X} -> Flags: empty={rempty_now}, full={wfull_now}{status_led}")

    # Synchronizer settling cycles across CDC
    for _ in range(4):
        tester.pulse_wclk()
        tester.pulse_rclk()

    wfull, rempty = tester.read_flags()
    print(f"  -> Flags after 16 writes: wfull={wfull}, rempty={rempty}")
    assert wfull == 1, f"FAIL: FIFO must assert wfull after 16 writes! (wfull={wfull})"
    assert rempty == 0, f"FAIL: FIFO should NOT be empty after 16 writes! (rempty={rempty})"
    print("  [PASS] Test 3 passed: FIFO successfully filled to depth 16.")

    # --------------------------------------------------------------------------
    # TEST 4: Overflow Protection
    # --------------------------------------------------------------------------
    print("\n[TEST 4] Overflow Protection (Attempt Write on Full)")
    tester.write_byte(0xFF)  # Attempt write to full FIFO
    wfull, rempty = tester.read_flags()
    assert wfull == 1, "FAIL: FIFO dropped full flag after overflow attempt!"
    assert rempty == 0, "FAIL: FIFO should NOT be empty while full!"
    print("  [PASS] Test 4 passed: Full flag remained asserted, pointer protected.")

    # --------------------------------------------------------------------------
    # TEST 5: Burst Read & Strict Data Integrity Check
    # --------------------------------------------------------------------------
    print("\n[TEST 5] Burst Read & Data Integrity Verification (Watch LEDs[15:8] change!)")
    received = []
    for idx in range(16):
        data = tester.read_byte()
        received.append(data)
        bin_str = f"{data:08b}"
        wfull_now, rempty_now = tester.read_flags()
        status_led = " [LED[1] EMPTY ON!]" if rempty_now else (" [LED[0] FULL OFF]" if not wfull_now and idx == 0 else "")
        print(f"    [{idx+1:2d}/16] Read 0x{data:02X} -> LEDs[15:8]: {bin_str} | Flags: empty={rempty_now}, full={wfull_now}{status_led}")

    print(f"  -> Received sequence: {[hex(b) for b in received]}")
    assert received == test_pattern, f"FAIL: Data corrupted! Expected {test_pattern}, got {received}"

    wfull, rempty = tester.read_flags()
    print(f"  -> Flags after burst read: wfull={wfull}, rempty={rempty} [LED[1] EMPTY ON!]")
    assert rempty == 1, "FAIL: FIFO should be EMPTY after reading all 16 bytes!"
    assert wfull == 0, "FAIL: FIFO should NOT be FULL after reading!"
    print("  [PASS] Test 5 passed: All 16 bytes matched byte-for-byte in exact FIFO order!")


# ==============================================================================
# Advanced UVM-Equivalent Hardware Verification Suite (Phases 1 to 4)
# ==============================================================================
def run_uvm_suite(tester, num_transactions=40):
    print("\n" + "=" * 65)
    print("       ADVANCED UVM-EQUIVALENT HARDWARE VERIFICATION SUITE")
    print("=" * 65)

    # --------------------------------------------------------------------------
    # UVM PHASE 1: Concurrent Random Traffic & Real-Time Scoreboard
    # --------------------------------------------------------------------------
    print("\n[UVM PHASE 1] Concurrent Random Traffic & Real-Time Scoreboard (w_seq & r_seq)")
    print(f"  -> Injecting {num_transactions} randomized read/write interleaved transactions...")
    tester.reset_fifo()
    scoreboard = []
    writes_done = 0
    reads_done = 0

    for step in range(num_transactions):
        wfull, rempty = tester.read_flags()

        # Build valid action set based on hardware flag state
        possible_actions = []
        if not wfull:
            possible_actions.append("write")
        if not rempty and len(scoreboard) > 0:
            possible_actions.append("read")
        if not wfull and not rempty and len(scoreboard) > 0:
            possible_actions.append("both")

        action = random.choice(possible_actions) if possible_actions else "write"

        if action in ("write", "both"):
            byte_val = random.randint(0x00, 0xFF)
            tester.write_byte(byte_val)
            scoreboard.append(byte_val)
            writes_done += 1
            w_now, _ = tester.read_flags()
            print(f"    [Step {step+1:3d}] WROTE 0x{byte_val:02X} | Scoreboard Depth: {len(scoreboard):2d} | Flags: full={w_now}")

        if action in ("read", "both") and len(scoreboard) > 0:
            read_val = tester.read_byte()
            expected_val = scoreboard.pop(0)
            reads_done += 1
            _, r_now = tester.read_flags()
            print(f"    [Step {step+1:3d}] READ  0x{read_val:02X} (Exp: 0x{expected_val:02X}) | Scoreboard Depth: {len(scoreboard):2d} | Flags: empty={r_now}")
            assert read_val == expected_val, f"SCOREBOARD MISMATCH! Expected 0x{expected_val:02X}, got 0x{read_val:02X}"

    # Drain any remaining bytes from Scoreboard
    if scoreboard:
        print(f"  -> Draining remaining {len(scoreboard)} bytes from Scoreboard...")
        while scoreboard:
            expected_val = scoreboard.pop(0)
            read_val = tester.read_byte()
            reads_done += 1
            assert read_val == expected_val, f"DRAIN MISMATCH! Expected 0x{expected_val:02X}, got 0x{read_val:02X}"

    wfull_end, rempty_end = tester.read_flags()
    assert rempty_end == 1, "FAIL: FIFO should be empty after scoreboard drain!"
    print(f"  [PASS] UVM Phase 1: Completed {writes_done} writes, {reads_done} reads with 100% Scoreboard match (0 drops, 0 mismatches)!")

    # --------------------------------------------------------------------------
    # UVM PHASE 2: Dynamic Burst Until Full (w_burst_seq)
    # --------------------------------------------------------------------------
    print("\n[UVM PHASE 2] Dynamic Burst Until Full (w_burst_seq)")
    tester.reset_fifo()
    burst_data = []
    count = 0
    max_limit = 25
    while count < max_limit:
        wfull, _ = tester.read_flags()
        if wfull:
            print(f"  -> Hardware 'wfull' asserted after exactly {count} bytes written!")
            break
        byte_val = (0x40 + count) & 0xFF
        tester.write_byte(byte_val)
        burst_data.append(byte_val)
        count += 1

    assert count == 16, f"FAIL: Expected FIFO to fill at depth 16, but took {count} bytes!"
    wfull, rempty = tester.read_flags()
    assert wfull == 1 and rempty == 0, f"FAIL: Invalid flags after fill (wfull={wfull}, rempty={rempty})"
    print("  [PASS] UVM Phase 2: Burst fill stopped dynamically on hardware wfull at depth 16.")

    # --------------------------------------------------------------------------
    # UVM PHASE 3: Dynamic Drain Until Empty (r_drain_seq)
    # --------------------------------------------------------------------------
    print("\n[UVM PHASE 3] Dynamic Drain Until Empty (r_drain_seq)")
    drained_data = []
    drain_count = 0
    while drain_count < max_limit:
        _, rempty = tester.read_flags()
        if rempty:
            print(f"  -> Hardware 'rempty' asserted after exactly {drain_count} bytes read!")
            break
        val = tester.read_byte()
        drained_data.append(val)
        drain_count += 1

    assert drain_count == 16, f"FAIL: Expected FIFO to drain in exactly 16 bytes, took {drain_count}!"
    assert drained_data == burst_data, "FAIL: Data order mismatch during dynamic drain!"
    wfull, rempty = tester.read_flags()
    assert rempty == 1 and wfull == 0, f"FAIL: Invalid flags after drain (wfull={wfull}, rempty={rempty})"
    print("  [PASS] UVM Phase 3: Drain completed with 100% data order and flag fidelity.")

    # --------------------------------------------------------------------------
    # UVM PHASE 4: Mid-Traffic Asynchronous Reset Recovery (fifo_reset_recovery_test)
    # --------------------------------------------------------------------------
    print("\n[UVM PHASE 4] Mid-Traffic Asynchronous Reset Recovery (fifo_reset_recovery_test)")
    print("  -> Step 1: Pre-reset active traffic spree (writing 9 bytes into FIFO)...")
    for i in range(9):
        tester.write_byte(0x60 + i)

    wfull_pre, rempty_pre = tester.read_flags()
    print(f"  -> State before reset: wfull={wfull_pre}, rempty={rempty_pre} (FIFO contains 9 bytes)")
    assert rempty_pre == 0, "FIFO should not be empty!"

    print("  -> Step 2: Injecting asynchronous reset mid-traffic (wrst_n=0, rrst_n=0)...")
    tester.pulse_reset(hold_cycles=5)

    wfull_post, rempty_post = tester.read_flags()
    print(f"  -> State after reset: wfull={wfull_post}, rempty={rempty_post} [LED[1] EMPTY ON!]")
    assert rempty_post == 1, "FAIL: FIFO did not return to EMPTY after asynchronous reset!"
    assert wfull_post == 0, "FAIL: FIFO reported full after reset!"

    print("  -> Step 3: Post-reset recovery verification (verifying clean restart with zero lockup)...")
    recovery_pattern = [0x80 + i for i in range(16)]
    for b in recovery_pattern:
        tester.write_byte(b)
    wfull_rec, rempty_rec = tester.read_flags()
    assert wfull_rec == 1 and rempty_rec == 0, "FAIL: FIFO failed to fill after reset recovery!"

    recovered = [tester.read_byte() for _ in range(16)]
    assert recovered == recovery_pattern, "FAIL: Post-reset data corrupted!"
    wfull_end, rempty_end = tester.read_flags()
    assert rempty_end == 1, "FAIL: FIFO did not return to empty after post-reset drain!"
    print("  [PASS] UVM Phase 4: Asynchronous reset mid-traffic recovered flawlessly with zero lockup!")

    print("\n" + "=" * 65)
    print("  ALL 4 UVM-EQUIVALENT PHASES COMPLETED WITH 100% HARDWARE SUCCESS! ")
    print("=" * 65 + "\n")


# ==============================================================================
# Main Entry Point
# ==============================================================================
def main():
    parser = argparse.ArgumentParser(description="Raspberry Pi Basys 3 FIFO Tester & UVM Hardware Suite")
    parser.add_argument("--mock", action="store_true", help="Force mock simulation mode (no GPIO hardware)")
    parser.add_argument("--mode", choices=["all", "basic", "uvm"], default="all", help="Test mode to run: 'basic', 'uvm', or 'all' (default: all)")
    parser.add_argument("--transactions", type=int, default=40, help="Number of randomized transactions in UVM Phase 1 (default: 40)")
    parser.add_argument("--delay", type=float, default=0.15, help="Step delay in seconds between byte operations to watch onboard LEDs in real-time (default: 0.15s)")
    args = parser.parse_args()

    use_mock = args.mock or (not HARDWARE_AVAILABLE)

    if not HARDWARE_AVAILABLE and not args.mock:
        print("[NOTICE] RPi.GPIO not detected on this system. Running automatically in --mock mode.\n")

    tester = FIFOTester(mock=use_mock, step_delay=args.delay)
    try:
        if args.mode in ("all", "basic"):
            run_basic_tests(tester)
        if args.mode in ("all", "uvm"):
            run_uvm_suite(tester, num_transactions=args.transactions)
    finally:
        tester.cleanup()


if __name__ == "__main__":
    main()
