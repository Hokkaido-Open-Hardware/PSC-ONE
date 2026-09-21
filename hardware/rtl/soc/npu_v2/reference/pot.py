"""Exact exhaustive 8-bit two-term codebook; no third-party dependencies."""
import csv
import json
import math
from pathlib import Path


def term(nibble):
    return (-1 if nibble & 8 else 1) * (1 << (nibble & 7))


def decode(code):
    return 0 if code == 0 else term(code & 15) + term(code >> 4)


def encode(weight):
    if not -128 <= weight <= 127:
        raise ValueError('weight must be INT8')
    # Equal error: smaller magnitude, then smaller byte code.
    return min(range(256), key=lambda c: (abs(decode(c) - weight),
               abs(decode(c)), c))


CODES = tuple(encode(w) for w in range(-128, 128))


def quantize(weight):
    return decode(CODES[weight + 128])


def metrics(original, quantized):
    errors = [abs(a-b) for a, b in zip(original, quantized, strict=True)]
    return {'count': len(errors), 'MAE': sum(errors)/len(errors),
            'RMSE': math.sqrt(sum(e*e for e in errors)/len(errors)),
            'maximum_error': max(errors), 'changed': sum(e != 0 for e in errors)}


def evaluate(output):
    output.mkdir(parents=True, exist_ok=True)
    # Independent enumeration. +/-2 still have codes after reserving byte 0.
    terms = [s * (1 << a) for a in range(8) for s in (-1, 1)]
    possible = {a+b for a in terms for b in terms}
    assert {decode(c) for c in range(256)} == possible
    for w in range(-128, 128):
        assert abs(quantize(w)-w) == min(abs(v-w) for v in possible)
    assert CODES[128] == 0 and quantize(-128) == -128
    with (output/'int8_quantization.csv').open('w') as f:
        writer = csv.writer(f)
        writer.writerow(['original_weight', 'code', 'quantized_weight', 'absolute_error'])
        writer.writerows((w, CODES[w+128], quantize(w), abs(quantize(w)-w)) for w in range(-128,128))
    result = metrics(list(range(-128,128)), [quantize(w) for w in range(-128,128)])
    (output/'quantization.json').write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(result))


if __name__ == '__main__':
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument('--output', type=Path, required=True)
    evaluate(p.parse_args().output)
