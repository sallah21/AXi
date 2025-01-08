echo off
del -f t1
del -f ov76_to_axim.vcd

iverilog -Wall -s OV76_TO_AXIM_tb -o t1 ov76_bhv.v ov76_to_axim.v ov76_to_axim_tb.v
if ERRORLEVEL 1 goto ON_ERROR

vvp t1
if ERRORLEVEL 1 goto ON_ERROR

gtkwave t1.gtkw

goto SIM_EXIT

:ON_ERROR
echo Terminating on error.

:SIM_EXIT

