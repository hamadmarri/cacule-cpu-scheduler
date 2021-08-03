![logo](cacule_logo_gh.png)

The CacULE CPU scheduler is a CFS patchset that is based on interactivity score mechanism.
The interactivity score is inspired by the ULE scheduler (FreeBSD
scheduler). The goal of this patch is to enhance system responsiveness/latency.


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

### sched_max_lifetime_ms
Instead of calculating a task IS value for infinite life time, we use
`sched_max_lifetime_ms` which is 22s by default. Task's `cacule_lifetime` and
`vruntime` shrink whenever a task life time exceeds 30s. Therefore, the rate of change of IS
for old and new tasks is normalized. The value `sched_max_lifetime` can be
changed at run time by the following sysctl command:
```
sysctl kernel.sched_max_lifetime_ms=60000
```
The value is in milliseconds, the above command changes `sched_max_lifetime`
from 22s to 60s.

In the first round, when the task's life time became > 22s, the `cacule_start_time`
get reset to be (`current_time - 11s`), then, the task will keep resetting
every 15s.

### Starve and Cache Scores
See [here](https://github.com/hamadmarri/cacule-cpu-scheduler/discussions/43).

### sched_cacule_yield
See [here](https://github.com/hamadmarri/cacule-cpu-scheduler/issues/35).

## Complexity
* The complexity of Enqueue a task is O(1).
* The complexity of Dequeue a task is O(1).
* The complexity of pick the next task is in O(n).

n is the number of tasks in a runqueue (each CPU has its own runqueue).

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
updates (cfs and se updates loads) are removed. The RDB balancer follows CFS
paradigm in which RDB balancing happen at the same points CFS does. RDB balancing happens
in three functions: `newidle_balance`, `idle_balance`, and `active_balance`. The `newidle_balance`
is called exactly at the same time as CFS did (when pick next task fails to find any task to run).
The RDB `newidle_balance` pulls one task that is the highest HRRN/IS from any CPU. The RDB `idle_balance`
is called in `trigger_load_balance` when CPU is idle, it does the same as `newidle_balance` but with 
slight changes since `newidle_balance` is a special case. The RDB `active_balance` checks if the current
(NORMAL) runqueue has one task, if so, it pulls the highest of the highest HRRN/IS among all other CPUS. If the
runqueue has more than one task, then it pulls any highest HRRN/IS (same as idle does). A CPU cannot pull a task
from another CPU that has fewer tasks (when pull any). For the all three balancing
`newidle_balance`, `idle_balance`, and `active_balance`, the cpu first tries to pull from a CPU that shares the same
cache (`cpus_share_cache`). If can't pull any then it tries to pull from any CPU even though they are not in the same core.
Only when pulling the highest of the highest HRRN/IS (i.e. `active_balance` when CPU has one task), there is no check for
shared cache.

## How to install
The following installation links are not only for easier installation,
but they are also right configured for best CacULE experience.

### Debian/Ubuntu
[XanMod](https://xanmod.org/)

### Arch
[AUR - ptr1337](https://aur.archlinux.org/packages/?K=ptr1337&SeB=m)

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
For a helper script to auto config use [this](https://github.com/hamadmarri/cacule-cpu-scheduler/blob/master/scripts/apply_suggested_configs.sh)

## Benchmarks
The tests are ran 11 times and best 10 tests are picked.
Between each test, a sleep for 2 minutes such the following script:

```
 for i in (seq 1 11); sleep 2m; <test command>; end
```

For the following tests, CacULE is patched on Ubuntu linux-lowlatency kernel source.

[Benchmarks Data](https://github.com/hamadmarri/cacule-cpu-scheduler/tree/master/helper%20docs%20for%20kernel%20dev/benchmarking)

### Stress-ng test
![Benchmarks Data](./helper&#32;docs&#32;for&#32;kernel&#32;dev/benchmarking/stress-ng/cacule-vs-lowlatency-bogo-ops.png)
![Benchmarks Data](./helper&#32;docs&#32;for&#32;kernel&#32;dev/benchmarking/stress-ng/cacule-vs-lowlatency-bogo-ops-per-sec.png)

### Latency test
Please see the scripts for responsiveness/latency tests:
[os-scheduler-responsiveness-test](https://github.com/hamadmarri/os-scheduler-responsiveness-test)

![Benchmarks Data](./helper&#32;docs&#32;for&#32;kernel&#32;dev/benchmarking/responsive&#32;script/cacule-vs-lowlatency-python.png)
![Benchmarks Data](./helper&#32;docs&#32;for&#32;kernel&#32;dev/benchmarking/responsive&#32;script/cacule-vs-lowlatency-go.png)



## Blind Tests
I made comparison between cfs and cachy on xanmod, for blind test

* test1: https://youtu.be/DilwWlNbExg?t=14
* test2: https://youtu.be/1S3OxLrcbGY?t=14
* test3: https://youtu.be/HqaNGhThihA?t=38

to reveal the which is which go back to time 0s on the video and see `uname -r` output

Note: In one of the tests, the recorder seems to be freezes and lagging, I repeated this test twice, while testing system is not pausing but the recorder maybe freezing or lagging while recording.


## Special Thanks to
1. Alexandre Frade (the maintainer of [xanmod](https://github.com/xanmod))
2. Raymond K. Zhao ([github](https://github.com/raykzhao))
3. Peter Jung ([github](https://github.com/ptr1337))
4. JohnyPeaN ([github](https://github.com/JohnyPeaN))

## Contacts
Telegram: https://t.me/cacule_sched

## Discussions
https://github.com/hamadmarri/cacule-cpu-scheduler/discussions
