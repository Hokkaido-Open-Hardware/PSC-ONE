//! api/speech_recognition_api.c/.h. Fixed-point feature extractor and classifier.
//! A caller-owned Workspace replaces global scratch; reuse it between calls.
pub const SAMPLE_RATE: usize = 16000;
pub const RECORD_SAMPLES: usize = 48000;
#[derive(Default, Debug, Clone, Copy)]
pub struct ResultData {
    pub class_id: i32,
    pub score: [i32; 3],
    pub voice_start: u32,
    pub voice_end: u32,
}
pub struct Workspace {
    centered: [i32; 16000],
    re: [i32; 4096],
    im: [i32; 4096],
}
impl Default for Workspace {
    fn default() -> Self {
        Self {
            centered: [0; 16000],
            re: [0; 4096],
            im: [0; 4096],
        }
    }
}

/// Decode immutable signed model/window coefficients from little-endian asset bytes.
fn table(b: &[u8], i: usize) -> i32 {
    i32::from_le_bytes(b[i * 4..i * 4 + 4].try_into().unwrap())
}

/// Clamp wide intermediate results before narrowing to the fixed-point storage type.
fn sat(v: i64) -> i32 {
    v.clamp(i32::MIN as i64, i32::MAX as i64) as i32
}
const MEAN: &[u8] = include_bytes!("../../assets/trained_feature_mean_q16.bin");
const INV: &[u8] = include_bytes!("../../assets/trained_feature_inv_std_q16.bin");
const W1: &[u8] = include_bytes!("../../assets/trained_w1_q16.bin");
const B1: &[u8] = include_bytes!("../../assets/trained_b1_q16.bin");
const W2: &[u8] = include_bytes!("../../assets/trained_w2_q16.bin");
const B2: &[u8] = include_bytes!("../../assets/trained_b2_q16.bin");
const HANN: &[u8] = include_bytes!("../../assets/speech_hann_q30.bin");
const COS: &[u8] = include_bytes!("../../assets/speech_twiddle_cos_q30.bin");
const SIN: &[u8] = include_bytes!("../../assets/speech_twiddle_sin_q30.bin");
const LOG: &[u8] = include_bytes!("../../assets/speech_log2_mantissa_q16.bin");
const BAND_START: &[u8] = include_bytes!("../../assets/speech_band_start.bin");
const BAND_END: &[u8] = include_bytes!("../../assets/speech_band_end.bin");
/// Read one frequency-band boundary from the original u16 lookup table.
fn band(b: &[u8], i: usize) -> usize {
    u16::from_le_bytes([b[2 * i], b[2 * i + 1]]) as usize
}

/// Normalize 64 features, apply the 16-neuron ReLU layer, and produce three Q16 scores.
pub fn run_trained_network_q16(features: &[i32; 64]) -> [i32; 3] {
    let mut norm = [0; 64];
    let mut hidden = [0; 16];
    let mut scores = [0; 3];
    for i in 0..64 {
        norm[i] =
            sat((features[i].wrapping_sub(table(MEAN, i)) as i64 * table(INV, i) as i64) >> 16);
    }
    for h in 0..16 {
        let mut acc = (table(B1, h) as i64) << 16;
        for i in 0..64 {
            acc = acc.wrapping_add(norm[i] as i64 * table(W1, i * 16 + h) as i64);
        }
        hidden[h] = sat(acc >> 16).max(0);
    }
    for o in 0..3 {
        let mut acc = (table(B2, o) as i64) << 16;
        for h in 0..16 {
            acc = acc.wrapping_add(hidden[h] as i64 * table(W2, h * 3 + o) as i64);
        }
        scores[o] = sat(acc >> 16);
    }
    scores
}

/// Compute the integer square root by consuming two input bits per iteration.
fn isqrt(mut op: u64) -> u32 {
    let mut result = 0;
    let mut one = 1u64 << 62;
    while one > op {
        one >>= 2;
    }
    while one != 0 {
        if op >= result + one {
            op -= result + one;
            result = (result >> 1) + one;
        } else {
            result >>= 1;
        }
        one >>= 2;
    }
    result as u32
}

/// Interpolate a 257-entry mantissa table after separating the binary exponent.
fn log2(value: u64) -> i32 {
    if value == 0 {
        return 0;
    }
    let exponent = 63 - value.leading_zeros();
    let mantissa = if exponent >= 24 {
        value >> (exponent - 24)
    } else {
        value << (24 - exponent)
    };
    let fraction = (mantissa - (1 << 24)) as u32;
    let i = (fraction >> 16) as usize;
    let a = table(LOG, i);
    let b = table(LOG, i + 1);
    ((exponent as i32) << 16) + a + (((b - a) as i64 * (fraction & 65535) as i64) >> 16) as i32
}

/// Sign-extend 24-bit audio, apply the reference gain of 12, and saturate to PCM16.
pub fn sample24_to_s16(raw: u32) -> i16 {
    let signed = ((raw << 8) as i32) >> 8;
    ((signed >> 8) * 12).clamp(-32768, 32767) as i16
}

/// Require two consecutive 256-sample blocks above the mean-absolute-amplitude threshold.
pub fn detect_voice_range(samples: &[i16]) -> Result<(usize, usize), i32> {
    let mut first = None;
    let mut last = 0;
    let mut run = 0;
    for (i, chunk) in samples.chunks_exact(256).enumerate() {
        let sum: u32 = chunk.iter().map(|x| x.unsigned_abs() as u32).sum();
        if sum / 256 >= 300 {
            run += 1;
            if run == 2 && first.is_none() {
                first = Some((i - 1) * 256);
            }
            last = (i + 1) * 256;
        } else {
            run = 0;
        }
    }
    match first {
        Some(first) if last > first => Ok((first, last)),
        _ => Err(-1),
    }
}
impl Workspace {
    /// Run the 4096-point Q30 FFT with one-bit scaling at each stage to control growth.
    fn fft(&mut self) {
        let mut j = 0;
        for i in 1..4096 {
            let mut bit = 2048;
            while j & bit != 0 {
                j ^= bit;
                bit >>= 1;
            }
            j ^= bit;
            if i < j {
                self.re.swap(i, j);
                self.im.swap(i, j);
            }
        }
        let mut len = 2;
        while len <= 4096 {
            let half = len / 2;
            let step = 4096 / len;
            for base in (0..4096).step_by(len) {
                for k in 0..half {
                    let wr = table(COS, k * step) as i64;
                    let wi = -table(SIN, k * step) as i64;
                    let even = base + k;
                    let odd = even + half;
                    let br = self.re[odd] as i64;
                    let bi = self.im[odd] as i64;
                    let tr = ((wr * br - wi * bi) >> 30) as i32;
                    let ti = ((wr * bi + wi * br) >> 30) as i32;
                    let ar = self.re[even];
                    let ai = self.im[even];
                    self.re[even] = ar.wrapping_add(tr) >> 1;
                    self.im[even] = ai.wrapping_add(ti) >> 1;
                    self.re[odd] = ar.wrapping_sub(tr) >> 1;
                    self.im[odd] = ai.wrapping_sub(ti) >> 1;
                }
            }
            len *= 2;
        }
    }

    /// Locate active speech, crop around its peak or center-pad, then normalize amplitude to 0.95.
    fn center(&mut self, samples: &[i16]) -> Result<(), i32> {
        if samples.len() < 320 {
            return Err(-1);
        }
        let energy = |start: usize| -> u64 {
            samples[start..start + 320]
                .iter()
                .map(|&x| (x as i64 * x as i64) as u64)
                .sum()
        };
        let max = (0..=samples.len() - 320)
            .step_by(160)
            .map(&energy)
            .max()
            .unwrap_or(0);
        let threshold = (max * 144 / 10000).max(9664 * 320);
        let mut first = None;
        let mut last = 0;
        for start in (0..=samples.len() - 320).step_by(160) {
            if energy(start) >= threshold {
                if first.is_none() {
                    first = Some(start);
                }
                last = start;
            }
        }
        let (start, end) = if let Some(first) = first {
            (
                first.saturating_sub(800),
                (last + 320 + 800).min(samples.len()),
            )
        } else {
            (0, samples.len())
        };
        let len = end - start;
        if len >= 16000 {
            let mut peak = 0;
            let mut value = -1;
            for i in 0..len {
                let v = (samples[start + i] as i32).abs();
                if v > value {
                    value = v;
                    peak = i;
                }
            }
            let crop = peak.saturating_sub(8000).min(len - 16000);
            for i in 0..16000 {
                self.centered[i] = (samples[start + crop + i] as i32) << 15;
            }
        } else {
            self.centered.fill(0);
            let offset = (16000 - len) / 2;
            for i in 0..len {
                self.centered[offset + i] = (samples[start + i] as i32) << 15;
            }
        }
        let peak = self.centered.iter().map(|x| x.abs()).max().unwrap_or(0);
        if peak > 0 {
            for x in &mut self.centered {
                *x = sat(*x as i64 * 1020054733 / peak as i64);
            }
        }
        Ok(())
    }

    /// Window four regions, measure 16 log-power bands each, then standardize each region.
    pub fn speech_extract_features(&mut self, samples: &[i16]) -> Result<[i32; 64], i32> {
        self.center(samples)?;
        let mut features = [0; 64];
        for region in 0..4 {
            let base = region * 4000;
            let sum: i64 = self.centered[base..base + 4000]
                .iter()
                .map(|&v| v as i64)
                .sum();
            let mean = (sum / 4000) as i32;
            for i in 0..4096 {
                self.re[i] = if i < 4000 {
                    ((self.centered[base + i].wrapping_sub(mean) as i64 * table(HANN, i) as i64)
                        >> 30) as i32
                } else {
                    0
                };
                self.im[i] = 0;
            }
            self.fft();
            let mut logs = [0i32; 16];
            for b in 0..16 {
                let start = band(BAND_START, b);
                let end = band(BAND_END, b);
                let mut power = 0u64;
                for k in start..end {
                    let re = self.re[k] as i64;
                    let im = self.im[k] as i64;
                    power = power.wrapping_add((re * re + im * im) as u64);
                }
                if end > start {
                    power /= (end - start) as u64;
                }
                logs[b] = log2(power + (1 << 36)) - (36 << 16);
            }
            let mean = (logs.iter().map(|&v| v as i64).sum::<i64>() >> 4) as i32;
            let variance: u64 = logs
                .iter()
                .map(|&v| {
                    let d = v as i64 - mean as i64;
                    (d * d) as u64
                })
                .sum();
            let std = isqrt(variance >> 4).max(1);
            for b in 0..16 {
                features[region * 16 + b] =
                    sat(((logs[b] as i64 - mean as i64) << 16) / std as i32 as i64);
            }
        }
        Ok(features)
    }

    /// Use at most the first two seconds, detect voice, extract features, and choose the largest score.
    pub fn speech_recognize_pcm(&mut self, samples: &[i16]) -> Result<ResultData, i32> {
        if samples.is_empty() {
            return Err(-1);
        }
        let samples = &samples[..samples.len().min(32000)];
        let (start, end) = detect_voice_range(samples).map_err(|_| -2)?;
        let features = self.speech_extract_features(samples).map_err(|_| -3)?;
        let score = run_trained_network_q16(&features);
        let mut class = 0;
        for i in 1..3 {
            if score[i] > score[class] {
                class = i;
            }
        }
        Ok(ResultData {
            class_id: class as i32,
            score,
            voice_start: start as u32,
            voice_end: end as u32,
        })
    }
}

/// Translate the numeric classifier result into the shell-facing class name.
pub fn speech_class_name(id: i32) -> &'static str {
    match id {
        0 => "UP",
        1 => "DOWN",
        2 => "UNKNOWN",
        _ => "ERROR",
    }
}

/// Flush old I2S samples and stop recording at the first microphone timeout.
pub unsafe fn speech_record(samples: &mut [i16]) -> usize {
    crate::common::mmio_w32(0x10007004, 1);
    for (i, s) in samples.iter_mut().enumerate() {
        match crate::drivers::mic_api::mic_read_sample24() {
            Ok(raw) => *s = sample24_to_s16(raw),
            Err(_) => return i,
        }
    }
    samples.len()
}

/// Record three seconds into static scratch, classify, and emit diagnostic scores.
pub unsafe fn s_call_speech_recognition_api() -> i32 {
    static mut PCM: [i16; 48000] = [0; 48000];
    static mut WORK: Workspace = Workspace {
        centered: [0; 16000],
        re: [0; 4096],
        im: [0; 4096],
    };
    let pcm = &mut *core::ptr::addr_of_mut!(PCM);
    crate::s_print!("SPEECH RECORD START samples=48000\n");
    if speech_record(pcm) != 48000 {
        return -1;
    }
    match (&mut *core::ptr::addr_of_mut!(WORK)).speech_recognize_pcm(pcm) {
        Ok(r) => {
            crate::s_print!(
                "VOICE RANGE start={} end={}\nSCORE UP={} DOWN={} UNKNOWN={}\nSPEECH RESULT={}\n",
                r.voice_start,
                r.voice_end,
                r.score[0],
                r.score[1],
                r.score[2],
                speech_class_name(r.class_id)
            );
            r.class_id
        }
        Err(e) => {
            crate::s_print!("SPEECH RECOGNITION ERROR={}\n", e);
            -1
        }
    }
}

/// Legacy INT8 model metadata. Fixed array sizes make invalid C-style buffers impossible.
/// The normal PCM recognizer uses the embedded Q16 model, as in the original C source.
pub struct SpeechModel {
    pub dense1_weight: &'static [i8; 1024],
    pub dense1_bias: &'static [i32; 16],
    pub dense2_weight: &'static [i8; 48],
    pub dense2_bias: &'static [i32; 3],
    pub dense1_shift: u8,
    pub dense2_shift: u8,
}
static mut LEGACY_MODEL: Option<&'static SpeechModel> = None;

/// Select legacy weights, or restore the UNKNOWN-only dummy model with None.
/// The kernel must serialize model changes with legacy inference calls.
pub unsafe fn speech_recognition_set_model(model: Option<&'static SpeechModel>) {
    LEGACY_MODEL = model;
}

/// Retain the optional legacy path without changing the trained PCM classifier.
pub unsafe fn run_dense_network(features: &[i32; 64]) -> [i32; 3] {
    let Some(model) = LEGACY_MODEL else {
        return [0, 0, 1];
    };
    let round = |value: i32, shift: u8| {
        if shift == 0 {
            return value;
        }
        if shift >= 31 {
            return if value < 0 { -1 } else { 0 };
        }
        let half = 1i32 << (shift - 1);
        if value >= 0 {
            value.wrapping_add(half) >> shift
        } else {
            (value.wrapping_neg().wrapping_add(half) >> shift).wrapping_neg()
        }
    };
    let mut hidden = [0i32; 16];
    for h in 0..16 {
        let mut sum = model.dense1_bias[h];
        for i in 0..64 {
            sum =
                sum.wrapping_add(features[i].wrapping_mul(model.dense1_weight[h * 64 + i] as i32));
        }
        hidden[h] = round(sum, model.dense1_shift).max(0);
    }
    core::array::from_fn(|output| {
        let mut sum = model.dense2_bias[output];
        for h in 0..16 {
            sum = sum
                .wrapping_add(hidden[h].wrapping_mul(model.dense2_weight[output * 16 + h] as i32));
        }
        round(sum, model.dense2_shift)
    })
}
