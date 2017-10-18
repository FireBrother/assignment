#Report of Practice in Synchronization

## Practice 1.
### 1.1
>Q: ￼￼￼￼￼￼Survey how locks are implemented in Linux uniprocessor and multiprocessors)

I found the source code in Linux kernel as follows:

spinlock_types.h

	typedef struct spinlock {
		union {
			struct raw_spinlock rlock;
	
	#ifdef CONFIG_DEBUG_LOCK_ALLOC
	# define LOCK_PADSIZE (offsetof(struct raw_spinlock, dep_map))
			struct {
				u8 __padding[LOCK_PADSIZE];
				struct lockdep_map dep_map;
			};
	#endif
		};
	} spinlock_t;

...I abandoned to read the source code because the codes for spinlock are too complicated.  
I tried to read the book, *Understanding the Linux Kernel*.

Each spin lock is represented by a `spinlock_t` structure consisting of a single lock field; the values and 1 correspond, respectively, to the "unlocked" and the "locked" state. The `SPIN_LOCK_UNLOCKED` macro initializes a spin lock to 0.

The `spin_lock` macro is used to acquire a spin lock. It takes the address `slp` of the spin lock as its parameter and yields essentially the following code:
	1: lock; btsl $0, slp	   jnc  3f	2: testb $1,slp	   jne 2b	jmp 1b 3:

The `btsl` atomic instruction copies into the carry flag the value of bit in `*slp`, then sets the bit. A test is then performed on the carry flag: if it is null, it means that the spin lock was unlocked and hence normal execution continues at label 3 (the `f` suffix denotes the fact that the label is a "forward" one: it appear in a later line of the program). Otherwise, the tight loop at label 2 (the b suffix denotes a "backward" label) is executed until the spin lock assumes the value 0. Then execution restarts from label 1, since it would be unsafe to proceed without checking whether another processor has grabbed the lock.

The `spin_unlock` macro releases a previously acquired spin lock; it essentially yields the following code:
	lock; btrl $0, slpThe btrl atomic assembly language instruction clears the bit of the spin lock `*slp`.

### 1.2
>Q: ￼Survey how semaphores are implemented in Linux uniprocessor and multiprocessors)

semaphore.h:

	struct semaphore {
		raw_spinlock_t		lock;
		unsigned int		count;
		struct list_head	wait_list;
	};

semaphore.c:

	void down(struct semaphore *sem)
	{
		unsigned long flags;
	
		raw_spin_lock_irqsave(&sem->lock, flags);
		if (likely(sem->count > 0))
			sem->count--;
		else
			__down(sem);
		raw_spin_unlock_irqrestore(&sem->lock, flags);
	}
	EXPORT_SYMBOL(down);
	
	void up(struct semaphore *sem)
	{
		unsigned long flags;
	
		raw_spin_lock_irqsave(&sem->lock, flags);
		if (likely(list_empty(&sem->wait_list)))
			sem->count++;
		else
			__up(sem);
		raw_spin_unlock_irqrestore(&sem->lock, flags);
	}
	EXPORT_SYMBOL(up);

There are also some functions with suffix to fulfill different requirements but I won't show them in my report.  
Compared with `spinlock`, the codes for semaphore ar so easy to understand that there is nearly no need to explain it in natural language.  The only thing is the `wait_list`, which is  insteresting.  
`wait_list` is used to record the tasks that are blocked because of the `semaphore`(however, the implementation is in the function `__down_common()`, which is not involed in my report). 

## Before my report
In order to observe the behavior conveniently, I use signal to control the program. I will omit the codes about signal to keep the report easy to read.

## Practice 2.
>Q: If a system provides only the mutex semaphore, how can you use it to implement a counting semaphore?

### Introduction
I use a structure containing an integer and a mutex to implement the counting semaphore. The mutex is used for blocking the thread.  
`SIGTSTP`: to call `my_up()`.

### Codes

	#include <stdio.h>
	#include <pthread.h>
	#include <signal.h>
	#include <ctype.h>
	#include <sys/types.h>
	#include <unistd.h>
	
	#define P(x) pthread_mutex_lock(x)
	#define V(x) pthread_mutex_unlock(x)

	pthread_mutex_t mutex;
	
	struct my_semaphore {
	    pthread_mutex_t m;
	    int count;
	};
	
	struct my_semaphore sema;
	
	void my_semaphore_init(struct my_semaphore *s, int count) {
	    pthread_mutex_init(&(s->m), NULL);
	    // to consume a mutex so that the thread will be blocked when it P() next time.
	    P(&(s->m));
	    s->count = count;
	}
	
	void my_down(struct my_semaphore *s) {
	    P(&mutex);
	    --s->count;
	    V(&mutex);
	    if (s->count < 0) P(&(s->m));
	}
	
	void my_up(struct my_semaphore *s) {
	    P(&mutex);
	    if (s->count < 0) V(&(s->m));
	    ++s->count;
	    V(&mutex);
	}
	
	void *thread(void *arg) {
	    my_down(&sema);
	    printf("I'm requesting a count.\n");
	    return NULL;
	}
	
	int main() {
	    Signal(SIGTSTP, sigtstp_handler);
	    pthread_mutex_init(&mutex, NULL);
	    my_semaphore_init(&sema, 1);
	    my_up(&sema);
	    my_down(&sema);
	    printf("This point can be reached.\n");
	    my_down(&sema);
	    printf("This point can be reached.\n");
	    my_down(&sema);
	    printf("This point can not be reached until I press ctrl-z!\n");
	    printf("Now here is multithread test.\n");
	    pthread_t tids[2];	    
	    pthread_create(&tids[0], NULL, &thread, NULL);
	    pthread_create(&tids[1], NULL, &thread, NULL);
	    pthread_join(tids[0], NULL);
	    pthread_join(tids[1], NULL);
	}

### Result
	wuxiandeMacBook-Air:Report of Practice in Synchronization wuxian$ ./counting_by_mutex 
	This point can be reached.
	This point can be reached.
	^ZThis point can not be reached until I press ctrl-z!
	Now here is multithread test.
	^ZI'm requesting a count.
	^ZI'm requesting a count.

## Practice 3.
### Introduction
I add a bool variable `writer_is_waiting` to indicate that a `writer` is waiting. When `writer_is_waiting` is ture, the `reader` that starts after it must be blocked until the `writer` is finished, so I use a `pthread_cond_t` to block the `reader`.  
`SIGTSTP`: start a `writer` task.  
`SIGINT`: terminate all threads.

### Codes
	#include <stdio.h>
	#include <pthread.h>
	#include <signal.h>
	#include <ctype.h>
	#include <sys/types.h>
	#include <stdlib.h>
	#include <unistd.h>
	
	#define P(x) pthread_mutex_lock(x)
	#define V(x) pthread_mutex_unlock(x)
	
	pthread_mutex_t mutex, mutex2, w_or_r;
	int writer_is_waiting = 0;
	int reader_count = 0;
	int flag_sigint = 0;
	pthread_cond_t cond;
	
	void writer() {
	    P(&mutex2);
	    writer_is_waiting = 1;
	    V(&mutex2);
	    P(&w_or_r);
	    printf("This is a writing task.\n");
	    V(&w_or_r);
	    P(&mutex2);
	    writer_is_waiting = 0;
	    pthread_cond_broadcast(&cond);
	    V(&mutex2);
	}
	
	void reader(int no_starvation) {
	    P(&mutex2);
	    if (no_starvation && writer_is_waiting) pthread_cond_wait(&cond, &mutex2);
	    V(&mutex2);
	    P(&mutex);
	    reader_count++;
	    if (reader_count == 1) P(&w_or_r);
	    V(&mutex);
	    sleep(1);
	    P(&mutex);
	    reader_count--;
	    if (reader_count == 0) V(&w_or_r);
	    V(&mutex);
	}
	
	void *thread(void *arg) {
	    while (!flag_sigint) reader(*(int *)arg);
	    return NULL;
	}
	
	int main(int argc, char *argv[]) {
	    if (argc != 3) {
	        printf("usage: writer_and_reader NUM_TASKS no_starvation\n");
	        exit(0);
	    }
	    pthread_mutex_init(&mutex, NULL);
	    pthread_mutex_init(&mutex2, NULL);
	    pthread_mutex_init(&w_or_r, NULL);
	    pthread_cond_init(&cond, NULL);
	    Signal(SIGTSTP, sigtstp_handler);
	    Signal(SIGINT, sigint_handler);
	    const int NUM_TASKS = atoi(argv[1]);
	    int no_starvation = atoi(argv[2]);
	    pthread_t tids[NUM_TASKS];
	    for (int i = 0; i < NUM_TASKS; i++) {
	        int ret = pthread_create(&tids[i], NULL, &thread, (void *)&no_starvation);
	        if (ret) {
	            printf("pthread_create: error.\n");
	            return ret;
	        };
	    }
	    while (!flag_sigint) {
	        printf("%d reads are running.\n", reader_count);
	        usleep(0.4 * 1000 * 1000);
	    }
	    for (int i = 0; i < NUM_TASKS; i++)
	        pthread_join(tids[i], NULL);
	}

### Result
	wuxiandeMacBook-Air:Report of Practice in Synchronization wuxian$ ./writer_and_reader 2000 1
	1999 reads are running.
	2000 reads are running.
	2000 reads are running.
	^ZThis is a writing task.
	0 reads are running.
	2000 reads are running.
	2000 reads are running.
	2000 reads are running.
