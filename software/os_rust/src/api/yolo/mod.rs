//! Fixed normalized-xywh COCO80 profile, corresponding to os/src/api/yolo/.
#[cfg(target_arch = "riscv32")]
pub mod yolo_command;
pub mod yolo_display;
pub mod yolo_postprocess;
pub mod yolo_preprocess;
pub const SIDE: usize = 160;
pub const CLASSES: usize = 80;
pub const ANCHORS: usize = 525;
pub const MAX_DETECTIONS: usize = 50;
pub const INPUT_BYTES: usize = 3 * SIDE * SIDE * 4;
pub const OUTPUT_BYTES: usize = 84 * ANCHORS * 4;
pub const ARGUMENT: i32 = -300;
pub const PROFILE: i32 = -301;
pub const PREPROCESS: i32 = -302;
pub const OUTPUT: i32 = -303;
#[repr(C)]
#[derive(Clone, Copy, Default, Debug, PartialEq)]
pub struct Geometry {
    pub width: u32,
    pub height: u32,
    pub resized_width: u32,
    pub resized_height: u32,
    pub left: u32,
    pub top: u32,
    pub scale: f32,
}
impl Geometry {
    pub const ZERO: Self = Self {
        width: 0,
        height: 0,
        resized_width: 0,
        resized_height: 0,
        left: 0,
        top: 0,
        scale: 0.0,
    };
}
#[repr(C)]
#[derive(Clone, Copy, Default, Debug, PartialEq)]
pub struct Detection {
    pub x1: f32,
    pub y1: f32,
    pub x2: f32,
    pub y2: f32,
    pub score: f32,
    pub class_id: u16,
    pub anchor: u16,
}
impl Detection {
    pub const ZERO: Self = Self {
        x1: 0.0,
        y1: 0.0,
        x2: 0.0,
        y2: 0.0,
        score: 0.0,
        class_id: 0,
        anchor: 0,
    };
}
#[repr(C)]
#[derive(Debug, PartialEq)]
pub struct YoloResult {
    pub geometry: Geometry,
    pub detections: [Detection; MAX_DETECTIONS],
    pub candidates: u32,
    pub nms_count: u32,
    pub count: u32,
    pub truncated: u32,
    pub input_hash: u32,
    pub output_hash: u32,
    pub load_us: i32,
    pub preprocess_us: i32,
    pub invoke_us: i32,
    pub postprocess_us: i32,
}
impl YoloResult {
    pub const fn new() -> Self {
        Self {
            geometry: Geometry::ZERO,
            detections: [Detection::ZERO; MAX_DETECTIONS],
            candidates: 0,
            nms_count: 0,
            count: 0,
            truncated: 0,
            input_hash: 0,
            output_hash: 0,
            load_us: 0,
            preprocess_us: 0,
            invoke_us: 0,
            postprocess_us: 0,
        }
    }
}
impl Default for YoloResult {
    fn default() -> Self {
        Self::new()
    }
}
pub fn hash(bytes: &[u8]) -> u32 {
    bytes
        .iter()
        .fold(2166136261, |h, b| (h ^ *b as u32).wrapping_mul(16777619))
}
pub fn profile_ok(g: &super::tflite::tflite_graph::Graph<'_>) -> bool {
    let (Ok(i), Ok(o)) = (g.input_info(), g.output_info()) else {
        return false;
    };
    i.kind == 0
        && i.rank == 4
        && i.dims[..4] == [1, 3, SIDE, SIDE]
        && i.bytes == INPUT_BYTES
        && o.kind == 0
        && o.rank == 3
        && o.dims[..3] == [1, 84, ANCHORS]
        && o.bytes == OUTPUT_BYTES
        && g.info.operators == 289
}
const _: () = assert!(core::mem::size_of::<Detection>() == 24);

/// The JPEG preprocessor and NMS never run concurrently. Reinitialize each
/// union member before use; no reference survives a stage transition.
pub struct Workspace {
    storage: Stage,
}
union Stage {
    pre: core::mem::ManuallyDrop<yolo_preprocess::Workspace>,
    post: core::mem::ManuallyDrop<yolo_postprocess::Workspace>,
}
impl Workspace {
    pub const fn new() -> Self {
        Self {
            storage: Stage {
                pre: core::mem::ManuallyDrop::new(yolo_preprocess::Workspace::new()),
            },
        }
    }
    /// Safety: writable aligned storage with no outstanding stage borrows.
    #[cfg(any(target_arch = "riscv32", test))]
    pub(crate) unsafe fn init_at(p: *mut Self) {
        // Both stages contain only unsigned integers, floats and bools. Zero is
        // valid for the active preprocessor; never create a temporary stage.
        core::ptr::write_bytes(p, 0, 1);
    }
    pub fn pre(&mut self) -> &mut yolo_preprocess::Workspace {
        unsafe {
            let p = core::ptr::addr_of_mut!(self.storage.pre);
            core::ptr::write_bytes(p, 0, 1);
            &mut self.storage.pre
        }
    }
    pub fn post(&mut self) -> &mut yolo_postprocess::Workspace {
        unsafe {
            let p = core::ptr::addr_of_mut!(self.storage.post);
            core::ptr::write_bytes(p, 0, 1);
            &mut self.storage.post
        }
    }
}
impl Default for Workspace {
    fn default() -> Self {
        Self::new()
    }
}
