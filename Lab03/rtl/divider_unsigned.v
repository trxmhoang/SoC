module divider_unsigned (
    input wire [31:0] dividend,
    input wire [31:0] divisor,
    output wire [31:0] quotient,
    output wire [31:0] remainder
);

wire [31:0] dividend_arr [0:32];
wire [31:0] quotient_arr [0:32];
wire [31:0] remainder_arr [0:32];

assign dividend_arr[0] = dividend;
assign quotient_arr[0] = 32'b0;
assign remainder_arr[0] = 32'b0;

genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : loop
        divu_1iter div_iter (
            .dividend_in   (dividend_arr[i]),
            .quotient_in   (quotient_arr[i]),
            .remainder_in  (remainder_arr[i]),
            .divisor       (divisor),
            .dividend_out  (dividend_arr[i+1]),
            .quotient_out  (quotient_arr[i+1]),
            .remainder_out (remainder_arr[i+1])
        );
    end
endgenerate

assign quotient = quotient_arr[32];
assign remainder = remainder_arr[32];
endmodule