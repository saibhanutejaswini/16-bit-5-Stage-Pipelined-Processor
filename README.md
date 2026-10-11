# Pipelined16 — 16-Bit Five-Stage Pipelined Processor

## Overview

Pipelined16 is a 16-bit pipelined processor designed using **Verilog HDL** and simulated using **AMD Xilinx Vivado**.

The processor uses a five-stage pipeline to execute arithmetic, logical, memory, and control-flow instructions. This project demonstrates fundamental computer architecture concepts, including pipelining, data forwarding, hazard detection, and pipeline flushing.

## Features

- 16-bit processor architecture with a custom instruction set.
- Five-stage instruction pipeline.
- Eight general-purpose registers, R0–R7, each 16 bits wide.
- Arithmetic and logical operations.
- Immediate arithmetic using ADDI.
- LOAD and STORE memory instructions.
- Conditional branching using BEQ.
- Unconditional jumps using JUMP.
- Data forwarding to handle data dependencies.
- Hazard detection with load-use stall handling.
- Pipeline flushing to prevent incorrect execution after control-flow changes.
- Separate instruction and data memories, each containing 256 16-bit locations.
- Behavioral verification using a comprehensive Verilog testbench.

## Processor Architecture

The processor consists of five pipeline stages.

### 1. Instruction Fetch (IF)

Fetches the instruction from instruction memory using the program counter (PC). The PC advances sequentially or changes when a branch or jump redirects execution.

### 2. Instruction Decode (ID)

Decodes the fetched instruction, reads register operands, generates control signals, and identifies potential data hazards.

### 3. Execute (EX)

Performs arithmetic and logical operations using the ALU, calculates memory addresses, and evaluates conditional branches.

### 4. Memory Access (MEM)

Handles data-memory read and write operations for LOAD and STORE instructions.

### 5. Write Back (WB)

Writes the ALU result or loaded memory value into the destination register.

Pipeline registers transfer instruction data and control signals between successive stages.

## Instruction Set

The processor supports the following instructions:

- **R-type:** ADD, SUB, AND, OR, XOR.
- **ADDI:** Adds a sign-extended immediate value to a register.
- **LOAD:** Loads data from memory into a register.
- **STORE:** Stores register data into memory.
- **BEQ:** Branches when two registers contain equal values.
- **JUMP:** Transfers execution to an absolute instruction address.

### Instruction Formats

**R-type instruction**

`[15:12] Opcode | [11:9] RD | [8:6] RS1 | [5:3] RS2 | [2:0] FUNCT`

**I-type instruction**

`[15:12] Opcode | [11:9] RD | [8:6] RS1 | [5:0] Immediate`

LOAD and STORE use a register, base register, and 6-bit offset. BEQ uses two register operands and a 6-bit signed offset. JUMP uses a 12-bit absolute target address.

### ALU Operations

The ALU supports five operations:

- ADD — addition.
- SUB — subtraction.
- AND — bitwise AND.
- OR — bitwise OR.
- XOR — bitwise XOR.

## Pipeline Hazard Handling

### Data Forwarding

Forwarding allows results from later pipeline stages to be supplied directly to the execute stage when an instruction depends on a previous instruction's result. This reduces unnecessary stalls.

### Hazard Detection

The hazard detection unit identifies load-use dependencies. When an instruction requires a value that is still being loaded from memory, the processor inserts a stall to allow the data to become available.

### Pipeline Flushing

Pipeline flushing removes instructions that should not execute after a taken branch or jump. This prevents wrong-path instructions from modifying registers or memory.

## Project Structure

The current project uses a combined Verilog design file and a separate testbench.

```text
Pipelined16/
├── design code.v
├── testbench code.v
└── README.md
```

- `design code.v` contains the processor and its supporting modules.
- `testbench code.v` initializes the test program, runs the simulation, and checks expected register and memory values.
- `README.md` documents the project architecture, features, and verification process.

## Tools and Technologies

- **Verilog HDL** — hardware description and processor implementation.
- **AMD Xilinx Vivado** — Verilog compilation and behavioral simulation.
- **XSim** — simulation engine used through Vivado.

## How to Run the Simulation

1. Open the project in AMD Xilinx Vivado.
2. Add `design code.v` under Design Sources.
3. Add `testbench code.v` under Simulation Sources.
4. Set `testbench` as the simulation top module.
5. Select **Run Simulation → Run Behavioral Simulation**.
6. Review the simulation output in the Tcl Console or simulation window.

Ensure both files are included in the project before running the simulation.

## Verification Results

The comprehensive testbench has successfully passed its programmed checks in Vivado behavioral simulation.

The tested scenarios include:

- Arithmetic and logical instruction execution.
- Register writeback.
- LOAD and STORE operations.
- Load-use hazard detection and stalling.
- Taken and not-taken branch behavior.
- Jump handling.
- Prevention of wrong-path register updates.

The recorded simulation produced the expected register values and stored data, detected one load-use stall and one taken branch, and reported:

**PASS: All programmed checks passed.**

These results confirm that the programmed test cases passed. Further testing is needed to establish correctness across additional instruction sequences, and behavioral simulation alone does not establish successful FPGA implementation or timing closure.

## Learning Outcomes

This project provides practical experience with:

- Computer architecture and instruction encoding.
- Verilog module design and integration.
- Five-stage processor pipelining.
- ALU and register-file implementation.
- Data forwarding and hazard detection.
- Branch control and pipeline flushing.
- Testbench development and simulation-based verification.

## Future Improvements

- Expand the instruction set with additional operations.
- Add more automated test cases for edge conditions.
- Improve branch handling and hazard coverage.
- Add pipeline timing diagrams and simulation waveforms.
- Explore synthesis, static timing analysis, and FPGA implementation.

## Author

SAI BHANU TEJASWINI
Developed as an educational project to explore processor architecture, digital design, and Verilog-based hardware development.

---

*Pipelined16 — Learning processor architecture by building it from the ground up.*
