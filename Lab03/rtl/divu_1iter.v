module divu_1iter (
    input wire [31:0] dividend_in,
    input wire [31:0] quotient_in,
    input wire [31:0] remainder_in,
    input wire [31:0] divisor,

    output wire [31:0] dividend_out,
    output wire [31:0] quotient_out,
    output wire [31:0] remainder_out
);

wire [31:0] new_remainder, subtract;
wire can_subtract;
assign new_remainder = {remainder_in[30:0], dividend_in[31]};
assign subtract = new_remainder - divisor;
assign can_subtract = new_remainder >= divisor;

assign remainder_out = can_subtract ? subtract : new_remainder;
assign quotient_out = {quotient_in[30:0], can_subtract};
assign dividend_out = dividend_in << 1;
endmodule