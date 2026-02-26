// =============================================================================
// Testbench: ripple_carry_adder_4bit_tb
// Description: Comprehensive testbench for the 4-bit Ripple Carry Adder.
//              - Exhaustive test: all 512 input combinations (a[3:0], b[3:0], cin)
//              - Corner case verification
//              - Self-checking with automatic PASS/FAIL reporting
//
// Author: IC Design Agent
// =============================================================================

`timescale 1ns / 1ps

module ripple_carry_adder_4bit_tb;

    // -------------------------------------------------------------------------
    // Signal declarations
    // -------------------------------------------------------------------------
    reg  [3:0] a;
    reg  [3:0] b;
    reg        cin;
    wire [3:0] sum;
    wire       cout;

    // Test tracking
    integer pass_count;
    integer fail_count;
    integer test_num;

    // Expected values
    reg [4:0] expected;  // {cout, sum}

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    ripple_carry_adder_4bit uut (
        .a    (a),
        .b    (b),
        .cin  (cin),
        .sum  (sum),
        .cout (cout)
    );

    // -------------------------------------------------------------------------
    // Task: check result
    // -------------------------------------------------------------------------
    task check_result;
        input [3:0] ta;
        input [3:0] tb;
        input       tcin;
        input [3:0] tsum;
        input       tcout;
        begin
            expected = ta + tb + tcin;
            if ({tcout, tsum} !== expected) begin
                $display("[FAIL] Test #%0d: a=%b(%0d) b=%b(%0d) cin=%b | sum=%b(%0d) cout=%b | expected sum=%b(%0d) cout=%b",
                    test_num, ta, ta, tb, tb, tcin,
                    tsum, tsum, tcout,
                    expected[3:0], expected[3:0], expected[4]);
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
    integer i;

    initial begin
        // Optional: dump waveforms for debugging
        $dumpfile("results/ripple_carry_adder_4bit.vcd");
        $dumpvars(0, ripple_carry_adder_4bit_tb);

        // Initialize counters
        pass_count = 0;
        fail_count = 0;
        test_num   = 0;

        $display("==========================================================");
        $display("  4-bit Ripple Carry Adder - Testbench");
        $display("==========================================================");

        // =====================================================================
        // Phase 1: Corner Cases (explicit, for clarity)
        // =====================================================================
        $display("\n--- Phase 1: Corner Cases ---");

        // Test: 0 + 0 + 0 = 0
        a = 4'b0000; b = 4'b0000; cin = 0; #10;
        check_result(a, b, cin, sum, cout);

        // Test: 0 + 0 + 1 = 1
        a = 4'b0000; b = 4'b0000; cin = 1; #10;
        check_result(a, b, cin, sum, cout);

        // Test: Max + 0 = Max (no overflow)
        a = 4'b1111; b = 4'b0000; cin = 0; #10;
        check_result(a, b, cin, sum, cout);

        // Test: 0 + Max = Max (no overflow)
        a = 4'b0000; b = 4'b1111; cin = 0; #10;
        check_result(a, b, cin, sum, cout);

        // Test: Max + Max = 30 with cout=1 (overflow)
        a = 4'b1111; b = 4'b1111; cin = 0; #10;
        check_result(a, b, cin, sum, cout);

        // Test: Max + Max + 1 = 31 with cout=1 (max overflow)
        a = 4'b1111; b = 4'b1111; cin = 1; #10;
        check_result(a, b, cin, sum, cout);

        // Test: 1 + 1 = 2
        a = 4'b0001; b = 4'b0001; cin = 0; #10;
        check_result(a, b, cin, sum, cout);

        // Test: Carry propagation across all bits: 0111 + 0001 = 1000
        a = 4'b0111; b = 4'b0001; cin = 0; #10;
        check_result(a, b, cin, sum, cout);

        // Test: Full carry propagation: 1111 + 0001 = 10000
        a = 4'b1111; b = 4'b0001; cin = 0; #10;
        check_result(a, b, cin, sum, cout);

        // Test: Alternating bits: 1010 + 0101 = 1111
        a = 4'b1010; b = 4'b0101; cin = 0; #10;
        check_result(a, b, cin, sum, cout);

        // Test: 1000 + 1000 = 10000 (overflow at MSB only)
        a = 4'b1000; b = 4'b1000; cin = 0; #10;
        check_result(a, b, cin, sum, cout);

        $display("  Corner cases completed: %0d passed, %0d failed", pass_count, fail_count);

        // =====================================================================
        // Phase 2: Exhaustive Test - All 512 combinations
        // =====================================================================
        $display("\n--- Phase 2: Exhaustive Test (512 combinations) ---");

        // Reset counters for exhaustive phase
        pass_count = 0;
        fail_count = 0;

        for (i = 0; i < 512; i = i + 1) begin
            a   = i[3:0];       // bits [3:0]
            b   = i[7:4];       // bits [7:4]
            cin = i[8];          // bit  [8]
            #10;
            check_result(a, b, cin, sum, cout);
        end

        $display("  Exhaustive test completed: %0d passed, %0d failed", pass_count, fail_count);

        // =====================================================================
        // Final Report
        // =====================================================================
        $display("\n==========================================================");
        if (fail_count == 0) begin
            $display("  *** ALL TESTS PASSED *** (%0d / %0d)", pass_count, pass_count);
        end else begin
            $display("  *** SOME TESTS FAILED *** (%0d failed out of %0d)", fail_count, pass_count + fail_count);
        end
        $display("==========================================================\n");

        $finish;
    end

endmodule
