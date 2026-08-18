#ifndef PSC_ASSERT_H
#define PSC_ASSERT_H

#ifdef NDEBUG
#define assert(x) ((void)0)
#else
#define assert(x) do { if (!(x)) abort(); } while (0)
#endif

#endif
