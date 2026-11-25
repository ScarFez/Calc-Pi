; pi_bs_mt.asm - Multi-Threaded Overflow-Free AMD64 Chudnovsky Pi Solver (NASM)
default rel
bits 64

%define DEFAULT_DIGITS 101
%define NUM_THREADS    4
%define C3_OVER_24     10939058860032000

struc ThreadArg
    .a:     resq 1
    .b:     resq 1
    .pad:   resq 2
    .P:     resb 32
    .Q:     resb 32
    .T:     resb 32
endstruc

section .rodata
    align 16
    fmt_out db "Approximation of pi with %lu decimal places:", 10, "%.*Ff", 10, 0

section .text
    global main
    global binary_split
    global worker_thread

    extern atoi
    extern pthread_create
    extern pthread_join
    extern __gmpz_init
    extern __gmpz_clear
    extern __gmpz_set_ui
    extern __gmpz_mul
    extern __gmpz_mul_ui
    extern __gmpz_sub_ui
    extern __gmpz_add
    extern __gmpz_add_ui
    extern __gmpz_neg
    extern __gmpz_pow_ui
    extern __gmpf_set_default_prec
    extern __gmpf_init
    extern __gmpf_clear
    extern __gmpf_set_z
    extern __gmpf_sqrt_ui
    extern __gmpf_mul
    extern __gmpf_mul_ui
    extern __gmpf_div
    extern __gmp_printf

; void binary_split(uint64_t a, uint64_t b, mpz_ptr P, mpz_ptr Q, mpz_ptr T)
binary_split:
    mov     rax, rsi
    sub     rax, rdi
    cmp     rax, 1
    jne     .recurse

    test    rdi, rdi
    jnz     .base_nonzero

    ; a == 0: P = 1, Q = 1, T = 13591409
    push    r12
    push    r13
    push    r14
    sub     rsp, 8
    mov     r12, rdx
    mov     r13, rcx
    mov     r14, r8

    mov     rdi, r12
    mov     esi, 1
    call    __gmpz_set_ui wrt ..plt

    mov     rdi, r13
    mov     esi, 1
    call    __gmpz_set_ui wrt ..plt

    mov     rdi, r14
    mov     esi, 13591409
    call    __gmpz_set_ui wrt ..plt

    add     rsp, 8
    pop     r14
    pop     r13
    pop     r12
    ret

.base_nonzero:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 8
    and     rsp, -32
    sub     rsp, 32
    mov     rbx, rsp

    mov     r12, rdi
    mov     r13, rdx
    mov     r14, rcx
    mov     r15, r8

    vpxor   ymm0, ymm0, ymm0
    vmovdqa [rbx], ymm0
    vzeroupper

    mov     rdi, rbx
    call    __gmpz_init wrt ..plt

    ; P = -(6a - 5)(2a - 1)(6a - 1)
    mov     rdi, r13
    mov     rsi, r12
    call    __gmpz_set_ui wrt ..plt
    mov     rdi, r13
    mov     rsi, r13
    mov     edx, 6
    call    __gmpz_mul_ui wrt ..plt
    mov     rdi, r13
    mov     rsi, r13
    mov     edx, 5
    call    __gmpz_sub_ui wrt ..plt

    mov     rdi, rbx
    mov     rsi, r12
    call    __gmpz_set_ui wrt ..plt
    mov     rdi, rbx
    mov     rsi, rbx
    mov     edx, 2
    call    __gmpz_mul_ui wrt ..plt
    mov     rdi, rbx
    mov     rsi, rbx
    mov     edx, 1
    call    __gmpz_sub_ui wrt ..plt

    mov     rdi, r13
    mov     rsi, r13
    mov     rdx, rbx
    call    __gmpz_mul wrt ..plt

    mov     rdi, rbx
    mov     rsi, r12
    call    __gmpz_set_ui wrt ..plt
    mov     rdi, rbx
    mov     rsi, rbx
    mov     edx, 6
    call    __gmpz_mul_ui wrt ..plt
    mov     rdi, rbx
    mov     rsi, rbx
    mov     edx, 1
    call    __gmpz_sub_ui wrt ..plt

    mov     rdi, r13
    mov     rsi, r13
    mov     rdx, rbx
    call    __gmpz_mul wrt ..plt

    mov     rdi, r13
    mov     rsi, r13
    call    __gmpz_neg wrt ..plt

    ; Q = a^3 * (640320^3 / 24)
    mov     rdi, r14
    mov     rsi, r12
    call    __gmpz_set_ui wrt ..plt
    mov     rdi, r14
    mov     rsi, r14
    mov     edx, 3
    call    __gmpz_pow_ui wrt ..plt
    mov     rdi, r14
    mov     rsi, r14
    mov     rdx, C3_OVER_24
    call    __gmpz_mul_ui wrt ..plt
    ; T = P * (13591409 + 545140134 * a)
    mov     rdi, rbx
    mov     rsi, r12
    call    __gmpz_set_ui wrt ..plt
    mov     rdi, rbx
    mov     rsi, rbx
    mov     edx, 545140134
    call    __gmpz_mul_ui wrt ..plt
    mov     rdi, rbx
    mov     rsi, rbx
    mov     edx, 13591409
    call    __gmpz_add_ui wrt ..plt

    mov     rdi, r15
    mov     rsi, r13
    mov     rdx, rbx
    call    __gmpz_mul wrt ..plt

    mov     rdi, rbx
    call    __gmpz_clear wrt ..plt

    lea     rsp, [rbp - 40]
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

.recurse:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 8
    and     rsp, -32
    sub     rsp, 128
    mov     rbx, rsp

    mov     r12, rdi
    mov     r13, rsi
    mov     r14, rdx
    mov     r15, rcx
    mov     [rbx + 96], r8

    vpxor   ymm0, ymm0, ymm0
    vmovdqa [rbx + 0],  ymm0
    vmovdqa [rbx + 32], ymm0
    vmovdqa [rbx + 64], ymm0
    vzeroupper

    lea     rdi, [rbx + 0]
    call    __gmpz_init wrt ..plt
    lea     rdi, [rbx + 32]
    call    __gmpz_init wrt ..plt
    lea     rdi, [rbx + 64]
    call    __gmpz_init wrt ..plt

    lea     rax, [r12 + r13]
    shr     rax, 1
    mov     [rbx + 104], rax

    mov     rdi, r12
    mov     rsi, rax
    mov     rdx, r14
    mov     rcx, r15
    mov     r8,  [rbx + 96]
    call    binary_split

    mov     rdi, [rbx + 104]
    mov     rsi, r13
    lea     rdx, [rbx + 0]
    lea     rcx, [rbx + 32]
    lea     r8,  [rbx + 64]
    call    binary_split

    mov     rdi, [rbx + 96]
    mov     rsi, rdi
    lea     rdx, [rbx + 32]
    call    __gmpz_mul wrt ..plt

    lea     rdi, [rbx + 64]
    mov     rsi, r14
    mov     rdx, rdi
    call    __gmpz_mul wrt ..plt

    mov     rdi, [rbx + 96]
    mov     rsi, rdi
    lea     rdx, [rbx + 64]
    call    __gmpz_add wrt ..plt

    mov     rdi, r14
    mov     rsi, rdi
    lea     rdx, [rbx + 0]
    call    __gmpz_mul wrt ..plt

    mov     rdi, r15
    mov     rsi, rdi
    lea     rdx, [rbx + 32]
    call    __gmpz_mul wrt ..plt

    lea     rdi, [rbx + 0]
    call    __gmpz_clear wrt ..plt
    lea     rdi, [rbx + 32]
    call    __gmpz_clear wrt ..plt
    lea     rdi, [rbx + 64]
    call    __gmpz_clear wrt ..plt

    lea     rsp, [rbp - 40]
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; void *worker_thread(void *arg)
worker_thread:
    push    rbx
    mov     rbx, rdi
    mov     rdi, [rbx + ThreadArg.a]
    mov     rsi, [rbx + ThreadArg.b]
    cmp     rdi, rsi
    jge     .empty

    lea     rdx, [rbx + ThreadArg.P]
    lea     rcx, [rbx + ThreadArg.Q]
    lea     r8,  [rbx + ThreadArg.T]
    call    binary_split
    jmp     .done

.empty:
    lea     rdi, [rbx + ThreadArg.P]
    mov     esi, 1
    call    __gmpz_set_ui wrt ..plt
    lea     rdi, [rbx + ThreadArg.Q]
    mov     esi, 1
    call    __gmpz_set_ui wrt ..plt
    lea     rdi, [rbx + ThreadArg.T]
    xor     esi, esi
    call    __gmpz_set_ui wrt ..plt

.done:
    xor     eax, eax
    pop     rbx
    ret

; void merge_branch(ThreadArg *dst, ThreadArg *src)
merge_branch:
    push    r12
    push    r13
    sub     rsp, 8
    mov     r12, rdi
    mov     r13, rsi

    lea     rdi, [r12 + ThreadArg.T]
    mov     rsi, rdi
    lea     rdx, [r13 + ThreadArg.Q]
    call    __gmpz_mul wrt ..plt
    lea     rdi, [r13 + ThreadArg.T]
    lea     rsi, [r12 + ThreadArg.P]
    mov     rdx, rdi
    call    __gmpz_mul wrt ..plt

    lea     rdi, [r12 + ThreadArg.T]
    mov     rsi, rdi
    lea     rdx, [r13 + ThreadArg.T]
    call    __gmpz_add wrt ..plt

    lea     rdi, [r12 + ThreadArg.P]
    mov     rsi, rdi
    lea     rdx, [r13 + ThreadArg.P]
    call    __gmpz_mul wrt ..plt

    lea     rdi, [r12 + ThreadArg.Q]
    mov     rsi, rdi
    lea     rdx, [r13 + ThreadArg.Q]
    call    __gmpz_mul wrt ..plt

    add     rsp, 8
    pop     r13
    pop     r12
    ret

main:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 8
    and     rsp, -32
    sub     rsp, 640
    mov     rbx, rsp

    mov     r12, DEFAULT_DIGITS
    cmp     rdi, 1
    jle     .zero_mem
    mov     rdi, [rsi + 8]
    call    atoi wrt ..plt
    test    eax, eax
    jle     .zero_mem
    movsxd  r12, eax

.zero_mem:
    vpxor   ymm0, ymm0, ymm0
    xor     ecx, ecx
.zero_loop:
    vmovdqa [rbx + rcx], ymm0
    add     ecx, 32
    cmp     ecx, 640
    jl      .zero_loop
    vzeroupper

    mov     rax, r12
    xor     edx, edx
    mov     ecx, 14
    div     rcx
    lea     r13, [rax + 2]

    xor     r14d, r14d
.init_threads:
    mov     rax, r14
    shl     rax, 7
    lea     rcx, [rbx + rax]

    mov     rax, r13
    mul     r14
    shr     rax, 2
    mov     [rcx + ThreadArg.a], rax

    lea     rdx, [r14 + 1]
    mov     rax, r13
    mul     rdx
    shr     rax, 2
    mov     [rcx + ThreadArg.b], rax

    push    rcx
    sub     rsp, 8
    lea     rdi, [rcx + ThreadArg.P]
    call    __gmpz_init wrt ..plt
    mov     rcx, [rsp + 8]
    lea     rdi, [rcx + ThreadArg.Q]
    call    __gmpz_init wrt ..plt
    mov     rcx, [rsp + 8]
    lea     rdi, [rcx + ThreadArg.T]
    call    __gmpz_init wrt ..plt
    add     rsp, 8
    pop     rcx

    lea     rdi, [rbx + 512 + r14 * 8]
    xor     esi, esi
    lea     rdx, [worker_thread]
    call    pthread_create wrt ..plt

    inc     r14
    cmp     r14, NUM_THREADS
    jl      .init_threads

    xor     r14d, r14d
.join_loop:
    mov     rdi, [rbx + 512 + r14 * 8]
    xor     esi, esi
    call    pthread_join wrt ..plt
    inc     r14
    cmp     r14, NUM_THREADS
    jl      .join_loop

    lea     rdi, [rbx + 0]
    lea     rsi, [rbx + 128]
    call    merge_branch

    lea     rdi, [rbx + 256]
    lea     rsi, [rbx + 384]
    call    merge_branch

    lea     rdi, [rbx + 0]
    lea     rsi, [rbx + 256]
    call    merge_branch

    lea     rdi, [r12 * 4 + 256]
    call    __gmpf_set_default_prec wrt ..plt

    lea     rdi, [rbx + 544]
    call    __gmpf_init wrt ..plt
    lea     rdi, [rbx + 576]
    call    __gmpf_init wrt ..plt
    lea     rdi, [rbx + 608]
    call    __gmpf_init wrt ..plt

    lea     rdi, [rbx + 576]
    lea     rsi, [rbx + ThreadArg.Q]
    call    __gmpf_set_z wrt ..plt

    lea     rdi, [rbx + 608]
    lea     rsi, [rbx + ThreadArg.T]
    call    __gmpf_set_z wrt ..plt

    lea     rdi, [rbx + 544]
    mov     esi, 10005
    call    __gmpf_sqrt_ui wrt ..plt

    lea     rdi, [rbx + 544]
    mov     rsi, rdi
    mov     edx, 426880
    call    __gmpf_mul_ui wrt ..plt

    lea     rdi, [rbx + 544]
    mov     rsi, rdi
    lea     rdx, [rbx + 576]
    call    __gmpf_mul wrt ..plt

    lea     rdi, [rbx + 544]
    mov     rsi, rdi
    lea     rdx, [rbx + 608]
    call    __gmpf_div wrt ..plt

    lea     rdi, [fmt_out]
    mov     rsi, r12
    mov     rdx, r12
    lea     rcx, [rbx + 544]
    xor     eax, eax
    call    __gmp_printf wrt ..plt
    xor     r14d, r14d
.cleanup:
    mov     rax, r14
    shl     rax, 7
    lea     rcx, [rbx + rax]
    push    rcx
    sub     rsp, 8
    lea     rdi, [rcx + ThreadArg.P]
    call    __gmpz_clear wrt ..plt
    mov     rcx, [rsp + 8]
    lea     rdi, [rcx + ThreadArg.Q]
    call    __gmpz_clear wrt ..plt
    mov     rcx, [rsp + 8]
    lea     rdi, [rcx + ThreadArg.T]
    call    __gmpz_clear wrt ..plt
    add     rsp, 8
    pop     rcx

    inc     r14
    cmp     r14, NUM_THREADS
    jl      .cleanup

    lea     rdi, [rbx + 544]
    call    __gmpf_clear wrt ..plt
    lea     rdi, [rbx + 576]
    call    __gmpf_clear wrt ..plt
    lea     rdi, [rbx + 608]
    call    __gmpf_clear wrt ..plt

    lea     rsp, [rbp - 32]
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    xor     eax, eax
    ret

section .note.GNU-stack noalloc noexec nowrite progbits

