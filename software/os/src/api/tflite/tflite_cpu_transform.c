#include "tflite_cpu.h"
#include "tflite_quant.h"
#include <string.h>
#include <math.h>
/* All dimensions, byte spans, constant control tensors and quantization have
   been validated by prepare. FLOAT32 user data is checked before conversion. */
static size_t flat(const int32_t d[4]){return (size_t)d[0]*d[1]*d[2]*d[3];}
static void coords(size_t i,const int32_t dims[4],int32_t c[4]){for(int d=3;d>=0;--d){c[d]=i%dims[d];i/=dims[d];}}
static size_t index4(const int32_t c[4],const int32_t d[4]){return (((size_t)c[0]*d[1]+c[1])*d[2]+c[2])*d[3]+c[3];}
int psc_tflite_cpu_transform(const psc_tflite_cpu_op *p,const void *const *inputs,void *out){
    const uint8_t *x=(const uint8_t *)inputs[0];uint8_t *y=(uint8_t *)out;size_t n=flat(p->out);
    if(p->kind==22){memcpy(y,x,n*p->width);return 0;}
    if(p->kind==2){
        size_t outer=1,inner=1;for(int d=0;d<p->axis;++d)outer*=p->out[d];for(int d=p->axis+1;d<4;++d)inner*=p->out[d];
        for(size_t o=0;o<outer;++o)for(int j=0;j<p->input_count;++j){size_t bytes=inner*p->concat_size[j]*p->width;memcpy(y,(const uint8_t *)inputs[j]+o*bytes,bytes);y+=bytes;}return 0;
    }
    if(p->kind==114){
        int8_t *dest=(int8_t *)out;
        for(size_t i=0;i<n;++i){int32_t q;
            if(p->type==0){float v;memcpy(&v,x+i*4,4);if(!isfinite(v))return -203;float r=roundf(v/p->output_scale);
                if(r<=-128-p->output_zero)q=-128;else if(r>=127-p->output_zero)q=127;else q=(int32_t)r+p->output_zero;
            }else q=psc_tflite_requantize((int32_t)((const int8_t *)x)[i]-p->input_zero,p->multiplier[0],p->shift[0])+p->output_zero;
            if(q<-128)q=-128;if(q>127)q=127;dest[i]=(int8_t)q;
        }return 0;
    }
    if(p->kind==6){for(size_t i=0;i<n;++i){float v=((int32_t)((const int8_t *)x)[i]-p->input_zero)*p->input_scale;memcpy(y+i*4,&v,4);}return 0;}
    if(p->kind==25){
        const int8_t *src=(const int8_t *)inputs[0];int8_t *dest=(int8_t *)out;int depth=p->out[3];
        for(size_t i=0;i<n;i+=depth){int max=-128;for(int c=0;c<depth;++c)if(src[i+c]>max)max=src[i+c];
            int32_t sum=0;for(int c=0;c<depth;++c)sum+=(p->exp_lut[max-src[i+c]]+2048LL)>>12;
            int32_t mult;int shift;psc_tflite_softmax_scale(sum,&mult,&shift);
            for(int c=0;c<depth;++c){int32_t q=psc_tflite_softmax_output(p->exp_lut[max-src[i+c]],mult,shift);if(q>127)q=127;if(q<-128)q=-128;dest[i+c]=q;}
        }return 0;
    }
    for(size_t i=0;i<n;++i){int32_t o[4],c[4];coords(i,p->out,o);int valid=1;
        for(int d=0;d<4;++d)c[d]=o[d];
        if(p->kind==39)for(int d=0;d<4;++d)c[p->aux[d]]=o[d];
        else if(p->kind==34||p->kind==65)for(int d=0;d<4;++d){c[d]=o[d]+(p->kind==34?-p->begin[d]:p->begin[d]);if(c[d]<0||c[d]>=p->in[d])valid=0;}
        else if(p->kind==97){for(int d=1;d<=2;++d){float scale=p->aux[0]&&p->out[d]>1?(p->in[d]-1)/(float)(p->out[d]-1):p->in[d]/(float)p->out[d];float pos=(o[d]+(p->aux[1]?0.5f:0.0f))*scale;c[d]=(int32_t)(p->aux[0]?roundf(pos):floorf(pos));if(c[d]<0)c[d]=0;if(c[d]>=p->in[d])c[d]=p->in[d]-1;}}
        if(valid)memcpy(y+i*p->width,x+index4(c,p->in)*p->width,p->width);
        else memset(y+i*p->width,p->width==1?p->input_zero:0,p->width);
    }return 0;
}
