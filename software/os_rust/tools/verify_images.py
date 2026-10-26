#!/usr/bin/env python3
"""Check linked addresses, unresolved symbols, MEM serialization and the JPEG C ABI."""
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[1]
build = root / "build"
for name, binary, address in (("kernel", "kernel.bin", 0x200000), ("user", "shell.bin", 0x400000)):
    elf = build / f"{name}.elf"
    header = subprocess.check_output(["riscv64-unknown-elf-readelf", "-h", str(elf)], text=True)
    entry = int(re.search(r"Entry point address:\s*(0x[0-9a-fA-F]+)", header)[1], 16)
    assert entry == address, (name, hex(entry))
    assert "ELF32" in header and "RISC-V" in header and "little endian" in header
    undefined = subprocess.check_output(["riscv64-unknown-elf-nm", "-u", str(elf)], text=True)
    assert not undefined.strip(), undefined
    data = (build / binary).read_bytes()
    expected = data + bytes((-len(data)) % 4)
    lines = (build / f"{name}.mem").read_text().splitlines()
    assert all(re.fullmatch(r"[0-9a-f]{8}", line) for line in lines)
    decoded = b"".join(int(line, 16).to_bytes(4, "little") for line in lines)
    assert decoded == expected, f"{name}.mem does not match the binary"
    print(f"PASS {name}: entry={entry:#010x}, {len(lines)} words, no undefined symbols")

symbols = subprocess.check_output(["riscv64-unknown-elf-nm", str(build / "user.elf")], text=True)
for symbol in ("psc_micropython_run", "fat32_read", "call_sd_read_buf_api", "psc_tflite_load", "psc_tflite_invoke", "jd_prepare", "jd_decomp"):
    assert re.search(rf"\b{symbol}$", symbols, re.M), f"missing linked ABI: {symbol}"

# The C side is compiled using the same configuration and target as the linked decoder.
# Rust has matching compile-time size and offset assertions beside its repr(C) type.
source = build / "jpeg_abi_check.c"
source.write_text('''#include <stddef.h>
#include "tjpgd.h"
_Static_assert(sizeof(JDEC) == 132, "JDEC size");
_Static_assert(offsetof(JDEC, device) == 124, "JDEC device");
_Static_assert(offsetof(JDEC, width) == 28, "JDEC width");
_Static_assert(sizeof(JRECT) == 8, "JRECT size");
''')
subprocess.run(["clang", "--target=riscv32-unknown-elf", "-march=rv32im_zicsr_zifencei", "-mabi=ilp32", "-ffreestanding", "--sysroot=/usr/lib/picolibc/riscv64-unknown-elf", "-I" + str(build / "tjpgd"), "-fsyntax-only", str(source)], check=True)
print("PASS MicroPython symbols and TJpgDec C/Rust ABI")

# The independent Rust runtime must fit the same physical reservations as C.
kernel_symbols = subprocess.check_output(["riscv64-unknown-elf-nm", str(build / "kernel.elf")], text=True)
def address(name):
    match = re.search(rf"^([0-9a-fA-F]+) \w {name}$", kernel_symbols, re.M)
    assert match, name
    return int(match[1], 16)
assert address("__arena_start") == 0x40000
assert address("__arena_end") == 0x100000
assert address("__model_low") == 0x140000
assert address("__model_low_end") == 0x200000
assert address("__model_high") == 0x4c0000
assert address("__model_high_end") == 0x800000
assert (build / "shell.bin").stat().st_size <= 0xc0000
# Returning Runtime by value caused >128KiB nested firmware stack frames.
# Only the in-place initialization entry may be reachable from the shell.
assert not re.search(r"7Runtime7prepare$", symbols, re.M), "large FC runtime returned on firmware stack"
assert "prepare_into" in symbols, "missing resident FC initialization"
user_map = (build / "user.map").read_text()
assert not re.search(r"tflite_\w+\.o\b", user_map), "C TFLite object linked into Rust firmware"
print("PASS Rust-only TFLite, in-place FC initialization and model/Arena reservations")
