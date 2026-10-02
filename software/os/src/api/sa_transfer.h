#ifndef PSC_SA_TRANSFER_H
#define PSC_SA_TRANSFER_H
/* SYS_SA_RUN: a5 bit0=signed; bit31 enables a6 profile output (optional).
   Legacy callers pass only 0/1 and a6 is never inspected for them. */
/* With RECT_FLAG, a4 packs K[7:0], N[15:8], M[23:16].
   Without it, a4 remains the legacy square dimension. */
#define PSC_SA_RECT_FLAG 0x40000000u
#define PSC_SA_DIMS(m,k,n) (((m) << 16) | ((n) << 8) | (k))
#define PSC_SA_PROFILE_FLAG 0x80000000u
typedef struct {
    int valid;
    unsigned copy_in_us, execute_us, copy_out_us;
} psc_sa_profile_t;
#endif
