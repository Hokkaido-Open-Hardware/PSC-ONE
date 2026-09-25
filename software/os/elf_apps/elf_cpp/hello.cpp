#include "syscall.hpp"

// Existing start.S calls user_main and passes its result to SYS_EXIT.
extern "C" int user_main()
{
    psc::print("Hello from PSC-ONE ELF C++!\n");
    return 0;
}
