//! ABI boundary to the unchanged PSC MicroPython C archive.
//! NLR/longjmp stays inside C; these Rust callbacks never enter the VM.
use crate::{api::user::UserSd, fs::fat32::Fat32};
use core::ffi::{c_char, CStr};
extern "C" {
    fn psc_micropython_run() -> i32;
}

/// The interactive shell serializes VM entry with all other commands.
pub unsafe fn run() -> i32 {
    psc_micropython_run()
}

#[no_mangle]
/// MicroPython owns a writable 512-byte destination for the duration of the call.
pub unsafe extern "C" fn call_sd_read_buf_api(lba: u32, buffer: *mut u8) -> i32 {
    if buffer.is_null() {
        return -1;
    }
    crate::api::user::call_sd_read_buf_api(lba, &mut *buffer.cast::<[u8; 512]>())
        .err()
        .unwrap_or(0)
}

#[no_mangle]
/// MicroPython owns a readable 512-byte source for the duration of the call.
pub unsafe extern "C" fn call_sd_write_buf_api(lba: u32, buffer: *const u8) -> i32 {
    if buffer.is_null() {
        return -1;
    }
    crate::api::user::call_sd_write_buf_api(lba, &*buffer.cast::<[u8; 512]>())
        .err()
        .unwrap_or(0)
}

#[no_mangle]
pub extern "C" fn fat32_ls() {
    if let Err(e) = Fat32::mount(&mut UserSd).and_then(|fs| fs.ls(&mut UserSd)) {
        crate::api::user::print(format_args!("FAT32 error {e}\n"));
    }
}

#[no_mangle]
/// Preserve the C return convention and clear read_size even on errors.
pub unsafe extern "C" fn fat32_read(
    name: *const c_char,
    dst: *mut u8,
    max: u32,
    actual: *mut u32,
) -> i32 {
    if name.is_null() || dst.is_null() || actual.is_null() {
        return -1;
    }
    *actual = 0;
    let result = (|| {
        let name = CStr::from_ptr(name).to_str().map_err(|_| -1)?;
        let fs = Fat32::mount(&mut UserSd)?;
        let n = fs.read(
            &mut UserSd,
            name,
            core::slice::from_raw_parts_mut(dst, max as usize),
        )?;
        *actual = n as u32;
        Ok::<(), i32>(())
    })();
    result.err().unwrap_or(0)
}
