#!/usr/bin/env python3
"""Isolated NPU regression/timing runs; never invokes a clean target."""
import argparse
from collections import Counter
import json
import os
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET

SIM = Path(__file__).resolve().parents[2]
ROOT = SIM.parents[2]


def execute(command, log, cwd=None, env=None):
    with log.open('w') as output:
        subprocess.run([str(x) for x in command], cwd=cwd, env=env,
                       stdout=output, stderr=subprocess.STDOUT, check=True)


def regression(args):
    env = dict(os.environ, PYTHONPATH=str(SIM),
               PATH=str(ROOT/'myenv/bin')+':'+os.environ['PATH'])
    makefile = subprocess.check_output(['cocotb-config','--makefiles'], env=env,
                                      text=True).strip()+'/Makefile.sim'
    src = args.src
    legacy = src if args.baseline else SIM.parent/'rtl/soc/npu/src'
    pe = [legacy/n for n in ['PSC_NPU_PE_INT.sv','PSC_NPU_PE_Mult.sv','PSC_NPU_PE_SimTop.v']]
    sa = [src/'PSC_NPU_SystolicArray4x4.v']
    if not args.baseline:
        sa += [src/n for n in ['PSC_NPU_MACScheduler.sv','PSC_NPU_Mul4.sv','PSC_NPU_AccBank.sv']]
    else:
        sa += pe
    ctrl = sa + [src/'PSC_NPU_Controller.v',src/'PSC_NPU_ReadController.v']
    cases = [
        ('pe','PSC_NPU_PE_SimTop','int8_PE_test',pe,''),
        ('sa2','PSC_NPU_SystolicArray2x2','int8_SA_test',pe+[legacy/'PSC_NPU_SystolicArray2x2.v'],''),
        ('sa4','PSC_NPU_SystolicArray4x4','int8_SA_4x4_test',sa,
         '-PPSC_NPU_SystolicArray4x4.MUL_NUM=4' if args.baseline else ''),
        ('controller','PSC_NPU_Controller','int8_SA_Ctrl_test',ctrl,''),
        ('sa_contract','PSC_NPU_SystolicArray4x4','streaming_acc_test',sa,
         '-PPSC_NPU_SystolicArray4x4.MUL_NUM=4' if args.baseline else ''),
        ('controller_cycles','PSC_NPU_Controller','streaming_controller_test',ctrl,''),
    ]
    legacy_ctrl = pe + [legacy/'PSC_NPU_ReadController.v',
                       legacy/'PSC_NPU_Controller.v',legacy/'PSC_NPU_SystolicArray4x4.v']
    cases.append(('legacy_controller1','PSC_NPU_Controller','int8_SA_Ctrl_test',
                  legacy_ctrl,'-PPSC_NPU_Controller.MUL_NUM=1'))
    if not args.baseline:
        cases += [
            ('acc_bank','PSC_NPU_AccBank','streaming_bank_test',[src/'PSC_NPU_AccBank.sv'],''),
            ('mul4','PSC_NPU_Mul4','streaming_mul_test',[src/'PSC_NPU_Mul4.sv'],''),
        ]
    result = {}
    for name, top, test, sources, params in cases:
        if args.case and name not in args.case.split(','):
            continue
        build = args.build/name
        build.mkdir(parents=True, exist_ok=True)
        env['NPU_BASELINE'] = str(int(args.baseline))
        env['NPU_CYCLE_RESULTS'] = str(build/'cycles.json')
        cmd = ['make','-f',makefile,'SIM=icarus','TOPLEVEL_LANG=verilog',
               f'TOPLEVEL={top}',f'COCOTB_TEST_MODULES=cocotb_tb.npu.{test}',
               f'SIM_BUILD={build}',f'COCOTB_RESULTS_FILE={build}/results.xml',
               'VERILOG_SOURCES='+' '.join(str(p) for p in sources),
               'COMPILE_ARGS=-g2012 -DNPU_ASSERTIONS '+params]
        execute(cmd, build/'run.log', cwd=build, env=env)
        xml = ET.parse(build/'results.xml').getroot()
        assert not xml.findall('.//failure') and not xml.findall('.//skipped'), name
        result[name] = len(xml.findall('.//testcase'))
        print(name, result[name], 'PASS', flush=True)
    (args.build/'regression.json').write_text(json.dumps(result,indent=2)+'\n')


def timing(args):
    wrapper = SIM.parent/'rtl/tang20k/timing/PSC_NPU_TimingTop.sv'
    cst = wrapper.with_suffix('.cst')
    datapath = ['PSC_NPU_PE_INT.sv','PSC_NPU_PE_Mult.sv'] if args.baseline else [
        'PSC_NPU_MACScheduler.sv','PSC_NPU_Mul4.sv','PSC_NPU_AccBank.sv']
    sources = [wrapper]+[args.src/n for n in [
        'PSC_NPU_Controller.v','PSC_NPU_ReadController.v','PSC_NPU_SystolicArray4x4.v',*datapath]]
    output = args.build/'npu.json'
    script = ('read_verilog -sv '+' '.join(str(p) for p in sources)+'; '
              'hierarchy -check -top PSC_NPU_Timing; flatten; '
              f'synth_gowin -top PSC_NPU_Timing -family gw2a -json {output}; stat')
    (args.build/'synth.ys').write_text(script+'\n')
    execute([SIM/'yosys/build/yosys','-s',args.build/'synth.ys'],args.build/'yosys.log')
    cells = json.loads(output.read_text())['modules']['PSC_NPU_Timing']['cells']
    counts = Counter(c['type'] for c in cells.values())
    result = {'cells':dict(counts), 'LUT':sum(counts[f'LUT{i}'] for i in range(1,5)),
              'FF':sum(v for k,v in counts.items() if k.startswith('DFF')),
              'ALU':counts['ALU'], 'MUX':sum(counts[f'MUX2_LUT{i}'] for i in range(5,9)),
              'MULT9X9':counts['MULT9X9'], 'pnr':[]}
    for seed in (1,2,3):
        routed = args.build/f'pnr_seed{seed}.json'
        log = args.build/f'pnr_seed{seed}.log'
        execute(['nextpnr-himbaechel','--json',output,'--write',routed,
                 '--device','GW2AR-LV18QN88C8/I7','--vopt','family=GW2A-18C',
                 '--vopt',f'cst={cst}','--freq','81','--seed',seed,
                 '--report',args.build/f'timing_seed{seed}.json'],log)
        wires,pips = set(),set()
        nets = json.loads(routed.read_text())['modules']['top']['netnames']
        for net in nets.values():
            text = net.get('attributes',{}).get('ROUTING','').strip()
            if text:
                parts = text.split(';'); assert len(parts)%3 == 0
                wires.update(parts[0::3]); pips.update(p for p in parts[1::3] if p)
        text = log.read_text()
        result['pnr'].append({'seed':seed,'wires':len(wires),'pips':len(pips),
            'fmax_MHz':float(re.findall(r'Max frequency.*?: ([0-9.]+) MHz',text)[-1]),
            'logic_routing_ns':re.findall(r'([0-9.]+) ns logic, ([0-9.]+) ns routing',text)[-1]})
    (args.build/'timing_summary.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result),flush=True)


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--src',type=Path)
    parser.add_argument('--build',type=Path,required=True)
    parser.add_argument('--baseline',action='store_true')
    parser.add_argument('--timing',action='store_true')
    parser.add_argument('--case')
    args=parser.parse_args()
    default_src = SIM.parent/'rtl/soc'/('npu' if args.baseline else 'npu_v1')/'src'
    args.src=(args.src or default_src).resolve();args.build=args.build.resolve()
    args.build.mkdir(parents=True,exist_ok=True)
    timing(args) if args.timing else regression(args)
