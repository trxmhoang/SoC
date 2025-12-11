# Quit any previous simulation
quit -sim

# Create a work library
vlib work

# Compile the Verilog source files
vlog -sv ../../rtl/DatapathSingleCycle.v
vlog -sv ../../tb/tb_reg.v

# Load simulation
vsim -voptargs="+acc" work.tb_reg

# Add waves
add wave -r /tb_reg/*

# Run simulation
run -all