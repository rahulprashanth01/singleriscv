// =============================================================================
// Module: singlecycle_top
// Description: Top-level integration of the RV32I single-cycle processor.
//              Instantiates all datapath and control leaf modules with flat
//              wiring (no stage wrappers). Supports all RV32I base integer
//              instructions except system calls (ECALL, EBREAK, FENCE, CSR).
//
// Supported Instructions (37 total):
//   R-type:  ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
//   I-type:  ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
//   Load:    LB, LH, LW, LBU, LHU
//   Store:   SB, SH, SW
//   Branch:  BEQ, BNE, BLT, BGE, BLTU, BGEU
//   U-type:  LUI, AUIPC
//   Jump:    JAL, JALR
// =============================================================================

module singlecycle_top (
    input wire clk,
    input wire reset
);

    // =========================================================================
    // INTERNAL WIRES
    // =========================================================================

    // --- PC Wires ---
    wire [31:0] current_pc;
    wire [31:0] pc_plus4;
    wire [31:0] pc_next;

    // --- Instruction ---
    wire [31:0] instruction;

    // --- Instruction Field Extraction ---
    wire [6:0]  opcode       = instruction[6:0];
    wire [4:0]  rd           = instruction[11:7];
    wire [2:0]  funct3       = instruction[14:12];
    wire [4:0]  rs1          = instruction[19:15];
    wire [4:0]  rs2          = instruction[24:20];
    wire        funct7_bit5  = instruction[30];

    // --- Immediate ---
    wire [31:0] imm_out;

    // --- Register File ---
    wire [31:0] reg_read_data1;
    wire [31:0] reg_read_data2;

    // --- Control Signals ---
    wire        ctrl_RegWrite;
    wire        ctrl_ALUSrc;
    wire        ctrl_MemWrite;
    wire        ctrl_MemRead;
    wire [1:0]  ctrl_MemToReg;
    wire        ctrl_Branch;
    wire        ctrl_Jump;
    wire        ctrl_JumpReg;
    wire [1:0]  ctrl_ALUOp;

    // --- ALU ---
    wire [31:0] alu_input_a;
    wire [31:0] alu_input_b;
    wire [3:0]  alu_ctrl_signal;
    wire [31:0] alu_result;
    wire        alu_zero;

    // --- Data Memory ---
    wire [31:0] mem_read_data;

    // --- Write-Back ---
    wire [31:0] write_back_data;

    // --- Branch/Jump ---
    wire        branch_taken;
    wire [31:0] branch_target;
    wire [31:0] jalr_target;

    // =========================================================================
    // 1. PROGRAM COUNTER
    // =========================================================================
    pc u_pc (
        .clk     (clk),
        .reset   (reset),
        .pc_next (pc_next),
        .pc      (current_pc)
    );

    // =========================================================================
    // 2. PC + 4 ADDER
    // =========================================================================
    pc_adder u_pc_adder (
        .pc_in    (current_pc),
        .pc_plus4 (pc_plus4)
    );

    // =========================================================================
    // 3. INSTRUCTION MEMORY
    // =========================================================================
    instruction_mem u_imem (
        .read_address (current_pc),
        .instruction  (instruction)
    );

    // =========================================================================
    // 4. IMMEDIATE GENERATOR
    // =========================================================================
    imm_gen u_imm_gen (
        .instruction (instruction),
        .imm_out     (imm_out)
    );

    // =========================================================================
    // 5. REGISTER FILE
    // =========================================================================
    register_file u_reg_file (
        .clk        (clk),
        .RegWrite   (ctrl_RegWrite),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .write_data (write_back_data),
        .read_data1 (reg_read_data1),
        .read_data2 (reg_read_data2)
    );

    // =========================================================================
    // 6. MAIN CONTROL UNIT
    // =========================================================================
    main_control u_main_ctrl (
        .opcode   (opcode),
        .RegWrite (ctrl_RegWrite),
        .ALUSrc   (ctrl_ALUSrc),
        .MemWrite (ctrl_MemWrite),
        .MemRead  (ctrl_MemRead),
        .MemToReg (ctrl_MemToReg),
        .Branch   (ctrl_Branch),
        .Jump     (ctrl_Jump),
        .JumpReg  (ctrl_JumpReg),
        .ALUOp    (ctrl_ALUOp)
    );

    // =========================================================================
    // 7. ALU CONTROL
    // =========================================================================
    alu_control u_alu_ctrl (
        .ALUOp       (ctrl_ALUOp),
        .funct3      (funct3),
        .funct7_bit5 (funct7_bit5),
        .opcode_bit5 (opcode[5]),
        .alu_control (alu_ctrl_signal)
    );

    // =========================================================================
    // 8. ALU SOURCE A MUX
    //    - AUIPC: ALU input A = PC (to compute PC + upper immediate)
    //    - All others: ALU input A = rs1 data
    // =========================================================================
    wire is_auipc = (opcode == 7'b0010111);

    mux2to1 u_mux_alu_a (
        .in0 (reg_read_data1),  // Normal: rs1
        .in1 (current_pc),      // AUIPC:  PC
        .sel (is_auipc),
        .out (alu_input_a)
    );

    // =========================================================================
    // 9. ALU SOURCE B MUX
    //    - ALUSrc=0: rs2 (R-type, B-type)
    //    - ALUSrc=1: immediate (I-type, S-type, U-type, JALR)
    // =========================================================================
    mux2to1 u_mux_alu_b (
        .in0 (reg_read_data2),
        .in1 (imm_out),
        .sel (ctrl_ALUSrc),
        .out (alu_input_b)
    );

    // =========================================================================
    // 10. ALU
    // =========================================================================
    alu u_alu (
        .a           (alu_input_a),
        .b           (alu_input_b),
        .alu_control (alu_ctrl_signal),
        .result      (alu_result),
        .zero        (alu_zero)
    );

    // =========================================================================
    // 11. DATA MEMORY
    // =========================================================================
    data_mem u_dmem (
        .clk        (clk),
        .MemWrite   (ctrl_MemWrite),
        .MemRead    (ctrl_MemRead),
        .funct3     (funct3),
        .address    (alu_result),
        .write_data (reg_read_data2),
        .read_data  (mem_read_data)
    );

    // =========================================================================
    // 12. WRITE-BACK MUX (3-input via two cascaded 2:1 muxes)
    //     MemToReg = 00 → ALU result
    //     MemToReg = 01 → Memory read data
    //     MemToReg = 10 → PC + 4 (for JAL/JALR link address)
    // =========================================================================
    reg [31:0] wb_mux_out;
    always @(*) begin
        case (ctrl_MemToReg)
            2'b00:   wb_mux_out = alu_result;
            2'b01:   wb_mux_out = mem_read_data;
            2'b10:   wb_mux_out = pc_plus4;
            default: wb_mux_out = alu_result;
        endcase
    end
    assign write_back_data = wb_mux_out;

    // =========================================================================
    // 13. BRANCH LOGIC
    // =========================================================================
    branch_logic u_branch (
        .Branch       (ctrl_Branch),
        .funct3       (funct3),
        .rs1_data     (reg_read_data1),
        .rs2_data     (reg_read_data2),
        .branch_taken (branch_taken)
    );

    // =========================================================================
    // 14. BRANCH / JUMP TARGET CALCULATION
    //     Branch target = PC + immediate (B-type offset)
    //     JAL target    = PC + immediate (J-type offset)
    //     JALR target   = (rs1 + immediate) & ~1
    // =========================================================================
    assign branch_target = current_pc + imm_out;
    assign jalr_target   = (reg_read_data1 + imm_out) & 32'hFFFFFFFE; // Clear LSB

    // =========================================================================
    // 15. NEXT PC MUX
    //     Priority: JALR > JAL > Branch taken > PC+4
    // =========================================================================
    reg [31:0] pc_next_mux;
    always @(*) begin
        if (ctrl_JumpReg)
            pc_next_mux = jalr_target;
        else if (ctrl_Jump)
            pc_next_mux = branch_target;    // JAL uses same PC+imm path
        else if (branch_taken)
            pc_next_mux = branch_target;
        else
            pc_next_mux = pc_plus4;
    end
    assign pc_next = pc_next_mux;

endmodule
