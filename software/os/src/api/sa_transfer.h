#ifndef PSC_SA_TRANSFER_H
#define PSC_SA_TRANSFER_H
/* SYS_SA_RUN: a5 bit0=signed; bit31 enables a6 profile output (optional).
   Legacy callers pass only 0/1 and a6 is never inspected for them. */
#define PSC_SA_PROFILE_FLAG 0x80000000u
typedef struct {
    int valid;
    unsigned copy_in_us, execute_us, copy_out_us;
} psc_sa_profile_t;
#endif
