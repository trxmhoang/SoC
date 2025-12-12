`timescale 1ns / 1ps
module tb_pipelined;
reg clk, rst;
wire halt;
wire [31:0] trace_pc, trace_inst;
integer i, test, timeout, pass, fail;

Processor dut (
    .clk  (clk),
    .rst  (rst),
    .halt (halt),
    .trace_writeback_pc (trace_pc),
    .trace_writeback_inst (trace_inst)
);

task br;
    $display ("%0s", {80{"="}});
endtask

task msg (input [700:0] txt);
    begin
        br();
        $display ("%0s", txt);
        br();
    end
endtask

task load_inst (input [31:0] addr, input [31:0] inst);
    begin
        dut.memory.mem_array[addr >> 2] = inst;
    end
endtask

task check (input [200:0] txt, input [4:0] reg_num, input [31:0] exp);
    begin
        if (dut.datapath.rf.regs[reg_num] === exp) begin
            $display ("[PASS] Time = %0t | %s | Output x%0d = 0x%8h", $time, txt, reg_num, dut.datapath.rf.regs[reg_num]);
            pass = pass + 1;
        end else begin
            $display ("[FAIL] Time = %0t | %s | Expect x%0d = 0x%8h | Output x%0d = 0x%8h", $time, txt, reg_num, exp, reg_num, dut.datapath.rf.regs[reg_num]);
            fail = fail + 1;
        end
    end
endtask

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    msg ("TEST BEGIN");
    rst = 1;
    timeout = 0;
    pass = 0;
    fail = 0;
    test = 0;
    repeat (5) @(posedge clk);
    #1;
    rst = 0;
    #1;

    msg ("TEST 1");
    load_inst (32'h00, 32'h00a00093); // ADDI x1, x0, 10
    load_inst (32'h04, 32'hffb00113); // ADDI x2, x0, -5
    load_inst (32'h08, 32'h002081b3); // ADD x3, x1, x2 (5)
    load_inst (32'h0C, 32'h40208233); // SUB x4, x1, x2 (15)
    load_inst (32'h10, 32'h0020f2b3); // AND x5, x1, x2 (10)
    load_inst (32'h14, 32'h0020e333); // OR x6, x1, x2 (-5)
    load_inst (32'h18, 32'h0020c3b3); // XOR x7, x1, x2 (-15)
    load_inst (32'h1C, 32'h00209413); // SLLI x8, x1, 2 (40)
    load_inst (32'h20, 32'h40115493); // SRAI x9, x2, 1 (-3)
    load_inst (32'h24, 32'h00115513); // SRLI x10, x2, 1
    load_inst (32'h28, 32'h001125b3); // SLT x11, x2, x1 (1)
    load_inst (32'h2C, 32'h00113633); // SLTU x12, x2, x1 (0)
    load_inst (32'h30, 32'h021086b3); // MUL x13, x1, x1 (100)
    load_inst (32'h34, 32'h0220c733); // DIV x14, x1, x2 (-2)
    load_inst (32'h38, 32'h0220e7b3); // REM x15, x1, x2 (0)
    load_inst (32'h3C, 32'h02115833); // DIVU x16, x2, x1
    load_inst (32'h40, 32'h06302223); // SW x3, 100(x0)
    load_inst (32'h44, 32'h06402903); // LW x18, 100(x0)
    load_inst (32'h48, 32'h00108463); // BEQ x1, x1, 8
    load_inst (32'h4C, 32'h06300993); // (Skipped)
    load_inst (32'h50, 32'h00100993); // ADDI x19, x0, 1
    load_inst (32'h54, 32'h00800a6f); // JAL x20, 8
    load_inst (32'h58, 32'h06300a93); // (Skipped)
    load_inst (32'h5C, 32'h00200a93); // ADDI x21, x0, 2
    load_inst (32'h60, 32'h12345b37); // LUI x22, 0x12345
    load_inst(32'h68, 32'h0050cb93);  // XORI x23, x1, 5
    load_inst (32'h6C, 32'h00f0fc13); // ANDI x24, x1, 0xF
    load_inst (32'h70, 32'hf006ec93); // ORI x25, x13, 0xFF00
    load_inst (32'h74, 32'h0283ad13); // SLTI x26, x7, 0x28
    load_inst (32'h78, 32'hff143d93); // SLTIU x27, x8, 0xfffffff1
    load_inst (32'h7C, 32'h01309e33); // SLL x28, x1, x19 
    load_inst (32'h80, 32'h01335eb3); // SRL x29, x6, x19
    load_inst (32'h84, 32'h41335f33); // SRA x30, x6, x19
    load_inst (32'h8C, 32'h03b77fb3); // REMU x31, x14, x27
    load_inst(32'h90, 32'h00000073); // HALT

    timeout = 0;
    pass = 0;
    fail = 0;

    while (!halt && timeout < 1000) begin
        #10 timeout = timeout + 10;
    end

    if (test == 0) begin
        check ("ADDI x1, x0, 10", 1, 10);
        check ("ADDI x2, x0, -5", 2, -5);
        check ("ADD x3, x1, x2", 3, 5);
        check ("SUB x4, x1, x2", 4, 15);
        check ("AND x5, x1, x2", 5, 10);
        check ("OR x6, x1, x2", 6, -5);
        check ("XOR x7, x1, x2", 7, -15);
        check ("SLLI x8, x1, 2", 8, 40);
        check ("SRAI x9, x2, 1", 9, -3);
        check ("SRLI x10, x2, 1", 10, 32'h7fff_fffd);
        check ("SLT x11, x2, x1", 11, 1);
        check ("SLTU x12, x2, x1", 12, 0);
        check ("MUL x13, x1, x1", 13, 100);
        check ("DIV x14, x1, x2", 14, -2);
        check ("REM x15, x1, x2", 15, 0);
        check ("DIVU x16, x2, x1", 16, 32'h1999_9999);
        check ("LW x18, 100(x0)", 18, 5);
        check ("ADDI x19, x0, 1", 19, 1);
        check ("JAL x20, 8", 20, 32'h58); // PC of next instruction
        check ("ADDI x21, x0, 2", 21, 2);
        check ("LUI x22, 0x12345", 22, 32'h1234_5000);
        check ("XORI x23, x1, 5", 23, 32'hf);
        check ("ANDI x24, x1, 0xF", 24, 32'ha);
        check ("ORI x25, x13, 0xFF00", 25, 32'hffff_ff64);
        check ("SLTI x26, x7, 0x28", 26, 1);
        check ("SLTIU x27, x8, 0xFFFF_FFF1", 27, 1);
        check ("SLL x28, x1, x19", 28, 20);
        check ("SRL x29, x6, x19", 29, 32'h7FFF_FFFD);
        check ("SRA x30, x6, x19", 30, 32'hFFFF_FFFD);
        check ("REMU x31, x14, x27", 31, 0);

        if (halt) begin
            $display ("[PASS] HALT asserted.");
            pass = pass + 1;
        end else begin
            $display ("[FAIL] HALT is missing.");
            fail = fail + 1;
        end
    end

    msg ("TEST 2 (REUSED REGISTERS)");
    rst = 1;
    repeat (5) @(posedge clk);
    #1;
    rst = 0;
    #1;

    load_inst (32'h0, 32'hffb00093); // ADDI x1, x0, 0xFFFF_FFFB
    load_inst (32'h4, 32'h00300113); // ADDI x2, x0, 3
    load_inst (32'h8, 32'h022091b3); // MULH x3, x1, x2
    load_inst (32'hC, 32'h0220a233); // MULHSU x4, x1, x2
    load_inst (32'h10, 32'h0220b2b3); // MULHU x5, x1, x2
    load_inst (32'h14, 32'he9800313); // ADDI x6, x0, 0xABCD_FE98
    load_inst (32'h18, 32'h06600223); // SB x6, 100(x0)
    load_inst (32'h1C, 32'h06601423); // SH x6, 104(x0)
    load_inst (32'h20, 32'h06400383); // LB x7, 100(x0)
    load_inst (32'h24, 32'h06801403); // LH x8, 104(x0)
    load_inst (32'h28, 32'h00831463); // BNE x6, x8, 8
    load_inst (32'h2C, 32'h06904483); // LBU x9, 105(x0)
    load_inst (32'h30, 32'h06805503); // LHU x10, 104(x0)
    load_inst (32'h34, 32'h00a4c463); // BLT x9, x10, 12
    load_inst (32'h38, 32'h00a4c5b3); // XOR x11, x9, x10 //skipped
    load_inst (32'h3C, 32'h00a4e5b3); // OR x11, x9, x10 // skipped
    load_inst (32'h40, 32'h00a485b3); // ADD x11, x9, x10
    load_inst (32'h44, 32'h00535463); // BGE x6, x5, 8
    load_inst (32'h48, 32'h0062e663); // BLTU x5, x6, 12
    load_inst (32'h4C, 32'h00a4e633); // OR x12, x9, x10 // skip then turned back by bgeu
    load_inst (32'h50, 32'h08200767); // JALR x14, 130(x0)
    load_inst (32'h54, 32'h0004e633); // OR x12, x9, x0
    load_inst (32'h58, 32'h06c02c23); // SW x12, 120(x0)
    load_inst (32'h5C, 32'h07802683); // LW x13, 120(x0)
    load_inst (32'h60, 32'hfe9576e3); // BGEU x10, x9, -20
    load_inst (32'h82, 32'h00000073); // HALT

    test = 1;
    timeout = 0;

    while (!halt && timeout < 1000) begin
        #10 timeout = timeout + 10;
    end

    if (test) begin
        check ("ADDI x1, x0, 0xFFFF_FFFB", 1, 32'hFFFF_FFFB);
        check ("ADDI x2, x0, 3", 2, 32'h3);
        check ("MULH x3, x1, x2", 3, 32'hFFFF_FFFF);
        check ("MULHSU x4, x1, x2", 4, 32'hFFFF_FFFF);
        check ("MULHU x5, x1, x2", 5, 32'h2);
        check ("ADDI x6, x0, 0xABCD_FE98", 6, 32'hFFFF_FE98);
        check ("LB x7, 100(x0)", 7, 32'hFFFF_FF98);
        check ("LH x8, 104(x0)", 8, 32'hFFFF_FE98);
        check ("LBU x9, 105(x0)", 9, 32'h0000_00FE);
        check ("LHU x10, 104(x0)", 10, 32'h0000_FE98);
        check ("ADD x11, x9, x10", 11, 32'h0000_FF96);
        check ("OR x12, x9, x10", 12, 32'h0000_FEFE);
        check ("LW x13, 120(x0)", 13, 32'h0000_00FE);
        check ("JALR x14, 130(x0)", 14, 32'h54); 

        if (halt) begin
            $display ("[PASS] HALT asserted.");
            pass = pass + 1;
        end else begin
            $display ("[FAIL] HALT is missing.");
            fail = fail + 1;
        end
    end 

    msg ("SUMMARY");
    $display ("TOTAL TESTS : %0d", pass + fail);
    $display ("TOTAL PASSED: %0d", pass);
    $display ("TOTAL FAILED: %0d", fail);

    if (fail == 0) 
        $display ("======> ALL TESTS PASSED");
    else if (pass == 0)
        $display ("======> ALL TESTS FAILED");
    else
        $display ("======> SOME TESTS FAILED");
    
    msg ("TEST END");

    #100;
    $finish;
end
endmodule