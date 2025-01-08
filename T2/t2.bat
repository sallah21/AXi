echo off
del -f t2
del -f t2.vcd

iverilog -Wall -s AXIM_TO_HDMI_tb -o t2 axi_s_bfm.v axim_to_hdmi.v axim_to_hdmi_tb.v
if ERRORLEVEL 1 goto ON_ERROR

vvp t2
if ERRORLEVEL 1 goto ON_ERROR

gtkwave t2.gtkw

goto SIM_EXIT

:ON_ERROR
echo Terminating on error.

:SIM_EXIT

