//! kernel/user_memory.h
pub const USER_BASE: u32 = 0x00400000;
pub const USER_STACK_TOP: u32 = USER_BASE + 0x00100000;
pub const USER_STACK_SIZE: u32 = 128 * 1024;
pub const USER_STACK_GUARD: u32 = 4096;
