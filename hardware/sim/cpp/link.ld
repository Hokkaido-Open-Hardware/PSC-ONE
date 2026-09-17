/* RAM only, start @ 0x00000000 */
MEMORY { RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K }
ENTRY(_start)

/* Stack */
_stack_top = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS {
  .text : ALIGN(4) {
    *(.text*) *(.rodata*)
  } > RAM

  .sdata : ALIGN(4) {
    PROVIDE(__global_pointer$ = . + 0x1000);
    *(.sdata*) *(.srodata*)
  } > RAM

  .data : ALIGN(4) {
    *(.data*)
  } > RAM

  .init_array : ALIGN(4) {
    __init_array_start = .; *(.init_array*) __init_array_end = .;
  } > RAM

  .fini_array : ALIGN(4) {
    __fini_array_start = .; *(.fini_array*) __fini_array_end = .;
  } > RAM

  .bss (NOLOAD) : ALIGN(4) {
    __bss_start = .;
    *(.bss*) *(.sbss*)
    __bss_end = .;
  } > RAM

  __heap_start = .;
}