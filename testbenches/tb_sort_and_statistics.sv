`timescale 1ns/1ps

module tb_sort_and_statistics;

    logic clk;
    logic reset_n;

    // Set to 1 if you want one trace line for every executed instruction.
    localparam logic TRACE_ENABLE = 1'b0;

    // --------------------------------------------------------
    // Expected Results
    // --------------------------------------------------------
    localparam logic signed [31:0] EXPECTED_SORTED [0:7] = '{
        -32'sd42,
        -32'sd7,
         32'sd0,
         32'sd2,
         32'sd11,
         32'sd18,
         32'sd51,
         32'sd99
    };

    localparam logic signed [31:0] EXPECTED_MIN            = -32'sd42;
    localparam logic signed [31:0] EXPECTED_MAX            =  32'sd99;
    localparam logic signed [31:0] EXPECTED_SUM            =  32'sd132;
    localparam logic signed [31:0] EXPECTED_POSITIVE_COUNT =  32'sd5;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------
    top dut (
        .clk     (clk),
        .reset_n (reset_n),
        .debug_sel (3'd0),
        .debug_data ()
    );


    // --------------------------------------------------------
    // Clock: 100 MHz
    // --------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // --------------------------------------------------------
    // Helper: read a 32-bit little-endian word from Data Memory
    // --------------------------------------------------------
    function automatic logic [31:0] read_word(input integer address);
        read_word = {
            dut.u_data_memory.mem[address + 3],
            dut.u_data_memory.mem[address + 2],
            dut.u_data_memory.mem[address + 1],
            dut.u_data_memory.mem[address]
        };
    endfunction


    // --------------------------------------------------------
    // Main Test
    // --------------------------------------------------------
    initial begin

        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------
        reset_n = 1'b0;
        repeat (2) @(negedge clk);
        reset_n = 1'b1;


        // ----------------------------------------------------
        // Wait until the original array has been stored
        //
        // The last initialization STORE is instruction #17
        // at PC = 0x40.
        // Therefore, when PC reaches 0x44, all 8 values
        // are already stored in Data Memory.
        // ----------------------------------------------------
        wait (dut.pc == 32'h0000_0044);

        // Allow the last nonblocking STORE to settle.
        #1;


        // ----------------------------------------------------
        // Display original array
        // ----------------------------------------------------
        $display("");
        $display("================================================");
        $display("RV32I SORT AND STATISTICS");
        $display("================================================");
        $display("Original array:");
        $display("A[0] = %0d", $signed(read_word(0)));
        $display("A[1] = %0d", $signed(read_word(4)));
        $display("A[2] = %0d", $signed(read_word(8)));
        $display("A[3] = %0d", $signed(read_word(12)));
        $display("A[4] = %0d", $signed(read_word(16)));
        $display("A[5] = %0d", $signed(read_word(20)));
        $display("A[6] = %0d", $signed(read_word(24)));
        $display("A[7] = %0d", $signed(read_word(28)));
        $display("================================================");

        // ----------------------------------------------------
        // Wait until the complete program finishes
        //
        // HALT is instruction #57 at PC = 0xE0.
        // ----------------------------------------------------
        wait (dut.pc == 32'h0000_00E0);

        // Allow all nonblocking writes from the previous
        // clock edge to settle before checking results.
        #1;


        // ----------------------------------------------------
        // Display sorted array
        // Expected:
        // [-42, -7, 0, 2, 11, 18, 51, 99]
        // ----------------------------------------------------
        $display("");
        $display("================================================");
        $display("Sorted array:");
        $display("A[0] = %0d", $signed(read_word(0)));
        $display("A[1] = %0d", $signed(read_word(4)));
        $display("A[2] = %0d", $signed(read_word(8)));
        $display("A[3] = %0d", $signed(read_word(12)));
        $display("A[4] = %0d", $signed(read_word(16)));
        $display("A[5] = %0d", $signed(read_word(20)));
        $display("A[6] = %0d", $signed(read_word(24)));
        $display("A[7] = %0d", $signed(read_word(28)));


        // ----------------------------------------------------
        // Display calculated results
        // ----------------------------------------------------
        $display("");
        $display("Results:");
        $display("MIN            = %0d", $signed(read_word(32)));
        $display("MAX            = %0d", $signed(read_word(36)));
        $display("SUM            = %0d", $signed(read_word(40)));
        $display("POSITIVE COUNT = %0d", $signed(read_word(44)));
        $display("------------------------------------------------");


        // ----------------------------------------------------
        // Check sorted array
        // ----------------------------------------------------
        for (int i = 0; i < 8; i++) begin

            if ($signed(read_word(i * 4)) !== EXPECTED_SORTED[i])
                $fatal(1, "FAIL: A[%0d] expected %0d",
                       i, EXPECTED_SORTED[i]);

        end

        // ----------------------------------------------------
        // Check calculated results
        // ----------------------------------------------------
        if ($signed(read_word(32)) !== EXPECTED_MIN)
            $fatal(1, "FAIL: MIN expected %0d", EXPECTED_MIN);

        if ($signed(read_word(36)) !== EXPECTED_MAX)
            $fatal(1, "FAIL: MAX expected %0d", EXPECTED_MAX);

        if ($signed(read_word(40)) !== EXPECTED_SUM)
            $fatal(1, "FAIL: SUM expected %0d", EXPECTED_SUM);

        if ($signed(read_word(44)) !== EXPECTED_POSITIVE_COUNT)
            $fatal(1, "FAIL: POSITIVE COUNT expected %0d",
                   EXPECTED_POSITIVE_COUNT);


        // ----------------------------------------------------
        // Check result registers
        // ----------------------------------------------------
        if ($signed(dut.u_register_file.regs[22]) !== EXPECTED_MIN)
            $fatal(1, "FAIL: x22 (MIN)");

        if ($signed(dut.u_register_file.regs[23]) !== EXPECTED_MAX)
            $fatal(1, "FAIL: x23 (MAX)");

        if ($signed(dut.u_register_file.regs[24]) !== EXPECTED_SUM)
            $fatal(1, "FAIL: x24 (SUM)");

        if ($signed(dut.u_register_file.regs[25]) !== EXPECTED_POSITIVE_COUNT)
            $fatal(1, "FAIL: x25 (POSITIVE COUNT)");


        // ----------------------------------------------------
        // PASS
        // ----------------------------------------------------
        $display("PASS: SORT AND STATISTICS COMPLETED SUCCESSFULLY");
        $display("================================================");
        $display("");

        $finish;
    end


    // --------------------------------------------------------
    // Optional instruction trace
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (reset_n && TRACE_ENABLE) begin
            $display(
                "t=%0t PC=%08h instr=%08h i=%0d j=%0d sum=%0d count=%0d",
                $time,
                dut.pc,
                dut.fetched_instruction,
                dut.u_register_file.regs[12],
                dut.u_register_file.regs[14],
                $signed(dut.u_register_file.regs[24]),
                dut.u_register_file.regs[25]
            );
        end
    end


    // --------------------------------------------------------
    // Safety timeout
    //
    // Program normally completes in roughly 4.2 us.
    // If PC never reaches HALT, stop simulation at 10 us.
    // --------------------------------------------------------
    initial begin
        #10000;
        $fatal(1, "TIMEOUT: CPU did not reach program HALT.");
    end

endmodule
