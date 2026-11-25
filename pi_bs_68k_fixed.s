| pi_bs_68k_fixed.s - Verified Overflow-Free Motorola 68060 Chudnovsky Pi Solver (GAS syntax)
    .text
    .even

    .equ DEFAULT_DIGITS, 101
    .equ C3_OVER_24_HI,  0x0026DD04       | Upper 32 bits of 640320^3 / 24
    .equ C3_OVER_24_LO,  0x1D878000       | Lower 32 bits of 640320^3 / 24

    .section .rodata
    .even
fmt_out:
    .asciz "Approximation of pi with %lu decimal places:\n%.*Ff\n"
    .even

    .text
    .globl binary_split
    .type binary_split, @function

| void binary_split(uint32_t a, uint32_t b, mpz_ptr P, mpz_ptr Q, mpz_ptr T)
binary_split:
    movem.l %d2-%d4/%a2-%a5, -(%sp)       | 7 regs = 28 bytes; args at 32(%sp)..48(%sp)
    move.l  32(%sp), %d2                  | %d2 = a
    move.l  36(%sp), %d3                  | %d3 = b
    move.l  40(%sp), %a2                  | %a2 = P
    move.l  44(%sp), %a3                  | %a3 = Q
    move.l  48(%sp), %a4                  | %a4 = T

    move.l  %d3, %d0
    sub.l   %d2, %d0                      | %d0 = b - a
    cmp.l   #1, %d0
    jne     .Lbs_recurse

    | --- Base Case: b - a == 1 ---
    tst.l   %d2
    jne     .Lbs_base_nonzero

    | a == 0: P = 1, Q = 1, T = 13591409
    move.l  #1, -(%sp)
    move.l  %a2, -(%sp)
    jsr     __gmpz_set_ui
    addq.l  #8, %sp

    move.l  #1, -(%sp)
    move.l  %a3, -(%sp)
    jsr     __gmpz_set_ui
    addq.l  #8, %sp

    move.l  #13591409, -(%sp)
    move.l  %a4, -(%sp)
    jsr     __gmpz_set_ui
    addq.l  #8, %sp

    movem.l (%sp)+, %d2-%d4/%a2-%a5
    rts

.Lbs_base_nonzero:
    sub.l   #16, %sp
    move.l  %sp, %a5                      | %a5 = &tmp

    clr.l   (%a5)
    clr.l   4(%a5)
    clr.l   8(%a5)

    move.l  %a5, -(%sp)
    jsr     __gmpz_init
    addq.l  #4, %sp

    | P = -(6a - 5)(2a - 1)(6a - 1) via mpz_t
    move.l  %d2, -(%sp)
    move.l  %a2, -(%sp)
    jsr     __gmpz_set_ui
    addq.l  #8, %sp

    move.l  #6, -(%sp)
    move.l  %a2, -(%sp)
    move.l  %a2, -(%sp)
    jsr     __gmpz_mul_ui
    add.l   #12, %sp

    move.l  #5, -(%sp)
    move.l  %a2, -(%sp)
    move.l  %a2, -(%sp)
    jsr     __gmpz_sub_ui
    add.l   #12, %sp

    | tmp = 2a - 1
    move.l  %d2, -(%sp)
    move.l  %a5, -(%sp)
    jsr     __gmpz_set_ui
    addq.l  #8, %sp

    move.l  #2, -(%sp)
    move.l  %a5, -(%sp)
    move.l  %a5, -(%sp)
    jsr     __gmpz_mul_ui
    add.l   #12, %sp

    move.l  #1, -(%sp)
    move.l  %a5, -(%sp)
    move.l  %a5, -(%sp)
    jsr     __gmpz_sub_ui
    add.l   #12, %sp

    move.l  %a5, -(%sp)
    move.l  %a2, -(%sp)
    move.l  %a2, -(%sp)
    jsr     __gmpz_mul
    add.l   #12, %sp

    | tmp = 6a - 1
    move.l  %d2, -(%sp)
    move.l  %a5, -(%sp)
    jsr     __gmpz_set_ui
    addq.l  #8, %sp

    move.l  #6, -(%sp)
    move.l  %a5, -(%sp)
    move.l  %a5, -(%sp)
    jsr     __gmpz_mul_ui
    add.l   #12, %sp

    move.l  #1, -(%sp)
    move.l  %a5, -(%sp)
    move.l  %a5, -(%sp)
    jsr     __gmpz_sub_ui
    add.l   #12, %sp

    move.l  %a5, -(%sp)
    move.l  %a2, -(%sp)
    move.l  %a2, -(%sp)
    jsr     __gmpz_mul
    add.l   #12, %sp

    move.l  %a2, -(%sp)
    move.l  %a2, -(%sp)
    jsr     __gmpz_neg
    addq.l  #8, %sp

    | Q = a^3 * (640320^3 / 24)
    move.l  %d2, -(%sp)
    move.l  %a3, -(%sp)
    jsr     __gmpz_set_ui
    addq.l  #8, %sp

    move.l  #3, -(%sp)
    move.l  %a3, -(%sp)
    move.l  %a3, -(%sp)
    jsr     __gmpz_pow_ui
    add.l   #12, %sp

    | Construct 64-bit C3_OVER_24 safely using 32-bit immediate moves
    move.l  #C3_OVER_24_HI, -(%sp)
    move.l  %a5, -(%sp)
    jsr     __gmpz_set_ui
    addq.l  #8, %sp

    move.l  #32, -(%sp)
    move.l  %a5, -(%sp)
    move.l  %a5, -(%sp)
    jsr     __gmpz_mul_2exp
    add.l   #12, %sp

    move.l  #C3_OVER_24_LO, -(%sp)
    move.l  %a5, -(%sp)
    move.l  %a5, -(%sp)
    jsr     __gmpz_add_ui
    add.l   #12, %sp

    move.l  %a5, -(%sp)
    move.l  %a3, -(%sp)
    move.l  %a3, -(%sp)
    jsr     __gmpz_mul
    add.l   #12, %sp

    | T = P * (13591409 + 545140134 * a)
    move.l  %d2, -(%sp)
    move.l  %a5, -(%sp)
    jsr     __gmpz_set_ui
    addq.l  #8, %sp

    move.l  #545140134, -(%sp)
    move.l  %a5, -(%sp)
    move.l  %a5, -(%sp)
    jsr     __gmpz_mul_ui
    add.l   #12, %sp

    move.l  #13591409, -(%sp)
    move.l  %a5, -(%sp)
    move.l  %a5, -(%sp)
    jsr     __gmpz_add_ui
    add.l   #12, %sp

    move.l  %a5, -(%sp)
    move.l  %a2, -(%sp)
    move.l  %a4, -(%sp)
    jsr     __gmpz_mul
    add.l   #12, %sp

    move.l  %a5, -(%sp)
    jsr     __gmpz_clear
    addq.l  #4, %sp

    add.l   #16, %sp
    movem.l (%sp)+, %d2-%d4/%a2-%a5
    rts

.Lbs_recurse:
    sub.l   #48, %sp
    move.l  %sp, %a5                      | P2=0(%a5), Q2=16(%a5), T2=32(%a5)

    move.l  %a5, %a0
    moveq   #11, %d0
.Lbs_zero:
    clr.l   (%a0)+
    dbf     %d0, .Lbs_zero

    pea     32(%a5)
    jsr     __gmpz_init
    pea     16(%a5)
    jsr     __gmpz_init
    move.l  %a5, -(%sp)
    jsr     __gmpz_init
    add.l   #12, %sp

    | %d4 = m = (a + b) >> 1
    move.l  %d2, %d4
    add.l   %d3, %d4
    lsr.l   #1, %d4

    | Left half: binary_split(a, m, P, Q, T)
    move.l  %a4, -(%sp)
    move.l  %a3, -(%sp)
    move.l  %a2, -(%sp)
    move.l  %d4, -(%sp)
    move.l  %d2, -(%sp)
    jsr     binary_split
    add.l   #20, %sp

    | Right half: binary_split(m, b, &P2, &Q2, &T2)
    pea     32(%a5)
    pea     16(%a5)
    move.l  %a5, -(%sp)
    move.l  %d3, -(%sp)
    move.l  %d4, -(%sp)
    jsr     binary_split
    add.l   #20, %sp

    | Combine: T = T*Q2 + P*T2; P = P*P2; Q = Q*Q2
    pea     16(%a5)
    move.l  %a4, -(%sp)
    move.l  %a4, -(%sp)
    jsr     __gmpz_mul
    add.l   #12, %sp

    pea     32(%a5)
    move.l  %a2, -(%sp)
    pea     32(%a5)
    jsr     __gmpz_mul
    add.l   #12, %sp

    pea     32(%a5)
    move.l  %a4, -(%sp)
    move.l  %a4, -(%sp)
    jsr     __gmpz_add
    add.l   #12, %sp

    move.l  %a5, -(%sp)
    move.l  %a2, -(%sp)
    move.l  %a2, -(%sp)
    jsr     __gmpz_mul
    add.l   #12, %sp

    pea     16(%a5)
    move.l  %a3, -(%sp)
    move.l  %a3, -(%sp)
    jsr     __gmpz_mul
    add.l   #12, %sp

    pea     32(%a5)
    jsr     __gmpz_clear
    pea     16(%a5)
    jsr     __gmpz_clear
    move.l  %a5, -(%sp)
    jsr     __gmpz_clear
    add.l   #12, %sp

    add.l   #48, %sp
    movem.l (%sp)+, %d2-%d4/%a2-%a5
    rts
    .size binary_split, .-binary_split


    .globl main
    .type main, @function
main:
    movem.l %d2-%d3/%a2, -(%sp)           | 3 regs = 12 bytes; argc at 112(%sp), argv at 116(%sp)
    sub.l   #96, %sp
    move.l  %sp, %a2

    move.l  #DEFAULT_DIGITS, %d2          | %d2 = digits
    move.l  112(%sp), %d0                 | argc
    cmp.l   #1, %d0
    jle     .Lmain_zero

    move.l  116(%sp), %a0                 | argv
    move.l  4(%a0), -(%sp)                | argv
    jsr     atoi
    addq.l  #4, %sp
    tst.l   %d0
    jle     .Lmain_zero
    move.l  %d0, %d2

.Lmain_zero:
    move.l  %a2, %a0
    moveq   #23, %d0
.Lzero_loop:
    clr.l   (%a0)+
    dbf     %d0, .Lzero_loop

    pea     32(%a2)
    jsr     __gmpz_init
    pea     16(%a2)
    jsr     __gmpz_init
    move.l  %a2, -(%sp)
    jsr     __gmpz_init
    add.l   #12, %sp

    | N_terms = (digits / 14) + 2 using 68060-safe 32x32->64 mulu.l reciprocal
    move.l  #0x92492493, %d0
    mulu.l  %d2, %d1:%d0
    lsr.l   #3, %d1
    addq.l  #2, %d1
    move.l  %d1, %d3                      | %d3 = N_terms

    | binary_split(0, N_terms, &P, &Q, &T)
    pea     32(%a2)
    pea     16(%a2)
    move.l  %a2, -(%sp)
    move.l  %d3, -(%sp)
    clr.l   -(%sp)
    jsr     binary_split
    add.l   #20, %sp

    | Set floating-point precision: digits * 4 + 256 bits
    move.l  %d2, %d0
    lsl.l   #2, %d0
    add.l   #256, %d0
    move.l  %d0, -(%sp)
    jsr     __gmpf_set_default_prec
    addq.l  #4, %sp

    pea     80(%a2)
    jsr     __gmpf_init
    pea     64(%a2)
    jsr     __gmpf_init
    pea     48(%a2)
    jsr     __gmpf_init
    add.l   #12, %sp

    pea     16(%a2)
    pea     64(%a2)
    jsr     __gmpf_set_z
    addq.l  #8, %sp

    pea     32(%a2)
    pea     80(%a2)
    jsr     __gmpf_set_z
    addq.l  #8, %sp

    move.l  #10005, -(%sp)
    pea     48(%a2)
    jsr     __gmpf_sqrt_ui
    addq.l  #8, %sp

    move.l  #426880, -(%sp)
    pea     48(%a2)
    pea     48(%a2)
    jsr     __gmpf_mul_ui
    add.l   #12, %sp

    pea     64(%a2)
    pea     48(%a2)
    pea     48(%a2)
    jsr     __gmpf_mul
    add.l   #12, %sp

    pea     80(%a2)
    pea     48(%a2)
    pea     48(%a2)
    jsr     __gmpf_div
    add.l   #12, %sp

    | Print result
    pea     48(%a2)
    move.l  %d2, -(%sp)
    move.l  %d2, -(%sp)
    pea     fmt_out
    jsr     __gmp_printf
    add.l   #16, %sp

    | Cleanup
    pea     32(%a2)
    jsr     __gmpz_clear
    pea     16(%a2)
    jsr     __gmpz_clear
    move.l  %a2, -(%sp)
    jsr     __gmpz_clear
    add.l   #12, %sp

    pea     80(%a2)
    jsr     __gmpf_clear
    pea     64(%a2)
    jsr     __gmpf_clear
    pea     48(%a2)
    jsr     __gmpf_clear
    add.l   #12, %sp

    add.l   #96, %sp
    movem.l (%sp)+, %d2-%d3/%a2
    moveq   #0, %d0
    rts
    .size main, .-main
    .section .note.GNU-stack,"",@progbits

