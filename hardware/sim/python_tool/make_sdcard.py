#!/usr/bin/env python3
"""Build and read back a deterministic FAT32 SD image using only Python 3."""

import argparse
from pathlib import Path
import struct
import sys

SECTOR = 512
TOTAL_SECTORS = 64 * 1024 * 1024 // SECTOR
# Aligned to 4 MiB, above PSC_SDCard's inclusive LBA 0x1000 write guard.
PART_LBA = 8192
RESERVED = 32
FATS = 2
EOC = 0x0FFFFFFF
NAMES = (b"KERNEL  MEM", b"USER    MEM")
BUILD_HELP = (
    "Build from hardware/sim with:\n"
    "  make -C ../../software/os MODE=sim kernel_mem ./build/user.mem\n"
    "  make -f Makefile.sdcard INPUT_DIR=../../software/os/build\n"
    "Or use the mem/ copies retained by Makefile.pscos, or specify "
    "KERNEL_MEM=... USER_MEM=... ."
)


def u16(data, offset):
    return struct.unpack_from("<H", data, offset)[0]


def u32(data, offset):
    return struct.unpack_from("<I", data, offset)[0]


def w16(data, offset, value):
    struct.pack_into("<H", data, offset, value)


def w32(data, offset, value):
    struct.pack_into("<I", data, offset, value)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def inputs(kernel, user):
    for path in (kernel, user):
        if not path.is_file():
            raise ValueError(f"Missing input file: {path}\n{BUILD_HELP}")
    return kernel.read_bytes(), user.read_bytes()


def build(image, contents):
    """One MBR partition, 512 bytes/cluster, two FATs, root cluster 2."""
    partition_sectors = TOTAL_SECTORS - PART_LBA
    # F entries * 4 must cover (partition - reserved - 2*F) + 2 clusters.
    fat_sectors = (partition_sectors - RESERVED + 2 + 129) // 130
    clusters = partition_sectors - RESERVED - FATS * fat_sectors
    counts = [(len(data) + SECTOR - 1) // SECTOR for data in contents]
    used = 1 + sum(counts)  # root directory consumes one cluster
    require(used <= clusters, "Inputs exceed the 64 MiB SD image capacity")
    require(all(len(data) <= 0xFFFFFFFF for data in contents), "File exceeds FAT32 size limit")

    mbr = bytearray(SECTOR)
    # CHS is unused for type 0x0c (LBA); use saturated CHS values.
    mbr[446:454] = bytes.fromhex("00 fe ff ff 0c fe ff ff")
    w32(mbr, 454, PART_LBA)
    w32(mbr, 458, partition_sectors)
    mbr[510:512] = b"\x55\xaa"

    boot = bytearray(SECTOR)
    boot[:11] = b"\xeb\x58\x90PSC-ONE "
    w16(boot, 11, SECTOR)
    boot[13] = 1
    w16(boot, 14, RESERVED)
    boot[16] = FATS
    boot[21] = 0xF8
    w16(boot, 24, 63)
    w16(boot, 26, 255)
    w32(boot, 28, PART_LBA)
    w32(boot, 32, partition_sectors)
    w32(boot, 36, fat_sectors)
    w32(boot, 44, 2)
    w16(boot, 48, 1)  # FSInfo
    w16(boot, 50, 6)  # backup boot sector
    boot[64] = 0x80
    boot[66] = 0x29
    w32(boot, 67, 0x50534331)
    boot[71:82] = b"NO NAME    "
    boot[82:90] = b"FAT32   "
    boot[90:94] = b"\xfa\xf4\xeb\xfd"  # non-bootable on a PC
    boot[510:512] = b"\x55\xaa"

    info = bytearray(SECTOR)
    w32(info, 0, 0x41615252)
    w32(info, 484, 0x61417272)
    w32(info, 488, clusters - used)
    w32(info, 492, used + 2 if used < clusters else 0xFFFFFFFF)
    w32(info, 508, 0xAA550000)

    fat = bytearray(fat_sectors * SECTOR)
    for cluster, value in enumerate((0x0FFFFFF8, EOC, EOC)):
        w32(fat, cluster * 4, value)
    directory = bytearray(SECTOR)
    next_cluster = 3
    starts = []
    for index, (name, data, count) in enumerate(zip(NAMES, contents, counts)):
        start = next_cluster if count else 0
        starts.append(start)
        for cluster in range(next_cluster, next_cluster + count):
            w32(fat, cluster * 4,
                EOC if cluster == next_cluster + count - 1 else cluster + 1)
        entry = bytearray(32)
        entry[:11] = name
        entry[11] = 0x20  # archive
        entry[12] = 0x18  # lowercase base and extension, standard 8.3 case flags
        for offset in (16, 18, 24):
            w16(entry, offset, 0x21)  # 1980-01-01, reproducible timestamps
        w16(entry, 20, start >> 16)
        w16(entry, 26, start & 0xFFFF)
        w32(entry, 28, len(data))
        directory[index * 32:(index + 1) * 32] = entry
        next_cluster += count

    image.parent.mkdir(parents=True, exist_ok=True)
    require(not image.is_symlink() and (not image.exists() or image.is_file()),
            "Output must be a regular image file")
    with image.open("wb") as disk:
        disk.truncate(TOTAL_SECTORS * SECTOR)

        def write(lba, data):
            disk.seek(lba * SECTOR)
            disk.write(data)

        write(0, mbr)
        for offset in (0, 6):
            write(PART_LBA + offset, boot)
            write(PART_LBA + offset + 1, info)
        fat_lba = PART_LBA + RESERVED
        for number in range(FATS):
            write(fat_lba + number * fat_sectors, fat)
        data_lba = fat_lba + FATS * fat_sectors
        write(data_lba, directory)
        for start, data in zip(starts, contents):
            if data:
                write(data_lba + start - 2, data)
    print(f"Generated {image}: {TOTAL_SECTORS * SECTOR} bytes, "
          f"partition LBA={PART_LBA}, data LBA={data_lba}, clusters={clusters}")


def read_files(image):
    """Parse on-disk MBR/BPB, directory and FAT chains, independent of layout constants."""
    with image.open("rb") as disk:
        size = image.stat().st_size

        def read(lba, count=1):
            require(lba >= 0 and (lba + count) * SECTOR <= size, "LBA outside image")
            disk.seek(lba * SECTOR)
            data = disk.read(count * SECTOR)
            require(len(data) == count * SECTOR, "Truncated image")
            return data

        mbr = read(0)
        require(mbr[510:] == b"\x55\xaa" and mbr[450] == 0x0C, "Invalid FAT32 MBR")
        part, length = u32(mbr, 454), u32(mbr, 458)
        require(part > 0 and (part + length) * SECTOR == size, "Invalid partition bounds")
        bpb = read(part)
        spc, reserved, fats = bpb[13], u16(bpb, 14), bpb[16]
        fatsz, root = u32(bpb, 36), u32(bpb, 44)
        require(bpb[510:] == b"\x55\xaa" and u16(bpb, 11) == SECTOR,
                "Invalid FAT32 boot sector")
        require(spc in (1, 2, 4, 8, 16, 32, 64, 128) and reserved > 0 and fats == 2
                and fatsz > 0 and u16(bpb, 17) == 0 and u16(bpb, 22) == 0
                and u16(bpb, 42) == 0 and u32(bpb, 32) == length
                and u32(bpb, 28) == part, "Invalid FAT32 geometry")
        data_lba = part + reserved + fats * fatsz
        clusters = (length - reserved - fats * fatsz) // spc
        require(65525 <= clusters < 0x0FFFFFF5 and clusters + 2 <= fatsz * 128,
                "Cluster count does not describe FAT32")
        require(read(part + u16(bpb, 50)) == bpb, "Backup boot sector mismatch")
        info = read(part + u16(bpb, 48))
        require(u32(info, 0) == 0x41615252 and u32(info, 484) == 0x61417272
                and u32(info, 508) == 0xAA550000, "Invalid FSInfo")
        require(read(part + u16(bpb, 50) + u16(bpb, 48)) == info, "Backup FSInfo mismatch")
        fat = read(part + reserved, fatsz)
        require(read(part + reserved + fatsz, fatsz) == fat, "FAT copies differ")
        allocated = set()

        def chain(start):
            cluster = start
            while True:
                require(2 <= cluster < clusters + 2, "Invalid FAT cluster")
                require(cluster not in allocated, "FAT cycle or cross-linked file")
                allocated.add(cluster)
                yield read(data_lba + (cluster - 2) * spc, spc)
                cluster = u32(fat, cluster * 4) & 0x0FFFFFFF
                if cluster >= 0x0FFFFFF8:
                    return

        directory = b"".join(chain(root))
        files = {}
        for offset in range(0, len(directory), 32):
            entry = directory[offset:offset + 32]
            if entry[0] == 0:
                break
            if entry[0] == 0xE5 or entry[11] == 0x0F or entry[11] & 0x18:
                continue
            name = entry[:11]
            require(name not in files, "Duplicate directory entry")
            start = (u16(entry, 20) << 16) | u16(entry, 26)
            length = u32(entry, 28)
            data = b"".join(chain(start)) if start else b""
            require(len(data) == ((length + spc * SECTOR - 1) // (spc * SECTOR)) * spc * SECTOR,
                    "File size and FAT chain length differ")
            files[name] = data[:length]
        return files


def verify(image, contents):
    files = read_files(image)
    require(set(files) == set(NAMES), "Expected kernel.mem and user.mem in root directory")
    for name, expected in zip(NAMES, contents):
        require(files[name] == expected, f"Byte mismatch for {name.decode()}")
        print(f"PASS: {name.decode()} ({len(expected)} bytes), FAT32 readback matches input")


def export_sector(image, lba):
    require(0 <= lba < image.stat().st_size // SECTOR, "LBA outside image")
    with image.open("rb") as disk:
        disk.seek(lba * SECTOR)
        data = disk.read(SECTOR)
    output = image.parent / f"sector_{lba:08x}.hex"
    output.write_text("".join(f"{byte:02x}\n" for byte in data), encoding="ascii")
    print(f"Generated {output}: LBA {lba}, image offset {lba * SECTOR}, 512 byte tokens")
    return output


def export_hex(image):
    """Export a sparse byte-addressed readmemh image; omitted bytes are zero."""
    output = image.with_suffix(".hex")
    require(output.resolve() != image.resolve(), "HEX output must not overwrite image")
    require(not output.is_symlink(), "HEX output must not be a symlink")
    with image.open("rb") as disk, output.open("w", encoding="ascii") as hexfile:
        offset = 0
        while data := disk.read(SECTOR):
            if any(data):
                hexfile.write(f"@{offset:08x}\n")
                hexfile.write(data.hex(" ") + "\n")
            offset += len(data)
    print(f"Generated {output}: sparse byte HEX for $readmemh ({offset} image bytes)")
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("build", "verify", "sector", "hex"):
        sub = subparsers.add_parser(command)
        sub.add_argument("--image", type=Path, required=True)
        if command == "sector":
            sub.add_argument("--lba", type=lambda text: int(text, 0), required=True)
        elif command != "hex":
            sub.add_argument("--kernel", type=Path, required=True)
            sub.add_argument("--user", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.command == "sector":
            export_sector(args.image, args.lba)
        elif args.command == "hex":
            export_hex(args.image)
        else:
            contents = inputs(args.kernel, args.user)
            require(args.image.resolve() not in (args.kernel.resolve(), args.user.resolve()),
                    "Output image must not overwrite an input file")
            if args.command == "build":
                require(args.image.with_suffix(".hex").resolve() not in
                        (args.kernel.resolve(), args.user.resolve()),
                        "HEX output must not overwrite an input file")
                build(args.image, contents)
            verify(args.image, contents)
            if args.command == "build":
                export_hex(args.image)
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
