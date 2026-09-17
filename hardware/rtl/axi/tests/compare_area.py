#!/usr/bin/env python3
"""Compare the old I+D bridge pair and shared bridge on Gowin GW2A-18C.

Pass an unmodified pre-change bridge file via --before. Both timing wrappers
use the same registered stimulus/observation boundary. This measures the bridge
subsystem, not whole-SoC Fmax. Outputs and JSON netlists are retained in --build.
"""
import argparse
import json
import subprocess
from pathlib import Path
from collections import Counter


def wrapper(shared):
    fields = {
        'awid': 1, 'awaddr': 32, 'awlen': 8, 'awsize': 3, 'awburst': 2, 'awvalid': 1,
        'wdata': 32, 'wstrb': 4, 'wlast': 1, 'wvalid': 1, 'bready': 1,
        'arid': 1, 'araddr': 32, 'arlen': 8, 'arsize': 3, 'arburst': 2, 'arvalid': 1, 'rready': 1}
    s = '''module BridgeTimingTop(input clock, input reset_n, output reg timing_keep);
    reg [127:0] stimulus;
    always @(posedge clock or negedge reset_n)
        if (!reset_n) stimulus <= 128'h123456789ABCDEF00123456789ABCDEF0;
        else stimulus <= {stimulus[126:0], stimulus[127]^stimulus[125]^stimulus[100]^stimulus[98]};
'''
    for name, width in [('i_ready',1),('d_ready',1),('w_ready',1),('i_data',128),('d_data',128)]:
        s += f'    (* keep = 1 *) wire [{width-1}:0] {name};\n'
    observations = ['i_ready','d_ready','w_ready','i_data','d_data']
    for index in range(1 if shared else 2):
        prefix = f'axi{index}_'
        for name, width in fields.items():
            s += f'    (* keep = 1 *) wire [{width-1}:0] {prefix}{name};\n'
            observations.append(prefix+name)
        if shared:
            ports = {'i_read_valid':'stimulus[0]', 'i_read_addr':'stimulus[63:32]',
                     'i_read_ready':'i_ready', 'i_read_data':'i_data',
                     'd_read_valid':'stimulus[1]', 'd_read_addr':'stimulus[95:64]',
                     'd_read_ready':'d_ready', 'd_read_data':'d_data',
                     'd_write_valid':'stimulus[2]', 'd_write_addr':'stimulus[95:64]',
                     'd_write_data':'stimulus', 'd_write_ready':'w_ready'}
        else:
            ports = {'read_valid':f'stimulus[{index}]',
                     'read_addr':'stimulus[95:64]' if index else 'stimulus[63:32]',
                     'read_ready':'d_ready' if index else 'i_ready',
                     'read_data':'d_data' if index else 'i_data',
                     'write_valid':'stimulus[2]' if index else "1'b0",
                     'write_addr':'stimulus[95:64]' if index else "32'b0",
                     'write_data':'stimulus' if index else "128'b0",
                     'write_ready':'w_ready' if index else ''}
        ports.update(clock='clock', reset_n='reset_n')
        ports.update({'m_axi_'+n:prefix+n for n in fields})
        # Independent slave response stimuli for the former two channels.
        k = 0 if shared or index == 0 else 8
        ports.update({'m_axi_'+n:v for n,v in {
            'awready':f'stimulus[{3+k}]', 'wready':f'stimulus[{4+k}]',
            'bvalid':f'stimulus[{5+k}]', 'bresp':"2'b0", 'bid':"1'b0",
            'arready':f'stimulus[{6+k}]', 'rvalid':f'stimulus[{7+k}]',
            'rlast':f'stimulus[{8+k}]', 'rdata':f'stimulus[{127-k}:{96-k}]',
            'rresp':"2'b0", 'rid':"1'b0"}.items()})
        s += f'    sdram_32bit_to_128bit_axi_bridge bridge{index} (\n'
        s += ',\n'.join(f'        .{n}({v})' for n,v in ports.items())+'\n    );\n'
    s += '    always @(posedge clock) timing_keep <= ^{'+','.join(observations)+'};\nendmodule\n'
    return s


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--before',type=Path,required=True)
    parser.add_argument('--build',type=Path,required=True)
    parser.add_argument('--yosys',default='yosys')
    parser.add_argument('--nextpnr',default='nextpnr-himbaechel')
    args=parser.parse_args()
    args.build.mkdir(parents=True,exist_ok=True)
    cst=args.build/'pins.cst'
    cst.write_text('IO_LOC "clock" 4;\nIO_LOC "reset_n" 88;\nIO_LOC "timing_keep" 15;\n')
    report={}
    for name, shared, source in [('before',False,args.before),('after',True,Path(__file__).resolve().parents[1]/'sdram_32bit_to_128bit_axi_bridge.v')]:
        build=args.build/name;build.mkdir(exist_ok=True)
        top=build/'timing.v';top.write_text(wrapper(shared))
        netlist=build/'netlist.json'
        with (build/'yosys.log').open('w') as log:
            subprocess.run([args.yosys,'-p',f'read_verilog -sv {source.resolve()} {top}; hierarchy -check -top BridgeTimingTop; stat; synth_gowin -top BridgeTimingTop -family gw2a -json {netlist}; stat'],stdout=log,stderr=subprocess.STDOUT,check=True)
        cells=Counter(c['type'] for c in json.loads(netlist.read_text())['modules']['BridgeTimingTop']['cells'].values())
        report[name]={'cells':dict(cells),'LUT':sum(v for k,v in cells.items() if k.startswith('LUT')),'MUX':sum(v for k,v in cells.items() if k.startswith('MUX')),'DFF':sum(v for k,v in cells.items() if k.startswith('DFF'))}
        with (build/'nextpnr.log').open('w') as log:
            result=subprocess.run([args.nextpnr,'--json',str(netlist),'--write',str(build/'pnr.json'),'--device','GW2AR-LV18QN88C8/I7','--vopt','family=GW2A-18C','--vopt',f'cst={cst}','--freq','81','--seed','1','--report',str(build/'timing.json')],stdout=log,stderr=subprocess.STDOUT)
        report[name]['pnr_exit']=result.returncode
        if (build/'timing.json').exists():
            report[name]['fmax']=json.loads((build/'timing.json').read_text()).get('fmax')
        print(name,report[name],flush=True)
    (args.build/'comparison.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':
    main()
