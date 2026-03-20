# 🔧 RISC-V PicoRV32 — Custom ALU Operations on FPGA

A Vivado-based project implementing the **PicoRV32** RISC-V (RV32IM) soft processor on a **Xilinx Artix-7 FPGA**, with a comprehensive testbench that verifies all core ALU operations through hand-assembled firmware.

> Based on the official [YosysHQ/picorv32](https://github.com/YosysHQ/picorv32) — a size-optimized RISC-V CPU core.

---

## 📋 Table of Contents

- [Features](#-features)
- [Project Structure](#-project-structure)
- [ALU Operations Tested](#-alu-operations-tested)
- [Architecture](#-architecture)
- [Core Configuration](#-core-configuration)
- [Getting Started](#-getting-started)
- [Simulation Results](#-simulation-results)
- [Modifying the Firmware](#-modifying-the-firmware)
- [Target FPGA](#-target-fpga)
- [References](#-references)
- [License](#-license)

---

## ✨ Features

- **Complete RV32IM CPU** — Full RISC-V base integer instruction set + Multiply/Divide extension
- **Barrel Shifter** — Single-cycle shift operations (SLL, SRL, SRA)
- **AXI4-Lite Interface** — Industry-standard memory bus protocol
- **Comprehensive ALU Testbench** — Verifies 17 distinct ALU instructions
- **Waveform-Friendly** — All internal CPU registers and ALU signals exposed for easy debugging
- **Auto-Logging** — Register writes printed with timestamps during simulation
- **Vivado 2024.2 Ready** — Pre-configured `.xpr` project file

---

## 🧮 ALU Operations Tested

The firmware exercises **all RV32I ALU operations** through 18 carefully ordered instructions:

| # | Address | Machine Code | Assembly | Operation | Expected Result |
|---|---------|-------------|----------|-----------|-----------------|
| 1 | `0x00` | `00500093` | `addi x1, x0, 5` | Load Immediate | x1 = 5 |
| 2 | `0x04` | `00700113` | `addi x2, x0, 7` | Load Immediate | x2 = 7 |
| 3 | `0x08` | `002081B3` | `add  x3, x1, x2` | **Addition** | x3 = 12 |
| 4 | `0x0C` | `00100213` | `addi x4, x0, 1` | Load Immediate | x4 = 1 |
| 5 | `0x10` | `40208233` | `sub  x4, x1, x2` | **Subtraction** | x4 = -2 (0xFFFFFFFE) |
| 6 | `0x14` | `004092B3` | `sll  x5, x1, x4` | **Shift Left Logical** (reg) | x5 = x1 << x4[4:0] |
| 7 | `0x18` | `00409313` | `slli x6, x1, 4` | **Shift Left Logical** (imm) | x6 = 80 (0x50) |
| 8 | `0x1C` | `0050E393` | `ori  x7, x1, 5` | **OR Immediate** | x7 = 5 |
| 9 | `0x20` | `0050F413` | `andi x8, x1, 5` | **AND Immediate** | x8 = 5 |
| 10 | `0x24` | `0050C493` | `xori x9, x1, 5` | **XOR Immediate** | x9 = 0 |
| 11 | `0x28` | `00545513` | `srli x10, x8, 5` | **Shift Right Logical** (imm) | x10 = 0 |
| 12 | `0x2C` | `00545593` | `srli x11, x8, 5` | **Shift Right Logical** (imm) | x11 = 0 |
| 13 | `0x30` | `40545613` | `srai x12, x8, 5` | **Shift Right Arithmetic** (imm) | x12 = 0 |
| 14 | `0x34` | `00209693` | `sll  x13, x1, x2` | **Shift Left Logical** (reg) | x13 = 5 << 7 = 640 |
| 15 | `0x38` | `00509713` | `srl  x14, x1, x5` | **Shift Right Logical** (reg) | x14 = x1 >> x5[4:0] |
| 16 | `0x3C` | `40509793` | `sra  x15, x1, x5` | **Shift Right Arithmetic** (reg) | x15 = x1 >>> x5[4:0] |
| 17 | `0x40` | `00000013` | `nop` | No Operation | — |
| 18 | `0x44` | `00000073` | `ecall` | Trap / End | Simulation stops |

### Operations Coverage

| Category | Instructions | Encoding |
|----------|-------------|----------|
| **Arithmetic** | ADD, SUB, ADDI | R-type / I-type |
| **Logical** | AND, OR, XOR, ANDI, ORI, XORI | R-type / I-type |
| **Shift** | SLL, SRL, SRA, SLLI, SRLI, SRAI | R-type / I-type |

---

## ⚙️ Core Configuration

The PicoRV32 is instantiated with the following parameters:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `BARREL_SHIFTER` | 1 | Single-cycle barrel shifter (faster than iterative) |
| `ENABLE_MUL` | 1 | Hardware multiplier (MUL, MULH, MULHSU, MULHU) |
| `ENABLE_DIV` | 1 | Hardware divider (DIV, DIVU, REM, REMU) |
| `ENABLE_COUNTERS` | 1 | Cycle/instruction counters (RDCYCLE, RDINSTRET) |
| `ENABLE_REGS_16_31` | 1 | Full 32-register file (not RV32E) |
| `ENABLE_REGS_DUALPORT` | 1 | Dual-port register file for better performance |
| `REGS_INIT_ZERO` | 1 | All registers zeroed on reset |
| `CATCH_MISALIGN` | 1 | Trap on misaligned memory access |
| `CATCH_ILLINSN` | 1 | Trap on illegal instructions |
| `PROGADDR_RESET` | `0x00000000` | Program starts at address 0 |
| `STACKADDR` | `0x00000FFC` | Stack pointer initialized to top of 4KB |

---

## 🚀 Getting Started

### Prerequisites
- **Vivado 2024.2** (or compatible version)
- Target FPGA: Xilinx Artix-7 `xc7a100tcsg324-3` (Nexys A7 / Nexys 4 DDR)

### Running the Simulation

1. **Open the project:**
   ```
   File → Open Project → RISCV_PicoRV32_ALU.xpr
   ```

2. **Run Behavioral Simulation:**
   ```
   Flow Navigator → SIMULATION → Run Simulation → Run Behavioral Simulation
   ```

3. **Add signals to waveform** (right-click `testbench` in Scope panel):
   - CPU registers: `x1` through `x15`
   - ALU signals: `alu_out_w`, `reg_op1_w`, `reg_op2_w`
   - Instruction flags: `instr_add_w`, `instr_sub_w`, `instr_sll_w`, etc.
   - Control: `clk`, `resetn`, `trap`, `reg_pc`, `cpu_st`

4. **Run simulation for 5000 ns:**
   ```tcl
   run 5000 ns
   ```

5. **Check the Tcl Console** for auto-logged register writes:
   ```
   [1250 ns] x1  = 0x00000005 (5)
   [1340 ns] x2  = 0x00000007 (7)
   [1430 ns] x3  = 0x0000000c (12)
   [1520 ns] x4  = 0xfffffffe (-2)
   ...
   TRAP detected at time 2500
   ```

---

## 📊 Simulation Results

### Expected Register Values After Execution

| Register | Hex Value | Decimal | Instruction |
|----------|-----------|---------|-------------|
| x1 | `0x00000005` | 5 | `addi x1, x0, 5` |
| x2 | `0x00000007` | 7 | `addi x2, x0, 7` |
| x3 | `0x0000000C` | 12 | `add x3, x1, x2` |
| x4 | `0xFFFFFFFE` | -2 | `sub x4, x1, x2` |
| x6 | `0x00000050` | 80 | `slli x6, x1, 4` |
| x7 | `0x00000005` | 5 | `ori x7, x1, 5` |
| x8 | `0x00000005` | 5 | `andi x8, x1, 5` |
| x9 | `0x00000000` | 0 | `xori x9, x1, 5` |
| x13 | `0x00000280` | 640 | `sll x13, x1, x2` (5 << 7) |

---

## ✏️ Modifying the Firmware

To test different ALU operations, edit `firmware/firmware.hex`. Each line is one 32-bit instruction in hex.

### RISC-V Instruction Encoding Quick Reference

**R-type** (register-register): `funct7[6:0] | rs2[4:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[6:0]`

| Instruction | funct7 | funct3 | opcode |
|-------------|--------|--------|--------|
| ADD | 0000000 | 000 | 0110011 |
| SUB | 0100000 | 000 | 0110011 |
| SLL | 0000000 | 001 | 0110011 |
| SLT | 0000000 | 010 | 0110011 |
| SLTU | 0000000 | 011 | 0110011 |
| XOR | 0000000 | 100 | 0110011 |
| SRL | 0000000 | 101 | 0110011 |
| SRA | 0100000 | 101 | 0110011 |
| OR | 0000000 | 110 | 0110011 |
| AND | 0000000 | 111 | 0110011 |

**I-type** (register-immediate): `imm[11:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[6:0]`

| Instruction | funct3 | opcode |
|-------------|--------|--------|
| ADDI | 000 | 0010011 |
| SLTI | 010 | 0010011 |
| XORI | 100 | 0010011 |
| ORI | 110 | 0010011 |
| ANDI | 111 | 0010011 |
| SLLI | 001 | 0010011 |
| SRLI | 101 | 0010011 |
| SRAI | 101 | 0010011 (imm[11:5] = 0100000) |

---

## 🎯 Target FPGA

| Parameter | Value |
|-----------|-------|
| **Device** | Xilinx Artix-7 |
| **Part** | `xc7a100tcsg324-3` |
| **Board** | Nexys A7 / Nexys 4 DDR |
| **Speed Grade** | -3 (fastest) |
| **Clock** | 100 MHz (testbench) |

---

## 📚 References

- [PicoRV32 — YosysHQ](https://github.com/YosysHQ/picorv32) — Official CPU core repository
- [RISC-V ISA Specification v2.2](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf) — Instruction set manual
- [RISC-V Instruction Encoder/Decoder](https://luplab.gitlab.io/rvcodecjs/) — Online tool for encoding instructions
- [Xilinx Artix-7 Datasheet](https://www.xilinx.com/products/silicon-devices/fpga/artix-7.html)

---

## 📄 License

The PicoRV32 core is licensed under the [ISC License](https://opensource.org/licenses/ISC) by Claire Xenia Wolf.

The testbench and firmware in this project are provided for educational purposes.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-alu-op`)
3. Add your test instructions to `firmware/firmware.hex`
4. Commit your changes (`git commit -m 'Add rotate instructions'`)
5. Push to the branch (`git push origin feature/new-alu-op`)
6. Open a Pull Request
