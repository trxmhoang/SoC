# Create work library if it doesn't exist
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile all source files
vlog -work work ../../rtl/divu_1iter.v
vlog -work work ../../rtl/divider_unsigned.v
vlog -work work ../../rtl/cla.v
vlog -work work ../../rtl/DatapathSingleCycle.v
vlog -work work ../../tb/tb_single.v

# Start simulation
vsim -t 1ns -voptargs="+acc" work.tb_single

# Add waveforms
add wave -divider "Clock and Reset"
add wave -noupdate /tb_single/clock_proc
add wave -noupdate /tb_single/clock_mem
add wave -noupdate /tb_single/rst
add wave -noupdate /tb_single/halt

add wave -divider "Program Counter"
add wave -noupdate -radix hexadecimal /tb_single/dut/pc_to_imem
add wave -noupdate -radix hexadecimal /tb_single/dut/datapath/pcCurrent
add wave -noupdate -radix hexadecimal /tb_single/dut/datapath/pcNext

add wave -divider "Instruction"
add wave -noupdate -radix hexadecimal /tb_single/dut/inst_from_imem
add wave -noupdate -radix binary /tb_single/dut/datapath/inst_opcode

add wave -divider "Register File"
add wave -noupdate -radix unsigned /tb_single/dut/datapath/inst_rd
add wave -noupdate -radix unsigned /tb_single/dut/datapath/inst_rs1
add wave -noupdate -radix unsigned /tb_single/dut/datapath/inst_rs2
add wave -noupdate -radix hexadecimal /tb_single/dut/datapath/rd_data
add wave -noupdate -radix hexadecimal /tb_single/dut/datapath/rs1_data
add wave -noupdate -radix hexadecimal /tb_single/dut/datapath/rs2_data
add wave -noupdate /tb_single/dut/datapath/rf_we

add wave -divider "ALU"
add wave -noupdate -radix hexadecimal /tb_single/dut/datapath/cla_res
add wave -noupdate -radix hexadecimal /tb_single/dut/datapath/div_res

add wave -divider "Memory Interface"
add wave -noupdate -radix hexadecimal /tb_single/dut/mem_data_addr
add wave -noupdate -radix hexadecimal /tb_single/dut/mem_data_to_write
add wave -noupdate -radix hexadecimal /tb_single/dut/mem_data_loaded_value
add wave -noupdate -radix binary /tb_single/dut/mem_data_we

add wave -divider "Test Signals"
add wave -noupdate -radix unsigned /tb_single/timeout

# Run simulation
run -all

# Print results
echo "==================================================================="
echo "Simulation Complete"
echo "==================================================================="
