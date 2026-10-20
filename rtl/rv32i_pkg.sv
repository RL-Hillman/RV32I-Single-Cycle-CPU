

package rv32i_pkg;


  // --------------------------------------------------------
  // RISC-V Opcodes (Instruction Formats)
  // --------------------------------------------------------
    typedef enum logic [6:0] {

        OPCODE_OP      = 7'h33,

        OPCODE_LOAD    = 7'h03,

        OPCODE_OP_IMM  = 7'h13,

        OPCODE_JALR    = 7'h67,

        OPCODE_STORE   = 7'h23,

        OPCODE_BRANCH  = 7'h63,

        OPCODE_LUI     = 7'h37,

        OPCODE_AUIPC   = 7'h17,

        OPCODE_JAL     = 7'h6F,
        
        OPCODE_CUSTOM_0 = 7'h0B

    } opcode_t;


    // --------------------------------------------------------
    // Custom Instructions (Funct3)
    // --------------------------------------------------------
    typedef enum logic [2:0] {
        CUSTOM_SAD = 3'b000
    } custom_instr_t; 


  // --------------------------------------------------------
  // ALU Operation 
  // --------------------------------------------------------
  typedef enum logic [3:0] {
    ADD,
    SUB,
    SLL,
	SLT,
	SLTU,
	XOR,
    SRL,
    SRA,
    OR,
    AND,
    SAD
  } alu_op_t;

  // --------------------------------------------------------
  // Memory Access Sizes
  // --------------------------------------------------------
  typedef enum logic [1:0] {
    BYTE      = 2'b00,
    HALF_WORD = 2'b01,
    WORD      = 2'b10
  } mem_size_t;


   // --------------------------------------------------------
  // B-Type Instructions (Funct3)
  // --------------------------------------------------------
  typedef enum logic [2:0] {
    B_BEQ  = 3'h0,
    B_BNE  = 3'h1,
    B_BLT  = 3'h4,
    B_BGE  = 3'h5,
    B_BLTU = 3'h6,
    B_BGEU = 3'h7
  } b_type_instr_t;


  // --------------------------------------------------------
  // R-Type Instructions (Funct7[5], Funct3)
  // --------------------------------------------------------
  typedef enum logic [3:0] {
    R_ADD  = 4'h0,
    R_SUB  = 4'h8,
    R_SLL  = 4'h1,
	R_SLT  = 4'h2,
	R_SLTU = 4'h3,
	R_XOR  = 4'h4,
	R_SRL  = 4'h5,
    R_SRA  = 4'hD,
	R_OR   = 4'h6,
    R_AND  = 4'h7
  } r_type_instr_t;

  // --------------------------------------------------------
  // I-Type Instructions (Opcode[4], Funct3)
  // --------------------------------------------------------
  typedef enum logic [3:0] {
    I_LB    = 4'h0,
    I_LH    = 4'h1,
    I_LW    = 4'h2,
    I_LBU   = 4'h4,
    I_LHU   = 4'h5,
    I_ADDI  = 4'h8,
    I_SLTI  = 4'hA,
	I_SLTIU = 4'hB,
	I_XORI  = 4'hC,
    I_ORI   = 4'hE,
	I_ANDI  = 4'hF,
    I_SLLI  = 4'h9,
    I_SRLI_SRAI = 4'hD  // shared funct3
  } i_type_instr_t;

  // --------------------------------------------------------
  // S-Type Instructions (Funct3)
  // --------------------------------------------------------
  typedef enum logic [2:0] {
    S_SB = 3'h0,
    S_SH = 3'h1,
    S_SW = 3'h2
  } s_type_instr_t;

  // --------------------------------------------------------
  // Register File Writeback Sources
  // --------------------------------------------------------
  typedef enum logic [1:0] {
      WB_SRC_ALU = 2'b00,
      WB_SRC_MEM = 2'b01,
      WB_SRC_IMM = 2'b10,
      WB_SRC_PC  = 2'b11
  } wb_src_t;

  // --------------------------------------------------------
  // Control Signal Struct
  // --------------------------------------------------------
  typedef struct packed {
  
    // Data Memory Control  
    logic        dmem_access_en;         // Enables Data Memory access
    logic        dmem_wr_rd;        // 1 = write, 0 = read
    mem_size_t   dmem_access_size;     // BYTE, HALF_WORD, WORD
    logic        load_unsigned; // 1 = zero-extend loads (LBU/LHU)
    
    // Register File Control
    logic        rf_write_enable;   // Enables write to rd
    wb_src_t     rf_wr_data_sel; // Selects the data source written to rd

    // PC Control
    logic        pc_src_select;    // 1 = jump, 0 = sequential
    
    // ALU Control
    logic        alu_src_a_select; // 1 = PC, 0 = rs1
    logic        alu_src_b_select; // 1 = IMM, 0 = rs2
    alu_op_t     alu_op;           // ALU function selector
    
  } control_t;

endpackage