/* User virtual addresses match kernel/user_memory.rs. */
ENTRY(start)
SECTIONS {
    . = 0x00400000;
    .text : { KEEP(*(.text.start)) *(.text .text.*) }
    .rodata : ALIGN(16) { *(.rodata .rodata.*) }
    .data : ALIGN(16) { *(.data .data.* .sdata .sdata.*) }
    .bss : ALIGN(16) {
        *(.bss .bss.* .sbss .sbss.*) *(COMMON)
        . = ALIGN(16);
        __user_bss_end = .;
    }
    __user_stack_top = 0x00500000;
    __user_stack_bottom = __user_stack_top - 128 * 1024 - 4096;
    ASSERT(__user_bss_end <= __user_stack_bottom, "user image overlaps stack guard")
    /DISCARD/ : { *(.eh_frame*) *(.comment) }
}
