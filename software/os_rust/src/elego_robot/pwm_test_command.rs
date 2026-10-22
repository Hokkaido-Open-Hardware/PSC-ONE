//! elego_robot/pwm_test_command.c. Freeze capture before emitting diagnostics.
use super::pwm_test::*;
use crate::api::{i2c_capture::*, user::*};
/// Acquire the shared stopwatch, run the transport check, and report results after capture stops.
pub fn cmd_i2c_pwm_test() {
    print(format_args!(
        "I2C Slave addr=0x42\nPWM test: left=20 right=20\n"
    ));
    let status = call_i2c_capture(STATUS);
    if status & PWM_SUPPORTED == 0 || status & 1 != 0 {
        print(format_args!(
            "PWM communication FAIL: unsupported or busy capture\n"
        ));
        return;
    }
    if call_timer_measure_begin() != 0 {
        print(format_args!("PWM communication FAIL: timer busy\n"));
        return;
    }
    let mut result = TestResult::default();
    let outcome = capture(&mut result);
    call_timer_measure_end_us();
    if result.write_seen {
        print(format_args!(
            "Arduino WRITE: left={} right={}\n",
            result.left, result.right
        ));
    }
    if result.read_seen {
        print(format_args!("Arduino READ: {} bytes\n", result.read_bytes));
    }
    if result.report_seen {
        print(format_args!(
            "Arduino ACK: left={} right={}\n",
            result.ack_left, result.ack_right
        ));
        if result.report_status & 0x80 != 0 {
            print(format_args!("Transport test only; motor use disabled.\n"));
        }
    }
    match outcome {
        Ok(()) => print(format_args!("PWM communication PASS\n")),
        Err(e) => print(format_args!("PWM communication FAIL: {}\n", e)),
    }
}

/// Bound capture by both elapsed time and poll count, then validate the frozen event sequence.
fn capture(result: &mut TestResult) -> Result<(), &'static str> {
    let start = call_timer_measure_read_us() as u32;
    if start == u32::MAX {
        return Err("timer unavailable");
    }
    if call_i2c_capture(ARM_PWM) == u32::MAX {
        return Err("PWM ARM failed");
    }
    let mut polls = 0;
    let mut error = None;
    let status = loop {
        let status = call_i2c_capture(STATUS);
        if status & DONE != 0 {
            break status;
        }
        let now = call_timer_measure_read_us() as u32;
        polls += 1;
        if now == u32::MAX || now.wrapping_sub(start) >= 10_000_000 || polls >= 10_000_000 {
            error = Some("CPU communication timeout / timer unavailable");
            call_i2c_capture(ABORT);
            break call_i2c_capture(STATUS);
        }
    };
    let count = call_i2c_capture(COUNT) as usize;
    if count > 64 {
        return Err("invalid capture count");
    }
    let mut events = [0; 64];
    for e in &mut events[..count] {
        *e = call_i2c_capture(POP);
    }
    let decoded = pwm_test_decode(&events[..count], result);
    // A valid prefix must never turn a timed-out or overflowed capture into PASS.
    if status & TIMEOUT != 0 {
        return Err("RTL communication timeout");
    }
    if status & OVERFLOW != 0 {
        return Err("capture overflow");
    }
    if let Some(e) = error {
        return Err(e);
    }
    if status & ABORTED != 0 {
        return Err("capture aborted");
    }
    if status & LIMIT == 0 {
        return Err("capture did not reach transaction limit");
    }
    decoded
}
