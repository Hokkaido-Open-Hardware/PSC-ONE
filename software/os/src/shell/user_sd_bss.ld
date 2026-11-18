/* SD boot has no resident USER.MEM source. The kernel backs this zero-fill
   segment with those physical pages. Keep it outside the shell stack. */
SECTIONS {
    .sd_bss (USER_BASE + 0x00200000) (NOLOAD) : {
        __shell_sd_bss_base = .;
        *(.bss .bss.* .sbss .sbss.*)
        *(COMMON)
        . = ALIGN(4096);
        __shell_sd_bss_end = .;
    }
}
ASSERT(__shell_sd_bss_base >= __user_stack_top &&
       __shell_sd_bss_end <= USER_BASE + 0x00400000,
       "SD shell BSS overlaps stack or model window")
