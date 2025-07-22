#include "erl_nif.h"

// Provide weak symbols for NIF functions so they can be linked
// These will be overridden by the actual implementations when loaded in Erlang VM

__attribute__((weak)) ERL_NIF_TERM enif_make_badarg(ErlNifEnv* env) {
    return 0;
}

__attribute__((weak)) ERL_NIF_TERM enif_make_int(ErlNifEnv* env, int i) {
    return 0;
}

__attribute__((weak)) ERL_NIF_TERM enif_make_double(ErlNifEnv* env, double d) {
    return 0;
}

__attribute__((weak)) ERL_NIF_TERM enif_make_atom(ErlNifEnv* env, const char* name) {
    return 0;
}

__attribute__((weak)) ERL_NIF_TERM enif_make_binary(ErlNifEnv* env, ErlNifBinary* bin) {
    return 0;
}

__attribute__((weak)) ERL_NIF_TERM enif_make_long(ErlNifEnv* env, long i) {
    return 0;
}

__attribute__((weak)) ERL_NIF_TERM enif_make_tuple_from_array(ErlNifEnv* env, const ERL_NIF_TERM arr[], unsigned cnt) {
    return 0;
}

__attribute__((weak)) int enif_get_int(ErlNifEnv* env, ERL_NIF_TERM term, int* ip) {
    return 0;
}

__attribute__((weak)) int enif_get_double(ErlNifEnv* env, ERL_NIF_TERM term, double* dp) {
    return 0;
}

__attribute__((weak)) int enif_get_long(ErlNifEnv* env, ERL_NIF_TERM term, long* ip) {
    return 0;
}

__attribute__((weak)) int enif_inspect_binary(ErlNifEnv* env, ERL_NIF_TERM bin_term, ErlNifBinary* bin) {
    return 0;
}

__attribute__((weak)) int enif_alloc_binary(size_t size, ErlNifBinary* bin) {
    return 0;
}

__attribute__((weak)) int enif_get_atom_length(ErlNifEnv* env, ERL_NIF_TERM term, unsigned* len, unsigned encoding) {
    return 0;
}

__attribute__((weak)) int enif_get_atom(ErlNifEnv* env, ERL_NIF_TERM term, char* buf, unsigned len, unsigned encoding) {
    return 0;
}

__attribute__((weak)) int enif_get_list_length(ErlNifEnv* env, ERL_NIF_TERM term, unsigned* len) {
    return 0;
}

__attribute__((weak)) int enif_get_string(ErlNifEnv* env, ERL_NIF_TERM list, char* buf, unsigned len, unsigned encoding) {
    return 0;
}

__attribute__((weak)) char* strdup(const char* s) {
    return 0;
}