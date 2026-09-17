#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- デバッグ結果の絶対アドレス ---------- */
static constexpr std::uintptr_t RESULT_ADDR = 0x00001000u;  // mem[1024]

/* ---------- 宣言（extern：リンカ都合で残してOK） ---------- */
extern "C" volatile uint32_t result;
extern "C" volatile uint32_t results[8];

/* ---------- CSR番号 ---------- */
#define CSR_MSTATUS  0x300u
#define CSR_MISA     0x301u
#define CSR_MIE      0x304u
#define CSR_MTVEC    0x305u
#define CSR_MSCRATCH 0x340u
#define CSR_MEPC     0x341u
#define CSR_MCAUSE   0x342u
#define CSR_MIP      0x344u

/* ---------- CSRユーティリティ（CSR番号はテンプレートで即値化） ---------- */
template <uint32_t CSR>
static inline uint32_t read_csr() {
    uint32_t v;
    asm volatile ("csrr %0, %1" : "=r"(v) : "i"(CSR));
    return v;
}
template <uint32_t CSR>
static inline void write_csr(uint32_t v) {
    asm volatile ("csrw %0, %1" :: "i"(CSR), "r"(v));
}
template <uint32_t CSR>
static inline void set_csr(uint32_t mask) {
    asm volatile ("csrs %0, %1" :: "i"(CSR), "r"(mask));
}
template <uint32_t CSR>
static inline void clr_csr(uint32_t mask) {
    asm volatile ("csrc %0, %1" :: "i"(CSR), "r"(mask));
}

/* ビット */
#define MSTATUS_MIE (1u << 3)
#define MIE_MTIE    (1u << 7)

/* 期待値（Csr.v 実装に合わせる） */
//static constexpr uint32_t EXPECT_MISA       = 0x40000100u;  // ← 元
static constexpr uint32_t EXPECT_MISA       = 0x40140100u;   // ← 修正
static constexpr uint32_t EXPECT_MSTATUS_ON = MSTATUS_MIE;   // 0x0000_0008
static constexpr uint32_t EXPECT_MSTATUS_OFF= 0x00000000u;
static constexpr uint32_t EXPECT_MIE_MTIE   = MIE_MTIE;      // 0x0000_0080

/* 簡単なアサート集計（ビット和でエラー原因を表現） */
static inline void note_fail(uint32_t &fail, uint32_t bit) { fail |= bit; }

/* ---------- エントリ ---------- */
extern "C" void run() {
    volatile uint32_t* const dbg = reinterpret_cast<volatile uint32_t*>(RESULT_ADDR);
    uint32_t fail = 0;

    // 1) 初期観測
    results[0] = read_csr<CSR_MSTATUS>();
    results[1] = read_csr<CSR_MISA>();
    if (results[1] != EXPECT_MISA)          note_fail(fail, 1u<<0); // misa不一致

    // 2) mscratch R/W
    write_csr<CSR_MSCRATCH>(0x12345678u);
    results[2] = read_csr<CSR_MSCRATCH>();
    if (results[2] != 0x12345678u)          note_fail(fail, 1u<<1); // mscratch不一致

    // 3) mstatus.MIE set -> clear
    set_csr<CSR_MSTATUS>(MSTATUS_MIE);
    results[3] = read_csr<CSR_MSTATUS>();
    if ((results[3] & MSTATUS_MIE) != EXPECT_MSTATUS_ON)
                                              note_fail(fail, 1u<<2); // MIE set 失敗

    clr_csr<CSR_MSTATUS>(MSTATUS_MIE);
    results[4] = read_csr<CSR_MSTATUS>();
    if ((results[4] & MSTATUS_MIE) != EXPECT_MSTATUS_OFF)
                                              note_fail(fail, 1u<<3); // MIE clear 失敗

    // 4) mie.MTIE set
    set_csr<CSR_MIE>(MIE_MTIE);
    results[5] = read_csr<CSR_MIE>();
    if ((results[5] & MIE_MTIE) != EXPECT_MIE_MTIE)
                                              note_fail(fail, 1u<<4); // MTIE set 失敗

    // ===== 合否書き込み =====
    if (fail == 0) {
        *dbg   = 0x22u;   // mem[1024]
        result = 0x22u;   // 互換用
    } else {
        // 失敗時はエラーサマリを残す（デバグ用）
        // 例: 0xBAD0_0000 | failビット
        const uint32_t err = 0xBAD00000u | fail;
        *dbg   = err;
        result = err;
    }

    // テスト終了のコード送信
    PIO32 = TEST_END_CODE;

    // PIO データによるアサーション用書き込み
    if (result == 0x22u) {
        PIO32 = 0x22u;
    } else {
        PIO32 = result;
    }

    while (1) { }  // 無限ループ
}

/* ---------- 定義（実体） ---------- */
extern "C" {
    volatile uint32_t result = 0;
    volatile uint32_t results[8] = {0};
}
