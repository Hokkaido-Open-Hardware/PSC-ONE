#ifndef PSC_SA_QTILE_H
#define PSC_SA_QTILE_H
/* Extensions of SYS_SA_RUN. CAPS is read-only and issues no NPU command. */
#define PSC_SA_CAPS_FLAG 0x10000000u
#define PSC_SA_QTILE_FLAG 0x20000000u
#define PSC_SA_QBATCH_FLAG 0x20000001u
#define PSC_SA_CAP_QTILE 0x100u
#define PSC_SA_Q_MAX_K 2304u
/* Sixteen little-endian INT32 words; output is a separate user buffer.
   0..3 bias-input_zero*sum(real weights), 4..7 multiplier, 8..11 shift,
   12 output_zero, 13 min, 14 max, 15 reserved=0. */
typedef struct {
    int parameters[16];
    unsigned commands, read_bytes, write_bytes;
    unsigned copy_in_us, execute_us, copy_out_us;
    int valid;
} psc_sa_qtile_t;
/* Bounded synchronous batch: A[m][k], B[n/4][k][4], C[m][n].
   m=1..8, n=4/8, k=4..2304 (multiple of four). No user pointer reaches DMA.
   Each 4x4 completes its whole K before the next tile. Output is untouched
   on failure; completed_tiles describes device progress, not valid output.
   read_bytes counts logical NPU reads; copy_in_bytes counts staged A+B.
   Timing: execute includes CSR/polling, copy_out includes scratch gathering.
   Metadata validation/copies remain in the enclosing syscall wall time. */
#define PSC_SA_Q_BATCH_M 8u
#define PSC_SA_Q_BATCH_N 8u
typedef struct {
    unsigned m, k, n, reserved;
    int parameters[PSC_SA_Q_BATCH_N/4][16];
    unsigned commands, completed_tiles, read_bytes, write_bytes, copy_in_bytes;
    unsigned copy_in_us, execute_us, copy_out_us;
    int valid;
} psc_sa_qbatch_t;
#endif
