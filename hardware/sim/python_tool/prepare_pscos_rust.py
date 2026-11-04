#!/usr/bin/env python3
"""Stage Rust OS images in a private simulation directory without changing sim/mem."""
import argparse
import hashlib
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--os", type=Path, required=True)
parser.add_argument("--build", type=Path, help="Firmware output directory (default: OS/build)")
parser.add_argument("--bootrom", type=Path, required=True)
parser.add_argument("--bootloader", type=Path, required=True, help="FAT32 loader ROM for SD boot")
parser.add_argument("--run", type=Path, required=True)
args = parser.parse_args()
build = args.build if args.build is not None else args.os / "build"

# Validate every input before replacing any staged image. SD image word counts
# must match the linked image sizes; only boot ROMs have RTL capacities.
config = (build / "image_layout.h").read_text()
expected = {}
for name in ("kernel", "user"):
    match = re.search(rf"^#define IMAGE_{name.upper()}_WORDS (\d+)u$", config, re.M)
    if not match:
        raise SystemExit(f"missing IMAGE_{name.upper()}_WORDS in image_layout.h")
    expected[name] = int(match[1])
images = {}
inputs = [
    ("bootrom", args.bootrom, 128),
    ("kernel", build / "kernel.mem", expected["kernel"]),
    ("user", build / "user.mem", expected["user"]),
    ("bootloader_fat32", args.bootloader, 4500),
]
for name, source, limit in inputs:
    raw = source.read_bytes()
    words = raw.split()
    if not 0 < len(words) <= limit:
        raise SystemExit(f"{source}: {len(words)} words exceeds capacity {limit}, or is empty")
    if name in expected and len(words) != expected[name]:
        raise SystemExit(f"{source}: word count does not match the linked image size")
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
