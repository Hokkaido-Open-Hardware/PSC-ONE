// fft_api.h
#pragma once
#include <stdint.h>

#define FFT_MAX_SIZE 1024

/*============================================================
    Complex (Q15)
============================================================*/

typedef struct
{
    int32_t re;
    int32_t im;

} fft_complex_t;

/*============================================================
    Twiddle Table
============================================================*/

extern const fft_complex_t fft_twiddle[FFT_MAX_SIZE / 2];

/*============================================================
    API
============================================================*/

fft_complex_t fft_mul_q15(fft_complex_t a, fft_complex_t b);
int fft_q15(fft_complex_t *x, int n);