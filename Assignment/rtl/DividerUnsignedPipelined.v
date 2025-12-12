`timescale 1ns / 1ns

// quotient = dividend / divisor

module DividerUnsignedPipelined (
    input             clk, rst, stall,
    input      [31:0] i_dividend,
    input      [31:0] i_divisor,
    output reg [31:0] o_remainder,
    output reg [31:0] o_quotient
);

  // TODO: your code here
reg [31:0] r_dividend [0:6];
reg [31:0] r_divisor [0:6];
reg [31:0] r_quotient [0:6];
reg [31:0] r_remainder [0:6];

// STAGE 0 
wire [31:0] s0_dividend [0:4];
wire [31:0] s0_quotient [0:4];
wire [31:0] s0_remainder [0:4];

assign s0_dividend[0] = i_dividend;
assign s0_quotient[0] = 32'b0;
assign s0_remainder[0] = 32'b0;

genvar i, j;
generate 
    for (j = 0; j < 4; j = j + 1) begin : stage0_loop
        divu_1iter u_div0 (
            .i_dividend  (s0_dividend[j]),
            .i_divisor   (i_divisor),
            .i_remainder (s0_remainder[j]),
            .i_quotient  (s0_quotient[j]),
            .o_dividend  (s0_dividend[j + 1]),
            .o_remainder (s0_remainder[j + 1]),
            .o_quotient  (s0_quotient[j + 1])
        );
    end
endgenerate

always @(posedge clk) begin
    if (rst) begin
        r_dividend[0] <= 32'b0;
        r_divisor[0] <= 32'b0;
        r_quotient[0] <= 32'b0;
        r_remainder[0] <= 32'b0;
    end else if (!stall) begin
        r_dividend[0] <= s0_dividend[4];
        r_divisor[0] <= i_divisor;
        r_quotient[0] <= s0_quotient[4];
        r_remainder[0] <= s0_remainder[4];
    end
end

// STAGE 1 - STAGE 6
generate
    for (i = 1; i < 7; i = i + 1) begin : pipe_loop
        wire [31:0] chain_dividend [0:4];
        wire [31:0] chain_quotient [0:4];
        wire [31:0] chain_remainder [0:4];
        wire [31:0] stage_divisor;

        assign chain_dividend[0] = r_dividend[i - 1];
        assign chain_quotient[0] = r_quotient[i - 1];
        assign chain_remainder[0] = r_remainder[i - 1];
        assign stage_divisor = r_divisor[i - 1];

        for (j = 0; j < 4; j = j + 1) begin : iter_loop
            divu_1iter u_div (
                .i_dividend  (chain_dividend[j]),
                .i_divisor   (stage_divisor),
                .i_remainder (chain_remainder[j]),
                .i_quotient  (chain_quotient[j]),
                .o_dividend  (chain_dividend[j + 1]),
                .o_remainder (chain_remainder[j + 1]),
                .o_quotient  (chain_quotient[j + 1])
            );
        end

        always @(posedge clk) begin
            if (rst) begin
                r_dividend[i] <= 32'b0;
                r_divisor[i] <= 32'b0;
                r_quotient[i] <= 32'b0;
                r_remainder[i] <= 32'b0;
            end else if (!stall) begin
                r_dividend[i] <= chain_dividend[4];
                r_divisor[i] <= stage_divisor;
                r_quotient[i] <= chain_quotient[4];
                r_remainder[i] <= chain_remainder[4];
            end
        end
    end
endgenerate

// STAGE 7
wire [31:0] s7_dividend [0:4];
wire [31:0] s7_quotient [0:4];
wire [31:0] s7_remainder [0:4];

assign s7_dividend[0] = r_dividend[6];
assign s7_quotient[0] = r_quotient[6];
assign s7_remainder[0] = r_remainder[6];

generate
    for (j = 0; j < 4; j = j + 1) begin : stage7_loop
        divu_1iter u_div7 (
            .i_dividend  (s7_dividend[j]),
            .i_divisor   (r_divisor[6]),
            .i_remainder (s7_remainder[j]),
            .i_quotient  (s7_quotient[j]),
            .o_dividend  (s7_dividend[j + 1]),
            .o_remainder (s7_remainder[j + 1]),
            .o_quotient  (s7_quotient[j + 1])
        );
    end
endgenerate

always @(posedge clk) begin
    if (rst) begin
        o_quotient <= 32'b0;
        o_remainder <= 32'b0;
    end else if (!stall) begin
        o_quotient <= s7_quotient[4];
        o_remainder <= s7_remainder[4];
    end
end
endmodule

module divu_1iter (
    input      [31:0] i_dividend,
    input      [31:0] i_divisor,
    input      [31:0] i_remainder,
    input      [31:0] i_quotient,
    output reg [31:0] o_dividend,
    output reg [31:0] o_remainder,
    output reg [31:0] o_quotient
);

wire [31:0] new_remainder, subtract;
assign new_remainder = {i_remainder[30:0], i_dividend[31]};
assign subtract = new_remainder - i_divisor;

always @(*) begin
  o_dividend = i_dividend << 1;
  if (new_remainder >= i_divisor) begin
    o_remainder = subtract;
    o_quotient = {i_quotient[30:0], 1'b1};
  end else begin
    o_remainder = new_remainder;
    o_quotient = {i_quotient[30:0], 1'b0};
  end
end
endmodule