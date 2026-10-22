//! Passive IMU command: bounded captures, receipt-time filtering and throttled output.
use super::imu::*;
use crate::api::{i2c_capture::*, user::*};

/// Monitor mode rearms before math/output; ARM gaps are not a measured loss count.
pub fn cmd_i2c_imu(mode: u32) {
    if mode == 1 {
        let pass = imu_self_test();
        print(format_args!(
            "IMU self-test {}\n",
            if pass { "PASS" } else { "FAIL" }
        ));
        if !pass {
            return;
        }
    }
    print(format_args!(
        "Passive IMU capture; q/Ctrl-C exits; bounded wait.\n"
    ));
    if call_timer_measure_begin() != 0 {
        print(format_args!("IMU: timer busy; capture not started.\n"));
        return;
    }
    let monitor = mode == 2;
    let mut tracker = Tracker::default();
    let mut filter = Filter::default();
    imu_reset(&mut filter);
    let mut events = [0; 64];
    let mut samples = 0;
    let mut gaps = 0;
    let mut rejected = 0;
    let mut timeouts = 0;
    let mut skipped = 0;
    let mut invalid = 0;
    let mut armed = false;
    let initial = call_timer_measure_read_us();
    let mut batch_start = initial as u32;
    let mut last_display = batch_start;
    let mut polls = 0;
    let (mut dt, mut acc, mut gyro) = (0.0, 0.0, 0.0);
    let mut compute_us = -1;
    if monitor {
        print(format_args!(
            "Snapshot mode: receipt dt includes capture/UART latency; continuity unknown.\n"
        ));
    }
    'capture: loop {
        if initial == -1 {
            break;
        }
        if !armed {
            if call_i2c_capture(ARM) == u32::MAX {
                print(format_args!("IMU: capture ARM failed.\n"));
                break;
            }
            armed = true;
        }
        if matches!(getchar_timeout(), 113 | 3) {
            break;
        }
        let now = call_timer_measure_read_us();
        if now == -1 {
            break;
        }
        polls += 1;
        if polls >= 10_000_000
            || (now as u32).wrapping_sub(batch_start) >= 10_000_000
            || (!monitor && (now as u32).wrapping_sub(initial as u32) >= 10_000_000)
        {
            print(format_args!("IMU: CPU timeout.\n"));
            break;
        }
        let status = call_i2c_capture(STATUS);
        if status & DONE == 0 {
            continue;
        }
        armed = false;
        let count = call_i2c_capture(COUNT) as usize;
        if count > 64 {
            print(format_args!("IMU: invalid capture count.\n"));
            break;
        }
        for e in &mut events[..count] {
            *e = call_i2c_capture(POP);
        }
        let acquired = call_timer_measure_read_us();
        if acquired == -1 {
            break;
        }
        gaps += 1;
        if status & TIMEOUT != 0 {
            timeouts += 1;
        }
        if monitor {
            if call_i2c_capture(ARM) == u32::MAX {
                break;
            }
            armed = true;
        }
        let mut cursor = 0;
        let mut found = 0;
        while let Some(sample) = imu_decode(&events[..count], &mut cursor) {
            found += 1;
            samples += 1;
            if mode == 0 {
                print(format_args!("MPU6050 {:?}\n", sample));
                break 'capture;
            }
            let start = call_timer_measure_read_us();
            if monitor {
                let (updated, delta, angle, velocity) =
                    imu_track(&mut tracker, &sample, acquired as u32);
                dt = delta;
                acc = angle;
                gyro = velocity;
                if updated < 0 {
                    invalid += 1;
                } else if updated == 0 {
                    skipped += 1;
                }
                filter = tracker.filter;
            } else {
                imu_reset(&mut filter);
                (acc, gyro) = imu_update(&mut filter, &sample, 0.0);
            }
            let end = call_timer_measure_read_us();
            compute_us = if start != -1 && end != -1 {
                end.wrapping_sub(start)
            } else {
                -1
            };
            if !monitor {
                print(format_args!("MPU6050 {:?}\n", sample));
                break;
            }
        }
        if found == 0 || status & (OVERFLOW | ABORTED) != 0 {
            rejected += 1;
        }
        let now = call_timer_measure_read_us();
        if now == -1 {
            break;
        }
        if (!monitor && found != 0)
            || (monitor && (now as u32).wrapping_sub(last_display) >= 100_000)
        {
            print(format_args!("samples={samples} gaps_unknown={gaps} rejected_batches={rejected} timeouts={timeouts} skipped_dt={skipped} invalid_samples={invalid} dt_ms={:.6} acc_deg={acc:.6} gyro_dps={gyro:.6} estimate_deg={:.6} bias={:.6} compute_us={compute_us}\n", dt*1000.0,filter.angle,filter.q_bias));
            last_display = now as u32;
        }
        if !monitor && found != 0 {
            break;
        }
        batch_start = now as u32;
        polls = 0;
    }
    // Always release capture and timer, including abort, malformed count and UART exit.
    if armed {
        call_i2c_capture(ABORT);
    }
    call_timer_measure_end_us();
    print(format_args!("IMU stopped: samples={samples} gaps_unknown={gaps} rejected_batches={rejected} timeouts={timeouts}\n"));
}
