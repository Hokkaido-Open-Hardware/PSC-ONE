# Copy this file and the generated phase3/MODEL.TFL to the SD root.
# MicroPython REPL: import psc; psc.run("MP_TFL.PY")
import psc


def fails(error, fn, *args):
    try:
        fn(*args)
    except error:
        return
    raise AssertionError("expected exception")


def check():
    psc.tflite_reset()
    assert psc.tflite_arena_used() == 0
    fails(OSError, psc.tflite_input_size)
    fails(OSError, psc.tflite_run, b"")
    fails(TypeError, psc.tflite_load, b"MODEL.TFL")
    fails(ValueError, psc.tflite_load, "MODEL.TFL\x00ignored")
    for backend in (-1, 2):
        fails(ValueError, psc.tflite_set_fc_backend, backend)
    for tile in (-4, 0, 5, 20):
        fails(ValueError, psc.tflite_set_synap_tile_size, tile)
    psc.tflite_load("MODEL.TFL")
    assert psc.tflite_input_size() == 16
    assert psc.tflite_arena_used() == 116
    # Fixed input/output from the existing official reference oracle.
    data = b"\x80\x7f\xfd\x00\x01\xff\x40\xc0\x07\xf5\x1f\xe0\x5a\x9c\x02\xfe"
    expected = b"\xdc\x1b\x12\x08"
    fails(TypeError, psc.tflite_run, "abcdefghijklmnop")
    fails(ValueError, psc.tflite_run, b"\x00" * 15)
    fails(ValueError, psc.tflite_run, data + b"\x00")
    psc.tflite_set_fc_backend(0)
    saved = psc.tflite_run(data)
    assert type(saved) is bytes and saved == expected
    psc.tflite_run(b"\x00" * 16)
    assert saved == expected
    print("PASS: MicroPython TFLite CPU and input validation")
    psc.tflite_set_fc_backend(1)
    for tile in (4, 8, 12, 16):
        psc.tflite_set_synap_tile_size(tile)
        assert psc.tflite_run(data) == expected
        print("PASS: MicroPython TFLite Synap tile", tile)
    psc.tflite_reset()
    assert saved == expected
    fails(OSError, psc.tflite_run, data)
    psc.tflite_load("MODEL.TFL")
    assert psc.tflite_run(data) == expected
    fails(OSError, psc.tflite_load, "ABSENT.TFL")
    fails(OSError, psc.tflite_input_size)
    fails(OSError, psc.tflite_run, data)
    assert saved == expected


try:
    check()
finally:
    psc.tflite_reset()
print("PASS: MicroPython TFLite all checks")
