/* ANSI C (C89) Chudnovsky Pi solver using GMP with verified precision */

#include <stdio.h>
#include <stdlib.h>
#include <gmp.h>

#define DEFAULT_DIGITS 101

void calculate_pi(int digits) {
    mpf_t C, M, L, X, X_step, pi_sum, term, abs_term, threshold, num, den, tmp;
    mp_bitcnt_t prec_bits;
    unsigned long k;

    /* ~3.322 bits per decimal digit; 4 bits/digit + 256 guard bits */
    prec_bits = (mp_bitcnt_t)digits * 4UL + 256UL;
    mpf_set_default_prec(prec_bits);

    mpf_init(C);
    mpf_init(M);
    mpf_init(L);
    mpf_init(X);
    mpf_init(X_step);
    mpf_init(pi_sum);
    mpf_init(term);
    mpf_init(abs_term);
    mpf_init(threshold);
    mpf_init(num);
    mpf_init(den);
    mpf_init(tmp);

    /* C = 426880 * sqrt(10005) */
    mpf_sqrt_ui(C, 10005UL);
    mpf_mul_ui(C, C, 426880UL);

    /* k = 0 initial values */
    mpf_set_ui(M, 1UL);
    mpf_set_ui(L, 13591409UL);
    mpf_set_ui(X, 1UL);

    /* X_step = 640320^3 = 262537412640768000 (computed from exact integers) */
    mpf_set_ui(X_step, 640320UL);
    mpf_pow_ui(X_step, X_step, 3UL);

    /* pi_sum = L (since for k = 0, M * L / X = 13591409) */
    mpf_set(pi_sum, L);

    /* threshold = 10^(-digits - 20) */
    mpf_set_ui(threshold, 10UL);
    mpf_pow_ui(threshold, threshold, (unsigned long)(digits + 20));
    mpf_ui_div(threshold, 1UL, threshold);

    k = 1UL;
    while (1) {
        /* Compute numerator safely in GMP: 24 * (6k - 5) * (2k - 1) * (6k - 1) */
        mpf_set_ui(num, 24UL);

        mpf_set_ui(tmp, k);
        mpf_mul_ui(tmp, tmp, 6UL);
        mpf_sub_ui(tmp, tmp, 5UL);
        mpf_mul(num, num, tmp);

        mpf_set_ui(tmp, k);
        mpf_mul_ui(tmp, tmp, 2UL);
        mpf_sub_ui(tmp, tmp, 1UL);
        mpf_mul(num, num, tmp);

        mpf_set_ui(tmp, k);
        mpf_mul_ui(tmp, tmp, 6UL);
        mpf_sub_ui(tmp, tmp, 1UL);
        mpf_mul(num, num, tmp);

        /* Compute denominator safely in GMP: k^3 */
        mpf_set_ui(den, k);
        mpf_pow_ui(den, den, 3UL);

        /* Update M_k = -M_{k-1} * num / den */
        mpf_mul(M, M, num);
        mpf_div(M, M, den);
        mpf_neg(M, M);

        /* Update L_k = L_{k-1} + 545140134 */
        mpf_add_ui(L, L, 545140134UL);

        /* Update X_k = X_{k-1} * 640320^3 */
        mpf_mul(X, X, X_step);

        /* term = (M * L) / X */
        mpf_mul(term, M, L);
        mpf_div(term, term, X);
        mpf_add(pi_sum, pi_sum, term);

        /* Check convergence: break if |term| < threshold */
        mpf_abs(abs_term, term);
        if (mpf_cmp(abs_term, threshold) < 0) {
            break;
        }

        k++;
    }

    /* pi = C / pi_sum */
    mpf_div(pi_sum, C, pi_sum);

    /* Print formatted to exact decimal places */
    gmp_printf("Approximation of pi with %d decimal places:\n%.*Ff\n",
               digits, digits, pi_sum);

    /* Clean up all GMP variables */
    mpf_clear(C);
    mpf_clear(M);
    mpf_clear(L);
    mpf_clear(X);
    mpf_clear(X_step);
    mpf_clear(pi_sum);
    mpf_clear(term);
    mpf_clear(abs_term);
    mpf_clear(threshold);
    mpf_clear(num);
    mpf_clear(den);
    mpf_clear(tmp);
}

int main(int argc, char *argv[]) {
    int digits_to_calculate = DEFAULT_DIGITS;

    if (argc > 1) {
        digits_to_calculate = atoi(argv[1]);
        if (digits_to_calculate <= 0) {
            digits_to_calculate = DEFAULT_DIGITS;
        }
    }

    calculate_pi(digits_to_calculate);
    return 0;
}