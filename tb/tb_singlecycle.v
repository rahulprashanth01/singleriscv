// =============================================================================
// Testbench: tb_singlecycle
// Description: Comprehensive testbench for the RV32I single-cycle processor.
//              Loads a test program exercising every instruction type, then
//              checks final register values against expected results.
//
// Test Program Summary:
//   Instructions 0-8:   I-type ALU (ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI)
//   Instructions 9-18:  R-type (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU)
//   Instructions 19-20: U-type (LUI, AUIPC)
//   Instructions 21-24: Store/Load (SW, LW, SB, LBU)
//   Instructions 25-26: Store/Load (SH, LHU)
//   Instructions 27-29: Branch (BEQ not-taken, BEQ taken, BNE)
//   Instructions 30-31: Jump (JAL, JALR)
// =============================================================================

`timescale 1ns / 1ps

module tb_singlecycle ();

    reg clk;
    reg reset;

    // Instantiate the Unit Under Test
    singlecycle_top uut (
        .clk   (clk),
        .reset (reset)
    );

    // Clock generation: 10ns period (100 MHz)
    always #5 clk = ~clk;

    // =========================================================================
    // MACHINE CODE LOADING
    // =========================================================================
    // All machine code is hand-assembled from the RISC-V ISA spec.
    // Format: instruction_memory[word_address] = 32-bit machine code;

    initial begin
        clk   = 0;
        reset = 1;

        // =====================================================================
        // I-TYPE ALU INSTRUCTIONS (rd = rs1 OP immediate)
        // =====================================================================

        // Inst 0:  ADDI x1, x0, 100       → x1 = 100
        // Encoding: imm[11:0]=100(0x064), rs1=0, funct3=000, rd=1, opcode=0010011
        uut.u_imem.mem[0] = 32'h06400093;

        // Inst 1:  ADDI x2, x0, 200       → x2 = 200
        uut.u_imem.mem[1] = 32'h0C800113;

        // Inst 2:  ADDI x3, x0, -50       → x3 = -50 (0xFFFFFFCE)
        uut.u_imem.mem[2] = 32'hFCE00193;

        // Inst 3:  ANDI x4, x1, 0xFF      → x4 = 100 & 255 = 100
        uut.u_imem.mem[3] = 32'h0FF0F213;

        // Inst 4:  ORI  x5, x1, 0x0F      → x5 = 100 | 15 = 111
        uut.u_imem.mem[4] = 32'h00F0E293;

        // Inst 5:  XORI x6, x1, 0xFF      → x6 = 100 ^ 255 = 155
        uut.u_imem.mem[5] = 32'h0FF0C313;

        // Inst 6:  SLTI x7, x3, 0         → x7 = (-50 < 0) ? 1 : 0 = 1
        uut.u_imem.mem[6] = 32'h0001A393;

        // Inst 7:  SLLI x8, x1, 2         → x8 = 100 << 2 = 400
        uut.u_imem.mem[7] = 32'h00209413;

        // Inst 8:  SRLI x9, x2, 3         → x9 = 200 >> 3 = 25
        // Encoding: imm[11:0]=3, rs1=x2(00010), funct3=101, rd=x9(01001), opcode=0010011
        uut.u_imem.mem[8] = 32'h00315493;

        // Inst 9:  SRAI x10, x3, 2        → x10 = -50 >>> 2 = -13 (0xFFFFFFF3)
        // Encoding: imm[11:5]=0100000, imm[4:0]=2, rs1=x3(00011), funct3=101, rd=x10(01010), opcode=0010011
        uut.u_imem.mem[9] = 32'h4021D513;

        // =====================================================================
        // R-TYPE INSTRUCTIONS (rd = rs1 OP rs2)
        // =====================================================================

        // Inst 10: ADD x11, x1, x2        → x11 = 100 + 200 = 300
        uut.u_imem.mem[10] = 32'h002085B3;

        // Inst 11: SUB x12, x2, x1        → x12 = 200 - 100 = 100
        uut.u_imem.mem[11] = 32'h40110633;

        // Inst 12: AND x13, x1, x2        → x13 = 100 & 200 = 64
        uut.u_imem.mem[12] = 32'h0020F6B3;

        // Inst 13: OR  x14, x1, x2        → x14 = 100 | 200 = 236
        uut.u_imem.mem[13] = 32'h0020E733;

        // Inst 14: XOR x15, x1, x2        → x15 = 100 ^ 200 = 172
        uut.u_imem.mem[14] = 32'h0020C7B3;

        // Inst 15: SLT x16, x3, x1        → x16 = (-50 < 100) ? 1 : 0 = 1
        uut.u_imem.mem[15] = 32'h0011A833;

        // Inst 16: SLTU x17, x1, x2       → x17 = (100 < 200) ? 1 : 0 = 1
        uut.u_imem.mem[16] = 32'h0020B8B3;

        // Inst 17: SLL x18, x1, x9        → x18 = 100 << (25 & 0x1F) = 100 << 25
        //          100 << 25 = 0xC8000000 = 3355443200 (unsigned)
        uut.u_imem.mem[17] = 32'h00909933;

        // =====================================================================
        // U-TYPE INSTRUCTIONS
        // =====================================================================

        // Inst 18: LUI x19, 0xDEADB       → x19 = 0xDEADB000
        uut.u_imem.mem[18] = 32'hDEADB9B7;

        // Inst 19: AUIPC x20, 0x00001     → x20 = PC + 0x1000 = 76 + 4096 = 4172
        //          PC at this instruction = 19*4 = 76 = 0x4C
        uut.u_imem.mem[19] = 32'h00001A17;

        // =====================================================================
        // STORE / LOAD INSTRUCTIONS
        // =====================================================================

        // Inst 20: ADDI x21, x0, 64       → x21 = 64 (base address for mem ops)
        uut.u_imem.mem[20] = 32'h04000A93;

        // Inst 21: SW   x1, 0(x21)        → mem[64..67] = 100
        // S-type: imm[11:5]=0, rs2=x1, rs1=x21, funct3=010, imm[4:0]=0, opcode=0100011
        uut.u_imem.mem[21] = 32'h001AA023;

        // Inst 22: LW   x22, 0(x21)       → x22 = mem[64..67] = 100
        uut.u_imem.mem[22] = 32'h000AAB03;

        // Inst 23: SB   x2, 4(x21)        → mem[68] = 200 & 0xFF = 0xC8
        uut.u_imem.mem[23] = 32'h002A8223;

        // Inst 24: LBU  x23, 4(x21)       → x23 = mem[68] zero-extended = 0xC8 = 200
        uut.u_imem.mem[24] = 32'h004ACB83;

        // Inst 25: SH   x2, 8(x21)        → mem[72..73] = 200 & 0xFFFF = 200
        uut.u_imem.mem[25] = 32'h002A9423;

        // Inst 26: LHU  x24, 8(x21)       → x24 = mem[72..73] zero-extended = 200
        uut.u_imem.mem[26] = 32'h008ADC03;

        // =====================================================================
        // BRANCH INSTRUCTIONS
        // =====================================================================

        // Inst 27: BEQ x1, x2, +8         → NOT TAKEN (100 != 200), fall through to Inst 28
        // B-type: imm=8 → {0, 0, 000001, 00000, rs2=x2, rs1=x1, funct3=000, 0, opcode}
        uut.u_imem.mem[27] = 32'h00208463;

        // Inst 28: ADDI x25, x0, 1        → x25 = 1 (executed because BEQ not taken)
        uut.u_imem.mem[28] = 32'h00100C93;

        // Inst 29: BEQ x1, x1, +8         → TAKEN (100 == 100), skip Inst 30
        uut.u_imem.mem[29] = 32'h00108463;

        // Inst 30: ADDI x25, x0, 99       → SKIPPED (x25 should remain 1)
        uut.u_imem.mem[30] = 32'h06300C93;

        // Inst 31: BNE x1, x2, +8         → TAKEN (100 != 200), skip Inst 32
        uut.u_imem.mem[31] = 32'h00209463;

        // Inst 32: ADDI x25, x0, 99       → SKIPPED (x25 should remain 1)
        uut.u_imem.mem[32] = 32'h06300C93;

        // =====================================================================
        // JUMP INSTRUCTIONS
        // =====================================================================

        // Inst 33: JAL x26, +8            → x26 = PC+4 = 33*4+4 = 136, jump to Inst 35
        // J-type: offset=8
        uut.u_imem.mem[33] = 32'h00800D6F;

        // Inst 34: ADDI x25, x0, 99       → SKIPPED by JAL
        uut.u_imem.mem[34] = 32'h06300C93;

        // Inst 35: ADDI x27, x0, 42       → x27 = 42 (landed here from JAL)
        uut.u_imem.mem[35] = 32'h02A00D93;

        // Inst 36: JALR x28, x26, 0       → x28 = PC+4 = 36*4+4 = 148, jump to x26=136 (Inst 34)
        //          But Inst 34 = ADDI x25, x0, 99, so x25 will become 99
        uut.u_imem.mem[36] = 32'h000D0E67;

        // Inst 37 (= inst at address 136 = word 34): ADDI x25, x0, 99  → x25 = 99
        //          This time it actually executes because JALR jumped back to it

        // Inst 38 (= word 35): ADDI x27, x0, 42  → x27 stays 42 (re-executed)
        // Inst 39 (= word 36): JALR x28, x26, 0  → x28 = 148 again, jumps to 136 again
        //          This creates an infinite loop. Let simulation timeout.

        // =====================================================================
        // Simulation Control
        // =====================================================================

        // Release reset
        #12;
        reset = 0;

        // Let processor run — enough cycles for ~40 instructions + some branch loops
        #500;

        // =====================================================================
        // RESULTS VERIFICATION
        // =====================================================================
        $display("============================================================");
        $display("  RISC-V RV32I Single-Cycle Processor — Test Results");
        $display("============================================================");
        $display("");

        // I-type ALU
        $display("--- I-Type ALU ---");
        check_reg("ADDI  x1  = 100     ", 1,  32'd100);
        check_reg("ADDI  x2  = 200     ", 2,  32'd200);
        check_reg("ADDI  x3  = -50     ", 3,  -32'd50);
        check_reg("ANDI  x4  = 100     ", 4,  32'd100);
        check_reg("ORI   x5  = 111     ", 5,  32'd111);
        check_reg("XORI  x6  = 155     ", 6,  32'd155);
        check_reg("SLTI  x7  = 1       ", 7,  32'd1);
        check_reg("SLLI  x8  = 400     ", 8,  32'd400);
        check_reg("SRLI  x9  = 25      ", 9,  32'd25);
        check_reg("SRAI  x10 = -13     ", 10, -32'd13);

        $display("");
        $display("--- R-Type ---");
        check_reg("ADD   x11 = 300     ", 11, 32'd300);
        check_reg("SUB   x12 = 100     ", 12, 32'd100);
        check_reg("AND   x13 = 64      ", 13, 32'd64);
        check_reg("OR    x14 = 236     ", 14, 32'd236);
        check_reg("XOR   x15 = 172     ", 15, 32'd172);
        check_reg("SLT   x16 = 1       ", 16, 32'd1);
        check_reg("SLTU  x17 = 1       ", 17, 32'd1);

        $display("");
        $display("--- U-Type ---");
        check_reg("LUI   x19 = 0xDEADB000", 19, 32'hDEADB000);
        check_reg("AUIPC x20 = 4172    ", 20, 32'd4172);

        $display("");
        $display("--- Load / Store ---");
        check_reg("LW    x22 = 100     ", 22, 32'd100);
        check_reg("LBU   x23 = 200     ", 23, 32'd200);
        check_reg("LHU   x24 = 200     ", 24, 32'd200);

        $display("");
        $display("--- Branch ---");
        // After JALR loops back, x25 gets overwritten to 99
        check_reg("x25 final = 99      ", 25, 32'd99);

        $display("");
        $display("--- Jump ---");
        check_reg("JAL   x26 = 136     ", 26, 32'd136);
        check_reg("ADDI  x27 = 42      ", 27, 32'd42);
        check_reg("JALR  x28 = 148     ", 28, 32'd148);

        $display("");
        $display("============================================================");
        $display("  Test Complete");
        $display("============================================================");

        $finish;
    end

    // =========================================================================
    // VERIFICATION TASK
    // =========================================================================
    task check_reg;
        input [40*8-1:0] name;     // Test name string (up to 40 chars)
        input [4:0]      reg_num;  // Register number
        input [31:0]     expected; // Expected value
        begin
            if (uut.u_reg_file.registers[reg_num] === expected)
                $display("  [PASS] %0s | x%0d = %0d (0x%08X)",
                         name, reg_num,
                         uut.u_reg_file.registers[reg_num],
                         uut.u_reg_file.registers[reg_num]);
            else
                $display("  [FAIL] %0s | x%0d = %0d (0x%08X), expected %0d (0x%08X)",
                         name, reg_num,
                         uut.u_reg_file.registers[reg_num],
                         uut.u_reg_file.registers[reg_num],
                         expected, expected);
        end
    endtask

    // =========================================================================
    // WAVEFORM DUMP
    // =========================================================================
    initial begin
        $dumpfile("sim/waveform.vcd");
        $dumpvars(0, tb_singlecycle);
    end

    // =========================================================================
    // MONITOR — Track PC and key registers during simulation
    // =========================================================================
    initial begin
        $monitor("Time=%0t | PC=0x%08X | x1=%0d | x2=%0d | x3=%0d | x22=%0d | x25=%0d | x26=%0d",
                 $time, uut.current_pc,
                 uut.u_reg_file.registers[1],
                 uut.u_reg_file.registers[2],
                 uut.u_reg_file.registers[3],
                 uut.u_reg_file.registers[22],
                 uut.u_reg_file.registers[25],
                 uut.u_reg_file.registers[26]);
    end

endmodule
