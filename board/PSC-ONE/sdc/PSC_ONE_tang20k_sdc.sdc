# PSC-ONE

# ===============================
# System clock (27MHz)
# ===============================
create_clock -name sys_clk -period 37.037 -waveform {0.000 18.518} [get_ports {sys_clk}]
