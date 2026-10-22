//! boot/boot_fat32.c/.h: root-directory boot file and ASCII .mem loading.
use crate::fs::fat32::{le16, le32, BlockDevice};
pub struct BootFat32 {
    pub part_lba: u32,
    pub fat_begin: u32,
    pub data_begin: u32,
    pub root_cluster: u32,
    pub sectors_per_cluster: u32,
}

/// Recognize the basic FAT32 boot-sector geometry and signature.
fn valid_bpb(b: &[u8; 512]) -> bool {
    le16(b, 510) == 0xaa55
        && le16(b, 11) == 512
        && b[13] != 0
        && le16(b, 14) != 0
        && b[16] != 0
        && le32(b, 36) != 0
        && le32(b, 44) >= 2
}
impl BootFat32 {
    /// Accept a FAT32 super-floppy or follow the first MBR partition to its BPB.
    pub fn mount(dev: &mut impl BlockDevice) -> Result<Self, i32> {
        let mut b = [0; 512];
        dev.read(0, &mut b)?;
        // Both partitioned cards and super-floppy FAT32 images are supported.
        let part = if valid_bpb(&b) {
            0
        } else {
            if le16(&b, 510) != 0xaa55 {
                return Err(-1);
            }
            let part = le32(&b, 0x1c6);
            if part == 0 {
                return Err(-1);
            }
            dev.read(part, &mut b)?;
            part
        };
        if !valid_bpb(&b) || b[16] > 4 {
            return Err(-1);
        }
        let fat = part.wrapping_add(le16(&b, 14));
        Ok(Self {
            part_lba: part,
            fat_begin: fat,
            data_begin: fat.wrapping_add(b[16] as u32 * le32(&b, 36)),
            root_cluster: le32(&b, 44),
            sectors_per_cluster: b[13] as u32,
        })
    }

    /// Convert a data cluster to its first sector while retaining wrapping address arithmetic.
    pub fn cluster_to_lba(&self, c: u32) -> u32 {
        self.data_begin
            .wrapping_add(c.saturating_sub(2).wrapping_mul(self.sectors_per_cluster))
    }

    /// Fetch the next 28-bit FAT link and propagate media errors.
    pub fn next_cluster(&self, dev: &mut impl BlockDevice, c: u32) -> Result<u32, i32> {
        if c < 2 {
            return Ok(0x0ffffff8);
        }
        let mut b = [0; 512];
        dev.read(self.fat_begin + c / 128, &mut b)?;
        Ok(le32(&b, (c % 128) as usize * 4) & 0x0fffffff)
    }

    /// Search root-directory chains case-insensitively using the boot short-name convention.
    pub fn find(&self, dev: &mut impl BlockDevice, name: &str) -> Result<(u32, u32), i32> {
        let bytes = name.as_bytes();
        let mut wanted = [b' '; 11];
        let (mut i, mut j) = (0, 0);
        while i < bytes.len() && bytes[i] != b'.' && j < 8 {
            wanted[j] = bytes[i].to_ascii_uppercase();
            i += 1;
            j += 1;
        }
        if bytes.get(i) == Some(&b'.') {
            i += 1;
        }
        j = 8;
        while i < bytes.len() && j < 11 {
            wanted[j] = bytes[i].to_ascii_uppercase();
            i += 1;
            j += 1;
        }
        let mut c = self.root_cluster;
        let mut b = [0; 512];
        while c >= 2 && c < 0x0ffffff8 && c != 0x0ffffff7 {
            for s in 0..self.sectors_per_cluster {
                dev.read(self.cluster_to_lba(c) + s, &mut b)?;
                for e in b.chunks_exact(32) {
                    if e[0] == 0 {
                        return Err(-1);
                    }
                    if e[0] == 0xe5 || e[11] == 0xf || e[11] & 0x18 != 0 {
                        continue;
                    }
                    if e[..11] == wanted {
                        return Ok(((le16(e, 20) << 16) | le16(e, 26), le32(e, 28)));
                    }
                }
            }
            c = self.next_cluster(dev, c)?;
        }
        Err(-1)
    }

    /// Deliver exactly the declared file bytes, rejecting a premature or bad cluster link.
    fn stream(
        &self,
        dev: &mut impl BlockDevice,
        name: &str,
        mut consume: impl FnMut(&[u8]) -> Result<(), i32>,
    ) -> Result<u32, i32> {
        let (mut c, size) = self.find(dev, name)?;
        let mut remaining = size;
        let mut b = [0; 512];
        // Match the bootloader's progress format for the kernel's user-image load.
        // Count ASCII file bytes, including whitespace, rather than decoded RAM bytes.
        let report_progress =
            cfg!(target_arch = "riscv32") && name.eq_ignore_ascii_case("USER.MEM");
        if report_progress {
            crate::s_print!("FAT32: loading USER.MEM size={}\n", size);
        }
        while remaining != 0 {
            if c < 2 || c >= 0x0ffffff8 || c == 0x0ffffff7 {
                return Err(-1);
            }
            for s in 0..self.sectors_per_cluster {
                if remaining == 0 {
                    break;
                }
                dev.read(self.cluster_to_lba(c) + s, &mut b)?;
                let n = remaining.min(512);
                consume(&b[..n as usize])?;
                remaining -= n;
                // Report only successfully consumed sectors, every 16 KiB and at EOF.
                let read_bytes = size - remaining;
                if report_progress && (read_bytes % 16384 == 0 || remaining == 0) {
                    crate::s_print!("FAT32: USER.MEM read={}/{} bytes\n", read_bytes, size);
                }
            }
            if remaining != 0 {
                c = self.next_cluster(dev, c)?;
            }
        }
        Ok(size)
    }

    /// Copy binary file chunks into a caller-bounded destination buffer.
    pub fn load_file(
        &self,
        dev: &mut impl BlockDevice,
        name: &str,
        dst: &mut [u8],
    ) -> Result<usize, i32> {
        let mut offset = 0;
        self.stream(dev, name, |b| {
            if b.len() > dst.len() - offset {
                return Err(-1);
            }
            dst[offset..offset + b.len()].copy_from_slice(b);
            offset += b.len();
            Ok(())
        })?;
        Ok(offset)
    }

    /// The sink receives temporary, aligned chunks; it must copy before returning.
    /// Decode eight hexadecimal digits per word and deliver bounded temporary word chunks.
    pub fn stream_mem_file(
        &self,
        dev: &mut impl BlockDevice,
        name: &str,
        max_words: u32,
        mut sink: impl FnMut(u32, &[u32]) -> Result<(), i32>,
    ) -> Result<u32, i32> {
        if max_words > 0x3fffffff {
            return Err(-1);
        }
        let mut decoded = [0; 64];
        let (mut buffered, mut words, mut digits, mut word) = (0, 0u32, 0, 0u32);
        let size = self.stream(dev, name, |b| {
            // Hex words can cross sectors. Whitespace does not terminate a word.
            for &c in b {
                if let Some(h) = (c as char).to_digit(16) {
                    word = (word << 4) | h;
                    digits += 1;
                    if digits == 8 {
                        if words >= max_words {
                            return Err(-1);
                        }
                        decoded[buffered] = word;
                        buffered += 1;
                        words += 1;
                        digits = 0;
                        word = 0;
                        if buffered == 64 {
                            sink((words - buffered as u32) * 4, &decoded)?;
                            buffered = 0;
                        }
                    }
                } else if !matches!(c, b'\r' | b'\n' | b' ' | b'\t') {
                    return Err(-1);
                }
            }
            if buffered != 0 {
                sink((words - buffered as u32) * 4, &decoded[..buffered])?;
                buffered = 0;
            }
            Ok(())
        })?;
        if size == 0 || digits != 0 {
            return Err(-1);
        }
        Ok(words)
    }

    /// Write decoded words through the streaming sink without exceeding the destination slice.
    pub fn load_mem_file_bounded(
        &self,
        dev: &mut impl BlockDevice,
        name: &str,
        dst: &mut [u32],
    ) -> Result<u32, i32> {
        let max = dst.len().min(0x3fffffff) as u32;
        self.stream_mem_file(dev, name, max, |offset, words| {
            let start = offset as usize / 4;
            dst[start..start + words.len()].copy_from_slice(words);
            Ok(())
        })
    }
}
