#!/usr/bin/env python3
"""Export image sizes and allocator bounds for validation only, never for the boot ROM."""
import argparse
from pathlib import Path
import re
import subprocess


def symbols(build):
    output = subprocess.check_output(
        ["riscv64-unknown-elf-nm", str(build / "kernel.elf")], text=True
    )
    return {name: int(value, 16) for value, name in
            re.findall(r"^([0-9a-fA-F]+) \w (\S+)$", output, re.M)}


def generate(build):
    sym = symbols(build)
    kernel_size = (build / "kernel.bin").stat().st_size
    user_size = (build / "shell.bin").stat().st_size
    assert user_size == sym["__shell_image_size"]
    start = sym["__free_ram"]
    end = sym["__free_ram_end"]
    assert start % 4096 == 0
    assert start == ((sym["__kernel_stack_top"] + 4095) & ~4095)
    assert start + ((user_size + 4095) & ~4095) + 128 * 1024 + sym.get("__page_table_reserve", 8 * 4096) <= end
    assert sym["__kernel_base"] + kernel_size <= sym["__bss"]
    assert end <= sym["__kernel_limit"]
    assert "__user_image_start" not in sym
    content = (
        "/* Validation/testbench constants only; not a bootloader input. */\n"
        f"#define IMAGE_KERNEL_WORDS {(kernel_size + 3) // 4}u\n"
        f"#define IMAGE_USER_WORDS {(user_size + 3) // 4}u\n"
        f"#define IMAGE_POOL_START 0x{start:08x}u\n"
        f"#define IMAGE_POOL_END 0x{end:08x}u\n"
    )
    path = build / "image_layout.h"
    if not path.exists() or path.read_text() != content:
        path.write_text(content)
    print(f"SD USER.MEM: {user_size} bytes; allocated at runtime in [{start:#010x}, {end:#010x})")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", required=True, type=Path)
    generate(parser.parse_args().build)
