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
static mut DIAGNOSTICS: bool = true;

/// Only the serialized shell command loop changes this setting.
pub fn diagnostics(enabled: bool) {
    unsafe {
        DIAGNOSTICS = enabled;
    }
}

/// Reuse the original immutable demo oracle; tracing is outside timed inference.
pub fn run(name: &str, backend: Backend) -> Result<(), i32> {
    load(name)?;
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
            if DIAGNOSTICS {
                for (i, row) in trace[..count].iter().enumerate() {
                    print(format_args!(
                        "channel={i} acc={} requant={} output={}\n",
                        row[0], row[1], row[2]
                    ));
                }
            }
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
