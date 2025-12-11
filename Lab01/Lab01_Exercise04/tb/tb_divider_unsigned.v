module tb_divider_unsigned;
reg  [31:0] dividend;
reg  [31:0] divisor;
wire [31:0] quotient;
wire [31:0] remainder;

integer pass, fail;

divider_unsigned u_dut (
    .dividend  (dividend),
    .divisor   (divisor),
    .quotient  (quotient),
    .remainder (remainder)
);

task divi;
    $display ("------------------------------------------------------------------------");
endtask

task msg (input [700:0] txt);
    begin
        divi();
        $display ("%0s", txt);
        divi();
    end
endtask

task check (input [31:0] exp_quo, input [31:0] exp_rem);
    begin
        $display ("[OUTPUT] Time = %0t | quotient = %0d, remainder = %0d", $time, quotient, remainder);
        $display ("[EXPECT] Time = %0t | quotient = %0d, remainder = %0d", $time, exp_quo, exp_rem);

        if ((quotient === exp_quo) && (remainder === exp_rem)) begin
            $display ("======> PASSED");
            pass = pass + 1;
        end else begin
            $display ("======> FAILED");
            fail = fail + 1;
        end
    end
endtask

task test (input [31:0] div_in, input [31:0] dvsr);
    begin
        divi();
        $display ("[TEST]   Time = %0t | dividend = %0d, divisor = %0d", $time, div_in, dvsr);
        divi();

        dividend = div_in;
        divisor  = dvsr;
        #10;
    end
endtask

initial begin
    pass = 0;
    fail = 0;
    #10;
    
    test (32'd4, 32'd2);
    check (32'd2, 32'd0); 

    test (32'd4, 32'd4);
    check (32'd1, 32'd0); 

    test (32'd10, 32'd4);
    check (32'd2, 32'd2); 

    test (32'd2, 32'd4);
    check(32'd0, 32'd2); 

    test (32'd100, 32'd1);
    check (32'd100, 32'd0);

    test (32'd100, 32'd7);
    check (32'd14, 32'd2);

    test (32'd0, 32'd50);
    check (32'd0, 32'd0);

    test (32'hFFFF_FFFF, 32'd1);
    check (32'hFFFF_FFFF, 32'd0);

    test (32'hFFFF_FFFF, 32'hFFFF_FFFF);
    check (32'd1, 32'd0);

    test (32'hFFFF_FFFF, 32'd2);
    check (32'd2147483647, 32'd1);

    test (32'h8000_0000, 32'd2);
    check (32'd1073741824, 32'd0);

    test (32'd123456789, 32'd987);
    check (32'd125082, 32'd855);

    test (32'd400000, 32'd399999);
    check (32'd1, 32'd1);

    test (32'd1024, 32'd1025);
    check (32'd0, 32'd1024);

    msg ("SUMMARY");
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