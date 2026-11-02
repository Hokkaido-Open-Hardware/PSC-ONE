#[cfg_attr(target_arch = "riscv64", path = "../board/psc_one_rv64/elf_loader.rs")]
pub mod elf_loader;
#[cfg(any(target_arch = "riscv32", target_arch = "riscv64"))]
#[cfg_attr(target_arch = "riscv64", path = "../board/psc_one_rv64/kernel.rs")]
pub mod kernel;
#[cfg(any(target_arch = "riscv32", target_arch = "riscv64"))]
#[cfg_attr(target_arch = "riscv64", path = "../board/psc_one_rv64/kernel_elf.rs")]
pub mod kernel_elf;
#[cfg(any(target_arch = "riscv32", target_arch = "riscv64"))]
#[cfg_attr(
    target_arch = "riscv64",
    path = "../board/psc_one_rv64/kernel_process.rs"
)]
pub mod kernel_process;
#[cfg(any(target_arch = "riscv32", target_arch = "riscv64"))]
#[cfg_attr(
    target_arch = "riscv64",
    path = "../board/psc_one_rv64/kernel_syscall.rs"
)]
pub mod kernel_syscall;
#[cfg(any(target_arch = "riscv32", target_arch = "riscv64"))]
#[cfg_attr(target_arch = "riscv64", path = "../board/psc_one_rv64/kernel_trap.rs")]
pub mod kernel_trap;
// Preserve the aligned ABI constant table.
#[rustfmt::skip]
pub mod syscall;
#[cfg_attr(target_arch = "riscv64", path = "../board/psc_one_rv64/types.rs")]
pub mod types;
pub mod user_memory;

#[cfg(any(target_arch = "riscv32", target_arch = "riscv64"))]
pub mod console;
#[cfg(any(target_arch = "riscv32", target_arch = "riscv64"))]
pub mod multitask_test;

#[cfg(any(target_arch = "riscv64", test))]
#[path = "../board/psc_one_rv64/sv39.rs"]
pub mod sv39;
