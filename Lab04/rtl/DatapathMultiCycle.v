/* INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ns

// registers are 32 bits in RV32
`define REG_SIZE 31

// RV opcodes are 7 bits
`define OPCODE_SIZE 6

// Don't forget your CLA and Divider
/* `include "cla.v"
`include "DividerUnsignedPipelined.v" */

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

  // TODO: copy your homework #3 code here
  localparam NumRegs = 32;
  reg [`REG_SIZE:0] regs[0:NumRegs-1];
  integer i;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      for (i = 0; i < NumRegs; i = i + 1) begin
        regs[i] <= 0;
      end
    end else if (we && (rd != 0)) begin
      regs[rd] <= rd_data;
    end
  end

  always @(*) begin
    rs1_data = (rs1 == 0) ? 32'd0 : regs[rs1];
    rs2_data = (rs2 == 0) ? 32'd0 : regs[rs2];
  end
endmodule

module DatapathMultiCycle (
    input                    clk,
    input                    rst,
    output reg               halt,
    output     [`REG_SIZE:0] pc_to_imem,
    input      [`REG_SIZE:0] inst_from_imem,
    // addr_to_dmem is a read-write port
    output reg [`REG_SIZE:0] addr_to_dmem,
    input      [`REG_SIZE:0] load_data_from_dmem,
    output reg [`REG_SIZE:0] store_data_to_dmem,
    output reg [        3:0] store_we_to_dmem
);

  // TODO: your code here (largely based on homework #3)
  // components of the instruction
  wire [           6:0] inst_funct7;
  wire [           4:0] inst_rs2;
  wire [           4:0] inst_rs1;
  wire [           2:0] inst_funct3;
  wire [           4:0] inst_rd;
  wire [`OPCODE_SIZE:0] inst_opcode;

  // split R-type instruction - see section 2.2 of RiscV spec
  assign {inst_funct7, inst_rs2, inst_rs1, inst_funct3, inst_rd, inst_opcode} = inst_from_imem;

  // setup for I, S, B & J type instructions
  // I - short immediates and loads
  wire [11:0] imm_i;
  assign imm_i = inst_from_imem[31:20];
  wire [ 4:0] imm_shamt = inst_from_imem[24:20];

  // S - stores
  wire [11:0] imm_s;
  assign imm_s = {inst_funct7, inst_rd};

  // B - conditionals
  wire [12:0] imm_b;
  assign {imm_b[12], imm_b[10:1], imm_b[11], imm_b[0]} = {inst_funct7, inst_rd, 1'b0};

  // J - unconditional jumps
  wire [20:0] imm_j;
  assign {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], imm_j[0]} = {inst_from_imem[31:12], 1'b0};

  wire [`REG_SIZE:0] imm_i_sext = {{20{imm_i[11]}}, imm_i[11:0]};
  wire [`REG_SIZE:0] imm_s_sext = {{20{imm_s[11]}}, imm_s[11:0]};
  wire [`REG_SIZE:0] imm_b_sext = {{19{imm_b[12]}}, imm_b[12:0]};
  wire [`REG_SIZE:0] imm_j_sext = {{11{imm_j[20]}}, imm_j[20:0]};

  // opcodes - see section 19 of RiscV spec
  localparam [`OPCODE_SIZE:0] OpLoad    = 7'b00_000_11;
  localparam [`OPCODE_SIZE:0] OpStore   = 7'b01_000_11;
  localparam [`OPCODE_SIZE:0] OpBranch  = 7'b11_000_11;
  localparam [`OPCODE_SIZE:0] OpJalr    = 7'b11_001_11;
  localparam [`OPCODE_SIZE:0] OpMiscMem = 7'b00_011_11;
  localparam [`OPCODE_SIZE:0] OpJal     = 7'b11_011_11;

  localparam [`OPCODE_SIZE:0] OpRegImm  = 7'b00_100_11;
  localparam [`OPCODE_SIZE:0] OpRegReg  = 7'b01_100_11;
  localparam [`OPCODE_SIZE:0] OpEnviron = 7'b11_100_11;

  localparam [`OPCODE_SIZE:0] OpAuipc   = 7'b00_101_11;
  localparam [`OPCODE_SIZE:0] OpLui     = 7'b01_101_11;

  wire inst_lui    = (inst_opcode == OpLui    );
  wire inst_auipc  = (inst_opcode == OpAuipc  );
  wire inst_jal    = (inst_opcode == OpJal    );
  wire inst_jalr   = (inst_opcode == OpJalr   );

  wire inst_beq    = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b000);
  wire inst_bne    = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b001);
  wire inst_blt    = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b100);
  wire inst_bge    = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b101);
  wire inst_bltu   = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b110);
  wire inst_bgeu   = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b111);

  wire inst_lb     = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b000);
  wire inst_lh     = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b001);
  wire inst_lw     = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b010);
  wire inst_lbu    = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b100);
  wire inst_lhu    = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b101);

  wire inst_sb     = (inst_opcode == OpStore  ) & (inst_from_imem[14:12] == 3'b000);
  wire inst_sh     = (inst_opcode == OpStore  ) & (inst_from_imem[14:12] == 3'b001);
  wire inst_sw     = (inst_opcode == OpStore  ) & (inst_from_imem[14:12] == 3'b010);

  wire inst_addi   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b000);
  wire inst_slti   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b010);
  wire inst_sltiu  = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b011);
  wire inst_xori   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b100);
  wire inst_ori    = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b110);
  wire inst_andi   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b111);

  wire inst_slli   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b001) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_srli   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b101) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_srai   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b101) & (inst_from_imem[31:25] == 7'b0100000);

  wire inst_add    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b000) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_sub    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b000) & (inst_from_imem[31:25] == 7'b0100000);
  wire inst_sll    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b001) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_slt    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b010) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_sltu   = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b011) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_xor    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b100) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_srl    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b101) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_sra    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b101) & (inst_from_imem[31:25] == 7'b0100000);
  wire inst_or     = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b110) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_and    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b111) & (inst_from_imem[31:25] == 7'd0      );

  wire inst_mul    = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b000    );
  wire inst_mulh   = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b001    );
  wire inst_mulhsu = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b010    );
  wire inst_mulhu  = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b011    );
  wire inst_div    = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b100    );
  wire inst_divu   = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b101    );
  wire inst_rem    = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b110    );
  wire inst_remu   = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b111    );

  wire inst_ecall  = (inst_opcode == OpEnviron) & (inst_from_imem[31:7] == 25'd0  );
  wire inst_fence  = (inst_opcode == OpMiscMem);

  // stall
  reg [3:0] stall_counter;
  wire stall_en;
  wire is_div_op = inst_div | inst_divu | inst_rem | inst_remu;

  always @(posedge clk) begin
    if (rst) begin
      stall_counter <= 0;
    end else begin
      if (is_div_op) begin
        if (stall_counter < 8) begin
          stall_counter <= stall_counter + 1;
        end else begin
          stall_counter <= 0;
        end
      end else begin
        stall_counter <= 0;
      end
    end
  end

  assign stall_en = is_div_op & (stall_counter < 8);

  // program counter
  reg [`REG_SIZE:0] pcNext, pcCurrent;
  always @(posedge clk) begin
    if (rst) begin
      pcCurrent <= 32'd0;
    end else if (!stall_en) begin
      pcCurrent <= pcNext;
    end
  end
  assign pc_to_imem = pcCurrent;

  // cycle/inst._from_imem counters
  reg [`REG_SIZE:0] cycles_current, num_inst_current;
  always @(posedge clk) begin
    if (rst) begin
      cycles_current <= 0;
      num_inst_current <= 0;
    end else begin
      cycles_current <= cycles_current + 1;
      if (!rst && !stall_en) begin
        num_inst_current <= num_inst_current + 1;
      end
    end
  end

  // NOTE: don't rename your RegFile instance as the tests expect it to be `rf`
  // TODO: you will need to edit the port connections, however.
  wire [`REG_SIZE:0] rs1_data;
  wire [`REG_SIZE:0] rs2_data;
  reg [`REG_SIZE:0] rd_data;
  reg rf_we;

  RegFile rf (
    .clk      (clk),
    .rst      (rst),
    .we       (rf_we),
    .rd       (inst_rd),
    .rd_data  (rd_data),
    .rs1      (inst_rs1),
    .rs2      (inst_rs2),
    .rs1_data (rs1_data),
    .rs2_data (rs2_data)
  );

  wire [31:0] cla_res, cla_op_b, cla_op_b_raw;
  wire cla_cin;

  assign cla_op_b_raw = (inst_opcode == OpRegImm) ? imm_i_sext : rs2_data;
  assign cla_op_b = inst_sub ? ~cla_op_b_raw : cla_op_b_raw;
  assign cla_cin = inst_sub ? 1'b1 : 1'b0;

  cla u_cla (
    .a      (rs1_data),
    .b      (cla_op_b),
    .cin    (cla_cin),
    .sum    (cla_res)
  );

  wire [31:0] div_op_a, div_op_b;
  wire is_signed_div;

  assign is_signed_div = inst_div | inst_rem;
  assign div_op_a = (is_signed_div & rs1_data[31]) ? (~rs1_data + 1) : rs1_data;
  assign div_op_b = (is_signed_div & rs2_data[31]) ? (~rs2_data + 1) : rs2_data;

  wire [31:0] div_quot_raw, div_rem_raw;
  DividerUnsignedPipelined u_div (
    .clk (clk),
    .rst (rst),
    .stall (1'b0),
    .i_dividend (div_op_a),
    .i_divisor  (div_op_b),
    .o_quotient (div_quot_raw),
    .o_remainder(div_rem_raw)
  );

  reg [31:0] div_res;
  always @(*) begin
    if (inst_div || inst_divu) begin
      if (rs2_data == 0) begin
        div_res = 32'hFFFF_FFFF;
      end else if (inst_div && (rs1_data == 32'h8000_0000) && (rs2_data == 32'hFFFF_FFFF)) begin
        div_res = 32'h8000_0000;
      end else if (is_signed_div && (rs1_data[31] ^ rs2_data[31])) begin
        div_res = ~div_quot_raw + 32'd1;
      end else begin
        div_res = div_quot_raw;
      end
    end else begin // rem or remu
      if (rs2_data == 0) begin
        div_res = rs1_data;
      end else if (inst_rem && (rs1_data == 32'h8000_0000) && (rs2_data == 32'hFFFF_FFFF)) begin
        div_res = 32'd0;
      end else if (is_signed_div && (rs1_data[31])) begin
        div_res = ~div_rem_raw + 32'd1;
      end else begin
        div_res = div_rem_raw;
      end
    end
  end

  wire [63:0] mul_u, mul_s, mul_su;
  assign mul_u = {32'b0, rs1_data} * {32'b0, rs2_data};
  assign mul_s = $signed(rs1_data) * $signed(rs2_data);
  assign mul_su = $signed(rs1_data) * $signed({1'b0, rs2_data});

  reg take_branch;
  always @(*) begin
    case (inst_funct3)
      3'b000: take_branch = (rs1_data == rs2_data);                   // beq
      3'b001: take_branch = (rs1_data != rs2_data);                   // bne
      3'b100: take_branch = ($signed(rs1_data) < $signed(rs2_data));  // blt
      3'b101: take_branch = ($signed(rs1_data) >= $signed(rs2_data)); // bge
      3'b110: take_branch = (rs1_data < rs2_data);                    // bltu
      3'b111: take_branch = (rs1_data >= rs2_data);                   // bgeu
      default: take_branch = 1'b0;
    endcase
  end

  reg [31:0] load_data;
  always @(*) begin
    case (addr_to_dmem[1:0])
      2'b00: load_data = load_data_from_dmem;
      2'b01: load_data = load_data_from_dmem >> 8;
      2'b10: load_data = load_data_from_dmem >> 16;
      2'b11: load_data = load_data_from_dmem >> 24;
    endcase
  end

  reg illegal_inst;

  always @(*) begin
    illegal_inst = 1'b0;
    pcNext = pcCurrent + 4;
    rf_we = 0;
    rd_data = 0;
    halt = 0;
    addr_to_dmem = 0;
    store_data_to_dmem = 0;
    store_we_to_dmem = 0;
    
    case (inst_opcode)
      OpLui: begin
        // TODO: start here by implementing lui
        rf_we = 1;
        rd_data = {inst_from_imem[31:12], 12'b0};
      end

      OpAuipc: begin
        rf_we = 1;
        rd_data = pcCurrent + {inst_from_imem[31:12], 12'b0};
      end

      OpJal: begin
        rf_we = 1;
        rd_data = pcCurrent + 4;
        pcNext = pcCurrent + imm_j_sext;
      end

      OpJalr: begin
        rf_we = 1;
        rd_data = pcCurrent + 4;
        pcNext = (rs1_data + imm_i_sext) & ~32'd1;
      end

      OpBranch: begin
        if (take_branch) begin
          pcNext = pcCurrent + imm_b_sext;
        end
      end

      OpLoad: begin
        rf_we = 1;
        addr_to_dmem = rs1_data + imm_i_sext;

        case (inst_funct3)
          3'b000: rd_data = {{24{load_data[7]}}, load_data[7:0]};   // lb
          3'b001: rd_data = {{16{load_data[15]}}, load_data[15:0]}; // lh
          3'b010: rd_data = load_data;                              // lw
          3'b100: rd_data = {24'b0, load_data[7:0]};                // lbu
          3'b101: rd_data = {16'b0, load_data[15:0]};               // lhu
        endcase
      end

      OpStore: begin
        addr_to_dmem = rs1_data + imm_s_sext;
        store_data_to_dmem = rs2_data << (addr_to_dmem[1:0] * 8);

        case (inst_funct3)
          3'b000: store_we_to_dmem = 4'b0001 << addr_to_dmem[1:0]; // sb
          3'b001: store_we_to_dmem = 4'b0011 << addr_to_dmem[1:0]; // sh
          3'b010: store_we_to_dmem = 4'b1111;                      // sw
        endcase
      end

      OpRegImm: begin
        rf_we = 1;
        case (inst_funct3)
          3'b000: rd_data = cla_res;                                                   // addi
          3'b010: rd_data = ($signed(rs1_data) < $signed(imm_i_sext)) ? 32'd1 : 32'd0; // slti
          3'b011: rd_data = (rs1_data < imm_i_sext) ? 32'd1 : 32'd0;                   // sltiu
          3'b100: rd_data = rs1_data ^ imm_i_sext;                                     // xori
          3'b110: rd_data = rs1_data | imm_i_sext;                                     // ori
          3'b111: rd_data = rs1_data & imm_i_sext;                                     // andi
          3'b001: rd_data = rs1_data << imm_shamt;                                     // slli
          3'b101: begin
            if (inst_funct7 == 7'd0) begin
              rd_data = rs1_data >> imm_shamt;                                         // srli
            end else begin
              rd_data = $signed(rs1_data) >>> imm_shamt;                               // srai
            end
          end
        endcase
      end

      OpRegReg: begin
        if (is_div_op) begin
          rf_we = !stall_en;
        end else begin
          rf_we = 1;
        end

        if (inst_funct7 == 7'd1) begin
          case (inst_funct3)
            3'b000: rd_data = rs1_data * rs2_data;             // mul
            3'b001: rd_data = mul_s[63:32];                    // mulh
            3'b010: rd_data = mul_su[63:32];                   // mulhsu
            3'b011: rd_data = mul_u[63:32];                    // mulhu
            3'b100, 3'b101, 3'b110, 3'b111: rd_data = div_res; // div, divu, rem, remu
          endcase
        end else begin
          case (inst_funct3) 
            3'b000: rd_data = cla_res;                                                 // add, sub
            3'b001: rd_data = rs1_data << rs2_data[4:0];                               // sll
            3'b010: rd_data = ($signed(rs1_data) < $signed(rs2_data)) ? 32'd1 : 32'd0; // slt
            3'b011: rd_data = (rs1_data < rs2_data) ? 32'd1 : 32'd0;                   // sltu
            3'b100: rd_data = rs1_data ^ rs2_data;                                     // xor
            3'b101: begin
              if (inst_funct7[5]) rd_data = $signed(rs1_data) >>> rs2_data[4:0];       // sra
              else rd_data = rs1_data >> rs2_data[4:0];                                // srl
            end
            3'b110: rd_data = rs1_data | rs2_data;                                     // or
            3'b111: rd_data = rs1_data & rs2_data;                                     // and
          endcase
        end
      end

      OpEnviron: begin
        if (inst_from_imem[31:7] == 25'd0) halt = 1'b1; // ecall
      end

      default: begin
        illegal_inst = 1'b1;
      end
    endcase
  end
endmodule

module MemorySingleCycle #(
    parameter NUM_WORDS = 512
) (
  input                    rst,                 // rst for both imem and dmem
  input                    clock_mem,           // clock for both imem and dmem
  input      [`REG_SIZE:0] pc_to_imem,          // must always be aligned to a 4B boundary
  output reg [`REG_SIZE:0] inst_from_imem,      // the value at memory location pc_to_imem
  input      [`REG_SIZE:0] addr_to_dmem,        // must always be aligned to a 4B boundary
  output reg [`REG_SIZE:0] load_data_from_dmem, // the value at memory location addr_to_dmem
  input      [`REG_SIZE:0] store_data_to_dmem,  // the value to be written to addr_to_dmem, controlled by store_we_to_dmem
  // Each bit determines whether to write the corresponding byte of store_data_to_dmem to memory location addr_to_dmem.
  // E.g., 4'b1111 will write 4 bytes. 4'b0001 will write only the least-significant byte.
  input      [        3:0] store_we_to_dmem
);

  // memory is arranged as an array of 4B words
  reg [`REG_SIZE:0] mem_array[0:NUM_WORDS-1];

  // preload instructions to mem_array
  always @(posedge rst) begin
    $readmemh("mem_initial_contents.hex", mem_array);
  end

  localparam AddrMsb = $clog2(NUM_WORDS) + 1;
  localparam AddrLsb = 2;

  always @(posedge clock_mem) begin
    inst_from_imem <= mem_array[{pc_to_imem[AddrMsb:AddrLsb]}];
  end

  always @(negedge clock_mem) begin
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

/*
This shows the relationship between clock_proc and clock_mem. The clock_mem is
phase-shifted 90° from clock_proc. You could think of one proc cycle being
broken down into 3 parts. During part 1 (which starts @posedge clock_proc)
the current PC is sent to the imem. In part 2 (starting @posedge clock_mem) we
read from imem. In part 3 (starting @negedge clock_mem) we read/write memory and
prepare register/PC updates, which occur at @posedge clock_proc.

        ____
 proc: |    |______
           ____
 mem:  ___|    |___
*/
module Processor (
    input  clock_proc,
    input  clock_mem,
    input  rst,
    output halt
);

  wire [`REG_SIZE:0] pc_to_imem, inst_from_imem, mem_data_addr, mem_data_loaded_value, mem_data_to_write;
  wire [        3:0] mem_data_we;

  // This wire is set by cocotb to the name of the currently-running test, to make it easier
  // to see what is going on in the waveforms.
  wire [(8*32)-1:0] test_case;

  MemorySingleCycle #(
      .NUM_WORDS(8192)
  ) memory (
    .rst                 (rst),
    .clock_mem           (clock_mem),
    // imem is read-only
    .pc_to_imem          (pc_to_imem),
    .inst_from_imem      (inst_from_imem),
    // dmem is read-write
    .addr_to_dmem        (mem_data_addr),
    .load_data_from_dmem (mem_data_loaded_value),
    .store_data_to_dmem  (mem_data_to_write),
    .store_we_to_dmem    (mem_data_we)
  );

  DatapathMultiCycle datapath (
    .clk                 (clock_proc),
    .rst                 (rst),
    .pc_to_imem          (pc_to_imem),
    .inst_from_imem      (inst_from_imem),
    .addr_to_dmem        (mem_data_addr),
    .store_data_to_dmem  (mem_data_to_write),
    .store_we_to_dmem    (mem_data_we),
    .load_data_from_dmem (mem_data_loaded_value),
    .halt                (halt)
  );
endmodule
