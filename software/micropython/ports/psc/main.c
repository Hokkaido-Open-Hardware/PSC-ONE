#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "py/builtin.h"
#include "py/compile.h"
#include "py/runtime.h"
#include "py/repl.h"
#include "py/gc.h"
#include "py/mphal.h"
#include "py/stackctrl.h"
#include "shared/runtime/gchelper.h"
#include "mphalport.h"
#include "py/mperrno.h"
#include "shared/runtime/pyexec.h"
#include "psc_vfs.h"

#if MICROPY_ENABLE_COMPILER
void do_str(const char *src, mp_parse_input_kind_t input_kind) {
    nlr_buf_t nlr;
    if (nlr_push(&nlr) == 0) {
        mp_lexer_t *lex = mp_lexer_new_from_str_len(MP_QSTR__lt_stdin_gt_, src, strlen(src), 0);
        qstr source_name = lex->source_name;
        mp_parse_tree_t parse_tree = mp_parse(lex, input_kind);
        mp_obj_t module_fun = mp_compile(&parse_tree, source_name, true);
        mp_call_function_0(module_fun);
        nlr_pop();
    } else {
        // uncaught exception
        mp_obj_print_exception(&mp_plat_print, (mp_obj_t)nlr.ret_val);
    }
}
#endif

#if MICROPY_ENABLE_GC
static char heap[MICROPY_HEAP_SIZE] __attribute__((aligned(16)));
#endif

// Explicit shell exit, separate from the standard Ctrl+D soft reset.
bool psc_mp_exit_requested;
int psc_micropython_run(void) {
    mp_stack_ctrl_init();
    mp_stack_set_limit(120 * 1024);
    psc_mp_exit_requested = false;
    pyexec_mode_kind = PYEXEC_MODE_FRIENDLY_REPL;
    if (psc_mp_console_begin() != 0) return -1;
    for (;;) {
        #if MICROPY_ENABLE_GC
        gc_init(heap, heap + sizeof(heap));
        #endif
        mp_init();
        psc_vfs_init();
        mp_hal_set_interrupt_char(-1);
        for (;;) {
            int ret = pyexec_mode_kind == PYEXEC_MODE_RAW_REPL
                ? pyexec_raw_repl() : pyexec_friendly_repl();
            if (ret & PYEXEC_FORCED_EXIT) break;
        }
        mp_hal_set_interrupt_char(-1);
        // Finalise even reachable files before discarding the heap/mount.
        gc_sweep_all();
        mp_deinit();
        if (psc_mp_exit_requested) break;
        mp_hal_stdout_tx_str("MPY: soft reboot\r\n");
    }
    psc_mp_console_end();
    return 0;
}

#ifndef PSC_MICROPY_EMBEDDED
int main(int argc, char **argv) {
    (void)argc;
    (void)argv;
    return psc_micropython_run();
}
#endif

#if MICROPY_ENABLE_GC
void gc_collect(void) {
    gc_collect_start();
    gc_helper_collect_regs_and_stack();
    gc_collect_end();
}
#endif

#if !MICROPY_VFS
mp_lexer_t *mp_lexer_new_from_file(qstr filename) {
    mp_raise_OSError(MP_ENOENT);
}

mp_import_stat_t mp_import_stat(const char *path) {
    return MP_IMPORT_STAT_NO_EXIST;
}

#endif

void nlr_jump_fail(void *val) {
    while (1) {
        ;
    }
}

void MP_NORETURN __fatal_error(const char *msg) {
    while (1) {
        ;
    }
}

#ifndef NDEBUG
void MP_WEAK __assert_func(const char *file, int line, const char *func, const char *expr) {
    printf("Assertion '%s' failed, at file %s:%d\n", expr, file, line);
    __fatal_error("Assertion failed");
}
#endif

#if MICROPY_MIN_USE_CORTEX_CPU

// this is a minimal IRQ and reset framework for any Cortex-M CPU

extern uint32_t _estack, _sidata, _sdata, _edata, _sbss, _ebss;

void Reset_Handler(void) __attribute__((naked));
void Reset_Handler(void) {
    // set stack pointer
    __asm volatile ("ldr sp, =_estack");
    // copy .data section from flash to RAM
    for (uint32_t *src = &_sidata, *dest = &_sdata; dest < &_edata;) {
        *dest++ = *src++;
    }
    // zero out .bss section
    for (uint32_t *dest = &_sbss; dest < &_ebss;) {
        *dest++ = 0;
    }
    // jump to board initialisation
    void _start(void);
    _start();
}

void Default_Handler(void) {
    for (;;) {
    }
}

const uint32_t isr_vector[] __attribute__((section(".isr_vector"))) = {
    (uint32_t)&_estack,
    (uint32_t)&Reset_Handler,
    (uint32_t)&Default_Handler, // NMI_Handler
    (uint32_t)&Default_Handler, // HardFault_Handler
    (uint32_t)&Default_Handler, // MemManage_Handler
    (uint32_t)&Default_Handler, // BusFault_Handler
    (uint32_t)&Default_Handler, // UsageFault_Handler
    0,
    0,
    0,
    0,
    (uint32_t)&Default_Handler, // SVC_Handler
    (uint32_t)&Default_Handler, // DebugMon_Handler
    0,
    (uint32_t)&Default_Handler, // PendSV_Handler
    (uint32_t)&Default_Handler, // SysTick_Handler
};

void _start(void) {
    // when we get here: stack is initialised, bss is clear, data is copied

    // SCB->CCR: enable 8-byte stack alignment for IRQ handlers, in accord with EABI
    *((volatile uint32_t *)0xe000ed14) |= 1 << 9;

    // initialise the cpu and peripherals
    #if MICROPY_MIN_USE_STM32_MCU
    void stm32_init(void);
    stm32_init();
    #endif

    // now that we have a basic system up and running we can call main
    main(0, NULL);

    // we must not return
    for (;;) {
    }
}

#endif

#if MICROPY_MIN_USE_STM32_MCU

// this is minimal set-up code for an STM32 MCU

typedef struct {
    volatile uint32_t CR;
    volatile uint32_t PLLCFGR;
    volatile uint32_t CFGR;
    volatile uint32_t CIR;
    uint32_t _1[8];
    volatile uint32_t AHB1ENR;
    volatile uint32_t AHB2ENR;
    volatile uint32_t AHB3ENR;
    uint32_t _2;
    volatile uint32_t APB1ENR;
    volatile uint32_t APB2ENR;
} periph_rcc_t;

typedef struct {
    volatile uint32_t MODER;
    volatile uint32_t OTYPER;
    volatile uint32_t OSPEEDR;
    volatile uint32_t PUPDR;
    volatile uint32_t IDR;
    volatile uint32_t ODR;
    volatile uint16_t BSRRL;
    volatile uint16_t BSRRH;
    volatile uint32_t LCKR;
    volatile uint32_t AFR[2];
} periph_gpio_t;

typedef struct {
    volatile uint32_t SR;
    volatile uint32_t DR;
    volatile uint32_t BRR;
    volatile uint32_t CR1;
} periph_uart_t;

#define USART1 ((periph_uart_t *)0x40011000)
#define GPIOA  ((periph_gpio_t *)0x40020000)
#define GPIOB  ((periph_gpio_t *)0x40020400)
#define RCC    ((periph_rcc_t *)0x40023800)

// simple GPIO interface
#define GPIO_MODE_IN (0)
#define GPIO_MODE_OUT (1)
#define GPIO_MODE_ALT (2)
#define GPIO_PULL_NONE (0)
#define GPIO_PULL_UP (0)
#define GPIO_PULL_DOWN (1)
void gpio_init(periph_gpio_t *gpio, int pin, int mode, int pull, int alt) {
    gpio->MODER = (gpio->MODER & ~(3 << (2 * pin))) | (mode << (2 * pin));
    // OTYPER is left as default push-pull
    // OSPEEDR is left as default low speed
    gpio->PUPDR = (gpio->PUPDR & ~(3 << (2 * pin))) | (pull << (2 * pin));
    gpio->AFR[pin >> 3] = (gpio->AFR[pin >> 3] & ~(15 << (4 * (pin & 7)))) | (alt << (4 * (pin & 7)));
}
#define gpio_get(gpio, pin) ((gpio->IDR >> (pin)) & 1)
#define gpio_set(gpio, pin, value) do { gpio->ODR = (gpio->ODR & ~(1 << (pin))) | (value << pin); } while (0)
#define gpio_low(gpio, pin) do { gpio->BSRRH = (1 << (pin)); } while (0)
#define gpio_high(gpio, pin) do { gpio->BSRRL = (1 << (pin)); } while (0)

void stm32_init(void) {
    // basic MCU config
    RCC->CR |= (uint32_t)0x00000001; // set HSION
    RCC->CFGR = 0x00000000; // reset all
    RCC->CR &= (uint32_t)0xfef6ffff; // reset HSEON, CSSON, PLLON
    RCC->PLLCFGR = 0x24003010; // reset PLLCFGR
    RCC->CR &= (uint32_t)0xfffbffff; // reset HSEBYP
    RCC->CIR = 0x00000000; // disable IRQs

    // leave the clock as-is (internal 16MHz)

    // enable GPIO clocks
    RCC->AHB1ENR |= 0x00000003; // GPIOAEN, GPIOBEN

    // turn on an LED! (on pyboard it's the red one)
    gpio_init(GPIOA, 13, GPIO_MODE_OUT, GPIO_PULL_NONE, 0);
    gpio_high(GPIOA, 13);

    // enable UART1 at 9600 baud (TX=B6, RX=B7)
    gpio_init(GPIOB, 6, GPIO_MODE_ALT, GPIO_PULL_NONE, 7);
    gpio_init(GPIOB, 7, GPIO_MODE_ALT, GPIO_PULL_NONE, 7);
    RCC->APB2ENR |= 0x00000010; // USART1EN
    USART1->BRR = (104 << 4) | 3; // 16MHz/(16*104.1875) = 9598 baud
    USART1->CR1 = 0x0000200c; // USART enable, tx enable, rx enable
}

#endif
