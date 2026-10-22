//! fs/fat32_stream.c and streaming declarations from fat32.h.
//! Per-file buffers, sticky errors, Brent cycle detection, no heap.
use super::fat32::{le16, le32, BlockDevice};
pub const NAME: i32 = -2;
pub const NOT_FOUND: i32 = -3;
pub const SD: i32 = -4;
pub const FORMAT: i32 = -5;
pub const CHAIN: i32 = -6;
pub const STATE: i32 = -7;
/// Accept the deliberately restricted uppercase root-directory 8.3 filename syntax.
pub fn short_name(name: &str) -> Result<[u8; 11], i32> {
    let mut out = [b' '; 11];
    let (mut base, mut ext, mut dot) = (0, 0, false);
    for c in name.bytes() {
        if c == b'.' && !dot && base != 0 {
            dot = true;
            continue;
        }
        if !(c.is_ascii_uppercase() || c.is_ascii_digit() || c == b'_' || c == b'-') {
            return Err(NAME);
        }
        if !dot {
            if base == 8 {
                return Err(NAME);
            }
            out[base] = c;
            base += 1;
        } else {
            if ext == 3 {
                return Err(NAME);
            }
            out[8 + ext] = c;
            ext += 1;
        }
    }
    if base == 0 || (dot && ext == 0) {
        Err(NAME)
    } else {
        Ok(out)
    }
}
pub struct File {
    pub file_size: u32,
    pub file_pos: u32,
    pub first_cluster: u32,
    current_cluster: u32,
    data_begin: u32,
    fat_begin: u32,
    spc: u32,
    cluster_count: u32,
    sector_in_cluster: u32,
    sector_offset: usize,
    cached_lba: u32,
    chain_anchor: u32,
    chain_power: u32,
    chain_length: u32,
    chain_steps: u32,
    pub error: i32,
    pub opened: bool,
    sector_buf: [u8; 512],
}
impl Default for File {
    fn default() -> Self {
        Self {
            file_size: 0,
            file_pos: 0,
            first_cluster: 0,
            current_cluster: 0,
            data_begin: 0,
            fat_begin: 0,
            spc: 0,
            cluster_count: 0,
            sector_in_cluster: 0,
            sector_offset: 0,
            cached_lba: u32::MAX,
            chain_anchor: 0,
            chain_power: 1,
            chain_length: 0,
            chain_steps: 0,
            error: 0,
            opened: false,
            sector_buf: [0; 512],
        }
    }
}
impl File {
    /// Latch an error so subsequent stream reads cannot silently resume after corruption.
    fn fail<T>(&mut self, error: i32) -> Result<T, i32> {
        self.error = error;
        Err(error)
    }

    /// Reject reserved, bad, and out-of-volume cluster identifiers.
    fn valid(&self, c: u32) -> bool {
        c >= 2 && c - 2 < self.cluster_count && c < 0x0ffffff0
    }

    /// Reuse the cached sector until its LBA changes; SD failures become sticky.
    fn sector(&mut self, dev: &mut impl BlockDevice, lba: u32) -> Result<(), i32> {
        if self.cached_lba != lba {
            if dev.read(lba, &mut self.sector_buf).is_err() {
                return self.fail(SD);
            }
            self.cached_lba = lba;
        }
        Ok(())
    }

    /// Reset both stream offsets and constant-space cycle-detection state.
    fn chain_start(&mut self, c: u32) {
        self.current_cluster = c;
        self.chain_anchor = c;
        self.chain_power = 1;
        self.chain_length = 0;
        self.chain_steps = 0;
        self.sector_in_cluster = 0;
        self.sector_offset = 0;
    }

    /// Advance the FAT chain using Brent cycle detection and a volume-sized step limit.
    fn next(&mut self, dev: &mut impl BlockDevice) -> Result<bool, i32> {
        let c = self.current_cluster;
        if !self.valid(c) {
            return self.fail(CHAIN);
        }
        self.sector(dev, self.fat_begin + c / 128)?;
        let next = le32(&self.sector_buf, (c % 128) as usize * 4) & 0x0fffffff;
        if next >= 0x0ffffff8 {
            return Ok(true);
        }
        self.chain_steps += 1;
        if !self.valid(next) || self.chain_steps >= self.cluster_count || next == self.chain_anchor
        {
            return self.fail(CHAIN);
        }
        self.chain_length += 1;
        if self.chain_length == self.chain_power {
            self.chain_anchor = next;
            self.chain_length = 0;
            if self.chain_power < 0x10000000 {
                self.chain_power *= 2;
            }
        }
        self.current_cluster = next;
        self.sector_in_cluster = 0;
        self.sector_offset = 0;
        Ok(false)
    }

    /// Invalidate the open handle and sector cache without performing any disk writes.
    pub fn close(&mut self) {
        self.opened = false;
        self.cached_lba = u32::MAX;
    }

    /// Validate volume geometry, traverse the root chain, and initialize file state.
    pub fn open(&mut self, dev: &mut impl BlockDevice, name: &str) -> Result<(), i32> {
        *self = Self::default();
        let wanted = match short_name(name) {
            Ok(n) => n,
            Err(e) => return self.fail(e),
        };
        self.sector(dev, 0)?;
        if le16(&self.sector_buf, 510) != 0xaa55 {
            return self.fail(FORMAT);
        }
        let part = le32(&self.sector_buf, 0x1c6);
        if part == 0 {
            return self.fail(FORMAT);
        }
        self.sector(dev, part)?;
        let b = &self.sector_buf;
        let spc = b[13] as u32;
        let reserved = le16(b, 14);
        let fats = b[16] as u32;
        let fatsz = le32(b, 36);
        let total = le32(b, 32);
        let root = le32(b, 44);
        if le16(b, 510) != 0xaa55
            || le16(b, 11) != 512
            || spc == 0
            || spc > 128
            || spc & (spc - 1) != 0
            || reserved == 0
            || fats == 0
            || fats > 2
            || fatsz == 0
            || fatsz > 0x01000000
            || le16(b, 17) != 0
            || le16(b, 22) != 0
            || le16(b, 42) != 0
            || total > u32::MAX - part
        {
            return self.fail(FORMAT);
        }
        let overhead = reserved + fats * fatsz;
        if total <= overhead {
            return self.fail(FORMAT);
        }
        self.cluster_count = (total - overhead) / spc;
        if self.cluster_count == 0
            || self.cluster_count > 0x0fffffee
            || self.cluster_count + 2 > fatsz * 128
        {
            return self.fail(FORMAT);
        }
        let active = if le16(b, 40) & 0x80 != 0 {
            (b[40] & 15) as u32
        } else {
            0
        };
        if active >= fats {
            return self.fail(FORMAT);
        }
        self.fat_begin = part + reserved + active * fatsz;
        self.data_begin = part + overhead;
        self.spc = spc;
        if !self.valid(root) {
            return self.fail(CHAIN);
        }
        self.chain_start(root);
        loop {
            for s in 0..spc {
                self.sector(dev, self.data_begin + (self.current_cluster - 2) * spc + s)?;
                for off in (0..512).step_by(32) {
                    let e = &self.sector_buf[off..off + 32];
                    if e[0] == 0 {
                        return self.fail(NOT_FOUND);
                    }
                    if e[0] == 0xe5 || e[11] & 0x18 != 0 || e[11] == 0x0f || e[..11] != wanted {
                        continue;
                    }
                    self.file_size = le32(e, 28);
                    self.first_cluster = (le16(e, 20) << 16) | le16(e, 26);
                    if self.file_size != 0 && !self.valid(self.first_cluster) {
                        return self.fail(CHAIN);
                    }
                    self.chain_start(self.first_cluster);
                    self.opened = true;
                    return Ok(());
                }
            }
            if self.next(dev)? {
                return self.fail(NOT_FOUND);
            }
        }
    }

    /// Read or skip bytes while preserving partial progress and detecting premature end-of-chain.
    fn transfer(
        &mut self,
        dev: &mut impl BlockDevice,
        mut dst: Option<&mut [u8]>,
        count: u32,
        actual: &mut u32,
    ) -> Result<(), i32> {
        *actual = 0;
        if !self.opened {
            return Err(STATE);
        }
        if self.error != 0 {
            return Err(self.error);
        }
        let count = count.min(self.file_size - self.file_pos);
        while *actual < count {
            if self.sector_offset == 512 {
                self.sector_offset = 0;
                self.sector_in_cluster += 1;
                if self.sector_in_cluster == self.spc && self.next(dev)? {
                    return self.fail(CHAIN);
                }
            }
            if !self.valid(self.current_cluster) {
                return self.fail(CHAIN);
            }
            self.sector(
                dev,
                self.data_begin + (self.current_cluster - 2) * self.spc + self.sector_in_cluster,
            )?;
            let n = (512 - self.sector_offset).min((count - *actual) as usize);
            if let Some(out) = dst.as_deref_mut() {
                out[*actual as usize..*actual as usize + n]
                    .copy_from_slice(&self.sector_buf[self.sector_offset..self.sector_offset + n]);
            }
            self.sector_offset += n;
            self.file_pos += n as u32;
            *actual += n as u32;
        }
        Ok(())
    }

    /// Fill at most the destination length and report a successful short read at EOF.
    pub fn read(
        &mut self,
        dev: &mut impl BlockDevice,
        dst: &mut [u8],
        actual: &mut u32,
    ) -> Result<(), i32> {
        let count = dst.len().min(u32::MAX as usize) as u32;
        self.transfer(dev, Some(dst), count, actual)
    }

    /// Consume the same checked disk path as reading so skips cannot conceal SD errors.
    pub fn skip(
        &mut self,
        dev: &mut impl BlockDevice,
        count: u32,
        actual: &mut u32,
    ) -> Result<(), i32> {
        self.transfer(dev, None, count, actual)
    }
}
