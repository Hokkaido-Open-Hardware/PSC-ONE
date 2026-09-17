import unittest
from cpu_profiles.base import BaseProfile
from cpu_profiles.v2 import V2Profile
from fst_viewer import TraceModel
from pathlib import Path


class RegisterTests(unittest.TestCase):
    def test_direct_array_and_missing_values(self):
        values = BaseProfile().register_values({'x0':0, 'x31':0xffffffff}, {}, None)
        self.assertEqual(len(values),32)
        self.assertEqual(values[31],0xffffffff)
        self.assertIsNone(values[1])

    def test_v2_pre_edge_write_and_stop(self):
        p=V2Profile()
        pre={'reg_reset_n':1,'reg_cpu_stop':0,'reg_wb_valid':1,'reg_wb_addr':14,'reg_wb_data':2}
        current=dict(pre,reg_wb_data=999)
        values=p.register_values(current,pre,(0,)*32)
        self.assertEqual(values[14],2)
        self.assertEqual(p.register_values(current,dict(pre,reg_cpu_stop=1),values),(0,)*32)
        self.assertEqual(p.register_values(dict(current,reg_reset_n=0),pre,values),(0,)*32)

    def test_v2_unknown_and_speculative_write(self):
        p=V2Profile()
        self.assertEqual(p.register_values({}, {}, None),(0,)+(None,)*31)
        pre={'reg_reset_n':1,'reg_cpu_stop':0,'reg_wb_valid':1,'reg_wb_addr':32,'reg_wb_data':7}
        self.assertEqual(p.register_values(pre,pre,(0,)*32),(0,)*32)
        pre['reg_wb_addr']=None
        self.assertEqual(p.register_values(pre,pre,(0,)*32),(0,)+(None,)*31)

    def test_history_and_changed_flag(self):
        m=TraceModel(Path('not-read.fst'))
        m.profile=BaseProfile()
        m.register_samples=[(0,)*32,(0,7)+(0,)*30]
        self.assertEqual(m.register_detail(0)['values'][1]['value'],0)
        self.assertTrue(m.register_detail(1)['values'][1]['changed'])
        self.assertFalse(m.register_detail(1)['values'][0]['changed'])
