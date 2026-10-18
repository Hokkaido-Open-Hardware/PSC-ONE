#pragma once
#include <stdint.h>

/* Capture MMIO uses SEQ+4/+8/+12, independently of slave status/control. */
#define I2C_CAPTURE_ARM    0u
#define I2C_CAPTURE_STATUS 1u
#define I2C_CAPTURE_COUNT  2u
#define I2C_CAPTURE_POP    3u
#define I2C_CAPTURE_ABORT  4u
#define I2C_CAPTURE_LIMIT    (1u << 6)
#define I2C_CAPTURE_MULTI    (1u << 7)
#define I2C_CAPTURE_STOPS(status) (((status) >> 8) & 255u)
#define I2C_CAPTURE_TIMEOUT  (1u << 5)
#define I2C_CAPTURE_DONE   (1u << 2)
#define I2C_CAPTURE_OVERFLOW (1u << 3)
#define I2C_CAPTURE_ABORTED  (1u << 4)

uint32_t call_i2c_capture(uint32_t operation);
