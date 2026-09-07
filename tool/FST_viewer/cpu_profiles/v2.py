"""Two-entry ROB/IQ, rename and independent ALU/MUL-DIV lanes.

Layouts: cpu_v2_experimental/src/PSC_InstructionUnit.sv rob_entry_t/iq_entry_t.
Validated against the generated v2 FST (307/80 bits), not v1 payloads.
"""
from .base import BaseProfile, ViewerError, unpack_ctrl
from .v1 import V1Profile

ROB_FIELDS = (("valid",1),("completed",1),("address_ready",1),("instruction",32),
    ("ctrl",130),("side_effect_value",32),("dest_valid",1),("dest_phys",6),
    ("result",32),("branch_taken",1),("branch_target",32),("exception_valid",1),
    ("exception_cause",5),("exception_tval",32))
IQ_FIELDS = (("valid",1),("rob_tag",1),("src1_ready",1),("src1_value",32),
    ("src1_tag",6),("src2_ready",1),("src2_value",32),("src2_tag",6))


def unpack(raw, fields):
    if raw is None:
        return None
    result = {}
    pos = sum(w for _,w in fields)
    for k,w in fields:
        pos -= w
        result[k] = (raw >> pos) & ((1 << w)-1)
    if "ctrl" in result:
        result["ctrl"] = unpack_ctrl(result["ctrl"])
        result["pc"] = result["ctrl"]["out_pc"]
        result["writeback_value"] = result["result"] if result["completed"] else None
        result["alu_result"] = result["result"] if result["completed"] or result["address_ready"] else None
    return result


class V2Profile(BaseProfile):
    register_source = "Reconstructed architectural bank (PRF p0–p31, reset / WB3)"

    def register_values(self, current, pre, previous):
        values = list(previous or ((0,) + (None,)*31))
        # p1–p31 are updated only by WB3; p32/p33 are speculative.
        # Sample pre-edge inputs, not the combinational values after the edge.
        if current.get("reg_reset_n") == 0 or pre.get("reg_reset_n") == 0 or pre.get("reg_cpu_stop") == 1:
            return (0,)*32
        if pre.get("reg_reset_n") != 1 or pre.get("reg_cpu_stop") != 0:
            return (0,) + (None,)*31
        valid, addr = pre.get("reg_wb_valid"), pre.get("reg_wb_addr")
        if valid != 0:
            if addr is None:
                values[1:] = [None]*31
            elif 0 < addr < 32:
                values[addr] = pre.get("reg_wb_data") if valid == 1 else None
        values[0] = 0
        return tuple(values)
    cpu = "v2"
    model = "experimental OoO / scheduler"
    anchor = ".u_inst_engine.u_inst_unit.rob_count"
    stage_names = ("DECODE / RENAME", "IQ 0", "IQ 1", "ALU EXECUTE", "MUL / DIV",
                   "ROB 0", "ROB 1", "MEMORY HEAD", "COMMIT")
    specs = {}
    optional_widths = dict(V1Profile.optional_widths)
    required = {"clock":1,"reset_n":1,"cpu_stop":1,"cpu_trap":1,
        "ROB_DEPTH":32,"IQ_DEPTH":32,"PRF_DEPTH":32,
        "rob0":307,"rob1":307,"iq0":80,"iq1":80,
        "rob_head":1,"rob_tail":1,"rob_count":2,"dispatch_fire":1,
        "decode_stage_valid":1,"decode_stage_opcode":32,"decode_stage_ctrl":130,
        "decode_capture_fire":1,"alu_active":1,"md_active":1,
        "alu_active_rob_tag":1,"md_active_rob_tag":1,"commit_fire":1,
        "alu_active_ctrl":130,"md_active_ctrl":130,
        "alu_active_src1":32,"alu_active_src2":32,"md_active_src1":32,"md_active_src2":32,
        "alu_execute_data":32,"md_execute_data":32,"alu_wb_valid":1,"md_wb_valid":1}

    def setup(self, m):
        super().setup(m)
        self.rename = None
        self.rob_tokens = [None,None]

    def sample(self, m, timestamp, pre):
        v = m._current
        c = len(m.samples)
        for key, expected in (("ROB_DEPTH",2),("IQ_DEPTH",2),("PRF_DEPTH",34)):
            if v.get(key) is not None and v[key] != expected:
                raise ViewerError(f"v2: unsupported {key}={v[key]}, expected {expected}")
        old_rename = self.rename
        robs = [unpack(v.get(f"rob{i}"),ROB_FIELDS) for i in range(2)]
        if v.get("reset_n") != 1 or v.get("cpu_stop") == 1:
            self.rename = None
            self.rob_tokens = [None,None]
        else:
            if pre.get("dispatch_fire") == 1:
                slot = pre["rob_tail"]
                self.rob_tokens[slot] = old_rename
            if v.get("decode_stage_valid") != 1:
                self.rename = None
            elif pre.get("decode_capture_fire") == 1 or self.rename is None:
                ctrl = unpack_ctrl(v.get("decode_stage_ctrl"))
                self.rename = m._new_record(ctrl["out_pc"],v["decode_stage_opcode"],c)
            for i, rob in enumerate(robs):
                if not rob or not rob["valid"]:
                    self.rob_tokens[i] = None
                    continue
                token = self.rob_tokens[i]
                if token is None:
                    self.rob_tokens[i] = m._new_record(rob["pc"],rob["instruction"],c)
                else:
                    record = m.records[token]
                    if record.pc != rob["pc"] or record.opcode != rob["instruction"]:
                        raise ViewerError(f"v2: ROB identity mismatch at cycle {c}, slot {i}")

        iq_tokens = []
        for i in range(2):
            q = unpack(v.get(f"iq{i}"),IQ_FIELDS)
            iq_tokens.append(self.rob_tokens[q["rob_tag"]] if q and q["valid"] else None)
        lane_tokens = [self.rob_tokens[v[f"{lane}_active_rob_tag"]]
                       if v.get(f"{lane}_active") == 1 else None for lane in ("alu","md")]
        head = v.get("rob_head") or 0
        memory = self.rob_tokens[head] if v.get("load_valid") or v.get("store_valid") else None
        commit = self.rob_tokens[head] if v.get("commit_fire") else None
        tokens = [self.rename,*iq_tokens,*lane_tokens,*self.rob_tokens,memory,commit]
        self.append(m,timestamp,tokens)
        sample = m.samples[-1]
        for name, token, data in zip(self.stage_names,tokens,self.stage_data(sample)):
            if token is not None:
                # Unknown fields must not erase already captured operand values.
                m.records[token].touch(name,c,{k:x for k,x in (data or {}).items() if x is not None})

    def stage_data(self,sample):
        v = sample.value
        robs = [unpack(v(f"rob{i}"),ROB_FIELDS) for i in range(2)]
        ctrl = unpack_ctrl(v("decode_stage_ctrl"))
        rename = {"pc":ctrl["out_pc"],"ctrl":ctrl}
        queues = []
        for i in range(2):
            q = unpack(v(f"iq{i}"),IQ_FIELDS)
            if q and q["valid"] and robs[q["rob_tag"]]:
                queues.append(dict(robs[q["rob_tag"]],
                    rs1_value=q["src1_value"] if q["src1_ready"] else None,
                    rs2_value=q["src2_value"] if q["src2_ready"] else None))
            else:
                queues.append(None)
        lanes = []
        for lane in ("alu","md"):
            ctrl = unpack_ctrl(v(f"{lane}_active_ctrl"))
            lanes.append({"pc":ctrl["out_pc"],"ctrl":ctrl,
                "rs1_value":v(f"{lane}_active_src1"),"rs2_value":v(f"{lane}_active_src2"),
                "alu_result":v(f"{lane}_execute_data") if v(f"{lane}_wb_valid") else None})
        head = robs[v("rob_head") or 0]
        commit = dict(head,writeback_value=v("commit_result")) if head else None
        return [rename,*queues,*lanes,*robs,head,commit]

    def extra_detail(self,sample):
        v=sample.value
        result = {k:v(k) for k in ("rob_head","rob_tail","rob_count","dispatch_fire",
            "rob_full","dispatch_blocked","alu_select_valid","md_select_valid","commit_fire",
            "rat_spec_valid","alloc_phys","free_list","alu_active_dest_phys","md_active_dest_phys")}
        for i in range(2):
            rob=unpack(v(f"rob{i}"),ROB_FIELDS)
            q=unpack(v(f"iq{i}"),IQ_FIELDS)
            if rob:
                result[f"ROB {i} valid / completed / phys"] = f"{rob['valid']} / {rob['completed']} / p{rob['dest_phys']}"
            if q:
                result[f"IQ {i} ready rs1 / rs2"] = f"{q['src1_ready']} / {q['src2_ready']}"
        return result


U = ".u_inst_engine.u_inst_unit."
V2Profile.specs = {k:s.replace(".u_execute.",".u_execute_mul_div.") for k,s in V1Profile.specs.items()
                  if k not in ("id_issue","issue_ex","ex_mem","mem_wb","commit")}
for k in set(V2Profile.required)|{"rob_full","dispatch_blocked","alu_select_valid","md_select_valid",
    "rat_spec_valid","alloc_phys","free_list","alu_active_dest_phys","md_active_dest_phys",
    "commit_result","load_valid","store_valid"}:
    V2Profile.specs[k] = U+k
for i in range(2):
    V2Profile.specs[f"rob{i}"] = U+f"rob.rob[{i}]"
    V2Profile.specs[f"iq{i}"] = U+f"iq.iq[{i}]"
# Normalize common flow names only where the RTL has a corresponding real signal.
V2Profile.specs.update(decode_fire=U+"decode_capture_fire",issue_fire=U+"dispatch_fire",
    backend_serial=U+"dispatch_blocked",early_branch_valid=U+"branch_redirect")
for key, signal, width in (("reset_n","reset_n",1),("cpu_stop","cpu_stop",1),
                           ("wb_valid","wb3_valid",1),("wb_addr","wb3_addr",6),
                           ("wb_data","wb3_data",32)):
    V2Profile.specs["reg_"+key] = U+"u_physical_register_file."+signal
    V2Profile.optional_widths["reg_"+key] = width
