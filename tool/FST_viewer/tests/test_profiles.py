import errno
import unittest
from types import SimpleNamespace
from fst_viewer import bind_server, ViewerHandler
from cpu_profiles import select_profile
from cpu_profiles.base import ViewerError, SignalInfo
from cpu_profiles.v1 import V1Profile
from cpu_profiles.legacy import LegacyProfile
from cpu_profiles.v2 import V2Profile, unpack, ROB_FIELDS, IQ_FIELDS


class ProfileTests(unittest.TestCase):
    def test_legacy_operands_only_after_register_read(self):
        values = dict(opcode=0x02b70733, arch_pc=0x88, legacy_state=2,
                      register_read1=544, register_read2=0, execute_done=1)
        sample = SimpleNamespace(value=values.get, tokens=[0]*10)
        self.assertIsNone(LegacyProfile().stage_data(sample)[0]['rs1_value'])
        self.assertIsNone(LegacyProfile().stage_data(sample)[0]['alu_result'])
        values.update(legacy_state=3, register_read1=1, register_read2=2)
        self.assertEqual(LegacyProfile().stage_data(sample)[0]['rs1_value'],1)

    def test_structural_detection(self):
        for cpu, leaf in (("legacy",".u_execute_state.execute_state"),
                          ("v1",".u_inst_engine.u_inst_unit.id_issue"),
                          ("v2",".u_inst_engine.u_inst_unit.rob_count")):
            self.assertEqual(select_profile({"top.core"+leaf:None}).cpu,cpu)
        with self.assertRaises(ViewerError):
            select_profile({})

    def test_wrong_width_is_rejected(self):
        for cls in (V1Profile,V2Profile):
            p=cls()
            paths={"top"+p.specs[k]:SignalInfo(w,"x", "top"+p.specs[k])
                   for k,w in p.required.items()}
            key="id_issue" if p.cpu=="v1" else "rob0"
            paths["top"+p.specs[key]].width-=1
            with self.assertRaisesRegex(ViewerError,"expected"):
                p.setup(SimpleNamespace(_paths=paths,signals={}))

    def test_v2_layout(self):
        self.assertEqual(sum(w for _,w in ROB_FIELDS),307)
        self.assertEqual(sum(w for _,w in IQ_FIELDS),80)
        # Bits independently located from the SV declarations.
        r=unpack((1<<306)|(1<<305)|(0x02c58533<<272)|(33<<103)|0x123,ROB_FIELDS)
        self.assertEqual(r['valid'],1)
        self.assertEqual(r['completed'],1)
        self.assertEqual(r['instruction'],0x02c58533)
        self.assertEqual(r['dest_phys'],33)
        self.assertEqual(r['exception_tval'],0x123)


class PortTests(unittest.TestCase):
    def test_occupied_ports_increment(self):
        calls=[]
        def server(address, handler):
            calls.append(address[1])
            if address[1]<8002:
                raise OSError(errno.EADDRINUSE,"occupied")
            return address
        self.assertEqual(bind_server('127.0.0.1',8000,ViewerHandler,server)[1],8002)
        self.assertEqual(calls,[8000,8001,8002])

    def test_other_errors_are_not_hidden(self):
        def server(*args): raise OSError(errno.EACCES,"denied")
        with self.assertRaises(OSError): bind_server('127.0.0.1',8000,ViewerHandler,server)

    def test_range_exhaustion(self):
        def server(*args): raise OSError(errno.EADDRINUSE,"occupied")
        with self.assertRaises(ViewerError): bind_server('127.0.0.1',65535,ViewerHandler,server)
        with self.assertRaises(ViewerError): bind_server('127.0.0.1',65536,ViewerHandler,server)
