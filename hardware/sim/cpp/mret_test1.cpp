#include <cstdint>
#include <cstddef>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- mret 後の戻り先 ---------- */
extern "C" void mret_target();

/* ---------- エントリ（M-mode で呼ばれる） ---------- */
extern "C" void run() {

    /* mret_target の実アドレスを C で取得 */
    uintptr_t target_addr = reinterpret_cast<uintptr_t>(&mret_target);

    /* デバッグ：アドレス下位を可視化 */
    PIO32 = 0xA000 | (target_addr & 0x0FFF);

    /* mepc に直接書き込む（la 不使用） */
    asm volatile (
        "csrw mepc, %0\n"
        :
        : "r"(target_addr)
        : "memory"
    );

    /*
    * mstatus.MPP = 01 (S-mode)
    * bits[12:11]
    */
    asm volatile (
        /* MPP をクリア (bits[12:11] = 00) */
        "li   t0,  (3 << 11)\n"      // 0x1800
        "csrrc x0, mstatus, t0\n"   // mstatus &= ~0x1800

        /* MPP = 01 (S-mode) */
        "li   t0,  (1 << 11)\n"      // 0x0800
        "csrs  mstatus, t0\n"       // mstatus |= 0x0800
        :
        :
        : "t0", "memory"
    );

    /* mret 実行前マーカー */
    PIO32 = 0x1001;

    /* I/O 可視化保証 */
    asm volatile ("fence iorw, iorw" ::: "memory");

    /* 特権遷移：M → S */
    asm volatile ("mret" ::: "memory");

    /* ここに来たら失敗 */
    PIO32 = 0xBEEF;
    while (1) {}
}

/* ---------- mret 後（S-mode で実行される） ---------- */
extern "C" void mret_target() {

    uint32_t mstatus;
    uint32_t result;

    /* mstatus を読む */
    asm volatile (
        "csrr %0, mstatus\n"
        : "=r"(mstatus)
        :
        : "memory"
    );

    /*
     * デバッグ出力：
     * 下位 12bit を PIO に出す
     * 期待値：0x000
     */
    PIO32 = 0xB000 | (mstatus & 0x0FFF);
    if (mstatus != 0x080) {
        result = 0x1234; 
    } else {
        result = 0xDCBA;
    }

    /* 到達確認 */
    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) {}
}
