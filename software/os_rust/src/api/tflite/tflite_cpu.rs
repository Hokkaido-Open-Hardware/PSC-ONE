//! Rust CPU kernels and per-operator validation for the C PSC-OS numerical contract.
use super::{
    tflite_graph::{supported, Graph, Plan},
    tflite_inspect::{bias_scale_matches, GRAPH, UNSUPPORTED},
    tflite_quant::*,
    tflite_runtime::Backend,
    tflite_synap::Device,
};
#[derive(Default)]
pub(crate) struct Op {
    pub kind: i32,
    pub x: usize,
    pub y: usize,
    pub w: usize,
    pub bias: i32,
    pub ids: [i32; 16],
    pub count: usize,
    pub input: [usize; 4],
    pub output: [usize; 4],
    pub filter: [usize; 4],
    pub stride: [usize; 2],
    pub dilation: [usize; 2],
    pub pad: [usize; 2],
    pub zero: i32,
    pub second_zero: i32,
    pub out_zero: i32,
    pub min: i32,
    pub max: i32,
    pub mult: [i32; 3],
    pub shift: [i32; 3],
    pub ba: [usize; 4],
    pub bb: [usize; 4],
    pub axis: usize,
    pub aux: [usize; 4],
    pub begin: [usize; 4],
    pub concat: [usize; 16],
    pub width: usize,
    pub xtype: u8,
    pub xs: f32,
    pub ys: f32,
    pub beta: f32,
    pub params: usize,
}
fn require(ok: bool) -> Result<(), i32> {
    if ok {
        Ok(())
    } else {
        Err(GRAPH)
    }
}
fn support(ok: bool) -> Result<(), i32> {
    if ok {
        Ok(())
    } else {
        Err(UNSUPPORTED)
    }
}
fn spatial(
    input: usize,
    filter: usize,
    dilation: usize,
    stride: usize,
    padding: u8,
    out: usize,
) -> Result<usize, i32> {
    require(filter > 0 && dilation > 0 && stride > 0)?;
    let eff = (filter as u64 - 1) * dilation as u64 + 1;
    require(eff <= i32::MAX as u64 && out as u64 * stride as u64 + eff <= i32::MAX as u64)?;
    let (n, pad) = match padding {
        0 => {
            let n = (input as u64 + stride as u64 - 1) / stride as u64;
            (
                n,
                ((n - 1) * stride as u64 + eff).saturating_sub(input as u64) / 2,
            )
        }
        1 => (
            if input as u64 >= eff {
                (input as u64 - eff) / stride as u64 + 1
            } else {
                0
            },
            0,
        ),
        _ => return Err(UNSUPPORTED),
    };
    require(n == out as u64)?;
    Ok(pad as usize)
}
fn activation(op: &mut Op, a: u8) -> Result<(), i32> {
    op.min = -128;
    op.max = 127;
    let quant = |v: f64| -> i32 {
        (round(v / op.ys as f64) + op.out_zero as f64)
            .max(-128.0)
            .min(127.0) as i32
    };
    match a {
        0 => {}
        1 => op.min = op.out_zero,
        2 => {
            op.min = quant(-1.0);
            op.max = quant(1.0)
        }
        3 => {
            op.min = op.out_zero;
            op.max = quant(6.0)
        }
        _ => return Err(UNSUPPORTED),
    }
    Ok(())
}
fn count(n: usize, expected: usize) -> Result<(), i32> {
    require(n == expected)
}
pub(crate) fn compile(g: &Graph<'_>, i: usize) -> Result<Op, i32> {
    let r = g.reader();
    let (table, k, version) = g.operator(i)?;
    support(supported(k) && (1..=4).contains(&version))?;
    for (id, w) in [(14, 1), (18, 1), (20, 4)] {
        support(r.vector(table, id, w)?.1 == 0)?;
    }
    for id in [22, 24] {
        if let Some(p) = r.field(table, id, 8)? {
            support(r.i64(p)? == 0)?;
        }
    }
    support(r.byte(table, 26)? == 0)?;
    let (a, na) = r.vector(table, 6, 4)?;
    let (y, ny) = r.vector(table, 8, 4)?;
    require(na > 0 && ny == 1)?;
    support(na <= 16)?;
    let mut o = Op {
        kind: k,
        x: r.index(a, g.info.tensors, 0)?,
        y: r.index(y, g.info.tensors, 0)?,
        count: na,
        bias: -1,
        ids: [-1; 16],
        ..Op::default()
    };
    for j in 0..na {
        o.ids[j] = r.u32(a + 4 * j)? as i32;
    }
    let x = g.tensor(o.x)?;
    let y = g.tensor(o.y)?;
    o.input = x.shape()?;
    o.output = y.shape()?;
    o.xtype = x.kind;
    o.width = if x.kind == 9 { 1 } else { 4 };
    o.xs = x.scale;
    o.ys = y.scale;
    o.zero = x.zero;
    o.out_zero = y.zero;
    let tag = r.byte(table, 10)?;
    let opt = r.indirect(table, 12)?;
    let options = |expected: u8| -> Result<usize, i32> {
        require(tag == expected)?;
        opt.ok_or(GRAPH)
    };
    let optional = |expected: u8| -> Result<(), i32> { require(tag == expected || tag == 0) };
    if !matches!(k, 0 | 3 | 9 | 14 | 17 | 18 | 41) {
        support(matches!(x.kind, 0 | 2 | 9) && matches!(y.kind, 0 | 2 | 9))?;
        if x.kind == 9 {
            support(x.affine(false))?;
        }
        if y.kind == 9 {
            support(y.affine(false))?;
        }
        if matches!(k, 6 | 25 | 114) {
            count(na, 1)?;
            require(x.same_shape(y))?;
            match k {
                114 => {
                    optional(89)?;
                    support(y.kind == 9 && matches!(x.kind, 0 | 9))?;
                    if x.kind == 9 {
                        (o.mult[0], o.shift[0]) = quantize(o.xs as f64 / o.ys as f64)?;
                        support(255i64 * (1i64 << o.shift[0].max(0)) <= i32::MAX as i64 - 128)?;
                    }
                }
                6 => {
                    optional(38)?;
                    support(x.kind == 9 && y.kind == 0)?;
                }
                _ => {
                    let v = options(9)?;
                    support(
                        x.rank > 0
                            && x.kind == 9
                            && y.kind == 9
                            && o.ys == 1.0 / 256.0
                            && o.out_zero == -128
                            && o.output[3] <= 511,
                    )?;
                    o.beta = f32::from_bits(r.scalar(v, 4, 0)?);
                    softmax_params(o.beta as f64, o.xs as f64)?;
                    o.params = 1024;
                }
            }
            return Ok(o);
        }
        support(x.same_quant(y))?;
        if k == 2 {
            let v = options(10)?;
            support(r.byte(v, 6)? == 0)?;
            let mut axis = r.scalar(v, 4, 0)? as i32;
            if axis < 0 {
                axis += x.rank as i32;
            }
            require(axis >= 0 && (axis as usize) < x.rank && x.rank == y.rank)?;
            let axis = axis as usize;
            o.axis = 4 - x.rank + axis;
            let mut sum = 0usize;
            for j in 0..na {
                require(o.ids[j] >= 0)?;
                let t = g.tensor(o.ids[j] as usize)?;
                support(t.same_quant(x) && t.rank == x.rank)?;
                for d in 0..x.rank {
                    if d != axis {
                        require(t.dims[d] == y.dims[d])?;
                    }
                }
                o.concat[j] = t.dims[axis];
                sum = sum.checked_add(t.dims[axis]).ok_or(GRAPH)?;
            }
            require(sum == y.dims[axis])?;
            return Ok(o);
        }
        if k == 22 {
            require(na <= 2 && x.bytes == y.bytes)?;
            optional(17)?;
            let (raw, nr) = if na == 2 && o.ids[1] >= 0 {
                let t = g.control(o.ids[1])?;
                support(t.rank == 1)?;
                (t.data, t.bytes / 4)
            } else {
                r.vector(opt.ok_or(GRAPH)?, 4, 4)?
            };
            require(nr == y.rank)?;
            let mut infer = 0;
            for d in 0..nr {
                let dim = r.u32(raw + 4 * d)? as i32;
                if dim == -1 {
                    infer += 1;
                    require(infer <= 1)?;
                } else {
                    require(dim > 0 && dim as usize == y.dims[d])?;
                }
            }
            return Ok(o);
        }
        count(na, if k == 65 { 3 } else { 2 })?;
        let control = g.control(o.ids[1])?;
        match k {
            39 => {
                optional(26)?;
                require(control.rank == 1 && control.bytes == x.rank * 4 && y.rank == x.rank)?;
                o.aux = [0, 1, 2, 3];
                let mut seen = 0;
                for d in 0..x.rank {
                    let axis = g.integer(control, d)?;
                    require(axis >= 0 && (axis as usize) < x.rank && (seen & (1 << axis)) == 0)?;
                    seen |= 1 << axis;
                    require(y.dims[d] == x.dims[axis as usize])?;
                    o.aux[4 - x.rank + d] = 4 - x.rank + axis as usize;
                }
            }
            34 => {
                optional(22)?;
                require(
                    control.rank == 2
                        && control.dims[0] == x.rank
                        && control.dims[1] == 2
                        && y.rank == x.rank,
                )?;
                for d in 0..x.rank {
                    let b = g.integer(control, 2 * d)?;
                    let e = g.integer(control, 2 * d + 1)?;
                    require(
                        b >= 0
                            && e >= 0
                            && b as u64 + e as u64 + x.dims[d] as u64 == y.dims[d] as u64,
                    )?;
                    o.begin[4 - x.rank + d] = b as usize;
                }
            }
            65 => {
                optional(48)?;
                let sizes = g.control(o.ids[2])?;
                require(
                    control.rank == 1
                        && sizes.rank == 1
                        && control.bytes == x.rank * 4
                        && sizes.bytes == x.rank * 4
                        && y.rank == x.rank,
                )?;
                for d in 0..x.rank {
                    let b = g.integer(control, d)?;
                    let mut n = g.integer(sizes, d)?;
                    require(b >= 0 && (b as usize) < x.dims[d])?;
                    if n == -1 {
                        n = (x.dims[d] - b as usize) as i32;
                    }
                    require(
                        n > 0 && n as usize <= x.dims[d] - b as usize && n as usize == y.dims[d],
                    )?;
                    o.begin[4 - x.rank + d] = b as usize;
                }
            }
            97 => {
                let v = options(74)?;
                require(
                    x.rank == 4
                        && y.rank == 4
                        && control.rank == 1
                        && control.bytes == 8
                        && o.input[0] == o.output[0]
                        && o.input[3] == o.output[3]
                        && g.integer(control, 0)? == o.output[1] as i32
                        && g.integer(control, 1)? == o.output[2] as i32,
                )?;
                o.aux[0] = r.byte(v, 4)? as usize;
                o.aux[1] = r.byte(v, 6)? as usize;
                support(o.aux[0] <= 1 && o.aux[1] <= 1 && o.aux[0] + o.aux[1] <= 1)?;
                support(
                    [o.input[1], o.input[2], o.output[1], o.output[2]]
                        .iter()
                        .all(|n| *n <= 1 << 24),
                )?;
            }
            _ => return Err(UNSUPPORTED),
        }
        return Ok(o);
    }
    support(x.affine(false) && y.affine(false))?;
    let mut act = 0;
    if k == 3 || k == 9 {
        require((2..=3).contains(&na) && o.ids[1] >= 0)?;
        o.w = o.ids[1] as usize;
        if na == 3 {
            o.bias = o.ids[2];
        }
        let w = g.tensor(o.w)?;
        support(w.affine(k == 3) && w.data != 0)?;
        if k == 3 {
            let v = options(1)?;
            require(x.rank == 4 && y.rank == 4 && w.rank == 4)?;
            o.filter = w.shape()?;
            o.stride = [r.scalar(v, 8, 0)? as usize, r.scalar(v, 6, 0)? as usize];
            o.dilation = [r.scalar(v, 14, 1)? as usize, r.scalar(v, 12, 1)? as usize];
            act = r.byte(v, 10)?;
            support(o.stride.iter().all(|v| matches!(v, 1 | 2)))?;
            require(
                o.input[0] == o.output[0]
                    && o.input[3] == o.filter[3]
                    && o.output[3] == o.filter[0],
            )?;
            for d in 0..2 {
                o.pad[d] = spatial(
                    o.input[d + 1],
                    o.filter[d + 1],
                    o.dilation[d],
                    o.stride[d],
                    r.byte(v, 4)?,
                    o.output[d + 1],
                )?;
            }
        } else {
            let v = options(8)?;
            support(
                version == 4 && r.byte(v, 6)? == 0 && r.byte(v, 8)? == 0 && r.byte(v, 10)? == 0,
            )?;
            require(w.rank == 2 && y.rank == 2)?;
            let depth = w.dims[1];
            let channels = w.dims[0];
            require(
                x.bytes % depth == 0
                    && y.bytes as u64 == (x.bytes / depth) as u64 * channels as u64
                    && y.dims[0] == x.bytes / depth
                    && y.dims[1] == channels,
            )?;
            o.input = [x.bytes / depth, 1, 1, depth];
            o.output = [o.input[0], 1, 1, channels];
            o.filter = [channels, 1, 1, depth];
            o.stride = [1, 1];
            o.dilation = [1, 1];
            act = r.byte(v, 4)?;
        }
        let channels = o.filter[0];
        require(w.nq == 1 || (w.nq == channels && w.axis == 0))?;
        for c in 0..w.nq {
            support(g.quant(w, c)?.1 == 0)?;
        }
        if o.bias >= 0 {
            let b = g.tensor(o.bias as usize)?;
            require(
                b.kind == 2
                    && b.data != 0
                    && b.rank == 1
                    && b.dims[0] == channels
                    && !b.details
                    && (b.nq == 1 || b.nq == channels)
                    && (b.nq == 1 || b.axis == 0),
            )?;
        }
        o.params = channels.checked_mul(8).ok_or(GRAPH)?;
        for c in 0..channels {
            channel(g, &o, c)?;
        }
    } else if matches!(k, 0 | 18 | 41) {
        count(na, 2)?;
        require(o.ids[1] >= 0)?;
        o.w = o.ids[1] as usize;
        let b = g.tensor(o.w)?;
        support(b.affine(false))?;
        let bs = b.shape()?;
        require(y.rank == x.rank.max(b.rank))?;
        let (mut sa, mut sb) = (1, 1);
        for d in (0..4).rev() {
            require(o.input[d] == bs[d] || o.input[d] == 1 || bs[d] == 1)?;
            require(o.output[d] == o.input[d].max(bs[d]))?;
            o.ba[d] = if o.input[d] == 1 { 0 } else { sa };
            o.bb[d] = if bs[d] == 1 { 0 } else { sb };
            sa *= o.input[d];
            sb *= bs[d];
        }
        o.second_zero = b.zero;
        let v = options(match k {
            0 => 11,
            18 => 21,
            _ => 28,
        })?;
        act = r.byte(v, 4)?;
        if k == 18 {
            (o.mult[2], o.shift[2]) = quantize(o.xs as f64 * b.scale as f64 / o.ys as f64)?;
            support(65025i64 * (1i64 << o.shift[2].max(0)) <= i32::MAX as i64 - 128)?;
        } else {
            let twice = 2.0 * (o.xs.max(b.scale) as f64);
            (o.mult[0], o.shift[0]) = quantize(o.xs as f64 / twice)?;
            (o.mult[1], o.shift[1]) = quantize(b.scale as f64 / twice)?;
            (o.mult[2], o.shift[2]) = quantize(twice / (1048576.0 * o.ys as f64))?;
            support(o.shift.iter().all(|s| *s <= 0))?;
        }
    } else if k == 14 {
        count(na, 1)?;
        require(tag == 0 && x.same_shape(y))?;
        support(o.ys == 1.0 / 256.0 && o.out_zero == -128)?;
        logistic_params(o.xs as f64, o.zero)?;
        o.params = 256;
    } else {
        count(na, 1)?;
        let v = options(5)?;
        require(x.rank == 4 && y.rank == 4)?;
        support(o.xs == o.ys && o.zero == o.out_zero)?;
        o.filter = [
            1,
            r.scalar(v, 12, 0)? as usize,
            r.scalar(v, 10, 0)? as usize,
            1,
        ];
        o.stride = [r.scalar(v, 8, 0)? as usize, r.scalar(v, 6, 0)? as usize];
        act = r.byte(v, 14)?;
        require(o.input[0] == o.output[0] && o.input[3] == o.output[3])?;
        for d in 0..2 {
            o.pad[d] = spatial(
                o.input[d + 1],
                o.filter[d + 1],
                1,
                o.stride[d],
                r.byte(v, 4)?,
                o.output[d + 1],
            )?;
        }
    }
    activation(&mut o, act)?;
    Ok(o)
}
fn channel(g: &Graph<'_>, o: &Op, c: usize) -> Result<(i32, i32), i32> {
    let w = g.tensor(o.w)?;
    let (ws, _) = g.quant(w, c)?;
    let (mult, shift) = quantize(o.xs as f64 * ws as f64 / o.ys as f64)?;
    let bias = if o.bias >= 0 {
        let b = g.tensor(o.bias as usize)?;
        let (bs, bz) = g.quant(b, c)?;
        require(bias_scale_matches(o.xs, ws, bs) && bz == 0)?;
        g.integer(b, c)? as i64
    } else {
        0
    };
    let depth = o.filter[1] as i64 * o.filter[2] as i64 * o.filter[3] as i64;
    let bound = depth * 255 * 128;
    let factor = 1i64 << shift.max(0);
    require(
        bound <= i32::MAX as i64
            && bias - bound >= (i32::MIN as i64 + 128) / factor
            && bias + bound <= (i32::MAX as i64 - 128) / factor,
    )?;
    Ok((mult, shift))
}
pub(crate) fn parameters(g: &Graph<'_>, o: &Op, dst: &mut [u8]) -> Result<(), i32> {
    match o.kind {
        3 | 9 => {
            for c in 0..o.filter[0] {
                let (m, s) = channel(g, o, c)?;
                dst[c * 4..c * 4 + 4].copy_from_slice(&m.to_le_bytes());
                let p = (o.filter[0] + c) * 4;
                dst[p..p + 4].copy_from_slice(&s.to_le_bytes());
            }
        }
        14 => {
            let lut = logistic_lut(o.xs as f64, o.zero)?;
            for (d, s) in dst.iter_mut().zip(lut) {
                *d = s as u8;
            }
        }
        25 => {
            let lut = softmax_lut(o.beta as f64, o.xs as f64)?;
            for (d, s) in dst.chunks_exact_mut(4).zip(lut) {
                d.copy_from_slice(&s.to_le_bytes());
            }
        }
        _ => {}
    }
    Ok(())
}

/// CPU v1's signed dot-product instruction; other firmware builds fall back to CPU.
#[inline]
pub(crate) fn dot4(a: [u8; 4], b: [u8; 4]) -> i32 {
    #[cfg(all(target_arch = "riscv32", feature = "pulp"))]
    unsafe {
        let result: i32;
        core::arch::asm!(".insn r 0x7b, 1, 0x48, {d}, {a}, {b}",d=out(reg) result,a=in(reg) u32::from_le_bytes(a),b=in(reg) u32::from_le_bytes(b),options(nomem,nostack));
        return result;
    }
    #[cfg(not(all(target_arch = "riscv32", feature = "pulp")))]
    {
        a.iter()
            .zip(b)
            .map(|(x, y)| *x as i8 as i32 * y as i8 as i32)
            .sum()
    }
}
pub(crate) fn select(o: &Op, b: Backend) -> Backend {
    if matches!(o.kind, 3 | 9) {
        if b == Backend::Synap {
            return b;
        }
        if b == Backend::Auto
            && o.kind == 9
            && matches!(o.input[0], 16 | 32)
            && o.input[0] == o.input[3]
            && o.input[0] == o.output[3]
        {
            return Backend::Synap;
        }
        if matches!(b, Backend::Pulp | Backend::Auto) && cfg!(feature = "pulp") {
            return Backend::Pulp;
        }
    }
    Backend::Cpu
}
struct Memory<'a> {
    model: &'a [u8],
    plans: &'a [Plan],
    arena: &'a mut [u8],
}
impl Memory<'_> {
    fn byte(&self, t: usize, i: usize) -> u8 {
        let p = self.plans[t];
        debug_assert!(i < p.bytes);
        if p.data != 0 {
            self.model[p.data + i]
        } else {
            self.arena[p.offset + i]
        }
    }
    fn signed(&self, t: usize, i: usize) -> i32 {
        self.byte(t, i) as i8 as i32
    }
    fn word(&self, t: usize, i: usize) -> i32 {
        i32::from_le_bytes(core::array::from_fn(|j| self.byte(t, i * 4 + j)))
    }
    fn param(&self, i: usize) -> i32 {
        i32::from_le_bytes(self.arena[i..i + 4].try_into().unwrap())
    }
    fn put(&mut self, t: usize, i: usize, b: u8) {
        self.arena[self.plans[t].offset + i] = b;
    }
    fn copy(&mut self, t: usize, from: usize, y: usize, to: usize, width: usize) {
        for j in 0..width {
            let b = self.byte(t, from * width + j);
            self.put(y, to * width + j, b);
        }
    }
}
fn coords(mut i: usize, d: [usize; 4]) -> [usize; 4] {
    let mut c = [0; 4];
    for j in (0..4).rev() {
        c[j] = i % d[j];
        i /= d[j];
    }
    c
}
fn index(c: [usize; 4], d: [usize; 4]) -> usize {
    ((c[0] * d[1] + c[1]) * d[2] + c[2]) * d[3] + c[3]
}
fn conv_input(o: &Op, row: usize, k: usize) -> Option<usize> {
    let n = row / (o.output[1] * o.output[2]);
    let oy = row / o.output[2] % o.output[1];
    let ox = row % o.output[2];
    let ky = k / (o.filter[2] * o.filter[3]);
    let kx = k / o.filter[3] % o.filter[2];
    let ic = k % o.filter[3];
    let iy = oy as i64 * o.stride[0] as i64 - o.pad[0] as i64 + ky as i64 * o.dilation[0] as i64;
    let ix = ox as i64 * o.stride[1] as i64 - o.pad[1] as i64 + kx as i64 * o.dilation[1] as i64;
    if iy < 0 || ix < 0 || iy >= o.input[1] as i64 || ix >= o.input[2] as i64 {
        None
    } else {
        Some(index([n, iy as usize, ix as usize, ic], o.input))
    }
}
fn post(mem: &mut Memory<'_>, o: &Op, param: usize, row: usize, c: usize, acc: i32) {
    let q = requantize(
        acc,
        mem.param(param + c * 4),
        mem.param(param + (o.filter[0] + c) * 4),
    ) + o.out_zero;
    mem.put(o.y, row * o.output[3] + c, q.clamp(o.min, o.max) as u8);
}
fn conv_cpu(mem: &mut Memory<'_>, o: &Op, param: usize, pulp: bool) {
    let depth = o.filter[1] * o.filter[2] * o.filter[3];
    let rows = o.output[0] * o.output[1] * o.output[2];
    for row in 0..rows {
        for c in 0..o.output[3] {
            let mut acc = if o.bias < 0 {
                0
            } else {
                mem.word(o.bias as usize, c)
            };
            if pulp {
                for start in (0..depth).step_by(4) {
                    let mut a = [0; 4];
                    let mut b = [0; 4];
                    let mut sum = 0;
                    for j in 0..4 {
                        let k = start + j;
                        if k < depth {
                            a[j] = conv_input(o, row, k)
                                .map(|ix| mem.byte(o.x, ix))
                                .unwrap_or(o.zero as u8);
                            b[j] = mem.byte(o.w, c * depth + k);
                            sum += b[j] as i8 as i32;
                        }
                    }
                    acc += dot4(a, b) - o.zero * sum;
                }
            } else {
                for k in 0..depth {
                    if let Some(ix) = conv_input(o, row, k) {
                        acc += (mem.signed(o.x, ix) - o.zero) * mem.signed(o.w, c * depth + k);
                    }
                }
            }
            post(mem, o, param, row, c, acc);
        }
    }
}
fn conv_npu(
    mem: &mut Memory<'_>,
    o: &Op,
    param: usize,
    dev: &mut impl Device,
    tile: usize,
) -> Result<u32, i32> {
    let mut a = [0i8; 4096];
    let mut b = [0i8; 4096];
    let mut cbuf = [0i32; 4096];
    let mut sums = [0i32; 4096];
    let depth = o.filter[1] * o.filter[2] * o.filter[3];
    let rows = o.output[0] * o.output[1] * o.output[2];
    let cols = o.output[3];
    let mut calls = 0;
    for first in (0..rows).step_by(tile) {
        let m = (rows - first).min(tile);
        for col in (0..cols).step_by(tile) {
            let n = (cols - col).min(tile);
            sums[..m * n].fill(0);
            for base in (0..depth).step_by(tile) {
                let k = (depth - base).min(tile);
                let pk = (k + 3) & !3;
                let pn = (n + 3) & !3;
                a[..m * pk].fill(0);
                b[..pk * pn].fill(0);
                for row in 0..m {
                    for j in 0..k {
                        a[row * pk + j] = conv_input(o, first + row, base + j)
                            .map(|ix| mem.byte(o.x, ix))
                            .unwrap_or(o.zero as u8)
                            as i8;
                    }
                }
                for j in 0..k {
                    for z in 0..n {
                        b[j * pn + z] = mem.byte(o.w, (col + z) * depth + base + j) as i8;
                    }
                }
                let rc = dev.tile(
                    &a[..m * pk],
                    &b[..pk * pn],
                    &mut cbuf[..m * pn],
                    m,
                    pk,
                    pn,
                    None,
                );
                if rc != 0 {
                    return Err(match rc {
                        -1 => -208,
                        -2 => -207,
                        -3 => -209,
                        _ => -206,
                    });
                }
                calls += 1;
                for z in 0..n {
                    let mut correction = 0;
                    for j in 0..k {
                        correction += b[j * pn + z] as i32;
                    }
                    correction *= o.zero;
                    for row in 0..m {
                        sums[row * n + z] += cbuf[row * pn + z] - correction;
                    }
                }
            }
            for row in 0..m {
                for z in 0..n {
                    let bias = if o.bias < 0 {
                        0
                    } else {
                        mem.word(o.bias as usize, col + z)
                    };
                    post(
                        mem,
                        o,
                        param,
                        first + row,
                        col + z,
                        sums[row * n + z] + bias,
                    );
                }
            }
        }
    }
    Ok(calls)
}
pub(crate) fn execute(
    o: &Op,
    model: &[u8],
    plans: &[Plan],
    arena: &mut [u8],
    param: usize,
    device: &mut impl Device,
    backend: Backend,
    tile: usize,
) -> Result<u32, i32> {
    let mut mem = Memory {
        model,
        plans,
        arena,
    };
    let n = o.output.iter().product();
    match o.kind {
        3 | 9 => {
            if backend == Backend::Synap {
                return conv_npu(&mut mem, o, param, device, tile);
            }
            conv_cpu(&mut mem, o, param, backend == Backend::Pulp);
        }
        0 | 18 | 41 => {
            for i in 0..n {
                let c = coords(i, o.output);
                let ai = (0..4).map(|d| c[d] * o.ba[d]).sum();
                let bi = (0..4).map(|d| c[d] * o.bb[d]).sum();
                let mut x = mem.signed(o.x, ai) - o.zero;
                let mut b = mem.signed(o.w, bi) - o.second_zero;
                let q = if o.kind == 18 {
                    requantize(x * b, o.mult[2], o.shift[2])
                } else {
                    x = requantize(x * 1048576, o.mult[0], o.shift[0]);
                    b = requantize(b * 1048576, o.mult[1], o.shift[1]);
                    requantize(
                        if o.kind == 41 { x - b } else { x + b },
                        o.mult[2],
                        o.shift[2],
                    )
                };
                mem.put(o.y, i, (q + o.out_zero).clamp(o.min, o.max) as u8);
            }
        }
        14 => {
            for i in 0..n {
                let v = mem.signed(o.x, i);
                let b = mem.arena[param + (v + 128) as usize];
                mem.put(o.y, i, b);
            }
        }
        17 => {
            for i in 0..n {
                let c = coords(i, o.output);
                let y0 = c[1] as i64 * o.stride[0] as i64 - o.pad[0] as i64;
                let x0 = c[2] as i64 * o.stride[1] as i64 - o.pad[1] as i64;
                let mut v = -128;
                for y in y0.max(0)..(y0 + o.filter[1] as i64).min(o.input[1] as i64) {
                    for x in x0.max(0)..(x0 + o.filter[2] as i64).min(o.input[2] as i64) {
                        v = v.max(
                            mem.signed(o.x, index([c[0], y as usize, x as usize, c[3]], o.input)),
                        );
                    }
                }
                mem.put(o.y, i, v.clamp(o.min, o.max) as u8);
            }
        }
        22 => {
            for i in 0..n {
                mem.copy(o.x, i, o.y, i, o.width);
            }
        }
        2 => {
            let outer: usize = o.output[..o.axis].iter().product();
            let inner: usize = o.output[o.axis + 1..].iter().product();
            let mut to = 0;
            for row in 0..outer {
                for j in 0..o.count {
                    let len = inner * o.concat[j];
                    for i in 0..len {
                        mem.copy(o.ids[j] as usize, row * len + i, o.y, to, o.width);
                        to += 1;
                    }
                }
            }
        }
        114 => {
            for i in 0..n {
                let q = if o.xtype == 0 {
                    let f = f32::from_bits(mem.word(o.x, i) as u32);
                    if !f.is_finite() {
                        return Err(GRAPH);
                    }
                    let v = round((f / o.ys) as f64);
                    if v <= (-128 - o.out_zero) as f64 {
                        -128
                    } else if v >= (127 - o.out_zero) as f64 {
                        127
                    } else {
                        v as i32 + o.out_zero
                    }
                } else {
                    requantize(mem.signed(o.x, i) - o.zero, o.mult[0], o.shift[0]) + o.out_zero
                };
                mem.put(o.y, i, q.clamp(-128, 127) as u8);
            }
        }
        6 => {
            for i in 0..n {
                let v = (mem.signed(o.x, i) - o.zero) as f32 * o.xs;
                for (j, b) in v.to_le_bytes().iter().enumerate() {
                    mem.put(o.y, i * 4 + j, *b);
                }
            }
        }
        25 => {
            let depth = o.output[3];
            for first in (0..n).step_by(depth) {
                let max = (0..depth)
                    .map(|c| mem.signed(o.x, first + c))
                    .max()
                    .ok_or(GRAPH)?;
                let mut sum = 0;
                for c in 0..depth {
                    sum += ((mem.param(param + (max - mem.signed(o.x, first + c)) as usize * 4)
                        as i64
                        + 2048)
                        >> 12) as i32;
                }
                let (m, s) = softmax_scale(sum);
                for c in 0..depth {
                    let exponent =
                        mem.param(param + (max - mem.signed(o.x, first + c)) as usize * 4);
                    mem.put(o.y, first + c, softmax_output(exponent, m, s) as u8);
                }
            }
        }
        _ => {
            for i in 0..n {
                let out = coords(i, o.output);
                let mut c = out;
                let mut valid = true;
                match o.kind {
                    39 => {
                        for d in 0..4 {
                            c[o.aux[d]] = out[d];
                        }
                    }
                    34 => {
                        for d in 0..4 {
                            if out[d] < o.begin[d] {
                                valid = false;
                            } else {
                                c[d] = out[d] - o.begin[d];
                                if c[d] >= o.input[d] {
                                    valid = false;
                                }
                            }
                        }
                    }
                    65 => {
                        for d in 0..4 {
                            c[d] += o.begin[d];
                        }
                    }
                    97 => {
                        for d in 1..=2 {
                            let scale = if o.aux[0] != 0 && o.output[d] > 1 {
                                (o.input[d] - 1) as f32 / (o.output[d] - 1) as f32
                            } else {
                                o.input[d] as f32 / o.output[d] as f32
                            };
                            let pos =
                                (out[d] as f32 + if o.aux[1] != 0 { 0.5 } else { 0.0 }) * scale;
                            c[d] = (if o.aux[0] != 0 {
                                round(pos as f64) as usize
                            } else {
                                pos as usize
                            })
                            .min(o.input[d] - 1);
                        }
                    }
                    _ => return Err(UNSUPPORTED),
                }
                if valid {
                    mem.copy(o.x, index(c, o.input), o.y, i, o.width);
                } else {
                    for j in 0..o.width {
                        mem.put(
                            o.y,
                            i * o.width + j,
                            if o.width == 1 { o.zero as u8 } else { 0 },
                        );
                    }
                }
            }
        }
    }
    Ok(0)
}
