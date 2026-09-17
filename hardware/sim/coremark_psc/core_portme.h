#ifndef PSC_CORE_PORTME_H
#define PSC_CORE_PORTME_H

#include <stddef.h>

/* Integer-only target output; support.py computes fractional scores from ticks. */
#define HAS_FLOAT 0
#define HAS_TIME_H 0
#define USE_CLOCK 0
#define HAS_STDIO 0
#define HAS_PRINTF 0
#define COMPILER_VERSION "GCC " __VERSION__
#define COMPILER_FLAGS FLAGS_STR
#define MEM_LOCATION "STATIC in SDRAM; code in SDRAM; existing I/D caches"

typedef signed short ee_s16;
typedef unsigned short ee_u16;
typedef signed int ee_s32;
typedef unsigned int ee_u32;
typedef unsigned char ee_u8;
typedef double ee_f32;
typedef unsigned int ee_ptr_int;
typedef size_t ee_size_t;
typedef ee_u32 CORE_TICKS;
#define align_mem(x) ((void *)(((ee_ptr_int)(x) + 3u) & ~3u))
#define SEED_METHOD SEED_VOLATILE
#define MEM_METHOD MEM_STATIC
#define MULTITHREAD 1
#define MAIN_HAS_NOARGC 1
#define MAIN_HAS_NORETURN 0

extern ee_u32 default_num_contexts;
typedef struct { ee_u8 portable_id; } core_portable;
void portable_init(core_portable *p, int *argc, char *argv[]);
void portable_fini(core_portable *p);
int ee_printf(const char *fmt, ...);
#endif
