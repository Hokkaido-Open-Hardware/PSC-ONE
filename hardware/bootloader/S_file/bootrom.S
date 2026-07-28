
./build/bootrom.elf:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <_start>:

/* ------------------------------------------------------------
 * M-mode Boot Entry
 * ------------------------------------------------------------ */
_start:
    la      sp, _mstack_top
   0:	00001117          	auipc	sp,0x1
   4:	13010113          	addi	sp,sp,304 # 1130 <_mstack_top>

    # mtvec = trap handler
    la      t0, m_trap_vector
   8:	00000297          	auipc	t0,0x0
   c:	04428293          	addi	t0,t0,68 # 4c <m_trap_vector>
    csrw    mtvec, t0
  10:	30529073          	csrw	mtvec,t0

    # Disable MMU
    csrw    satp, zero
  14:	18001073          	csrw	satp,zero

    # Delegate U-mode ECALL to S-mode
    li      t0, (1 << 8)
  18:	10000293          	li	t0,256
    csrw    medeleg, t0
  1c:	30229073          	csrw	medeleg,t0

    # mstatus.MPP = S-mode (01)
    csrr    t0, mstatus
  20:	300022f3          	csrr	t0,mstatus
    li      t1, ~(3 << 11)     # MPP mask clear
  24:	ffffe337          	lui	t1,0xffffe
  28:	7ff30313          	addi	t1,t1,2047 # ffffe7ff <_mstack_top+0xffffd6cf>
    and     t0, t0, t1
  2c:	0062f2b3          	and	t0,t0,t1
    li      t1, (1 << 11)      # MPP = S
  30:	00100313          	li	t1,1
  34:	00b31313          	slli	t1,t1,0xb
    or      t0, t0, t1
  38:	0062e2b3          	or	t0,t0,t1
    csrw    mstatus, t0
  3c:	30029073          	csrw	mstatus,t0

    # mepc = S kernel entry (0x00200000)
#ifdef USE_BOOTLOADER
    li t0, 0x00100000
  40:	001002b7          	lui	t0,0x100
#else
    li t0, 0x00200000
#endif

    csrw mepc, t0
  44:	34129073          	csrw	mepc,t0
    mret
  48:	30200073          	mret

0000004c <m_trap_vector>:

/* ------------------------------------------------------------
 * M-mode trap handler
 * ------------------------------------------------------------ */
m_trap_vector:
    addi    sp, sp, -128
  4c:	f8010113          	addi	sp,sp,-128
    sw      ra,   0(sp)
  50:	00112023          	sw	ra,0(sp)
    sw      t0,   4(sp)
  54:	00512223          	sw	t0,4(sp)
    sw      t1,   8(sp)
  58:	00612423          	sw	t1,8(sp)
    sw      t2,  12(sp)
  5c:	00712623          	sw	t2,12(sp)
    sw      a0,  16(sp)
  60:	00a12823          	sw	a0,16(sp)
    sw      a1,  20(sp)
  64:	00b12a23          	sw	a1,20(sp)
    sw      a2,  24(sp)
  68:	00c12c23          	sw	a2,24(sp)
    sw      a3,  28(sp)
  6c:	00d12e23          	sw	a3,28(sp)
    sw      a4,  32(sp)
  70:	02e12023          	sw	a4,32(sp)
    sw      a5,  36(sp)
  74:	02f12223          	sw	a5,36(sp)
    sw      a6,  40(sp)
  78:	03012423          	sw	a6,40(sp)
    sw      a7,  44(sp)
  7c:	03112623          	sw	a7,44(sp)

    csrr    t0, mcause
  80:	342022f3          	csrr	t0,mcause
    li      t1, 9              # S-mode ECALL
  84:	00900313          	li	t1,9
    beq     t0, t1, sbi_ecall
  88:	00628463          	beq	t0,t1,90 <sbi_ecall>

0000008c <illegal>:

illegal:
    j       illegal
  8c:	0000006f          	j	8c <illegal>

00000090 <sbi_ecall>:
/* ------------------------------------------------------------
 * SBI Dispatcher
 * a7 = ext (1=putchar, 2=getchar)
 * ------------------------------------------------------------ */
sbi_ecall:
    li t1, 1
  90:	00100313          	li	t1,1
    beq a7, t1, sbi_putchar
  94:	00688a63          	beq	a7,t1,a8 <sbi_putchar>

    li t1, 2
  98:	00200313          	li	t1,2
    beq a7, t1, sbi_getchar
  9c:	02688863          	beq	a7,t1,cc <sbi_getchar>

    j illegal
  a0:	fedff06f          	j	8c <illegal>

000000a4 <uart_base>:
  a4:	0000                	.insn	2, 0x0000
  a6:	1000                	.insn	2, 0x1000

000000a8 <sbi_putchar>:

/* ------------------------------------------------------------
 * SBI console putchar
 * ------------------------------------------------------------ */
sbi_putchar:
    la t1, uart_base
  a8:	00000317          	auipc	t1,0x0
  ac:	ffc30313          	addi	t1,t1,-4 # a4 <uart_base>
    lw t1, 0(t1)
  b0:	00032303          	lw	t1,0(t1)

1:
    lw t2, 8(t1)   # UART_ST
  b4:	00832383          	lw	t2,8(t1)
    andi t2, t2, 1 # TX busy
  b8:	0013f393          	andi	t2,t2,1
    bnez t2, 1b
  bc:	fe039ce3          	bnez	t2,b4 <sbi_putchar+0xc>

    sb a0, 0(t1)   # UART_TX
  c0:	00a30023          	sb	a0,0(t1)
    li a0, 0       # return OK
  c4:	00000513          	li	a0,0
    j sbi_ret
  c8:	0240006f          	j	ec <sbi_ret>

000000cc <sbi_getchar>:

/* ------------------------------------------------------------
 * SBI console getchar
 * ------------------------------------------------------------ */
sbi_getchar:
    la t1, uart_base
  cc:	00000317          	auipc	t1,0x0
  d0:	fd830313          	addi	t1,t1,-40 # a4 <uart_base>
    lw t1, 0(t1)
  d4:	00032303          	lw	t1,0(t1)

2:
    lw t2, 8(t1)    # UART_ST
  d8:	00832383          	lw	t2,8(t1)
    andi t2, t2, 2  # RX available
  dc:	0023f393          	andi	t2,t2,2
    beqz t2, 2b
  e0:	fe038ce3          	beqz	t2,d8 <sbi_getchar+0xc>

    lb a0, 4(t1)    # UART_RX
  e4:	00430503          	lb	a0,4(t1)
    j sbi_ret
  e8:	0040006f          	j	ec <sbi_ret>

000000ec <sbi_ret>:

/* ------------------------------------------------------------
 * SBI return
 * ------------------------------------------------------------ */
sbi_ret:
    csrr t0, mepc
  ec:	341022f3          	csrr	t0,mepc
    addi t0, t0, 4
  f0:	00428293          	addi	t0,t0,4 # 100004 <_mstack_top+0xfeed4>
    csrw mepc, t0
  f4:	34129073          	csrw	mepc,t0

    lw      ra,   0(sp)
  f8:	00012083          	lw	ra,0(sp)
    lw      t0,   4(sp)
  fc:	00412283          	lw	t0,4(sp)
    lw      t1,   8(sp)
 100:	00812303          	lw	t1,8(sp)
    lw      t2,  12(sp)
 104:	00c12383          	lw	t2,12(sp)
    lw      a0,  16(sp)
 108:	01012503          	lw	a0,16(sp)
    lw      a1,  20(sp)
 10c:	01412583          	lw	a1,20(sp)
    lw      a2,  24(sp)
 110:	01812603          	lw	a2,24(sp)
    lw      a3,  28(sp)
 114:	01c12683          	lw	a3,28(sp)
    lw      a4,  32(sp)
 118:	02012703          	lw	a4,32(sp)
    lw      a5,  36(sp)
 11c:	02412783          	lw	a5,36(sp)
    lw      a6,  40(sp)
 120:	02812803          	lw	a6,40(sp)
    lw      a7,  44(sp)
 124:	02c12883          	lw	a7,44(sp)
    addi    sp, sp, 128
 128:	08010113          	addi	sp,sp,128

    mret
 12c:	30200073          	mret

Disassembly of section .riscv.attributes:

00000000 <.riscv.attributes>:
   0:	3c41                	.insn	2, 0x3c41
    la      sp, _mstack_top
   2:	0000                	.insn	2, 0x0000
   4:	7200                	.insn	2, 0x7200
   6:	7369                	.insn	2, 0x7369
    la      t0, m_trap_vector
   8:	01007663          	bgeu	zero,a6,14 <_start+0x14>
   c:	0032                	.insn	2, 0x0032
   e:	0000                	.insn	2, 0x0000
    csrw    mtvec, t0
  10:	7205                	.insn	2, 0x7205
  12:	3376                	.insn	2, 0x3376
    csrw    satp, zero
  14:	6932                	.insn	2, 0x6932
  16:	7032                	.insn	2, 0x7032
    li      t0, (1 << 8)
  18:	5f31                	.insn	2, 0x5f31
  1a:	326d                	.insn	2, 0x326d
    csrw    medeleg, t0
  1c:	3070                	.insn	2, 0x3070
  1e:	7a5f 6369 7273      	.insn	6, 0x727363697a5f
    li      t1, ~(3 << 11)     # MPP mask clear
  24:	7032                	.insn	2, 0x7032
  26:	5f30                	.insn	2, 0x5f30
  28:	697a                	.insn	2, 0x697a
  2a:	6566                	.insn	2, 0x6566
    and     t0, t0, t1
  2c:	636e                	.insn	2, 0x636e
  2e:	6965                	.insn	2, 0x6965
    li      t1, (1 << 11)      # MPP = S
  30:	7032                	.insn	2, 0x7032
  32:	5f30                	.insn	2, 0x5f30
  34:	6d7a                	.insn	2, 0x6d7a
  36:	756d                	.insn	2, 0x756d
    or      t0, t0, t1
  38:	316c                	.insn	2, 0x316c
  3a:	3070                	.insn	2, 0x3070
	...

Disassembly of section .debug_info:

00000000 <.debug_info>:
   0:	013e                	.insn	2, 0x013e
    la      sp, _mstack_top
   2:	0000                	.insn	2, 0x0000
   4:	0005                	.insn	2, 0x0005
   6:	0401                	.insn	2, 0x0401
    la      t0, m_trap_vector
   8:	0000                	.insn	2, 0x0000
   a:	0000                	.insn	2, 0x0000
   c:	0001                	.insn	2, 0x0001
   e:	0000                	.insn	2, 0x0000
    csrw    mtvec, t0
  10:	0000                	.insn	2, 0x0000
  12:	0000                	.insn	2, 0x0000
    csrw    satp, zero
  14:	3000                	.insn	2, 0x3000
  16:	0001                	.insn	2, 0x0001
    li      t0, (1 << 8)
  18:	2e00                	.insn	2, 0x2e00
  1a:	6372732f          	.insn	4, 0x6372732f
    csrw    medeleg, t0
  1e:	6373702f          	.insn	4, 0x6373702f
    csrr    t0, mstatus
  22:	6d5f 6962 736f      	.insn	6, 0x736f69626d5f
    li      t1, ~(3 << 11)     # MPP mask clear
  28:	532e                	.insn	2, 0x532e
  2a:	2f00                	.insn	2, 0x2f00
    and     t0, t0, t1
  2c:	6f68                	.insn	2, 0x6f68
  2e:	656d                	.insn	2, 0x656d
    li      t1, (1 << 11)      # MPP = S
  30:	7261682f          	.insn	4, 0x7261682f
  34:	6875                	.insn	2, 0x6875
  36:	6b69                	.insn	2, 0x6b69
    or      t0, t0, t1
  38:	72502f6f          	jal	t5,2f5c <_mstack_top+0x1e2c>
    csrw    mstatus, t0
  3c:	6172676f          	jal	a4,26e52 <_mstack_top+0x25d22>
    li t0, 0x00100000
  40:	2f6d                	.insn	2, 0x2f6d
  42:	5350                	.insn	2, 0x5350
    csrw mepc, t0
  44:	56525f43          	.insn	4, 0x56525f43
    mret
  48:	2f493233          	.insn	4, 0x2f493233
    addi    sp, sp, -128
  4c:	5350                	.insn	2, 0x5350
  4e:	4e4f2d43          	.insn	4, 0x4e4f2d43
    sw      ra,   0(sp)
  52:	2f45                	.insn	2, 0x2f45
    sw      t0,   4(sp)
  54:	74666f73          	csrrsi	t5,0x746,12
    sw      t1,   8(sp)
  58:	65726177          	.insn	4, 0x65726177
    sw      t2,  12(sp)
  5c:	00736f2f          	.insn	4, 0x00736f2f
    sw      a0,  16(sp)
  60:	6255                	.insn	2, 0x6255
  62:	6e75                	.insn	2, 0x6e75
    sw      a1,  20(sp)
  64:	7574                	.insn	2, 0x7574
  66:	6320                	.insn	2, 0x6320
    sw      a2,  24(sp)
  68:	616c                	.insn	2, 0x616c
  6a:	676e                	.insn	2, 0x676e
    sw      a3,  28(sp)
  6c:	7620                	.insn	2, 0x7620
  6e:	7265                	.insn	2, 0x7265
    sw      a4,  32(sp)
  70:	6e6f6973          	csrrsi	s2,0x6e6,30
    sw      a5,  36(sp)
  74:	3220                	.insn	2, 0x3220
  76:	2e31                	.insn	2, 0x2e31
    sw      a6,  40(sp)
  78:	2e31                	.insn	2, 0x2e31
  7a:	2038                	.insn	2, 0x2038
    sw      a7,  44(sp)
  7c:	3628                	.insn	2, 0x3628
  7e:	6275                	.insn	2, 0x6275
    csrr    t0, mcause
  80:	6e75                	.insn	2, 0x6e75
  82:	7574                	.insn	2, 0x7574
    li      t1, 9              # S-mode ECALL
  84:	2931                	.insn	2, 0x2931
  86:	0100                	.insn	2, 0x0100
    beq     t0, t1, sbi_ecall
  88:	0280                	.insn	2, 0x0280
  8a:	72617473          	csrrci	s0,mhpmevent6h,2
    j       illegal
  8e:	0074                	.insn	2, 0x0074
    li t1, 1
  90:	0000                	.insn	2, 0x0000
  92:	0000                	.insn	2, 0x0000
    beq a7, t1, sbi_putchar
  94:	00000017          	auipc	zero,0x0
    li t1, 2
  98:	0000                	.insn	2, 0x0000
  9a:	0000                	.insn	2, 0x0000
    beq a7, t1, sbi_getchar
  9c:	6d02                	.insn	2, 0x6d02
  9e:	745f 6172 5f70      	.insn	6, 0x5f706172745f
    j illegal
  a4:	6576                	.insn	2, 0x6576
  a6:	726f7463          	bgeu	t5,t1,7ce <_mstack+0x69e>
    la t1, uart_base
  aa:	0000                	.insn	2, 0x0000
  ac:	0000                	.insn	2, 0x0000
  ae:	3a00                	.insn	2, 0x3a00
    lw t1, 0(t1)
  b0:	0000                	.insn	2, 0x0000
  b2:	4c00                	.insn	2, 0x4c00
    lw t2, 8(t1)   # UART_ST
  b4:	0000                	.insn	2, 0x0000
  b6:	0200                	.insn	2, 0x0200
    andi t2, t2, 1 # TX busy
  b8:	6c69                	.insn	2, 0x6c69
  ba:	656c                	.insn	2, 0x656c
    bnez t2, 1b
  bc:	006c6167          	.insn	4, 0x006c6167
    sb a0, 0(t1)   # UART_TX
  c0:	0000                	.insn	2, 0x0000
  c2:	0000                	.insn	2, 0x0000
    li a0, 0       # return OK
  c4:	004d                	.insn	2, 0x004d
  c6:	0000                	.insn	2, 0x0000
    j sbi_ret
  c8:	008c                	.insn	2, 0x008c
  ca:	0000                	.insn	2, 0x0000
    la t1, uart_base
  cc:	7302                	.insn	2, 0x7302
  ce:	6962                	.insn	2, 0x6962
  d0:	655f 6163 6c6c      	.insn	6, 0x6c6c6163655f
    lw t1, 0(t1)
  d6:	0000                	.insn	2, 0x0000
    lw t2, 8(t1)    # UART_ST
  d8:	0000                	.insn	2, 0x0000
  da:	5500                	.insn	2, 0x5500
    andi t2, t2, 2  # RX available
  dc:	0000                	.insn	2, 0x0000
  de:	9000                	.insn	2, 0x9000
    beqz t2, 2b
  e0:	0000                	.insn	2, 0x0000
  e2:	0200                	.insn	2, 0x0200
    lb a0, 4(t1)    # UART_RX
  e4:	6175                	.insn	2, 0x6175
  e6:	7472                	.insn	2, 0x7472
    j sbi_ret
  e8:	625f 7361 0065      	.insn	6, 0x00657361625f
    csrr t0, mepc
  ee:	0000                	.insn	2, 0x0000
    addi t0, t0, 4
  f0:	0000                	.insn	2, 0x0000
  f2:	0062                	.insn	2, 0x0062
    csrw mepc, t0
  f4:	0000                	.insn	2, 0x0000
  f6:	00a4                	.insn	2, 0x00a4
    lw      ra,   0(sp)
  f8:	0000                	.insn	2, 0x0000
  fa:	7302                	.insn	2, 0x7302
    lw      t0,   4(sp)
  fc:	6962                	.insn	2, 0x6962
  fe:	705f 7475 6863      	.insn	6, 0x68637475705f
    lw      t2,  12(sp)
 104:	7261                	.insn	2, 0x7261
 106:	0000                	.insn	2, 0x0000
    lw      a0,  16(sp)
 108:	0000                	.insn	2, 0x0000
 10a:	6800                	.insn	2, 0x6800
    lw      a1,  20(sp)
 10c:	0000                	.insn	2, 0x0000
 10e:	a800                	.insn	2, 0xa800
    lw      a2,  24(sp)
 110:	0000                	.insn	2, 0x0000
 112:	0200                	.insn	2, 0x0200
    lw      a3,  28(sp)
 114:	5f696273          	csrrsi	tp,0x5f6,18
    lw      a4,  32(sp)
 118:	63746567          	.insn	4, 0x63746567
    lw      a5,  36(sp)
 11c:	6168                	.insn	2, 0x6168
 11e:	0072                	.insn	2, 0x0072
    lw      a6,  40(sp)
 120:	0000                	.insn	2, 0x0000
 122:	0000                	.insn	2, 0x0000
    lw      a7,  44(sp)
 124:	0078                	.insn	2, 0x0078
 126:	0000                	.insn	2, 0x0000
    addi    sp, sp, 128
 128:	00cc                	.insn	2, 0x00cc
 12a:	0000                	.insn	2, 0x0000
    mret
 12c:	7302                	.insn	2, 0x7302
 12e:	6962                	.insn	2, 0x6962
 130:	725f 7465 0000      	.insn	6, 0x7465725f
 136:	0000                	.insn	2, 0x0000
 138:	8700                	.insn	2, 0x8700
 13a:	0000                	.insn	2, 0x0000
 13c:	ec00                	.insn	2, 0xec00
 13e:	0000                	.insn	2, 0x0000
	...

Disassembly of section .debug_abbrev:

00000000 <.debug_abbrev>:
   0:	1101                	.insn	2, 0x1101
    la      sp, _mstack_top
   2:	1001                	.insn	2, 0x1001
   4:	12011117          	auipc	sp,0x12011
    la      t0, m_trap_vector
   8:	0301                	.insn	2, 0x0301
   a:	1b08                	.insn	2, 0x1b08
   c:	2508                	.insn	2, 0x2508
   e:	1308                	.insn	2, 0x1308
    csrw    mtvec, t0
  10:	0005                	.insn	2, 0x0005
  12:	0200                	.insn	2, 0x0200
    csrw    satp, zero
  14:	000a                	.insn	2, 0x000a
  16:	063a0803          	lb	a6,99(s4)
    li      t0, (1 << 8)
  1a:	0111063b          	.insn	4, 0x0111063b
    csrw    medeleg, t0
  1e:	0000                	.insn	2, 0x0000
	...

Disassembly of section .debug_aranges:

00000000 <.debug_aranges>:
   0:	001c                	.insn	2, 0x001c
    la      sp, _mstack_top
   2:	0000                	.insn	2, 0x0000
   4:	0002                	.insn	2, 0x0002
   6:	0000                	.insn	2, 0x0000
    la      t0, m_trap_vector
   8:	0000                	.insn	2, 0x0000
   a:	0004                	.insn	2, 0x0004
	...
    csrw    satp, zero
  14:	0130                	.insn	2, 0x0130
	...

Disassembly of section .debug_line:

00000000 <.debug_line>:
   0:	009d                	.insn	2, 0x009d
    la      sp, _mstack_top
   2:	0000                	.insn	2, 0x0000
   4:	0005                	.insn	2, 0x0005
   6:	0004                	.insn	2, 0x0004
    la      t0, m_trap_vector
   8:	0025                	.insn	2, 0x0025
   a:	0000                	.insn	2, 0x0000
   c:	0101                	.insn	2, 0x0101
   e:	fb01                	.insn	2, 0xfb01
    csrw    mtvec, t0
  10:	0d0e                	.insn	2, 0x0d0e
  12:	0100                	.insn	2, 0x0100
    csrw    satp, zero
  14:	0101                	.insn	2, 0x0101
  16:	0001                	.insn	2, 0x0001
    li      t0, (1 << 8)
  18:	0000                	.insn	2, 0x0000
  1a:	0001                	.insn	2, 0x0001
    csrw    medeleg, t0
  1c:	0100                	.insn	2, 0x0100
  1e:	0101                	.insn	2, 0x0101
    csrr    t0, mstatus
  20:	011f 0000 0000      	.insn	6, 0x011f
    li      t1, ~(3 << 11)     # MPP mask clear
  26:	0102                	.insn	2, 0x0102
  28:	021f 010f 0035      	.insn	6, 0x0035010f021f
    and     t0, t0, t1
  2e:	0000                	.insn	2, 0x0000
    li      t1, (1 << 11)      # MPP = S
  30:	0400                	.insn	2, 0x0400
  32:	0000                	.insn	2, 0x0000
  34:	0205                	.insn	2, 0x0205
  36:	0000                	.insn	2, 0x0000
    or      t0, t0, t1
  38:	0000                	.insn	2, 0x0000
  3a:	85011003          	lh	zero,-1968(sp) # 12010854 <_mstack_top+0x1200f724>
    csrw    mstatus, t0
  3e:	4b4d4d83          	lbu	s11,1204(s10)
    li t0, 0x00100000
  42:	4b4d                	.insn	2, 0x4b4d
    csrw mepc, t0
  44:	4b834b83          	lbu	s7,1208(t1)
    mret
  48:	4f4e                	.insn	2, 0x4f4e
  4a:	4b4b504b          	.insn	4, 0x4b4b504b
    addi    sp, sp, -128
  4e:	4b4b4b4b          	.insn	4, 0x4b4b4b4b
    sw      ra,   0(sp)
  52:	4b4b4b4b          	.insn	4, 0x4b4b4b4b
    sw      t0,   4(sp)
  56:	4b4c4b4b          	.insn	4, 0x4b4c4b4b
    sw      t1,   8(sp)
  5a:	0903034b          	.insn	4, 0x0903034b
    sw      t2,  12(sp)
  5e:	0004                	.insn	2, 0x0004
    sw      a0,  16(sp)
  60:	5201                	.insn	2, 0x5201
  62:	0902034b          	.insn	4, 0x0902034b
    sw      a1,  20(sp)
  66:	0004                	.insn	2, 0x0004
    sw      a2,  24(sp)
  68:	4b01                	.insn	2, 0x4b01
  6a:	04090203          	lb	tp,64(s2)
    sw      a3,  28(sp)
  6e:	0100                	.insn	2, 0x0100
    sw      a4,  32(sp)
  70:	83820d03          	lb	s10,-1992(tp) # fffff838 <_mstack_top+0xffffe708>
    sw      a5,  36(sp)
  74:	4b4d                	.insn	2, 0x4b4d
  76:	0902034b          	.insn	4, 0x0902034b
    sw      a6,  40(sp)
  7a:	0004                	.insn	2, 0x0004
    sw      a7,  44(sp)
  7c:	4b01                	.insn	2, 0x4b01
  7e:	4d83504b          	.insn	4, 0x4d83504b
    csrr    t0, mcause
  82:	02034b4b          	.insn	4, 0x02034b4b
    li      t1, 9              # S-mode ECALL
  86:	0409                	.insn	2, 0x0409
    beq     t0, t1, sbi_ecall
  88:	0100                	.insn	2, 0x0100
  8a:	4b4b504b          	.insn	4, 0x4b4b504b
    j       illegal
  8e:	4b4c                	.insn	2, 0x4b4c
    li t1, 1
  90:	4b4b4b4b          	.insn	4, 0x4b4b4b4b
    beq a7, t1, sbi_putchar
  94:	4b4b4b4b          	.insn	4, 0x4b4b4b4b
    li t1, 2
  98:	4c4b4b4b          	.insn	4, 0x4c4b4b4b
    beq a7, t1, sbi_getchar
  9c:	0402                	.insn	2, 0x0402
  9e:	0100                	.insn	2, 0x0100
    j illegal
  a0:	01                	.byte	0x01

Disassembly of section .debug_line_str:

00000000 <.debug_line_str>:
   0:	6d6f682f          	.insn	4, 0x6d6f682f
    la      sp, _mstack_top
   4:	2f65                	.insn	2, 0x2f65
   6:	6168                	.insn	2, 0x6168
    la      t0, m_trap_vector
   8:	7572                	.insn	2, 0x7572
   a:	6968                	.insn	2, 0x6968
   c:	502f6f6b          	.insn	4, 0x502f6f6b
    csrw    mtvec, t0
  10:	6f72                	.insn	2, 0x6f72
  12:	6d617267          	.insn	4, 0x6d617267
    csrw    satp, zero
  16:	4353502f          	.insn	4, 0x4353502f
    li      t0, (1 << 8)
  1a:	525f 3356 4932      	.insn	6, 0x49323356525f
    csrr    t0, mstatus
  20:	4353502f          	.insn	4, 0x4353502f
    li      t1, ~(3 << 11)     # MPP mask clear
  24:	4f2d                	.insn	2, 0x4f2d
  26:	454e                	.insn	2, 0x454e
  28:	666f732f          	.insn	4, 0x666f732f
    and     t0, t0, t1
  2c:	7774                	.insn	2, 0x7774
  2e:	7261                	.insn	2, 0x7261
    li      t1, (1 << 11)      # MPP = S
  30:	2f65                	.insn	2, 0x2f65
  32:	2e00736f          	jal	t1,7312 <_mstack_top+0x61e2>
  36:	6372732f          	.insn	4, 0x6372732f
    or      t0, t0, t1
  3a:	6373702f          	.insn	4, 0x6373702f
    csrw    mstatus, t0
  3e:	6d5f 6962 736f      	.insn	6, 0x736f69626d5f
    csrw mepc, t0
  44:	532e                	.insn	2, 0x532e
	...
