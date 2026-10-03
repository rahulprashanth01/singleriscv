// =============================================================================
// Module: instruction_mem (Instruction Memory)
// Description: 256-word (1 KB) read-only instruction memory.
//              Word-addressed using bits [31:2] to convert byte address
//              to word index (each instruction is 4 bytes).
//              Contents are loaded externally by the testbench.
// =============================================================================

module instruction_mem (
    input  wire [31:0] read_address,
    output wire [31:0] instruction
);

    reg [31:0] mem [0:255];

    assign instruction = mem[read_address[31:2]];

endmodule
