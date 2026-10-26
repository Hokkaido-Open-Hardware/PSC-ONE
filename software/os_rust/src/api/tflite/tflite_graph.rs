//! Independent Rust FlatBuffer graph reader and lifetime planner.
//! No C/C++ parser or inference library is linked. All offsets are checked before use.
use super::{
    tflite_cpu,
    tflite_inspect::{scale_ok, Reader, FORMAT, GRAPH, MODEL_CAPACITY, SIZE, UNSUPPORTED},
    tflite_runtime::Backend,
    tflite_synap::Device,
};
pub const ARENA: i32 = -210;
pub const ARENA_CAPACITY: usize = 768 * 1024;
pub const LIMIT: usize = 1024;
#[derive(Clone, Copy, Default, Debug)]
pub struct Analysis {
    pub tensors: usize,
    pub operators: usize,
    pub opcodes: usize,
    pub constant_bytes: usize,
    pub tensor_bytes: usize,
    pub largest: usize,
    pub out_of_line: usize,
    pub dynamic: usize,
    pub supported: usize,
    pub unsupported: usize,
    pub lifetime_peak: usize,
}
#[derive(Clone, Copy)]
pub(crate) struct Plan {
    pub table: usize,
    pub bytes: usize,
    pub data: usize,
    pub offset: usize,
    first: i16,
    last: i16,
}
impl Plan {
    const EMPTY: Self = Self {
        table: 0,
        bytes: 0,
        data: 0,
        offset: usize::MAX,
        first: -1,
        last: 0,
    };
}
#[derive(Clone, Copy, Default, Debug)]
pub struct Tensor {
    pub dims: [usize; 8],
    pub rank: usize,
    pub kind: u8,
    pub bytes: usize,
    pub data: usize,
    pub scale: f32,
    pub zero: i32,
    pub(crate) scales: usize,
    pub(crate) zeros: usize,
    pub(crate) nq: usize,
    pub(crate) axis: usize,
    pub(crate) details: bool,
}
impl Tensor {
    pub(crate) fn shape(self) -> Result<[usize; 4], i32> {
        if self.rank > 4 {
            return Err(UNSUPPORTED);
        }
        let mut d = [1; 4];
        d[4 - self.rank..].copy_from_slice(&self.dims[..self.rank]);
        Ok(d)
    }
    pub(crate) fn affine(self, channels: bool) -> bool {
        self.kind == 9 && !self.details && self.nq > 0 && (channels || self.nq == 1)
    }
    pub(crate) fn same_quant(self, b: Self) -> bool {
        self.kind == b.kind
            && (self.kind != 9
                || (self.affine(false)
                    && b.affine(false)
                    && self.scale == b.scale
                    && self.zero == b.zero))
    }
    pub(crate) fn same_shape(self, b: Self) -> bool {
        self.rank == b.rank && self.dims == b.dims
    }
}
#[derive(Clone, Copy, Default, Debug)]
pub struct Record {
    pub kind: i32,
    pub backend: u8,
    pub us: i32,
    pub status: i32,
    pub tiles: u32,
}
/// Workspace is initialized in place; model and arena borrows survive until reset.
/// No allocation proportional to model counts occurs on the firmware stack.
pub struct Graph<'a> {
    pub info: Analysis,
    pub required: usize,
    pub(crate) model: &'a [u8],
    pub(crate) plans: [Plan; LIMIT],
    codes: usize,
    buffers: usize,
    nbuffers: usize,
    ops: usize,
    input_id: usize,
    output_id: usize,
    params: [usize; 512],
    arena: Option<&'a mut [u8]>,
    prepared: bool,
    output_valid: bool,
    backend: Backend,
    tile: usize,
    pub records: [Record; 512],
}
impl<'a> Graph<'a> {
    pub const fn new() -> Self {
        Self {
            info: Analysis {
                tensors: 0,
                operators: 0,
                opcodes: 0,
                constant_bytes: 0,
                tensor_bytes: 0,
                largest: 0,
                out_of_line: 0,
                dynamic: 0,
                supported: 0,
                unsupported: 0,
                lifetime_peak: 0,
            },
            required: 0,
            model: &[],
            plans: [Plan::EMPTY; LIMIT],
            codes: 0,
            buffers: 0,
            nbuffers: 0,
            ops: 0,
            input_id: 0,
            output_id: 0,
            params: [0; 512],
            arena: None,
            prepared: false,
            output_valid: false,
            backend: Backend::Cpu,
            tile: 32,
            records: [Record {
                kind: 0,
                backend: 0,
                us: -1,
                status: 0,
                tiles: 0,
            }; 512],
        }
    }
    pub fn reset(&mut self) {
        self.prepared = false;
        self.output_valid = false;
        self.model = &[];
        self.arena = None;
        self.required = 0;
        self.backend = Backend::Cpu;
        self.tile = 32;
    }
    pub(super) fn reader(&self) -> Reader<'a> {
        Reader(self.model)
    }
    fn buffer(&self, index: usize) -> Result<(usize, usize, bool), i32> {
        if index >= self.nbuffers {
            return Err(GRAPH);
        }
        let r = self.reader();
        let b = r.offset(self.buffers + 4 * index)?;
        let (p, n) = r.vector(b, 4, 1)?;
        let off = match r.field(b, 6, 8)? {
            Some(p) => r.i64(p)? as u64,
            None => 0,
        };
        let size = match r.field(b, 8, 8)? {
            Some(p) => r.i64(p)? as u64,
            None => 0,
        };
        if off > 1 {
            if n != 0 || off > self.model.len() as u64 || size > self.model.len() as u64 - off {
                return Err(GRAPH);
            }
            Ok((
                if size == 0 { 0 } else { off as usize },
                size as usize,
                true,
            ))
        } else {
            if size != 0 {
                return Err(GRAPH);
            }
            Ok((if n == 0 { 0 } else { p }, n, false))
        }
    }
    pub fn tensor(&self, id: usize) -> Result<Tensor, i32> {
        if id >= self.info.tensors {
            return Err(GRAPH);
        }
        let r = self.reader();
        let t = self.plans[id].table;
        let (shape, rank) = r.vector(t, 4, 4)?;
        if rank > 8 {
            return Err(UNSUPPORTED);
        }
        let mut out = Tensor {
            rank,
            kind: r.byte(t, 6)?,
            ..Tensor::default()
        };
        let width = match out.kind {
            3 | 6 | 9 => 1,
            1 | 7 => 2,
            0 | 2 => 4,
            4 | 10 => 8,
            _ => return Err(UNSUPPORTED),
        };
        let mut elements = 1usize;
        for d in 0..rank {
            let n = r.u32(shape + 4 * d)? as i32;
            if n <= 0 {
                return Err(UNSUPPORTED);
            }
            elements = elements
                .checked_mul(n as usize)
                .filter(|v| *v <= i32::MAX as usize / width)
                .ok_or(GRAPH)?;
            out.dims[d] = n as usize;
        }
        out.bytes = elements * width;
        if r.byte(t, 14)? != 0 || r.indirect(t, 16)?.is_some() || r.scalar(t, 24, 0)? != 0 {
            return Err(UNSUPPORTED);
        }
        let (data, len, _) = self.buffer(r.scalar(t, 8, 0)? as usize)?;
        if len != 0 && len != out.bytes {
            return Err(GRAPH);
        }
        out.data = data;
        let (sig, ns) = r.vector(t, 18, 4)?;
        if ns != 0 && ns != rank {
            return Err(GRAPH);
        }
        // Names are diagnostics only, but malformed strings must still be rejected.
        if let Some(p) = r.indirect(t, 10)? {
            let n = r.u32(p)? as usize;
            let s = r.bytes(p + 4, n.checked_add(1).ok_or(FORMAT)?)?;
            if s[n] != 0 {
                return Err(FORMAT);
            }
        }
        if let Some(q) = r.indirect(t, 12)? {
            r.vector(q, 4, 4)?;
            r.vector(q, 6, 4)?;
            let (sc, nq) = r.vector(q, 8, 4)?;
            let (ze, nz) = r.vector(q, 10, 8)?;
            out.details = r.byte(q, 12)? != 0 || r.indirect(q, 14)?.is_some();
            out.axis = r.scalar(q, 16, 0)? as usize;
            if nq != 0 {
                if nq != nz
                    || (rank == 0 && out.axis != 0)
                    || (rank != 0 && out.axis >= rank)
                    || (nq > 1 && (rank == 0 || nq != out.dims[out.axis]))
                {
                    return Err(GRAPH);
                }
                for j in 0..nq {
                    let s = f32::from_bits(r.u32(sc + 4 * j)?);
                    let z = r.i64(ze + 8 * j)?;
                    if !scale_ok(s)
                        || (out.kind == 9 && !(-128..=127).contains(&z))
                        || (out.kind == 2 && z != 0)
                    {
                        return Err(GRAPH);
                    }
                }
                out.scale = f32::from_bits(r.u32(sc)?);
                out.zero = r.i64(ze)? as i32;
            } else if nz != 0 {
                return Err(GRAPH);
            }
            out.scales = sc;
            out.zeros = ze;
            out.nq = nq;
        }
        // Validate shape signature bytes even when analysis permits a dynamic signature.
        for d in 0..ns {
            r.u32(sig + 4 * d)?;
        }
        Ok(out)
    }
    pub(crate) fn operator(&self, i: usize) -> Result<(usize, i32, i32), i32> {
        if i >= self.info.operators {
            return Err(GRAPH);
        }
        let r = self.reader();
        let op = r.offset(self.ops + 4 * i)?;
        let ci = r.scalar(op, 4, 0)? as usize;
        if ci >= self.info.opcodes {
            return Err(GRAPH);
        }
        let c = r.offset(self.codes + 4 * ci)?;
        let kind = (r.byte(c, 4)? as i8 as i32).max(r.scalar(c, 10, 0)? as i32);
        Ok((op, kind, r.scalar(c, 8, 1)? as i32))
    }
    pub fn kind(&self, i: usize) -> Result<i32, i32> {
        Ok(self.operator(i)?.1)
    }
    pub fn is_legacy_fc(&self) -> bool {
        self.info.out_of_line == 0 && (0..self.info.operators).all(|i| self.kind(i) == Ok(9))
    }
    /// Structural analysis is independent of execution support and arena size.
    pub fn analyze(&mut self, bytes: &'a [u8]) -> Result<Analysis, i32> {
        self.reset();
        self.info = Analysis::default();
        self.plans.fill(Plan::EMPTY);
        if !(8..=MODEL_CAPACITY).contains(&bytes.len()) {
            return Err(SIZE);
        }
        if &bytes[4..8] != b"TFL3" {
            return Err(FORMAT);
        }
        super::tflite_verify::verify(bytes)?;
        self.model = bytes;
        let r = self.reader();
        let root = r.offset(0)?;
        if r.scalar(root, 4, 0)? != 3 {
            return Err(UNSUPPORTED);
        }
        for field in [20, 22] {
            if r.vector(root, field, 4)?.1 != 0 {
                return Err(UNSUPPORTED);
            }
        }
        let (gs, ng) = r.vector(root, 8, 4)?;
        let (bs, nb) = r.vector(root, 12, 4)?;
        let (cs, nc) = r.vector(root, 6, 4)?;
        if ng != 1 || nb == 0 || nb > LIMIT || nc > LIMIT {
            return Err(UNSUPPORTED);
        }
        self.buffers = bs;
        self.nbuffers = nb;
        self.codes = cs;
        self.info.opcodes = nc;
        for i in 0..nb {
            let (_, n, external) = self.buffer(i)?;
            if i == 0 && n != 0 {
                return Err(GRAPH);
            }
            self.info.constant_bytes = self
                .info
                .constant_bytes
                .checked_add(n)
                .filter(|v| *v <= u32::MAX as usize)
                .ok_or(GRAPH)?;
            self.info.out_of_line += usize::from(external);
        }
        let g = r.offset(gs)?;
        let (ts, nt) = r.vector(g, 4, 4)?;
        let (ops, no) = r.vector(g, 10, 4)?;
        if nt == 0 || nt > LIMIT || no == 0 || no > LIMIT {
            return Err(UNSUPPORTED);
        }
        self.ops = ops;
        self.info.tensors = nt;
        self.info.operators = no;
        for i in 0..nt {
            self.plans[i].table = r.offset(ts + 4 * i)?;
            let t = self.tensor(i)?;
            let (sig, ns) = r.vector(self.plans[i].table, 18, 4)?;
            if (0..ns).any(|d| r.u32(sig + 4 * d).ok() != Some(t.dims[d] as u32)) {
                self.info.dynamic += 1;
            }
            let p = &mut self.plans[i];
            p.bytes = t.bytes;
            p.data = t.data;
            if t.data == 0 {
                self.info.tensor_bytes = self
                    .info
                    .tensor_bytes
                    .checked_add(t.bytes)
                    .filter(|v| *v <= u32::MAX as usize)
                    .ok_or(ARENA)?;
                self.info.largest = self.info.largest.max(t.bytes);
            }
        }
        let (ins, ni) = r.vector(g, 6, 4)?;
        let (outs, ny) = r.vector(g, 8, 4)?;
        if ni == 0 || ny == 0 {
            return Err(GRAPH);
        }
        self.input_id = if ni == 1 { r.index(ins, nt, 0)? } else { LIMIT };
        self.output_id = if ny == 1 {
            r.index(outs, nt, 0)?
        } else {
            LIMIT
        };
        for j in 0..ni {
            let id = r.index(ins, nt, j)?;
            let p = &mut self.plans[id];
            if p.data != 0 || p.first >= 0 {
                return Err(GRAPH);
            }
            p.first = 0;
            p.last = no as i16 + 1;
        }
        for i in 0..no {
            let (op, k, _) = self.operator(i)?;
            let code = r.offset(cs + 4 * r.scalar(op, 4, 0)? as usize)?;
            let custom = r.indirect(code, 6)?;
            if let Some(p) = custom {
                let n = r.u32(p)? as usize;
                if r.bytes(p + 4, n.checked_add(1).ok_or(FORMAT)?)?[n] != 0 {
                    return Err(FORMAT);
                }
            }
            if supported(k) && custom.is_none() {
                self.info.supported += 1;
            } else {
                self.info.unsupported += 1;
            }
            let (a, na) = r.vector(op, 6, 4)?;
            let (y, ny) = r.vector(op, 8, 4)?;
            if ny == 0 {
                return Err(GRAPH);
            }
            for j in 0..na {
                if r.u32(a + 4 * j)? == u32::MAX {
                    continue;
                }
                let id = r.index(a, nt, j)?;
                let p = &mut self.plans[id];
                if p.data == 0 && p.first < 0 {
                    return Err(GRAPH);
                }
                p.last = p.last.max(i as i16 + 1);
            }
            for j in 0..ny {
                let id = r.index(y, nt, j)?;
                let p = &mut self.plans[id];
                if p.data != 0 || p.first >= 0 {
                    return Err(GRAPH);
                }
                p.first = i as i16 + 1;
                p.last = p.first;
            }
            // Check lengths of optional vectors before any execution rejection.
            for (f, w) in [(14, 1), (18, 1), (20, 4)] {
                r.vector(op, f, w)?;
            }
            if let Some(options) = r.indirect(op, 12)? {
                r.field(options, 4, 1)?;
            }
        }
        for j in 0..ny {
            let id = r.index(outs, nt, j)?;
            let p = &mut self.plans[id];
            if p.first < 0 || p.data != 0 {
                return Err(GRAPH);
            }
            p.last = no as i16 + 1;
        }
        for time in 0..=no + 1 {
            let mut live = 0usize;
            for p in &self.plans[..nt] {
                if p.data == 0 && p.first >= 0 && p.first <= time as i16 && p.last >= time as i16 {
                    live = live.checked_add(align(p.bytes)?).ok_or(ARENA)?;
                }
            }
            self.info.lifetime_peak = self.info.lifetime_peak.max(live);
        }
        Ok(self.info)
    }
    pub(crate) fn quant(&self, t: Tensor, c: usize) -> Result<(f32, i32), i32> {
        let i = if t.nq == 1 { 0 } else { c };
        if i >= t.nq {
            return Err(GRAPH);
        }
        Ok((
            f32::from_bits(self.reader().u32(t.scales + i * 4)?),
            self.reader().i64(t.zeros + i * 8)? as i32,
        ))
    }
    pub(crate) fn control(&self, id: i32) -> Result<Tensor, i32> {
        if id < 0 {
            return Err(GRAPH);
        }
        let t = self.tensor(id as usize)?;
        if t.kind != 2 || t.data == 0 {
            return Err(UNSUPPORTED);
        }
        Ok(t)
    }
    pub(crate) fn integer(&self, t: Tensor, i: usize) -> Result<i32, i32> {
        if i >= t.bytes / 4 {
            return Err(GRAPH);
        }
        Ok(self.reader().u32(t.data + i * 4)? as i32)
    }
    pub fn prepare(&mut self, bytes: &'a [u8], arena: &'a mut [u8]) -> Result<(), i32> {
        self.analyze(bytes)?;
        if self.info.unsupported != 0
            || self.info.dynamic != 0
            || self.info.operators > 512
            || self.input_id == LIMIT
            || self.output_id == LIMIT
        {
            return Err(UNSUPPORTED);
        }
        // Validate all options before calculating or publishing an allocation plan.
        for i in 0..self.info.operators {
            tflite_cpu::compile(self, i)?;
        }
        let mut peak = 0;
        for time in 0..=self.info.operators {
            for i in 0..self.info.tensors {
                let t = self.plans[i];
                if t.data != 0 || t.first != time as i16 {
                    continue;
                }
                let mut pos = 0usize;
                loop {
                    let mut collision = false;
                    for u in &self.plans[..self.info.tensors] {
                        if u.offset == usize::MAX || t.last < u.first || u.last < t.first {
                            continue;
                        }
                        if pos.checked_add(t.bytes).ok_or(ARENA)? > u.offset
                            && u.offset + u.bytes > pos
                        {
                            pos = align(u.offset + u.bytes)?;
                            collision = true;
                            break;
                        }
                    }
                    if !collision {
                        break;
                    }
                }
                self.plans[i].offset = pos;
                peak = peak.max(pos.checked_add(t.bytes).ok_or(ARENA)?);
            }
        }
        let activation = align(peak)?;
        let mut offset = activation;
        for i in 0..self.info.operators {
            let op = tflite_cpu::compile(self, i)?;
            offset = align(offset)?;
            self.params[i] = offset;
            offset = offset.checked_add(op.params).ok_or(ARENA)?;
        }
        self.required = offset;
        if offset > arena.len() {
            return Err(ARENA);
        }
        arena[..offset].fill(0);
        for i in 0..self.info.operators {
            let op = tflite_cpu::compile(self, i)?;
            tflite_cpu::parameters(
                self,
                &op,
                &mut arena[self.params[i]..self.params[i] + op.params],
            )?;
        }
        self.arena = Some(arena);
        self.prepared = true;
        Ok(())
    }
    pub fn set_backend(&mut self, b: Backend) {
        self.backend = b;
        self.output_valid = false;
    }
    pub fn set_tile(&mut self, tile: usize) -> Result<(), i32> {
        if !(4..=64).contains(&tile) || tile % 4 != 0 {
            return Err(UNSUPPORTED);
        }
        self.tile = tile;
        self.output_valid = false;
        Ok(())
    }
    pub fn input_info(&self) -> Result<Tensor, i32> {
        self.tensor(self.input_id)
    }
    pub fn output_info(&self) -> Result<Tensor, i32> {
        self.tensor(self.output_id)
    }
    pub fn input(&mut self) -> Result<&mut [u8], i32> {
        if !self.prepared {
            return Err(GRAPH);
        }
        self.output_valid = false;
        let p = self.plans[self.input_id];
        Ok(&mut self.arena.as_deref_mut().ok_or(GRAPH)?[p.offset..p.offset + p.bytes])
    }
    pub fn arena_used(&self) -> usize {
        if self.prepared {
            self.required
        } else {
            0
        }
    }

    pub fn output(&self) -> Option<&[u8]> {
        if !self.output_valid {
            return None;
        }
        let p = self.plans[self.output_id];
        Some(&self.arena.as_deref()?[p.offset..p.offset + p.bytes])
    }
    pub fn invoke(
        &mut self,
        device: &mut impl Device,
        mut trace: impl FnMut(usize, usize, u8, &[u8]) -> Result<(), i32>,
    ) -> Result<(), i32> {
        self.output_valid = false;
        if !self.prepared {
            return Err(GRAPH);
        }
        self.records.fill(Record::default());
        for i in 0..self.info.operators {
            let op = tflite_cpu::compile(self, i)?;
            let kind = self.tensor(op.y)?.kind;
            let backend = tflite_cpu::select(&op, self.backend);
            let start = device.clock_us();
            let result = tflite_cpu::execute(
                &op,
                self.model,
                &self.plans,
                self.arena.as_deref_mut().ok_or(GRAPH)?,
                self.params[i],
                device,
                backend,
                self.tile,
            );
            let end = device.clock_us();
            self.records[i] = Record {
                kind: op.kind,
                backend: match backend {
                    Backend::Cpu => 0,
                    Backend::Synap => 1,
                    Backend::Pulp => 2,
                    _ => 0,
                },
                us: if start >= 0 && end >= start {
                    end - start
                } else {
                    -1
                },
                status: result.as_ref().err().copied().unwrap_or(0),
                tiles: result.as_ref().copied().unwrap_or(0),
            };
            result?;
            let p = self.plans[op.y];
            trace(
                i,
                op.y,
                kind,
                &self.arena.as_deref().ok_or(GRAPH)?[p.offset..p.offset + p.bytes],
            )?;
        }
        self.output_valid = true;
        Ok(())
    }
}
fn align(n: usize) -> Result<usize, i32> {
    n.checked_add(3)
        .filter(|v| *v <= u32::MAX as usize)
        .map(|v| v & !3)
        .ok_or(ARENA)
}
pub fn supported(k: i32) -> bool {
    matches!(
        k,
        0 | 2 | 3 | 6 | 9 | 14 | 17 | 18 | 22 | 25 | 34 | 39 | 41 | 65 | 97 | 114
    )
}
pub fn name(k: i32) -> &'static str {
    match k {
        0 => "ADD",
        2 => "CONCATENATION",
        3 => "CONV_2D",
        6 => "DEQUANTIZE",
        9 => "FULLY_CONNECTED",
        14 => "LOGISTIC",
        17 => "MAX_POOL_2D",
        18 => "MUL",
        22 => "RESHAPE",
        25 => "SOFTMAX",
        34 => "PAD",
        39 => "TRANSPOSE",
        41 => "SUB",
        65 => "SLICE",
        97 => "RESIZE_NEAREST_NEIGHBOR",
        114 => "QUANTIZE",
        _ => "UNSUPPORTED",
    }
}
