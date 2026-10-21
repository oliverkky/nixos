/*
 * Steam desktop UI scale workaround. Inspired by steam-cef-scale-override:
 * https://github.com/IanHollow/steam-cef-scale-override (MIT license).
 */
#define _GNU_SOURCE

#include <dlfcn.h>
#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef int (*cef_initialize_t)(const void *, const void *, void *, void *);
typedef void (*cef_set_scale_t)(double);

static int is_steam_webhelper(void) {
    char path[4096];
    ssize_t length = readlink("/proc/self/exe", path, sizeof(path) - 1);
    if (length < 0 || (size_t)length >= sizeof(path))
        return 0;
    path[length] = '\0';
    char *name = strrchr(path, '/');
    return strcmp(name ? name + 1 : path, "steamwebhelper") == 0;
}

static int requested_scale(double *scale) {
    const char *value = getenv("STEAM_UI_SCALE");
    if (!value || !*value)
        return 0;

    char *end;
    errno = 0;
    double parsed = strtod(value, &end);
    if (errno || end == value || *end || !isfinite(parsed) || parsed < 0.25 || parsed > 8.0) {
        fprintf(stderr, "steam-ui-scale: invalid STEAM_UI_SCALE value\n");
        return 0;
    }
    *scale = parsed;
    return 1;
}

__attribute__((visibility("default")))
int cef_initialize(const void *args, const void *settings, void *application, void *sandbox_info) {
    cef_initialize_t original = (cef_initialize_t)dlsym(RTLD_NEXT, "cef_initialize");
    if (!original) {
        fprintf(stderr, "steam-ui-scale: cef_initialize is unavailable\n");
        return 0;
    }

    int result = original(args, settings, application, sandbox_info);
    if (!result || !is_steam_webhelper())
        return result;

    double scale;
    if (!requested_scale(&scale))
        return result;

    cef_set_scale_t set_scale = (cef_set_scale_t)dlsym(RTLD_NEXT, "cef_set_force_device_scale_factor");
    if (set_scale) {
        set_scale(scale);
        fprintf(stderr, "steam-ui-scale: applied %.2f to steamwebhelper\n", scale);
    } else {
        fprintf(stderr, "steam-ui-scale: CEF scale function is unavailable\n");
    }
    return result;
}
