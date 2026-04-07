# ============================================================================
# pins.xdc - AX7015B (XC7Z015) pin constraints
# ============================================================================

# ------ PL 50MHz oscillator (core board X2, BANK13 MRCC) ------
set_property PACKAGE_PIN Y14 [get_ports {pl_clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {pl_clk}]
create_clock -period 20.000 -name pl_clk [get_ports {pl_clk}]

# ------ Baseboard PL LEDs (BANK35, active low) ------
set_property PACKAGE_PIN A5 [get_ports {led[0]}]
set_property PACKAGE_PIN A7 [get_ports {led[1]}]
set_property PACKAGE_PIN A6 [get_ports {led[2]}]
set_property PACKAGE_PIN B8 [get_ports {led[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
