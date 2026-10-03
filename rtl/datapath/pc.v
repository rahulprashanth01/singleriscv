// =============================================================================
// Module: pc (Program Counter)
// Description: 32-bit program counter with synchronous reset.
//              On reset, PC is set to 0. Otherwise, PC loads pc_next on each
//              rising clock edge.
// =============================================================================

module pc (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] pc_next,
    output reg  [31:0] pc
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'b0;
        else
            pc <= pc_next;
    end

endmodule
