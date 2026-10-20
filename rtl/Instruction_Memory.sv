
module instruction_memory #(
    parameter ADDRESS_WIDTH = 8 // 2^8 = 256 bytes
)(
    input  logic        read_enable,
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    // --------------------------------------------------------
    // Memory Declaration
    // --------------------------------------------------------
    logic [7:0] memory [0:(2**ADDRESS_WIDTH)-1];

    // --------------------------------------------------------
    // Initialize Memory
    // --------------------------------------------------------
    initial begin
        $readmemh("instruction_memory.mem",memory);
    end

    // --------------------------------------------------------
    // Combinational Read
    // --------------------------------------------------------
    assign instruction =
    (
    read_enable && address[1:0] == 2'b00 && address <= (2**ADDRESS_WIDTH)-4)
    ? {
        memory[address + 3],
        memory[address + 2],
        memory[address + 1],
        memory[address]
      }
    : 32'd0;

endmodule