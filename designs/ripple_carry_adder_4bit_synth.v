/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : K-2015.06-SP2
// Date      : Fri Feb 27 00:37:51 2026
/////////////////////////////////////////////////////////////


module full_adder_3 ( a, b, cin, sum, cout );
  input a, b, cin;
  output sum, cout;
  wire   n1, n2, n3;

  ND2D0HVT U1 ( .A1(b), .A2(a), .ZN(n1) );
  XNR3D2HVT U2 ( .A1(cin), .A2(b), .A3(n3), .ZN(sum) );
  INVD0HVT U3 ( .I(a), .ZN(n3) );
  CKND2D0HVT U4 ( .A1(n2), .A2(n1), .ZN(cout) );
  OAI21D0HVT U5 ( .A1(b), .A2(a), .B(cin), .ZN(n2) );
endmodule


module full_adder_0 ( a, b, cin, sum, cout );
  input a, b, cin;
  output sum, cout;


  FA1D2HVT U1 ( .A(a), .B(b), .CI(cin), .CO(cout), .S(sum) );
endmodule


module full_adder_1 ( a, b, cin, sum, cout );
  input a, b, cin;
  output sum, cout;
  wire   n1, n2, n3, n4;

  OAI21D0HVT U1 ( .A1(n3), .A2(n2), .B(n1), .ZN(cout) );
  CKND2D0HVT U2 ( .A1(b), .A2(a), .ZN(n1) );
  NR2D1HVT U3 ( .A1(b), .A2(a), .ZN(n2) );
  INVD0HVT U4 ( .I(cin), .ZN(n3) );
  XNR2D2HVT U5 ( .A1(cin), .A2(n4), .ZN(sum) );
  XNR2D0HVT U6 ( .A1(b), .A2(a), .ZN(n4) );
endmodule


module full_adder_2 ( a, b, cin, sum, cout );
  input a, b, cin;
  output sum, cout;


  FA1D2HVT U1 ( .A(a), .B(b), .CI(cin), .CO(cout), .S(sum) );
endmodule


module ripple_carry_adder_4bit ( a, b, cin, sum, cout );
  input [3:0] a;
  input [3:0] b;
  output [3:0] sum;
  input cin;
  output cout;

  wire   [3:1] c;

  full_adder_3 \fa_stage[0].u_fa  ( .a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .cout(c[1]) );
  full_adder_2 \fa_stage[1].u_fa  ( .a(a[1]), .b(b[1]), .cin(c[1]), .sum(
        sum[1]), .cout(c[2]) );
  full_adder_1 \fa_stage[2].u_fa  ( .a(a[2]), .b(b[2]), .cin(c[2]), .sum(
        sum[2]), .cout(c[3]) );
  full_adder_0 \fa_stage[3].u_fa  ( .a(a[3]), .b(b[3]), .cin(c[3]), .sum(
        sum[3]), .cout(cout) );
endmodule

