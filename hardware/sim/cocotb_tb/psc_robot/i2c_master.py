"""External open-drain master. Only simulation top-level pins are driven."""
from cocotb.triggers import Timer


FRAMES = ((0x11, 0xFE, 0x80, 0x7F), (0x00, 0xFF, 0x55, 0xAA))


def hex_payload(frame):
    return " ".join(f"{byte:02X}" for byte in frame)


class RobotI2CMaster:
    def __init__(self, dut):
        self.scl = dut.PSCONE_SCL
        # Explicit low-enable and resolved bus avoid Verilator's 2-state Z.
        self.sda_low = dut.i2c_master_sda_low
        self.sda_bus = dut.i2c_sda_bus

    async def wait(self):
        await Timer(5000, unit="ns")

    async def start(self):
        self.scl.value = 0
        self.sda_low.value = 0
        await self.wait()
        self.scl.value = 1
        await self.wait()
        assert int(self.sda_bus.value) == 1, "SDA stuck low before START"
        self.sda_low.value = 1
        await self.wait()
        self.scl.value = 0

    async def stop(self):
        self.scl.value = 0
        self.sda_low.value = 1
        await self.wait()
        self.scl.value = 1
        await self.wait()
        self.sda_low.value = 0
        await self.wait()
        assert int(self.sda_bus.value) == 1, "SDA stuck low after STOP"

    async def write_byte(self, value):
        for bit in range(7, -1, -1):
            self.sda_low.value = 1 - ((value >> bit) & 1)
            await self.wait()
            self.scl.value = 1
            await self.wait()
            self.scl.value = 0
        self.sda_low.value = 0  # release for the slave's ACK
        await self.wait()
        self.scl.value = 1
        await self.wait()
        ack = int(self.sda_bus.value) == 0
        self.scl.value = 0
        await self.wait()
        return ack

    async def write_frame(self, frame):
        assert len(frame) == 4 and all(0 <= byte <= 255 for byte in frame)
        await self.start()
        try:
            for label, value in [("address", 0x42 << 1), ("register", 0),
                                 *[(f"data[{i}]", byte) for i, byte in enumerate(frame)]]:
                assert await self.write_byte(value), f"I2C NACK: {label} 0x{value:02x}"
        finally:
            await self.stop()
