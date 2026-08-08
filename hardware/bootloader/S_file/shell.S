
./build/shell.elf:     file format elf32-littleriscv


Disassembly of section .text:

00400000 <start>:

/* ===== エントリ ===== */
__attribute__((section(".text.start")))
__attribute__((naked))
void start(void) {
    __asm__ __volatile__(
  400000:	00423537          	lui	a0,0x423
  400004:	44050513          	addi	a0,a0,1088 # 423440 <__user_stack_top>
  400008:	00050113          	mv	sp,a0
  40000c:	00000097          	auipc	ra,0x0
  400010:	010080e7          	jalr	16(ra) # 40001c <main>
  400014:	00001097          	auipc	ra,0x1
  400018:	a1c080e7          	jalr	-1508(ra) # 400a30 <exit>

0040001c <main>:
// shell.c
#include "user.h"
#include "fat32.h"

void main(void) {
  40001c:	f8010113          	addi	sp,sp,-128
  400020:	06112e23          	sw	ra,124(sp)
  400024:	06812c23          	sw	s0,120(sp)
  400028:	06912a23          	sw	s1,116(sp)
  40002c:	07212823          	sw	s2,112(sp)
  400030:	07312623          	sw	s3,108(sp)
  400034:	07412423          	sw	s4,104(sp)
  400038:	07512223          	sw	s5,100(sp)
  40003c:	07612023          	sw	s6,96(sp)
  400040:	05712e23          	sw	s7,92(sp)
  400044:	05812c23          	sw	s8,88(sp)
  400048:	05912a23          	sw	s9,84(sp)
  40004c:	05a12823          	sw	s10,80(sp)
  400050:	05b12623          	sw	s11,76(sp)

    //SA API call
    //printf("call sa start.\n");
    call_sa_api(0x04);
  400054:	00400513          	li	a0,4
  400058:	00001097          	auipc	ra,0x1
  40005c:	9f0080e7          	jalr	-1552(ra) # 400a48 <call_sa_api>

    // DUMP API call
    //call_dump_api();


    printf("shell start.\n");
  400060:	00402537          	lui	a0,0x402
  400064:	ed450513          	addi	a0,a0,-300 # 401ed4 <__modsi3+0x68>
  400068:	00001097          	auipc	ra,0x1
  40006c:	c44080e7          	jalr	-956(ra) # 400cac <printf>
  400070:	00000913          	li	s2,0
  400074:	02000d13          	li	s10,32
  400078:	00402437          	lui	s0,0x402
  40007c:	ee240413          	addi	s0,s0,-286 # 401ee2 <__modsi3+0x76>
  400080:	004024b7          	lui	s1,0x402
  400084:	eef48493          	addi	s1,s1,-273 # 401eef <__modsi3+0x83>
  400088:	00a00c13          	li	s8,10
  40008c:	00c00c93          	li	s9,12
  400090:	00800b93          	li	s7,8
  400094:	00900b13          	li	s6,9
  400098:	00018537          	lui	a0,0x18
  40009c:	6a050513          	addi	a0,a0,1696 # 186a0 <start-0x3e7960>
  4000a0:	00a12423          	sw	a0,8(sp)
  4000a4:	01f00a93          	li	s5,31
  4000a8:	07f00993          	li	s3,127
  4000ac:	0180006f          	j	4000c4 <main+0xa8>

        if (argc == 0) continue;

        /* ===== コマンド分岐 ===== */
        if (strcmp(argv[0], "hello") == 0) {
            printf("Hello world from shell!\n");
  4000b0:	00402537          	lui	a0,0x402
  4000b4:	f0250513          	addi	a0,a0,-254 # 401f02 <__modsi3+0x96>
  4000b8:	00001097          	auipc	ra,0x1
  4000bc:	bf4080e7          	jalr	-1036(ra) # 400cac <printf>
  4000c0:	01f00a93          	li	s5,31
        putchar(0x1B); putchar('['); putchar('3'); putchar('4'); putchar('m'); // 青
  4000c4:	01b00513          	li	a0,27
  4000c8:	00001097          	auipc	ra,0x1
  4000cc:	e9c080e7          	jalr	-356(ra) # 400f64 <putchar>
  4000d0:	05b00513          	li	a0,91
  4000d4:	00001097          	auipc	ra,0x1
  4000d8:	e90080e7          	jalr	-368(ra) # 400f64 <putchar>
  4000dc:	03300513          	li	a0,51
  4000e0:	00001097          	auipc	ra,0x1
  4000e4:	e84080e7          	jalr	-380(ra) # 400f64 <putchar>
  4000e8:	03400513          	li	a0,52
  4000ec:	00001097          	auipc	ra,0x1
  4000f0:	e78080e7          	jalr	-392(ra) # 400f64 <putchar>
  4000f4:	06d00513          	li	a0,109
  4000f8:	00001097          	auipc	ra,0x1
  4000fc:	e6c080e7          	jalr	-404(ra) # 400f64 <putchar>
        putchar('P');
  400100:	05000513          	li	a0,80
  400104:	00001097          	auipc	ra,0x1
  400108:	e60080e7          	jalr	-416(ra) # 400f64 <putchar>
        putchar('S');
  40010c:	05300513          	li	a0,83
  400110:	00001097          	auipc	ra,0x1
  400114:	e54080e7          	jalr	-428(ra) # 400f64 <putchar>
        putchar('C');
  400118:	04300513          	li	a0,67
  40011c:	00001097          	auipc	ra,0x1
  400120:	e48080e7          	jalr	-440(ra) # 400f64 <putchar>
        putchar('_');
  400124:	05f00513          	li	a0,95
  400128:	00001097          	auipc	ra,0x1
  40012c:	e3c080e7          	jalr	-452(ra) # 400f64 <putchar>
        putchar('O');
  400130:	04f00513          	li	a0,79
  400134:	00001097          	auipc	ra,0x1
  400138:	e30080e7          	jalr	-464(ra) # 400f64 <putchar>
        putchar('S');
  40013c:	05300513          	li	a0,83
  400140:	00001097          	auipc	ra,0x1
  400144:	e24080e7          	jalr	-476(ra) # 400f64 <putchar>
        putchar('>');
  400148:	03e00513          	li	a0,62
  40014c:	00001097          	auipc	ra,0x1
  400150:	e18080e7          	jalr	-488(ra) # 400f64 <putchar>
        putchar(' ');
  400154:	02000513          	li	a0,32
  400158:	00001097          	auipc	ra,0x1
  40015c:	e0c080e7          	jalr	-500(ra) # 400f64 <putchar>
        putchar(0x1B); putchar('['); putchar('0'); putchar('m'); // リセット
  400160:	01b00513          	li	a0,27
  400164:	00001097          	auipc	ra,0x1
  400168:	e00080e7          	jalr	-512(ra) # 400f64 <putchar>
  40016c:	05b00513          	li	a0,91
  400170:	00001097          	auipc	ra,0x1
  400174:	df4080e7          	jalr	-524(ra) # 400f64 <putchar>
  400178:	03000513          	li	a0,48
  40017c:	00001097          	auipc	ra,0x1
  400180:	de8080e7          	jalr	-536(ra) # 400f64 <putchar>
  400184:	06d00513          	li	a0,109
  400188:	00000a13          	li	s4,0
  40018c:	0ff57513          	zext.b	a0,a0
  400190:	00001097          	auipc	ra,0x1
  400194:	dd4080e7          	jalr	-556(ra) # 400f64 <putchar>
  400198:	00090d93          	mv	s11,s2
  40019c:	0100006f          	j	4001ac <main+0x190>
            if (ch == 8 || ch == 127) {
  4001a0:	07351e63          	bne	a0,s3,40021c <main+0x200>
  4001a4:	00090d93          	mv	s11,s2
                if (len > 0) {
  4001a8:	0b404263          	bgtz	s4,40024c <main+0x230>
            uint32_t sw = poll_switch_api() & 0x03;
  4001ac:	00001097          	auipc	ra,0x1
  4001b0:	0f8080e7          	jalr	248(ra) # 4012a4 <poll_switch_api>
            bool sw1_pressed = ((prev_sw & 0x01) != 0) && ((sw & 0x01) == 0);
  4001b4:	001df593          	andi	a1,s11,1
            uint32_t sw = poll_switch_api() & 0x03;
  4001b8:	00050913          	mv	s2,a0
            if (sw1_pressed) {
  4001bc:	00058c63          	beqz	a1,4001d4 <main+0x1b8>
  4001c0:	00197513          	andi	a0,s2,1
  4001c4:	00051863          	bnez	a0,4001d4 <main+0x1b8>
                printf("SW1 pressed\n");
  4001c8:	00040513          	mv	a0,s0
  4001cc:	00001097          	auipc	ra,0x1
  4001d0:	ae0080e7          	jalr	-1312(ra) # 400cac <printf>
  4001d4:	001dd513          	srli	a0,s11,0x1
  4001d8:	00297593          	andi	a1,s2,2
  4001dc:	0015b593          	seqz	a1,a1
  4001e0:	00b57533          	and	a0,a0,a1
            if (sw2_pressed) {
  4001e4:	00050863          	beqz	a0,4001f4 <main+0x1d8>
                printf("SW2 pressed\n");
  4001e8:	00048513          	mv	a0,s1
  4001ec:	00001097          	auipc	ra,0x1
  4001f0:	ac0080e7          	jalr	-1344(ra) # 400cac <printf>
            int ch = getchar_timeout();
  4001f4:	00001097          	auipc	ra,0x1
  4001f8:	090080e7          	jalr	144(ra) # 401284 <getchar_timeout>
  4001fc:	00090d93          	mv	s11,s2
            if (ch < 0) {
  400200:	fa0546e3          	bltz	a0,4001ac <main+0x190>
            if (ch == '\n' && len == 0) {
  400204:	01851463          	bne	a0,s8,40020c <main+0x1f0>
  400208:	f80a08e3          	beqz	s4,400198 <main+0x17c>
            if (ch == 8 || ch == 127) {
  40020c:	f8accae3          	blt	s9,a0,4001a0 <main+0x184>
  400210:	f9750ae3          	beq	a0,s7,4001a4 <main+0x188>
  400214:	01851863          	bne	a0,s8,400224 <main+0x208>
  400218:	0580006f          	j	400270 <main+0x254>
  40021c:	00d00593          	li	a1,13
  400220:	04b50863          	beq	a0,a1,400270 <main+0x254>
  400224:	00aae663          	bltu	s5,a0,400230 <main+0x214>
  400228:	00090d93          	mv	s11,s2
  40022c:	f96510e3          	bne	a0,s6,4001ac <main+0x190>
            if (len >= (int)sizeof(cmdline) - 1) {
  400230:	01e00593          	li	a1,30
  400234:	e945c8e3          	blt	a1,s4,4000c4 <main+0xa8>
            cmdline[len++] = (char)ch;
  400238:	02c10593          	addi	a1,sp,44
  40023c:	014585b3          	add	a1,a1,s4
  400240:	001a0a13          	addi	s4,s4,1
  400244:	00a58023          	sb	a0,0(a1)
        }
  400248:	f45ff06f          	j	40018c <main+0x170>
                    len--;
  40024c:	fffa0a13          	addi	s4,s4,-1
                    putchar('\b');
  400250:	00800513          	li	a0,8
  400254:	00001097          	auipc	ra,0x1
  400258:	d10080e7          	jalr	-752(ra) # 400f64 <putchar>
                    putchar(' ');
  40025c:	02000513          	li	a0,32
  400260:	00001097          	auipc	ra,0x1
  400264:	d04080e7          	jalr	-764(ra) # 400f64 <putchar>
  400268:	00800513          	li	a0,8
                }
  40026c:	f21ff06f          	j	40018c <main+0x170>
                putchar('\n');
  400270:	00a00513          	li	a0,10
  400274:	00001097          	auipc	ra,0x1
  400278:	cf0080e7          	jalr	-784(ra) # 400f64 <putchar>
                cmdline[len] = '\0';
  40027c:	02c10513          	addi	a0,sp,44
  400280:	01450533          	add	a0,a0,s4
  400284:	00050023          	sb	zero,0(a0)
  400288:	e20a0ee3          	beqz	s4,4000c4 <main+0xa8>
  40028c:	02c10513          	addi	a0,sp,44
  400290:	0080006f          	j	400298 <main+0x27c>
        while (*p == ' ' || *p == '\t') p++;
  400294:	00150513          	addi	a0,a0,1
  400298:	00054583          	lbu	a1,0(a0)
  40029c:	ff658ce3          	beq	a1,s6,400294 <main+0x278>
  4002a0:	ffa58ae3          	beq	a1,s10,400294 <main+0x278>
  4002a4:	e20580e3          	beqz	a1,4000c4 <main+0xa8>
  4002a8:	00000a93          	li	s5,0
  4002ac:	00c10693          	addi	a3,sp,12
  4002b0:	00600713          	li	a4,6
  4002b4:	00050593          	mv	a1,a0
  4002b8:	000a8a13          	mv	s4,s5
            argv[argc++] = p;
  4002bc:	001a8a93          	addi	s5,s5,1
  4002c0:	002a1513          	slli	a0,s4,0x2
  4002c4:	00a68533          	add	a0,a3,a0
  4002c8:	00b52023          	sw	a1,0(a0)
            while (*p && *p != ' ' && *p != '\t') p++;
  4002cc:	00158513          	addi	a0,a1,1
  4002d0:	0005c603          	lbu	a2,0(a1)
  4002d4:	04060063          	beqz	a2,400314 <main+0x2f8>
  4002d8:	01660e63          	beq	a2,s6,4002f4 <main+0x2d8>
  4002dc:	01a60c63          	beq	a2,s10,4002f4 <main+0x2d8>
  4002e0:	00158593          	addi	a1,a1,1
  4002e4:	00150513          	addi	a0,a0,1
  4002e8:	0005c603          	lbu	a2,0(a1)
  4002ec:	fe0616e3          	bnez	a2,4002d8 <main+0x2bc>
  4002f0:	0240006f          	j	400314 <main+0x2f8>
            *p++ = '\0';
  4002f4:	00058023          	sb	zero,0(a1)
  4002f8:	0080006f          	j	400300 <main+0x2e4>
  4002fc:	00150513          	addi	a0,a0,1
            while (*p == ' ' || *p == '\t') p++;
  400300:	00054583          	lbu	a1,0(a0)
  400304:	ffa58ce3          	beq	a1,s10,4002fc <main+0x2e0>
  400308:	ff658ae3          	beq	a1,s6,4002fc <main+0x2e0>
        while (*p && argc < ARGV_MAX) {
  40030c:	00058463          	beqz	a1,400314 <main+0x2f8>
  400310:	fb4772e3          	bgeu	a4,s4,4002b4 <main+0x298>
        if (strcmp(argv[0], "hello") == 0) {
  400314:	00c12503          	lw	a0,12(sp)
  400318:	00050d93          	mv	s11,a0
  40031c:	004025b7          	lui	a1,0x402
  400320:	efc58593          	addi	a1,a1,-260 # 401efc <__modsi3+0x90>
  400324:	00001097          	auipc	ra,0x1
  400328:	e24080e7          	jalr	-476(ra) # 401148 <strcmp>
  40032c:	d80502e3          	beqz	a0,4000b0 <main+0x94>

        // ---- Dump ----
        } else if (strcmp(argv[0], "dump") == 0) {
  400330:	000d8513          	mv	a0,s11
  400334:	004025b7          	lui	a1,0x402
  400338:	f1b58593          	addi	a1,a1,-229 # 401f1b <__modsi3+0xaf>
  40033c:	00001097          	auipc	ra,0x1
  400340:	e0c080e7          	jalr	-500(ra) # 401148 <strcmp>
  400344:	1a050063          	beqz	a0,4004e4 <main+0x4c8>
            unsigned lenb = (argc >= 3) ? parse_u32(argv[2]) : 0x100;
            hexdump((const void*)addr, lenb, (uintptr_t)addr);
        */

        // ---- 素数出力サンプル ----
        } else if (strcmp(argv[0], "primes") == 0) {
  400348:	000d8513          	mv	a0,s11
  40034c:	004025b7          	lui	a1,0x402
  400350:	f2058593          	addi	a1,a1,-224 # 401f20 <__modsi3+0xb4>
  400354:	00001097          	auipc	ra,0x1
  400358:	df4080e7          	jalr	-524(ra) # 401148 <strcmp>
  40035c:	01f00a93          	li	s5,31
  400360:	1c050a63          	beqz	a0,400534 <main+0x518>
                }
            }
            cmd_primes(max);

        // ---- セルフテスト ----
        } else if (strcmp(argv[0], "self_test") == 0) {
  400364:	000d8513          	mv	a0,s11
  400368:	004025b7          	lui	a1,0x402
  40036c:	f4158593          	addi	a1,a1,-191 # 401f41 <__modsi3+0xd5>
  400370:	00001097          	auipc	ra,0x1
  400374:	dd8080e7          	jalr	-552(ra) # 401148 <strcmp>
  400378:	d40506e3          	beqz	a0,4000c4 <main+0xa8>
            //TBD
            //cmd_primes(max);

        // ---- SynapEngine ----
        } else if (strcmp(argv[0], "sa_start") == 0) {
  40037c:	000d8513          	mv	a0,s11
  400380:	004025b7          	lui	a1,0x402
  400384:	f4b58593          	addi	a1,a1,-181 # 401f4b <__modsi3+0xdf>
  400388:	00001097          	auipc	ra,0x1
  40038c:	dc0080e7          	jalr	-576(ra) # 401148 <strcmp>
  400390:	24050463          	beqz	a0,4005d8 <main+0x5bc>
            }
            // SA API call 
            call_sa_api(matrix_max);

        // ---- I2S MIC READ ----
        } else if (strcmp(argv[0], "mic_read") == 0) {
  400394:	000d8513          	mv	a0,s11
  400398:	004025b7          	lui	a1,0x402
  40039c:	f6558593          	addi	a1,a1,-155 # 401f65 <__modsi3+0xf9>
  4003a0:	00001097          	auipc	ra,0x1
  4003a4:	da8080e7          	jalr	-600(ra) # 401148 <strcmp>
  4003a8:	28050263          	beqz	a0,40062c <main+0x610>

            unsigned count = parse_u32(argv[1]);
            call_mic_api(count);

        // ---- I2S MIC WRITE to FILE ----
        } else if (strcmp(argv[0], "mic_write") == 0) {
  4003ac:	000d8513          	mv	a0,s11
  4003b0:	004025b7          	lui	a1,0x402
  4003b4:	f8758593          	addi	a1,a1,-121 # 401f87 <__modsi3+0x11b>
  4003b8:	00001097          	auipc	ra,0x1
  4003bc:	d90080e7          	jalr	-624(ra) # 401148 <strcmp>
  4003c0:	2e050463          	beqz	a0,4006a8 <main+0x68c>
            unsigned count = parse_u32(argv[1]);
            //call_mic_write_api(count);
            call_mic_write_file(count);

        // ---- SDカードREAD ----
        } else if (strcmp(argv[0], "sd_read") == 0) {
  4003c4:	000d8513          	mv	a0,s11
  4003c8:	004025b7          	lui	a1,0x402
  4003cc:	fab58593          	addi	a1,a1,-85 # 401fab <__modsi3+0x13f>
  4003d0:	00001097          	auipc	ra,0x1
  4003d4:	d78080e7          	jalr	-648(ra) # 401148 <strcmp>
  4003d8:	30050463          	beqz	a0,4006e0 <main+0x6c4>

            unsigned sd_sector = parse_u32(argv[1]);
            call_sd_read_api(sd_sector);

        // ---- SDカードWRITE TEST----
        } else if (strcmp(argv[0], "sd_write") == 0) {
  4003dc:	000d8513          	mv	a0,s11
  4003e0:	004025b7          	lui	a1,0x402
  4003e4:	fcc58593          	addi	a1,a1,-52 # 401fcc <__modsi3+0x160>
  4003e8:	00001097          	auipc	ra,0x1
  4003ec:	d60080e7          	jalr	-672(ra) # 401148 <strcmp>
  4003f0:	36050663          	beqz	a0,40075c <main+0x740>
                goto prompt;
            }
            call_sd_write_test_api(sd_sector);

        // ---- FAT32 Info ----
        } else if (strcmp(argv[0], "fat32_info") == 0) {
  4003f4:	000d8513          	mv	a0,s11
  4003f8:	004025b7          	lui	a1,0x402
  4003fc:	00e58593          	addi	a1,a1,14 # 40200e <__modsi3+0x1a2>
  400400:	00001097          	auipc	ra,0x1
  400404:	d48080e7          	jalr	-696(ra) # 401148 <strcmp>
  400408:	38050a63          	beqz	a0,40079c <main+0x780>
            printf("spc=%x\n",           g_fat32.sectors_per_cluster);
            printf("fat_begin=%x\n",     g_fat32.fat_begin);
            printf("data_begin=%x\n",    g_fat32.data_begin);

        // ---- FAT32 ls ----
        } else if (strcmp(argv[0], "fat32_ls") == 0) {
  40040c:	000d8513          	mv	a0,s11
  400410:	004025b7          	lui	a1,0x402
  400414:	07058593          	addi	a1,a1,112 # 402070 <__modsi3+0x204>
  400418:	00001097          	auipc	ra,0x1
  40041c:	d30080e7          	jalr	-720(ra) # 401148 <strcmp>
  400420:	3a050063          	beqz	a0,4007c0 <main+0x7a4>

            fat32_ls();

        // ---- FAT32 cat ----
        } else if (strcmp(argv[0], "fat32_cat") == 0) {
  400424:	000d8513          	mv	a0,s11
  400428:	004025b7          	lui	a1,0x402
  40042c:	07958593          	addi	a1,a1,121 # 402079 <__modsi3+0x20d>
  400430:	00001097          	auipc	ra,0x1
  400434:	d18080e7          	jalr	-744(ra) # 401148 <strcmp>
  400438:	38050a63          	beqz	a0,4007cc <main+0x7b0>
            }

            fat32_cat(argv[1]);

        // ---- FAT32 touch ----
        } else if (strcmp(argv[0], "fat32_touch") == 0) {
  40043c:	000d8513          	mv	a0,s11
  400440:	004025b7          	lui	a1,0x402
  400444:	09c58593          	addi	a1,a1,156 # 40209c <__modsi3+0x230>
  400448:	00001097          	auipc	ra,0x1
  40044c:	d00080e7          	jalr	-768(ra) # 401148 <strcmp>
  400450:	40050463          	beqz	a0,400858 <main+0x83c>
            }

            if (fat32_touch(argv[1]) != 0) {
                printf("fat32_touch failed\n");
            } 
        } else if (strcmp(argv[0], "speech") == 0) {
  400454:	000d8513          	mv	a0,s11
  400458:	004025b7          	lui	a1,0x402
  40045c:	0d758593          	addi	a1,a1,215 # 4020d7 <__modsi3+0x26b>
  400460:	00001097          	auipc	ra,0x1
  400464:	ce8080e7          	jalr	-792(ra) # 401148 <strcmp>
  400468:	42050063          	beqz	a0,400888 <main+0x86c>
            cmd_speech();
                    
        // ---- Helps出力 ----
        } else if (strcmp(argv[0], "help") == 0) {
  40046c:	000d8513          	mv	a0,s11
  400470:	004025b7          	lui	a1,0x402
  400474:	0de58593          	addi	a1,a1,222 # 4020de <__modsi3+0x272>
  400478:	00001097          	auipc	ra,0x1
  40047c:	cd0080e7          	jalr	-816(ra) # 401148 <strcmp>
  400480:	40050a63          	beqz	a0,400894 <main+0x878>
            printf("  sa_start\n");
            printf("  sd_read\n");
            printf("  exit | quit | q\n");
            */

        } else if (strcmp(argv[0], "exit") == 0 ||
  400484:	000d8513          	mv	a0,s11
  400488:	004025b7          	lui	a1,0x402
  40048c:	0ee58593          	addi	a1,a1,238 # 4020ee <__modsi3+0x282>
  400490:	00001097          	auipc	ra,0x1
  400494:	cb8080e7          	jalr	-840(ra) # 401148 <strcmp>
  400498:	40050863          	beqz	a0,4008a8 <main+0x88c>
                   strcmp(argv[0], "quit") == 0 ||
  40049c:	000d8513          	mv	a0,s11
  4004a0:	004025b7          	lui	a1,0x402
  4004a4:	0f358593          	addi	a1,a1,243 # 4020f3 <__modsi3+0x287>
  4004a8:	00001097          	auipc	ra,0x1
  4004ac:	ca0080e7          	jalr	-864(ra) # 401148 <strcmp>
  4004b0:	3e050c63          	beqz	a0,4008a8 <main+0x88c>
                   strcmp(argv[0], "q") == 0) {
  4004b4:	000d8513          	mv	a0,s11
  4004b8:	004025b7          	lui	a1,0x402
  4004bc:	0f858593          	addi	a1,a1,248 # 4020f8 <__modsi3+0x28c>
  4004c0:	00001097          	auipc	ra,0x1
  4004c4:	c88080e7          	jalr	-888(ra) # 401148 <strcmp>
                   strcmp(argv[0], "quit") == 0 ||
  4004c8:	3e050063          	beqz	a0,4008a8 <main+0x88c>
            exit();
        
        } else {
            printf("unknown command: %s\n", argv[0]);
  4004cc:	00402537          	lui	a0,0x402
  4004d0:	0fa50513          	addi	a0,a0,250 # 4020fa <__modsi3+0x28e>
  4004d4:	000d8593          	mv	a1,s11
  4004d8:	00000097          	auipc	ra,0x0
  4004dc:	7d4080e7          	jalr	2004(ra) # 400cac <printf>
  4004e0:	be5ff06f          	j	4000c4 <main+0xa8>
  4004e4:	10000593          	li	a1,256
            if (argc >= 2) {
  4004e8:	060a0a63          	beqz	s4,40055c <main+0x540>
                if (parse_hex(argv[1], &val) == 0) {
  4004ec:	01012683          	lw	a3,16(sp)
/* 簡易16進パーサ（"  0x1234" / "1234" 形式どちらも可） */
int parse_hex(const char *s, uintptr_t *out) {
    uintptr_t v = 0;

    /* skip leading spaces */
    while (*s == ' ' || *s == '\t') s++;
  4004f0:	00268693          	addi	a3,a3,2
  4004f4:	00600793          	li	a5,6
  4004f8:	00500813          	li	a6,5
  4004fc:	0080006f          	j	400504 <main+0x4e8>
  400500:	00168693          	addi	a3,a3,1
  400504:	ffe6c603          	lbu	a2,-2(a3)
  400508:	ff660ce3          	beq	a2,s6,400500 <main+0x4e4>
  40050c:	ffa60ae3          	beq	a2,s10,400500 <main+0x4e4>
  400510:	03000513          	li	a0,48
  400514:	04a61e63          	bne	a2,a0,400570 <main+0x554>

    /* optional 0x / 0X */
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s += 2;
  400518:	fff6c503          	lbu	a0,-1(a3)
  40051c:	02056513          	ori	a0,a0,32
  400520:	07800613          	li	a2,120
  400524:	12c51663          	bne	a0,a2,400650 <main+0x634>
    if (!*s) return -1;
  400528:	0006c603          	lbu	a2,0(a3)
  40052c:	12061663          	bnez	a2,400658 <main+0x63c>
  400530:	0480006f          	j	400578 <main+0x55c>
            if (argc >= 2) {
  400534:	0c0a0663          	beqz	s4,400600 <main+0x5e4>
                max = parse_u32(argv[1]);
  400538:	01012503          	lw	a0,16(sp)
  40053c:	00001097          	auipc	ra,0x1
  400540:	c3c080e7          	jalr	-964(ra) # 401178 <parse_u32>
  400544:	00050593          	mv	a1,a0
  400548:	00402537          	lui	a0,0x402
  40054c:	f2750513          	addi	a0,a0,-217 # 401f27 <__modsi3+0xbb>
  400550:	00812603          	lw	a2,8(sp)
                if (max > 100000) {
  400554:	0ab67863          	bgeu	a2,a1,400604 <main+0x5e8>
  400558:	25c0006f          	j	4007b4 <main+0x798>
  40055c:	00200537          	lui	a0,0x200
  400560:	01f00a93          	li	s5,31
            call_dump_api(addr, len);
  400564:	00001097          	auipc	ra,0x1
  400568:	ba4080e7          	jalr	-1116(ra) # 401108 <call_dump_api>
  40056c:	b59ff06f          	j	4000c4 <main+0xa8>
  400570:	ffe68693          	addi	a3,a3,-2
    if (!*s) return -1;
  400574:	0e061263          	bnez	a2,400658 <main+0x63c>
  400578:	00200537          	lui	a0,0x200
            if (argc >= 3) {
  40057c:	00200613          	li	a2,2
  400580:	00ca9a63          	bne	s5,a2,400594 <main+0x578>
  400584:	01f00a93          	li	s5,31
            call_dump_api(addr, len);
  400588:	00001097          	auipc	ra,0x1
  40058c:	b80080e7          	jalr	-1152(ra) # 401108 <call_dump_api>
  400590:	b35ff06f          	j	4000c4 <main+0xa8>
                if (parse_hex(argv[2], &val) == 0) {
  400594:	01412683          	lw	a3,20(sp)
    while (*s == ' ' || *s == '\t') s++;
  400598:	00268693          	addi	a3,a3,2
  40059c:	0080006f          	j	4005a4 <main+0x588>
  4005a0:	00168693          	addi	a3,a3,1
  4005a4:	ffe6c603          	lbu	a2,-2(a3)
  4005a8:	ff660ce3          	beq	a2,s6,4005a0 <main+0x584>
  4005ac:	ffa60ae3          	beq	a2,s10,4005a0 <main+0x584>
  4005b0:	03000713          	li	a4,48
  4005b4:	06e61063          	bne	a2,a4,400614 <main+0x5f8>
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s += 2;
  4005b8:	fff6c603          	lbu	a2,-1(a3)
  4005bc:	02066613          	ori	a2,a2,32
  4005c0:	07800713          	li	a4,120
  4005c4:	01f00a93          	li	s5,31
  4005c8:	12e61e63          	bne	a2,a4,400704 <main+0x6e8>
    if (!*s) return -1;
  4005cc:	0006c603          	lbu	a2,0(a3)
  4005d0:	12061e63          	bnez	a2,40070c <main+0x6f0>
  4005d4:	04c0006f          	j	400620 <main+0x604>
            if (argc >= 2) {
  4005d8:	0e0a0a63          	beqz	s4,4006cc <main+0x6b0>
                matrix_max = parse_u32(argv[1]);
  4005dc:	01012503          	lw	a0,16(sp)
  4005e0:	00001097          	auipc	ra,0x1
  4005e4:	b98080e7          	jalr	-1128(ra) # 401178 <parse_u32>
  4005e8:	00050593          	mv	a1,a0
  4005ec:	00402537          	lui	a0,0x402
  4005f0:	f5450513          	addi	a0,a0,-172 # 401f54 <__modsi3+0xe8>
                if (matrix_max > 4) {
  4005f4:	00400613          	li	a2,4
  4005f8:	0cb67c63          	bgeu	a2,a1,4006d0 <main+0x6b4>
  4005fc:	1b80006f          	j	4007b4 <main+0x798>
  400600:	3e800593          	li	a1,1000
            cmd_primes(max);
  400604:	00058513          	mv	a0,a1
  400608:	00000097          	auipc	ra,0x0
  40060c:	36c080e7          	jalr	876(ra) # 400974 <cmd_primes>
        } else if (strcmp(argv[0], "exit") == 0 ||
  400610:	ab5ff06f          	j	4000c4 <main+0xa8>
  400614:	ffe68693          	addi	a3,a3,-2
  400618:	01f00a93          	li	s5,31
    if (!*s) return -1;
  40061c:	0e061863          	bnez	a2,40070c <main+0x6f0>
            call_dump_api(addr, len);
  400620:	00001097          	auipc	ra,0x1
  400624:	ae8080e7          	jalr	-1304(ra) # 401108 <call_dump_api>
  400628:	a9dff06f          	j	4000c4 <main+0xa8>
  40062c:	00402537          	lui	a0,0x402
  400630:	f6e50513          	addi	a0,a0,-146 # 401f6e <__modsi3+0x102>
            if (argc < 2) {
  400634:	180a0063          	beqz	s4,4007b4 <main+0x798>
            unsigned count = parse_u32(argv[1]);
  400638:	01012503          	lw	a0,16(sp)
  40063c:	00001097          	auipc	ra,0x1
  400640:	b3c080e7          	jalr	-1220(ra) # 401178 <parse_u32>
            call_mic_api(count);
  400644:	00001097          	auipc	ra,0x1
  400648:	948080e7          	jalr	-1720(ra) # 400f8c <call_mic_api>
        } else if (strcmp(argv[0], "exit") == 0 ||
  40064c:	a79ff06f          	j	4000c4 <main+0xa8>
  400650:	ffe68693          	addi	a3,a3,-2
  400654:	03000613          	li	a2,48
  400658:	00000513          	li	a0,0

    while (*s) {
        char c = *s++;
        uint32_t d;
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  40065c:	00168693          	addi	a3,a3,1
  400660:	0200006f          	j	400680 <main+0x664>
  400664:	fd000713          	li	a4,-48
  400668:	00c70733          	add	a4,a4,a2
    while (*s) {
  40066c:	0006c603          	lbu	a2,0(a3)
        else if (c >= 'a' && c <= 'f') d = 10u + (uint32_t)(c - 'a');
        else if (c >= 'A' && c <= 'F') d = 10u + (uint32_t)(c - 'A');
        else break;
        v = (v << 4) | d;
  400670:	00451513          	slli	a0,a0,0x4
  400674:	00a76533          	or	a0,a4,a0
    while (*s) {
  400678:	00168693          	addi	a3,a3,1
  40067c:	f00600e3          	beqz	a2,40057c <main+0x560>
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  400680:	fd060713          	addi	a4,a2,-48
  400684:	ff8760e3          	bltu	a4,s8,400664 <main+0x648>
        else if (c >= 'a' && c <= 'f') d = 10u + (uint32_t)(c - 'a');
  400688:	f9f60713          	addi	a4,a2,-97
  40068c:	00f77663          	bgeu	a4,a5,400698 <main+0x67c>
  400690:	fa900713          	li	a4,-87
  400694:	fd5ff06f          	j	400668 <main+0x64c>
        else if (c >= 'A' && c <= 'F') d = 10u + (uint32_t)(c - 'A');
  400698:	fbf60713          	addi	a4,a2,-65
  40069c:	eee860e3          	bltu	a6,a4,40057c <main+0x560>
  4006a0:	fc900713          	li	a4,-55
  4006a4:	fc5ff06f          	j	400668 <main+0x64c>
  4006a8:	00402537          	lui	a0,0x402
  4006ac:	f9150513          	addi	a0,a0,-111 # 401f91 <__modsi3+0x125>
            if (argc < 2) {
  4006b0:	100a0263          	beqz	s4,4007b4 <main+0x798>
            unsigned count = parse_u32(argv[1]);
  4006b4:	01012503          	lw	a0,16(sp)
  4006b8:	00001097          	auipc	ra,0x1
  4006bc:	ac0080e7          	jalr	-1344(ra) # 401178 <parse_u32>
            call_mic_write_file(count);
  4006c0:	00001097          	auipc	ra,0x1
  4006c4:	8d8080e7          	jalr	-1832(ra) # 400f98 <call_mic_write_file>
        } else if (strcmp(argv[0], "fat32_touch") == 0) {
  4006c8:	9fdff06f          	j	4000c4 <main+0xa8>
  4006cc:	00400593          	li	a1,4
            call_sa_api(matrix_max);
  4006d0:	00058513          	mv	a0,a1
  4006d4:	00000097          	auipc	ra,0x0
  4006d8:	374080e7          	jalr	884(ra) # 400a48 <call_sa_api>
        } else if (strcmp(argv[0], "exit") == 0 ||
  4006dc:	9e9ff06f          	j	4000c4 <main+0xa8>
  4006e0:	00402537          	lui	a0,0x402
  4006e4:	fb350513          	addi	a0,a0,-77 # 401fb3 <__modsi3+0x147>
            if (argc < 2) {
  4006e8:	0c0a0663          	beqz	s4,4007b4 <main+0x798>
            unsigned sd_sector = parse_u32(argv[1]);
  4006ec:	01012503          	lw	a0,16(sp)
  4006f0:	00001097          	auipc	ra,0x1
  4006f4:	a88080e7          	jalr	-1400(ra) # 401178 <parse_u32>
            call_sd_read_api(sd_sector);
  4006f8:	00001097          	auipc	ra,0x1
  4006fc:	958080e7          	jalr	-1704(ra) # 401050 <call_sd_read_api>
        } else if (strcmp(argv[0], "exit") == 0 ||
  400700:	9c5ff06f          	j	4000c4 <main+0xa8>
  400704:	ffe68693          	addi	a3,a3,-2
  400708:	03000613          	li	a2,48
  40070c:	00000593          	li	a1,0
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  400710:	00168693          	addi	a3,a3,1
  400714:	0200006f          	j	400734 <main+0x718>
  400718:	fd000713          	li	a4,-48
  40071c:	00c70733          	add	a4,a4,a2
    while (*s) {
  400720:	0006c603          	lbu	a2,0(a3)
        v = (v << 4) | d;
  400724:	00459593          	slli	a1,a1,0x4
  400728:	00b765b3          	or	a1,a4,a1
    while (*s) {
  40072c:	00168693          	addi	a3,a3,1
  400730:	ee0608e3          	beqz	a2,400620 <main+0x604>
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  400734:	fd060713          	addi	a4,a2,-48
  400738:	ff8760e3          	bltu	a4,s8,400718 <main+0x6fc>
        else if (c >= 'a' && c <= 'f') d = 10u + (uint32_t)(c - 'a');
  40073c:	f9f60713          	addi	a4,a2,-97
  400740:	00f77663          	bgeu	a4,a5,40074c <main+0x730>
  400744:	fa900713          	li	a4,-87
  400748:	fd5ff06f          	j	40071c <main+0x700>
        else if (c >= 'A' && c <= 'F') d = 10u + (uint32_t)(c - 'A');
  40074c:	fbf60713          	addi	a4,a2,-65
  400750:	ece868e3          	bltu	a6,a4,400620 <main+0x604>
  400754:	fc900713          	li	a4,-55
  400758:	fc5ff06f          	j	40071c <main+0x700>
  40075c:	00402537          	lui	a0,0x402
  400760:	fd550513          	addi	a0,a0,-43 # 401fd5 <__modsi3+0x169>
            if (argc < 2) {
  400764:	040a0863          	beqz	s4,4007b4 <main+0x798>
            unsigned sd_sector = parse_u32(argv[1]);
  400768:	01012503          	lw	a0,16(sp)
  40076c:	00001097          	auipc	ra,0x1
  400770:	a0c080e7          	jalr	-1524(ra) # 401178 <parse_u32>
  400774:	00050593          	mv	a1,a0
            if (sd_sector < 5000) {
  400778:	00355613          	srli	a2,a0,0x3
  40077c:	00402537          	lui	a0,0x402
  400780:	fef50513          	addi	a0,a0,-17 # 401fef <__modsi3+0x183>
  400784:	27100693          	li	a3,625
  400788:	02d66663          	bltu	a2,a3,4007b4 <main+0x798>
            call_sd_write_test_api(sd_sector);
  40078c:	00058513          	mv	a0,a1
  400790:	00001097          	auipc	ra,0x1
  400794:	8cc080e7          	jalr	-1844(ra) # 40105c <call_sd_write_test_api>
        } else if (strcmp(argv[0], "exit") == 0 ||
  400798:	92dff06f          	j	4000c4 <main+0xa8>
            if (fat32_mount() != 0) {
  40079c:	00001097          	auipc	ra,0x1
  4007a0:	c00080e7          	jalr	-1024(ra) # 40139c <fat32_mount>
  4007a4:	00050593          	mv	a1,a0
  4007a8:	00402537          	lui	a0,0x402
  4007ac:	01950513          	addi	a0,a0,25 # 402019 <__modsi3+0x1ad>
  4007b0:	02058c63          	beqz	a1,4007e8 <main+0x7cc>
  4007b4:	00000097          	auipc	ra,0x0
  4007b8:	4f8080e7          	jalr	1272(ra) # 400cac <printf>
        } else if (strcmp(argv[0], "exit") == 0 ||
  4007bc:	909ff06f          	j	4000c4 <main+0xa8>
            fat32_ls();
  4007c0:	00001097          	auipc	ra,0x1
  4007c4:	f58080e7          	jalr	-168(ra) # 401718 <fat32_ls>
        } else if (strcmp(argv[0], "help") == 0) {
  4007c8:	8fdff06f          	j	4000c4 <main+0xa8>
  4007cc:	00402537          	lui	a0,0x402
  4007d0:	08350513          	addi	a0,a0,131 # 402083 <__modsi3+0x217>
            if (argc < 2) {
  4007d4:	fe0a00e3          	beqz	s4,4007b4 <main+0x798>
            fat32_cat(argv[1]);
  4007d8:	01012503          	lw	a0,16(sp)
  4007dc:	00001097          	auipc	ra,0x1
  4007e0:	ad4080e7          	jalr	-1324(ra) # 4012b0 <fat32_cat>
        } else if (strcmp(argv[0], "fat32_touch") == 0) {
  4007e4:	8e1ff06f          	j	4000c4 <main+0xa8>
  4007e8:	00402537          	lui	a0,0x402
            printf("part_lba=%x\n",      g_fat32.part_lba);
  4007ec:	22c52583          	lw	a1,556(a0) # 40222c <g_fat32>
  4007f0:	22c50a13          	addi	s4,a0,556
  4007f4:	00402537          	lui	a0,0x402
  4007f8:	02d50513          	addi	a0,a0,45 # 40202d <__modsi3+0x1c1>
  4007fc:	00000097          	auipc	ra,0x0
  400800:	4b0080e7          	jalr	1200(ra) # 400cac <printf>
            printf("root_cluster=%x\n",  g_fat32.root_cluster);
  400804:	00ca2583          	lw	a1,12(s4)
  400808:	00402537          	lui	a0,0x402
  40080c:	03a50513          	addi	a0,a0,58 # 40203a <__modsi3+0x1ce>
  400810:	00000097          	auipc	ra,0x0
  400814:	49c080e7          	jalr	1180(ra) # 400cac <printf>
            printf("spc=%x\n",           g_fat32.sectors_per_cluster);
  400818:	010a2583          	lw	a1,16(s4)
  40081c:	00402537          	lui	a0,0x402
  400820:	04b50513          	addi	a0,a0,75 # 40204b <__modsi3+0x1df>
  400824:	00000097          	auipc	ra,0x0
  400828:	488080e7          	jalr	1160(ra) # 400cac <printf>
            printf("fat_begin=%x\n",     g_fat32.fat_begin);
  40082c:	004a2583          	lw	a1,4(s4)
  400830:	00402537          	lui	a0,0x402
  400834:	05350513          	addi	a0,a0,83 # 402053 <__modsi3+0x1e7>
  400838:	00000097          	auipc	ra,0x0
  40083c:	474080e7          	jalr	1140(ra) # 400cac <printf>
            printf("data_begin=%x\n",    g_fat32.data_begin);
  400840:	008a2583          	lw	a1,8(s4)
  400844:	00402537          	lui	a0,0x402
  400848:	06150513          	addi	a0,a0,97 # 402061 <__modsi3+0x1f5>
  40084c:	00000097          	auipc	ra,0x0
  400850:	460080e7          	jalr	1120(ra) # 400cac <printf>
  400854:	871ff06f          	j	4000c4 <main+0xa8>
  400858:	00402537          	lui	a0,0x402
  40085c:	0a850513          	addi	a0,a0,168 # 4020a8 <__modsi3+0x23c>
            if (argc < 2) {
  400860:	f40a0ae3          	beqz	s4,4007b4 <main+0x798>
            if (fat32_touch(argv[1]) != 0) {
  400864:	01012503          	lw	a0,16(sp)
  400868:	00001097          	auipc	ra,0x1
  40086c:	138080e7          	jalr	312(ra) # 4019a0 <fat32_touch>
  400870:	84050ae3          	beqz	a0,4000c4 <main+0xa8>
                printf("fat32_touch failed\n");
  400874:	00402537          	lui	a0,0x402
  400878:	0c350513          	addi	a0,a0,195 # 4020c3 <__modsi3+0x257>
  40087c:	00000097          	auipc	ra,0x0
  400880:	430080e7          	jalr	1072(ra) # 400cac <printf>
        } else if (strcmp(argv[0], "exit") == 0 ||
  400884:	841ff06f          	j	4000c4 <main+0xa8>
            cmd_speech();
  400888:	00000097          	auipc	ra,0x0
  40088c:	7ec080e7          	jalr	2028(ra) # 401074 <cmd_speech>
        } else if (strcmp(argv[0], "help") == 0) {
  400890:	835ff06f          	j	4000c4 <main+0xa8>
            printf("commands:\n");
  400894:	00402537          	lui	a0,0x402
  400898:	0e350513          	addi	a0,a0,227 # 4020e3 <__modsi3+0x277>
  40089c:	00000097          	auipc	ra,0x0
  4008a0:	410080e7          	jalr	1040(ra) # 400cac <printf>
        } else if (strcmp(argv[0], "exit") == 0 ||
  4008a4:	821ff06f          	j	4000c4 <main+0xa8>
            exit();
  4008a8:	00000097          	auipc	ra,0x0
  4008ac:	188080e7          	jalr	392(ra) # 400a30 <exit>

004008b0 <parse_hex>:
    while (*s == ' ' || *s == '\t') s++;
  4008b0:	00250693          	addi	a3,a0,2
  4008b4:	00900613          	li	a2,9
  4008b8:	02000713          	li	a4,32
  4008bc:	0080006f          	j	4008c4 <parse_hex+0x14>
  4008c0:	00168693          	addi	a3,a3,1
  4008c4:	ffe6c503          	lbu	a0,-2(a3)
  4008c8:	fec50ce3          	beq	a0,a2,4008c0 <parse_hex+0x10>
  4008cc:	fee50ae3          	beq	a0,a4,4008c0 <parse_hex+0x10>
  4008d0:	03000613          	li	a2,48
  4008d4:	02c51063          	bne	a0,a2,4008f4 <parse_hex+0x44>
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s += 2;
  4008d8:	fff6c503          	lbu	a0,-1(a3)
  4008dc:	02056513          	ori	a0,a0,32
  4008e0:	07800613          	li	a2,120
  4008e4:	02c51063          	bne	a0,a2,400904 <parse_hex+0x54>
    if (!*s) return -1;
  4008e8:	0006c503          	lbu	a0,0(a3)
  4008ec:	02051063          	bnez	a0,40090c <parse_hex+0x5c>
  4008f0:	00c0006f          	j	4008fc <parse_hex+0x4c>
  4008f4:	ffe68693          	addi	a3,a3,-2
  4008f8:	00051a63          	bnez	a0,40090c <parse_hex+0x5c>
  4008fc:	fff00513          	li	a0,-1
    }
    *out = v;
    return 0;
  400900:	00008067          	ret
  400904:	ffe68693          	addi	a3,a3,-2
  400908:	03000513          	li	a0,48
  40090c:	00000613          	li	a2,0
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  400910:	00168693          	addi	a3,a3,1
  400914:	00a00713          	li	a4,10
  400918:	00600793          	li	a5,6
  40091c:	00500813          	li	a6,5
  400920:	0200006f          	j	400940 <parse_hex+0x90>
  400924:	fd000893          	li	a7,-48
  400928:	00a888b3          	add	a7,a7,a0
    while (*s) {
  40092c:	0006c503          	lbu	a0,0(a3)
        v = (v << 4) | d;
  400930:	00461613          	slli	a2,a2,0x4
  400934:	00c8e633          	or	a2,a7,a2
    while (*s) {
  400938:	00168693          	addi	a3,a3,1
  40093c:	02050663          	beqz	a0,400968 <parse_hex+0xb8>
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  400940:	fd050893          	addi	a7,a0,-48
  400944:	fee8e0e3          	bltu	a7,a4,400924 <parse_hex+0x74>
        else if (c >= 'a' && c <= 'f') d = 10u + (uint32_t)(c - 'a');
  400948:	f9f50893          	addi	a7,a0,-97
  40094c:	00f8f663          	bgeu	a7,a5,400958 <parse_hex+0xa8>
  400950:	fa900893          	li	a7,-87
  400954:	fd5ff06f          	j	400928 <parse_hex+0x78>
        else if (c >= 'A' && c <= 'F') d = 10u + (uint32_t)(c - 'A');
  400958:	fbf50893          	addi	a7,a0,-65
  40095c:	01186663          	bltu	a6,a7,400968 <parse_hex+0xb8>
  400960:	fc900893          	li	a7,-55
  400964:	fc5ff06f          	j	400928 <parse_hex+0x78>
  400968:	00000513          	li	a0,0
    *out = v;
  40096c:	00c5a023          	sw	a2,0(a1)
  400970:	00008067          	ret

00400974 <cmd_primes>:
{
  400974:	fe010113          	addi	sp,sp,-32
  400978:	00112e23          	sw	ra,28(sp)
  40097c:	00812c23          	sw	s0,24(sp)
  400980:	00912a23          	sw	s1,20(sp)
  400984:	01212823          	sw	s2,16(sp)
  400988:	01312623          	sw	s3,12(sp)
  40098c:	00200913          	li	s2,2
  400990:	00050413          	mv	s0,a0
  400994:	00000493          	li	s1,0
    for (unsigned n = 2; n <= max; n++) {
  400998:	07256463          	bltu	a0,s2,400a00 <cmd_primes+0x8c>
  40099c:	004029b7          	lui	s3,0x402
  4009a0:	10f98993          	addi	s3,s3,271 # 40210f <__modsi3+0x2a3>
  4009a4:	00c0006f          	j	4009b0 <cmd_primes+0x3c>
  4009a8:	00190913          	addi	s2,s2,1
  4009ac:	05246063          	bltu	s0,s2,4009ec <cmd_primes+0x78>
        if (is_prime(n)) {
  4009b0:	00090513          	mv	a0,s2
  4009b4:	00001097          	auipc	ra,0x1
  4009b8:	880080e7          	jalr	-1920(ra) # 401234 <is_prime>
  4009bc:	fe0506e3          	beqz	a0,4009a8 <cmd_primes+0x34>
            printf("%d ", (int)n);
  4009c0:	00098513          	mv	a0,s3
  4009c4:	00090593          	mv	a1,s2
  4009c8:	00000097          	auipc	ra,0x0
  4009cc:	2e4080e7          	jalr	740(ra) # 400cac <printf>
            count++;
  4009d0:	00148493          	addi	s1,s1,1
            if ((count % 8) == 0)
  4009d4:	0074f513          	andi	a0,s1,7
  4009d8:	fc0518e3          	bnez	a0,4009a8 <cmd_primes+0x34>
                putchar('\n');
  4009dc:	00a00513          	li	a0,10
  4009e0:	00000097          	auipc	ra,0x0
  4009e4:	584080e7          	jalr	1412(ra) # 400f64 <putchar>
  4009e8:	fc1ff06f          	j	4009a8 <cmd_primes+0x34>
    if ((count % 8) != 0)
  4009ec:	0074f513          	andi	a0,s1,7
  4009f0:	00050863          	beqz	a0,400a00 <cmd_primes+0x8c>
        putchar('\n');
  4009f4:	00a00513          	li	a0,10
  4009f8:	00000097          	auipc	ra,0x0
  4009fc:	56c080e7          	jalr	1388(ra) # 400f64 <putchar>
    printf("total primes: %d (0..%d)\n", count, (int)max);
  400a00:	00402537          	lui	a0,0x402
  400a04:	11350513          	addi	a0,a0,275 # 402113 <__modsi3+0x2a7>
  400a08:	00048593          	mv	a1,s1
  400a0c:	00040613          	mv	a2,s0
  400a10:	01c12083          	lw	ra,28(sp)
  400a14:	01812403          	lw	s0,24(sp)
  400a18:	01412483          	lw	s1,20(sp)
  400a1c:	01012903          	lw	s2,16(sp)
  400a20:	00c12983          	lw	s3,12(sp)
  400a24:	02010113          	addi	sp,sp,32
  400a28:	00000317          	auipc	t1,0x0
  400a2c:	28430067          	jr	644(t1) # 400cac <printf>

00400a30 <exit>:
    __asm__ __volatile__ (
  400a30:	05a00693          	li	a3,90
  400a34:	00000593          	li	a1,0
  400a38:	00000613          	li	a2,0
  400a3c:	00000513          	li	a0,0
  400a40:	00000073          	ecall
    for (;;);
  400a44:	0000006f          	j	400a44 <exit+0x14>

00400a48 <call_sa_api>:
{
  400a48:	00050713          	mv	a4,a0
    if (matrix_size == 0 ||
  400a4c:	fff50513          	addi	a0,a0,-1
  400a50:	00f00593          	li	a1,15
  400a54:	24a5e463          	bltu	a1,a0,400c9c <call_sa_api+0x254>
  400a58:	00377513          	andi	a0,a4,3
  400a5c:	24051063          	bnez	a0,400c9c <call_sa_api+0x254>
  400a60:	9f010113          	addi	sp,sp,-1552
  400a64:	00000593          	li	a1,0
    for (uint32_t i = 0; i < matrix_size; ++i) {
  400a68:	00271793          	slli	a5,a4,0x2
  400a6c:	51010613          	addi	a2,sp,1296
  400a70:	41010693          	addi	a3,sp,1040
  400a74:	01010813          	addi	a6,sp,16
  400a78:	51010893          	addi	a7,sp,1296
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400a7c:	02b702b3          	mul	t0,a4,a1
  400a80:	005702b3          	add	t0,a4,t0
  400a84:	005602b3          	add	t0,a2,t0
  400a88:	00058313          	mv	t1,a1
  400a8c:	00080393          	mv	t2,a6
  400a90:	00068e13          	mv	t3,a3
  400a94:	00088e93          	mv	t4,a7
  400a98:	00050f13          	mv	t5,a0
            matrix_B[index] = (uint8_t)(3u * i + j + 5u);
  400a9c:	005f0f93          	addi	t6,t5,5
  400aa0:	01fe0023          	sb	t6,0(t3)
            matrix_A[index] = (uint8_t)(2u * i + 2u * j + 2u);
  400aa4:	00131f93          	slli	t6,t1,0x1
            matrix_C[index] = 0u;
  400aa8:	0003a023          	sw	zero,0(t2)
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400aac:	001f0f13          	addi	t5,t5,1
            matrix_A[index] = (uint8_t)(2u * i + 2u * j + 2u);
  400ab0:	002f8f93          	addi	t6,t6,2
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400ab4:	001e0e13          	addi	t3,t3,1
            matrix_A[index] = (uint8_t)(2u * i + 2u * j + 2u);
  400ab8:	01fe8023          	sb	t6,0(t4)
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400abc:	001e8e93          	addi	t4,t4,1
  400ac0:	00438393          	addi	t2,t2,4
  400ac4:	00130313          	addi	t1,t1,1
  400ac8:	fc5e9ae3          	bne	t4,t0,400a9c <call_sa_api+0x54>
    for (uint32_t i = 0; i < matrix_size; ++i) {
  400acc:	00158593          	addi	a1,a1,1
  400ad0:	00350513          	addi	a0,a0,3
  400ad4:	00e888b3          	add	a7,a7,a4
  400ad8:	00e686b3          	add	a3,a3,a4
  400adc:	00f80833          	add	a6,a6,a5
  400ae0:	f8e59ee3          	bne	a1,a4,400a7c <call_sa_api+0x34>
  400ae4:	00000813          	li	a6,0
  400ae8:	00a00893          	li	a7,10
    __asm__ volatile(
  400aec:	41010593          	addi	a1,sp,1040
  400af0:	01010613          	addi	a2,sp,16
  400af4:	00a00693          	li	a3,10
  400af8:	51010513          	addi	a0,sp,1296
  400afc:	00000073          	ecall
  400b00:	04100593          	li	a1,65
    __asm__ __volatile__ (
  400b04:	00058513          	mv	a0,a1
  400b08:	00100693          	li	a3,1
  400b0c:	00000073          	ecall
  400b10:	00088513          	mv	a0,a7
  400b14:	00100693          	li	a3,1
  400b18:	00000073          	ecall
  400b1c:	51010593          	addi	a1,sp,1296
  400b20:	02000613          	li	a2,32
  400b24:	51010293          	addi	t0,sp,1296
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400b28:	03070533          	mul	a0,a4,a6
  400b2c:	00a70533          	add	a0,a4,a0
  400b30:	00a58333          	add	t1,a1,a0
  400b34:	00028393          	mv	t2,t0
            print_int((int)matrix_A[i * matrix_size + j]);
  400b38:	0003ce03          	lbu	t3,0(t2)
    __asm__ __volatile__ (
  400b3c:	000e0513          	mv	a0,t3
  400b40:	05b00693          	li	a3,91
  400b44:	00000073          	ecall
    __asm__ __volatile__ (
  400b48:	00060513          	mv	a0,a2
  400b4c:	00100693          	li	a3,1
  400b50:	00000073          	ecall
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400b54:	00138393          	addi	t2,t2,1
  400b58:	fe6390e3          	bne	t2,t1,400b38 <call_sa_api+0xf0>
    __asm__ __volatile__ (
  400b5c:	00088513          	mv	a0,a7
  400b60:	00100693          	li	a3,1
  400b64:	00000073          	ecall
    for (uint32_t i = 0; i < matrix_size; ++i) {
  400b68:	00180813          	addi	a6,a6,1
  400b6c:	00e282b3          	add	t0,t0,a4
  400b70:	fae81ce3          	bne	a6,a4,400b28 <call_sa_api+0xe0>
  400b74:	00000593          	li	a1,0
  400b78:	00a00613          	li	a2,10
  400b7c:	04200813          	li	a6,66
    __asm__ __volatile__ (
  400b80:	00060513          	mv	a0,a2
  400b84:	00100693          	li	a3,1
  400b88:	00000073          	ecall
  400b8c:	00080513          	mv	a0,a6
  400b90:	00100693          	li	a3,1
  400b94:	00000073          	ecall
  400b98:	00060513          	mv	a0,a2
  400b9c:	00100693          	li	a3,1
  400ba0:	00000073          	ecall
  400ba4:	41010813          	addi	a6,sp,1040
  400ba8:	02000893          	li	a7,32
  400bac:	41010293          	addi	t0,sp,1040
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400bb0:	02b70533          	mul	a0,a4,a1
  400bb4:	00a70533          	add	a0,a4,a0
  400bb8:	00a80333          	add	t1,a6,a0
  400bbc:	00028393          	mv	t2,t0
            print_int((int)matrix_B[i * matrix_size + j]);
  400bc0:	0003ce03          	lbu	t3,0(t2)
    __asm__ __volatile__ (
  400bc4:	000e0513          	mv	a0,t3
  400bc8:	05b00693          	li	a3,91
  400bcc:	00000073          	ecall
    __asm__ __volatile__ (
  400bd0:	00088513          	mv	a0,a7
  400bd4:	00100693          	li	a3,1
  400bd8:	00000073          	ecall
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400bdc:	00138393          	addi	t2,t2,1
  400be0:	fe6390e3          	bne	t2,t1,400bc0 <call_sa_api+0x178>
    __asm__ __volatile__ (
  400be4:	00060513          	mv	a0,a2
  400be8:	00100693          	li	a3,1
  400bec:	00000073          	ecall
    for (uint32_t i = 0; i < matrix_size; ++i) {
  400bf0:	00158593          	addi	a1,a1,1
  400bf4:	00e282b3          	add	t0,t0,a4
  400bf8:	fae59ce3          	bne	a1,a4,400bb0 <call_sa_api+0x168>
  400bfc:	00000593          	li	a1,0
  400c00:	00a00613          	li	a2,10
  400c04:	04300813          	li	a6,67
    __asm__ __volatile__ (
  400c08:	00060513          	mv	a0,a2
  400c0c:	00100693          	li	a3,1
  400c10:	00000073          	ecall
  400c14:	00080513          	mv	a0,a6
  400c18:	00100693          	li	a3,1
  400c1c:	00000073          	ecall
  400c20:	00060513          	mv	a0,a2
  400c24:	00100693          	li	a3,1
  400c28:	00000073          	ecall
  400c2c:	01010813          	addi	a6,sp,16
  400c30:	02000893          	li	a7,32
  400c34:	01010293          	addi	t0,sp,16
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400c38:	02b78533          	mul	a0,a5,a1
  400c3c:	00a78533          	add	a0,a5,a0
  400c40:	00a80333          	add	t1,a6,a0
  400c44:	00028393          	mv	t2,t0
            print_int((int)matrix_C[i * matrix_size + j]);
  400c48:	0003ae03          	lw	t3,0(t2)
    __asm__ __volatile__ (
  400c4c:	000e0513          	mv	a0,t3
  400c50:	05b00693          	li	a3,91
  400c54:	00000073          	ecall
    __asm__ __volatile__ (
  400c58:	00088513          	mv	a0,a7
  400c5c:	00100693          	li	a3,1
  400c60:	00000073          	ecall
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400c64:	00438393          	addi	t2,t2,4
  400c68:	fe6390e3          	bne	t2,t1,400c48 <call_sa_api+0x200>
    __asm__ __volatile__ (
  400c6c:	00060513          	mv	a0,a2
  400c70:	00100693          	li	a3,1
  400c74:	00000073          	ecall
    for (uint32_t i = 0; i < matrix_size; ++i) {
  400c78:	00158593          	addi	a1,a1,1
  400c7c:	00f282b3          	add	t0,t0,a5
  400c80:	fae59ce3          	bne	a1,a4,400c38 <call_sa_api+0x1f0>
  400c84:	00a00593          	li	a1,10
    __asm__ __volatile__ (
  400c88:	00058513          	mv	a0,a1
  400c8c:	00100693          	li	a3,1
  400c90:	00000073          	ecall
}
  400c94:	61010113          	addi	sp,sp,1552
  400c98:	00008067          	ret
        printf("invalid matrix size\n");
  400c9c:	00402537          	lui	a0,0x402
  400ca0:	12d50513          	addi	a0,a0,301 # 40212d <__modsi3+0x2c1>
  400ca4:	00000317          	auipc	t1,0x0
  400ca8:	00830067          	jr	8(t1) # 400cac <printf>

00400cac <printf>:
void printf(const char *fmt, ...) {
  400cac:	fc010113          	addi	sp,sp,-64
  400cb0:	00812e23          	sw	s0,28(sp)
  400cb4:	00912c23          	sw	s1,24(sp)
  400cb8:	01212a23          	sw	s2,20(sp)
  400cbc:	01312823          	sw	s3,16(sp)
  400cc0:	00050293          	mv	t0,a0
  400cc4:	02f12a23          	sw	a5,52(sp)
  400cc8:	03012c23          	sw	a6,56(sp)
  400ccc:	03112e23          	sw	a7,60(sp)
  400cd0:	02b12223          	sw	a1,36(sp)
  400cd4:	02c12423          	sw	a2,40(sp)
  400cd8:	02d12623          	sw	a3,44(sp)
  400cdc:	02e12823          	sw	a4,48(sp)
  400ce0:	02410513          	addi	a0,sp,36
  400ce4:	02500593          	li	a1,37
  400ce8:	07200613          	li	a2,114
  400cec:	06400713          	li	a4,100
  400cf0:	02d00793          	li	a5,45
  400cf4:	ccccd6b7          	lui	a3,0xccccd
  400cf8:	00110813          	addi	a6,sp,1
  400cfc:	00900893          	li	a7,9
  400d00:	00100313          	li	t1,1
  400d04:	03000393          	li	t2,48
  400d08:	07300e13          	li	t3,115
  400d0c:	07800e93          	li	t4,120
    va_start(vargs, fmt);
  400d10:	00a12623          	sw	a0,12(sp)
  400d14:	ccd68f13          	addi	t5,a3,-819 # cccccccd <USER_MAX+0xcc7ccccd>
  400d18:	00402fb7          	lui	t6,0x402
  400d1c:	1eaf8f93          	addi	t6,t6,490 # 4021ea <__modsi3+0x37e>
  400d20:	00c0006f          	j	400d2c <printf+0x80>
            switch (*fmt) {
  400d24:	20050c63          	beqz	a0,400f3c <printf+0x290>
        fmt++;
  400d28:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400d2c:	0002c403          	lbu	s0,0(t0)
  400d30:	00b40e63          	beq	s0,a1,400d4c <printf+0xa0>
  400d34:	20040c63          	beqz	s0,400f4c <printf+0x2a0>
    __asm__ __volatile__ (
  400d38:	00040513          	mv	a0,s0
  400d3c:	00100693          	li	a3,1
  400d40:	00000073          	ecall
        fmt++;
  400d44:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400d48:	fe5ff06f          	j	400d2c <printf+0x80>
            switch (*fmt) {
  400d4c:	0012c503          	lbu	a0,1(t0)
            fmt++;
  400d50:	00128293          	addi	t0,t0,1
            switch (*fmt) {
  400d54:	02a64c63          	blt	a2,a0,400d8c <printf+0xe0>
  400d58:	12b50663          	beq	a0,a1,400e84 <printf+0x1d8>
  400d5c:	fce514e3          	bne	a0,a4,400d24 <printf+0x78>
                    int value = va_arg(vargs, int);
  400d60:	00c12503          	lw	a0,12(sp)
  400d64:	00450693          	addi	a3,a0,4
  400d68:	00d12623          	sw	a3,12(sp)
  400d6c:	00052483          	lw	s1,0(a0)
                    if (value < 0) {
  400d70:	1604c063          	bltz	s1,400ed0 <printf+0x224>
                    if (u == 0) {
  400d74:	16049663          	bnez	s1,400ee0 <printf+0x234>
    __asm__ __volatile__ (
  400d78:	00038513          	mv	a0,t2
  400d7c:	00100693          	li	a3,1
  400d80:	00000073          	ecall
        fmt++;
  400d84:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400d88:	fa5ff06f          	j	400d2c <printf+0x80>
            switch (*fmt) {
  400d8c:	11c50663          	beq	a0,t3,400e98 <printf+0x1ec>
  400d90:	f9d51ce3          	bne	a0,t4,400d28 <printf+0x7c>
                    unsigned value = va_arg(vargs, unsigned);
  400d94:	00c12503          	lw	a0,12(sp)
  400d98:	00450693          	addi	a3,a0,4
  400d9c:	00d12623          	sw	a3,12(sp)
  400da0:	00052403          	lw	s0,0(a0)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400da4:	01c45513          	srli	a0,s0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400da8:	00af8533          	add	a0,t6,a0
  400dac:	00054483          	lbu	s1,0(a0)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400db0:	00441513          	slli	a0,s0,0x4
  400db4:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400db8:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400dbc:	00048513          	mv	a0,s1
  400dc0:	00100693          	li	a3,1
  400dc4:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400dc8:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400dcc:	00841513          	slli	a0,s0,0x8
  400dd0:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400dd4:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400dd8:	00048513          	mv	a0,s1
  400ddc:	00100693          	li	a3,1
  400de0:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400de4:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400de8:	00c41513          	slli	a0,s0,0xc
  400dec:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400df0:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400df4:	00048513          	mv	a0,s1
  400df8:	00100693          	li	a3,1
  400dfc:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400e00:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400e04:	01041513          	slli	a0,s0,0x10
  400e08:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400e0c:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400e10:	00048513          	mv	a0,s1
  400e14:	00100693          	li	a3,1
  400e18:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400e1c:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400e20:	01441513          	slli	a0,s0,0x14
  400e24:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400e28:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400e2c:	00048513          	mv	a0,s1
  400e30:	00100693          	li	a3,1
  400e34:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400e38:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400e3c:	01841513          	slli	a0,s0,0x18
  400e40:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400e44:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400e48:	00048513          	mv	a0,s1
  400e4c:	00100693          	li	a3,1
  400e50:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400e54:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400e58:	00f47413          	andi	s0,s0,15
                        putchar("0123456789abcdef"[nibble]);
  400e5c:	008f8433          	add	s0,t6,s0
    __asm__ __volatile__ (
  400e60:	00048513          	mv	a0,s1
  400e64:	00100693          	li	a3,1
  400e68:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400e6c:	00044403          	lbu	s0,0(s0)
    __asm__ __volatile__ (
  400e70:	00040513          	mv	a0,s0
  400e74:	00100693          	li	a3,1
  400e78:	00000073          	ecall
        fmt++;
  400e7c:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400e80:	eadff06f          	j	400d2c <printf+0x80>
    __asm__ __volatile__ (
  400e84:	00058513          	mv	a0,a1
  400e88:	00100693          	li	a3,1
  400e8c:	00000073          	ecall
        fmt++;
  400e90:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400e94:	e99ff06f          	j	400d2c <printf+0x80>
                    const char *s = va_arg(vargs, const char *);
  400e98:	00c12503          	lw	a0,12(sp)
  400e9c:	00450693          	addi	a3,a0,4
  400ea0:	00d12623          	sw	a3,12(sp)
  400ea4:	00052483          	lw	s1,0(a0)
                    while (*s) {
  400ea8:	0004c403          	lbu	s0,0(s1)
  400eac:	e6040ee3          	beqz	s0,400d28 <printf+0x7c>
  400eb0:	00148493          	addi	s1,s1,1
    __asm__ __volatile__ (
  400eb4:	00040513          	mv	a0,s0
  400eb8:	00100693          	li	a3,1
  400ebc:	00000073          	ecall
                    while (*s) {
  400ec0:	0004c403          	lbu	s0,0(s1)
  400ec4:	00148493          	addi	s1,s1,1
  400ec8:	fe0416e3          	bnez	s0,400eb4 <printf+0x208>
  400ecc:	e5dff06f          	j	400d28 <printf+0x7c>
    __asm__ __volatile__ (
  400ed0:	00078513          	mv	a0,a5
  400ed4:	00100693          	li	a3,1
  400ed8:	00000073          	ecall
                        u = (unsigned int)(-(value + 1)) + 1;
  400edc:	409004b3          	neg	s1,s1
  400ee0:	00000513          	li	a0,0
  400ee4:	00048693          	mv	a3,s1
  400ee8:	00050413          	mv	s0,a0
                        u /= 10;
  400eec:	03e4b933          	mulhu	s2,s1,t5
                        buf[i++] = '0' + (u % 10);
  400ef0:	00150513          	addi	a0,a0,1
                        u /= 10;
  400ef4:	00395493          	srli	s1,s2,0x3
                        buf[i++] = '0' + (u % 10);
  400ef8:	0f897913          	andi	s2,s2,248
  400efc:	00149993          	slli	s3,s1,0x1
  400f00:	41268933          	sub	s2,a3,s2
  400f04:	41390933          	sub	s2,s2,s3
  400f08:	03096913          	ori	s2,s2,48
  400f0c:	008809b3          	add	s3,a6,s0
  400f10:	01298023          	sb	s2,0(s3)
                    while (u > 0) {
  400f14:	fcd8e8e3          	bltu	a7,a3,400ee4 <printf+0x238>
                        putchar(buf[--i]);
  400f18:	00880533          	add	a0,a6,s0
  400f1c:	00054483          	lbu	s1,0(a0)
    __asm__ __volatile__ (
  400f20:	00048513          	mv	a0,s1
  400f24:	00100693          	li	a3,1
  400f28:	00000073          	ecall
                    while (i > 0) {
  400f2c:	00140513          	addi	a0,s0,1
  400f30:	fff40413          	addi	s0,s0,-1
  400f34:	fea342e3          	blt	t1,a0,400f18 <printf+0x26c>
  400f38:	df1ff06f          	j	400d28 <printf+0x7c>
  400f3c:	02500593          	li	a1,37
    __asm__ __volatile__ (
  400f40:	00058513          	mv	a0,a1
  400f44:	00100693          	li	a3,1
  400f48:	00000073          	ecall
}
  400f4c:	01c12403          	lw	s0,28(sp)
  400f50:	01812483          	lw	s1,24(sp)
  400f54:	01412903          	lw	s2,20(sp)
  400f58:	01012983          	lw	s3,16(sp)
  400f5c:	04010113          	addi	sp,sp,64
  400f60:	00008067          	ret

00400f64 <putchar>:
{
  400f64:	00050593          	mv	a1,a0
    __asm__ __volatile__ (
  400f68:	00058513          	mv	a0,a1
  400f6c:	00100693          	li	a3,1
  400f70:	00000073          	ecall
}
  400f74:	00008067          	ret

00400f78 <print_int>:
{
  400f78:	00050593          	mv	a1,a0
    __asm__ __volatile__ (
  400f7c:	00058513          	mv	a0,a1
  400f80:	05b00693          	li	a3,91
  400f84:	00000073          	ecall
}
  400f88:	00008067          	ret

00400f8c <call_mic_api>:
    __asm__ __volatile__(
  400f8c:	01400693          	li	a3,20
  400f90:	00000073          	ecall
}
  400f94:	00008067          	ret

00400f98 <call_mic_write_file>:
{
  400f98:	fe010113          	addi	sp,sp,-32
  400f9c:	00112e23          	sw	ra,28(sp)
  400fa0:	00812c23          	sw	s0,24(sp)
  400fa4:	00912a23          	sw	s1,20(sp)
  400fa8:	00050413          	mv	s0,a0
    if (fat32_find(
  400fac:	00402537          	lui	a0,0x402
  400fb0:	14250513          	addi	a0,a0,322 # 402142 <__modsi3+0x2d6>
  400fb4:	01010593          	addi	a1,sp,16
  400fb8:	00c10613          	addi	a2,sp,12
  400fbc:	00000097          	auipc	ra,0x0
  400fc0:	49c080e7          	jalr	1180(ra) # 401458 <fat32_find>
            &size) != 0) {
  400fc4:	00050863          	beqz	a0,400fd4 <call_mic_write_file+0x3c>
        printf("MIC.TXT not found\n");
  400fc8:	00402537          	lui	a0,0x402
  400fcc:	14a50513          	addi	a0,a0,330 # 40214a <__modsi3+0x2de>
  400fd0:	0180006f          	j	400fe8 <call_mic_write_file+0x50>
    if (cluster < 2) {
  400fd4:	01012503          	lw	a0,16(sp)
  400fd8:	00100593          	li	a1,1
  400fdc:	02a5e663          	bltu	a1,a0,401008 <call_mic_write_file+0x70>
        printf("MIC.TXT has no cluster\n");
  400fe0:	00402537          	lui	a0,0x402
  400fe4:	15d50513          	addi	a0,a0,349 # 40215d <__modsi3+0x2f1>
  400fe8:	00000097          	auipc	ra,0x0
  400fec:	cc4080e7          	jalr	-828(ra) # 400cac <printf>
  400ff0:	00000513          	li	a0,0
}
  400ff4:	01c12083          	lw	ra,28(sp)
  400ff8:	01812403          	lw	s0,24(sp)
  400ffc:	01412483          	lw	s1,20(sp)
  401000:	02010113          	addi	sp,sp,32
  401004:	00008067          	ret
        cluster_to_lba(cluster);
  401008:	00000097          	auipc	ra,0x0
  40100c:	6f0080e7          	jalr	1776(ra) # 4016f8 <cluster_to_lba>
        cluster,
  401010:	01012583          	lw	a1,16(sp)
        size
  401014:	00c12683          	lw	a3,12(sp)
        cluster_to_lba(cluster);
  401018:	00050493          	mv	s1,a0
    printf(
  40101c:	00402537          	lui	a0,0x402
  401020:	17550513          	addi	a0,a0,373 # 402175 <__modsi3+0x309>
  401024:	00048613          	mv	a2,s1
  401028:	00000097          	auipc	ra,0x0
  40102c:	c84080e7          	jalr	-892(ra) # 400cac <printf>
    __asm__ __volatile__(
  401030:	01500693          	li	a3,21
  401034:	00048593          	mv	a1,s1
  401038:	00040513          	mv	a0,s0
  40103c:	00000073          	ecall
  401040:	fb5ff06f          	j	400ff4 <call_mic_write_file+0x5c>

00401044 <call_mic_write_api>:
    __asm__ __volatile__(
  401044:	01500693          	li	a3,21
  401048:	00000073          	ecall
}
  40104c:	00008067          	ret

00401050 <call_sd_read_api>:
    __asm__ __volatile__(
  401050:	01e00693          	li	a3,30
  401054:	00000073          	ecall
}
  401058:	00008067          	ret

0040105c <call_sd_write_test_api>:
    __asm__ __volatile__(
  40105c:	01f00693          	li	a3,31
  401060:	00000073          	ecall
}
  401064:	00008067          	ret

00401068 <call_sd_write_buf_api>:
    __asm__ __volatile__(
  401068:	02000693          	li	a3,32
  40106c:	00000073          	ecall
    return sd_api2(
  401070:	00008067          	ret

00401074 <cmd_speech>:
{
  401074:	ff010113          	addi	sp,sp,-16
  401078:	00112623          	sw	ra,12(sp)
    printf("Speech recognition start\n");
  40107c:	00402537          	lui	a0,0x402
  401080:	19350513          	addi	a0,a0,403 # 402193 <__modsi3+0x327>
  401084:	00000097          	auipc	ra,0x0
  401088:	c28080e7          	jalr	-984(ra) # 400cac <printf>
    __asm__ __volatile__(
  40108c:	03c00693          	li	a3,60
  401090:	00200613          	li	a2,2
  401094:	00000513          	li	a0,0
  401098:	00000073          	ecall
    switch (result) {
  40109c:	02c50663          	beq	a0,a2,4010c8 <cmd_speech+0x54>
  4010a0:	00050593          	mv	a1,a0
  4010a4:	00100513          	li	a0,1
  4010a8:	00a58a63          	beq	a1,a0,4010bc <cmd_speech+0x48>
  4010ac:	02059a63          	bnez	a1,4010e0 <cmd_speech+0x6c>
        printf("RESULT: UP\n");
  4010b0:	00402537          	lui	a0,0x402
  4010b4:	1ad50513          	addi	a0,a0,429 # 4021ad <__modsi3+0x341>
  4010b8:	0180006f          	j	4010d0 <cmd_speech+0x5c>
        printf("RESULT: DOWN\n");
  4010bc:	00402537          	lui	a0,0x402
  4010c0:	1b950513          	addi	a0,a0,441 # 4021b9 <__modsi3+0x34d>
  4010c4:	00c0006f          	j	4010d0 <cmd_speech+0x5c>
        printf("RESULT: UNKNOWN\n");
  4010c8:	00402537          	lui	a0,0x402
  4010cc:	1c750513          	addi	a0,a0,455 # 4021c7 <__modsi3+0x35b>
  4010d0:	00c12083          	lw	ra,12(sp)
  4010d4:	01010113          	addi	sp,sp,16
  4010d8:	00000317          	auipc	t1,0x0
  4010dc:	bd430067          	jr	-1068(t1) # 400cac <printf>
        printf("RESULT: ERROR %d\n", result);
  4010e0:	00402537          	lui	a0,0x402
  4010e4:	1d850513          	addi	a0,a0,472 # 4021d8 <__modsi3+0x36c>
  4010e8:	00c12083          	lw	ra,12(sp)
  4010ec:	01010113          	addi	sp,sp,16
  4010f0:	00000317          	auipc	t1,0x0
  4010f4:	bbc30067          	jr	-1092(t1) # 400cac <printf>

004010f8 <call_speech_recognition_api>:
    __asm__ __volatile__(
  4010f8:	03c00693          	li	a3,60
  4010fc:	00000513          	li	a0,0
  401100:	00000073          	ecall
    return (int32_t)a0;
  401104:	00008067          	ret

00401108 <call_dump_api>:
    __asm__ __volatile__(
  401108:	02800693          	li	a3,40
  40110c:	00000073          	ecall
}
  401110:	00008067          	ret

00401114 <strcpy>:
    while (*src)
  401114:	0005c603          	lbu	a2,0(a1)
  401118:	00050693          	mv	a3,a0
  40111c:	02060263          	beqz	a2,401140 <strcpy+0x2c>
  401120:	00158593          	addi	a1,a1,1
  401124:	00050713          	mv	a4,a0
        *d++ = *src++;
  401128:	00c70023          	sb	a2,0(a4)
    while (*src)
  40112c:	0005c603          	lbu	a2,0(a1)
        *d++ = *src++;
  401130:	00170693          	addi	a3,a4,1
    while (*src)
  401134:	00158593          	addi	a1,a1,1
  401138:	00068713          	mv	a4,a3
  40113c:	fe0616e3          	bnez	a2,401128 <strcpy+0x14>
    *d = '\0';
  401140:	00068023          	sb	zero,0(a3)
    return dst;
  401144:	00008067          	ret

00401148 <strcmp>:
    while (*s1 && *s2) {
  401148:	00054603          	lbu	a2,0(a0)
  40114c:	02060063          	beqz	a2,40116c <strcmp+0x24>
  401150:	00150513          	addi	a0,a0,1
  401154:	0005c683          	lbu	a3,0(a1)
  401158:	00d61a63          	bne	a2,a3,40116c <strcmp+0x24>
  40115c:	00054603          	lbu	a2,0(a0)
        s2++;
  401160:	00158593          	addi	a1,a1,1
    while (*s1 && *s2) {
  401164:	00150513          	addi	a0,a0,1
  401168:	fe0616e3          	bnez	a2,401154 <strcmp+0xc>
    return *(unsigned char *)s1 - *(unsigned char *)s2;
  40116c:	0005c503          	lbu	a0,0(a1)
  401170:	40a60533          	sub	a0,a2,a0
  401174:	00008067          	ret

00401178 <parse_u32>:
unsigned parse_u32(const char *s) {
  401178:	00050593          	mv	a1,a0
    if ((s[0] == '0') && (s[1] == 'x' || s[1] == 'X')) {
  40117c:	00054503          	lbu	a0,0(a0)
  401180:	03000693          	li	a3,48
  401184:	02d51663          	bne	a0,a3,4011b0 <parse_u32+0x38>
  401188:	0015c503          	lbu	a0,1(a1)
  40118c:	02056513          	ori	a0,a0,32
  401190:	07800613          	li	a2,120
  401194:	02c51663          	bne	a0,a2,4011c0 <parse_u32+0x48>
    while (*s) {
  401198:	0025c503          	lbu	a0,2(a1)
        s += 2;
  40119c:	00258593          	addi	a1,a1,2
  4011a0:	01000613          	li	a2,16
  4011a4:	00050693          	mv	a3,a0
    while (*s) {
  4011a8:	00051e63          	bnez	a0,4011c4 <parse_u32+0x4c>
  4011ac:	0840006f          	j	401230 <parse_u32+0xb8>
  4011b0:	00a00613          	li	a2,10
  4011b4:	00050693          	mv	a3,a0
  4011b8:	00051663          	bnez	a0,4011c4 <parse_u32+0x4c>
  4011bc:	0740006f          	j	401230 <parse_u32+0xb8>
  4011c0:	00a00613          	li	a2,10
  4011c4:	00000513          	li	a0,0
        if (c >= '0' && c <= '9')       d = (unsigned)(c - '0');
  4011c8:	00158593          	addi	a1,a1,1
  4011cc:	00a00713          	li	a4,10
  4011d0:	00600793          	li	a5,6
  4011d4:	00500813          	li	a6,5
  4011d8:	fd068893          	addi	a7,a3,-48
  4011dc:	00e8fa63          	bgeu	a7,a4,4011f0 <parse_u32+0x78>
  4011e0:	fd000893          	li	a7,-48
  4011e4:	00d888b3          	add	a7,a7,a3
        if (d >= base) break;
  4011e8:	02c8ea63          	bltu	a7,a2,40121c <parse_u32+0xa4>
  4011ec:	0440006f          	j	401230 <parse_u32+0xb8>
        else if (c >= 'a' && c <= 'f')  d = 10u + (unsigned)(c - 'a');
  4011f0:	f9f68893          	addi	a7,a3,-97
  4011f4:	00f8fa63          	bgeu	a7,a5,401208 <parse_u32+0x90>
  4011f8:	fa900893          	li	a7,-87
  4011fc:	00d888b3          	add	a7,a7,a3
        if (d >= base) break;
  401200:	00c8ee63          	bltu	a7,a2,40121c <parse_u32+0xa4>
  401204:	02c0006f          	j	401230 <parse_u32+0xb8>
        else if (c >= 'A' && c <= 'F')  d = 10u + (unsigned)(c - 'A');
  401208:	fbf68893          	addi	a7,a3,-65
  40120c:	03186263          	bltu	a6,a7,401230 <parse_u32+0xb8>
  401210:	fc900893          	li	a7,-55
  401214:	00d888b3          	add	a7,a7,a3
        if (d >= base) break;
  401218:	00c8fc63          	bgeu	a7,a2,401230 <parse_u32+0xb8>
    while (*s) {
  40121c:	0005c683          	lbu	a3,0(a1)
        v = v * base + d;
  401220:	02c50533          	mul	a0,a0,a2
  401224:	00a88533          	add	a0,a7,a0
    while (*s) {
  401228:	00158593          	addi	a1,a1,1
  40122c:	fa0696e3          	bnez	a3,4011d8 <parse_u32+0x60>
    return v;
  401230:	00008067          	ret

00401234 <is_prime>:
{
  401234:	00200613          	li	a2,2
    if (n < 2) return false;
  401238:	00c57663          	bgeu	a0,a2,401244 <is_prime+0x10>
  40123c:	00000513          	li	a0,0
}
  401240:	00008067          	ret
  401244:	00050593          	mv	a1,a0
  401248:	00400613          	li	a2,4
  40124c:	00100513          	li	a0,1
    for (unsigned i = 2; i * i <= n; i++) {
  401250:	00c5ee63          	bltu	a1,a2,40126c <is_prime+0x38>
  401254:	00200613          	li	a2,2
        if (n % i == 0)
  401258:	02c5f6b3          	remu	a3,a1,a2
  40125c:	fe0680e3          	beqz	a3,40123c <is_prime+0x8>
    for (unsigned i = 2; i * i <= n; i++) {
  401260:	00160613          	addi	a2,a2,1
  401264:	02c606b3          	mul	a3,a2,a2
  401268:	fed5f8e3          	bgeu	a1,a3,401258 <is_prime+0x24>
}
  40126c:	00008067          	ret

00401270 <getchar>:
    __asm__ __volatile__ (
  401270:	00200693          	li	a3,2
  401274:	00000073          	ecall
  401278:	00050593          	mv	a1,a0
    return ch;
  40127c:	00058513          	mv	a0,a1
  401280:	00008067          	ret

00401284 <getchar_timeout>:
    __asm__ __volatile__ (
  401284:	00300693          	li	a3,3
  401288:	00000073          	ecall
  40128c:	00050593          	mv	a1,a0
    return ch;
  401290:	00058513          	mv	a0,a1
  401294:	00008067          	ret

00401298 <call_sd_read_buf_api>:
    __asm__ __volatile__(
  401298:	02100693          	li	a3,33
  40129c:	00000073          	ecall
    return (int)a0;
  4012a0:	00008067          	ret

004012a4 <poll_switch_api>:
    __asm__ __volatile__(
  4012a4:	03200693          	li	a3,50
  4012a8:	00000073          	ecall
    return a0;
  4012ac:	00008067          	ret

004012b0 <fat32_cat>:
static uint8_t fat32_buf[512];

fat32_info_t g_fat32;

int fat32_cat(const char *name)
{
  4012b0:	de010113          	addi	sp,sp,-544
  4012b4:	20112e23          	sw	ra,540(sp)
  4012b8:	20812c23          	sw	s0,536(sp)
  4012bc:	20912a23          	sw	s1,532(sp)
  4012c0:	00050413          	mv	s0,a0
    uint8_t buf[512];

    uint32_t cluster;
    uint32_t size;

    if (fat32_mount())
  4012c4:	00000097          	auipc	ra,0x0
  4012c8:	0d8080e7          	jalr	216(ra) # 40139c <fat32_mount>
  4012cc:	00050593          	mv	a1,a0
  4012d0:	fff00513          	li	a0,-1
  4012d4:	0a059a63          	bnez	a1,401388 <fat32_cat+0xd8>
        return -1;

    if (fat32_find(name, &cluster, &size)) {
  4012d8:	01010593          	addi	a1,sp,16
  4012dc:	00c10613          	addi	a2,sp,12
  4012e0:	00040513          	mv	a0,s0
  4012e4:	00000097          	auipc	ra,0x0
  4012e8:	174080e7          	jalr	372(ra) # 401458 <fat32_find>
  4012ec:	00050e63          	beqz	a0,401308 <fat32_cat+0x58>
        printf("file not found\n");
  4012f0:	00402537          	lui	a0,0x402
  4012f4:	1fb50513          	addi	a0,a0,507 # 4021fb <__modsi3+0x38f>
  4012f8:	00000097          	auipc	ra,0x0
  4012fc:	9b4080e7          	jalr	-1612(ra) # 400cac <printf>
  401300:	fff00513          	li	a0,-1
        return -1;
  401304:	0840006f          	j	401388 <fat32_cat+0xd8>
    }

    uint32_t lba =
        cluster_to_lba(cluster);
  401308:	01012503          	lw	a0,16(sp)
    return -1;
}

uint32_t cluster_to_lba(uint32_t cluster)
{
    return g_fat32.data_begin +
  40130c:	004025b7          	lui	a1,0x402
  401310:	22c58593          	addi	a1,a1,556 # 40222c <g_fat32>
           (cluster - 2) *
           g_fat32.sectors_per_cluster;
  401314:	0105a603          	lw	a2,16(a1)
    return g_fat32.data_begin +
  401318:	0085a583          	lw	a1,8(a1)
           (cluster - 2) *
  40131c:	ffe50513          	addi	a0,a0,-2
  401320:	02a60533          	mul	a0,a2,a0
    return g_fat32.data_begin +
  401324:	00b50533          	add	a0,a0,a1
    if (call_sd_read_buf_api(lba, buf))
  401328:	01410593          	addi	a1,sp,20
  40132c:	00000097          	auipc	ra,0x0
  401330:	f6c080e7          	jalr	-148(ra) # 401298 <call_sd_read_buf_api>
  401334:	00050593          	mv	a1,a0
  401338:	fff00513          	li	a0,-1
  40133c:	04059663          	bnez	a1,401388 <fat32_cat+0xd8>
  401340:	00c12503          	lw	a0,12(sp)
    for (uint32_t i = 0; i < size; i++) {
  401344:	02050a63          	beqz	a0,401378 <fat32_cat+0xc8>
  401348:	fff50513          	addi	a0,a0,-1
  40134c:	1ff00593          	li	a1,511
  401350:	00b56463          	bltu	a0,a1,401358 <fat32_cat+0xa8>
  401354:	1ff00513          	li	a0,511
  401358:	01410413          	addi	s0,sp,20
  40135c:	00850533          	add	a0,a0,s0
  401360:	00150493          	addi	s1,a0,1
        putchar(buf[i]);
  401364:	00044503          	lbu	a0,0(s0)
  401368:	00000097          	auipc	ra,0x0
  40136c:	bfc080e7          	jalr	-1028(ra) # 400f64 <putchar>
    for (uint32_t i = 0; i < size; i++) {
  401370:	00140413          	addi	s0,s0,1
  401374:	fe9418e3          	bne	s0,s1,401364 <fat32_cat+0xb4>
    putchar('\n');
  401378:	00a00513          	li	a0,10
  40137c:	00000097          	auipc	ra,0x0
  401380:	be8080e7          	jalr	-1048(ra) # 400f64 <putchar>
  401384:	00000513          	li	a0,0
}
  401388:	21c12083          	lw	ra,540(sp)
  40138c:	21812403          	lw	s0,536(sp)
  401390:	21412483          	lw	s1,532(sp)
  401394:	22010113          	addi	sp,sp,544
  401398:	00008067          	ret

0040139c <fat32_mount>:
}

int fat32_mount(void)
{
  40139c:	ff010113          	addi	sp,sp,-16
  4013a0:	00112623          	sw	ra,12(sp)
  4013a4:	00812423          	sw	s0,8(sp)
  4013a8:	00912223          	sw	s1,4(sp)
  4013ac:	01212023          	sw	s2,0(sp)
    uint8_t *buf = fat32_buf;

    if (call_sd_read_buf_api(0, buf))
  4013b0:	004025b7          	lui	a1,0x402
  4013b4:	24058593          	addi	a1,a1,576 # 402240 <fat32_buf>
  4013b8:	00000513          	li	a0,0
  4013bc:	00000097          	auipc	ra,0x0
  4013c0:	edc080e7          	jalr	-292(ra) # 401298 <call_sd_read_buf_api>
  4013c4:	fff00413          	li	s0,-1
  4013c8:	06051a63          	bnez	a0,40143c <fat32_mount+0xa0>
        return -1;

    g_fat32.part_lba =
        ((uint32_t)buf[0x1C6]) |
  4013cc:	00402937          	lui	s2,0x402
  4013d0:	22c90493          	addi	s1,s2,556 # 40222c <g_fat32>
        ((uint32_t)buf[0x1C7] << 8) |
        ((uint32_t)buf[0x1C8] << 16) |
  4013d4:	1dc4c503          	lbu	a0,476(s1)
        ((uint32_t)buf[0x1C6]) |
  4013d8:	1da4d583          	lhu	a1,474(s1)
        ((uint32_t)buf[0x1C9] << 24);
  4013dc:	1dd4c603          	lbu	a2,477(s1)
        ((uint32_t)buf[0x1C8] << 16) |
  4013e0:	01051513          	slli	a0,a0,0x10
        ((uint32_t)buf[0x1C7] << 8) |
  4013e4:	00a5e533          	or	a0,a1,a0
        ((uint32_t)buf[0x1C6]) |
  4013e8:	01448593          	addi	a1,s1,20
        ((uint32_t)buf[0x1C9] << 24);
  4013ec:	01861613          	slli	a2,a2,0x18
        ((uint32_t)buf[0x1C8] << 16) |
  4013f0:	00c56533          	or	a0,a0,a2
    g_fat32.part_lba =
  4013f4:	22a92623          	sw	a0,556(s2)

    if (call_sd_read_buf_api(g_fat32.part_lba, buf))
  4013f8:	00000097          	auipc	ra,0x0
  4013fc:	ea0080e7          	jalr	-352(ra) # 401298 <call_sd_read_buf_api>
  401400:	02051e63          	bnez	a0,40143c <fat32_mount+0xa0>
  401404:	00000413          	li	s0,0
        ((uint32_t)buf[45] << 8) |
        ((uint32_t)buf[46] << 16) |
        ((uint32_t)buf[47] << 24);

    g_fat32.fat_begin =
        g_fat32.part_lba + reserved;
  401408:	22c92503          	lw	a0,556(s2)
        ((uint32_t)buf[14]) |
  40140c:	0224d583          	lhu	a1,34(s1)
        (uint32_t)buf[16];
  401410:	0244c603          	lbu	a2,36(s1)
        ((uint32_t)buf[38] << 16) |
  401414:	0384a683          	lw	a3,56(s1)
        (uint32_t)buf[13];
  401418:	0214c703          	lbu	a4,33(s1)
        g_fat32.part_lba + reserved;
  40141c:	00b50533          	add	a0,a0,a1

    g_fat32.data_begin =
        g_fat32.fat_begin + fat_count * fat_size;
  401420:	02c685b3          	mul	a1,a3,a2
        ((uint32_t)buf[46] << 16) |
  401424:	0404a603          	lw	a2,64(s1)
        g_fat32.fat_begin + fat_count * fat_size;
  401428:	00b505b3          	add	a1,a0,a1
    g_fat32.fat_begin =
  40142c:	00a4a223          	sw	a0,4(s1)
    g_fat32.data_begin =
  401430:	00b4a423          	sw	a1,8(s1)
    g_fat32.root_cluster =
  401434:	00c4a623          	sw	a2,12(s1)
    g_fat32.sectors_per_cluster =
  401438:	00e4a823          	sw	a4,16(s1)

    return 0;
}
  40143c:	00040513          	mv	a0,s0
  401440:	00c12083          	lw	ra,12(sp)
  401444:	00812403          	lw	s0,8(sp)
  401448:	00412483          	lw	s1,4(sp)
  40144c:	00012903          	lw	s2,0(sp)
  401450:	01010113          	addi	sp,sp,16
  401454:	00008067          	ret

00401458 <fat32_find>:
{
  401458:	fc010113          	addi	sp,sp,-64
  40145c:	02112e23          	sw	ra,60(sp)
  401460:	02812c23          	sw	s0,56(sp)
  401464:	02912a23          	sw	s1,52(sp)
  401468:	03212823          	sw	s2,48(sp)
  40146c:	03312623          	sw	s3,44(sp)
  401470:	03412423          	sw	s4,40(sp)
  401474:	03512223          	sw	s5,36(sp)
  401478:	03612023          	sw	s6,32(sp)
  40147c:	01712e23          	sw	s7,28(sp)
  401480:	01812c23          	sw	s8,24(sp)
  401484:	01912a23          	sw	s9,20(sp)
  401488:	01a12823          	sw	s10,16(sp)
  40148c:	00060493          	mv	s1,a2
  401490:	00058913          	mv	s2,a1
  401494:	00050993          	mv	s3,a0
    if (fat32_mount())
  401498:	00000097          	auipc	ra,0x0
  40149c:	f04080e7          	jalr	-252(ra) # 40139c <fat32_mount>
  4014a0:	fff00413          	li	s0,-1
  4014a4:	02051a63          	bnez	a0,4014d8 <fat32_find+0x80>
        cluster_to_lba(g_fat32.root_cluster);
  4014a8:	00402a37          	lui	s4,0x402
  4014ac:	22ca0a13          	addi	s4,s4,556 # 40222c <g_fat32>
  4014b0:	00ca2503          	lw	a0,12(s4)
           g_fat32.sectors_per_cluster;
  4014b4:	010a2583          	lw	a1,16(s4)
    return g_fat32.data_begin +
  4014b8:	008a2603          	lw	a2,8(s4)
           (cluster - 2) *
  4014bc:	ffe50513          	addi	a0,a0,-2
  4014c0:	02a58533          	mul	a0,a1,a0
    return g_fat32.data_begin +
  4014c4:	00c50533          	add	a0,a0,a2
    if (call_sd_read_buf_api(root_lba, buf))
  4014c8:	014a0593          	addi	a1,s4,20
  4014cc:	00000097          	auipc	ra,0x0
  4014d0:	dcc080e7          	jalr	-564(ra) # 401298 <call_sd_read_buf_api>
  4014d4:	04050063          	beqz	a0,401514 <fat32_find+0xbc>
}
  4014d8:	00040513          	mv	a0,s0
  4014dc:	03c12083          	lw	ra,60(sp)
  4014e0:	03812403          	lw	s0,56(sp)
  4014e4:	03412483          	lw	s1,52(sp)
  4014e8:	03012903          	lw	s2,48(sp)
  4014ec:	02c12983          	lw	s3,44(sp)
  4014f0:	02812a03          	lw	s4,40(sp)
  4014f4:	02412a83          	lw	s5,36(sp)
  4014f8:	02012b03          	lw	s6,32(sp)
  4014fc:	01c12b83          	lw	s7,28(sp)
  401500:	01812c03          	lw	s8,24(sp)
  401504:	01412c83          	lw	s9,20(sp)
  401508:	01012d03          	lw	s10,16(sp)
  40150c:	04010113          	addi	sp,sp,64
  401510:	00008067          	ret
  401514:	019a0a13          	addi	s4,s4,25
  401518:	01000a93          	li	s5,16
  40151c:	0e500b13          	li	s6,229
  401520:	00f00b93          	li	s7,15
  401524:	02000c13          	li	s8,32
  401528:	00310c93          	addi	s9,sp,3
  40152c:	02e00d13          	li	s10,46
  401530:	0380006f          	j	401568 <fat32_find+0x110>
                    shortname[k++] = e[j];
  401534:	00158513          	addi	a0,a1,1
  401538:	00bc85b3          	add	a1,s9,a1
  40153c:	00c58023          	sb	a2,0(a1)
        shortname[k] = '\0';
  401540:	00ac8533          	add	a0,s9,a0
  401544:	00050023          	sb	zero,0(a0)
        if (strcmp(shortname, name) == 0) {
  401548:	00310513          	addi	a0,sp,3
  40154c:	00098593          	mv	a1,s3
  401550:	00000097          	auipc	ra,0x0
  401554:	bf8080e7          	jalr	-1032(ra) # 401148 <strcmp>
  401558:	14050063          	beqz	a0,401698 <fat32_find+0x240>
    for (int i = 0; i < 16; i++) {
  40155c:	fffa8a93          	addi	s5,s5,-1
  401560:	020a0a13          	addi	s4,s4,32
  401564:	f60a8ae3          	beqz	s5,4014d8 <fat32_find+0x80>
        if (e[0] == 0x00)
  401568:	ffba4503          	lbu	a0,-5(s4)
  40156c:	ff6508e3          	beq	a0,s6,40155c <fat32_find+0x104>
  401570:	f60504e3          	beqz	a0,4014d8 <fat32_find+0x80>
        if (e[11] == 0x0F)
  401574:	006a4583          	lbu	a1,6(s4)
  401578:	ff7582e3          	beq	a1,s7,40155c <fat32_find+0x104>
            if (e[j] != ' ')
  40157c:	01851a63          	bne	a0,s8,401590 <fat32_find+0x138>
  401580:	00000513          	li	a0,0
  401584:	ffca4583          	lbu	a1,-4(s4)
  401588:	01859c63          	bne	a1,s8,4015a0 <fat32_find+0x148>
  40158c:	0200006f          	j	4015ac <fat32_find+0x154>
                shortname[k++] = e[j];
  401590:	00a101a3          	sb	a0,3(sp)
  401594:	00100513          	li	a0,1
            if (e[j] != ' ')
  401598:	ffca4583          	lbu	a1,-4(s4)
  40159c:	01858863          	beq	a1,s8,4015ac <fat32_find+0x154>
                shortname[k++] = e[j];
  4015a0:	00ac8633          	add	a2,s9,a0
  4015a4:	00150513          	addi	a0,a0,1
  4015a8:	00b60023          	sb	a1,0(a2)
            if (e[j] != ' ')
  4015ac:	ffda4583          	lbu	a1,-3(s4)
  4015b0:	03859c63          	bne	a1,s8,4015e8 <fat32_find+0x190>
  4015b4:	ffea4583          	lbu	a1,-2(s4)
  4015b8:	05859263          	bne	a1,s8,4015fc <fat32_find+0x1a4>
  4015bc:	fffa4583          	lbu	a1,-1(s4)
  4015c0:	05859863          	bne	a1,s8,401610 <fat32_find+0x1b8>
  4015c4:	000a4583          	lbu	a1,0(s4)
  4015c8:	05859e63          	bne	a1,s8,401624 <fat32_find+0x1cc>
  4015cc:	001a4583          	lbu	a1,1(s4)
  4015d0:	07859463          	bne	a1,s8,401638 <fat32_find+0x1e0>
  4015d4:	002a4583          	lbu	a1,2(s4)
  4015d8:	07859a63          	bne	a1,s8,40164c <fat32_find+0x1f4>
        if (e[8] != ' ') {
  4015dc:	003a4583          	lbu	a1,3(s4)
  4015e0:	f78580e3          	beq	a1,s8,401540 <fat32_find+0xe8>
  4015e4:	07c0006f          	j	401660 <fat32_find+0x208>
                shortname[k++] = e[j];
  4015e8:	00ac8633          	add	a2,s9,a0
  4015ec:	00150513          	addi	a0,a0,1
  4015f0:	00b60023          	sb	a1,0(a2)
            if (e[j] != ' ')
  4015f4:	ffea4583          	lbu	a1,-2(s4)
  4015f8:	fd8582e3          	beq	a1,s8,4015bc <fat32_find+0x164>
                shortname[k++] = e[j];
  4015fc:	00ac8633          	add	a2,s9,a0
  401600:	00150513          	addi	a0,a0,1
  401604:	00b60023          	sb	a1,0(a2)
            if (e[j] != ' ')
  401608:	fffa4583          	lbu	a1,-1(s4)
  40160c:	fb858ce3          	beq	a1,s8,4015c4 <fat32_find+0x16c>
                shortname[k++] = e[j];
  401610:	00ac8633          	add	a2,s9,a0
  401614:	00150513          	addi	a0,a0,1
  401618:	00b60023          	sb	a1,0(a2)
            if (e[j] != ' ')
  40161c:	000a4583          	lbu	a1,0(s4)
  401620:	fb8586e3          	beq	a1,s8,4015cc <fat32_find+0x174>
                shortname[k++] = e[j];
  401624:	00ac8633          	add	a2,s9,a0
  401628:	00150513          	addi	a0,a0,1
  40162c:	00b60023          	sb	a1,0(a2)
            if (e[j] != ' ')
  401630:	001a4583          	lbu	a1,1(s4)
  401634:	fb8580e3          	beq	a1,s8,4015d4 <fat32_find+0x17c>
                shortname[k++] = e[j];
  401638:	00ac8633          	add	a2,s9,a0
  40163c:	00150513          	addi	a0,a0,1
  401640:	00b60023          	sb	a1,0(a2)
            if (e[j] != ' ')
  401644:	002a4583          	lbu	a1,2(s4)
  401648:	f9858ae3          	beq	a1,s8,4015dc <fat32_find+0x184>
                shortname[k++] = e[j];
  40164c:	00ac8633          	add	a2,s9,a0
  401650:	00150513          	addi	a0,a0,1
  401654:	00b60023          	sb	a1,0(a2)
        if (e[8] != ' ') {
  401658:	003a4583          	lbu	a1,3(s4)
  40165c:	ef8582e3          	beq	a1,s8,401540 <fat32_find+0xe8>
                if (e[j] != ' ')
  401660:	004a4603          	lbu	a2,4(s4)
            shortname[k++] = '.';
  401664:	00ac86b3          	add	a3,s9,a0
  401668:	01a68023          	sb	s10,0(a3)
                    shortname[k++] = e[j];
  40166c:	00b680a3          	sb	a1,1(a3)
  401670:	00250593          	addi	a1,a0,2
                if (e[j] != ' ')
  401674:	01860a63          	beq	a2,s8,401688 <fat32_find+0x230>
                    shortname[k++] = e[j];
  401678:	00bc85b3          	add	a1,s9,a1
  40167c:	00350513          	addi	a0,a0,3
  401680:	00c58023          	sb	a2,0(a1)
  401684:	00050593          	mv	a1,a0
                if (e[j] != ' ')
  401688:	005a4603          	lbu	a2,5(s4)
  40168c:	eb8614e3          	bne	a2,s8,401534 <fat32_find+0xdc>
  401690:	00058513          	mv	a0,a1
  401694:	eadff06f          	j	401540 <fat32_find+0xe8>
  401698:	00000413          	li	s0,0
                ((uint32_t)e[21] << 8);
  40169c:	010a4503          	lbu	a0,16(s4)
                ((uint32_t)e[20]) |
  4016a0:	00fa4583          	lbu	a1,15(s4)
                ((uint32_t)e[26]) |
  4016a4:	015a4603          	lbu	a2,21(s4)
                ((uint32_t)e[27] << 8);
  4016a8:	016a4683          	lbu	a3,22(s4)
                (cl_hi << 16) | cl_lo;
  4016ac:	01851513          	slli	a0,a0,0x18
  4016b0:	01059593          	slli	a1,a1,0x10
                ((uint32_t)e[26]) |
  4016b4:	00b56533          	or	a0,a0,a1
                ((uint32_t)e[27] << 8);
  4016b8:	00869693          	slli	a3,a3,0x8
                (cl_hi << 16) | cl_lo;
  4016bc:	00d66633          	or	a2,a2,a3
  4016c0:	00c56533          	or	a0,a0,a2
            *cluster =
  4016c4:	00a92023          	sw	a0,0(s2)
                ((uint32_t)e[29] << 8) |
  4016c8:	018a4503          	lbu	a0,24(s4)
                ((uint32_t)e[30] << 16) |
  4016cc:	019a4583          	lbu	a1,25(s4)
                ((uint32_t)e[31] << 24);
  4016d0:	01aa4603          	lbu	a2,26(s4)
                ((uint32_t)e[28]) |
  4016d4:	017a4683          	lbu	a3,23(s4)
                ((uint32_t)e[29] << 8) |
  4016d8:	00851513          	slli	a0,a0,0x8
                ((uint32_t)e[30] << 16) |
  4016dc:	01059593          	slli	a1,a1,0x10
                ((uint32_t)e[31] << 24);
  4016e0:	01861613          	slli	a2,a2,0x18
                ((uint32_t)e[28]) |
  4016e4:	00d56533          	or	a0,a0,a3
                ((uint32_t)e[29] << 8) |
  4016e8:	00c5e5b3          	or	a1,a1,a2
                ((uint32_t)e[30] << 16) |
  4016ec:	00b56533          	or	a0,a0,a1
            *size =
  4016f0:	00a4a023          	sw	a0,0(s1)
  4016f4:	de5ff06f          	j	4014d8 <fat32_find+0x80>

004016f8 <cluster_to_lba>:
    return g_fat32.data_begin +
  4016f8:	004025b7          	lui	a1,0x402
  4016fc:	22c58593          	addi	a1,a1,556 # 40222c <g_fat32>
           g_fat32.sectors_per_cluster;
  401700:	0105a603          	lw	a2,16(a1)
    return g_fat32.data_begin +
  401704:	0085a583          	lw	a1,8(a1)
           (cluster - 2) *
  401708:	ffe50513          	addi	a0,a0,-2
  40170c:	02a60533          	mul	a0,a2,a0
    return g_fat32.data_begin +
  401710:	00b50533          	add	a0,a0,a1
  401714:	00008067          	ret

00401718 <fat32_ls>:

void fat32_ls(void)
{
  401718:	fd010113          	addi	sp,sp,-48
  40171c:	02112623          	sw	ra,44(sp)
  401720:	02812423          	sw	s0,40(sp)
  401724:	02912223          	sw	s1,36(sp)
  401728:	03212023          	sw	s2,32(sp)
  40172c:	01312e23          	sw	s3,28(sp)
  401730:	01412c23          	sw	s4,24(sp)
  401734:	01512a23          	sw	s5,20(sp)
  401738:	01612823          	sw	s6,16(sp)
  40173c:	01712623          	sw	s7,12(sp)
  401740:	01812423          	sw	s8,8(sp)
    uint8_t *buf = fat32_buf;

    if (fat32_mount())
  401744:	00000097          	auipc	ra,0x0
  401748:	c58080e7          	jalr	-936(ra) # 40139c <fat32_mount>
  40174c:	02051a63          	bnez	a0,401780 <fat32_ls+0x68>
        return;

    uint32_t root_lba =
        cluster_to_lba(g_fat32.root_cluster);
  401750:	00402937          	lui	s2,0x402
  401754:	22c90913          	addi	s2,s2,556 # 40222c <g_fat32>
  401758:	00c92503          	lw	a0,12(s2)
           g_fat32.sectors_per_cluster;
  40175c:	01092583          	lw	a1,16(s2)
    return g_fat32.data_begin +
  401760:	00892603          	lw	a2,8(s2)
           (cluster - 2) *
  401764:	ffe50513          	addi	a0,a0,-2
  401768:	02a58533          	mul	a0,a1,a0
    return g_fat32.data_begin +
  40176c:	00c50533          	add	a0,a0,a2

    if (call_sd_read_buf_api(root_lba, buf))
  401770:	01490593          	addi	a1,s2,20
  401774:	00000097          	auipc	ra,0x0
  401778:	b24080e7          	jalr	-1244(ra) # 401298 <call_sd_read_buf_api>
  40177c:	02050a63          	beqz	a0,4017b0 <fat32_ls+0x98>
        printf(" cl=%x lba=%x size=%x\n",
                cl,
                lba,
                size);
    }
}
  401780:	02c12083          	lw	ra,44(sp)
  401784:	02812403          	lw	s0,40(sp)
  401788:	02412483          	lw	s1,36(sp)
  40178c:	02012903          	lw	s2,32(sp)
  401790:	01c12983          	lw	s3,28(sp)
  401794:	01812a03          	lw	s4,24(sp)
  401798:	01412a83          	lw	s5,20(sp)
  40179c:	01012b03          	lw	s6,16(sp)
  4017a0:	00c12b83          	lw	s7,12(sp)
  4017a4:	00812c03          	lw	s8,8(sp)
  4017a8:	03010113          	addi	sp,sp,48
  4017ac:	00008067          	ret
  4017b0:	01990993          	addi	s3,s2,25
  4017b4:	01000a13          	li	s4,16
  4017b8:	0e500a93          	li	s5,229
  4017bc:	00f00b13          	li	s6,15
  4017c0:	02000b93          	li	s7,32
  4017c4:	00402437          	lui	s0,0x402
  4017c8:	20b40413          	addi	s0,s0,523 # 40220b <__modsi3+0x39f>
  4017cc:	00200c13          	li	s8,2
  4017d0:	004024b7          	lui	s1,0x402
  4017d4:	17c48493          	addi	s1,s1,380 # 40217c <__modsi3+0x310>
  4017d8:	0580006f          	j	401830 <fat32_ls+0x118>
           g_fat32.sectors_per_cluster;
  4017dc:	01092503          	lw	a0,16(s2)
    return g_fat32.data_begin +
  4017e0:	00892603          	lw	a2,8(s2)
           (cluster - 2) *
  4017e4:	ffe58693          	addi	a3,a1,-2
  4017e8:	02d50533          	mul	a0,a0,a3
    return g_fat32.data_begin +
  4017ec:	00c50633          	add	a2,a0,a2
            ((uint32_t)e[29] << 8) |
  4017f0:	0189c503          	lbu	a0,24(s3)
            ((uint32_t)e[28]) |
  4017f4:	0179c683          	lbu	a3,23(s3)
            ((uint32_t)e[30] << 16) |
  4017f8:	0199c703          	lbu	a4,25(s3)
            ((uint32_t)e[31] << 24);
  4017fc:	01a9c783          	lbu	a5,26(s3)
            ((uint32_t)e[29] << 8) |
  401800:	00851513          	slli	a0,a0,0x8
            ((uint32_t)e[28]) |
  401804:	00d56533          	or	a0,a0,a3
            ((uint32_t)e[30] << 16) |
  401808:	01071713          	slli	a4,a4,0x10
            ((uint32_t)e[31] << 24);
  40180c:	01879793          	slli	a5,a5,0x18
            ((uint32_t)e[29] << 8) |
  401810:	00f766b3          	or	a3,a4,a5
            ((uint32_t)e[30] << 16) |
  401814:	00d566b3          	or	a3,a0,a3
        printf(" cl=%x lba=%x size=%x\n",
  401818:	00048513          	mv	a0,s1
  40181c:	fffff097          	auipc	ra,0xfffff
  401820:	490080e7          	jalr	1168(ra) # 400cac <printf>
    for (int i = 0; i < 16; i++) {
  401824:	fffa0a13          	addi	s4,s4,-1
  401828:	02098993          	addi	s3,s3,32
  40182c:	f40a0ae3          	beqz	s4,401780 <fat32_ls+0x68>
        if (e[0] == 0x00)
  401830:	ffb9c503          	lbu	a0,-5(s3)
  401834:	ff5508e3          	beq	a0,s5,401824 <fat32_ls+0x10c>
  401838:	f40504e3          	beqz	a0,401780 <fat32_ls+0x68>
        if (e[11] == 0x0F)
  40183c:	0069c583          	lbu	a1,6(s3)
  401840:	ff6582e3          	beq	a1,s6,401824 <fat32_ls+0x10c>
            if (e[j] != ' ')
  401844:	05751463          	bne	a0,s7,40188c <fat32_ls+0x174>
  401848:	ffc9c503          	lbu	a0,-4(s3)
  40184c:	05751863          	bne	a0,s7,40189c <fat32_ls+0x184>
  401850:	ffd9c503          	lbu	a0,-3(s3)
  401854:	05751c63          	bne	a0,s7,4018ac <fat32_ls+0x194>
  401858:	ffe9c503          	lbu	a0,-2(s3)
  40185c:	07751063          	bne	a0,s7,4018bc <fat32_ls+0x1a4>
  401860:	fff9c503          	lbu	a0,-1(s3)
  401864:	07751463          	bne	a0,s7,4018cc <fat32_ls+0x1b4>
  401868:	0009c503          	lbu	a0,0(s3)
  40186c:	07751863          	bne	a0,s7,4018dc <fat32_ls+0x1c4>
  401870:	0019c503          	lbu	a0,1(s3)
  401874:	07751c63          	bne	a0,s7,4018ec <fat32_ls+0x1d4>
  401878:	0029c503          	lbu	a0,2(s3)
  40187c:	09751063          	bne	a0,s7,4018fc <fat32_ls+0x1e4>
        if (e[8] != ' ') {
  401880:	0039c503          	lbu	a0,3(s3)
  401884:	09751463          	bne	a0,s7,40190c <fat32_ls+0x1f4>
  401888:	0b00006f          	j	401938 <fat32_ls+0x220>
                putchar(e[j]);
  40188c:	fffff097          	auipc	ra,0xfffff
  401890:	6d8080e7          	jalr	1752(ra) # 400f64 <putchar>
            if (e[j] != ' ')
  401894:	ffc9c503          	lbu	a0,-4(s3)
  401898:	fb750ce3          	beq	a0,s7,401850 <fat32_ls+0x138>
                putchar(e[j]);
  40189c:	fffff097          	auipc	ra,0xfffff
  4018a0:	6c8080e7          	jalr	1736(ra) # 400f64 <putchar>
            if (e[j] != ' ')
  4018a4:	ffd9c503          	lbu	a0,-3(s3)
  4018a8:	fb7508e3          	beq	a0,s7,401858 <fat32_ls+0x140>
                putchar(e[j]);
  4018ac:	fffff097          	auipc	ra,0xfffff
  4018b0:	6b8080e7          	jalr	1720(ra) # 400f64 <putchar>
            if (e[j] != ' ')
  4018b4:	ffe9c503          	lbu	a0,-2(s3)
  4018b8:	fb7504e3          	beq	a0,s7,401860 <fat32_ls+0x148>
                putchar(e[j]);
  4018bc:	fffff097          	auipc	ra,0xfffff
  4018c0:	6a8080e7          	jalr	1704(ra) # 400f64 <putchar>
            if (e[j] != ' ')
  4018c4:	fff9c503          	lbu	a0,-1(s3)
  4018c8:	fb7500e3          	beq	a0,s7,401868 <fat32_ls+0x150>
                putchar(e[j]);
  4018cc:	fffff097          	auipc	ra,0xfffff
  4018d0:	698080e7          	jalr	1688(ra) # 400f64 <putchar>
            if (e[j] != ' ')
  4018d4:	0009c503          	lbu	a0,0(s3)
  4018d8:	f9750ce3          	beq	a0,s7,401870 <fat32_ls+0x158>
                putchar(e[j]);
  4018dc:	fffff097          	auipc	ra,0xfffff
  4018e0:	688080e7          	jalr	1672(ra) # 400f64 <putchar>
            if (e[j] != ' ')
  4018e4:	0019c503          	lbu	a0,1(s3)
  4018e8:	f97508e3          	beq	a0,s7,401878 <fat32_ls+0x160>
                putchar(e[j]);
  4018ec:	fffff097          	auipc	ra,0xfffff
  4018f0:	678080e7          	jalr	1656(ra) # 400f64 <putchar>
            if (e[j] != ' ')
  4018f4:	0029c503          	lbu	a0,2(s3)
  4018f8:	f97504e3          	beq	a0,s7,401880 <fat32_ls+0x168>
                putchar(e[j]);
  4018fc:	fffff097          	auipc	ra,0xfffff
  401900:	668080e7          	jalr	1640(ra) # 400f64 <putchar>
        if (e[8] != ' ') {
  401904:	0039c503          	lbu	a0,3(s3)
  401908:	03750863          	beq	a0,s7,401938 <fat32_ls+0x220>
            putchar('.');
  40190c:	02e00513          	li	a0,46
  401910:	fffff097          	auipc	ra,0xfffff
  401914:	654080e7          	jalr	1620(ra) # 400f64 <putchar>
                if (e[j] != ' ')
  401918:	0039c503          	lbu	a0,3(s3)
  40191c:	07751063          	bne	a0,s7,40197c <fat32_ls+0x264>
  401920:	0049c503          	lbu	a0,4(s3)
  401924:	07751463          	bne	a0,s7,40198c <fat32_ls+0x274>
  401928:	0059c503          	lbu	a0,5(s3)
  40192c:	01750663          	beq	a0,s7,401938 <fat32_ls+0x220>
                    putchar(e[j]);
  401930:	fffff097          	auipc	ra,0xfffff
  401934:	634080e7          	jalr	1588(ra) # 400f64 <putchar>
        printf(" attr=%x", (uint32_t)e[11]);
  401938:	0069c583          	lbu	a1,6(s3)
  40193c:	00040513          	mv	a0,s0
  401940:	fffff097          	auipc	ra,0xfffff
  401944:	36c080e7          	jalr	876(ra) # 400cac <printf>
            ((uint32_t)e[27] << 8);
  401948:	0169c503          	lbu	a0,22(s3)
            ((uint32_t)e[21] << 8);
  40194c:	0109c583          	lbu	a1,16(s3)
            ((uint32_t)e[20]) |
  401950:	00f9c603          	lbu	a2,15(s3)
            ((uint32_t)e[26]) |
  401954:	0159c683          	lbu	a3,21(s3)
            ((uint32_t)e[27] << 8);
  401958:	00851513          	slli	a0,a0,0x8
            (cl_hi << 16) | cl_lo;
  40195c:	01859593          	slli	a1,a1,0x18
  401960:	01061613          	slli	a2,a2,0x10
            ((uint32_t)e[26]) |
  401964:	00c5e5b3          	or	a1,a1,a2
            (cl_hi << 16) | cl_lo;
  401968:	00a6e533          	or	a0,a3,a0
  40196c:	00a5e5b3          	or	a1,a1,a0
        if (cl >= 2)
  401970:	e785f6e3          	bgeu	a1,s8,4017dc <fat32_ls+0xc4>
  401974:	00000613          	li	a2,0
  401978:	e79ff06f          	j	4017f0 <fat32_ls+0xd8>
                    putchar(e[j]);
  40197c:	fffff097          	auipc	ra,0xfffff
  401980:	5e8080e7          	jalr	1512(ra) # 400f64 <putchar>
                if (e[j] != ' ')
  401984:	0049c503          	lbu	a0,4(s3)
  401988:	fb7500e3          	beq	a0,s7,401928 <fat32_ls+0x210>
                    putchar(e[j]);
  40198c:	fffff097          	auipc	ra,0xfffff
  401990:	5d8080e7          	jalr	1496(ra) # 400f64 <putchar>
                if (e[j] != ' ')
  401994:	0059c503          	lbu	a0,5(s3)
  401998:	f9751ce3          	bne	a0,s7,401930 <fat32_ls+0x218>
  40199c:	f9dff06f          	j	401938 <fat32_ls+0x220>

004019a0 <fat32_touch>:

    return 0;
}

int fat32_touch(const char *name)
{
  4019a0:	fd010113          	addi	sp,sp,-48
  4019a4:	02112623          	sw	ra,44(sp)
  4019a8:	02812423          	sw	s0,40(sp)
  4019ac:	02912223          	sw	s1,36(sp)
  4019b0:	03212023          	sw	s2,32(sp)
  4019b4:	01312e23          	sw	s3,28(sp)
  4019b8:	01412c23          	sw	s4,24(sp)
  4019bc:	00050413          	mv	s0,a0
    uint8_t *buf = fat32_buf;

    if (fat32_mount())
  4019c0:	00000097          	auipc	ra,0x0
  4019c4:	9dc080e7          	jalr	-1572(ra) # 40139c <fat32_mount>
  4019c8:	fff00993          	li	s3,-1
  4019cc:	36051063          	bnez	a0,401d2c <fat32_touch+0x38c>
        return -1;

    uint32_t root_lba =
        cluster_to_lba(g_fat32.root_cluster);
  4019d0:	00402a37          	lui	s4,0x402
  4019d4:	22ca0a13          	addi	s4,s4,556 # 40222c <g_fat32>
  4019d8:	00ca2503          	lw	a0,12(s4)
           g_fat32.sectors_per_cluster;
  4019dc:	010a2583          	lw	a1,16(s4)
    return g_fat32.data_begin +
  4019e0:	008a2483          	lw	s1,8(s4)
           (cluster - 2) *
  4019e4:	ffe50513          	addi	a0,a0,-2
  4019e8:	02a58533          	mul	a0,a1,a0
    return g_fat32.data_begin +
  4019ec:	009504b3          	add	s1,a0,s1

    if (call_sd_read_buf_api(root_lba, buf))
  4019f0:	014a0913          	addi	s2,s4,20
  4019f4:	00048513          	mv	a0,s1
  4019f8:	00090593          	mv	a1,s2
  4019fc:	00000097          	auipc	ra,0x0
  401a00:	89c080e7          	jalr	-1892(ra) # 401298 <call_sd_read_buf_api>
  401a04:	32051463          	bnez	a0,401d2c <fat32_touch+0x38c>
  401a08:	02000593          	li	a1,32
    while (*name &&
  401a0c:	00044503          	lbu	a0,0(s0)
        out[i] = ' ';
  401a10:	00b106a3          	sb	a1,13(sp)
  401a14:	00b10723          	sb	a1,14(sp)
  401a18:	00b107a3          	sb	a1,15(sp)
  401a1c:	00b10823          	sb	a1,16(sp)
  401a20:	00b108a3          	sb	a1,17(sp)
  401a24:	00b10923          	sb	a1,18(sp)
  401a28:	00b109a3          	sb	a1,19(sp)
  401a2c:	00b10a23          	sb	a1,20(sp)
  401a30:	00b10aa3          	sb	a1,21(sp)
  401a34:	00b10b23          	sb	a1,22(sp)
  401a38:	00b10ba3          	sb	a1,23(sp)
    while (*name &&
  401a3c:	04050063          	beqz	a0,401a7c <fat32_touch+0xdc>
  401a40:	00000593          	li	a1,0
  401a44:	02e00613          	li	a2,46
  401a48:	00700693          	li	a3,7
  401a4c:	00d10713          	addi	a4,sp,13
           *name != '.' &&
  401a50:	02c50a63          	beq	a0,a2,401a84 <fat32_touch+0xe4>
  401a54:	02b6e863          	bltu	a3,a1,401a84 <fat32_touch+0xe4>
        out[pos++] = *name++;
  401a58:	00b407b3          	add	a5,s0,a1
  401a5c:	00b70833          	add	a6,a4,a1
  401a60:	00a80023          	sb	a0,0(a6)
    while (*name &&
  401a64:	0017c503          	lbu	a0,1(a5)
        out[pos++] = *name++;
  401a68:	00158793          	addi	a5,a1,1
  401a6c:	00078593          	mv	a1,a5
    while (*name &&
  401a70:	fe0510e3          	bnez	a0,401a50 <fat32_touch+0xb0>
    while (*name &&
  401a74:	00f405b3          	add	a1,s0,a5
  401a78:	0100006f          	j	401a88 <fat32_touch+0xe8>
  401a7c:	00040593          	mv	a1,s0
    while (*name &&
  401a80:	0080006f          	j	401a88 <fat32_touch+0xe8>
  401a84:	00b405b3          	add	a1,s0,a1
    while (*name &&
  401a88:	00158593          	addi	a1,a1,1
  401a8c:	02e00613          	li	a2,46
  401a90:	00050a63          	beqz	a0,401aa4 <fat32_touch+0x104>
  401a94:	00c50863          	beq	a0,a2,401aa4 <fat32_touch+0x104>
  401a98:	0005c503          	lbu	a0,0(a1)
  401a9c:	00158593          	addi	a1,a1,1
  401aa0:	fe051ae3          	bnez	a0,401a94 <fat32_touch+0xf4>
    if (*name == '.')
  401aa4:	fd250513          	addi	a0,a0,-46
  401aa8:	00153513          	seqz	a0,a0
    while (*name && pos < 11) {
  401aac:	00a58533          	add	a0,a1,a0
  401ab0:	fff54583          	lbu	a1,-1(a0)
  401ab4:	02058863          	beqz	a1,401ae4 <fat32_touch+0x144>
  401ab8:	00000613          	li	a2,0
  401abc:	01510693          	addi	a3,sp,21
  401ac0:	00a00713          	li	a4,10
        out[pos++] = *name++;
  401ac4:	00c507b3          	add	a5,a0,a2
  401ac8:	00c68833          	add	a6,a3,a2
  401acc:	00b80023          	sb	a1,0(a6)
    while (*name && pos < 11) {
  401ad0:	0007c583          	lbu	a1,0(a5)
  401ad4:	00058863          	beqz	a1,401ae4 <fat32_touch+0x144>
  401ad8:	00860793          	addi	a5,a2,8
  401adc:	00160613          	addi	a2,a2,1
  401ae0:	fee7e2e3          	bltu	a5,a4,401ac4 <fat32_touch+0x124>

    for (int i = 0; i < 16; i++) {

        uint8_t *e = &buf[i * 32];

        if (e[0] != 0x00 &&
  401ae4:	014a4583          	lbu	a1,20(s4)
  401ae8:	0e500613          	li	a2,229
  401aec:	00090513          	mv	a0,s2
  401af0:	12c58c63          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401af4:	00090513          	mv	a0,s2
  401af8:	12058863          	beqz	a1,401c28 <fat32_touch+0x288>
  401afc:	034a4583          	lbu	a1,52(s4)
  401b00:	034a0513          	addi	a0,s4,52
  401b04:	12058263          	beqz	a1,401c28 <fat32_touch+0x288>
  401b08:	0e500613          	li	a2,229
  401b0c:	10c58e63          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401b10:	054a4583          	lbu	a1,84(s4)
  401b14:	054a0513          	addi	a0,s4,84
  401b18:	10058863          	beqz	a1,401c28 <fat32_touch+0x288>
  401b1c:	0e500613          	li	a2,229
  401b20:	10c58463          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401b24:	074a4583          	lbu	a1,116(s4)
  401b28:	074a0513          	addi	a0,s4,116
  401b2c:	0e058e63          	beqz	a1,401c28 <fat32_touch+0x288>
  401b30:	0e500613          	li	a2,229
  401b34:	0ec58a63          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401b38:	094a4583          	lbu	a1,148(s4)
  401b3c:	094a0513          	addi	a0,s4,148
  401b40:	0e058463          	beqz	a1,401c28 <fat32_touch+0x288>
  401b44:	0e500613          	li	a2,229
  401b48:	0ec58063          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401b4c:	0b4a4583          	lbu	a1,180(s4)
  401b50:	0b4a0513          	addi	a0,s4,180
  401b54:	0c058a63          	beqz	a1,401c28 <fat32_touch+0x288>
  401b58:	0e500613          	li	a2,229
  401b5c:	0cc58663          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401b60:	0d4a4583          	lbu	a1,212(s4)
  401b64:	0d4a0513          	addi	a0,s4,212
  401b68:	0c058063          	beqz	a1,401c28 <fat32_touch+0x288>
  401b6c:	0e500613          	li	a2,229
  401b70:	0ac58c63          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401b74:	0f4a4583          	lbu	a1,244(s4)
  401b78:	0f4a0513          	addi	a0,s4,244
  401b7c:	0a058663          	beqz	a1,401c28 <fat32_touch+0x288>
  401b80:	0e500613          	li	a2,229
  401b84:	0ac58263          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401b88:	114a4583          	lbu	a1,276(s4)
  401b8c:	114a0513          	addi	a0,s4,276
  401b90:	08058c63          	beqz	a1,401c28 <fat32_touch+0x288>
  401b94:	0e500613          	li	a2,229
  401b98:	08c58863          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401b9c:	134a4583          	lbu	a1,308(s4)
  401ba0:	134a0513          	addi	a0,s4,308
  401ba4:	08058263          	beqz	a1,401c28 <fat32_touch+0x288>
  401ba8:	0e500613          	li	a2,229
  401bac:	06c58e63          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401bb0:	154a4583          	lbu	a1,340(s4)
  401bb4:	154a0513          	addi	a0,s4,340
  401bb8:	06058863          	beqz	a1,401c28 <fat32_touch+0x288>
  401bbc:	0e500613          	li	a2,229
  401bc0:	06c58463          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401bc4:	174a4583          	lbu	a1,372(s4)
  401bc8:	174a0513          	addi	a0,s4,372
  401bcc:	04058e63          	beqz	a1,401c28 <fat32_touch+0x288>
  401bd0:	0e500613          	li	a2,229
  401bd4:	04c58a63          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401bd8:	194a4583          	lbu	a1,404(s4)
  401bdc:	194a0513          	addi	a0,s4,404
  401be0:	04058463          	beqz	a1,401c28 <fat32_touch+0x288>
  401be4:	0e500613          	li	a2,229
  401be8:	04c58063          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401bec:	1b4a4583          	lbu	a1,436(s4)
  401bf0:	1b4a0513          	addi	a0,s4,436
  401bf4:	02058a63          	beqz	a1,401c28 <fat32_touch+0x288>
  401bf8:	0e500613          	li	a2,229
  401bfc:	02c58663          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401c00:	1d4a4583          	lbu	a1,468(s4)
  401c04:	1d4a0513          	addi	a0,s4,468
  401c08:	02058063          	beqz	a1,401c28 <fat32_touch+0x288>
  401c0c:	0e500613          	li	a2,229
  401c10:	00c58c63          	beq	a1,a2,401c28 <fat32_touch+0x288>
  401c14:	1f4a4583          	lbu	a1,500(s4)
  401c18:	1f4a0513          	addi	a0,s4,500
  401c1c:	00058663          	beqz	a1,401c28 <fat32_touch+0x288>
  401c20:	0e500613          	li	a2,229
  401c24:	0ec59463          	bne	a1,a2,401d0c <fat32_touch+0x36c>
            e[0] != 0xE5)
            continue;

        for (int j = 0; j < 32; j++)
            e[j] = 0;
  401c28:	00050623          	sb	zero,12(a0)
  401c2c:	000506a3          	sb	zero,13(a0)
  401c30:	00050723          	sb	zero,14(a0)
  401c34:	000507a3          	sb	zero,15(a0)
  401c38:	00050823          	sb	zero,16(a0)
  401c3c:	000508a3          	sb	zero,17(a0)
  401c40:	00050923          	sb	zero,18(a0)
  401c44:	000509a3          	sb	zero,19(a0)

        // archive
        e[11] = 0x20;

        // first cluster = 0
        e[20] = 0;
  401c48:	00050a23          	sb	zero,20(a0)
        e[21] = 0;
  401c4c:	00050aa3          	sb	zero,21(a0)
            e[j] = 0;
  401c50:	00050b23          	sb	zero,22(a0)
  401c54:	00050ba3          	sb	zero,23(a0)
            e[j] = shortname[j];
  401c58:	00d14583          	lbu	a1,13(sp)
  401c5c:	00e14603          	lbu	a2,14(sp)
  401c60:	00f14683          	lbu	a3,15(sp)
  401c64:	01014703          	lbu	a4,16(sp)
  401c68:	01114783          	lbu	a5,17(sp)
  401c6c:	01214803          	lbu	a6,18(sp)
  401c70:	01314883          	lbu	a7,19(sp)
  401c74:	01414283          	lbu	t0,20(sp)
  401c78:	00b50023          	sb	a1,0(a0)
  401c7c:	00c500a3          	sb	a2,1(a0)
  401c80:	00d50123          	sb	a3,2(a0)
  401c84:	00e501a3          	sb	a4,3(a0)
  401c88:	01514583          	lbu	a1,21(sp)
  401c8c:	01614603          	lbu	a2,22(sp)
  401c90:	01714683          	lbu	a3,23(sp)
  401c94:	00f50223          	sb	a5,4(a0)
  401c98:	010502a3          	sb	a6,5(a0)
  401c9c:	01150323          	sb	a7,6(a0)
  401ca0:	005503a3          	sb	t0,7(a0)
  401ca4:	02000713          	li	a4,32
            e[j] = 0;
  401ca8:	00050c23          	sb	zero,24(a0)
  401cac:	00050ca3          	sb	zero,25(a0)
        e[26] = 0;
  401cb0:	00050d23          	sb	zero,26(a0)
        e[27] = 0;
  401cb4:	00050da3          	sb	zero,27(a0)
            e[j] = shortname[j];
  401cb8:	00b50423          	sb	a1,8(a0)
  401cbc:	00c504a3          	sb	a2,9(a0)
  401cc0:	00d50523          	sb	a3,10(a0)
        e[11] = 0x20;
  401cc4:	00e505a3          	sb	a4,11(a0)

        // size = 0
        e[28] = 0;
  401cc8:	00050e23          	sb	zero,28(a0)
        e[29] = 0;
  401ccc:	00050ea3          	sb	zero,29(a0)
        e[30] = 0;
  401cd0:	00050f23          	sb	zero,30(a0)
        e[31] = 0;
  401cd4:	00050fa3          	sb	zero,31(a0)

        printf("USER BUF: ");
  401cd8:	00402537          	lui	a0,0x402
  401cdc:	21450513          	addi	a0,a0,532 # 402214 <__modsi3+0x3a8>
  401ce0:	fffff097          	auipc	ra,0xfffff
  401ce4:	fcc080e7          	jalr	-52(ra) # 400cac <printf>
        for (int i = 0; i < 16; i++) {
            printf("%x ", (uint32_t)buf[i]);
        }
        */

        printf("\n");
  401ce8:	00402537          	lui	a0,0x402
  401cec:	f1950513          	addi	a0,a0,-231 # 401f19 <__modsi3+0xad>
  401cf0:	fffff097          	auipc	ra,0xfffff
  401cf4:	fbc080e7          	jalr	-68(ra) # 400cac <printf>

        if (call_sd_write_buf_api(root_lba, buf))
  401cf8:	00048513          	mv	a0,s1
  401cfc:	00090593          	mv	a1,s2
  401d00:	fffff097          	auipc	ra,0xfffff
  401d04:	368080e7          	jalr	872(ra) # 401068 <call_sd_write_buf_api>
  401d08:	00050663          	beqz	a0,401d14 <fat32_touch+0x374>
  401d0c:	fff00993          	li	s3,-1
  401d10:	01c0006f          	j	401d2c <fat32_touch+0x38c>
            return -1;

        printf("created: %s\n", name);
  401d14:	00402537          	lui	a0,0x402
  401d18:	21f50513          	addi	a0,a0,543 # 40221f <__modsi3+0x3b3>
  401d1c:	00040593          	mv	a1,s0
  401d20:	fffff097          	auipc	ra,0xfffff
  401d24:	f8c080e7          	jalr	-116(ra) # 400cac <printf>
  401d28:	00000993          	li	s3,0

        return 0;
    }

    return -1;
  401d2c:	00098513          	mv	a0,s3
  401d30:	02c12083          	lw	ra,44(sp)
  401d34:	02812403          	lw	s0,40(sp)
  401d38:	02412483          	lw	s1,36(sp)
  401d3c:	02012903          	lw	s2,32(sp)
  401d40:	01c12983          	lw	s3,28(sp)
  401d44:	01812a03          	lw	s4,24(sp)
  401d48:	03010113          	addi	sp,sp,48
  401d4c:	00008067          	ret

00401d50 <__udivsi3>:
  401d50:	04058a63          	beqz	a1,401da4 <__udivsi3+0x54>
  401d54:	00000813          	li	a6,0
  401d58:	00000613          	li	a2,0
  401d5c:	01f00693          	li	a3,31
  401d60:	00100713          	li	a4,1
  401d64:	fff00793          	li	a5,-1
  401d68:	00181813          	slli	a6,a6,0x1
  401d6c:	00d558b3          	srl	a7,a0,a3
  401d70:	00d712b3          	sll	t0,a4,a3
  401d74:	fff68693          	addi	a3,a3,-1
  401d78:	0018f893          	andi	a7,a7,1
  401d7c:	0108e833          	or	a6,a7,a6
  401d80:	00b838b3          	sltu	a7,a6,a1
  401d84:	fff88893          	addi	a7,a7,-1
  401d88:	0058f2b3          	and	t0,a7,t0
  401d8c:	00b8f8b3          	and	a7,a7,a1
  401d90:	00c2e633          	or	a2,t0,a2
  401d94:	41180833          	sub	a6,a6,a7
  401d98:	fcf698e3          	bne	a3,a5,401d68 <__udivsi3+0x18>
  401d9c:	00060513          	mv	a0,a2
  401da0:	00008067          	ret
  401da4:	00000513          	li	a0,0
  401da8:	00008067          	ret

00401dac <__umodsi3>:
  401dac:	00000613          	li	a2,0
  401db0:	02058a63          	beqz	a1,401de4 <__umodsi3+0x38>
  401db4:	01f00693          	li	a3,31
  401db8:	fff00713          	li	a4,-1
  401dbc:	00161613          	slli	a2,a2,0x1
  401dc0:	00d557b3          	srl	a5,a0,a3
  401dc4:	0017f793          	andi	a5,a5,1
  401dc8:	00c7e633          	or	a2,a5,a2
  401dcc:	00b637b3          	sltu	a5,a2,a1
  401dd0:	fff78793          	addi	a5,a5,-1
  401dd4:	00b7f7b3          	and	a5,a5,a1
  401dd8:	fff68693          	addi	a3,a3,-1
  401ddc:	40f60633          	sub	a2,a2,a5
  401de0:	fce69ee3          	bne	a3,a4,401dbc <__umodsi3+0x10>
  401de4:	00060513          	mv	a0,a2
  401de8:	00008067          	ret

00401dec <__divsi3>:
  401dec:	06058c63          	beqz	a1,401e64 <__divsi3+0x78>
  401df0:	00050613          	mv	a2,a0
  401df4:	00000293          	li	t0,0
  401df8:	00000513          	li	a0,0
  401dfc:	41f65793          	srai	a5,a2,0x1f
  401e00:	41f5d813          	srai	a6,a1,0x1f
  401e04:	01f00693          	li	a3,31
  401e08:	00100713          	li	a4,1
  401e0c:	00f648b3          	xor	a7,a2,a5
  401e10:	40f887b3          	sub	a5,a7,a5
  401e14:	0105c8b3          	xor	a7,a1,a6
  401e18:	41088833          	sub	a6,a7,a6
  401e1c:	fff00893          	li	a7,-1
  401e20:	00129293          	slli	t0,t0,0x1
  401e24:	00d7d333          	srl	t1,a5,a3
  401e28:	00d713b3          	sll	t2,a4,a3
  401e2c:	fff68693          	addi	a3,a3,-1
  401e30:	00137313          	andi	t1,t1,1
  401e34:	005362b3          	or	t0,t1,t0
  401e38:	0102b333          	sltu	t1,t0,a6
  401e3c:	fff30313          	addi	t1,t1,-1
  401e40:	007373b3          	and	t2,t1,t2
  401e44:	01037333          	and	t1,t1,a6
  401e48:	00a3e533          	or	a0,t2,a0
  401e4c:	406282b3          	sub	t0,t0,t1
  401e50:	fd1698e3          	bne	a3,a7,401e20 <__divsi3+0x34>
  401e54:	00c5c5b3          	xor	a1,a1,a2
  401e58:	0005d463          	bgez	a1,401e60 <__divsi3+0x74>
  401e5c:	40a00533          	neg	a0,a0
  401e60:	00008067          	ret
  401e64:	00000513          	li	a0,0
  401e68:	00008067          	ret

00401e6c <__modsi3>:
  401e6c:	06058063          	beqz	a1,401ecc <__modsi3+0x60>
  401e70:	00050613          	mv	a2,a0
  401e74:	00000513          	li	a0,0
  401e78:	41f65693          	srai	a3,a2,0x1f
  401e7c:	41f5d793          	srai	a5,a1,0x1f
  401e80:	00d64733          	xor	a4,a2,a3
  401e84:	40d706b3          	sub	a3,a4,a3
  401e88:	01f00713          	li	a4,31
  401e8c:	00f5c5b3          	xor	a1,a1,a5
  401e90:	40f585b3          	sub	a1,a1,a5
  401e94:	fff00793          	li	a5,-1
  401e98:	00151513          	slli	a0,a0,0x1
  401e9c:	00e6d833          	srl	a6,a3,a4
  401ea0:	00187813          	andi	a6,a6,1
  401ea4:	00a86533          	or	a0,a6,a0
  401ea8:	00b53833          	sltu	a6,a0,a1
  401eac:	fff80813          	addi	a6,a6,-1
  401eb0:	00b87833          	and	a6,a6,a1
  401eb4:	fff70713          	addi	a4,a4,-1
  401eb8:	41050533          	sub	a0,a0,a6
  401ebc:	fcf71ee3          	bne	a4,a5,401e98 <__modsi3+0x2c>
  401ec0:	00065463          	bgez	a2,401ec8 <__modsi3+0x5c>
  401ec4:	40a00533          	neg	a0,a0
  401ec8:	00008067          	ret
  401ecc:	00000513          	li	a0,0
  401ed0:	00008067          	ret

Disassembly of section .rodata:

00401ed4 <.rodata>:
  401ed4:	6c656873          	csrrsi	a6,0x6c6,10
  401ed8:	206c                	.insn	2, 0x206c
  401eda:	72617473          	csrrci	s0,mhpmevent6h,2
  401ede:	2e74                	.insn	2, 0x2e74
  401ee0:	000a                	.insn	2, 0x000a
  401ee2:	20315753          	.insn	4, 0x20315753
  401ee6:	7270                	.insn	2, 0x7270
  401ee8:	7365                	.insn	2, 0x7365
  401eea:	0a646573          	csrrsi	a0,0xa6,8
  401eee:	5300                	.insn	2, 0x5300
  401ef0:	70203257          	.insn	4, 0x70203257
  401ef4:	6572                	.insn	2, 0x6572
  401ef6:	64657373          	csrrci	t1,hviprio1,10
  401efa:	000a                	.insn	2, 0x000a
  401efc:	6568                	.insn	2, 0x6568
  401efe:	6c6c                	.insn	2, 0x6c6c
  401f00:	6548006f          	j	482554 <__user_stack_top+0x5f114>
  401f04:	6c6c                	.insn	2, 0x6c6c
  401f06:	6f77206f          	j	474dfc <__user_stack_top+0x519bc>
  401f0a:	6c72                	.insn	2, 0x6c72
  401f0c:	2064                	.insn	2, 0x2064
  401f0e:	7266                	.insn	2, 0x7266
  401f10:	73206d6f          	jal	s10,408642 <__user_stack_start+0x5202>
  401f14:	6568                	.insn	2, 0x6568
  401f16:	6c6c                	.insn	2, 0x6c6c
  401f18:	0a21                	.insn	2, 0x0a21
  401f1a:	6400                	.insn	2, 0x6400
  401f1c:	6d75                	.insn	2, 0x6d75
  401f1e:	0070                	.insn	2, 0x0070
  401f20:	7270                	.insn	2, 0x7270
  401f22:	6d69                	.insn	2, 0x6d69
  401f24:	7365                	.insn	2, 0x7365
  401f26:	6d00                	.insn	2, 0x6d00
  401f28:	7861                	.insn	2, 0x7861
  401f2a:	7420                	.insn	2, 0x7420
  401f2c:	6c206f6f          	jal	t5,4085ee <__user_stack_start+0x51ae>
  401f30:	7261                	.insn	2, 0x7261
  401f32:	28206567          	.insn	4, 0x28206567
  401f36:	3d3c                	.insn	2, 0x3d3c
  401f38:	3031                	.insn	2, 0x3031
  401f3a:	3030                	.insn	2, 0x3030
  401f3c:	3030                	.insn	2, 0x3030
  401f3e:	0a29                	.insn	2, 0x0a29
  401f40:	7300                	.insn	2, 0x7300
  401f42:	6c65                	.insn	2, 0x6c65
  401f44:	5f66                	.insn	2, 0x5f66
  401f46:	6574                	.insn	2, 0x6574
  401f48:	73007473          	csrrci	s0,mhpmevent16h,0
  401f4c:	5f61                	.insn	2, 0x5f61
  401f4e:	72617473          	csrrci	s0,mhpmevent6h,2
  401f52:	0074                	.insn	2, 0x0074
  401f54:	616d                	.insn	2, 0x616d
  401f56:	7274                	.insn	2, 0x7274
  401f58:	7869                	.insn	2, 0x7869
  401f5a:	7320                	.insn	2, 0x7320
  401f5c:	7a69                	.insn	2, 0x7a69
  401f5e:	2065                	.insn	2, 0x2065
  401f60:	203e                	.insn	2, 0x203e
  401f62:	0a34                	.insn	2, 0x0a34
  401f64:	6d00                	.insn	2, 0x6d00
  401f66:	6369                	.insn	2, 0x6369
  401f68:	725f 6165 0064      	.insn	6, 0x00646165725f
  401f6e:	7375                	.insn	2, 0x7375
  401f70:	6761                	.insn	2, 0x6761
  401f72:	3a65                	.insn	2, 0x3a65
  401f74:	6d20                	.insn	2, 0x6d20
  401f76:	6369                	.insn	2, 0x6369
  401f78:	725f 6165 2064      	.insn	6, 0x20646165725f
  401f7e:	633c                	.insn	2, 0x633c
  401f80:	746e756f          	jal	a0,4e96c6 <__user_stack_top+0xc6286>
  401f84:	0a3e                	.insn	2, 0x0a3e
  401f86:	6d00                	.insn	2, 0x6d00
  401f88:	6369                	.insn	2, 0x6369
  401f8a:	775f 6972 6574      	.insn	6, 0x65746972775f
  401f90:	7500                	.insn	2, 0x7500
  401f92:	65676173          	csrrsi	sp,hviprio1h,14
  401f96:	203a                	.insn	2, 0x203a
  401f98:	696d                	.insn	2, 0x696d
  401f9a:	72775f63          	bge	a4,t2,4026d8 <__user_stack_bottom+0x298>
  401f9e:	7469                	.insn	2, 0x7469
  401fa0:	2065                	.insn	2, 0x2065
  401fa2:	633c                	.insn	2, 0x633c
  401fa4:	746e756f          	jal	a0,4e96ea <__user_stack_top+0xc62aa>
  401fa8:	0a3e                	.insn	2, 0x0a3e
  401faa:	7300                	.insn	2, 0x7300
  401fac:	5f64                	.insn	2, 0x5f64
  401fae:	6572                	.insn	2, 0x6572
  401fb0:	6461                	.insn	2, 0x6461
  401fb2:	7500                	.insn	2, 0x7500
  401fb4:	65676173          	csrrsi	sp,hviprio1h,14
  401fb8:	203a                	.insn	2, 0x203a
  401fba:	725f6473          	csrrsi	s0,mhpmevent5h,30
  401fbe:	6165                	.insn	2, 0x6165
  401fc0:	2064                	.insn	2, 0x2064
  401fc2:	733c                	.insn	2, 0x733c
  401fc4:	6365                	.insn	2, 0x6365
  401fc6:	6f74                	.insn	2, 0x6f74
  401fc8:	3e72                	.insn	2, 0x3e72
  401fca:	000a                	.insn	2, 0x000a
  401fcc:	775f6473          	csrrsi	s0,0x775,30
  401fd0:	6972                	.insn	2, 0x6972
  401fd2:	6574                	.insn	2, 0x6574
  401fd4:	7500                	.insn	2, 0x7500
  401fd6:	65676173          	csrrsi	sp,hviprio1h,14
  401fda:	203a                	.insn	2, 0x203a
  401fdc:	775f6473          	csrrsi	s0,0x775,30
  401fe0:	6972                	.insn	2, 0x6972
  401fe2:	6574                	.insn	2, 0x6574
  401fe4:	3c20                	.insn	2, 0x3c20
  401fe6:	74636573          	csrrsi	a0,0x746,6
  401fea:	0a3e726f          	jal	tp,4e988c <__user_stack_top+0xc644c>
  401fee:	7300                	.insn	2, 0x7300
  401ff0:	5f64                	.insn	2, 0x5f64
  401ff2:	74636573          	csrrsi	a0,0x746,6
  401ff6:	7720726f          	jal	tp,409768 <__user_stack_start+0x6328>
  401ffa:	6972                	.insn	2, 0x6972
  401ffc:	6574                	.insn	2, 0x6574
  401ffe:	7320                	.insn	2, 0x7320
  402000:	6365                	.insn	2, 0x6365
  402002:	6f74                	.insn	2, 0x6f74
  402004:	2072                	.insn	2, 0x2072
  402006:	203c                	.insn	2, 0x203c
  402008:	3035                	.insn	2, 0x3035
  40200a:	3030                	.insn	2, 0x3030
  40200c:	000a                	.insn	2, 0x000a
  40200e:	6166                	.insn	2, 0x6166
  402010:	3374                	.insn	2, 0x3374
  402012:	5f32                	.insn	2, 0x5f32
  402014:	6e69                	.insn	2, 0x6e69
  402016:	6f66                	.insn	2, 0x6f66
  402018:	4600                	.insn	2, 0x4600
  40201a:	5441                	.insn	2, 0x5441
  40201c:	6d203233          	.insn	4, 0x6d203233
  402020:	746e756f          	jal	a0,4e9766 <__user_stack_top+0xc6326>
  402024:	6620                	.insn	2, 0x6620
  402026:	6961                	.insn	2, 0x6961
  402028:	656c                	.insn	2, 0x656c
  40202a:	0a64                	.insn	2, 0x0a64
  40202c:	7000                	.insn	2, 0x7000
  40202e:	7261                	.insn	2, 0x7261
  402030:	5f74                	.insn	2, 0x5f74
  402032:	626c                	.insn	2, 0x626c
  402034:	3d61                	.insn	2, 0x3d61
  402036:	7825                	.insn	2, 0x7825
  402038:	000a                	.insn	2, 0x000a
  40203a:	6f72                	.insn	2, 0x6f72
  40203c:	635f746f          	jal	s0,4f9e70 <__user_stack_top+0xd6a30>
  402040:	756c                	.insn	2, 0x756c
  402042:	72657473          	csrrci	s0,mhpmevent6h,10
  402046:	253d                	.insn	2, 0x253d
  402048:	0a78                	.insn	2, 0x0a78
  40204a:	7300                	.insn	2, 0x7300
  40204c:	6370                	.insn	2, 0x6370
  40204e:	253d                	.insn	2, 0x253d
  402050:	0a78                	.insn	2, 0x0a78
  402052:	6600                	.insn	2, 0x6600
  402054:	7461                	.insn	2, 0x7461
  402056:	625f 6765 6e69      	.insn	6, 0x6e696765625f
  40205c:	253d                	.insn	2, 0x253d
  40205e:	0a78                	.insn	2, 0x0a78
  402060:	6400                	.insn	2, 0x6400
  402062:	7461                	.insn	2, 0x7461
  402064:	5f61                	.insn	2, 0x5f61
  402066:	6562                	.insn	2, 0x6562
  402068:	3d6e6967          	.insn	4, 0x3d6e6967
  40206c:	7825                	.insn	2, 0x7825
  40206e:	000a                	.insn	2, 0x000a
  402070:	6166                	.insn	2, 0x6166
  402072:	3374                	.insn	2, 0x3374
  402074:	5f32                	.insn	2, 0x5f32
  402076:	736c                	.insn	2, 0x736c
  402078:	6600                	.insn	2, 0x6600
  40207a:	7461                	.insn	2, 0x7461
  40207c:	635f3233          	.insn	4, 0x635f3233
  402080:	7461                	.insn	2, 0x7461
  402082:	7500                	.insn	2, 0x7500
  402084:	65676173          	csrrsi	sp,hviprio1h,14
  402088:	203a                	.insn	2, 0x203a
  40208a:	6166                	.insn	2, 0x6166
  40208c:	3374                	.insn	2, 0x3374
  40208e:	5f32                	.insn	2, 0x5f32
  402090:	20746163          	bltu	s0,t2,402292 <fat32_buf+0x52>
  402094:	663c                	.insn	2, 0x663c
  402096:	6c69                	.insn	2, 0x6c69
  402098:	3e65                	.insn	2, 0x3e65
  40209a:	000a                	.insn	2, 0x000a
  40209c:	6166                	.insn	2, 0x6166
  40209e:	3374                	.insn	2, 0x3374
  4020a0:	5f32                	.insn	2, 0x5f32
  4020a2:	6f74                	.insn	2, 0x6f74
  4020a4:	6375                	.insn	2, 0x6375
  4020a6:	0068                	.insn	2, 0x0068
  4020a8:	7375                	.insn	2, 0x7375
  4020aa:	6761                	.insn	2, 0x6761
  4020ac:	3a65                	.insn	2, 0x3a65
  4020ae:	6620                	.insn	2, 0x6620
  4020b0:	7461                	.insn	2, 0x7461
  4020b2:	745f3233          	.insn	4, 0x745f3233
  4020b6:	6863756f          	jal	a0,43973c <__user_stack_top+0x162fc>
  4020ba:	3c20                	.insn	2, 0x3c20
  4020bc:	6966                	.insn	2, 0x6966
  4020be:	656c                	.insn	2, 0x656c
  4020c0:	0a3e                	.insn	2, 0x0a3e
  4020c2:	6600                	.insn	2, 0x6600
  4020c4:	7461                	.insn	2, 0x7461
  4020c6:	745f3233          	.insn	4, 0x745f3233
  4020ca:	6863756f          	jal	a0,439750 <__user_stack_top+0x16310>
  4020ce:	6620                	.insn	2, 0x6620
  4020d0:	6961                	.insn	2, 0x6961
  4020d2:	656c                	.insn	2, 0x656c
  4020d4:	0a64                	.insn	2, 0x0a64
  4020d6:	7300                	.insn	2, 0x7300
  4020d8:	6570                	.insn	2, 0x6570
  4020da:	6365                	.insn	2, 0x6365
  4020dc:	0068                	.insn	2, 0x0068
  4020de:	6568                	.insn	2, 0x6568
  4020e0:	706c                	.insn	2, 0x706c
  4020e2:	6300                	.insn	2, 0x6300
  4020e4:	616d6d6f          	jal	s10,4d86fa <__user_stack_top+0xb52ba>
  4020e8:	646e                	.insn	2, 0x646e
  4020ea:	000a3a73          	csrrc	s4,0x0,s4
  4020ee:	7865                	.insn	2, 0x7865
  4020f0:	7469                	.insn	2, 0x7469
  4020f2:	7100                	.insn	2, 0x7100
  4020f4:	6975                	.insn	2, 0x6975
  4020f6:	0074                	.insn	2, 0x0074
  4020f8:	0071                	.insn	2, 0x0071
  4020fa:	6e75                	.insn	2, 0x6e75
  4020fc:	776f6e6b          	.insn	4, 0x776f6e6b
  402100:	206e                	.insn	2, 0x206e
  402102:	6d6d6f63          	bltu	s10,s6,4027e0 <__user_stack_bottom+0x3a0>
  402106:	6e61                	.insn	2, 0x6e61
  402108:	3a64                	.insn	2, 0x3a64
  40210a:	2520                	.insn	2, 0x2520
  40210c:	25000a73          	.insn	4, 0x25000a73
  402110:	2064                	.insn	2, 0x2064
  402112:	7400                	.insn	2, 0x7400
  402114:	6c61746f          	jal	s0,4197da <__user_stack_start+0x1639a>
  402118:	7020                	.insn	2, 0x7020
  40211a:	6972                	.insn	2, 0x6972
  40211c:	656d                	.insn	2, 0x656d
  40211e:	25203a73          	csrrc	s4,vsireg2,zero
  402122:	2064                	.insn	2, 0x2064
  402124:	3028                	.insn	2, 0x3028
  402126:	2e2e                	.insn	2, 0x2e2e
  402128:	6425                	.insn	2, 0x6425
  40212a:	0a29                	.insn	2, 0x0a29
  40212c:	6900                	.insn	2, 0x6900
  40212e:	766e                	.insn	2, 0x766e
  402130:	6c61                	.insn	2, 0x6c61
  402132:	6469                	.insn	2, 0x6469
  402134:	6d20                	.insn	2, 0x6d20
  402136:	7461                	.insn	2, 0x7461
  402138:	6972                	.insn	2, 0x6972
  40213a:	2078                	.insn	2, 0x2078
  40213c:	657a6973          	csrrsi	s2,hviprio2h,20
  402140:	000a                	.insn	2, 0x000a
  402142:	494d                	.insn	2, 0x494d
  402144:	58542e43          	.insn	4, 0x58542e43
  402148:	0054                	.insn	2, 0x0054
  40214a:	494d                	.insn	2, 0x494d
  40214c:	58542e43          	.insn	4, 0x58542e43
  402150:	2054                	.insn	2, 0x2054
  402152:	6f6e                	.insn	2, 0x6f6e
  402154:	2074                	.insn	2, 0x2074
  402156:	6f66                	.insn	2, 0x6f66
  402158:	6e75                	.insn	2, 0x6e75
  40215a:	0a64                	.insn	2, 0x0a64
  40215c:	4d00                	.insn	2, 0x4d00
  40215e:	4349                	.insn	2, 0x4349
  402160:	542e                	.insn	2, 0x542e
  402162:	5458                	.insn	2, 0x5458
  402164:	6820                	.insn	2, 0x6820
  402166:	7361                	.insn	2, 0x7361
  402168:	6e20                	.insn	2, 0x6e20
  40216a:	6c63206f          	j	434830 <__user_stack_top+0x113f0>
  40216e:	7375                	.insn	2, 0x7375
  402170:	6574                	.insn	2, 0x6574
  402172:	0a72                	.insn	2, 0x0a72
  402174:	4d00                	.insn	2, 0x4d00
  402176:	4349                	.insn	2, 0x4349
  402178:	542e                	.insn	2, 0x542e
  40217a:	5458                	.insn	2, 0x5458
  40217c:	6320                	.insn	2, 0x6320
  40217e:	3d6c                	.insn	2, 0x3d6c
  402180:	7825                	.insn	2, 0x7825
  402182:	6c20                	.insn	2, 0x6c20
  402184:	6162                	.insn	2, 0x6162
  402186:	253d                	.insn	2, 0x253d
  402188:	2078                	.insn	2, 0x2078
  40218a:	657a6973          	csrrsi	s2,hviprio2h,20
  40218e:	253d                	.insn	2, 0x253d
  402190:	0a78                	.insn	2, 0x0a78
  402192:	5300                	.insn	2, 0x5300
  402194:	6570                	.insn	2, 0x6570
  402196:	6365                	.insn	2, 0x6365
  402198:	2068                	.insn	2, 0x2068
  40219a:	6572                	.insn	2, 0x6572
  40219c:	6e676f63          	bltu	a4,t1,40289a <__user_stack_bottom+0x45a>
  4021a0:	7469                	.insn	2, 0x7469
  4021a2:	6f69                	.insn	2, 0x6f69
  4021a4:	206e                	.insn	2, 0x206e
  4021a6:	72617473          	csrrci	s0,mhpmevent6h,2
  4021aa:	0a74                	.insn	2, 0x0a74
  4021ac:	5200                	.insn	2, 0x5200
  4021ae:	5345                	.insn	2, 0x5345
  4021b0:	4c55                	.insn	2, 0x4c55
  4021b2:	3a54                	.insn	2, 0x3a54
  4021b4:	5520                	.insn	2, 0x5520
  4021b6:	0a50                	.insn	2, 0x0a50
  4021b8:	5200                	.insn	2, 0x5200
  4021ba:	5345                	.insn	2, 0x5345
  4021bc:	4c55                	.insn	2, 0x4c55
  4021be:	3a54                	.insn	2, 0x3a54
  4021c0:	4420                	.insn	2, 0x4420
  4021c2:	0a4e574f          	.insn	4, 0x0a4e574f
  4021c6:	5200                	.insn	2, 0x5200
  4021c8:	5345                	.insn	2, 0x5345
  4021ca:	4c55                	.insn	2, 0x4c55
  4021cc:	3a54                	.insn	2, 0x3a54
  4021ce:	5520                	.insn	2, 0x5520
  4021d0:	4b4e                	.insn	2, 0x4b4e
  4021d2:	4f4e                	.insn	2, 0x4f4e
  4021d4:	000a4e57          	.insn	4, 0x000a4e57
  4021d8:	4552                	.insn	2, 0x4552
  4021da:	544c5553          	.insn	4, 0x544c5553
  4021de:	203a                	.insn	2, 0x203a
  4021e0:	5245                	.insn	2, 0x5245
  4021e2:	4f52                	.insn	2, 0x4f52
  4021e4:	2052                	.insn	2, 0x2052
  4021e6:	6425                	.insn	2, 0x6425
  4021e8:	000a                	.insn	2, 0x000a
  4021ea:	3130                	.insn	2, 0x3130
  4021ec:	3332                	.insn	2, 0x3332
  4021ee:	3534                	.insn	2, 0x3534
  4021f0:	3736                	.insn	2, 0x3736
  4021f2:	3938                	.insn	2, 0x3938
  4021f4:	6261                	.insn	2, 0x6261
  4021f6:	66656463          	bltu	a0,t1,40285e <__user_stack_bottom+0x41e>
  4021fa:	6600                	.insn	2, 0x6600
  4021fc:	6c69                	.insn	2, 0x6c69
  4021fe:	2065                	.insn	2, 0x2065
  402200:	6f6e                	.insn	2, 0x6f6e
  402202:	2074                	.insn	2, 0x2074
  402204:	6f66                	.insn	2, 0x6f66
  402206:	6e75                	.insn	2, 0x6e75
  402208:	0a64                	.insn	2, 0x0a64
  40220a:	2000                	.insn	2, 0x2000
  40220c:	7461                	.insn	2, 0x7461
  40220e:	7274                	.insn	2, 0x7274
  402210:	253d                	.insn	2, 0x253d
  402212:	0078                	.insn	2, 0x0078
  402214:	5355                	.insn	2, 0x5355
  402216:	5245                	.insn	2, 0x5245
  402218:	4220                	.insn	2, 0x4220
  40221a:	4655                	.insn	2, 0x4655
  40221c:	203a                	.insn	2, 0x203a
  40221e:	6300                	.insn	2, 0x6300
  402220:	6572                	.insn	2, 0x6572
  402222:	7461                	.insn	2, 0x7461
  402224:	6465                	.insn	2, 0x6465
  402226:	203a                	.insn	2, 0x203a
  402228:	7325                	.insn	2, 0x7325
  40222a:	000a                	.insn	2, 0x000a

Disassembly of section .debug_loclists:

00000000 <.debug_loclists>:
   0:	000003b7          	lui	t2,0x0
   4:	0005                	.insn	2, 0x0005
   6:	0004                	.insn	2, 0x0004
   8:	001e                	.insn	2, 0x001e
   a:	0000                	.insn	2, 0x0000
   c:	0078                	.insn	2, 0x0078
   e:	0000                	.insn	2, 0x0000
  10:	009c                	.insn	2, 0x009c
  12:	0000                	.insn	2, 0x0000
  14:	00dc                	.insn	2, 0x00dc
  16:	0000                	.insn	2, 0x0000
  18:	00ed                	.insn	2, 0x00ed
  1a:	0000                	.insn	2, 0x0000
  1c:	00000103          	lb	sp,0(zero) # 0 <start-0x400000>
  20:	0112                	.insn	2, 0x0112
  22:	0000                	.insn	2, 0x0000
  24:	0126                	.insn	2, 0x0126
  26:	0000                	.insn	2, 0x0000
  28:	013e                	.insn	2, 0x013e
  2a:	0000                	.insn	2, 0x0000
  2c:	017f 0000 01d1 0000 	.insn	10, 0x0207000001d10000017f
  34:	0207 
  36:	0000                	.insn	2, 0x0000
  38:	022e                	.insn	2, 0x022e
  3a:	0000                	.insn	2, 0x0000
  3c:	00000247          	.insn	4, 0x0247
  40:	027d                	.insn	2, 0x027d
  42:	0000                	.insn	2, 0x0000
  44:	02a4                	.insn	2, 0x02a4
  46:	0000                	.insn	2, 0x0000
  48:	000002bb          	.insn	4, 0x02bb
  4c:	000002c3          	.insn	4, 0x02c3
  50:	02d2                	.insn	2, 0x02d2
  52:	0000                	.insn	2, 0x0000
  54:	02da                	.insn	2, 0x02da
  56:	0000                	.insn	2, 0x0000
  58:	02e2                	.insn	2, 0x02e2
  5a:	0000                	.insn	2, 0x0000
  5c:	02ea                	.insn	2, 0x02ea
  5e:	0000                	.insn	2, 0x0000
  60:	02f9                	.insn	2, 0x02f9
  62:	0000                	.insn	2, 0x0000
  64:	0301                	.insn	2, 0x0301
  66:	0000                	.insn	2, 0x0000
  68:	0309                	.insn	2, 0x0309
  6a:	0000                	.insn	2, 0x0000
  6c:	0351                	.insn	2, 0x0351
  6e:	0000                	.insn	2, 0x0000
  70:	0368                	.insn	2, 0x0368
  72:	0000                	.insn	2, 0x0000
  74:	00000377          	.insn	4, 0x0377
  78:	037f 0000 038e 0000 	.insn	10, 0x039f0000038e0000037f
  80:	039f 
  82:	0000                	.insn	2, 0x0000
  84:	5404                	.insn	2, 0x5404
  86:	0194                	.insn	2, 0x0194
  88:	3002                	.insn	2, 0x3002
  8a:	049f 0194 01a8      	.insn	6, 0x01a80194049f
  90:	6201                	.insn	2, 0x6201
  92:	8404                	.insn	2, 0x8404
  94:	01039003          	lh	zero,16(t2) # 10 <start-0x3ffff0>
  98:	0462                	.insn	2, 0x0462
  9a:	0390                	.insn	2, 0x0390
  9c:	03d8                	.insn	2, 0x03d8
  9e:	6b01                	.insn	2, 0x6b01
  a0:	d804                	.insn	2, 0xd804
  a2:	01119403          	lh	s0,17(gp)
  a6:	0062                	.insn	2, 0x0062
  a8:	9404                	.insn	2, 0x9404
  aa:	a801                	.insn	2, 0xa801
  ac:	0101                	.insn	2, 0x0101
  ae:	0465                	.insn	2, 0x0465
  b0:	05a0                	.insn	2, 0x05a0
  b2:	05a4                	.insn	2, 0x05a4
  b4:	6401                	.insn	2, 0x6401
  b6:	a404                	.insn	2, 0xa404
  b8:	c405                	.insn	2, 0xc405
  ba:	0106                	.insn	2, 0x0106
  bc:	0465                	.insn	2, 0x0465
  be:	09c8                	.insn	2, 0x09c8
  c0:	0a98                	.insn	2, 0x0a98
  c2:	6501                	.insn	2, 0x6501
  c4:	c004                	.insn	2, 0xc004
  c6:	c80a                	.insn	2, 0xc80a
  c8:	010a                	.insn	2, 0x010a
  ca:	0465                	.insn	2, 0x0465
  cc:	0ad4                	.insn	2, 0x0ad4
  ce:	0aec                	.insn	2, 0x0aec
  d0:	6501                	.insn	2, 0x6501
  d2:	f804                	.insn	2, 0xf804
  d4:	ac0a                	.insn	2, 0xac0a
  d6:	0465010b          	.insn	4, 0x0465010b
  da:	0bf8                	.insn	2, 0x0bf8
  dc:	0c80                	.insn	2, 0x0c80
  de:	6501                	.insn	2, 0x6501
  e0:	b404                	.insn	2, 0xb404
  e2:	8c0c                	.insn	2, 0x8c0c
  e4:	010d                	.insn	2, 0x010d
  e6:	0065                	.insn	2, 0x0065
  e8:	ec04                	.insn	2, 0xec04
  ea:	f002                	.insn	2, 0xf002
  ec:	0302                	.insn	2, 0x0302
  ee:	0011                	.insn	2, 0x0011
  f0:	049f 0384 0598      	.insn	6, 0x05980384049f
  f6:	6401                	.insn	2, 0x6401
  f8:	0400                	.insn	2, 0x0400
  fa:	0384                	.insn	2, 0x0384
  fc:	0390                	.insn	2, 0x0390
  fe:	5a01                	.insn	2, 0x5a01
 100:	e004                	.insn	2, 0xe004
 102:	0104b803          	.insn	4, 0x0104b803
 106:	045a                	.insn	2, 0x045a
 108:	04d4                	.insn	2, 0x04d4
 10a:	04d8                	.insn	2, 0x04d8
 10c:	5a01                	.insn	2, 0x5a01
 10e:	0400                	.insn	2, 0x0400
 110:	0384                	.insn	2, 0x0384
 112:	0390                	.insn	2, 0x0390
 114:	6201                	.insn	2, 0x6201
 116:	a004                	.insn	2, 0xa004
 118:	0104f003          	.insn	4, 0x0104f003
 11c:	0062                	.insn	2, 0x0062
 11e:	c804                	.insn	2, 0xc804
 120:	0d03d003          	lhu	zero,208(t2)
 124:	007a                	.insn	2, 0x007a
 126:	aba8                	.insn	2, 0xaba8
 128:	8080                	.insn	2, 0x8080
 12a:	a800                	.insn	2, 0xa800
 12c:	008080af          	.insn	4, 0x008080af
 130:	009f f804 9804      	.insn	6, 0x9804f804009f
 136:	0105                	.insn	2, 0x0105
 138:	045a                	.insn	2, 0x045a
 13a:	05a0                	.insn	2, 0x05a0
 13c:	05d8                	.insn	2, 0x05d8
 13e:	5b01                	.insn	2, 0x5b01
 140:	d804                	.insn	2, 0xd804
 142:	e005                	.insn	2, 0xe005
 144:	0305                	.insn	2, 0x0305
 146:	009f017b          	.insn	4, 0x009f017b
 14a:	c804                	.insn	2, 0xc804
 14c:	9809                	.insn	2, 0x9809
 14e:	060a                	.insn	2, 0x060a
 150:	8010                	.insn	2, 0x8010
 152:	8080                	.insn	2, 0x8080
 154:	9f01                	.insn	2, 0x9f01
 156:	c004                	.insn	2, 0xc004
 158:	e00a                	.insn	2, 0xe00a
 15a:	060a                	.insn	2, 0x060a
 15c:	8010                	.insn	2, 0x8010
 15e:	8080                	.insn	2, 0x8080
 160:	9f01                	.insn	2, 0x9f01
 162:	e004                	.insn	2, 0xe004
 164:	f40a                	.insn	2, 0xf40a
 166:	010a                	.insn	2, 0x010a
 168:	045a                	.insn	2, 0x045a
 16a:	0af8                	.insn	2, 0x0af8
 16c:	0bbc                	.insn	2, 0x0bbc
 16e:	5a01                	.insn	2, 0x5a01
 170:	f804                	.insn	2, 0xf804
 172:	010c8c0b          	.insn	4, 0x010c8c0b
 176:	045a                	.insn	2, 0x045a
 178:	0cbc                	.insn	2, 0x0cbc
 17a:	0d84                	.insn	2, 0x0d84
 17c:	1006                	.insn	2, 0x1006
 17e:	8080                	.insn	2, 0x8080
 180:	0180                	.insn	2, 0x0180
 182:	049f 0df0 0eb8      	.insn	6, 0x0eb80df0049f
 188:	5a01                	.insn	2, 0x5a01
 18a:	0400                	.insn	2, 0x0400
 18c:	09c8                	.insn	2, 0x09c8
 18e:	0a98                	.insn	2, 0x0a98
 190:	1004                	.insn	2, 0x1004
 192:	0280                	.insn	2, 0x0280
 194:	049f 0ac8 0ad0      	.insn	6, 0x0ad00ac8049f
 19a:	5b01                	.insn	2, 0x5b01
 19c:	d404                	.insn	2, 0xd404
 19e:	ec0a                	.insn	2, 0xec0a
 1a0:	040a                	.insn	2, 0x040a
 1a2:	8010                	.insn	2, 0x8010
 1a4:	9f02                	.insn	2, 0x9f02
 1a6:	ec04                	.insn	2, 0xec04
 1a8:	f40a                	.insn	2, 0xf40a
 1aa:	010a                	.insn	2, 0x010a
 1ac:	0af8045b          	.insn	4, 0x0af8045b
 1b0:	0bbc                	.insn	2, 0x0bbc
 1b2:	1004                	.insn	2, 0x1004
 1b4:	0280                	.insn	2, 0x0280
 1b6:	049f 0bf8 0c84      	.insn	6, 0x0c840bf8049f
 1bc:	1004                	.insn	2, 0x1004
 1be:	0280                	.insn	2, 0x0280
 1c0:	049f 0c84 0c8c      	.insn	6, 0x0c8c0c84049f
 1c6:	5b01                	.insn	2, 0x5b01
 1c8:	bc04                	.insn	2, 0xbc04
 1ca:	840c                	.insn	2, 0x840c
 1cc:	040d                	.insn	2, 0x040d
 1ce:	8010                	.insn	2, 0x8010
 1d0:	9f02                	.insn	2, 0x9f02
 1d2:	f004                	.insn	2, 0xf004
 1d4:	b80d                	.insn	2, 0xb80d
 1d6:	040e                	.insn	2, 0x040e
 1d8:	8010                	.insn	2, 0x8010
 1da:	9f02                	.insn	2, 0x9f02
 1dc:	0400                	.insn	2, 0x0400
 1de:	09d4                	.insn	2, 0x09d4
 1e0:	09d8                	.insn	2, 0x09d8
 1e2:	5d01                	.insn	2, 0x5d01
 1e4:	e404                	.insn	2, 0xe404
 1e6:	e809                	.insn	2, 0xe809
 1e8:	0309                	.insn	2, 0x0309
 1ea:	7f7d                	.insn	2, 0x7f7d
 1ec:	049f 09e8 0a8c      	.insn	6, 0x0a8c09e8049f
 1f2:	9f7e7d03          	.insn	4, 0x9f7e7d03
 1f6:	9004                	.insn	2, 0x9004
 1f8:	980a                	.insn	2, 0x980a
 1fa:	010a                	.insn	2, 0x010a
 1fc:	045d                	.insn	2, 0x045d
 1fe:	0ad8                	.insn	2, 0x0ad8
 200:	0adc                	.insn	2, 0x0adc
 202:	5d01                	.insn	2, 0x5d01
 204:	c804                	.insn	2, 0xc804
 206:	e00c                	.insn	2, 0xe00c
 208:	010c                	.insn	2, 0x010c
 20a:	045d                	.insn	2, 0x045d
 20c:	0ce4                	.insn	2, 0x0ce4
 20e:	0d84                	.insn	2, 0x0d84
 210:	5d01                	.insn	2, 0x5d01
 212:	0400                	.insn	2, 0x0400
 214:	09d4                	.insn	2, 0x09d4
 216:	0a98                	.insn	2, 0x0a98
 218:	3002                	.insn	2, 0x3002
 21a:	049f 0ad4 0adc      	.insn	6, 0x0adc0ad4049f
 220:	3002                	.insn	2, 0x3002
 222:	049f 0cbc 0cc8      	.insn	6, 0x0cc80cbc049f
 228:	3002                	.insn	2, 0x3002
 22a:	049f 0cc8 0cd8      	.insn	6, 0x0cd80cc8049f
 230:	5a01                	.insn	2, 0x5a01
 232:	dc04                	.insn	2, 0xdc04
 234:	840c                	.insn	2, 0x840c
 236:	010d                	.insn	2, 0x010d
 238:	005a                	.insn	2, 0x005a
 23a:	9804                	.insn	2, 0x9804
 23c:	ac0a                	.insn	2, 0xac0a
 23e:	040a                	.insn	2, 0x040a
 240:	e810                	.insn	2, 0xe810
 242:	ac049f07          	.insn	4, 0xac049f07
 246:	c00a                	.insn	2, 0xc00a
 248:	010a                	.insn	2, 0x010a
 24a:	0be8045b          	.insn	4, 0x0be8045b
 24e:	0bf4                	.insn	2, 0x0bf4
 250:	5b01                	.insn	2, 0x5b01
 252:	0400                	.insn	2, 0x0400
 254:	0afc                	.insn	2, 0x0afc
 256:	0b80                	.insn	2, 0x0b80
 258:	5d01                	.insn	2, 0x5d01
 25a:	8404                	.insn	2, 0x8404
 25c:	030b880b          	.insn	4, 0x030b880b
 260:	7f7d                	.insn	2, 0x7f7d
 262:	049f 0b88 0bb0      	.insn	6, 0x0bb00b88049f
 268:	9f7e7d03          	.insn	4, 0x9f7e7d03
 26c:	b404                	.insn	2, 0xb404
 26e:	010bbc0b          	.insn	4, 0x010bbc0b
 272:	045d                	.insn	2, 0x045d
 274:	0c80                	.insn	2, 0x0c80
 276:	0c84                	.insn	2, 0x0c84
 278:	5d01                	.insn	2, 0x5d01
 27a:	fc04                	.insn	2, 0xfc04
 27c:	940d                	.insn	2, 0x940d
 27e:	010e                	.insn	2, 0x010e
 280:	045d                	.insn	2, 0x045d
 282:	0e98                	.insn	2, 0x0e98
 284:	0eb8                	.insn	2, 0x0eb8
 286:	5d01                	.insn	2, 0x5d01
 288:	0400                	.insn	2, 0x0400
 28a:	0afc                	.insn	2, 0x0afc
 28c:	0bbc                	.insn	2, 0x0bbc
 28e:	3002                	.insn	2, 0x3002
 290:	049f 0bf8 0c84      	.insn	6, 0x0c840bf8049f
 296:	3002                	.insn	2, 0x3002
 298:	049f 0df0 0dfc      	.insn	6, 0x0dfc0df0049f
 29e:	3002                	.insn	2, 0x3002
 2a0:	049f 0dfc 0e8c      	.insn	6, 0x0e8c0dfc049f
 2a6:	5b01                	.insn	2, 0x5b01
 2a8:	9004                	.insn	2, 0x9004
 2aa:	b80e                	.insn	2, 0xb80e
 2ac:	010e                	.insn	2, 0x010e
 2ae:	bc04005b          	.insn	4, 0xbc04005b
 2b2:	020bd00b          	.insn	4, 0x020bd00b
 2b6:	9f34                	.insn	2, 0x9f34
 2b8:	d004                	.insn	2, 0xd004
 2ba:	010be40b          	.insn	4, 0x010be40b
 2be:	0db4045b          	.insn	4, 0x0db4045b
 2c2:	0dc0                	.insn	2, 0x0dc0
 2c4:	5b01                	.insn	2, 0x5b01
 2c6:	0400                	.insn	2, 0x0400
 2c8:	0ca8                	.insn	2, 0x0ca8
 2ca:	0cb0                	.insn	2, 0x0cb0
 2cc:	5a01                	.insn	2, 0x5a01
 2ce:	0400                	.insn	2, 0x0400
 2d0:	0cc8                	.insn	2, 0x0cc8
 2d2:	0cd4                	.insn	2, 0x0cd4
 2d4:	5c01                	.insn	2, 0x5c01
 2d6:	e404                	.insn	2, 0xe404
 2d8:	840c                	.insn	2, 0x840c
 2da:	010d                	.insn	2, 0x010d
 2dc:	005c                	.insn	2, 0x005c
 2de:	d004                	.insn	2, 0xd004
 2e0:	e40c                	.insn	2, 0xe40c
 2e2:	010c                	.insn	2, 0x010c
 2e4:	005e                	.insn	2, 0x005e
 2e6:	a404                	.insn	2, 0xa404
 2e8:	ac0d                	.insn	2, 0xac0d
 2ea:	010d                	.insn	2, 0x010d
 2ec:	005a                	.insn	2, 0x005a
 2ee:	dc04                	.insn	2, 0xdc04
 2f0:	e40d                	.insn	2, 0xe40d
 2f2:	010d                	.insn	2, 0x010d
 2f4:	005a                	.insn	2, 0x005a
 2f6:	fc04                	.insn	2, 0xfc04
 2f8:	880d                	.insn	2, 0x880d
 2fa:	010e                	.insn	2, 0x010e
 2fc:	045c                	.insn	2, 0x045c
 2fe:	0e98                	.insn	2, 0x0e98
 300:	0eb8                	.insn	2, 0x0eb8
 302:	5c01                	.insn	2, 0x5c01
 304:	0400                	.insn	2, 0x0400
 306:	0e84                	.insn	2, 0x0e84
 308:	0e98                	.insn	2, 0x0e98
 30a:	5e01                	.insn	2, 0x5e01
 30c:	0400                	.insn	2, 0x0400
 30e:	0edc                	.insn	2, 0x0edc
 310:	0efc                	.insn	2, 0x0efc
 312:	5b01                	.insn	2, 0x5b01
 314:	0400                	.insn	2, 0x0400
 316:	1194                	.insn	2, 0x1194
 318:	11a4                	.insn	2, 0x11a4
 31a:	5a01                	.insn	2, 0x5a01
 31c:	a404                	.insn	2, 0xa404
 31e:	a811                	.insn	2, 0xa811
 320:	0311                	.insn	2, 0x0311
 322:	7f7d                	.insn	2, 0x7f7d
 324:	049f 11a8 11cc      	.insn	6, 0x11cc11a8049f
 32a:	9f7e7d03          	.insn	4, 0x9f7e7d03
 32e:	d004                	.insn	2, 0xd004
 330:	d811                	.insn	2, 0xd811
 332:	0111                	.insn	2, 0x0111
 334:	045d                	.insn	2, 0x045d
 336:	11d8                	.insn	2, 0x11d8
 338:	11dc                	.insn	2, 0x11dc
 33a:	9f7e7d03          	.insn	4, 0x9f7e7d03
 33e:	dc04                	.insn	2, 0xdc04
 340:	e811                	.insn	2, 0xe811
 342:	0111                	.insn	2, 0x0111
 344:	045d                	.insn	2, 0x045d
 346:	11e8                	.insn	2, 0x11e8
 348:	11ec                	.insn	2, 0x11ec
 34a:	9f7e7d03          	.insn	4, 0x9f7e7d03
 34e:	8804                	.insn	2, 0x8804
 350:	a012                	.insn	2, 0xa012
 352:	0112                	.insn	2, 0x0112
 354:	045d                	.insn	2, 0x045d
 356:	12a4                	.insn	2, 0x12a4
 358:	12cc                	.insn	2, 0x12cc
 35a:	5d01                	.insn	2, 0x5d01
 35c:	0400                	.insn	2, 0x0400
 35e:	1194                	.insn	2, 0x1194
 360:	1288                	.insn	2, 0x1288
 362:	3002                	.insn	2, 0x3002
 364:	049f 1288 1298      	.insn	6, 0x12981288049f
 36a:	5c01                	.insn	2, 0x5c01
 36c:	9c04                	.insn	2, 0x9c04
 36e:	d812                	.insn	2, 0xd812
 370:	0112                	.insn	2, 0x0112
 372:	005c                	.insn	2, 0x005c
 374:	8804                	.insn	2, 0x8804
 376:	9412                	.insn	2, 0x9412
 378:	0112                	.insn	2, 0x0112
 37a:	045a                	.insn	2, 0x045a
 37c:	12a4                	.insn	2, 0x12a4
 37e:	12c4                	.insn	2, 0x12c4
 380:	5a01                	.insn	2, 0x5a01
 382:	0400                	.insn	2, 0x0400
 384:	1290                	.insn	2, 0x1290
 386:	12a4                	.insn	2, 0x12a4
 388:	6101                	.insn	2, 0x6101
 38a:	0400                	.insn	2, 0x0400
 38c:	12d8                	.insn	2, 0x12d8
 38e:	12f8                	.insn	2, 0x12f8
 390:	5a01                	.insn	2, 0x5a01
 392:	f804                	.insn	2, 0xf804
 394:	fc12                	.insn	2, 0xfc12
 396:	00580113          	addi	sp,a6,5
 39a:	f804                	.insn	2, 0xf804
 39c:	8c12                	.insn	2, 0x8c12
 39e:	00110313          	addi	t1,sp,1
 3a2:	049f 138c 13e4      	.insn	6, 0x13e4138c049f
 3a8:	5901                	.insn	2, 0x5901
 3aa:	0400                	.insn	2, 0x0400
 3ac:	12f8                	.insn	2, 0x12f8
 3ae:	138c                	.insn	2, 0x138c
 3b0:	3202                	.insn	2, 0x3202
 3b2:	049f 138c 13d0      	.insn	6, 0x13d0138c049f
 3b8:	6201                	.insn	2, 0x6201
 3ba:	4600                	.insn	2, 0x4600
 3bc:	0004                	.insn	2, 0x0004
 3be:	0500                	.insn	2, 0x0500
 3c0:	0400                	.insn	2, 0x0400
 3c2:	2e00                	.insn	2, 0x2e00
 3c4:	0000                	.insn	2, 0x0000
 3c6:	b800                	.insn	2, 0xb800
 3c8:	0000                	.insn	2, 0x0000
 3ca:	c000                	.insn	2, 0xc000
 3cc:	0000                	.insn	2, 0x0000
 3ce:	ce00                	.insn	2, 0xce00
 3d0:	0000                	.insn	2, 0x0000
 3d2:	d700                	.insn	2, 0xd700
 3d4:	0000                	.insn	2, 0x0000
 3d6:	e000                	.insn	2, 0xe000
 3d8:	0000                	.insn	2, 0x0000
 3da:	ed00                	.insn	2, 0xed00
 3dc:	0000                	.insn	2, 0x0000
 3de:	f700                	.insn	2, 0xf700
 3e0:	0000                	.insn	2, 0x0000
 3e2:	0200                	.insn	2, 0x0200
 3e4:	0001                	.insn	2, 0x0001
 3e6:	0c00                	.insn	2, 0x0c00
 3e8:	0001                	.insn	2, 0x0001
 3ea:	1700                	.insn	2, 0x1700
 3ec:	0001                	.insn	2, 0x0001
 3ee:	2100                	.insn	2, 0x2100
 3f0:	0001                	.insn	2, 0x0001
 3f2:	2c00                	.insn	2, 0x2c00
 3f4:	0001                	.insn	2, 0x0001
 3f6:	3d00                	.insn	2, 0x3d00
 3f8:	0001                	.insn	2, 0x0001
 3fa:	4e00                	.insn	2, 0x4e00
 3fc:	0001                	.insn	2, 0x0001
 3fe:	6d00                	.insn	2, 0x6d00
 400:	0001                	.insn	2, 0x0001
 402:	9000                	.insn	2, 0x9000
 404:	0001                	.insn	2, 0x0001
 406:	9a00                	.insn	2, 0x9a00
 408:	0001                	.insn	2, 0x0001
 40a:	ee00                	.insn	2, 0xee00
 40c:	0001                	.insn	2, 0x0001
 40e:	2900                	.insn	2, 0x2900
 410:	0002                	.insn	2, 0x0002
 412:	4300                	.insn	2, 0x4300
 414:	0002                	.insn	2, 0x0002
 416:	5400                	.insn	2, 0x5400
 418:	0002                	.insn	2, 0x0002
 41a:	6500                	.insn	2, 0x6500
 41c:	0002                	.insn	2, 0x0002
 41e:	6f00                	.insn	2, 0x6f00
 420:	0002                	.insn	2, 0x0002
 422:	8700                	.insn	2, 0x8700
 424:	0002                	.insn	2, 0x0002
 426:	9100                	.insn	2, 0x9100
 428:	0002                	.insn	2, 0x0002
 42a:	a200                	.insn	2, 0xa200
 42c:	0002                	.insn	2, 0x0002
 42e:	ac00                	.insn	2, 0xac00
 430:	0002                	.insn	2, 0x0002
 432:	b600                	.insn	2, 0xb600
 434:	0002                	.insn	2, 0x0002
 436:	c000                	.insn	2, 0xc000
 438:	0002                	.insn	2, 0x0002
 43a:	ca00                	.insn	2, 0xca00
 43c:	0002                	.insn	2, 0x0002
 43e:	dc00                	.insn	2, 0xdc00
 440:	0002                	.insn	2, 0x0002
 442:	fb00                	.insn	2, 0xfb00
 444:	0002                	.insn	2, 0x0002
 446:	0d00                	.insn	2, 0x0d00
 448:	1e000003          	lb	zero,480(zero) # 1e0 <start-0x3ffe20>
 44c:	36000003          	lb	zero,864(zero) # 360 <start-0x3ffca0>
 450:	50000003          	lb	zero,1280(zero) # 500 <start-0x3ffb00>
 454:	68000003          	lb	zero,1664(zero) # 680 <start-0x3ff980>
 458:	99000003          	lb	zero,-1648(zero) # fffff990 <USER_MAX+0xffaff990>
 45c:	ba000003          	lb	zero,-1120(zero) # fffffba0 <USER_MAX+0xffaffba0>
 460:	c4000003          	lb	zero,-960(zero) # fffffc40 <USER_MAX+0xffaffc40>
 464:	dc000003          	lb	zero,-576(zero) # fffffdc0 <USER_MAX+0xffaffdc0>
 468:	f4000003          	lb	zero,-192(zero) # ffffff40 <USER_MAX+0xffafff40>
 46c:	16000003          	lb	zero,352(zero) # 160 <start-0x3ffea0>
 470:	0004                	.insn	2, 0x0004
 472:	2000                	.insn	2, 0x2000
 474:	0004                	.insn	2, 0x0004
 476:	2a00                	.insn	2, 0x2a00
 478:	0004                	.insn	2, 0x0004
 47a:	3400                	.insn	2, 0x3400
 47c:	0004                	.insn	2, 0x0004
 47e:	0300                	.insn	2, 0x0300
 480:	1103140b          	.insn	4, 0x1103140b
 484:	9f00                	.insn	2, 0x9f00
 486:	0100                	.insn	2, 0x0100
 488:	1c18040b          	.insn	4, 0x1c18040b
 48c:	5a01                	.insn	2, 0x5a01
 48e:	1c04                	.insn	2, 0x1c04
 490:	04fc                	.insn	2, 0x04fc
 492:	5e01                	.insn	2, 0x5e01
 494:	0100                	.insn	2, 0x0100
 496:	b458040b          	.insn	4, 0xb458040b
 49a:	0101                	.insn	2, 0x0101
 49c:	0b01005b          	.insn	4, 0x0b01005b
 4a0:	5804                	.insn	2, 0x5804
 4a2:	026c                	.insn	2, 0x026c
 4a4:	9f30                	.insn	2, 0x9f30
 4a6:	0100                	.insn	2, 0x0100
 4a8:	01f0040b          	.insn	4, 0x01f0040b
 4ac:	01f8                	.insn	2, 0x01f8
 4ae:	7204                	.insn	2, 0x7204
 4b0:	0a90                	.insn	2, 0x0a90
 4b2:	009f 0b01 8404      	.insn	6, 0x84040b01009f
 4b8:	c402                	.insn	2, 0xc402
 4ba:	0102                	.insn	2, 0x0102
 4bc:	0060                	.insn	2, 0x0060
 4be:	0b01                	.insn	2, 0x0b01
 4c0:	8404                	.insn	2, 0x8404
 4c2:	8802                	.insn	2, 0x8802
 4c4:	0202                	.insn	2, 0x0202
 4c6:	9f30                	.insn	2, 0x9f30
 4c8:	0100                	.insn	2, 0x0100
 4ca:	038c040b          	.insn	4, 0x038c040b
 4ce:	03cc                	.insn	2, 0x03cc
 4d0:	5b01                	.insn	2, 0x5b01
 4d2:	0100                	.insn	2, 0x0100
 4d4:	038c040b          	.insn	4, 0x038c040b
 4d8:	0390                	.insn	2, 0x0390
 4da:	3002                	.insn	2, 0x3002
 4dc:	009f 0b01 9404      	.insn	6, 0x94040b01009f
 4e2:	d404                	.insn	2, 0xd404
 4e4:	0104                	.insn	2, 0x0104
 4e6:	0b01005b          	.insn	4, 0x0b01005b
 4ea:	9404                	.insn	2, 0x9404
 4ec:	9804                	.insn	2, 0x9804
 4ee:	0204                	.insn	2, 0x0204
 4f0:	9f30                	.insn	2, 0x9f30
 4f2:	0100                	.insn	2, 0x0100
 4f4:	04fc040b          	.insn	4, 0x04fc040b
 4f8:	0594                	.insn	2, 0x0594
 4fa:	5a01                	.insn	2, 0x5a01
 4fc:	9404                	.insn	2, 0x9404
 4fe:	b405                	.insn	2, 0xb405
 500:	010a                	.insn	2, 0x010a
 502:	0055                	.insn	2, 0x0055
 504:	0b01                	.insn	2, 0x0b01
 506:	c004                	.insn	2, 0xc004
 508:	dc06                	.insn	2, 0xdc06
 50a:	0106                	.insn	2, 0x0106
 50c:	0459                	.insn	2, 0x0459
 50e:	09a0                	.insn	2, 0x09a0
 510:	09b0                	.insn	2, 0x09b0
 512:	5901                	.insn	2, 0x5901
 514:	0100                	.insn	2, 0x0100
 516:	06c4040b          	.insn	4, 0x06c4040b
 51a:	06dc                	.insn	2, 0x06dc
 51c:	5901                	.insn	2, 0x5901
 51e:	b004                	.insn	2, 0xb004
 520:	bc09                	.insn	2, 0xbc09
 522:	0109                	.insn	2, 0x0109
 524:	0459                	.insn	2, 0x0459
 526:	09bc                	.insn	2, 0x09bc
 528:	09c8                	.insn	2, 0x09c8
 52a:	5d01                	.insn	2, 0x5d01
 52c:	c804                	.insn	2, 0xc804
 52e:	e809                	.insn	2, 0xe809
 530:	0109                	.insn	2, 0x0109
 532:	0059                	.insn	2, 0x0059
 534:	0b01                	.insn	2, 0x0b01
 536:	c404                	.insn	2, 0xc404
 538:	dc06                	.insn	2, 0xdc06
 53a:	0306                	.insn	2, 0x0306
 53c:	0011                	.insn	2, 0x0011
 53e:	049f 09b0 09b4      	.insn	6, 0x09b409b0049f
 544:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 548:	bc04                	.insn	2, 0xbc04
 54a:	c409                	.insn	2, 0xc409
 54c:	0109                	.insn	2, 0x0109
 54e:	0458                	.insn	2, 0x0458
 550:	09c4                	.insn	2, 0x09c4
 552:	09e8                	.insn	2, 0x09e8
 554:	5a01                	.insn	2, 0x5a01
 556:	0100                	.insn	2, 0x0100
 558:	06f4040b          	.insn	4, 0x06f4040b
 55c:	08ac                	.insn	2, 0x08ac
 55e:	5801                	.insn	2, 0x5801
 560:	0100                	.insn	2, 0x0100
 562:	06f4040b          	.insn	4, 0x06f4040b
 566:	0798                	.insn	2, 0x0798
 568:	9f071103          	lh	sp,-1552(a4)
 56c:	9804                	.insn	2, 0x9804
 56e:	0307b407          	.insn	4, 0x0307b407
 572:	0611                	.insn	2, 0x0611
 574:	049f 07b4 07d0      	.insn	6, 0x07d007b4049f
 57a:	9f051103          	lh	sp,-1552(a0)
 57e:	d004                	.insn	2, 0xd004
 580:	0307ec07          	.insn	4, 0x0307ec07
 584:	0411                	.insn	2, 0x0411
 586:	049f 07ec 0888      	.insn	6, 0x088807ec049f
 58c:	9f031103          	lh	sp,-1552(t1)
 590:	8804                	.insn	2, 0x8804
 592:	a408                	.insn	2, 0xa408
 594:	0308                	.insn	2, 0x0308
 596:	0211                	.insn	2, 0x0211
 598:	049f 08a4 08bc      	.insn	6, 0x08bc08a4049f
 59e:	9f011103          	lh	sp,-1552(sp)
 5a2:	bc04                	.insn	2, 0xbc04
 5a4:	cc08                	.insn	2, 0xcc08
 5a6:	0308                	.insn	2, 0x0308
 5a8:	0011                	.insn	2, 0x0011
 5aa:	049f 08cc 08d4      	.insn	6, 0x08d408cc049f
 5b0:	9f7f1103          	lh	sp,-1545(t5)
 5b4:	0100                	.insn	2, 0x0100
 5b6:	06f8040b          	.insn	4, 0x06f8040b
 5ba:	06fc                	.insn	2, 0x06fc
 5bc:	5a01                	.insn	2, 0x5a01
 5be:	8804                	.insn	2, 0x8804
 5c0:	01079807          	.insn	4, 0x01079807
 5c4:	045a                	.insn	2, 0x045a
 5c6:	07a4                	.insn	2, 0x07a4
 5c8:	07b4                	.insn	2, 0x07b4
 5ca:	5a01                	.insn	2, 0x5a01
 5cc:	c004                	.insn	2, 0xc004
 5ce:	0107d007          	.insn	4, 0x0107d007
 5d2:	045a                	.insn	2, 0x045a
 5d4:	07dc                	.insn	2, 0x07dc
 5d6:	07ec                	.insn	2, 0x07ec
 5d8:	5a01                	.insn	2, 0x5a01
 5da:	f804                	.insn	2, 0xf804
 5dc:	01088807          	.insn	4, 0x01088807
 5e0:	045a                	.insn	2, 0x045a
 5e2:	0894                	.insn	2, 0x0894
 5e4:	08a4                	.insn	2, 0x08a4
 5e6:	5a01                	.insn	2, 0x5a01
 5e8:	ac04                	.insn	2, 0xac04
 5ea:	b008                	.insn	2, 0xb008
 5ec:	0108                	.insn	2, 0x0108
 5ee:	0058                	.insn	2, 0x0058
 5f0:	0b01                	.insn	2, 0x0b01
 5f2:	f804                	.insn	2, 0xf804
 5f4:	8408                	.insn	2, 0x8408
 5f6:	0109                	.insn	2, 0x0109
 5f8:	0459                	.insn	2, 0x0459
 5fa:	0984                	.insn	2, 0x0984
 5fc:	0990                	.insn	2, 0x0990
 5fe:	9f7f7903          	.insn	4, 0x9f7f7903
 602:	9004                	.insn	2, 0x9004
 604:	9809                	.insn	2, 0x9809
 606:	0109                	.insn	2, 0x0109
 608:	0059                	.insn	2, 0x0059
 60a:	0b01                	.insn	2, 0x0b01
 60c:	b404                	.insn	2, 0xb404
 60e:	b80a                	.insn	2, 0xb80a
 610:	010a                	.insn	2, 0x010a
 612:	045a                	.insn	2, 0x045a
 614:	0ab8                	.insn	2, 0x0ab8
 616:	0ac8                	.insn	2, 0x0ac8
 618:	5b01                	.insn	2, 0x5b01
 61a:	0100                	.insn	2, 0x0100
 61c:	0ac8040b          	.insn	4, 0x0ac8040b
 620:	0acc                	.insn	2, 0x0acc
 622:	5a01                	.insn	2, 0x5a01
 624:	cc04                	.insn	2, 0xcc04
 626:	dc0a                	.insn	2, 0xdc0a
 628:	010a                	.insn	2, 0x010a
 62a:	0b01005b          	.insn	4, 0x0b01005b
 62e:	dc04                	.insn	2, 0xdc04
 630:	e40a                	.insn	2, 0xe40a
 632:	010a                	.insn	2, 0x010a
 634:	005a                	.insn	2, 0x005a
 636:	0b01                	.insn	2, 0x0b01
 638:	e804                	.insn	2, 0xe804
 63a:	fc0a                	.insn	2, 0xfc0a
 63c:	010a                	.insn	2, 0x010a
 63e:	045a                	.insn	2, 0x045a
 640:	0afc                	.insn	2, 0x0afc
 642:	0bcc                	.insn	2, 0x0bcc
 644:	5801                	.insn	2, 0x5801
 646:	d804                	.insn	2, 0xd804
 648:	010c940b          	.insn	4, 0x010c940b
 64c:	0058                	.insn	2, 0x0058
 64e:	0b01                	.insn	2, 0x0b01
 650:	ec04                	.insn	2, 0xec04
 652:	010c940b          	.insn	4, 0x010c940b
 656:	0059                	.insn	2, 0x0059
 658:	0b01                	.insn	2, 0x0b01
 65a:	8004                	.insn	2, 0x8004
 65c:	900c                	.insn	2, 0x900c
 65e:	010c                	.insn	2, 0x010c
 660:	0458                	.insn	2, 0x0458
 662:	0c90                	.insn	2, 0x0c90
 664:	0c94                	.insn	2, 0x0c94
 666:	5a01                	.insn	2, 0x5a01
 668:	0100                	.insn	2, 0x0100
 66a:	0c94040b          	.insn	4, 0x0c94040b
 66e:	0c9c                	.insn	2, 0x0c9c
 670:	5a01                	.insn	2, 0x5a01
 672:	0100                	.insn	2, 0x0100
 674:	0ca0040b          	.insn	4, 0x0ca0040b
 678:	0ca8                	.insn	2, 0x0ca8
 67a:	5a01                	.insn	2, 0x5a01
 67c:	0100                	.insn	2, 0x0100
 67e:	0cac040b          	.insn	4, 0x0cac040b
 682:	0cb4                	.insn	2, 0x0cb4
 684:	5a01                	.insn	2, 0x5a01
 686:	0100                	.insn	2, 0x0100
 688:	0cb8040b          	.insn	4, 0x0cb8040b
 68c:	0cc0                	.insn	2, 0x0cc0
 68e:	5a01                	.insn	2, 0x5a01
 690:	0100                	.insn	2, 0x0100
 692:	0cdc040b          	.insn	4, 0x0cdc040b
 696:	0cec                	.insn	2, 0x0cec
 698:	3002                	.insn	2, 0x3002
 69a:	049f 0cec 0cf0      	.insn	6, 0x0cf00cec049f
 6a0:	5a01                	.insn	2, 0x5a01
 6a2:	0100                	.insn	2, 0x0100
 6a4:	0cec040b          	.insn	4, 0x0cec040b
 6a8:	0cf4                	.insn	2, 0x0cf4
 6aa:	5a01                	.insn	2, 0x5a01
 6ac:	f404                	.insn	2, 0xf404
 6ae:	980c                	.insn	2, 0x980c
 6b0:	010d                	.insn	2, 0x010d
 6b2:	0d98045b          	.insn	4, 0x0d98045b
 6b6:	0d9c                	.insn	2, 0x0d9c
 6b8:	5a01                	.insn	2, 0x5a01
 6ba:	b004                	.insn	2, 0xb004
 6bc:	c80d                	.insn	2, 0xc80d
 6be:	010d                	.insn	2, 0x010d
 6c0:	0b01005b          	.insn	4, 0x0b01005b
 6c4:	c804                	.insn	2, 0xc804
 6c6:	d40d                	.insn	2, 0xd40d
 6c8:	020d                	.insn	2, 0x020d
 6ca:	9f30                	.insn	2, 0x9f30
 6cc:	d404                	.insn	2, 0xd404
 6ce:	d80d                	.insn	2, 0xd80d
 6d0:	010d                	.insn	2, 0x010d
 6d2:	005a                	.insn	2, 0x005a
 6d4:	0b01                	.insn	2, 0x0b01
 6d6:	e404                	.insn	2, 0xe404
 6d8:	f40d                	.insn	2, 0xf40d
 6da:	010d                	.insn	2, 0x010d
 6dc:	0df8045b          	.insn	4, 0x0df8045b
 6e0:	0e88                	.insn	2, 0x0e88
 6e2:	5b01                	.insn	2, 0x5b01
 6e4:	0100                	.insn	2, 0x0100
 6e6:	0de4040b          	.insn	4, 0x0de4040b
 6ea:	0df8                	.insn	2, 0x0df8
 6ec:	5a01                	.insn	2, 0x5a01
 6ee:	f804                	.insn	2, 0xf804
 6f0:	840d                	.insn	2, 0x840d
 6f2:	010e                	.insn	2, 0x010e
 6f4:	045e                	.insn	2, 0x045e
 6f6:	0e84                	.insn	2, 0x0e84
 6f8:	0e90                	.insn	2, 0x0e90
 6fa:	5d01                	.insn	2, 0x5d01
 6fc:	0100                	.insn	2, 0x0100
 6fe:	0e98040b          	.insn	4, 0x0e98040b
 702:	0ea4                	.insn	2, 0x0ea4
 704:	5a01                	.insn	2, 0x5a01
 706:	a404                	.insn	2, 0xa404
 708:	ac0e                	.insn	2, 0xac0e
 70a:	030e                	.insn	2, 0x030e
 70c:	7f7a                	.insn	2, 0x7f7a
 70e:	049f 0eac 0eb8      	.insn	6, 0x0eb80eac049f
 714:	5a01                	.insn	2, 0x5a01
 716:	0100                	.insn	2, 0x0100
 718:	0ec8040b          	.insn	4, 0x0ec8040b
 71c:	0ecc                	.insn	2, 0x0ecc
 71e:	5a01                	.insn	2, 0x5a01
 720:	cc04                	.insn	2, 0xcc04
 722:	9c0e                	.insn	2, 0x9c0e
 724:	045b010f          	.insn	4, 0x045b010f
 728:	0fa8                	.insn	2, 0x0fa8
 72a:	0ffc                	.insn	2, 0x0ffc
 72c:	5b01                	.insn	2, 0x5b01
 72e:	0100                	.insn	2, 0x0100
 730:	0ecc040b          	.insn	4, 0x0ecc040b
 734:	0ee8                	.insn	2, 0x0ee8
 736:	3a02                	.insn	2, 0x3a02
 738:	049f 0ee8 0ef4      	.insn	6, 0x0ef40ee8049f
 73e:	4002                	.insn	2, 0x4002
 740:	049f 0ef4 0f80      	.insn	6, 0x0f800ef4049f
 746:	5c01                	.insn	2, 0x5c01
 748:	8004                	.insn	2, 0x8004
 74a:	020f840f          	.insn	4, 0x020f840f
 74e:	9f3a                	.insn	2, 0x9f3a
 750:	8404                	.insn	2, 0x8404
 752:	010f900f          	.insn	4, 0x010f900f
 756:	045c                	.insn	2, 0x045c
 758:	0f90                	.insn	2, 0x0f90
 75a:	0f94                	.insn	2, 0x0f94
 75c:	3a02                	.insn	2, 0x3a02
 75e:	009f 0b01 f404      	.insn	6, 0xf4040b01009f
 764:	800e                	.insn	2, 0x800e
 766:	9f30020f          	.insn	4, 0x9f30020f
 76a:	8404                	.insn	2, 0x8404
 76c:	020f900f          	.insn	4, 0x020f900f
 770:	9f30                	.insn	2, 0x9f30
 772:	a804                	.insn	2, 0xa804
 774:	010ff40f          	.insn	4, 0x010ff40f
 778:	045a                	.insn	2, 0x045a
 77a:	0ff8                	.insn	2, 0x0ff8
 77c:	1084                	.insn	2, 0x1084
 77e:	5a01                	.insn	2, 0x5a01
 780:	0100                	.insn	2, 0x0100
 782:	0fa8040b          	.insn	4, 0x0fa8040b
 786:	0fec                	.insn	2, 0x0fec
 788:	5d01                	.insn	2, 0x5d01
 78a:	0100                	.insn	2, 0x0100
 78c:	0fb8040b          	.insn	4, 0x0fb8040b
 790:	0fc0                	.insn	2, 0x0fc0
 792:	6101                	.insn	2, 0x6101
 794:	d004                	.insn	2, 0xd004
 796:	010fd80f          	.insn	4, 0x010fd80f
 79a:	0461                	.insn	2, 0x0461
 79c:	0fe8                	.insn	2, 0x0fe8
 79e:	1080                	.insn	2, 0x1080
 7a0:	6101                	.insn	2, 0x6101
 7a2:	0100                	.insn	2, 0x0100
 7a4:	1084040b          	.insn	4, 0x1084040b
 7a8:	108c                	.insn	2, 0x108c
 7aa:	5a01                	.insn	2, 0x5a01
 7ac:	9404                	.insn	2, 0x9404
 7ae:	9810                	.insn	2, 0x9810
 7b0:	0110                	.insn	2, 0x0110
 7b2:	045a                	.insn	2, 0x045a
 7b4:	1098                	.insn	2, 0x1098
 7b6:	10c0                	.insn	2, 0x10c0
 7b8:	5b01                	.insn	2, 0x5b01
 7ba:	0100                	.insn	2, 0x0100
 7bc:	1098040b          	.insn	4, 0x1098040b
 7c0:	10a8                	.insn	2, 0x10a8
 7c2:	3202                	.insn	2, 0x3202
 7c4:	049f 10a8 10ac      	.insn	6, 0x10ac10a8049f
 7ca:	5c01                	.insn	2, 0x5c01
 7cc:	ac04                	.insn	2, 0xac04
 7ce:	b410                	.insn	2, 0xb410
 7d0:	0310                	.insn	2, 0x0310
 7d2:	017c                	.insn	2, 0x017c
 7d4:	049f 10b4 10bc      	.insn	6, 0x10bc10b4049f
 7da:	5c01                	.insn	2, 0x5c01
 7dc:	0100                	.insn	2, 0x0100
 7de:	10cc040b          	.insn	4, 0x10cc040b
 7e2:	10d4                	.insn	2, 0x10d4
 7e4:	5b01                	.insn	2, 0x5b01
 7e6:	0100                	.insn	2, 0x0100
 7e8:	10e0040b          	.insn	4, 0x10e0040b
 7ec:	10e8                	.insn	2, 0x10e8
 7ee:	5b01                	.insn	2, 0x5b01
 7f0:	0100                	.insn	2, 0x0100
 7f2:	10e8040b          	.insn	4, 0x10e8040b
 7f6:	10f0                	.insn	2, 0x10f0
 7f8:	5a01                	.insn	2, 0x5a01
 7fa:	0100                	.insn	2, 0x0100
 7fc:	10fc040b          	.insn	4, 0x10fc040b
 800:	1180                	.insn	2, 0x1180
 802:	5a01                	.insn	2, 0x5a01
 804:	0300                	.insn	2, 0x0300
 806:	0006                	.insn	2, 0x0006
 808:	0500                	.insn	2, 0x0500
 80a:	0400                	.insn	2, 0x0400
 80c:	2400                	.insn	2, 0x2400
 80e:	0000                	.insn	2, 0x0000
 810:	9000                	.insn	2, 0x9000
 812:	0000                	.insn	2, 0x0000
 814:	9c00                	.insn	2, 0x9c00
 816:	0000                	.insn	2, 0x0000
 818:	a200                	.insn	2, 0xa200
 81a:	0000                	.insn	2, 0x0000
 81c:	a900                	.insn	2, 0xa900
 81e:	0000                	.insn	2, 0x0000
 820:	b200                	.insn	2, 0xb200
 822:	0000                	.insn	2, 0x0000
 824:	ba00                	.insn	2, 0xba00
 826:	0000                	.insn	2, 0x0000
 828:	c200                	.insn	2, 0xc200
 82a:	0000                	.insn	2, 0x0000
 82c:	ca00                	.insn	2, 0xca00
 82e:	0000                	.insn	2, 0x0000
 830:	d200                	.insn	2, 0xd200
 832:	0000                	.insn	2, 0x0000
 834:	e800                	.insn	2, 0xe800
 836:	0000                	.insn	2, 0x0000
 838:	fe00                	.insn	2, 0xfe00
 83a:	0000                	.insn	2, 0x0000
 83c:	1400                	.insn	2, 0x1400
 83e:	0001                	.insn	2, 0x0001
 840:	1c00                	.insn	2, 0x1c00
 842:	0001                	.insn	2, 0x0001
 844:	2400                	.insn	2, 0x2400
 846:	0001                	.insn	2, 0x0001
 848:	4900                	.insn	2, 0x4900
 84a:	0001                	.insn	2, 0x0001
 84c:	9600                	.insn	2, 0x9600
 84e:	0001                	.insn	2, 0x0001
 850:	c700                	.insn	2, 0xc700
 852:	0001                	.insn	2, 0x0001
 854:	6100                	.insn	2, 0x6100
 856:	0002                	.insn	2, 0x0002
 858:	6900                	.insn	2, 0x6900
 85a:	0002                	.insn	2, 0x0002
 85c:	7100                	.insn	2, 0x7100
 85e:	0002                	.insn	2, 0x0002
 860:	7900                	.insn	2, 0x7900
 862:	0002                	.insn	2, 0x0002
 864:	9100                	.insn	2, 0x9100
 866:	0002                	.insn	2, 0x0002
 868:	a000                	.insn	2, 0xa000
 86a:	0002                	.insn	2, 0x0002
 86c:	d100                	.insn	2, 0xd100
 86e:	0002                	.insn	2, 0x0002
 870:	d900                	.insn	2, 0xd900
 872:	0002                	.insn	2, 0x0002
 874:	7300                	.insn	2, 0x7300
 876:	aa000003          	lb	zero,-1376(zero) # fffffaa0 <USER_MAX+0xffaffaa0>
 87a:	b9000003          	lb	zero,-1136(zero) # fffffb90 <USER_MAX+0xffaffb90>
 87e:	c1000003          	lb	zero,-1008(zero) # fffffc10 <USER_MAX+0xffaffc10>
 882:	c9000003          	lb	zero,-880(zero) # fffffc90 <USER_MAX+0xffaffc90>
 886:	d1000003          	lb	zero,-752(zero) # fffffd10 <USER_MAX+0xffaffd10>
 88a:	3e000003          	lb	zero,992(zero) # 3e0 <start-0x3ffc20>
 88e:	0004                	.insn	2, 0x0004
 890:	7800                	.insn	2, 0x7800
 892:	0004                	.insn	2, 0x0004
 894:	0900                	.insn	2, 0x0900
 896:	0005                	.insn	2, 0x0005
 898:	1800                	.insn	2, 0x1800
 89a:	0005                	.insn	2, 0x0005
 89c:	8e00                	.insn	2, 0x8e00
 89e:	0005                	.insn	2, 0x0005
 8a0:	0400                	.insn	2, 0x0400
 8a2:	1400                	.insn	2, 0x1400
 8a4:	5a01                	.insn	2, 0x5a01
 8a6:	1404                	.insn	2, 0x1404
 8a8:	01ac                	.insn	2, 0x01ac
 8aa:	5801                	.insn	2, 0x5801
 8ac:	0400                	.insn	2, 0x0400
 8ae:	705c                	.insn	2, 0x705c
 8b0:	5a01                	.insn	2, 0x5a01
 8b2:	0400                	.insn	2, 0x0400
 8b4:	8478                	.insn	2, 0x8478
 8b6:	0101                	.insn	2, 0x0101
 8b8:	005a                	.insn	2, 0x005a
 8ba:	9404                	.insn	2, 0x9404
 8bc:	b401                	.insn	2, 0xb401
 8be:	0201                	.insn	2, 0x0201
 8c0:	9f30                	.insn	2, 0x9f30
 8c2:	0400                	.insn	2, 0x0400
 8c4:	0288                	.insn	2, 0x0288
 8c6:	0294                	.insn	2, 0x0294
 8c8:	5b01                	.insn	2, 0x5b01
 8ca:	0400                	.insn	2, 0x0400
 8cc:	02e0                	.insn	2, 0x02e0
 8ce:	02f4                	.insn	2, 0x02f4
 8d0:	5b01                	.insn	2, 0x5b01
 8d2:	0400                	.insn	2, 0x0400
 8d4:	02e4                	.insn	2, 0x02e4
 8d6:	02f8                	.insn	2, 0x02f8
 8d8:	5c01                	.insn	2, 0x5c01
 8da:	0400                	.insn	2, 0x0400
 8dc:	02e8                	.insn	2, 0x02e8
 8de:	038c                	.insn	2, 0x038c
 8e0:	5d01                	.insn	2, 0x5d01
 8e2:	0400                	.insn	2, 0x0400
 8e4:	03a8                	.insn	2, 0x03a8
 8e6:	03e8                	.insn	2, 0x03e8
 8e8:	5a01                	.insn	2, 0x5a01
 8ea:	e804                	.insn	2, 0xe804
 8ec:	0104c003          	lbu	zero,16(s1)
 8f0:	04e40463          	beq	s0,a4,938 <start-0x3ff6c8>
 8f4:	08c8                	.insn	2, 0x08c8
 8f6:	6301                	.insn	2, 0x6301
 8f8:	0400                	.insn	2, 0x0400
 8fa:	03a8                	.insn	2, 0x03a8
 8fc:	03e4                	.insn	2, 0x03e4
 8fe:	5b01                	.insn	2, 0x5b01
 900:	e404                	.insn	2, 0xe404
 902:	0104bc03          	.insn	4, 0x0104bc03
 906:	0462                	.insn	2, 0x0462
 908:	04e4                	.insn	2, 0x04e4
 90a:	08c8                	.insn	2, 0x08c8
 90c:	6201                	.insn	2, 0x6201
 90e:	0400                	.insn	2, 0x0400
 910:	03a8                	.insn	2, 0x03a8
 912:	03e0                	.insn	2, 0x03e0
 914:	5c01                	.insn	2, 0x5c01
 916:	e004                	.insn	2, 0xe004
 918:	0104b803          	.insn	4, 0x0104b803
 91c:	0459                	.insn	2, 0x0459
 91e:	04e4                	.insn	2, 0x04e4
 920:	08c8                	.insn	2, 0x08c8
 922:	5901                	.insn	2, 0x5901
 924:	0400                	.insn	2, 0x0400
 926:	0484                	.insn	2, 0x0484
 928:	0490                	.insn	2, 0x0490
 92a:	5a01                	.insn	2, 0x5a01
 92c:	0400                	.insn	2, 0x0400
 92e:	0498                	.insn	2, 0x0498
 930:	04a4                	.insn	2, 0x04a4
 932:	5a01                	.insn	2, 0x5a01
 934:	0400                	.insn	2, 0x0400
 936:	0584                	.insn	2, 0x0584
 938:	0590                	.insn	2, 0x0590
 93a:	9f0a1103          	lh	sp,-1552(s4)
 93e:	bc04                	.insn	2, 0xbc04
 940:	0307c007          	.insn	4, 0x0307c007
 944:	0811                	.insn	2, 0x0811
 946:	049f 07c0 07d8      	.insn	6, 0x07d807c0049f
 94c:	9f091103          	lh	sp,-1552(s2)
 950:	d804                	.insn	2, 0xd804
 952:	0307e807          	.insn	4, 0x0307e807
 956:	0a11                	.insn	2, 0x0a11
 958:	009f 8404 8805      	.insn	6, 0x88058404009f
 95e:	0105                	.insn	2, 0x0105
 960:	0588045b          	.insn	4, 0x0588045b
 964:	0594                	.insn	2, 0x0594
 966:	5a01                	.insn	2, 0x5a01
 968:	cc04                	.insn	2, 0xcc04
 96a:	d405                	.insn	2, 0xd405
 96c:	0305                	.insn	2, 0x0305
 96e:	0011                	.insn	2, 0x0011
 970:	049f 05d4 05e0      	.insn	6, 0x05e005d4049f
 976:	5a01                	.insn	2, 0x5a01
 978:	e004                	.insn	2, 0xe004
 97a:	e805                	.insn	2, 0xe805
 97c:	0305                	.insn	2, 0x0305
 97e:	0111                	.insn	2, 0x0111
 980:	049f 05e8 07b0      	.insn	6, 0x07b005e8049f
 986:	5a01                	.insn	2, 0x5a01
 988:	b004                	.insn	2, 0xb004
 98a:	0307bc07          	.insn	4, 0x0307bc07
 98e:	017a                	.insn	2, 0x017a
 990:	049f 07c4 07cc      	.insn	6, 0x07cc07c4049f
 996:	5b01                	.insn	2, 0x5b01
 998:	d004                	.insn	2, 0xd004
 99a:	0107d807          	.insn	4, 0x0107d807
 99e:	045a                	.insn	2, 0x045a
 9a0:	07d8                	.insn	2, 0x07d8
 9a2:	07e8                	.insn	2, 0x07e8
 9a4:	5b01                	.insn	2, 0x5b01
 9a6:	0400                	.insn	2, 0x0400
 9a8:	0584                	.insn	2, 0x0584
 9aa:	05ac                	.insn	2, 0x05ac
 9ac:	8509                	.insn	2, 0x8509
 9ae:	1100                	.insn	2, 0x1100
 9b0:	1c10                	.insn	2, 0x1c10
 9b2:	7f11                	.insn	2, 0x7f11
 9b4:	ac049f1b          	.insn	4, 0xac049f1b
 9b8:	b005                	.insn	2, 0xb005
 9ba:	0c05                	.insn	2, 0x0c05
 9bc:	0085                	.insn	2, 0x0085
 9be:	1011                	.insn	2, 0x1011
 9c0:	111c                	.insn	2, 0x111c
 9c2:	01111b7f b8049f22 	.insn	12, 0x0908c805b8049f2201111b7f
 9ca:	0908c805 
 9ce:	0085                	.insn	2, 0x0085
 9d0:	1011                	.insn	2, 0x1011
 9d2:	111c                	.insn	2, 0x111c
 9d4:	009f1b7f d405cc04 	.insn	12, 0x00110305d405cc04009f1b7f
 9dc:	00110305 
 9e0:	049f 05d4 05e0      	.insn	6, 0x05e005d4049f
 9e6:	9f011103          	lh	sp,-1552(sp)
 9ea:	e004                	.insn	2, 0xe004
 9ec:	e805                	.insn	2, 0xe805
 9ee:	0305                	.insn	2, 0x0305
 9f0:	0011                	.insn	2, 0x0011
 9f2:	049f 05e8 05fc      	.insn	6, 0x05fc05e8049f
 9f8:	9f011103          	lh	sp,-1552(sp)
 9fc:	fc04                	.insn	2, 0xfc04
 9fe:	8405                	.insn	2, 0x8405
 a00:	0306                	.insn	2, 0x0306
 a02:	0211                	.insn	2, 0x0211
 a04:	049f 0684 068c      	.insn	6, 0x068c0684049f
 a0a:	9f031103          	lh	sp,-1552(t1)
 a0e:	8c04                	.insn	2, 0x8c04
 a10:	9406                	.insn	2, 0x9406
 a12:	0306                	.insn	2, 0x0306
 a14:	0411                	.insn	2, 0x0411
 a16:	049f 0694 069c      	.insn	6, 0x069c0694049f
 a1c:	9f051103          	lh	sp,-1552(a0)
 a20:	9c04                	.insn	2, 0x9c04
 a22:	a406                	.insn	2, 0xa406
 a24:	0306                	.insn	2, 0x0306
 a26:	0611                	.insn	2, 0x0611
 a28:	049f 06a4 06ac      	.insn	6, 0x06ac06a4049f
 a2e:	9f071103          	lh	sp,-1552(a4)
 a32:	b804                	.insn	2, 0xb804
 a34:	c406                	.insn	2, 0xc406
 a36:	0306                	.insn	2, 0x0306
 a38:	0211                	.insn	2, 0x0211
 a3a:	049f 06c4 06d8      	.insn	6, 0x06d806c4049f
 a40:	9f031103          	lh	sp,-1552(t1)
 a44:	d804                	.insn	2, 0xd804
 a46:	ec06                	.insn	2, 0xec06
 a48:	0306                	.insn	2, 0x0306
 a4a:	0411                	.insn	2, 0x0411
 a4c:	049f 06ec 0780      	.insn	6, 0x078006ec049f
 a52:	9f051103          	lh	sp,-1552(a0)
 a56:	8004                	.insn	2, 0x8004
 a58:	03079407          	.insn	4, 0x03079407
 a5c:	0611                	.insn	2, 0x0611
 a5e:	049f 0794 07a8      	.insn	6, 0x07a80794049f
 a64:	9f071103          	lh	sp,-1552(a4)
 a68:	a804                	.insn	2, 0xa804
 a6a:	0307b007          	.insn	4, 0x0307b007
 a6e:	0811                	.insn	2, 0x0811
 a70:	009f c804 dc08      	.insn	6, 0xdc08c804009f
 a76:	0108                	.insn	2, 0x0108
 a78:	005a                	.insn	2, 0x005a
 a7a:	ac04                	.insn	2, 0xac04
 a7c:	b809                	.insn	2, 0xb809
 a7e:	0109                	.insn	2, 0x0109
 a80:	005a                	.insn	2, 0x005a
 a82:	c004                	.insn	2, 0xc004
 a84:	cc09                	.insn	2, 0xcc09
 a86:	0109                	.insn	2, 0x0109
 a88:	005a                	.insn	2, 0x005a
 a8a:	ac04                	.insn	2, 0xac04
 a8c:	c00a                	.insn	2, 0xc00a
 a8e:	020a                	.insn	2, 0x020a
 a90:	9f30                	.insn	2, 0x9f30
 a92:	c004                	.insn	2, 0xc004
 a94:	f40a                	.insn	2, 0xf40a
 a96:	010a                	.insn	2, 0x010a
 a98:	045c                	.insn	2, 0x045c
 a9a:	0dc0                	.insn	2, 0x0dc0
 a9c:	0dcc                	.insn	2, 0x0dcc
 a9e:	3002                	.insn	2, 0x3002
 aa0:	009f ac04 f40a      	.insn	6, 0xf40aac04009f
 aa6:	010a                	.insn	2, 0x010a
 aa8:	0dc0045b          	.insn	4, 0x0dc0045b
 aac:	0dcc                	.insn	2, 0x0dcc
 aae:	5b01                	.insn	2, 0x5b01
 ab0:	0400                	.insn	2, 0x0400
 ab2:	0aac                	.insn	2, 0x0aac
 ab4:	0af4                	.insn	2, 0x0af4
 ab6:	8409                	.insn	2, 0x8409
 ab8:	1100                	.insn	2, 0x1100
 aba:	1c10                	.insn	2, 0x1c10
 abc:	7f11                	.insn	2, 0x7f11
 abe:	f4049f1b          	.insn	4, 0xf4049f1b
 ac2:	f80a                	.insn	2, 0xf80a
 ac4:	0c0a                	.insn	2, 0x0c0a
 ac6:	0084                	.insn	2, 0x0084
 ac8:	1011                	.insn	2, 0x1011
 aca:	111c                	.insn	2, 0x111c
 acc:	01111b7f 80049f22 	.insn	12, 0x090df00b80049f2201111b7f
 ad4:	090df00b 
 ad8:	0084                	.insn	2, 0x0084
 ada:	1011                	.insn	2, 0x1011
 adc:	111c                	.insn	2, 0x111c
 ade:	009f1b7f f40ae804 	.insn	12, 0x005d010af40ae804009f1b7f
 ae6:	005d010a 
 aea:	9404                	.insn	2, 0x9404
 aec:	030b980b          	.insn	4, 0x030b980b
 af0:	0011                	.insn	2, 0x0011
 af2:	049f 0b98 0ba0      	.insn	6, 0x0ba00b98049f
 af8:	9f011103          	lh	sp,-1552(sp)
 afc:	a004                	.insn	2, 0xa004
 afe:	030ba80b          	.insn	4, 0x030ba80b
 b02:	0211                	.insn	2, 0x0211
 b04:	049f 0ba8 0bb0      	.insn	6, 0x0bb00ba8049f
 b0a:	9f031103          	lh	sp,-1552(t1)
 b0e:	b004                	.insn	2, 0xb004
 b10:	030bb80b          	.insn	4, 0x030bb80b
 b14:	0411                	.insn	2, 0x0411
 b16:	049f 0bb8 0bc0      	.insn	6, 0x0bc00bb8049f
 b1c:	9f051103          	lh	sp,-1552(a0)
 b20:	c004                	.insn	2, 0xc004
 b22:	030bc80b          	.insn	4, 0x030bc80b
 b26:	0611                	.insn	2, 0x0611
 b28:	049f 0bc8 0bd0      	.insn	6, 0x0bd00bc8049f
 b2e:	9f071103          	lh	sp,-1552(a4)
 b32:	dc04                	.insn	2, 0xdc04
 b34:	030be40b          	.insn	4, 0x030be40b
 b38:	0011                	.insn	2, 0x0011
 b3a:	049f 0be4 0bf4      	.insn	6, 0x0bf40be4049f
 b40:	9f011103          	lh	sp,-1552(sp)
 b44:	f404                	.insn	2, 0xf404
 b46:	030c840b          	.insn	4, 0x030c840b
 b4a:	0211                	.insn	2, 0x0211
 b4c:	049f 0c84 0c94      	.insn	6, 0x0c940c84049f
 b52:	9f031103          	lh	sp,-1552(t1)
 b56:	9404                	.insn	2, 0x9404
 b58:	a40c                	.insn	2, 0xa40c
 b5a:	030c                	.insn	2, 0x030c
 b5c:	0411                	.insn	2, 0x0411
 b5e:	049f 0ca4 0cb4      	.insn	6, 0x0cb40ca4049f
 b64:	9f051103          	lh	sp,-1552(a0)
 b68:	b404                	.insn	2, 0xb404
 b6a:	c40c                	.insn	2, 0xc40c
 b6c:	030c                	.insn	2, 0x030c
 b6e:	0611                	.insn	2, 0x0611
 b70:	049f 0cc4 0cd4      	.insn	6, 0x0cd40cc4049f
 b76:	9f071103          	lh	sp,-1552(a4)
 b7a:	d404                	.insn	2, 0xd404
 b7c:	dc0c                	.insn	2, 0xdc0c
 b7e:	030c                	.insn	2, 0x030c
 b80:	0811                	.insn	2, 0x0811
 b82:	009f e804 f00c      	.insn	6, 0xf00ce804009f
 b88:	030c                	.insn	2, 0x030c
 b8a:	0811                	.insn	2, 0x0811
 b8c:	049f 0cf0 0cf8      	.insn	6, 0x0cf80cf0049f
 b92:	9f091103          	lh	sp,-1552(s2)
 b96:	f804                	.insn	2, 0xf804
 b98:	880c                	.insn	2, 0x880c
 b9a:	030d                	.insn	2, 0x030d
 b9c:	0a11                	.insn	2, 0x0a11
 b9e:	049f 0dcc 0dd4      	.insn	6, 0x0dd40dcc049f
 ba4:	9f081103          	lh	sp,-1552(a6)
 ba8:	d404                	.insn	2, 0xd404
 baa:	e40d                	.insn	2, 0xe40d
 bac:	030d                	.insn	2, 0x030d
 bae:	0911                	.insn	2, 0x0911
 bb0:	049f 0de4 0df0      	.insn	6, 0x0df00de4049f
 bb6:	9f0a1103          	lh	sp,-1552(s4)
 bba:	0400                	.insn	2, 0x0400
 bbc:	0df0                	.insn	2, 0x0df0
 bbe:	0e90                	.insn	2, 0x0e90
 bc0:	5a01                	.insn	2, 0x5a01
 bc2:	9004                	.insn	2, 0x9004
 bc4:	880e                	.insn	2, 0x880e
 bc6:	0115                	.insn	2, 0x0115
 bc8:	0058                	.insn	2, 0x0058
 bca:	ac04                	.insn	2, 0xac04
 bcc:	b80e                	.insn	2, 0xb80e
 bce:	010e                	.insn	2, 0x010e
 bd0:	005a                	.insn	2, 0x005a
 bd2:	c004                	.insn	2, 0xc004
 bd4:	fc0e                	.insn	2, 0xfc0e
 bd6:	0114                	.insn	2, 0x0114
 bd8:	0059                	.insn	2, 0x0059
 bda:	dc04                	.insn	2, 0xdc04
 bdc:	e00e                	.insn	2, 0xe00e
 bde:	0058010f          	.insn	4, 0x0058010f
 be2:	dc04                	.insn	2, 0xdc04
 be4:	e40e                	.insn	2, 0xe40e
 be6:	030e                	.insn	2, 0x030e
 be8:	0011                	.insn	2, 0x0011
 bea:	049f 0ee4 0ee8      	.insn	6, 0x0ee80ee4049f
 bf0:	9f011103          	lh	sp,-1552(sp)
 bf4:	e804                	.insn	2, 0xe804
 bf6:	ec0e                	.insn	2, 0xec0e
 bf8:	030e                	.insn	2, 0x030e
 bfa:	0211                	.insn	2, 0x0211
 bfc:	049f 0eec 0ef0      	.insn	6, 0x0ef00eec049f
 c02:	9f031103          	lh	sp,-1552(t1)
 c06:	f004                	.insn	2, 0xf004
 c08:	f40e                	.insn	2, 0xf40e
 c0a:	030e                	.insn	2, 0x030e
 c0c:	0411                	.insn	2, 0x0411
 c0e:	049f 0ef4 0ef8      	.insn	6, 0x0ef80ef4049f
 c14:	9f051103          	lh	sp,-1552(a0)
 c18:	f804                	.insn	2, 0xf804
 c1a:	fc0e                	.insn	2, 0xfc0e
 c1c:	030e                	.insn	2, 0x030e
 c1e:	0611                	.insn	2, 0x0611
 c20:	049f 0efc 0f80      	.insn	6, 0x0f800efc049f
 c26:	9f071103          	lh	sp,-1552(a4)
 c2a:	8004                	.insn	2, 0x8004
 c2c:	030f840f          	.insn	4, 0x030f840f
 c30:	0811                	.insn	2, 0x0811
 c32:	049f 0f84 0f88      	.insn	6, 0x0f880f84049f
 c38:	9f091103          	lh	sp,-1552(s2)
 c3c:	8804                	.insn	2, 0x8804
 c3e:	030f8c0f          	.insn	4, 0x030f8c0f
 c42:	0a11                	.insn	2, 0x0a11
 c44:	049f 0f8c 10b4      	.insn	6, 0x10b40f8c049f
 c4a:	9f0b1103          	lh	sp,-1552(s6)
 c4e:	0400                	.insn	2, 0x0400
 c50:	0f8c                	.insn	2, 0x0f8c
 c52:	0fa0                	.insn	2, 0x0fa0
 c54:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 c58:	a004                	.insn	2, 0xa004
 c5a:	010fbc0f          	.insn	4, 0x010fbc0f
 c5e:	0fbc045b          	.insn	4, 0x0fbc045b
 c62:	0fcc                	.insn	2, 0x0fcc
 c64:	5f01                	.insn	2, 0x5f01
 c66:	cc04                	.insn	2, 0xcc04
 c68:	030fd40f          	.insn	4, 0x030fd40f
 c6c:	0011                	.insn	2, 0x0011
 c6e:	049f 0fd4 0fd8      	.insn	6, 0x0fd80fd4049f
 c74:	5b01                	.insn	2, 0x5b01
 c76:	fc04                	.insn	2, 0xfc04
 c78:	0310940f          	.insn	4, 0x0310940f
 c7c:	0811                	.insn	2, 0x0811
 c7e:	049f 1094 10b0      	.insn	6, 0x10b01094049f
 c84:	9f097c03          	.insn	4, 0x9f097c03
 c88:	0400                	.insn	2, 0x0400
 c8a:	10b4                	.insn	2, 0x10b4
 c8c:	10cc                	.insn	2, 0x10cc
 c8e:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 c92:	cc04                	.insn	2, 0xcc04
 c94:	e010                	.insn	2, 0xe010
 c96:	0310                	.insn	2, 0x0310
 c98:	0111                	.insn	2, 0x0111
 c9a:	049f 10e0 10f4      	.insn	6, 0x10f410e0049f
 ca0:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 ca4:	f404                	.insn	2, 0xf404
 ca6:	8810                	.insn	2, 0x8810
 ca8:	0311                	.insn	2, 0x0311
 caa:	0311                	.insn	2, 0x0311
 cac:	049f 1188 119c      	.insn	6, 0x119c1188049f
 cb2:	9f041103          	lh	sp,-1552(s0)
 cb6:	9c04                	.insn	2, 0x9c04
 cb8:	b011                	.insn	2, 0xb011
 cba:	0311                	.insn	2, 0x0311
 cbc:	0511                	.insn	2, 0x0511
 cbe:	049f 11b0 11c4      	.insn	6, 0x11c411b0049f
 cc4:	9f061103          	lh	sp,-1552(a2)
 cc8:	c404                	.insn	2, 0xc404
 cca:	d811                	.insn	2, 0xd811
 ccc:	0311                	.insn	2, 0x0311
 cce:	0711                	.insn	2, 0x0711
 cd0:	049f 11d8 11ec      	.insn	6, 0x11ec11d8049f
 cd6:	9f081103          	lh	sp,-1552(a6)
 cda:	ec04                	.insn	2, 0xec04
 cdc:	8011                	.insn	2, 0x8011
 cde:	0312                	.insn	2, 0x0312
 ce0:	0911                	.insn	2, 0x0911
 ce2:	049f 1280 1294      	.insn	6, 0x12941280049f
 ce8:	9f0a1103          	lh	sp,-1552(s4)
 cec:	9404                	.insn	2, 0x9404
 cee:	a812                	.insn	2, 0xa812
 cf0:	0312                	.insn	2, 0x0312
 cf2:	0b11                	.insn	2, 0x0b11
 cf4:	049f 12a8 12bc      	.insn	6, 0x12bc12a8049f
 cfa:	9f0c1103          	lh	sp,-1552(s8)
 cfe:	bc04                	.insn	2, 0xbc04
 d00:	d012                	.insn	2, 0xd012
 d02:	0312                	.insn	2, 0x0312
 d04:	0d11                	.insn	2, 0x0d11
 d06:	049f 12d0 12e4      	.insn	6, 0x12e412d0049f
 d0c:	9f0e1103          	lh	sp,-1552(t3)
 d10:	e404                	.insn	2, 0xe404
 d12:	f812                	.insn	2, 0xf812
 d14:	0312                	.insn	2, 0x0312
 d16:	0f11                	.insn	2, 0x0f11
 d18:	009f b404 d410      	.insn	6, 0xd410b404009f
 d1e:	0110                	.insn	2, 0x0110
 d20:	0462                	.insn	2, 0x0462
 d22:	10d4                	.insn	2, 0x10d4
 d24:	12f8                	.insn	2, 0x12f8
 d26:	5a01                	.insn	2, 0x5a01
 d28:	0400                	.insn	2, 0x0400
 d2a:	12f8                	.insn	2, 0x12f8
 d2c:	12fc                	.insn	2, 0x12fc
 d2e:	9f0c1103          	lh	sp,-1552(s8)
 d32:	fc04                	.insn	2, 0xfc04
 d34:	8012                	.insn	2, 0x8012
 d36:	0d110313          	addi	t1,sp,209
 d3a:	049f 1380 1384      	.insn	6, 0x13841380049f
 d40:	9f0e1103          	lh	sp,-1552(t3)
 d44:	8404                	.insn	2, 0x8404
 d46:	03138813          	addi	a6,t2,49
 d4a:	0f11                	.insn	2, 0x0f11
 d4c:	049f 1388 138c      	.insn	6, 0x138c1388049f
 d52:	9f101103          	lh	sp,-1551(zero) # fffff9f1 <USER_MAX+0xffaff9f1>
 d56:	8c04                	.insn	2, 0x8c04
 d58:	03139013          	slli	zero,t2,0x31
 d5c:	1111                	.insn	2, 0x1111
 d5e:	049f 1390 1394      	.insn	6, 0x13941390049f
 d64:	9f121103          	lh	sp,-1551(tp) # fffff9f1 <USER_MAX+0xffaff9f1>
 d68:	9404                	.insn	2, 0x9404
 d6a:	03139813          	slli	a6,t2,0x31
 d6e:	1311                	.insn	2, 0x1311
 d70:	049f 1398 13a4      	.insn	6, 0x13a41398049f
 d76:	9f161103          	lh	sp,-1551(a2)
 d7a:	a404                	.insn	2, 0xa404
 d7c:	0313a813          	slti	a6,t2,49
 d80:	1711                	.insn	2, 0x1711
 d82:	049f 13a8 13fc      	.insn	6, 0x13fc13a8049f
 d88:	9f181103          	lh	sp,-1551(a6)
 d8c:	fc04                	.insn	2, 0xfc04
 d8e:	03148013          	addi	zero,s1,49
 d92:	1911                	.insn	2, 0x1911
 d94:	049f 1480 14dc      	.insn	6, 0x14dc1480049f
 d9a:	9f201103          	lh	sp,-1550(zero) # fffff9f2 <USER_MAX+0xffaff9f2>
 d9e:	0400                	.insn	2, 0x0400
 da0:	13cc                	.insn	2, 0x13cc
 da2:	13d0                	.insn	2, 0x13d0
 da4:	9f011103          	lh	sp,-1552(sp)
 da8:	d004                	.insn	2, 0xd004
 daa:	0313d413          	srli	s0,t2,0x31
 dae:	0211                	.insn	2, 0x0211
 db0:	049f 13d4 13d8      	.insn	6, 0x13d813d4049f
 db6:	9f031103          	lh	sp,-1552(t1)
 dba:	d804                	.insn	2, 0xd804
 dbc:	0313e813          	ori	a6,t2,49
 dc0:	0411                	.insn	2, 0x0411
 dc2:	049f 13e8 13ec      	.insn	6, 0x13ec13e8049f
 dc8:	9f051103          	lh	sp,-1552(a0)
 dcc:	ec04                	.insn	2, 0xec04
 dce:	0313f013          	andi	zero,t2,49
 dd2:	0611                	.insn	2, 0x0611
 dd4:	049f 13f0 13f4      	.insn	6, 0x13f413f0049f
 dda:	9f071103          	lh	sp,-1552(a4)
 dde:	f404                	.insn	2, 0xf404
 de0:	0313f813          	andi	a6,t2,49
 de4:	0811                	.insn	2, 0x0811
 de6:	049f 13f8 1480      	.insn	6, 0x148013f8049f
 dec:	9f0b1103          	lh	sp,-1552(s6)
 df0:	8004                	.insn	2, 0x8004
 df2:	8c14                	.insn	2, 0x8c14
 df4:	0314                	.insn	2, 0x0314
 df6:	0011                	.insn	2, 0x0011
 df8:	049f 148c 1490      	.insn	6, 0x1490148c049f
 dfe:	9f091103          	lh	sp,-1552(s2)
 e02:	9004                	.insn	2, 0x9004
 e04:	dc14                	.insn	2, 0xdc14
 e06:	0314                	.insn	2, 0x0314
 e08:	0a11                	.insn	2, 0x0a11
 e0a:	009f                	.short	0x009f

Disassembly of section .debug_abbrev:

00000000 <.debug_abbrev>:
   0:	1101                	.insn	2, 0x1101
   2:	2501                	.insn	2, 0x2501
   4:	1325                	.insn	2, 0x1325
   6:	0305                	.insn	2, 0x0305
   8:	7225                	.insn	2, 0x7225
   a:	1b171017          	auipc	zero,0x1b171
   e:	1125                	.insn	2, 0x1125
  10:	7306121b          	.insn	4, 0x7306121b
  14:	8c177417          	auipc	s0,0x8c177
  18:	1701                	.insn	2, 0x1701
  1a:	0000                	.insn	2, 0x0000
  1c:	2402                	.insn	2, 0x2402
  1e:	0300                	.insn	2, 0x0300
  20:	3e25                	.insn	2, 0x3e25
  22:	000b0b0b          	.insn	4, 0x000b0b0b
  26:	0300                	.insn	2, 0x0300
  28:	0034                	.insn	2, 0x0034
  2a:	1349                	.insn	2, 0x1349
  2c:	0b3a                	.insn	2, 0x0b3a
  2e:	18020b3b          	.insn	4, 0x18020b3b
  32:	0000                	.insn	2, 0x0000
  34:	0104                	.insn	2, 0x0104
  36:	4901                	.insn	2, 0x4901
  38:	05000013          	li	zero,80
  3c:	0021                	.insn	2, 0x0021
  3e:	1349                	.insn	2, 0x1349
  40:	00000b37          	lui	s6,0x0
  44:	2406                	.insn	2, 0x2406
  46:	0300                	.insn	2, 0x0300
  48:	0b25                	.insn	2, 0x0b25
  4a:	000b3e0b          	.insn	4, 0x000b3e0b
  4e:	0700                	.insn	2, 0x0700
  50:	0034                	.insn	2, 0x0034
  52:	1349                	.insn	2, 0x1349
  54:	0b3a                	.insn	2, 0x0b3a
  56:	1802053b          	.insn	4, 0x1802053b
  5a:	0000                	.insn	2, 0x0000
  5c:	1608                	.insn	2, 0x1608
  5e:	4900                	.insn	2, 0x4900
  60:	3a250313          	addi	t1,a0,930
  64:	000b3b0b          	.insn	4, 0x000b3b0b
  68:	0900                	.insn	2, 0x0900
  6a:	012e                	.insn	2, 0x012e
  6c:	0b3a2503          	lw	a0,179(s4)
  70:	1927053b          	.insn	4, 0x1927053b
  74:	1349                	.insn	2, 0x1349
  76:	2120193f 0a000001 	.insn	8, 0x0a0000012120193f
  7e:	0005                	.insn	2, 0x0005
  80:	0b3a2503          	lw	a0,179(s4)
  84:	1349053b          	.insn	4, 0x1349053b
  88:	0000                	.insn	2, 0x0000
  8a:	0300340b          	.insn	4, 0x0300340b
  8e:	3a25                	.insn	2, 0x3a25
  90:	49053b0b          	.insn	4, 0x49053b0b
  94:	0c000013          	li	zero,192
  98:	0000010b          	.insn	4, 0x010b
  9c:	0f0d                	.insn	2, 0x0f0d
  9e:	4900                	.insn	2, 0x4900
  a0:	0e000013          	li	zero,224
  a4:	0026                	.insn	2, 0x0026
  a6:	1349                	.insn	2, 0x1349
  a8:	0000                	.insn	2, 0x0000
  aa:	11012e0f          	.insn	4, 0x11012e0f
  ae:	4006121b          	.insn	4, 0x4006121b
  b2:	7a18                	.insn	2, 0x7a18
  b4:	0319                	.insn	2, 0x0319
  b6:	3a25                	.insn	2, 0x3a25
  b8:	270b3b0b          	.insn	4, 0x270b3b0b
  bc:	3f19                	.insn	2, 0x3f19
  be:	0019                	.insn	2, 0x0019
  c0:	1000                	.insn	2, 0x1000
  c2:	0034                	.insn	2, 0x0034
  c4:	2202                	.insn	2, 0x2202
  c6:	0b3a2503          	lw	a0,179(s4)
  ca:	13490b3b          	.insn	4, 0x13490b3b
  ce:	0000                	.insn	2, 0x0000
  d0:	0b11                	.insn	2, 0x0b11
  d2:	1101                	.insn	2, 0x1101
  d4:	0006121b          	.insn	4, 0x0006121b
  d8:	1200                	.insn	2, 0x1200
  da:	0034                	.insn	2, 0x0034
  dc:	1802                	.insn	2, 0x1802
  de:	0b3a2503          	lw	a0,179(s4)
  e2:	13490b3b          	.insn	4, 0x13490b3b
  e6:	0000                	.insn	2, 0x0000
  e8:	03000a13          	li	s4,48
  ec:	3a25                	.insn	2, 0x3a25
  ee:	390b3b0b          	.insn	4, 0x390b3b0b
  f2:	001b110b          	.insn	4, 0x001b110b
  f6:	1400                	.insn	2, 0x1400
  f8:	2355010b          	.insn	4, 0x2355010b
  fc:	0000                	.insn	2, 0x0000
  fe:	3415                	.insn	2, 0x3415
 100:	0300                	.insn	2, 0x0300
 102:	3a25                	.insn	2, 0x3a25
 104:	490b3b0b          	.insn	4, 0x490b3b0b
 108:	16000013          	li	zero,352
 10c:	011d                	.insn	2, 0x011d
 10e:	1331                	.insn	2, 0x1331
 110:	2355                	.insn	2, 0x2355
 112:	0b58                	.insn	2, 0x0b58
 114:	0b59                	.insn	2, 0x0b59
 116:	00000b57          	.insn	4, 0x0b57
 11a:	02000517          	auipc	a0,0x2000
 11e:	3122                	.insn	2, 0x3122
 120:	18000013          	li	zero,384
 124:	0034                	.insn	2, 0x0034
 126:	2202                	.insn	2, 0x2202
 128:	1331                	.insn	2, 0x1331
 12a:	0000                	.insn	2, 0x0000
 12c:	0b19                	.insn	2, 0x0b19
 12e:	5501                	.insn	2, 0x5501
 130:	00133123          	.insn	4, 0x00133123
 134:	1a00                	.insn	2, 0x1a00
 136:	0048                	.insn	2, 0x0048
 138:	1b7d137f 2e1b0000 	.insn	12, 0x3a2503012e1b00001b7d137f
 140:	3a250301 
 144:	270b3b0b          	.insn	4, 0x270b3b0b
 148:	3c19                	.insn	2, 0x3c19
 14a:	3f19                	.insn	2, 0x3f19
 14c:	0019                	.insn	2, 0x0019
 14e:	1c00                	.insn	2, 0x1c00
 150:	0005                	.insn	2, 0x0005
 152:	1349                	.insn	2, 0x1349
 154:	0000                	.insn	2, 0x0000
 156:	181d                	.insn	2, 0x181d
 158:	0000                	.insn	2, 0x0000
 15a:	1e00                	.insn	2, 0x1e00
 15c:	002e                	.insn	2, 0x002e
 15e:	0b3a2503          	lw	a0,179(s4)
 162:	19270b3b          	.insn	4, 0x19270b3b
 166:	1349                	.insn	2, 0x1349
 168:	193c                	.insn	2, 0x193c
 16a:	0000193f 03012e1f 	.insn	8, 0x03012e1f0000193f
 172:	3a25                	.insn	2, 0x3a25
 174:	270b3b0b          	.insn	4, 0x270b3b0b
 178:	4919                	.insn	2, 0x4919
 17a:	3f193c13          	sltiu	s8,s2,1009
 17e:	0019                	.insn	2, 0x0019
 180:	2000                	.insn	2, 0x2000
 182:	012e                	.insn	2, 0x012e
 184:	1b11                	.insn	2, 0x1b11
 186:	0612                	.insn	2, 0x0612
 188:	1840                	.insn	2, 0x1840
 18a:	197a                	.insn	2, 0x197a
 18c:	0b3a2503          	lw	a0,179(s4)
 190:	1927053b          	.insn	4, 0x1927053b
 194:	0000193f 02000521 	.insn	8, 0x020005210000193f
 19c:	0322                	.insn	2, 0x0322
 19e:	3a25                	.insn	2, 0x3a25
 1a0:	49053b0b          	.insn	4, 0x49053b0b
 1a4:	22000013          	li	zero,544
 1a8:	0034                	.insn	2, 0x0034
 1aa:	2202                	.insn	2, 0x2202
 1ac:	0b3a2503          	lw	a0,179(s4)
 1b0:	1349053b          	.insn	4, 0x1349053b
 1b4:	0000                	.insn	2, 0x0000
 1b6:	7f004823          	.insn	4, 0x7f004823
 1ba:	19018213          	addi	tp,gp,400
 1be:	0181                	.insn	2, 0x0181
 1c0:	2400001b          	.insn	4, 0x2400001b
 1c4:	002e                	.insn	2, 0x002e
 1c6:	0b3a2503          	lw	a0,179(s4)
 1ca:	19270b3b          	.insn	4, 0x19270b3b
 1ce:	193c                	.insn	2, 0x193c
 1d0:	0000193f 03002e25 	.insn	8, 0x03002e250000193f
 1d8:	3a25                	.insn	2, 0x3a25
 1da:	270b3b0b          	.insn	4, 0x270b3b0b
 1de:	3c19                	.insn	2, 0x3c19
 1e0:	3f19                	.insn	2, 0x3f19
 1e2:	8719                	.insn	2, 0x8719
 1e4:	1901                	.insn	2, 0x1901
 1e6:	0000                	.insn	2, 0x0000
 1e8:	2e26                	.insn	2, 0x2e26
 1ea:	1101                	.insn	2, 0x1101
 1ec:	4006121b          	.insn	4, 0x4006121b
 1f0:	7a18                	.insn	2, 0x7a18
 1f2:	3119                	.insn	2, 0x3119
 1f4:	27000013          	li	zero,624
 1f8:	0005                	.insn	2, 0x0005
 1fa:	1802                	.insn	2, 0x1802
 1fc:	1331                	.insn	2, 0x1331
 1fe:	0000                	.insn	2, 0x0000
 200:	0100                	.insn	2, 0x0100
 202:	0111                	.insn	2, 0x0111
 204:	2525                	.insn	2, 0x2525
 206:	25030513          	addi	a0,t1,592
 20a:	1772                	.insn	2, 0x1772
 20c:	1710                	.insn	2, 0x1710
 20e:	0111251b          	.insn	4, 0x0111251b
 212:	2355                	.insn	2, 0x2355
 214:	17741773          	csrrw	a4,0x177,s0
 218:	018c                	.insn	2, 0x018c
 21a:	02000017          	auipc	zero,0x2000
 21e:	0034                	.insn	2, 0x0034
 220:	1349                	.insn	2, 0x1349
 222:	0b3a                	.insn	2, 0x0b3a
 224:	18020b3b          	.insn	4, 0x18020b3b
 228:	0000                	.insn	2, 0x0000
 22a:	49010103          	lb	sp,1168(sp)
 22e:	04000013          	li	zero,64
 232:	0021                	.insn	2, 0x0021
 234:	1349                	.insn	2, 0x1349
 236:	00000b37          	lui	s6,0x0
 23a:	2405                	.insn	2, 0x2405
 23c:	0300                	.insn	2, 0x0300
 23e:	3e25                	.insn	2, 0x3e25
 240:	000b0b0b          	.insn	4, 0x000b0b0b
 244:	0600                	.insn	2, 0x0600
 246:	0024                	.insn	2, 0x0024
 248:	0b0b2503          	lw	a0,176(s6) # b0 <start-0x3fff50>
 24c:	0b3e                	.insn	2, 0x0b3e
 24e:	0000                	.insn	2, 0x0000
 250:	49003407          	.insn	4, 0x49003407
 254:	3b0b3a13          	sltiu	s4,s6,944
 258:	0205                	.insn	2, 0x0205
 25a:	0018                	.insn	2, 0x0018
 25c:	0800                	.insn	2, 0x0800
 25e:	0016                	.insn	2, 0x0016
 260:	1349                	.insn	2, 0x1349
 262:	0b3a2503          	lw	a0,179(s4)
 266:	0000053b          	.insn	4, 0x053b
 26a:	1609                	.insn	2, 0x1609
 26c:	4900                	.insn	2, 0x4900
 26e:	3a250313          	addi	t1,a0,930 # 20004bc <USER_MAX+0x1b004bc>
 272:	000b3b0b          	.insn	4, 0x000b3b0b
 276:	0a00                	.insn	2, 0x0a00
 278:	1349000f          	.insn	4, 0x1349000f
 27c:	0000                	.insn	2, 0x0000
 27e:	03012e0b          	.insn	4, 0x03012e0b
 282:	3a25                	.insn	2, 0x3a25
 284:	270b3b0b          	.insn	4, 0x270b3b0b
 288:	4919                	.insn	2, 0x4919
 28a:	01212013          	slti	zero,sp,18
 28e:	0000                	.insn	2, 0x0000
 290:	050c                	.insn	2, 0x050c
 292:	0300                	.insn	2, 0x0300
 294:	3a25                	.insn	2, 0x3a25
 296:	490b3b0b          	.insn	4, 0x490b3b0b
 29a:	0d000013          	li	zero,208
 29e:	0034                	.insn	2, 0x0034
 2a0:	0b3a2503          	lw	a0,179(s4)
 2a4:	13490b3b          	.insn	4, 0x13490b3b
 2a8:	0000                	.insn	2, 0x0000
 2aa:	2e0e                	.insn	2, 0x2e0e
 2ac:	1101                	.insn	2, 0x1101
 2ae:	4006121b          	.insn	4, 0x4006121b
 2b2:	7a18                	.insn	2, 0x7a18
 2b4:	0319                	.insn	2, 0x0319
 2b6:	3a25                	.insn	2, 0x3a25
 2b8:	270b3b0b          	.insn	4, 0x270b3b0b
 2bc:	3f19                	.insn	2, 0x3f19
 2be:	8719                	.insn	2, 0x8719
 2c0:	1901                	.insn	2, 0x1901
 2c2:	0000                	.insn	2, 0x0000
 2c4:	31011d0f          	.insn	4, 0x31011d0f
 2c8:	121b1113          	.insn	4, 0x121b1113
 2cc:	5806                	.insn	2, 0x5806
 2ce:	570b590b          	.insn	4, 0x570b590b
 2d2:	1000000b          	.insn	4, 0x1000000b
 2d6:	0005                	.insn	2, 0x0005
 2d8:	0d1c                	.insn	2, 0x0d1c
 2da:	1331                	.insn	2, 0x1331
 2dc:	0000                	.insn	2, 0x0000
 2de:	3411                	.insn	2, 0x3411
 2e0:	0200                	.insn	2, 0x0200
 2e2:	3122                	.insn	2, 0x3122
 2e4:	12000013          	li	zero,288
 2e8:	0034                	.insn	2, 0x0034
 2ea:	0d1c                	.insn	2, 0x0d1c
 2ec:	1331                	.insn	2, 0x1331
 2ee:	0000                	.insn	2, 0x0000
 2f0:	03012e13          	slti	t3,sp,48
 2f4:	3a25                	.insn	2, 0x3a25
 2f6:	27053b0b          	.insn	4, 0x27053b0b
 2fa:	4919                	.insn	2, 0x4919
 2fc:	01212013          	slti	zero,sp,18
 300:	0000                	.insn	2, 0x0000
 302:	0514                	.insn	2, 0x0514
 304:	0300                	.insn	2, 0x0300
 306:	3a25                	.insn	2, 0x3a25
 308:	49053b0b          	.insn	4, 0x49053b0b
 30c:	15000013          	li	zero,336
 310:	0034                	.insn	2, 0x0034
 312:	0b3a2503          	lw	a0,179(s4)
 316:	1349053b          	.insn	4, 0x1349053b
 31a:	0000                	.insn	2, 0x0000
 31c:	2e16                	.insn	2, 0x2e16
 31e:	0301                	.insn	2, 0x0301
 320:	3a25                	.insn	2, 0x3a25
 322:	27053b0b          	.insn	4, 0x27053b0b
 326:	3f19                	.insn	2, 0x3f19
 328:	2019                	.insn	2, 0x2019
 32a:	0121                	.insn	2, 0x0121
 32c:	0000                	.insn	2, 0x0000
 32e:	11012e17          	auipc	t3,0x11012
 332:	4006121b          	.insn	4, 0x4006121b
 336:	7a18                	.insn	2, 0x7a18
 338:	0319                	.insn	2, 0x0319
 33a:	3a25                	.insn	2, 0x3a25
 33c:	270b3b0b          	.insn	4, 0x270b3b0b
 340:	3f19                	.insn	2, 0x3f19
 342:	0019                	.insn	2, 0x0019
 344:	1800                	.insn	2, 0x1800
 346:	0005                	.insn	2, 0x0005
 348:	2202                	.insn	2, 0x2202
 34a:	0b3a2503          	lw	a0,179(s4)
 34e:	13490b3b          	.insn	4, 0x13490b3b
 352:	0000                	.insn	2, 0x0000
 354:	3419                	.insn	2, 0x3419
 356:	0200                	.insn	2, 0x0200
 358:	0318                	.insn	2, 0x0318
 35a:	3a25                	.insn	2, 0x3a25
 35c:	490b3b0b          	.insn	4, 0x490b3b0b
 360:	1a000013          	li	zero,416
 364:	1b11010b          	.insn	4, 0x1b11010b
 368:	0612                	.insn	2, 0x0612
 36a:	0000                	.insn	2, 0x0000
 36c:	0200341b          	.insn	4, 0x0200341b
 370:	0322                	.insn	2, 0x0322
 372:	3a25                	.insn	2, 0x3a25
 374:	490b3b0b          	.insn	4, 0x490b3b0b
 378:	1c000013          	li	zero,448
 37c:	2355010b          	.insn	4, 0x2355010b
 380:	0000                	.insn	2, 0x0000
 382:	051d                	.insn	2, 0x051d
 384:	0200                	.insn	2, 0x0200
 386:	3118                	.insn	2, 0x3118
 388:	1e000013          	li	zero,480
 38c:	0034                	.insn	2, 0x0034
 38e:	1802                	.insn	2, 0x1802
 390:	1331                	.insn	2, 0x1331
 392:	0000                	.insn	2, 0x0000
 394:	051f 1c00 310f      	.insn	6, 0x310f1c00051f
 39a:	20000013          	li	zero,512
 39e:	0048                	.insn	2, 0x0048
 3a0:	0182137f 1b018119 	.insn	12, 0x2e2100001b0181190182137f
 3a8:	2e210000 
 3ac:	1101                	.insn	2, 0x1101
 3ae:	4006121b          	.insn	4, 0x4006121b
 3b2:	7a18                	.insn	2, 0x7a18
 3b4:	0319                	.insn	2, 0x0319
 3b6:	3a25                	.insn	2, 0x3a25
 3b8:	27053b0b          	.insn	4, 0x27053b0b
 3bc:	3f19                	.insn	2, 0x3f19
 3be:	0019                	.insn	2, 0x0019
 3c0:	2200                	.insn	2, 0x2200
 3c2:	0005                	.insn	2, 0x0005
 3c4:	2202                	.insn	2, 0x2202
 3c6:	0b3a2503          	lw	a0,179(s4)
 3ca:	1349053b          	.insn	4, 0x1349053b
 3ce:	0000                	.insn	2, 0x0000
 3d0:	02003423          	.insn	4, 0x02003423
 3d4:	0318                	.insn	2, 0x0318
 3d6:	3a25                	.insn	2, 0x3a25
 3d8:	49053b0b          	.insn	4, 0x49053b0b
 3dc:	24000013          	li	zero,576
 3e0:	000a                	.insn	2, 0x000a
 3e2:	0b3a2503          	lw	a0,179(s4)
 3e6:	0b39053b          	.insn	4, 0x0b39053b
 3ea:	1b11                	.insn	2, 0x1b11
 3ec:	0000                	.insn	2, 0x0000
 3ee:	3425                	.insn	2, 0x3425
 3f0:	0200                	.insn	2, 0x0200
 3f2:	0322                	.insn	2, 0x0322
 3f4:	3a25                	.insn	2, 0x3a25
 3f6:	49053b0b          	.insn	4, 0x49053b0b
 3fa:	26000013          	li	zero,608
 3fe:	011d                	.insn	2, 0x011d
 400:	1331                	.insn	2, 0x1331
 402:	1b11                	.insn	2, 0x1b11
 404:	0612                	.insn	2, 0x0612
 406:	0b58                	.insn	2, 0x0b58
 408:	0559                	.insn	2, 0x0559
 40a:	00000b57          	.insn	4, 0x0b57
 40e:	31001d27          	.insn	4, 0x31001d27
 412:	121b1113          	.insn	4, 0x121b1113
 416:	5806                	.insn	2, 0x5806
 418:	5705590b          	.insn	4, 0x5705590b
 41c:	2800000b          	.insn	4, 0x2800000b
 420:	001d                	.insn	2, 0x001d
 422:	1331                	.insn	2, 0x1331
 424:	2355                	.insn	2, 0x2355
 426:	0b58                	.insn	2, 0x0b58
 428:	0559                	.insn	2, 0x0559
 42a:	00000b57          	.insn	4, 0x0b57
 42e:	1829                	.insn	2, 0x1829
 430:	0000                	.insn	2, 0x0000
 432:	2a00                	.insn	2, 0x2a00
 434:	012e                	.insn	2, 0x012e
 436:	1b11                	.insn	2, 0x1b11
 438:	0612                	.insn	2, 0x0612
 43a:	1840                	.insn	2, 0x1840
 43c:	197a                	.insn	2, 0x197a
 43e:	1331                	.insn	2, 0x1331
 440:	0000                	.insn	2, 0x0000
 442:	0200052b          	.insn	4, 0x0200052b
 446:	3122                	.insn	2, 0x3122
 448:	2c000013          	li	zero,704
 44c:	0034                	.insn	2, 0x0034
 44e:	0f1c                	.insn	2, 0x0f1c
 450:	1331                	.insn	2, 0x1331
 452:	0000                	.insn	2, 0x0000
 454:	2e2d                	.insn	2, 0x2e2d
 456:	1101                	.insn	2, 0x1101
 458:	4006121b          	.insn	4, 0x4006121b
 45c:	7a18                	.insn	2, 0x7a18
 45e:	0319                	.insn	2, 0x0319
 460:	3a25                	.insn	2, 0x3a25
 462:	270b3b0b          	.insn	4, 0x270b3b0b
 466:	4919                	.insn	2, 0x4919
 468:	00193f13          	seqz	t5,s2
 46c:	2e00                	.insn	2, 0x2e00
 46e:	0048                	.insn	2, 0x0048
 470:	1b7d137f 2e2f0000 	.insn	12, 0x3a2503012e2f00001b7d137f
 478:	3a250301 
 47c:	270b3b0b          	.insn	4, 0x270b3b0b
 480:	4919                	.insn	2, 0x4919
 482:	3f193c13          	sltiu	s8,s2,1009
 486:	0019                	.insn	2, 0x0019
 488:	3000                	.insn	2, 0x3000
 48a:	0005                	.insn	2, 0x0005
 48c:	1349                	.insn	2, 0x1349
 48e:	0000                	.insn	2, 0x0000
 490:	2631                	.insn	2, 0x2631
 492:	4900                	.insn	2, 0x4900
 494:	32000013          	li	zero,800
 498:	012e                	.insn	2, 0x012e
 49a:	1b11                	.insn	2, 0x1b11
 49c:	0612                	.insn	2, 0x0612
 49e:	1840                	.insn	2, 0x1840
 4a0:	197a                	.insn	2, 0x197a
 4a2:	0b3a2503          	lw	a0,179(s4)
 4a6:	1927053b          	.insn	4, 0x1927053b
 4aa:	1349                	.insn	2, 0x1349
 4ac:	0000193f 02000533 	.insn	8, 0x020005330000193f
 4b4:	0318                	.insn	2, 0x0318
 4b6:	3a25                	.insn	2, 0x3a25
 4b8:	49053b0b          	.insn	4, 0x49053b0b
 4bc:	34000013          	li	zero,832
 4c0:	012e                	.insn	2, 0x012e
 4c2:	0b3a2503          	lw	a0,179(s4)
 4c6:	1927053b          	.insn	4, 0x1927053b
 4ca:	1349                	.insn	2, 0x1349
 4cc:	2120193f 35000001 	.insn	8, 0x350000012120193f
 4d4:	012e                	.insn	2, 0x012e
 4d6:	0b3a2503          	lw	a0,179(s4)
 4da:	1927053b          	.insn	4, 0x1927053b
 4de:	2120                	.insn	2, 0x2120
 4e0:	0001                	.insn	2, 0x0001
 4e2:	3600                	.insn	2, 0x3600
 4e4:	0034                	.insn	2, 0x0034
 4e6:	0f1c                	.insn	2, 0x0f1c
 4e8:	0b3a2503          	lw	a0,179(s4)
 4ec:	1349053b          	.insn	4, 0x1349053b
 4f0:	0000                	.insn	2, 0x0000
 4f2:	11002e37          	lui	t3,0x11002
 4f6:	4006121b          	.insn	4, 0x4006121b
 4fa:	7a18                	.insn	2, 0x7a18
 4fc:	0319                	.insn	2, 0x0319
 4fe:	3a25                	.insn	2, 0x3a25
 500:	27053b0b          	.insn	4, 0x27053b0b
 504:	3f19                	.insn	2, 0x3f19
 506:	0019                	.insn	2, 0x0019
 508:	3800                	.insn	2, 0x3800
 50a:	0021                	.insn	2, 0x0021
 50c:	1349                	.insn	2, 0x1349
 50e:	00000537          	lui	a0,0x0
 512:	1639                	.insn	2, 0x1639
 514:	4900                	.insn	2, 0x4900
 516:	00250313          	addi	t1,a0,2 # 2 <start-0x3ffffe>
 51a:	3a00                	.insn	2, 0x3a00
 51c:	0000000f          	fence	unknown,unknown
 520:	0100                	.insn	2, 0x0100
 522:	0111                	.insn	2, 0x0111
 524:	2525                	.insn	2, 0x2525
 526:	25030513          	addi	a0,t1,592
 52a:	1772                	.insn	2, 0x1772
 52c:	1710                	.insn	2, 0x1710
 52e:	1b11251b          	.insn	4, 0x1b11251b
 532:	0612                	.insn	2, 0x0612
 534:	17741773          	csrrw	a4,0x177,s0
 538:	018c                	.insn	2, 0x018c
 53a:	02000017          	auipc	zero,0x2000
 53e:	0034                	.insn	2, 0x0034
 540:	1349                	.insn	2, 0x1349
 542:	0b3a                	.insn	2, 0x0b3a
 544:	18020b3b          	.insn	4, 0x18020b3b
 548:	0000                	.insn	2, 0x0000
 54a:	49010103          	lb	sp,1168(sp)
 54e:	04000013          	li	zero,64
 552:	0021                	.insn	2, 0x0021
 554:	1349                	.insn	2, 0x1349
 556:	00000b37          	lui	s6,0x0
 55a:	2405                	.insn	2, 0x2405
 55c:	0300                	.insn	2, 0x0300
 55e:	3e25                	.insn	2, 0x3e25
 560:	000b0b0b          	.insn	4, 0x000b0b0b
 564:	0600                	.insn	2, 0x0600
 566:	0024                	.insn	2, 0x0024
 568:	0b0b2503          	lw	a0,176(s6) # b0 <start-0x3fff50>
 56c:	0b3e                	.insn	2, 0x0b3e
 56e:	0000                	.insn	2, 0x0000
 570:	49003407          	.insn	4, 0x49003407
 574:	3b0b3a13          	sltiu	s4,s6,944
 578:	0205                	.insn	2, 0x0205
 57a:	0018                	.insn	2, 0x0018
 57c:	0800                	.insn	2, 0x0800
 57e:	0034                	.insn	2, 0x0034
 580:	13492503          	lw	a0,308(s2)
 584:	0b3a                	.insn	2, 0x0b3a
 586:	18020b3b          	.insn	4, 0x18020b3b
 58a:	0000                	.insn	2, 0x0000
 58c:	2109                	.insn	2, 0x2109
 58e:	4900                	.insn	2, 0x4900
 590:	00053713          	sltiu	a4,a0,0
 594:	0a00                	.insn	2, 0x0a00
 596:	0016                	.insn	2, 0x0016
 598:	1349                	.insn	2, 0x1349
 59a:	0b3a2503          	lw	a0,179(s4)
 59e:	00000b3b          	.insn	4, 0x0b3b
 5a2:	0300340b          	.insn	4, 0x0300340b
 5a6:	4925                	.insn	2, 0x4925
 5a8:	3a193f13          	sltiu	t5,s2,929
 5ac:	020b3b0b          	.insn	4, 0x020b3b0b
 5b0:	0018                	.insn	2, 0x0018
 5b2:	0c00                	.insn	2, 0x0c00
 5b4:	0b0b0113          	addi	sp,s6,176
 5b8:	0b3a                	.insn	2, 0x0b3a
 5ba:	00000b3b          	.insn	4, 0x0b3b
 5be:	0d0d                	.insn	2, 0x0d0d
 5c0:	0300                	.insn	2, 0x0300
 5c2:	4925                	.insn	2, 0x4925
 5c4:	3b0b3a13          	sltiu	s4,s6,944
 5c8:	000b380b          	.insn	4, 0x000b380b
 5cc:	0e00                	.insn	2, 0x0e00
 5ce:	012e                	.insn	2, 0x012e
 5d0:	0b3a2503          	lw	a0,179(s4)
 5d4:	19270b3b          	.insn	4, 0x19270b3b
 5d8:	1349                	.insn	2, 0x1349
 5da:	2120193f 0f000001 	.insn	8, 0x0f0000012120193f
 5e2:	0005                	.insn	2, 0x0005
 5e4:	0b3a2503          	lw	a0,179(s4)
 5e8:	13490b3b          	.insn	4, 0x13490b3b
 5ec:	0000                	.insn	2, 0x0000
 5ee:	2e10                	.insn	2, 0x2e10
 5f0:	1101                	.insn	2, 0x1101
 5f2:	4006121b          	.insn	4, 0x4006121b
 5f6:	7a18                	.insn	2, 0x7a18
 5f8:	0319                	.insn	2, 0x0319
 5fa:	3a25                	.insn	2, 0x3a25
 5fc:	270b3b0b          	.insn	4, 0x270b3b0b
 600:	4919                	.insn	2, 0x4919
 602:	00193f13          	seqz	t5,s2
 606:	1100                	.insn	2, 0x1100
 608:	0005                	.insn	2, 0x0005
 60a:	2202                	.insn	2, 0x2202
 60c:	0b3a2503          	lw	a0,179(s4)
 610:	13490b3b          	.insn	4, 0x13490b3b
 614:	0000                	.insn	2, 0x0000
 616:	3412                	.insn	2, 0x3412
 618:	0200                	.insn	2, 0x0200
 61a:	0318                	.insn	2, 0x0318
 61c:	3a25                	.insn	2, 0x3a25
 61e:	490b3b0b          	.insn	4, 0x490b3b0b
 622:	13000013          	li	zero,304
 626:	0034                	.insn	2, 0x0034
 628:	2202                	.insn	2, 0x2202
 62a:	0b3a2503          	lw	a0,179(s4)
 62e:	13490b3b          	.insn	4, 0x13490b3b
 632:	0000                	.insn	2, 0x0000
 634:	1d14                	.insn	2, 0x1d14
 636:	3101                	.insn	2, 0x3101
 638:	121b1113          	.insn	4, 0x121b1113
 63c:	5806                	.insn	2, 0x5806
 63e:	570b590b          	.insn	4, 0x570b590b
 642:	1500000b          	.insn	4, 0x1500000b
 646:	0005                	.insn	2, 0x0005
 648:	2202                	.insn	2, 0x2202
 64a:	1331                	.insn	2, 0x1331
 64c:	0000                	.insn	2, 0x0000
 64e:	0b16                	.insn	2, 0x0b16
 650:	1101                	.insn	2, 0x1101
 652:	0006121b          	.insn	4, 0x0006121b
 656:	1700                	.insn	2, 0x1700
 658:	0048                	.insn	2, 0x0048
 65a:	1b7d137f 34180000 	.insn	12, 0x3a250300341800001b7d137f
 662:	3a250300 
 666:	490b3b0b          	.insn	4, 0x490b3b0b
 66a:	19000013          	li	zero,400
 66e:	2355010b          	.insn	4, 0x2355010b
 672:	0000                	.insn	2, 0x0000
 674:	2e1a                	.insn	2, 0x2e1a
 676:	0301                	.insn	2, 0x0301
 678:	3a25                	.insn	2, 0x3a25
 67a:	270b3b0b          	.insn	4, 0x270b3b0b
 67e:	3c19                	.insn	2, 0x3c19
 680:	3f19                	.insn	2, 0x3f19
 682:	0019                	.insn	2, 0x0019
 684:	1b00                	.insn	2, 0x1b00
 686:	0005                	.insn	2, 0x0005
 688:	1349                	.insn	2, 0x1349
 68a:	0000                	.insn	2, 0x0000
 68c:	181c                	.insn	2, 0x181c
 68e:	0000                	.insn	2, 0x0000
 690:	1d00                	.insn	2, 0x1d00
 692:	1349000f          	.insn	4, 0x1349000f
 696:	0000                	.insn	2, 0x0000
 698:	261e                	.insn	2, 0x261e
 69a:	4900                	.insn	2, 0x4900
 69c:	1f000013          	li	zero,496
 6a0:	012e                	.insn	2, 0x012e
 6a2:	0b3a2503          	lw	a0,179(s4)
 6a6:	19270b3b          	.insn	4, 0x19270b3b
 6aa:	1349                	.insn	2, 0x1349
 6ac:	193c                	.insn	2, 0x193c
 6ae:	0000193f 00000f20 	.insn	8, 0x0f200000193f
 6b6:	2100                	.insn	2, 0x2100
 6b8:	012e                	.insn	2, 0x012e
 6ba:	1b11                	.insn	2, 0x1b11
 6bc:	0612                	.insn	2, 0x0612
 6be:	1840                	.insn	2, 0x1840
 6c0:	197a                	.insn	2, 0x197a
 6c2:	1331                	.insn	2, 0x1331
 6c4:	0000                	.insn	2, 0x0000
 6c6:	2e22                	.insn	2, 0x2e22
 6c8:	1101                	.insn	2, 0x1101
 6ca:	4006121b          	.insn	4, 0x4006121b
 6ce:	7a18                	.insn	2, 0x7a18
 6d0:	0319                	.insn	2, 0x0319
 6d2:	3a25                	.insn	2, 0x3a25
 6d4:	270b3b0b          	.insn	4, 0x270b3b0b
 6d8:	3f19                	.insn	2, 0x3f19
 6da:	0019                	.insn	2, 0x0019
 6dc:	2300                	.insn	2, 0x2300
 6de:	0005                	.insn	2, 0x0005
 6e0:	1802                	.insn	2, 0x1802
 6e2:	1331                	.insn	2, 0x1331
 6e4:	0000                	.insn	2, 0x0000
 6e6:	2e24                	.insn	2, 0x2e24
 6e8:	0301                	.insn	2, 0x0301
 6ea:	3a25                	.insn	2, 0x3a25
 6ec:	270b3b0b          	.insn	4, 0x270b3b0b
 6f0:	4919                	.insn	2, 0x4919
 6f2:	01212013          	slti	zero,sp,18
 6f6:	0000                	.insn	2, 0x0000
 6f8:	3425                	.insn	2, 0x3425
 6fa:	0300                	.insn	2, 0x0300
 6fc:	3a25                	.insn	2, 0x3a25
 6fe:	49053b0b          	.insn	4, 0x49053b0b
 702:	26000013          	li	zero,608
 706:	012e                	.insn	2, 0x012e
 708:	1b11                	.insn	2, 0x1b11
 70a:	0612                	.insn	2, 0x0612
 70c:	1840                	.insn	2, 0x1840
 70e:	197a                	.insn	2, 0x197a
 710:	0b3a2503          	lw	a0,179(s4)
 714:	1927053b          	.insn	4, 0x1927053b
 718:	1349                	.insn	2, 0x1349
 71a:	0000193f 02000527 	.insn	8, 0x020005270000193f
 722:	0322                	.insn	2, 0x0322
 724:	3a25                	.insn	2, 0x3a25
 726:	49053b0b          	.insn	4, 0x49053b0b
 72a:	28000013          	li	zero,640
 72e:	0034                	.insn	2, 0x0034
 730:	1802                	.insn	2, 0x1802
 732:	0b3a2503          	lw	a0,179(s4)
 736:	1349053b          	.insn	4, 0x1349053b
 73a:	0000                	.insn	2, 0x0000
 73c:	3429                	.insn	2, 0x3429
 73e:	0200                	.insn	2, 0x0200
 740:	0322                	.insn	2, 0x0322
 742:	3a25                	.insn	2, 0x3a25
 744:	49053b0b          	.insn	4, 0x49053b0b
 748:	2a000013          	li	zero,672
 74c:	011d                	.insn	2, 0x011d
 74e:	1331                	.insn	2, 0x1331
 750:	1b11                	.insn	2, 0x1b11
 752:	0612                	.insn	2, 0x0612
 754:	0b58                	.insn	2, 0x0b58
 756:	0559                	.insn	2, 0x0559
 758:	00000b57          	.insn	4, 0x0b57
 75c:	0200342b          	.insn	4, 0x0200342b
 760:	3122                	.insn	2, 0x3122
 762:	00000013          	nop

Disassembly of section .debug_info:

00000000 <.debug_info>:
       0:	07b8                	.insn	2, 0x07b8
       2:	0000                	.insn	2, 0x0000
       4:	0005                	.insn	2, 0x0005
       6:	0401                	.insn	2, 0x0401
       8:	0000                	.insn	2, 0x0000
       a:	0000                	.insn	2, 0x0000
       c:	0001                	.insn	2, 0x0001
       e:	001d                	.insn	2, 0x001d
      10:	0801                	.insn	2, 0x0801
      12:	0000                	.insn	2, 0x0000
      14:	0000                	.insn	2, 0x0000
      16:	0000                	.insn	2, 0x0000
      18:	0200                	.insn	2, 0x0200
      1a:	142a                	.insn	2, 0x142a
      1c:	000a                	.insn	2, 0x000a
      1e:	0800                	.insn	2, 0x0800
      20:	0000                	.insn	2, 0x0000
      22:	0c00                	.insn	2, 0x0c00
      24:	0000                	.insn	2, 0x0000
      26:	0c00                	.insn	2, 0x0c00
      28:	0000                	.insn	2, 0x0000
      2a:	0200                	.insn	2, 0x0200
      2c:	0724                	.insn	2, 0x0724
      2e:	0201                	.insn	2, 0x0201
      30:	03040723          	sb	a6,46(s0) # 8c177042 <USER_MAX+0x8bc77042>
      34:	003d                	.insn	2, 0x003d
      36:	0000                	.insn	2, 0x0000
      38:	1001                	.insn	2, 0x1001
      3a:	a102                	.insn	2, 0xa102
      3c:	0400                	.insn	2, 0x0400
      3e:	0049                	.insn	2, 0x0049
      40:	0000                	.insn	2, 0x0000
      42:	4d05                	.insn	2, 0x4d05
      44:	0000                	.insn	2, 0x0000
      46:	0e00                	.insn	2, 0x0e00
      48:	0200                	.insn	2, 0x0200
      4a:	06010803          	lb	a6,96(sp)
      4e:	0804                	.insn	2, 0x0804
      50:	005b0307          	.insn	4, 0x005b0307
      54:	0000                	.insn	2, 0x0000
      56:	3b01                	.insn	2, 0x3b01
      58:	a102                	.insn	2, 0xa102
      5a:	0401                	.insn	2, 0x0401
      5c:	0049                	.insn	2, 0x0049
      5e:	0000                	.insn	2, 0x0000
      60:	4d05                	.insn	2, 0x4d05
      62:	0000                	.insn	2, 0x0000
      64:	0d00                	.insn	2, 0x0d00
      66:	0300                	.insn	2, 0x0300
      68:	0000005b          	.insn	4, 0x005b
      6c:	4001                	.insn	2, 0x4001
      6e:	a102                	.insn	2, 0xa102
      70:	0302                	.insn	2, 0x0302
      72:	0000007b          	.insn	4, 0x007b
      76:	9101                	.insn	2, 0x9101
      78:	a102                	.insn	2, 0xa102
      7a:	00490403          	lb	s0,4(s2)
      7e:	0000                	.insn	2, 0x0000
      80:	4d05                	.insn	2, 0x4d05
      82:	0000                	.insn	2, 0x0000
      84:	0600                	.insn	2, 0x0600
      86:	0300                	.insn	2, 0x0300
      88:	0091                	.insn	2, 0x0091
      8a:	0000                	.insn	2, 0x0000
      8c:	9201                	.insn	2, 0x9201
      8e:	a102                	.insn	2, 0xa102
      90:	0404                	.insn	2, 0x0404
      92:	0049                	.insn	2, 0x0049
      94:	0000                	.insn	2, 0x0000
      96:	4d05                	.insn	2, 0x4d05
      98:	0000                	.insn	2, 0x0000
      9a:	1900                	.insn	2, 0x1900
      9c:	0300                	.insn	2, 0x0300
      9e:	000000a7          	.insn	4, 0x00a7
      a2:	9501                	.insn	2, 0x9501
      a4:	a102                	.insn	2, 0xa102
      a6:	0405                	.insn	2, 0x0405
      a8:	0049                	.insn	2, 0x0049
      aa:	0000                	.insn	2, 0x0000
      ac:	4d05                	.insn	2, 0x4d05
      ae:	0000                	.insn	2, 0x0000
      b0:	0500                	.insn	2, 0x0500
      b2:	0300                	.insn	2, 0x0300
      b4:	00bd                	.insn	2, 0x00bd
      b6:	0000                	.insn	2, 0x0000
      b8:	b201                	.insn	2, 0xb201
      ba:	a102                	.insn	2, 0xa102
      bc:	0406                	.insn	2, 0x0406
      be:	0049                	.insn	2, 0x0049
      c0:	0000                	.insn	2, 0x0000
      c2:	4d05                	.insn	2, 0x4d05
      c4:	0000                	.insn	2, 0x0000
      c6:	0700                	.insn	2, 0x0700
      c8:	0300                	.insn	2, 0x0300
      ca:	000000d3          	.insn	4, 0x00d3
      ce:	b701                	.insn	2, 0xb701
      d0:	a102                	.insn	2, 0xa102
      d2:	00490407          	.insn	4, 0x00490407
      d6:	0000                	.insn	2, 0x0000
      d8:	4d05                	.insn	2, 0x4d05
      da:	0000                	.insn	2, 0x0000
      dc:	1a00                	.insn	2, 0x1a00
      de:	0300                	.insn	2, 0x0300
      e0:	00e9                	.insn	2, 0x00e9
      e2:	0000                	.insn	2, 0x0000
      e4:	be01                	.insn	2, 0xbe01
      e6:	a102                	.insn	2, 0xa102
      e8:	0408                	.insn	2, 0x0408
      ea:	0049                	.insn	2, 0x0049
      ec:	0000                	.insn	2, 0x0000
      ee:	4d05                	.insn	2, 0x4d05
      f0:	0000                	.insn	2, 0x0000
      f2:	0a00                	.insn	2, 0x0a00
      f4:	0300                	.insn	2, 0x0300
      f6:	00ff 0000 c301 a102 	.insn	10, 0x0409a102c301000000ff
      fe:	0409 
     100:	0049                	.insn	2, 0x0049
     102:	0000                	.insn	2, 0x0000
     104:	4d05                	.insn	2, 0x4d05
     106:	0000                	.insn	2, 0x0000
     108:	0900                	.insn	2, 0x0900
     10a:	0300                	.insn	2, 0x0300
     10c:	0115                	.insn	2, 0x0115
     10e:	0000                	.insn	2, 0x0000
     110:	c801                	.insn	2, 0xc801
     112:	a102                	.insn	2, 0xa102
     114:	040a                	.insn	2, 0x040a
     116:	0049                	.insn	2, 0x0049
     118:	0000                	.insn	2, 0x0000
     11a:	4d05                	.insn	2, 0x4d05
     11c:	0000                	.insn	2, 0x0000
     11e:	1100                	.insn	2, 0x1100
     120:	0300                	.insn	2, 0x0300
     122:	00ff 0000 d001 a102 	.insn	10, 0x030ba102d001000000ff
     12a:	030b 
     12c:	0091                	.insn	2, 0x0091
     12e:	0000                	.insn	2, 0x0000
     130:	d201                	.insn	2, 0xd201
     132:	a102                	.insn	2, 0xa102
     134:	030c                	.insn	2, 0x030c
     136:	00e9                	.insn	2, 0x00e9
     138:	0000                	.insn	2, 0x0000
     13a:	da01                	.insn	2, 0xda01
     13c:	a102                	.insn	2, 0xa102
     13e:	030d                	.insn	2, 0x030d
     140:	000000d3          	.insn	4, 0x00d3
     144:	dc01                	.insn	2, 0xdc01
     146:	a102                	.insn	2, 0xa102
     148:	030e                	.insn	2, 0x030e
     14a:	00000153          	.insn	4, 0x0153
     14e:	e501                	.insn	2, 0xe501
     150:	a102                	.insn	2, 0xa102
     152:	0049040f          	.insn	4, 0x0049040f
     156:	0000                	.insn	2, 0x0000
     158:	4d05                	.insn	2, 0x4d05
     15a:	0000                	.insn	2, 0x0000
     15c:	0800                	.insn	2, 0x0800
     15e:	0300                	.insn	2, 0x0300
     160:	0091                	.insn	2, 0x0091
     162:	0000                	.insn	2, 0x0000
     164:	e701                	.insn	2, 0xe701
     166:	a102                	.insn	2, 0xa102
     168:	0310                	.insn	2, 0x0310
     16a:	00ff 0000 ef01 a102 	.insn	10, 0x0311a102ef01000000ff
     172:	0311 
     174:	000000d3          	.insn	4, 0x00d3
     178:	f101                	.insn	2, 0xf101
     17a:	a102                	.insn	2, 0xa102
     17c:	0312                	.insn	2, 0x0312
     17e:	00000187          	.insn	4, 0x0187
     182:	f701                	.insn	2, 0xf701
     184:	a102                	.insn	2, 0xa102
     186:	00490413          	addi	s0,s2,4
     18a:	0000                	.insn	2, 0x0000
     18c:	4d05                	.insn	2, 0x4d05
     18e:	0000                	.insn	2, 0x0000
     190:	1f00                	.insn	2, 0x1f00
     192:	0300                	.insn	2, 0x0300
     194:	019d                	.insn	2, 0x019d
     196:	0000                	.insn	2, 0x0000
     198:	fd01                	.insn	2, 0xfd01
     19a:	a102                	.insn	2, 0xa102
     19c:	0414                	.insn	2, 0x0414
     19e:	0049                	.insn	2, 0x0049
     1a0:	0000                	.insn	2, 0x0000
     1a2:	4d05                	.insn	2, 0x4d05
     1a4:	0000                	.insn	2, 0x0000
     1a6:	0b00                	.insn	2, 0x0b00
     1a8:	0700                	.insn	2, 0x0700
     1aa:	01b4                	.insn	2, 0x01b4
     1ac:	0000                	.insn	2, 0x0000
     1ae:	0001                	.insn	2, 0x0001
     1b0:	0201                	.insn	2, 0x0201
     1b2:	15a1                	.insn	2, 0x15a1
     1b4:	4904                	.insn	2, 0x4904
     1b6:	0000                	.insn	2, 0x0000
     1b8:	0500                	.insn	2, 0x0500
     1ba:	004d                	.insn	2, 0x004d
     1bc:	0000                	.insn	2, 0x0000
     1be:	0014                	.insn	2, 0x0014
     1c0:	00005b07          	.insn	4, 0x5b07
     1c4:	0100                	.insn	2, 0x0100
     1c6:	0104                	.insn	2, 0x0104
     1c8:	a102                	.insn	2, 0xa102
     1ca:	0716                	.insn	2, 0x0716
     1cc:	0115                	.insn	2, 0x0115
     1ce:	0000                	.insn	2, 0x0000
     1d0:	0501                	.insn	2, 0x0501
     1d2:	0201                	.insn	2, 0x0201
     1d4:	17a1                	.insn	2, 0x17a1
     1d6:	00015307          	.insn	4, 0x00015307
     1da:	0100                	.insn	2, 0x0100
     1dc:	0106                	.insn	2, 0x0106
     1de:	a102                	.insn	2, 0xa102
     1e0:	0718                	.insn	2, 0x0718
     1e2:	003d                	.insn	2, 0x003d
     1e4:	0000                	.insn	2, 0x0000
     1e6:	0701                	.insn	2, 0x0701
     1e8:	0201                	.insn	2, 0x0201
     1ea:	19a1                	.insn	2, 0x19a1
     1ec:	0001f707          	.insn	4, 0x0001f707
     1f0:	0100                	.insn	2, 0x0100
     1f2:	0108                	.insn	2, 0x0108
     1f4:	a102                	.insn	2, 0xa102
     1f6:	041a                	.insn	2, 0x041a
     1f8:	0049                	.insn	2, 0x0049
     1fa:	0000                	.insn	2, 0x0000
     1fc:	4d05                	.insn	2, 0x4d05
     1fe:	0000                	.insn	2, 0x0000
     200:	0f00                	.insn	2, 0x0f00
     202:	0700                	.insn	2, 0x0700
     204:	00ff 0000 0b01 0201 	.insn	10, 0x1ba102010b01000000ff
     20c:	1ba1 
     20e:	0000e907          	.insn	4, 0xe907
     212:	0100                	.insn	2, 0x0100
     214:	0110                	.insn	2, 0x0110
     216:	a102                	.insn	2, 0xa102
     218:	071c                	.insn	2, 0x071c
     21a:	0091                	.insn	2, 0x0091
     21c:	0000                	.insn	2, 0x0000
     21e:	1301                	.insn	2, 0x1301
     220:	0201                	.insn	2, 0x0201
     222:	1da1                	.insn	2, 0x1da1
     224:	00022f07          	.insn	4, 0x00022f07
     228:	0100                	.insn	2, 0x0100
     22a:	011a                	.insn	2, 0x011a
     22c:	a102                	.insn	2, 0xa102
     22e:	041e                	.insn	2, 0x041e
     230:	0049                	.insn	2, 0x0049
     232:	0000                	.insn	2, 0x0000
     234:	4d05                	.insn	2, 0x4d05
     236:	0000                	.insn	2, 0x0000
     238:	0c00                	.insn	2, 0x0c00
     23a:	0700                	.insn	2, 0x0700
     23c:	0246                	.insn	2, 0x0246
     23e:	0000                	.insn	2, 0x0000
     240:	1d01                	.insn	2, 0x1d01
     242:	0201                	.insn	2, 0x0201
     244:	1fa1                	.insn	2, 0x1fa1
     246:	4904                	.insn	2, 0x4904
     248:	0000                	.insn	2, 0x0000
     24a:	0500                	.insn	2, 0x0500
     24c:	004d                	.insn	2, 0x004d
     24e:	0000                	.insn	2, 0x0000
     250:	b407001b          	.insn	4, 0xb407001b
     254:	0001                	.insn	2, 0x0001
     256:	0100                	.insn	2, 0x0100
     258:	0122                	.insn	2, 0x0122
     25a:	a102                	.insn	2, 0xa102
     25c:	0720                	.insn	2, 0x0720
     25e:	00bd                	.insn	2, 0x00bd
     260:	0000                	.insn	2, 0x0000
     262:	2401                	.insn	2, 0x2401
     264:	0201                	.insn	2, 0x0201
     266:	21a1                	.insn	2, 0x21a1
     268:	0000a707          	.insn	4, 0xa707
     26c:	0100                	.insn	2, 0x0100
     26e:	0128                	.insn	2, 0x0128
     270:	a102                	.insn	2, 0xa102
     272:	0722                	.insn	2, 0x0722
     274:	019d                	.insn	2, 0x019d
     276:	0000                	.insn	2, 0x0000
     278:	2901                	.insn	2, 0x2901
     27a:	0201                	.insn	2, 0x0201
     27c:	23a1                	.insn	2, 0x23a1
     27e:	0000a707          	.insn	4, 0xa707
     282:	0100                	.insn	2, 0x0100
     284:	a1020133          	.insn	4, 0xa1020133
     288:	0724                	.insn	2, 0x0724
     28a:	000000a7          	.insn	4, 0x00a7
     28e:	3401                	.insn	2, 0x3401
     290:	0201                	.insn	2, 0x0201
     292:	25a1                	.insn	2, 0x25a1
     294:	00029f07          	.insn	4, 0x00029f07
     298:	0100                	.insn	2, 0x0100
     29a:	0135                	.insn	2, 0x0135
     29c:	a102                	.insn	2, 0xa102
     29e:	0426                	.insn	2, 0x0426
     2a0:	0049                	.insn	2, 0x0049
     2a2:	0000                	.insn	2, 0x0000
     2a4:	4d05                	.insn	2, 0x4d05
     2a6:	0000                	.insn	2, 0x0000
     2a8:	0200                	.insn	2, 0x0200
     2aa:	0700                	.insn	2, 0x0700
     2ac:	02b6                	.insn	2, 0x02b6
     2ae:	0000                	.insn	2, 0x0000
     2b0:	3901                	.insn	2, 0x3901
     2b2:	0201                	.insn	2, 0x0201
     2b4:	27a1                	.insn	2, 0x27a1
     2b6:	4904                	.insn	2, 0x4904
     2b8:	0000                	.insn	2, 0x0000
     2ba:	0500                	.insn	2, 0x0500
     2bc:	004d                	.insn	2, 0x004d
     2be:	0000                	.insn	2, 0x0000
     2c0:	0015                	.insn	2, 0x0015
     2c2:	0002cd07          	.insn	4, 0x0002cd07
     2c6:	0100                	.insn	2, 0x0100
     2c8:	0144                	.insn	2, 0x0144
     2ca:	a102                	.insn	2, 0xa102
     2cc:	0428                	.insn	2, 0x0428
     2ce:	0049                	.insn	2, 0x0049
     2d0:	0000                	.insn	2, 0x0000
     2d2:	4d05                	.insn	2, 0x4d05
     2d4:	0000                	.insn	2, 0x0000
     2d6:	0400                	.insn	2, 0x0400
     2d8:	0700                	.insn	2, 0x0700
     2da:	000000d3          	.insn	4, 0x00d3
     2de:	4d01                	.insn	2, 0x4d01
     2e0:	0201                	.insn	2, 0x0201
     2e2:	29a1                	.insn	2, 0x29a1
     2e4:	0502                	.insn	2, 0x0502
     2e6:	0405                	.insn	2, 0x0405
     2e8:	f008                	.insn	2, 0xf008
     2ea:	0002                	.insn	2, 0x0002
     2ec:	0700                	.insn	2, 0x0700
     2ee:	1102                	.insn	2, 0x1102
     2f0:	0602                	.insn	2, 0x0602
     2f2:	08090407          	.insn	4, 0x08090407
     2f6:	5101                	.insn	2, 0x5101
     2f8:	e401                	.insn	2, 0xe401
     2fa:	0002                	.insn	2, 0x0002
     2fc:	0a00                	.insn	2, 0x0a00
     2fe:	0109                	.insn	2, 0x0109
     300:	0151                	.insn	2, 0x0151
     302:	032d                	.insn	2, 0x032d
     304:	0000                	.insn	2, 0x0000
     306:	0a0a                	.insn	2, 0x0a0a
     308:	5101                	.insn	2, 0x5101
     30a:	3701                	.insn	2, 0x3701
     30c:	0b000003          	lb	zero,176(zero) # b0 <start-0x3fff50>
     310:	010c                	.insn	2, 0x010c
     312:	0152                	.insn	2, 0x0152
     314:	033c                	.insn	2, 0x033c
     316:	0000                	.insn	2, 0x0000
     318:	0b0c                	.insn	2, 0x0b0c
     31a:	010d                	.insn	2, 0x010d
     31c:	015c                	.insn	2, 0x015c
     31e:	0049                	.insn	2, 0x0049
     320:	0000                	.insn	2, 0x0000
     322:	5d010e0b          	.insn	4, 0x5d010e0b
     326:	e801                	.insn	2, 0xe801
     328:	0002                	.insn	2, 0x0002
     32a:	0000                	.insn	2, 0x0000
     32c:	0d00                	.insn	2, 0x0d00
     32e:	0332                	.insn	2, 0x0332
     330:	0000                	.insn	2, 0x0000
     332:	490e                	.insn	2, 0x490e
     334:	0000                	.insn	2, 0x0000
     336:	0d00                	.insn	2, 0x0d00
     338:	033c                	.insn	2, 0x033c
     33a:	0000                	.insn	2, 0x0000
     33c:	e808                	.insn	2, 0xe808
     33e:	0002                	.insn	2, 0x0002
     340:	0b00                	.insn	2, 0x0b00
     342:	1402                	.insn	2, 0x1402
     344:	08942a0f          	.insn	4, 0x08942a0f
     348:	0000                	.insn	2, 0x0000
     34a:	5201                	.insn	2, 0x5201
     34c:	0125                	.insn	2, 0x0125
     34e:	1005                	.insn	2, 0x1005
     350:	2900                	.insn	2, 0x2900
     352:	1501                	.insn	2, 0x1501
     354:	02e8                	.insn	2, 0x02e8
     356:	0000                	.insn	2, 0x0000
     358:	2b11                	.insn	2, 0x2b11
     35a:	0800                	.insn	2, 0x0800
     35c:	0000                	.insn	2, 0x0000
     35e:	0212                	.insn	2, 0x0212
     360:	2c91                	.insn	2, 0x2c91
     362:	9e2a0127          	.insn	4, 0x9e2a0127
     366:	12000007          	.insn	4, 0x12000007
     36a:	9102                	.insn	2, 0x9102
     36c:	280c                	.insn	2, 0x280c
     36e:	7d01                	.insn	2, 0x7d01
     370:	07aa                	.insn	2, 0x07aa
     372:	0000                	.insn	2, 0x0000
     374:	0110                	.insn	2, 0x0110
     376:	012a                	.insn	2, 0x012a
     378:	e47e                	.insn	2, 0xe47e
     37a:	0002                	.insn	2, 0x0002
     37c:	1000                	.insn	2, 0x1000
     37e:	2b02                	.insn	2, 0x2b02
     380:	2b01                	.insn	2, 0x2b01
     382:	02e4                	.insn	2, 0x02e4
     384:	0000                	.insn	2, 0x0000
     386:	0610                	.insn	2, 0x0610
     388:	b681012f          	.insn	4, 0xb681012f
     38c:	13000007          	.insn	4, 0x13000007
     390:	0135                	.insn	2, 0x0135
     392:	0119                	.insn	2, 0x0119
     394:	2c110183          	lb	gp,705(sp)
     398:	0034                	.insn	2, 0x0034
     39a:	0000                	.insn	2, 0x0000
     39c:	1610                	.insn	2, 0x1610
     39e:	0134                	.insn	2, 0x0134
     3a0:	f0f5                	.insn	2, 0xf0f5
     3a2:	0002                	.insn	2, 0x0002
     3a4:	0000                	.insn	2, 0x0000
     3a6:	2d11                	.insn	2, 0x2d11
     3a8:	0018                	.insn	2, 0x0018
     3aa:	0000                	.insn	2, 0x0000
     3ac:	1310                	.insn	2, 0x1310
     3ae:	0134                	.insn	2, 0x0134
     3b0:	0002f0eb          	.insn	4, 0x0002f0eb
     3b4:	0000                	.insn	2, 0x0000
     3b6:	2e11                	.insn	2, 0x2e11
     3b8:	0018                	.insn	2, 0x0018
     3ba:	0000                	.insn	2, 0x0000
     3bc:	1210                	.insn	2, 0x1210
     3be:	f0e00133          	.insn	4, 0xf0e00133
     3c2:	0002                	.insn	2, 0x0002
     3c4:	0000                	.insn	2, 0x0000
     3c6:	2f11                	.insn	2, 0x2f11
     3c8:	0018                	.insn	2, 0x0018
     3ca:	0000                	.insn	2, 0x0000
     3cc:	0f10                	.insn	2, 0x0f10
     3ce:	f0d60133          	.insn	4, 0xf0d60133
     3d2:	0002                	.insn	2, 0x0002
     3d4:	0000                	.insn	2, 0x0000
     3d6:	0014                	.insn	2, 0x0014
     3d8:	0e10                	.insn	2, 0x0e10
     3da:	0132                	.insn	2, 0x0132
     3dc:	e8c4                	.insn	2, 0xe8c4
     3de:	0002                	.insn	2, 0x0002
     3e0:	0000                	.insn	2, 0x0000
     3e2:	0114                	.insn	2, 0x0114
     3e4:	0b10                	.insn	2, 0x0b10
     3e6:	0131                	.insn	2, 0x0131
     3e8:	0002f0b3          	and	ra,t0,zero
     3ec:	0000                	.insn	2, 0x0000
     3ee:	0214                	.insn	2, 0x0214
     3f0:	0710                	.insn	2, 0x0710
     3f2:	0130                	.insn	2, 0x0130
     3f4:	0002e897          	auipc	a7,0x2e
     3f8:	1000                	.insn	2, 0x1000
     3fa:	2b08                	.insn	2, 0x2b08
     3fc:	9801                	.insn	2, 0x9801
     3fe:	02e8                	.insn	2, 0x02e8
     400:	0000                	.insn	2, 0x0000
     402:	3715                	.insn	2, 0x3715
     404:	9901                	.insn	2, 0x9901
     406:	033c                	.insn	2, 0x033c
     408:	0000                	.insn	2, 0x0000
     40a:	f416                	.insn	2, 0xf416
     40c:	0002                	.insn	2, 0x0002
     40e:	0300                	.insn	2, 0x0300
     410:	9c01                	.insn	2, 0x9c01
     412:	1715                	.insn	2, 0x1715
     414:	fd09                	.insn	2, 0xfd09
     416:	0002                	.insn	2, 0x0002
     418:	1800                	.insn	2, 0x1800
     41a:	0f0a                	.insn	2, 0x0f0a
     41c:	19000003          	lb	zero,400(zero) # 190 <start-0x3ffe70>
     420:	1804                	.insn	2, 0x1804
     422:	18000003          	lb	zero,384(zero) # 180 <start-0x3ffe80>
     426:	1910                	.insn	2, 0x1910
     428:	18000003          	lb	zero,384(zero) # 180 <start-0x3ffe80>
     42c:	2211                	.insn	2, 0x2211
     42e:	00000003          	lb	zero,0(zero) # 0 <start-0x400000>
     432:	1600                	.insn	2, 0x1600
     434:	02f4                	.insn	2, 0x02f4
     436:	0000                	.insn	2, 0x0000
     438:	0105                	.insn	2, 0x0105
     43a:	15a2                	.insn	2, 0x15a2
     43c:	02fd0c17          	auipc	s8,0x2fd0
     440:	0000                	.insn	2, 0x0000
     442:	0d18                	.insn	2, 0x0d18
     444:	0000030f          	.insn	4, 0x030f
     448:	0619                	.insn	2, 0x0619
     44a:	0318                	.insn	2, 0x0318
     44c:	0000                	.insn	2, 0x0000
     44e:	1418                	.insn	2, 0x1418
     450:	0319                	.insn	2, 0x0319
     452:	0000                	.insn	2, 0x0000
     454:	1518                	.insn	2, 0x1518
     456:	0322                	.insn	2, 0x0322
     458:	0000                	.insn	2, 0x0000
     45a:	0000                	.insn	2, 0x0000
     45c:	1400                	.insn	2, 0x1400
     45e:	2c031007          	.insn	4, 0x2c031007
     462:	4901                	.insn	2, 0x4901
     464:	02e4                	.insn	2, 0x02e4
     466:	0000                	.insn	2, 0x0000
     468:	0410                	.insn	2, 0x0410
     46a:	012d                	.insn	2, 0x012d
     46c:	e835                	.insn	2, 0xe835
     46e:	0002                	.insn	2, 0x0002
     470:	1000                	.insn	2, 0x1000
     472:	2e05                	.insn	2, 0x2e05
     474:	3801                	.insn	2, 0x3801
     476:	0796                	.insn	2, 0x0796
     478:	0000                	.insn	2, 0x0000
     47a:	3615                	.insn	2, 0x3615
     47c:	3701                	.insn	2, 0x3701
     47e:	0796                	.insn	2, 0x0796
     480:	0000                	.insn	2, 0x0000
     482:	0000                	.insn	2, 0x0000
     484:	471a                	.insn	2, 0x471a
     486:	0006                	.insn	2, 0x0006
     488:	3000                	.insn	2, 0x3000
     48a:	511a                	.insn	2, 0x511a
     48c:	0006                	.insn	2, 0x0006
     48e:	3100                	.insn	2, 0x3100
     490:	511a                	.insn	2, 0x511a
     492:	0006                	.insn	2, 0x0006
     494:	3200                	.insn	2, 0x3200
     496:	5c1a                	.insn	2, 0x5c1a
     498:	0006                	.insn	2, 0x0006
     49a:	3300                	.insn	2, 0x3300
     49c:	5c1a                	.insn	2, 0x5c1a
     49e:	0006                	.insn	2, 0x0006
     4a0:	3400                	.insn	2, 0x3400
     4a2:	5c1a                	.insn	2, 0x5c1a
     4a4:	0006                	.insn	2, 0x0006
     4a6:	3500                	.insn	2, 0x3500
     4a8:	5c1a                	.insn	2, 0x5c1a
     4aa:	0006                	.insn	2, 0x0006
     4ac:	3600                	.insn	2, 0x3600
     4ae:	5c1a                	.insn	2, 0x5c1a
     4b0:	0006                	.insn	2, 0x0006
     4b2:	3700                	.insn	2, 0x3700
     4b4:	5c1a                	.insn	2, 0x5c1a
     4b6:	0006                	.insn	2, 0x0006
     4b8:	3800                	.insn	2, 0x3800
     4ba:	5c1a                	.insn	2, 0x5c1a
     4bc:	0006                	.insn	2, 0x0006
     4be:	3900                	.insn	2, 0x3900
     4c0:	5c1a                	.insn	2, 0x5c1a
     4c2:	0006                	.insn	2, 0x0006
     4c4:	3a00                	.insn	2, 0x3a00
     4c6:	5c1a                	.insn	2, 0x5c1a
     4c8:	0006                	.insn	2, 0x0006
     4ca:	3b00                	.insn	2, 0x3b00
     4cc:	5c1a                	.insn	2, 0x5c1a
     4ce:	0006                	.insn	2, 0x0006
     4d0:	3c00                	.insn	2, 0x3c00
     4d2:	5c1a                	.insn	2, 0x5c1a
     4d4:	0006                	.insn	2, 0x0006
     4d6:	3d00                	.insn	2, 0x3d00
     4d8:	5c1a                	.insn	2, 0x5c1a
     4da:	0006                	.insn	2, 0x0006
     4dc:	3e00                	.insn	2, 0x3e00
     4de:	5c1a                	.insn	2, 0x5c1a
     4e0:	0006                	.insn	2, 0x0006
     4e2:	3f00                	.insn	2, 0x3f00
     4e4:	5c1a                	.insn	2, 0x5c1a
     4e6:	0006                	.insn	2, 0x0006
     4e8:	4000                	.insn	2, 0x4000
     4ea:	5c1a                	.insn	2, 0x5c1a
     4ec:	0006                	.insn	2, 0x0006
     4ee:	4100                	.insn	2, 0x4100
     4f0:	5c1a                	.insn	2, 0x5c1a
     4f2:	0006                	.insn	2, 0x0006
     4f4:	4200                	.insn	2, 0x4200
     4f6:	5c1a                	.insn	2, 0x5c1a
     4f8:	0006                	.insn	2, 0x0006
     4fa:	4300                	.insn	2, 0x4300
     4fc:	661a                	.insn	2, 0x661a
     4fe:	0006                	.insn	2, 0x0006
     500:	4400                	.insn	2, 0x4400
     502:	511a                	.insn	2, 0x511a
     504:	0006                	.insn	2, 0x0006
     506:	4500                	.insn	2, 0x4500
     508:	511a                	.insn	2, 0x511a
     50a:	0006                	.insn	2, 0x0006
     50c:	4600                	.insn	2, 0x4600
     50e:	6e1a                	.insn	2, 0x6e1a
     510:	0006                	.insn	2, 0x0006
     512:	4700                	.insn	2, 0x4700
     514:	5c1a                	.insn	2, 0x5c1a
     516:	0006                	.insn	2, 0x0006
     518:	4800                	.insn	2, 0x4800
     51a:	5c1a                	.insn	2, 0x5c1a
     51c:	0006                	.insn	2, 0x0006
     51e:	4900                	.insn	2, 0x4900
     520:	5c1a                	.insn	2, 0x5c1a
     522:	0006                	.insn	2, 0x0006
     524:	4a00                	.insn	2, 0x4a00
     526:	761a                	.insn	2, 0x761a
     528:	0006                	.insn	2, 0x0006
     52a:	4b00                	.insn	2, 0x4b00
     52c:	761a                	.insn	2, 0x761a
     52e:	0006                	.insn	2, 0x0006
     530:	4c00                	.insn	2, 0x4c00
     532:	761a                	.insn	2, 0x761a
     534:	0006                	.insn	2, 0x0006
     536:	4d00                	.insn	2, 0x4d00
     538:	761a                	.insn	2, 0x761a
     53a:	0006                	.insn	2, 0x0006
     53c:	4e00                	.insn	2, 0x4e00
     53e:	761a                	.insn	2, 0x761a
     540:	0006                	.insn	2, 0x0006
     542:	4f00                	.insn	2, 0x4f00
     544:	761a                	.insn	2, 0x761a
     546:	0006                	.insn	2, 0x0006
     548:	5000                	.insn	2, 0x5000
     54a:	761a                	.insn	2, 0x761a
     54c:	0006                	.insn	2, 0x0006
     54e:	5100                	.insn	2, 0x5100
     550:	761a                	.insn	2, 0x761a
     552:	0006                	.insn	2, 0x0006
     554:	5200                	.insn	2, 0x5200
     556:	761a                	.insn	2, 0x761a
     558:	0006                	.insn	2, 0x0006
     55a:	5300                	.insn	2, 0x5300
     55c:	761a                	.insn	2, 0x761a
     55e:	0006                	.insn	2, 0x0006
     560:	5400                	.insn	2, 0x5400
     562:	761a                	.insn	2, 0x761a
     564:	0006                	.insn	2, 0x0006
     566:	5500                	.insn	2, 0x5500
     568:	761a                	.insn	2, 0x761a
     56a:	0006                	.insn	2, 0x0006
     56c:	5600                	.insn	2, 0x5600
     56e:	761a                	.insn	2, 0x761a
     570:	0006                	.insn	2, 0x0006
     572:	5700                	.insn	2, 0x5700
     574:	761a                	.insn	2, 0x761a
     576:	0006                	.insn	2, 0x0006
     578:	5800                	.insn	2, 0x5800
     57a:	761a                	.insn	2, 0x761a
     57c:	0006                	.insn	2, 0x0006
     57e:	5900                	.insn	2, 0x5900
     580:	761a                	.insn	2, 0x761a
     582:	0006                	.insn	2, 0x0006
     584:	5a00                	.insn	2, 0x5a00
     586:	761a                	.insn	2, 0x761a
     588:	0006                	.insn	2, 0x0006
     58a:	5b00                	.insn	2, 0x5b00
     58c:	761a                	.insn	2, 0x761a
     58e:	0006                	.insn	2, 0x0006
     590:	5c00                	.insn	2, 0x5c00
     592:	511a                	.insn	2, 0x511a
     594:	0006                	.insn	2, 0x0006
     596:	5d00                	.insn	2, 0x5d00
     598:	891a                	.insn	2, 0x891a
     59a:	0006                	.insn	2, 0x0006
     59c:	5e00                	.insn	2, 0x5e00
     59e:	971a                	.insn	2, 0x971a
     5a0:	0006                	.insn	2, 0x0006
     5a2:	5f00                	.insn	2, 0x5f00
     5a4:	971a                	.insn	2, 0x971a
     5a6:	0006                	.insn	2, 0x0006
     5a8:	6000                	.insn	2, 0x6000
     5aa:	891a                	.insn	2, 0x891a
     5ac:	0006                	.insn	2, 0x0006
     5ae:	6100                	.insn	2, 0x6100
     5b0:	a61a                	.insn	2, 0xa61a
     5b2:	0006                	.insn	2, 0x0006
     5b4:	6200                	.insn	2, 0x6200
     5b6:	971a                	.insn	2, 0x971a
     5b8:	0006                	.insn	2, 0x0006
     5ba:	6300                	.insn	2, 0x6300
     5bc:	891a                	.insn	2, 0x891a
     5be:	0006                	.insn	2, 0x0006
     5c0:	6400                	.insn	2, 0x6400
     5c2:	f91a                	.insn	2, 0xf91a
     5c4:	0006                	.insn	2, 0x0006
     5c6:	6500                	.insn	2, 0x6500
     5c8:	891a                	.insn	2, 0x891a
     5ca:	0006                	.insn	2, 0x0006
     5cc:	6600                	.insn	2, 0x6600
     5ce:	031a                	.insn	2, 0x031a
     5d0:	67000007          	.insn	4, 0x67000007
     5d4:	471a                	.insn	2, 0x471a
     5d6:	0006                	.insn	2, 0x0006
     5d8:	6800                	.insn	2, 0x6800
     5da:	891a                	.insn	2, 0x891a
     5dc:	0006                	.insn	2, 0x0006
     5de:	6900                	.insn	2, 0x6900
     5e0:	111a                	.insn	2, 0x111a
     5e2:	6a000007          	.insn	4, 0x6a000007
     5e6:	891a                	.insn	2, 0x891a
     5e8:	0006                	.insn	2, 0x0006
     5ea:	6b00                	.insn	2, 0x6b00
     5ec:	1b1a                	.insn	2, 0x1b1a
     5ee:	6c000007          	.insn	4, 0x6c000007
     5f2:	251a                	.insn	2, 0x251a
     5f4:	6d000007          	.insn	4, 0x6d000007
     5f8:	511a                	.insn	2, 0x511a
     5fa:	0006                	.insn	2, 0x0006
     5fc:	6e00                	.insn	2, 0x6e00
     5fe:	2d1a                	.insn	2, 0x2d1a
     600:	6f000007          	.insn	4, 0x6f000007
     604:	311a                	.insn	2, 0x311a
     606:	70000007          	.insn	4, 0x70000007
     60a:	511a                	.insn	2, 0x511a
     60c:	0006                	.insn	2, 0x0006
     60e:	7100                	.insn	2, 0x7100
     610:	511a                	.insn	2, 0x511a
     612:	0006                	.insn	2, 0x0006
     614:	7200                	.insn	2, 0x7200
     616:	511a                	.insn	2, 0x511a
     618:	0006                	.insn	2, 0x0006
     61a:	7300                	.insn	2, 0x7300
     61c:	511a                	.insn	2, 0x511a
     61e:	0006                	.insn	2, 0x0006
     620:	7400                	.insn	2, 0x7400
     622:	511a                	.insn	2, 0x511a
     624:	0006                	.insn	2, 0x0006
     626:	7500                	.insn	2, 0x7500
     628:	3f1a                	.insn	2, 0x3f1a
     62a:	76000007          	.insn	4, 0x76000007
     62e:	511a                	.insn	2, 0x511a
     630:	0006                	.insn	2, 0x0006
     632:	7700                	.insn	2, 0x7700
     634:	4d1a                	.insn	2, 0x4d1a
     636:	78000007          	.insn	4, 0x78000007
     63a:	511a                	.insn	2, 0x511a
     63c:	0006                	.insn	2, 0x0006
     63e:	7900                	.insn	2, 0x7900
     640:	511a                	.insn	2, 0x511a
     642:	7a000007          	.insn	4, 0x7a000007
     646:	1b00                	.insn	2, 0x1b00
     648:	1c29020f          	.insn	4, 0x1c29020f
     64c:	02e8                	.insn	2, 0x02e8
     64e:	0000                	.insn	2, 0x0000
     650:	1b00                	.insn	2, 0x1b00
     652:	0210                	.insn	2, 0x0210
     654:	1c4e                	.insn	2, 0x1c4e
     656:	032d                	.insn	2, 0x032d
     658:	0000                	.insn	2, 0x0000
     65a:	001d                	.insn	2, 0x001d
     65c:	3d02111b          	.insn	4, 0x3d02111b
     660:	491c                	.insn	2, 0x491c
     662:	0000                	.insn	2, 0x0000
     664:	0000                	.insn	2, 0x0000
     666:	121e                	.insn	2, 0x121e
     668:	4d02                	.insn	2, 0x4d02
     66a:	02e8                	.insn	2, 0x02e8
     66c:	0000                	.insn	2, 0x0000
     66e:	131e                	.insn	2, 0x131e
     670:	3f02                	.insn	2, 0x3f02
     672:	02e4                	.insn	2, 0x02e4
     674:	0000                	.insn	2, 0x0000
     676:	141f 4a02 02e4      	.insn	6, 0x02e44a02141f
     67c:	0000                	.insn	2, 0x0000
     67e:	2d1c                	.insn	2, 0x2d1c
     680:	1c000003          	lb	zero,448(zero) # 1c0 <start-0x3ffe40>
     684:	032d                	.insn	2, 0x032d
     686:	0000                	.insn	2, 0x0000
     688:	1f00                	.insn	2, 0x1f00
     68a:	0215                	.insn	2, 0x0215
     68c:	f03c                	.insn	2, 0xf03c
     68e:	0002                	.insn	2, 0x0002
     690:	1c00                	.insn	2, 0x1c00
     692:	032d                	.insn	2, 0x032d
     694:	0000                	.insn	2, 0x0000
     696:	1b00                	.insn	2, 0x1b00
     698:	0216                	.insn	2, 0x0216
     69a:	02e81c37          	lui	s8,0x2e81
     69e:	0000                	.insn	2, 0x0000
     6a0:	e81c                	.insn	2, 0xe81c
     6a2:	0002                	.insn	2, 0x0002
     6a4:	0000                	.insn	2, 0x0000
     6a6:	7c20                	.insn	2, 0x7c20
     6a8:	00bc                	.insn	2, 0x00bc
     6aa:	0000                	.insn	2, 0x0000
     6ac:	5201                	.insn	2, 0x5201
     6ae:	0126                	.insn	2, 0x0126
     6b0:	1b21013f 013f0131 	.insn	8, 0x013f01311b21013f
     6b8:	02f0                	.insn	2, 0x02f0
     6ba:	0000                	.insn	2, 0x0000
     6bc:	1c22                	.insn	2, 0x1c22
     6be:	01410133          	add	sp,sp,s4
     6c2:	02e4                	.insn	2, 0x02e4
     6c4:	0000                	.insn	2, 0x0000
     6c6:	7d11                	.insn	2, 0x7d11
     6c8:	0054                	.insn	2, 0x0054
     6ca:	0000                	.insn	2, 0x0000
     6cc:	1d22                	.insn	2, 0x1d22
     6ce:	0138                	.insn	2, 0x0138
     6d0:	0142                	.insn	2, 0x0142
     6d2:	02f0                	.insn	2, 0x02f0
     6d4:	0000                	.insn	2, 0x0000
     6d6:	1a00                	.insn	2, 0x1a00
     6d8:	0788                	.insn	2, 0x0788
     6da:	0000                	.insn	2, 0x0000
     6dc:	1a7e                	.insn	2, 0x1a7e
     6de:	0651                	.insn	2, 0x0651
     6e0:	0000                	.insn	2, 0x0000
     6e2:	065c1a7f 01800000 	.insn	12, 0x00065c1a01800000065c1a7f
     6ea:	00065c1a 
     6ee:	8100                	.insn	2, 0x8100
     6f0:	2301                	.insn	2, 0x2301
     6f2:	0651                	.insn	2, 0x0651
     6f4:	0000                	.insn	2, 0x0000
     6f6:	0182                	.insn	2, 0x0182
     6f8:	1b00                	.insn	2, 0x1b00
     6fa:	1c2b0217          	auipc	tp,0x1c2b0
     6fe:	02f0                	.insn	2, 0x02f0
     700:	0000                	.insn	2, 0x0000
     702:	1f00                	.insn	2, 0x1f00
     704:	0218                	.insn	2, 0x0218
     706:	e82d                	.insn	2, 0xe82d
     708:	0002                	.insn	2, 0x0002
     70a:	1c00                	.insn	2, 0x1c00
     70c:	02e8                	.insn	2, 0x02e8
     70e:	0000                	.insn	2, 0x0000
     710:	1b00                	.insn	2, 0x1b00
     712:	0219                	.insn	2, 0x0219
     714:	02f01c2f          	.insn	4, 0x02f01c2f
     718:	0000                	.insn	2, 0x0000
     71a:	1b00                	.insn	2, 0x1b00
     71c:	021a                	.insn	2, 0x021a
     71e:	1c30                	.insn	2, 0x1c30
     720:	02f0                	.insn	2, 0x02f0
     722:	0000                	.insn	2, 0x0000
     724:	1e00                	.insn	2, 0x1e00
     726:	e410031b          	.insn	4, 0xe410031b
     72a:	0002                	.insn	2, 0x0002
     72c:	2400                	.insn	2, 0x2400
     72e:	031c                	.insn	2, 0x031c
     730:	1f11                	.insn	2, 0x1f11
     732:	031d                	.insn	2, 0x031d
     734:	e40e                	.insn	2, 0xe40e
     736:	0002                	.insn	2, 0x0002
     738:	1c00                	.insn	2, 0x1c00
     73a:	032d                	.insn	2, 0x032d
     73c:	0000                	.insn	2, 0x0000
     73e:	1f00                	.insn	2, 0x1f00
     740:	031e                	.insn	2, 0x031e
     742:	e412                	.insn	2, 0xe412
     744:	0002                	.insn	2, 0x0002
     746:	1c00                	.insn	2, 0x1c00
     748:	032d                	.insn	2, 0x032d
     74a:	0000                	.insn	2, 0x0000
     74c:	2400                	.insn	2, 0x2400
     74e:	021f 2534 0220      	.insn	6, 0x02202534021f
     754:	c47b264f          	.insn	4, 0xc47b264f
     758:	0000                	.insn	2, 0x0000
     75a:	0100                	.insn	2, 0x0100
     75c:	f452                	.insn	2, 0xf452
     75e:	0002                	.insn	2, 0x0002
     760:	1700                	.insn	2, 0x1700
     762:	0002fd17          	auipc	s10,0x2f
     766:	2700                	.insn	2, 0x2700
     768:	5b01                	.insn	2, 0x5b01
     76a:	0306                	.insn	2, 0x0306
     76c:	0000                	.insn	2, 0x0000
     76e:	1818                	.insn	2, 0x1818
     770:	0000030f          	.insn	4, 0x030f
     774:	0819                	.insn	2, 0x0819
     776:	0318                	.insn	2, 0x0318
     778:	0000                	.insn	2, 0x0000
     77a:	1918                	.insn	2, 0x1918
     77c:	0319                	.insn	2, 0x0319
     77e:	0000                	.insn	2, 0x0000
     780:	1a18                	.insn	2, 0x1a18
     782:	0322                	.insn	2, 0x0322
     784:	0000                	.insn	2, 0x0000
     786:	0000                	.insn	2, 0x0000
     788:	211f 3b02 0796      	.insn	6, 0x07963b02211f
     78e:	0000                	.insn	2, 0x0000
     790:	f01c                	.insn	2, 0xf01c
     792:	0002                	.insn	2, 0x0002
     794:	0000                	.insn	2, 0x0000
     796:	e408                	.insn	2, 0xe408
     798:	0002                	.insn	2, 0x0002
     79a:	2200                	.insn	2, 0x2200
     79c:	0e02                	.insn	2, 0x0e02
     79e:	4904                	.insn	2, 0x4904
     7a0:	0000                	.insn	2, 0x0000
     7a2:	0500                	.insn	2, 0x0500
     7a4:	004d                	.insn	2, 0x004d
     7a6:	0000                	.insn	2, 0x0000
     7a8:	0020                	.insn	2, 0x0020
     7aa:	2d04                	.insn	2, 0x2d04
     7ac:	05000003          	lb	zero,80(zero) # 50 <start-0x3fffb0>
     7b0:	004d                	.insn	2, 0x004d
     7b2:	0000                	.insn	2, 0x0000
     7b4:	0008                	.insn	2, 0x0008
     7b6:	490d                	.insn	2, 0x490d
     7b8:	0000                	.insn	2, 0x0000
     7ba:	0000                	.insn	2, 0x0000
     7bc:	0bf5                	.insn	2, 0x0bf5
     7be:	0000                	.insn	2, 0x0000
     7c0:	0005                	.insn	2, 0x0005
     7c2:	0401                	.insn	2, 0x0401
     7c4:	0201                	.insn	2, 0x0201
     7c6:	0000                	.insn	2, 0x0000
     7c8:	0001                	.insn	2, 0x0001
     7ca:	001d                	.insn	2, 0x001d
     7cc:	f401                	.insn	2, 0xf401
     7ce:	0000                	.insn	2, 0x0000
     7d0:	f700                	.insn	2, 0xf700
     7d2:	0006                	.insn	2, 0x0006
     7d4:	0200                	.insn	2, 0x0200
     7d6:	0000                	.insn	2, 0x0000
     7d8:	0000                	.insn	2, 0x0000
     7da:	2004                	.insn	2, 0x2004
     7dc:	0002                	.insn	2, 0x0002
     7de:	c700                	.insn	2, 0xc700
     7e0:	0000                	.insn	2, 0x0000
     7e2:	c700                	.insn	2, 0xc700
     7e4:	02000003          	lb	zero,32(zero) # 20 <start-0x3fffe0>
     7e8:	0035                	.insn	2, 0x0035
     7ea:	0000                	.insn	2, 0x0000
     7ec:	8701                	.insn	2, 0x8701
     7ee:	a102                	.insn	2, 0xa102
     7f0:	0300                	.insn	2, 0x0300
     7f2:	0041                	.insn	2, 0x0041
     7f4:	0000                	.insn	2, 0x0000
     7f6:	4504                	.insn	2, 0x4504
     7f8:	0000                	.insn	2, 0x0000
     7fa:	1500                	.insn	2, 0x1500
     7fc:	0500                	.insn	2, 0x0500
     7fe:	06010803          	lb	a6,96(sp)
     802:	0804                	.insn	2, 0x0804
     804:	00530207          	.insn	4, 0x00530207
     808:	0000                	.insn	2, 0x0000
     80a:	eb01                	.insn	2, 0xeb01
     80c:	a102                	.insn	2, 0xa102
     80e:	0301                	.insn	2, 0x0301
     810:	0041                	.insn	2, 0x0041
     812:	0000                	.insn	2, 0x0000
     814:	4504                	.insn	2, 0x4504
     816:	0000                	.insn	2, 0x0000
     818:	0800                	.insn	2, 0x0800
     81a:	0200                	.insn	2, 0x0200
     81c:	0069                	.insn	2, 0x0069
     81e:	0000                	.insn	2, 0x0000
     820:	ef01                	.insn	2, 0xef01
     822:	a102                	.insn	2, 0xa102
     824:	0302                	.insn	2, 0x0302
     826:	0041                	.insn	2, 0x0041
     828:	0000                	.insn	2, 0x0000
     82a:	4504                	.insn	2, 0x4504
     82c:	0000                	.insn	2, 0x0000
     82e:	1300                	.insn	2, 0x1300
     830:	0200                	.insn	2, 0x0200
     832:	007f 0000 f401 a102 	.insn	10, 0x0303a102f4010000007f
     83a:	0303 
     83c:	0041                	.insn	2, 0x0041
     83e:	0000                	.insn	2, 0x0000
     840:	4504                	.insn	2, 0x4504
     842:	0000                	.insn	2, 0x0000
     844:	1800                	.insn	2, 0x1800
     846:	0200                	.insn	2, 0x0200
     848:	0095                	.insn	2, 0x0095
     84a:	0000                	.insn	2, 0x0000
     84c:	fc01                	.insn	2, 0xfc01
     84e:	a102                	.insn	2, 0xa102
     850:	0304                	.insn	2, 0x0304
     852:	0041                	.insn	2, 0x0041
     854:	0000                	.insn	2, 0x0000
     856:	4504                	.insn	2, 0x4504
     858:	0000                	.insn	2, 0x0000
     85a:	1e00                	.insn	2, 0x1e00
     85c:	0700                	.insn	2, 0x0700
     85e:	00ac                	.insn	2, 0x00ac
     860:	0000                	.insn	2, 0x0000
     862:	3901                	.insn	2, 0x3901
     864:	0201                	.insn	2, 0x0201
     866:	05a1                	.insn	2, 0x05a1
     868:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
     86c:	0400                	.insn	2, 0x0400
     86e:	0045                	.insn	2, 0x0045
     870:	0000                	.insn	2, 0x0000
     872:	001a                	.insn	2, 0x001a
     874:	0000c307          	.insn	4, 0xc307
     878:	0100                	.insn	2, 0x0100
     87a:	0140                	.insn	2, 0x0140
     87c:	a102                	.insn	2, 0xa102
     87e:	0306                	.insn	2, 0x0306
     880:	0041                	.insn	2, 0x0041
     882:	0000                	.insn	2, 0x0000
     884:	4504                	.insn	2, 0x4504
     886:	0000                	.insn	2, 0x0000
     888:	0c00                	.insn	2, 0x0c00
     88a:	0700                	.insn	2, 0x0700
     88c:	00da                	.insn	2, 0x00da
     88e:	0000                	.insn	2, 0x0000
     890:	4401                	.insn	2, 0x4401
     892:	0201                	.insn	2, 0x0201
     894:	07a1                	.insn	2, 0x07a1
     896:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
     89a:	0400                	.insn	2, 0x0400
     89c:	0045                	.insn	2, 0x0045
     89e:	0000                	.insn	2, 0x0000
     8a0:	000e                	.insn	2, 0x000e
     8a2:	0000f107          	.insn	4, 0xf107
     8a6:	0100                	.insn	2, 0x0100
     8a8:	0148                	.insn	2, 0x0148
     8aa:	a102                	.insn	2, 0xa102
     8ac:	0308                	.insn	2, 0x0308
     8ae:	0041                	.insn	2, 0x0041
     8b0:	0000                	.insn	2, 0x0000
     8b2:	4504                	.insn	2, 0x4504
     8b4:	0000                	.insn	2, 0x0000
     8b6:	1100                	.insn	2, 0x1100
     8b8:	0700                	.insn	2, 0x0700
     8ba:	0108                	.insn	2, 0x0108
     8bc:	0000                	.insn	2, 0x0000
     8be:	4c01                	.insn	2, 0x4c01
     8c0:	0201                	.insn	2, 0x0201
     8c2:	09a1                	.insn	2, 0x09a1
     8c4:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
     8c8:	0400                	.insn	2, 0x0400
     8ca:	0045                	.insn	2, 0x0045
     8cc:	0000                	.insn	2, 0x0000
     8ce:	0012                	.insn	2, 0x0012
     8d0:	0000f107          	.insn	4, 0xf107
     8d4:	0100                	.insn	2, 0x0100
     8d6:	01ac                	.insn	2, 0x01ac
     8d8:	a102                	.insn	2, 0xa102
     8da:	080a                	.insn	2, 0x080a
     8dc:	0128                	.insn	2, 0x0128
     8de:	0000                	.insn	2, 0x0000
     8e0:	0206                	.insn	2, 0x0206
     8e2:	010e                	.insn	2, 0x010e
     8e4:	0505                	.insn	2, 0x0505
     8e6:	0108                	.insn	2, 0x0108
     8e8:	3409                	.insn	2, 0x3409
     8ea:	0001                	.insn	2, 0x0001
     8ec:	0800                	.insn	2, 0x0800
     8ee:	ca02                	.insn	2, 0xca02
     8f0:	0705                	.insn	2, 0x0705
     8f2:	34080407          	.insn	4, 0x34080407
     8f6:	0001                	.insn	2, 0x0001
     8f8:	0900                	.insn	2, 0x0900
     8fa:	2e02                	.insn	2, 0x2e02
     8fc:	0501                	.insn	2, 0x0501
     8fe:	050a                	.insn	2, 0x050a
     900:	0a04                	.insn	2, 0x0a04
     902:	0128                	.insn	2, 0x0128
     904:	0000                	.insn	2, 0x0000
     906:	4109                	.insn	2, 0x4109
     908:	0001                	.insn	2, 0x0001
     90a:	0b00                	.insn	2, 0x0b00
     90c:	c502                	.insn	2, 0xc502
     90e:	3a010c0b          	.insn	4, 0x3a010c0b
     912:	0141                	.insn	2, 0x0141
     914:	0000                	.insn	2, 0x0000
     916:	0d0c                	.insn	2, 0x0d0c
     918:	3a01                	.insn	2, 0x3a01
     91a:	0141                	.insn	2, 0x0141
     91c:	0000                	.insn	2, 0x0000
     91e:	0e0c                	.insn	2, 0x0e0c
     920:	3a01                	.insn	2, 0x3a01
     922:	0141                	.insn	2, 0x0141
     924:	0000                	.insn	2, 0x0000
     926:	0f0c                	.insn	2, 0x0f0c
     928:	3a01                	.insn	2, 0x3a01
     92a:	0141                	.insn	2, 0x0141
     92c:	0000                	.insn	2, 0x0000
     92e:	100c                	.insn	2, 0x100c
     930:	3a01                	.insn	2, 0x3a01
     932:	0141                	.insn	2, 0x0141
     934:	0000                	.insn	2, 0x0000
     936:	110d                	.insn	2, 0x110d
     938:	3c01                	.insn	2, 0x3c01
     93a:	0141                	.insn	2, 0x0141
     93c:	0000                	.insn	2, 0x0000
     93e:	120d                	.insn	2, 0x120d
     940:	3d01                	.insn	2, 0x3d01
     942:	0141                	.insn	2, 0x0141
     944:	0000                	.insn	2, 0x0000
     946:	130d                	.insn	2, 0x130d
     948:	3e01                	.insn	2, 0x3e01
     94a:	0141                	.insn	2, 0x0141
     94c:	0000                	.insn	2, 0x0000
     94e:	140d                	.insn	2, 0x140d
     950:	3f01                	.insn	2, 0x3f01
     952:	0141                	.insn	2, 0x0141
     954:	0000                	.insn	2, 0x0000
     956:	0e00                	.insn	2, 0x0e00
     958:	0000180b          	.insn	4, 0x180b
     95c:	0100                	.insn	2, 0x0100
     95e:	2852                	.insn	2, 0x2852
     960:	4e01                	.insn	2, 0x4e01
     962:	0001520f          	.insn	4, 0x0001520f
     966:	0b00                	.insn	2, 0x0b00
     968:	0014                	.insn	2, 0x0014
     96a:	0000                	.insn	2, 0x0000
     96c:	5301                	.insn	2, 0x5301
     96e:	1005                	.insn	2, 0x1005
     970:	00da                	.insn	2, 0x00da
     972:	015a                	.insn	2, 0x015a
     974:	0000                	.insn	2, 0x0000
     976:	0010                	.insn	2, 0x0010
     978:	0162                	.insn	2, 0x0162
     97a:	0000                	.insn	2, 0x0000
     97c:	0010                	.insn	2, 0x0010
     97e:	016a                	.insn	2, 0x016a
     980:	0000                	.insn	2, 0x0000
     982:	0010                	.insn	2, 0x0010
     984:	0172                	.insn	2, 0x0172
     986:	0000                	.insn	2, 0x0000
     988:	0011                	.insn	2, 0x0011
     98a:	017a                	.insn	2, 0x017a
     98c:	0000                	.insn	2, 0x0000
     98e:	0012                	.insn	2, 0x0012
     990:	0182                	.insn	2, 0x0182
     992:	0000                	.insn	2, 0x0000
     994:	0012                	.insn	2, 0x0012
     996:	018a                	.insn	2, 0x018a
     998:	0000                	.insn	2, 0x0000
     99a:	da12                	.insn	2, 0xda12
     99c:	9200                	.insn	2, 0x9200
     99e:	0001                	.insn	2, 0x0001
     9a0:	0000                	.insn	2, 0x0000
     9a2:	1300                	.insn	2, 0x1300
     9a4:	0115                	.insn	2, 0x0115
     9a6:	0251                	.insn	2, 0x0251
     9a8:	0000024b          	.insn	4, 0x024b
     9ac:	0d14                	.insn	2, 0x0d14
     9ae:	5201                	.insn	2, 0x5201
     9b0:	2c02                	.insn	2, 0x2c02
     9b2:	0001                	.insn	2, 0x0001
     9b4:	1400                	.insn	2, 0x1400
     9b6:	010e                	.insn	2, 0x010e
     9b8:	012c0253          	.insn	4, 0x012c0253
     9bc:	0000                	.insn	2, 0x0000
     9be:	0f14                	.insn	2, 0x0f14
     9c0:	5401                	.insn	2, 0x5401
     9c2:	2c02                	.insn	2, 0x2c02
     9c4:	0001                	.insn	2, 0x0001
     9c6:	1400                	.insn	2, 0x1400
     9c8:	0110                	.insn	2, 0x0110
     9ca:	0255                	.insn	2, 0x0255
     9cc:	012c                	.insn	2, 0x012c
     9ce:	0000                	.insn	2, 0x0000
     9d0:	1614                	.insn	2, 0x1614
     9d2:	5601                	.insn	2, 0x5601
     9d4:	2c02                	.insn	2, 0x2c02
     9d6:	0001                	.insn	2, 0x0001
     9d8:	1500                	.insn	2, 0x1500
     9da:	02590117          	auipc	sp,0x2590
     9de:	012c                	.insn	2, 0x012c
     9e0:	0000                	.insn	2, 0x0000
     9e2:	1815                	.insn	2, 0x1815
     9e4:	5a01                	.insn	2, 0x5a01
     9e6:	2c02                	.insn	2, 0x2c02
     9e8:	0001                	.insn	2, 0x0001
     9ea:	1500                	.insn	2, 0x1500
     9ec:	0119                	.insn	2, 0x0119
     9ee:	0258                	.insn	2, 0x0258
     9f0:	012c                	.insn	2, 0x012c
     9f2:	0000                	.insn	2, 0x0000
     9f4:	1a15                	.insn	2, 0x1a15
     9f6:	5b01                	.insn	2, 0x5b01
     9f8:	2c02                	.insn	2, 0x2c02
     9fa:	0001                	.insn	2, 0x0001
     9fc:	1500                	.insn	2, 0x1500
     9fe:	025c011b          	.insn	4, 0x025c011b
     a02:	012c                	.insn	2, 0x012c
     a04:	0000                	.insn	2, 0x0000
     a06:	0900                	.insn	2, 0x0900
     a08:	0134                	.insn	2, 0x0134
     a0a:	0000                	.insn	2, 0x0000
     a0c:	0308                	.insn	2, 0x0308
     a0e:	1611                	.insn	2, 0x1611
     a10:	011c                	.insn	2, 0x011c
     a12:	0219                	.insn	2, 0x0219
     a14:	1d14                	.insn	2, 0x1d14
     a16:	1901                	.insn	2, 0x1901
     a18:	4102                	.insn	2, 0x4102
     a1a:	0000                	.insn	2, 0x0000
     a1c:	0000                	.insn	2, 0x0000
     a1e:	1e16                	.insn	2, 0x1e16
     a20:	4101                	.insn	2, 0x4101
     a22:	1402                	.insn	2, 0x1402
     a24:	011f 0241 0141      	.insn	6, 0x01410241011f
     a2a:	0000                	.insn	2, 0x0000
     a2c:	1700                	.insn	2, 0x1700
     a2e:	640c                	.insn	2, 0x640c
     a30:	0002                	.insn	2, 0x0002
     a32:	0100                	.insn	2, 0x0100
     a34:	2952                	.insn	2, 0x2952
     a36:	7801                	.insn	2, 0x7801
     a38:	0118                	.insn	2, 0x0118
     a3a:	0140                	.insn	2, 0x0140
     a3c:	2c78                	.insn	2, 0x2c78
     a3e:	0001                	.insn	2, 0x0001
     a40:	1900                	.insn	2, 0x1900
     a42:	0a909103          	lh	sp,169(ra)
     a46:	013d                	.insn	2, 0x013d
     a48:	bc80                	.insn	2, 0xbc80
     a4a:	1900000b          	.insn	4, 0x1900000b
     a4e:	08909103          	lh	sp,137(ra)
     a52:	013e                	.insn	2, 0x013e
     a54:	bc81                	.insn	2, 0xbc81
     a56:	1900000b          	.insn	4, 0x1900000b
     a5a:	9102                	.insn	2, 0x9102
     a5c:	3f10                	.insn	2, 0x3f10
     a5e:	8201                	.insn	2, 0x8201
     a60:	0bc9                	.insn	2, 0x0bc9
     a62:	0000                	.insn	2, 0x0000
     a64:	0d1a                	.insn	2, 0x0d1a
     a66:	007c                	.insn	2, 0x007c
     a68:	0000                	.insn	2, 0x0000
     a6a:	0141021b          	.insn	4, 0x0141021b
     a6e:	00012c8b          	.insn	4, 0x00012c8b
     a72:	1a00                	.insn	2, 0x1a00
     a74:	500e                	.insn	2, 0x500e
     a76:	0000                	.insn	2, 0x0000
     a78:	1b00                	.insn	2, 0x1b00
     a7a:	8c014203          	lbu	tp,-1856(sp) # 259029a <USER_MAX+0x209029a>
     a7e:	012c                	.insn	2, 0x012c
     a80:	0000                	.insn	2, 0x0000
     a82:	001c                	.insn	2, 0x001c
     a84:	430d                	.insn	2, 0x430d
     a86:	8d01                	.insn	2, 0x8d01
     a88:	0bd6                	.insn	2, 0x0bd6
     a8a:	0000                	.insn	2, 0x0000
     a8c:	0000                	.insn	2, 0x0000
     a8e:	0f00                	.insn	2, 0x0f00
     a90:	000001e7          	jalr	gp,zero # 0 <start-0x400000>
     a94:	0000180f          	.insn	4, 0x180f
     a98:	0100                	.insn	2, 0x0100
     a9a:	0595                	.insn	2, 0x0595
     a9c:	041d                	.insn	2, 0x041d
     a9e:	9091                	.insn	2, 0x9091
     aa0:	9f08                	.insn	2, 0x9f08
     aa2:	0202                	.insn	2, 0x0202
     aa4:	0000                	.insn	2, 0x0000
     aa6:	031d                	.insn	2, 0x031d
     aa8:	1091                	.insn	2, 0x1091
     aaa:	0b9f 0002 1e00      	.insn	6, 0x1e0000020b9f
     ab0:	9104                	.insn	2, 0x9104
     ab2:	0890                	.insn	2, 0x0890
     ab4:	1d9f 0002 1e00      	.insn	6, 0x1e0000021d9f
     aba:	9f109103          	lh	sp,-1551(ra)
     abe:	0226                	.insn	2, 0x0226
     ac0:	0000                	.insn	2, 0x0000
     ac2:	0411                	.insn	2, 0x0411
     ac4:	0000022f          	.insn	4, 0x022f
     ac8:	0f00                	.insn	2, 0x0f00
     aca:	00000253          	.insn	4, 0x0253
     ace:	0c10                	.insn	2, 0x0c10
     ad0:	0000                	.insn	2, 0x0000
     ad2:	0100                	.insn	2, 0x0100
     ad4:	059d                	.insn	2, 0x059d
     ad6:	411f 0258 0000      	.insn	6, 0x0258411f
     adc:	0f00                	.insn	2, 0x0f00
     ade:	00000253          	.insn	4, 0x0253
     ae2:	1811                	.insn	2, 0x1811
     ae4:	0000                	.insn	2, 0x0000
     ae6:	0100                	.insn	2, 0x0100
     ae8:	059e                	.insn	2, 0x059e
     aea:	0a1f 0258 0000      	.insn	6, 0x02580a1f
     af0:	1a00                	.insn	2, 0x1a00
     af2:	4c12                	.insn	2, 0x4c12
     af4:	0000                	.insn	2, 0x0000
     af6:	1b00                	.insn	2, 0x1b00
     af8:	4105                	.insn	2, 0x4105
     afa:	a001                	.insn	2, 0xa001
     afc:	012c                	.insn	2, 0x012c
     afe:	0000                	.insn	2, 0x0000
     b00:	121a                	.insn	2, 0x121a
     b02:	0034                	.insn	2, 0x0034
     b04:	0000                	.insn	2, 0x0000
     b06:	0142061b          	.insn	4, 0x0142061b
     b0a:	2ca1                	.insn	2, 0x2ca1
     b0c:	0001                	.insn	2, 0x0001
     b0e:	0f00                	.insn	2, 0x0f00
     b10:	0262                	.insn	2, 0x0262
     b12:	0000                	.insn	2, 0x0000
     b14:	00000c13          	li	s8,0
     b18:	0100                	.insn	2, 0x0100
     b1a:	0da2                	.insn	2, 0x0da2
     b1c:	011d                	.insn	2, 0x011d
     b1e:	676c                	.insn	2, 0x676c
     b20:	0002                	.insn	2, 0x0002
     b22:	0000                	.insn	2, 0x0000
     b24:	0002530f          	.insn	4, 0x0002530f
     b28:	1400                	.insn	2, 0x1400
     b2a:	000c                	.insn	2, 0x000c
     b2c:	0000                	.insn	2, 0x0000
     b2e:	a301                	.insn	2, 0xa301
     b30:	1f0d                	.insn	2, 0x1f0d
     b32:	5820                	.insn	2, 0x5820
     b34:	0002                	.insn	2, 0x0002
     b36:	0000                	.insn	2, 0x0000
     b38:	0f00                	.insn	2, 0x0f00
     b3a:	00000253          	.insn	4, 0x0253
     b3e:	0c15                	.insn	2, 0x0c15
     b40:	0000                	.insn	2, 0x0000
     b42:	0100                	.insn	2, 0x0100
     b44:	09a5                	.insn	2, 0x09a5
     b46:	0a1f 0258 0000      	.insn	6, 0x02580a1f
     b4c:	0000                	.insn	2, 0x0000
     b4e:	0002530f          	.insn	4, 0x0002530f
     b52:	1600                	.insn	2, 0x1600
     b54:	000c                	.insn	2, 0x000c
     b56:	0000                	.insn	2, 0x0000
     b58:	a801                	.insn	2, 0xa801
     b5a:	1f05                	.insn	2, 0x1f05
     b5c:	580a                	.insn	2, 0x580a
     b5e:	0002                	.insn	2, 0x0002
     b60:	0000                	.insn	2, 0x0000
     b62:	0002530f          	.insn	4, 0x0002530f
     b66:	1700                	.insn	2, 0x1700
     b68:	000c                	.insn	2, 0x000c
     b6a:	0000                	.insn	2, 0x0000
     b6c:	a901                	.insn	2, 0xa901
     b6e:	1f05                	.insn	2, 0x1f05
     b70:	5842                	.insn	2, 0x5842
     b72:	0002                	.insn	2, 0x0002
     b74:	0000                	.insn	2, 0x0000
     b76:	0002530f          	.insn	4, 0x0002530f
     b7a:	1800                	.insn	2, 0x1800
     b7c:	0018                	.insn	2, 0x0018
     b7e:	0000                	.insn	2, 0x0000
     b80:	aa01                	.insn	2, 0xaa01
     b82:	1f05                	.insn	2, 0x1f05
     b84:	580a                	.insn	2, 0x580a
     b86:	0002                	.insn	2, 0x0002
     b88:	0000                	.insn	2, 0x0000
     b8a:	191a                	.insn	2, 0x191a
     b8c:	004c                	.insn	2, 0x004c
     b8e:	0000                	.insn	2, 0x0000
     b90:	0141071b          	.insn	4, 0x0141071b
     b94:	2cac                	.insn	2, 0x2cac
     b96:	0001                	.insn	2, 0x0001
     b98:	1a00                	.insn	2, 0x1a00
     b9a:	3419                	.insn	2, 0x3419
     b9c:	0000                	.insn	2, 0x0000
     b9e:	1b00                	.insn	2, 0x1b00
     ba0:	4208                	.insn	2, 0x4208
     ba2:	ad01                	.insn	2, 0xad01
     ba4:	012c                	.insn	2, 0x012c
     ba6:	0000                	.insn	2, 0x0000
     ba8:	0002620f          	.insn	4, 0x0002620f
     bac:	1a00                	.insn	2, 0x1a00
     bae:	000c                	.insn	2, 0x000c
     bb0:	0000                	.insn	2, 0x0000
     bb2:	ae01                	.insn	2, 0xae01
     bb4:	1d0d                	.insn	2, 0x1d0d
     bb6:	6c01                	.insn	2, 0x6c01
     bb8:	00000267          	jalr	tp,zero # 0 <start-0x400000>
     bbc:	0f00                	.insn	2, 0x0f00
     bbe:	00000253          	.insn	4, 0x0253
     bc2:	00000c1b          	.insn	4, 0x0c1b
     bc6:	0100                	.insn	2, 0x0100
     bc8:	201f0daf          	.insn	4, 0x201f0daf
     bcc:	0258                	.insn	2, 0x0258
     bce:	0000                	.insn	2, 0x0000
     bd0:	0000                	.insn	2, 0x0000
     bd2:	0002530f          	.insn	4, 0x0002530f
     bd6:	1c00                	.insn	2, 0x1c00
     bd8:	000c                	.insn	2, 0x000c
     bda:	0000                	.insn	2, 0x0000
     bdc:	b101                	.insn	2, 0xb101
     bde:	1f09                	.insn	2, 0x1f09
     be0:	580a                	.insn	2, 0x580a
     be2:	0002                	.insn	2, 0x0002
     be4:	0000                	.insn	2, 0x0000
     be6:	0f00                	.insn	2, 0x0f00
     be8:	00000253          	.insn	4, 0x0253
     bec:	0c1d                	.insn	2, 0x0c1d
     bee:	0000                	.insn	2, 0x0000
     bf0:	0100                	.insn	2, 0x0100
     bf2:	05b4                	.insn	2, 0x05b4
     bf4:	0a1f 0258 0000      	.insn	6, 0x02580a1f
     bfa:	0f00                	.insn	2, 0x0f00
     bfc:	00000253          	.insn	4, 0x0253
     c00:	0c1e                	.insn	2, 0x0c1e
     c02:	0000                	.insn	2, 0x0000
     c04:	0100                	.insn	2, 0x0100
     c06:	05b5                	.insn	2, 0x05b5
     c08:	431f 0258 0000      	.insn	6, 0x0258431f
     c0e:	0f00                	.insn	2, 0x0f00
     c10:	00000253          	.insn	4, 0x0253
     c14:	181f 0000 0100      	.insn	6, 0x01000000181f
     c1a:	05b6                	.insn	2, 0x05b6
     c1c:	0a1f 0258 0000      	.insn	6, 0x02580a1f
     c22:	1a00                	.insn	2, 0x1a00
     c24:	4c20                	.insn	2, 0x4c20
     c26:	0000                	.insn	2, 0x0000
     c28:	1b00                	.insn	2, 0x1b00
     c2a:	4109                	.insn	2, 0x4109
     c2c:	b801                	.insn	2, 0xb801
     c2e:	012c                	.insn	2, 0x012c
     c30:	0000                	.insn	2, 0x0000
     c32:	201a                	.insn	2, 0x201a
     c34:	0034                	.insn	2, 0x0034
     c36:	0000                	.insn	2, 0x0000
     c38:	01420a1b          	.insn	4, 0x01420a1b
     c3c:	2cb9                	.insn	2, 0x2cb9
     c3e:	0001                	.insn	2, 0x0001
     c40:	0f00                	.insn	2, 0x0f00
     c42:	0262                	.insn	2, 0x0262
     c44:	0000                	.insn	2, 0x0000
     c46:	0c21                	.insn	2, 0x0c21
     c48:	0000                	.insn	2, 0x0000
     c4a:	0100                	.insn	2, 0x0100
     c4c:	0dba                	.insn	2, 0x0dba
     c4e:	011d                	.insn	2, 0x011d
     c50:	676c                	.insn	2, 0x676c
     c52:	0002                	.insn	2, 0x0002
     c54:	0000                	.insn	2, 0x0000
     c56:	0002530f          	.insn	4, 0x0002530f
     c5a:	2200                	.insn	2, 0x2200
     c5c:	000c                	.insn	2, 0x000c
     c5e:	0000                	.insn	2, 0x0000
     c60:	bb01                	.insn	2, 0xbb01
     c62:	1f0d                	.insn	2, 0x1f0d
     c64:	5820                	.insn	2, 0x5820
     c66:	0002                	.insn	2, 0x0002
     c68:	0000                	.insn	2, 0x0000
     c6a:	0f00                	.insn	2, 0x0f00
     c6c:	00000253          	.insn	4, 0x0253
     c70:	00000c23          	sb	zero,24(zero) # 18 <start-0x3fffe8>
     c74:	0100                	.insn	2, 0x0100
     c76:	09bd                	.insn	2, 0x09bd
     c78:	0a1f 0258 0000      	.insn	6, 0x02580a1f
     c7e:	0000                	.insn	2, 0x0000
     c80:	0002530f          	.insn	4, 0x0002530f
     c84:	2400                	.insn	2, 0x2400
     c86:	000c                	.insn	2, 0x000c
     c88:	0000                	.insn	2, 0x0000
     c8a:	c001                	.insn	2, 0xc001
     c8c:	1f05                	.insn	2, 0x1f05
     c8e:	580a                	.insn	2, 0x580a
     c90:	0002                	.insn	2, 0x0002
     c92:	0000                	.insn	2, 0x0000
     c94:	df20                	.insn	2, 0xdf20
     c96:	0004                	.insn	2, 0x0004
     c98:	2500                	.insn	2, 0x2500
     c9a:	2100                	.insn	2, 0x2100
     c9c:	b826                	.insn	2, 0xb826
     c9e:	0002                	.insn	2, 0x0002
     ca0:	0100                	.insn	2, 0x0100
     ca2:	2a52                	.insn	2, 0x2a52
     ca4:	7101                	.insn	2, 0x7101
     ca6:	2201                	.insn	2, 0x2201
     ca8:	7101470b          	.insn	4, 0x7101470b
     cac:	7b01                	.insn	2, 0x7b01
     cae:	23000007          	.insn	4, 0x23000007
     cb2:	9102                	.insn	2, 0x9102
     cb4:	440c                	.insn	2, 0x440c
     cb6:	7201                	.insn	2, 0x7201
     cb8:	db01                	.insn	2, 0xdb01
     cba:	2400000b          	.insn	4, 0x2400000b
     cbe:	014c                	.insn	2, 0x014c
     cc0:	4d0101b7          	lui	gp,0x4d010
     cc4:	011c                	.insn	2, 0x011c
     cc6:	01910223          	sb	s9,4(sp)
     cca:	0146                	.insn	2, 0x0146
     ccc:	0194                	.insn	2, 0x0194
     cce:	0be2                	.insn	2, 0x0be2
     cd0:	0000                	.insn	2, 0x0000
     cd2:	0c25                	.insn	2, 0x0c25
     cd4:	0148                	.insn	2, 0x0148
     cd6:	0188                	.insn	2, 0x0188
     cd8:	0141                	.insn	2, 0x0141
     cda:	0000                	.insn	2, 0x0000
     cdc:	0d25                	.insn	2, 0x0d25
     cde:	0149                	.insn	2, 0x0149
     ce0:	018a                	.insn	2, 0x018a
     ce2:	0134                	.insn	2, 0x0134
     ce4:	0000                	.insn	2, 0x0000
     ce6:	0e25                	.insn	2, 0x0e25
     ce8:	0141                	.insn	2, 0x0141
     cea:	0195                	.insn	2, 0x0195
     cec:	0141                	.insn	2, 0x0141
     cee:	0000                	.insn	2, 0x0000
     cf0:	5326                	.insn	2, 0x5326
     cf2:	0002                	.insn	2, 0x0002
     cf4:	2700                	.insn	2, 0x2700
     cf6:	000c                	.insn	2, 0x000c
     cf8:	0000                	.insn	2, 0x0000
     cfa:	8c01                	.insn	2, 0x8c01
     cfc:	1901                	.insn	2, 0x1901
     cfe:	2d1f 0258 0000      	.insn	6, 0x02582d1f
     d04:	2600                	.insn	2, 0x2600
     d06:	00000253          	.insn	4, 0x0253
     d0a:	0c28                	.insn	2, 0x0c28
     d0c:	0000                	.insn	2, 0x0000
     d0e:	0100                	.insn	2, 0x0100
     d10:	0199                	.insn	2, 0x0199
     d12:	1f19                	.insn	2, 0x1f19
     d14:	5830                	.insn	2, 0x5830
     d16:	0002                	.insn	2, 0x0002
     d18:	0000                	.insn	2, 0x0000
     d1a:	00025327          	.insn	4, 0x00025327
     d1e:	2900                	.insn	2, 0x2900
     d20:	000c                	.insn	2, 0x000c
     d22:	0000                	.insn	2, 0x0000
     d24:	a401                	.insn	2, 0xa401
     d26:	1901                	.insn	2, 0x1901
     d28:	1a00                	.insn	2, 0x1a00
     d2a:	e82a                	.insn	2, 0xe82a
     d2c:	0000                	.insn	2, 0x0000
     d2e:	2500                	.insn	2, 0x2500
     d30:	a901480f          	.insn	4, 0xa901480f
     d34:	3401                	.insn	2, 0x3401
     d36:	0001                	.insn	2, 0x0001
     d38:	1a00                	.insn	2, 0x1a00
     d3a:	0000d82b          	.insn	4, 0xd82b
     d3e:	2500                	.insn	2, 0x2500
     d40:	4110                	.insn	2, 0x4110
     d42:	aa01                	.insn	2, 0xaa01
     d44:	4101                	.insn	2, 0x4101
     d46:	0001                	.insn	2, 0x0001
     d48:	1a00                	.insn	2, 0x1a00
     d4a:	0000d82b          	.insn	4, 0xd82b
     d4e:	2500                	.insn	2, 0x2500
     d50:	4a11                	.insn	2, 0x4a11
     d52:	ab01                	.insn	2, 0xab01
     d54:	3401                	.insn	2, 0x3401
     d56:	0001                	.insn	2, 0x0001
     d58:	2800                	.insn	2, 0x2800
     d5a:	00000253          	.insn	4, 0x0253
     d5e:	0102                	.insn	2, 0x0102
     d60:	01ac                	.insn	2, 0x01ac
     d62:	0019                	.insn	2, 0x0019
     d64:	0000                	.insn	2, 0x0000
     d66:	5326                	.insn	2, 0x5326
     d68:	0002                	.insn	2, 0x0002
     d6a:	2c00                	.insn	2, 0x2c00
     d6c:	000c                	.insn	2, 0x000c
     d6e:	0000                	.insn	2, 0x0000
     d70:	7d01                	.insn	2, 0x7d01
     d72:	1501                	.insn	2, 0x1501
     d74:	251f 0258 0000      	.insn	6, 0x0258251f
     d7a:	1a00                	.insn	2, 0x1a00
     d7c:	382d                	.insn	2, 0x382d
     d7e:	0000                	.insn	2, 0x0000
     d80:	2500                	.insn	2, 0x2500
     d82:	4b12                	.insn	2, 0x4b12
     d84:	8001                	.insn	2, 0x8001
     d86:	7b01                	.insn	2, 0x7b01
     d88:	26000007          	.insn	4, 0x26000007
     d8c:	00000253          	.insn	4, 0x0253
     d90:	0c2e                	.insn	2, 0x0c2e
     d92:	0000                	.insn	2, 0x0000
     d94:	0100                	.insn	2, 0x0100
     d96:	0182                	.insn	2, 0x0182
     d98:	1d19                	.insn	2, 0x1d19
     d9a:	5801                	.insn	2, 0x5801
     d9c:	0258                	.insn	2, 0x0258
     d9e:	0000                	.insn	2, 0x0000
     da0:	0000                	.insn	2, 0x0000
     da2:	5326                	.insn	2, 0x5326
     da4:	0002                	.insn	2, 0x0002
     da6:	2f00                	.insn	2, 0x2f00
     da8:	000c                	.insn	2, 0x000c
     daa:	0000                	.insn	2, 0x0000
     dac:	7a01                	.insn	2, 0x7a01
     dae:	1501                	.insn	2, 0x1501
     db0:	251f 0258 0000      	.insn	6, 0x0258251f
     db6:	2600                	.insn	2, 0x2600
     db8:	00000253          	.insn	4, 0x0253
     dbc:	0c30                	.insn	2, 0x0c30
     dbe:	0000                	.insn	2, 0x0000
     dc0:	0100                	.insn	2, 0x0100
     dc2:	01b1                	.insn	2, 0x01b1
     dc4:	1d0d                	.insn	2, 0x1d0d
     dc6:	5801                	.insn	2, 0x5801
     dc8:	0258                	.insn	2, 0x0258
     dca:	0000                	.insn	2, 0x0000
     dcc:	2900                	.insn	2, 0x2900
     dce:	2a00                	.insn	2, 0x2a00
     dd0:	1431                	.insn	2, 0x1431
     dd2:	0000                	.insn	2, 0x0000
     dd4:	0100                	.insn	2, 0x0100
     dd6:	5352                	.insn	2, 0x5352
     dd8:	0002                	.insn	2, 0x0002
     dda:	2b00                	.insn	2, 0x2b00
     ddc:	00025813          	srli	a6,tp,0x0
     de0:	0000                	.insn	2, 0x0000
     de2:	322a                	.insn	2, 0x322a
     de4:	0014                	.insn	2, 0x0014
     de6:	0000                	.insn	2, 0x0000
     de8:	5201                	.insn	2, 0x5201
     dea:	0262                	.insn	2, 0x0262
     dec:	0000                	.insn	2, 0x0000
     dee:	0267142b          	.insn	4, 0x0267142b
     df2:	0000                	.insn	2, 0x0000
     df4:	1300                	.insn	2, 0x1300
     df6:	0120                	.insn	2, 0x0120
     df8:	026c                	.insn	2, 0x026c
     dfa:	0000024b          	.insn	4, 0x024b
     dfe:	0d14                	.insn	2, 0x0d14
     e00:	6c01                	.insn	2, 0x6c01
     e02:	2c02                	.insn	2, 0x2c02
     e04:	0001                	.insn	2, 0x0001
     e06:	1400                	.insn	2, 0x1400
     e08:	010e                	.insn	2, 0x010e
     e0a:	026c                	.insn	2, 0x026c
     e0c:	012c                	.insn	2, 0x012c
     e0e:	0000                	.insn	2, 0x0000
     e10:	1115                	.insn	2, 0x1115
     e12:	6e01                	.insn	2, 0x6e01
     e14:	2c02                	.insn	2, 0x2c02
     e16:	0001                	.insn	2, 0x0001
     e18:	1500                	.insn	2, 0x1500
     e1a:	0114                	.insn	2, 0x0114
     e1c:	012c026f          	jal	tp,c0e2e <start-0x33f1d2>
     e20:	0000                	.insn	2, 0x0000
     e22:	1700                	.insn	2, 0x1700
     e24:	00000c33          	add	s8,zero,zero
     e28:	0100                	.insn	2, 0x0100
     e2a:	2b52                	.insn	2, 0x2b52
     e2c:	c501                	.insn	2, 0xc501
     e2e:	1518                	.insn	2, 0x1518
     e30:	014d                	.insn	2, 0x014d
     e32:	34c5                	.insn	2, 0x34c5
     e34:	0001                	.insn	2, 0x0001
     e36:	0f00                	.insn	2, 0x0f00
     e38:	0639                	.insn	2, 0x0639
     e3a:	0000                	.insn	2, 0x0000
     e3c:	00000833          	add	a6,zero,zero
     e40:	0100                	.insn	2, 0x0100
     e42:	05c8                	.insn	2, 0x05c8
     e44:	141f 0642 0000      	.insn	6, 0x0642141f
     e4a:	011d                	.insn	2, 0x011d
     e4c:	4b5a                	.insn	2, 0x4b5a
     e4e:	0006                	.insn	2, 0x0006
     e50:	1e00                	.insn	2, 0x1e00
     e52:	5a01                	.insn	2, 0x5a01
     e54:	0654                	.insn	2, 0x0654
     e56:	0000                	.insn	2, 0x0000
     e58:	142c                	.insn	2, 0x142c
     e5a:	065d                	.insn	2, 0x065d
     e5c:	0000                	.insn	2, 0x0000
     e5e:	0000                	.insn	2, 0x0000
     e60:	cf01210b          	.insn	4, 0xcf01210b
     e64:	012c                	.insn	2, 0x012c
     e66:	0000                	.insn	2, 0x0000
     e68:	0d0c                	.insn	2, 0x0d0c
     e6a:	d001                	.insn	2, 0xd001
     e6c:	012c                	.insn	2, 0x012c
     e6e:	0000                	.insn	2, 0x0000
     e70:	0e0c                	.insn	2, 0x0e0c
     e72:	d101                	.insn	2, 0xd101
     e74:	012c                	.insn	2, 0x012c
     e76:	0000                	.insn	2, 0x0000
     e78:	0f0c                	.insn	2, 0x0f0c
     e7a:	d201                	.insn	2, 0xd201
     e7c:	012c                	.insn	2, 0x012c
     e7e:	0000                	.insn	2, 0x0000
     e80:	120d                	.insn	2, 0x120d
     e82:	d501                	.insn	2, 0xd501
     e84:	012c                	.insn	2, 0x012c
     e86:	0000                	.insn	2, 0x0000
     e88:	110d                	.insn	2, 0x110d
     e8a:	d401                	.insn	2, 0xd401
     e8c:	012c                	.insn	2, 0x012c
     e8e:	0000                	.insn	2, 0x0000
     e90:	140d                	.insn	2, 0x140d
     e92:	d601                	.insn	2, 0xd601
     e94:	012c                	.insn	2, 0x012c
     e96:	0000                	.insn	2, 0x0000
     e98:	2d00                	.insn	2, 0x2d00
     e9a:	ac34                	.insn	2, 0xac34
     e9c:	0000                	.insn	2, 0x0000
     e9e:	0100                	.insn	2, 0x0100
     ea0:	2c52                	.insn	2, 0x2c52
     ea2:	e401                	.insn	2, 0xe401
     ea4:	0000024b          	.insn	4, 0x024b
     ea8:	1618                	.insn	2, 0x1618
     eaa:	014d                	.insn	2, 0x014d
     eac:	2ce5                	.insn	2, 0x2ce5
     eae:	0001                	.insn	2, 0x0001
     eb0:	1900                	.insn	2, 0x1900
     eb2:	9102                	.insn	2, 0x9102
     eb4:	4e10                	.insn	2, 0x4e10
     eb6:	e701                	.insn	2, 0xe701
     eb8:	012c                	.insn	2, 0x012c
     eba:	0000                	.insn	2, 0x0000
     ebc:	0219                	.insn	2, 0x0219
     ebe:	0c91                	.insn	2, 0x0c91
     ec0:	2ce8014f          	.insn	4, 0x2ce8014f
     ec4:	0001                	.insn	2, 0x0001
     ec6:	1b00                	.insn	2, 0x1b00
     ec8:	f8015017          	auipc	zero,0xf8015
     ecc:	012c                	.insn	2, 0x012c
     ece:	0000                	.insn	2, 0x0000
     ed0:	a426                	.insn	2, 0xa426
     ed2:	0006                	.insn	2, 0x0006
     ed4:	3500                	.insn	2, 0x3500
     ed6:	0014                	.insn	2, 0x0014
     ed8:	0000                	.insn	2, 0x0000
     eda:	0201                	.insn	2, 0x0201
     edc:	0c01                	.insn	2, 0x0c01
     ede:	151f 06ac 0000      	.insn	6, 0x06ac151f
     ee4:	011d                	.insn	2, 0x011d
     ee6:	b458                	.insn	2, 0xb458
     ee8:	0006                	.insn	2, 0x0006
     eea:	1d00                	.insn	2, 0x1d00
     eec:	5901                	.insn	2, 0x5901
     eee:	06bc                	.insn	2, 0x06bc
     ef0:	0000                	.insn	2, 0x0000
     ef2:	011e                	.insn	2, 0x011e
     ef4:	c459                	.insn	2, 0xc459
     ef6:	0006                	.insn	2, 0x0006
     ef8:	1100                	.insn	2, 0x1100
     efa:	cc18                	.insn	2, 0xcc18
     efc:	0006                	.insn	2, 0x0006
     efe:	2c00                	.insn	2, 0x2c00
     f00:	d415                	.insn	2, 0xd415
     f02:	0006                	.insn	2, 0x0006
     f04:	0000                	.insn	2, 0x0000
     f06:	632e                	.insn	2, 0x632e
     f08:	36000007          	.insn	4, 0x36000007
     f0c:	df2e                	.insn	2, 0xdf2e
     f0e:	0004                	.insn	2, 0x0004
     f10:	3700                	.insn	2, 0x3700
     f12:	922e                	.insn	2, 0x922e
     f14:	38000007          	.insn	4, 0x38000007
     f18:	df2e                	.insn	2, 0xdf2e
     f1a:	0004                	.insn	2, 0x0004
     f1c:	3500                	.insn	2, 0x3500
     f1e:	2f00                	.insn	2, 0x2f00
     f20:	0422                	.insn	2, 0x0422
     f22:	0001410f          	.insn	4, 0x0001410f
     f26:	3000                	.insn	2, 0x3000
     f28:	0000077b          	.insn	4, 0x077b
     f2c:	8530                	.insn	2, 0x8530
     f2e:	30000007          	.insn	4, 0x30000007
     f32:	0785                	.insn	2, 0x0785
     f34:	0000                	.insn	2, 0x0000
     f36:	0a00                	.insn	2, 0x0a00
     f38:	0780                	.insn	2, 0x0780
     f3a:	0000                	.insn	2, 0x0000
     f3c:	4131                	.insn	2, 0x4131
     f3e:	0000                	.insn	2, 0x0000
     f40:	0a00                	.insn	2, 0x0a00
     f42:	078a                	.insn	2, 0x078a
     f44:	0000                	.insn	2, 0x0000
     f46:	3409                	.insn	2, 0x3409
     f48:	0001                	.insn	2, 0x0001
     f4a:	0800                	.insn	2, 0x0800
     f4c:	1e05                	.insn	2, 0x1e05
     f4e:	2503232f          	.insn	4, 0x2503232f
     f52:	0000024b          	.insn	4, 0x024b
     f56:	4b30                	.insn	2, 0x4b30
     f58:	0002                	.insn	2, 0x0002
     f5a:	0000                	.insn	2, 0x0000
     f5c:	3921                	.insn	2, 0x3921
     f5e:	000c                	.insn	2, 0x000c
     f60:	0000                	.insn	2, 0x0000
     f62:	5201                	.insn	2, 0x5201
     f64:	012d                	.insn	2, 0x012d
     f66:	1922010b          	.insn	4, 0x1922010b
     f6a:	014d                	.insn	2, 0x014d
     f6c:	0134010b          	.insn	4, 0x0134010b
     f70:	0000                	.insn	2, 0x0000
     f72:	3926                	.insn	2, 0x3926
     f74:	0006                	.insn	2, 0x0006
     f76:	3900                	.insn	2, 0x3900
     f78:	0008                	.insn	2, 0x0008
     f7a:	0000                	.insn	2, 0x0000
     f7c:	0e01                	.insn	2, 0x0e01
     f7e:	0501                	.insn	2, 0x0501
     f80:	151f 0642 0000      	.insn	6, 0x0642151f
     f86:	011d                	.insn	2, 0x011d
     f88:	4b5a                	.insn	2, 0x4b5a
     f8a:	0006                	.insn	2, 0x0006
     f8c:	1e00                	.insn	2, 0x1e00
     f8e:	5a01                	.insn	2, 0x5a01
     f90:	0654                	.insn	2, 0x0654
     f92:	0000                	.insn	2, 0x0000
     f94:	152c                	.insn	2, 0x152c
     f96:	065d                	.insn	2, 0x065d
     f98:	0000                	.insn	2, 0x0000
     f9a:	0000                	.insn	2, 0x0000
     f9c:	7c012413          	slti	s0,sp,1984
     fa0:	4b02                	.insn	2, 0x4b02
     fa2:	0002                	.insn	2, 0x0002
     fa4:	1400                	.insn	2, 0x1400
     fa6:	010d                	.insn	2, 0x010d
     fa8:	027c                	.insn	2, 0x027c
     faa:	012c                	.insn	2, 0x012c
     fac:	0000                	.insn	2, 0x0000
     fae:	0e14                	.insn	2, 0x0e14
     fb0:	7c01                	.insn	2, 0x7c01
     fb2:	2c02                	.insn	2, 0x2c02
     fb4:	0001                	.insn	2, 0x0001
     fb6:	1500                	.insn	2, 0x1500
     fb8:	0111                	.insn	2, 0x0111
     fba:	027e                	.insn	2, 0x027e
     fbc:	012c                	.insn	2, 0x012c
     fbe:	0000                	.insn	2, 0x0000
     fc0:	1415                	.insn	2, 0x1415
     fc2:	7f01                	.insn	2, 0x7f01
     fc4:	2c02                	.insn	2, 0x2c02
     fc6:	0001                	.insn	2, 0x0001
     fc8:	0000                	.insn	2, 0x0000
     fca:	3a21                	.insn	2, 0x3a21
     fcc:	000c                	.insn	2, 0x000c
     fce:	0000                	.insn	2, 0x0000
     fd0:	5201                	.insn	2, 0x5201
     fd2:	012e                	.insn	2, 0x012e
     fd4:	0116                	.insn	2, 0x0116
     fd6:	1a22                	.insn	2, 0x1a22
     fd8:	0151                	.insn	2, 0x0151
     fda:	0116                	.insn	2, 0x0116
     fdc:	0134                	.insn	2, 0x0134
     fde:	0000                	.insn	2, 0x0000
     fe0:	e026                	.insn	2, 0xe026
     fe2:	3a000007          	.insn	4, 0x3a000007
     fe6:	0008                	.insn	2, 0x0008
     fe8:	0000                	.insn	2, 0x0000
     fea:	1901                	.insn	2, 0x1901
     fec:	0501                	.insn	2, 0x0501
     fee:	1e1f 07e9 0000      	.insn	6, 0x07e91e1f
     ff4:	011d                	.insn	2, 0x011d
     ff6:	f25a                	.insn	2, 0xf25a
     ff8:	1e000007          	.insn	4, 0x1e000007
     ffc:	5a01                	.insn	2, 0x5a01
     ffe:	000007fb          	.insn	4, 0x07fb
    1002:	1e2c                	.insn	2, 0x1e2c
    1004:	0804                	.insn	2, 0x0804
    1006:	0000                	.insn	2, 0x0000
    1008:	0000                	.insn	2, 0x0000
    100a:	3b21                	.insn	2, 0x3b21
    100c:	000c                	.insn	2, 0x000c
    100e:	0000                	.insn	2, 0x0000
    1010:	5201                	.insn	2, 0x5201
    1012:	0121012f          	.insn	4, 0x0121012f
    1016:	1b22                	.insn	2, 0x1b22
    1018:	0151                	.insn	2, 0x0151
    101a:	0121                	.insn	2, 0x0121
    101c:	0134                	.insn	2, 0x0134
    101e:	0000                	.insn	2, 0x0000
    1020:	e026                	.insn	2, 0xe026
    1022:	3b000007          	.insn	4, 0x3b000007
    1026:	0008                	.insn	2, 0x0008
    1028:	0000                	.insn	2, 0x0000
    102a:	2401                	.insn	2, 0x2401
    102c:	0501                	.insn	2, 0x0501
    102e:	1f1f 07e9 0000      	.insn	6, 0x07e91f1f
    1034:	011d                	.insn	2, 0x011d
    1036:	f25a                	.insn	2, 0xf25a
    1038:	1e000007          	.insn	4, 0x1e000007
    103c:	5a01                	.insn	2, 0x5a01
    103e:	000007fb          	.insn	4, 0x07fb
    1042:	1f2c                	.insn	2, 0x1f2c
    1044:	0804                	.insn	2, 0x0804
    1046:	0000                	.insn	2, 0x0000
    1048:	0000                	.insn	2, 0x0000
    104a:	8c012513          	slti	a0,sp,-1856
    104e:	4b02                	.insn	2, 0x4b02
    1050:	0002                	.insn	2, 0x0002
    1052:	1400                	.insn	2, 0x1400
    1054:	010d                	.insn	2, 0x010d
    1056:	028d                	.insn	2, 0x028d
    1058:	012c                	.insn	2, 0x012c
    105a:	0000                	.insn	2, 0x0000
    105c:	0e14                	.insn	2, 0x0e14
    105e:	8e01                	.insn	2, 0x8e01
    1060:	2c02                	.insn	2, 0x2c02
    1062:	0001                	.insn	2, 0x0001
    1064:	1400                	.insn	2, 0x1400
    1066:	028f010f          	.insn	4, 0x028f010f
    106a:	012c                	.insn	2, 0x012c
    106c:	0000                	.insn	2, 0x0000
    106e:	1115                	.insn	2, 0x1115
    1070:	9101                	.insn	2, 0x9101
    1072:	2c02                	.insn	2, 0x2c02
    1074:	0001                	.insn	2, 0x0001
    1076:	1500                	.insn	2, 0x1500
    1078:	0112                	.insn	2, 0x0112
    107a:	0292                	.insn	2, 0x0292
    107c:	012c                	.insn	2, 0x012c
    107e:	0000                	.insn	2, 0x0000
    1080:	1415                	.insn	2, 0x1415
    1082:	9301                	.insn	2, 0x9301
    1084:	2c02                	.insn	2, 0x2c02
    1086:	0001                	.insn	2, 0x0001
    1088:	0000                	.insn	2, 0x0000
    108a:	3c32                	.insn	2, 0x3c32
    108c:	000c                	.insn	2, 0x000c
    108e:	0000                	.insn	2, 0x0000
    1090:	5201                	.insn	2, 0x5201
    1092:	0130                	.insn	2, 0x0130
    1094:	024b012b          	.insn	4, 0x024b012b
    1098:	0000                	.insn	2, 0x0000
    109a:	1c22                	.insn	2, 0x1c22
    109c:	0151                	.insn	2, 0x0151
    109e:	012c                	.insn	2, 0x012c
    10a0:	012c                	.insn	2, 0x012c
    10a2:	0000                	.insn	2, 0x0000
    10a4:	465b0133          	.insn	4, 0x465b0133
    10a8:	2d01                	.insn	2, 0x2d01
    10aa:	ee01                	.insn	2, 0xee01
    10ac:	2600000b          	.insn	4, 0x2600000b
    10b0:	088e                	.insn	2, 0x088e
    10b2:	0000                	.insn	2, 0x0000
    10b4:	083c                	.insn	2, 0x083c
    10b6:	0000                	.insn	2, 0x0000
    10b8:	0100                	.insn	2, 0x0100
    10ba:	1f0c012f          	.insn	4, 0x1f0c012f
    10be:	9720                	.insn	2, 0x9720
    10c0:	0008                	.insn	2, 0x0008
    10c2:	1d00                	.insn	2, 0x1d00
    10c4:	5a01                	.insn	2, 0x5a01
    10c6:	08a0                	.insn	2, 0x08a0
    10c8:	0000                	.insn	2, 0x0000
    10ca:	011d                	.insn	2, 0x011d
    10cc:	0008a95b          	.insn	4, 0x0008a95b
    10d0:	1e00                	.insn	2, 0x1e00
    10d2:	5a01                	.insn	2, 0x5a01
    10d4:	08b2                	.insn	2, 0x08b2
    10d6:	0000                	.insn	2, 0x0000
    10d8:	011e                	.insn	2, 0x011e
    10da:	0008bb5b          	.insn	4, 0x0008bb5b
    10de:	2c00                	.insn	2, 0x2c00
    10e0:	c420                	.insn	2, 0xc420
    10e2:	0008                	.insn	2, 0x0008
    10e4:	0000                	.insn	2, 0x0000
    10e6:	3400                	.insn	2, 0x3400
    10e8:	0126                	.insn	2, 0x0126
    10ea:	02c4                	.insn	2, 0x02c4
    10ec:	0141                	.insn	2, 0x0141
    10ee:	0000                	.insn	2, 0x0000
    10f0:	1115                	.insn	2, 0x1115
    10f2:	c601                	.insn	2, 0xc601
    10f4:	2c02                	.insn	2, 0x2c02
    10f6:	0001                	.insn	2, 0x0001
    10f8:	1500                	.insn	2, 0x1500
    10fa:	0114                	.insn	2, 0x0114
    10fc:	012c02c7          	.insn	4, 0x012c02c7
    1100:	0000                	.insn	2, 0x0000
    1102:	2100                	.insn	2, 0x2100
    1104:	843d                	.insn	2, 0x843d
    1106:	0000                	.insn	2, 0x0000
    1108:	0100                	.insn	2, 0x0100
    110a:	3152                	.insn	2, 0x3152
    110c:	3701                	.insn	2, 0x3701
    110e:	2501                	.insn	2, 0x2501
    1110:	521e                	.insn	2, 0x521e
    1112:	3b01                	.insn	2, 0x3b01
    1114:	4101                	.insn	2, 0x4101
    1116:	0001                	.insn	2, 0x0001
    1118:	2600                	.insn	2, 0x2600
    111a:	0000092b          	.insn	4, 0x092b
    111e:	103e                	.insn	2, 0x103e
    1120:	0000                	.insn	2, 0x0000
    1122:	0100                	.insn	2, 0x0100
    1124:	013c                	.insn	2, 0x013c
    1126:	1109                	.insn	2, 0x1109
    1128:	341d                	.insn	2, 0x341d
    112a:	0009                	.insn	2, 0x0009
    112c:	2c00                	.insn	2, 0x2c00
    112e:	3d3c                	.insn	2, 0x3d3c
    1130:	0009                	.insn	2, 0x0009
    1132:	0000                	.insn	2, 0x0000
    1134:	df2e                	.insn	2, 0xdf2e
    1136:	0004                	.insn	2, 0x0004
    1138:	3e00                	.insn	2, 0x3e00
    113a:	df20                	.insn	2, 0xdf20
    113c:	0004                	.insn	2, 0x0004
    113e:	3f00                	.insn	2, 0x3f00
    1140:	df20                	.insn	2, 0xdf20
    1142:	0004                	.insn	2, 0x0004
    1144:	4000                	.insn	2, 0x4000
    1146:	2a00                	.insn	2, 0x2a00
    1148:	1041                	.insn	2, 0x1041
    114a:	0000                	.insn	2, 0x0000
    114c:	0100                	.insn	2, 0x0100
    114e:	2b52                	.insn	2, 0x2b52
    1150:	0009                	.insn	2, 0x0009
    1152:	1100                	.insn	2, 0x1100
    1154:	341f 0009 2c00      	.insn	6, 0x2c000009341f
    115a:	3d3c                	.insn	2, 0x3d3c
    115c:	0009                	.insn	2, 0x0009
    115e:	0000                	.insn	2, 0x0000
    1160:	2735                	.insn	2, 0x2735
    1162:	b201                	.insn	2, 0xb201
    1164:	1402                	.insn	2, 0x1402
    1166:	010d                	.insn	2, 0x010d
    1168:	02b2                	.insn	2, 0x02b2
    116a:	012c                	.insn	2, 0x012c
    116c:	0000                	.insn	2, 0x0000
    116e:	0e14                	.insn	2, 0x0e14
    1170:	b301                	.insn	2, 0xb301
    1172:	2c02                	.insn	2, 0x2c02
    1174:	0001                	.insn	2, 0x0001
    1176:	1400                	.insn	2, 0x1400
    1178:	02b4010f          	.insn	4, 0x02b4010f
    117c:	012c                	.insn	2, 0x012c
    117e:	0000                	.insn	2, 0x0000
    1180:	1115                	.insn	2, 0x1115
    1182:	b601                	.insn	2, 0xb601
    1184:	2c02                	.insn	2, 0x2c02
    1186:	0001                	.insn	2, 0x0001
    1188:	1500                	.insn	2, 0x1500
    118a:	0112                	.insn	2, 0x0112
    118c:	012c02b7          	lui	t0,0x12c0
    1190:	0000                	.insn	2, 0x0000
    1192:	1415                	.insn	2, 0x1415
    1194:	b801                	.insn	2, 0xb801
    1196:	2c02                	.insn	2, 0x2c02
    1198:	0001                	.insn	2, 0x0001
    119a:	0000                	.insn	2, 0x0000
    119c:	4221                	.insn	2, 0x4221
    119e:	000c                	.insn	2, 0x000c
    11a0:	0000                	.insn	2, 0x0000
    11a2:	5201                	.insn	2, 0x5201
    11a4:	0132                	.insn	2, 0x0132
    11a6:	01330153          	.insn	4, 0x01330153
    11aa:	535a                	.insn	2, 0x535a
    11ac:	5301                	.insn	2, 0x5301
    11ae:	2c01                	.insn	2, 0x2c01
    11b0:	0001                	.insn	2, 0x0001
    11b2:	3300                	.insn	2, 0x3300
    11b4:	5b01                	.insn	2, 0x5b01
    11b6:	0154                	.insn	2, 0x0154
    11b8:	012c0153          	.insn	4, 0x012c0153
    11bc:	0000                	.insn	2, 0x0000
    11be:	a426                	.insn	2, 0xa426
    11c0:	0009                	.insn	2, 0x0009
    11c2:	4200                	.insn	2, 0x4200
    11c4:	0008                	.insn	2, 0x0008
    11c6:	0000                	.insn	2, 0x0000
    11c8:	5601                	.insn	2, 0x5601
    11ca:	0501                	.insn	2, 0x0501
    11cc:	281f 09a9 0000      	.insn	6, 0x09a9281f
    11d2:	011d                	.insn	2, 0x011d
    11d4:	b25a                	.insn	2, 0xb25a
    11d6:	0009                	.insn	2, 0x0009
    11d8:	1d00                	.insn	2, 0x1d00
    11da:	5b01                	.insn	2, 0x5b01
    11dc:	000009bb          	.insn	4, 0x09bb
    11e0:	011e                	.insn	2, 0x011e
    11e2:	c45a                	.insn	2, 0xc45a
    11e4:	0009                	.insn	2, 0x0009
    11e6:	1e00                	.insn	2, 0x1e00
    11e8:	5b01                	.insn	2, 0x5b01
    11ea:	09cd                	.insn	2, 0x09cd
    11ec:	0000                	.insn	2, 0x0000
    11ee:	282c                	.insn	2, 0x282c
    11f0:	09d6                	.insn	2, 0x09d6
    11f2:	0000                	.insn	2, 0x0000
    11f4:	0000                	.insn	2, 0x0000
    11f6:	4332                	.insn	2, 0x4332
    11f8:	0034                	.insn	2, 0x0034
    11fa:	0000                	.insn	2, 0x0000
    11fc:	5201                	.insn	2, 0x5201
    11fe:	015e0133          	add	sp,t3,s5
    1202:	00000baf          	.insn	4, 0x0baf
    1206:	555a0133          	.insn	4, 0x555a0133
    120a:	5e01                	.insn	2, 0x5e01
    120c:	af01                	.insn	2, 0xaf01
    120e:	2200000b          	.insn	4, 0x2200000b
    1212:	5620                	.insn	2, 0x5620
    1214:	5e01                	.insn	2, 0x5e01
    1216:	7b01                	.insn	2, 0x7b01
    1218:	25000007          	.insn	4, 0x25000007
    121c:	5721                	.insn	2, 0x5721
    121e:	5f01                	.insn	2, 0x5f01
    1220:	af01                	.insn	2, 0xaf01
    1222:	0000000b          	.insn	4, 0x000b
    1226:	4432                	.insn	2, 0x4432
    1228:	0030                	.insn	2, 0x0030
    122a:	0000                	.insn	2, 0x0000
    122c:	5201                	.insn	2, 0x5201
    122e:	0134                	.insn	2, 0x0134
    1230:	0166                	.insn	2, 0x0166
    1232:	0141                	.insn	2, 0x0141
    1234:	0000                	.insn	2, 0x0000
    1236:	2222                	.insn	2, 0x2222
    1238:	0158                	.insn	2, 0x0158
    123a:	0166                	.insn	2, 0x0166
    123c:	0000077b          	.insn	4, 0x077b
    1240:	595b0133          	.insn	4, 0x595b0133
    1244:	6601                	.insn	2, 0x6601
    1246:	7b01                	.insn	2, 0x7b01
    1248:	00000007          	.insn	4, 0x0007
    124c:	4532                	.insn	2, 0x4532
    124e:	00bc                	.insn	2, 0x00bc
    1250:	0000                	.insn	2, 0x0000
    1252:	5201                	.insn	2, 0x5201
    1254:	0135                	.insn	2, 0x0135
    1256:	013401bf 23220000 	.insn	8, 0x23220000013401bf
    125e:	01bf014b          	.insn	4, 0x01bf014b
    1262:	0000077b          	.insn	4, 0x077b
    1266:	2425                	.insn	2, 0x2425
    1268:	015a                	.insn	2, 0x015a
    126a:	01c0                	.insn	2, 0x01c0
    126c:	0134                	.insn	2, 0x0134
    126e:	0000                	.insn	2, 0x0000
    1270:	2525                	.insn	2, 0x2525
    1272:	011f 01c5 0134      	.insn	6, 0x013401c5011f
    1278:	0000                	.insn	2, 0x0000
    127a:	031c                	.insn	2, 0x031c
    127c:	2625                	.insn	2, 0x2625
    127e:	01c7015b          	.insn	4, 0x01c7015b
    1282:	0041                	.insn	2, 0x0041
    1284:	0000                	.insn	2, 0x0000
    1286:	2725                	.insn	2, 0x2725
    1288:	01c80157          	.insn	4, 0x01c80157
    128c:	0134                	.insn	2, 0x0134
    128e:	0000                	.insn	2, 0x0000
    1290:	0000                	.insn	2, 0x0000
    1292:	4632                	.insn	2, 0x4632
    1294:	003c                	.insn	2, 0x003c
    1296:	0000                	.insn	2, 0x0000
    1298:	5201                	.insn	2, 0x5201
    129a:	0136                	.insn	2, 0x0136
    129c:	01d4                	.insn	2, 0x01d4
    129e:	0bb4                	.insn	2, 0x0bb4
    12a0:	0000                	.insn	2, 0x0000
    12a2:	2822                	.insn	2, 0x2822
    12a4:	015c                	.insn	2, 0x015c
    12a6:	01d4                	.insn	2, 0x01d4
    12a8:	0134                	.insn	2, 0x0134
    12aa:	0000                	.insn	2, 0x0000
    12ac:	471a                	.insn	2, 0x471a
    12ae:	001c                	.insn	2, 0x001c
    12b0:	0000                	.insn	2, 0x0000
    12b2:	2925                	.insn	2, 0x2925
    12b4:	0141                	.insn	2, 0x0141
    12b6:	01d8                	.insn	2, 0x01d8
    12b8:	0134                	.insn	2, 0x0134
    12ba:	0000                	.insn	2, 0x0000
    12bc:	0000                	.insn	2, 0x0000
    12be:	4832                	.insn	2, 0x4832
    12c0:	0014                	.insn	2, 0x0014
    12c2:	0000                	.insn	2, 0x0000
    12c4:	5201                	.insn	2, 0x5201
    12c6:	0138                	.insn	2, 0x0138
    12c8:	0225                	.insn	2, 0x0225
    12ca:	0141                	.insn	2, 0x0141
    12cc:	0000                	.insn	2, 0x0000
    12ce:	2a25                	.insn	2, 0x2a25
    12d0:	011d                	.insn	2, 0x011d
    12d2:	01410227          	.insn	4, 0x01410227
    12d6:	0000                	.insn	2, 0x0000
    12d8:	3200                	.insn	2, 0x3200
    12da:	1449                	.insn	2, 0x1449
    12dc:	0000                	.insn	2, 0x0000
    12de:	0100                	.insn	2, 0x0100
    12e0:	3952                	.insn	2, 0x3952
    12e2:	3301                	.insn	2, 0x3301
    12e4:	4102                	.insn	2, 0x4102
    12e6:	0001                	.insn	2, 0x0001
    12e8:	2500                	.insn	2, 0x2500
    12ea:	35011d2b          	.insn	4, 0x35011d2b
    12ee:	4102                	.insn	2, 0x4102
    12f0:	0001                	.insn	2, 0x0001
    12f2:	0000                	.insn	2, 0x0000
    12f4:	4a32                	.insn	2, 0x4a32
    12f6:	000c                	.insn	2, 0x000c
    12f8:	0000                	.insn	2, 0x0000
    12fa:	5201                	.insn	2, 0x5201
    12fc:	013a                	.insn	2, 0x013a
    12fe:	02a1                	.insn	2, 0x02a1
    1300:	0141                	.insn	2, 0x0141
    1302:	0000                	.insn	2, 0x0000
    1304:	2c22                	.insn	2, 0x2c22
    1306:	0151                	.insn	2, 0x0151
    1308:	02a1                	.insn	2, 0x02a1
    130a:	012c                	.insn	2, 0x012c
    130c:	0000                	.insn	2, 0x0000
    130e:	465b0133          	.insn	4, 0x465b0133
    1312:	a101                	.insn	2, 0xa101
    1314:	e102                	.insn	2, 0xe102
    1316:	2300000b          	.insn	4, 0x2300000b
    131a:	5a01                	.insn	2, 0x5a01
    131c:	0111                	.insn	2, 0x0111
    131e:	012c02a3          	sb	s2,5(s8) # 2e81005 <USER_MAX+0x2981005>
    1322:	0000                	.insn	2, 0x0000
    1324:	125b0123          	sb	t0,290(s6)
    1328:	a401                	.insn	2, 0xa401
    132a:	2c02                	.insn	2, 0x2c02
    132c:	0001                	.insn	2, 0x0001
    132e:	3600                	.insn	2, 0x3600
    1330:	1421                	.insn	2, 0x1421
    1332:	a501                	.insn	2, 0xa501
    1334:	2c02                	.insn	2, 0x2c02
    1336:	0001                	.insn	2, 0x0001
    1338:	0000                	.insn	2, 0x0000
    133a:	4b32                	.insn	2, 0x4b32
    133c:	000c                	.insn	2, 0x000c
    133e:	0000                	.insn	2, 0x0000
    1340:	5201                	.insn	2, 0x5201
    1342:	02d5013b          	.insn	4, 0x02d5013b
    1346:	0000024b          	.insn	4, 0x024b
    134a:	3236                	.insn	2, 0x3236
    134c:	0114                	.insn	2, 0x0114
    134e:	02d8                	.insn	2, 0x02d8
    1350:	012c                	.insn	2, 0x012c
    1352:	0000                	.insn	2, 0x0000
    1354:	2d25                	.insn	2, 0x2d25
    1356:	0111                	.insn	2, 0x0111
    1358:	012c02d7          	.insn	4, 0x012c02d7
    135c:	0000                	.insn	2, 0x0000
    135e:	3700                	.insn	2, 0x3700
    1360:	1c4c                	.insn	2, 0x1c4c
    1362:	0000                	.insn	2, 0x0000
    1364:	0100                	.insn	2, 0x0100
    1366:	3c52                	.insn	2, 0x3c52
    1368:	e701                	.insn	2, 0xe701
    136a:	0a02                	.insn	2, 0x0a02
    136c:	0041                	.insn	2, 0x0041
    136e:	0000                	.insn	2, 0x0000
    1370:	4109                	.insn	2, 0x4109
    1372:	0001                	.insn	2, 0x0001
    1374:	3700                	.insn	2, 0x3700
    1376:	1f030e03          	lb	t3,496(t1)
    137a:	0001                	.insn	2, 0x0001
    137c:	3800                	.insn	2, 0x3800
    137e:	0045                	.insn	2, 0x0045
    1380:	0000                	.insn	2, 0x0000
    1382:	0100                	.insn	2, 0x0100
    1384:	0300                	.insn	2, 0x0300
    1386:	012c                	.insn	2, 0x012c
    1388:	0000                	.insn	2, 0x0000
    138a:	4538                	.insn	2, 0x4538
    138c:	0000                	.insn	2, 0x0000
    138e:	0000                	.insn	2, 0x0000
    1390:	0001                	.insn	2, 0x0001
    1392:	2c31                	.insn	2, 0x2c31
    1394:	0001                	.insn	2, 0x0001
    1396:	3900                	.insn	2, 0x3900
    1398:	0be1                	.insn	2, 0x0be1
    139a:	0000                	.insn	2, 0x0000
    139c:	3a45                	.insn	2, 0x3a45
    139e:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
    13a2:	0400                	.insn	2, 0x0400
    13a4:	0045                	.insn	2, 0x0045
    13a6:	0000                	.insn	2, 0x0000
    13a8:	f30a000b          	.insn	4, 0xf30a000b
    13ac:	3100000b          	.insn	4, 0x3100000b
    13b0:	011f 0000 6100      	.insn	6, 0x61000000011f
    13b6:	0005                	.insn	2, 0x0005
    13b8:	0500                	.insn	2, 0x0500
    13ba:	0100                	.insn	2, 0x0100
    13bc:	2104                	.insn	2, 0x2104
    13be:	0005                	.insn	2, 0x0005
    13c0:	0100                	.insn	2, 0x0100
    13c2:	1d00                	.insn	2, 0x1d00
    13c4:	0100                	.insn	2, 0x0100
    13c6:	0270                	.insn	2, 0x0270
    13c8:	0000                	.insn	2, 0x0000
    13ca:	0d72                	.insn	2, 0x0d72
    13cc:	0000                	.insn	2, 0x0000
    13ce:	0702                	.insn	2, 0x0702
    13d0:	0aa0                	.insn	2, 0x0aa0
    13d2:	0000                	.insn	2, 0x0000
    13d4:	0360                	.insn	2, 0x0360
    13d6:	0000                	.insn	2, 0x0000
    13d8:	0144                	.insn	2, 0x0144
    13da:	0000                	.insn	2, 0x0000
    13dc:	0811                	.insn	2, 0x0811
    13de:	0000                	.insn	2, 0x0000
    13e0:	3502                	.insn	2, 0x3502
    13e2:	0000                	.insn	2, 0x0000
    13e4:	0100                	.insn	2, 0x0100
    13e6:	00a10213          	addi	tp,sp,10
    13ea:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
    13ee:	0400                	.insn	2, 0x0400
    13f0:	0045                	.insn	2, 0x0045
    13f2:	0000                	.insn	2, 0x0000
    13f4:	0010                	.insn	2, 0x0010
    13f6:	0305                	.insn	2, 0x0305
    13f8:	0108                	.insn	2, 0x0108
    13fa:	0406                	.insn	2, 0x0406
    13fc:	0708                	.insn	2, 0x0708
    13fe:	5302                	.insn	2, 0x5302
    1400:	0000                	.insn	2, 0x0000
    1402:	0100                	.insn	2, 0x0100
    1404:	01a102d7          	.insn	4, 0x01a102d7
    1408:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
    140c:	0400                	.insn	2, 0x0400
    140e:	0045                	.insn	2, 0x0045
    1410:	0000                	.insn	2, 0x0000
    1412:	0009                	.insn	2, 0x0009
    1414:	6902                	.insn	2, 0x6902
    1416:	0000                	.insn	2, 0x0000
    1418:	0100                	.insn	2, 0x0100
    141a:	02f0                	.insn	2, 0x02f0
    141c:	02a1                	.insn	2, 0x02a1
    141e:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
    1422:	0400                	.insn	2, 0x0400
    1424:	0045                	.insn	2, 0x0045
    1426:	0000                	.insn	2, 0x0000
    1428:	80070017          	auipc	zero,0x80070
    142c:	0000                	.insn	2, 0x0000
    142e:	0100                	.insn	2, 0x0100
    1430:	014c                	.insn	2, 0x014c
    1432:	a102                	.insn	2, 0xa102
    1434:	00410303          	lb	t1,4(sp)
    1438:	0000                	.insn	2, 0x0000
    143a:	4504                	.insn	2, 0x4504
    143c:	0000                	.insn	2, 0x0000
    143e:	0b00                	.insn	2, 0x0b00
    1440:	0700                	.insn	2, 0x0700
    1442:	00000097          	auipc	ra,0x0
    1446:	5401                	.insn	2, 0x5401
    1448:	0201                	.insn	2, 0x0201
    144a:	04a1                	.insn	2, 0x04a1
    144c:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
    1450:	0400                	.insn	2, 0x0400
    1452:	0045                	.insn	2, 0x0045
    1454:	0000                	.insn	2, 0x0000
    1456:	0002                	.insn	2, 0x0002
    1458:	0000ae07          	.insn	4, 0xae07
    145c:	0100                	.insn	2, 0x0100
    145e:	0159                	.insn	2, 0x0159
    1460:	a102                	.insn	2, 0xa102
    1462:	0305                	.insn	2, 0x0305
    1464:	0041                	.insn	2, 0x0041
    1466:	0000                	.insn	2, 0x0000
    1468:	4504                	.insn	2, 0x4504
    146a:	0000                	.insn	2, 0x0000
    146c:	0d00                	.insn	2, 0x0d00
    146e:	0800                	.insn	2, 0x0800
    1470:	c705                	.insn	2, 0xc705
    1472:	0000                	.insn	2, 0x0000
    1474:	0100                	.insn	2, 0x0100
    1476:	0404                	.insn	2, 0x0404
    1478:	06a1                	.insn	2, 0x06a1
    147a:	d4031423          	sh	zero,-696(t1)
    147e:	0000                	.insn	2, 0x0000
    1480:	0900                	.insn	2, 0x0900
    1482:	0045                	.insn	2, 0x0045
    1484:	0000                	.insn	2, 0x0000
    1486:	0200                	.insn	2, 0x0200
    1488:	0a00                	.insn	2, 0x0a00
    148a:	00dc                	.insn	2, 0x00dc
    148c:	0000                	.insn	2, 0x0000
    148e:	050f0207          	.insn	4, 0x050f0207
    1492:	0806                	.insn	2, 0x0806
    1494:	0b01                	.insn	2, 0x0b01
    1496:	eb08                	.insn	2, 0xeb08
    1498:	0000                	.insn	2, 0x0000
    149a:	0100                	.insn	2, 0x0100
    149c:	0206                	.insn	2, 0x0206
    149e:	06a1                	.insn	2, 0x06a1
    14a0:	f30a                	.insn	2, 0xf30a
    14a2:	0000                	.insn	2, 0x0000
    14a4:	1000                	.insn	2, 0x1000
    14a6:	140c0c03          	lb	s8,320(s8)
    14aa:	090d0603          	lb	a2,144(s10) # 2f7f2 <start-0x3d080e>
    14ae:	0125                	.insn	2, 0x0125
    14b0:	0000                	.insn	2, 0x0000
    14b2:	0d000703          	lb	a4,208(zero) # d0 <start-0x3fff30>
    14b6:	250c                	.insn	2, 0x250c
    14b8:	0001                	.insn	2, 0x0001
    14ba:	0300                	.insn	2, 0x0300
    14bc:	0408                	.insn	2, 0x0408
    14be:	0d0d                	.insn	2, 0x0d0d
    14c0:	0125                	.insn	2, 0x0125
    14c2:	0000                	.insn	2, 0x0000
    14c4:	0d080903          	lb	s2,208(a6)
    14c8:	250e                	.insn	2, 0x250e
    14ca:	0001                	.insn	2, 0x0001
    14cc:	0300                	.insn	2, 0x0300
    14ce:	0c0a                	.insn	2, 0x0c0a
    14d0:	0f0d                	.insn	2, 0x0f0d
    14d2:	0125                	.insn	2, 0x0125
    14d4:	0000                	.insn	2, 0x0000
    14d6:	00100b03          	lb	s6,1(zero) # 1 <start-0x3fffff>
    14da:	2d0a                	.insn	2, 0x2d0a
    14dc:	0001                	.insn	2, 0x0001
    14de:	0b00                	.insn	2, 0x0b00
    14e0:	1102                	.insn	2, 0x1102
    14e2:	0a05                	.insn	2, 0x0a05
    14e4:	110e0407          	.insn	4, 0x110e0407
    14e8:	7a01                	.insn	2, 0x7a01
    14ea:	0125                	.insn	2, 0x0125
    14ec:	0000                	.insn	2, 0x0000
    14ee:	7a01120f          	.insn	4, 0x7a01120f
    14f2:	0125                	.insn	2, 0x0125
    14f4:	0000                	.insn	2, 0x0000
    14f6:	1000                	.insn	2, 0x1000
    14f8:	0000ec07          	.insn	4, 0xec07
    14fc:	0100                	.insn	2, 0x0100
    14fe:	1e52                	.insn	2, 0x1e52
    1500:	0801                	.insn	2, 0x0801
    1502:	02f5                	.insn	2, 0x02f5
    1504:	0000                	.insn	2, 0x0000
    1506:	0011                	.insn	2, 0x0011
    1508:	0119                	.insn	2, 0x0119
    150a:	d808                	.insn	2, 0xd808
    150c:	0002                	.insn	2, 0x0002
    150e:	1200                	.insn	2, 0x1200
    1510:	9102                	.insn	2, 0x9102
    1512:	2314                	.insn	2, 0x2314
    1514:	0a01                	.insn	2, 0x0a01
    1516:	000000c7          	.insn	4, 0x00c7
    151a:	0212                	.insn	2, 0x0212
    151c:	1091                	.insn	2, 0x1091
    151e:	0112                	.insn	2, 0x0112
    1520:	250c                	.insn	2, 0x250c
    1522:	0001                	.insn	2, 0x0001
    1524:	1200                	.insn	2, 0x1200
    1526:	9102                	.insn	2, 0x9102
    1528:	240c                	.insn	2, 0x240c
    152a:	0d01                	.insn	2, 0x0d01
    152c:	0125                	.insn	2, 0x0125
    152e:	0000                	.insn	2, 0x0000
    1530:	01250213          	addi	tp,a0,18
    1534:	00012517          	auipc	a0,0x12
    1538:	1400                	.insn	2, 0x1400
    153a:	0131                	.insn	2, 0x0131
    153c:	0000                	.insn	2, 0x0000
    153e:	1c08                	.insn	2, 0x1c08
    1540:	0000                	.insn	2, 0x0000
    1542:	0100                	.insn	2, 0x0100
    1544:	0918                	.insn	2, 0x0918
    1546:	0115                	.insn	2, 0x0115
    1548:	0139                	.insn	2, 0x0139
    154a:	0000                	.insn	2, 0x0000
    154c:	1600                	.insn	2, 0x1600
    154e:	3409                	.insn	2, 0x3409
    1550:	0000                	.insn	2, 0x0000
    1552:	1300                	.insn	2, 0x1300
    1554:	1d011b03          	lh	s6,464(sp)
    1558:	0125                	.insn	2, 0x0125
    155a:	0000                	.insn	2, 0x0000
    155c:	1700                	.insn	2, 0x1700
    155e:	01cd                	.insn	2, 0x01cd
    1560:	0000                	.insn	2, 0x0000
    1562:	170a                	.insn	2, 0x170a
    1564:	020d                	.insn	2, 0x020d
    1566:	0000                	.insn	2, 0x0000
    1568:	02cd170b          	.insn	4, 0x02cd170b
    156c:	0000                	.insn	2, 0x0000
    156e:	170c                	.insn	2, 0x170c
    1570:	02e2                	.insn	2, 0x02e2
    1572:	0000                	.insn	2, 0x0000
    1574:	170d                	.insn	2, 0x170d
    1576:	02fa                	.insn	2, 0x02fa
    1578:	0000                	.insn	2, 0x0000
    157a:	170e                	.insn	2, 0x170e
    157c:	02fa                	.insn	2, 0x02fa
    157e:	0000                	.insn	2, 0x0000
    1580:	1010000f          	.insn	4, 0x1010000f
    1584:	00bc                	.insn	2, 0x00bc
    1586:	0000                	.insn	2, 0x0000
    1588:	5201                	.insn	2, 0x5201
    158a:	011f f581 0002      	.insn	6, 0x0002f581011f
    1590:	1300                	.insn	2, 0x1300
    1592:	2304                	.insn	2, 0x2304
    1594:	8301                	.insn	2, 0x8301
    1596:	0458                	.insn	2, 0x0458
    1598:	0000                	.insn	2, 0x0000
    159a:	01260513          	addi	a0,a2,18
    159e:	2591                	.insn	2, 0x2591
    15a0:	0001                	.insn	2, 0x0001
    15a2:	1300                	.insn	2, 0x1300
    15a4:	2706                	.insn	2, 0x2706
    15a6:	9501                	.insn	2, 0x9501
    15a8:	0125                	.insn	2, 0x0125
    15aa:	0000                	.insn	2, 0x0000
    15ac:	01280713          	addi	a4,a6,18
    15b0:	2598                	.insn	2, 0x2598
    15b2:	0001                	.insn	2, 0x0001
    15b4:	1700                	.insn	2, 0x1700
    15b6:	02e2                	.insn	2, 0x02e2
    15b8:	0000                	.insn	2, 0x0000
    15ba:	1711                	.insn	2, 0x1711
    15bc:	02e2                	.insn	2, 0x02e2
    15be:	0000                	.insn	2, 0x0000
    15c0:	0012                	.insn	2, 0x0012
    15c2:	1310                	.insn	2, 0x1310
    15c4:	02a0                	.insn	2, 0x02a0
    15c6:	0000                	.insn	2, 0x0000
    15c8:	5201                	.insn	2, 0x5201
    15ca:	0120                	.insn	2, 0x0120
    15cc:	f52a                	.insn	2, 0xf52a
    15ce:	0002                	.insn	2, 0x0002
    15d0:	1100                	.insn	2, 0x1100
    15d2:	1908                	.insn	2, 0x1908
    15d4:	2b01                	.insn	2, 0x2b01
    15d6:	02d8                	.insn	2, 0x02d8
    15d8:	0000                	.insn	2, 0x0000
    15da:	0911                	.insn	2, 0x0911
    15dc:	0112                	.insn	2, 0x0112
    15de:	532c                	.insn	2, 0x532c
    15e0:	0005                	.insn	2, 0x0005
    15e2:	1100                	.insn	2, 0x1100
    15e4:	240a                	.insn	2, 0x240a
    15e6:	2d01                	.insn	2, 0x2d01
    15e8:	00000553          	.insn	4, 0x0553
    15ec:	012a0c13          	addi	s8,s4,18
    15f0:	2534                	.insn	2, 0x2534
    15f2:	0001                	.insn	2, 0x0001
    15f4:	1800                	.insn	2, 0x1800
    15f6:	582f0123          	sb	sp,1410(t5)
    15fa:	0004                	.insn	2, 0x0004
    15fc:	1400                	.insn	2, 0x1400
    15fe:	0131                	.insn	2, 0x0131
    1600:	0000                	.insn	2, 0x0000
    1602:	1414                	.insn	2, 0x1414
    1604:	0000                	.insn	2, 0x0000
    1606:	0100                	.insn	2, 0x0100
    1608:	0935                	.insn	2, 0x0935
    160a:	0b15                	.insn	2, 0x0b15
    160c:	0139                	.insn	2, 0x0139
    160e:	0000                	.insn	2, 0x0000
    1610:	1600                	.insn	2, 0x1600
    1612:	c415                	.insn	2, 0xc415
    1614:	0001                	.insn	2, 0x0001
    1616:	1300                	.insn	2, 0x1300
    1618:	3a011b0f          	.insn	4, 0x3a011b0f
    161c:	02f5                	.insn	2, 0x02f5
    161e:	0000                	.insn	2, 0x0000
    1620:	0019                	.insn	2, 0x0019
    1622:	0212                	.insn	2, 0x0212
    1624:	0391                	.insn	2, 0x0391
    1626:	0129                	.insn	2, 0x0129
    1628:	ae4a                	.insn	2, 0xae4a
    162a:	0000                	.insn	2, 0x0000
    162c:	1300                	.insn	2, 0x1300
    162e:	2c0e                	.insn	2, 0x2c0e
    1630:	4b01                	.insn	2, 0x4b01
    1632:	02f5                	.insn	2, 0x02f5
    1634:	0000                	.insn	2, 0x0000
    1636:	2d18                	.insn	2, 0x2d18
    1638:	3c01                	.insn	2, 0x3c01
    163a:	0458                	.insn	2, 0x0458
    163c:	0000                	.insn	2, 0x0000
    163e:	0119                	.insn	2, 0x0119
    1640:	012b0d13          	addi	s10,s6,18
    1644:	f558                	.insn	2, 0xf558
    1646:	0002                	.insn	2, 0x0002
    1648:	0000                	.insn	2, 0x0000
    164a:	1616                	.insn	2, 0x1616
    164c:	005c                	.insn	2, 0x005c
    164e:	0000                	.insn	2, 0x0000
    1650:	2e18                	.insn	2, 0x2e18
    1652:	6201                	.insn	2, 0x6201
    1654:	0125                	.insn	2, 0x0125
    1656:	0000                	.insn	2, 0x0000
    1658:	2f18                	.insn	2, 0x2f18
    165a:	6601                	.insn	2, 0x6601
    165c:	0125                	.insn	2, 0x0125
    165e:	0000                	.insn	2, 0x0000
    1660:	1900                	.insn	2, 0x1900
    1662:	1302                	.insn	2, 0x1302
    1664:	2b10                	.insn	2, 0x2b10
    1666:	4e01                	.insn	2, 0x4e01
    1668:	02f5                	.insn	2, 0x02f5
    166a:	0000                	.insn	2, 0x0000
    166c:	0000                	.insn	2, 0x0000
    166e:	1700                	.insn	2, 0x1700
    1670:	01cd                	.insn	2, 0x01cd
    1672:	0000                	.insn	2, 0x0000
    1674:	02e21717          	auipc	a4,0x2e21
    1678:	0000                	.insn	2, 0x0000
    167a:	1718                	.insn	2, 0x1718
    167c:	0304                	.insn	2, 0x0304
    167e:	0000                	.insn	2, 0x0000
    1680:	0019                	.insn	2, 0x0019
    1682:	131a                	.insn	2, 0x131a
    1684:	4e02                	.insn	2, 0x4e02
    1686:	0002d81b          	.insn	4, 0x0002d81b
    168a:	1c00                	.insn	2, 0x1c00
    168c:	1d00                	.insn	2, 0x1d00
    168e:	02dd                	.insn	2, 0x02dd
    1690:	0000                	.insn	2, 0x0000
    1692:	411e                	.insn	2, 0x411e
    1694:	0000                	.insn	2, 0x0000
    1696:	1f00                	.insn	2, 0x1f00
    1698:	0214                	.insn	2, 0x0214
    169a:	f532                	.insn	2, 0xf532
    169c:	0002                	.insn	2, 0x0002
    169e:	1b00                	.insn	2, 0x1b00
    16a0:	0125                	.insn	2, 0x0125
    16a2:	0000                	.insn	2, 0x0000
    16a4:	0002f91b          	.insn	4, 0x0002f91b
    16a8:	0000                	.insn	2, 0x0000
    16aa:	1505                	.insn	2, 0x1505
    16ac:	0405                	.insn	2, 0x0405
    16ae:	1a20                	.insn	2, 0x1a20
    16b0:	0216                	.insn	2, 0x0216
    16b2:	1b3d                	.insn	2, 0x1b3d
    16b4:	0041                	.insn	2, 0x0041
    16b6:	0000                	.insn	2, 0x0000
    16b8:	1f00                	.insn	2, 0x1f00
    16ba:	f54a0217          	auipc	tp,0xf54a0
    16be:	0002                	.insn	2, 0x0002
    16c0:	1b00                	.insn	2, 0x1b00
    16c2:	02d8                	.insn	2, 0x02d8
    16c4:	0000                	.insn	2, 0x0000
    16c6:	0002d81b          	.insn	4, 0x0002d81b
    16ca:	0000                	.insn	2, 0x0000
    16cc:	1a21                	.insn	2, 0x1a21
    16ce:	0020                	.insn	2, 0x0020
    16d0:	0000                	.insn	2, 0x0000
    16d2:	5201                	.insn	2, 0x5201
    16d4:	0131                	.insn	2, 0x0131
    16d6:	0000                	.insn	2, 0x0000
    16d8:	1115                	.insn	2, 0x1115
    16da:	0139                	.insn	2, 0x0139
    16dc:	0000                	.insn	2, 0x0000
    16de:	2200                	.insn	2, 0x2200
    16e0:	0002881b          	.insn	4, 0x0002881b
    16e4:	0100                	.insn	2, 0x0100
    16e6:	2152                	.insn	2, 0x2152
    16e8:	b001                	.insn	2, 0xb001
    16ea:	012a1313          	slli	t1,s4,0x12
    16ee:	000125b7          	lui	a1,0x12
    16f2:	1800                	.insn	2, 0x1800
    16f4:	58b20123          	sb	a1,1410(tp) # f54a1c3c <USER_MAX+0xf4fa1c3c>
    16f8:	0004                	.insn	2, 0x0004
    16fa:	1400                	.insn	2, 0x1400
    16fc:	0131                	.insn	2, 0x0131
    16fe:	0000                	.insn	2, 0x0000
    1700:	141c                	.insn	2, 0x141c
    1702:	0000                	.insn	2, 0x0000
    1704:	0100                	.insn	2, 0x0100
    1706:	09b8                	.insn	2, 0x09b8
    1708:	1215                	.insn	2, 0x1215
    170a:	0139                	.insn	2, 0x0139
    170c:	0000                	.insn	2, 0x0000
    170e:	1600                	.insn	2, 0x1600
    1710:	c41d                	.insn	2, 0xc41d
    1712:	0001                	.insn	2, 0x0001
    1714:	1300                	.insn	2, 0x1300
    1716:	1b16                	.insn	2, 0x1b16
    1718:	bd01                	.insn	2, 0xbd01
    171a:	02f5                	.insn	2, 0x02f5
    171c:	0000                	.insn	2, 0x0000
    171e:	0319                	.insn	2, 0x0319
    1720:	01251413          	slli	s0,a0,0x12
    1724:	25e4                	.insn	2, 0x25e4
    1726:	0001                	.insn	2, 0x0001
    1728:	1300                	.insn	2, 0x1300
    172a:	3015                	.insn	2, 0x3015
    172c:	e101                	.insn	2, 0xe101
    172e:	0125                	.insn	2, 0x0125
    1730:	0000                	.insn	2, 0x0000
    1732:	01241713          	slli	a4,s0,0x12
    1736:	25e9                	.insn	2, 0x25e9
    1738:	0001                	.insn	2, 0x0001
    173a:	1800                	.insn	2, 0x1800
    173c:	012d                	.insn	2, 0x012d
    173e:	000458bf 012e1800 	.insn	8, 0x012e1800000458bf
    1746:	25d9                	.insn	2, 0x25d9
    1748:	0001                	.insn	2, 0x0001
    174a:	1800                	.insn	2, 0x1800
    174c:	25dd012f          	.insn	4, 0x25dd012f
    1750:	0001                	.insn	2, 0x0001
    1752:	1400                	.insn	2, 0x1400
    1754:	0131                	.insn	2, 0x0131
    1756:	0000                	.insn	2, 0x0000
    1758:	141d                	.insn	2, 0x141d
    175a:	0000                	.insn	2, 0x0000
    175c:	0100                	.insn	2, 0x0100
    175e:	012313e7          	.insn	4, 0x012313e7
    1762:	0001395b          	.insn	4, 0x0001395b
    1766:	0000                	.insn	2, 0x0000
    1768:	0419                	.insn	2, 0x0419
    176a:	012b1813          	slli	a6,s6,0x12
    176e:	f5ca                	.insn	2, 0xf5ca
    1770:	0002                	.insn	2, 0x0002
    1772:	0000                	.insn	2, 0x0000
    1774:	0519                	.insn	2, 0x0519
    1776:	012b1913          	slli	s2,s6,0x12
    177a:	f5d1                	.insn	2, 0xf5d1
    177c:	0002                	.insn	2, 0x0002
    177e:	0000                	.insn	2, 0x0000
    1780:	0000                	.insn	2, 0x0000
    1782:	0001cd17          	auipc	s10,0x1c
    1786:	1e00                	.insn	2, 0x1e00
    1788:	0002e217          	auipc	tp,0x2e
    178c:	1f00                	.insn	2, 0x1f00
    178e:	0002cd17          	auipc	s10,0x2c
    1792:	2000                	.insn	2, 0x2000
    1794:	0002fa17          	auipc	s4,0x2f
    1798:	2100                	.insn	2, 0x2100
    179a:	0002fa17          	auipc	s4,0x2f
    179e:	2200                	.insn	2, 0x2200
    17a0:	0002fa17          	auipc	s4,0x2f
    17a4:	2300                	.insn	2, 0x2300
    17a6:	0002fa17          	auipc	s4,0x2f
    17aa:	2400                	.insn	2, 0x2400
    17ac:	0002fa17          	auipc	s4,0x2f
    17b0:	2500                	.insn	2, 0x2500
    17b2:	0002fa17          	auipc	s4,0x2f
    17b6:	2600                	.insn	2, 0x2600
    17b8:	0002fa17          	auipc	s4,0x2f
    17bc:	2700                	.insn	2, 0x2700
    17be:	0002fa17          	auipc	s4,0x2f
    17c2:	2800                	.insn	2, 0x2800
    17c4:	0002fa17          	auipc	s4,0x2f
    17c8:	2900                	.insn	2, 0x2900
    17ca:	0002fa17          	auipc	s4,0x2f
    17ce:	2a00                	.insn	2, 0x2a00
    17d0:	0002cd17          	auipc	s10,0x2c
    17d4:	2b00                	.insn	2, 0x2b00
    17d6:	0002fa17          	auipc	s4,0x2f
    17da:	2c00                	.insn	2, 0x2c00
    17dc:	0002fa17          	auipc	s4,0x2f
    17e0:	2d00                	.insn	2, 0x2d00
    17e2:	2400                	.insn	2, 0x2400
    17e4:	0118                	.insn	2, 0x0118
    17e6:	0002f5f7          	.insn	4, 0x0002f5f7
    17ea:	0f00                	.insn	2, 0x0f00
    17ec:	0119                	.insn	2, 0x0119
    17ee:	d8f8                	.insn	2, 0xd8f8
    17f0:	0002                	.insn	2, 0x0002
    17f2:	0f00                	.insn	2, 0x0f00
    17f4:	011a                	.insn	2, 0x011a
    17f6:	58f9                	.insn	2, 0x58f9
    17f8:	0004                	.insn	2, 0x0004
    17fa:	1800                	.insn	2, 0x1800
    17fc:	f5fb011b          	.insn	4, 0xf5fb011b
    1800:	0002                	.insn	2, 0x0002
    1802:	2500                	.insn	2, 0x2500
    1804:	011c                	.insn	2, 0x011c
    1806:	0101                	.insn	2, 0x0101
    1808:	02f5                	.insn	2, 0x02f5
    180a:	0000                	.insn	2, 0x0000
    180c:	1d00                	.insn	2, 0x1d00
    180e:	00d4                	.insn	2, 0x00d4
    1810:	0000                	.insn	2, 0x0000
    1812:	2e26                	.insn	2, 0x2e26
    1814:	03b0                	.insn	2, 0x03b0
    1816:	0000                	.insn	2, 0x0000
    1818:	5201                	.insn	2, 0x5201
    181a:	0122                	.insn	2, 0x0122
    181c:	011d                	.insn	2, 0x011d
    181e:	02f5                	.insn	2, 0x02f5
    1820:	0000                	.insn	2, 0x0000
    1822:	01191a27          	.insn	4, 0x01191a27
    1826:	011d                	.insn	2, 0x011d
    1828:	02d8                	.insn	2, 0x02d8
    182a:	0000                	.insn	2, 0x0000
    182c:	0228                	.insn	2, 0x0228
    182e:	0d91                	.insn	2, 0x0d91
    1830:	0129                	.insn	2, 0x0129
    1832:	012a                	.insn	2, 0x012a
    1834:	0558                	.insn	2, 0x0558
    1836:	0000                	.insn	2, 0x0000
    1838:	1c29                	.insn	2, 0x1c29
    183a:	012a                	.insn	2, 0x012a
    183c:	0124                	.insn	2, 0x0124
    183e:	0125                	.insn	2, 0x0125
    1840:	0000                	.insn	2, 0x0000
    1842:	2325                	.insn	2, 0x2325
    1844:	1f01                	.insn	2, 0x1f01
    1846:	5801                	.insn	2, 0x5801
    1848:	0004                	.insn	2, 0x0004
    184a:	2a00                	.insn	2, 0x2a00
    184c:	0131                	.insn	2, 0x0131
    184e:	0000                	.insn	2, 0x0000
    1850:	0000142f          	.insn	4, 0x142f
    1854:	0100                	.insn	2, 0x0100
    1856:	0125                	.insn	2, 0x0125
    1858:	1509                	.insn	2, 0x1509
    185a:	0001391b          	.insn	4, 0x0001391b
    185e:	0000                	.insn	2, 0x0000
    1860:	2e2a                	.insn	2, 0x2e2a
    1862:	0004                	.insn	2, 0x0004
    1864:	3000                	.insn	2, 0x3000
    1866:	00d8                	.insn	2, 0x00d8
    1868:	0000                	.insn	2, 0x0000
    186a:	2c01                	.insn	2, 0x2c01
    186c:	0501                	.insn	2, 0x0501
    186e:	1d15                	.insn	2, 0x1d15
    1870:	0436                	.insn	2, 0x0436
    1872:	0000                	.insn	2, 0x0000
    1874:	0d910323          	sb	s9,198(sp)
    1878:	3e9f 0004 2b00      	.insn	6, 0x2b0000043e9f
    187e:	461e                	.insn	2, 0x461e
    1880:	0004                	.insn	2, 0x0004
    1882:	2b00                	.insn	2, 0x2b00
    1884:	4e1f 0004 0000      	.insn	6, 0x00044e1f
    188a:	3116                	.insn	2, 0x3116
    188c:	0248                	.insn	2, 0x0248
    188e:	0000                	.insn	2, 0x0000
    1890:	2029                	.insn	2, 0x2029
    1892:	012e011b          	.insn	4, 0x012e011b
    1896:	02f5                	.insn	2, 0x02f5
    1898:	0000                	.insn	2, 0x0000
    189a:	3116                	.insn	2, 0x3116
    189c:	0248                	.insn	2, 0x0248
    189e:	0000                	.insn	2, 0x0000
    18a0:	2129                	.insn	2, 0x2129
    18a2:	012d                	.insn	2, 0x012d
    18a4:	0130                	.insn	2, 0x0130
    18a6:	0458                	.insn	2, 0x0458
    18a8:	0000                	.insn	2, 0x0000
    18aa:	0619                	.insn	2, 0x0619
    18ac:	2229                	.insn	2, 0x2229
    18ae:	0136012b          	.insn	4, 0x0136012b
    18b2:	02f5                	.insn	2, 0x02f5
    18b4:	0000                	.insn	2, 0x0000
    18b6:	1900                	.insn	2, 0x1900
    18b8:	2b232907          	.insn	4, 0x2b232907
    18bc:	3a01                	.insn	2, 0x3a01
    18be:	f501                	.insn	2, 0xf501
    18c0:	0002                	.insn	2, 0x0002
    18c2:	0000                	.insn	2, 0x0000
    18c4:	0000                	.insn	2, 0x0000
    18c6:	0001cd17          	auipc	s10,0x1c
    18ca:	3200                	.insn	2, 0x3200
    18cc:	0002e217          	auipc	tp,0x2e
    18d0:	3300                	.insn	2, 0x3300
    18d2:	0002cd17          	auipc	s10,0x2c
    18d6:	3400                	.insn	2, 0x3400
    18d8:	0002cd17          	auipc	s10,0x2c
    18dc:	3500                	.insn	2, 0x3500
    18de:	00053617          	auipc	a2,0x53
    18e2:	3600                	.insn	2, 0x3600
    18e4:	0002cd17          	auipc	s10,0x2c
    18e8:	3700                	.insn	2, 0x3700
    18ea:	1f00                	.insn	2, 0x1f00
    18ec:	021d                	.insn	2, 0x021d
    18ee:	2531                	.insn	2, 0x2531
    18f0:	0001                	.insn	2, 0x0001
    18f2:	1b00                	.insn	2, 0x1b00
    18f4:	0125                	.insn	2, 0x0125
    18f6:	0000                	.insn	2, 0x0000
    18f8:	0005491b          	.insn	4, 0x0005491b
    18fc:	0000                	.insn	2, 0x0000
    18fe:	4e1d                	.insn	2, 0x4e1d
    1900:	0005                	.insn	2, 0x0005
    1902:	1e00                	.insn	2, 0x1e00
    1904:	00d4                	.insn	2, 0x00d4
    1906:	0000                	.insn	2, 0x0000
    1908:	251d                	.insn	2, 0x251d
    190a:	0001                	.insn	2, 0x0001
    190c:	0300                	.insn	2, 0x0300
    190e:	00d4                	.insn	2, 0x00d4
    1910:	0000                	.insn	2, 0x0000
    1912:	4504                	.insn	2, 0x4504
    1914:	0000                	.insn	2, 0x0000
    1916:	0b00                	.insn	2, 0x0b00
	...

Disassembly of section .debug_rnglists:

00000000 <.debug_rnglists>:
   0:	000000b7          	lui	ra,0x0
   4:	0005                	.insn	2, 0x0005
   6:	0004                	.insn	2, 0x0004
   8:	0009                	.insn	2, 0x0009
   a:	0000                	.insn	2, 0x0000
   c:	0024                	.insn	2, 0x0024
   e:	0000                	.insn	2, 0x0000
  10:	0000002f          	.insn	4, 0x002f
  14:	003a                	.insn	2, 0x003a
  16:	0000                	.insn	2, 0x0000
  18:	0054                	.insn	2, 0x0054
  1a:	0000                	.insn	2, 0x0000
  1c:	0064                	.insn	2, 0x0064
  1e:	0000                	.insn	2, 0x0000
  20:	0074                	.insn	2, 0x0074
  22:	0000                	.insn	2, 0x0000
  24:	0084                	.insn	2, 0x0084
  26:	0000                	.insn	2, 0x0000
  28:	0094                	.insn	2, 0x0094
  2a:	0000                	.insn	2, 0x0000
  2c:	009f 0000 bc04      	.insn	6, 0xbc040000009f
  32:	040be40b          	.insn	4, 0x040be40b
  36:	0db4                	.insn	2, 0x0db4
  38:	0dc0                	.insn	2, 0x0dc0
  3a:	0400                	.insn	2, 0x0400
  3c:	0a98                	.insn	2, 0x0a98
  3e:	0ac0                	.insn	2, 0x0ac0
  40:	e804                	.insn	2, 0xe804
  42:	000bf40b          	.insn	4, 0x000bf40b
  46:	cc04                	.insn	2, 0xcc04
  48:	9809                	.insn	2, 0x9809
  4a:	040a                	.insn	2, 0x040a
  4c:	0ac8                	.insn	2, 0x0ac8
  4e:	0bbc                	.insn	2, 0x0bbc
  50:	8004                	.insn	2, 0x8004
  52:	900c                	.insn	2, 0x900c
  54:	040c                	.insn	2, 0x040c
  56:	0cc0                	.insn	2, 0x0cc0
  58:	0d84                	.insn	2, 0x0d84
  5a:	f404                	.insn	2, 0xf404
  5c:	b80d                	.insn	2, 0xb80d
  5e:	000e                	.insn	2, 0x000e
  60:	d404                	.insn	2, 0xd404
  62:	9809                	.insn	2, 0x9809
  64:	040a                	.insn	2, 0x040a
  66:	0ad8                	.insn	2, 0x0ad8
  68:	0adc                	.insn	2, 0x0adc
  6a:	c004                	.insn	2, 0xc004
  6c:	840c                	.insn	2, 0x840c
  6e:	000d                	.insn	2, 0x000d
  70:	c004                	.insn	2, 0xc004
  72:	d00c                	.insn	2, 0xd00c
  74:	040c                	.insn	2, 0x040c
  76:	0cd4                	.insn	2, 0x0cd4
  78:	0cdc                	.insn	2, 0x0cdc
  7a:	e404                	.insn	2, 0xe404
  7c:	840c                	.insn	2, 0x840c
  7e:	000d                	.insn	2, 0x000d
  80:	fc04                	.insn	2, 0xfc04
  82:	bc0a                	.insn	2, 0xbc0a
  84:	0c80040b          	.insn	4, 0x0c80040b
  88:	0c84                	.insn	2, 0x0c84
  8a:	f404                	.insn	2, 0xf404
  8c:	b80d                	.insn	2, 0xb80d
  8e:	000e                	.insn	2, 0x000e
  90:	f404                	.insn	2, 0xf404
  92:	840d                	.insn	2, 0x840d
  94:	040e                	.insn	2, 0x040e
  96:	0e88                	.insn	2, 0x0e88
  98:	0e90                	.insn	2, 0x0e90
  9a:	9804                	.insn	2, 0x9804
  9c:	b80e                	.insn	2, 0xb80e
  9e:	000e                	.insn	2, 0x000e
  a0:	8404                	.insn	2, 0x8404
  a2:	0404ac03          	lw	s8,64(s1)
  a6:	04b0                	.insn	2, 0x04b0
  a8:	04f0                	.insn	2, 0x04f0
  aa:	0400                	.insn	2, 0x0400
  ac:	11f4                	.insn	2, 0x11f4
  ae:	1290                	.insn	2, 0x1290
  b0:	9404                	.insn	2, 0x9404
  b2:	9c12                	.insn	2, 0x9c12
  b4:	0412                	.insn	2, 0x0412
  b6:	12a4                	.insn	2, 0x12a4
  b8:	12c4                	.insn	2, 0x12c4
  ba:	7900                	.insn	2, 0x7900
  bc:	0000                	.insn	2, 0x0000
  be:	0500                	.insn	2, 0x0500
  c0:	0400                	.insn	2, 0x0400
  c2:	0500                	.insn	2, 0x0500
  c4:	0000                	.insn	2, 0x0000
  c6:	1400                	.insn	2, 0x1400
  c8:	0000                	.insn	2, 0x0000
  ca:	2400                	.insn	2, 0x2400
  cc:	0000                	.insn	2, 0x0000
  ce:	3100                	.insn	2, 0x3100
  d0:	0000                	.insn	2, 0x0000
  d2:	5c00                	.insn	2, 0x5c00
  d4:	0000                	.insn	2, 0x0000
  d6:	6900                	.insn	2, 0x6900
  d8:	0000                	.insn	2, 0x0000
  da:	0100                	.insn	2, 0x0100
  dc:	7c6c040b          	.insn	4, 0x7c6c040b
  e0:	8004                	.insn	2, 0x8004
  e2:	8401                	.insn	2, 0x8401
  e4:	0401                	.insn	2, 0x0401
  e6:	0188                	.insn	2, 0x0188
  e8:	018c                	.insn	2, 0x018c
  ea:	0100                	.insn	2, 0x0100
  ec:	06b0040b          	.insn	4, 0x06b0040b
  f0:	06d4                	.insn	2, 0x06d4
  f2:	a004                	.insn	2, 0xa004
  f4:	8c09                	.insn	2, 0x8c09
  f6:	000a                	.insn	2, 0x000a
  f8:	0b01                	.insn	2, 0x0b01
  fa:	8c04                	.insn	2, 0x8c04
  fc:	04079807          	.insn	4, 0x04079807
 100:	07a8                	.insn	2, 0x07a8
 102:	07b4                	.insn	2, 0x07b4
 104:	c404                	.insn	2, 0xc404
 106:	0407d007          	.insn	4, 0x0407d007
 10a:	07e0                	.insn	2, 0x07e0
 10c:	07ec                	.insn	2, 0x07ec
 10e:	fc04                	.insn	2, 0xfc04
 110:	04088807          	.insn	4, 0x04088807
 114:	0898                	.insn	2, 0x0898
 116:	08a4                	.insn	2, 0x08a4
 118:	b004                	.insn	2, 0xb004
 11a:	bc08                	.insn	2, 0xbc08
 11c:	0408                	.insn	2, 0x0408
 11e:	08c0                	.insn	2, 0x08c0
 120:	08cc                	.insn	2, 0x08cc
 122:	0100                	.insn	2, 0x0100
 124:	0f98040b          	.insn	4, 0x0f98040b
 128:	0fec                	.insn	2, 0x0fec
 12a:	f004                	.insn	2, 0xf004
 12c:	000ff80f          	.insn	4, 0x000ff80f
 130:	11800b03          	lb	s6,280(zero) # 118 <start-0x3ffee8>
 134:	001c4c03          	lbu	s8,1(s8)
 138:	008a                	.insn	2, 0x008a
 13a:	0000                	.insn	2, 0x0000
 13c:	0005                	.insn	2, 0x0005
 13e:	0004                	.insn	2, 0x0004
 140:	0008                	.insn	2, 0x0008
 142:	0000                	.insn	2, 0x0000
 144:	0020                	.insn	2, 0x0020
 146:	0000                	.insn	2, 0x0000
 148:	0000002b          	.insn	4, 0x002b
 14c:	0000003b          	.insn	4, 0x003b
 150:	0046                	.insn	2, 0x0046
 152:	0000                	.insn	2, 0x0000
 154:	0051                	.insn	2, 0x0051
 156:	0000                	.insn	2, 0x0000
 158:	005c                	.insn	2, 0x005c
 15a:	0000                	.insn	2, 0x0000
 15c:	00000067          	jr	zero # 0 <start-0x400000>
 160:	00000077          	.insn	4, 0x0077
 164:	8404                	.insn	2, 0x8404
 166:	ac05                	.insn	2, 0xac05
 168:	0405                	.insn	2, 0x0405
 16a:	05b8                	.insn	2, 0x05b8
 16c:	08c8                	.insn	2, 0x08c8
 16e:	0400                	.insn	2, 0x0400
 170:	0584                	.insn	2, 0x0584
 172:	0590                	.insn	2, 0x0590
 174:	b004                	.insn	2, 0xb004
 176:	0407b407          	.insn	4, 0x0407b407
 17a:	07bc                	.insn	2, 0x07bc
 17c:	07e8                	.insn	2, 0x07e8
 17e:	0400                	.insn	2, 0x0400
 180:	05cc                	.insn	2, 0x05cc
 182:	06ac                	.insn	2, 0x06ac
 184:	b804                	.insn	2, 0xb804
 186:	a806                	.insn	2, 0xa806
 188:	ac040007          	.insn	4, 0xac040007
 18c:	f40a                	.insn	2, 0xf40a
 18e:	040a                	.insn	2, 0x040a
 190:	0b80                	.insn	2, 0x0b80
 192:	0df0                	.insn	2, 0x0df0
 194:	0400                	.insn	2, 0x0400
 196:	0b94                	.insn	2, 0x0b94
 198:	0bd0                	.insn	2, 0x0bd0
 19a:	dc04                	.insn	2, 0xdc04
 19c:	000cd40b          	.insn	4, 0x000cd40b
 1a0:	e804                	.insn	2, 0xe804
 1a2:	880c                	.insn	2, 0x880c
 1a4:	040d                	.insn	2, 0x040d
 1a6:	0dcc                	.insn	2, 0x0dcc
 1a8:	0df0                	.insn	2, 0x0df0
 1aa:	0400                	.insn	2, 0x0400
 1ac:	12f8                	.insn	2, 0x12f8
 1ae:	1398                	.insn	2, 0x1398
 1b0:	a004                	.insn	2, 0xa004
 1b2:	0413a813          	slti	a6,t2,65
 1b6:	13f8                	.insn	2, 0x13f8
 1b8:	1480                	.insn	2, 0x1480
 1ba:	0400                	.insn	2, 0x0400
 1bc:	13a8                	.insn	2, 0x13a8
 1be:	13f8                	.insn	2, 0x13f8
 1c0:	8804                	.insn	2, 0x8804
 1c2:	9414                	.insn	2, 0x9414
 1c4:	0014                	.insn	2, 0x0014

Disassembly of section .debug_str_offsets:

00000000 <.debug_str_offsets>:
   0:	00e8                	.insn	2, 0x00e8
   2:	0000                	.insn	2, 0x0000
   4:	0005                	.insn	2, 0x0005
   6:	0000                	.insn	2, 0x0000
   8:	0000                	.insn	2, 0x0000
   a:	0000                	.insn	2, 0x0000
   c:	00000027          	.insn	4, 0x0027
  10:	00000033          	add	zero,zero,zero
  14:	0236                	.insn	2, 0x0236
  16:	0000                	.insn	2, 0x0000
  18:	0068                	.insn	2, 0x0068
  1a:	0000                	.insn	2, 0x0000
  1c:	0085                	.insn	2, 0x0085
  1e:	0000                	.insn	2, 0x0000
  20:	007c                	.insn	2, 0x007c
  22:	0000                	.insn	2, 0x0000
  24:	0089                	.insn	2, 0x0089
  26:	0000                	.insn	2, 0x0000
  28:	0092                	.insn	2, 0x0092
  2a:	0000                	.insn	2, 0x0000
  2c:	01c5                	.insn	2, 0x01c5
  2e:	0000                	.insn	2, 0x0000
  30:	00dd                	.insn	2, 0x00dd
  32:	0000                	.insn	2, 0x0000
  34:	009c                	.insn	2, 0x009c
  36:	0000                	.insn	2, 0x0000
  38:	01d2                	.insn	2, 0x01d2
  3a:	0000                	.insn	2, 0x0000
  3c:	000003bf 0000021c 	.insn	8, 0x021c000003bf
  44:	00a6                	.insn	2, 0x00a6
  46:	0000                	.insn	2, 0x0000
  48:	00b2                	.insn	2, 0x00b2
  4a:	0000                	.insn	2, 0x0000
  4c:	00b9                	.insn	2, 0x00b9
  4e:	0000                	.insn	2, 0x0000
  50:	00c1                	.insn	2, 0x00c1
  52:	0000                	.insn	2, 0x0000
  54:	00d1                	.insn	2, 0x00d1
  56:	0000                	.insn	2, 0x0000
  58:	00e1                	.insn	2, 0x00e1
  5a:	0000                	.insn	2, 0x0000
  5c:	00e8                	.insn	2, 0x00e8
  5e:	0000                	.insn	2, 0x0000
  60:	00f2                	.insn	2, 0x00f2
  62:	0000                	.insn	2, 0x0000
  64:	0100                	.insn	2, 0x0100
  66:	0000                	.insn	2, 0x0000
  68:	010d                	.insn	2, 0x010d
  6a:	0000                	.insn	2, 0x0000
  6c:	0121                	.insn	2, 0x0121
  6e:	0000                	.insn	2, 0x0000
  70:	0132                	.insn	2, 0x0132
  72:	0000                	.insn	2, 0x0000
  74:	0149                	.insn	2, 0x0149
  76:	0000                	.insn	2, 0x0000
  78:	0155                	.insn	2, 0x0155
  7a:	0000                	.insn	2, 0x0000
  7c:	015e                	.insn	2, 0x015e
  7e:	0000                	.insn	2, 0x0000
  80:	0168                	.insn	2, 0x0168
  82:	0000                	.insn	2, 0x0000
  84:	0174                	.insn	2, 0x0174
  86:	0000                	.insn	2, 0x0000
  88:	017f 0000 0184 0000 	.insn	10, 0x018d000001840000017f
  90:	018d 
  92:	0000                	.insn	2, 0x0000
  94:	0192                	.insn	2, 0x0192
  96:	0000                	.insn	2, 0x0000
  98:	01a5                	.insn	2, 0x01a5
  9a:	0000                	.insn	2, 0x0000
  9c:	000001b7          	lui	gp,0x0
  a0:	01bc                	.insn	2, 0x01bc
  a2:	0000                	.insn	2, 0x0000
  a4:	000001c7          	.insn	4, 0x01c7
  a8:	000001cf          	.insn	4, 0x01cf
  ac:	01d4                	.insn	2, 0x01d4
  ae:	0000                	.insn	2, 0x0000
  b0:	01dc                	.insn	2, 0x01dc
  b2:	0000                	.insn	2, 0x0000
  b4:	01e1                	.insn	2, 0x01e1
  b6:	0000                	.insn	2, 0x0000
  b8:	017c                	.insn	2, 0x017c
  ba:	0000                	.insn	2, 0x0000
  bc:	01d9                	.insn	2, 0x01d9
  be:	0000                	.insn	2, 0x0000
  c0:	01e5                	.insn	2, 0x01e5
  c2:	0000                	.insn	2, 0x0000
  c4:	00e6                	.insn	2, 0x00e6
  c6:	0000                	.insn	2, 0x0000
  c8:	01f1                	.insn	2, 0x01f1
  ca:	0000                	.insn	2, 0x0000
  cc:	01fd                	.insn	2, 0x01fd
  ce:	0000                	.insn	2, 0x0000
  d0:	01f6                	.insn	2, 0x01f6
  d2:	0000                	.insn	2, 0x0000
  d4:	0445                	.insn	2, 0x0445
  d6:	0000                	.insn	2, 0x0000
  d8:	0201                	.insn	2, 0x0201
  da:	0000                	.insn	2, 0x0000
  dc:	0000020b          	.insn	4, 0x020b
  e0:	0212                	.insn	2, 0x0212
  e2:	0000                	.insn	2, 0x0000
  e4:	021e                	.insn	2, 0x021e
  e6:	0000                	.insn	2, 0x0000
  e8:	000001e3          	beqz	zero,8ea <start-0x3ff716>
  ec:	0178                	.insn	2, 0x0178
  ee:	0000                	.insn	2, 0x0000
  f0:	0005                	.insn	2, 0x0005
  f2:	0000                	.insn	2, 0x0000
  f4:	0000                	.insn	2, 0x0000
  f6:	0000                	.insn	2, 0x0000
  f8:	0222                	.insn	2, 0x0222
  fa:	0000                	.insn	2, 0x0000
  fc:	00000033          	add	zero,zero,zero
 100:	0236                	.insn	2, 0x0236
 102:	0000                	.insn	2, 0x0000
 104:	0068                	.insn	2, 0x0068
 106:	0000                	.insn	2, 0x0000
 108:	022d                	.insn	2, 0x022d
 10a:	0000                	.insn	2, 0x0000
 10c:	0000023b          	.insn	4, 0x023b
 110:	007c                	.insn	2, 0x007c
 112:	0000                	.insn	2, 0x0000
 114:	0089                	.insn	2, 0x0089
 116:	0000                	.insn	2, 0x0000
 118:	009c                	.insn	2, 0x009c
 11a:	0000                	.insn	2, 0x0000
 11c:	0085                	.insn	2, 0x0085
 11e:	0000                	.insn	2, 0x0000
 120:	008a                	.insn	2, 0x008a
 122:	0000                	.insn	2, 0x0000
 124:	00000243          	.insn	4, 0x0243
 128:	0000024b          	.insn	4, 0x024b
 12c:	0251                	.insn	2, 0x0251
 12e:	0000                	.insn	2, 0x0000
 130:	0256                	.insn	2, 0x0256
 132:	0000                	.insn	2, 0x0000
 134:	0000025b          	.insn	4, 0x025b
 138:	00000277          	.insn	4, 0x0277
 13c:	0269                	.insn	2, 0x0269
 13e:	0000                	.insn	2, 0x0000
 140:	0270                	.insn	2, 0x0270
 142:	0000                	.insn	2, 0x0000
 144:	027e                	.insn	2, 0x027e
 146:	0000                	.insn	2, 0x0000
 148:	000000ab          	.insn	4, 0x00ab
 14c:	0260                	.insn	2, 0x0260
 14e:	0000                	.insn	2, 0x0000
 150:	0265                	.insn	2, 0x0265
 152:	0000                	.insn	2, 0x0000
 154:	026c                	.insn	2, 0x026c
 156:	0000                	.insn	2, 0x0000
 158:	00000273          	.insn	4, 0x0273
 15c:	027a                	.insn	2, 0x027a
 15e:	0000                	.insn	2, 0x0000
 160:	0281                	.insn	2, 0x0281
 162:	0000                	.insn	2, 0x0000
 164:	00b9                	.insn	2, 0x00b9
 166:	0000                	.insn	2, 0x0000
 168:	017c                	.insn	2, 0x017c
 16a:	0000                	.insn	2, 0x0000
 16c:	0288                	.insn	2, 0x0288
 16e:	0000                	.insn	2, 0x0000
 170:	01d2                	.insn	2, 0x01d2
 172:	0000                	.insn	2, 0x0000
 174:	0105                	.insn	2, 0x0105
 176:	0000                	.insn	2, 0x0000
 178:	0292                	.insn	2, 0x0292
 17a:	0000                	.insn	2, 0x0000
 17c:	0000029b          	.insn	4, 0x029b
 180:	02a6                	.insn	2, 0x02a6
 182:	0000                	.insn	2, 0x0000
 184:	02b5                	.insn	2, 0x02b5
 186:	0000                	.insn	2, 0x0000
 188:	02bc                	.insn	2, 0x02bc
 18a:	0000                	.insn	2, 0x0000
 18c:	02c4                	.insn	2, 0x02c4
 18e:	0000                	.insn	2, 0x0000
 190:	000000f7          	.insn	4, 0x00f7
 194:	017f 0000 00a6 0000 	.insn	10, 0x00b2000000a60000017f
 19c:	00b2 
 19e:	0000                	.insn	2, 0x0000
 1a0:	0100                	.insn	2, 0x0100
 1a2:	0000                	.insn	2, 0x0000
 1a4:	010d                	.insn	2, 0x010d
 1a6:	0000                	.insn	2, 0x0000
 1a8:	02e0                	.insn	2, 0x02e0
 1aa:	0000                	.insn	2, 0x0000
 1ac:	0121                	.insn	2, 0x0121
 1ae:	0000                	.insn	2, 0x0000
 1b0:	0132                	.insn	2, 0x0132
 1b2:	0000                	.insn	2, 0x0000
 1b4:	000002f3          	.insn	4, 0x02f3
 1b8:	0174                	.insn	2, 0x0174
 1ba:	0000                	.insn	2, 0x0000
 1bc:	00f2                	.insn	2, 0x00f2
 1be:	0000                	.insn	2, 0x0000
 1c0:	0309                	.insn	2, 0x0309
 1c2:	0000                	.insn	2, 0x0000
 1c4:	00e1                	.insn	2, 0x00e1
 1c6:	0000                	.insn	2, 0x0000
 1c8:	00e8                	.insn	2, 0x00e8
 1ca:	0000                	.insn	2, 0x0000
 1cc:	0184                	.insn	2, 0x0184
 1ce:	0000                	.insn	2, 0x0000
 1d0:	018d                	.insn	2, 0x018d
 1d2:	0000                	.insn	2, 0x0000
 1d4:	0310                	.insn	2, 0x0310
 1d6:	0000                	.insn	2, 0x0000
 1d8:	00d1                	.insn	2, 0x00d1
 1da:	0000                	.insn	2, 0x0000
 1dc:	0318                	.insn	2, 0x0318
 1de:	0000                	.insn	2, 0x0000
 1e0:	00c1                	.insn	2, 0x00c1
 1e2:	0000                	.insn	2, 0x0000
 1e4:	032d                	.insn	2, 0x032d
 1e6:	0000                	.insn	2, 0x0000
 1e8:	00000333          	add	t1,zero,zero
 1ec:	033c                	.insn	2, 0x033c
 1ee:	0000                	.insn	2, 0x0000
 1f0:	0345                	.insn	2, 0x0345
 1f2:	0000                	.insn	2, 0x0000
 1f4:	034e                	.insn	2, 0x034e
 1f6:	0000                	.insn	2, 0x0000
 1f8:	00000463          	beqz	zero,200 <start-0x3ffe00>
 1fc:	035a                	.insn	2, 0x035a
 1fe:	0000                	.insn	2, 0x0000
 200:	035c                	.insn	2, 0x035c
 202:	0000                	.insn	2, 0x0000
 204:	0362                	.insn	2, 0x0362
 206:	0000                	.insn	2, 0x0000
 208:	0368                	.insn	2, 0x0368
 20a:	0000                	.insn	2, 0x0000
 20c:	000003c7          	.insn	4, 0x03c7
 210:	037a                	.insn	2, 0x037a
 212:	0000                	.insn	2, 0x0000
 214:	037e                	.insn	2, 0x037e
 216:	0000                	.insn	2, 0x0000
 218:	0384                	.insn	2, 0x0384
 21a:	0000                	.insn	2, 0x0000
 21c:	0386                	.insn	2, 0x0386
 21e:	0000                	.insn	2, 0x0000
 220:	01c5                	.insn	2, 0x01c5
 222:	0000                	.insn	2, 0x0000
 224:	038d                	.insn	2, 0x038d
 226:	0000                	.insn	2, 0x0000
 228:	0445                	.insn	2, 0x0445
 22a:	0000                	.insn	2, 0x0000
 22c:	040a                	.insn	2, 0x040a
 22e:	0000                	.insn	2, 0x0000
 230:	0000044f          	.insn	4, 0x044f
 234:	0391                	.insn	2, 0x0391
 236:	0000                	.insn	2, 0x0000
 238:	0204                	.insn	2, 0x0204
 23a:	0000                	.insn	2, 0x0000
 23c:	0000039b          	.insn	4, 0x039b
 240:	01f1                	.insn	2, 0x01f1
 242:	0000                	.insn	2, 0x0000
 244:	01e1                	.insn	2, 0x01e1
 246:	0000                	.insn	2, 0x0000
 248:	03a2                	.insn	2, 0x03a2
 24a:	0000                	.insn	2, 0x0000
 24c:	03a6                	.insn	2, 0x03a6
 24e:	0000                	.insn	2, 0x0000
 250:	021c                	.insn	2, 0x021c
 252:	0000                	.insn	2, 0x0000
 254:	03aa                	.insn	2, 0x03aa
 256:	0000                	.insn	2, 0x0000
 258:	03ad                	.insn	2, 0x03ad
 25a:	0000                	.insn	2, 0x0000
 25c:	03b0                	.insn	2, 0x03b0
 25e:	0000                	.insn	2, 0x0000
 260:	000003bf 000001e3 	.insn	8, 0x01e3000003bf
 268:	00c8                	.insn	2, 0x00c8
 26a:	0000                	.insn	2, 0x0000
 26c:	0005                	.insn	2, 0x0005
 26e:	0000                	.insn	2, 0x0000
 270:	0000                	.insn	2, 0x0000
 272:	0000                	.insn	2, 0x0000
 274:	03b5                	.insn	2, 0x03b5
 276:	0000                	.insn	2, 0x0000
 278:	00000033          	add	zero,zero,zero
 27c:	0236                	.insn	2, 0x0236
 27e:	0000                	.insn	2, 0x0000
 280:	0068                	.insn	2, 0x0068
 282:	0000                	.insn	2, 0x0000
 284:	03c1                	.insn	2, 0x03c1
 286:	0000                	.insn	2, 0x0000
 288:	022d                	.insn	2, 0x022d
 28a:	0000                	.insn	2, 0x0000
 28c:	0000023b          	.insn	4, 0x023b
 290:	000003cb          	.insn	4, 0x03cb
 294:	000003d3          	.insn	4, 0x03d3
 298:	007c                	.insn	2, 0x007c
 29a:	0000                	.insn	2, 0x0000
 29c:	0089                	.insn	2, 0x0089
 29e:	0000                	.insn	2, 0x0000
 2a0:	03dc                	.insn	2, 0x03dc
 2a2:	0000                	.insn	2, 0x0000
 2a4:	03e6                	.insn	2, 0x03e6
 2a6:	0000                	.insn	2, 0x0000
 2a8:	03f1                	.insn	2, 0x03f1
 2aa:	0000                	.insn	2, 0x0000
 2ac:	03fe                	.insn	2, 0x03fe
 2ae:	0000                	.insn	2, 0x0000
 2b0:	0412                	.insn	2, 0x0412
 2b2:	0000                	.insn	2, 0x0000
 2b4:	02a6                	.insn	2, 0x02a6
 2b6:	0000                	.insn	2, 0x0000
 2b8:	040a                	.insn	2, 0x040a
 2ba:	0000                	.insn	2, 0x0000
 2bc:	00b2                	.insn	2, 0x00b2
 2be:	0000                	.insn	2, 0x0000
 2c0:	0318                	.insn	2, 0x0318
 2c2:	0000                	.insn	2, 0x0000
 2c4:	0085                	.insn	2, 0x0085
 2c6:	0000                	.insn	2, 0x0000
 2c8:	00b9                	.insn	2, 0x00b9
 2ca:	0000                	.insn	2, 0x0000
 2cc:	00e1                	.insn	2, 0x00e1
 2ce:	0000                	.insn	2, 0x0000
 2d0:	041f 0000 042f      	.insn	6, 0x042f0000041f
 2d6:	0000                	.insn	2, 0x0000
 2d8:	00dd                	.insn	2, 0x00dd
 2da:	0000                	.insn	2, 0x0000
 2dc:	00000463          	beqz	zero,2e4 <start-0x3ffd1c>
 2e0:	0434                	.insn	2, 0x0434
 2e2:	0000                	.insn	2, 0x0000
 2e4:	000002f3          	.insn	4, 0x02f3
 2e8:	015e                	.insn	2, 0x015e
 2ea:	0000                	.insn	2, 0x0000
 2ec:	0149                	.insn	2, 0x0149
 2ee:	0000                	.insn	2, 0x0000
 2f0:	0000029b          	.insn	4, 0x029b
 2f4:	0155                	.insn	2, 0x0155
 2f6:	0000                	.insn	2, 0x0000
 2f8:	0168                	.insn	2, 0x0168
 2fa:	0000                	.insn	2, 0x0000
 2fc:	000003c7          	.insn	4, 0x03c7
 300:	0000044f          	.insn	4, 0x044f
 304:	02b1                	.insn	2, 0x02b1
 306:	0000                	.insn	2, 0x0000
 308:	0438                	.insn	2, 0x0438
 30a:	0000                	.insn	2, 0x0000
 30c:	0441                	.insn	2, 0x0441
 30e:	0000                	.insn	2, 0x0000
 310:	0000044b          	.insn	4, 0x044b
 314:	042a                	.insn	2, 0x042a
 316:	0000                	.insn	2, 0x0000
 318:	0454                	.insn	2, 0x0454
 31a:	0000                	.insn	2, 0x0000
 31c:	035a                	.insn	2, 0x035a
 31e:	0000                	.insn	2, 0x0000
 320:	045d                	.insn	2, 0x045d
 322:	0000                	.insn	2, 0x0000
 324:	0000038b          	.insn	4, 0x038b
 328:	045f 0000 0465      	.insn	6, 0x04650000045f
 32e:	0000                	.insn	2, 0x0000
 330:	0000046b          	.insn	4, 0x046b

Disassembly of section .debug_str:

00000000 <.debug_str>:
   0:	6255                	.insn	2, 0x6255
   2:	6e75                	.insn	2, 0x6e75
   4:	7574                	.insn	2, 0x7574
   6:	6320                	.insn	2, 0x6320
   8:	616c                	.insn	2, 0x616c
   a:	676e                	.insn	2, 0x676e
   c:	7620                	.insn	2, 0x7620
   e:	7265                	.insn	2, 0x7265
  10:	6e6f6973          	csrrsi	s2,0x6e6,30
  14:	3220                	.insn	2, 0x3220
  16:	2e31                	.insn	2, 0x2e31
  18:	2e31                	.insn	2, 0x2e31
  1a:	2038                	.insn	2, 0x2038
  1c:	3628                	.insn	2, 0x3628
  1e:	6275                	.insn	2, 0x6275
  20:	6e75                	.insn	2, 0x6e75
  22:	7574                	.insn	2, 0x7574
  24:	2931                	.insn	2, 0x2931
  26:	7300                	.insn	2, 0x7300
  28:	6372                	.insn	2, 0x6372
  2a:	6568732f          	.insn	4, 0x6568732f
  2e:	6c6c                	.insn	2, 0x6c6c
  30:	632e                	.insn	2, 0x632e
  32:	2f00                	.insn	2, 0x2f00
  34:	6f68                	.insn	2, 0x6f68
  36:	656d                	.insn	2, 0x656d
  38:	7261682f          	.insn	4, 0x7261682f
  3c:	6875                	.insn	2, 0x6875
  3e:	6b69                	.insn	2, 0x6b69
  40:	72502f6f          	jal	t5,2f64 <start-0x3fd09c>
  44:	6172676f          	jal	a4,26e5a <start-0x3d91a6>
  48:	2f6d                	.insn	2, 0x2f6d
  4a:	5350                	.insn	2, 0x5350
  4c:	56525f43          	.insn	4, 0x56525f43
  50:	2f493233          	.insn	4, 0x2f493233
  54:	5350                	.insn	2, 0x5350
  56:	4e4f2d43          	.insn	4, 0x4e4f2d43
  5a:	2f45                	.insn	2, 0x2f45
  5c:	74666f73          	csrrsi	t5,0x746,12
  60:	65726177          	.insn	4, 0x65726177
  64:	00736f2f          	.insn	4, 0x00736f2f
  68:	5f5f 5241 4152      	.insn	6, 0x415252415f5f
  6e:	5f59                	.insn	2, 0x5f59
  70:	455a4953          	.insn	4, 0x455a4953
  74:	545f 5059 5f45      	.insn	6, 0x5f455059545f
  7a:	005f 6e75 6973      	.insn	6, 0x69736e75005f
  80:	64656e67          	.insn	4, 0x64656e67
  84:	6920                	.insn	2, 0x6920
  86:	746e                	.insn	2, 0x746e
  88:	7500                	.insn	2, 0x7500
  8a:	6e69                	.insn	2, 0x6e69
  8c:	3374                	.insn	2, 0x3374
  8e:	5f32                	.insn	2, 0x5f32
  90:	0074                	.insn	2, 0x0074
  92:	6170                	.insn	2, 0x6170
  94:	7372                	.insn	2, 0x7372
  96:	5f65                	.insn	2, 0x5f65
  98:	6568                	.insn	2, 0x6568
  9a:	0078                	.insn	2, 0x0078
  9c:	6975                	.insn	2, 0x6975
  9e:	746e                	.insn	2, 0x746e
  a0:	7470                	.insn	2, 0x7470
  a2:	5f72                	.insn	2, 0x5f72
  a4:	0074                	.insn	2, 0x0074
  a6:	6c6c6163          	bltu	s8,t1,768 <start-0x3ff898>
  aa:	735f 5f61 7061      	.insn	6, 0x70615f61735f
  b0:	0069                	.insn	2, 0x0069
  b2:	7270                	.insn	2, 0x7270
  b4:	6e69                	.insn	2, 0x6e69
  b6:	6674                	.insn	2, 0x6674
  b8:	7000                	.insn	2, 0x7000
  ba:	7475                	.insn	2, 0x7475
  bc:	72616863          	bltu	sp,t1,7ec <start-0x3ff814>
  c0:	7000                	.insn	2, 0x7000
  c2:	5f6c6c6f          	jal	s8,c66b8 <start-0x339948>
  c6:	74697773          	csrrci	a4,0x746,18
  ca:	615f6863          	bltu	t5,s5,6da <start-0x3ff926>
  ce:	6970                	.insn	2, 0x6970
  d0:	6700                	.insn	2, 0x6700
  d2:	7465                	.insn	2, 0x7465
  d4:	72616863          	bltu	sp,t1,804 <start-0x3ff7fc>
  d8:	745f 6d69 6f65      	.insn	6, 0x6f656d69745f
  de:	7475                	.insn	2, 0x7475
  e0:	7300                	.insn	2, 0x7300
  e2:	7274                	.insn	2, 0x7274
  e4:	00706d63          	bltu	zero,t2,fe <start-0x3fff02>
  e8:	6170                	.insn	2, 0x6170
  ea:	7372                	.insn	2, 0x7372
  ec:	5f65                	.insn	2, 0x5f65
  ee:	3375                	.insn	2, 0x3375
  f0:	0032                	.insn	2, 0x0032
  f2:	6c6c6163          	bltu	s8,t1,7b4 <start-0x3ff84c>
  f6:	645f 6d75 5f70      	.insn	6, 0x5f706d75645f
  fc:	7061                	.insn	2, 0x7061
  fe:	0069                	.insn	2, 0x0069
 100:	6c6c6163          	bltu	s8,t1,7c2 <start-0x3ff83e>
 104:	6d5f 6369 615f      	.insn	6, 0x615f63696d5f
 10a:	6970                	.insn	2, 0x6970
 10c:	6300                	.insn	2, 0x6300
 10e:	6c61                	.insn	2, 0x6c61
 110:	5f6c                	.insn	2, 0x5f6c
 112:	696d                	.insn	2, 0x696d
 114:	72775f63          	bge	a4,t2,852 <start-0x3ff7ae>
 118:	7469                	.insn	2, 0x7469
 11a:	5f65                	.insn	2, 0x5f65
 11c:	6966                	.insn	2, 0x6966
 11e:	656c                	.insn	2, 0x656c
 120:	6300                	.insn	2, 0x6300
 122:	6c61                	.insn	2, 0x6c61
 124:	5f6c                	.insn	2, 0x5f6c
 126:	725f6473          	csrrsi	s0,mhpmevent5h,30
 12a:	6165                	.insn	2, 0x6165
 12c:	5f64                	.insn	2, 0x5f64
 12e:	7061                	.insn	2, 0x7061
 130:	0069                	.insn	2, 0x0069
 132:	6c6c6163          	bltu	s8,t1,7f4 <start-0x3ff80c>
 136:	735f 5f64 7277      	.insn	6, 0x72775f64735f
 13c:	7469                	.insn	2, 0x7469
 13e:	5f65                	.insn	2, 0x5f65
 140:	6574                	.insn	2, 0x6574
 142:	615f7473          	csrrci	s0,htimedeltah,30
 146:	6970                	.insn	2, 0x6970
 148:	6600                	.insn	2, 0x6600
 14a:	7461                	.insn	2, 0x7461
 14c:	6d5f3233          	.insn	4, 0x6d5f3233
 150:	746e756f          	jal	a0,e7896 <start-0x31876a>
 154:	6600                	.insn	2, 0x6600
 156:	7461                	.insn	2, 0x7461
 158:	6c5f3233          	.insn	4, 0x6c5f3233
 15c:	61660073          	.insn	4, 0x61660073
 160:	3374                	.insn	2, 0x3374
 162:	5f32                	.insn	2, 0x5f32
 164:	00746163          	bltu	s0,t2,166 <start-0x3ffe9a>
 168:	6166                	.insn	2, 0x6166
 16a:	3374                	.insn	2, 0x3374
 16c:	5f32                	.insn	2, 0x5f32
 16e:	6f74                	.insn	2, 0x6f74
 170:	6375                	.insn	2, 0x6375
 172:	0068                	.insn	2, 0x0068
 174:	5f646d63          	bltu	s0,s6,76e <start-0x3ff892>
 178:	65657073          	csrci	hviprio1h,10
 17c:	65006863          	bltu	zero,a6,7cc <start-0x3ff834>
 180:	6978                	.insn	2, 0x6978
 182:	0074                	.insn	2, 0x0074
 184:	7369                	.insn	2, 0x7369
 186:	705f 6972 656d      	.insn	6, 0x656d6972705f
 18c:	6200                	.insn	2, 0x6200
 18e:	006c6f6f          	jal	t5,c6194 <start-0x339e6c>
 192:	5744                	.insn	2, 0x5744
 194:	415f 4554 755f      	.insn	6, 0x755f4554415f
 19a:	736e                	.insn	2, 0x736e
 19c:	6769                	.insn	2, 0x6769
 19e:	656e                	.insn	2, 0x656e
 1a0:	5f64                	.insn	2, 0x5f64
 1a2:	44003233          	.insn	4, 0x44003233
 1a6:	54415f57          	.insn	4, 0x54415f57
 1aa:	5f45                	.insn	2, 0x5f45
 1ac:	6e75                	.insn	2, 0x6e75
 1ae:	6e676973          	csrrsi	s2,0x6e6,14
 1b2:	6465                	.insn	2, 0x6465
 1b4:	315f 6d00 6961      	.insn	6, 0x69616d00315f
 1ba:	006e                	.insn	2, 0x006e
 1bc:	5f646d63          	bltu	s0,s6,7b6 <start-0x3ff84a>
 1c0:	7270                	.insn	2, 0x7270
 1c2:	6d69                	.insn	2, 0x6d69
 1c4:	7365                	.insn	2, 0x7365
 1c6:	6300                	.insn	2, 0x6300
 1c8:	646d                	.insn	2, 0x646d
 1ca:	696c                	.insn	2, 0x696c
 1cc:	656e                	.insn	2, 0x656e
 1ce:	6100                	.insn	2, 0x6100
 1d0:	6772                	.insn	2, 0x6772
 1d2:	0076                	.insn	2, 0x0076
 1d4:	7270                	.insn	2, 0x7270
 1d6:	7665                	.insn	2, 0x7665
 1d8:	735f 0077 7261      	.insn	6, 0x72610077735f
 1de:	6c006367          	.insn	4, 0x6c006367
 1e2:	6e65                	.insn	2, 0x6e65
 1e4:	7300                	.insn	2, 0x7300
 1e6:	705f3277          	.insn	4, 0x705f3277
 1ea:	6572                	.insn	2, 0x6572
 1ec:	64657373          	csrrci	t1,hviprio1,10
 1f0:	6100                	.insn	2, 0x6100
 1f2:	6464                	.insn	2, 0x6464
 1f4:	0072                	.insn	2, 0x0072
 1f6:	616d                	.insn	2, 0x616d
 1f8:	7274                	.insn	2, 0x7274
 1fa:	7869                	.insn	2, 0x7869
 1fc:	6d5f 7861 7300      	.insn	6, 0x730078616d5f
 202:	5f64                	.insn	2, 0x5f64
 204:	74636573          	csrrsi	a0,0x746,6
 208:	7000726f          	jal	tp,7908 <start-0x3f86f8>
 20c:	6f72                	.insn	2, 0x6f72
 20e:	706d                	.insn	2, 0x706d
 210:	0074                	.insn	2, 0x0074
 212:	5f317773          	csrrci	a4,0x5f3,2
 216:	7270                	.insn	2, 0x7270
 218:	7365                	.insn	2, 0x7365
 21a:	00646573          	csrrsi	a0,0x6,8
 21e:	6176                	.insn	2, 0x6176
 220:	006c                	.insn	2, 0x006c
 222:	2f637273          	csrrci	tp,0x2f6,6
 226:	7375                	.insn	2, 0x7375
 228:	7265                	.insn	2, 0x7265
 22a:	632e                	.insn	2, 0x632e
 22c:	7500                	.insn	2, 0x7500
 22e:	736e                	.insn	2, 0x736e
 230:	6769                	.insn	2, 0x6769
 232:	656e                	.insn	2, 0x656e
 234:	2064                	.insn	2, 0x2064
 236:	72616863          	bltu	sp,t1,966 <start-0x3ff69a>
 23a:	7500                	.insn	2, 0x7500
 23c:	6e69                	.insn	2, 0x6e69
 23e:	3874                	.insn	2, 0x3874
 240:	745f 7300 7379      	.insn	6, 0x73797300745f
 246:	6c6c6163          	bltu	s8,t1,908 <start-0x3ff6f8>
 24a:	7300                	.insn	2, 0x7300
 24c:	7379                	.insn	2, 0x7379
 24e:	6f6e                	.insn	2, 0x6f6e
 250:	6100                	.insn	2, 0x6100
 252:	6772                	.insn	2, 0x6772
 254:	0030                	.insn	2, 0x0030
 256:	7261                	.insn	2, 0x7261
 258:	61003167          	.insn	4, 0x61003167
 25c:	6772                	.insn	2, 0x6772
 25e:	0032                	.insn	2, 0x0032
 260:	7261                	.insn	2, 0x7261
 262:	72003467          	.insn	4, 0x72003467
 266:	6765                	.insn	2, 0x6765
 268:	615f 0031 6572      	.insn	6, 0x65720031615f
 26e:	32615f67          	.insn	4, 0x32615f67
 272:	7200                	.insn	2, 0x7200
 274:	6765                	.insn	2, 0x6765
 276:	615f 0030 6572      	.insn	6, 0x65720030615f
 27c:	33615f67          	.insn	4, 0x33615f67
 280:	7200                	.insn	2, 0x7200
 282:	6765                	.insn	2, 0x6765
 284:	615f 0034 7270      	.insn	6, 0x72700034615f
 28a:	6e69                	.insn	2, 0x6e69
 28c:	5f74                	.insn	2, 0x5f74
 28e:	6e69                	.insn	2, 0x6e69
 290:	0074                	.insn	2, 0x0074
 292:	696d                	.insn	2, 0x696d
 294:	70615f63          	bge	sp,t1,9b2 <start-0x3ff64e>
 298:	3269                	.insn	2, 0x3269
 29a:	6600                	.insn	2, 0x6600
 29c:	7461                	.insn	2, 0x7461
 29e:	665f3233          	.insn	4, 0x665f3233
 2a2:	6e69                	.insn	2, 0x6e69
 2a4:	0064                	.insn	2, 0x0064
 2a6:	73756c63          	bltu	a0,s7,9de <start-0x3ff622>
 2aa:	6574                	.insn	2, 0x6574
 2ac:	5f72                	.insn	2, 0x5f72
 2ae:	6f74                	.insn	2, 0x6f74
 2b0:	6c5f 6162 7300      	.insn	6, 0x730061626c5f
 2b6:	5f64                	.insn	2, 0x5f64
 2b8:	7061                	.insn	2, 0x7061
 2ba:	0069                	.insn	2, 0x0069
 2bc:	615f6473          	csrrsi	s0,htimedeltah,30
 2c0:	6970                	.insn	2, 0x6970
 2c2:	0032                	.insn	2, 0x0032
 2c4:	6c6c6163          	bltu	s8,t1,986 <start-0x3ff67a>
 2c8:	735f 6570 6365      	.insn	6, 0x63656570735f
 2ce:	5f68                	.insn	2, 0x5f68
 2d0:	6572                	.insn	2, 0x6572
 2d2:	6e676f63          	bltu	a4,t1,9d0 <start-0x3ff630>
 2d6:	7469                	.insn	2, 0x7469
 2d8:	6f69                	.insn	2, 0x6f69
 2da:	5f6e                	.insn	2, 0x5f6e
 2dc:	7061                	.insn	2, 0x7061
 2de:	0069                	.insn	2, 0x0069
 2e0:	6c6c6163          	bltu	s8,t1,9a2 <start-0x3ff65e>
 2e4:	6d5f 6369 775f      	.insn	6, 0x775f63696d5f
 2ea:	6972                	.insn	2, 0x6972
 2ec:	6574                	.insn	2, 0x6574
 2ee:	615f 6970 6300      	.insn	6, 0x63006970615f
 2f4:	6c61                	.insn	2, 0x6c61
 2f6:	5f6c                	.insn	2, 0x5f6c
 2f8:	775f6473          	csrrsi	s0,0x775,30
 2fc:	6972                	.insn	2, 0x6972
 2fe:	6574                	.insn	2, 0x6574
 300:	625f 6675 615f      	.insn	6, 0x615f6675625f
 306:	6970                	.insn	2, 0x6970
 308:	7300                	.insn	2, 0x7300
 30a:	7274                	.insn	2, 0x7274
 30c:	00797063          	bgeu	s2,t2,30c <start-0x3ffcf4>
 310:	63746567          	.insn	4, 0x63746567
 314:	6168                	.insn	2, 0x6168
 316:	0072                	.insn	2, 0x0072
 318:	6c6c6163          	bltu	s8,t1,9da <start-0x3ff626>
 31c:	735f 5f64 6572      	.insn	6, 0x65725f64735f
 322:	6461                	.insn	2, 0x6461
 324:	625f 6675 615f      	.insn	6, 0x615f6675625f
 32a:	6970                	.insn	2, 0x6970
 32c:	7300                	.insn	2, 0x7300
 32e:	6174                	.insn	2, 0x6174
 330:	7472                	.insn	2, 0x7472
 332:	6d00                	.insn	2, 0x6d00
 334:	7461                	.insn	2, 0x7461
 336:	6972                	.insn	2, 0x6972
 338:	5f78                	.insn	2, 0x5f78
 33a:	0041                	.insn	2, 0x0041
 33c:	616d                	.insn	2, 0x616d
 33e:	7274                	.insn	2, 0x7274
 340:	7869                	.insn	2, 0x7869
 342:	425f 6d00 7461      	.insn	6, 0x74616d00425f
 348:	6972                	.insn	2, 0x6972
 34a:	5f78                	.insn	2, 0x5f78
 34c:	616d0043          	.insn	4, 0x616d0043
 350:	7274                	.insn	2, 0x7274
 352:	7869                	.insn	2, 0x7869
 354:	735f 7a69 0065      	.insn	6, 0x00657a69735f
 35a:	006a                	.insn	2, 0x006a
 35c:	6e69                	.insn	2, 0x6e69
 35e:	6564                	.insn	2, 0x6564
 360:	0078                	.insn	2, 0x0078
 362:	6176                	.insn	2, 0x6176
 364:	6772                	.insn	2, 0x6772
 366:	5f5f0073          	.insn	4, 0x5f5f0073
 36a:	7562                	.insn	2, 0x7562
 36c:	6c69                	.insn	2, 0x6c69
 36e:	6974                	.insn	2, 0x6974
 370:	5f6e                	.insn	2, 0x5f6e
 372:	6176                	.insn	2, 0x6176
 374:	6c5f 7369 0074      	.insn	6, 0x007473696c5f
 37a:	6d66                	.insn	2, 0x6d66
 37c:	0074                	.insn	2, 0x0074
 37e:	6176                	.insn	2, 0x6176
 380:	756c                	.insn	2, 0x756c
 382:	0065                	.insn	2, 0x0065
 384:	0075                	.insn	2, 0x0075
 386:	696e                	.insn	2, 0x696e
 388:	6262                	.insn	2, 0x6262
 38a:	656c                	.insn	2, 0x656c
 38c:	6500                	.insn	2, 0x6500
 38e:	646e                	.insn	2, 0x646e
 390:	7300                	.insn	2, 0x7300
 392:	6174                	.insn	2, 0x6174
 394:	7472                	.insn	2, 0x7472
 396:	6c5f 6162 7200      	.insn	6, 0x720061626c5f
 39c:	7365                	.insn	2, 0x7365
 39e:	6c75                	.insn	2, 0x6c75
 3a0:	0074                	.insn	2, 0x0074
 3a2:	7364                	.insn	2, 0x7364
 3a4:	0074                	.insn	2, 0x0074
 3a6:	00637273          	csrrci	tp,0x6,6
 3aa:	73003173          	csrrc	sp,mhpmevent16h,zero
 3ae:	0032                	.insn	2, 0x0032
 3b0:	6162                	.insn	2, 0x6162
 3b2:	73006573          	csrrsi	a0,mhpmevent16h,0
 3b6:	6372                	.insn	2, 0x6372
 3b8:	7461662f          	.insn	4, 0x7461662f
 3bc:	632e3233          	.insn	4, 0x632e3233
 3c0:	6600                	.insn	2, 0x6600
 3c2:	7461                	.insn	2, 0x7461
 3c4:	625f3233          	.insn	4, 0x625f3233
 3c8:	6675                	.insn	2, 0x6675
 3ca:	6700                	.insn	2, 0x6700
 3cc:	665f 7461 3233      	.insn	6, 0x32337461665f
 3d2:	7000                	.insn	2, 0x7000
 3d4:	7261                	.insn	2, 0x7261
 3d6:	5f74                	.insn	2, 0x5f74
 3d8:	626c                	.insn	2, 0x626c
 3da:	0061                	.insn	2, 0x0061
 3dc:	6166                	.insn	2, 0x6166
 3de:	5f74                	.insn	2, 0x5f74
 3e0:	6562                	.insn	2, 0x6562
 3e2:	006e6967          	.insn	4, 0x006e6967
 3e6:	6164                	.insn	2, 0x6164
 3e8:	6174                	.insn	2, 0x6174
 3ea:	625f 6765 6e69      	.insn	6, 0x6e696765625f
 3f0:	7200                	.insn	2, 0x7200
 3f2:	5f746f6f          	jal	t5,471e8 <start-0x3b8e18>
 3f6:	73756c63          	bltu	a0,s7,b2e <start-0x3ff4d2>
 3fa:	6574                	.insn	2, 0x6574
 3fc:	0072                	.insn	2, 0x0072
 3fe:	74636573          	csrrsi	a0,0x746,6
 402:	5f73726f          	jal	tp,381f8 <start-0x3c7e08>
 406:	6570                	.insn	2, 0x6570
 408:	5f72                	.insn	2, 0x5f72
 40a:	73756c63          	bltu	a0,s7,b42 <start-0x3ff4be>
 40e:	6574                	.insn	2, 0x6574
 410:	0072                	.insn	2, 0x0072
 412:	6166                	.insn	2, 0x6166
 414:	3374                	.insn	2, 0x3374
 416:	5f32                	.insn	2, 0x5f32
 418:	6e69                	.insn	2, 0x6e69
 41a:	6f66                	.insn	2, 0x6f66
 41c:	745f 6600 7461      	.insn	6, 0x74616600745f
 422:	6d5f3233          	.insn	4, 0x6d5f3233
 426:	6b61                	.insn	2, 0x6b61
 428:	5f65                	.insn	2, 0x5f65
 42a:	726f6873          	csrrsi	a6,mhpmevent6h,30
 42e:	6e74                	.insn	2, 0x6e74
 430:	6d61                	.insn	2, 0x6d61
 432:	0065                	.insn	2, 0x0065
 434:	6f70                	.insn	2, 0x6f70
 436:	65720073          	.insn	4, 0x65720073
 43a:	76726573          	csrrsi	a0,0x767,4
 43e:	6465                	.insn	2, 0x6465
 440:	6600                	.insn	2, 0x6600
 442:	7461                	.insn	2, 0x7461
 444:	635f 756f 746e      	.insn	6, 0x746e756f635f
 44a:	6600                	.insn	2, 0x6600
 44c:	7461                	.insn	2, 0x7461
 44e:	735f 7a69 0065      	.insn	6, 0x00657a69735f
 454:	6f72                	.insn	2, 0x6f72
 456:	6c5f746f          	jal	s0,f831a <start-0x307ce6>
 45a:	6162                	.insn	2, 0x6162
 45c:	6b00                	.insn	2, 0x6b00
 45e:	6300                	.insn	2, 0x6300
 460:	5f6c                	.insn	2, 0x5f6c
 462:	6968                	.insn	2, 0x6968
 464:	6300                	.insn	2, 0x6300
 466:	5f6c                	.insn	2, 0x5f6c
 468:	6f6c                	.insn	2, 0x6f6c
 46a:	6300                	.insn	2, 0x6300
 46c:	006c                	.insn	2, 0x006c

Disassembly of section .debug_addr:

00000000 <.debug_addr>:
   0:	0214                	.insn	2, 0x0214
   2:	0000                	.insn	2, 0x0000
   4:	0005                	.insn	2, 0x0005
   6:	0004                	.insn	2, 0x0004
   8:	1ed4                	.insn	2, 0x1ed4
   a:	0040                	.insn	2, 0x0040
   c:	1ee2                	.insn	2, 0x1ee2
   e:	0040                	.insn	2, 0x0040
  10:	00401eef          	jal	t4,1014 <start-0x3fefec>
  14:	1efc                	.insn	2, 0x1efc
  16:	0040                	.insn	2, 0x0040
  18:	1f02                	.insn	2, 0x1f02
  1a:	0040                	.insn	2, 0x0040
  1c:	00401f1b          	.insn	4, 0x00401f1b
  20:	1f20                	.insn	2, 0x1f20
  22:	0040                	.insn	2, 0x0040
  24:	00401f27          	.insn	4, 0x00401f27
  28:	1f41                	.insn	2, 0x1f41
  2a:	0040                	.insn	2, 0x0040
  2c:	00401f4b          	.insn	4, 0x00401f4b
  30:	1f54                	.insn	2, 0x1f54
  32:	0040                	.insn	2, 0x0040
  34:	1f65                	.insn	2, 0x1f65
  36:	0040                	.insn	2, 0x0040
  38:	1f6e                	.insn	2, 0x1f6e
  3a:	0040                	.insn	2, 0x0040
  3c:	00401f87          	.insn	4, 0x00401f87
  40:	1f91                	.insn	2, 0x1f91
  42:	0040                	.insn	2, 0x0040
  44:	00401fab          	.insn	4, 0x00401fab
  48:	00401fb3          	sll	t6,zero,tp
  4c:	1fcc                	.insn	2, 0x1fcc
  4e:	0040                	.insn	2, 0x0040
  50:	1fd5                	.insn	2, 0x1fd5
  52:	0040                	.insn	2, 0x0040
  54:	00401fef          	jal	t6,1058 <start-0x3fefa8>
  58:	200e                	.insn	2, 0x200e
  5a:	0040                	.insn	2, 0x0040
  5c:	2019                	.insn	2, 0x2019
  5e:	0040                	.insn	2, 0x0040
  60:	202d                	.insn	2, 0x202d
  62:	0040                	.insn	2, 0x0040
  64:	203a                	.insn	2, 0x203a
  66:	0040                	.insn	2, 0x0040
  68:	0040204b          	.insn	4, 0x0040204b
  6c:	00402053          	.insn	4, 0x00402053
  70:	2061                	.insn	2, 0x2061
  72:	0040                	.insn	2, 0x0040
  74:	2070                	.insn	2, 0x2070
  76:	0040                	.insn	2, 0x0040
  78:	2079                	.insn	2, 0x2079
  7a:	0040                	.insn	2, 0x0040
  7c:	00402083          	lw	ra,4(zero) # 4 <start-0x3ffffc>
  80:	209c                	.insn	2, 0x209c
  82:	0040                	.insn	2, 0x0040
  84:	20a8                	.insn	2, 0x20a8
  86:	0040                	.insn	2, 0x0040
  88:	004020c3          	.insn	4, 0x004020c3
  8c:	004020d7          	.insn	4, 0x004020d7
  90:	20de                	.insn	2, 0x20de
  92:	0040                	.insn	2, 0x0040
  94:	004020e3          	.insn	4, 0x004020e3
  98:	20ee                	.insn	2, 0x20ee
  9a:	0040                	.insn	2, 0x0040
  9c:	004020f3          	csrr	ra,0x4
  a0:	20f8                	.insn	2, 0x20f8
  a2:	0040                	.insn	2, 0x0040
  a4:	20fa                	.insn	2, 0x20fa
  a6:	0040                	.insn	2, 0x0040
  a8:	0040210f          	.insn	4, 0x0040210f
  ac:	00402113          	slti	sp,zero,4
  b0:	001c                	.insn	2, 0x001c
  b2:	0040                	.insn	2, 0x0040
  b4:	00b0                	.insn	2, 0x00b0
  b6:	0040                	.insn	2, 0x0040
  b8:	0764                	.insn	2, 0x0764
  ba:	0040                	.insn	2, 0x0040
  bc:	06e8                	.insn	2, 0x06e8
  be:	0040                	.insn	2, 0x0040
  c0:	06b0                	.insn	2, 0x06b0
  c2:	0040                	.insn	2, 0x0040
  c4:	0634                	.insn	2, 0x0634
  c6:	0040                	.insn	2, 0x0040
  c8:	0060                	.insn	2, 0x0060
  ca:	0040                	.insn	2, 0x0040
  cc:	0070                	.insn	2, 0x0070
  ce:	0040                	.insn	2, 0x0040
  d0:	00c0                	.insn	2, 0x00c0
  d2:	0040                	.insn	2, 0x0040
  d4:	00d0                	.insn	2, 0x00d0
  d6:	0040                	.insn	2, 0x0040
  d8:	00dc                	.insn	2, 0x00dc
  da:	0040                	.insn	2, 0x0040
  dc:	00e8                	.insn	2, 0x00e8
  de:	0040                	.insn	2, 0x0040
  e0:	00f4                	.insn	2, 0x00f4
  e2:	0040                	.insn	2, 0x0040
  e4:	0100                	.insn	2, 0x0100
  e6:	0040                	.insn	2, 0x0040
  e8:	010c                	.insn	2, 0x010c
  ea:	0040                	.insn	2, 0x0040
  ec:	0118                	.insn	2, 0x0118
  ee:	0040                	.insn	2, 0x0040
  f0:	0124                	.insn	2, 0x0124
  f2:	0040                	.insn	2, 0x0040
  f4:	0130                	.insn	2, 0x0130
  f6:	0040                	.insn	2, 0x0040
  f8:	013c                	.insn	2, 0x013c
  fa:	0040                	.insn	2, 0x0040
  fc:	0148                	.insn	2, 0x0148
  fe:	0040                	.insn	2, 0x0040
 100:	0154                	.insn	2, 0x0154
 102:	0040                	.insn	2, 0x0040
 104:	0160                	.insn	2, 0x0160
 106:	0040                	.insn	2, 0x0040
 108:	016c                	.insn	2, 0x016c
 10a:	0040                	.insn	2, 0x0040
 10c:	0178                	.insn	2, 0x0178
 10e:	0040                	.insn	2, 0x0040
 110:	0184                	.insn	2, 0x0184
 112:	0040                	.insn	2, 0x0040
 114:	0198                	.insn	2, 0x0198
 116:	0040                	.insn	2, 0x0040
 118:	01b4                	.insn	2, 0x01b4
 11a:	0040                	.insn	2, 0x0040
 11c:	01d4                	.insn	2, 0x01d4
 11e:	0040                	.insn	2, 0x0040
 120:	01f4                	.insn	2, 0x01f4
 122:	0040                	.insn	2, 0x0040
 124:	01fc                	.insn	2, 0x01fc
 126:	0040                	.insn	2, 0x0040
 128:	025c                	.insn	2, 0x025c
 12a:	0040                	.insn	2, 0x0040
 12c:	0268                	.insn	2, 0x0268
 12e:	0040                	.insn	2, 0x0040
 130:	027c                	.insn	2, 0x027c
 132:	0040                	.insn	2, 0x0040
 134:	032c                	.insn	2, 0x032c
 136:	0040                	.insn	2, 0x0040
 138:	0344                	.insn	2, 0x0344
 13a:	0040                	.insn	2, 0x0040
 13c:	035c                	.insn	2, 0x035c
 13e:	0040                	.insn	2, 0x0040
 140:	0378                	.insn	2, 0x0378
 142:	0040                	.insn	2, 0x0040
 144:	0390                	.insn	2, 0x0390
 146:	0040                	.insn	2, 0x0040
 148:	03a8                	.insn	2, 0x03a8
 14a:	0040                	.insn	2, 0x0040
 14c:	03c0                	.insn	2, 0x03c0
 14e:	0040                	.insn	2, 0x0040
 150:	03d8                	.insn	2, 0x03d8
 152:	0040                	.insn	2, 0x0040
 154:	03f0                	.insn	2, 0x03f0
 156:	0040                	.insn	2, 0x0040
 158:	0408                	.insn	2, 0x0408
 15a:	0040                	.insn	2, 0x0040
 15c:	0420                	.insn	2, 0x0420
 15e:	0040                	.insn	2, 0x0040
 160:	0438                	.insn	2, 0x0438
 162:	0040                	.insn	2, 0x0040
 164:	0450                	.insn	2, 0x0450
 166:	0040                	.insn	2, 0x0040
 168:	0468                	.insn	2, 0x0468
 16a:	0040                	.insn	2, 0x0040
 16c:	0480                	.insn	2, 0x0480
 16e:	0040                	.insn	2, 0x0040
 170:	0498                	.insn	2, 0x0498
 172:	0040                	.insn	2, 0x0040
 174:	04b0                	.insn	2, 0x04b0
 176:	0040                	.insn	2, 0x0040
 178:	04c8                	.insn	2, 0x04c8
 17a:	0040                	.insn	2, 0x0040
 17c:	04e0                	.insn	2, 0x04e0
 17e:	0040                	.insn	2, 0x0040
 180:	0544                	.insn	2, 0x0544
 182:	0040                	.insn	2, 0x0040
 184:	056c                	.insn	2, 0x056c
 186:	0040                	.insn	2, 0x0040
 188:	0590                	.insn	2, 0x0590
 18a:	0040                	.insn	2, 0x0040
 18c:	05e8                	.insn	2, 0x05e8
 18e:	0040                	.insn	2, 0x0040
 190:	0610                	.insn	2, 0x0610
 192:	0040                	.insn	2, 0x0040
 194:	0628                	.insn	2, 0x0628
 196:	0040                	.insn	2, 0x0040
 198:	0644                	.insn	2, 0x0644
 19a:	0040                	.insn	2, 0x0040
 19c:	064c                	.insn	2, 0x064c
 19e:	0040                	.insn	2, 0x0040
 1a0:	06c0                	.insn	2, 0x06c0
 1a2:	0040                	.insn	2, 0x0040
 1a4:	06c8                	.insn	2, 0x06c8
 1a6:	0040                	.insn	2, 0x0040
 1a8:	06dc                	.insn	2, 0x06dc
 1aa:	0040                	.insn	2, 0x0040
 1ac:	06f8                	.insn	2, 0x06f8
 1ae:	0040                	.insn	2, 0x0040
 1b0:	0700                	.insn	2, 0x0700
 1b2:	0040                	.insn	2, 0x0040
 1b4:	0774                	.insn	2, 0x0774
 1b6:	0040                	.insn	2, 0x0040
 1b8:	0798                	.insn	2, 0x0798
 1ba:	0040                	.insn	2, 0x0040
 1bc:	07a4                	.insn	2, 0x07a4
 1be:	0040                	.insn	2, 0x0040
 1c0:	07bc                	.insn	2, 0x07bc
 1c2:	0040                	.insn	2, 0x0040
 1c4:	07c8                	.insn	2, 0x07c8
 1c6:	0040                	.insn	2, 0x0040
 1c8:	07e4                	.insn	2, 0x07e4
 1ca:	0040                	.insn	2, 0x0040
 1cc:	0804                	.insn	2, 0x0804
 1ce:	0040                	.insn	2, 0x0040
 1d0:	0818                	.insn	2, 0x0818
 1d2:	0040                	.insn	2, 0x0040
 1d4:	082c                	.insn	2, 0x082c
 1d6:	0040                	.insn	2, 0x0040
 1d8:	0840                	.insn	2, 0x0840
 1da:	0040                	.insn	2, 0x0040
 1dc:	0854                	.insn	2, 0x0854
 1de:	0040                	.insn	2, 0x0040
 1e0:	0870                	.insn	2, 0x0870
 1e2:	0040                	.insn	2, 0x0040
 1e4:	0884                	.insn	2, 0x0884
 1e6:	0040                	.insn	2, 0x0040
 1e8:	0890                	.insn	2, 0x0890
 1ea:	0040                	.insn	2, 0x0040
 1ec:	08a4                	.insn	2, 0x08a4
 1ee:	0040                	.insn	2, 0x0040
 1f0:	08b0                	.insn	2, 0x08b0
 1f2:	0040                	.insn	2, 0x0040
 1f4:	08b0                	.insn	2, 0x08b0
 1f6:	0040                	.insn	2, 0x0040
 1f8:	0974                	.insn	2, 0x0974
 1fa:	0040                	.insn	2, 0x0040
 1fc:	0998                	.insn	2, 0x0998
 1fe:	0040                	.insn	2, 0x0040
 200:	09bc                	.insn	2, 0x09bc
 202:	0040                	.insn	2, 0x0040
 204:	09d0                	.insn	2, 0x09d0
 206:	0040                	.insn	2, 0x0040
 208:	09e8                	.insn	2, 0x09e8
 20a:	0040                	.insn	2, 0x0040
 20c:	0a00                	.insn	2, 0x0a00
 20e:	0040                	.insn	2, 0x0040
 210:	0a28                	.insn	2, 0x0a28
 212:	0040                	.insn	2, 0x0040
 214:	00c4                	.insn	2, 0x00c4
 216:	0040                	.insn	2, 0x0040
 218:	013c                	.insn	2, 0x013c
 21a:	0000                	.insn	2, 0x0000
 21c:	0005                	.insn	2, 0x0005
 21e:	0004                	.insn	2, 0x0004
 220:	212d                	.insn	2, 0x212d
 222:	0040                	.insn	2, 0x0040
 224:	2142                	.insn	2, 0x2142
 226:	0040                	.insn	2, 0x0040
 228:	214a                	.insn	2, 0x214a
 22a:	0040                	.insn	2, 0x0040
 22c:	215d                	.insn	2, 0x215d
 22e:	0040                	.insn	2, 0x0040
 230:	2175                	.insn	2, 0x2175
 232:	0040                	.insn	2, 0x0040
 234:	00402193          	slti	gp,zero,4
 238:	21ad                	.insn	2, 0x21ad
 23a:	0040                	.insn	2, 0x0040
 23c:	21b9                	.insn	2, 0x21b9
 23e:	0040                	.insn	2, 0x0040
 240:	004021c7          	.insn	4, 0x004021c7
 244:	21d8                	.insn	2, 0x21d8
 246:	0040                	.insn	2, 0x0040
 248:	21ea                	.insn	2, 0x21ea
 24a:	0040                	.insn	2, 0x0040
 24c:	0a30                	.insn	2, 0x0a30
 24e:	0040                	.insn	2, 0x0040
 250:	0a48                	.insn	2, 0x0a48
 252:	0040                	.insn	2, 0x0040
 254:	0a68                	.insn	2, 0x0a68
 256:	0040                	.insn	2, 0x0040
 258:	0a7c                	.insn	2, 0x0a7c
 25a:	0040                	.insn	2, 0x0040
 25c:	0aec                	.insn	2, 0x0aec
 25e:	0040                	.insn	2, 0x0040
 260:	0b04                	.insn	2, 0x0b04
 262:	0040                	.insn	2, 0x0040
 264:	0b10                	.insn	2, 0x0b10
 266:	0040                	.insn	2, 0x0040
 268:	0b28                	.insn	2, 0x0b28
 26a:	0040                	.insn	2, 0x0040
 26c:	0b3c                	.insn	2, 0x0b3c
 26e:	0040                	.insn	2, 0x0040
 270:	0b48                	.insn	2, 0x0b48
 272:	0040                	.insn	2, 0x0040
 274:	0b5c                	.insn	2, 0x0b5c
 276:	0040                	.insn	2, 0x0040
 278:	0b80                	.insn	2, 0x0b80
 27a:	0040                	.insn	2, 0x0040
 27c:	0b8c                	.insn	2, 0x0b8c
 27e:	0040                	.insn	2, 0x0040
 280:	0b98                	.insn	2, 0x0b98
 282:	0040                	.insn	2, 0x0040
 284:	0bb0                	.insn	2, 0x0bb0
 286:	0040                	.insn	2, 0x0040
 288:	0bc4                	.insn	2, 0x0bc4
 28a:	0040                	.insn	2, 0x0040
 28c:	0bd0                	.insn	2, 0x0bd0
 28e:	0040                	.insn	2, 0x0040
 290:	0be4                	.insn	2, 0x0be4
 292:	0040                	.insn	2, 0x0040
 294:	0c08                	.insn	2, 0x0c08
 296:	0040                	.insn	2, 0x0040
 298:	0c14                	.insn	2, 0x0c14
 29a:	0040                	.insn	2, 0x0040
 29c:	0c20                	.insn	2, 0x0c20
 29e:	0040                	.insn	2, 0x0040
 2a0:	0c38                	.insn	2, 0x0c38
 2a2:	0040                	.insn	2, 0x0040
 2a4:	0c4c                	.insn	2, 0x0c4c
 2a6:	0040                	.insn	2, 0x0040
 2a8:	0c58                	.insn	2, 0x0c58
 2aa:	0040                	.insn	2, 0x0040
 2ac:	0c6c                	.insn	2, 0x0c6c
 2ae:	0040                	.insn	2, 0x0040
 2b0:	0c88                	.insn	2, 0x0c88
 2b2:	0040                	.insn	2, 0x0040
 2b4:	0ca4                	.insn	2, 0x0ca4
 2b6:	0040                	.insn	2, 0x0040
 2b8:	0cac                	.insn	2, 0x0cac
 2ba:	0040                	.insn	2, 0x0040
 2bc:	0ed0                	.insn	2, 0x0ed0
 2be:	0040                	.insn	2, 0x0040
 2c0:	0d78                	.insn	2, 0x0d78
 2c2:	0040                	.insn	2, 0x0040
 2c4:	0f20                	.insn	2, 0x0f20
 2c6:	0040                	.insn	2, 0x0040
 2c8:	0d94                	.insn	2, 0x0d94
 2ca:	0040                	.insn	2, 0x0040
 2cc:	0da4                	.insn	2, 0x0da4
 2ce:	0040                	.insn	2, 0x0040
 2d0:	0e84                	.insn	2, 0x0e84
 2d2:	0040                	.insn	2, 0x0040
 2d4:	0e98                	.insn	2, 0x0e98
 2d6:	0040                	.insn	2, 0x0040
 2d8:	0eb4                	.insn	2, 0x0eb4
 2da:	0040                	.insn	2, 0x0040
 2dc:	0f40                	.insn	2, 0x0f40
 2de:	0040                	.insn	2, 0x0040
 2e0:	0d38                	.insn	2, 0x0d38
 2e2:	0040                	.insn	2, 0x0040
 2e4:	0f64                	.insn	2, 0x0f64
 2e6:	0040                	.insn	2, 0x0040
 2e8:	0f78                	.insn	2, 0x0f78
 2ea:	0040                	.insn	2, 0x0040
 2ec:	0f8c                	.insn	2, 0x0f8c
 2ee:	0040                	.insn	2, 0x0040
 2f0:	0f98                	.insn	2, 0x0f98
 2f2:	0040                	.insn	2, 0x0040
 2f4:	1030                	.insn	2, 0x1030
 2f6:	0040                	.insn	2, 0x0040
 2f8:	0fc4                	.insn	2, 0x0fc4
 2fa:	0040                	.insn	2, 0x0040
 2fc:	0ff0                	.insn	2, 0x0ff0
 2fe:	0040                	.insn	2, 0x0040
 300:	1010                	.insn	2, 0x1010
 302:	0040                	.insn	2, 0x0040
 304:	1044                	.insn	2, 0x1044
 306:	0040                	.insn	2, 0x0040
 308:	1050                	.insn	2, 0x1050
 30a:	0040                	.insn	2, 0x0040
 30c:	105c                	.insn	2, 0x105c
 30e:	0040                	.insn	2, 0x0040
 310:	1068                	.insn	2, 0x1068
 312:	0040                	.insn	2, 0x0040
 314:	1074                	.insn	2, 0x1074
 316:	0040                	.insn	2, 0x0040
 318:	108c                	.insn	2, 0x108c
 31a:	0040                	.insn	2, 0x0040
 31c:	10d8                	.insn	2, 0x10d8
 31e:	0040                	.insn	2, 0x0040
 320:	10f0                	.insn	2, 0x10f0
 322:	0040                	.insn	2, 0x0040
 324:	10f8                	.insn	2, 0x10f8
 326:	0040                	.insn	2, 0x0040
 328:	1108                	.insn	2, 0x1108
 32a:	0040                	.insn	2, 0x0040
 32c:	1114                	.insn	2, 0x1114
 32e:	0040                	.insn	2, 0x0040
 330:	1148                	.insn	2, 0x1148
 332:	0040                	.insn	2, 0x0040
 334:	1178                	.insn	2, 0x1178
 336:	0040                	.insn	2, 0x0040
 338:	1234                	.insn	2, 0x1234
 33a:	0040                	.insn	2, 0x0040
 33c:	1250                	.insn	2, 0x1250
 33e:	0040                	.insn	2, 0x0040
 340:	1270                	.insn	2, 0x1270
 342:	0040                	.insn	2, 0x0040
 344:	1284                	.insn	2, 0x1284
 346:	0040                	.insn	2, 0x0040
 348:	1298                	.insn	2, 0x1298
 34a:	0040                	.insn	2, 0x0040
 34c:	12a4                	.insn	2, 0x12a4
 34e:	0040                	.insn	2, 0x0040
 350:	0000                	.insn	2, 0x0000
 352:	0040                	.insn	2, 0x0040
 354:	0f4c                	.insn	2, 0x0f4c
 356:	0040                	.insn	2, 0x0040
 358:	00e4                	.insn	2, 0x00e4
 35a:	0000                	.insn	2, 0x0000
 35c:	0005                	.insn	2, 0x0005
 35e:	0004                	.insn	2, 0x0004
 360:	004021fb          	.insn	4, 0x004021fb
 364:	0040220b          	.insn	4, 0x0040220b
 368:	217c                	.insn	2, 0x217c
 36a:	0040                	.insn	2, 0x0040
 36c:	2214                	.insn	2, 0x2214
 36e:	0040                	.insn	2, 0x0040
 370:	1f19                	.insn	2, 0x1f19
 372:	0040                	.insn	2, 0x0040
 374:	221f 0040 222c      	.insn	6, 0x222c0040221f
 37a:	0040                	.insn	2, 0x0040
 37c:	12b0                	.insn	2, 0x12b0
 37e:	0040                	.insn	2, 0x0040
 380:	130c                	.insn	2, 0x130c
 382:	0040                	.insn	2, 0x0040
 384:	1344                	.insn	2, 0x1344
 386:	0040                	.insn	2, 0x0040
 388:	12cc                	.insn	2, 0x12cc
 38a:	0040                	.insn	2, 0x0040
 38c:	12ec                	.insn	2, 0x12ec
 38e:	0040                	.insn	2, 0x0040
 390:	1300                	.insn	2, 0x1300
 392:	0040                	.insn	2, 0x0040
 394:	1334                	.insn	2, 0x1334
 396:	0040                	.insn	2, 0x0040
 398:	1370                	.insn	2, 0x1370
 39a:	0040                	.insn	2, 0x0040
 39c:	1384                	.insn	2, 0x1384
 39e:	0040                	.insn	2, 0x0040
 3a0:	139c                	.insn	2, 0x139c
 3a2:	0040                	.insn	2, 0x0040
 3a4:	13c4                	.insn	2, 0x13c4
 3a6:	0040                	.insn	2, 0x0040
 3a8:	1400                	.insn	2, 0x1400
 3aa:	0040                	.insn	2, 0x0040
 3ac:	1458                	.insn	2, 0x1458
 3ae:	0040                	.insn	2, 0x0040
 3b0:	14b4                	.insn	2, 0x14b4
 3b2:	0040                	.insn	2, 0x0040
 3b4:	1534                	.insn	2, 0x1534
 3b6:	0040                	.insn	2, 0x0040
 3b8:	169c                	.insn	2, 0x169c
 3ba:	0040                	.insn	2, 0x0040
 3bc:	14a0                	.insn	2, 0x14a0
 3be:	0040                	.insn	2, 0x0040
 3c0:	14d4                	.insn	2, 0x14d4
 3c2:	0040                	.insn	2, 0x0040
 3c4:	1558                	.insn	2, 0x1558
 3c6:	0040                	.insn	2, 0x0040
 3c8:	16f8                	.insn	2, 0x16f8
 3ca:	0040                	.insn	2, 0x0040
 3cc:	1718                	.insn	2, 0x1718
 3ce:	0040                	.insn	2, 0x0040
 3d0:	175c                	.insn	2, 0x175c
 3d2:	0040                	.insn	2, 0x0040
 3d4:	17dc                	.insn	2, 0x17dc
 3d6:	0040                	.insn	2, 0x0040
 3d8:	174c                	.insn	2, 0x174c
 3da:	0040                	.insn	2, 0x0040
 3dc:	177c                	.insn	2, 0x177c
 3de:	0040                	.insn	2, 0x0040
 3e0:	1824                	.insn	2, 0x1824
 3e2:	0040                	.insn	2, 0x0040
 3e4:	1894                	.insn	2, 0x1894
 3e6:	0040                	.insn	2, 0x0040
 3e8:	18a4                	.insn	2, 0x18a4
 3ea:	0040                	.insn	2, 0x0040
 3ec:	18b4                	.insn	2, 0x18b4
 3ee:	0040                	.insn	2, 0x0040
 3f0:	18c4                	.insn	2, 0x18c4
 3f2:	0040                	.insn	2, 0x0040
 3f4:	18d4                	.insn	2, 0x18d4
 3f6:	0040                	.insn	2, 0x0040
 3f8:	18e4                	.insn	2, 0x18e4
 3fa:	0040                	.insn	2, 0x0040
 3fc:	18f4                	.insn	2, 0x18f4
 3fe:	0040                	.insn	2, 0x0040
 400:	1904                	.insn	2, 0x1904
 402:	0040                	.insn	2, 0x0040
 404:	1918                	.insn	2, 0x1918
 406:	0040                	.insn	2, 0x0040
 408:	1938                	.insn	2, 0x1938
 40a:	0040                	.insn	2, 0x0040
 40c:	1948                	.insn	2, 0x1948
 40e:	0040                	.insn	2, 0x0040
 410:	1984                	.insn	2, 0x1984
 412:	0040                	.insn	2, 0x0040
 414:	1994                	.insn	2, 0x1994
 416:	0040                	.insn	2, 0x0040
 418:	19a0                	.insn	2, 0x19a0
 41a:	0040                	.insn	2, 0x0040
 41c:	19dc                	.insn	2, 0x19dc
 41e:	0040                	.insn	2, 0x0040
 420:	1a0c                	.insn	2, 0x1a0c
 422:	0040                	.insn	2, 0x0040
 424:	1ae4                	.insn	2, 0x1ae4
 426:	0040                	.insn	2, 0x0040
 428:	19c8                	.insn	2, 0x19c8
 42a:	0040                	.insn	2, 0x0040
 42c:	1a04                	.insn	2, 0x1a04
 42e:	0040                	.insn	2, 0x0040
 430:	1ce8                	.insn	2, 0x1ce8
 432:	0040                	.insn	2, 0x0040
 434:	1cf8                	.insn	2, 0x1cf8
 436:	0040                	.insn	2, 0x0040
 438:	1d08                	.insn	2, 0x1d08
 43a:	0040                	.insn	2, 0x0040
 43c:	1d28                	.insn	2, 0x1d28
 43e:	0040                	.insn	2, 0x0040

Disassembly of section .comment:

00000000 <.comment>:
   0:	6255                	.insn	2, 0x6255
   2:	6e75                	.insn	2, 0x6e75
   4:	7574                	.insn	2, 0x7574
   6:	6320                	.insn	2, 0x6320
   8:	616c                	.insn	2, 0x616c
   a:	676e                	.insn	2, 0x676e
   c:	7620                	.insn	2, 0x7620
   e:	7265                	.insn	2, 0x7265
  10:	6e6f6973          	csrrsi	s2,0x6e6,30
  14:	3220                	.insn	2, 0x3220
  16:	2e31                	.insn	2, 0x2e31
  18:	2e31                	.insn	2, 0x2e31
  1a:	2038                	.insn	2, 0x2038
  1c:	3628                	.insn	2, 0x3628
  1e:	6275                	.insn	2, 0x6275
  20:	6e75                	.insn	2, 0x6e75
  22:	7574                	.insn	2, 0x7574
  24:	2931                	.insn	2, 0x2931
	...

Disassembly of section .riscv.attributes:

00000000 <.riscv.attributes>:
   0:	3e41                	.insn	2, 0x3e41
   2:	0000                	.insn	2, 0x0000
   4:	7200                	.insn	2, 0x7200
   6:	7369                	.insn	2, 0x7369
   8:	01007663          	bgeu	zero,a6,14 <start-0x3fffec>
   c:	0034                	.insn	2, 0x0034
   e:	0000                	.insn	2, 0x0000
  10:	1004                	.insn	2, 0x1004
  12:	7205                	.insn	2, 0x7205
  14:	3376                	.insn	2, 0x3376
  16:	6932                	.insn	2, 0x6932
  18:	7032                	.insn	2, 0x7032
  1a:	5f31                	.insn	2, 0x5f31
  1c:	326d                	.insn	2, 0x326d
  1e:	3070                	.insn	2, 0x3070
  20:	7a5f 6369 7273      	.insn	6, 0x727363697a5f
  26:	7032                	.insn	2, 0x7032
  28:	5f30                	.insn	2, 0x5f30
  2a:	697a                	.insn	2, 0x697a
  2c:	6566                	.insn	2, 0x6566
  2e:	636e                	.insn	2, 0x636e
  30:	6965                	.insn	2, 0x6965
  32:	7032                	.insn	2, 0x7032
  34:	5f30                	.insn	2, 0x5f30
  36:	6d7a                	.insn	2, 0x6d7a
  38:	756d                	.insn	2, 0x756d
  3a:	316c                	.insn	2, 0x316c
  3c:	3070                	.insn	2, 0x3070
	...

Disassembly of section .debug_frame:

00000000 <.debug_frame>:
   0:	0010                	.insn	2, 0x0010
   2:	0000                	.insn	2, 0x0000
   4:	ffff                	.insn	2, 0xffff
   6:	ffff                	.insn	2, 0xffff
   8:	0004                	.insn	2, 0x0004
   a:	0004                	.insn	2, 0x0004
   c:	7c01                	.insn	2, 0x7c01
   e:	0c01                	.insn	2, 0x0c01
  10:	0002                	.insn	2, 0x0002
  12:	0000                	.insn	2, 0x0000
  14:	002c                	.insn	2, 0x002c
  16:	0000                	.insn	2, 0x0000
  18:	0000                	.insn	2, 0x0000
  1a:	0000                	.insn	2, 0x0000
  1c:	001c                	.insn	2, 0x001c
  1e:	0040                	.insn	2, 0x0040
  20:	0894                	.insn	2, 0x0894
  22:	0000                	.insn	2, 0x0000
  24:	0e44                	.insn	2, 0x0e44
  26:	0180                	.insn	2, 0x0180
  28:	8174                	.insn	2, 0x8174
  2a:	8801                	.insn	2, 0x8801
  2c:	8902                	.insn	2, 0x8902
  2e:	93049203          	lh	tp,-1744(s1)
  32:	9405                	.insn	2, 0x9405
  34:	9506                	.insn	2, 0x9506
  36:	97089607          	.insn	4, 0x97089607
  3a:	9809                	.insn	2, 0x9809
  3c:	990a                	.insn	2, 0x990a
  3e:	9b0c9a0b          	.insn	4, 0x9b0c9a0b
  42:	000d                	.insn	2, 0x000d
  44:	000c                	.insn	2, 0x000c
  46:	0000                	.insn	2, 0x0000
  48:	0000                	.insn	2, 0x0000
  4a:	0000                	.insn	2, 0x0000
  4c:	08b0                	.insn	2, 0x08b0
  4e:	0040                	.insn	2, 0x0040
  50:	00c4                	.insn	2, 0x00c4
  52:	0000                	.insn	2, 0x0000
  54:	0024                	.insn	2, 0x0024
  56:	0000                	.insn	2, 0x0000
  58:	0000                	.insn	2, 0x0000
  5a:	0000                	.insn	2, 0x0000
  5c:	0974                	.insn	2, 0x0974
  5e:	0040                	.insn	2, 0x0040
  60:	00bc                	.insn	2, 0x00bc
  62:	0000                	.insn	2, 0x0000
  64:	0e44                	.insn	2, 0x0e44
  66:	5420                	.insn	2, 0x5420
  68:	0181                	.insn	2, 0x0181
  6a:	0288                	.insn	2, 0x0288
  6c:	0389                	.insn	2, 0x0389
  6e:	0492                	.insn	2, 0x0492
  70:	98020593          	addi	a1,tp,-1664 # 2f24c <start-0x3d0db4>
  74:	c8c1                	.insn	2, 0xc8c1
  76:	d2c9                	.insn	2, 0xd2c9
  78:	000e44d3          	.insn	4, 0x000e44d3
  7c:	0010                	.insn	2, 0x0010
  7e:	0000                	.insn	2, 0x0000
  80:	ffff                	.insn	2, 0xffff
  82:	ffff                	.insn	2, 0xffff
  84:	0004                	.insn	2, 0x0004
  86:	0004                	.insn	2, 0x0004
  88:	7c01                	.insn	2, 0x7c01
  8a:	0c01                	.insn	2, 0x0c01
  8c:	0002                	.insn	2, 0x0002
  8e:	0000                	.insn	2, 0x0000
  90:	000c                	.insn	2, 0x000c
  92:	0000                	.insn	2, 0x0000
  94:	007c                	.insn	2, 0x007c
  96:	0000                	.insn	2, 0x0000
  98:	0a30                	.insn	2, 0x0a30
  9a:	0040                	.insn	2, 0x0040
  9c:	0018                	.insn	2, 0x0018
  9e:	0000                	.insn	2, 0x0000
  a0:	0018                	.insn	2, 0x0018
  a2:	0000                	.insn	2, 0x0000
  a4:	007c                	.insn	2, 0x007c
  a6:	0000                	.insn	2, 0x0000
  a8:	0a48                	.insn	2, 0x0a48
  aa:	0040                	.insn	2, 0x0040
  ac:	0264                	.insn	2, 0x0264
  ae:	0000                	.insn	2, 0x0000
  b0:	0e5c                	.insn	2, 0x0e5c
  b2:	0c90                	.insn	2, 0x0c90
  b4:	0e023403          	.insn	4, 0x0e023403
  b8:	0000                	.insn	2, 0x0000
  ba:	0000                	.insn	2, 0x0000
  bc:	0024                	.insn	2, 0x0024
  be:	0000                	.insn	2, 0x0000
  c0:	007c                	.insn	2, 0x007c
  c2:	0000                	.insn	2, 0x0000
  c4:	0cac                	.insn	2, 0x0cac
  c6:	0040                	.insn	2, 0x0040
  c8:	02b8                	.insn	2, 0x02b8
  ca:	0000                	.insn	2, 0x0000
  cc:	0e44                	.insn	2, 0x0e44
  ce:	5040                	.insn	2, 0x5040
  d0:	0988                	.insn	2, 0x0988
  d2:	0a89                	.insn	2, 0x0a89
  d4:	0b92                	.insn	2, 0x0b92
  d6:	9c030c93          	addi	s9,t1,-1600
  da:	c802                	.insn	2, 0xc802
  dc:	d2c9                	.insn	2, 0xd2c9
  de:	000e44d3          	.insn	4, 0x000e44d3
  e2:	0000                	.insn	2, 0x0000
  e4:	000c                	.insn	2, 0x000c
  e6:	0000                	.insn	2, 0x0000
  e8:	007c                	.insn	2, 0x007c
  ea:	0000                	.insn	2, 0x0000
  ec:	0f64                	.insn	2, 0x0f64
  ee:	0040                	.insn	2, 0x0040
  f0:	0014                	.insn	2, 0x0014
  f2:	0000                	.insn	2, 0x0000
  f4:	000c                	.insn	2, 0x000c
  f6:	0000                	.insn	2, 0x0000
  f8:	007c                	.insn	2, 0x007c
  fa:	0000                	.insn	2, 0x0000
  fc:	0f78                	.insn	2, 0x0f78
  fe:	0040                	.insn	2, 0x0040
 100:	0014                	.insn	2, 0x0014
 102:	0000                	.insn	2, 0x0000
 104:	000c                	.insn	2, 0x000c
 106:	0000                	.insn	2, 0x0000
 108:	007c                	.insn	2, 0x007c
 10a:	0000                	.insn	2, 0x0000
 10c:	0f8c                	.insn	2, 0x0f8c
 10e:	0040                	.insn	2, 0x0040
 110:	000c                	.insn	2, 0x000c
 112:	0000                	.insn	2, 0x0000
 114:	0024                	.insn	2, 0x0024
 116:	0000                	.insn	2, 0x0000
 118:	007c                	.insn	2, 0x007c
 11a:	0000                	.insn	2, 0x0000
 11c:	0f98                	.insn	2, 0x0f98
 11e:	0040                	.insn	2, 0x0040
 120:	00ac                	.insn	2, 0x00ac
 122:	0000                	.insn	2, 0x0000
 124:	0e44                	.insn	2, 0x0e44
 126:	4c20                	.insn	2, 0x4c20
 128:	0181                	.insn	2, 0x0181
 12a:	0288                	.insn	2, 0x0288
 12c:	0389                	.insn	2, 0x0389
 12e:	020a                	.insn	2, 0x020a
 130:	c158                	.insn	2, 0xc158
 132:	c9c8                	.insn	2, 0xc9c8
 134:	0e44                	.insn	2, 0x0e44
 136:	4400                	.insn	2, 0x4400
 138:	0000000b          	.insn	4, 0x000b
 13c:	000c                	.insn	2, 0x000c
 13e:	0000                	.insn	2, 0x0000
 140:	007c                	.insn	2, 0x007c
 142:	0000                	.insn	2, 0x0000
 144:	1044                	.insn	2, 0x1044
 146:	0040                	.insn	2, 0x0040
 148:	000c                	.insn	2, 0x000c
 14a:	0000                	.insn	2, 0x0000
 14c:	000c                	.insn	2, 0x000c
 14e:	0000                	.insn	2, 0x0000
 150:	007c                	.insn	2, 0x007c
 152:	0000                	.insn	2, 0x0000
 154:	1050                	.insn	2, 0x1050
 156:	0040                	.insn	2, 0x0040
 158:	000c                	.insn	2, 0x000c
 15a:	0000                	.insn	2, 0x0000
 15c:	000c                	.insn	2, 0x000c
 15e:	0000                	.insn	2, 0x0000
 160:	007c                	.insn	2, 0x007c
 162:	0000                	.insn	2, 0x0000
 164:	105c                	.insn	2, 0x105c
 166:	0040                	.insn	2, 0x0040
 168:	000c                	.insn	2, 0x000c
 16a:	0000                	.insn	2, 0x0000
 16c:	000c                	.insn	2, 0x000c
 16e:	0000                	.insn	2, 0x0000
 170:	007c                	.insn	2, 0x007c
 172:	0000                	.insn	2, 0x0000
 174:	1068                	.insn	2, 0x1068
 176:	0040                	.insn	2, 0x0040
 178:	000c                	.insn	2, 0x000c
 17a:	0000                	.insn	2, 0x0000
 17c:	0020                	.insn	2, 0x0020
 17e:	0000                	.insn	2, 0x0000
 180:	007c                	.insn	2, 0x007c
 182:	0000                	.insn	2, 0x0000
 184:	1074                	.insn	2, 0x1074
 186:	0040                	.insn	2, 0x0040
 188:	0084                	.insn	2, 0x0084
 18a:	0000                	.insn	2, 0x0000
 18c:	0e44                	.insn	2, 0x0e44
 18e:	4410                	.insn	2, 0x4410
 190:	0181                	.insn	2, 0x0181
 192:	020a                	.insn	2, 0x020a
 194:	c158                	.insn	2, 0xc158
 196:	0e44                	.insn	2, 0x0e44
 198:	4800                	.insn	2, 0x4800
 19a:	44c14c0b          	.insn	4, 0x44c14c0b
 19e:	000e                	.insn	2, 0x000e
 1a0:	000c                	.insn	2, 0x000c
 1a2:	0000                	.insn	2, 0x0000
 1a4:	007c                	.insn	2, 0x007c
 1a6:	0000                	.insn	2, 0x0000
 1a8:	10f8                	.insn	2, 0x10f8
 1aa:	0040                	.insn	2, 0x0040
 1ac:	0010                	.insn	2, 0x0010
 1ae:	0000                	.insn	2, 0x0000
 1b0:	000c                	.insn	2, 0x000c
 1b2:	0000                	.insn	2, 0x0000
 1b4:	007c                	.insn	2, 0x007c
 1b6:	0000                	.insn	2, 0x0000
 1b8:	1108                	.insn	2, 0x1108
 1ba:	0040                	.insn	2, 0x0040
 1bc:	000c                	.insn	2, 0x000c
 1be:	0000                	.insn	2, 0x0000
 1c0:	000c                	.insn	2, 0x000c
 1c2:	0000                	.insn	2, 0x0000
 1c4:	007c                	.insn	2, 0x007c
 1c6:	0000                	.insn	2, 0x0000
 1c8:	1114                	.insn	2, 0x1114
 1ca:	0040                	.insn	2, 0x0040
 1cc:	0034                	.insn	2, 0x0034
 1ce:	0000                	.insn	2, 0x0000
 1d0:	000c                	.insn	2, 0x000c
 1d2:	0000                	.insn	2, 0x0000
 1d4:	007c                	.insn	2, 0x007c
 1d6:	0000                	.insn	2, 0x0000
 1d8:	1148                	.insn	2, 0x1148
 1da:	0040                	.insn	2, 0x0040
 1dc:	0030                	.insn	2, 0x0030
 1de:	0000                	.insn	2, 0x0000
 1e0:	000c                	.insn	2, 0x000c
 1e2:	0000                	.insn	2, 0x0000
 1e4:	007c                	.insn	2, 0x007c
 1e6:	0000                	.insn	2, 0x0000
 1e8:	1178                	.insn	2, 0x1178
 1ea:	0040                	.insn	2, 0x0040
 1ec:	00bc                	.insn	2, 0x00bc
 1ee:	0000                	.insn	2, 0x0000
 1f0:	000c                	.insn	2, 0x000c
 1f2:	0000                	.insn	2, 0x0000
 1f4:	007c                	.insn	2, 0x007c
 1f6:	0000                	.insn	2, 0x0000
 1f8:	1234                	.insn	2, 0x1234
 1fa:	0040                	.insn	2, 0x0040
 1fc:	003c                	.insn	2, 0x003c
 1fe:	0000                	.insn	2, 0x0000
 200:	000c                	.insn	2, 0x000c
 202:	0000                	.insn	2, 0x0000
 204:	007c                	.insn	2, 0x007c
 206:	0000                	.insn	2, 0x0000
 208:	1270                	.insn	2, 0x1270
 20a:	0040                	.insn	2, 0x0040
 20c:	0014                	.insn	2, 0x0014
 20e:	0000                	.insn	2, 0x0000
 210:	000c                	.insn	2, 0x000c
 212:	0000                	.insn	2, 0x0000
 214:	007c                	.insn	2, 0x007c
 216:	0000                	.insn	2, 0x0000
 218:	1284                	.insn	2, 0x1284
 21a:	0040                	.insn	2, 0x0040
 21c:	0014                	.insn	2, 0x0014
 21e:	0000                	.insn	2, 0x0000
 220:	000c                	.insn	2, 0x000c
 222:	0000                	.insn	2, 0x0000
 224:	007c                	.insn	2, 0x007c
 226:	0000                	.insn	2, 0x0000
 228:	1298                	.insn	2, 0x1298
 22a:	0040                	.insn	2, 0x0040
 22c:	000c                	.insn	2, 0x000c
 22e:	0000                	.insn	2, 0x0000
 230:	000c                	.insn	2, 0x000c
 232:	0000                	.insn	2, 0x0000
 234:	007c                	.insn	2, 0x007c
 236:	0000                	.insn	2, 0x0000
 238:	12a4                	.insn	2, 0x12a4
 23a:	0040                	.insn	2, 0x0040
 23c:	000c                	.insn	2, 0x000c
 23e:	0000                	.insn	2, 0x0000
 240:	000c                	.insn	2, 0x000c
 242:	0000                	.insn	2, 0x0000
 244:	007c                	.insn	2, 0x007c
 246:	0000                	.insn	2, 0x0000
 248:	0000                	.insn	2, 0x0000
 24a:	0040                	.insn	2, 0x0040
 24c:	001c                	.insn	2, 0x001c
 24e:	0000                	.insn	2, 0x0000
 250:	0010                	.insn	2, 0x0010
 252:	0000                	.insn	2, 0x0000
 254:	ffff                	.insn	2, 0xffff
 256:	ffff                	.insn	2, 0xffff
 258:	0004                	.insn	2, 0x0004
 25a:	0004                	.insn	2, 0x0004
 25c:	7c01                	.insn	2, 0x7c01
 25e:	0c01                	.insn	2, 0x0c01
 260:	0002                	.insn	2, 0x0002
 262:	0000                	.insn	2, 0x0000
 264:	0020                	.insn	2, 0x0020
 266:	0000                	.insn	2, 0x0000
 268:	0250                	.insn	2, 0x0250
 26a:	0000                	.insn	2, 0x0000
 26c:	12b0                	.insn	2, 0x12b0
 26e:	0040                	.insn	2, 0x0040
 270:	00ec                	.insn	2, 0x00ec
 272:	0000                	.insn	2, 0x0000
 274:	0e44                	.insn	2, 0x0e44
 276:	04a0                	.insn	2, 0x04a0
 278:	814c                	.insn	2, 0x814c
 27a:	8801                	.insn	2, 0x8801
 27c:	8902                	.insn	2, 0x8902
 27e:	c1d40203          	lb	tp,-995(s0)
 282:	c9c8                	.insn	2, 0xc9c8
 284:	0e44                	.insn	2, 0x0e44
 286:	0000                	.insn	2, 0x0000
 288:	0024                	.insn	2, 0x0024
 28a:	0000                	.insn	2, 0x0000
 28c:	0250                	.insn	2, 0x0250
 28e:	0000                	.insn	2, 0x0000
 290:	139c                	.insn	2, 0x139c
 292:	0040                	.insn	2, 0x0040
 294:	00bc                	.insn	2, 0x00bc
 296:	0000                	.insn	2, 0x0000
 298:	0e44                	.insn	2, 0x0e44
 29a:	5010                	.insn	2, 0x5010
 29c:	0181                	.insn	2, 0x0181
 29e:	0288                	.insn	2, 0x0288
 2a0:	0389                	.insn	2, 0x0389
 2a2:	0492                	.insn	2, 0x0492
 2a4:	a002                	.insn	2, 0xa002
 2a6:	c8c1                	.insn	2, 0xc8c1
 2a8:	d2c9                	.insn	2, 0xd2c9
 2aa:	0e44                	.insn	2, 0x0e44
 2ac:	0000                	.insn	2, 0x0000
 2ae:	0000                	.insn	2, 0x0000
 2b0:	003c                	.insn	2, 0x003c
 2b2:	0000                	.insn	2, 0x0000
 2b4:	0250                	.insn	2, 0x0250
 2b6:	0000                	.insn	2, 0x0000
 2b8:	1458                	.insn	2, 0x1458
 2ba:	0040                	.insn	2, 0x0040
 2bc:	02a0                	.insn	2, 0x02a0
 2be:	0000                	.insn	2, 0x0000
 2c0:	0e44                	.insn	2, 0x0e44
 2c2:	7040                	.insn	2, 0x7040
 2c4:	0181                	.insn	2, 0x0181
 2c6:	0288                	.insn	2, 0x0288
 2c8:	0389                	.insn	2, 0x0389
 2ca:	0492                	.insn	2, 0x0492
 2cc:	06940593          	addi	a1,s0,105
 2d0:	0795                	.insn	2, 0x0795
 2d2:	0896                	.insn	2, 0x0896
 2d4:	0a980997          	auipc	s3,0xa980
 2d8:	0b99                	.insn	2, 0x0b99
 2da:	0c9a                	.insn	2, 0x0c9a
 2dc:	020a                	.insn	2, 0x020a
 2de:	c180                	.insn	2, 0xc180
 2e0:	c9c8                	.insn	2, 0xc9c8
 2e2:	d3d2                	.insn	2, 0xd3d2
 2e4:	d5d4                	.insn	2, 0xd5d4
 2e6:	d7d6                	.insn	2, 0xd7d6
 2e8:	d9d8                	.insn	2, 0xd9d8
 2ea:	44da                	.insn	2, 0x44da
 2ec:	000e                	.insn	2, 0x000e
 2ee:	0b44                	.insn	2, 0x0b44
 2f0:	000c                	.insn	2, 0x000c
 2f2:	0000                	.insn	2, 0x0000
 2f4:	0250                	.insn	2, 0x0250
 2f6:	0000                	.insn	2, 0x0000
 2f8:	16f8                	.insn	2, 0x16f8
 2fa:	0040                	.insn	2, 0x0040
 2fc:	0020                	.insn	2, 0x0020
 2fe:	0000                	.insn	2, 0x0000
 300:	0038                	.insn	2, 0x0038
 302:	0000                	.insn	2, 0x0000
 304:	0250                	.insn	2, 0x0250
 306:	0000                	.insn	2, 0x0000
 308:	1718                	.insn	2, 0x1718
 30a:	0040                	.insn	2, 0x0040
 30c:	0288                	.insn	2, 0x0288
 30e:	0000                	.insn	2, 0x0000
 310:	0e44                	.insn	2, 0x0e44
 312:	6830                	.insn	2, 0x6830
 314:	0181                	.insn	2, 0x0181
 316:	0288                	.insn	2, 0x0288
 318:	0389                	.insn	2, 0x0389
 31a:	0492                	.insn	2, 0x0492
 31c:	06940593          	addi	a1,s0,105
 320:	0795                	.insn	2, 0x0795
 322:	0896                	.insn	2, 0x0896
 324:	0a980997          	auipc	s3,0xa980
 328:	020a                	.insn	2, 0x020a
 32a:	c164                	.insn	2, 0xc164
 32c:	c9c8                	.insn	2, 0xc9c8
 32e:	d3d2                	.insn	2, 0xd3d2
 330:	d5d4                	.insn	2, 0xd5d4
 332:	d7d6                	.insn	2, 0xd7d6
 334:	44d8                	.insn	2, 0x44d8
 336:	000e                	.insn	2, 0x000e
 338:	0b44                	.insn	2, 0x0b44
 33a:	0000                	.insn	2, 0x0000
 33c:	0028                	.insn	2, 0x0028
 33e:	0000                	.insn	2, 0x0000
 340:	0250                	.insn	2, 0x0250
 342:	0000                	.insn	2, 0x0000
 344:	19a0                	.insn	2, 0x19a0
 346:	0040                	.insn	2, 0x0040
 348:	03b0                	.insn	2, 0x03b0
 34a:	0000                	.insn	2, 0x0000
 34c:	0e44                	.insn	2, 0x0e44
 34e:	5830                	.insn	2, 0x5830
 350:	0181                	.insn	2, 0x0181
 352:	0288                	.insn	2, 0x0288
 354:	0389                	.insn	2, 0x0389
 356:	0492                	.insn	2, 0x0492
 358:	06940593          	addi	a1,s0,105
 35c:	c1038c03          	lb	s8,-1008(t2)
 360:	c9c8                	.insn	2, 0xc9c8
 362:	d3d2                	.insn	2, 0xd3d2
 364:	44d4                	.insn	2, 0x44d4
 366:	000e                	.insn	2, 0x000e

Disassembly of section .debug_line:

00000000 <.debug_line>:
       0:	000006f3          	.insn	4, 0x06f3
       4:	0005                	.insn	2, 0x0005
       6:	0004                	.insn	2, 0x0004
       8:	007a                	.insn	2, 0x007a
       a:	0000                	.insn	2, 0x0000
       c:	0101                	.insn	2, 0x0101
       e:	fb01                	.insn	2, 0xfb01
      10:	0d0e                	.insn	2, 0x0d0e
      12:	0100                	.insn	2, 0x0100
      14:	0101                	.insn	2, 0x0101
      16:	0001                	.insn	2, 0x0001
      18:	0000                	.insn	2, 0x0000
      1a:	0001                	.insn	2, 0x0001
      1c:	0100                	.insn	2, 0x0100
      1e:	0101                	.insn	2, 0x0101
      20:	021f 0000 0000      	.insn	6, 0x021f
      26:	0035                	.insn	2, 0x0035
      28:	0000                	.insn	2, 0x0000
      2a:	021f0103          	lb	sp,33(t5)
      2e:	041e050f          	.insn	4, 0x041e050f
      32:	0000003b          	.insn	4, 0x003b
      36:	c300                	.insn	2, 0xc300
      38:	bff98aa7          	.insn	4, 0xbff98aa7
      3c:	ebc9                	.insn	2, 0xebc9
      3e:	597a                	.insn	2, 0x597a
      40:	33b8                	.insn	2, 0x33b8
      42:	0f6a                	.insn	2, 0x0f6a
      44:	e07c                	.insn	2, 0xe07c
      46:	3f45                	.insn	2, 0x3f45
      48:	0000                	.insn	2, 0x0000
      4a:	0100                	.insn	2, 0x0100
      4c:	f98aa7c3          	.insn	4, 0xf98aa7c3
      50:	7aebc9bf 6a33b859 	.insn	8, 0x6a33b8597aebc9bf
      58:	45e07c0f          	.insn	4, 0x45e07c0f
      5c:	00000047          	.insn	4, 0x0047
      60:	3701                	.insn	2, 0x3701
      62:	0bd2                	.insn	2, 0x0bd2
      64:	88f9524b          	.insn	4, 0x88f9524b
      68:	a3c4                	.insn	2, 0xa3c4
      6a:	2a19                	.insn	2, 0x2a19
      6c:	f27f                	.insn	2, 0xf27f
      6e:	4e87d623          	.insn	4, 0x4e87d623
      72:	0000                	.insn	2, 0x0000
      74:	0100                	.insn	2, 0x0100
      76:	8925                	.insn	2, 0x8925
      78:	ef25                	.insn	2, 0xef25
      7a:	9699                	.insn	2, 0x9699
      7c:	84d0                	.insn	2, 0x84d0
      7e:	8c71                	.insn	2, 0x8c71
      80:	b17c                	.insn	2, 0xb17c
      82:	b91c                	.insn	2, 0xb91c
      84:	0500e2fb          	.insn	4, 0x0500e2fb
      88:	1c02                	.insn	2, 0x1c02
      8a:	4000                	.insn	2, 0x4000
      8c:	1600                	.insn	2, 0x1600
      8e:	0505                	.insn	2, 0x0505
      90:	020a                	.insn	2, 0x020a
      92:	1638                	.insn	2, 0x1638
      94:	06c1                	.insn	2, 0x06c1
      96:	05f27003          	.insn	4, 0x05f27003
      9a:	060d                	.insn	2, 0x060d
      9c:	02019203          	lh	tp,32(gp) # 20 <start-0x3fffe0>
      a0:	0140                	.insn	2, 0x0140
      a2:	0306                	.insn	2, 0x0306
      a4:	7eee                	.insn	2, 0x7eee
      a6:	05f2                	.insn	2, 0x05f2
      a8:	0609                	.insn	2, 0x0609
      aa:	054a1e03          	lh	t3,84(s4) # 30830 <start-0x3cf7d0>
      ae:	0618                	.insn	2, 0x0618
      b0:	05ba                	.insn	2, 0x05ba
      b2:	ba26                	.insn	2, 0xba26
      b4:	3405                	.insn	2, 0x3405
      b6:	05ba                	.insn	2, 0x05ba
      b8:	ba42                	.insn	2, 0xba42
      ba:	0905                	.insn	2, 0x0905
      bc:	bc06                	.insn	2, 0xbc06
      be:	bbbbbbbb          	.insn	4, 0xbbbbbbbb
      c2:	bcbbbbbb          	.insn	4, 0xbcbbbbbb
      c6:	1805                	.insn	2, 0x1805
      c8:	ba06                	.insn	2, 0xba06
      ca:	2605                	.insn	2, 0x2605
      cc:	03ba                	.insn	2, 0x03ba
      ce:	1905ba57          	.insn	4, 0x1905ba57
      d2:	0306                	.insn	2, 0x0306
      d4:	00d5                	.insn	2, 0x00d5
      d6:	ac08                	.insn	2, 0xac08
      d8:	0306                	.insn	2, 0x0306
      da:	04097fab          	.insn	4, 0x04097fab
      de:	0100                	.insn	2, 0x0100
      e0:	0306                	.insn	2, 0x0306
      e2:	00d6                	.insn	2, 0x00d6
      e4:	054a                	.insn	2, 0x054a
      e6:	095f031b          	.insn	4, 0x095f031b
      ea:	0004                	.insn	2, 0x0004
      ec:	0501                	.insn	2, 0x0501
      ee:	842a                	.insn	2, 0x842a
      f0:	1b05                	.insn	2, 0x1b05
      f2:	0548                	.insn	2, 0x0548
      f4:	4f11                	.insn	2, 0x4f11
      f6:	0005                	.insn	2, 0x0005
      f8:	0306                	.insn	2, 0x0306
      fa:	0946                	.insn	2, 0x0946
      fc:	0004                	.insn	2, 0x0004
      fe:	0501                	.insn	2, 0x0501
     100:	0311                	.insn	2, 0x0311
     102:	4a3a                	.insn	2, 0x4a3a
     104:	0306                	.insn	2, 0x0306
     106:	0901                	.insn	2, 0x0901
     108:	0004                	.insn	2, 0x0004
     10a:	0501                	.insn	2, 0x0501
     10c:	0600                	.insn	2, 0x0600
     10e:	05ba4503          	lbu	a0,91(s4)
     112:	0611                	.insn	2, 0x0611
     114:	03f23f03          	.insn	4, 0x03f23f03
     118:	0901                	.insn	2, 0x0901
     11a:	0004                	.insn	2, 0x0004
     11c:	0501                	.insn	2, 0x0501
     11e:	0316                	.insn	2, 0x0316
     120:	ba09                	.insn	2, 0xba09
     122:	0306                	.insn	2, 0x0306
     124:	05827fb7          	lui	t6,0x5827
     128:	0614                	.insn	2, 0x0614
     12a:	4a00cb03          	lbu	s6,1184(ra) # 4a0 <start-0x3ffb60>
     12e:	1c05                	.insn	2, 0x1c05
     130:	04090503          	lb	a0,64(s2)
     134:	0100                	.insn	2, 0x0100
     136:	1905                	.insn	2, 0x1905
     138:	08090503          	lb	a0,128(s2)
     13c:	0100                	.insn	2, 0x0100
     13e:	0306                	.insn	2, 0x0306
     140:	18097fab          	.insn	4, 0x18097fab
     144:	0100                	.insn	2, 0x0100
     146:	1505                	.insn	2, 0x1505
     148:	0306                	.insn	2, 0x0306
     14a:	00ee                	.insn	2, 0x00ee
     14c:	0c09                	.insn	2, 0x0c09
     14e:	0100                	.insn	2, 0x0100
     150:	0d05                	.insn	2, 0x0d05
     152:	08090603          	lb	a2,128(s2)
     156:	0100                	.insn	2, 0x0100
     158:	1805                	.insn	2, 0x1805
     15a:	8206                	.insn	2, 0x8206
     15c:	1c05                	.insn	2, 0x1c05
     15e:	054a                	.insn	2, 0x054a
     160:	0609                	.insn	2, 0x0609
     162:	054c                	.insn	2, 0x054c
     164:	0318                	.insn	2, 0x0318
     166:	4a61                	.insn	2, 0x4a61
     168:	1505                	.insn	2, 0x1505
     16a:	bb4d                	.insn	2, 0xbb4d
     16c:	0306                	.insn	2, 0x0306
     16e:	7fa5                	.insn	2, 0x7fa5
     170:	05ba                	.insn	2, 0x05ba
     172:	0611                	.insn	2, 0x0611
     174:	4a00dd03          	lhu	s10,1184(ra)
     178:	bb51                	.insn	2, 0xbb51
     17a:	1e05                	.insn	2, 0x1e05
     17c:	8206                	.insn	2, 0x8206
     17e:	097f9b03          	lh	s6,151(t6) # 5827097 <USER_MAX+0x5327097>
     182:	0008                	.insn	2, 0x0008
     184:	0501                	.insn	2, 0x0501
     186:	062a                	.insn	2, 0x062a
     188:	82018203          	lb	tp,-2016(gp)
     18c:	1005                	.insn	2, 0x1005
     18e:	064a                	.insn	2, 0x064a
     190:	097efe03          	.insn	4, 0x097efe03
     194:	0008                	.insn	2, 0x0008
     196:	0501                	.insn	2, 0x0501
     198:	0616                	.insn	2, 0x0616
     19a:	09018503          	lb	a0,144(gp)
     19e:	001c                	.insn	2, 0x001c
     1a0:	0501                	.insn	2, 0x0501
     1a2:	060d                	.insn	2, 0x060d
     1a4:	054a                	.insn	2, 0x054a
     1a6:	821a                	.insn	2, 0x821a
     1a8:	0d05                	.insn	2, 0x0d05
     1aa:	4c06                	.insn	2, 0x4c06
     1ac:	1405                	.insn	2, 0x1405
     1ae:	4a06                	.insn	2, 0x4a06
     1b0:	1705                	.insn	2, 0x1705
     1b2:	054a                	.insn	2, 0x054a
     1b4:	0334                	.insn	2, 0x0334
     1b6:	0900                	.insn	2, 0x0900
     1b8:	000c                	.insn	2, 0x000c
     1ba:	0501                	.insn	2, 0x0501
     1bc:	4a0d                	.insn	2, 0x4a0d
     1be:	1405                	.insn	2, 0x1405
     1c0:	054a                	.insn	2, 0x054a
     1c2:	12054a17          	auipc	s4,0x12054
     1c6:	0306                	.insn	2, 0x0306
     1c8:	00080903          	lb	s2,0(a6)
     1cc:	0501                	.insn	2, 0x0501
     1ce:	0600                	.insn	2, 0x0600
     1d0:	827ef603          	.insn	4, 0x827ef603
     1d4:	1405                	.insn	2, 0x1405
     1d6:	0306                	.insn	2, 0x0306
     1d8:	054a018b          	.insn	4, 0x054a018b
     1dc:	061e                	.insn	2, 0x061e
     1de:	054a                	.insn	2, 0x054a
     1e0:	0609                	.insn	2, 0x0609
     1e2:	08097903          	.insn	4, 0x08097903
     1e6:	0100                	.insn	2, 0x0100
     1e8:	1405                	.insn	2, 0x1405
     1ea:	08090d03          	lb	s10,128(s2)
     1ee:	0100                	.insn	2, 0x0100
     1f0:	0d05                	.insn	2, 0x0d05
     1f2:	8206                	.insn	2, 0x8206
     1f4:	2605                	.insn	2, 0x2605
     1f6:	05f2                	.insn	2, 0x05f2
     1f8:	0614                	.insn	2, 0x0614
     1fa:	04090403          	lb	s0,64(s2)
     1fe:	0100                	.insn	2, 0x0100
     200:	2c05                	.insn	2, 0x2c05
     202:	0806                	.insn	2, 0x0806
     204:	053c                	.insn	2, 0x053c
     206:	0614                	.insn	2, 0x0614
     208:	04091d03          	lh	s10,64(s2)
     20c:	0100                	.insn	2, 0x0100
     20e:	0306                	.insn	2, 0x0306
     210:	7ece                	.insn	2, 0x7ece
     212:	3c08                	.insn	2, 0x3c08
     214:	2e05                	.insn	2, 0x2e05
     216:	4a01b203          	.insn	4, 0x4a01b203
     21a:	1405                	.insn	2, 0x1405
     21c:	0306                	.insn	2, 0x0306
     21e:	090c                	.insn	2, 0x090c
     220:	0004                	.insn	2, 0x0004
     222:	0501                	.insn	2, 0x0501
     224:	0631                	.insn	2, 0x0631
     226:	3c08                	.insn	2, 0x3c08
     228:	1405                	.insn	2, 0x1405
     22a:	0306                	.insn	2, 0x0306
     22c:	0905                	.insn	2, 0x0905
     22e:	0004                	.insn	2, 0x0004
     230:	0501                	.insn	2, 0x0501
     232:	0630                	.insn	2, 0x0630
     234:	3c08                	.insn	2, 0x3c08
     236:	1405                	.insn	2, 0x1405
     238:	0306                	.insn	2, 0x0306
     23a:	090d                	.insn	2, 0x090d
     23c:	0004                	.insn	2, 0x0004
     23e:	0501                	.insn	2, 0x0501
     240:	0630                	.insn	2, 0x0630
     242:	3c08                	.insn	2, 0x3c08
     244:	1405                	.insn	2, 0x1405
     246:	0306                	.insn	2, 0x0306
     248:	090a                	.insn	2, 0x090a
     24a:	0004                	.insn	2, 0x0004
     24c:	0501                	.insn	2, 0x0501
     24e:	0631                	.insn	2, 0x0631
     250:	3c08                	.insn	2, 0x3c08
     252:	1405                	.insn	2, 0x1405
     254:	0306                	.insn	2, 0x0306
     256:	0004090b          	.insn	4, 0x0004090b
     25a:	0501                	.insn	2, 0x0501
     25c:	3c08062f          	.insn	4, 0x3c08062f
     260:	1405                	.insn	2, 0x1405
     262:	0306                	.insn	2, 0x0306
     264:	090a                	.insn	2, 0x090a
     266:	0004                	.insn	2, 0x0004
     268:	0501                	.insn	2, 0x0501
     26a:	0630                	.insn	2, 0x0630
     26c:	3c08                	.insn	2, 0x3c08
     26e:	1405                	.insn	2, 0x1405
     270:	0306                	.insn	2, 0x0306
     272:	090e                	.insn	2, 0x090e
     274:	0004                	.insn	2, 0x0004
     276:	0501                	.insn	2, 0x0501
     278:	0632                	.insn	2, 0x0632
     27a:	3c08                	.insn	2, 0x3c08
     27c:	1405                	.insn	2, 0x1405
     27e:	0306                	.insn	2, 0x0306
     280:	090e                	.insn	2, 0x090e
     282:	0004                	.insn	2, 0x0004
     284:	0501                	.insn	2, 0x0501
     286:	0630                	.insn	2, 0x0630
     288:	3c08                	.insn	2, 0x3c08
     28a:	1405                	.insn	2, 0x1405
     28c:	0306                	.insn	2, 0x0306
     28e:	0905                	.insn	2, 0x0905
     290:	0004                	.insn	2, 0x0004
     292:	0501                	.insn	2, 0x0501
     294:	0631                	.insn	2, 0x0631
     296:	3c08                	.insn	2, 0x3c08
     298:	1405                	.insn	2, 0x1405
     29a:	0306                	.insn	2, 0x0306
     29c:	090a                	.insn	2, 0x090a
     29e:	0004                	.insn	2, 0x0004
     2a0:	0501                	.insn	2, 0x0501
     2a2:	3c080633          	.insn	4, 0x3c080633
     2a6:	1405                	.insn	2, 0x1405
     2a8:	0306                	.insn	2, 0x0306
     2aa:	090a                	.insn	2, 0x090a
     2ac:	0004                	.insn	2, 0x0004
     2ae:	0501                	.insn	2, 0x0501
     2b0:	062e                	.insn	2, 0x062e
     2b2:	3c08                	.insn	2, 0x3c08
     2b4:	1405                	.insn	2, 0x1405
     2b6:	0306                	.insn	2, 0x0306
     2b8:	0904                	.insn	2, 0x0904
     2ba:	0004                	.insn	2, 0x0004
     2bc:	0501                	.insn	2, 0x0501
     2be:	062c                	.insn	2, 0x062c
     2c0:	3c08                	.insn	2, 0x3c08
     2c2:	1405                	.insn	2, 0x1405
     2c4:	0306                	.insn	2, 0x0306
     2c6:	0004090b          	.insn	4, 0x0004090b
     2ca:	0501                	.insn	2, 0x0501
     2cc:	0631                	.insn	2, 0x0631
     2ce:	3c08                	.insn	2, 0x3c08
     2d0:	1405                	.insn	2, 0x1405
     2d2:	0306                	.insn	2, 0x0306
     2d4:	0901                	.insn	2, 0x0901
     2d6:	0004                	.insn	2, 0x0004
     2d8:	0501                	.insn	2, 0x0501
     2da:	0631                	.insn	2, 0x0631
     2dc:	3c08                	.insn	2, 0x3c08
     2de:	1405                	.insn	2, 0x1405
     2e0:	0306                	.insn	2, 0x0306
     2e2:	0901                	.insn	2, 0x0901
     2e4:	0004                	.insn	2, 0x0004
     2e6:	0501                	.insn	2, 0x0501
     2e8:	0831                	.insn	2, 0x0831
     2ea:	030d053b          	.insn	4, 0x030d053b
     2ee:	0905                	.insn	2, 0x0905
     2f0:	0004                	.insn	2, 0x0004
     2f2:	0601                	.insn	2, 0x0601
     2f4:	087dc703          	lbu	a4,135(s11)
     2f8:	053c                	.insn	2, 0x053c
     2fa:	0616                	.insn	2, 0x0616
     2fc:	82019b03          	lh	s6,-2016(gp)
     300:	1f05                	.insn	2, 0x1f05
     302:	04090103          	lb	sp,64(s2)
     306:	0100                	.insn	2, 0x0100
     308:	0505                	.insn	2, 0x0505
     30a:	4a01b903          	.insn	4, 0x4a01b903
     30e:	0306                	.insn	2, 0x0306
     310:	034a7dab          	.insn	4, 0x034a7dab
     314:	02d5                	.insn	2, 0x02d5
     316:	05ba                	.insn	2, 0x05ba
     318:	4a0c                	.insn	2, 0x4a0c
     31a:	1605                	.insn	2, 0x1605
     31c:	054a                	.insn	2, 0x054a
     31e:	0619                	.insn	2, 0x0619
     320:	10090303          	lb	t1,256(s2)
     324:	0100                	.insn	2, 0x0100
     326:	2505                	.insn	2, 0x2505
     328:	4a06                	.insn	2, 0x4a06
     32a:	0a05                	.insn	2, 0x0a05
     32c:	0306                	.insn	2, 0x0306
     32e:	0901                	.insn	2, 0x0901
     330:	000c                	.insn	2, 0x000c
     332:	0501                	.insn	2, 0x0501
     334:	0609                	.insn	2, 0x0609
     336:	054a                	.insn	2, 0x054a
     338:	0616                	.insn	2, 0x0616
     33a:	097edb03          	lhu	s6,151(t4)
     33e:	0008                	.insn	2, 0x0008
     340:	0501                	.insn	2, 0x0501
     342:	0321                	.insn	2, 0x0321
     344:	0901                	.insn	2, 0x0901
     346:	0004                	.insn	2, 0x0004
     348:	0501                	.insn	2, 0x0501
     34a:	034a0617          	auipc	a2,0x34a0
     34e:	05ba7ecb          	.insn	4, 0x05ba7ecb
     352:	0619                	.insn	2, 0x0619
     354:	ba01b603          	.insn	4, 0xba01b603
     358:	0306                	.insn	2, 0x0306
     35a:	7eca                	.insn	2, 0x7eca
     35c:	0809                	.insn	2, 0x0809
     35e:	0100                	.insn	2, 0x0100
     360:	0d05                	.insn	2, 0x0d05
     362:	0306                	.insn	2, 0x0306
     364:	068201a7          	.insn	4, 0x068201a7
     368:	827ed903          	lhu	s2,-2009(t4)
     36c:	0905                	.insn	2, 0x0905
     36e:	0306                	.insn	2, 0x0306
     370:	02d9                	.insn	2, 0x02d9
     372:	0682                	.insn	2, 0x0682
     374:	097da703          	lw	a4,151(s11)
     378:	0004                	.insn	2, 0x0004
     37a:	0501                	.insn	2, 0x0501
     37c:	0616                	.insn	2, 0x0616
     37e:	4a01a103          	lw	sp,1184(gp)
     382:	0306                	.insn	2, 0x0306
     384:	7edf 0809 0100      	.insn	6, 0x010008097edf
     38a:	0d05                	.insn	2, 0x0d05
     38c:	0306                	.insn	2, 0x0306
     38e:	064a01a7          	.insn	4, 0x064a01a7
     392:	827ed903          	lhu	s2,-2009(t4)
     396:	1f05                	.insn	2, 0x1f05
     398:	0306                	.insn	2, 0x0306
     39a:	01a2                	.insn	2, 0x01a2
     39c:	054a                	.insn	2, 0x054a
     39e:	0305                	.insn	2, 0x0305
     3a0:	064a01b3          	.insn	4, 0x064a01b3
     3a4:	4a7dab03          	lw	s6,1191(s11)
     3a8:	4a02d503          	lhu	a0,1184(t0) # 12c04a0 <USER_MAX+0xdc04a0>
     3ac:	0c05                	.insn	2, 0x0c05
     3ae:	054a                	.insn	2, 0x054a
     3b0:	4a16                	.insn	2, 0x4a16
     3b2:	1905                	.insn	2, 0x1905
     3b4:	0306                	.insn	2, 0x0306
     3b6:	00100903          	lb	s2,1(zero) # 1 <start-0x3fffff>
     3ba:	0501                	.insn	2, 0x0501
     3bc:	0625                	.insn	2, 0x0625
     3be:	054a                	.insn	2, 0x054a
     3c0:	060a                	.insn	2, 0x060a
     3c2:	10090103          	lb	sp,256(s2)
     3c6:	0100                	.insn	2, 0x0100
     3c8:	0905                	.insn	2, 0x0905
     3ca:	4a06                	.insn	2, 0x4a06
     3cc:	1605                	.insn	2, 0x1605
     3ce:	0306                	.insn	2, 0x0306
     3d0:	7eec                	.insn	2, 0x7eec
     3d2:	0809                	.insn	2, 0x0809
     3d4:	0100                	.insn	2, 0x0100
     3d6:	2805                	.insn	2, 0x2805
     3d8:	04090103          	lb	sp,64(s2)
     3dc:	0100                	.insn	2, 0x0100
     3de:	1e05                	.insn	2, 0x1e05
     3e0:	4a06                	.insn	2, 0x4a06
     3e2:	ba7eba03          	.insn	4, 0xba7eba03
     3e6:	2005                	.insn	2, 0x2005
     3e8:	0306                	.insn	2, 0x0306
     3ea:	068201c7          	.insn	4, 0x068201c7
     3ee:	097eb903          	.insn	4, 0x097eb903
     3f2:	000c                	.insn	2, 0x000c
     3f4:	0501                	.insn	2, 0x0501
     3f6:	060d                	.insn	2, 0x060d
     3f8:	4a01bb03          	.insn	4, 0x4a01bb03
     3fc:	0905                	.insn	2, 0x0905
     3fe:	ba00f803          	.insn	4, 0xba00f803
     402:	0306                	.insn	2, 0x0306
     404:	7dcd                	.insn	2, 0x7dcd
     406:	064a                	.insn	2, 0x064a
     408:	8202d903          	lhu	s2,-2016(t0)
     40c:	0d05                	.insn	2, 0x0d05
     40e:	097ece03          	lbu	t3,151(t4)
     412:	0004                	.insn	2, 0x0004
     414:	0601                	.insn	2, 0x0601
     416:	827ed903          	lhu	s2,-2009(t4)
     41a:	1605                	.insn	2, 0x1605
     41c:	0306                	.insn	2, 0x0306
     41e:	01d1                	.insn	2, 0x01d1
     420:	05ba                	.insn	2, 0x05ba
     422:	0328                	.insn	2, 0x0328
     424:	0905                	.insn	2, 0x0905
     426:	0004                	.insn	2, 0x0004
     428:	0501                	.insn	2, 0x0501
     42a:	061e                	.insn	2, 0x061e
     42c:	054a                	.insn	2, 0x054a
     42e:	060d                	.insn	2, 0x060d
     430:	03090583          	lb	a1,48(s2)
     434:	00dc                	.insn	2, 0x00dc
     436:	0682                	.insn	2, 0x0682
     438:	4a7dcd03          	lbu	s10,1191(s11)
     43c:	1605                	.insn	2, 0x1605
     43e:	0306                	.insn	2, 0x0306
     440:	02de                	.insn	2, 0x02de
     442:	06ba                	.insn	2, 0x06ba
     444:	827da203          	lw	tp,-2009(s11)
     448:	0c05                	.insn	2, 0x0c05
     44a:	0306                	.insn	2, 0x0306
     44c:	058202db          	.insn	4, 0x058202db
     450:	5110                	.insn	2, 0x5110
     452:	1605                	.insn	2, 0x1605
     454:	4a06                	.insn	2, 0x4a06
     456:	0505                	.insn	2, 0x0505
     458:	0306                	.insn	2, 0x0306
     45a:	4a79                	.insn	2, 0x4a79
     45c:	1605                	.insn	2, 0x1605
     45e:	08090303          	lb	t1,128(s2)
     462:	0100                	.insn	2, 0x0100
     464:	1b05                	.insn	2, 0x1b05
     466:	08090103          	lb	sp,128(s2)
     46a:	0100                	.insn	2, 0x0100
     46c:	0306                	.insn	2, 0x0306
     46e:	7da1                	.insn	2, 0x7da1
     470:	0809                	.insn	2, 0x0809
     472:	0100                	.insn	2, 0x0100
     474:	4a02df03          	lhu	t5,1184(t0)
     478:	4b06                	.insn	2, 0x4b06
     47a:	0306                	.insn	2, 0x0306
     47c:	7da0                	.insn	2, 0x7da0
     47e:	0809                	.insn	2, 0x0809
     480:	0100                	.insn	2, 0x0100
     482:	1605                	.insn	2, 0x1605
     484:	0306                	.insn	2, 0x0306
     486:	05f201db          	.insn	4, 0x05f201db
     48a:	0328                	.insn	2, 0x0328
     48c:	0905                	.insn	2, 0x0905
     48e:	0004                	.insn	2, 0x0004
     490:	0501                	.insn	2, 0x0501
     492:	061e                	.insn	2, 0x061e
     494:	054a                	.insn	2, 0x054a
     496:	060d                	.insn	2, 0x060d
     498:	0584                	.insn	2, 0x0584
     49a:	0309                	.insn	2, 0x0309
     49c:	8238                	.insn	2, 0x8238
     49e:	0306                	.insn	2, 0x0306
     4a0:	7de6                	.insn	2, 0x7de6
     4a2:	054a                	.insn	2, 0x054a
     4a4:	060d                	.insn	2, 0x060d
     4a6:	4a01cd03          	lbu	s10,1184(gp)
     4aa:	0905                	.insn	2, 0x0905
     4ac:	ba00e603          	.insn	4, 0xba00e603
     4b0:	0306                	.insn	2, 0x0306
     4b2:	7dcd                	.insn	2, 0x7dcd
     4b4:	054a                	.insn	2, 0x054a
     4b6:	0616                	.insn	2, 0x0616
     4b8:	8201e603          	.insn	4, 0x8201e603
     4bc:	2c05                	.insn	2, 0x2c05
     4be:	04090503          	lb	a0,64(s2)
     4c2:	0100                	.insn	2, 0x0100
     4c4:	2205                	.insn	2, 0x2205
     4c6:	4a06                	.insn	2, 0x4a06
     4c8:	0d05                	.insn	2, 0x0d05
     4ca:	8306                	.insn	2, 0x8306
     4cc:	0905                	.insn	2, 0x0905
     4ce:	8200c703          	lbu	a4,-2016(ra)
     4d2:	0306                	.insn	2, 0x0306
     4d4:	7dcd                	.insn	2, 0x7dcd
     4d6:	054a                	.insn	2, 0x054a
     4d8:	0616                	.insn	2, 0x0616
     4da:	ba02de03          	lhu	t3,-1120(t0)
     4de:	0306                	.insn	2, 0x0306
     4e0:	7da2                	.insn	2, 0x7da2
     4e2:	0582                	.insn	2, 0x0582
     4e4:	060c                	.insn	2, 0x060c
     4e6:	8202db03          	lhu	s6,-2016(t0)
     4ea:	1005                	.insn	2, 0x1005
     4ec:	0551                	.insn	2, 0x0551
     4ee:	0616                	.insn	2, 0x0616
     4f0:	054a                	.insn	2, 0x054a
     4f2:	0605                	.insn	2, 0x0605
     4f4:	054a7903          	.insn	4, 0x054a7903
     4f8:	0316                	.insn	2, 0x0316
     4fa:	00080903          	lb	s2,0(a6)
     4fe:	0501                	.insn	2, 0x0501
     500:	0901031b          	.insn	4, 0x0901031b
     504:	0008                	.insn	2, 0x0008
     506:	0601                	.insn	2, 0x0601
     508:	097da103          	lw	sp,151(s11)
     50c:	0008                	.insn	2, 0x0008
     50e:	0301                	.insn	2, 0x0301
     510:	02df 064a 064b      	.insn	6, 0x064b064a02df
     516:	097da003          	lw	zero,151(s11)
     51a:	0008                	.insn	2, 0x0008
     51c:	0501                	.insn	2, 0x0501
     51e:	0616                	.insn	2, 0x0616
     520:	f201f003          	.insn	4, 0xf201f003
     524:	2c05                	.insn	2, 0x2c05
     526:	04090503          	lb	a0,64(s2)
     52a:	0100                	.insn	2, 0x0100
     52c:	2205                	.insn	2, 0x2205
     52e:	4a06                	.insn	2, 0x4a06
     530:	1b05                	.insn	2, 0x1b05
     532:	bb06                	.insn	2, 0xbb06
     534:	0d05                	.insn	2, 0x0d05
     536:	14090403          	lb	s0,320(s2)
     53a:	0100                	.insn	2, 0x0100
     53c:	0905                	.insn	2, 0x0905
     53e:	05ba3903          	.insn	4, 0x05ba3903
     542:	0311                	.insn	2, 0x0311
     544:	4a4c                	.insn	2, 0x4a4c
     546:	1f05                	.insn	2, 0x1f05
     548:	0806                	.insn	2, 0x0806
     54a:	053c                	.insn	2, 0x053c
     54c:	0300                	.insn	2, 0x0300
     54e:	7e81                	.insn	2, 0x7e81
     550:	0409                	.insn	2, 0x0409
     552:	0100                	.insn	2, 0x0100
     554:	0905                	.insn	2, 0x0905
     556:	0306                	.insn	2, 0x0306
     558:	058202b3          	.insn	4, 0x058202b3
     55c:	030d                	.insn	2, 0x030d
     55e:	4a5a                	.insn	2, 0x4a5a
     560:	0905                	.insn	2, 0x0905
     562:	06821b03          	lh	s6,104(tp) # 68 <start-0x3fff98>
     566:	4a7dd803          	lhu	a6,1191(s11)
     56a:	1605                	.insn	2, 0x1605
     56c:	0306                	.insn	2, 0x0306
     56e:	0292                	.insn	2, 0x0292
     570:	0582                	.insn	2, 0x0582
     572:	09050317          	auipc	t1,0x9050
     576:	0004                	.insn	2, 0x0004
     578:	0501                	.insn	2, 0x0501
     57a:	060d                	.insn	2, 0x060d
     57c:	054a                	.insn	2, 0x054a
     57e:	0609                	.insn	2, 0x0609
     580:	0685                	.insn	2, 0x0685
     582:	4a7de603          	.insn	4, 0x4a7de603
     586:	3205                	.insn	2, 0x3205
     588:	0306                	.insn	2, 0x0306
     58a:	0284                	.insn	2, 0x0284
     58c:	054a                	.insn	2, 0x054a
     58e:	060d                	.insn	2, 0x060d
     590:	0582                	.insn	2, 0x0582
     592:	0632                	.insn	2, 0x0632
     594:	060d05f3          	.insn	4, 0x060d05f3
     598:	054a                	.insn	2, 0x054a
     59a:	0632                	.insn	2, 0x0632
     59c:	060d05f3          	.insn	4, 0x060d05f3
     5a0:	054a                	.insn	2, 0x054a
     5a2:	0632                	.insn	2, 0x0632
     5a4:	060d05f3          	.insn	4, 0x060d05f3
     5a8:	054a                	.insn	2, 0x054a
     5aa:	0632                	.insn	2, 0x0632
     5ac:	060d05f3          	.insn	4, 0x060d05f3
     5b0:	034a                	.insn	2, 0x034a
     5b2:	7df8                	.insn	2, 0x7df8
     5b4:	05f2                	.insn	2, 0x05f2
     5b6:	0616                	.insn	2, 0x0616
     5b8:	ba029c03          	lh	s8,-1120(t0)
     5bc:	1d05                	.insn	2, 0x1d05
     5be:	04090503          	lb	a0,64(s2)
     5c2:	0100                	.insn	2, 0x0100
     5c4:	1105                	.insn	2, 0x1105
     5c6:	4a06                	.insn	2, 0x4a06
     5c8:	2605                	.insn	2, 0x2605
     5ca:	0582                	.insn	2, 0x0582
     5cc:	0611                	.insn	2, 0x0611
     5ce:	04090103          	lb	sp,64(s2)
     5d2:	0100                	.insn	2, 0x0100
     5d4:	0905                	.insn	2, 0x0905
     5d6:	05f21103          	lh	sp,95(tp) # 5f <start-0x3fffa1>
     5da:	030d                	.insn	2, 0x030d
     5dc:	4a72                	.insn	2, 0x4a72
     5de:	0905                	.insn	2, 0x0905
     5e0:	0585                	.insn	2, 0x0585
     5e2:	4b0d                	.insn	2, 0x4b0d
     5e4:	0905                	.insn	2, 0x0905
     5e6:	05f20a03          	lb	s4,95(tp) # 5f <start-0x3fffa1>
     5ea:	4d0d                	.insn	2, 0x4d0d
     5ec:	0505                	.insn	2, 0x0505
     5ee:	030a                	.insn	2, 0x030a
     5f0:	091f 0008 0501      	.insn	6, 0x05010008091f
     5f6:	060c                	.insn	2, 0x060c
     5f8:	3c08                	.insn	2, 0x3c08
     5fa:	1605                	.insn	2, 0x1605
     5fc:	034a                	.insn	2, 0x034a
     5fe:	08097dab          	.insn	4, 0x08097dab
     602:	0100                	.insn	2, 0x0100
     604:	4a02d503          	lhu	a0,1184(t0)
     608:	1905                	.insn	2, 0x1905
     60a:	0306                	.insn	2, 0x0306
     60c:	00040903          	lb	s2,0(s0)
     610:	0501                	.insn	2, 0x0501
     612:	0625                	.insn	2, 0x0625
     614:	054a                	.insn	2, 0x054a
     616:	060a                	.insn	2, 0x060a
     618:	0c090103          	lb	sp,192(s2)
     61c:	0100                	.insn	2, 0x0100
     61e:	0905                	.insn	2, 0x0905
     620:	4a06                	.insn	2, 0x4a06
     622:	0a05                	.insn	2, 0x0a05
     624:	0306                	.insn	2, 0x0306
     626:	0900                	.insn	2, 0x0900
     628:	0008                	.insn	2, 0x0008
     62a:	0501                	.insn	2, 0x0501
     62c:	0609                	.insn	2, 0x0609
     62e:	034a                	.insn	2, 0x034a
     630:	04097da7          	.insn	4, 0x04097da7
     634:	0100                	.insn	2, 0x0100
     636:	0105                	.insn	2, 0x0105
     638:	0306                	.insn	2, 0x0306
     63a:	02e6                	.insn	2, 0x02e6
     63c:	064a                	.insn	2, 0x064a
     63e:	4a7d9a03          	lh	s4,1191(s11)
     642:	1605                	.insn	2, 0x1605
     644:	0306                	.insn	2, 0x0306
     646:	02de                	.insn	2, 0x02de
     648:	06ba                	.insn	2, 0x06ba
     64a:	087da203          	lw	tp,135(s11)
     64e:	053c                	.insn	2, 0x053c
     650:	060c                	.insn	2, 0x060c
     652:	8202db03          	lhu	s6,-2016(t0)
     656:	1005                	.insn	2, 0x1005
     658:	0551                	.insn	2, 0x0551
     65a:	0616                	.insn	2, 0x0616
     65c:	054a                	.insn	2, 0x054a
     65e:	0605                	.insn	2, 0x0605
     660:	054a7903          	.insn	4, 0x054a7903
     664:	0316                	.insn	2, 0x0316
     666:	00080903          	lb	s2,0(a6)
     66a:	0501                	.insn	2, 0x0501
     66c:	0901031b          	.insn	4, 0x0901031b
     670:	0008                	.insn	2, 0x0008
     672:	0601                	.insn	2, 0x0601
     674:	097da103          	lw	sp,151(s11)
     678:	0008                	.insn	2, 0x0008
     67a:	0301                	.insn	2, 0x0301
     67c:	02df 064a 064b      	.insn	6, 0x064b064a02df
     682:	097da003          	lw	zero,151(s11)
     686:	0008                	.insn	2, 0x0008
     688:	0501                	.insn	2, 0x0501
     68a:	060a                	.insn	2, 0x060a
     68c:	ba02e403          	.insn	4, 0xba02e403
     690:	0105                	.insn	2, 0x0105
     692:	054c                	.insn	2, 0x054c
     694:	0300                	.insn	2, 0x0300
     696:	095a                	.insn	2, 0x095a
     698:	0004                	.insn	2, 0x0004
     69a:	0501                	.insn	2, 0x0501
     69c:	0a05                	.insn	2, 0x0a05
     69e:	2402                	.insn	2, 0x2402
     6a0:	0614                	.insn	2, 0x0614
     6a2:	097dbe03          	.insn	4, 0x097dbe03
     6a6:	0004                	.insn	2, 0x0004
     6a8:	0501                	.insn	2, 0x0501
     6aa:	0625                	.insn	2, 0x0625
     6ac:	ba02c203          	lbu	tp,-1120(t0)
     6b0:	0505                	.insn	2, 0x0505
     6b2:	4a06                	.insn	2, 0x4a06
     6b4:	0d05                	.insn	2, 0x0d05
     6b6:	0306                	.insn	2, 0x0306
     6b8:	0901                	.insn	2, 0x0901
     6ba:	0004                	.insn	2, 0x0004
     6bc:	0601                	.insn	2, 0x0601
     6be:	ba7dbd03          	.insn	4, 0xba7dbd03
     6c2:	0306                	.insn	2, 0x0306
     6c4:	02c4                	.insn	2, 0x02c4
     6c6:	0409                	.insn	2, 0x0409
     6c8:	0100                	.insn	2, 0x0100
     6ca:	1205                	.insn	2, 0x1205
     6cc:	4b1d05f3          	.insn	4, 0x4b1d05f3
     6d0:	1105                	.insn	2, 0x1105
     6d2:	08090103          	lb	sp,128(s2)
     6d6:	0100                	.insn	2, 0x0100
     6d8:	0306                	.insn	2, 0x0306
     6da:	7db9                	.insn	2, 0x7db9
     6dc:	05ba                	.insn	2, 0x05ba
     6de:	0615                	.insn	2, 0x0615
     6e0:	4a02ca03          	lbu	s4,1184(t0)
     6e4:	0905                	.insn	2, 0x0905
     6e6:	08090103          	lb	sp,128(s2)
     6ea:	0100                	.insn	2, 0x0100
     6ec:	0505                	.insn	2, 0x0505
     6ee:	06bc                	.insn	2, 0x06bc
     6f0:	2002f20b          	.insn	4, 0x2002f20b
     6f4:	0100                	.insn	2, 0x0100
     6f6:	7701                	.insn	2, 0x7701
     6f8:	0006                	.insn	2, 0x0006
     6fa:	0500                	.insn	2, 0x0500
     6fc:	0400                	.insn	2, 0x0400
     6fe:	a800                	.insn	2, 0xa800
     700:	0000                	.insn	2, 0x0000
     702:	0100                	.insn	2, 0x0100
     704:	0101                	.insn	2, 0x0101
     706:	000d0efb          	.insn	4, 0x000d0efb
     70a:	0101                	.insn	2, 0x0101
     70c:	0101                	.insn	2, 0x0101
     70e:	0000                	.insn	2, 0x0000
     710:	0100                	.insn	2, 0x0100
     712:	0000                	.insn	2, 0x0000
     714:	0101                	.insn	2, 0x0101
     716:	1f01                	.insn	2, 0x1f01
     718:	00000003          	lb	zero,0(zero) # 0 <start-0x400000>
     71c:	3500                	.insn	2, 0x3500
     71e:	0000                	.insn	2, 0x0000
     720:	5600                	.insn	2, 0x5600
     722:	0000                	.insn	2, 0x0000
     724:	0300                	.insn	2, 0x0300
     726:	1f01                	.insn	2, 0x1f01
     728:	0f02                	.insn	2, 0x0f02
     72a:	1e05                	.insn	2, 0x1e05
     72c:	7c06                	.insn	2, 0x7c06
     72e:	0000                	.insn	2, 0x0000
     730:	0000                	.insn	2, 0x0000
     732:	c6ac                	.insn	2, 0xc6ac
     734:	a9c8                	.insn	2, 0xa9c8
     736:	57c1                	.insn	2, 0x57c1
     738:	740d                	.insn	2, 0x740d
     73a:	d91c                	.insn	2, 0xd91c
     73c:	94e8                	.insn	2, 0x94e8
     73e:	948d                	.insn	2, 0x948d
     740:	cb12                	.insn	2, 0xcb12
     742:	0080                	.insn	2, 0x0080
     744:	0000                	.insn	2, 0x0000
     746:	ac01                	.insn	2, 0xac01
     748:	c8c6                	.insn	2, 0xc8c6
     74a:	c1a9                	.insn	2, 0xc1a9
     74c:	1c740d57          	.insn	4, 0x1c740d57
     750:	e8d9                	.insn	2, 0xe8d9
     752:	8d94                	.insn	2, 0x8d94
     754:	1294                	.insn	2, 0x1294
     756:	000087cb          	.insn	4, 0x87cb
     75a:	0200                	.insn	2, 0x0200
     75c:	7aa4                	.insn	2, 0x7aa4
     75e:	6c6a                	.insn	2, 0x6c6a
     760:	cb7f 27c6 2376 e67d 	.insn	18, 0x3701000000474995acabe67d237627c6cb7f
     768:	acab 4995 0047 0000 
     770:	3701 
     772:	0bd2                	.insn	2, 0x0bd2
     774:	88f9524b          	.insn	4, 0x88f9524b
     778:	a3c4                	.insn	2, 0xa3c4
     77a:	2a19                	.insn	2, 0x2a19
     77c:	f27f                	.insn	2, 0xf27f
     77e:	4e87d623          	.insn	4, 0x4e87d623
     782:	0000                	.insn	2, 0x0000
     784:	0100                	.insn	2, 0x0100
     786:	8925                	.insn	2, 0x8925
     788:	ef25                	.insn	2, 0xef25
     78a:	9699                	.insn	2, 0x9699
     78c:	84d0                	.insn	2, 0x84d0
     78e:	8c71                	.insn	2, 0x8c71
     790:	b17c                	.insn	2, 0xb17c
     792:	b91c                	.insn	2, 0xb91c
     794:	0090e2fb          	.insn	4, 0x0090e2fb
     798:	0000                	.insn	2, 0x0000
     79a:	f901                	.insn	2, 0xf901
     79c:	4759                	.insn	2, 0x4759
     79e:	9fbe                	.insn	2, 0x9fbe
     7a0:	b709                	.insn	2, 0xb709
     7a2:	a8ac                	.insn	2, 0xa8ac
     7a4:	f2ee                	.insn	2, 0xf2ee
     7a6:	f136                	.insn	2, 0xf136
     7a8:	b1da                	.insn	2, 0xb1da
     7aa:	0a0505f3          	.insn	4, 0x0a0505f3
     7ae:	0500                	.insn	2, 0x0500
     7b0:	3002                	.insn	2, 0x3002
     7b2:	400a                	.insn	2, 0x400a
     7b4:	0300                	.insn	2, 0x0300
     7b6:	00c0                	.insn	2, 0x00c0
     7b8:	0301                	.insn	2, 0x0301
     7ba:	053c0813          	addi	a6,s8,83
     7be:	0300                	.insn	2, 0x0300
     7c0:	0925                	.insn	2, 0x0925
     7c2:	0004                	.insn	2, 0x0004
     7c4:	0501                	.insn	2, 0x0501
     7c6:	0a1a                	.insn	2, 0x0a1a
     7c8:	064a0b03          	lb	s6,100(s4) # 12054226 <USER_MAX+0x11b54226>
     7cc:	097efc03          	.insn	4, 0x097efc03
     7d0:	000c                	.insn	2, 0x000c
     7d2:	0301                	.insn	2, 0x0301
     7d4:	0184                	.insn	2, 0x0184
     7d6:	054a                	.insn	2, 0x054a
     7d8:	0605                	.insn	2, 0x0605
     7da:	0c090703          	lb	a4,192(s2)
     7de:	0100                	.insn	2, 0x0100
     7e0:	0905                	.insn	2, 0x0905
     7e2:	3d08                	.insn	2, 0x3d08
     7e4:	0306                	.insn	2, 0x0306
     7e6:	7ef4                	.insn	2, 0x7ef4
     7e8:	05ba                	.insn	2, 0x05ba
     7ea:	061f 9003 0801      	.insn	6, 0x08019003061f
     7f0:	053c                	.insn	2, 0x053c
     7f2:	061d                	.insn	2, 0x061d
     7f4:	054a                	.insn	2, 0x054a
     7f6:	061f 0549 4c1d      	.insn	6, 0x4c1d0549061f
     7fc:	2005                	.insn	2, 0x2005
     7fe:	0545                	.insn	2, 0x0545
     800:	4d1f 2005 0547      	.insn	6, 0x054720054d1f
     806:	4d1d                	.insn	2, 0x4d1d
     808:	2005                	.insn	2, 0x2005
     80a:	06090547          	.insn	4, 0x06090547
     80e:	05ba                	.insn	2, 0x05ba
     810:	7f03062b          	.insn	4, 0x7f03062b
     814:	0409                	.insn	2, 0x0409
     816:	0100                	.insn	2, 0x0100
     818:	0505                	.insn	2, 0x0505
     81a:	4a06                	.insn	2, 0x4a06
     81c:	097ef503          	.insn	4, 0x097ef503
     820:	0014                	.insn	2, 0x0014
     822:	0601                	.insn	2, 0x0601
     824:	8204de03          	lhu	t3,-2016(s1)
     828:	0306                	.insn	2, 0x0306
     82a:	7ba2                	.insn	2, 0x7ba2
     82c:	3c08                	.insn	2, 0x3c08
     82e:	0306                	.insn	2, 0x0306
     830:	064a049b          	.insn	4, 0x064a049b
     834:	03ba                	.insn	2, 0x03ba
     836:	7be5                	.insn	2, 0x7be5
     838:	05f2                	.insn	2, 0x05f2
     83a:	0609                	.insn	2, 0x0609
     83c:	8201a103          	lw	sp,-2016(gp)
     840:	0306                	.insn	2, 0x0306
     842:	7edf 05ba 061c      	.insn	6, 0x061c05ba7edf
     848:	4a01a203          	lw	tp,1184(gp)
     84c:	0505                	.insn	2, 0x0505
     84e:	4a03a103          	lw	sp,1184(t2)
     852:	05ba5803          	lhu	a6,91(s4)
     856:	0320                	.insn	2, 0x0320
     858:	7d86                	.insn	2, 0x7d86
     85a:	05ba                	.insn	2, 0x05ba
     85c:	0609                	.insn	2, 0x0609
     85e:	054a                	.insn	2, 0x054a
     860:	0605                	.insn	2, 0x0605
     862:	0902fa03          	.insn	4, 0x0902fa03
     866:	0004                	.insn	2, 0x0004
     868:	0501                	.insn	2, 0x0501
     86a:	7d85032b          	.insn	4, 0x7d85032b
     86e:	05ba                	.insn	2, 0x05ba
     870:	0605                	.insn	2, 0x0605
     872:	034a                	.insn	2, 0x034a
     874:	7ee0                	.insn	2, 0x7ee0
     876:	0809                	.insn	2, 0x0809
     878:	0100                	.insn	2, 0x0100
     87a:	0306                	.insn	2, 0x0306
     87c:	06ba049b          	.insn	4, 0x06ba049b
     880:	baba                	.insn	2, 0xbaba
     882:	0905                	.insn	2, 0x0905
     884:	0306                	.insn	2, 0x0306
     886:	7d92                	.insn	2, 0x7d92
     888:	7408                	.insn	2, 0x7408
     88a:	0306                	.insn	2, 0x0306
     88c:	05ba7ed3          	.insn	4, 0x05ba7ed3
     890:	061c                	.insn	2, 0x061c
     892:	4a01ae03          	lw	t3,1184(gp)
     896:	0505                	.insn	2, 0x0505
     898:	4a039503          	lh	a0,1184(t2)
     89c:	05ba5803          	lhu	a6,91(s4)
     8a0:	0320                	.insn	2, 0x0320
     8a2:	7d92                	.insn	2, 0x7d92
     8a4:	05ba                	.insn	2, 0x05ba
     8a6:	0609                	.insn	2, 0x0609
     8a8:	054a                	.insn	2, 0x054a
     8aa:	0605                	.insn	2, 0x0605
     8ac:	0902ee03          	.insn	4, 0x0902ee03
     8b0:	0004                	.insn	2, 0x0004
     8b2:	0501                	.insn	2, 0x0501
     8b4:	7d91032b          	.insn	4, 0x7d91032b
     8b8:	05ba                	.insn	2, 0x05ba
     8ba:	0605                	.insn	2, 0x0605
     8bc:	034a                	.insn	2, 0x034a
     8be:	7ed4                	.insn	2, 0x7ed4
     8c0:	0809                	.insn	2, 0x0809
     8c2:	0100                	.insn	2, 0x0100
     8c4:	0306                	.insn	2, 0x0306
     8c6:	06ba049b          	.insn	4, 0x06ba049b
     8ca:	baba                	.insn	2, 0xbaba
     8cc:	0905                	.insn	2, 0x0905
     8ce:	0306                	.insn	2, 0x0306
     8d0:	7d9e                	.insn	2, 0x7d9e
     8d2:	7408                	.insn	2, 0x7408
     8d4:	0306                	.insn	2, 0x0306
     8d6:	05ba7ec7          	.insn	4, 0x05ba7ec7
     8da:	061c                	.insn	2, 0x061c
     8dc:	4a01ba03          	.insn	4, 0x4a01ba03
     8e0:	0505                	.insn	2, 0x0505
     8e2:	4a038903          	lb	s2,1184(t2)
     8e6:	05ba5803          	lhu	a6,91(s4)
     8ea:	0320                	.insn	2, 0x0320
     8ec:	7d9e                	.insn	2, 0x7d9e
     8ee:	05ba                	.insn	2, 0x05ba
     8f0:	0609                	.insn	2, 0x0609
     8f2:	054a                	.insn	2, 0x054a
     8f4:	0605                	.insn	2, 0x0605
     8f6:	0902e203          	.insn	4, 0x0902e203
     8fa:	0004                	.insn	2, 0x0004
     8fc:	0501                	.insn	2, 0x0501
     8fe:	7d9d032b          	.insn	4, 0x7d9d032b
     902:	05ba                	.insn	2, 0x05ba
     904:	0605                	.insn	2, 0x0605
     906:	034a                	.insn	2, 0x034a
     908:	7ec8                	.insn	2, 0x7ec8
     90a:	0809                	.insn	2, 0x0809
     90c:	0100                	.insn	2, 0x0100
     90e:	0306                	.insn	2, 0x0306
     910:	054a049b          	.insn	4, 0x054a049b
     914:	0b01                	.insn	2, 0x0b01
     916:	ba7da603          	lw	a2,-1113(s11)
     91a:	0905                	.insn	2, 0x0905
     91c:	05824603          	lbu	a2,88(tp) # 58 <start-0x3fffa8>
     920:	0300                	.insn	2, 0x0300
     922:	01ea                	.insn	2, 0x01ea
     924:	1009                	.insn	2, 0x1009
     926:	0100                	.insn	2, 0x0100
     928:	0505                	.insn	2, 0x0505
     92a:	020a                	.insn	2, 0x020a
     92c:	1464                	.insn	2, 0x1464
     92e:	0d05                	.insn	2, 0x0d05
     930:	4108                	.insn	2, 0x4108
     932:	0c05                	.insn	2, 0x0c05
     934:	04093c03          	.insn	4, 0x04093c03
     938:	0100                	.insn	2, 0x0100
     93a:	054a4103          	lbu	sp,84(s4)
     93e:	0605                	.insn	2, 0x0605
     940:	064a                	.insn	2, 0x064a
     942:	0901a603          	lw	a2,144(gp)
     946:	0008                	.insn	2, 0x0008
     948:	0501                	.insn	2, 0x0501
     94a:	030c                	.insn	2, 0x030c
     94c:	7f99                	.insn	2, 0x7f99
     94e:	05ba                	.insn	2, 0x05ba
     950:	0305                	.insn	2, 0x0305
     952:	4a41                	.insn	2, 0x4a41
     954:	1505                	.insn	2, 0x1505
     956:	054d                	.insn	2, 0x054d
     958:	4910                	.insn	2, 0x4910
     95a:	0d05                	.insn	2, 0x0d05
     95c:	0321054b          	.insn	4, 0x0321054b
     960:	0910                	.insn	2, 0x0910
     962:	000c                	.insn	2, 0x000c
     964:	0501                	.insn	2, 0x0501
     966:	f51f 1b05 0d03      	.insn	6, 0x0d031b05f51f
     96c:	0409                	.insn	2, 0x0409
     96e:	0100                	.insn	2, 0x0100
     970:	0505                	.insn	2, 0x0505
     972:	09018303          	lb	t1,144(gp)
     976:	0004                	.insn	2, 0x0004
     978:	0501                	.insn	2, 0x0501
     97a:	030c                	.insn	2, 0x030c
     97c:	7f99                	.insn	2, 0x7f99
     97e:	05ba                	.insn	2, 0x05ba
     980:	0305                	.insn	2, 0x0305
     982:	4a41                	.insn	2, 0x4a41
     984:	0d05                	.insn	2, 0x0d05
     986:	054d                	.insn	2, 0x054d
     988:	0326                	.insn	2, 0x0326
     98a:	0931                	.insn	2, 0x0931
     98c:	0008                	.insn	2, 0x0008
     98e:	0501                	.insn	2, 0x0501
     990:	f432                	.insn	2, 0xf432
     992:	2105                	.insn	2, 0x2105
     994:	813e054b          	.insn	4, 0x813e054b
     998:	2105                	.insn	2, 0x2105
     99a:	03050583          	lb	a1,48(a0) # 13564 <start-0x3eca9c>
     99e:	054a00ef          	jal	a09f2 <start-0x35f60e>
     9a2:	0321                	.insn	2, 0x0321
     9a4:	7f91                	.insn	2, 0x7f91
     9a6:	05ba                	.insn	2, 0x05ba
     9a8:	493e                	.insn	2, 0x493e
     9aa:	2105                	.insn	2, 0x2105
     9ac:	03050583          	lb	a1,48(a0)
     9b0:	054a00ef          	jal	a0a04 <start-0x35f5fc>
     9b4:	0321                	.insn	2, 0x0321
     9b6:	7f91                	.insn	2, 0x7f91
     9b8:	05ba                	.insn	2, 0x05ba
     9ba:	493e                	.insn	2, 0x493e
     9bc:	2105                	.insn	2, 0x2105
     9be:	03050583          	lb	a1,48(a0)
     9c2:	054a00ef          	jal	a0a16 <start-0x35f5ea>
     9c6:	0321                	.insn	2, 0x0321
     9c8:	7f91                	.insn	2, 0x7f91
     9ca:	05ba                	.insn	2, 0x05ba
     9cc:	493e                	.insn	2, 0x493e
     9ce:	2105                	.insn	2, 0x2105
     9d0:	03050583          	lb	a1,48(a0)
     9d4:	054a00ef          	jal	a0a28 <start-0x35f5d8>
     9d8:	0321                	.insn	2, 0x0321
     9da:	7f91                	.insn	2, 0x7f91
     9dc:	05ba                	.insn	2, 0x05ba
     9de:	493e                	.insn	2, 0x493e
     9e0:	2105                	.insn	2, 0x2105
     9e2:	03050583          	lb	a1,48(a0)
     9e6:	054a00ef          	jal	a0a3a <start-0x35f5c6>
     9ea:	0321                	.insn	2, 0x0321
     9ec:	7f91                	.insn	2, 0x7f91
     9ee:	05ba                	.insn	2, 0x05ba
     9f0:	493e                	.insn	2, 0x493e
     9f2:	2105                	.insn	2, 0x2105
     9f4:	03050583          	lb	a1,48(a0)
     9f8:	054a00ef          	jal	a0a4c <start-0x35f5b4>
     9fc:	0321                	.insn	2, 0x0321
     9fe:	7f91                	.insn	2, 0x7f91
     a00:	05ba                	.insn	2, 0x05ba
     a02:	493e                	.insn	2, 0x493e
     a04:	2105                	.insn	2, 0x2105
     a06:	0305054b          	.insn	4, 0x0305054b
     a0a:	054a00ef          	jal	a0a5e <start-0x35f5a2>
     a0e:	0321                	.insn	2, 0x0321
     a10:	7f91                	.insn	2, 0x7f91
     a12:	05ba                	.insn	2, 0x05ba
     a14:	0305                	.insn	2, 0x0305
     a16:	054a00ef          	jal	a0a6a <start-0x35f596>
     a1a:	030c                	.insn	2, 0x030c
     a1c:	7f99                	.insn	2, 0x7f99
     a1e:	05ba                	.insn	2, 0x05ba
     a20:	0305                	.insn	2, 0x0305
     a22:	4a41                	.insn	2, 0x4a41
     a24:	4a01a603          	lw	a2,1184(gp)
     a28:	0c05                	.insn	2, 0x0c05
     a2a:	ba7f9903          	lh	s2,-1113(t6)
     a2e:	0505                	.insn	2, 0x0505
     a30:	054a4103          	lbu	sp,84(s4)
     a34:	0325                	.insn	2, 0x0325
     a36:	1c054a0b          	.insn	4, 0x1c054a0b
     a3a:	061505f3          	.insn	4, 0x061505f3
     a3e:	054a                	.insn	2, 0x054a
     a40:	0605                	.insn	2, 0x0605
     a42:	09019a03          	lh	s4,144(gp)
     a46:	0008                	.insn	2, 0x0008
     a48:	0501                	.insn	2, 0x0501
     a4a:	031c                	.insn	2, 0x031c
     a4c:	7ee6                	.insn	2, 0x7ee6
     a4e:	05ba                	.insn	2, 0x05ba
     a50:	0615                	.insn	2, 0x0615
     a52:	054a                	.insn	2, 0x054a
     a54:	0605                	.insn	2, 0x0605
     a56:	09019a03          	lh	s4,144(gp)
     a5a:	000c                	.insn	2, 0x000c
     a5c:	0501                	.insn	2, 0x0501
     a5e:	033a                	.insn	2, 0x033a
     a60:	06ba7ef3          	csrrci	t4,0x6b,20
     a64:	4a7cf203          	.insn	4, 0x4a7cf203
     a68:	1b05                	.insn	2, 0x1b05
     a6a:	0306                	.insn	2, 0x0306
     a6c:	039f 05ba 491e      	.insn	6, 0x491e05ba039f
     a72:	1b05                	.insn	2, 0x1b05
     a74:	492d054b          	.insn	4, 0x492d054b
     a78:	2405                	.insn	2, 0x2405
     a7a:	f206                	.insn	2, 0xf206
     a7c:	2205                	.insn	2, 0x2205
     a7e:	054a                	.insn	2, 0x054a
     a80:	0615                	.insn	2, 0x0615
     a82:	0581                	.insn	2, 0x0581
     a84:	0321                	.insn	2, 0x0321
     a86:	00040907          	.insn	4, 0x00040907
     a8a:	0501                	.insn	2, 0x0501
     a8c:	0305                	.insn	2, 0x0305
     a8e:	058200f7          	.insn	4, 0x058200f7
     a92:	031e                	.insn	2, 0x031e
     a94:	7f88                	.insn	2, 0x7f88
     a96:	05ba                	.insn	2, 0x05ba
     a98:	0615                	.insn	2, 0x0615
     a9a:	0382                	.insn	2, 0x0382
     a9c:	7cdd                	.insn	2, 0x7cdd
     a9e:	0809                	.insn	2, 0x0809
     aa0:	0100                	.insn	2, 0x0100
     aa2:	0505                	.insn	2, 0x0505
     aa4:	0306                	.insn	2, 0x0306
     aa6:	054a049b          	.insn	4, 0x054a049b
     aaa:	0b01                	.insn	2, 0x0b01
     aac:	ba7f9e03          	lh	t3,-1113(t6)
     ab0:	0005                	.insn	2, 0x0005
     ab2:	0900e103          	.insn	4, 0x0900e103
     ab6:	0018                	.insn	2, 0x0018
     ab8:	0501                	.insn	2, 0x0501
     aba:	0a05                	.insn	2, 0x0a05
     abc:	c201054b          	.insn	4, 0xc201054b
     ac0:	0005                	.insn	2, 0x0005
     ac2:	04091f03          	lh	t5,64(s2)
     ac6:	0100                	.insn	2, 0x0100
     ac8:	0505                	.insn	2, 0x0505
     aca:	4b0a                	.insn	2, 0x4b0a
     acc:	0105                	.insn	2, 0x0105
     ace:	05c2                	.insn	2, 0x05c2
     ad0:	0a05                	.insn	2, 0x0a05
     ad2:	04092603          	lw	a2,64(s2)
     ad6:	0100                	.insn	2, 0x0100
     ad8:	0105                	.insn	2, 0x0105
     ada:	827cdb03          	lhu	s6,-2009(s9)
     ade:	0005                	.insn	2, 0x0005
     ae0:	04091a03          	lh	s4,64(s2)
     ae4:	0100                	.insn	2, 0x0100
     ae6:	0905                	.insn	2, 0x0905
     ae8:	080a                	.insn	2, 0x080a
     aea:	0540                	.insn	2, 0x0540
     aec:	0814                	.insn	2, 0x0814
     aee:	03090577          	.insn	4, 0x03090577
     af2:	0902                	.insn	2, 0x0902
     af4:	0004                	.insn	2, 0x0004
     af6:	be01                	.insn	2, 0xbe01
     af8:	1105                	.insn	2, 0x1105
     afa:	8206                	.insn	2, 0x8206
     afc:	0905                	.insn	2, 0x0905
     afe:	0306                	.insn	2, 0x0306
     b00:	0901                	.insn	2, 0x0901
     b02:	0004                	.insn	2, 0x0004
     b04:	0501                	.insn	2, 0x0501
     b06:	0600                	.insn	2, 0x0600
     b08:	827e8c03          	lb	s8,-2009(t4)
     b0c:	0105                	.insn	2, 0x0105
     b0e:	0b06                	.insn	2, 0x0b06
     b10:	ba028703          	lb	a4,-1120(t0)
     b14:	0905                	.insn	2, 0x0905
     b16:	3c087203          	.insn	4, 0x3c087203
     b1a:	4c86                	.insn	2, 0x4c86
     b1c:	054a7a03          	.insn	4, 0x054a7a03
     b20:	4c05                	.insn	2, 0x4c05
     b22:	3c085d03          	lhu	s10,960(a6)
     b26:	0306                	.insn	2, 0x0306
     b28:	7ea8                	.insn	2, 0x7ea8
     b2a:	06f2                	.insn	2, 0x06f2
     b2c:	030a                	.insn	2, 0x030a
     b2e:	04f1                	.insn	2, 0x04f1
     b30:	0409                	.insn	2, 0x0409
     b32:	0100                	.insn	2, 0x0100
     b34:	0105                	.insn	2, 0x0105
     b36:	827da103          	lw	sp,-2009(s11)
     b3a:	0505                	.insn	2, 0x0505
     b3c:	030a                	.insn	2, 0x030a
     b3e:	040902ef          	jal	t0,90b7e <start-0x36f482>
     b42:	0100                	.insn	2, 0x0100
     b44:	0105                	.insn	2, 0x0105
     b46:	827d9c03          	lh	s8,-2009(s11)
     b4a:	0505                	.insn	2, 0x0505
     b4c:	030a                	.insn	2, 0x030a
     b4e:	02e4                	.insn	2, 0x02e4
     b50:	0409                	.insn	2, 0x0409
     b52:	0100                	.insn	2, 0x0100
     b54:	0105                	.insn	2, 0x0105
     b56:	827da703          	lw	a4,-2009(s11)
     b5a:	0505                	.insn	2, 0x0505
     b5c:	030a                	.insn	2, 0x030a
     b5e:	02ed                	.insn	2, 0x02ed
     b60:	0409                	.insn	2, 0x0409
     b62:	0100                	.insn	2, 0x0100
     b64:	827d9a03          	lh	s4,-2009(s11)
     b68:	0005                	.insn	2, 0x0005
     b6a:	04090903          	lb	s2,64(s2)
     b6e:	0100                	.insn	2, 0x0100
     b70:	0505                	.insn	2, 0x0505
     b72:	830a                	.insn	2, 0x830a
     b74:	f2039103          	lh	sp,-224(t2)
     b78:	f27cf403          	.insn	4, 0xf27cf403
     b7c:	0306                	.insn	2, 0x0306
     b7e:	7dc2                	.insn	2, 0x7dc2
     b80:	0409                	.insn	2, 0x0409
     b82:	0100                	.insn	2, 0x0100
     b84:	8202be03          	.insn	4, 0x8202be03
     b88:	0905                	.insn	2, 0x0905
     b8a:	0306                	.insn	2, 0x0306
     b8c:	0902                	.insn	2, 0x0902
     b8e:	0008                	.insn	2, 0x0008
     b90:	be01                	.insn	2, 0xbe01
     b92:	05be                	.insn	2, 0x05be
     b94:	0600                	.insn	2, 0x0600
     b96:	7db8030b          	.insn	4, 0x7db8030b
     b9a:	0582                	.insn	2, 0x0582
     b9c:	0609                	.insn	2, 0x0609
     b9e:	f202cc03          	lbu	s8,-224(t0)
     ba2:	0b06                	.insn	2, 0x0b06
     ba4:	0582                	.insn	2, 0x0582
     ba6:	0605                	.insn	2, 0x0605
     ba8:	030a                	.insn	2, 0x030a
     baa:	02fe                	.insn	2, 0x02fe
     bac:	1009                	.insn	2, 0x1009
     bae:	0100                	.insn	2, 0x0100
     bb0:	0ac1                	.insn	2, 0x0ac1
     bb2:	04096903          	.insn	4, 0x04096903
     bb6:	0100                	.insn	2, 0x0100
     bb8:	0105                	.insn	2, 0x0105
     bba:	827da103          	lw	sp,-2009(s11)
     bbe:	0c05                	.insn	2, 0x0c05
     bc0:	030a                	.insn	2, 0x030a
     bc2:	0905                	.insn	2, 0x0905
     bc4:	0004                	.insn	2, 0x0004
     bc6:	0501                	.insn	2, 0x0501
     bc8:	0605                	.insn	2, 0x0605
     bca:	0382                	.insn	2, 0x0382
     bcc:	7da0                	.insn	2, 0x7da0
     bce:	0809                	.insn	2, 0x0809
     bd0:	0100                	.insn	2, 0x0100
     bd2:	0e05                	.insn	2, 0x0e05
     bd4:	0306                	.insn	2, 0x0306
     bd6:	02e1                	.insn	2, 0x02e1
     bd8:	054a                	.insn	2, 0x054a
     bda:	490c                	.insn	2, 0x490c
     bdc:	0b05                	.insn	2, 0x0b05
     bde:	4905054b          	.insn	4, 0x4905054b
     be2:	0306                	.insn	2, 0x0306
     be4:	7da0                	.insn	2, 0x7da0
     be6:	034a                	.insn	2, 0x034a
     be8:	02e0                	.insn	2, 0x02e0
     bea:	054a                	.insn	2, 0x054a
     bec:	0608                	.insn	2, 0x0608
     bee:	04090203          	lb	tp,64(s2)
     bf2:	0100                	.insn	2, 0x0100
     bf4:	0505                	.insn	2, 0x0505
     bf6:	0a0c054b          	.insn	4, 0x0a0c054b
     bfa:	04090403          	lb	s0,64(s2)
     bfe:	0100                	.insn	2, 0x0100
     c00:	1005                	.insn	2, 0x1005
     c02:	4a06                	.insn	2, 0x4a06
     c04:	0505                	.insn	2, 0x0505
     c06:	04090003          	lb	zero,64(s2)
     c0a:	0100                	.insn	2, 0x0100
     c0c:	1305                	.insn	2, 0x1305
     c0e:	054a                	.insn	2, 0x054a
     c10:	4a05                	.insn	2, 0x4a05
     c12:	0c05                	.insn	2, 0x0c05
     c14:	04090003          	lb	zero,64(s2)
     c18:	0100                	.insn	2, 0x0100
     c1a:	0b05                	.insn	2, 0x0b05
     c1c:	4e06                	.insn	2, 0x4e06
     c1e:	1005                	.insn	2, 0x1005
     c20:	0546                	.insn	2, 0x0546
     c22:	09070323          	sb	a6,134(a4) # 2e226fa <USER_MAX+0x29226fa>
     c26:	0008                	.insn	2, 0x0008
     c28:	0501                	.insn	2, 0x0501
     c2a:	0621                	.insn	2, 0x0621
     c2c:	054a                	.insn	2, 0x054a
     c2e:	4a05                	.insn	2, 0x4a05
     c30:	0005                	.insn	2, 0x0005
     c32:	0306                	.insn	2, 0x0306
     c34:	00d1                	.insn	2, 0x00d1
     c36:	0409                	.insn	2, 0x0409
     c38:	0100                	.insn	2, 0x0100
     c3a:	0a05                	.insn	2, 0x0a05
     c3c:	4c0a                	.insn	2, 0x4c0a
     c3e:	1705                	.insn	2, 0x1705
     c40:	8206                	.insn	2, 0x8206
     c42:	1b05                	.insn	2, 0x1b05
     c44:	04090003          	lb	zero,64(s2)
     c48:	0100                	.insn	2, 0x0100
     c4a:	2705                	.insn	2, 0x2705
     c4c:	054a                	.insn	2, 0x054a
     c4e:	060c                	.insn	2, 0x060c
     c50:	0c090503          	lb	a0,192(s2)
     c54:	0100                	.insn	2, 0x0100
     c56:	0b05                	.insn	2, 0x0b05
     c58:	bd030647          	.insn	4, 0xbd030647
     c5c:	4a7c                	.insn	2, 0x4a7c
     c5e:	0505                	.insn	2, 0x0505
     c60:	0306                	.insn	2, 0x0306
     c62:	03c6                	.insn	2, 0x03c6
     c64:	0682                	.insn	2, 0x0682
     c66:	097cba03          	.insn	4, 0x097cba03
     c6a:	0008                	.insn	2, 0x0008
     c6c:	0601                	.insn	2, 0x0601
     c6e:	8203c603          	lbu	a2,-2016(t2)
     c72:	0306                	.insn	2, 0x0306
     c74:	7cba                	.insn	2, 0x7cba
     c76:	0809                	.insn	2, 0x0809
     c78:	0100                	.insn	2, 0x0100
     c7a:	1605                	.insn	2, 0x1605
     c7c:	0306                	.insn	2, 0x0306
     c7e:	03c9                	.insn	2, 0x03c9
     c80:	0682                	.insn	2, 0x0682
     c82:	4a7cb703          	.insn	4, 0x4a7cb703
     c86:	0306                	.insn	2, 0x0306
     c88:	03c9                	.insn	2, 0x03c9
     c8a:	06ba                	.insn	2, 0x06ba
     c8c:	097cb703          	.insn	4, 0x097cb703
     c90:	0008                	.insn	2, 0x0008
     c92:	0501                	.insn	2, 0x0501
     c94:	cd03060f          	.insn	4, 0xcd03060f
     c98:	1b058203          	lb	tp,432(a1) # 121b0 <start-0x3ede50>
     c9c:	08097d03          	.insn	4, 0x08097d03
     ca0:	0100                	.insn	2, 0x0100
     ca2:	0306                	.insn	2, 0x0306
     ca4:	7cb6                	.insn	2, 0x7cb6
     ca6:	0809                	.insn	2, 0x0809
     ca8:	0100                	.insn	2, 0x0100
     caa:	0f05                	.insn	2, 0x0f05
     cac:	0306                	.insn	2, 0x0306
     cae:	03cd                	.insn	2, 0x03cd
     cb0:	0582                	.insn	2, 0x0582
     cb2:	097e031b          	.insn	4, 0x097e031b
     cb6:	0008                	.insn	2, 0x0008
     cb8:	0601                	.insn	2, 0x0601
     cba:	097cb503          	.insn	4, 0x097cb503
     cbe:	0008                	.insn	2, 0x0008
     cc0:	0501                	.insn	2, 0x0501
     cc2:	cd03060f          	.insn	4, 0xcd03060f
     cc6:	0c058203          	lb	tp,192(a1)
     cca:	04097903          	.insn	4, 0x04097903
     cce:	0100                	.insn	2, 0x0100
     cd0:	0f05                	.insn	2, 0x0f05
     cd2:	0552                	.insn	2, 0x0552
     cd4:	0616                	.insn	2, 0x0616
     cd6:	054a                	.insn	2, 0x054a
     cd8:	0605                	.insn	2, 0x0605
     cda:	034a7803          	.insn	4, 0x034a7803
     cde:	090a                	.insn	2, 0x090a
     ce0:	0008                	.insn	2, 0x0008
     ce2:	0501                	.insn	2, 0x0501
     ce4:	0300                	.insn	2, 0x0300
     ce6:	0905                	.insn	2, 0x0905
     ce8:	0004                	.insn	2, 0x0004
     cea:	0501                	.insn	2, 0x0501
     cec:	064b0a0b          	.insn	4, 0x064b0a0b
     cf0:	097caa03          	lw	s4,151(s9)
     cf4:	0004                	.insn	2, 0x0004
     cf6:	0501                	.insn	2, 0x0501
     cf8:	0601                	.insn	2, 0x0601
     cfa:	4a03dd03          	lhu	s10,1184(t2)
     cfe:	0306                	.insn	2, 0x0306
     d00:	054a7ca3          	.insn	4, 0x054a7ca3
     d04:	0605                	.insn	2, 0x0605
     d06:	ba03d803          	lhu	a6,-1120(t2)
     d0a:	0306                	.insn	2, 0x0306
     d0c:	7ca8                	.insn	2, 0x7ca8
     d0e:	0409                	.insn	2, 0x0409
     d10:	0100                	.insn	2, 0x0100
     d12:	0f05                	.insn	2, 0x0f05
     d14:	0306                	.insn	2, 0x0306
     d16:	03d9                	.insn	2, 0x03d9
     d18:	054a                	.insn	2, 0x054a
     d1a:	054a0613          	addi	a2,s4,84
     d1e:	7f030627          	.insn	4, 0x7f030627
     d22:	0409                	.insn	2, 0x0409
     d24:	0100                	.insn	2, 0x0100
     d26:	1c05                	.insn	2, 0x1c05
     d28:	4a06                	.insn	2, 0x4a06
     d2a:	0505                	.insn	2, 0x0505
     d2c:	054a                	.insn	2, 0x054a
     d2e:	0601                	.insn	2, 0x0601
     d30:	04090503          	lb	a0,64(s2)
     d34:	0100                	.insn	2, 0x0100
     d36:	0505                	.insn	2, 0x0505
     d38:	030a                	.insn	2, 0x030a
     d3a:	040900cb          	.insn	4, 0x040900cb
     d3e:	0100                	.insn	2, 0x0100
     d40:	0ac2                	.insn	2, 0x0ac2
     d42:	08090603          	lb	a2,128(s2)
     d46:	0100                	.insn	2, 0x0100
     d48:	0ac2                	.insn	2, 0x0ac2
     d4a:	0900e903          	.insn	4, 0x0900e903
     d4e:	0008                	.insn	2, 0x0008
     d50:	8901                	.insn	2, 0x8901
     d52:	030a                	.insn	2, 0x030a
     d54:	092c                	.insn	2, 0x092c
     d56:	0004                	.insn	2, 0x0004
     d58:	8901                	.insn	2, 0x8901
     d5a:	0402                	.insn	2, 0x0402
     d5c:	0100                	.insn	2, 0x0100
     d5e:	0501                	.insn	2, 0x0501
     d60:	0a05                	.insn	2, 0x0a05
     d62:	0500                	.insn	2, 0x0500
     d64:	0002                	.insn	2, 0x0002
     d66:	4000                	.insn	2, 0x4000
     d68:	0300                	.insn	2, 0x0300
     d6a:	020105e7          	jalr	a1,32(sp)
     d6e:	001c                	.insn	2, 0x001c
     d70:	0101                	.insn	2, 0x0101
     d72:	0845                	.insn	2, 0x0845
     d74:	0000                	.insn	2, 0x0000
     d76:	0005                	.insn	2, 0x0005
     d78:	0004                	.insn	2, 0x0004
     d7a:	007a                	.insn	2, 0x007a
     d7c:	0000                	.insn	2, 0x0000
     d7e:	0101                	.insn	2, 0x0101
     d80:	fb01                	.insn	2, 0xfb01
     d82:	0d0e                	.insn	2, 0x0d0e
     d84:	0100                	.insn	2, 0x0100
     d86:	0101                	.insn	2, 0x0101
     d88:	0001                	.insn	2, 0x0001
     d8a:	0000                	.insn	2, 0x0000
     d8c:	0001                	.insn	2, 0x0001
     d8e:	0100                	.insn	2, 0x0100
     d90:	0101                	.insn	2, 0x0101
     d92:	021f 0000 0000      	.insn	6, 0x021f
     d98:	0035                	.insn	2, 0x0035
     d9a:	0000                	.insn	2, 0x0000
     d9c:	021f0103          	lb	sp,33(t5)
     da0:	041e050f          	.insn	4, 0x041e050f
     da4:	009c                	.insn	2, 0x009c
     da6:	0000                	.insn	2, 0x0000
     da8:	3600                	.insn	2, 0x3600
     daa:	f9e5                	.insn	2, 0xf9e5
     dac:	6905                	.insn	2, 0x6905
     dae:	2600a817          	auipc	a6,0x2600a
     db2:	a1e5                	.insn	2, 0xa1e5
     db4:	8d59                	.insn	2, 0x8d59
     db6:	de40                	.insn	2, 0xde40
     db8:	0000a067          	.insn	4, 0xa067
     dbc:	0100                	.insn	2, 0x0100
     dbe:	e536                	.insn	2, 0xe536
     dc0:	05f9                	.insn	2, 0x05f9
     dc2:	1769                	.insn	2, 0x1769
     dc4:	00a8                	.insn	2, 0x00a8
     dc6:	e526                	.insn	2, 0xe526
     dc8:	59a1                	.insn	2, 0x59a1
     dca:	408d                	.insn	2, 0x408d
     dcc:	67de                	.insn	2, 0x67de
     dce:	00000047          	.insn	4, 0x0047
     dd2:	3701                	.insn	2, 0x3701
     dd4:	0bd2                	.insn	2, 0x0bd2
     dd6:	88f9524b          	.insn	4, 0x88f9524b
     dda:	a3c4                	.insn	2, 0xa3c4
     ddc:	2a19                	.insn	2, 0x2a19
     dde:	f27f                	.insn	2, 0xf27f
     de0:	4e87d623          	.insn	4, 0x4e87d623
     de4:	0000                	.insn	2, 0x0000
     de6:	0100                	.insn	2, 0x0100
     de8:	8925                	.insn	2, 0x8925
     dea:	ef25                	.insn	2, 0xef25
     dec:	9699                	.insn	2, 0x9699
     dee:	84d0                	.insn	2, 0x84d0
     df0:	8c71                	.insn	2, 0x8c71
     df2:	b17c                	.insn	2, 0xb17c
     df4:	b91c                	.insn	2, 0xb91c
     df6:	0500e2fb          	.insn	4, 0x0500e2fb
     dfa:	b002                	.insn	2, 0xb002
     dfc:	4012                	.insn	2, 0x4012
     dfe:	1a00                	.insn	2, 0x1a00
     e00:	0905                	.insn	2, 0x0905
     e02:	080a                	.insn	2, 0x080a
     e04:	0342                	.insn	2, 0x0342
     e06:	00140903          	lb	s2,1(s0)
     e0a:	0301                	.insn	2, 0x0301
     e0c:	0901                	.insn	2, 0x0901
     e0e:	0018                	.insn	2, 0x0018
     e10:	0601                	.insn	2, 0x0601
     e12:	06f26d03          	.insn	4, 0x06f26d03
     e16:	054a1403          	lh	s0,84(s4)
     e1a:	4e18                	.insn	2, 0x4e18
     e1c:	1405                	.insn	2, 0x1405
     e1e:	4a00e403          	.insn	4, 0x4a00e403
     e22:	4884                	.insn	2, 0x4884
     e24:	1505                	.insn	2, 0x1505
     e26:	061a054b          	.insn	4, 0x061a054b
     e2a:	054a                	.insn	2, 0x054a
     e2c:	061f 0549 0309      	.insn	6, 0x03090549061f
     e32:	7f9e                	.insn	2, 0x7f9e
     e34:	064a                	.insn	2, 0x064a
     e36:	18096603          	.insn	4, 0x18096603
     e3a:	0100                	.insn	2, 0x0100
     e3c:	0505                	.insn	2, 0x0505
     e3e:	0306                	.insn	2, 0x0306
     e40:	4a1d                	.insn	2, 0x4a1d
     e42:	0306                	.insn	2, 0x0306
     e44:	00100963          	beq	zero,ra,e56 <start-0x3ff1aa>
     e48:	0601                	.insn	2, 0x0601
     e4a:	05821d03          	lh	s10,88(tp) # 58 <start-0x3fffa8>
     e4e:	8711                	.insn	2, 0x8711
     e50:	0905                	.insn	2, 0x0905
     e52:	4a06                	.insn	2, 0x4a06
     e54:	0505                	.insn	2, 0x0505
     e56:	7d06                	.insn	2, 0x7d06
     e58:	08090803          	lb	a6,128(s2)
     e5c:	0100                	.insn	2, 0x0100
     e5e:	0306                	.insn	2, 0x0306
     e60:	0105ba5b          	.insn	4, 0x0105ba5b
     e64:	0b06                	.insn	2, 0x0b06
     e66:	054a2803          	lw	a6,84(s4)
     e6a:	0300                	.insn	2, 0x0300
     e6c:	00da                	.insn	2, 0x00da
     e6e:	1409                	.insn	2, 0x1409
     e70:	0100                	.insn	2, 0x0100
     e72:	0905                	.insn	2, 0x0905
     e74:	080a                	.insn	2, 0x080a
     e76:	fb03063f 033c087e 	.insn	8, 0x033c087efb03063f
     e7e:	0185                	.insn	2, 0x0185
     e80:	054a                	.insn	2, 0x054a
     e82:	0614                	.insn	2, 0x0614
     e84:	04090403          	lb	s0,64(s2)
     e88:	0100                	.insn	2, 0x0100
     e8a:	0584                	.insn	2, 0x0584
     e8c:	4820                	.insn	2, 0x4820
     e8e:	0a05                	.insn	2, 0x0a05
     e90:	054d                	.insn	2, 0x054d
     e92:	491f 2505 0549      	.insn	6, 0x05492505491f
     e98:	4914                	.insn	2, 0x4914
     e9a:	1f05                	.insn	2, 0x1f05
     e9c:	054d                	.insn	2, 0x054d
     e9e:	4926                	.insn	2, 0x4926
     ea0:	1605                	.insn	2, 0x1605
     ea2:	50090547          	.insn	4, 0x50090547
     ea6:	0306                	.insn	2, 0x0306
     ea8:	7ef2                	.insn	2, 0x7ef2
     eaa:	0c09                	.insn	2, 0x0c09
     eac:	0100                	.insn	2, 0x0100
     eae:	1105                	.insn	2, 0x1105
     eb0:	0306                	.insn	2, 0x0306
     eb2:	01a8                	.insn	2, 0x01a8
     eb4:	054a                	.insn	2, 0x054a
     eb6:	031d                	.insn	2, 0x031d
     eb8:	4a6a                	.insn	2, 0x4a6a
     eba:	1305                	.insn	2, 0x1305
     ebc:	054e                	.insn	2, 0x054e
     ebe:	13054f23          	.insn	4, 0x13054f23
     ec2:	054e                	.insn	2, 0x054e
     ec4:	031a                	.insn	2, 0x031a
     ec6:	4a09                	.insn	2, 0x4a09
     ec8:	2705                	.insn	2, 0x2705
     eca:	054d                	.insn	2, 0x054d
     ecc:	4a790323          	sb	t2,1190(s2)
     ed0:	1b05                	.insn	2, 0x1b05
     ed2:	0551                	.insn	2, 0x0551
     ed4:	18054617          	auipc	a2,0x18054
     ed8:	054d                	.insn	2, 0x054d
     eda:	031a                	.insn	2, 0x031a
     edc:	21054a77          	.insn	4, 0x21054a77
     ee0:	03010547          	.insn	4, 0x03010547
     ee4:	4a10                	.insn	2, 0x4a10
     ee6:	0b06                	.insn	2, 0x0b06
     ee8:	054a                	.insn	2, 0x054a
     eea:	0600                	.insn	2, 0x0600
     eec:	097f8003          	lb	zero,151(t6)
     ef0:	0018                	.insn	2, 0x0018
     ef2:	0501                	.insn	2, 0x0501
     ef4:	0a09                	.insn	2, 0x0a09
     ef6:	4002                	.insn	2, 0x4002
     ef8:	0615                	.insn	2, 0x0615
     efa:	03824f03          	lbu	t5,56(tp) # 38 <start-0x3fffc8>
     efe:	4a31                	.insn	2, 0x4a31
     f00:	2005                	.insn	2, 0x2005
     f02:	0306                	.insn	2, 0x0306
     f04:	0904                	.insn	2, 0x0904
     f06:	0004                	.insn	2, 0x0004
     f08:	0501                	.insn	2, 0x0501
     f0a:	0314                	.insn	2, 0x0314
     f0c:	00c9                	.insn	2, 0x00c9
     f0e:	48ba                	.insn	2, 0x48ba
     f10:	1505                	.insn	2, 0x1505
     f12:	061a054b          	.insn	4, 0x061a054b
     f16:	054a                	.insn	2, 0x054a
     f18:	061f 0549 0309      	.insn	6, 0x03090549061f
     f1e:	054a7fbb          	.insn	4, 0x054a7fbb
     f22:	0301                	.insn	2, 0x0301
     f24:	00c1                	.insn	2, 0x00c1
     f26:	1009                	.insn	2, 0x1009
     f28:	0100                	.insn	2, 0x0100
     f2a:	0b06                	.insn	2, 0x0b06
     f2c:	034a                	.insn	2, 0x034a
     f2e:	7f88                	.insn	2, 0x7f88
     f30:	3802                	.insn	2, 0x3802
     f32:	0501                	.insn	2, 0x0501
     f34:	0620                	.insn	2, 0x0620
     f36:	0800da03          	lhu	s4,128(ra)
     f3a:	05e4                	.insn	2, 0x05e4
     f3c:	0615                	.insn	2, 0x0615
     f3e:	054a                	.insn	2, 0x054a
     f40:	4a24                	.insn	2, 0x4a24
     f42:	0905                	.insn	2, 0x0905
     f44:	4e06                	.insn	2, 0x4e06
     f46:	1605                	.insn	2, 0x1605
     f48:	4a06                	.insn	2, 0x4a06
     f4a:	0d05                	.insn	2, 0x0d05
     f4c:	4c06                	.insn	2, 0x4c06
     f4e:	2505                	.insn	2, 0x2505
     f50:	f206                	.insn	2, 0xf206
     f52:	1705                	.insn	2, 0x1705
     f54:	0306                	.insn	2, 0x0306
     f56:	095a                	.insn	2, 0x095a
     f58:	0004                	.insn	2, 0x0004
     f5a:	0501                	.insn	2, 0x0501
     f5c:	0605                	.insn	2, 0x0605
     f5e:	0582                	.insn	2, 0x0582
     f60:	060d                	.insn	2, 0x060d
     f62:	04090503          	lb	a0,64(s2)
     f66:	0100                	.insn	2, 0x0100
     f68:	1205                	.insn	2, 0x1205
     f6a:	4a06                	.insn	2, 0x4a06
     f6c:	0d05                	.insn	2, 0x0d05
     f6e:	0306                	.insn	2, 0x0306
     f70:	0908                	.insn	2, 0x0908
     f72:	0008                	.insn	2, 0x0008
     f74:	0501                	.insn	2, 0x0501
     f76:	054a0613          	addi	a2,s4,84
     f7a:	0616                	.insn	2, 0x0616
     f7c:	04090803          	lb	a6,64(s2)
     f80:	0100                	.insn	2, 0x0100
     f82:	0306                	.insn	2, 0x0306
     f84:	7fb1                	.insn	2, 0x7fb1
     f86:	0409                	.insn	2, 0x0409
     f88:	0100                	.insn	2, 0x0100
     f8a:	1105                	.insn	2, 0x1105
     f8c:	4a00cf03          	lbu	t5,1184(ra)
     f90:	1605                	.insn	2, 0x1605
     f92:	054a                	.insn	2, 0x054a
     f94:	0620                	.insn	2, 0x0620
     f96:	08090103          	lb	sp,128(s2)
     f9a:	0100                	.insn	2, 0x0100
     f9c:	1105                	.insn	2, 0x1105
     f9e:	0581                	.insn	2, 0x0581
     fa0:	0616                	.insn	2, 0x0616
     fa2:	054a                	.insn	2, 0x054a
     fa4:	0620                	.insn	2, 0x0620
     fa6:	04090103          	lb	sp,64(s2)
     faa:	0100                	.insn	2, 0x0100
     fac:	1c05                	.insn	2, 0x1c05
     fae:	4a06                	.insn	2, 0x4a06
     fb0:	2005                	.insn	2, 0x2005
     fb2:	054a                	.insn	2, 0x054a
     fb4:	0611                	.insn	2, 0x0611
     fb6:	0549                	.insn	2, 0x0549
     fb8:	0616                	.insn	2, 0x0616
     fba:	054a                	.insn	2, 0x054a
     fbc:	0311                	.insn	2, 0x0311
     fbe:	0900                	.insn	2, 0x0900
     fc0:	0004                	.insn	2, 0x0004
     fc2:	0501                	.insn	2, 0x0501
     fc4:	4a16                	.insn	2, 0x4a16
     fc6:	1105                	.insn	2, 0x1105
     fc8:	04090003          	lb	zero,64(s2)
     fcc:	0100                	.insn	2, 0x0100
     fce:	1605                	.insn	2, 0x1605
     fd0:	054a                	.insn	2, 0x054a
     fd2:	0311                	.insn	2, 0x0311
     fd4:	0900                	.insn	2, 0x0900
     fd6:	0004                	.insn	2, 0x0004
     fd8:	0501                	.insn	2, 0x0501
     fda:	4a16                	.insn	2, 0x4a16
     fdc:	1105                	.insn	2, 0x1105
     fde:	04090003          	lb	zero,64(s2)
     fe2:	0100                	.insn	2, 0x0100
     fe4:	1605                	.insn	2, 0x1605
     fe6:	054a                	.insn	2, 0x054a
     fe8:	0311                	.insn	2, 0x0311
     fea:	0900                	.insn	2, 0x0900
     fec:	0004                	.insn	2, 0x0004
     fee:	0501                	.insn	2, 0x0501
     ff0:	4a16                	.insn	2, 0x4a16
     ff2:	0d05                	.insn	2, 0x0d05
     ff4:	0306                	.insn	2, 0x0306
     ff6:	0905                	.insn	2, 0x0905
     ff8:	0004                	.insn	2, 0x0004
     ffa:	0501                	.insn	2, 0x0501
     ffc:	0612                	.insn	2, 0x0612
     ffe:	054a                	.insn	2, 0x054a
    1000:	0611                	.insn	2, 0x0611
    1002:	08097c03          	.insn	4, 0x08097c03
    1006:	0100                	.insn	2, 0x0100
    1008:	1c05                	.insn	2, 0x1c05
    100a:	4a06                	.insn	2, 0x4a06
    100c:	2005                	.insn	2, 0x2005
    100e:	054a                	.insn	2, 0x054a
    1010:	0611                	.insn	2, 0x0611
    1012:	0549                	.insn	2, 0x0549
    1014:	0616                	.insn	2, 0x0616
    1016:	054a                	.insn	2, 0x054a
    1018:	0611                	.insn	2, 0x0611
    101a:	04090103          	lb	sp,64(s2)
    101e:	0100                	.insn	2, 0x0100
    1020:	1c05                	.insn	2, 0x1c05
    1022:	4a06                	.insn	2, 0x4a06
    1024:	2005                	.insn	2, 0x2005
    1026:	054a                	.insn	2, 0x054a
    1028:	0611                	.insn	2, 0x0611
    102a:	0549                	.insn	2, 0x0549
    102c:	0616                	.insn	2, 0x0616
    102e:	054a                	.insn	2, 0x054a
    1030:	0611                	.insn	2, 0x0611
    1032:	04090103          	lb	sp,64(s2)
    1036:	0100                	.insn	2, 0x0100
    1038:	1c05                	.insn	2, 0x1c05
    103a:	4a06                	.insn	2, 0x4a06
    103c:	2005                	.insn	2, 0x2005
    103e:	054a                	.insn	2, 0x054a
    1040:	0611                	.insn	2, 0x0611
    1042:	0549                	.insn	2, 0x0549
    1044:	0616                	.insn	2, 0x0616
    1046:	054a                	.insn	2, 0x054a
    1048:	0611                	.insn	2, 0x0611
    104a:	04090103          	lb	sp,64(s2)
    104e:	0100                	.insn	2, 0x0100
    1050:	1c05                	.insn	2, 0x1c05
    1052:	4a06                	.insn	2, 0x4a06
    1054:	2005                	.insn	2, 0x2005
    1056:	054a                	.insn	2, 0x054a
    1058:	0611                	.insn	2, 0x0611
    105a:	0549                	.insn	2, 0x0549
    105c:	0616                	.insn	2, 0x0616
    105e:	054a                	.insn	2, 0x054a
    1060:	0611                	.insn	2, 0x0611
    1062:	04090103          	lb	sp,64(s2)
    1066:	0100                	.insn	2, 0x0100
    1068:	1c05                	.insn	2, 0x1c05
    106a:	4a06                	.insn	2, 0x4a06
    106c:	2005                	.insn	2, 0x2005
    106e:	054a                	.insn	2, 0x054a
    1070:	0611                	.insn	2, 0x0611
    1072:	0549                	.insn	2, 0x0549
    1074:	0616                	.insn	2, 0x0616
    1076:	054a                	.insn	2, 0x054a
    1078:	0611                	.insn	2, 0x0611
    107a:	04090103          	lb	sp,64(s2)
    107e:	0100                	.insn	2, 0x0100
    1080:	1c05                	.insn	2, 0x1c05
    1082:	4a06                	.insn	2, 0x4a06
    1084:	2005                	.insn	2, 0x2005
    1086:	054a                	.insn	2, 0x054a
    1088:	060d                	.insn	2, 0x060d
    108a:	054e                	.insn	2, 0x054e
    108c:	0612                	.insn	2, 0x0612
    108e:	054a                	.insn	2, 0x054a
    1090:	0615                	.insn	2, 0x0615
    1092:	04090503          	lb	a0,64(s2)
    1096:	0100                	.insn	2, 0x0100
    1098:	0d05                	.insn	2, 0x0d05
    109a:	061c0547          	.insn	4, 0x061c0547
    109e:	054a                	.insn	2, 0x054a
    10a0:	0624                	.insn	2, 0x0624
    10a2:	054e                	.insn	2, 0x054e
    10a4:	0620                	.insn	2, 0x0620
    10a6:	054a                	.insn	2, 0x054a
    10a8:	061a                	.insn	2, 0x061a
    10aa:	0549                	.insn	2, 0x0549
    10ac:	0315                	.insn	2, 0x0315
    10ae:	0901                	.insn	2, 0x0901
    10b0:	0004                	.insn	2, 0x0004
    10b2:	0501                	.insn	2, 0x0501
    10b4:	0620                	.insn	2, 0x0620
    10b6:	054a                	.insn	2, 0x054a
    10b8:	4a24                	.insn	2, 0x4a24
    10ba:	1505                	.insn	2, 0x1505
    10bc:	8106                	.insn	2, 0x8106
    10be:	1a05                	.insn	2, 0x1a05
    10c0:	4a06                	.insn	2, 0x4a06
    10c2:	097fa703          	lw	a4,151(t6)
    10c6:	0004                	.insn	2, 0x0004
    10c8:	0301                	.insn	2, 0x0301
    10ca:	00d9                	.insn	2, 0x00d9
    10cc:	034a                	.insn	2, 0x034a
    10ce:	054a7fa7          	.insn	4, 0x054a7fa7
    10d2:	0612                	.insn	2, 0x0612
    10d4:	4a00e403          	.insn	4, 0x4a00e403
    10d8:	1c05                	.insn	2, 0x1c05
    10da:	4e49                	.insn	2, 0x4e49
    10dc:	4d18054b          	.insn	4, 0x4d18054b
    10e0:	2305                	.insn	2, 0x2305
    10e2:	057e                	.insn	2, 0x057e
    10e4:	4b22                	.insn	2, 0x4b22
    10e6:	1805                	.insn	2, 0x1805
    10e8:	054d                	.insn	2, 0x054d
    10ea:	061f 054a 0616      	.insn	6, 0x0616054a061f
    10f0:	0549                	.insn	2, 0x0549
    10f2:	4f1c                	.insn	2, 0x4f1c
    10f4:	4b12054b          	.insn	4, 0x4b12054b
    10f8:	1c05                	.insn	2, 0x1c05
    10fa:	4b220547          	.insn	4, 0x4b220547
    10fe:	23054b4b          	.insn	4, 0x23054b4b
    1102:	4b280547          	.insn	4, 0x4b280547
    1106:	2905                	.insn	2, 0x2905
    1108:	4713054b          	.insn	4, 0x4713054b
    110c:	1405                	.insn	2, 0x1405
    110e:	030a                	.insn	2, 0x030a
    1110:	0008090f          	.insn	4, 0x0008090f
    1114:	8401                	.insn	2, 0x8401
    1116:	0548                	.insn	2, 0x0548
    1118:	4b15                	.insn	2, 0x4b15
    111a:	1a05                	.insn	2, 0x1a05
    111c:	4a06                	.insn	2, 0x4a06
    111e:	1f05                	.insn	2, 0x1f05
    1120:	4906                	.insn	2, 0x4906
    1122:	0505                	.insn	2, 0x0505
    1124:	4a06                	.insn	2, 0x4a06
    1126:	0005                	.insn	2, 0x0005
    1128:	0306                	.insn	2, 0x0306
    112a:	0935                	.insn	2, 0x0935
    112c:	0004                	.insn	2, 0x0004
    112e:	0501                	.insn	2, 0x0501
    1130:	0a09                	.insn	2, 0x0a09
    1132:	2c02                	.insn	2, 0x2c02
    1134:	0515                	.insn	2, 0x0515
    1136:	0320                	.insn	2, 0x0320
    1138:	0904                	.insn	2, 0x0904
    113a:	000c                	.insn	2, 0x000c
    113c:	0501                	.insn	2, 0x0501
    113e:	0314                	.insn	2, 0x0314
    1140:	ba46                	.insn	2, 0xba46
    1142:	0548                	.insn	2, 0x0548
    1144:	4b15                	.insn	2, 0x4b15
    1146:	1a05                	.insn	2, 0x1a05
    1148:	4a06                	.insn	2, 0x4a06
    114a:	1f05                	.insn	2, 0x1f05
    114c:	4906                	.insn	2, 0x4906
    114e:	0905                	.insn	2, 0x0905
    1150:	054a3e03          	.insn	4, 0x054a3e03
    1154:	0b01                	.insn	2, 0x0b01
    1156:	10093b03          	.insn	4, 0x10093b03
    115a:	0100                	.insn	2, 0x0100
    115c:	0306                	.insn	2, 0x0306
    115e:	30027e8b          	.insn	4, 0x30027e8b
    1162:	0501                	.insn	2, 0x0501
    1164:	0614                	.insn	2, 0x0614
    1166:	0200fe03          	.insn	4, 0x0200fe03
    116a:	012c                	.insn	2, 0x012c
    116c:	0548                	.insn	2, 0x0548
    116e:	4b15                	.insn	2, 0x4b15
    1170:	1a05                	.insn	2, 0x1a05
    1172:	4a06                	.insn	2, 0x4a06
    1174:	1f05                	.insn	2, 0x1f05
    1176:	4906                	.insn	2, 0x4906
    1178:	1805                	.insn	2, 0x1805
    117a:	4a00ef03          	.insn	4, 0x4a00ef03
    117e:	4c49                	.insn	2, 0x4c49
    1180:	0e05                	.insn	2, 0x0e05
    1182:	481e054b          	.insn	4, 0x481e054b
    1186:	1f05                	.insn	2, 0x1f05
    1188:	0549                	.insn	2, 0x0549
    118a:	4c1e                	.insn	2, 0x4c1e
    118c:	4824054b          	.insn	4, 0x4824054b
    1190:	2505                	.insn	2, 0x2505
    1192:	4e09054b          	.insn	4, 0x4e09054b
    1196:	1705                	.insn	2, 0x1705
    1198:	05ba4d03          	lbu	s10,91(s4)
    119c:	0605                	.insn	2, 0x0605
    119e:	0582                	.insn	2, 0x0582
    11a0:	060d                	.insn	2, 0x060d
    11a2:	04090403          	lb	s0,64(s2)
    11a6:	0100                	.insn	2, 0x0100
    11a8:	1205                	.insn	2, 0x1205
    11aa:	4a06                	.insn	2, 0x4a06
    11ac:	0d05                	.insn	2, 0x0d05
    11ae:	0306                	.insn	2, 0x0306
    11b0:	0906                	.insn	2, 0x0906
    11b2:	0008                	.insn	2, 0x0008
    11b4:	0501                	.insn	2, 0x0501
    11b6:	054a0613          	addi	a2,s4,84
    11ba:	0616                	.insn	2, 0x0616
    11bc:	04090403          	lb	s0,64(s2)
    11c0:	0100                	.insn	2, 0x0100
    11c2:	1105                	.insn	2, 0x1105
    11c4:	0306                	.insn	2, 0x0306
    11c6:	0900                	.insn	2, 0x0900
    11c8:	0004                	.insn	2, 0x0004
    11ca:	0501                	.insn	2, 0x0501
    11cc:	4a16                	.insn	2, 0x4a16
    11ce:	1105                	.insn	2, 0x1105
    11d0:	04090003          	lb	zero,64(s2)
    11d4:	0100                	.insn	2, 0x0100
    11d6:	1605                	.insn	2, 0x1605
    11d8:	054a                	.insn	2, 0x054a
    11da:	0311                	.insn	2, 0x0311
    11dc:	0900                	.insn	2, 0x0900
    11de:	0004                	.insn	2, 0x0004
    11e0:	0501                	.insn	2, 0x0501
    11e2:	4a16                	.insn	2, 0x4a16
    11e4:	1105                	.insn	2, 0x1105
    11e6:	04090003          	lb	zero,64(s2)
    11ea:	0100                	.insn	2, 0x0100
    11ec:	1605                	.insn	2, 0x1605
    11ee:	054a                	.insn	2, 0x054a
    11f0:	0311                	.insn	2, 0x0311
    11f2:	0900                	.insn	2, 0x0900
    11f4:	0004                	.insn	2, 0x0004
    11f6:	0501                	.insn	2, 0x0501
    11f8:	4a16                	.insn	2, 0x4a16
    11fa:	1105                	.insn	2, 0x1105
    11fc:	04090003          	lb	zero,64(s2)
    1200:	0100                	.insn	2, 0x0100
    1202:	1605                	.insn	2, 0x1605
    1204:	054a                	.insn	2, 0x054a
    1206:	0311                	.insn	2, 0x0311
    1208:	0900                	.insn	2, 0x0900
    120a:	0004                	.insn	2, 0x0004
    120c:	0501                	.insn	2, 0x0501
    120e:	4a16                	.insn	2, 0x4a16
    1210:	0d05                	.insn	2, 0x0d05
    1212:	0306                	.insn	2, 0x0306
    1214:	0904                	.insn	2, 0x0904
    1216:	0004                	.insn	2, 0x0004
    1218:	0501                	.insn	2, 0x0501
    121a:	0612                	.insn	2, 0x0612
    121c:	054a                	.insn	2, 0x054a
    121e:	0611                	.insn	2, 0x0611
    1220:	08097d03          	.insn	4, 0x08097d03
    1224:	0100                	.insn	2, 0x0100
    1226:	0581                	.insn	2, 0x0581
    1228:	0616                	.insn	2, 0x0616
    122a:	054a                	.insn	2, 0x054a
    122c:	0611                	.insn	2, 0x0611
    122e:	04090103          	lb	sp,64(s2)
    1232:	0100                	.insn	2, 0x0100
    1234:	0581                	.insn	2, 0x0581
    1236:	0616                	.insn	2, 0x0616
    1238:	054a                	.insn	2, 0x054a
    123a:	0611                	.insn	2, 0x0611
    123c:	04090103          	lb	sp,64(s2)
    1240:	0100                	.insn	2, 0x0100
    1242:	0581                	.insn	2, 0x0581
    1244:	0616                	.insn	2, 0x0616
    1246:	054a                	.insn	2, 0x054a
    1248:	0611                	.insn	2, 0x0611
    124a:	04090103          	lb	sp,64(s2)
    124e:	0100                	.insn	2, 0x0100
    1250:	0581                	.insn	2, 0x0581
    1252:	0616                	.insn	2, 0x0616
    1254:	054a                	.insn	2, 0x054a
    1256:	0611                	.insn	2, 0x0611
    1258:	04090103          	lb	sp,64(s2)
    125c:	0100                	.insn	2, 0x0100
    125e:	0581                	.insn	2, 0x0581
    1260:	0616                	.insn	2, 0x0616
    1262:	054a                	.insn	2, 0x054a
    1264:	0611                	.insn	2, 0x0611
    1266:	04090103          	lb	sp,64(s2)
    126a:	0100                	.insn	2, 0x0100
    126c:	0581                	.insn	2, 0x0581
    126e:	0616                	.insn	2, 0x0616
    1270:	054a                	.insn	2, 0x054a
    1272:	0611                	.insn	2, 0x0611
    1274:	04090103          	lb	sp,64(s2)
    1278:	0100                	.insn	2, 0x0100
    127a:	0581                	.insn	2, 0x0581
    127c:	0616                	.insn	2, 0x0616
    127e:	054a                	.insn	2, 0x054a
    1280:	0611                	.insn	2, 0x0611
    1282:	04090103          	lb	sp,64(s2)
    1286:	0100                	.insn	2, 0x0100
    1288:	0d05                	.insn	2, 0x0d05
    128a:	0585                	.insn	2, 0x0585
    128c:	0612                	.insn	2, 0x0612
    128e:	054a                	.insn	2, 0x054a
    1290:	060d                	.insn	2, 0x060d
    1292:	04090103          	lb	sp,64(s2)
    1296:	0100                	.insn	2, 0x0100
    1298:	1505                	.insn	2, 0x1505
    129a:	05bc                	.insn	2, 0x05bc
    129c:	061a                	.insn	2, 0x061a
    129e:	054a                	.insn	2, 0x054a
    12a0:	0315                	.insn	2, 0x0315
    12a2:	0900                	.insn	2, 0x0900
    12a4:	0004                	.insn	2, 0x0004
    12a6:	0501                	.insn	2, 0x0501
    12a8:	4a1a                	.insn	2, 0x4a1a
    12aa:	1505                	.insn	2, 0x1505
    12ac:	04090003          	lb	zero,64(s2)
    12b0:	0100                	.insn	2, 0x0100
    12b2:	1a05                	.insn	2, 0x1a05
    12b4:	054a                	.insn	2, 0x054a
    12b6:	0615                	.insn	2, 0x0615
    12b8:	04090103          	lb	sp,64(s2)
    12bc:	0100                	.insn	2, 0x0100
    12be:	2605                	.insn	2, 0x2605
    12c0:	0586                	.insn	2, 0x0586
    12c2:	0609                	.insn	2, 0x0609
    12c4:	054a                	.insn	2, 0x054a
    12c6:	0618                	.insn	2, 0x0618
    12c8:	05c2                	.insn	2, 0x05c2
    12ca:	460e                	.insn	2, 0x460e
    12cc:	1805                	.insn	2, 0x1805
    12ce:	4e49                	.insn	2, 0x4e49
    12d0:	1e05                	.insn	2, 0x1e05
    12d2:	4d14054b          	.insn	4, 0x4d14054b
    12d6:	1f05                	.insn	2, 0x1f05
    12d8:	057e                	.insn	2, 0x057e
    12da:	4e14                	.insn	2, 0x4e14
    12dc:	1b05                	.insn	2, 0x1b05
    12de:	4a06                	.insn	2, 0x4a06
    12e0:	1005                	.insn	2, 0x1005
    12e2:	4e06                	.insn	2, 0x4e06
    12e4:	0306                	.insn	2, 0x0306
    12e6:	7e9a                	.insn	2, 0x7e9a
    12e8:	0409                	.insn	2, 0x0409
    12ea:	0100                	.insn	2, 0x0100
    12ec:	4a01e603          	.insn	4, 0x4a01e603
    12f0:	1505                	.insn	2, 0x1505
    12f2:	0306                	.insn	2, 0x0306
    12f4:	4a6d                	.insn	2, 0x4a6d
    12f6:	0581                	.insn	2, 0x0581
    12f8:	061a                	.insn	2, 0x061a
    12fa:	054a                	.insn	2, 0x054a
    12fc:	0615                	.insn	2, 0x0615
    12fe:	04090103          	lb	sp,64(s2)
    1302:	0100                	.insn	2, 0x0100
    1304:	0581                	.insn	2, 0x0581
    1306:	061a                	.insn	2, 0x061a
    1308:	054a                	.insn	2, 0x054a
    130a:	0600                	.insn	2, 0x0600
    130c:	0900cc03          	lbu	s8,144(ra)
    1310:	0008                	.insn	2, 0x0008
    1312:	0501                	.insn	2, 0x0501
    1314:	0a09                	.insn	2, 0x0a09
    1316:	e708                	.insn	2, 0xe708
    1318:	0306                	.insn	2, 0x0306
    131a:	7ddf 0382 02a1      	.insn	6, 0x02a103827ddf
    1320:	054a                	.insn	2, 0x054a
    1322:	0620                	.insn	2, 0x0620
    1324:	04090403          	lb	s0,64(s2)
    1328:	0100                	.insn	2, 0x0100
    132a:	1405                	.insn	2, 0x1405
    132c:	ba7ed903          	lhu	s2,-1113(t4)
    1330:	0548                	.insn	2, 0x0548
    1332:	4b15                	.insn	2, 0x4b15
    1334:	1a05                	.insn	2, 0x1a05
    1336:	4a06                	.insn	2, 0x4a06
    1338:	1f05                	.insn	2, 0x1f05
    133a:	4906                	.insn	2, 0x4906
    133c:	0905                	.insn	2, 0x0905
    133e:	4a01ab03          	lw	s6,1184(gp)
    1342:	0306                	.insn	2, 0x0306
    1344:	7dd9                	.insn	2, 0x7dd9
    1346:	1809                	.insn	2, 0x1809
    1348:	0100                	.insn	2, 0x0100
    134a:	0c05                	.insn	2, 0x0c05
    134c:	0306                	.insn	2, 0x0306
    134e:	0284                	.insn	2, 0x0284
    1350:	054a                	.insn	2, 0x054a
    1352:	4510                	.insn	2, 0x4510
    1354:	1205                	.insn	2, 0x1205
    1356:	2c02                	.insn	2, 0x2c02
    1358:	fc030617          	auipc	a2,0xfc030
    135c:	097d                	.insn	2, 0x097d
    135e:	0004                	.insn	2, 0x0004
    1360:	0501                	.insn	2, 0x0501
    1362:	0619                	.insn	2, 0x0619
    1364:	f2028503          	lb	a0,-224(t0)
    1368:	0905                	.insn	2, 0x0905
    136a:	08090303          	lb	t1,128(s2)
    136e:	0100                	.insn	2, 0x0100
    1370:	1405                	.insn	2, 0x1405
    1372:	8206                	.insn	2, 0x8206
    1374:	0c05                	.insn	2, 0x0c05
    1376:	4606                	.insn	2, 0x4606
    1378:	1005                	.insn	2, 0x1005
    137a:	064e                	.insn	2, 0x064e
    137c:	4a7df803          	.insn	4, 0x4a7df803
    1380:	1205                	.insn	2, 0x1205
    1382:	0306                	.insn	2, 0x0306
    1384:	0284                	.insn	2, 0x0284
    1386:	054a                	.insn	2, 0x054a
    1388:	0305                	.insn	2, 0x0305
    138a:	0908                	.insn	2, 0x0908
    138c:	0004                	.insn	2, 0x0004
    138e:	0601                	.insn	2, 0x0601
    1390:	827df403          	.insn	4, 0x827df403
    1394:	1205                	.insn	2, 0x1205
    1396:	0306                	.insn	2, 0x0306
    1398:	0284                	.insn	2, 0x0284
    139a:	064a                	.insn	2, 0x064a
    139c:	4a7dfc03          	.insn	4, 0x4a7dfc03
    13a0:	0505                	.insn	2, 0x0505
    13a2:	0306                	.insn	2, 0x0306
    13a4:	028c                	.insn	2, 0x028c
    13a6:	054a                	.insn	2, 0x054a
    13a8:	0612                	.insn	2, 0x0612
    13aa:	0582                	.insn	2, 0x0582
    13ac:	030c                	.insn	2, 0x030c
    13ae:	0900                	.insn	2, 0x0900
    13b0:	0008                	.insn	2, 0x0008
    13b2:	0501                	.insn	2, 0x0501
    13b4:	4a05                	.insn	2, 0x4a05
    13b6:	1205                	.insn	2, 0x1205
    13b8:	054a                	.insn	2, 0x054a
    13ba:	0403060f          	.insn	4, 0x0403060f
    13be:	0409                	.insn	2, 0x0409
    13c0:	0100                	.insn	2, 0x0100
    13c2:	0c05                	.insn	2, 0x0c05
    13c4:	0588                	.insn	2, 0x0588
    13c6:	0605                	.insn	2, 0x0605
    13c8:	0382                	.insn	2, 0x0382
    13ca:	7dea                	.insn	2, 0x7dea
    13cc:	0409                	.insn	2, 0x0409
    13ce:	0100                	.insn	2, 0x0100
    13d0:	4a029603          	lh	a2,1184(t0)
    13d4:	1405                	.insn	2, 0x1405
    13d6:	8306                	.insn	2, 0x8306
    13d8:	0c05                	.insn	2, 0x0c05
    13da:	05b9                	.insn	2, 0x05b9
    13dc:	0605                	.insn	2, 0x0605
    13de:	054a                	.insn	2, 0x054a
    13e0:	0300                	.insn	2, 0x0300
    13e2:	7dea                	.insn	2, 0x7dea
    13e4:	0409                	.insn	2, 0x0409
    13e6:	0100                	.insn	2, 0x0100
    13e8:	0505                	.insn	2, 0x0505
    13ea:	4a029603          	lh	a2,1184(t0)
    13ee:	0d05                	.insn	2, 0x0d05
    13f0:	0306                	.insn	2, 0x0306
    13f2:	091c                	.insn	2, 0x091c
    13f4:	0008                	.insn	2, 0x0008
    13f6:	0501                	.insn	2, 0x0501
    13f8:	061a                	.insn	2, 0x061a
    13fa:	03ba                	.insn	2, 0x03ba
    13fc:	7dce                	.insn	2, 0x7dce
    13fe:	0409                	.insn	2, 0x0409
    1400:	0100                	.insn	2, 0x0100
    1402:	4a02b203          	.insn	4, 0x4a02b203
    1406:	0d05                	.insn	2, 0x0d05
    1408:	04090003          	lb	zero,64(s2)
    140c:	0100                	.insn	2, 0x0100
    140e:	1a05                	.insn	2, 0x1a05
    1410:	0382                	.insn	2, 0x0382
    1412:	7dce                	.insn	2, 0x7dce
    1414:	0409                	.insn	2, 0x0409
    1416:	0100                	.insn	2, 0x0100
    1418:	4a02b203          	.insn	4, 0x4a02b203
    141c:	0d05                	.insn	2, 0x0d05
    141e:	04090003          	lb	zero,64(s2)
    1422:	0100                	.insn	2, 0x0100
    1424:	1a05                	.insn	2, 0x1a05
    1426:	0382                	.insn	2, 0x0382
    1428:	7dce                	.insn	2, 0x7dce
    142a:	0409                	.insn	2, 0x0409
    142c:	0100                	.insn	2, 0x0100
    142e:	4a02b203          	.insn	4, 0x4a02b203
    1432:	0d05                	.insn	2, 0x0d05
    1434:	04090003          	lb	zero,64(s2)
    1438:	0100                	.insn	2, 0x0100
    143a:	1a05                	.insn	2, 0x1a05
    143c:	0382                	.insn	2, 0x0382
    143e:	7dce                	.insn	2, 0x7dce
    1440:	0409                	.insn	2, 0x0409
    1442:	0100                	.insn	2, 0x0100
    1444:	4a02b203          	.insn	4, 0x4a02b203
    1448:	0d05                	.insn	2, 0x0d05
    144a:	04090003          	lb	zero,64(s2)
    144e:	0100                	.insn	2, 0x0100
    1450:	1a05                	.insn	2, 0x1a05
    1452:	0382                	.insn	2, 0x0382
    1454:	7dce                	.insn	2, 0x7dce
    1456:	0409                	.insn	2, 0x0409
    1458:	0100                	.insn	2, 0x0100
    145a:	4a02b203          	.insn	4, 0x4a02b203
    145e:	0d05                	.insn	2, 0x0d05
    1460:	04090003          	lb	zero,64(s2)
    1464:	0100                	.insn	2, 0x0100
    1466:	1a05                	.insn	2, 0x1a05
    1468:	0382                	.insn	2, 0x0382
    146a:	7dce                	.insn	2, 0x7dce
    146c:	0409                	.insn	2, 0x0409
    146e:	0100                	.insn	2, 0x0100
    1470:	4a02b203          	.insn	4, 0x4a02b203
    1474:	0d05                	.insn	2, 0x0d05
    1476:	04090003          	lb	zero,64(s2)
    147a:	0100                	.insn	2, 0x0100
    147c:	1a05                	.insn	2, 0x1a05
    147e:	0382                	.insn	2, 0x0382
    1480:	7dce                	.insn	2, 0x7dce
    1482:	0409                	.insn	2, 0x0409
    1484:	0100                	.insn	2, 0x0100
    1486:	4a02b203          	.insn	4, 0x4a02b203
    148a:	0d05                	.insn	2, 0x0d05
    148c:	04090003          	lb	zero,64(s2)
    1490:	0100                	.insn	2, 0x0100
    1492:	1a05                	.insn	2, 0x1a05
    1494:	0382                	.insn	2, 0x0382
    1496:	7dce                	.insn	2, 0x7dce
    1498:	0409                	.insn	2, 0x0409
    149a:	0100                	.insn	2, 0x0100
    149c:	4a02b203          	.insn	4, 0x4a02b203
    14a0:	0d05                	.insn	2, 0x0d05
    14a2:	04090003          	lb	zero,64(s2)
    14a6:	0100                	.insn	2, 0x0100
    14a8:	1a05                	.insn	2, 0x1a05
    14aa:	0382                	.insn	2, 0x0382
    14ac:	7dce                	.insn	2, 0x7dce
    14ae:	0409                	.insn	2, 0x0409
    14b0:	0100                	.insn	2, 0x0100
    14b2:	4a02b203          	.insn	4, 0x4a02b203
    14b6:	0d05                	.insn	2, 0x0d05
    14b8:	04090003          	lb	zero,64(s2)
    14bc:	0100                	.insn	2, 0x0100
    14be:	1a05                	.insn	2, 0x1a05
    14c0:	0382                	.insn	2, 0x0382
    14c2:	7dce                	.insn	2, 0x7dce
    14c4:	0409                	.insn	2, 0x0409
    14c6:	0100                	.insn	2, 0x0100
    14c8:	4a02b203          	.insn	4, 0x4a02b203
    14cc:	0d05                	.insn	2, 0x0d05
    14ce:	04090003          	lb	zero,64(s2)
    14d2:	0100                	.insn	2, 0x0100
    14d4:	1a05                	.insn	2, 0x1a05
    14d6:	0382                	.insn	2, 0x0382
    14d8:	7dce                	.insn	2, 0x7dce
    14da:	0409                	.insn	2, 0x0409
    14dc:	0100                	.insn	2, 0x0100
    14de:	4a02b203          	.insn	4, 0x4a02b203
    14e2:	0d05                	.insn	2, 0x0d05
    14e4:	04090003          	lb	zero,64(s2)
    14e8:	0100                	.insn	2, 0x0100
    14ea:	1a05                	.insn	2, 0x1a05
    14ec:	0382                	.insn	2, 0x0382
    14ee:	7dce                	.insn	2, 0x7dce
    14f0:	0409                	.insn	2, 0x0409
    14f2:	0100                	.insn	2, 0x0100
    14f4:	4a02b203          	.insn	4, 0x4a02b203
    14f8:	0d05                	.insn	2, 0x0d05
    14fa:	04090003          	lb	zero,64(s2)
    14fe:	0100                	.insn	2, 0x0100
    1500:	1a05                	.insn	2, 0x1a05
    1502:	0382                	.insn	2, 0x0382
    1504:	7dce                	.insn	2, 0x7dce
    1506:	0409                	.insn	2, 0x0409
    1508:	0100                	.insn	2, 0x0100
    150a:	4a02b203          	.insn	4, 0x4a02b203
    150e:	0d05                	.insn	2, 0x0d05
    1510:	04090003          	lb	zero,64(s2)
    1514:	0100                	.insn	2, 0x0100
    1516:	1a05                	.insn	2, 0x1a05
    1518:	0382                	.insn	2, 0x0382
    151a:	7dce                	.insn	2, 0x7dce
    151c:	0409                	.insn	2, 0x0409
    151e:	0100                	.insn	2, 0x0100
    1520:	4a02b203          	.insn	4, 0x4a02b203
    1524:	0d05                	.insn	2, 0x0d05
    1526:	04090003          	lb	zero,64(s2)
    152a:	0100                	.insn	2, 0x0100
    152c:	1a05                	.insn	2, 0x1a05
    152e:	0382                	.insn	2, 0x0382
    1530:	7dce                	.insn	2, 0x7dce
    1532:	0409                	.insn	2, 0x0409
    1534:	0100                	.insn	2, 0x0100
    1536:	4a02b203          	.insn	4, 0x4a02b203
    153a:	0d05                	.insn	2, 0x0d05
    153c:	04090003          	lb	zero,64(s2)
    1540:	0100                	.insn	2, 0x0100
    1542:	1a05                	.insn	2, 0x1a05
    1544:	0382                	.insn	2, 0x0382
    1546:	7dce                	.insn	2, 0x7dce
    1548:	0409                	.insn	2, 0x0409
    154a:	0100                	.insn	2, 0x0100
    154c:	4a02b203          	.insn	4, 0x4a02b203
    1550:	1205                	.insn	2, 0x1205
    1552:	0306                	.insn	2, 0x0306
    1554:	0905                	.insn	2, 0x0905
    1556:	0004                	.insn	2, 0x0004
    1558:	0501                	.insn	2, 0x0501
    155a:	080a030f          	.insn	4, 0x080a030f
    155e:	4be4                	.insn	2, 0x4be4
    1560:	1205                	.insn	2, 0x1205
    1562:	054a7503          	.insn	4, 0x054a7503
    1566:	8614                	.insn	2, 0x8614
    1568:	1205                	.insn	2, 0x1205
    156a:	0806                	.insn	2, 0x0806
    156c:	05e4                	.insn	2, 0x05e4
    156e:	f214                	.insn	2, 0xf214
    1570:	1205                	.insn	2, 0x1205
    1572:	03ba                	.insn	2, 0x03ba
    1574:	7dc5                	.insn	2, 0x7dc5
    1576:	06f2                	.insn	2, 0x06f2
    1578:	4a02b703          	.insn	4, 0x4a02b703
    157c:	0f05                	.insn	2, 0x0f05
    157e:	4b820c03          	lb	s8,1208(tp) # 4b8 <start-0x3ffb48>
    1582:	1205                	.insn	2, 0x1205
    1584:	054a7703          	.insn	4, 0x054a7703
    1588:	0903bd0f          	.insn	4, 0x0903bd0f
    158c:	4b4a                	.insn	2, 0x4b4a
    158e:	09054b4b          	.insn	4, 0x09054b4b
    1592:	fa4c                	.insn	2, 0xfa4c
    1594:	0d05                	.insn	2, 0x0d05
    1596:	06f4                	.insn	2, 0x06f4
    1598:	097daa03          	lw	s4,151(s11)
    159c:	0014                	.insn	2, 0x0014
    159e:	0501                	.insn	2, 0x0501
    15a0:	0609                	.insn	2, 0x0609
    15a2:	8202d903          	lhu	s2,-2016(t0)
    15a6:	0306                	.insn	2, 0x0306
    15a8:	3c087da7          	.insn	4, 0x3c087da7
    15ac:	0105                	.insn	2, 0x0105
    15ae:	0306                	.insn	2, 0x0306
    15b0:	02df 064a 4a0b      	.insn	6, 0x4a0b064a02df
    15b6:	2002                	.insn	2, 0x2002
    15b8:	0100                	.insn	2, 0x0100
    15ba:	01                	.byte	0x01

Disassembly of section .debug_line_str:

00000000 <.debug_line_str>:
   0:	6d6f682f          	.insn	4, 0x6d6f682f
   4:	2f65                	.insn	2, 0x2f65
   6:	6168                	.insn	2, 0x6168
   8:	7572                	.insn	2, 0x7572
   a:	6968                	.insn	2, 0x6968
   c:	502f6f6b          	.insn	4, 0x502f6f6b
  10:	6f72                	.insn	2, 0x6f72
  12:	6d617267          	.insn	4, 0x6d617267
  16:	4353502f          	.insn	4, 0x4353502f
  1a:	525f 3356 4932      	.insn	6, 0x49323356525f
  20:	4353502f          	.insn	4, 0x4353502f
  24:	4f2d                	.insn	2, 0x4f2d
  26:	454e                	.insn	2, 0x454e
  28:	666f732f          	.insn	4, 0x666f732f
  2c:	7774                	.insn	2, 0x7774
  2e:	7261                	.insn	2, 0x7261
  30:	2f65                	.insn	2, 0x2f65
  32:	2e00736f          	jal	t1,7312 <start-0x3f8cee>
  36:	6372732f          	.insn	4, 0x6372732f
  3a:	7300                	.insn	2, 0x7300
  3c:	6372                	.insn	2, 0x6372
  3e:	6568732f          	.insn	4, 0x6568732f
  42:	6c6c                	.insn	2, 0x6c6c
  44:	632e                	.insn	2, 0x632e
  46:	7500                	.insn	2, 0x7500
  48:	2e726573          	csrrsi	a0,0x2e7,4
  4c:	0068                	.insn	2, 0x0068
  4e:	6166                	.insn	2, 0x6166
  50:	3374                	.insn	2, 0x3374
  52:	2e32                	.insn	2, 0x2e32
  54:	0068                	.insn	2, 0x0068
  56:	7273752f          	.insn	4, 0x7273752f
  5a:	62696c2f          	.insn	4, 0x62696c2f
  5e:	766c6c2f          	.insn	4, 0x766c6c2f
  62:	2d6d                	.insn	2, 0x2d6d
  64:	3132                	.insn	2, 0x3132
  66:	62696c2f          	.insn	4, 0x62696c2f
  6a:	616c632f          	.insn	4, 0x616c632f
  6e:	676e                	.insn	2, 0x676e
  70:	2f31322f          	.insn	4, 0x2f31322f
  74:	6e69                	.insn	2, 0x6e69
  76:	64756c63          	bltu	a0,t2,6ce <start-0x3ff932>
  7a:	0065                	.insn	2, 0x0065
  7c:	2f637273          	csrrci	tp,0x2f6,6
  80:	7375                	.insn	2, 0x7375
  82:	7265                	.insn	2, 0x7265
  84:	632e                	.insn	2, 0x632e
  86:	7300                	.insn	2, 0x7300
  88:	6474                	.insn	2, 0x6474
  8a:	6e69                	.insn	2, 0x6e69
  8c:	2e74                	.insn	2, 0x2e74
  8e:	0068                	.insn	2, 0x0068
  90:	616e7973          	csrrci	s2,0x616,28
  94:	5f70                	.insn	2, 0x5f70
  96:	7061                	.insn	2, 0x7061
  98:	2e69                	.insn	2, 0x2e69
  9a:	0068                	.insn	2, 0x0068
  9c:	2f637273          	csrrci	tp,0x2f6,6
  a0:	6166                	.insn	2, 0x6166
  a2:	3374                	.insn	2, 0x3374
  a4:	2e32                	.insn	2, 0x2e32
  a6:	0063                	.short	0x0063
