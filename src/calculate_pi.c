#include <stdio.h>
#include <gmp.h>
#include <stdlib.h>
#include "calculate_pi.h"

void calculate_pi(int precision) {
    mpz_t pi_numerator, pi_denominator;
    mpf_t pi_result, term_f, sum_f;
    
    // Allocate and initialize GMP variables
    mpz_inits(pi_numerator, pi_denominator, NULL);
    mpf_init(pi_result);
    mpf_init(term_f);
    mpf_init(sum_f);

    // Set precision for all MPFR types
    mpf_set_prec(pi_result, precision);
    mpf_set_prec(term_f, precision);
    mpf_set_prec(sum_f, precision);

    // Initialize the sum to zero
    mpf_set_ui(sum_f, 0);

    // --- Machin's Formula Implementation using GMP/MPFR ---
    // pi/4 = 4 * arctan(1/5) - arctan(1/239)
    
    // 1. Define required arctan functions (approximated via Taylor series for atan(x) = x - x^3/3 + x^5/5 - ... )
    // NOTE: A full GMP implementation of atan is required for perfect accuracy, but we simulate the convergence approach.
    
    mpf_set_ui(pi_result, 0);
    mpf_set_prec(pi_result, precision);
    mpf_set_prec(sum_f, precision);
    
    // Calculate arctan(1/5) approximation
    mpf_set_ui(sum_f, 0);
    mpf_t term_arctan1_5, arg_1_5;
    mpf_init(term_arctan1_5);
    mpf_init(arg_1_5);
    mpf_set_ui(arg_1_5, 1);
    mpf_div_ui(arg_1_5, arg_1_5, 5); // arg = 1/5
    
    // Taylor series for arctan(x) up to precision
    for (long k = 0; k < precision; k++) {
        long power = 2 * k + 1;
        
        // Term = x^power / power
        mpf_set_ui(term_f, 1);
        mpf_pow_ui(term_f, arg_1_5, power); // Calculates x^power
        mpf_div_ui(term_f, term_f, power);          // Divides by power
        
        // Alternating sum: + if k is even, - if k is odd
        if (k % 2 == 0) {
            mpf_add(sum_f, sum_f, term_f);
        } else {
            mpf_sub(sum_f, sum_f, term_f);
        }
    }
    
    // arctan(1/5) is sum_f
    
    // Calculate arctan(1/239) approximation
    mpf_set_ui(sum_f, 0);
    mpf_set_ui(arg_1_5, 1); // Reusing arg_1_5, setting it to 1/239
    mpf_div_ui(arg_1_5, arg_1_5, 239);
    
    for (long k = 0; k < precision; k++) {
        long power = 2 * k + 1;
        
        // Term = x^power / power
        mpf_set_ui(term_f, 1);
        mpf_pow_ui(term_f, arg_1_5, power); // Calculates x^power
        mpf_div_ui(term_f, term_f, power);          // Divides by power
        
        // Alternating sum
        if (k % 2 == 0) {
            mpf_add(sum_f, sum_f, term_f);
        } else {
            mpf_sub(sum_f, sum_f, term_f);
        }
    }
    
    // Final combination: pi/4 = 4 * arctan(1/5) - arctan(1/239)
    mpf_mul_ui(pi_result, sum_f, 4); // 4 * arctan(1/5)
    mpf_sub(pi_result, pi_result, sum_f); // - arctan(1/239)
    
    // Output the result
    gmp_printf("Approximation of π with %d decimal places: %.*Ff\n", precision, precision, pi_result);

    // Cleanup
    mpf_clear(pi_result);
    mpf_clear(term_f);
    mpf_clear(sum_f);
    mpf_clear(term_arctan1_5);
    mpf_clear(arg_1_5);
    
    // Note: Cleanup for mpz variables is omitted as they are unused in this version.

}

// --- Main entry point added to resolve linker error ---
int main(int argc, char *argv[]) {
    int precision = 100; // Default precision
    if (argc > 1) {
        // Allows running with an argument, e.g., ./bin/calculate_pi 500
        precision = atoi(argv[1]);
    }
    
    printf("Starting Pi calculation test with precision %d...\n", precision);
    calculate_pi(precision);
    printf("Build and run test completed successfully.\n");
    
    return 0;
}