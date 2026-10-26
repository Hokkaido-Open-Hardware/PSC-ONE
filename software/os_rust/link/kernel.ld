/* Resident FPGA kernel: identity mappings must stay below the user VA region. */
ENTRY(boot)
/* Same split physical backing as os/src/kernel/kernel_fpga.ld. */
__arena_start = 0x00040000;
__arena_end = 0x00100000;
__model_low = 0x00140000;
__model_low_end = 0x00200000;
__model_high = 0x004c0000;
__model_high_end = 0x00800000;
ASSERT(__shell_image_size <= 0x000c0000, "USER.MEM overlaps model backing")
ASSERT(__model_low_end - __model_low + __model_high_end - __model_high == 0x00400000,
       "model backing size mismatch")
ASSERT(__arena_end - __arena_start == 768 * 1024, "arena backing size mismatch")
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
