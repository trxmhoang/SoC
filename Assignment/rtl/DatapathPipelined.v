`timescale 1ns / 1ns
`define REG_SIZE 31
`define INST_SIZE 31
`define OPCODE_SIZE 6
`define DIVIDER_STAGES 8

// Don't forget your old codes
//`include "cla.v"
//`include "DividerUnsignedPipelined.v"

module RegFile (
  input      [        4:0] rd,
  input      [`REG_SIZE:0] rd_data,
  input      [        4:0] rs1,
  output reg [`REG_SIZE:0] rs1_data,
  input      [        4:0] rs2,
  output reg [`REG_SIZE:0] rs2_data,
  input                    clk,
  input                    we,
  input                    rst
);

  localparam NumRegs = 32;
  reg [`REG_SIZE:0] regs[0:NumRegs-1];
  integer i;
  
  always @(negedge clk) begin
    if (rst) 
        for (i = 0; i < NumRegs; i = i + 1) regs[i] <= 0;
    else if (we && (rd != 0)) 
        regs[rd] <= rd_data;
  end
  
  always @(*) begin
    rs1_data = (rs1 == 0) ? 32'd0 : regs[rs1];
    rs2_data = (rs2 == 0) ? 32'd0 : regs[rs2];
  end
endmodule

module DatapathPipelined (
  input                     clk,
  input                     rst,
  output     [ `REG_SIZE:0] pc_to_imem,
  input      [`INST_SIZE:0] inst_from_imem,
  // dmem is read/write
  output reg [ `REG_SIZE:0] addr_to_dmem,
  input      [ `REG_SIZE:0] load_data_from_dmem,
  output reg [ `REG_SIZE:0] store_data_to_dmem,
  output reg [         3:0] store_we_to_dmem,
  output reg                halt,
  // The PC of the inst currently in Writeback. 0 if not a valid inst.
  output reg [ `REG_SIZE:0] trace_writeback_pc,
  // The bits of the inst currently in Writeback. 0 if not a valid inst.
  output reg [`INST_SIZE:0] trace_writeback_inst
);

  localparam [`OPCODE_SIZE:0] OpcodeLoad    = 7'b00_000_11;
  localparam [`OPCODE_SIZE:0] OpcodeStore   = 7'b01_000_11;
  localparam [`OPCODE_SIZE:0] OpcodeBranch  = 7'b11_000_11;
  localparam [`OPCODE_SIZE:0] OpcodeJalr    = 7'b11_001_11;
  localparam [`OPCODE_SIZE:0] OpcodeMiscMem = 7'b00_011_11;
  localparam [`OPCODE_SIZE:0] OpcodeJal     = 7'b11_011_11;

  localparam [`OPCODE_SIZE:0] OpcodeRegImm  = 7'b00_100_11;
  localparam [`OPCODE_SIZE:0] OpcodeRegReg  = 7'b01_100_11;
  localparam [`OPCODE_SIZE:0] OpcodeEnviron = 7'b11_100_11;

  localparam [`OPCODE_SIZE:0] OpcodeAuipc   = 7'b00_101_11;
  localparam [`OPCODE_SIZE:0] OpcodeLui     = 7'b01_101_11;

  localparam [`INST_SIZE:0] NOP = 32'h00000013;

  reg [`REG_SIZE:0] cycles_current;
  always @(posedge clk) begin
    if (rst) begin
      cycles_current <= 0;
    end else begin
      cycles_current <= cycles_current + 1;
    end
  end
  
  reg  [`REG_SIZE:0] f_pc;
  wire [`REG_SIZE:0] f_pc_next;
  wire stall; 
  wire pc_src; 
  wire [`REG_SIZE:0] x_target_pc;

  reg [`REG_SIZE:0] d_pc;
  reg [`INST_SIZE:0] d_inst;
  
  reg [`REG_SIZE:0] x_pc, x_rs1_data, x_rs2_data, x_imm;
  reg [`INST_SIZE:0] x_inst;
  reg [4:0] x_rd, x_rs1, x_rs2;
  reg [6:0] x_opcode, x_funct7;
  reg [2:0] x_funct3;
  reg x_reg_write, x_mem_read, x_mem_write, x_branch, x_jal, x_jalr, x_halt;

  reg [`REG_SIZE:0] m_pc, m_alu_res, m_rs2_data;
  reg [`INST_SIZE:0] m_inst;
  reg [4:0] m_rd;
  reg [2:0] m_funct3;
  reg m_reg_write, m_mem_read, m_mem_write, m_halt;
  
  reg [`REG_SIZE:0] w_pc, w_alu_res, w_mem_read_data;
  reg [`INST_SIZE:0] w_inst;
  reg [4:0] w_rd;
  reg [2:0] w_funct3;
  reg w_reg_write, w_mem_read, w_halt;
  
  wire [`REG_SIZE:0] w_final_data;

  /***************/
  /* FETCH STAGE */
  /***************/
  assign f_pc_next = pc_src ? x_target_pc : (f_pc + 4);
  assign pc_to_imem = f_pc;

  always @(posedge clk) begin
    if (rst) 
      f_pc <= 0;
    else if (!stall) 
      f_pc <= f_pc_next;
  end

  always @(posedge clk) begin
    if (rst) begin 
        d_pc <= 0; 
        d_inst <= NOP; 
    end else if (pc_src) begin 
        d_pc <= 0; 
        d_inst <= NOP; 
    end else if (!stall) begin 
        d_pc <= f_pc; 
        d_inst <= inst_from_imem;
    end
  end

  /****************/
  /* DECODE STAGE */
  /****************/
  
  wire [6:0] d_funct7, d_opcode;
  wire [2:0] d_funct3;
  wire [4:0] d_rs1, d_rs2, d_rd;
  wire [`REG_SIZE:0] rf_rs1_data, rf_rs2_data;
  assign {d_funct7, d_rs2, d_rs1, d_funct3, d_rd, d_opcode} = d_inst;

  RegFile rf (
    .rd(w_rd), 
    .rd_data(w_final_data), 
    .we(w_reg_write),       
    .rs1(d_rs1), 
    .rs1_data(rf_rs1_data),
    .rs2(d_rs2), 
    .rs2_data(rf_rs2_data),
    .clk(clk), 
    .rst(rst)
  );

  wire [`REG_SIZE:0] d_rs1_val = (w_reg_write && w_rd != 0 && w_rd == d_rs1) ? w_final_data : rf_rs1_data;
  wire [`REG_SIZE:0] d_rs2_val = (w_reg_write && w_rd != 0 && w_rd == d_rs2) ? w_final_data : rf_rs2_data;

  reg [`REG_SIZE:0] d_imm;
  always @(*) begin
    case (d_opcode)
      OpcodeStore:  d_imm = { {20{d_inst[31]}}, d_inst[31:25], d_inst[11:7] };
      OpcodeBranch: d_imm = { {20{d_inst[31]}}, d_inst[7], d_inst[30:25], d_inst[11:8], 1'b0 };
      OpcodeJal:    d_imm = { {12{d_inst[31]}}, d_inst[19:12], d_inst[20], d_inst[30:21], 1'b0 };
      OpcodeLui, OpcodeAuipc: d_imm = { d_inst[31:12], 12'b0 };
      default:      d_imm = { {20{d_inst[31]}}, d_inst[31:20] };
    endcase
  end
  
  wire d_use_rs1 = (d_opcode != OpcodeLui && d_opcode != OpcodeAuipc && d_opcode != OpcodeJal);
  wire d_use_rs2 = (d_opcode == OpcodeRegReg || d_opcode == OpcodeStore || d_opcode == OpcodeBranch);
  
  wire load_use_hazard = (x_mem_read && x_rd != 0 && ((d_use_rs1 && d_rs1 == x_rd) || (d_use_rs2 && d_rs2 == x_rd)));
  
  reg [4:0] fifo_div_rd [0:`DIVIDER_STAGES-1];
  reg fifo_div_valid [0:`DIVIDER_STAGES-1];
  reg fifo_div_rem [0:`DIVIDER_STAGES-1];
  reg [31:0] fifo_div_pc [0:`DIVIDER_STAGES-1];
  reg [31:0] fifo_div_inst [0:`DIVIDER_STAGES-1];
  reg fifo_div_a_neg [0:`DIVIDER_STAGES-1];
  reg fifo_div_b_neg [0:`DIVIDER_STAGES-1];
  reg fifo_div_by_zero [0:`DIVIDER_STAGES-1];
  reg [31:0] fifo_div_dividend [0:`DIVIDER_STAGES-1];

  wire x_is_div = (x_opcode == OpcodeRegReg) && (x_funct7 == 7'b0000001) && x_funct3[2];
  wire div_in_ex = x_is_div && x_reg_write && (x_rd != 0);

  wire [4:0] div_rd_in_fifo [0:7];
  assign div_rd_in_fifo[0] = fifo_div_valid[0] ? fifo_div_rd[0] : 5'b0;
  assign div_rd_in_fifo[1] = fifo_div_valid[1] ? fifo_div_rd[1] : 5'b0;
  assign div_rd_in_fifo[2] = fifo_div_valid[2] ? fifo_div_rd[2] : 5'b0;
  assign div_rd_in_fifo[3] = fifo_div_valid[3] ? fifo_div_rd[3] : 5'b0;
  assign div_rd_in_fifo[4] = fifo_div_valid[4] ? fifo_div_rd[4] : 5'b0;
  assign div_rd_in_fifo[5] = fifo_div_valid[5] ? fifo_div_rd[5] : 5'b0;
  assign div_rd_in_fifo[6] = fifo_div_valid[6] ? fifo_div_rd[6] : 5'b0;
  assign div_rd_in_fifo[7] = fifo_div_valid[7] ? fifo_div_rd[7] : 5'b0;

  wire div_raw_hazard = 
                    (d_use_rs1 && (d_rs1 != 0) && 
                      ( (div_in_ex && (d_rs1 == x_rd)) || 
                        (d_rs1 == div_rd_in_fifo[0]) ||
                        (d_rs1 == div_rd_in_fifo[1]) ||
                        (d_rs1 == div_rd_in_fifo[2]) ||
                        (d_rs1 == div_rd_in_fifo[3]) ||
                        (d_rs1 == div_rd_in_fifo[4]) ||
                        (d_rs1 == div_rd_in_fifo[5]) ||
                        (d_rs1 == div_rd_in_fifo[6]) 
                      )
                    ) ||
                    (d_use_rs2 && (d_rs2 != 0) && 
                      ( (div_in_ex && (d_rs2 == x_rd)) || 
                        (d_rs2 == div_rd_in_fifo[0]) ||
                        (d_rs2 == div_rd_in_fifo[1]) ||
                        (d_rs2 == div_rd_in_fifo[2]) ||
                        (d_rs2 == div_rd_in_fifo[3]) ||
                        (d_rs2 == div_rd_in_fifo[4]) ||
                        (d_rs2 == div_rd_in_fifo[5]) ||
                        (d_rs2 == div_rd_in_fifo[6]) 
                      )
                    );


  wire d_writes_reg = (d_opcode != OpcodeStore && d_opcode != OpcodeBranch) && (d_rd != 0);
  wire d_is_div = (d_opcode == OpcodeRegReg) && (d_funct7 == 7'b0000001) && d_funct3[2];
  
  wire div_busy = div_in_ex || fifo_div_valid[0] || fifo_div_valid[1] || fifo_div_valid[2] || fifo_div_valid[3] || fifo_div_valid[4] || fifo_div_valid[5] || fifo_div_valid[6];
                      
  wire div_struct_hazard = div_busy && d_writes_reg && !d_is_div;
  assign stall = load_use_hazard || div_raw_hazard || div_struct_hazard;
  
  always @(posedge clk) begin
    if (rst || stall || pc_src) begin 
      x_pc <= 0; 
      x_inst <= NOP; 
      x_rd <= 0; 
      x_rs1 <= 0; 
      x_rs2 <= 0;
      x_rs1_data <= 0; 
      x_rs2_data <= 0; 
      x_imm <= 0; 
      x_opcode <= 0; 
      x_funct3 <= 0; 
      x_funct7 <= 0;
      x_reg_write <= 0; 
      x_mem_read <= 0; 
      x_mem_write <= 0;
      x_branch <= 0; 
      x_jal <= 0; 
      x_jalr <= 0; 
      x_halt <= 0;
    end else begin 
      x_pc <= d_pc; 
      x_inst <= d_inst; 
      x_rd <= d_rd; 
      x_rs1 <= d_rs1; 
      x_rs2 <= d_rs2;
      x_rs1_data <= d_rs1_val; 
      x_rs2_data <= d_rs2_val;
      x_imm <= d_imm;
      x_opcode <= d_opcode; 
      x_funct3 <= d_funct3; 
      x_funct7 <= d_funct7;
      x_reg_write <= (d_opcode != OpcodeStore && d_opcode != OpcodeBranch);
      x_mem_read <= (d_opcode == OpcodeLoad); 
      x_mem_write <= (d_opcode == OpcodeStore);
      x_branch <= (d_opcode == OpcodeBranch); 
      x_jal <= (d_opcode == OpcodeJal); 
      x_jalr <= (d_opcode == OpcodeJalr);
      x_halt <= (d_inst == 32'h00000073) || (d_inst == 32'h00100073);
    end
  end

  /****************/
  /* EXECUTE STAGE */
  /****************/

  wire match_mem_rs1 = (m_reg_write && m_rd != 0 && m_rd == x_rs1);
  wire match_wb_rs1  = (w_reg_write && w_rd != 0 && w_rd == x_rs1);

  wire match_mem_rs2 = (m_reg_write && m_rd != 0 && m_rd == x_rs2);
  wire match_wb_rs2  = (w_reg_write && w_rd != 0 && w_rd == x_rs2);

  wire [`REG_SIZE:0] fwd_a_val = match_mem_rs1 ? m_alu_res :
                                (match_wb_rs1 ? w_final_data : x_rs1_data);
  wire [`REG_SIZE:0] fwd_b_val = match_mem_rs2 ? m_alu_res :
                                (match_wb_rs2 ? w_final_data : x_rs2_data);

  wire x_is_imm = (x_opcode == OpcodeRegImm) || (x_opcode == OpcodeLoad) || (x_opcode == OpcodeJalr) || (x_opcode == OpcodeAuipc) || (x_opcode == OpcodeLui) || (x_opcode == OpcodeStore);
  wire [`REG_SIZE:0] x_alu_op1 = fwd_a_val;
  wire [`REG_SIZE:0] x_alu_op2 = x_is_imm ? x_imm : fwd_b_val;
  wire x_is_sub = (x_opcode == OpcodeRegReg) && (x_funct7[5] && x_funct3 == 3'b000);
  
  wire div_start = x_is_div && !pc_src; 
  wire div_signed = !x_funct3[0];
  wire current_div_a_neg = div_signed && fwd_a_val[31];
  wire current_div_b_neg = div_signed && fwd_b_val[31];
  wire current_div_by_zero = (fwd_b_val == 0);
  wire [31:0] current_div_a = current_div_a_neg ? (~fwd_a_val + 1) : fwd_a_val;
  wire [31:0] current_div_b = current_div_b_neg ? (~fwd_b_val + 1) : fwd_b_val;

  integer k;
  always @(posedge clk) begin
    if (rst) begin
      for (k = 0; k < `DIVIDER_STAGES; k = k + 1) begin
        fifo_div_valid[k] <= 0;
        fifo_div_rd[k] <= 0;
        fifo_div_rem[k] <= 0;
        fifo_div_pc[k] <= 0;
        fifo_div_inst[k] <= 0;
        fifo_div_a_neg[k] <= 0;
        fifo_div_b_neg[k] <= 0;
        fifo_div_by_zero[k] <= 0;
        fifo_div_dividend[k] <= 0;
      end
    end else begin
      for (k = `DIVIDER_STAGES-1; k > 0; k = k - 1) begin
        fifo_div_valid[k] <= fifo_div_valid[k - 1];
        fifo_div_rd[k] <= fifo_div_rd[k - 1];
        fifo_div_rem[k] <= fifo_div_rem[k - 1];
        fifo_div_pc[k] <= fifo_div_pc[k - 1];
        fifo_div_inst[k] <= fifo_div_inst[k - 1];
        fifo_div_a_neg[k] <= fifo_div_a_neg[k - 1];
        fifo_div_b_neg[k] <= fifo_div_b_neg[k - 1];
        fifo_div_by_zero[k] <= fifo_div_by_zero[k - 1];
        fifo_div_dividend[k] <= fifo_div_dividend[k - 1];
      end

      fifo_div_valid[0] <= div_start;
      fifo_div_rd[0] <= x_rd;
      fifo_div_rem[0] <= x_funct3[1];
      fifo_div_pc[0] <= x_pc;
      fifo_div_inst[0] <= x_inst;
      fifo_div_a_neg[0] <= current_div_a_neg;
      fifo_div_b_neg[0] <= current_div_b_neg;
      fifo_div_by_zero[0] <= current_div_by_zero;
      fifo_div_dividend[0] <= fwd_a_val;
    end
  end

  wire [31:0] div_quot_raw, div_rem_raw;
  DividerUnsignedPipelined u_div (
    .clk(clk),
    .rst(rst),
    .stall(1'b0),
    .i_dividend(current_div_a),
    .i_divisor(current_div_b),
    .o_quotient(div_quot_raw),
    .o_remainder(div_rem_raw)
  );

  wire [31:0] div_quot_mid = (fifo_div_a_neg[`DIVIDER_STAGES-1] ^ fifo_div_b_neg[`DIVIDER_STAGES-1]) ? (~div_quot_raw + 1) : div_quot_raw;
  wire [31:0] div_rem_mid = fifo_div_a_neg[`DIVIDER_STAGES-1] ? (~div_rem_raw + 1) : div_rem_raw;
  wire [31:0] div_quot_final = fifo_div_by_zero[`DIVIDER_STAGES-1] ? 32'hFFFFFFFF : div_quot_mid;
  wire [31:0] div_rem_final = fifo_div_by_zero[`DIVIDER_STAGES-1] ? fifo_div_dividend[`DIVIDER_STAGES-1] : div_rem_mid;
  wire [31:0] div_res = fifo_div_rem[`DIVIDER_STAGES-1] ? div_rem_final : div_quot_final;

  wire div_done = fifo_div_valid[`DIVIDER_STAGES-1];
  
  wire [31:0] cla_res;
  wire [31:0] cla_op_b = x_is_sub ? ~x_alu_op2 : x_alu_op2;
  wire cla_cin = x_is_sub ? 1'b1 : 1'b0;
  
  cla u_cla (
    .a(x_alu_op1),
    .b(cla_op_b),
    .cin(cla_cin),
    .sum(cla_res)
  );
 
  wire [63:0] mul_u, mul_s, mul_su;
  assign mul_u = x_alu_op1 * x_alu_op2;
  assign mul_s = $signed(x_alu_op1) * $signed(x_alu_op2);
  assign mul_su = $signed(x_alu_op1) * $signed({1'b0, x_alu_op2});

  reg [`REG_SIZE:0] alu_res;
  always @(*) begin
    case (x_opcode)
      OpcodeLui: alu_res = x_alu_op2;
      OpcodeAuipc: alu_res = x_pc + x_alu_op2;
      OpcodeJal, OpcodeJalr: alu_res = x_pc + 4;
      OpcodeLoad, OpcodeStore: alu_res = cla_res;
      OpcodeRegImm, OpcodeRegReg:
        if ((x_opcode == OpcodeRegReg) && (x_funct7 == 7'b0000001)) begin
          case (x_funct3)
            3'b000: alu_res = mul_s[31:0];
            3'b001: alu_res = mul_s[63:32];
            3'b010: alu_res = mul_su[63:32];
            3'b011: alu_res = mul_u[63:32];
            default: alu_res = div_res;
          endcase
        end else begin
          case (x_funct3)
            3'b000: alu_res = cla_res; 
            3'b001: alu_res = x_alu_op1 << x_alu_op2[4:0];
            3'b010: alu_res = ($signed(x_alu_op1) < $signed(x_alu_op2)) ? 32'd1 : 32'd0;
            3'b011: alu_res = (x_alu_op1 < x_alu_op2) ? 32'd1 : 32'd0;
            3'b100: alu_res = x_alu_op1 ^ x_alu_op2;
            3'b101: begin
              if (x_funct7[5]) begin
                alu_res = $signed(x_alu_op1) >>> x_alu_op2[4:0];
              end else begin
                alu_res = x_alu_op1 >> x_alu_op2[4:0];
              end
            end
            3'b110: alu_res = x_alu_op1 | x_alu_op2;
            3'b111: alu_res = x_alu_op1 & x_alu_op2;
            default: alu_res = 32'd0;
          endcase
        end
        default: alu_res = 32'd0;
    endcase
  end

  // Branch
  reg taken;
  always @(*) begin
    case (x_funct3)
      3'b000: taken = (fwd_a_val == fwd_b_val);
      3'b001: taken = (fwd_a_val != fwd_b_val);
      3'b100: taken = ($signed(fwd_a_val) < $signed(fwd_b_val));
      3'b101: taken = ($signed(fwd_a_val) >= $signed(fwd_b_val));
      3'b110: taken = (fwd_a_val < fwd_b_val);
      3'b111: taken = (fwd_a_val >= fwd_b_val);
      default: taken = 0;
    endcase
  end

  assign pc_src = (x_branch && taken) || x_jal || x_jalr;
  assign x_target_pc = (x_opcode == OpcodeJalr) ? ((fwd_a_val + x_imm) & ~32'd1) : (x_pc + x_imm);

  always @(posedge clk) begin
    if (rst) begin
      m_pc <= 0;
      m_inst <= NOP;
      m_alu_res <= 0;
      m_rs2_data <= 0;
      m_rd <= 0;
      m_funct3 <= 0;
      m_reg_write <= 0;
      m_mem_read <= 0;
      m_mem_write <= 0;
      m_halt <= 0;
    end else begin
      m_pc <= x_pc;
      m_inst <= x_inst;
      m_rs2_data <= fwd_b_val;
      m_funct3 <= x_funct3;
      m_mem_read <= x_mem_read;
      m_mem_write <= x_mem_write;
      m_halt <= x_halt;

      if (div_done) begin
        m_alu_res <= div_res;
        m_rd <= fifo_div_rd[`DIVIDER_STAGES-1];
        m_reg_write <= 1'b1;
      end else begin
        m_alu_res <= alu_res;
        m_rd <= x_rd;
        m_reg_write <= x_reg_write && !x_is_div;
      end
    end
  end

  /****************/
  /* MEMORY STAGE */
  /****************/

  always @(*) begin
    // default values
    addr_to_dmem = m_alu_res;
    store_data_to_dmem = m_rs2_data;
    store_we_to_dmem = 4'b0000;

    if (m_mem_write) begin
      case (m_funct3)
        2'b00: begin // SB
            case (m_alu_res[1:0])
                2'b00: begin store_data_to_dmem = {24'b0, m_rs2_data[7:0]};       store_we_to_dmem = 4'b0001; end
                2'b01: begin store_data_to_dmem = {16'b0, m_rs2_data[7:0], 8'b0}; store_we_to_dmem = 4'b0010; end
                2'b10: begin store_data_to_dmem = {8'b0, m_rs2_data[7:0], 16'b0}; store_we_to_dmem = 4'b0100; end
                2'b11: begin store_data_to_dmem = {m_rs2_data[7:0], 24'b0};       store_we_to_dmem = 4'b1000; end
            endcase
        end
        2'b01: begin // SH
            case (m_alu_res[1])
                1'b0: begin store_data_to_dmem = {16'b0, m_rs2_data[15:0]}; store_we_to_dmem = 4'b0011; end
                1'b1: begin store_data_to_dmem = {m_rs2_data[15:0], 16'b0}; store_we_to_dmem = 4'b1100; end
            endcase
        end
        default: begin // SW
            store_data_to_dmem = m_rs2_data;
            store_we_to_dmem = 4'b1111;
        end
      endcase
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      w_reg_write <= 0;
      w_rd <= 0;
      w_pc <= 0;
      w_inst <= NOP;
      w_halt <= 0;
      w_alu_res <= 0;
      w_mem_read_data <= 0;
      w_funct3 <= 0;
      w_mem_read <= 0;
    end else begin
      w_reg_write <= m_reg_write;
      w_rd <= m_rd;
      w_alu_res <= m_alu_res;
      w_mem_read_data <= load_data_from_dmem; 
      w_mem_read <= m_mem_read;
      w_funct3 <= m_funct3;
      w_pc <= m_pc; 
      w_inst <= m_inst;
      w_halt <= m_halt;
    end
  end

  /****************/
  /*WRITEBACK STAGE*/
  /****************/
 
  wire [`REG_SIZE:0] w_load_process;
  reg [`REG_SIZE:0] w_load_shift;
  wire [1:0] w_byte_offset = w_alu_res[1:0];

  wire [7:0] byte0, byte1, byte2, byte3;
  assign {byte3, byte2, byte1, byte0} = w_mem_read_data;
  wire [15:0] half0, half1;
  assign {half1, half0} = w_mem_read_data;

  wire [31:0] lb0 = {{24{byte0[7]}}, byte0};
  wire [31:0] lb1 = {{24{byte1[7]}}, byte1};  
  wire [31:0] lb2 = {{24{byte2[7]}}, byte2};
  wire [31:0] lb3 = {{24{byte3[7]}}, byte3};
  wire [31:0] lh0 = {{16{half0[15]}}, half0};
  wire [31:0] lh1 = {{16{half1[15]}}, half1};

  assign w_load_process = (w_funct3 == 3'b000) ? // LB
                            ( w_byte_offset == 2'b00 ? lb0 :
                              w_byte_offset == 2'b01 ? lb1 :
                              w_byte_offset == 2'b10 ? lb2 : lb3) :
                          (w_funct3 == 3'b001) ? // LH
                            ( w_byte_offset == 2'b00 ? lh0 : lh1) :
                          (w_funct3 == 3'b100) ? // LBU
                            (w_byte_offset == 2'b00 ? {24'd0, byte0} :
                            w_byte_offset == 2'b01 ? {24'd0, byte1} :
                            w_byte_offset == 2'b10 ? {24'd0, byte2} : {24'd0, byte3}) :
                          (w_funct3 == 3'b101) ? // LHU
                            (w_byte_offset == 2'b00 ? {16'd0, half0} : {16'd0, half1}) :
                          w_mem_read_data; // LW

assign w_final_data = w_mem_read ? w_load_process : w_alu_res;

  always @(posedge clk) begin
    if (rst) begin
      halt <= 0;
      trace_writeback_pc <= 0;
      trace_writeback_inst <= NOP;
    end else begin
      halt <= w_halt;
      trace_writeback_pc <= w_pc;
      trace_writeback_inst <= w_inst;
    end
  end
endmodule

module MemorySingleCycle #(
    parameter NUM_WORDS = 512
) (
    input                    rst,                 // rst for both imem and dmem
    input                    clk,                 // clock for both imem and dmem
	                                              // The memory reads/writes on @(negedge clk)
    input      [`REG_SIZE:0] pc_to_imem,          // must always be aligned to a 4B boundary
    output reg [`REG_SIZE:0] inst_from_imem,      // the value at memory location pc_to_imem
    input      [`REG_SIZE:0] addr_to_dmem,        // must always be aligned to a 4B boundary
    output reg [`REG_SIZE:0] load_data_from_dmem, // the value at memory location addr_to_dmem
    input      [`REG_SIZE:0] store_data_to_dmem,  // the value to be written to addr_to_dmem, controlled by store_we_to_dmem
    // Each bit determines whether to write the corresponding byte of store_data_to_dmem to memory location addr_to_dmem.
    // E.g., 4'b1111 will write 4 bytes. 4'b0001 will write only the least-significant byte.
    input      [        3:0] store_we_to_dmem
);

  reg [`REG_SIZE:0] mem_array[0:NUM_WORDS-1];
  
  always @(negedge rst) begin
    if (rst == 0) 
      $readmemh("mem_initial_contents.hex", mem_array, 0, NUM_WORDS-1);
  end

  localparam AddrMsb = $clog2(NUM_WORDS) + 1;
  localparam AddrLsb = 2;

  always @(negedge clk) begin
    inst_from_imem <= mem_array[{pc_to_imem[AddrMsb:AddrLsb]}];
  end

  always @(negedge clk) begin
    if (store_we_to_dmem[0]) begin
      mem_array[addr_to_dmem[AddrMsb:AddrLsb]][7:0] <= store_data_to_dmem[7:0];
    end
    if (store_we_to_dmem[1]) begin
      mem_array[addr_to_dmem[AddrMsb:AddrLsb]][15:8] <= store_data_to_dmem[15:8];
    end
    if (store_we_to_dmem[2]) begin
      mem_array[addr_to_dmem[AddrMsb:AddrLsb]][23:16] <= store_data_to_dmem[23:16];
    end
    if (store_we_to_dmem[3]) begin
      mem_array[addr_to_dmem[AddrMsb:AddrLsb]][31:24] <= store_data_to_dmem[31:24];
    end
    // dmem is "read-first": read returns value before the write
    load_data_from_dmem <= mem_array[{addr_to_dmem[AddrMsb:AddrLsb]}];
  end
endmodule

module Processor (
    input                 clk,
    input                 rst,
    output                halt,
    output [ `REG_SIZE:0] trace_writeback_pc,
    output [`INST_SIZE:0] trace_writeback_inst
);

  wire [`INST_SIZE:0] inst_from_imem;
  wire [ `REG_SIZE:0] pc_to_imem, mem_data_addr, mem_data_loaded_value, mem_data_to_write;
  wire [         3:0] mem_data_we;

  // This wire is set by cocotb to the name of the currently-running test, to make it easier
  // to see what is going on in the waveforms.
  wire [(8*32)-1:0] test_case;

  MemorySingleCycle #(
      .NUM_WORDS(8192)
  ) memory (
    .rst                 (rst),
    .clk                 (clk),
    // imem is read-only
    .pc_to_imem          (pc_to_imem),
    .inst_from_imem      (inst_from_imem),
    // dmem is read-write
    .addr_to_dmem        (mem_data_addr),
    .load_data_from_dmem (mem_data_loaded_value),
    .store_data_to_dmem  (mem_data_to_write),
    .store_we_to_dmem    (mem_data_we)
  );

  DatapathPipelined datapath (
    .clk                  (clk),
    .rst                  (rst),
    .pc_to_imem           (pc_to_imem),
    .inst_from_imem       (inst_from_imem),
    .addr_to_dmem         (mem_data_addr),
    .store_data_to_dmem   (mem_data_to_write),
    .store_we_to_dmem     (mem_data_we),
    .load_data_from_dmem  (mem_data_loaded_value),
    .halt                 (halt),
    .trace_writeback_pc   (trace_writeback_pc),
    .trace_writeback_inst (trace_writeback_inst)
  );
endmodule