pub mod boot_fat32;
pub mod boot_logo;
pub mod bootloader;
#[cfg(any(target_arch = "riscv32", target_arch = "riscv64"))]
pub mod bootloader_entry;
pub mod bootloader_fat32;
pub mod mbios;
#[cfg(any(target_arch = "riscv32", target_arch = "riscv64"))]
#[cfg_attr(target_arch = "riscv64", path = "../board/psc_one_rv64/mbios.rs")]
pub mod psc_mbios;
