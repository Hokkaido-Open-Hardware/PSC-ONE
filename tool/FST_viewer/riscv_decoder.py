"""Small, dependency-free RV32IM/Zicsr disassembler used by the viewer."""

from __future__ import annotations

from dataclasses import dataclass, asdict


ABI_NAMES = (
    "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
    "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
    "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
    "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6",
)


@dataclass(frozen=True, slots=True)
class DecodedInstruction:
    word: int
    pc: int
    mnemonic: str
    operands: str
    category: str
    rd: int | None = None
    rs1: int | None = None
    rs2: int | None = None
    immediate: int | None = None
    target: int | None = None

    @property
    def text(self) -> str:
        return f"{self.mnemonic} {self.operands}".rstrip()

    def to_dict(self) -> dict:
        result = asdict(self)
        result["text"] = self.text
        return result


def reg_name(index: int, abi: bool = True) -> str:
    return ABI_NAMES[index] if abi else f"x{index}"


def reg_label(index: int) -> str:
    return f"x{index} ({ABI_NAMES[index]})"


def _signed(value: int, bits: int) -> int:
    value &= (1 << bits) - 1
    sign = 1 << (bits - 1)
    return value - (1 << bits) if value & sign else value


def _result(word: int, pc: int, mnemonic: str, operands: str = "",
            category: str = "OTHER", **fields: int | None) -> DecodedInstruction:
    return DecodedInstruction(word & 0xFFFF_FFFF, pc & 0xFFFF_FFFF,
                              mnemonic, operands, category, **fields)


def decode(word: int, pc: int = 0, abi: bool = True) -> DecodedInstruction:
    """Decode instructions implemented by PSC_RV32 v1 (RV32IM + Zicsr)."""
    word &= 0xFFFF_FFFF
    pc &= 0xFFFF_FFFF
    opcode = word & 0x7F
    rd = (word >> 7) & 0x1F
    funct3 = (word >> 12) & 7
    rs1 = (word >> 15) & 0x1F
    rs2 = (word >> 20) & 0x1F
    funct7 = (word >> 25) & 0x7F
    r = lambda n: reg_name(n, abi)

    if opcode == 0x33:
        if funct7 == 0x01:
            names = ("mul", "mulh", "mulhsu", "mulhu", "div", "divu", "rem", "remu")
            mnemonic = names[funct3]
            category = "MUL" if funct3 < 4 else "DIV"
            return _result(word, pc, mnemonic, f"{r(rd)}, {r(rs1)}, {r(rs2)}",
                           category, rd=rd, rs1=rs1, rs2=rs2)
        table = {
            (0x00, 0): "add", (0x20, 0): "sub", (0x00, 1): "sll",
            (0x00, 2): "slt", (0x00, 3): "sltu", (0x00, 4): "xor",
            (0x00, 5): "srl", (0x20, 5): "sra", (0x00, 6): "or",
            (0x00, 7): "and",
        }
        if (funct7, funct3) in table:
            return _result(word, pc, table[(funct7, funct3)],
                           f"{r(rd)}, {r(rs1)}, {r(rs2)}", "ALU",
                           rd=rd, rs1=rs1, rs2=rs2)

    if opcode == 0x13:
        imm = _signed(word >> 20, 12)
        names = {0: "addi", 2: "slti", 3: "sltiu", 4: "xori", 6: "ori", 7: "andi"}
        if funct3 in names:
            return _result(word, pc, names[funct3], f"{r(rd)}, {r(rs1)}, {imm}",
                           "ALU", rd=rd, rs1=rs1, immediate=imm)
        if funct3 == 1 and funct7 == 0:
            shamt = rs2
            return _result(word, pc, "slli", f"{r(rd)}, {r(rs1)}, {shamt}",
                           "ALU", rd=rd, rs1=rs1, immediate=shamt)
        if funct3 == 5 and funct7 in (0, 0x20):
            shamt = rs2
            mnemonic = "srai" if funct7 == 0x20 else "srli"
            return _result(word, pc, mnemonic, f"{r(rd)}, {r(rs1)}, {shamt}",
                           "ALU", rd=rd, rs1=rs1, immediate=shamt)

    if opcode == 0x03:
        names = {0: "lb", 1: "lh", 2: "lw", 4: "lbu", 5: "lhu"}
        if funct3 in names:
            imm = _signed(word >> 20, 12)
            return _result(word, pc, names[funct3], f"{r(rd)}, {imm}({r(rs1)})",
                           "LOAD", rd=rd, rs1=rs1, immediate=imm)

    if opcode == 0x23:
        names = {0: "sb", 1: "sh", 2: "sw"}
        if funct3 in names:
            imm = _signed(((word >> 25) << 5) | rd, 12)
            return _result(word, pc, names[funct3], f"{r(rs2)}, {imm}({r(rs1)})",
                           "STORE", rs1=rs1, rs2=rs2, immediate=imm)

    if opcode == 0x63:
        names = {0: "beq", 1: "bne", 4: "blt", 5: "bge", 6: "bltu", 7: "bgeu"}
        if funct3 in names:
            imm = _signed(((word >> 31) << 12) | (((word >> 7) & 1) << 11) |
                          (((word >> 25) & 0x3F) << 5) | (((word >> 8) & 0xF) << 1), 13)
            target = (pc + imm) & 0xFFFF_FFFF
            return _result(word, pc, names[funct3],
                           f"{r(rs1)}, {r(rs2)}, 0x{target:08x}", "BRANCH",
                           rs1=rs1, rs2=rs2, immediate=imm, target=target)

    if opcode == 0x6F:
        imm = _signed(((word >> 31) << 20) | (((word >> 12) & 0xFF) << 12) |
                      (((word >> 20) & 1) << 11) | (((word >> 21) & 0x3FF) << 1), 21)
        target = (pc + imm) & 0xFFFF_FFFF
        return _result(word, pc, "jal", f"{r(rd)}, 0x{target:08x}", "JUMP",
                       rd=rd, immediate=imm, target=target)

    if opcode == 0x67 and funct3 == 0:
        imm = _signed(word >> 20, 12)
        return _result(word, pc, "jalr", f"{r(rd)}, {imm}({r(rs1)})", "JUMP",
                       rd=rd, rs1=rs1, immediate=imm)

    if opcode in (0x37, 0x17):
        imm = word & 0xFFFFF000
        mnemonic = "lui" if opcode == 0x37 else "auipc"
        return _result(word, pc, mnemonic, f"{r(rd)}, 0x{imm >> 12:x}", "ALU",
                       rd=rd, immediate=imm)

    if opcode == 0x0F:
        if funct3 == 0:
            pred = (word >> 24) & 0xF
            succ = (word >> 20) & 0xF
            flags = lambda x: "".join(c for bit, c in ((8, "i"), (4, "o"), (2, "r"), (1, "w")) if x & bit) or "0"
            return _result(word, pc, "fence", f"{flags(pred)}, {flags(succ)}", "SYSTEM")
        if funct3 == 1:
            return _result(word, pc, "fence.i", category="SYSTEM")

    if opcode == 0x73:
        exact = {
            0x00000073: "ecall", 0x00100073: "ebreak", 0x10200073: "sret",
            0x30200073: "mret", 0x10500073: "wfi",
        }
        if word in exact:
            return _result(word, pc, exact[word], category="SYSTEM")
        if funct7 == 0x09 and rd == 0 and funct3 == 0:
            return _result(word, pc, "sfence.vma", f"{r(rs1)}, {r(rs2)}", "SYSTEM",
                           rs1=rs1, rs2=rs2)
        csr_names = {1: "csrrw", 2: "csrrs", 3: "csrrc", 5: "csrrwi", 6: "csrrsi", 7: "csrrci"}
        if funct3 in csr_names:
            csr = (word >> 20) & 0xFFF
            mnemonic = csr_names[funct3]
            source = str(rs1) if funct3 >= 5 else r(rs1)
            fields = {"rd": rd, "immediate": rs1} if funct3 >= 5 else {"rd": rd, "rs1": rs1}
            return _result(word, pc, mnemonic, f"{r(rd)}, 0x{csr:03x}, {source}",
                           "CSR", **fields)

    return _result(word, pc, ".word", f"0x{word:08x}", "OTHER",
                   rd=rd, rs1=rs1, rs2=rs2)


__all__ = ["ABI_NAMES", "DecodedInstruction", "decode", "reg_label", "reg_name"]
