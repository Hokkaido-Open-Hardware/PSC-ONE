#include <cstdint>

/* ---------- MMIO / PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言 ---------- */
extern "C" volatile uint32_t result;

/* ---------- 便利関数 ---------- */
static inline void mmio_write(uint32_t v) {
    PIO32 = v;
    // MMIO順序を安定化（実装が弱い/バグってるとここで露呈する）
    asm volatile ("fence iorw, iorw" ::: "memory");
}

static inline void report(uint32_t id, uint32_t val) {
    mmio_write(id);
    mmio_write(val);
}

/* ---------- エントリ ---------- */
extern "C" void run() {
    uint32_t a = 10;
    uint32_t c = 0;
    uint32_t d = 0;

    /* =====================================================
       TEST1: ADDI RAW chain (短)
       c = a+20*4 = 10+80 = 90
       ===================================================== */
    asm volatile ("addi %0, %1, 20" : "=r"(c) : "r"(a));
    asm volatile ("addi %0, %1, 20" : "=r"(c) : "r"(c));
    asm volatile ("addi %0, %1, 20" : "=r"(c) : "r"(c));
    asm volatile ("addi %0, %1, 20" : "=r"(c) : "r"(c));
    result = c;
    report(1, result);

    /* =====================================================
       TEST2: WAW hazard (同一dstに連続書き込み)
       期待: d = a+3 = 13
       ===================================================== */
    asm volatile ("addi %0, %1, 1" : "=r"(d) : "r"(a));
    asm volatile ("addi %0, %1, 2" : "=r"(d) : "r"(a));
    asm volatile ("addi %0, %1, 3" : "=r"(d) : "r"(a));
    result ^= d;
    report(2, d);

    /* =====================================================
       TEST3: NO hazard (独立)
       e=15, f=17 -> e+f=32
       ===================================================== */
    uint32_t e=0,f=0;
    asm volatile ("addi %0, %1, 5" : "=r"(e) : "r"(a));
    asm volatile ("addi %0, %1, 7" : "=r"(f) : "r"(a));
    result ^= (e + f);
    report(3, (e + f));

    /* =====================================================
       TEST4: x0 write ignore
       期待: z=0
       ===================================================== */
    uint32_t z=0;
    asm volatile ("addi x0, x0, 123");
    asm volatile ("addi %0, x0, 0" : "=r"(z));
    result ^= z;
    report(4, z);

    /* =====================================================
       TEST5: Long RAW chain (長)
       s=1 -> 50回 +1 => 51
       ===================================================== */
    uint32_t s = 1;
    for (int i=0;i<50;i++) {
        asm volatile ("addi %0, %1, 1" : "=r"(s) : "r"(s));
    }
    result ^= s;
    report(5, s);

    /* =====================================================
       TEST6: RAW with interleaving (依存と独立の混在)
       依存: r = (((a+1)+2)+3)+4 = a+10=20
       独立: u = a+100
       ===================================================== */
    uint32_t r=0,u=0;
    asm volatile ("addi %0, %1, 1"   : "=r"(r) : "r"(a));
    asm volatile ("addi %0, %1, 100" : "=r"(u) : "r"(a)); // 独立
    asm volatile ("addi %0, %1, 2"   : "=r"(r) : "r"(r));
    asm volatile ("addi %0, %1, 3"   : "=r"(r) : "r"(r));
    asm volatile ("addi %0, %1, 4"   : "=r"(r) : "r"(r));
    result ^= (r ^ u);
    report(6, (r ^ u));

    /* =====================================================
       TEST7: ALU mix (ADD/SUB/AND/OR/XOR/SLL/SRL/SRA)
       -> デコード/シフタ/符号シフトの確認
       ===================================================== */
    uint32_t x=0,y=0,t=0;
    asm volatile ("addi %0, x0, 0x55" : "=r"(x));      // 0x55
    asm volatile ("addi %0, x0, 0x0F" : "=r"(y));      // 0x0F
    asm volatile ("add  %0, %1, %2"   : "=r"(t) : "r"(x), "r"(y)); // 0x64
    asm volatile ("xor  %0, %0, %1"   : "+r"(t) : "r"(x));         // 0x31
    asm volatile ("or   %0, %0, %1"   : "+r"(t) : "r"(y));         // 0x3F
    asm volatile ("and  %0, %0, %1"   : "+r"(t) : "r"(x));         // 0x15
    asm volatile ("sll  %0, %0, %1"   : "+r"(t) : "r"(y));         // 0x15 << 0x0F(=15) -> 0x000A8000
    asm volatile ("srl  %0, %0, %1"   : "+r"(t) : "r"(y));         // 戻るはず
    // 算術右シフト確認用に負数を作る
    uint32_t neg=0;
    asm volatile ("addi %0, x0, -4" : "=r"(neg));                 // 0xFFFF_FFFC
    asm volatile ("sra  %0, %0, %1" : "+r"(neg) : "r"(y));        // >>15 算術
    result ^= (t ^ neg);
    report(7, (t ^ neg));

    /* =====================================================
       TEST8: Branch (taken/not-taken) + flush
       - 連続分岐でPC/フラッシュ/即値生成の確認
       ===================================================== */
    uint32_t br=0;
    asm volatile (
        "addi  %[br], x0, 0        \n"
        "addi  t0,   x0, 1         \n"
        "addi  t1,   x0, 1         \n"
        "beq   t0,   t1, 1f        \n" // taken
        "addi  %[br], %[br], 100   \n" // 実行されない
        "1:                        \n"
        "addi  %[br], %[br], 7     \n"
        "bne   t0,   t1, 2f        \n" // not taken
        "addi  %[br], %[br], 9     \n" // 実行される
        "2:                        \n"
        : [br] "+r"(br)
        :
        : "t0","t1","memory"
    );
    result ^= br;
    report(8, br); // 期待: 7+9=16

    /* =====================================================
       TEST9: JAL/JALR (リンク・戻り) + 依存
       - PC+4, rd書き込み, jalrターゲット計算
       ===================================================== */
    uint32_t j=0;
    asm volatile (
        "addi  %[j], x0, 1         \n"
        "jal   ra, 1f              \n" // ra=return addr
        "addi  %[j], %[j], 100     \n" // 実行されない
        "1:                        \n"
        "addi  %[j], %[j], 3       \n"
        // jalrで「raへ戻る」を擬似（ここでは次へ飛ぶだけ）
        "auipc t0, 0               \n"
        "addi  t0, t0, 12          \n" // 直後のラベルへ(調整値は実装で変わり得るので最小限)
        "jalr  x0, t0, 0           \n"
        "addi  %[j], %[j], 200     \n" // 実行されない想定
        "addi  %[j], %[j], 5       \n"
        : [j] "+r"(j)
        :
        : "t0","ra","memory"
    );
    result ^= j;
    report(9, j); // 期待: 1+3+5=9 （jalr調整がズレる実装だとここで露呈）

    /* =====================================================
       TEST10: Memory hazards (store/load, load-use)
       - SB/SH/SW, LB/LBU/LH/LHU/LW
       - 同一アドレス依存（store→load）
       ===================================================== */
    alignas(4) static volatile uint8_t mem[64];
    // 初期化（ストアが効いているかも確認）
    for (int i=0;i<64;i++) mem[i] = 0;

    uint32_t m=0;
    // store word -> load word (RAW via memory)
    asm volatile ("sw %1, 0(%0)" :: "r"(mem), "r"(0x11223344u) : "memory");
    asm volatile ("lw %0, 0(%1)" : "=r"(m) : "r"(mem) : "memory");
    // load-use: 直後に依存演算
    asm volatile ("addi %0, %0, 1" : "+r"(m));
    result ^= m;
    report(10, m); // 期待: 0x11223345

    /* byte/half test + sign/zero extend */
    uint32_t lb=0,lbu=0,lh=0,lhu=0;
    asm volatile ("sb %1, 1(%0)" :: "r"(mem), "r"(0x80u) : "memory");   // mem[1]=0x80 (負に見える)
    asm volatile ("sh %1, 2(%0)" :: "r"(mem), "r"(0xFF7Fu) : "memory"); // mem[2..3]=0xFF7F
    asm volatile ("lb  %0, 1(%1)" : "=r"(lb)  : "r"(mem) : "memory");  // sign
    asm volatile ("lbu %0, 1(%1)" : "=r"(lbu) : "r"(mem) : "memory");  // zero
    asm volatile ("lh  %0, 2(%1)" : "=r"(lh)  : "r"(mem) : "memory");  // sign
    asm volatile ("lhu %0, 2(%1)" : "=r"(lhu) : "r"(mem) : "memory");  // zero
    result ^= (lb ^ lbu ^ lh ^ lhu);
    report(11, (lb ^ lbu ^ lh ^ lhu));

    /* =====================================================
       TEST11: Unaligned access behavior (任意)
       - 仕様/実装で例外 or 切り捨て等があり得るので、
         “あえて”踏むなら分離して観測する
       - もし未対応ならこのテストはコメントアウト推奨
       ===================================================== */
#if 0
    uint32_t ua=0;
    asm volatile ("lw %0, 1(%1)" : "=r"(ua) : "r"(mem) : "memory");
    result ^= ua;
    report(12, ua);
#endif

    /* =====================================================
       TEST12: Stress loop (分岐 + load/use + store)
       - primes1000で落ちる系の「長時間で崩れる」バグを炙る
       ===================================================== */
    uint32_t acc=0;
    for (int i=0;i<200;i++) {
        // store
        asm volatile ("sw %1, 4(%0)" :: "r"(mem), "r"(i) : "memory");
        // load-use
        uint32_t tmp=0;
        asm volatile ("lw %0, 4(%1)" : "=r"(tmp) : "r"(mem) : "memory");
        asm volatile ("addi %0, %0, 3" : "+r"(tmp));
        acc ^= tmp;

        // branch mix
        if ((i & 7) == 0) acc += 1;
        else              acc += 2;
    }
    result ^= acc;
    report(13, acc);

    /* =====================================================
       TEST14: load-use hazard (lw直後にuse)
       - 典型: lw rX, offset(rB) の直後に rX をALUで使用
       - フォワード/ストール不備だとここで壊れやすい
       ===================================================== */
    uint32_t lu = 0;

    // テスト用に mem[8..11] に 0x12345678 を格納（aligned）
    asm volatile ("sw %1, 8(%0)" :: "r"(mem), "r"(0x12345678u) : "memory");

    // lw の直後に tmp を使う（同一asmブロックで順序固定）
    // 期待:
    //   tmp = 0x12345678
    //   tmp = tmp + 1       => 0x12345679
    //   tmp = tmp ^ 0x00FF00FF
    //       = 0x12CB56? ではなく正確に:
    //         0x12345679 ^ 0x00FF00FF = 0x12CB5686
    asm volatile (
        "lw   %[lu], 8(%[base])      \n"  // load
        "addi %[lu], %[lu], 1        \n"  // use immediately (load-use)
        "xori %[lu], %[lu], 0x0FF    \n"  // 低12bit即値: 0x0FF だけ使う（RV32I xori imm12）
        // ここで 0x00FF00FF をやりたいが imm12制限があるので分解して作る:
        // lu ^= 0x000000FF は上の xori で実施済み
        // 次に 0x00FF0000 を作って xor
        "lui  t2, 0x00FF0            \n"  // t2 = 0x00FF0000
        "xor  %[lu], %[lu], t2       \n"
        : [lu] "+r"(lu)
        : [base] "r"(mem)
        : "t2", "memory"
    );

    result ^= lu;
    report(14, lu);

    /* =====================================================
       FINAL
       ===================================================== */
    mmio_write(TEST_END_CODE);
    mmio_write(result);

    while (1) { }
}

/* ---------- 実体 ---------- */
extern "C" {
    volatile uint32_t result = 0;
}