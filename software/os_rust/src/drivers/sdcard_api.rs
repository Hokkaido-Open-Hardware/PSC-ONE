//! drivers/sdcard_api.c/.h; 128 word reads but 512 byte-valued word writes.
use crate::common::{delay, mmio_r32, mmio_w32};
const DATA: u32 = 0x10006000;
const SECTOR: u32 = 0x10006004;
const CTRL: u32 = 0x10006008;
/// Poll until the selected status condition changes; retain the caller-specific timeout code.
unsafe fn wait(mask: u32, set: bool, error: i32) -> Result<(), i32> {
    let mut timeout = 100000;
    while (mmio_r32(CTRL) & mask != 0) == set {
        timeout -= 1;
        if timeout == 0 {
            return Err(error);
        }
    }
    Ok(())
}

/// Read a complete 512-byte sector. Completion must precede draining the word FIFO.
pub unsafe fn sd_read_sector(sector: u32, buf: &mut [u8; 512]) -> Result<(), i32> {
    // Flush stale FIFO contents before deciding whether card initialization is needed.
    mmio_w32(CTRL, 4);
    delay(100);
    if mmio_r32(CTRL) & 4 == 0 {
        mmio_w32(CTRL, 1);
    }
    wait(2, true, -1)?;
    delay(100);
    mmio_w32(SECTOR, sector);
    mmio_w32(CTRL, 2);
    // READY must first fall (command accepted) and then rise (full sector received).
    // FIFO nonempty alone does not guarantee that a four-byte DATA read is valid.
    wait(4, true, -2)?;
    wait(4, false, -2)?;
    delay(50);
    for chunk in buf.chunks_exact_mut(4) {
        wait(8, true, -3)?;
        // One MMIO read pops four bytes, with the oldest byte in bits 7:0.
        chunk.copy_from_slice(&mmio_r32(DATA).to_le_bytes());
    }
    Ok(())
}

/// Fill the byte-wide transmit FIFO through word MMIO, then wait for the write command.
unsafe fn sd_write_once(sector: u32, buf: &[u8; 512]) -> Result<(), i32> {
    mmio_w32(CTRL, 4);
    delay(100);
    // The write FIFO differs from the read FIFO: each word store pushes one byte.
    for &b in buf {
        mmio_w32(DATA, b as u32);
    }
    if mmio_r32(CTRL) & 4 == 0 {
        mmio_w32(CTRL, 1);
    }
    wait(2, true, -1)?;
    delay(100);
    mmio_w32(SECTOR, sector);
    mmio_w32(CTRL, 16);
    delay(100);
    wait(4, false, -2)?;
    delay(50);
    Ok(())
}

/// Calculate the SD data CRC with polynomial 0x1021 and an initial value of zero.
pub fn sd_crc16(buf: &[u8]) -> u16 {
    let mut crc = 0u16;
    for &b in buf {
        crc ^= (b as u16) << 8;
        for _ in 0..8 {
            crc = if crc & 0x8000 != 0 {
                (crc << 1) ^ 0x1021
            } else {
                crc << 1
            };
        }
    }
    crc
}

/// Retry up to three times and accept data only when software and hardware CRCs agree.
pub unsafe fn sd_read_sector_checked(sector: u32, buf: &mut [u8; 512]) -> Result<(), i32> {
    for _ in 0..3 {
        if sd_read_sector(sector, buf).is_ok() && sd_crc16(buf) == (mmio_r32(CTRL) >> 16) as u16 {
            return Ok(());
        }
    }
    Err(-4)
}

/// Read back the whole sector after writing; command acceptance alone is not success.
unsafe fn sd_write_verified(sector: u32, buf: &[u8; 512], quiet: bool) -> Result<(), i32> {
    for retry in 0..3 {
        if sd_write_once(sector, buf).is_err() {
            if !quiet {
                crate::s_print!("WRITE FAIL retry={}\n", retry);
            }
            continue;
        }
        let mut verify = [0; 512];
        if sd_read_sector(sector, &mut verify).is_err() {
            if !quiet {
                crate::s_print!("VERIFY READ ERROR\n");
            }
            continue;
        }
        if verify == *buf {
            return Ok(());
        }
        if !quiet {
            crate::s_print!("VERIFY ERROR sector={:x}\n", sector);
        }
    }
    Err(-1)
}

/// Write with readback verification and diagnostic UART messages.
pub unsafe fn sd_write_sector(sector: u32, buf: &[u8; 512]) -> Result<(), i32> {
    sd_write_verified(sector, buf, false)
}

/// Use the same verification without injecting text into a binary console protocol.
pub unsafe fn sd_write_sector_quiet(sector: u32, buf: &[u8; 512]) -> Result<(), i32> {
    sd_write_verified(sector, buf, true)
}

/// Expose a diagnostic read: report CRC status and dump the final buffer.
pub unsafe fn s_call_sdcard_read_api(sector: u32) {
    let mut buf = [0; 512];
    let result = sd_read_sector_checked(sector, &mut buf);
    crate::s_print!(
        "CRC {}\n",
        if result.is_ok() {
            "OK"
        } else {
            "FAILED (final)"
        }
    );
    crate::common::hexdump(&buf, 0);
}

/// Run the shell write diagnostic with up to three command attempts.
pub unsafe fn s_call_sdcard_write_api(sector: u32, buf: &[u8; 512]) -> Result<(), i32> {
    crate::s_print!("WRITE START\n");
    for retry in 0..3 {
        if sd_write_once(sector, buf).is_ok() {
            crate::s_print!("WRITE END\n");
            return Ok(());
        }
        crate::s_print!("WRITE FAIL retry={}\n", retry);
    }
    crate::s_print!("WRITE ERROR\n");
    Err(-1)
}
