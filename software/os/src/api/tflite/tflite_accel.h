#ifndef PSC_TFLITE_ACCEL_H
#define PSC_TFLITE_ACCEL_H
#include "tflite_cpu.h"
#include "tflite_quant.h"
#include "psc/pulp_fc.h"

// Only compiled, validated INT8 Conv/FC geometry reaches these helpers.
// CPU kernels and the shared requantization implementation stay unchanged.
static inline int32_t psc_accel_bias(const uint8_t *b,int oc) {
    if(!b)return 0;b+=4*oc;
    return int32_t(uint32_t(b[0])|(uint32_t(b[1])<<8)|(uint32_t(b[2])<<16)|(uint32_t(b[3])<<24));
}
static inline int8_t psc_accel_output(const psc_tflite_cpu_op &p,int oc,int32_t acc) {
    int32_t q=psc_tflite_requantize(acc,p.channel_multiplier[oc],p.channel_shift[oc])+p.output_zero;
    if(q<p.minimum)q=p.minimum;if(q>p.maximum)q=p.maximum;return int8_t(q);
}
static inline bool psc_pulp_supports(const psc_tflite_cpu_op &p) {
#if PSC_HAS_CV_DOTSP_B || defined(PSC_PULP_TEST_EMULATE)
    return (p.kind==3||p.kind==9) && p.in[3]<=8192 &&
        (p.in[3]>=4 || (p.dilation_w==1 && p.filter[2]*p.in[3]>=4));
#else
    (void)p;return false;
#endif
}
// No im2col allocation. Reuse OHWI weights across all output positions.
// Padding contributes input_zero*weight to the raw dot, then the complete
// constant zero-point correction is applied once per output channel.
// prepare's conservative bias +/- depth*255*128 proof bounds partial sums.
// Return whether a SIMD instruction actually ran (very small borders can
// have scalar-only spans). Unaligned operands use the existing safe loader.
static inline bool psc_pulp_conv(const psc_tflite_cpu_op &p,const int8_t *x,
                                 const int8_t *w,const uint8_t *bias,int8_t *y) {
    bool used=false;int depth=p.filter[1]*p.filter[2]*p.in[3];
    for(int oc=0;oc<p.out[3];++oc) {
        const int8_t *weights=w+oc*depth;int32_t sum=0;
        for(int k=0;k<depth;++k)sum+=weights[k];
        int32_t initial=psc_accel_bias(bias,oc)-p.input_zero*sum;
        for(int n=0;n<p.out[0];++n)for(int oy=0;oy<p.out[1];++oy)for(int ox=0;ox<p.out[2];++ox) {
            int32_t acc=initial;
            for(int ky=0;ky<p.filter[1];++ky) {
                int iy=oy*p.stride_h-p.pad_h+ky*p.dilation_h;
                for(int kx=0;kx<p.filter[2];) {
                    int ix=ox*p.stride_w-p.pad_w+kx*p.dilation_w;
                    const int8_t *v=weights+(ky*p.filter[2]+kx)*p.in[3];
                    if(iy<0||iy>=p.in[1]||ix<0||ix>=p.in[2]) {
                        for(int c=0;c<p.in[3];++c)acc+=p.input_zero*v[c];++kx;
                    } else {
                        int run=1;
                        if(p.dilation_w==1){run=p.filter[2]-kx;if(run>p.in[2]-ix)run=p.in[2]-ix;}
                        int count=run*p.in[3];
                        const int8_t *u=x+((size_t(n)*p.in[1]+iy)*p.in[2]+ix)*p.in[3];
                        // Bound each SIMD raw dot independently, including long FC rows.
                        for(int base=0;base<count;) {
                            int len=count-base;if(len>8192)len=8192;int32_t dot=0;
                            if(psc_tflite_pulp::try_dot(u+base,v+base,len,0,true,&dot))used=true;
                            else for(int c=0;c<len;++c)dot+=int32_t(u[base+c])*v[base+c];
                            acc+=dot;base+=len;
                        }
                        kx+=run;
                    }
                }
            }
            y[((size_t(n)*p.out[1]+oy)*p.out[2]+ox)*p.out[3]+oc]=psc_accel_output(p,oc,acc);
        }
    }
    return used;
}
#endif
