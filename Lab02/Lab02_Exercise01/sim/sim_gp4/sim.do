# Quit any previous simulation
quit -sim

# Create a work library
vlib work

# Map the work library
vmap work work

# Compile the Verilog source files
vlog ../../rtl/cla.v
vlog ../../tb/tb_gp4.v

# Load the simulation
vsim tb_gp4

# Run the simulation
# The testbench will $display test results in the console
run -all