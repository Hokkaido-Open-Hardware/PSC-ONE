ENTRY(_start)

MEMORY {
    BRAM (rx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS {
    .text : ALIGN(4) {
        *(.text*)
        *(.rodata*)
    } > BRAM
    ASSERT(SIZEOF(.text) <= 512, "MBIOS exceeds the hardware 128-word ROM")
}
