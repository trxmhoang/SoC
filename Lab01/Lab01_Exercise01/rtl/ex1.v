module ex1 (
    input wire clk,
    input wire rst_n,
    input wire [3:0] button,
    output reg [2:0] hor_led,
    output reg [2:0] ver_led,
    output reg [3:0] bcd0,
    output reg [3:0] bcd1,
    output reg [3:0] bcd2,
    output reg [3:0] bcd3
);

parameter RED = 3'b100;
parameter YELLOW = 3'b110;
parameter GREEN = 3'b010;

parameter INIT = 3'd0; //initial state
parameter HR_VG = 3'd1; //horizontal red - vertical green
parameter HR_VY = 3'd2; //horizontal red - vertical yellow
parameter HG_VR = 3'd3; //horizontal green - vertical red
parameter HY_VR = 3'd4; //horizontal yellow - vertical red

parameter MODE1 = 2'd1;
parameter MODE2 = 2'd2;
parameter MODE3 = 2'd3;

`ifdef SIMULATION
    //for sim, a sec is 100 cycles
    parameter PULSE_COUNT = 27'd100;
`else
    //for fpga, a sec is 125m cycles
    parameter PULSE_COUNT = 27'd125_000_000;
`endif

//clock divider
reg [26:0] clk_cnt;
wire pulse_1s;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        clk_cnt <= 27'd0;
    else if (clk_cnt == PULSE_COUNT - 1)
        clk_cnt <= 27'd0;
    else 
        clk_cnt <= clk_cnt + 1;
end

assign pulse_1s = (clk_cnt == PULSE_COUNT - 1);

//debounce handling
wire [3:0] btn_stable;
wire [3:0] btn_pulse;
wire [3:0] btn_press;

debounce u_db0 (
    .clk        (clk),
    .rst_n      (rst_n),
    .btn_in     (button[0]),
    .btn_stable (btn_stable[0]),
    .btn_pulse  (btn_pulse[0])
);

debounce u_db1 (
    .clk        (clk),
    .rst_n      (rst_n),
    .btn_in     (button[1]),
    .btn_stable (btn_stable[1]),
    .btn_pulse  (btn_pulse[1])
);

debounce u_db2 (
    .clk        (clk),
    .rst_n      (rst_n),
    .btn_in     (button[2]),
    .btn_stable (btn_stable[2]),
    .btn_pulse  (btn_pulse[2])
);

debounce u_db3 (
    .clk        (clk),
    .rst_n      (rst_n),
    .btn_in     (button[3]),
    .btn_stable (btn_stable[3]),
    .btn_pulse  (btn_pulse[3])
);

assign btn_press = btn_pulse;

//button handling
reg[2:0] state;
reg[6:0] timer;
reg[1:0] mode;
reg[6:0] green_time = 7'd3, yellow_time = 7'd2;
reg[6:0] temp_green_time, temp_yellow_time;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mode <= MODE1;
        temp_green_time <= green_time;
        temp_yellow_time <= yellow_time;
    end else begin
        case(btn_press) 
            4'b0001: begin
                case(mode) 
                    MODE1: mode <= MODE2;
                    MODE2: begin
                        mode <= MODE3;
                        temp_green_time <= green_time;
                    end
                    MODE3: begin
                        mode <= MODE1;
                        temp_yellow_time <= yellow_time;
                    end
                    default: begin
                        mode <= MODE1;
                        state <= HR_VG;
                        timer <= green_time;
                    end
                endcase
            end

            4'b0010: begin
                case(mode)
                    MODE2: 
                        if(temp_green_time < 99) temp_green_time <= temp_green_time + 1;
                    MODE3:
                        if(temp_yellow_time < 20) temp_yellow_time <= temp_yellow_time + 1;
                endcase
            end

            4'b0100: begin
                case(mode)
                    MODE2: 
                        if(temp_green_time > 2) temp_green_time <= temp_green_time - 1;
                    MODE3:
                        if(temp_yellow_time > 1) temp_yellow_time <= temp_yellow_time - 1;
                endcase
            end

            4'b1000: begin
                case(mode)
                    MODE2: 
                        green_time <= temp_green_time;
                    MODE3:
                        yellow_time <= temp_yellow_time;
                endcase
            end
        endcase
    end
end

//led handling
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= INIT;
        timer <= 0;
    end else if (mode != MODE1) begin
        state <= INIT;
        timer <= 0;
    end else if (pulse_1s) begin
        case(state)
            INIT: begin
                state <= HR_VG;
                timer <= green_time;
            end

            HR_VG: begin
                if(timer <= 1) begin
                    state <= HR_VY;
                    timer <= yellow_time;
                end else begin
                    timer <= timer - 1;
                end
            end

            HR_VY: begin
                if(timer <= 1) begin
                    state <= HG_VR;
                    timer <= green_time;
                end else begin
                    timer <= timer - 1;
                end
            end

            HG_VR: begin
                if(timer <= 1) begin
                    state <= HY_VR;
                    timer <= yellow_time;
                end else begin
                    timer <= timer - 1;
                end
            end

            HY_VR: begin
                if(timer <= 1) begin
                    state <= HR_VG;
                    timer <= green_time;
                end else begin
                    timer <= timer - 1;
                end
            end

            default: state <= INIT;
        endcase
    end else begin
        state <= state;
        timer <= timer;
    end
end

//led display
always @(*) begin
    case (mode)
        MODE1: begin
            case (state) 
                INIT: begin
                    hor_led = RED;
                    ver_led = RED;
                end

                HR_VG: begin
                    hor_led = RED;
                    ver_led = GREEN;
                end

                HR_VY: begin
                    hor_led = RED;
                    ver_led = YELLOW;
                end

                HG_VR: begin
                    hor_led = GREEN;
                    ver_led = RED;
                end

                HY_VR: begin
                    hor_led = YELLOW;
                    ver_led = RED;
                end

                default: begin
                    hor_led = RED;
                    ver_led = RED;
                end
            endcase
        end

        MODE2: begin
            hor_led = GREEN;
            ver_led = GREEN;
        end 

        MODE3: begin
            hor_led = YELLOW;
            ver_led = YELLOW;
        end

        default: begin
            hor_led = RED;
            ver_led = RED;
        end
    endcase
end

//segment handling
reg[7:0] display_val;
reg[3:0] ten_digit;
reg[3:0] one_digit;

always @(*) begin   
    case(mode)
        MODE1: display_val = timer;
        MODE2: display_val = temp_green_time;
        MODE3: display_val = temp_yellow_time;
        default: display_val = timer;
    endcase

    ten_digit = display_val / 10;
    one_digit = display_val % 10;

    bcd0 = one_digit;
    bcd1 = ten_digit;
    bcd2 = 4'hF;
    bcd3 = mode;
end
endmodule