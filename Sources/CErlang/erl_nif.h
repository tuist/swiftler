/*
 * Simplified erl_nif.h for Swiftler
 * Based on Erlang/OTP erl_nif.h (Apache 2.0 License)
 * 
 * This is a minimal version containing only the essential NIF types and functions
 * needed for basic Swift-Erlang integration.
 */

#ifndef __ERL_NIF_H__
#define __ERL_NIF_H__

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Basic types */
typedef uint64_t ERL_NIF_TERM;
typedef struct enif_environment_t ErlNifEnv;
typedef struct enif_pid_t ErlNifPid;
typedef struct enif_binary {
    size_t size;
    unsigned char* data;
} ErlNifBinary;

typedef struct {
    const char* name;
    unsigned arity;
    ERL_NIF_TERM (*fptr)(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    unsigned flags;
} ErlNifFunc;

typedef struct {
    int major;
    int minor;
    const char* name;
    int num_of_funcs;
    ErlNifFunc* funcs;
    int (*load)(ErlNifEnv*, void**, ERL_NIF_TERM);
    int (*reload)(ErlNifEnv*, void**, ERL_NIF_TERM);
    int (*upgrade)(ErlNifEnv*, void**, void**, ERL_NIF_TERM);
    void (*unload)(ErlNifEnv*, void*);
    const char* vm_variant;
    unsigned options;
    size_t sizeof_ErlNifResourceTypeInit;
    const char* min_erts;
} ErlNifEntry;

/* Version constants */
#define ERL_NIF_MAJOR_VERSION 2
#define ERL_NIF_MINOR_VERSION 16

/* Encoding constants */
#define ERL_NIF_LATIN1 1U

/* Function declarations - these will be linked at runtime */
extern ERL_NIF_TERM enif_make_badarg(ErlNifEnv* env);
extern ERL_NIF_TERM enif_make_int(ErlNifEnv* env, int i);
extern ERL_NIF_TERM enif_make_long(ErlNifEnv* env, long i);
extern ERL_NIF_TERM enif_make_double(ErlNifEnv* env, double d);
extern ERL_NIF_TERM enif_make_atom(ErlNifEnv* env, const char* name);
extern ERL_NIF_TERM enif_make_tuple_from_array(ErlNifEnv* env, const ERL_NIF_TERM arr[], unsigned cnt);
extern ERL_NIF_TERM enif_make_binary(ErlNifEnv* env, ErlNifBinary* bin);

extern int enif_get_int(ErlNifEnv* env, ERL_NIF_TERM term, int* ip);
extern int enif_get_long(ErlNifEnv* env, ERL_NIF_TERM term, long* ip);
extern int enif_get_double(ErlNifEnv* env, ERL_NIF_TERM term, double* dp);
extern int enif_get_atom_length(ErlNifEnv* env, ERL_NIF_TERM term, unsigned* len, unsigned encoding);
extern int enif_get_atom(ErlNifEnv* env, ERL_NIF_TERM term, char* buf, unsigned len, unsigned encoding);
extern int enif_get_string(ErlNifEnv* env, ERL_NIF_TERM list, char* buf, unsigned len, unsigned encoding);
extern int enif_get_list_length(ErlNifEnv* env, ERL_NIF_TERM term, unsigned* len);

extern int enif_inspect_binary(ErlNifEnv* env, ERL_NIF_TERM bin_term, ErlNifBinary* bin);
extern int enif_alloc_binary(size_t size, ErlNifBinary* bin);

/* Helper for string duplication */
extern char* strdup(const char* s);

/* Memory functions */
extern void* memcpy(void* dest, const void* src, size_t n);

#ifdef __cplusplus
}
#endif

#endif /* __ERL_NIF_H__ */