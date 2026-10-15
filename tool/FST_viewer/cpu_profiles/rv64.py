"""CPU_RV64 pipeline layouts from cpu_rv64/src/PSC_{Types,InstructionUnit}.sv."""
from .base import CTRL_FIELDS, unpack_ctrl
from .v1 import V1Profile


# RV64 widens imm/out_pc and inserts two flags before pipeline_type.
RV64_CTRL_FIELDS = tuple(
    (name, 64 if name in ("imm", "out_pc") else width)
    for name, width in CTRL_FIELDS[:-2]
) + (("word_op", 1), ("is_ebreak", 1)) + CTRL_FIELDS[-2:]
assert sum(width for _, width in RV64_CTRL_FIELDS) == 196

STAGE_FIELDS = {
    "id_issue": (("pc", 64),),
    "issue_ex": (("pc", 64), ("rs1_value", 64), ("rs2_value", 64)),
    "ex_mem": (("pc", 64), ("rs1_value", 64), ("rs2_value", 64), ("alu_result", 64)),
    "mem_wb": (("pc", 64), ("rs1_value", 64), ("alu_result", 64),
               ("branch_taken", 1), ("writeback_value", 64)),
}
STAGE_FIELDS["commit"] = STAGE_FIELDS["mem_wb"]


def unpack_stage(raw, name):
    if raw is None:
        return None
    fields = (("valid", 1), ("ctrl", 196)) + STAGE_FIELDS[name]
    pos = sum(width for _, width in fields)
    result = {}
    for key, width in fields:
        pos -= width
        result[key] = (raw >> pos) & ((1 << width) - 1)
    result["ctrl"] = unpack_ctrl(result["ctrl"], RV64_CTRL_FIELDS)
    return result


class RV64Profile(V1Profile):
    cpu = "rv64"
    xlen = 64
    unpack_stage = staticmethod(unpack_stage)
    required = dict(V1Profile.required, pc_now=64, id_issue=261, issue_ex=389,
                    ex_mem=453, mem_wb=454, commit=454)
    # RV64 uses one memory transaction controller, without the v1 load/store FSMs.
    specs = {key: path for key, path in V1Profile.specs.items()
             if key not in ("load_state", "load_busy", "store_state", "store_busy")}
    specs.update({key: ".u_inst_engine.u_memory." + leaf for key, leaf in (
        ("memory_pending", "pending"), ("memory_mmu_started", "mmu_started"),
        ("memory_translated", "translated"), ("memory_byte_index", "byte_index"))})
    optional_widths = dict(V1Profile.optional_widths, **{key: 64 for key in (
        "arch_pc", "counter", "next_pc", "branch_target_pc", "seq_pc",
        "execute_alu_data", "operand_1", "operand_2", "div_quotient", "div_remainder",
        "mul_out", "load_read_data", "memory_alu_data", "memory_reg_data_1",
        "memory_reg_data_2", "data_mem_read_address", "data_mem_read_data",
        "data_mem_write_address", "data_mem_write_data")})

    def extra_detail(self, sample):
        return {label: sample.value(key) for label, key in (
            ("Memory pending", "memory_pending"), ("MMU started", "memory_mmu_started"),
            ("Translated", "memory_translated"), ("Byte index", "memory_byte_index"))}
