//! Bitmap values from drivers/font.h, stored verbatim as little-endian u16.
pub const FONT_WIDTH: usize = 12;
pub const FONT_HEIGHT: usize = 12;
const DATA: &[u8; 2304] = include_bytes!("../../assets/font12x12.le16");
/// Fetch one little-endian 12-bit glyph row; unsupported characters use the question mark.
pub fn row(ch: u8, y: usize) -> u16 {
    let ch = if (32..=126).contains(&ch) { ch } else { b'?' };
    let i = ((ch - 32) as usize * 12 + y) * 2;
    u16::from_le_bytes([DATA[i], DATA[i + 1]])
}
