# Quit any previous simulation
quit -sim

# Create a work library
vlib work

# Map the work library
vmap work work

# Compile the Verilog source files
vlog ../../rtl/divu_1iter.v
vlog ../../tb/tb_divu_1iter.v

# Load the simulation
vsim tb_divu_1iter

# Add all signals from the testbench to the wave viewer
# add wave -r *

# Run the simulation
# The testbench will $display test results in the console
run -all