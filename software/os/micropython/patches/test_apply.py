#!/usr/bin/env python3
"""Exercise patch preparation in disposable source copies, never the worktree."""

from concurrent.futures import ThreadPoolExecutor
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
ORIGINAL = subprocess.check_output(
    ["git", "show", "HEAD:extmod/vfs_fat.c"], cwd=HERE.parent / "micropython"
)
ARTIFACTS = Path(tempfile.mkdtemp(prefix="psc-patch-tests-"))


class PatchTests(unittest.TestCase):
    def setUp(self):
        self.root = ARTIFACTS / self._testMethodName
        self.source = self.root / "micropython/micropython"
        self.patches = self.root / "micropython/patches"
        self.build = self.root / "builder"
        for directory in (self.source / "extmod", self.source / "py", self.patches, self.build):
            directory.mkdir(parents=True)
        for name in ("apply.py", "build.mk", "0001-psc-micropython.patch"):
            shutil.copy2(HERE / name, self.patches / name)
        self.target = self.source / "extmod/vfs_fat.c"
        self.target.write_bytes(ORIGINAL)
        (self.source / "py/mkenv.mk").write_text("# fixture\n")
        self.sentinel = self.source / "unrelated.txt"
        self.sentinel.write_text("Preserve this local change.\n")
        self.sentinel_state = self.state(self.sentinel)
        (self.build / "Makefile").write_text('''\
PSC_BUILD_MAKEFILE := $(abspath $(lastword $(MAKEFILE_LIST)))
include $(dir $(PSC_BUILD_MAKEFILE))../micropython/patches/build.mk
ifeq ($(PSC_PATCH_BUILD_BODY),1)
.DEFAULT_GOAL := all
.PHONY: all clean
all: a.o b.o c.o d.o e.o f.o g.o h.o
generated.c: ../micropython/micropython/extmod/vfs_fat.c
\tpython3 probe.py generate $@
a.o b.o c.o d.o e.o f.o g.o h.o: %.o: generated.c
\tpython3 probe.py compile $@
clean:
\t@echo "fixture clean (no deletion)"
endif
''')
        (self.build / "probe.py").write_text('''\
from pathlib import Path
import subprocess
import sys
source = Path("../micropython/micropython").resolve()
patch = Path("../micropython/patches/0001-psc-micropython.patch").resolve()
subprocess.run(["git", "apply", "--reverse", "--check", str(patch)], cwd=source, check=True)
with open("events.log", "a") as log:
    log.write(sys.argv[1] + " " + sys.argv[2] + "\\n")
if sys.argv[1] == "generate":
    Path(sys.argv[2]).write_text("int fixture(void) { return 1; }\\n")
else:
    subprocess.run(["cc", "-c", "generated.c", "-o", sys.argv[2]], check=True)
''')

    def tearDown(self):
        self.assertEqual(self.sentinel_state, self.state(self.sentinel))

    @staticmethod
    def state(path):
        return path.read_bytes(), path.stat().st_mtime_ns

    def run_command(self, args, success=True):
        result = subprocess.run(args, cwd=ARTIFACTS, text=True, capture_output=True)
        with (self.root / "commands.log").open("a") as log:
            log.write(f"{args!r}\n{result.stdout}{result.stderr}\n")
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout + result.stderr

    def apply(self, success=True):
        return self.run_command([sys.executable, str(self.patches / "apply.py")], success)

    def make(self, *args, success=True):
        # Deliberately invoke outside the makefile directory, including -j.
        return self.run_command(
            ["make", "-j8", "-f", str(self.build / "Makefile"), *args], success
        )

    def conflict(self):
        self.target.write_bytes(ORIGINAL.replace(
            b"mp_timestamp_t seconds = timeutils_seconds_since_epoch(",
            b"mp_timestamp_t local_change = timeutils_seconds_since_epoch("
        ))
        self.assertNotEqual(self.target.read_bytes(), ORIGINAL)

    def test_unapplied(self):
        with self.target.open("ab") as file:
            file.write(b"\n/* unrelated local modification */\n")
        self.assertIn("MicroPython: applied", self.apply())
        self.assertNotEqual(self.target.read_bytes(), ORIGINAL)
        self.assertTrue(self.target.read_bytes().endswith(b"/* unrelated local modification */\n"))
        self.run_command([
            "git", "-C", str(self.source), "apply", "--reverse", "--check",
            str(self.patches / "0001-psc-micropython.patch")
        ])

    def test_applied_preserves_local_changes_and_mtime(self):
        self.apply()
        with self.target.open("ab") as file:
            file.write(b"\n/* unrelated local modification */\n")
        before = self.state(self.target)
        self.assertIn("already applied", self.apply())
        self.assertEqual(before, self.state(self.target))

    def test_conflict_stops_build_without_changes(self):
        self.conflict()
        before = self.state(self.target)
        output = self.make(success=False)
        for diagnostic in ("build stopped", "--reverse --check", "git apply --check", "patch does not apply"):
            self.assertIn(diagnostic, output)
        self.assertEqual(before, self.state(self.target))
        self.assertFalse((self.build / "events.log").exists())

    def test_missing_submodule(self):
        self.source.rename(self.source.with_name("saved-source"))
        output = self.make(success=False)
        self.assertIn("git submodule update --init --recursive", output)
        self.assertFalse((self.build / "events.log").exists())
        self.source.with_name("saved-source").rename(self.source)

    def test_clean_only_does_not_apply_even_with_conflict(self):
        self.conflict()
        before = self.state(self.target)
        self.assertIn("fixture clean", self.make("clean"))
        self.assertEqual(before, self.state(self.target))
        self.assertFalse((self.build / "events.log").exists())

    def test_dry_run_does_not_apply(self):
        before = self.state(self.target)
        self.make("-n")
        self.assertEqual(before, self.state(self.target))
        self.assertFalse((self.build / "events.log").exists())

    def test_parallel_generation_and_compilation(self):
        output = self.make("a.o", "all", "h.o")
        self.assertLess(output.index("MicroPython: applied"), output.index("probe.py generate"))
        events = (self.build / "events.log").read_text().splitlines()
        self.assertEqual(events[0], "generate generated.c")
        self.assertEqual(len(events), 9)
        self.assertEqual(len(list(self.build.glob("*.o"))), 8)

    def test_reapplication_rebuilds_existing_outputs(self):
        self.make()
        # Only this isolated fixture is returned to the original source state.
        self.target.write_bytes(ORIGINAL)
        os.utime(self.target, (1, 1))
        self.make()
        events = (self.build / "events.log").read_text().splitlines()
        self.assertEqual(events.count("generate generated.c"), 2)
        self.assertEqual(len(events), 18)
        before = self.state(self.target)
        self.make()
        self.assertEqual(before, self.state(self.target))
        self.assertEqual(events, (self.build / "events.log").read_text().splitlines())

    def test_concurrent_patch_invocations(self):
        with ThreadPoolExecutor(max_workers=8) as pool:
            outputs = list(pool.map(lambda _: self.apply(), range(8)))
        self.assertEqual(sum("MicroPython: applied" in output for output in outputs), 1)
        self.assertEqual(sum("already applied" in output for output in outputs), 7)

    def test_real_makefiles_stop_before_loading_build_rules(self):
        self.conflict()
        before = self.state(self.target)
        # Exercise both actual entry points with missing build dependencies:
        # only the patch diagnostic should appear, before upstream includes,
        # tool discovery or source generation can run.
        for relative in ("micropython/ports/psc/Makefile", "os/Makefile"):
            makefile = self.root / relative
            makefile.parent.mkdir(parents=True)
            shutil.copy2(HERE.parent.parent / relative, makefile)
            for missing in (False, True):
                with self.subTest(makefile=relative, missing=missing):
                    if missing:
                        self.source.rename(self.source.with_name("saved-source"))
                    try:
                        output = self.run_command(
                            ["make", "-j8", "-f", str(makefile), "all"], success=False
                        )
                        diagnostic = "git submodule update --init --recursive" if missing else "build stopped"
                        self.assertIn(diagnostic, output)
                        self.assertNotIn("No rule to make target", output)
                        self.assertNotIn("Entering directory", output)
                    finally:
                        if missing:
                            self.source.with_name("saved-source").rename(self.source)
        self.assertEqual(before, self.state(self.target))


if __name__ == "__main__":
    print(f"Test artifacts (retained): {ARTIFACTS}", flush=True)
    unittest.main(verbosity=2)
