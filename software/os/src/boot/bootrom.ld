ENTRY(_start)

MEMORY {
    BRAM (rx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS {
    .text : ALIGN(4) {
        *(.text*)
        *(.rodata*)
    } > BRAM
    .bss (NOLOAD) : ALIGN(16) {
        *(.bss .bss.* .sbss .sbss.*);
        __mbios_ram_end = .;
    } > BRAM
    ASSERT(__mbios_ram_end <= 0x00040000, "MBIOS stack overlaps Tensor Arena")
    ASSERT(SIZEOF(.text) <= 512, "MBIOS exceeds the hardware 128-word ROM")
}
