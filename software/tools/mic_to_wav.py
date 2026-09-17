#!/usr/bin/env python3

import wave
import numpy as np
import matplotlib.pyplot as plt

# ----------------------------------------------------------
# RAWデータダンプ
# ----------------------------------------------------------
def dump_raw(pcm, count=64):

    print("----- RAW PCM DUMP -----")

    for i in range(min(count, len(pcm))):
        print(f"{i:6d} : 0x{np.uint32(pcm[i]):08X}  {pcm[i]:11d}")

    print("------------------------")

# ----------------------------------------------------------
# MIC.TXT → int32 PCM
# ----------------------------------------------------------
def load_mic_file(filename, skip_bytes=0):

    with open(filename, "rb") as f:
        data = f.read()

    data = data[skip_bytes:]

    n = len(data) // 4

    # 32bit signed PCM
    pcm = np.frombuffer(data[:n * 4], dtype="<i4")

    for i in range(10):
        print(i, hex(np.uint32(pcm[i])), pcm[i])

    bad = np.where(np.abs(pcm) > 1000000)[0]

    print("bad count =", len(bad))

    if len(bad):
        print("first bad =", bad[0])

        for i in range(max(0, bad[0]-5), bad[0]+5):
            print(i, hex(np.uint32(pcm[i])), pcm[i])

    dump_raw(pcm, 5000)

    return pcm

# ----------------------------------------------------------
# WAV保存
# ----------------------------------------------------------
def save_wav(filename, pcm24, sample_rate=16000, gain=12.0):

    pcm16 = (pcm24 >> 8).astype(np.float64)

    pcm16 *= gain

    pcm16 = np.clip(
        pcm16,
        -32768,
        32767
    ).astype(np.int16)

    with wave.open(filename, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        w.writeframes(pcm16.tobytes())


# ----------------------------------------------------------
# 波形表示
# ----------------------------------------------------------
def plot_wave(pcm24, sample_rate=16000):

    t = np.arange(len(pcm24)) / sample_rate

    plt.figure(figsize=(12,4))
    plt.plot(t, pcm24)
    plt.title("Waveform")
    plt.xlabel("Time [sec]")
    plt.ylabel("Amplitude")
    plt.grid(True)
    plt.show()


# ----------------------------------------------------------
# FFT表示
# ----------------------------------------------------------
def plot_fft(pcm24, sample_rate=16000):

    x = pcm24.astype(np.float64)

    spec = np.fft.rfft(x)

    freq = np.fft.rfftfreq(len(x), 1.0/sample_rate)

    plt.figure(figsize=(12,4))
    plt.plot(freq, np.abs(spec))
    plt.title("FFT")
    plt.xlabel("Frequency [Hz]")
    plt.ylabel("Magnitude")
    plt.grid(True)
    plt.show()


# ----------------------------------------------------------
# スペクトログラム
# ----------------------------------------------------------
def plot_spectrogram(pcm24, sample_rate=16000):

    plt.figure(figsize=(12,5))

    plt.specgram(
        pcm24,
        NFFT=512,
        Fs=sample_rate,
        noverlap=256
    )

    plt.title("Spectrogram")
    plt.xlabel("Time [sec]")
    plt.ylabel("Frequency [Hz]")
    plt.colorbar()

    plt.show()


# ----------------------------------------------------------
# 統計
# ----------------------------------------------------------
def print_info(pcm24, sample_rate=16000):

    print("Samples   :", len(pcm24))
    print("Duration  :", len(pcm24)/sample_rate, "sec")
    print("Min       :", pcm24.min())
    print("Max       :", pcm24.max())
    print("Mean      :", pcm24.mean())
    print("Std       :", pcm24.std())


# ----------------------------------------------------------
# MAIN
# ----------------------------------------------------------
if __name__ == "__main__":

    SAMPLE_RATE = 16000

    pcm = load_mic_file(
        "MIC.TXT",
        skip_bytes=0
    )

    print_info(pcm, SAMPLE_RATE)

    save_wav(
        "mic.wav",
        pcm,
        SAMPLE_RATE
    )

    plot_wave(
        pcm,
        SAMPLE_RATE
    )

    plot_fft(
        pcm,
        SAMPLE_RATE
    )

    plot_spectrogram(
        pcm,
        SAMPLE_RATE
    )