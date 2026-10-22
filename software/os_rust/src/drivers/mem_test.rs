//! drivers/mem_test.c/.h. Destructive tests require exclusively owned RAM.
use crate::common::{mmio_r32, mmio_w32};
/// Advance the Galois LFSR with the original 0xa3000000 feedback polynomial.
fn lfsr_next(x: u32) -> u32 {
    (x >> 1) ^ if x & 1 != 0 { 0xa3000000 } else { 0 }
}

/// Replay the same address sequence for write and verification passes.
unsafe fn check(start: u32, end: u32, random: bool) -> bool {
    assert!(start & 3 == 0 && end >= start);
    let range = end - start;
    if random {
        assert!(range.is_power_of_two());
    }
    let mut pass = true;
    for write in [true, false] {
        let mut lfsr = 0x12345678;
        for i in 0..range / 4 {
            let addr = start + if random { lfsr & (range - 4) } else { i * 4 };
            let expected = addr ^ 0xa5a5a5a5;
            if write {
                mmio_w32(addr, expected);
            } else {
                let value = mmio_r32(addr);
                if value != expected {
                    pass = false;
                    crate::s_print!(
                        "MEM ERROR addr={:x} read={:x} exp={:x}\n",
                        addr,
                        value,
                        expected
                    );
                    mmio_w32(0x10000000, 0xee01);
                }
            }
            lfsr = lfsr_next(lfsr);
        }
    }
    crate::s_print!("[mem_check] {}\n", if pass { "OK" } else { "NG" });
    pass
}

/// Test a power-of-two RAM range with deterministic pseudorandom addressing.
pub unsafe fn random_mem_check(start: u32, end: u32) -> bool {
    check(start, end, true)
}

/// Walk every aligned word in the requested RAM interval.
pub unsafe fn seqential_mem_check(start: u32, end: u32) -> bool {
    check(start, end, false)
}
