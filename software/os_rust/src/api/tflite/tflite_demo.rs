//! Fixed-input inference diagnostics and repeated CPU/NPU output comparison.
use super::{tflite_file::*, tflite_platform::Platform, tflite_runtime::*};
use crate::api::user::*;
const INPUT: [i8; 16] = [
    -128, 127, -3, 0, 1, -1, 64, -64, 7, -11, 31, -32, 90, -100, 2, -2,
];
const TRACE: [[i32; 3]; 20] = [
    [1380, 156, 127],
    [797, 83, 83],
    [-596, -92, -17],
    [-2514, -331, -17],
    [-1552, -211, -17],
    [-920, -132, -17],
    [2472, 292, 127],
    [2489, 294, 127],
    [1411, 160, 127],
    [-417, -69, -17],
    [-2365, -313, -17],
    [-2363, -312, -17],
    [-1251, -173, -17],
    [716, 73, 73],
    [2653, 315, 127],
    [1665, 191, 127],
    [-695, -36, -36],
    [322, 27, 27],
    [169, 18, 18],
    [16, 8, 8],
];

/// Only the serialized shell command loop changes this setting.
pub fn diagnostics(enabled: bool) {
    super::tflite_file::diagnostics(enabled);
}

/// Reuse the original immutable demo oracle; tracing is outside timed inference.
pub fn run(name: &str, backend: Backend) -> Result<(), i32> {
    load(name)?;
    if is_graph() {
        return run_graph(backend);
    }
    unsafe {
        with_runtime(|rt| {
            rt.set_backend(backend);
            let input_size = rt.input().len();
            for (i, v) in rt.input().iter_mut().enumerate() {
                *v = INPUT[i % 16];
            }
            let mut trace = [[0; 3]; 20];
            let mut count = 0;
            let mut valid = true;
            rt.invoke(&mut Platform, |layer, channel, values| {
                let index = if layer == 0 { channel } else { 16 + channel };
                if layer > 1 || channel >= if layer == 0 { 16 } else { 4 } || index != count {
                    valid = false;
                    return;
                }
                trace[index].copy_from_slice(&values[2..]);
                count += 1;
            })?;
            let timing = call_timer_measure_begin() == 0;
            let result = rt.invoke(&mut Platform, |_, _, _| {});
            let elapsed = if timing {
                call_timer_measure_end_us()
            } else {
                -1
            };
            result?;
            let output = rt.output().ok_or(-203)?;
            if diagnostics_enabled() {
                for (i, row) in trace[..count].iter().enumerate() {
                    print(format_args!(
                        "channel={i} acc={} requant={} output={}\n",
                        row[0], row[1], row[2]
                    ));
                }
            }
            print(format_args!("Output: ["));
            for (i, v) in output.iter().enumerate() {
                print(format_args!("{}{v}", if i == 0 { "" } else { "," }));
            }
            print(format_args!("]\n"));
            print(format_args!(
                "TFLite {} output={:?}; invoke={elapsed} us; arena={} / 4096\n",
                backend_name(backend),
                output,
                rt.arena_used()
            ));
            if input_size == 16 && count == 20 && output.len() == 4 {
                print(format_args!(
                    "Validation (demo oracle): {}\n",
                    if valid && trace == TRACE {
                        "PASS"
                    } else {
                        "FAIL"
                    }
                ));
            } else {
                print(format_args!(
                    "Repeated demo input; application-specific validation required.\n"
                ));
            }
            Ok(())
        })
    }
}

/// Compare every output byte and rotate backend order across three warm samples.
pub fn bench(name: &str, quick: bool) -> Result<(), i32> {
    load(name)?;
    if is_graph() {
        return bench_graph(quick);
    }
    unsafe {
        with_runtime(|rt| {
            for (i, v) in rt.input().iter_mut().enumerate() {
                *v = INPUT[i % 16];
            }
            rt.invoke(&mut Platform, |_, _, _| {})?;
            let mut reference = [0; 4096];
            let output = rt.output().ok_or(-203)?;
            let size = output.len();
            reference[..size].copy_from_slice(output);
            let modes = [
                (Backend::Cpu, 4),
                (Backend::Pulp, 4),
                (Backend::Synap, 32),
                (Backend::Synap, 16),
                (Backend::Auto, 4),
                (Backend::Synap, 4),
                (Backend::Synap, 8),
                (Backend::Synap, 12),
                (Backend::Synap, 64),
            ];
            let count = if quick { 5 } else { modes.len() };
            for sample in 0..3 {
                for turn in 0..count {
                    let (backend, tile) = modes[(sample + turn) % count];
                    rt.set_backend(backend);
                    rt.set_tile(tile)?;
                    rt.invoke(&mut Platform, |_, _, _| {})?;
                    let timing = call_timer_measure_begin() == 0;
                    let result = rt.invoke(&mut Platform, |_, _, _| {});
                    let elapsed = if timing {
                        call_timer_measure_end_us()
                    } else {
                        -1
                    };
                    result?;
                    if rt.output() != Some(&reference[..size]) {
                        print(format_args!(
                            "Comparison: FAIL backend={}\n",
                            backend_name(backend)
                        ));
                        return Err(-203);
                    }
                    print(format_args!(
                        "BENCH sample={sample} backend={} tile={tile} invoke={elapsed} us\n",
                        backend_name(backend)
                    ));
                }
            }
            rt.set_backend(Backend::Cpu);
            rt.set_tile(4)?;
            rt.invoke(&mut Platform, |_, _, _| {})?;
            print(format_args!(
                "Comparison: PASS ({size} output bytes, three warm samples)\n"
            ));
            Ok(())
        })
    }
}

fn hash(bytes: &[u8]) -> u32 {
    bytes
        .iter()
        .fold(2166136261u32, |h, b| (h ^ *b as u32).wrapping_mul(16777619))
}
fn values(kind: u8, bytes: &[u8], limit: usize) {
    let width = if kind == 9 { 1 } else { 4 };
    for (i, chunk) in bytes.chunks_exact(width).take(limit).enumerate() {
        if i != 0 {
            print(format_args!(","));
        }
        match kind {
            9 => print(format_args!("{}", chunk[0] as i8)),
            0 => print(format_args!(
                "{:.5e}",
                f32::from_le_bytes(chunk.try_into().unwrap())
            )),
            _ => print(format_args!(
                "{}",
                i32::from_le_bytes(chunk.try_into().unwrap())
            )),
        }
    }
}
fn run_graph(backend: Backend) -> Result<(), i32> {
    unsafe {
        with_graph(|g| {
            let input_kind = g.input_info()?.kind;
            g.set_backend(backend);
            let input = g.input()?;
            if input_kind == 9 {
                for (i, b) in input.iter_mut().enumerate() {
                    *b = INPUT[i % 16] as u8;
                }
            } else {
                input.fill(0);
            }
            print(format_args!(
                "TFLite: prepare {} operators PASS; backend={}\n",
                g.info.operators,
                backend_name(backend)
            ));
            let timing = call_timer_measure_begin() == 0;
            let result = g.invoke(&mut Platform, |op, tensor, kind, bytes| {
                if diagnostics_enabled() {
                    print(format_args!(
                        "TensorTrace op={op} tensor={tensor} type={kind} bytes={} fnv1a32={:08x}\n",
                        bytes.len(),
                        hash(bytes)
                    ));
                    if matches!(op, 0 | 3 | 4 | 5 | 288) {
                        print(format_args!("TensorValues op={op} first16=["));
                        values(kind, bytes, 16);
                        print(format_args!("]\n"));
                    }
                }
                Ok(())
            });
            let elapsed = if timing {
                call_timer_measure_end_us()
            } else {
                -1
            };
            result?;
            let (mut counts, mut times, mut tiles) = ([0; 3], [0i64; 3], 0u32);
            for (i, r) in g.records[..g.info.operators].iter().enumerate() {
                counts[r.backend as usize] += 1;
                times[r.backend as usize] += r.us as i64;
                tiles += r.tiles;
                if diagnostics_enabled() {
                    print(format_args!(
                        "Operator {i} {} backend={} time={} us status={}\n",
                        super::tflite_graph::name(r.kind),
                        ["cpu", "npu", "pulp"][r.backend as usize],
                        r.us,
                        r.status
                    ));
                }
            }
            let output = g.output().ok_or(-203)?;
            print(format_args!(
                "TFLite: invoke complete; output tensor ready\nOutput: ["
            ));
            values(g.output_info()?.kind, output, 32);
            print(format_args!(
                "]\nOutput bytes={} fnv1a32={:08x}\n",
                output.len(),
                hash(output)
            ));
            let (load, prepare) = times_from_file();
            print(format_args!("Arena: {} / {} bytes\nLoad: {load} us; Prepare: {prepare} us; Invoke: {elapsed} us\nExecution: cpu={} pulp={} npu={}; times cpu={} pulp={} npu={} us; NPU tiles={tiles}\n",g.required,super::tflite_graph::ARENA_CAPACITY,counts[0],counts[2],counts[1],times[0],times[2],times[1]));
            Ok(())
        })
    }
}
fn times_from_file() -> (i32, i32) {
    super::tflite_file::times()
}
fn bench_graph(quick: bool) -> Result<(), i32> {
    unsafe {
        with_graph(|g| {
            let kind = g.input_info()?.kind;
            let input = g.input()?;
            if kind == 9 {
                for (i, b) in input.iter_mut().enumerate() {
                    *b = INPUT[i % 16] as u8;
                }
            } else {
                input.fill(0);
            }
            g.set_backend(Backend::Cpu);
            g.invoke(&mut Platform, |_, _, _, _| Ok(()))?;
            // Match the C command's bounded comparison storage. No hash-only PASS.
            let mut reference = [0u8; 4096];
            let output = g.output().ok_or(-203)?;
            if output.len() > reference.len() {
                print(format_args!(
                    "Comparison: FAIL reference (output exceeds 4096 bytes)\n"
                ));
                return Err(-210);
            }
            let size = output.len();
            reference[..size].copy_from_slice(output);
            let modes = [
                (Backend::Cpu, 4),
                (Backend::Pulp, 4),
                (Backend::Synap, 32),
                (Backend::Synap, 16),
                (Backend::Auto, 4),
                (Backend::Synap, 4),
                (Backend::Synap, 8),
                (Backend::Synap, 12),
                (Backend::Synap, 64),
            ];
            let count = if quick { 5 } else { modes.len() };
            for sample in 0..3 {
                for turn in 0..count {
                    let (mode, tile) = modes[(sample + turn) % count];
                    g.set_backend(mode);
                    g.set_tile(tile)?;
                    g.invoke(&mut Platform, |_, _, _, _| Ok(()))?;
                    let timing = call_timer_measure_begin() == 0;
                    let result = g.invoke(&mut Platform, |_, _, _, _| Ok(()));
                    let elapsed = if timing {
                        call_timer_measure_end_us()
                    } else {
                        -1
                    };
                    result?;
                    if g.output() != Some(&reference[..size]) {
                        return Err(-203);
                    }
                    print(format_args!(
                        "BENCH_GRAPH sample={sample} backend={} tile={tile} invoke={elapsed} us\n",
                        backend_name(mode)
                    ));
                }
            }
            print(format_args!("Comparison: PASS (all graph output bytes, cpu/npu/pulp/auto, three warm samples)\n"));
            g.set_backend(Backend::Cpu);
            g.set_tile(4)?;
            g.invoke(&mut Platform, |_, _, _, _| Ok(()))?;
            Ok(())
        })
    }
}
