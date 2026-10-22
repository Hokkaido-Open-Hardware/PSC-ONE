//! Baseline JPEG display with Rust-owned validation, file IO and LCD callbacks.
use super::{jpeg_headers::*, tjpgd_port::*};
use crate::{api::user::*, fs::fat32_stream::File};

/// Stack ownership prevents overlapping sessions from sharing mutable decoder buffers.
pub fn view(name: &str) -> Result<(), i32> {
    let mut file = File::default();
    file.open(&mut UserSd, name)?;
    let header = check(&mut file, &mut UserSd)?;
    file.close();
    file.open(&mut UserSd, name)?;
    let mut session = Session {
        file,
        header,
        error: 0,
        eoi: false,
        entropy_ff: false,
    };
    // u32 storage provides the alignment required by the C decoder's work allocator.
    let mut work = [0u32; 1024];
    let mut decoder: Decoder = unsafe { core::mem::zeroed() };
    let result = (|| unsafe {
        let rc = jd_prepare(
            &mut decoder,
            input,
            work.as_mut_ptr().cast(),
            4096,
            (&mut session as *mut Session).cast(),
        );
        decoder_result(&session, rc)?;
        if decoder.width != session.header.width || decoder.height != session.header.height {
            return Err(FORMAT);
        }
        print(format_args!("JPEG {}x{}\n", decoder.width, decoder.height));
        if call_lcd_rgb888_begin() != 0 {
            return Err(LCD);
        }
        decoder_result(&session, jd_decomp(&mut decoder, output, 0))?;
        finish(&mut session)
    })();
    session.file.close();
    result
}
