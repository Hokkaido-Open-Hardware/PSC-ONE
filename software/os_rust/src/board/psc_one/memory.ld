/* PSC-ONE physical reservations and user ABI. Ends are exclusive.
 * The kernel reads USER.MEM from SD into contiguous allocated process pages
 * below __kernel_limit, never staged at physical 0x00400000.
 * Model backing remains split to preserve the existing 4 MiB model mapping. */
__kernel_origin = 0x00200000;
__kernel_limit = 0x00400000;
__user_base = 0x00400000;
__user_stack_top = 0x00500000;
__user_stack_size = 128 * 1024;
__user_stack_guard = 4096;
__kernel_stack_size = 128 * 1024;
__page_pool_size = 1024 * 1024;
__arena_start = 0x00040000;
__arena_end = 0x00100000;
__model_low = 0x00140000;
__model_low_end = 0x00200000;
__model_high = 0x004c0000;
__model_high_end = 0x00800000;
