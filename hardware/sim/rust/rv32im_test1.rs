#![no_std]
#![no_main]
// PSC-ONE compact RV32IM test. rustc --target riscv32im-unknown-none-elf
// Same rust_tests.x linker script; all executable code and vectors in .text.start.
// The self-contained assembly section is padded to exactly 12288 bytes (3072 words).
// .org is a build-time size guard: assembly fails if this section exceeds 12 KiB.
// Verify the FINAL binary is <=16384 bytes (4096 words) after linking.
// Diagnostic RAM moved to 0x00700000..0x0070001f, stack top 0x00800000.
// PASS: 0x12345678. FAIL: 0xDEAD0000 | case number. EE01 handshake retained.
// Failure PIO32 frame: D00F0000, tag/value pairs, D00FFFFF, EE01, fail code.
// Tags D0010000..D0010007: case, instruction ID, A, B/immediate,
// expected, actual, final status, completed vector count.
// Full 32-bit payloads must be interpreted inside the frame (may equal EE01).
// IDs 1..18: ADD SUB SLL SLT SLTU XOR SRL SRA OR AND
//            MUL MULH MULHSU MULHU DIV DIVU REM REMU
// IDs 19..27: ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI
// IDs 28,29,30: LUI, AUIPC, x0 check.
// RR vectors check distinct rd, rd=rs1, rd=rs2 under ONE case ID.
// Failure returns the first incorrect result among those three layouts.
// Immediate cases use three immediate values, each with six operand patterns.
// Includes divide by zero and signed MIN/-1 overflow; no runtime oracle.
// Loads/stores/branches/CSR/fences are not explicitly tested.
// Total: 551 vectors; 1307 result comparisons on success.
use core::arch::global_asm;
use core::panic::PanicInfo;
global_asm!(r#"
    .section .text.start,"ax",@progbits
    .option push
    .option arch, +m
    .option norvc
    .option norelax
    .global _start
_start:
    lui sp, 0x800
    li s8, 0x00700000
    li s9, 0x10001000
    sw zero, 24(s8)
    sw zero, 28(s8)
    li s4, 0
    la s0, groups
next_group:
    lw s5, 0(s0)
    beqz s5, pass
    lw t0, 4(s0)
    sw t0, 4(s8)
    lw s3, 8(s0)
    lw s2, 12(s0)
next_case:
    addi s4, s4, 1
    sw s4, 0(s8)
    lw a0, 0(s2)
    lw a1, 4(s2)
    lw a2, 8(s2)
    mv s6, a2
    sw a0, 8(s8)
    sw a1, 12(s8)
    sw a2, 16(s8)
    li t0, 0xEEEEEEEE
    sw t0, 20(s8)
    jalr ra, 0(s5)
    sw a0, 20(s8)
    bne a0, s6, fail
    sw s4, 28(s8)
    addi s2, s2, 12
    addi s3, s3, -1
    bnez s3, next_case
    addi s0, s0, 16
    j next_group
pass:
    li s7, 0x12345678
    j finish
fail:
    li s7, 0xDEAD0000
    or s7, s7, s4
    sw s7, 24(s8)
    li a0, 0xD00F0000
    jal ra, emit
    li s0, 0
    mv s1, s8
dump_loop:
    li a0, 0xD0010000
    or a0, a0, s0
    jal ra, emit
    lw a0, 0(s1)
    jal ra, emit
    addi s0, s0, 1
    addi s1, s1, 4
    li t0, 8
    bne s0, t0, dump_loop
    li a0, 0xD00FFFFF
    jal ra, emit
finish:
    sw s7, 24(s8)
    li a0, 0xEE01
    sw a0, 0(s9)
    sw s7, 0(s9)
halt:
    j halt
emit:
    sw a0, 0(s9)
    li t5, 64
emit_wait:
    addi t5, t5, -1
    bnez t5, emit_wait
    ret
op_return:
    mv a0, a4
    ret

op_add:
    mv t0, a0
    add a4, a0, a1
    bne a4, a2, op_return
    add a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    add a1, t0, a1
    mv a4, a1
    j op_return
op_sub:
    mv t0, a0
    sub a4, a0, a1
    bne a4, a2, op_return
    sub a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    sub a1, t0, a1
    mv a4, a1
    j op_return
op_sll:
    mv t0, a0
    sll a4, a0, a1
    bne a4, a2, op_return
    sll a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    sll a1, t0, a1
    mv a4, a1
    j op_return
op_slt:
    mv t0, a0
    slt a4, a0, a1
    bne a4, a2, op_return
    slt a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    slt a1, t0, a1
    mv a4, a1
    j op_return
op_sltu:
    mv t0, a0
    sltu a4, a0, a1
    bne a4, a2, op_return
    sltu a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    sltu a1, t0, a1
    mv a4, a1
    j op_return
op_xor:
    mv t0, a0
    xor a4, a0, a1
    bne a4, a2, op_return
    xor a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    xor a1, t0, a1
    mv a4, a1
    j op_return
op_srl:
    mv t0, a0
    srl a4, a0, a1
    bne a4, a2, op_return
    srl a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    srl a1, t0, a1
    mv a4, a1
    j op_return
op_sra:
    mv t0, a0
    sra a4, a0, a1
    bne a4, a2, op_return
    sra a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    sra a1, t0, a1
    mv a4, a1
    j op_return
op_or:
    mv t0, a0
    or a4, a0, a1
    bne a4, a2, op_return
    or a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    or a1, t0, a1
    mv a4, a1
    j op_return
op_and:
    mv t0, a0
    and a4, a0, a1
    bne a4, a2, op_return
    and a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    and a1, t0, a1
    mv a4, a1
    j op_return
op_mul:
    mv t0, a0
    mul a4, a0, a1
    bne a4, a2, op_return
    mul a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    mul a1, t0, a1
    mv a4, a1
    j op_return
op_mulh:
    mv t0, a0
    mulh a4, a0, a1
    bne a4, a2, op_return
    mulh a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    mulh a1, t0, a1
    mv a4, a1
    j op_return
op_mulhsu:
    mv t0, a0
    mulhsu a4, a0, a1
    bne a4, a2, op_return
    mulhsu a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    mulhsu a1, t0, a1
    mv a4, a1
    j op_return
op_mulhu:
    mv t0, a0
    mulhu a4, a0, a1
    bne a4, a2, op_return
    mulhu a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    mulhu a1, t0, a1
    mv a4, a1
    j op_return
op_div:
    mv t0, a0
    div a4, a0, a1
    bne a4, a2, op_return
    div a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    div a1, t0, a1
    mv a4, a1
    j op_return
op_divu:
    mv t0, a0
    divu a4, a0, a1
    bne a4, a2, op_return
    divu a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    divu a1, t0, a1
    mv a4, a1
    j op_return
op_rem:
    mv t0, a0
    rem a4, a0, a1
    bne a4, a2, op_return
    rem a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    rem a1, t0, a1
    mv a4, a1
    j op_return
op_remu:
    mv t0, a0
    remu a4, a0, a1
    bne a4, a2, op_return
    remu a0, a0, a1
    mv a4, a0
    bne a4, a2, op_return
    remu a1, t0, a1
    mv a4, a1
    j op_return
op_addi_0:
    addi a0, a0, -2048
    ret
op_addi_1:
    addi a0, a0, -1
    ret
op_addi_2:
    addi a0, a0, 2047
    ret
op_slti_0:
    slti a0, a0, -2048
    ret
op_slti_1:
    slti a0, a0, -1
    ret
op_slti_2:
    slti a0, a0, 2047
    ret
op_sltiu_0:
    sltiu a0, a0, -2048
    ret
op_sltiu_1:
    sltiu a0, a0, -1
    ret
op_sltiu_2:
    sltiu a0, a0, 2047
    ret
op_xori_0:
    xori a0, a0, -2048
    ret
op_xori_1:
    xori a0, a0, -1
    ret
op_xori_2:
    xori a0, a0, 2047
    ret
op_ori_0:
    ori a0, a0, -2048
    ret
op_ori_1:
    ori a0, a0, -1
    ret
op_ori_2:
    ori a0, a0, 2047
    ret
op_andi_0:
    andi a0, a0, -2048
    ret
op_andi_1:
    andi a0, a0, -1
    ret
op_andi_2:
    andi a0, a0, 2047
    ret
op_slli_0:
    slli a0, a0, 0
    ret
op_slli_1:
    slli a0, a0, 1
    ret
op_slli_2:
    slli a0, a0, 31
    ret
op_srli_0:
    srli a0, a0, 0
    ret
op_srli_1:
    srli a0, a0, 1
    ret
op_srli_2:
    srli a0, a0, 31
    ret
op_srai_0:
    srai a0, a0, 0
    ret
op_srai_1:
    srai a0, a0, 1
    ret
op_srai_2:
    srai a0, a0, 31
    ret
op_lui_0:
    lui a0, 0
    ret
op_auipc_0:
    auipc t0, 0
    auipc a0, 0
    sub a0, a0, t0
    ret
op_lui_1:
    lui a0, 1
    ret
op_auipc_1:
    auipc t0, 0
    auipc a0, 1
    sub a0, a0, t0
    ret
op_lui_524287:
    lui a0, 524287
    ret
op_auipc_524287:
    auipc t0, 0
    auipc a0, 524287
    sub a0, a0, t0
    ret
op_lui_524288:
    lui a0, 524288
    ret
op_auipc_524288:
    auipc t0, 0
    auipc a0, 524288
    sub a0, a0, t0
    ret
op_lui_1048575:
    lui a0, 1048575
    ret
op_auipc_1048575:
    auipc t0, 0
    auipc a0, 1048575
    sub a0, a0, t0
    ret
op_zero:
    addi zero, zero, 123
    add a0, zero, zero
    ret
groups:
    .word op_add, 1, 21, vectors_0
    .word op_sub, 2, 21, vectors_1
    .word op_sll, 3, 21, vectors_2
    .word op_slt, 4, 21, vectors_3
    .word op_sltu, 5, 21, vectors_4
    .word op_xor, 6, 21, vectors_5
    .word op_srl, 7, 21, vectors_6
    .word op_sra, 8, 21, vectors_7
    .word op_or, 9, 21, vectors_8
    .word op_and, 10, 21, vectors_9
    .word op_mul, 11, 21, vectors_10
    .word op_mulh, 12, 21, vectors_11
    .word op_mulhsu, 13, 21, vectors_12
    .word op_mulhu, 14, 21, vectors_13
    .word op_div, 15, 21, vectors_14
    .word op_divu, 16, 21, vectors_15
    .word op_rem, 17, 21, vectors_16
    .word op_remu, 18, 21, vectors_17
    .word op_addi_0, 19, 6, vectors_18
    .word op_addi_1, 19, 6, vectors_19
    .word op_addi_2, 19, 6, vectors_20
    .word op_slti_0, 20, 6, vectors_21
    .word op_slti_1, 20, 6, vectors_22
    .word op_slti_2, 20, 6, vectors_23
    .word op_sltiu_0, 21, 6, vectors_24
    .word op_sltiu_1, 21, 6, vectors_25
    .word op_sltiu_2, 21, 6, vectors_26
    .word op_xori_0, 22, 6, vectors_27
    .word op_xori_1, 22, 6, vectors_28
    .word op_xori_2, 22, 6, vectors_29
    .word op_ori_0, 23, 6, vectors_30
    .word op_ori_1, 23, 6, vectors_31
    .word op_ori_2, 23, 6, vectors_32
    .word op_andi_0, 24, 6, vectors_33
    .word op_andi_1, 24, 6, vectors_34
    .word op_andi_2, 24, 6, vectors_35
    .word op_slli_0, 25, 6, vectors_36
    .word op_slli_1, 25, 6, vectors_37
    .word op_slli_2, 25, 6, vectors_38
    .word op_srli_0, 26, 6, vectors_39
    .word op_srli_1, 26, 6, vectors_40
    .word op_srli_2, 26, 6, vectors_41
    .word op_srai_0, 27, 6, vectors_42
    .word op_srai_1, 27, 6, vectors_43
    .word op_srai_2, 27, 6, vectors_44
    .word op_lui_0, 28, 1, vectors_45
    .word op_auipc_0, 29, 1, vectors_46
    .word op_lui_1, 28, 1, vectors_47
    .word op_auipc_1, 29, 1, vectors_48
    .word op_lui_524287, 28, 1, vectors_49
    .word op_auipc_524287, 29, 1, vectors_50
    .word op_lui_524288, 28, 1, vectors_51
    .word op_auipc_524288, 29, 1, vectors_52
    .word op_lui_1048575, 28, 1, vectors_53
    .word op_auipc_1048575, 29, 1, vectors_54
    .word op_zero, 30, 1, vectors_55
    .word 0, 0, 0, 0
vectors_0: # op_add, instruction ID 1
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000001
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0x80000000
    .word 0x00000000, 0x00000001, 0x00000001
    .word 0x00000001, 0x00000001, 0x00000002
    .word 0xffffffff, 0x00000001, 0x00000000
    .word 0xffffffff, 0xffffffff, 0xfffffffe
    .word 0x80000000, 0xffffffff, 0x7fffffff
    .word 0x80000000, 0x00000001, 0x80000001
    .word 0x7fffffff, 0x00000001, 0x80000000
    .word 0x80000000, 0x7fffffff, 0xffffffff
    .word 0x00000007, 0x00000003, 0x0000000a
    .word 0xfffffff9, 0x00000003, 0xfffffffc
    .word 0x00000007, 0xfffffffd, 0x00000004
    .word 0xfffffff9, 0xfffffffd, 0xfffffff6
    .word 0xaaaaaaaa, 0x55555555, 0xffffffff
    .word 0x12345678, 0x87654321, 0x99999999
    .word 0x80000001, 0x0000001f, 0x80000020
    .word 0x80000001, 0x00000020, 0x80000021
    .word 0x80000001, 0x00000021, 0x80000022
vectors_1: # op_sub, instruction ID 2
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000001
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0x80000000
    .word 0x00000000, 0x00000001, 0xffffffff
    .word 0x00000001, 0x00000001, 0x00000000
    .word 0xffffffff, 0x00000001, 0xfffffffe
    .word 0xffffffff, 0xffffffff, 0x00000000
    .word 0x80000000, 0xffffffff, 0x80000001
    .word 0x80000000, 0x00000001, 0x7fffffff
    .word 0x7fffffff, 0x00000001, 0x7ffffffe
    .word 0x80000000, 0x7fffffff, 0x00000001
    .word 0x00000007, 0x00000003, 0x00000004
    .word 0xfffffff9, 0x00000003, 0xfffffff6
    .word 0x00000007, 0xfffffffd, 0x0000000a
    .word 0xfffffff9, 0xfffffffd, 0xfffffffc
    .word 0xaaaaaaaa, 0x55555555, 0x55555555
    .word 0x12345678, 0x87654321, 0x8acf1357
    .word 0x80000001, 0x0000001f, 0x7fffffe2
    .word 0x80000001, 0x00000020, 0x7fffffe1
    .word 0x80000001, 0x00000021, 0x7fffffe0
vectors_2: # op_sll, instruction ID 3
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000001
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0x80000000
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000002
    .word 0xffffffff, 0x00000001, 0xfffffffe
    .word 0xffffffff, 0xffffffff, 0x80000000
    .word 0x80000000, 0xffffffff, 0x00000000
    .word 0x80000000, 0x00000001, 0x00000000
    .word 0x7fffffff, 0x00000001, 0xfffffffe
    .word 0x80000000, 0x7fffffff, 0x00000000
    .word 0x00000007, 0x00000003, 0x00000038
    .word 0xfffffff9, 0x00000003, 0xffffffc8
    .word 0x00000007, 0xfffffffd, 0xe0000000
    .word 0xfffffff9, 0xfffffffd, 0x20000000
    .word 0xaaaaaaaa, 0x55555555, 0x55400000
    .word 0x12345678, 0x87654321, 0x2468acf0
    .word 0x80000001, 0x0000001f, 0x80000000
    .word 0x80000001, 0x00000020, 0x80000001
    .word 0x80000001, 0x00000021, 0x00000002
vectors_3: # op_slt, instruction ID 4
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000000
    .word 0xffffffff, 0x00000000, 0x00000001
    .word 0x80000000, 0x00000000, 0x00000001
    .word 0x00000000, 0x00000001, 0x00000001
    .word 0x00000001, 0x00000001, 0x00000000
    .word 0xffffffff, 0x00000001, 0x00000001
    .word 0xffffffff, 0xffffffff, 0x00000000
    .word 0x80000000, 0xffffffff, 0x00000001
    .word 0x80000000, 0x00000001, 0x00000001
    .word 0x7fffffff, 0x00000001, 0x00000000
    .word 0x80000000, 0x7fffffff, 0x00000001
    .word 0x00000007, 0x00000003, 0x00000000
    .word 0xfffffff9, 0x00000003, 0x00000001
    .word 0x00000007, 0xfffffffd, 0x00000000
    .word 0xfffffff9, 0xfffffffd, 0x00000001
    .word 0xaaaaaaaa, 0x55555555, 0x00000001
    .word 0x12345678, 0x87654321, 0x00000000
    .word 0x80000001, 0x0000001f, 0x00000001
    .word 0x80000001, 0x00000020, 0x00000001
    .word 0x80000001, 0x00000021, 0x00000001
vectors_4: # op_sltu, instruction ID 5
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000000
    .word 0xffffffff, 0x00000000, 0x00000000
    .word 0x80000000, 0x00000000, 0x00000000
    .word 0x00000000, 0x00000001, 0x00000001
    .word 0x00000001, 0x00000001, 0x00000000
    .word 0xffffffff, 0x00000001, 0x00000000
    .word 0xffffffff, 0xffffffff, 0x00000000
    .word 0x80000000, 0xffffffff, 0x00000001
    .word 0x80000000, 0x00000001, 0x00000000
    .word 0x7fffffff, 0x00000001, 0x00000000
    .word 0x80000000, 0x7fffffff, 0x00000000
    .word 0x00000007, 0x00000003, 0x00000000
    .word 0xfffffff9, 0x00000003, 0x00000000
    .word 0x00000007, 0xfffffffd, 0x00000001
    .word 0xfffffff9, 0xfffffffd, 0x00000001
    .word 0xaaaaaaaa, 0x55555555, 0x00000000
    .word 0x12345678, 0x87654321, 0x00000001
    .word 0x80000001, 0x0000001f, 0x00000000
    .word 0x80000001, 0x00000020, 0x00000000
    .word 0x80000001, 0x00000021, 0x00000000
vectors_5: # op_xor, instruction ID 6
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000001
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0x80000000
    .word 0x00000000, 0x00000001, 0x00000001
    .word 0x00000001, 0x00000001, 0x00000000
    .word 0xffffffff, 0x00000001, 0xfffffffe
    .word 0xffffffff, 0xffffffff, 0x00000000
    .word 0x80000000, 0xffffffff, 0x7fffffff
    .word 0x80000000, 0x00000001, 0x80000001
    .word 0x7fffffff, 0x00000001, 0x7ffffffe
    .word 0x80000000, 0x7fffffff, 0xffffffff
    .word 0x00000007, 0x00000003, 0x00000004
    .word 0xfffffff9, 0x00000003, 0xfffffffa
    .word 0x00000007, 0xfffffffd, 0xfffffffa
    .word 0xfffffff9, 0xfffffffd, 0x00000004
    .word 0xaaaaaaaa, 0x55555555, 0xffffffff
    .word 0x12345678, 0x87654321, 0x95511559
    .word 0x80000001, 0x0000001f, 0x8000001e
    .word 0x80000001, 0x00000020, 0x80000021
    .word 0x80000001, 0x00000021, 0x80000020
vectors_6: # op_srl, instruction ID 7
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000001
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0x80000000
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000000
    .word 0xffffffff, 0x00000001, 0x7fffffff
    .word 0xffffffff, 0xffffffff, 0x00000001
    .word 0x80000000, 0xffffffff, 0x00000001
    .word 0x80000000, 0x00000001, 0x40000000
    .word 0x7fffffff, 0x00000001, 0x3fffffff
    .word 0x80000000, 0x7fffffff, 0x00000001
    .word 0x00000007, 0x00000003, 0x00000000
    .word 0xfffffff9, 0x00000003, 0x1fffffff
    .word 0x00000007, 0xfffffffd, 0x00000000
    .word 0xfffffff9, 0xfffffffd, 0x00000007
    .word 0xaaaaaaaa, 0x55555555, 0x00000555
    .word 0x12345678, 0x87654321, 0x091a2b3c
    .word 0x80000001, 0x0000001f, 0x00000001
    .word 0x80000001, 0x00000020, 0x80000001
    .word 0x80000001, 0x00000021, 0x40000000
vectors_7: # op_sra, instruction ID 8
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000001
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0x80000000
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000000
    .word 0xffffffff, 0x00000001, 0xffffffff
    .word 0xffffffff, 0xffffffff, 0xffffffff
    .word 0x80000000, 0xffffffff, 0xffffffff
    .word 0x80000000, 0x00000001, 0xc0000000
    .word 0x7fffffff, 0x00000001, 0x3fffffff
    .word 0x80000000, 0x7fffffff, 0xffffffff
    .word 0x00000007, 0x00000003, 0x00000000
    .word 0xfffffff9, 0x00000003, 0xffffffff
    .word 0x00000007, 0xfffffffd, 0x00000000
    .word 0xfffffff9, 0xfffffffd, 0xffffffff
    .word 0xaaaaaaaa, 0x55555555, 0xfffffd55
    .word 0x12345678, 0x87654321, 0x091a2b3c
    .word 0x80000001, 0x0000001f, 0xffffffff
    .word 0x80000001, 0x00000020, 0x80000001
    .word 0x80000001, 0x00000021, 0xc0000000
vectors_8: # op_or, instruction ID 9
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000001
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0x80000000
    .word 0x00000000, 0x00000001, 0x00000001
    .word 0x00000001, 0x00000001, 0x00000001
    .word 0xffffffff, 0x00000001, 0xffffffff
    .word 0xffffffff, 0xffffffff, 0xffffffff
    .word 0x80000000, 0xffffffff, 0xffffffff
    .word 0x80000000, 0x00000001, 0x80000001
    .word 0x7fffffff, 0x00000001, 0x7fffffff
    .word 0x80000000, 0x7fffffff, 0xffffffff
    .word 0x00000007, 0x00000003, 0x00000007
    .word 0xfffffff9, 0x00000003, 0xfffffffb
    .word 0x00000007, 0xfffffffd, 0xffffffff
    .word 0xfffffff9, 0xfffffffd, 0xfffffffd
    .word 0xaaaaaaaa, 0x55555555, 0xffffffff
    .word 0x12345678, 0x87654321, 0x97755779
    .word 0x80000001, 0x0000001f, 0x8000001f
    .word 0x80000001, 0x00000020, 0x80000021
    .word 0x80000001, 0x00000021, 0x80000021
vectors_9: # op_and, instruction ID 10
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000000
    .word 0xffffffff, 0x00000000, 0x00000000
    .word 0x80000000, 0x00000000, 0x00000000
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000001
    .word 0xffffffff, 0x00000001, 0x00000001
    .word 0xffffffff, 0xffffffff, 0xffffffff
    .word 0x80000000, 0xffffffff, 0x80000000
    .word 0x80000000, 0x00000001, 0x00000000
    .word 0x7fffffff, 0x00000001, 0x00000001
    .word 0x80000000, 0x7fffffff, 0x00000000
    .word 0x00000007, 0x00000003, 0x00000003
    .word 0xfffffff9, 0x00000003, 0x00000001
    .word 0x00000007, 0xfffffffd, 0x00000005
    .word 0xfffffff9, 0xfffffffd, 0xfffffff9
    .word 0xaaaaaaaa, 0x55555555, 0x00000000
    .word 0x12345678, 0x87654321, 0x02244220
    .word 0x80000001, 0x0000001f, 0x00000001
    .word 0x80000001, 0x00000020, 0x00000000
    .word 0x80000001, 0x00000021, 0x00000001
vectors_10: # op_mul, instruction ID 11
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000000
    .word 0xffffffff, 0x00000000, 0x00000000
    .word 0x80000000, 0x00000000, 0x00000000
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000001
    .word 0xffffffff, 0x00000001, 0xffffffff
    .word 0xffffffff, 0xffffffff, 0x00000001
    .word 0x80000000, 0xffffffff, 0x80000000
    .word 0x80000000, 0x00000001, 0x80000000
    .word 0x7fffffff, 0x00000001, 0x7fffffff
    .word 0x80000000, 0x7fffffff, 0x80000000
    .word 0x00000007, 0x00000003, 0x00000015
    .word 0xfffffff9, 0x00000003, 0xffffffeb
    .word 0x00000007, 0xfffffffd, 0xffffffeb
    .word 0xfffffff9, 0xfffffffd, 0x00000015
    .word 0xaaaaaaaa, 0x55555555, 0x71c71c72
    .word 0x12345678, 0x87654321, 0x70b88d78
    .word 0x80000001, 0x0000001f, 0x8000001f
    .word 0x80000001, 0x00000020, 0x00000020
    .word 0x80000001, 0x00000021, 0x80000021
vectors_11: # op_mulh, instruction ID 12
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000000
    .word 0xffffffff, 0x00000000, 0x00000000
    .word 0x80000000, 0x00000000, 0x00000000
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000000
    .word 0xffffffff, 0x00000001, 0xffffffff
    .word 0xffffffff, 0xffffffff, 0x00000000
    .word 0x80000000, 0xffffffff, 0x00000000
    .word 0x80000000, 0x00000001, 0xffffffff
    .word 0x7fffffff, 0x00000001, 0x00000000
    .word 0x80000000, 0x7fffffff, 0xc0000000
    .word 0x00000007, 0x00000003, 0x00000000
    .word 0xfffffff9, 0x00000003, 0xffffffff
    .word 0x00000007, 0xfffffffd, 0xffffffff
    .word 0xfffffff9, 0xfffffffd, 0x00000000
    .word 0xaaaaaaaa, 0x55555555, 0xe38e38e3
    .word 0x12345678, 0x87654321, 0xf76c768d
    .word 0x80000001, 0x0000001f, 0xfffffff0
    .word 0x80000001, 0x00000020, 0xfffffff0
    .word 0x80000001, 0x00000021, 0xffffffef
vectors_12: # op_mulhsu, instruction ID 13
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000000
    .word 0xffffffff, 0x00000000, 0x00000000
    .word 0x80000000, 0x00000000, 0x00000000
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000000
    .word 0xffffffff, 0x00000001, 0xffffffff
    .word 0xffffffff, 0xffffffff, 0xffffffff
    .word 0x80000000, 0xffffffff, 0x80000000
    .word 0x80000000, 0x00000001, 0xffffffff
    .word 0x7fffffff, 0x00000001, 0x00000000
    .word 0x80000000, 0x7fffffff, 0xc0000000
    .word 0x00000007, 0x00000003, 0x00000000
    .word 0xfffffff9, 0x00000003, 0xffffffff
    .word 0x00000007, 0xfffffffd, 0x00000006
    .word 0xfffffff9, 0xfffffffd, 0xfffffff9
    .word 0xaaaaaaaa, 0x55555555, 0xe38e38e3
    .word 0x12345678, 0x87654321, 0x09a0cd05
    .word 0x80000001, 0x0000001f, 0xfffffff0
    .word 0x80000001, 0x00000020, 0xfffffff0
    .word 0x80000001, 0x00000021, 0xffffffef
vectors_13: # op_mulhu, instruction ID 14
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000000
    .word 0xffffffff, 0x00000000, 0x00000000
    .word 0x80000000, 0x00000000, 0x00000000
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000000
    .word 0xffffffff, 0x00000001, 0x00000000
    .word 0xffffffff, 0xffffffff, 0xfffffffe
    .word 0x80000000, 0xffffffff, 0x7fffffff
    .word 0x80000000, 0x00000001, 0x00000000
    .word 0x7fffffff, 0x00000001, 0x00000000
    .word 0x80000000, 0x7fffffff, 0x3fffffff
    .word 0x00000007, 0x00000003, 0x00000000
    .word 0xfffffff9, 0x00000003, 0x00000002
    .word 0x00000007, 0xfffffffd, 0x00000006
    .word 0xfffffff9, 0xfffffffd, 0xfffffff6
    .word 0xaaaaaaaa, 0x55555555, 0x38e38e38
    .word 0x12345678, 0x87654321, 0x09a0cd05
    .word 0x80000001, 0x0000001f, 0x0000000f
    .word 0x80000001, 0x00000020, 0x00000010
    .word 0x80000001, 0x00000021, 0x00000010
vectors_14: # op_div, instruction ID 15
    .word 0x00000000, 0x00000000, 0xffffffff
    .word 0x00000001, 0x00000000, 0xffffffff
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0xffffffff
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000001
    .word 0xffffffff, 0x00000001, 0xffffffff
    .word 0xffffffff, 0xffffffff, 0x00000001
    .word 0x80000000, 0xffffffff, 0x80000000
    .word 0x80000000, 0x00000001, 0x80000000
    .word 0x7fffffff, 0x00000001, 0x7fffffff
    .word 0x80000000, 0x7fffffff, 0xffffffff
    .word 0x00000007, 0x00000003, 0x00000002
    .word 0xfffffff9, 0x00000003, 0xfffffffe
    .word 0x00000007, 0xfffffffd, 0xfffffffe
    .word 0xfffffff9, 0xfffffffd, 0x00000002
    .word 0xaaaaaaaa, 0x55555555, 0xffffffff
    .word 0x12345678, 0x87654321, 0x00000000
    .word 0x80000001, 0x0000001f, 0xfbdef7be
    .word 0x80000001, 0x00000020, 0xfc000001
    .word 0x80000001, 0x00000021, 0xfc1f07c2
vectors_15: # op_divu, instruction ID 16
    .word 0x00000000, 0x00000000, 0xffffffff
    .word 0x00000001, 0x00000000, 0xffffffff
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0xffffffff
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000001
    .word 0xffffffff, 0x00000001, 0xffffffff
    .word 0xffffffff, 0xffffffff, 0x00000001
    .word 0x80000000, 0xffffffff, 0x00000000
    .word 0x80000000, 0x00000001, 0x80000000
    .word 0x7fffffff, 0x00000001, 0x7fffffff
    .word 0x80000000, 0x7fffffff, 0x00000001
    .word 0x00000007, 0x00000003, 0x00000002
    .word 0xfffffff9, 0x00000003, 0x55555553
    .word 0x00000007, 0xfffffffd, 0x00000000
    .word 0xfffffff9, 0xfffffffd, 0x00000000
    .word 0xaaaaaaaa, 0x55555555, 0x00000002
    .word 0x12345678, 0x87654321, 0x00000000
    .word 0x80000001, 0x0000001f, 0x04210842
    .word 0x80000001, 0x00000020, 0x04000000
    .word 0x80000001, 0x00000021, 0x03e0f83e
vectors_16: # op_rem, instruction ID 17
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000001
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0x80000000
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000000
    .word 0xffffffff, 0x00000001, 0x00000000
    .word 0xffffffff, 0xffffffff, 0x00000000
    .word 0x80000000, 0xffffffff, 0x00000000
    .word 0x80000000, 0x00000001, 0x00000000
    .word 0x7fffffff, 0x00000001, 0x00000000
    .word 0x80000000, 0x7fffffff, 0xffffffff
    .word 0x00000007, 0x00000003, 0x00000001
    .word 0xfffffff9, 0x00000003, 0xffffffff
    .word 0x00000007, 0xfffffffd, 0x00000001
    .word 0xfffffff9, 0xfffffffd, 0xffffffff
    .word 0xaaaaaaaa, 0x55555555, 0xffffffff
    .word 0x12345678, 0x87654321, 0x12345678
    .word 0x80000001, 0x0000001f, 0xffffffff
    .word 0x80000001, 0x00000020, 0xffffffe1
    .word 0x80000001, 0x00000021, 0xffffffff
vectors_17: # op_remu, instruction ID 18
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000001
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0x80000000
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000000
    .word 0xffffffff, 0x00000001, 0x00000000
    .word 0xffffffff, 0xffffffff, 0x00000000
    .word 0x80000000, 0xffffffff, 0x80000000
    .word 0x80000000, 0x00000001, 0x00000000
    .word 0x7fffffff, 0x00000001, 0x00000000
    .word 0x80000000, 0x7fffffff, 0x00000001
    .word 0x00000007, 0x00000003, 0x00000001
    .word 0xfffffff9, 0x00000003, 0x00000000
    .word 0x00000007, 0xfffffffd, 0x00000007
    .word 0xfffffff9, 0xfffffffd, 0xfffffff9
    .word 0xaaaaaaaa, 0x55555555, 0x00000000
    .word 0x12345678, 0x87654321, 0x12345678
    .word 0x80000001, 0x0000001f, 0x00000003
    .word 0x80000001, 0x00000020, 0x00000001
    .word 0x80000001, 0x00000021, 0x00000003
vectors_18: # op_addi_0, instruction ID 19
    .word 0x00000000, 0xfffff800, 0xfffff800
    .word 0x00000001, 0xfffff800, 0xfffff801
    .word 0xffffffff, 0xfffff800, 0xfffff7ff
    .word 0x80000000, 0xfffff800, 0x7ffff800
    .word 0x7fffffff, 0xfffff800, 0x7ffff7ff
    .word 0xaaaaaaaa, 0xfffff800, 0xaaaaa2aa
vectors_19: # op_addi_1, instruction ID 19
    .word 0x00000000, 0xffffffff, 0xffffffff
    .word 0x00000001, 0xffffffff, 0x00000000
    .word 0xffffffff, 0xffffffff, 0xfffffffe
    .word 0x80000000, 0xffffffff, 0x7fffffff
    .word 0x7fffffff, 0xffffffff, 0x7ffffffe
    .word 0xaaaaaaaa, 0xffffffff, 0xaaaaaaa9
vectors_20: # op_addi_2, instruction ID 19
    .word 0x00000000, 0x000007ff, 0x000007ff
    .word 0x00000001, 0x000007ff, 0x00000800
    .word 0xffffffff, 0x000007ff, 0x000007fe
    .word 0x80000000, 0x000007ff, 0x800007ff
    .word 0x7fffffff, 0x000007ff, 0x800007fe
    .word 0xaaaaaaaa, 0x000007ff, 0xaaaab2a9
vectors_21: # op_slti_0, instruction ID 20
    .word 0x00000000, 0xfffff800, 0x00000000
    .word 0x00000001, 0xfffff800, 0x00000000
    .word 0xffffffff, 0xfffff800, 0x00000000
    .word 0x80000000, 0xfffff800, 0x00000001
    .word 0x7fffffff, 0xfffff800, 0x00000000
    .word 0xaaaaaaaa, 0xfffff800, 0x00000001
vectors_22: # op_slti_1, instruction ID 20
    .word 0x00000000, 0xffffffff, 0x00000000
    .word 0x00000001, 0xffffffff, 0x00000000
    .word 0xffffffff, 0xffffffff, 0x00000000
    .word 0x80000000, 0xffffffff, 0x00000001
    .word 0x7fffffff, 0xffffffff, 0x00000000
    .word 0xaaaaaaaa, 0xffffffff, 0x00000001
vectors_23: # op_slti_2, instruction ID 20
    .word 0x00000000, 0x000007ff, 0x00000001
    .word 0x00000001, 0x000007ff, 0x00000001
    .word 0xffffffff, 0x000007ff, 0x00000001
    .word 0x80000000, 0x000007ff, 0x00000001
    .word 0x7fffffff, 0x000007ff, 0x00000000
    .word 0xaaaaaaaa, 0x000007ff, 0x00000001
vectors_24: # op_sltiu_0, instruction ID 21
    .word 0x00000000, 0xfffff800, 0x00000001
    .word 0x00000001, 0xfffff800, 0x00000001
    .word 0xffffffff, 0xfffff800, 0x00000000
    .word 0x80000000, 0xfffff800, 0x00000001
    .word 0x7fffffff, 0xfffff800, 0x00000001
    .word 0xaaaaaaaa, 0xfffff800, 0x00000001
vectors_25: # op_sltiu_1, instruction ID 21
    .word 0x00000000, 0xffffffff, 0x00000001
    .word 0x00000001, 0xffffffff, 0x00000001
    .word 0xffffffff, 0xffffffff, 0x00000000
    .word 0x80000000, 0xffffffff, 0x00000001
    .word 0x7fffffff, 0xffffffff, 0x00000001
    .word 0xaaaaaaaa, 0xffffffff, 0x00000001
vectors_26: # op_sltiu_2, instruction ID 21
    .word 0x00000000, 0x000007ff, 0x00000001
    .word 0x00000001, 0x000007ff, 0x00000001
    .word 0xffffffff, 0x000007ff, 0x00000000
    .word 0x80000000, 0x000007ff, 0x00000000
    .word 0x7fffffff, 0x000007ff, 0x00000000
    .word 0xaaaaaaaa, 0x000007ff, 0x00000000
vectors_27: # op_xori_0, instruction ID 22
    .word 0x00000000, 0xfffff800, 0xfffff800
    .word 0x00000001, 0xfffff800, 0xfffff801
    .word 0xffffffff, 0xfffff800, 0x000007ff
    .word 0x80000000, 0xfffff800, 0x7ffff800
    .word 0x7fffffff, 0xfffff800, 0x800007ff
    .word 0xaaaaaaaa, 0xfffff800, 0x555552aa
vectors_28: # op_xori_1, instruction ID 22
    .word 0x00000000, 0xffffffff, 0xffffffff
    .word 0x00000001, 0xffffffff, 0xfffffffe
    .word 0xffffffff, 0xffffffff, 0x00000000
    .word 0x80000000, 0xffffffff, 0x7fffffff
    .word 0x7fffffff, 0xffffffff, 0x80000000
    .word 0xaaaaaaaa, 0xffffffff, 0x55555555
vectors_29: # op_xori_2, instruction ID 22
    .word 0x00000000, 0x000007ff, 0x000007ff
    .word 0x00000001, 0x000007ff, 0x000007fe
    .word 0xffffffff, 0x000007ff, 0xfffff800
    .word 0x80000000, 0x000007ff, 0x800007ff
    .word 0x7fffffff, 0x000007ff, 0x7ffff800
    .word 0xaaaaaaaa, 0x000007ff, 0xaaaaad55
vectors_30: # op_ori_0, instruction ID 23
    .word 0x00000000, 0xfffff800, 0xfffff800
    .word 0x00000001, 0xfffff800, 0xfffff801
    .word 0xffffffff, 0xfffff800, 0xffffffff
    .word 0x80000000, 0xfffff800, 0xfffff800
    .word 0x7fffffff, 0xfffff800, 0xffffffff
    .word 0xaaaaaaaa, 0xfffff800, 0xfffffaaa
vectors_31: # op_ori_1, instruction ID 23
    .word 0x00000000, 0xffffffff, 0xffffffff
    .word 0x00000001, 0xffffffff, 0xffffffff
    .word 0xffffffff, 0xffffffff, 0xffffffff
    .word 0x80000000, 0xffffffff, 0xffffffff
    .word 0x7fffffff, 0xffffffff, 0xffffffff
    .word 0xaaaaaaaa, 0xffffffff, 0xffffffff
vectors_32: # op_ori_2, instruction ID 23
    .word 0x00000000, 0x000007ff, 0x000007ff
    .word 0x00000001, 0x000007ff, 0x000007ff
    .word 0xffffffff, 0x000007ff, 0xffffffff
    .word 0x80000000, 0x000007ff, 0x800007ff
    .word 0x7fffffff, 0x000007ff, 0x7fffffff
    .word 0xaaaaaaaa, 0x000007ff, 0xaaaaafff
vectors_33: # op_andi_0, instruction ID 24
    .word 0x00000000, 0xfffff800, 0x00000000
    .word 0x00000001, 0xfffff800, 0x00000000
    .word 0xffffffff, 0xfffff800, 0xfffff800
    .word 0x80000000, 0xfffff800, 0x80000000
    .word 0x7fffffff, 0xfffff800, 0x7ffff800
    .word 0xaaaaaaaa, 0xfffff800, 0xaaaaa800
vectors_34: # op_andi_1, instruction ID 24
    .word 0x00000000, 0xffffffff, 0x00000000
    .word 0x00000001, 0xffffffff, 0x00000001
    .word 0xffffffff, 0xffffffff, 0xffffffff
    .word 0x80000000, 0xffffffff, 0x80000000
    .word 0x7fffffff, 0xffffffff, 0x7fffffff
    .word 0xaaaaaaaa, 0xffffffff, 0xaaaaaaaa
vectors_35: # op_andi_2, instruction ID 24
    .word 0x00000000, 0x000007ff, 0x00000000
    .word 0x00000001, 0x000007ff, 0x00000001
    .word 0xffffffff, 0x000007ff, 0x000007ff
    .word 0x80000000, 0x000007ff, 0x00000000
    .word 0x7fffffff, 0x000007ff, 0x000007ff
    .word 0xaaaaaaaa, 0x000007ff, 0x000002aa
vectors_36: # op_slli_0, instruction ID 25
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000001
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0x80000000
    .word 0x7fffffff, 0x00000000, 0x7fffffff
    .word 0xaaaaaaaa, 0x00000000, 0xaaaaaaaa
vectors_37: # op_slli_1, instruction ID 25
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000002
    .word 0xffffffff, 0x00000001, 0xfffffffe
    .word 0x80000000, 0x00000001, 0x00000000
    .word 0x7fffffff, 0x00000001, 0xfffffffe
    .word 0xaaaaaaaa, 0x00000001, 0x55555554
vectors_38: # op_slli_2, instruction ID 25
    .word 0x00000000, 0x0000001f, 0x00000000
    .word 0x00000001, 0x0000001f, 0x80000000
    .word 0xffffffff, 0x0000001f, 0x80000000
    .word 0x80000000, 0x0000001f, 0x00000000
    .word 0x7fffffff, 0x0000001f, 0x80000000
    .word 0xaaaaaaaa, 0x0000001f, 0x00000000
vectors_39: # op_srli_0, instruction ID 26
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000001
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0x80000000
    .word 0x7fffffff, 0x00000000, 0x7fffffff
    .word 0xaaaaaaaa, 0x00000000, 0xaaaaaaaa
vectors_40: # op_srli_1, instruction ID 26
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000000
    .word 0xffffffff, 0x00000001, 0x7fffffff
    .word 0x80000000, 0x00000001, 0x40000000
    .word 0x7fffffff, 0x00000001, 0x3fffffff
    .word 0xaaaaaaaa, 0x00000001, 0x55555555
vectors_41: # op_srli_2, instruction ID 26
    .word 0x00000000, 0x0000001f, 0x00000000
    .word 0x00000001, 0x0000001f, 0x00000000
    .word 0xffffffff, 0x0000001f, 0x00000001
    .word 0x80000000, 0x0000001f, 0x00000001
    .word 0x7fffffff, 0x0000001f, 0x00000000
    .word 0xaaaaaaaa, 0x0000001f, 0x00000001
vectors_42: # op_srai_0, instruction ID 27
    .word 0x00000000, 0x00000000, 0x00000000
    .word 0x00000001, 0x00000000, 0x00000001
    .word 0xffffffff, 0x00000000, 0xffffffff
    .word 0x80000000, 0x00000000, 0x80000000
    .word 0x7fffffff, 0x00000000, 0x7fffffff
    .word 0xaaaaaaaa, 0x00000000, 0xaaaaaaaa
vectors_43: # op_srai_1, instruction ID 27
    .word 0x00000000, 0x00000001, 0x00000000
    .word 0x00000001, 0x00000001, 0x00000000
    .word 0xffffffff, 0x00000001, 0xffffffff
    .word 0x80000000, 0x00000001, 0xc0000000
    .word 0x7fffffff, 0x00000001, 0x3fffffff
    .word 0xaaaaaaaa, 0x00000001, 0xd5555555
vectors_44: # op_srai_2, instruction ID 27
    .word 0x00000000, 0x0000001f, 0x00000000
    .word 0x00000001, 0x0000001f, 0x00000000
    .word 0xffffffff, 0x0000001f, 0xffffffff
    .word 0x80000000, 0x0000001f, 0xffffffff
    .word 0x7fffffff, 0x0000001f, 0x00000000
    .word 0xaaaaaaaa, 0x0000001f, 0xffffffff
vectors_45: # op_lui_0, instruction ID 28
    .word 0x00000000, 0x00000000, 0x00000000
vectors_46: # op_auipc_0, instruction ID 29
    .word 0x00000000, 0x00000000, 0x00000004
vectors_47: # op_lui_1, instruction ID 28
    .word 0x00000000, 0x00000001, 0x00001000
vectors_48: # op_auipc_1, instruction ID 29
    .word 0x00000000, 0x00000001, 0x00001004
vectors_49: # op_lui_524287, instruction ID 28
    .word 0x00000000, 0x0007ffff, 0x7ffff000
vectors_50: # op_auipc_524287, instruction ID 29
    .word 0x00000000, 0x0007ffff, 0x7ffff004
vectors_51: # op_lui_524288, instruction ID 28
    .word 0x00000000, 0x00080000, 0x80000000
vectors_52: # op_auipc_524288, instruction ID 29
    .word 0x00000000, 0x00080000, 0x80000004
vectors_53: # op_lui_1048575, instruction ID 28
    .word 0x00000000, 0x000fffff, 0xfffff000
vectors_54: # op_auipc_1048575, instruction ID 29
    .word 0x00000000, 0x000fffff, 0xfffff004
vectors_55: # op_zero, instruction ID 30
    .word 0x00000000, 0x0000007b, 0x00000000
    # Size guard: moving .org backwards is an assembly error.
    # Pad this self-contained code AND data section to exactly 12 KiB.
    .org 12288, 0
    .option pop
"#);
#[panic_handler]
fn panic(_: &PanicInfo) -> ! { loop {} }
