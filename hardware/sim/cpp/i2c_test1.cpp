// i2c_test1.cpp - PSC-ONE I2C Slave MMIO smoke test (bare metal).
// Test format: cache_RW_test1.cpp, extern "C" void run(), PIO32 PASS/FAIL.
//
// Scope: CPU-side MMIO only. An external I2C master is NOT required.
//       SCL/SDA transfers, address ACK, input_ready/SEQ increments and IRQ
//       assertion on input reception require a separate cocotb I2C-master test.
//
// Assumptions:
//   - I2C peripheral is instantiated, reset has been released, and its
//     MMIO addresses are decoded/routed to the CPU's bus.
//   - No external I2C master writes to the peripheral during this test.
//   - Default RTL register addresses are used unless overridden below.

#include <cstdint>

#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

static constexpr uint32_t TEST_END_CODE = 0x0000EE01u;
static constexpr uint32_t TEST_PASS     = 0x600DCAFEu;
static constexpr uint32_t TEST_FAIL     = 0xBAD00000u;

// Override EACH address to match the PSC_RV32_I2C parameter values at SoC top.
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
#define PSC_I2C_ADDR_CONTROL 0x1000900Cu
#endif
#ifndef PSC_I2C_ADDR_SEQ
#define PSC_I2C_ADDR_SEQ     0x10009010u
#endif

static constexpr uintptr_t ADDR_INPUT   = PSC_I2C_ADDR_INPUT;
static constexpr uintptr_t ADDR_STATUS  = PSC_I2C_ADDR_STATUS;
static constexpr uintptr_t ADDR_OUTPUT  = PSC_I2C_ADDR_OUTPUT;
static constexpr uintptr_t ADDR_CONTROL = PSC_I2C_ADDR_CONTROL;
static constexpr uintptr_t ADDR_SEQ     = PSC_I2C_ADDR_SEQ;

static constexpr uint32_t ST_INPUT_READY  = 1u << 0;
static constexpr uint32_t ST_OUTPUT_READY = 1u << 1;
static constexpr uint32_t ST_OVERRUN      = 1u << 2;
static constexpr uint32_t ST_MASK = ST_INPUT_READY | ST_OUTPUT_READY | ST_OVERRUN;

static inline uint32_t mmio_read(uintptr_t addr) {
    return *reinterpret_cast<volatile uint32_t*>(addr);
}

static inline void mmio_write(uintptr_t addr, uint32_t value) {
    *reinterpret_cast<volatile uint32_t*>(addr) = value;
}

extern "C" volatile uint32_t result;
extern "C" volatile uint32_t i2c_test_errors;
extern "C" volatile uint32_t i2c_test_last_read;

extern "C" void run() {
    uint32_t errors = 0u;
    uint32_t value = 0u;

    // 0: Reset state: no input, output or overrun flags.
    value = mmio_read(ADDR_STATUS);
    if ((value & ST_MASK) != 0u) errors |= 1u << 0;

    // 1: Initial INPUT buffer should contain four zero bytes.
    value = mmio_read(ADDR_INPUT);
    if (value != 0u) errors |= 1u << 1;

    // 2: Initial sequence number should be zero.
    value = mmio_read(ADDR_SEQ);
    if (value != 0u) errors |= 1u << 2;

    // 3: Initial OUTPUT value should be zero.
    value = mmio_read(ADDR_OUTPUT);
    if (value != 0u) errors |= 1u << 3;

    // 4: IRQ Enable defaults to zero.
    value = mmio_read(ADDR_CONTROL);
    if ((value & 1u) != 0u) errors |= 1u << 4;

    // 5: CONTROL IRQ enable set/readback.
    mmio_write(ADDR_CONTROL, 1u);
    value = mmio_read(ADDR_CONTROL);
    if (value != 1u) errors |= 1u << 5;

    // 6: CONTROL only uses bit 0 and can be cleared again.
    mmio_write(ADDR_CONTROL, 0u);
    value = mmio_read(ADDR_CONTROL);
    if (value != 0u) errors |= 1u << 6;

    // 7: CPU can write the 8-bit result register and read it back.
    mmio_write(ADDR_OUTPUT, 0xA5u);
    value = mmio_read(ADDR_OUTPUT);
    if (value != 0xA5u) errors |= 1u << 7;

    // 8: OUTPUT write sets output_ready but not input_ready / overrun.
    value = mmio_read(ADDR_STATUS);
    if ((value & ST_MASK) != ST_OUTPUT_READY) errors |= 1u << 8;

    // 9: STATUS is W1C: writing zero must NOT clear output_ready.
    mmio_write(ADDR_STATUS, 0u);
    value = mmio_read(ADDR_STATUS);
    if ((value & ST_MASK) != ST_OUTPUT_READY) errors |= 1u << 9;

    // 10: W1C bit 1 clears output_ready; OUTPUT data remains unchanged.
    mmio_write(ADDR_STATUS, ST_OUTPUT_READY);
    value = mmio_read(ADDR_STATUS);
    if ((value & ST_MASK) != 0u) errors |= 1u << 10;
    value = mmio_read(ADDR_OUTPUT);
    if (value != 0xA5u) errors |= 1u << 11;

    // 12: Only OUTPUT[7:0] is retained, regardless of upper write bits.
    mmio_write(ADDR_OUTPUT, 0x123456E7u);
    value = mmio_read(ADDR_OUTPUT);
    if (value != 0xE7u) errors |= 1u << 12;

    // 13: The new OUTPUT write sets output_ready once again.
    value = mmio_read(ADDR_STATUS);
    if ((value & ST_MASK) != ST_OUTPUT_READY) errors |= 1u << 13;

    // 14: Clear all W1C flags for the following tests.
    mmio_write(ADDR_STATUS, ST_MASK);
    value = mmio_read(ADDR_STATUS);
    if ((value & ST_MASK) != 0u) errors |= 1u << 14;

    // 15: No I2C master transaction: INPUT/SEQ remain unchanged.
    if (mmio_read(ADDR_INPUT) != 0u || mmio_read(ADDR_SEQ) != 0u) {
        errors |= 1u << 15;
    }

    i2c_test_errors = errors;   // debugger / waveform visibility
    i2c_test_last_read = value;
    result = (errors == 0u) ? TEST_PASS : (TEST_FAIL | errors);

    PIO32 = TEST_END_CODE;
    PIO32 = result;
    while (1) { }
}

extern "C" {
volatile uint32_t result = 0u;
volatile uint32_t i2c_test_errors = 0u;
volatile uint32_t i2c_test_last_read = 0u;
}