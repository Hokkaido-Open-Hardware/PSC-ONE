// PSC_RV32_I2C slave: CPU-side MMIO API (kernel / bare metal).
#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* PSC_ONE_SOC addresses, not the standalone module's 0x10002000 default.
 * Override each address when the SoC parameters differ. */
#ifndef PSC_I2C_ADDR_INPUT
#define PSC_I2C_ADDR_INPUT   0x10009000u
#endif
#ifndef PSC_I2C_ADDR_STATUS
#define PSC_I2C_ADDR_STATUS  0x10009004u
#endif
#ifndef PSC_I2C_ADDR_OUTPUT
#define PSC_I2C_ADDR_OUTPUT  0x10009008u
#endif
#ifndef PSC_I2C_ADDR_CONTROL
#define PSC_I2C_ADDR_CONTROL 0x1000900cu
#endif
#ifndef PSC_I2C_ADDR_SEQ
#define PSC_I2C_ADDR_SEQ     0x10009010u
#endif

#define PSC_I2C_INPUT_COUNT          4u
#define PSC_I2C_STATUS_INPUT_READY   (1u << 0)
#define PSC_I2C_STATUS_OUTPUT_READY  (1u << 1)
#define PSC_I2C_STATUS_OVERRUN       (1u << 2)
#define PSC_I2C_STATUS_MASK          0x07u
#define PSC_I2C_CONTROL_IRQ_ENABLE  (1u << 0)

enum {
    I2C_OK = 0,
    I2C_ERR_INVALID = -1,
    I2C_ERR_NOT_READY = -2,
    I2C_ERR_TIMEOUT = -3
};

/* Disable the peripheral IRQ and discard pending status (W1C).
 * Does not reset INPUT, OUTPUT or SEQ. Call before starting the master. */
void i2c_init(void);
uint32_t i2c_get_status(void);
/* Clear only the requested status bits; no read/modify/write on W1C. */
void i2c_clear_status(uint32_t mask);
/* Controls irq_rx only. Current PSC_ONE_SOC does not route it to the CPU. */
void i2c_set_irq_enabled(int enabled);
int i2c_get_irq_enabled(void);
/* SEQ wraps at 256; increments after a complete four-byte input write. */
uint8_t i2c_get_sequence(void);

/* Nonblocking: unpack INPUT into signed values in INPUT0..3 order.
 * NULL -> INVALID; no input_ready -> NOT_READY, leaving input unchanged.
 * Reads never clear flags. After copying, explicitly clear INPUT_READY.
 * OVERRUN remains available through i2c_get_status().
 *
 * There is no hardware snapshot/queue: the master must wait for the result
 * before sending another input. Bytes change during reception, and neither
 * SEQ nor input_ready detects a partially received replacement frame.
 * Serialize callers; concurrent receive/clear cannot be made atomic here. */
int i2c_read_input(int8_t input[PSC_I2C_INPUT_COUNT]);
/* At most max_polls STATUS reads; zero returns TIMEOUT without MMIO.
 * Poll count is not a time in microseconds. Does not read/acknowledge INPUT. */
int i2c_wait_input(uint32_t max_polls);
/* Low byte only; hardware sets output_ready. Master reads do not clear it.
 * A new complete input or explicit W1C clears output_ready. */
void i2c_write_output(int8_t output);
int8_t i2c_read_output(void);

#ifdef __cplusplus
}
#endif
