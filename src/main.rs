use rug::{ops::Pow, Float};
use std::env;

const DEFAULT_DIGITS: u32 = 101;

fn calculate_pi(digits: u32) {
    // ~3.322 bits per decimal digit; 4 bits/digit + 256 guard bits
    let prec_bits: u32 = digits * 4 + 256;

    // C = 426880 * sqrt(10005)
    let c = Float::with_val(prec_bits, 10005).sqrt() * 426880;

    // k = 0 initial values
    let mut m = Float::with_val(prec_bits, 1);
    let mut l = Float::with_val(prec_bits, 13591409);
    let mut x = Float::with_val(prec_bits, 1);

    // X_step = 640320^3 = 262537412640768000
    let x_step = Float::with_val(prec_bits, 640320).pow(3);

    // pi_sum = L (since for k = 0, M * L / X = 13591409)
    let mut pi_sum = l.clone();

    // threshold = 10^(-digits - 20)
    let threshold = Float::with_val(prec_bits, 1)
        / Float::with_val(prec_bits, 10).pow(digits + 20);

    let mut k: u64 = 1;
    loop {
        // Compute numerator safely in arbitrary precision: 24 * (6k - 5) * (2k - 1) * (6k - 1)
        let k_f = Float::with_val(prec_bits, k);
        let num = Float::with_val(prec_bits, 24)
            * (Float::with_val(prec_bits, &k_f * 6) - 5)
            * (Float::with_val(prec_bits, &k_f * 2) - 1)
            * (Float::with_val(prec_bits, &k_f * 6) - 1);

        // Compute denominator safely: k^3
        let den = k_f.pow(3);

        // Update M_k = -M_{k-1} * num / den
        m = -m * num / den;

        // Update L_k = L_{k-1} + 545140134
        l += 545140134;

        // Update X_k = X_{k-1} * 640320^3
        x *= &x_step;

        // term = (M * L) / X
        let term = Float::with_val(prec_bits, &m * &l) / &x;
        pi_sum += &term;

        // Check convergence: break if |term| < threshold
        if term.abs() < threshold {
            break;
        }

        k += 1;
    }

    // pi = C / pi_sum
    let pi = c / pi_sum;

    // Print formatted to exact decimal places
    println!(
        "Approximation of pi with {} decimal places:\n{:.*}",
        digits, digits as usize, pi
    );
}

fn main() {
    let digits_to_calculate = env::args()
        .nth(1)
        .and_then(|arg| arg.parse::<u32>().ok())
        .filter(|&d| d > 0)
        .unwrap_or(DEFAULT_DIGITS);

    calculate_pi(digits_to_calculate);
}

