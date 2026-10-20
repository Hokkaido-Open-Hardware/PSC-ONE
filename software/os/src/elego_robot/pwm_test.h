#pragma once
#include <stdint.h>

typedef struct {
    int write_seen, read_seen, report_seen;
    int left, right, ack_left, ack_right;
    unsigned read_bytes, report_status;
} pwm_test_result;

int pwm_test_signed16(const uint8_t *p);
/* NULL means an exact ordered WRITE/READ/report match. */
const char *pwm_test_decode(const uint32_t *events, unsigned count,
                            pwm_test_result *result);
void cmd_i2c_pwm_test(void);
