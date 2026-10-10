"""UART console in a separate Tk process; simulator access stays in cocotb."""
import json
import os
from pathlib import Path
from queue import Empty, Queue
import subprocess
import sys
import threading


class UartGui:
    def __init__(self, send_queue, logfile, i2c_queue=None):
        self.send_queue = send_queue
        self.i2c_queue = i2c_queue
        self.output = Queue()
        self.ready = threading.Event()
        self.started = False
        self.error = "GUI did not become ready"
        self.process = subprocess.Popen(
            [sys.executable, "-u", str(Path(__file__).resolve()), str(logfile)],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            text=True, encoding="utf-8", bufsize=1,
        )
        self.reader = threading.Thread(target=self._read, daemon=True)
        self.writer = threading.Thread(target=self._write, daemon=True)
        self.reader.start()
        self.writer.start()
        if not self.ready.wait(5) or not self.started:
            self.close()
            raise RuntimeError(self.error)

    def _read(self):
        try:
            for line in self.process.stdout:
                message = json.loads(line)
                if message[0] == "ready":
                    self.started = True
                    self.ready.set()
                elif message[0] == "key":
                    self.send_queue.put(("gui", message[1]))
                elif message[0] == "i2c" and self.i2c_queue is not None:
                    self.i2c_queue.put(tuple(message[1]))
                elif message[0] == "error":
                    self.error = message[1]
        finally:
            self.ready.set()
            if self.started:
                self.send_queue.put(("notice", "UART GUI closed; simulation continues."))

    def _write(self):
        try:
            while True:
                message = self.output.get()
                if message is None:
                    break
                self.process.stdin.write(json.dumps(message) + "\n")
                self.process.stdin.flush()
        except (BrokenPipeError, OSError):
            pass
        finally:
            try:
                self.process.stdin.close()
            except OSError:
                pass

    def write_byte(self, value):
        if self.process.poll() is None:
            self.output.put(("byte", value))

    def prompt_ready(self):
        if self.process.poll() is None:
            self.output.put(("status", "Ready — keys are sent to UART RX"))

    def i2c_state(self, ready, text):
        if self.process.poll() is None:
            self.output.put(("i2c_state", ready, text))

    def close(self):
        self.output.put(None)
        try:
            self.process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            self.process.terminate()
            try:
                self.process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
        self.writer.join(timeout=1)
        self.reader.join(timeout=1)
        self.process.stdout.close()


def key_text(event):
    """Translate terminal keys without applying local echo."""
    special = {
        "Return": "\r", "KP_Enter": "\r", "BackSpace": "\x08",
        "Tab": "\t", "Escape": "\x1b", "Delete": "\x1b[3~",
        "Up": "\x1b[A", "Down": "\x1b[B", "Right": "\x1b[C",
        "Left": "\x1b[D", "Home": "\x1b[H", "End": "\x1b[F",
    }
    if event.keysym in special:
        return special[event.keysym]
    if event.state & 4 and len(event.keysym) == 1:
        value = ord(event.keysym.upper())
        if 64 <= value <= 95:
            return chr(value & 31)
    # The existing sender transports 8-bit characters, not Unicode codepoints.
    return "".join(ch for ch in event.char if ord(ch) < 256)


def parse_i2c_hex(values):
    """Four byte values, in INPUT0..INPUT3 wire order; optional 0x prefix."""
    if len(values) != 4:
        raise ValueError("Enter four bytes")
    result = []
    for index, value in enumerate(values):
        value = value.strip()
        if value.lower().startswith("0x"):
            value = value[2:]
        if not 1 <= len(value) <= 2 or any(c not in "0123456789abcdefABCDEF" for c in value):
            raise ValueError(f"INPUT{index}: enter 00–FF")
        result.append(int(value, 16))
    return result


class Console:
    def __init__(self, root, logfile, send):
        import tkinter as tk
        from tkinter.scrolledtext import ScrolledText

        self.root = root
        self.send = send
        root.title("PSC-OS Robot — UART / I2C")
        root.geometry("1180x640")
        root.minsize(960, 480)
        self.status = tk.StringVar(value="Waiting for PSC_OS> — input is queued")
        tk.Label(root, textvariable=self.status, anchor="w").pack(fill="x")
        body = tk.Frame(root)
        body.pack(fill="both", expand=True)
        panel = tk.Frame(body, padx=18, pady=18, width=280)
        panel.pack(side="right", fill="y")
        tk.Label(panel, text="I2C TRANSMIT", font=("sans", 14, "bold"), anchor="w").pack(fill="x")
        tk.Label(panel, text="Slave 0x42  ·  Register 0x00\n4 bytes / HEX 00–FF", justify="left", anchor="w").pack(fill="x", pady=(8, 18))
        self.i2c_values = []
        for index, value in enumerate(("11", "FE", "80", "7F")):
            row = tk.Frame(panel)
            row.pack(fill="x", pady=5)
            tk.Label(row, text=f"INPUT{index}", width=9, anchor="w").pack(side="left")
            var = tk.StringVar(value=value)
            self.i2c_values.append(var)
            tk.Entry(row, textvariable=var, width=8, font=("monospace", 14)).pack(side="right")
            var.trace_add("write", self.update_i2c_preview)
        self.i2c_preview = tk.StringVar()
        tk.Label(panel, textvariable=self.i2c_preview, font=("monospace", 12), anchor="w").pack(fill="x", pady=(20, 10))
        self.i2c_button = tk.Button(panel, text="Send I2C", command=self.send_i2c, state="disabled", pady=8)
        self.i2c_button.pack(fill="x")
        self.i2c_status = tk.StringVar(value="Waiting for robot_control")
        tk.Label(panel, textvariable=self.i2c_status, justify="left", anchor="w", wraplength=240).pack(fill="x", pady=12)
        tk.Label(panel, text="UART console: q / Ctrl-C to stop", anchor="w").pack(side="bottom", fill="x")
        self.i2c_ready = False
        self.update_i2c_preview()
        self.text = ScrolledText(
            body, background="#101820", foreground="#e6edf3",
            insertbackground="#e6edf3", font=("monospace", 12),
            wrap="char", state="disabled", takefocus=True,
        )
        self.text.pack(fill="both", expand=True)
        tk.Label(root, text=f"UART log: {logfile}", anchor="w").pack(fill="x")
        self.text.bind("<KeyPress>", self.on_key)
        self.text.focus_set()
        self.column = 0
        self.escape = ""

    def update_i2c_preview(self, *args):
        if not hasattr(self, "i2c_button"):
            return
        try:
            frame = parse_i2c_hex([var.get() for var in self.i2c_values])
            self.i2c_preview.set("HEX  " + " ".join(f"{byte:02X}" for byte in frame))
            valid = True
        except ValueError as exc:
            self.i2c_preview.set(str(exc))
            valid = False
        self.i2c_button.configure(state="normal" if valid and self.i2c_ready else "disabled")

    def set_i2c_state(self, ready, text):
        self.i2c_ready = ready
        self.i2c_status.set(text)
        self.update_i2c_preview()

    def send_i2c(self):
        if not self.i2c_ready:
            return
        try:
            frame = parse_i2c_hex([var.get() for var in self.i2c_values])
        except ValueError:
            self.update_i2c_preview()
            return
        self.set_i2c_state(False, "Sending… waiting for OS receive report")
        self.send(("i2c", frame))

    def on_key(self, event):
        value = key_text(event)
        if value:
            self.send(("key", value))
        return "break"

    def write_byte(self, value):
        # Preserve CR/LF and backspace semantics for OS command echo/editing.
        # PSC-OS emits ANSI colour sequences around its prompt. Consume CSI
        # sequences so the console does not show literal "[34m" / "[0m".
        if self.escape:
            if self.escape == "\x1b" and value == ord("["):
                self.escape = "\x1b["
            elif self.escape == "\x1b" or 0x40 <= value <= 0x7e:
                self.escape = ""
            return
        if value == 27:
            self.escape = "\x1b"
            return
        text = self.text
        text.configure(state="normal")
        if value == 13:
            self.column = 0
        elif value == 10:
            text.insert("end-1c", "\n")
            self.column = 0
        elif value == 8:
            self.column = max(0, self.column - 1)
        elif value == 9 or value >= 32 and value != 127:
            line = int(text.index("end-1c").split(".")[0])
            index = f"{line}.{self.column}"
            if text.compare(index, "<", "end-1c"):
                text.delete(index, f"{index}+1c")
            text.insert(index, chr(value))
            self.column += 1
        # Bound scrollback during long simulations.
        lines = int(text.index("end-1c").split(".")[0])
        if lines > 10000:
            text.delete("1.0", f"{lines - 10000}.0")
        text.configure(state="disabled")
        text.see("end")


def main():
    def send(message):
        print(json.dumps(message), flush=True)

    try:
        import tkinter as tk
        root = tk.Tk()
    except Exception as exc:
        send(("error", str(exc)))
        return 1
    console = Console(root, sys.argv[1], send)
    incoming = Queue()

    def read_input():
        # Avoid holding a buffered stdin lock when the user closes the window
        # while this daemon thread is waiting for the simulator.
        pending = b""
        while True:
            chunk = os.read(sys.stdin.fileno(), 65536)
            if not chunk:
                break
            pending += chunk
            while b"\n" in pending:
                line, pending = pending.split(b"\n", 1)
                incoming.put(json.loads(line))
        incoming.put(None)

    def poll():
        for _ in range(4096):
            try:
                message = incoming.get_nowait()
            except Empty:
                break
            if message is None:
                root.destroy()
                return
            if message[0] == "byte":
                console.write_byte(message[1])
            elif message[0] == "status":
                console.status.set(message[1])
            elif message[0] == "i2c_state":
                console.set_i2c_state(message[1], message[2])
        root.after(20, poll)

    threading.Thread(target=read_input, daemon=True).start()
    root.after(20, poll)
    send(("ready",))
    root.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
