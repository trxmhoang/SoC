module ex3 (
    input wire clk,
    input wire rst_n,
    input wire [3:0] btn,
    output reg [3:0] led
);

`ifdef SIMULATION
    //for sim, a sec is 100 cycles
    parameter CLK_FREQ = 27'd100;
`else
    //for fpga, a sec is 125m cycles
    parameter CLK_FREQ = 27'd125_000_000;
`endif

parameter PATTERN = 4'b0011;
parameter MODE0 = 2'd0;
parameter MODE1 = 2'd1;
parameter MODE2 = 2'd2;
parameter MODE3 = 2'd3;

reg [1:0] mode;
reg [26:0] clk_cnt;
wire tick_1s;
assign tick_1s = (clk_cnt == CLK_FREQ - 1);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        clk_cnt <= 27'd0;
    else if (tick_1s)
        clk_cnt <= 27'd0;
    else
        clk_cnt <= clk_cnt + 1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        mode <= MODE0;
    else if (btn[0])
        mode <= MODE0;
    else if (btn[1])
        mode <= MODE1;
    else if (btn[2])
        mode <= MODE2;
    else if (btn[3])
        mode <= MODE3;
    else
        mode <= mode;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        led <= PATTERN;
    else if (tick_1s) begin
        case (mode)
            MODE1: led <= {led[2:0], led[3]}; //shift left
            MODE2: led <= {led[0], led[3:1]}; //shift right
            MODE3: led <= led;                //pause
            default: led <= PATTERN;          //reset pattern
        endcase
    end else if (btn[0]) 
        led <= PATTERN;
    else 
        led <= led;
end
endmodule