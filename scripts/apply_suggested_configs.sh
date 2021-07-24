#!/bin/bash

# This script sets the recommended/suggested configs by Hamad Al Marri
# run this inside the kernel directory

# General Setup
echo ./scripts/config --disable CONFIG_EXPERT
./scripts/config --disable CONFIG_EXPERT


#Note 1:
# CONFIG_NO_HZ_FULL requires you to add the boot
# parameter "nohz_full=" in your grup. For example,
# in case your machine has 4 CPUS, "nohz_full=1-3"
# makes all CPUs (except CPU0) adaptive ticks.  Without
# "nohz_full=1-3", no benfit of selecting
#
# Hamad Al Marri
#
#Notes 2:
# The adaptive tickless mode must be manually enabled in
# nohz_full= kernel parameter, and CPU0 should be excluded
# from the list. For example, if you have a 4-core CPU
# (w/o hyperthreading), you may use nohz_full=1-3 to enable
# adaptive tickless mode on all cores except CPU0. In addition,
# as mentioned https://linux.enea.com/4.0/documentation/html/book-enea-linux-realtime-guide/,
# if your CPU supports hyperthreading, both threads from the
# same physical core must enable/disable adaptive tickless mode
# at the same time. For example, if you have a 4-core CPU with
# 8 threads, you may use nohz_full=1-3,5-7 to enable adaptive
# tickess mode on all physical cores and their sibling threads
# except CPU0.
#
# Raymond K. Zhao
#
# Please see the discussions here:
# https://github.com/hamadmarri/cacule-cpu-scheduler/discussions/23#discussioncomment-711456
# https://github.com/hamadmarri/cacule-cpu-scheduler/discussions/32
#
#echo ./scripts/config --enable CONFIG_NO_HZ_FULL
#./scripts/config --enable CONFIG_NO_HZ_FULL

echo ./scripts/config --enable CONFIG_PREEMPT
./scripts/config --enable CONFIG_PREEMPT

echo ./scripts/config --enable CONFIG_SCHED_AUTOGROUP
./scripts/config --enable CONFIG_SCHED_AUTOGROUP

echo ./scripts/config --disable CONFIG_VIRT_CPU_ACCOUNTING_GEN
./scripts/config --disable CONFIG_VIRT_CPU_ACCOUNTING_GEN

echo ./scripts/config --enable CONFIG_TICK_CPU_ACCOUNTING
./scripts/config --enable CONFIG_TICK_CPU_ACCOUNTING

echo ./scripts/config --disable CONFIG_BSD_PROCESS_ACCT
./scripts/config --disable CONFIG_BSD_PROCESS_ACCT

echo ./scripts/config --disable CONFIG_TASK_XACCT
./scripts/config --disable CONFIG_TASK_XACCT

echo ./scripts/config --disable CONFIG_PSI
./scripts/config --disable CONFIG_PSI

echo ./scripts/config --disable CONFIG_MEMCG
./scripts/config --disable CONFIG_MEMCG

echo ./scripts/config --disable CONFIG_CGROUP_CPUACCT
./scripts/config --disable CONFIG_CGROUP_CPUACCT

echo ./scripts/config --disable CONFIG_CGROUP_DEBUG
./scripts/config --disable CONFIG_CGROUP_DEBUG

echo ./scripts/config --disable CONFIG_CHECKPOINT_RESTORE
./scripts/config --disable CONFIG_CHECKPOINT_RESTORE

echo ./scripts/config --disable CONFIG_SLAB_MERGE_DEFAULT
./scripts/config --disable CONFIG_SLAB_MERGE_DEFAULT

echo ./scripts/config --disable CONFIG_SLAB_FREELIST_HARDENED
./scripts/config --disable CONFIG_SLAB_FREELIST_HARDENED

echo ./scripts/config --disable CONFIG_SLUB_CPU_PARTIAL
./scripts/config --disable CONFIG_SLUB_CPU_PARTIAL

echo ./scripts/config --disable CONFIG_PROFILING
./scripts/config --disable CONFIG_PROFILING

# Processor type and features
echo ./scripts/config --disable CONFIG_RETPOLINE
./scripts/config --disable CONFIG_RETPOLINE

echo ./scripts/config --disable CONFIG_X86_5LEVEL
./scripts/config --disable CONFIG_X86_5LEVEL

echo ./scripts/config --disable CONFIG_KEXEC
./scripts/config --disable CONFIG_KEXEC

echo ./scripts/config --disable CONFIG_KEXEC_FILE
./scripts/config --disable CONFIG_KEXEC_FILE

echo ./scripts/config --disable CONFIG_CRASH_DUMP
./scripts/config --disable CONFIG_CRASH_DUMP

echo ./scripts/config --set-val CONFIG_NR_CPUS $(nproc)
./scripts/config --set-val CONFIG_NR_CPUS $(nproc)

# if you are not using this kernel as guest in a virtual machine,
# then disable CONFIG_HYPERVISOR_GUEST
#./scripts/config --disable CONFIG_HYPERVISOR_GUEST

# General architecture-dependent options
echo ./scripts/config --disable CONFIG_KPROBES
./scripts/config --disable CONFIG_KPROBES

# Kernel hacking
echo ./scripts/config --disable CONFIG_FTRACE
./scripts/config --disable CONFIG_FTRACE

echo ./scripts/config --disable CONFIG_DEBUG_KERNEL
./scripts/config --disable CONFIG_DEBUG_KERNEL

echo ./scripts/config --disable CONFIG_PAGE_EXTENSION
./scripts/config --disable CONFIG_PAGE_EXTENSION

echo ./scripts/config --set-val CONFIG_RCU_CPU_STALL_TIMEOUT 4
./scripts/config --set-val CONFIG_RCU_CPU_STALL_TIMEOUT 4

echo ./scripts/config --disable CONFIG_PRINTK_TIME
./scripts/config --disable CONFIG_PRINTK_TIME

echo ./scripts/config --disable CONFIG_DEBUG_INFO
./scripts/config --disable CONFIG_DEBUG_INFO

echo ./scripts/config --disable CONFIG_ENABLE_MUST_CHECK
./scripts/config --disable CONFIG_ENABLE_MUST_CHECK

echo ./scripts/config --disable CONFIG_STRIP_ASM_SYMS
./scripts/config --disable CONFIG_STRIP_ASM_SYMS

echo ./scripts/config --disable CONFIG_UNUSED_SYMBOLS
./scripts/config --disable CONFIG_UNUSED_SYMBOLS

echo ./scripts/config --disable CONFIG_DEBUG_FS
./scripts/config --disable CONFIG_DEBUG_FS

echo ./scripts/config --disable CONFIG_OPTIMIZE_INLINING
./scripts/config --disable CONFIG_OPTIMIZE_INLINING

echo ./scripts/config --disable CONFIG_DEBUG_SECTION_MISMATCH
./scripts/config --disable CONFIG_DEBUG_SECTION_MISMATCH

echo ./scripts/config --disable CONFIG_SECTION_MISMATCH_WARN_ONLY
./scripts/config --disable CONFIG_SECTION_MISMATCH_WARN_ONLY

echo ./scripts/config --disable CONFIG_STACK_VALIDATION
./scripts/config --disable CONFIG_STACK_VALIDATION

echo ./scripts/config --disable CONFIG_DEBUG_FORCE_WEAK_PER_CPU
./scripts/config --disable CONFIG_DEBUG_FORCE_WEAK_PER_CPU

echo ./scripts/config --disable CONFIG_MAGIC_SYSRQ
./scripts/config --disable CONFIG_MAGIC_SYSRQ

echo ./scripts/config --disable CONFIG_MAGIC_SYSRQ_SERIAL
./scripts/config --disable CONFIG_MAGIC_SYSRQ_SERIAL

echo ./scripts/config --disable CONFIG_PAGE_EXTENSION
./scripts/config --disable CONFIG_PAGE_EXTENSION

echo ./scripts/config --disable CONFIG_DEBUG_PAGEALLOC
./scripts/config --disable CONFIG_DEBUG_PAGEALLOC

echo ./scripts/config --disable CONFIG_PAGE_OWNER
./scripts/config --disable CONFIG_PAGE_OWNER

echo ./scripts/config --disable CONFIG_DEBUG_MEMORY_INIT
./scripts/config --disable CONFIG_DEBUG_MEMORY_INIT

echo ./scripts/config --disable CONFIG_HARDLOCKUP_DETECTOR
./scripts/config --disable CONFIG_HARDLOCKUP_DETECTOR

echo ./scripts/config --disable CONFIG_SOFTLOCKUP_DETECTOR
./scripts/config --disable CONFIG_SOFTLOCKUP_DETECTOR

echo ./scripts/config --disable CONFIG_DETECT_HUNG_TASK
./scripts/config --disable CONFIG_DETECT_HUNG_TASK

echo ./scripts/config --disable CONFIG_WQ_WATCHDOG
./scripts/config --disable CONFIG_WQ_WATCHDOG

echo ./scripts/config --set-val CONFIG_PANIC_TIMEOUT 10
./scripts/config --set-val CONFIG_PANIC_TIMEOUT 10

echo ./scripts/config --disable CONFIG_SCHED_DEBUG
./scripts/config --disable CONFIG_SCHED_DEBUG

echo ./scripts/config --disable CONFIG_SCHEDSTATS
./scripts/config --disable CONFIG_SCHEDSTATS

echo ./scripts/config --disable CONFIG_SCHED_STACK_END_CHECK
./scripts/config --disable CONFIG_SCHED_STACK_END_CHECK

echo ./scripts/config --disable CONFIG_STACKTRACE
./scripts/config --disable CONFIG_STACKTRACE

echo ./scripts/config --disable CONFIG_DEBUG_BUGVERBOSE
./scripts/config --disable CONFIG_DEBUG_BUGVERBOSE

echo ./scripts/config --set-val CONFIG_RCU_CPU_STALL_TIMEOUT 4
./scripts/config --set-val CONFIG_RCU_CPU_STALL_TIMEOUT 4

echo ./scripts/config --disable CONFIG_RCU_TRACE
./scripts/config --disable CONFIG_RCU_TRACE

echo ./scripts/config --disable CONFIG_FAULT_INJECTION
./scripts/config --disable CONFIG_FAULT_INJECTION

echo ./scripts/config --disable CONFIG_LATENCYTOP
./scripts/config --disable CONFIG_LATENCYTOP

echo ./scripts/config --disable CONFIG_PROVIDE_OHCI1394_DMA_INIT
./scripts/config --disable CONFIG_PROVIDE_OHCI1394_DMA_INIT

echo ./scripts/config --disable RUNTIME_TESTING_MENU
./scripts/config --disable RUNTIME_TESTING_MENU

echo ./scripts/config --disable CONFIG_MEMTEST
./scripts/config --disable CONFIG_MEMTEST

echo ./scripts/config --disable CONFIG_KGDB
./scripts/config --disable CONFIG_KGDB

echo ./scripts/config --disable CONFIG_EARLY_PRINTK
./scripts/config --disable CONFIG_EARLY_PRINTK

echo ./scripts/config --disable CONFIG_DOUBLEFAULT
./scripts/config --disable CONFIG_DOUBLEFAULT


echo "
Note 1:
 CONFIG_NO_HZ_FULL requires you to add the boot
 parameter \"nohz_full=\" in your grup. For example,
 in case your machine has 4 CPUS, \"nohz_full=1-3\"
 makes all CPUs (except CPU0) adaptive ticks.  Without
 \"nohz_full=1-3\", no benfit of selecting CONFIG_NO_HZ_FULL

 Hamad Al Marri

Notes 2:
 The adaptive tickless mode must be manually enabled in
 nohz_full= kernel parameter, and CPU0 should be excluded
 from the list. For example, if you have a 4-core CPU
 (w/o hyperthreading), you may use nohz_full=1-3 to enable
 adaptive tickless mode on all cores except CPU0. In addition,
 as mentioned https://linux.enea.com/4.0/documentation/html/book-enea-linux-realtime-guide/,
 if your CPU supports hyperthreading, both threads from the
 same physical core must enable/disable adaptive tickless mode
 at the same time. For example, if you have a 4-core CPU with
 8 threads, you may use nohz_full=1-3,5-7 to enable adaptive
 tickess mode on all physical cores and their sibling threads
 except CPU0.

 Raymond K. Zhao

 Please see the discussions here:
 https://github.com/hamadmarri/cacule-cpu-scheduler/discussions/23#discussioncomment-711456
 https://github.com/hamadmarri/cacule-cpu-scheduler/discussions/32
 "
