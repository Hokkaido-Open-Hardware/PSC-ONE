#include "common.h"

void *memcpy(void *dst, const void *src, size_t n) {
    uint8_t *d = (uint8_t *) dst;
    const uint8_t *s = (const uint8_t *) src;
    while (n--)
        *d++ = *s++;
    return dst;
}

int memcmp(const void *a, const void *b, size_t n)
{
    const uint8_t *p1 = (const uint8_t *)a;
    const uint8_t *p2 = (const uint8_t *)b;

    while (n--) {
        if (*p1 != *p2)
            return (int)*p1 - (int)*p2;
        p1++;
        p2++;
    }

    return 0;
}

#if 1
void *memset(void *buf, char c, size_t n) {
    uint8_t *p = (uint8_t *) buf;
    while (n--)
        *p++ = c;
    return buf;
}
#else
void *memset(void *buf, char c, size_t n)
{
    uint8_t *p = (uint8_t *)buf;
    size_t total = n;
    size_t count = 0;

    s_printf("memset start n=%x\n", (uint32_t)n);

    while (n--) {

        *p++ = (uint8_t)c;
        count++;

        if ((count & 0xFFF) == 0) {
            s_printf(
                "memset %x/%x\n",
                (uint32_t)count,
                (uint32_t)total
            );
        }
    }

    s_printf("memset end\n");

    return buf;
}
#endif

/*
// 将来的に使用したいVer.
void *memset(void *dst, int c, size_t n) {
    uint32_t v = (uint8_t)c;
    v |= v << 8;
    v |= v << 16;

    uint32_t *d = dst;
    while (n >= 4) {
        *d++ = v;
        n -= 4;
    }

    uint8_t *db = (uint8_t *)d;
    while (n--) {
        *db++ = (uint8_t)c;
    }
    return dst;
}
*/

void uart_putchar(char ch);

/* u / 10 と u % 10 を同時に計算（最大32ループ） */
static uint32_t divmod10(uint32_t u, uint32_t *rem)
{
    uint32_t q = 0;
    uint32_t r = 0;

    for (int i = 31; i >= 0; --i) {
        r = (r << 1) | ((u >> i) & 1u);
        if (r >= 10u) {
            r -= 10u;
            q |= (1u << i);
        }
    }

    *rem = r;
    return q;
}

void s_print_int(int v)
{
    uint32_t u;
    char buf[10];
    int idx = 0;

    if (v < 0) {
        uart_putchar('-');
        u = (uint32_t)(-(v + 1)) + 1u;
    } else {
        u = (uint32_t)v;
    }

    if (u == 0) {
        uart_putchar('0');
        return;
    }

    while (u != 0) {
        uint32_t rem;
        u = divmod10(u, &rem);
        buf[idx++] = (char)('0' + rem);
    }

    while (idx > 0) {
        uart_putchar(buf[--idx]);
    }
}

/* ================================================================
 * s_printf
 * ================================================================ */
void s_printf(const char *fmt, ...) {
    va_list vargs;
    va_start(vargs, fmt);

    while (*fmt) {
        if (*fmt == '%') {
            fmt++;
            switch (*fmt) {
                case '\0':
                    uart_putchar('%');
                    goto end;
                case '%':
                    uart_putchar('%');
                    break;
                case 's': {
                    const char *s = va_arg(vargs, const char *);
                    while (*s) {
                        uart_putchar(*s);
                        s++;
                    }
                    break;
                }
                case 'd': {  // Print an integer in decimal (safe version)
                    int value = va_arg(vargs, int);

                    unsigned int u;
                    if (value < 0) {
                        uart_putchar('-');
                        // INT_MIN 対策：符号反転を unsigned で行う 
                        u = (unsigned int)(-(value + 1)) + 1;
                    } else {
                        u = (unsigned int)value;
                    }

                    // 逆順に数字を溜める 
                    char buf[11];   // int32 max: 10 digits + '\0' not needed
                    int i = 0;

                    // 0 の特別扱い 
                    if (u == 0) {
                        uart_putchar('0');
                        break;
                    }

                    while (u > 0) {
                        buf[i++] = '0' + (u % 10);
                        u /= 10;
                    }

                    // 正順に出力 
                    while (i > 0) {
                        uart_putchar(buf[--i]);
                    }
                    break;
                }
                case 'x': { // Print an integer in hexadecimal.
                    unsigned value = va_arg(vargs, unsigned);
                    for (int i = 7; i >= 0; i--) {
                        unsigned nibble = (value >> (i * 4)) & 0xf;
                        uart_putchar("0123456789abcdef"[nibble]);
                    }
                }
            }
        } else {
            uart_putchar(*fmt);
        }

        fmt++;
    }

end:
    va_end(vargs);
}

/* ================================================================
 * Hexdump utilities & "dump" command (virtual address space)
 * ================================================================ */

/* 2桁HEX出力 */
static inline void print_hex8(uint8_t v) {
    static const char HEX[] = "0123456789abcdef";
    uart_putchar(HEX[v >> 4]);
    uart_putchar(HEX[v & 0x0F]);
}

/* 8桁HEX出力（アドレス表示用） */
static inline void print_hex32(uint32_t v) {
    for (int i = 7; i >= 0; --i) {
        uint8_t nib = (v >> (i * 4)) & 0x0F;
        static const char HEX[] = "0123456789abcdef";
        uart_putchar(HEX[nib]);
    }
}

/* 簡易16進パーサ（"  0x1234" / "1234" 形式どちらも可） */
int parse_hex(const char *s, uintptr_t *out) {
    uintptr_t v = 0;

    /* skip leading spaces */
    while (*s == ' ' || *s == '\t') s++;

    /* optional 0x / 0X */
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s += 2;
    if (!*s) return -1;

    while (*s) {
        char c = *s++;
        uint32_t d;
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
        else if (c >= 'a' && c <= 'f') d = 10u + (uint32_t)(c - 'a');
        else if (c >= 'A' && c <= 'F') d = 10u + (uint32_t)(c - 'A');
        else break;
        v = (v << 4) | d;
    }
    *out = v;
    return 0;
}

/* 汎用hexdump本体：
 *  - addr: 先頭アドレス（今のページテーブルで有効な仮想アドレス）
 *  - len : ダンプ長
 *  - base_addr_label: 行頭に表示するベースアドレス（通常は addr と同じ）
 */
void hexdump(const void *addr, size_t len, uintptr_t base_addr_label) {
    const uint8_t *p = (const uint8_t *)addr;
    size_t off = 0;

    while (off < len) {
        size_t line = (len - off > 16) ? 16 : (len - off);

        /* 行頭: アドレス表示 */
        print_hex32((uint32_t)(base_addr_label + off));
        s_printf(": ");

        /* HEX部（16B固定幅） */
        for (size_t i = 0; i < 16; i++) {
            if (i < line) {
                print_hex8(p[off + i]);
            } else {
                /* 足りない分はスペースで穴埋め */
                uart_putchar(' ');
                uart_putchar(' ');
            }
            uart_putchar(' ');
            if (i == 7) uart_putchar(' '); /* 8バイト境界でスペース追加 */
        }

        /* ASCII部 */
        uart_putchar(' ');
        uart_putchar('|');
        for (size_t i = 0; i < line; i++) {
            uint8_t c = p[off + i];
            uart_putchar((c >= 0x20 && c <= 0x7e) ? (char)c : '.');
        }
        uart_putchar('|');
        uart_putchar('\n');

        off += line;
    }
}

void cmd_dump(int argc, const char **argv) {
    const uintptr_t DEFAULT_BASE = 0x00000000u;  /* 0x0000とする */
    const size_t    DEFAULT_LEN  = 0x100u;
    const size_t    MAX_LEN      = 0x1000u;      /* 誤爆防止の上限 */

    uintptr_t addr = DEFAULT_BASE;
    size_t    len  = DEFAULT_LEN;

    if (argc >= 1 && argv && argv[0] && argv[0][0]) {
        uintptr_t offset = 0;
        if (parse_hex(argv[0], &offset) != 0) {
            s_printf("usage: dmp [offset_hex] [len_hex]\n");
            return;
        }
        addr = DEFAULT_BASE + offset;
    }
    if (argc >= 2 && argv && argv[1] && argv[1][0]) {
        uintptr_t lhex = 0;
        if (parse_hex(argv[1], &lhex) != 0) {
            s_printf("usage: dump [offset_hex] [len_hex]\n");
            return;
        }
        len = (size_t)lhex;
    }

    if (len == 0) {
        len = DEFAULT_LEN;
    } else if (len > MAX_LEN) {
        s_printf("[info] len too big (>0x%X), round down to 0x%X\n",
               (unsigned)MAX_LEN, (unsigned)MAX_LEN);
        len = MAX_LEN;
    }

    hexdump((const void *)addr, len, addr);
}