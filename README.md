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
`sched_max_lifetime_ms` which is 30s by default. Task's `cacule_lifetime` and
`vruntime` shrink whenever a task life time exceeds 30s. Therefore, the rate of change of IS
for old and new tasks is normalized. The value `sched_max_lifetime` can be
changed at run time by the following sysctl command:
```
sysctl kernel.sched_max_lifetime_ms=60000
```
The value is in milliseconds, the above command changes `sched_max_lifetime`
from 30s to 60s.

In the first round, when the task's life time became > 30s, the `cacule_start_time`
get reset to be (`current_time - 15s`), then, the task will keep resetting
every 15s. The reset method of the vruntime preserves the same IS ratio (roughly)
by the following:
```
// multiply old life time by 8 for more precision
old_IS_x8 = old_life_time / ((vruntime / 8) + 1)

// reset vruntime based on old IS ratio
vruntime = (new_life_time * 8) / old_IS_x8;
```

### sched_harsh_mode_enabled
Another sysctl command is `sched_harsh_mode_enabled`

The default value of `sched_harsh_mode_enabled` is 0 means disabled.
You can set it to 1 to enable harsh mode.

Note: harsh mode is good when in normal use of the system
(i.e. no background heavy work) if you compile while harsh mode enabled,
you might have mini freezes.
Sometimes it is usefule to enable harsh mode when you have a single task for
example gaming or just browsing. The only time you don't want harsh mode
is when you have a background heavy load.

Also note that some 3rd parties enables harsh mode by default. To check:

```
$ sudo sysctl kernel.sched_harsh_mode_enabled
kernel.sched_harsh_mode_enabled = 1
```

To disable harsh mode

```
# temporarily
sudo sysctl kernel.sched_harsh_mode_enabled=0

# permanently
sudo sysctl -w kernel.sched_harsh_mode_enabled=0 | sudo tee -a /etc/sysctl.conf
```

## Complexity
* The complexity of Enqueue a task is O(n).
* The complexity of Dequeue a task is O(1).
* The complexity of pick the next task is in O(1).

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
For a helper script to auto config use this https://github.com/hamadmarri/cacule-cpu-scheduler/blob/master/cachy%20debug%20helper%20files/apply_suggested_configs.sh

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
2. Raymond K. Zhao (https://github.com/raykzhao)
3. Peter Jung ([github](https://github.com/ptr1337))


## Contacts
Telegram: https://t.me/cacule_sched

## Discussions
https://github.com/hamadmarri/cacule-cpu-scheduler/discussions

## Donate
* BTC: 16ZZtjbWGX8HDpcyi7is1EigkTrFnfRKy8
* Paypal: https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=8F7F4D8BKR8XC
* Or you can do some monero mining on my behalf (using CPU is an option):
	* Download https://github.com/fireice-uk/xmr-stak/releases/tag/1.0.5-rx, extract and run `./xmr-stak-rx`
	* currency: monero
	* pool address: pool.minexmr.com:4444
	* wallet address: 41f2tHhZV4V4ef9rFiq3AE7iRkwrNYXSjTNJtt9A1P74KrQXhk2o1PbP4GgtM5vi8adfL8pxWyUre4AZSQxmbPRTLVMLmSJ

