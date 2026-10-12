# MicroPython PSC port

[PSC-ONE](../../../../README.md) · [Documentation](../../../../docs/README.md)

This port targets RV32IM with Zicsr/Zifencei. The standalone [Makefile](Makefile) uses Clang/LLVM and picolibc; the embedded PSC-OS build is managed by the [OS Makefile](../../../os/Makefile).

## Thonny / UART REPL

Build the updated FPGA design as well as PSC-OS: the UART's formerly unused
interrupt is now routed to the existing machine interrupt input. CPU RTL is
unchanged. Routing is opt-in (`UART CTRL[3]`) and is off after reset; the
existing IRQ status and `CTRL[0]` retain their meaning.

The kernel and user images must both be updated (MicroPython is in the user
image). For the existing SD boot flow, build both with:

```sh
make -C PSC-ONE/software/os MODE=psc kernel_mem ./build/user.mem
```

Use the resulting `build/kernel.mem` and `build/user.mem` with the existing
PSC-OS boot procedure; do not deploy only the kernel image.

1. Boot PSC-OS and enter `microPython` (or `micropython`) in a serial terminal.
2. Wait for `>>> `, then close the terminal to release the serial port.
3. In Thonny select **MicroPython (generic)** and the PSC-ONE USB-UART port.
   Use **115200 baud, 8 data bits, no parity, 1 stop bit**, with no RTS/CTS or
   XON/XOFF flow control. Disable RTC synchronization/validation (no RTC API).
4. Run editor code in RAM with F5; use Stop / Ctrl+C to interrupt Python.
   Thonny does not automatically launch MicroPython from the PSC-OS shell.

The port uses upstream `shared/runtime/pyexec.c` for friendly, raw and
raw-paste protocols. Ctrl+A enters raw REPL; Ctrl+B returns to friendly REPL.
In raw mode, source followed by Ctrl+D produces `OK`, stdout, `04`, exception
output, `04`, `>`. Raw-paste (`05 41 01`) replies `52 01 80 00 01`: support,
128-byte window, and one additional window credit. Its transfer ACK is `04`,
not `OK`. Protocol bytes are never echoed or newline-translated by the HAL.
Normal Python text output uses standard CRLF translation.

An empty Ctrl+D performs a MicroPython soft reset in either REPL mode. The
mode is preserved and the Python heap/globals are reinitialized. It does not
restart PSC-OS. To explicitly return to the PSC-OS shell, run:

```python
import psc
psc.exit()
```

During MicroPython, machine interrupts drain UART RX into a 1024-byte OS ring.
The shell is suspended inside the synchronous `microPython` command. Only
while execution enables an interrupt character does the IRQ handler consume
Ctrl+C and mark a pending interrupt. The VM loop, blocking stdin, and stdout
poll that notification and call `mp_sched_keyboard_interrupt()` in user
context. During source entry the standard REPL receives Ctrl+C as a byte,
including raw-paste cancellation. UART and timer sources share an IRQ entry;
UART interrupts do not advance the scheduler or alter the timer.

The port enables keyboard exceptions, standard sys streams/buffer, IO, GC,
`input`, `help('modules')`, string formatting/slicing, `sys.path`/`argv`, and
the standard writable FAT VFS. The first MBR partition, also used by the
PSC-OS FAT32 commands, is mounted at `/` on entry and on each soft reset.
The port uses MicroPython's bundled FatFs and the existing PSC-OS SD sector
syscalls. The older shell FAT32 implementation has no general write/append/
unlink API, so it is retained for its existing callers rather than expanded
into a second writable filesystem implementation.

`open()` supports text/binary reads, writes, append, seek, flush, close and
context managers. `os.listdir`, `ilistdir`, `stat`, `statvfs`, `remove`,
`rename`, `mkdir`, `rmdir`, `chdir` and `getcwd` use that SD filesystem.
Python modules can be imported from the current directory. Long ASCII names
and subdirectories are supported; filenames use FatFs's CP437 encoding, not
UTF-8. File **contents** may contain UTF-8 or arbitrary binary data. No RTC is
available: new FAT timestamps use the fixed date 2018-01-01. Files with unset
FAT dates (e.g. shell `fat32_touch`) return timestamp zero.

Use `with open(...)` or explicitly close files before reading them through
`psc.run`, `psc.fat32_ls`, TFLite or another existing shell-side reader.
The shell is suspended during MicroPython, and all remaining open files are
finalised before `psc.exit()` or a soft reset discards the Python heap.
The shell still uses its existing root-only, uppercase 8.3 lookup: for
`/sample.py`, use `fat32_cat SAMPLE.PY`. Longer names have FAT short aliases.
Those restrictions do not apply to Python's VFS APIs.

Buffered SD writes now wait for completion and verify the sector without
printing kernel diagnostics into the Raw REPL stream. The microphone's
existing diagnostic write API and the explicit SD write-test command retain
their behavior. Both the **kernel and user image** must be updated.

The card must have an MBR and a FAT32 first partition with 512-byte sectors.
The existing FPGA controller protects writes to LBAs `<= 0x1000`; the FAT,
directory, data and FSInfo sectors must lie outside that protected range.
This integration does not repartition, format or change that protection.
Read/write failures raise `OSError`; after a write error the mount rejects
further I/O until a soft reset. Data affected by a failed write is not
guaranteed to have been saved. Restore the card connection before resetting;
do not exchange cards while files are open.

With no card or an invalid filesystem, MicroPython still starts normally:
the unmounted virtual root is empty and `open()` raises `OSError(19)`
(`ENODEV`). After inserting a card, reset with Ctrl+D or run
`psc.mount_sd()` to retry and report the mount error explicitly. Calling
`psc.mount_sd()` while already mounted raises `OSError(16)` (`EBUSY`).

### Save and run from Windows Thonny

After updating both images and entering MicroPython, connect as described
above. In Thonny choose **Save as → MicroPython device**, save the following
as `/sample.py`, reopen it from the device file panel and press **F5**:

```python
import os
with open('/test.txt', 'w') as f:
    f.write('PSC-ONE SD OK\n')
with open('/test.txt', 'a') as f:
    f.write('append OK\n')
with open('/test.txt') as f:
    print(f.read())
print(os.listdir('/'))
print(os.stat('/sample.py')[6])
```

Verify the two printed lines, `sample.py` in the listing, and a nonzero
file size. Soft reset and reopen `/sample.py` to check persistence. After
`psc.exit()`, `fat32_cat TEST.TXT` should show the same content in PSC-OS.
Firmware flashing and RTC services are outside this integration.

The RISC-V GC helper saves register roots and scans the stack without printing
GC statistics into the protocol. The shell uses the kernel's existing 128KB
user stack at `USER_MAX`, instead of embedding a second stack in the binary.

Limitations: the 128KB Python heap limits normal raw source size. Raw-paste
bounds in-flight source bytes but does not remove compilation/heap limits.
UART has no hardware flow control: hosts must respect raw-paste credits and
wait for completion before sending another command. Arbitrary input floods
while Python is not reading can fill the finite ring. Long synchronous C
calls (for example TFLite) deliver pending KeyboardInterrupt when they return
to an interrupt checkpoint; they are not forcibly unwound in an IRQ.

### Reproducible simulation

From the repository root (requires the existing cocotb/Verilator environment):

```sh
myenv/bin/python PSC-ONE/software/os/tests/micropython/rtl_run.py \
  --build /tmp/psc-thonny-validation
```

This builds in isolated directories without invoking any clean target. It
runs the full PSC-OS shell and MicroPython on CPU v1 with the actual UART
pins at 115200 8N1, without `FST_UART_MODE`, register injection, or artificial
RX-ready backpressure. Results are in `results.xml`, `simulation.log`,
`protocol.jsonl`, `uart-tx.bin` (host to board) and `uart-rx.bin` (board to host).

For the Thonny startup probe, obtain `mp_back.py` and
`bare_metal_backend.py` from the
[Thonny v4.1.7 sources](https://github.com/thonny/thonny/tree/v4.1.7/thonny/plugins/micropython),
then extract its helper generators without starting a GUI:

```sh
python3 PSC-ONE/software/os/tests/micropython/thonny_helper.py \
  --mp-back /path/to/mp_back.py --bare-back /path/to/bare_metal_backend.py \
  --output /tmp/thonny-helper.py
myenv/bin/python PSC-ONE/software/os/tests/micropython/rtl_run.py \
  --build /tmp/psc-thonny-validation --thonny-helper /tmp/thonny-helper.py
```

This probe sends the original generic-serial helper over raw-paste and checks
its discovery calls. The RTL test also saves/reads/executes/imports
`sample.py`, checks append and directory operations, persists an unclosed
file across soft reset, reads Python's file from the shell, and reads a
shell-created file after re-entering Python. The SD fixture is a valid FAT32
partition with two FAT copies and FSInfo; transfers use the actual SPI model.

For faster filesystem/fault coverage on the host:

```sh
python3 PSC-ONE/software/os/tests/micropython/host_run.py \
  --build /tmp/psc-mp-vfs-host \
  --thonny-back /path/to/bare_metal_backend.py \
  --thonny-helper /tmp/thonny-helper.py
python3 PSC-ONE/software/os/tests/fat32/run.py \
  --build /tmp/psc-fat32-regression
```

The first test compiles the production PSC VFS and MicroPython REPL with a
file-backed SD HAL. On a 64-bit host it uses MPZ integers (the RV32 image
uses MicroPython's 32-bit-only longlong backend) and disables the frozen test
module. It checks multi-cluster data, metadata, directories, reset/GC,
missing/unformatted media and injected read/write/FAT-mirror/FSInfo failures.
When the optional Thonny paths are supplied, its original serial save/read
methods run against that REPL, including multiple chunks and UTF-8 content.
These are protocol tests, not a Windows Thonny GUI or physical-board test;
use the manual steps above for that final check.

## PSC-OS TFLite bindings

PSC-OS embeds this port in the same user image as the existing TFLite runtime.
The seven functions below call that C API directly; no new syscall is used.
This integration targets the embedded PSC-OS build, not standalone
`micropython.elf` (which does not link the TFLite runtime).

| API | Result / behavior |
| --- | --- |
| `psc.tflite_load(name)` | Load and prepare an uppercase 8.3 filename from the SD root; returns `None`. |
| `psc.tflite_reset()` | Reset model, results and settings; returns `None`. |
| `psc.tflite_input_size()` | Required input size in bytes; raises `OSError` when unprepared. |
| `psc.tflite_run(data)` | Copy input, synchronously invoke, and return a Python-owned `bytes` copy. |
| `psc.tflite_set_fc_backend(backend)` | `0` = CPU, `1` = Synap; returns `None`. |
| `psc.tflite_set_synap_tile_size(size)` | Select `4`, `8`, `12` or `16`; returns `None`. |
| `psc.tflite_arena_used()` | C arena bytes used, zero after reset. |

`tflite_run` accepts a readable byte buffer, rejects text strings, and requires
exactly the model input byte count. INT8 values use two's-complement encoding
(`-1` is byte `255`). It exposes no arena or internal buffer memoryview.
Returned bytes survive subsequent inference, load and reset operations.
Wrong types raise `TypeError`; wrong input lengths, backend/tile values and
embedded NUL filenames raise `ValueError`. C API failures raise `OSError`
with the original negative error code in `args[0]`.

The shell and Python share one resident model. A C API load failure also
invalidates the old model; shell `tflite_info` invalidates it too. Leaving the
REPL does not reset TFLite. Load/reset restores CPU backend and tile size 4.
Synap errors do not fall back to CPU. Inference is synchronous and provides
no Python callback or cancellation hook. The existing limited INT8 FC model
profile, 8 KiB model capacity and 4 KiB arena still apply.

Build from `PSC-ONE/software/os` with `make MODE=psc kernel_mem`.
For a board/RTL smoke test, generate the existing deterministic model:

```sh
python3 PSC-ONE/software/os/tests/tflite/generate_model.py --build /tmp/psc-tflite-demo
```

Copy `/tmp/psc-tflite-demo/MODEL.TFL` and
`PSC-ONE/software/os/tests/tflite/MP_TFL.PY` to the SD root (ensure
`ABSENT.TFL` does not exist). In the PSC-OS MicroPython REPL run:

```python
import psc
psc.run("MP_TFL.PY")
```

The script checks known CPU output, all four Synap tile sizes, argument errors,
load/reset behavior and output-copy lifetime. It requires working Synap
hardware (or RTL simulation), and ends with
`PASS: MicroPython TFLite all checks` only when every assertion succeeds.

## Build modes

From the repository root, build the PSC-OS image with:

```sh
make -C PSC-ONE/software/os MODE=psc kernel_mem
```

For the standalone port, inspect the compiler and picolibc paths in the local
Makefile, then run `make -C PSC-ONE/software/micropython/ports/psc`.
The standalone image does not include the PSC-OS TFLite runtime.
