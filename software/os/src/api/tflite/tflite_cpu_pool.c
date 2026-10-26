#include "tflite_cpu.h"
void psc_tflite_cpu_pool(const psc_tflite_cpu_op *p,const int8_t *x,int8_t *y) {
    for(int n=0;n<p->out[0];++n)for(int oy=0;oy<p->out[1];++oy)
    for(int ox=0;ox<p->out[2];++ox)for(int c=0;c<p->out[3];++c) {
        int y0=oy*p->stride_h-p->pad_h,x0=ox*p->stride_w-p->pad_w;
        int y1=y0+p->filter[1],x1=x0+p->filter[2];
        if(y0<0)y0=0;if(x0<0)x0=0;
        if(y1>p->in[1])y1=p->in[1];if(x1>p->in[2])x1=p->in[2];
        int32_t v=-128;
        for(int iy=y0;iy<y1;++iy)for(int ix=x0;ix<x1;++ix) {
            int32_t q=x[((size_t)n*p->in[1]+iy)*p->in[2]*p->in[3]+ix*p->in[3]+c];
            if(q>v)v=q;
        }
        if(v<p->minimum)v=p->minimum;
        if(v>p->maximum)v=p->maximum;
        *y++=(int8_t)v;
    }
}
