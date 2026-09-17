#!/usr/bin/env python3
# sdcard_mem_to_img.py
#
# .mem (hex) → SDカード用 raw img 変換
#
# 対応:
#  - 16bit / 32bit hex
#  - 空白区切り / 改行区切り
#  - コメント無視
#  - セクタ(512B)アライン
#

import argparse

SECTOR_SIZE = 512


def parse_mem_file(path):
    data = []

    with open(path, "r") as f:
        for line in f:
            line = line.strip()

            # コメント除去
            if "//" in line:
                line = line.split("//")[0]
            if "#" in line:
                line = line.split("#")[0]

            if not line:
                continue

            # 空白区切りで分割
            tokens = line.split()

            for t in tokens:
                t = t.strip()
                if t:
                    data.append(t)

    return data


def detect_width(hex_list):
    max_len = max(len(x) for x in hex_list)

    if max_len <= 4:
        return 16
    elif max_len <= 8:
        return 32
    else:
        raise ValueError("Unsupported hex width")


def build_binary(hex_list, width):
    out = bytearray()

    if width == 16:
        for h in hex_list:
            val = int(h, 16)
            out += val.to_bytes(2, "little")

    elif width == 32:
        for h in hex_list:
            val = int(h, 16)
            out += val.to_bytes(4, "little")

    else:
        raise ValueError("Invalid width")

    return out


def pad_to_sector(data):
    while len(data) % SECTOR_SIZE != 0:
        data += b'\x00'
    return data


def main():
    parser = argparse.ArgumentParser(description="Convert .mem to SD card img")
    parser.add_argument("input", help=".mem file")
    parser.add_argument("-o", "--output", default="sd.img", help="output img file")
    parser.add_argument("--no-pad", action="store_true", help="disable sector padding")

    args = parser.parse_args()

    hex_list = parse_mem_file(args.input)
    if not hex_list:
        raise RuntimeError("No data found")

    width = detect_width(hex_list)
    print(f"[INFO] detected width: {width} bit")

    data = build_binary(hex_list, width)

    if not args.no_pad:
        data = pad_to_sector(data)

    with open(args.output, "wb") as f:
        f.write(data)

    print(f"[OK] wrote {args.output} ({len(data)} bytes)")


if __name__ == "__main__":
    main()