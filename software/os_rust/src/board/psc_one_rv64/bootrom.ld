ENTRY(mbios_entry)
SECTIONS {
    . = 0;
    .text : { KEEP(*(.text.mbios)) *(.text .text.*) *(.rodata .rodata.*) }
    ASSERT(SIZEOF(.text) <= 512, "RV64 MBIOS exceeds 128-word ROM")
    /* Writable stack in low RAM, outside the boot ROM and NPU buffers. */
    . = 0x00010000;
    .bss (NOLOAD) : ALIGN(16) { *(.bss .bss.* .sbss .sbss.*) }
    ASSERT(. <= 0x00020000, "MBIOS stack overlaps NPU buffers")
    /DISCARD/ : { *(.eh_frame*) *(.comment) }
}
