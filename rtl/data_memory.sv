import rv32i_pkg::*;

module data_memory #(
    parameter ADDR_WIDTH = 6 // 2^6 = 64 Bytes
)(
    input  logic         clk,

    // Memory control
    input  logic         dmem_access_en, // 1 = access data memory
    input  logic         dmem_wr_rd, // 1 = Store, 0 = Load
    input  mem_size_t    dmem_access_size, // BYTE, HALF_WORD, WORD

    // Memory address and write data
    input  logic [31:0]  dmem_address,
    input  logic [31:0]  dmem_write_data,

    // Load control
    input  logic         load_unsigned, // 1 = zero extend, 0 = sign extend

    // Memory read data
    output logic [31:0]  dmem_read_data
);


    // --------------------------------------------------------
    // Data Memory
    // Byte-addressable memory
    // --------------------------------------------------------

    logic [7:0] mem [0:(2**ADDR_WIDTH)-1];


    // --------------------------------------------------------
    // Write Logic - Store Instructions
    // --------------------------------------------------------

    always_ff @(posedge clk) begin

        if (dmem_access_en && dmem_wr_rd) begin

            case (dmem_access_size)

                // Store Byte - SB
                BYTE:
                mem[dmem_address] <= dmem_write_data[7:0];


                // Store Half Word - SH
                HALF_WORD: begin
                    mem[dmem_address]     <= dmem_write_data[7:0];
                    mem[dmem_address + 1] <= dmem_write_data[15:8];
                end


                // Store Word - SW
                WORD: begin
                    mem[dmem_address]     <= dmem_write_data[7:0];
                    mem[dmem_address + 1] <= dmem_write_data[15:8];
                    mem[dmem_address + 2] <= dmem_write_data[23:16];
                    mem[dmem_address + 3] <= dmem_write_data[31:24];
                end

            endcase

        end

    end


    // --------------------------------------------------------
    // Read Logic - Load Instructions
    // --------------------------------------------------------

    always_comb begin

        // Default value
        dmem_read_data = 32'd0;

        if (dmem_access_en && !dmem_wr_rd) begin

            case (dmem_access_size)

                // ------------------------------------------------
                // Load Byte - LB / LBU
                // ------------------------------------------------

                BYTE: begin

                    if (load_unsigned)
                        // LBU - Zero Extension
                        dmem_read_data = {
                        24'd0,
                        mem[dmem_address]
                        };

                    else
                        // LB - Sign Extension
                        dmem_read_data = {
                        {24{mem[dmem_address][7]}},
                        mem[dmem_address]
                        };

                end


                // ------------------------------------------------
                // Load Half Word - LH / LHU
                // ------------------------------------------------

                HALF_WORD: begin

                    if (load_unsigned)
                        // LHU - Zero Extension
                        dmem_read_data = {
                        16'd0,
                        mem[dmem_address + 1],
                        mem[dmem_address]
                        };

                    else
                        // LH - Sign Extension
                        dmem_read_data = {
                        {16{mem[dmem_address + 1][7]}},
                        mem[dmem_address + 1],
                        mem[dmem_address]
                        };

                end


                // ------------------------------------------------
                // Load Word - LW
                // ------------------------------------------------

                WORD: begin

                    dmem_read_data = {
                    mem[dmem_address + 3],
                    mem[dmem_address + 2],
                    mem[dmem_address + 1],
                    mem[dmem_address]
                    };

                end

            endcase

        end

    end

endmodule