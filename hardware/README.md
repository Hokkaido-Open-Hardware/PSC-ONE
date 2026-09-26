<p align="center">
  <a href="https://github.com/QPSC-Design/PSC-ONE">
    <img src="../docs/images/PSC-ONE_Logo.png" width="640" alt="PSC-ONE Logo">
  </a>
</p>

# PSC-ONE Hardware

[Project](../README.md) · [Documentation](../docs/README.md) · [MMU](../docs/cpu_mmu.md)

| Selection | RTL / documentation |
| --- | --- |
| CPU legacy | [Original CPU](rtl/soc/cpu/) |
| CPU v1 | [Stable CPU](rtl/soc/cpu_v1/) |
| CPU v2 | [Experimental CPU](rtl/soc/cpu_v2_experimental/) |
| NPU legacy | [Configurable shared multipliers](rtl/soc/npu/README.md) |
| NPU v1 | [Fixed four-lane MAC](rtl/soc/npu_v1/README.md) |
| NPU v2 | [Experimental shift/add](rtl/soc/npu_v2/README.md) |

CPU and NPU versions are selected separately. The legacy NPU diagram in the accelerator section
explains the shared-arithmetic concept; it does not specify the v1/v2 datapath.

This directory contains the RTL hardware design of **PSC-ONE**, a fully custom FPGA-based RISC-V SoC.

------------------------------------------------------------------------

<!-- contents -->
- [Overview](#overview)
- [Main Components](#main-components)
- [CPU (PSC_RV32_V1)](#cpu-psc_rv32_v1)
- [CPU (PSC_RV32_V2)](#cpu-psc_rv32_v2)
- [PSC-NPU (SynapEngine)](#psc-npu-synapengine)
- [PFE QUBO Engine](#pfe-qubo-engine)
- [I2S Audio Interface](#i2s-audio-interface)
- [Display Interface](#display-interface)
- [Interconnect Architecture](#interconnect-architecture)
- [Hardware/Software Co-Design](#hardwaresoftware-co-design)
- [Verification](#verification-1)
- [Current Status](#current-status)
- [Notes](#notes)
- [Status](#status)
<!-- /contents -->

## Overview

PSC-ONE is an experimental full-stack SoC that integrates:

* A custom RISC-V CPU
* Cache and memory-management units
* SDRAM and boot memory
* Storage and multimedia interfaces
* Custom hardware accelerators
* A dedicated operating system, PSC-OS

The project is designed as a hardware/software co-design platform for CPU architecture, operating systems, memory systems, and application-specific accelerators.

The main target platform is currently the **Tang Nano 20K**, using the FPGA's internal SDRAM as system memory.

------------------------------------------------------------------------

## Main Components

### PSC_RV32 CPU

**PSC_RV32** is a custom 32-bit RISC-V processor designed from scratch for PSC-ONE.

The following diagram shows the internal architecture of the PSC_RV32 CPU and its connection to the PSC-ONE memory subsystem.

The CPU integrates instruction fetch and execution logic, general-purpose registers, CSR control, privilege-mode handling, Sv32 address translation, instruction and data caches, and interfaces to system memory and memory-mapped peripherals.

<img src="../docs/images/PSC_RV32.jpg" width="800" alt="PSC RV32">

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

The CPU is designed to execute PSC-OS and user applications directly on the FPGA.

------------------------------------------------------------------------

## CPU (PSC_RV32_V1)

### CPU Architecture

The following diagram shows the internal architecture of the PSC_RV32_V1 CPU and its connection to the PSC-ONE memory subsystem.

PSC_RV32_V1 is the primary RISC-V CPU core used in PSC-ONE.

The CPU uses a **pipelined execution architecture** designed to overlap instruction processing and reduce the number of cycles required per instruction.

Instruction fetch is handled by a dedicated fetch unit with **branch prediction**, allowing the CPU to continue fetching from a predicted program counter before the branch result is known.

Arithmetic, branch, LOAD, and STORE operations are integrated into the pipelined execution flow. Forwarding and pipeline control logic are used to handle dependencies and maintain correct instruction execution.

The core implements **RV32I** together with CSR and fence instructions, integer multiplication, and division/remainder operations.

PSC_RV32_V1 supports **Machine, Supervisor, and User privilege modes** and **Sv32 virtual memory translation**. Instruction and data accesses use separate cache paths connected to the PSC-ONE memory subsystem.

<img src="../docs/images/PSC_RV32_V1.jpg" width="800" alt="PSC RV32 V1">

> Diagram note: the drawing labels the main instruction FIFO as 32 words.
> The current v1 FetchUnit defaults to 16 words; the predicted-target FIFO
> remains 8 words. The image is retained as an earlier configuration.

The PSC_RV32_V1 architecture provides:

* Pipelined instruction execution
* Branch prediction and speculative instruction fetch
* Pipeline forwarding and dependency handling
* Pipelined LOAD and STORE execution
* RV32I integer instructions
* Integer multiplication and division/remainder
* CSR and fence instructions
* Machine, Supervisor, and User privilege modes
* Sv32 virtual memory translation
* Separate instruction and data caches
* Exception and interrupt processing
* Memory-mapped PSC-ONE peripheral and accelerator access

PSC_RV32_V1 is the stable FPGA-oriented CPU. Throughput depends on the workload and memory configuration. Its two SIMD extensions are described in the [PULP specification](../docs/cpu_pulp.md) ([日本語](../docs/cpu_pulp_JP.md)).

------------------------------------------------------------------------

## CPU (PSC_RV32_V2)

### Experimental Out-of-Order Architecture

<img src="../docs/images/PSC_RV32_V2.jpg" width="800" alt="PSC RV32 V2">

V2 implements a small out-of-order backend with register renaming and in-order
retirement. Its [instruction unit](rtl/soc/cpu_v2_experimental/src/PSC_InstructionUnit.sv)
defaults to ROB=2, IQ=2 and PRF=34. Independent ready instructions may execute
while an older operation is stalled. Memory/CSR side effects are controlled at
the ROB head. V1 also overlaps pipeline stages; it is not a serialized baseline.

Two ROB slots describe in-flight capacity, not a guarantee of two instructions
issued or retired every clock. V2 remains experimental.

#### Verification

Run from `PSC-ONE/hardware/sim` with the toolchain and cocotb environment ready:

```sh
make -f Makefile.riscv.sim simulate_RISCV_TESTS_PARALLEL CPU_VERSION=v2
make -f Makefile.cpu.core simulate_CPU_CORE CPU_VERSION=v2
make -f Makefile.cpu simulate_PSC_ONE_TESTS TEST_PROGRAM_LIST=basic CPU_VERSION=v2
make -f Makefile.cpu simulate_PSC_ONE_TESTS TEST_PROGRAM_LIST=long CPU_VERSION=v2
```

### RISC-V ISA Test Results

The `PSC_RV32_V1` processor has been verified using the official `riscv-tests` instruction test suite.

The following test groups currently pass in Verilator and cocotb simulation:

* RV32I base integer instruction tests
* RV32M multiplication, division, and remainder tests
* Load and store instruction tests
* Branch and jump instruction tests
* Shift and comparison instruction tests
* `FENCE.I` instruction test

The recorded v1 regression result is **49/49 RISC-V ISA tests passed**. This is a historical result, not a test run performed by editing this README.

The `rv32ui-ma_data` test is currently excluded because it requires misaligned data access support. PSC_RV32_V1 currently expects naturally aligned load and store accesses.

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

------------------------------------------------------------------------

### Memory Management Unit

PSC-ONE includes an Sv32-compatible virtual-memory system.

The memory-management architecture includes:

* Sv32 page-table translation
* SATP register support
* `SFENCE.VMA` support
* Machine, Supervisor, and User address spaces
* Memory protection through page permissions
* Separate kernel and user memory regions

The MMU provides address translation for PSC-OS user programs. See the [ELF protection limitations](../software/os/tests/elf/README.md#remaining-protection-limitation) before treating this as complete process isolation.

------------------------------------------------------------------------

### Cache System

PSC-ONE includes separate instruction and data cache paths.

The cache architecture supports:

* Cached instruction fetches
* Cached data reads and writes
* Write-back operation
* Write-no-allocate behavior
* Cache bypass for memory-mapped peripherals
* Software-managed coherency with hardware accelerators

SynapEngine and other accelerators share the system memory with the CPU. Software performs the required cache synchronization before and after accelerator execution.

------------------------------------------------------------------------

### SDRAM System

The current Tang Nano 20K implementation uses the FPGA's integrated SDRAM as the main system memory.

The memory subsystem provides storage for:

* PSC-OS kernel
* User programs
* Application data
* Matrix input and output data
* Audio samples
* SD-card transfer buffers

The CPU, caches, DMA-related logic, and hardware accelerators access the shared memory architecture.

------------------------------------------------------------------------

### Boot System

PSC-ONE contains boot ROM logic used to initialize the system and load software from an SD card.

The boot process loads:

* PSC-OS kernel image
* User program image
* Required runtime data

The loaded software is copied into system memory before execution begins.

------------------------------------------------------------------------

### SD Card Interface

PSC-ONE includes an SPI-mode SD-card controller.

Current SD-card support includes:

* SD-card initialization
* Single-sector read
* Single-sector write
* FAT32 filesystem access
* Kernel and user-program loading
* File access from PSC-OS
* Audio and application-data storage

SPI mode is used to keep the hardware implementation compact and reliable.

------------------------------------------------------------------------

### UART Interface

The UART interface provides:

* Boot and debug output
* PSC-OS command-line access
* Test-result output
* Hardware and software diagnostics

UART is the primary development and debugging interface.

------------------------------------------------------------------------

## PSC-NPU (SynapEngine)

**PSC-NPU** is the matrix-processing accelerator integrated into PSC-ONE.

The following diagram shows the internal architecture of PSC-NPU.

The legacy PSC-NPU implements a logical 4×4 Output-Stationary systolic array using virtualized PE contexts. PE state and dataflow control are separated from the arithmetic units, allowing the logical PE array to share a configurable number of external multipliers.

<img src="../docs/images/PSC_NPU.jpg" width="800" alt="PSC NPU">

> Diagram note: “share a single multiplier” describes the shared-arithmetic
> concept. The legacy multiplier count is configurable; NPU v1 uses four
> physical multiplier lanes. The drawing is not an exact v1/v2 netlist.

The legacy implementation provides:

* 4×4 logical int8 systolic array
* Output-Stationary dataflow
* 32-bit partial-sum accumulation
* Virtualized Processing Elements
* Hardware-multithreading-style PE execution
* Shared PE control logic
* External arithmetic units
* Configurable number of physical multipliers
* Support for matrices larger than 4×4 through tiled execution
* Direct integration with the CPU cache and memory system
* cocotb-based verification

Unlike a conventional systolic array, PSC-NPU does not require a dedicated multiplier inside every PE.

The PE contexts maintain dataflow state and partial sums, while multiplication is performed by a configurable number of external shared multipliers.

Conceptually:

```text
Logical PE contexts
        │
        ▼
Arithmetic scheduler
        │
        ▼
Shared multiplier units
        │
        ▼
PE partial-sum accumulation
```

This architecture allows the number of physical multipliers to be selected independently of the logical 4×4 array size.

Because the arithmetic units are separated from PE control and state, future versions may support arithmetic operations other than integer multiplication.

Possible future extensions include:

* FP16 or BF16 arithmetic
* Alternative arithmetic operators
* 1×16 or 16×1 logical PE arrangements
* FIR filtering
* One-dimensional convolution
* Configurable PE interconnect topologies

These topology-reconfiguration features are architectural concepts and are not implemented in the current version.

------------------------------------------------------------------------

## PFE QUBO Engine

PSC-ONE includes an experimental **PFE** accelerator for QUBO-related computation.

The PFE engine provides:

* Memory-mapped control
* QUBO coefficient input
* Binary-variable input
* Hardware energy calculation
* CPU-readable result and status registers

This engine is used to explore non-von-Neumann and optimization-oriented hardware architectures.

------------------------------------------------------------------------

## I2S Audio Interface

PSC-ONE contains an I2S receive interface for digital microphone input.

The current audio path supports:

* Mono audio input
* 16 kHz sampling
* 24-bit I2S sample reception
* FIFO-based buffering
* PSC-OS audio capture
* SD-card storage of recorded samples

The audio interface is intended for future speech-recognition and signal-processing experiments.

------------------------------------------------------------------------

## Display Interface

PSC-ONE supports an ILI9488-based LCD module.

The display interface is used for:

* System status output
* Application output
* Audio and AI demonstration interfaces
* Standalone operation without a host terminal

------------------------------------------------------------------------

## Interconnect Architecture

PSC-ONE uses a unified memory-mapped address architecture.

The memory address space and accelerator control interfaces include:

* Boot ROM
* SDRAM
* Cacheable system memory
* UART
* SD-card controller
* I2S interface
* Display controller
* SynapEngine
* PFE accelerator
* Other control and status registers

Memory accesses are routed according to the target address.

Normal memory is accessed through the cache and SDRAM paths, while peripheral regions bypass the cache and access the corresponding hardware modules directly.

------------------------------------------------------------------------

## Hardware/Software Co-Design

PSC-ONE hardware is developed together with PSC-OS.

PSC-OS provides software interfaces for:

* Process execution
* Virtual memory
* SD-card and FAT32 access
* Audio capture
* Display output
* SynapEngine matrix multiplication
* Experimental PFE hardware (a PSC-OS API is not currently exposed)
* Hardware diagnostics

This allows new hardware features to be tested through complete software workloads rather than isolated RTL simulations alone.

------------------------------------------------------------------------

## Verification

PSC-ONE uses multiple levels of verification:

* RTL simulation
* cocotb testbenches
* CPU instruction tests
* Cache and memory-access tests
* Full SoC boot simulation
* SynapEngine matrix-result comparison
* SD-card read/write tests
* FPGA implementation tests

Hardware accelerator results are compared against software reference implementations.

------------------------------------------------------------------------

## Current Status

The current PSC-ONE hardware supports:

* Custom RV32 CPU operation
* Machine, Supervisor, and User privilege modes
* Sv32 virtual memory
* Instruction and data caches
* Internal SDRAM access
* SD-card boot
* FAT32 read and write
* UART console
* LCD output
* I2S microphone input
* 4×4 Output-Stationary SynapEngine
* PFE QUBO acceleration
* PSC-OS execution
* User-program execution

------------------------------------------------------------------------

## Notes

* The current primary FPGA target is the Tang Nano 20K
* Main memory uses the FPGA's integrated SDRAM
* The SD-card controller operates in SPI mode
* Peripherals use MMIO; NPU control uses custom CPU CSRs and matrix buffers in memory
* CPU and accelerator memory coherency is currently managed by software
* SynapEngine currently uses a logical 4×4 Output-Stationary configuration
* SynapEngine arithmetic units are external to the logical PE array
* RTL interfaces and module organization may change as development continues

------------------------------------------------------------------------

## Status

🚧 **Active Development**

PSC-ONE is operational but remains an experimental architecture.

The CPU, operating system, memory subsystem, and hardware accelerators are continuously being extended and optimized.
