#!/bin/sh

cd kernel/
echo "kernel/"
global --color $@

cd ../include/linux/
echo "include/linux/"
global --color $@

cd ../../mm
echo "mm/"
global --color $@
