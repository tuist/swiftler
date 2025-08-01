#include <stdio.h>
#include <dlfcn.h>
#include <stdlib.h>

typedef unsigned long ERL_NIF_TERM;
typedef void* (*nif_init_func)(void);

int main() {
    // Load the dynamic library
    void* handle = dlopen("native/.build/release/libCalculatorNative.dylib", RTLD_NOW | RTLD_LOCAL);
    if (!handle) {
        printf("Failed to load library: %s\n", dlerror());
        return 1;
    }
    
    // Look for _nif_init
    nif_init_func nif_init = (nif_init_func)dlsym(handle, "_nif_init");
    if (!nif_init) {
        printf("Failed to find _nif_init: %s\n", dlerror());
        dlclose(handle);
        return 1;
    }
    
    printf("Found _nif_init at %p\n", nif_init);
    
    // Don't actually call it since we don't have the Erlang runtime
    
    // Look for the greet function - try both with and without underscore
    void* greet_func = dlsym(handle, "__swiftler_nif_thunk_greet");
    if (greet_func) {
        printf("Found __swiftler_nif_thunk_greet at %p\n", greet_func);
    } else {
        printf("Failed to find __swiftler_nif_thunk_greet: %s\n", dlerror());
        
        // Try with three underscores
        greet_func = dlsym(handle, "___swiftler_nif_thunk_greet");
        if (greet_func) {
            printf("Found ___swiftler_nif_thunk_greet at %p\n", greet_func);
        } else {
            printf("Also failed to find ___swiftler_nif_thunk_greet\n");
        }
    }
    
    dlclose(handle);
    return 0;
}