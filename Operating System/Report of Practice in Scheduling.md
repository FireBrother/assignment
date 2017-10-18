# Report of Practice in Scheduling
---
Xian Wu, 1300012817

## Practice 1.
>Q: Check the scheduling policies in Linux and Windows and compare these policies (also for multiprocessor and real-time scheduling)

### In Linux
- Linux has three shceduling policies, which are `SCHED_OTHER`, `SCHED_FIFO` and `SCHED_RR`.
- Linux has two kinds of process, which are `real-time process` and `time-sharing process.`
- `Real-time process` uses the policy of `SCHED_FIFO` and `SCHED_RR` and `time-sharing process` uses the policy of `SCHED_OTHER`.
- Here are some documents from wiki:
	> #### Linux
	> ##### Linux 2.4
	> In Linux 2.4, an O(n) scheduler with a multilevel feedback queue with priority levels ranging from 0 to 140 was used; 0–99 are reserved for real-time tasks and 100–140 are considered nice task levels. For real-time tasks, the time quantum for switching processes was approximately 200 ms, and for nice tasks approximately 10 ms.[citation needed] The scheduler ran through the run queue of all ready processes, letting the highest priority processes go first and run through their time slices, after which they will be placed in an expired queue. When the active queue is empty the expired queue will become the active queue and vice versa.
	> 
	> However, some Enterprise Linux distributions such as SUSE Linux Enterprise Server replaced this scheduler with a backport of the O(1) scheduler (which was maintained by Alan Cox in his Linux 2.4-ac Kernel series) to the Linux 2.4 kernel used by the distribution.
	> 
	> ##### Linux 2.6.0 to Linux 2.6.22
	> In versions 2.6.0 to 2.6.22, the kernel used an O(1) scheduler developed by Ingo Molnar and many other kernel developers during the Linux 2.5 development. For many kernel in time frame, Con Kolivas developed patch sets which improved interactivity with this scheduler or even replaced it with his own schedulers.
	> 
	> ##### Since Linux 2.6.23
	> Con Kolivas's work, most significantly his implementation of "fair scheduling" named "Rotating Staircase Deadline", inspired Ingo Molnár to develop the Completely Fair Scheduler as a replacement for the earlier O(1) scheduler, crediting Kolivas in his announcement.[11] CFS is the first implementation of a fair queuing process scheduler widely used in a general-purpose operating system.
	> 
	> The Completely Fair Scheduler (CFS) uses a well-studied, classic scheduling algorithm called fair queuing originally invented for packet networks. Fair queuing had been previously applied to CPU scheduling under the name stride scheduling. The fair queuing CFS scheduler has a scheduling complexity of O(log N), where N is the number of tasks in the runqueue. Choosing a task can be done in constant time, but reinserting a task after it has run requires O(log N) operations, because the run queue is implemented as a red-black tree.
	> 
	> The Brain Fuck Scheduler (BFS), also created by Con Kolivas, is an alternative to the CFS.
- The "priority" represents the priority for `real-time process` and running time for `time-sharing process`.

### Completely Fair Scheduler
The data structure used for the scheduling algorithm is a red-black tree in which the nodes are scheduler specific structures, entitled "sched_entity". These are derived from the general task_struct process descriptor, with added scheduler elements. These nodes are indexed by processor execution time in nanoseconds. A maximum execution time is also calculated for each process. This time is based upon the idea that an "ideal processor" would equally share processing power amongst all processes. Thus, the maximum execution time is the time the process has been waiting to run, divided by the total number of processes, or in other words, the maximum execution time is the time the process would have expected to run on an "ideal processor".
When the scheduler is invoked to run a new processes, the operation of the scheduler is as follows:
1. The left most node of the scheduling tree is chosen (as it will have the lowest spent execution time), and sent for execution.
2. If the process simply completes execution, it is removed from the system and scheduling tree.
3. If the process reaches its maximum execution time or is otherwise stopped (voluntarily or via interrupt) it is reinserted into the scheduling tree based on its new spent execution time.
4. The new left-most node will then be selected from the tree, repeating the iteration.
5. If the process spends a lot of its time sleeping, then its spent time value is low and it automatically gets the priority boost when it finally needs it. Hence such tasks do not get less processor time than the tasks that are constantly running.

### In Windows
- The unit of scheduling in Windows is threads and process is only the container of threads.
- Windows has 32 levels of priority.
- The priority of each thread is determined by the following criteria:
	- The priority class of its process
	- The priority level of the thread within the priority class of its process
- Each process belongs to one of the following priority classes:
    - IDLE_PRIORITY_CLASS
    - BELOW_NORMAL_PRIORITY_CLASS
    - NORMAL_PRIORITY_CLASS
    - ABOVE_NORMAL_PRIORITY_CLASS
    - HIGH_PRIORITY_CLASS
    - REALTIME_PRIORITY_CLASS
- The following are priority levels within each priority class:
    - THREAD_PRIORITY_IDLE
    - THREAD_PRIORITY_LOWEST
    - THREAD_PRIORITY_BELOW_NORMAL
    - THREAD_PRIORITY_NORMAL
    - THREAD_PRIORITY_ABOVE_NORMAL
    - THREAD_PRIORITY_HIGHEST
    - THREAD_PRIORITY_TIME_CRITICAL
- Priority Inversion(From msdn)
	> Priority inversion occurs when two or more threads with different priorities are in contention to be scheduled. Consider a simple case with three threads: thread 1, thread 2, and thread 3. Thread 1 is high priority and becomes ready to be scheduled. Thread 2, a low-priority thread, is executing code in a critical section. Thread 1, the high-priority thread, begins waiting for a shared resource from thread 2. Thread 3 has medium priority. Thread 3 receives all the processor time, because the high-priority thread (thread 1) is waiting for shared resources from the low-priority thread (thread 2). Thread 2 will not leave the critical section, because it does not have the highest priority and will not be scheduled.
	> The scheduler solves this problem by randomly boosting the priority of the ready threads (in this case, the low priority lock-holders). The low priority threads run long enough to exit the critical section, and the high-priority thread can enter the critical section. If the low-priority thread does not get enough CPU time to exit the critical section the first time, it will get another chance during the next round of scheduling.

- Priority Boosts
	> Each thread has a dynamic priority. This is the priority the scheduler uses to determine which thread to execute. Initially, a thread's dynamic priority is the same as its base priority. The system can boost and lower the dynamic priority, to ensure that it is responsive and that no threads are starved for processor time. The system does not boost the priority of threads with a base priority level between 16 and 31. Only threads with a base priority between 0 and 15 receive dynamic priority boosts.
	> The system boosts the dynamic priority of a thread to enhance its responsiveness as follows.
	> When a process that uses `NORMAL_PRIORITY_CLASS` is brought to the foreground, the scheduler boosts the priority class of the process associated with the foreground window, so that it is greater than or equal to the priority class of any background processes. The priority class returns to its original setting when the process is no longer in the foreground.
	> When a window receives input, such as timer messages, mouse messages, or keyboard input, the scheduler boosts the priority of the thread that owns the window.
	> When the wait conditions for a blocked thread are satisfied, the scheduler boosts the priority of the thread. For example, when a wait operation associated with disk or keyboard I/O finishes, the thread receives a priority boost.
	> You can disable the priority-boosting feature by calling the `SetProcessPriorityBoost` or `SetThreadPriorityBoost` function. To determine whether this feature has been disabled, call the `GetProcessPriorityBoost` or `GetThreadPriorityBoost` function.
	> After raising a thread's dynamic priority, the scheduler reduces that priority by one level each time the thread completes a time slice, until the thread drops back to its base priority. A thread's dynamic priority is never less than its base priority.

### Multiple Processors
#### Thread Affinity
Thread affinity forces a thread to run on a specific subset of processors. Setting thread affinity should generally be avoided, because it can interfere with the scheduler's ability to schedule threads effectively across processors. This can decrease the performance gains produced by parallel processing. An appropriate use of thread affinity is testing each processor.
The system represents affinity with a bitmask called a processor affinity mask. The affinity mask is the size of the maximum number of processors in the system, with bits set to identify a subset of processors. Initially, the system determines the subset of processors in the mask.
You can obtain the current thread affinity for all threads of the process by calling the `GetProcessAffinityMask` function. Use the `SetProcessAffinityMask` function to specify thread affinity for all threads of the process. To set the thread affinity for a single thread, use the `SetThreadAffinityMask` function. The thread affinity must be a subset of the process affinity.
On systems with more than 64 processors, the affinity mask initially represents processors in a single processor group. However, thread affinity can be set to a processor in a different group, which alters the affinity mask for the process. For more information, see Processor Groups.
#### Thread Ideal Processor
When you specify a thread ideal processor, the scheduler runs the thread on the specified processor when possible. Use the `SetThreadIdealProcessor` function to specify a preferred processor for a thread. This does not guarantee that the ideal processor will be chosen but provides a useful hint to the scheduler. On systems with more than 64 processors, you can use the `SetThreadIdealProcessorEx` function to specify a preferred processor in a specific processor group.