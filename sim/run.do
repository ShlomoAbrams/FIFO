# run.do - FIFO UVM (Coverage Enabled)

# 1. Force close any previous simulation
quit -sim

# 2. Clean up previous database and log files
catch { file delete -force vsim.wlf transcript fifo_cov.ucdb coverage_report.txt }
if [file exists work] { 
    catch { vdel -all -lib work } 
}
vlib work
vmap work work

# 3. Define UVM Paths
set UVM_SRC "C:/MentorGraphics/MODELSIM/verilog_src/uvm-1.1d/src"
set UVM_DPI "C:/MentorGraphics/MODELSIM/uvm-1.1d/win64/uvm_dpi"
set UVM_INC "+incdir+$UVM_SRC"

# 4. Compile RTL (VHDL) with Coverage[cite: 6]
vcom -reportprogress 300 -2008 -cover bcesxf \
    ../rtl/fifo_mem.vhd ../rtl/fifo_r_ptr.vhd ../rtl/fifo_w_ptr.vhd ../rtl/fifo_synchronizer.vhd ../rtl/fifo.vhd

# 5. Compile SV files with Coverage[cite: 4, 6]
vlog -sv -mfcu $UVM_INC -cover bcesxf -L mtiUvm \
	../uvm/fifo_if.sv \
    ../uvm/fifo_transaction.sv \
    ../uvm/fifo_sva.sv \
    ../uvm/fifo_w_sequence.sv \
    ../uvm/fifo_r_sequence.sv \
    ../uvm/fifo_w_burst_sequence.sv \
    ../uvm/fifo_r_drain_sequence.sv \
    ../uvm/fifo_w_driver.sv \
    ../uvm/fifo_r_driver.sv \
    ../uvm/fifo_w_monitor.sv \
    ../uvm/fifo_r_monitor.sv \
    ../uvm/fifo_scoreboard.sv \
    ../uvm/fifo_env.sv \
    ../uvm/fifo_test.sv \
    ../uvm/fifo_top.sv

# 6. Simulate with Coverage and Assertions enabled[cite: 5, 6]
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
add wave -expand -group "Write Domain" -color "Cyan" -position insertpoint sim:/fifo_top/dut/wfull
add wave -expand -group "Write Domain" -color "Cyan" -position insertpoint sim:/fifo_top/dut/winc
add wave -expand -group "Write Domain" -color "Cyan" -label "wclken (Write Enable)" sim:/fifo_top/dut/fifo_mem_unit/wclken
add wave -expand -group "Write Domain" -color "Cyan" -radix unsigned -label "waddr (Write Addr)" sim:/fifo_top/dut/fifo_mem_unit/waddr

# Read Domain (Primary - Always Visible)

add wave -expand -group "Read Domain" -color "SpringGreen" -radix hex -label "rdata (Data Out)" sim:/fifo_top/dut/fifo_mem_unit/rdata
add wave -expand -group "Read Domain" -color "SpringGreen" -position insertpoint sim:/fifo_top/dut/rempty
add wave -expand -group "Read Domain" -color "SpringGreen" -position insertpoint sim:/fifo_top/dut/rinc
add wave -expand -group "Read Domain" -color "SpringGreen" -label "rclken (Read Enable)" sim:/fifo_top/dut/fifo_mem_unit/rclken
add wave -expand -group "Read Domain" -color "SpringGreen" -radix unsigned -label "raddr (Read Addr)" sim:/fifo_top/dut/fifo_mem_unit/raddr

# ============================================================================
# WHITE-BOX DEBUGGING (Secondary - Collapsed Folders)
# ============================================================================

# THE FULL LOGIC PROOF (Combinational Cause & Effect) 
add wave -group "Write Pointers: wfull proof" -color "Gold" -label "wptr_g_next" sim:/fifo_top/dut/wptr_full_unit/wptr_g_next
add wave -group "Write Pointers: wfull proof" -color "Gold" -label "w2q_rptr" sim:/fifo_top/dut/wptr_full_unit/w2q_rptr
add wave -group "Write Pointers: wfull proof" -color "Orange" -label "wfull_next" sim:/fifo_top/dut/wptr_full_unit/wfull_next
add wave -group "Write Pointers: wfull proof" -color "Red" -label "wfull (Registered)" sim:/fifo_top/dut/wfull

# THE EMPTY LOGIC PROOF (Combinational Cause & Effect) 
add wave -group "Read Pointers: rempty proof" -color "Gold" -label "rptr_g_next" sim:/fifo_top/dut/rptr_empty_unit/rptr_g_next
add wave -group "Read Pointers: rempty proof" -color "Gold" -label "r2q_wptr" sim:/fifo_top/dut/rptr_empty_unit/r2q_wptr
add wave -group "Read Pointers: rempty proof" -color "Orange" -label "rempty_next" sim:/fifo_top/dut/rptr_empty_unit/rempty_next
add wave -group "Read Pointers: rempty proof" -color "Red" -label "rempty (Registered)" sim:/fifo_top/dut/rempty

# Formatting
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
wave zoom full



# 8. Run Simulation and Generate Report[cite: 5]
run -all

# Save the coverage database[cite: 5]
coverage save fifo_cov.ucdb

# Generate a detailed text-based report for your project records[cite: 4, 5]
coverage report -detail -cvg -directive -comments -output coverage_report.txt

# Log completion
echo "Simulation Finished. Matches recorded in scoreboard. Coverage report saved to coverage_report.txt"