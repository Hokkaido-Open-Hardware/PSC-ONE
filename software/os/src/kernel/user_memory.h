#pragma once

/* Shared with user.ld (USER_BASE is supplied by the OS Makefile). */
#ifndef USER_BASE
#define USER_BASE 0x00400000u
#endif
#define USER_STACK_TOP   (USER_BASE + 0x00100000u)
#define USER_STACK_SIZE  (128 * 1024)
#define USER_STACK_GUARD (4 * 1024)
