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

    // sd_rw_ready=1ではない場合
    if ((PSC_SD_IF_CTRL & 0x04) == 0x00) {
        // sd init_start
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
        buf[i] = (unsigned char)(PSC_IF_DATA & 0xFF);
    }

    return 0;
}

static int sd_write_once(uint32_t sd_sector_address, const uint8_t *buf)
{
    uint32_t timeout;

    // ---- INIT ----
    // FIFO flush
    PSC_SD_IF_CTRL = 0x04;
    tiny_delay(READINIT_WAIT);

    // データをFIFO_Wに書き込み
    for (int i = 0; i < 512; i++) {
        PSC_IF_DATA = buf[i] & 0xFF;
        //s_printf("WDATA=%x\n", buf[i] & 0xFF);
    }

    // sd_rw_ready=1ではない場合
    if ((PSC_SD_IF_CTRL & 0x04) == 0x00) {
        // sd init_start
        PSC_SD_IF_CTRL = 0x01;
    }

    timeout = TIMEOUT_CYCLE;
    while (PSC_SD_IF_CTRL & 0x02) {
        if (--timeout == 0) return -1;
    }

    // wait
    tiny_delay(READCMD_WAIT);

    // ---- WRITE ----
    PSC_SD_SECTOR = sd_sector_address;
    PSC_SD_IF_CTRL = 0x10;

    // wait
    tiny_delay(READSECTOR_WAIT);

    timeout = TIMEOUT_CYCLE;
    while ((PSC_SD_IF_CTRL & 0x04) == 0) {
        if (--timeout == 0) return -2;
    }

    // wait
    tiny_delay(READDATA_WAIT);

    // ---- DATA ----
    /*
    for (int i = 0; i < 512; i++) {
        timeout = TIMEOUT_CYCLE;
        while (PSC_SD_IF_CTRL & (1 << 3)) {
            if (--timeout == 0) return -3;
        }
        buf[i] = (unsigned char)(SD_IF_DATA & 0xFF);
    }
    */

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
int sd_read_sector(uint32_t sector, uint8_t *buf)
{
    return sd_read_once(sector, buf);
}

// -------------------------------------------------------
int sd_write_sector(uint32_t sector, uint8_t *buf)
{
    const int retry_max = 3;

    for (int retry = 0; retry < retry_max; retry++) {

        if (sd_write_once(sector, buf) != 0) {
            s_printf("WRITE FAIL retry=%d\n", retry);
            continue;
        }

        uint8_t verify[512];

        if (sd_read_sector(sector, verify) != 0) {
            s_printf("VERIFY READ ERROR\n");
            continue;
        }

        bool ok = true;

        for (int i = 0; i < 512; i++) {
            if (verify[i] != buf[i]) {
                s_printf("VERIFY ERROR sector=%x byte=%d\n", sector, i);
                s_printf("WRITE=%x READ=%x\n", buf[i], verify[i]);
                ok = false;
                break;
            }
        }

        if (ok)
            return 0;
    }

    return -1;
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
// -------------------------------------------------------
// SDカードWRITE実行関数
// -------------------------------------------------------
int s_call_sdcard_write_api(
    uint32_t sd_sector_address,
    const uint8_t *buf)
{
    s_printf("WRITE START\n");

    const int retry_max = 3;

    for (int retry = 0; retry < retry_max; retry++) {

        if (sd_write_once(sd_sector_address, buf) == 0) {
            s_printf("WRITE END\n");
            return 0;
        }

        s_printf("WRITE FAIL retry=%d\n", retry);
    }

    s_printf("WRITE ERROR\n");

    return -1;
}