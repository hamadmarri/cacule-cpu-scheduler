# Cachy-sched

Cachy-sched is a linux scheduler that utilizes CPU cache
and it is based on Highest Response Ratio Next (HRRN) policy.

## About Cachy Scheduler
* All balancing code is removed. There is no periodic balancing nor idle CPU balancing. Once a task is
assigned to a CPU, it sticks with it until it exits. The reason is to utilize the CPU cache of tasks.
* No grouping for tasks, `FAIR_GROUP_SCHED` must be disabled.
* No support for `NUMA`, `NUMA` must be disabled.
* Each CPU has its own runqueue.
* NORMAL runqueue is a linked list of sched_entities (instead of RB-Tree).
* RT and other runqueues are just the same as the CFS's.
* A task gets preempted in every tick. If the clock ticks in 250HZ (i.e. `CONFIG_HZ_250=y`) then a task
runs for 4 milliseconds and then got preempted if there are other tasks in the runqueue.
* Wake up tasks preempt currently running tasks.
* This scheduler is designed for desktop and mobile usage since it is about responsiveness. It may be not bad for servers.

## How to apply the patch
* Download the linux kernel (https://www.kernel.org/) that is same version as the patch (i.e if patch file name is cachy-5.7.6.patch, then download https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.7.6.tar.xz)
* Unzip linux kernel
* Download cachy patch file and place it inside the just unzipped linux kernel folder
* cd linux-(version)
* patch -p1 < cachy-5.7.6.patch
* **`make menuconfig` make sure to disable `FAIR_GROUP_SCHED` and `NUMA`**
* To build the kernel you need to follow linux build kernel tutorials.

## Complexity
* The complexity of Enqueue and Dequeue a task is `O(1)`.
* The complexity of pick the next task is in `O(n)`, where 
`n` is the number of tasks in a runqueue (each CPU has its own runqueue).

Note: `O(n)` sounds scary, but usually for a machine with 4 CPUS where it is used for
desktop or mobile jobs, the maximum number of runnable tasks might
not exceeds 10 (at the pick next run time) - the idle tasks are excluded since they are dequeued when sleeping 
and enqueued when they wake up. The Cachy scheduler latency for a high number of CPUs (4+)
is usually less than the CFS's since no tree balancing nor tasks balancing are required - 
again for desktop and mobile usage.

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
    
## Tests and Benchmarks

### Phoronix Test Suite
[Cachy vs CFS](https://openbenchmarking.org/result/2007245-NI-CACHYVSCF85)

### stress-ng test with perf stat
The below results are the best results of both Cachy and CFS out of 20 runs.
Sometimes CFS is faster but usually Cachy is faster in this test.

#### Cachy
```
uname -a
Linux suse 5.7.6-cachy-1-default #1 SMP Fri Jul 24 18:00:47 AEST 2020 x86_64 x86_64 x86_64 GNU/Linux

sudo perf stat -e context-switches,cycles,instructions,L1-dcache-loads,L1-dcache-load-misses,LLC-loads,LLC-load-misses,branches,branch-misses -a -B stress-ng --cpu 4 -t 2m --cpu-method all --metrics-brief

stress-ng: info:  [12260] dispatching hogs: 4 cpu
stress-ng: info:  [12260] successful run completed in 120.06s (2 mins, 0.06 secs)
stress-ng: info:  [12260] stressor       bogo ops real time  usr time  sys time   bogo ops/s   bogo ops/s
stress-ng: info:  [12260]                           (secs)    (secs)    (secs)   (real time) (usr+sys time)
stress-ng: info:  [12260] cpu               87526    120.03    478.67      0.02       729.23       182.84

 Performance counter stats for 'system wide':

            36,459      context-switches                                            
 1,248,551,472,864      cycles                                                        (62.50%)
 1,337,471,008,174      instructions              #    1.07  insn per cycle           (75.00%)
   133,423,744,677      L1-dcache-loads                                               (65.93%)
    12,176,291,467      L1-dcache-load-misses     #    9.13% of all L1-dcache hits    (53.11%)
     2,969,067,073      LLC-loads                                                     (34.21%)
         8,452,809      LLC-load-misses           #    0.28% of all LL-cache hits     (37.50%)
   194,805,161,497      branches                                                      (49.99%)
     1,546,718,372      branch-misses             #    0.79% of all branches          (50.00%)

     120.060440580 seconds time elapsed

```

#### CFS
```
uname -a
Linux suse 5.7.7-1-default #1 SMP Wed Jul 1 19:03:27 UTC 2020 (cba119b) x86_64 x86_64 x86_64 GNU/Linux

sudo perf stat -e context-switches,cycles,instructions,L1-dcache-loads,L1-dcache-load-misses,LLC-loads,LLC-load-misses,branches,branch-misses -a -B stress-ng --cpu 4 -t 2m --cpu-method all --metrics-brief

stress-ng: info:  [2862] dispatching hogs: 4 cpu
stress-ng: info:  [2862] successful run completed in 120.08s (2 mins, 0.08 secs)
stress-ng: info:  [2862] stressor       bogo ops real time  usr time  sys time   bogo ops/s   bogo ops/s
stress-ng: info:  [2862]                           (secs)    (secs)    (secs)   (real time) (usr+sys time)
stress-ng: info:  [2862] cpu               86378    120.04    478.73      0.01       719.58       180.43

 Performance counter stats for 'system wide':

            31,631      context-switches                                            
 1,234,757,563,294      cycles                                                        (62.50%)
 1,320,229,149,505      instructions              #    1.07  insn per cycle           (75.00%)
   131,542,661,029      L1-dcache-loads                                               (62.32%)
    12,147,505,410      L1-dcache-load-misses     #    9.23% of all L1-dcache hits    (56.44%)
     4,326,450,020      LLC-loads                                                     (40.23%)
        14,863,894      LLC-load-misses           #    0.34% of all LL-cache hits     (37.50%)
   191,987,804,607      branches                                                      (49.99%)
     1,514,131,111      branch-misses             #    0.79% of all branches          (50.00%)

     120.132072691 seconds time elapsed
```






