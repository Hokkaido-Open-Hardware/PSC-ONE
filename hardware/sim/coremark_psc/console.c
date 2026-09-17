/* CoreMark's integer format subset adapted to PSC-OS s_printf.
 * No UART driver or number conversion is duplicated here. CoreMark does
 * not inspect ee_printf's return value. Hex output uses s_printf's eight
 * digit width, including for upstream's %04x CRC fields. */
#include "common.h"
extern void uart_putchar(char ch);

int ee_printf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    while (*fmt) {
        if (*fmt++ != '%') {
            uart_putchar(fmt[-1]);
            continue;
        }
        while (*fmt >= '0' && *fmt <= '9') ++fmt;
        int is_long = (*fmt == 'l');
        if (is_long) ++fmt;
        switch (*fmt++) {
        case '%': uart_putchar('%'); break;
        case 's': s_printf("%s", va_arg(args, const char *)); break;
        case 'd': s_printf("%d", va_arg(args, int)); break;
        case 'x': s_printf("%x", va_arg(args, unsigned int)); break;
        case 'u': {
            unsigned int v = is_long ? (unsigned int)va_arg(args, unsigned long)
                                     : va_arg(args, unsigned int);
            if (v > 0x7fffffffu) s_printf("%d%d", v / 10u, v % 10u);
            else s_printf("%d", (int)v);
            break;
        }
        default:
            s_printf("ERROR! Unsupported CoreMark console format\n");
            for (;;) { }
        }
    }
    va_end(args);
    return 0;
}
