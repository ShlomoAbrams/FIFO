# run.do - FIFO UVM (Coverage Enabled)

# 1. Force close any previous simulation
quit -sim

# 2. Clean up previous database and log files
catch { file delete -force vsim.wlf transcript fifo_cov.ucdb coverage_report.txt }
catch { foreach f [glob -nocomplain wlft*] { file delete -force $f } }
if [file exists work] { 
    catch { vdel -all -lib work } 
    catch { file delete -force work }
}
vlib work
vmap work work

# 3. Define UVM Paths
set UVM_SRC "C:/MentorGraphics/MODELSIM/verilog_src/uvm-1.1d/src"
set UVM_DPI "C:/MentorGraphics/MODELSIM/uvm-1.1d/win64/uvm_dpi"
set UVM_INC "+incdir+$UVM_SRC"

# 4. Compile RTL (VHDL) with Coverage
vcom -reportprogress 300 -2008 -cover bcesxf \
    ../rtl/fifo_mem.vhd ../rtl/fifo_r_ptr.vhd ../rtl/fifo_w_ptr.vhd ../rtl/fifo_synchronizer.vhd ../rtl/fifo.vhd

# 5. Compile SV files with Coverage
vlog -sv -mfcu $UVM_INC -cover bcesxf -L mtiUvm \
	../uvm/fifo_if.sv \
	../uvm/fifo_sva.sv \
	../uvm/fifo_pkg.sv \
	../uvm/fifo_top.sv

# 6. Simulate with Coverage and Assertions enabled
vsim -t 1ps -voptargs="+acc" -coverage -assertdebug -onfinish stop \
     -L mtiUvm -sv_lib $UVM_DPI work.fifo_top +UVM_TESTNAME=fifo_test

# 7. FIFO Waveform Setup - Fully Grouped 

catch { delete wave * }

# Global Timing (Primary - Always Visible)
add wave -expand -group "Clocks & Resets" -color "White" -position insertpoint sim:/fifo_top/dut/wclk
add wave -expand -group "Clocks & Resets" -color "White" -position insertpoint sim:/fifo_top/dut/wrst_n
add wave -expand -group "Clocks & Resets" -color "White" -position insertpoint sim:/fifo_top/dut/rclk
add wave -expand -group "Clocks & Resets" -color "White" -position insertpoint sim:/fifo_top/dut/rrst_n

# Write Domain (Primary - Always Visible)

add wave -expand -group "Write Domain" -color "Cyan" -radix hex -label "wdata (Data In)" sim:/fifo_top/dut/fifo_mem_unit/wdata
add wave -expand -group "Write Domain" -color "Cyan" -radix unsigned -label "waddr (Write Addr)" sim:/fifo_top/dut/fifo_mem_unit/waddr
add wave -expand -group "Write Domain" -color "Cyan" -label "wclken (Write Enable)" sim:/fifo_top/dut/fifo_mem_unit/wclken
add wave -expand -group "Write Domain" -color "White" -position insertpoint sim:/fifo_top/dut/wclk

# Read Domain (Primary - Always Visible)

add wave -expand -group "Read Domain" -color "SpringGreen" -radix hex -label "rdata (Data Out)" sim:/fifo_top/dut/fifo_mem_unit/rdata
add wave -expand -group "Read Domain" -color "SpringGreen" -radix unsigned -label "raddr (Read Addr)" sim:/fifo_top/dut/fifo_mem_unit/raddr
add wave -expand -group "Read Domain" -color "SpringGreen" -label "rclken (Read Enable)" sim:/fifo_top/dut/fifo_mem_unit/rclken
add wave -expand -group "Read Domain" -color "White" -position insertpoint sim:/fifo_top/dut/rclk

# THE FULL LOGIC PROOF (Combinational Cause & Effect) 
add wave -expand -group "FIFO Full Condition" -color "Gold" -label "wptr_g_next" sim:/fifo_top/dut/wptr_full_unit/wptr_g_next
add wave -expand -group "FIFO Full Condition" -color "Gold" -label "w2q_rptr" sim:/fifo_top/dut/wptr_full_unit/w2q_rptr
add wave -expand -group "FIFO Full Condition" -color "Orange" -label "wfull_next" sim:/fifo_top/dut/wptr_full_unit/wfull_next
add wave -expand -group "FIFO Full Condition" -color "Red" -label "wfull (Registered)" sim:/fifo_top/dut/wfull
add wave -expand -group "FIFO Full Condition" -color "White" -label "wclk" sim:/fifo_top/dut/wclk

# THE EMPTY LOGIC PROOF (Combinational Cause & Effect) 
add wave -expand -group "FIFO Empty Condition" -color "Gold" -label "rptr_g_next" sim:/fifo_top/dut/rptr_empty_unit/rptr_g_next
add wave -expand -group "FIFO Empty Condition" -color "Gold" -label "r2q_wptr" sim:/fifo_top/dut/rptr_empty_unit/r2q_wptr
add wave -expand -group "FIFO Empty Condition" -color "Orange" -label "rempty_next" sim:/fifo_top/dut/rptr_empty_unit/rempty_next
add wave -expand -group "FIFO Empty Condition" -color "Red" -label "rempty (Registered)" sim:/fifo_top/dut/rempty
add wave -expand -group "FIFO Empty Condition" -color "White" -label "rclk"  sim:/fifo_top/dut/rclk

# READ-TO-WRITE SYNCHRONIZATION (CDC)
add wave -expand -group "Read-to-Write Sync" -color "White" -label "rclk (Source Clock)" sim:/fifo_top/dut/rclk
add wave -expand -group "Read-to-Write Sync" -color "Plum" -label "ptr_g (Async Input)" sim:/fifo_top/dut/read_to_write_sync/ptr_g
add wave -expand -group "Read-to-Write Sync" -color "White" -label "wclk (Dest Clock)" sim:/fifo_top/dut/wclk
add wave -expand -group "Read-to-Write Sync" -color "MediumOrchid" -label "q1ptr_g (Stage 1)" sim:/fifo_top/dut/read_to_write_sync/q1ptr_g
add wave -expand -group "Read-to-Write Sync" -color "Magenta" -label "q2ptr_g (Stage 2)" sim:/fifo_top/dut/read_to_write_sync/q2ptr_g

# WRITE-TO-READ SYNCHRONIZATION (CDC)
add wave -expand -group "Write-to-Read Sync" -color "White" -label "wclk (Source Clock)" sim:/fifo_top/dut/wclk
add wave -expand -group "Write-to-Read Sync" -color "Plum" -label "ptr_g (Async Input)" sim:/fifo_top/dut/write_to_read_sync/ptr_g
add wave -expand -group "Write-to-Read Sync" -color "White" -label "rclk (Dest Clock)" sim:/fifo_top/dut/rclk
add wave -expand -group "Write-to-Read Sync" -color "MediumOrchid" -label "q1ptr_g (Stage 1)" sim:/fifo_top/dut/write_to_read_sync/q1ptr_g
add wave -expand -group "Write-to-Read Sync" -color "Magenta" -label "q2ptr_g (Stage 2)" sim:/fifo_top/dut/write_to_read_sync/q2ptr_g

# Formatting
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
wave zoom full

# 8. Run Simulation and Generate Report
run -all

# Save the coverage database
coverage save fifo_cov.ucdb

# Generate a detailed text-based report for your project records
coverage report -detail -cvg -directive -comments -output coverage_report.txt

# Log completion
echo "Simulation Finished. Matches recorded in scoreboard. Coverage report saved to coverage_report.txt"