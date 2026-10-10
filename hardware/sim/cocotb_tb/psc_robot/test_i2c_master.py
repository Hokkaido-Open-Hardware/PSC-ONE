"""Host checks for wire framing; the SoC test verifies actual slave ACK/data."""
import asyncio
from pathlib import Path
from types import SimpleNamespace
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from cocotb_tb.psc_robot.i2c_master import RobotI2CMaster, FRAMES, hex_payload


class BusSamples:
    def __init__(self, samples):
        self.samples = iter(samples)

    @property
    def value(self):
        return next(self.samples)


class MasterTests(unittest.TestCase):
    def run_frame(self, samples):
        dut = SimpleNamespace(PSCONE_SCL=SimpleNamespace(value=1),
                              i2c_master_sda_low=SimpleNamespace(value=0),
                              i2c_sda_bus=BusSamples(samples))
        master = RobotI2CMaster(dut)
        waveform = []

        async def wait():
            waveform.append((dut.PSCONE_SCL.value, dut.i2c_master_sda_low.value))

        master.wait = wait
        return master, dut, waveform

    def test_frame_bits_and_release_for_ack(self):
        master, dut, waveform = self.run_frame([1] + [0] * 6 + [1])
        asyncio.run(master.write_frame(FRAMES[0]))
        clocks = [low for scl, low in waveform[3:-3] if scl == 1]
        expected = []
        for value in (0x84, 0x00, *FRAMES[0]):
            expected.extend(1 - ((value >> bit) & 1) for bit in range(7, -1, -1))
            expected.append(0)  # master releases SDA for ACK
        self.assertEqual(clocks, expected)
        self.assertEqual((dut.PSCONE_SCL.value, dut.i2c_master_sda_low.value), (1, 0))
        self.assertEqual(hex_payload(FRAMES[0]), "11 FE 80 7F")

    def test_nack_fails_and_releases_bus(self):
        master, dut, waveform = self.run_frame([1, 1, 1])
        with self.assertRaisesRegex(AssertionError, "I2C NACK: address"):
            asyncio.run(master.write_frame(FRAMES[0]))
        self.assertEqual(waveform[-3:], [(0, 1), (1, 1), (1, 0)])


if __name__ == "__main__":
    unittest.main()
