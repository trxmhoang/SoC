echo "--- SIMULATION BEGIN ---"
echo "--- 1. Cleaning up old simulation... ---"
quit -sim

echo "--- 2. Creating 'work' library... ---"
vlib work

echo "--- 3. Compiling all files (fast sim)... ---"
# We add "+define+SIMULATION" to tell Verilog to build in "fast mode"
vlog -quiet +define+SIMULATION ../rtl/debounce.v
vlog -quiet +define+SIMULATION ../rtl/ex1.v
vlog -quiet +define+SIMULATION ../tb/tb.v

echo "--- 4. Loading simulation... ---"
# We load the testbench 'tb' and enable debug access
vsim -voptargs=+acc work.tb

echo "--- 5. Adding waves... ---"
add wave -divider "Top Level (tb)"
add wave /tb/clk
add wave /tb/rst_n
add wave /tb/dut/clk_cnt
add wave /tb/dut/pulse_1s
add wave /tb/button
add wave -divider "Design Outputs (dut)"
add wave /tb/dut/hor_led
add wave /tb/dut/ver_led
add wave /tb/dut/bcd3
add wave /tb/dut/bcd2
add wave /tb/dut/bcd1
add wave /tb/dut/bcd0
add wave -divider "Design Internals (dut)"
add wave /tb/dut/mode
add wave /tb/dut/state
add wave /tb/dut/timer
add wave /tb/dut/green_time
add wave /tb/dut/yellow_time
add wave /tb/dut/temp_green_time
add wave /tb/dut/temp_yellow_time

echo "--- 6. Running simulation... ---"
run -all

echo "--- SIMULATION END ---"