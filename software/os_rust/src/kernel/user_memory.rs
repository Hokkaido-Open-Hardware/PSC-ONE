//! kernel/user_memory.h
pub const USER_BASE: u32 = 0x00400000;
pub const USER_STACK_TOP: u32 = USER_BASE + 0x00100000;
pub const USER_STACK_SIZE: u32 = 128 * 1024;
pub const USER_STACK_GUARD: u32 = 4096;

// Dedicated TFLite mappings, identical to the C OS memory contract.
pub const USER_MODEL_BASE: u32 = 0x00800000;
pub const USER_MODEL_SIZE: u32 = 4 * 1024 * 1024;
pub const USER_ARENA_BASE: u32 = 0x00c00000;
pub const USER_ARENA_SIZE: u32 = 768 * 1024;

pub fn user_span(address: u32, bytes: u32) -> bool {
    bytes != 0
        && [
            (USER_BASE, USER_STACK_TOP - USER_BASE),
            (USER_MODEL_BASE, USER_MODEL_SIZE),
            (USER_ARENA_BASE, USER_ARENA_SIZE),
        ]
        .iter()
        .any(|&(base, size)| {
            address >= base && address < base + size && bytes <= base + size - address
        })
}
