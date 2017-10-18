#include <stdio.h>
#include <pthread.h>
#include <signal.h>
#include <ctype.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>

#define P(x) pthread_mutex_lock(x)
#define V(x) pthread_mutex_unlock(x)
typedef void handler_t(int);

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

handler_t *Signal(int signum, handler_t *handler) {
    struct sigaction action, old_action;
    action.sa_handler = handler;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_RESTART;
    if (sigaction(signum, &action, &old_action) < 0)
        printf("Signal: error.\n");
    return (old_action.sa_handler);
}

void sigtstp_handler(int sig) {
    writer();
}

void sigint_handler(int sig) {
    P(&mutex2);
    flag_sigint = 1;
    V(&mutex2);
    exit(0);
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
