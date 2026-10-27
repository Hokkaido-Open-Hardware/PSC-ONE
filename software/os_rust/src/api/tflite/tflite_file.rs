//! Resident Rust model ownership and synchronous MicroPython ABI.
use super::{
    tflite_graph::{Graph, ARENA_CAPACITY},
    tflite_inspect::*,
    tflite_platform::Platform,
    tflite_runtime::*,
};
use crate::{
    api::user::{self, UserSd},
    fs::fat32_stream::File,
    kernel::user_memory::*,
};
use core::ptr::{addr_of_mut, null, null_mut};
// FC and generic graph execution are mutually exclusive. YOLO scratch is only
// live with a generic graph, so the complete resident state shares one allocation.
use core::mem::ManuallyDrop;
struct GenericState {
    graph: Graph<'static>,
    yolo: crate::api::yolo::Workspace,
}
impl GenericState {
    const fn new() -> Self {
        Self {
            graph: Graph::new(),
            yolo: crate::api::yolo::Workspace::new(),
        }
    }
}
union Storage {
    fc: ManuallyDrop<Runtime<'static>>,
    generic: ManuallyDrop<GenericState>,
}
static mut STORAGE: Storage = Storage {
    generic: ManuallyDrop::new(GenericState::new()),
};
static mut STORAGE_FC: bool = false;
unsafe fn fc_ptr() -> *mut Runtime<'static> {
    addr_of_mut!((*addr_of_mut!(STORAGE)).fc).cast()
}
unsafe fn generic_ptr() -> *mut GenericState {
    addr_of_mut!((*addr_of_mut!(STORAGE)).generic).cast()
}
unsafe fn graph_ptr() -> *mut Graph<'static> {
    addr_of_mut!((*generic_ptr()).graph)
}
unsafe fn activate_fc() {
    // Call only after all graph borrows have ended. Neither member has a destructor.
    Runtime::init_at(fc_ptr());
    STORAGE_FC = true;
}
static mut FC_READY: bool = false;
static mut GENERIC: bool = false;
static mut BUSY: bool = false;
static mut DIAGNOSTICS: bool = true;
static mut LOAD_US: i32 = -1;
static mut PREPARE_US: i32 = -1;
pub fn diagnostics(enabled: bool) {
    unsafe {
        DIAGNOSTICS = enabled;
    }
}
pub fn diagnostics_enabled() -> bool {
    unsafe { DIAGNOSTICS }
}
pub fn is_graph() -> bool {
    unsafe { GENERIC }
}
pub fn times() -> (i32, i32) {
    unsafe { (LOAD_US, PREPARE_US) }
}
pub unsafe fn with_runtime<T>(
    f: impl FnOnce(&mut Runtime<'static>) -> Result<T, i32>,
) -> Result<T, i32> {
    if BUSY {
        return Err(-205);
    }
    BUSY = true;
    let result = if FC_READY {
        f(&mut *fc_ptr())
    } else {
        Err(GRAPH)
    };
    BUSY = false;
    result
}
pub unsafe fn with_graph<T>(
    f: impl FnOnce(&mut Graph<'static>) -> Result<T, i32>,
) -> Result<T, i32> {
    if BUSY {
        return Err(-205);
    }
    BUSY = true;
    let result = if STORAGE_FC {
        Err(GRAPH)
    } else {
        f(&mut *graph_ptr())
    };
    BUSY = false;
    result
}
unsafe fn reset_inner() {
    FC_READY = false;
    if STORAGE_FC {
        (&mut *fc_ptr()).reset();
        Graph::init_at(graph_ptr());
        crate::api::yolo::Workspace::init_at(addr_of_mut!((*generic_ptr()).yolo));
        STORAGE_FC = false;
    } else {
        (&mut *graph_ptr()).reset();
    }
    GENERIC = false;
}
/// All existing model/arena borrows are dropped before replacing the backing bytes.
unsafe fn read_model(name: &str) -> Result<&'static [u8], i32> {
    reset_inner();
    let mut file = File::default();
    let result = (|| {
        file.open(&mut UserSd, name)?;
        let size = file.file_size as usize;
        if !(8..=MODEL_CAPACITY).contains(&size) {
            return Err(SIZE);
        }
        let bytes = core::slice::from_raw_parts_mut(USER_MODEL_BASE as *mut u8, size);
        let mut offset = 0;
        while offset < size {
            let end = (offset + 4096).min(size);
            let mut actual = 0;
            file.read(&mut UserSd, &mut bytes[offset..end], &mut actual)?;
            if actual as usize != end - offset {
                return Err(-204);
            }
            offset = end;
            if DIAGNOSTICS && (offset % (512 * 1024) == 0 || offset == size) {
                user::print(format_args!("Model read: {offset} / {size} bytes\n"));
            }
        }
        Ok(&*bytes)
    })();
    file.close();
    result
}
pub fn load(name: &str) -> Result<(), i32> {
    unsafe {
        if BUSY {
            return Err(-205);
        }
        BUSY = true;
        let result = (|| {
            let timing = user::call_timer_measure_begin() == 0;
            let bytes = read_model(name);
            LOAD_US = if timing {
                user::call_timer_measure_end_us()
            } else {
                -1
            };
            PREPARE_US = -1;
            let bytes = bytes?;
            let timing = user::call_timer_measure_begin() == 0;
            let graph = &mut *graph_ptr();
            let prepared = (|| {
                graph.analyze(bytes)?;
                GENERIC = !graph.is_legacy_fc();
                if GENERIC {
                    graph.prepare(
                        bytes,
                        core::slice::from_raw_parts_mut(USER_ARENA_BASE as *mut u8, ARENA_CAPACITY),
                    )
                } else {
                    activate_fc();
                    (&mut *fc_ptr()).prepare_into(bytes)?;
                    FC_READY = true;
                    Ok(())
                }
            })();
            PREPARE_US = if timing {
                user::call_timer_measure_end_us()
            } else {
                -1
            };
            user::print(format_args!(
                "Model: {} / {} bytes; Arena required: {} / {} bytes\n",
                bytes.len(),
                MODEL_CAPACITY,
                if STORAGE_FC {
                    (&*fc_ptr()).arena_required()
                } else {
                    (&*graph_ptr()).required
                },
                if GENERIC { ARENA_CAPACITY } else { 4096 }
            ));
            prepared
        })();
        BUSY = false;
        result
    }
}
/// Inspection remains available for large or unsupported execution profiles.
pub fn info(name: &str) -> Result<(), i32> {
    unsafe {
        if BUSY {
            return Err(-205);
        }
        BUSY = true;
        let result = (|| {
            let timing = user::call_timer_measure_begin() == 0;
            let bytes = read_model(name);
            let us = if timing {
                user::call_timer_measure_end_us()
            } else {
                -1
            };
            let bytes = bytes?;
            let g = &mut *graph_ptr();
            let a = g.analyze(bytes)?;
            let legacy = g.is_legacy_fc();
            let capacity = if legacy { 4096 } else { ARENA_CAPACITY };
            user::print(format_args!("TFLite TFL3 bytes={} schema=3\nModel buffer range: {:x}..{:x} (exclusive); model size: {} bytes\nModel load time: {us} us; Arena capacity: {capacity} bytes\nFlatBuffer validation: OK; tensors={} operators={} opcodes={}\nOut-of-line buffers: {}; Largest tensor: {} bytes\nTensor arena lifetime lower bound: {}; available: {capacity} bytes\nSupported operator kernels: {}; unsupported operators: {}\n",bytes.len(),USER_MODEL_BASE,USER_MODEL_BASE+USER_MODEL_SIZE,bytes.len(),a.tensors,a.operators,a.opcodes,a.out_of_line,a.largest,a.lifetime_peak,a.supported,a.unsupported));
            if DIAGNOSTICS {
                for i in 0..a.tensors {
                    let t = g.tensor(i)?;
                    user::print(format_args!(
                        "Tensor {i} type={} shape={:?} bytes={} scale={} zero_point={}\n",
                        t.kind,
                        &t.dims[..t.rank],
                        t.bytes,
                        t.scale,
                        t.zero
                    ));
                }
                for i in 0..a.operators {
                    let k = g.kind(i)?;
                    user::print(format_args!(
                        "Operator {i} {} builtin={k}\n",
                        super::tflite_graph::name(k)
                    ));
                }
            }
            let profile = if legacy {
                activate_fc();
                let runtime = &mut *fc_ptr();
                runtime.prepare_into(bytes).map(|_| runtime.arena_used())
            } else {
                g.prepare(
                    bytes,
                    core::slice::from_raw_parts_mut(USER_ARENA_BASE as *mut u8, ARENA_CAPACITY),
                )
                .map(|_| g.required)
            };
            match profile {
                Ok(n) => user::print(format_args!(
                    "Arena required (with reuse/parameters): {n} bytes\n"
                )),
                Err(e) => user::print(format_args!(
                    "Execution unavailable {e}: {}\n",
                    error_string(e)
                )),
            };
            reset_inner();
            Ok(())
        })();
        BUSY = false;
        result
    }
}
pub fn error_string(rc: i32) -> &'static str {
    match rc {
        0 => "OK",
        -200 => "model capacity exceeded (model 8..4194304 bytes)",
        -201 => "invalid FlatBuffer encoding",
        -202 => "unsupported CPU operator or execution condition",
        -203 => "invalid tensor/operator/quantization relationship",
        -204 => "short model read",
        -205 => "TFLite API busy",
        -206 => "SynapEngine syscall failure",
        -207 => "SynapEngine timeout",
        -208 => "SynapEngine size/buffer error",
        -209 => "SynapEngine busy",
        -210 => "Tensor Arena insufficient (see required/available capacity)",
        -2 => "use root uppercase 8.3 filename (MODEL.TFL)",
        -3 => "file not found",
        -4 => "SD read failed",
        -5 => "invalid FAT32 volume",
        -6 => "invalid/truncated FAT chain",
        _ => "FAT32 state error",
    }
}
#[no_mangle]
pub unsafe extern "C" fn psc_tflite_load(name: *const core::ffi::c_char) -> i32 {
    if name.is_null() {
        return FORMAT;
    }
    match core::ffi::CStr::from_ptr(name).to_str() {
        Ok(s) => load(s).err().unwrap_or(0),
        Err(_) => FORMAT,
    }
}
#[no_mangle]
pub unsafe extern "C" fn psc_tflite_reset() -> i32 {
    if BUSY {
        return -205;
    }
    reset_inner();
    0
}
#[no_mangle]
pub unsafe extern "C" fn psc_tflite_get_input(bytes: *mut usize) -> *mut i8 {
    if bytes.is_null() {
        return null_mut();
    }
    *bytes = 0;
    if GENERIC {
        with_graph(|g| {
            let x = g.input()?;
            *bytes = x.len();
            Ok(x.as_mut_ptr().cast())
        })
        .unwrap_or(null_mut())
    } else {
        with_runtime(|r| {
            let x = r.input();
            *bytes = x.len();
            Ok(x.as_mut_ptr())
        })
        .unwrap_or(null_mut())
    }
}
#[no_mangle]
pub unsafe extern "C" fn psc_tflite_get_output(bytes: *mut usize) -> *const i8 {
    if bytes.is_null() {
        return null();
    }
    *bytes = 0;
    if GENERIC {
        with_graph(|g| {
            let y = g.output().ok_or(GRAPH)?;
            *bytes = y.len();
            Ok(y.as_ptr().cast())
        })
        .unwrap_or(null())
    } else {
        with_runtime(|r| {
            let y = r.output().ok_or(GRAPH)?;
            *bytes = y.len();
            Ok(y.as_ptr())
        })
        .unwrap_or(null())
    }
}
#[no_mangle]
pub unsafe extern "C" fn psc_tflite_invoke() -> i32 {
    if GENERIC {
        with_graph(|g| g.invoke(&mut Platform, |_, _, _, _| Ok(())))
    } else {
        with_runtime(|r| r.invoke(&mut Platform, |_, _, _| {}))
    }
    .err()
    .unwrap_or(0)
}
#[no_mangle]
pub unsafe extern "C" fn psc_tflite_arena_used() -> usize {
    if GENERIC {
        with_graph(|g| Ok(g.arena_used()))
    } else {
        with_runtime(|r| Ok(r.arena_used()))
    }
    .unwrap_or(0)
}
#[no_mangle]
pub unsafe extern "C" fn psc_tflite_arena_capacity() -> usize {
    if GENERIC {
        ARENA_CAPACITY
    } else {
        4096
    }
}
#[no_mangle]
pub unsafe extern "C" fn psc_tflite_arena_required() -> usize {
    if BUSY {
        return 0;
    }
    if GENERIC {
        (&*graph_ptr()).required
    } else if STORAGE_FC {
        (&*fc_ptr()).arena_required()
    } else {
        0
    }
}
#[no_mangle]
pub unsafe extern "C" fn psc_tflite_set_fc_backend(backend: u32) -> i32 {
    let b = match backend {
        0 => Backend::Cpu,
        1 => Backend::Synap,
        2 => Backend::Pulp,
        3 => Backend::Auto,
        _ => return UNSUPPORTED,
    };
    if GENERIC {
        with_graph(|g| {
            g.set_backend(b);
            Ok(())
        })
    } else {
        with_runtime(|r| {
            r.set_backend(b);
            Ok(())
        })
    }
    .err()
    .unwrap_or(0)
}
#[no_mangle]
pub unsafe extern "C" fn psc_tflite_set_synap_tile_size(tile: u32) -> i32 {
    if GENERIC {
        with_graph(|g| g.set_tile(tile as usize))
    } else {
        with_runtime(|r| r.set_tile(tile as usize))
    }
    .err()
    .unwrap_or(0)
}

/// Hold the model lock across JPEG preprocessing, invoke and NMS. The stage
/// workspace borrows cannot escape the synchronous closure.
pub unsafe fn with_yolo<T>(
    f: impl FnOnce(&mut Graph<'static>, &mut crate::api::yolo::Workspace) -> Result<T, i32>,
) -> Result<T, i32> {
    if BUSY {
        return Err(-205);
    }
    if STORAGE_FC || !GENERIC {
        return Err(GRAPH);
    }
    BUSY = true;
    let state = &mut *generic_ptr();
    let result = f(&mut state.graph, &mut state.yolo);
    BUSY = false;
    result
}
