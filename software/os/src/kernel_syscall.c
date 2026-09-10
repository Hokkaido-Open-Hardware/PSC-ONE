#include "common.h"
#include "syscall.h"
#include "kernel.h"
#include "synap_api.h"
#include "sdcard_api.h"
#include "timer_api.h"
#include "mic_api.h"
#include "led_api.h"
#include "lcd_api.h"
#include "jpeg_display.h"
#include "speech_recognition_api.h"

#ifndef PIO32_ADDR
#define PIO32_ADDR (*(volatile uint32_t *)0x10001000)
#endif

/* Validate every Sv32 page before dereferencing a user rectangle.
   Current OS uses level-0 4KiB user mappings only. */
static int lcd_user_readable(uint32_t address, uint32_t bytes)
{
    if (!current_proc || !bytes || address < USER_BASE ||
        address >= USER_STACK_TOP || bytes > USER_STACK_TOP - address) return 0;
    uint32_t end = address + bytes - 1;
    for (uint32_t va = address & ~(PAGE_SIZE - 1); ; va += PAGE_SIZE) {
        uint32_t pte = current_proc->page_table[va >> 22];
        if (!(pte & PAGE_V) || (pte & (PAGE_R | PAGE_W | PAGE_X))) return 0;
        uint32_t *table = (uint32_t *)((pte >> 10) << 12);
        pte = table[(va >> 12) & 1023];
        if ((pte & (PAGE_V | PAGE_U | PAGE_R)) != (PAGE_V | PAGE_U | PAGE_R)) return 0;
        if (va == (end & ~(PAGE_SIZE - 1))) return 1;
    }
}

void handle_syscall(struct trap_frame *f) {
    switch (f->a3) {
    case SYS_PUTCHAR:
        uart_putchar(f->a0);
        break;

    case SYS_GETCHAR:
        while (1) {
            long ch = uart_getchar();
            if (ch >= 0) {
                f->a0 = ch;
                break;
            }
            yield();
        }
        break;

    case SYS_GETCHAR_TIMEOUT:
        f->a0 = uart_getchar_timeout(1000);
        break;

    case SYS_PRINT_INT:
        s_print_int(f->a0);
        break;

    case SYS_SA_RUN: {
        const uint8_t *user_A = (const uint8_t *)(uintptr_t)f->a0;
        const uint8_t *user_B = (const uint8_t *)(uintptr_t)f->a1;
        uint32_t *user_C = (uint32_t *)(uintptr_t)f->a2;
        uint32_t n = f->a4;
        bool option = (bool)f->a5;

        if (n == 0 || n > SA_MAT_MAX || (n & 3u) != 0u) {
            f->a0 = (uint32_t)-1;
            break;
        }

        static uint8_t kernel_A[SA_MAT_MAX * SA_MAT_MAX];
        static uint8_t kernel_B[SA_MAT_MAX * SA_MAT_MAX];
        static uint32_t kernel_C[SA_MAT_MAX * SA_MAT_MAX];

        uint32_t elements = n * n;

        for (uint32_t i = 0; i < elements; ++i) {
            kernel_A[i] = user_A[i];
            kernel_B[i] = user_B[i];
            kernel_C[i] = 0;
        }

        sa_run(kernel_A, kernel_B, (uint8_t)n, kernel_C, option);

        for (uint32_t i = 0; i < elements; ++i)
            user_C[i] = kernel_C[i];

        f->a0 = 0;
        break;
    }

    case I2S_MIC_READ:
        f->a0 = s_call_mic_read_samples24(f->a0);
        break;

    case I2S_MIC_WRITE:
        f->a0 = s_call_mic_write_samples24(f->a0, f->a1);
        break;

    case SYS_SD_READ:
        s_call_sdcard_read_api(f->a0);
        break;

    case SYS_SD_WRITE_TEST: {
        uint8_t test_buf[512];
        for (int i = 0; i < 512; i++)
            test_buf[i] = (uint8_t)i;
        f->a0 = s_call_sdcard_write_api(f->a0, test_buf);
        break;
    }

    case SYS_SD_WRITE:
        f->a0 = s_call_sdcard_write_api(f->a0,
                                         (const uint8_t *)f->a1);
        break;

    case SYS_SD_READ_BUF: {
        static uint8_t kbuf[512];
        int ret = sd_read_sector(f->a0, kbuf);
        if (ret == 0)
            memcpy((void *)f->a1, kbuf, 512);
        f->a0 = ret;
        break;
    }

    case SYS_LCD_RGB888_BEGIN:
        f->a0 = lcd_begin_rgb888();
        break;
    case SYS_LCD_RGB888_RECT: {
        uint32_t width = f->a2, height = f->a4;
        if (!width || width > 16 || !height || height > 16 ||
            f->a0 >= JPEG_LCD_WIDTH || f->a1 >= JPEG_LCD_HEIGHT || width > JPEG_LCD_WIDTH - f->a0 ||
            height > JPEG_LCD_HEIGHT - f->a1 || !lcd_user_readable(f->a5, width * height * 3)) {
            f->a0 = (uint32_t)-1;
            break;
        }
        /* Small snapshot: no retained user pointer, no framebuffer. */
        uint8_t rgb[16 * 16 * 3];
        memcpy(rgb, (const void *)f->a5, width * height * 3);
        f->a0 = lcd_write_rgb888_rect(f->a0, f->a1, width, height, rgb);
        break;
    }

    case SYS_TIMER_MEASURE_BEGIN:
        f->a0 = timer_measure_begin();
        break;
    case SYS_TIMER_MEASURE_END:
        f->a0 = timer_measure_end();
        break;
    case SYS_TIMER_START:
        timer_start(f->a0);
        break;
    case SYS_TIMER_START_AUTO:
        timer_start_auto(f->a0);
        break;
    case SYS_TIMER_STOP:
        timer_stop();
        break;
    case SYS_TIMER_GET_COUNT:
        f->a0 = timer_get_count();
        break;
    case SYS_TIMER_GET_STATUS:
        f->a0 = timer_get_status();
        break;
    case SYS_TIMER_IS_RUNNING:
        f->a0 = (uint32_t)timer_is_running();
        break;
    case SYS_TIMER_WAIT_US:
        timer_wait_us(f->a0);
        break;
    case SYS_TIMER_WAIT_MS:
        timer_wait_ms(f->a0);
        break;

    case SYS_LED_WRITE:
        led_write(f->a0);
        break;
    case SYS_LED_ON:
        led_on(f->a0);
        break;
    case SYS_LED_OFF:
        led_off(f->a0);
        break;
    case SYS_LED_TOGGLE:
        led_toggle(f->a0);
        break;
    case SYS_LED_ALL_ON:
        led_all_on();
        break;
    case SYS_LED_ALL_OFF:
        led_all_off();
        break;
    case SYS_LED_GET_STATE:
        f->a0 = led_get_state();
        break;

    case SYS_DUMP: {
        uintptr_t addr = (uintptr_t)f->a0;
        size_t len = (size_t)f->a1;
        if (len == 0)
            len = 0x100;
        else if (len > 0x1000)
            len = 0x1000;
        hexdump((const void *)addr, len, addr);
        break;
    }

    case SYS_SW_READ: {
        volatile uint32_t tmp = PIO32_ADDR;
        f->a0 = tmp & 0x03;
        break;
    }

    case SYS_SPEECH_RECOGNITION:
        f->a0 = (uint32_t)s_call_speech_recognition_api();
        break;

    case SYS_EXIT:
        s_printf("process %d exited\n", current_proc->pid);
        reboot();
        __builtin_unreachable();

    default:
        PANIC("unexpected syscall a3=%x\n", f->a3);
    }
}
