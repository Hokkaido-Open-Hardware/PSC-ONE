#include "tflite_synap.h"
#include "tflite_accel.h"
#include <string.h>
namespace {
/* Shared synchronous workspace, protected by runtime's invoking guard.
   SYS_SA_RUN copies to kernel physical buffers; no user VA is given to NPU. */
alignas(16) int8_t a[SA_MAT_MAX*SA_MAT_MAX], b[SA_MAT_MAX*SA_MAT_MAX];
alignas(16) int32_t c[SA_MAT_MAX*SA_MAT_MAX];
void elapsed(psc_tflite_profile_t *p,int start,int end,uint32_t &field) {
    if (start < 0 || end < start) p->valid=0;
    else field+=uint32_t(end-start);
}
}

extern "C" __attribute__((weak)) int psc_tflite_qtile_available(void) { return -1; }
extern "C" __attribute__((weak)) int psc_tflite_sa_qtile(const int8_t *,const int8_t *,int8_t *,unsigned,unsigned,psc_sa_qtile_t *) { return -4; }
extern "C" __attribute__((weak)) int psc_tflite_qbatch_enabled(void) { return 0; }
extern "C" __attribute__((weak)) int psc_tflite_sa_qbatch(const int8_t *,const int8_t *,int8_t *,psc_sa_qbatch_t *) { return -4; }
namespace {
// Full K for only one 4x4 output tile. One syscall owns all K segments.
// This workspace is separate from the existing raw path and bounded at 36 KiB plus output scratch.
alignas(16) int8_t qa[PSC_SA_Q_BATCH_M*PSC_SA_Q_MAX_K],qb[PSC_SA_Q_BATCH_N*PSC_SA_Q_MAX_K],qc[PSC_SA_Q_BATCH_M*PSC_SA_Q_BATCH_N];
int quantized_conv(const psc_tflite_cpu_op &p,const int8_t *x,const int8_t *w,
                   const uint8_t *bias,int8_t *y,psc_tflite_profile_t *profile) {
    unsigned depth=p.filter[1]*p.filter[2]*p.in[3],kt=(depth+3)&~3u;
    unsigned positions=p.out[0]*p.out[1]*p.out[2];
    for(unsigned oc=0;oc<unsigned(p.out[3]);oc+=4) {
        unsigned cols=unsigned(p.out[3])-oc;if(cols>4)cols=4;
        psc_sa_qtile_t q={};
        int t0=profile?psc_tflite_clock_us():-1;
        memset(qb,0,kt*4);
        for(unsigned col=0;col<cols;++col) {
            int32_t sum=0;
            for(unsigned k=0;k<depth;++k){int8_t v=w[(oc+col)*depth+k];sum+=v;qb[k*4+col]=v;}
            q.parameters[col]=psc_accel_bias(bias,oc+col)-p.input_zero*sum;
            q.parameters[4+col]=p.channel_multiplier[oc+col];q.parameters[8+col]=p.channel_shift[oc+col];
        }
        q.parameters[12]=p.output_zero;q.parameters[13]=p.minimum;q.parameters[14]=p.maximum;
        if(profile)elapsed(profile,t0,psc_tflite_clock_us(),profile->packing_us);
        for(unsigned pos=0;pos<positions;pos+=4) {
            unsigned rows=positions-pos;if(rows>4)rows=4;
            t0=profile?psc_tflite_clock_us():-1;
            memset(qa,0,rows*kt);
            for(unsigned row=0;row<rows;++row) {
                unsigned pixel=pos+row;
                int ox=pixel%p.out[2],oy=(pixel/p.out[2])%p.out[1],batch=pixel/(p.out[2]*p.out[1]);
                unsigned at=0;
                for(int ky=0;ky<p.filter[1];++ky)for(int kx=0;kx<p.filter[2];++kx) {
                    int iy=oy*p.stride_h-p.pad_h+ky*p.dilation_h,ix=ox*p.stride_w-p.pad_w+kx*p.dilation_w;
                    if(iy<0||iy>=p.in[1]||ix<0||ix>=p.in[2])
                        memset(qa+row*kt+at,uint8_t(p.input_zero),p.in[3]);
                    else memcpy(qa+row*kt+at,x+((size_t(batch)*p.in[1]+iy)*p.in[2]+ix)*p.in[3],p.in[3]);
                    at+=p.in[3];
                }
            }
            int t1=profile?psc_tflite_clock_us():-1;
            int rc=psc_tflite_sa_qtile(qa,qb,qc,rows,kt,&q);
            int t2=profile?psc_tflite_clock_us():-1;
            if(profile) {
                ++profile->syscalls;profile->tiles+=q.commands;profile->device_status=rc;
                profile->copy_in_bytes+=(rows+4)*kt;
                profile->read_bytes+=q.read_bytes;profile->write_bytes+=q.write_bytes;
                elapsed(profile,t0,t1,profile->packing_us);elapsed(profile,t1,t2,profile->syscall_us);
                if(!q.valid)profile->valid=0;
                else {profile->copy_in_us+=q.copy_in_us;profile->execute_us+=q.execute_us;profile->copy_out_us+=q.copy_out_us;}
            }
            if(rc)return rc==-2?PSC_TFLITE_ERR_SYNAP_TIMEOUT:rc==-3?PSC_TFLITE_ERR_SYNAP_BUSY:PSC_TFLITE_ERR_SYNAP;
            for(unsigned row=0;row<rows;++row)memcpy(y+(pos+row)*p.out[3]+oc,qc+row*4,cols);
            if(profile)elapsed(profile,t2,psc_tflite_clock_us(),profile->post_us);
        }
    }
    return 0;
}
int quantized_batch_conv(const psc_tflite_cpu_op &p,const int8_t *x,const int8_t *w,
                   const uint8_t *bias,int8_t *y,psc_tflite_profile_t *profile) {
    unsigned depth=p.filter[1]*p.filter[2]*p.in[3],kt=(depth+3)&~3u;
    unsigned positions=p.out[0]*p.out[1]*p.out[2];
    for(unsigned oc=0;oc<unsigned(p.out[3]);oc+=PSC_SA_Q_BATCH_N) {
        unsigned cols=unsigned(p.out[3])-oc;if(cols>PSC_SA_Q_BATCH_N)cols=PSC_SA_Q_BATCH_N;
        unsigned nt=(cols+3)&~3u;
        psc_sa_qbatch_t q={};q.k=kt;q.n=nt;
        int t0=profile?psc_tflite_clock_us():-1;
        memset(qb,0,kt*nt);
        for(unsigned col=0;col<cols;++col) {
            int32_t sum=0;
            for(unsigned k=0;k<depth;++k){int8_t v=w[(oc+col)*depth+k];sum+=v;qb[(col/4)*kt*4+k*4+col%4]=v;}
            q.parameters[col/4][col%4]=psc_accel_bias(bias,oc+col)-p.input_zero*sum;
            q.parameters[col/4][4+col%4]=p.channel_multiplier[oc+col];q.parameters[col/4][8+col%4]=p.channel_shift[oc+col];
        }
        for(unsigned g=0;g<nt/4;++g) {
            q.parameters[g][12]=p.output_zero;q.parameters[g][13]=p.minimum;q.parameters[g][14]=p.maximum;
        }
        if(profile)elapsed(profile,t0,psc_tflite_clock_us(),profile->packing_us);
        for(unsigned pos=0;pos<positions;pos+=PSC_SA_Q_BATCH_M) {
            unsigned rows=positions-pos;if(rows>PSC_SA_Q_BATCH_M)rows=PSC_SA_Q_BATCH_M;
            q.m=rows;
            t0=profile?psc_tflite_clock_us():-1;
            memset(qa,0,rows*kt);
            for(unsigned row=0;row<rows;++row) {
                unsigned pixel=pos+row;
                int ox=pixel%p.out[2],oy=(pixel/p.out[2])%p.out[1],batch=pixel/(p.out[2]*p.out[1]);
                unsigned at=0;
                for(int ky=0;ky<p.filter[1];++ky)for(int kx=0;kx<p.filter[2];++kx) {
                    int iy=oy*p.stride_h-p.pad_h+ky*p.dilation_h,ix=ox*p.stride_w-p.pad_w+kx*p.dilation_w;
                    if(iy<0||iy>=p.in[1]||ix<0||ix>=p.in[2])
                        memset(qa+row*kt+at,uint8_t(p.input_zero),p.in[3]);
                    else memcpy(qa+row*kt+at,x+((size_t(batch)*p.in[1]+iy)*p.in[2]+ix)*p.in[3],p.in[3]);
                    at+=p.in[3];
                }
            }
            int t1=profile?psc_tflite_clock_us():-1;
            int rc=psc_tflite_sa_qbatch(qa,qb,qc,&q);
            int t2=profile?psc_tflite_clock_us():-1;
            if(profile) {
                ++profile->syscalls;profile->tiles+=q.commands;profile->device_status=rc;
                profile->copy_in_bytes+=q.copy_in_bytes;
                profile->read_bytes+=q.read_bytes;profile->write_bytes+=q.write_bytes;
                elapsed(profile,t0,t1,profile->packing_us);elapsed(profile,t1,t2,profile->syscall_us);
                if(!q.valid)profile->valid=0;
                else {profile->copy_in_us+=q.copy_in_us;profile->execute_us+=q.execute_us;profile->copy_out_us+=q.copy_out_us;}
            }
            if(rc)return rc==-2?PSC_TFLITE_ERR_SYNAP_TIMEOUT:rc==-3?PSC_TFLITE_ERR_SYNAP_BUSY:PSC_TFLITE_ERR_SYNAP;
            for(unsigned row=0;row<rows;++row)memcpy(y+(pos+row)*p.out[3]+oc,qc+row*nt,cols);
            if(profile)elapsed(profile,t2,psc_tflite_clock_us(),profile->post_us);
        }
    }
    return 0;
}
}
extern "C" int psc_tflite_synap_batch(const int8_t *x,const int8_t *w,unsigned m,unsigned k,unsigned n,
                                    unsigned tile,int32_t *dot,psc_tflite_profile_t *p) {
    if (!x || !w || !dot || !k || k>8192 || !m || m>tile || !n || n>tile ||
        tile<4 || tile>SA_MAT_MAX || tile%4) return PSC_TFLITE_ERR_GRAPH;
    for (unsigned row=0;row<m*n;++row) dot[row]=0;
    for (unsigned base=0;base<k;base+=tile) {
        int t0=p?psc_tflite_clock_us():-1;
        unsigned count=k-base<tile ? k-base : tile;
        // A contains only real input rows; B is transposed weights.
        // M=m avoids computing and copying the padded tile rows.
        memset(a,0,m*tile);memset(b,0,tile*tile);
        for(unsigned sample=0;sample<m;++sample)
            for(unsigned col=0;col<count;++col) a[sample*tile+col]=x[sample*k+base+col];
        for(unsigned row=0;row<count;++row)
            for(unsigned col=0;col<n;++col) b[row*tile+col]=w[col*k+base+row];
        int t1=p?psc_tflite_clock_us():-1;
        psc_sa_profile_t device={};
        int rc=psc_tflite_sa_tile(a,b,c,m,tile,tile,p?&device:nullptr);
        int t2=p?psc_tflite_clock_us():-1;
        if(p) {
            if(!rc)++p->tiles;++p->syscalls;p->device_status=rc;
            p->copy_in_bytes+=m*tile+tile*tile;
            elapsed(p,t0,t1,p->packing_us);elapsed(p,t1,t2,p->syscall_us);
            if(!device.valid) p->valid=0;
            else {p->copy_in_us+=device.copy_in_us;p->execute_us+=device.execute_us;p->copy_out_us+=device.copy_out_us;}
        }
        if(rc) { // never consume stale c, no fallback
            if(rc==-1) return PSC_TFLITE_ERR_SYNAP_ARGUMENT;
            if(rc==-2) return PSC_TFLITE_ERR_SYNAP_TIMEOUT;
            if(rc==-3) return PSC_TFLITE_ERR_SYNAP_BUSY;
            return PSC_TFLITE_ERR_SYNAP;
        }
        for(unsigned sample=0;sample<m;++sample)
            for(unsigned row=0;row<n;++row) dot[sample*n+row]+=c[sample*tile+row];
        if(p) elapsed(p,t2,psc_tflite_clock_us(),p->partial_us);
    }
    return 0;
}

extern "C" int psc_tflite_synap_conv(const psc_tflite_cpu_op *params,const int8_t *x,
    const int8_t *w,const uint8_t *bias,int8_t *y,unsigned tile,int32_t *acc,psc_tflite_profile_t *profile) {
    const auto &p=*params;
    if(tile<4||tile>SA_MAT_MAX||tile%4)return PSC_TFLITE_ERR_SYNAP_ARGUMENT;
    unsigned depth=p.filter[1]*p.filter[2]*p.in[3];
    // prepare validates every weight zero point is zero and proves INT32 bounds.
    // Unsupported depth/quantization keeps the existing raw path.
    bool supported=depth<=PSC_SA_Q_MAX_K && p.second_zero==0;
    for(int oc=0;supported && oc<p.out[3];++oc)
        supported=p.channel_shift[oc]>=-31 && p.channel_shift[oc]<=30;
    int capability=supported?psc_tflite_qtile_available():-1;
    if(profile && capability>=0)++profile->syscalls; // includes an unsupported probe
    if(capability>0) {
        if(psc_tflite_qbatch_enabled())return quantized_batch_conv(p,x,w,bias,y,profile);
        return quantized_conv(p,x,w,bias,y,profile);
    }
    unsigned positions=p.out[0]*p.out[1]*p.out[2];
    int32_t initial[SA_MAT_MAX];
    for(unsigned oc=0;oc<unsigned(p.out[3]);oc+=tile) {
        unsigned cols=unsigned(p.out[3])-oc;if(cols>tile)cols=tile;
        unsigned nt=(cols+3)&~3u;
        int t0=profile?psc_tflite_clock_us():-1;
        for(unsigned c0=0;c0<cols;++c0) {
            int32_t sum=0;for(unsigned k=0;k<depth;++k)sum+=w[(oc+c0)*depth+k];
            initial[c0]=psc_accel_bias(bias,oc+c0)-p.input_zero*sum;
        }
        if(profile)elapsed(profile,t0,psc_tflite_clock_us(),profile->packing_us);
        for(unsigned pos=0;pos<positions;pos+=tile) {
            unsigned rows=positions-pos;if(rows>tile)rows=tile;
            for(unsigned row=0;row<rows;++row)for(unsigned col=0;col<cols;++col)acc[row*cols+col]=initial[col];
            for(unsigned base=0;base<depth;base+=tile) {
                unsigned count=depth-base;if(count>tile)count=tile;unsigned kt=(count+3)&~3u;
                t0=profile?psc_tflite_clock_us():-1;
                memset(a,0,rows*kt);memset(b,0,kt*nt);
                for(unsigned row=0;row<rows;++row) {
                    unsigned pixel=pos+row;
                    int ox=pixel%p.out[2],oy=(pixel/p.out[2])%p.out[1],batch=pixel/(p.out[2]*p.out[1]);
                    unsigned ky=base/(p.filter[2]*p.in[3]),kx=(base/p.in[3])%p.filter[2],ic=base%p.in[3];
                    for(unsigned k=0;k<count;) {
                        int iy=oy*p.stride_h-p.pad_h+ky*p.dilation_h;
                        int ix=ox*p.stride_w-p.pad_w+kx*p.dilation_w;
                        unsigned run=p.in[3]-ic;if(run>count-k)run=count-k;
                        if(iy<0||iy>=p.in[1]||ix<0||ix>=p.in[2])memset(a+row*kt+k,uint8_t(p.input_zero),run);
                        else memcpy(a+row*kt+k,x+((size_t(batch)*p.in[1]+iy)*p.in[2]+ix)*p.in[3]+ic,run);
                        k+=run;ic+=run;if(ic==unsigned(p.in[3])){ic=0;if(++kx==unsigned(p.filter[2])){kx=0;++ky;}}
                    }
                }
                for(unsigned k=0;k<count;++k)for(unsigned col=0;col<cols;++col)b[k*nt+col]=w[(oc+col)*depth+base+k];
                int t1=profile?psc_tflite_clock_us():-1;psc_sa_profile_t device={};
                int rc=psc_tflite_sa_tile(a,b,c,rows,kt,nt,profile?&device:nullptr);
                int t2=profile?psc_tflite_clock_us():-1;
                if(profile) {
                    profile->device_status=rc;if(!rc)++profile->tiles;++profile->syscalls;
                    profile->copy_in_bytes+=rows*kt+kt*nt;profile->read_bytes+=rows*kt+kt*nt;profile->write_bytes+=rows*nt*4;
                    elapsed(profile,t0,t1,profile->packing_us);elapsed(profile,t1,t2,profile->syscall_us);
                    if(!device.valid)profile->valid=0;
                    else {profile->copy_in_us+=device.copy_in_us;profile->execute_us+=device.execute_us;profile->copy_out_us+=device.copy_out_us;}
                }
                // Some earlier output tiles may be written. The runtime marks
                // the whole output invalid. No CPU retry while DMA is uncertain.
                if(rc)return rc==-1?PSC_TFLITE_ERR_SYNAP_ARGUMENT:rc==-2?PSC_TFLITE_ERR_SYNAP_TIMEOUT:rc==-3?PSC_TFLITE_ERR_SYNAP_BUSY:PSC_TFLITE_ERR_SYNAP;
                for(unsigned row=0;row<rows;++row)for(unsigned col=0;col<cols;++col)acc[row*cols+col]+=c[row*nt+col];
                if(profile)elapsed(profile,t2,psc_tflite_clock_us(),profile->partial_us);
            }
            t0=profile?psc_tflite_clock_us():-1;
            for(unsigned row=0;row<rows;++row)for(unsigned col=0;col<cols;++col)
                y[(pos+row)*p.out[3]+oc+col]=psc_accel_output(p,oc+col,acc[row*cols+col]);
            if(profile)elapsed(profile,t0,psc_tflite_clock_us(),profile->post_us);
        }
    }
    return 0;
}

extern "C" int psc_tflite_synap_dot(const int8_t *x,const int8_t *w,unsigned k,unsigned n,
                                    unsigned tile,int32_t *dot,psc_tflite_profile_t *p) {
    return psc_tflite_synap_batch(x,w,1,k,n,tile,dot,p);
}
