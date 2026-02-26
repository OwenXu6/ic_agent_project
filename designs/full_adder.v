// =============================================================================
// Module: full_adder
// Description: 1-bit Full Adder - the basic building block for ripple carry adder
// Author: IC Design Agent
// =============================================================================

module full_adder (
    input  wire a,      // Operand A
    input  wire b,      // Operand B
    input  wire cin,    // Carry In
    output wire sum,    // Sum output
    output wire cout    // Carry Out
);

    // Sum  = A XOR B XOR Cin
    // Cout = (A AND B) OR (Cin AND (A XOR B))
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));

endmodule
