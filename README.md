![cachy-logo](./cachy-logo.png)

Cachy-sched is a linux scheduler that is based on Highest Response Ratio Next (HRRN) policy.

## About Cachy Scheduler
* Each CPU has its own runqueue.
* NORMAL runqueue is a linked list of sched_entities (instead of RB-Tree).
* RT and other runqueues are just the same as the CFS's.
* A task gets preempted in every tick if any task has higher HRRN. If the clock ticks in 250HZ (i.e. `CONFIG_HZ_250=y`) then a task
runs for 4 milliseconds and then got preempted if there are other tasks in the runqueue and if any task has higher HRRN.
* Wake up tasks preempt currently running tasks if its HRRN value is higher.
* This scheduler is designed for desktop usage since it is about responsiveness.
* Cachy might be good for mobiles or Android since it has high responsiveness, but it needs to be integrated to
Android, I don't think the current version it is ready to go without some tweeking and adapting to Android hacks.


## Patched Kernel Tree
1. Go to [kernel tree repository](https://github.com/hamadmarri/linux) 
2. Select a tag version that starts with `cachy` (i.e `cachy-5.8-r6`)
3. Download and compile


## How to apply the patch
1. Download the linux kernel (https://www.kernel.org/) that is same version as the patch (i.e if patch file name is cachy-5.7.6.patch, then download https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.7.6.tar.xz)
2. Unzip linux kernel
3. Download cachy patch file and place it inside the just unzipped linux kernel folder
4. cd linux-(version)
5. patch -p1 < cachy-5.7.6.patch (or git -am)
6. To build the kernel you need to follow linux build kernel documentation and tutorials.


To confirm that Cachy is currently running:
```

dmesg | grep -i "cachy cpu"
[    0.059697] Cachy CPU scheduler v5.9 by Hamad Al Marri.

```

## Special Thanks to
1. Alexandre Frade (the maintainer of [xanmod](https://github.com/xanmod))


## Complexity
* The complexity of Enqueue a task is `O(n)`.
* The complexity of Dequeue a task is `O(1)`.
* The complexity of pick the next task is in `O(1)`, where 
`n` is the number of tasks in a runqueue (each CPU has its own runqueue).

Note: `O(n)` sounds scary, but usually for a machine with 4 CPUS where it is used for
desktop or mobile jobs, the maximum number of runnable tasks might
not exceeds 10 (at the pick next run time) - the idle tasks are excluded since they are dequeued when sleeping 
and enqueued when they wake up.

## Highest Response Ratio Next (HRRN) policy
Cachy is based in Highest Response Ratio Next (HRRN) policy with some modifications.
HRRN is a scheduling policy in which the process
that has the highest response ratio will run next. Each process
has a response ratio value `R = (w_t + s_t) / s_t` where `w_t` is
the process waiting time, and `s_t` is the process running
time. If two process has similar running times, the
process that has been waiting longer will run first. HRRN aims
to prevent starvation since it strives the waiting time for processes,
and also it increases the response time.


If two processes have the same `R` after integer rounding, the division remainder is compared.

Highest response ratio next (HRRN) scheduling is a non-preemptive discipline. It was developed by Brinch Hansen as modification of shortest job next (SJN) to mitigate the problem of process starvation [wikipedia](https://en.wikipedia.org/wiki/Highest_response_ratio_next). The original HRRN is non-preemptive meaning that a task runs until it finishes. This nature is not
good for interactive systems. Applying original HRRN with preemptive modifications requires one change. Native HRRN can work great for short amount of time lets say (< 60 minutes) until some
tasks gets too old and new tasks created, then the imbalance happens. Assume one task `T1` (Xorg) is running and waiting for users inputs.
This task will have high HRRN because it sleeps more than it runs, however, after a long time (say 60 minuets = 3600000000000ns) the life
time of `T1` is 3600000000000ns lets assume the sum of execution time is 50% = 1800000000000ns. The HRRN = 3600000000000 / 1800000000000 
= 2. If `T1` runs for 4ms, the rate of change on HRRN is too low: HRRN = 3600000000000 / 1800004000000 = 1.999995556

Also, if `T1` waited for 1s HRRN = 3601000000000 / 1800004000000 = 2.00055111, the rate of change is low too. Both situations are bad, because:
1. A new task `T2` will have higher HRRN when it starts, thus it will be picked instead of `T1`
2. The rate of change of `T2` compared to `T1` is higher.

This situation is not good for infinite-life processes such as Xorg and desktop related threads. Those task must run ASAP when they
wake up, because they are related to responsiveness and Interactivity.

Therefore, the original HRRN needs some modifications.

#### HRRN maximum life time
Instead of calculating a task HRRN value for infinite life time, we proposed `hrrn_max_lifetime` which is 20s by default. A task's
`hrrn_start_time` and `hrrn_sum_exec_runtime` reset every 20s. Therefore, the rate of change of HRRN for old and new tasks is
normalized. The value `hrrn_max_lifetime` can be changed at run time by the following sysctl command:

```
sudo sysctl kernel.sched_hrrn_max_lifetime_ms=60000
```

The value is in milliseconds, the above command changes `hrrn_max_lifetime` from 20s to 60s.


## Priorities
The priorities are applied as the followings:
The `vruntime` is used in HRRN as the sum of execution time. The `vruntime` is adjusted by CFS based on tasks priorities.
The same code fro CFS is used in Cachy. The `vruntime` is equal to `sum_exec_runtime` if a task has nice value of 0 (normal priority).
The `vruntime` will be lower than `sum_exec_runtime` for higher tasks priorities, which make HRRN thinks that those task didn't run for much time (compared to
their actual run time).
The `vruntime` will be higher than `sum_exec_runtime` for lower tasks priorities, which make HRRN thinks that those task ran for much time (compared to
their actual run time).
So priorities are already taken in the acount by using `vruntime` in the HRRN equation instead of actual `sum_exec_runtime`.


## Tests and Benchmarks

### Interactivity and Responsiveness while compiling shaders
#### Cachy compared with MUQSS
[MUQSS](https://www.youtube.com/watch?v=B-6MVWONOuc)
[Cachy](https://www.youtube.com/watch?v=jt1xl3wtZ0s)


## Phoronix Test Suite
https://openbenchmarking.org/result/2007301-NI-CACHYVSCF60


## Blind Tests
I made comparison between cfs and cachy on xanmod, for blind test

* test1: https://youtu.be/DilwWlNbExg?t=14
* test2: https://youtu.be/1S3OxLrcbGY?t=14
* test3: https://youtu.be/HqaNGhThihA?t=38

to reveal the which is which go back to time 0s on the video and see `uname -r` output

Note: In one of the tests, the recorder seems to be freezes and lagging, I repeated this test twice, while testing system is not pausing but the recorder maybe freezing or lagging while recording.


## Contacts
Telegram: https://t.me/cachy_sched
