pub mod jpeg_headers;
#[cfg(any(target_arch = "riscv32", feature = "jpeg-host"))]
pub mod jpeg_view;
#[cfg(any(target_arch = "riscv32", feature = "jpeg-host"))]
pub mod tjpgd_port;

/// Synchronous packed RGB888 MCU sink. Commit only after decode and EOI succeed.
pub trait RgbSink {
    fn begin(&mut self, width: u32, height: u32) -> Result<(), i32>;
    fn rect(&mut self, x: u32, y: u32, width: u32, height: u32, rgb: &[u8]) -> Result<(), i32>;
}
