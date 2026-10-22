//! drivers/mic_api.c/.h. Capture is bounded by the original 160000-word buffer.
use crate::common::{delay, mmio_r32, mmio_w32};
const RX: u32 = 0x10007000;
const STATUS: u32 = 0x10007004;
static mut SAMPLES: [u32; 160000] = [0; 160000];
/// Bound the wait for a nonempty I2S receive FIFO.
pub unsafe fn mic_wait_sample() -> Result<(), i32> {
    let mut timeout = 50000;
    while mmio_r32(STATUS) & 1 != 0 {
        timeout -= 1;
        if timeout == 0 {
            return Err(-1);
        }
        delay(1);
    }
    Ok(())
}

/// Return the complete hardware sample word after checking FIFO availability.
pub unsafe fn mic_read_raw() -> Result<u32, i32> {
    mic_wait_sample()?;
    Ok(mmio_r32(RX))
}

/// Discard non-audio high bits and retain the microphone sample payload.
pub unsafe fn mic_read_sample24() -> Result<u32, i32> {
    Ok(mic_read_raw()? & 0xffffff)
}

/// Stop on the first timeout and return the number of samples already captured.
pub unsafe fn mic_read_samples24(buf: &mut [u32]) -> usize {
    for (i, s) in buf.iter_mut().enumerate() {
        match mic_read_sample24() {
            Ok(v) => *s = v,
            Err(_) => return i,
        }
        delay(10);
    }
    buf.len()
}

/// Flush stale audio and drain batches of 24 samples into bounded static storage.
unsafe fn capture(count: usize) -> usize {
    if count == 0 || count > 160000 {
        return 0;
    }
    mmio_w32(STATUS, 1);
    let mut n = 0;
    while n < count {
        while mmio_r32(STATUS) >> 24 < 24 {}
        for _ in 0..24 {
            if n == count {
                break;
            }
            SAMPLES[n] = mmio_r32(RX);
            n += 1;
        }
        delay(10);
    }
    n
}

/// Capture first and print later so UART delays do not interrupt sampling.
pub unsafe fn s_call_mic_read_samples24(count: usize) -> usize {
    let n = capture(count);
    for i in 0..n {
        crate::s_print!("MIC[{}]={:x}\n", i, SAMPLES[i]);
    }
    crate::s_print!("MIC SAMPLE COUNT={}\n", n);
    n
}

/// Pack 128 samples per sector; zero-pad the final partial sector.
pub unsafe fn s_call_mic_write_samples24(count: usize, mut sector: u32) -> usize {
    let n = capture(count);
    if n == 0 {
        return 0;
    }
    for start in (0..n).step_by(128) {
        let mut b = [0u8; 512];
        for (j, chunk) in b.chunks_exact_mut(4).enumerate() {
            if start + j < n {
                chunk.copy_from_slice(&SAMPLES[start + j].to_le_bytes());
            }
        }
        if super::sdcard_api::sd_write_sector(sector, &b).is_err() {
            crate::s_print!("MIC WRITE ERROR sector={:x}\n", sector);
            return 0;
        }
        sector += 1;
    }
    crate::s_print!("MIC SAMPLE COUNT={}\n", n);
    n
}
