#!/bin/bash

rm -f t2
rm -f axim_to_hdmi.vcd
clear 
iverilog -Wall -s AXIM_TO_HDMI_tb -o t2 axi_s_bfm.v axim_to_hdmi.v axim_to_hdmi_tb.v

if [ $? -eq 1 ]; then
    echo Source compilation failure
    exit 1
fi

vvp t2

if [ $? -ne 0 ]; then
    echo Running simulation failure
    exit 1
fi

gtkwave t2.gtkw

if [$? -ne 0]; then
    echo GTKWave failure
    exit 1
fi

