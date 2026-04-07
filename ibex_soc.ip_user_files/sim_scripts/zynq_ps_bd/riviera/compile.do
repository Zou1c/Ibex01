transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xilinx_vip
vlib riviera/axi_infrastructure_v1_1_0
vlib riviera/axi_vip_v1_1_19
vlib riviera/processing_system7_vip_v1_0_21
vlib riviera/xil_defaultlib

vmap xilinx_vip riviera/xilinx_vip
vmap axi_infrastructure_v1_1_0 riviera/axi_infrastructure_v1_1_0
vmap axi_vip_v1_1_19 riviera/axi_vip_v1_1_19
vmap processing_system7_vip_v1_0_21 riviera/processing_system7_vip_v1_0_21
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xilinx_vip  -incr "+incdir+E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib \
"E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
"E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
"E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work axi_infrastructure_v1_1_0  -incr -v2k5 "+incdir+../../../../ibex_soc.gen/sources_1/bd/zynq_ps_bd/ipshared/ec67/hdl" "+incdir+../../../../ibex_soc.gen/sources_1/bd/zynq_ps_bd/ipshared/86fe/hdl" "+incdir+E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib \
"../../../../ibex_soc.gen/sources_1/bd/zynq_ps_bd/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_vip_v1_1_19  -incr "+incdir+../../../../ibex_soc.gen/sources_1/bd/zynq_ps_bd/ipshared/ec67/hdl" "+incdir+../../../../ibex_soc.gen/sources_1/bd/zynq_ps_bd/ipshared/86fe/hdl" "+incdir+E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib \
"../../../../ibex_soc.gen/sources_1/bd/zynq_ps_bd/ipshared/8c45/hdl/axi_vip_v1_1_vl_rfs.sv" \

vlog -work processing_system7_vip_v1_0_21  -incr "+incdir+../../../../ibex_soc.gen/sources_1/bd/zynq_ps_bd/ipshared/ec67/hdl" "+incdir+../../../../ibex_soc.gen/sources_1/bd/zynq_ps_bd/ipshared/86fe/hdl" "+incdir+E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib \
"../../../../ibex_soc.gen/sources_1/bd/zynq_ps_bd/ipshared/86fe/hdl/processing_system7_vip_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../ibex_soc.gen/sources_1/bd/zynq_ps_bd/ipshared/ec67/hdl" "+incdir+../../../../ibex_soc.gen/sources_1/bd/zynq_ps_bd/ipshared/86fe/hdl" "+incdir+E:/vivado24.2/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib \
"../../../bd/zynq_ps_bd/ip/zynq_ps_bd_processing_system7_0_0/sim/zynq_ps_bd_processing_system7_0_0.v" \
"../../../bd/zynq_ps_bd/sim/zynq_ps_bd.v" \

vlog -work xil_defaultlib \
"glbl.v"

