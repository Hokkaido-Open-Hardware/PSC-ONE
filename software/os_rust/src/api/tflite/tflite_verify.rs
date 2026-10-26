//! Bounds/alignment verifier interpreting Rust Schema v3 descriptors.
//! All scalar reads are bytewise; recursive tables are capped at depth 16 and
//! 65536 visits, matching the current C analyzer's verifier budget.
use super::{
    tflite_inspect::{Reader, FORMAT},
    tflite_schema::{MODEL, TABLES, UNIONS},
};
pub(super) struct Field(pub usize, pub u8, pub usize);
struct Verifier<'a> {
    r: Reader<'a>,
    visits: usize,
}
impl Verifier<'_> {
    fn table(&mut self, t: usize, kind: usize, depth: usize) -> Result<(), i32> {
        self.visits += 1;
        if depth > 16 || self.visits > 65536 || t & 3 != 0 {
            return Err(FORMAT);
        }
        let displacement = self.r.u32(t)? as i32 as i64;
        let vt = t as i64 - displacement;
        if vt < 0 || vt & 1 != 0 {
            return Err(FORMAT);
        }
        // Validate the entire vtable/object even when this table has no fields.
        self.r.field(t, 4, 0)?;
        for &Field(id, kind, target) in TABLES.get(kind).ok_or(FORMAT)?.iter() {
            let width = if kind <= 8 { kind as usize } else { 4 };
            let Some(p) = self.r.field(t, id, width)? else {
                continue;
            };
            if p % width != 0 {
                return Err(FORMAT);
            }
            if kind <= 8 {
                continue;
            }
            let child = self.r.offset(p)?;
            match kind {
                11 | 12 | 14 | 18 => {
                    let width = kind as usize - 10;
                    if child & 3 != 0 || (child + 4) % width != 0 {
                        return Err(FORMAT);
                    }
                    let n = self.r.u32(child)? as usize;
                    self.r
                        .bytes(child + 4, n.checked_mul(width).ok_or(FORMAT)?)?;
                }
                30 => {
                    if child & 3 != 0 {
                        return Err(FORMAT);
                    }
                    let n = self.r.u32(child)? as usize;
                    let s = self.r.bytes(child + 4, n.checked_add(1).ok_or(FORMAT)?)?;
                    if s[n] != 0 {
                        return Err(FORMAT);
                    }
                }
                31 => self.table(child, target, depth + 1)?,
                32 => {
                    if child & 3 != 0 {
                        return Err(FORMAT);
                    }
                    let n = self.r.u32(child)? as usize;
                    self.r.bytes(child + 4, n.checked_mul(4).ok_or(FORMAT)?)?;
                    for i in 0..n {
                        let p = self.r.offset(child + 4 + i * 4)?;
                        self.table(p, target, depth + 1)?;
                    }
                }
                34 => {
                    let tag = self.r.byte(t, id - 2)?;
                    if tag != 0 {
                        let table = UNIONS
                            .get(target)
                            .ok_or(FORMAT)?
                            .iter()
                            .find(|(v, _)| *v == tag)
                            .ok_or(FORMAT)?
                            .1;
                        self.table(child, table, depth + 1)?;
                    }
                }
                _ => return Err(FORMAT),
            }
        }
        Ok(())
    }
}
pub(super) fn verify(bytes: &[u8]) -> Result<(), i32> {
    let r = Reader(bytes);
    let root = r.offset(0)?;
    Verifier { r, visits: 0 }.table(root, MODEL, 1)
}
