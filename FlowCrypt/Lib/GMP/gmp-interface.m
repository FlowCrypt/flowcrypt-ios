#include "gmp.h"
#include <stdio.h>

const char* c_gmp_mod_pow(const char* base, const char* exponent, const char* modulo) {
    mpz_t mpz_base, mpz_exponent, mpz_modulo, mpz_result;
    mpz_inits (mpz_base, mpz_exponent, mpz_modulo, mpz_result, NULL);
    if (mpz_set_str (mpz_base, base, 10) != 0) {
        printf("Invalid base bigint");
        return "";
    }
    if (mpz_set_str (mpz_exponent, exponent, 10) != 0) {
        printf("Invalid exponent bigint");
        return "";
    }
    if (mpz_set_str (mpz_modulo, modulo, 10) != 0) {
        printf("Invalid modulo bigint");
        return "";
    }
    // mpz_result = mpz_base ^ mpz_exponent mod mpz_modulo
    mpz_powm (mpz_result, mpz_base, mpz_exponent, mpz_modulo);
    return mpz_get_str (NULL, 10, mpz_result);
}
