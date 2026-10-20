#include "pwm_test.h"

int pwm_test_signed16(const uint8_t *p)
{
    int value = (int)p[0] | ((int)p[1] << 8);
    return value >= 32768 ? value - 65536 : value;
}

const char *pwm_test_decode(const uint32_t *events, unsigned count,
                            pwm_test_result *r)
{
    const uint8_t expected[4] = {20, 0, 20, 0};
    uint8_t data[9];
    unsigned phase = 0, active = 0, address = 0, length = 0, bad_ack = 0;
    *r = (pwm_test_result){0};
    if (count > 64) return "invalid capture count";
    for (unsigned i = 0; i < count; ++i) {
        unsigned event = events[i], kind = (event >> 9) & 7;
        unsigned byte = event & 255, nack = (event >> 8) & 1;
        if (kind == 1 || kind == 2) {
            if (active || (phase && kind == 2)) return "unexpected START / incomplete transaction";
            active = 1; address = 0; length = 0; bad_ack = 0;
        } else if (kind == 4) {
            if (!active || address || (byte >> 1) != 0x42 || nack)
                return "invalid address / address NACK";
            address = byte;
        } else if (kind == 5) {
            if (!active || !address) return "data without address";
            if (length < sizeof(data)) data[length] = (uint8_t)byte;
            /* READ must ACK the first three bytes and NACK the fourth. */
            if (nack != ((address & 1) && length == 3)) bad_ack = 1;
            ++length;
        } else if (kind == 3) {
            if (!active || !address) return "incomplete transaction";
            active = 0;
            if (phase == 0) {
                /* ARM can precede READ/report of a cycle whose WRITE was missed. */
                if (address & 1) continue;
                if (length == 9 && data[0] == 0xa5) continue;
                if (length != 4) return "Arduino WRITE length mismatch";
                if (bad_ack) return "Arduino WRITE NACK";
                r->write_seen = 1;
                r->left = pwm_test_signed16(data);
                r->right = pwm_test_signed16(data + 2);
                phase = 1;
            } else if (phase == 1) {
                if (!(address & 1)) return "expected Arduino READ";
                r->read_seen = 1; r->read_bytes = length;
                if (length != 4) return "Arduino READ length mismatch";
                if (bad_ack) return "Arduino READ ACK/NACK mismatch";
                for (unsigned j = 0; j < 4; ++j)
                    if (data[j] != expected[j]) return "Arduino READ value mismatch";
                phase = 2;
            } else {
                if (address & 1) return "expected Arduino report WRITE";
                if (length != 9) return "Arduino report length mismatch";
                if (bad_ack) return "Arduino report NACK";
                if (data[0] != 0xa5 || data[1] != 1)
                    return "Arduino report identifier/version mismatch";
                r->report_seen = 1; r->report_status = data[2];
                r->ack_left = pwm_test_signed16(data + 5);
                r->ack_right = pwm_test_signed16(data + 7);
                /* Arduino sets bit7 unconditionally: transport test only. */
                if (data[2] & 0x7f) return "Arduino receive error/timeout";
                if (data[3] != 4 || data[4] != 4)
                    return "Arduino requested/returned length mismatch";
                for (unsigned j = 0; j < 4; ++j)
                    if (data[j + 5] != expected[j]) return "Arduino report value mismatch";
                return 0;
            }
        } else return "invalid capture event";
    }
    return "incomplete WRITE/READ/report sequence";
}
