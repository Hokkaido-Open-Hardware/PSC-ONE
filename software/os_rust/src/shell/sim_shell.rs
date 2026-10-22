//! shell/sim_shell.c: minimal simulation image without the interactive shell.
/// Announce the minimal simulation image and remain alive without touching other devices.
pub fn main() -> ! {
    for b in b"simulation shell start.\n" {
        crate::api::user::putchar(*b);
    }
    loop {
        core::hint::spin_loop();
    }
}
