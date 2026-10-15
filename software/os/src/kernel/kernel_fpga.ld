ENTRY(boot)

SECTIONS {
    . = 0x00200000;     /* 2MB */
    __kernel_base = .;

    .text :{
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

    /* Cold-boot snapshot, outside BSS and the allocator. Warm restart keeps
       the resident text/shell images and restores writable initializers. */
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
    . += 128 * 1024; /* 128KB */
    __kernel_stack_top = .;

    . = ALIGN(4096);
    __free_ram = .;
    /* Keep kernel identity mappings below the user virtual range.
       SD chunks go directly to allocated process pages, with no staging image. */
    __free_ram_end = MIN(__free_ram + 1 * 1024 * 1024,
                         USER_BASE);
    ASSERT(__free_ram < __free_ram_end, "kernel overlaps user virtual range")
    /* Shell copy + separately mapped stack + page tables for idle/shell. */
    ASSERT(__free_ram + ALIGN(__shell_image_size, 4096)
           + 128 * 1024 + 8 * 4096 <= __free_ram_end,
           "insufficient page pool for shell and stack")
}
