#!/usr/bin/env python3
"""Verify the exact vendored inputs locally; never downloads or changes files."""
import hashlib
import json
from pathlib import Path

base = Path(__file__).resolve().parents[2] / 'third_party/tflite'
manifest = json.loads((base / 'manifest.json').read_text())
expected = manifest['files_sha256']
actual = {p.relative_to(base).as_posix() for p in base.rglob('*') if p.is_file()}
actual -= {'README.md', 'manifest.json'}
if actual != set(expected):
    raise SystemExit(f'vendor file set mismatch: missing={set(expected)-actual}, extra={actual-set(expected)}')
for name, sha in expected.items():
    path = base / name
    if path.is_symlink() or hashlib.sha256(path.read_bytes()).hexdigest() != sha:
        raise SystemExit(f'vendor checksum mismatch: {name}')
print(f'PASS: vendor SHA-256 ({len(expected)} upstream files, FlatBuffers 25.9.23)')
