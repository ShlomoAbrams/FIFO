# ============================================================================
# run.do - FIFO UVM (Coverage Enabled)
# ============================================================================

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
    fifo_mem.vhd fifo_r_ptr.vhd fifo_w_ptr.vhd fifo_synchronizer.vhd fifo.vhd

# 5. Compile SV files with Coverage[cite: 4, 6]
vlog -sv -mfcu $UVM_INC -cover bcesxf -L mtiUvm \
    fifo_if.sv \
    fifo_transaction.sv \
    fifo_sva.sv \
    fifo_w_sequence.sv \
    fifo_r_sequence.sv \
	fifo_w_burst_sequence.sv \
    fifo_r_drain_sequence.sv \
    fifo_w_driver.sv \
    fifo_r_driver.sv \
    fifo_w_monitor.sv \
    fifo_r_monitor.sv \
    fifo_scoreboard.sv \
    fifo_env.sv \
    fifo_test.sv \
    fifo_top.sv

# 6. Simulate with Coverage and Assertions enabled[cite: 5, 6]
vsim -t 1ps -voptargs="+acc" -coverage -assertdebug -onfinish stop \
     -L mtiUvm -sv_lib $UVM_DPI work.fifo_top +UVM_TESTNAME=fifo_test

# 7. Waves
quietly add wave -r /*

# 8. Run Simulation and Generate Report[cite: 5]
run -all

# Save the coverage database[cite: 5]
coverage save fifo_cov.ucdb

# Generate a detailed text-based report for your project records[cite: 4, 5]
coverage report -detail -cvg -directive -comments -output coverage_report.txt

# Log completion
echo "Simulation Finished. Matches recorded in scoreboard. Coverage report saved to coverage_report.txt"