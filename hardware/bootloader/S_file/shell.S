
./build/shell.elf:     file format elf32-littleriscv


Disassembly of section .text:

00400000 <start>:

/* ===== エントリ ===== */
__attribute__((section(".text.start")))
__attribute__((naked))
void start(void) {
    __asm__ __volatile__(
  400000:	00429537          	lui	a0,0x429
  400004:	46050513          	addi	a0,a0,1120 # 429460 <__user_stack_top>
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
  400064:	eec50513          	addi	a0,a0,-276 # 401eec <__modsi3+0x68>
  400068:	00001097          	auipc	ra,0x1
  40006c:	c5c080e7          	jalr	-932(ra) # 400cc4 <printf>
  400070:	00000913          	li	s2,0
  400074:	02000d13          	li	s10,32
  400078:	00402437          	lui	s0,0x402
  40007c:	efa40413          	addi	s0,s0,-262 # 401efa <__modsi3+0x76>
  400080:	004024b7          	lui	s1,0x402
  400084:	f0748493          	addi	s1,s1,-249 # 401f07 <__modsi3+0x83>
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
  4000b4:	f1a50513          	addi	a0,a0,-230 # 401f1a <__modsi3+0x96>
  4000b8:	00001097          	auipc	ra,0x1
  4000bc:	c0c080e7          	jalr	-1012(ra) # 400cc4 <printf>
  4000c0:	01f00a93          	li	s5,31
        putchar(0x1B); putchar('['); putchar('3'); putchar('4'); putchar('m'); // 青
  4000c4:	01b00513          	li	a0,27
  4000c8:	00001097          	auipc	ra,0x1
  4000cc:	eb4080e7          	jalr	-332(ra) # 400f7c <putchar>
  4000d0:	05b00513          	li	a0,91
  4000d4:	00001097          	auipc	ra,0x1
  4000d8:	ea8080e7          	jalr	-344(ra) # 400f7c <putchar>
  4000dc:	03300513          	li	a0,51
  4000e0:	00001097          	auipc	ra,0x1
  4000e4:	e9c080e7          	jalr	-356(ra) # 400f7c <putchar>
  4000e8:	03400513          	li	a0,52
  4000ec:	00001097          	auipc	ra,0x1
  4000f0:	e90080e7          	jalr	-368(ra) # 400f7c <putchar>
  4000f4:	06d00513          	li	a0,109
  4000f8:	00001097          	auipc	ra,0x1
  4000fc:	e84080e7          	jalr	-380(ra) # 400f7c <putchar>
        putchar('P');
  400100:	05000513          	li	a0,80
  400104:	00001097          	auipc	ra,0x1
  400108:	e78080e7          	jalr	-392(ra) # 400f7c <putchar>
        putchar('S');
  40010c:	05300513          	li	a0,83
  400110:	00001097          	auipc	ra,0x1
  400114:	e6c080e7          	jalr	-404(ra) # 400f7c <putchar>
        putchar('C');
  400118:	04300513          	li	a0,67
  40011c:	00001097          	auipc	ra,0x1
  400120:	e60080e7          	jalr	-416(ra) # 400f7c <putchar>
        putchar('_');
  400124:	05f00513          	li	a0,95
  400128:	00001097          	auipc	ra,0x1
  40012c:	e54080e7          	jalr	-428(ra) # 400f7c <putchar>
        putchar('O');
  400130:	04f00513          	li	a0,79
  400134:	00001097          	auipc	ra,0x1
  400138:	e48080e7          	jalr	-440(ra) # 400f7c <putchar>
        putchar('S');
  40013c:	05300513          	li	a0,83
  400140:	00001097          	auipc	ra,0x1
  400144:	e3c080e7          	jalr	-452(ra) # 400f7c <putchar>
        putchar('>');
  400148:	03e00513          	li	a0,62
  40014c:	00001097          	auipc	ra,0x1
  400150:	e30080e7          	jalr	-464(ra) # 400f7c <putchar>
        putchar(' ');
  400154:	02000513          	li	a0,32
  400158:	00001097          	auipc	ra,0x1
  40015c:	e24080e7          	jalr	-476(ra) # 400f7c <putchar>
        putchar(0x1B); putchar('['); putchar('0'); putchar('m'); // リセット
  400160:	01b00513          	li	a0,27
  400164:	00001097          	auipc	ra,0x1
  400168:	e18080e7          	jalr	-488(ra) # 400f7c <putchar>
  40016c:	05b00513          	li	a0,91
  400170:	00001097          	auipc	ra,0x1
  400174:	e0c080e7          	jalr	-500(ra) # 400f7c <putchar>
  400178:	03000513          	li	a0,48
  40017c:	00001097          	auipc	ra,0x1
  400180:	e00080e7          	jalr	-512(ra) # 400f7c <putchar>
  400184:	06d00513          	li	a0,109
  400188:	00000a13          	li	s4,0
  40018c:	0ff57513          	zext.b	a0,a0
  400190:	00001097          	auipc	ra,0x1
  400194:	dec080e7          	jalr	-532(ra) # 400f7c <putchar>
  400198:	00090d93          	mv	s11,s2
  40019c:	0100006f          	j	4001ac <main+0x190>
            if (ch == 8 || ch == 127) {
  4001a0:	07351e63          	bne	a0,s3,40021c <main+0x200>
  4001a4:	00090d93          	mv	s11,s2
                if (len > 0) {
  4001a8:	0b404263          	bgtz	s4,40024c <main+0x230>
            uint32_t sw = poll_switch_api() & 0x03;
  4001ac:	00001097          	auipc	ra,0x1
  4001b0:	110080e7          	jalr	272(ra) # 4012bc <poll_switch_api>
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
  4001d0:	af8080e7          	jalr	-1288(ra) # 400cc4 <printf>
  4001d4:	001dd513          	srli	a0,s11,0x1
  4001d8:	00297593          	andi	a1,s2,2
  4001dc:	0015b593          	seqz	a1,a1
  4001e0:	00b57533          	and	a0,a0,a1
            if (sw2_pressed) {
  4001e4:	00050863          	beqz	a0,4001f4 <main+0x1d8>
                printf("SW2 pressed\n");
  4001e8:	00048513          	mv	a0,s1
  4001ec:	00001097          	auipc	ra,0x1
  4001f0:	ad8080e7          	jalr	-1320(ra) # 400cc4 <printf>
            int ch = getchar_timeout();
  4001f4:	00001097          	auipc	ra,0x1
  4001f8:	0a8080e7          	jalr	168(ra) # 40129c <getchar_timeout>
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
  400258:	d28080e7          	jalr	-728(ra) # 400f7c <putchar>
                    putchar(' ');
  40025c:	02000513          	li	a0,32
  400260:	00001097          	auipc	ra,0x1
  400264:	d1c080e7          	jalr	-740(ra) # 400f7c <putchar>
  400268:	00800513          	li	a0,8
                }
  40026c:	f21ff06f          	j	40018c <main+0x170>
                putchar('\n');
  400270:	00a00513          	li	a0,10
  400274:	00001097          	auipc	ra,0x1
  400278:	d08080e7          	jalr	-760(ra) # 400f7c <putchar>
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
  400320:	f1458593          	addi	a1,a1,-236 # 401f14 <__modsi3+0x90>
  400324:	00001097          	auipc	ra,0x1
  400328:	e3c080e7          	jalr	-452(ra) # 401160 <strcmp>
  40032c:	d80502e3          	beqz	a0,4000b0 <main+0x94>

        // ---- Dump ----
        } else if (strcmp(argv[0], "dump") == 0) {
  400330:	000d8513          	mv	a0,s11
  400334:	004025b7          	lui	a1,0x402
  400338:	f3358593          	addi	a1,a1,-205 # 401f33 <__modsi3+0xaf>
  40033c:	00001097          	auipc	ra,0x1
  400340:	e24080e7          	jalr	-476(ra) # 401160 <strcmp>
  400344:	1a050063          	beqz	a0,4004e4 <main+0x4c8>
            unsigned lenb = (argc >= 3) ? parse_u32(argv[2]) : 0x100;
            hexdump((const void*)addr, lenb, (uintptr_t)addr);
        */

        // ---- 素数出力サンプル ----
        } else if (strcmp(argv[0], "primes") == 0) {
  400348:	000d8513          	mv	a0,s11
  40034c:	004025b7          	lui	a1,0x402
  400350:	f3858593          	addi	a1,a1,-200 # 401f38 <__modsi3+0xb4>
  400354:	00001097          	auipc	ra,0x1
  400358:	e0c080e7          	jalr	-500(ra) # 401160 <strcmp>
  40035c:	01f00a93          	li	s5,31
  400360:	1c050a63          	beqz	a0,400534 <main+0x518>
                }
            }
            cmd_primes(max);

        // ---- セルフテスト ----
        } else if (strcmp(argv[0], "self_test") == 0) {
  400364:	000d8513          	mv	a0,s11
  400368:	004025b7          	lui	a1,0x402
  40036c:	f5958593          	addi	a1,a1,-167 # 401f59 <__modsi3+0xd5>
  400370:	00001097          	auipc	ra,0x1
  400374:	df0080e7          	jalr	-528(ra) # 401160 <strcmp>
  400378:	d40506e3          	beqz	a0,4000c4 <main+0xa8>
            //TBD
            //cmd_primes(max);

        // ---- SynapEngine ----
        } else if (strcmp(argv[0], "sa_start") == 0) {
  40037c:	000d8513          	mv	a0,s11
  400380:	004025b7          	lui	a1,0x402
  400384:	f6358593          	addi	a1,a1,-157 # 401f63 <__modsi3+0xdf>
  400388:	00001097          	auipc	ra,0x1
  40038c:	dd8080e7          	jalr	-552(ra) # 401160 <strcmp>
  400390:	24050463          	beqz	a0,4005d8 <main+0x5bc>
            }
            // SA API call 
            call_sa_api(matrix_max);

        // ---- I2S MIC READ ----
        } else if (strcmp(argv[0], "mic_read") == 0) {
  400394:	000d8513          	mv	a0,s11
  400398:	004025b7          	lui	a1,0x402
  40039c:	f7d58593          	addi	a1,a1,-131 # 401f7d <__modsi3+0xf9>
  4003a0:	00001097          	auipc	ra,0x1
  4003a4:	dc0080e7          	jalr	-576(ra) # 401160 <strcmp>
  4003a8:	28050263          	beqz	a0,40062c <main+0x610>

            unsigned count = parse_u32(argv[1]);
            call_mic_api(count);

        // ---- I2S MIC WRITE to FILE ----
        } else if (strcmp(argv[0], "mic_write") == 0) {
  4003ac:	000d8513          	mv	a0,s11
  4003b0:	004025b7          	lui	a1,0x402
  4003b4:	f9f58593          	addi	a1,a1,-97 # 401f9f <__modsi3+0x11b>
  4003b8:	00001097          	auipc	ra,0x1
  4003bc:	da8080e7          	jalr	-600(ra) # 401160 <strcmp>
  4003c0:	2e050463          	beqz	a0,4006a8 <main+0x68c>
            unsigned count = parse_u32(argv[1]);
            //call_mic_write_api(count);
            call_mic_write_file(count);

        // ---- SDカードREAD ----
        } else if (strcmp(argv[0], "sd_read") == 0) {
  4003c4:	000d8513          	mv	a0,s11
  4003c8:	004025b7          	lui	a1,0x402
  4003cc:	fc358593          	addi	a1,a1,-61 # 401fc3 <__modsi3+0x13f>
  4003d0:	00001097          	auipc	ra,0x1
  4003d4:	d90080e7          	jalr	-624(ra) # 401160 <strcmp>
  4003d8:	30050463          	beqz	a0,4006e0 <main+0x6c4>

            unsigned sd_sector = parse_u32(argv[1]);
            call_sd_read_api(sd_sector);

        // ---- SDカードWRITE TEST----
        } else if (strcmp(argv[0], "sd_write") == 0) {
  4003dc:	000d8513          	mv	a0,s11
  4003e0:	004025b7          	lui	a1,0x402
  4003e4:	fe458593          	addi	a1,a1,-28 # 401fe4 <__modsi3+0x160>
  4003e8:	00001097          	auipc	ra,0x1
  4003ec:	d78080e7          	jalr	-648(ra) # 401160 <strcmp>
  4003f0:	36050663          	beqz	a0,40075c <main+0x740>
                goto prompt;
            }
            call_sd_write_test_api(sd_sector);

        // ---- FAT32 Info ----
        } else if (strcmp(argv[0], "fat32_info") == 0) {
  4003f4:	000d8513          	mv	a0,s11
  4003f8:	004025b7          	lui	a1,0x402
  4003fc:	02658593          	addi	a1,a1,38 # 402026 <__modsi3+0x1a2>
  400400:	00001097          	auipc	ra,0x1
  400404:	d60080e7          	jalr	-672(ra) # 401160 <strcmp>
  400408:	38050a63          	beqz	a0,40079c <main+0x780>
            printf("spc=%x\n",           g_fat32.sectors_per_cluster);
            printf("fat_begin=%x\n",     g_fat32.fat_begin);
            printf("data_begin=%x\n",    g_fat32.data_begin);

        // ---- FAT32 ls ----
        } else if (strcmp(argv[0], "fat32_ls") == 0) {
  40040c:	000d8513          	mv	a0,s11
  400410:	004025b7          	lui	a1,0x402
  400414:	08858593          	addi	a1,a1,136 # 402088 <__modsi3+0x204>
  400418:	00001097          	auipc	ra,0x1
  40041c:	d48080e7          	jalr	-696(ra) # 401160 <strcmp>
  400420:	3a050063          	beqz	a0,4007c0 <main+0x7a4>

            fat32_ls();

        // ---- FAT32 cat ----
        } else if (strcmp(argv[0], "fat32_cat") == 0) {
  400424:	000d8513          	mv	a0,s11
  400428:	004025b7          	lui	a1,0x402
  40042c:	09158593          	addi	a1,a1,145 # 402091 <__modsi3+0x20d>
  400430:	00001097          	auipc	ra,0x1
  400434:	d30080e7          	jalr	-720(ra) # 401160 <strcmp>
  400438:	38050a63          	beqz	a0,4007cc <main+0x7b0>
            }

            fat32_cat(argv[1]);

        // ---- FAT32 touch ----
        } else if (strcmp(argv[0], "fat32_touch") == 0) {
  40043c:	000d8513          	mv	a0,s11
  400440:	004025b7          	lui	a1,0x402
  400444:	0b458593          	addi	a1,a1,180 # 4020b4 <__modsi3+0x230>
  400448:	00001097          	auipc	ra,0x1
  40044c:	d18080e7          	jalr	-744(ra) # 401160 <strcmp>
  400450:	40050463          	beqz	a0,400858 <main+0x83c>
            }

            if (fat32_touch(argv[1]) != 0) {
                printf("fat32_touch failed\n");
            } 
        } else if (strcmp(argv[0], "speech") == 0) {
  400454:	000d8513          	mv	a0,s11
  400458:	004025b7          	lui	a1,0x402
  40045c:	0ef58593          	addi	a1,a1,239 # 4020ef <__modsi3+0x26b>
  400460:	00001097          	auipc	ra,0x1
  400464:	d00080e7          	jalr	-768(ra) # 401160 <strcmp>
  400468:	42050063          	beqz	a0,400888 <main+0x86c>
            cmd_speech();
                    
        // ---- Helps出力 ----
        } else if (strcmp(argv[0], "help") == 0) {
  40046c:	000d8513          	mv	a0,s11
  400470:	004025b7          	lui	a1,0x402
  400474:	0f658593          	addi	a1,a1,246 # 4020f6 <__modsi3+0x272>
  400478:	00001097          	auipc	ra,0x1
  40047c:	ce8080e7          	jalr	-792(ra) # 401160 <strcmp>
  400480:	40050a63          	beqz	a0,400894 <main+0x878>
            printf("  sa_start\n");
            printf("  sd_read\n");
            printf("  exit | quit | q\n");
            */

        } else if (strcmp(argv[0], "exit") == 0 ||
  400484:	000d8513          	mv	a0,s11
  400488:	004025b7          	lui	a1,0x402
  40048c:	10658593          	addi	a1,a1,262 # 402106 <__modsi3+0x282>
  400490:	00001097          	auipc	ra,0x1
  400494:	cd0080e7          	jalr	-816(ra) # 401160 <strcmp>
  400498:	40050863          	beqz	a0,4008a8 <main+0x88c>
                   strcmp(argv[0], "quit") == 0 ||
  40049c:	000d8513          	mv	a0,s11
  4004a0:	004025b7          	lui	a1,0x402
  4004a4:	10b58593          	addi	a1,a1,267 # 40210b <__modsi3+0x287>
  4004a8:	00001097          	auipc	ra,0x1
  4004ac:	cb8080e7          	jalr	-840(ra) # 401160 <strcmp>
  4004b0:	3e050c63          	beqz	a0,4008a8 <main+0x88c>
                   strcmp(argv[0], "q") == 0) {
  4004b4:	000d8513          	mv	a0,s11
  4004b8:	004025b7          	lui	a1,0x402
  4004bc:	11058593          	addi	a1,a1,272 # 402110 <__modsi3+0x28c>
  4004c0:	00001097          	auipc	ra,0x1
  4004c4:	ca0080e7          	jalr	-864(ra) # 401160 <strcmp>
                   strcmp(argv[0], "quit") == 0 ||
  4004c8:	3e050063          	beqz	a0,4008a8 <main+0x88c>
            exit();
        
        } else {
            printf("unknown command: %s\n", argv[0]);
  4004cc:	00402537          	lui	a0,0x402
  4004d0:	11250513          	addi	a0,a0,274 # 402112 <__modsi3+0x28e>
  4004d4:	000d8593          	mv	a1,s11
  4004d8:	00000097          	auipc	ra,0x0
  4004dc:	7ec080e7          	jalr	2028(ra) # 400cc4 <printf>
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
  400540:	c54080e7          	jalr	-940(ra) # 401190 <parse_u32>
  400544:	00050593          	mv	a1,a0
  400548:	00402537          	lui	a0,0x402
  40054c:	f3f50513          	addi	a0,a0,-193 # 401f3f <__modsi3+0xbb>
  400550:	00812603          	lw	a2,8(sp)
                if (max > 100000) {
  400554:	0ab67863          	bgeu	a2,a1,400604 <main+0x5e8>
  400558:	25c0006f          	j	4007b4 <main+0x798>
  40055c:	00200537          	lui	a0,0x200
  400560:	01f00a93          	li	s5,31
            call_dump_api(addr, len);
  400564:	00001097          	auipc	ra,0x1
  400568:	bbc080e7          	jalr	-1092(ra) # 401120 <call_dump_api>
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
  40058c:	b98080e7          	jalr	-1128(ra) # 401120 <call_dump_api>
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
  4005e4:	bb0080e7          	jalr	-1104(ra) # 401190 <parse_u32>
  4005e8:	00050593          	mv	a1,a0
  4005ec:	00402537          	lui	a0,0x402
  4005f0:	f6c50513          	addi	a0,a0,-148 # 401f6c <__modsi3+0xe8>
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
  400624:	b00080e7          	jalr	-1280(ra) # 401120 <call_dump_api>
  400628:	a9dff06f          	j	4000c4 <main+0xa8>
  40062c:	00402537          	lui	a0,0x402
  400630:	f8650513          	addi	a0,a0,-122 # 401f86 <__modsi3+0x102>
            if (argc < 2) {
  400634:	180a0063          	beqz	s4,4007b4 <main+0x798>
            unsigned count = parse_u32(argv[1]);
  400638:	01012503          	lw	a0,16(sp)
  40063c:	00001097          	auipc	ra,0x1
  400640:	b54080e7          	jalr	-1196(ra) # 401190 <parse_u32>
            call_mic_api(count);
  400644:	00001097          	auipc	ra,0x1
  400648:	960080e7          	jalr	-1696(ra) # 400fa4 <call_mic_api>
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
  4006ac:	fa950513          	addi	a0,a0,-87 # 401fa9 <__modsi3+0x125>
            if (argc < 2) {
  4006b0:	100a0263          	beqz	s4,4007b4 <main+0x798>
            unsigned count = parse_u32(argv[1]);
  4006b4:	01012503          	lw	a0,16(sp)
  4006b8:	00001097          	auipc	ra,0x1
  4006bc:	ad8080e7          	jalr	-1320(ra) # 401190 <parse_u32>
            call_mic_write_file(count);
  4006c0:	00001097          	auipc	ra,0x1
  4006c4:	8f0080e7          	jalr	-1808(ra) # 400fb0 <call_mic_write_file>
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
  4006e4:	fcb50513          	addi	a0,a0,-53 # 401fcb <__modsi3+0x147>
            if (argc < 2) {
  4006e8:	0c0a0663          	beqz	s4,4007b4 <main+0x798>
            unsigned sd_sector = parse_u32(argv[1]);
  4006ec:	01012503          	lw	a0,16(sp)
  4006f0:	00001097          	auipc	ra,0x1
  4006f4:	aa0080e7          	jalr	-1376(ra) # 401190 <parse_u32>
            call_sd_read_api(sd_sector);
  4006f8:	00001097          	auipc	ra,0x1
  4006fc:	970080e7          	jalr	-1680(ra) # 401068 <call_sd_read_api>
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
  400760:	fed50513          	addi	a0,a0,-19 # 401fed <__modsi3+0x169>
            if (argc < 2) {
  400764:	040a0863          	beqz	s4,4007b4 <main+0x798>
            unsigned sd_sector = parse_u32(argv[1]);
  400768:	01012503          	lw	a0,16(sp)
  40076c:	00001097          	auipc	ra,0x1
  400770:	a24080e7          	jalr	-1500(ra) # 401190 <parse_u32>
  400774:	00050593          	mv	a1,a0
            if (sd_sector < 5000) {
  400778:	00355613          	srli	a2,a0,0x3
  40077c:	00402537          	lui	a0,0x402
  400780:	00750513          	addi	a0,a0,7 # 402007 <__modsi3+0x183>
  400784:	27100693          	li	a3,625
  400788:	02d66663          	bltu	a2,a3,4007b4 <main+0x798>
            call_sd_write_test_api(sd_sector);
  40078c:	00058513          	mv	a0,a1
  400790:	00001097          	auipc	ra,0x1
  400794:	8e4080e7          	jalr	-1820(ra) # 401074 <call_sd_write_test_api>
        } else if (strcmp(argv[0], "exit") == 0 ||
  400798:	92dff06f          	j	4000c4 <main+0xa8>
            if (fat32_mount() != 0) {
  40079c:	00001097          	auipc	ra,0x1
  4007a0:	c18080e7          	jalr	-1000(ra) # 4013b4 <fat32_mount>
  4007a4:	00050593          	mv	a1,a0
  4007a8:	00402537          	lui	a0,0x402
  4007ac:	03150513          	addi	a0,a0,49 # 402031 <__modsi3+0x1ad>
  4007b0:	02058c63          	beqz	a1,4007e8 <main+0x7cc>
  4007b4:	00000097          	auipc	ra,0x0
  4007b8:	510080e7          	jalr	1296(ra) # 400cc4 <printf>
        } else if (strcmp(argv[0], "exit") == 0 ||
  4007bc:	909ff06f          	j	4000c4 <main+0xa8>
            fat32_ls();
  4007c0:	00001097          	auipc	ra,0x1
  4007c4:	f70080e7          	jalr	-144(ra) # 401730 <fat32_ls>
        } else if (strcmp(argv[0], "help") == 0) {
  4007c8:	8fdff06f          	j	4000c4 <main+0xa8>
  4007cc:	00402537          	lui	a0,0x402
  4007d0:	09b50513          	addi	a0,a0,155 # 40209b <__modsi3+0x217>
            if (argc < 2) {
  4007d4:	fe0a00e3          	beqz	s4,4007b4 <main+0x798>
            fat32_cat(argv[1]);
  4007d8:	01012503          	lw	a0,16(sp)
  4007dc:	00001097          	auipc	ra,0x1
  4007e0:	aec080e7          	jalr	-1300(ra) # 4012c8 <fat32_cat>
        } else if (strcmp(argv[0], "fat32_touch") == 0) {
  4007e4:	8e1ff06f          	j	4000c4 <main+0xa8>
  4007e8:	00408537          	lui	a0,0x408
            printf("part_lba=%x\n",      g_fat32.part_lba);
  4007ec:	24452583          	lw	a1,580(a0) # 408244 <g_fat32>
  4007f0:	24450a13          	addi	s4,a0,580
  4007f4:	00402537          	lui	a0,0x402
  4007f8:	04550513          	addi	a0,a0,69 # 402045 <__modsi3+0x1c1>
  4007fc:	00000097          	auipc	ra,0x0
  400800:	4c8080e7          	jalr	1224(ra) # 400cc4 <printf>
            printf("root_cluster=%x\n",  g_fat32.root_cluster);
  400804:	00ca2583          	lw	a1,12(s4)
  400808:	00402537          	lui	a0,0x402
  40080c:	05250513          	addi	a0,a0,82 # 402052 <__modsi3+0x1ce>
  400810:	00000097          	auipc	ra,0x0
  400814:	4b4080e7          	jalr	1204(ra) # 400cc4 <printf>
            printf("spc=%x\n",           g_fat32.sectors_per_cluster);
  400818:	010a2583          	lw	a1,16(s4)
  40081c:	00402537          	lui	a0,0x402
  400820:	06350513          	addi	a0,a0,99 # 402063 <__modsi3+0x1df>
  400824:	00000097          	auipc	ra,0x0
  400828:	4a0080e7          	jalr	1184(ra) # 400cc4 <printf>
            printf("fat_begin=%x\n",     g_fat32.fat_begin);
  40082c:	004a2583          	lw	a1,4(s4)
  400830:	00402537          	lui	a0,0x402
  400834:	06b50513          	addi	a0,a0,107 # 40206b <__modsi3+0x1e7>
  400838:	00000097          	auipc	ra,0x0
  40083c:	48c080e7          	jalr	1164(ra) # 400cc4 <printf>
            printf("data_begin=%x\n",    g_fat32.data_begin);
  400840:	008a2583          	lw	a1,8(s4)
  400844:	00402537          	lui	a0,0x402
  400848:	07950513          	addi	a0,a0,121 # 402079 <__modsi3+0x1f5>
  40084c:	00000097          	auipc	ra,0x0
  400850:	478080e7          	jalr	1144(ra) # 400cc4 <printf>
  400854:	871ff06f          	j	4000c4 <main+0xa8>
  400858:	00402537          	lui	a0,0x402
  40085c:	0c050513          	addi	a0,a0,192 # 4020c0 <__modsi3+0x23c>
            if (argc < 2) {
  400860:	f40a0ae3          	beqz	s4,4007b4 <main+0x798>
            if (fat32_touch(argv[1]) != 0) {
  400864:	01012503          	lw	a0,16(sp)
  400868:	00001097          	auipc	ra,0x1
  40086c:	150080e7          	jalr	336(ra) # 4019b8 <fat32_touch>
  400870:	84050ae3          	beqz	a0,4000c4 <main+0xa8>
                printf("fat32_touch failed\n");
  400874:	00402537          	lui	a0,0x402
  400878:	0db50513          	addi	a0,a0,219 # 4020db <__modsi3+0x257>
  40087c:	00000097          	auipc	ra,0x0
  400880:	448080e7          	jalr	1096(ra) # 400cc4 <printf>
        } else if (strcmp(argv[0], "exit") == 0 ||
  400884:	841ff06f          	j	4000c4 <main+0xa8>
            cmd_speech();
  400888:	00001097          	auipc	ra,0x1
  40088c:	804080e7          	jalr	-2044(ra) # 40108c <cmd_speech>
        } else if (strcmp(argv[0], "help") == 0) {
  400890:	835ff06f          	j	4000c4 <main+0xa8>
            printf("commands:\n");
  400894:	00402537          	lui	a0,0x402
  400898:	0fb50513          	addi	a0,a0,251 # 4020fb <__modsi3+0x277>
  40089c:	00000097          	auipc	ra,0x0
  4008a0:	428080e7          	jalr	1064(ra) # 400cc4 <printf>
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
  4009a0:	12798993          	addi	s3,s3,295 # 402127 <__modsi3+0x2a3>
  4009a4:	00c0006f          	j	4009b0 <cmd_primes+0x3c>
  4009a8:	00190913          	addi	s2,s2,1
  4009ac:	05246063          	bltu	s0,s2,4009ec <cmd_primes+0x78>
        if (is_prime(n)) {
  4009b0:	00090513          	mv	a0,s2
  4009b4:	00001097          	auipc	ra,0x1
  4009b8:	898080e7          	jalr	-1896(ra) # 40124c <is_prime>
  4009bc:	fe0506e3          	beqz	a0,4009a8 <cmd_primes+0x34>
            printf("%d ", (int)n);
  4009c0:	00098513          	mv	a0,s3
  4009c4:	00090593          	mv	a1,s2
  4009c8:	00000097          	auipc	ra,0x0
  4009cc:	2fc080e7          	jalr	764(ra) # 400cc4 <printf>
            count++;
  4009d0:	00148493          	addi	s1,s1,1
            if ((count % 8) == 0)
  4009d4:	0074f513          	andi	a0,s1,7
  4009d8:	fc0518e3          	bnez	a0,4009a8 <cmd_primes+0x34>
                putchar('\n');
  4009dc:	00a00513          	li	a0,10
  4009e0:	00000097          	auipc	ra,0x0
  4009e4:	59c080e7          	jalr	1436(ra) # 400f7c <putchar>
  4009e8:	fc1ff06f          	j	4009a8 <cmd_primes+0x34>
    if ((count % 8) != 0)
  4009ec:	0074f513          	andi	a0,s1,7
  4009f0:	00050863          	beqz	a0,400a00 <cmd_primes+0x8c>
        putchar('\n');
  4009f4:	00a00513          	li	a0,10
  4009f8:	00000097          	auipc	ra,0x0
  4009fc:	584080e7          	jalr	1412(ra) # 400f7c <putchar>
    printf("total primes: %d (0..%d)\n", count, (int)max);
  400a00:	00402537          	lui	a0,0x402
  400a04:	12b50513          	addi	a0,a0,299 # 40212b <__modsi3+0x2a7>
  400a08:	00048593          	mv	a1,s1
  400a0c:	00040613          	mv	a2,s0
  400a10:	01c12083          	lw	ra,28(sp)
  400a14:	01812403          	lw	s0,24(sp)
  400a18:	01412483          	lw	s1,20(sp)
  400a1c:	01012903          	lw	s2,16(sp)
  400a20:	00c12983          	lw	s3,12(sp)
  400a24:	02010113          	addi	sp,sp,32
  400a28:	00000317          	auipc	t1,0x0
  400a2c:	29c30067          	jr	668(t1) # 400cc4 <printf>

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
  400a48:	00050793          	mv	a5,a0
    if (matrix_size == 0 ||
  400a4c:	fff50513          	addi	a0,a0,-1
  400a50:	03f00593          	li	a1,63
  400a54:	26a5e063          	bltu	a1,a0,400cb4 <call_sa_api+0x26c>
  400a58:	0037f513          	andi	a0,a5,3
  400a5c:	24051c63          	bnez	a0,400cb4 <call_sa_api+0x26c>
  400a60:	00000593          	li	a1,0
    for (uint32_t i = 0; i < matrix_size; ++i) {
  400a64:	00279813          	slli	a6,a5,0x2
  400a68:	00402637          	lui	a2,0x402
  400a6c:	24460613          	addi	a2,a2,580 # 402244 <call_sa_api.matrix_A>
  400a70:	004036b7          	lui	a3,0x403
  400a74:	24468693          	addi	a3,a3,580 # 403244 <call_sa_api.matrix_B>
  400a78:	00404737          	lui	a4,0x404
  400a7c:	24470713          	addi	a4,a4,580 # 404244 <call_sa_api.matrix_C>
  400a80:	00060893          	mv	a7,a2
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400a84:	02b782b3          	mul	t0,a5,a1
  400a88:	005782b3          	add	t0,a5,t0
  400a8c:	005602b3          	add	t0,a2,t0
  400a90:	00058313          	mv	t1,a1
  400a94:	00070393          	mv	t2,a4
  400a98:	00068e13          	mv	t3,a3
  400a9c:	00088e93          	mv	t4,a7
  400aa0:	00050f13          	mv	t5,a0
            matrix_B[index] = (uint8_t)(3u * i + j + 5u);
  400aa4:	005f0f93          	addi	t6,t5,5
  400aa8:	01fe0023          	sb	t6,0(t3)
            matrix_A[index] = (uint8_t)(2u * i + 2u * j + 2u);
  400aac:	00131f93          	slli	t6,t1,0x1
            matrix_C[index] = 0u;
  400ab0:	0003a023          	sw	zero,0(t2)
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400ab4:	001f0f13          	addi	t5,t5,1
            matrix_A[index] = (uint8_t)(2u * i + 2u * j + 2u);
  400ab8:	002f8f93          	addi	t6,t6,2
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400abc:	001e0e13          	addi	t3,t3,1
            matrix_A[index] = (uint8_t)(2u * i + 2u * j + 2u);
  400ac0:	01fe8023          	sb	t6,0(t4)
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400ac4:	001e8e93          	addi	t4,t4,1
  400ac8:	00438393          	addi	t2,t2,4
  400acc:	00130313          	addi	t1,t1,1
  400ad0:	fc5e9ae3          	bne	t4,t0,400aa4 <call_sa_api+0x5c>
    for (uint32_t i = 0; i < matrix_size; ++i) {
  400ad4:	00158593          	addi	a1,a1,1
  400ad8:	00350513          	addi	a0,a0,3
  400adc:	00f888b3          	add	a7,a7,a5
  400ae0:	00f686b3          	add	a3,a3,a5
  400ae4:	01070733          	add	a4,a4,a6
  400ae8:	f8f59ee3          	bne	a1,a5,400a84 <call_sa_api+0x3c>
  400aec:	00000313          	li	t1,0
    __asm__ __volatile__ (
  400af0:	004023b7          	lui	t2,0x402
  400af4:	24438393          	addi	t2,t2,580 # 402244 <call_sa_api.matrix_A>
  400af8:	004032b7          	lui	t0,0x403
  400afc:	24428293          	addi	t0,t0,580 # 403244 <call_sa_api.matrix_B>
  400b00:	004048b7          	lui	a7,0x404
  400b04:	24488893          	addi	a7,a7,580 # 404244 <call_sa_api.matrix_C>
  400b08:	00a00e13          	li	t3,10
  400b0c:	04100e93          	li	t4,65
  400b10:	00038513          	mv	a0,t2
  400b14:	00028593          	mv	a1,t0
  400b18:	00088613          	mv	a2,a7
  400b1c:	000e0693          	mv	a3,t3
  400b20:	00078713          	mv	a4,a5
  400b24:	00000073          	ecall
  400b28:	00050f13          	mv	t5,a0
    __asm__ __volatile__ (
  400b2c:	000e8513          	mv	a0,t4
  400b30:	00100693          	li	a3,1
  400b34:	00000073          	ecall
  400b38:	000e0513          	mv	a0,t3
  400b3c:	00100693          	li	a3,1
  400b40:	00000073          	ecall
  400b44:	02000593          	li	a1,32
  400b48:	00038613          	mv	a2,t2
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400b4c:	02678533          	mul	a0,a5,t1
  400b50:	00a78533          	add	a0,a5,a0
  400b54:	00a38733          	add	a4,t2,a0
  400b58:	00060e93          	mv	t4,a2
            print_int((int)matrix_A[i * matrix_size + j]);
  400b5c:	000ecf03          	lbu	t5,0(t4)
    __asm__ __volatile__ (
  400b60:	000f0513          	mv	a0,t5
  400b64:	05b00693          	li	a3,91
  400b68:	00000073          	ecall
    __asm__ __volatile__ (
  400b6c:	00058513          	mv	a0,a1
  400b70:	00100693          	li	a3,1
  400b74:	00000073          	ecall
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400b78:	001e8e93          	addi	t4,t4,1
  400b7c:	feee90e3          	bne	t4,a4,400b5c <call_sa_api+0x114>
    __asm__ __volatile__ (
  400b80:	000e0513          	mv	a0,t3
  400b84:	00100693          	li	a3,1
  400b88:	00000073          	ecall
    for (uint32_t i = 0; i < matrix_size; ++i) {
  400b8c:	00130313          	addi	t1,t1,1
  400b90:	00f60633          	add	a2,a2,a5
  400b94:	faf31ce3          	bne	t1,a5,400b4c <call_sa_api+0x104>
  400b98:	00000593          	li	a1,0
  400b9c:	00a00613          	li	a2,10
  400ba0:	04200713          	li	a4,66
    __asm__ __volatile__ (
  400ba4:	00060513          	mv	a0,a2
  400ba8:	00100693          	li	a3,1
  400bac:	00000073          	ecall
  400bb0:	00070513          	mv	a0,a4
  400bb4:	00100693          	li	a3,1
  400bb8:	00000073          	ecall
  400bbc:	00060513          	mv	a0,a2
  400bc0:	00100693          	li	a3,1
  400bc4:	00000073          	ecall
  400bc8:	02000713          	li	a4,32
  400bcc:	00028313          	mv	t1,t0
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400bd0:	02b78533          	mul	a0,a5,a1
  400bd4:	00a78533          	add	a0,a5,a0
  400bd8:	00a283b3          	add	t2,t0,a0
  400bdc:	00030e13          	mv	t3,t1
            print_int((int)matrix_B[i * matrix_size + j]);
  400be0:	000e4e83          	lbu	t4,0(t3)
    __asm__ __volatile__ (
  400be4:	000e8513          	mv	a0,t4
  400be8:	05b00693          	li	a3,91
  400bec:	00000073          	ecall
    __asm__ __volatile__ (
  400bf0:	00070513          	mv	a0,a4
  400bf4:	00100693          	li	a3,1
  400bf8:	00000073          	ecall
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400bfc:	001e0e13          	addi	t3,t3,1
  400c00:	fe7e10e3          	bne	t3,t2,400be0 <call_sa_api+0x198>
    __asm__ __volatile__ (
  400c04:	00060513          	mv	a0,a2
  400c08:	00100693          	li	a3,1
  400c0c:	00000073          	ecall
    for (uint32_t i = 0; i < matrix_size; ++i) {
  400c10:	00158593          	addi	a1,a1,1
  400c14:	00f30333          	add	t1,t1,a5
  400c18:	faf59ce3          	bne	a1,a5,400bd0 <call_sa_api+0x188>
  400c1c:	00000593          	li	a1,0
  400c20:	00a00613          	li	a2,10
  400c24:	04300713          	li	a4,67
    __asm__ __volatile__ (
  400c28:	00060513          	mv	a0,a2
  400c2c:	00100693          	li	a3,1
  400c30:	00000073          	ecall
  400c34:	00070513          	mv	a0,a4
  400c38:	00100693          	li	a3,1
  400c3c:	00000073          	ecall
  400c40:	00060513          	mv	a0,a2
  400c44:	00100693          	li	a3,1
  400c48:	00000073          	ecall
  400c4c:	02000713          	li	a4,32
  400c50:	00088293          	mv	t0,a7
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400c54:	02b80533          	mul	a0,a6,a1
  400c58:	00a80533          	add	a0,a6,a0
  400c5c:	00a88333          	add	t1,a7,a0
  400c60:	00028393          	mv	t2,t0
            print_int((int)matrix_C[i * matrix_size + j]);
  400c64:	0003ae03          	lw	t3,0(t2)
    __asm__ __volatile__ (
  400c68:	000e0513          	mv	a0,t3
  400c6c:	05b00693          	li	a3,91
  400c70:	00000073          	ecall
    __asm__ __volatile__ (
  400c74:	00070513          	mv	a0,a4
  400c78:	00100693          	li	a3,1
  400c7c:	00000073          	ecall
        for (uint32_t j = 0; j < matrix_size; ++j) {
  400c80:	00438393          	addi	t2,t2,4
  400c84:	fe6390e3          	bne	t2,t1,400c64 <call_sa_api+0x21c>
    __asm__ __volatile__ (
  400c88:	00060513          	mv	a0,a2
  400c8c:	00100693          	li	a3,1
  400c90:	00000073          	ecall
    for (uint32_t i = 0; i < matrix_size; ++i) {
  400c94:	00158593          	addi	a1,a1,1
  400c98:	010282b3          	add	t0,t0,a6
  400c9c:	faf59ce3          	bne	a1,a5,400c54 <call_sa_api+0x20c>
  400ca0:	00a00593          	li	a1,10
    __asm__ __volatile__ (
  400ca4:	00058513          	mv	a0,a1
  400ca8:	00100693          	li	a3,1
  400cac:	00000073          	ecall
}
  400cb0:	00008067          	ret
        printf("invalid matrix size\n");
  400cb4:	00402537          	lui	a0,0x402
  400cb8:	14550513          	addi	a0,a0,325 # 402145 <__modsi3+0x2c1>
  400cbc:	00000317          	auipc	t1,0x0
  400cc0:	00830067          	jr	8(t1) # 400cc4 <printf>

00400cc4 <printf>:
void printf(const char *fmt, ...) {
  400cc4:	fc010113          	addi	sp,sp,-64
  400cc8:	00812e23          	sw	s0,28(sp)
  400ccc:	00912c23          	sw	s1,24(sp)
  400cd0:	01212a23          	sw	s2,20(sp)
  400cd4:	01312823          	sw	s3,16(sp)
  400cd8:	00050293          	mv	t0,a0
  400cdc:	02f12a23          	sw	a5,52(sp)
  400ce0:	03012c23          	sw	a6,56(sp)
  400ce4:	03112e23          	sw	a7,60(sp)
  400ce8:	02b12223          	sw	a1,36(sp)
  400cec:	02c12423          	sw	a2,40(sp)
  400cf0:	02d12623          	sw	a3,44(sp)
  400cf4:	02e12823          	sw	a4,48(sp)
  400cf8:	02410513          	addi	a0,sp,36
  400cfc:	02500593          	li	a1,37
  400d00:	07200613          	li	a2,114
  400d04:	06400713          	li	a4,100
  400d08:	02d00793          	li	a5,45
  400d0c:	ccccd6b7          	lui	a3,0xccccd
  400d10:	00110813          	addi	a6,sp,1
  400d14:	00900893          	li	a7,9
  400d18:	00100313          	li	t1,1
  400d1c:	03000393          	li	t2,48
  400d20:	07300e13          	li	t3,115
  400d24:	07800e93          	li	t4,120
    va_start(vargs, fmt);
  400d28:	00a12623          	sw	a0,12(sp)
  400d2c:	ccd68f13          	addi	t5,a3,-819 # cccccccd <USER_MAX+0xcc7ccccd>
  400d30:	00402fb7          	lui	t6,0x402
  400d34:	202f8f93          	addi	t6,t6,514 # 402202 <__modsi3+0x37e>
  400d38:	00c0006f          	j	400d44 <printf+0x80>
            switch (*fmt) {
  400d3c:	20050c63          	beqz	a0,400f54 <printf+0x290>
        fmt++;
  400d40:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400d44:	0002c403          	lbu	s0,0(t0)
  400d48:	00b40e63          	beq	s0,a1,400d64 <printf+0xa0>
  400d4c:	20040c63          	beqz	s0,400f64 <printf+0x2a0>
    __asm__ __volatile__ (
  400d50:	00040513          	mv	a0,s0
  400d54:	00100693          	li	a3,1
  400d58:	00000073          	ecall
        fmt++;
  400d5c:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400d60:	fe5ff06f          	j	400d44 <printf+0x80>
            switch (*fmt) {
  400d64:	0012c503          	lbu	a0,1(t0)
            fmt++;
  400d68:	00128293          	addi	t0,t0,1
            switch (*fmt) {
  400d6c:	02a64c63          	blt	a2,a0,400da4 <printf+0xe0>
  400d70:	12b50663          	beq	a0,a1,400e9c <printf+0x1d8>
  400d74:	fce514e3          	bne	a0,a4,400d3c <printf+0x78>
                    int value = va_arg(vargs, int);
  400d78:	00c12503          	lw	a0,12(sp)
  400d7c:	00450693          	addi	a3,a0,4
  400d80:	00d12623          	sw	a3,12(sp)
  400d84:	00052483          	lw	s1,0(a0)
                    if (value < 0) {
  400d88:	1604c063          	bltz	s1,400ee8 <printf+0x224>
                    if (u == 0) {
  400d8c:	16049663          	bnez	s1,400ef8 <printf+0x234>
    __asm__ __volatile__ (
  400d90:	00038513          	mv	a0,t2
  400d94:	00100693          	li	a3,1
  400d98:	00000073          	ecall
        fmt++;
  400d9c:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400da0:	fa5ff06f          	j	400d44 <printf+0x80>
            switch (*fmt) {
  400da4:	11c50663          	beq	a0,t3,400eb0 <printf+0x1ec>
  400da8:	f9d51ce3          	bne	a0,t4,400d40 <printf+0x7c>
                    unsigned value = va_arg(vargs, unsigned);
  400dac:	00c12503          	lw	a0,12(sp)
  400db0:	00450693          	addi	a3,a0,4
  400db4:	00d12623          	sw	a3,12(sp)
  400db8:	00052403          	lw	s0,0(a0)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400dbc:	01c45513          	srli	a0,s0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400dc0:	00af8533          	add	a0,t6,a0
  400dc4:	00054483          	lbu	s1,0(a0)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400dc8:	00441513          	slli	a0,s0,0x4
  400dcc:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400dd0:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400dd4:	00048513          	mv	a0,s1
  400dd8:	00100693          	li	a3,1
  400ddc:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400de0:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400de4:	00841513          	slli	a0,s0,0x8
  400de8:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400dec:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400df0:	00048513          	mv	a0,s1
  400df4:	00100693          	li	a3,1
  400df8:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400dfc:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400e00:	00c41513          	slli	a0,s0,0xc
  400e04:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400e08:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400e0c:	00048513          	mv	a0,s1
  400e10:	00100693          	li	a3,1
  400e14:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400e18:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400e1c:	01041513          	slli	a0,s0,0x10
  400e20:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400e24:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400e28:	00048513          	mv	a0,s1
  400e2c:	00100693          	li	a3,1
  400e30:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400e34:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400e38:	01441513          	slli	a0,s0,0x14
  400e3c:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400e40:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400e44:	00048513          	mv	a0,s1
  400e48:	00100693          	li	a3,1
  400e4c:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400e50:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400e54:	01841513          	slli	a0,s0,0x18
  400e58:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400e5c:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400e60:	00048513          	mv	a0,s1
  400e64:	00100693          	li	a3,1
  400e68:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400e6c:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400e70:	00f47413          	andi	s0,s0,15
                        putchar("0123456789abcdef"[nibble]);
  400e74:	008f8433          	add	s0,t6,s0
    __asm__ __volatile__ (
  400e78:	00048513          	mv	a0,s1
  400e7c:	00100693          	li	a3,1
  400e80:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400e84:	00044403          	lbu	s0,0(s0)
    __asm__ __volatile__ (
  400e88:	00040513          	mv	a0,s0
  400e8c:	00100693          	li	a3,1
  400e90:	00000073          	ecall
        fmt++;
  400e94:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400e98:	eadff06f          	j	400d44 <printf+0x80>
    __asm__ __volatile__ (
  400e9c:	00058513          	mv	a0,a1
  400ea0:	00100693          	li	a3,1
  400ea4:	00000073          	ecall
        fmt++;
  400ea8:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400eac:	e99ff06f          	j	400d44 <printf+0x80>
                    const char *s = va_arg(vargs, const char *);
  400eb0:	00c12503          	lw	a0,12(sp)
  400eb4:	00450693          	addi	a3,a0,4
  400eb8:	00d12623          	sw	a3,12(sp)
  400ebc:	00052483          	lw	s1,0(a0)
                    while (*s) {
  400ec0:	0004c403          	lbu	s0,0(s1)
  400ec4:	e6040ee3          	beqz	s0,400d40 <printf+0x7c>
  400ec8:	00148493          	addi	s1,s1,1
    __asm__ __volatile__ (
  400ecc:	00040513          	mv	a0,s0
  400ed0:	00100693          	li	a3,1
  400ed4:	00000073          	ecall
                    while (*s) {
  400ed8:	0004c403          	lbu	s0,0(s1)
  400edc:	00148493          	addi	s1,s1,1
  400ee0:	fe0416e3          	bnez	s0,400ecc <printf+0x208>
  400ee4:	e5dff06f          	j	400d40 <printf+0x7c>
    __asm__ __volatile__ (
  400ee8:	00078513          	mv	a0,a5
  400eec:	00100693          	li	a3,1
  400ef0:	00000073          	ecall
                        u = (unsigned int)(-(value + 1)) + 1;
  400ef4:	409004b3          	neg	s1,s1
  400ef8:	00000513          	li	a0,0
  400efc:	00048693          	mv	a3,s1
  400f00:	00050413          	mv	s0,a0
                        u /= 10;
  400f04:	03e4b933          	mulhu	s2,s1,t5
                        buf[i++] = '0' + (u % 10);
  400f08:	00150513          	addi	a0,a0,1
                        u /= 10;
  400f0c:	00395493          	srli	s1,s2,0x3
                        buf[i++] = '0' + (u % 10);
  400f10:	0f897913          	andi	s2,s2,248
  400f14:	00149993          	slli	s3,s1,0x1
  400f18:	41268933          	sub	s2,a3,s2
  400f1c:	41390933          	sub	s2,s2,s3
  400f20:	03096913          	ori	s2,s2,48
  400f24:	008809b3          	add	s3,a6,s0
  400f28:	01298023          	sb	s2,0(s3)
                    while (u > 0) {
  400f2c:	fcd8e8e3          	bltu	a7,a3,400efc <printf+0x238>
                        putchar(buf[--i]);
  400f30:	00880533          	add	a0,a6,s0
  400f34:	00054483          	lbu	s1,0(a0)
    __asm__ __volatile__ (
  400f38:	00048513          	mv	a0,s1
  400f3c:	00100693          	li	a3,1
  400f40:	00000073          	ecall
                    while (i > 0) {
  400f44:	00140513          	addi	a0,s0,1
  400f48:	fff40413          	addi	s0,s0,-1
  400f4c:	fea342e3          	blt	t1,a0,400f30 <printf+0x26c>
  400f50:	df1ff06f          	j	400d40 <printf+0x7c>
  400f54:	02500593          	li	a1,37
    __asm__ __volatile__ (
  400f58:	00058513          	mv	a0,a1
  400f5c:	00100693          	li	a3,1
  400f60:	00000073          	ecall
}
  400f64:	01c12403          	lw	s0,28(sp)
  400f68:	01812483          	lw	s1,24(sp)
  400f6c:	01412903          	lw	s2,20(sp)
  400f70:	01012983          	lw	s3,16(sp)
  400f74:	04010113          	addi	sp,sp,64
  400f78:	00008067          	ret

00400f7c <putchar>:
{
  400f7c:	00050593          	mv	a1,a0
    __asm__ __volatile__ (
  400f80:	00058513          	mv	a0,a1
  400f84:	00100693          	li	a3,1
  400f88:	00000073          	ecall
}
  400f8c:	00008067          	ret

00400f90 <print_int>:
{
  400f90:	00050593          	mv	a1,a0
    __asm__ __volatile__ (
  400f94:	00058513          	mv	a0,a1
  400f98:	05b00693          	li	a3,91
  400f9c:	00000073          	ecall
}
  400fa0:	00008067          	ret

00400fa4 <call_mic_api>:
    __asm__ __volatile__(
  400fa4:	01400693          	li	a3,20
  400fa8:	00000073          	ecall
}
  400fac:	00008067          	ret

00400fb0 <call_mic_write_file>:
{
  400fb0:	fe010113          	addi	sp,sp,-32
  400fb4:	00112e23          	sw	ra,28(sp)
  400fb8:	00812c23          	sw	s0,24(sp)
  400fbc:	00912a23          	sw	s1,20(sp)
  400fc0:	00050413          	mv	s0,a0
    if (fat32_find(
  400fc4:	00402537          	lui	a0,0x402
  400fc8:	15a50513          	addi	a0,a0,346 # 40215a <__modsi3+0x2d6>
  400fcc:	01010593          	addi	a1,sp,16
  400fd0:	00c10613          	addi	a2,sp,12
  400fd4:	00000097          	auipc	ra,0x0
  400fd8:	49c080e7          	jalr	1180(ra) # 401470 <fat32_find>
            &size) != 0) {
  400fdc:	00050863          	beqz	a0,400fec <call_mic_write_file+0x3c>
        printf("MIC.TXT not found\n");
  400fe0:	00402537          	lui	a0,0x402
  400fe4:	16250513          	addi	a0,a0,354 # 402162 <__modsi3+0x2de>
  400fe8:	0180006f          	j	401000 <call_mic_write_file+0x50>
    if (cluster < 2) {
  400fec:	01012503          	lw	a0,16(sp)
  400ff0:	00100593          	li	a1,1
  400ff4:	02a5e663          	bltu	a1,a0,401020 <call_mic_write_file+0x70>
        printf("MIC.TXT has no cluster\n");
  400ff8:	00402537          	lui	a0,0x402
  400ffc:	17550513          	addi	a0,a0,373 # 402175 <__modsi3+0x2f1>
  401000:	00000097          	auipc	ra,0x0
  401004:	cc4080e7          	jalr	-828(ra) # 400cc4 <printf>
  401008:	00000513          	li	a0,0
}
  40100c:	01c12083          	lw	ra,28(sp)
  401010:	01812403          	lw	s0,24(sp)
  401014:	01412483          	lw	s1,20(sp)
  401018:	02010113          	addi	sp,sp,32
  40101c:	00008067          	ret
        cluster_to_lba(cluster);
  401020:	00000097          	auipc	ra,0x0
  401024:	6f0080e7          	jalr	1776(ra) # 401710 <cluster_to_lba>
        cluster,
  401028:	01012583          	lw	a1,16(sp)
        size
  40102c:	00c12683          	lw	a3,12(sp)
        cluster_to_lba(cluster);
  401030:	00050493          	mv	s1,a0
    printf(
  401034:	00402537          	lui	a0,0x402
  401038:	18d50513          	addi	a0,a0,397 # 40218d <__modsi3+0x309>
  40103c:	00048613          	mv	a2,s1
  401040:	00000097          	auipc	ra,0x0
  401044:	c84080e7          	jalr	-892(ra) # 400cc4 <printf>
    __asm__ __volatile__(
  401048:	01500693          	li	a3,21
  40104c:	00048593          	mv	a1,s1
  401050:	00040513          	mv	a0,s0
  401054:	00000073          	ecall
  401058:	fb5ff06f          	j	40100c <call_mic_write_file+0x5c>

0040105c <call_mic_write_api>:
    __asm__ __volatile__(
  40105c:	01500693          	li	a3,21
  401060:	00000073          	ecall
}
  401064:	00008067          	ret

00401068 <call_sd_read_api>:
    __asm__ __volatile__(
  401068:	01e00693          	li	a3,30
  40106c:	00000073          	ecall
}
  401070:	00008067          	ret

00401074 <call_sd_write_test_api>:
    __asm__ __volatile__(
  401074:	01f00693          	li	a3,31
  401078:	00000073          	ecall
}
  40107c:	00008067          	ret

00401080 <call_sd_write_buf_api>:
    __asm__ __volatile__(
  401080:	02000693          	li	a3,32
  401084:	00000073          	ecall
    return sd_api2(
  401088:	00008067          	ret

0040108c <cmd_speech>:
{
  40108c:	ff010113          	addi	sp,sp,-16
  401090:	00112623          	sw	ra,12(sp)
    printf("Speech recognition start\n");
  401094:	00402537          	lui	a0,0x402
  401098:	1ab50513          	addi	a0,a0,427 # 4021ab <__modsi3+0x327>
  40109c:	00000097          	auipc	ra,0x0
  4010a0:	c28080e7          	jalr	-984(ra) # 400cc4 <printf>
    __asm__ __volatile__(
  4010a4:	03c00693          	li	a3,60
  4010a8:	00200613          	li	a2,2
  4010ac:	00000513          	li	a0,0
  4010b0:	00000073          	ecall
    switch (result) {
  4010b4:	02c50663          	beq	a0,a2,4010e0 <cmd_speech+0x54>
  4010b8:	00050593          	mv	a1,a0
  4010bc:	00100513          	li	a0,1
  4010c0:	00a58a63          	beq	a1,a0,4010d4 <cmd_speech+0x48>
  4010c4:	02059a63          	bnez	a1,4010f8 <cmd_speech+0x6c>
        printf("RESULT: UP\n");
  4010c8:	00402537          	lui	a0,0x402
  4010cc:	1c550513          	addi	a0,a0,453 # 4021c5 <__modsi3+0x341>
  4010d0:	0180006f          	j	4010e8 <cmd_speech+0x5c>
        printf("RESULT: DOWN\n");
  4010d4:	00402537          	lui	a0,0x402
  4010d8:	1d150513          	addi	a0,a0,465 # 4021d1 <__modsi3+0x34d>
  4010dc:	00c0006f          	j	4010e8 <cmd_speech+0x5c>
        printf("RESULT: UNKNOWN\n");
  4010e0:	00402537          	lui	a0,0x402
  4010e4:	1df50513          	addi	a0,a0,479 # 4021df <__modsi3+0x35b>
  4010e8:	00c12083          	lw	ra,12(sp)
  4010ec:	01010113          	addi	sp,sp,16
  4010f0:	00000317          	auipc	t1,0x0
  4010f4:	bd430067          	jr	-1068(t1) # 400cc4 <printf>
        printf("RESULT: ERROR %d\n", result);
  4010f8:	00402537          	lui	a0,0x402
  4010fc:	1f050513          	addi	a0,a0,496 # 4021f0 <__modsi3+0x36c>
  401100:	00c12083          	lw	ra,12(sp)
  401104:	01010113          	addi	sp,sp,16
  401108:	00000317          	auipc	t1,0x0
  40110c:	bbc30067          	jr	-1092(t1) # 400cc4 <printf>

00401110 <call_speech_recognition_api>:
    __asm__ __volatile__(
  401110:	03c00693          	li	a3,60
  401114:	00000513          	li	a0,0
  401118:	00000073          	ecall
    return (int32_t)a0;
  40111c:	00008067          	ret

00401120 <call_dump_api>:
    __asm__ __volatile__(
  401120:	02800693          	li	a3,40
  401124:	00000073          	ecall
}
  401128:	00008067          	ret

0040112c <strcpy>:
    while (*src)
  40112c:	0005c603          	lbu	a2,0(a1)
  401130:	00050693          	mv	a3,a0
  401134:	02060263          	beqz	a2,401158 <strcpy+0x2c>
  401138:	00158593          	addi	a1,a1,1
  40113c:	00050713          	mv	a4,a0
        *d++ = *src++;
  401140:	00c70023          	sb	a2,0(a4)
    while (*src)
  401144:	0005c603          	lbu	a2,0(a1)
        *d++ = *src++;
  401148:	00170693          	addi	a3,a4,1
    while (*src)
  40114c:	00158593          	addi	a1,a1,1
  401150:	00068713          	mv	a4,a3
  401154:	fe0616e3          	bnez	a2,401140 <strcpy+0x14>
    *d = '\0';
  401158:	00068023          	sb	zero,0(a3)
    return dst;
  40115c:	00008067          	ret

00401160 <strcmp>:
    while (*s1 && *s2) {
  401160:	00054603          	lbu	a2,0(a0)
  401164:	02060063          	beqz	a2,401184 <strcmp+0x24>
  401168:	00150513          	addi	a0,a0,1
  40116c:	0005c683          	lbu	a3,0(a1)
  401170:	00d61a63          	bne	a2,a3,401184 <strcmp+0x24>
  401174:	00054603          	lbu	a2,0(a0)
        s2++;
  401178:	00158593          	addi	a1,a1,1
    while (*s1 && *s2) {
  40117c:	00150513          	addi	a0,a0,1
  401180:	fe0616e3          	bnez	a2,40116c <strcmp+0xc>
    return *(unsigned char *)s1 - *(unsigned char *)s2;
  401184:	0005c503          	lbu	a0,0(a1)
  401188:	40a60533          	sub	a0,a2,a0
  40118c:	00008067          	ret

00401190 <parse_u32>:
unsigned parse_u32(const char *s) {
  401190:	00050593          	mv	a1,a0
    if ((s[0] == '0') && (s[1] == 'x' || s[1] == 'X')) {
  401194:	00054503          	lbu	a0,0(a0)
  401198:	03000693          	li	a3,48
  40119c:	02d51663          	bne	a0,a3,4011c8 <parse_u32+0x38>
  4011a0:	0015c503          	lbu	a0,1(a1)
  4011a4:	02056513          	ori	a0,a0,32
  4011a8:	07800613          	li	a2,120
  4011ac:	02c51663          	bne	a0,a2,4011d8 <parse_u32+0x48>
    while (*s) {
  4011b0:	0025c503          	lbu	a0,2(a1)
        s += 2;
  4011b4:	00258593          	addi	a1,a1,2
  4011b8:	01000613          	li	a2,16
  4011bc:	00050693          	mv	a3,a0
    while (*s) {
  4011c0:	00051e63          	bnez	a0,4011dc <parse_u32+0x4c>
  4011c4:	0840006f          	j	401248 <parse_u32+0xb8>
  4011c8:	00a00613          	li	a2,10
  4011cc:	00050693          	mv	a3,a0
  4011d0:	00051663          	bnez	a0,4011dc <parse_u32+0x4c>
  4011d4:	0740006f          	j	401248 <parse_u32+0xb8>
  4011d8:	00a00613          	li	a2,10
  4011dc:	00000513          	li	a0,0
        if (c >= '0' && c <= '9')       d = (unsigned)(c - '0');
  4011e0:	00158593          	addi	a1,a1,1
  4011e4:	00a00713          	li	a4,10
  4011e8:	00600793          	li	a5,6
  4011ec:	00500813          	li	a6,5
  4011f0:	fd068893          	addi	a7,a3,-48
  4011f4:	00e8fa63          	bgeu	a7,a4,401208 <parse_u32+0x78>
  4011f8:	fd000893          	li	a7,-48
  4011fc:	00d888b3          	add	a7,a7,a3
        if (d >= base) break;
  401200:	02c8ea63          	bltu	a7,a2,401234 <parse_u32+0xa4>
  401204:	0440006f          	j	401248 <parse_u32+0xb8>
        else if (c >= 'a' && c <= 'f')  d = 10u + (unsigned)(c - 'a');
  401208:	f9f68893          	addi	a7,a3,-97
  40120c:	00f8fa63          	bgeu	a7,a5,401220 <parse_u32+0x90>
  401210:	fa900893          	li	a7,-87
  401214:	00d888b3          	add	a7,a7,a3
        if (d >= base) break;
  401218:	00c8ee63          	bltu	a7,a2,401234 <parse_u32+0xa4>
  40121c:	02c0006f          	j	401248 <parse_u32+0xb8>
        else if (c >= 'A' && c <= 'F')  d = 10u + (unsigned)(c - 'A');
  401220:	fbf68893          	addi	a7,a3,-65
  401224:	03186263          	bltu	a6,a7,401248 <parse_u32+0xb8>
  401228:	fc900893          	li	a7,-55
  40122c:	00d888b3          	add	a7,a7,a3
        if (d >= base) break;
  401230:	00c8fc63          	bgeu	a7,a2,401248 <parse_u32+0xb8>
    while (*s) {
  401234:	0005c683          	lbu	a3,0(a1)
        v = v * base + d;
  401238:	02c50533          	mul	a0,a0,a2
  40123c:	00a88533          	add	a0,a7,a0
    while (*s) {
  401240:	00158593          	addi	a1,a1,1
  401244:	fa0696e3          	bnez	a3,4011f0 <parse_u32+0x60>
    return v;
  401248:	00008067          	ret

0040124c <is_prime>:
{
  40124c:	00200613          	li	a2,2
    if (n < 2) return false;
  401250:	00c57663          	bgeu	a0,a2,40125c <is_prime+0x10>
  401254:	00000513          	li	a0,0
}
  401258:	00008067          	ret
  40125c:	00050593          	mv	a1,a0
  401260:	00400613          	li	a2,4
  401264:	00100513          	li	a0,1
    for (unsigned i = 2; i * i <= n; i++) {
  401268:	00c5ee63          	bltu	a1,a2,401284 <is_prime+0x38>
  40126c:	00200613          	li	a2,2
        if (n % i == 0)
  401270:	02c5f6b3          	remu	a3,a1,a2
  401274:	fe0680e3          	beqz	a3,401254 <is_prime+0x8>
    for (unsigned i = 2; i * i <= n; i++) {
  401278:	00160613          	addi	a2,a2,1
  40127c:	02c606b3          	mul	a3,a2,a2
  401280:	fed5f8e3          	bgeu	a1,a3,401270 <is_prime+0x24>
}
  401284:	00008067          	ret

00401288 <getchar>:
    __asm__ __volatile__ (
  401288:	00200693          	li	a3,2
  40128c:	00000073          	ecall
  401290:	00050593          	mv	a1,a0
    return ch;
  401294:	00058513          	mv	a0,a1
  401298:	00008067          	ret

0040129c <getchar_timeout>:
    __asm__ __volatile__ (
  40129c:	00300693          	li	a3,3
  4012a0:	00000073          	ecall
  4012a4:	00050593          	mv	a1,a0
    return ch;
  4012a8:	00058513          	mv	a0,a1
  4012ac:	00008067          	ret

004012b0 <call_sd_read_buf_api>:
    __asm__ __volatile__(
  4012b0:	02100693          	li	a3,33
  4012b4:	00000073          	ecall
    return (int)a0;
  4012b8:	00008067          	ret

004012bc <poll_switch_api>:
    __asm__ __volatile__(
  4012bc:	03200693          	li	a3,50
  4012c0:	00000073          	ecall
    return a0;
  4012c4:	00008067          	ret

004012c8 <fat32_cat>:
static uint8_t fat32_buf[512];

fat32_info_t g_fat32;

int fat32_cat(const char *name)
{
  4012c8:	de010113          	addi	sp,sp,-544
  4012cc:	20112e23          	sw	ra,540(sp)
  4012d0:	20812c23          	sw	s0,536(sp)
  4012d4:	20912a23          	sw	s1,532(sp)
  4012d8:	00050413          	mv	s0,a0
    uint8_t buf[512];

    uint32_t cluster;
    uint32_t size;

    if (fat32_mount())
  4012dc:	00000097          	auipc	ra,0x0
  4012e0:	0d8080e7          	jalr	216(ra) # 4013b4 <fat32_mount>
  4012e4:	00050593          	mv	a1,a0
  4012e8:	fff00513          	li	a0,-1
  4012ec:	0a059a63          	bnez	a1,4013a0 <fat32_cat+0xd8>
        return -1;

    if (fat32_find(name, &cluster, &size)) {
  4012f0:	01010593          	addi	a1,sp,16
  4012f4:	00c10613          	addi	a2,sp,12
  4012f8:	00040513          	mv	a0,s0
  4012fc:	00000097          	auipc	ra,0x0
  401300:	174080e7          	jalr	372(ra) # 401470 <fat32_find>
  401304:	00050e63          	beqz	a0,401320 <fat32_cat+0x58>
        printf("file not found\n");
  401308:	00402537          	lui	a0,0x402
  40130c:	21350513          	addi	a0,a0,531 # 402213 <__modsi3+0x38f>
  401310:	00000097          	auipc	ra,0x0
  401314:	9b4080e7          	jalr	-1612(ra) # 400cc4 <printf>
  401318:	fff00513          	li	a0,-1
        return -1;
  40131c:	0840006f          	j	4013a0 <fat32_cat+0xd8>
    }

    uint32_t lba =
        cluster_to_lba(cluster);
  401320:	01012503          	lw	a0,16(sp)
    return -1;
}

uint32_t cluster_to_lba(uint32_t cluster)
{
    return g_fat32.data_begin +
  401324:	004085b7          	lui	a1,0x408
  401328:	24458593          	addi	a1,a1,580 # 408244 <g_fat32>
           (cluster - 2) *
           g_fat32.sectors_per_cluster;
  40132c:	0105a603          	lw	a2,16(a1)
    return g_fat32.data_begin +
  401330:	0085a583          	lw	a1,8(a1)
           (cluster - 2) *
  401334:	ffe50513          	addi	a0,a0,-2
  401338:	02a60533          	mul	a0,a2,a0
    return g_fat32.data_begin +
  40133c:	00b50533          	add	a0,a0,a1
    if (call_sd_read_buf_api(lba, buf))
  401340:	01410593          	addi	a1,sp,20
  401344:	00000097          	auipc	ra,0x0
  401348:	f6c080e7          	jalr	-148(ra) # 4012b0 <call_sd_read_buf_api>
  40134c:	00050593          	mv	a1,a0
  401350:	fff00513          	li	a0,-1
  401354:	04059663          	bnez	a1,4013a0 <fat32_cat+0xd8>
  401358:	00c12503          	lw	a0,12(sp)
    for (uint32_t i = 0; i < size; i++) {
  40135c:	02050a63          	beqz	a0,401390 <fat32_cat+0xc8>
  401360:	fff50513          	addi	a0,a0,-1
  401364:	1ff00593          	li	a1,511
  401368:	00b56463          	bltu	a0,a1,401370 <fat32_cat+0xa8>
  40136c:	1ff00513          	li	a0,511
  401370:	01410413          	addi	s0,sp,20
  401374:	00850533          	add	a0,a0,s0
  401378:	00150493          	addi	s1,a0,1
        putchar(buf[i]);
  40137c:	00044503          	lbu	a0,0(s0)
  401380:	00000097          	auipc	ra,0x0
  401384:	bfc080e7          	jalr	-1028(ra) # 400f7c <putchar>
    for (uint32_t i = 0; i < size; i++) {
  401388:	00140413          	addi	s0,s0,1
  40138c:	fe9418e3          	bne	s0,s1,40137c <fat32_cat+0xb4>
    putchar('\n');
  401390:	00a00513          	li	a0,10
  401394:	00000097          	auipc	ra,0x0
  401398:	be8080e7          	jalr	-1048(ra) # 400f7c <putchar>
  40139c:	00000513          	li	a0,0
}
  4013a0:	21c12083          	lw	ra,540(sp)
  4013a4:	21812403          	lw	s0,536(sp)
  4013a8:	21412483          	lw	s1,532(sp)
  4013ac:	22010113          	addi	sp,sp,544
  4013b0:	00008067          	ret

004013b4 <fat32_mount>:
}

int fat32_mount(void)
{
  4013b4:	ff010113          	addi	sp,sp,-16
  4013b8:	00112623          	sw	ra,12(sp)
  4013bc:	00812423          	sw	s0,8(sp)
  4013c0:	00912223          	sw	s1,4(sp)
  4013c4:	01212023          	sw	s2,0(sp)
    uint8_t *buf = fat32_buf;

    if (call_sd_read_buf_api(0, buf))
  4013c8:	004085b7          	lui	a1,0x408
  4013cc:	25858593          	addi	a1,a1,600 # 408258 <fat32_buf>
  4013d0:	00000513          	li	a0,0
  4013d4:	00000097          	auipc	ra,0x0
  4013d8:	edc080e7          	jalr	-292(ra) # 4012b0 <call_sd_read_buf_api>
  4013dc:	fff00413          	li	s0,-1
  4013e0:	06051a63          	bnez	a0,401454 <fat32_mount+0xa0>
        return -1;

    g_fat32.part_lba =
        ((uint32_t)buf[0x1C6]) |
  4013e4:	00408937          	lui	s2,0x408
  4013e8:	24490493          	addi	s1,s2,580 # 408244 <g_fat32>
        ((uint32_t)buf[0x1C7] << 8) |
        ((uint32_t)buf[0x1C8] << 16) |
  4013ec:	1dc4c503          	lbu	a0,476(s1)
        ((uint32_t)buf[0x1C6]) |
  4013f0:	1da4d583          	lhu	a1,474(s1)
        ((uint32_t)buf[0x1C9] << 24);
  4013f4:	1dd4c603          	lbu	a2,477(s1)
        ((uint32_t)buf[0x1C8] << 16) |
  4013f8:	01051513          	slli	a0,a0,0x10
        ((uint32_t)buf[0x1C7] << 8) |
  4013fc:	00a5e533          	or	a0,a1,a0
        ((uint32_t)buf[0x1C6]) |
  401400:	01448593          	addi	a1,s1,20
        ((uint32_t)buf[0x1C9] << 24);
  401404:	01861613          	slli	a2,a2,0x18
        ((uint32_t)buf[0x1C8] << 16) |
  401408:	00c56533          	or	a0,a0,a2
    g_fat32.part_lba =
  40140c:	24a92223          	sw	a0,580(s2)

    if (call_sd_read_buf_api(g_fat32.part_lba, buf))
  401410:	00000097          	auipc	ra,0x0
  401414:	ea0080e7          	jalr	-352(ra) # 4012b0 <call_sd_read_buf_api>
  401418:	02051e63          	bnez	a0,401454 <fat32_mount+0xa0>
  40141c:	00000413          	li	s0,0
        ((uint32_t)buf[45] << 8) |
        ((uint32_t)buf[46] << 16) |
        ((uint32_t)buf[47] << 24);

    g_fat32.fat_begin =
        g_fat32.part_lba + reserved;
  401420:	24492503          	lw	a0,580(s2)
        ((uint32_t)buf[14]) |
  401424:	0224d583          	lhu	a1,34(s1)
        (uint32_t)buf[16];
  401428:	0244c603          	lbu	a2,36(s1)
        ((uint32_t)buf[38] << 16) |
  40142c:	0384a683          	lw	a3,56(s1)
        (uint32_t)buf[13];
  401430:	0214c703          	lbu	a4,33(s1)
        g_fat32.part_lba + reserved;
  401434:	00b50533          	add	a0,a0,a1

    g_fat32.data_begin =
        g_fat32.fat_begin + fat_count * fat_size;
  401438:	02c685b3          	mul	a1,a3,a2
        ((uint32_t)buf[46] << 16) |
  40143c:	0404a603          	lw	a2,64(s1)
        g_fat32.fat_begin + fat_count * fat_size;
  401440:	00b505b3          	add	a1,a0,a1
    g_fat32.fat_begin =
  401444:	00a4a223          	sw	a0,4(s1)
    g_fat32.data_begin =
  401448:	00b4a423          	sw	a1,8(s1)
    g_fat32.root_cluster =
  40144c:	00c4a623          	sw	a2,12(s1)
    g_fat32.sectors_per_cluster =
  401450:	00e4a823          	sw	a4,16(s1)

    return 0;
}
  401454:	00040513          	mv	a0,s0
  401458:	00c12083          	lw	ra,12(sp)
  40145c:	00812403          	lw	s0,8(sp)
  401460:	00412483          	lw	s1,4(sp)
  401464:	00012903          	lw	s2,0(sp)
  401468:	01010113          	addi	sp,sp,16
  40146c:	00008067          	ret

00401470 <fat32_find>:
{
  401470:	fc010113          	addi	sp,sp,-64
  401474:	02112e23          	sw	ra,60(sp)
  401478:	02812c23          	sw	s0,56(sp)
  40147c:	02912a23          	sw	s1,52(sp)
  401480:	03212823          	sw	s2,48(sp)
  401484:	03312623          	sw	s3,44(sp)
  401488:	03412423          	sw	s4,40(sp)
  40148c:	03512223          	sw	s5,36(sp)
  401490:	03612023          	sw	s6,32(sp)
  401494:	01712e23          	sw	s7,28(sp)
  401498:	01812c23          	sw	s8,24(sp)
  40149c:	01912a23          	sw	s9,20(sp)
  4014a0:	01a12823          	sw	s10,16(sp)
  4014a4:	00060493          	mv	s1,a2
  4014a8:	00058913          	mv	s2,a1
  4014ac:	00050993          	mv	s3,a0
    if (fat32_mount())
  4014b0:	00000097          	auipc	ra,0x0
  4014b4:	f04080e7          	jalr	-252(ra) # 4013b4 <fat32_mount>
  4014b8:	fff00413          	li	s0,-1
  4014bc:	02051a63          	bnez	a0,4014f0 <fat32_find+0x80>
        cluster_to_lba(g_fat32.root_cluster);
  4014c0:	00408a37          	lui	s4,0x408
  4014c4:	244a0a13          	addi	s4,s4,580 # 408244 <g_fat32>
  4014c8:	00ca2503          	lw	a0,12(s4)
           g_fat32.sectors_per_cluster;
  4014cc:	010a2583          	lw	a1,16(s4)
    return g_fat32.data_begin +
  4014d0:	008a2603          	lw	a2,8(s4)
           (cluster - 2) *
  4014d4:	ffe50513          	addi	a0,a0,-2
  4014d8:	02a58533          	mul	a0,a1,a0
    return g_fat32.data_begin +
  4014dc:	00c50533          	add	a0,a0,a2
    if (call_sd_read_buf_api(root_lba, buf))
  4014e0:	014a0593          	addi	a1,s4,20
  4014e4:	00000097          	auipc	ra,0x0
  4014e8:	dcc080e7          	jalr	-564(ra) # 4012b0 <call_sd_read_buf_api>
  4014ec:	04050063          	beqz	a0,40152c <fat32_find+0xbc>
}
  4014f0:	00040513          	mv	a0,s0
  4014f4:	03c12083          	lw	ra,60(sp)
  4014f8:	03812403          	lw	s0,56(sp)
  4014fc:	03412483          	lw	s1,52(sp)
  401500:	03012903          	lw	s2,48(sp)
  401504:	02c12983          	lw	s3,44(sp)
  401508:	02812a03          	lw	s4,40(sp)
  40150c:	02412a83          	lw	s5,36(sp)
  401510:	02012b03          	lw	s6,32(sp)
  401514:	01c12b83          	lw	s7,28(sp)
  401518:	01812c03          	lw	s8,24(sp)
  40151c:	01412c83          	lw	s9,20(sp)
  401520:	01012d03          	lw	s10,16(sp)
  401524:	04010113          	addi	sp,sp,64
  401528:	00008067          	ret
  40152c:	019a0a13          	addi	s4,s4,25
  401530:	01000a93          	li	s5,16
  401534:	0e500b13          	li	s6,229
  401538:	00f00b93          	li	s7,15
  40153c:	02000c13          	li	s8,32
  401540:	00310c93          	addi	s9,sp,3
  401544:	02e00d13          	li	s10,46
  401548:	0380006f          	j	401580 <fat32_find+0x110>
                    shortname[k++] = e[j];
  40154c:	00158513          	addi	a0,a1,1
  401550:	00bc85b3          	add	a1,s9,a1
  401554:	00c58023          	sb	a2,0(a1)
        shortname[k] = '\0';
  401558:	00ac8533          	add	a0,s9,a0
  40155c:	00050023          	sb	zero,0(a0)
        if (strcmp(shortname, name) == 0) {
  401560:	00310513          	addi	a0,sp,3
  401564:	00098593          	mv	a1,s3
  401568:	00000097          	auipc	ra,0x0
  40156c:	bf8080e7          	jalr	-1032(ra) # 401160 <strcmp>
  401570:	14050063          	beqz	a0,4016b0 <fat32_find+0x240>
    for (int i = 0; i < 16; i++) {
  401574:	fffa8a93          	addi	s5,s5,-1
  401578:	020a0a13          	addi	s4,s4,32
  40157c:	f60a8ae3          	beqz	s5,4014f0 <fat32_find+0x80>
        if (e[0] == 0x00)
  401580:	ffba4503          	lbu	a0,-5(s4)
  401584:	ff6508e3          	beq	a0,s6,401574 <fat32_find+0x104>
  401588:	f60504e3          	beqz	a0,4014f0 <fat32_find+0x80>
        if (e[11] == 0x0F)
  40158c:	006a4583          	lbu	a1,6(s4)
  401590:	ff7582e3          	beq	a1,s7,401574 <fat32_find+0x104>
            if (e[j] != ' ')
  401594:	01851a63          	bne	a0,s8,4015a8 <fat32_find+0x138>
  401598:	00000513          	li	a0,0
  40159c:	ffca4583          	lbu	a1,-4(s4)
  4015a0:	01859c63          	bne	a1,s8,4015b8 <fat32_find+0x148>
  4015a4:	0200006f          	j	4015c4 <fat32_find+0x154>
                shortname[k++] = e[j];
  4015a8:	00a101a3          	sb	a0,3(sp)
  4015ac:	00100513          	li	a0,1
            if (e[j] != ' ')
  4015b0:	ffca4583          	lbu	a1,-4(s4)
  4015b4:	01858863          	beq	a1,s8,4015c4 <fat32_find+0x154>
                shortname[k++] = e[j];
  4015b8:	00ac8633          	add	a2,s9,a0
  4015bc:	00150513          	addi	a0,a0,1
  4015c0:	00b60023          	sb	a1,0(a2)
            if (e[j] != ' ')
  4015c4:	ffda4583          	lbu	a1,-3(s4)
  4015c8:	03859c63          	bne	a1,s8,401600 <fat32_find+0x190>
  4015cc:	ffea4583          	lbu	a1,-2(s4)
  4015d0:	05859263          	bne	a1,s8,401614 <fat32_find+0x1a4>
  4015d4:	fffa4583          	lbu	a1,-1(s4)
  4015d8:	05859863          	bne	a1,s8,401628 <fat32_find+0x1b8>
  4015dc:	000a4583          	lbu	a1,0(s4)
  4015e0:	05859e63          	bne	a1,s8,40163c <fat32_find+0x1cc>
  4015e4:	001a4583          	lbu	a1,1(s4)
  4015e8:	07859463          	bne	a1,s8,401650 <fat32_find+0x1e0>
  4015ec:	002a4583          	lbu	a1,2(s4)
  4015f0:	07859a63          	bne	a1,s8,401664 <fat32_find+0x1f4>
        if (e[8] != ' ') {
  4015f4:	003a4583          	lbu	a1,3(s4)
  4015f8:	f78580e3          	beq	a1,s8,401558 <fat32_find+0xe8>
  4015fc:	07c0006f          	j	401678 <fat32_find+0x208>
                shortname[k++] = e[j];
  401600:	00ac8633          	add	a2,s9,a0
  401604:	00150513          	addi	a0,a0,1
  401608:	00b60023          	sb	a1,0(a2)
            if (e[j] != ' ')
  40160c:	ffea4583          	lbu	a1,-2(s4)
  401610:	fd8582e3          	beq	a1,s8,4015d4 <fat32_find+0x164>
                shortname[k++] = e[j];
  401614:	00ac8633          	add	a2,s9,a0
  401618:	00150513          	addi	a0,a0,1
  40161c:	00b60023          	sb	a1,0(a2)
            if (e[j] != ' ')
  401620:	fffa4583          	lbu	a1,-1(s4)
  401624:	fb858ce3          	beq	a1,s8,4015dc <fat32_find+0x16c>
                shortname[k++] = e[j];
  401628:	00ac8633          	add	a2,s9,a0
  40162c:	00150513          	addi	a0,a0,1
  401630:	00b60023          	sb	a1,0(a2)
            if (e[j] != ' ')
  401634:	000a4583          	lbu	a1,0(s4)
  401638:	fb8586e3          	beq	a1,s8,4015e4 <fat32_find+0x174>
                shortname[k++] = e[j];
  40163c:	00ac8633          	add	a2,s9,a0
  401640:	00150513          	addi	a0,a0,1
  401644:	00b60023          	sb	a1,0(a2)
            if (e[j] != ' ')
  401648:	001a4583          	lbu	a1,1(s4)
  40164c:	fb8580e3          	beq	a1,s8,4015ec <fat32_find+0x17c>
                shortname[k++] = e[j];
  401650:	00ac8633          	add	a2,s9,a0
  401654:	00150513          	addi	a0,a0,1
  401658:	00b60023          	sb	a1,0(a2)
            if (e[j] != ' ')
  40165c:	002a4583          	lbu	a1,2(s4)
  401660:	f9858ae3          	beq	a1,s8,4015f4 <fat32_find+0x184>
                shortname[k++] = e[j];
  401664:	00ac8633          	add	a2,s9,a0
  401668:	00150513          	addi	a0,a0,1
  40166c:	00b60023          	sb	a1,0(a2)
        if (e[8] != ' ') {
  401670:	003a4583          	lbu	a1,3(s4)
  401674:	ef8582e3          	beq	a1,s8,401558 <fat32_find+0xe8>
                if (e[j] != ' ')
  401678:	004a4603          	lbu	a2,4(s4)
            shortname[k++] = '.';
  40167c:	00ac86b3          	add	a3,s9,a0
  401680:	01a68023          	sb	s10,0(a3)
                    shortname[k++] = e[j];
  401684:	00b680a3          	sb	a1,1(a3)
  401688:	00250593          	addi	a1,a0,2
                if (e[j] != ' ')
  40168c:	01860a63          	beq	a2,s8,4016a0 <fat32_find+0x230>
                    shortname[k++] = e[j];
  401690:	00bc85b3          	add	a1,s9,a1
  401694:	00350513          	addi	a0,a0,3
  401698:	00c58023          	sb	a2,0(a1)
  40169c:	00050593          	mv	a1,a0
                if (e[j] != ' ')
  4016a0:	005a4603          	lbu	a2,5(s4)
  4016a4:	eb8614e3          	bne	a2,s8,40154c <fat32_find+0xdc>
  4016a8:	00058513          	mv	a0,a1
  4016ac:	eadff06f          	j	401558 <fat32_find+0xe8>
  4016b0:	00000413          	li	s0,0
                ((uint32_t)e[21] << 8);
  4016b4:	010a4503          	lbu	a0,16(s4)
                ((uint32_t)e[20]) |
  4016b8:	00fa4583          	lbu	a1,15(s4)
                ((uint32_t)e[26]) |
  4016bc:	015a4603          	lbu	a2,21(s4)
                ((uint32_t)e[27] << 8);
  4016c0:	016a4683          	lbu	a3,22(s4)
                (cl_hi << 16) | cl_lo;
  4016c4:	01851513          	slli	a0,a0,0x18
  4016c8:	01059593          	slli	a1,a1,0x10
                ((uint32_t)e[26]) |
  4016cc:	00b56533          	or	a0,a0,a1
                ((uint32_t)e[27] << 8);
  4016d0:	00869693          	slli	a3,a3,0x8
                (cl_hi << 16) | cl_lo;
  4016d4:	00d66633          	or	a2,a2,a3
  4016d8:	00c56533          	or	a0,a0,a2
            *cluster =
  4016dc:	00a92023          	sw	a0,0(s2)
                ((uint32_t)e[29] << 8) |
  4016e0:	018a4503          	lbu	a0,24(s4)
                ((uint32_t)e[30] << 16) |
  4016e4:	019a4583          	lbu	a1,25(s4)
                ((uint32_t)e[31] << 24);
  4016e8:	01aa4603          	lbu	a2,26(s4)
                ((uint32_t)e[28]) |
  4016ec:	017a4683          	lbu	a3,23(s4)
                ((uint32_t)e[29] << 8) |
  4016f0:	00851513          	slli	a0,a0,0x8
                ((uint32_t)e[30] << 16) |
  4016f4:	01059593          	slli	a1,a1,0x10
                ((uint32_t)e[31] << 24);
  4016f8:	01861613          	slli	a2,a2,0x18
                ((uint32_t)e[28]) |
  4016fc:	00d56533          	or	a0,a0,a3
                ((uint32_t)e[29] << 8) |
  401700:	00c5e5b3          	or	a1,a1,a2
                ((uint32_t)e[30] << 16) |
  401704:	00b56533          	or	a0,a0,a1
            *size =
  401708:	00a4a023          	sw	a0,0(s1)
  40170c:	de5ff06f          	j	4014f0 <fat32_find+0x80>

00401710 <cluster_to_lba>:
    return g_fat32.data_begin +
  401710:	004085b7          	lui	a1,0x408
  401714:	24458593          	addi	a1,a1,580 # 408244 <g_fat32>
           g_fat32.sectors_per_cluster;
  401718:	0105a603          	lw	a2,16(a1)
    return g_fat32.data_begin +
  40171c:	0085a583          	lw	a1,8(a1)
           (cluster - 2) *
  401720:	ffe50513          	addi	a0,a0,-2
  401724:	02a60533          	mul	a0,a2,a0
    return g_fat32.data_begin +
  401728:	00b50533          	add	a0,a0,a1
  40172c:	00008067          	ret

00401730 <fat32_ls>:

void fat32_ls(void)
{
  401730:	fd010113          	addi	sp,sp,-48
  401734:	02112623          	sw	ra,44(sp)
  401738:	02812423          	sw	s0,40(sp)
  40173c:	02912223          	sw	s1,36(sp)
  401740:	03212023          	sw	s2,32(sp)
  401744:	01312e23          	sw	s3,28(sp)
  401748:	01412c23          	sw	s4,24(sp)
  40174c:	01512a23          	sw	s5,20(sp)
  401750:	01612823          	sw	s6,16(sp)
  401754:	01712623          	sw	s7,12(sp)
  401758:	01812423          	sw	s8,8(sp)
    uint8_t *buf = fat32_buf;

    if (fat32_mount())
  40175c:	00000097          	auipc	ra,0x0
  401760:	c58080e7          	jalr	-936(ra) # 4013b4 <fat32_mount>
  401764:	02051a63          	bnez	a0,401798 <fat32_ls+0x68>
        return;

    uint32_t root_lba =
        cluster_to_lba(g_fat32.root_cluster);
  401768:	00408937          	lui	s2,0x408
  40176c:	24490913          	addi	s2,s2,580 # 408244 <g_fat32>
  401770:	00c92503          	lw	a0,12(s2)
           g_fat32.sectors_per_cluster;
  401774:	01092583          	lw	a1,16(s2)
    return g_fat32.data_begin +
  401778:	00892603          	lw	a2,8(s2)
           (cluster - 2) *
  40177c:	ffe50513          	addi	a0,a0,-2
  401780:	02a58533          	mul	a0,a1,a0
    return g_fat32.data_begin +
  401784:	00c50533          	add	a0,a0,a2

    if (call_sd_read_buf_api(root_lba, buf))
  401788:	01490593          	addi	a1,s2,20
  40178c:	00000097          	auipc	ra,0x0
  401790:	b24080e7          	jalr	-1244(ra) # 4012b0 <call_sd_read_buf_api>
  401794:	02050a63          	beqz	a0,4017c8 <fat32_ls+0x98>
        printf(" cl=%x lba=%x size=%x\n",
                cl,
                lba,
                size);
    }
}
  401798:	02c12083          	lw	ra,44(sp)
  40179c:	02812403          	lw	s0,40(sp)
  4017a0:	02412483          	lw	s1,36(sp)
  4017a4:	02012903          	lw	s2,32(sp)
  4017a8:	01c12983          	lw	s3,28(sp)
  4017ac:	01812a03          	lw	s4,24(sp)
  4017b0:	01412a83          	lw	s5,20(sp)
  4017b4:	01012b03          	lw	s6,16(sp)
  4017b8:	00c12b83          	lw	s7,12(sp)
  4017bc:	00812c03          	lw	s8,8(sp)
  4017c0:	03010113          	addi	sp,sp,48
  4017c4:	00008067          	ret
  4017c8:	01990993          	addi	s3,s2,25
  4017cc:	01000a13          	li	s4,16
  4017d0:	0e500a93          	li	s5,229
  4017d4:	00f00b13          	li	s6,15
  4017d8:	02000b93          	li	s7,32
  4017dc:	00402437          	lui	s0,0x402
  4017e0:	22340413          	addi	s0,s0,547 # 402223 <__modsi3+0x39f>
  4017e4:	00200c13          	li	s8,2
  4017e8:	004024b7          	lui	s1,0x402
  4017ec:	19448493          	addi	s1,s1,404 # 402194 <__modsi3+0x310>
  4017f0:	0580006f          	j	401848 <fat32_ls+0x118>
           g_fat32.sectors_per_cluster;
  4017f4:	01092503          	lw	a0,16(s2)
    return g_fat32.data_begin +
  4017f8:	00892603          	lw	a2,8(s2)
           (cluster - 2) *
  4017fc:	ffe58693          	addi	a3,a1,-2
  401800:	02d50533          	mul	a0,a0,a3
    return g_fat32.data_begin +
  401804:	00c50633          	add	a2,a0,a2
            ((uint32_t)e[29] << 8) |
  401808:	0189c503          	lbu	a0,24(s3)
            ((uint32_t)e[28]) |
  40180c:	0179c683          	lbu	a3,23(s3)
            ((uint32_t)e[30] << 16) |
  401810:	0199c703          	lbu	a4,25(s3)
            ((uint32_t)e[31] << 24);
  401814:	01a9c783          	lbu	a5,26(s3)
            ((uint32_t)e[29] << 8) |
  401818:	00851513          	slli	a0,a0,0x8
            ((uint32_t)e[28]) |
  40181c:	00d56533          	or	a0,a0,a3
            ((uint32_t)e[30] << 16) |
  401820:	01071713          	slli	a4,a4,0x10
            ((uint32_t)e[31] << 24);
  401824:	01879793          	slli	a5,a5,0x18
            ((uint32_t)e[29] << 8) |
  401828:	00f766b3          	or	a3,a4,a5
            ((uint32_t)e[30] << 16) |
  40182c:	00d566b3          	or	a3,a0,a3
        printf(" cl=%x lba=%x size=%x\n",
  401830:	00048513          	mv	a0,s1
  401834:	fffff097          	auipc	ra,0xfffff
  401838:	490080e7          	jalr	1168(ra) # 400cc4 <printf>
    for (int i = 0; i < 16; i++) {
  40183c:	fffa0a13          	addi	s4,s4,-1
  401840:	02098993          	addi	s3,s3,32
  401844:	f40a0ae3          	beqz	s4,401798 <fat32_ls+0x68>
        if (e[0] == 0x00)
  401848:	ffb9c503          	lbu	a0,-5(s3)
  40184c:	ff5508e3          	beq	a0,s5,40183c <fat32_ls+0x10c>
  401850:	f40504e3          	beqz	a0,401798 <fat32_ls+0x68>
        if (e[11] == 0x0F)
  401854:	0069c583          	lbu	a1,6(s3)
  401858:	ff6582e3          	beq	a1,s6,40183c <fat32_ls+0x10c>
            if (e[j] != ' ')
  40185c:	05751463          	bne	a0,s7,4018a4 <fat32_ls+0x174>
  401860:	ffc9c503          	lbu	a0,-4(s3)
  401864:	05751863          	bne	a0,s7,4018b4 <fat32_ls+0x184>
  401868:	ffd9c503          	lbu	a0,-3(s3)
  40186c:	05751c63          	bne	a0,s7,4018c4 <fat32_ls+0x194>
  401870:	ffe9c503          	lbu	a0,-2(s3)
  401874:	07751063          	bne	a0,s7,4018d4 <fat32_ls+0x1a4>
  401878:	fff9c503          	lbu	a0,-1(s3)
  40187c:	07751463          	bne	a0,s7,4018e4 <fat32_ls+0x1b4>
  401880:	0009c503          	lbu	a0,0(s3)
  401884:	07751863          	bne	a0,s7,4018f4 <fat32_ls+0x1c4>
  401888:	0019c503          	lbu	a0,1(s3)
  40188c:	07751c63          	bne	a0,s7,401904 <fat32_ls+0x1d4>
  401890:	0029c503          	lbu	a0,2(s3)
  401894:	09751063          	bne	a0,s7,401914 <fat32_ls+0x1e4>
        if (e[8] != ' ') {
  401898:	0039c503          	lbu	a0,3(s3)
  40189c:	09751463          	bne	a0,s7,401924 <fat32_ls+0x1f4>
  4018a0:	0b00006f          	j	401950 <fat32_ls+0x220>
                putchar(e[j]);
  4018a4:	fffff097          	auipc	ra,0xfffff
  4018a8:	6d8080e7          	jalr	1752(ra) # 400f7c <putchar>
            if (e[j] != ' ')
  4018ac:	ffc9c503          	lbu	a0,-4(s3)
  4018b0:	fb750ce3          	beq	a0,s7,401868 <fat32_ls+0x138>
                putchar(e[j]);
  4018b4:	fffff097          	auipc	ra,0xfffff
  4018b8:	6c8080e7          	jalr	1736(ra) # 400f7c <putchar>
            if (e[j] != ' ')
  4018bc:	ffd9c503          	lbu	a0,-3(s3)
  4018c0:	fb7508e3          	beq	a0,s7,401870 <fat32_ls+0x140>
                putchar(e[j]);
  4018c4:	fffff097          	auipc	ra,0xfffff
  4018c8:	6b8080e7          	jalr	1720(ra) # 400f7c <putchar>
            if (e[j] != ' ')
  4018cc:	ffe9c503          	lbu	a0,-2(s3)
  4018d0:	fb7504e3          	beq	a0,s7,401878 <fat32_ls+0x148>
                putchar(e[j]);
  4018d4:	fffff097          	auipc	ra,0xfffff
  4018d8:	6a8080e7          	jalr	1704(ra) # 400f7c <putchar>
            if (e[j] != ' ')
  4018dc:	fff9c503          	lbu	a0,-1(s3)
  4018e0:	fb7500e3          	beq	a0,s7,401880 <fat32_ls+0x150>
                putchar(e[j]);
  4018e4:	fffff097          	auipc	ra,0xfffff
  4018e8:	698080e7          	jalr	1688(ra) # 400f7c <putchar>
            if (e[j] != ' ')
  4018ec:	0009c503          	lbu	a0,0(s3)
  4018f0:	f9750ce3          	beq	a0,s7,401888 <fat32_ls+0x158>
                putchar(e[j]);
  4018f4:	fffff097          	auipc	ra,0xfffff
  4018f8:	688080e7          	jalr	1672(ra) # 400f7c <putchar>
            if (e[j] != ' ')
  4018fc:	0019c503          	lbu	a0,1(s3)
  401900:	f97508e3          	beq	a0,s7,401890 <fat32_ls+0x160>
                putchar(e[j]);
  401904:	fffff097          	auipc	ra,0xfffff
  401908:	678080e7          	jalr	1656(ra) # 400f7c <putchar>
            if (e[j] != ' ')
  40190c:	0029c503          	lbu	a0,2(s3)
  401910:	f97504e3          	beq	a0,s7,401898 <fat32_ls+0x168>
                putchar(e[j]);
  401914:	fffff097          	auipc	ra,0xfffff
  401918:	668080e7          	jalr	1640(ra) # 400f7c <putchar>
        if (e[8] != ' ') {
  40191c:	0039c503          	lbu	a0,3(s3)
  401920:	03750863          	beq	a0,s7,401950 <fat32_ls+0x220>
            putchar('.');
  401924:	02e00513          	li	a0,46
  401928:	fffff097          	auipc	ra,0xfffff
  40192c:	654080e7          	jalr	1620(ra) # 400f7c <putchar>
                if (e[j] != ' ')
  401930:	0039c503          	lbu	a0,3(s3)
  401934:	07751063          	bne	a0,s7,401994 <fat32_ls+0x264>
  401938:	0049c503          	lbu	a0,4(s3)
  40193c:	07751463          	bne	a0,s7,4019a4 <fat32_ls+0x274>
  401940:	0059c503          	lbu	a0,5(s3)
  401944:	01750663          	beq	a0,s7,401950 <fat32_ls+0x220>
                    putchar(e[j]);
  401948:	fffff097          	auipc	ra,0xfffff
  40194c:	634080e7          	jalr	1588(ra) # 400f7c <putchar>
        printf(" attr=%x", (uint32_t)e[11]);
  401950:	0069c583          	lbu	a1,6(s3)
  401954:	00040513          	mv	a0,s0
  401958:	fffff097          	auipc	ra,0xfffff
  40195c:	36c080e7          	jalr	876(ra) # 400cc4 <printf>
            ((uint32_t)e[27] << 8);
  401960:	0169c503          	lbu	a0,22(s3)
            ((uint32_t)e[21] << 8);
  401964:	0109c583          	lbu	a1,16(s3)
            ((uint32_t)e[20]) |
  401968:	00f9c603          	lbu	a2,15(s3)
            ((uint32_t)e[26]) |
  40196c:	0159c683          	lbu	a3,21(s3)
            ((uint32_t)e[27] << 8);
  401970:	00851513          	slli	a0,a0,0x8
            (cl_hi << 16) | cl_lo;
  401974:	01859593          	slli	a1,a1,0x18
  401978:	01061613          	slli	a2,a2,0x10
            ((uint32_t)e[26]) |
  40197c:	00c5e5b3          	or	a1,a1,a2
            (cl_hi << 16) | cl_lo;
  401980:	00a6e533          	or	a0,a3,a0
  401984:	00a5e5b3          	or	a1,a1,a0
        if (cl >= 2)
  401988:	e785f6e3          	bgeu	a1,s8,4017f4 <fat32_ls+0xc4>
  40198c:	00000613          	li	a2,0
  401990:	e79ff06f          	j	401808 <fat32_ls+0xd8>
                    putchar(e[j]);
  401994:	fffff097          	auipc	ra,0xfffff
  401998:	5e8080e7          	jalr	1512(ra) # 400f7c <putchar>
                if (e[j] != ' ')
  40199c:	0049c503          	lbu	a0,4(s3)
  4019a0:	fb7500e3          	beq	a0,s7,401940 <fat32_ls+0x210>
                    putchar(e[j]);
  4019a4:	fffff097          	auipc	ra,0xfffff
  4019a8:	5d8080e7          	jalr	1496(ra) # 400f7c <putchar>
                if (e[j] != ' ')
  4019ac:	0059c503          	lbu	a0,5(s3)
  4019b0:	f9751ce3          	bne	a0,s7,401948 <fat32_ls+0x218>
  4019b4:	f9dff06f          	j	401950 <fat32_ls+0x220>

004019b8 <fat32_touch>:

    return 0;
}

int fat32_touch(const char *name)
{
  4019b8:	fd010113          	addi	sp,sp,-48
  4019bc:	02112623          	sw	ra,44(sp)
  4019c0:	02812423          	sw	s0,40(sp)
  4019c4:	02912223          	sw	s1,36(sp)
  4019c8:	03212023          	sw	s2,32(sp)
  4019cc:	01312e23          	sw	s3,28(sp)
  4019d0:	01412c23          	sw	s4,24(sp)
  4019d4:	00050413          	mv	s0,a0
    uint8_t *buf = fat32_buf;

    if (fat32_mount())
  4019d8:	00000097          	auipc	ra,0x0
  4019dc:	9dc080e7          	jalr	-1572(ra) # 4013b4 <fat32_mount>
  4019e0:	fff00993          	li	s3,-1
  4019e4:	36051063          	bnez	a0,401d44 <fat32_touch+0x38c>
        return -1;

    uint32_t root_lba =
        cluster_to_lba(g_fat32.root_cluster);
  4019e8:	00408a37          	lui	s4,0x408
  4019ec:	244a0a13          	addi	s4,s4,580 # 408244 <g_fat32>
  4019f0:	00ca2503          	lw	a0,12(s4)
           g_fat32.sectors_per_cluster;
  4019f4:	010a2583          	lw	a1,16(s4)
    return g_fat32.data_begin +
  4019f8:	008a2483          	lw	s1,8(s4)
           (cluster - 2) *
  4019fc:	ffe50513          	addi	a0,a0,-2
  401a00:	02a58533          	mul	a0,a1,a0
    return g_fat32.data_begin +
  401a04:	009504b3          	add	s1,a0,s1

    if (call_sd_read_buf_api(root_lba, buf))
  401a08:	014a0913          	addi	s2,s4,20
  401a0c:	00048513          	mv	a0,s1
  401a10:	00090593          	mv	a1,s2
  401a14:	00000097          	auipc	ra,0x0
  401a18:	89c080e7          	jalr	-1892(ra) # 4012b0 <call_sd_read_buf_api>
  401a1c:	32051463          	bnez	a0,401d44 <fat32_touch+0x38c>
  401a20:	02000593          	li	a1,32
    while (*name &&
  401a24:	00044503          	lbu	a0,0(s0)
        out[i] = ' ';
  401a28:	00b106a3          	sb	a1,13(sp)
  401a2c:	00b10723          	sb	a1,14(sp)
  401a30:	00b107a3          	sb	a1,15(sp)
  401a34:	00b10823          	sb	a1,16(sp)
  401a38:	00b108a3          	sb	a1,17(sp)
  401a3c:	00b10923          	sb	a1,18(sp)
  401a40:	00b109a3          	sb	a1,19(sp)
  401a44:	00b10a23          	sb	a1,20(sp)
  401a48:	00b10aa3          	sb	a1,21(sp)
  401a4c:	00b10b23          	sb	a1,22(sp)
  401a50:	00b10ba3          	sb	a1,23(sp)
    while (*name &&
  401a54:	04050063          	beqz	a0,401a94 <fat32_touch+0xdc>
  401a58:	00000593          	li	a1,0
  401a5c:	02e00613          	li	a2,46
  401a60:	00700693          	li	a3,7
  401a64:	00d10713          	addi	a4,sp,13
           *name != '.' &&
  401a68:	02c50a63          	beq	a0,a2,401a9c <fat32_touch+0xe4>
  401a6c:	02b6e863          	bltu	a3,a1,401a9c <fat32_touch+0xe4>
        out[pos++] = *name++;
  401a70:	00b407b3          	add	a5,s0,a1
  401a74:	00b70833          	add	a6,a4,a1
  401a78:	00a80023          	sb	a0,0(a6)
    while (*name &&
  401a7c:	0017c503          	lbu	a0,1(a5)
        out[pos++] = *name++;
  401a80:	00158793          	addi	a5,a1,1
  401a84:	00078593          	mv	a1,a5
    while (*name &&
  401a88:	fe0510e3          	bnez	a0,401a68 <fat32_touch+0xb0>
    while (*name &&
  401a8c:	00f405b3          	add	a1,s0,a5
  401a90:	0100006f          	j	401aa0 <fat32_touch+0xe8>
  401a94:	00040593          	mv	a1,s0
    while (*name &&
  401a98:	0080006f          	j	401aa0 <fat32_touch+0xe8>
  401a9c:	00b405b3          	add	a1,s0,a1
    while (*name &&
  401aa0:	00158593          	addi	a1,a1,1
  401aa4:	02e00613          	li	a2,46
  401aa8:	00050a63          	beqz	a0,401abc <fat32_touch+0x104>
  401aac:	00c50863          	beq	a0,a2,401abc <fat32_touch+0x104>
  401ab0:	0005c503          	lbu	a0,0(a1)
  401ab4:	00158593          	addi	a1,a1,1
  401ab8:	fe051ae3          	bnez	a0,401aac <fat32_touch+0xf4>
    if (*name == '.')
  401abc:	fd250513          	addi	a0,a0,-46
  401ac0:	00153513          	seqz	a0,a0
    while (*name && pos < 11) {
  401ac4:	00a58533          	add	a0,a1,a0
  401ac8:	fff54583          	lbu	a1,-1(a0)
  401acc:	02058863          	beqz	a1,401afc <fat32_touch+0x144>
  401ad0:	00000613          	li	a2,0
  401ad4:	01510693          	addi	a3,sp,21
  401ad8:	00a00713          	li	a4,10
        out[pos++] = *name++;
  401adc:	00c507b3          	add	a5,a0,a2
  401ae0:	00c68833          	add	a6,a3,a2
  401ae4:	00b80023          	sb	a1,0(a6)
    while (*name && pos < 11) {
  401ae8:	0007c583          	lbu	a1,0(a5)
  401aec:	00058863          	beqz	a1,401afc <fat32_touch+0x144>
  401af0:	00860793          	addi	a5,a2,8
  401af4:	00160613          	addi	a2,a2,1
  401af8:	fee7e2e3          	bltu	a5,a4,401adc <fat32_touch+0x124>

    for (int i = 0; i < 16; i++) {

        uint8_t *e = &buf[i * 32];

        if (e[0] != 0x00 &&
  401afc:	014a4583          	lbu	a1,20(s4)
  401b00:	0e500613          	li	a2,229
  401b04:	00090513          	mv	a0,s2
  401b08:	12c58c63          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401b0c:	00090513          	mv	a0,s2
  401b10:	12058863          	beqz	a1,401c40 <fat32_touch+0x288>
  401b14:	034a4583          	lbu	a1,52(s4)
  401b18:	034a0513          	addi	a0,s4,52
  401b1c:	12058263          	beqz	a1,401c40 <fat32_touch+0x288>
  401b20:	0e500613          	li	a2,229
  401b24:	10c58e63          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401b28:	054a4583          	lbu	a1,84(s4)
  401b2c:	054a0513          	addi	a0,s4,84
  401b30:	10058863          	beqz	a1,401c40 <fat32_touch+0x288>
  401b34:	0e500613          	li	a2,229
  401b38:	10c58463          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401b3c:	074a4583          	lbu	a1,116(s4)
  401b40:	074a0513          	addi	a0,s4,116
  401b44:	0e058e63          	beqz	a1,401c40 <fat32_touch+0x288>
  401b48:	0e500613          	li	a2,229
  401b4c:	0ec58a63          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401b50:	094a4583          	lbu	a1,148(s4)
  401b54:	094a0513          	addi	a0,s4,148
  401b58:	0e058463          	beqz	a1,401c40 <fat32_touch+0x288>
  401b5c:	0e500613          	li	a2,229
  401b60:	0ec58063          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401b64:	0b4a4583          	lbu	a1,180(s4)
  401b68:	0b4a0513          	addi	a0,s4,180
  401b6c:	0c058a63          	beqz	a1,401c40 <fat32_touch+0x288>
  401b70:	0e500613          	li	a2,229
  401b74:	0cc58663          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401b78:	0d4a4583          	lbu	a1,212(s4)
  401b7c:	0d4a0513          	addi	a0,s4,212
  401b80:	0c058063          	beqz	a1,401c40 <fat32_touch+0x288>
  401b84:	0e500613          	li	a2,229
  401b88:	0ac58c63          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401b8c:	0f4a4583          	lbu	a1,244(s4)
  401b90:	0f4a0513          	addi	a0,s4,244
  401b94:	0a058663          	beqz	a1,401c40 <fat32_touch+0x288>
  401b98:	0e500613          	li	a2,229
  401b9c:	0ac58263          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401ba0:	114a4583          	lbu	a1,276(s4)
  401ba4:	114a0513          	addi	a0,s4,276
  401ba8:	08058c63          	beqz	a1,401c40 <fat32_touch+0x288>
  401bac:	0e500613          	li	a2,229
  401bb0:	08c58863          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401bb4:	134a4583          	lbu	a1,308(s4)
  401bb8:	134a0513          	addi	a0,s4,308
  401bbc:	08058263          	beqz	a1,401c40 <fat32_touch+0x288>
  401bc0:	0e500613          	li	a2,229
  401bc4:	06c58e63          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401bc8:	154a4583          	lbu	a1,340(s4)
  401bcc:	154a0513          	addi	a0,s4,340
  401bd0:	06058863          	beqz	a1,401c40 <fat32_touch+0x288>
  401bd4:	0e500613          	li	a2,229
  401bd8:	06c58463          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401bdc:	174a4583          	lbu	a1,372(s4)
  401be0:	174a0513          	addi	a0,s4,372
  401be4:	04058e63          	beqz	a1,401c40 <fat32_touch+0x288>
  401be8:	0e500613          	li	a2,229
  401bec:	04c58a63          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401bf0:	194a4583          	lbu	a1,404(s4)
  401bf4:	194a0513          	addi	a0,s4,404
  401bf8:	04058463          	beqz	a1,401c40 <fat32_touch+0x288>
  401bfc:	0e500613          	li	a2,229
  401c00:	04c58063          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401c04:	1b4a4583          	lbu	a1,436(s4)
  401c08:	1b4a0513          	addi	a0,s4,436
  401c0c:	02058a63          	beqz	a1,401c40 <fat32_touch+0x288>
  401c10:	0e500613          	li	a2,229
  401c14:	02c58663          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401c18:	1d4a4583          	lbu	a1,468(s4)
  401c1c:	1d4a0513          	addi	a0,s4,468
  401c20:	02058063          	beqz	a1,401c40 <fat32_touch+0x288>
  401c24:	0e500613          	li	a2,229
  401c28:	00c58c63          	beq	a1,a2,401c40 <fat32_touch+0x288>
  401c2c:	1f4a4583          	lbu	a1,500(s4)
  401c30:	1f4a0513          	addi	a0,s4,500
  401c34:	00058663          	beqz	a1,401c40 <fat32_touch+0x288>
  401c38:	0e500613          	li	a2,229
  401c3c:	0ec59463          	bne	a1,a2,401d24 <fat32_touch+0x36c>
            e[0] != 0xE5)
            continue;

        for (int j = 0; j < 32; j++)
            e[j] = 0;
  401c40:	00050623          	sb	zero,12(a0)
  401c44:	000506a3          	sb	zero,13(a0)
  401c48:	00050723          	sb	zero,14(a0)
  401c4c:	000507a3          	sb	zero,15(a0)
  401c50:	00050823          	sb	zero,16(a0)
  401c54:	000508a3          	sb	zero,17(a0)
  401c58:	00050923          	sb	zero,18(a0)
  401c5c:	000509a3          	sb	zero,19(a0)

        // archive
        e[11] = 0x20;

        // first cluster = 0
        e[20] = 0;
  401c60:	00050a23          	sb	zero,20(a0)
        e[21] = 0;
  401c64:	00050aa3          	sb	zero,21(a0)
            e[j] = 0;
  401c68:	00050b23          	sb	zero,22(a0)
  401c6c:	00050ba3          	sb	zero,23(a0)
            e[j] = shortname[j];
  401c70:	00d14583          	lbu	a1,13(sp)
  401c74:	00e14603          	lbu	a2,14(sp)
  401c78:	00f14683          	lbu	a3,15(sp)
  401c7c:	01014703          	lbu	a4,16(sp)
  401c80:	01114783          	lbu	a5,17(sp)
  401c84:	01214803          	lbu	a6,18(sp)
  401c88:	01314883          	lbu	a7,19(sp)
  401c8c:	01414283          	lbu	t0,20(sp)
  401c90:	00b50023          	sb	a1,0(a0)
  401c94:	00c500a3          	sb	a2,1(a0)
  401c98:	00d50123          	sb	a3,2(a0)
  401c9c:	00e501a3          	sb	a4,3(a0)
  401ca0:	01514583          	lbu	a1,21(sp)
  401ca4:	01614603          	lbu	a2,22(sp)
  401ca8:	01714683          	lbu	a3,23(sp)
  401cac:	00f50223          	sb	a5,4(a0)
  401cb0:	010502a3          	sb	a6,5(a0)
  401cb4:	01150323          	sb	a7,6(a0)
  401cb8:	005503a3          	sb	t0,7(a0)
  401cbc:	02000713          	li	a4,32
            e[j] = 0;
  401cc0:	00050c23          	sb	zero,24(a0)
  401cc4:	00050ca3          	sb	zero,25(a0)
        e[26] = 0;
  401cc8:	00050d23          	sb	zero,26(a0)
        e[27] = 0;
  401ccc:	00050da3          	sb	zero,27(a0)
            e[j] = shortname[j];
  401cd0:	00b50423          	sb	a1,8(a0)
  401cd4:	00c504a3          	sb	a2,9(a0)
  401cd8:	00d50523          	sb	a3,10(a0)
        e[11] = 0x20;
  401cdc:	00e505a3          	sb	a4,11(a0)

        // size = 0
        e[28] = 0;
  401ce0:	00050e23          	sb	zero,28(a0)
        e[29] = 0;
  401ce4:	00050ea3          	sb	zero,29(a0)
        e[30] = 0;
  401ce8:	00050f23          	sb	zero,30(a0)
        e[31] = 0;
  401cec:	00050fa3          	sb	zero,31(a0)

        printf("USER BUF: ");
  401cf0:	00402537          	lui	a0,0x402
  401cf4:	22c50513          	addi	a0,a0,556 # 40222c <__modsi3+0x3a8>
  401cf8:	fffff097          	auipc	ra,0xfffff
  401cfc:	fcc080e7          	jalr	-52(ra) # 400cc4 <printf>
        for (int i = 0; i < 16; i++) {
            printf("%x ", (uint32_t)buf[i]);
        }
        */

        printf("\n");
  401d00:	00402537          	lui	a0,0x402
  401d04:	f3150513          	addi	a0,a0,-207 # 401f31 <__modsi3+0xad>
  401d08:	fffff097          	auipc	ra,0xfffff
  401d0c:	fbc080e7          	jalr	-68(ra) # 400cc4 <printf>

        if (call_sd_write_buf_api(root_lba, buf))
  401d10:	00048513          	mv	a0,s1
  401d14:	00090593          	mv	a1,s2
  401d18:	fffff097          	auipc	ra,0xfffff
  401d1c:	368080e7          	jalr	872(ra) # 401080 <call_sd_write_buf_api>
  401d20:	00050663          	beqz	a0,401d2c <fat32_touch+0x374>
  401d24:	fff00993          	li	s3,-1
  401d28:	01c0006f          	j	401d44 <fat32_touch+0x38c>
            return -1;

        printf("created: %s\n", name);
  401d2c:	00402537          	lui	a0,0x402
  401d30:	23750513          	addi	a0,a0,567 # 402237 <__modsi3+0x3b3>
  401d34:	00040593          	mv	a1,s0
  401d38:	fffff097          	auipc	ra,0xfffff
  401d3c:	f8c080e7          	jalr	-116(ra) # 400cc4 <printf>
  401d40:	00000993          	li	s3,0

        return 0;
    }

    return -1;
  401d44:	00098513          	mv	a0,s3
  401d48:	02c12083          	lw	ra,44(sp)
  401d4c:	02812403          	lw	s0,40(sp)
  401d50:	02412483          	lw	s1,36(sp)
  401d54:	02012903          	lw	s2,32(sp)
  401d58:	01c12983          	lw	s3,28(sp)
  401d5c:	01812a03          	lw	s4,24(sp)
  401d60:	03010113          	addi	sp,sp,48
  401d64:	00008067          	ret

00401d68 <__udivsi3>:
  401d68:	04058a63          	beqz	a1,401dbc <__udivsi3+0x54>
  401d6c:	00000813          	li	a6,0
  401d70:	00000613          	li	a2,0
  401d74:	01f00693          	li	a3,31
  401d78:	00100713          	li	a4,1
  401d7c:	fff00793          	li	a5,-1
  401d80:	00181813          	slli	a6,a6,0x1
  401d84:	00d558b3          	srl	a7,a0,a3
  401d88:	00d712b3          	sll	t0,a4,a3
  401d8c:	fff68693          	addi	a3,a3,-1
  401d90:	0018f893          	andi	a7,a7,1
  401d94:	0108e833          	or	a6,a7,a6
  401d98:	00b838b3          	sltu	a7,a6,a1
  401d9c:	fff88893          	addi	a7,a7,-1
  401da0:	0058f2b3          	and	t0,a7,t0
  401da4:	00b8f8b3          	and	a7,a7,a1
  401da8:	00c2e633          	or	a2,t0,a2
  401dac:	41180833          	sub	a6,a6,a7
  401db0:	fcf698e3          	bne	a3,a5,401d80 <__udivsi3+0x18>
  401db4:	00060513          	mv	a0,a2
  401db8:	00008067          	ret
  401dbc:	00000513          	li	a0,0
  401dc0:	00008067          	ret

00401dc4 <__umodsi3>:
  401dc4:	00000613          	li	a2,0
  401dc8:	02058a63          	beqz	a1,401dfc <__umodsi3+0x38>
  401dcc:	01f00693          	li	a3,31
  401dd0:	fff00713          	li	a4,-1
  401dd4:	00161613          	slli	a2,a2,0x1
  401dd8:	00d557b3          	srl	a5,a0,a3
  401ddc:	0017f793          	andi	a5,a5,1
  401de0:	00c7e633          	or	a2,a5,a2
  401de4:	00b637b3          	sltu	a5,a2,a1
  401de8:	fff78793          	addi	a5,a5,-1
  401dec:	00b7f7b3          	and	a5,a5,a1
  401df0:	fff68693          	addi	a3,a3,-1
  401df4:	40f60633          	sub	a2,a2,a5
  401df8:	fce69ee3          	bne	a3,a4,401dd4 <__umodsi3+0x10>
  401dfc:	00060513          	mv	a0,a2
  401e00:	00008067          	ret

00401e04 <__divsi3>:
  401e04:	06058c63          	beqz	a1,401e7c <__divsi3+0x78>
  401e08:	00050613          	mv	a2,a0
  401e0c:	00000293          	li	t0,0
  401e10:	00000513          	li	a0,0
  401e14:	41f65793          	srai	a5,a2,0x1f
  401e18:	41f5d813          	srai	a6,a1,0x1f
  401e1c:	01f00693          	li	a3,31
  401e20:	00100713          	li	a4,1
  401e24:	00f648b3          	xor	a7,a2,a5
  401e28:	40f887b3          	sub	a5,a7,a5
  401e2c:	0105c8b3          	xor	a7,a1,a6
  401e30:	41088833          	sub	a6,a7,a6
  401e34:	fff00893          	li	a7,-1
  401e38:	00129293          	slli	t0,t0,0x1
  401e3c:	00d7d333          	srl	t1,a5,a3
  401e40:	00d713b3          	sll	t2,a4,a3
  401e44:	fff68693          	addi	a3,a3,-1
  401e48:	00137313          	andi	t1,t1,1
  401e4c:	005362b3          	or	t0,t1,t0
  401e50:	0102b333          	sltu	t1,t0,a6
  401e54:	fff30313          	addi	t1,t1,-1
  401e58:	007373b3          	and	t2,t1,t2
  401e5c:	01037333          	and	t1,t1,a6
  401e60:	00a3e533          	or	a0,t2,a0
  401e64:	406282b3          	sub	t0,t0,t1
  401e68:	fd1698e3          	bne	a3,a7,401e38 <__divsi3+0x34>
  401e6c:	00c5c5b3          	xor	a1,a1,a2
  401e70:	0005d463          	bgez	a1,401e78 <__divsi3+0x74>
  401e74:	40a00533          	neg	a0,a0
  401e78:	00008067          	ret
  401e7c:	00000513          	li	a0,0
  401e80:	00008067          	ret

00401e84 <__modsi3>:
  401e84:	06058063          	beqz	a1,401ee4 <__modsi3+0x60>
  401e88:	00050613          	mv	a2,a0
  401e8c:	00000513          	li	a0,0
  401e90:	41f65693          	srai	a3,a2,0x1f
  401e94:	41f5d793          	srai	a5,a1,0x1f
  401e98:	00d64733          	xor	a4,a2,a3
  401e9c:	40d706b3          	sub	a3,a4,a3
  401ea0:	01f00713          	li	a4,31
  401ea4:	00f5c5b3          	xor	a1,a1,a5
  401ea8:	40f585b3          	sub	a1,a1,a5
  401eac:	fff00793          	li	a5,-1
  401eb0:	00151513          	slli	a0,a0,0x1
  401eb4:	00e6d833          	srl	a6,a3,a4
  401eb8:	00187813          	andi	a6,a6,1
  401ebc:	00a86533          	or	a0,a6,a0
  401ec0:	00b53833          	sltu	a6,a0,a1
  401ec4:	fff80813          	addi	a6,a6,-1
  401ec8:	00b87833          	and	a6,a6,a1
  401ecc:	fff70713          	addi	a4,a4,-1
  401ed0:	41050533          	sub	a0,a0,a6
  401ed4:	fcf71ee3          	bne	a4,a5,401eb0 <__modsi3+0x2c>
  401ed8:	00065463          	bgez	a2,401ee0 <__modsi3+0x5c>
  401edc:	40a00533          	neg	a0,a0
  401ee0:	00008067          	ret
  401ee4:	00000513          	li	a0,0
  401ee8:	00008067          	ret

Disassembly of section .rodata:

00401eec <.rodata>:
  401eec:	6c656873          	csrrsi	a6,0x6c6,10
  401ef0:	206c                	.insn	2, 0x206c
  401ef2:	72617473          	csrrci	s0,mhpmevent6h,2
  401ef6:	2e74                	.insn	2, 0x2e74
  401ef8:	000a                	.insn	2, 0x000a
  401efa:	20315753          	.insn	4, 0x20315753
  401efe:	7270                	.insn	2, 0x7270
  401f00:	7365                	.insn	2, 0x7365
  401f02:	0a646573          	csrrsi	a0,0xa6,8
  401f06:	5300                	.insn	2, 0x5300
  401f08:	70203257          	.insn	4, 0x70203257
  401f0c:	6572                	.insn	2, 0x6572
  401f0e:	64657373          	csrrci	t1,hviprio1,10
  401f12:	000a                	.insn	2, 0x000a
  401f14:	6568                	.insn	2, 0x6568
  401f16:	6c6c                	.insn	2, 0x6c6c
  401f18:	6548006f          	j	48256c <__user_stack_top+0x5910c>
  401f1c:	6c6c                	.insn	2, 0x6c6c
  401f1e:	6f77206f          	j	474e14 <__user_stack_top+0x4b9b4>
  401f22:	6c72                	.insn	2, 0x6c72
  401f24:	2064                	.insn	2, 0x2064
  401f26:	7266                	.insn	2, 0x7266
  401f28:	73206d6f          	jal	s10,40865a <__user_stack_bottom+0x1fa>
  401f2c:	6568                	.insn	2, 0x6568
  401f2e:	6c6c                	.insn	2, 0x6c6c
  401f30:	0a21                	.insn	2, 0x0a21
  401f32:	6400                	.insn	2, 0x6400
  401f34:	6d75                	.insn	2, 0x6d75
  401f36:	0070                	.insn	2, 0x0070
  401f38:	7270                	.insn	2, 0x7270
  401f3a:	6d69                	.insn	2, 0x6d69
  401f3c:	7365                	.insn	2, 0x7365
  401f3e:	6d00                	.insn	2, 0x6d00
  401f40:	7861                	.insn	2, 0x7861
  401f42:	7420                	.insn	2, 0x7420
  401f44:	6c206f6f          	jal	t5,408606 <__user_stack_bottom+0x1a6>
  401f48:	7261                	.insn	2, 0x7261
  401f4a:	28206567          	.insn	4, 0x28206567
  401f4e:	3d3c                	.insn	2, 0x3d3c
  401f50:	3031                	.insn	2, 0x3031
  401f52:	3030                	.insn	2, 0x3030
  401f54:	3030                	.insn	2, 0x3030
  401f56:	0a29                	.insn	2, 0x0a29
  401f58:	7300                	.insn	2, 0x7300
  401f5a:	6c65                	.insn	2, 0x6c65
  401f5c:	5f66                	.insn	2, 0x5f66
  401f5e:	6574                	.insn	2, 0x6574
  401f60:	73007473          	csrrci	s0,mhpmevent16h,0
  401f64:	5f61                	.insn	2, 0x5f61
  401f66:	72617473          	csrrci	s0,mhpmevent6h,2
  401f6a:	0074                	.insn	2, 0x0074
  401f6c:	616d                	.insn	2, 0x616d
  401f6e:	7274                	.insn	2, 0x7274
  401f70:	7869                	.insn	2, 0x7869
  401f72:	7320                	.insn	2, 0x7320
  401f74:	7a69                	.insn	2, 0x7a69
  401f76:	2065                	.insn	2, 0x2065
  401f78:	203e                	.insn	2, 0x203e
  401f7a:	0a34                	.insn	2, 0x0a34
  401f7c:	6d00                	.insn	2, 0x6d00
  401f7e:	6369                	.insn	2, 0x6369
  401f80:	725f 6165 0064      	.insn	6, 0x00646165725f
  401f86:	7375                	.insn	2, 0x7375
  401f88:	6761                	.insn	2, 0x6761
  401f8a:	3a65                	.insn	2, 0x3a65
  401f8c:	6d20                	.insn	2, 0x6d20
  401f8e:	6369                	.insn	2, 0x6369
  401f90:	725f 6165 2064      	.insn	6, 0x20646165725f
  401f96:	633c                	.insn	2, 0x633c
  401f98:	746e756f          	jal	a0,4e96de <__user_stack_top+0xc027e>
  401f9c:	0a3e                	.insn	2, 0x0a3e
  401f9e:	6d00                	.insn	2, 0x6d00
  401fa0:	6369                	.insn	2, 0x6369
  401fa2:	775f 6972 6574      	.insn	6, 0x65746972775f
  401fa8:	7500                	.insn	2, 0x7500
  401faa:	65676173          	csrrsi	sp,hviprio1h,14
  401fae:	203a                	.insn	2, 0x203a
  401fb0:	696d                	.insn	2, 0x696d
  401fb2:	72775f63          	bge	a4,t2,4026f0 <call_sa_api.matrix_A+0x4ac>
  401fb6:	7469                	.insn	2, 0x7469
  401fb8:	2065                	.insn	2, 0x2065
  401fba:	633c                	.insn	2, 0x633c
  401fbc:	746e756f          	jal	a0,4e9702 <__user_stack_top+0xc02a2>
  401fc0:	0a3e                	.insn	2, 0x0a3e
  401fc2:	7300                	.insn	2, 0x7300
  401fc4:	5f64                	.insn	2, 0x5f64
  401fc6:	6572                	.insn	2, 0x6572
  401fc8:	6461                	.insn	2, 0x6461
  401fca:	7500                	.insn	2, 0x7500
  401fcc:	65676173          	csrrsi	sp,hviprio1h,14
  401fd0:	203a                	.insn	2, 0x203a
  401fd2:	725f6473          	csrrsi	s0,mhpmevent5h,30
  401fd6:	6165                	.insn	2, 0x6165
  401fd8:	2064                	.insn	2, 0x2064
  401fda:	733c                	.insn	2, 0x733c
  401fdc:	6365                	.insn	2, 0x6365
  401fde:	6f74                	.insn	2, 0x6f74
  401fe0:	3e72                	.insn	2, 0x3e72
  401fe2:	000a                	.insn	2, 0x000a
  401fe4:	775f6473          	csrrsi	s0,0x775,30
  401fe8:	6972                	.insn	2, 0x6972
  401fea:	6574                	.insn	2, 0x6574
  401fec:	7500                	.insn	2, 0x7500
  401fee:	65676173          	csrrsi	sp,hviprio1h,14
  401ff2:	203a                	.insn	2, 0x203a
  401ff4:	775f6473          	csrrsi	s0,0x775,30
  401ff8:	6972                	.insn	2, 0x6972
  401ffa:	6574                	.insn	2, 0x6574
  401ffc:	3c20                	.insn	2, 0x3c20
  401ffe:	74636573          	csrrsi	a0,0x746,6
  402002:	0a3e726f          	jal	tp,4e98a4 <__user_stack_top+0xc0444>
  402006:	7300                	.insn	2, 0x7300
  402008:	5f64                	.insn	2, 0x5f64
  40200a:	74636573          	csrrsi	a0,0x746,6
  40200e:	7720726f          	jal	tp,409780 <__user_stack_start+0x320>
  402012:	6972                	.insn	2, 0x6972
  402014:	6574                	.insn	2, 0x6574
  402016:	7320                	.insn	2, 0x7320
  402018:	6365                	.insn	2, 0x6365
  40201a:	6f74                	.insn	2, 0x6f74
  40201c:	2072                	.insn	2, 0x2072
  40201e:	203c                	.insn	2, 0x203c
  402020:	3035                	.insn	2, 0x3035
  402022:	3030                	.insn	2, 0x3030
  402024:	000a                	.insn	2, 0x000a
  402026:	6166                	.insn	2, 0x6166
  402028:	3374                	.insn	2, 0x3374
  40202a:	5f32                	.insn	2, 0x5f32
  40202c:	6e69                	.insn	2, 0x6e69
  40202e:	6f66                	.insn	2, 0x6f66
  402030:	4600                	.insn	2, 0x4600
  402032:	5441                	.insn	2, 0x5441
  402034:	6d203233          	.insn	4, 0x6d203233
  402038:	746e756f          	jal	a0,4e977e <__user_stack_top+0xc031e>
  40203c:	6620                	.insn	2, 0x6620
  40203e:	6961                	.insn	2, 0x6961
  402040:	656c                	.insn	2, 0x656c
  402042:	0a64                	.insn	2, 0x0a64
  402044:	7000                	.insn	2, 0x7000
  402046:	7261                	.insn	2, 0x7261
  402048:	5f74                	.insn	2, 0x5f74
  40204a:	626c                	.insn	2, 0x626c
  40204c:	3d61                	.insn	2, 0x3d61
  40204e:	7825                	.insn	2, 0x7825
  402050:	000a                	.insn	2, 0x000a
  402052:	6f72                	.insn	2, 0x6f72
  402054:	635f746f          	jal	s0,4f9e88 <__user_stack_top+0xd0a28>
  402058:	756c                	.insn	2, 0x756c
  40205a:	72657473          	csrrci	s0,mhpmevent6h,10
  40205e:	253d                	.insn	2, 0x253d
  402060:	0a78                	.insn	2, 0x0a78
  402062:	7300                	.insn	2, 0x7300
  402064:	6370                	.insn	2, 0x6370
  402066:	253d                	.insn	2, 0x253d
  402068:	0a78                	.insn	2, 0x0a78
  40206a:	6600                	.insn	2, 0x6600
  40206c:	7461                	.insn	2, 0x7461
  40206e:	625f 6765 6e69      	.insn	6, 0x6e696765625f
  402074:	253d                	.insn	2, 0x253d
  402076:	0a78                	.insn	2, 0x0a78
  402078:	6400                	.insn	2, 0x6400
  40207a:	7461                	.insn	2, 0x7461
  40207c:	5f61                	.insn	2, 0x5f61
  40207e:	6562                	.insn	2, 0x6562
  402080:	3d6e6967          	.insn	4, 0x3d6e6967
  402084:	7825                	.insn	2, 0x7825
  402086:	000a                	.insn	2, 0x000a
  402088:	6166                	.insn	2, 0x6166
  40208a:	3374                	.insn	2, 0x3374
  40208c:	5f32                	.insn	2, 0x5f32
  40208e:	736c                	.insn	2, 0x736c
  402090:	6600                	.insn	2, 0x6600
  402092:	7461                	.insn	2, 0x7461
  402094:	635f3233          	.insn	4, 0x635f3233
  402098:	7461                	.insn	2, 0x7461
  40209a:	7500                	.insn	2, 0x7500
  40209c:	65676173          	csrrsi	sp,hviprio1h,14
  4020a0:	203a                	.insn	2, 0x203a
  4020a2:	6166                	.insn	2, 0x6166
  4020a4:	3374                	.insn	2, 0x3374
  4020a6:	5f32                	.insn	2, 0x5f32
  4020a8:	20746163          	bltu	s0,t2,4022aa <call_sa_api.matrix_A+0x66>
  4020ac:	663c                	.insn	2, 0x663c
  4020ae:	6c69                	.insn	2, 0x6c69
  4020b0:	3e65                	.insn	2, 0x3e65
  4020b2:	000a                	.insn	2, 0x000a
  4020b4:	6166                	.insn	2, 0x6166
  4020b6:	3374                	.insn	2, 0x3374
  4020b8:	5f32                	.insn	2, 0x5f32
  4020ba:	6f74                	.insn	2, 0x6f74
  4020bc:	6375                	.insn	2, 0x6375
  4020be:	0068                	.insn	2, 0x0068
  4020c0:	7375                	.insn	2, 0x7375
  4020c2:	6761                	.insn	2, 0x6761
  4020c4:	3a65                	.insn	2, 0x3a65
  4020c6:	6620                	.insn	2, 0x6620
  4020c8:	7461                	.insn	2, 0x7461
  4020ca:	745f3233          	.insn	4, 0x745f3233
  4020ce:	6863756f          	jal	a0,439754 <__user_stack_top+0x102f4>
  4020d2:	3c20                	.insn	2, 0x3c20
  4020d4:	6966                	.insn	2, 0x6966
  4020d6:	656c                	.insn	2, 0x656c
  4020d8:	0a3e                	.insn	2, 0x0a3e
  4020da:	6600                	.insn	2, 0x6600
  4020dc:	7461                	.insn	2, 0x7461
  4020de:	745f3233          	.insn	4, 0x745f3233
  4020e2:	6863756f          	jal	a0,439768 <__user_stack_top+0x10308>
  4020e6:	6620                	.insn	2, 0x6620
  4020e8:	6961                	.insn	2, 0x6961
  4020ea:	656c                	.insn	2, 0x656c
  4020ec:	0a64                	.insn	2, 0x0a64
  4020ee:	7300                	.insn	2, 0x7300
  4020f0:	6570                	.insn	2, 0x6570
  4020f2:	6365                	.insn	2, 0x6365
  4020f4:	0068                	.insn	2, 0x0068
  4020f6:	6568                	.insn	2, 0x6568
  4020f8:	706c                	.insn	2, 0x706c
  4020fa:	6300                	.insn	2, 0x6300
  4020fc:	616d6d6f          	jal	s10,4d8712 <__user_stack_top+0xaf2b2>
  402100:	646e                	.insn	2, 0x646e
  402102:	000a3a73          	csrrc	s4,0x0,s4
  402106:	7865                	.insn	2, 0x7865
  402108:	7469                	.insn	2, 0x7469
  40210a:	7100                	.insn	2, 0x7100
  40210c:	6975                	.insn	2, 0x6975
  40210e:	0074                	.insn	2, 0x0074
  402110:	0071                	.insn	2, 0x0071
  402112:	6e75                	.insn	2, 0x6e75
  402114:	776f6e6b          	.insn	4, 0x776f6e6b
  402118:	206e                	.insn	2, 0x206e
  40211a:	6d6d6f63          	bltu	s10,s6,4027f8 <call_sa_api.matrix_A+0x5b4>
  40211e:	6e61                	.insn	2, 0x6e61
  402120:	3a64                	.insn	2, 0x3a64
  402122:	2520                	.insn	2, 0x2520
  402124:	25000a73          	.insn	4, 0x25000a73
  402128:	2064                	.insn	2, 0x2064
  40212a:	7400                	.insn	2, 0x7400
  40212c:	6c61746f          	jal	s0,4197f2 <__user_stack_start+0x10392>
  402130:	7020                	.insn	2, 0x7020
  402132:	6972                	.insn	2, 0x6972
  402134:	656d                	.insn	2, 0x656d
  402136:	25203a73          	csrrc	s4,vsireg2,zero
  40213a:	2064                	.insn	2, 0x2064
  40213c:	3028                	.insn	2, 0x3028
  40213e:	2e2e                	.insn	2, 0x2e2e
  402140:	6425                	.insn	2, 0x6425
  402142:	0a29                	.insn	2, 0x0a29
  402144:	6900                	.insn	2, 0x6900
  402146:	766e                	.insn	2, 0x766e
  402148:	6c61                	.insn	2, 0x6c61
  40214a:	6469                	.insn	2, 0x6469
  40214c:	6d20                	.insn	2, 0x6d20
  40214e:	7461                	.insn	2, 0x7461
  402150:	6972                	.insn	2, 0x6972
  402152:	2078                	.insn	2, 0x2078
  402154:	657a6973          	csrrsi	s2,hviprio2h,20
  402158:	000a                	.insn	2, 0x000a
  40215a:	494d                	.insn	2, 0x494d
  40215c:	58542e43          	.insn	4, 0x58542e43
  402160:	0054                	.insn	2, 0x0054
  402162:	494d                	.insn	2, 0x494d
  402164:	58542e43          	.insn	4, 0x58542e43
  402168:	2054                	.insn	2, 0x2054
  40216a:	6f6e                	.insn	2, 0x6f6e
  40216c:	2074                	.insn	2, 0x2074
  40216e:	6f66                	.insn	2, 0x6f66
  402170:	6e75                	.insn	2, 0x6e75
  402172:	0a64                	.insn	2, 0x0a64
  402174:	4d00                	.insn	2, 0x4d00
  402176:	4349                	.insn	2, 0x4349
  402178:	542e                	.insn	2, 0x542e
  40217a:	5458                	.insn	2, 0x5458
  40217c:	6820                	.insn	2, 0x6820
  40217e:	7361                	.insn	2, 0x7361
  402180:	6e20                	.insn	2, 0x6e20
  402182:	6c63206f          	j	434848 <__user_stack_top+0xb3e8>
  402186:	7375                	.insn	2, 0x7375
  402188:	6574                	.insn	2, 0x6574
  40218a:	0a72                	.insn	2, 0x0a72
  40218c:	4d00                	.insn	2, 0x4d00
  40218e:	4349                	.insn	2, 0x4349
  402190:	542e                	.insn	2, 0x542e
  402192:	5458                	.insn	2, 0x5458
  402194:	6320                	.insn	2, 0x6320
  402196:	3d6c                	.insn	2, 0x3d6c
  402198:	7825                	.insn	2, 0x7825
  40219a:	6c20                	.insn	2, 0x6c20
  40219c:	6162                	.insn	2, 0x6162
  40219e:	253d                	.insn	2, 0x253d
  4021a0:	2078                	.insn	2, 0x2078
  4021a2:	657a6973          	csrrsi	s2,hviprio2h,20
  4021a6:	253d                	.insn	2, 0x253d
  4021a8:	0a78                	.insn	2, 0x0a78
  4021aa:	5300                	.insn	2, 0x5300
  4021ac:	6570                	.insn	2, 0x6570
  4021ae:	6365                	.insn	2, 0x6365
  4021b0:	2068                	.insn	2, 0x2068
  4021b2:	6572                	.insn	2, 0x6572
  4021b4:	6e676f63          	bltu	a4,t1,4028b2 <call_sa_api.matrix_A+0x66e>
  4021b8:	7469                	.insn	2, 0x7469
  4021ba:	6f69                	.insn	2, 0x6f69
  4021bc:	206e                	.insn	2, 0x206e
  4021be:	72617473          	csrrci	s0,mhpmevent6h,2
  4021c2:	0a74                	.insn	2, 0x0a74
  4021c4:	5200                	.insn	2, 0x5200
  4021c6:	5345                	.insn	2, 0x5345
  4021c8:	4c55                	.insn	2, 0x4c55
  4021ca:	3a54                	.insn	2, 0x3a54
  4021cc:	5520                	.insn	2, 0x5520
  4021ce:	0a50                	.insn	2, 0x0a50
  4021d0:	5200                	.insn	2, 0x5200
  4021d2:	5345                	.insn	2, 0x5345
  4021d4:	4c55                	.insn	2, 0x4c55
  4021d6:	3a54                	.insn	2, 0x3a54
  4021d8:	4420                	.insn	2, 0x4420
  4021da:	0a4e574f          	.insn	4, 0x0a4e574f
  4021de:	5200                	.insn	2, 0x5200
  4021e0:	5345                	.insn	2, 0x5345
  4021e2:	4c55                	.insn	2, 0x4c55
  4021e4:	3a54                	.insn	2, 0x3a54
  4021e6:	5520                	.insn	2, 0x5520
  4021e8:	4b4e                	.insn	2, 0x4b4e
  4021ea:	4f4e                	.insn	2, 0x4f4e
  4021ec:	000a4e57          	.insn	4, 0x000a4e57
  4021f0:	4552                	.insn	2, 0x4552
  4021f2:	544c5553          	.insn	4, 0x544c5553
  4021f6:	203a                	.insn	2, 0x203a
  4021f8:	5245                	.insn	2, 0x5245
  4021fa:	4f52                	.insn	2, 0x4f52
  4021fc:	2052                	.insn	2, 0x2052
  4021fe:	6425                	.insn	2, 0x6425
  402200:	000a                	.insn	2, 0x000a
  402202:	3130                	.insn	2, 0x3130
  402204:	3332                	.insn	2, 0x3332
  402206:	3534                	.insn	2, 0x3534
  402208:	3736                	.insn	2, 0x3736
  40220a:	3938                	.insn	2, 0x3938
  40220c:	6261                	.insn	2, 0x6261
  40220e:	66656463          	bltu	a0,t1,402876 <call_sa_api.matrix_A+0x632>
  402212:	6600                	.insn	2, 0x6600
  402214:	6c69                	.insn	2, 0x6c69
  402216:	2065                	.insn	2, 0x2065
  402218:	6f6e                	.insn	2, 0x6f6e
  40221a:	2074                	.insn	2, 0x2074
  40221c:	6f66                	.insn	2, 0x6f66
  40221e:	6e75                	.insn	2, 0x6e75
  402220:	0a64                	.insn	2, 0x0a64
  402222:	2000                	.insn	2, 0x2000
  402224:	7461                	.insn	2, 0x7461
  402226:	7274                	.insn	2, 0x7274
  402228:	253d                	.insn	2, 0x253d
  40222a:	0078                	.insn	2, 0x0078
  40222c:	5355                	.insn	2, 0x5355
  40222e:	5245                	.insn	2, 0x5245
  402230:	4220                	.insn	2, 0x4220
  402232:	4655                	.insn	2, 0x4655
  402234:	203a                	.insn	2, 0x203a
  402236:	6300                	.insn	2, 0x6300
  402238:	6572                	.insn	2, 0x6572
  40223a:	7461                	.insn	2, 0x7461
  40223c:	6465                	.insn	2, 0x6465
  40223e:	203a                	.insn	2, 0x203a
  402240:	7325                	.insn	2, 0x7325
  402242:	000a                	.insn	2, 0x000a

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
 3ba:	5f00                	.insn	2, 0x5f00
 3bc:	0004                	.insn	2, 0x0004
 3be:	0500                	.insn	2, 0x0500
 3c0:	0400                	.insn	2, 0x0400
 3c2:	3000                	.insn	2, 0x3000
 3c4:	0000                	.insn	2, 0x0000
 3c6:	c000                	.insn	2, 0xc000
 3c8:	0000                	.insn	2, 0x0000
 3ca:	c800                	.insn	2, 0xc800
 3cc:	0000                	.insn	2, 0x0000
 3ce:	d600                	.insn	2, 0xd600
 3d0:	0000                	.insn	2, 0x0000
 3d2:	df00                	.insn	2, 0xdf00
 3d4:	0000                	.insn	2, 0x0000
 3d6:	e800                	.insn	2, 0xe800
 3d8:	0000                	.insn	2, 0x0000
 3da:	f200                	.insn	2, 0xf200
 3dc:	0000                	.insn	2, 0x0000
 3de:	fc00                	.insn	2, 0xfc00
 3e0:	0000                	.insn	2, 0x0000
 3e2:	0600                	.insn	2, 0x0600
 3e4:	0001                	.insn	2, 0x0001
 3e6:	1000                	.insn	2, 0x1000
 3e8:	0001                	.insn	2, 0x0001
 3ea:	1b00                	.insn	2, 0x1b00
 3ec:	0001                	.insn	2, 0x0001
 3ee:	2500                	.insn	2, 0x2500
 3f0:	0001                	.insn	2, 0x0001
 3f2:	3000                	.insn	2, 0x3000
 3f4:	0001                	.insn	2, 0x0001
 3f6:	3a00                	.insn	2, 0x3a00
 3f8:	0001                	.insn	2, 0x0001
 3fa:	4500                	.insn	2, 0x4500
 3fc:	0001                	.insn	2, 0x0001
 3fe:	5600                	.insn	2, 0x5600
 400:	0001                	.insn	2, 0x0001
 402:	6700                	.insn	2, 0x6700
 404:	0001                	.insn	2, 0x0001
 406:	8600                	.insn	2, 0x8600
 408:	0001                	.insn	2, 0x0001
 40a:	a900                	.insn	2, 0xa900
 40c:	0001                	.insn	2, 0x0001
 40e:	b300                	.insn	2, 0xb300
 410:	0001                	.insn	2, 0x0001
 412:	0700                	.insn	2, 0x0700
 414:	0002                	.insn	2, 0x0002
 416:	4200                	.insn	2, 0x4200
 418:	0002                	.insn	2, 0x0002
 41a:	5c00                	.insn	2, 0x5c00
 41c:	0002                	.insn	2, 0x0002
 41e:	6d00                	.insn	2, 0x6d00
 420:	0002                	.insn	2, 0x0002
 422:	7e00                	.insn	2, 0x7e00
 424:	0002                	.insn	2, 0x0002
 426:	8800                	.insn	2, 0x8800
 428:	0002                	.insn	2, 0x0002
 42a:	a000                	.insn	2, 0xa000
 42c:	0002                	.insn	2, 0x0002
 42e:	aa00                	.insn	2, 0xaa00
 430:	0002                	.insn	2, 0x0002
 432:	bb00                	.insn	2, 0xbb00
 434:	0002                	.insn	2, 0x0002
 436:	c500                	.insn	2, 0xc500
 438:	0002                	.insn	2, 0x0002
 43a:	cf00                	.insn	2, 0xcf00
 43c:	0002                	.insn	2, 0x0002
 43e:	d900                	.insn	2, 0xd900
 440:	0002                	.insn	2, 0x0002
 442:	e300                	.insn	2, 0xe300
 444:	0002                	.insn	2, 0x0002
 446:	f500                	.insn	2, 0xf500
 448:	0002                	.insn	2, 0x0002
 44a:	1400                	.insn	2, 0x1400
 44c:	26000003          	lb	zero,608(zero) # 260 <start-0x3ffda0>
 450:	37000003          	lb	zero,880(zero) # 370 <start-0x3ffc90>
 454:	4f000003          	lb	zero,1264(zero) # 4f0 <start-0x3ffb10>
 458:	69000003          	lb	zero,1680(zero) # 690 <start-0x3ff970>
 45c:	81000003          	lb	zero,-2032(zero) # fffff810 <USER_MAX+0xffaff810>
 460:	b2000003          	lb	zero,-1248(zero) # fffffb20 <USER_MAX+0xffaffb20>
 464:	d3000003          	lb	zero,-720(zero) # fffffd30 <USER_MAX+0xffaffd30>
 468:	dd000003          	lb	zero,-560(zero) # fffffdd0 <USER_MAX+0xffaffdd0>
 46c:	f5000003          	lb	zero,-176(zero) # ffffff50 <USER_MAX+0xffafff50>
 470:	0d000003          	lb	zero,208(zero) # d0 <start-0x3fff30>
 474:	0004                	.insn	2, 0x0004
 476:	2f00                	.insn	2, 0x2f00
 478:	0004                	.insn	2, 0x0004
 47a:	3900                	.insn	2, 0x3900
 47c:	0004                	.insn	2, 0x0004
 47e:	4300                	.insn	2, 0x4300
 480:	0004                	.insn	2, 0x0004
 482:	4d00                	.insn	2, 0x4d00
 484:	0004                	.insn	2, 0x0004
 486:	0300                	.insn	2, 0x0300
 488:	140e                	.insn	2, 0x140e
 48a:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 48e:	0100                	.insn	2, 0x0100
 490:	040e                	.insn	2, 0x040e
 492:	1c18                	.insn	2, 0x1c18
 494:	5a01                	.insn	2, 0x5a01
 496:	1c04                	.insn	2, 0x1c04
 498:	0594                	.insn	2, 0x0594
 49a:	5f01                	.insn	2, 0x5f01
 49c:	0100                	.insn	2, 0x0100
 49e:	040e                	.insn	2, 0x040e
 4a0:	bc60                	.insn	2, 0xbc60
 4a2:	0101                	.insn	2, 0x0101
 4a4:	0e01005b          	.insn	4, 0x0e01005b
 4a8:	6004                	.insn	2, 0x6004
 4aa:	0274                	.insn	2, 0x0274
 4ac:	9f30                	.insn	2, 0x9f30
 4ae:	0100                	.insn	2, 0x0100
 4b0:	040e                	.insn	2, 0x040e
 4b2:	01c8                	.insn	2, 0x01c8
 4b4:	029c                	.insn	2, 0x029c
 4b6:	5701                	.insn	2, 0x5701
 4b8:	0100                	.insn	2, 0x0100
 4ba:	040e                	.insn	2, 0x040e
 4bc:	01d0                	.insn	2, 0x01d0
 4be:	029c                	.insn	2, 0x029c
 4c0:	5501                	.insn	2, 0x5501
 4c2:	0100                	.insn	2, 0x0100
 4c4:	040e                	.insn	2, 0x040e
 4c6:	01d8                	.insn	2, 0x01d8
 4c8:	029c                	.insn	2, 0x029c
 4ca:	6101                	.insn	2, 0x6101
 4cc:	0100                	.insn	2, 0x0100
 4ce:	040e                	.insn	2, 0x040e
 4d0:	02a8                	.insn	2, 0x02a8
 4d2:	02e8                	.insn	2, 0x02e8
 4d4:	5601                	.insn	2, 0x5601
 4d6:	0100                	.insn	2, 0x0100
 4d8:	040e                	.insn	2, 0x040e
 4da:	02a8                	.insn	2, 0x02a8
 4dc:	02ac                	.insn	2, 0x02ac
 4de:	3002                	.insn	2, 0x3002
 4e0:	009f 0e01 ac04      	.insn	6, 0xac040e01009f
 4e6:	0103ec03          	.insn	4, 0x0103ec03
 4ea:	0e01005b          	.insn	4, 0x0e01005b
 4ee:	ac04                	.insn	2, 0xac04
 4f0:	0203b003          	.insn	4, 0x0203b003
 4f4:	9f30                	.insn	2, 0x9f30
 4f6:	0100                	.insn	2, 0x0100
 4f8:	040e                	.insn	2, 0x040e
 4fa:	04b0                	.insn	2, 0x04b0
 4fc:	04f0                	.insn	2, 0x04f0
 4fe:	5b01                	.insn	2, 0x5b01
 500:	0100                	.insn	2, 0x0100
 502:	040e                	.insn	2, 0x040e
 504:	04b0                	.insn	2, 0x04b0
 506:	04b4                	.insn	2, 0x04b4
 508:	3002                	.insn	2, 0x3002
 50a:	009f 0e01 9404      	.insn	6, 0x94040e01009f
 510:	ac05                	.insn	2, 0xac05
 512:	0105                	.insn	2, 0x0105
 514:	045a                	.insn	2, 0x045a
 516:	05ac                	.insn	2, 0x05ac
 518:	0acc                	.insn	2, 0x0acc
 51a:	5501                	.insn	2, 0x5501
 51c:	0100                	.insn	2, 0x0100
 51e:	040e                	.insn	2, 0x040e
 520:	06d8                	.insn	2, 0x06d8
 522:	06f4                	.insn	2, 0x06f4
 524:	5901                	.insn	2, 0x5901
 526:	b804                	.insn	2, 0xb804
 528:	c809                	.insn	2, 0xc809
 52a:	0109                	.insn	2, 0x0109
 52c:	0059                	.insn	2, 0x0059
 52e:	0e01                	.insn	2, 0x0e01
 530:	dc04                	.insn	2, 0xdc04
 532:	f406                	.insn	2, 0xf406
 534:	0106                	.insn	2, 0x0106
 536:	0459                	.insn	2, 0x0459
 538:	09c8                	.insn	2, 0x09c8
 53a:	09d4                	.insn	2, 0x09d4
 53c:	5901                	.insn	2, 0x5901
 53e:	d404                	.insn	2, 0xd404
 540:	e009                	.insn	2, 0xe009
 542:	0109                	.insn	2, 0x0109
 544:	045d                	.insn	2, 0x045d
 546:	09e0                	.insn	2, 0x09e0
 548:	0a80                	.insn	2, 0x0a80
 54a:	5901                	.insn	2, 0x5901
 54c:	0100                	.insn	2, 0x0100
 54e:	040e                	.insn	2, 0x040e
 550:	06dc                	.insn	2, 0x06dc
 552:	06f4                	.insn	2, 0x06f4
 554:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 558:	c804                	.insn	2, 0xc804
 55a:	cc09                	.insn	2, 0xcc09
 55c:	0309                	.insn	2, 0x0309
 55e:	0011                	.insn	2, 0x0011
 560:	049f 09d4 09dc      	.insn	6, 0x09dc09d4049f
 566:	5801                	.insn	2, 0x5801
 568:	dc04                	.insn	2, 0xdc04
 56a:	8009                	.insn	2, 0x8009
 56c:	010a                	.insn	2, 0x010a
 56e:	005a                	.insn	2, 0x005a
 570:	0e01                	.insn	2, 0x0e01
 572:	8c04                	.insn	2, 0x8c04
 574:	0108c407          	.insn	4, 0x0108c407
 578:	0058                	.insn	2, 0x0058
 57a:	0e01                	.insn	2, 0x0e01
 57c:	8c04                	.insn	2, 0x8c04
 57e:	0307b007          	.insn	4, 0x0307b007
 582:	0711                	.insn	2, 0x0711
 584:	049f 07b0 07cc      	.insn	6, 0x07cc07b0049f
 58a:	9f061103          	lh	sp,-1552(a2)
 58e:	cc04                	.insn	2, 0xcc04
 590:	0307e807          	.insn	4, 0x0307e807
 594:	0511                	.insn	2, 0x0511
 596:	049f 07e8 0884      	.insn	6, 0x088407e8049f
 59c:	9f041103          	lh	sp,-1552(s0)
 5a0:	8404                	.insn	2, 0x8404
 5a2:	a008                	.insn	2, 0xa008
 5a4:	0308                	.insn	2, 0x0308
 5a6:	0311                	.insn	2, 0x0311
 5a8:	049f 08a0 08bc      	.insn	6, 0x08bc08a0049f
 5ae:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 5b2:	bc04                	.insn	2, 0xbc04
 5b4:	d408                	.insn	2, 0xd408
 5b6:	0308                	.insn	2, 0x0308
 5b8:	0111                	.insn	2, 0x0111
 5ba:	049f 08d4 08e4      	.insn	6, 0x08e408d4049f
 5c0:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 5c4:	e404                	.insn	2, 0xe404
 5c6:	ec08                	.insn	2, 0xec08
 5c8:	0308                	.insn	2, 0x0308
 5ca:	7f11                	.insn	2, 0x7f11
 5cc:	009f 0e01 9004      	.insn	6, 0x90040e01009f
 5d2:	01079407          	.insn	4, 0x01079407
 5d6:	045a                	.insn	2, 0x045a
 5d8:	07a0                	.insn	2, 0x07a0
 5da:	07b0                	.insn	2, 0x07b0
 5dc:	5a01                	.insn	2, 0x5a01
 5de:	bc04                	.insn	2, 0xbc04
 5e0:	0107cc07          	.insn	4, 0x0107cc07
 5e4:	045a                	.insn	2, 0x045a
 5e6:	07d8                	.insn	2, 0x07d8
 5e8:	07e8                	.insn	2, 0x07e8
 5ea:	5a01                	.insn	2, 0x5a01
 5ec:	f404                	.insn	2, 0xf404
 5ee:	01088407          	.insn	4, 0x01088407
 5f2:	045a                	.insn	2, 0x045a
 5f4:	0890                	.insn	2, 0x0890
 5f6:	08a0                	.insn	2, 0x08a0
 5f8:	5a01                	.insn	2, 0x5a01
 5fa:	ac04                	.insn	2, 0xac04
 5fc:	bc08                	.insn	2, 0xbc08
 5fe:	0108                	.insn	2, 0x0108
 600:	045a                	.insn	2, 0x045a
 602:	08c4                	.insn	2, 0x08c4
 604:	08c8                	.insn	2, 0x08c8
 606:	5801                	.insn	2, 0x5801
 608:	0100                	.insn	2, 0x0100
 60a:	040e                	.insn	2, 0x040e
 60c:	0990                	.insn	2, 0x0990
 60e:	099c                	.insn	2, 0x099c
 610:	5901                	.insn	2, 0x5901
 612:	9c04                	.insn	2, 0x9c04
 614:	a809                	.insn	2, 0xa809
 616:	0309                	.insn	2, 0x0309
 618:	7f79                	.insn	2, 0x7f79
 61a:	049f 09a8 09b0      	.insn	6, 0x09b009a8049f
 620:	5901                	.insn	2, 0x5901
 622:	0100                	.insn	2, 0x0100
 624:	040e                	.insn	2, 0x040e
 626:	0acc                	.insn	2, 0x0acc
 628:	0ad0                	.insn	2, 0x0ad0
 62a:	5a01                	.insn	2, 0x5a01
 62c:	d004                	.insn	2, 0xd004
 62e:	e00a                	.insn	2, 0xe00a
 630:	010a                	.insn	2, 0x010a
 632:	0e01005b          	.insn	4, 0x0e01005b
 636:	e004                	.insn	2, 0xe004
 638:	e40a                	.insn	2, 0xe40a
 63a:	010a                	.insn	2, 0x010a
 63c:	045a                	.insn	2, 0x045a
 63e:	0ae4                	.insn	2, 0x0ae4
 640:	0af4                	.insn	2, 0x0af4
 642:	5b01                	.insn	2, 0x5b01
 644:	0100                	.insn	2, 0x0100
 646:	040e                	.insn	2, 0x040e
 648:	0af4                	.insn	2, 0x0af4
 64a:	0afc                	.insn	2, 0x0afc
 64c:	5a01                	.insn	2, 0x5a01
 64e:	0100                	.insn	2, 0x0100
 650:	040e                	.insn	2, 0x040e
 652:	0b80                	.insn	2, 0x0b80
 654:	0b94                	.insn	2, 0x0b94
 656:	5a01                	.insn	2, 0x5a01
 658:	9404                	.insn	2, 0x9404
 65a:	010be40b          	.insn	4, 0x010be40b
 65e:	0458                	.insn	2, 0x0458
 660:	0bf0                	.insn	2, 0x0bf0
 662:	0cac                	.insn	2, 0x0cac
 664:	5801                	.insn	2, 0x5801
 666:	0100                	.insn	2, 0x0100
 668:	040e                	.insn	2, 0x040e
 66a:	0c84                	.insn	2, 0x0c84
 66c:	0cac                	.insn	2, 0x0cac
 66e:	5901                	.insn	2, 0x5901
 670:	0100                	.insn	2, 0x0100
 672:	040e                	.insn	2, 0x040e
 674:	0c98                	.insn	2, 0x0c98
 676:	0ca8                	.insn	2, 0x0ca8
 678:	5801                	.insn	2, 0x5801
 67a:	a804                	.insn	2, 0xa804
 67c:	ac0c                	.insn	2, 0xac0c
 67e:	010c                	.insn	2, 0x010c
 680:	005a                	.insn	2, 0x005a
 682:	0e01                	.insn	2, 0x0e01
 684:	ac04                	.insn	2, 0xac04
 686:	b40c                	.insn	2, 0xb40c
 688:	010c                	.insn	2, 0x010c
 68a:	005a                	.insn	2, 0x005a
 68c:	0e01                	.insn	2, 0x0e01
 68e:	b804                	.insn	2, 0xb804
 690:	c00c                	.insn	2, 0xc00c
 692:	010c                	.insn	2, 0x010c
 694:	005a                	.insn	2, 0x005a
 696:	0e01                	.insn	2, 0x0e01
 698:	c404                	.insn	2, 0xc404
 69a:	cc0c                	.insn	2, 0xcc0c
 69c:	010c                	.insn	2, 0x010c
 69e:	005a                	.insn	2, 0x005a
 6a0:	0e01                	.insn	2, 0x0e01
 6a2:	d004                	.insn	2, 0xd004
 6a4:	d80c                	.insn	2, 0xd80c
 6a6:	010c                	.insn	2, 0x010c
 6a8:	005a                	.insn	2, 0x005a
 6aa:	0e01                	.insn	2, 0x0e01
 6ac:	f404                	.insn	2, 0xf404
 6ae:	840c                	.insn	2, 0x840c
 6b0:	020d                	.insn	2, 0x020d
 6b2:	9f30                	.insn	2, 0x9f30
 6b4:	8404                	.insn	2, 0x8404
 6b6:	880d                	.insn	2, 0x880d
 6b8:	010d                	.insn	2, 0x010d
 6ba:	005a                	.insn	2, 0x005a
 6bc:	0e01                	.insn	2, 0x0e01
 6be:	8404                	.insn	2, 0x8404
 6c0:	8c0d                	.insn	2, 0x8c0d
 6c2:	010d                	.insn	2, 0x010d
 6c4:	045a                	.insn	2, 0x045a
 6c6:	0d8c                	.insn	2, 0x0d8c
 6c8:	0db0                	.insn	2, 0x0db0
 6ca:	5b01                	.insn	2, 0x5b01
 6cc:	b004                	.insn	2, 0xb004
 6ce:	b40d                	.insn	2, 0xb40d
 6d0:	010d                	.insn	2, 0x010d
 6d2:	045a                	.insn	2, 0x045a
 6d4:	0dc8                	.insn	2, 0x0dc8
 6d6:	0de0                	.insn	2, 0x0de0
 6d8:	5b01                	.insn	2, 0x5b01
 6da:	0100                	.insn	2, 0x0100
 6dc:	040e                	.insn	2, 0x040e
 6de:	0de0                	.insn	2, 0x0de0
 6e0:	0dec                	.insn	2, 0x0dec
 6e2:	3002                	.insn	2, 0x3002
 6e4:	049f 0dec 0df0      	.insn	6, 0x0df00dec049f
 6ea:	5a01                	.insn	2, 0x5a01
 6ec:	0100                	.insn	2, 0x0100
 6ee:	040e                	.insn	2, 0x040e
 6f0:	0dfc                	.insn	2, 0x0dfc
 6f2:	0e8c                	.insn	2, 0x0e8c
 6f4:	5b01                	.insn	2, 0x5b01
 6f6:	9004                	.insn	2, 0x9004
 6f8:	a00e                	.insn	2, 0xa00e
 6fa:	010e                	.insn	2, 0x010e
 6fc:	0e01005b          	.insn	4, 0x0e01005b
 700:	fc04                	.insn	2, 0xfc04
 702:	900d                	.insn	2, 0x900d
 704:	010e                	.insn	2, 0x010e
 706:	045a                	.insn	2, 0x045a
 708:	0e90                	.insn	2, 0x0e90
 70a:	0e9c                	.insn	2, 0x0e9c
 70c:	5e01                	.insn	2, 0x5e01
 70e:	9c04                	.insn	2, 0x9c04
 710:	a80e                	.insn	2, 0xa80e
 712:	010e                	.insn	2, 0x010e
 714:	005d                	.insn	2, 0x005d
 716:	0e01                	.insn	2, 0x0e01
 718:	b004                	.insn	2, 0xb004
 71a:	bc0e                	.insn	2, 0xbc0e
 71c:	010e                	.insn	2, 0x010e
 71e:	045a                	.insn	2, 0x045a
 720:	0ebc                	.insn	2, 0x0ebc
 722:	0ec4                	.insn	2, 0x0ec4
 724:	9f7f7a03          	.insn	4, 0x9f7f7a03
 728:	c404                	.insn	2, 0xc404
 72a:	d00e                	.insn	2, 0xd00e
 72c:	010e                	.insn	2, 0x010e
 72e:	005a                	.insn	2, 0x005a
 730:	0e01                	.insn	2, 0x0e01
 732:	e004                	.insn	2, 0xe004
 734:	e40e                	.insn	2, 0xe40e
 736:	010e                	.insn	2, 0x010e
 738:	045a                	.insn	2, 0x045a
 73a:	0ee4                	.insn	2, 0x0ee4
 73c:	0fb4                	.insn	2, 0x0fb4
 73e:	5b01                	.insn	2, 0x5b01
 740:	c004                	.insn	2, 0xc004
 742:	0110940f          	.insn	4, 0x0110940f
 746:	0e01005b          	.insn	4, 0x0e01005b
 74a:	e404                	.insn	2, 0xe404
 74c:	800e                	.insn	2, 0x800e
 74e:	9f3a020f          	.insn	4, 0x9f3a020f
 752:	8004                	.insn	2, 0x8004
 754:	020f8c0f          	.insn	4, 0x020f8c0f
 758:	9f40                	.insn	2, 0x9f40
 75a:	8c04                	.insn	2, 0x8c04
 75c:	010f980f          	.insn	4, 0x010f980f
 760:	045c                	.insn	2, 0x045c
 762:	0f98                	.insn	2, 0x0f98
 764:	0f9c                	.insn	2, 0x0f9c
 766:	3a02                	.insn	2, 0x3a02
 768:	049f 0f9c 0fa8      	.insn	6, 0x0fa80f9c049f
 76e:	5c01                	.insn	2, 0x5c01
 770:	a804                	.insn	2, 0xa804
 772:	020fac0f          	.insn	4, 0x020fac0f
 776:	9f3a                	.insn	2, 0x9f3a
 778:	0100                	.insn	2, 0x0100
 77a:	040e                	.insn	2, 0x040e
 77c:	0f8c                	.insn	2, 0x0f8c
 77e:	0f98                	.insn	2, 0x0f98
 780:	3002                	.insn	2, 0x3002
 782:	049f 0f9c 0fa8      	.insn	6, 0x0fa80f9c049f
 788:	3002                	.insn	2, 0x3002
 78a:	049f 0fc0 108c      	.insn	6, 0x108c0fc0049f
 790:	5a01                	.insn	2, 0x5a01
 792:	9004                	.insn	2, 0x9004
 794:	9c10                	.insn	2, 0x9c10
 796:	0110                	.insn	2, 0x0110
 798:	005a                	.insn	2, 0x005a
 79a:	0e01                	.insn	2, 0x0e01
 79c:	c004                	.insn	2, 0xc004
 79e:	0110840f          	.insn	4, 0x0110840f
 7a2:	005d                	.insn	2, 0x005d
 7a4:	0e01                	.insn	2, 0x0e01
 7a6:	d004                	.insn	2, 0xd004
 7a8:	010fd80f          	.insn	4, 0x010fd80f
 7ac:	0461                	.insn	2, 0x0461
 7ae:	0fe8                	.insn	2, 0x0fe8
 7b0:	0ff0                	.insn	2, 0x0ff0
 7b2:	6101                	.insn	2, 0x6101
 7b4:	8004                	.insn	2, 0x8004
 7b6:	9810                	.insn	2, 0x9810
 7b8:	0110                	.insn	2, 0x0110
 7ba:	0061                	.insn	2, 0x0061
 7bc:	0e01                	.insn	2, 0x0e01
 7be:	9c04                	.insn	2, 0x9c04
 7c0:	a410                	.insn	2, 0xa410
 7c2:	0110                	.insn	2, 0x0110
 7c4:	045a                	.insn	2, 0x045a
 7c6:	10ac                	.insn	2, 0x10ac
 7c8:	10b0                	.insn	2, 0x10b0
 7ca:	5a01                	.insn	2, 0x5a01
 7cc:	b004                	.insn	2, 0xb004
 7ce:	d810                	.insn	2, 0xd810
 7d0:	0110                	.insn	2, 0x0110
 7d2:	0e01005b          	.insn	4, 0x0e01005b
 7d6:	b004                	.insn	2, 0xb004
 7d8:	c010                	.insn	2, 0xc010
 7da:	0210                	.insn	2, 0x0210
 7dc:	9f32                	.insn	2, 0x9f32
 7de:	c004                	.insn	2, 0xc004
 7e0:	c410                	.insn	2, 0xc410
 7e2:	0110                	.insn	2, 0x0110
 7e4:	045c                	.insn	2, 0x045c
 7e6:	10c4                	.insn	2, 0x10c4
 7e8:	10cc                	.insn	2, 0x10cc
 7ea:	9f017c03          	.insn	4, 0x9f017c03
 7ee:	cc04                	.insn	2, 0xcc04
 7f0:	d410                	.insn	2, 0xd410
 7f2:	0110                	.insn	2, 0x0110
 7f4:	005c                	.insn	2, 0x005c
 7f6:	0e01                	.insn	2, 0x0e01
 7f8:	e404                	.insn	2, 0xe404
 7fa:	ec10                	.insn	2, 0xec10
 7fc:	0110                	.insn	2, 0x0110
 7fe:	0e01005b          	.insn	4, 0x0e01005b
 802:	f804                	.insn	2, 0xf804
 804:	8010                	.insn	2, 0x8010
 806:	0111                	.insn	2, 0x0111
 808:	0e01005b          	.insn	4, 0x0e01005b
 80c:	8004                	.insn	2, 0x8004
 80e:	8811                	.insn	2, 0x8811
 810:	0111                	.insn	2, 0x0111
 812:	005a                	.insn	2, 0x005a
 814:	0e01                	.insn	2, 0x0e01
 816:	9404                	.insn	2, 0x9404
 818:	9811                	.insn	2, 0x9811
 81a:	0111                	.insn	2, 0x0111
 81c:	005a                	.insn	2, 0x005a
 81e:	00000603          	lb	a2,0(zero) # 0 <start-0x400000>
 822:	0005                	.insn	2, 0x0005
 824:	0004                	.insn	2, 0x0004
 826:	0024                	.insn	2, 0x0024
 828:	0000                	.insn	2, 0x0000
 82a:	0090                	.insn	2, 0x0090
 82c:	0000                	.insn	2, 0x0000
 82e:	009c                	.insn	2, 0x009c
 830:	0000                	.insn	2, 0x0000
 832:	00a2                	.insn	2, 0x00a2
 834:	0000                	.insn	2, 0x0000
 836:	00a9                	.insn	2, 0x00a9
 838:	0000                	.insn	2, 0x0000
 83a:	00b2                	.insn	2, 0x00b2
 83c:	0000                	.insn	2, 0x0000
 83e:	00ba                	.insn	2, 0x00ba
 840:	0000                	.insn	2, 0x0000
 842:	00c2                	.insn	2, 0x00c2
 844:	0000                	.insn	2, 0x0000
 846:	00ca                	.insn	2, 0x00ca
 848:	0000                	.insn	2, 0x0000
 84a:	00d2                	.insn	2, 0x00d2
 84c:	0000                	.insn	2, 0x0000
 84e:	00e8                	.insn	2, 0x00e8
 850:	0000                	.insn	2, 0x0000
 852:	00fe                	.insn	2, 0x00fe
 854:	0000                	.insn	2, 0x0000
 856:	0114                	.insn	2, 0x0114
 858:	0000                	.insn	2, 0x0000
 85a:	011c                	.insn	2, 0x011c
 85c:	0000                	.insn	2, 0x0000
 85e:	0124                	.insn	2, 0x0124
 860:	0000                	.insn	2, 0x0000
 862:	0149                	.insn	2, 0x0149
 864:	0000                	.insn	2, 0x0000
 866:	0196                	.insn	2, 0x0196
 868:	0000                	.insn	2, 0x0000
 86a:	000001c7          	.insn	4, 0x01c7
 86e:	0261                	.insn	2, 0x0261
 870:	0000                	.insn	2, 0x0000
 872:	0269                	.insn	2, 0x0269
 874:	0000                	.insn	2, 0x0000
 876:	0271                	.insn	2, 0x0271
 878:	0000                	.insn	2, 0x0000
 87a:	0279                	.insn	2, 0x0279
 87c:	0000                	.insn	2, 0x0000
 87e:	0291                	.insn	2, 0x0291
 880:	0000                	.insn	2, 0x0000
 882:	02a0                	.insn	2, 0x02a0
 884:	0000                	.insn	2, 0x0000
 886:	02d1                	.insn	2, 0x02d1
 888:	0000                	.insn	2, 0x0000
 88a:	02d9                	.insn	2, 0x02d9
 88c:	0000                	.insn	2, 0x0000
 88e:	00000373          	.insn	4, 0x0373
 892:	03aa                	.insn	2, 0x03aa
 894:	0000                	.insn	2, 0x0000
 896:	03b9                	.insn	2, 0x03b9
 898:	0000                	.insn	2, 0x0000
 89a:	03c1                	.insn	2, 0x03c1
 89c:	0000                	.insn	2, 0x0000
 89e:	03c9                	.insn	2, 0x03c9
 8a0:	0000                	.insn	2, 0x0000
 8a2:	03d1                	.insn	2, 0x03d1
 8a4:	0000                	.insn	2, 0x0000
 8a6:	043e                	.insn	2, 0x043e
 8a8:	0000                	.insn	2, 0x0000
 8aa:	0478                	.insn	2, 0x0478
 8ac:	0000                	.insn	2, 0x0000
 8ae:	0509                	.insn	2, 0x0509
 8b0:	0000                	.insn	2, 0x0000
 8b2:	0518                	.insn	2, 0x0518
 8b4:	0000                	.insn	2, 0x0000
 8b6:	058e                	.insn	2, 0x058e
 8b8:	0000                	.insn	2, 0x0000
 8ba:	0004                	.insn	2, 0x0004
 8bc:	0114                	.insn	2, 0x0114
 8be:	045a                	.insn	2, 0x045a
 8c0:	ac14                	.insn	2, 0xac14
 8c2:	0101                	.insn	2, 0x0101
 8c4:	0058                	.insn	2, 0x0058
 8c6:	5c04                	.insn	2, 0x5c04
 8c8:	0170                	.insn	2, 0x0170
 8ca:	005a                	.insn	2, 0x005a
 8cc:	7804                	.insn	2, 0x7804
 8ce:	0184                	.insn	2, 0x0184
 8d0:	5a01                	.insn	2, 0x5a01
 8d2:	0400                	.insn	2, 0x0400
 8d4:	0194                	.insn	2, 0x0194
 8d6:	01b4                	.insn	2, 0x01b4
 8d8:	3002                	.insn	2, 0x3002
 8da:	009f 8804 9402      	.insn	6, 0x94028804009f
 8e0:	0102                	.insn	2, 0x0102
 8e2:	e004005b          	.insn	4, 0xe004005b
 8e6:	f402                	.insn	2, 0xf402
 8e8:	0102                	.insn	2, 0x0102
 8ea:	e404005b          	.insn	4, 0xe404005b
 8ee:	f802                	.insn	2, 0xf802
 8f0:	0102                	.insn	2, 0x0102
 8f2:	005c                	.insn	2, 0x005c
 8f4:	e804                	.insn	2, 0xe804
 8f6:	8c02                	.insn	2, 0x8c02
 8f8:	005d0103          	lb	sp,5(s10)
 8fc:	a804                	.insn	2, 0xa804
 8fe:	0103e803          	.insn	4, 0x0103e803
 902:	045a                	.insn	2, 0x045a
 904:	03e8                	.insn	2, 0x03e8
 906:	04c0                	.insn	2, 0x04c0
 908:	6301                	.insn	2, 0x6301
 90a:	e404                	.insn	2, 0xe404
 90c:	c804                	.insn	2, 0xc804
 90e:	0108                	.insn	2, 0x0108
 910:	a8040063          	beqz	s0,fffffb90 <USER_MAX+0xffaffb90>
 914:	0103e403          	.insn	4, 0x0103e403
 918:	03e4045b          	.insn	4, 0x03e4045b
 91c:	04bc                	.insn	2, 0x04bc
 91e:	6201                	.insn	2, 0x6201
 920:	e404                	.insn	2, 0xe404
 922:	c804                	.insn	2, 0xc804
 924:	0108                	.insn	2, 0x0108
 926:	0062                	.insn	2, 0x0062
 928:	a804                	.insn	2, 0xa804
 92a:	0103e003          	.insn	4, 0x0103e003
 92e:	045c                	.insn	2, 0x045c
 930:	03e0                	.insn	2, 0x03e0
 932:	04b8                	.insn	2, 0x04b8
 934:	5901                	.insn	2, 0x5901
 936:	e404                	.insn	2, 0xe404
 938:	c804                	.insn	2, 0xc804
 93a:	0108                	.insn	2, 0x0108
 93c:	0059                	.insn	2, 0x0059
 93e:	8404                	.insn	2, 0x8404
 940:	9004                	.insn	2, 0x9004
 942:	0104                	.insn	2, 0x0104
 944:	005a                	.insn	2, 0x005a
 946:	9804                	.insn	2, 0x9804
 948:	a404                	.insn	2, 0xa404
 94a:	0104                	.insn	2, 0x0104
 94c:	005a                	.insn	2, 0x005a
 94e:	8404                	.insn	2, 0x8404
 950:	9005                	.insn	2, 0x9005
 952:	0305                	.insn	2, 0x0305
 954:	0a11                	.insn	2, 0x0a11
 956:	049f 07bc 07c0      	.insn	6, 0x07c007bc049f
 95c:	9f081103          	lh	sp,-1552(a6)
 960:	c004                	.insn	2, 0xc004
 962:	0307d807          	.insn	4, 0x0307d807
 966:	0911                	.insn	2, 0x0911
 968:	049f 07d8 07e8      	.insn	6, 0x07e807d8049f
 96e:	9f0a1103          	lh	sp,-1552(s4)
 972:	0400                	.insn	2, 0x0400
 974:	0584                	.insn	2, 0x0584
 976:	0588                	.insn	2, 0x0588
 978:	5b01                	.insn	2, 0x5b01
 97a:	8804                	.insn	2, 0x8804
 97c:	9405                	.insn	2, 0x9405
 97e:	0105                	.insn	2, 0x0105
 980:	045a                	.insn	2, 0x045a
 982:	05cc                	.insn	2, 0x05cc
 984:	05d4                	.insn	2, 0x05d4
 986:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 98a:	d404                	.insn	2, 0xd404
 98c:	e005                	.insn	2, 0xe005
 98e:	0105                	.insn	2, 0x0105
 990:	045a                	.insn	2, 0x045a
 992:	05e0                	.insn	2, 0x05e0
 994:	05e8                	.insn	2, 0x05e8
 996:	9f011103          	lh	sp,-1552(sp)
 99a:	e804                	.insn	2, 0xe804
 99c:	b005                	.insn	2, 0xb005
 99e:	045a0107          	.insn	4, 0x045a0107
 9a2:	07b0                	.insn	2, 0x07b0
 9a4:	07bc                	.insn	2, 0x07bc
 9a6:	9f017a03          	.insn	4, 0x9f017a03
 9aa:	c404                	.insn	2, 0xc404
 9ac:	0107cc07          	.insn	4, 0x0107cc07
 9b0:	07d0045b          	.insn	4, 0x07d0045b
 9b4:	07d8                	.insn	2, 0x07d8
 9b6:	5a01                	.insn	2, 0x5a01
 9b8:	d804                	.insn	2, 0xd804
 9ba:	0107e807          	.insn	4, 0x0107e807
 9be:	8404005b          	.insn	4, 0x8404005b
 9c2:	ac05                	.insn	2, 0xac05
 9c4:	0905                	.insn	2, 0x0905
 9c6:	0085                	.insn	2, 0x0085
 9c8:	1011                	.insn	2, 0x1011
 9ca:	111c                	.insn	2, 0x111c
 9cc:	049f1b7f 05b005ac 	.insn	12, 0x1100850c05b005ac049f1b7f
 9d4:	1100850c 
 9d8:	1c10                	.insn	2, 0x1c10
 9da:	7f11                	.insn	2, 0x7f11
 9dc:	2201111b          	.insn	4, 0x2201111b
 9e0:	049f 05b8 08c8      	.insn	6, 0x08c805b8049f
 9e6:	8509                	.insn	2, 0x8509
 9e8:	1100                	.insn	2, 0x1100
 9ea:	1c10                	.insn	2, 0x1c10
 9ec:	7f11                	.insn	2, 0x7f11
 9ee:	04009f1b          	.insn	4, 0x04009f1b
 9f2:	05cc                	.insn	2, 0x05cc
 9f4:	05d4                	.insn	2, 0x05d4
 9f6:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 9fa:	d404                	.insn	2, 0xd404
 9fc:	e005                	.insn	2, 0xe005
 9fe:	0305                	.insn	2, 0x0305
 a00:	0111                	.insn	2, 0x0111
 a02:	049f 05e0 05e8      	.insn	6, 0x05e805e0049f
 a08:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 a0c:	e804                	.insn	2, 0xe804
 a0e:	fc05                	.insn	2, 0xfc05
 a10:	0305                	.insn	2, 0x0305
 a12:	0111                	.insn	2, 0x0111
 a14:	049f 05fc 0684      	.insn	6, 0x068405fc049f
 a1a:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 a1e:	8404                	.insn	2, 0x8404
 a20:	8c06                	.insn	2, 0x8c06
 a22:	0306                	.insn	2, 0x0306
 a24:	0311                	.insn	2, 0x0311
 a26:	049f 068c 0694      	.insn	6, 0x0694068c049f
 a2c:	9f041103          	lh	sp,-1552(s0)
 a30:	9404                	.insn	2, 0x9404
 a32:	9c06                	.insn	2, 0x9c06
 a34:	0306                	.insn	2, 0x0306
 a36:	0511                	.insn	2, 0x0511
 a38:	049f 069c 06a4      	.insn	6, 0x06a4069c049f
 a3e:	9f061103          	lh	sp,-1552(a2)
 a42:	a404                	.insn	2, 0xa404
 a44:	ac06                	.insn	2, 0xac06
 a46:	0306                	.insn	2, 0x0306
 a48:	0711                	.insn	2, 0x0711
 a4a:	049f 06b8 06c4      	.insn	6, 0x06c406b8049f
 a50:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 a54:	c404                	.insn	2, 0xc404
 a56:	d806                	.insn	2, 0xd806
 a58:	0306                	.insn	2, 0x0306
 a5a:	0311                	.insn	2, 0x0311
 a5c:	049f 06d8 06ec      	.insn	6, 0x06ec06d8049f
 a62:	9f041103          	lh	sp,-1552(s0)
 a66:	ec04                	.insn	2, 0xec04
 a68:	8006                	.insn	2, 0x8006
 a6a:	05110307          	.insn	4, 0x05110307
 a6e:	049f 0780 0794      	.insn	6, 0x07940780049f
 a74:	9f061103          	lh	sp,-1552(a2)
 a78:	9404                	.insn	2, 0x9404
 a7a:	0307a807          	.insn	4, 0x0307a807
 a7e:	0711                	.insn	2, 0x0711
 a80:	049f 07a8 07b0      	.insn	6, 0x07b007a8049f
 a86:	9f081103          	lh	sp,-1552(a6)
 a8a:	0400                	.insn	2, 0x0400
 a8c:	08c8                	.insn	2, 0x08c8
 a8e:	08dc                	.insn	2, 0x08dc
 a90:	5a01                	.insn	2, 0x5a01
 a92:	0400                	.insn	2, 0x0400
 a94:	09ac                	.insn	2, 0x09ac
 a96:	09b8                	.insn	2, 0x09b8
 a98:	5a01                	.insn	2, 0x5a01
 a9a:	0400                	.insn	2, 0x0400
 a9c:	09c0                	.insn	2, 0x09c0
 a9e:	09cc                	.insn	2, 0x09cc
 aa0:	5a01                	.insn	2, 0x5a01
 aa2:	0400                	.insn	2, 0x0400
 aa4:	0aac                	.insn	2, 0x0aac
 aa6:	0ac0                	.insn	2, 0x0ac0
 aa8:	3002                	.insn	2, 0x3002
 aaa:	049f 0ac0 0af4      	.insn	6, 0x0af40ac0049f
 ab0:	5c01                	.insn	2, 0x5c01
 ab2:	c004                	.insn	2, 0xc004
 ab4:	cc0d                	.insn	2, 0xcc0d
 ab6:	020d                	.insn	2, 0x020d
 ab8:	9f30                	.insn	2, 0x9f30
 aba:	0400                	.insn	2, 0x0400
 abc:	0aac                	.insn	2, 0x0aac
 abe:	0af4                	.insn	2, 0x0af4
 ac0:	5b01                	.insn	2, 0x5b01
 ac2:	c004                	.insn	2, 0xc004
 ac4:	cc0d                	.insn	2, 0xcc0d
 ac6:	010d                	.insn	2, 0x010d
 ac8:	ac04005b          	.insn	4, 0xac04005b
 acc:	f40a                	.insn	2, 0xf40a
 ace:	090a                	.insn	2, 0x090a
 ad0:	0084                	.insn	2, 0x0084
 ad2:	1011                	.insn	2, 0x1011
 ad4:	111c                	.insn	2, 0x111c
 ad6:	049f1b7f 0af80af4 	.insn	12, 0x1100840c0af80af4049f1b7f
 ade:	1100840c 
 ae2:	1c10                	.insn	2, 0x1c10
 ae4:	7f11                	.insn	2, 0x7f11
 ae6:	2201111b          	.insn	4, 0x2201111b
 aea:	049f 0b80 0df0      	.insn	6, 0x0df00b80049f
 af0:	8409                	.insn	2, 0x8409
 af2:	1100                	.insn	2, 0x1100
 af4:	1c10                	.insn	2, 0x1c10
 af6:	7f11                	.insn	2, 0x7f11
 af8:	04009f1b          	.insn	4, 0x04009f1b
 afc:	0ae8                	.insn	2, 0x0ae8
 afe:	0af4                	.insn	2, 0x0af4
 b00:	5d01                	.insn	2, 0x5d01
 b02:	0400                	.insn	2, 0x0400
 b04:	0b94                	.insn	2, 0x0b94
 b06:	0b98                	.insn	2, 0x0b98
 b08:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 b0c:	9804                	.insn	2, 0x9804
 b0e:	030ba00b          	.insn	4, 0x030ba00b
 b12:	0111                	.insn	2, 0x0111
 b14:	049f 0ba0 0ba8      	.insn	6, 0x0ba80ba0049f
 b1a:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 b1e:	a804                	.insn	2, 0xa804
 b20:	030bb00b          	.insn	4, 0x030bb00b
 b24:	0311                	.insn	2, 0x0311
 b26:	049f 0bb0 0bb8      	.insn	6, 0x0bb80bb0049f
 b2c:	9f041103          	lh	sp,-1552(s0)
 b30:	b804                	.insn	2, 0xb804
 b32:	030bc00b          	.insn	4, 0x030bc00b
 b36:	0511                	.insn	2, 0x0511
 b38:	049f 0bc0 0bc8      	.insn	6, 0x0bc80bc0049f
 b3e:	9f061103          	lh	sp,-1552(a2)
 b42:	c804                	.insn	2, 0xc804
 b44:	030bd00b          	.insn	4, 0x030bd00b
 b48:	0711                	.insn	2, 0x0711
 b4a:	049f 0bdc 0be4      	.insn	6, 0x0be40bdc049f
 b50:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 b54:	e404                	.insn	2, 0xe404
 b56:	030bf40b          	.insn	4, 0x030bf40b
 b5a:	0111                	.insn	2, 0x0111
 b5c:	049f 0bf4 0c84      	.insn	6, 0x0c840bf4049f
 b62:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 b66:	8404                	.insn	2, 0x8404
 b68:	940c                	.insn	2, 0x940c
 b6a:	030c                	.insn	2, 0x030c
 b6c:	0311                	.insn	2, 0x0311
 b6e:	049f 0c94 0ca4      	.insn	6, 0x0ca40c94049f
 b74:	9f041103          	lh	sp,-1552(s0)
 b78:	a404                	.insn	2, 0xa404
 b7a:	b40c                	.insn	2, 0xb40c
 b7c:	030c                	.insn	2, 0x030c
 b7e:	0511                	.insn	2, 0x0511
 b80:	049f 0cb4 0cc4      	.insn	6, 0x0cc40cb4049f
 b86:	9f061103          	lh	sp,-1552(a2)
 b8a:	c404                	.insn	2, 0xc404
 b8c:	d40c                	.insn	2, 0xd40c
 b8e:	030c                	.insn	2, 0x030c
 b90:	0711                	.insn	2, 0x0711
 b92:	049f 0cd4 0cdc      	.insn	6, 0x0cdc0cd4049f
 b98:	9f081103          	lh	sp,-1552(a6)
 b9c:	0400                	.insn	2, 0x0400
 b9e:	0ce8                	.insn	2, 0x0ce8
 ba0:	0cf0                	.insn	2, 0x0cf0
 ba2:	9f081103          	lh	sp,-1552(a6)
 ba6:	f004                	.insn	2, 0xf004
 ba8:	f80c                	.insn	2, 0xf80c
 baa:	030c                	.insn	2, 0x030c
 bac:	0911                	.insn	2, 0x0911
 bae:	049f 0cf8 0d88      	.insn	6, 0x0d880cf8049f
 bb4:	9f0a1103          	lh	sp,-1552(s4)
 bb8:	cc04                	.insn	2, 0xcc04
 bba:	d40d                	.insn	2, 0xd40d
 bbc:	030d                	.insn	2, 0x030d
 bbe:	0811                	.insn	2, 0x0811
 bc0:	049f 0dd4 0de4      	.insn	6, 0x0de40dd4049f
 bc6:	9f091103          	lh	sp,-1552(s2)
 bca:	e404                	.insn	2, 0xe404
 bcc:	f00d                	.insn	2, 0xf00d
 bce:	030d                	.insn	2, 0x030d
 bd0:	0a11                	.insn	2, 0x0a11
 bd2:	009f f004 900d      	.insn	6, 0x900df004009f
 bd8:	010e                	.insn	2, 0x010e
 bda:	045a                	.insn	2, 0x045a
 bdc:	0e90                	.insn	2, 0x0e90
 bde:	1588                	.insn	2, 0x1588
 be0:	5801                	.insn	2, 0x5801
 be2:	0400                	.insn	2, 0x0400
 be4:	0eac                	.insn	2, 0x0eac
 be6:	0eb8                	.insn	2, 0x0eb8
 be8:	5a01                	.insn	2, 0x5a01
 bea:	0400                	.insn	2, 0x0400
 bec:	0ec0                	.insn	2, 0x0ec0
 bee:	14fc                	.insn	2, 0x14fc
 bf0:	5901                	.insn	2, 0x5901
 bf2:	0400                	.insn	2, 0x0400
 bf4:	0edc                	.insn	2, 0x0edc
 bf6:	0fe0                	.insn	2, 0x0fe0
 bf8:	5801                	.insn	2, 0x5801
 bfa:	0400                	.insn	2, 0x0400
 bfc:	0edc                	.insn	2, 0x0edc
 bfe:	0ee4                	.insn	2, 0x0ee4
 c00:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 c04:	e404                	.insn	2, 0xe404
 c06:	e80e                	.insn	2, 0xe80e
 c08:	030e                	.insn	2, 0x030e
 c0a:	0111                	.insn	2, 0x0111
 c0c:	049f 0ee8 0eec      	.insn	6, 0x0eec0ee8049f
 c12:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 c16:	ec04                	.insn	2, 0xec04
 c18:	f00e                	.insn	2, 0xf00e
 c1a:	030e                	.insn	2, 0x030e
 c1c:	0311                	.insn	2, 0x0311
 c1e:	049f 0ef0 0ef4      	.insn	6, 0x0ef40ef0049f
 c24:	9f041103          	lh	sp,-1552(s0)
 c28:	f404                	.insn	2, 0xf404
 c2a:	f80e                	.insn	2, 0xf80e
 c2c:	030e                	.insn	2, 0x030e
 c2e:	0511                	.insn	2, 0x0511
 c30:	049f 0ef8 0efc      	.insn	6, 0x0efc0ef8049f
 c36:	9f061103          	lh	sp,-1552(a2)
 c3a:	fc04                	.insn	2, 0xfc04
 c3c:	800e                	.insn	2, 0x800e
 c3e:	0711030f          	.insn	4, 0x0711030f
 c42:	049f 0f80 0f84      	.insn	6, 0x0f840f80049f
 c48:	9f081103          	lh	sp,-1552(a6)
 c4c:	8404                	.insn	2, 0x8404
 c4e:	030f880f          	.insn	4, 0x030f880f
 c52:	0911                	.insn	2, 0x0911
 c54:	049f 0f88 0f8c      	.insn	6, 0x0f8c0f88049f
 c5a:	9f0a1103          	lh	sp,-1552(s4)
 c5e:	8c04                	.insn	2, 0x8c04
 c60:	0310b40f          	.insn	4, 0x0310b40f
 c64:	0b11                	.insn	2, 0x0b11
 c66:	009f 8c04 a00f      	.insn	6, 0xa00f8c04009f
 c6c:	0011030f          	.insn	4, 0x0011030f
 c70:	049f 0fa0 0fbc      	.insn	6, 0x0fbc0fa0049f
 c76:	5b01                	.insn	2, 0x5b01
 c78:	bc04                	.insn	2, 0xbc04
 c7a:	010fcc0f          	.insn	4, 0x010fcc0f
 c7e:	045f 0fcc 0fd4      	.insn	6, 0x0fd40fcc045f
 c84:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 c88:	d404                	.insn	2, 0xd404
 c8a:	010fd80f          	.insn	4, 0x010fd80f
 c8e:	0ffc045b          	.insn	4, 0x0ffc045b
 c92:	1094                	.insn	2, 0x1094
 c94:	9f081103          	lh	sp,-1552(a6)
 c98:	9404                	.insn	2, 0x9404
 c9a:	b010                	.insn	2, 0xb010
 c9c:	0310                	.insn	2, 0x0310
 c9e:	097c                	.insn	2, 0x097c
 ca0:	009f b404 cc10      	.insn	6, 0xcc10b404009f
 ca6:	0310                	.insn	2, 0x0310
 ca8:	0011                	.insn	2, 0x0011
 caa:	049f 10cc 10e0      	.insn	6, 0x10e010cc049f
 cb0:	9f011103          	lh	sp,-1552(sp)
 cb4:	e004                	.insn	2, 0xe004
 cb6:	f410                	.insn	2, 0xf410
 cb8:	0310                	.insn	2, 0x0310
 cba:	0211                	.insn	2, 0x0211
 cbc:	049f 10f4 1188      	.insn	6, 0x118810f4049f
 cc2:	9f031103          	lh	sp,-1552(t1)
 cc6:	8804                	.insn	2, 0x8804
 cc8:	9c11                	.insn	2, 0x9c11
 cca:	0311                	.insn	2, 0x0311
 ccc:	0411                	.insn	2, 0x0411
 cce:	049f 119c 11b0      	.insn	6, 0x11b0119c049f
 cd4:	9f051103          	lh	sp,-1552(a0)
 cd8:	b004                	.insn	2, 0xb004
 cda:	c411                	.insn	2, 0xc411
 cdc:	0311                	.insn	2, 0x0311
 cde:	0611                	.insn	2, 0x0611
 ce0:	049f 11c4 11d8      	.insn	6, 0x11d811c4049f
 ce6:	9f071103          	lh	sp,-1552(a4)
 cea:	d804                	.insn	2, 0xd804
 cec:	ec11                	.insn	2, 0xec11
 cee:	0311                	.insn	2, 0x0311
 cf0:	0811                	.insn	2, 0x0811
 cf2:	049f 11ec 1280      	.insn	6, 0x128011ec049f
 cf8:	9f091103          	lh	sp,-1552(s2)
 cfc:	8004                	.insn	2, 0x8004
 cfe:	9412                	.insn	2, 0x9412
 d00:	0312                	.insn	2, 0x0312
 d02:	0a11                	.insn	2, 0x0a11
 d04:	049f 1294 12a8      	.insn	6, 0x12a81294049f
 d0a:	9f0b1103          	lh	sp,-1552(s6)
 d0e:	a804                	.insn	2, 0xa804
 d10:	bc12                	.insn	2, 0xbc12
 d12:	0312                	.insn	2, 0x0312
 d14:	0c11                	.insn	2, 0x0c11
 d16:	049f 12bc 12d0      	.insn	6, 0x12d012bc049f
 d1c:	9f0d1103          	lh	sp,-1552(s10)
 d20:	d004                	.insn	2, 0xd004
 d22:	e412                	.insn	2, 0xe412
 d24:	0312                	.insn	2, 0x0312
 d26:	0e11                	.insn	2, 0x0e11
 d28:	049f 12e4 12f8      	.insn	6, 0x12f812e4049f
 d2e:	9f0f1103          	lh	sp,-1552(t5)
 d32:	0400                	.insn	2, 0x0400
 d34:	10b4                	.insn	2, 0x10b4
 d36:	10d4                	.insn	2, 0x10d4
 d38:	6201                	.insn	2, 0x6201
 d3a:	d404                	.insn	2, 0xd404
 d3c:	f810                	.insn	2, 0xf810
 d3e:	0112                	.insn	2, 0x0112
 d40:	005a                	.insn	2, 0x005a
 d42:	f804                	.insn	2, 0xf804
 d44:	fc12                	.insn	2, 0xfc12
 d46:	0312                	.insn	2, 0x0312
 d48:	0c11                	.insn	2, 0x0c11
 d4a:	049f 12fc 1380      	.insn	6, 0x138012fc049f
 d50:	9f0d1103          	lh	sp,-1552(s10)
 d54:	8004                	.insn	2, 0x8004
 d56:	03138413          	addi	s0,t2,49
 d5a:	0e11                	.insn	2, 0x0e11
 d5c:	049f 1384 1388      	.insn	6, 0x13881384049f
 d62:	9f0f1103          	lh	sp,-1552(t5)
 d66:	8804                	.insn	2, 0x8804
 d68:	03138c13          	addi	s8,t2,49
 d6c:	1011                	.insn	2, 0x1011
 d6e:	049f 138c 1390      	.insn	6, 0x1390138c049f
 d74:	9f111103          	lh	sp,-1551(sp)
 d78:	9004                	.insn	2, 0x9004
 d7a:	03139413          	slli	s0,t2,0x31
 d7e:	1211                	.insn	2, 0x1211
 d80:	049f 1394 1398      	.insn	6, 0x13981394049f
 d86:	9f131103          	lh	sp,-1551(t1)
 d8a:	9804                	.insn	2, 0x9804
 d8c:	0313a413          	slti	s0,t2,49
 d90:	1611                	.insn	2, 0x1611
 d92:	049f 13a4 13a8      	.insn	6, 0x13a813a4049f
 d98:	9f171103          	lh	sp,-1551(a4)
 d9c:	a804                	.insn	2, 0xa804
 d9e:	0313fc13          	andi	s8,t2,49
 da2:	1811                	.insn	2, 0x1811
 da4:	049f 13fc 1480      	.insn	6, 0x148013fc049f
 daa:	9f191103          	lh	sp,-1551(s2)
 dae:	8004                	.insn	2, 0x8004
 db0:	dc14                	.insn	2, 0xdc14
 db2:	0314                	.insn	2, 0x0314
 db4:	2011                	.insn	2, 0x2011
 db6:	009f cc04 d013      	.insn	6, 0xd013cc04009f
 dbc:	01110313          	addi	t1,sp,17
 dc0:	049f 13d0 13d4      	.insn	6, 0x13d413d0049f
 dc6:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 dca:	d404                	.insn	2, 0xd404
 dcc:	0313d813          	srli	a6,t2,0x31
 dd0:	0311                	.insn	2, 0x0311
 dd2:	049f 13d8 13e8      	.insn	6, 0x13e813d8049f
 dd8:	9f041103          	lh	sp,-1552(s0)
 ddc:	e804                	.insn	2, 0xe804
 dde:	0313ec13          	ori	s8,t2,49
 de2:	0511                	.insn	2, 0x0511
 de4:	049f 13ec 13f0      	.insn	6, 0x13f013ec049f
 dea:	9f061103          	lh	sp,-1552(a2)
 dee:	f004                	.insn	2, 0xf004
 df0:	0313f413          	andi	s0,t2,49
 df4:	0711                	.insn	2, 0x0711
 df6:	049f 13f4 13f8      	.insn	6, 0x13f813f4049f
 dfc:	9f081103          	lh	sp,-1552(a6)
 e00:	f804                	.insn	2, 0xf804
 e02:	03148013          	addi	zero,s1,49
 e06:	0b11                	.insn	2, 0x0b11
 e08:	049f 1480 148c      	.insn	6, 0x148c1480049f
 e0e:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 e12:	8c04                	.insn	2, 0x8c04
 e14:	9014                	.insn	2, 0x9014
 e16:	0314                	.insn	2, 0x0314
 e18:	0911                	.insn	2, 0x0911
 e1a:	049f 1490 14dc      	.insn	6, 0x14dc1490049f
 e20:	9f0a1103          	lh	sp,-1552(s4)
	...

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
 21e:	012e                	.insn	2, 0x012e
 220:	1b11                	.insn	2, 0x1b11
 222:	0612                	.insn	2, 0x0612
 224:	1840                	.insn	2, 0x1840
 226:	197a                	.insn	2, 0x197a
 228:	0b3a2503          	lw	a0,179(s4)
 22c:	19270b3b          	.insn	4, 0x19270b3b
 230:	0000193f 03003403 	.insn	8, 0x030034030000193f
 238:	4925                	.insn	2, 0x4925
 23a:	3b0b3a13          	sltiu	s4,s6,944
 23e:	0018020b          	.insn	4, 0x0018020b
 242:	0400                	.insn	2, 0x0400
 244:	0005                	.insn	2, 0x0005
 246:	2202                	.insn	2, 0x2202
 248:	0b3a2503          	lw	a0,179(s4)
 24c:	13490b3b          	.insn	4, 0x13490b3b
 250:	0000                	.insn	2, 0x0000
 252:	0b05                	.insn	2, 0x0b05
 254:	1101                	.insn	2, 0x1101
 256:	0006121b          	.insn	4, 0x0006121b
 25a:	0600                	.insn	2, 0x0600
 25c:	0034                	.insn	2, 0x0034
 25e:	2202                	.insn	2, 0x2202
 260:	0b3a2503          	lw	a0,179(s4)
 264:	13490b3b          	.insn	4, 0x13490b3b
 268:	0000                	.insn	2, 0x0000
 26a:	55010b07          	.insn	4, 0x55010b07
 26e:	08000023          	sb	zero,128(zero) # 80 <start-0x3fff80>
 272:	0034                	.insn	2, 0x0034
 274:	0b3a2503          	lw	a0,179(s4)
 278:	13490b3b          	.insn	4, 0x13490b3b
 27c:	0000                	.insn	2, 0x0000
 27e:	1d09                	.insn	2, 0x1d09
 280:	3101                	.insn	2, 0x3101
 282:	121b1113          	.insn	4, 0x121b1113
 286:	5806                	.insn	2, 0x5806
 288:	570b590b          	.insn	4, 0x570b590b
 28c:	0a00000b          	.insn	4, 0x0a00000b
 290:	0005                	.insn	2, 0x0005
 292:	0f1c                	.insn	2, 0x0f1c
 294:	1331                	.insn	2, 0x1331
 296:	0000                	.insn	2, 0x0000
 298:	0200050b          	.insn	4, 0x0200050b
 29c:	3122                	.insn	2, 0x3122
 29e:	0c000013          	li	zero,192
 2a2:	0005                	.insn	2, 0x0005
 2a4:	1802                	.insn	2, 0x1802
 2a6:	1331                	.insn	2, 0x1331
 2a8:	0000                	.insn	2, 0x0000
 2aa:	480d                	.insn	2, 0x480d
 2ac:	7f00                	.insn	2, 0x7f00
 2ae:	19018213          	addi	tp,gp,400
 2b2:	0181                	.insn	2, 0x0181
 2b4:	0e00001b          	.insn	4, 0x0e00001b
 2b8:	0101                	.insn	2, 0x0101
 2ba:	1349                	.insn	2, 0x1349
 2bc:	0000                	.insn	2, 0x0000
 2be:	4900210f          	.insn	4, 0x4900210f
 2c2:	00053713          	sltiu	a4,a0,0
 2c6:	1000                	.insn	2, 0x1000
 2c8:	0016                	.insn	2, 0x0016
 2ca:	1349                	.insn	2, 0x1349
 2cc:	0b3a2503          	lw	a0,179(s4)
 2d0:	0000053b          	.insn	4, 0x053b
 2d4:	2411                	.insn	2, 0x2411
 2d6:	0300                	.insn	2, 0x0300
 2d8:	3e25                	.insn	2, 0x3e25
 2da:	000b0b0b          	.insn	4, 0x000b0b0b
 2de:	1200                	.insn	2, 0x1200
 2e0:	0024                	.insn	2, 0x0024
 2e2:	0b0b2503          	lw	a0,176(s6) # b0 <start-0x3fff50>
 2e6:	0b3e                	.insn	2, 0x0b3e
 2e8:	0000                	.insn	2, 0x0000
 2ea:	49001613          	.insn	4, 0x49001613
 2ee:	3a250313          	addi	t1,a0,930 # 20004bc <USER_MAX+0x1b004bc>
 2f2:	000b3b0b          	.insn	4, 0x000b3b0b
 2f6:	1400                	.insn	2, 0x1400
 2f8:	0034                	.insn	2, 0x0034
 2fa:	1349                	.insn	2, 0x1349
 2fc:	0b3a                	.insn	2, 0x0b3a
 2fe:	18020b3b          	.insn	4, 0x18020b3b
 302:	0000                	.insn	2, 0x0000
 304:	2115                	.insn	2, 0x2115
 306:	4900                	.insn	2, 0x4900
 308:	000b3713          	sltiu	a4,s6,0
 30c:	1600                	.insn	2, 0x1600
 30e:	0034                	.insn	2, 0x0034
 310:	1349                	.insn	2, 0x1349
 312:	0b3a                	.insn	2, 0x0b3a
 314:	1802053b          	.insn	4, 0x1802053b
 318:	0000                	.insn	2, 0x0000
 31a:	49000f17          	auipc	t5,0x49000
 31e:	18000013          	li	zero,384
 322:	012e                	.insn	2, 0x012e
 324:	0b3a2503          	lw	a0,179(s4)
 328:	19270b3b          	.insn	4, 0x19270b3b
 32c:	1349                	.insn	2, 0x1349
 32e:	2120                	.insn	2, 0x2120
 330:	0001                	.insn	2, 0x0001
 332:	1900                	.insn	2, 0x1900
 334:	0005                	.insn	2, 0x0005
 336:	0b3a2503          	lw	a0,179(s4)
 33a:	13490b3b          	.insn	4, 0x13490b3b
 33e:	0000                	.insn	2, 0x0000
 340:	2e1a                	.insn	2, 0x2e1a
 342:	1101                	.insn	2, 0x1101
 344:	4006121b          	.insn	4, 0x4006121b
 348:	7a18                	.insn	2, 0x7a18
 34a:	0319                	.insn	2, 0x0319
 34c:	3a25                	.insn	2, 0x3a25
 34e:	270b3b0b          	.insn	4, 0x270b3b0b
 352:	3f19                	.insn	2, 0x3f19
 354:	8719                	.insn	2, 0x8719
 356:	1901                	.insn	2, 0x1901
 358:	0000                	.insn	2, 0x0000
 35a:	1c00051b          	.insn	4, 0x1c00051b
 35e:	310d                	.insn	2, 0x310d
 360:	1c000013          	li	zero,448
 364:	0034                	.insn	2, 0x0034
 366:	2202                	.insn	2, 0x2202
 368:	1331                	.insn	2, 0x1331
 36a:	0000                	.insn	2, 0x0000
 36c:	341d                	.insn	2, 0x341d
 36e:	1c00                	.insn	2, 0x1c00
 370:	310d                	.insn	2, 0x310d
 372:	1e000013          	li	zero,480
 376:	012e                	.insn	2, 0x012e
 378:	0b3a2503          	lw	a0,179(s4)
 37c:	1927053b          	.insn	4, 0x1927053b
 380:	1349                	.insn	2, 0x1349
 382:	2120                	.insn	2, 0x2120
 384:	0001                	.insn	2, 0x0001
 386:	1f00                	.insn	2, 0x1f00
 388:	0005                	.insn	2, 0x0005
 38a:	0b3a2503          	lw	a0,179(s4)
 38e:	1349053b          	.insn	4, 0x1349053b
 392:	0000                	.insn	2, 0x0000
 394:	3420                	.insn	2, 0x3420
 396:	0300                	.insn	2, 0x0300
 398:	3a25                	.insn	2, 0x3a25
 39a:	49053b0b          	.insn	4, 0x49053b0b
 39e:	21000013          	li	zero,528
 3a2:	012e                	.insn	2, 0x012e
 3a4:	0b3a2503          	lw	a0,179(s4)
 3a8:	1927053b          	.insn	4, 0x1927053b
 3ac:	2120193f 22000001 	.insn	8, 0x220000012120193f
 3b4:	012e                	.insn	2, 0x012e
 3b6:	1b11                	.insn	2, 0x1b11
 3b8:	0612                	.insn	2, 0x0612
 3ba:	1840                	.insn	2, 0x1840
 3bc:	197a                	.insn	2, 0x197a
 3be:	0b3a2503          	lw	a0,179(s4)
 3c2:	1927053b          	.insn	4, 0x1927053b
 3c6:	0000193f 02000523 	.insn	8, 0x020005230000193f
 3ce:	0322                	.insn	2, 0x0322
 3d0:	3a25                	.insn	2, 0x3a25
 3d2:	49053b0b          	.insn	4, 0x49053b0b
 3d6:	24000013          	li	zero,576
 3da:	0034                	.insn	2, 0x0034
 3dc:	1802                	.insn	2, 0x1802
 3de:	0b3a2503          	lw	a0,179(s4)
 3e2:	1349053b          	.insn	4, 0x1349053b
 3e6:	0000                	.insn	2, 0x0000
 3e8:	0a25                	.insn	2, 0x0a25
 3ea:	0300                	.insn	2, 0x0300
 3ec:	3a25                	.insn	2, 0x3a25
 3ee:	39053b0b          	.insn	4, 0x39053b0b
 3f2:	001b110b          	.insn	4, 0x001b110b
 3f6:	2600                	.insn	2, 0x2600
 3f8:	0034                	.insn	2, 0x0034
 3fa:	2202                	.insn	2, 0x2202
 3fc:	0b3a2503          	lw	a0,179(s4)
 400:	1349053b          	.insn	4, 0x1349053b
 404:	0000                	.insn	2, 0x0000
 406:	31011d27          	.insn	4, 0x31011d27
 40a:	121b1113          	.insn	4, 0x121b1113
 40e:	5806                	.insn	2, 0x5806
 410:	5705590b          	.insn	4, 0x5705590b
 414:	2800000b          	.insn	4, 0x2800000b
 418:	001d                	.insn	2, 0x001d
 41a:	1331                	.insn	2, 0x1331
 41c:	1b11                	.insn	2, 0x1b11
 41e:	0612                	.insn	2, 0x0612
 420:	0b58                	.insn	2, 0x0b58
 422:	0559                	.insn	2, 0x0559
 424:	00000b57          	.insn	4, 0x0b57
 428:	1d29                	.insn	2, 0x1d29
 42a:	3100                	.insn	2, 0x3100
 42c:	58235513          	.insn	4, 0x58235513
 430:	5705590b          	.insn	4, 0x5705590b
 434:	2a00000b          	.insn	4, 0x2a00000b
 438:	0018                	.insn	2, 0x0018
 43a:	0000                	.insn	2, 0x0000
 43c:	11012e2b          	.insn	4, 0x11012e2b
 440:	4006121b          	.insn	4, 0x4006121b
 444:	7a18                	.insn	2, 0x7a18
 446:	3119                	.insn	2, 0x3119
 448:	2c000013          	li	zero,704
 44c:	0034                	.insn	2, 0x0034
 44e:	1802                	.insn	2, 0x1802
 450:	1331                	.insn	2, 0x1331
 452:	0000                	.insn	2, 0x0000
 454:	342d                	.insn	2, 0x342d
 456:	1c00                	.insn	2, 0x1c00
 458:	0013310f          	.insn	4, 0x0013310f
 45c:	2e00                	.insn	2, 0x2e00
 45e:	012e                	.insn	2, 0x012e
 460:	1b11                	.insn	2, 0x1b11
 462:	0612                	.insn	2, 0x0612
 464:	1840                	.insn	2, 0x1840
 466:	197a                	.insn	2, 0x197a
 468:	0b3a2503          	lw	a0,179(s4)
 46c:	19270b3b          	.insn	4, 0x19270b3b
 470:	1349                	.insn	2, 0x1349
 472:	0000193f 0200342f 	.insn	8, 0x0200342f0000193f
 47a:	0318                	.insn	2, 0x0318
 47c:	3a25                	.insn	2, 0x3a25
 47e:	490b3b0b          	.insn	4, 0x490b3b0b
 482:	30000013          	li	zero,768
 486:	0048                	.insn	2, 0x0048
 488:	1b7d137f 2e310000 	.insn	12, 0x3a2503012e3100001b7d137f
 490:	3a250301 
 494:	270b3b0b          	.insn	4, 0x270b3b0b
 498:	4919                	.insn	2, 0x4919
 49a:	3f193c13          	sltiu	s8,s2,1009
 49e:	0019                	.insn	2, 0x0019
 4a0:	3200                	.insn	2, 0x3200
 4a2:	0005                	.insn	2, 0x0005
 4a4:	1349                	.insn	2, 0x1349
 4a6:	0000                	.insn	2, 0x0000
 4a8:	49002633          	.insn	4, 0x49002633
 4ac:	34000013          	li	zero,832
 4b0:	012e                	.insn	2, 0x012e
 4b2:	1b11                	.insn	2, 0x1b11
 4b4:	0612                	.insn	2, 0x0612
 4b6:	1840                	.insn	2, 0x1840
 4b8:	197a                	.insn	2, 0x197a
 4ba:	0b3a2503          	lw	a0,179(s4)
 4be:	1927053b          	.insn	4, 0x1927053b
 4c2:	1349                	.insn	2, 0x1349
 4c4:	0000193f 02000535 	.insn	8, 0x020005350000193f
 4cc:	0318                	.insn	2, 0x0318
 4ce:	3a25                	.insn	2, 0x3a25
 4d0:	49053b0b          	.insn	4, 0x49053b0b
 4d4:	36000013          	li	zero,864
 4d8:	012e                	.insn	2, 0x012e
 4da:	0b3a2503          	lw	a0,179(s4)
 4de:	1927053b          	.insn	4, 0x1927053b
 4e2:	1349                	.insn	2, 0x1349
 4e4:	2120193f 37000001 	.insn	8, 0x370000012120193f
 4ec:	012e                	.insn	2, 0x012e
 4ee:	0b3a2503          	lw	a0,179(s4)
 4f2:	1927053b          	.insn	4, 0x1927053b
 4f6:	2120                	.insn	2, 0x2120
 4f8:	0001                	.insn	2, 0x0001
 4fa:	3800                	.insn	2, 0x3800
 4fc:	0034                	.insn	2, 0x0034
 4fe:	0f1c                	.insn	2, 0x0f1c
 500:	0b3a2503          	lw	a0,179(s4)
 504:	1349053b          	.insn	4, 0x1349053b
 508:	0000                	.insn	2, 0x0000
 50a:	2e39                	.insn	2, 0x2e39
 50c:	1100                	.insn	2, 0x1100
 50e:	4006121b          	.insn	4, 0x4006121b
 512:	7a18                	.insn	2, 0x7a18
 514:	0319                	.insn	2, 0x0319
 516:	3a25                	.insn	2, 0x3a25
 518:	27053b0b          	.insn	4, 0x27053b0b
 51c:	3f19                	.insn	2, 0x3f19
 51e:	0019                	.insn	2, 0x0019
 520:	3a00                	.insn	2, 0x3a00
 522:	0016                	.insn	2, 0x0016
 524:	1349                	.insn	2, 0x1349
 526:	00002503          	lw	a0,0(zero) # 0 <start-0x400000>
 52a:	00000f3b          	.insn	4, 0x0f3b
 52e:	0000                	.insn	2, 0x0000
 530:	1101                	.insn	2, 0x1101
 532:	2501                	.insn	2, 0x2501
 534:	1325                	.insn	2, 0x1325
 536:	0305                	.insn	2, 0x0305
 538:	7225                	.insn	2, 0x7225
 53a:	1b171017          	auipc	zero,0x1b171
 53e:	1125                	.insn	2, 0x1125
 540:	7306121b          	.insn	4, 0x7306121b
 544:	8c177417          	auipc	s0,0x8c177
 548:	1701                	.insn	2, 0x1701
 54a:	0000                	.insn	2, 0x0000
 54c:	3402                	.insn	2, 0x3402
 54e:	4900                	.insn	2, 0x4900
 550:	3b0b3a13          	sltiu	s4,s6,944
 554:	0018020b          	.insn	4, 0x0018020b
 558:	0300                	.insn	2, 0x0300
 55a:	0101                	.insn	2, 0x0101
 55c:	1349                	.insn	2, 0x1349
 55e:	0000                	.insn	2, 0x0000
 560:	2104                	.insn	2, 0x2104
 562:	4900                	.insn	2, 0x4900
 564:	000b3713          	sltiu	a4,s6,0
 568:	0500                	.insn	2, 0x0500
 56a:	0024                	.insn	2, 0x0024
 56c:	0b3e2503          	lw	a0,179(t3)
 570:	00000b0b          	.insn	4, 0x0b0b
 574:	2406                	.insn	2, 0x2406
 576:	0300                	.insn	2, 0x0300
 578:	0b25                	.insn	2, 0x0b25
 57a:	000b3e0b          	.insn	4, 0x000b3e0b
 57e:	0700                	.insn	2, 0x0700
 580:	0034                	.insn	2, 0x0034
 582:	1349                	.insn	2, 0x1349
 584:	0b3a                	.insn	2, 0x0b3a
 586:	1802053b          	.insn	4, 0x1802053b
 58a:	0000                	.insn	2, 0x0000
 58c:	3408                	.insn	2, 0x3408
 58e:	0300                	.insn	2, 0x0300
 590:	4925                	.insn	2, 0x4925
 592:	3b0b3a13          	sltiu	s4,s6,944
 596:	0018020b          	.insn	4, 0x0018020b
 59a:	0900                	.insn	2, 0x0900
 59c:	0021                	.insn	2, 0x0021
 59e:	1349                	.insn	2, 0x1349
 5a0:	00000537          	lui	a0,0x0
 5a4:	160a                	.insn	2, 0x160a
 5a6:	4900                	.insn	2, 0x4900
 5a8:	3a250313          	addi	t1,a0,930 # 3a2 <start-0x3ffc5e>
 5ac:	000b3b0b          	.insn	4, 0x000b3b0b
 5b0:	0b00                	.insn	2, 0x0b00
 5b2:	0034                	.insn	2, 0x0034
 5b4:	13492503          	lw	a0,308(s2)
 5b8:	0b3a193f 18020b3b 	.insn	8, 0x18020b3b0b3a193f
 5c0:	0000                	.insn	2, 0x0000
 5c2:	130c                	.insn	2, 0x130c
 5c4:	0b01                	.insn	2, 0x0b01
 5c6:	3b0b3a0b          	.insn	4, 0x3b0b3a0b
 5ca:	0d00000b          	.insn	4, 0x0d00000b
 5ce:	000d                	.insn	2, 0x000d
 5d0:	13492503          	lw	a0,308(s2)
 5d4:	0b3a                	.insn	2, 0x0b3a
 5d6:	0b380b3b          	.insn	4, 0x0b380b3b
 5da:	0000                	.insn	2, 0x0000
 5dc:	2e0e                	.insn	2, 0x2e0e
 5de:	0301                	.insn	2, 0x0301
 5e0:	3a25                	.insn	2, 0x3a25
 5e2:	270b3b0b          	.insn	4, 0x270b3b0b
 5e6:	4919                	.insn	2, 0x4919
 5e8:	20193f13          	sltiu	t5,s2,513
 5ec:	0121                	.insn	2, 0x0121
 5ee:	0000                	.insn	2, 0x0000
 5f0:	0300050f          	.insn	4, 0x0300050f
 5f4:	3a25                	.insn	2, 0x3a25
 5f6:	490b3b0b          	.insn	4, 0x490b3b0b
 5fa:	10000013          	li	zero,256
 5fe:	012e                	.insn	2, 0x012e
 600:	1b11                	.insn	2, 0x1b11
 602:	0612                	.insn	2, 0x0612
 604:	1840                	.insn	2, 0x1840
 606:	197a                	.insn	2, 0x197a
 608:	0b3a2503          	lw	a0,179(s4)
 60c:	19270b3b          	.insn	4, 0x19270b3b
 610:	1349                	.insn	2, 0x1349
 612:	0000193f 02000511 	.insn	8, 0x020005110000193f
 61a:	0322                	.insn	2, 0x0322
 61c:	3a25                	.insn	2, 0x3a25
 61e:	490b3b0b          	.insn	4, 0x490b3b0b
 622:	12000013          	li	zero,288
 626:	0034                	.insn	2, 0x0034
 628:	1802                	.insn	2, 0x1802
 62a:	0b3a2503          	lw	a0,179(s4)
 62e:	13490b3b          	.insn	4, 0x13490b3b
 632:	0000                	.insn	2, 0x0000
 634:	02003413          	sltiu	s0,zero,32
 638:	0322                	.insn	2, 0x0322
 63a:	3a25                	.insn	2, 0x3a25
 63c:	490b3b0b          	.insn	4, 0x490b3b0b
 640:	14000013          	li	zero,320
 644:	011d                	.insn	2, 0x011d
 646:	1331                	.insn	2, 0x1331
 648:	1b11                	.insn	2, 0x1b11
 64a:	0612                	.insn	2, 0x0612
 64c:	0b58                	.insn	2, 0x0b58
 64e:	0b59                	.insn	2, 0x0b59
 650:	00000b57          	.insn	4, 0x0b57
 654:	0515                	.insn	2, 0x0515
 656:	0200                	.insn	2, 0x0200
 658:	3122                	.insn	2, 0x3122
 65a:	16000013          	li	zero,352
 65e:	1b11010b          	.insn	4, 0x1b11010b
 662:	0612                	.insn	2, 0x0612
 664:	0000                	.insn	2, 0x0000
 666:	7f004817          	auipc	a6,0x7f004
 66a:	001b7d13          	andi	s10,s6,1
 66e:	1800                	.insn	2, 0x1800
 670:	0034                	.insn	2, 0x0034
 672:	0b3a2503          	lw	a0,179(s4)
 676:	13490b3b          	.insn	4, 0x13490b3b
 67a:	0000                	.insn	2, 0x0000
 67c:	0b19                	.insn	2, 0x0b19
 67e:	5501                	.insn	2, 0x5501
 680:	1a000023          	sb	zero,416(zero) # 1a0 <start-0x3ffe60>
 684:	012e                	.insn	2, 0x012e
 686:	0b3a2503          	lw	a0,179(s4)
 68a:	19270b3b          	.insn	4, 0x19270b3b
 68e:	193c                	.insn	2, 0x193c
 690:	0000193f 4900051b 	.insn	8, 0x4900051b0000193f
 698:	1c000013          	li	zero,448
 69c:	0018                	.insn	2, 0x0018
 69e:	0000                	.insn	2, 0x0000
 6a0:	0f1d                	.insn	2, 0x0f1d
 6a2:	4900                	.insn	2, 0x4900
 6a4:	1e000013          	li	zero,480
 6a8:	0026                	.insn	2, 0x0026
 6aa:	1349                	.insn	2, 0x1349
 6ac:	0000                	.insn	2, 0x0000
 6ae:	2e1f 0301 3a25      	.insn	6, 0x3a2503012e1f
 6b4:	270b3b0b          	.insn	4, 0x270b3b0b
 6b8:	4919                	.insn	2, 0x4919
 6ba:	3f193c13          	sltiu	s8,s2,1009
 6be:	0019                	.insn	2, 0x0019
 6c0:	2000                	.insn	2, 0x2000
 6c2:	0000000f          	fence	unknown,unknown
 6c6:	2e21                	.insn	2, 0x2e21
 6c8:	1101                	.insn	2, 0x1101
 6ca:	4006121b          	.insn	4, 0x4006121b
 6ce:	7a18                	.insn	2, 0x7a18
 6d0:	3119                	.insn	2, 0x3119
 6d2:	22000013          	li	zero,544
 6d6:	012e                	.insn	2, 0x012e
 6d8:	1b11                	.insn	2, 0x1b11
 6da:	0612                	.insn	2, 0x0612
 6dc:	1840                	.insn	2, 0x1840
 6de:	197a                	.insn	2, 0x197a
 6e0:	0b3a2503          	lw	a0,179(s4)
 6e4:	19270b3b          	.insn	4, 0x19270b3b
 6e8:	0000193f 02000523 	.insn	8, 0x020005230000193f
 6f0:	3118                	.insn	2, 0x3118
 6f2:	24000013          	li	zero,576
 6f6:	012e                	.insn	2, 0x012e
 6f8:	0b3a2503          	lw	a0,179(s4)
 6fc:	19270b3b          	.insn	4, 0x19270b3b
 700:	1349                	.insn	2, 0x1349
 702:	2120                	.insn	2, 0x2120
 704:	0001                	.insn	2, 0x0001
 706:	2500                	.insn	2, 0x2500
 708:	0034                	.insn	2, 0x0034
 70a:	0b3a2503          	lw	a0,179(s4)
 70e:	1349053b          	.insn	4, 0x1349053b
 712:	0000                	.insn	2, 0x0000
 714:	2e26                	.insn	2, 0x2e26
 716:	1101                	.insn	2, 0x1101
 718:	4006121b          	.insn	4, 0x4006121b
 71c:	7a18                	.insn	2, 0x7a18
 71e:	0319                	.insn	2, 0x0319
 720:	3a25                	.insn	2, 0x3a25
 722:	27053b0b          	.insn	4, 0x27053b0b
 726:	4919                	.insn	2, 0x4919
 728:	00193f13          	seqz	t5,s2
 72c:	2700                	.insn	2, 0x2700
 72e:	0005                	.insn	2, 0x0005
 730:	2202                	.insn	2, 0x2202
 732:	0b3a2503          	lw	a0,179(s4)
 736:	1349053b          	.insn	4, 0x1349053b
 73a:	0000                	.insn	2, 0x0000
 73c:	3428                	.insn	2, 0x3428
 73e:	0200                	.insn	2, 0x0200
 740:	0318                	.insn	2, 0x0318
 742:	3a25                	.insn	2, 0x3a25
 744:	49053b0b          	.insn	4, 0x49053b0b
 748:	29000013          	li	zero,656
 74c:	0034                	.insn	2, 0x0034
 74e:	2202                	.insn	2, 0x2202
 750:	0b3a2503          	lw	a0,179(s4)
 754:	1349053b          	.insn	4, 0x1349053b
 758:	0000                	.insn	2, 0x0000
 75a:	1d2a                	.insn	2, 0x1d2a
 75c:	3101                	.insn	2, 0x3101
 75e:	121b1113          	.insn	4, 0x121b1113
 762:	5806                	.insn	2, 0x5806
 764:	5705590b          	.insn	4, 0x5705590b
 768:	2b00000b          	.insn	4, 0x2b00000b
 76c:	0034                	.insn	2, 0x0034
 76e:	2202                	.insn	2, 0x2202
 770:	1331                	.insn	2, 0x1331
 772:	0000                	.insn	2, 0x0000
	...

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
      30:	03040723          	sb	a6,46(s0) # 8c177572 <USER_MAX+0x8bc77572>
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
     7bc:	0bc1                	.insn	2, 0x0bc1
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
     7e8:	00027c0f          	.insn	4, 0x00027c0f
     7ec:	0100                	.insn	2, 0x0100
     7ee:	2952                	.insn	2, 0x2952
     7f0:	7802                	.insn	2, 0x7802
     7f2:	028a0303          	lb	t1,40(s4)
     7f6:	0000                	.insn	2, 0x0000
     7f8:	7a02                	.insn	2, 0x7a02
     7fa:	a102                	.insn	2, 0xa102
     7fc:	0300                	.insn	2, 0x0300
     7fe:	00028a07          	.insn	4, 0x00028a07
     802:	0200                	.insn	2, 0x0200
     804:	01a1027b          	.insn	4, 0x01a1027b
     808:	02a80803          	lb	a6,42(a6) # 7f004690 <USER_MAX+0x7eb04690>
     80c:	0000                	.insn	2, 0x0000
     80e:	7c02                	.insn	2, 0x7c02
     810:	a102                	.insn	2, 0xa102
     812:	0402                	.insn	2, 0x0402
     814:	3d01                	.insn	2, 0x3d01
     816:	7802                	.insn	2, 0x7802
     818:	02b5                	.insn	2, 0x02b5
     81a:	0000                	.insn	2, 0x0000
     81c:	1005                	.insn	2, 0x1005
     81e:	0088                	.insn	2, 0x0088
     820:	0000                	.insn	2, 0x0000
     822:	0206                	.insn	2, 0x0206
     824:	023e                	.insn	2, 0x023e
     826:	b585                	.insn	2, 0xb585
     828:	0002                	.insn	2, 0x0002
     82a:	0500                	.insn	2, 0x0500
     82c:	5011                	.insn	2, 0x5011
     82e:	0000                	.insn	2, 0x0000
     830:	0600                	.insn	2, 0x0600
     832:	86023f03          	.insn	4, 0x86023f03
     836:	02b5                	.insn	2, 0x02b5
     838:	0000                	.insn	2, 0x0000
     83a:	40080007          	.insn	4, 0x40080007
     83e:	8702                	.insn	2, 0x8702
     840:	0ba2                	.insn	2, 0x0ba2
     842:	0000                	.insn	2, 0x0000
     844:	0000                	.insn	2, 0x0000
     846:	0900                	.insn	2, 0x0900
     848:	0460                	.insn	2, 0x0460
     84a:	0000                	.insn	2, 0x0000
     84c:	3c12                	.insn	2, 0x3c12
     84e:	0000                	.insn	2, 0x0000
     850:	0200                	.insn	2, 0x0200
     852:	0a0a058f          	.insn	4, 0x0a0a058f
     856:	0469                	.insn	2, 0x0469
     858:	0000                	.insn	2, 0x0000
     85a:	0472040b          	.insn	4, 0x0472040b
     85e:	0000                	.insn	2, 0x0000
     860:	047b050b          	.insn	4, 0x047b050b
     864:	0000                	.insn	2, 0x0000
     866:	0484060b          	.insn	4, 0x0484060b
     86a:	0000                	.insn	2, 0x0000
     86c:	010c                	.insn	2, 0x010c
     86e:	8d5f 0004 0000      	.insn	6, 0x00048d5f
     874:	a809                	.insn	2, 0xa809
     876:	0004                	.insn	2, 0x0004
     878:	1300                	.insn	2, 0x1300
     87a:	000c                	.insn	2, 0x000c
     87c:	0000                	.insn	2, 0x0000
     87e:	9702                	.insn	2, 0x9702
     880:	0a05                	.insn	2, 0x0a05
     882:	ad41                	.insn	2, 0xad41
     884:	0004                	.insn	2, 0x0004
     886:	0000                	.insn	2, 0x0000
     888:	a809                	.insn	2, 0xa809
     88a:	0004                	.insn	2, 0x0004
     88c:	1400                	.insn	2, 0x1400
     88e:	0014                	.insn	2, 0x0014
     890:	0000                	.insn	2, 0x0000
     892:	9802                	.insn	2, 0x9802
     894:	0a05                	.insn	2, 0x0a05
     896:	ad0a                	.insn	2, 0xad0a
     898:	0004                	.insn	2, 0x0004
     89a:	0000                	.insn	2, 0x0000
     89c:	1505                	.insn	2, 0x1505
     89e:	004c                	.insn	2, 0x004c
     8a0:	0000                	.insn	2, 0x0000
     8a2:	0706                	.insn	2, 0x0706
     8a4:	023e                	.insn	2, 0x023e
     8a6:	b59a                	.insn	2, 0xb59a
     8a8:	0002                	.insn	2, 0x0002
     8aa:	0500                	.insn	2, 0x0500
     8ac:	3415                	.insn	2, 0x3415
     8ae:	0000                	.insn	2, 0x0000
     8b0:	0600                	.insn	2, 0x0600
     8b2:	3f08                	.insn	2, 0x3f08
     8b4:	9b02                	.insn	2, 0x9b02
     8b6:	02b5                	.insn	2, 0x02b5
     8b8:	0000                	.insn	2, 0x0000
     8ba:	b709                	.insn	2, 0xb709
     8bc:	0004                	.insn	2, 0x0004
     8be:	1600                	.insn	2, 0x1600
     8c0:	000c                	.insn	2, 0x000c
     8c2:	0000                	.insn	2, 0x0000
     8c4:	9c02                	.insn	2, 0x9c02
     8c6:	0c0d                	.insn	2, 0x0c0d
     8c8:	6e01                	.insn	2, 0x6e01
     8ca:	04bc                	.insn	2, 0x04bc
     8cc:	0000                	.insn	2, 0x0000
     8ce:	0900                	.insn	2, 0x0900
     8d0:	04a8                	.insn	2, 0x04a8
     8d2:	0000                	.insn	2, 0x0000
     8d4:	00000c17          	auipc	s8,0x0
     8d8:	0200                	.insn	2, 0x0200
     8da:	0d9d                	.insn	2, 0x0d9d
     8dc:	200a                	.insn	2, 0x200a
     8de:	04ad                	.insn	2, 0x04ad
     8e0:	0000                	.insn	2, 0x0000
     8e2:	0000                	.insn	2, 0x0000
     8e4:	a809                	.insn	2, 0xa809
     8e6:	0004                	.insn	2, 0x0004
     8e8:	1800                	.insn	2, 0x1800
     8ea:	000c                	.insn	2, 0x000c
     8ec:	0000                	.insn	2, 0x0000
     8ee:	9f02                	.insn	2, 0x9f02
     8f0:	0a09                	.insn	2, 0x0a09
     8f2:	ad0a                	.insn	2, 0xad0a
     8f4:	0004                	.insn	2, 0x0004
     8f6:	0000                	.insn	2, 0x0000
     8f8:	0900                	.insn	2, 0x0900
     8fa:	04a8                	.insn	2, 0x04a8
     8fc:	0000                	.insn	2, 0x0000
     8fe:	0c19                	.insn	2, 0x0c19
     900:	0000                	.insn	2, 0x0000
     902:	0200                	.insn	2, 0x0200
     904:	05a2                	.insn	2, 0x05a2
     906:	0a0a                	.insn	2, 0x0a0a
     908:	04ad                	.insn	2, 0x04ad
     90a:	0000                	.insn	2, 0x0000
     90c:	0900                	.insn	2, 0x0900
     90e:	04a8                	.insn	2, 0x04a8
     910:	0000                	.insn	2, 0x0000
     912:	0c1a                	.insn	2, 0x0c1a
     914:	0000                	.insn	2, 0x0000
     916:	0200                	.insn	2, 0x0200
     918:	420a05a3          	sb	zero,1067(s4)
     91c:	04ad                	.insn	2, 0x04ad
     91e:	0000                	.insn	2, 0x0000
     920:	0900                	.insn	2, 0x0900
     922:	04a8                	.insn	2, 0x04a8
     924:	0000                	.insn	2, 0x0000
     926:	0000141b          	.insn	4, 0x141b
     92a:	0200                	.insn	2, 0x0200
     92c:	05a4                	.insn	2, 0x05a4
     92e:	0a0a                	.insn	2, 0x0a0a
     930:	04ad                	.insn	2, 0x04ad
     932:	0000                	.insn	2, 0x0000
     934:	0500                	.insn	2, 0x0500
     936:	4c1c                	.insn	2, 0x4c1c
     938:	0000                	.insn	2, 0x0000
     93a:	0600                	.insn	2, 0x0600
     93c:	3e09                	.insn	2, 0x3e09
     93e:	a602                	.insn	2, 0xa602
     940:	02b5                	.insn	2, 0x02b5
     942:	0000                	.insn	2, 0x0000
     944:	1c05                	.insn	2, 0x1c05
     946:	0034                	.insn	2, 0x0034
     948:	0000                	.insn	2, 0x0000
     94a:	0a06                	.insn	2, 0x0a06
     94c:	b5a7023f 09000002 	.insn	8, 0x09000002b5a7023f
     954:	000004b7          	lui	s1,0x0
     958:	0c1d                	.insn	2, 0x0c1d
     95a:	0000                	.insn	2, 0x0000
     95c:	0200                	.insn	2, 0x0200
     95e:	0da8                	.insn	2, 0x0da8
     960:	010c                	.insn	2, 0x010c
     962:	bc6d                	.insn	2, 0xbc6d
     964:	0004                	.insn	2, 0x0004
     966:	0000                	.insn	2, 0x0000
     968:	a809                	.insn	2, 0xa809
     96a:	0004                	.insn	2, 0x0004
     96c:	1e00                	.insn	2, 0x1e00
     96e:	000c                	.insn	2, 0x000c
     970:	0000                	.insn	2, 0x0000
     972:	a902                	.insn	2, 0xa902
     974:	0a0d                	.insn	2, 0x0a0d
     976:	ad20                	.insn	2, 0xad20
     978:	0004                	.insn	2, 0x0004
     97a:	0000                	.insn	2, 0x0000
     97c:	0900                	.insn	2, 0x0900
     97e:	04a8                	.insn	2, 0x04a8
     980:	0000                	.insn	2, 0x0000
     982:	0c1f 0000 0200      	.insn	6, 0x020000000c1f
     988:	0a0a09ab          	.insn	4, 0x0a0a09ab
     98c:	04ad                	.insn	2, 0x04ad
     98e:	0000                	.insn	2, 0x0000
     990:	0000                	.insn	2, 0x0000
     992:	a809                	.insn	2, 0xa809
     994:	0004                	.insn	2, 0x0004
     996:	2000                	.insn	2, 0x2000
     998:	000c                	.insn	2, 0x000c
     99a:	0000                	.insn	2, 0x0000
     99c:	ae02                	.insn	2, 0xae02
     99e:	0a05                	.insn	2, 0x0a05
     9a0:	ad0a                	.insn	2, 0xad0a
     9a2:	0004                	.insn	2, 0x0004
     9a4:	0000                	.insn	2, 0x0000
     9a6:	a809                	.insn	2, 0xa809
     9a8:	0004                	.insn	2, 0x0004
     9aa:	2100                	.insn	2, 0x2100
     9ac:	000c                	.insn	2, 0x000c
     9ae:	0000                	.insn	2, 0x0000
     9b0:	af02                	.insn	2, 0xaf02
     9b2:	0a05                	.insn	2, 0x0a05
     9b4:	0004ad43          	.insn	4, 0x0004ad43
     9b8:	0000                	.insn	2, 0x0000
     9ba:	a809                	.insn	2, 0xa809
     9bc:	0004                	.insn	2, 0x0004
     9be:	2200                	.insn	2, 0x2200
     9c0:	0014                	.insn	2, 0x0014
     9c2:	0000                	.insn	2, 0x0000
     9c4:	b002                	.insn	2, 0xb002
     9c6:	0a05                	.insn	2, 0x0a05
     9c8:	ad0a                	.insn	2, 0xad0a
     9ca:	0004                	.insn	2, 0x0004
     9cc:	0000                	.insn	2, 0x0000
     9ce:	2305                	.insn	2, 0x2305
     9d0:	004c                	.insn	2, 0x004c
     9d2:	0000                	.insn	2, 0x0000
     9d4:	0b06                	.insn	2, 0x0b06
     9d6:	023e                	.insn	2, 0x023e
     9d8:	b5b2                	.insn	2, 0xb5b2
     9da:	0002                	.insn	2, 0x0002
     9dc:	0500                	.insn	2, 0x0500
     9de:	00003423          	.insn	4, 0x3423
     9e2:	0600                	.insn	2, 0x0600
     9e4:	3f0c                	.insn	2, 0x3f0c
     9e6:	b302                	.insn	2, 0xb302
     9e8:	02b5                	.insn	2, 0x02b5
     9ea:	0000                	.insn	2, 0x0000
     9ec:	b709                	.insn	2, 0xb709
     9ee:	0004                	.insn	2, 0x0004
     9f0:	2400                	.insn	2, 0x2400
     9f2:	000c                	.insn	2, 0x000c
     9f4:	0000                	.insn	2, 0x0000
     9f6:	b402                	.insn	2, 0xb402
     9f8:	0c0d                	.insn	2, 0x0c0d
     9fa:	6c01                	.insn	2, 0x6c01
     9fc:	04bc                	.insn	2, 0x04bc
     9fe:	0000                	.insn	2, 0x0000
     a00:	0900                	.insn	2, 0x0900
     a02:	04a8                	.insn	2, 0x04a8
     a04:	0000                	.insn	2, 0x0000
     a06:	0c25                	.insn	2, 0x0c25
     a08:	0000                	.insn	2, 0x0000
     a0a:	0200                	.insn	2, 0x0200
     a0c:	0db5                	.insn	2, 0x0db5
     a0e:	200a                	.insn	2, 0x200a
     a10:	04ad                	.insn	2, 0x04ad
     a12:	0000                	.insn	2, 0x0000
     a14:	0000                	.insn	2, 0x0000
     a16:	a809                	.insn	2, 0xa809
     a18:	0004                	.insn	2, 0x0004
     a1a:	2600                	.insn	2, 0x2600
     a1c:	000c                	.insn	2, 0x000c
     a1e:	0000                	.insn	2, 0x0000
     a20:	b702                	.insn	2, 0xb702
     a22:	0a09                	.insn	2, 0x0a09
     a24:	ad0a                	.insn	2, 0xad0a
     a26:	0004                	.insn	2, 0x0004
     a28:	0000                	.insn	2, 0x0000
     a2a:	0900                	.insn	2, 0x0900
     a2c:	04a8                	.insn	2, 0x04a8
     a2e:	0000                	.insn	2, 0x0000
     a30:	00000c27          	.insn	4, 0x0c27
     a34:	0200                	.insn	2, 0x0200
     a36:	05ba                	.insn	2, 0x05ba
     a38:	0a0a                	.insn	2, 0x0a0a
     a3a:	04ad                	.insn	2, 0x04ad
     a3c:	0000                	.insn	2, 0x0000
     a3e:	0d00                	.insn	2, 0x0d00
     a40:	04c6                	.insn	2, 0x04c6
     a42:	0000                	.insn	2, 0x0000
     a44:	0028                	.insn	2, 0x0028
     a46:	970e                	.insn	2, 0x970e
     a48:	0002                	.insn	2, 0x0002
     a4a:	0f00                	.insn	2, 0x0f00
     a4c:	02a4                	.insn	2, 0x02a4
     a4e:	0000                	.insn	2, 0x0000
     a50:	1000                	.insn	2, 0x1000
     a52:	1000                	.insn	2, 0x1000
     a54:	02a0                	.insn	2, 0x02a0
     a56:	0000                	.insn	2, 0x0000
     a58:	0105                	.insn	2, 0x0105
     a5a:	010e                	.insn	2, 0x010e
     a5c:	0411                	.insn	2, 0x0411
     a5e:	0108                	.insn	2, 0x0108
     a60:	0612                	.insn	2, 0x0612
     a62:	0708                	.insn	2, 0x0708
     a64:	b50e                	.insn	2, 0xb50e
     a66:	0002                	.insn	2, 0x0002
     a68:	0f00                	.insn	2, 0x0f00
     a6a:	02a4                	.insn	2, 0x02a4
     a6c:	0000                	.insn	2, 0x0000
     a6e:	1000                	.insn	2, 0x1000
     a70:	1300                	.insn	2, 0x1300
     a72:	02bd                	.insn	2, 0x02bd
     a74:	0000                	.insn	2, 0x0000
     a76:	010a                	.insn	2, 0x010a
     a78:	11ca                	.insn	2, 0x11ca
     a7a:	0709                	.insn	2, 0x0709
     a7c:	1404                	.insn	2, 0x1404
     a7e:	000002cb          	.insn	4, 0x02cb
     a82:	8102                	.insn	2, 0x8102
     a84:	a102                	.insn	2, 0xa102
     a86:	02d70e03          	lb	t3,45(a4)
     a8a:	0000                	.insn	2, 0x0000
     a8c:	a415                	.insn	2, 0xa415
     a8e:	0002                	.insn	2, 0x0002
     a90:	1500                	.insn	2, 0x1500
     a92:	1100                	.insn	2, 0x1100
     a94:	1401080b          	.insn	4, 0x1401080b
     a98:	02e5                	.insn	2, 0x02e5
     a9a:	0000                	.insn	2, 0x0000
     a9c:	e502                	.insn	2, 0xe502
     a9e:	a102                	.insn	2, 0xa102
     aa0:	0e04                	.insn	2, 0x0e04
     aa2:	000002d7          	.insn	4, 0x02d7
     aa6:	a415                	.insn	2, 0xa415
     aa8:	0002                	.insn	2, 0x0002
     aaa:	0800                	.insn	2, 0x0800
     aac:	1400                	.insn	2, 0x1400
     aae:	000002fb          	.insn	4, 0x02fb
     ab2:	e902                	.insn	2, 0xe902
     ab4:	a102                	.insn	2, 0xa102
     ab6:	0e05                	.insn	2, 0x0e05
     ab8:	000002d7          	.insn	4, 0x02d7
     abc:	a415                	.insn	2, 0xa415
     abe:	0002                	.insn	2, 0x0002
     ac0:	1300                	.insn	2, 0x1300
     ac2:	1400                	.insn	2, 0x1400
     ac4:	0311                	.insn	2, 0x0311
     ac6:	0000                	.insn	2, 0x0000
     ac8:	ee02                	.insn	2, 0xee02
     aca:	a102                	.insn	2, 0xa102
     acc:	0e06                	.insn	2, 0x0e06
     ace:	000002d7          	.insn	4, 0x02d7
     ad2:	a415                	.insn	2, 0xa415
     ad4:	0002                	.insn	2, 0x0002
     ad6:	1800                	.insn	2, 0x1800
     ad8:	1400                	.insn	2, 0x1400
     ada:	00000327          	.insn	4, 0x0327
     ade:	f602                	.insn	2, 0xf602
     ae0:	a102                	.insn	2, 0xa102
     ae2:	02d70e07          	.insn	4, 0x02d70e07
     ae6:	0000                	.insn	2, 0x0000
     ae8:	a415                	.insn	2, 0xa415
     aea:	0002                	.insn	2, 0x0002
     aec:	1e00                	.insn	2, 0x1e00
     aee:	1600                	.insn	2, 0x1600
     af0:	033e                	.insn	2, 0x033e
     af2:	0000                	.insn	2, 0x0000
     af4:	3302                	.insn	2, 0x3302
     af6:	0201                	.insn	2, 0x0201
     af8:	08a1                	.insn	2, 0x08a1
     afa:	d70e                	.insn	2, 0xd70e
     afc:	0002                	.insn	2, 0x0002
     afe:	1500                	.insn	2, 0x1500
     b00:	02a4                	.insn	2, 0x02a4
     b02:	0000                	.insn	2, 0x0000
     b04:	001a                	.insn	2, 0x001a
     b06:	5516                	.insn	2, 0x5516
     b08:	02000003          	lb	zero,32(zero) # 20 <start-0x3fffe0>
     b0c:	013a                	.insn	2, 0x013a
     b0e:	a102                	.insn	2, 0xa102
     b10:	0e09                	.insn	2, 0x0e09
     b12:	000002d7          	.insn	4, 0x02d7
     b16:	a415                	.insn	2, 0xa415
     b18:	0002                	.insn	2, 0x0002
     b1a:	0c00                	.insn	2, 0x0c00
     b1c:	1600                	.insn	2, 0x1600
     b1e:	036c                	.insn	2, 0x036c
     b20:	0000                	.insn	2, 0x0000
     b22:	3e02                	.insn	2, 0x3e02
     b24:	0201                	.insn	2, 0x0201
     b26:	0aa1                	.insn	2, 0x0aa1
     b28:	d70e                	.insn	2, 0xd70e
     b2a:	0002                	.insn	2, 0x0002
     b2c:	1500                	.insn	2, 0x1500
     b2e:	02a4                	.insn	2, 0x02a4
     b30:	0000                	.insn	2, 0x0000
     b32:	000e                	.insn	2, 0x000e
     b34:	8316                	.insn	2, 0x8316
     b36:	02000003          	lb	zero,32(zero) # 20 <start-0x3fffe0>
     b3a:	0142                	.insn	2, 0x0142
     b3c:	a102                	.insn	2, 0xa102
     b3e:	02d70e0b          	.insn	4, 0x02d70e0b
     b42:	0000                	.insn	2, 0x0000
     b44:	a415                	.insn	2, 0xa415
     b46:	0002                	.insn	2, 0x0002
     b48:	1100                	.insn	2, 0x1100
     b4a:	1600                	.insn	2, 0x1600
     b4c:	039a                	.insn	2, 0x039a
     b4e:	0000                	.insn	2, 0x0000
     b50:	4602                	.insn	2, 0x4602
     b52:	0201                	.insn	2, 0x0201
     b54:	0ca1                	.insn	2, 0x0ca1
     b56:	d70e                	.insn	2, 0xd70e
     b58:	0002                	.insn	2, 0x0002
     b5a:	1500                	.insn	2, 0x1500
     b5c:	02a4                	.insn	2, 0x02a4
     b5e:	0000                	.insn	2, 0x0000
     b60:	0012                	.insn	2, 0x0012
     b62:	8316                	.insn	2, 0x8316
     b64:	02000003          	lb	zero,32(zero) # 20 <start-0x3fffe0>
     b68:	01a6                	.insn	2, 0x01a6
     b6a:	a102                	.insn	2, 0xa102
     b6c:	100d                	.insn	2, 0x100d
     b6e:	02bd                	.insn	2, 0x02bd
     b70:	0000                	.insn	2, 0x0000
     b72:	010c                	.insn	2, 0x010c
     b74:	012e                	.insn	2, 0x012e
     b76:	0d11                	.insn	2, 0x0d11
     b78:	0405                	.insn	2, 0x0405
     b7a:	0002a017          	auipc	zero,0x2a
     b7e:	1300                	.insn	2, 0x1300
     b80:	03ba                	.insn	2, 0x03ba
     b82:	0000                	.insn	2, 0x0000
     b84:	010e                	.insn	2, 0x010e
     b86:	18c5                	.insn	2, 0x18c5
     b88:	ba3a020f          	.insn	4, 0xba3a020f
     b8c:	19000003          	lb	zero,400(zero) # 190 <start-0x3ffe70>
     b90:	0210                	.insn	2, 0x0210
     b92:	ba3a                	.insn	2, 0xba3a
     b94:	19000003          	lb	zero,400(zero) # 190 <start-0x3ffe70>
     b98:	0211                	.insn	2, 0x0211
     b9a:	ba3a                	.insn	2, 0xba3a
     b9c:	19000003          	lb	zero,400(zero) # 190 <start-0x3ffe70>
     ba0:	0212                	.insn	2, 0x0212
     ba2:	ba3a                	.insn	2, 0xba3a
     ba4:	19000003          	lb	zero,400(zero) # 190 <start-0x3ffe70>
     ba8:	ba3a0213          	addi	tp,s4,-1117
     bac:	08000003          	lb	zero,128(zero) # 80 <start-0x3fff80>
     bb0:	0214                	.insn	2, 0x0214
     bb2:	ba3c                	.insn	2, 0xba3c
     bb4:	08000003          	lb	zero,128(zero) # 80 <start-0x3fff80>
     bb8:	0215                	.insn	2, 0x0215
     bba:	ba3d                	.insn	2, 0xba3d
     bbc:	08000003          	lb	zero,128(zero) # 80 <start-0x3fff80>
     bc0:	0216                	.insn	2, 0x0216
     bc2:	ba3e                	.insn	2, 0xba3e
     bc4:	08000003          	lb	zero,128(zero) # 80 <start-0x3fff80>
     bc8:	ba3f0217          	auipc	tp,0xba3f0
     bcc:	00000003          	lb	zero,0(zero) # 0 <start-0x400000>
     bd0:	0e1a                	.insn	2, 0x0e1a
     bd2:	0018                	.insn	2, 0x0018
     bd4:	0000                	.insn	2, 0x0000
     bd6:	5201                	.insn	2, 0x5201
     bd8:	0228                	.insn	2, 0x0228
     bda:	094e                	.insn	2, 0x094e
     bdc:	000003cb          	.insn	4, 0x03cb
     be0:	140e                	.insn	2, 0x140e
     be2:	0000                	.insn	2, 0x0000
     be4:	0200                	.insn	2, 0x0200
     be6:	da1b0553          	.insn	4, 0xda1b0553
     bea:	d300                	.insn	2, 0xd300
     bec:	1b000003          	lb	zero,432(zero) # 1b0 <start-0x3ffe50>
     bf0:	db00                	.insn	2, 0xdb00
     bf2:	1b000003          	lb	zero,432(zero) # 1b0 <start-0x3ffe50>
     bf6:	e300                	.insn	2, 0xe300
     bf8:	1b000003          	lb	zero,432(zero) # 1b0 <start-0x3ffe50>
     bfc:	eb00                	.insn	2, 0xeb00
     bfe:	1c000003          	lb	zero,448(zero) # 1c0 <start-0x3ffe40>
     c02:	f300                	.insn	2, 0xf300
     c04:	1d000003          	lb	zero,464(zero) # 1d0 <start-0x3ffe30>
     c08:	fb00                	.insn	2, 0xfb00
     c0a:	1d000003          	lb	zero,464(zero) # 1d0 <start-0x3ffe30>
     c0e:	0300                	.insn	2, 0x0300
     c10:	0004                	.insn	2, 0x0004
     c12:	1d00                	.insn	2, 0x1d00
     c14:	00da                	.insn	2, 0x00da
     c16:	0000040b          	.insn	4, 0x040b
     c1a:	0000                	.insn	2, 0x0000
     c1c:	181e                	.insn	2, 0x181e
     c1e:	4b02                	.insn	2, 0x4b02
     c20:	a002                	.insn	2, 0xa002
     c22:	0004                	.insn	2, 0x0004
     c24:	1f00                	.insn	2, 0x1f00
     c26:	0219                	.insn	2, 0x0219
     c28:	02b5024b          	.insn	4, 0x02b5024b
     c2c:	0000                	.insn	2, 0x0000
     c2e:	141f 4c02 b502      	.insn	6, 0xb5024c02141f
     c34:	0002                	.insn	2, 0x0002
     c36:	1f00                	.insn	2, 0x1f00
     c38:	0215                	.insn	2, 0x0215
     c3a:	024d                	.insn	2, 0x024d
     c3c:	02b5                	.insn	2, 0x02b5
     c3e:	0000                	.insn	2, 0x0000
     c40:	161f 4e02 b502      	.insn	6, 0xb5024e02161f
     c46:	0002                	.insn	2, 0x0002
     c48:	1f00                	.insn	2, 0x1f00
     c4a:	021a                	.insn	2, 0x021a
     c4c:	02b5024f          	.insn	4, 0x02b5024f
     c50:	0000                	.insn	2, 0x0000
     c52:	1b20                	.insn	2, 0x1b20
     c54:	5102                	.insn	2, 0x5102
     c56:	b502                	.insn	2, 0xb502
     c58:	0002                	.insn	2, 0x0002
     c5a:	0000                	.insn	2, 0x0000
     c5c:	0002bd13          	sltiu	s10,t0,0
     c60:	0a00                	.insn	2, 0x0a00
     c62:	1c211103          	lh	sp,450(sp)
     c66:	1302                	.insn	2, 0x1302
     c68:	1f02                	.insn	2, 0x1f02
     c6a:	021d                	.insn	2, 0x021d
     c6c:	02d70213          	addi	tp,a4,45
     c70:	0000                	.insn	2, 0x0000
     c72:	2100                	.insn	2, 0x2100
     c74:	021e                	.insn	2, 0x021e
     c76:	1f1f023b          	.insn	4, 0x1f1f023b
     c7a:	3b02                	.insn	2, 0x3b02
     c7c:	ba02                	.insn	2, 0xba02
     c7e:	00000003          	lb	zero,0(zero) # 0 <start-0x400000>
     c82:	2922                	.insn	2, 0x2922
     c84:	02b8                	.insn	2, 0x02b8
     c86:	0000                	.insn	2, 0x0000
     c88:	5201                	.insn	2, 0x5201
     c8a:	022a                	.insn	2, 0x022a
     c8c:	0d23016b          	.insn	4, 0x0d23016b
     c90:	0244                	.insn	2, 0x0244
     c92:	0761016b          	.insn	4, 0x0761016b
     c96:	0000                	.insn	2, 0x0000
     c98:	0224                	.insn	2, 0x0224
     c9a:	0c91                	.insn	2, 0x0c91
     c9c:	0241                	.insn	2, 0x0241
     c9e:	016c                	.insn	2, 0x016c
     ca0:	00000ba7          	.insn	4, 0x0ba7
     ca4:	4925                	.insn	2, 0x4925
     ca6:	b102                	.insn	2, 0xb102
     ca8:	0101                	.insn	2, 0x0101
     caa:	0750                	.insn	2, 0x0750
     cac:	2401                	.insn	2, 0x2401
     cae:	9102                	.insn	2, 0x9102
     cb0:	4301                	.insn	2, 0x4301
     cb2:	8e02                	.insn	2, 0x8e02
     cb4:	ae01                	.insn	2, 0xae01
     cb6:	2600000b          	.insn	4, 0x2600000b
     cba:	450e                	.insn	2, 0x450e
     cbc:	8202                	.insn	2, 0x8202
     cbe:	ba01                	.insn	2, 0xba01
     cc0:	26000003          	lb	zero,608(zero) # 260 <start-0x3ffda0>
     cc4:	8402460f          	.insn	4, 0x8402460f
     cc8:	bd01                	.insn	2, 0xbd01
     cca:	0002                	.insn	2, 0x0002
     ccc:	2600                	.insn	2, 0x2600
     cce:	3e10                	.insn	2, 0x3e10
     cd0:	8f02                	.insn	2, 0x8f02
     cd2:	ba01                	.insn	2, 0xba01
     cd4:	27000003          	lb	zero,624(zero) # 270 <start-0x3ffd90>
     cd8:	04a8                	.insn	2, 0x04a8
     cda:	0000                	.insn	2, 0x0000
     cdc:	0c2a                	.insn	2, 0x0c2a
     cde:	0000                	.insn	2, 0x0000
     ce0:	0200                	.insn	2, 0x0200
     ce2:	0186                	.insn	2, 0x0186
     ce4:	0a19                	.insn	2, 0x0a19
     ce6:	ad2d                	.insn	2, 0xad2d
     ce8:	0004                	.insn	2, 0x0004
     cea:	0000                	.insn	2, 0x0000
     cec:	0004a827          	.insn	4, 0x0004a827
     cf0:	2b00                	.insn	2, 0x2b00
     cf2:	000c                	.insn	2, 0x000c
     cf4:	0000                	.insn	2, 0x0000
     cf6:	9302                	.insn	2, 0x9302
     cf8:	1901                	.insn	2, 0x1901
     cfa:	300a                	.insn	2, 0x300a
     cfc:	04ad                	.insn	2, 0x04ad
     cfe:	0000                	.insn	2, 0x0000
     d00:	2800                	.insn	2, 0x2800
     d02:	04a8                	.insn	2, 0x04a8
     d04:	0000                	.insn	2, 0x0000
     d06:	0c2c                	.insn	2, 0x0c2c
     d08:	0000                	.insn	2, 0x0000
     d0a:	0200                	.insn	2, 0x0200
     d0c:	019e                	.insn	2, 0x019e
     d0e:	0019                	.insn	2, 0x0019
     d10:	2d05                	.insn	2, 0x2d05
     d12:	00e8                	.insn	2, 0x00e8
     d14:	0000                	.insn	2, 0x0000
     d16:	1126                	.insn	2, 0x1126
     d18:	0245                	.insn	2, 0x0245
     d1a:	02bd01a3          	sb	a1,35(s10) # 2f785 <start-0x3d087b>
     d1e:	0000                	.insn	2, 0x0000
     d20:	2e05                	.insn	2, 0x2e05
     d22:	00d8                	.insn	2, 0x00d8
     d24:	0000                	.insn	2, 0x0000
     d26:	1226                	.insn	2, 0x1226
     d28:	023e                	.insn	2, 0x023e
     d2a:	01a4                	.insn	2, 0x01a4
     d2c:	03ba                	.insn	2, 0x03ba
     d2e:	0000                	.insn	2, 0x0000
     d30:	2e05                	.insn	2, 0x2e05
     d32:	00d8                	.insn	2, 0x00d8
     d34:	0000                	.insn	2, 0x0000
     d36:	1326                	.insn	2, 0x1326
     d38:	01a50247          	.insn	4, 0x01a50247
     d3c:	02bd                	.insn	2, 0x02bd
     d3e:	0000                	.insn	2, 0x0000
     d40:	a829                	.insn	2, 0xa829
     d42:	0004                	.insn	2, 0x0004
     d44:	0200                	.insn	2, 0x0200
     d46:	a602                	.insn	2, 0xa602
     d48:	1901                	.insn	2, 0x1901
     d4a:	0000                	.insn	2, 0x0000
     d4c:	2700                	.insn	2, 0x2700
     d4e:	04a8                	.insn	2, 0x04a8
     d50:	0000                	.insn	2, 0x0000
     d52:	00000c2f          	.insn	4, 0x0c2f
     d56:	0200                	.insn	2, 0x0200
     d58:	0a150177          	.insn	4, 0x0a150177
     d5c:	ad25                	.insn	2, 0xad25
     d5e:	0004                	.insn	2, 0x0004
     d60:	0000                	.insn	2, 0x0000
     d62:	3005                	.insn	2, 0x3005
     d64:	0038                	.insn	2, 0x0038
     d66:	0000                	.insn	2, 0x0000
     d68:	1426                	.insn	2, 0x1426
     d6a:	0248                	.insn	2, 0x0248
     d6c:	017a                	.insn	2, 0x017a
     d6e:	0761                	.insn	2, 0x0761
     d70:	0000                	.insn	2, 0x0000
     d72:	0004a827          	.insn	4, 0x0004a827
     d76:	3100                	.insn	2, 0x3100
     d78:	000c                	.insn	2, 0x000c
     d7a:	0000                	.insn	2, 0x0000
     d7c:	7c02                	.insn	2, 0x7c02
     d7e:	1901                	.insn	2, 0x1901
     d80:	010c                	.insn	2, 0x010c
     d82:	ad58                	.insn	2, 0xad58
     d84:	0004                	.insn	2, 0x0004
     d86:	0000                	.insn	2, 0x0000
     d88:	2700                	.insn	2, 0x2700
     d8a:	04a8                	.insn	2, 0x04a8
     d8c:	0000                	.insn	2, 0x0000
     d8e:	0c32                	.insn	2, 0x0c32
     d90:	0000                	.insn	2, 0x0000
     d92:	0200                	.insn	2, 0x0200
     d94:	0174                	.insn	2, 0x0174
     d96:	0a15                	.insn	2, 0x0a15
     d98:	ad25                	.insn	2, 0xad25
     d9a:	0004                	.insn	2, 0x0004
     d9c:	0000                	.insn	2, 0x0000
     d9e:	0004a827          	.insn	4, 0x0004a827
     da2:	3300                	.insn	2, 0x3300
     da4:	000c                	.insn	2, 0x000c
     da6:	0000                	.insn	2, 0x0000
     da8:	ab02                	.insn	2, 0xab02
     daa:	0d01                	.insn	2, 0x0d01
     dac:	010c                	.insn	2, 0x010c
     dae:	ad58                	.insn	2, 0xad58
     db0:	0004                	.insn	2, 0x0004
     db2:	0000                	.insn	2, 0x0000
     db4:	002a                	.insn	2, 0x002a
     db6:	0014342b          	.insn	4, 0x0014342b
     dba:	0000                	.insn	2, 0x0000
     dbc:	5201                	.insn	2, 0x5201
     dbe:	04a8                	.insn	2, 0x04a8
     dc0:	0000                	.insn	2, 0x0000
     dc2:	04ad150b          	.insn	4, 0x04ad150b
     dc6:	0000                	.insn	2, 0x0000
     dc8:	2b00                	.insn	2, 0x2b00
     dca:	1435                	.insn	2, 0x1435
     dcc:	0000                	.insn	2, 0x0000
     dce:	0100                	.insn	2, 0x0100
     dd0:	b752                	.insn	2, 0xb752
     dd2:	0004                	.insn	2, 0x0004
     dd4:	0b00                	.insn	2, 0x0b00
     dd6:	bc16                	.insn	2, 0xbc16
     dd8:	0004                	.insn	2, 0x0004
     dda:	0000                	.insn	2, 0x0000
     ddc:	201e                	.insn	2, 0x201e
     dde:	6202                	.insn	2, 0x6202
     de0:	a002                	.insn	2, 0xa002
     de2:	0004                	.insn	2, 0x0004
     de4:	1f00                	.insn	2, 0x1f00
     de6:	0210                	.insn	2, 0x0210
     de8:	0262                	.insn	2, 0x0262
     dea:	02b5                	.insn	2, 0x02b5
     dec:	0000                	.insn	2, 0x0000
     dee:	111f 6202 b502      	.insn	6, 0xb5026202111f
     df4:	0002                	.insn	2, 0x0002
     df6:	2000                	.insn	2, 0x2000
     df8:	0214                	.insn	2, 0x0214
     dfa:	0264                	.insn	2, 0x0264
     dfc:	02b5                	.insn	2, 0x02b5
     dfe:	0000                	.insn	2, 0x0000
     e00:	1720                	.insn	2, 0x1720
     e02:	6502                	.insn	2, 0x6502
     e04:	b502                	.insn	2, 0xb502
     e06:	0002                	.insn	2, 0x0002
     e08:	0000                	.insn	2, 0x0000
     e0a:	3602                	.insn	2, 0x3602
     e0c:	000c                	.insn	2, 0x000c
     e0e:	0000                	.insn	2, 0x0000
     e10:	5201                	.insn	2, 0x5201
     e12:	04bf022b          	.insn	4, 0x04bf022b
     e16:	bf024a17          	auipc	s4,0xbf024
     e1a:	02bd                	.insn	2, 0x02bd
     e1c:	0000                	.insn	2, 0x0000
     e1e:	2009                	.insn	2, 0x2009
     e20:	0006                	.insn	2, 0x0006
     e22:	3600                	.insn	2, 0x3600
     e24:	0008                	.insn	2, 0x0008
     e26:	0000                	.insn	2, 0x0000
     e28:	c202                	.insn	2, 0xc202
     e2a:	0a05                	.insn	2, 0x0a05
     e2c:	2914                	.insn	2, 0x2914
     e2e:	0006                	.insn	2, 0x0006
     e30:	0c00                	.insn	2, 0x0c00
     e32:	5a01                	.insn	2, 0x5a01
     e34:	0632                	.insn	2, 0x0632
     e36:	0000                	.insn	2, 0x0000
     e38:	012c                	.insn	2, 0x012c
     e3a:	3b5a                	.insn	2, 0x3b5a
     e3c:	0006                	.insn	2, 0x0006
     e3e:	2d00                	.insn	2, 0x2d00
     e40:	4414                	.insn	2, 0x4414
     e42:	0006                	.insn	2, 0x0006
     e44:	0000                	.insn	2, 0x0000
     e46:	1800                	.insn	2, 0x1800
     e48:	0221                	.insn	2, 0x0221
     e4a:	b5c9                	.insn	2, 0xb5c9
     e4c:	0002                	.insn	2, 0x0002
     e4e:	1900                	.insn	2, 0x1900
     e50:	0210                	.insn	2, 0x0210
     e52:	b5ca                	.insn	2, 0xb5ca
     e54:	0002                	.insn	2, 0x0002
     e56:	1900                	.insn	2, 0x1900
     e58:	0211                	.insn	2, 0x0211
     e5a:	0002b5cb          	.insn	4, 0x0002b5cb
     e5e:	1900                	.insn	2, 0x1900
     e60:	0212                	.insn	2, 0x0212
     e62:	b5cc                	.insn	2, 0xb5cc
     e64:	0002                	.insn	2, 0x0002
     e66:	0800                	.insn	2, 0x0800
     e68:	0215                	.insn	2, 0x0215
     e6a:	0002b5cf          	.insn	4, 0x0002b5cf
     e6e:	0800                	.insn	2, 0x0800
     e70:	0214                	.insn	2, 0x0214
     e72:	b5ce                	.insn	2, 0xb5ce
     e74:	0002                	.insn	2, 0x0002
     e76:	0800                	.insn	2, 0x0800
     e78:	b5d00217          	auipc	tp,0xb5d00
     e7c:	0002                	.insn	2, 0x0002
     e7e:	0000                	.insn	2, 0x0000
     e80:	372e                	.insn	2, 0x372e
     e82:	00ac                	.insn	2, 0x00ac
     e84:	0000                	.insn	2, 0x0000
     e86:	5201                	.insn	2, 0x5201
     e88:	022c                	.insn	2, 0x022c
     e8a:	a0de                	.insn	2, 0xa0de
     e8c:	0004                	.insn	2, 0x0004
     e8e:	0400                	.insn	2, 0x0400
     e90:	4a18                	.insn	2, 0x4a18
     e92:	df02                	.insn	2, 0xdf02
     e94:	02b5                	.insn	2, 0x02b5
     e96:	0000                	.insn	2, 0x0000
     e98:	1091022f          	.insn	4, 0x1091022f
     e9c:	b5e1024b          	.insn	4, 0xb5e1024b
     ea0:	0002                	.insn	2, 0x0002
     ea2:	2f00                	.insn	2, 0x2f00
     ea4:	9102                	.insn	2, 0x9102
     ea6:	4c0c                	.insn	2, 0x4c0c
     ea8:	e202                	.insn	2, 0xe202
     eaa:	02b5                	.insn	2, 0x02b5
     eac:	0000                	.insn	2, 0x0000
     eae:	1906                	.insn	2, 0x1906
     eb0:	024d                	.insn	2, 0x024d
     eb2:	b5f2                	.insn	2, 0xb5f2
     eb4:	0002                	.insn	2, 0x0002
     eb6:	0900                	.insn	2, 0x0900
     eb8:	0000068b          	.insn	4, 0x068b
     ebc:	1438                	.insn	2, 0x1438
     ebe:	0000                	.insn	2, 0x0000
     ec0:	0200                	.insn	2, 0x0200
     ec2:	0cfc                	.insn	2, 0x0cfc
     ec4:	150a                	.insn	2, 0x150a
     ec6:	00000693          	li	a3,0
     eca:	010c                	.insn	2, 0x010c
     ecc:	9b58                	.insn	2, 0x9b58
     ece:	0006                	.insn	2, 0x0006
     ed0:	0c00                	.insn	2, 0x0c00
     ed2:	5901                	.insn	2, 0x5901
     ed4:	000006a3          	sb	zero,13(zero) # d <start-0x3ffff3>
     ed8:	012c                	.insn	2, 0x012c
     eda:	ab59                	.insn	2, 0xab59
     edc:	0006                	.insn	2, 0x0006
     ede:	1c00                	.insn	2, 0x1c00
     ee0:	b31a                	.insn	2, 0xb31a
     ee2:	0006                	.insn	2, 0x0006
     ee4:	2d00                	.insn	2, 0x2d00
     ee6:	bb15                	.insn	2, 0xbb15
     ee8:	0006                	.insn	2, 0x0006
     eea:	0000                	.insn	2, 0x0000
     eec:	4930                	.insn	2, 0x4930
     eee:	39000007          	.insn	4, 0x39000007
     ef2:	c630                	.insn	2, 0xc630
     ef4:	0004                	.insn	2, 0x0004
     ef6:	3a00                	.insn	2, 0x3a00
     ef8:	7830                	.insn	2, 0x7830
     efa:	3b000007          	.insn	4, 0x3b000007
     efe:	c630                	.insn	2, 0xc630
     f00:	0004                	.insn	2, 0x0004
     f02:	3800                	.insn	2, 0x3800
     f04:	3100                	.insn	2, 0x3100
     f06:	0422                	.insn	2, 0x0422
     f08:	0003ba0f          	.insn	4, 0x0003ba0f
     f0c:	3200                	.insn	2, 0x3200
     f0e:	0761                	.insn	2, 0x0761
     f10:	0000                	.insn	2, 0x0000
     f12:	6b32                	.insn	2, 0x6b32
     f14:	32000007          	.insn	4, 0x32000007
     f18:	0000076b          	.insn	4, 0x076b
     f1c:	1700                	.insn	2, 0x1700
     f1e:	0766                	.insn	2, 0x0766
     f20:	0000                	.insn	2, 0x0000
     f22:	0002d733          	srl	a4,t0,zero
     f26:	1700                	.insn	2, 0x1700
     f28:	0770                	.insn	2, 0x0770
     f2a:	0000                	.insn	2, 0x0000
     f2c:	0002bd13          	sltiu	s10,t0,0
     f30:	0a00                	.insn	2, 0x0a00
     f32:	1e05                	.insn	2, 0x1e05
     f34:	2331                	.insn	2, 0x2331
     f36:	04a02503          	lw	a0,74(zero) # 4a <start-0x3fffb6>
     f3a:	0000                	.insn	2, 0x0000
     f3c:	a032                	.insn	2, 0xa032
     f3e:	0004                	.insn	2, 0x0004
     f40:	0000                	.insn	2, 0x0000
     f42:	3c22                	.insn	2, 0x3c22
     f44:	000c                	.insn	2, 0x000c
     f46:	0000                	.insn	2, 0x0000
     f48:	5201                	.insn	2, 0x5201
     f4a:	022d                	.insn	2, 0x022d
     f4c:	0105                	.insn	2, 0x0105
     f4e:	024a1b23          	sh	tp,54(s4) # bf024e4c <USER_MAX+0xbeb24e4c>
     f52:	0105                	.insn	2, 0x0105
     f54:	02bd                	.insn	2, 0x02bd
     f56:	0000                	.insn	2, 0x0000
     f58:	00062027          	.insn	4, 0x00062027
     f5c:	3c00                	.insn	2, 0x3c00
     f5e:	0008                	.insn	2, 0x0008
     f60:	0000                	.insn	2, 0x0000
     f62:	0802                	.insn	2, 0x0802
     f64:	0501                	.insn	2, 0x0501
     f66:	150a                	.insn	2, 0x150a
     f68:	0629                	.insn	2, 0x0629
     f6a:	0000                	.insn	2, 0x0000
     f6c:	010c                	.insn	2, 0x010c
     f6e:	325a                	.insn	2, 0x325a
     f70:	0006                	.insn	2, 0x0006
     f72:	2c00                	.insn	2, 0x2c00
     f74:	5a01                	.insn	2, 0x5a01
     f76:	0000063b          	.insn	4, 0x063b
     f7a:	152d                	.insn	2, 0x152d
     f7c:	0644                	.insn	2, 0x0644
     f7e:	0000                	.insn	2, 0x0000
     f80:	0000                	.insn	2, 0x0000
     f82:	241e                	.insn	2, 0x241e
     f84:	7202                	.insn	2, 0x7202
     f86:	a002                	.insn	2, 0xa002
     f88:	0004                	.insn	2, 0x0004
     f8a:	1f00                	.insn	2, 0x1f00
     f8c:	0210                	.insn	2, 0x0210
     f8e:	0272                	.insn	2, 0x0272
     f90:	02b5                	.insn	2, 0x02b5
     f92:	0000                	.insn	2, 0x0000
     f94:	111f 7202 b502      	.insn	6, 0xb5027202111f
     f9a:	0002                	.insn	2, 0x0002
     f9c:	2000                	.insn	2, 0x2000
     f9e:	0214                	.insn	2, 0x0214
     fa0:	0274                	.insn	2, 0x0274
     fa2:	02b5                	.insn	2, 0x02b5
     fa4:	0000                	.insn	2, 0x0000
     fa6:	1720                	.insn	2, 0x1720
     fa8:	7502                	.insn	2, 0x7502
     faa:	b502                	.insn	2, 0xb502
     fac:	0002                	.insn	2, 0x0002
     fae:	0000                	.insn	2, 0x0000
     fb0:	3d22                	.insn	2, 0x3d22
     fb2:	000c                	.insn	2, 0x000c
     fb4:	0000                	.insn	2, 0x0000
     fb6:	5201                	.insn	2, 0x5201
     fb8:	022e                	.insn	2, 0x022e
     fba:	0110                	.insn	2, 0x0110
     fbc:	024e1c23          	sh	tp,56(t3)
     fc0:	0110                	.insn	2, 0x0110
     fc2:	02bd                	.insn	2, 0x02bd
     fc4:	0000                	.insn	2, 0x0000
     fc6:	0007c627          	.insn	4, 0x0007c627
     fca:	3d00                	.insn	2, 0x3d00
     fcc:	0008                	.insn	2, 0x0008
     fce:	0000                	.insn	2, 0x0000
     fd0:	1302                	.insn	2, 0x1302
     fd2:	0501                	.insn	2, 0x0501
     fd4:	1e0a                	.insn	2, 0x1e0a
     fd6:	000007cf          	.insn	4, 0x07cf
     fda:	010c                	.insn	2, 0x010c
     fdc:	d85a                	.insn	2, 0xd85a
     fde:	2c000007          	.insn	4, 0x2c000007
     fe2:	5a01                	.insn	2, 0x5a01
     fe4:	07e1                	.insn	2, 0x07e1
     fe6:	0000                	.insn	2, 0x0000
     fe8:	1e2d                	.insn	2, 0x1e2d
     fea:	07ea                	.insn	2, 0x07ea
     fec:	0000                	.insn	2, 0x0000
     fee:	0000                	.insn	2, 0x0000
     ff0:	3e22                	.insn	2, 0x3e22
     ff2:	000c                	.insn	2, 0x000c
     ff4:	0000                	.insn	2, 0x0000
     ff6:	5201                	.insn	2, 0x5201
     ff8:	011b022f          	.insn	4, 0x011b022f
     ffc:	024e1d23          	sh	tp,58(t3)
    1000:	02bd011b          	.insn	4, 0x02bd011b
    1004:	0000                	.insn	2, 0x0000
    1006:	0007c627          	.insn	4, 0x0007c627
    100a:	3e00                	.insn	2, 0x3e00
    100c:	0008                	.insn	2, 0x0008
    100e:	0000                	.insn	2, 0x0000
    1010:	1e02                	.insn	2, 0x1e02
    1012:	0501                	.insn	2, 0x0501
    1014:	1f0a                	.insn	2, 0x1f0a
    1016:	000007cf          	.insn	4, 0x07cf
    101a:	010c                	.insn	2, 0x010c
    101c:	d85a                	.insn	2, 0xd85a
    101e:	2c000007          	.insn	4, 0x2c000007
    1022:	5a01                	.insn	2, 0x5a01
    1024:	07e1                	.insn	2, 0x07e1
    1026:	0000                	.insn	2, 0x0000
    1028:	1f2d                	.insn	2, 0x1f2d
    102a:	07ea                	.insn	2, 0x07ea
    102c:	0000                	.insn	2, 0x0000
    102e:	0000                	.insn	2, 0x0000
    1030:	251e                	.insn	2, 0x251e
    1032:	8202                	.insn	2, 0x8202
    1034:	a002                	.insn	2, 0xa002
    1036:	0004                	.insn	2, 0x0004
    1038:	1f00                	.insn	2, 0x1f00
    103a:	0210                	.insn	2, 0x0210
    103c:	02b50283          	lb	t0,43(a0)
    1040:	0000                	.insn	2, 0x0000
    1042:	111f 8402 b502      	.insn	6, 0xb5028402111f
    1048:	0002                	.insn	2, 0x0002
    104a:	1f00                	.insn	2, 0x1f00
    104c:	0212                	.insn	2, 0x0212
    104e:	0285                	.insn	2, 0x0285
    1050:	02b5                	.insn	2, 0x02b5
    1052:	0000                	.insn	2, 0x0000
    1054:	1420                	.insn	2, 0x1420
    1056:	8702                	.insn	2, 0x8702
    1058:	b502                	.insn	2, 0xb502
    105a:	0002                	.insn	2, 0x0002
    105c:	2000                	.insn	2, 0x2000
    105e:	0215                	.insn	2, 0x0215
    1060:	0288                	.insn	2, 0x0288
    1062:	02b5                	.insn	2, 0x02b5
    1064:	0000                	.insn	2, 0x0000
    1066:	1720                	.insn	2, 0x1720
    1068:	8902                	.insn	2, 0x8902
    106a:	b502                	.insn	2, 0xb502
    106c:	0002                	.insn	2, 0x0002
    106e:	0000                	.insn	2, 0x0000
    1070:	3f34                	.insn	2, 0x3f34
    1072:	000c                	.insn	2, 0x000c
    1074:	0000                	.insn	2, 0x0000
    1076:	5201                	.insn	2, 0x5201
    1078:	0230                	.insn	2, 0x0230
    107a:	0125                	.insn	2, 0x0125
    107c:	04a0                	.insn	2, 0x04a0
    107e:	0000                	.insn	2, 0x0000
    1080:	024e1e23          	sh	tp,60(t3)
    1084:	0126                	.insn	2, 0x0126
    1086:	02b5                	.insn	2, 0x02b5
    1088:	0000                	.insn	2, 0x0000
    108a:	0135                	.insn	2, 0x0135
    108c:	2702435b          	.insn	4, 0x2702435b
    1090:	ba01                	.insn	2, 0xba01
    1092:	2700000b          	.insn	4, 0x2700000b
    1096:	0874                	.insn	2, 0x0874
    1098:	0000                	.insn	2, 0x0000
    109a:	0000083f 01290200 	.insn	8, 0x012902000000083f
    10a2:	0a0c                	.insn	2, 0x0a0c
    10a4:	7d20                	.insn	2, 0x7d20
    10a6:	0008                	.insn	2, 0x0008
    10a8:	0c00                	.insn	2, 0x0c00
    10aa:	5a01                	.insn	2, 0x5a01
    10ac:	0886                	.insn	2, 0x0886
    10ae:	0000                	.insn	2, 0x0000
    10b0:	010c                	.insn	2, 0x010c
    10b2:	00088f5b          	.insn	4, 0x00088f5b
    10b6:	2c00                	.insn	2, 0x2c00
    10b8:	5a01                	.insn	2, 0x5a01
    10ba:	0898                	.insn	2, 0x0898
    10bc:	0000                	.insn	2, 0x0000
    10be:	012c                	.insn	2, 0x012c
    10c0:	0008a15b          	.insn	4, 0x0008a15b
    10c4:	2d00                	.insn	2, 0x2d00
    10c6:	aa20                	.insn	2, 0xaa20
    10c8:	0008                	.insn	2, 0x0008
    10ca:	0000                	.insn	2, 0x0000
    10cc:	3600                	.insn	2, 0x3600
    10ce:	0226                	.insn	2, 0x0226
    10d0:	02ba                	.insn	2, 0x02ba
    10d2:	03ba                	.insn	2, 0x03ba
    10d4:	0000                	.insn	2, 0x0000
    10d6:	1420                	.insn	2, 0x1420
    10d8:	bc02                	.insn	2, 0xbc02
    10da:	b502                	.insn	2, 0xb502
    10dc:	0002                	.insn	2, 0x0002
    10de:	2000                	.insn	2, 0x2000
    10e0:	02bd0217          	auipc	tp,0x2bd0
    10e4:	02b5                	.insn	2, 0x02b5
    10e6:	0000                	.insn	2, 0x0000
    10e8:	2200                	.insn	2, 0x2200
    10ea:	8440                	.insn	2, 0x8440
    10ec:	0000                	.insn	2, 0x0000
    10ee:	0100                	.insn	2, 0x0100
    10f0:	3152                	.insn	2, 0x3152
    10f2:	3102                	.insn	2, 0x3102
    10f4:	2601                	.insn	2, 0x2601
    10f6:	4f20                	.insn	2, 0x4f20
    10f8:	3502                	.insn	2, 0x3502
    10fa:	ba01                	.insn	2, 0xba01
    10fc:	27000003          	lb	zero,624(zero) # 270 <start-0x3ffd90>
    1100:	0911                	.insn	2, 0x0911
    1102:	0000                	.insn	2, 0x0000
    1104:	1041                	.insn	2, 0x1041
    1106:	0000                	.insn	2, 0x0000
    1108:	0200                	.insn	2, 0x0200
    110a:	0136                	.insn	2, 0x0136
    110c:	1c09                	.insn	2, 0x1c09
    110e:	1a1f 0009 2d00      	.insn	6, 0x2d0000091a1f
    1114:	233c                	.insn	2, 0x233c
    1116:	0009                	.insn	2, 0x0009
    1118:	0000                	.insn	2, 0x0000
    111a:	c630                	.insn	2, 0xc630
    111c:	0004                	.insn	2, 0x0004
    111e:	4100                	.insn	2, 0x4100
    1120:	c60d                	.insn	2, 0xc60d
    1122:	0004                	.insn	2, 0x0004
    1124:	4200                	.insn	2, 0x4200
    1126:	c60d                	.insn	2, 0xc60d
    1128:	0004                	.insn	2, 0x0004
    112a:	4300                	.insn	2, 0x4300
    112c:	2b00                	.insn	2, 0x2b00
    112e:	1044                	.insn	2, 0x1044
    1130:	0000                	.insn	2, 0x0000
    1132:	0100                	.insn	2, 0x0100
    1134:	1152                	.insn	2, 0x1152
    1136:	0009                	.insn	2, 0x0009
    1138:	1c00                	.insn	2, 0x1c00
    113a:	1a21                	.insn	2, 0x1a21
    113c:	0009                	.insn	2, 0x0009
    113e:	2d00                	.insn	2, 0x2d00
    1140:	233c                	.insn	2, 0x233c
    1142:	0009                	.insn	2, 0x0009
    1144:	0000                	.insn	2, 0x0000
    1146:	a8022737          	lui	a4,0xa8022
    114a:	1f02                	.insn	2, 0x1f02
    114c:	0210                	.insn	2, 0x0210
    114e:	02a8                	.insn	2, 0x02a8
    1150:	02b5                	.insn	2, 0x02b5
    1152:	0000                	.insn	2, 0x0000
    1154:	111f a902 b502      	.insn	6, 0xb502a902111f
    115a:	0002                	.insn	2, 0x0002
    115c:	1f00                	.insn	2, 0x1f00
    115e:	0212                	.insn	2, 0x0212
    1160:	02aa                	.insn	2, 0x02aa
    1162:	02b5                	.insn	2, 0x02b5
    1164:	0000                	.insn	2, 0x0000
    1166:	1420                	.insn	2, 0x1420
    1168:	ac02                	.insn	2, 0xac02
    116a:	b502                	.insn	2, 0xb502
    116c:	0002                	.insn	2, 0x0002
    116e:	2000                	.insn	2, 0x2000
    1170:	0215                	.insn	2, 0x0215
    1172:	02ad                	.insn	2, 0x02ad
    1174:	02b5                	.insn	2, 0x02b5
    1176:	0000                	.insn	2, 0x0000
    1178:	1720                	.insn	2, 0x1720
    117a:	ae02                	.insn	2, 0xae02
    117c:	b502                	.insn	2, 0xb502
    117e:	0002                	.insn	2, 0x0002
    1180:	0000                	.insn	2, 0x0000
    1182:	4522                	.insn	2, 0x4522
    1184:	000c                	.insn	2, 0x000c
    1186:	0000                	.insn	2, 0x0000
    1188:	5201                	.insn	2, 0x5201
    118a:	0232                	.insn	2, 0x0232
    118c:	014d                	.insn	2, 0x014d
    118e:	0135                	.insn	2, 0x0135
    1190:	505a                	.insn	2, 0x505a
    1192:	4d02                	.insn	2, 0x4d02
    1194:	b501                	.insn	2, 0xb501
    1196:	0002                	.insn	2, 0x0002
    1198:	3500                	.insn	2, 0x3500
    119a:	5b01                	.insn	2, 0x5b01
    119c:	0251                	.insn	2, 0x0251
    119e:	014d                	.insn	2, 0x014d
    11a0:	02b5                	.insn	2, 0x02b5
    11a2:	0000                	.insn	2, 0x0000
    11a4:	00098a27          	.insn	4, 0x00098a27
    11a8:	4500                	.insn	2, 0x4500
    11aa:	0008                	.insn	2, 0x0008
    11ac:	0000                	.insn	2, 0x0000
    11ae:	5002                	.insn	2, 0x5002
    11b0:	0501                	.insn	2, 0x0501
    11b2:	280a                	.insn	2, 0x280a
    11b4:	0000098f          	.insn	4, 0x098f
    11b8:	010c                	.insn	2, 0x010c
    11ba:	985a                	.insn	2, 0x985a
    11bc:	0009                	.insn	2, 0x0009
    11be:	0c00                	.insn	2, 0x0c00
    11c0:	5b01                	.insn	2, 0x5b01
    11c2:	09a1                	.insn	2, 0x09a1
    11c4:	0000                	.insn	2, 0x0000
    11c6:	012c                	.insn	2, 0x012c
    11c8:	aa5a                	.insn	2, 0xaa5a
    11ca:	0009                	.insn	2, 0x0009
    11cc:	2c00                	.insn	2, 0x2c00
    11ce:	5b01                	.insn	2, 0x5b01
    11d0:	000009b3          	add	s3,zero,zero
    11d4:	282d                	.insn	2, 0x282d
    11d6:	09bc                	.insn	2, 0x09bc
    11d8:	0000                	.insn	2, 0x0000
    11da:	0000                	.insn	2, 0x0000
    11dc:	4634                	.insn	2, 0x4634
    11de:	0034                	.insn	2, 0x0034
    11e0:	0000                	.insn	2, 0x0000
    11e2:	5201                	.insn	2, 0x5201
    11e4:	01580233          	add	tp,a6,s5
    11e8:	0b95                	.insn	2, 0x0b95
    11ea:	0000                	.insn	2, 0x0000
    11ec:	0135                	.insn	2, 0x0135
    11ee:	525a                	.insn	2, 0x525a
    11f0:	5802                	.insn	2, 0x5802
    11f2:	9501                	.insn	2, 0x9501
    11f4:	2300000b          	.insn	4, 0x2300000b
    11f8:	5322                	.insn	2, 0x5322
    11fa:	5802                	.insn	2, 0x5802
    11fc:	6101                	.insn	2, 0x6101
    11fe:	26000007          	.insn	4, 0x26000007
    1202:	59025423          	.insn	4, 0x59025423
    1206:	9501                	.insn	2, 0x9501
    1208:	0000000b          	.insn	4, 0x000b
    120c:	4734                	.insn	2, 0x4734
    120e:	0030                	.insn	2, 0x0030
    1210:	0000                	.insn	2, 0x0000
    1212:	5201                	.insn	2, 0x5201
    1214:	0234                	.insn	2, 0x0234
    1216:	0160                	.insn	2, 0x0160
    1218:	03ba                	.insn	2, 0x03ba
    121a:	0000                	.insn	2, 0x0000
    121c:	02552423          	sw	t0,40(a0)
    1220:	0160                	.insn	2, 0x0160
    1222:	0761                	.insn	2, 0x0761
    1224:	0000                	.insn	2, 0x0000
    1226:	0135                	.insn	2, 0x0135
    1228:	6002565b          	.insn	4, 0x6002565b
    122c:	6101                	.insn	2, 0x6101
    122e:	00000007          	.insn	4, 0x0007
    1232:	4834                	.insn	2, 0x4834
    1234:	00bc                	.insn	2, 0x00bc
    1236:	0000                	.insn	2, 0x0000
    1238:	5201                	.insn	2, 0x5201
    123a:	0235                	.insn	2, 0x0235
    123c:	01b9                	.insn	2, 0x01b9
    123e:	02bd                	.insn	2, 0x02bd
    1240:	0000                	.insn	2, 0x0000
    1242:	02482523          	sw	tp,42(a6)
    1246:	01b9                	.insn	2, 0x01b9
    1248:	0761                	.insn	2, 0x0761
    124a:	0000                	.insn	2, 0x0000
    124c:	2626                	.insn	2, 0x2626
    124e:	01ba0257          	.insn	4, 0x01ba0257
    1252:	02bd                	.insn	2, 0x02bd
    1254:	0000                	.insn	2, 0x0000
    1256:	2726                	.insn	2, 0x2726
    1258:	021f 01bf 02bd      	.insn	6, 0x02bd01bf021f
    125e:	0000                	.insn	2, 0x0000
    1260:	28260307          	.insn	4, 0x28260307
    1264:	0258                	.insn	2, 0x0258
    1266:	01c1                	.insn	2, 0x01c1
    1268:	000002d7          	.insn	4, 0x02d7
    126c:	2926                	.insn	2, 0x2926
    126e:	0254                	.insn	2, 0x0254
    1270:	01c2                	.insn	2, 0x01c2
    1272:	02bd                	.insn	2, 0x02bd
    1274:	0000                	.insn	2, 0x0000
    1276:	0000                	.insn	2, 0x0000
    1278:	4934                	.insn	2, 0x4934
    127a:	003c                	.insn	2, 0x003c
    127c:	0000                	.insn	2, 0x0000
    127e:	5201                	.insn	2, 0x5201
    1280:	0236                	.insn	2, 0x0236
    1282:	01ce                	.insn	2, 0x01ce
    1284:	0b9a                	.insn	2, 0x0b9a
    1286:	0000                	.insn	2, 0x0000
    1288:	02192a23          	sw	ra,52(s2)
    128c:	01ce                	.insn	2, 0x01ce
    128e:	02bd                	.insn	2, 0x02bd
    1290:	0000                	.insn	2, 0x0000
    1292:	4a05                	.insn	2, 0x4a05
    1294:	001c                	.insn	2, 0x001c
    1296:	0000                	.insn	2, 0x0000
    1298:	2b26                	.insn	2, 0x2b26
    129a:	023e                	.insn	2, 0x023e
    129c:	01d2                	.insn	2, 0x01d2
    129e:	02bd                	.insn	2, 0x02bd
    12a0:	0000                	.insn	2, 0x0000
    12a2:	0000                	.insn	2, 0x0000
    12a4:	4b34                	.insn	2, 0x4b34
    12a6:	0014                	.insn	2, 0x0014
    12a8:	0000                	.insn	2, 0x0000
    12aa:	5201                	.insn	2, 0x5201
    12ac:	0238                	.insn	2, 0x0238
    12ae:	021f 03ba 0000      	.insn	6, 0x03ba021f
    12b4:	2c26                	.insn	2, 0x2c26
    12b6:	021d                	.insn	2, 0x021d
    12b8:	0221                	.insn	2, 0x0221
    12ba:	03ba                	.insn	2, 0x03ba
    12bc:	0000                	.insn	2, 0x0000
    12be:	3400                	.insn	2, 0x3400
    12c0:	144c                	.insn	2, 0x144c
    12c2:	0000                	.insn	2, 0x0000
    12c4:	0100                	.insn	2, 0x0100
    12c6:	3952                	.insn	2, 0x3952
    12c8:	2d02                	.insn	2, 0x2d02
    12ca:	ba02                	.insn	2, 0xba02
    12cc:	26000003          	lb	zero,608(zero) # 260 <start-0x3ffda0>
    12d0:	1d2d                	.insn	2, 0x1d2d
    12d2:	2f02                	.insn	2, 0x2f02
    12d4:	ba02                	.insn	2, 0xba02
    12d6:	00000003          	lb	zero,0(zero) # 0 <start-0x400000>
    12da:	4d34                	.insn	2, 0x4d34
    12dc:	000c                	.insn	2, 0x000c
    12de:	0000                	.insn	2, 0x0000
    12e0:	5201                	.insn	2, 0x5201
    12e2:	023a                	.insn	2, 0x023a
    12e4:	03ba0297          	auipc	t0,0x3ba0
    12e8:	0000                	.insn	2, 0x0000
    12ea:	024e2e23          	sw	tp,60(t3)
    12ee:	02b50297          	auipc	t0,0x2b50
    12f2:	0000                	.insn	2, 0x0000
    12f4:	0135                	.insn	2, 0x0135
    12f6:	9702435b          	.insn	4, 0x9702435b
    12fa:	ad02                	.insn	2, 0xad02
    12fc:	2400000b          	.insn	4, 0x2400000b
    1300:	5a01                	.insn	2, 0x5a01
    1302:	0214                	.insn	2, 0x0214
    1304:	0299                	.insn	2, 0x0299
    1306:	02b5                	.insn	2, 0x02b5
    1308:	0000                	.insn	2, 0x0000
    130a:	0124                	.insn	2, 0x0124
    130c:	9a02155b          	.insn	4, 0x9a02155b
    1310:	b502                	.insn	2, 0xb502
    1312:	0002                	.insn	2, 0x0002
    1314:	3800                	.insn	2, 0x3800
    1316:	1721                	.insn	2, 0x1721
    1318:	9b02                	.insn	2, 0x9b02
    131a:	b502                	.insn	2, 0xb502
    131c:	0002                	.insn	2, 0x0002
    131e:	0000                	.insn	2, 0x0000
    1320:	4e34                	.insn	2, 0x4e34
    1322:	000c                	.insn	2, 0x000c
    1324:	0000                	.insn	2, 0x0000
    1326:	5201                	.insn	2, 0x5201
    1328:	02cb023b          	.insn	4, 0x02cb023b
    132c:	04a0                	.insn	2, 0x04a0
    132e:	0000                	.insn	2, 0x0000
    1330:	3238                	.insn	2, 0x3238
    1332:	02ce0217          	auipc	tp,0x2ce0
    1336:	02b5                	.insn	2, 0x02b5
    1338:	0000                	.insn	2, 0x0000
    133a:	2f26                	.insn	2, 0x2f26
    133c:	0214                	.insn	2, 0x0214
    133e:	02cd                	.insn	2, 0x02cd
    1340:	02b5                	.insn	2, 0x02b5
    1342:	0000                	.insn	2, 0x0000
    1344:	3900                	.insn	2, 0x3900
    1346:	00001c4f          	.insn	4, 0x1c4f
    134a:	0100                	.insn	2, 0x0100
    134c:	3c52                	.insn	2, 0x3c52
    134e:	dd02                	.insn	2, 0xdd02
    1350:	1702                	.insn	2, 0x1702
    1352:	000002d7          	.insn	4, 0x02d7
    1356:	0003ba13          	sltiu	s4,t2,0
    135a:	3700                	.insn	2, 0x3700
    135c:	b5330e03          	lb	t3,-1197(t1)
    1360:	0002                	.insn	2, 0x0002
    1362:	3a00                	.insn	2, 0x3a00
    1364:	0bad                	.insn	2, 0x0bad
    1366:	0000                	.insn	2, 0x0000
    1368:	3b42                	.insn	2, 0x3b42
    136a:	d70e                	.insn	2, 0xd70e
    136c:	0002                	.insn	2, 0x0002
    136e:	1500                	.insn	2, 0x1500
    1370:	02a4                	.insn	2, 0x02a4
    1372:	0000                	.insn	2, 0x0000
    1374:	bf17000b          	.insn	4, 0xbf17000b
    1378:	3300000b          	.insn	4, 0x3300000b
    137c:	00000297          	auipc	t0,0x0
    1380:	6100                	.insn	2, 0x6100
    1382:	0005                	.insn	2, 0x0005
    1384:	0500                	.insn	2, 0x0500
    1386:	0100                	.insn	2, 0x0100
    1388:	3004                	.insn	2, 0x3004
    138a:	0005                	.insn	2, 0x0005
    138c:	0100                	.insn	2, 0x0100
    138e:	1d00                	.insn	2, 0x1d00
    1390:	0100                	.insn	2, 0x0100
    1392:	0260                	.insn	2, 0x0260
    1394:	0000                	.insn	2, 0x0000
    1396:	0d79                	.insn	2, 0x0d79
    1398:	0000                	.insn	2, 0x0000
    139a:	0702                	.insn	2, 0x0702
    139c:	0aa0                	.insn	2, 0x0aa0
    139e:	0000                	.insn	2, 0x0000
    13a0:	036c                	.insn	2, 0x036c
    13a2:	0000                	.insn	2, 0x0000
    13a4:	0145                	.insn	2, 0x0145
    13a6:	0000                	.insn	2, 0x0000
    13a8:	082a                	.insn	2, 0x082a
    13aa:	0000                	.insn	2, 0x0000
    13ac:	3502                	.insn	2, 0x3502
    13ae:	0000                	.insn	2, 0x0000
    13b0:	0100                	.insn	2, 0x0100
    13b2:	00a10213          	addi	tp,sp,10
    13b6:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
    13ba:	0400                	.insn	2, 0x0400
    13bc:	0045                	.insn	2, 0x0045
    13be:	0000                	.insn	2, 0x0000
    13c0:	0010                	.insn	2, 0x0010
    13c2:	0305                	.insn	2, 0x0305
    13c4:	0108                	.insn	2, 0x0108
    13c6:	0406                	.insn	2, 0x0406
    13c8:	0708                	.insn	2, 0x0708
    13ca:	5302                	.insn	2, 0x5302
    13cc:	0000                	.insn	2, 0x0000
    13ce:	0100                	.insn	2, 0x0100
    13d0:	01a102d7          	.insn	4, 0x01a102d7
    13d4:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
    13d8:	0400                	.insn	2, 0x0400
    13da:	0045                	.insn	2, 0x0045
    13dc:	0000                	.insn	2, 0x0000
    13de:	0009                	.insn	2, 0x0009
    13e0:	6902                	.insn	2, 0x6902
    13e2:	0000                	.insn	2, 0x0000
    13e4:	0100                	.insn	2, 0x0100
    13e6:	02f0                	.insn	2, 0x02f0
    13e8:	02a1                	.insn	2, 0x02a1
    13ea:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
    13ee:	0400                	.insn	2, 0x0400
    13f0:	0045                	.insn	2, 0x0045
    13f2:	0000                	.insn	2, 0x0000
    13f4:	80070017          	auipc	zero,0x80070
    13f8:	0000                	.insn	2, 0x0000
    13fa:	0100                	.insn	2, 0x0100
    13fc:	014c                	.insn	2, 0x014c
    13fe:	a102                	.insn	2, 0xa102
    1400:	00410303          	lb	t1,4(sp)
    1404:	0000                	.insn	2, 0x0000
    1406:	4504                	.insn	2, 0x4504
    1408:	0000                	.insn	2, 0x0000
    140a:	0b00                	.insn	2, 0x0b00
    140c:	0700                	.insn	2, 0x0700
    140e:	00000097          	auipc	ra,0x0
    1412:	5401                	.insn	2, 0x5401
    1414:	0201                	.insn	2, 0x0201
    1416:	04a1                	.insn	2, 0x04a1
    1418:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
    141c:	0400                	.insn	2, 0x0400
    141e:	0045                	.insn	2, 0x0045
    1420:	0000                	.insn	2, 0x0000
    1422:	0002                	.insn	2, 0x0002
    1424:	0000ae07          	.insn	4, 0xae07
    1428:	0100                	.insn	2, 0x0100
    142a:	0159                	.insn	2, 0x0159
    142c:	a102                	.insn	2, 0xa102
    142e:	0305                	.insn	2, 0x0305
    1430:	0041                	.insn	2, 0x0041
    1432:	0000                	.insn	2, 0x0000
    1434:	4504                	.insn	2, 0x4504
    1436:	0000                	.insn	2, 0x0000
    1438:	0d00                	.insn	2, 0x0d00
    143a:	0800                	.insn	2, 0x0800
    143c:	c705                	.insn	2, 0xc705
    143e:	0000                	.insn	2, 0x0000
    1440:	0100                	.insn	2, 0x0100
    1442:	0404                	.insn	2, 0x0404
    1444:	06a1                	.insn	2, 0x06a1
    1446:	d4031423          	sh	zero,-696(t1)
    144a:	0000                	.insn	2, 0x0000
    144c:	0900                	.insn	2, 0x0900
    144e:	0045                	.insn	2, 0x0045
    1450:	0000                	.insn	2, 0x0000
    1452:	0200                	.insn	2, 0x0200
    1454:	0a00                	.insn	2, 0x0a00
    1456:	00dc                	.insn	2, 0x00dc
    1458:	0000                	.insn	2, 0x0000
    145a:	050f0207          	.insn	4, 0x050f0207
    145e:	0806                	.insn	2, 0x0806
    1460:	0b01                	.insn	2, 0x0b01
    1462:	eb08                	.insn	2, 0xeb08
    1464:	0000                	.insn	2, 0x0000
    1466:	0100                	.insn	2, 0x0100
    1468:	0206                	.insn	2, 0x0206
    146a:	06a1                	.insn	2, 0x06a1
    146c:	f30a                	.insn	2, 0xf30a
    146e:	0000                	.insn	2, 0x0000
    1470:	1000                	.insn	2, 0x1000
    1472:	140c0c03          	lb	s8,320(s8) # a14 <start-0x3ff5ec>
    1476:	090d0603          	lb	a2,144(s10)
    147a:	0125                	.insn	2, 0x0125
    147c:	0000                	.insn	2, 0x0000
    147e:	0d000703          	lb	a4,208(zero) # d0 <start-0x3fff30>
    1482:	250c                	.insn	2, 0x250c
    1484:	0001                	.insn	2, 0x0001
    1486:	0300                	.insn	2, 0x0300
    1488:	0408                	.insn	2, 0x0408
    148a:	0d0d                	.insn	2, 0x0d0d
    148c:	0125                	.insn	2, 0x0125
    148e:	0000                	.insn	2, 0x0000
    1490:	0d080903          	lb	s2,208(a6)
    1494:	250e                	.insn	2, 0x250e
    1496:	0001                	.insn	2, 0x0001
    1498:	0300                	.insn	2, 0x0300
    149a:	0c0a                	.insn	2, 0x0c0a
    149c:	0f0d                	.insn	2, 0x0f0d
    149e:	0125                	.insn	2, 0x0125
    14a0:	0000                	.insn	2, 0x0000
    14a2:	00100b03          	lb	s6,1(zero) # 1 <start-0x3fffff>
    14a6:	2d0a                	.insn	2, 0x2d0a
    14a8:	0001                	.insn	2, 0x0001
    14aa:	0b00                	.insn	2, 0x0b00
    14ac:	1102                	.insn	2, 0x1102
    14ae:	0a05                	.insn	2, 0x0a05
    14b0:	110e0407          	.insn	4, 0x110e0407
    14b4:	7a01                	.insn	2, 0x7a01
    14b6:	0125                	.insn	2, 0x0125
    14b8:	0000                	.insn	2, 0x0000
    14ba:	7a01120f          	.insn	4, 0x7a01120f
    14be:	0125                	.insn	2, 0x0125
    14c0:	0000                	.insn	2, 0x0000
    14c2:	1000                	.insn	2, 0x1000
    14c4:	0000ec07          	.insn	4, 0xec07
    14c8:	0100                	.insn	2, 0x0100
    14ca:	1e52                	.insn	2, 0x1e52
    14cc:	0801                	.insn	2, 0x0801
    14ce:	02f5                	.insn	2, 0x02f5
    14d0:	0000                	.insn	2, 0x0000
    14d2:	0011                	.insn	2, 0x0011
    14d4:	0119                	.insn	2, 0x0119
    14d6:	d808                	.insn	2, 0xd808
    14d8:	0002                	.insn	2, 0x0002
    14da:	1200                	.insn	2, 0x1200
    14dc:	9102                	.insn	2, 0x9102
    14de:	2314                	.insn	2, 0x2314
    14e0:	0a01                	.insn	2, 0x0a01
    14e2:	000000c7          	.insn	4, 0x00c7
    14e6:	0212                	.insn	2, 0x0212
    14e8:	1091                	.insn	2, 0x1091
    14ea:	0112                	.insn	2, 0x0112
    14ec:	250c                	.insn	2, 0x250c
    14ee:	0001                	.insn	2, 0x0001
    14f0:	1200                	.insn	2, 0x1200
    14f2:	9102                	.insn	2, 0x9102
    14f4:	240c                	.insn	2, 0x240c
    14f6:	0d01                	.insn	2, 0x0d01
    14f8:	0125                	.insn	2, 0x0125
    14fa:	0000                	.insn	2, 0x0000
    14fc:	01250213          	addi	tp,a0,18
    1500:	00012517          	auipc	a0,0x12
    1504:	1400                	.insn	2, 0x1400
    1506:	0131                	.insn	2, 0x0131
    1508:	0000                	.insn	2, 0x0000
    150a:	1c08                	.insn	2, 0x1c08
    150c:	0000                	.insn	2, 0x0000
    150e:	0100                	.insn	2, 0x0100
    1510:	0918                	.insn	2, 0x0918
    1512:	0115                	.insn	2, 0x0115
    1514:	0139                	.insn	2, 0x0139
    1516:	0000                	.insn	2, 0x0000
    1518:	1600                	.insn	2, 0x1600
    151a:	3409                	.insn	2, 0x3409
    151c:	0000                	.insn	2, 0x0000
    151e:	1300                	.insn	2, 0x1300
    1520:	1d011b03          	lh	s6,464(sp)
    1524:	0125                	.insn	2, 0x0125
    1526:	0000                	.insn	2, 0x0000
    1528:	1700                	.insn	2, 0x1700
    152a:	01cd                	.insn	2, 0x01cd
    152c:	0000                	.insn	2, 0x0000
    152e:	170a                	.insn	2, 0x170a
    1530:	020d                	.insn	2, 0x020d
    1532:	0000                	.insn	2, 0x0000
    1534:	02cd170b          	.insn	4, 0x02cd170b
    1538:	0000                	.insn	2, 0x0000
    153a:	170c                	.insn	2, 0x170c
    153c:	02e2                	.insn	2, 0x02e2
    153e:	0000                	.insn	2, 0x0000
    1540:	170d                	.insn	2, 0x170d
    1542:	02fa                	.insn	2, 0x02fa
    1544:	0000                	.insn	2, 0x0000
    1546:	170e                	.insn	2, 0x170e
    1548:	02fa                	.insn	2, 0x02fa
    154a:	0000                	.insn	2, 0x0000
    154c:	1010000f          	.insn	4, 0x1010000f
    1550:	00bc                	.insn	2, 0x00bc
    1552:	0000                	.insn	2, 0x0000
    1554:	5201                	.insn	2, 0x5201
    1556:	011f f581 0002      	.insn	6, 0x0002f581011f
    155c:	1300                	.insn	2, 0x1300
    155e:	2304                	.insn	2, 0x2304
    1560:	8301                	.insn	2, 0x8301
    1562:	0458                	.insn	2, 0x0458
    1564:	0000                	.insn	2, 0x0000
    1566:	01260513          	addi	a0,a2,18
    156a:	2591                	.insn	2, 0x2591
    156c:	0001                	.insn	2, 0x0001
    156e:	1300                	.insn	2, 0x1300
    1570:	2706                	.insn	2, 0x2706
    1572:	9501                	.insn	2, 0x9501
    1574:	0125                	.insn	2, 0x0125
    1576:	0000                	.insn	2, 0x0000
    1578:	01280713          	addi	a4,a6,18
    157c:	2598                	.insn	2, 0x2598
    157e:	0001                	.insn	2, 0x0001
    1580:	1700                	.insn	2, 0x1700
    1582:	02e2                	.insn	2, 0x02e2
    1584:	0000                	.insn	2, 0x0000
    1586:	1711                	.insn	2, 0x1711
    1588:	02e2                	.insn	2, 0x02e2
    158a:	0000                	.insn	2, 0x0000
    158c:	0012                	.insn	2, 0x0012
    158e:	1310                	.insn	2, 0x1310
    1590:	02a0                	.insn	2, 0x02a0
    1592:	0000                	.insn	2, 0x0000
    1594:	5201                	.insn	2, 0x5201
    1596:	0120                	.insn	2, 0x0120
    1598:	f52a                	.insn	2, 0xf52a
    159a:	0002                	.insn	2, 0x0002
    159c:	1100                	.insn	2, 0x1100
    159e:	1908                	.insn	2, 0x1908
    15a0:	2b01                	.insn	2, 0x2b01
    15a2:	02d8                	.insn	2, 0x02d8
    15a4:	0000                	.insn	2, 0x0000
    15a6:	0911                	.insn	2, 0x0911
    15a8:	0112                	.insn	2, 0x0112
    15aa:	532c                	.insn	2, 0x532c
    15ac:	0005                	.insn	2, 0x0005
    15ae:	1100                	.insn	2, 0x1100
    15b0:	240a                	.insn	2, 0x240a
    15b2:	2d01                	.insn	2, 0x2d01
    15b4:	00000553          	.insn	4, 0x0553
    15b8:	012a0c13          	addi	s8,s4,18
    15bc:	2534                	.insn	2, 0x2534
    15be:	0001                	.insn	2, 0x0001
    15c0:	1800                	.insn	2, 0x1800
    15c2:	582f0123          	sb	sp,1410(t5) # 4900089c <USER_MAX+0x48b0089c>
    15c6:	0004                	.insn	2, 0x0004
    15c8:	1400                	.insn	2, 0x1400
    15ca:	0131                	.insn	2, 0x0131
    15cc:	0000                	.insn	2, 0x0000
    15ce:	1414                	.insn	2, 0x1414
    15d0:	0000                	.insn	2, 0x0000
    15d2:	0100                	.insn	2, 0x0100
    15d4:	0935                	.insn	2, 0x0935
    15d6:	0b15                	.insn	2, 0x0b15
    15d8:	0139                	.insn	2, 0x0139
    15da:	0000                	.insn	2, 0x0000
    15dc:	1600                	.insn	2, 0x1600
    15de:	c415                	.insn	2, 0xc415
    15e0:	0001                	.insn	2, 0x0001
    15e2:	1300                	.insn	2, 0x1300
    15e4:	3a011b0f          	.insn	4, 0x3a011b0f
    15e8:	02f5                	.insn	2, 0x02f5
    15ea:	0000                	.insn	2, 0x0000
    15ec:	0019                	.insn	2, 0x0019
    15ee:	0212                	.insn	2, 0x0212
    15f0:	0391                	.insn	2, 0x0391
    15f2:	0129                	.insn	2, 0x0129
    15f4:	ae4a                	.insn	2, 0xae4a
    15f6:	0000                	.insn	2, 0x0000
    15f8:	1300                	.insn	2, 0x1300
    15fa:	2c0e                	.insn	2, 0x2c0e
    15fc:	4b01                	.insn	2, 0x4b01
    15fe:	02f5                	.insn	2, 0x02f5
    1600:	0000                	.insn	2, 0x0000
    1602:	2d18                	.insn	2, 0x2d18
    1604:	3c01                	.insn	2, 0x3c01
    1606:	0458                	.insn	2, 0x0458
    1608:	0000                	.insn	2, 0x0000
    160a:	0119                	.insn	2, 0x0119
    160c:	012b0d13          	addi	s10,s6,18
    1610:	f558                	.insn	2, 0xf558
    1612:	0002                	.insn	2, 0x0002
    1614:	0000                	.insn	2, 0x0000
    1616:	1616                	.insn	2, 0x1616
    1618:	005c                	.insn	2, 0x005c
    161a:	0000                	.insn	2, 0x0000
    161c:	2e18                	.insn	2, 0x2e18
    161e:	6201                	.insn	2, 0x6201
    1620:	0125                	.insn	2, 0x0125
    1622:	0000                	.insn	2, 0x0000
    1624:	2f18                	.insn	2, 0x2f18
    1626:	6601                	.insn	2, 0x6601
    1628:	0125                	.insn	2, 0x0125
    162a:	0000                	.insn	2, 0x0000
    162c:	1900                	.insn	2, 0x1900
    162e:	1302                	.insn	2, 0x1302
    1630:	2b10                	.insn	2, 0x2b10
    1632:	4e01                	.insn	2, 0x4e01
    1634:	02f5                	.insn	2, 0x02f5
    1636:	0000                	.insn	2, 0x0000
    1638:	0000                	.insn	2, 0x0000
    163a:	1700                	.insn	2, 0x1700
    163c:	01cd                	.insn	2, 0x01cd
    163e:	0000                	.insn	2, 0x0000
    1640:	02e21717          	auipc	a4,0x2e21
    1644:	0000                	.insn	2, 0x0000
    1646:	1718                	.insn	2, 0x1718
    1648:	0304                	.insn	2, 0x0304
    164a:	0000                	.insn	2, 0x0000
    164c:	0019                	.insn	2, 0x0019
    164e:	131a                	.insn	2, 0x131a
    1650:	4e02                	.insn	2, 0x4e02
    1652:	0002d81b          	.insn	4, 0x0002d81b
    1656:	1c00                	.insn	2, 0x1c00
    1658:	1d00                	.insn	2, 0x1d00
    165a:	02dd                	.insn	2, 0x02dd
    165c:	0000                	.insn	2, 0x0000
    165e:	411e                	.insn	2, 0x411e
    1660:	0000                	.insn	2, 0x0000
    1662:	1f00                	.insn	2, 0x1f00
    1664:	0214                	.insn	2, 0x0214
    1666:	f532                	.insn	2, 0xf532
    1668:	0002                	.insn	2, 0x0002
    166a:	1b00                	.insn	2, 0x1b00
    166c:	0125                	.insn	2, 0x0125
    166e:	0000                	.insn	2, 0x0000
    1670:	0002f91b          	.insn	4, 0x0002f91b
    1674:	0000                	.insn	2, 0x0000
    1676:	1505                	.insn	2, 0x1505
    1678:	0405                	.insn	2, 0x0405
    167a:	1a20                	.insn	2, 0x1a20
    167c:	0216                	.insn	2, 0x0216
    167e:	1b3d                	.insn	2, 0x1b3d
    1680:	0041                	.insn	2, 0x0041
    1682:	0000                	.insn	2, 0x0000
    1684:	1f00                	.insn	2, 0x1f00
    1686:	f54a0217          	auipc	tp,0xf54a0
    168a:	0002                	.insn	2, 0x0002
    168c:	1b00                	.insn	2, 0x1b00
    168e:	02d8                	.insn	2, 0x02d8
    1690:	0000                	.insn	2, 0x0000
    1692:	0002d81b          	.insn	4, 0x0002d81b
    1696:	0000                	.insn	2, 0x0000
    1698:	1a21                	.insn	2, 0x1a21
    169a:	0020                	.insn	2, 0x0020
    169c:	0000                	.insn	2, 0x0000
    169e:	5201                	.insn	2, 0x5201
    16a0:	0131                	.insn	2, 0x0131
    16a2:	0000                	.insn	2, 0x0000
    16a4:	1115                	.insn	2, 0x1115
    16a6:	0139                	.insn	2, 0x0139
    16a8:	0000                	.insn	2, 0x0000
    16aa:	2200                	.insn	2, 0x2200
    16ac:	0002881b          	.insn	4, 0x0002881b
    16b0:	0100                	.insn	2, 0x0100
    16b2:	2152                	.insn	2, 0x2152
    16b4:	b001                	.insn	2, 0xb001
    16b6:	012a1313          	slli	t1,s4,0x12
    16ba:	000125b7          	lui	a1,0x12
    16be:	1800                	.insn	2, 0x1800
    16c0:	58b20123          	sb	a1,1410(tp) # f54a1c08 <USER_MAX+0xf4fa1c08>
    16c4:	0004                	.insn	2, 0x0004
    16c6:	1400                	.insn	2, 0x1400
    16c8:	0131                	.insn	2, 0x0131
    16ca:	0000                	.insn	2, 0x0000
    16cc:	141c                	.insn	2, 0x141c
    16ce:	0000                	.insn	2, 0x0000
    16d0:	0100                	.insn	2, 0x0100
    16d2:	09b8                	.insn	2, 0x09b8
    16d4:	1215                	.insn	2, 0x1215
    16d6:	0139                	.insn	2, 0x0139
    16d8:	0000                	.insn	2, 0x0000
    16da:	1600                	.insn	2, 0x1600
    16dc:	c41d                	.insn	2, 0xc41d
    16de:	0001                	.insn	2, 0x0001
    16e0:	1300                	.insn	2, 0x1300
    16e2:	1b16                	.insn	2, 0x1b16
    16e4:	bd01                	.insn	2, 0xbd01
    16e6:	02f5                	.insn	2, 0x02f5
    16e8:	0000                	.insn	2, 0x0000
    16ea:	0319                	.insn	2, 0x0319
    16ec:	01251413          	slli	s0,a0,0x12
    16f0:	25e4                	.insn	2, 0x25e4
    16f2:	0001                	.insn	2, 0x0001
    16f4:	1300                	.insn	2, 0x1300
    16f6:	3015                	.insn	2, 0x3015
    16f8:	e101                	.insn	2, 0xe101
    16fa:	0125                	.insn	2, 0x0125
    16fc:	0000                	.insn	2, 0x0000
    16fe:	01241713          	slli	a4,s0,0x12
    1702:	25e9                	.insn	2, 0x25e9
    1704:	0001                	.insn	2, 0x0001
    1706:	1800                	.insn	2, 0x1800
    1708:	012d                	.insn	2, 0x012d
    170a:	000458bf 012e1800 	.insn	8, 0x012e1800000458bf
    1712:	25d9                	.insn	2, 0x25d9
    1714:	0001                	.insn	2, 0x0001
    1716:	1800                	.insn	2, 0x1800
    1718:	25dd012f          	.insn	4, 0x25dd012f
    171c:	0001                	.insn	2, 0x0001
    171e:	1400                	.insn	2, 0x1400
    1720:	0131                	.insn	2, 0x0131
    1722:	0000                	.insn	2, 0x0000
    1724:	141d                	.insn	2, 0x141d
    1726:	0000                	.insn	2, 0x0000
    1728:	0100                	.insn	2, 0x0100
    172a:	012313e7          	.insn	4, 0x012313e7
    172e:	0001395b          	.insn	4, 0x0001395b
    1732:	0000                	.insn	2, 0x0000
    1734:	0419                	.insn	2, 0x0419
    1736:	012b1813          	slli	a6,s6,0x12
    173a:	f5ca                	.insn	2, 0xf5ca
    173c:	0002                	.insn	2, 0x0002
    173e:	0000                	.insn	2, 0x0000
    1740:	0519                	.insn	2, 0x0519
    1742:	012b1913          	slli	s2,s6,0x12
    1746:	f5d1                	.insn	2, 0xf5d1
    1748:	0002                	.insn	2, 0x0002
    174a:	0000                	.insn	2, 0x0000
    174c:	0000                	.insn	2, 0x0000
    174e:	0001cd17          	auipc	s10,0x1c
    1752:	1e00                	.insn	2, 0x1e00
    1754:	0002e217          	auipc	tp,0x2e
    1758:	1f00                	.insn	2, 0x1f00
    175a:	0002cd17          	auipc	s10,0x2c
    175e:	2000                	.insn	2, 0x2000
    1760:	0002fa17          	auipc	s4,0x2f
    1764:	2100                	.insn	2, 0x2100
    1766:	0002fa17          	auipc	s4,0x2f
    176a:	2200                	.insn	2, 0x2200
    176c:	0002fa17          	auipc	s4,0x2f
    1770:	2300                	.insn	2, 0x2300
    1772:	0002fa17          	auipc	s4,0x2f
    1776:	2400                	.insn	2, 0x2400
    1778:	0002fa17          	auipc	s4,0x2f
    177c:	2500                	.insn	2, 0x2500
    177e:	0002fa17          	auipc	s4,0x2f
    1782:	2600                	.insn	2, 0x2600
    1784:	0002fa17          	auipc	s4,0x2f
    1788:	2700                	.insn	2, 0x2700
    178a:	0002fa17          	auipc	s4,0x2f
    178e:	2800                	.insn	2, 0x2800
    1790:	0002fa17          	auipc	s4,0x2f
    1794:	2900                	.insn	2, 0x2900
    1796:	0002fa17          	auipc	s4,0x2f
    179a:	2a00                	.insn	2, 0x2a00
    179c:	0002cd17          	auipc	s10,0x2c
    17a0:	2b00                	.insn	2, 0x2b00
    17a2:	0002fa17          	auipc	s4,0x2f
    17a6:	2c00                	.insn	2, 0x2c00
    17a8:	0002fa17          	auipc	s4,0x2f
    17ac:	2d00                	.insn	2, 0x2d00
    17ae:	2400                	.insn	2, 0x2400
    17b0:	0118                	.insn	2, 0x0118
    17b2:	0002f5f7          	.insn	4, 0x0002f5f7
    17b6:	0f00                	.insn	2, 0x0f00
    17b8:	0119                	.insn	2, 0x0119
    17ba:	d8f8                	.insn	2, 0xd8f8
    17bc:	0002                	.insn	2, 0x0002
    17be:	0f00                	.insn	2, 0x0f00
    17c0:	011a                	.insn	2, 0x011a
    17c2:	58f9                	.insn	2, 0x58f9
    17c4:	0004                	.insn	2, 0x0004
    17c6:	1800                	.insn	2, 0x1800
    17c8:	f5fb011b          	.insn	4, 0xf5fb011b
    17cc:	0002                	.insn	2, 0x0002
    17ce:	2500                	.insn	2, 0x2500
    17d0:	011c                	.insn	2, 0x011c
    17d2:	0101                	.insn	2, 0x0101
    17d4:	02f5                	.insn	2, 0x02f5
    17d6:	0000                	.insn	2, 0x0000
    17d8:	1d00                	.insn	2, 0x1d00
    17da:	00d4                	.insn	2, 0x00d4
    17dc:	0000                	.insn	2, 0x0000
    17de:	2e26                	.insn	2, 0x2e26
    17e0:	03b0                	.insn	2, 0x03b0
    17e2:	0000                	.insn	2, 0x0000
    17e4:	5201                	.insn	2, 0x5201
    17e6:	0122                	.insn	2, 0x0122
    17e8:	011d                	.insn	2, 0x011d
    17ea:	02f5                	.insn	2, 0x02f5
    17ec:	0000                	.insn	2, 0x0000
    17ee:	01191a27          	.insn	4, 0x01191a27
    17f2:	011d                	.insn	2, 0x011d
    17f4:	02d8                	.insn	2, 0x02d8
    17f6:	0000                	.insn	2, 0x0000
    17f8:	0228                	.insn	2, 0x0228
    17fa:	0d91                	.insn	2, 0x0d91
    17fc:	0129                	.insn	2, 0x0129
    17fe:	012a                	.insn	2, 0x012a
    1800:	0558                	.insn	2, 0x0558
    1802:	0000                	.insn	2, 0x0000
    1804:	1c29                	.insn	2, 0x1c29
    1806:	012a                	.insn	2, 0x012a
    1808:	0124                	.insn	2, 0x0124
    180a:	0125                	.insn	2, 0x0125
    180c:	0000                	.insn	2, 0x0000
    180e:	2325                	.insn	2, 0x2325
    1810:	1f01                	.insn	2, 0x1f01
    1812:	5801                	.insn	2, 0x5801
    1814:	0004                	.insn	2, 0x0004
    1816:	2a00                	.insn	2, 0x2a00
    1818:	0131                	.insn	2, 0x0131
    181a:	0000                	.insn	2, 0x0000
    181c:	0000142f          	.insn	4, 0x142f
    1820:	0100                	.insn	2, 0x0100
    1822:	0125                	.insn	2, 0x0125
    1824:	1509                	.insn	2, 0x1509
    1826:	0001391b          	.insn	4, 0x0001391b
    182a:	0000                	.insn	2, 0x0000
    182c:	2e2a                	.insn	2, 0x2e2a
    182e:	0004                	.insn	2, 0x0004
    1830:	3000                	.insn	2, 0x3000
    1832:	00d8                	.insn	2, 0x00d8
    1834:	0000                	.insn	2, 0x0000
    1836:	2c01                	.insn	2, 0x2c01
    1838:	0501                	.insn	2, 0x0501
    183a:	1d15                	.insn	2, 0x1d15
    183c:	0436                	.insn	2, 0x0436
    183e:	0000                	.insn	2, 0x0000
    1840:	0d910323          	sb	s9,198(sp)
    1844:	3e9f 0004 2b00      	.insn	6, 0x2b0000043e9f
    184a:	461e                	.insn	2, 0x461e
    184c:	0004                	.insn	2, 0x0004
    184e:	2b00                	.insn	2, 0x2b00
    1850:	4e1f 0004 0000      	.insn	6, 0x00044e1f
    1856:	3116                	.insn	2, 0x3116
    1858:	0248                	.insn	2, 0x0248
    185a:	0000                	.insn	2, 0x0000
    185c:	2029                	.insn	2, 0x2029
    185e:	012e011b          	.insn	4, 0x012e011b
    1862:	02f5                	.insn	2, 0x02f5
    1864:	0000                	.insn	2, 0x0000
    1866:	3116                	.insn	2, 0x3116
    1868:	0248                	.insn	2, 0x0248
    186a:	0000                	.insn	2, 0x0000
    186c:	2129                	.insn	2, 0x2129
    186e:	012d                	.insn	2, 0x012d
    1870:	0130                	.insn	2, 0x0130
    1872:	0458                	.insn	2, 0x0458
    1874:	0000                	.insn	2, 0x0000
    1876:	0619                	.insn	2, 0x0619
    1878:	2229                	.insn	2, 0x2229
    187a:	0136012b          	.insn	4, 0x0136012b
    187e:	02f5                	.insn	2, 0x02f5
    1880:	0000                	.insn	2, 0x0000
    1882:	1900                	.insn	2, 0x1900
    1884:	2b232907          	.insn	4, 0x2b232907
    1888:	3a01                	.insn	2, 0x3a01
    188a:	f501                	.insn	2, 0xf501
    188c:	0002                	.insn	2, 0x0002
    188e:	0000                	.insn	2, 0x0000
    1890:	0000                	.insn	2, 0x0000
    1892:	0001cd17          	auipc	s10,0x1c
    1896:	3200                	.insn	2, 0x3200
    1898:	0002e217          	auipc	tp,0x2e
    189c:	3300                	.insn	2, 0x3300
    189e:	0002cd17          	auipc	s10,0x2c
    18a2:	3400                	.insn	2, 0x3400
    18a4:	0002cd17          	auipc	s10,0x2c
    18a8:	3500                	.insn	2, 0x3500
    18aa:	00053617          	auipc	a2,0x53
    18ae:	3600                	.insn	2, 0x3600
    18b0:	0002cd17          	auipc	s10,0x2c
    18b4:	3700                	.insn	2, 0x3700
    18b6:	1f00                	.insn	2, 0x1f00
    18b8:	021d                	.insn	2, 0x021d
    18ba:	2531                	.insn	2, 0x2531
    18bc:	0001                	.insn	2, 0x0001
    18be:	1b00                	.insn	2, 0x1b00
    18c0:	0125                	.insn	2, 0x0125
    18c2:	0000                	.insn	2, 0x0000
    18c4:	0005491b          	.insn	4, 0x0005491b
    18c8:	0000                	.insn	2, 0x0000
    18ca:	4e1d                	.insn	2, 0x4e1d
    18cc:	0005                	.insn	2, 0x0005
    18ce:	1e00                	.insn	2, 0x1e00
    18d0:	00d4                	.insn	2, 0x00d4
    18d2:	0000                	.insn	2, 0x0000
    18d4:	251d                	.insn	2, 0x251d
    18d6:	0001                	.insn	2, 0x0001
    18d8:	0300                	.insn	2, 0x0300
    18da:	00d4                	.insn	2, 0x00d4
    18dc:	0000                	.insn	2, 0x0000
    18de:	4504                	.insn	2, 0x4504
    18e0:	0000                	.insn	2, 0x0000
    18e2:	0b00                	.insn	2, 0x0b00
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
  a2:	0404ac03          	lw	s8,64(s1) # 40 <start-0x3fffc0>
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
  ba:	7a00                	.insn	2, 0x7a00
  bc:	0000                	.insn	2, 0x0000
  be:	0500                	.insn	2, 0x0500
  c0:	0400                	.insn	2, 0x0400
  c2:	0500                	.insn	2, 0x0500
  c4:	0000                	.insn	2, 0x0000
  c6:	1400                	.insn	2, 0x1400
  c8:	0000                	.insn	2, 0x0000
  ca:	2500                	.insn	2, 0x2500
  cc:	0000                	.insn	2, 0x0000
  ce:	3200                	.insn	2, 0x3200
  d0:	0000                	.insn	2, 0x0000
  d2:	5d00                	.insn	2, 0x5d00
  d4:	0000                	.insn	2, 0x0000
  d6:	6a00                	.insn	2, 0x6a00
  d8:	0000                	.insn	2, 0x0000
  da:	0100                	.insn	2, 0x0100
  dc:	040e                	.insn	2, 0x040e
  de:	8474                	.insn	2, 0x8474
  e0:	0401                	.insn	2, 0x0401
  e2:	0188                	.insn	2, 0x0188
  e4:	018c                	.insn	2, 0x018c
  e6:	9004                	.insn	2, 0x9004
  e8:	9401                	.insn	2, 0x9401
  ea:	0001                	.insn	2, 0x0001
  ec:	0e01                	.insn	2, 0x0e01
  ee:	c804                	.insn	2, 0xc804
  f0:	ec06                	.insn	2, 0xec06
  f2:	0406                	.insn	2, 0x0406
  f4:	09b8                	.insn	2, 0x09b8
  f6:	0aa4                	.insn	2, 0x0aa4
  f8:	0100                	.insn	2, 0x0100
  fa:	040e                	.insn	2, 0x040e
  fc:	07a4                	.insn	2, 0x07a4
  fe:	07b0                	.insn	2, 0x07b0
 100:	c004                	.insn	2, 0xc004
 102:	0407cc07          	.insn	4, 0x0407cc07
 106:	07dc                	.insn	2, 0x07dc
 108:	07e8                	.insn	2, 0x07e8
 10a:	f804                	.insn	2, 0xf804
 10c:	04088407          	.insn	4, 0x04088407
 110:	0894                	.insn	2, 0x0894
 112:	08a0                	.insn	2, 0x08a0
 114:	b004                	.insn	2, 0xb004
 116:	bc08                	.insn	2, 0xbc08
 118:	0408                	.insn	2, 0x0408
 11a:	08c8                	.insn	2, 0x08c8
 11c:	08d4                	.insn	2, 0x08d4
 11e:	d804                	.insn	2, 0xd804
 120:	e408                	.insn	2, 0xe408
 122:	0008                	.insn	2, 0x0008
 124:	0e01                	.insn	2, 0x0e01
 126:	b004                	.insn	2, 0xb004
 128:	0410840f          	.insn	4, 0x0410840f
 12c:	1088                	.insn	2, 0x1088
 12e:	1090                	.insn	2, 0x1090
 130:	0300                	.insn	2, 0x0300
 132:	980e                	.insn	2, 0x980e
 134:	0311                	.insn	2, 0x0311
 136:	8a001c4f          	.insn	4, 0x8a001c4f
 13a:	0000                	.insn	2, 0x0000
 13c:	0500                	.insn	2, 0x0500
 13e:	0400                	.insn	2, 0x0400
 140:	0800                	.insn	2, 0x0800
 142:	0000                	.insn	2, 0x0000
 144:	2000                	.insn	2, 0x2000
 146:	0000                	.insn	2, 0x0000
 148:	2b00                	.insn	2, 0x2b00
 14a:	0000                	.insn	2, 0x0000
 14c:	3b00                	.insn	2, 0x3b00
 14e:	0000                	.insn	2, 0x0000
 150:	4600                	.insn	2, 0x4600
 152:	0000                	.insn	2, 0x0000
 154:	5100                	.insn	2, 0x5100
 156:	0000                	.insn	2, 0x0000
 158:	5c00                	.insn	2, 0x5c00
 15a:	0000                	.insn	2, 0x0000
 15c:	6700                	.insn	2, 0x6700
 15e:	0000                	.insn	2, 0x0000
 160:	7700                	.insn	2, 0x7700
 162:	0000                	.insn	2, 0x0000
 164:	0400                	.insn	2, 0x0400
 166:	0584                	.insn	2, 0x0584
 168:	05ac                	.insn	2, 0x05ac
 16a:	b804                	.insn	2, 0xb804
 16c:	c805                	.insn	2, 0xc805
 16e:	0008                	.insn	2, 0x0008
 170:	8404                	.insn	2, 0x8404
 172:	9005                	.insn	2, 0x9005
 174:	0405                	.insn	2, 0x0405
 176:	07b0                	.insn	2, 0x07b0
 178:	07b4                	.insn	2, 0x07b4
 17a:	bc04                	.insn	2, 0xbc04
 17c:	0007e807          	.insn	4, 0x0007e807
 180:	cc04                	.insn	2, 0xcc04
 182:	ac05                	.insn	2, 0xac05
 184:	0406                	.insn	2, 0x0406
 186:	06b8                	.insn	2, 0x06b8
 188:	07a8                	.insn	2, 0x07a8
 18a:	0400                	.insn	2, 0x0400
 18c:	0aac                	.insn	2, 0x0aac
 18e:	0af4                	.insn	2, 0x0af4
 190:	8004                	.insn	2, 0x8004
 192:	000df00b          	.insn	4, 0x000df00b
 196:	9404                	.insn	2, 0x9404
 198:	040bd00b          	.insn	4, 0x040bd00b
 19c:	0bdc                	.insn	2, 0x0bdc
 19e:	0cd4                	.insn	2, 0x0cd4
 1a0:	0400                	.insn	2, 0x0400
 1a2:	0ce8                	.insn	2, 0x0ce8
 1a4:	0d88                	.insn	2, 0x0d88
 1a6:	cc04                	.insn	2, 0xcc04
 1a8:	f00d                	.insn	2, 0xf00d
 1aa:	000d                	.insn	2, 0x000d
 1ac:	f804                	.insn	2, 0xf804
 1ae:	9812                	.insn	2, 0x9812
 1b0:	13a00413          	li	s0,314
 1b4:	13a8                	.insn	2, 0x13a8
 1b6:	f804                	.insn	2, 0xf804
 1b8:	00148013          	addi	zero,s1,1
 1bc:	a804                	.insn	2, 0xa804
 1be:	0413f813          	andi	a6,t2,65
 1c2:	1488                	.insn	2, 0x1488
 1c4:	1494                	.insn	2, 0x1494
	...

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
  14:	0000023f 00000068 	.insn	8, 0x00680000023f
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
  3c:	03aa                	.insn	2, 0x03aa
  3e:	0000                	.insn	2, 0x0000
  40:	021c                	.insn	2, 0x021c
  42:	0000                	.insn	2, 0x0000
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
  d4:	0430                	.insn	2, 0x0430
  d6:	0000                	.insn	2, 0x0000
  d8:	0201                	.insn	2, 0x0201
  da:	0000                	.insn	2, 0x0000
  dc:	0000020b          	.insn	4, 0x020b
  e0:	0212                	.insn	2, 0x0212
  e2:	0000                	.insn	2, 0x0000
  e4:	021e                	.insn	2, 0x021e
  e6:	0000                	.insn	2, 0x0000
  e8:	000001e3          	beqz	zero,8ea <start-0x3ff716>
  ec:	0168                	.insn	2, 0x0168
  ee:	0000                	.insn	2, 0x0000
  f0:	0005                	.insn	2, 0x0005
  f2:	0000                	.insn	2, 0x0000
  f4:	0000                	.insn	2, 0x0000
  f6:	0000                	.insn	2, 0x0000
  f8:	0222                	.insn	2, 0x0222
  fa:	0000                	.insn	2, 0x0000
  fc:	00000033          	add	zero,zero,zero
 100:	022d                	.insn	2, 0x022d
 102:	0000                	.insn	2, 0x0000
 104:	0236                	.insn	2, 0x0236
 106:	0000                	.insn	2, 0x0000
 108:	0244                	.insn	2, 0x0244
 10a:	0000                	.insn	2, 0x0000
 10c:	0068                	.insn	2, 0x0068
 10e:	0000                	.insn	2, 0x0000
 110:	024c                	.insn	2, 0x024c
 112:	0000                	.insn	2, 0x0000
 114:	0255                	.insn	2, 0x0255
 116:	0000                	.insn	2, 0x0000
 118:	007c                	.insn	2, 0x007c
 11a:	0000                	.insn	2, 0x0000
 11c:	0089                	.insn	2, 0x0089
 11e:	0000                	.insn	2, 0x0000
 120:	0000023f 0000009c 	.insn	8, 0x009c0000023f
 128:	0085                	.insn	2, 0x0085
 12a:	0000                	.insn	2, 0x0000
 12c:	008a                	.insn	2, 0x008a
 12e:	0000                	.insn	2, 0x0000
 130:	025e                	.insn	2, 0x025e
 132:	0000                	.insn	2, 0x0000
 134:	0266                	.insn	2, 0x0266
 136:	0000                	.insn	2, 0x0000
 138:	026c                	.insn	2, 0x026c
 13a:	0000                	.insn	2, 0x0000
 13c:	0271                	.insn	2, 0x0271
 13e:	0000                	.insn	2, 0x0000
 140:	0276                	.insn	2, 0x0276
 142:	0000                	.insn	2, 0x0000
 144:	0000027b          	.insn	4, 0x027b
 148:	027e                	.insn	2, 0x027e
 14a:	0000                	.insn	2, 0x0000
 14c:	0281                	.insn	2, 0x0281
 14e:	0000                	.insn	2, 0x0000
 150:	0284                	.insn	2, 0x0284
 152:	0000                	.insn	2, 0x0000
 154:	000000ab          	.insn	4, 0x00ab
 158:	000001e3          	beqz	zero,95a <start-0x3ff6a6>
 15c:	00000287          	.insn	4, 0x0287
 160:	028a                	.insn	2, 0x028a
 162:	0000                	.insn	2, 0x0000
 164:	00b9                	.insn	2, 0x00b9
 166:	0000                	.insn	2, 0x0000
 168:	017c                	.insn	2, 0x017c
 16a:	0000                	.insn	2, 0x0000
 16c:	028e                	.insn	2, 0x028e
 16e:	0000                	.insn	2, 0x0000
 170:	01d2                	.insn	2, 0x01d2
 172:	0000                	.insn	2, 0x0000
 174:	0105                	.insn	2, 0x0105
 176:	0000                	.insn	2, 0x0000
 178:	0298                	.insn	2, 0x0298
 17a:	0000                	.insn	2, 0x0000
 17c:	02a1                	.insn	2, 0x02a1
 17e:	0000                	.insn	2, 0x0000
 180:	02ac                	.insn	2, 0x02ac
 182:	0000                	.insn	2, 0x0000
 184:	000002bb          	.insn	4, 0x02bb
 188:	02c2                	.insn	2, 0x02c2
 18a:	0000                	.insn	2, 0x0000
 18c:	02ca                	.insn	2, 0x02ca
 18e:	0000                	.insn	2, 0x0000
 190:	000000f7          	.insn	4, 0x00f7
 194:	017f 0000 00a6 0000 	.insn	10, 0x00b2000000a60000017f
 19c:	00b2 
 19e:	0000                	.insn	2, 0x0000
 1a0:	0100                	.insn	2, 0x0100
 1a2:	0000                	.insn	2, 0x0000
 1a4:	010d                	.insn	2, 0x010d
 1a6:	0000                	.insn	2, 0x0000
 1a8:	02e6                	.insn	2, 0x02e6
 1aa:	0000                	.insn	2, 0x0000
 1ac:	0121                	.insn	2, 0x0121
 1ae:	0000                	.insn	2, 0x0000
 1b0:	0132                	.insn	2, 0x0132
 1b2:	0000                	.insn	2, 0x0000
 1b4:	02f9                	.insn	2, 0x02f9
 1b6:	0000                	.insn	2, 0x0000
 1b8:	0174                	.insn	2, 0x0174
 1ba:	0000                	.insn	2, 0x0000
 1bc:	00f2                	.insn	2, 0x00f2
 1be:	0000                	.insn	2, 0x0000
 1c0:	0000030f          	.insn	4, 0x030f
 1c4:	00e1                	.insn	2, 0x00e1
 1c6:	0000                	.insn	2, 0x0000
 1c8:	00e8                	.insn	2, 0x00e8
 1ca:	0000                	.insn	2, 0x0000
 1cc:	0184                	.insn	2, 0x0184
 1ce:	0000                	.insn	2, 0x0000
 1d0:	018d                	.insn	2, 0x018d
 1d2:	0000                	.insn	2, 0x0000
 1d4:	0316                	.insn	2, 0x0316
 1d6:	0000                	.insn	2, 0x0000
 1d8:	00d1                	.insn	2, 0x00d1
 1da:	0000                	.insn	2, 0x0000
 1dc:	031e                	.insn	2, 0x031e
 1de:	0000                	.insn	2, 0x0000
 1e0:	00c1                	.insn	2, 0x00c1
 1e2:	0000                	.insn	2, 0x0000
 1e4:	00000333          	add	t1,zero,zero
 1e8:	0339                	.insn	2, 0x0339
 1ea:	0000                	.insn	2, 0x0000
 1ec:	044e                	.insn	2, 0x044e
 1ee:	0000                	.insn	2, 0x0000
 1f0:	0345                	.insn	2, 0x0345
 1f2:	0000                	.insn	2, 0x0000
 1f4:	00000347          	.insn	4, 0x0347
 1f8:	034d                	.insn	2, 0x034d
 1fa:	0000                	.insn	2, 0x0000
 1fc:	00000353          	.insn	4, 0x0353
 200:	03b2                	.insn	2, 0x03b2
 202:	0000                	.insn	2, 0x0000
 204:	0365                	.insn	2, 0x0365
 206:	0000                	.insn	2, 0x0000
 208:	0369                	.insn	2, 0x0369
 20a:	0000                	.insn	2, 0x0000
 20c:	0000036f          	jal	t1,20c <start-0x3ffdf4>
 210:	0371                	.insn	2, 0x0371
 212:	0000                	.insn	2, 0x0000
 214:	01c5                	.insn	2, 0x01c5
 216:	0000                	.insn	2, 0x0000
 218:	0378                	.insn	2, 0x0378
 21a:	0000                	.insn	2, 0x0000
 21c:	0430                	.insn	2, 0x0430
 21e:	0000                	.insn	2, 0x0000
 220:	03f5                	.insn	2, 0x03f5
 222:	0000                	.insn	2, 0x0000
 224:	043a                	.insn	2, 0x043a
 226:	0000                	.insn	2, 0x0000
 228:	037c                	.insn	2, 0x037c
 22a:	0000                	.insn	2, 0x0000
 22c:	0204                	.insn	2, 0x0204
 22e:	0000                	.insn	2, 0x0000
 230:	0386                	.insn	2, 0x0386
 232:	0000                	.insn	2, 0x0000
 234:	01f1                	.insn	2, 0x01f1
 236:	0000                	.insn	2, 0x0000
 238:	01e1                	.insn	2, 0x01e1
 23a:	0000                	.insn	2, 0x0000
 23c:	038d                	.insn	2, 0x038d
 23e:	0000                	.insn	2, 0x0000
 240:	0391                	.insn	2, 0x0391
 242:	0000                	.insn	2, 0x0000
 244:	021c                	.insn	2, 0x021c
 246:	0000                	.insn	2, 0x0000
 248:	0395                	.insn	2, 0x0395
 24a:	0000                	.insn	2, 0x0000
 24c:	0398                	.insn	2, 0x0398
 24e:	0000                	.insn	2, 0x0000
 250:	0000039b          	.insn	4, 0x039b
 254:	03aa                	.insn	2, 0x03aa
 256:	0000                	.insn	2, 0x0000
 258:	00c8                	.insn	2, 0x00c8
 25a:	0000                	.insn	2, 0x0000
 25c:	0005                	.insn	2, 0x0005
 25e:	0000                	.insn	2, 0x0000
 260:	0000                	.insn	2, 0x0000
 262:	0000                	.insn	2, 0x0000
 264:	03a0                	.insn	2, 0x03a0
 266:	0000                	.insn	2, 0x0000
 268:	00000033          	add	zero,zero,zero
 26c:	0000023f 00000068 	.insn	8, 0x00680000023f
 274:	03ac                	.insn	2, 0x03ac
 276:	0000                	.insn	2, 0x0000
 278:	0236                	.insn	2, 0x0236
 27a:	0000                	.insn	2, 0x0000
 27c:	0244                	.insn	2, 0x0244
 27e:	0000                	.insn	2, 0x0000
 280:	03b6                	.insn	2, 0x03b6
 282:	0000                	.insn	2, 0x0000
 284:	03be                	.insn	2, 0x03be
 286:	0000                	.insn	2, 0x0000
 288:	007c                	.insn	2, 0x007c
 28a:	0000                	.insn	2, 0x0000
 28c:	0089                	.insn	2, 0x0089
 28e:	0000                	.insn	2, 0x0000
 290:	000003c7          	.insn	4, 0x03c7
 294:	03d1                	.insn	2, 0x03d1
 296:	0000                	.insn	2, 0x0000
 298:	03dc                	.insn	2, 0x03dc
 29a:	0000                	.insn	2, 0x0000
 29c:	03e9                	.insn	2, 0x03e9
 29e:	0000                	.insn	2, 0x0000
 2a0:	03fd                	.insn	2, 0x03fd
 2a2:	0000                	.insn	2, 0x0000
 2a4:	02ac                	.insn	2, 0x02ac
 2a6:	0000                	.insn	2, 0x0000
 2a8:	03f5                	.insn	2, 0x03f5
 2aa:	0000                	.insn	2, 0x0000
 2ac:	00b2                	.insn	2, 0x00b2
 2ae:	0000                	.insn	2, 0x0000
 2b0:	031e                	.insn	2, 0x031e
 2b2:	0000                	.insn	2, 0x0000
 2b4:	0085                	.insn	2, 0x0085
 2b6:	0000                	.insn	2, 0x0000
 2b8:	00b9                	.insn	2, 0x00b9
 2ba:	0000                	.insn	2, 0x0000
 2bc:	00e1                	.insn	2, 0x00e1
 2be:	0000                	.insn	2, 0x0000
 2c0:	040a                	.insn	2, 0x040a
 2c2:	0000                	.insn	2, 0x0000
 2c4:	041a                	.insn	2, 0x041a
 2c6:	0000                	.insn	2, 0x0000
 2c8:	00dd                	.insn	2, 0x00dd
 2ca:	0000                	.insn	2, 0x0000
 2cc:	044e                	.insn	2, 0x044e
 2ce:	0000                	.insn	2, 0x0000
 2d0:	041f 0000 02f9      	.insn	6, 0x02f90000041f
 2d6:	0000                	.insn	2, 0x0000
 2d8:	015e                	.insn	2, 0x015e
 2da:	0000                	.insn	2, 0x0000
 2dc:	0149                	.insn	2, 0x0149
 2de:	0000                	.insn	2, 0x0000
 2e0:	02a1                	.insn	2, 0x02a1
 2e2:	0000                	.insn	2, 0x0000
 2e4:	0155                	.insn	2, 0x0155
 2e6:	0000                	.insn	2, 0x0000
 2e8:	0168                	.insn	2, 0x0168
 2ea:	0000                	.insn	2, 0x0000
 2ec:	03b2                	.insn	2, 0x03b2
 2ee:	0000                	.insn	2, 0x0000
 2f0:	043a                	.insn	2, 0x043a
 2f2:	0000                	.insn	2, 0x0000
 2f4:	000002b7          	lui	t0,0x0
 2f8:	00000423          	sb	zero,8(zero) # 8 <start-0x3ffff8>
 2fc:	042c                	.insn	2, 0x042c
 2fe:	0000                	.insn	2, 0x0000
 300:	0436                	.insn	2, 0x0436
 302:	0000                	.insn	2, 0x0000
 304:	0415                	.insn	2, 0x0415
 306:	0000                	.insn	2, 0x0000
 308:	0000043f 00000345 	.insn	8, 0x03450000043f
 310:	0448                	.insn	2, 0x0448
 312:	0000                	.insn	2, 0x0000
 314:	0376                	.insn	2, 0x0376
 316:	0000                	.insn	2, 0x0000
 318:	044a                	.insn	2, 0x044a
 31a:	0000                	.insn	2, 0x0000
 31c:	0450                	.insn	2, 0x0450
 31e:	0000                	.insn	2, 0x0000
 320:	0456                	.insn	2, 0x0456
	...

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
 22c:	6d00                	.insn	2, 0x6d00
 22e:	7461                	.insn	2, 0x7461
 230:	6972                	.insn	2, 0x6972
 232:	5f78                	.insn	2, 0x5f78
 234:	0041                	.insn	2, 0x0041
 236:	6e75                	.insn	2, 0x6e75
 238:	6e676973          	csrrsi	s2,0x6e6,14
 23c:	6465                	.insn	2, 0x6465
 23e:	6320                	.insn	2, 0x6320
 240:	6168                	.insn	2, 0x6168
 242:	0072                	.insn	2, 0x0072
 244:	6975                	.insn	2, 0x6975
 246:	746e                	.insn	2, 0x746e
 248:	5f38                	.insn	2, 0x5f38
 24a:	0074                	.insn	2, 0x0074
 24c:	616d                	.insn	2, 0x616d
 24e:	7274                	.insn	2, 0x7274
 250:	7869                	.insn	2, 0x7869
 252:	425f 6d00 7461      	.insn	6, 0x74616d00425f
 258:	6972                	.insn	2, 0x6972
 25a:	5f78                	.insn	2, 0x5f78
 25c:	79730043          	.insn	4, 0x79730043
 260:	6c616373          	csrrsi	t1,0x6c6,2
 264:	006c                	.insn	2, 0x006c
 266:	6e737973          	csrrci	s2,0x6e7,6
 26a:	7261006f          	j	10990 <start-0x3ef670>
 26e:	61003067          	.insn	4, 0x61003067
 272:	6772                	.insn	2, 0x6772
 274:	0031                	.insn	2, 0x0031
 276:	7261                	.insn	2, 0x7261
 278:	61003267          	.insn	4, 0x61003267
 27c:	0030                	.insn	2, 0x0030
 27e:	3161                	.insn	2, 0x3161
 280:	6100                	.insn	2, 0x6100
 282:	0032                	.insn	2, 0x0032
 284:	3361                	.insn	2, 0x3361
 286:	6100                	.insn	2, 0x6100
 288:	0034                	.insn	2, 0x0034
 28a:	6572                	.insn	2, 0x6572
 28c:	0074                	.insn	2, 0x0074
 28e:	7270                	.insn	2, 0x7270
 290:	6e69                	.insn	2, 0x6e69
 292:	5f74                	.insn	2, 0x5f74
 294:	6e69                	.insn	2, 0x6e69
 296:	0074                	.insn	2, 0x0074
 298:	696d                	.insn	2, 0x696d
 29a:	70615f63          	bge	sp,t1,9b8 <start-0x3ff648>
 29e:	3269                	.insn	2, 0x3269
 2a0:	6600                	.insn	2, 0x6600
 2a2:	7461                	.insn	2, 0x7461
 2a4:	665f3233          	.insn	4, 0x665f3233
 2a8:	6e69                	.insn	2, 0x6e69
 2aa:	0064                	.insn	2, 0x0064
 2ac:	73756c63          	bltu	a0,s7,9e4 <start-0x3ff61c>
 2b0:	6574                	.insn	2, 0x6574
 2b2:	5f72                	.insn	2, 0x5f72
 2b4:	6f74                	.insn	2, 0x6f74
 2b6:	6c5f 6162 7300      	.insn	6, 0x730061626c5f
 2bc:	5f64                	.insn	2, 0x5f64
 2be:	7061                	.insn	2, 0x7061
 2c0:	0069                	.insn	2, 0x0069
 2c2:	615f6473          	csrrsi	s0,htimedeltah,30
 2c6:	6970                	.insn	2, 0x6970
 2c8:	0032                	.insn	2, 0x0032
 2ca:	6c6c6163          	bltu	s8,t1,98c <start-0x3ff674>
 2ce:	735f 6570 6365      	.insn	6, 0x63656570735f
 2d4:	5f68                	.insn	2, 0x5f68
 2d6:	6572                	.insn	2, 0x6572
 2d8:	6e676f63          	bltu	a4,t1,9d6 <start-0x3ff62a>
 2dc:	7469                	.insn	2, 0x7469
 2de:	6f69                	.insn	2, 0x6f69
 2e0:	5f6e                	.insn	2, 0x5f6e
 2e2:	7061                	.insn	2, 0x7061
 2e4:	0069                	.insn	2, 0x0069
 2e6:	6c6c6163          	bltu	s8,t1,9a8 <start-0x3ff658>
 2ea:	6d5f 6369 775f      	.insn	6, 0x775f63696d5f
 2f0:	6972                	.insn	2, 0x6972
 2f2:	6574                	.insn	2, 0x6574
 2f4:	615f 6970 6300      	.insn	6, 0x63006970615f
 2fa:	6c61                	.insn	2, 0x6c61
 2fc:	5f6c                	.insn	2, 0x5f6c
 2fe:	775f6473          	csrrsi	s0,0x775,30
 302:	6972                	.insn	2, 0x6972
 304:	6574                	.insn	2, 0x6574
 306:	625f 6675 615f      	.insn	6, 0x615f6675625f
 30c:	6970                	.insn	2, 0x6970
 30e:	7300                	.insn	2, 0x7300
 310:	7274                	.insn	2, 0x7274
 312:	00797063          	bgeu	s2,t2,312 <start-0x3ffcee>
 316:	63746567          	.insn	4, 0x63746567
 31a:	6168                	.insn	2, 0x6168
 31c:	0072                	.insn	2, 0x0072
 31e:	6c6c6163          	bltu	s8,t1,9e0 <start-0x3ff620>
 322:	735f 5f64 6572      	.insn	6, 0x65725f64735f
 328:	6461                	.insn	2, 0x6461
 32a:	625f 6675 615f      	.insn	6, 0x615f6675625f
 330:	6970                	.insn	2, 0x6970
 332:	7300                	.insn	2, 0x7300
 334:	6174                	.insn	2, 0x6174
 336:	7472                	.insn	2, 0x7472
 338:	6d00                	.insn	2, 0x6d00
 33a:	7461                	.insn	2, 0x7461
 33c:	6972                	.insn	2, 0x6972
 33e:	5f78                	.insn	2, 0x5f78
 340:	657a6973          	csrrsi	s2,hviprio2h,20
 344:	6a00                	.insn	2, 0x6a00
 346:	6900                	.insn	2, 0x6900
 348:	646e                	.insn	2, 0x646e
 34a:	7865                	.insn	2, 0x7865
 34c:	7600                	.insn	2, 0x7600
 34e:	7261                	.insn	2, 0x7261
 350:	5f007367          	.insn	4, 0x5f007367
 354:	625f 6975 746c      	.insn	6, 0x746c6975625f
 35a:	6e69                	.insn	2, 0x6e69
 35c:	765f 5f61 696c      	.insn	6, 0x696c5f61765f
 362:	66007473          	csrrci	s0,0x660,0
 366:	746d                	.insn	2, 0x746d
 368:	7600                	.insn	2, 0x7600
 36a:	6c61                	.insn	2, 0x6c61
 36c:	6575                	.insn	2, 0x6575
 36e:	7500                	.insn	2, 0x7500
 370:	6e00                	.insn	2, 0x6e00
 372:	6269                	.insn	2, 0x6269
 374:	6c62                	.insn	2, 0x6c62
 376:	0065                	.insn	2, 0x0065
 378:	6e65                	.insn	2, 0x6e65
 37a:	0064                	.insn	2, 0x0064
 37c:	72617473          	csrrci	s0,mhpmevent6h,2
 380:	5f74                	.insn	2, 0x5f74
 382:	626c                	.insn	2, 0x626c
 384:	0061                	.insn	2, 0x0061
 386:	6572                	.insn	2, 0x6572
 388:	746c7573          	csrrci	a0,0x746,24
 38c:	6400                	.insn	2, 0x6400
 38e:	73007473          	csrrci	s0,mhpmevent16h,0
 392:	6372                	.insn	2, 0x6372
 394:	7300                	.insn	2, 0x7300
 396:	0031                	.insn	2, 0x0031
 398:	62003273          	csrrc	tp,0x620,zero
 39c:	7361                	.insn	2, 0x7361
 39e:	0065                	.insn	2, 0x0065
 3a0:	2f637273          	csrrci	tp,0x2f6,6
 3a4:	6166                	.insn	2, 0x6166
 3a6:	3374                	.insn	2, 0x3374
 3a8:	2e32                	.insn	2, 0x2e32
 3aa:	61660063          	beq	a2,s6,9aa <start-0x3ff656>
 3ae:	3374                	.insn	2, 0x3374
 3b0:	5f32                	.insn	2, 0x5f32
 3b2:	7562                	.insn	2, 0x7562
 3b4:	0066                	.insn	2, 0x0066
 3b6:	61665f67          	.insn	4, 0x61665f67
 3ba:	3374                	.insn	2, 0x3374
 3bc:	0032                	.insn	2, 0x0032
 3be:	6170                	.insn	2, 0x6170
 3c0:	7472                	.insn	2, 0x7472
 3c2:	6c5f 6162 6600      	.insn	6, 0x660061626c5f
 3c8:	7461                	.insn	2, 0x7461
 3ca:	625f 6765 6e69      	.insn	6, 0x6e696765625f
 3d0:	6400                	.insn	2, 0x6400
 3d2:	7461                	.insn	2, 0x7461
 3d4:	5f61                	.insn	2, 0x5f61
 3d6:	6562                	.insn	2, 0x6562
 3d8:	006e6967          	.insn	4, 0x006e6967
 3dc:	6f72                	.insn	2, 0x6f72
 3de:	635f746f          	jal	s0,f8212 <start-0x307dee>
 3e2:	756c                	.insn	2, 0x756c
 3e4:	72657473          	csrrci	s0,mhpmevent6h,10
 3e8:	7300                	.insn	2, 0x7300
 3ea:	6365                	.insn	2, 0x6365
 3ec:	6f74                	.insn	2, 0x6f74
 3ee:	7372                	.insn	2, 0x7372
 3f0:	705f 7265 635f      	.insn	6, 0x635f7265705f
 3f6:	756c                	.insn	2, 0x756c
 3f8:	72657473          	csrrci	s0,mhpmevent6h,10
 3fc:	6600                	.insn	2, 0x6600
 3fe:	7461                	.insn	2, 0x7461
 400:	695f3233          	.insn	4, 0x695f3233
 404:	666e                	.insn	2, 0x666e
 406:	00745f6f          	jal	t5,45c0c <start-0x3ba3f4>
 40a:	6166                	.insn	2, 0x6166
 40c:	3374                	.insn	2, 0x3374
 40e:	5f32                	.insn	2, 0x5f32
 410:	616d                	.insn	2, 0x616d
 412:	735f656b          	.insn	4, 0x735f656b
 416:	6f68                	.insn	2, 0x6f68
 418:	7472                	.insn	2, 0x7472
 41a:	616e                	.insn	2, 0x616e
 41c:	656d                	.insn	2, 0x656d
 41e:	7000                	.insn	2, 0x7000
 420:	7200736f          	jal	t1,7b40 <start-0x3f84c0>
 424:	7365                	.insn	2, 0x7365
 426:	7265                	.insn	2, 0x7265
 428:	6576                	.insn	2, 0x6576
 42a:	0064                	.insn	2, 0x0064
 42c:	6166                	.insn	2, 0x6166
 42e:	5f74                	.insn	2, 0x5f74
 430:	6e756f63          	bltu	a0,t2,b2e <start-0x3ff4d2>
 434:	0074                	.insn	2, 0x0074
 436:	6166                	.insn	2, 0x6166
 438:	5f74                	.insn	2, 0x5f74
 43a:	657a6973          	csrrsi	s2,hviprio2h,20
 43e:	7200                	.insn	2, 0x7200
 440:	5f746f6f          	jal	t5,47236 <start-0x3b8dca>
 444:	626c                	.insn	2, 0x626c
 446:	0061                	.insn	2, 0x0061
 448:	6c63006b          	.insn	4, 0x6c63006b
 44c:	685f 0069 6c63      	.insn	6, 0x6c630069685f
 452:	6c5f 006f 6c63      	.insn	6, 0x6c63006f6c5f
	...

Disassembly of section .debug_addr:

00000000 <.debug_addr>:
   0:	0214                	.insn	2, 0x0214
   2:	0000                	.insn	2, 0x0000
   4:	0005                	.insn	2, 0x0005
   6:	0004                	.insn	2, 0x0004
   8:	1eec                	.insn	2, 0x1eec
   a:	0040                	.insn	2, 0x0040
   c:	1efa                	.insn	2, 0x1efa
   e:	0040                	.insn	2, 0x0040
  10:	00401f07          	.insn	4, 0x00401f07
  14:	1f14                	.insn	2, 0x1f14
  16:	0040                	.insn	2, 0x0040
  18:	1f1a                	.insn	2, 0x1f1a
  1a:	0040                	.insn	2, 0x0040
  1c:	00401f33          	sll	t5,zero,tp
  20:	1f38                	.insn	2, 0x1f38
  22:	0040                	.insn	2, 0x0040
  24:	00401f3f 00401f59 	.insn	8, 0x00401f5900401f3f
  2c:	00401f63          	bne	zero,tp,4a <start-0x3fffb6>
  30:	1f6c                	.insn	2, 0x1f6c
  32:	0040                	.insn	2, 0x0040
  34:	1f7d                	.insn	2, 0x1f7d
  36:	0040                	.insn	2, 0x0040
  38:	1f86                	.insn	2, 0x1f86
  3a:	0040                	.insn	2, 0x0040
  3c:	1f9f 0040 1fa9      	.insn	6, 0x1fa900401f9f
  42:	0040                	.insn	2, 0x0040
  44:	00401fc3          	.insn	4, 0x00401fc3
  48:	00401fcb          	.insn	4, 0x00401fcb
  4c:	1fe4                	.insn	2, 0x1fe4
  4e:	0040                	.insn	2, 0x0040
  50:	1fed                	.insn	2, 0x1fed
  52:	0040                	.insn	2, 0x0040
  54:	00402007          	.insn	4, 0x00402007
  58:	2026                	.insn	2, 0x2026
  5a:	0040                	.insn	2, 0x0040
  5c:	2031                	.insn	2, 0x2031
  5e:	0040                	.insn	2, 0x0040
  60:	2045                	.insn	2, 0x2045
  62:	0040                	.insn	2, 0x0040
  64:	2052                	.insn	2, 0x2052
  66:	0040                	.insn	2, 0x0040
  68:	00402063          	.insn	4, 0x00402063
  6c:	0040206b          	.insn	4, 0x0040206b
  70:	2079                	.insn	2, 0x2079
  72:	0040                	.insn	2, 0x0040
  74:	2088                	.insn	2, 0x2088
  76:	0040                	.insn	2, 0x0040
  78:	2091                	.insn	2, 0x2091
  7a:	0040                	.insn	2, 0x0040
  7c:	0040209b          	.insn	4, 0x0040209b
  80:	20b4                	.insn	2, 0x20b4
  82:	0040                	.insn	2, 0x0040
  84:	20c0                	.insn	2, 0x20c0
  86:	0040                	.insn	2, 0x0040
  88:	004020db          	.insn	4, 0x004020db
  8c:	004020ef          	jal	2090 <start-0x3fdf70>
  90:	20f6                	.insn	2, 0x20f6
  92:	0040                	.insn	2, 0x0040
  94:	004020fb          	.insn	4, 0x004020fb
  98:	2106                	.insn	2, 0x2106
  9a:	0040                	.insn	2, 0x0040
  9c:	0040210b          	.insn	4, 0x0040210b
  a0:	2110                	.insn	2, 0x2110
  a2:	0040                	.insn	2, 0x0040
  a4:	2112                	.insn	2, 0x2112
  a6:	0040                	.insn	2, 0x0040
  a8:	00402127          	.insn	4, 0x00402127
  ac:	0040212b          	.insn	4, 0x0040212b
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
 218:	0148                	.insn	2, 0x0148
 21a:	0000                	.insn	2, 0x0000
 21c:	0005                	.insn	2, 0x0005
 21e:	0004                	.insn	2, 0x0004
 220:	2244                	.insn	2, 0x2244
 222:	0040                	.insn	2, 0x0040
 224:	3244                	.insn	2, 0x3244
 226:	0040                	.insn	2, 0x0040
 228:	4244                	.insn	2, 0x4244
 22a:	0040                	.insn	2, 0x0040
 22c:	2145                	.insn	2, 0x2145
 22e:	0040                	.insn	2, 0x0040
 230:	215a                	.insn	2, 0x215a
 232:	0040                	.insn	2, 0x0040
 234:	2162                	.insn	2, 0x2162
 236:	0040                	.insn	2, 0x0040
 238:	2175                	.insn	2, 0x2175
 23a:	0040                	.insn	2, 0x0040
 23c:	218d                	.insn	2, 0x218d
 23e:	0040                	.insn	2, 0x0040
 240:	004021ab          	.insn	4, 0x004021ab
 244:	21c5                	.insn	2, 0x21c5
 246:	0040                	.insn	2, 0x0040
 248:	21d1                	.insn	2, 0x21d1
 24a:	0040                	.insn	2, 0x0040
 24c:	21df 0040 21f0      	.insn	6, 0x21f0004021df
 252:	0040                	.insn	2, 0x0040
 254:	2202                	.insn	2, 0x2202
 256:	0040                	.insn	2, 0x0040
 258:	0a30                	.insn	2, 0x0a30
 25a:	0040                	.insn	2, 0x0040
 25c:	0a48                	.insn	2, 0x0a48
 25e:	0040                	.insn	2, 0x0040
 260:	0a64                	.insn	2, 0x0a64
 262:	0040                	.insn	2, 0x0040
 264:	0a84                	.insn	2, 0x0a84
 266:	0040                	.insn	2, 0x0040
 268:	0af0                	.insn	2, 0x0af0
 26a:	0040                	.insn	2, 0x0040
 26c:	0b2c                	.insn	2, 0x0b2c
 26e:	0040                	.insn	2, 0x0040
 270:	0b38                	.insn	2, 0x0b38
 272:	0040                	.insn	2, 0x0040
 274:	0b4c                	.insn	2, 0x0b4c
 276:	0040                	.insn	2, 0x0040
 278:	0b60                	.insn	2, 0x0b60
 27a:	0040                	.insn	2, 0x0040
 27c:	0b6c                	.insn	2, 0x0b6c
 27e:	0040                	.insn	2, 0x0040
 280:	0b80                	.insn	2, 0x0b80
 282:	0040                	.insn	2, 0x0040
 284:	0ba4                	.insn	2, 0x0ba4
 286:	0040                	.insn	2, 0x0040
 288:	0bb0                	.insn	2, 0x0bb0
 28a:	0040                	.insn	2, 0x0040
 28c:	0bbc                	.insn	2, 0x0bbc
 28e:	0040                	.insn	2, 0x0040
 290:	0bd0                	.insn	2, 0x0bd0
 292:	0040                	.insn	2, 0x0040
 294:	0be4                	.insn	2, 0x0be4
 296:	0040                	.insn	2, 0x0040
 298:	0bf0                	.insn	2, 0x0bf0
 29a:	0040                	.insn	2, 0x0040
 29c:	0c04                	.insn	2, 0x0c04
 29e:	0040                	.insn	2, 0x0040
 2a0:	0c28                	.insn	2, 0x0c28
 2a2:	0040                	.insn	2, 0x0040
 2a4:	0c34                	.insn	2, 0x0c34
 2a6:	0040                	.insn	2, 0x0040
 2a8:	0c40                	.insn	2, 0x0c40
 2aa:	0040                	.insn	2, 0x0040
 2ac:	0c54                	.insn	2, 0x0c54
 2ae:	0040                	.insn	2, 0x0040
 2b0:	0c68                	.insn	2, 0x0c68
 2b2:	0040                	.insn	2, 0x0040
 2b4:	0c74                	.insn	2, 0x0c74
 2b6:	0040                	.insn	2, 0x0040
 2b8:	0c88                	.insn	2, 0x0c88
 2ba:	0040                	.insn	2, 0x0040
 2bc:	0ca4                	.insn	2, 0x0ca4
 2be:	0040                	.insn	2, 0x0040
 2c0:	0cbc                	.insn	2, 0x0cbc
 2c2:	0040                	.insn	2, 0x0040
 2c4:	0cc4                	.insn	2, 0x0cc4
 2c6:	0040                	.insn	2, 0x0040
 2c8:	0ee8                	.insn	2, 0x0ee8
 2ca:	0040                	.insn	2, 0x0040
 2cc:	0d90                	.insn	2, 0x0d90
 2ce:	0040                	.insn	2, 0x0040
 2d0:	0f38                	.insn	2, 0x0f38
 2d2:	0040                	.insn	2, 0x0040
 2d4:	0dac                	.insn	2, 0x0dac
 2d6:	0040                	.insn	2, 0x0040
 2d8:	0dbc                	.insn	2, 0x0dbc
 2da:	0040                	.insn	2, 0x0040
 2dc:	0e9c                	.insn	2, 0x0e9c
 2de:	0040                	.insn	2, 0x0040
 2e0:	0eb0                	.insn	2, 0x0eb0
 2e2:	0040                	.insn	2, 0x0040
 2e4:	0ecc                	.insn	2, 0x0ecc
 2e6:	0040                	.insn	2, 0x0040
 2e8:	0f58                	.insn	2, 0x0f58
 2ea:	0040                	.insn	2, 0x0040
 2ec:	0d50                	.insn	2, 0x0d50
 2ee:	0040                	.insn	2, 0x0040
 2f0:	0f7c                	.insn	2, 0x0f7c
 2f2:	0040                	.insn	2, 0x0040
 2f4:	0f90                	.insn	2, 0x0f90
 2f6:	0040                	.insn	2, 0x0040
 2f8:	0fa4                	.insn	2, 0x0fa4
 2fa:	0040                	.insn	2, 0x0040
 2fc:	0fb0                	.insn	2, 0x0fb0
 2fe:	0040                	.insn	2, 0x0040
 300:	1048                	.insn	2, 0x1048
 302:	0040                	.insn	2, 0x0040
 304:	0fdc                	.insn	2, 0x0fdc
 306:	0040                	.insn	2, 0x0040
 308:	1008                	.insn	2, 0x1008
 30a:	0040                	.insn	2, 0x0040
 30c:	1028                	.insn	2, 0x1028
 30e:	0040                	.insn	2, 0x0040
 310:	105c                	.insn	2, 0x105c
 312:	0040                	.insn	2, 0x0040
 314:	1068                	.insn	2, 0x1068
 316:	0040                	.insn	2, 0x0040
 318:	1074                	.insn	2, 0x1074
 31a:	0040                	.insn	2, 0x0040
 31c:	1080                	.insn	2, 0x1080
 31e:	0040                	.insn	2, 0x0040
 320:	108c                	.insn	2, 0x108c
 322:	0040                	.insn	2, 0x0040
 324:	10a4                	.insn	2, 0x10a4
 326:	0040                	.insn	2, 0x0040
 328:	10f0                	.insn	2, 0x10f0
 32a:	0040                	.insn	2, 0x0040
 32c:	1108                	.insn	2, 0x1108
 32e:	0040                	.insn	2, 0x0040
 330:	1110                	.insn	2, 0x1110
 332:	0040                	.insn	2, 0x0040
 334:	1120                	.insn	2, 0x1120
 336:	0040                	.insn	2, 0x0040
 338:	112c                	.insn	2, 0x112c
 33a:	0040                	.insn	2, 0x0040
 33c:	1160                	.insn	2, 0x1160
 33e:	0040                	.insn	2, 0x0040
 340:	1190                	.insn	2, 0x1190
 342:	0040                	.insn	2, 0x0040
 344:	124c                	.insn	2, 0x124c
 346:	0040                	.insn	2, 0x0040
 348:	1268                	.insn	2, 0x1268
 34a:	0040                	.insn	2, 0x0040
 34c:	1288                	.insn	2, 0x1288
 34e:	0040                	.insn	2, 0x0040
 350:	129c                	.insn	2, 0x129c
 352:	0040                	.insn	2, 0x0040
 354:	12b0                	.insn	2, 0x12b0
 356:	0040                	.insn	2, 0x0040
 358:	12bc                	.insn	2, 0x12bc
 35a:	0040                	.insn	2, 0x0040
 35c:	0000                	.insn	2, 0x0000
 35e:	0040                	.insn	2, 0x0040
 360:	0f64                	.insn	2, 0x0f64
 362:	0040                	.insn	2, 0x0040
 364:	00e4                	.insn	2, 0x00e4
 366:	0000                	.insn	2, 0x0000
 368:	0005                	.insn	2, 0x0005
 36a:	0004                	.insn	2, 0x0004
 36c:	00402213          	slti	tp,zero,4
 370:	00402223          	sw	tp,4(zero) # 4 <start-0x3ffffc>
 374:	2194                	.insn	2, 0x2194
 376:	0040                	.insn	2, 0x0040
 378:	222c                	.insn	2, 0x222c
 37a:	0040                	.insn	2, 0x0040
 37c:	1f31                	.insn	2, 0x1f31
 37e:	0040                	.insn	2, 0x0040
 380:	00402237          	lui	tp,0x402
 384:	8244                	.insn	2, 0x8244
 386:	0040                	.insn	2, 0x0040
 388:	12c8                	.insn	2, 0x12c8
 38a:	0040                	.insn	2, 0x0040
 38c:	1324                	.insn	2, 0x1324
 38e:	0040                	.insn	2, 0x0040
 390:	135c                	.insn	2, 0x135c
 392:	0040                	.insn	2, 0x0040
 394:	12e4                	.insn	2, 0x12e4
 396:	0040                	.insn	2, 0x0040
 398:	1304                	.insn	2, 0x1304
 39a:	0040                	.insn	2, 0x0040
 39c:	1318                	.insn	2, 0x1318
 39e:	0040                	.insn	2, 0x0040
 3a0:	134c                	.insn	2, 0x134c
 3a2:	0040                	.insn	2, 0x0040
 3a4:	1388                	.insn	2, 0x1388
 3a6:	0040                	.insn	2, 0x0040
 3a8:	139c                	.insn	2, 0x139c
 3aa:	0040                	.insn	2, 0x0040
 3ac:	13b4                	.insn	2, 0x13b4
 3ae:	0040                	.insn	2, 0x0040
 3b0:	13dc                	.insn	2, 0x13dc
 3b2:	0040                	.insn	2, 0x0040
 3b4:	1418                	.insn	2, 0x1418
 3b6:	0040                	.insn	2, 0x0040
 3b8:	1470                	.insn	2, 0x1470
 3ba:	0040                	.insn	2, 0x0040
 3bc:	14cc                	.insn	2, 0x14cc
 3be:	0040                	.insn	2, 0x0040
 3c0:	154c                	.insn	2, 0x154c
 3c2:	0040                	.insn	2, 0x0040
 3c4:	16b4                	.insn	2, 0x16b4
 3c6:	0040                	.insn	2, 0x0040
 3c8:	14b8                	.insn	2, 0x14b8
 3ca:	0040                	.insn	2, 0x0040
 3cc:	14ec                	.insn	2, 0x14ec
 3ce:	0040                	.insn	2, 0x0040
 3d0:	1570                	.insn	2, 0x1570
 3d2:	0040                	.insn	2, 0x0040
 3d4:	1710                	.insn	2, 0x1710
 3d6:	0040                	.insn	2, 0x0040
 3d8:	1730                	.insn	2, 0x1730
 3da:	0040                	.insn	2, 0x0040
 3dc:	1774                	.insn	2, 0x1774
 3de:	0040                	.insn	2, 0x0040
 3e0:	17f4                	.insn	2, 0x17f4
 3e2:	0040                	.insn	2, 0x0040
 3e4:	1764                	.insn	2, 0x1764
 3e6:	0040                	.insn	2, 0x0040
 3e8:	1794                	.insn	2, 0x1794
 3ea:	0040                	.insn	2, 0x0040
 3ec:	183c                	.insn	2, 0x183c
 3ee:	0040                	.insn	2, 0x0040
 3f0:	18ac                	.insn	2, 0x18ac
 3f2:	0040                	.insn	2, 0x0040
 3f4:	18bc                	.insn	2, 0x18bc
 3f6:	0040                	.insn	2, 0x0040
 3f8:	18cc                	.insn	2, 0x18cc
 3fa:	0040                	.insn	2, 0x0040
 3fc:	18dc                	.insn	2, 0x18dc
 3fe:	0040                	.insn	2, 0x0040
 400:	18ec                	.insn	2, 0x18ec
 402:	0040                	.insn	2, 0x0040
 404:	18fc                	.insn	2, 0x18fc
 406:	0040                	.insn	2, 0x0040
 408:	190c                	.insn	2, 0x190c
 40a:	0040                	.insn	2, 0x0040
 40c:	191c                	.insn	2, 0x191c
 40e:	0040                	.insn	2, 0x0040
 410:	1930                	.insn	2, 0x1930
 412:	0040                	.insn	2, 0x0040
 414:	1950                	.insn	2, 0x1950
 416:	0040                	.insn	2, 0x0040
 418:	1960                	.insn	2, 0x1960
 41a:	0040                	.insn	2, 0x0040
 41c:	199c                	.insn	2, 0x199c
 41e:	0040                	.insn	2, 0x0040
 420:	19ac                	.insn	2, 0x19ac
 422:	0040                	.insn	2, 0x0040
 424:	19b8                	.insn	2, 0x19b8
 426:	0040                	.insn	2, 0x0040
 428:	19f4                	.insn	2, 0x19f4
 42a:	0040                	.insn	2, 0x0040
 42c:	1a24                	.insn	2, 0x1a24
 42e:	0040                	.insn	2, 0x0040
 430:	1afc                	.insn	2, 0x1afc
 432:	0040                	.insn	2, 0x0040
 434:	19e0                	.insn	2, 0x19e0
 436:	0040                	.insn	2, 0x0040
 438:	1a1c                	.insn	2, 0x1a1c
 43a:	0040                	.insn	2, 0x0040
 43c:	1d00                	.insn	2, 0x1d00
 43e:	0040                	.insn	2, 0x0040
 440:	1d10                	.insn	2, 0x1d10
 442:	0040                	.insn	2, 0x0040
 444:	1d20                	.insn	2, 0x1d20
 446:	0040                	.insn	2, 0x0040
 448:	1d40                	.insn	2, 0x1d40
 44a:	0040                	.insn	2, 0x0040

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
  70:	98020593          	addi	a1,tp,-1664 # 401980 <fat32_ls+0x250>
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
  a0:	000c                	.insn	2, 0x000c
  a2:	0000                	.insn	2, 0x0000
  a4:	007c                	.insn	2, 0x007c
  a6:	0000                	.insn	2, 0x0000
  a8:	0a48                	.insn	2, 0x0a48
  aa:	0040                	.insn	2, 0x0040
  ac:	027c                	.insn	2, 0x027c
  ae:	0000                	.insn	2, 0x0000
  b0:	0024                	.insn	2, 0x0024
  b2:	0000                	.insn	2, 0x0000
  b4:	007c                	.insn	2, 0x007c
  b6:	0000                	.insn	2, 0x0000
  b8:	0cc4                	.insn	2, 0x0cc4
  ba:	0040                	.insn	2, 0x0040
  bc:	02b8                	.insn	2, 0x02b8
  be:	0000                	.insn	2, 0x0000
  c0:	0e44                	.insn	2, 0x0e44
  c2:	5040                	.insn	2, 0x5040
  c4:	0988                	.insn	2, 0x0988
  c6:	0a89                	.insn	2, 0x0a89
  c8:	0b92                	.insn	2, 0x0b92
  ca:	9c030c93          	addi	s9,t1,-1600
  ce:	c802                	.insn	2, 0xc802
  d0:	d2c9                	.insn	2, 0xd2c9
  d2:	000e44d3          	.insn	4, 0x000e44d3
  d6:	0000                	.insn	2, 0x0000
  d8:	000c                	.insn	2, 0x000c
  da:	0000                	.insn	2, 0x0000
  dc:	007c                	.insn	2, 0x007c
  de:	0000                	.insn	2, 0x0000
  e0:	0f7c                	.insn	2, 0x0f7c
  e2:	0040                	.insn	2, 0x0040
  e4:	0014                	.insn	2, 0x0014
  e6:	0000                	.insn	2, 0x0000
  e8:	000c                	.insn	2, 0x000c
  ea:	0000                	.insn	2, 0x0000
  ec:	007c                	.insn	2, 0x007c
  ee:	0000                	.insn	2, 0x0000
  f0:	0f90                	.insn	2, 0x0f90
  f2:	0040                	.insn	2, 0x0040
  f4:	0014                	.insn	2, 0x0014
  f6:	0000                	.insn	2, 0x0000
  f8:	000c                	.insn	2, 0x000c
  fa:	0000                	.insn	2, 0x0000
  fc:	007c                	.insn	2, 0x007c
  fe:	0000                	.insn	2, 0x0000
 100:	0fa4                	.insn	2, 0x0fa4
 102:	0040                	.insn	2, 0x0040
 104:	000c                	.insn	2, 0x000c
 106:	0000                	.insn	2, 0x0000
 108:	0024                	.insn	2, 0x0024
 10a:	0000                	.insn	2, 0x0000
 10c:	007c                	.insn	2, 0x007c
 10e:	0000                	.insn	2, 0x0000
 110:	0fb0                	.insn	2, 0x0fb0
 112:	0040                	.insn	2, 0x0040
 114:	00ac                	.insn	2, 0x00ac
 116:	0000                	.insn	2, 0x0000
 118:	0e44                	.insn	2, 0x0e44
 11a:	4c20                	.insn	2, 0x4c20
 11c:	0181                	.insn	2, 0x0181
 11e:	0288                	.insn	2, 0x0288
 120:	0389                	.insn	2, 0x0389
 122:	020a                	.insn	2, 0x020a
 124:	c158                	.insn	2, 0xc158
 126:	c9c8                	.insn	2, 0xc9c8
 128:	0e44                	.insn	2, 0x0e44
 12a:	4400                	.insn	2, 0x4400
 12c:	0000000b          	.insn	4, 0x000b
 130:	000c                	.insn	2, 0x000c
 132:	0000                	.insn	2, 0x0000
 134:	007c                	.insn	2, 0x007c
 136:	0000                	.insn	2, 0x0000
 138:	105c                	.insn	2, 0x105c
 13a:	0040                	.insn	2, 0x0040
 13c:	000c                	.insn	2, 0x000c
 13e:	0000                	.insn	2, 0x0000
 140:	000c                	.insn	2, 0x000c
 142:	0000                	.insn	2, 0x0000
 144:	007c                	.insn	2, 0x007c
 146:	0000                	.insn	2, 0x0000
 148:	1068                	.insn	2, 0x1068
 14a:	0040                	.insn	2, 0x0040
 14c:	000c                	.insn	2, 0x000c
 14e:	0000                	.insn	2, 0x0000
 150:	000c                	.insn	2, 0x000c
 152:	0000                	.insn	2, 0x0000
 154:	007c                	.insn	2, 0x007c
 156:	0000                	.insn	2, 0x0000
 158:	1074                	.insn	2, 0x1074
 15a:	0040                	.insn	2, 0x0040
 15c:	000c                	.insn	2, 0x000c
 15e:	0000                	.insn	2, 0x0000
 160:	000c                	.insn	2, 0x000c
 162:	0000                	.insn	2, 0x0000
 164:	007c                	.insn	2, 0x007c
 166:	0000                	.insn	2, 0x0000
 168:	1080                	.insn	2, 0x1080
 16a:	0040                	.insn	2, 0x0040
 16c:	000c                	.insn	2, 0x000c
 16e:	0000                	.insn	2, 0x0000
 170:	0020                	.insn	2, 0x0020
 172:	0000                	.insn	2, 0x0000
 174:	007c                	.insn	2, 0x007c
 176:	0000                	.insn	2, 0x0000
 178:	108c                	.insn	2, 0x108c
 17a:	0040                	.insn	2, 0x0040
 17c:	0084                	.insn	2, 0x0084
 17e:	0000                	.insn	2, 0x0000
 180:	0e44                	.insn	2, 0x0e44
 182:	4410                	.insn	2, 0x4410
 184:	0181                	.insn	2, 0x0181
 186:	020a                	.insn	2, 0x020a
 188:	c158                	.insn	2, 0xc158
 18a:	0e44                	.insn	2, 0x0e44
 18c:	4800                	.insn	2, 0x4800
 18e:	44c14c0b          	.insn	4, 0x44c14c0b
 192:	000e                	.insn	2, 0x000e
 194:	000c                	.insn	2, 0x000c
 196:	0000                	.insn	2, 0x0000
 198:	007c                	.insn	2, 0x007c
 19a:	0000                	.insn	2, 0x0000
 19c:	1110                	.insn	2, 0x1110
 19e:	0040                	.insn	2, 0x0040
 1a0:	0010                	.insn	2, 0x0010
 1a2:	0000                	.insn	2, 0x0000
 1a4:	000c                	.insn	2, 0x000c
 1a6:	0000                	.insn	2, 0x0000
 1a8:	007c                	.insn	2, 0x007c
 1aa:	0000                	.insn	2, 0x0000
 1ac:	1120                	.insn	2, 0x1120
 1ae:	0040                	.insn	2, 0x0040
 1b0:	000c                	.insn	2, 0x000c
 1b2:	0000                	.insn	2, 0x0000
 1b4:	000c                	.insn	2, 0x000c
 1b6:	0000                	.insn	2, 0x0000
 1b8:	007c                	.insn	2, 0x007c
 1ba:	0000                	.insn	2, 0x0000
 1bc:	112c                	.insn	2, 0x112c
 1be:	0040                	.insn	2, 0x0040
 1c0:	0034                	.insn	2, 0x0034
 1c2:	0000                	.insn	2, 0x0000
 1c4:	000c                	.insn	2, 0x000c
 1c6:	0000                	.insn	2, 0x0000
 1c8:	007c                	.insn	2, 0x007c
 1ca:	0000                	.insn	2, 0x0000
 1cc:	1160                	.insn	2, 0x1160
 1ce:	0040                	.insn	2, 0x0040
 1d0:	0030                	.insn	2, 0x0030
 1d2:	0000                	.insn	2, 0x0000
 1d4:	000c                	.insn	2, 0x000c
 1d6:	0000                	.insn	2, 0x0000
 1d8:	007c                	.insn	2, 0x007c
 1da:	0000                	.insn	2, 0x0000
 1dc:	1190                	.insn	2, 0x1190
 1de:	0040                	.insn	2, 0x0040
 1e0:	00bc                	.insn	2, 0x00bc
 1e2:	0000                	.insn	2, 0x0000
 1e4:	000c                	.insn	2, 0x000c
 1e6:	0000                	.insn	2, 0x0000
 1e8:	007c                	.insn	2, 0x007c
 1ea:	0000                	.insn	2, 0x0000
 1ec:	124c                	.insn	2, 0x124c
 1ee:	0040                	.insn	2, 0x0040
 1f0:	003c                	.insn	2, 0x003c
 1f2:	0000                	.insn	2, 0x0000
 1f4:	000c                	.insn	2, 0x000c
 1f6:	0000                	.insn	2, 0x0000
 1f8:	007c                	.insn	2, 0x007c
 1fa:	0000                	.insn	2, 0x0000
 1fc:	1288                	.insn	2, 0x1288
 1fe:	0040                	.insn	2, 0x0040
 200:	0014                	.insn	2, 0x0014
 202:	0000                	.insn	2, 0x0000
 204:	000c                	.insn	2, 0x000c
 206:	0000                	.insn	2, 0x0000
 208:	007c                	.insn	2, 0x007c
 20a:	0000                	.insn	2, 0x0000
 20c:	129c                	.insn	2, 0x129c
 20e:	0040                	.insn	2, 0x0040
 210:	0014                	.insn	2, 0x0014
 212:	0000                	.insn	2, 0x0000
 214:	000c                	.insn	2, 0x000c
 216:	0000                	.insn	2, 0x0000
 218:	007c                	.insn	2, 0x007c
 21a:	0000                	.insn	2, 0x0000
 21c:	12b0                	.insn	2, 0x12b0
 21e:	0040                	.insn	2, 0x0040
 220:	000c                	.insn	2, 0x000c
 222:	0000                	.insn	2, 0x0000
 224:	000c                	.insn	2, 0x000c
 226:	0000                	.insn	2, 0x0000
 228:	007c                	.insn	2, 0x007c
 22a:	0000                	.insn	2, 0x0000
 22c:	12bc                	.insn	2, 0x12bc
 22e:	0040                	.insn	2, 0x0040
 230:	000c                	.insn	2, 0x000c
 232:	0000                	.insn	2, 0x0000
 234:	000c                	.insn	2, 0x000c
 236:	0000                	.insn	2, 0x0000
 238:	007c                	.insn	2, 0x007c
 23a:	0000                	.insn	2, 0x0000
 23c:	0000                	.insn	2, 0x0000
 23e:	0040                	.insn	2, 0x0040
 240:	001c                	.insn	2, 0x001c
 242:	0000                	.insn	2, 0x0000
 244:	0010                	.insn	2, 0x0010
 246:	0000                	.insn	2, 0x0000
 248:	ffff                	.insn	2, 0xffff
 24a:	ffff                	.insn	2, 0xffff
 24c:	0004                	.insn	2, 0x0004
 24e:	0004                	.insn	2, 0x0004
 250:	7c01                	.insn	2, 0x7c01
 252:	0c01                	.insn	2, 0x0c01
 254:	0002                	.insn	2, 0x0002
 256:	0000                	.insn	2, 0x0000
 258:	0020                	.insn	2, 0x0020
 25a:	0000                	.insn	2, 0x0000
 25c:	0244                	.insn	2, 0x0244
 25e:	0000                	.insn	2, 0x0000
 260:	12c8                	.insn	2, 0x12c8
 262:	0040                	.insn	2, 0x0040
 264:	00ec                	.insn	2, 0x00ec
 266:	0000                	.insn	2, 0x0000
 268:	0e44                	.insn	2, 0x0e44
 26a:	04a0                	.insn	2, 0x04a0
 26c:	814c                	.insn	2, 0x814c
 26e:	8801                	.insn	2, 0x8801
 270:	8902                	.insn	2, 0x8902
 272:	c1d40203          	lb	tp,-995(s0)
 276:	c9c8                	.insn	2, 0xc9c8
 278:	0e44                	.insn	2, 0x0e44
 27a:	0000                	.insn	2, 0x0000
 27c:	0024                	.insn	2, 0x0024
 27e:	0000                	.insn	2, 0x0000
 280:	0244                	.insn	2, 0x0244
 282:	0000                	.insn	2, 0x0000
 284:	13b4                	.insn	2, 0x13b4
 286:	0040                	.insn	2, 0x0040
 288:	00bc                	.insn	2, 0x00bc
 28a:	0000                	.insn	2, 0x0000
 28c:	0e44                	.insn	2, 0x0e44
 28e:	5010                	.insn	2, 0x5010
 290:	0181                	.insn	2, 0x0181
 292:	0288                	.insn	2, 0x0288
 294:	0389                	.insn	2, 0x0389
 296:	0492                	.insn	2, 0x0492
 298:	a002                	.insn	2, 0xa002
 29a:	c8c1                	.insn	2, 0xc8c1
 29c:	d2c9                	.insn	2, 0xd2c9
 29e:	0e44                	.insn	2, 0x0e44
 2a0:	0000                	.insn	2, 0x0000
 2a2:	0000                	.insn	2, 0x0000
 2a4:	003c                	.insn	2, 0x003c
 2a6:	0000                	.insn	2, 0x0000
 2a8:	0244                	.insn	2, 0x0244
 2aa:	0000                	.insn	2, 0x0000
 2ac:	1470                	.insn	2, 0x1470
 2ae:	0040                	.insn	2, 0x0040
 2b0:	02a0                	.insn	2, 0x02a0
 2b2:	0000                	.insn	2, 0x0000
 2b4:	0e44                	.insn	2, 0x0e44
 2b6:	7040                	.insn	2, 0x7040
 2b8:	0181                	.insn	2, 0x0181
 2ba:	0288                	.insn	2, 0x0288
 2bc:	0389                	.insn	2, 0x0389
 2be:	0492                	.insn	2, 0x0492
 2c0:	06940593          	addi	a1,s0,105
 2c4:	0795                	.insn	2, 0x0795
 2c6:	0896                	.insn	2, 0x0896
 2c8:	0a980997          	auipc	s3,0xa980
 2cc:	0b99                	.insn	2, 0x0b99
 2ce:	0c9a                	.insn	2, 0x0c9a
 2d0:	020a                	.insn	2, 0x020a
 2d2:	c180                	.insn	2, 0xc180
 2d4:	c9c8                	.insn	2, 0xc9c8
 2d6:	d3d2                	.insn	2, 0xd3d2
 2d8:	d5d4                	.insn	2, 0xd5d4
 2da:	d7d6                	.insn	2, 0xd7d6
 2dc:	d9d8                	.insn	2, 0xd9d8
 2de:	44da                	.insn	2, 0x44da
 2e0:	000e                	.insn	2, 0x000e
 2e2:	0b44                	.insn	2, 0x0b44
 2e4:	000c                	.insn	2, 0x000c
 2e6:	0000                	.insn	2, 0x0000
 2e8:	0244                	.insn	2, 0x0244
 2ea:	0000                	.insn	2, 0x0000
 2ec:	1710                	.insn	2, 0x1710
 2ee:	0040                	.insn	2, 0x0040
 2f0:	0020                	.insn	2, 0x0020
 2f2:	0000                	.insn	2, 0x0000
 2f4:	0038                	.insn	2, 0x0038
 2f6:	0000                	.insn	2, 0x0000
 2f8:	0244                	.insn	2, 0x0244
 2fa:	0000                	.insn	2, 0x0000
 2fc:	1730                	.insn	2, 0x1730
 2fe:	0040                	.insn	2, 0x0040
 300:	0288                	.insn	2, 0x0288
 302:	0000                	.insn	2, 0x0000
 304:	0e44                	.insn	2, 0x0e44
 306:	6830                	.insn	2, 0x6830
 308:	0181                	.insn	2, 0x0181
 30a:	0288                	.insn	2, 0x0288
 30c:	0389                	.insn	2, 0x0389
 30e:	0492                	.insn	2, 0x0492
 310:	06940593          	addi	a1,s0,105
 314:	0795                	.insn	2, 0x0795
 316:	0896                	.insn	2, 0x0896
 318:	0a980997          	auipc	s3,0xa980
 31c:	020a                	.insn	2, 0x020a
 31e:	c164                	.insn	2, 0xc164
 320:	c9c8                	.insn	2, 0xc9c8
 322:	d3d2                	.insn	2, 0xd3d2
 324:	d5d4                	.insn	2, 0xd5d4
 326:	d7d6                	.insn	2, 0xd7d6
 328:	44d8                	.insn	2, 0x44d8
 32a:	000e                	.insn	2, 0x000e
 32c:	0b44                	.insn	2, 0x0b44
 32e:	0000                	.insn	2, 0x0000
 330:	0028                	.insn	2, 0x0028
 332:	0000                	.insn	2, 0x0000
 334:	0244                	.insn	2, 0x0244
 336:	0000                	.insn	2, 0x0000
 338:	19b8                	.insn	2, 0x19b8
 33a:	0040                	.insn	2, 0x0040
 33c:	03b0                	.insn	2, 0x03b0
 33e:	0000                	.insn	2, 0x0000
 340:	0e44                	.insn	2, 0x0e44
 342:	5830                	.insn	2, 0x5830
 344:	0181                	.insn	2, 0x0181
 346:	0288                	.insn	2, 0x0288
 348:	0389                	.insn	2, 0x0389
 34a:	0492                	.insn	2, 0x0492
 34c:	06940593          	addi	a1,s0,105
 350:	c1038c03          	lb	s8,-1008(t2)
 354:	c9c8                	.insn	2, 0xc9c8
 356:	d3d2                	.insn	2, 0xd3d2
 358:	44d4                	.insn	2, 0x44d4
 35a:	000e                	.insn	2, 0x000e

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
      60:	ec01                	.insn	2, 0xec01
      62:	1904                	.insn	2, 0x1904
      64:	6777f1e7          	.insn	4, 0x6777f1e7
      68:	5866                	.insn	2, 0x5866
      6a:	b001                	.insn	2, 0xb001
      6c:	336d                	.insn	2, 0x336d
      6e:	baae                	.insn	2, 0xbaae
      70:	4e9e                	.insn	2, 0x4e9e
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
      aa:	054a1e03          	lh	t3,84(s4) # 307fc <start-0x3cf804>
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
     3a8:	4a02d503          	lhu	a0,1184(t0) # 4a0 <start-0x3ffb60>
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
     6f6:	7e01                	.insn	2, 0x7e01
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
     71c:	5600                	.insn	2, 0x5600
     71e:	0000                	.insn	2, 0x0000
     720:	3500                	.insn	2, 0x3500
     722:	0000                	.insn	2, 0x0000
     724:	0300                	.insn	2, 0x0300
     726:	1f01                	.insn	2, 0x1f01
     728:	0f02                	.insn	2, 0x0f02
     72a:	1e05                	.insn	2, 0x1e05
     72c:	7c06                	.insn	2, 0x7c06
     72e:	0000                	.insn	2, 0x0000
     730:	0000                	.insn	2, 0x0000
     732:	00dd                	.insn	2, 0x00dd
     734:	f2d66d1b          	.insn	4, 0xf2d66d1b
     738:	0d42                	.insn	2, 0x0d42
     73a:	e4e4                	.insn	2, 0xe4e4
     73c:	d829                	.insn	2, 0xd829
     73e:	a24e                	.insn	2, 0xa24e
     740:	7eb1                	.insn	2, 0x7eb1
     742:	00000087          	.insn	4, 0x0087
     746:	a401                	.insn	2, 0xa401
     748:	6a7a                	.insn	2, 0x6a7a
     74a:	7f6c                	.insn	2, 0x7f6c
     74c:	7627c6cb          	.insn	4, 0x7627c6cb
     750:	abe67d23          	.insn	4, 0xabe67d23
     754:	95ac                	.insn	2, 0x95ac
     756:	8049                	.insn	2, 0x8049
     758:	0000                	.insn	2, 0x0000
     75a:	0200                	.insn	2, 0x0200
     75c:	00dd                	.insn	2, 0x00dd
     75e:	f2d66d1b          	.insn	4, 0xf2d66d1b
     762:	0d42                	.insn	2, 0x0d42
     764:	e4e4                	.insn	2, 0xe4e4
     766:	d829                	.insn	2, 0xd829
     768:	a24e                	.insn	2, 0xa24e
     76a:	7eb1                	.insn	2, 0x7eb1
     76c:	00000047          	.insn	4, 0x0047
     770:	ec02                	.insn	2, 0xec02
     772:	1904                	.insn	2, 0x1904
     774:	6777f1e7          	.insn	4, 0x6777f1e7
     778:	5866                	.insn	2, 0x5866
     77a:	b001                	.insn	2, 0xb001
     77c:	336d                	.insn	2, 0x336d
     77e:	baae                	.insn	2, 0xbaae
     780:	4e9e                	.insn	2, 0x4e9e
     782:	0000                	.insn	2, 0x0000
     784:	0200                	.insn	2, 0x0200
     786:	8925                	.insn	2, 0x8925
     788:	ef25                	.insn	2, 0xef25
     78a:	9699                	.insn	2, 0x9699
     78c:	84d0                	.insn	2, 0x84d0
     78e:	8c71                	.insn	2, 0x8c71
     790:	b17c                	.insn	2, 0xb17c
     792:	b91c                	.insn	2, 0xb91c
     794:	0090e2fb          	.insn	4, 0x0090e2fb
     798:	0000                	.insn	2, 0x0000
     79a:	6802                	.insn	2, 0x6802
     79c:	3bb5                	.insn	2, 0x3bb5
     79e:	3f18                	.insn	2, 0x3f18
     7a0:	316ffc03          	.insn	4, 0x316ffc03
     7a4:	7ed9                	.insn	2, 0x7ed9
     7a6:	00ce                	.insn	2, 0x00ce
     7a8:	290a                	.insn	2, 0x290a
     7aa:	0451                	.insn	2, 0x0451
     7ac:	0502                	.insn	2, 0x0502
     7ae:	0a05                	.insn	2, 0x0a05
     7b0:	0500                	.insn	2, 0x0500
     7b2:	3002                	.insn	2, 0x3002
     7b4:	400a                	.insn	2, 0x400a
     7b6:	0300                	.insn	2, 0x0300
     7b8:	00c0                	.insn	2, 0x00c0
     7ba:	0301                	.insn	2, 0x0301
     7bc:	053c0813          	addi	a6,s8,83
     7c0:	0300                	.insn	2, 0x0300
     7c2:	0925                	.insn	2, 0x0925
     7c4:	0004                	.insn	2, 0x0004
     7c6:	0501                	.insn	2, 0x0501
     7c8:	0a1a                	.insn	2, 0x0a1a
     7ca:	8203064f          	.insn	4, 0x8203064f
     7ce:	097f 000c 0301 00fe 	.insn	10, 0x034a00fe0301000c097f
     7d6:	034a 
     7d8:	7f82                	.insn	2, 0x7f82
     7da:	0409                	.insn	2, 0x0409
     7dc:	0100                	.insn	2, 0x0100
     7de:	0505                	.insn	2, 0x0505
     7e0:	0306                	.insn	2, 0x0306
     7e2:	0185                	.insn	2, 0x0185
     7e4:	054a                	.insn	2, 0x054a
     7e6:	0809                	.insn	2, 0x0809
     7e8:	06e5                	.insn	2, 0x06e5
     7ea:	ba7efa03          	.insn	4, 0xba7efa03
     7ee:	1f05                	.insn	2, 0x1f05
     7f0:	0306                	.insn	2, 0x0306
     7f2:	018a                	.insn	2, 0x018a
     7f4:	3c08                	.insn	2, 0x3c08
     7f6:	1d05                	.insn	2, 0x1d05
     7f8:	4a06                	.insn	2, 0x4a06
     7fa:	1f05                	.insn	2, 0x1f05
     7fc:	4906                	.insn	2, 0x4906
     7fe:	1d05                	.insn	2, 0x1d05
     800:	054c                	.insn	2, 0x054c
     802:	4520                	.insn	2, 0x4520
     804:	1f05                	.insn	2, 0x1f05
     806:	054d                	.insn	2, 0x054d
     808:	4720                	.insn	2, 0x4720
     80a:	1d05                	.insn	2, 0x1d05
     80c:	054d                	.insn	2, 0x054d
     80e:	4720                	.insn	2, 0x4720
     810:	0905                	.insn	2, 0x0905
     812:	ba06                	.insn	2, 0xba06
     814:	2b05                	.insn	2, 0x2b05
     816:	0306                	.insn	2, 0x0306
     818:	097f 0004 0501 0605 	.insn	10, 0x034a060505010004097f
     820:	034a 
     822:	14097efb          	.insn	4, 0x14097efb
     826:	0100                	.insn	2, 0x0100
     828:	0306                	.insn	2, 0x0306
     82a:	04d2                	.insn	2, 0x04d2
     82c:	064a                	.insn	2, 0x064a
     82e:	087bae03          	lw	t3,135(s7)
     832:	0374                	.insn	2, 0x0374
     834:	04d2                	.insn	2, 0x04d2
     836:	0682                	.insn	2, 0x0682
     838:	ac084303          	lbu	t1,-1344(a6)
     83c:	ba06                	.insn	2, 0xba06
     83e:	0905                	.insn	2, 0x0905
     840:	0306                	.insn	2, 0x0306
     842:	7d86                	.insn	2, 0x7d86
     844:	3c08                	.insn	2, 0x3c08
     846:	0306                	.insn	2, 0x0306
     848:	7ee5                	.insn	2, 0x7ee5
     84a:	05ba                	.insn	2, 0x05ba
     84c:	061c                	.insn	2, 0x061c
     84e:	4a019c03          	lh	s8,1184(gp)
     852:	0505                	.insn	2, 0x0505
     854:	4a03a103          	lw	sp,1184(t2)
     858:	05ba5803          	lhu	a6,91(s4) # 1205421d <USER_MAX+0x11b5421d>
     85c:	0320                	.insn	2, 0x0320
     85e:	7d86                	.insn	2, 0x7d86
     860:	05ba                	.insn	2, 0x05ba
     862:	0609                	.insn	2, 0x0609
     864:	054a                	.insn	2, 0x054a
     866:	0605                	.insn	2, 0x0605
     868:	0902fa03          	.insn	4, 0x0902fa03
     86c:	0004                	.insn	2, 0x0004
     86e:	0501                	.insn	2, 0x0501
     870:	7d85032b          	.insn	4, 0x7d85032b
     874:	05ba                	.insn	2, 0x05ba
     876:	0605                	.insn	2, 0x0605
     878:	034a                	.insn	2, 0x034a
     87a:	7ee6                	.insn	2, 0x7ee6
     87c:	0809                	.insn	2, 0x0809
     87e:	0100                	.insn	2, 0x0100
     880:	0306                	.insn	2, 0x0306
     882:	0495                	.insn	2, 0x0495
     884:	06ba                	.insn	2, 0x06ba
     886:	baba                	.insn	2, 0xbaba
     888:	0905                	.insn	2, 0x0905
     88a:	0306                	.insn	2, 0x0306
     88c:	7d92                	.insn	2, 0x7d92
     88e:	3c08                	.insn	2, 0x3c08
     890:	0306                	.insn	2, 0x0306
     892:	7ed9                	.insn	2, 0x7ed9
     894:	05ba                	.insn	2, 0x05ba
     896:	061c                	.insn	2, 0x061c
     898:	4a01a803          	lw	a6,1184(gp)
     89c:	0505                	.insn	2, 0x0505
     89e:	4a039503          	lh	a0,1184(t2)
     8a2:	05ba5803          	lhu	a6,91(s4)
     8a6:	0320                	.insn	2, 0x0320
     8a8:	7d92                	.insn	2, 0x7d92
     8aa:	05ba                	.insn	2, 0x05ba
     8ac:	0609                	.insn	2, 0x0609
     8ae:	054a                	.insn	2, 0x054a
     8b0:	0605                	.insn	2, 0x0605
     8b2:	0902ee03          	.insn	4, 0x0902ee03
     8b6:	0004                	.insn	2, 0x0004
     8b8:	0501                	.insn	2, 0x0501
     8ba:	7d91032b          	.insn	4, 0x7d91032b
     8be:	05ba                	.insn	2, 0x05ba
     8c0:	0605                	.insn	2, 0x0605
     8c2:	034a                	.insn	2, 0x034a
     8c4:	7eda                	.insn	2, 0x7eda
     8c6:	0809                	.insn	2, 0x0809
     8c8:	0100                	.insn	2, 0x0100
     8ca:	0306                	.insn	2, 0x0306
     8cc:	0495                	.insn	2, 0x0495
     8ce:	06ba                	.insn	2, 0x06ba
     8d0:	baba                	.insn	2, 0xbaba
     8d2:	0905                	.insn	2, 0x0905
     8d4:	0306                	.insn	2, 0x0306
     8d6:	7d9e                	.insn	2, 0x7d9e
     8d8:	3c08                	.insn	2, 0x3c08
     8da:	0306                	.insn	2, 0x0306
     8dc:	7ecd                	.insn	2, 0x7ecd
     8de:	05ba                	.insn	2, 0x05ba
     8e0:	061c                	.insn	2, 0x061c
     8e2:	4a01b403          	.insn	4, 0x4a01b403
     8e6:	0505                	.insn	2, 0x0505
     8e8:	4a038903          	lb	s2,1184(t2)
     8ec:	05ba5803          	lhu	a6,91(s4)
     8f0:	0320                	.insn	2, 0x0320
     8f2:	7d9e                	.insn	2, 0x7d9e
     8f4:	05ba                	.insn	2, 0x05ba
     8f6:	0609                	.insn	2, 0x0609
     8f8:	054a                	.insn	2, 0x054a
     8fa:	0605                	.insn	2, 0x0605
     8fc:	0902e203          	.insn	4, 0x0902e203
     900:	0004                	.insn	2, 0x0004
     902:	0501                	.insn	2, 0x0501
     904:	7d9d032b          	.insn	4, 0x7d9d032b
     908:	05ba                	.insn	2, 0x05ba
     90a:	0605                	.insn	2, 0x0605
     90c:	034a                	.insn	2, 0x034a
     90e:	7ece                	.insn	2, 0x7ece
     910:	0809                	.insn	2, 0x0809
     912:	0100                	.insn	2, 0x0100
     914:	0306                	.insn	2, 0x0306
     916:	0495                	.insn	2, 0x0495
     918:	054a                	.insn	2, 0x054a
     91a:	0301                	.insn	2, 0x0301
     91c:	7da6                	.insn	2, 0x7da6
     91e:	05ba                	.insn	2, 0x05ba
     920:	0309                	.insn	2, 0x0309
     922:	4a46                	.insn	2, 0x4a46
     924:	0005                	.insn	2, 0x0005
     926:	0901ea03          	.insn	4, 0x0901ea03
     92a:	0010                	.insn	2, 0x0010
     92c:	0501                	.insn	2, 0x0501
     92e:	0a05                	.insn	2, 0x0a05
     930:	6402                	.insn	2, 0x6402
     932:	0514                	.insn	2, 0x0514
     934:	080d                	.insn	2, 0x080d
     936:	0541                	.insn	2, 0x0541
     938:	030c                	.insn	2, 0x030c
     93a:	093c                	.insn	2, 0x093c
     93c:	0004                	.insn	2, 0x0004
     93e:	0301                	.insn	2, 0x0301
     940:	4a41                	.insn	2, 0x4a41
     942:	0505                	.insn	2, 0x0505
     944:	4a06                	.insn	2, 0x4a06
     946:	0306                	.insn	2, 0x0306
     948:	01a6                	.insn	2, 0x01a6
     94a:	0809                	.insn	2, 0x0809
     94c:	0100                	.insn	2, 0x0100
     94e:	0c05                	.insn	2, 0x0c05
     950:	ba7f9903          	lh	s2,-1113(t6)
     954:	0505                	.insn	2, 0x0505
     956:	054a4103          	lbu	sp,84(s4)
     95a:	4d15                	.insn	2, 0x4d15
     95c:	1005                	.insn	2, 0x1005
     95e:	0549                	.insn	2, 0x0549
     960:	4b0d                	.insn	2, 0x4b0d
     962:	2105                	.insn	2, 0x2105
     964:	0c091003          	lh	zero,192(s2)
     968:	0100                	.insn	2, 0x0100
     96a:	1f05                	.insn	2, 0x1f05
     96c:	05f5                	.insn	2, 0x05f5
     96e:	090d031b          	.insn	4, 0x090d031b
     972:	0004                	.insn	2, 0x0004
     974:	0501                	.insn	2, 0x0501
     976:	0305                	.insn	2, 0x0305
     978:	04090183          	lb	gp,64(s2)
     97c:	0100                	.insn	2, 0x0100
     97e:	0c05                	.insn	2, 0x0c05
     980:	ba7f9903          	lh	s2,-1113(t6)
     984:	0505                	.insn	2, 0x0505
     986:	054a4103          	lbu	sp,84(s4)
     98a:	4d0d                	.insn	2, 0x4d0d
     98c:	2605                	.insn	2, 0x2605
     98e:	08093103          	.insn	4, 0x08093103
     992:	0100                	.insn	2, 0x0100
     994:	3205                	.insn	2, 0x3205
     996:	05f4                	.insn	2, 0x05f4
     998:	4b21                	.insn	2, 0x4b21
     99a:	3e05                	.insn	2, 0x3e05
     99c:	0581                	.insn	2, 0x0581
     99e:	8321                	.insn	2, 0x8321
     9a0:	0505                	.insn	2, 0x0505
     9a2:	4a00ef03          	.insn	4, 0x4a00ef03
     9a6:	2105                	.insn	2, 0x2105
     9a8:	ba7f9103          	lh	sp,-1113(t6)
     9ac:	3e05                	.insn	2, 0x3e05
     9ae:	0549                	.insn	2, 0x0549
     9b0:	8321                	.insn	2, 0x8321
     9b2:	0505                	.insn	2, 0x0505
     9b4:	4a00ef03          	.insn	4, 0x4a00ef03
     9b8:	2105                	.insn	2, 0x2105
     9ba:	ba7f9103          	lh	sp,-1113(t6)
     9be:	3e05                	.insn	2, 0x3e05
     9c0:	0549                	.insn	2, 0x0549
     9c2:	8321                	.insn	2, 0x8321
     9c4:	0505                	.insn	2, 0x0505
     9c6:	4a00ef03          	.insn	4, 0x4a00ef03
     9ca:	2105                	.insn	2, 0x2105
     9cc:	ba7f9103          	lh	sp,-1113(t6)
     9d0:	3e05                	.insn	2, 0x3e05
     9d2:	0549                	.insn	2, 0x0549
     9d4:	8321                	.insn	2, 0x8321
     9d6:	0505                	.insn	2, 0x0505
     9d8:	4a00ef03          	.insn	4, 0x4a00ef03
     9dc:	2105                	.insn	2, 0x2105
     9de:	ba7f9103          	lh	sp,-1113(t6)
     9e2:	3e05                	.insn	2, 0x3e05
     9e4:	0549                	.insn	2, 0x0549
     9e6:	8321                	.insn	2, 0x8321
     9e8:	0505                	.insn	2, 0x0505
     9ea:	4a00ef03          	.insn	4, 0x4a00ef03
     9ee:	2105                	.insn	2, 0x2105
     9f0:	ba7f9103          	lh	sp,-1113(t6)
     9f4:	3e05                	.insn	2, 0x3e05
     9f6:	0549                	.insn	2, 0x0549
     9f8:	8321                	.insn	2, 0x8321
     9fa:	0505                	.insn	2, 0x0505
     9fc:	4a00ef03          	.insn	4, 0x4a00ef03
     a00:	2105                	.insn	2, 0x2105
     a02:	ba7f9103          	lh	sp,-1113(t6)
     a06:	3e05                	.insn	2, 0x3e05
     a08:	0549                	.insn	2, 0x0549
     a0a:	4b21                	.insn	2, 0x4b21
     a0c:	0505                	.insn	2, 0x0505
     a0e:	4a00ef03          	.insn	4, 0x4a00ef03
     a12:	2105                	.insn	2, 0x2105
     a14:	ba7f9103          	lh	sp,-1113(t6)
     a18:	0505                	.insn	2, 0x0505
     a1a:	4a00ef03          	.insn	4, 0x4a00ef03
     a1e:	0c05                	.insn	2, 0x0c05
     a20:	ba7f9903          	lh	s2,-1113(t6)
     a24:	0505                	.insn	2, 0x0505
     a26:	034a4103          	lbu	sp,52(s4)
     a2a:	01a6                	.insn	2, 0x01a6
     a2c:	054a                	.insn	2, 0x054a
     a2e:	030c                	.insn	2, 0x030c
     a30:	7f99                	.insn	2, 0x7f99
     a32:	05ba                	.insn	2, 0x05ba
     a34:	0305                	.insn	2, 0x0305
     a36:	4a41                	.insn	2, 0x4a41
     a38:	2505                	.insn	2, 0x2505
     a3a:	054a0b03          	lb	s6,84(s4)
     a3e:	f31c                	.insn	2, 0xf31c
     a40:	1505                	.insn	2, 0x1505
     a42:	4a06                	.insn	2, 0x4a06
     a44:	0505                	.insn	2, 0x0505
     a46:	0306                	.insn	2, 0x0306
     a48:	019a                	.insn	2, 0x019a
     a4a:	0809                	.insn	2, 0x0809
     a4c:	0100                	.insn	2, 0x0100
     a4e:	1c05                	.insn	2, 0x1c05
     a50:	ba7ee603          	.insn	4, 0xba7ee603
     a54:	1505                	.insn	2, 0x1505
     a56:	4a06                	.insn	2, 0x4a06
     a58:	0505                	.insn	2, 0x0505
     a5a:	0306                	.insn	2, 0x0306
     a5c:	019a                	.insn	2, 0x019a
     a5e:	0c09                	.insn	2, 0x0c09
     a60:	0100                	.insn	2, 0x0100
     a62:	3a05                	.insn	2, 0x3a05
     a64:	ba7ef303          	.insn	4, 0xba7ef303
     a68:	0306                	.insn	2, 0x0306
     a6a:	7cf8                	.insn	2, 0x7cf8
     a6c:	054a                	.insn	2, 0x054a
     a6e:	9903061b          	.insn	4, 0x9903061b
     a72:	1e05ba03          	.insn	4, 0x1e05ba03
     a76:	0549                	.insn	2, 0x0549
     a78:	2d054b1b          	.insn	4, 0x2d054b1b
     a7c:	0549                	.insn	2, 0x0549
     a7e:	0624                	.insn	2, 0x0624
     a80:	05f2                	.insn	2, 0x05f2
     a82:	4a22                	.insn	2, 0x4a22
     a84:	1505                	.insn	2, 0x1505
     a86:	8106                	.insn	2, 0x8106
     a88:	2105                	.insn	2, 0x2105
     a8a:	04090703          	lb	a4,64(s2)
     a8e:	0100                	.insn	2, 0x0100
     a90:	0505                	.insn	2, 0x0505
     a92:	8200f703          	.insn	4, 0x8200f703
     a96:	1e05                	.insn	2, 0x1e05
     a98:	ba7f8803          	lb	a6,-1113(t6)
     a9c:	1505                	.insn	2, 0x1505
     a9e:	8206                	.insn	2, 0x8206
     aa0:	097ce303          	.insn	4, 0x097ce303
     aa4:	0008                	.insn	2, 0x0008
     aa6:	0501                	.insn	2, 0x0501
     aa8:	0605                	.insn	2, 0x0605
     aaa:	4a049503          	lh	a0,1184(s1)
     aae:	0105                	.insn	2, 0x0105
     ab0:	7f9e030b          	.insn	4, 0x7f9e030b
     ab4:	05ba                	.insn	2, 0x05ba
     ab6:	0300                	.insn	2, 0x0300
     ab8:	00e1                	.insn	2, 0x00e1
     aba:	1809                	.insn	2, 0x1809
     abc:	0100                	.insn	2, 0x0100
     abe:	0505                	.insn	2, 0x0505
     ac0:	4b0a                	.insn	2, 0x4b0a
     ac2:	0105                	.insn	2, 0x0105
     ac4:	05c2                	.insn	2, 0x05c2
     ac6:	0300                	.insn	2, 0x0300
     ac8:	091f 0004 0501      	.insn	6, 0x05010004091f
     ace:	0a05                	.insn	2, 0x0a05
     ad0:	c201054b          	.insn	4, 0xc201054b
     ad4:	0505                	.insn	2, 0x0505
     ad6:	030a                	.insn	2, 0x030a
     ad8:	0922                	.insn	2, 0x0922
     ada:	0004                	.insn	2, 0x0004
     adc:	0501                	.insn	2, 0x0501
     ade:	0301                	.insn	2, 0x0301
     ae0:	7cdf 0582 0300      	.insn	6, 0x030005827cdf
     ae6:	091a                	.insn	2, 0x091a
     ae8:	0004                	.insn	2, 0x0004
     aea:	0501                	.insn	2, 0x0501
     aec:	0a09                	.insn	2, 0x0a09
     aee:	4008                	.insn	2, 0x4008
     af0:	1405                	.insn	2, 0x1405
     af2:	7708                	.insn	2, 0x7708
     af4:	0905                	.insn	2, 0x0905
     af6:	04090203          	lb	tp,64(s2)
     afa:	0100                	.insn	2, 0x0100
     afc:	05be                	.insn	2, 0x05be
     afe:	0611                	.insn	2, 0x0611
     b00:	0582                	.insn	2, 0x0582
     b02:	0609                	.insn	2, 0x0609
     b04:	04090103          	lb	sp,64(s2)
     b08:	0100                	.insn	2, 0x0100
     b0a:	0005                	.insn	2, 0x0005
     b0c:	0306                	.insn	2, 0x0306
     b0e:	7e92                	.insn	2, 0x7e92
     b10:	0582                	.insn	2, 0x0582
     b12:	0601                	.insn	2, 0x0601
     b14:	0281030b          	.insn	4, 0x0281030b
     b18:	05ba                	.insn	2, 0x05ba
     b1a:	0309                	.insn	2, 0x0309
     b1c:	0872                	.insn	2, 0x0872
     b1e:	863c                	.insn	2, 0x863c
     b20:	034c                	.insn	2, 0x034c
     b22:	4a7a                	.insn	2, 0x4a7a
     b24:	0505                	.insn	2, 0x0505
     b26:	034c                	.insn	2, 0x034c
     b28:	085d                	.insn	2, 0x085d
     b2a:	063c                	.insn	2, 0x063c
     b2c:	f27eae03          	lw	t3,-217(t4)
     b30:	0a06                	.insn	2, 0x0a06
     b32:	0904e703          	.insn	4, 0x0904e703
     b36:	0004                	.insn	2, 0x0004
     b38:	0501                	.insn	2, 0x0501
     b3a:	0301                	.insn	2, 0x0301
     b3c:	7da5                	.insn	2, 0x7da5
     b3e:	0582                	.insn	2, 0x0582
     b40:	0a05                	.insn	2, 0x0a05
     b42:	0902eb03          	.insn	4, 0x0902eb03
     b46:	0004                	.insn	2, 0x0004
     b48:	0501                	.insn	2, 0x0501
     b4a:	0301                	.insn	2, 0x0301
     b4c:	7da0                	.insn	2, 0x7da0
     b4e:	0582                	.insn	2, 0x0582
     b50:	0a05                	.insn	2, 0x0a05
     b52:	0902e003          	.insn	4, 0x0902e003
     b56:	0004                	.insn	2, 0x0004
     b58:	0501                	.insn	2, 0x0501
     b5a:	0301                	.insn	2, 0x0301
     b5c:	05827dab          	.insn	4, 0x05827dab
     b60:	0a05                	.insn	2, 0x0a05
     b62:	0902e903          	.insn	4, 0x0902e903
     b66:	0004                	.insn	2, 0x0004
     b68:	0301                	.insn	2, 0x0301
     b6a:	7d9e                	.insn	2, 0x7d9e
     b6c:	0582                	.insn	2, 0x0582
     b6e:	0300                	.insn	2, 0x0300
     b70:	0909                	.insn	2, 0x0909
     b72:	0004                	.insn	2, 0x0004
     b74:	0501                	.insn	2, 0x0501
     b76:	0a05                	.insn	2, 0x0a05
     b78:	038d0383          	lb	t2,56(s10) # 2d8e8 <start-0x3d2718>
     b7c:	03f2                	.insn	2, 0x03f2
     b7e:	7cf8                	.insn	2, 0x7cf8
     b80:	06f2                	.insn	2, 0x06f2
     b82:	097dc803          	lbu	a6,151(s11)
     b86:	0004                	.insn	2, 0x0004
     b88:	0301                	.insn	2, 0x0301
     b8a:	02b8                	.insn	2, 0x02b8
     b8c:	0582                	.insn	2, 0x0582
     b8e:	0609                	.insn	2, 0x0609
     b90:	08090203          	lb	tp,128(s2)
     b94:	0100                	.insn	2, 0x0100
     b96:	bebe                	.insn	2, 0xbebe
     b98:	0005                	.insn	2, 0x0005
     b9a:	0b06                	.insn	2, 0x0b06
     b9c:	827dbe03          	.insn	4, 0x827dbe03
     ba0:	0905                	.insn	2, 0x0905
     ba2:	0306                	.insn	2, 0x0306
     ba4:	02c6                	.insn	2, 0x02c6
     ba6:	06f2                	.insn	2, 0x06f2
     ba8:	0505820b          	.insn	4, 0x0505820b
     bac:	0a06                	.insn	2, 0x0a06
     bae:	0902fa03          	.insn	4, 0x0902fa03
     bb2:	0010                	.insn	2, 0x0010
     bb4:	c101                	.insn	2, 0xc101
     bb6:	030a                	.insn	2, 0x030a
     bb8:	0969                	.insn	2, 0x0969
     bba:	0004                	.insn	2, 0x0004
     bbc:	0501                	.insn	2, 0x0501
     bbe:	0301                	.insn	2, 0x0301
     bc0:	7da5                	.insn	2, 0x7da5
     bc2:	0582                	.insn	2, 0x0582
     bc4:	0a0c                	.insn	2, 0x0a0c
     bc6:	04090503          	lb	a0,64(s2)
     bca:	0100                	.insn	2, 0x0100
     bcc:	0505                	.insn	2, 0x0505
     bce:	8206                	.insn	2, 0x8206
     bd0:	097da603          	lw	a2,151(s11)
     bd4:	0008                	.insn	2, 0x0008
     bd6:	0501                	.insn	2, 0x0501
     bd8:	060e                	.insn	2, 0x060e
     bda:	4a02db03          	lhu	s6,1184(t0)
     bde:	0c05                	.insn	2, 0x0c05
     be0:	0549                	.insn	2, 0x0549
     be2:	05054b0b          	.insn	4, 0x05054b0b
     be6:	0649                	.insn	2, 0x0649
     be8:	4a7da603          	lw	a2,1191(s11)
     bec:	4a02da03          	lhu	s4,1184(t0)
     bf0:	0805                	.insn	2, 0x0805
     bf2:	0306                	.insn	2, 0x0306
     bf4:	0902                	.insn	2, 0x0902
     bf6:	0004                	.insn	2, 0x0004
     bf8:	0501                	.insn	2, 0x0501
     bfa:	4b05                	.insn	2, 0x4b05
     bfc:	0c05                	.insn	2, 0x0c05
     bfe:	030a                	.insn	2, 0x030a
     c00:	0904                	.insn	2, 0x0904
     c02:	0004                	.insn	2, 0x0004
     c04:	0501                	.insn	2, 0x0501
     c06:	0610                	.insn	2, 0x0610
     c08:	054a                	.insn	2, 0x054a
     c0a:	0305                	.insn	2, 0x0305
     c0c:	0900                	.insn	2, 0x0900
     c0e:	0004                	.insn	2, 0x0004
     c10:	0501                	.insn	2, 0x0501
     c12:	05054a13          	xori	s4,a0,80
     c16:	054a                	.insn	2, 0x054a
     c18:	030c                	.insn	2, 0x030c
     c1a:	0900                	.insn	2, 0x0900
     c1c:	0004                	.insn	2, 0x0004
     c1e:	0501                	.insn	2, 0x0501
     c20:	054e060b          	.insn	4, 0x054e060b
     c24:	4610                	.insn	2, 0x4610
     c26:	2305                	.insn	2, 0x2305
     c28:	08090703          	lb	a4,128(s2)
     c2c:	0100                	.insn	2, 0x0100
     c2e:	2105                	.insn	2, 0x2105
     c30:	4a06                	.insn	2, 0x4a06
     c32:	0505                	.insn	2, 0x0505
     c34:	054a                	.insn	2, 0x054a
     c36:	0600                	.insn	2, 0x0600
     c38:	0900d103          	lhu	sp,144(ra)
     c3c:	0004                	.insn	2, 0x0004
     c3e:	0501                	.insn	2, 0x0501
     c40:	0a0a                	.insn	2, 0x0a0a
     c42:	054c                	.insn	2, 0x054c
     c44:	05820617          	auipc	a2,0x5820
     c48:	0900031b          	.insn	4, 0x0900031b
     c4c:	0004                	.insn	2, 0x0004
     c4e:	0501                	.insn	2, 0x0501
     c50:	0c054a27          	.insn	4, 0x0c054a27
     c54:	0306                	.insn	2, 0x0306
     c56:	0905                	.insn	2, 0x0905
     c58:	000c                	.insn	2, 0x000c
     c5a:	0501                	.insn	2, 0x0501
     c5c:	0306470b          	.insn	4, 0x0306470b
     c60:	054a7cc3          	.insn	4, 0x054a7cc3
     c64:	0605                	.insn	2, 0x0605
     c66:	8203c003          	lbu	zero,-2016(t2)
     c6a:	0306                	.insn	2, 0x0306
     c6c:	7cc0                	.insn	2, 0x7cc0
     c6e:	0809                	.insn	2, 0x0809
     c70:	0100                	.insn	2, 0x0100
     c72:	0306                	.insn	2, 0x0306
     c74:	03c0                	.insn	2, 0x03c0
     c76:	0682                	.insn	2, 0x0682
     c78:	097cc003          	lbu	zero,151(s9)
     c7c:	0008                	.insn	2, 0x0008
     c7e:	0501                	.insn	2, 0x0501
     c80:	0616                	.insn	2, 0x0616
     c82:	8203c303          	lbu	t1,-2016(t2)
     c86:	0306                	.insn	2, 0x0306
     c88:	7cbd                	.insn	2, 0x7cbd
     c8a:	064a                	.insn	2, 0x064a
     c8c:	ba03c303          	lbu	t1,-1120(t2)
     c90:	0306                	.insn	2, 0x0306
     c92:	7cbd                	.insn	2, 0x7cbd
     c94:	0809                	.insn	2, 0x0809
     c96:	0100                	.insn	2, 0x0100
     c98:	0f05                	.insn	2, 0x0f05
     c9a:	0306                	.insn	2, 0x0306
     c9c:	058203c7          	.insn	4, 0x058203c7
     ca0:	097d031b          	.insn	4, 0x097d031b
     ca4:	0008                	.insn	2, 0x0008
     ca6:	0601                	.insn	2, 0x0601
     ca8:	097cbc03          	.insn	4, 0x097cbc03
     cac:	0008                	.insn	2, 0x0008
     cae:	0501                	.insn	2, 0x0501
     cb0:	c703060f          	.insn	4, 0xc703060f
     cb4:	1b058203          	lb	tp,432(a1) # 121b0 <start-0x3ede50>
     cb8:	08097e03          	.insn	4, 0x08097e03
     cbc:	0100                	.insn	2, 0x0100
     cbe:	0306                	.insn	2, 0x0306
     cc0:	08097cbb          	.insn	4, 0x08097cbb
     cc4:	0100                	.insn	2, 0x0100
     cc6:	0f05                	.insn	2, 0x0f05
     cc8:	0306                	.insn	2, 0x0306
     cca:	058203c7          	.insn	4, 0x058203c7
     cce:	030c                	.insn	2, 0x030c
     cd0:	0979                	.insn	2, 0x0979
     cd2:	0004                	.insn	2, 0x0004
     cd4:	0501                	.insn	2, 0x0501
     cd6:	1605520f          	.insn	4, 0x1605520f
     cda:	4a06                	.insn	2, 0x4a06
     cdc:	0505                	.insn	2, 0x0505
     cde:	0306                	.insn	2, 0x0306
     ce0:	4a78                	.insn	2, 0x4a78
     ce2:	08090a03          	lb	s4,128(s2)
     ce6:	0100                	.insn	2, 0x0100
     ce8:	0005                	.insn	2, 0x0005
     cea:	04090503          	lb	a0,64(s2)
     cee:	0100                	.insn	2, 0x0100
     cf0:	0b05                	.insn	2, 0x0b05
     cf2:	4b0a                	.insn	2, 0x4b0a
     cf4:	0306                	.insn	2, 0x0306
     cf6:	7cb0                	.insn	2, 0x7cb0
     cf8:	0409                	.insn	2, 0x0409
     cfa:	0100                	.insn	2, 0x0100
     cfc:	0105                	.insn	2, 0x0105
     cfe:	0306                	.insn	2, 0x0306
     d00:	064a03d7          	.insn	4, 0x064a03d7
     d04:	4a7ca903          	lw	s2,1191(s9)
     d08:	0505                	.insn	2, 0x0505
     d0a:	0306                	.insn	2, 0x0306
     d0c:	03d2                	.insn	2, 0x03d2
     d0e:	06ba                	.insn	2, 0x06ba
     d10:	097cae03          	lw	t3,151(s9)
     d14:	0004                	.insn	2, 0x0004
     d16:	0501                	.insn	2, 0x0501
     d18:	d303060f          	.insn	4, 0xd303060f
     d1c:	13054a03          	lbu	s4,304(a0) # 13630 <start-0x3ec9d0>
     d20:	4a06                	.insn	2, 0x4a06
     d22:	2705                	.insn	2, 0x2705
     d24:	0306                	.insn	2, 0x0306
     d26:	097f 0004 0501 061c 	.insn	10, 0x054a061c05010004097f
     d2e:	054a 
     d30:	4a05                	.insn	2, 0x4a05
     d32:	0105                	.insn	2, 0x0105
     d34:	0306                	.insn	2, 0x0306
     d36:	0905                	.insn	2, 0x0905
     d38:	0004                	.insn	2, 0x0004
     d3a:	0501                	.insn	2, 0x0501
     d3c:	0a05                	.insn	2, 0x0a05
     d3e:	0900cb03          	lbu	s6,144(ra)
     d42:	0004                	.insn	2, 0x0004
     d44:	c201                	.insn	2, 0xc201
     d46:	030a                	.insn	2, 0x030a
     d48:	0906                	.insn	2, 0x0906
     d4a:	0008                	.insn	2, 0x0008
     d4c:	c201                	.insn	2, 0xc201
     d4e:	030a                	.insn	2, 0x030a
     d50:	00e5                	.insn	2, 0x00e5
     d52:	0809                	.insn	2, 0x0809
     d54:	0100                	.insn	2, 0x0100
     d56:	0a89                	.insn	2, 0x0a89
     d58:	04092c03          	lw	s8,64(s2)
     d5c:	0100                	.insn	2, 0x0100
     d5e:	0289                	.insn	2, 0x0289
     d60:	0004                	.insn	2, 0x0004
     d62:	0101                	.insn	2, 0x0101
     d64:	0204                	.insn	2, 0x0204
     d66:	0505                	.insn	2, 0x0505
     d68:	000a                	.insn	2, 0x000a
     d6a:	0205                	.insn	2, 0x0205
     d6c:	0000                	.insn	2, 0x0000
     d6e:	0040                	.insn	2, 0x0040
     d70:	0105dd03          	lhu	s10,16(a1)
     d74:	1c02                	.insn	2, 0x1c02
     d76:	0100                	.insn	2, 0x0100
     d78:	4501                	.insn	2, 0x4501
     d7a:	0008                	.insn	2, 0x0008
     d7c:	0500                	.insn	2, 0x0500
     d7e:	0400                	.insn	2, 0x0400
     d80:	7a00                	.insn	2, 0x7a00
     d82:	0000                	.insn	2, 0x0000
     d84:	0100                	.insn	2, 0x0100
     d86:	0101                	.insn	2, 0x0101
     d88:	000d0efb          	.insn	4, 0x000d0efb
     d8c:	0101                	.insn	2, 0x0101
     d8e:	0101                	.insn	2, 0x0101
     d90:	0000                	.insn	2, 0x0000
     d92:	0100                	.insn	2, 0x0100
     d94:	0000                	.insn	2, 0x0000
     d96:	0101                	.insn	2, 0x0101
     d98:	1f01                	.insn	2, 0x1f01
     d9a:	0002                	.insn	2, 0x0002
     d9c:	0000                	.insn	2, 0x0000
     d9e:	3500                	.insn	2, 0x3500
     da0:	0000                	.insn	2, 0x0000
     da2:	0300                	.insn	2, 0x0300
     da4:	1f01                	.insn	2, 0x1f01
     da6:	0f02                	.insn	2, 0x0f02
     da8:	1e05                	.insn	2, 0x1e05
     daa:	9c04                	.insn	2, 0x9c04
     dac:	0000                	.insn	2, 0x0000
     dae:	0000                	.insn	2, 0x0000
     db0:	e536                	.insn	2, 0xe536
     db2:	05f9                	.insn	2, 0x05f9
     db4:	1769                	.insn	2, 0x1769
     db6:	00a8                	.insn	2, 0x00a8
     db8:	e526                	.insn	2, 0xe526
     dba:	59a1                	.insn	2, 0x59a1
     dbc:	408d                	.insn	2, 0x408d
     dbe:	67de                	.insn	2, 0x67de
     dc0:	00a0                	.insn	2, 0x00a0
     dc2:	0000                	.insn	2, 0x0000
     dc4:	3601                	.insn	2, 0x3601
     dc6:	f9e5                	.insn	2, 0xf9e5
     dc8:	6905                	.insn	2, 0x6905
     dca:	2600a817          	auipc	a6,0x2600a
     dce:	a1e5                	.insn	2, 0xa1e5
     dd0:	8d59                	.insn	2, 0x8d59
     dd2:	de40                	.insn	2, 0xde40
     dd4:	00004767          	.insn	4, 0x4767
     dd8:	0100                	.insn	2, 0x0100
     dda:	04ec                	.insn	2, 0x04ec
     ddc:	e719                	.insn	2, 0xe719
     dde:	77f1                	.insn	2, 0x77f1
     de0:	01586667          	.insn	4, 0x01586667
     de4:	6db0                	.insn	2, 0x6db0
     de6:	9ebaae33          	.insn	4, 0x9ebaae33
     dea:	004e                	.insn	2, 0x004e
     dec:	0000                	.insn	2, 0x0000
     dee:	2501                	.insn	2, 0x2501
     df0:	2589                	.insn	2, 0x2589
     df2:	d09699ef          	jal	s3,fff6aafa <USER_MAX+0xffa6aafa>
     df6:	7184                	.insn	2, 0x7184
     df8:	7c8c                	.insn	2, 0x7c8c
     dfa:	1cb1                	.insn	2, 0x1cb1
     dfc:	fbb9                	.insn	2, 0xfbb9
     dfe:	00e2                	.insn	2, 0x00e2
     e00:	0205                	.insn	2, 0x0205
     e02:	12c8                	.insn	2, 0x12c8
     e04:	0040                	.insn	2, 0x0040
     e06:	051a                	.insn	2, 0x051a
     e08:	0a09                	.insn	2, 0x0a09
     e0a:	4208                	.insn	2, 0x4208
     e0c:	14090303          	lb	t1,320(s2)
     e10:	0100                	.insn	2, 0x0100
     e12:	18090103          	lb	sp,384(s2)
     e16:	0100                	.insn	2, 0x0100
     e18:	0306                	.insn	2, 0x0306
     e1a:	f26d                	.insn	2, 0xf26d
     e1c:	0306                	.insn	2, 0x0306
     e1e:	4a14                	.insn	2, 0x4a14
     e20:	1805                	.insn	2, 0x1805
     e22:	054e                	.insn	2, 0x054e
     e24:	0314                	.insn	2, 0x0314
     e26:	00e4                	.insn	2, 0x00e4
     e28:	844a                	.insn	2, 0x844a
     e2a:	0548                	.insn	2, 0x0548
     e2c:	4b15                	.insn	2, 0x4b15
     e2e:	1a05                	.insn	2, 0x1a05
     e30:	4a06                	.insn	2, 0x4a06
     e32:	1f05                	.insn	2, 0x1f05
     e34:	4906                	.insn	2, 0x4906
     e36:	0905                	.insn	2, 0x0905
     e38:	4a7f9e03          	lh	t3,1191(t6)
     e3c:	0306                	.insn	2, 0x0306
     e3e:	0966                	.insn	2, 0x0966
     e40:	0018                	.insn	2, 0x0018
     e42:	0501                	.insn	2, 0x0501
     e44:	0605                	.insn	2, 0x0605
     e46:	064a1d03          	lh	s10,100(s4)
     e4a:	10096303          	.insn	4, 0x10096303
     e4e:	0100                	.insn	2, 0x0100
     e50:	0306                	.insn	2, 0x0306
     e52:	821d                	.insn	2, 0x821d
     e54:	1105                	.insn	2, 0x1105
     e56:	06090587          	.insn	4, 0x06090587
     e5a:	054a                	.insn	2, 0x054a
     e5c:	0605                	.insn	2, 0x0605
     e5e:	037d                	.insn	2, 0x037d
     e60:	0908                	.insn	2, 0x0908
     e62:	0008                	.insn	2, 0x0008
     e64:	0601                	.insn	2, 0x0601
     e66:	05ba5b03          	lhu	s6,91(s4)
     e6a:	0601                	.insn	2, 0x0601
     e6c:	4a28030b          	.insn	4, 0x4a28030b
     e70:	0005                	.insn	2, 0x0005
     e72:	0900da03          	lhu	s4,144(ra)
     e76:	0014                	.insn	2, 0x0014
     e78:	0501                	.insn	2, 0x0501
     e7a:	0a09                	.insn	2, 0x0a09
     e7c:	3f08                	.insn	2, 0x3f08
     e7e:	0306                	.insn	2, 0x0306
     e80:	3c087efb          	.insn	4, 0x3c087efb
     e84:	4a018503          	lb	a0,1184(gp)
     e88:	1405                	.insn	2, 0x1405
     e8a:	0306                	.insn	2, 0x0306
     e8c:	0904                	.insn	2, 0x0904
     e8e:	0004                	.insn	2, 0x0004
     e90:	8401                	.insn	2, 0x8401
     e92:	2005                	.insn	2, 0x2005
     e94:	0548                	.insn	2, 0x0548
     e96:	4d0a                	.insn	2, 0x4d0a
     e98:	1f05                	.insn	2, 0x1f05
     e9a:	0549                	.insn	2, 0x0549
     e9c:	4925                	.insn	2, 0x4925
     e9e:	1405                	.insn	2, 0x1405
     ea0:	0549                	.insn	2, 0x0549
     ea2:	4d1f 2605 0549      	.insn	6, 0x054926054d1f
     ea8:	4716                	.insn	2, 0x4716
     eaa:	0905                	.insn	2, 0x0905
     eac:	0650                	.insn	2, 0x0650
     eae:	097ef203          	.insn	4, 0x097ef203
     eb2:	000c                	.insn	2, 0x000c
     eb4:	0501                	.insn	2, 0x0501
     eb6:	0611                	.insn	2, 0x0611
     eb8:	4a01a803          	lw	a6,1184(gp)
     ebc:	1d05                	.insn	2, 0x1d05
     ebe:	054a6a03          	.insn	4, 0x054a6a03
     ec2:	23054e13          	xori	t3,a0,560
     ec6:	4e13054f          	.insn	4, 0x4e13054f
     eca:	1a05                	.insn	2, 0x1a05
     ecc:	054a0903          	lb	s2,84(s4)
     ed0:	23054d27          	.insn	4, 0x23054d27
     ed4:	054a7903          	.insn	4, 0x054a7903
     ed8:	1705511b          	.insn	4, 0x1705511b
     edc:	0546                	.insn	2, 0x0546
     ede:	4d18                	.insn	2, 0x4d18
     ee0:	1a05                	.insn	2, 0x1a05
     ee2:	054a7703          	.insn	4, 0x054a7703
     ee6:	4721                	.insn	2, 0x4721
     ee8:	0105                	.insn	2, 0x0105
     eea:	064a1003          	lh	zero,100(s4)
     eee:	00054a0b          	.insn	4, 0x00054a0b
     ef2:	0306                	.insn	2, 0x0306
     ef4:	7f80                	.insn	2, 0x7f80
     ef6:	1809                	.insn	2, 0x1809
     ef8:	0100                	.insn	2, 0x0100
     efa:	0905                	.insn	2, 0x0905
     efc:	020a                	.insn	2, 0x020a
     efe:	1540                	.insn	2, 0x1540
     f00:	0306                	.insn	2, 0x0306
     f02:	3103824f          	.insn	4, 0x3103824f
     f06:	054a                	.insn	2, 0x054a
     f08:	0620                	.insn	2, 0x0620
     f0a:	04090403          	lb	s0,64(s2)
     f0e:	0100                	.insn	2, 0x0100
     f10:	1405                	.insn	2, 0x1405
     f12:	ba00c903          	lbu	s2,-1120(ra)
     f16:	0548                	.insn	2, 0x0548
     f18:	4b15                	.insn	2, 0x4b15
     f1a:	1a05                	.insn	2, 0x1a05
     f1c:	4a06                	.insn	2, 0x4a06
     f1e:	1f05                	.insn	2, 0x1f05
     f20:	4906                	.insn	2, 0x4906
     f22:	0905                	.insn	2, 0x0905
     f24:	4a7fbb03          	.insn	4, 0x4a7fbb03
     f28:	0105                	.insn	2, 0x0105
     f2a:	0900c103          	lbu	sp,144(ra)
     f2e:	0010                	.insn	2, 0x0010
     f30:	0601                	.insn	2, 0x0601
     f32:	88034a0b          	.insn	4, 0x88034a0b
     f36:	027f 0138 2005 0306 	.insn	10, 0x00da030620050138027f
     f3e:	00da 
     f40:	e408                	.insn	2, 0xe408
     f42:	1505                	.insn	2, 0x1505
     f44:	4a06                	.insn	2, 0x4a06
     f46:	2405                	.insn	2, 0x2405
     f48:	054a                	.insn	2, 0x054a
     f4a:	0609                	.insn	2, 0x0609
     f4c:	054e                	.insn	2, 0x054e
     f4e:	0616                	.insn	2, 0x0616
     f50:	054a                	.insn	2, 0x054a
     f52:	060d                	.insn	2, 0x060d
     f54:	054c                	.insn	2, 0x054c
     f56:	0625                	.insn	2, 0x0625
     f58:	05f2                	.insn	2, 0x05f2
     f5a:	5a030617          	auipc	a2,0x5a030
     f5e:	0409                	.insn	2, 0x0409
     f60:	0100                	.insn	2, 0x0100
     f62:	0505                	.insn	2, 0x0505
     f64:	8206                	.insn	2, 0x8206
     f66:	0d05                	.insn	2, 0x0d05
     f68:	0306                	.insn	2, 0x0306
     f6a:	0905                	.insn	2, 0x0905
     f6c:	0004                	.insn	2, 0x0004
     f6e:	0501                	.insn	2, 0x0501
     f70:	0612                	.insn	2, 0x0612
     f72:	054a                	.insn	2, 0x054a
     f74:	060d                	.insn	2, 0x060d
     f76:	08090803          	lb	a6,128(s2)
     f7a:	0100                	.insn	2, 0x0100
     f7c:	1305                	.insn	2, 0x1305
     f7e:	4a06                	.insn	2, 0x4a06
     f80:	1605                	.insn	2, 0x1605
     f82:	0306                	.insn	2, 0x0306
     f84:	0908                	.insn	2, 0x0908
     f86:	0004                	.insn	2, 0x0004
     f88:	0601                	.insn	2, 0x0601
     f8a:	097fb103          	.insn	4, 0x097fb103
     f8e:	0004                	.insn	2, 0x0004
     f90:	0501                	.insn	2, 0x0501
     f92:	0311                	.insn	2, 0x0311
     f94:	054a00cf          	.insn	4, 0x054a00cf
     f98:	4a16                	.insn	2, 0x4a16
     f9a:	2005                	.insn	2, 0x2005
     f9c:	0306                	.insn	2, 0x0306
     f9e:	0901                	.insn	2, 0x0901
     fa0:	0008                	.insn	2, 0x0008
     fa2:	0501                	.insn	2, 0x0501
     fa4:	8111                	.insn	2, 0x8111
     fa6:	1605                	.insn	2, 0x1605
     fa8:	4a06                	.insn	2, 0x4a06
     faa:	2005                	.insn	2, 0x2005
     fac:	0306                	.insn	2, 0x0306
     fae:	0901                	.insn	2, 0x0901
     fb0:	0004                	.insn	2, 0x0004
     fb2:	0501                	.insn	2, 0x0501
     fb4:	061c                	.insn	2, 0x061c
     fb6:	054a                	.insn	2, 0x054a
     fb8:	4a20                	.insn	2, 0x4a20
     fba:	1105                	.insn	2, 0x1105
     fbc:	4906                	.insn	2, 0x4906
     fbe:	1605                	.insn	2, 0x1605
     fc0:	4a06                	.insn	2, 0x4a06
     fc2:	1105                	.insn	2, 0x1105
     fc4:	04090003          	lb	zero,64(s2)
     fc8:	0100                	.insn	2, 0x0100
     fca:	1605                	.insn	2, 0x1605
     fcc:	054a                	.insn	2, 0x054a
     fce:	0311                	.insn	2, 0x0311
     fd0:	0900                	.insn	2, 0x0900
     fd2:	0004                	.insn	2, 0x0004
     fd4:	0501                	.insn	2, 0x0501
     fd6:	4a16                	.insn	2, 0x4a16
     fd8:	1105                	.insn	2, 0x1105
     fda:	04090003          	lb	zero,64(s2)
     fde:	0100                	.insn	2, 0x0100
     fe0:	1605                	.insn	2, 0x1605
     fe2:	054a                	.insn	2, 0x054a
     fe4:	0311                	.insn	2, 0x0311
     fe6:	0900                	.insn	2, 0x0900
     fe8:	0004                	.insn	2, 0x0004
     fea:	0501                	.insn	2, 0x0501
     fec:	4a16                	.insn	2, 0x4a16
     fee:	1105                	.insn	2, 0x1105
     ff0:	04090003          	lb	zero,64(s2)
     ff4:	0100                	.insn	2, 0x0100
     ff6:	1605                	.insn	2, 0x1605
     ff8:	054a                	.insn	2, 0x054a
     ffa:	060d                	.insn	2, 0x060d
     ffc:	04090503          	lb	a0,64(s2)
    1000:	0100                	.insn	2, 0x0100
    1002:	1205                	.insn	2, 0x1205
    1004:	4a06                	.insn	2, 0x4a06
    1006:	1105                	.insn	2, 0x1105
    1008:	0306                	.insn	2, 0x0306
    100a:	097c                	.insn	2, 0x097c
    100c:	0008                	.insn	2, 0x0008
    100e:	0501                	.insn	2, 0x0501
    1010:	061c                	.insn	2, 0x061c
    1012:	054a                	.insn	2, 0x054a
    1014:	4a20                	.insn	2, 0x4a20
    1016:	1105                	.insn	2, 0x1105
    1018:	4906                	.insn	2, 0x4906
    101a:	1605                	.insn	2, 0x1605
    101c:	4a06                	.insn	2, 0x4a06
    101e:	1105                	.insn	2, 0x1105
    1020:	0306                	.insn	2, 0x0306
    1022:	0901                	.insn	2, 0x0901
    1024:	0004                	.insn	2, 0x0004
    1026:	0501                	.insn	2, 0x0501
    1028:	061c                	.insn	2, 0x061c
    102a:	054a                	.insn	2, 0x054a
    102c:	4a20                	.insn	2, 0x4a20
    102e:	1105                	.insn	2, 0x1105
    1030:	4906                	.insn	2, 0x4906
    1032:	1605                	.insn	2, 0x1605
    1034:	4a06                	.insn	2, 0x4a06
    1036:	1105                	.insn	2, 0x1105
    1038:	0306                	.insn	2, 0x0306
    103a:	0901                	.insn	2, 0x0901
    103c:	0004                	.insn	2, 0x0004
    103e:	0501                	.insn	2, 0x0501
    1040:	061c                	.insn	2, 0x061c
    1042:	054a                	.insn	2, 0x054a
    1044:	4a20                	.insn	2, 0x4a20
    1046:	1105                	.insn	2, 0x1105
    1048:	4906                	.insn	2, 0x4906
    104a:	1605                	.insn	2, 0x1605
    104c:	4a06                	.insn	2, 0x4a06
    104e:	1105                	.insn	2, 0x1105
    1050:	0306                	.insn	2, 0x0306
    1052:	0901                	.insn	2, 0x0901
    1054:	0004                	.insn	2, 0x0004
    1056:	0501                	.insn	2, 0x0501
    1058:	061c                	.insn	2, 0x061c
    105a:	054a                	.insn	2, 0x054a
    105c:	4a20                	.insn	2, 0x4a20
    105e:	1105                	.insn	2, 0x1105
    1060:	4906                	.insn	2, 0x4906
    1062:	1605                	.insn	2, 0x1605
    1064:	4a06                	.insn	2, 0x4a06
    1066:	1105                	.insn	2, 0x1105
    1068:	0306                	.insn	2, 0x0306
    106a:	0901                	.insn	2, 0x0901
    106c:	0004                	.insn	2, 0x0004
    106e:	0501                	.insn	2, 0x0501
    1070:	061c                	.insn	2, 0x061c
    1072:	054a                	.insn	2, 0x054a
    1074:	4a20                	.insn	2, 0x4a20
    1076:	1105                	.insn	2, 0x1105
    1078:	4906                	.insn	2, 0x4906
    107a:	1605                	.insn	2, 0x1605
    107c:	4a06                	.insn	2, 0x4a06
    107e:	1105                	.insn	2, 0x1105
    1080:	0306                	.insn	2, 0x0306
    1082:	0901                	.insn	2, 0x0901
    1084:	0004                	.insn	2, 0x0004
    1086:	0501                	.insn	2, 0x0501
    1088:	061c                	.insn	2, 0x061c
    108a:	054a                	.insn	2, 0x054a
    108c:	4a20                	.insn	2, 0x4a20
    108e:	0d05                	.insn	2, 0x0d05
    1090:	4e06                	.insn	2, 0x4e06
    1092:	1205                	.insn	2, 0x1205
    1094:	4a06                	.insn	2, 0x4a06
    1096:	1505                	.insn	2, 0x1505
    1098:	0306                	.insn	2, 0x0306
    109a:	0905                	.insn	2, 0x0905
    109c:	0004                	.insn	2, 0x0004
    109e:	0501                	.insn	2, 0x0501
    10a0:	470d                	.insn	2, 0x470d
    10a2:	1c05                	.insn	2, 0x1c05
    10a4:	4a06                	.insn	2, 0x4a06
    10a6:	2405                	.insn	2, 0x2405
    10a8:	4e06                	.insn	2, 0x4e06
    10aa:	2005                	.insn	2, 0x2005
    10ac:	4a06                	.insn	2, 0x4a06
    10ae:	1a05                	.insn	2, 0x1a05
    10b0:	4906                	.insn	2, 0x4906
    10b2:	1505                	.insn	2, 0x1505
    10b4:	04090103          	lb	sp,64(s2)
    10b8:	0100                	.insn	2, 0x0100
    10ba:	2005                	.insn	2, 0x2005
    10bc:	4a06                	.insn	2, 0x4a06
    10be:	2405                	.insn	2, 0x2405
    10c0:	054a                	.insn	2, 0x054a
    10c2:	0615                	.insn	2, 0x0615
    10c4:	0581                	.insn	2, 0x0581
    10c6:	061a                	.insn	2, 0x061a
    10c8:	034a                	.insn	2, 0x034a
    10ca:	04097fa7          	.insn	4, 0x04097fa7
    10ce:	0100                	.insn	2, 0x0100
    10d0:	4a00d903          	lhu	s2,1184(ra)
    10d4:	4a7fa703          	lw	a4,1191(t6)
    10d8:	1205                	.insn	2, 0x1205
    10da:	0306                	.insn	2, 0x0306
    10dc:	00e4                	.insn	2, 0x00e4
    10de:	054a                	.insn	2, 0x054a
    10e0:	491c                	.insn	2, 0x491c
    10e2:	4b4e                	.insn	2, 0x4b4e
    10e4:	1805                	.insn	2, 0x1805
    10e6:	054d                	.insn	2, 0x054d
    10e8:	22057e23          	.insn	4, 0x22057e23
    10ec:	4d18054b          	.insn	4, 0x4d18054b
    10f0:	1f05                	.insn	2, 0x1f05
    10f2:	4a06                	.insn	2, 0x4a06
    10f4:	1605                	.insn	2, 0x1605
    10f6:	4906                	.insn	2, 0x4906
    10f8:	1c05                	.insn	2, 0x1c05
    10fa:	12054b4f          	.insn	4, 0x12054b4f
    10fe:	471c054b          	.insn	4, 0x471c054b
    1102:	2205                	.insn	2, 0x2205
    1104:	054b4b4b          	.insn	4, 0x054b4b4b
    1108:	28054723          	.insn	4, 0x28054723
    110c:	4b29054b          	.insn	4, 0x4b29054b
    1110:	1305                	.insn	2, 0x1305
    1112:	0a140547          	.insn	4, 0x0a140547
    1116:	08090f03          	lb	t5,128(s2)
    111a:	0100                	.insn	2, 0x0100
    111c:	4884                	.insn	2, 0x4884
    111e:	1505                	.insn	2, 0x1505
    1120:	061a054b          	.insn	4, 0x061a054b
    1124:	054a                	.insn	2, 0x054a
    1126:	061f 0549 0605      	.insn	6, 0x06050549061f
    112c:	054a                	.insn	2, 0x054a
    112e:	0600                	.insn	2, 0x0600
    1130:	04093503          	.insn	4, 0x04093503
    1134:	0100                	.insn	2, 0x0100
    1136:	0905                	.insn	2, 0x0905
    1138:	020a                	.insn	2, 0x020a
    113a:	152c                	.insn	2, 0x152c
    113c:	2005                	.insn	2, 0x2005
    113e:	0c090403          	lb	s0,192(s2)
    1142:	0100                	.insn	2, 0x0100
    1144:	1405                	.insn	2, 0x1405
    1146:	48ba4603          	lbu	a2,1163(s4)
    114a:	1505                	.insn	2, 0x1505
    114c:	061a054b          	.insn	4, 0x061a054b
    1150:	054a                	.insn	2, 0x054a
    1152:	061f 0549 0309      	.insn	6, 0x03090549061f
    1158:	4a3e                	.insn	2, 0x4a3e
    115a:	0105                	.insn	2, 0x0105
    115c:	093b030b          	.insn	4, 0x093b030b
    1160:	0010                	.insn	2, 0x0010
    1162:	0601                	.insn	2, 0x0601
    1164:	027e8b03          	lb	s6,39(t4)
    1168:	0130                	.insn	2, 0x0130
    116a:	1405                	.insn	2, 0x1405
    116c:	0306                	.insn	2, 0x0306
    116e:	00fe                	.insn	2, 0x00fe
    1170:	2c02                	.insn	2, 0x2c02
    1172:	4801                	.insn	2, 0x4801
    1174:	1505                	.insn	2, 0x1505
    1176:	061a054b          	.insn	4, 0x061a054b
    117a:	054a                	.insn	2, 0x054a
    117c:	061f 0549 0318      	.insn	6, 0x03180549061f
    1182:	494a00ef          	jal	a1616 <start-0x35e9ea>
    1186:	054c                	.insn	2, 0x054c
    1188:	4b0e                	.insn	2, 0x4b0e
    118a:	1e05                	.insn	2, 0x1e05
    118c:	0548                	.insn	2, 0x0548
    118e:	491f 1e05 4b4c      	.insn	6, 0x4b4c1e05491f
    1194:	2405                	.insn	2, 0x2405
    1196:	0548                	.insn	2, 0x0548
    1198:	4b25                	.insn	2, 0x4b25
    119a:	0905                	.insn	2, 0x0905
    119c:	054e                	.insn	2, 0x054e
    119e:	ba4d0317          	auipc	t1,0xba4d0
    11a2:	0505                	.insn	2, 0x0505
    11a4:	8206                	.insn	2, 0x8206
    11a6:	0d05                	.insn	2, 0x0d05
    11a8:	0306                	.insn	2, 0x0306
    11aa:	0904                	.insn	2, 0x0904
    11ac:	0004                	.insn	2, 0x0004
    11ae:	0501                	.insn	2, 0x0501
    11b0:	0612                	.insn	2, 0x0612
    11b2:	054a                	.insn	2, 0x054a
    11b4:	060d                	.insn	2, 0x060d
    11b6:	08090603          	lb	a2,128(s2)
    11ba:	0100                	.insn	2, 0x0100
    11bc:	1305                	.insn	2, 0x1305
    11be:	4a06                	.insn	2, 0x4a06
    11c0:	1605                	.insn	2, 0x1605
    11c2:	0306                	.insn	2, 0x0306
    11c4:	0904                	.insn	2, 0x0904
    11c6:	0004                	.insn	2, 0x0004
    11c8:	0501                	.insn	2, 0x0501
    11ca:	0611                	.insn	2, 0x0611
    11cc:	04090003          	lb	zero,64(s2)
    11d0:	0100                	.insn	2, 0x0100
    11d2:	1605                	.insn	2, 0x1605
    11d4:	054a                	.insn	2, 0x054a
    11d6:	0311                	.insn	2, 0x0311
    11d8:	0900                	.insn	2, 0x0900
    11da:	0004                	.insn	2, 0x0004
    11dc:	0501                	.insn	2, 0x0501
    11de:	4a16                	.insn	2, 0x4a16
    11e0:	1105                	.insn	2, 0x1105
    11e2:	04090003          	lb	zero,64(s2)
    11e6:	0100                	.insn	2, 0x0100
    11e8:	1605                	.insn	2, 0x1605
    11ea:	054a                	.insn	2, 0x054a
    11ec:	0311                	.insn	2, 0x0311
    11ee:	0900                	.insn	2, 0x0900
    11f0:	0004                	.insn	2, 0x0004
    11f2:	0501                	.insn	2, 0x0501
    11f4:	4a16                	.insn	2, 0x4a16
    11f6:	1105                	.insn	2, 0x1105
    11f8:	04090003          	lb	zero,64(s2)
    11fc:	0100                	.insn	2, 0x0100
    11fe:	1605                	.insn	2, 0x1605
    1200:	054a                	.insn	2, 0x054a
    1202:	0311                	.insn	2, 0x0311
    1204:	0900                	.insn	2, 0x0900
    1206:	0004                	.insn	2, 0x0004
    1208:	0501                	.insn	2, 0x0501
    120a:	4a16                	.insn	2, 0x4a16
    120c:	1105                	.insn	2, 0x1105
    120e:	04090003          	lb	zero,64(s2)
    1212:	0100                	.insn	2, 0x0100
    1214:	1605                	.insn	2, 0x1605
    1216:	054a                	.insn	2, 0x054a
    1218:	060d                	.insn	2, 0x060d
    121a:	04090403          	lb	s0,64(s2)
    121e:	0100                	.insn	2, 0x0100
    1220:	1205                	.insn	2, 0x1205
    1222:	4a06                	.insn	2, 0x4a06
    1224:	1105                	.insn	2, 0x1105
    1226:	0306                	.insn	2, 0x0306
    1228:	097d                	.insn	2, 0x097d
    122a:	0008                	.insn	2, 0x0008
    122c:	8101                	.insn	2, 0x8101
    122e:	1605                	.insn	2, 0x1605
    1230:	4a06                	.insn	2, 0x4a06
    1232:	1105                	.insn	2, 0x1105
    1234:	0306                	.insn	2, 0x0306
    1236:	0901                	.insn	2, 0x0901
    1238:	0004                	.insn	2, 0x0004
    123a:	8101                	.insn	2, 0x8101
    123c:	1605                	.insn	2, 0x1605
    123e:	4a06                	.insn	2, 0x4a06
    1240:	1105                	.insn	2, 0x1105
    1242:	0306                	.insn	2, 0x0306
    1244:	0901                	.insn	2, 0x0901
    1246:	0004                	.insn	2, 0x0004
    1248:	8101                	.insn	2, 0x8101
    124a:	1605                	.insn	2, 0x1605
    124c:	4a06                	.insn	2, 0x4a06
    124e:	1105                	.insn	2, 0x1105
    1250:	0306                	.insn	2, 0x0306
    1252:	0901                	.insn	2, 0x0901
    1254:	0004                	.insn	2, 0x0004
    1256:	8101                	.insn	2, 0x8101
    1258:	1605                	.insn	2, 0x1605
    125a:	4a06                	.insn	2, 0x4a06
    125c:	1105                	.insn	2, 0x1105
    125e:	0306                	.insn	2, 0x0306
    1260:	0901                	.insn	2, 0x0901
    1262:	0004                	.insn	2, 0x0004
    1264:	8101                	.insn	2, 0x8101
    1266:	1605                	.insn	2, 0x1605
    1268:	4a06                	.insn	2, 0x4a06
    126a:	1105                	.insn	2, 0x1105
    126c:	0306                	.insn	2, 0x0306
    126e:	0901                	.insn	2, 0x0901
    1270:	0004                	.insn	2, 0x0004
    1272:	8101                	.insn	2, 0x8101
    1274:	1605                	.insn	2, 0x1605
    1276:	4a06                	.insn	2, 0x4a06
    1278:	1105                	.insn	2, 0x1105
    127a:	0306                	.insn	2, 0x0306
    127c:	0901                	.insn	2, 0x0901
    127e:	0004                	.insn	2, 0x0004
    1280:	8101                	.insn	2, 0x8101
    1282:	1605                	.insn	2, 0x1605
    1284:	4a06                	.insn	2, 0x4a06
    1286:	1105                	.insn	2, 0x1105
    1288:	0306                	.insn	2, 0x0306
    128a:	0901                	.insn	2, 0x0901
    128c:	0004                	.insn	2, 0x0004
    128e:	0501                	.insn	2, 0x0501
    1290:	850d                	.insn	2, 0x850d
    1292:	1205                	.insn	2, 0x1205
    1294:	4a06                	.insn	2, 0x4a06
    1296:	0d05                	.insn	2, 0x0d05
    1298:	0306                	.insn	2, 0x0306
    129a:	0901                	.insn	2, 0x0901
    129c:	0004                	.insn	2, 0x0004
    129e:	0501                	.insn	2, 0x0501
    12a0:	bc15                	.insn	2, 0xbc15
    12a2:	1a05                	.insn	2, 0x1a05
    12a4:	4a06                	.insn	2, 0x4a06
    12a6:	1505                	.insn	2, 0x1505
    12a8:	04090003          	lb	zero,64(s2)
    12ac:	0100                	.insn	2, 0x0100
    12ae:	1a05                	.insn	2, 0x1a05
    12b0:	054a                	.insn	2, 0x054a
    12b2:	0315                	.insn	2, 0x0315
    12b4:	0900                	.insn	2, 0x0900
    12b6:	0004                	.insn	2, 0x0004
    12b8:	0501                	.insn	2, 0x0501
    12ba:	4a1a                	.insn	2, 0x4a1a
    12bc:	1505                	.insn	2, 0x1505
    12be:	0306                	.insn	2, 0x0306
    12c0:	0901                	.insn	2, 0x0901
    12c2:	0004                	.insn	2, 0x0004
    12c4:	0501                	.insn	2, 0x0501
    12c6:	8626                	.insn	2, 0x8626
    12c8:	0905                	.insn	2, 0x0905
    12ca:	4a06                	.insn	2, 0x4a06
    12cc:	1805                	.insn	2, 0x1805
    12ce:	c206                	.insn	2, 0xc206
    12d0:	0e05                	.insn	2, 0x0e05
    12d2:	0546                	.insn	2, 0x0546
    12d4:	4918                	.insn	2, 0x4918
    12d6:	054e                	.insn	2, 0x054e
    12d8:	4b1e                	.insn	2, 0x4b1e
    12da:	1405                	.insn	2, 0x1405
    12dc:	054d                	.insn	2, 0x054d
    12de:	7e1f 1405 054e      	.insn	6, 0x054e14057e1f
    12e4:	054a061b          	.insn	4, 0x054a061b
    12e8:	0610                	.insn	2, 0x0610
    12ea:	064e                	.insn	2, 0x064e
    12ec:	097e9a03          	lh	s4,151(t4)
    12f0:	0004                	.insn	2, 0x0004
    12f2:	0301                	.insn	2, 0x0301
    12f4:	01e6                	.insn	2, 0x01e6
    12f6:	054a                	.insn	2, 0x054a
    12f8:	0615                	.insn	2, 0x0615
    12fa:	814a6d03          	.insn	4, 0x814a6d03
    12fe:	1a05                	.insn	2, 0x1a05
    1300:	4a06                	.insn	2, 0x4a06
    1302:	1505                	.insn	2, 0x1505
    1304:	0306                	.insn	2, 0x0306
    1306:	0901                	.insn	2, 0x0901
    1308:	0004                	.insn	2, 0x0004
    130a:	8101                	.insn	2, 0x8101
    130c:	1a05                	.insn	2, 0x1a05
    130e:	4a06                	.insn	2, 0x4a06
    1310:	0005                	.insn	2, 0x0005
    1312:	0306                	.insn	2, 0x0306
    1314:	00cc                	.insn	2, 0x00cc
    1316:	0809                	.insn	2, 0x0809
    1318:	0100                	.insn	2, 0x0100
    131a:	0905                	.insn	2, 0x0905
    131c:	080a                	.insn	2, 0x080a
    131e:	df0306e7          	jalr	a3,-528(t1) # ba4d0f8e <USER_MAX+0xb9fd0f8e>
    1322:	827d                	.insn	2, 0x827d
    1324:	4a02a103          	lw	sp,1184(t0)
    1328:	2005                	.insn	2, 0x2005
    132a:	0306                	.insn	2, 0x0306
    132c:	0904                	.insn	2, 0x0904
    132e:	0004                	.insn	2, 0x0004
    1330:	0501                	.insn	2, 0x0501
    1332:	0314                	.insn	2, 0x0314
    1334:	7ed9                	.insn	2, 0x7ed9
    1336:	48ba                	.insn	2, 0x48ba
    1338:	1505                	.insn	2, 0x1505
    133a:	061a054b          	.insn	4, 0x061a054b
    133e:	054a                	.insn	2, 0x054a
    1340:	061f 0549 0309      	.insn	6, 0x03090549061f
    1346:	064a01ab          	.insn	4, 0x064a01ab
    134a:	097dd903          	lhu	s2,151(s11)
    134e:	0018                	.insn	2, 0x0018
    1350:	0501                	.insn	2, 0x0501
    1352:	060c                	.insn	2, 0x060c
    1354:	4a028403          	lb	s0,1184(t0)
    1358:	1005                	.insn	2, 0x1005
    135a:	0545                	.insn	2, 0x0545
    135c:	0212                	.insn	2, 0x0212
    135e:	172c                	.insn	2, 0x172c
    1360:	0306                	.insn	2, 0x0306
    1362:	7dfc                	.insn	2, 0x7dfc
    1364:	0409                	.insn	2, 0x0409
    1366:	0100                	.insn	2, 0x0100
    1368:	1905                	.insn	2, 0x1905
    136a:	0306                	.insn	2, 0x0306
    136c:	0285                	.insn	2, 0x0285
    136e:	05f2                	.insn	2, 0x05f2
    1370:	0309                	.insn	2, 0x0309
    1372:	00080903          	lb	s2,0(a6) # 2600adca <USER_MAX+0x25b0adca>
    1376:	0501                	.insn	2, 0x0501
    1378:	0614                	.insn	2, 0x0614
    137a:	0582                	.insn	2, 0x0582
    137c:	060c                	.insn	2, 0x060c
    137e:	0546                	.insn	2, 0x0546
    1380:	4e10                	.insn	2, 0x4e10
    1382:	0306                	.insn	2, 0x0306
    1384:	7df8                	.insn	2, 0x7df8
    1386:	054a                	.insn	2, 0x054a
    1388:	0612                	.insn	2, 0x0612
    138a:	4a028403          	lb	s0,1184(t0)
    138e:	0505                	.insn	2, 0x0505
    1390:	04090803          	lb	a6,64(s2)
    1394:	0100                	.insn	2, 0x0100
    1396:	0306                	.insn	2, 0x0306
    1398:	7df4                	.insn	2, 0x7df4
    139a:	0582                	.insn	2, 0x0582
    139c:	0612                	.insn	2, 0x0612
    139e:	4a028403          	lb	s0,1184(t0)
    13a2:	0306                	.insn	2, 0x0306
    13a4:	7dfc                	.insn	2, 0x7dfc
    13a6:	054a                	.insn	2, 0x054a
    13a8:	0605                	.insn	2, 0x0605
    13aa:	4a028c03          	lb	s8,1184(t0)
    13ae:	1205                	.insn	2, 0x1205
    13b0:	8206                	.insn	2, 0x8206
    13b2:	0c05                	.insn	2, 0x0c05
    13b4:	08090003          	lb	zero,128(s2)
    13b8:	0100                	.insn	2, 0x0100
    13ba:	0505                	.insn	2, 0x0505
    13bc:	054a                	.insn	2, 0x054a
    13be:	4a12                	.insn	2, 0x4a12
    13c0:	0f05                	.insn	2, 0x0f05
    13c2:	0306                	.insn	2, 0x0306
    13c4:	0904                	.insn	2, 0x0904
    13c6:	0004                	.insn	2, 0x0004
    13c8:	0501                	.insn	2, 0x0501
    13ca:	880c                	.insn	2, 0x880c
    13cc:	0505                	.insn	2, 0x0505
    13ce:	8206                	.insn	2, 0x8206
    13d0:	097dea03          	.insn	4, 0x097dea03
    13d4:	0004                	.insn	2, 0x0004
    13d6:	0301                	.insn	2, 0x0301
    13d8:	0296                	.insn	2, 0x0296
    13da:	054a                	.insn	2, 0x054a
    13dc:	0614                	.insn	2, 0x0614
    13de:	b90c0583          	lb	a1,-1136(s8)
    13e2:	0505                	.insn	2, 0x0505
    13e4:	4a06                	.insn	2, 0x4a06
    13e6:	0005                	.insn	2, 0x0005
    13e8:	097dea03          	.insn	4, 0x097dea03
    13ec:	0004                	.insn	2, 0x0004
    13ee:	0501                	.insn	2, 0x0501
    13f0:	0305                	.insn	2, 0x0305
    13f2:	0296                	.insn	2, 0x0296
    13f4:	054a                	.insn	2, 0x054a
    13f6:	060d                	.insn	2, 0x060d
    13f8:	08091c03          	lh	s8,128(s2)
    13fc:	0100                	.insn	2, 0x0100
    13fe:	1a05                	.insn	2, 0x1a05
    1400:	ba06                	.insn	2, 0xba06
    1402:	097dce03          	lbu	t3,151(s11)
    1406:	0004                	.insn	2, 0x0004
    1408:	0301                	.insn	2, 0x0301
    140a:	02b2                	.insn	2, 0x02b2
    140c:	054a                	.insn	2, 0x054a
    140e:	030d                	.insn	2, 0x030d
    1410:	0900                	.insn	2, 0x0900
    1412:	0004                	.insn	2, 0x0004
    1414:	0501                	.insn	2, 0x0501
    1416:	821a                	.insn	2, 0x821a
    1418:	097dce03          	lbu	t3,151(s11)
    141c:	0004                	.insn	2, 0x0004
    141e:	0301                	.insn	2, 0x0301
    1420:	02b2                	.insn	2, 0x02b2
    1422:	054a                	.insn	2, 0x054a
    1424:	030d                	.insn	2, 0x030d
    1426:	0900                	.insn	2, 0x0900
    1428:	0004                	.insn	2, 0x0004
    142a:	0501                	.insn	2, 0x0501
    142c:	821a                	.insn	2, 0x821a
    142e:	097dce03          	lbu	t3,151(s11)
    1432:	0004                	.insn	2, 0x0004
    1434:	0301                	.insn	2, 0x0301
    1436:	02b2                	.insn	2, 0x02b2
    1438:	054a                	.insn	2, 0x054a
    143a:	030d                	.insn	2, 0x030d
    143c:	0900                	.insn	2, 0x0900
    143e:	0004                	.insn	2, 0x0004
    1440:	0501                	.insn	2, 0x0501
    1442:	821a                	.insn	2, 0x821a
    1444:	097dce03          	lbu	t3,151(s11)
    1448:	0004                	.insn	2, 0x0004
    144a:	0301                	.insn	2, 0x0301
    144c:	02b2                	.insn	2, 0x02b2
    144e:	054a                	.insn	2, 0x054a
    1450:	030d                	.insn	2, 0x030d
    1452:	0900                	.insn	2, 0x0900
    1454:	0004                	.insn	2, 0x0004
    1456:	0501                	.insn	2, 0x0501
    1458:	821a                	.insn	2, 0x821a
    145a:	097dce03          	lbu	t3,151(s11)
    145e:	0004                	.insn	2, 0x0004
    1460:	0301                	.insn	2, 0x0301
    1462:	02b2                	.insn	2, 0x02b2
    1464:	054a                	.insn	2, 0x054a
    1466:	030d                	.insn	2, 0x030d
    1468:	0900                	.insn	2, 0x0900
    146a:	0004                	.insn	2, 0x0004
    146c:	0501                	.insn	2, 0x0501
    146e:	821a                	.insn	2, 0x821a
    1470:	097dce03          	lbu	t3,151(s11)
    1474:	0004                	.insn	2, 0x0004
    1476:	0301                	.insn	2, 0x0301
    1478:	02b2                	.insn	2, 0x02b2
    147a:	054a                	.insn	2, 0x054a
    147c:	030d                	.insn	2, 0x030d
    147e:	0900                	.insn	2, 0x0900
    1480:	0004                	.insn	2, 0x0004
    1482:	0501                	.insn	2, 0x0501
    1484:	821a                	.insn	2, 0x821a
    1486:	097dce03          	lbu	t3,151(s11)
    148a:	0004                	.insn	2, 0x0004
    148c:	0301                	.insn	2, 0x0301
    148e:	02b2                	.insn	2, 0x02b2
    1490:	054a                	.insn	2, 0x054a
    1492:	030d                	.insn	2, 0x030d
    1494:	0900                	.insn	2, 0x0900
    1496:	0004                	.insn	2, 0x0004
    1498:	0501                	.insn	2, 0x0501
    149a:	821a                	.insn	2, 0x821a
    149c:	097dce03          	lbu	t3,151(s11)
    14a0:	0004                	.insn	2, 0x0004
    14a2:	0301                	.insn	2, 0x0301
    14a4:	02b2                	.insn	2, 0x02b2
    14a6:	054a                	.insn	2, 0x054a
    14a8:	030d                	.insn	2, 0x030d
    14aa:	0900                	.insn	2, 0x0900
    14ac:	0004                	.insn	2, 0x0004
    14ae:	0501                	.insn	2, 0x0501
    14b0:	821a                	.insn	2, 0x821a
    14b2:	097dce03          	lbu	t3,151(s11)
    14b6:	0004                	.insn	2, 0x0004
    14b8:	0301                	.insn	2, 0x0301
    14ba:	02b2                	.insn	2, 0x02b2
    14bc:	054a                	.insn	2, 0x054a
    14be:	030d                	.insn	2, 0x030d
    14c0:	0900                	.insn	2, 0x0900
    14c2:	0004                	.insn	2, 0x0004
    14c4:	0501                	.insn	2, 0x0501
    14c6:	821a                	.insn	2, 0x821a
    14c8:	097dce03          	lbu	t3,151(s11)
    14cc:	0004                	.insn	2, 0x0004
    14ce:	0301                	.insn	2, 0x0301
    14d0:	02b2                	.insn	2, 0x02b2
    14d2:	054a                	.insn	2, 0x054a
    14d4:	030d                	.insn	2, 0x030d
    14d6:	0900                	.insn	2, 0x0900
    14d8:	0004                	.insn	2, 0x0004
    14da:	0501                	.insn	2, 0x0501
    14dc:	821a                	.insn	2, 0x821a
    14de:	097dce03          	lbu	t3,151(s11)
    14e2:	0004                	.insn	2, 0x0004
    14e4:	0301                	.insn	2, 0x0301
    14e6:	02b2                	.insn	2, 0x02b2
    14e8:	054a                	.insn	2, 0x054a
    14ea:	030d                	.insn	2, 0x030d
    14ec:	0900                	.insn	2, 0x0900
    14ee:	0004                	.insn	2, 0x0004
    14f0:	0501                	.insn	2, 0x0501
    14f2:	821a                	.insn	2, 0x821a
    14f4:	097dce03          	lbu	t3,151(s11)
    14f8:	0004                	.insn	2, 0x0004
    14fa:	0301                	.insn	2, 0x0301
    14fc:	02b2                	.insn	2, 0x02b2
    14fe:	054a                	.insn	2, 0x054a
    1500:	030d                	.insn	2, 0x030d
    1502:	0900                	.insn	2, 0x0900
    1504:	0004                	.insn	2, 0x0004
    1506:	0501                	.insn	2, 0x0501
    1508:	821a                	.insn	2, 0x821a
    150a:	097dce03          	lbu	t3,151(s11)
    150e:	0004                	.insn	2, 0x0004
    1510:	0301                	.insn	2, 0x0301
    1512:	02b2                	.insn	2, 0x02b2
    1514:	054a                	.insn	2, 0x054a
    1516:	030d                	.insn	2, 0x030d
    1518:	0900                	.insn	2, 0x0900
    151a:	0004                	.insn	2, 0x0004
    151c:	0501                	.insn	2, 0x0501
    151e:	821a                	.insn	2, 0x821a
    1520:	097dce03          	lbu	t3,151(s11)
    1524:	0004                	.insn	2, 0x0004
    1526:	0301                	.insn	2, 0x0301
    1528:	02b2                	.insn	2, 0x02b2
    152a:	054a                	.insn	2, 0x054a
    152c:	030d                	.insn	2, 0x030d
    152e:	0900                	.insn	2, 0x0900
    1530:	0004                	.insn	2, 0x0004
    1532:	0501                	.insn	2, 0x0501
    1534:	821a                	.insn	2, 0x821a
    1536:	097dce03          	lbu	t3,151(s11)
    153a:	0004                	.insn	2, 0x0004
    153c:	0301                	.insn	2, 0x0301
    153e:	02b2                	.insn	2, 0x02b2
    1540:	054a                	.insn	2, 0x054a
    1542:	030d                	.insn	2, 0x030d
    1544:	0900                	.insn	2, 0x0900
    1546:	0004                	.insn	2, 0x0004
    1548:	0501                	.insn	2, 0x0501
    154a:	821a                	.insn	2, 0x821a
    154c:	097dce03          	lbu	t3,151(s11)
    1550:	0004                	.insn	2, 0x0004
    1552:	0301                	.insn	2, 0x0301
    1554:	02b2                	.insn	2, 0x02b2
    1556:	054a                	.insn	2, 0x054a
    1558:	0612                	.insn	2, 0x0612
    155a:	04090503          	lb	a0,64(s2)
    155e:	0100                	.insn	2, 0x0100
    1560:	0f05                	.insn	2, 0x0f05
    1562:	e4080a03          	lb	s4,-448(a6)
    1566:	0312054b          	.insn	4, 0x0312054b
    156a:	4a75                	.insn	2, 0x4a75
    156c:	1405                	.insn	2, 0x1405
    156e:	0586                	.insn	2, 0x0586
    1570:	0612                	.insn	2, 0x0612
    1572:	e408                	.insn	2, 0xe408
    1574:	1405                	.insn	2, 0x1405
    1576:	05f2                	.insn	2, 0x05f2
    1578:	ba12                	.insn	2, 0xba12
    157a:	f27dc503          	lbu	a0,-217(s11)
    157e:	0306                	.insn	2, 0x0306
    1580:	054a02b7          	lui	t0,0x54a0
    1584:	820c030f          	.insn	4, 0x820c030f
    1588:	0312054b          	.insn	4, 0x0312054b
    158c:	0f054a77          	.insn	4, 0x0f054a77
    1590:	03bd                	.insn	2, 0x03bd
    1592:	4a09                	.insn	2, 0x4a09
    1594:	054b4b4b          	.insn	4, 0x054b4b4b
    1598:	4c09                	.insn	2, 0x4c09
    159a:	05fa                	.insn	2, 0x05fa
    159c:	f40d                	.insn	2, 0xf40d
    159e:	0306                	.insn	2, 0x0306
    15a0:	7daa                	.insn	2, 0x7daa
    15a2:	1409                	.insn	2, 0x1409
    15a4:	0100                	.insn	2, 0x0100
    15a6:	0905                	.insn	2, 0x0905
    15a8:	0306                	.insn	2, 0x0306
    15aa:	02d9                	.insn	2, 0x02d9
    15ac:	0682                	.insn	2, 0x0682
    15ae:	087da703          	lw	a4,135(s11)
    15b2:	053c                	.insn	2, 0x053c
    15b4:	0601                	.insn	2, 0x0601
    15b6:	4a02df03          	lhu	t5,1184(t0) # 54a04a0 <USER_MAX+0x4fa04a0>
    15ba:	0b06                	.insn	2, 0x0b06
    15bc:	024a                	.insn	2, 0x024a
    15be:	0020                	.insn	2, 0x0020
    15c0:	0101                	.insn	2, 0x0101

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
