//! Validate baseline JPEG headers before the upstream decoder reads its tables.
use crate::fs::{fat32::BlockDevice, fat32_stream::File};
pub const FORMAT: i32 = -100;
pub const UNSUPPORTED: i32 = -101;
pub const LARGE: i32 = -102;
pub const EOF: i32 = -103;
pub const LCD: i32 = -104;
pub const WORK: i32 = -105;
#[derive(Default)]
pub struct Header {
    pub width: u16,
    pub height: u16,
    pub scan_offset: u32,
}

fn exact(file: &mut File, dev: &mut impl BlockDevice, bytes: &mut [u8]) -> Result<(), i32> {
    let mut got = 0;
    file.read(dev, bytes, &mut got)?;
    if got as usize != bytes.len() {
        return Err(EOF);
    }
    Ok(())
}

fn be16(bytes: &[u8]) -> u16 {
    u16::from_be_bytes([bytes[0], bytes[1]])
}

/// Reject progressive, oversized and malformed tables before entering C.
pub fn check(file: &mut File, dev: &mut impl BlockDevice) -> Result<Header, i32> {
    let mut b = [0; 512];
    exact(file, dev, &mut b[..2])?;
    if b[..2] != [255, 0xd8] {
        return Err(FORMAT);
    }
    let mut header = Header::default();
    let (mut components, mut quant, mut huff) = (0usize, 0u32, 0u32);
    let mut qid = [0; 3];
    loop {
        if file.file_pos > 128 * 1024 {
            return Err(UNSUPPORTED);
        }
        exact(file, dev, &mut b[..4])?;
        let length = be16(&b[2..]) as usize;
        if b[0] != 255 || length < 2 {
            return Err(FORMAT);
        }
        let marker = b[1];
        let mut n = length - 2;
        if n as u32 > file.file_size - file.file_pos {
            return Err(EOF);
        }
        if (0xe0..=0xef).contains(&marker) || marker == 0xfe {
            if marker == 0xee && n >= 12 {
                exact(file, dev, &mut b[..12])?;
                n -= 12;
                if &b[..5] == b"Adobe" && b[11] != 1 {
                    return Err(UNSUPPORTED);
                }
            }
            let mut skipped = 0;
            file.skip(dev, n as u32, &mut skipped)?;
            if skipped != n as u32 {
                return Err(EOF);
            }
            continue;
        }
        if !matches!(marker, 0xc0 | 0xc4 | 0xdb | 0xdd | 0xda) || n == 0 || n > 512 {
            return Err(UNSUPPORTED);
        }
        exact(file, dev, &mut b[..n])?;
        match marker {
            0xc0 => {
                if components != 0 || n < 6 {
                    return Err(FORMAT);
                }
                if b[0] != 8 || !matches!(b[5], 1 | 3) {
                    return Err(UNSUPPORTED);
                }
                components = b[5] as usize;
                if n != 6 + 3 * components {
                    return Err(FORMAT);
                }
                header.height = be16(&b[1..]);
                header.width = be16(&b[3..]);
                if header.width == 0 || header.height == 0 {
                    return Err(FORMAT);
                }
                if header.width > 480 || header.height > 320 {
                    return Err(LARGE);
                }
                for i in 0..components {
                    let sample = b[7 + 3 * i];
                    if b[6 + 3 * i] != i as u8 + 1 || b[8 + 3 * i] > 3 {
                        return Err(UNSUPPORTED);
                    }
                    if i != 0 || components == 1 {
                        if sample != 0x11 {
                            return Err(UNSUPPORTED);
                        }
                    } else if !matches!(sample, 0x11 | 0x21 | 0x22) {
                        return Err(UNSUPPORTED);
                    }
                    qid[i] = b[8 + 3 * i];
                }
            }
            0xdb => {
                if n % 65 != 0 {
                    return Err(FORMAT);
                }
                for table in b[..n].chunks_exact(65) {
                    if table[0] > 3 || quant & (1 << table[0]) != 0 {
                        return Err(UNSUPPORTED);
                    }
                    quant |= 1 << table[0];
                    if table[1..].contains(&0) {
                        return Err(FORMAT);
                    }
                }
            }
            0xc4 => {
                let mut p = 0;
                while p < n {
                    if n - p < 17 {
                        return Err(FORMAT);
                    }
                    let kind = b[p];
                    p += 1;
                    if !matches!(kind, 0 | 1 | 0x10 | 0x11) {
                        return Err(UNSUPPORTED);
                    }
                    let bit = (kind & 1) * 2 + (kind >> 4);
                    if huff & (1 << bit) != 0 {
                        return Err(UNSUPPORTED);
                    }
                    huff |= 1 << bit;
                    let (mut slots, mut count) = (1i32, 0usize);
                    for _ in 0..16 {
                        let c = b[p];
                        p += 1;
                        count += c as usize;
                        slots = slots * 2 - c as i32;
                        // An all-ones Huffman code is forbidden in JPEG.
                        if slots <= 0 {
                            return Err(FORMAT);
                        }
                    }
                    if count == 0 || count > 256 || count > n - p {
                        return Err(FORMAT);
                    }
                    for &symbol in &b[p..p + count] {
                        if kind < 16 {
                            if symbol > 11 {
                                return Err(FORMAT);
                            }
                        } else if symbol & 15 > 10
                            || (symbol & 15 == 0 && symbol != 0 && symbol != 0xf0)
                        {
                            return Err(FORMAT);
                        }
                    }
                    p += count;
                }
            }
            0xdd => {
                if n != 2 {
                    return Err(FORMAT);
                }
            }
            _ => {
                if components == 0
                    || n != 4 + 2 * components
                    || b[0] as usize != components
                    || b[n - 3..n] != [0, 63, 0]
                {
                    return Err(UNSUPPORTED);
                }
                for i in 0..components {
                    if b[1 + 2 * i] != i as u8 + 1 || b[2 + 2 * i] != if i == 0 { 0 } else { 0x11 }
                    {
                        return Err(UNSUPPORTED);
                    }
                    let required = if i == 0 { 3 } else { 12 };
                    if quant & (1 << qid[i]) == 0 || huff & required != required {
                        return Err(FORMAT);
                    }
                }
                header.scan_offset = file.file_pos;
                return Ok(header);
            }
        }
    }
}
