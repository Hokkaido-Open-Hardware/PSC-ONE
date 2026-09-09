# Review regressions

From the repository root:

```sh
python3 PSC-ONE/hardware/sim/tests/review_regressions/run.py
```

Requires Python 3, Icarus Verilog (`iverilog` / `vvp`), GCC and G++.
Build products are retained in a fresh directory under `TMPDIR` (default `/tmp`).
No repository source or existing build products are overwritten or removed.

The tests cover:

- Legacy/v1/v2 MMU L1 replacement, repeated cache hits, root changes and SFENCE.
- Timer restart on a tick and at expiry, normal expiry and autoreload.
- DMA RTL zero-length requests, normal transfers and repeated requests.
- DMA C size/alignment combinations, delayed start/completion and sticky old done.
- FAT32 multi-sector and fragmented directories/files, end markers, read errors,
  empty files and premature end-of-chain.
- `psc.run` accepting exactly 4096 bytes and rejecting an oversized script
  before passing it to the interpreter.
- UART polling with no received byte and with a received byte.

The C tests compile the real FAT32 source. For `dma_memcpy` and `psc_run`, the
runner extracts the production function verbatim and supplies host stubs for
CSR access and MicroPython runtime entry points. These are boundary tests;
DMA cache coherence and a complete MicroPython VM are not simulated here.
The UART test compiles the original C++ file and maps mock MMIO pages on Linux.
