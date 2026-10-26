ENTRY(boot)

/* PSC 8MiB SDRAM physical layout (exclusive ends).
 *   00000000..00040000  MBIOS / M stack / existing NPU DMA buffers
 *   00040000..00100000  Tensor Arena (separate user VA mapping)
 *   00100000..00140000  FAT32 bootloader and its stack/reserve
 *   00140000..00200000  model backing, low part
 *   00200000..00400000  kernel, S stack and process page pool
 *   00400000..004c0000  direct-boot USER.MEM source reservation
 *   004c0000..00800000  model backing, high part
 *
 * Model VA 00800000..00c00000 is stitched from the two model ranges.
 * Arena VA 00c00000..00cc0000 maps only the separate Arena range.
 * Neither region is allocated from the process page pool. Large-model
 * support is required for SD boot; direct USER.MEM boot retains its source
 * reservation for small-model regression and warm restart.
 */
__sdram_end          = 0x00800000;
__bootloader_base    = 0x00100000;
__kernel_origin     = 0x00200000;
__user_image_base    = 0x00400000;
__user_image_limit   = 0x004c0000;

__arena_start       = 0x00040000;
__arena_end         = __bootloader_base;
__arena_size        = 768 * 1024;

__model_low         = 0x00140000;
__model_low_end     = __kernel_origin;
__model_high        = __user_image_limit;
__model_size        = 4 * 1024 * 1024;
__model_high_end    = __model_high + __model_size - (__model_low_end - __model_low);

__kernel_stack_size = 128 * 1024;
__page_pool_size    = 1 * 1024 * 1024;
__shell_stack_size  = 128 * 1024;
__boot_table_budget = 8 * 4096;

SECTIONS {
    . = __kernel_origin;
    __kernel_base = .;

    .text : {
        KEEP(*(.text.boot));
        *(.text .text.*);
    }
    .rodata : ALIGN(4) {
        *(.rodata .rodata.*);
    }
    .data : ALIGN(4) {
        __data = .;
        *(.data .data.* .sdata .sdata.*);
        __data_end = .;
    }

    /* Warm restart restores initialized data from this cold-boot snapshot.
       Keep it outside BSS and outside the page allocator. */
    .restart_data (NOLOAD) : ALIGN(16) {
        __data_initial = .;
        . += SIZEOF(.data);
    }
    .bss : ALIGN(4) {
        __bss = .;
        *(.bss .bss.* .sbss .sbss.*);
        __bss_end = .;
    }

    . = ALIGN(16);
    . += __kernel_stack_size;
    __kernel_stack_top = .;

    /* SD boot copies USER.MEM directly into allocated process pages.
       Keep identity-mapped kernel allocations below the user VA window. */
    . = ALIGN(4096);
    __free_ram = .;
    __free_ram_end = MIN(__free_ram + __page_pool_size, USER_BASE);
}

/* Fixed reservations: also checked against actual ELF symbols by
   tests/tflite/memory_layout.py. The bootloader/MBIOS scripts enforce
   their own upper bounds, since their sections are separate ELF files. */
ASSERT(__arena_start >= 0x00030000 + 64 * 64 * 4, "Arena overlaps NPU result")
ASSERT(__arena_end - __arena_start == __arena_size, "Arena size mismatch")
ASSERT(__arena_end <= __bootloader_base, "Arena overlaps bootloader")
ASSERT(__kernel_base >= __model_low_end, "kernel overlaps model backing")
ASSERT(__model_high_end == __sdram_end, "model backing exceeds 8MiB SDRAM")
ASSERT(__shell_image_size <= __user_image_limit - __user_image_base,
       "USER.MEM overlaps model backing")

/* Kernel/process boot budget, including page rounding and separate stack. */
ASSERT(__free_ram < __free_ram_end, "kernel overlaps user virtual range")
ASSERT(__free_ram_end <= __user_image_base, "page pool overlaps model/source")
ASSERT(__free_ram + ALIGN(__shell_image_size, 4096)
       + __shell_stack_size + __boot_table_budget <= __free_ram_end,
       "insufficient page pool for shell and stack")
