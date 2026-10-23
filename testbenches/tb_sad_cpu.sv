`timescale 1ns / 1ps

module tb_sad_cpu();

    // --------------------------------------------------------
    // Test Version Selection
    // --------------------------------------------------------
    // 1'b1 = Custom SAD instruction
    // 1'b0 = Standard RV32I SAD implementation
    localparam bit USE_CUSTOM_SAD = 1'b1;


    // --------------------------------------------------------
    // Program Configuration
    // --------------------------------------------------------
    localparam logic [31:0] CUSTOM_SAD_START_PC   = 32'h0000_0010;
    localparam logic [31:0] CUSTOM_SAD_END_PC     = 32'h0000_0010;

    localparam logic [31:0] STANDARD_SAD_START_PC = 32'h0000_0010;
    localparam logic [31:0] STANDARD_SAD_END_PC   = 32'h0000_0078;


    // --------------------------------------------------------
    // Expected Results
    // --------------------------------------------------------
    localparam logic [31:0] EXPECTED_X1     = 32'h64785032;
    localparam logic [31:0] EXPECTED_X2     = 32'h69765F34;
    localparam logic [31:0] EXPECTED_RESULT = 32'd24;


    // --------------------------------------------------------
    // DUT Inputs
    // --------------------------------------------------------
    logic clk;
    logic reset_n;


    // --------------------------------------------------------
    // Testbench Variables
    // --------------------------------------------------------
    integer sad_cycle_count;

    logic [31:0] sad_start_pc;
    logic [31:0] sad_end_pc;

    logic [7:0] custom_diff0;
    logic [7:0] custom_diff1;
    logic [7:0] custom_diff2;
    logic [7:0] custom_diff3;


    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------
    top dut (
        .clk     (clk),
        .reset_n (reset_n),
        .debug_sel  (3'd0),
        .debug_data ()
    );


    // --------------------------------------------------------
    // Clock Generation
    // --------------------------------------------------------
    // 10 ns clock period
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // --------------------------------------------------------
    // Select Program Addresses
    // --------------------------------------------------------
    always_comb begin

        if (USE_CUSTOM_SAD) begin
            sad_start_pc = CUSTOM_SAD_START_PC;
            sad_end_pc   = CUSTOM_SAD_END_PC;
        end

        else begin
            sad_start_pc = STANDARD_SAD_START_PC;
            sad_end_pc   = STANDARD_SAD_END_PC;
        end

    end


    // --------------------------------------------------------
    // Test Sequence
    // --------------------------------------------------------
    initial begin

        reset_n         = 1'b0;
        sad_cycle_count = 0;

        custom_diff0 = 8'd0;
        custom_diff1 = 8'd0;
        custom_diff2 = 8'd0;
        custom_diff3 = 8'd0;


        // ----------------------------------------------------
        // Test Header
        // ----------------------------------------------------
        $display("========================================");

        if (USE_CUSTOM_SAD)
            $display("       Custom SAD CPU Test");
        else
            $display("      Standard RV32I SAD Test");

        $display("========================================");


        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------
        repeat (2)
            @(posedge clk);

        @(negedge clk);
        reset_n = 1'b1;


        // ----------------------------------------------------
        // Wait for SAD calculation to begin
        // ----------------------------------------------------
        wait (dut.pc == sad_start_pc);


        // ----------------------------------------------------
        // Capture Custom SAD Internal Results
        // ----------------------------------------------------
        // The SIMD SAD unit is combinational, so its internal
        // results must be captured while the SAD instruction
        // is still active.
        if (USE_CUSTOM_SAD) begin

            #1;

            custom_diff0 = dut.u_alu.u_simd_sad.diff0;
            custom_diff1 = dut.u_alu.u_simd_sad.diff1;
            custom_diff2 = dut.u_alu.u_simd_sad.diff2;
            custom_diff3 = dut.u_alu.u_simd_sad.diff3;

        end


        // ----------------------------------------------------
        // Count Only SAD Calculation Cycles
        // ----------------------------------------------------
        begin : count_sad_cycles

            logic [31:0] executed_pc;

            forever begin

                // Capture the current instruction address
                @(negedge clk);
                executed_pc = dut.pc;

                // Execute the instruction
                @(posedge clk);

                // Allow register and PC updates to settle
                #1;

                // Count the executed instruction
                sad_cycle_count = sad_cycle_count + 1;

                // Stop after executing the last SAD instruction
                if (executed_pc == sad_end_pc)
                    break;

            end

        end


        // ----------------------------------------------------
        // Display Results
        // ----------------------------------------------------
        $display("----------------------------------------");
        $display("            Test Results");
        $display("----------------------------------------");

        if (USE_CUSTOM_SAD)
            $display("Implementation   = Custom SAD Instruction");
        else
            $display("Implementation   = Standard RV32I");


        $display("x1               = 0x%08h",
                 dut.u_register_file.regs[1]);

        $display("x2               = 0x%08h",
                 dut.u_register_file.regs[2]);

        $display("SAD Result       = %0d",
                 dut.u_register_file.regs[3]);

        $display("SAD Cycles       = %0d",
                 sad_cycle_count);


        // ----------------------------------------------------
        // Custom SAD Internal Calculation
        // ----------------------------------------------------
        if (USE_CUSTOM_SAD) begin

            $display("----------------------------------------");
            $display("       Custom SAD Calculation");
            $display("----------------------------------------");

            $display("diff0            = %0d", custom_diff0);
            $display("diff1            = %0d", custom_diff1);
            $display("diff2            = %0d", custom_diff2);
            $display("diff3            = %0d", custom_diff3);

            $display("Sum of diffs     = %0d",
                     custom_diff0 +
                     custom_diff1 +
                     custom_diff2 +
                     custom_diff3);

        end


        // ----------------------------------------------------
        // Check Result
        // ----------------------------------------------------
        $display("----------------------------------------");

        if (
            dut.u_register_file.regs[1] === EXPECTED_X1 &&
            dut.u_register_file.regs[2] === EXPECTED_X2 &&
            dut.u_register_file.regs[3] === EXPECTED_RESULT
        ) begin

            $display("PASS: SAD calculation is correct! (not sad at all! :) )");
            $display("Expected SAD     = %0d", EXPECTED_RESULT);
            $display("Actual SAD       = %0d",
                     dut.u_register_file.regs[3]);

        end

        else begin

            $display("FAIL: SAD calculation failed! (very sad! :( )");

            $display("Expected x1      = 0x%08h", EXPECTED_X1);
            $display("Actual x1        = 0x%08h",
                     dut.u_register_file.regs[1]);

            $display("Expected x2      = 0x%08h", EXPECTED_X2);
            $display("Actual x2        = 0x%08h",
                     dut.u_register_file.regs[2]);

            $display("Expected SAD     = %0d", EXPECTED_RESULT);
            $display("Actual SAD       = %0d",
                     dut.u_register_file.regs[3]);

        end


        // ----------------------------------------------------
        // Test End
        // ----------------------------------------------------
        $display("----------------------------------------");
        $display("========================================");
        $display("          Test Finished");
        $display("========================================");

        $finish;

    end
    // --------------------------------------------------------
    // Simulation Timeout
    // --------------------------------------------------------
    initial begin
        #1000;
        $fatal(1, "TIMEOUT: SAD calculation did not finish!");
    end
endmodule
