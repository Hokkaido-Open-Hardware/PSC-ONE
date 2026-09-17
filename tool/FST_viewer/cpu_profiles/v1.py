"""Verified cpu_v1 valid/ready pipeline profile."""
from .base import BaseProfile, CycleSample, unpack_ctrl, ViewerError

SIGNAL_SPECS = {
    "clock": ("unit", "clock"),
    "reset_n": ("unit", "reset_n"),
    "cpu_stop": ("unit", "cpu_stop"),
    "cpu_trap": ("unit", "cpu_trap"),
    "arch_pc": ("unit", "pc"),
    "counter": ("unit", "counter"),
    "opcode": ("unit", "opcode"),
    "pc_now": ("unit", "pc_now"),
    "fifo_req_ready": ("unit", "fifo_req_ready"),
    "fifo_read_ready": ("unit", "fifo_read_ready"),
    "fifo_read_valid": ("unit", "fifo_read_valid"),
    "fifo_flush": ("unit", "fifo_flush"),
    "decode_enb": ("unit", "decode_enb"),
    "decode_done": ("unit", "decode_done"),
    "decode_fire": ("unit", "decode_fire"),
    "issue_fire": ("unit", "issue_fire"),
    "ex_fire": ("unit", "ex_fire"),
    "mem_fire": ("unit", "mem_fire"),
    "raw_hazard": ("unit", "raw_hazard"),
    "raw_hazard_rs1": ("unit", "raw_hazard_rs1"),
    "raw_hazard_rs2": ("unit", "raw_hazard_rs2"),
    "forward_sel_rs1": ("unit", "forward_sel_rs1"),
    "forward_sel_rs2": ("unit", "forward_sel_rs2"),
    "backend_serial": ("unit", "backend_serial"),
    "pipeline_empty": ("unit", "pipeline_empty"),
    "execute_task_busy": ("unit", "execute_task_busy"),
    "execute_task_done": ("unit", "execute_task_done"),
    "memory_complete": ("unit", "memory_complete"),
    "branch_taken_now": ("unit", "branch_taken_now"),
    "early_branch_valid": ("unit", "early_branch_valid"),
    "commit_branch_taken": ("unit", "commit_branch_taken"),
    "timer_irq_take": ("unit", "timer_irq_take"),
    "d_pf": ("unit", "d_pf"),
    "i_pf": ("unit", "i_pf"),
    "id_issue": ("unit", "id_issue"),
    "issue_ex": ("unit", "issue_ex"),
    "ex_mem": ("unit", "ex_mem"),
    "mem_wb": ("unit", "mem_wb"),
    "commit": ("unit", "commit"),
    "next_pc": ("pc", "next_pc"),
    "branch_target_pc": ("pc", "branch_target_pc"),
    "seq_pc": ("pc", "seq_pc"),
    "cpu_state": ("core", "cpu_state"),
    "fetch_valid": ("core", "fetch_valid"),
    "fetch_ready": ("core", "fetch_ready"),
    "execute_state": ("execute", "state"),
    "execute_busy": ("execute", "busy"),
    "execute_done": ("execute", "done"),
    "execute_alu_data": ("execute", "alu_data"),
    "operand_1": ("execute", "operand_1"),
    "operand_2": ("execute", "operand_2"),
    "is_div_op": ("execute", "is_div_op"),
    "is_mul_op": ("execute", "is_mul_op"),
    "div_start": ("execute", "div_start"),
    "div_busy": ("execute", "div_busy"),
    "div_done": ("execute", "div_done"),
    "div_quotient": ("execute", "div_quotient"),
    "div_remainder": ("execute", "div_remainder"),
    "mul_start": ("execute", "mul_start"),
    "mul_busy": ("execute", "mul_busy"),
    "mul_done": ("execute", "mul_done"),
    "mul_out": ("execute", "mul_out"),
    "divider_state": ("divider", "state"),
    "divider_count": ("divider", "count"),
    "multiplier_state": ("multiplier", "state"),
    "load_valid": ("engine", "load_valid"),
    "load_done": ("engine", "load_done"),
    "load_read_data": ("engine", "load_read_data"),
    "store_valid": ("engine", "store_valid"),
    "store_done": ("engine", "store_done"),
    "memory_alu_data": ("engine", "memory_alu_data"),
    "memory_reg_data_1": ("engine", "memory_reg_data_1"),
    "memory_reg_data_2": ("engine", "memory_reg_data_2"),
    "data_mem_read_valid": ("engine", "data_mem_read_valid"),
    "data_mem_read_ready": ("engine", "data_mem_read_ready"),
    "data_mem_read_address": ("engine", "data_mem_read_address"),
    "data_mem_read_data": ("engine", "data_mem_read_data"),
    "data_mem_req_ready": ("engine", "data_mem_req_ready"),
    "data_mem_write_valid": ("engine", "data_mem_write_valid"),
    "data_mem_write_ready": ("engine", "data_mem_write_ready"),
    "data_mem_write_address": ("engine", "data_mem_write_address"),
    "data_mem_write_data": ("engine", "data_mem_write_data"),
    "mem_write_sel": ("engine", "mem_write_sel"),
    "load_state": ("load", "state"),
    "load_busy": ("load", "busy"),
    "store_state": ("store", "state"),
    "store_busy": ("store", "busy"),
}

def unpack_stage(raw: int | None, name: str) -> dict | None:
    if raw is None:
        return None
    if name == "id_issue":
        return {"valid": (raw >> 162) & 1, "ctrl": unpack_ctrl((raw >> 32) & ((1 << 130) - 1)),
                "pc": raw & 0xFFFF_FFFF}
    if name == "issue_ex":
        return {"valid": (raw >> 226) & 1, "ctrl": unpack_ctrl((raw >> 96) & ((1 << 130) - 1)),
                "pc": (raw >> 64) & 0xFFFF_FFFF, "rs1_value": (raw >> 32) & 0xFFFF_FFFF,
                "rs2_value": raw & 0xFFFF_FFFF}
    if name == "ex_mem":
        return {"valid": (raw >> 258) & 1, "ctrl": unpack_ctrl((raw >> 128) & ((1 << 130) - 1)),
                "pc": (raw >> 96) & 0xFFFF_FFFF, "rs1_value": (raw >> 64) & 0xFFFF_FFFF,
                "rs2_value": (raw >> 32) & 0xFFFF_FFFF, "alu_result": raw & 0xFFFF_FFFF}
    shift = 129
    return {"valid": (raw >> 259) & 1, "ctrl": unpack_ctrl((raw >> shift) & ((1 << 130) - 1)),
            "pc": (raw >> 97) & 0xFFFF_FFFF, "rs1_value": (raw >> 65) & 0xFFFF_FFFF,
            "alu_result": (raw >> 33) & 0xFFFF_FFFF, "branch_taken": (raw >> 32) & 1,
            "writeback_value": raw & 0xFFFF_FFFF}



STAGE_NAMES = ("ID / ISSUE", "EXECUTE", "MEMORY", "WRITEBACK", "COMMIT")
class V1Profile(BaseProfile):
    register_bank = ".u_inst_engine.u_inst_unit.u_regfile.registers.registers[{i}]"
    cpu = "v1"
    model = "pipeline"
    anchor = ".u_inst_engine.u_inst_unit.id_issue"
    stage_names = STAGE_NAMES
    stage_keys = ("id_issue", "issue_ex", "ex_mem", "mem_wb", "commit")
    bases = {"unit":".u_inst_engine.u_inst_unit","engine":".u_inst_engine","core":"",
             "pc":".u_inst_engine.u_inst_unit.u_PSC_PC","execute":".u_inst_engine.u_execute",
             "divider":".u_inst_engine.u_execute.u_divider",
             "multiplier":".u_inst_engine.u_execute.u_multiplier",
             "load":".u_inst_engine.u_load","store":".u_inst_engine.u_store"}
    required = {"clock":1,"reset_n":1,"cpu_stop":1,"opcode":32,"pc_now":32,
        "id_issue":163,"issue_ex":227,"ex_mem":259,"mem_wb":260,"commit":260,
        "decode_fire":1,"issue_fire":1,"ex_fire":1,"mem_fire":1,"fifo_flush":1}
    specs = {}
    optional_widths = {"execute_state":2,"divider_state":3,"multiplier_state":2,
                       "load_state":4,"store_state":3,"cpu_state":4}

    def stage_data(self, sample):
        stages = [unpack_stage(sample.value(k), k) for k in self.stage_keys]
        if stages[1]:
            stages[1]["alu_result"] = sample.value("execute_alu_data") if sample.value("execute_done") == 1 else None
        return stages

    def sample(self, m, timestamp: int, pre: dict[str, int | None]) -> None:
        cycle = len(m.samples)
        post_stages = [unpack_stage(m._current.get(key), key)
                       for key in ("id_issue", "issue_ex", "ex_mem", "mem_wb", "commit")]
        pre_stages = [unpack_stage(pre.get(key), key)
                      for key in ("id_issue", "issue_ex", "ex_mem", "mem_wb", "commit")]
        old = m._stage_tokens
        decode_fire = pre.get("decode_fire") == 1
        issue_fire = pre.get("issue_fire") == 1
        ex_fire = pre.get("ex_fire") == 1
        mem_fire = pre.get("mem_fire") == 1

        new_token = None
        if (decode_fire and m._valid(post_stages[0]) and
                pre.get("reset_n") == 1 and not pre.get("cpu_stop") and
                not pre.get("fifo_flush") and
                pre.get("pc_now") is not None and pre.get("opcode") is not None):
            new_token = m._new_record(pre["pc_now"], pre["opcode"], cycle)
        candidates = [
            new_token if decode_fire else (None if issue_fire else old[0]),
            old[0] if issue_fire else (None if ex_fire else old[1]),
            old[1] if ex_fire else (None if mem_fire else old[2]),
            old[2] if mem_fire else None,
            old[3] if m._valid(pre_stages[3]) else None,
        ]
        for index, stage in enumerate(post_stages):
            if not m._valid(stage):
                candidates[index] = None
                continue
            assert stage is not None
            token = candidates[index]
            if token is None or m.records[token].pc != stage["pc"]:
                token = m._recover_token(stage["pc"], cycle)
                candidates[index] = token
            m.records[token].touch(STAGE_NAMES[index], cycle, stage)

        m._stage_tokens = candidates
        values = tuple(m._current.get(key) for key in m.sample_keys)
        m.samples.append(CycleSample(cycle, timestamp * m.time_factor_fs,
                                        values, tuple(candidates), m.key_indices))
        if cycle and cycle % 25_000 == 0:
            print(f"  parsed {cycle:,} clock cycles...", flush=True)


V1Profile.specs = {k: V1Profile.bases[b]+"."+leaf for k,(b,leaf) in SIGNAL_SPECS.items()}
