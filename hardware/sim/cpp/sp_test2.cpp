#include <cstdint>

/* ---------- アサーション用PIO出力 --------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言 ---------- */
extern "C" volatile uint32_t result;
extern "C" void kernel_entry(void);   // ★ここに出す

/* ---------- run ---------- */
extern "C" void run()
{
    // ★ mtvec を kernel_entry に設定（direct mode）
    asm volatile(
        "la   t0, kernel_entry\n"
        "csrw mtvec, t0\n"
        :
        :
        : "t0", "memory"
    );

    uint32_t sp_before;
    uint32_t sp_after;
    uint32_t frame_addr;

    /* レジスタ既知値 */
    asm volatile(
        "li ra,0x11111111\n"
        "li gp,0x22222222\n"
        "li tp,0x33333333\n"
        "li t0,0x44444444\n"
        "li t1,0x55555555\n"
        "li t2,0x66666666\n"
        "li t3,0x77777777\n"
        "li t4,0x88888888\n"
        "li t5,0x99999999\n"
        "li t6,0xAAAAAAAA\n"
        "li a0,0xBBBBBBBB\n"
        "li a1,0xCCCCCCCC\n"
        "li a2,0xDDDDDDDD\n"
        "li a3,0xEEEEEEEE\n"
        "li a4,0x12345678\n"
        "li a5,0x87654321\n"
        "li a6,0xCAFEBABE\n"
        "li a7,0x0BADBEEF\n"
        "li s0,0x11112222\n"
        "li s1,0x33334444\n"
        "li s2,0x55556666\n"
        "li s3,0x77778888\n"
        "li s4,0x9999AAAA\n"
        "li s5,0xBBBBCCCC\n"
        "li s6,0xDDDDEEEE\n"
        "li s7,0x11113333\n"
        "li s8,0x22224444\n"
        "li s9,0x33335555\n"
        "li s10,0x44446666\n"
        "li s11,0x55557777\n"
        :
        :
        : "memory"
    );

    /* SP保存 */
    asm volatile("mv %0, sp" : "=r"(sp_before) :: "memory");

    /* kernel_entry が作るフレーム位置（あなたの想定） */
    frame_addr = sp_before - 124;

    /* 順序固定（念のため） */
    asm volatile("" ::: "memory");

    /* トラップ */
    asm volatile("ecall" ::: "memory");

    /* SP復帰確認 */
    asm volatile("mv %0, sp" : "=r"(sp_after) :: "memory");

    uint32_t ok = 1;

    if (sp_before != sp_after)
        ok = 0;

    /* スタックフレーム検証 */
    volatile uint32_t* frame = (volatile uint32_t*)frame_addr;

    if (frame[0] != 0x11111111) ok = 0;   // ra
    if (frame[1] != 0x22222222) ok = 0;   // gp
    if (frame[2] != 0x33333333) ok = 0;   // tp
    if (frame[3] != 0x44444444) ok = 0;   // t0
    if (frame[4] != 0x55555555) ok = 0;   // t1
    if (frame[5] != 0x66666666) ok = 0;   // t2
    if (frame[6] != 0x77777777) ok = 0;   // t3
    if (frame[7] != 0x88888888) ok = 0;   // t4
    if (frame[8] != 0x99999999) ok = 0;   // t5
    if (frame[9] != 0xAAAAAAAA) ok = 0;   // t6

    if (frame[10] != 0xBBBBBBBB) ok = 0;  // a0
    if (frame[11] != 0xCCCCCCCC) ok = 0;
    if (frame[12] != 0xDDDDDDDD) ok = 0;
    if (frame[13] != 0xEEEEEEEE) ok = 0;

    if (frame[18] != 0x11112222) ok = 0;  // s0
    if (frame[23] != 0xBBBBCCCC) ok = 0;  // s5
    if (frame[29] != 0x55557777) ok = 0;  // s11

    result = ok ? 0x12345678u : 0xBAD0BAD0u;

    /* テスト終了 */
    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) {}
}

/* ---------- 定義 ---------- */
extern "C" {
    volatile uint32_t result = 0;
}