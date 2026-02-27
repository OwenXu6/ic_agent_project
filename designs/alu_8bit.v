// =============================================================================
// Module: alu_8bit
// Description: 8-bit Arithmetic Logic Unit with 3-bit opcode.
//              Supports ADD, SUB, AND, OR, XOR, NOT operations.
//              Outputs a zero flag (asserted when result is 0).
//
// Opcode Table:
//   3'b000 : ADD  — result = a + b
//   3'b001 : SUB  — result = a - b
//   3'b010 : AND  — result = a & b
//   3'b011 : OR   — result = a | b
//   3'b100 : XOR  — result = a ^ b
//   3'b101 : NOT  — result = ~a
//   3'b110 : (reserved — defaults to 0)
//   3'b111 : (reserved — defaults to 0)
//
// Port List:
//   - clk          : clock input
//   - rst_n        : active-low synchronous reset
//   - a[7:0]       : 8-bit operand A
//   - b[7:0]       : 8-bit operand B
//   - opcode[2:0]  : 3-bit operation select
//   - result[7:0]  : 8-bit result output (registered)
//   - carry_out    : carry/borrow output for ADD/SUB (registered)
//   - zero         : zero flag — asserted when result == 0 (registered)
//
// Author: IC Design Agent
// =============================================================================

module alu_8bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    input  wire [2:0]  opcode,
    output reg  [7:0]  result,
    output reg         carry_out,
    output reg         zero
);

    // Operation codes
    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_AND = 3'b010;
    localparam OP_OR  = 3'b011;
    localparam OP_XOR = 3'b100;
    localparam OP_NOT = 3'b101;

    // Internal combinational signals
    reg  [7:0] result_comb;
    reg         carry_comb;

    // Combinational ALU logic
    always @(*) begin
        result_comb = 8'b0;
        carry_comb  = 1'b0;

        case (opcode)
            OP_ADD: begin
                {carry_comb, result_comb} = a + b;
            end
            OP_SUB: begin
                {carry_comb, result_comb} = a - b;  // carry_comb = borrow
            end
            OP_AND: begin
                result_comb = a & b;
            end
            OP_OR: begin
                result_comb = a | b;
            end
            OP_XOR: begin
                result_comb = a ^ b;
            end
            OP_NOT: begin
                result_comb = ~a;
            end
            default: begin
                result_comb = 8'b0;
                carry_comb  = 1'b0;
            end
        endcase
    end

    // Registered outputs
    always @(posedge clk) begin
        if (!rst_n) begin
            result    <= 8'b0;
            carry_out <= 1'b0;
            zero      <= 1'b1;  // result is 0 after reset
        end else begin
            result    <= result_comb;
            carry_out <= carry_comb;
            zero      <= (result_comb == 8'b0);
        end
    end

endmodule
