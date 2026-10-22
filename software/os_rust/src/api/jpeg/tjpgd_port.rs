//! TJpgDec ABI for JD_FASTDECODE=1, JD_FORMAT=0 and RGB888 tiles.
use super::jpeg_headers::*;
use crate::{api::user::*, fs::fat32_stream::File};
use core::ffi::c_void;
#[repr(C)]
pub struct Rect {
    left: u16,
    right: u16,
    top: u16,
    bottom: u16,
}
#[repr(C)]
pub struct Decoder {
    dctr: usize,
    dptr: *mut u8,
    inbuf: *mut u8,
    dbit: u8,
    scale: u8,
    msx: u8,
    msy: u8,
    qtid: [u8; 3],
    ncomp: u8,
    dcv: [i16; 3],
    nrst: u16,
    pub width: u16,
    pub height: u16,
    huffbits: [[*mut u8; 2]; 2],
    huffcode: [[*mut u16; 2]; 2],
    huffdata: [[*mut u8; 2]; 2],
    qttbl: [*mut i32; 4],
    wreg: u32,
    marker: u8,
    workbuf: *mut c_void,
    mcubuf: *mut i16,
    pool: *mut c_void,
    sz_pool: usize,
    infunc: Option<unsafe extern "C" fn(*mut Decoder, *mut u8, usize) -> usize>,
    pub device: *mut c_void,
    swap: u8,
}
extern "C" {
    pub fn jd_prepare(
        jd: *mut Decoder,
        input: unsafe extern "C" fn(*mut Decoder, *mut u8, usize) -> usize,
        pool: *mut c_void,
        size: usize,
        device: *mut c_void,
    ) -> i32;
    pub fn jd_decomp(
        jd: *mut Decoder,
        output: unsafe extern "C" fn(*mut Decoder, *mut c_void, *mut Rect) -> i32,
        scale: u8,
    ) -> i32;
}
pub struct Session {
    pub file: File,
    pub header: Header,
    pub error: i32,
    pub eoi: bool,
    pub entropy_ff: bool,
}

/// Track read-ahead too: the upstream decoder stops at MCU count, not necessarily EOI.
unsafe fn input_session(s: &mut Session, buffer: *mut u8, count: usize) -> usize {
    if s.error != 0 {
        return 0;
    }
    let pos = s.file.file_pos;
    let mut got = 0;
    let result = if buffer.is_null() {
        s.file.skip(&mut UserSd, count as u32, &mut got)
    } else {
        s.file.read(
            &mut UserSd,
            core::slice::from_raw_parts_mut(buffer, count),
            &mut got,
        )
    };
    if let Err(e) = result {
        s.error = e;
        return 0;
    }
    if !buffer.is_null() {
        for (i, &byte) in core::slice::from_raw_parts(buffer, got as usize)
            .iter()
            .enumerate()
        {
            if pos + (i as u32) < s.header.scan_offset || s.eoi {
                continue;
            }
            if s.entropy_ff {
                if byte == 0xd9 {
                    s.eoi = true;
                } else if byte != 0 && byte != 255 && !(0xd0..=0xd7).contains(&byte) {
                    s.error = FORMAT;
                }
            }
            s.entropy_ff = byte == 255;
        }
    }
    if s.error != 0 {
        0
    } else {
        got as usize
    }
}

/// C calls synchronously; the session and scratch storage outlive both decoder calls.
pub unsafe extern "C" fn input(jd: *mut Decoder, buffer: *mut u8, count: usize) -> usize {
    input_session(&mut *((*jd).device.cast::<Session>()), buffer, count)
}

/// Validate rectangle bounds before constructing a Rust slice over the C RGB buffer.
pub unsafe extern "C" fn output(jd: *mut Decoder, bitmap: *mut c_void, rect: *mut Rect) -> i32 {
    let s = &mut *((*jd).device.cast::<Session>());
    if s.error != 0 {
        return 0;
    }
    let r = &*rect;
    if r.right < r.left
        || r.bottom < r.top
        || r.right >= s.header.width
        || r.bottom >= s.header.height
    {
        s.error = FORMAT;
        return 0;
    }
    let w = (r.right - r.left + 1) as u32;
    let h = (r.bottom - r.top + 1) as u32;
    if w > 16 || h > 16 {
        s.error = FORMAT;
        return 0;
    }
    let rgb = core::slice::from_raw_parts(bitmap.cast::<u8>(), (w * h * 3) as usize);
    if call_lcd_rgb888_rect(r.left as u32, r.top as u32, w, h, rgb) != 0 {
        s.error = LCD;
        return 0;
    }
    1
}

/// Reject a truncated entropy stream even when all expected MCUs were decoded.
pub fn finish(s: &mut Session) -> Result<(), i32> {
    let mut tail = [0; 32];
    while !s.eoi && s.error == 0 {
        if unsafe { input_session(s, tail.as_mut_ptr(), tail.len()) } == 0 {
            return Err(if s.error != 0 { s.error } else { EOF });
        }
    }
    if s.error != 0 {
        Err(s.error)
    } else {
        Ok(())
    }
}

pub fn decoder_result(s: &Session, result: i32) -> Result<(), i32> {
    if s.error != 0 {
        return Err(s.error);
    }
    match result {
        0 => Ok(()),
        2 => Err(EOF),
        3 => Err(WORK),
        4 | 7 | 8 => Err(UNSUPPORTED),
        _ => Err(FORMAT),
    }
}

// Verify both sides whenever the vendor/configuration changes; see verify_images.py.
const _: () = assert!(core::mem::size_of::<Decoder>() == 132);
const _: () = assert!(core::mem::offset_of!(Decoder, device) == 124);
const _: () = assert!(core::mem::offset_of!(Decoder, width) == 28);
const _: () = assert!(core::mem::size_of::<Rect>() == 8);
