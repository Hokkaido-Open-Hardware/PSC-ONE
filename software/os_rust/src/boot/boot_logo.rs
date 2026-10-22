//! Lossless RGB111 RLE asset from boot/boot_logo.h.
pub static DATA: &[u8] = include_bytes!("../../assets/boot_logo.rle16");
/// Decode each little-endian run into a pixel count and its three RGB bits.
pub fn runs() -> impl Iterator<Item = (usize, u8)> {
    DATA.chunks_exact(2).map(|b| {
        let v = u16::from_le_bytes([b[0], b[1]]);
        ((v >> 3) as usize, (v & 7) as u8)
    })
}
