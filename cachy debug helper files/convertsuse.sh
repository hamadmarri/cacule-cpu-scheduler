#!/bin/sh

make clean
make mrproper
cp .config.suse.less .config
touch .config
