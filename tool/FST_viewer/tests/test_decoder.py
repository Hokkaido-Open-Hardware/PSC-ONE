import unittest

from riscv_decoder import decode, reg_label


class DecoderTests(unittest.TestCase):
    def check(self, word, mnemonic, text=None, pc=0x1000):
        decoded = decode(word, pc)
        self.assertEqual(decoded.mnemonic, mnemonic)
        if text is not None:
            self.assertEqual(decoded.text, text)
        return decoded

    def test_base_integer(self):
        self.check(0x00C58533, "add", "add a0, a1, a2")
        self.check(0x40C58533, "sub", "sub a0, a1, a2")
        self.check(0x00400093, "addi", "addi ra, zero, 4")
        self.check(0x00012503, "lw", "lw a0, 0(sp)")
        self.check(0x00A12023, "sw", "sw a0, 0(sp)")

    def test_m_extension(self):
        self.check(0x02C58533, "mul", "mul a0, a1, a2")
        for funct3, mnemonic in enumerate(("mul", "mulh", "mulhsu", "mulhu", "div", "divu", "rem", "remu")):
            word = (1 << 25) | (12 << 20) | (11 << 15) | (funct3 << 12) | (10 << 7) | 0x33
            self.check(word, mnemonic)

    def test_control_and_csr(self):
        branch = self.check(0x00000463, "beq")
        self.assertEqual(branch.target, 0x1008)
        csr_word = (0x300 << 20) | (11 << 15) | (1 << 12) | (10 << 7) | 0x73
        self.check(csr_word, "csrrw", "csrrw a0, 0x300, a1")
        self.check(0x30200073, "mret")
        self.check(0x12000073, "sfence.vma")

    def test_register_label(self):
        self.assertEqual(reg_label(10), "x10 (a0)")


if __name__ == "__main__":
    unittest.main()
