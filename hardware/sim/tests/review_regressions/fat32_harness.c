
#include "fat32.h"
#include <setjmp.h>
extern int puts(const char *);
extern void abort(void);
#define CHECK(x) do { if (!(x)) { puts("FAT32 assertion failed: " #x); abort(); } } while(0)
static uint8_t disk[64][512], output[8192];
static unsigned output_count;
static int failed_sector = -1;
void putchar(char c) { CHECK(output_count < sizeof(output)); output[output_count++] = (uint8_t)c; }
void printf(const char *fmt, ...) { (void)fmt; }
int strcmp(const char *a, const char *b) { while (*a && *a == *b) {a++;b++;} return (unsigned char)*a - (unsigned char)*b; }
int call_sd_read_buf_api(uint32_t sector, void *out) {
    if (sector >= 64 || sector == (uint32_t)failed_sector) return -1;
    for (int i=0;i<512;i++) ((uint8_t*)out)[i] = disk[sector][i];
    return 0;
}
uint32_t call_sd_write_buf_api(uint32_t s, const uint8_t *b) { (void)s; (void)b; return 1; }
static void w32(uint8_t *b, uint32_t n) { for(int i=0;i<4;i++) b[i]=(uint8_t)(n>>(8*i)); }
static void entry(unsigned sec, unsigned slot, unsigned cluster, unsigned size) {
    uint8_t *e = &disk[sec][slot*32];
    const char *name = "TEST    PY ";
    for(int i=0;i<32;i++) e[i]=0;
    for(int i=0;i<11;i++) e[i]=(uint8_t)name[i];
    e[11]=0x20; e[26]=(uint8_t)cluster; w32(e+28,size);
}
static void full_directory(unsigned sector) { for(int i=0;i<16;i++) disk[sector][i*32]=0xe5; }
static void setup(void) {
    for(unsigned s=0;s<64;s++) for(unsigned i=0;i<512;i++) disk[s][i]=0;
    failed_sector=-1; output_count=0;
    w32(&disk[0][0x1c6],1);
    disk[1][13]=2; disk[1][14]=1; disk[1][16]=1;
    w32(&disk[1][36],1); w32(&disk[1][44],2);
    // FAT root directory: cluster 2 -> 5 -> EOC.
    w32(&disk[2][8],5); w32(&disk[2][20],0x0fffffff);
}
// Minimal MicroPython boundary; the runner inserts the actual psc_run body.
typedef const char *mp_obj_t;
#define PSC_PY_MAX_SIZE (4u * 1024u)
#define MP_ENOENT 2
#define MP_PARSE_FILE_INPUT 0
#define MP_ERROR_TEXT(x) x
#define mp_const_none ((mp_obj_t)0)
static jmp_buf exception;
static unsigned executed, rejected;
static const char *mp_obj_str_get_str(mp_obj_t name) { return name; }
static void mp_raise_OSError(int e) { (void)e; CHECK(0); }
static void mp_raise_ValueError(const char *s) { (void)s; rejected++; longjmp(exception,1); }
static void do_str(const char *s, int kind) { (void)s; (void)kind; executed++; }
/* @PSC_RUN_FUNCTION@ */
int main(void) {
    uint32_t cluster, size;
    setup(); entry(3,0,3,17);
    CHECK(fat32_find("TEST.PY",&cluster,&size)==0 && cluster==3 && size==17);
    setup(); full_directory(3); full_directory(4); entry(4,15,3,17);
    CHECK(fat32_find("TEST.PY",&cluster,&size)==0 && cluster==3);
    setup(); full_directory(3); full_directory(4); entry(9,0,3,17);
    CHECK(fat32_find("TEST.PY",&cluster,&size)==0 && cluster==3);
    // An end marker must stop search, even if later sectors contain a match.
    disk[3][0]=0; CHECK(fat32_find("TEST.PY",&cluster,&size)==-1);
    setup(); full_directory(3); full_directory(4); full_directory(9); full_directory(10);
    CHECK(fat32_find("TEST.PY",&cluster,&size)==-1);
    failed_sector=2; CHECK(fat32_find("TEST.PY",&cluster,&size)==-1);
    setup(); entry(3,0,3,1300);
    // File cluster 3 -> 7 (fragmented).
    w32(&disk[2][12],7); w32(&disk[2][28],0x0fffffff);
    for(unsigned i=0;i<1300;i++) {
        unsigned sec=i<1024 ? 5+i/512 : 13+(i-1024)/512;
        disk[sec][i%512]=(uint8_t)(i*17+3);
    }
    CHECK(fat32_cat("TEST.PY")==0 && output_count==1301);
    for(unsigned i=0;i<1300;i++) CHECK(output[i]==(uint8_t)(i*17+3));
    CHECK(output[1300]=='\n');
    output_count=0; failed_sector=13; CHECK(fat32_cat("TEST.PY")==-1);
    failed_sector=-1; w32(&disk[2][12],0x0fffffff); output_count=0;
    CHECK(fat32_cat("TEST.PY")==-1);
    setup(); entry(3,0,0,0); CHECK(fat32_cat("TEST.PY")==0 && output_count==1);
    // Probe used by psc.run: exact limit accepted, one extra byte detected.
    setup(); disk[1][13]=16; entry(3,0,3,4096);
    static uint8_t buf[4097];
    CHECK(fat32_read("TEST.PY",buf,sizeof(buf),&size)==0 && size==4096);
    w32(&disk[3][28],4608);
    CHECK(fat32_read("TEST.PY",buf,sizeof(buf),&size)==0 && size==4097);
    w32(&disk[3][28],4096);
    psc_run("TEST.PY"); CHECK(executed==1 && rejected==0);
    w32(&disk[3][28],4608);
    if (setjmp(exception)==0) { psc_run("TEST.PY"); CHECK(0); }
    CHECK(executed==1 && rejected==1);
    puts("FAT32 and psc.run regression PASS"); return 0;
}
