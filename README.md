<p align="center">
  <a href="https://github.com/QPSC-Design/PSC-ONE">
    <img src="docs/images/PSC-ONE_Logo.png" width="100%">
  </a>
</p>

# PSC-ONE SoC

An open-source full-stack RISC-V SoC platform for FPGA-based edge computing and AI acceleration.  
PSC-ONE integrates a custom CPU, memory subsystem, peripherals,
operating system, and AI accelerator into a unified architecture,
enabling end-to-end hardware/software co-design.

The SynapEngine accelerator is controlled directly through custom
RISC-V CSR registers and accesses matrix data through the shared
cache/memory subsystem. This reduces explicit data transfers and
redundant memory copies during matrix operations and future neural-network workloads.
  
The current PSC-ONE prototype hardware.  
  
<img src="docs/images/PSC-ONE_board.jpg" width="600">

The displayed color bars are generated directly by the PSC-ONE hardware and confirm correct operation of the LCD subsystem.　

<img src="docs/images/PSCONE_IPS_20260612.jpg" width="400">

The PSC-ONE boot logo rendered on the actual FPGA hardware during system startup, demonstrating successful LCD initialization and graphics output.  

<img src="docs/images/PSC_Boot_pic.jpg" width="600">

## What is PSC-ONE?

PSC-ONE is an open-source full-stack RISC-V SoC project developed by QPSC-Design.

It aims to build a fully custom edge computing platform from the ground up, including the following components:

- A custom RV32-based RISC-V CPU core
- A memory subsystem, including an SDRAM controller, caches, and an Sv32 MMU
- An SD card boot and storage interface
- Memory-mapped peripheral interfaces
- An AI acceleration engine, SynapEngine, based on a systolic array architecture
- A custom operating system, PSC-OS

PSC-ONE is not just a CPU core, but a complete experimental SoC platform for research, edge AI development, and architectural exploration.

---

## PSC-ONE SoC Architecture

<img src="docs/images/PSC_ONE_SoC_Block.jpg" width="800">

This section presents the overall PSC-ONE SoC architecture, including the
PSC_RV32ISP CPU, memory subsystem, peripherals, PSC-OS, and PSC-ONE AI.

---

## Repository Structure

- `hardware/` - FPGA RTL design, including the CPU core, memory subsystem, and peripherals
- `software/` - PSC-OS, boot code, and user-side software
- `docs/` - Architecture diagrams and supporting documentation

---

## Hardware Components

The hardware side of PSC-ONE currently includes:

- `PSC_RV32ISP` custom RISC-V CPU core
- SDRAM controller
- SD card interface (SPI mode)
- Memory-mapped peripheral system
- SynapEngine AI accelerator

---

## Software Stack

The software side of PSC-ONE currently includes:

- `PSC-OS`, a custom operating system for the platform
- Boot and initialization flow for FPGA-based execution
- User programs and runtime experiments, including UART-based output demos

---

# CPU (PSC_RV32ISP)

## CPU Architecture

This diagram presents the top-level architecture of the PSC system.  
It shows how the PSC_RV32ISP CPU core is integrated with memory and peripheral components, including UART, SDRAM, and the SD card interface.  
Most peripherals are connected through memory-mapped interfaces.
The SynapEngine accelerator is controlled directly through custom RISC-V
CSR registers and accesses matrix data through the shared cache/memory subsystem.
  
A key feature of the PSC architecture is the tightly coupled integration of the SynapEngine accelerator with the CPU.  
Both the PSC_RV32ISP core and the SynapEngine access memory through
the shared cache and memory subsystem.
Unlike loosely coupled accelerator designs that require explicit DMA transfers
for every operation, SynapEngine can directly access data through the shared
cache/memory subsystem, reducing redundant memory copies.
  
This tightly coupled architecture improves overall efficiency by reducing memory access overhead and is particularly suitable for data-intensive workloads such as matrix operations and future neural-network inference.

<img src="docs/images/PSC_RV32ISP.jpg" width="800">

Current CPU features include:

* RV32I base integer instruction set
* Zicsr CSR instructions
* Zifencei instruction support
* Integer multiplication support
* Integer division and remainder support
* Machine, Supervisor, and User privilege modes
* Exception and interrupt handling
* ECALL and SRET support
* Sv32 virtual memory
* Instruction and data caches
* Load-use and register-dependency handling
* Optional pipelined execution
* Custom hardware-accelerator integration

---

# CPU (PSC_RV32ISP_V1)

## CPU Architecture

The following diagram shows the internal architecture of the PSC_RV32ISP_V1 CPU and its connection to the PSC-ONE memory subsystem.

PSC_RV32ISP_V1 is a redesigned version of the original PSC_RV32ISP processor.  
Its execution logic is divided into independent functional modules, including instruction fetch, decode, arithmetic execution, branch processing, memory access, CSR control, and register write-back.

A central control unit dispatches operations to these modules and waits for their completion.  
This task-oriented organization replaces a tightly coupled monolithic state machine with a clearer and more modular architecture.

Instruction control information generated by the decoder is transferred between modules using a packed SystemVerilog structure.  
This reduces the number of individual control signals and makes the CPU easier to extend and maintain.

The CPU currently operates as a multi-cycle state-machine processor.  
However, the separation of execution modules provides a foundation for future pipelined execution, multiple instruction slots, and multithreaded operation.

<img src="docs/images/PSC_RV32ISP_V1.jpg" width="800">

The task-driven design provides:

* Clear separation between functional modules
* Explicit control of instruction execution order
* Support for variable-latency execution units
* Simple cache and MMU wait-state handling
* Unified handling of branches, loads, stores, CSR operations, and exceptions
* A foundation for multiple execution slots and limited parallel execution
* Easier extension with custom PSC-ONE hardware accelerators

PSC_RV32ISP_V1 currently uses a state-controlled execution model. Future versions may hold multiple instruction tasks simultaneously and permit independent tasks to overlap when there are no register, memory, or control dependencies.

## RISC-V ISA Test Results

The `PSC_RV32ISP_V1` processor has been verified using the official `riscv-tests` instruction test suite.

The following test groups currently pass in Verilator and cocotb simulation:

* RV32I base integer instruction tests
* RV32M multiplication, division, and remainder tests
* Load and store instruction tests
* Branch and jump instruction tests
* Shift and comparison instruction tests
* `FENCE.I` instruction test

A total of **49 official RISC-V ISA tests pass** on `PSC_RV32ISP_V1`.

The `rv32ui-ma_data` test is currently excluded because it requires misaligned data access support. PSC_RV32ISP_V1 currently expects naturally aligned load and store accesses.

Test sources are based on:

```text
https://github.com/riscv-software-src/riscv-tests
```

The tests are executed using:

```text
Verilator
cocotb
RISC-V GNU Toolchain
```


---

## PSC_RV32ISP vs PicoRV32 (Yosys Analysis)

### Resource Comparison

| Metric           | PSC_RV32ISP          | PicoRV32 |
|------------------|----------------------|----------|
| Cells            | 1385                 | 515      |
| Adders           | 15                   | 8        |
| Subtractors      | 4                    | 3        |
| Multipliers      | **3**                | **0**    |
| Multiplexers     | 377                  | 148      |
| Comparators      | 354                  | 69       |
| Registers (FF)   | 217                  | 105      |

---

## Architectural Features

| Feature                       | PSC_RV32ISP | PicoRV32 |
| ----------------------------- | :---------: | :------: |
| RV32I                         |      ✓      |     ✓    |
| Zicsr / CSR Support           |      ✓      | Optional |
| RV32M MUL/DIV/REM             |      ✓      | Optional |
| Privilege Modes (M/S/U)       |      ✓      |     ✗    |
| Sv32 MMU                      |      ✓      |     ✗    |
| Instruction FIFO              |      ✓      |     ✗    |
| Fetch/Execute Separation      |      ✓      |     ✗    |
| RAW Hazard Detection          |      ✓      |     ✗    |
| Load-Use Stall                |      ✓      |     ✗    |
| Pipeline Execution            |   Partial   |     ✗    |
| Instruction Cache             |      ✓      |     ✗    |
| Data Cache                    |      ✓      |     ✗    |

> Resource counts are based on generic Yosys RTL cells before FPGA
> technology mapping. PicoRV32 results depend on the selected configuration.
> Multiplexer counts include Yosys `$mux` cells only and exclude `$pmux` cells.

---

# PSC-ONE AI

PSC-ONE AI is a hardware accelerator platform for matrix multiplication (GEMM),
built around a custom systolic-array architecture.

It is part of the broader PSC-ONE experimental SoC platform,
which integrates:

- Custom RISC-V CPU
- Memory subsystem
- AI accelerator
- Hardware/software co-design environment

The project focuses on exploring efficient dataflow architectures
under constrained memory bandwidth for edge AI systems.

---

## PSC-ONE AI Architecture

<img src="docs/images/PSC_SynapEngine.jpg" width="800">

The system integrates the SynapEngine systolic array
with the PSC-ONE SoC platform.

---

## PSC-ONE AI Features

- 4×4 INT8 systolic array
- Output-Stationary (OS) dataflow
- Direct control through custom RISC-V CSR registers
- Direct matrix data access through the CPU cache/memory subsystem
- Integrated with the custom PSC-RV32ISP processor
- Experimental hardware/software co-design platform

---

## 8×8 Matrix Multiplication Performance

The following results compare the execution time of an 8×8 matrix multiplication across different PSC-RV32ISP configurations and the systolic array accelerator.

### Execution Time Comparison

| Configuration                                  | Execution Time | Performance vs. V1 |
| ---------------------------------------------- | -------------: | -----------------: |
| PSC_RV32ISP                                    |         591 µs |       ~1.80× faster |
| PSC_RV32ISP_V1                                 |        1066 µs |           Baseline |
| Systolic Array                                 |          44 µs |       ~24.2× faster |
| PSC_RV32ISP_V1 (Fetch FIFO enabled)            |         742 µs |       ~1.44× faster |
| PSC_RV32ISP_V1 (R/I-Type pipeline enabled)     |         651 µs |       ~1.64× faster |

### Results

The systolic array completed the 8×8 matrix multiplication in **44 µs**, approximately **24.2× faster** than the baseline PSC_RV32ISP_V1 processor.

Enabling the Fetch FIFO reduced the PSC_RV32ISP_V1 execution time from **1066 µs to 742 µs**. Enabling the R/I-Type pipeline further reduced it to **651 µs**, approaching the performance of the original PSC_RV32ISP processor at **591 µs**.

These results demonstrate that both instruction-fetch optimization and R/I-Type pipelining significantly improve CPU performance. However, the dedicated systolic array still provides a much larger performance advantage for matrix multiplication workloads.

---

## Systolic Array and PicoRV32 Resource Scale Comparison

### Resource Comparison

| Metric         | Systolic Array (4×4) | PicoRV32 |
| -------------- | -------------------: | -------: |
| Cells          |                  555 |      515 |
| Multipliers    |                **2** |    **0** |
| Adders         |                   25 |        8 |
| Multiplexers   |                  113 |      148 |
| Registers (FF) |                   88 |      105 |
| Control Logic  |             Moderate |     High |

> Multiplexer counts include Yosys `$mux` cells only and exclude `$pmux` cells.

- A **dataflow-oriented compute engine (Systolic Array)**
- A **control-oriented general-purpose CPU (PicoRV32)**

---

## PSC-ONE AI Goals

This project is not intended to compete with commercial AI accelerators.

Instead, the goal is to explore:

- Dataflow-oriented accelerator design
- Memory bandwidth optimization
- Small-scale AI hardware prototyping
- Hardware/software integration techniques
- Experimental SoC architecture research

---

## PSC-ONE AI Future Work

- Manufacturing a demonstration FPGA board
- Voice recognition demo using the AI accelerator
- Robot control using PSC-ONE AI
- Expansion of the systolic array architecture
- DMA and memory subsystem improvements

---

# PSC-OS

PSC-OS is a custom operating system developed specifically for the PSC-ONE platform.

Unlike Linux, BSD, or existing RTOSes, PSC-OS is designed together with the PSC_RV32ISP CPU, memory subsystem, peripherals, and hardware accelerators, providing a tightly integrated hardware/software co-design environment.

The following diagram illustrates the software architecture of PSC-OS, including user applications, the kernel, device drivers, and the underlying PSC-ONE hardware platform.

<img src="docs/images/PSC_OS.jpg" width="800">

> This diagram presents the conceptual architecture of PSC-OS and PSC-ONE. Some modules shown may represent planned or experimental extensions.

Current PSC-OS features include:

- Bootloader and kernel
- Machine, Supervisor, and User privilege modes
- Sv32 virtual memory
- ECALL-based system-call interface
- Interactive command shell
- FAT32 filesystem support
- SD-card boot and storage
- User-program loading and execution
- Device drivers for UART, LCD, I2S microphone, and SD card
- Native support for the SynapEngine and PFE hardware accelerators

PSC-OS serves both as the runtime environment for the PSC-ONE SoC and as an experimental platform for operating-system, CPU, and hardware/software co-design research.

---

# Demo

## PSC-OS LCD Demo

This video shows a live demonstration of the PSC system running on FPGA hardware.  
It highlights real-time interaction between the CPU, SD card interface, and UART output.  
The system successfully boots and executes software on a fully integrated hardware platform.

[![Watch the demo](https://img.youtube.com/vi/aRCHluWXozY/maxresdefault.jpg)](https://youtube.com/shorts/aRCHluWXozY?si=T0kp_dv_nBH07tnj)

---

## PSC-OS Boot

This video demonstrates the PSC system running `PSC-OS` on FPGA hardware after boot.  
It shows prime number computation executed on the custom `PSC_RV32ISP` CPU, with results transmitted over UART.  
The demo highlights a fully functional hardware-software stack, from boot to program execution.

[![Watch the demo](https://img.youtube.com/vi/lV74ni7FAt4/maxresdefault.jpg)](https://youtu.be/lV74ni7FAt4?si=_Xm8yCdqHN_oQzrs)

---

## PSC-OS Boot from SD Card

This demo uses a Kioxia 32GB SD card for storage.

<img src="docs/images/PSC_FPGA_SD_Card.jpg" width="400">

This video demonstrates the PSC system booting PSC-OS from an SD card on FPGA hardware.  
It shows the SD interface operating in serial mode, with CRC checks performed during data transfer.  
If an error is detected, the system automatically retries the read operation, ensuring reliable boot execution from external storage.  

[![Watch the demo](https://img.youtube.com/vi/FILxQiaqKrk/maxresdefault.jpg)](https://youtu.be/FILxQiaqKrk?si=9KQKO3LVkketo0ZM)

---

# Development Status

## Hardware

### CPU
- [x] RV32I Base Integer Instruction Set
- [x] RV32M Multiply/Divide Extension
- [x] Zicsr and Zifencei Extensions
- [ ] Full Pipeline Execution
- [x] Partial Pipeline Execution for selected instruction types
- [x] Branch Instructions
- [x] Load / Store Instructions
- [x] CSR Support
- [x] ECALL / SRET Support
- [x] MMU (Sv32)
- [ ] Interrupt Controller

### Memory System
- [x] SDRAM Controller
- [x] AXI4 Memory Interface
- [x] Cache Controller
- [x] Virtual Memory Support
- [x] DMA Engine

### AI Accelerator
- [x] SynapEngine Architecture
- [x] 4×4 INT8 Systolic Array
- [x] Matrix Multiplication API
- [x] Shared Memory Integration
- [ ] Larger Systolic Array
- [ ] Quantized Neural Network Inference

### Peripherals
- [x] UART
- [x] LED Controller
- [x] Timer
- [x] SD Card (SPI Mode, Read)
- [x] SD Card (SPI Mode, Write)
- [x] LCD Controller
- [ ] Ethernet
- [ ] USB

## Software

### PSC-OS
- [x] Bootloader
- [x] FAT32 Bootloader
- [x] Kernel
- [x] User Mode Execution
- [x] System Call Interface
- [x] Command Shell
- [x] Memory Management
- [x] SD Card Driver
- [x] SD Card Program Loader
- [x] FAT32 File System
- [ ] Networking Stack

### Device Drivers
- [x] UART
- [x] Timer
- [x] SDRAM Controller
- [x] LCD Controller (ILI9488)
- [x] I2S Microphone Interface
- [x] Systolic Array Accelerator

### Applications
- [x] Prime Number Benchmark
- [x] Matrix Multiplication Demo
- [x] SDRAM Test
- [x] SD Card Test
- [x] FAT32 File Browser (`ls`, `cat`)
- [x] FAT32 File Write
- [ ] AI Inference Demo
- [ ] Audio Processing Demo
- [ ] Speech Recognition Demo

## Verification

### Simulation
- [x] Icarus Verilog
- [x] Verilator
- [x] Cocotb Test Environment
- [x] Official RISC-V ISA tests: 49 RV32I/RV32M tests passed
- [x] SDRAM Tests
- [x] MMU Tests
- [x] PSC-OS Boot Test

### FPGA
- [x] Tang 20K
- [x] SDRAM Boot
- [x] PSC-OS Boot
- [x] UART Console
- [x] SD Card Boot
- [x] SynapEngine Execution
- [ ] Long-Term Stability Test

## Documentation

- [x] Project Overview
- [x] Build Instructions
- [x] Simulation Guide
- [x] Hardware Architecture
- [ ] Software Architecture
- [ ] Developer Guide
- [ ] API Reference

## Future Goals

- [ ] PSC-ONE v1.0 Release
- [ ] Neural Network Inference on SynapEngine
- [ ] Audio Recognition Demo
- [ ] Self-Balancing Robot Demo
- [ ] Custom ASIC Prototype

---

# Future Work

## Demonstration FPGA board

A demonstration FPGA board is currently under development.
Future work includes speech recognition and robotic control using the AI accelerator.

<img src="docs/images/PSC-ONE_RedBoard.png" width="700">

## Speech Recognition Demo

This demo showcases real-time speech recognition running on the PSC-ONE platform.  
An external microphone captures voice input, which is processed by the onboard SynapEngine AI accelerator. The recognized text is then displayed directly on the LCD screen in real time.  

<img src="docs/images/PSC_ONE_voice_anime_en.png" width="700">

## Demonstration Robot

A demonstration of a two-wheeled self-balancing robot controlled by the PSC-ONE board is also planned

<img src="docs/images/Demo_Robot.jpg" width="500">

## PFE

### PSC-ONE Phase Flow Engine

The PSC-ONE Phase Flow Engine is an experimental hardware accelerator architecture developed as part of the PSC project.
It is designed for future AI, signal-processing, and data-flow computing research on the PSC-ONE platform.

Location:

```text
hardware/pfe/
```

---

# Getting Started

A more detailed setup guide will be added as the project evolves.  
At a high level, the workflow is as follows:

1. Build the hardware design
2. Program the FPGA
3. Prepare the boot image or software binaries
4. Run the system and observe output through the available interfaces

---

# Repository Status

This repository is an experimental research project
and is under active development.

RTL, software, and architecture may change frequently.

---

# License

MIT License

---

## 🚧 Work in Progress

This project is actively under development.  
Features, architecture, interfaces, and documentation may change as the design evolves.