//! Sv39: three 512-entry tables, 64-bit PTEs and 4 KiB mappings.
//! Table pointers are physical addresses, identity mapped in supervisor mode.
pub const V: u64 = 1;
pub const R: u64 = 2;
pub const W: u64 = 4;
pub const X: u64 = 8;
pub const U: u64 = 16;
pub const A: u64 = 64;
pub const D: u64 = 128;
const PPN_MASK: u64 = (1 << 44) - 1;

pub fn canonical(va: u64) -> bool {
    ((va << 25) as i64 >> 25) as u64 == va
}

pub fn satp(root: u64) -> u64 {
    assert!(root & 4095 == 0 && root >> 56 == 0, "invalid Sv39 root");
    (8 << 60) | (root >> 12)
}

fn table_address(pte: u64) -> u64 {
    ((pte >> 10) & PPN_MASK) << 12
}

/// Caller owns root and every table returned by allocate; allocations must be zeroed.
pub unsafe fn map_page(
    root: *mut u64,
    va: u64,
    pa: u64,
    flags: u64,
    mut allocate: impl FnMut() -> *mut u64,
) {
    assert!(canonical(va), "noncanonical Sv39 address");
    assert!(va & 4095 == 0 && pa & 4095 == 0 && pa >> 56 == 0);
    assert!(flags & !0xff == 0 && flags & (R | X) != 0);
    assert!(flags & W == 0 || flags & R != 0, "reserved W-only PTE");
    assert!(!root.is_null() && root as usize & 4095 == 0);
    let mut table = root;
    for level in (1..=2).rev() {
        let entry = table.add(((va >> (12 + level * 9)) & 511) as usize);
        if *entry & V == 0 {
            let next = allocate();
            assert!(!next.is_null() && next as usize & 4095 == 0);
            assert!((next as u64) >> 56 == 0);
            *entry = ((next as u64 >> 12) << 10) | V;
        }
        assert!(
            *entry & (R | W | X | U | A | D) == 0 && *entry >> 54 == 0,
            "invalid or leaf intermediate PTE"
        );
        table = table_address(*entry) as *mut u64;
    }
    // Eager A/D avoids depending on a hardware-managed accessed/dirty update.
    *table.add(((va >> 12) & 511) as usize) = ((pa >> 12) << 10) | flags | V | A | D;
}

#[derive(Debug, PartialEq, Eq)]
pub struct Translation {
    pub physical: u64,
    pub flags: u64,
}

/// Walk a trusted kernel-owned table; reject reserved PTEs and misaligned superpages.
pub unsafe fn translate(root: *const u64, va: u64) -> Option<Translation> {
    if !canonical(va) || root.is_null() || root as usize & 4095 != 0 {
        return None;
    }
    let mut table = root;
    for level in (0..=2).rev() {
        let pte = *table.add(((va >> (12 + level * 9)) & 511) as usize);
        if pte & V == 0 || pte >> 54 != 0 || (pte & W != 0 && pte & R == 0) {
            return None;
        }
        let pa = table_address(pte);
        if pte & (R | X) != 0 {
            let mask = (1u64 << (12 + level * 9)) - 1;
            if pa & mask != 0 {
                return None;
            }
            return Some(Translation {
                physical: pa | (va & mask),
                flags: pte & 0xff,
            });
        }
        if level == 0 || pte & (U | A | D) != 0 {
            return None;
        }
        table = pa as *const u64;
    }
    None
}
