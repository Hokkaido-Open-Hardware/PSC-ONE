#!/usr/bin/env python3
"""Run focused regressions; all build products stay in a new /tmp directory."""
import os
import pathlib
import subprocess
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[3]
BUILD = pathlib.Path(tempfile.mkdtemp(prefix="psc-regressions-", dir=os.environ.get("TMPDIR", "/tmp")))
print(f"Build directory: {BUILD}", flush=True)

def run(args):
    subprocess.run([str(a) for a in args], check=True, timeout=60)

for version, folder, suffix in [("legacy", "cpu", "v"), ("v1", "cpu_v1", "sv"), ("v2", "cpu_v2_experimental", "sv")]:
    exe = BUILD / ("mmu_" + version)
    run(["iverilog", "-g2012", "-s", "tb", "-o", exe, HERE / "mmu_tb.sv",
         ROOT / f"hardware/rtl/{folder}/src/MMU.{suffix}"])
    run(["vvp", exe])
for name, rtl in [("timer", "mmio/TIMER/PSC_RV32IS_TIMER.v"), ("dma", "dma/PSC_ONE_DMA_axi.v")]:
    exe = BUILD / name
    run(["iverilog", "-g2012", "-s", "tb", "-o", exe, HERE / (name + "_tb.sv"), ROOT / "hardware/rtl" / rtl])
    run(["vvp", exe])
modpsc = (ROOT / "software/micropython/ports/psc/modpsc.c").read_text()
psc_run = modpsc[modpsc.index("static mp_obj_t psc_run("):modpsc.index("static MP_DEFINE_CONST_FUN_OBJ_1(")]
(BUILD / "fat32_host.c").write_text((HERE / "fat32_harness.c").read_text().replace("/* @PSC_RUN_FUNCTION@ */", psc_run))
run(["gcc", "-std=c11", "-fno-builtin", "-Dprintf=psc_printf", "-Dputchar=psc_putchar", "-I", ROOT / "software/os/src",
     ROOT / "software/os/src/fat32.c", BUILD / "fat32_host.c", "-o", BUILD / "fat32"])
run([BUILD / "fat32"])
# Exercise the exact production function with a delayed CSR/DMA model.
# Only hardware-specific inline assembly helpers are replaced for host execution.
dma = (ROOT / "software/os/src/dma.c").read_text()
dma_function = dma[dma.index("void *dma_memcpy"):]
(BUILD / "dma_host.c").write_text((HERE / "dma_harness.c").read_text().replace("/* @DMA_FUNCTION@ */", dma_function))
run(["gcc", "-std=c11", "-O2", "-fno-pie", "-no-pie", "-Wno-pointer-to-int-cast", BUILD / "dma_host.c", "-o", BUILD / "dma_host"])
run([BUILD / "dma_host"])
run(["g++", "-std=c++17", "-O2", HERE / "uart_harness.cpp", ROOT / "hardware/sim/cpp/uart_rxtx.cpp", "-o", BUILD / "uart"])
run([BUILD / "uart"])
print("All focused regressions PASS")
