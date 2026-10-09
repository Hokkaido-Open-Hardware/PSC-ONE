#include "i2c_api.h"

/* All peripheral accesses must be aligned 32-bit word operations.
 * The overrides allow host tests to model MMIO side effects. */
#ifndef PSC_I2C_MMIO_READ
#define PSC_I2C_MMIO_READ(addr) (*(volatile uint32_t *)(uintptr_t)(addr))
#endif
#ifndef PSC_I2C_MMIO_WRITE
#define PSC_I2C_MMIO_WRITE(addr, value) \
    (*(volatile uint32_t *)(uintptr_t)(addr) = (uint32_t)(value))
#endif

/* Explicit sign extension also keeps host tests independent of the compiler's
 * out-of-range unsigned-to-signed conversion behavior. */
static int8_t signed_byte(uint32_t value)
{
    int32_t byte = (int32_t)(value & 0xffu);
    return (int8_t)(byte >= 128 ? byte - 256 : byte);
}

void i2c_init(void)
{
    i2c_set_irq_enabled(0);
    i2c_clear_status(PSC_I2C_STATUS_MASK);
}

uint32_t i2c_get_status(void)
{
    return PSC_I2C_MMIO_READ(PSC_I2C_ADDR_STATUS) & PSC_I2C_STATUS_MASK;
}

void i2c_clear_status(uint32_t mask)
{
    PSC_I2C_MMIO_WRITE(PSC_I2C_ADDR_STATUS, mask & PSC_I2C_STATUS_MASK);
}

void i2c_set_irq_enabled(int enabled)
{
    PSC_I2C_MMIO_WRITE(PSC_I2C_ADDR_CONTROL,
                       enabled ? PSC_I2C_CONTROL_IRQ_ENABLE : 0u);
}

int i2c_get_irq_enabled(void)
{
    return (PSC_I2C_MMIO_READ(PSC_I2C_ADDR_CONTROL) &
            PSC_I2C_CONTROL_IRQ_ENABLE) != 0u;
}

uint8_t i2c_get_sequence(void)
{
    return (uint8_t)(PSC_I2C_MMIO_READ(PSC_I2C_ADDR_SEQ) & 0xffu);
}

int i2c_read_input(int8_t input[PSC_I2C_INPUT_COUNT])
{
    uint32_t packed;
    if (input == 0)
        return I2C_ERR_INVALID;
    if ((i2c_get_status() & PSC_I2C_STATUS_INPUT_READY) == 0u)
        return I2C_ERR_NOT_READY;

    packed = PSC_I2C_MMIO_READ(PSC_I2C_ADDR_INPUT);
    for (uint32_t i = 0; i < PSC_I2C_INPUT_COUNT; ++i)
        input[i] = signed_byte(packed >> (8u * i));
    return I2C_OK;
}

int i2c_wait_input(uint32_t max_polls)
{
    for (uint32_t i = 0; i < max_polls; ++i) {
        if ((i2c_get_status() & PSC_I2C_STATUS_INPUT_READY) != 0u)
            return I2C_OK;
    }
    return I2C_ERR_TIMEOUT;
}

void i2c_write_output(int8_t output)
{
    PSC_I2C_MMIO_WRITE(PSC_I2C_ADDR_OUTPUT, (uint32_t)(uint8_t)output);
}

int8_t i2c_read_output(void)
{
    return signed_byte(PSC_I2C_MMIO_READ(PSC_I2C_ADDR_OUTPUT));
}
