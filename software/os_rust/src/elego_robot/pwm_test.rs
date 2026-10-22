//! elego_robot/pwm_test.c/.h: validate the Arduino transport round trip.
#[derive(Default, Debug)]
pub struct TestResult {
    pub write_seen: bool,
    pub read_seen: bool,
    pub report_seen: bool,
    pub left: i32,
    pub right: i32,
    pub read_bytes: usize,
    pub ack_left: i32,
    pub ack_right: i32,
    pub report_status: u8,
}

/// Decode a signed little-endian PWM word from two captured bytes.
pub fn pwm_test_signed16(p: &[u8]) -> i32 {
    i16::from_le_bytes([p[0], p[1]]) as i32
}

/// Require a valid WRITE, READ, and report transaction sequence with matching ACK behavior.
pub fn pwm_test_decode(events: &[u32], result: &mut TestResult) -> Result<(), &'static str> {
    *result = TestResult::default();
    if events.len() > 64 {
        return Err("invalid capture count");
    }
    let expected = [20, 0, 20, 0];
    let mut data = [0u8; 9];
    let (mut phase, mut active, mut address, mut length, mut bad_ack) = (0, false, 0, 0, false);
    for &event in events {
        let kind = (event >> 9) & 7;
        let byte = event & 255;
        let nack = event & 256 != 0;
        match kind {
            1 | 2 => {
                if active || (phase != 0 && kind == 2) {
                    return Err("unexpected START / incomplete transaction");
                }
                active = true;
                address = 0;
                length = 0;
                bad_ack = false;
            }
            4 => {
                if !active || address != 0 || byte >> 1 != 0x42 || nack {
                    return Err("invalid address / address NACK");
                }
                address = byte;
            }
            5 => {
                if !active || address == 0 {
                    return Err("data without address");
                }
                if length < data.len() {
                    data[length] = byte as u8;
                }
                if nack != (address & 1 != 0 && length == 3) {
                    bad_ack = true;
                }
                length += 1;
            }
            3 => {
                if !active || address == 0 {
                    return Err("incomplete transaction");
                }
                active = false;
                if phase == 0 {
                    // ARM can miss the preceding write; ignore its orphan read/report.
                    if address & 1 != 0 || (length == 9 && data[0] == 0xa5) {
                        continue;
                    }
                    if length != 4 {
                        return Err("Arduino WRITE length mismatch");
                    }
                    if bad_ack {
                        return Err("Arduino WRITE NACK");
                    }
                    result.write_seen = true;
                    result.left = pwm_test_signed16(&data);
                    result.right = pwm_test_signed16(&data[2..]);
                    phase = 1;
                } else if phase == 1 {
                    if address & 1 == 0 {
                        return Err("expected Arduino READ");
                    }
                    result.read_seen = true;
                    result.read_bytes = length;
                    if length != 4 {
                        return Err("Arduino READ length mismatch");
                    }
                    if bad_ack {
                        return Err("Arduino READ ACK/NACK mismatch");
                    }
                    if data[..4] != expected {
                        return Err("Arduino READ value mismatch");
                    }
                    phase = 2;
                } else {
                    if address & 1 != 0 {
                        return Err("expected Arduino report WRITE");
                    }
                    if length != 9 {
                        return Err("Arduino report length mismatch");
                    }
                    if bad_ack {
                        return Err("Arduino report NACK");
                    }
                    if data[0] != 0xa5 || data[1] != 1 {
                        return Err("Arduino report identifier/version mismatch");
                    }
                    result.report_seen = true;
                    result.report_status = data[2];
                    result.ack_left = pwm_test_signed16(&data[5..]);
                    result.ack_right = pwm_test_signed16(&data[7..]);
                    if data[2] & 0x7f != 0 {
                        return Err("Arduino receive error/timeout");
                    }
                    if data[3] != 4 || data[4] != 4 {
                        return Err("Arduino requested/returned length mismatch");
                    }
                    if data[5..9] != expected {
                        return Err("Arduino report value mismatch");
                    }
                    return Ok(());
                }
            }
            _ => return Err("invalid capture event"),
        }
    }
    Err("incomplete WRITE/READ/report sequence")
}
