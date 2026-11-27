# PSC-ONE for the Tang Mega 138K

<img src="../../docs/images/TangMega138K.jpg" alt="Tang Mega 138K board" width="600">

## Rotating teapot demo

<img src="../../docs/images/tang138k_teapod.jpg" alt="Teapot demo running on the Tang Mega 138K" width="600">

The display controller reads pixel data over the AXI bus from a framebuffer (VRAM) in external DDR3 memory. The demo rotates the teapot to its next orientation every 0.2 seconds.

## SoC block diagram

<img src="../../docs/images/PSC_ONE_SoC_138K_Block.jpg" alt="Block diagram of the PSC-ONE SoC for the Tang Mega 138K" width="600">

The PSC_RV32 CPU uses separate instruction and data caches and controls peripherals through memory-mapped I/O.<br>
The AXI4 arbiter gives the CPU, DMA engine, and boot ROM loader shared access to external DDR3 memory.<br>
Custom hardware in `USER_LOGIC` can access the same memory through its own 32-bit AXI4 port.

### RV32 v1 address translation

The board top defaults to `ENABLE_SV32_TLB=1`. This gives each RV32 v1 MMU
an independent eight-entry TLB for 4 KiB pages. Set the parameter to `0` on
`PSC_ONE_138K_Chip` before synthesis to use the original page-table walker
and its one-entry caches. Both configurations handle 4 MiB pages in the walker.

## USER_LOGIC

`USER_LOGIC` is an FPGA region connected to the PSC-ONE AXI bus. You can use it to implement your own logic. I plan to use this region for an AI accelerator and confidential company logic.

## UART connection

The onboard BL616 UART appears to be unavailable in this configuration. For serial communication, connect a USB-to-UART adapter with 3.3 V logic levels to the GPIO pins above the PCIe connector. The [board constraint file](cst/PSC_ONE_tang138k_cst.cst) defines the FPGA pin assignments.

| Board signal | FPGA pin | USB-to-UART adapter pin |
| --- | --- | --- |
| `gpio_uart_tx` (output) | A13 | RX |
| `gpio_uart_rx` (input) | B15 | TX |
| GND | — | GND |

## License

You may use this design under the terms of the [PSC-ONE MIT License](../../LICENSE).
