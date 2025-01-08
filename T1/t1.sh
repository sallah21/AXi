#!/bin/bash

rm -f t1
rm -f ov76_to_axim.vcd

iverilog -Wall -s OV76_TO_AXIM_tb -o t1 axi_s_bfm.v ov76_bhv.v ov76_to_axim.v ov76_to_axim_tb.v

if [ $? -eq 1 ]; then
    echo Source compilation failure
    exit 1
fi

vvp t1

if [ $? -ne 0 ]; then
    echo Running simulation failure
    exit 1
fi

gtkwave t1.gtkw

if [$? -ne 0]; then
    echo GTKWave failure
    exit 1
fi

