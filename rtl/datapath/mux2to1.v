// =============================================================================
// Module: mux2to1
// Description: Parameterized 2-to-1 multiplexer. Defaults to 32-bit width.
//              When sel=0, output=in0. When sel=1, output=in1.
// =============================================================================

module mux2to1 #(
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] in0,
    input  wire [WIDTH-1:0] in1,
    input  wire             sel,
    output wire [WIDTH-1:0] out
);

    assign out = sel ? in1 : in0;

endmodule
