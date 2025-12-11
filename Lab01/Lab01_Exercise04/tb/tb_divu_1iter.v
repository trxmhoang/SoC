module tb_divu_1iter;
reg [31:0] remainder_in;
reg [31:0] quotient_in;
reg [31:0] dividend_in;
reg [31:0] divisor;

wire [31:0] remainder_out;
wire [31:0] quotient_out;
wire [31:0] dividend_out;

integer pass, fail;

divu_1iter u_dut (
    .remainder_in  (remainder_in),
    .quotient_in   (quotient_in),
    .dividend_in   (dividend_in),
    .divisor       (divisor),

    .remainder_out (remainder_out),
    .quotient_out  (quotient_out),
    .dividend_out  (dividend_out)
);

task divi;
    $display ("---------------------------------------------------------------------------------------------");
endtask

task check (input [31:0] exp_rem, input [31:0] exp_quo, input [31:0] exp_div);
    begin
        $display ("[OUTPUT] Time = %0t | remainder_out = %0d, quotient_out = %0d, dividend_out = %h", $time, remainder_out, quotient_out, dividend_out);
        $display ("[EXPECT] Time = %0t | remainder_out = %0d, quotient_out = %0d, dividend_out = %h", $time, exp_rem, exp_quo, exp_div);

        if ((remainder_out === exp_rem) && (quotient_out === exp_quo) && (dividend_out === exp_div)) begin
            $display ("======> PASSED");
            pass = pass + 1;
        end else begin
            $display ("======> FAILED");
            fail = fail + 1;
        end
    end
endtask

task test (input [31:0] div_in, input [31:0] dvsr, input [31:0] rem_in, input [31:0] quo_in);
    begin
        divi();
        $display ("[TEST]   Time = %0t | dividend_in = %0h, divisor = %0d, remainder_in = %0d, quotient_in = %0d", $time, div_in, dvsr, rem_in, quo_in);
        divi();

        dividend_in  = div_in;
        divisor      = dvsr;
        remainder_in = rem_in;
        quotient_in  = quo_in;
        #10;
    end
endtask

initial begin
    pass = 0;
    fail = 0;
    #10;

    test (32'h8000_0000, 32'd2, 32'd0, 32'd8);
    check (32'd1, 32'd16, 32'd0); 
    
    test (32'h8000_0000, 32'd1, 32'd0, 32'd8);
    check (32'd0, 32'd17, 32'd0); 

    test (32'h0000_0004, 32'd3, 32'd2, 32'd1);
    check (32'd1, 32'd3, 32'd8);

    test (32'h4000_0000, 32'd5, 32'd3, 32'd0);
    check (32'd1, 32'd1, 32'h8000_0000);

    test (32'h0000_0000, 32'd10, 32'd4, 32'd1);
    check (32'd8, 32'd2, 32'h0000_0000);

    test (32'ha000_0000, 32'd3, 32'd2, 32'd5);
    check(32'd2, 32'd11, 32'h4000_0000);

    test (32'h8000_0000, 32'd6, 32'd2, 32'd0);
    check(32'd5, 32'd0, 32'h0000_0000);

    test (32'h8000_0000, 32'd5, 32'd2, 32'd0);
    check (32'd0, 32'd1, 32'h0000_0000);

    test (32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'hFFFF_FFFF);
    check (32'd0, 32'hFFFF_FFFF, 32'hFFFF_FFFE);

    test (32'h1234_5678, 32'd100, 32'd200, 32'd42);
    check (32'd300, 32'd85, 32'h2468_ACF0);

    test (32'h1234_5678, 32'd500, 32'd200, 32'd42);
    check (32'd400, 32'd84, 32'h2468_ACF0);

    test (32'h0000_0000, 32'd1, 32'd0, 32'd123);
    check(32'd0, 32'd246, 32'h0000_0000);

    test (32'h8000_0000, 32'hFFFF_FFFF, 32'd0, 32'd0);
    check(32'd1, 32'd0, 32'h0000_0000);

    divi();
    $display ("SUMMARY");
    divi();
    $display ("TOTAL TESTS : %0d", pass + fail);
    $display ("Total PASSED: %0d", pass);
    $display ("Total FAILED: %0d", fail);

    if (fail == 0)
        $display ("======> ALL TESTS PASSED");
    else
        $display ("======> SOME TESTS FAILED");
    
    #100;
    $finish; 
end
endmodule