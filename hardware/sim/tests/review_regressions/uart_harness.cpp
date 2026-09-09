
#include <sys/mman.h>
#include <cassert>
#include <cstdint>
#include <cstdio>
extern "C" void run();
int main() {
    void *p=mmap(reinterpret_cast<void*>(0x10000000u),8192,PROT_READ|PROT_WRITE,
                 MAP_PRIVATE|MAP_ANONYMOUS|MAP_FIXED_NOREPLACE,-1,0);
    assert(p!=MAP_FAILED);
    auto *regs=static_cast<volatile uint32_t*>(p);
    run(); assert(regs[0x1000/4]==0);
    regs[1]='A'; regs[2]=2;
    run(); assert(regs[0]=='A' && regs[0x1000/4]=='A');
    puts("UART regression PASS (no RX and RX)");
}
