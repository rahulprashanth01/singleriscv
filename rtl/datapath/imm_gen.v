// =============================================================================
// Module: imm_gen (Immediate Generator)
// Description: Extracts and sign-extends the immediate value from a 32-bit
//              RISC-V instruction based on its opcode. Handles all RV32I
//              instruction formats:
//
//   I-type:  inst[31:20]                               → sign-extended 12-bit
//   S-type:  {inst[31:25], inst[11:7]}                  → sign-extended 12-bit
//   B-type:  {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0} → sign-ext 13-bit
//   U-type:  {inst[31:12], 12'b0}                       → upper 20 bits
//   J-type:  {inst[31], inst[19:12], inst[20], inst[30:21], 1'b0} → sign-ext 21-bit
// =============================================================================

module imm_gen (
    input  wire [31:0] instruction,
    output reg  [31:0] imm_out
);

    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            // -----------------------------------------------------------------
            // I-type: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
            //         LB, LH, LW, LBU, LHU
            //         JALR
            // -----------------------------------------------------------------
            7'b0010011, // I-type ALU
            7'b0000011, // I-type Load
            7'b1100111: // JALR
                imm_out = {{20{instruction[31]}}, instruction[31:20]};

            // -----------------------------------------------------------------
            // S-type: SB, SH, SW
            // -----------------------------------------------------------------
            7'b0100011:
                imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            // -----------------------------------------------------------------
            // B-type: BEQ, BNE, BLT, BGE, BLTU, BGEU
            // -----------------------------------------------------------------
            7'b1100011:
                imm_out = {{19{instruction[31]}}, instruction[31], instruction[7],
                           instruction[30:25], instruction[11:8], 1'b0};

            // -----------------------------------------------------------------
            // U-type: LUI, AUIPC
            // -----------------------------------------------------------------
            7'b0110111, // LUI
            7'b0010111: // AUIPC
                imm_out = {instruction[31:12], 12'b0};

            // -----------------------------------------------------------------
            // J-type: JAL
            // -----------------------------------------------------------------
            7'b1101111:
                imm_out = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                           instruction[20], instruction[30:21], 1'b0};

            default:
                imm_out = 32'b0;
        endcase
    end

endmodule
