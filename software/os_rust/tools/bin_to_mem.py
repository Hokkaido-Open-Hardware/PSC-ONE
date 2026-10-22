#!/usr/bin/env python3
"""Emit one little-endian 32-bit word per line for PSC $readmemh images."""
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("source", type=Path)
parser.add_argument("destination", type=Path)
args = parser.parse_args()
data = args.source.read_bytes()
data += bytes((-len(data)) % 4)
with args.destination.open("w", encoding="ascii") as output:
    for offset in range(0, len(data), 4):
        output.write(f"{int.from_bytes(data[offset:offset + 4], 'little'):08x}\n")
