## Constraints File (XDC) for Basys 3 Dual-Clock FIFO
## Target Board: Digilent Basys 3 (XC7A35T-1CPG236C)

## =====================================================================
## 1. Clocks & Clock Routing (Asymmetric Dual-Clock STA Constraints)
## =====================================================================
# Because wclk and rclk enter through PMOD GPIO pins, allow standard routing:
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets jc_wclk_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets jc_rclk_IBUF]

# Write clock: 50 MHz (20.0 ns period)
create_clock -period 20.000 -name wclk [get_ports jc_wclk]

# Read clock:  10 MHz (100.0 ns period)
create_clock -period 100.000 -name rclk [get_ports jc_rclk]

# Asynchronous Clock Groups: Disable synchronous STA across CDC boundaries
set_clock_groups -asynchronous \
    -group [get_clocks wclk] \
    -group [get_clocks rclk]

## =====================================================================
## 2. PMOD JA: 8-bit Write Data Bus (wdata[7:0] - Inputs from RPi)
## =====================================================================
set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS33} [get_ports {ja[0]}]; # JA1
set_property -dict {PACKAGE_PIN L2 IOSTANDARD LVCMOS33} [get_ports {ja[1]}]; # JA2
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports {ja[2]}]; # JA3
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports {ja[3]}]; # JA4
set_property -dict {PACKAGE_PIN H1 IOSTANDARD LVCMOS33} [get_ports {ja[4]}]; # JA7
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {ja[5]}]; # JA8
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33} [get_ports {ja[6]}]; # JA9
set_property -dict {PACKAGE_PIN G3 IOSTANDARD LVCMOS33} [get_ports {ja[7]}]; # JA10

## =====================================================================
## 3. PMOD JB: 8-bit Read Data Bus (rdata[7:0] - Outputs to RPi)
## =====================================================================
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports {jb[0]}]; # JB1
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports {jb[1]}]; # JB2
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports {jb[2]}]; # JB3
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports {jb[3]}]; # JB4
set_property -dict {PACKAGE_PIN A15 IOSTANDARD LVCMOS33} [get_ports {jb[4]}]; # JB7
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS33} [get_ports {jb[5]}]; # JB8
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports {jb[6]}]; # JB9
set_property -dict {PACKAGE_PIN C16 IOSTANDARD LVCMOS33} [get_ports {jb[7]}]; # JB10

## =====================================================================
## 4. PMOD JC: Control Clocks, Resets & Status Flags
## =====================================================================
# Top Row: Enables & Resets (Pins 1..4)
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports jc_winc];   # JC1
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports jc_rinc];   # JC2
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33 PULLUP true}   [get_ports jc_wrst_n]; # JC3
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33 PULLUP true}   [get_ports jc_rrst_n]; # JC4

# Bottom Row: Clocks & Status Flags (Pins 7..10)
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33}               [get_ports jc_wclk];   # JC7
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33}               [get_ports jc_rclk];   # JC8
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33}               [get_ports jc_wfull];  # JC9
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33}               [get_ports jc_rempty]; # JC10

## =====================================================================
## 5. On-board Push Button (Center Button BTNC - Manual Reset)
## =====================================================================
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports btnC]

## =====================================================================
## 6. On-board 16 LEDs for Visual Debugging
## =====================================================================
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {led[0]}];  # LD0
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {led[1]}];  # LD1
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {led[2]}];  # LD2
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports {led[3]}];  # LD3
set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {led[4]}];  # LD4
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports {led[5]}];  # LD5
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {led[6]}];  # LD6
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {led[7]}];  # LD7
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {led[8]}];  # LD8
set_property -dict {PACKAGE_PIN V3  IOSTANDARD LVCMOS33} [get_ports {led[9]}];  # LD9
set_property -dict {PACKAGE_PIN W3  IOSTANDARD LVCMOS33} [get_ports {led[10]}]; # LD10
set_property -dict {PACKAGE_PIN U3  IOSTANDARD LVCMOS33} [get_ports {led[11]}]; # LD11
set_property -dict {PACKAGE_PIN P3  IOSTANDARD LVCMOS33} [get_ports {led[12]}]; # LD12
set_property -dict {PACKAGE_PIN N3  IOSTANDARD LVCMOS33} [get_ports {led[13]}]; # LD13
set_property -dict {PACKAGE_PIN P1  IOSTANDARD LVCMOS33} [get_ports {led[14]}]; # LD14
set_property -dict {PACKAGE_PIN L1  IOSTANDARD LVCMOS33} [get_ports {led[15]}]; # LD15

## =====================================================================
## 7. Configuration Voltage & SPI Flash Mode Settings
## =====================================================================
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
