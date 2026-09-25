#include "syscall.hpp"

// Volatile inputs keep the arithmetic in the executable at -O2.
static volatile int left = 21;
static volatile int right = 6;

extern "C" int user_main()
{
    const int a = left;
    const int b = right;
    const int sum = a + b;
    const int difference = a - b;
    const int product = a * b; // RV32IM: integer M-extension multiplication.
    psc::print("21 + 6 = ");
    psc::print_int(sum);
    psc::print("\n21 - 6 = ");
    psc::print_int(difference);
    psc::print("\n21 * 6 = ");
    psc::print_int(product);
    psc::print("\n");
    return (sum == 27 && difference == 15 && product == 126) ? 0 : 1;
}
