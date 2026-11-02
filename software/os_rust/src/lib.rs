//! Manual Rust port of PSC-OS. Hardware entry points require PSC-ONE MMIO.
#![no_std]
#![allow(clippy::missing_safety_doc)]
pub mod api;
pub mod board;
pub mod boot;
#[path = "lib/common.rs"]
pub mod common;
#[path = "lib/divmodsi3.rs"]
pub mod divmodsi3;
pub mod drivers;
pub mod fs;
pub mod kernel;
#[path = "lib/mulsi3.rs"]
pub mod mulsi3;

pub mod elego_robot;
#[cfg(any(target_arch = "riscv32", target_arch = "riscv64"))]
pub mod shell;
