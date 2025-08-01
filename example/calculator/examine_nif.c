#include <stdio.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>

// Minimal ErlNifFunc structure
typedef struct {
    const char *name;
    unsigned arity;
    void *fptr;
    unsigned flags;
} ErlNifFunc;

// Minimal ErlNifEntry structure
typedef struct {
    int major;
    int minor;
    const char* name;
    int num_of_funcs;
    ErlNifFunc* funcs;
    void* load;
    void* reload;
    void* upgrade;
    void* unload;
    const char* vm_variant;
    unsigned options;
    size_t sizeof_ErlNifResourceTypeInit;
    const char* min_erts;
} ErlNifEntry;

typedef ErlNifEntry* (*nif_init_func)(void);

int main() {
    void* handle = dlopen("native/.build/release/libCalculatorNative.dylib", RTLD_NOW | RTLD_LOCAL);
    if (!handle) {
        printf("Failed to load library: %s\n", dlerror());
        return 1;
    }
    
    nif_init_func nif_init = (nif_init_func)dlsym(handle, "_nif_init");
    if (!nif_init) {
        printf("Failed to find _nif_init: %s\n", dlerror());
        dlclose(handle);
        return 1;
    }
    
    printf("Calling nif_init...\n");
    ErlNifEntry* entry = nif_init();
    
    if (!entry) {
        printf("nif_init returned NULL\n");
        dlclose(handle);
        return 1;
    }
    
    printf("NIF Entry:\n");
    printf("  Module name: %s\n", entry->name);
    printf("  Major: %d, Minor: %d\n", entry->major, entry->minor);
    printf("  Number of functions: %d\n", entry->num_of_funcs);
    printf("  VM variant: %s\n", entry->vm_variant);
    printf("  Min ERTS: %s\n", entry->min_erts);
    
    printf("\nFunctions:\n");
    for (int i = 0; i < entry->num_of_funcs; i++) {
        ErlNifFunc* func = &entry->funcs[i];
        printf("  [%d] name: '%s', arity: %u, fptr: %p\n", 
               i, func->name, func->arity, func->fptr);
        
        // Check if this is the greet function
        if (func->name && strcmp(func->name, "greet") == 0) {
            printf("      ^ This is the greet function!\n");
            
            // Try to find the actual symbol
            char symbol_name[256];
            snprintf(symbol_name, sizeof(symbol_name), "__swiftler_nif_thunk_%s", func->name);
            void* symbol = dlsym(handle, symbol_name);
            printf("      Looking for symbol '%s': %p\n", symbol_name, symbol);
            
            if (symbol == func->fptr) {
                printf("      Symbol matches function pointer!\n");
            } else {
                printf("      WARNING: Symbol does not match function pointer!\n");
                printf("      func->fptr: %p\n", func->fptr);
                printf("      dlsym result: %p\n", symbol);
            }
        }
    }
    
    dlclose(handle);
    return 0;
}