<p align="center">
  <a href="https://github.com/QPSC-Design/PSC-ONE">
    <img src="images/PSC-ONE_Logo.png" width="100%">
  </a>
</p>

# Getting Started with PSC-ONE

This guide provides a quick introduction to building, simulating, and running **PSC-ONE**.

PSC-ONE is an FPGA-based RISC-V SoC project featuring a custom RISC-V CPU, PSC-OS, external SDRAM, peripherals, and hardware accelerators.

The goal of this guide is to get PSC-ONE running first.

For detailed information about the architecture and implementation, see the main [README](../README.md).

---

## 1. Hardware

PSC-ONE currently targets the **Tang Nano 20K** FPGA development board.

Main components used by PSC-ONE include:

* Tang Nano 20K FPGA board
* Custom PSC_RV32 RISC-V CPU
* External SDRAM
* UART
* SD card
* I2S microphone
* SPI LCD
* PSC-NPU / SynapEngine matrix accelerator

Not all peripherals are required for the basic tests.

For the first test, the Tang Nano 20K and a UART connection are sufficient.

---

## 2. Get the Source Code

Clone the repository:

```bash
git clone https://github.com/QPSC-Design/PSC-ONE.git
cd PSC-ONE
```

The main directory structure is:

```text
PSC-ONE/
├── docs/
├── hardware/
│   ├── rtl/
│   └── sim/
├── software/
│   └── os/
└── README.md
```

The `hardware/rtl` directory contains the FPGA RTL implementation.

The `hardware/sim` directory contains the Verilator/cocotb simulation environment.

The `software/os` directory contains PSC-OS and related software.

---

# 3. Run the CPU Simulation

Before programming the FPGA, the PSC_RV32 CPU can be tested using simulation.

Move to the simulation directory:

```bash
cd hardware/sim
```

Run the RISC-V CPU tests:

```bash
make -f Makefile.riscv.sim simulate_RISCV_TESTS
```

PSC-ONE uses **Verilator** and **cocotb** for RTL simulation.

The tests execute RISC-V programs on the actual SystemVerilog implementation of the PSC_RV32 CPU.

A successful test should finish with a PASS result.

---

# 4. Run PSC-OS in Simulation

PSC-OS can also be booted without using the FPGA board.

From:

```bash
hardware/sim
```

run:

```bash
make -f Makefile.pscos simulate_PSCOS SIM_FAST=1
```

The simulation boots the PSC-ONE SoC and starts PSC-OS.

When PSC-OS has successfully booted, the shell prompt appears:

```text
PSC_OS>
```

For example:

```text
PSC_OS> hello
Hello world from shell!
```

This means that the RISC-V CPU, memory system, boot process, and PSC-OS are running together in the RTL simulation.

---

# 5. PSC-OS Shell

PSC-OS provides a small interactive shell through UART.

Several built-in commands are available.

Examples include:

```text
hello
primes
dump
fat32_info
fat32_ls
speech
micropython
```

For example:

```text
PSC_OS> hello
Hello world from shell!
```

PSC-OS also provides system calls for accessing hardware resources from user programs.

These include:

* UART
* timer
* SD card
* FAT32 filesystem
* I2S microphone
* LCD
* SynapEngine / PSC-NPU

---

# 6. Run PSC-ONE on the FPGA

After confirming the basic operation in simulation, PSC-ONE can be synthesized and programmed onto the **Tang Nano 20K** FPGA board.

## 6.1 Download the RTL Source

Clone or download the PSC-ONE repository:

```bash
git clone https://github.com/QPSC-Design/PSC-ONE.git
cd PSC-ONE
```

The FPGA RTL source files are located under:

```text
hardware/rtl/
```

PSC-ONE is primarily implemented in SystemVerilog.

---

## 6.2 Open the Project in Gowin EDA

Install **Gowin EDA** and open the PSC-ONE FPGA project.

The FPGA design targets the **Tang Nano 20K**, which uses a Gowin FPGA.

The normal FPGA development flow is:

```text
PSC-ONE RTL
     |
     v
Gowin EDA
     |
     v
Synthesis
     |
     v
Place & Route
     |
     v
Bitstream
     |
     v
Tang Nano 20K
```

Run synthesis and place-and-route in Gowin EDA to generate the FPGA bitstream.

---

## 6.3 Connect the Tang Nano 20K

Connect the **Tang Nano 20K** to the PC using a USB cable.

The USB connection is used to program the FPGA.

Make sure the board is detected by the PC before starting the programming process.

---

## 6.4 Program the FPGA

Open the Gowin Programmer from Gowin EDA.

Select the generated bitstream and program the Tang Nano 20K through the USB connection.

The complete hardware flow is therefore:

```text
Download PSC-ONE
       |
       v
Open FPGA project in Gowin EDA
       |
       v
Synthesize RTL
       |
       v
Place & Route
       |
       v
Generate Bitstream
       |
       v
Connect Tang Nano 20K via USB
       |
       v
Program FPGA
```

After programming is complete, the custom **PSC_RV32 RISC-V CPU** and the rest of the PSC-ONE SoC are implemented in the FPGA.

---

## 6.5 Start PSC-OS

Connect to PSC-ONE through UART and open a serial terminal on the PC.

PSC-OS communicates with the host PC through UART.

After PSC-ONE boots successfully, the following prompt should appear:

```text
PSC_OS>
```

Try:

```text
PSC_OS> hello
```

Expected output:

```text
Hello world from shell!
```

At this point, PSC-ONE is running PSC-OS on the custom PSC_RV32 processor implemented entirely inside the FPGA.


---

# 7. Start MicroPython

PSC-OS includes a minimal MicroPython environment.

From the PSC-OS shell:

```text
PSC_OS> micropython
```

The MicroPython REPL will start.

You can then execute normal Python expressions:

```python
>>> 1 + 2
3
```

PSC-ONE also provides the `psc` module for accessing hardware functions.

For example:

```python
>>> import psc
```

The module provides interfaces to PSC-ONE hardware and PSC-OS services.

Examples include:

```python
psc.fat32_ls()
psc.led_on()
psc.led_off()
psc.sa_run(...)
psc.timer_start(...)
psc.timer_stop(...)
```

This allows hardware implemented in the FPGA to be controlled directly from MicroPython.

---

# 8. SynapEngine / PSC-NPU

PSC-ONE contains a matrix-processing accelerator called **SynapEngine**.

SynapEngine can be accessed from PSC-OS and MicroPython.

Conceptually, the software executes:

```text
Application
    |
    v
PSC-OS / MicroPython
    |
    v
PSC-NPU API
    |
    v
SynapEngine
    |
    v
FPGA hardware
```

This makes it possible to compare software matrix operations running on PSC_RV32 with hardware-accelerated operations running on SynapEngine.

---

# 9. Speech Recognition Demo

PSC-ONE can also perform a small speech-recognition demonstration.

The system uses:

```text
I2S Microphone
      |
      v
   PSC-ONE
      |
      v
Feature Extraction
      |
      v
PSC-NPU / SynapEngine
      |
      v
Neural Network
      |
      v
Recognition Result
```

The demonstration performs the entire recognition pipeline using the PSC-ONE FPGA platform.

From PSC-OS, the speech-recognition function can be started with:

```text
PSC_OS> speech
```

The I2S microphone captures audio, PSC-ONE processes the input, and the neural network produces the recognition result.

---

# 10. Where to Go Next

Once the basic system is running, the following areas are good starting points for exploring PSC-ONE:

**CPU**

Study the PSC_RV32 RISC-V CPU implementation in:

```text
hardware/rtl/
```

**Simulation**

Run and modify the Verilator/cocotb tests in:

```text
hardware/sim/
```

**Operating System**

Explore PSC-OS in:

```text
software/os/
```

**MicroPython**

Start the MicroPython REPL from PSC-OS and experiment with the `psc` hardware interface.

**Hardware Acceleration**

Experiment with SynapEngine / PSC-NPU and compare hardware-accelerated matrix operations with software execution.

**Speech Recognition**

Connect an I2S microphone and run the speech-recognition demonstration.

---

# PSC-ONE

PSC-ONE is intended as an experimental platform for exploring the complete stack of a small computer system:

```text
Application
     |
MicroPython / C
     |
   PSC-OS
     |
 Custom RISC-V CPU
     |
FPGA SoC + Hardware Accelerators
     |
    FPGA
```

Because the CPU, operating system, peripherals, and hardware accelerators are developed together, PSC-ONE can be used to experiment with both software and hardware at every level of the system.
