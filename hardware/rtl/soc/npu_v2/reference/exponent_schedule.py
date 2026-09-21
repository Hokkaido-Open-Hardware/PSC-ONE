#!/usr/bin/env python3
"""Pre-RTL exponent-major/Horner study; existing 8-bit codes stay unchanged."""
import argparse
from collections import Counter
import csv
import hashlib
import json
import math
from pathlib import Path
from pot import CODES, decode


def terms(code):
    if code == 0:
        return []
    return [(code & 7, -1 if code & 8 else 1),
            ((code >> 4) & 7, -1 if code & 128 else 1)]


def coefficient(code, exponent):
    return sum(sign for e, sign in terms(code) if e == exponent)


def horner(x, code, serial=False):
    acc = 0
    trace = []
    for exponent in range(7, -1, -1):
        if serial:
            for phase in (0, 1):
                if phase == 0:
                    acc *= 2
                term = [] if code == 0 else terms(code)[phase:phase+1]
                acc += sum(x*s for e,s in term if e == exponent)
                trace.append(acc)
        else:
            acc = acc*2+x*coefficient(code, exponent)
            trace.append(acc)
    return acc, trace


def minimal_terms(code):
    value=decode(code)
    if value == 0:return []
    if abs(value) & (abs(value)-1) == 0:
        return [(abs(value).bit_length()-1, -1 if value<0 else 1)]
    return terms(code)


def distribution(codes):
    count=len(codes)
    raw=[t for code in codes for t in terms(code)]
    minimal=[t for code in codes for t in minimal_terms(code)]
    coefficients=[coefficient(code,k) for code in codes for k in range(8)]
    return {
        'weights':count,
        'encoded_term_count':{str(n):sum(len(terms(c))==n for c in codes) for n in range(3)},
        'minimal_term_count':{str(n):sum(len(minimal_terms(c))==n for c in codes) for n in range(3)},
        'raw_exponents':[{'exponent':k,'positive':raw.count((k,1)),'negative':raw.count((k,-1))} for k in range(8)],
        'minimal_exponents':[{'exponent':k,'positive':minimal.count((k,1)),'negative':minimal.count((k,-1))} for k in range(8)],
        'exponent_major_raw_terms':len(raw),'exponent_major_minimal_terms':len(minimal),
        'zero_weight_rate':sum(decode(c)==0 for c in codes)/count,
        'serial_term_skip_rate':1-len(raw)/(16*count),
        'horner_coefficient_skip_rate':coefficients.count(0)/(8*count),
        'horner_coefficients':{str(k):coefficients.count(k) for k in (-2,-1,0,1,2)},
        'reordering_changes_raw_term_count':False,
        'ideal_sparse_issue_cycles':{str(l):sum(math.ceil(sum(e==k for e,s in raw)/l) for k in range(8)) for l in (4,8,16)},
        'ideal_sparse_caveat':'ignores destination conflicts, loading, scatter addresses, final reduction and empty exponent transitions',
        'dense_issue_cycles':{str(l):{'v1':math.ceil(count/4),'selector_v2':2*math.ceil(count/l),
                                     'horner8':8*math.ceil(count/l),'horner16':16*math.ceil(count/l)} for l in (4,8,16)},
    }


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--model-json',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    model=json.loads(a.model_json.read_text())
    datasets={'all_INT8':list(CODES),'unique_canonical':sorted(set(CODES))}
    datasets.update({f'FC{i+1}':[CODES[w+128] for w in layer['weights']] for i,layer in enumerate(model['layers'])})
    datasets['model_all']=datasets['FC1']+datasets['FC2']
    # Independent integer product oracle, exhaustive beyond the required
    # canonical codes: all 256 codes, all signed AND unsigned activations.
    checked=0
    for mode in (0,1):
        for a_byte in range(256):
            x=a_byte-(256 if mode and a_byte&128 else 0)
            for code in range(256):
                for serial in (False,True):
                    actual,trace=horner(x,code,serial)
                    assert actual==x*decode(code)
                    assert all(-(1<<16)<=v<(1<<16) for v in trace)
                    checked+=1
    result={'datasets':{n:distribution(c) for n,c in datasets.items()},
            'python_exhaustive_comparisons':checked,'status':'PASS',
            'encoding':{'unchanged_code_bits_per_weight':8,'minimal_terms_with_separate_valid_bits':10,
                        'ternary_planes_bits_per_weight':16,'raw_two_term_signed_planes_bits_per_weight':24,
                        'sparse_term_bits_for_FC1':9,
                        'sparse_term_note':'exponent implicit in bucket; sign 1 + input index 4 + output index 4; exclude bucket pointers/counts',
                        'ternary_note':'16 bits assumes normalized coefficients -1/0/+1; raw equal-exponent terms can need +/-2 (3 bits/exponent)'},
            'architectures':{
                'exponent_banks':{'extra_ACC_bits_per_16_outputs':16*8*32,'notes':'8 banks; fixed shifts on separate outputs require wide reduction/add network'},
                'fixed_shift_writeback':{'notes':'parallel exponent-specific adders need wide output selection; serialized fixed 1-bit shifts take extra cycles'},
                'horner16':{'lane_product_bits':17,'lane_adders':[17,9],'cycles_per_group':16,
                            'notes':'one term at a time: +/-x/skip; 17-bit feedback hold/double mux and 4-bit term mux'},
                'horner8':{'lane_product_bits':17,'lane_adders':[17,9],'cycles_per_group':8,
                           'notes':'merge equal-exponent terms; contribution 0,+/-x,+/-2x. Always fixed feedback doubling; at most one 2:1 magnitude mux'},
                'global_horner_ACC':{'notes':'would double previous K-tile sums too. Requires reordering Controller/read path over the entire reduction or extra saved ACC bank; avoid interface/dataflow changes'}},
            'batch_cycles':{str(l):{name:{'issue':steps*16//(4 if name=='v1' else l),'start_to_done':4+steps*16//(4 if name=='v1' else l),'start_interval':5+steps*16//(4 if name=='v1' else l)}
                           for name,steps in [('v1',1),('selector_v2',2),('horner8',8),('horner16',16)]} for l in (4,8,16)}}
    (a.output/'exponent_study.json').write_text(json.dumps(result,indent=2)+'\n')
    with (a.output/'exponent_weights.csv').open('w') as f:
        w=csv.writer(f);w.writerow(['dataset','index','code','decoded','encoded_terms','minimal_terms',*[f'coefficient_{i}' for i in range(8)]])
        for name,codes in datasets.items():
            w.writerows([name,i,c,decode(c),len(terms(c)),len(minimal_terms(c)),*[coefficient(c,k) for k in range(8)]] for i,c in enumerate(codes))
    print(json.dumps(result,indent=2))

if __name__=='__main__':main()
