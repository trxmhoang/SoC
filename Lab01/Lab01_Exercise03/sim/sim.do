echo "--- SIMULATION BEGIN ---"
echo "--- 1. Cleaning up old simulation... ---"
quit -sim

echo "--- 2. Creating 'work' library... ---"
vlib work

echo "--- 3. Compiling all files (fast sim)... ---"
# We add "+define+SIMULATION" to tell Verilog to build in "fast mode"
vlog -quiet +define+SIMULATION ../rtl/ex3.v
vlog -quiet +define+SIMULATION ../tb/tb.v

echo "--- 4. Loading simulation... ---"
# We load the testbench 'tb' and enable debug access
vsim -voptargs=+acc work.tb

echo "--- 5. Adding waves... ---"
add wave -divider "Top Level (tb)"
add wave /tb/clk
add wave /tb/rst_n
add wave /tb/dut/clk_cnt
add wave /tb/dut/tick_1s
add wave /tb/btn

add wave -divider "Design Outputs (dut)"
add wave /tb/dut/led

add wave -divider "Design Internals (dut)"
add wave /tb/dut/mode

echo "--- 6. Running simulation... ---"
run -all

echo "--- SIMULATION END ---"