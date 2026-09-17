# PSC_SDCard

## Overview

PSC_SDCard is a hardware IP core that implements SD card (SPI mode) sector read functionality for FPGA-based systems.

It provides a simple MMIO-based interface for the CPU, while internally handling SD card initialization, command sequencing, data transfer, FIFO buffering, and SPI communication.

From the CPU perspective, it behaves like a memory-mapped SD card reader.

---

## Features

- Full SD card initialization (SPI mode)
- Single block read (CMD17)
- 512-byte FIFO buffer
- Memory-mapped interface (MMIO)
- CRC reception (no validation yet)
- Configurable SPI clock (init + fast mode)
- Error and status reporting

---

## Example: SD Read Log

The following is an actual log captured from PSC_OS when reading a sector from the SD card.

This demonstrates that PSC_SDReader successfully performs a full SD card read sequence, including CRC reception and FIFO-based data transfer.

```asm
PSC_OS> sd_read 100
CRC OK (retry=0)

37 55 25 00 13 05 05 EB 13 01 05 00 6F 10 80 4C 
B7 05 00 10 03 A6 85 00 13 76 16 00 63 06 06 00 
13 00 00 00 6F F0 1F FF 23 A0 A5 00 67 80 00 00 
B7 05 00 10 03 A6 85 00 13 76 16 00 63 06 06 00 
13 00 00 00 6F F0 1F FF 23 A0 A5 00 67 80 00 00 
37 05 00 10 83 25 85 00 93 F5 25 00 63 96 05 00 
13 00 00 00 6F F0 1F FF 03 25 45 00 13 75 F5 0F 
67 80 00 00 13 01 01 FF 23 26 11 00 23 24 81 00 
B7 55 22 00 03 C6 05 E0 63 08 06 00 B7 55 22 00 
03 A4 45 E0 6F 00 40 01 13 06 10 00 23 80 C5 E0 
B7 55 25 00 13 84 05 00 13 16 C5 00 33 05 C4 00 
B7 55 22 00 B7 56 35 00 93 86 06 00 23 A2 A5 E0 
63 F2 A6 02 37 25 20 00 13 05 F5 69 B7 25 20 00 
93 85 25 2E 13 06 90 08 97 10 00 00 E7 80 80 69 
6F 00 00 00 13 05 04 00 93 05 00 00 97 10 00 00 
E7 80 80 56 13 05 04 00 83 20 C1 00 03 24 81 00 
13 01 01 01 67 80 00 00 37 05 50 00 B7 05 40 00 
13 01 05 00 73 90 15 14 93 02 00 02 73 90 02 10 
73 00 20 10 73 10 01 14 13 01 41 F8 13 00 00 00 
23 20 11 00 23 22 31 00 23 24 41 00 23 26 51 00 
23 28 61 00 23 2A 71 00 23 2C C1 01 23 2E D1 01 
23 20 E1 03 23 22 F1 03 23 24 A1 02 23 26 B1 02 
23 28 C1 02 23 2A D1 02 23 2C E1 02 23 2E F1 02 
23 20 01 05 23 22 11 05 23 24 81 04 23 26 91 04 
23 28 21 05 23 2A 31 05 23 2C 41 05 23 2E 51 05 
23 20 61 07 23 22 71 07 23 24 81 07 23 26 91 07 
23 28 A1 07 23 2A B1 07 73 25 00 14 23 2C A1 06 
13 05 01 00 97 10 00 00 E7 80 40 F7 83 20 01 00 
83 21 41 00 03 22 81 00 83 22 C1 00 03 23 01 01 
83 23 41 01 03 2E 81 01 83 2E C1 01 03 2F 01 02 
83 2F 41 02 03 25 81 02 83 25 C1 02 03 26 01 03 
83 26 41 03 03 27 81 03 83 27 C1 03 03 28 01 04
```

### Notes

- Sector: LBA 100
- CRC status: OK (retry=0)
- Data size: 512 bytes
- Transfer path: SD → SPI → FIFO → CPU (MMIO)

This log was captured on real FPGA hardware using PSC_OS.
The output shows raw binary data stored in the SD card sector, corresponding to executable code loaded by the system.

---

## Memory Map (MMIO)

| Address      | Name         | Description                    |
|-------------|--------------|--------------------------------|
| 0x10006000  | SD_IF_DATA   | FIFO read (1 byte per access) |
| 0x10006004  | SD_IF_SECTOR | Sector (LBA) register         |
| 0x10006008  | SD_IF_CTRL   | Control / Status register     |

---

## Control Register (SD_IF_CTRL)

Write (Control)

| Bit | Function             |
|-----|----------------------|
| 0   | Start initialization |
| 1   | Start read (CMD17)   |
| 2   | FIFO flush           |
| 3   | Soft reset           |
| 4   | Clear error          |

Read (Status)

| Bit | Name        | Description                 |
|-----|-------------|-----------------------------|
| 1   | busy        | Operation in progress       |
| 2   | read_ready  | Ready for new read command  |
| 3   | fifo_empty  | FIFO is empty               |
| 4   | fifo_full   | FIFO is full                |
| 5   | error       | Error occurred              |

Upper bytes contain CRC1 and CRC2 received from the SD card.

---

## Usage Flow

1. Initialize SD Card

```c
*(volatile uint32_t*)0x10006008 = 0x01;
```

2. Set Sector (LBA)

```c
*(volatile uint32_t*)0x10006004 = lba;
```

3. Start Read

```c
*(volatile uint32_t*)0x10006008 = 0x02;
```

4. Read Data (512 bytes)

```c
for (int i = 0; i < 512; i++) {
    uint8_t data = *(volatile uint32_t*)0x10006000;
}
```

---

## Internal Architecture

The module consists of three main components:

- SPI Engine (PSC_SDReader_SPI)
  Handles SPI timing and byte-level communication with the SD card. Supports both initialization (slow clock) and normal operation (fast clock).

- FIFO Buffer
  Stores the 512-byte sector data received from the SD card. This decouples SPI timing from CPU access timing.

- FSM (Finite State Machine)
  Controls SD card initialization and read operations.

---

## Initialization Sequence

RESET  
→ 80 clock cycles (CS high)  
→ CMD0  
→ CMD8  
→ CMD55  
→ ACMD41 (loop until ready)  
→ CMD58  
→ READY  

---

## Read Sequence

READY  
→ CMD17 (read single block)  
→ WAIT_R1  
→ WAIT_TOKEN (0xFE)  
→ READ_DATA (512 bytes)  
→ READ_CRC (2 bytes)  
→ DONE  
→ READY  

---

## FIFO Behavior

- Data is pushed from SPI into FIFO
- CPU reads data via MMIO
- FIFO depth is configurable (default: 512 bytes)

---

## Busy Definition

```verilog
busy = (state != ST_READY) || (fifo_count != 0);
```

The module is considered busy when the FSM is active or when unread data remains in the FIFO.

---

## Limitations

- SDHC only (LBA addressing assumed)
- No CRC validation (only captured)
- Single block read only (no CMD18)
- Write operation not supported
- FIFO full handling is minimal

---

## Future Improvements

- CRC verification
- Multi-block read (CMD18)
- Write support (CMD24)
- DMA integration
- SDSC support

---

## Summary

PSC_SDReader is a lightweight SD card interface IP that provides a simple CPU-side interface with fully hardware-managed SD protocol.

It is suitable for bare-metal OS, FPGA SoC designs, and custom storage subsystems.
