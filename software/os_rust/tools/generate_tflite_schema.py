#!/usr/bin/env python3
"""Generate declarative Rust verification tables from the pinned Schema v3 header.
No C implementation is linked or called. Normal builds use the checked-in tables.
Fail on unrecognized fields rather than silently omitting verification.
"""
from pathlib import Path
import argparse
import hashlib
import re
root = Path(__file__).resolve().parents[1]
header = root.parent / 'os/third_party/tflite/schema_generated.h'
s = header.read_text()
tables = dict(re.findall(r'struct (\w+) FLATBUFFERS_FINAL_CLASS : private ::flatbuffers::Table \{(.*?)\n\};', s, re.S))
ids = {name: i for i, name in enumerate(tables)}
widths = {'uint8_t':1,'int8_t':1,'uint16_t':2,'int16_t':2,'uint32_t':4,'int32_t':4,'float':4,'uint64_t':8,'int64_t':8,'double':8}
unions = {}
for name, body in re.findall(r'inline bool Verify(\w+)\(::flatbuffers::Verifier &verifier, const void \*obj, \w+ type\) \{(.*?)\n\}', s, re.S):
    entries = []
    for label, typ in re.findall(r'case (\w+): \{\s*auto ptr = reinterpret_cast<const tflite::(\w+) \*>\(obj\);', body):
        enum_value = int(re.search(r'\b'+re.escape(label)+r' = (\d+)', s)[1])
        entries.append((enum_value, ids[typ]))
    if entries: unions[name] = entries
union_ids = {name:i for i,name in enumerate(unions)}
lines = ['//! Generated schema descriptors; regenerate with tools/generate_tflite_schema.py.',
         '//! Schema SHA256: '+hashlib.sha256(header.read_bytes()).hexdigest(),
         'use super::tflite_verify::Field;', '#[rustfmt::skip]',
         'pub(super) static TABLES: &[&[Field]] = &[']
for name, body in tables.items():
    fields = dict((k,int(v)) for k,v in re.findall(r'(VT_\w+) = (\d+)',body))
    verify = re.search(r'bool Verify\(::flatbuffers::Verifier &verifier\) const \{(.*?)\n  \}', body, re.S)[1]
    scalar = {f:widths[t] for t,f in re.findall(r'VerifyField<(\w+)>\(verifier, (VT_\w+), \d+\)', verify)}
    offsets = re.findall(r'VerifyOffset\(verifier, (VT_\w+)\)',verify)
    entries = []
    for f,offset in fields.items():
        target=0
        if f in scalar: kind=scalar[f]
        else:
            assert f in offsets,(name,f,verify)
            typ=re.search(r'GetPointer<(.*?)>\('+f+r'\)',body)[1].replace('const ','').replace(' ','')
            if typ=='::flatbuffers::String*':kind=30
            elif typ=='void*':
                accessor=re.search(r'const void \*(\w+)\(\) const \{\s*return GetPointer<const void \*>\('+f+r'\)',body)[1]
                union=re.search(r'Verify(\w+)\(verifier, '+accessor+r'\(\), (\w+)\(\)\)',verify)[1]
                kind=34;target=union_ids[union]
            elif typ.startswith('::flatbuffers::Vector<'):
                inner=typ[len('::flatbuffers::Vector<'):-2]
                if inner in widths:kind=10+widths[inner]
                else:
                    nested=re.fullmatch(r'::flatbuffers::Offset<(?:tflite::)?(\w+)>',inner)
                    assert nested,(name,typ)
                    kind=32;target=ids[nested[1]]
            else:
                nested=re.fullmatch(r'tflite::(\w+)\*',typ);assert nested,(name,typ)
                kind=31;target=ids[nested[1]]
        entries.append(f'Field({offset},{kind},{target})')
    lines.append('    &['+','.join(entries)+f'], // {name}')
lines += ['];','#[rustfmt::skip]','pub(super) static UNIONS: &[&[(u8,usize)]] = &[']
for name,values in unions.items():lines.append('    &['+','.join(f'({v},{t})' for v,t in values)+f'], // {name}')
lines += ['];',f'pub(super) const MODEL: usize = {ids["Model"]};','']
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
output = root/'src/api/tflite/tflite_schema.rs'
content = '\n'.join(lines)
if args.check:
    assert output.read_text() == content, "Rust schema descriptors are stale; regenerate explicitly"
else:
    output.write_text(content)
print(f'Generated {len(tables)} tables, {len(unions)} unions')
