module system (
   input wire [3:0] btn,
   output wire [5:0] led
);

wire [31:0] sum;
cla cla1 (
   .a (32'd26),
   .b ({28'b0, btn}),
   .cin (1'b0),
   .sum (sum)
);

assign led = sum[5:0];
endmodule
