// --------------------------------------------------------
// Top-Level RISC-V Processor (RV32I Single-Cycle)
// --------------------------------------------------------
`default_nettype none

import rv32i_pkg::*;

module top 
(
    input wire logic clk,
    input wire logic reset_n
);

    // ========================================================
    // Instruction Memory / Fetch Signals
    // ========================================================
    
    // Fetch -> Instruction Memory
    logic        imem_read_en;        // Enables instruction memory read
    logic [31:0] imem_address;        // Address of the instruction to fetch
    
    // Instruction Memory -> Fetch
    logic [31:0] imem_instruction;    // Instruction read from instruction memory
    
    // Fetch -> Decode
    logic [31:0] fetched_instruction; // Instruction passed from Fetch to Decode
    
    // ========================================================
    // Program Counter Signals
    // ========================================================
    logic [31:0] pc;          // Address of the current instruction
    logic [31:0] next_pc;     // Address to be loaded into PC on the next clock edge
    logic [31:0] pc_plus_4;   // Next sequential instruction address (PC + 4)


    // pc_sel = 1 -> Unconditional jump (JAL / JALR)
    // pc_sel = 0 -> No unconditional jump; branch_taken may still redirect PC
    logic        pc_sel;
    
    // branch_taken = 1 when a B-Type branch condition is true
    logic        branch_taken;



    // ========================================================
    // Decode Signals
    // ========================================================
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;

    logic        r_type;
    logic        i_type;
    logic        s_type;
    logic        b_type;
    logic        u_type;
    logic        j_type;
    logic        custom_type;
    
    logic [31:0] immediate;

    // ========================================================
    // Register File Signals
    // ========================================================
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] rf_wr_data;

    logic        rf_wr_en;
    wb_src_t     rf_wr_data_sel;

    // ========================================================
    // ALU Signals
    // ========================================================
    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic [31:0] alu_res;

    logic        op1_sel;
    logic        op2_sel;
    alu_op_t     alu_op;


    // ========================================================
    // Data Memory Signals
    // ========================================================
    logic        dmem_access_en;
    logic        dmem_wr_rd;
    mem_size_t   dmem_access_size;
    logic        load_unsigned;

    logic [31:0] dmem_address;
    logic [31:0] dmem_write_data;
    logic [31:0] dmem_read_data;

    // ========================================================
    // Program Counter Logic
    // ========================================================
    
    // PC resets and updates once per clock.
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            pc <= 32'd0 ;
        else 
            pc <= next_pc;
    end

    // Normal sequential execution: next instruction is PC + 4.
    assign pc_plus_4 = pc + 32'd4;

    // For a taken branch, JAL, or JALR, the ALU already contains
    // the target address.
    // Bit 0 is forced to zero. This is required by JALR and is
    // harmless for branch/JAL because their immediates already
    // produce an even target address.
    assign next_pc = (branch_taken || pc_sel)
                   ? {alu_res[31:1], 1'b0}
                   : pc_plus_4;

   
    // ========================================================
    // Instruction Memory
    // ========================================================
    // Stores the program instructions.
    // Fetch supplies the address and read-enable signal.
    instruction_memory u_instruction_memory (
        .read_enable (imem_read_en),
        .address     (imem_address),
        .instruction (imem_instruction)
    );


    // ========================================================
    // Fetch Unit
    // ========================================================
    // Sends the current PC to Instruction Memory and returns
    // the fetched 32-bit instruction to the Decode stage.
    fetch u_fetch (
        .reset_n            (reset_n),
        .pc                 (pc),
        .memory_instruction (imem_instruction),
        .memory_read_enable (imem_read_en),
        .memory_address     (imem_address),
        .instruction        (fetched_instruction)
    );


    // ========================================================
    // Decode Unit
    // ========================================================
    // Splits the instruction into register addresses, opcode,
    // funct fields, instruction format, and immediate value.
    decode u_decode (
        .instruction (fetched_instruction),

        .rs1_addr    (rs1_addr),
        .rs2_addr    (rs2_addr),
        .rd_addr     (rd_addr),
        .opcode      (opcode),
        .funct3      (funct3),
        .funct7      (funct7),

        .r_type      (r_type),
        .i_type      (i_type),
        .s_type      (s_type),
        .b_type      (b_type),
        .u_type      (u_type),
        .j_type      (j_type),
        .custom_type (custom_type),
        
        .immediate   (immediate)
    );


    // ========================================================
    // Control Unit
    // ========================================================
    // Converts the decoded instruction into control signals for
    // the ALU, PC, Register File, and Data Memory.
    control u_control (
        .r_type            (r_type),
        .i_type            (i_type),
        .s_type            (s_type),
        .b_type            (b_type),
        .u_type            (u_type),
        .j_type            (j_type),
        .custom_type       (custom_type),

        .funct3            (funct3),
        .funct7            (funct7),
        .opcode            (opcode),

        .pc_sel            (pc_sel),
        .op1_sel           (op1_sel),
        .op2_sel           (op2_sel),
        .alu_op            (alu_op),

        .rf_wr_data_sel    (rf_wr_data_sel),
        .rf_wr_en          (rf_wr_en),

        .dmem_access_en    (dmem_access_en),
        .dmem_wr_rd        (dmem_wr_rd),
        .dmem_access_size  (dmem_access_size),
        .load_unsigned     (load_unsigned)
    );


    // ========================================================
    // Register File Writeback MUX
    // ========================================================
    // Selects which value is written into rd:
    //   ALU result   -> arithmetic, AUIPC
    //   Memory data  -> load instructions
    //   Immediate    -> LUI
    //   PC + 4       -> JAL / JALR return address
    always_comb begin

        case (rf_wr_data_sel)
            WB_SRC_ALU: rf_wr_data = alu_res;
            WB_SRC_MEM: rf_wr_data = dmem_read_data;
            WB_SRC_IMM: rf_wr_data = immediate;
            WB_SRC_PC : rf_wr_data = pc_plus_4;
            default   : rf_wr_data = 32'd0;
        endcase
    end


    // ========================================================
    // Register File
    // ========================================================
    // Reads rs1 and rs2 combinationally.
    // Writes rd on the rising clock edge when rf_wr_en = 1.
    register_file u_register_file (
        .clk       (clk),
        .reset_n   (reset_n),

        .rs1_addr  (rs1_addr),
        .rs2_addr  (rs2_addr),

        .rd_addr   (rd_addr),
        .rf_wr_en  (rf_wr_en),
        .wr_data   (rf_wr_data),

        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );

    // ========================================================
    // Branch Control
    // ========================================================
    // Compares rs1 and rs2 for BEQ, BNE, BLT, BGE, BLTU, BGEU.
    // branch_taken is only asserted for a B-Type instruction.
    branch_control u_branch_control (
        .opr_a        (rs1_data),
        .opr_b        (rs2_data),
        .is_b_type    (b_type),
        .funct3       (funct3),
        .branch_taken (branch_taken)
    );


    // ========================================================
    // ALU Input MUXes
    // ========================================================
    // op1_sel = 0 -> rs1
    // op1_sel = 1 -> PC
    assign alu_a = op1_sel ? pc : rs1_data;

    // op2_sel = 0 -> rs2
    // op2_sel = 1 -> immediate
    assign alu_b = op2_sel ? immediate : rs2_data;


    // ========================================================
    // ALU
    // ========================================================
    // Performs arithmetic/logic operations and also calculates:
    //   load/store address = rs1 + immediate
    //   branch target      = PC  + immediate
    //   JAL target         = PC  + immediate
    //   JALR target        = rs1 + immediate
    alu u_alu (
        .alu_a   (alu_a),
        .alu_b   (alu_b),
        .alu_op  (alu_op),
        .alu_res (alu_res)
    );


    // ========================================================
    // Data Memory Connections
    // ========================================================
    // For LOAD/STORE instructions, the ALU calculates the memory
    // address 
    assign dmem_address = alu_res;

    // STORE instructions write the original rs2 value to memory.
    assign dmem_write_data = rs2_data;


    // ========================================================
    // Data Memory
    // ========================================================
    // Handles LB/LBU/LH/LHU/LW and SB/SH/SW.
    data_memory u_data_memory (
        .clk              (clk),

        .dmem_access_en   (dmem_access_en),
        .dmem_wr_rd       (dmem_wr_rd),
        .dmem_access_size (dmem_access_size),

        .dmem_address     (dmem_address),
        .dmem_write_data  (dmem_write_data),

        .load_unsigned    (load_unsigned),
        .dmem_read_data   (dmem_read_data)
    );

endmodule
`default_nettype wire