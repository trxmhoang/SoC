quit -sim
vlib work

vlog -sv ../../rtl/DividerUnsignedPipelined.v
vlog -sv ../../tb/tb_div.v

vsim -voptargs="+acc" work.tb_div

add wave /tb_div/clk
add wave /tb_div/rst
add wave /tb_div/stall
add wave /tb_div/i_dividend
add wave /tb_div/i_divisor
add wave /tb_div/dut/o_quotient
add wave /tb_div/dut/o_remainder

run -all