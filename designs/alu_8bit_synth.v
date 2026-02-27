/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : K-2015.06-SP2
// Date      : Fri Feb 27 13:57:10 2026
/////////////////////////////////////////////////////////////


module alu_8bit ( clk, rst_n, a, b, opcode, result, carry_out, zero );
  input [7:0] a;
  input [7:0] b;
  input [2:0] opcode;
  output [7:0] result;
  input clk, rst_n;
  output carry_out, zero;
  wire   N80, N81, N82, N83, N84, N85, N86, N87, N88, n72, n73, n74, n75, n76,
         n77, n78, n79, n80, n81, n82, n83, n84, n85, n86, n87, n88, n89, n90,
         n91, n92, n93, n94, n95, n96, n97, n98, n99, n100, n101, n102, n103,
         n104, n105, n106, n107, n108, n109, n110, n111, n112, n113, n114,
         n115, n116, n117, n118, n119, n120, n121, n122, n123, n124, n125,
         n126, n127, n128, n129, n130, n131, n132, n133, n134, n135, n136,
         n137, n138, n139, n140, n141, n142, n143, n144, n145, n146, n147,
         n148, n149, n150, n151, n152, n153, n154, n155, n156, n157, n158,
         n159, n160, n161, n162, n163, n164, n165, n166, n167, n168, n169,
         n170, n171, n172, n173, n174, n175, n176, n177, n178, n179, n180,
         n181, n182, n183, n184, n185, n186, n187, n188, n189, n190, n191,
         n192;

  DFKCNQD2HVT \result_reg[0]  ( .CN(rst_n), .D(n192), .CP(clk), .Q(result[0])
         );
  DFQD2HVT zero_reg ( .D(N88), .CP(clk), .Q(zero) );
  DFQD2HVT carry_out_reg ( .D(N87), .CP(clk), .Q(carry_out) );
  DFQD2HVT \result_reg[1]  ( .D(N80), .CP(clk), .Q(result[1]) );
  DFQD2HVT \result_reg[2]  ( .D(N81), .CP(clk), .Q(result[2]) );
  DFQD2HVT \result_reg[3]  ( .D(N82), .CP(clk), .Q(result[3]) );
  DFQD2HVT \result_reg[4]  ( .D(N83), .CP(clk), .Q(result[4]) );
  DFQD2HVT \result_reg[5]  ( .D(N84), .CP(clk), .Q(result[5]) );
  DFQD2HVT \result_reg[6]  ( .D(N85), .CP(clk), .Q(result[6]) );
  DFQD2HVT \result_reg[7]  ( .D(N86), .CP(clk), .Q(result[7]) );
  AOI32D0HVT U84 ( .A1(n134), .A2(a[7]), .A3(n152), .B1(n135), .B2(n140), .ZN(
        n137) );
  INR2XD0HVT U85 ( .A1(n131), .B1(n171), .ZN(n81) );
  OAI21D0HVT U86 ( .A1(n158), .A2(n153), .B(n154), .ZN(n143) );
  MAOI222D0HVT U87 ( .A(n76), .B(n172), .C(a[1]), .ZN(n155) );
  MAOI222D0HVT U88 ( .A(n74), .B(b[4]), .C(a[4]), .ZN(n108) );
  MAOI222D0HVT U89 ( .A(b[3]), .B(a[3]), .C(n143), .ZN(n95) );
  MAOI222D0HVT U90 ( .A(n78), .B(n145), .C(a[3]), .ZN(n88) );
  MAOI222D0HVT U91 ( .A(n75), .B(n102), .C(n108), .ZN(n122) );
  MAOI222D0HVT U92 ( .A(b[6]), .B(a[6]), .C(n122), .ZN(n133) );
  MAOI222D0HVT U93 ( .A(n80), .B(n124), .C(a[6]), .ZN(n131) );
  MAOI222D0HVT U94 ( .A(n77), .B(b[2]), .C(n155), .ZN(n145) );
  CKND2D0HVT U95 ( .A1(b[2]), .A2(a[2]), .ZN(n154) );
  MAOI222D0HVT U96 ( .A(b[1]), .B(a[1]), .C(n117), .ZN(n158) );
  IND2D0HVT U97 ( .A1(a[0]), .B1(b[0]), .ZN(n172) );
  MAOI222D0HVT U98 ( .A(n87), .B(b[4]), .C(n88), .ZN(n104) );
  AOI211XD0HVT U99 ( .A1(n168), .A2(n133), .B(n132), .C(n72), .ZN(n135) );
  NR2D0HVT U100 ( .A1(n131), .A2(n171), .ZN(n132) );
  MAOI222D0HVT U101 ( .A(b[5]), .B(n79), .C(n102), .ZN(n124) );
  INVD0HVT U102 ( .I(n104), .ZN(n79) );
  NR2D0HVT U103 ( .A1(n133), .A2(n173), .ZN(n83) );
  NR2D0HVT U104 ( .A1(n83), .A2(n81), .ZN(n134) );
  OAI211D0HVT U105 ( .A1(a[6]), .A2(n181), .B(n130), .C(n129), .ZN(n189) );
  INR2D0HVT U106 ( .A1(n191), .B1(n190), .ZN(N86) );
  AOI22D0HVT U107 ( .A1(b[7]), .A2(n82), .B1(n81), .B2(n140), .ZN(n85) );
  INVD0HVT U108 ( .I(n101), .ZN(n72) );
  INVD0HVT U109 ( .I(n169), .ZN(n73) );
  INVD0HVT U110 ( .I(b[1]), .ZN(n76) );
  INVD0HVT U111 ( .I(b[5]), .ZN(n75) );
  CKND2D0HVT U112 ( .A1(n95), .A2(n94), .ZN(n93) );
  CKND2D0HVT U113 ( .A1(a[0]), .A2(b[0]), .ZN(n174) );
  INVD0HVT U114 ( .I(opcode[1]), .ZN(n86) );
  CKND2D0HVT U115 ( .A1(opcode[0]), .A2(n114), .ZN(n171) );
  INVD0HVT U116 ( .I(n174), .ZN(n117) );
  OAI211D0HVT U117 ( .A1(a[4]), .A2(n181), .B(n97), .C(n96), .ZN(n98) );
  ND3D0HVT U118 ( .A1(n184), .A2(n183), .A3(n182), .ZN(n185) );
  CKND2D0HVT U119 ( .A1(n165), .A2(n117), .ZN(n118) );
  OAI31D0HVT U120 ( .A1(n189), .A2(n191), .A3(n185), .B(rst_n), .ZN(N88) );
  INVD0HVT U121 ( .I(a[7]), .ZN(n140) );
  NR2D0HVT U122 ( .A1(opcode[2]), .A2(opcode[1]), .ZN(n114) );
  IND2D0HVT U123 ( .A1(opcode[0]), .B1(n114), .ZN(n173) );
  INVD0HVT U124 ( .I(a[5]), .ZN(n102) );
  NR2D0HVT U125 ( .A1(b[2]), .A2(a[2]), .ZN(n153) );
  INVD0HVT U126 ( .I(n95), .ZN(n74) );
  INVD0HVT U127 ( .I(b[6]), .ZN(n80) );
  INVD0HVT U128 ( .I(a[4]), .ZN(n87) );
  INVD0HVT U129 ( .I(b[3]), .ZN(n78) );
  INVD0HVT U130 ( .I(a[2]), .ZN(n77) );
  OAI221D0HVT U131 ( .A1(a[7]), .A2(n73), .B1(n140), .B2(n173), .C(n134), .ZN(
        n82) );
  INVD0HVT U132 ( .I(n83), .ZN(n84) );
  INVD0HVT U133 ( .I(rst_n), .ZN(n190) );
  AOI221D0HVT U134 ( .A1(n140), .A2(n85), .B1(n84), .B2(n85), .C(n190), .ZN(
        N87) );
  CKND2D0HVT U135 ( .A1(n86), .A2(opcode[2]), .ZN(n91) );
  NR2D0HVT U136 ( .A1(opcode[0]), .A2(n91), .ZN(n178) );
  INVD0HVT U137 ( .I(n178), .ZN(n101) );
  NR2D0HVT U138 ( .A1(opcode[2]), .A2(n86), .ZN(n165) );
  INVD0HVT U139 ( .I(n165), .ZN(n152) );
  CKND2D0HVT U140 ( .A1(opcode[0]), .A2(n165), .ZN(n164) );
  OAI221D0HVT U141 ( .A1(a[4]), .A2(n101), .B1(n87), .B2(n152), .C(n164), .ZN(
        n100) );
  NR2D0HVT U142 ( .A1(b[4]), .A2(n87), .ZN(n92) );
  AOI21D0HVT U143 ( .A1(b[4]), .A2(n87), .B(n92), .ZN(n94) );
  INVD0HVT U144 ( .I(n88), .ZN(n90) );
  NR2D0HVT U145 ( .A1(n94), .A2(n90), .ZN(n89) );
  AOI211D0HVT U146 ( .A1(n94), .A2(n90), .B(n171), .C(n89), .ZN(n99) );
  IND2D0HVT U147 ( .A1(n91), .B1(opcode[0]), .ZN(n181) );
  INVD0HVT U148 ( .I(n164), .ZN(n138) );
  AOI22D0HVT U149 ( .A1(n138), .A2(a[4]), .B1(n92), .B2(n178), .ZN(n97) );
  INVD0HVT U150 ( .I(n173), .ZN(n168) );
  OAI211D0HVT U151 ( .A1(n95), .A2(n94), .B(n168), .C(n93), .ZN(n96) );
  AOI211D0HVT U152 ( .A1(b[4]), .A2(n100), .B(n99), .C(n98), .ZN(n183) );
  NR2D0HVT U153 ( .A1(n183), .A2(n190), .ZN(N83) );
  OAI221D0HVT U154 ( .A1(a[5]), .A2(n101), .B1(n102), .B2(n152), .C(n164), 
        .ZN(n113) );
  NR2D0HVT U155 ( .A1(b[5]), .A2(n102), .ZN(n105) );
  AOI21D0HVT U156 ( .A1(b[5]), .A2(n102), .B(n105), .ZN(n107) );
  NR2D0HVT U157 ( .A1(n107), .A2(n104), .ZN(n103) );
  AOI211D0HVT U158 ( .A1(n107), .A2(n104), .B(n171), .C(n103), .ZN(n112) );
  AOI22D0HVT U159 ( .A1(n138), .A2(a[5]), .B1(n105), .B2(n178), .ZN(n110) );
  CKND2D0HVT U160 ( .A1(n108), .A2(n107), .ZN(n106) );
  OAI211D0HVT U161 ( .A1(n108), .A2(n107), .B(n168), .C(n106), .ZN(n109) );
  OAI211D0HVT U162 ( .A1(a[5]), .A2(n181), .B(n110), .C(n109), .ZN(n111) );
  AOI211D0HVT U163 ( .A1(b[5]), .A2(n113), .B(n112), .C(n111), .ZN(n184) );
  NR2D0HVT U164 ( .A1(n184), .A2(n190), .ZN(N84) );
  NR2D0HVT U165 ( .A1(n114), .A2(n178), .ZN(n115) );
  AOI21D0HVT U166 ( .A1(b[0]), .A2(a[0]), .B(n115), .ZN(n116) );
  OAI22D0HVT U167 ( .A1(n116), .A2(n138), .B1(a[0]), .B2(b[0]), .ZN(n119) );
  OAI211D0HVT U168 ( .A1(a[0]), .A2(n181), .B(n119), .C(n118), .ZN(n192) );
  CKAN2D0HVT U169 ( .A1(a[6]), .A2(b[6]), .Z(n120) );
  NR2D0HVT U170 ( .A1(b[6]), .A2(a[6]), .ZN(n121) );
  MAOI22D0HVT U171 ( .A1(n165), .A2(n120), .B1(n121), .B2(n164), .ZN(n130) );
  NR2D0HVT U172 ( .A1(n121), .A2(n120), .ZN(n127) );
  INVD0HVT U173 ( .I(n122), .ZN(n125) );
  INVD0HVT U174 ( .I(n171), .ZN(n169) );
  AOI22D0HVT U175 ( .A1(n125), .A2(n168), .B1(n169), .B2(n124), .ZN(n123) );
  CKND2D0HVT U176 ( .A1(n127), .A2(n123), .ZN(n128) );
  OAI22D0HVT U177 ( .A1(n125), .A2(n173), .B1(n73), .B2(n124), .ZN(n126) );
  OAI22D0HVT U178 ( .A1(n178), .A2(n128), .B1(n127), .B2(n126), .ZN(n129) );
  AOI221D0HVT U179 ( .A1(n135), .A2(a[7]), .B1(n134), .B2(n140), .C(b[7]), 
        .ZN(n136) );
  AOI221D0HVT U180 ( .A1(n138), .A2(b[7]), .B1(n137), .B2(b[7]), .C(n136), 
        .ZN(n139) );
  OAI221D0HVT U181 ( .A1(a[7]), .A2(n181), .B1(n140), .B2(n164), .C(n139), 
        .ZN(n191) );
  CKAN2D0HVT U182 ( .A1(a[3]), .A2(b[3]), .Z(n141) );
  NR2D0HVT U183 ( .A1(b[3]), .A2(a[3]), .ZN(n142) );
  MAOI22D0HVT U184 ( .A1(n165), .A2(n141), .B1(n142), .B2(n164), .ZN(n151) );
  NR2D0HVT U185 ( .A1(n142), .A2(n141), .ZN(n148) );
  INVD0HVT U186 ( .I(n143), .ZN(n146) );
  AOI22D0HVT U187 ( .A1(n146), .A2(n168), .B1(n169), .B2(n145), .ZN(n144) );
  CKND2D0HVT U188 ( .A1(n148), .A2(n144), .ZN(n149) );
  OAI22D0HVT U189 ( .A1(n146), .A2(n173), .B1(n171), .B2(n145), .ZN(n147) );
  OAI22D0HVT U190 ( .A1(n178), .A2(n149), .B1(n148), .B2(n147), .ZN(n150) );
  OAI211D0HVT U191 ( .A1(a[3]), .A2(n181), .B(n151), .C(n150), .ZN(n188) );
  OA22D0HVT U192 ( .A1(n152), .A2(n154), .B1(n153), .B2(n164), .Z(n163) );
  INR2D0HVT U193 ( .A1(n154), .B1(n153), .ZN(n160) );
  INVD0HVT U194 ( .I(n155), .ZN(n157) );
  AOI22D0HVT U195 ( .A1(n158), .A2(n168), .B1(n169), .B2(n157), .ZN(n156) );
  CKND2D0HVT U196 ( .A1(n160), .A2(n156), .ZN(n161) );
  OAI22D0HVT U197 ( .A1(n158), .A2(n173), .B1(n171), .B2(n157), .ZN(n159) );
  OAI22D0HVT U198 ( .A1(n178), .A2(n161), .B1(n160), .B2(n159), .ZN(n162) );
  OAI211D0HVT U199 ( .A1(a[2]), .A2(n181), .B(n163), .C(n162), .ZN(n187) );
  CKAN2D0HVT U200 ( .A1(a[1]), .A2(b[1]), .Z(n166) );
  NR2D0HVT U201 ( .A1(b[1]), .A2(a[1]), .ZN(n167) );
  MAOI22D0HVT U202 ( .A1(n165), .A2(n166), .B1(n167), .B2(n164), .ZN(n180) );
  NR2D0HVT U203 ( .A1(n167), .A2(n166), .ZN(n176) );
  AOI22D0HVT U204 ( .A1(n169), .A2(n172), .B1(n168), .B2(n174), .ZN(n170) );
  CKND2D0HVT U205 ( .A1(n176), .A2(n170), .ZN(n177) );
  OAI22D0HVT U206 ( .A1(n174), .A2(n173), .B1(n172), .B2(n171), .ZN(n175) );
  OAI22D0HVT U207 ( .A1(n178), .A2(n177), .B1(n176), .B2(n175), .ZN(n179) );
  OAI211D0HVT U208 ( .A1(a[1]), .A2(n181), .B(n180), .C(n179), .ZN(n186) );
  NR4D0HVT U209 ( .A1(n188), .A2(n187), .A3(n186), .A4(n192), .ZN(n182) );
  INR2D0HVT U210 ( .A1(n186), .B1(n190), .ZN(N80) );
  INR2D0HVT U211 ( .A1(n187), .B1(n190), .ZN(N81) );
  INR2D0HVT U212 ( .A1(n188), .B1(n190), .ZN(N82) );
  INR2D0HVT U213 ( .A1(n189), .B1(n190), .ZN(N85) );
endmodule

