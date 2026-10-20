
import rv32i_pkg::*;

module control (

    // Instruction type flags
    input  logic       r_type,
    input  logic       i_type,
    input  logic       s_type,
    input  logic       b_type,
    input  logic       u_type,
    input  logic       j_type,
    input logic        custom_type,
    
    // Instruction fields
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    input  logic [6:0] opcode,

    // ALU / PC control
    output logic       pc_sel,
    output logic       op1_sel,
    output logic       op2_sel,
    output alu_op_t    alu_op,

    // Register File control
    output wb_src_t    rf_wr_data_sel,
    output logic       rf_wr_en,

    // Data Memory control
    output logic       dmem_access_en,
    output logic       dmem_wr_rd,
    output mem_size_t  dmem_access_size,
    output logic       load_unsigned
    
);


    // --------------------------------------------------------
    // Internal Signals
    // --------------------------------------------------------

    logic [3:0] funct_r;
    logic       funct7_bit5;

    control_t ctrl_r;
    control_t ctrl_i;
    control_t ctrl_s;
    control_t ctrl_b;
    control_t ctrl_u;
    control_t ctrl_j;
    control_t ctrl_custom;
    control_t ctrl;

    // --------------------------------------------------------
    // R-Type Control
    // --------------------------------------------------------
    assign funct7_bit5 = funct7[5];
    assign funct_r = {funct7_bit5,funct3};
    
    always_comb begin

        ctrl_r = '0;

        ctrl_r.rf_write_enable = 1'b1;
        ctrl_r.alu_src_a_select = 1'b0; // ALU operand A = rs1
        ctrl_r.alu_src_b_select = 1'b0; // ALU operand B = rs2
        ctrl_r.rf_wr_data_sel   = WB_SRC_ALU; // Write ALU result to rd
        case (funct_r)

            R_ADD:
            ctrl_r.alu_op = ADD;

            R_SUB:
            ctrl_r.alu_op = SUB;

            R_SLL:
            ctrl_r.alu_op = SLL;

            R_SLT:
            ctrl_r.alu_op = SLT;

            R_SLTU:
            ctrl_r.alu_op = SLTU;

            R_XOR:
            ctrl_r.alu_op = XOR;

            R_SRL:
            ctrl_r.alu_op = SRL;

            R_SRA:
            ctrl_r.alu_op = SRA;

            R_OR:
            ctrl_r.alu_op = OR;

            R_AND:
            ctrl_r.alu_op = AND;

        endcase

    end


    // --------------------------------------------------------
    // I-Type Control
    // --------------------------------------------------------

    always_comb begin

        ctrl_i = '0;

        ctrl_i.rf_write_enable  = 1'b1;

        ctrl_i.alu_src_a_select = 1'b0; // ALU operand A = rs1
        ctrl_i.alu_src_b_select = 1'b1; // ALU operand B = immediate

        ctrl_i.rf_wr_data_sel   = WB_SRC_ALU; // Default: ALU result to rd
        ctrl_i.alu_op           = ADD; // Default: rs1 + immediate

        case (opcode)

            // ------------------------------------------------
            // OP-IMM
            // ------------------------------------------------

            OPCODE_OP_IMM: begin

                case ({opcode[4], funct3})

                    I_ADDI:
                    ctrl_i.alu_op = ADD;

                    I_SLTI:
                    ctrl_i.alu_op = SLT;

                    I_SLTIU:
                    ctrl_i.alu_op = SLTU;

                    I_XORI:
                    ctrl_i.alu_op = XOR;

                    I_ORI:
                    ctrl_i.alu_op = OR;

                    I_ANDI:
                    ctrl_i.alu_op = AND;

                    I_SLLI:
                    ctrl_i.alu_op = SLL;

                    I_SRLI_SRAI:
                    ctrl_i.alu_op =
                    funct7_bit5 ? SRA : SRL;

                endcase

            end


            // ------------------------------------------------
            // LOAD
            // ------------------------------------------------

            OPCODE_LOAD: begin

                ctrl_i.dmem_access_en = 1'b1;
                ctrl_i.dmem_wr_rd     = 1'b0;
                ctrl_i.rf_wr_data_sel  = WB_SRC_MEM;

                case ({opcode[4], funct3})

                    I_LB: begin
                        ctrl_i.dmem_access_size = BYTE;
                        ctrl_i.load_unsigned    = 1'b0;
                    end


                    I_LH: begin
                        ctrl_i.dmem_access_size = HALF_WORD;
                        ctrl_i.load_unsigned    = 1'b0;
                    end


                    I_LW: begin
                        ctrl_i.dmem_access_size = WORD;
                        ctrl_i.load_unsigned    = 1'b0;
                    end


                    I_LBU: begin
                        ctrl_i.dmem_access_size = BYTE;
                        ctrl_i.load_unsigned    = 1'b1;
                    end


                    I_LHU: begin
                        ctrl_i.dmem_access_size = HALF_WORD;
                        ctrl_i.load_unsigned    = 1'b1;
                    end

                endcase

            end


            // ------------------------------------------------
            // JALR
            // ------------------------------------------------

            OPCODE_JALR: begin

                ctrl_i.pc_src_select = 1'b1; // PC = jump target

                ctrl_i.rf_wr_data_sel = WB_SRC_PC; // rd = PC + 4

            end

        endcase

    end


    // --------------------------------------------------------
    // S-Type Control
    // --------------------------------------------------------

    always_comb begin

        ctrl_s = '0;

        ctrl_s.dmem_access_en   = 1'b1; // Access Data Memory
        ctrl_s.dmem_wr_rd       = 1'b1; // Memory write

        ctrl_s.alu_src_a_select = 1'b0; // ALU operand A = rs1
        ctrl_s.alu_src_b_select = 1'b1; // ALU operand B = immediate
        ctrl_s.alu_op           = ADD; // Address = rs1 + immediate


        case (funct3)

            S_SB:
            ctrl_s.dmem_access_size = BYTE;

            S_SH:
            ctrl_s.dmem_access_size = HALF_WORD;

            S_SW:
            ctrl_s.dmem_access_size = WORD;

        endcase

    end


    // --------------------------------------------------------
    // B-Type Control
    // --------------------------------------------------------

    always_comb begin

        ctrl_b = '0;

        // Branch target = PC + immediate
        ctrl_b.alu_src_a_select = 1'b1; // ALU operand A = PC
        ctrl_b.alu_src_b_select = 1'b1; // ALU operand B = immediate    

        ctrl_b.alu_op = ADD; // Branch target = PC + immediate

    end


    // --------------------------------------------------------
    // U-Type Control
    // --------------------------------------------------------

    always_comb begin

        ctrl_u = '0;

        ctrl_u.rf_write_enable = 1'b1;


        case (opcode)

            // ------------------------------------------------
            // AUIPC
            // ------------------------------------------------
            
            OPCODE_AUIPC: begin

                ctrl_u.alu_src_a_select = 1'b1; // ALU operand A = PC
                ctrl_u.alu_src_b_select = 1'b1; // ALU operand B = immediate

                ctrl_u.alu_op = ADD; // PC + immediate

                ctrl_u.rf_wr_data_sel = WB_SRC_ALU;

            end


            // ------------------------------------------------
            // LUI
            // ------------------------------------------------

            OPCODE_LUI: begin

                ctrl_u.rf_wr_data_sel = WB_SRC_IMM; // Write immediate directly to rd

            end

        endcase

    end
    // --------------------------------------------------------
    // J-Type Control
    // JAL
    // --------------------------------------------------------

    always_comb begin

        ctrl_j = '0;

        ctrl_j.rf_write_enable = 1'b1;


        ctrl_j.rf_wr_data_sel = WB_SRC_PC; // rd = PC + 4

        ctrl_j.alu_src_a_select = 1'b1; // ALU operand A = PC
        ctrl_j.alu_src_b_select = 1'b1; // ALU operand B = immediate

        ctrl_j.alu_op = ADD; // Jump target = PC + immediate

        ctrl_j.pc_src_select = 1'b1; // Select jump target as next PC

    end

      // --------------------------------------------------------
     // Custom Instruction Control
    // --------------------------------------------------------
    
    always_comb begin
    
        ctrl_custom = '0;
    
        case (funct3)
    
            // ------------------------------------------------
            // SAD
            // ------------------------------------------------
            CUSTOM_SAD: begin
            
                // Custom ALU result is written to rd
                ctrl_custom.alu_op = SAD;
                ctrl_custom.rf_write_enable = 1'b1;
                ctrl_custom.rf_wr_data_sel  = WB_SRC_ALU;

                // Custom instructions use rs1 and rs2
                ctrl_custom.alu_src_a_select = 1'b0;
                ctrl_custom.alu_src_b_select = 1'b0;
                
            end
            
        endcase
    
    end
    
    // --------------------------------------------------------
    // Final Control Selection
    // --------------------------------------------------------

    always_comb begin

        ctrl = '0;

        if (r_type)
            ctrl = ctrl_r;

        else if (i_type)
            ctrl = ctrl_i;

        else if (s_type)
            ctrl = ctrl_s;

        else if (b_type)
            ctrl = ctrl_b;

        else if (u_type)
            ctrl = ctrl_u;

        else if (j_type)
            ctrl = ctrl_j;
        
        else if (custom_type)
            ctrl = ctrl_custom;
    end


    // --------------------------------------------------------
    // Output Assignments
    // --------------------------------------------------------

    assign pc_sel  = ctrl.pc_src_select;

    assign op1_sel = ctrl.alu_src_a_select;
    assign op2_sel = ctrl.alu_src_b_select;

    assign alu_op  = ctrl.alu_op;


    // Register File

    assign rf_wr_data_sel = ctrl.rf_wr_data_sel;

    assign rf_wr_en = ctrl.rf_write_enable;


    // Data Memory

    assign dmem_access_en = ctrl.dmem_access_en;

    assign dmem_wr_rd = ctrl.dmem_wr_rd;

    assign dmem_access_size = ctrl.dmem_access_size;

    assign load_unsigned = ctrl.load_unsigned;
    
endmodule