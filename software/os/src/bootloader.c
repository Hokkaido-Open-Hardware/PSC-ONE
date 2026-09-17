#include "sdcard_api.h"
#include "kernel.h"
#include "common.h"
#include <stdint.h>

#define PIO32 (*(volatile uint32_t*)0x10001000)

#define KERNEL_LOAD_ADDR   0x00200000u
#define USER_LOAD_ADDR     0x00400000u

// UART ベースやビット定義が common.h に無ければ保険として定義
#ifndef UART_MMIO_BASE
#define UART_MMIO_BASE 0x10000000u
#endif

#ifndef UART_TX
#define UART_TX 0x0
#endif
#ifndef UART_RX
#define UART_RX 0x4
#endif
#ifndef UART_ST
#define UART_ST 0x8
#endif

#ifndef ST_TX_BUSY
#define ST_TX_BUSY (1u << 0)
#endif
#ifndef ST_RX_AVAIL
#define ST_RX_AVAIL (1u << 1)
#endif

/* -------------------------------------------------------
 * 必要に応じて変更
 * 例:
 *   kernel.img を LBA 100 から 128 sector
 *   user.img   を LBA 300 から  18 sector
 * ------------------------------------------------------- */
#define KERNEL_LBA_START   100u
#define KERNEL_LBA_COUNT   128u

#define USER_LBA_START     300u
#define USER_LBA_COUNT     18u

/* -------------------------------------------------------
 * デバッグ表示設定
 * ------------------------------------------------------- */
#if 1
#define SD_DEBUG_RW32          1
#define SD_DEBUG_WORDS_PER_SEC 16   /* 32bitワード表示数: 16なら先頭64byte */
#else
#define SD_DEBUG_RW32          0
#define SD_DEBUG_WORDS_PER_SEC 0
#endif

/* -------------------------------------------------------
 * PSC_SD_IF_CTRL bit
 *  bit0 : init trigger (write)
 *  bit1 : busy
 *  bit2 : read_ready
 *  bit3 : fifo_empty
 *  bit31:24 : CRC1
 *  bit23:16 : CRC2
 * ------------------------------------------------------- */
#define SD_CTRL_INIT_TRIG   0x01u
#define SD_CTRL_READ_TRIG   0x02u
#define SD_CTRL_FIFO_FLUSH  0x04u

#define SD_ST_BUSY          (1u << 1)
#define SD_ST_READ_READY    (1u << 2)
#define SD_ST_FIFO_EMPTY    (1u << 3)

#define SD_READ_RETRY_MAX   3u

/* ------------------------------------------------------- */
#if 0
#define UART_BASE          0x10000000u
void putchar(char c)
{
    volatile uint32_t *uart = (volatile uint32_t *)UART_BASE;

    while (uart[2] & 1u) {
    }

    uart[0] = (uint32_t)(uint8_t)c;
}
#endif

void putchar(char ch) {
    // 送信ビジー解除待ち
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
        __asm__ __volatile__("nop");
    }
    mmio_w32(UART_MMIO_BASE + UART_TX, (uint32_t)(uint8_t)ch);
}

/* common.c 用 */
void uart_putchar(char c)
{
    putchar(c);
}

void bl_print_hex(uint32_t v)
{
    for (int i = 7; i >= 0; i--) {
        uint8_t n = (v >> (i * 4)) & 0xF;
        putchar(n < 10 ? '0' + n : 'A' + n - 10);
    }
}

/* ------------------------------------------------------- */
void bl_print(const char *s)
{
    while (*s) {
        putchar(*s++);
    }
    
    /* debug
    while (1) {
        uint8_t v = (uint8_t)*s;

        bl_print_hex((uint32_t)s);
        putchar(':');
        bl_print_hex(v);
        putchar(' ');

        if (v >= 0x20 && v <= 0x7E) {
            putchar(v);
        }

        putchar('\n');

        if (v == 0) break;

        s++;
    }
    */
}

void bl_print_dec(uint32_t v)
{
    char buf[10];
    int i = 0;

    if (v == 0u) {
        putchar('0');
        return;
    }

    while (v > 0u) {
        buf[i++] = (char)('0' + (v % 10u));
        v /= 10u;
    }

    while (i > 0) {
        putchar(buf[--i]);
    }
}

static void bl_print_kv_hex(const char *key, uint32_t val)
{
    bl_print(key);
    bl_print_hex(val);
    bl_print("\n");
}

/* ------------------------------------------------------- */
static inline void tiny_delay(unsigned n)
{
    while (n--) {
        __asm__ __volatile__("nop");
    }
}

static inline void cpu_relax(void)
{
    __asm__ __volatile__("nop");
}

/* 命令キャッシュ同期 */
static inline void sync_icache(void)
{
    __asm__ __volatile__("fence.i" ::: "memory");
}

/* -------------------------------------------------------
 * little-endian 32bit読出し
 * buf は任意アラインメント対応
 * ------------------------------------------------------- */
static uint32_t load_le32_from_u8(const uint8_t *p)
{
    return ((uint32_t)p[0] << 0)
         | ((uint32_t)p[1] << 8)
         | ((uint32_t)p[2] << 16)
         | ((uint32_t)p[3] << 24);
}

/* -------------------------------------------------------
 * デバッグ表示
 * ------------------------------------------------------- */
static void dump_buf32(const char *tag, const uint8_t *buf)
{
#if SD_DEBUG_RW32
    for (int w = 0; w < SD_DEBUG_WORDS_PER_SEC; w++) {
        int byte_off = w * 4;
        uint32_t val = load_le32_from_u8(&buf[byte_off]);

        bl_print(tag);
        bl_print("[");
        bl_print_hex((uint32_t)byte_off);
        bl_print("] = ");
        bl_print_hex(val);
        bl_print("\n");
    }
#else
    (void)tag;
    (void)buf;
#endif
}

static void dump_dst32(const char *tag, volatile uint8_t *dst)
{
#if SD_DEBUG_RW32
    for (int w = 0; w < SD_DEBUG_WORDS_PER_SEC; w++) {
        int byte_off = w * 4;
        uint32_t val = ((uint32_t)dst[byte_off + 0] << 0)
                     | ((uint32_t)dst[byte_off + 1] << 8)
                     | ((uint32_t)dst[byte_off + 2] << 16)
                     | ((uint32_t)dst[byte_off + 3] << 24);

        bl_print(tag);
        bl_print("[");
        bl_print_hex((uint32_t)byte_off);
        bl_print("] = ");
        bl_print_hex(val);
        bl_print("\n");
    }
#else
    (void)tag;
    (void)dst;
#endif
}

/* -------------------------------------------------------
 * SD CRC16 (poly=0x1021, init=0x0000)
 * ------------------------------------------------------- */
static uint16_t sd_crc16_512(const uint8_t *buf)
{
    uint16_t crc = 0;

    for (int i = 0; i < 512; i++) {
        crc ^= (uint16_t)((uint16_t)buf[i] << 8);

        for (int j = 0; j < 8; j++) {
            if (crc & 0x8000u) {
                crc = (uint16_t)((crc << 1) ^ 0x1021u);
            } else {
                crc = (uint16_t)(crc << 1);
            }
        }
    }

    return crc;
}

/* -------------------------------------------------------
 * CTRLレジスタからHW CRCを取得
 *  CTRL[31:24] = CRC1
 *  CTRL[23:16] = CRC2
 * ------------------------------------------------------- */
static uint16_t sd_get_hw_crc(void)
{
    uint32_t ctrl = PSC_SD_IF_CTRL;
    uint8_t crc1_hw = (uint8_t)((ctrl >> 24) & 0xFFu);
    uint8_t crc2_hw = (uint8_t)((ctrl >> 16) & 0xFFu);

    return (uint16_t)(((uint16_t)crc1_hw << 8) | (uint16_t)crc2_hw);
}

/* -------------------------------------------------------
 * SD 初期化
 * ------------------------------------------------------- */
static int sd_init_if_needed(void)
{
    uint32_t timeout;

    PSC_SD_IF_CTRL = SD_CTRL_FIFO_FLUSH;
    tiny_delay(100);

    if ((PSC_SD_IF_CTRL & SD_ST_READ_READY) == 0u) {
        bl_print("SD INIT start\n");

        PSC_SD_IF_CTRL = SD_CTRL_INIT_TRIG;
        tiny_delay(100);

        timeout = 50000u;
        while (PSC_SD_IF_CTRL & SD_ST_BUSY) {
            if (--timeout == 0u) {
                bl_print("SD INIT TIMEOUT\n");
                return -1;
            }
            cpu_relax();
        }

        tiny_delay(100);
    }

    return 0;
}

/* -------------------------------------------------------
 * 1 sector (512B) を読み込む本体
 *   - CRC一致なら dst へコピーして return 0
 *   - CRC不一致なら同一LBAを再READ
 * ------------------------------------------------------- */
static int sd_read_sector_to_mem(uint32_t lba, volatile uint8_t *dst)
{
    uint32_t timeout;
    uint8_t buf[512];

    for (uint32_t retry = 0; retry < SD_READ_RETRY_MAX; retry++) {

        PSC_SD_IF_CTRL = SD_CTRL_FIFO_FLUSH;
        tiny_delay(50);

        PSC_SD_SECTOR = lba;

        PSC_SD_IF_CTRL = SD_CTRL_READ_TRIG;
        tiny_delay(50);

        timeout = 50000u;
        while ((PSC_SD_IF_CTRL & SD_ST_READ_READY) == 0u) {
            if (--timeout == 0u) {
                bl_print("SD READ TIMEOUT: lba=");
                bl_print_hex(lba);
                bl_print(" retry=");
                bl_print_hex(retry);
                bl_print("\n");
                return -1;
            }
            cpu_relax();
        }

        tiny_delay(20);

        for (int i = 0; i < 512; i++) {
            timeout = 50000u;
            while (PSC_SD_IF_CTRL & SD_ST_FIFO_EMPTY) {
                if (--timeout == 0u) {
                    bl_print("FIFO EMPTY TIMEOUT: lba=");
                    bl_print_hex(lba);
                    bl_print(" index=");
                    bl_print_hex((uint32_t)i);
                    bl_print(" retry=");
                    bl_print_hex(retry);
                    bl_print("\n");
                    return -1;
                }
                cpu_relax();
            }

            buf[i] = (uint8_t)(PSC_SD_ADDR & 0xFFu);
        }

#if SD_DEBUG_RW32
        dump_buf32("RD", buf);
#endif

        {
            uint16_t crc_sw = sd_crc16_512(buf);
            uint16_t crc_hw = sd_get_hw_crc();

            if (crc_sw == crc_hw) {
                for (int i = 0; i < 512; i++) {
                    dst[i] = buf[i];
                }

#if SD_DEBUG_RW32
                dump_dst32("WR", dst);
#endif
                return 0;
            }

            bl_print("CRC NG: lba=");
            bl_print_hex(lba);
            bl_print(" retry=");
            bl_print_hex(retry);
            bl_print(" sw=");
            bl_print_hex((uint32_t)crc_sw);
            bl_print(" hw=");
            bl_print_hex((uint32_t)crc_hw);
            bl_print("\n");
        }

        tiny_delay(100);
    }

    bl_print("CRC FAILED: lba=");
    bl_print_hex(lba);
    bl_print("\n");
    return -1;
}

/* -------------------------------------------------------
 * 複数 sector を連続で SDRAM へロード
 * ------------------------------------------------------- */
static int sd_load_image(uint32_t start_lba, uint32_t sector_count, uint32_t dst_addr)
{
    volatile uint8_t *dst = (volatile uint8_t *)dst_addr;

    bl_print("LOAD: LBA=");
    bl_print_hex(start_lba);
    bl_print(" count=");
    bl_print_hex(sector_count);
    bl_print(" -> addr=");
    bl_print_hex(dst_addr);
    bl_print("\n");

    for (uint32_t i = 0; i < sector_count; i++) {
        if (sd_read_sector_to_mem(start_lba + i, dst + (i * 512u)) != 0) {
            bl_print("LOAD FAILED: lba=");
            bl_print_hex(start_lba + i);
            bl_print("\n");
            return -1;
        }

        if ((i & 0x7u) == 0u) {
            bl_print("  loaded sector ");
            bl_print_hex(i);
            bl_print(" / ");
            bl_print_hex(sector_count);
            bl_print("\n");
        }
    }

    return 0;
}

/* -------------------------------------------------------
 * 指定アドレスへジャンプ
 * ------------------------------------------------------- */
static void jump_to_addr(uint32_t addr)
{
    void (*entry)(void) = (void (*)(void))addr;

    sync_icache();

    bl_print("JUMP TO ");
    bl_print_hex(addr);
    bl_print("\n");

    entry();

    for (;;) {
    }
}

/* -------------------------------------------------------
 * SDRAM メモリアクセステスト
 * ------------------------------------------------------- */

#define MEM_STEP 4u   // 32bit access

/* 32bit LFSR (Galois) */
static inline uint32_t lfsr_next(uint32_t x) {
    uint32_t lsb = x & 1u;
    x >>= 1;
    if (lsb) {
        x ^= 0xA3000000u;
    }
    return x;
}

static inline uint32_t test_pattern(uint32_t addr) {
    return addr ^ 0xA5A5A5A5u;
}

void random_mem_check(
    uint32_t start_addr,
    uint32_t end_addr,
    uint32_t access_count)
{
    bool TestPass = true;
    uint32_t lfsr;
    uint32_t addr;

    uint32_t range_bytes = end_addr - start_addr;
    uint32_t mask = range_bytes - MEM_STEP;

    s_printf("[mem_check] range %x - %x\n",
             start_addr, end_addr);

    s_printf("[mem_check] access count=%x\n",
             access_count);

    /* ================= write ================= */

    lfsr = 0x12345678u;

    for (uint32_t i = 0; i < access_count; i++)
    {
        addr = start_addr + (lfsr & mask);

        *(volatile uint32_t *)addr =
            test_pattern(addr);

        lfsr = lfsr_next(lfsr);
    }

    /* ================= read ================= */

    lfsr = 0x12345678u;

    for (uint32_t i = 0; i < access_count; i++)
    {
        addr = start_addr + (lfsr & mask);

        uint32_t v =
            *(volatile uint32_t *)addr;

        uint32_t exp =
            test_pattern(addr);

        if (v != exp)
        {
            TestPass = false;

            s_printf(
                "MEM ERROR addr=%x read=%x exp=%x\n",
                addr, v, exp);

            mmio_w32(
                UART_MMIO_BASE + UART_TX,
                0xEE01);
        }

        lfsr = lfsr_next(lfsr);
    }

    if (TestPass)
        s_printf("[mem_check] OK\n");
    else
        s_printf("[mem_check] NG\n");
}

/* -------------------------------------------------------
 * bootloader main
 * BIOS からここへ来る想定
 * ------------------------------------------------------- */
void bootloader_main(void)
{
    bl_print("boot start\n");

    // random R/W
    bl_print("\n=== PSC random memory RW test start ===\n");
    random_mem_check(0x00600000, 0x00800000, (uint32_t)500);

    bl_print("\n=== PSC bootloader start ===\n");
    bl_print_kv_hex("CTRL=", PSC_SD_IF_CTRL);

    if (sd_init_if_needed() != 0) {
        bl_print("bootloader: SD init failed\n");
        for (;;) {
        }
    }

    if (sd_load_image(KERNEL_LBA_START, KERNEL_LBA_COUNT, KERNEL_LOAD_ADDR) != 0) {
        bl_print("bootloader: kernel load failed\n");
        for (;;) {
        }
    }

    if (sd_load_image(USER_LBA_START, USER_LBA_COUNT, USER_LOAD_ADDR) != 0) {
        bl_print("bootloader: user load failed\n");
        for (;;) {
        }
    }

    bl_print("bootloader: load done\n");

    bl_print("kernel[0]=");
    bl_print_hex(*(volatile uint32_t *)KERNEL_LOAD_ADDR);
    bl_print("\n");

    bl_print("user[0]  =");
    bl_print_hex(*(volatile uint32_t *)USER_LOAD_ADDR);
    bl_print("\n");

    sync_icache();

    jump_to_addr(KERNEL_LOAD_ADDR);
}