#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- PFE MMIO ---------- */
#define PFE_DATA (*reinterpret_cast<volatile uint32_t*>(0x10008000u))
#define PFE_CTRL (*reinterpret_cast<volatile uint32_t*>(0x10008004u))

/* ---------- Command ---------- */
static constexpr uint32_t CMD_START   = 1;
static constexpr uint32_t CMD_CLEAR   = 2;
static constexpr uint32_t CMD_WRITE_Q = 3;
static constexpr uint32_t CMD_WRITE_X = 4;

/* ---------- Read ---------- */
static constexpr uint32_t READ_ENERGY = 1;
static constexpr uint32_t READ_STATUS = 2;

/* ---------- result ---------- */
extern "C" volatile uint32_t result;

/* ---------- helper ---------- */
static inline void write_q(uint32_t index, int32_t value)
{
    PFE_DATA = (uint32_t)value;
    PFE_CTRL = (index << 8) | CMD_WRITE_Q;
}

static inline void write_x(uint32_t x)
{
    PFE_CTRL = (x << 8) | CMD_WRITE_X;
}

static inline void start_pfe(void)
{
    PFE_CTRL = CMD_START;
}

static inline void wait_done(void)
{
    while (1) {
        PFE_CTRL = (READ_STATUS << 16);

        if ((PFE_DATA >> 1) & 1)
            break;
    }
}

static inline int32_t calc_energy(uint32_t x)
{
    write_x(x);

    start_pfe();
    wait_done();

    PFE_CTRL = (READ_ENERGY << 16);

    return (int32_t)PFE_DATA;
}

/* ---------- Entry ---------- */
extern "C" void run()
{
    uint32_t error_count = 0;

    PFE_CTRL = CMD_CLEAR;

    /* ---------- Q Matrix (8x8) ---------- */
    static const int8_t q[64] = {

        //      0   1   2   3   4   5   6   7
           -1,  2,  0,  0,  0,  0,  0,  0,
            2, -3,  1,  0,  0,  0,  0,  0,
            0,  1, -2,  2,  0,  0,  0,  0,
            0,  0,  2, -1, -1,  0,  0,  0,
            0,  0,  0, -1, -2,  1,  0,  0,
            0,  0,  0,  0,  1, -3,  2,  0,
            0,  0,  0,  0,  0,  2, -1, -2,
            0,  0,  0,  0,  0,  0, -2, -1
    };

    // -----------------------------
    // Write Q
    // -----------------------------
    for (uint32_t i = 0; i < 64; i++)
        write_q(i, q[i]);

    // -----------------------------
    // Exhaustive Search
    // -----------------------------
    int32_t ref_energy = 0x7fffffff;
    uint32_t ref_x = 0;

    for (uint32_t x = 0; x < 256; x++) {

        int32_t e = calc_energy(x);

        if (e < ref_energy) {
            ref_energy = e;
            ref_x = x;
        }
    }

    // -----------------------------
    // Greedy Search
    // -----------------------------
    uint32_t cur_x = 0;
    int32_t cur_energy = calc_energy(cur_x);

    bool update;

    do {

        update = false;

        for (uint32_t bit = 0; bit < 8; bit++) {

            uint32_t next = cur_x ^ (1u << bit);

            int32_t e = calc_energy(next);

            if (e < cur_energy) {
                cur_energy = e;
                cur_x = next;
                update = true;
            }
        }

    } while (update);

    // Debug
    PIO32 = ref_x;
    PIO32 = (uint32_t)ref_energy;

    PIO32 = cur_x;
    PIO32 = (uint32_t)cur_energy;

    int32_t gap = cur_energy - ref_energy;
    if (gap < 0)
        gap = -gap;

    if (gap > 10)
        error_count++;

    result = error_count;

    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) {
    }
}

extern "C" {
    volatile uint32_t result = 0;
}