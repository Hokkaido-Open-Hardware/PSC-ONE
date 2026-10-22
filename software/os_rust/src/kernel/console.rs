//! Interrupt-driven MicroPython console. M-mode produces; S-mode consumes.
use crate::common::{mmio_r32, mmio_w32};
use core::ptr::{addr_of, addr_of_mut, read_volatile as read, write_volatile as write};
static mut RX: [u8; 1024] = [0; 1024];
static mut HEAD: u32 = 0;
static mut TAIL: u32 = 0;
static mut ACTIVE: bool = false;
static mut INTERRUPTS: u32 = 0;
static mut LOST: u32 = 0;
static mut INTERRUPT_CHAR: i32 = -1;
static mut SEEN: u32 = 0;
static mut SAVED_CTRL: u32 = 0;

/// Never enter the VM from this handler: the interrupted address space may differ.
pub unsafe fn irq() {
    if !read(addr_of!(ACTIVE)) {
        return;
    }
    let status = mmio_r32(0x10000008);
    if status & 8 != 0 {
        write(addr_of_mut!(LOST), read(addr_of!(LOST)).wrapping_add(1));
        mmio_w32(0x1000000c, 13);
    }
    if status & 2 == 0 {
        return;
    }
    let byte = mmio_r32(0x10000004) as u8;
    if byte as i32 == read(addr_of!(INTERRUPT_CHAR)) {
        write(
            addr_of_mut!(INTERRUPTS),
            read(addr_of!(INTERRUPTS)).wrapping_add(1),
        );
    } else {
        let head = read(addr_of!(HEAD));
        if head.wrapping_sub(read(addr_of!(TAIL))) < 1024 {
            write(
                addr_of_mut!(RX).cast::<u8>().add((head & 1023) as usize),
                byte,
            );
            // Publish the byte before advancing the producer index.
            write(addr_of_mut!(HEAD), head.wrapping_add(1));
        } else {
            write(addr_of_mut!(LOST), read(addr_of!(LOST)).wrapping_add(1));
        }
    }
}

/// Implement the existing seven-action C console ABI without Rust callbacks into C.
pub unsafe fn control(action: u32, value: i32) -> i32 {
    match action {
        0 => {
            if read(addr_of!(ACTIVE)) {
                return -1;
            }
            SAVED_CTRL = mmio_r32(0x1000000c);
            write(addr_of_mut!(HEAD), 0);
            write(addr_of_mut!(TAIL), 0);
            write(addr_of_mut!(INTERRUPTS), 0);
            write(addr_of_mut!(LOST), 0);
            write(addr_of_mut!(INTERRUPT_CHAR), -1);
            SEEN = 0;
            super::kernel_process::enable_machine_timer_trap();
            write(addr_of_mut!(ACTIVE), true);
            mmio_w32(0x1000000c, 15);
            0
        }
        1 => {
            mmio_w32(0x1000000c, SAVED_CTRL | 6);
            write(addr_of_mut!(ACTIVE), false);
            0
        }
        2 => {
            let tail = read(addr_of!(TAIL));
            if tail == read(addr_of!(HEAD)) {
                return -1;
            }
            let byte = read(addr_of!(RX).cast::<u8>().add((tail & 1023) as usize));
            write(addr_of_mut!(TAIL), tail.wrapping_add(1));
            byte as i32
        }
        3 => {
            write(addr_of_mut!(INTERRUPT_CHAR), value);
            if value < 0 {
                SEEN = read(addr_of!(INTERRUPTS));
            }
            0
        }
        4 => {
            let count = read(addr_of!(INTERRUPTS));
            let pending = count != SEEN;
            SEEN = count;
            pending as i32
        }
        5 => (read(addr_of!(HEAD)) != read(addr_of!(TAIL))) as i32,
        6 => read(addr_of!(LOST)) as i32,
        _ => -1,
    }
}
