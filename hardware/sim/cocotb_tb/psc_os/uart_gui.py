"""UART console in a separate Tk process; simulator access stays in cocotb."""
import json
import os
from pathlib import Path
from queue import Empty, Queue
import subprocess
import sys
import threading


class UartGui:
    def __init__(self, send_queue, logfile):
        self.send_queue = send_queue
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


class Console:
    def __init__(self, root, logfile, send):
        import tkinter as tk
        from tkinter.scrolledtext import ScrolledText

        self.root = root
        self.send = send
        root.title("PSC-OS UART Console")
        root.geometry("960x640")
        self.status = tk.StringVar(value="Waiting for PSC_OS> — input is queued")
        tk.Label(root, textvariable=self.status, anchor="w").pack(fill="x")
        self.text = ScrolledText(
            root, background="#101820", foreground="#e6edf3",
            insertbackground="#e6edf3", font=("monospace", 12),
            selectbackground="#3465a4", selectforeground="#ffffff",
            exportselection=False,
            wrap="char", state="disabled", takefocus=True,
        )
        self.text.pack(fill="both", expand=True)
        tk.Label(root, text=f"UART log: {logfile}", anchor="w").pack(fill="x")
        self.text.bind("<KeyPress>", self.on_key)
        # Physical bindings take precedence over Tk's virtual Copy shortcut.
        self.text.bind("<Control-KeyPress-c>", self.on_key)
        self.text.bind("<Control-KeyPress-C>", self.on_key)
        self.text.bind("<<Copy>>", self.copy_selection)
        self.copy_menu = tk.Menu(self.text, tearoff=False)
        self.copy_menu.add_command(label="Copy", command=self.copy_selection)
        self.text.bind("<Button-3>", self.show_copy_menu)
        self.text.focus_set()
        self.column = 0
        self.escape = ""

    def on_key(self, event):
        if event.state & 4 and event.keysym.lower() == "c":
            # Keep Ctrl+C as a terminal interrupt when nothing is selected.
            # Ctrl+Shift+C is always a local copy shortcut.
            if self.text.tag_ranges("sel") or event.state & 1:
                return self.copy_selection()
        value = key_text(event)
        if value:
            self.send(("key", value))
        return "break"

    def copy_selection(self, event=None):
        if self.text.tag_ranges("sel"):
            selected = self.text.get("sel.first", "sel.last")
            self.text.clipboard_clear()
            self.text.clipboard_append(selected)
        return "break"

    def show_copy_menu(self, event):
        self.copy_menu.entryconfigure(
            0, state="normal" if self.text.tag_ranges("sel") else "disabled")
        try:
            self.copy_menu.tk_popup(event.x_root, event.y_root)
        finally:
            self.copy_menu.grab_release()
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
        follow_output = text.yview()[1] >= 1.0 and not text.tag_ranges("sel")
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
        if follow_output:
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
        root.after(20, poll)

    threading.Thread(target=read_input, daemon=True).start()
    root.after(20, poll)
    send(("ready",))
    root.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
