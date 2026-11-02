#!/usr/bin/env python3
"""Check linked addresses, unresolved symbols, MEM serialization and the JPEG C ABI."""
import argparse
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--build", type=Path, default=root / "build")
parser.add_argument("--board", choices=["psc_one", "psc_one_rv64"], default="psc_one")
parser.add_argument("--micropython", choices=["0", "1"], default="0")
args = parser.parse_args()
build = args.build
rv64 = args.board == "psc_one_rv64"
xlen = 64 if rv64 else 32
user_base = 0x1000000 if rv64 else 0x400000
kernel_limit = 0x4c0000 if rv64 else 0x400000
page_table_reserve = (16 if rv64 else 8) * 4096
for name, binary, address in (
    ("bootrom", "bootrom.bin", 0),
    ("bootloader_fat32", "bootloader_fat32.bin", 0x100000),
    ("kernel", "kernel.bin", 0x200000),
    ("user", "shell.bin", user_base),
):
    elf = build / f"{name}.elf"
    header = subprocess.check_output(["riscv64-unknown-elf-readelf", "-h", str(elf)], text=True)
    entry = int(re.search(r"Entry point address:\s*(0x[0-9a-fA-F]+)", header)[1], 16)
    assert entry == address, (name, hex(entry))
    assert f"ELF{xlen}" in header and "RISC-V" in header and "little endian" in header
    undefined = subprocess.check_output(["riscv64-unknown-elf-nm", "-u", str(elf)], text=True)
    assert not undefined.strip(), undefined
    data = (build / binary).read_bytes()
    expected = data + bytes((-len(data)) % 4)
    lines = (build / f"{name}.mem").read_text().splitlines()
    assert all(re.fullmatch(r"[0-9a-f]{8}", line) for line in lines)
    decoded = b"".join(int(line, 16).to_bytes(4, "little") for line in lines)
    assert decoded == expected, f"{name}.mem does not match the binary"
    print(f"PASS {name}: entry={entry:#010x}, {len(lines)} words, no undefined symbols")

loader = (build / "bootloader_fat32.bin").read_bytes()
assert len(loader) <= 4500 * 4
assert (build / "bootrom.bin").stat().st_size <= 128 * 4
assert b"USER.MEM deferred to kernel" in loader, "use the standard C OS FAT32 kernel loader"
assert b"USER.MEM loaded addr=" not in loader, "fixed USER.MEM loader is obsolete"

symbols = subprocess.check_output(["riscv64-unknown-elf-nm", str(build / "user.elf")], text=True)
mp_symbols = ("psc_micropython_run", "fat32_read", "call_sd_read_buf_api",
              "psc_tflite_load", "psc_tflite_invoke")
for symbol in mp_symbols:
    linked = bool(re.search(rf"\b{symbol}$", symbols, re.M))
    assert linked == (args.micropython == "1"), f"unexpected MicroPython linkage: {symbol}"
for symbol in ("jd_prepare", "jd_decomp"):
    assert re.search(rf"\b{symbol}$", symbols, re.M), f"missing linked ABI: {symbol}"
# These native Rust paths remain required with the MicroPython C ABI disabled.
for pattern in (r"tflite_runtime.*prepare_into", r"tflite_graph.*invoke_callbacks"):
    assert re.search(pattern, symbols), f"missing native inference path: {pattern}"

# The C side is compiled using the same configuration and target as the linked decoder.
# Rust has matching compile-time size and offset assertions beside its repr(C) type.
source = build / "jpeg_abi_check.c"
source.write_text(f'''#include <stddef.h>
#include "tjpgd.h"
_Static_assert(sizeof(JDEC) == {240 if rv64 else 132}, "JDEC size");
_Static_assert(offsetof(JDEC, device) == {224 if rv64 else 124}, "JDEC device");
_Static_assert(offsetof(JDEC, width) == {40 if rv64 else 28}, "JDEC width");
_Static_assert(sizeof(JRECT) == 8, "JRECT size");
''')
subprocess.run(["clang", f"--target=riscv{xlen}-unknown-elf", f"-march=rv{xlen}im_zicsr_zifencei", "-mabi=lp64" if rv64 else "-mabi=ilp32", "-ffreestanding", "--sysroot=/usr/lib/picolibc/riscv64-unknown-elf", "-I" + str(build / "tjpgd"), "-fsyntax-only", str(source)], check=True)
print(f"PASS MicroPython enabled={args.micropython} linkage and TJpgDec C/Rust ABI")

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
size = (build / "shell.bin").stat().st_size
start = address("__free_ram")
end = address("__free_ram_end")
assert start == ((address("__kernel_stack_top") + 4095) & ~4095)
assert address("__bss_end") <= address("__kernel_stack_top") <= start < end <= kernel_limit
assert end - start >= ((size + 4095) & ~4095) + 128 * 1024 + page_table_reserve
assert "_binary_shell_bin_start" not in kernel_symbols
assert "__user_image_start" not in kernel_symbols
assert "BootSd" in kernel_symbols, "kernel must read USER.MEM from SD"
assert "kernel_warm_boot" in kernel_symbols
from boot_config import generate
generate(build)
print("PASS SD loader/warm restart symbols and contiguous page-pool budget (static checks)")
# Returning Runtime by value caused >128KiB nested firmware stack frames.
# Only the in-place initialization entry may be reachable from the shell.
assert not re.search(r"7Runtime7prepare$", symbols, re.M), "large FC runtime returned on firmware stack"
assert "prepare_into" in symbols, "missing resident FC initialization"
user_map = (build / "user.map").read_text()
assert not re.search(r"tflite_\w+\.o\b", user_map), "C TFLite object linked into Rust firmware"
print("PASS Rust-only TFLite, in-place FC initialization and model/Arena reservations")
