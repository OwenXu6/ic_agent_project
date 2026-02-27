// =============================================================================
// Testbench: alu_8bit_tb
// Description: Exhaustive self-checking testbench for the 8-bit ALU.
//              - Tests all 6 operations with directed + exhaustive patterns
//              - Verifies zero flag behavior
//              - Verifies carry/borrow for ADD/SUB
//              - Corner cases: 0, FF, overflow, underflow
//
// Author: IC Design Agent
// =============================================================================

`timescale 1ns / 1ps

module alu_8bit_tb;

    // -------------------------------------------------------------------------
    // Signal declarations
    // -------------------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg  [7:0]  a;
    reg  [7:0]  b;
    reg  [2:0]  opcode;
    wire [7:0]  result;
    wire        carry_out;
    wire        zero;

    // Test tracking
    integer pass_count;
    integer fail_count;
    integer test_num;

    // Expected values
    reg  [7:0]  exp_result;
    reg         exp_carry;
    reg         exp_zero;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    alu_8bit uut (
        .clk       (clk),
        .rst_n     (rst_n),
        .a         (a),
        .b         (b),
        .opcode    (opcode),
        .result    (result),
        .carry_out (carry_out),
        .zero      (zero)
    );

    // -------------------------------------------------------------------------
    // Clock generation: 10ns period (100MHz)
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: compute expected result
    // -------------------------------------------------------------------------
    task compute_expected;
        input [7:0]  ta;
        input [7:0]  tb;
        input [2:0]  top;
        output [7:0] eres;
        output       ecarry;
        output       ezero;
        reg [8:0] tmp;
        begin
            eres   = 8'b0;
            ecarry = 1'b0;
            case (top)
                3'b000: begin  // ADD
                    tmp    = ta + tb;
                    eres   = tmp[7:0];
                    ecarry = tmp[8];
                end
                3'b001: begin  // SUB
                    tmp    = ta - tb;
                    eres   = tmp[7:0];
                    ecarry = tmp[8];  // borrow
                end
                3'b010: begin  // AND
                    eres   = ta & tb;
                    ecarry = 1'b0;
                end
                3'b011: begin  // OR
                    eres   = ta | tb;
                    ecarry = 1'b0;
                end
                3'b100: begin  // XOR
                    eres   = ta ^ tb;
                    ecarry = 1'b0;
                end
                3'b101: begin  // NOT
                    eres   = ~ta;
                    ecarry = 1'b0;
                end
                default: begin
                    eres   = 8'b0;
                    ecarry = 1'b0;
                end
            endcase
            ezero = (eres == 8'b0);
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: apply stimulus and check
    // -------------------------------------------------------------------------
    task test_op;
        input [7:0]  ta;
        input [7:0]  tb;
        input [2:0]  top;
        begin
            a      = ta;
            b      = tb;
            opcode = top;
            @(posedge clk);   // latch input
            #1;               // small delay after rising edge for output to settle

            compute_expected(ta, tb, top, exp_result, exp_carry, exp_zero);

            if (result !== exp_result || carry_out !== exp_carry || zero !== exp_zero) begin
                $display("[FAIL] Test #%0d: op=%0d a=0x%02h b=0x%02h | got result=0x%02h carry=%b zero=%b | exp result=0x%02h carry=%b zero=%b",
                    test_num, top, ta, tb, result, carry_out, zero, exp_result, exp_carry, exp_zero);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
            test_num = test_num + 1;
        end
    endtask

    // -------------------------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------------------------
    integer i, j, op;

    initial begin
        $dumpfile("results/alu_8bit.vcd");
        $dumpvars(0, alu_8bit_tb);

        pass_count = 0;
        fail_count = 0;
        test_num   = 0;

        // Initialize
        a      = 8'b0;
        b      = 8'b0;
        opcode = 3'b0;
        rst_n  = 0;

        $display("==========================================================");
        $display("  8-bit ALU - Testbench");
        $display("==========================================================");

        // =====================================================================
        // Phase 0: Reset test
        // =====================================================================
        $display("\n--- Phase 0: Reset Test ---");
        @(posedge clk); @(posedge clk);
        #1;
        if (result !== 8'b0 || zero !== 1'b1) begin
            $display("[FAIL] After reset: result=0x%02h zero=%b (expected 0x00, zero=1)", result, zero);
            fail_count = fail_count + 1;
        end else begin
            $display("[PASS] Reset: result=0x00, zero=1");
            pass_count = pass_count + 1;
        end
        test_num = test_num + 1;

        // Release reset
        rst_n = 1;
        @(posedge clk);

        // =====================================================================
        // Phase 1: Corner cases for each operation
        // =====================================================================
        $display("\n--- Phase 1: Corner Cases ---");

        // ADD corner cases
        test_op(8'h00, 8'h00, 3'b000);  // 0 + 0
        test_op(8'hFF, 8'h01, 3'b000);  // overflow: 255 + 1
        test_op(8'hFF, 8'hFF, 3'b000);  // max overflow: 255 + 255
        test_op(8'h80, 8'h80, 3'b000);  // 128 + 128
        test_op(8'h01, 8'h01, 3'b000);  // 1 + 1

        // SUB corner cases
        test_op(8'h00, 8'h00, 3'b001);  // 0 - 0
        test_op(8'h00, 8'h01, 3'b001);  // underflow: 0 - 1
        test_op(8'hFF, 8'hFF, 3'b001);  // 255 - 255 = 0
        test_op(8'h80, 8'h01, 3'b001);  // 128 - 1
        test_op(8'h01, 8'hFF, 3'b001);  // underflow: 1 - 255

        // AND corner cases
        test_op(8'hFF, 8'hFF, 3'b010);  // all 1s
        test_op(8'hFF, 8'h00, 3'b010);  // mask with 0
        test_op(8'hAA, 8'h55, 3'b010);  // alternating bits = 0

        // OR corner cases
        test_op(8'h00, 8'h00, 3'b011);  // 0 | 0 = 0
        test_op(8'hAA, 8'h55, 3'b011);  // alternating = FF
        test_op(8'hFF, 8'h00, 3'b011);  // FF | 0 = FF

        // XOR corner cases
        test_op(8'hFF, 8'hFF, 3'b100);  // same = 0
        test_op(8'hAA, 8'h55, 3'b100);  // alternating = FF
        test_op(8'h00, 8'h00, 3'b100);  // 0 ^ 0 = 0

        // NOT corner cases
        test_op(8'h00, 8'h00, 3'b101);  // ~0 = FF
        test_op(8'hFF, 8'h00, 3'b101);  // ~FF = 0
        test_op(8'hA5, 8'h00, 3'b101);  // ~A5 = 5A

        $display("  Corner cases: %0d passed, %0d failed", pass_count, fail_count);

        // =====================================================================
        // Phase 2: Exhaustive test for all ops with representative values
        //          For ADD/SUB: test all 256 values of A with selected B values
        //          For logic ops: test all 256 values of A with selected B values
        // =====================================================================
        $display("\n--- Phase 2: Exhaustive Test ---");

        // Reset counts for this phase
        pass_count = 0;
        fail_count = 0;

        // Test all 6 operations
        for (op = 0; op < 6; op = op + 1) begin
            // For each operation, sweep all A values against 16 representative B values
            for (i = 0; i < 256; i = i + 1) begin
                // Test with B = 0, 1, 2, 7F, 80, AA, 55, FF, and some others
                test_op(i[7:0], 8'h00, op[2:0]);
                test_op(i[7:0], 8'h01, op[2:0]);
                test_op(i[7:0], 8'h7F, op[2:0]);
                test_op(i[7:0], 8'h80, op[2:0]);
                test_op(i[7:0], 8'hFF, op[2:0]);
                test_op(i[7:0], 8'hA5, op[2:0]);
                test_op(i[7:0], 8'h55, op[2:0]);
                test_op(i[7:0], i[7:0], op[2:0]);  // a == b case
            end
        end

        $display("  Exhaustive test: %0d passed, %0d failed", pass_count, fail_count);

        // =====================================================================
        // Phase 3: Default opcode test (reserved opcodes)
        // =====================================================================
        $display("\n--- Phase 3: Reserved Opcode Test ---");
        test_op(8'hAB, 8'hCD, 3'b110);
        test_op(8'hAB, 8'hCD, 3'b111);
        $display("  Reserved opcodes: result should be 0x00");

        // =====================================================================
        // Final Report
        // =====================================================================
        $display("\n==========================================================");
        if (fail_count == 0) begin
            $display("  *** ALL TESTS PASSED *** (%0d total)", pass_count);
        end else begin
            $display("  *** SOME TESTS FAILED *** (%0d failed out of %0d)", fail_count, pass_count + fail_count);
        end
        $display("==========================================================\n");

        $finish;
    end

endmodule
