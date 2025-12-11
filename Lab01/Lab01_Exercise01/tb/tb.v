module tb;
reg clk;
reg rst_n;
reg [3:0] button;
wire [2:0] hor_led;
wire [2:0] ver_led;
wire [3:0] bcd0;
wire [3:0] bcd1;
wire [3:0] bcd2;
wire [3:0] bcd3;

parameter RED = 3'b100;
parameter YELLOW = 3'b110;
parameter GREEN = 3'b010;
parameter CLK_PERIOD = 8; // 8ns => 125MHz

integer pass, fail;

`ifdef SIMULATION
    //for sim, debounce is 100 cycles + margin
    parameter DB = (100 * CLK_PERIOD) + 70; // 870ns
    //for sim, a sec is 100 clock cycles + margin
    parameter WAIT_1S  = (100 * CLK_PERIOD) * 1 + 20; 
    parameter WAIT_2S  = (100 * CLK_PERIOD) * 2 + 20; 
    parameter WAIT_3S  = (100 * CLK_PERIOD) * 3 + 20;
    parameter WAIT_4S  = (100 * CLK_PERIOD) * 4 + 20;
    parameter WAIT_5S  = (100 * CLK_PERIOD) * 5 + 20;
    parameter WAIT_6S  = (100 * CLK_PERIOD) * 6 + 20;
`else
    parameter DB = 10_000_000; // 10ms
    parameter WAIT_1S  = 1_100_000_000;
    parameter WAIT_2S  = 2_000_000_000;
    parameter WAIT_3S  = 64'd3_000_000_000;
    parameter WAIT_4S  = 64'd4_000_000_000;
    parameter WAIT_5S  = 64'd5_000_000_000;
    parameter WAIT_6S  = 64'd6_000_000_000;
`endif

ex1 dut (
    .clk (clk),
    .rst_n (rst_n),
    .button (button),
    .hor_led (hor_led),
    .ver_led (ver_led),
    .bcd0 (bcd0),
    .bcd1 (bcd1),
    .bcd2 (bcd2),
    .bcd3 (bcd3)
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

task check (input [3:0] exp_bcd3, input [3:0] exp_bcd2, input [3:0] exp_bcd1, input [3:0] exp_bcd0, input [2:0] exp_hor_led, input [2:0] exp_ver_led);
    begin
        #10;
        $display ("[EXPECT] Time = %0t | 7SEGs = %0h%0h-%0h%0h, HOR_LED = %b, VER_LED = %b", $time, exp_bcd3, exp_bcd2, exp_bcd1, exp_bcd0, exp_hor_led, exp_ver_led);

        $display ("[OUTPUT] Time = %0t | 7SEGs = %0h%0h-%0h%0h, HOR_LED = %b, VER_LED = %b", $time, bcd3, bcd2, bcd1, bcd0, hor_led, ver_led);

        if ((bcd0 == exp_bcd0) && (bcd1 == exp_bcd1) && (bcd2 == exp_bcd2) && (bcd3 == exp_bcd3) && (hor_led == exp_hor_led) && (ver_led == exp_ver_led)) begin
            $display ("======> PASSED");
            pass = pass + 1;
        end else begin
            $display ("======> FAILED");
            fail = fail + 1;
        end
    end
endtask

task incr;
    begin
        button = 4'b0010;
        #(DB);
        button = 4'b0000;
        #(DB);
    end
endtask

task decr;
    begin
        button = 4'b0100;
        #(DB);
        button = 4'b0000;
        #(DB);
    end
endtask

task save;
    begin
        button = 4'b1000;
        #(DB);
        button = 4'b0000;
        #(DB);
    end
endtask

task mode;
    begin
        button = 4'b0001;
        #(DB);
        button = 4'b0000;
        #(DB);
    end
endtask

initial begin 
    clk = 0;
    forever #4 clk = ~clk; 
end
//F = 125MHz clock -> T = 8ns period

initial begin
    $dumpfile ("tb.vcd");
    $dumpvars (0, tb);
    
    rst_n = 1'b0;
    button = 4'b0000;
    pass = 0;
    fail = 0;
    #100;
    rst_n = 1'b1;
    #100;

    msg ("TEST 1: FSM AUTO MODE TEST");
    #(WAIT_1S);
    check (4'd1, 4'd15, 4'd0, 4'd3, RED, GREEN);

    #(WAIT_3S);
    check (4'd1, 4'd15, 4'd0, 4'd2, RED, YELLOW);

    #(WAIT_2S);
    check (4'd1, 4'd15, 4'd0, 4'd3, GREEN, RED);

    #(WAIT_3S);
    check (4'd1, 4'd15, 4'd0, 4'd2, YELLOW, RED);

    #(WAIT_2S);
    check (4'd1, 4'd15, 4'd0, 4'd3, RED, GREEN);

    msg ("TEST 2: FSM BUTTON TEST");
    msg ("\t1. Increase green 3 times, increase yellow 3 times, then save");
    //green
    mode();
    repeat (3) incr();
    check (4'd2, 4'd15, 4'd0, 3'd6, GREEN, GREEN);
    save();
    //yellow
    mode();
    repeat (3) incr();
    check (4'd3, 4'd15, 4'd0, 4'd5, YELLOW, YELLOW);
    save();
    mode();

    #(WAIT_2S);
    check (4'd1, 4'd15, 4'd0, 4'd4, RED, GREEN);
    #(WAIT_6S);
    check (4'd1, 4'd15, 4'd0, 4'd3, RED, YELLOW);

    msg ("\t2. Decrease green 2 times, decrease yellow 1 time, then save");
    //green
    mode();
    repeat (2) decr();
    check (4'd2, 4'd15, 4'd0, 3'd4, GREEN, GREEN);
    save();
    //yellow
    mode();
    decr();
    check (4'd3, 4'd15, 4'd0, 4'd4, YELLOW, YELLOW);
    save();
    mode();

    #(WAIT_1S);
    check (4'd1, 4'd15, 4'd0, 4'd3, RED, GREEN);
    #(WAIT_3S);
    check (4'd1, 4'd15, 4'd0, 4'd4, RED, YELLOW);

    msg ("\t3. Increase green 1 time, decrease yellow 1 time, then no save");
    //green
    mode();
    incr();
    check (4'd2, 4'd15, 4'd0, 3'd5, GREEN, GREEN);
    //yellow
    mode();
    decr();
    check (4'd3, 4'd15, 4'd0, 4'd3, YELLOW, YELLOW);
    mode();

    #(WAIT_2S);
    check (4'd1, 4'd15, 4'd0, 4'd2, RED, GREEN);
    #(WAIT_4S);
    check (4'd1, 4'd15, 4'd0, 4'd2, RED, YELLOW);

    msg ("\t4. Increase green 1 time, decrease yellow 1 time, then save");
    //green
    mode();
    incr();
    check (4'd2, 4'd15, 4'd0, 3'd5, GREEN, GREEN);
    save();
    //yellow
    mode();
    decr();
    check (4'd3, 4'd15, 4'd0, 4'd3, YELLOW, YELLOW);
    save();
    mode();

    #(WAIT_2S);
    check (4'd1, 4'd15, 4'd0, 4'd3, RED, GREEN);
    #(WAIT_4S);
    check (4'd1, 4'd15, 4'd0, 4'd2, RED, YELLOW);

    msg ("TEST 3: RESET TEST");
    mode();
    check (4'd2, 4'd15, 4'd0, 4'd5, GREEN, GREEN);
    $display ("Resetting...");
    rst_n = 1'b0;
    #(WAIT_2S);
    check (4'd1, 4'd15, 4'd0, 4'd0, RED, RED);

    mode();
    check (4'd1, 4'd15, 4'd0, 4'd0, RED, RED);

    mode();
    check (4'd1, 4'd15, 4'd0, 4'd0, RED, RED);

    $display ("Releasing reset...");
    rst_n = 1'b1;
    #800;
    #(WAIT_1S);
    check (4'd1, 4'd15, 4'd0, 4'd4, RED, GREEN);
    #(WAIT_5S);
    check (4'd1, 4'd15, 4'd0, 4'd2, RED, YELLOW);

    msg ("TEST 4: MIN, MAX BOUNDARY TEST");
    msg ("\t1. Increase green 94 times, increase yellow 17 times to reach max");
    //green 
    mode();
    repeat (94) incr();
    check (4'd2, 4'd15, 4'd9, 4'd9, GREEN, GREEN);
    save();
    //yellow
    mode();
    repeat (17) incr();
    check (4'd3, 4'd15, 4'd2, 4'd0, YELLOW, YELLOW);
    save();
    mode();
    
    msg ("\t 2. Increase green 3 times, increase yellow 5 times");
    //green 
    mode();
    repeat (3) incr();
    check (4'd2, 4'd15, 4'd9, 4'd9, GREEN, GREEN);
    save();
    //yellow
    mode();
    repeat (5) incr();
    check (4'd3, 4'd15, 4'd2, 4'd0, YELLOW, YELLOW);
    save();
    mode();

    msg ("\t 3. Decrease green 97 times, decrease yellow 19 times to reach min");
    //green 
    mode();
    repeat (97) decr();
    check (4'd2, 4'd15, 4'd0, 4'd2, GREEN, GREEN);
    save();
    //yellow
    mode();
    repeat (19) decr();
    check (4'd3, 4'd15, 4'd0, 4'd1, YELLOW, YELLOW);
    save();
    mode();

    msg ("\t 4. Decrease green 8 times, decrease yellow 3 times");
    //green 
    mode();
    repeat (8) decr();
    check (4'd2, 4'd15, 4'd0, 4'd2, GREEN, GREEN);
    save();
    //yellow
    mode();
    repeat (3) decr();
    check (4'd3, 4'd15, 4'd0, 4'd1, YELLOW, YELLOW);
    save();
    mode();

    #100;
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