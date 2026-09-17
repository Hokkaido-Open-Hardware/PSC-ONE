"""Shared profile contract, normalized trace records and packed control layout."""
from __future__ import annotations
from dataclasses import dataclass, field
from riscv_decoder import decode, reg_label

CPU_STATES = {0: "IDLE", 1: "CPU_RUN", 2: "CPU_TRAP", 3: "CPU_HALT", 4: "EXECUTE (TBD)"}
EXEC_STATES = {0: "IDLE", 1: "DIV_WAIT", 2: "MUL_WAIT", 3: "RESULT_HOLD"}
DIV_STATES = {0: "IDLE", 1: "INIT", 2: "RUN", 3: "FIX", 4: "DONE"}
MUL_STATES = {0: "IDLE", 1: "RUN"}
LOAD_STATES = {
    0: "IDLE", 1: "BRANCH_MMU", 2: "BRANCH_MMU_W",
    3: "BRANCH_ACCESS", 4: "BRANCH_WAIT", 5: "BRANCH_DONE",
}
STORE_STATES = {
    0: "IDLE", 1: "STORE_MMU", 2: "STORE_MMU_W",
    3: "STORE_ACCESS", 4: "STORE_WAIT", 5: "STORE_DONE",
}
STAGE_NAMES = ("ID / ISSUE", "EXECUTE", "MEMORY", "WRITEBACK", "COMMIT")


CTRL_FIELDS = (
    ("r_addr1", 5), ("r_addr2", 5), ("w_addr", 5), ("imm", 32),
    ("alucon", 5), ("funct3", 3), ("op1sel", 1), ("op2sel", 1),
    ("mem_rw", 1), ("rf_wen", 1), ("wb_sel", 2), ("pc_sel", 2),
    ("out_pc", 32), ("is_fence", 1), ("is_fence_i", 1),
    ("is_sfence_vma", 1), ("csr_wr", 1), ("csr_cmd", 2),
    ("csr_use_imm", 1), ("csr_addr", 12), ("csr_zimm", 5),
    ("is_sret", 1), ("is_mret", 1), ("is_ecall", 1),
    ("is_load", 1), ("is_store", 1), ("use_rs1", 1),
    ("use_rs2", 1), ("is_R_type", 1), ("is_op_imm", 1),
    ("pipeline_type", 1), ("raise_illegal_instruction", 1),
)
assert sum(width for _, width in CTRL_FIELDS) == 130


class ViewerError(RuntimeError):
    pass


def unpack_ctrl(raw: int | None) -> dict[str, int | None]:
    if raw is None:
        return {name: None for name, _ in CTRL_FIELDS}
    result: dict[str, int] = {}
    pos = 130
    for name, width in CTRL_FIELDS:
        pos -= width
        result[name] = (raw >> pos) & ((1 << width) - 1)
    return result


@dataclass(slots=True)
class SignalInfo:
    width: int
    code: str
    path: str


@dataclass(slots=True)
class CycleSample:
    cycle: int
    time_fs: int
    values: tuple[int | None, ...]
    tokens: tuple[int | None, ...]
    indices: dict = field(default_factory=dict)

    def value(self, key: str) -> int | None:
        return self.values[self.indices[key]] if key in self.indices else None


@dataclass(slots=True)
class InstructionRecord:
    ident: int
    pc: int
    opcode: int
    decoded: dict
    start_cycle: int
    end_cycle: int
    stages: dict[str, list[int]] = field(default_factory=dict)
    rs1_value: int | None = None
    rs2_value: int | None = None
    alu_result: int | None = None
    writeback_value: int | None = None
    branch_taken: int | None = None
    status: str = "in-flight"

    def touch(self, stage: str, cycle: int, data: dict | None) -> None:
        span = self.stages.setdefault(stage, [cycle, cycle])
        span[1] = cycle
        self.end_cycle = max(self.end_cycle, cycle)
        if not data:
            return
        self.rs1_value = data.get("rs1_value", self.rs1_value)
        self.rs2_value = data.get("rs2_value", self.rs2_value)
        self.alu_result = data.get("alu_result", self.alu_result)
        self.writeback_value = data.get("writeback_value", self.writeback_value)
        self.branch_taken = data.get("branch_taken", self.branch_taken)
        if stage == "COMMIT":
            self.status = "retired"

    def to_dict(self) -> dict:
        result = {
            "id": self.ident, "pc": self.pc, "opcode": self.opcode,
            "decoded": self.decoded, "category": self.decoded["category"],
            "mnemonic": self.decoded["mnemonic"], "text": self.decoded["text"],
            "start": self.start_cycle, "end": self.end_cycle,
            "cycles": self.end_cycle - self.start_cycle + 1,
            "stages": self.stages, "status": self.status,
            "rs1_value": self.rs1_value, "rs2_value": self.rs2_value,
            "alu_result": self.alu_result, "writeback_value": self.writeback_value,
            "branch_taken": self.branch_taken,
        }
        return result



class BaseProfile:
    register_bank = None
    register_source = "FST register array"
    cpu = ""
    model = ""
    stage_names = ()
    stage_keys = ()
    required = {}
    specs = {}
    optional_widths = {}
    state_maps = {"cpu_state": CPU_STATES, "execute_state": EXEC_STATES,
                  "divider_state": DIV_STATES, "multiplier_state": MUL_STATES,
                  "load_state": LOAD_STATES, "store_state": STORE_STATES}

    def state_name(self, key, value):
        if value is None:
            return "—"
        return self.state_maps.get(key, {}).get(value, f"UNKNOWN({value})")

    def discover(self, paths):
        return [p[:-len(self.anchor)] for p in paths if p.endswith(self.anchor)]

    def setup(self, m):
        roots = self.discover(m._paths)
        if len(roots) != 1:
            raise ViewerError(f"{self.cpu}: hierarchy ambiguous/missing: {roots}")
        self.root = roots[0]
        for key, suffix in self.specs.items():
            info = m._paths.get(self.root + suffix)
            if info:
                m.signals[key] = info
        if self.register_bank:
            for i in range(32):
                info = m._paths.get(self.root + self.register_bank.format(i=i))
                if info:
                    if info.width != 32:
                        raise ViewerError(f"{self.cpu}: x{i} expected 32 bits, got {info.width}")
                    m.signals[f"x{i}"] = info
        for key, width in self.required.items():
            info = m.signals.get(key)
            if info is None or info.width != width:
                raise ViewerError(f"{self.cpu}: required signal {key}: expected {width} bits, got {info}")
        for key, width in self.optional_widths.items():
            info = m.signals.get(key)
            if info is not None and info.width != width:
                raise ViewerError(f"{self.cpu}: optional signal {key}: expected {width} bits, got {info.width}")
        m.sample_keys = tuple(m.signals)
        m.key_indices = {key: i for i, key in enumerate(m.sample_keys)}
        m._current = dict.fromkeys(m.sample_keys)
        m._stage_tokens = [None] * len(self.stage_names)

    def append(self, m, timestamp, tokens):
        m._stage_tokens = list(tokens)
        m.samples.append(CycleSample(len(m.samples), timestamp*m.time_factor_fs,
            tuple(m._current.get(key) for key in m.sample_keys), tuple(tokens), m.key_indices))

    def stage_data(self, sample):
        raise NotImplementedError

    def register_values(self, current, pre, previous):
        return tuple(current.get(f"x{i}") for i in range(32))

    def extra_detail(self, sample):
        return {}

    def inspect_stages(self, m, sample):
        result = []
        for name, ident, data in zip(self.stage_names, sample.tokens, self.stage_data(sample)):
            if ident is None or not data:
                result.append({"name": name, "instruction": None})
                continue
            ctrl = data.get("ctrl", {})
            r = m.records[ident]
            fields = {}
            for role, key, use in (("rs1","r_addr1","use_rs1"),("rs2","r_addr2","use_rs2"),("rd","w_addr","rf_wen")):
                n = ctrl.get(key)
                fields[role] = n
                fields[role+"_label"] = reg_label(n) if n is not None and ctrl.get(use) else "—"
            result.append({"name":name,"instruction":r.to_dict(),"pc":r.pc,
                "ctrl":ctrl, **fields, **{k:data.get(k) for k in
                    ("rs1_value","rs2_value","alu_result","writeback_value","branch_taken")}})
        return result
