#!/usr/bin/env python3
"""Scoreboard regression and latency measurements for cache_dma_controller."""
import argparse
from pathlib import Path
import subprocess
import tempfile


def main():
    tests = Path(__file__).resolve().parent
    src = tests.parent / "src"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rtl", type=Path, default=src / "cache_dma_controller.sv")
    parser.add_argument("--build", type=Path)
    args = parser.parse_args()
    build = args.build or Path(tempfile.mkdtemp(prefix="cache-regression-"))
    build.mkdir(parents=True, exist_ok=True)
    for tag_lsb, stall in [(6, 0), (6, 1), (14, 1)]:
        name = f"tag{tag_lsb}-stall{stall}"
        executable = build / f"{name}.vvp"
        with (build / f"{name}-compile.log").open("w") as log:
            subprocess.run([
                "iverilog", "-g2012", "-s", "cache_regression",
                f"-Pcache_regression.TAGLSB={tag_lsb}",
                f"-Pcache_regression.STALL={stall}",
                "-o", str(executable), str(tests / "cache_regression.sv"),
                str(args.rtl.resolve()), str(src / "dm_cache_data.v"),
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
