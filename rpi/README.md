# Raspberry Pi & Basys 3 Hardware-in-the-Loop Setup Guide

This guide details how to wire and test your **Asynchronous Dual-Clock FIFO** implemented on the **Digilent Basys 3 FPGA** using a **Raspberry Pi** as the automated master test controller.

---

## 1. Safety & Voltage Compatibility

> [!IMPORTANT]
> **Logic Level Compatibility**:
> * **Raspberry Pi GPIOs**: 3.3V LVCMOS
> * **Digilent Basys 3 PMODs**: 3.3V LVCMOS (`IOSTANDARD LVCMOS33`)
> * **Result**: 100% directly compatible! **No level-shifter chips are required.**
>
> **CRITICAL RULE: COMMON GROUND**
> You **MUST** connect at least one Ground pin from the Raspberry Pi (e.g., Pin 6 or 14) to the Basys 3 PMOD Ground (Pin 5 or 11 on any PMOD header). Without a common electrical ground, signal readings will float and corrupt data!

---

## 2. Complete Wiring Table

Connect 25 female-to-female jumper wires between the **Raspberry Pi 40-pin header** and the **Basys 3 PMOD connectors**:

### Power & Ground
| Signal | Raspberry Pi Pin | Basys 3 Header |
| :--- | :--- | :--- |
| **GND (Ground)** | **Pin 6, 9, 14, 20, 25, 30, or 34** | **PMOD JC Pin 5 (or Pin 11)** |

---

### PMOD JA: 8-bit Write Data Bus (`wdata[7:0]`)
*RPi drives data into the FIFO.*

| Signal | RPi BCM Name | RPi Physical Pin | Basys 3 Pin | FPGA Ball |
| :--- | :--- | :--- | :--- | :--- |
| `wdata[0]` | GPIO 2  | Pin 3  | JA1  | J1 |
| `wdata[1]` | GPIO 3  | Pin 5  | JA2  | L2 |
| `wdata[2]` | GPIO 4  | Pin 7  | JA3  | J2 |
| `wdata[3]` | GPIO 14 | Pin 8  | JA4  | G2 |
| `wdata[4]` | GPIO 15 | Pin 10 | JA7  | H1 |
| `wdata[5]` | GPIO 17 | Pin 11 | JA8  | K2 |
| `wdata[6]` | GPIO 18 | Pin 12 | JA9  | H2 |
| `wdata[7]` | GPIO 27 | Pin 13 | JA10 | G3 |

---

### PMOD JB: 8-bit Read Data Bus (`rdata[7:0]`)
*FPGA drives data out to RPi.*

| Signal | RPi BCM Name | RPi Physical Pin | Basys 3 Pin | FPGA Ball |
| :--- | :--- | :--- | :--- | :--- |
| `rdata[0]` | GPIO 22 | Pin 15 | JB1  | A14 |
| `rdata[1]` | GPIO 23 | Pin 16 | JB2  | A16 |
| `rdata[2]` | GPIO 24 | Pin 18 | JB3  | B15 |
| `rdata[3]` | GPIO 10 | Pin 19 | JB4  | B16 |
| `rdata[4]` | GPIO 9  | Pin 21 | JB7  | A15 |
| `rdata[5]` | GPIO 25 | Pin 22 | JB8  | A17 |
| `rdata[6]` | GPIO 11 | Pin 23 | JB9  | C15 |
| `rdata[7]` | GPIO 8  | Pin 24 | JB10 | C16 |

---

### PMOD JC: Clocks, Enables & Flags
*Control signals between RPi and FPGA.*

#### Top Row (Pins 1..4: Enables & Resets):
| Signal | Direction (from RPi) | RPi BCM Name | RPi Physical Pin | Basys 3 Pin | FPGA Ball |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `winc`   | Output (Write Enable) | GPIO 7  | Pin 26 | JC1 | K17 |
| `rinc`   | Output (Read Enable)  | GPIO 13 | Pin 33 | JC2 | M18 |
| `wrst_n` | Output (Write Reset)  | GPIO 6  | Pin 31 | JC3 | N17 |
| `rrst_n` | Output (Read Reset)   | GPIO 26 | Pin 37 | JC4 | P18 |

#### Bottom Row (Pins 7..10: Clocks & Flags):
| Signal | Direction (from RPi) | RPi BCM Name | RPi Physical Pin | Basys 3 Pin | FPGA Ball |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `wclk`   | Output (Write Clock)  | GPIO 5  | Pin 29 | JC7  | L17 |
| `rclk`   | Output (Read Clock)   | GPIO 19 | Pin 35 | JC8  | M19 |
| `wfull`  | Input (Full Flag)     | GPIO 12 | Pin 32 | JC9  | P17 |
| `rempty` | Input (Empty Flag)    | GPIO 16 | Pin 36 | JC10 | R18 |

---

## 3. Running the Test on the Raspberry Pi

1. Copy [`rpi_fifo_tester.py`](rpi_fifo_tester.py) to your Raspberry Pi:
   ```bash
   scp rpi/rpi_fifo_tester.py pi@<raspberry-pi-ip>:~/
   ```

2. On the Raspberry Pi, make sure the GPIO library is installed:
   ```bash
   sudo apt update
   sudo apt install -y python3-rpi.gpio
   ```

3. Power up the **Basys 3** and program it with the generated bitstream (`basys3_fifo_top.bit`).
   - You should see **`LED[1]`** light up on the board (indicating the FIFO is initialized as **EMPTY**).

4. Run the automated hardware test suite on the Raspberry Pi:
   ```bash
   python3 rpi_fifo_tester.py
   ```

### What the test performs:
- **Test 1**: Asserts asynchronous reset and checks that `rempty == 1` and `wfull == 0`.
- **Test 2**: Writes a single byte (`0xA5`), verifies `rempty` drops to `0`, reads it back, verifies byte-for-byte equality, and checks that `rempty` goes back to `1`.
- **Test 3**: Burst-writes 16 consecutive test bytes (`0x10..0x1F`) to completely fill the FIFO and asserts `wfull == 1` (`LED[0]` turns on!).
- **Test 4**: Attempts an illegal write when full to verify **overflow protection**.
- **Test 5**: Burst-reads all 16 bytes back, verifies strict FIFO ordering, and confirms `rempty` asserts and `wfull` deasserts.
