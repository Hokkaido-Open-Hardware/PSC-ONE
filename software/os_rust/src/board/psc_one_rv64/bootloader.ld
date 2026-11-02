ENTRY(bootloader_entry)
SECTIONS {
    . = 0x00100000;
    .text : { KEEP(*(.text.bootloader)) *(.text .text.*) }
    .rodata : ALIGN(16) { *(.rodata .rodata.*) }
    .data : ALIGN(16) { *(.data .data.* .sdata .sdata.*) }
    ASSERT(. - 0x00100000 <= 4500 * 4, "RV64 FAT32 loader exceeds boot storage")
    .bss (NOLOAD) : ALIGN(16) {
        __bss = .; *(.bss .bss.* .sbss .sbss.*) __bss_end = .;
    }
    . = ALIGN(16);
    . += 16384;
    _stack_top = .;
    ASSERT(. <= 0x00140000, "bootloader overlaps model backing")
    /DISCARD/ : { *(.eh_frame*) *(.comment) }
}
