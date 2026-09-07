#!/usr/bin/env python3
"""PSC_RV32 FST CPU viewer: parser, analysis model, and local web GUI."""

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import re
import shutil
import signal
import subprocess
import sys
import threading
import webbrowser
from dataclasses import dataclass, field
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

from riscv_decoder import decode, reg_label


APP_DIR = Path(__file__).resolve().parent
STATIC_DIR = APP_DIR / "static"

from cpu_profiles.base import (CPU_STATES, EXEC_STATES, DIV_STATES, MUL_STATES,
    LOAD_STATES, STORE_STATES, CTRL_FIELDS, unpack_ctrl, SignalInfo, CycleSample,
    InstructionRecord, ViewerError)
from cpu_profiles.v1 import unpack_stage
from cpu_profiles import select_profile


class TraceModel:
    def __init__(self, source: Path, cpu: str = "auto"):
        self.cpu_request = cpu
        self.profile = None
        self.sample_keys = ()
        self.key_indices = {}
        self.source = source.resolve()
        self.timescale = "1ps"
        self.time_factor_fs = 1_000
        self.signals: dict[str, SignalInfo] = {}
        self.samples: list[CycleSample] = []
        self.register_samples: list[tuple] = []
        self.instructions: list[InstructionRecord] = []
        self.records: dict[int, InstructionRecord] = {}
        self.first_activity = 0
        self._paths: dict[str, SignalInfo] = {}
        self._current: dict[str, int | None] = {}
        self._stage_tokens: list[int | None] = [None] * 5
        self._pc_opcode: dict[int, int] = {}
        self._next_ident = 1

    @staticmethod
    def _value(text: str) -> int | None:
        text = text.strip().lower()
        if not text or any(ch in text for ch in "xz"):
            return None
        try:
            return int(text, 2)
        except ValueError:
            return None

    def _open_vcd(self) -> subprocess.Popen | None:
        if self.source.suffix.lower() == ".vcd":
            return None
        converter = shutil.which("fst2vcd")
        if not converter:
            raise ViewerError("fst2vcd が見つかりません。gtkwave パッケージをインストールしてください。")
        return subprocess.Popen([converter, "-f", str(self.source)], stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, text=True, encoding="ascii", errors="replace",
                                bufsize=1024 * 1024)

    def parse(self) -> None:
        if not self.source.is_file():
            raise ViewerError(f"入力ファイルが見つかりません: {self.source}")
        proc = self._open_vcd()
        stream = self.source.open("r", encoding="ascii", errors="replace") if proc is None else proc.stdout
        assert stream is not None
        try:
            self._parse_stream(stream)
        except BaseException:
            if proc is not None:
                proc.terminate()
                proc.wait()
            raise
        finally:
            stream.close()
        if proc is not None:
            stderr = proc.stderr.read() if proc.stderr else ""
            return_code = proc.wait()
            if return_code:
                raise ViewerError(f"fst2vcd failed ({return_code}): {stderr.strip()}")
        if not self.samples:
            raise ViewerError("CPU clockの立ち上がりを検出できませんでした。")
        for record in self.instructions:
            if record.status != "retired":
                record.status = "flushed/incomplete"
        active = [sample.cycle for sample in self.samples if any(t is not None for t in sample.tokens)]
        self.first_activity = active[0] if active else 0

    def _parse_stream(self, stream) -> None:
        scopes: list[str] = []
        timescale_lines: list[str] = []
        reading_timescale = False
        for line in stream:
            stripped = line.strip()
            parts = stripped.split()
            if stripped.startswith("$timescale"):
                reading_timescale = True
                timescale_lines.append(stripped)
                if "$end" in stripped:
                    reading_timescale = False
            elif reading_timescale:
                timescale_lines.append(stripped)
                if "$end" in stripped:
                    reading_timescale = False
            elif parts[:2] == ["$scope", "module"]:
                scopes.append(parts[2])
            elif parts and parts[0] == "$upscope":
                if scopes:
                    scopes.pop()
            elif parts and parts[0] == "$var" and len(parts) >= 6:
                width, code, name = int(parts[2]), parts[3], parts[4]
                path = ".".join((*scopes, name))
                self._paths[path] = SignalInfo(width, code, path)
            elif parts and parts[0] == "$enddefinitions":
                break
        self._set_timescale(" ".join(timescale_lines))
        self._resolve_signals()
        code_to_keys: dict[str, list[str]] = {}
        for key, info in self.signals.items():
            code_to_keys.setdefault(info.code, []).append(key)

        current_time = 0
        changes: list[tuple[str, int | None]] = []
        for line in stream:
            stripped = line.strip()
            if not stripped or stripped.startswith("$"):
                continue
            if stripped.startswith("#"):
                if changes:
                    self._process_block(current_time, changes, code_to_keys)
                    changes = []
                try:
                    current_time = int(stripped[1:])
                except ValueError:
                    pass
                continue
            if stripped[0] in "01xXzZ":
                code, value = stripped[1:], self._value(stripped[0])
            elif stripped[0] in "bB":
                fields = stripped[1:].split(None, 1)
                if len(fields) != 2:
                    continue
                value, code = self._value(fields[0]), fields[1]
            else:
                continue
            if code in code_to_keys:
                changes.append((code, value))
        if changes:
            self._process_block(current_time, changes, code_to_keys)

    def _set_timescale(self, declaration: str) -> None:
        match = re.search(r"(\d+)\s*(s|ms|us|ns|ps|fs)", declaration, re.I)
        if not match:
            return
        number, unit = int(match.group(1)), match.group(2).lower()
        factors = {"s": 10**15, "ms": 10**12, "us": 10**9, "ns": 10**6, "ps": 10**3, "fs": 1}
        self.timescale = f"{number}{unit}"
        self.time_factor_fs = number * factors[unit]

    def _resolve_signals(self) -> None:
        self.profile = select_profile(self._paths, self.cpu_request)
        self.profile.setup(self)

    def _process_block(self, timestamp: int, changes: list[tuple[str, int | None]],
                       code_to_keys: dict[str, list[str]]) -> None:
        pre = self._current.copy()
        for code, value in changes:
            for key in code_to_keys.get(code, ()):
                self._current[key] = value
        if pre.get("clock") == 1 or self._current.get("clock") != 1:
            return
        self._sample(timestamp, pre)

    @staticmethod
    def _valid(stage: dict | None) -> bool:
        return bool(stage and stage.get("valid") == 1)

    def _new_record(self, pc: int, opcode: int, cycle: int) -> int:
        ident = self._next_ident
        self._next_ident += 1
        decoded = decode(opcode, pc).to_dict()
        record = InstructionRecord(ident, pc, opcode, decoded, cycle, cycle)
        self.instructions.append(record)
        self.records[ident] = record
        self._pc_opcode[pc] = opcode
        return ident

    def _recover_token(self, pc: int, cycle: int) -> int:
        opcode = self._pc_opcode.get(pc, 0)
        return self._new_record(pc, opcode, cycle)

    def _sample(self, timestamp, pre):
        self.profile.sample(self, timestamp, pre)
        previous = self.register_samples[-1] if self.register_samples else None
        registers = self.profile.register_values(self._current, pre, previous)
        self.register_samples.append(previous if registers == previous else registers)

    def _instruction_summary(self, ident: int | None) -> dict | None:
        if ident is None:
            return None
        record = self.records[ident]
        return {"id": ident, "pc": record.pc, "opcode": record.opcode,
                "mnemonic": record.decoded["mnemonic"], "text": record.decoded["text"],
                "category": record.decoded["category"]}

    def cycle_range(self, start: int, count: int, category: str = "ALL") -> dict:
        start = max(0, min(start, len(self.samples) - 1))
        count = max(1, min(count, 500))
        end = min(len(self.samples), start + count)
        rows = []
        for sample in self.samples[start:end]:
            tokens = []
            for token in sample.tokens:
                if token is not None and category != "ALL" and self.records[token].decoded["category"] != category:
                    token = None
                tokens.append(token)
            fetch = None
            opcode, pc_now = sample.value("opcode"), sample.value("pc_now")
            if opcode is not None and pc_now is not None and sample.value("decode_enb") == 1:
                decoded = decode(opcode, pc_now)
                if category == "ALL" or decoded.category == category:
                    fetch = {"pc": pc_now, "opcode": opcode, "mnemonic": decoded.mnemonic,
                             "text": decoded.text, "category": decoded.category}
            rows.append({
                "cycle": sample.cycle, "time_fs": sample.time_fs,
                "pc": sample.value("arch_pc"), "counter": sample.value("counter"),
                "cpu_state": self.profile.state_name("cpu_state", sample.value("cpu_state")),
                "fetch": fetch, "tokens": tokens,
                "stall": sample.value("raw_hazard") == 1,
                "busy": sample.value("execute_task_busy") == 1,
                "flush": sample.value("fifo_flush") == 1,
                "branch": sample.value("branch_taken_now") == 1,
                "mul_busy": sample.value("mul_busy") == 1,
                "div_busy": sample.value("div_busy") == 1,
            })
        used_ids = {ident for row in rows for ident in row["tokens"] if ident is not None}
        return {"start": start, "end": end, "cycles": rows,
                "instructions": {str(i): self._instruction_summary(i) for i in used_ids}}

    @staticmethod
    def _hex(value: int | None, width: int = 8) -> str | None:
        return None if value is None else f"0x{value:0{width}x}"

    def cycle_detail(self, cycle: int) -> dict:
        cycle = max(0, min(cycle, len(self.samples) - 1))
        sample = self.samples[cycle]
        stages = self.profile.inspect_stages(self, sample)
        value = sample.value
        return {
            "cycle": cycle, "time_fs": sample.time_fs,
            "pc": value("arch_pc"), "counter": value("counter"),
            "cpu_state": self.profile.state_name("cpu_state", value("cpu_state")),
            "fetch": None if value("opcode") is None or value("pc_now") is None else
                     decode(value("opcode"), value("pc_now")).to_dict(),
            "stages": stages,
            "profile_detail": self.profile.extra_detail(sample),
            "registers": self.register_detail(cycle),
            "execution": {
                "state": self.profile.state_name("execute_state", value("execute_state")),
                "busy": value("execute_busy"), "done": value("execute_done"),
                "operand_1": value("operand_1"), "operand_2": value("operand_2"),
                "alu_result": value("execute_alu_data"),
                "mul": {"active": value("is_mul_op"), "start": value("mul_start"),
                        "busy": value("mul_busy"), "done": value("mul_done"),
                        "state": self.profile.state_name("multiplier_state", value("multiplier_state")),
                        "result": value("mul_out")},
                "div": {"active": value("is_div_op"), "start": value("div_start"),
                        "busy": value("div_busy"), "done": value("div_done"),
                        "state": self.profile.state_name("divider_state", value("divider_state")),
                        "count": value("divider_count"), "quotient": value("div_quotient"),
                        "remainder": value("div_remainder")},
            },
            "memory": {
                "load_valid": value("load_valid"), "load_done": value("load_done"),
                "load_state": self.profile.state_name("load_state", value("load_state")),
                "store_valid": value("store_valid"), "store_done": value("store_done"),
                "store_state": self.profile.state_name("store_state", value("store_state")),
                "virtual_address": value("memory_alu_data"),
                "read_valid": value("data_mem_read_valid"), "read_ready": value("data_mem_read_ready"),
                "read_address": value("data_mem_read_address"), "read_data": value("data_mem_read_data"),
                "write_valid": value("data_mem_write_valid"), "write_ready": value("data_mem_write_ready"),
                "write_address": value("data_mem_write_address"), "write_data": value("data_mem_write_data"),
                "write_select": value("mem_write_sel"),
            },
            "flow": {
                "decode_fire": value("decode_fire"), "issue_fire": value("issue_fire"),
                "execute_fire": value("ex_fire"), "memory_fire": value("mem_fire"),
                "raw_hazard": value("raw_hazard"), "raw_hazard_rs1": value("raw_hazard_rs1"),
                "raw_hazard_rs2": value("raw_hazard_rs2"),
                "forward_rs1": value("forward_sel_rs1"), "forward_rs2": value("forward_sel_rs2"),
                "backend_serial": value("backend_serial"), "pipeline_empty": value("pipeline_empty"),
                "fifo_flush": value("fifo_flush"), "branch_taken": value("branch_taken_now"),
                "early_branch": value("early_branch_valid"), "next_pc": value("next_pc"),
                "branch_target_pc": value("branch_target_pc"), "seq_pc": value("seq_pc"),
                "data_page_fault": value("d_pf"), "instruction_page_fault": value("i_pf"),
                "timer_irq_take": value("timer_irq_take"),
            },
        }

    def register_detail(self, cycle):
        current = self.register_samples[cycle]
        previous = self.register_samples[cycle-1] if cycle else (None,)*32
        return {"source": self.profile.register_source, "values": [
            {"index": i, "label": reg_label(i), "value": value,
             "changed": value is not None and previous[i] is not None and value != previous[i]}
            for i, value in enumerate(current)]}

    def instruction_query(self, start: int, end: int, category: str, query: str,
                          limit: int = 400) -> list[dict]:
        query = query.strip().lower()
        result = []
        for record in self.instructions:
            if record.end_cycle < start or record.start_cycle > end:
                continue
            if category != "ALL" and record.decoded["category"] != category:
                continue
            if query and query not in record.decoded["text"].lower() and query not in f"{record.pc:08x}":
                continue
            result.append(record.to_dict())
            if len(result) >= limit:
                break
        return result

    def search(self, kind: str, text: str, start: int, direction: int) -> dict | None:
        records = self.instructions if direction >= 0 else reversed(self.instructions)
        text = text.strip().lower()
        try:
            pc_value = int(text, 0) if kind == "pc" else None
        except ValueError:
            try:
                pc_value = int(text, 16)
            except ValueError:
                return None
        for record in records:
            if direction >= 0 and record.start_cycle < start:
                continue
            if direction < 0 and record.start_cycle > start:
                continue
            matches = record.pc == pc_value if kind == "pc" else text in record.decoded["text"].lower()
            if matches:
                return record.to_dict()
        return None

    def meta(self) -> dict:
        retired = sum(record.status == "retired" for record in self.instructions)
        categories: dict[str, int] = {}
        for record in self.instructions:
            category = record.decoded["category"]
            categories[category] = categories.get(category, 0) + 1
        return {
            "cpu": self.profile.cpu, "display_model": self.profile.model,
            "stage_names": list(self.profile.stage_names),
            "source": str(self.source), "size": self.source.stat().st_size,
            "timescale": self.timescale, "cycles": len(self.samples),
            "instructions": len(self.instructions), "retired": retired,
            "first_activity": self.first_activity, "categories": categories,
            "signals": {key: {"path": info.path, "width": info.width} for key, info in self.signals.items()},
            "missing_optional": sorted(set(self.profile.specs) - set(self.signals)),
        }


class ViewerHandler(BaseHTTPRequestHandler):
    model: TraceModel

    def log_message(self, fmt: str, *args) -> None:
        if self.path.startswith("/api/"):
            return
        super().log_message(fmt, *args)

    def _json(self, data, status=HTTPStatus.OK) -> None:
        body = json.dumps(data, separators=(",", ":"), ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _integer(self, query: dict, key: str, default: int) -> int:
        try:
            return int(query.get(key, [str(default)])[0])
        except ValueError:
            return default

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        query = parse_qs(parsed.query)
        try:
            if parsed.path == "/api/meta":
                return self._json(self.model.meta())
            if parsed.path == "/api/cycles":
                start = self._integer(query, "start", self.model.first_activity)
                count = self._integer(query, "count", 80)
                category = query.get("category", ["ALL"])[0].upper()
                return self._json(self.model.cycle_range(start, count, category))
            if parsed.path.startswith("/api/cycle/"):
                return self._json(self.model.cycle_detail(int(parsed.path.rsplit("/", 1)[1])))
            if parsed.path == "/api/instructions":
                start = self._integer(query, "start", 0)
                end = self._integer(query, "end", len(self.model.samples))
                category = query.get("category", ["ALL"])[0].upper()
                text = query.get("q", [""])[0]
                return self._json(self.model.instruction_query(start, end, category, text))
            if parsed.path == "/api/search":
                kind = query.get("kind", ["mnemonic"])[0]
                text = query.get("q", [""])[0]
                start = self._integer(query, "start", 0)
                direction = self._integer(query, "direction", 1)
                return self._json(self.model.search(kind, text, start, direction))
            return self._static(parsed.path)
        except (ValueError, KeyError) as error:
            self._json({"error": str(error)}, HTTPStatus.BAD_REQUEST)

    def _static(self, request_path: str) -> None:
        relative = "index.html" if request_path in ("", "/") else request_path.lstrip("/")
        candidate = (STATIC_DIR / relative).resolve()
        if STATIC_DIR.resolve() not in candidate.parents or not candidate.is_file():
            self.send_error(HTTPStatus.NOT_FOUND)
            return
        body = candidate.read_bytes()
        mime = mimetypes.guess_type(candidate.name)[0] or "application/octet-stream"
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", mime)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def find_trace(explicit: str | None) -> Path:
    if explicit:
        return Path(explicit).expanduser()
    project = APP_DIR.parent.parent
    wave_dir = project / "hardware" / "sim" / "wave"
    candidates = list(wave_dir.glob("*.fst"))
    candidates += list(wave_dir.glob("*.vcd"))
    if not candidates:
        raise ViewerError(f"FST/VCDが指定されず、{wave_dir} にも見つかりません。")
    return max(candidates, key=lambda path: path.stat().st_mtime)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="PSC_RV32 CPU FST timeline viewer")
    parser.add_argument("trace", nargs="?", help="FST or VCD file (default: newest under hardware/sim/wave)")
    parser.add_argument("--host", default="127.0.0.1", help="HTTP bind address (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=8000, help="First HTTP port to try; 0 selects any free port")
    parser.add_argument("--cpu", choices=("auto", "legacy", "v1", "v2"), default="auto")
    parser.add_argument("--no-browser", action="store_true", help="do not open the default browser")
    parser.add_argument("--summary", action="store_true", help="parse, print JSON summary, and exit")
    return parser.parse_args()


def bind_server(host, port, handler, server_class=ThreadingHTTPServer):
    """Bind directly (no check-then-bind race); only EADDRINUSE advances."""
    import errno
    if not 0 <= port <= 65535:
        raise ViewerError("Port must be between 0 and 65535")
    for candidate in ([0] if port == 0 else range(port, 65536)):
        try:
            return server_class((host, candidate), handler)
        except OSError as error:
            if error.errno != errno.EADDRINUSE:
                raise
    raise ViewerError(f"No available port in {port}..65535")


def main() -> int:
    args = parse_args()
    try:
        trace = find_trace(args.trace)
        print(f"PSC_RV32 FST Viewer\n  trace: {trace.resolve()}\n  parsing with verified CPU signals...", flush=True)
        model = TraceModel(trace, args.cpu)
        model.parse()
        meta = model.meta()
        print(f"  cycles: {meta['cycles']:,}\n  instructions: {meta['instructions']:,} "
              f"({meta['retired']:,} retired)\n  signals: {len(meta['signals'])}", flush=True)
        if args.summary:
            print(json.dumps(meta, indent=2, ensure_ascii=False))
            return 0
        ViewerHandler.model = model
        server = bind_server(args.host, args.port, ViewerHandler)
        port = server.server_address[1]
        url = f"http://{args.host}:{port}/"
        print(f"  GUI: {url}\n  Ctrl-C to stop", flush=True)
        if not args.no_browser:
            threading.Timer(0.25, lambda: webbrowser.open(url)).start()
        signal.signal(signal.SIGINT, lambda *_: threading.Thread(target=server.shutdown).start())
        server.serve_forever()
        server.server_close()
        return 0
    except (ViewerError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
