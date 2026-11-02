/* Resident FPGA kernel: identity mappings must stay below the user VA region. */
ENTRY(boot)
/* Same split physical backing as os/src/kernel/kernel_fpga.ld. */
INCLUDE memory.ld
ASSERT(__model_low_end - __model_low + __model_high_end - __model_high == 0x00400000,
       "model backing size mismatch")
ASSERT(__arena_end - __arena_start == 768 * 1024, "arena backing size mismatch")
ASSERT(__kernel_origin >= __model_low_end, "kernel overlaps low model backing")
ASSERT(__kernel_limit <= __user_base, "kernel identity mappings overlap user VA")
ASSERT(__kernel_limit <= __model_high, "kernel overlaps high model backing")
SECTIONS {
    . = __kernel_origin;
    __kernel_base = .;
    .text : { KEEP(*(.text.boot)) *(.text .text.*) }
    .rodata : ALIGN(16) { *(.rodata .rodata.*) }
    .data : ALIGN(16) {
        __data = .;
        *(.data .data.* .sdata .sdata.*)
        __data_end = .;
    }
    __kernel_file_end = .;
    .restart_data (NOLOAD) : ALIGN(16) {
        __data_initial = .;
        . += SIZEOF(.data);
    }
    .bss (NOLOAD) : ALIGN(16) {
        __bss = .;
        *(.bss .bss.* .sbss .sbss.*) *(COMMON)
        __bss_end = .;
    }
    . = ALIGN(16);
    . += __kernel_stack_size;
    __kernel_stack_top = .;
    /* USER.MEM is read from SD into allocated process pages at runtime. */
    . = ALIGN(4096);
    __free_ram = .;
    __free_ram_end = MIN(__free_ram + __page_pool_size, __kernel_limit);
    ASSERT(__shell_image_size <= __user_stack_top - __user_stack_size - __user_stack_guard - __user_base,
           "user image overlaps stack guard")
    ASSERT(__free_ram + ALIGN(__shell_image_size, 4096) + __user_stack_size + 8 * 4096 <= __free_ram_end,
           "insufficient page pool for stack and page tables")
    /DISCARD/ : { *(.eh_frame*) *(.comment) }
}
