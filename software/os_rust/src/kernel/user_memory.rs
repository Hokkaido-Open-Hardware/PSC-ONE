//! User address validation for the selected board.
pub use crate::board::{
    USER_ARENA_BASE, USER_ARENA_SIZE, USER_BASE, USER_MODEL_BASE, USER_MODEL_SIZE,
    USER_STACK_GUARD, USER_STACK_SIZE, USER_STACK_TOP,
};

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
