//! Shared layouts from kernel/kernel.h. Offsets match the RV64 trap assembly.
pub const PROCS_MAX: usize = 8;
pub const PROC_UNUSED: u32 = 0;
pub const PROC_RUNNABLE: u32 = 1;
pub const PROC_EXITED: u32 = 2;
pub const SATP_SV39: u64 = 8 << 60;
pub const PAGE_V: u32 = 1;
pub const PAGE_R: u32 = 2;
pub const PAGE_W: u32 = 4;
pub const PAGE_X: u32 = 8;
pub const PAGE_U: u32 = 16;
#[derive(Clone, Copy, Default)]
#[repr(C, align(16))]
pub struct MachineContext {
    pub x: [u64; 32],
    pub mepc: u64,
    pub mstatus: u64,
    pub mcause: u64,
    pub sscratch: u64,
    pub sepc: u64,
    pub sstatus: u64,
    pub scause: u64,
    pub stval: u64,
}
#[derive(Clone, Copy, Default)]
#[repr(C, align(16))]
pub struct TrapFrame {
    pub ra: u64,
    pub gp: u64,
    pub tp: u64,
    pub t0: u64,
    pub t1: u64,
    pub t2: u64,
    pub t3: u64,
    pub t4: u64,
    pub t5: u64,
    pub t6: u64,
    pub a0: u64,
    pub a1: u64,
    pub a2: u64,
    pub a3: u64,
    pub a4: u64,
    pub a5: u64,
    pub a6: u64,
    pub a7: u64,
    pub s0: u64,
    pub s1: u64,
    pub s2: u64,
    pub s3: u64,
    pub s4: u64,
    pub s5: u64,
    pub s6: u64,
    pub s7: u64,
    pub s8: u64,
    pub s9: u64,
    pub s10: u64,
    pub s11: u64,
    pub sp: u64,
    pub sepc: u64,
    pub sstatus: u64,
    pub scause: u64,
    pub stval: u64,
}
#[repr(C, align(16))]
pub struct Process {
    pub pid: i32,
    pub state: u32,
    pub sp: u64,
    pub context: MachineContext,
    pub context_valid: u32,
    pub page_table: *mut u64,
    pub stack: Stack,
}
#[repr(C, align(16))]
pub struct Stack(pub [u8; 8192]);
const _: () = assert!(core::mem::size_of::<MachineContext>() == 320);
const _: () = assert!(core::mem::size_of::<TrapFrame>() == 288);
const _: () = assert!(core::mem::offset_of!(MachineContext, mepc) == 256);
const _: () = assert!(core::mem::offset_of!(MachineContext, stval) == 312);
const _: () = assert!(core::mem::offset_of!(TrapFrame, a0) == 80);
const _: () = assert!(core::mem::offset_of!(TrapFrame, sp) == 240);
const _: () = assert!(core::mem::offset_of!(TrapFrame, sepc) == 248);
const _: () = assert!(core::mem::offset_of!(TrapFrame, stval) == 272);
