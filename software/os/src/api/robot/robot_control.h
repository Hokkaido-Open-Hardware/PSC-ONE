#pragma once

/* Shell entry (U-mode syscall) and kernel implementation. */
void call_robot_control(void);
void robot_control(void);

#include <stdint.h>

/* Wire v1: pitch/0.004 rad, filtered rate/0.04 rad/s,
 * filtered wheel velocity/0.5 rad/s, target velocity/0.004 m/s.
 * Output is common wheel velocity/0.25 rad/s. Zero points are all zero.
 * Rounded fixed-point approximation of PSC_Robot's LQR, saturated to INT8.
 * No floating point, NPU or change to the I2C peripheral is required. */
int8_t robot_control_compute(const int8_t input[4]);
int robot_control_poll(void);
void robot_control_run(void) __attribute__((noreturn));
