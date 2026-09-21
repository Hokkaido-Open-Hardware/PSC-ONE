#!/usr/bin/env python3
"""Four-block comparison; preserve every original selector result."""
import argparse
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
p.add_argument('--v1-tests',type=Path,required=True)
p.add_argument('--horner8-area',type=Path,required=True)
p.add_argument('--horner16-area',type=Path,required=True)
p.add_argument('--serial-tests',type=Path,required=True)
p.add_argument('--output',type=Path,default=BASE/'results/selectorless')
a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
old=json.loads((BASE/'results/synthesis_comparison.json').read_text())
current=json.loads((a.timing/'synthesis_comparison.json').read_text())
assert set(current['variants'])=={'v1','v2_4'}
for key in ('device','family','target_MHz','yosys','nextpnr','wrapper_sha256'):
    assert old[key]==current[key], key
baseline_model=json.loads((BASE/'results/model_evaluation.json').read_text())
assert hashlib.sha256((ROOT/baseline_model['model']).read_bytes()).hexdigest()==baseline_model['sha256']
result={'conditions':{k:current[k] for k in ['device','family','target_MHz','yosys','nextpnr','wrapper_sha256']},
        'blocks':4,'model_sha256':baseline_model['sha256'],
        'designs':{'v1_4mul':current['variants']['v1'],
                   'selector_v2_4':old['variants']['v2_4'],
                   'horner_v2_4':current['variants']['v2_4']}}
for name,v in result['designs'].items():
    if name!='selector_v2_4':
        for path,digest in v['source_sha256'].items():
            assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,path
    assert len(v['pnr'])==3
    assert all(r['pass_81MHz'] for r in v['pnr'])
    v['median_fmax_MHz']=statistics.median(r['fmax_MHz'] for r in v['pnr'])
    for r in v['pnr']:
        seed=r['seed']
        if name!='selector_v2_4':
            variant='v1' if name=='v1_4mul' else 'v2_4'
            report=json.loads((a.timing/variant/f'timing_seed{seed}.json').read_text())
            r['utilization']=report['utilization']
            r['critical_path']=report['critical_paths'][0]
            text=(a.timing/variant/f'critical_seed{seed}.txt').read_text()
        else:
            text=(BASE/f'results/critical_v2_4_seed{seed}.txt').read_text()
        (a.output/f'critical_{name}_seed{seed}.txt').write_text(text)
result['candidate_synthesis']={}
for name,build in [('horner8',a.horner8_area),('horner16',a.horner16_area)]:
    v=json.loads((build/'synthesis_comparison.json').read_text())['variants']['v2_4']
    result['candidate_synthesis'][name]={k:v[k] for k in ['LUT','FF','ALU','MUX','MULT9X9','selector_audit','full_hierarchy_selector_audit']}
old_cycles=json.loads((BASE/'results/controller_cycles.json').read_text())
cycles={'v1_4mul':json.loads((a.v1_tests/'controller_cycles/cycles.json').read_text()),
        'selector_v2_4':old_cycles['v2_4'],
        'horner_v2_4':json.loads((a.tests/'controller4/cycles.json').read_text())}
assert cycles['v1_4mul']==old_cycles['v1']
result['controller_cycles']=cycles
checks={}
for label,build,filter4 in [('adopted_unit',a.tests,True),('adopted_full_model',a.model_tests,True),
                             ('v1_regression',a.v1_tests,False),('serial_candidate',a.serial_tests,True)]:
    rows=[]
    for xml in sorted(build.glob('*/results.xml')):
        if filter4 and not xml.parent.name.endswith('4'):continue
        root=ET.parse(xml).getroot()
        assert not root.findall('.//failure') and not root.findall('.//skipped')
        rows.extend(t.attrib for t in root.findall('.//testcase'))
    assert rows
    checks[label]={'PASS':len(rows),'FAIL':0,'SKIP':0,'tests':rows}
result['verification']=checks
result['adopted_model_samples']=262
result['adopted_model_channels']=5240
result['new_bottleneck']='snapshot -> context/coefficient/sign logic -> 17-bit Horner carry chain -> partial product register'
(a.output/'comparison_4lane.json').write_text(json.dumps(result,indent=2)+'\n')
lines=['## 追記：8:1 selector除去実験（4演算ブロックで比較）','',
       '以下が現在の採用RTL。上のselector方式の測定値は履歴としてそのまま保存した。',
       '主比較は **v1の4 MUL、旧v2の4 selector lane、新v2の4 Horner lane**。',
       '8/16 laneの旧表と混ぜない。新規npu_v3は作成せず、変更はnpu_v2配下に限定した。','',
       '### Python評価と方式選定','',
       'weight byteは変更せず、従来の8bit canonical codeをそのまま受け付ける。',
       '現在の符号化ではゼロ以外は2項を格納する。単一PoTも同指数2項や隣接指数差で表されるため、',
       '格納された項数と、数学的に簡約した最小項数の両方を集計した。','',
       '| 対象 | weight数 | 格納0/1/2項 | 簡約後0/1/2項 | exponent-majorの格納項数 | 簡約後項数 |',
       '|---|---:|---|---|---:|---:|']
study=json.loads((a.output/'exponent_study.json').read_text())
for name in ['all_INT8','unique_canonical','FC1','FC2','model_all']:
    d=study['datasets'][name]
    raw='/'.join(str(d['encoded_term_count'][str(k)]) for k in range(3))
    minimal='/'.join(str(d['minimal_term_count'][str(k)]) for k in range(3))
    lines.append(f"| {name} | {d['weights']} | {raw} | {minimal} | {d['exponent_major_raw_terms']} | {d['exponent_major_minimal_terms']} |")
lines+=['','並べ替えだけでは項数は減らない。簡約は別の変換であり採用RTLではencodingを変更しない。',
        'all_INT8は元の−128～127を各1回量子化した分布、unique_canonicalは重複codeを除いた88種類。','',
        '| exponent | 全INT8 positive | 全INT8 negative | 現モデル positive | 現モデル negative |',
        '|---|---:|---:|---:|---:|']
for k in range(8):
    x=study['datasets']['all_INT8']['raw_exponents'][k]
    y=study['datasets']['model_all']['raw_exponents'][k]
    lines.append(f"| {k} | {x['positive']} | {x['negative']} | {y['positive']} | {y['negative']} |")
lines+=['','モデルのzero weight率は22/320=6.875%。8-phase Hornerの寄与ゼロ率は77.578125%、',
        '全INT8では75.390625%。2項を別phaseにする16-phaseではskip率は各88.359375%/87.548828125%。',
        '**skipは加える寄与が0という意味で、clockを省略する意味ではない。**',
        'Hornerはその指数の寄与が0でも固定倍化を行う必要がある。',
        'モデルは指数0～3だけを使うが、採用実装はモデル依存にせず毎回7→0を走査する。','',
        '現在のweight encodingは8bitのまま。項ごとにvalidを追加すると10bit、簡約済みternary planeは16bit、',
        '未簡約の±2係数も含むplaneは24bit/weight。疎なFC1 bucketは少なくとも1項あたり',
        'sign 1 + input index 4 + output index 4 = 9bitが必要で、bucket pointer/countは別途必要。',
        '理想的な4 lane sparse発行は全INT8 131 cycles、FC1 121 cycles、FC2 32 cycles。',
        'これはdestination競合・転送・最終reduceを無視した下限で、今回の実装cycleではない。','',
        '| 案 | 追加状態・回路 | 判断 |','|---|---|---|',
        '| exponent別ACC | 16出力×8指数×32bit=4096bitの一時ACC、固定shift後のwide reduction | 状態量と最終加算が大きい |',
        '| 固定shift WB | 指数ごとの固定経路を並列に置くとwide出力選択/加算が必要。1bit反復ならcycle増 | selector移設を避けるため不採用 |',
        '| 既存ACC全体のHorner | 過去のK tileの累積値まで倍になる。全K再走査か退避ACCが必要 | Controller/read変更を避ける |',
        '| lane内Horner16 | 17bit部分積、1項ずつ±x/skip、feedbackのhold/double選択 | 合成して比較 |',
        '| lane内Horner8 | 17bit部分積、同指数を合算した0/±x/±2x、feedbackは常に固定倍化 | 4 laneで最小だったため採用 |','',
        '| 4 lane候補、Yosys合成 | LUT1–4計 | FF | MUX | ALU |',
        '|---|---:|---:|---:|---:|']
for name,v in result['candidate_synthesis'].items():
    lines.append(f"| {name} | {v['LUT']} | {v['FF']} | {v['MUX']} | {v['ALU']} |")
lines+=['','8 laneの予備検討後、ユーザー指定に従い4 laneで選定をやり直した。',
        '上表は4 laneの候補比較であり、全候補をFPGAで実測した最適解の主張ではない。',
        'SERIAL_TERMS=0（既定）が採用8-phase、=1が比較用16-phase。既定LANES=4。','',
        '### 採用構造とnetlist確認','',
        'Schedulerが各groupについてexponentを7→0へ進め、laneは指数一致を比較するだけ。',
        'coef_k = Σ(sign_t | shift_t == k)、p_next = 2*p + coef_k*x。',
        '同指数・同符号なら±2x、反対符号なら0になる。2xと2pはconstant concatenationで実装した。',
        '17bitの部分積はsigned/unsigned activationと全256 byte codeの範囲（最大±65280）を保持できる。',
        '最初の指数で部分積を0から開始し、exponent 0の完了後だけ既存32bit ACCへ加算する。',
        '16 ACCは変更せず、過去の積和を倍化しない。A/B転送・snapshot契約・MMIO・8bit weight codeも維持する。','',
        '| 16 MAC batch / 4 lane | v1 | 旧v2 selector | 新v2 Horner8 | 比較Horner16 |',
        '|---|---:|---:|---:|---:|',
        '| issue clocks | 4 | 8 | 32 | 64 |',
        '| start E0からdoneまで | 8 | 12 | 36 | 68 |',
        '| 最短start間隔 | 9 | 13 | 37 | 69 |',
        '| issue中のweight/clock | 4 | 2 | 0.5 | 0.25 |','',
        '新Horner8のWBはE10/E18/E26/E34、ACC更新はE11/E19/E27/E35、doneはE36。',
        'zero/clear/reset/back-to-backとbusy中のsnapshot保護を検証した。','',
        '合成前generic netlistとController全体をflattenしたnetlistを両方監査した。',
        '演算部の `$mul/$shl/$shr/$sshl/$sshr/$pmux` は全て0。',
        '旧版の16bit×8択 `$pmux` は消え、weightがshift済みactivationを選ぶ経路はない。',
        '残る `$shiftx` はA/B contextの4:1選択（入力幅32bit以下）に限る。',
        'merged係数にはx/固定2xの2:1選択が残るが、指数別8候補の選択ではない。',
        'Schedulerも監査し、ACC/ReadControllerはbaselineとbyte一致、Controller本体は',
        'compile-time parameter伝播以外一致を確認した。既存の16 ACC read選択などは残っているため、',
        '「NPU全体に大きなMUXが一切ない」という意味ではない。selectorの別階層への移設はない。','',
        '### 同条件nextpnr、4演算ブロック比較','',
        '既存wrapper/CST、GW2AR-LV18QN88C8/I7、GW2A-18C、81 MHz、seed 1/2/3。',
        'tool versionとwrapper hashも旧測定と一致。v1は今回再実行、旧v2は保存済み結果を使用した。',
        'LUTはseed 1、Fmaxは3 seed中央値。その他のresource数は3 seedで同一。','',
        '| 構成 | LUT4 | FF | MULT9X9 | MUX | ALU | Fmax中央値 MHz |',
        '|---|---:|---:|---:|---:|---:|---:|']
for name,v in result['designs'].items():
    u=v['pnr'][0]['utilization'];mux=sum(x['used'] for k,x in u.items() if k.startswith('MUX2_LUT'))
    lines.append(f"| {name} | {u['LUT4']['used']} | {u['DFF']['used']} | {u['MULT9X9']['used']} | {mux} | {u['ALU']['used']} | {v['median_fmax_MHz']:.2f} |")
lines+=['','MULT9X9はprimitive数。v1は演算4＋アドレス3、旧/新v2は演算0＋アドレス3。',
        'ALU/MUXは別resource種別であり、LUTと単純合算して面積とはしない。','',
        '| 構成 | Fmax seed 1 / 2 / 3 MHz | LUT4の範囲 | 最遅seed logic + routing ns |',
        '|---|---|---|---|']
for name,v in result['designs'].items():
    rows=v['pnr'];worst=min(rows,key=lambda x:x['fmax_MHz'])
    lut=[x['utilization']['LUT4']['used'] for x in rows]
    lines.append(f"| {name} | "+' / '.join(f"{x['fmax_MHz']:.2f}" for x in rows)+f" | {min(lut)}–{max(lut)} | {worst['logic_ns']:.2f} + {worst['routing_ns']:.2f} |")
lines+=['','新方式のcritical pathは snapshot → context/係数/符号処理 → **17bit Horner加算のcarry chain**',
        '→ 部分積レジスタ。旧shift selectorを除去しても、この直列経路が新しい律速になった。',
        '詳細な始点・終点・全段の遅延は比較JSONとcritical_*.txtに保存。','',
        '| X×Y / delay | v1 cycles / µs@81MHz | 旧v2 cycles / µs | 新Horner cycles / µs |',
        '|---|---:|---:|---:|']
for i,c in enumerate(cycles['v1_4mul']):
    fields=[f"{cycles[n][i]['cycles']} / {cycles[n][i]['cycles']/81:.3f}" for n in result['designs']]
    lines.append(f"| {c['x']}×{c['y']} / {c['delay']} (signed={c['signed']}) | "+' | '.join(fields)+' |')
lines+=['','新規6 run（v1/new各3 seed）は全て81 MHz制約PASS。旧v2の保存済み3 runもPASS。',
        'FmaxはNPU単体wrapperの推定値であり、SoC統合後や実機の保証周波数ではない。','',
        '### 判断','',
        '1. 8:1 activation shift selectorの除去: **達成**。他階層へ移していない。',
        '2. 旧v2からのLUT削減: **達成**。3482→2795（−19.7%）、MUX 841→119（−85.9%）。',
        '3. Fmax回復: **未達**。旧v2 129.43→新124.78 MHz、v1は202.72 MHz。',
        '4. throughputとの釣り合い: 4×4で旧v2の262→550 cycles（約2.10倍）。約20%のLUT削減に対して性能損失が大きい。',
        '5. v1への利点: 演算MULT9X9を4個空けられる。ただしLUT4は2769→2795とほぼ同じで、',
        '   4×4は214→550 cycles（約2.57倍）。DSPが特に不足する場合以外、置き換える明確な総合利点は確認できない。','',
        '追加の最適化は行わず、17bit Horner加算を新しいボトルネックとして記録する。',
        '電力は測定していない。実モデルの精度・実機・SoC統合は今回の結論の対象外。','',
        '### 検証・保存先','',
        'Pythonは全activation×全256 code×signed/unsigned×Horner2方式、262144比較PASS。',
        '採用4 laneの5 unit/Controller testcase＋TFLite全体1 testcase、v1回帰5 testcaseが全PASS。',
        '比較用Horner16も4 laneの網羅・core・Controller計4 testcaseがPASS。',
        'signed/unsigned、canonical全88 codeに加えて全256 code、各途中Horner値、±256復号値、',
        'ACC wrap、zero、reset全途中edge、clear、300回back-to-back、matrix/backpressureを含む。',
        'TFLiteは全262入力×20ch=5240 channelをController経由で実行し、',
        'FC1のRTL結果をrequantしてFC2へ渡し、全ACC/requant/output/argmaxがCPUと一致した。',
        'weight変換は旧方式と同じであり、現在の検証用モデルの最終出力も `[-36,27,18,8]`、class=1。',
        '学習済みモデルの分類精度を示す結果ではない。',
        'Verilator lintは終了コード0。既存Controllerの幅warningと定数parameter幅warningは残る。','',
        '旧ソース・README・測定結果42ファイルを `results/selector_baseline_source.tar.gz` に保存し、',
        '`selector_baseline_manifest.json` にSHA256を記録した。既存resultsのCSV/JSON/critical pathは上書きしていない。',
        '今回の詳細は `results/selectorless/`、full log/netlistは以下のbuild先。','',
        '```bash',
        'python3 PSC-ONE/hardware/rtl/soc/npu_v2/reference/exponent_schedule.py \\',
        '  --model-json /tmp/psc-npu-v2-model/model.json \\',
        '  --output PSC-ONE/hardware/rtl/soc/npu_v2/results/selectorless',
        'myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/tests/run.py \\',
        '  --build /tmp/psc-npu-v2-horner4-check --lanes 4 \\',
        '  --vectors /tmp/psc-npu-v2-model/rtl_vectors.json',
        'python3 PSC-ONE/hardware/rtl/soc/npu_v2/tests/synthesis.py \\',
        '  --build /tmp/psc-npu-v2-horner4-timing --variants v1 v2_4',
        '```','',
        'モデルJSON/CPU trace/vectorがない場合は `reference/evaluate_model.py` を',
        '旧READMEの手順で実行する。上のcheckは全採用testを同一buildにまとめて再実行する手順。',
        '今回の既存実行先はunit=`/tmp/psc-npu-v2-horner-tests`（主比較は末尾4のcase）、',
        'full model=`/tmp/psc-npu-v2-horner4-full-model`、v1=`/tmp/psc-npu-v2-horner4-v1-tests`、',
        '候補面積=`/tmp/psc-npu-v2-horner8-lane4-area`と`/tmp/psc-npu-v2-horner16-lane4-area`。',
        '4 laneへの指定前に走った8/16 laneのunit試験もPASSしたが、主比較の測定値には使用していない。',
        'netlist監査の初回エラーはYosysのescaped階層名の照合ミスであり、RTL不一致ではなかった。',
        '階層名を正規化して再合成・監査しPASSした。','',
        '変更: srcのPotLanes/MACScheduler/SystolicArray4x4/Controller、testsのCoreTop/core/pot_lanes/run/synthesis、README。',
        '新規: reference/exponent_schedule.py、tests/selectorless_report.py、baseline archive/manifest、results/selectorless。',
        '削除なし。npu/npu_v1、CPU、OS、SoC、既存Makefileは変更なし。Git add/commit/push等も未実施。','']
(a.output/'report_4lane.md').write_text('\n'.join(lines))
print('PASS: four-block report, baseline provenance, current source hashes and verification')
for n,v in result['designs'].items():
    print(n,'LUT4',v['pnr'][0]['utilization']['LUT4']['used'],'Fmax median',v['median_fmax_MHz'])
