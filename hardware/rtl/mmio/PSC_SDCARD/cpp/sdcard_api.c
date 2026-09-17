#include "sdcard_api.h"
#include "kernel.h"
#include "common.h"

#define READINIT_WAIT   100
#define READCMD_WAIT    100
#define READSECTOR_WAIT 100
#define READDATA_WAIT    50

#define TIMEOUT_CYCLE   50000

static inline void tiny_delay(unsigned n){
    while (n--) {
        __asm__ __volatile__("nop");
    }
}

static int sd_read_once(uint32_t sd_sector_address, unsigned char *buf)
{
    uint32_t timeout;

    // ---- INIT ----
    // FIFO flush
    PSC_SD_IF_CTRL = 0x04;
    tiny_delay(READINIT_WAIT);

    // read_ready=1ではない場合
    if ((PSC_SD_IF_CTRL & 0x04) == 0x00) {
        PSC_SD_IF_CTRL = 0x01;
    }

    timeout = TIMEOUT_CYCLE;
    while (PSC_SD_IF_CTRL & 0x02) {
        if (--timeout == 0) return -1;
    }

    // wait
    tiny_delay(READCMD_WAIT);

    // ---- READ ----
    PSC_SD_SECTOR = sd_sector_address;
    PSC_SD_IF_CTRL = 0x02;

    // wait
    tiny_delay(READSECTOR_WAIT);

    timeout = TIMEOUT_CYCLE;
    while ((PSC_SD_IF_CTRL & 0x04) == 0) {
        if (--timeout == 0) return -2;
    }

    // wait
    tiny_delay(READDATA_WAIT);

    // ---- DATA ----
    for (int i = 0; i < 512; i++) {
        timeout = TIMEOUT_CYCLE;
        while (PSC_SD_IF_CTRL & (1 << 3)) {
            if (--timeout == 0) return -3;
        }
        buf[i] = (unsigned char)(PSC_SD_ADDR & 0xFF);
    }

    return 0;
}

static uint16_t sd_crc16(const unsigned char *buf)
{
    uint16_t crc = 0;

    for (int i = 0; i < 512; i++) {
        crc ^= (uint16_t)buf[i] << 8;
        for (int j = 0; j < 8; j++) {
            crc = (crc & 0x8000) ? (crc << 1) ^ 0x1021 : (crc << 1);
        }
    }
    return crc;
}

// -------------------------------------------------------
// SDカードREAD実行関数
void s_call_sdcard_read_api(uint32_t sd_sector_address)
{
    unsigned char buf[512];

    int retry_max = 3;
    int success = 0;

    for (int retry = 0; retry < retry_max; retry++) {

        if (sd_read_once(sd_sector_address, buf) != 0) {
            s_printf("READ FAIL retry=%d\n", retry);
            continue;
        }

        // CRC HW
        uint32_t ctrl = PSC_SD_IF_CTRL;
        uint16_t crc_hw = ((ctrl >> 24) & 0xFF) << 8 |
                          ((ctrl >> 16) & 0xFF);

        // CRC SW
        uint16_t crc = sd_crc16(buf);

        if (crc == crc_hw) {
            s_printf("CRC OK (retry=%d)\n", retry);
            success = 1;
            break;
        } else {
            s_printf("CRC NG retry=%d (calc=%x hw=%x)\n",
                     retry, crc, crc_hw);
        }
    }

    if (!success) {
        s_printf("CRC FAILED (final)\n");
    }

    // ---- dump（常に実行）----
    const char hex[] = "0123456789ABCDEF";

    for (int i = 0; i < 512; i++) {
        unsigned char d = buf[i];
        putchar(hex[(d >> 4) & 0xF]);
        putchar(hex[d & 0xF]);
        putchar(' ');
        if ((i & 15) == 15) putchar('\n');
    }
}
