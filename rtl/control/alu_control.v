// =============================================================================
// Module: alu_control
// Description: Decodes the 4-bit ALU control signal from ALUOp (2-bit category
//              from Main Control), funct3, and funct7 bit 30.
//
// ALUOp encoding:
//   2'b00 — Force ADD (Loads, Stores, AUIPC)
//   2'b01 — Force SUB (Branches — comparison via subtraction)
//   2'b10 — Look at funct3/funct7 (R-type and I-type ALU)
//   2'b11 — Pass B (LUI — pass immediate through ALU)
// =============================================================================

module alu_control (
    input  wire [1:0] ALUOp,
    input  wire [2:0] funct3,
    input  wire       funct7_bit5,   // instruction[30]
    input  wire       opcode_bit5,   // instruction[5] — distinguishes R-type from I-type
    output reg  [3:0] alu_control
);

    always @(*) begin
        case (ALUOp)
            2'b00: // Force ADD (Loads, Stores, AUIPC)
                alu_control = 4'b0010;

            2'b01: // Force SUB (Branches)
                alu_control = 4'b0110;

            2'b11: // Pass B input (LUI)
                alu_control = 4'b1010;

            2'b10: begin // R-type / I-type ALU — decode funct3 and funct7
                case (funct3)
                    3'b000: // ADD or SUB
                        // SUB only when both funct7[5]=1 AND opcode[5]=1 (R-type SUB)
                        alu_control = (funct7_bit5 & opcode_bit5) ? 4'b0110 : 4'b0010;

                    3'b001: // SLL
                        alu_control = 4'b0100;

                    3'b010: // SLT
                        alu_control = 4'b0111;

                    3'b011: // SLTU
                        alu_control = 4'b1000;

                    3'b100: // XOR
                        alu_control = 4'b0011;

                    3'b101: // SRL or SRA
                        // SRA when funct7[5]=1, SRL when funct7[5]=0
                        alu_control = (funct7_bit5) ? 4'b1001 : 4'b0101;

                    3'b110: // OR
                        alu_control = 4'b0001;

                    3'b111: // AND
                        alu_control = 4'b0000;

                    default:
                        alu_control = 4'b0010;
                endcase
            end

            default:
                alu_control = 4'b0010;
        endcase
    end

endmodule
