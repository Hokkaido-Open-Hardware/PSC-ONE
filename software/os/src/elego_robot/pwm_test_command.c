#ifdef PWM_HOST_TEST
#include <stdio.h>
#include "../api/i2c_capture.h"
int call_timer_measure_begin(void);
int call_timer_measure_read_us(void);
int call_timer_measure_end_us(void);
#else
#include "../api/user.h"
#endif
#include "pwm_test.h"

void cmd_i2c_pwm_test(void)
{
    uint32_t events[64], status;
    pwm_test_result result = {0};
    const char *error = 0;
    unsigned count = 0, polls = 0;
    printf("I2C Slave addr=0x42\nPWM test: left=20 right=20\n");
    status = call_i2c_capture(I2C_CAPTURE_STATUS);
    if (!(status & I2C_CAPTURE_PWM_SUPPORTED)) {
        printf("PWM communication FAIL: unsupported FPGA; rebuild/program FPGA.\n");
        return;
    }
    if (status & 1u) {
        printf("PWM communication FAIL: capture busy.\n");
        return;
    }
    if (call_timer_measure_begin() != 0) {
        printf("PWM communication FAIL: timer busy.\n");
        return;
    }
    uint32_t start = (uint32_t)call_timer_measure_read_us();
    if (start == UINT32_MAX) error = "timer unavailable";
    else if (call_i2c_capture(I2C_CAPTURE_ARM_PWM) == UINT32_MAX)
        error = "PWM ARM failed";
    else {
        /* No UART output while capture/READ response is active. */
        for (;;) {
            status = call_i2c_capture(I2C_CAPTURE_STATUS);
            if (status & I2C_CAPTURE_DONE) break;
            uint32_t now = (uint32_t)call_timer_measure_read_us();
            if (now == UINT32_MAX || now - start >= 10000000u ||
                ++polls >= 10000000u) {
                error = "CPU communication timeout / timer unavailable";
                call_i2c_capture(I2C_CAPTURE_ABORT);
                status = call_i2c_capture(I2C_CAPTURE_STATUS);
                break;
            }
        }
        count = call_i2c_capture(I2C_CAPTURE_COUNT);
        if (count <= 64) {
            for (unsigned i = 0; i < count; ++i)
                events[i] = call_i2c_capture(I2C_CAPTURE_POP);
            const char *decoded = pwm_test_decode(events, count, &result);
            if (!error) error = decoded;
        } else error = "invalid capture count";
        /* A partial/aborted capture must never report PASS. */
        if (status & I2C_CAPTURE_TIMEOUT) error = "RTL communication timeout";
        else if (status & I2C_CAPTURE_OVERFLOW) error = "capture overflow";
        else if (status & I2C_CAPTURE_ABORTED) {
            if (!error) error = "capture aborted";
        } else if (!(status & I2C_CAPTURE_LIMIT) && !error)
            error = "capture did not reach transaction limit";
    }
    call_timer_measure_end_us();
    if (result.write_seen)
        printf("Arduino WRITE: left=%d right=%d\n", result.left, result.right);
    if (result.read_seen) printf("Arduino READ: %d bytes\n", result.read_bytes);
    if (result.report_seen) {
        printf("Arduino ACK: left=%d right=%d\n", result.ack_left, result.ack_right);
        if (result.report_status & 0x80)
            printf("Arduino status bit7 set: transport test only; motor use disabled.\n");
    }
    if (error) printf("PWM communication FAIL: %s\n", error);
    else printf("PWM communication PASS\n");
}
