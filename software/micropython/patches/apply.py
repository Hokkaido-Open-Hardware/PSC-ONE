#!/usr/bin/env python3
"""Apply the PSC patch without replacing any existing MicroPython changes."""

import fcntl
from pathlib import Path
import subprocess
import sys


def main():
    patch = Path(__file__).resolve().with_name("0001-psc-micropython.patch")
    source = patch.parent.parent / "micropython"
    if not all((source / name).is_file() for name in ("py/mkenv.mk", "extmod/vfs_fat.c")):
        sys.exit(
            f"MicroPython submodule is missing or incomplete: {source}\n"
            "From the repository root, run: git submodule update --init --recursive"
        )

    def git(*args):
        return subprocess.run(
            ["git", *args], cwd=source, text=True, capture_output=True
        )

    # Serialize separate build invocations too, without creating a stamp or
    # modifying .git. Each invocation still verifies the actual source content.
    with patch.open("rb") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        reverse = git("apply", "--reverse", "--check", str(patch))
        if reverse.returncode == 0:
            print("MicroPython: PSC patch already applied", flush=True)
            return
        forward = git("apply", "--check", str(patch))
        if forward.returncode:
            sys.exit(
                f"MicroPython: cannot apply {patch.name}; build stopped.\n"
                "Existing changes have been preserved. Inspect the submodule diff "
                "and patch compatibility.\n"
                f"git apply --reverse --check:\n{reverse.stdout}{reverse.stderr}"
                f"git apply --check:\n{forward.stdout}{forward.stderr}"
            )
        applied = git("apply", str(patch))
        if applied.returncode:
            sys.exit(
                "MicroPython: git apply failed; build stopped.\n"
                + applied.stdout + applied.stderr
            )
        print(f"MicroPython: applied {patch.name}", flush=True)


if __name__ == "__main__":
    try:
        main()
    except OSError as error:
        sys.exit(f"MicroPython patch preparation failed: {error}")
