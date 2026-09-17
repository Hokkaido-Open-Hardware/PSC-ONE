// sp_test1.cpp
#include <cstdint>

/* ---------- アサーション用PIO出力（Byteアドレス） ---------- */
#define PIO_BASE \
    (reinterpret_cast<volatile uint32_t*>(0x10001000u))

#define PIO32        (PIO_BASE[0])
#define PIO_SP       (PIO_BASE[1])
#define PIO_STACK_TOP (PIO_BASE[2])
#define PIO_FLAGS    (PIO_BASE[3])
#define PIO_RESULT   (PIO_BASE[4])

static constexpr uint32_t TEST_END_CODE = 0xEE01u;

/* ---------- リンカシンボル（リンクスクリプト側で定義） ---------- */
extern "C" char _stack_top;

/* ---------- 可視化用グローバル ---------- */
extern "C" volatile uint32_t result;

/* ---------- SP読み取りユーティリティ ---------- */
static inline uintptr_t read_sp()
{
    uintptr_t sp_now;

    asm volatile (
        "mv %0, sp"
        : "=r"(sp_now)
    );

    return sp_now;
}

/* ネスト呼び出しでSPが下方向に動くか観察 */
__attribute__((noinline))
static bool sp_grows_down(uintptr_t caller_sp)
{
    volatile uint32_t local_array[8] = {
        0x12345678u,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    };

    /*
     * local_arrayが最適化で削除されないようにする。
     */
    asm volatile (
        ""
        :
        : "r"(local_array)
        : "memory"
    );

    const uintptr_t callee_sp = read_sp();

    /*
     * デバッグ用：
     * callee側のSPもPIOへ記録する。
     */
    PIO_BASE[5] = static_cast<uint32_t>(callee_sp);
    PIO_BASE[6] = static_cast<uint32_t>(caller_sp);

    return callee_sp < caller_sp;
}

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run()
{
    /*
     * run()の関数プロローグ実行後のSP。
     */
    uintptr_t sp0 = read_sp();

    /*
     * リンカスクリプトで定義された_stack_topのアドレス。
     */
    uintptr_t stack_top =
        reinterpret_cast<uintptr_t>(&_stack_top);

    /*
     * 判定1：
     * RISC-V ABIで要求される16-byteアライン。
     */
    bool ok_align =
        ((sp0 & 0xFu) == 0u);

    /*
     * 判定2：
     * 現在のSPが_stack_top以下にあること。
     */
    bool ok_below_top =
        (sp0 <= stack_top);

    /*
     * 判定3：
     * 関数呼び出しによりSPが減少すること。
     */
    bool ok_grow_down =
        sp_grows_down(sp0);

    uint32_t flags =
        (ok_align     ? 1u : 0u) |
        (ok_below_top ? 2u : 0u) |
        (ok_grow_down ? 4u : 0u);

    uint32_t delta16 = 0;

    if (stack_top >= sp0) {
        uintptr_t delta = stack_top - sp0;

        delta16 =
            static_cast<uint32_t>(delta & 0xFFFFu);
    }

    result =
        (delta16 << 16) |
        (flags & 0xFFFFu);

    /*
     * デバッグ情報をPIOへ保存する。
     *
     * word0 : 終了／合否コード
     * word1 : run()内のsp0
     * word2 : リンカシンボル_stack_top
     * word3 : 判定flags
     * word4 : result
     * word5 : sp_grows_down()内のcallee_sp
     * word6 : sp_grows_down()へ渡したcaller_sp
     */
    PIO32 =
        static_cast<uint32_t>(sp0);

    PIO32 =
        static_cast<uint32_t>(stack_top);

    PIO32 =
        flags;

    PIO32 =
        result;

    /*
     * コンパイラによるPIO書き込みの並べ替えを防止する。
     */
    asm volatile ("" ::: "memory");

    /*
     * Cocotbへテスト終了を通知する。
     */
    PIO32 = TEST_END_CODE;

    /*
     * 最終的なテスト結果をword0へ出力する。
     */
    if (flags == 7u) {
        PIO32 = 0x5AA5u;
    } else {
        PIO32 = 0xEE00u | flags;
    }

    while (1) {
        asm volatile ("" ::: "memory");
    }
}

/* ---------- resultの実体 ---------- */
extern "C" {
    volatile uint32_t result = 0;
}