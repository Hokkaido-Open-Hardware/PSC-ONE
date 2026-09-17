#ifndef SYSCALL_H
#define SYSCALL_H

/* syscall 番号定義 */
#define SYS_PUTCHAR         1
#define SYS_GETCHAR         2
#define SYS_GETCHAR_TIMEOUT 3

// --- SA ---
#define SYS_SA_RUN          10

// --- MIC ---
#define I2S_MIC_READ        20
#define I2S_MIC_WRITE       21

// --- SD CARD ---
#define SYS_SD_READ         30
#define SYS_SD_WRITE_TEST   31
#define SYS_SD_WRITE        32
#define SYS_SD_READ_BUF     33

// --- DUMP ---
#define SYS_DUMP            40

// --- SW ---
#define SYS_SW_READ         50

// --- FAT32 ---
#define SYS_READFILE        51
#define SYS_WRITEFILE       52

// --- SPEECH_RECOGNITION ---
#define SYS_SPEECH_RECOGNITION 60

// --- TIMER ---
#define SYS_TIMER_START           70
#define SYS_TIMER_START_AUTO      71
#define SYS_TIMER_STOP            72
#define SYS_TIMER_GET_COUNT       73
#define SYS_TIMER_GET_STATUS      74
#define SYS_TIMER_IS_RUNNING      75
#define SYS_TIMER_WAIT_US         76
#define SYS_TIMER_WAIT_MS         77

// --- LED ---

#define SYS_LED_WRITE             80
#define SYS_LED_ON                81
#define SYS_LED_OFF               82
#define SYS_LED_TOGGLE            83
#define SYS_LED_ALL_ON            84
#define SYS_LED_ALL_OFF           85
#define SYS_LED_GET_STATE         86

// --- SYSTEM ---
#define SYS_EXIT            90
#define SYS_PRINT_INT       91

#endif
