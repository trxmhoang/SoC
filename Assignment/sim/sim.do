# Library
vlib work
vmap work work

# Compile
vlog -work work ../rtl/cla.v
vlog -work work ../rtl/DividerUnsignedPipelined.v
vlog -work work ../rtl/DatapathPipelined.v
vlog -work work ../tb/tb_pipe.v

# Load simulation
vsim -voptargs=+acc work.tb_pipelined

# Wave
# --- GLOBAL SIGNALS ---
add wave -noupdate -divider {GLOBAL CONTROL}
add wave -noupdate -radix binary /tb_pipelined/clk
add wave -noupdate -radix binary /tb_pipelined/rst
add wave -noupdate -radix binary /tb_pipelined/halt

# --- PIPELINE CONTROL & HAZARDS ---
add wave -noupdate -divider {HAZARD & STALL}
add wave -noupdate -radix binary /tb_pipelined/dut/datapath/stall
add wave -noupdate -radix binary /tb_pipelined/dut/datapath/pc_src
add wave -noupdate -radix hex /tb_pipelined/dut/datapath/x_target_pc

# --- 1. FETCH STAGE (IF) ---
add wave -noupdate -divider {1. FETCH (IF)}
add wave -noupdate -radix hex -label "IF_PC" /tb_pipelined/dut/datapath/f_pc
add wave -noupdate -radix hex -label "IF_Inst" /tb_pipelined/dut/datapath/inst_from_imem

# --- 2. DECODE STAGE (ID) ---
add wave -noupdate -divider {2. DECODE (ID)}
add wave -noupdate -radix hex -label "ID_PC" /tb_pipelined/dut/datapath/d_pc
add wave -noupdate -radix hex -label "ID_Inst" /tb_pipelined/dut/datapath/d_inst
add wave -noupdate -radix unsigned -label "rs1_idx" /tb_pipelined/dut/datapath/d_rs1
add wave -noupdate -radix unsigned -label "rs2_idx" /tb_pipelined/dut/datapath/d_rs2
add wave -noupdate -radix unsigned -label "rd_idx" /tb_pipelined/dut/datapath/d_rd
add wave -noupdate -radix hex -label "Imm" /tb_pipelined/dut/datapath/d_imm

# --- 3. EXECUTE STAGE (EX) ---
add wave -noupdate -divider {3. EXECUTE (EX)}
add wave -noupdate -radix hex -label "EX_PC" /tb_pipelined/dut/datapath/x_pc
add wave -noupdate -radix hex -label "ALU_Op1 (Fwd)" /tb_pipelined/dut/datapath/fwd_a_val
add wave -noupdate -radix hex -label "ALU_Op2 (Fwd/Imm)" /tb_pipelined/dut/datapath/x_alu_op2
add wave -noupdate -radix hex -label "ALU_Result" /tb_pipelined/dut/datapath/alu_res
add wave -noupdate -label "Is_Branch" /tb_pipelined/dut/datapath/x_branch
add wave -noupdate -label "Branch_Taken" /tb_pipelined/dut/datapath/taken

# --- 4. MEMORY STAGE (MEM) ---
add wave -noupdate -divider {4. MEMORY (MEM)}
add wave -noupdate -radix hex -label "MEM_PC" /tb_pipelined/dut/datapath/m_pc
add wave -noupdate -radix hex -label "Mem_Addr" /tb_pipelined/dut/datapath/m_alu_res
add wave -noupdate -radix hex -label "Mem_Write_Data" /tb_pipelined/dut/datapath/m_rs2_data
add wave -noupdate -radix binary -label "Mem_WE" /tb_pipelined/dut/datapath/m_mem_write
add wave -noupdate -radix binary -label "Mem_RE" /tb_pipelined/dut/datapath/m_mem_read

# --- 5. WRITEBACK STAGE (WB) ---
add wave -noupdate -divider {5. WRITEBACK (WB)}
add wave -noupdate -radix hex -label "WB_PC" /tb_pipelined/dut/datapath/w_pc
add wave -noupdate -radix hex -label "WB_Inst" /tb_pipelined/dut/datapath/w_inst
add wave -noupdate -radix hex -label "WB_Data" /tb_pipelined/dut/datapath/w_final_data
add wave -noupdate -radix unsigned -label "WB_Dest_Reg" /tb_pipelined/dut/datapath/w_rd
add wave -noupdate -radix binary -label "Reg_Write_En" /tb_pipelined/dut/datapath/w_reg_write

# --- REGISTER FILE CHECK ---
add wave -noupdate -divider {REGISTERS (x1-x10)}
add wave -noupdate -radix hex /tb_pipelined/dut/datapath/rf/regs[1]
add wave -noupdate -radix hex /tb_pipelined/dut/datapath/rf/regs[2]
add wave -noupdate -radix hex /tb_pipelined/dut/datapath/rf/regs[3]
add wave -noupdate -radix hex /tb_pipelined/dut/datapath/rf/regs[4]
add wave -noupdate -radix hex /tb_pipelined/dut/datapath/rf/regs[10]

# Run simulation
run -all