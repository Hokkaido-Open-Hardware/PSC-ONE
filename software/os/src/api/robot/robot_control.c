#include "robot_control.h"
#include "../i2c_api.h"
#include "../../kernel/kernel.h"

/* The shell cannot access peripheral MMIO from U-mode. This command runs
 * in the kernel via SYS_ROBOT_CONTROL, like the existing microphone command.
 * The external master must wait for each UART report before its next frame:
 * the I2C peripheral has one input slot, not a receive FIFO. */
void robot_control(void)
{
    int8_t input[PSC_I2C_INPUT_COUNT];

    i2c_init();
    s_printf("robot_control: ready (I2C=0x42, 4 bytes; q/Ctrl-C to stop)\n");
    for (;;) {
        /* Poll once: the blocking getchar would prevent I2C reception while
         * no console key is pressed. */
        long ch = uart_getchar_timeout(1);
        if (ch == 'q' || ch == 3)
            break;

        uint32_t status = i2c_get_status();
        if (i2c_read_input(input) == I2C_OK) {
            int seq = i2c_get_sequence();
            static const char digits[] = "0123456789ABCDEF";
            char hex[PSC_I2C_INPUT_COUNT * 3];
            unsigned pos = 0;
            for (unsigned i = 0; i < PSC_I2C_INPUT_COUNT; ++i) {
                uint8_t byte = (uint8_t)input[i];
                if (i != 0)
                    hex[pos++] = ' ';
                hex[pos++] = digits[byte >> 4];
                hex[pos++] = digits[byte & 15u];
            }
            hex[pos] = '\0';
            i2c_clear_status(PSC_I2C_STATUS_INPUT_READY | PSC_I2C_STATUS_OVERRUN);
            s_printf("I2C RX seq=%d HEX=%s\n", seq, hex);
            if (status & PSC_I2C_STATUS_OVERRUN)
                s_printf("robot_control: I2C overrun (input lost)\n");
        }
    }
    i2c_set_irq_enabled(0);
    s_printf("robot_control: stopped\n");
}

/* PSC_Robot lockstep integration service; shell command above is retained. */
int8_t robot_control_compute(const int8_t input[4])
{
    /* Q16 coefficients include input/output scales and wheel radius .034.
     * u = (-2.14021658*p + .0350137084*rate
     *      + 2.23606798*.034*wheel - 2.23606798*target) / .034 */
    int32_t acc = -66006 * (int32_t)input[0]
                + 10799 * (int32_t)input[1]
                + 293086 * (int32_t)input[2]
                - 68963 * (int32_t)input[3];
    int32_t result = acc >= 0 ? (acc + 32768) / 65536
                              : -((-acc + 32768) / 65536);
    if (result > 127) result = 127;
    if (result < -128) result = -128;
    return (int8_t)result;
}

int robot_control_poll(void)
{
    int8_t input[4];
    int rc = i2c_read_input(input);
    if (rc != I2C_OK) return rc;
    /* Master serializes frames and checks OVERRUN; do not erase evidence. */
    i2c_clear_status(PSC_I2C_STATUS_INPUT_READY);
    i2c_write_output(robot_control_compute(input));
    return I2C_OK;
}

void robot_control_run(void)
{
    i2c_init();
    /* Startup sentinel: OUTPUT_READY + SEQ=0. Master reads this before input. */
    i2c_write_output(0);
    for (;;) (void)robot_control_poll();
}
