"""Run with the repository Python: test_uart_gui.py [--gui]."""
import asyncio
import io
import os
from pathlib import Path
from queue import Queue
import sys
from types import SimpleNamespace
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from cocotb_tb.psc_robot.uart_gui import Console, UartGui, key_text, parse_i2c_hex

GUI_TESTS = "--gui" in sys.argv
if GUI_TESTS:
    sys.argv.remove("--gui")


class InputTests(unittest.TestCase):
    def test_i2c_hex_validation(self):
        self.assertEqual(parse_i2c_hex(["00", "ff", "0x80", "7F"]), [0, 255, 128, 127])
        for invalid in ("", "100", "-1", "GG", "0b10", "1_", "+F"):
            with self.subTest(value=invalid), self.assertRaises(ValueError):
                parse_i2c_hex([invalid, "00", "00", "00"])

    def test_keys(self):
        for keysym, char, state, expected in (
            ("a", "a", 0, "a"), ("Return", "\r", 0, "\r"),
            ("BackSpace", "\x08", 0, "\x08"), ("c", "", 4, "\x03"),
            ("Up", "", 0, "\x1b[A"), ("Shift_L", "", 0, ""),
            ("kana_A", "ア", 0, ""),
        ):
            with self.subTest(keysym=keysym):
                self.assertEqual(key_text(SimpleNamespace(
                    keysym=keysym, char=char, state=state)), expected)

    def test_existing_serial_sender_frames(self):
        from cocotb_tb.psc_robot import PSCONE_robot_test as bench
        signal = SimpleNamespace(value=1)
        waveform = []

        async def timer(duration, unit):
            waveform.append((signal.value, duration, unit))

        dut = SimpleNamespace(_log=SimpleNamespace(info=lambda message: None))
        with patch.object(bench, "Timer", timer):
            asyncio.run(bench.uart_serial_send(dut, signal, "a\x08\r\x03"))
        self.assertEqual(waveform.pop(0), (1, bench.UART_BIT_NS * 80, "ns"))
        for value in b"a\x08\r\x03":
            frame, waveform = waveform[:11], waveform[11:]
            self.assertEqual([entry[0] for entry in frame[:10]],
                             [0] + [(value >> bit) & 1 for bit in range(8)] + [1])
            self.assertEqual(frame[-1], (1, bench.UART_KEY_INTERVAL_MS, "ms"))
        self.assertEqual(waveform, [])

    def test_startup_failure(self):
        with patch.dict(os.environ, {"DISPLAY": ""}):
            with self.assertRaises(RuntimeError):
                UartGui(Queue(), "test.log")

    def test_all_input_sources_wait_for_rx_consumption(self):
        from cocotb_tb.psc_robot import PSCONE_robot_test as bench

        async def check(source):
            uart = SimpleNamespace(rx_avail=0)
            dut = SimpleNamespace(
                u_chip=SimpleNamespace(u_soc=SimpleNamespace(u_uart=uart)),
                uart_rx=SimpleNamespace(value=1),
                _log=SimpleNamespace(info=lambda message: None))
            queue = Queue()
            queue.put((source, "ab"))
            prompt = asyncio.Event()
            sent = []

            async def timer(*args, **kwargs):
                await asyncio.sleep(0)

            async def serial_send(dut, rx, text, **kwargs):
                sent.append(text)
                uart.rx_avail = 1

            with patch.object(bench, "Timer", timer), patch.object(
                    bench, "uart_serial_send", serial_send):
                worker = asyncio.create_task(bench.uart_send_worker(dut, queue, prompt))
                try:
                    await asyncio.sleep(0)
                    self.assertEqual(sent, [])
                    prompt.set()
                    for _ in range(10):
                        await asyncio.sleep(0)
                    self.assertEqual(sent, ["a"])
                    uart.rx_avail = 0
                    for _ in range(10):
                        await asyncio.sleep(0)
                    self.assertEqual(sent, ["a", "b"])
                finally:
                    worker.cancel()
                    try:
                        await worker
                    except asyncio.CancelledError:
                        pass
        for source in ("gui", "auto", "stdin"):
            with self.subTest(source=source):
                asyncio.run(check(source))

    def test_i2c_process_message_routing(self):
        gui = UartGui.__new__(UartGui)
        gui.send_queue = Queue()
        gui.i2c_queue = Queue()
        gui.ready = __import__("threading").Event()
        gui.started = False
        gui.process = SimpleNamespace(stdout=io.StringIO(
            '["ready"]\n["key", "r"]\n["i2c", [0, 255, 85, 170]]\n'))
        gui._read()
        self.assertTrue(gui.ready.is_set())
        self.assertEqual(gui.i2c_queue.get_nowait(), (0, 255, 85, 170))
        self.assertEqual(gui.send_queue.get_nowait(), ("gui", "r"))


@unittest.skipUnless(GUI_TESTS, "use --gui to test an actual display")
class GuiTests(unittest.TestCase):
    def test_render_and_keyboard(self):
        import tkinter as tk
        root = tk.Tk()
        messages = []
        try:
            console = Console(root, "test.log", messages.append)
            root.update()
            for value in b"boot\r\n\x1b[34mPSC_OS> \x1b[0mhelx\x08 \x08p\r\n":
                console.write_byte(value)
            self.assertEqual(console.text.get("1.0", "end-1c"),
                             "boot\nPSC_OS> help\n")
            console.text.focus_force()
            root.update()
            for key in ("h", "e", "l", "p", "Return", "BackSpace"):
                console.text.event_generate("<KeyPress>", keysym=key)
            root.update()
            self.assertEqual(messages, [("key", ch) for ch in "help\r\x08"])
            # Input must be echoed by the OS, not duplicated by the widget.
            self.assertEqual(console.text.get("1.0", "end-1c"),
                             "boot\nPSC_OS> help\n")
            report = "I2C RX seq=1 HEX=11 FE 80 7F\n"
            for value in report.encode("ascii"):
                console.write_byte(value)
            self.assertTrue(console.text.get("1.0", "end-1c").endswith(report))
            self.assertEqual(str(console.i2c_button["state"]), "disabled")
            console.set_i2c_state(True, "Ready")
            console.i2c_values[0].set("GG")
            self.assertEqual(str(console.i2c_button["state"]), "disabled")
            console.i2c_values[0].set("A5")
            console.i2c_button.invoke()
            self.assertEqual(messages[-1], ("i2c", [0xA5, 0xFE, 0x80, 0x7F]))
            self.assertEqual(str(console.i2c_button["state"]), "disabled")
            self.assertIn("waiting", console.i2c_status.get())
            console.set_i2c_state(True, "Received by OS")
            self.assertEqual(str(console.i2c_button["state"]), "normal")
        finally:
            root.destroy()

    def test_process_lifecycle(self):
        gui = UartGui(Queue(), "test.log")
        for value in b"PSC_OS> ":
            gui.write_byte(value)
        gui.prompt_ready()
        gui.close()
        self.assertEqual(gui.process.returncode, 0)
        self.assertFalse(gui.reader.is_alive())
        self.assertFalse(gui.writer.is_alive())


if __name__ == "__main__":
    unittest.main()
