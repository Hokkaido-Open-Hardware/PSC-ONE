# PSC-OS on Rust

PSC-OS on Rust is a Rust port of PSC-OS for the PSC-ONE RISC-V SoC and
FPGA platform. It provides a bare-metal supervisor kernel and a separate
user-mode command shell, with access to PSC-ONE peripherals through system
calls and memory-mapped hardware interfaces.

The Rust code uses `#![no_std]` and targets `riscv32im-unknown-none-elf`
or `riscv64im-unknown-none-elf` (RV64IM / LP64 / Sv39).
Hardware execution requires the PSC-ONE environment; the firmware is not a
desktop application. Selected hardware-independent routines can be tested
on the host.

## Architecture

- **Kernel:** supervisor-mode startup, traps and system calls, physical page
  allocation, Sv32 (RV32) or Sv39 (RV64) address translation, and user-process support.
- **User shell:** a separately linked user-mode image with an interactive
  UART console and the `PSC_OS>` prompt.
- **Storage:** SD-card access, FAT32 operations, and ELF application loading.
- **Peripherals and applications:** LCD output, JPEG display, timers, LEDs,
  DMA, microphone and I2C access, robot support, and TensorFlow Lite model
  inspection and execution with CPU and accelerator backends.
- **MicroPython:** disabled by default for both RV32 and RV64, matching the
  C shell's `PSC_OS_DEBUG_WITHOUT_MICROPYTHON` configuration. The optional
  interpreter code remains available through `MICROPYTHON=1`.

This is a mixed Rust/C firmware build. It reuses the TJpgDec C decoder,
runtime libraries, and optionally MicroPython from the existing [C implementation](../os/).
TFLite parsing, verification, quantization, CPU kernels and accelerator dispatch
are implemented independently in Rust; no C/C++ TFLite runtime is linked.
The RV32 build reuses the existing C SBI boot ROM and FAT32 bootloader.
RV64 builds a separate Rust MBIOS and Rust FAT32 bootloader with LP64 register
saves. The TJpgDec and Picolibc sources/libraries must be available in the checkout.

The kernel entry address is `0x00200000`; the user image is linked at virtual
address `0x00400000` on RV32 or `0x01000000` on RV64. The linker scripts define the memory layout, stack
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
| `src/board/psc_one/` | RV32 MMIO, memory layout, linker scripts and build flags |
| `src/board/psc_one_rv64/` | RV64 build/link settings, Sv39, LP64 traps/context, ELF64 and MBIOS |
| `link/` | Compatibility wrappers for the board linker scripts |
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
MicroPython is not built or linked by default. If enabled, its checkout must
already contain the PSC port patches; the Rust Makefile deliberately bypasses
the wrapper that applies patches through Git.

```sh
rustup target add riscv32im-unknown-none-elf
make -C PSC-ONE/software/os_rust
```

Cargo builds run in offline mode. Rust artifacts are placed in `target/`,
while firmware images and the local MicroPython build are placed in `build/`
inside this directory.

| Output | Description |
| --- | --- |
| `build/bootrom.mem`, `build/bootloader_fat32.mem` | Matching FPGA boot ROMs |
| `build/kernel.elf`, `build/user.elf` | Linked firmware with symbols |
| `build/kernel.bin`, `build/shell.bin` | Binary kernel and user images |
| `build/kernel.mem`, `build/user.mem` | Hexadecimal memory images |
| `build/kernel.map`, `build/user.map` | Linker maps |

`BOARD=psc_one` is the supported RV32 profile. MMIO bases and the user ABI
are defined in `src/board/psc_one/config.rs`; `memory.ld`, `kernel.ld`, and
`user.ld` own the linked layout, and `board.mk` owns the toolchain flags.
`CPU_VERSION=rv64` selects `BOARD=psc_one_rv64` automatically; an explicit
`BOARD=psc_one_rv64` also selects RV64. Unknown boards are rejected.

### RV64 / Sv39 support (2026-11-03)

```sh
# One-time toolchain setup. RV64IM core/compiler_builtins are built from source.
rustup toolchain install nightly-2026-09-04 --component rust-src
# Build and statically verify all four RV64 images (MicroPython disabled).
make -C PSC-ONE/software/os_rust verify CPU_VERSION=rv64
# Equivalent explicit board selection:
make -C PSC-ONE/software/os_rust verify BOARD=psc_one_rv64
# Optional library-only type check/build:
make -C PSC-ONE/software/os_rust check-target CPU_VERSION=rv64
make -C PSC-ONE/software/os_rust lib CPU_VERSION=rv64
```

`board.mk` selects `riscv64im-unknown-none-elf`, `+zicsr,+zifencei`, static
relocation, the medium code model, and C `-march=rv64im_zicsr_zifencei -mabi=lp64`.
Cargo uses `-Z build-std=core,compiler_builtins`; the IMAC prebuilt library is not
used because it may contain unsupported atomic/compressed instructions.
`RUST_TOOLCHAIN` can override the pinned nightly. Cargo builds remain offline.

Sv39 uses three levels of 512 64-bit PTEs, 4 KiB pages, `satp.MODE=8`, and
`sfence.vma` on address-space changes. Page construction sets accessed/dirty
bits; user-buffer checks walk all three levels and require user permissions.
Noncanonical addresses, reserved PTE encodings and misaligned superpages are
rejected by the walker. Kernel/MMIO pages remain supervisor-only and the user
stack guard remains unmapped. Model and arena mappings use separate user leaves.
Trap frames, machine contexts and cooperative register saves use 64-bit slots.
The foreground loader accepts bounded ELF64/RISC-V soft-float executables and
rejects ELF32. The existing PSC syscall device values and user buffers remain
within the board's low 32-bit address range; this is not an unrestricted 64-bit
userspace address allocation API.

| Setting | RV32 | RV64 |
| --- | --- | --- |
| Kernel entry (physical) | `0x00200000` | `0x00200000` |
| Kernel/page-pool upper bound | `0x00400000` | `0x004c0000` |
| Shell entry (virtual) | `0x00400000` | `0x01000000` |
| User stack top (virtual) | `0x00500000` | `0x01100000` |
| Model / arena user VA | `0x00800000` / `0x00c00000` | Same |
| Output directory | `os_rust/build/` | `os_rust/build/psc_one_rv64/` |

RV64 moves the shell VA outside the extended kernel identity range, leaving
space for its larger LP64 images and page tables (including optional MicroPython).
The physical 4 MiB model and 768 KiB arena reservations remain unchanged; the
higher user VA does not require additional physical SDRAM. RV32 keeps its
existing memory map and Sv32 implementation. The default behavior change common
to both builds is that MicroPython is disabled; its command reports that state.

For RV64 hardware, use **all four files from `build/psc_one_rv64/`**:
`bootrom.mem` and `bootloader_fat32.mem` for the RV64 FPGA boot images, and
`kernel.mem` / `user.mem` as `KERNEL.MEM` / `USER.MEM` on the FAT32 SD card.
The RV32 ROM/loader and RV32 ELF applications must not be mixed into this set.
No FPGA files are installed by this Makefile. Kernel and shell images are read
from SD in the same order as RV32.

Verification here means compilation/linking, ELF/MEM/layout/C-ABI checks and
host tests for Sv39/ELF64. **RV64 hardware boot, interrupts, restart and peripheral
operation remain unverified. No Rust OS RTL simulation was run for this change**,
as requested; hardware operation is to be checked separately.

### MicroPython selection

`MICROPYTHON=0` is the default for **both** architectures. It excludes the Rust
VM entry/callback module, MicroPython archive and its printf object from the
firmware build. Sources remain available behind the `micropython` Cargo feature.
The configuration stamp tracks the selection so switching modes rebuilds images.
To explicitly re-enable it, pass `MICROPYTHON=1` to make. RV64 then uses the
upstream RV64 GC/NLR helpers, LP64 C libraries and MPZ integers. Normal builds
do not require a MicroPython compilation.

The boot flow is the same as the C PSC-OS SD configuration:

1. The RV32 C loader or RV64 Rust loader loads `KERNEL.MEM` from FAT32.
2. The kernel calls `create_process_from_sd()`, reads `USER.MEM` from SD into
   newly allocated contiguous process pages, and maps them at the board's user VA.
3. A warm restart restores kernel data, clears BSS, resets the allocator and
   reads `USER.MEM` from SD again.

There is no fixed physical USER.MEM staging address or preloaded-image contract.
`USER.MEM deferred to kernel` is the expected bootloader message. The kernel then
prints `KERNEL: reading USER.MEM from SD into process pages` and confirms the load.

The normal `make` / `make verify` generates all four MEM files under the selected
board output directory shown above.
For physical FPGA use, copy `kernel.mem` and `user.mem` to the FAT32 SD card.
For RV32, the standard C OS `bootrom.mem` and `bootloader_fat32.mem` are reused unchanged;
no Rust-specific user address or image size is compiled into the ROM.
`build/image_layout.h` contains sizes/allocator bounds only for staging checks
and the native testbench. It is not an input to the bootloader.

## RTL simulation

The RV32 Rust simulation wrapper supports Verilator and always boots from SD.
The RV64 addition described above does not enable this wrapper for RV64.
It requires the Python/cocotb environment used by PSC-ONE.

```sh
# Prepare matching Rust firmware, C BIOS/loader, and the FAT32 card.
make -C PSC-ONE/hardware/sim -f Makefile.pscos.rust prepare_rust CPU_VERSION=v1
# Interactive SD boot (also the default target).
make -C PSC-ONE/hardware/sim -f Makefile.pscos.rust simulate_SD_PSCOS CPU_VERSION=v1
# Bounded boot check; succeeds only after observing PSC_OS>.
make -C PSC-ONE/hardware/sim -f Makefile.pscos.rust smoke_sd CPU_VERSION=v1
```

The direct-load targets `simulate_PSCOS`, `simulate_PSCOS_RUST`, and `smoke`
have been removed. `RUST_BOOT=rtl` and `USER_SOURCE=rtl` are rejected.
Artifacts and UART logs live under
`PSC-ONE/hardware/sim/build/pscos-rust/sd_<CPU>_<NPU>_<SIM_FAST>/`.

At the shell prompt, enter `help` for the implemented command syntax.
Commands include `hello`, `primes`, `fat32_info`, `fat32_ls`, `run`,
`jpeg`, `tflite_info`, and `tflite_run`; `micropython` reports disabled unless
explicitly enabled at build time. Commands that access
files or peripherals require the corresponding SD contents or hardware/model
configuration. The reserved `self_test` command does not perform validation.

## Validation

Check Rust formatting and run host-side logic tests:

```sh
make -C PSC-ONE/software/os_rust check
```

The tests cover inference reference results, malformed model handling,
integer and signal-processing helpers, FAT32 streaming, JPEG header
validation, Sv39 translation/permissions/boundaries, and ELF32/ELF64 loader checks.

Build and verify the firmware images:

```sh
make -C PSC-ONE/software/os_rust verify
```

For the native Verilator boot/restart check using the same compiled SD-mode RTL:

```sh
python3 -B PSC-ONE/software/os_rust/tests/boot.py \
  --run PSC-ONE/hardware/sim/build/pscos-rust/sd_v1_legacy_1 \
  --build build/rust-sd-boot-check
```

This verifies the C bootloader/kernel division, SD loading into contiguous
process pages, unmapped stack guards, `hello`, and SD USER.MEM reload on warm
restart before another successful `hello`.

Image verification checks ELF entry addresses and format, unresolved symbols,
binary-to-memory-image conversion, required integration symbols, and the
TJpgDec C/Rust ABI layout. Host tests and image checks complement the RTL
boot tests; they do not establish that every peripheral command works on
physical hardware.

## TFLite compatibility with the C OS

The shell accepts the same four commands and backends:

```text
tflite_info MODEL.TFL
tflite_run MODEL.TFL [cpu|npu|pulp|auto]
tflite_diag [on|off]
tflite_bench MODEL.TFL [quick]
```

Missing or invalid arguments print usage. Files must use root-directory,
uppercase 8.3 names. `tflite_info` analyzes a structurally valid model even
when execution is unsupported or the Arena is too small. It invalidates any
previous resident model, just like load/reset. Diagnostics default to on.

Model capacity is 4 MiB. The model is mapped at VA `0x00800000`, separately
from the shell and stack. Mixed graphs have a 768 KiB Arena at VA `0x00c00000`;
the existing FC-only profile retains its separate 4 KiB Arena. The kernel uses
the same split physical model backing as C, preserving the bootloader,
the 4 MiB model and 768 KiB Arena reservations. USER.MEM now resides in the
kernel page pool; restart reloads it from SD. Linker/image checks enforce
non-overlap with BSS and kernel stack, plus sufficient space for the user image,
user stack and page tables.

The independent Rust graph implementation supports the current 16 operators:
CONV_2D, FULLY_CONNECTED, ADD, SUB, MUL, LOGISTIC, MAX_POOL_2D, TRANSPOSE, PAD,
SLICE, CONCATENATION, RESIZE_NEAREST_NEIGHBOR, RESHAPE, SOFTMAX, QUANTIZE and
DEQUANTIZE. Analysis is bounded to 1024 tensors/operators/buffers; execution
supports 512 operators, one input/output, static shapes and up to rank 4.
INT8, FLOAT32 and INT32 are supported under the same per-operator conditions
as the C runtime. Unsupported shapes/types/options are rejected explicitly.
Out-of-line constants are bounds checked within the same model file.

INT8 results use the double-rounding reference contract, including integer
Logistic/Softmax. CPU is the default. NPU uses bounded im2col tiles for Conv/FC;
started device failures invalidate output without CPU retry. PULP uses signed
`cv.dotsp.b` only when built with `CPU_VERSION=v1`; other builds fall back to
CPU. AUTO keeps the measured square FC NPU selection and otherwise chooses
PULP where enabled. Operator records report the backend actually used.
Rust currently recompiles validated operator descriptors during invocation
from immutable model bytes, saving resident descriptor storage; wall time
includes this work, while operator timings cover execution only.

The shell's demo inputs are repeated INT8 values or zero FLOAT32/INT32 values,
not image preprocessing. Graph diagnostics include tensor hashes before Arena
reuse. The graph benchmark compares every output byte using the same bounded 4 KiB
reference buffer as C, across three warm samples (five configurations in quick
mode). Larger outputs are rejected explicitly by the benchmark; inference
retains the 768 KiB Arena limit.

FC firmware initialization occurs in its resident workspace. Returning the
large runtime by value previously exhausted the 128 KiB user stack. The host
convenience constructor remains available; image verification rejects its
presence in firmware.

### Independent reference checks

The first suite requires a host C++ compiler but no Python ML packages. It
exports inputs/outputs from the pinned upstream reference kernels and compares
the separate Rust executable in CPU/PULP/NPU-mock/AUTO modes. The C++ exporter
is test-only and is never linked into firmware.

```sh
python3 PSC-ONE/software/os_rust/tests/tflite/reference.py --build build/rust-tflite-reference
```

For the additional 111 transform/negative/integration fixtures, use Python with
`ai-edge-litert==2.3.0`, NumPy and FlatBuffers:

```sh
cargo build --offline --release --features pulp --manifest-path PSC-ONE/software/os_rust/Cargo.toml --example graph_reference
python PSC-ONE/software/os/tests/tflite/phase2_ops.py --build build/rust-tflite-phase2 --runtime "$PWD/PSC-ONE/software/os_rust/target/release/examples/graph_reference"
```

`examples/graph_reference.rs` also checks a model against a directory containing
`tensor-<id>.bin` for every operator output. Supply model, output file, input
file, and reference directory as positional arguments; `PSC_RUST_BACKEND`
selects `cpu`, `pulp`, `npu` or `auto`. Host NPU calls perform mock matrix
multiplication and do not establish hardware timing.

The checked-in Rust schema descriptors are regenerated with
`tools/generate_tflite_schema.py` from the pinned schema declaration. Normal
Rust builds do not read, compile or link that C++ header.

## YOLO JPEG detection (C OS parity)

```text
yolo_backend cpu
yolo YOLO.TFL TEST.JPG
yolo_backend npu
yolo YOLO.TFL TEST2.JPG
yolo_diag on
```

`yolo_backend [cpu|pulp|npu|auto]` selects/shows a persistent preference;
CPU is the boot default. It is reapplied after each model load and is independent
of `tflite_run`. `yolo_diag on|off` controls tensor hashes and operator diagnostics
independently of `tflite_diag`, and defaults to off. The command accepts two
uppercase root-directory 8.3 filenames, matching the C shell.

This is the same fixed normalized-xywh COCO80 profile as
[`os/src/api/yolo/`](../os/src/api/yolo/README.md): FLOAT32 `[1,3,160,160]` input,
FLOAT32 `[1,84,525]` output, and 289 operators. Shape checks do not establish
compatibility with an arbitrary model using different output semantics.
Baseline JPEG limits remain 480x320. RGB decoding streams into a 17-row buffer;
centered letterbox, rational ties-to-even dimensions, half-pixel bilinear pixel
rounding, RGB/255 CHW layout, score > 0.25, class-wise IoU > 0.45 NMS, stable ties,
original-image clipping and the 50-detection limit match C.

The shell clears the previous LCD result first. JPEG preflight precedes model
loading; full decode and EOI must succeed before inference. Inference failure
clears saved detections and resets runtime output. Started NPU failures abort
without CPU retry. After successful inference, the JPEG is decoded again and
bounded RGB888 tiles draw yellow boxes and white labels. A display error keeps
the inference results. The `yolo_command::run` entry performs inference without
LCD access; the shell wrapper adds display. No full-frame buffer is allocated.

UART reports requested and actual backend counts, fallback reasons, successful
NPU tile calls, input/output hashes, stage timing and optional per-operator
traces. Operator time sums describe completed work only; they are not a
CPU-only model baseline. Host PULP/NPU tests use emulation/mocks, not hardware.

FC execution and generic-graph/YOLO work share a resident allocation, and JPEG
preprocessing shares storage with NMS. Only the active member is accessed under
the existing synchronous runtime lock. Stage changes initialize storage in
place to avoid large stack temporaries. The model/Arena addresses, 128 KiB user
stack, page-pool bounds and linker assertions remain unchanged.

Additional verification (from repository root):

```sh
# Requires the existing Python environment with NumPy, Pillow, OpenCV and LiteRT.
python -B PSC-ONE/software/os/tests/yolo/run.py --build build/yolo-c-reference --mixed
python -B PSC-ONE/software/os_rust/tests/yolo/run.py --build build/yolo-rust-reference --c-reference build/yolo-c-reference
python3 PSC-ONE/software/os_rust/tests/yolo/memory.py --build PSC-ONE/software/os_rust/build
```

The comparison checks 36 streaming input cases, NMS boundaries, exact LCD pixels,
and both SD JPEGs across four backends against all 289 reference tensors. The
`jpeg-host` feature exposes the same decoder callbacks for this test; its runner
links only the existing TJpgDec C decoder. It does not link C YOLO/TFLite code.
`tests/yolo/uart.py --help` describes the separate bounded RTL smoke for command
syntax, model-profile rejection, FC/graph storage transitions and warm restart.
It does not attempt full YOLO inference on RTL.
