# Cachy-sched

Cachy-sched is a linux scheduler that utilizes CPU cache
and it is based on Highest Response Ratio Next (HRRN) policy.

## About Cachy Scheduler
* All balancing code is removed except for idle CPU balancing. There is no periodic balancing, only idle CPU balancing is applied. Once a task is
assigned to a CPU, it sticks with it until another CPUS got idle then this task might get pulled to new cpu.
The reason of disabling periodic balancing is to utilize the CPU cache of tasks.
* No grouping for tasks, `FAIR_GROUP_SCHED` must be disabled.
* No support for `NUMA`, `NUMA` must be disabled.
* Each CPU has its own runqueue.
* NORMAL runqueue is a linked list of sched_entities (instead of RB-Tree).
* RT and other runqueues are just the same as the CFS's.
* A task gets preempted in every tick. If the clock ticks in 250HZ (i.e. `CONFIG_HZ_250=y`) then a task
runs for 4 milliseconds and then got preempted if there are other tasks in the runqueue.
* Wake up tasks preempt currently running tasks if its HRRN value is higher.
* This scheduler is designed for desktop usage since it is about responsiveness. It may be not bad for servers.
* Cachy might be good for mobiles or Android since it has high responsiveness. Cachy need to be integrated to
Android, I don't think the current version it is ready to go without some tweeking and adapting to Android hacks.


## Patched Kernel Tree
1. Go to [kernel tree repository](https://github.com/hamadmarri/linux) 
2. Select a tag version that starts with `cachy` (i.e `cachy-5.9-r1`)
3. Download and compile


## How to apply the patch
1. Download the linux kernel (https://www.kernel.org/) that is same version as the patch (i.e if patch file name is cachy-5.7.6.patch, then download https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.7.6.tar.xz)
2. Unzip linux kernel
3. Download cachy patch file and place it inside the just unzipped linux kernel folder
4. cd linux-(version)
5. patch -p1 < cachy-5.7.6.patch
6. **`make menuconfig` make sure `FAIR_GROUP_SCHED` and `NUMA` are disabled**
7. To build the kernel you need to follow linux build kernel documentation and tutorials.


To confirm that Cachy is currently running:
```

dmesg | grep -i "cachy cpu"
[    0.059697] Cachy CPU scheduler v5.9 by Hamad Al Marri.

```

## Special Thanks to
1. Alexandre Frade (the maintainer of [xanmod](https://github.com/xanmod))


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


If two processes have the same `R` after integer rounding, the division remainder is compared. See below the full
calculation for `R` value:

```
u64 r_curr, r_se, w_curr = 1ULL, w_se = 1ULL;
struct task_struct *t_curr = task_of(curr);
struct task_struct *t_se = task_of(se);
u64 vr_curr 	= curr->hrrn_sum_exec_runtime + 1;
u64 vr_se 	= se->hrrn_sum_exec_runtime   + 1;
s64 diff;

diff = now - curr->hrrn_start_time;
if (diff > 0)
	w_curr	= diff;

diff = now - se->hrrn_start_time;
if (diff > 0)
	w_se	= diff;

// adjusting for priorities
w_curr	*= (140 - t_curr->prio);
w_se	*= (140 - t_se->prio);

r_curr	= w_curr / vr_curr;
r_se	= w_se / vr_se;
diff	= r_se - r_curr;

// take the remainder if equal
if (diff == 0)
{
	r_curr	= w_curr % vr_curr;
	r_se	= w_se % vr_se;
	diff	= r_se - r_curr;
}

if (diff > 0)
	return 1;

return -1;

```


Highest response ratio next (HRRN) scheduling is a non-preemptive discipline. It was developed by Brinch Hansen as modification of shortest job next (SJN) to mitigate the problem of process starvation [wikipedia](https://en.wikipedia.org/wiki/Highest_response_ratio_next). The original HRRN is non-preemptive meaning that a task runs until it finishes. This nature is not
good for interactive systems. Applying original HRRN with preemptive modifications requires two changes. First, what happens if
the scheduler forces a task to preempt every tick? This can work great for short amount of time lets say (< 60 minutes) until some
tasks ages and new tasks created, then the imbalance happens. Assume one task `T1` (Xorg) is running and waiting for users inputs.
This task will have high HRRN because it sleeps more than it runs, however, after a long time (say 60 minuets = 3600000000000ns) the life
time of `T1` is 3600000000000ns lets assume the sum of execution time is 50% = 1800000000000ns. The HRRN = 3600000000000 / 1800000000000 
= 2. If `T1` runs for 4ms, the rate of change on HRRN is too low: HRRN = 3600000000000 / 1800004000000 = 1.999995556

Also, if `T1` waited for 1s HRRN = 3601000000000 / 1800004000000 = 2.00055111, the rate of change is low too. Both situations are bad, because:
1. A new task `T2` will have higher HRRN when it starts, thus it will be picked instead of `T1`
2. The rate of change of `T2` compared to `T1` is higher.

This situation is not good for infinite-life processes such as Xorg and desktop related threads. Those task must run ASAP when they
wake up, because they are related to responsiveness and Interactivity.

Therefore, the original HRRN needs some modifications.

### HRRN Modifications
We have implemented two modifications that enhances HRRN to work as a preemptive policy:

#### HRRN maximum life time
Instead of calculating a task HRRN value for infinite life time, we proposed `hrrn_max_lifetime` which is 10s by default. A task's
`hrrn_start_time` and `hrrn_sum_exec_runtime` reset every 10s. Therefore, the rate of change of HRRN for old and new tasks is
normalized. The value `hrrn_max_lifetime` can be changed at run time by the following sysctl command:

```
sudo sysctl kernel.sched_hrrn_max_lifetime_ms=60000
```

The value is in milliseconds, the above command changes `hrrn_max_lifetime` from 10s to 60s.

#### HRRN latency
A new task could overcome old tasks because it has 1 sum execution, and lets say its age is few microseconds 7000ns (7us). This new task will have
HRRN = 7000 which is high compared with older tasks. That's why we proposed `hrrn_latency` which is in microseconds. When a new task is
forked, the `hrrn_start_time` is set to (current time in nano + hrrn_latency). The default value of `hrrn_latency` is 0. This value
can be changed by the following:

```
sudo sysctl kernel.sched_hrrn_latency_us=6000
```

This sets `hrrn_latency` to 6ms. Notice that a new task will have HRRN=1 for this period of time. Notice also that if no runnable tasks other
than this new task, this task will run. Adding 6ms doesn't mean that a new task will pause for 6ms. It means it will have HRRN=1 or 0
for 6ms. It depends on how many other task on the run queue and whether they have higher HRRN or not. This will solve a problem when
having heavy compilation with -j5 on 4CPUS machine. The compilation will create new threads for each file and that might cause freezes
and hangups. Technically those new threads could have higher HRRN values than Xorg or whatever old running desktop tasks.

Having said that, the default value is 0, on my machine this value doesn't make any problems and I don't have any freezes when
compiling kernel unless I changed it to -500000000. It depends on your machine and on how fast is your HD drive.



## Priorities
The priorities are applied as the followings:
* The wait time is calculated and then multiplied by `(140 - t_curr->prio)` where `t_curr` is the task.
* Highest priority in NORMAL policy is `100` so the wait is multiplied by `140 - 100 = 40`.
* Normal priority in NORMAL policy is `120` so the wait is multiplied by `140 - 120 = 20`.
* Lowest priority is `139` so the wait is multiplied by `140 - 139 = 1`.
* This calculation is applied for all task in NORMAL policy where they range from `100 - 139`.
* After the multiplication, wait is divided by `s_t` (the `sum_exec_runtime + 1`).



## Tests and Benchmarks

### Interactivity and Responsiveness while compiling shaders
#### Cachy compared with MUQSS
[MUQSS](https://www.youtube.com/watch?v=B-6MVWONOuc)
[Cachy](https://www.youtube.com/watch?v=jt1xl3wtZ0s)



### Phoronix Test Suite
https://openbenchmarking.org/result/2007301-NI-CACHYVSCF60


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






