// =============================================================================
// Module: branch_logic
// Description: Evaluates branch conditions for B-type instructions based on
//              funct3 and the two source register values. Outputs a single
//              branch_taken signal.
//
// funct3 encoding:
//   3'b000 — BEQ   (Branch if Equal)
//   3'b001 — BNE   (Branch if Not Equal)
//   3'b100 — BLT   (Branch if Less Than, signed)
//   3'b101 — BGE   (Branch if Greater or Equal, signed)
//   3'b110 — BLTU  (Branch if Less Than, unsigned)
//   3'b111 — BGEU  (Branch if Greater or Equal, unsigned)
// =============================================================================

module branch_logic (
    input  wire        Branch,      // Control signal: is this a branch instruction?
    input  wire [2:0]  funct3,      // Branch type
    input  wire [31:0] rs1_data,    // Value of rs1
    input  wire [31:0] rs2_data,    // Value of rs2
    output reg         branch_taken // 1 if branch condition is met
);

    reg condition_met;

    always @(*) begin
        condition_met = 1'b0;

        case (funct3)
            3'b000: condition_met = (rs1_data == rs2_data);                          // BEQ
            3'b001: condition_met = (rs1_data != rs2_data);                          // BNE
            3'b100: condition_met = ($signed(rs1_data) < $signed(rs2_data));          // BLT
            3'b101: condition_met = ($signed(rs1_data) >= $signed(rs2_data));         // BGE
            3'b110: condition_met = (rs1_data < rs2_data);                           // BLTU
            3'b111: condition_met = (rs1_data >= rs2_data);                          // BGEU
            default: condition_met = 1'b0;
        endcase

        branch_taken = Branch & condition_met;
    end

endmodule
