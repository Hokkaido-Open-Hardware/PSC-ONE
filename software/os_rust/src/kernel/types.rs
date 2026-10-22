//! Shared layouts from kernel/kernel.h. Offsets match the RV32 trap assembly.
pub const PROCS_MAX: usize = 8;
pub const PROC_UNUSED: u32 = 0;
pub const PROC_RUNNABLE: u32 = 1;
pub const PROC_EXITED: u32 = 2;
pub const SATP_SV32: u32 = 1 << 31;
pub const PAGE_V: u32 = 1;
pub const PAGE_R: u32 = 2;
pub const PAGE_W: u32 = 4;
pub const PAGE_X: u32 = 8;
pub const PAGE_U: u32 = 16;
#[derive(Clone, Copy, Default)]
#[repr(C, align(16))]
pub struct MachineContext {
    pub x: [u32; 32],
    pub mepc: u32,
    pub mstatus: u32,
    pub mcause: u32,
    pub sscratch: u32,
    pub sepc: u32,
    pub sstatus: u32,
    pub scause: u32,
    pub stval: u32,
}
#[derive(Clone, Copy, Default)]
#[repr(C, align(16))]
pub struct TrapFrame {
    pub ra: u32,
    pub gp: u32,
    pub tp: u32,
    pub t0: u32,
    pub t1: u32,
    pub t2: u32,
    pub t3: u32,
    pub t4: u32,
    pub t5: u32,
    pub t6: u32,
    pub a0: u32,
    pub a1: u32,
    pub a2: u32,
    pub a3: u32,
    pub a4: u32,
    pub a5: u32,
    pub a6: u32,
    pub a7: u32,
    pub s0: u32,
    pub s1: u32,
    pub s2: u32,
    pub s3: u32,
    pub s4: u32,
    pub s5: u32,
    pub s6: u32,
    pub s7: u32,
    pub s8: u32,
    pub s9: u32,
    pub s10: u32,
    pub s11: u32,
    pub sp: u32,
    pub sepc: u32,
    pub sstatus: u32,
    pub scause: u32,
    pub stval: u32,
}
#[repr(C, align(16))]
pub struct Process {
    pub pid: i32,
    pub state: u32,
    pub sp: u32,
    pub context: MachineContext,
    pub context_valid: u32,
    pub page_table: *mut u32,
    pub stack: Stack,
}
#[repr(C, align(16))]
pub struct Stack(pub [u8; 8192]);
const _: () = assert!(core::mem::size_of::<MachineContext>() == 160);
const _: () = assert!(core::mem::size_of::<TrapFrame>() == 144);
