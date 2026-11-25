from decimal import Decimal, getcontext

# Set precision high enough for 101 decimal places plus a safety buffer
PRECISION = 120
getcontext().prec = PRECISION


def chudnovsky_pi():
    C = Decimal(426880) * Decimal(10005).sqrt()

    # k = 0 initial values
    M = Decimal(1)          # Multinomial term: (-1)^k * (6k)! / ((3k)! * (k!)^3)
    L = Decimal(13591409)   # Linear term: 545140134k + 13591409
    X = Decimal(1)          # Exponential term: (640320^3)^k

    pi_sum = L              # For k = 0, (M * L) / X = (1 * 13591409) / 1
    k = 1
    threshold = Decimal(10) ** (-PRECISION)

    while True:
        # Update M_k from M_{k-1} (includes the factor of 24)
        numerator = Decimal(24 * (6 * k - 5) * (2 * k - 1) * (6 * k - 1))
        denominator = Decimal(k ** 3)
        M = -M * numerator / denominator

        # Update L_k and X_k
        L += 545140134
        X *= 262537412640768000  # 640320^3

        term = (M * L) / X
        pi_sum += term

        if abs(term) < threshold:
            break
        k += 1

    # Divide C by the sum to get pi
    return C / pi_sum


if __name__ == "__main__":
    pi_value = chudnovsky_pi()
    print(f"Approximation of π with 101 decimal places:\\n{pi_value:.101f}")