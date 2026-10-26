#include "tflite_cpu.h"
#include "tflite_quant.h"
void psc_tflite_cpu_binary(const psc_tflite_cpu_op *p,const int8_t *a,const int8_t *b,int8_t *y) {
    size_t count=(size_t)p->out[0]*p->out[1]*p->out[2]*p->out[3];
    for(size_t i=0;i<count;++i) {
        size_t t=i,ai=0,bi=0;
        for(int d=3;d>=0;--d) {size_t c=t%p->out[d];t/=p->out[d];ai+=c*p->broadcast_a[d];bi+=c*p->broadcast_b[d];}
        int32_t x=(int32_t)a[ai]-p->input_zero,z=(int32_t)b[bi]-p->second_zero,q;
        if(p->kind==0||p->kind==41) {
            x=psc_tflite_requantize(x*1048576,p->multiplier[0],p->shift[0]);
            z=psc_tflite_requantize(z*1048576,p->multiplier[1],p->shift[1]);
            q=psc_tflite_requantize(p->kind==41?x-z:x+z,p->multiplier[2],p->shift[2]);
        } else q=psc_tflite_requantize(x*z,p->multiplier[2],p->shift[2]);
        q+=p->output_zero;
        if(q<p->minimum)q=p->minimum;
        if(q>p->maximum)q=p->maximum;
        y[i]=(int8_t)q;
    }
}
