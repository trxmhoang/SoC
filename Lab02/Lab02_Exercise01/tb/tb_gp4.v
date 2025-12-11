`timescale 1ns / 1ps
module tb_gp4;
reg [3:0] gin, pin;
reg cin;
wire gout, pout;
wire [2:0] cout;

integer pass, fail;

gp4 dut (
   .gin(gin),
   .pin(pin),
   .cin(cin),
   .gout(gout),
   .pout(pout),
   .cout(cout)
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

task test (input [3:0] tg, input [3:0] tp, input tcin);
    begin
        divi();
        $display ("[TEST]   Time = %0t | gin = 4'b%b, pin = 4'b%b, cin = %b", $time, tg, tp, tcin);
        divi();
        
        gin = tg;
        pin = tp;
        cin = tcin;
        #10;
    end
endtask

task check (input exp_gout, input exp_pout, input [2:0] exp_cout);
    begin
        $display ("[OUTPUT] Time = %0t | gout = %b, pout = %b, cout = 3'b%b", $time, gout, pout, cout);
        $display ("[EXPECT] Time = %0t | gout = %b, pout = %b, cout = 3'b%b", $time, exp_gout, exp_pout, exp_cout);

        if ((gout === exp_gout) && (pout === exp_pout) && (cout === exp_cout)) begin
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

    test (0, 0, 0);
    check (0, 0, 0);

    test (8, 0, 0);
    check (1, 0, 0);

    test (0, 4'b1111, 1);
    check (0, 1, 3'b111);

    test (0, 4'b1111, 0);
    check (0, 1, 0);

    test (4'b1111, 4'b1111, 1);
    check (1, 1, 3'b111);
    
    test (4'b1010, 4'b0101, 0); 
    check (1, 0, 3'b110);

    test (4'b1100, 4'b0011, 1); 
    check (1, 0, 3'b111);

    test (4'b0110, 4'b1001, 0); 
    check (1, 0, 3'b110);
    
    test (4'b0011, 4'b1100, 1); 
    check (1, 0, 3'b111);
    
    test (4'b1001, 4'b0110, 0); 
    check (1, 0, 3'b111);
    
    test (4'b0101, 4'b1010, 1'b1); 
    check (1, 0, 3'b111);
    
    test (4'b1110, 4'b0111, 0); 
    check (1, 0, 3'b110);
    
    test (4'b0001, 4'b1110, 1); 
    check (1, 0, 3'b111);

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