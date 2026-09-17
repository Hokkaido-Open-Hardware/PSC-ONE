.section .text
.globl _start
_start:
    la sp, _stack_top
    call bootloader_main
1:
    j 1b

.section .bss
.align 4
_stack:
    .skip 16384
_stack_top: