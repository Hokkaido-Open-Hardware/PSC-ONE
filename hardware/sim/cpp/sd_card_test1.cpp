// sd_if_test1_timeout.cpp
#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;
static constexpr uint32_t ERR_INIT_TIMEOUT = 0xDEAD0001;
static constexpr uint32_t ERR_READ_TIMEOUT = 0xDEAD0002;

/* ---------- PSC SD IF ---------- */
#define PSC_SD_ADDR     (*reinterpret_cast<volatile uint32_t*>(0x10006000u))
#define PSC_SD_SECTOR   (*reinterpret_cast<volatile uint32_t*>(0x10006004u))
#define PSC_SD_IF_CTRL  (*reinterpret_cast<volatile uint32_t*>(0x10006008u))

static inline void tiny_delay(unsigned n){
    while (n--) {
        asm volatile("nop");
    }
}

extern "C" void run() {

    // read data
    uint32_t read_byte;

    // --------------------------------------
    // 1回目のREAD
    // --------------------------------------

    // wait
    tiny_delay(200);

    // fifo flush
    PSC_SD_IF_CTRL = 0x04;

    // ======================= INITIALIZE ======================
    // SDカードイニシャライズで開始
    // start_pulse = H
    PSC_SD_IF_CTRL = 0x01;

    // busy=1 wait.
    // busy=0 でPASS
    uint32_t timeout = 2000;  // 適宜調整
    while ((PSC_SD_IF_CTRL & 0x02) != 0x00) {
        if (--timeout == 0) {
            PIO32 = 0xEE03;
            break;
        }
        __asm__ __volatile__("nop");
    }

    PIO32 = 0x3322;

    // ======================= READ ======================
    // sd_rw_ready=1ではない場合
    if ((PSC_SD_IF_CTRL & 0x04) == 0x00) {    
        // SDカードイニシャライズで開始
        PIO32 = 0x33E2;
        PSC_SD_IF_CTRL = 0x01;
    }

    // セクタ指定（READ）
    PSC_SD_SECTOR = 0x04030201;

    // READトリガ（READ）
    PSC_SD_IF_CTRL = 0x02;

    tiny_delay(100);    // 今の所必須

    // sd_rw_ready=0 wait.
    // sd_rw_ready=1 でPASS
    timeout = 50000; 
    while ((PSC_SD_IF_CTRL & 0x04) == 0x00) {
        if (--timeout == 0) {
            PIO32 = 0xEE04;
            break;
        }
        __asm__ __volatile__("nop");
    }
    // CRC1,2
    uint32_t crc_data = PSC_SD_IF_CTRL;
    PIO32 = crc_data;   // exp: 0xC1, 0xC2

    // READ
    read_byte = PSC_SD_ADDR;
    read_byte = PSC_SD_ADDR;
    read_byte = PSC_SD_ADDR;
    read_byte = PSC_SD_ADDR;

    // --------------------------------------
    // 2回目のREAD
    // --------------------------------------
#if 0

    PIO32 = 0x3114;

    // sd_rw_ready=1ではない場合
    if ((PSC_SD_IF_CTRL & 0x04) == 0x00) {    
        // SDカードイニシャライズで開始
        PIO32 = 0x33E4;
        PSC_SD_IF_CTRL = 0x01;
    } else {
        PIO32 = 0x33EE;
    }

    // sd_rw_ready=1 wait.
    // sd_rw_ready=1 でPASS
    // 2回目ならready=1のはず
    timeout = 2000;  // 適宜調整
    while ((PSC_SD_IF_CTRL & 0x04) != 0x04) {
        if (--timeout == 0) {
            PIO32 = 0xEE03;
            break;
        }
        __asm__ __volatile__("nop");
    }

    PIO32 = 0x3414;

    // fifo flush
    PSC_SD_IF_CTRL = 0x04;

    // セクタ指定（READ）
    PSC_SD_SECTOR = 0x0d0c0b0a;

    // READトリガ（READ）
    PSC_SD_IF_CTRL = 0x02;

    // wait
    tiny_delay(100);    // 今の所必須

    // sd_rw_ready=0 wait.
    // sd_rw_ready=1 でPASS
    timeout = 50000; 
    while ((PSC_SD_IF_CTRL & 0x04) == 0x00) {
        if (--timeout == 0) {
            PIO32 = 0xEE04;
            break;
        }
        __asm__ __volatile__("nop");
    }

    // READ
    read_byte = PSC_SD_ADDR;
    read_byte = PSC_SD_ADDR;
    read_byte = PSC_SD_ADDR;
    read_byte = PSC_SD_ADDR;

#endif

    // ================= RESULT =================
    PIO32 = TEST_END_CODE;
    PIO32 = read_byte;

    while (1) {}
}
