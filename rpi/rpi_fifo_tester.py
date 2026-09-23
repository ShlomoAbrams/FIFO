#!/usr/bin/env python3
"""
================================================================================
Raspberry Pi Hardware-in-the-Loop Testbench for Basys 3 Dual-Clock FIFO
================================================================================

This script runs on a Raspberry Pi connected via jumper wires to a Digilent Basys 3
FPGA running the Asynchronous FIFO bitstream.

WIRING TABLE (Raspberry Pi 40-Pin Header <---> Basys 3 PMOD Headers):
--------------------------------------------------------------------------------
Signal Name | Direction (from RPi) | RPi BCM GPIO | RPi Physical Pin | Basys 3 PMOD Pin
--------------------------------------------------------------------------------
COMMON GROUND (MANDATORY):
GND         | Reference            | GND          | Pin 6, 9, or 14  | PMOD JC Pin 5 or 11
--------------------------------------------------------------------------------
PMOD JA: Write Data Bus (wdata[7:0] - RPi Outputs to FPGA)
wdata[0]    | Output               | GPIO 2       | Pin 3            | JA1 (J1)
wdata[1]    | Output               | GPIO 3       | Pin 5            | JA2 (L2)
wdata[2]    | Output               | GPIO 4       | Pin 7            | JA3 (J2)
wdata[3]    | Output               | GPIO 14      | Pin 8            | JA4 (G2)
wdata[4]    | Output               | GPIO 15      | Pin 10           | JA7 (H1)
wdata[5]    | Output               | GPIO 17      | Pin 11           | JA8 (K2)
wdata[6]    | Output               | GPIO 18      | Pin 12           | JA9 (H2)
wdata[7]    | Output               | GPIO 27      | Pin 13           | JA10 (G3)
--------------------------------------------------------------------------------
PMOD JB: Read Data Bus (rdata[7:0] - RPi Inputs from FPGA)
rdata[0]    | Input                | GPIO 22      | Pin 15           | JB1 (A14)
rdata[1]    | Input                | GPIO 23      | Pin 16           | JB2 (A16)
rdata[2]    | Input                | GPIO 24      | Pin 18           | JB3 (B15)
rdata[3]    | Input                | GPIO 10      | Pin 19           | JB4 (B16)
rdata[4]    | Input                | GPIO 9       | Pin 21           | JB7 (A15)
rdata[5]    | Input                | GPIO 25      | Pin 22           | JB8 (A17)
rdata[6]    | Input                | GPIO 11      | Pin 23           | JB9 (C15)
rdata[7]    | Input                | GPIO 8       | Pin 24           | JB10 (C16)
--------------------------------------------------------------------------------
PMOD JC: Control Clocks, Resets & Flags
Top Row (Enables & Resets):
winc        | Output               | GPIO 7       | Pin 26           | JC1 (K17)
rinc        | Output               | GPIO 13      | Pin 33           | JC2 (M18)
wrst_n      | Output               | GPIO 6       | Pin 31           | JC3 (N17)
rrst_n      | Output               | GPIO 26      | Pin 37           | JC4 (P18)
Bottom Row (Clocks & Flags):
wclk        | Output               | GPIO 5       | Pin 29           | JC7 (L17)
rclk        | Output               | GPIO 19      | Pin 35           | JC8 (M19)
wfull       | Input                | GPIO 12      | Pin 32           | JC9 (P17)
rempty      | Input                | GPIO 16      | Pin 36           | JC10 (R18)
================================================================================
"""

import sys
import time
import argparse

# Check for Raspberry Pi hardware environment
try:
    import RPi.GPIO as GPIO
    HARDWARE_AVAILABLE = True
except (ImportError, RuntimeError):
    HARDWARE_AVAILABLE = False


# ==============================================================================
# Pin Definitions (Broadcom / BCM Numbering)
# ==============================================================================
PIN_WDATA  = [2, 3, 4, 14, 15, 17, 18, 27]   # wdata[0..7] (Outputs)
PIN_RDATA  = [22, 23, 24, 10, 9, 25, 11, 8]  # rdata[0..7] (Inputs)

# PMOD JC Top Row: Enables & Resets
PIN_WINC   = 7    # JC1: Write enable (Output)
PIN_RINC   = 13   # JC2: Read enable (Output)
PIN_WRST_N = 6    # JC3: Write reset, active-low (Output)
PIN_RRST_N = 26   # JC4: Read reset, active-low (Output)

# PMOD JC Bottom Row: Clocks & Status Flags
PIN_WCLK   = 5    # JC7: Write clock (Output)
PIN_RCLK   = 19   # JC8: Read clock (Output)
PIN_WFULL  = 12   # JC9: Full flag (Input)
PIN_REMPTY = 16   # JC10: Empty flag (Input)


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
    def __init__(self, mock=False, clock_delay=0.0001):
        self.mock = mock
        self.clock_delay = clock_delay  # Half-period delay (seconds)

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

    def reset_fifo(self):
        """Asserts asynchronous active-low resets, cycles clocks, and releases."""
        print("  -> Asserting Reset (active-low)...")
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
            for _ in range(3):
                self.pulse_wclk()
                self.pulse_rclk()
            GPIO.output(PIN_WRST_N, GPIO.HIGH)
            GPIO.output(PIN_RRST_N, GPIO.HIGH)
            for _ in range(3):
                self.pulse_wclk()
                self.pulse_rclk()

    def write_byte(self, value):
        """Drives wdata bus, pulses winc, and generates a rising wclk edge."""
        val = value & 0xFF
        if self.mock:
            self.sim.wdata = val
            self.sim.winc = 1
            self.sim.tick_write()
            self.sim.winc = 0
        else:
            for i in range(8):
                bit = (val >> i) & 1
                GPIO.output(PIN_WDATA[i], bit)
            GPIO.output(PIN_WINC, GPIO.HIGH)
            self.pulse_wclk()
            GPIO.output(PIN_WINC, GPIO.LOW)

    def read_byte(self):
        """Pulses rinc, clocks rclk, and reads rdata bus."""
        if self.mock:
            self.sim.rinc = 1
            self.sim.tick_read()
            self.sim.rinc = 0
            return self.sim.rdata
        else:
            GPIO.output(PIN_RINC, GPIO.HIGH)
            self.pulse_rclk()
            GPIO.output(PIN_RINC, GPIO.LOW)
            # Sample rdata bus
            val = 0
            for i in range(8):
                bit = GPIO.input(PIN_RDATA[i])
                val |= (bit << i)
            return val


# ==============================================================================
# Comprehensive Test Suite
# ==============================================================================
def run_tests(tester):
    print("\n" + "=" * 60)
    print("      ASYNCHRONOUS FIFO HARDWARE VALIDATION SUITE")
    print("=" * 60)

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
    test_byte = 0xA5  # 10100101
    print(f"  -> Writing byte: 0x{test_byte:02X}")
    tester.write_byte(test_byte)

    # Allow synchronizer 2 clock cycles to update rempty
    for _ in range(3):
        tester.pulse_rclk()

    wfull, rempty = tester.read_flags()
    print(f"  -> Post-write flags: wfull={wfull}, rempty={rempty}")
    assert rempty == 0, "FAIL: FIFO should NOT be empty after write!"

    read_val = tester.read_byte()
    print(f"  -> Read back byte: 0x{read_val:02X}")
    assert read_val == test_byte, f"FAIL: Data mismatch! Expected 0x{test_byte:02X}, got 0x{read_val:02X}"

    # Cycle read clock for synchronizer to reflect empty state
    for _ in range(3):
        tester.pulse_rclk()
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

    # Synchronizer settling cycles
    for _ in range(3):
        tester.pulse_wclk()

    wfull, rempty = tester.read_flags()
    print(f"  -> Flags after 16 writes: wfull={wfull}, rempty={rempty}")
    assert wfull == 1, f"FAIL: FIFO must assert wfull after 16 writes! (wfull={wfull})"
    print("  [PASS] Test 3 passed: FIFO successfully filled to depth 16.")

    # --------------------------------------------------------------------------
    # TEST 4: Overflow Protection
    # --------------------------------------------------------------------------
    print("\n[TEST 4] Overflow Protection (Attempt Write on Full)")
    tester.write_byte(0xFF)  # Attempt write to full FIFO
    wfull, rempty = tester.read_flags()
    assert wfull == 1, "FAIL: FIFO dropped full flag after overflow attempt!"
    print("  [PASS] Test 4 passed: Full flag remained asserted, pointer protected.")

    # --------------------------------------------------------------------------
    # TEST 5: Burst Read & Strict Data Integrity Check
    # --------------------------------------------------------------------------
    print("\n[TEST 5] Burst Read & Data Integrity Verification")
    received = []
    for idx in range(16):
        data = tester.read_byte()
        received.append(data)

    print(f"  -> Received sequence: {[hex(b) for b in received]}")
    assert received == test_pattern, f"FAIL: Data corrupted! Expected {test_pattern}, got {received}"

    # Cycle read clock for empty flag update
    for _ in range(4):
        tester.pulse_rclk()
        tester.pulse_wclk()

    wfull, rempty = tester.read_flags()
    print(f"  -> Flags after burst read: wfull={wfull}, rempty={rempty}")
    assert rempty == 1, "FAIL: FIFO should be EMPTY after reading all 16 bytes!"
    assert wfull == 0, "FAIL: FIFO should NOT be FULL after reading!"
    print("  [PASS] Test 5 passed: All 16 bytes matched byte-for-byte in exact FIFO order!")

    # --------------------------------------------------------------------------
    # SUMMARY
    # --------------------------------------------------------------------------
    print("\n" + "=" * 60)
    print("  ALL 5 HARDWARE VALIDATION TESTS PASSED SUCCESSFULLY! ")
    print("=" * 60 + "\n")


# ==============================================================================
# Main Entry Point
# ==============================================================================
def main():
    parser = argparse.ArgumentParser(description="Raspberry Pi Basys 3 FIFO Tester")
    parser.add_argument("--mock", action="store_true", help="Force mock simulation mode (no GPIO hardware)")
    args = parser.parse_args()

    use_mock = args.mock or (not HARDWARE_AVAILABLE)

    if not HARDWARE_AVAILABLE and not args.mock:
        print("[NOTICE] RPi.GPIO not detected on this system. Running automatically in --mock mode.\n")

    tester = FIFOTester(mock=use_mock)
    try:
        run_tests(tester)
    finally:
        tester.cleanup()


if __name__ == "__main__":
    main()
