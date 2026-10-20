#ifdef IMU_HOST_TEST
#include <stdio.h>
#include "../api/i2c_capture.h"
int getchar_timeout(void);
int call_timer_measure_begin(void);
int call_timer_measure_read_us(void);
int call_timer_measure_end_us(void);
#else
#include "../api/user.h"
#endif
#include "imu.h"

static void decimal(float value)
{
    /* No %f or field widths in the shell's printf. Six decimal places. */
    if (value < 0) { putchar('-'); value = -value; }
    int whole = (int)value;
    int fraction = (int)((value - (float)whole) * 1000000.0f + 0.5f);
    if (fraction == 1000000) { ++whole; fraction = 0; }
    printf("%d.", whole);
    for (int divisor = 100000; divisor; divisor /= 10)
        putchar('0' + (fraction / divisor) % 10);
}

static void raw(const imu_sample *s)
{
    printf("MPU6050 addr=%x reg=0x3B len=14 %s\n",
           s->address, s->repeated_start ? "Repeated START" : "STOP->START");
    printf("ax=%d ay=%d az=%d temp_raw=%d gx=%d gy=%d gz=%d\n",
           s->ax, s->ay, s->az, s->temperature, s->gx, s->gy, s->gz);
}

void cmd_i2c_imu(int mode)
{
    uint32_t events[64];
    imu_filter filter;
    imu_tracker tracker = {0};
    float dt = 0;
    unsigned skipped_dt = 0, invalid = 0;
    imu_sample sample = {0};
    float acc = 0, gyro = 0;
    unsigned samples = 0, gaps = 0, rejected = 0, timeouts = 0;
    unsigned polls = 0;
    int compute_us = -1;
    uint32_t last_display = 0, batch_start = 0;
    int monitor = mode == 2, armed = 0;
    imu_reset(&filter);
    if (mode == 1) {
        int pass = imu_self_test();
        printf("IMU self-test %s (tolerance 0.0001; independent state)\n",
               pass ? "PASS" : "FAIL");
        if (!pass) return;
    }
    printf("Passive IMU capture; q/Ctrl-C exits; bounded wait.\n");
    if (monitor)
        printf("Snapshot mode: no event timestamps, capture stops after 2 STOPs.\n"
               "Software receipt dt includes capture/UART latency; lost count unknown.\n"
               "dt=0 or dt>250ms: skip update; long dt rebases time only.\n"
               "Arduino comparison requires identical inputs, initial state and period.\n");
    /* Require a usable timebase for deadlines and 100ms display throttling. */
    if (call_timer_measure_begin() != 0) {
        printf("IMU: timer busy; capture not started.\n");
        return;
    }
    uint32_t command_start = (uint32_t)call_timer_measure_read_us();
    if (command_start == UINT32_MAX) goto finished;
    last_display = batch_start = command_start;
    if (call_i2c_capture(I2C_CAPTURE_ARM) == (uint32_t)-1) goto arm_failed;
    armed = 1;
    for (;;) {
        int ch = getchar_timeout();
        if (ch == 'q' || ch == 3) break;
        uint32_t now = (uint32_t)call_timer_measure_read_us();
        if (now == UINT32_MAX) {
            printf("IMU: timer unavailable (or reserved -1 tick); stopping.\n");
            break;
        }
        if (++polls >= 10000000u || now - batch_start >= 10000000 ||
            (!monitor && now - command_start >= 10000000u)) {
            printf("IMU: CPU timeout; no complete sample within deadline.\n");
            break;
        }
        uint32_t status = call_i2c_capture(I2C_CAPTURE_STATUS);
        if (!(status & I2C_CAPTURE_DONE)) continue;
        armed = 0;
        uint32_t count = call_i2c_capture(I2C_CAPTURE_COUNT);
        if (count > 64u) {
            printf("IMU: invalid capture count.\n");
            break;
        }
        for (unsigned i = 0; i < count; ++i)
            events[i] = call_i2c_capture(I2C_CAPTURE_POP);
        uint32_t acquired_us = (uint32_t)call_timer_measure_read_us();
        if (acquired_us == UINT32_MAX) break;
        if (status & I2C_CAPTURE_TIMEOUT) ++timeouts;
        /* A complete STOP-delimited sample before a later timeout/overflow
         * remains valid. The parser never consumes an incomplete suffix. */
        ++gaps; /* each ARM boundary has unknown continuity, NOT lost count */
        if (monitor) {
            /* Rearm before math/UART; hardware captures independently.
             * It can still freeze during UART: this is not a stream FIFO. */
            if (call_i2c_capture(I2C_CAPTURE_ARM) == (uint32_t)-1) goto arm_failed;
            armed = 1;
        }
        unsigned cursor = 0, found = 0;
        while (imu_decode(events, count, &cursor, &sample)) {
            ++found; ++samples;
            if (mode == 0) { raw(&sample); goto finished; }
            int start = call_timer_measure_read_us();
            if (monitor) {
                int updated = imu_track(&tracker, &sample, acquired_us, &dt, &acc, &gyro);
                if (updated < 0) ++invalid;
                else if (!updated) ++skipped_dt;
                filter = tracker.filter;
            } else {
                imu_reset(&filter);
                imu_update(&filter, &sample, 0.0f, &acc, &gyro);
            }
            int end = call_timer_measure_read_us();
            compute_us = start != -1 && end != -1 ?
                (int)((uint32_t)end - (uint32_t)start) : -1;
            if (!monitor) {
                raw(&sample);
                break;
            }
        }
        if (!found || (status & (I2C_CAPTURE_OVERFLOW | I2C_CAPTURE_ABORTED)))
            ++rejected;
        now = (uint32_t)call_timer_measure_read_us();
        if (now == UINT32_MAX) break;
        if ((!monitor && found) || (monitor && now - last_display >= 100000)) {
            printf("samples=%d gaps_unknown=%d rejected_batches=%d timeouts=%d",
                   (int)samples, (int)gaps, (int)rejected, (int)timeouts);
            if (monitor) {
                printf(" skipped_dt=%d invalid_samples=%d dt_ms=", (int)skipped_dt, (int)invalid);
                decimal(dt * 1000.0f);
            }
            if (samples) {
                printf(" acc_deg="); decimal(acc);
                printf(" gyro_dps="); decimal(gyro);
                printf(" estimate_deg="); decimal(filter.angle);
                printf(" bias="); decimal(filter.q_bias);
                printf(" compute_us=%d", compute_us);
                if (!monitor) printf(" [reset, dt=0, NOT converged]");
            }
            printf("\n");
            last_display = now;
        }
        if (!monitor && found) break;
        if (!monitor) {
            if (call_i2c_capture(I2C_CAPTURE_ARM) == (uint32_t)-1) goto arm_failed;
            armed = 1;
        }
        batch_start = now;
        polls = 0;
    }
    goto finished;
arm_failed:
    printf("IMU: capture ARM failed.\n");
finished:
    if (armed) call_i2c_capture(I2C_CAPTURE_ABORT);
    call_timer_measure_end_us();
    printf("IMU stopped: samples=%d gaps_unknown=%d rejected_batches=%d timeouts=%d\n",
           (int)samples, (int)gaps, (int)rejected, (int)timeouts);
}
