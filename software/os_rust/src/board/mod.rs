//! Board wiring and memory contract; register offsets stay in the drivers.
//! Host tests use the RV32 profile; RV64 firmware selects the LP64/Sv39 profile.
#[cfg_attr(target_arch = "riscv64", path = "psc_one_rv64/config.rs")]
#[cfg_attr(not(target_arch = "riscv64"), path = "psc_one/config.rs")]
mod config;
pub use config::*;
