// =============================================================================
// Module: ripple_carry_adder_4bit
// Description: 4-bit Ripple Carry Adder built from 4 cascaded full adders.
//              Carry propagates sequentially from LSB to MSB (ripple fashion).
//
// Port List:
//   - a[3:0]   : 4-bit input operand A
//   - b[3:0]   : 4-bit input operand B
//   - cin       : Carry input (for cascading or subtraction support)
//   - sum[3:0] : 4-bit sum output
//   - cout      : Carry output (overflow indicator for unsigned addition)
//
// Author: IC Design Agent
// =============================================================================

module ripple_carry_adder_4bit (
    input  wire [3:0] a,      // 4-bit Operand A
    input  wire [3:0] b,      // 4-bit Operand B
    input  wire       cin,    // Carry In
    output wire [3:0] sum,    // 4-bit Sum
    output wire       cout    // Carry Out
);

    // Internal carry chain wires
    // c[0] = cin, c[1] = carry from bit0, ..., c[4] = cout
    wire [4:0] c;

    assign c[0] = cin;
    assign cout  = c[4];

    // Generate 4 full adder instances using a generate block
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : fa_stage
            full_adder u_fa (
                .a    (a[i]),
                .b    (b[i]),
                .cin  (c[i]),
                .sum  (sum[i]),
                .cout (c[i+1])
            );
        end
    endgenerate

endmodule
