#!/usr/bin/env python3
"""Same full-controller wrapper/device/frequency/seeds for v1 and v2.
Artifacts are isolated. No production Makefile or source selection is changed.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE=Path(__file__).resolve().parents[1]
ROOT=BASE.parents[4]
SIM=ROOT/'PSC-ONE/hardware/sim'
WRAPPER=ROOT/'PSC-ONE/hardware/rtl/tang20k/timing/PSC_NPU_TimingTop.sv'
TOP='PSC_NPU_Timing'


def execute(command,log):
    with log.open('w') as out:
        subprocess.run(list(map(str,command)),stdout=out,stderr=subprocess.STDOUT,check=True)


def counts(path,top):
    cells=json.loads(path.read_text())['modules'][top]['cells']
    c=Counter(x['type'] for x in cells.values())
    return {'cells':dict(c),'LUT':sum(c[f'LUT{i}'] for i in range(1,5)),
            'FF':sum(v for k,v in c.items() if k.startswith('DFF')),
            'MUX':sum(v for k,v in c.items() if k.startswith('MUX2_LUT')),
            'ALU':c['ALU'],'MULT9X9':c['MULT9X9'],'MULT18X18':c['MULT18X18']}


def main():
    p=argparse.ArgumentParser();p.add_argument('--build',type=Path,required=True)
    p.add_argument('--seeds',type=int,nargs='+',default=[1,2,3])
    p.add_argument('--variants',nargs='+',choices=['v1','v2_4','v2_8','v2_16'],default=['v2_8'])
    a=p.parse_args();a.build=a.build.resolve();a.build.mkdir(parents=True,exist_ok=True)
    yosys=SIM/'yosys/build/yosys'
    result={'device':'GW2AR-LV18QN88C8/I7','family':'GW2A-18C','target_MHz':81,
            'yosys':subprocess.check_output([str(yosys),'-V'],text=True).strip(),
            'nextpnr':subprocess.check_output(['nextpnr-himbaechel','--version'],text=True,stderr=subprocess.STDOUT).strip(),
            'wrapper_sha256':hashlib.sha256(WRAPPER.read_bytes()).hexdigest(),'variants':{}}
    for variant in a.variants:
        build=a.build/variant;build.mkdir(parents=True,exist_ok=True)
        v2=variant!='v1';lanes=int(variant.split('_')[1]) if v2 else 4
        src=BASE/'src' if v2 else BASE.parent/'npu_v1/src'
        files=([src/name for name in ['PSC_NPU_AccBank.sv','PSC_NPU_Controller.v','PSC_NPU_MACScheduler.sv','PSC_NPU_PotLanes.sv','PSC_NPU_ReadController.v','PSC_NPU_SystolicArray4x4.v']] if v2 else sorted(src.glob('*.*v')))
        config=f'chparam -set LANES {lanes} PSC_NPU_Controller; ' if v2 else ''
        script='read_verilog -sv '+' '.join(map(str,[WRAPPER,*files]))+'; '+config+f'hierarchy -check -top {TOP}; flatten; synth_gowin -top {TOP} -family gw2a -json {build}/npu.json; stat'
        (build/'synth.ys').write_text(script+'\n')
        execute([yosys,'-s',build/'synth.ys'],build/'yosys.log')
        summary=counts(build/'npu.json',TOP)
        summary['source_sha256']={str(f.relative_to(ROOT)):hashlib.sha256(f.read_bytes()).hexdigest() for f in files}
        # Audit and synthesize the actual arithmetic module independently,
        # so controller address products cannot hide a data multiplier.
        arithmetic='PSC_NPU_PotLanes' if v2 else 'PSC_NPU_Mul4'
        arfile=src/(arithmetic+'.sv')
        cfg=f'chparam -set LANES {lanes} {arithmetic}; ' if v2 else ''
        audit=f'read_verilog -sv {arfile}; '+cfg+f'hierarchy -top {arithmetic}; proc; opt; write_json {build}/arithmetic_generic.json; synth_gowin -top {arithmetic} -family gw2a -json {build}/arithmetic.json; stat'
        (build/'arithmetic.ys').write_text(audit+'\n')
        execute([yosys,'-s',build/'arithmetic.ys'],build/'arithmetic.log')
        summary['arithmetic']=counts(build/'arithmetic.json',arithmetic)
        generic=json.loads((build/'arithmetic_generic.json').read_text())['modules'][arithmetic]['cells']
        types=Counter(c['type'] for c in generic.values())
        summary['arithmetic_generic_cells']=dict(types)
        if v2:
            assert not any(types[k] for k in ['$mul','$shl','$shr','$sshl','$sshr']), types
            assert not summary['arithmetic']['MULT9X9'] and not summary['arithmetic']['MULT18X18']
            selectors=[c for c in generic.values() if c['type']=='$pmux']
            assert len(selectors)==lanes
            assert all(int(c['parameters']['WIDTH'],2)==16 and
                       int(c['parameters']['S_WIDTH'],2)==8 for c in selectors)
        summary['pnr']=[]
        result['variants'][variant]=summary
        print(variant,'synth',json.dumps({k:summary[k] for k in ['LUT','FF','MUX','ALU','MULT9X9']}),flush=True)
        for seed in a.seeds:
            report=build/f'timing_seed{seed}.json';log=build/f'pnr_seed{seed}.log'
            command=['nextpnr-himbaechel','--json',build/'npu.json','--write',build/f'pnr_seed{seed}.json',
                     '--device',result['device'],'--vopt','family='+result['family'],
                     '--vopt','cst='+str(WRAPPER.with_suffix('.cst')),'--freq','81','--seed',seed,
                     '--timing-allow-fail','--report',report]
            execute(command,log)
            text=log.read_text()
            fmax=float(re.findall(r'Max frequency.*?: ([0-9.]+) MHz',text)[-1])
            delays=re.findall(r'([0-9.]+) ns logic, ([0-9.]+) ns routing',text)[-1]
            # Preserve full post-route critical path for source-level review.
            starts=[m.start() for m in re.finditer(r'Info: Critical path report for clock',text)]
            critical=text[starts[-1]:] if starts else ''
            end=critical.find('Info: Max frequency')
            if end>=0:critical=critical[:end]
            (build/f'critical_seed{seed}.txt').write_text(critical)
            item={'seed':seed,'fmax_MHz':fmax,'pass_81MHz':fmax>=81,
                  'logic_ns':float(delays[0]),'routing_ns':float(delays[1])}
            item['utilization']=json.loads(report.read_text())['utilization']
            summary['pnr'].append(item)
            (a.build/'synthesis_comparison.json').write_text(json.dumps(result,indent=2)+'\n')
            print(variant,item,flush=True)
    print('Artifacts:',a.build,flush=True)

if __name__=='__main__':main()
