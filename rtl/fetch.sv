// --------------------------------------------------------
// Fetch - RTL
// --------------------------------------------------------

module fetch (
    input  logic         reset_n,
    input  logic [31:0]  pc, // Program Counter input
    input  logic [31:0]  memory_instruction, // Instruction from instruction memory

    output logic         memory_read_enable, // Read enable to instruction memory
    output logic [31:0]  memory_address, // Address to instruction memory
    output logic [31:0]  instruction // Fetched instruction
);


    assign memory_read_enable = reset_n;
    assign memory_address     = pc;
    assign instruction        = memory_instruction;

endmodule