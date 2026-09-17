#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

extern "C" volatile uint32_t result;

/* ====== 設定（環境に合わせて変更可） ====== */
static constexpr uintptr_t RAM_BASE = 0x00008000;  // テスト用ワークRAM開始
static constexpr uint32_t NTEST    = 10u;

/* テストで使うオフセット（同一ライン／別ラインを混ぜる想定） */
// 0x0000を混ぜるとBoot_rom書き込み省略モードでFAILするので注意.
static constexpr uint32_t OFFS[NTEST] = {
    0x014, 0x004, 0x008, 0x00C,      // 近接（同一/隣接ワード）
    0x100, 0x104, 0x108, 0x10C,      // ある程度離す（別ライン想定）
    0x200, 0x204                      // さらに離す
};

static inline volatile uint32_t* addr_ptr(uint32_t off) {
    return reinterpret_cast<volatile uint32_t*>(static_cast<uintptr_t>(RAM_BASE + off));
}

/* ダミーアクセスでキャッシュを汚染（簡易） */
static void pollute_cache() {
    volatile uint32_t sum = 0;
    for (uint32_t k = 0; k < 16u; ++k) {
        sum += *addr_ptr(0x300u + (k << 2));  // 適当な別領域を読む
    }
    (void)sum; // 最適化抑止
}

extern "C" void run() {
    // 書き込みパターン
    uint32_t wpat[NTEST];
    for (uint32_t i = 0; i < NTEST; ++i) wpat[i] = 0xAAA00000u + i;  // ここが安全に

    // 結果フラグ。ビットiが1ならテストiでミスマッチ
    uint32_t errors = 0;

    // テスト領域を初期化
    for(uint32_t a = 0x300; a < 0x400; a += 4) {
        *(volatile uint32_t*)a = 0;
    }

    // --- 10回のRWテスト ---
    for (uint32_t i = 0; i < NTEST; ++i) {
        volatile uint32_t* p = addr_ptr(OFFS[i]);

        // Write
        *p = wpat[i];

        // 1) 即時Readで検証（Write-Through/Write-Backいずれでもヒット期待）
        uint32_t r1 = *p;
        if (r1 != wpat[i]) {
            errors |= (1u << i);
        }

        // 2) キャッシュ汚染後に再Read（置換/書き戻し動作の確認）
        pollute_cache();
        uint32_t r2 = *p;
        if (r2 != wpat[i]) {
            errors |= (1u << i);
        }
    }

    // まとめ（0=PASS、非0=どのケースが失敗したかのビットマスク）
    result = (errors == 0u) ? 0x600DCAFEu : (0xBAD00000u | errors);

    // テスト終了のコード送信
    PIO32 = TEST_END_CODE;

    // PIO データによるアサーション用書き込み
    if (result == 0x600DCAFE) {
        PIO32 = 0x600DCAFE;
    } else {
        PIO32 = result;
    }

    // 以降停止
    while (1) { }
}

extern "C" {
    volatile uint32_t result = 0;
}
