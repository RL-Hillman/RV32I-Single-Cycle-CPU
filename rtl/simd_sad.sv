// --------------------------------------------------------
// SIMD SAD4 - Single Instruction, Multiple Data
//             Sum of Absolute Differences
// --------------------------------------------------------
// Splits two 32-bit operands into four 8-bit unsigned values.
//
// result = |A0-B0| + |A1-B1| + |A2-B2| + |A3-B3|
//
// SIMD = Single Instruction, Multiple Data
// SAD  = Sum of Absolute Differences
// 4    = Four 8-bit values processed in parallel
//
// Main use:
// Image processing / motion detection / block matching
// --------------------------------------------------------

`default_nettype none

module simd_sad (

    input wire logic [31:0] operand_a,
    input wire logic [31:0] operand_b,

    output logic [31:0] result
);

    // ========================================================
    // Split 32-bit Operands into Four 8-bit SIMD Lanes
    // ========================================================

    logic [7:0] a0, a1, a2, a3;
    logic [7:0] b0, b1, b2, b3;

    assign a0 = operand_a[7:0];
    assign a1 = operand_a[15:8];
    assign a2 = operand_a[23:16];
    assign a3 = operand_a[31:24];

    assign b0 = operand_b[7:0];
    assign b1 = operand_b[15:8];
    assign b2 = operand_b[23:16];
    assign b3 = operand_b[31:24];


    // ========================================================
    // Absolute Difference - Four Operations in Parallel
    // ========================================================

    logic [7:0] diff0;
    logic [7:0] diff1;
    logic [7:0] diff2;
    logic [7:0] diff3;

    assign diff0 = (a0 >= b0) ? (a0 - b0) : (b0 - a0);
    assign diff1 = (a1 >= b1) ? (a1 - b1) : (b1 - a1);
    assign diff2 = (a2 >= b2) ? (a2 - b2) : (b2 - a2);
    assign diff3 = (a3 >= b3) ? (a3 - b3) : (b3 - a3);


    // ========================================================
    // Adder Tree
    // ========================================================
    // Maximum single difference = 255
    //
    // First level:
    // 255 + 255 = 510 -> requires 9 bits
    //
    // Final level:
    // 510 + 510 = 1020 -> requires 10 bits
    // ========================================================

    logic [8:0] sum01;
    logic [8:0] sum23;
    logic [9:0] sad_result;

    assign sum01 = {1'b0, diff0} + {1'b0, diff1};
    assign sum23 = {1'b0, diff2} + {1'b0, diff3};

    assign sad_result = {1'b0, sum01} + {1'b0, sum23};


    // ========================================================
    // 32-bit Processor Result
    // ========================================================

    assign result = {22'd0, sad_result};

endmodule

`default_nettype wire