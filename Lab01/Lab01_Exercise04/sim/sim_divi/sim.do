# Quit any previous simulation
quit -sim

# Create a work library
vlib work

# Map the work library
vmap work work

# Compile the Verilog source files
# The unit-under-test (divu_1iter) must be compiled first
vlog ../../rtl/divu_1iter.v
vlog ../../rtl/divider_unsigned.v
vlog ../../tb/tb_divider_unsigned.v

# Load the simulation
vsim tb_divider_unsigned

# Add all signals from the testbench to the wave viewer
# add wave -r *

# Run the simulation
# The testbench will $display test results in the console
run -all