#!/usr/bin/env python3
"""Scoreboard regression and latency measurements for cache_dma_controller."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile


def main():
    tests = Path(__file__).resolve().parent
    src = tests.parent / "src"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rtl", type=Path, help="Alternative RTL for revision comparisons")
    parser.add_argument("--ways", type=int, choices=(1, 2), action="append",
                        help="Select a mode (repeatable). Default: both, or 1 with --rtl.")
    parser.add_argument("--build", type=Path)
    args = parser.parse_args()
    build = args.build or Path(tempfile.mkdtemp(prefix="cache-regression-"))
    build.mkdir(parents=True, exist_ok=True)
    rtl = args.rtl or src / "cache_dma_controller.sv"
    legacy = args.rtl and not re.search(
        r"\bparameter\s+(?:(?:int|integer|bit)\s+)?PSC_CACHE_2WAY\b", rtl.read_text())
    selected_ways = args.ways or ([1] if args.rtl else [1, 2])
    cases = [(1, 6, 0), (1, 6, 1), (1, 14, 1),
             (2, 6, 0), (2, 6, 1), (2, 12, 1), (2, 14, 1)]
    for ways, tag_lsb, stall in cases:
        if ways not in selected_ways:
            continue
        name = f"{ways}way-tag{tag_lsb}-stall{stall}"
        executable = build / f"{name}.vvp"
        # Older comparison RTL selected its second way with a preprocessor define.
        legacy_flags = ["-DCACHE_TEST_LEGACY_RTL"] if legacy else []
        if legacy and ways == 2:
            legacy_flags.append("-DPSC_CACHE_2WAY")
        with (build / f"{name}-compile.log").open("w") as log:
            subprocess.run([
                "iverilog", "-g2012", *legacy_flags, "-s", "cache_regression",
                f"-Pcache_regression.PSC_CACHE_2WAY={ways - 1}",
                f"-Pcache_regression.TAGLSB={tag_lsb}",
                f"-Pcache_regression.STALL={stall}",
                "-o", str(executable), str(tests / "cache_regression.sv"),
                str(rtl.resolve()), str(src / "dm_cache_data.v"),
                str(src / "dm_cache_tag.v"),
            ], stdout=log, stderr=subprocess.STDOUT, check=True)
        result = subprocess.run(["vvp", str(executable)], text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (build / f"{name}.log").write_text(result.stdout)
        print(result.stdout, end="")
        result.check_returncode()
        if "PASS cache_regression" not in result.stdout:
            raise RuntimeError("Simulation ended without the PASS marker")
    print(f"Logs: {build.resolve()}")


if __name__ == "__main__":
    main()
