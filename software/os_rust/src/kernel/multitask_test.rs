//! Supervisor scheduler demonstration, excluded from the normal startup path.
use super::{kernel_process::*, types::PROC_EXITED};
use core::ptr::{addr_of, read_volatile};

/// Preserve the original active demonstration: print continuously without yielding.
unsafe fn worker(label: &str) -> ! {
    let mut count = 0u32;
    loop {
        crate::s_print!("{}\n{}\n", label, count);
        crate::common::delay(1000);
        count = count.wrapping_add(1);
    }
}

pub unsafe extern "C" fn proc_a_entry() -> ! {
    worker("DDDDDDDD")
}

pub unsafe extern "C" fn proc_b_entry() -> ! {
    worker("EEEEEEEE")
}

/// This demonstration is intentionally endless, as in the enabled C source branches.
/// It must not be presented as a finite PASS/FAIL scheduler regression.
pub unsafe fn run_multitask_dummy_test() -> ! {
    IDLE = create_process(&[]);
    (*IDLE).pid = 0;
    CURRENT = IDLE;
    let a = create_kernel_task(proc_a_entry);
    let b = create_kernel_task(proc_b_entry);
    crate::s_print!("DUMMY_TEST_START\n");
    preemption_start();
    while read_volatile(addr_of!((*a).state)) != PROC_EXITED
        || read_volatile(addr_of!((*b).state)) != PROC_EXITED
    {
        core::hint::spin_loop();
    }
    crate::drivers::timer_api::timer_stop();
    crate::s_print!(
        "DUMMY_TIMER_DONE ticks={}\n",
        read_volatile(addr_of!(PREEMPTION_TICKS))
    );
    loop {
        core::hint::spin_loop();
    }
}
