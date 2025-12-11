module tb;
reg clk;
reg rst_n;
reg [3:0] btn;
wire [3:0] led;

parameter CLK_PERIOD = 8; // 8ns => 125MHz
parameter DEBOUNCE_WAIT = CLK_PERIOD * 5;
parameter TICK_WAIT = CLK_PERIOD * 100;
parameter PATTERN = 4'b0011;

integer pass, fail;

ex3 dut (
    .clk   (clk),
    .rst_n (rst_n),
    .btn   (btn),
    .led   (led)
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

task check (input [3:0] exp_led);
    begin
        $display ("[OUTPUT] Time = %0t | LED = 4'b%4b", $time, led);
        $display ("[EXPECT] Time = %0t | LED = 4'b%4b", $time, exp_led);

        if (led === exp_led) begin
            $display ("======> PASSED");
            pass = pass + 1;
        end else begin
            $display ("======> FAILED");
            fail = fail + 1;
        end
    end
endtask

task press (input [3:0] btn_press);
    begin
        case (btn_press)
            4'b0001: $display ("Button 0 is pressed");
            4'b0010: $display ("Button 1 is pressed");
            4'b0100: $display ("Button 2 is pressed");
            4'b1000: $display ("Button 3 is pressed");
            default: $display ("More than one button is pressed");
        endcase

        btn = btn_press;
        #(DEBOUNCE_WAIT);
        btn = 4'b0000;
        #(DEBOUNCE_WAIT);
    end
endtask

initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

initial begin
    rst_n = 0;
    btn = 4'b0000;
    pass = 0;
    fail = 0;
    #100;
    rst_n = 1;
    #100;

    msg ("TEST 1: INITIAL VALUE CHECK");
    check (PATTERN);

    msg ("TEST 2: BUTTON 1 PRESS (SHIFT LEFT) CHECK");
    press (4'b0010);

    #(TICK_WAIT);
    check (4'b0110);

    #(TICK_WAIT);
    check (4'b1100);

    #(TICK_WAIT);
    check (4'b1001);

    #(TICK_WAIT);
    check (4'b0011);

    msg ("TEST 3: BUTTON 2 PRESS (SHIFT RIGHT) CHECK");
    press (4'b0100);

    #(TICK_WAIT);
    check (4'b1001);

    #(TICK_WAIT);
    check (4'b1100);

    #(TICK_WAIT);
    check (4'b0110);

    #(TICK_WAIT);
    check (4'b0011); 
    msg ("TEST 4: BUTTON 3 PRESS (PAUSE) CHECK");
    #(TICK_WAIT);
    check (4'b1001);

    press (4'b1000);

    #(TICK_WAIT);
    check (4'b1001);

    #(TICK_WAIT);
    check (4'b1001);

    msg ("TEST 5: BUTTON 0 PRESS (RESET) CHECK");
    press (4'b0001);

    #(TICK_WAIT);
    check (PATTERN);

    #(TICK_WAIT);
    check (PATTERN);

    #(TICK_WAIT);
    check (PATTERN);

    press (4'b0100); 

    #(TICK_WAIT);
    check (4'b1001);

    #(TICK_WAIT);
    check (4'b1100);

    msg ("TEST 6: RESET CHECK");
    $display ("Reseting...");
    rst_n = 0;

    #(TICK_WAIT);
    check (PATTERN);

    press (4'b0010);
    #(TICK_WAIT);
    check (PATTERN);

    #(TICK_WAIT);
    check (PATTERN);

    press (4'b0100);
    #(TICK_WAIT);
    check (PATTERN);

    #(TICK_WAIT);
    check (PATTERN);

    #(CLK_PERIOD * 5);
    $display ("Releasing reset...");
    rst_n = 1;
    #10;

    check (PATTERN);

    press (4'b0010);

    #(TICK_WAIT);
    check (4'b0110);

    #(TICK_WAIT);
    check (4'b1100);

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