#!/usr/bin/env python3
"""Exercise actual sa_run_checked source with mock CSR/result memory on HOST.
Only MMIO/CSR and fences are substituted; shorten polling to four iterations
in the generated test copy. Production source and RTL are untouched.
"""
from pathlib import Path
import argparse
import os
import subprocess

os_dir=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--build',type=Path,required=True);a=p.parse_args()
build=a.build.resolve();build.mkdir(parents=True,exist_ok=True)
source=(os_dir/'src/synap_api.c').read_text()
source=source[source.index('static int sa_active;'):source.index('/* ============================================================\n   Test data generator')]
assert source.count('10000000u')==1
source=source.replace('10000000u','4u')
source=source.replace('__asm__ volatile("fence rw, rw" ::: "memory");','__asm__ volatile("" ::: "memory");')
prefix=r'''
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <assert.h>
typedef int bool;
#define false 0
#define SA_MAT_MAX 16u
#define SA_LOG(...) ((void)0)
#define CSR_SA_CTRL 0x7c0
#define CSR_SA_STATUS 0x7c8
#define CSR_SA_ADDR_A 0x7d0
#define CSR_SA_ADDR_B 0x7d4
#define CSR_SA_ADDR_C 0x7d8
static uint32_t result_words[256], last_ctrl;
static int done_mode=1, reset_count, start_count, reenter, reads;
static uint8_t input[256];
static uint32_t output[256];
#define PSC_SA_ADDR_C ((uintptr_t)result_words)
int sa_run_checked(const uint8_t*,const uint8_t*,uint8_t,uint32_t*,bool);
static void write_csr(unsigned csr,uint32_t value) {
    if(csr==CSR_SA_CTRL) {
        last_ctrl=value;
        if(value&2)++reset_count;
        if(value&1)++start_count;
    }
}
static uint32_t read_csr(unsigned csr) {
    assert(csr==CSR_SA_STATUS);++reads;
    if(reenter) {reenter=0;assert(sa_run_checked(input,input,4,output,1)==-3);}
    return done_mode ? 1 : 0;
}
#define CSR_WRITE(csr,value) write_csr(csr,value)
#define CSR_READ(csr) read_csr(csr)
'''
suffix=r'''
int main(void) {
    for(unsigned i=0;i<256;++i)result_words[i]=(uint32_t)(-(int)i-1);
    assert(sa_run_checked(input,input,0,output,1)==-1);
    assert(sa_run_checked(input,input,3,output,1)==-1);
    assert(sa_run_checked(input,input,20,output,1)==-1);
    assert(sa_run_checked(0,input,4,output,1)==-1);
    assert(sa_run_checked(input,0,4,output,1)==-1);
    assert(sa_run_checked(input,input,4,0,1)==-1);
    assert(start_count==0);
    reenter=1;
    assert(sa_run_checked(input,input,4,output,1)==0);
    assert(!sa_active && (last_ctrl&8));
    for(unsigned i=0;i<16;++i)assert(output[i]==result_words[i]);
    for(unsigned i=0;i<256;++i)output[i]=0x12345678;
    done_mode=0;int resets=reset_count;reads=0;
    assert(sa_run_checked(input,input,4,output,1)==-2);
    assert(reads==4 && reset_count==resets+2 && !sa_active);
    for(unsigned i=0;i<256;++i)assert(output[i]==0x12345678);
    done_mode=1;
    for(unsigned n=4;n<=16;n+=4) {
        assert(sa_run_checked(input,input,n,output,0)==0);
        assert(!(last_ctrl&8));
        for(unsigned i=0;i<n*n;++i)assert(output[i]==result_words[i]);
    }
    sa_run(input,input,4,output,1);assert(last_ctrl&8);
    puts("PASS: actual Synap driver arguments, busy, timeout reset/no output, recovery, legacy API");
}
'''
src=build/'synap_driver_host.c';src.write_text(prefix+source+suffix)
exe=build/'synap_driver_host'
subprocess.run([os.environ.get('CC','gcc'),'-std=c11','-O1','-g','-fsanitize=address,undefined',
                '-fno-sanitize-recover=all','-fno-omit-frame-pointer','-fno-pie','-no-pie',str(src),'-o',str(exe)],check=True)
subprocess.run([str(exe)],check=True,timeout=30,
               env=dict(os.environ,ASAN_OPTIONS='detect_leaks=1:halt_on_error=1',UBSAN_OPTIONS='halt_on_error=1'))
