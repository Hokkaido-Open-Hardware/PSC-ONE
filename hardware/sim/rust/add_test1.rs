#![no_std]
#![no_main]

use core::arch::global_asm;
use core::panic::PanicInfo;

global_asm!(
    r#"
    .section .text.start
    .global _start

_start:
    lui     sp, 0x800
    j       rust_main
"#
);

const RESULT_BASE: *mut u32 = 0x0000_1000 as *mut u32;
const PIO_ADDR: *mut u32 = 0x1000_1000 as *mut u32;

const TEST_READY: u32 = 0x0000_EE01;
const TEST_PASS_RESULT: u32 = 0x1234_5678;

static mut DATA: [u32; 8] = [
    10, 20, 30, 40,
    50, 60, 70, 80,
];

#[inline(never)]
fn add_func(a: u32, b: u32) -> u32 {
    a.wrapping_add(b)
}

#[inline(always)]
unsafe fn write_result(index: usize, value: u32) {
    unsafe {
        core::ptr::write_volatile(
            RESULT_BASE.add(index),
            value,
        );
    }
}

#[inline(always)]
unsafe fn write_pio(value: u32) {
    unsafe {
        core::ptr::write_volatile(
            PIO_ADDR,
            value,
        );
    }
}

#[inline(never)]
fn test_fail(code: u32) -> ! {
    unsafe {
        write_result(6, code);

        // Test end marker
        write_pio(TEST_READY);

        // Final result
        write_pio(code);
    }

    loop {}
}

#[unsafe(no_mangle)]
pub extern "C" fn rust_main() -> ! {
    let a = unsafe {
        core::ptr::read_volatile(&raw const DATA[0])
    };

    let b = unsafe {
        core::ptr::read_volatile(&raw const DATA[1])
    };

    let c = unsafe {
        core::ptr::read_volatile(&raw const DATA[2])
    };

    let d = unsafe {
        core::ptr::read_volatile(&raw const DATA[3])
    };

    // TEST1: 10 + 20 = 30
    let result1 = a.wrapping_add(b);

    // TEST2: 10 + 20 + 30 + 40 = 100
    let result2 = a
        .wrapping_add(b)
        .wrapping_add(c)
        .wrapping_add(d);

    // TEST3: function call ADD
    let result3 = add_func(a, b);

    // TEST4: array sum = 360
    let mut sum = 0u32;

    for i in 0..8 {
        let value = unsafe {
            core::ptr::read_volatile(&raw const DATA[i])
        };

        sum = sum.wrapping_add(value);
    }

    // TEST5: 0xfffffff0 + 0x20 = 0x10
    let x = unsafe {
        core::ptr::read_volatile(
            &(0xffff_fff0u32) as *const u32
        )
    };

    let y = unsafe {
        core::ptr::read_volatile(
            &(0x0000_0020u32) as *const u32
        )
    };

    let result5 = x.wrapping_add(y);

    // TEST6: 0xffffffff + 1 = 0
    let max = unsafe {
        core::ptr::read_volatile(
            &(0xffff_ffffu32) as *const u32
        )
    };

    let one = unsafe {
        core::ptr::read_volatile(
            &(1u32) as *const u32
        )
    };

    let result6 = max.wrapping_add(one);

    unsafe {
        write_result(0, result1);
        write_result(1, result2);
        write_result(2, result3);
        write_result(3, sum);
        write_result(4, result5);
        write_result(5, result6);
    }

    if result1 != 30 {
        test_fail(0xDEAD_0001);
    }

    if result2 != 100 {
        test_fail(0xDEAD_0002);
    }

    if result3 != 30 {
        test_fail(0xDEAD_0003);
    }

    if sum != 360 {
        test_fail(0xDEAD_0004);
    }

    if result5 != 0x0000_0010 {
        test_fail(0xDEAD_0005);
    }

    if result6 != 0x0000_0000 {
        test_fail(0xDEAD_0006);
    }

    unsafe {
        write_result(6, TEST_PASS_RESULT);

        // First notify cocotb that execution is complete
        write_pio(TEST_READY);

        // Then output the actual test result
        write_pio(TEST_PASS_RESULT);
    }

    loop {}
}

#[panic_handler]
fn panic(_: &PanicInfo) -> ! {
    test_fail(0xDEAD_FFFF);
}