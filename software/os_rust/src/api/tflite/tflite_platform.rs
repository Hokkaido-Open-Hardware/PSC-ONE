//! tflite_platform.c: user-mode device calls, never direct NPU MMIO.
pub struct Platform;
#[cfg(target_arch = "riscv32")]
impl super::tflite_synap::Device for Platform {
    fn tile(
        &mut self,
        a: &[i8],
        b: &[i8],
        c: &mut [i32],
        m: usize,
        k: usize,
        n: usize,
        p: Option<&mut crate::api::sa_transfer::Profile>,
    ) -> i32 {
        crate::api::user::call_sa_matmul_int8_rect(a, b, c, m, k, n, p)
    }

    fn clock_us(&mut self) -> i32 {
        crate::api::user::call_timer_measure_read_us()
    }
}
