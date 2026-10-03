// =============================================================================
// Module: alu (Arithmetic Logic Unit)
// Description: Performs all RV32I arithmetic and logical operations based on
//              the 4-bit alu_control signal from the ALU Control unit.
//
// ALU Control Encoding:
//   4'b0000 — AND        4'b0101 — SRL (Shift Right Logical)
//   4'b0001 — OR         4'b0110 — SUB
//   4'b0010 — ADD        4'b0111 — SLT (Set Less Than, signed)
//   4'b0011 — XOR        4'b1000 — SLTU (Set Less Than, unsigned)
//   4'b0100 — SLL        4'b1001 — SRA (Shift Right Arithmetic)
// =============================================================================

module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_control,

    output wire [31:0] result,
    output wire        zero
);

    reg [31:0] alu_result;

    assign result = alu_result;
    assign zero   = (result == 32'b0);

    always @(*) begin
        case (alu_control)
            4'b0000: alu_result = a & b;                                    // AND
            4'b0001: alu_result = a | b;                                    // OR
            4'b0010: alu_result = a + b;                                    // ADD
            4'b0011: alu_result = a ^ b;                                    // XOR
            4'b0100: alu_result = a << b[4:0];                              // SLL
            4'b0101: alu_result = a >> b[4:0];                              // SRL
            4'b0110: alu_result = a - b;                                    // SUB
            4'b0111: alu_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
            4'b1000: alu_result = (a < b) ? 32'd1 : 32'd0;                 // SLTU
            4'b1001: alu_result = $signed(a) >>> b[4:0];                    // SRA
            4'b1010: alu_result = b;                                         // PASS B (for LUI)
            default: alu_result = 32'b0;
        endcase
    end

endmodule
