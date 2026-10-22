//! lib/mulsi3.c
/// Compute the low 32 product bits using shift-and-add, including overflow wrap.
pub fn mulsi3(mut a: u32, mut b: u32) -> u32 {
    let mut r = 0u32;
    while b != 0 {
        if b & 1 != 0 {
            r = r.wrapping_add(a);
        }
        a <<= 1;
        b >>= 1;
    }
    r
}
