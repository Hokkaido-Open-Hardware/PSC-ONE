#include "tflite_cpu.h"
#include "tflite_quant.h"
static int32_t bias_value(const uint8_t *p) {
    return (int32_t)((uint32_t)p[0] | ((uint32_t)p[1]<<8) |
                     ((uint32_t)p[2]<<16) | ((uint32_t)p[3]<<24));
}
void psc_tflite_cpu_conv(const psc_tflite_cpu_op *p, const int8_t *x,
                        const int8_t *w, const uint8_t *bias, int8_t *y) {
    for (int n=0;n<p->out[0];++n) for (int oy=0;oy<p->out[1];++oy)
    for (int ox=0;ox<p->out[2];++ox) for (int oc=0;oc<p->out[3];++oc) {
        int32_t acc=bias ? bias_value(bias+4*oc) : 0;
        for (int ky=0;ky<p->filter[1];++ky) {
            int iy=oy*p->stride_h-p->pad_h+ky*p->dilation_h;
            if (iy<0 || iy>=p->in[1]) continue; /* padding is input zero point */
            for (int kx=0;kx<p->filter[2];++kx) {
                int ix=ox*p->stride_w-p->pad_w+kx*p->dilation_w;
                if (ix<0 || ix>=p->in[2]) continue;
                size_t xi=((size_t)n*p->in[1]+iy)*p->in[2]*p->in[3]+ix*p->in[3];
                size_t wi=((size_t)oc*p->filter[1]+ky)*p->filter[2]*p->filter[3]+kx*p->filter[3];
                for (int ic=0;ic<p->in[3];++ic)
                    acc+=((int32_t)x[xi+ic]-p->input_zero)*w[wi+ic];
            }
        }
        int32_t q=psc_tflite_requantize(acc,p->channel_multiplier[oc],p->channel_shift[oc])+p->output_zero;
        if(q<p->minimum)q=p->minimum;
        if(q>p->maximum)q=p->maximum;
        *y++=(int8_t)q;
    }
}
