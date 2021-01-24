# CacULE CPU Scheduler

CacULE is a new version of Cachy. The CacULE CPU scheduler is based on interactivity score mechanism.
The interactivity score is inspired by the ULE scheduler (FreeBSD
scheduler).


## About CacULE Scheduler
* Each CPU has its own runqueue.
* NORMAL runqueue is a linked list of sched_entities (instead of RB-Tree).
* RT and other runqueues are just the same as the CFS's.
* Wake up tasks preempt currently running tasks if its interactivity score value is higher.


## The CacULE Interactivity Score
The interactivity score is inspired by the ULE scheduler (FreeBSD scheduler).
For more information see: https://web.cs.ucdavis.edu/~roper/ecs150/ULE.pdf
CacULE doesn't replace CFS with ULE, it only changes the CFS' pick next task
mechanism to ULE's interactivity score mechanism for picking next task to run.

### sched_interactivity_factor
Sets the value *m* for interactivity score calculations. See Figure 1 in
https://web.cs.ucdavis.edu/~roper/ecs150/ULE.pdf
The default value of in CacULE is 32768 which means that the Maximum Interactive
Score is 65536 (since m = Maximum Interactive Score / 2).
You can tune sched_interactivity_factor with sysctl command:

	sysctl kernel.sched_interactivity_factor=50

This command changes the sched_interactivity_factor from 32768 to 50.



## Complexity
The complexity of Enqueue and Dequeue a task is O(1).

The complexity of pick the next task is in O(n), where n is the number of tasks
in a runqueue (each CPU has its own runqueue).

Note: O(n) sounds scary, but usually for a machine with 4 CPUS where it is used
for desktop or mobile jobs, the maximum number of runnable tasks might not
exceeds 10 (at the pick next run time) - the idle tasks are excluded since they
are dequeued when sleeping and enqueued when they wake up.

## Tasks' Priorities
The priorities are applied as the followings:
The `vruntime` is used in Interactivity Score as the sum of execution time. The `vruntime` is adjusted by CFS based on tasks priorities.
The same code from CFS is used in CacULE. The `vruntime` is equal to `sum_exec_runtime` if a task has nice value of 0 (normal priority).
The `vruntime` will be lower than `sum_exec_runtime` for higher tasks priorities, which make Interactivity Score thinks that those task didn't run for much time (compared to
their actual run time).
The `vruntime` will be higher than `sum_exec_runtime` for lower tasks priorities, which make Interactivity Score thinks that those task ran for much time (compared to
their actual run time).
So priorities are already taken in the acount by using `vruntime` in the Interactivity Score equation instead of actual `sum_exec_runtime`.


## Response Driven Balancer (RDB)
This is an experimental load balancer for Cachy/CacULE. It is a lightweight
load balancer which is a replacement of CFS load balancer. It migrates
tasks based on their HRRN/Interactivity Scores (IS). Most of CFS load balancing-related
updates (cfs and se updates weights) are removed. The RDB balancer follows CFS
paradigm in which RDB balancing happen at the same points CFS does. RDB balancing happens
in three functions: `newidle_balance`, `idle_balance`, and `active_balance`. The `newidle_balance`
is called exactly at the same time as CFS did (when pick next task fails to find any task to run).
The RDB `newidle_balance` pulls one task that is the highest HRRN/IS from any CPU. The RDB `idle_balance`
is called in `trigger_load_balance` when CPU is idle, it does the same as `newidle_balance` but with 
slight changes since `newidle_balance` is special case. The RDB `active_balance` checks if the current
(NORMAL) runqueue has one task, if so, it pulls the highest of the highest HRRN/IS among all other CPUS. If the
runqueue has more than one task, then it pulls any highest HRRN/IS (same as idle does). For the all three balancing
`newidle_balance`, `idle_balance`, and `active_balance`, the cpu first tries to pull from a CPU that shares the same
cache (`cpus_share_cache`). If can't pull any then it tries to pull from any CPU even though they are not in the same core.
Only when pulling the highest of the highest HRRN/IS (i.e. `active_balance` when CPU has one task), there is no check for
shared cache.

Since `trigger_load_balance` is called for every tick, there is a guard time to prevent frequent tasks migration to reduce
runqueues locking and to reduce unnecessary tasks migrations. The time is `3ms` after each `active_balance`. This time
guard is specifically for HZ=500,1000. We don't want to run balancing every 2ms or 1ms to prevent regression in performance.
Here is how frequent the `trigger_load_balance` would run balancer with given HZ values:
* HZ=100 runs every ~10ms
* HZ=250 runs every ~4ms
* HZ=300 runs every ~3ms
* HZ=500 runs every ~4ms
* HZ=1000 runs every ~3ms


## Patched Kernel Tree
1. Go to [kernel tree repository](https://github.com/hamadmarri/linux) 
2. Select a tag version that starts with `cachy / cacule` (i.e `cachy-5.8-r6`)
3. Download and compile


## How to apply the patch
1. Download the linux kernel (https://www.kernel.org/) that is same version as the patch
 (i.e if patch file name is cachy-5.7.6.patch, then download https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.7.6.tar.xz)
2. Unzip linux kernel
3. Download cachy patch file and place it inside the just unzipped linux kernel folder
4. cd linux-(version)
5. patch -p1 < cachy-5.7.6.patch (or git -am)
6. To build the kernel you need to follow linux build kernel documentation and tutorials.


To confirm that CacULE is currently running:
```

dmesg | grep -i "cacule cpu"
[    0.122999] CacULE CPU scheduler v5.9 by Hamad Al Marri.

```

## Suggested Configs
* SCHED_AUTOGROUP=n
* CGROUP_SCHED=n
* FAIR_GROUP_SCHED=n
* CFS_BANDWIDTH=n
* CONFIG_BSD_PROCESS_ACCT=n
* CONFIG_TASK_XACCT=n
* CONFIG_PSI=n
* CONFIG_AUDIT=n
* Cputime accounting (Simple tick based cputime accounting)  --->
	* CONFIG_VIRT_CPU_ACCOUNTING_GEN=n
	* CONFIG_TICK_CPU_ACCOUNTING=y

* CONFIG_CGROUPS
	* CONFIG_MEMCG=n
	* CONFIG_CGROUP_CPUACCT=n
	* CONFIG_CGROUP_DEBUG=n

* CONFIG_CHECKPOINT_RESTORE=n
* CONFIG_EXPERT=n
* CONFIG_SLAB_MERGE_DEFAULT=n
* CONFIG_SLAB_FREELIST_HARDENED=n
* CONFIG_SLUB_CPU_PARTIAL=n
* CONFIG_PROFILING=n

### Processor type and features 
* CONFIG_RETPOLINE=n
* CONFIG_X86_5LEVEL=n
* Timer frequency: I prefere 250 HZ
* CONFIG_KEXEC=n
* CONFIG_KEXEC_FILE=n
* CONFIG_CRASH_DUMP=n

if you are not using this kernel as guest in 
a virtual machine, then disable `CONFIG_HYPERVISOR_GUEST`

#### cpu type
I have "Intel(R) Core(TM) i7-4600U CPU @ 2.10GHz"
therefore I used CONFIG_MCORE2 (Processor family (Core 2/newer Xeon))

may need to include 
-march=corei7-avx flag
KCFLAGS="-O2 -march=corei7-avx" KCPPFLAGS="-O2 -march=corei7-avx"

CONFIG_NR_CPUS = 4 #as I have 4 cpus

### power
* Default CPUFreq governor (performance)
* CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y
* CONFIG_CPU_FREQ_GOV_PERFORMANCE=y
* CONFIG_CPU_FREQ_GOV_ONDEMAND=n

### General architecture-dependent options
* CONFIG_KPROBES=n
* CONFIG_STACKPROTECTOR=n
* CONFIG_VMAP_STACK=n

### Security
* CONFIG_SECURITY=n
* CONFIG_HARDENED_USERCOPY=n

### Kernel hacking
* CONFIG_PAGE_EXTENSION=n
* Disable all except
	* CONFIG_DYNAMIC_DEBUG=y
	* CONFIG_STRICT_DEVMEM=y
	* CONFIG_IO_STRICT_DEVMEM=y
* CONFIG_RCU_CPU_STALL_TIMEOUT=4

## Blind Tests
I made comparison between cfs and cachy on xanmod, for blind test

* test1: https://youtu.be/DilwWlNbExg?t=14
* test2: https://youtu.be/1S3OxLrcbGY?t=14
* test3: https://youtu.be/HqaNGhThihA?t=38

to reveal the which is which go back to time 0s on the video and see `uname -r` output

Note: In one of the tests, the recorder seems to be freezes and lagging, I repeated this test twice, while testing system is not pausing but the recorder maybe freezing or lagging while recording.


## Special Thanks to
1. Alexandre Frade (the maintainer of [xanmod](https://github.com/xanmod))
2. Raymond K. Zhao (https://github.com/raykzhao)

## Contacts
Telegram: https://t.me/cacule_sched

## Donate
* BTC: 16ZZtjbWGX8HDpcyi7is1EigkTrFnfRKy8
* Paypal: https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=8F7F4D8BKR8XC

