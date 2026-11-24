#pragma once

/* PSC-ONE / PSC_RV32 wiring and memory contract.
 * Driver register offsets, bit definitions and algorithms stay with drivers.
 * No C types here: the boot assembly consumes these constants too. */
#define PSC_BOARD_NAME              "PSC-ONE / PSC_RV32"
#define PSC_BOARD_XLEN              32
#define PSC_BOARD_OS_SUPPORTED      1

#define PSC_BOARD_MMIO_BASE         0x10000000
#define PSC_BOARD_MMIO_SIZE         0x00010000
#define PSC_BOARD_UART_BASE         0x10000000
#define PSC_BOARD_SWITCH_BASE       0x10001000
#define PSC_BOARD_TIMER_BASE        0x10002000
#define PSC_BOARD_LCD_BASE          0x10003000
#define PSC_BOARD_LED_BASE          0x10004000
#define PSC_BOARD_SYNAP_BASE        0x10005000
#define PSC_BOARD_SD_BASE           0x10006000
#define PSC_BOARD_MIC_BASE          0x10007000
#define PSC_BOARD_I2C_BASE          0x10009000

#define PSC_BOARD_SYNAP_DATA_BASE   0x00020000
#define PSC_BOARD_SYNAP_RESULT_BASE 0x00030000
#define PSC_BOARD_ARENA_PHYS_BASE   0x00040000
#define PSC_BOARD_BOOTLOADER_BASE   0x00100000
#define PSC_BOARD_KERNEL_BASE       0x00200000
#define PSC_BOARD_MEMORY_TEST_START 0x00600000
#define PSC_BOARD_MEMORY_TEST_END   0x00800000

#ifdef PSC_TANG138K_VRAM
/* Physical DDR3 address shared with PSC_ONE_138K_Chip.VRAM_ADDRESS. */
#define PSC_BOARD_VRAM_BASE         0x00900000
#define PSC_BOARD_VRAM_WIDTH        1920
#define PSC_BOARD_VRAM_HEIGHT       1080
#define PSC_BOARD_VRAM_BYTES        (PSC_BOARD_VRAM_WIDTH / 2 * PSC_BOARD_VRAM_HEIGHT)
/* Supervisor VA in the unused part of the shell's Arena leaf table. */
#define PSC_BOARD_VRAM_VA           0x00d00000
#define PSC_BOARD_VRAM_B_BASE       (PSC_BOARD_VRAM_BASE + 0x00100000)
#define PSC_BOARD_VRAM_B_VA         0x00f00000
#define PSC_BOARD_RGB565_BASE       0x00b00000
#define PSC_BOARD_Z16_BASE          0x00b80000
#define PSC_BOARD_RGB565_VA         0x00e00000
#define PSC_BOARD_Z16_VA            0x00e80000
#define PSC_BOARD_RGBZ_PLANE_BYTES  (640 * 360 * 2)
#define PSC_BOARD_RGBZ_CONTROL      0x1000a000
#define PSC_BOARD_RGBZ_STATUS       0x1000a004
#endif

/* Keep in sync with boot/kernel/shell linker scripts and the RTL ROM loader. */
#define PSC_BOARD_USER_BASE         0x00400000
#define PSC_BOARD_USER_STACK_OFFSET 0x00100000
#define PSC_BOARD_USER_STACK_SIZE   (128 * 1024)
#define PSC_BOARD_USER_STACK_GUARD   (4 * 1024)
#define PSC_BOARD_USER_MODEL_OFFSET 0x00400000
#define PSC_BOARD_USER_MODEL_SIZE   0x00400000
#define PSC_BOARD_USER_ARENA_BASE   0x00c00000
#define PSC_BOARD_USER_ARENA_SIZE   0x000c0000
