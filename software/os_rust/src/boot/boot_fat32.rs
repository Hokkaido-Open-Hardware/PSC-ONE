//! boot/boot_fat32.c/.h: root-directory boot file and ASCII .mem loading.
use crate::fs::fat32::{le16, le32, BlockDevice};

// Host-side FAT32 validation must not access UART MMIO.
macro_rules! boot_log {
    ($($arg:tt)*) => {
        #[cfg(any(target_arch = "riscv32", target_arch = "riscv64"))]
        crate::s_print!($($arg)*);
    };
}
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
        boot_log!("FAT32: mount enter\nFAT32: read LBA0\n");
        let mut b = [0; 512];
        dev.read(0, &mut b).map_err(|e| {
            boot_log!("FAT32: read LBA0 failed\n");
            e
        })?;
        boot_log!("FAT32: read LBA0 ok\n");
        // Both partitioned cards and super-floppy FAT32 images are supported.
        let part = if valid_bpb(&b) {
            boot_log!("FAT32: super floppy\n");
            0
        } else {
            if le16(&b, 510) != 0xaa55 {
                boot_log!("FAT32: MBR sig bad\n");
                return Err(-1);
            }
            let part = le32(&b, 0x1c6);
            boot_log!("FAT32: part ok\n");
            if part == 0 {
                boot_log!("FAT32: part_lba zero\n");
                return Err(-1);
            }
            boot_log!("FAT32: read BPB\n");
            dev.read(part, &mut b).map_err(|e| {
                boot_log!("FAT32: read BPB failed\n");
                e
            })?;
            boot_log!("FAT32: read BPB ok\n");
            if !valid_bpb(&b) {
                boot_log!("FAT32: BPB invalid\n");
                return Err(-1);
            }
            boot_log!("FAT32: BPB valid\n");
            part
        };
        boot_log!("FAT32: parse 1\n");
        let _bytes_per_sector = le16(&b, 11);
        boot_log!("FAT32: parse 2\n");
        let sectors_per_cluster = b[13] as u32;
        boot_log!("FAT32: parse 3\n");
        let reserved = le16(&b, 14);
        boot_log!("FAT32: parse 4\n");
        let fat_count = b[16] as u32;
        boot_log!("FAT32: parse 5\n");
        let fat_size = le32(&b, 36);
        boot_log!("FAT32: parse 6\n");
        let root_cluster = le32(&b, 44);
        boot_log!("FAT32: validate\n");
        // valid_bpb already checked all other geometry fields above.
        if fat_count > 4 {
            boot_log!("FAT32: bad fat_count\n");
            return Err(-1);
        }
        boot_log!("FAT32: root check\n");
        if root_cluster == 2 {
            boot_log!("FAT32: root is 2\n");
        } else {
            boot_log!("FAT32: root NOT 2\n");
        }
        boot_log!("FAT32: calc fat\n");
        let fat = part.wrapping_add(reserved);
        boot_log!("FAT32: calc data\n");
        let mut data = fat;
        for _index in 1..=fat_count {
            boot_log!("FAT32: add fat{}\n", _index);
            data = data.wrapping_add(fat_size);
        }
        boot_log!("FAT32: mount ok\n");
        Ok(Self {
            part_lba: part,
            fat_begin: fat,
            data_begin: data,
            root_cluster,
            sectors_per_cluster,
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
        boot_log!("FAT32: find enter\n");
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
        boot_log!("FAT32: root loop\n");
        while c >= 2 && c < 0x0ffffff8 && c != 0x0ffffff7 {
            boot_log!("FAT32: calc lba\n");
            let dir_lba = self.cluster_to_lba(c);
            boot_log!("FAT32: read dir\n");
            for s in 0..self.sectors_per_cluster {
                dev.read(dir_lba + s, &mut b).map_err(|e| {
                    boot_log!("FAT32: read dir failed\n");
                    e
                })?;
                boot_log!("FAT32: dir ok\n");
                for e in b.chunks_exact(32) {
                    if e[0] == 0 {
                        boot_log!("FAT32: dir end\n");
                        return Err(-1);
                    }
                    if e[0] == 0xe5 || e[11] == 0xf || e[11] & 0x18 != 0 {
                        continue;
                    }
                    boot_log!("FAT32: entry\n");
                    if e[..11] == wanted {
                        boot_log!("FAT32: found\n");
                        return Ok(((le16(e, 20) << 16) | le16(e, 26), le32(e, 28)));
                    }
                }
            }
            boot_log!("FAT32: next\n");
            c = self.next_cluster(dev, c)?;
        }
        boot_log!("FAT32: not found\n");
        Err(-1)
    }

    /// Deliver exactly the declared file bytes, rejecting a premature or bad cluster link.
    fn stream(
        &self,
        dev: &mut impl BlockDevice,
        name: &str,
        mem_image: bool,
        mut consume: impl FnMut(&[u8]) -> Result<(), i32>,
    ) -> Result<u32, i32> {
        let (mut c, size) = self.find(dev, name).map_err(|e| {
            boot_log!("FAT32: find failed\n");
            e
        })?;
        if mem_image {
            boot_log!("FAT32: find ok\n");
            if size == 0 {
                boot_log!("FAT32: size zero\n");
                return Err(-1);
            }
            if c < 2 {
                boot_log!("FAT32: invalid start cluster\n");
                return Err(-1);
            }
        }
        let mut remaining = size;
        let mut b = [0; 512];
        // Count successfully decoded ASCII file bytes, excluding metadata/retries.
        if mem_image {
            boot_log!("FAT32: loading {} size={}\n", name, size);
        }
        while remaining != 0 {
            if c < 2 {
                boot_log!("FAT32: cluster <2\n");
                return Err(-1);
            }
            if c == 0x0ffffff7 {
                boot_log!("FAT32: bad cluster\n");
                return Err(-1);
            }
            if c >= 0x0ffffff8 {
                boot_log!("FAT32: EOC before complete\n");
                return Err(-1);
            }
            for s in 0..self.sectors_per_cluster {
                if remaining == 0 {
                    break;
                }
                dev.read(self.cluster_to_lba(c) + s, &mut b).map_err(|e| {
                    boot_log!("FAT32: read file failed\n");
                    e
                })?;
                let n = remaining.min(512);
                consume(&b[..n as usize])?;
                remaining -= n;
                // EOF is reported by stream_mem_file after the partial-word check.
                let read_bytes = size - remaining;
                if mem_image && remaining != 0 && read_bytes % 16384 == 0 {
                    boot_log!("FAT32: {} read={}/{} bytes\n", name, read_bytes, size);
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
        self.stream(dev, name, false, |b| {
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
        boot_log!("FAT32: load mem enter\n");
        if max_words > 0x3fffffff {
            return Err(-1);
        }
        let mut decoded = [0; 64];
        let (mut buffered, mut words, mut digits, mut word) = (0, 0u32, 0, 0u32);
        let _size = self.stream(dev, name, true, |b| {
            // Hex words can cross sectors. Whitespace does not terminate a word.
            for &c in b {
                if let Some(h) = (c as char).to_digit(16) {
                    word = (word << 4) | h;
                    digits += 1;
                    if digits == 8 {
                        if words >= max_words {
                            boot_log!("FAT32: mem image too large\n");
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
                    boot_log!("FAT32: bad mem char\n");
                    return Err(-1);
                }
            }
            if buffered != 0 {
                sink((words - buffered as u32) * 4, &decoded[..buffered])?;
                buffered = 0;
            }
            Ok(())
        })?;
        if digits != 0 {
            boot_log!("FAT32: partial hex word\n");
            return Err(-1);
        }
        boot_log!("FAT32: {} read={}/{} bytes\n", name, _size, _size);
        boot_log!("FAT32: {} load complete\n", name);
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
