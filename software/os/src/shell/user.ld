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
        __user_bss_end = .;
    }

    /* create_process() maps this stack separately. Do not also embed 128KB
       of zero stack in shell.bin: MicroPython needs that page-pool space. */
    __user_stack_top = USER_MAX;
    __user_stack_start = __user_stack_top - 128 * 1024;
    __user_stack_bottom = __user_stack_start - 4096; /* unmapped guard */
    ASSERT(__user_bss_end <= __user_stack_bottom,
           "user image overlaps stack guard")
}
