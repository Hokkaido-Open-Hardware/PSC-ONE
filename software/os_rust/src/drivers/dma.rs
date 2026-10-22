//! drivers/dma.c/.h. Identity mapped nonoverlapping buffers, no concurrent DMA.
#[cfg(target_arch = "riscv32")]
/// Publish dirty cache lines before DMA; optionally invalidate stale destination lines.
unsafe fn cache_sync(addr: *const u8, invalidate: bool) {
    if invalidate {
        core::arch::asm!("fence rw, rw", "li t0, 2", "csrw 0x7f0, t0", "csrw 0x7f0, zero", "lw zero, 0({p})", "li t0, 1", "csrw 0x7f0, t0", "csrw 0x7f0, zero", "lw zero, 0({p})", "fence rw, rw", p=in(reg) addr, out("t0") _);
    } else {
        core::arch::asm!("fence rw, rw", "li t0, 2", "csrw 0x7f0, t0", "csrw 0x7f0, zero", "lw zero, 0({p})", p=in(reg) addr, out("t0") _);
    }
}

/// Transfer aligned whole words with DMA and copy any remaining bytes with the CPU.
pub unsafe fn memcpy_dma(dst: *mut u8, src: *const u8, n: usize) -> *mut u8 {
    let mut bytes = 0;
    #[cfg(target_arch = "riscv32")]
    if (dst as usize | src as usize) & 3 == 0 && n >= 4 {
        bytes = n & !3;
        // DMA bypasses the write-back cache, so publish source and dirty destination lines.
        cache_sync(src, false);
        core::arch::asm!("csrw 0x7e4, {words}","csrw 0x7e8, {src}","csrw 0x7ec, {dst}","csrw 0x7e0, {start}",words=in(reg) bytes/4,src=in(reg) src,dst=in(reg) dst,start=in(reg) 1u32);
        // Hold START until BUSY acknowledges it, including a restart from DONE state.
        loop {
            let s: u32;
            core::arch::asm!("csrr {}, 0x7f0",out(reg) s);
            if s & 2 != 0 {
                break;
            }
        }
        core::arch::asm!("csrw 0x7e0, zero");
        // BUSY is acceptance, not completion; wait separately for the DONE bit.
        loop {
            let s: u32;
            core::arch::asm!("csrr {}, 0x7f0",out(reg) s);
            if s & 1 != 0 {
                break;
            }
        }
        // Preserve unrelated dirty data before discarding stale cached DMA results.
        cache_sync(src, true);
    }
    // Short/unaligned transfers and the trailing 1..3 bytes use ordinary CPU accesses.
    while bytes < n {
        *dst.add(bytes) = *src.add(bytes);
        bytes += 1;
    }
    dst
}
