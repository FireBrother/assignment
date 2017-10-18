#include <stdio.h>
#include <pthread.h>
#include <signal.h>
#include <ctype.h>
#include <sys/types.h>
#include <unistd.h>

#define P(x) pthread_mutex_lock(x)
#define V(x) pthread_mutex_unlock(x)
typedef void handler_t(int);

pthread_mutex_t mutex;

struct my_semaphore {
    pthread_mutex_t m;
    int count;
};

struct my_semaphore sema;

void my_semaphore_init(struct my_semaphore *s, int count) {
    pthread_mutex_init(&(s->m), NULL);
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
    my_up(&sema);
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
