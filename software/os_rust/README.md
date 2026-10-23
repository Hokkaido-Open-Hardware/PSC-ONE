# PSC-OS on Rust

PSC-OS on Rust is a Rust port of PSC-OS for the PSC-ONE RISC-V SoC and
FPGA platform. It provides a bare-metal supervisor kernel and a separate
user-mode command shell, with access to PSC-ONE peripherals through system
calls and memory-mapped hardware interfaces.

The Rust code uses `#![no_std]` and targets `riscv32im-unknown-none-elf`.
Hardware execution requires the PSC-ONE environment; the firmware is not a
desktop application. Selected hardware-independent routines can be tested
on the host.

## Architecture

- **Kernel:** supervisor-mode startup, traps and system calls, physical page
  allocation, Sv32 address translation, and user-process support.
- **User shell:** a separately linked user-mode image with an interactive
  UART console and the `PSC_OS>` prompt.
- **Storage:** SD-card access, FAT32 operations, and ELF application loading.
- **Peripherals and applications:** LCD output, JPEG display, timers, LEDs,
  DMA, microphone and I2C access, robot support, and TensorFlow Lite model
  inspection and execution with CPU and accelerator backends.
- **MicroPython:** an embedded interpreter linked through the existing PSC
  MicroPython C port.

This is a mixed Rust/C firmware build. It reuses the TJpgDec C decoder,
MicroPython, and runtime libraries from the existing [C implementation](../os/).
The simulation flow also builds the existing SBI boot ROM and, for SD boot,
the FAT32 bootloader. These dependencies must be available in the checkout.

The kernel entry address is `0x00200000`; the user image is linked at virtual
address `0x00400000`. The linker scripts define the memory layout, stack
regions, and checks against image overlap.

## Source layout

| Path | Purpose |
| --- | --- |
| `src/bin/` | Kernel and user firmware entry points |
| `src/kernel/` | Kernel services, traps, memory management, and process support |
| `src/boot/` | Boot and FAT32 loading support |
| `src/shell/` | Command shell, ELF commands, and MicroPython integration |
| `src/fs/` | FAT32 filesystem and streaming reads |
| `src/drivers/` | PSC-ONE peripheral drivers |
| `src/api/` | User APIs, signal processing, and inference support |
| `src/elego_robot/` | Robot PWM and IMU support |
| `link/` | Kernel and user linker scripts |
| `assets/` | Boot logo and font data |
| `tests/` | Host-side logic tests and fixtures |
| `tools/` | Image conversion and firmware verification tools |

## Build

Run the following commands from the repository root.

The build requires Rust and Cargo with the `riscv32im-unknown-none-elf` target,
GNU Make, Python 3, ripgrep, Clang, `llvm-objcopy`, and the
`riscv64-unknown-elf` GCC/binutils tools. Use a Rust compiler that supports
`core::arch::naked_asm!` and `#[unsafe(naked)]`.

The current Makefile expects Picolibc under
`/usr/lib/picolibc/riscv64-unknown-elf`, including its `rv32i/ilp32` libraries.
The MicroPython checkout must already contain the PSC port patches; the Rust
Makefile deliberately bypasses the wrapper that applies patches through Git.

```sh
rustup target add riscv32im-unknown-none-elf
make -C PSC-ONE/software/os_rust
```

Cargo builds run in offline mode. Rust artifacts are placed in `target/`,
while firmware images and the local MicroPython build are placed in `build/`
inside this directory.

| Output | Description |
| --- | --- |
| `build/kernel.elf`, `build/user.elf` | Linked firmware with symbols |
| `build/kernel.bin`, `build/shell.bin` | Binary kernel and user images |
| `build/kernel.mem`, `build/user.mem` | Hexadecimal memory images |
| `build/kernel.map`, `build/user.map` | Linker maps |

The default `USER_SOURCE=rtl` expects the user image to be preloaded by the
simulation environment. To build a kernel that reads `USER.MEM` from FAT32
on cold boot, use:

```sh
make -C PSC-ONE/software/os_rust USER_SOURCE=sd
```

## RTL simulation

The Rust simulation wrapper currently supports Verilator. It also requires
the Python/cocotb environment used by the PSC-ONE simulation infrastructure.
Run an interactive simulation with CPU v1 using:

```sh
make -C PSC-ONE/hardware/sim -f Makefile.pscos.rust simulate_PSCOS CPU_VERSION=v1
```

For a bounded boot check that succeeds when the testbench observes `PSC_OS>`:

```sh
make -C PSC-ONE/hardware/sim -f Makefile.pscos.rust smoke CPU_VERSION=v1
```

To exercise the FAT32 SD-card boot path:

```sh
make -C PSC-ONE/hardware/sim -f Makefile.pscos.rust simulate_SD_PSCOS CPU_VERSION=v1
make -C PSC-ONE/hardware/sim -f Makefile.pscos.rust smoke_sd CPU_VERSION=v1
```

These targets select the appropriate `USER_SOURCE` automatically and prepare
the required boot images. Simulation artifacts and UART logs are stored under
`PSC-ONE/hardware/sim/build/pscos-rust/`, with separate directories for direct
and SD boot.

At the shell prompt, enter `help` for the implemented command syntax.
Commands include `hello`, `primes`, `fat32_info`, `fat32_ls`, `run`,
`micropython`, `jpeg`, `tflite_info`, and `tflite_run`. Commands that access
files or peripherals require the corresponding SD contents or hardware/model
configuration. The reserved `self_test` command does not perform validation.

## Validation

Check Rust formatting and run host-side logic tests:

```sh
make -C PSC-ONE/software/os_rust check
```

The tests cover inference reference results, malformed model handling,
integer and signal-processing helpers, FAT32 streaming, JPEG header
validation, and ELF loader checks.

Build and verify the firmware images:

```sh
make -C PSC-ONE/software/os_rust verify
```

Image verification checks ELF entry addresses and format, unresolved symbols,
binary-to-memory-image conversion, required integration symbols, and the
TJpgDec C/Rust ABI layout. Host tests and image checks complement the RTL
boot tests; they do not establish that every peripheral command works on
physical hardware.
