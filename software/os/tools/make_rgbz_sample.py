#!/usr/bin/env python3
"""Generate headerless 640x360 little-endian RGB565 and Z16 sample files."""
import argparse
from pathlib import Path
from struct import pack_into


def sample(x, y):
    # Optical-axis depth in millimetres, nearest object first.
    if (x - 350) ** 2 + (y - 188) ** 2 <= 68 ** 2:
        return 0xF800, 500
    if 190 <= x < 360 and 75 <= y < 265:
        return 0x07E0, 1000
    if 410 <= x < 530 and 100 <= y < 290:
        return 0xFFE0, 2000
    return (0x001F if (x // 40 + y // 40) % 2 else 0x0015), 4000


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    directory = parser.parse_args().directory
    directory.mkdir(parents=True, exist_ok=True)
    rgb = bytearray(640 * 360 * 2)
    depth = bytearray(len(rgb))
    for y in range(360):
        for x in range(640):
            colour, z = sample(x, y)
            offset = (y * 640 + x) * 2
            pack_into('<H', rgb, offset, colour)
            pack_into('<H', depth, offset, z)
    (directory / 'COLOR.RAW').write_bytes(rgb)
    (directory / 'DEPTH.RAW').write_bytes(depth)


if __name__ == '__main__':
    main()
