//! fs/fat32.c/.h. Caller owns the volume and device instead of global buffers.
pub trait BlockDevice {
    fn read(&mut self, lba: u32, buf: &mut [u8; 512]) -> Result<(), i32>;
    fn write(&mut self, lba: u32, buf: &[u8; 512]) -> Result<(), i32>;
}
pub struct SdCard {
    _private: (),
}
impl SdCard {
    /// Requires exclusive ownership of the PSC SD peripheral.
    pub unsafe fn new() -> Self {
        Self { _private: () }
    }
}
impl BlockDevice for SdCard {
    fn read(&mut self, lba: u32, buf: &mut [u8; 512]) -> Result<(), i32> {
        unsafe { crate::drivers::sdcard_api::sd_read_sector(lba, buf) }
    }

    fn write(&mut self, lba: u32, buf: &[u8; 512]) -> Result<(), i32> {
        unsafe { crate::drivers::sdcard_api::sd_write_sector(lba, buf) }
    }
}

/// Decode FAT fields bytewise so packed disk structures need no aligned references.
pub(crate) fn le16(b: &[u8], i: usize) -> u32 {
    u16::from_le_bytes([b[i], b[i + 1]]) as u32
}

/// Read a little-endian on-disk integer after its sector has been loaded.
pub(crate) fn le32(b: &[u8], i: usize) -> u32 {
    u32::from_le_bytes([b[i], b[i + 1], b[i + 2], b[i + 3]])
}
#[derive(Default, Clone, Copy)]
pub struct Fat32 {
    pub part_lba: u32,
    pub fat_begin: u32,
    pub data_begin: u32,
    pub root_cluster: u32,
    pub sectors_per_cluster: u32,
}

/// Combine the high and low directory-entry cluster fields.
fn cluster(e: &[u8]) -> u32 {
    (le16(e, 20) << 16) | le16(e, 26)
}

/// Build the printable 8.3 name while omitting FAT space padding.
fn short_display(e: &[u8], out: &mut [u8; 12]) -> usize {
    let mut n = 0;
    for &c in &e[..8] {
        if c != b' ' {
            out[n] = c;
            n += 1;
        }
    }
    if e[8] != b' ' {
        out[n] = b'.';
        n += 1;
        for &c in &e[8..11] {
            if c != b' ' {
                out[n] = c;
                n += 1;
            }
        }
    }
    n
}
impl Fat32 {
    /// Read the first partition BPB and derive FAT, data, and root-directory locations.
    pub fn mount(dev: &mut impl BlockDevice) -> Result<Self, i32> {
        let mut b = [0; 512];
        dev.read(0, &mut b)?;
        let part_lba = le32(&b, 0x1c6);
        dev.read(part_lba, &mut b)?;
        let fat_begin = part_lba.wrapping_add(le16(&b, 14));
        Ok(Self {
            part_lba,
            fat_begin,
            data_begin: fat_begin.wrapping_add(b[16] as u32 * le32(&b, 36)),
            root_cluster: le32(&b, 44),
            sectors_per_cluster: b[13] as u32,
        })
    }

    /// Translate a data-cluster number using FAT32 cluster numbering starting at two.
    pub fn cluster_to_lba(&self, c: u32) -> u32 {
        self.data_begin
            .wrapping_add(c.wrapping_sub(2).wrapping_mul(self.sectors_per_cluster))
    }

    /// Read one masked 28-bit cluster-chain link from the FAT.
    fn next(&self, dev: &mut impl BlockDevice, c: u32) -> Result<u32, i32> {
        let mut b = [0; 512];
        dev.read(self.fat_begin + c / 128, &mut b)?;
        Ok(le32(&b, (c % 128) as usize * 4) & 0x0fffffff)
    }

    /// Search every root-directory sector for an exact printable short filename.
    pub fn find(&self, dev: &mut impl BlockDevice, name: &str) -> Result<(u32, u32), i32> {
        let mut c = self.root_cluster;
        let mut b = [0; 512];
        if self.sectors_per_cluster == 0 {
            return Err(-1);
        }
        while (2..0x0ffffff0).contains(&c) {
            for s in 0..self.sectors_per_cluster {
                dev.read(self.cluster_to_lba(c) + s, &mut b)?;
                for e in b.chunks_exact(32) {
                    if e[0] == 0 {
                        return Err(-1);
                    }
                    if e[0] == 0xe5 || e[11] == 0xf {
                        continue;
                    }
                    let mut out = [0; 12];
                    let n = short_display(e, &mut out);
                    if &out[..n] == name.as_bytes() {
                        return Ok((cluster(e), le32(e, 28)));
                    }
                }
            }
            let next = self.next(dev, c)?;
            if next == c {
                return Err(-1);
            }
            c = next;
        }
        Err(-1)
    }

    pub fn read(
        &self,
        dev: &mut impl BlockDevice,
        name: &str,
        dst: &mut [u8],
    ) -> Result<usize, i32> {
        let (mut c, size) = self.find(dev, name)?;
        let mut remaining = (size as usize).min(dst.len());
        let mut total = 0;
        let mut b = [0; 512];
        if self.sectors_per_cluster == 0 {
            return Err(-1);
        }
        while remaining != 0 {
            for s in 0..self.sectors_per_cluster {
                if remaining == 0 {
                    break;
                }
                dev.read(self.cluster_to_lba(c) + s, &mut b)?;
                let n = remaining.min(512);
                dst[total..total + n].copy_from_slice(&b[..n]);
                total += n;
                remaining -= n;
            }
            if remaining == 0 {
                break;
            }
            c = self.next(dev, c)?;
            if c >= 0x0ffffff8 {
                break;
            }
        }
        Ok(total)
    }

    /// Stream file bytes to the console and fail if the chain ends before the declared size.
    pub fn cat(&self, dev: &mut impl BlockDevice, name: &str) -> Result<(), i32> {
        let (mut c, mut remaining) = self.find(dev, name)?;
        let mut b = [0; 512];
        while remaining != 0 {
            if !(2..0x0ffffff0).contains(&c) || self.sectors_per_cluster == 0 {
                return Err(-1);
            }
            for s in 0..self.sectors_per_cluster {
                if remaining == 0 {
                    break;
                }
                dev.read(self.cluster_to_lba(c) + s, &mut b)?;
                let n = remaining.min(512);
                for &v in &b[..n as usize] {
                    unsafe {
                        crate::common::putchar(v);
                    }
                }
                remaining -= n;
            }
            if remaining != 0 {
                c = self.next(dev, c)?;
            }
        }
        crate::s_print!("\n");
        Ok(())
    }

    /// Create an empty archive entry in the first root sector, preserving the original scope.
    pub fn touch(&self, dev: &mut impl BlockDevice, name: &str) -> Result<(), i32> {
        let lba = self.cluster_to_lba(self.root_cluster);
        let mut b = [0; 512];
        dev.read(lba, &mut b)?;
        let mut short = [b' '; 11];
        let mut parts = name.splitn(2, '.');
        let base = parts.next().unwrap_or("");
        for (d, s) in short[..8].iter_mut().zip(base.bytes()) {
            *d = s;
        }
        for (d, s) in short[8..]
            .iter_mut()
            .zip(parts.next().unwrap_or("").bytes())
        {
            *d = s;
        }
        for e in b.chunks_exact_mut(32) {
            if e[0] == 0 || e[0] == 0xe5 {
                e.fill(0);
                e[..11].copy_from_slice(&short);
                e[11] = 0x20;
                dev.write(lba, &b)?;
                crate::s_print!("created: {}\n", name);
                return Ok(());
            }
        }
        Err(-1)
    }

    /// Preserve long-name state across sector boundaries and print each directory record.
    pub fn ls(&self, dev: &mut impl BlockDevice) -> Result<(), i32> {
        let mut c = self.root_cluster;
        let mut b = [0; 512];
        let mut lfn = Lfn::default();
        if self.sectors_per_cluster == 0 {
            return Err(-1);
        }
        while (2..0x0ffffff0).contains(&c) {
            for s in 0..self.sectors_per_cluster {
                dev.read(self.cluster_to_lba(c) + s, &mut b)?;
                for e in b.chunks_exact(32) {
                    if e[0] == 0 {
                        return Ok(());
                    }
                    if e[0] == 0xe5 {
                        lfn.slots = 0;
                        continue;
                    }
                    if e[11] == 0xf {
                        lfn.entry(e);
                        continue;
                    }
                    let length = lfn.length(e);
                    let mut columns = 0;
                    if length != 0 {
                        columns = lfn.print(length);
                    } else {
                        let mut name = [0; 12];
                        let n = short_display(e, &mut name);
                        for &v in &name[..n] {
                            unsafe {
                                crate::common::putchar(v);
                            }
                        }
                        columns += n;
                    }
                    for _ in columns..29 {
                        crate::s_print!(" ");
                    }
                    lfn.slots = 0;
                    let cl = cluster(e);
                    let lba = if cl >= 2 { self.cluster_to_lba(cl) } else { 0 };
                    crate::s_print!(
                        " attr={:x} cl={:x} lba={:x} size={:x}\n",
                        e[11],
                        cl,
                        lba,
                        le32(e, 28)
                    );
                }
            }
            let next = self.next(dev, c)?;
            if next == c {
                return Err(-1);
            }
            c = next;
        }
        Ok(())
    }
}
struct Lfn {
    name: [u16; 260],
    slots: usize,
    next: usize,
    checksum: u8,
}
impl Default for Lfn {
    fn default() -> Self {
        Self {
            name: [0; 260],
            slots: 0,
            next: 0,
            checksum: 0,
        }
    }
}
impl Lfn {
    /// Accept only a correctly ordered LFN fragment with a matching checksum.
    fn entry(&mut self, e: &[u8]) {
        let order = (e[0] & 31) as usize;
        if e[0] & 0xa0 != 0 || order == 0 || order > 20 || e[12] != 0 || e[26] != 0 || e[27] != 0 {
            self.slots = 0;
            return;
        }
        if e[0] & 0x40 != 0 {
            self.slots = order * 13;
            self.next = order;
            self.checksum = e[13];
        }
        if self.slots == 0 || self.next != order || self.checksum != e[13] {
            self.slots = 0;
            return;
        }
        for (i, p) in [1, 3, 5, 7, 9, 14, 16, 18, 20, 22, 24, 28, 30]
            .iter()
            .enumerate()
        {
            self.name[(order - 1) * 13 + i] = le16(e, *p) as u16;
        }
        self.next -= 1;
    }

    /// Validate the complete UTF-16 name and padding before printing any part of it.
    fn length(&self, e: &[u8]) -> usize {
        if self.slots == 0 || self.next != 0 || e[11] & 8 != 0 {
            return 0;
        }
        let mut sum = 0u8;
        for &b in &e[..11] {
            sum = sum.rotate_right(1).wrapping_add(b);
        }
        if sum != self.checksum {
            return 0;
        }
        let mut n = 0;
        while n < self.slots && self.name[n] != 0 {
            if self.name[n] == 0xffff {
                return 0;
            }
            n += 1;
        }
        if n == 0 || n > 255 || n <= self.slots - 13 {
            return 0;
        }
        for i in n + 1..self.slots {
            if self.name[i] != 0xffff {
                return 0;
            }
        }
        n
    }

    /// Decode surrogate pairs and truncate long names by display columns, not UTF-8 bytes.
    fn print(&self, length: usize) -> usize {
        let chars = || {
            core::char::decode_utf16(self.name[..length].iter().copied())
                .map(|c| c.unwrap_or('\u{fffd}'))
        };
        let total: usize = chars().map(|c| name_columns(c as u32)).sum();
        let mut columns = 0;
        for c in chars() {
            let width = name_columns(c as u32);
            if total > 28 && columns + width > 25 {
                break;
            }
            columns += width;
            crate::s_print!("{}", c);
        }
        if total > 28 {
            crate::s_print!("...");
            columns += 3;
        }
        columns
    }
}

/// Approximate terminal width for combining marks, CJK text, and common emoji.
fn name_columns(c: u32) -> usize {
    if (0x0300..=0x036f).contains(&c) || (0xfe00..=0xfe0f).contains(&c) {
        return 0;
    }
    if (0x1100..=0x115f).contains(&c)
        || ((0x2e80..=0xa4cf).contains(&c) && c != 0x303f)
        || (0xac00..=0xd7a3).contains(&c)
        || (0xf900..=0xfaff).contains(&c)
        || (0xfe10..=0xfe19).contains(&c)
        || (0xfe30..=0xfe6f).contains(&c)
        || (0xff01..=0xff60).contains(&c)
        || (0xffe0..=0xffe6).contains(&c)
        || (0x1f300..=0x1faff).contains(&c)
        || (0x20000..=0x3fffd).contains(&c)
    {
        2
    } else {
        1
    }
}
