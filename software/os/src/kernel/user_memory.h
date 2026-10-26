#pragma once

/* Shared with user.ld (USER_BASE is supplied by the OS Makefile). */
#ifndef USER_BASE
#define USER_BASE 0x00400000u
#endif
#define USER_STACK_TOP   (USER_BASE + 0x00100000u)
#define USER_STACK_SIZE  (128 * 1024)
#define USER_STACK_GUARD (4 * 1024)

/* Dedicated model VA, outside the shell image/stack window. Physical backing
   is reserved by the kernel linker, not taken from alloc_pages(). */
#define USER_MODEL_BASE (USER_BASE + 0x00400000u)
#define USER_MODEL_SIZE 0x00400000u

/* Independent 768KiB Arena; PA 0x40000..0x100000 in PSC SDRAM. */
#define USER_ARENA_BASE 0x00c00000u
#define USER_ARENA_SIZE 0x000c0000u
