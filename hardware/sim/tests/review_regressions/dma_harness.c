
#include <stdint.h>
#include <stddef.h>
#include <assert.h>
#include <stdio.h>
#include <string.h>
#define CSR_DMA_CTRL 0x7e0
#define CSR_DMA_WORDS 0x7e4
#define CSR_DMA_SRC 0x7e8
#define CSR_DMA_DST 0x7ec
static uint32_t words, source, dest, status, start;
static unsigned starts, polls, clears;
static uint8_t src_buf[128] __attribute__((aligned(16)));
static uint8_t dst_buf[128] __attribute__((aligned(16)));
static void csr_write(uint32_t csr, uint32_t value) {
    switch(csr) {
    case CSR_DMA_WORDS: words=value; break;
    case CSR_DMA_SRC: source=value; break;
    case CSR_DMA_DST: dest=value; break;
    case CSR_DMA_CTRL:
        start=value;
        if(value) { assert(words>0); starts++; polls=0; }
        break;
    default: assert(0);
    }
}
static uint32_t csr_read_dma_status(void) {
    // Start is delayed; old done may still be high until acceptance.
    if(start && ++polls>=3) status=2;
    if(!start && status==2 && ++polls>=7) {
        memcpy((void*)(uintptr_t)dest,(void*)(uintptr_t)source,words*4);
        status=1;
    }
    return status;
}
static void dcache_clear(void) { assert(status==1 && polls>=7); clears++; }
/* The runner inserts the production dma_memcpy definition here. */
/* @DMA_FUNCTION@ */
int main(void) {
    for(unsigned so=0;so<4;so++) for(unsigned d=0;d<4;d++) for(unsigned n=0;n<=65;n++) {
        for(unsigned i=0;i<128;i++) { src_buf[i]=(uint8_t)(i*17+3); dst_buf[i]=0xa5; }
        unsigned old_starts=starts, old_clears=clears;
        assert(dma_memcpy(dst_buf+16+d,src_buf+16+so,n)==dst_buf+16+d);
        assert(!memcmp(dst_buf+16+d,src_buf+16+so,n));
        for(unsigned i=0;i<16+d;i++) assert(dst_buf[i]==0xa5);
        for(unsigned i=16+d+n;i<128;i++) assert(dst_buf[i]==0xa5);
        unsigned expected=(so==0 && d==0 && n>=4);
        assert(starts-old_starts==expected && clears-old_clears==expected);
    }
    puts("DMA C regression PASS (1056 size/alignment cases)");
}
