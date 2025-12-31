set_property IOSTANDARD LVCMOS25 [get_ports i_clk]
set_property PACKAGE_PIN Y9 [get_ports i_clk]


set_property -dict {PACKAGE_PIN F22 IOSTANDARD LVCMOS25} [get_ports {i_rst}]
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS25} [get_ports {i_sw}]
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS25} [get_ports {i_up_button}]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS25} [get_ports {i_down_button}]  
set_property -dict {PACKAGE_PIN T22 IOSTANDARD LVCMOS25} [get_ports {o_State}] 

