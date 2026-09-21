#!/usr/bin/env python3
"""Isolated cocotb suite. Never invokes clean or changes production selection."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as ET
BASE=Path(__file__).resolve().parents[1]
ROOT=BASE.parents[4]
p=argparse.ArgumentParser()
p.add_argument('--build',type=Path,required=True)
p.add_argument('--vectors',type=Path,required=True)
p.add_argument('--lanes',type=int,nargs='+',default=[8],choices=[4,8,16])
p.add_argument('--case',nargs='+',default=['lanes','core','controller','bank','model_controller'])
a=p.parse_args();a.build=a.build.resolve();a.build.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,PATH=str(Path(sys.executable).parent)+':'+os.environ['PATH'],PYTHONPATH=str(BASE/'tests')+':'+str(BASE/'reference'),MODEL_VECTORS=str(a.vectors.resolve()))
mk=subprocess.check_output(['cocotb-config','--makefiles'],env=env,text=True).strip()+'/Makefile.sim'
src=BASE/'src';all_src=[src/name for name in ['PSC_NPU_AccBank.sv','PSC_NPU_Controller.v','PSC_NPU_MACScheduler.sv','PSC_NPU_PotLanes.sv','PSC_NPU_ReadController.v','PSC_NPU_SystolicArray4x4.v']]
result={}
for lanes in a.lanes:
    env['LANES']=str(lanes)
    for case,top,module,sources in [
        ('lanes','PSC_NPU_PotLanes','pot_lanes_test',[src/'PSC_NPU_PotLanes.sv']),
        ('core','CoreTop','core_test',all_src+[BASE/'tests/CoreTop.sv']),
        ('controller','PSC_NPU_Controller','controller_test',all_src),
        ('model_controller','PSC_NPU_Controller','model_controller_test',all_src),
        ('bank','PSC_NPU_AccBank','bank_test',[src/'PSC_NPU_AccBank.sv'])]:
        if case not in a.case:continue
        build=a.build/f'{case}{lanes}';build.mkdir(parents=True,exist_ok=True)
        env['NPU_CYCLE_RESULTS']=str(build/'cycles.json')
        cmd=['make','-f',mk,'SIM=icarus',f'TOPLEVEL={top}','TOPLEVEL_LANG=verilog',f'COCOTB_TEST_MODULES={module}',f'SIM_BUILD={build}',f'COCOTB_RESULTS_FILE={build}/results.xml','VERILOG_SOURCES='+' '.join(map(str,sources)),f'COMPILE_ARGS=-g2012 -DNPU_ASSERTIONS -P{top}.LANES={lanes}']
        with (build/'run.log').open('w') as log:
            subprocess.run(cmd,cwd=build,env=env,stdout=log,stderr=subprocess.STDOUT,check=True)
        xml=ET.parse(build/'results.xml').getroot()
        assert xml.findall('.//testcase') and not xml.findall('.//failure') and not xml.findall('.//skipped')
        result[f'{case}{lanes}']=len(xml.findall('.//testcase'))
        (a.build/'regression.json').write_text(json.dumps(result,indent=2)+'\n')
        print(case,lanes,'PASS',flush=True)
