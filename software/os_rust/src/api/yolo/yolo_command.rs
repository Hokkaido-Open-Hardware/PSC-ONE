//! Synchronous shell integration; resident workspaces stay off the user stack.
use super::{
    yolo_display::{ImageSink, PlatformLcd, Renderer},
    yolo_postprocess::class_name,
    *,
};
use crate::api::{
    jpeg::jpeg_view,
    tflite::{
        tflite_file as file,
        tflite_graph::Graph,
        tflite_platform::Platform,
        tflite_runtime::{backend_name, Backend},
    },
    user::*,
};
use core::ptr::addr_of_mut;
static mut BUSY: bool = false;
static mut BACKEND: Backend = Backend::Cpu;
static mut DIAGNOSTICS: bool = false;
static mut DISPLAY: Renderer = Renderer::new();
static mut RESULT: YoloResult = YoloResult::new();
pub fn set_backend(backend: Backend) -> Result<(), i32> {
    unsafe {
        if BUSY {
            return Err(-205);
        }
        BACKEND = backend;
    }
    Ok(())
}
pub fn get_backend() -> Backend {
    unsafe { BACKEND }
}
pub fn diagnostics(enabled: bool) {
    unsafe {
        if !BUSY {
            DIAGNOSTICS = enabled;
        }
    }
}
pub fn cmd_backend(name: Option<&str>) {
    if let Some(name) = name {
        let b = match name {
            "cpu" => Backend::Cpu,
            "pulp" => Backend::Pulp,
            "npu" => Backend::Synap,
            "auto" => Backend::Auto,
            _ => {
                print(format_args!("usage: yolo_backend cpu|pulp|npu|auto\n"));
                return;
            }
        };
        if let Err(e) = set_backend(b) {
            print(format_args!("YOLO backend error {e}\n"));
            return;
        }
    }
    print(format_args!(
        "YOLO requested={} (applied after load/prepare)\n",
        backend_name(get_backend())
    ));
}
fn end_time(start: i32) -> i32 {
    if start == 0 {
        call_timer_measure_end_us()
    } else {
        -1
    }
}
fn record_backend(b: u8) -> &'static str {
    match b {
        1 => "npu",
        2 => "pulp",
        _ => "cpu",
    }
}
fn execution_report(g: &Graph<'_>, rc: i32, wall: i32, backend: Backend, diag: bool) {
    let e = &g.execution;
    let p = &g.profile;
    print(format_args!(
        "YOLO requested={} status={rc} completed={} CPU={} PULP={} NPU={} fallbacks={}\n",
        backend_name(backend),
        e.completed,
        e.operators[0],
        e.operators[2],
        e.operators[1],
        e.fallbacks
    ));
    print(format_args!(
        "YOLO invoke_wall_us={wall} operator_sum_us: CPU={} PULP={} NPU={}\n",
        e.invoke_us[0], e.invoke_us[2], e.invoke_us[1]
    ));
    print(format_args!(
        "YOLO CPU sum covers only completed CPU operators, not a CPU-only model benchmark\n"
    ));
    print(format_args!(
        "YOLO NPU successful_tiles={} profile_valid={} device_status={}\n",
        p.tiles, p.valid as u8, p.device_status
    ));
    for i in 0..e.completed as usize {
        let r = &g.records[i];
        let reason = g.operator_reason(i).unwrap_or("unknown");
        if diag {
            print(format_args!(
                "YOLO op={i} kind={} actual={} us={} tiles={} reason={reason}\n",
                r.kind,
                record_backend(r.backend),
                r.us,
                r.tiles
            ));
        }
        if backend == Backend::Cpu || r.backend != 0 {
            continue;
        }
        if (0..i).any(|j| g.records[j].backend == 0 && g.operator_reason(j) == Some(reason)) {
            continue;
        }
        let count = (i..e.completed as usize)
            .filter(|&j| g.records[j].backend == 0 && g.operator_reason(j) == Some(reason))
            .count();
        print(format_args!(
            "YOLO fallback count={count} reason={reason}\n"
        ));
    }
    if rc != 0 && (e.completed as usize) < g.info.operators {
        let r = &g.records[e.completed as usize];
        print(format_args!(
            "YOLO stopped op={} attempted={} status={} tiles={}; output invalid\n",
            e.completed,
            record_backend(r.backend),
            r.status,
            r.tiles
        ));
    }
}
/// Inference-only entry: preflight before model IO, failure invalidates all output.
#[inline(never)]
pub fn run(model: &str, jpeg: &str, result: &mut YoloResult) -> Result<(), i32> {
    unsafe {
        if BUSY {
            return Err(-205);
        }
        BUSY = true;
        *result = YoloResult::new();
        let backend = BACKEND;
        let diag = DIAGNOSTICS;
        let rc = (|| {
            print(format_args!("YOLO: check JPEG {jpeg}\n"));
            jpeg_view::probe(jpeg)?;
            print(format_args!(
                "YOLO: load {model}; profile=normalized-xywh COCO80\n"
            ));
            let start = call_timer_measure_begin();
            let loaded = file::load(model);
            let load_us = end_time(start);
            loaded?;
            if !file::is_graph() {
                return Err(PROFILE);
            }
            file::with_yolo(|g, work| {
                if !profile_ok(g) {
                    return Err(PROFILE);
                }
                g.set_backend(backend);
                g.profiling = true;
                let input = g.input()?;
                print(format_args!(
                    "YOLO: JPEG {jpeg} -> RGB/255 CHW [1,3,160,160]\n"
                ));
                let start = call_timer_measure_begin();
                let mut pre = work.pre().stream(input);
                let prepared = jpeg_view::decode_rgb(jpeg, &mut pre).and_then(|_| pre.finish());
                let preprocess_us = end_time(start);
                let geometry = prepared?;
                let input_hash = hash(input);
                print(format_args!(
                    "YOLO image={}x{} resize={}x{} pad_ltrb={},{},{},{} input_fnv={input_hash:x}\n",
                    geometry.width,
                    geometry.height,
                    geometry.resized_width,
                    geometry.resized_height,
                    geometry.left,
                    geometry.top,
                    SIDE as u32 - geometry.resized_width - geometry.left,
                    SIDE as u32 - geometry.resized_height - geometry.top
                ));
                let start = call_timer_measure_begin();
                let invoked=g.invoke_traced(&mut Platform,|op,id,kind,bytes| {
                    if diag { print(format_args!("TensorTrace op={op} tensor={id} type={kind} bytes={} fnv1a32={:x}\n",bytes.len(),hash(bytes))); } Ok(())
                },|op,begin| {
                    if begin && (op==0 || (op+1)%25==0 || op==288) { print(format_args!("YOLO requested={} operator {}/289\n",backend_name(backend),op+1)); }
                });
                let invoke_us = end_time(start);
                execution_report(
                    g,
                    invoked.as_ref().err().copied().unwrap_or(0),
                    invoke_us,
                    backend,
                    diag,
                );
                invoked?;
                let output = g.output().ok_or(OUTPUT)?;
                if output.len() != OUTPUT_BYTES
                    || g.execution.completed != 289
                    || g.execution.operators.iter().sum::<u32>() != 289
                {
                    return Err(OUTPUT);
                }
                let output_hash = hash(output);
                let start = call_timer_measure_begin();
                let post = work.post().process(output, geometry, result);
                let postprocess_us = end_time(start);
                post?;
                result.input_hash = input_hash;
                result.output_hash = output_hash;
                result.load_us = load_us;
                result.preprocess_us = preprocess_us;
                result.invoke_us = invoke_us;
                result.postprocess_us = postprocess_us;
                Ok(())
            })
        })();
        if rc.is_err() {
            *result = YoloResult::new();
            file::psc_tflite_reset();
        }
        BUSY = false;
        rc
    }
}
pub fn command(model: &str, jpeg: &str) {
    unsafe {
        let start = call_timer_measure_begin();
        let cleared = (&mut *addr_of_mut!(DISPLAY)).clear(&mut PlatformLcd);
        let clear_us = end_time(start);
        print(format_args!(
            "YOLO LCD us: clear={clear_us} (-1=unavailable)\n"
        ));
        let r = &mut *addr_of_mut!(RESULT);
        if let Err(e) = cleared {
            *r = YoloResult::new();
            file::psc_tflite_reset();
            print(format_args!(
                "YOLO LCD clear error {e}: old screen may remain; inference not started\n"
            ));
            return;
        }
        if let Err(e) = run(model, jpeg, r) {
            print(format_args!("YOLO error {e}: {}\n", error_string(e)));
            return;
        }
        print(format_args!(
            "YOLO complete: 289 operators; requested={} output=[1,84,525] fnv={:x}\n",
            backend_name(get_backend()),
            r.output_hash
        ));
        print(format_args!(
            "YOLO conf_milli=250 iou_milli=450 candidates={} nms={} detections={} truncated={}\n",
            r.candidates, r.nms_count, r.count, r.truncated
        ));
        for d in &r.detections[..r.count as usize] {
            print(format_args!(
                "DET anchor={} class={} name={} score_milli={} xyxy_milli={},{},{},{}\n",
                d.anchor,
                d.class_id,
                class_name(d.class_id as usize),
                (d.score * 1000.0 + 0.5) as u32,
                (d.x1 * 1000.0 + 0.5) as u32,
                (d.y1 * 1000.0 + 0.5) as u32,
                (d.x2 * 1000.0 + 0.5) as u32,
                (d.y2 * 1000.0 + 0.5) as u32
            ));
        }
        print(format_args!(
            "YOLO us: load_prepare={} jpeg_preprocess={} invoke_wall={} nms={} (-1=unavailable)\n",
            r.load_us, r.preprocess_us, r.invoke_us, r.postprocess_us
        ));
        print(format_args!("YOLO invoke_wall includes progress UART and optional tensor diagnostics; coordinates are original-image pixels x1000\n"));
        print(format_args!(
            "YOLO arena={}/{} bytes\n",
            file::psc_tflite_arena_used(),
            file::psc_tflite_arena_capacity()
        ));
        let start = call_timer_measure_begin();
        let displayed = (|| {
            Renderer::validate(r)?;
            jpeg_view::decode_rgb(
                jpeg,
                &mut ImageSink {
                    lcd: &mut PlatformLcd,
                    geometry: r.geometry,
                },
            )?;
            (&mut *addr_of_mut!(DISPLAY)).overlays(&mut PlatformLcd, r)
        })();
        let lcd_us = end_time(start);
        match displayed {
            Ok(()) => print(format_args!(
                "YOLO LCD complete: JPEG + {} detections (480x320 landscape)\n",
                r.count
            )),
            Err(e) => print(format_args!(
                "YOLO LCD error {e}: {}; inference results retained\n",
                error_string(e)
            )),
        }
        print(format_args!(
            "YOLO LCD us: jpeg_overlay={lcd_us} (-1=unavailable)\n"
        ));
    }
}
fn error_string(e: i32) -> &'static str {
    if e <= -300 {
        "YOLO profile/input/output error"
    } else if e <= -200 {
        file::error_string(e)
    } else {
        match e {
            -100 => "invalid JPEG format",
            -101 => "unsupported JPEG",
            -102 => "image exceeds 480x320",
            -103 => "truncated JPEG",
            -104 => "LCD transfer failed",
            -105 => "JPEG workspace insufficient",
            _ => file::error_string(e),
        }
    }
}
