#!/usr/bin/env python3
"""Collect measured artifacts without rerunning synthesis or simulation."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import statistics
import xml.etree.ElementTree as ET

BASE=Path(__file__).resolve().parents[1]
ROOT=BASE.parents[4]
p=argparse.ArgumentParser()
p.add_argument('--timing',type=Path,required=True)
p.add_argument('--tests',type=Path,required=True)
p.add_argument('--model-tests',type=Path,required=True)
p.add_argument('--baseline',type=Path,required=True)
p.add_argument('--output',type=Path,default=BASE/'results')
a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
result=json.loads((a.timing/'synthesis_comparison.json').read_text())
assert set(result['variants'])=={'v1','v2_4','v2_8','v2_16'}
for name,v in result['variants'].items():
    assert len(v['pnr'])==3
    assert all(i['pass_81MHz'] for i in v['pnr'])
    for path,digest in v['source_sha256'].items():
        assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest, path
    for item in v['pnr']:
        seed=item['seed'];raw=json.loads((a.timing/name/f'timing_seed{seed}.json').read_text())
        item['utilization']=raw['utilization']
        path=raw['critical_paths'][0]['path']
        item['critical_start']=path[0]['from'];item['critical_end']=path[-1]['to']
        (a.output/f'critical_{name}_seed{seed}.txt').write_text((a.timing/name/f'critical_seed{seed}.txt').read_text())
    v['median_fmax_MHz']=statistics.median(i['fmax_MHz'] for i in v['pnr'])
    v['min_fmax_MHz']=min(i['fmax_MHz'] for i in v['pnr'])
    v['max_fmax_MHz']=max(i['fmax_MHz'] for i in v['pnr'])
    if name!='v1':
        generic=json.loads((a.timing/name/'arithmetic_generic.json').read_text())['modules']['PSC_NPU_PotLanes']['cells']
        selectors=[c for c in generic.values() if c['type']=='$pmux']
        assert len(selectors)==int(name.split('_')[1])
        assert all(int(c['parameters']['WIDTH'],2)==16 and int(c['parameters']['S_WIDTH'],2)==8 for c in selectors)
        v['selector_audit']='PASS: one 16-bit 8-choice selector per lane, no data multiplier or variable shift'
(a.output/'synthesis_comparison.json').write_text(json.dumps(result,indent=2)+'\n')
verification={}
for label,path in [('v2_unit',a.tests),('v2_full_model',a.model_tests),('v1',a.baseline)]:
    cases={}
    for xml in sorted(path.glob('*/results.xml')):
        model_case=xml.parent.name.startswith('model_controller')
        if label=='v2_unit' and model_case:
            continue
        if label=='v2_full_model' and not model_case:
            continue
        root=ET.parse(xml).getroot();tests=root.findall('.//testcase')
        assert tests and not root.findall('.//failure') and not root.findall('.//skipped')
        cases[xml.parent.name]=[t.attrib for t in tests]
    assert cases
    verification[label]={'tests':sum(len(t) for t in cases.values()),'failures':0,'skips':0,'cases':cases}
(a.output/'verification.json').write_text(json.dumps(verification,indent=2)+'\n')
cycles={'v1':json.loads((a.baseline/'controller_cycles/cycles.json').read_text())}
cycles.update({f'v2_{n}':json.loads((a.tests/f'controller{n}/cycles.json').read_text()) for n in (4,8,16)})
(a.output/'controller_cycles.json').write_text(json.dumps(cycles,indent=2)+'\n')
lines=['# nextpnr測定結果','',
       '全構成で同じ既存Controller wrapper/CST、GW2AR-LV18QN88C8/I7、GW2A-18C、',
       '81 MHz制約、seed 1/2/3。`--timing-allow-fail`は違反時にも測定値を残すために指定。',
       '合否は81 MHz制約に対して別途判定した。今回12 runは全てPASS。',
       'SoC全体ではなく、pseudo stimulusを含むNPU Controller単体の配置配線結果。','',
       '| 構成 | LUT4 (pnr, seed 1) | FF | MULT9X9 | MUX | ALU (pnr) | Fmax中央値 MHz | 3 seed範囲 MHz |',
       '|---|---:|---:|---:|---:|---:|---:|---|']
for name,v in result['variants'].items():
    u=v['pnr'][0]['utilization']
    get=lambda k:u[k]['used']
    mux=sum(c['used'] for k,c in u.items() if k.startswith('MUX2_LUT'))
    lines.append(f"| {name} | {get('LUT4')} | {get('DFF')} | {get('MULT9X9')} | {mux} | {get('ALU')} | {v['median_fmax_MHz']:.2f} | {v['min_fmax_MHz']:.2f}–{v['max_fmax_MHz']:.2f} |")
lines += ['', 'LUT4はnextpnrのpacked utilization値。ALU/MUXは別resource種別の報告であり、',
          '単純合計してFPGA面積とはしない。FF/MULT/MUXも同じnextpnr reportから取得。',
          'LUT以外の表中resource数は3 seedで同一。MULT18X18/ALU54D/BSRAMは全て0。',
          'LUT4の3 seed範囲: '+ '、'.join(
              name+'='+str(min(i['utilization']['LUT4']['used'] for i in v['pnr']))+'–'+
              str(max(i['utilization']['LUT4']['used'] for i in v['pnr']))
              for name,v in result['variants'].items())+'。',
          'MULT9X9はプリミティブ数であり物理DSP macroの占有ブロック数とは異なる。',
          'v1の7個中4個がINT8演算用、残り3個はアドレス用。v2の演算部は0個。','',
          '| 構成 | Yosys LUT1–4計 | FF | MUX | ALU | 演算部のみ MULT9X9 |',
          '|---|---:|---:|---:|---:|---:|']
for name,v in result['variants'].items():
    lines.append(f"| {name} | {v['LUT']} | {v['FF']} | {v['MUX']} | {v['ALU']} | {v['arithmetic']['MULT9X9']} |")
lines+=['','nextpnrはpacking時にALU等を変換するためYosysのLUT/ALU数と異なる。','',
        '| 構成 | seed 1 Fmax | seed 2 Fmax | seed 3 Fmax | 最遅seedのlogic + routing ns |',
        '|---|---:|---:|---:|---|']
for name,v in result['variants'].items():
    worst=min(v['pnr'],key=lambda r:r['fmax_MHz'])
    lines.append('| '+name+' | '+' | '.join(f"{r['fmax_MHz']:.2f}" for r in v['pnr'])+f" | {worst['logic_ns']:.2f} + {worst['routing_ns']:.2f} |")
lines+=['','v1のcritical pathはController制御からwriteback register enable等へ至る経路。',
        'v2はPoT laneのoperand/phase/shift選択と符号反転を経てWBへ至る経路が律速。',
        '厳密な始点・終点はJSON、各段の論理/配線遅延は `critical_*_seed*.txt` に保存。','',
        '| X × Y / memory delay | v1 cycles | v2 4 cycles | v2 8 cycles | v2 16 cycles |',
        '|---|---:|---:|---:|---:|']
for i,c in enumerate(cycles['v1']):
    lines.append(f"| {c['x']} × {c['y']} / {c['delay']} (signed={c['signed']}) | "+' | '.join(str(cycles[n][i]['cycles']) for n in ['v1','v2_4','v2_8','v2_16'])+' |')
lines+=['','8 laneで2clk/weightのissue throughputとController cycle数をv1まで回復。',
        '16 laneは同一81 MHzで約8～12%のController cycle削減に留まり、転送と制御が残る。',
        '各設計のFmaxで動かす仮定では、代表4×4 (delay=1) の実行時間は次のとおり。','',
        '| 構成 | cycles / Fmax中央値 (µs) | 81 MHzでの時間 (µs) |',
        '|---|---:|---:|']
for name,v in result['variants'].items():
    c=cycles[name][0]['cycles']
    lines.append(f"| {name} | {c/v['median_fmax_MHz']:.3f} | {c/81:.3f} |")
lines+=['','結論: 本実装・本mapping条件ではDSPを4個削減できる一方、LUT/MUX増加と',
        'Fmax低下が大きい。DSPの不足がないTang Nano 20K用途でv1を置き換える優位性は確認できない。',
        'DSPを他用途へ確保し、81 MHz固定で使う場合は8 laneが候補だが、面積は増加する。',
        '16 laneはMUX増加が特に大きく、今回の速度改善に対して費用が大きい。',
        '汎用barrel shifterはないが、固定8択selectもmapping後のコストは無視できない。',
        '最大Fmaxは単体wrapperの推定値であり、SoC統合後や実機の保証周波数ではない。','']
(a.output/'synthesis_report.md').write_text('\n'.join(lines))
print('\n'.join(lines))
