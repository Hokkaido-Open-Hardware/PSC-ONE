/* User virtual addresses match kernel/user_memory.rs. */
ENTRY(start)
INCLUDE memory.ld
SECTIONS {
    . = __user_base;
    .text : { KEEP(*(.text.start)) *(.text .text.*) }
    .rodata : ALIGN(16) { *(.rodata .rodata.*) }
    .data : ALIGN(16) { *(.data .data.* .sdata .sdata.*) }
    .bss : ALIGN(16) {
        *(.bss .bss.* .sbss .sbss.*) *(COMMON)
        . = ALIGN(16);
        __user_bss_end = .;
    }
    __user_stack_bottom = __user_stack_top - __user_stack_size - __user_stack_guard;
    ASSERT(__user_bss_end <= __user_stack_bottom, "user image overlaps stack guard")
    /DISCARD/ : { *(.eh_frame*) *(.comment) }
}
