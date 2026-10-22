//! Stable PSC-OS syscall numbers shared by user wrappers and the kernel dispatcher.
//!
//! Execute ECALL from U-mode with the service number in a3. Arguments occupy
//! a0, a1, a2, a4, a5 and a6 in that order; a3 is never an argument register.
//! Most results use a0. Signed errors are carried as their raw two's-complement
//! bits, so callers must cast to i32 before checking for a negative status.
//!
//! Keep these values synchronized with os/src/kernel/syscall.h and MicroPython.
//! Numeric gaps and reserved services are intentional; do not renumber them.
//! Raw-pointer diagnostics belong to the trusted shell ABI. Foreground ELF
//! programs are restricted by kernel_syscall.rs to console and exit services.

// Console: byte IO and the interrupt-backed MicroPython receive queue.
/// Transmit the low byte of a0; no return value is specified.
pub const SYS_PUTCHAR: u32               = 1;
/// Wait for input and return the received byte in a0.
pub const SYS_GETCHAR: u32               = 2;
/// Poll for a bounded interval; return a byte or -1 when no byte arrives.
pub const SYS_GETCHAR_TIMEOUT: u32       = 3;
/// a0 selects console action 0..6; a1 supplies the interrupt character for action 3.
/// Actions: begin, end, read, set interrupt, poll interrupt, available, overrun.
/// Begin/end transfer UART receive ownership between the shell and MicroPython.
pub const SYS_MP_CONSOLE: u32            = 4;

// Accelerator and robot services; the kernel owns the hardware-facing buffers.
/// a0/a1/a2 are A/B/C pointers; a4 is the matrix size or packed M/N/K dimensions.
/// a5 holds signed/rectangle/profile flags; a6 optionally points to profiling data.
/// Return 0 on success or a negative accelerator error; see sa_transfer.rs.
pub const SYS_SA_RUN: u32                = 10;
/// Enter the kernel robot-control loop; return 0 after the loop completes.
pub const SYS_ROBOT_CONTROL: u32         = 11;
/// a0 is an i2c_capture operation; return register data, 0, or -1 if unsupported.
pub const SYS_I2C_CAPTURE: u32           = 12;

// Microphone capture uses signed 24-bit samples stored in kernel-owned memory.
/// a0 is the requested sample count; capture and print samples through the console.
pub const I2S_MIC_READ: u32              = 20;
/// a0 is the sample count; a1 is the first SD sector used for captured samples.
pub const I2S_MIC_WRITE: u32             = 21;

// SD operations address 512-byte sectors by logical block number, not byte offset.
/// Read sector a0 and print its contents for diagnostics.
pub const SYS_SD_READ: u32               = 30;
/// Write the diagnostic byte pattern to sector a0; return the write status.
pub const SYS_SD_WRITE_TEST: u32         = 31;
/// Write sector a0 from the 512 readable bytes at a1; return 0 or an error.
pub const SYS_SD_WRITE: u32              = 32;
/// Read sector a0 into the 512 writable bytes at a1; return 0 or an error.
pub const SYS_SD_READ_BUF: u32           = 33;

/// Dump memory at a0; a1 is the byte count (0 means 256, maximum 4096).
/// This trusted-shell diagnostic may fault when passed an unmapped address.
pub const SYS_DUMP: u32                  = 40;
/// Return the two active-low switch bits in a0, without edge detection.
pub const SYS_SW_READ: u32               = 50;

// Historical reservations: no dispatch handler exists for these two numbers.
// FAT32 currently runs in user space over SYS_SD_READ_BUF / SYS_SD_WRITE.
/// Reserved file-read service. Do not issue this syscall in the current kernel.
pub const SYS_READFILE: u32              = 51;
/// Reserved file-write service. Do not issue this syscall in the current kernel.
pub const SYS_WRITEFILE: u32             = 52;

/// Record and classify speech; return 0 (UP), 1 (DOWN), 2 (UNKNOWN), or an error.
pub const SYS_SPEECH_RECOGNITION: u32    = 60;

// Raw timer controls and blocking waits. Measurement services share this device.
/// Start a one-shot timer with the reload value in a0.
pub const SYS_TIMER_START: u32           = 70;
/// Start an automatically reloading timer with the reload value in a0.
pub const SYS_TIMER_START_AUTO: u32      = 71;
/// Stop the hardware timer; no arguments or return value.
pub const SYS_TIMER_STOP: u32            = 72;
/// Return the current hardware counter value.
pub const SYS_TIMER_GET_COUNT: u32       = 73;
/// Return the raw timer status bits defined in drivers/timer_api.rs.
pub const SYS_TIMER_GET_STATUS: u32      = 74;
/// Return 1 while the timer is running, otherwise 0.
pub const SYS_TIMER_IS_RUNNING: u32      = 75;
/// Block for the duration in a0 microseconds.
pub const SYS_TIMER_WAIT_US: u32         = 76;
/// Block for the duration in a0 milliseconds.
pub const SYS_TIMER_WAIT_MS: u32         = 77;
/// Acquire the measurement timer; return 0 or -1 if already in use.
pub const SYS_TIMER_MEASURE_BEGIN: u32   = 78;
/// Finish this measurement and return elapsed milliseconds, or -1 if inactive.
pub const SYS_TIMER_MEASURE_END: u32     = 79;

// LED bitmasks refer to the logical LED shadow maintained by the driver.
/// Replace the LED state with the bitmask in a0.
pub const SYS_LED_WRITE: u32             = 80;
/// Turn on the single LED indexed by a0 (0..5).
pub const SYS_LED_ON: u32                = 81;
/// Turn off the single LED indexed by a0 (0..5).
pub const SYS_LED_OFF: u32               = 82;
/// Toggle the single LED indexed by a0 (0..5).
pub const SYS_LED_TOGGLE: u32            = 83;
/// Turn on all supported LEDs; no arguments.
pub const SYS_LED_ALL_ON: u32            = 84;
/// Turn off all supported LEDs; no arguments.
pub const SYS_LED_ALL_OFF: u32           = 85;
/// Return the driver's logical LED shadow bitmask.
pub const SYS_LED_GET_STATE: u32         = 86;

// Later timer additions retain their original numbers after the LED block.
/// Finish this measurement and return elapsed microseconds, or -1 if inactive.
pub const SYS_TIMER_MEASURE_END_US: u32  = 87;
/// Read elapsed microseconds without releasing the measurement timer.
pub const SYS_TIMER_MEASURE_READ_US: u32 = 88;

// LCD rectangles are tightly packed RGB888, at most 16x16 pixels per call.
/// Reserved legacy initialization number; use SYS_LCD_RGB888_BEGIN instead.
pub const SYS_LCD_INIT: u32              = 90;
/// Reserved legacy fill number; no current dispatcher implementation.
pub const SYS_LCD_FILL_RGB: u32          = 91;
/// Prepare landscape RGB888 drawing; return 0 on success.
pub const SYS_LCD_RGB888_BEGIN: u32      = 92;
/// a0=x, a1=y, a2=width, a4=height, a5=RGB pointer; return 0 or an error.
/// The kernel validates both the screen bounds and every source-buffer page.
pub const SYS_LCD_RGB888_RECT: u32       = 93;

// Process control: foreground ELFs return to the shell; the shell itself reboots.
/// End a foreground ELF with exit code a0, or restart PSC-OS from the shell.
pub const SYS_EXIT: u32                  = 100;
/// Print a0 as a signed decimal integer; no return value is specified.
pub const SYS_PRINT_INT: u32             = 101;
/// a0 points to an ELF file and a1 is its byte length; execution is synchronous.
/// On return a0 is the loader status and a1 is the program's exit code.
pub const SYS_ELF_RUN: u32               = 102;
