pub mod fft_api;
pub mod i2c_api;
pub mod i2c_capture;
pub mod sa_transfer;
pub mod speech_recognition_api;
#[cfg(target_arch = "riscv32")]
pub mod user;
pub mod robot {
    pub mod robot_control;
}
pub mod jpeg;
#[cfg(target_arch = "riscv32")]
pub mod synap_api;
pub mod tflite;

pub mod yolo;
