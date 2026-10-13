// CPU/MMIO regression for the deterministic Makefile.sdcard image.
#include <cstdint>

#define PIO32         (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
#define PSC_SD_DATA   (*reinterpret_cast<volatile uint32_t*>(0x10006000u))
#define PSC_SD_SECTOR (*reinterpret_cast<volatile uint32_t*>(0x10006004u))
#define PSC_SD_CTRL   (*reinterpret_cast<volatile uint32_t*>(0x10006008u))

static constexpr uint32_t BUSY = 0x02;
static constexpr uint32_t READY = 0x04;
static constexpr uint32_t EMPTY = 0x08;
static constexpr uint32_t ERROR = 0x20;

[[noreturn]] static void finish(uint32_t result) {
    PIO32 = 0xEE01;
    PIO32 = result;
    while (true) { asm volatile("nop"); }
}

static uint32_t wait_status(uint32_t mask, uint32_t expected, uint32_t failure) {
    for (uint32_t remaining = 200000; remaining != 0; --remaining) {
        const uint32_t status = PSC_SD_CTRL;
        if ((status & ERROR) != 0) finish(0xDEAD0005);
        if ((status & mask) == expected) return status;
    }
    finish(failure);
}

static uint32_t expected_byte(uint32_t lba, uint32_t offset) {
    // 64 MiB FAT32 image: partition starts at LBA 8192, length 122880.
    // LBA 0 is the MBR; LBA 1 is entirely zero. These expectations are
    // independent of the bytes returned by the SD controller.
    static constexpr uint8_t partition[16] = {
        0x00, 0xFE, 0xFF, 0xFF, 0x0C, 0xFE, 0xFF, 0xFF,
        0x00, 0x20, 0x00, 0x00, 0x00, 0xE0, 0x01, 0x00
    };
    if (lba != 0) return 0;
    if (offset >= 446 && offset < 462) return partition[offset - 446];
    if (offset == 510) return 0x55;
    if (offset == 511) return 0xAA;
    return 0;
}

extern "C" void run() {
    PSC_SD_CTRL = 0x04;  // FIFO flush; DATA writes remain byte-oriented.
    PSC_SD_CTRL = 0x01;
    wait_status(BUSY | READY | EMPTY, READY | EMPTY, 0xDEAD0001);

    for (uint32_t lba = 0; lba < 2; ++lba) {
        // No intervening flush: both FIFO pointers must wrap after 512 bytes.
        PSC_SD_SECTOR = lba;
        if (PSC_SD_SECTOR != lba) finish(0xDEAD0006);
        PSC_SD_CTRL = 0x02;
        wait_status(READY, 0, 0xDEAD0002);
        const uint32_t completed = wait_status(READY, READY, 0xDEAD0003);
        if ((completed & EMPTY) != 0) finish(0xDEAD0007);

        uint32_t crc = 0;
        for (uint32_t index = 0; index < 128; ++index) {
            const uint32_t word = PSC_SD_DATA;  // exactly one READ per 4 bytes
            for (uint32_t lane = 0; lane < 4; ++lane) {
                const uint32_t offset = index * 4 + lane;
                const uint32_t byte = (word >> (lane * 8)) & 0xFF;
                if (byte != expected_byte(lba, offset))
                    finish(0xBAD00000 | (lba << 12) | offset);
                crc ^= byte << 8;
                for (uint32_t bit = 0; bit < 8; ++bit)
                    crc = ((crc << 1) ^ ((crc & 0x8000) != 0 ? 0x1021u : 0u)) & 0xFFFF;
            }
            const uint32_t status = PSC_SD_CTRL;
            if ((status & ERROR) != 0) finish(0xDEAD0008);
            if (((status & EMPTY) != 0) != (index == 127)) finish(0xDEAD0009);
        }
        if (crc != (completed >> 16)) finish(0xDEAD000A);
        if ((PSC_SD_CTRL & (BUSY | READY | EMPTY | ERROR)) != (READY | EMPTY))
            finish(0xDEAD000B);
        if (PSC_SD_DATA != 0xE0) finish(0xDEAD000C);
    }

    // Preserve the existing harness result: the empty marker, observed only
    // after both complete sectors, byte order, CRC and status have passed.
    finish(PSC_SD_DATA);
}
