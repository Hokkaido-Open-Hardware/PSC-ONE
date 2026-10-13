#!/usr/bin/env python3
"""SD image regression checks; artifacts are retained under sim/build/sdcard-tests/."""

import os
from pathlib import Path
import subprocess
import unittest

import make_sdcard as sd

HERE = Path(__file__).resolve().parent
SIM = HERE.parent
BUILD = SIM / "build/sdcard-tests"


class ImageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        BUILD.mkdir(parents=True, exist_ok=True)

    def test_boundary_bytes_and_empty(self):
        # Preserve NUL, high-bit bytes, CRLF and .mem-like text literally.
        for index, sizes in enumerate(((0, 0), (1, 511), (512, 513), (65537, 70001))):
            pattern = b"12345678\r\n@00001000\n" + bytes(range(256))
            contents = tuple((pattern * (size // len(pattern) + 1))[:size] for size in sizes)
            image = BUILD / f"boundary-{index}.img"
            sd.build(image, contents)
            sd.verify(image, contents)
            self.assertEqual(image.stat().st_size, 64 * 1024 * 1024)

    def test_corruption_detected(self):
        image = BUILD / "corrupt.img"
        contents = (b"1" * 1025, b"2" * 700)
        sd.build(image, contents)
        # Break both copies consistently: readback must detect the chain cycle.
        with image.open("r+b") as disk:
            disk.seek(sd.PART_LBA * 512)
            bpb = disk.read(512)
            fat_lba = sd.PART_LBA + sd.u16(bpb, 14)
            for copy in range(bpb[16]):
                disk.seek((fat_lba + copy * sd.u32(bpb, 36)) * 512 + 3 * 4)
                disk.write((3).to_bytes(4, "little"))
        with self.assertRaisesRegex(ValueError, "cycle"):
            sd.verify(image, contents)

    def test_missing_input_preserves_image(self):
        image = BUILD / "unchanged.img"
        image.write_bytes(b"previous image")
        result = subprocess.run([
            "make", "-f", "Makefile.sdcard", "SDCARD_DIR=" + str(BUILD),
            "IMAGE=" + str(image), "KERNEL_MEM=" + str(BUILD / "missing-kernel.mem"),
            "USER_MEM=" + str(BUILD / "missing-user.mem"),
        ], cwd=SIM, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("kernel_mem ./build/user.mem", result.stderr)
        self.assertEqual(image.read_bytes(), b"previous image")

    def test_sector_mapping(self):
        image = BUILD / "sector.img"
        sd.build(image, (b"kernel", b"user"))
        for lba in (0, sd.PART_LBA, sd.TOTAL_SECTORS - 1):
            output = sd.export_sector(image, lba)
            tokens = output.read_text().split()
            self.assertEqual(len(tokens), 512)
            with image.open("rb") as disk:
                disk.seek(lba * 512)
                self.assertEqual(bytes.fromhex(" ".join(tokens)), disk.read(512))
        with self.assertRaisesRegex(ValueError, "LBA"):
            sd.export_sector(image, sd.TOTAL_SECTORS)

    def test_pscos_reader(self):
        os_src = SIM.parents[1] / "software/os/src"
        exe = BUILD / "sdcard-host-check"
        # common.h hardcodes RV32 size_t/uintptr_t and conflicts with host libc.
        # Replace only that include in a build copy; all FAT32 functions remain
        # unchanged. Only its two console declarations are needed here.
        boot_source = (os_src / "boot/boot_fat32.c").read_text()
        common_include = '#include "../lib/common.h"'
        self.assertEqual(boot_source.count(common_include), 1)
        boot_copy = BUILD / "boot_fat32_host.c"
        boot_copy.write_text(boot_source.replace(common_include,
            'void s_printf(const char *fmt, ...);\nvoid s_print_int(int value);'))
        cc = os.environ.get("CC", "cc")
        flags = ["-std=c11", "-O1", "-g", "-fno-builtin",
                 "-fsanitize=address,undefined", "-fno-omit-frame-pointer", "-fno-pie",
                 "-Wno-int-to-pointer-cast", "-I" + str(os_src),
                 "-I" + str(os_src / "boot")]
        objects = []
        for source in (os_src / "fs/fat32_stream.c", boot_copy, HERE / "sdcard_host_check.c"):
            obj = BUILD / (source.stem + ".o")
            rename = [] if source.name == "sdcard_host_check.c" else [
                "-Dprintf=psc_printf", "-Dputchar=psc_putchar", "-Dexit=psc_exit"]
            subprocess.run([cc, *flags, *rename, "-c", str(source), "-o", str(obj)], check=True)
            objects.append(str(obj))
        subprocess.run([cc, "-fsanitize=address,undefined", "-no-pie", *objects,
                        "-o", str(exe)], check=True)
        kernel, user = BUILD / "kernel.mem", BUILD / "user.mem"
        kernel.write_bytes(b"01234567\r\n" * 10000)
        user.write_bytes(bytes(range(256)) * 301 + b"\x00\xff\n")
        image = BUILD / "pscos.img"
        sd.build(image, sd.inputs(kernel, user))
        subprocess.run([str(exe), str(image), str(kernel), str(user)], check=True)

    def test_whole_card_hex(self):
        image = BUILD / "whole-card.img"
        sd.build(image, (bytes(range(256)) * 3, b"user\r\n" * 99))
        output = sd.export_hex(image)
        restored = bytearray(image.stat().st_size)
        offset = 0
        for token in output.read_text().split():
            if token.startswith("@"):
                offset = int(token[1:], 16)
            else:
                restored[offset] = int(token, 16)
                offset += 1
        self.assertEqual(restored, image.read_bytes())


if __name__ == "__main__":
    unittest.main(verbosity=2)
