// =============================================================================
// Module: pc_adder
// Description: Adds 4 to the current PC to compute the address of the next
//              sequential instruction (each instruction is 4 bytes).
// =============================================================================

module pc_adder (
    input  wire [31:0] pc_in,
    output wire [31:0] pc_plus4
);

    assign pc_plus4 = pc_in + 32'd4;

endmodule
