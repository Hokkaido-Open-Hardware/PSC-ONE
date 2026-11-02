#pragma once
#include "../board/board.h"

/* Shared with user.ld (USER_BASE is supplied by the OS Makefile). */
#ifndef USER_BASE
#define USER_BASE PSC_BOARD_USER_BASE
#endif
#define USER_STACK_TOP   (USER_BASE + PSC_BOARD_USER_STACK_OFFSET)
#define USER_STACK_SIZE  PSC_BOARD_USER_STACK_SIZE
#define USER_STACK_GUARD PSC_BOARD_USER_STACK_GUARD

/* Dedicated model VA, outside the shell image/stack window. Physical backing
   is reserved by the kernel linker, not taken from alloc_pages(). */
#define USER_MODEL_BASE (USER_BASE + PSC_BOARD_USER_MODEL_OFFSET)
#define USER_MODEL_SIZE PSC_BOARD_USER_MODEL_SIZE

/* Independent 768KiB Arena; PA 0x40000..0x100000 in PSC SDRAM. */
#define USER_ARENA_BASE PSC_BOARD_USER_ARENA_BASE
#define USER_ARENA_SIZE PSC_BOARD_USER_ARENA_SIZE
