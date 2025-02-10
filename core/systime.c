
#include <time.h>
#include "systime.h"

uint64_t
systime_wall() {
    uint64_t t;
    struct timespec ti;
    clock_gettime(CLOCK_REALTIME, &ti);
    t = ti.tv_sec * 100 + (ti.tv_nsec / 10000000);
    return t;
}

uint64_t
systime_mono() {
    uint64_t t;
    struct timespec ti;
    clock_gettime(CLOCK_MONOTONIC, &ti);
    t = (uint64_t)ti.tv_sec * 100;
    t += ti.tv_nsec / 10000000;
    return t;
}
