# PSC-ONE

# ===============================
# System clock (27MHz)
# ===============================
create_clock -name sys_clk -period 37.037 -waveform {0.000 18.518} [get_ports {sys_clk}]

# Match the PLL (27 MHz x 3) and LCD CLKDIV (divide by 4).
create_generated_clock -name cpu_clk -source [get_ports {sys_clk}] -multiply_by 3 [get_pins {m_PLL/rpll_inst/CLKOUT}]
create_generated_clock -name lcd_clk -source [get_pins {m_PLL/rpll_inst/CLKOUT}] -divide_by 4 [get_pins {u_soc/u_lcd/m_gowin_clk_div/clkdiv_inst/CLKOUT}]

# LCD 20.25 MHz -> CPU 81 MHz: exclude hold checks only.
set_false_path -hold -from [get_clocks {lcd_clk}] -to [get_clocks {cpu_clk}]

# Include the excluded hold paths in the timing report for verification.
report_exceptions -hold -from [get_clocks {lcd_clk}] -to [get_clocks {cpu_clk}] -max_paths 25
