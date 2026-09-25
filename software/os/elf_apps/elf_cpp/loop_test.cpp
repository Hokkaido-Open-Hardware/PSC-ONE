#include "syscall.hpp"

// BSS is zeroed by the existing ELF loader. Volatile retains the loop at -O2.
static volatile unsigned int total;

extern "C" int user_main()
{
    if (total != 0) return 1;
    for (unsigned int i = 1; i <= 100; ++i) total += i;
    psc::print("Loop complete: sum(1..100) = ");
    psc::print_int(static_cast<int>(total));
    psc::print("\n");
    return total == 5050 ? 0 : 2;
}
