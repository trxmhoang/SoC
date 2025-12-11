`timescale 1ns / 1ps
module tb_reg;
reg clk, rst, we;
reg [4:0] rs1, rs2, rd;
reg [31:0] rd_data;
wire [31:0] rs1_data, rs2_data;

integer i, pass, fail;
reg [31:0] wr_val [0:31];
reg [31:0] exp_val;

RegFile dut (
    .clk (clk),
    .rst (rst),
    .we  (we),
    .rs1 (rs1),
    .rs2 (rs2),
    .rd  (rd),
    .rd_data (rd_data),
    .rs1_data (rs1_data),
    .rs2_data (rs2_data)
);

task divi;
    $display ("%0s", {80{"-"}});
endtask

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

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

task setup;
    begin
        rst = 1;
        repeat (2) @(posedge clk);
        #1;
        rst = 0;
        we = 0;
        @(posedge clk);
    end
endtask

task wr (input [4:0] reg_num, input [31:0] val);
    begin
        divi();
        $display ("[WRITE] Time = %0t | rd  = 0x%2h, Data = 0x%2h", $time, reg_num, val);
        divi();

        @(posedge clk);
        #1;
        we = 1;
        rd = reg_num;
        rd_data = val;

        @(posedge clk);
        #1;
        we = 0;
    end
endtask

task check (input [4:0] reg_num, input [31:0] exp);
    begin
        rs1 = reg_num;
        @(negedge clk);
        #1;
        if (rs1_data === exp) begin
            $display ("[PASS]  Time = %0t | rs1 = 0x%2h, Expected = 0x%8h, Output = 0x%8h", $time, reg_num, exp, rs1_data);
            pass = pass + 1;
        end else begin
            $display ("[FAIL]  Time = %0t | rs1 = 0x%2h, Expected = 0x%8h, Output = 0x%8h", $time, reg_num, exp, rs1_data);
            fail = fail + 1;
        end
    end
endtask

task check_all (input [4:0] reg1, input [31:0] exp1, input [4:0] reg2, input [31:0] exp2);
    begin
        rs1 = reg1;
        rs2 = reg2;
        @(negedge clk);
        #1;

        if (rs1_data === exp1) begin
            $display ("[PASS]  Time = %0t | rs1 = 0x%2h, Expected = 0x%8h, Output = 0x%8h", $time, reg1, exp1, rs1_data);
            pass = pass + 1;
        end else begin
            $display ("[FAIL]  Time = %0t | rs1 = 0x%2h, Expected = 0x%8h, Output = 0x%8h", $time, reg1, exp1, rs1_data);
            fail = fail + 1;
        end

        if (rs2_data === exp2) begin
            $display ("[PASS]  Time = %0t | rs2 = 0x%2h, Expected = 0x%8h, Output = 0x%8h", $time, reg2, exp2, rs2_data);
            pass = pass + 1;
        end else begin
            $display ("[FAIL]  Time = %0t | rs2 = 0x%2h, Expected = 0x%8h, Output = 0x%8h", $time, reg2, exp2, rs2_data);
            fail = fail + 1;
        end
    end
endtask

task init (input [4:0] reg1, input [4:0] reg2, input [31:0] exp);
    begin
        @(negedge clk);
        #1;
        if (rs1_data != 0 || rs2_data != 0) begin
            $display ("[FAIL]  Time = %0t | rs1 = 0x%2h and rs2 = 0x%2h should be initialized to 0", $time, reg1, reg2);
            fail = fail + 1;
        end else begin
            $display ("[PASS]  Time = %0t | rs1 = 0x%2h and rs2 = 0x%2h initialized to 0", $time, reg1, reg2);
            pass = pass + 1;
        end
    end
endtask

initial begin
    pass = 0;
    fail = 0;

    msg ("TEST 1: WRITE AND READ x0");
    setup();
    check (5'd0, 32'd0);

    wr (5'd0, 32'hFFFF_FFFF);
    check (5'd0, 32'd0);

    wr (5'd0, 32'h1234_5678);
    check (5'd0, 32'd0);

    msg ("TEST 2: WRITE AND READ x1");
    setup();
    wr (5'd1, 32'h1234_5678);
    check (5'd1, 32'h1234_5678);


    msg ("TEST 3: CHECK ALL REGISTERS");
    setup();
    for (i = 1; i < 32; i = i + 1) begin
        rs1 = i[4:0]; 
        rs2 = i[4:0];
        init (rs1, rs2, 32'd0);

        exp_val = $urandom();
        wr (i[4:0], exp_val);
        check_all (i[4:0], exp_val, i[4:0], exp_val);
    end

    msg ("TEST 4: WRITE ALL AND READ BACK");
    setup();
    wr_val[0] = 32'd0; // x0

    for (i = 1; i < 32; i = i + 1) begin
        wr_val[i] = $urandom();
        wr (i[4:0], wr_val[i]);
    end

    for (i = 1; i < 31; i = i + 1) begin
        check_all (i[4:0], wr_val[i], i + 1, wr_val[i + 1]);
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

    #100;
    $finish;
end
endmodule