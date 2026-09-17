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

        uint32_t status = PFE_DATA;

        if ((status >> 1) & 1)
            break;
    }
}

static inline int32_t read_energy(void)
{
    PFE_CTRL = (READ_ENERGY << 16);
    return (int32_t)PFE_DATA;
}

/* ---------- Entry ---------- */
extern "C" void run()
{
    uint32_t error_count = 0;

    PFE_CTRL = CMD_CLEAR;

    //
    // Q =
    // [ -1   2 ]
    // [  2  -3 ]
    //
    write_q(0, -1);
    write_q(1,  2);
    write_q(2,  2);
    write_q(3, -3);

    //
    // x = 01
    //
    write_x(0b01);

    start_pfe();
    wait_done();

    int32_t energy = read_energy();

    if (energy != -1)
        error_count++;

    result = error_count;

    //
    // End
    //
    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) {
    }
}

/* ---------- Definition ---------- */
extern "C" {
volatile uint32_t result = 0;
}