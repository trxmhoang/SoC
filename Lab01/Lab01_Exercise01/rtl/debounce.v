module debounce (
    input wire clk,       
    input wire rst_n,     
    input wire btn_in,    
    output reg btn_stable, 
    output reg btn_pulse   
);

`ifdef SIMULATION
    //for sim, debounce is 10 cycles
    parameter STABLE_CNT = 21'd10;
`else
    //for fpga, use the real delay
    parameter STABLE_CNT = 21'd1_250_000;
`endif

reg [20:0] cnt;
reg btn1; 
reg btn2; 
reg btn_stable_pre; 

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        btn1 <= 1;
        btn2 <= 1;
        btn_stable <= 1;
        btn_stable_pre <= 1;
        btn_pulse <= 0;
        cnt <= 0;
    end else begin
        btn_stable_pre <= btn_stable;
        btn1 <= btn_in;
        btn2 <= btn1;

        if (btn2 != btn_stable) 
            if (cnt < STABLE_CNT) cnt <= cnt + 1;
        else 
            cnt <= 0;
        
        if (cnt == STABLE_CNT) 
            btn_stable <= btn2;
        
        if (btn_stable == 0 && btn_stable_pre == 1)
            btn_pulse <= 1; 
        else 
            btn_pulse <= 0;
    end
end
endmodule