"""Legacy Verilog FSM; pipeline_type is tied low in the inspected RTL."""
from .base import BaseProfile, ViewerError
from .v1 import V1Profile


class LegacyProfile(BaseProfile):
    register_bank = ".u_execute_state.u_regfile.registers.registers[{i}]"
    cpu = "legacy"
    model = "FSM"
    anchor = ".u_execute_state.execute_state"
    fsm = dict(enumerate(("IDLE", "FIFO_READ", "DECODE", "EXECUTE", "BRANCH_MMU",
                         "BRANCH_MMU_W", "BRANCH", "STORE_MMU", "STORE_MMU_W", "STORE")))
    stage_names = ("CURRENT", "DECODE", "EXECUTE", "BRANCH_MMU", "BRANCH_MMU_W",
                   "BRANCH", "STORE_MMU", "STORE_MMU_W", "STORE", "COMMIT")
    state_maps = dict(BaseProfile.state_maps,
        execute_state=dict(enumerate(("IDLE","ALU","ALU_DONE","ALU_DIV_WAIT",
                                     "ALU_DIV_DONE","ALU_MUL_WAIT","ALU_DONE_WAIT"))),
        load_state=dict(enumerate(("IDLE","BRANCH","BRANCH_WAIT","BRANCH_DONE","BRANCH_DONE_WAIT"))),
        store_state=dict(enumerate(("IDLE","STORE","STORE_WAIT","STORE_DONE","STORE_DONE_WAIT"))))
    required = {"clock":1,"reset_n":1,"cpu_stop":1,"legacy_state":4,
                "opcode":32,"arch_pc":32,"decode_done":1,"decode_enb":1,
                "pipeline_mode":1,"r_addr1":5,"r_addr2":5,"w_addr":5}
    specs = {}
    optional_widths = {"execute_state":4,"divider_state":4,"multiplier_state":2,
                       "load_state":4,"store_state":4,"cpu_state":4}

    def setup(self, m):
        super().setup(m)
        self.current = None

    def sample(self, m, timestamp, pre):
        v = m._current
        c = len(m.samples)
        state = v.get("legacy_state")
        if v.get("pipeline_mode") == 1:
            raise ViewerError("legacy: enabled pipeline_mode is not the verified FSM configuration")
        if v.get("reset_n") != 1 or v.get("cpu_stop") == 1:
            self.current = None
        elif (self.current is None and pre.get("decode_enb") == 1 and
              v.get("decode_done") == 1 and pre.get("opcode") is not None):
            self.current = m._new_record(pre["arch_pc"], pre["opcode"], c)
        tokens = [None]*len(self.stage_names)
        if self.current is not None:
            record = m.records[self.current]
            tokens[0] = self.current
            name = self.fsm.get(state)
            if name in self.stage_names:
                tokens[self.stage_names.index(name)] = self.current
            if state == 0 and pre.get("legacy_state") == 9:
                tokens[-1] = self.current
                record.status = "retired"
            for row, token in zip(self.stage_names, tokens):
                if token is not None:
                    record.touch(row, c, None)
            if state == 3 and pre.get("legacy_state") != 3:
                # The legacy MUL/DIV path does not update Execute.r_data1/2.
                # Capture the actual register read ports before writeback instead.
                record.rs1_value = v.get("register_read1")
                record.rs2_value = v.get("register_read2")
            if state >= 4:
                record.alu_result = v.get("execute_alu_data")
            if tokens[-1] is not None:
                record.writeback_value = pre.get("w_data")
                record.branch_taken = pre.get("branch_taken_now")
                self.current = None
        self.append(m, timestamp, tokens)

    def stage_data(self, sample):
        v = sample.value
        ctrl = {k:v(k) for k in ("r_addr1","r_addr2","w_addr","rf_wen","alucon","funct3")}
        # Register-use semantics come from the decoded instruction, not the unused encoding bits.
        from riscv_decoder import decode
        d = decode(v("opcode") or 0, v("arch_pc") or 0)
        ctrl.update(use_rs1=d.rs1 is not None,use_rs2=d.rs2 is not None)
        ready = (v("legacy_state") or 0) >= 4
        reading = v("legacy_state") == 3
        data = {"pc":v("arch_pc"),"ctrl":ctrl,"rs1_value":v("register_read1") if reading else None,
                "rs2_value":v("register_read2") if reading else None,"alu_result":v("execute_alu_data") if ready else None,
                "writeback_value":v("w_data") if v("legacy_state") == 9 else None,
                "branch_taken":v("branch_taken_now")}
        return [data if t is not None else None for t in sample.tokens]

    def extra_detail(self, sample):
        return {"FSM":self.fsm.get(sample.value("legacy_state"),"—"),
                "Next FSM":self.fsm.get(sample.value("legacy_next_state"),"—"),
                "pipeline_mode":sample.value("pipeline_mode")}


E = ".u_execute_state"
LegacyProfile.specs = {k:E+"."+k for k in (
    "clock","reset_n","cpu_stop","opcode","decode_done","r_addr1","r_addr2","w_addr",
    "r_data1","r_data2","rf_wen","alucon","funct3","pipeline_mode","w_data")}
for key, suffix in V1Profile.specs.items():
    if suffix.startswith(".u_inst_engine.") and key.startswith("data_mem_"):
        LegacyProfile.specs[key] = E+"."+key
for key in ("cpu_state","counter","next_pc","branch_target_pc","seq_pc","timer_irq_take","i_pf"):
    LegacyProfile.specs[key] = "."+key
LegacyProfile.specs.update({
    "arch_pc":E+".pc","pc_now":E+".pc","legacy_state":E+".execute_state",
    "legacy_next_state":E+".next_state","decode_enb":E+".u_decorder.decode_enb",
    "execute_done":E+".alu_done","execute_alu_data":E+".alu_data",
    "memory_alu_data":E+".alu_data","load_valid":E+".u_branch.branch_enb",
    "load_done":E+".branch_done","store_valid":E+".u_memory_store.store_enb",
    "store_done":E+".store_done","mem_write_sel":E+".mem_write_sel",
    "branch_taken_now":E+".pc_sel2","fifo_flush":E+".fifo_flush_sig",
    "load_state":E+".u_branch.state","store_state":E+".u_memory_store.state",
    "operand_1":E+".u_execute.s_data1_w","operand_2":E+".u_execute.s_data2_w",
    "register_read1":E+".u_execute.r_data1_w","register_read2":E+".u_execute.r_data2_w",
    "execute_state":E+".u_execute.state","divider_state":E+".u_execute.u_divider.state",
    "divider_count":E+".u_execute.u_divider.count",
    "multiplier_state":E+".u_execute.u_multiplexer.state"})
for key in ("mul_start","mul_busy","mul_done","mul_out","div_start","div_busy","div_done","div_quotient","div_remainder"):
    LegacyProfile.specs[key] = E+".u_execute."+key
