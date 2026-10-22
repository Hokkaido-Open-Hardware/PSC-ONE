/* Resident FPGA kernel: identity mappings must stay below the user VA region. */
ENTRY(boot)
SECTIONS {
    . = 0x00200000;
    __kernel_base = .;
    .text : { KEEP(*(.text.boot)) *(.text .text.*) }
    .rodata : ALIGN(16) { *(.rodata .rodata.*) }
    .data : ALIGN(16) {
        __data = .;
        *(.data .data.* .sdata .sdata.*)
        __data_end = .;
    }
    .restart_data (NOLOAD) : ALIGN(16) {
        __data_initial = .;
        . += SIZEOF(.data);
    }
    .bss : ALIGN(16) {
        __bss = .;
        *(.bss .bss.* .sbss .sbss.*) *(COMMON)
        __bss_end = .;
    }
    . = ALIGN(16);
    . += 128 * 1024;
    __kernel_stack_top = .;
    . = ALIGN(4096);
    __free_ram = .;
    __free_ram_end = MIN(__free_ram + 1024 * 1024, 0x00400000);
    /* Match the C simulator build: user.mem is loaded separately at USER_BASE.
       Copy it into allocated process pages before enabling address translation. */
    _binary_shell_bin_start = 0x00400000;
    _binary_shell_bin_end = _binary_shell_bin_start + __shell_image_size;
    ASSERT(__free_ram < __free_ram_end, "kernel overlaps user virtual range")
    ASSERT(__free_ram + ALIGN(__shell_image_size, 4096) + 128 * 1024 + 8 * 4096 <= __free_ram_end,
           "insufficient page pool for shell and stack")
    /DISCARD/ : { *(.eh_frame*) *(.comment) }
}
