// =============================================================================
// Module: register_file
// Description: 32-entry x 32-bit register file for RV32I.
//              - Two combinational read ports (rs1, rs2)
//              - One synchronous write port (rd, written on posedge clk)
//              - Register x0 is hardwired to zero (reads always return 0,
//                writes are ignored)
// =============================================================================

module register_file (
    input  wire        clk,
    input  wire        RegWrite,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    reg [31:0] registers [0:31];

    // Initialize all registers to zero (simulation only)
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            registers[i] = 32'b0;
    end

    // Combinational reads — x0 always returns 0
    assign read_data1 = (rs1 == 5'b0) ? 32'b0 : registers[rs1];
    assign read_data2 = (rs2 == 5'b0) ? 32'b0 : registers[rs2];

    // Synchronous write — x0 is never written
    always @(posedge clk) begin
        if (RegWrite && (rd != 5'b0)) begin
            registers[rd] <= write_data;
        end
    end

endmodule
