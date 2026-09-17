ENTRY(boot)

SECTIONS {
    . = 0x80000000;   /* QEMU virt -bios none の初期PCと一致 */

    __kernel_base = .;

    .text : {
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

    /* stack */
    . = ALIGN(4);
    . += 128 * 1024;
    __stack_top = .;

    /* free RAM */
    . = ALIGN(4096);
    __free_ram = .;
    . += 64 * 1024 * 1024;
    __free_ram_end = .;
}
