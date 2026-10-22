//! kernel/elf_loader.c/.h. Bytewise RV32 ELF validation, bounded PT_LOAD list.
use super::user_memory::*;
pub const FILE_MAX: usize = 32 * 1024;
pub const PH_MAX: usize = 8;
pub const PAGE_SIZE: u32 = 4096;
pub const LOAD_PAGES: u32 = 16;
pub const STACK_PAGES: u32 = 4;
pub const STACK_BOTTOM: u32 = USER_STACK_TOP - STACK_PAGES * PAGE_SIZE;
pub const LOAD_END: u32 = STACK_BOTTOM - PAGE_SIZE;
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(i32)]
pub enum Error {
    Header = -1,
    Format = -2,
    Phdr = -3,
    Segment = -4,
    Range = -5,
    Overlap = -6,
    Limit = -7,
    Entry = -8,
    Busy = -9,
    Pointer = -10,
    Fault = -11,
}
#[derive(Default, Clone, Copy, Debug)]
#[repr(C)]
pub struct Segment {
    pub offset: u32,
    pub vaddr: u32,
    pub filesz: u32,
    pub memsz: u32,
    pub flags: u32,
}
#[derive(Default, Clone, Copy, Debug)]
#[repr(C)]
pub struct Image {
    pub entry: u32,
    pub count: u32,
    pub pages: u32,
    pub segments: [Segment; PH_MAX],
}

/// Read an unaligned little-endian ELF field without casting a packed structure.
fn le16(b: &[u8], i: usize) -> u32 {
    u16::from_le_bytes([b[i], b[i + 1]]) as u32
}

/// Read a 32-bit field only after its containing header has been bounds-checked.
fn le32(b: &[u8], i: usize) -> u32 {
    u32::from_le_bytes([b[i], b[i + 1], b[i + 2], b[i + 3]])
}

/// Reject incompatible RV32 ELFs and build a bounded, nonoverlapping PT_LOAD plan.
pub fn psc_elf_validate(b: &[u8]) -> Result<Image, Error> {
    if b.len() < 52 || &b[..4] != b"\x7fELF" {
        return Err(Error::Header);
    }
    if b.len() > FILE_MAX {
        return Err(Error::Limit);
    }
    if b[4] != 1
        || b[5] != 1
        || b[6] != 1
        || le16(b, 16) != 2
        || le16(b, 18) != 243
        || le32(b, 20) != 1
        || le32(b, 36) != 0
        || le16(b, 40) != 52
    {
        return Err(Error::Format);
    }
    let phoff = le32(b, 28) as usize;
    let phnum = le16(b, 44) as usize;
    if le16(b, 42) != 32
        || phnum == 0
        || phnum > PH_MAX
        || phoff < 52
        || phoff > b.len()
        || phnum > (b.len() - phoff) / 32
    {
        return Err(Error::Phdr);
    }
    let entry = le32(b, 24);
    let mut executable = false;
    let mut out = Image::default();
    for i in 0..phnum {
        let p = &b[phoff + i * 32..];
        let kind = le32(p, 0);
        if matches!(kind, 2 | 3 | 7) {
            return Err(Error::Format);
        }
        if kind != 1 {
            continue;
        }
        let s = Segment {
            offset: le32(p, 4),
            vaddr: le32(p, 8),
            filesz: le32(p, 16),
            memsz: le32(p, 20),
            flags: le32(p, 24),
        };
        let alignment = le32(p, 28);
        if s.filesz > s.memsz || s.offset > b.len() as u32 || s.filesz > b.len() as u32 - s.offset {
            return Err(Error::Segment);
        }
        if s.memsz == 0 {
            continue;
        }
        if s.flags & !7 != 0
            || s.flags & 5 == 0
            || (s.flags & 2 != 0 && s.flags & 4 == 0)
            || (alignment > 1
                && (alignment & (alignment - 1) != 0
                    || s.vaddr.wrapping_sub(s.offset) & (alignment - 1) != 0))
        {
            return Err(Error::Segment);
        }
        if s.vaddr < USER_BASE || s.vaddr >= LOAD_END || s.memsz > LOAD_END - s.vaddr {
            return Err(Error::Range);
        }
        let first = s.vaddr / PAGE_SIZE;
        let last = (s.vaddr + s.memsz - 1) / PAGE_SIZE;
        for t in &out.segments[..out.count as usize] {
            if first <= (t.vaddr + t.memsz - 1) / PAGE_SIZE && t.vaddr / PAGE_SIZE <= last {
                return Err(Error::Overlap);
            }
        }
        if last - first + 1 > LOAD_PAGES - out.pages {
            return Err(Error::Limit);
        }
        out.pages += last - first + 1;
        out.segments[out.count as usize] = s;
        out.count += 1;
        if s.flags & 1 != 0 && entry >= s.vaddr && s.filesz >= 4 && entry - s.vaddr <= s.filesz - 4
        {
            executable = true;
        }
    }
    if !executable || entry & 3 != 0 {
        return Err(Error::Entry);
    }
    out.entry = entry;
    Ok(out)
}

/// Provide stable diagnostic text for loader and user-memory validation failures.
pub fn psc_elf_error(error: Error) -> &'static str {
    match error {
        Error::Header => "bad ELF magic or truncated header",
        Error::Format => "unsupported ELF format/architecture",
        Error::Phdr => "invalid/truncated program header table",
        Error::Segment => "invalid PT_LOAD file range/size/flags/alignment",
        Error::Range => "PT_LOAD outside user region",
        Error::Overlap => "PT_LOAD pages overlap",
        Error::Limit => "ELF file/page limit exceeded",
        Error::Entry => "entry is not aligned executable file data",
        Error::Busy => "an ELF is already running",
        Error::Pointer => "invalid user buffer",
        Error::Fault => "user application fault",
    }
}
