ENTRY(boot)

SECTIONS {
    . = 0x80200000;
    __kernel_base = .;

    .text :{
        KEEP(*(.text.boot));
        *(.text .text.*);
    }

    .rodata : ALIGN(4) {
        *(.rodata .rodata.*);
    }

    .data : ALIGN(4) {
        *(.data .data.*);
    }

    .bss : ALIGN(4) {
        __bss = .;
        *(.bss .bss.* .sbss .sbss.*);
        __bss_end = .;
    }

    . = ALIGN(4);
    . += 128 * 1024; /* 128KB */
    __stack_top = .;

    . = ALIGN(4096);
    __free_ram = .;
    . += 64 * 1024 * 1024; /* 64MB */
    __free_ram_end = .;
    /* QEMU RAM backing, separate from the existing page allocator. */
    __model_low = ALIGN(__free_ram_end, 4096);
    __model_low_end = __model_low + 0x00400000;
    __model_high = __model_low_end;
    __arena_start = __model_low_end;
    __arena_end = __arena_start + 0x000c0000;
    ASSERT(__arena_end <= 0x88000000, "model exceeds QEMU 128MiB RAM")
}