SECTIONS
{
    . = 0x00100000;

    .text : {
        *(.text*)
    }

    .rodata : ALIGN(4) {
        *(.rodata*)
    }

    .data : ALIGN(4) {
        *(.data*)
    }

    .bss : ALIGN(4) {
        *(.bss*)
    }

    .stack (NOLOAD) : {
        . = ALIGN(16);
        _stack_start = .;
        . += 16384;
        _stack_top = .;
    }

    . = ALIGN(4);
    . += 4000 * 4;
}