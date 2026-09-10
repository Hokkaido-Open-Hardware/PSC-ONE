#!/usr/bin/env python3
"""Exercise production LCD/MMIO sequence, syscall validation and timer logic.
Only platform includes and hardware register access are substituted in generated
host translation units, following the existing review_regressions convention.
"""
from pathlib import Path
import re
import subprocess
OS = Path(__file__).resolve().parents[2]
BUILD = OS / 'build/jpeg_boundaries'
BUILD.mkdir(parents=True, exist_ok=True)

def test(name, source):
    path = BUILD / (name + '.c')
    path.write_text(source)
    exe = BUILD / name
    subprocess.run(['gcc','-std=c11','-D_GNU_SOURCE','-O1','-fno-builtin','-fno-pie','-no-pie','-Wl,-Ttext-segment=0x20000000','-I'+str(OS / 'src'),str(path),'-o',str(exe)],check=True)
    subprocess.run([str(exe)],check=True,timeout=20)

lcd = (OS / 'src/lcd_api.c').read_text()
lcd = re.sub(r'^#include .*\n', '', lcd, flags=re.M)
test('lcd', r'''
#include <stdint.h>
#include "jpeg_display.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#define CHECK(c) do { if (!(c)) { fprintf(stderr,"LCD line %d\n",__LINE__); abort(); } } while(0)
static uint32_t mmio_data, status=1, words[4096], used;
static int stalled;
static volatile uint32_t *status_ptr(void) {
    if (status == 3) { CHECK(used < 4096); words[used++] = mmio_data; }
    status = stalled ? 0 : 1;
    return &status;
}
#define PSC_LCD_PIXS_DATA mmio_data
#define PSC_LCD_PIXS_ST (*status_ptr())
static const uint8_t boot_logo[480*320];
static const uint16_t font12x12[95][12];
void s_printf(const char *fmt, ...) { (void)fmt; }
void lcd_clear(void); void lcd_set_cursor(uint32_t,uint32_t); void lcd_puts(const char *);
''' + lcd + r'''
int main(void) {
    CHECK(lcd_begin_rgb888() == 0); status_ptr();
    const uint32_t begin[] = {0x3a,0x166,0x36,0x1e8,0x33,0x100,0x100,0x101,0x1e0,0x100,0x100,0x37,0x100,0x100};
    CHECK(used == sizeof(begin)/sizeof(begin[0]));
    for(unsigned i=0;i<used;i++) { if(words[i]!=begin[i]) fprintf(stderr,"word %u: %x expected %x\n",i,words[i],begin[i]); CHECK(words[i]==begin[i]); }
    uint8_t colors[] = {255,0,0, 0,255,0, 0,0,255, 255,255,255, 0,0,0};
    used=0;
    CHECK(lcd_write_rgb888_rect(475,319,5,1,colors)==0);
    const uint32_t window[] = {0x2a,0x101,0x1db,0x101,0x1df,0x2b,0x101,0x13f,0x101,0x13f,0x2c};
    CHECK(used==11+15);
    for(unsigned i=0;i<11;i++) CHECK(words[i]==window[i]);
    for(unsigned i=0;i<15;i++) CHECK(words[11+i]==(0x100u | (255-colors[i])));
    used=0;
    CHECK(lcd_write_rgb888_rect(479,319,2,1,colors)==-1 && used==0);
    CHECK(lcd_write_rgb888_rect(0xffffffffu,0,1,1,colors)==-1 && used==0);
    CHECK(lcd_write_rgb888_rect(0,0,0,1,colors)==-1 && used==0);
    CHECK(lcd_write_rgb888_rect(0,0,17,1,colors)==-1 && used==0);
    CHECK(lcd_write_rgb888_rect(0,319,1,2,colors)==-1 && used==0);
    CHECK(lcd_write_rgb888_rect(480,0,1,1,colors)==-1 && used==0);
    CHECK(lcd_write_rgb888_rect(0,320,1,1,colors)==-1 && used==0);
    stalled=1;
    CHECK(lcd_begin_rgb888()==-1);
    CHECK(lcd_write_rgb888_rect(0,0,1,1,colors)==-1);
    puts("LCD register sequence, colours, bounds and timeout PASS");
}
''')

src = (OS / 'src/kernel_syscall.c').read_text()
helper = src[src.index('static int lcd_user_readable'):src.index('void handle_syscall')]
start = src.index('    case SYS_LCD_RGB888_BEGIN:')
end = src.index('    case SYS_TIMER_MEASURE_BEGIN:', start)
cases = src[start:end]
test('syscall', r'''
#include <stdint.h>
#include "jpeg_display.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#define CHECK(c) do { if (!(c)) { fprintf(stderr,"syscall line %d\n",__LINE__); abort(); } } while(0)
#define USER_BASE 0x400000u
#define USER_STACK_TOP 0x500000u
#define PAGE_SIZE 4096u
#define PAGE_V 1
#define PAGE_R 2
#define PAGE_W 4
#define PAGE_X 8
#define PAGE_U 16
#define SYS_LCD_RGB888_BEGIN 92
#define SYS_LCD_RGB888_RECT 93
struct process { uint32_t *page_table; };
static uint32_t l1[1024] __attribute__((aligned(4096))), l0[1024] __attribute__((aligned(4096)));
static struct process proc = {l1}, *current_proc = &proc;
struct trap_frame { uint32_t a0,a1,a2,a3,a4,a5; };
int lcd_begin_rgb888(void) { return 0; }
int lcd_write_rgb888_rect(uint32_t x,uint32_t y,uint32_t w,uint32_t h,const uint8_t *p) { return 0; }
''' + helper + '\nstatic void rect_call(struct trap_frame *f) { switch(f->a3) {\n' + cases + r'''
} }
int main(void) {
    l1[1] = ((uint32_t)(uintptr_t)l0 >> 12) << 10 | PAGE_V;
    l0[0] = PAGE_V | PAGE_R | PAGE_U;
    CHECK(lcd_user_readable(USER_BASE,768));
    CHECK(!lcd_user_readable(USER_BASE+4090,16));
    l0[1] = PAGE_V | PAGE_R | PAGE_U;
    CHECK(lcd_user_readable(USER_BASE+4090,16));
    CHECK(!lcd_user_readable(USER_BASE-1,4));
    CHECK(!lcd_user_readable(USER_STACK_TOP-1,4));
    CHECK(!lcd_user_readable(USER_BASE,0xffffffffu));
    l0[0] = PAGE_V | PAGE_R; CHECK(!lcd_user_readable(USER_BASE,1));
    l0[0] = PAGE_V | PAGE_U; CHECK(!lcd_user_readable(USER_BASE,1));
    struct trap_frame f = {0,0,16,SYS_LCD_RGB888_RECT,16,USER_BASE};
    rect_call(&f); CHECK((int)f.a0 == -1);
    f.a0=0; f.a2=0xffffffffu; rect_call(&f); CHECK((int)f.a0 == -1);
    CHECK(mmap((void *)USER_BASE, PAGE_SIZE, PROT_READ|PROT_WRITE,
               MAP_PRIVATE|MAP_ANONYMOUS|MAP_FIXED_NOREPLACE,-1,0) == (void *)USER_BASE);
    l0[0] = PAGE_V | PAGE_R | PAGE_U;
    f = (struct trap_frame){464,304,16,SYS_LCD_RGB888_RECT,16,USER_BASE};
    rect_call(&f); CHECK(f.a0 == 0);
    f = (struct trap_frame){479,319,1,SYS_LCD_RGB888_RECT,1,USER_BASE};
    rect_call(&f); CHECK(f.a0 == 0);
    const uint32_t bad[][4] = {{479,319,2,1},{479,319,1,2},{480,0,1,1},
                              {0,320,1,1},{0xffffffffu,0,1,1},{0,0xffffffffu,1,1}};
    for(unsigned i=0;i<sizeof(bad)/sizeof(bad[0]);i++) {
        f=(struct trap_frame){bad[i][0],bad[i][1],bad[i][2],SYS_LCD_RGB888_RECT,bad[i][3],USER_BASE};
        rect_call(&f); CHECK((int)f.a0 == -1);
    }
    puts("LCD syscall Sv32/page/landscape bounds validation PASS");
}
''')

timer = (OS / 'src/timer_measure.c').read_text()
timer = re.sub(r'^#include .*\n|^#define MEASURE_CTRL .*\n', '', timer, flags=re.M)
timer = re.sub(r'MEASURE_CTRL = ([^;]+);', r'test_write(\1);', timer)
test('timer', r'''
#include <stdint.h>
#include "jpeg_display.h"
#include <stdio.h>
#include <stdlib.h>
#define TIMER_ST_RUNNING (1u<<7)
#define TIMER_ST_IRQ_ENABLE (1u<<9)
#define TIMER_ST_IRQ_PENDING (1u<<10)
#define CHECK(c) do { if (!(c)) { fprintf(stderr,"timer line %d\n",__LINE__); abort(); } } while(0)
static uint32_t st, cnt, writes, enabled;
void enable_machine_timer_trap(void) { enabled++; }
uint32_t timer_get_status(void) { return st; }
uint32_t timer_get_count(void) { return cnt; }
void timer_stop(void) { st &= ~(TIMER_ST_RUNNING | TIMER_ST_IRQ_ENABLE); }
static void test_write(uint32_t v) {
    writes++;
    if(v & (1u<<16)) { cnt=v&65535; st |= TIMER_ST_RUNNING; }
    if(v & (1u<<18)) st |= TIMER_ST_IRQ_ENABLE; else st &= ~TIMER_ST_IRQ_ENABLE;
    if(v & (1u<<19)) st &= ~TIMER_ST_RUNNING;
    if(v & (1u<<20)) st &= ~TIMER_ST_IRQ_PENDING;
}
''' + timer + r'''
int main(void) {
    st=TIMER_ST_RUNNING; CHECK(timer_measure_begin()==-1 && writes==0 && enabled==0);
    st=0; CHECK(timer_measure_begin()==0 && enabled==1);
    CHECK(timer_measure_begin()==-1);
    for(unsigned i=0;i<3;i++) { st |= TIMER_ST_IRQ_PENDING; CHECK(timer_measure_irq()==1); }
    cnt=49999-12345; CHECK(timer_measure_end()==162 && st==0);
    CHECK(timer_measure_end()==-1 && timer_measure_irq()==0);
    CHECK(timer_measure_begin()==0);
    st |= TIMER_ST_IRQ_PENDING; cnt=49999-7000;
    CHECK(timer_measure_end()==57 && st==0);
    puts("Timer extension, pending wrap, repeated use and busy preservation PASS");
}
''')
