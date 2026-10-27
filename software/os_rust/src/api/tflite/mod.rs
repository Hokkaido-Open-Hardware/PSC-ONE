pub mod tflite_cpu;
#[cfg(target_arch = "riscv32")]
pub mod tflite_demo;
#[cfg(target_arch = "riscv32")]
pub mod tflite_file;
pub mod tflite_graph;
pub mod tflite_inspect;
pub mod tflite_platform;
pub mod tflite_quant;
pub mod tflite_runtime;
mod tflite_schema;
pub mod tflite_synap;
mod tflite_verify;

#[cfg(test)]
mod resident_tests {
    extern crate std;
    use self::std::{boxed::Box, vec};
    use super::{tflite_graph::Graph, tflite_runtime::Runtime};
    use core::mem::{ManuallyDrop, MaybeUninit};
    // Reuse one poisoned allocation exactly as the firmware does. Drop no
    // inactive union member and keep each borrow within its active stage.
    #[test]
    fn in_place_runtime_switches_reinitialize_all_metadata() {
        union Storage<'a> {
            fc: ManuallyDrop<Runtime<'a>>,
            graph: ManuallyDrop<Graph<'a>>,
        }
        let mut slot = Box::new(MaybeUninit::<Storage<'_>>::uninit());
        let mut arena = vec![0u8; 768 * 1024];
        unsafe {
            core::ptr::write_bytes(
                slot.as_mut_ptr().cast::<u8>(),
                0xa5,
                core::mem::size_of::<Storage<'_>>(),
            );
            for _ in 0..3 {
                let fc = core::ptr::addr_of_mut!((*slot.as_mut_ptr()).fc).cast::<Runtime<'_>>();
                Runtime::init_at(fc);
                let r = &mut *fc;
                r.prepare_into(include_bytes!("../../../tests/fixtures/model.tfl"))
                    .unwrap();
                assert_eq!(r.input().len(), 16);
                assert!(r.output().is_none());
                r.input().fill(77);
                let graph = core::ptr::addr_of_mut!((*slot.as_mut_ptr()).graph).cast::<Graph<'_>>();
                Graph::init_at(graph);
                let g = &mut *graph;
                assert!(g.input().is_err());
                assert!(g.output().is_none());
                assert!(g.operator_reason(0).is_none());
                g.prepare(
                    include_bytes!("../../../tests/fixtures/cnn.tfl"),
                    &mut arena,
                )
                .unwrap();
                assert_eq!(g.input().unwrap().len(), 32);
                assert_eq!(g.required, 472);
                g.input().unwrap().fill(91);
                g.reset();
            }
            let mut work = MaybeUninit::<crate::api::yolo::Workspace>::uninit();
            crate::api::yolo::Workspace::init_at(work.as_mut_ptr());
            let mut work = work.assume_init();
            let mut input = vec![0; crate::api::yolo::INPUT_BYTES];
            use crate::api::jpeg::RgbSink;
            let mut s = work.pre().stream(&mut input);
            s.begin(1, 1).unwrap();
            s.rect(0, 0, 1, 1, &[0; 3]).unwrap();
            s.finish().unwrap();
        }
    }
}
