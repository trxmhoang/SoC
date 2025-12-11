echo "--- SIMULATION BEGIN ---"
echo "--- 1. Cleaning up old simulation... ---"
quit -sim

echo "--- 2. Creating 'work' library... ---"
vlib work

echo "--- 3. Compiling all files (fast sim)... ---"
vlog -quiet ../../rtl/cla.v
vlog -quiet ../../rtl/system.v
vlog -quiet ../../tb/tb_sys.v

echo "--- 4. Loading simulation... ---"
# We load the testbench 'tb' and enable debug access
vsim -voptargs=+acc work.tb_sys

echo "--- 5. Adding waves... ---"
add wave /tb_sys/clk
add wave /tb_sys/btn
add wave /tb_sys/dut/led

echo "--- 6. Running simulation... ---"
run -all

echo "--- SIMULATION END ---"