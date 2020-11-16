#! /bin/bash

clear && make CC="ccache gcc" -j6 && qemu-system-x86_64 -kernel arch/x86/boot/bzImage \
-boot c -m 2049M -hda ../buildroot/output/images/rootfs.ext4 \
-append "root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr" \
-serial stdio -display none -smp $1
