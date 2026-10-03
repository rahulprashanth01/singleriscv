// =============================================================================
// Module: data_mem (Data Memory)
// Description: 1 KB (256 words) data memory supporting byte, halfword, and
//              word loads and stores, controlled by funct3.
//
// funct3 encoding (matches RISC-V Load/Store instructions):
//   3'b000 — LB / SB   (byte, sign-extended on load)
//   3'b001 — LH / SH   (halfword, sign-extended on load)
//   3'b010 — LW / SW   (word)
//   3'b100 — LBU        (byte, zero-extended on load)
//   3'b101 — LHU        (halfword, zero-extended on load)
// =============================================================================

module data_mem (
    input  wire        clk,
    input  wire        MemWrite,
    input  wire        MemRead,
    input  wire [2:0]  funct3,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);

    // Byte-addressable memory (1024 bytes)
    reg [7:0] memory [0:1023];

    // Initialize memory to zero (simulation only)
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            memory[i] = 8'b0;
    end

    // =========================================================================
    // Combinational Read (Load)
    // =========================================================================
    always @(*) begin
        if (MemRead) begin
            case (funct3)
                3'b000: // LB — Load Byte (sign-extended)
                    read_data = {{24{memory[address][7]}}, memory[address]};

                3'b001: // LH — Load Halfword (sign-extended)
                    read_data = {{16{memory[address + 1][7]}},
                                 memory[address + 1], memory[address]};

                3'b010: // LW — Load Word
                    read_data = {memory[address + 3], memory[address + 2],
                                 memory[address + 1], memory[address]};

                3'b100: // LBU — Load Byte Unsigned
                    read_data = {24'b0, memory[address]};

                3'b101: // LHU — Load Halfword Unsigned
                    read_data = {16'b0, memory[address + 1], memory[address]};

                default:
                    read_data = 32'b0;
            endcase
        end else begin
            read_data = 32'b0;
        end
    end

    // =========================================================================
    // Synchronous Write (Store)
    // =========================================================================
    always @(posedge clk) begin
        if (MemWrite) begin
            case (funct3)
                3'b000: // SB — Store Byte
                    memory[address] <= write_data[7:0];

                3'b001: begin // SH — Store Halfword
                    memory[address]     <= write_data[7:0];
                    memory[address + 1] <= write_data[15:8];
                end

                3'b010: begin // SW — Store Word
                    memory[address]     <= write_data[7:0];
                    memory[address + 1] <= write_data[15:8];
                    memory[address + 2] <= write_data[23:16];
                    memory[address + 3] <= write_data[31:24];
                end

                default: ; // No operation
            endcase
        end
    end

endmodule
