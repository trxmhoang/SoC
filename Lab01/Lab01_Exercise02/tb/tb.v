module tb;
reg clk;
reg rst_n;
reg sw;
wire [2:0] led;
wire [15:0] bcd;

parameter CLK_PERIOD = 8; // 8ns = 125MHz
parameter TICK_WAIT = (CLK_PERIOD * 50); 

parameter RED = 3'b100;
parameter GREEN = 3'b010;

parameter BCD_2 = 4'd2;
parameter BCD_5 = 4'd5;
parameter BCD_BLANK = 4'hF;
parameter ALL_BLANK = 16'hFFFF;

parameter S0 = {BCD_2, BCD_5, BCD_BLANK, BCD_BLANK}; // "25__"
parameter S1 = {BCD_BLANK, BCD_2, BCD_5, BCD_BLANK}; // "_25_"
parameter S2 = {BCD_BLANK, BCD_BLANK, BCD_2, BCD_5}; // "__25"
parameter S3 = {BCD_5, BCD_BLANK, BCD_BLANK, BCD_2}; // "5__2"

integer pass, fail;

ex2 dut (
    .clk (clk),
    .rst_n (rst_n),
    .sw (sw),
    .led (led),
    .bcd (bcd)
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

task check (input [15:0] exp_bcd, input [2:0] exp_led);
    begin
        $display ("[OUTPUT] Time = %0t | 7SEG = 16'h%4h, LED = 3'b%3b", $time, bcd, led);
        $display ("[EXPECT] Time = %0t | 7SEG = 16'h%4h, LED = 3'b%3b", $time, exp_bcd, exp_led);

        if ((bcd === exp_bcd) && (led === exp_led)) begin
            $display ("======> PASSED");
            pass = pass + 1;
        end else begin
            $display ("======> FAILED");
            fail = fail + 1;
        end
    end
endtask

task mode (input tsw);
    begin
        divi();
        $display ("[SWITCH] Time = %0t | Switching to effect %0d", $time, tsw + 1);
        divi();
        sw = tsw;
    end
endtask

initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

initial begin
    rst_n = 0;
    sw = 0;
    pass = 0;
    fail = 0;
    #100;
    rst_n = 1;
    #100;

    msg ("TEST 1: INITIAL VALUES CHECK");
    check (S0, RED);

    msg ("TEST 2: SCROLL MODE CHECK");
    #(TICK_WAIT);
    check (S1, RED);

    #(TICK_WAIT);
    check (S2, RED);

    #(TICK_WAIT);
    check (S3, RED);

    #(TICK_WAIT);
    check (S0, RED);

    #(TICK_WAIT);
    check (S1, RED);

    msg ("TEST 3: BOUNCE MODE CHECK");
    mode (1);
    #10;
    check (S1, GREEN);

    #(TICK_WAIT);
    check (S2, GREEN);

    #(TICK_WAIT);
    check (S1, GREEN);

    #(TICK_WAIT);
    check (S0, GREEN);

    #(TICK_WAIT);
    check (S1, GREEN);

    msg ("TEST 4: SWITCH BACK TO SCROLL MODE");
    mode (0);
    #10;
    check (S1, RED);

    #(TICK_WAIT);
    check (S2, RED);

    #(TICK_WAIT);
    check (S3, RED);

    msg ("TEST 5: SWITCH BACK TO BOUNCE MODE");
    mode (1);
    #10;
    check (S3, GREEN);

    #(TICK_WAIT);
    check (S2, GREEN);

    #(TICK_WAIT);
    check (S1, GREEN);

    #(TICK_WAIT);
    check (S0, GREEN);

    #(TICK_WAIT);
    check (S1, GREEN);

    msg ("TEST 6: RESET CHECK");
    $display ("Reseting...");
    @(posedge clk);
    rst_n = 0;
    #10;
    check (S0, GREEN);

    #(TICK_WAIT);
    check (S0, GREEN);

    mode (0);
    #10;
    check (S0, RED);

    mode (1);
    $display ("Releasing reset...");
    #(TICK_WAIT);
    rst_n = 1;
    #10;

    check (S0, GREEN);

    #(TICK_WAIT);
    check (S1, GREEN);

    #(TICK_WAIT);
    check (S2, GREEN);

    #(TICK_WAIT);
    check (S1, GREEN);

    #(TICK_WAIT);
    check (S0, GREEN);

    #(TICK_WAIT);
    check (S1, GREEN);
    
    msg ("SUMMARY");
    $display ("TOTAL TESTS : %0d", pass + fail);
    $display ("Total PASSED: %0d", pass);
    $display ("Total FAILED: %0d", fail);

    if (fail == 0)
        $display ("======> ALL TESTS PASSED");
    else if (pass == 0)
        $display ("======> ALL TESTS FAILED");
    else
        $display ("SOME TESTS FAILED");
    
    #100;
    $finish;    
end
endmodule