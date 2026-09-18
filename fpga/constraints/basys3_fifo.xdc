## Master Constraints File (XDC) for Basys 3 Dual-Clock FIFO
## Target Board: Digilent Basys 3 (XC7A35T-1CPG236C)

## =====================================================================
## 1. Clocks & Clock Routing (RPi Driven Clocks on PMOD JC)
## =====================================================================
# Because wclk and rclk are driven through PMOD pins, allow standard routing:
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets jc_wclk_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets jc_rclk_IBUF]

# Define 10 MHz nominal clocks for Timing Analysis (100 ns period):
create_clock -period 100.000 -name wclk [get_ports jc_wclk]
create_clock -period 100.000 -name rclk [get_ports jc_rclk]

# Asynchronous Clock Groups: Disable synchronous STA across CDC boundaries
set_clock_groups -asynchronous \
    -group [get_clocks wclk] \
    -group [get_clocks rclk]

## =====================================================================
## 2. PMOD JA: 8-bit Write Data Bus (wdata[7:0] - Inputs from RPi)
## =====================================================================
set_property PACKAGE_PIN J1 [get_ports {ja[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[0]}]

set_property PACKAGE_PIN L2 [get_ports {ja[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[1]}]

set_property PACKAGE_PIN J2 [get_ports {ja[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[2]}]

set_property PACKAGE_PIN G2 [get_ports {ja[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[3]}]

set_property PACKAGE_PIN H1 [get_ports {ja[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[4]}]

set_property PACKAGE_PIN K2 [get_ports {ja[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[5]}]

set_property PACKAGE_PIN H2 [get_ports {ja[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[6]}]

set_property PACKAGE_PIN G3 [get_ports {ja[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja[7]}]

## =====================================================================
## 3. PMOD JB: 8-bit Read Data Bus (rdata[7:0] - Outputs to RPi)
## =====================================================================
set_property PACKAGE_PIN A14 [get_ports {jb[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[0]}]

set_property PACKAGE_PIN A16 [get_ports {jb[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[1]}]

set_property PACKAGE_PIN B15 [get_ports {jb[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[2]}]

set_property PACKAGE_PIN B16 [get_ports {jb[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[3]}]

set_property PACKAGE_PIN A15 [get_ports {jb[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[4]}]

set_property PACKAGE_PIN A17 [get_ports {jb[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[5]}]

set_property PACKAGE_PIN C15 [get_ports {jb[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[6]}]

set_property PACKAGE_PIN C16 [get_ports {jb[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb[7]}]

## =====================================================================
## 4. PMOD JC: Control & Status Flags
## =====================================================================
# JC1: winc (Write Increment)
set_property PACKAGE_PIN K17 [get_ports jc_winc]
set_property IOSTANDARD LVCMOS33 [get_ports jc_winc]
set_property PULLDOWN true [get_ports jc_winc]

# JC2: wclk (Write Clock from RPi)
set_property PACKAGE_PIN M18 [get_ports jc_wclk]
set_property IOSTANDARD LVCMOS33 [get_ports jc_wclk]

# JC3: wrst_n (Write Domain Reset, active low)
set_property PACKAGE_PIN N17 [get_ports jc_wrst_n]
set_property IOSTANDARD LVCMOS33 [get_ports jc_wrst_n]
set_property PULLUP true [get_ports jc_wrst_n]

# JC4: wfull (FIFO Full flag output)
set_property PACKAGE_PIN P18 [get_ports jc_wfull]
set_property IOSTANDARD LVCMOS33 [get_ports jc_wfull]

# JC7: rinc (Read Increment)
set_property PACKAGE_PIN L17 [get_ports jc_rinc]
set_property IOSTANDARD LVCMOS33 [get_ports jc_rinc]
set_property PULLDOWN true [get_ports jc_rinc]

# JC8: rclk (Read Clock from RPi)
set_property PACKAGE_PIN M19 [get_ports jc_rclk]
set_property IOSTANDARD LVCMOS33 [get_ports jc_rclk]

# JC9: rrst_n (Read Domain Reset, active low)
set_property PACKAGE_PIN P17 [get_ports jc_rrst_n]
set_property IOSTANDARD LVCMOS33 [get_ports jc_rrst_n]
set_property PULLUP true [get_ports jc_rrst_n]

# JC10: rempty (FIFO Empty flag output)
set_property PACKAGE_PIN R18 [get_ports jc_rempty]
set_property IOSTANDARD LVCMOS33 [get_ports jc_rempty]

## =====================================================================
## 5. On-board Push Button (Center Button BTNC - Manual Reset)
## =====================================================================
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## =====================================================================
## 6. On-board 16 LEDs for Visual Debugging
## =====================================================================
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]

set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]

set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]

set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]

set_property PACKAGE_PIN V3 [get_ports {led[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]

set_property PACKAGE_PIN W3 [get_ports {led[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]

set_property PACKAGE_PIN U3 [get_ports {led[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]

set_property PACKAGE_PIN P3 [get_ports {led[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]

set_property PACKAGE_PIN N3 [get_ports {led[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]

set_property PACKAGE_PIN P1 [get_ports {led[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]

set_property PACKAGE_PIN L1 [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]

## =====================================================================
## 7. Configuration Voltage & SPI Flash Mode Settings
## =====================================================================
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
