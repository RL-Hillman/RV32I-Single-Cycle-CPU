
import rv32i_pkg::*;

module decode(
    input  logic [31:0] instruction,

    // Decoded instruction fields
    output logic [4:0]  rs1_addr,
    output logic [4:0]  rs2_addr,
    output logic [4:0]  rd_addr,
    output logic [6:0] opcode,
    output logic [2:0]  funct3,
    output logic [6:0]  funct7,

    // Instruction format
    output logic        r_type,
    output logic        i_type,
    output logic        s_type,
    output logic        b_type,
    output logic        u_type,
    output logic        j_type,
    output logic        custom_type,
    // Immediate
    output logic [31:0] immediate
);
    // --------------------------------------------------------
    // Internal Immediate Signals
    // --------------------------------------------------------

    logic [31:0] imm_i_type;
    logic [31:0] imm_s_type;
    logic [31:0] imm_b_type;
    logic [31:0] imm_u_type;
    logic [31:0] imm_j_type;


    // --------------------------------------------------------
    // Instruction Field Extraction
    // --------------------------------------------------------

    assign opcode   = instruction[6:0];
    assign rd_addr  = instruction[11:7];
    assign funct3   = instruction[14:12];
    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign funct7   = instruction[31:25];


    // --------------------------------------------------------
    // Immediate Generation
    // --------------------------------------------------------

    // I-Type
    assign imm_i_type = {
    {20{instruction[31]}},
    instruction[31:20]
    };

    // S-Type
    assign imm_s_type = {
    {20{instruction[31]}},
    instruction[31:25],
    instruction[11:7]
    };

    // B-Type
    assign imm_b_type = {
    {19{instruction[31]}},
    instruction[31],
    instruction[7],
    instruction[30:25],
    instruction[11:8],
    1'b0
    };

    // U-Type
    assign imm_u_type = {
    instruction[31:12],
    12'b0
    };

    // J-Type
    assign imm_j_type = {
    {11{instruction[31]}},
    instruction[31],
    instruction[19:12],
    instruction[20],
    instruction[30:21],
    1'b0
    };


    // --------------------------------------------------------
    // Instruction Format Detection
    // --------------------------------------------------------

    always_comb begin

        // Default values
        r_type = 1'b0;
        i_type = 1'b0;
        s_type = 1'b0;
        b_type = 1'b0;
        u_type = 1'b0;
        j_type = 1'b0;
        custom_type = 1'b0;
        
        case (opcode)

            OPCODE_OP:
            r_type = 1'b1;

            OPCODE_LOAD,
            OPCODE_OP_IMM,
            OPCODE_JALR:
            i_type = 1'b1;

            OPCODE_STORE:
            s_type = 1'b1;

            OPCODE_BRANCH:
            b_type = 1'b1;

            OPCODE_LUI,
            OPCODE_AUIPC:
            u_type = 1'b1;

            OPCODE_JAL:
            j_type = 1'b1;

            OPCODE_CUSTOM_0:
            custom_type = 1'b1;
            
        endcase

    end


    // --------------------------------------------------------
    // Immediate Selection
    // --------------------------------------------------------

    always_comb begin

        if (i_type)
            immediate = imm_i_type;

        else if (s_type)
            immediate = imm_s_type;

        else if (b_type)
            immediate = imm_b_type;

        else if (u_type)
            immediate = imm_u_type;

        else if (j_type)
            immediate = imm_j_type;
        else
            immediate = 32'd0;

    end




endmodule
