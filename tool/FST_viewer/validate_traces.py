"""Real-FST regression. Run after generating validation/{legacy,v1,v2}.fst.

--serve also serves each checked model, binding all three from port 8000 to
exercise occupied-port fallback using real listening sockets.
"""
import argparse
import json
import threading
from pathlib import Path
from fst_viewer import TraceModel, ViewerHandler, bind_server
from cpu_profiles.v1 import unpack_stage
from cpu_profiles.v2 import unpack, ROB_FIELDS


def verify(cpu):
    if cpu == 'v2':
        # Independent RTL read-port observations validate reconstructed p0–p31.
        from cpu_profiles.v2 import V2Profile
        for port in (1,2):
            for field in ('addr','data'):
                V2Profile.specs[f'check_read_{field}{port}'] = (
                    '.u_inst_engine.u_inst_unit.u_physical_register_file.'+f'read_{field}{port}')
    m=TraceModel(Path(__file__).parent/'validation'/f'{cpu}.fst')
    m.parse()
    assert m.profile.cpu==cpu
    assert m.instructions
    register_checks=0
    for s, values in zip(m.samples,m.register_samples):
        assert len(values)==32
        assert values[0] in (None,0)
        if cpu=='v2':
            for port in (1,2):
                addr=s.value(f'check_read_addr{port}')
                data=s.value(f'check_read_data{port}')
                if addr is not None and addr<32 and data is not None and values[addr] is not None:
                    assert values[addr]==data,(cpu,s.cycle,addr,values[addr],data)
                    register_checks+=1
        else:
            assert all(values[i]==s.value(f'x{i}') for i in range(32))
            register_checks+=32
    assert register_checks>0
    checked=0
    overlap=0
    for s in m.samples:
        if not any(t is not None for t in s.tokens): continue
        data=m.profile.stage_data(s)
        for token,p in zip(s.tokens,data):
            if token is not None:
                assert p is not None
                if cpu!='legacy' or s.value('legacy_state')!=0:
                    assert m.records[token].pc==p.get('pc',m.records[token].pc)
                checked+=1
        if cpu=='v2':
            overlap+=int(s.value('alu_active')==1 and s.value('md_active')==1)
            for i in range(2):
                r=unpack(s.value(f'rob{i}'),ROB_FIELDS)
                t=s.tokens[5+i]
                assert bool(r['valid'])==(t is not None)
                if t is not None: assert m.records[t].opcode==r['instruction']
    muls=[r for r in m.instructions if r.status=='retired' and r.decoded['mnemonic']=='mul']
    assert muls
    for r in muls:
        assert r.alu_result==(r.rs1_value*r.rs2_value)&0xffffffff,(cpu,r.to_dict())
        assert r.writeback_value==r.alu_result
    if cpu=='v1':
        assert (len(m.samples),len(m.instructions),checked)==(101922,1255,14877)
        assert sum(r.status=='retired' for r in m.instructions)==1047
        first=muls[0]
        assert first.stages['EXECUTE']==[90677,90680]
        assert m.cycle_detail(90678)['execution']['state']=='MUL_WAIT'
        assert m.cycle_detail(90678)['stages'][1]['alu_result'] is None
        assert m.cycle_detail(90680)['stages'][1]['alu_result']==2
        assert m.cycle_detail(90560)['memory']['read_valid']==1
        for r in m.instructions:
            if r.status=='retired':
                spans=list(r.stages.values())
                assert len(spans)==5
                assert all(a[1]+1==b[0] for a,b in zip(spans,spans[1:]))
    first=muls[0]
    assert m.search('pc',hex(first.pc),0,1)['pc']==first.pc
    assert m.search('mnemonic','mul',0,1)['mnemonic'].startswith('mul')
    assert any(r['id']==first.ident for r in m.instruction_query(first.start_cycle,first.end_cycle,'MUL',''))
    assert len(m.cycle_range(0,9999)['cycles'])==500
    report={'cpu':cpu,'cycles':len(m.samples),'instructions':len(m.instructions),
        'retired':sum(r.status=='retired' for r in m.instructions),'stage_pc_checks':checked,
        'mul_checks':len(muls),'register_checks':register_checks,'ALU_MD_overlap_cycles':overlap,'status':'PASS'}
    print(json.dumps(report),flush=True)
    return m


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--serve',action='store_true')
    args=parser.parse_args()
    servers=[]
    for cpu in ('legacy','v1','v2'):
        m=verify(cpu)
        if args.serve:
            handler=type(f'{cpu}Handler',(ViewerHandler,),{'model':m})
            server=bind_server('127.0.0.1',8000,handler)
            servers.append(server)
            threading.Thread(target=server.serve_forever,daemon=True).start()
            print(f'{cpu}: http://127.0.0.1:{server.server_port}/',flush=True)
    if servers:
        try: threading.Event().wait()
        except KeyboardInterrupt:
            for server in servers: server.shutdown();server.server_close()
