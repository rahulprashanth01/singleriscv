// =============================================================================
// Module: main_control
// Description: Decodes the 7-bit opcode from the instruction and generates
//              all control signals for the RV32I single-cycle datapath.
//
// Supported opcodes:
//   0110011 — R-type  (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU)
//   0010011 — I-type  (ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI)
//   0000011 — Load    (LB, LH, LW, LBU, LHU)
//   0100011 — Store   (SB, SH, SW)
//   1100011 — Branch  (BEQ, BNE, BLT, BGE, BLTU, BGEU)
//   0110111 — LUI
//   0010111 — AUIPC
//   1101111 — JAL
//   1100111 — JALR
// =============================================================================

module main_control (
    input  wire [6:0] opcode,

    output reg        RegWrite,   // 1 = write to rd
    output reg        ALUSrc,     // 0 = rs2, 1 = immediate
    output reg        MemWrite,   // 1 = store to data memory
    output reg        MemRead,    // 1 = load from data memory
    output reg [1:0]  MemToReg,   // 00 = ALU result, 01 = memory data, 10 = PC+4
    output reg        Branch,     // 1 = conditional branch instruction
    output reg        Jump,       // 1 = JAL
    output reg        JumpReg,    // 1 = JALR
    output reg [1:0]  ALUOp       // 00 = ADD, 01 = SUB, 10 = funct-based, 11 = pass B
);

    always @(*) begin
        // Default all signals to safe values (NOP-like behavior)
        RegWrite = 1'b0;
        ALUSrc   = 1'b0;
        MemWrite = 1'b0;
        MemRead  = 1'b0;
        MemToReg = 2'b00;
        Branch   = 1'b0;
        Jump     = 1'b0;
        JumpReg  = 1'b0;
        ALUOp    = 2'b00;

        case (opcode)
            // =================================================================
            // R-type: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
            // =================================================================
            7'b0110011: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b0;   // Use rs2
                MemToReg = 2'b00;  // ALU result → rd
                ALUOp    = 2'b10;  // Decode via funct3/funct7
            end

            // =================================================================
            // I-type ALU: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
            // =================================================================
            7'b0010011: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;   // Use immediate
                MemToReg = 2'b00;  // ALU result → rd
                ALUOp    = 2'b10;  // Decode via funct3/funct7
            end

            // =================================================================
            // I-type Load: LB, LH, LW, LBU, LHU
            // =================================================================
            7'b0000011: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;   // Use immediate (offset)
                MemRead  = 1'b1;
                MemToReg = 2'b01;  // Memory data → rd
                ALUOp    = 2'b00;  // Force ADD (base + offset)
            end

            // =================================================================
            // S-type Store: SB, SH, SW
            // =================================================================
            7'b0100011: begin
                ALUSrc   = 1'b1;   // Use immediate (offset)
                MemWrite = 1'b1;
                ALUOp    = 2'b00;  // Force ADD (base + offset)
            end

            // =================================================================
            // B-type Branch: BEQ, BNE, BLT, BGE, BLTU, BGEU
            // =================================================================
            7'b1100011: begin
                Branch   = 1'b1;
                ALUOp    = 2'b01;  // Force SUB (comparison)
            end

            // =================================================================
            // U-type: LUI — Load Upper Immediate
            // rd = imm << 12 (immediate already pre-shifted by imm_gen)
            // =================================================================
            7'b0110111: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;   // Use immediate
                MemToReg = 2'b00;  // ALU result → rd
                ALUOp    = 2'b11;  // Pass B (the immediate) through ALU
            end

            // =================================================================
            // U-type: AUIPC — Add Upper Immediate to PC
            // rd = PC + (imm << 12)
            // =================================================================
            7'b0010111: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;   // Use immediate
                MemToReg = 2'b00;  // ALU result → rd
                ALUOp    = 2'b00;  // Force ADD (PC + upper immediate)
                // NOTE: ALU input A will be PC for AUIPC (handled in top module)
            end

            // =================================================================
            // J-type: JAL — Jump And Link
            // rd = PC + 4; PC = PC + imm
            // =================================================================
            7'b1101111: begin
                RegWrite = 1'b1;
                Jump     = 1'b1;
                MemToReg = 2'b10;  // PC+4 → rd (link address)
            end

            // =================================================================
            // I-type: JALR — Jump And Link Register
            // rd = PC + 4; PC = (rs1 + imm) & ~1
            // =================================================================
            7'b1100111: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;   // Use immediate
                JumpReg  = 1'b1;
                MemToReg = 2'b10;  // PC+4 → rd (link address)
                ALUOp    = 2'b00;  // Force ADD (rs1 + imm)
            end

            default: begin
                // All outputs remain at default (NOP)
            end
        endcase
    end

endmodule
