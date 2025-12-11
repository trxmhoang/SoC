`timescale 1ns / 1ps
module tb_cla;
reg [31:0] a, b;
reg cin;
wire [31:0] sum;

integer pass, fail;

cla dut (
   .a(a),
   .b(b),
   .cin(cin),
   .sum(sum)
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

task test (input [31:0] ta, input [31:0] tb, input tcin);
    begin
        divi();
        $display ("[TEST]   Time = %0t | a = 32'h%h, b = 32'h%h, cin = %b", $time, ta, tb, tcin);
        divi();
        
        a = ta;
        b = tb;
        cin = tcin;
        #10;
    end
endtask

task check (input [31:0] exp_sum);
    begin
        $display ("[OUTPUT] Time = %0t | sum = 32'h%h", $time, sum);
        $display ("[EXPECT] Time = %0t | sum = 32'h%h", $time, exp_sum);

        if (sum === exp_sum) begin
            $display ("======> PASSED");
            pass = pass + 1;
        end else begin
            $display ("======> FAILED");
            fail = fail + 1;
        end
    end
endtask

initial begin
    pass = 0;
    fail = 0;
    #10;

    test (32'd15, 32'd10, 1'b0);
    check (32'd25);

    test (32'd100, 32'd200, 1'b1);
    check (32'd301);

    test (32'd0, 32'd0, 1'b0);
    check (32'd0);

    test (32'd0, 32'd0, 1'b1);
    check (32'd1);

    test (32'd1, 32'd0, 1'b0);
    check (32'd1);

    test (32'd1, 32'd1, 1'b0);
    check (32'd2);

    test (32'd1, 32'd1, 1'b1);
    check (32'd3);

    test (32'hFFFF_FFFF, 32'd0, 1'b1);
    check (32'd0);

    test (32'hFFFF_FFFF, 32'd1, 1'b0);
    check (32'd0);

    test (32'hAAAA_AAAA, 32'h5555_5555, 1'b0);
    check (32'hFFFF_FFFF);

    test (32'hAAAA_AAAA, 32'h5555_5555, 1'b1);
    check (32'h0);

    test (32'h0000_0001, 32'hFFFF_FFFF, 1'b0);
    check (32'd0);

    test (32'h0000_0001, 32'hFFFF_FFFF, 1'b1);
    check (32'd1);

    test (32'h8000_0000, 32'h8000_0000, 1'b0);
    check (32'd0);

    test (32'h7FFF_FFFF, 32'd1, 1'b0);
    check (32'h8000_0000);

    test (32'h1234_5678, 32'h8765_4321, 1'b0);
    check (32'h9999_9999);

    test (32'h1234_5678, 32'h8765_4321, 1'b1);
    check (32'h9999_999A);

    test (32'd1, 32'd1000000000, 1'b0);
    check (32'd1000000001);
    
    test (32'd2147483647, 32'd1, 1'b0);
    check (32'd2147483648); 

    test (32'hF0F0_F0F0, 32'h0F0F_0F0F, 1'b0);
    check (32'hFFFF_FFFF);

    test (32'hF0F0_F0F0, 32'h0F0F_0F0F, 1'b1);
    check (32'd0);

    msg ("SUMMARY");
    $display ("TOTAL TESTS : %0d", pass + fail);
    $display ("tOTAL PASSED: %0d", pass);
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