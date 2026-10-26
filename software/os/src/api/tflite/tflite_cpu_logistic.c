#include "tflite_cpu.h"
void psc_tflite_cpu_logistic(const psc_tflite_cpu_op *p,const int8_t *x,int8_t *y) {
    size_t count=(size_t)p->out[0]*p->out[1]*p->out[2]*p->out[3];
    for(size_t i=0;i<count;++i)y[i]=p->lut[(int)x[i]+128];
}
