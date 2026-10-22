//! api/robot/robot_control.c/.h
use crate::api::i2c_api::*;
/// Apply the calibrated Q16 feedback coefficients and saturate the motor command to INT8.
pub fn robot_control_compute(input: &[i8; 4]) -> i8 {
    let acc = -66006 * input[0] as i32 + 10799 * input[1] as i32 + 293086 * input[2] as i32
        - 68963 * input[3] as i32;
    let result = if acc >= 0 {
        (acc + 32768) / 65536
    } else {
        -((-acc + 32768) / 65536)
    };
    result.clamp(-128, 127) as i8
}

/// Consume one complete input, preserve overrun evidence, and publish its computed output.
pub unsafe fn robot_control_poll() -> Result<(), i32> {
    let mut input = [0; 4];
    i2c_read_input(&mut input)?;
    i2c_clear_status(INPUT_READY);
    i2c_write_output(robot_control_compute(&input));
    Ok(())
}

/// Publish a startup sentinel before entering the serialized lockstep control loop.
pub unsafe fn robot_control_run() -> ! {
    i2c_init();
    i2c_write_output(0);
    loop {
        let _ = robot_control_poll();
    }
}

#[cfg(target_arch = "riscv32")]
/// Poll UART nonblockingly so quitting the diagnostic never prevents I2C reception.
pub unsafe fn robot_control() {
    i2c_init();
    crate::s_print!("robot_control: ready (I2C=0x42, 4 bytes; q/Ctrl-C to stop)\n");
    loop {
        let ch = crate::kernel::kernel::uart_getchar_timeout(1);
        if ch == b'q' as i32 || ch == 3 {
            break;
        }
        let status = i2c_get_status();
        let mut input = [0; 4];
        if i2c_read_input(&mut input).is_ok() {
            let seq = i2c_get_sequence();
            i2c_clear_status(INPUT_READY | OVERRUN);
            crate::s_print!(
                "I2C RX seq={} HEX={:02X} {:02X} {:02X} {:02X}\n",
                seq,
                input[0] as u8,
                input[1] as u8,
                input[2] as u8,
                input[3] as u8
            );
            if status & OVERRUN != 0 {
                crate::s_print!("robot_control: I2C overrun (input lost)\n");
            }
        }
    }
    i2c_set_irq_enabled(false);
    crate::s_print!("robot_control: stopped\n");
}
