#ifndef PSC_STDIO_H
#define PSC_STDIO_H

#include <stddef.h>
#include <stdarg.h>

int printf(const char *fmt, ...);
int snprintf(char *str, size_t size, const char *fmt, ...);
int vsnprintf(char *str, size_t size, const char *fmt, va_list ap);
int puts(const char *s);
int putchar(int c);

#endif
