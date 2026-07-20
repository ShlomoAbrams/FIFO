# ==============================================================================
# ModelSim / QuestaSim Simulation Script (run.do)
# Automated compilation, simulation setup, waveform grouping, & coverage reporting
# ==============================================================================

# 1. Force close any running simulation instance
quit -sim

# 2. Clean up previous database, transcript, and waveform files
catch { file delete -force vsim.wlf transcript fifo_cov.ucdb coverage_report.txt covhtmlreport }
catch { foreach f [glob -nocomplain wlft*] { file delete -force $f } }
if [file exists work] { 
    catch { vdel -all -lib work } 
    catch { file delete -force work }
}

# Re-create clean work library
vlib work
vmap work work

# 3. Define UVM Include Paths and Pre-compiled DPI Library Locations
set UVM_SRC "C:/MentorGraphics/MODELSIM/verilog_src/uvm-1.1d/src"
set UVM_DPI "C:/MentorGraphics/MODELSIM/uvm-1.1d/win64/uvm_dpi"
set UVM_INC "+incdir+$UVM_SRC"

# 4. Compile RTL (VHDL files) with Code Coverage enabled (-cover bcesxf)
vcom -reportprogress 300 -2008 -cover bcesxf \
    ../rtl/fifo_mem.vhd ../rtl/fifo_r_ptr.vhd ../rtl/fifo_w_ptr.vhd ../rtl/fifo_synchronizer.vhd ../rtl/fifo.vhd

# 5. Compile UVM Testbench Package WITHOUT code coverage (excludes testbench internals from DUT coverage metrics)
vlog -sv -mfcu $UVM_INC -L mtiUvm ../uvm/fifo_pkg.sv

# 6. Compile SV Interface and Assertions WITH coverage
vlog -sv -mfcu $UVM_INC -cover bcesxf -L mtiUvm \
	../uvm/fifo_if.sv \
	../uvm/fifo_sva.sv

# 7. Compile SV Top Module WITHOUT coverage (keeps testbench initial blocks out of DUT metrics)
vlog -sv -mfcu $UVM_INC -L mtiUvm ../uvm/fifo_top.sv

# 7. CONFIGURE DYNAMIC SIMULATION PLUSARGS
# Default test name to 'fifo_reset_recovery_test' if not passed from TCL runner
if {![info exists TESTNAME]} {
    set TESTNAME "fifo_test"
}

# Construct the plusargs command-line string for UVM factory and testbench top
set PLUSARGS "+UVM_TESTNAME=$TESTNAME"

# Append write clock half-period if passed by runner (e.g., set WCLK_HALF 3)
if {[info exists WCLK_HALF]} {
    append PLUSARGS " +WCLK_HALF=$WCLK_HALF"
}

# Append read clock half-period if passed by runner (e.g., set RCLK_HALF 10)
if {[info exists RCLK_HALF]} {
    append PLUSARGS " +RCLK_HALF=$RCLK_HALF"
}

# Append hardware Data Width generic if passed by runner (e.g., set DATA_WIDTH 16)
if {[info exists DATA_WIDTH]} {
    append PLUSARGS " -gDUT_DATA_WIDTH=$DATA_WIDTH"
}

# Append hardware Address Width generic if passed by runner (e.g., set ADDR_WIDTH 5)
if {[info exists ADDR_WIDTH]} {
    append PLUSARGS " -gDUT_ADDR_WIDTH=$ADDR_WIDTH"
}

# Launch vsim with resolution 1ps, full visibility (+acc), coverage enabled, and SVA assertions enabled
eval vsim -t 1ps -voptargs="+acc" -coverage -assertdebug -onfinish stop \
     -L mtiUvm -sv_lib \$UVM_DPI work.fifo_top $PLUSARGS

# 8. CONFIGURE WAVEFORM GROUPS
catch { delete wave * }

# Global Timing (Primary - Always Visible)
add wave -group "Clocks & Resets" -color "White" -position insertpoint sim:/fifo_top/dut/wclk
add wave -group "Clocks & Resets" -color "White" -position insertpoint sim:/fifo_top/dut/wrst_n
add wave -group "Clocks & Resets" -color "White" -position insertpoint sim:/fifo_top/dut/rclk
add wave -group "Clocks & Resets" -color "White" -position insertpoint sim:/fifo_top/dut/rrst_n

# Write Domain (Primary - Always Visible)
add wave -group "Write Domain" -color "Cyan" -radix hex -label "wdata (Data In)" sim:/fifo_top/dut/fifo_mem_unit/wdata
add wave -group "Write Domain" -color "Cyan" -radix unsigned -label "waddr (Write Addr)" sim:/fifo_top/dut/fifo_mem_unit/waddr
add wave -group "Write Domain" -color "Cyan" -label "wclken (Write Enable)" sim:/fifo_top/dut/fifo_mem_unit/wclken
add wave -group "Write Domain" -color "White" -position insertpoint sim:/fifo_top/dut/wclk

# Read Domain (Primary - Always Visible)
add wave -group "Read Domain" -color "SpringGreen" -radix hex -label "rdata (Data Out)" sim:/fifo_top/dut/fifo_mem_unit/rdata
add wave -group "Read Domain" -color "SpringGreen" -radix unsigned -label "raddr (Read Addr)" sim:/fifo_top/dut/fifo_mem_unit/raddr
add wave -group "Read Domain" -color "SpringGreen" -label "rclken (Read Enable)" sim:/fifo_top/dut/fifo_mem_unit/rclken
add wave -group "Read Domain" -color "White" -position insertpoint sim:/fifo_top/dut/rclk

# THE FULL LOGIC PROOF (Combinational Cause & Effect) 
add wave -group "FIFO Full Condition" -color "Gold" -label "wptr_g_next" sim:/fifo_top/dut/wptr_full_unit/wptr_g_next
add wave -group "FIFO Full Condition" -color "Gold" -label "w2q_rptr" sim:/fifo_top/dut/wptr_full_unit/w2q_rptr
add wave -group "FIFO Full Condition" -color "Orange" -label "wfull_next" sim:/fifo_top/dut/wptr_full_unit/wfull_next
add wave -group "FIFO Full Condition" -color "Red" -label "wfull (Registered)" sim:/fifo_top/dut/wfull
add wave -group "FIFO Full Condition" -color "White" -label "wclk" sim:/fifo_top/dut/wclk

# THE EMPTY LOGIC PROOF (Combinational Cause & Effect) 
add wave -group "FIFO Empty Condition" -color "Gold" -label "rptr_g_next" sim:/fifo_top/dut/rptr_empty_unit/rptr_g_next
add wave -group "FIFO Empty Condition" -color "Gold" -label "r2q_wptr" sim:/fifo_top/dut/rptr_empty_unit/r2q_wptr
add wave -group "FIFO Empty Condition" -color "Orange" -label "rempty_next" sim:/fifo_top/dut/rptr_empty_unit/rempty_next
add wave -group "FIFO Empty Condition" -color "Red" -label "rempty (Registered)" sim:/fifo_top/dut/rempty
add wave -group "FIFO Empty Condition" -color "White" -label "rclk"  sim:/fifo_top/dut/rclk

# READ-TO-WRITE SYNCHRONIZATION (CDC)
add wave -group "Read-to-Write Sync" -color "White" -label "rclk (Source Clock)" sim:/fifo_top/dut/rclk
add wave -group "Read-to-Write Sync" -color "Plum" -label "ptr_g (Async Input)" sim:/fifo_top/dut/read_to_write_sync/ptr_g
add wave -group "Read-to-Write Sync" -color "White" -label "wclk (Dest Clock)" sim:/fifo_top/dut/wclk
add wave -group "Read-to-Write Sync" -color "MediumOrchid" -label "q1ptr_g (Stage 1)" sim:/fifo_top/dut/read_to_write_sync/q1ptr_g
add wave -group "Read-to-Write Sync" -color "Magenta" -label "q2ptr_g (Stage 2)" sim:/fifo_top/dut/read_to_write_sync/q2ptr_g

# WRITE-TO-READ SYNCHRONIZATION (CDC)
add wave -group "Write-to-Read Sync" -color "White" -label "wclk (Source Clock)" sim:/fifo_top/dut/wclk
add wave -group "Write-to-Read Sync" -color "Plum" -label "ptr_g (Async Input)" sim:/fifo_top/dut/write_to_read_sync/ptr_g
add wave -group "Write-to-Read Sync" -color "White" -label "rclk (Dest Clock)" sim:/fifo_top/dut/rclk
add wave -group "Write-to-Read Sync" -color "MediumOrchid" -label "q1ptr_g (Stage 1)" sim:/fifo_top/dut/write_to_read_sync/q1ptr_g
add wave -group "Write-to-Read Sync" -color "Magenta" -label "q2ptr_g (Stage 2)" sim:/fifo_top/dut/write_to_read_sync/q2ptr_g

# Configure Waveform Window Display
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
# Expand waveform groups in GUI
catch { wave expand * }
wave zoom full

# 9. Run Simulation and Generate Report
run -all

# Save coverage database file (.ucdb)
coverage save fifo_cov.ucdb

# Generate detailed text-based coverage report
coverage report -detail -cvg -directive -comments -output coverage_report.txt

# Generate HTML coverage report directory
coverage report -html -output covhtmlreport -assert -directive -cvg -code bcesxf
catch { exec cmd /c start covhtmlreport/index.html }

# Print simulation completion message
echo "Simulation Finished. Matches recorded in scoreboard. Coverage report saved to coverage_report.txt and HTML report to covhtml/"