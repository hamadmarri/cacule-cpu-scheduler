# Cachy-sched

Cachy-sched is a linux scheduler that utilizes CPU cache
and it is based on Highest Response Ratio Next (HRRN) policy.

## About Cachy Scheduler
* All balancing code is removed. There is no periodic balancing nor idle CPU balancing. Once a task is
assigned to a CPU, it sticks with it until it exits. The reason is to utilize the CPU cache of tasks.
* No grouping for tasks, `FAIR_GROUP_SCHED` must be disabled.
* No support for `NUMA`.
* Each CPU has its own runqueue.
* NORMAL runqueue is a linked list of sched_entities (instead of RB-Tree).
* A task gets preempted in every tick. If the clock ticks 250HZ (i.e. `CONFIG_HZ_250=y`) then a task
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
* Enqueue and Dequeue a task is `O(1)`.
* Pick the next task is `O(n)`, where `n` is the number of tasks in the runqueue (each CPU has its own runqueue). 

## Highest Response Ratio Next (HRRN) policy
Cachy is based in Highest Response Ratio Next (HRRN) policy.
HRRN is a non-preemptive scheduling policy in which the process
that has the highest response ratio will run next. Each process
has a response ratio value R = (w_t + s_t) / s_t where w_t is
the process waiting time, and s_t is the process estimated running
time. If two process has similar estimated running times, the
process that has been waiting longer will run first. HRRN aims
to prevent starvation since it strives the waiting time for processes.
    
## Tests and Benchmarks
TBA
