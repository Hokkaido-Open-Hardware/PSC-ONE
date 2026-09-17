# How to Use

---

## Run PE simulation

```bash
make -f Makefile.ai simulate_PE
```

### log

```bash
~/Program/PSC-ONE/hardware/sim$ make -f Makefile.ai simulate_PE

make -f /home/haruhiko/Program/PSC-ONE/myenv/lib/python3.12/site-packages/cocotb_tools/makefiles/Makefile.sim \
    SIM=icarus \
    MODULE=cocotb_tb.ai.int8_PE_test1 \
    TOPLEVEL=sim_PE_top \
    TOPLEVEL_LANG=verilog \
    EXTRA_ARGS="" \
    VERILOG_SOURCES="../rtl/ai/src/PE_INT.v ../rtl/ai/src/PE_mult.v ../rtl/ai/src/sim_PE_top.v"

     0.00ns INFO     cocotb.regression                  pytest not found, install it to enable better AssertionError messages
     0.00ns INFO     cocotb                             Running tests
     0.00ns INFO     cocotb.regression                  running cocotb_tb.ai.int8_PE_test1.test_pe_seri_nbit_multiple (1/1)
                                                            PE_Seri_Nbit を 20 ケースで検証（unsigned）。
    50.00ns INFO     cocotb.sim_PE_top                  Detected widths: DW=8, PW=16, SW=32
   150.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 0 passed: 0 * 0 + 0 = 0
   250.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 1 passed: 1 * 1 + 0 = 1
   350.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 2 passed: 1 * 1 + 0 = 1
   450.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 3 passed: 1 * 1 + 0 = 1
   550.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 4 passed: 3 * 3 + 0 = 9
   650.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 5 passed: 13 * 22 + 0 = 286
   750.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 6 passed: 13 * 22 + 0 = 286
   850.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 7 passed: 255 * 1 + 0 = 255
   950.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 8 passed: 1 * 1 + 0 = 1
  1050.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 9 passed: 1 * 255 + 0 = 255
  1150.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 10 passed: 1 * 1 + 2 = 3
  1250.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 11 passed: 3 * 3 + 13 = 22
  1350.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 12 passed: 127 * 2 + 0 = 254
  1450.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 13 passed: 255 * 255 + 0 = 65025
  1550.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 14 passed: 5 * 7 + 3 = 38
  1650.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 15 passed: 225 * 59 + 15 = 13290
  1750.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 16 passed: 46 * 17 + 171 = 953
  1850.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 17 passed: 50 * 181 + 484 = 9534
  1950.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 18 passed: 8 * 15 + 32 = 152
  1950.00ns INFO     cocotb.sim_PE_top                  ============================================================
  2050.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 0 passed: 0 * 0 + 0 = 0
  2140.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 1 passed: 1 * 1 + 0 = 1
  2230.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 2 passed: 1 * 1 + 0 = 2
  2320.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 3 passed: 1 * 1 + 0 = 3
  2410.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 4 passed: 3 * 3 + 0 = 12
  2500.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 5 passed: 13 * 22 + 0 = 298
  2590.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 6 passed: 13 * 22 + 0 = 584
  2680.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 7 passed: 255 * 1 + 0 = 839
  2770.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 8 passed: 1 * 1 + 0 = 840
  2860.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 9 passed: 1 * 255 + 0 = 1095
  2950.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 10 passed: 1 * 1 + 2 = 1096
  3040.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 11 passed: 3 * 3 + 13 = 1105
  3130.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 12 passed: 127 * 2 + 0 = 1359
  3220.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 13 passed: 255 * 255 + 0 = 66384
  3310.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 14 passed: 5 * 7 + 3 = 66419
  3400.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 15 passed: 225 * 59 + 15 = 79694
  3490.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 16 passed: 46 * 17 + 171 = 80476
  3580.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 17 passed: 50 * 181 + 484 = 89526
  3670.00ns INFO     cocotb.sim_PE_top                  ✅ Pattern 18 passed: 8 * 15 + 32 = 89646
  3670.00ns INFO     cocotb.sim_PE_top                  All patterns passed for PE_Seri_Nbit (unsigned).
  3670.00ns INFO     cocotb.regression                  cocotb_tb.ai.int8_PE_test1.test_pe_seri_nbit_multiple passed
  3670.00ns INFO     cocotb.regression                  ***************************************************************************************************************
                                                        ** TEST                                                   STATUS  SIM TIME (ns)  REAL TIME (s)  RATIO (ns/s) **
                                                        ***************************************************************************************************************
                                                        ** cocotb_tb.ai.int8_PE_test1.test_pe_seri_nbit_multiple   PASS        3670.00           0.02     167176.34  **
                                                        ***************************************************************************************************************
                                                        ** TESTS=1 PASS=1 FAIL=0 SKIP=0                                        3670.00           0.02     153035.70  **
                                                        ***************************************************************************************************************
                                                        

```

---

## Run CPU simulation

```bash
make -f Makefile.cpu simulate_PSC_ONE_TESTS 
```

### log

```bash
/home/haruhiko/Program/PSC-ONE/myenv/lib/python3.12/site-packages/cocotb_tools/makefiles/simulators/Makefile.icarus:66: Using MODULE is deprecated, please use COCOTB_TEST_MODULES instead.
     -.--ns INFO     gpi                                ..mbed/gpi_embed.cpp:93   in _embed_init_python              Using Python 3.12.4 interpreter at /home/haruhiko/Program/PSC-ONE/myenv/bin/python3
     -.--ns INFO     gpi                                ../gpi/GpiCommon.cpp:79   in gpi_print_registered_impl       VPI registered
     0.00ns INFO     cocotb                             Running on Icarus Verilog version 12.0 (stable)
     0.00ns INFO     cocotb                             Seeding Python random module with 1780380171
     0.00ns INFO     cocotb                             Initialized cocotb v2.0.1 from /home/haruhiko/Program/PSC-ONE/myenv/lib/python3.12/site-packages/cocotb
     0.00ns INFO     cocotb                             Running tests
     0.00ns INFO     cocotb.regression                  running cocotb_tb.cpu.RV32ISP_chip_test.RV32IS_chip_test1 (1/1)
     0.00ns INFO     cocotb.PSC_ONE_Chip_sim            ==============================================================
     0.00ns INFO     cocotb.PSC_ONE_Chip_sim            Start PSC_RV32IS Chip test
     0.00ns INFO     cocotb.PSC_ONE_Chip_sim            Boot from ROM
     0.00ns INFO     cocotb.PSC_ONE_Chip_sim            ==============================================================
     0.00ns INFO     cocotb.PSC_ONE_Chip_sim            Start PSC_RV32IS Chip test
     0.00ns INFO     cocotb.PSC_ONE_Chip_sim            [CONF] PROGRAM_FILE=./mem/add_test1.mem
     0.00ns INFO     cocotb.PSC_ONE_Chip_sim            PSC_RV32IS_Boot_axi ROM_WORD : 2048
ERROR: ../rtl/boot/PSC_ONE_Boot_axi.v:483: $readmemh: Unable to open mem/bootloader.mem for reading.
WARNING: ../rtl/boot/PSC_ONE_Boot_axi.v:504: $readmemh(mem/bootrom.mem): Not enough words in the file for the requested range [0:127].
475455.00ns INFO     cocotb.PSC_ONE_Chip_sim            Boot_rom_done=H. Start CPU
475455.00ns INFO     cocotb.PSC_ONE_Chip_sim            Waiting for PIO_out_reg == 0xEE01 ...
489285.00ns INFO     cocotb.PSC_ONE_Chip_sim            PIO matched 0xEE01 at cycle 1382
499285.00ns INFO     cocotb.PSC_ONE_Chip_sim            Stop CPU
499485.00ns INFO     cocotb.PSC_ONE_Chip_sim            pio.word0=0xff00ff0b, expected=0xff00ff0b
499485.00ns INFO     cocotb.PSC_ONE_Chip_sim            [LOG] Appended to log/test_result_20260602_150250.log
499485.00ns INFO     cocotb.PSC_ONE_Chip_sim            [PASS] PIO holds expected 0xff00ff0b
509485.00ns INFO     cocotb.regression                  cocotb_tb.cpu.RV32ISP_chip_test.RV32IS_chip_test1 passed
509485.00ns INFO     cocotb.regression                  ***********************************************************************************************************
                                                        ** TEST                                               STATUS  SIM TIME (ns)  REAL TIME (s)  RATIO (ns/s) **
                                                        ***********************************************************************************************************
                                                        ** cocotb_tb.cpu.RV32ISP_chip_test.RV32IS_chip_test1   PASS      509485.00           6.18      82483.84  **
                                                        ***********************************************************************************************************
                                                        ** TESTS=1 PASS=1 FAIL=0 SKIP=0                                  509485.00           6.18      82456.60  **
                                                        ***********************************************************************************************************
                                                        
```

---

# Clean simulation files

```bash
make -f Makefile.ai clean
```


