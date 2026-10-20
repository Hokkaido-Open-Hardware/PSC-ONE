#include "imu.h"

/* The freestanding shell links RV32 ILP32 picolibc libm and libgcc. */
extern float atan2f(float, float);

static int16_t signed_word(const uint32_t *p)
{
    int value = (int)((p[0] & 255u) * 256u + (p[1] & 255u));
    return (int16_t)(value >= 32768 ? value - 65536 : value);
}

int imu_decode(const uint32_t *e, unsigned count, unsigned *cursor,
               imu_sample *s)
{
    if (count > 64u) return 0;
    while (*cursor < count) {
        unsigned i = (*cursor)++, j, address, repeated;
        if (count - i < 20u || e[i] != 0x200u) continue;
        address = e[i + 1];
        if (address != 0x8d0u && address != 0x8d2u) continue;
        if (e[i + 2] != 0xa3bu) continue; /* exactly one ACKed register */
        j = i + 3;
        repeated = e[j] == 0x400u;
        if (repeated) ++j;
        else {
            /* Arduino Wire.endTransmission() emits STOP by default. */
            if (e[j] != 0x600u || e[j + 1] != 0x200u) continue;
            j += 2;
        }
        if (count - j < 16u || e[j++] != (address | 1u)) continue;
        unsigned data = j;
        for (unsigned k = 0; k < 14; ++k, ++j) {
            /* Slave ACKs address; master ACKs 13 bytes and NACKs last. */
            if ((e[j] & ~255u) != (k == 13 ? 0xb00u : 0xa00u)) break;
        }
        if (j != data + 14 || e[j] != 0x600u) continue;
        s->ax = signed_word(e + data);
        s->ay = signed_word(e + data + 2);
        s->az = signed_word(e + data + 4);
        s->temperature = signed_word(e + data + 6);
        s->gx = signed_word(e + data + 8);
        s->gy = signed_word(e + data + 10);
        s->gz = signed_word(e + data + 12);
        s->address = (address & 255u) >> 1;
        s->repeated_start = repeated;
        *cursor = j + 1;
        return 1;
    }
    return 0;
}

void imu_reset(imu_filter *f)
{
    *f = (imu_filter){0, 0, 1, 0, 0, 1};
}

void imu_update(imu_filter *f, const imu_sample *s, float dt,
                float *acc, float *gyro)
{
    *acc = atan2f((float)s->ay, (float)s->az) * 57.3f;
    *gyro = ((float)s->gx - 128.1f) / 131.0f;
    f->angle += (*gyro - f->q_bias) * dt;
    float error = *acc - f->angle;
    /* Tumbller Pdot uses the old covariance, including old P11. */
    float d00 = 0.001f - f->p01 - f->p10;
    float d01 = -f->p11, d10 = -f->p11;
    f->p00 += d00 * dt;
    f->p01 += d01 * dt;
    f->p10 += d10 * dt;
    f->p11 += 0.005f * dt;
    float k0 = f->p00 / (0.5f + f->p00);
    float k1 = f->p10 / (0.5f + f->p00);
    float t0 = f->p00, t1 = f->p01;
    f->p00 -= k0 * t0;
    f->p01 -= k0 * t1;
    f->p10 -= k1 * t0;
    f->p11 -= k1 * t1;
    f->angle += k0 * error;
    f->q_bias += k1 * error;
}

static int near(float value, float expected)
{
    float d = value - expected;
    return d > -0.0001f && d < 0.0001f;
}

int imu_self_test(void)
{
    imu_filter f;
    imu_sample s = {0};
    float acc, gyro;
    s.ay = 2845; s.az = 16135; s.gx = 1441;
    imu_reset(&f);
    imu_update(&f, &s, 0.005f, &acc, &gyro);
    return near(acc, 10.000613f) && near(gyro, 10.022137f) &&
           near(f.angle, 6.683790f) && near(f.q_bias, -0.033168f) &&
           near(f.p00, 0.333334f) && near(f.p01, -0.001667f) &&
           near(f.p10, -0.001667f) && near(f.p11, 1.000008f);
}

int imu_track(imu_tracker *t, const imu_sample *s, uint32_t now,
              float *dt, float *acc, float *gyro)
{
    *dt = 0;
    /* atan2(0,0) supplies no observable angle. */
    if (s->ay == 0 && s->az == 0) return -1;
    if (!t->initialized) {
        *acc = atan2f((float)s->ay, (float)s->az) * 57.3f;
        *gyro = ((float)s->gx - 128.1f) / 131.0f;
        imu_reset(&t->filter);
        t->filter.angle = *acc;
        t->previous_us = now;
        t->initialized = 1;
        return 1;
    }
    uint32_t elapsed = now - t->previous_us;
    *dt = (float)elapsed / 1000000.0f;
    if (!elapsed) {
        *acc = atan2f((float)s->ay, (float)s->az) * 57.3f;
        *gyro = ((float)s->gx - 128.1f) / 131.0f;
        return 0;
    }
    t->previous_us = now;
    if (elapsed > IMU_MAX_DT_US) {
        *acc = atan2f((float)s->ay, (float)s->az) * 57.3f;
        *gyro = ((float)s->gx - 128.1f) / 131.0f;
        return 0;
    }
    imu_update(&t->filter, s, *dt, acc, gyro);
    return 1;
}
