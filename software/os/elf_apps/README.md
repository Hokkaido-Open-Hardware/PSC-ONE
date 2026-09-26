# PSC-OS ELF C++ applications

[PSC-ONE](../../../README.md) · [Documentation](../../../docs/README.md)

```text
elf_apps/
├── Makefile
├── README.md
├── syscall.hpp
├── elf_cpp/
│   ├── hello.cpp
│   ├── arithmetic.cpp
│   └── loop_test.cpp
└── elf_bin/             # Created by make; final executables only
    ├── HELLO.ELF
    ├── ARITH.ELF
    └── LOOPTEST.ELF
```

```sh
cd PSC-ONE/software/os/elf_apps
make                  # All three final SD-card executables
make hello
make arithmetic
make loop_test
make inspect          # readelf ELF headers and program headers
make clean            # Remove only the three generated ELFs in elf_bin/
```

Requires Clang/Clang++ with RISC-V support and LLD, as does the existing OS
build. `make inspect` uses `riscv64-unknown-elf-readelf`; override it with
`make inspect READELF=readelf` if needed. No libc or C++ library is linked.

`elf_cpp/` holds C++ sources; `elf_bin/` is the completed-artifact directory
whose contents can be copied directly to the FAT32 SD card root. The build
creates it automatically and compiles each source directly to its final
uppercase **8.3** name: `hello.cpp` → `HELLO.ELF`, `arithmetic.cpp` →
`ARITH.ELF`, and `loop_test.cpp` → `LOOPTEST.ELF`. No filename aliases or
persistent intermediate objects are produced; compiler temporary files remain
outside `elf_bin/`. Copy all three ELFs to the SD card root, then run:

```text
PSC_OS> run HELLO.ELF
Hello from PSC-ONE ELF C++!
PSC_OS> run ARITH.ELF
21 + 6 = 27
21 - 6 = 15
21 * 6 = 126
PSC_OS> run LOOPTEST.ELF
Loop complete: sum(1..100) = 5050
```

Each command also prints the existing loader diagnostic and `run: exit 0`.
Arithmetic and loop samples return nonzero on an incorrect result. Volatile
operands retain actual integer arithmetic and loop instructions at `-O2`.

## Existing ABI and layout

This directory directly reuses `../tests/elf/start.S` and
`../tests/elf/user.ld`; syscall constants come from `../src/kernel/syscall.h`.
No OS sources or tests need changing. Define `extern "C" int user_main()` in
each application. The existing `_start` calls it and exits with its return
value through `SYS_EXIT`. `syscall.hpp` provides C++ wrappers for `SYS_PUTCHAR`
and `SYS_PRINT_INT`: argument/result in `a0`, syscall number in `a3`, `ecall`.

The compiler target is `--target=riscv64-unknown-elf` with
`-march=rv32im_zicsr_zifencei -mabi=ilp32`, producing **32-bit** RISC-V code,
matching the existing hello test. Flags include `-O2 -ffreestanding -nostdlib
-fno-exceptions -fno-rtti -fno-threadsafe-statics -fno-use-cxa-atexit
-fno-unwind-tables -fno-asynchronous-unwind-tables -fno-pic -fno-pie
-fno-stack-protector -fomit-frame-pointer -mstrict-align
-mno-relax -msmall-data-limit=0`. Linking disables relaxation, strips symbols,
and uses `-z max-page-size=16`, as the existing test does.

`USER_BASE_VAL=0x00400000` matches PSC-ONE's sim/fpga_mem/psc builds. `_start`
is at that address; RX text and RW data/BSS occupy separate 4 KiB virtual
pages. The loader supplies the stack at `0x00500000` and zeroes BSS. The ELF
contains virtual addresses; the kernel chooses backing physical pages.
Override `USER_BASE_VAL` only to match an OS built with a different existing
configuration. After changing compiler/flags/base, use `make -B` to rebuild.

The loader requires little-endian ELF32 RISC-V ET_EXEC with zero ELF flags,
an aligned entry in executable file data, no overlapping PT_LOAD pages, no
dynamic linking/TLS, at most 32 KiB per file and 16 load pages. It reserves
the stack/guard separately. Empty data PT_LOADs are permitted.

This minimal startup does not run global constructors/destructors or provide
GP/TLS, heap allocation, exceptions, RTTI, STL or iostream. Use only constant
global initialization and freestanding code without C++ runtime dependencies.
To add another sample, add its source/ELF prerequisite mapping and target to
the Makefile, following the three examples.

## Verification

The three samples passed the existing `tests/elf/host.c` harness using the real
`elf_loader.c` parser under AddressSanitizer/UndefinedBehaviorSanitizer.
`readelf -h -l` confirms ELF32, little endian, RISC-V ET_EXEC, flags zero,
and entry `0x00400000` for all three:

| Application | File bytes | RX PT_LOAD VA | RW PT_LOAD VA | Load pages |
|---|---:|---|---|---:|
| HELLO.ELF | 632 | 0x00400000 | Empty segment (ignored) | 1 |
| ARITH.ELF | 800 | 0x00400000 | 0x00401000 (.data) | 2 |
| LOOPTEST.ELF | 784 | 0x00400000 | 0x00401000 (.bss) | 2 |

A temporary C++ smoke test based on the existing ELF Verilator/cocotb runner
passed on CPU v1 with the unchanged OS, real SD/FAT32 reads and U-mode/Sv32
execution. It checked all three expected outputs and exit code zero, repeated
LOOPTEST and HELLO runs, shell SATP restoration and the existing shell `hello`
command after execution. This is simulation verification, not a new hardware
test. `make clean` followed by `make -j3` also passed, leaving only final ELF
files in `elf_bin/` with byte-identical contents.
