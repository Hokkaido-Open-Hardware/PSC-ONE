ENTRY(_start)

MEMORY {
    BRAM (rx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS {
    .text : ALIGN(4) {
        *(.text*)
        *(.rodata*)
    } > BRAM
}
