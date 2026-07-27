ENTRY(start)

/* デフォルト: 0x0040_0000（-defsym で上書き可能）*/
USER_BASE = DEFINED(USER_BASE) ? USER_BASE : 0x00400000;
/* ユーザ領域の上限（例: +1MB）*/
USER_MAX  = USER_BASE + 0x00100000;

SECTIONS {
    . = USER_BASE;

    .text : {
        KEEP(*(.text.start));
        *(.text .text.*);
    }

    .rodata : ALIGN(4) {
        *(.rodata .rodata.*);
    }

    .data : ALIGN(4) {
        *(.data .data.*);
    }

    .bss : ALIGN(4) {
        *(.bss .bss.* .sbss .sbss.*);

        . = ALIGN(16);
        __user_stack_bottom = .;
        . += 4K;   /* guard page */
        __user_stack_start = .;
        . += 128 * 1024;   /* stack 128KB */
        __user_stack_top = .;

        ASSERT(__user_stack_top <= USER_MAX, "user image + stack overflow USER_MAX");
    }
}

