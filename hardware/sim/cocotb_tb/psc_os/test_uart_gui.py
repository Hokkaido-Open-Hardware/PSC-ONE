"""Run with the repository Python: test_uart_gui.py [--gui]."""
import asyncio
import os
from pathlib import Path
from queue import Queue
import sys
from types import SimpleNamespace
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from cocotb_tb.psc_os.uart_gui import Console, UartGui, key_text

GUI_TESTS = "--gui" in sys.argv
if GUI_TESTS:
    sys.argv.remove("--gui")


class InputTests(unittest.TestCase):
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
        from cocotb_tb.psc_os import PSCONE_os_test as bench
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

    def test_gui_waits_for_rx_consumption(self):
        from cocotb_tb.psc_os import PSCONE_os_test as bench

        async def check():
            uart = SimpleNamespace(rx_avail=0)
            dut = SimpleNamespace(
                u_chip=SimpleNamespace(u_soc=SimpleNamespace(u_uart=uart)),
                uart_rx=SimpleNamespace(value=1),
                _log=SimpleNamespace(info=lambda message: None))
            queue = Queue()
            queue.put(("gui", "ab"))
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
        asyncio.run(check())


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
        finally:
            root.destroy()

    def test_mouse_selection_and_copy(self):
        import tkinter as tk
        root = tk.Tk()
        messages = []
        try:
            console = Console(root, "test.log", messages.append)
            text = console.text
            for value in b"boot\r\nPSC_OS> help\r\n":
                console.write_byte(value)
            text.focus_force()
            root.update()
            start = text.bbox("1.0")
            end = text.bbox("2.7")
            text.event_generate("<ButtonPress-1>", x=start[0], y=start[1])
            text.event_generate("<B1-Motion>", x=end[0], y=end[1])
            text.event_generate("<ButtonRelease-1>", x=end[0], y=end[1])
            root.update()
            self.assertEqual(text.get("sel.first", "sel.last"), "boot\nPSC_OS>")
            text.event_generate("<Control-KeyPress-c>")
            root.update()
            self.assertEqual(root.clipboard_get(), "boot\nPSC_OS>")
            self.assertEqual(messages, [])
            text.clipboard_clear()
            console.copy_menu.invoke(0)
            self.assertEqual(root.clipboard_get(), "boot\nPSC_OS>")
            # Ongoing output must not pull the selection out of view.
            for value in b"line\r\n" * 80:
                console.write_byte(value)
            root.update()
            self.assertEqual(text.index("@0,0"), "1.0")
            self.assertEqual(text.get("sel.first", "sel.last"), "boot\nPSC_OS>")
            text.tag_remove("sel", "1.0", "end")
            text.event_generate("<Control-Shift-KeyPress-C>")
            root.update()
            self.assertEqual(messages, [])
            text.event_generate("<Control-KeyPress-c>")
            root.update()
            self.assertEqual(messages, [("key", "\x03")])
            self.assertEqual(str(text.cget("state")), "disabled")
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
