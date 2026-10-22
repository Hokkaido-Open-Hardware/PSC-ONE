//! Resident model ownership and the synchronous C ABI used by MicroPython.
use super::{tflite_inspect::*, tflite_platform::Platform, tflite_runtime::*};
use crate::{api::user::UserSd, fs::fat32_stream::File};
use core::ptr::{addr_of_mut, null, null_mut};

#[repr(align(16))]
struct ModelBytes([u8; MODEL_CAPACITY]);
static mut MODEL: ModelBytes = ModelBytes([0; MODEL_CAPACITY]);
static mut RUNTIME: Option<Runtime<'static>> = None;
static mut BUSY: bool = false;

/// Single-core shell ownership: callers must not retain references across this closure.
/// The C API deliberately returns raw pointers that expire on reset or replacement.
pub unsafe fn with_runtime<T>(
    f: impl FnOnce(&mut Runtime<'static>) -> Result<T, i32>,
) -> Result<T, i32> {
    if BUSY {
        return Err(-205);
    }
    BUSY = true;
    let result = match (&mut *addr_of_mut!(RUNTIME)).as_mut() {
        Some(rt) => f(rt),
        None => Err(GRAPH),
    };
    BUSY = false;
    result
}

/// Read the entire bounded file before borrowing model bytes for inference.
pub fn load(name: &str) -> Result<(), i32> {
    unsafe {
        if BUSY {
            return Err(-205);
        }
        BUSY = true;
        *addr_of_mut!(RUNTIME) = None;
        let result = (|| {
            let mut file = File::default();
            file.open(&mut UserSd, name)?;
            let size = file.file_size as usize;
            if !(8..=MODEL_CAPACITY).contains(&size) {
                return Err(SIZE);
            }
            let buffer = &mut *addr_of_mut!(MODEL.0);
            let mut actual = 0;
            let result = file.read(&mut UserSd, &mut buffer[..size], &mut actual);
            file.close();
            result?;
            if actual as usize != size {
                return Err(-204);
            }
            *addr_of_mut!(RUNTIME) = Some(Runtime::prepare(&buffer[..size])?);
            Ok(())
        })();
        BUSY = false;
        result
    }
}

#[no_mangle]
/// The caller supplies a valid NUL-terminated filename for this synchronous call.
pub unsafe extern "C" fn psc_tflite_load(name: *const core::ffi::c_char) -> i32 {
    if name.is_null() {
        return FORMAT;
    }
    match core::ffi::CStr::from_ptr(name).to_str() {
        Ok(name) => load(name).err().unwrap_or(0),
        Err(_) => FORMAT,
    }
}

#[no_mangle]
/// Drop all borrows before allowing the shared model buffer to be overwritten.
pub unsafe extern "C" fn psc_tflite_reset() -> i32 {
    if BUSY {
        return -205;
    }
    *addr_of_mut!(RUNTIME) = None;
    0
}

#[no_mangle]
/// Input pointers remain valid only until reset, load, or prepare.
pub unsafe extern "C" fn psc_tflite_get_input(bytes: *mut usize) -> *mut i8 {
    if bytes.is_null() {
        return null_mut();
    }
    *bytes = 0;
    with_runtime(|rt| {
        let input = rt.input();
        *bytes = input.len();
        Ok(input.as_mut_ptr())
    })
    .unwrap_or(null_mut())
}

#[no_mangle]
/// Failed or absent invocation never exposes stale output as a successful result.
pub unsafe extern "C" fn psc_tflite_get_output(bytes: *mut usize) -> *const i8 {
    if bytes.is_null() {
        return null();
    }
    *bytes = 0;
    with_runtime(|rt| {
        let output = rt.output().ok_or(GRAPH)?;
        *bytes = output.len();
        Ok(output.as_ptr())
    })
    .unwrap_or(null())
}

#[no_mangle]
/// Hardware failures propagate to Python; no silent CPU retry is performed.
pub unsafe extern "C" fn psc_tflite_invoke() -> i32 {
    with_runtime(|rt| rt.invoke(&mut Platform, |_, _, _| {}))
        .err()
        .unwrap_or(0)
}

#[no_mangle]
pub unsafe extern "C" fn psc_tflite_arena_used() -> usize {
    with_runtime(|rt| Ok(rt.arena_used())).unwrap_or(0)
}

#[no_mangle]
pub unsafe extern "C" fn psc_tflite_set_fc_backend(backend: u32) -> i32 {
    let backend = match backend {
        0 => Backend::Cpu,
        1 => Backend::Synap,
        2 => Backend::Pulp,
        3 => Backend::Auto,
        _ => return UNSUPPORTED,
    };
    with_runtime(|rt| {
        rt.set_backend(backend);
        Ok(())
    })
    .err()
    .unwrap_or(0)
}

#[no_mangle]
pub unsafe extern "C" fn psc_tflite_set_synap_tile_size(tile: u32) -> i32 {
    with_runtime(|rt| rt.set_tile(tile as usize))
        .err()
        .unwrap_or(0)
}
