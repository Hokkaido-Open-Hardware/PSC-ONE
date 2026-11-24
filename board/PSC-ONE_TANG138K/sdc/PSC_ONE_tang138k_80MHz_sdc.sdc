# PSC-ONE
# Tang138K

# ===============================
# System clock (50MHz)
# ===============================
create_clock -name sys_clk -period 20.000 -waveform {0.000 10.000} [get_ports {sys_clk}]

# 50 MHz x 5 x (5 + 1/8) = 1281.25 MHz PLL VCO.
# CLKOUT0 is VCO / 16 (80.078125 MHz).
create_clock -name clk80 -period 12.4878 -waveform {0 6.2439} [get_nets {clock_100MHz}]
# DDR3 fabric CLKDIV divides CLKOUT2 by four (80.078125 MHz).
create_clock -name clk_x1 -period 12.4878 -waveform {0 6.2439} [get_pins {u_ddr3/gw3_top/u_ddr_phy_top/fclkdiv/CLKOUT}]
# CLKOUT2 is VCO / 4 (320.3125 MHz).
create_clock -name mem320 -period 3.12195 -waveform {0 1.560975} [get_nets {memory_clk}]

set_clock_groups -asynchronous -group [get_clocks {clk80}] -group [get_clocks {clk_x1}]
set_clock_groups -asynchronous -group [get_clocks {clk_x1}] -group [get_clocks {mem320}]
set_clock_groups -asynchronous -group [get_clocks {clk80}] -group [get_clocks {mem320}]

# The scanout holds the line address and bank until the synchronized
# completion returns. The AXI side captures them after two request FFs.
# Bound the bundled data to one AXI cycle (capture is at least two cycles
# after launch). There is no phase-related hold edge across these PLLs.
set_max_delay -from [get_regs {u_dvi_tx_top/gen_vram.scanout/request_addr_* u_dvi_tx_top/gen_vram.scanout/request_bank_*}] -to [get_regs {u_dvi_tx_top/gen_vram.scanout/araddr_* u_dvi_tx_top/gen_vram.scanout/bank_*}] 12.4878
set_false_path -hold -from [get_regs {u_dvi_tx_top/gen_vram.scanout/request_addr_* u_dvi_tx_top/gen_vram.scanout/request_bank_*}] -to [get_regs {u_dvi_tx_top/gen_vram.scanout/araddr_* u_dvi_tx_top/gen_vram.scanout/bank_*}]
# Line and frame-page handshakes each have a two-FF synchronizer in both directions.
# Time the interstage paths normally. Exempt only the four asynchronous D inputs.
set_false_path -to [get_pins {u_dvi_tx_top/gen_vram.scanout/request_sync_0_s0/D u_dvi_tx_top/gen_vram.scanout/completed_sync_0_s0/D u_dvi_tx_top/gen_vram.scanout/page_request_sync_0_s0/D u_dvi_tx_top/gen_vram.scanout/page_ack_sync_0_s0/D}]

# DDR PHY qualifies PLL lock through lock_syn[0:1] before its lock counter.
# Exclude only the reference-clock input to the first synchronizer D pin.
set_false_path -from [get_clocks {sys_clk}] -to [get_pins {u_ddr3/gw3_top/u_ddr_phy_top/ddr_sync/lock_syn_0_s0/D}]
