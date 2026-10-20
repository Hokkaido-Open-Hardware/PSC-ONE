#pragma once
#include <stdint.h>

typedef struct {
    int16_t ax, ay, az, temperature, gx, gy, gz;
    unsigned address, repeated_start;
} imu_sample;

typedef struct {
    float angle, q_bias, p00, p01, p10, p11;
} imu_filter;

/* Scan only within one frozen capture; never join across ARM boundaries. */
int imu_decode(const uint32_t *events, unsigned count, unsigned *cursor,
               imu_sample *sample);
void imu_reset(imu_filter *filter);
void imu_update(imu_filter *filter, const imu_sample *sample, float dt,
                float *acc_angle, float *gyro_x);
int imu_self_test(void);
void cmd_i2c_imu(int mode); /* 0 read, 1 test, 2 monitor */

/* Software receipt timestamps, modulo 2^32 microseconds. */
#define IMU_MAX_DT_US 250000u
typedef struct {
    imu_filter filter;
    uint32_t previous_us;
    unsigned initialized;
} imu_tracker;
/* 1: initialized/updated; 0: zero/long dt; -1: invalid angle input.
 * Long intervals rebase time only; invalid input preserves all state. */
int imu_track(imu_tracker *tracker, const imu_sample *sample, uint32_t now_us,
              float *dt, float *acc, float *gyro);
