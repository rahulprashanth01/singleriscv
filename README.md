# RISC-V RV32I Single-Cycle Processor

A complete RV32I base integer single-cycle processor implemented in Verilog.

## Supported Instructions (37 total)

| Type | Instructions |
|------|-------------|
| **R-type** | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND |
| **I-type ALU** | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI |
| **Load** | LB, LH, LW, LBU, LHU |
| **Store** | SB, SH, SW |
| **Branch** | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| **U-type** | LUI, AUIPC |
| **Jump** | JAL, JALR |

**Not implemented:** ECALL, EBREAK, FENCE, CSR instructions (system calls).

## Project Structure

```
singlecyclecore/
├── rtl/
│   ├── datapath/              # Data-moving components
│   │   ├── pc.v               # Program counter
│   │   ├── pc_adder.v         # PC + 4 adder
│   │   ├── alu.v              # Arithmetic logic unit
│   │   ├── register_file.v    # 32x32 register file
│   │   ├── imm_gen.v          # Immediate generator (I/S/B/U/J)
│   │   ├── instruction_mem.v  # Instruction memory (256 words)
│   │   ├── data_mem.v         # Data memory (1KB, byte-addressable)
│   │   └── mux2to1.v          # Parameterized 2:1 multiplexer
│   │
│   ├── control/               # Control-path components
│   │   ├── main_control.v     # Main control decoder
│   │   ├── alu_control.v      # ALU operation decoder
│   │   └── branch_logic.v     # Branch condition evaluator
│   │
│   └── top/                   # Top-level integration
│       └── singlecycle_top.v  # Full processor top module
│
├── tb/                        # Testbenches
│   └── tb_singlecycle.v       # Comprehensive test program
│
├── sim/                       # Simulation outputs
│   └── waveform.vcd           # Generated waveform file
│
└── README.md                  # This file
```

## Simulation

### Using Icarus Verilog

```bash
# Compile
iverilog -o sim/singlecycle_sim rtl/datapath/*.v rtl/control/*.v rtl/top/*.v tb/tb_singlecycle.v

# Simulate
vvp sim/singlecycle_sim

# View waveform (optional)
gtkwave sim/waveform.vcd
```

## Architecture

The processor follows the classic single-cycle microarchitecture from Patterson & Hennessy's
*Computer Organization and Design* textbook, with all instructions completing in a single
clock cycle. The datapath features:

- **PC** with branch/jump target multiplexer
- **Instruction Memory** (word-addressed, 256 entries)
- **Register File** (32 x 32-bit, x0 hardwired to zero)
- **Immediate Generator** (handles all 5 RISC-V formats)
- **ALU** with 10 operations
- **Data Memory** (byte-addressable, 1KB, supports LB/LH/LW/LBU/LHU/SB/SH/SW)
- **Write-back mux** (ALU result / memory data / PC+4)
- **Branch logic** (evaluates all 6 branch conditions)
- **AUIPC mux** (selects PC as ALU input A for AUIPC)
