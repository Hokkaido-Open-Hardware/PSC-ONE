//! Baseline JPEG display with Rust-owned validation, file IO and LCD callbacks.
use super::RgbSink;
use super::{jpeg_headers::*, tjpgd_port::*};
use crate::fs::{fat32::BlockDevice, fat32_stream::File};

/// Stack ownership prevents overlapping sessions from sharing mutable decoder buffers.
pub fn probe_with_device(name: &str, dev: &mut impl BlockDevice) -> Result<Header, i32> {
    let mut file = File::default();
    let result = (|| {
        file.open(dev, name)?;
        check(&mut file, dev)
    })();
    file.close();
    result
}
pub fn decode_with_device<D: BlockDevice>(
    name: &str,
    dev: &mut D,
    sink: &mut dyn RgbSink,
) -> Result<(), i32> {
    let mut file = File::default();
    file.open(dev, name)?;
    let header = check(&mut file, dev)?;
    file.close();
    file.open(dev, name)?;
    let mut session = Session {
        dev,
        sink,
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
            input::<D>,
            work.as_mut_ptr().cast(),
            4096,
            (&mut session as *mut Session<'_, D>).cast(),
        );
        decoder_result(&session, rc)?;
        if decoder.width != session.header.width || decoder.height != session.header.height {
            return Err(FORMAT);
        }
        session
            .sink
            .begin(decoder.width as u32, decoder.height as u32)
            .map_err(|e| if e < 0 { e } else { FORMAT })?;
        let rc = jd_decomp(&mut decoder, output::<D>, 0);
        decoder_result(&session, rc)?;
        finish(&mut session)
    })();
    session.file.close();
    result
}

#[cfg(target_arch = "riscv32")]
pub fn probe(name: &str) -> Result<Header, i32> {
    probe_with_device(name, &mut crate::api::user::UserSd)
}
#[cfg(target_arch = "riscv32")]
pub fn decode_rgb(name: &str, sink: &mut dyn RgbSink) -> Result<(), i32> {
    decode_with_device(name, &mut crate::api::user::UserSd, sink)
}
#[cfg(target_arch = "riscv32")]
pub fn view(name: &str) -> Result<(), i32> {
    use crate::api::user::*;
    struct Lcd;
    impl RgbSink for Lcd {
        fn begin(&mut self, w: u32, h: u32) -> Result<(), i32> {
            print(format_args!("JPEG {w}x{h}\n"));
            if call_lcd_rgb888_begin() == 0 {
                Ok(())
            } else {
                Err(LCD)
            }
        }
        fn rect(&mut self, x: u32, y: u32, w: u32, h: u32, rgb: &[u8]) -> Result<(), i32> {
            if call_lcd_rgb888_rect(x, y, w, h, rgb) == 0 {
                Ok(())
            } else {
                Err(LCD)
            }
        }
    }
    decode_rgb(name, &mut Lcd)
}
