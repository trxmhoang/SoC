`timescale 1ns / 1ps
module tb_div;
reg clk, rst, stall;
reg [31:0] i_dividend, i_divisor;
wire [31:0] o_remainder, o_quotient;

integer i, j;
integer pass, fail;
parameter TEST_CNT = 15;

reg [31:0] i_divd [0:TEST_CNT-1];
reg [31:0] i_divs [0:TEST_CNT-1];
reg [31:0] exp_quot [0:TEST_CNT-1];
reg [31:0] exp_rem  [0:TEST_CNT-1];

DividerUnsignedPipelined dut (
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .i_dividend(i_dividend),
    .i_divisor(i_divisor),
    .o_remainder(o_remainder),
    .o_quotient(o_quotient)
);

task divi;
    $display ("%0s", {80{"-"}});
endtask

task br;
    $display ("%0s", {100{"="}});
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

initial begin
    msg ("TEST BEGIN");

    rst = 1;
    stall = 0;
    i_dividend = 0;
    i_divisor = 1;
    pass = 0;
    fail = 0;
    #20;

    @(negedge clk);
    rst = 0;
    repeat (2) @(posedge clk);

    for (i = 0; i < TEST_CNT; i = i + 1) begin
        @(negedge clk);
        if (i == 0) begin
            i_divd[i] = 100;
            i_divs[i] = 10; // chia het
        end else if (i == 1) begin
            i_divd[i] = 100;
            i_divs[i] = 30; // co du
        end else if (i == 2) begin
            i_divd[i] = 5;
            i_divs[i] = 10; // bi chia < chia
        end else begin
            i_divd[i] = $random;
            i_divs[i] = ($random % 100) + 1;
        end

        i_dividend = i_divd[i];
        i_divisor = i_divs[i];

        exp_quot[i] = i_divd[i] / i_divs[i];
        exp_rem[i]  = i_divd[i] % i_divs[i];
    end

    @(negedge clk);
    i_dividend = 0;
    i_divisor = 1;
end

initial begin
    wait (rst == 0);
    repeat (10) @(posedge clk); // 2 delay + 8 latency = 10

    for (j = 0; j < TEST_CNT; j = j + 1) begin
        @(negedge clk);
        if ((o_quotient === exp_quot[j]) && (o_remainder === exp_rem[j])) begin
            $display("[PASS] Time = %0t | Test #%2d: %d / %d | Output Q = %d, R = %d", $time, j, i_divd[j], i_divs[j], o_quotient, o_remainder);
            pass = pass + 1;
        end else begin
            $display("[FAIL] Time = %0t | Test #%2d: %d / %d | Expect Q = %d, R = %d | Output Q = %d, R = %d", $time, j, i_divd[j], i_divs[j], exp_quot[j], exp_rem[j], o_quotient, o_remainder);
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