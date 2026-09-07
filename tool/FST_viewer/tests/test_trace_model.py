import unittest

from fst_viewer import CTRL_FIELDS, unpack_ctrl, unpack_stage


def pack_ctrl(values):
    raw = 0
    for name, width in CTRL_FIELDS:
        raw = (raw << width) | (values.get(name, 0) & ((1 << width) - 1))
    return raw


class PackedStructTests(unittest.TestCase):
    def setUp(self):
        self.ctrl_values = {
            "r_addr1": 11, "r_addr2": 12, "w_addr": 10,
            "imm": 0xFFFF_FFFC, "alucon": 0b11100, "funct3": 4,
            "rf_wen": 1, "is_R_type": 1,
        }
        self.ctrl = pack_ctrl(self.ctrl_values)

    def test_control_width_and_fields(self):
        self.assertEqual(sum(width for _, width in CTRL_FIELDS), 130)
        unpacked = unpack_ctrl(self.ctrl)
        for key, value in self.ctrl_values.items():
            self.assertEqual(unpacked[key], value)

    def test_issue_execute_layout(self):
        raw = (1 << 226) | (self.ctrl << 96) | (0x1020 << 64) | (0x10 << 32) | 0x20
        stage = unpack_stage(raw, "issue_ex")
        self.assertEqual(stage["valid"], 1)
        self.assertEqual(stage["pc"], 0x1020)
        self.assertEqual(stage["rs1_value"], 0x10)
        self.assertEqual(stage["rs2_value"], 0x20)
        self.assertEqual(stage["ctrl"]["w_addr"], 10)

    def test_commit_layout(self):
        raw = ((1 << 259) | (self.ctrl << 129) | (0x1020 << 97) |
               (0x10 << 65) | (0x200 << 33) | (1 << 32) | 0x204)
        stage = unpack_stage(raw, "commit")
        self.assertEqual(stage["pc"], 0x1020)
        self.assertEqual(stage["alu_result"], 0x200)
        self.assertEqual(stage["branch_taken"], 1)
        self.assertEqual(stage["writeback_value"], 0x204)


if __name__ == "__main__":
    unittest.main()
