#!/usr/bin/env python3
"""Stage Rust OS images in a private simulation directory without changing sim/mem."""
import argparse
import hashlib
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--os", type=Path, required=True)
parser.add_argument("--bootrom", type=Path, required=True)
parser.add_argument("--bootloader", type=Path, help="FAT32 loader ROM for SD boot")
parser.add_argument("--run", type=Path, required=True)
args = parser.parse_args()

# Validate every input before replacing any staged image. Limits match the
# PSCOS_SIM configuration in PSC_ONE_Boot_axi.v, including the fixed SBI ROM.
images = {}
inputs = [
    ("bootrom", args.bootrom, 128),
    ("kernel", args.os / "build" / "kernel.mem", 200_000),
    ("user", args.os / "build" / "user.mem", 180_000),
]
if args.bootloader:
    inputs.append(("bootloader_fat32", args.bootloader, 4500))
for name, source, limit in inputs:
    raw = source.read_bytes()
    words = raw.split()
    if not 0 < len(words) <= limit:
        raise SystemExit(f"{source}: {len(words)} words exceeds capacity {limit}, or is empty")
    if not all(re.fullmatch(rb"[0-9a-fA-F]{8}", word) for word in words):
        raise SystemExit(f"{source}: expected one 32-bit hexadecimal word per entry")
    images[name] = (raw, words)
    print(f"[Rust image] {name}: {len(words)} words, SHA256={hashlib.sha256(raw).hexdigest()}")

for directory in ("mem", "wave", "log_uart"):
    (args.run / directory).mkdir(parents=True, exist_ok=True)
for name, (raw, words) in images.items():
    if name == "bootrom":
        raw = b"\n".join(words + [b"00000000"] * (128 - len(words))) + b"\n"
    (args.run / "mem" / f"{name}.mem").write_bytes(raw)

# The RTL instantiates this ROM even in direct boot, but never executes it.
# Supply deterministic zeros so the unused instance does not emit a missing-file warning.
if not args.bootloader:
    (args.run / "mem" / "bootloader_fat32.mem").write_bytes(b"00000000\n" * 4500)
