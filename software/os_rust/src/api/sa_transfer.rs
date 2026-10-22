//! api/sa_transfer.h
pub const RECT_FLAG: u32 = 0x40000000;
pub const PROFILE_FLAG: u32 = 0x80000000;
pub const fn dims(m: u32, k: u32, n: u32) -> u32 {
    (m << 16) | (n << 8) | k
}
#[repr(C)]
#[derive(Default, Clone, Copy)]
pub struct Profile {
    pub valid: i32,
    pub copy_in_us: u32,
    pub execute_us: u32,
    pub copy_out_us: u32,
}
