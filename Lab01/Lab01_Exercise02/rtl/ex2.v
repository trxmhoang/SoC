module ex2 (
    input wire clk,
    input wire rst_n,
    input wire sw,
    output reg [2:0] led,
    output reg [15:0] bcd
);

`ifdef SIMULATION
    //for sim, a sec is 100 cycles
    parameter CLK_FREQ = 27'd100;
`else
    //for fpga, a sec is 125m cycles
    parameter CLK_FREQ = 27'd125_000_000;
`endif

parameter SHIFT_FREQ = 2;
parameter DIV_COUNT = CLK_FREQ / SHIFT_FREQ;

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

reg [26:0] clk_cnt;
wire tick;
reg [1:0] state;
reg direction; //0: left to right, 1: right to left

assign tick = (clk_cnt == DIV_COUNT - 1);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        clk_cnt <= 27'd0;
    else if (tick)
        clk_cnt <= 27'd0;
    else 
        clk_cnt <= clk_cnt + 1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 0;
        direction <= 0;
    end else if (tick) begin
        //scroll
        if (sw == 0) begin
            if (state == 2'd3)
                state <= 2'd0;
            else 
                state <= state + 1;
        end else begin 
        //bounce
            if (direction == 0) begin
                if (state == 2'd2) begin
                    direction <= 1;
                    state <= 2'd1;
                end else if (state == 2'd3) begin
                    direction <= 1;
                    state <= 2'd2;
                end else
                    state <= state + 1;
            end else begin
                if (state == 2'd0) begin
                    direction <= 0;
                    state <= 2'd1;
                end else 
                    state <= state - 1;
            end
        end
    end else begin
        state <= state;
        direction <= direction;
    end
end

always @(*) begin
    case (state)
        2'd0: bcd = S0;
        2'd1: bcd = S1;
        2'd2: bcd = S2;
        2'd3: bcd = S3;
        default: bcd = ALL_BLANK;
    endcase

    if (sw == 0)
        led = RED;
    else 
        led = GREEN;
end
endmodule