`timescale 1ns / 1ps

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits internally would generate a carry-out (independent of cin)
 * @param pout whether these 4 bits internally would propagate an incoming carry from cin
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);

   // TODO: your code here
   wire [3:0] c;
   assign c[0] = cin;
   assign c[1] = gin[0] | (pin[0] & c[0]);
   assign c[2] = gin[1] | (pin[1] & gin[0]) | (pin[1] & pin[0] & c[0]);
   assign c[3] = gin[2] | (pin[2] & gin[1]) | (pin[2] & pin[1] & gin[0]) | (pin[2] & pin[1] & pin[0] & c[0]);

   assign gout = gin[3] | (pin[3] & gin[2]) | (pin[3] & pin[2] & gin[1]) | (pin[3] & pin[2] & pin[1] & gin[0]);
   assign pout = &pin;
   assign cout = c[3:1];

endmodule

/** Same as gp4 but for an 8-bit window instead */
module gp8(input wire [7:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [6:0] cout);

   // TODO: your code here
   wire gout_lo, pout_lo;
   wire gout_hi, pout_hi;
   wire c4;
   wire [2:0] cout_lo, cout_hi;

   gp4 gpa_lo (
      .gin(gin[3:0]),
      .pin(pin[3:0]),
      .cin(cin),
      .gout(gout_lo),
      .pout(pout_lo),
      .cout(cout_lo)
   );

   assign c4 = gout_lo | (pout_lo & cin);

   gp4 gpa_hi (
      .gin(gin[7:4]),
      .pin(pin[7:4]),
      .cin(c4),
      .gout(gout_hi),
      .pout(pout_hi),
      .cout(cout_hi)
   );

   assign gout = gout_hi | (pout_hi & gout_lo);
   assign pout = pout_hi & pout_lo;
   assign cout = {cout_hi, c4, cout_lo};

endmodule

module cla
  (input wire [31:0]  a, b,
   input wire         cin,
   output wire [31:0] sum);

   // TODO: your code here
   wire [31:0] g, p;
   genvar i;
   generate
      for(i = 0; i < 32; i = i + 1) begin : gp1_loop
         gp1 u_gp1 (
            .a(a[i]),
            .b(b[i]),
            .g(g[i]),
            .p(p[i])
         );
      end
   endgenerate

   wire [7:0] gout, pout;
   wire [7:0] c_in;
   wire [23:0] c_out;
   wire unused_gout, unused_pout;
   
   assign c_in[0] = cin;
   gp8 u_gp8 (
      .gin(gout),
      .pin(pout),
      .cin(cin),
      .gout(unused_gout),
      .pout(unused_pout),
      .cout(c_in[7:1])
   );

   generate
      for(i = 0; i < 8; i = i + 1) begin : gp4_loop
         gp4 u_gp4 (
            .gin(g[4*i + 3 : 4*i]),
            .pin(p[4*i + 3 : 4*i]),
            .cin(c_in[i]),
            .gout(gout[i]),
            .pout(pout[i]),
            .cout(c_out[3*i + 2 : 3*i])
         );
      end
   endgenerate

   wire [31:0] full_cout;
   generate
      for(i = 0; i < 8; i = i + 1) begin : cout_loop
         assign full_cout[4*i] = c_in[i];
         assign full_cout[4*i + 3 : 4*i + 1] = c_out[3*i + 2 : 3*i];
      end
   endgenerate

   assign sum = a ^ b ^ full_cout;
endmodule
