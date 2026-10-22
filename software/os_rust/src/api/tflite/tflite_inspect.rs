//! tflite_inspect.cc: bounds-checked reader for PSC's INT8 FC FlatBuffer profile.
//! All model accesses are bytewise. No generated C++ schema or heap is required.
pub const MODEL_CAPACITY: usize = 8192;
pub const SIZE: i32 = -200;
pub const FORMAT: i32 = -201;
pub const UNSUPPORTED: i32 = -202;
pub const GRAPH: i32 = -203;
#[derive(Clone, Copy, Default, Debug)]
pub struct Info {
    pub version: u32,
    pub tensors: u32,
    pub operators: u32,
    pub constant_bytes: u32,
    pub tensor_bytes: u32,
}
#[derive(Clone, Copy, Default)]
pub struct Tensor {
    pub shape: [usize; 4],
    pub rank: usize,
    pub kind: u8,
    pub data: usize,
    pub bytes: usize,
    pub scale: f32,
    pub zero: i32,
}
#[derive(Clone, Copy, Default)]
pub struct Operator {
    pub x: usize,
    pub w: usize,
    pub bias: Option<usize>,
    pub y: usize,
    pub relu: bool,
}
pub struct Model<'a> {
    pub bytes: &'a [u8],
    pub tensors: [Tensor; 32],
    pub operators: [Operator; 8],
    pub input: usize,
    pub output: usize,
    pub info: Info,
}
#[derive(Clone, Copy)]
struct Reader<'a>(&'a [u8]);
impl<'a> Reader<'a> {
    fn bytes(self, p: usize, n: usize) -> Result<&'a [u8], i32> {
        self.0.get(p..p.checked_add(n).ok_or(FORMAT)?).ok_or(FORMAT)
    }

    fn u16(self, p: usize) -> Result<usize, i32> {
        Ok(u16::from_le_bytes(self.bytes(p, 2)?.try_into().unwrap()) as usize)
    }

    fn u32(self, p: usize) -> Result<u32, i32> {
        Ok(u32::from_le_bytes(self.bytes(p, 4)?.try_into().unwrap()))
    }

    fn i64(self, p: usize) -> Result<i64, i32> {
        Ok(i64::from_le_bytes(self.bytes(p, 8)?.try_into().unwrap()))
    }

    fn offset(self, p: usize) -> Result<usize, i32> {
        let off = self.u32(p)? as usize;
        if off == 0 {
            return Err(FORMAT);
        }
        let target = p.checked_add(off).ok_or(FORMAT)?;
        self.bytes(target, 1)?;
        Ok(target)
    }

    /// Vtable displacements are signed: deduplicated vtables may follow a table.
    fn field(self, table: usize, id: usize, width: usize) -> Result<Option<usize>, i32> {
        let displacement = self.u32(table)? as i32 as i64;
        let v = table as i64 - displacement;
        if v < 0 {
            return Err(FORMAT);
        }
        let v = v as usize;
        let length = self.u16(v)?;
        let object = self.u16(v + 2)?;
        if length < 4 || length & 1 != 0 || object < 4 {
            return Err(FORMAT);
        }
        self.bytes(v, length)?;
        self.bytes(table, object)?;
        if id + 2 > length {
            return Ok(None);
        }
        let off = self.u16(v + id)?;
        if off == 0 {
            return Ok(None);
        }
        if off < 4 || off + width > object {
            return Err(FORMAT);
        }
        Ok(Some(table + off))
    }

    fn scalar(self, t: usize, id: usize, default: u32) -> Result<u32, i32> {
        match self.field(t, id, 4)? {
            Some(p) => self.u32(p),
            None => Ok(default),
        }
    }

    fn byte(self, t: usize, id: usize) -> Result<u8, i32> {
        Ok(match self.field(t, id, 1)? {
            Some(p) => self.bytes(p, 1)?[0],
            None => 0,
        })
    }

    fn indirect(self, t: usize, id: usize) -> Result<Option<usize>, i32> {
        self.field(t, id, 4)?.map(|p| self.offset(p)).transpose()
    }

    fn vector(self, t: usize, id: usize, width: usize) -> Result<(usize, usize), i32> {
        let Some(p) = self.indirect(t, id)? else {
            return Ok((0, 0));
        };
        let n = self.u32(p)? as usize;
        self.bytes(p + 4, n.checked_mul(width).ok_or(FORMAT)?)?;
        Ok((p + 4, n))
    }

    fn index(self, p: usize, n: usize, i: usize) -> Result<usize, i32> {
        let id = self.u32(p + i * 4)? as i32;
        if id < 0 || id as usize >= n {
            return Err(GRAPH);
        }
        Ok(id as usize)
    }
}

fn scale_ok(value: f32) -> bool {
    let bits = value.to_bits();
    bits >> 31 == 0 && bits >> 23 != 0 && bits >> 23 < 255
}

fn bias_scale_matches(a: f32, b: f32, c: f32) -> bool {
    let (a, b, c) = (a.to_bits(), b.to_bits(), c.to_bits());
    let product = ((a & 0x7fffff) | 0x800000) as u64 * ((b & 0x7fffff) | 0x800000) as u64;
    let mut exponent = (a >> 23) as i32 + (b >> 23) as i32 - 127;
    let shift = if product & (1 << 47) != 0 {
        exponent += 1;
        24
    } else {
        23
    };
    let mut mantissa = ((product + (1 << (shift - 1))) >> shift) as u32;
    if mantissa == 0x1000000 {
        mantissa >>= 1;
        exponent += 1;
    }
    if exponent <= 0 || exponent >= 255 {
        return false;
    }
    let expected = ((exponent as u32) << 23) | (mantissa & 0x7fffff);
    c >= expected - 2 && c <= expected + 2
}

/// Validate topology, quantization, dimensions, and every referenced byte range.
pub fn inspect(bytes: &[u8]) -> Result<Model<'_>, i32> {
    if bytes.len() < 8 || bytes.len() > MODEL_CAPACITY {
        return Err(SIZE);
    }
    if &bytes[4..8] != b"TFL3" {
        return Err(FORMAT);
    }
    let r = Reader(bytes);
    let root = r.offset(0)?;
    if r.scalar(root, 4, 0)? != 3 {
        return Err(UNSUPPORTED);
    }
    for id in [20, 22] {
        if r.vector(root, id, 4)?.1 != 0 {
            return Err(UNSUPPORTED);
        }
    }
    let (codes, ncodes) = r.vector(root, 6, 4)?;
    let (graphs, ngraphs) = r.vector(root, 8, 4)?;
    let (buffers, nbuffers) = r.vector(root, 12, 4)?;
    if ngraphs != 1 || nbuffers == 0 || nbuffers > 64 || ncodes > 8 {
        return Err(UNSUPPORTED);
    }
    let mut buffer_data = [(0, 0); 64];
    let mut constant_bytes = 0;
    for i in 0..nbuffers {
        let b = r.offset(buffers + i * 4)?;
        for id in [6, 8] {
            if let Some(p) = r.field(b, id, 8)? {
                if r.i64(p)? != 0 {
                    return Err(UNSUPPORTED);
                }
            }
        }
        let data = r.vector(b, 4, 1)?;
        if i == 0 && data.1 != 0 {
            return Err(GRAPH);
        }
        constant_bytes += data.1;
        buffer_data[i] = data;
    }
    let g = r.offset(graphs)?;
    let (tensors, nt) = r.vector(g, 4, 4)?;
    let (inputs, ni) = r.vector(g, 6, 4)?;
    let (outputs, ny) = r.vector(g, 8, 4)?;
    let (ops, no) = r.vector(g, 10, 4)?;
    if nt == 0 || nt > 32 || no == 0 || no > 8 || ni != 1 || ny != 1 {
        return Err(UNSUPPORTED);
    }
    let input = r.index(inputs, nt, 0)?;
    let output = r.index(outputs, nt, 0)?;
    let mut model = Model {
        bytes,
        tensors: [Tensor::default(); 32],
        operators: [Operator::default(); 8],
        input,
        output,
        info: Info {
            version: 3,
            tensors: nt as u32,
            operators: no as u32,
            constant_bytes: constant_bytes as u32,
            tensor_bytes: 0,
        },
    };
    let mut ready = [false; 32];
    for i in 0..nt {
        let t = r.offset(tensors + i * 4)?;
        let (shape, rank) = r.vector(t, 4, 4)?;
        if rank == 0 || rank > 4 {
            return Err(UNSUPPORTED);
        }
        if r.byte(t, 14)? != 0 || r.indirect(t, 16)?.is_some() || r.scalar(t, 24, 0)? != 0 {
            return Err(UNSUPPORTED);
        }
        let kind = r.byte(t, 6)?;
        let width = match kind {
            9 => 1,
            2 => 4,
            _ => return Err(UNSUPPORTED),
        };
        let bi = r.scalar(t, 8, 0)? as usize;
        if bi >= nbuffers {
            return Err(GRAPH);
        }
        let (data, length) = buffer_data[bi];
        let (sig, nsig) = r.vector(t, 18, 4)?;
        if nsig != 0 && nsig != rank {
            return Err(GRAPH);
        }
        let mut dimensions = [0; 4];
        let mut elements = 1usize;
        for d in 0..rank {
            let v = r.u32(shape + d * 4)? as i32;
            if v <= 0 || (nsig != 0 && r.u32(sig + d * 4)? != v as u32) {
                return Err(UNSUPPORTED);
            }
            let v = v as usize;
            if v > 8192 / elements {
                return Err(UNSUPPORTED);
            }
            elements *= v;
            dimensions[d] = v;
        }
        if length != 0 && length != elements * width {
            return Err(GRAPH);
        }
        if length == 0 {
            model.info.tensor_bytes += (elements * width) as u32;
        }
        let q = r.indirect(t, 12)?.ok_or(UNSUPPORTED)?;
        if r.byte(q, 12)? != 0 || r.indirect(q, 14)?.is_some() {
            return Err(UNSUPPORTED);
        }
        let (scales, nscale) = r.vector(q, 8, 4)?;
        let (zeros, nzero) = r.vector(q, 10, 8)?;
        if nscale == 0 || nscale > 64 || nscale != nzero {
            return Err(GRAPH);
        }
        if nscale != 1 {
            return Err(UNSUPPORTED);
        }
        if r.scalar(q, 16, 0)? as usize >= rank {
            return Err(GRAPH);
        }
        let scale = f32::from_bits(r.u32(scales)?);
        let zero = r.i64(zeros)?;
        if !scale_ok(scale) || !(-128..=127).contains(&zero) || (kind == 2 && zero != 0) {
            return Err(GRAPH);
        }
        model.tensors[i] = Tensor {
            shape: dimensions,
            rank,
            kind,
            data: if length == 0 { 0 } else { data },
            bytes: elements * width,
            scale,
            zero: zero as i32,
        };
        ready[i] = length != 0;
    }
    if ready[input] || ready[output] || input == output {
        return Err(GRAPH);
    }
    ready[input] = true;
    if model.tensors[input].kind != 9 || model.tensors[output].kind != 9 {
        return Err(UNSUPPORTED);
    }
    for i in 0..no {
        let op = r.offset(ops + i * 4)?;
        let ci = r.scalar(op, 4, 0)? as usize;
        if ci >= ncodes {
            return Err(GRAPH);
        }
        let code = r.offset(codes + ci * 4)?;
        let builtin = (r.byte(code, 4)? as i8 as i32).max(r.scalar(code, 10, 0)? as i32);
        if builtin != 9
            || r.scalar(code, 8, 1)? != 4
            || r.indirect(code, 6)?.is_some()
            || r.byte(op, 10)? != 8
        {
            return Err(UNSUPPORTED);
        }
        for id in [14, 18, 20] {
            if r.vector(op, id, 1)?.1 != 0 {
                return Err(UNSUPPORTED);
            }
        }
        for id in [22, 24] {
            if let Some(p) = r.field(op, id, 8)? {
                if r.i64(p)? != 0 {
                    return Err(UNSUPPORTED);
                }
            }
        }
        if r.byte(op, 26)? != 0 {
            return Err(UNSUPPORTED);
        }
        let (a, na) = r.vector(op, 6, 4)?;
        let (y, ny) = r.vector(op, 8, 4)?;
        if na != 3 || ny != 1 {
            return Err(GRAPH);
        }
        let xi = r.index(a, nt, 0)?;
        let wi = r.index(a, nt, 1)?;
        let bi = r.u32(a + 8)? as i32;
        let yi = r.index(y, nt, 0)?;
        if !ready[xi]
            || !ready[wi]
            || ready[yi]
            || bi < -1
            || (bi >= 0 && (bi as usize >= nt || !ready[bi as usize]))
        {
            return Err(GRAPH);
        }
        let fc = r.indirect(op, 12)?.ok_or(UNSUPPORTED)?;
        let activation = r.byte(fc, 4)?;
        if activation > 1
            || r.byte(fc, 6)? != 0
            || r.byte(fc, 8)? != 0
            || r.byte(fc, 10)? != 0
            || !matches!(r.byte(fc, 12)?, 0 | 2)
        {
            return Err(UNSUPPORTED);
        }
        let (x, w, y) = (model.tensors[xi], model.tensors[wi], model.tensors[yi]);
        if x.kind != 9
            || w.kind != 9
            || y.kind != 9
            || x.rank != 2
            || w.rank != 2
            || y.rank != 2
            || x.shape[0] != y.shape[0]
        {
            return Err(UNSUPPORTED);
        }
        if x.shape[1] != w.shape[1] || y.shape[1] != w.shape[0] || w.data == 0 {
            return Err(GRAPH);
        }
        if w.zero != 0 || r.bytes(w.data, w.bytes)?.contains(&128) {
            return Err(UNSUPPORTED);
        }
        let bias = if bi >= 0 {
            let b = model.tensors[bi as usize];
            if b.kind != 2
                || b.data == 0
                || b.rank != 1
                || b.shape[0] != w.shape[0]
                || !bias_scale_matches(x.scale, w.scale, b.scale)
            {
                return Err(GRAPH);
            }
            Some(bi as usize)
        } else {
            None
        };
        ready[yi] = true;
        model.operators[i] = Operator {
            x: xi,
            w: wi,
            bias,
            y: yi,
            relu: activation == 1,
        };
    }
    if !ready[output] {
        return Err(GRAPH);
    }
    Ok(model)
}
