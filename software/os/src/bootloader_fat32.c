#include "sdcard_api.h"
#include "boot_fat32.h"
#include "kernel.h"
#include "common.h"

#include <stdint.h>
#include <stdbool.h>

#ifndef UART_MMIO_BASE
#define UART_MMIO_BASE 0x10000000u
#endif

#ifndef UART_TX
#define UART_TX 0x0
#endif

#ifndef UART_ST
#define UART_ST 0x8
#endif

#ifndef ST_TX_BUSY
#define ST_TX_BUSY (1u << 0)
#endif

#define SD_CTRL_INIT_TRIG   0x01u
#define SD_CTRL_READ_TRIG   0x02u
#define SD_CTRL_FIFO_FLUSH  0x04u

#define SD_ST_BUSY          (1u << 1)
#define SD_ST_RW_READY      (1u << 2)
#define SD_ST_FIFO_EMPTY    (1u << 3)

#define SD_READ_RETRY_MAX   3u

#ifndef KERNEL_LOAD_ADDR
#define KERNEL_LOAD_ADDR    0x00200000u
#endif

#ifndef USER_LOAD_ADDR
#define USER_LOAD_ADDR      0x00400000u
#endif

void putchar(char ch)
{
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
        __asm__ __volatile__("nop");
    }

    mmio_w32(UART_MMIO_BASE + UART_TX, (uint32_t)(uint8_t)ch);
}

void uart_putchar(char c)
{
    putchar(c);
}

static void bl_print(const char *s)
{
    while (*s) {
        putchar(*s++);
    }
}

static void bl_print_hex(uint32_t v)
{
    for (int i = 7; i >= 0; i--) {
        uint8_t n = (uint8_t)((v >> (i * 4)) & 0xFu);
        putchar(n < 10 ? (char)('0' + n) : (char)('A' + n - 10));
    }
}

static inline void tiny_delay(unsigned n)
{
    while (n--) {
        __asm__ __volatile__("nop");
    }
}

static inline void cpu_relax(void)
{
    __asm__ __volatile__("nop");
}

static uint16_t sd_crc16_512(const uint8_t *buf)
{
    uint16_t crc = 0;

    for (int i = 0; i < 512; i++) {
        crc ^= (uint16_t)((uint16_t)buf[i] << 8);

        for (int j = 0; j < 8; j++) {
            if (crc & 0x8000u)
                crc = (uint16_t)((crc << 1) ^ 0x1021u);
            else
                crc = (uint16_t)(crc << 1);
        }
    }

    return crc;
}

static uint16_t sd_get_hw_crc(void)
{
    uint32_t ctrl = PSC_SD_IF_CTRL;

    uint8_t crc1_hw = (uint8_t)((ctrl >> 24) & 0xFFu);
    uint8_t crc2_hw = (uint8_t)((ctrl >> 16) & 0xFFu);

    return (uint16_t)(((uint16_t)crc1_hw << 8) | crc2_hw);
}

static int sd_init_if_needed(void)
{
    uint32_t timeout;

    PSC_SD_IF_CTRL = SD_CTRL_FIFO_FLUSH;
    tiny_delay(100);

    bl_print("SD INIT start\n");

    PSC_SD_IF_CTRL = SD_CTRL_INIT_TRIG;
    tiny_delay(100);

    timeout = 50000u;

    while (PSC_SD_IF_CTRL & SD_ST_BUSY) {
        tiny_delay(100);
        if (--timeout == 0u) {
            bl_print("SD INIT TIMEOUT\n");
            return -1;
        }

        cpu_relax();
    }

    tiny_delay(100);
    return 0;
}

static int boot_sd_read_sector(uint32_t lba, uint8_t *dst)
{
    uint32_t timeout;

    for (uint32_t retry = 0; retry < SD_READ_RETRY_MAX; retry++) {
        PSC_SD_IF_CTRL = SD_CTRL_FIFO_FLUSH;
        tiny_delay(50);

        PSC_SD_SECTOR = lba;

        PSC_SD_IF_CTRL = SD_CTRL_READ_TRIG;
        tiny_delay(50);

        timeout = 50000u;

        while ((PSC_SD_IF_CTRL & SD_ST_RW_READY) == 0u) {
            if (--timeout == 0u) {
                bl_print("SD READ TIMEOUT lba=");
                bl_print_hex(lba);
                bl_print("\n");
                return -1;
            }

            cpu_relax();
        }

        tiny_delay(20);

        for (int i = 0; i < 512; i++) {
            timeout = 50000u;

            while (PSC_SD_IF_CTRL & SD_ST_FIFO_EMPTY) {
                if (--timeout == 0u) {
                    bl_print("FIFO EMPTY TIMEOUT lba=");
                    bl_print_hex(lba);
                    bl_print("\n");
                    return -1;
                }

                cpu_relax();
            }

            dst[i] = (uint8_t)(PSC_IF_DATA & 0xFFu);
        }

        {
            uint16_t crc_sw = sd_crc16_512(dst);
            uint16_t crc_hw = sd_get_hw_crc();

            if (crc_sw == crc_hw)
                return 0;

            bl_print("CRC NG lba=");
            bl_print_hex(lba);
            bl_print(" sw=");
            bl_print_hex((uint32_t)crc_sw);
            bl_print(" hw=");
            bl_print_hex((uint32_t)crc_hw);
            bl_print("\n");
        }

        tiny_delay(100);
    }

    bl_print("CRC FAILED lba=");
    bl_print_hex(lba);
    bl_print("\n");

    return -1;
}

static void jump_to_kernel(uint32_t addr)
{
    void (*entry)(void) = (void (*)(void))addr;
    entry();
}

void bootloader_main(void)
{
    uint32_t kernel_words = 0;
    uint32_t user_words = 0;

    bl_print("bootloader FAT32 start\n");

    if (sd_init_if_needed()) {
        bl_print("SD init failed\n");
        for (;;) {}
    }

    if (boot_fat32_mount(boot_sd_read_sector)) {
        bl_print("FAT32 mount failed\n");
        for (;;) {}
    }

    if (boot_fat32_load_mem_file("KERNEL.MEM", KERNEL_LOAD_ADDR, &kernel_words)) {
        bl_print("KERNEL.MEM load failed\n");
        for (;;) {}
    }

    if (boot_fat32_load_mem_file("USER.MEM", USER_LOAD_ADDR, &user_words)) {
        bl_print("USER.MEM load failed\n");
        for (;;) {}
    }

    bl_print("kernel words=");
    bl_print_hex(kernel_words);
    bl_print("\n");

    bl_print("user words=");
    bl_print_hex(user_words);
    bl_print("\n");

    bl_print("JUMP TO ");
    bl_print_hex(KERNEL_LOAD_ADDR);
    bl_print("\n");

    bl_print("kernel[0]=");
    bl_print_hex(*(volatile uint32_t *)0x00200000);
    bl_print("\n");

    bl_print("kernel[1]=");
    bl_print_hex(*(volatile uint32_t *)0x00200004);
    bl_print("\n");

    bl_print("kernel[2]=");
    bl_print_hex(*(volatile uint32_t *)0x00200008);
    bl_print("\n");

    bl_print("user[0]=");
    bl_print_hex(*(volatile uint32_t *)0x00400000);
    bl_print("\n");

    jump_to_kernel(KERNEL_LOAD_ADDR);

    for (;;) {}
}
