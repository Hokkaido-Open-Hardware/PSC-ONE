//! tflite_runtime.cc: bounded INT8 fully-connected execution without heap allocation.
use super::{
    tflite_inspect::*,
    tflite_quant::*,
    tflite_synap::{Device, Scratch},
};
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Backend {
    Cpu,
    Synap,
    Pulp,
    Auto,
}
#[derive(Default, Clone, Copy)]
pub struct Profile {
    pub tiles: u32,
    pub packing_us: u32,
    pub syscall_us: u32,
    pub copy_in_us: u32,
    pub execute_us: u32,
    pub copy_out_us: u32,
    pub partial_us: u32,
    pub post_us: u32,
    pub valid: bool,
    pub device_status: i32,
}
#[derive(Default, Clone, Copy)]
struct Fc {
    m: usize,
    k: usize,
    n: usize,
    multiplier: i32,
    shift: i32,
    row_sum_offset: usize,
}
/// Rust borrowing prevents reset, prepare, and input mutation during invocation.
pub struct Runtime<'a> {
    pub model: Model<'a>,
    arena: [i8; 4096],
    offsets: [usize; 32],
    used: usize,
    required: usize,
    fc: [Fc; 8],
    backend: Backend,
    tile: usize,
    output_valid: bool,
    pub profiling: bool,
    pub profile: Profile,
    scratch: Scratch,
    dots: [i32; 4096],
}
impl<'a> Runtime<'a> {
    /// A resident firmware runtime is initialized here, not copied through the stack.
    pub(super) const fn empty() -> Self {
        Self {
            model: Model {
                bytes: &[],
                tensors: [Tensor {
                    shape: [0; 4],
                    rank: 0,
                    kind: 0,
                    data: 0,
                    bytes: 0,
                    scale: 0.0,
                    zero: 0,
                }; 32],
                operators: [Operator {
                    x: 0,
                    w: 0,
                    bias: None,
                    y: 0,
                    relu: false,
                }; 8],
                input: 0,
                output: 0,
                info: Info {
                    version: 0,
                    tensors: 0,
                    operators: 0,
                    constant_bytes: 0,
                    tensor_bytes: 0,
                },
            },
            arena: [0; 4096],
            offsets: [0; 32],
            used: 0,
            required: 0,
            fc: [Fc {
                m: 0,
                k: 0,
                n: 0,
                multiplier: 0,
                shift: 0,
                row_sum_offset: 0,
            }; 8],
            backend: Backend::Cpu,
            tile: 4,
            output_valid: false,
            profiling: false,
            profile: Profile {
                tiles: 0,
                packing_us: 0,
                syscall_us: 0,
                copy_in_us: 0,
                execute_us: 0,
                copy_out_us: 0,
                partial_us: 0,
                post_us: 0,
                valid: false,
                device_status: 0,
            },
            scratch: Scratch::new(),
            dots: [0; 4096],
        }
    }
    /// Safety: aligned uninitialized storage, with no outstanding model/arena borrows.
    #[cfg(any(target_arch = "riscv32", test))]
    pub(super) unsafe fn init_at(p: *mut Self) {
        use core::ptr::{addr_of_mut, write_bytes};
        // Model metadata is small; the 40 KiB GEMM scratch is written in place.
        addr_of_mut!((*p).model).write(Model {
            bytes: &[],
            tensors: [Tensor {
                shape: [0; 4],
                rank: 0,
                kind: 0,
                data: 0,
                bytes: 0,
                scale: 0.0,
                zero: 0,
            }; 32],
            operators: [Operator {
                x: 0,
                w: 0,
                bias: None,
                y: 0,
                relu: false,
            }; 8],
            input: 0,
            output: 0,
            info: Info::default(),
        });
        write_bytes(addr_of_mut!((*p).arena).cast::<i8>(), 0, 4096);
        write_bytes(addr_of_mut!((*p).offsets).cast::<usize>(), 0, 32);
        addr_of_mut!((*p).used).write(0);
        addr_of_mut!((*p).required).write(0);
        addr_of_mut!((*p).fc).write([Fc::default(); 8]);
        addr_of_mut!((*p).backend).write(Backend::Cpu);
        addr_of_mut!((*p).tile).write(4);
        addr_of_mut!((*p).output_valid).write(false);
        addr_of_mut!((*p).profiling).write(false);
        addr_of_mut!((*p).profile).write(Profile::ZERO);
        // Scratch contains only integer arrays; all-zero is its valid initial value.
        write_bytes(addr_of_mut!((*p).scratch), 0, 1);
        write_bytes(addr_of_mut!((*p).dots).cast::<i32>(), 0, 4096);
    }
    pub(super) fn reset(&mut self) {
        self.model.bytes = &[];
        self.model.info = Info::default();
        self.output_valid = false;
        self.used = 0;
        self.required = 0;
    }
    /// Host convenience. Firmware uses prepare_into to avoid large return values.
    pub fn prepare(bytes: &'a [u8]) -> Result<Self, i32> {
        let mut rt = Self::empty();
        rt.prepare_into(bytes)?;
        Ok(rt)
    }
    /// Prove accumulator bounds and initialize the resident workspace in place.
    pub(super) fn prepare_into(&mut self, bytes: &'a [u8]) -> Result<(), i32> {
        self.reset();
        self.model = inspect(bytes)?;
        let mut planned = 0usize;
        for t in &self.model.tensors[..self.model.info.tensors as usize] {
            if t.data == 0 {
                planned = (planned + 3) & !3;
                planned += t.bytes;
            }
        }
        for op in &self.model.operators[..self.model.info.operators as usize] {
            planned = (planned + 3) & !3;
            planned += self.model.tensors[op.w].shape[0] * 4;
        }
        self.required = planned;
        if planned > self.arena.len() {
            return Err(-210);
        }

        self.arena.fill(0);
        self.offsets.fill(0);
        self.fc.fill(Fc::default());
        self.backend = Backend::Cpu;
        self.tile = 4;
        self.profiling = false;
        self.profile = Profile::default();
        for i in 0..self.model.info.tensors as usize {
            let t = self.model.tensors[i];
            if t.data == 0 {
                let pos = (self.used + 3) & !3;
                if t.bytes > 4096usize.saturating_sub(pos) {
                    return Err(-210);
                }
                self.offsets[i] = pos;
                self.used = pos + t.bytes;
            }
        }
        for i in 0..self.model.info.operators as usize {
            let op = self.model.operators[i];
            let (x, w, y) = (
                self.model.tensors[op.x],
                self.model.tensors[op.w],
                self.model.tensors[op.y],
            );
            let (multiplier, shift) = quantize(x.scale as f64 * w.scale as f64 / y.scale as f64)?;
            let (m, k, n) = (x.shape[0], w.shape[1], w.shape[0]);
            let pos = (self.used + 3) & !3;
            if n * 4 > 4096usize.saturating_sub(pos) {
                return Err(-210);
            }
            self.used = pos + n * 4;
            let f = Fc {
                m,
                k,
                n,
                multiplier,
                shift,
                row_sum_offset: pos,
            };
            for c in 0..n {
                let bias = self.bias(op.bias, c) as i64;
                let (mut low, mut high) = (bias, bias);
                let mut sum = 0;
                for j in 0..k {
                    let v = bytes[w.data + c * k + j] as i8 as i32;
                    sum += v;
                    let a = (-128 - x.zero) * v;
                    let b = (127 - x.zero) * v;
                    low += a.min(b) as i64;
                    high += a.max(b) as i64;
                }
                for (j, byte) in sum.to_le_bytes().iter().enumerate() {
                    self.arena[pos + c * 4 + j] = *byte as i8;
                }
                let factor = 1i64 << shift.max(0);
                if low < (i32::MIN as i64 + 128) / factor || high > (i32::MAX as i64 - 128) / factor
                {
                    return Err(GRAPH);
                }
            }
            self.fc[i] = f;
        }
        Ok(())
    }

    // Row sums share the bounded arena with activations; no per-layer oversized array.
    fn row_sum(&self, layer: usize, c: usize) -> i32 {
        let p = self.fc[layer].row_sum_offset + c * 4;
        i32::from_le_bytes(core::array::from_fn(|j| self.arena[p + j] as u8))
    }

    fn bias(&self, id: Option<usize>, channel: usize) -> i32 {
        if let Some(id) = id {
            let p = self.model.tensors[id].data + channel * 4;
            i32::from_le_bytes(self.model.bytes[p..p + 4].try_into().unwrap())
        } else {
            0
        }
    }

    fn value(&self, id: usize, index: usize) -> i8 {
        let t = self.model.tensors[id];
        if t.data != 0 {
            self.model.bytes[t.data + index] as i8
        } else {
            self.arena[self.offsets[id] + index]
        }
    }

    pub fn input(&mut self) -> &mut [i8] {
        self.output_valid = false;
        let id = self.model.input;
        let start = self.offsets[id];
        &mut self.arena[start..start + self.model.tensors[id].bytes]
    }

    pub fn output(&self) -> Option<&[i8]> {
        if !self.output_valid {
            return None;
        }
        let id = self.model.output;
        let start = self.offsets[id];
        Some(&self.arena[start..start + self.model.tensors[id].bytes])
    }

    pub fn arena_required(&self) -> usize {
        self.required
    }

    pub fn arena_used(&self) -> usize {
        self.used
    }

    pub fn set_backend(&mut self, backend: Backend) {
        self.backend = backend;
        self.output_valid = false;
    }

    pub fn set_tile(&mut self, tile: usize) -> Result<(), i32> {
        if tile < 4 || tile > 64 || tile % 4 != 0 {
            return Err(UNSUPPORTED);
        }
        self.tile = tile;
        self.output_valid = false;
        Ok(())
    }

    /// AUTO uses only measured unpadded square shapes; PULP safely falls back to CPU.
    pub fn selection(&self, i: usize) -> (Backend, usize) {
        let f = &self.fc[i];
        match self.backend {
            Backend::Synap => (Backend::Synap, self.tile),
            Backend::Auto if matches!(f.m, 16 | 32) && f.k == f.m && f.n == f.m => {
                (Backend::Synap, f.m)
            }
            Backend::Pulp | Backend::Auto
                if cfg!(feature = "pulp") && (4..=8192).contains(&f.k) =>
            {
                (Backend::Pulp, self.tile)
            }
            _ => (Backend::Cpu, self.tile),
        }
    }

    /// The trace receives raw dot, zero-point correction, bias, requantization and output.
    pub fn invoke(
        &mut self,
        device: &mut impl Device,
        mut trace: impl FnMut(usize, usize, [i32; 5]),
    ) -> Result<(), i32> {
        self.output_valid = false;
        self.profile = Profile {
            valid: self.profiling,
            ..Profile::default()
        };
        for layer in 0..self.model.info.operators as usize {
            let op = self.model.operators[layer];
            let (m, k, n, multiplier, shift) = {
                let f = &self.fc[layer];
                (f.m, f.k, f.n, f.multiplier, f.shift)
            };
            let (backend, tile) = self.selection(layer);
            let block = if backend == Backend::Synap { tile } else { 1 };
            let xzero = self.model.tensors[op.x].zero;
            let yzero = self.model.tensors[op.y].zero;
            let minimum = if op.relu { yzero } else { -128 };
            for row in (0..m).step_by(block) {
                let rows = (m - row).min(block);
                for first in (0..n).step_by(block) {
                    let cols = (n - first).min(block);
                    if backend == Backend::Synap {
                        let x = self.model.tensors[op.x];
                        let w = self.model.tensors[op.w];
                        let input = if x.data != 0 {
                            unsafe {
                                core::slice::from_raw_parts(
                                    self.model.bytes.as_ptr().add(x.data + row * k).cast::<i8>(),
                                    rows * k,
                                )
                            }
                        } else {
                            &self.arena[self.offsets[op.x] + row * k
                                ..self.offsets[op.x] + (row + rows) * k]
                        };
                        let weights = unsafe {
                            core::slice::from_raw_parts(
                                self.model
                                    .bytes
                                    .as_ptr()
                                    .add(w.data + first * k)
                                    .cast::<i8>(),
                                cols * k,
                            )
                        };
                        if let Err(e) = self.scratch.batch(
                            device,
                            input,
                            weights,
                            rows,
                            k,
                            cols,
                            tile,
                            &mut self.dots,
                            if self.profiling {
                                Some(&mut self.profile)
                            } else {
                                None
                            },
                        ) {
                            self.profile.valid = false;
                            return Err(e);
                        }
                    } else {
                        let mut dot = 0i32;
                        let mut j = 0;
                        if backend == Backend::Pulp {
                            while j + 4 <= k {
                                let a = core::array::from_fn(|lane| {
                                    self.value(op.x, row * k + j + lane) as u8
                                });
                                let b = core::array::from_fn(|lane| {
                                    self.value(op.w, first * k + j + lane) as u8
                                });
                                dot = dot.wrapping_add(super::tflite_cpu::dot4(a, b));
                                j += 4;
                            }
                        }
                        while j < k {
                            dot = dot.wrapping_add(
                                self.value(op.x, row * k + j) as i32
                                    * self.value(op.w, first * k + j) as i32,
                            );
                            j += 1;
                        }
                        self.dots[0] = dot;
                    }
                    let before = if self.profiling {
                        device.clock_us()
                    } else {
                        -1
                    };
                    for sample in 0..rows {
                        for local in 0..cols {
                            let c = first + local;
                            let index = (row + sample) * n + c;
                            let raw = self.dots[sample * cols + local];
                            let corrected =
                                (raw as i64 - xzero as i64 * self.row_sum(layer, c) as i64) as i32;
                            let biased = corrected.wrapping_add(self.bias(op.bias, c));
                            let q = requantize(biased, multiplier, shift) + yzero;
                            let out = q.clamp(minimum, 127) as i8;
                            self.arena[self.offsets[op.y] + index] = out;
                            trace(layer, index, [raw, corrected, biased, q, out as i32]);
                        }
                    }
                    if self.profiling {
                        let after = device.clock_us();
                        if before < 0 || after < before {
                            self.profile.valid = false;
                        } else {
                            self.profile.post_us += (after - before) as u32;
                        }
                    }
                }
            }
        }
        self.output_valid = true;
        Ok(())
    }
}

pub fn backend_name(backend: Backend) -> &'static str {
    match backend {
        Backend::Cpu => "cpu",
        Backend::Synap => "npu",
        Backend::Pulp => "pulp",
        Backend::Auto => "auto",
    }
}

impl Profile {
    pub const ZERO: Self = Self {
        tiles: 0,
        packing_us: 0,
        syscall_us: 0,
        copy_in_us: 0,
        execute_us: 0,
        copy_out_us: 0,
        partial_us: 0,
        post_us: 0,
        valid: false,
        device_status: 0,
    };
}
