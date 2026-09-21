#!/usr/bin/env python3
"""Collect measured shared8 results without overwriting previous experiments."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import shutil
import statistics
import xml.etree.ElementTree as ET

BASE = Path(__file__).resolve().parents[1]


def read(path):
    return json.loads(path.read_text())


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def verify(build):
    cases = [c for p in sorted(build.rglob('results.xml'))
             for c in ET.parse(p).getroot().findall('.//testcase')]
    assert cases and not any(c.findall('failure') or c.findall('skipped') for c in cases)
    return {'PASS': len(cases), 'FAIL': 0, 'SKIP': 0,
            'tests': [c.attrib for c in cases]}


def resources(design):
    u = design['pnr'][0]['utilization']
    return [u['LUT4']['used'], u['DFF']['used'], u['MULT9X9']['used'],
            sum(v['used'] for n, v in u.items() if n.startswith('MUX2_LUT')),
            u['ALU']['used']]


def median(design):
    return statistics.median(p['fmax_MHz'] for p in design['pnr'])


def table(designs):
    lines = ['| Architecture | LUT4 | FF | MULT9X9 | MUX | ALU | Fmax median MHz |',
             '|---|---:|---:|---:|---:|---:|---:|']
    for name, d in designs.items():
        lines.append('| ' + name + ' | ' + ' | '.join(map(str, resources(d)))
                     + f' | {median(d):.2f} |')
    return lines


def cone_audit(build):
    m = read(build/'npu.json')['modules']['PSC_NPU_Timing']
    cells = m['cells']
    driver = {bit: name for name, c in cells.items()
              for port, bits in c['connections'].items()
              if c['port_directions'][port] == 'output'
              for bit in bits if isinstance(bit, int)}
    # Locate the product-register always block in the current source.
    lines = (BASE/'src/PSC_NPU_PotLanes.sv').read_text().splitlines()
    line = next(i+1 for i, s in enumerate(lines)
                if 'always @(posedge clock' in s and i > 30)
    source = f'PSC_NPU_PotLanes.sv:{line}.'
    regs = [c for c in cells.values() if c['type'].startswith('DFF')
            and source in c.get('attributes', {}).get('src', '')]
    assert len(regs) == 8*17
    seen = set()

    def visit(bit):
        name = driver.get(bit)
        if name is None or name in seen:
            return
        c = cells[name]
        if c['type'].startswith('DFF'):
            return
        seen.add(name)
        for port, bits in c['connections'].items():
            if c['port_directions'][port] == 'input':
                for b in bits:
                    visit(b)

    for r in regs:
        for b in r['connections']['D']:
            visit(b)
    counts = Counter(cells[n]['type'] for n in seen)
    return {'scope': 'union of combinational D-input cones of all 136 product FFs; stop at other FFs',
            'stage': 'Yosys mapped, before nextpnr packing', 'product_FF': len(regs),
            'cells': dict(counts), 'LUT': sum(v for n, v in counts.items() if n.startswith('LUT')),
            'MUX': sum(v for n, v in counts.items() if n.startswith('MUX2_LUT')),
            'ALU': counts['ALU']}


def main():
    p = argparse.ArgumentParser()
    for name in ['main-build', 'unit-build', 'tests', 'v1-tests', 'batch-tests']:
        p.add_argument('--'+name, type=Path, required=True)
    p.add_argument('--lint', type=Path, required=True)
    a = p.parse_args()
    out = BASE/'results/shared8'
    out.mkdir(parents=True, exist_ok=True)
    current = read(a.main_build/'synthesis_comparison.json')
    unit = read(a.unit_build/'synthesis_comparison.json')
    old = read(BASE/'results/synthesis_comparison.json')
    horner = read(BASE/'results/selectorless/comparison_4lane.json')
    for key in ['device', 'family', 'target_MHz', 'yosys', 'nextpnr', 'wrapper_sha256']:
        assert current[key] == unit[key] == old[key] == horner['conditions'][key], key
    assert current['cst_sha256'] == unit['cst_sha256']
    for d in [*current['variants'].values(), *unit['variants'].values()]:
        assert [x['seed'] for x in d['pnr']] == [1, 2, 3]
    for path, expected in current['variants']['v1']['source_sha256'].items():
        assert hashlib.sha256((BASE.parents[4]/path).read_bytes()).hexdigest() == expected
    archived = read(BASE/'results/horner_baseline_manifest.json')
    preserved = {n: h for n, h in archived.items() if n.startswith('results/')}
    assert all(hashlib.sha256((BASE/n).read_bytes()).hexdigest() == h for n, h in preserved.items())
    designs = {'npu_v1 4 MUL': current['variants']['v1'],
               'old v2 selector 4': old['variants']['v2_4'],
               'old v2 selector 8': old['variants']['v2_8'],
               'v2 Horner 4': horner['designs']['horner_v2_4'],
               'new v2 Shared ShiftAdd 8': current['variants']['shared8']}
    arithmetic = {'4 x 9x9 MUL (*)': unit['variants']['mul4'],
                  '4 x 2-Term ShiftAdd': unit['variants']['shiftadd4'],
                  '8 x 2-Term ShiftAdd': unit['variants']['shiftadd8']}
    cycles = dict(horner['controller_cycles'])
    cycles['shared8'] = read(a.tests/'controller8/cycles.json')
    assert cycles['v1_4mul'] == read(a.v1_tests/'controller_cycles/cycles.json')
    batch = read(a.batch_tests/'core8/cycles.json')
    hier = read(a.main_build/'shared8/hierarchy.json')['modules']
    muxes = {name: [{'type': c['type'],
                    'width': int(c['parameters'].get('WIDTH', '0'), 2),
                    'select_width': int(c['parameters'].get('S_WIDTH', '0'), 2)}
                   for c in m.get('cells', {}).values() if c['type'] in ['$mux', '$pmux', '$shiftx']]
             for name, m in hier.items()}
    read_mux = [c for c in muxes['PSC_NPU_AccReadMux'] if c['type'] == '$pmux']
    assert len(read_mux) == 5 and all(c['width'] == 32 and c['select_width'] == 4 for c in read_mux)
    audit = {'packed_read': current['variants']['shared8']['packed_read_audit'],
             'block': current['variants']['shared8']['block_audit'],
             'physical_shiftadd_instances': current['variants']['shared8']['shiftadd_instances'],
             'hierarchical_muxes': muxes, 'product_cones': cone_audit(a.main_build/'shared8')}
    endpoint_sources = {}
    for variant, d in current['variants'].items():
        cells = read(a.main_build/variant/'npu.json')['modules']['PSC_NPU_Timing']['cells']
        endpoint_sources[variant] = []
        for run in d['pnr']:
            path = run['critical_path']['path']
            endpoint_sources[variant].append({'seed': run['seed'],
                'start': cells.get(path[0]['from']['cell'], {}).get('attributes', {}).get('src'),
                'end': cells.get(path[-1]['to']['cell'], {}).get('attributes', {}).get('src')})
    audit['critical_endpoint_sources'] = endpoint_sources
    verification = {'new_v2': verify(a.tests), 'v1': verify(a.v1_tests),
                    'batch_measurement': verify(a.batch_tests),
                    'preserved_baseline_result_files': len(preserved),
                    'verilator': 'exit 0; three pre-existing Controller width warnings'}
    timing_limitation = {
        'nextpnr_commit': 'dec04b3b',
        'finding': 'Gowin create_timing_info defines no MULT9X9 timing variant; unknown cell timing is TMG_IGNORE. Raw mul4 wrapper Fmax is stimulus-to-CE, not multiplier Fmax.',
        'effect': 'Do not interpret mul4 871 MHz as usable DSP frequency. Full-NPU Fmax also excludes address/arithmetic DSP internal arcs.',
        'source_files': {str(f): hashlib.sha256(f.read_bytes()).hexdigest() for f in [
            Path('/home/haruhiko/nextpnr/himbaechel/uarch/gowin/gowin_arch_gen.py'),
            Path('/home/haruhiko/nextpnr/himbaechel/arch.cc')]}}
    write(out/'comparison.json', {'conditions': {k: v for k, v in current.items() if k != 'variants'},
        'designs': designs, 'arithmetic': arithmetic, 'controller_cycles': cycles,
        'batch_timing': batch, 'verification': verification, 'netlist_audit': audit,
        'timing_model_limitation': timing_limitation})
    write(out/'netlist_audit.json', audit)
    write(out/'verification.json', verification)
    write(out/'timing_model_audit.json', timing_limitation)
    shutil.copyfile(a.lint, out/'verilator_lint.txt')
    for root, variants in [(a.main_build, current['variants']), (a.unit_build, unit['variants'])]:
        for name in variants:
            for seed in [1, 2, 3]:
                shutil.copyfile(root/name/f'critical_seed{seed}.txt', out/f'critical_{name}_seed{seed}.txt')
    lines = ['## 追記：16 PE / Shared 2-Term ShiftAdd ×8 と固定スライス設計', '',
        '現在のRTLはこの方式。旧selector/Hornerの測定値とソースarchiveは保存している。', '',
        '隣接PE (0,1), (2,3), …, (14,15) が各1個の `PSC_NPU_ShiftAdd2` を共有する。',
        '独立した組合せ演算moduleを8個だけ生成し、even/oddの2クロックで16 PEを処理する。',
        '各weightの2項は同じクロック内で選択・符号処理・加算し、17bit productをWBへ登録する。',
        'AccBankは従来の32bit加算・wrap・clear契約を保ち、接続だけをentry/2の固定laneにした。',
        'LANESは現実装では8のみ。旧方式の4/16指定は保存したarchiveのコードで再現する。', '',
        '### NPU全体の設計方針と監査', '',
        '**巨大なpacked vectorを可変indexで読まない。** packed bus自体は接続表現として使用し、',
        'part-selectのindexはgenvar/localparamによる合成時定数に限定する。', '',
        '| 箇所 | 現在の構造 |', '|---|---|',
        '| Controller A/B投入 | 既存caseによる固定byte slice。最大7択の32bit出力を維持 |',
        '| ReadController | read_idxのcaseで128bitの固定32bit区画へ書く |',
        '| A/B context | 4×4の隣接接続をgenvarで固定 |',
        '| PE共有 | 各laneの固定2 PEだけを8bit 2:1選択。全16 PEを動的検索しない |',
        '| ShiftAdd | 16bit固定shift候補をcase選択×2。17bit積を同一cycleで完成 |',
        '| WB/AccBank | lane、ACC ID、32bit sliceを固定。演算をACC内部に埋め込まない |',
        '| ACC読出し | 512bit可変part-selectを廃止。32bit 4:1×4 → 32bit 4:1 |', '',
        '新しい `PSC_NPU_AccReadMux` は組合せ回路でlatencyを増やさない。ID 0..15は従来通り、',
        '未定義だった16..63は0を返す。Controllerは0..15のみ使用する。assertionのindexもgenvar化した。',
        'Controller全体のgeneric netlistで `$shiftx=0`、可変shift=0を確認。ACC readは幅32・4択の',
        '`$pmux`が5個。ShiftAddは1個あたり幅16・8択が2個で、barrel shifterや乗算器、内部状態はない。',
        '固定スライス化はMUXそのものの廃止ではない。今回の直接2項方式ではweight-controlled shift選択を',
        '明示的に使用する。合成後は複数の選択条件が結合され、大きなMUX構造も残る。', '',
        '### 検証', '',
        f'新v2 {verification["new_v2"]["PASS"]} testcase、v1回帰 {verification["v1"]["PASS"]} testcaseは全PASS（FAIL/SKIP=0）。',
        '独立演算器で256 activation ×256 code × signed/unsigned = 131072組を全数比較。',
        '共有laneも同じ全数を検証し、全shift/sign/zero/±256復号weightとUINT8 255を含む。',
        'even/odd WB ID、reset途中全edge、clear優先、300回back-to-back、ACC wrap、行列/backpressureを検証した。',
        '全64 ACC read IDもrandom 32bit値で確認。Verilator lintは終了コード0、既存Controller幅warningが3件。',
        'TFLiteの262入力×20ch=5240出力はFC1/FC2のraw ACC・bias補正・requant・最終outputでCPU referenceと全一致。',
        'argmax一致262/262、demo最終出力[-36,27,18,8]、class=1。Python/実CPU比較も再実行した。',
        '現行モデルは全320weightがPoTで誤差0のfixtureであり、一般の学習済みモデルの精度保証ではない。', '',
        '### 同条件nextpnr比較', '',
        'GW2AR-LV18QN88C8/I7、GW2A-18C、81 MHz、seed 1/2/3。既存NPU wrapper/CST・tool versionを一致確認。',
        'v1/new v2と演算器単体3構成を新規実行（計15 run）。旧selector/Hornerは保存済み同条件結果。',
        'resourceはnextpnr seed 1、Fmaxは3 seed中央値。MUXはMUX2_LUT5..8の合計。', '',
        *table(designs), '',
        '全体のMULT9X9はv1=演算4＋アドレス3、新旧v2=演算0＋アドレス3。',
        'DSP macroの占有数ではなくprimitive数。ALU/MUX/LUTを単純合計して面積とはしない。', '',
        *table(arithmetic), '',
        '演算器単体は共通の登録済み入力/出力wrapperと同じCSTで測定。Controller/Scheduler/PE共有/AccBankは含まない。',
        '共通128bit stimulusと入出力FFは含むため、裸の組合せ回路の面積ではない。',
        '**(*) 4 MULの871 MHzは乗算器のFmaxとして使用できない。** このnextpnr版のGowin timing生成には',
        'MULT9X9のtiming arcがなく、未定義cellはtimingから除外される。実際の報告経路はstimulus→入力FF CE。',
        '全体のFmaxもDSP内部遅延を含まない制約がある。数値は比較条件を保持したnextpnrの報告値で、',
        'DSPを含む回路の実機動作周波数を保証しない。根拠とソースhashはtiming_model_audit.jsonに記録。', '',
        '### critical pathとseed差', '',
        '| Architecture | seed | Fmax MHz | logic ns | routing ns | LUT4 |',
        '|---|---:|---:|---:|---:|---:|']
    for name, d in {**designs, **arithmetic}.items():
        for run in d['pnr']:
            lines.append(f'| {name} | {run["seed"]} | {run["fmax_MHz"]:.2f} | {run["logic_ns"]:.3f} | {run["routing_ns"]:.3f} | {run["utilization"]["LUT4"]["used"]} |')
    lines += ['', 'logicはclk-to-Qとsetupを含み、routingと合計すると報告critical periodになる。',
              '端点のRTL sourceと全経路はnetlist_audit.json、comparison.json、critical_*.txtを参照。', '',
              '### cyclesと81 MHz性能', '',
              '| 構成 | issue clocks/16 PE | start→done | 最短次start | issue weight/clk | batch weight/clk |',
              '|---|---:|---:|---:|---:|---:|',
              '| v1 4 MUL | 4 | 8 | 9 | 4 | 1.778 |',
              '| old selector 4 | 8 | 12 | 13 | 2 | 1.231 |',
              '| old selector 8 | 4 | 8 | 9 | 4 | 1.778 |',
              '| Horner 4 | 32 | 36 | 37 | 0.5 | 0.432 |',
              '| new Shared ShiftAdd 8 | 2 | 6 | 7 | 8 | 2.286 |', '',
              '新v2はE0 start、E2 snapshot、E3 even WB、E4 even ACC/odd WB、E5 odd ACC、E6 done、E7次start。',
              '300 batchの実測はbatch_timingに保存。batch weight/clkは16/最短start間隔で、メモリ転送を含まない。', '',
              '| X×Y / signed / delay | v1 cycles / µs | selector4 cycles / µs | Horner4 cycles / µs | Shared8 cycles / µs |',
              '|---|---:|---:|---:|---:|']
    for i, r in enumerate(cycles['shared8']):
        vals = [cycles[key][i]['cycles'] for key in ['v1_4mul', 'selector_v2_4', 'horner_v2_4', 'shared8']]
        lines.append(f'| {r["x"]}×{r["y"]} / {r["signed"]} / {r["delay"]} | '+
                     ' | '.join(f'{v} / {v/81:.3f}' for v in vals)+' |')
    lines += ['', 'X/YはControllerのdimension。A=Y×X、B=X×Y、C=Y×Yであり、仕事量はX×Y² MAC。',
              'delay=5では固定パターンのrequest backpressureも含む。', '',
              '| 構成 | 4×4 MMAC/s @81MHz | kMAC/s/LUT4 | 連続batch MMAC/s @81MHz |',
              '|---|---:|---:|---:|']
    keys = [('npu_v1 4 MUL', 'v1_4mul', 9), ('old v2 selector 4', 'selector_v2_4', 13),
            ('v2 Horner 4', 'horner_v2_4', 37), ('new v2 Shared ShiftAdd 8', 'shared8', 7)]
    for name, key, interval in keys:
        perf = 64*81/cycles[key][0]['cycles']
        lines.append(f'| {name} | {perf:.3f} | {perf*1000/resources(designs[name])[0]:.3f} | {16*81/interval:.3f} |')
    lines += ['', '81 MHzでv1の214→新190 cycles、2.642→2.346 µs（実行時間11.2%減、throughput12.6%増）。',
              'このcycle比較は同じ固定clockの性能であり、DSP timing未評価のFmaxから実機性能を外挿していない。', '']
    cone = audit['product_cones']
    lines += ['### ボトルネックと判断', '',
        '新v2の全3 seedで最長経路は**ACC読出し→ControllerのC write data FF**。',
        'seed 1/3はAccBank FFが始点、seed 2はControllerの読出し選択/control FFが始点。',
        '最遅seed 2はlogic 1.746 ns、routing 3.477 nsで、配線が約67%を占める。',
        'ShiftAdd、PE共有、Scheduler、product WB、ACC更新加算は今回の最長経路ではなかった。',
        '演算器単体のShiftAddではweight入力FF→選択/符号/加算carry chain→product FFが律速になる。', '',
        f'面積側はproduct生成の組合せconeが支配的。136 product FFのD入力から前段FFまでをたどると、',
        f'Yosys mapping後でLUT={cone["LUT"]}、MUX={cone["MUX"]}、ALU={cone["ALU"]}。',
        'このconeは共有2:1選択と8個の2項演算器を含み、ACC読出しやACC更新は含まない。',
        '全体のmapped MUX 4903のうち4812がこのconeにあり、面積増の主因はACC readではない。',
        '単体8 blockではMUX 1369だが、共有MUXを含むflatten/ABC mappingでは選択論理が結合・展開される。',
        '固定スライスでもMUXの生成コストは消えないことが確認できた。大きなMUXを単に別階層へ隠したという説明はしない。', '',
        '| 判断項目 | 結果 |', '|---|---|',
        '| 巨大packed vectorの動的読出し | 全体で除去。generic $shiftx=0、可変shift=0 |',
        '| 16 PE / 8 block共有 | 達成。8 instance、even/odd各1 issue、2項は同一clock |',
        '| LUT削減 | 未達。v1 2769→9045、旧selector8 3473→9045 |',
        '| Fmax回復 | nextpnr報告値で旧selector8 131.49→224.97 MHz。v1 202.72 MHz。ただしDSP timing制約あり |',
        '| 81 MHz throughput | 4×4で12.6%向上、連続16 PE batchで28.6%向上 |',
        '| throughput/LUT | 4×4で8.748→3.016 kMAC/s/LUT、約65.5%低下 |',
        '| v1に対する利点 | 演算MULT9X9×4を空け、同一clockのcyclesを削減できる |', '',
        '**4個の専用乗算器を使える条件では、v1の方がLUT効率に優れる。**',
        '共有8 ShiftAddは速度改善に対してLUT増が大きく、一般的な置き換えの優位性は確認できない。',
        '今回の結果は直接2項演算・共有接続・ACC読出し変更を合わせた測定であり、',
        '固定スライス化だけのFmax改善効果を分離測定したものではない。',
        '追加の大規模最適化は行わず、面積は共有選択＋2項演算cone、timingはACC readと配線を課題として残す。',
        '電力、SoC統合、FPGA実機動作、一般学習済みモデルの精度は未測定。15 runは全て81 MHz制約をツール上PASS。', '',
        '### 再現・変更ファイル', '',
        '旧selector/Hornerの手順は各source archiveから実行する。以下は現在のshared8専用。', '',
        '```bash',
        'myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/reference/pot.py \\\n  --output PSC-ONE/hardware/rtl/soc/npu_v2/results/shared8',
        'myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/reference/evaluate_model.py \\\n  --build /tmp/psc-npu-v2-shared8-model-reference \\\n  --output PSC-ONE/hardware/rtl/soc/npu_v2/results/shared8',
        'myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/tests/run.py \\\n  --build /tmp/psc-npu-v2-shared8-check \\\n  --vectors /tmp/psc-npu-v2-shared8-model-reference/rtl_vectors.json',
        'myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/tests/synthesis.py \\\n  --build /tmp/psc-npu-v2-shared8-timing \\\n  --variants v1 shared8 mul4 shiftadd4 shiftadd8 --seeds 1 2 3',
        '```', '',
        '今回の実行先: full PNR=`/tmp/psc-npu-v2-shared8-pnr-main`、unit PNR=`/tmp/psc-npu-v2-shared8-pnr-unit`、',
        '検証=`/tmp/psc-npu-v2-shared8-final-tests`、batch実測=`/tmp/psc-npu-v2-shared8-batch-timing`、',
        'v1回帰=`/tmp/psc-npu-v2-shared8-v1-tests`。全log、generic/mapped/PNR netlistはこれらのbuildに保存。',
        'レポート再生成は `tests/shared8_report.py --main-build <full PNR> --unit-build <unit PNR> --tests <検証>',
        '--v1-tests <v1回帰> --batch-tests <batch実測> --lint /tmp/psc-npu-v2-shared8-final-lint.log`。',
        '単一buildで全variantを実行した場合、main-buildとunit-buildには同じpathを指定できる。', '',
        'Horner時点の63ファイルを `results/horner_baseline_source.tar.gz` とmanifestに保存。',
        '既存のselector/Horner測定結果はSHA256で不変を確認した。元のselector archiveも保持している。', '',
        '- 変更: `src/PSC_NPU_AccBank.sv`、`PSC_NPU_Controller.v`、`PSC_NPU_MACScheduler.sv`、',
        '  `PSC_NPU_PotLanes.sv`、`PSC_NPU_SystolicArray4x4.v`、',
        '  `tests/CoreTop.sv`、`bank_test.py`、`core_test.py`、`pot_lanes_test.py`、`run.py`、`synthesis.py`、README。',
        '- 新規: `src/PSC_NPU_ShiftAdd2.sv`、`PSC_NPU_AccReadMux.sv`、',
        '  `tests/shiftadd_test.py`、`acc_read_test.py`、`DatapathTiming.sv`、`shared8_report.py`、',
        '  Horner archive/manifestと`results/shared8/`の測定・検証記録。',
        '- 削除: なし。既存npu/npu_v1、CPU、OS、SoC、既存Makefileは変更なし。',
        '- Git: npu_v2ディレクトリは未追跡。add/commit/pushその他の状態変更は未実施。', '']
    (out/'report.md').write_text('\n'.join(lines)+'\n')
    print('Report:', out/'report.md')


if __name__ == '__main__':
    main()
