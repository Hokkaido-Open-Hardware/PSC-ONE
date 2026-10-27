//! shell/shell.c: bounded line editing, command parsing and synchronous dispatch.
//! The shell runs in U-mode. Hardware access goes through the a3 syscall ABI.
//! Commands borrow the current input line and finish before its buffer is reused.
use crate::api::tflite::{tflite_file, tflite_runtime::Backend};
use crate::api::user::*;
use crate::api::yolo::yolo_command;
use crate::fs::fat32::Fat32;
// Use the user-mode formatter, so shell messages never access privileged UART MMIO.
macro_rules! out { ($($arg:tt)*) => { print(format_args!($($arg)*)) }; }

// Keep each help line beside its command family so additions are easy to review.
const HELP: &str = concat!(
    "commands:\n",
    "hello | run FILE.ELF | dump [addr] [len] | primes [max]\n",
    "sa_start | robot_control | mic_read count | mic_write count\n",
    "sd_read sector | sd_write sector | fat32_info | fat32_ls\n",
    "fat32_cat FILE | fat32_read FILE | fat32_touch FILE\n",
    "speech | micropython | jpeg FILE.JPG\n",
    "i2c_capture [self|imu_read|imu_test|imu_monitor|pwm_test]\n",
    "yolo YOLO.TFL TEST.JPG (detection to UART + LCD)\n",
    "yolo_backend cpu|pulp|npu|auto (default cpu)\n",
    "yolo_diag on|off (tensor hashes; default off)\n",
    "tflite_info FILE.TFL | tflite_run FILE.TFL [cpu|npu|pulp|auto]\n",
    "tflite_diag [on|off] | tflite_bench FILE.TFL [quick]\n",
    "exit | quit | q\n",
);

/// Read at most 31 bytes while continuing to poll active-low board switches.
fn read_line(line: &mut [u8; 32], previous_switches: &mut u32) -> usize {
    let mut length = 0;
    loop {
        // Detect falling edges only: holding a switch must not repeat the message.
        let switches = poll_switch_api() & 3;
        for bit in 0..2 {
            if *previous_switches & (1 << bit) != 0 && switches & (1 << bit) == 0 {
                out!("SW{} pressed\n", bit + 1);
            }
        }
        *previous_switches = switches;
        // A bounded UART poll leaves time to check switches while the user is idle.
        let c = getchar_timeout();
        // Ignore a leftover LF after CRLF. An empty CR still submits an empty line.
        if c < 0 || (c == 10 && length == 0) {
            continue;
        }
        match c as u8 {
            // Accept both common terminal erase keys; erase the echoed byte too.
            8 | 127 => {
                if length != 0 {
                    length -= 1;
                    out!("\x08 \x08");
                }
            }
            b'\r' | b'\n' => {
                putchar(b'\n');
                return length;
            }
            // Tabs are argument separators; other control bytes are not command text.
            c if c < 32 && c != b'\t' => {}
            c => {
                // Preserve the C shell limit even though Rust slices need no NUL byte.
                // Reject the line instead of executing a silently truncated command.
                if length == 31 {
                    out!("\ncommand line too long\n");
                    return 0;
                }
                line[length] = c;
                length += 1;
                putchar(c);
            }
        }
    }
}

/// Preserve the original dump parser: optional 0x prefix, hexadecimal digits.
pub fn parse_hex(text: &str) -> Option<u32> {
    let text = text.trim_start_matches([' ', '\t']);
    let text = text
        .strip_prefix("0x")
        .or_else(|| text.strip_prefix("0X"))
        .unwrap_or(text);
    if text.is_empty() {
        return None;
    }
    // Stop at the first non-hex character and retain the original wrapping arithmetic.
    let mut value = 0u32;
    for c in text.chars() {
        let Some(digit) = c.to_digit(16) else {
            break;
        };
        value = value.wrapping_shl(4) | digit;
    }
    Some(value)
}

/// Print eight primes per row, with the same user-visible limit as the C shell.
fn primes(maximum: u32) {
    if maximum > 100_000 {
        out!("max too large (<=100000)\n");
        return;
    }
    let mut count = 0;
    for n in 2..=maximum {
        if is_prime(n) {
            out!("{n} ");
            count += 1;
            if count % 8 == 0 {
                putchar(b'\n');
            }
        }
    }
    if count % 8 != 0 {
        putchar(b'\n');
    }
    out!("total primes: {count} (0..{maximum})\n");
}

/// Freeze capture before printing; UART output must not delay the watchdog loop.
fn capture(self_only: bool) {
    use crate::api::i2c_capture::*;
    // Older FPGA images cannot filter capture to the PSC slave address.
    if self_only && call_i2c_capture(STATUS) & SELF_SUPPORTED == 0 {
        out!("I2C self capture unsupported; rebuild/program FPGA.\n");
        return;
    }
    // The timer is shared; never end a measurement that this command did not acquire.
    let timing = call_timer_measure_begin() == 0;
    if call_i2c_capture(if self_only { ARM_SELF } else { ARM }) == u32::MAX {
        if timing {
            call_timer_measure_end_us();
        }
        out!("I2C capture ARM failed.\n");
        return;
    }
    out!("I2C capture armed...\nWaiting for START...\n");
    let mut polls = 0;
    let mut status;
    loop {
        status = call_i2c_capture(STATUS);
        polls += 1;
        if status & DONE != 0 {
            break;
        }
        let elapsed = if timing {
            call_timer_measure_read_us()
        } else {
            -1
        };
        // Prefer a ten-second deadline; the fallback is a poll limit, not calibrated time.
        if elapsed >= 10_000_000 || (elapsed < 0 && polls >= 10_000_000) {
            break;
        }
    }
    if status & DONE == 0 {
        // Hardware can finish at the CPU deadline. Recheck before aborting.
        if call_i2c_capture(STATUS) & DONE == 0 {
            call_i2c_capture(ABORT);
        }
        status = call_i2c_capture(STATUS);
    }
    let elapsed = if timing {
        call_timer_measure_end_us()
    } else {
        -1
    };
    out!("Capture status={status:x}, polls={polls}, elapsed_us={elapsed}\n");
    // Hardware storage holds 64 events. Validate the count before draining the FIFO.
    let count = call_i2c_capture(COUNT);
    if count > 64 {
        out!("I2C capture: invalid event count\n");
        return;
    }
    let mut bytes = 0;
    for _ in 0..count {
        let event = call_i2c_capture(POP);
        // Bits 11:9 encode the event kind; bit 8 is NACK and bits 7:0 hold data.
        let kind = (event >> 9) & 7;
        let byte = event & 255;
        match kind {
            1 => out!("\nSTART\n"),
            2 => out!("\nREPEATED START\n"),
            3 => out!("STOP\n"),
            4 | 5 => {
                if kind == 4 {
                    out!(
                        "ADDR : 0x{:02X} {}",
                        byte >> 1,
                        if byte & 1 != 0 { "READ" } else { "WRITE" }
                    );
                } else {
                    out!("DATA : 0x{byte:02X}");
                }
                out!(" {}\n", if event & 256 != 0 { "NACK" } else { "ACK" });
                bytes += 1;
            }
            _ => {}
        }
    }
    out!(
        "Captured: {bytes} bytes; reason={}\n",
        if status & OVERFLOW != 0 {
            "OVERFLOW"
        } else if status & TIMEOUT != 0 {
            "TIMEOUT"
        } else if status & ABORTED != 0 {
            "ABORTED"
        } else if status & LIMIT != 0 {
            "LIMIT"
        } else {
            "unspecified"
        }
    );
}

/// Each command completes before the next prompt, including entry into the C VM.
fn dispatch(args: &[&str]) -> Result<(), i32> {
    // main() guarantees at least one token. Optional arguments remain borrowed slices.
    // The ? operator returns device/file errors to the common prompt-level reporter.
    let command = args[0];
    let argument = args.get(1).copied();
    match command {
        "hello" => out!("Hello world from shell!\n"),
        // ELF execution is synchronous: the kernel restores this shell on program exit.
        "run" if args.len() == 2 => {
            out!("run: exit {}\n", super::elf_command::cmd_run_elf(args[1])?)
        }
        // Keep hexadecimal address/length defaults and the trusted-shell diagnostic ABI.
        "dump" => unsafe {
            call_dump_api(
                argument.and_then(parse_hex).unwrap_or(0x200000),
                args.get(2).and_then(|s| parse_hex(s)).unwrap_or(0x100),
            );
        },
        "primes" => primes(argument.map(parse_u32).unwrap_or(1000)),
        "self_test" => {} // The original command is intentionally reserved.
        // Preserve the original small diagnostic matrix limit; inference uses its own API.
        "sa_start" => {
            let size = argument.map(parse_u32).unwrap_or(4);
            if size > 4 {
                out!("matrix size > 4\n");
            } else {
                call_sa_api(size as usize, true);
            }
        }
        // These services own their hardware buffers inside the supervisor kernel.
        "robot_control" => call_robot_control(),
        "mic_read" if argument.is_some() => call_mic_api(parse_u32(args[1])),
        "mic_write" if argument.is_some() => {
            call_mic_write_file(parse_u32(args[1]))?;
        }
        "sd_read" if argument.is_some() => call_sd_read_api(parse_u32(args[1])),
        // Retain the original guard against overwriting early boot/filesystem sectors.
        "sd_write" if argument.is_some() => {
            let sector = parse_u32(args[1]);
            if sector < 5000 {
                out!("sd_sector write sector < 5000\n");
            } else {
                call_sd_write_test_api(sector);
            }
        }
        // Mount through syscall-backed sector IO; user code must not access SD MMIO.
        "fat32_info" | "fat32_ls" | "fat32_cat" | "fat32_read" | "fat32_touch" => {
            let fs = Fat32::mount(&mut UserSd)?;
            match command {
                "fat32_info" => out!(
                    "part_lba={:x}\nroot_cluster={:x}\nspc={:x}\nfat_begin={:x}\ndata_begin={:x}\n",
                    fs.part_lba,
                    fs.root_cluster,
                    fs.sectors_per_cluster,
                    fs.fat_begin,
                    fs.data_begin
                ),
                "fat32_ls" => fs.ls(&mut UserSd)?,
                "fat32_cat" if argument.is_some() => fs.cat(&mut UserSd, args[1])?,
                "fat32_touch" if argument.is_some() => fs.touch(&mut UserSd, args[1])?,
                "fat32_read" if argument.is_some() => {
                    // This command previews one sector; fat32_cat streams the whole file.
                    let mut buffer = [0; 512];
                    let n = fs.read(&mut UserSd, args[1], &mut buffer)?;
                    out!("read size={n}\n");
                    for &byte in &buffer[..n] {
                        putchar(byte);
                    }
                    putchar(b'\n');
                }
                _ => out!("usage: {command} FILE\n"),
            }
        }
        // Recognition class IDs are part of the existing kernel/user contract.
        "speech" => {
            out!("Speech recognition start\n");
            match call_speech_recognition_api() {
                0 => out!("RESULT: UP\n"),
                1 => out!("RESULT: DOWN\n"),
                2 => out!("RESULT: UNKNOWN\n"),
                e => out!("RESULT: ERROR {e}\n"),
            }
        }
        // The C interpreter owns its REPL until psc.exit() returns control here.
        // No Rust callback enters the VM, keeping C NLR unwinding inside C frames.
        "microPython" | "micropython" => {
            out!("\n--- MicroPython start ---\n");
            let result = unsafe { super::micropython::run() };
            out!("\n--- return to PSC-OS shell (ret={result}) ---\n");
        }
        // Select passive capture, IMU analysis, or the bounded PWM transport check.
        "i2c_capture" => match argument {
            None => capture(false),
            Some("self") => capture(true),
            Some("pwm_test") => crate::elego_robot::pwm_test_command::cmd_i2c_pwm_test(),
            Some("imu_read") => crate::elego_robot::imu_command::cmd_i2c_imu(0),
            Some("imu_test") => crate::elego_robot::imu_command::cmd_i2c_imu(1),
            Some("imu_monitor") => crate::elego_robot::imu_command::cmd_i2c_imu(2),
            _ => out!("usage: i2c_capture [self|imu_read|imu_test|imu_monitor|pwm_test]\n"),
        },
        // Resident model replacement invalidates pointers obtained from a previous load.
        "yolo_backend" if args.len() <= 2 => yolo_command::cmd_backend(args.get(1).copied()),
        "yolo_backend" => out!("usage: yolo_backend cpu|pulp|npu|auto\n"),
        "yolo_diag" if args.len() == 2 && matches!(args[1], "on" | "off") => {
            yolo_command::diagnostics(args[1] == "on")
        }
        "yolo_diag" => out!("usage: yolo_diag on|off\n"),
        "yolo" if args.len() == 3 => yolo_command::command(args[1], args[2]),
        "yolo" => out!("usage: yolo MODEL.TFL IMAGE.JPG\n"),
        "tflite_info" if args.len() == 2 => {
            if let Err(e) = tflite_file::info(args[1]) {
                out!("TFLite error {e}: {}\n", tflite_file::error_string(e));
            }
        }
        "tflite_diag" if args.len() == 2 && matches!(args[1], "on" | "off") => {
            crate::api::tflite::tflite_demo::diagnostics(args[1] == "on")
        }
        // Validate the requested backend before loading or invoking a model.
        "tflite_run" if (2..=3).contains(&args.len()) => {
            let backend = match args.get(2).copied().unwrap_or("cpu") {
                "cpu" => Backend::Cpu,
                "npu" => Backend::Synap,
                "pulp" => Backend::Pulp,
                "auto" => Backend::Auto,
                _ => {
                    out!("usage: tflite_run MODEL.TFL [cpu|npu|pulp|auto]\n");
                    return Ok(());
                }
            };
            if let Err(e) = crate::api::tflite::tflite_demo::run(args[1], backend) {
                out!("TFLite run error {e}: {}\n", tflite_file::error_string(e));
            }
        }
        // The benchmark compares identical input across CPU/NPU/PULP/AUTO paths.
        "tflite_bench" if args.len() == 2 || (args.len() == 3 && args[2] == "quick") => {
            if let Err(e) = crate::api::tflite::tflite_demo::bench(args[1], args.len() == 3) {
                out!("TFLite bench error {e}: {}\n", tflite_file::error_string(e));
            }
        }
        "tflite_info" => out!("usage: tflite_info MODEL.TFL\n"),
        "tflite_run" => out!("usage: tflite_run MODEL.TFL [cpu|npu|pulp|auto]\n"),
        "tflite_bench" => out!("usage: tflite_bench MODEL.TFL [quick]\n"),
        "tflite_diag" => out!("usage: tflite_diag [on|off]\n"),
        // Finish the timer before propagating decode errors back to the prompt.
        "jpeg" => {
            if args.len() != 2 {
                out!("usage: jpeg FILE.JPG\n");
                return Ok(());
            }
            // The timer is shared; never end a measurement that this command did not acquire.
            let timing = call_timer_measure_begin() == 0;
            let result = crate::api::jpeg::jpeg_view::view(args[1]);
            let elapsed = if timing { call_timer_measure_end() } else { -1 };
            out!("JPEG result={:?}; time={elapsed} ms\n", result);
            result?;
        }
        // Exiting the shell asks the kernel to restart PSC-OS; it does not return.
        "exit" | "quit" | "q" => exit(),
        "help" => out!("{HELP}"),
        _ => out!("unknown command or invalid arguments: {command}; use help\n"),
    }
    Ok(())
}

/// Keep command storage on the stack; no allocation or borrowed input survives dispatch.
pub fn main() -> ! {
    out!("shell start.\n");
    let mut previous_switches = 0;
    loop {
        out!("\x1b[34mPSC_OS> \x1b[0m");
        // Each prompt starts with fresh storage; no command retains a borrowed token.
        let mut line = [0; 32];
        let n = read_line(&mut line, &mut previous_switches);
        // Reject invalid UTF-8 rather than constructing unchecked Rust strings.
        let Ok(text) = core::str::from_utf8(&line[..n]) else {
            out!("invalid UTF-8 command\n");
            continue;
        };
        // Match the C shell: spaces/tabs separate at most eight tokens; no quoting.
        let mut args = [""; 8];
        let mut count = 0;
        for token in text.split([' ', '\t']).filter(|s| !s.is_empty()).take(8) {
            args[count] = token;
            count += 1;
        }
        // Empty lines simply redraw the prompt; command errors do not terminate it.
        if count != 0 {
            if let Err(e) = dispatch(&args[..count]) {
                out!("{}: error {e}\n", args[0]);
            }
        }
    }
}
