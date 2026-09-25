#!/usr/bin/env python3
"""Evaluate the actual TFLite bytes using PSC CPU traces and a Python oracle."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import random
import re
import subprocess
from pot import CODES, decode, metrics, quantize

BASE = Path(__file__).resolve().parents[1]
ROOT = BASE.parents[4]
OS = ROOT/'PSC-ONE/software/os'


def requant(x, m, shift):
    x *= 1 << max(shift, 0)
    prod = x*m
    nudge = (1 << 30) if prod >= 0 else 1-(1 << 30)
    value = abs(prod+nudge)//(1 << 31) * (1 if prod+nudge >= 0 else -1)
    right = max(-shift, 0)
    mask = (1 << right)-1
    return (value >> right) + int((value & mask) > ((mask >> 1)+int(value < 0)))


def infer(layers, data, pot=False):
    rows=[]
    for l, layer in enumerate(layers):
        weights=[quantize(w) for w in layer['weights']] if pot else layer['weights']
        out=[]
        for c in range(layer['n']):
            w=weights[c*layer['k']:(c+1)*layer['k']]
            raw=sum(x*y for x,y in zip(data,w,strict=True))
            corrected=raw-layer['input_zero']*sum(w)
            biased=corrected+layer['bias'][c]
            q=requant(biased,layer['multiplier'],layer['shift'])+layer['output_zero']
            y=max(layer['activation_min'],min(127,q))
            out.append(y)
            rows.append([l,c,raw,corrected,biased,q,y])
        data=out
    return rows


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--model',type=Path,default=OS/'tests/tflite/build/tflite-model/phase3/MODEL.TFL')
    p.add_argument('--build',type=Path,required=True)
    p.add_argument('--output',type=Path,default=BASE/'results')
    a=p.parse_args(); a.build=a.build.resolve(); a.build.mkdir(parents=True,exist_ok=True);a.output.mkdir(parents=True,exist_ok=True)
    v=OS/'third_party/tflite'
    cmd=['g++','-std=c++17','-O2','-DTFLITE_SINGLE_ROUNDING=0']
    cmd += ['-I'+str(d) for d in [OS/'src/api/tflite',v,v/'flatbuffers/include',v/'gemmlowp']]
    cmd += [str(BASE/'reference/model_probe.cc')]+[str(OS/f) for f in ['src/api/tflite/tflite_inspect.cc','src/api/tflite/tflite_runtime.cc','src/api/tflite/tflite_quant.cc','src/api/tflite/tflite_synap.cc','tests/tflite/synap_mock.cc']]
    subprocess.run(cmd+['-o',str(a.build/'model_probe')],check=True)
    header=(OS/'src/api/tflite/tflite_demo.h').read_text()
    demo=[int(x) for x in re.search(r'demo_input\[16\] = \{([^}]+)',header)[1].split(',') if x.strip()]
    rng=random.Random(20260919)
    inputs=[demo]+[[v]*16 for v in [-128,-1,0,1,127]]+[[rng.randrange(-128,128) for _ in range(16)] for _ in range(256)]
    (a.build/'inputs.bin').write_bytes(bytes(x&255 for row in inputs for x in row))
    subprocess.run([str(a.build/'model_probe'),str(a.model.resolve()),str(a.build/'inputs.bin'),str(a.build)],check=True)
    layers=json.loads((a.build/'model.json').read_text())['layers']
    assert [x['n'] for x in layers]==[16,4] and all(x['k']==16 for x in layers), 'this evaluation uses the existing 16-input 20ch fixture'
    cpu=list(csv.DictReader((a.build/'cpu.csv').open()))
    original=[infer(layers,x) for x in inputs]; approx=[infer(layers,x,True) for x in inputs]
    flat=[[s,*row] for s,rows in enumerate(original) for row in rows]
    assert [[int(v) for v in row.values()] for row in cpu]==flat, 'Python must match real PSC CPU in every channel'
    golden=list(csv.DictReader((OS/'tests/tflite/build/tflite-model/phase3/reference.csv').open()))
    assert [[int(v) for v in row.values()] for row in golden]==[[r[0],r[1],r[4],r[5],r[6]] for r in original[0]]
    result={'model':str(a.model.relative_to(ROOT)), 'sha256':hashlib.sha256(a.model.read_bytes()).hexdigest(),
            'samples':len(inputs),'channels_per_sample':20,'cpu_python_exact':True,'existing_20ch_golden_exact':True,
            'classification_definition':'argmax of FC2 output; first index wins ties; synthetic model, no ground truth labels', 'layers':[]}
    with (a.output/'model_weights.csv').open('w') as f:
        writer=csv.writer(f);writer.writerow(['layer','index','original_weight','code','quantized_weight','absolute_error'])
        for l,layer in enumerate(layers):
            writer.writerows([l,i,w,CODES[w+128],quantize(w),abs(w-quantize(w))] for i,w in enumerate(layer['weights']))
            before=[r[-1] for rows in original for r in rows if r[0]==l]
            after=[r[-1] for rows in approx for r in rows if r[0]==l]
            acc0=[r[4] for rows in original for r in rows if r[0]==l]
            acc1=[r[4] for rows in approx for r in rows if r[0]==l]
            result['layers'].append({'name':f'FC{l+1}','weights':metrics(layer['weights'],[quantize(w) for w in layer['weights']]),'output':metrics(before,after),'accumulator':metrics(acc0,acc1)})
    result['classification_agreement']=sum(max(range(4),key=lambda c:org[16+c][-1])==max(range(4),key=lambda c:app[16+c][-1]) for org,app in zip(original,approx))
    result['demo_final_original']=[r[-1] for r in original[0][-4:]]
    result['demo_final_pot']=[r[-1] for r in approx[0][-4:]]
    result['demo_class_original']=max(range(4),key=lambda c:result['demo_final_original'][c])
    result['demo_class_pot']=max(range(4),key=lambda c:result['demo_final_pot'][c])
    with (a.output/'model_comparison.csv').open('w') as f:
        wr=csv.writer(f);wr.writerow(['sample','layer','channel','original_acc','pot_acc','original_output','pot_output','absolute_error'])
        for s,(org,app) in enumerate(zip(original,approx)):
            wr.writerows([s,r[0],r[1],r[4],q[4],r[6],q[6],abs(r[6]-q[6])] for r,q in zip(org,app))
    # Exact RTL vectors include the real layer inputs, all output channels and
    # the corrected bias (bias - input_zero * quantized row_sum).
    vectors=[]
    for sample,(data,rows) in enumerate(zip(inputs,approx)):
        for l,layer in enumerate(layers):
            if l: data=[r[-1] for r in rows if r[0]==l-1]
            for c in range(layer['n']):
                weights=layer['weights'][c*16:(c+1)*16]
                vectors.append({'sample':sample,'layer':l,'channel':c,'activation':data,'codes':[CODES[w+128] for w in weights],
                                'raw':next(r[2] for r in rows if r[:2]==[l,c])})
    (a.build/'rtl_vectors.json').write_text(json.dumps(vectors))
    (a.output/'model_evaluation.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))

if __name__=='__main__': main()
