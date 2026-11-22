# PSC-ONE
# Tang138K

# ===============================
# System clock (50MHz)
# ===============================
create_clock -name sys_clk -period 20.000 -waveform {0.000 10.000} [get_ports {sys_clk}]

# 80MHz
create_clock -name clk80 -period 12.500 -waveform {0 6.250} [get_nets {clock_100MHz}]
# 80MHz (DDR3 divided clock)
create_clock -name clk_x1 -period 12.500 -waveform {0 6.250} [get_pins {u_ddr3/gw3_top/u_ddr_phy_top/fclkdiv/CLKOUT}]
# 320MHz
create_clock -name mem320 -period 3.125 -waveform {0 1.5625} [get_nets {memory_clk}]

set_clock_groups -asynchronous -group [get_clocks {clk80}] -group [get_clocks {clk_x1}]
set_clock_groups -asynchronous -group [get_clocks {clk_x1}] -group [get_clocks {mem320}]
set_clock_groups -asynchronous -group [get_clocks {clk80}] -group [get_clocks {mem320}]