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
