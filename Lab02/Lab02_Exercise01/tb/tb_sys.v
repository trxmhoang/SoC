`timescale 1ns / 1ps
module tb_sys;
reg clk;
reg [3:0] btn;
wire [5:0] led;

integer i, pass, fail;

system dut (
   .btn (btn),
   .led (led)
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

task press (input [3:0] tbtn);
    begin
        divi();
        $display ("[TEST]   Time = %0t | btn = 4'b%b (%0d)", $time, tbtn, tbtn);
        divi();
        
        btn = tbtn;
        #10;
    end
endtask

task check (input [5:0] exp_led);
    begin
        $display ("[OUTPUT] Time = %0t | led = 6'b%b (%0d)", $time, led, led);
        $display ("[EXPECT] Time = %0t | led = 6'b%b (%0d)", $time, exp_led, exp_led);

        if (led === exp_led) begin
            $display ("======> PASSED");
            pass = pass + 1;
        end else begin
            $display ("======> FAILED");
            fail = fail + 1;
        end

        btn = 4'b0000;
        #10;
    end
endtask

initial begin
   clk = 0;
   forever #5 clk = ~clk;
end

initial begin
    btn = 4'b0000;
    pass = 0;
    fail = 0;
    #15;

    msg ("INITIAL TEST");
    check (6'd26);

    msg ("FUNCTIONAL TESTS");
    for (i = 0; i < 16; i = i + 1) begin
        press (i[3:0]);
        check (6'd26 + i);
    end

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