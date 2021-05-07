#!/bin/sh

make clean
make mrproper
cp .config.qemu .config
touch .config
