
./build/shell.elf:     file format elf32-littleriscv


Disassembly of section .text:

00400000 <start>:

/* ===== エントリ ===== */
__attribute__((section(".text.start")))
__attribute__((naked))
void start(void) {
    __asm__ __volatile__(
  400000:	00423537          	lui	a0,0x423
  400004:	3d050513          	addi	a0,a0,976 # 4233d0 <__user_stack_top>
  400008:	00050113          	mv	sp,a0
  40000c:	00000097          	auipc	ra,0x0
  400010:	010080e7          	jalr	16(ra) # 40001c <main>
  400014:	00001097          	auipc	ra,0x1
  400018:	9ec080e7          	jalr	-1556(ra) # 400a00 <exit>

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

    // DUMP API call
    //call_dump_api();


    printf("shell start.\n");
  400054:	00402537          	lui	a0,0x402
  400058:	ed450513          	addi	a0,a0,-300 # 401ed4 <__modsi3+0x68>
  40005c:	00001097          	auipc	ra,0x1
  400060:	dc4080e7          	jalr	-572(ra) # 400e20 <printf>
  400064:	00000913          	li	s2,0
  400068:	02000d13          	li	s10,32
  40006c:	00402437          	lui	s0,0x402
  400070:	ee240413          	addi	s0,s0,-286 # 401ee2 <__modsi3+0x76>
  400074:	004024b7          	lui	s1,0x402
  400078:	eef48493          	addi	s1,s1,-273 # 401eef <__modsi3+0x83>
  40007c:	00a00c13          	li	s8,10
  400080:	00c00c93          	li	s9,12
  400084:	00800b93          	li	s7,8
  400088:	00900b13          	li	s6,9
  40008c:	00018537          	lui	a0,0x18
  400090:	6a050513          	addi	a0,a0,1696 # 186a0 <start-0x3e7960>
  400094:	00a12423          	sw	a0,8(sp)
  400098:	01f00a93          	li	s5,31
  40009c:	07f00993          	li	s3,127
  4000a0:	0180006f          	j	4000b8 <main+0x9c>

        if (argc == 0) continue;

        /* ===== コマンド分岐 ===== */
        if (strcmp(argv[0], "hello") == 0) {
            printf("Hello world from shell!\n");
  4000a4:	00402537          	lui	a0,0x402
  4000a8:	f0250513          	addi	a0,a0,-254 # 401f02 <__modsi3+0x96>
  4000ac:	00001097          	auipc	ra,0x1
  4000b0:	d74080e7          	jalr	-652(ra) # 400e20 <printf>
  4000b4:	01f00a93          	li	s5,31
        putchar(0x1B); putchar('['); putchar('3'); putchar('4'); putchar('m'); // 青
  4000b8:	01b00513          	li	a0,27
  4000bc:	00001097          	auipc	ra,0x1
  4000c0:	c84080e7          	jalr	-892(ra) # 400d40 <putchar>
  4000c4:	05b00513          	li	a0,91
  4000c8:	00001097          	auipc	ra,0x1
  4000cc:	c78080e7          	jalr	-904(ra) # 400d40 <putchar>
  4000d0:	03300513          	li	a0,51
  4000d4:	00001097          	auipc	ra,0x1
  4000d8:	c6c080e7          	jalr	-916(ra) # 400d40 <putchar>
  4000dc:	03400513          	li	a0,52
  4000e0:	00001097          	auipc	ra,0x1
  4000e4:	c60080e7          	jalr	-928(ra) # 400d40 <putchar>
  4000e8:	06d00513          	li	a0,109
  4000ec:	00001097          	auipc	ra,0x1
  4000f0:	c54080e7          	jalr	-940(ra) # 400d40 <putchar>
        putchar('P');
  4000f4:	05000513          	li	a0,80
  4000f8:	00001097          	auipc	ra,0x1
  4000fc:	c48080e7          	jalr	-952(ra) # 400d40 <putchar>
        putchar('S');
  400100:	05300513          	li	a0,83
  400104:	00001097          	auipc	ra,0x1
  400108:	c3c080e7          	jalr	-964(ra) # 400d40 <putchar>
        putchar('C');
  40010c:	04300513          	li	a0,67
  400110:	00001097          	auipc	ra,0x1
  400114:	c30080e7          	jalr	-976(ra) # 400d40 <putchar>
        putchar('_');
  400118:	05f00513          	li	a0,95
  40011c:	00001097          	auipc	ra,0x1
  400120:	c24080e7          	jalr	-988(ra) # 400d40 <putchar>
        putchar('O');
  400124:	04f00513          	li	a0,79
  400128:	00001097          	auipc	ra,0x1
  40012c:	c18080e7          	jalr	-1000(ra) # 400d40 <putchar>
        putchar('S');
  400130:	05300513          	li	a0,83
  400134:	00001097          	auipc	ra,0x1
  400138:	c0c080e7          	jalr	-1012(ra) # 400d40 <putchar>
        putchar('>');
  40013c:	03e00513          	li	a0,62
  400140:	00001097          	auipc	ra,0x1
  400144:	c00080e7          	jalr	-1024(ra) # 400d40 <putchar>
        putchar(' ');
  400148:	02000513          	li	a0,32
  40014c:	00001097          	auipc	ra,0x1
  400150:	bf4080e7          	jalr	-1036(ra) # 400d40 <putchar>
        putchar(0x1B); putchar('['); putchar('0'); putchar('m'); // リセット
  400154:	01b00513          	li	a0,27
  400158:	00001097          	auipc	ra,0x1
  40015c:	be8080e7          	jalr	-1048(ra) # 400d40 <putchar>
  400160:	05b00513          	li	a0,91
  400164:	00001097          	auipc	ra,0x1
  400168:	bdc080e7          	jalr	-1060(ra) # 400d40 <putchar>
  40016c:	03000513          	li	a0,48
  400170:	00001097          	auipc	ra,0x1
  400174:	bd0080e7          	jalr	-1072(ra) # 400d40 <putchar>
  400178:	06d00513          	li	a0,109
  40017c:	00000a13          	li	s4,0
  400180:	0ff57513          	zext.b	a0,a0
  400184:	00001097          	auipc	ra,0x1
  400188:	bbc080e7          	jalr	-1092(ra) # 400d40 <putchar>
  40018c:	00090d93          	mv	s11,s2
  400190:	0100006f          	j	4001a0 <main+0x184>
            if (ch == 8 || ch == 127) {
  400194:	07351e63          	bne	a0,s3,400210 <main+0x1f4>
  400198:	00090d93          	mv	s11,s2
                if (len > 0) {
  40019c:	0b404263          	bgtz	s4,400240 <main+0x224>
            uint32_t sw = poll_switch_api() & 0x03;
  4001a0:	00001097          	auipc	ra,0x1
  4001a4:	104080e7          	jalr	260(ra) # 4012a4 <poll_switch_api>
            bool sw1_pressed = ((prev_sw & 0x01) != 0) && ((sw & 0x01) == 0);
  4001a8:	001df593          	andi	a1,s11,1
            uint32_t sw = poll_switch_api() & 0x03;
  4001ac:	00050913          	mv	s2,a0
            if (sw1_pressed) {
  4001b0:	00058c63          	beqz	a1,4001c8 <main+0x1ac>
  4001b4:	00197513          	andi	a0,s2,1
  4001b8:	00051863          	bnez	a0,4001c8 <main+0x1ac>
                printf("SW1 pressed\n");
  4001bc:	00040513          	mv	a0,s0
  4001c0:	00001097          	auipc	ra,0x1
  4001c4:	c60080e7          	jalr	-928(ra) # 400e20 <printf>
  4001c8:	001dd513          	srli	a0,s11,0x1
  4001cc:	00297593          	andi	a1,s2,2
  4001d0:	0015b593          	seqz	a1,a1
  4001d4:	00b57533          	and	a0,a0,a1
            if (sw2_pressed) {
  4001d8:	00050863          	beqz	a0,4001e8 <main+0x1cc>
                printf("SW2 pressed\n");
  4001dc:	00048513          	mv	a0,s1
  4001e0:	00001097          	auipc	ra,0x1
  4001e4:	c40080e7          	jalr	-960(ra) # 400e20 <printf>
            int ch = getchar_timeout();
  4001e8:	00001097          	auipc	ra,0x1
  4001ec:	09c080e7          	jalr	156(ra) # 401284 <getchar_timeout>
  4001f0:	00090d93          	mv	s11,s2
            if (ch < 0) {
  4001f4:	fa0546e3          	bltz	a0,4001a0 <main+0x184>
            if (ch == '\n' && len == 0) {
  4001f8:	01851463          	bne	a0,s8,400200 <main+0x1e4>
  4001fc:	f80a08e3          	beqz	s4,40018c <main+0x170>
            if (ch == 8 || ch == 127) {
  400200:	f8accae3          	blt	s9,a0,400194 <main+0x178>
  400204:	f9750ae3          	beq	a0,s7,400198 <main+0x17c>
  400208:	01851863          	bne	a0,s8,400218 <main+0x1fc>
  40020c:	0580006f          	j	400264 <main+0x248>
  400210:	00d00593          	li	a1,13
  400214:	04b50863          	beq	a0,a1,400264 <main+0x248>
  400218:	00aae663          	bltu	s5,a0,400224 <main+0x208>
  40021c:	00090d93          	mv	s11,s2
  400220:	f96510e3          	bne	a0,s6,4001a0 <main+0x184>
            if (len >= (int)sizeof(cmdline) - 1) {
  400224:	01e00593          	li	a1,30
  400228:	e945c8e3          	blt	a1,s4,4000b8 <main+0x9c>
            cmdline[len++] = (char)ch;
  40022c:	02c10593          	addi	a1,sp,44
  400230:	014585b3          	add	a1,a1,s4
  400234:	001a0a13          	addi	s4,s4,1
  400238:	00a58023          	sb	a0,0(a1)
        }
  40023c:	f45ff06f          	j	400180 <main+0x164>
                    len--;
  400240:	fffa0a13          	addi	s4,s4,-1
                    putchar('\b');
  400244:	00800513          	li	a0,8
  400248:	00001097          	auipc	ra,0x1
  40024c:	af8080e7          	jalr	-1288(ra) # 400d40 <putchar>
                    putchar(' ');
  400250:	02000513          	li	a0,32
  400254:	00001097          	auipc	ra,0x1
  400258:	aec080e7          	jalr	-1300(ra) # 400d40 <putchar>
  40025c:	00800513          	li	a0,8
                }
  400260:	f21ff06f          	j	400180 <main+0x164>
                putchar('\n');
  400264:	00a00513          	li	a0,10
  400268:	00001097          	auipc	ra,0x1
  40026c:	ad8080e7          	jalr	-1320(ra) # 400d40 <putchar>
                cmdline[len] = '\0';
  400270:	02c10513          	addi	a0,sp,44
  400274:	01450533          	add	a0,a0,s4
  400278:	00050023          	sb	zero,0(a0)
  40027c:	e20a0ee3          	beqz	s4,4000b8 <main+0x9c>
  400280:	02c10513          	addi	a0,sp,44
  400284:	0080006f          	j	40028c <main+0x270>
        while (*p == ' ' || *p == '\t') p++;
  400288:	00150513          	addi	a0,a0,1
  40028c:	00054583          	lbu	a1,0(a0)
  400290:	ff658ce3          	beq	a1,s6,400288 <main+0x26c>
  400294:	ffa58ae3          	beq	a1,s10,400288 <main+0x26c>
  400298:	e20580e3          	beqz	a1,4000b8 <main+0x9c>
  40029c:	00000a93          	li	s5,0
  4002a0:	00c10693          	addi	a3,sp,12
  4002a4:	00600713          	li	a4,6
  4002a8:	00050593          	mv	a1,a0
  4002ac:	000a8a13          	mv	s4,s5
            argv[argc++] = p;
  4002b0:	001a8a93          	addi	s5,s5,1
  4002b4:	002a1513          	slli	a0,s4,0x2
  4002b8:	00a68533          	add	a0,a3,a0
  4002bc:	00b52023          	sw	a1,0(a0)
            while (*p && *p != ' ' && *p != '\t') p++;
  4002c0:	00158513          	addi	a0,a1,1
  4002c4:	0005c603          	lbu	a2,0(a1)
  4002c8:	04060063          	beqz	a2,400308 <main+0x2ec>
  4002cc:	01660e63          	beq	a2,s6,4002e8 <main+0x2cc>
  4002d0:	01a60c63          	beq	a2,s10,4002e8 <main+0x2cc>
  4002d4:	00158593          	addi	a1,a1,1
  4002d8:	00150513          	addi	a0,a0,1
  4002dc:	0005c603          	lbu	a2,0(a1)
  4002e0:	fe0616e3          	bnez	a2,4002cc <main+0x2b0>
  4002e4:	0240006f          	j	400308 <main+0x2ec>
            *p++ = '\0';
  4002e8:	00058023          	sb	zero,0(a1)
  4002ec:	0080006f          	j	4002f4 <main+0x2d8>
  4002f0:	00150513          	addi	a0,a0,1
            while (*p == ' ' || *p == '\t') p++;
  4002f4:	00054583          	lbu	a1,0(a0)
  4002f8:	ffa58ce3          	beq	a1,s10,4002f0 <main+0x2d4>
  4002fc:	ff658ae3          	beq	a1,s6,4002f0 <main+0x2d4>
        while (*p && argc < ARGV_MAX) {
  400300:	00058463          	beqz	a1,400308 <main+0x2ec>
  400304:	fb4772e3          	bgeu	a4,s4,4002a8 <main+0x28c>
        if (strcmp(argv[0], "hello") == 0) {
  400308:	00c12503          	lw	a0,12(sp)
  40030c:	00050d93          	mv	s11,a0
  400310:	004025b7          	lui	a1,0x402
  400314:	efc58593          	addi	a1,a1,-260 # 401efc <__modsi3+0x90>
  400318:	00001097          	auipc	ra,0x1
  40031c:	e30080e7          	jalr	-464(ra) # 401148 <strcmp>
  400320:	d80502e3          	beqz	a0,4000a4 <main+0x88>

        // ---- Dump ----
        } else if (strcmp(argv[0], "dump") == 0) {
  400324:	000d8513          	mv	a0,s11
  400328:	004025b7          	lui	a1,0x402
  40032c:	f1b58593          	addi	a1,a1,-229 # 401f1b <__modsi3+0xaf>
  400330:	00001097          	auipc	ra,0x1
  400334:	e18080e7          	jalr	-488(ra) # 401148 <strcmp>
  400338:	18050463          	beqz	a0,4004c0 <main+0x4a4>
            unsigned lenb = (argc >= 3) ? parse_u32(argv[2]) : 0x100;
            hexdump((const void*)addr, lenb, (uintptr_t)addr);
        */

        // ---- 素数出力サンプル ----
        } else if (strcmp(argv[0], "primes") == 0) {
  40033c:	000d8513          	mv	a0,s11
  400340:	004025b7          	lui	a1,0x402
  400344:	f2058593          	addi	a1,a1,-224 # 401f20 <__modsi3+0xb4>
  400348:	00001097          	auipc	ra,0x1
  40034c:	e00080e7          	jalr	-512(ra) # 401148 <strcmp>
  400350:	01f00a93          	li	s5,31
  400354:	1a050e63          	beqz	a0,400510 <main+0x4f4>
                }
            }
            cmd_primes(max);

        // ---- セルフテスト ----
        } else if (strcmp(argv[0], "self_test") == 0) {
  400358:	000d8513          	mv	a0,s11
  40035c:	004025b7          	lui	a1,0x402
  400360:	f4158593          	addi	a1,a1,-191 # 401f41 <__modsi3+0xd5>
  400364:	00001097          	auipc	ra,0x1
  400368:	de4080e7          	jalr	-540(ra) # 401148 <strcmp>
  40036c:	d40506e3          	beqz	a0,4000b8 <main+0x9c>
            //TBD
            //cmd_primes(max);

        // ---- SynapEngine ----
        } else if (strcmp(argv[0], "sa_start") == 0) {
  400370:	000d8513          	mv	a0,s11
  400374:	004025b7          	lui	a1,0x402
  400378:	f4b58593          	addi	a1,a1,-181 # 401f4b <__modsi3+0xdf>
  40037c:	00001097          	auipc	ra,0x1
  400380:	dcc080e7          	jalr	-564(ra) # 401148 <strcmp>
  400384:	22050863          	beqz	a0,4005b4 <main+0x598>
            }
            // SA API call 
            call_sa_api(matrix_max);

        // ---- I2S MIC READ ----
        } else if (strcmp(argv[0], "mic_read") == 0) {
  400388:	000d8513          	mv	a0,s11
  40038c:	004025b7          	lui	a1,0x402
  400390:	f6558593          	addi	a1,a1,-155 # 401f65 <__modsi3+0xf9>
  400394:	00001097          	auipc	ra,0x1
  400398:	db4080e7          	jalr	-588(ra) # 401148 <strcmp>
  40039c:	26050663          	beqz	a0,400608 <main+0x5ec>

            unsigned count = parse_u32(argv[1]);
            call_mic_api(count);

        // ---- I2S MIC WRITE to FILE ----
        } else if (strcmp(argv[0], "mic_write") == 0) {
  4003a0:	000d8513          	mv	a0,s11
  4003a4:	004025b7          	lui	a1,0x402
  4003a8:	f8758593          	addi	a1,a1,-121 # 401f87 <__modsi3+0x11b>
  4003ac:	00001097          	auipc	ra,0x1
  4003b0:	d9c080e7          	jalr	-612(ra) # 401148 <strcmp>
  4003b4:	2c050863          	beqz	a0,400684 <main+0x668>
            unsigned count = parse_u32(argv[1]);
            //call_mic_write_api(count);
            call_mic_write_file(count);

        // ---- SDカードREAD ----
        } else if (strcmp(argv[0], "sd_read") == 0) {
  4003b8:	000d8513          	mv	a0,s11
  4003bc:	004025b7          	lui	a1,0x402
  4003c0:	fab58593          	addi	a1,a1,-85 # 401fab <__modsi3+0x13f>
  4003c4:	00001097          	auipc	ra,0x1
  4003c8:	d84080e7          	jalr	-636(ra) # 401148 <strcmp>
  4003cc:	2e050863          	beqz	a0,4006bc <main+0x6a0>

            unsigned sd_sector = parse_u32(argv[1]);
            call_sd_read_api(sd_sector);

        // ---- SDカードWRITE TEST----
        } else if (strcmp(argv[0], "sd_write") == 0) {
  4003d0:	000d8513          	mv	a0,s11
  4003d4:	004025b7          	lui	a1,0x402
  4003d8:	fcc58593          	addi	a1,a1,-52 # 401fcc <__modsi3+0x160>
  4003dc:	00001097          	auipc	ra,0x1
  4003e0:	d6c080e7          	jalr	-660(ra) # 401148 <strcmp>
  4003e4:	34050a63          	beqz	a0,400738 <main+0x71c>
                goto prompt;
            }
            call_sd_write_test_api(sd_sector);

        // ---- FAT32 Info ----
        } else if (strcmp(argv[0], "fat32_info") == 0) {
  4003e8:	000d8513          	mv	a0,s11
  4003ec:	004025b7          	lui	a1,0x402
  4003f0:	00e58593          	addi	a1,a1,14 # 40200e <__modsi3+0x1a2>
  4003f4:	00001097          	auipc	ra,0x1
  4003f8:	d54080e7          	jalr	-684(ra) # 401148 <strcmp>
  4003fc:	36050e63          	beqz	a0,400778 <main+0x75c>
            printf("spc=%x\n",           g_fat32.sectors_per_cluster);
            printf("fat_begin=%x\n",     g_fat32.fat_begin);
            printf("data_begin=%x\n",    g_fat32.data_begin);

        // ---- FAT32 ls ----
        } else if (strcmp(argv[0], "fat32_ls") == 0) {
  400400:	000d8513          	mv	a0,s11
  400404:	004025b7          	lui	a1,0x402
  400408:	07058593          	addi	a1,a1,112 # 402070 <__modsi3+0x204>
  40040c:	00001097          	auipc	ra,0x1
  400410:	d3c080e7          	jalr	-708(ra) # 401148 <strcmp>
  400414:	38050463          	beqz	a0,40079c <main+0x780>

            fat32_ls();

        // ---- FAT32 cat ----
        } else if (strcmp(argv[0], "fat32_cat") == 0) {
  400418:	000d8513          	mv	a0,s11
  40041c:	004025b7          	lui	a1,0x402
  400420:	07958593          	addi	a1,a1,121 # 402079 <__modsi3+0x20d>
  400424:	00001097          	auipc	ra,0x1
  400428:	d24080e7          	jalr	-732(ra) # 401148 <strcmp>
  40042c:	36050e63          	beqz	a0,4007a8 <main+0x78c>
            }

            fat32_cat(argv[1]);

        // ---- FAT32 touch ----
        } else if (strcmp(argv[0], "fat32_touch") == 0) {
  400430:	000d8513          	mv	a0,s11
  400434:	004025b7          	lui	a1,0x402
  400438:	09c58593          	addi	a1,a1,156 # 40209c <__modsi3+0x230>
  40043c:	00001097          	auipc	ra,0x1
  400440:	d0c080e7          	jalr	-756(ra) # 401148 <strcmp>
  400444:	3e050863          	beqz	a0,400834 <main+0x818>
            if (fat32_touch(argv[1]) != 0) {
                printf("fat32_touch failed\n");
            } 
            
        // ---- Helps出力 ----
        } else if (strcmp(argv[0], "help") == 0) {
  400448:	000d8513          	mv	a0,s11
  40044c:	004025b7          	lui	a1,0x402
  400450:	0d758593          	addi	a1,a1,215 # 4020d7 <__modsi3+0x26b>
  400454:	00001097          	auipc	ra,0x1
  400458:	cf4080e7          	jalr	-780(ra) # 401148 <strcmp>
  40045c:	40050463          	beqz	a0,400864 <main+0x848>
            printf("  sa_start\n");
            printf("  sd_read\n");
            printf("  exit | quit | q\n");
            */

        } else if (strcmp(argv[0], "exit") == 0 ||
  400460:	000d8513          	mv	a0,s11
  400464:	004025b7          	lui	a1,0x402
  400468:	0e758593          	addi	a1,a1,231 # 4020e7 <__modsi3+0x27b>
  40046c:	00001097          	auipc	ra,0x1
  400470:	cdc080e7          	jalr	-804(ra) # 401148 <strcmp>
  400474:	40050263          	beqz	a0,400878 <main+0x85c>
                   strcmp(argv[0], "quit") == 0 ||
  400478:	000d8513          	mv	a0,s11
  40047c:	004025b7          	lui	a1,0x402
  400480:	0ec58593          	addi	a1,a1,236 # 4020ec <__modsi3+0x280>
  400484:	00001097          	auipc	ra,0x1
  400488:	cc4080e7          	jalr	-828(ra) # 401148 <strcmp>
  40048c:	3e050663          	beqz	a0,400878 <main+0x85c>
                   strcmp(argv[0], "q") == 0) {
  400490:	000d8513          	mv	a0,s11
  400494:	004025b7          	lui	a1,0x402
  400498:	0f158593          	addi	a1,a1,241 # 4020f1 <__modsi3+0x285>
  40049c:	00001097          	auipc	ra,0x1
  4004a0:	cac080e7          	jalr	-852(ra) # 401148 <strcmp>
                   strcmp(argv[0], "quit") == 0 ||
  4004a4:	3c050a63          	beqz	a0,400878 <main+0x85c>
            exit();
        
        } else {
            printf("unknown command: %s\n", argv[0]);
  4004a8:	00402537          	lui	a0,0x402
  4004ac:	0f350513          	addi	a0,a0,243 # 4020f3 <__modsi3+0x287>
  4004b0:	000d8593          	mv	a1,s11
  4004b4:	00001097          	auipc	ra,0x1
  4004b8:	96c080e7          	jalr	-1684(ra) # 400e20 <printf>
  4004bc:	bfdff06f          	j	4000b8 <main+0x9c>
  4004c0:	10000593          	li	a1,256
            if (argc >= 2) {
  4004c4:	060a0a63          	beqz	s4,400538 <main+0x51c>
                if (parse_hex(argv[1], &val) == 0) {
  4004c8:	01012683          	lw	a3,16(sp)
/* 簡易16進パーサ（"  0x1234" / "1234" 形式どちらも可） */
int parse_hex(const char *s, uintptr_t *out) {
    uintptr_t v = 0;

    /* skip leading spaces */
    while (*s == ' ' || *s == '\t') s++;
  4004cc:	00268693          	addi	a3,a3,2
  4004d0:	00600793          	li	a5,6
  4004d4:	00500813          	li	a6,5
  4004d8:	0080006f          	j	4004e0 <main+0x4c4>
  4004dc:	00168693          	addi	a3,a3,1
  4004e0:	ffe6c603          	lbu	a2,-2(a3)
  4004e4:	ff660ce3          	beq	a2,s6,4004dc <main+0x4c0>
  4004e8:	ffa60ae3          	beq	a2,s10,4004dc <main+0x4c0>
  4004ec:	03000513          	li	a0,48
  4004f0:	04a61e63          	bne	a2,a0,40054c <main+0x530>

    /* optional 0x / 0X */
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s += 2;
  4004f4:	fff6c503          	lbu	a0,-1(a3)
  4004f8:	02056513          	ori	a0,a0,32
  4004fc:	07800613          	li	a2,120
  400500:	12c51663          	bne	a0,a2,40062c <main+0x610>
    if (!*s) return -1;
  400504:	0006c603          	lbu	a2,0(a3)
  400508:	12061663          	bnez	a2,400634 <main+0x618>
  40050c:	0480006f          	j	400554 <main+0x538>
            if (argc >= 2) {
  400510:	0c0a0663          	beqz	s4,4005dc <main+0x5c0>
                max = parse_u32(argv[1]);
  400514:	01012503          	lw	a0,16(sp)
  400518:	00001097          	auipc	ra,0x1
  40051c:	c60080e7          	jalr	-928(ra) # 401178 <parse_u32>
  400520:	00050593          	mv	a1,a0
  400524:	00402537          	lui	a0,0x402
  400528:	f2750513          	addi	a0,a0,-217 # 401f27 <__modsi3+0xbb>
  40052c:	00812603          	lw	a2,8(sp)
                if (max > 100000) {
  400530:	0ab67863          	bgeu	a2,a1,4005e0 <main+0x5c4>
  400534:	25c0006f          	j	400790 <main+0x774>
  400538:	00200537          	lui	a0,0x200
  40053c:	01f00a93          	li	s5,31
            call_dump_api(addr, len);
  400540:	00001097          	auipc	ra,0x1
  400544:	bc8080e7          	jalr	-1080(ra) # 401108 <call_dump_api>
  400548:	b71ff06f          	j	4000b8 <main+0x9c>
  40054c:	ffe68693          	addi	a3,a3,-2
    if (!*s) return -1;
  400550:	0e061263          	bnez	a2,400634 <main+0x618>
  400554:	00200537          	lui	a0,0x200
            if (argc >= 3) {
  400558:	00200613          	li	a2,2
  40055c:	00ca9a63          	bne	s5,a2,400570 <main+0x554>
  400560:	01f00a93          	li	s5,31
            call_dump_api(addr, len);
  400564:	00001097          	auipc	ra,0x1
  400568:	ba4080e7          	jalr	-1116(ra) # 401108 <call_dump_api>
  40056c:	b4dff06f          	j	4000b8 <main+0x9c>
                if (parse_hex(argv[2], &val) == 0) {
  400570:	01412683          	lw	a3,20(sp)
    while (*s == ' ' || *s == '\t') s++;
  400574:	00268693          	addi	a3,a3,2
  400578:	0080006f          	j	400580 <main+0x564>
  40057c:	00168693          	addi	a3,a3,1
  400580:	ffe6c603          	lbu	a2,-2(a3)
  400584:	ff660ce3          	beq	a2,s6,40057c <main+0x560>
  400588:	ffa60ae3          	beq	a2,s10,40057c <main+0x560>
  40058c:	03000713          	li	a4,48
  400590:	06e61063          	bne	a2,a4,4005f0 <main+0x5d4>
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s += 2;
  400594:	fff6c603          	lbu	a2,-1(a3)
  400598:	02066613          	ori	a2,a2,32
  40059c:	07800713          	li	a4,120
  4005a0:	01f00a93          	li	s5,31
  4005a4:	12e61e63          	bne	a2,a4,4006e0 <main+0x6c4>
    if (!*s) return -1;
  4005a8:	0006c603          	lbu	a2,0(a3)
  4005ac:	12061e63          	bnez	a2,4006e8 <main+0x6cc>
  4005b0:	04c0006f          	j	4005fc <main+0x5e0>
            if (argc >= 2) {
  4005b4:	0e0a0a63          	beqz	s4,4006a8 <main+0x68c>
                matrix_max = parse_u32(argv[1]);
  4005b8:	01012503          	lw	a0,16(sp)
  4005bc:	00001097          	auipc	ra,0x1
  4005c0:	bbc080e7          	jalr	-1092(ra) # 401178 <parse_u32>
  4005c4:	00050593          	mv	a1,a0
  4005c8:	00402537          	lui	a0,0x402
  4005cc:	f5450513          	addi	a0,a0,-172 # 401f54 <__modsi3+0xe8>
                if (matrix_max > 4) {
  4005d0:	00400613          	li	a2,4
  4005d4:	0cb67c63          	bgeu	a2,a1,4006ac <main+0x690>
  4005d8:	1b80006f          	j	400790 <main+0x774>
  4005dc:	3e800593          	li	a1,1000
            cmd_primes(max);
  4005e0:	00058513          	mv	a0,a1
  4005e4:	00000097          	auipc	ra,0x0
  4005e8:	360080e7          	jalr	864(ra) # 400944 <cmd_primes>
        } else if (strcmp(argv[0], "exit") == 0 ||
  4005ec:	acdff06f          	j	4000b8 <main+0x9c>
  4005f0:	ffe68693          	addi	a3,a3,-2
  4005f4:	01f00a93          	li	s5,31
    if (!*s) return -1;
  4005f8:	0e061863          	bnez	a2,4006e8 <main+0x6cc>
            call_dump_api(addr, len);
  4005fc:	00001097          	auipc	ra,0x1
  400600:	b0c080e7          	jalr	-1268(ra) # 401108 <call_dump_api>
  400604:	ab5ff06f          	j	4000b8 <main+0x9c>
  400608:	00402537          	lui	a0,0x402
  40060c:	f6e50513          	addi	a0,a0,-146 # 401f6e <__modsi3+0x102>
            if (argc < 2) {
  400610:	180a0063          	beqz	s4,400790 <main+0x774>
            unsigned count = parse_u32(argv[1]);
  400614:	01012503          	lw	a0,16(sp)
  400618:	00001097          	auipc	ra,0x1
  40061c:	b60080e7          	jalr	-1184(ra) # 401178 <parse_u32>
            call_mic_api(count);
  400620:	00000097          	auipc	ra,0x0
  400624:	748080e7          	jalr	1864(ra) # 400d68 <call_mic_api>
        } else if (strcmp(argv[0], "exit") == 0 ||
  400628:	a91ff06f          	j	4000b8 <main+0x9c>
  40062c:	ffe68693          	addi	a3,a3,-2
  400630:	03000613          	li	a2,48
  400634:	00000513          	li	a0,0

    while (*s) {
        char c = *s++;
        uint32_t d;
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  400638:	00168693          	addi	a3,a3,1
  40063c:	0200006f          	j	40065c <main+0x640>
  400640:	fd000713          	li	a4,-48
  400644:	00c70733          	add	a4,a4,a2
    while (*s) {
  400648:	0006c603          	lbu	a2,0(a3)
        else if (c >= 'a' && c <= 'f') d = 10u + (uint32_t)(c - 'a');
        else if (c >= 'A' && c <= 'F') d = 10u + (uint32_t)(c - 'A');
        else break;
        v = (v << 4) | d;
  40064c:	00451513          	slli	a0,a0,0x4
  400650:	00a76533          	or	a0,a4,a0
    while (*s) {
  400654:	00168693          	addi	a3,a3,1
  400658:	f00600e3          	beqz	a2,400558 <main+0x53c>
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  40065c:	fd060713          	addi	a4,a2,-48
  400660:	ff8760e3          	bltu	a4,s8,400640 <main+0x624>
        else if (c >= 'a' && c <= 'f') d = 10u + (uint32_t)(c - 'a');
  400664:	f9f60713          	addi	a4,a2,-97
  400668:	00f77663          	bgeu	a4,a5,400674 <main+0x658>
  40066c:	fa900713          	li	a4,-87
  400670:	fd5ff06f          	j	400644 <main+0x628>
        else if (c >= 'A' && c <= 'F') d = 10u + (uint32_t)(c - 'A');
  400674:	fbf60713          	addi	a4,a2,-65
  400678:	eee860e3          	bltu	a6,a4,400558 <main+0x53c>
  40067c:	fc900713          	li	a4,-55
  400680:	fc5ff06f          	j	400644 <main+0x628>
  400684:	00402537          	lui	a0,0x402
  400688:	f9150513          	addi	a0,a0,-111 # 401f91 <__modsi3+0x125>
            if (argc < 2) {
  40068c:	100a0263          	beqz	s4,400790 <main+0x774>
            unsigned count = parse_u32(argv[1]);
  400690:	01012503          	lw	a0,16(sp)
  400694:	00001097          	auipc	ra,0x1
  400698:	ae4080e7          	jalr	-1308(ra) # 401178 <parse_u32>
            call_mic_write_file(count);
  40069c:	00000097          	auipc	ra,0x0
  4006a0:	6d8080e7          	jalr	1752(ra) # 400d74 <call_mic_write_file>
        } else if (strcmp(argv[0], "fat32_touch") == 0) {
  4006a4:	a15ff06f          	j	4000b8 <main+0x9c>
  4006a8:	00400593          	li	a1,4
            call_sa_api(matrix_max);
  4006ac:	00058513          	mv	a0,a1
  4006b0:	00000097          	auipc	ra,0x0
  4006b4:	368080e7          	jalr	872(ra) # 400a18 <call_sa_api>
        } else if (strcmp(argv[0], "exit") == 0 ||
  4006b8:	a01ff06f          	j	4000b8 <main+0x9c>
  4006bc:	00402537          	lui	a0,0x402
  4006c0:	fb350513          	addi	a0,a0,-77 # 401fb3 <__modsi3+0x147>
            if (argc < 2) {
  4006c4:	0c0a0663          	beqz	s4,400790 <main+0x774>
            unsigned sd_sector = parse_u32(argv[1]);
  4006c8:	01012503          	lw	a0,16(sp)
  4006cc:	00001097          	auipc	ra,0x1
  4006d0:	aac080e7          	jalr	-1364(ra) # 401178 <parse_u32>
            call_sd_read_api(sd_sector);
  4006d4:	00001097          	auipc	ra,0x1
  4006d8:	a10080e7          	jalr	-1520(ra) # 4010e4 <call_sd_read_api>
        } else if (strcmp(argv[0], "exit") == 0 ||
  4006dc:	9ddff06f          	j	4000b8 <main+0x9c>
  4006e0:	ffe68693          	addi	a3,a3,-2
  4006e4:	03000613          	li	a2,48
  4006e8:	00000593          	li	a1,0
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  4006ec:	00168693          	addi	a3,a3,1
  4006f0:	0200006f          	j	400710 <main+0x6f4>
  4006f4:	fd000713          	li	a4,-48
  4006f8:	00c70733          	add	a4,a4,a2
    while (*s) {
  4006fc:	0006c603          	lbu	a2,0(a3)
        v = (v << 4) | d;
  400700:	00459593          	slli	a1,a1,0x4
  400704:	00b765b3          	or	a1,a4,a1
    while (*s) {
  400708:	00168693          	addi	a3,a3,1
  40070c:	ee0608e3          	beqz	a2,4005fc <main+0x5e0>
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  400710:	fd060713          	addi	a4,a2,-48
  400714:	ff8760e3          	bltu	a4,s8,4006f4 <main+0x6d8>
        else if (c >= 'a' && c <= 'f') d = 10u + (uint32_t)(c - 'a');
  400718:	f9f60713          	addi	a4,a2,-97
  40071c:	00f77663          	bgeu	a4,a5,400728 <main+0x70c>
  400720:	fa900713          	li	a4,-87
  400724:	fd5ff06f          	j	4006f8 <main+0x6dc>
        else if (c >= 'A' && c <= 'F') d = 10u + (uint32_t)(c - 'A');
  400728:	fbf60713          	addi	a4,a2,-65
  40072c:	ece868e3          	bltu	a6,a4,4005fc <main+0x5e0>
  400730:	fc900713          	li	a4,-55
  400734:	fc5ff06f          	j	4006f8 <main+0x6dc>
  400738:	00402537          	lui	a0,0x402
  40073c:	fd550513          	addi	a0,a0,-43 # 401fd5 <__modsi3+0x169>
            if (argc < 2) {
  400740:	040a0863          	beqz	s4,400790 <main+0x774>
            unsigned sd_sector = parse_u32(argv[1]);
  400744:	01012503          	lw	a0,16(sp)
  400748:	00001097          	auipc	ra,0x1
  40074c:	a30080e7          	jalr	-1488(ra) # 401178 <parse_u32>
  400750:	00050593          	mv	a1,a0
            if (sd_sector < 5000) {
  400754:	00355613          	srli	a2,a0,0x3
  400758:	00402537          	lui	a0,0x402
  40075c:	fef50513          	addi	a0,a0,-17 # 401fef <__modsi3+0x183>
  400760:	27100693          	li	a3,625
  400764:	02d66663          	bltu	a2,a3,400790 <main+0x774>
            call_sd_write_test_api(sd_sector);
  400768:	00058513          	mv	a0,a1
  40076c:	00001097          	auipc	ra,0x1
  400770:	984080e7          	jalr	-1660(ra) # 4010f0 <call_sd_write_test_api>
        } else if (strcmp(argv[0], "exit") == 0 ||
  400774:	945ff06f          	j	4000b8 <main+0x9c>
            if (fat32_mount() != 0) {
  400778:	00001097          	auipc	ra,0x1
  40077c:	c24080e7          	jalr	-988(ra) # 40139c <fat32_mount>
  400780:	00050593          	mv	a1,a0
  400784:	00402537          	lui	a0,0x402
  400788:	01950513          	addi	a0,a0,25 # 402019 <__modsi3+0x1ad>
  40078c:	02058c63          	beqz	a1,4007c4 <main+0x7a8>
  400790:	00000097          	auipc	ra,0x0
  400794:	690080e7          	jalr	1680(ra) # 400e20 <printf>
        } else if (strcmp(argv[0], "exit") == 0 ||
  400798:	921ff06f          	j	4000b8 <main+0x9c>
            fat32_ls();
  40079c:	00001097          	auipc	ra,0x1
  4007a0:	f7c080e7          	jalr	-132(ra) # 401718 <fat32_ls>
        } else if (strcmp(argv[0], "fat32_cat") == 0) {
  4007a4:	915ff06f          	j	4000b8 <main+0x9c>
  4007a8:	00402537          	lui	a0,0x402
  4007ac:	08350513          	addi	a0,a0,131 # 402083 <__modsi3+0x217>
            if (argc < 2) {
  4007b0:	fe0a00e3          	beqz	s4,400790 <main+0x774>
            fat32_cat(argv[1]);
  4007b4:	01012503          	lw	a0,16(sp)
  4007b8:	00001097          	auipc	ra,0x1
  4007bc:	af8080e7          	jalr	-1288(ra) # 4012b0 <fat32_cat>
        } else if (strcmp(argv[0], "fat32_touch") == 0) {
  4007c0:	8f9ff06f          	j	4000b8 <main+0x9c>
  4007c4:	00402537          	lui	a0,0x402
            printf("part_lba=%x\n",      g_fat32.part_lba);
  4007c8:	1bc52583          	lw	a1,444(a0) # 4021bc <g_fat32>
  4007cc:	1bc50a13          	addi	s4,a0,444
  4007d0:	00402537          	lui	a0,0x402
  4007d4:	02d50513          	addi	a0,a0,45 # 40202d <__modsi3+0x1c1>
  4007d8:	00000097          	auipc	ra,0x0
  4007dc:	648080e7          	jalr	1608(ra) # 400e20 <printf>
            printf("root_cluster=%x\n",  g_fat32.root_cluster);
  4007e0:	00ca2583          	lw	a1,12(s4)
  4007e4:	00402537          	lui	a0,0x402
  4007e8:	03a50513          	addi	a0,a0,58 # 40203a <__modsi3+0x1ce>
  4007ec:	00000097          	auipc	ra,0x0
  4007f0:	634080e7          	jalr	1588(ra) # 400e20 <printf>
            printf("spc=%x\n",           g_fat32.sectors_per_cluster);
  4007f4:	010a2583          	lw	a1,16(s4)
  4007f8:	00402537          	lui	a0,0x402
  4007fc:	04b50513          	addi	a0,a0,75 # 40204b <__modsi3+0x1df>
  400800:	00000097          	auipc	ra,0x0
  400804:	620080e7          	jalr	1568(ra) # 400e20 <printf>
            printf("fat_begin=%x\n",     g_fat32.fat_begin);
  400808:	004a2583          	lw	a1,4(s4)
  40080c:	00402537          	lui	a0,0x402
  400810:	05350513          	addi	a0,a0,83 # 402053 <__modsi3+0x1e7>
  400814:	00000097          	auipc	ra,0x0
  400818:	60c080e7          	jalr	1548(ra) # 400e20 <printf>
            printf("data_begin=%x\n",    g_fat32.data_begin);
  40081c:	008a2583          	lw	a1,8(s4)
  400820:	00402537          	lui	a0,0x402
  400824:	06150513          	addi	a0,a0,97 # 402061 <__modsi3+0x1f5>
  400828:	00000097          	auipc	ra,0x0
  40082c:	5f8080e7          	jalr	1528(ra) # 400e20 <printf>
  400830:	889ff06f          	j	4000b8 <main+0x9c>
  400834:	00402537          	lui	a0,0x402
  400838:	0a850513          	addi	a0,a0,168 # 4020a8 <__modsi3+0x23c>
            if (argc < 2) {
  40083c:	f40a0ae3          	beqz	s4,400790 <main+0x774>
            if (fat32_touch(argv[1]) != 0) {
  400840:	01012503          	lw	a0,16(sp)
  400844:	00001097          	auipc	ra,0x1
  400848:	15c080e7          	jalr	348(ra) # 4019a0 <fat32_touch>
  40084c:	860506e3          	beqz	a0,4000b8 <main+0x9c>
                printf("fat32_touch failed\n");
  400850:	00402537          	lui	a0,0x402
  400854:	0c350513          	addi	a0,a0,195 # 4020c3 <__modsi3+0x257>
  400858:	00000097          	auipc	ra,0x0
  40085c:	5c8080e7          	jalr	1480(ra) # 400e20 <printf>
        } else if (strcmp(argv[0], "exit") == 0 ||
  400860:	859ff06f          	j	4000b8 <main+0x9c>
            printf("commands:\n");
  400864:	00402537          	lui	a0,0x402
  400868:	0dc50513          	addi	a0,a0,220 # 4020dc <__modsi3+0x270>
  40086c:	00000097          	auipc	ra,0x0
  400870:	5b4080e7          	jalr	1460(ra) # 400e20 <printf>
        } else if (strcmp(argv[0], "exit") == 0 ||
  400874:	845ff06f          	j	4000b8 <main+0x9c>
            exit();
  400878:	00000097          	auipc	ra,0x0
  40087c:	188080e7          	jalr	392(ra) # 400a00 <exit>

00400880 <parse_hex>:
    while (*s == ' ' || *s == '\t') s++;
  400880:	00250693          	addi	a3,a0,2
  400884:	00900613          	li	a2,9
  400888:	02000713          	li	a4,32
  40088c:	0080006f          	j	400894 <parse_hex+0x14>
  400890:	00168693          	addi	a3,a3,1
  400894:	ffe6c503          	lbu	a0,-2(a3)
  400898:	fec50ce3          	beq	a0,a2,400890 <parse_hex+0x10>
  40089c:	fee50ae3          	beq	a0,a4,400890 <parse_hex+0x10>
  4008a0:	03000613          	li	a2,48
  4008a4:	02c51063          	bne	a0,a2,4008c4 <parse_hex+0x44>
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s += 2;
  4008a8:	fff6c503          	lbu	a0,-1(a3)
  4008ac:	02056513          	ori	a0,a0,32
  4008b0:	07800613          	li	a2,120
  4008b4:	02c51063          	bne	a0,a2,4008d4 <parse_hex+0x54>
    if (!*s) return -1;
  4008b8:	0006c503          	lbu	a0,0(a3)
  4008bc:	02051063          	bnez	a0,4008dc <parse_hex+0x5c>
  4008c0:	00c0006f          	j	4008cc <parse_hex+0x4c>
  4008c4:	ffe68693          	addi	a3,a3,-2
  4008c8:	00051a63          	bnez	a0,4008dc <parse_hex+0x5c>
  4008cc:	fff00513          	li	a0,-1
    }
    *out = v;
    return 0;
  4008d0:	00008067          	ret
  4008d4:	ffe68693          	addi	a3,a3,-2
  4008d8:	03000513          	li	a0,48
  4008dc:	00000613          	li	a2,0
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  4008e0:	00168693          	addi	a3,a3,1
  4008e4:	00a00713          	li	a4,10
  4008e8:	00600793          	li	a5,6
  4008ec:	00500813          	li	a6,5
  4008f0:	0200006f          	j	400910 <parse_hex+0x90>
  4008f4:	fd000893          	li	a7,-48
  4008f8:	00a888b3          	add	a7,a7,a0
    while (*s) {
  4008fc:	0006c503          	lbu	a0,0(a3)
        v = (v << 4) | d;
  400900:	00461613          	slli	a2,a2,0x4
  400904:	00c8e633          	or	a2,a7,a2
    while (*s) {
  400908:	00168693          	addi	a3,a3,1
  40090c:	02050663          	beqz	a0,400938 <parse_hex+0xb8>
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  400910:	fd050893          	addi	a7,a0,-48
  400914:	fee8e0e3          	bltu	a7,a4,4008f4 <parse_hex+0x74>
        else if (c >= 'a' && c <= 'f') d = 10u + (uint32_t)(c - 'a');
  400918:	f9f50893          	addi	a7,a0,-97
  40091c:	00f8f663          	bgeu	a7,a5,400928 <parse_hex+0xa8>
  400920:	fa900893          	li	a7,-87
  400924:	fd5ff06f          	j	4008f8 <parse_hex+0x78>
        else if (c >= 'A' && c <= 'F') d = 10u + (uint32_t)(c - 'A');
  400928:	fbf50893          	addi	a7,a0,-65
  40092c:	01186663          	bltu	a6,a7,400938 <parse_hex+0xb8>
  400930:	fc900893          	li	a7,-55
  400934:	fc5ff06f          	j	4008f8 <parse_hex+0x78>
  400938:	00000513          	li	a0,0
    *out = v;
  40093c:	00c5a023          	sw	a2,0(a1)
  400940:	00008067          	ret

00400944 <cmd_primes>:
{
  400944:	fe010113          	addi	sp,sp,-32
  400948:	00112e23          	sw	ra,28(sp)
  40094c:	00812c23          	sw	s0,24(sp)
  400950:	00912a23          	sw	s1,20(sp)
  400954:	01212823          	sw	s2,16(sp)
  400958:	01312623          	sw	s3,12(sp)
  40095c:	00200913          	li	s2,2
  400960:	00050413          	mv	s0,a0
  400964:	00000493          	li	s1,0
    for (unsigned n = 2; n <= max; n++) {
  400968:	07256463          	bltu	a0,s2,4009d0 <cmd_primes+0x8c>
  40096c:	004029b7          	lui	s3,0x402
  400970:	10898993          	addi	s3,s3,264 # 402108 <__modsi3+0x29c>
  400974:	00c0006f          	j	400980 <cmd_primes+0x3c>
  400978:	00190913          	addi	s2,s2,1
  40097c:	05246063          	bltu	s0,s2,4009bc <cmd_primes+0x78>
        if (is_prime(n)) {
  400980:	00090513          	mv	a0,s2
  400984:	00001097          	auipc	ra,0x1
  400988:	8b0080e7          	jalr	-1872(ra) # 401234 <is_prime>
  40098c:	fe0506e3          	beqz	a0,400978 <cmd_primes+0x34>
            printf("%d ", (int)n);
  400990:	00098513          	mv	a0,s3
  400994:	00090593          	mv	a1,s2
  400998:	00000097          	auipc	ra,0x0
  40099c:	488080e7          	jalr	1160(ra) # 400e20 <printf>
            count++;
  4009a0:	00148493          	addi	s1,s1,1
            if ((count % 8) == 0)
  4009a4:	0074f513          	andi	a0,s1,7
  4009a8:	fc0518e3          	bnez	a0,400978 <cmd_primes+0x34>
                putchar('\n');
  4009ac:	00a00513          	li	a0,10
  4009b0:	00000097          	auipc	ra,0x0
  4009b4:	390080e7          	jalr	912(ra) # 400d40 <putchar>
  4009b8:	fc1ff06f          	j	400978 <cmd_primes+0x34>
    if ((count % 8) != 0)
  4009bc:	0074f513          	andi	a0,s1,7
  4009c0:	00050863          	beqz	a0,4009d0 <cmd_primes+0x8c>
        putchar('\n');
  4009c4:	00a00513          	li	a0,10
  4009c8:	00000097          	auipc	ra,0x0
  4009cc:	378080e7          	jalr	888(ra) # 400d40 <putchar>
    printf("total primes: %d (0..%d)\n", count, (int)max);
  4009d0:	00402537          	lui	a0,0x402
  4009d4:	10c50513          	addi	a0,a0,268 # 40210c <__modsi3+0x2a0>
  4009d8:	00048593          	mv	a1,s1
  4009dc:	00040613          	mv	a2,s0
  4009e0:	01c12083          	lw	ra,28(sp)
  4009e4:	01812403          	lw	s0,24(sp)
  4009e8:	01412483          	lw	s1,20(sp)
  4009ec:	01012903          	lw	s2,16(sp)
  4009f0:	00c12983          	lw	s3,12(sp)
  4009f4:	02010113          	addi	sp,sp,32
  4009f8:	00000317          	auipc	t1,0x0
  4009fc:	42830067          	jr	1064(t1) # 400e20 <printf>

00400a00 <exit>:
    __asm__ __volatile__ (
  400a00:	05a00693          	li	a3,90
  400a04:	00000593          	li	a1,0
  400a08:	00000613          	li	a2,0
  400a0c:	00000513          	li	a0,0
  400a10:	00000073          	ecall
    for (;;);
  400a14:	0000006f          	j	400a14 <exit+0x14>

00400a18 <call_sa_api>:
{
  400a18:	000065b7          	lui	a1,0x6
  400a1c:	01058593          	addi	a1,a1,16 # 6010 <start-0x3f9ff0>
  400a20:	40b10133          	sub	sp,sp,a1
  400a24:	00050793          	mv	a5,a0
    for (uint32_t i = 0; i < matrix_size; i++) {
  400a28:	14050263          	beqz	a0,400b6c <call_sa_api+0x154>
  400a2c:	00000513          	li	a0,0
  400a30:	00000593          	li	a1,0
  400a34:	00005637          	lui	a2,0x5
  400a38:	01060613          	addi	a2,a2,16 # 5010 <start-0x3faff0>
  400a3c:	00c10633          	add	a2,sp,a2
  400a40:	000046b7          	lui	a3,0x4
  400a44:	01068693          	addi	a3,a3,16 # 4010 <start-0x3fbff0>
  400a48:	00d106b3          	add	a3,sp,a3
  400a4c:	00005737          	lui	a4,0x5
  400a50:	01070713          	addi	a4,a4,16 # 5010 <start-0x3faff0>
  400a54:	00e10733          	add	a4,sp,a4
        for (uint32_t j = 0; j < matrix_size; j++) {
  400a58:	00659813          	slli	a6,a1,0x6
  400a5c:	01078833          	add	a6,a5,a6
  400a60:	01060833          	add	a6,a2,a6
  400a64:	00068893          	mv	a7,a3
  400a68:	00070293          	mv	t0,a4
  400a6c:	00058313          	mv	t1,a1
  400a70:	00050393          	mv	t2,a0
            matrix_B[i][j] = (uint8_t)(3*i + j + 5);
  400a74:	00538e13          	addi	t3,t2,5
  400a78:	01c88023          	sb	t3,0(a7)
            matrix_A[i][j] = (uint8_t)(2*i + 2*j + 2);
  400a7c:	00131e13          	slli	t3,t1,0x1
        for (uint32_t j = 0; j < matrix_size; j++) {
  400a80:	00138393          	addi	t2,t2,1
  400a84:	00130313          	addi	t1,t1,1
            matrix_A[i][j] = (uint8_t)(2*i + 2*j + 2);
  400a88:	002e0e13          	addi	t3,t3,2
  400a8c:	01c28023          	sb	t3,0(t0)
        for (uint32_t j = 0; j < matrix_size; j++) {
  400a90:	00128293          	addi	t0,t0,1
  400a94:	00188893          	addi	a7,a7,1
  400a98:	fd029ee3          	bne	t0,a6,400a74 <call_sa_api+0x5c>
    for (uint32_t i = 0; i < matrix_size; i++) {
  400a9c:	00158593          	addi	a1,a1,1
  400aa0:	00350513          	addi	a0,a0,3
  400aa4:	04070713          	addi	a4,a4,64
  400aa8:	04068693          	addi	a3,a3,64
  400aac:	faf596e3          	bne	a1,a5,400a58 <call_sa_api+0x40>
  400ab0:	00000813          	li	a6,0
  400ab4:	00005537          	lui	a0,0x5
  400ab8:	01050513          	addi	a0,a0,16 # 5010 <start-0x3faff0>
  400abc:	00a108b3          	add	a7,sp,a0
  400ac0:	00004537          	lui	a0,0x4
  400ac4:	01050513          	addi	a0,a0,16 # 4010 <start-0x3fbff0>
  400ac8:	00a10333          	add	t1,sp,a0
  400acc:	01010393          	addi	t2,sp,16
  400ad0:	00a00293          	li	t0,10
  400ad4:	04100e13          	li	t3,65
    __asm__ __volatile__ (
  400ad8:	00088513          	mv	a0,a7
  400adc:	00030593          	mv	a1,t1
  400ae0:	00038613          	mv	a2,t2
  400ae4:	00028693          	mv	a3,t0
  400ae8:	00078713          	mv	a4,a5
  400aec:	00000073          	ecall
  400af0:	00050313          	mv	t1,a0
    __asm__ __volatile__ (
  400af4:	000e0513          	mv	a0,t3
  400af8:	00100693          	li	a3,1
  400afc:	00000073          	ecall
  400b00:	00028513          	mv	a0,t0
  400b04:	00100693          	li	a3,1
  400b08:	00000073          	ecall
  400b0c:	02000593          	li	a1,32
  400b10:	00005537          	lui	a0,0x5
  400b14:	01050513          	addi	a0,a0,16 # 5010 <start-0x3faff0>
  400b18:	00a10633          	add	a2,sp,a0
        for (uint32_t j = 0; j < matrix_size; j++) {
  400b1c:	00681513          	slli	a0,a6,0x6
  400b20:	00a78533          	add	a0,a5,a0
  400b24:	00a88733          	add	a4,a7,a0
  400b28:	00060313          	mv	t1,a2
            print_int((int)matrix_A[i][j]);
  400b2c:	00034383          	lbu	t2,0(t1)
    __asm__ __volatile__ (
  400b30:	00038513          	mv	a0,t2
  400b34:	05b00693          	li	a3,91
  400b38:	00000073          	ecall
    __asm__ __volatile__ (
  400b3c:	00058513          	mv	a0,a1
  400b40:	00100693          	li	a3,1
  400b44:	00000073          	ecall
        for (uint32_t j = 0; j < matrix_size; j++) {
  400b48:	00130313          	addi	t1,t1,1
  400b4c:	fee310e3          	bne	t1,a4,400b2c <call_sa_api+0x114>
    __asm__ __volatile__ (
  400b50:	00028513          	mv	a0,t0
  400b54:	00100693          	li	a3,1
  400b58:	00000073          	ecall
    for (uint32_t i = 0; i < matrix_size; i++) {
  400b5c:	00180813          	addi	a6,a6,1
  400b60:	04060613          	addi	a2,a2,64
  400b64:	faf81ce3          	bne	a6,a5,400b1c <call_sa_api+0x104>
  400b68:	05c0006f          	j	400bc4 <call_sa_api+0x1ac>
  400b6c:	00005537          	lui	a0,0x5
  400b70:	01050513          	addi	a0,a0,16 # 5010 <start-0x3faff0>
  400b74:	00a10833          	add	a6,sp,a0
  400b78:	00004537          	lui	a0,0x4
  400b7c:	01050513          	addi	a0,a0,16 # 4010 <start-0x3fbff0>
  400b80:	00a108b3          	add	a7,sp,a0
  400b84:	01010293          	addi	t0,sp,16
  400b88:	00a00313          	li	t1,10
  400b8c:	04100393          	li	t2,65
    __asm__ __volatile__ (
  400b90:	00080513          	mv	a0,a6
  400b94:	00088593          	mv	a1,a7
  400b98:	00028613          	mv	a2,t0
  400b9c:	00030693          	mv	a3,t1
  400ba0:	00078713          	mv	a4,a5
  400ba4:	00000073          	ecall
  400ba8:	00050813          	mv	a6,a0
    __asm__ __volatile__ (
  400bac:	00038513          	mv	a0,t2
  400bb0:	00100693          	li	a3,1
  400bb4:	00000073          	ecall
  400bb8:	00030513          	mv	a0,t1
  400bbc:	00100693          	li	a3,1
  400bc0:	00000073          	ecall
  400bc4:	00a00593          	li	a1,10
  400bc8:	04200613          	li	a2,66
  400bcc:	00058513          	mv	a0,a1
  400bd0:	00100693          	li	a3,1
  400bd4:	00000073          	ecall
  400bd8:	00060513          	mv	a0,a2
  400bdc:	00100693          	li	a3,1
  400be0:	00000073          	ecall
  400be4:	00058513          	mv	a0,a1
  400be8:	00100693          	li	a3,1
  400bec:	00000073          	ecall
    for (uint32_t i = 0; i < matrix_size; i++) {
  400bf0:	10078263          	beqz	a5,400cf4 <call_sa_api+0x2dc>
  400bf4:	00000593          	li	a1,0
  400bf8:	00004537          	lui	a0,0x4
  400bfc:	01050513          	addi	a0,a0,16 # 4010 <start-0x3fbff0>
  400c00:	00a10633          	add	a2,sp,a0
  400c04:	02000713          	li	a4,32
  400c08:	00a00813          	li	a6,10
  400c0c:	00004537          	lui	a0,0x4
  400c10:	01050513          	addi	a0,a0,16 # 4010 <start-0x3fbff0>
  400c14:	00a108b3          	add	a7,sp,a0
        for (uint32_t j = 0; j < matrix_size; j++) {
  400c18:	00659513          	slli	a0,a1,0x6
  400c1c:	00a78533          	add	a0,a5,a0
  400c20:	00a602b3          	add	t0,a2,a0
  400c24:	00088313          	mv	t1,a7
            print_int((int)matrix_B[i][j]);
  400c28:	00034383          	lbu	t2,0(t1)
    __asm__ __volatile__ (
  400c2c:	00038513          	mv	a0,t2
  400c30:	05b00693          	li	a3,91
  400c34:	00000073          	ecall
    __asm__ __volatile__ (
  400c38:	00070513          	mv	a0,a4
  400c3c:	00100693          	li	a3,1
  400c40:	00000073          	ecall
        for (uint32_t j = 0; j < matrix_size; j++) {
  400c44:	00130313          	addi	t1,t1,1
  400c48:	fe5310e3          	bne	t1,t0,400c28 <call_sa_api+0x210>
    __asm__ __volatile__ (
  400c4c:	00080513          	mv	a0,a6
  400c50:	00100693          	li	a3,1
  400c54:	00000073          	ecall
    for (uint32_t i = 0; i < matrix_size; i++) {
  400c58:	00158593          	addi	a1,a1,1
  400c5c:	04088893          	addi	a7,a7,64
  400c60:	faf59ce3          	bne	a1,a5,400c18 <call_sa_api+0x200>
  400c64:	00000593          	li	a1,0
  400c68:	00a00613          	li	a2,10
  400c6c:	04300713          	li	a4,67
    __asm__ __volatile__ (
  400c70:	00060513          	mv	a0,a2
  400c74:	00100693          	li	a3,1
  400c78:	00000073          	ecall
  400c7c:	00070513          	mv	a0,a4
  400c80:	00100693          	li	a3,1
  400c84:	00000073          	ecall
  400c88:	00060513          	mv	a0,a2
  400c8c:	00100693          	li	a3,1
  400c90:	00000073          	ecall
    for (uint32_t i = 0; i < matrix_size; i++) {
  400c94:	00279713          	slli	a4,a5,0x2
  400c98:	01010813          	addi	a6,sp,16
  400c9c:	02000893          	li	a7,32
  400ca0:	01010293          	addi	t0,sp,16
        for (uint32_t j = 0; j < matrix_size; j++) {
  400ca4:	00859513          	slli	a0,a1,0x8
  400ca8:	00a70533          	add	a0,a4,a0
  400cac:	00a80333          	add	t1,a6,a0
  400cb0:	00028393          	mv	t2,t0
            print_int((int)matrix_C[i][j]);
  400cb4:	0003ae03          	lw	t3,0(t2)
    __asm__ __volatile__ (
  400cb8:	000e0513          	mv	a0,t3
  400cbc:	05b00693          	li	a3,91
  400cc0:	00000073          	ecall
    __asm__ __volatile__ (
  400cc4:	00088513          	mv	a0,a7
  400cc8:	00100693          	li	a3,1
  400ccc:	00000073          	ecall
        for (uint32_t j = 0; j < matrix_size; j++) {
  400cd0:	00438393          	addi	t2,t2,4
  400cd4:	fe6390e3          	bne	t2,t1,400cb4 <call_sa_api+0x29c>
    __asm__ __volatile__ (
  400cd8:	00060513          	mv	a0,a2
  400cdc:	00100693          	li	a3,1
  400ce0:	00000073          	ecall
    for (uint32_t i = 0; i < matrix_size; i++) {
  400ce4:	00158593          	addi	a1,a1,1
  400ce8:	10028293          	addi	t0,t0,256
  400cec:	faf59ce3          	bne	a1,a5,400ca4 <call_sa_api+0x28c>
  400cf0:	0300006f          	j	400d20 <call_sa_api+0x308>
  400cf4:	00a00593          	li	a1,10
  400cf8:	04300613          	li	a2,67
    __asm__ __volatile__ (
  400cfc:	00058513          	mv	a0,a1
  400d00:	00100693          	li	a3,1
  400d04:	00000073          	ecall
  400d08:	00060513          	mv	a0,a2
  400d0c:	00100693          	li	a3,1
  400d10:	00000073          	ecall
  400d14:	00058513          	mv	a0,a1
  400d18:	00100693          	li	a3,1
  400d1c:	00000073          	ecall
  400d20:	00a00593          	li	a1,10
  400d24:	00058513          	mv	a0,a1
  400d28:	00100693          	li	a3,1
  400d2c:	00000073          	ecall
}
  400d30:	00006537          	lui	a0,0x6
  400d34:	01050513          	addi	a0,a0,16 # 6010 <start-0x3f9ff0>
  400d38:	00a10133          	add	sp,sp,a0
  400d3c:	00008067          	ret

00400d40 <putchar>:
{
  400d40:	00050593          	mv	a1,a0
    __asm__ __volatile__ (
  400d44:	00058513          	mv	a0,a1
  400d48:	00100693          	li	a3,1
  400d4c:	00000073          	ecall
}
  400d50:	00008067          	ret

00400d54 <print_int>:
{
  400d54:	00050593          	mv	a1,a0
    __asm__ __volatile__ (
  400d58:	00058513          	mv	a0,a1
  400d5c:	05b00693          	li	a3,91
  400d60:	00000073          	ecall
}
  400d64:	00008067          	ret

00400d68 <call_mic_api>:
    __asm__ __volatile__(
  400d68:	01400693          	li	a3,20
  400d6c:	00000073          	ecall
}
  400d70:	00008067          	ret

00400d74 <call_mic_write_file>:
{
  400d74:	fe010113          	addi	sp,sp,-32
  400d78:	00112e23          	sw	ra,28(sp)
  400d7c:	00812c23          	sw	s0,24(sp)
  400d80:	00912a23          	sw	s1,20(sp)
  400d84:	00050413          	mv	s0,a0
    if (fat32_find(
  400d88:	00402537          	lui	a0,0x402
  400d8c:	12650513          	addi	a0,a0,294 # 402126 <__modsi3+0x2ba>
  400d90:	01010593          	addi	a1,sp,16
  400d94:	00c10613          	addi	a2,sp,12
  400d98:	00000097          	auipc	ra,0x0
  400d9c:	6c0080e7          	jalr	1728(ra) # 401458 <fat32_find>
            &size) != 0) {
  400da0:	00050863          	beqz	a0,400db0 <call_mic_write_file+0x3c>
        printf("MIC.TXT not found\n");
  400da4:	00402537          	lui	a0,0x402
  400da8:	12e50513          	addi	a0,a0,302 # 40212e <__modsi3+0x2c2>
  400dac:	0180006f          	j	400dc4 <call_mic_write_file+0x50>
    if (cluster < 2) {
  400db0:	01012503          	lw	a0,16(sp)
  400db4:	00100593          	li	a1,1
  400db8:	02a5e663          	bltu	a1,a0,400de4 <call_mic_write_file+0x70>
        printf("MIC.TXT has no cluster\n");
  400dbc:	00402537          	lui	a0,0x402
  400dc0:	14150513          	addi	a0,a0,321 # 402141 <__modsi3+0x2d5>
  400dc4:	00000097          	auipc	ra,0x0
  400dc8:	05c080e7          	jalr	92(ra) # 400e20 <printf>
  400dcc:	00000513          	li	a0,0
}
  400dd0:	01c12083          	lw	ra,28(sp)
  400dd4:	01812403          	lw	s0,24(sp)
  400dd8:	01412483          	lw	s1,20(sp)
  400ddc:	02010113          	addi	sp,sp,32
  400de0:	00008067          	ret
        cluster_to_lba(cluster);
  400de4:	00001097          	auipc	ra,0x1
  400de8:	914080e7          	jalr	-1772(ra) # 4016f8 <cluster_to_lba>
        cluster,
  400dec:	01012583          	lw	a1,16(sp)
        size
  400df0:	00c12683          	lw	a3,12(sp)
        cluster_to_lba(cluster);
  400df4:	00050493          	mv	s1,a0
    printf(
  400df8:	00402537          	lui	a0,0x402
  400dfc:	15950513          	addi	a0,a0,345 # 402159 <__modsi3+0x2ed>
  400e00:	00048613          	mv	a2,s1
  400e04:	00000097          	auipc	ra,0x0
  400e08:	01c080e7          	jalr	28(ra) # 400e20 <printf>
    __asm__ __volatile__(
  400e0c:	01500693          	li	a3,21
  400e10:	00048593          	mv	a1,s1
  400e14:	00040513          	mv	a0,s0
  400e18:	00000073          	ecall
  400e1c:	fb5ff06f          	j	400dd0 <call_mic_write_file+0x5c>

00400e20 <printf>:
void printf(const char *fmt, ...) {
  400e20:	fc010113          	addi	sp,sp,-64
  400e24:	00812e23          	sw	s0,28(sp)
  400e28:	00912c23          	sw	s1,24(sp)
  400e2c:	01212a23          	sw	s2,20(sp)
  400e30:	01312823          	sw	s3,16(sp)
  400e34:	00050293          	mv	t0,a0
  400e38:	02f12a23          	sw	a5,52(sp)
  400e3c:	03012c23          	sw	a6,56(sp)
  400e40:	03112e23          	sw	a7,60(sp)
  400e44:	02b12223          	sw	a1,36(sp)
  400e48:	02c12423          	sw	a2,40(sp)
  400e4c:	02d12623          	sw	a3,44(sp)
  400e50:	02e12823          	sw	a4,48(sp)
  400e54:	02410513          	addi	a0,sp,36
  400e58:	02500593          	li	a1,37
  400e5c:	07200613          	li	a2,114
  400e60:	06400713          	li	a4,100
  400e64:	02d00793          	li	a5,45
  400e68:	ccccd6b7          	lui	a3,0xccccd
  400e6c:	00110813          	addi	a6,sp,1
  400e70:	00900893          	li	a7,9
  400e74:	00100313          	li	t1,1
  400e78:	03000393          	li	t2,48
  400e7c:	07300e13          	li	t3,115
  400e80:	07800e93          	li	t4,120
    va_start(vargs, fmt);
  400e84:	00a12623          	sw	a0,12(sp)
  400e88:	ccd68f13          	addi	t5,a3,-819 # cccccccd <USER_MAX+0xcc7ccccd>
  400e8c:	00402fb7          	lui	t6,0x402
  400e90:	177f8f93          	addi	t6,t6,375 # 402177 <__modsi3+0x30b>
  400e94:	00c0006f          	j	400ea0 <printf+0x80>
            switch (*fmt) {
  400e98:	20050c63          	beqz	a0,4010b0 <printf+0x290>
        fmt++;
  400e9c:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400ea0:	0002c403          	lbu	s0,0(t0)
  400ea4:	00b40e63          	beq	s0,a1,400ec0 <printf+0xa0>
  400ea8:	20040c63          	beqz	s0,4010c0 <printf+0x2a0>
    __asm__ __volatile__ (
  400eac:	00040513          	mv	a0,s0
  400eb0:	00100693          	li	a3,1
  400eb4:	00000073          	ecall
        fmt++;
  400eb8:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400ebc:	fe5ff06f          	j	400ea0 <printf+0x80>
            switch (*fmt) {
  400ec0:	0012c503          	lbu	a0,1(t0)
            fmt++;
  400ec4:	00128293          	addi	t0,t0,1
            switch (*fmt) {
  400ec8:	02a64c63          	blt	a2,a0,400f00 <printf+0xe0>
  400ecc:	12b50663          	beq	a0,a1,400ff8 <printf+0x1d8>
  400ed0:	fce514e3          	bne	a0,a4,400e98 <printf+0x78>
                    int value = va_arg(vargs, int);
  400ed4:	00c12503          	lw	a0,12(sp)
  400ed8:	00450693          	addi	a3,a0,4
  400edc:	00d12623          	sw	a3,12(sp)
  400ee0:	00052483          	lw	s1,0(a0)
                    if (value < 0) {
  400ee4:	1604c063          	bltz	s1,401044 <printf+0x224>
                    if (u == 0) {
  400ee8:	16049663          	bnez	s1,401054 <printf+0x234>
    __asm__ __volatile__ (
  400eec:	00038513          	mv	a0,t2
  400ef0:	00100693          	li	a3,1
  400ef4:	00000073          	ecall
        fmt++;
  400ef8:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400efc:	fa5ff06f          	j	400ea0 <printf+0x80>
            switch (*fmt) {
  400f00:	11c50663          	beq	a0,t3,40100c <printf+0x1ec>
  400f04:	f9d51ce3          	bne	a0,t4,400e9c <printf+0x7c>
                    unsigned value = va_arg(vargs, unsigned);
  400f08:	00c12503          	lw	a0,12(sp)
  400f0c:	00450693          	addi	a3,a0,4
  400f10:	00d12623          	sw	a3,12(sp)
  400f14:	00052403          	lw	s0,0(a0)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400f18:	01c45513          	srli	a0,s0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400f1c:	00af8533          	add	a0,t6,a0
  400f20:	00054483          	lbu	s1,0(a0)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400f24:	00441513          	slli	a0,s0,0x4
  400f28:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400f2c:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400f30:	00048513          	mv	a0,s1
  400f34:	00100693          	li	a3,1
  400f38:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400f3c:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400f40:	00841513          	slli	a0,s0,0x8
  400f44:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400f48:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400f4c:	00048513          	mv	a0,s1
  400f50:	00100693          	li	a3,1
  400f54:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400f58:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400f5c:	00c41513          	slli	a0,s0,0xc
  400f60:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400f64:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400f68:	00048513          	mv	a0,s1
  400f6c:	00100693          	li	a3,1
  400f70:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400f74:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400f78:	01041513          	slli	a0,s0,0x10
  400f7c:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400f80:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400f84:	00048513          	mv	a0,s1
  400f88:	00100693          	li	a3,1
  400f8c:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400f90:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400f94:	01441513          	slli	a0,s0,0x14
  400f98:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400f9c:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400fa0:	00048513          	mv	a0,s1
  400fa4:	00100693          	li	a3,1
  400fa8:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400fac:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400fb0:	01841513          	slli	a0,s0,0x18
  400fb4:	01c55513          	srli	a0,a0,0x1c
                        putchar("0123456789abcdef"[nibble]);
  400fb8:	00af8933          	add	s2,t6,a0
    __asm__ __volatile__ (
  400fbc:	00048513          	mv	a0,s1
  400fc0:	00100693          	li	a3,1
  400fc4:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400fc8:	00094483          	lbu	s1,0(s2)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  400fcc:	00f47413          	andi	s0,s0,15
                        putchar("0123456789abcdef"[nibble]);
  400fd0:	008f8433          	add	s0,t6,s0
    __asm__ __volatile__ (
  400fd4:	00048513          	mv	a0,s1
  400fd8:	00100693          	li	a3,1
  400fdc:	00000073          	ecall
                        putchar("0123456789abcdef"[nibble]);
  400fe0:	00044403          	lbu	s0,0(s0)
    __asm__ __volatile__ (
  400fe4:	00040513          	mv	a0,s0
  400fe8:	00100693          	li	a3,1
  400fec:	00000073          	ecall
        fmt++;
  400ff0:	00128293          	addi	t0,t0,1
    while (*fmt) {
  400ff4:	eadff06f          	j	400ea0 <printf+0x80>
    __asm__ __volatile__ (
  400ff8:	00058513          	mv	a0,a1
  400ffc:	00100693          	li	a3,1
  401000:	00000073          	ecall
        fmt++;
  401004:	00128293          	addi	t0,t0,1
    while (*fmt) {
  401008:	e99ff06f          	j	400ea0 <printf+0x80>
                    const char *s = va_arg(vargs, const char *);
  40100c:	00c12503          	lw	a0,12(sp)
  401010:	00450693          	addi	a3,a0,4
  401014:	00d12623          	sw	a3,12(sp)
  401018:	00052483          	lw	s1,0(a0)
                    while (*s) {
  40101c:	0004c403          	lbu	s0,0(s1)
  401020:	e6040ee3          	beqz	s0,400e9c <printf+0x7c>
  401024:	00148493          	addi	s1,s1,1
    __asm__ __volatile__ (
  401028:	00040513          	mv	a0,s0
  40102c:	00100693          	li	a3,1
  401030:	00000073          	ecall
                    while (*s) {
  401034:	0004c403          	lbu	s0,0(s1)
  401038:	00148493          	addi	s1,s1,1
  40103c:	fe0416e3          	bnez	s0,401028 <printf+0x208>
  401040:	e5dff06f          	j	400e9c <printf+0x7c>
    __asm__ __volatile__ (
  401044:	00078513          	mv	a0,a5
  401048:	00100693          	li	a3,1
  40104c:	00000073          	ecall
                        u = (unsigned int)(-(value + 1)) + 1;
  401050:	409004b3          	neg	s1,s1
  401054:	00000513          	li	a0,0
  401058:	00048693          	mv	a3,s1
  40105c:	00050413          	mv	s0,a0
                        u /= 10;
  401060:	03e4b933          	mulhu	s2,s1,t5
                        buf[i++] = '0' + (u % 10);
  401064:	00150513          	addi	a0,a0,1
                        u /= 10;
  401068:	00395493          	srli	s1,s2,0x3
                        buf[i++] = '0' + (u % 10);
  40106c:	0f897913          	andi	s2,s2,248
  401070:	00149993          	slli	s3,s1,0x1
  401074:	41268933          	sub	s2,a3,s2
  401078:	41390933          	sub	s2,s2,s3
  40107c:	03096913          	ori	s2,s2,48
  401080:	008809b3          	add	s3,a6,s0
  401084:	01298023          	sb	s2,0(s3)
                    while (u > 0) {
  401088:	fcd8e8e3          	bltu	a7,a3,401058 <printf+0x238>
                        putchar(buf[--i]);
  40108c:	00880533          	add	a0,a6,s0
  401090:	00054483          	lbu	s1,0(a0)
    __asm__ __volatile__ (
  401094:	00048513          	mv	a0,s1
  401098:	00100693          	li	a3,1
  40109c:	00000073          	ecall
                    while (i > 0) {
  4010a0:	00140513          	addi	a0,s0,1
  4010a4:	fff40413          	addi	s0,s0,-1
  4010a8:	fea342e3          	blt	t1,a0,40108c <printf+0x26c>
  4010ac:	df1ff06f          	j	400e9c <printf+0x7c>
  4010b0:	02500593          	li	a1,37
    __asm__ __volatile__ (
  4010b4:	00058513          	mv	a0,a1
  4010b8:	00100693          	li	a3,1
  4010bc:	00000073          	ecall
}
  4010c0:	01c12403          	lw	s0,28(sp)
  4010c4:	01812483          	lw	s1,24(sp)
  4010c8:	01412903          	lw	s2,20(sp)
  4010cc:	01012983          	lw	s3,16(sp)
  4010d0:	04010113          	addi	sp,sp,64
  4010d4:	00008067          	ret

004010d8 <call_mic_write_api>:
    __asm__ __volatile__(
  4010d8:	01500693          	li	a3,21
  4010dc:	00000073          	ecall
}
  4010e0:	00008067          	ret

004010e4 <call_sd_read_api>:
    __asm__ __volatile__(
  4010e4:	01e00693          	li	a3,30
  4010e8:	00000073          	ecall
}
  4010ec:	00008067          	ret

004010f0 <call_sd_write_test_api>:
    __asm__ __volatile__(
  4010f0:	01f00693          	li	a3,31
  4010f4:	00000073          	ecall
}
  4010f8:	00008067          	ret

004010fc <call_sd_write_buf_api>:
    __asm__ __volatile__(
  4010fc:	02000693          	li	a3,32
  401100:	00000073          	ecall
    return sd_api2(
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
  4012f4:	18850513          	addi	a0,a0,392 # 402188 <__modsi3+0x31c>
  4012f8:	00000097          	auipc	ra,0x0
  4012fc:	b28080e7          	jalr	-1240(ra) # 400e20 <printf>
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
  401310:	1bc58593          	addi	a1,a1,444 # 4021bc <g_fat32>
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
  40136c:	9d8080e7          	jalr	-1576(ra) # 400d40 <putchar>
    for (uint32_t i = 0; i < size; i++) {
  401370:	00140413          	addi	s0,s0,1
  401374:	fe9418e3          	bne	s0,s1,401364 <fat32_cat+0xb4>
    putchar('\n');
  401378:	00a00513          	li	a0,10
  40137c:	00000097          	auipc	ra,0x0
  401380:	9c4080e7          	jalr	-1596(ra) # 400d40 <putchar>
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
  4013b4:	1d058593          	addi	a1,a1,464 # 4021d0 <fat32_buf>
  4013b8:	00000513          	li	a0,0
  4013bc:	00000097          	auipc	ra,0x0
  4013c0:	edc080e7          	jalr	-292(ra) # 401298 <call_sd_read_buf_api>
  4013c4:	fff00413          	li	s0,-1
  4013c8:	06051a63          	bnez	a0,40143c <fat32_mount+0xa0>
        return -1;

    g_fat32.part_lba =
        ((uint32_t)buf[0x1C6]) |
  4013cc:	00402937          	lui	s2,0x402
  4013d0:	1bc90493          	addi	s1,s2,444 # 4021bc <g_fat32>
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
  4013f4:	1aa92e23          	sw	a0,444(s2)

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
  401408:	1bc92503          	lw	a0,444(s2)
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
  4014ac:	1bca0a13          	addi	s4,s4,444 # 4021bc <g_fat32>
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
  4016fc:	1bc58593          	addi	a1,a1,444 # 4021bc <g_fat32>
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
  401754:	1bc90913          	addi	s2,s2,444 # 4021bc <g_fat32>
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
  4017c8:	19840413          	addi	s0,s0,408 # 402198 <__modsi3+0x32c>
  4017cc:	00200c13          	li	s8,2
  4017d0:	004024b7          	lui	s1,0x402
  4017d4:	16048493          	addi	s1,s1,352 # 402160 <__modsi3+0x2f4>
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
  401820:	604080e7          	jalr	1540(ra) # 400e20 <printf>
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
  401890:	4b4080e7          	jalr	1204(ra) # 400d40 <putchar>
            if (e[j] != ' ')
  401894:	ffc9c503          	lbu	a0,-4(s3)
  401898:	fb750ce3          	beq	a0,s7,401850 <fat32_ls+0x138>
                putchar(e[j]);
  40189c:	fffff097          	auipc	ra,0xfffff
  4018a0:	4a4080e7          	jalr	1188(ra) # 400d40 <putchar>
            if (e[j] != ' ')
  4018a4:	ffd9c503          	lbu	a0,-3(s3)
  4018a8:	fb7508e3          	beq	a0,s7,401858 <fat32_ls+0x140>
                putchar(e[j]);
  4018ac:	fffff097          	auipc	ra,0xfffff
  4018b0:	494080e7          	jalr	1172(ra) # 400d40 <putchar>
            if (e[j] != ' ')
  4018b4:	ffe9c503          	lbu	a0,-2(s3)
  4018b8:	fb7504e3          	beq	a0,s7,401860 <fat32_ls+0x148>
                putchar(e[j]);
  4018bc:	fffff097          	auipc	ra,0xfffff
  4018c0:	484080e7          	jalr	1156(ra) # 400d40 <putchar>
            if (e[j] != ' ')
  4018c4:	fff9c503          	lbu	a0,-1(s3)
  4018c8:	fb7500e3          	beq	a0,s7,401868 <fat32_ls+0x150>
                putchar(e[j]);
  4018cc:	fffff097          	auipc	ra,0xfffff
  4018d0:	474080e7          	jalr	1140(ra) # 400d40 <putchar>
            if (e[j] != ' ')
  4018d4:	0009c503          	lbu	a0,0(s3)
  4018d8:	f9750ce3          	beq	a0,s7,401870 <fat32_ls+0x158>
                putchar(e[j]);
  4018dc:	fffff097          	auipc	ra,0xfffff
  4018e0:	464080e7          	jalr	1124(ra) # 400d40 <putchar>
            if (e[j] != ' ')
  4018e4:	0019c503          	lbu	a0,1(s3)
  4018e8:	f97508e3          	beq	a0,s7,401878 <fat32_ls+0x160>
                putchar(e[j]);
  4018ec:	fffff097          	auipc	ra,0xfffff
  4018f0:	454080e7          	jalr	1108(ra) # 400d40 <putchar>
            if (e[j] != ' ')
  4018f4:	0029c503          	lbu	a0,2(s3)
  4018f8:	f97504e3          	beq	a0,s7,401880 <fat32_ls+0x168>
                putchar(e[j]);
  4018fc:	fffff097          	auipc	ra,0xfffff
  401900:	444080e7          	jalr	1092(ra) # 400d40 <putchar>
        if (e[8] != ' ') {
  401904:	0039c503          	lbu	a0,3(s3)
  401908:	03750863          	beq	a0,s7,401938 <fat32_ls+0x220>
            putchar('.');
  40190c:	02e00513          	li	a0,46
  401910:	fffff097          	auipc	ra,0xfffff
  401914:	430080e7          	jalr	1072(ra) # 400d40 <putchar>
                if (e[j] != ' ')
  401918:	0039c503          	lbu	a0,3(s3)
  40191c:	07751063          	bne	a0,s7,40197c <fat32_ls+0x264>
  401920:	0049c503          	lbu	a0,4(s3)
  401924:	07751463          	bne	a0,s7,40198c <fat32_ls+0x274>
  401928:	0059c503          	lbu	a0,5(s3)
  40192c:	01750663          	beq	a0,s7,401938 <fat32_ls+0x220>
                    putchar(e[j]);
  401930:	fffff097          	auipc	ra,0xfffff
  401934:	410080e7          	jalr	1040(ra) # 400d40 <putchar>
        printf(" attr=%x", (uint32_t)e[11]);
  401938:	0069c583          	lbu	a1,6(s3)
  40193c:	00040513          	mv	a0,s0
  401940:	fffff097          	auipc	ra,0xfffff
  401944:	4e0080e7          	jalr	1248(ra) # 400e20 <printf>
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
  401980:	3c4080e7          	jalr	964(ra) # 400d40 <putchar>
                if (e[j] != ' ')
  401984:	0049c503          	lbu	a0,4(s3)
  401988:	fb7500e3          	beq	a0,s7,401928 <fat32_ls+0x210>
                    putchar(e[j]);
  40198c:	fffff097          	auipc	ra,0xfffff
  401990:	3b4080e7          	jalr	948(ra) # 400d40 <putchar>
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
  4019d4:	1bca0a13          	addi	s4,s4,444 # 4021bc <g_fat32>
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
  401cdc:	1a150513          	addi	a0,a0,417 # 4021a1 <__modsi3+0x335>
  401ce0:	fffff097          	auipc	ra,0xfffff
  401ce4:	140080e7          	jalr	320(ra) # 400e20 <printf>
        for (int i = 0; i < 16; i++) {
            printf("%x ", (uint32_t)buf[i]);
        }
        */

        printf("\n");
  401ce8:	00402537          	lui	a0,0x402
  401cec:	f1950513          	addi	a0,a0,-231 # 401f19 <__modsi3+0xad>
  401cf0:	fffff097          	auipc	ra,0xfffff
  401cf4:	130080e7          	jalr	304(ra) # 400e20 <printf>

        if (call_sd_write_buf_api(root_lba, buf))
  401cf8:	00048513          	mv	a0,s1
  401cfc:	00090593          	mv	a1,s2
  401d00:	fffff097          	auipc	ra,0xfffff
  401d04:	3fc080e7          	jalr	1020(ra) # 4010fc <call_sd_write_buf_api>
  401d08:	00050663          	beqz	a0,401d14 <fat32_touch+0x374>
  401d0c:	fff00993          	li	s3,-1
  401d10:	01c0006f          	j	401d2c <fat32_touch+0x38c>
            return -1;

        printf("created: %s\n", name);
  401d14:	00402537          	lui	a0,0x402
  401d18:	1ac50513          	addi	a0,a0,428 # 4021ac <__modsi3+0x340>
  401d1c:	00040593          	mv	a1,s0
  401d20:	fffff097          	auipc	ra,0xfffff
  401d24:	100080e7          	jalr	256(ra) # 400e20 <printf>
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
  401f00:	6548006f          	j	482554 <__user_stack_top+0x5f184>
  401f04:	6c6c                	.insn	2, 0x6c6c
  401f06:	6f77206f          	j	474dfc <__user_stack_top+0x51a2c>
  401f0a:	6c72                	.insn	2, 0x6c72
  401f0c:	2064                	.insn	2, 0x2064
  401f0e:	7266                	.insn	2, 0x7266
  401f10:	73206d6f          	jal	s10,408642 <__user_stack_start+0x5272>
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
  401f2c:	6c206f6f          	jal	t5,4085ee <__user_stack_start+0x521e>
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
  401f80:	746e756f          	jal	a0,4e96c6 <__user_stack_top+0xc62f6>
  401f84:	0a3e                	.insn	2, 0x0a3e
  401f86:	6d00                	.insn	2, 0x6d00
  401f88:	6369                	.insn	2, 0x6369
  401f8a:	775f 6972 6574      	.insn	6, 0x65746972775f
  401f90:	7500                	.insn	2, 0x7500
  401f92:	65676173          	csrrsi	sp,hviprio1h,14
  401f96:	203a                	.insn	2, 0x203a
  401f98:	696d                	.insn	2, 0x696d
  401f9a:	72775f63          	bge	a4,t2,4026d8 <__user_stack_bottom+0x308>
  401f9e:	7469                	.insn	2, 0x7469
  401fa0:	2065                	.insn	2, 0x2065
  401fa2:	633c                	.insn	2, 0x633c
  401fa4:	746e756f          	jal	a0,4e96ea <__user_stack_top+0xc631a>
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
  401fea:	0a3e726f          	jal	tp,4e988c <__user_stack_top+0xc64bc>
  401fee:	7300                	.insn	2, 0x7300
  401ff0:	5f64                	.insn	2, 0x5f64
  401ff2:	74636573          	csrrsi	a0,0x746,6
  401ff6:	7720726f          	jal	tp,409768 <__user_stack_start+0x6398>
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
  402020:	746e756f          	jal	a0,4e9766 <__user_stack_top+0xc6396>
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
  40203c:	635f746f          	jal	s0,4f9e70 <__user_stack_top+0xd6aa0>
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
  402090:	20746163          	bltu	s0,t2,402292 <fat32_buf+0xc2>
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
  4020b6:	6863756f          	jal	a0,43973c <__user_stack_top+0x1636c>
  4020ba:	3c20                	.insn	2, 0x3c20
  4020bc:	6966                	.insn	2, 0x6966
  4020be:	656c                	.insn	2, 0x656c
  4020c0:	0a3e                	.insn	2, 0x0a3e
  4020c2:	6600                	.insn	2, 0x6600
  4020c4:	7461                	.insn	2, 0x7461
  4020c6:	745f3233          	.insn	4, 0x745f3233
  4020ca:	6863756f          	jal	a0,439750 <__user_stack_top+0x16380>
  4020ce:	6620                	.insn	2, 0x6620
  4020d0:	6961                	.insn	2, 0x6961
  4020d2:	656c                	.insn	2, 0x656c
  4020d4:	0a64                	.insn	2, 0x0a64
  4020d6:	6800                	.insn	2, 0x6800
  4020d8:	6c65                	.insn	2, 0x6c65
  4020da:	0070                	.insn	2, 0x0070
  4020dc:	6d6d6f63          	bltu	s10,s6,4027ba <__user_stack_bottom+0x3ea>
  4020e0:	6e61                	.insn	2, 0x6e61
  4020e2:	7364                	.insn	2, 0x7364
  4020e4:	0a3a                	.insn	2, 0x0a3a
  4020e6:	6500                	.insn	2, 0x6500
  4020e8:	6978                	.insn	2, 0x6978
  4020ea:	0074                	.insn	2, 0x0074
  4020ec:	7571                	.insn	2, 0x7571
  4020ee:	7469                	.insn	2, 0x7469
  4020f0:	7100                	.insn	2, 0x7100
  4020f2:	7500                	.insn	2, 0x7500
  4020f4:	6b6e                	.insn	2, 0x6b6e
  4020f6:	6f6e                	.insn	2, 0x6f6e
  4020f8:	63206e77          	.insn	4, 0x63206e77
  4020fc:	616d6d6f          	jal	s10,4d8712 <__user_stack_top+0xb5342>
  402100:	646e                	.insn	2, 0x646e
  402102:	203a                	.insn	2, 0x203a
  402104:	7325                	.insn	2, 0x7325
  402106:	000a                	.insn	2, 0x000a
  402108:	6425                	.insn	2, 0x6425
  40210a:	0020                	.insn	2, 0x0020
  40210c:	6f74                	.insn	2, 0x6f74
  40210e:	6174                	.insn	2, 0x6174
  402110:	206c                	.insn	2, 0x206c
  402112:	7270                	.insn	2, 0x7270
  402114:	6d69                	.insn	2, 0x6d69
  402116:	7365                	.insn	2, 0x7365
  402118:	203a                	.insn	2, 0x203a
  40211a:	6425                	.insn	2, 0x6425
  40211c:	2820                	.insn	2, 0x2820
  40211e:	2e30                	.insn	2, 0x2e30
  402120:	252e                	.insn	2, 0x252e
  402122:	2964                	.insn	2, 0x2964
  402124:	000a                	.insn	2, 0x000a
  402126:	494d                	.insn	2, 0x494d
  402128:	58542e43          	.insn	4, 0x58542e43
  40212c:	0054                	.insn	2, 0x0054
  40212e:	494d                	.insn	2, 0x494d
  402130:	58542e43          	.insn	4, 0x58542e43
  402134:	2054                	.insn	2, 0x2054
  402136:	6f6e                	.insn	2, 0x6f6e
  402138:	2074                	.insn	2, 0x2074
  40213a:	6f66                	.insn	2, 0x6f66
  40213c:	6e75                	.insn	2, 0x6e75
  40213e:	0a64                	.insn	2, 0x0a64
  402140:	4d00                	.insn	2, 0x4d00
  402142:	4349                	.insn	2, 0x4349
  402144:	542e                	.insn	2, 0x542e
  402146:	5458                	.insn	2, 0x5458
  402148:	6820                	.insn	2, 0x6820
  40214a:	7361                	.insn	2, 0x7361
  40214c:	6e20                	.insn	2, 0x6e20
  40214e:	6c63206f          	j	434814 <__user_stack_top+0x11444>
  402152:	7375                	.insn	2, 0x7375
  402154:	6574                	.insn	2, 0x6574
  402156:	0a72                	.insn	2, 0x0a72
  402158:	4d00                	.insn	2, 0x4d00
  40215a:	4349                	.insn	2, 0x4349
  40215c:	542e                	.insn	2, 0x542e
  40215e:	5458                	.insn	2, 0x5458
  402160:	6320                	.insn	2, 0x6320
  402162:	3d6c                	.insn	2, 0x3d6c
  402164:	7825                	.insn	2, 0x7825
  402166:	6c20                	.insn	2, 0x6c20
  402168:	6162                	.insn	2, 0x6162
  40216a:	253d                	.insn	2, 0x253d
  40216c:	2078                	.insn	2, 0x2078
  40216e:	657a6973          	csrrsi	s2,hviprio2h,20
  402172:	253d                	.insn	2, 0x253d
  402174:	0a78                	.insn	2, 0x0a78
  402176:	3000                	.insn	2, 0x3000
  402178:	3231                	.insn	2, 0x3231
  40217a:	36353433          	.insn	4, 0x36353433
  40217e:	61393837          	lui	a6,0x61393
  402182:	6362                	.insn	2, 0x6362
  402184:	6564                	.insn	2, 0x6564
  402186:	0066                	.insn	2, 0x0066
  402188:	6966                	.insn	2, 0x6966
  40218a:	656c                	.insn	2, 0x656c
  40218c:	6e20                	.insn	2, 0x6e20
  40218e:	6620746f          	jal	s0,4097f0 <__user_stack_start+0x6420>
  402192:	646e756f          	jal	a0,4e97d8 <__user_stack_top+0xc6408>
  402196:	000a                	.insn	2, 0x000a
  402198:	6120                	.insn	2, 0x6120
  40219a:	7474                	.insn	2, 0x7474
  40219c:	3d72                	.insn	2, 0x3d72
  40219e:	7825                	.insn	2, 0x7825
  4021a0:	5500                	.insn	2, 0x5500
  4021a2:	20524553          	.insn	4, 0x20524553
  4021a6:	5542                	.insn	2, 0x5542
  4021a8:	3a46                	.insn	2, 0x3a46
  4021aa:	0020                	.insn	2, 0x0020
  4021ac:	61657263          	bgeu	a0,s6,4027b0 <__user_stack_bottom+0x3e0>
  4021b0:	6574                	.insn	2, 0x6574
  4021b2:	3a64                	.insn	2, 0x3a64
  4021b4:	2520                	.insn	2, 0x2520
  4021b6:	000a73 	.3byte	0x000a73

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
  84:	4804                	.insn	2, 0x4804
  86:	0188                	.insn	2, 0x0188
  88:	3002                	.insn	2, 0x3002
  8a:	049f 0188 019c      	.insn	6, 0x019c0188049f
  90:	6201                	.insn	2, 0x6201
  92:	f804                	.insn	2, 0xf804
  94:	8402                	.insn	2, 0x8402
  96:	04620103          	lb	sp,70(tp) # 46 <start-0x3fffba>
  9a:	0384                	.insn	2, 0x0384
  9c:	03cc                	.insn	2, 0x03cc
  9e:	6b01                	.insn	2, 0x6b01
  a0:	cc04                	.insn	2, 0xcc04
  a2:	0110e403          	.insn	4, 0x0110e403
  a6:	0062                	.insn	2, 0x0062
  a8:	8804                	.insn	2, 0x8804
  aa:	9c01                	.insn	2, 0x9c01
  ac:	0101                	.insn	2, 0x0101
  ae:	0465                	.insn	2, 0x0465
  b0:	0594                	.insn	2, 0x0594
  b2:	0598                	.insn	2, 0x0598
  b4:	6401                	.insn	2, 0x6401
  b6:	9804                	.insn	2, 0x9804
  b8:	b805                	.insn	2, 0xb805
  ba:	0106                	.insn	2, 0x0106
  bc:	0465                	.insn	2, 0x0465
  be:	09a4                	.insn	2, 0x09a4
  c0:	09f4                	.insn	2, 0x09f4
  c2:	6501                	.insn	2, 0x6501
  c4:	9c04                	.insn	2, 0x9c04
  c6:	a40a                	.insn	2, 0xa40a
  c8:	010a                	.insn	2, 0x010a
  ca:	0465                	.insn	2, 0x0465
  cc:	0ab0                	.insn	2, 0x0ab0
  ce:	0ac8                	.insn	2, 0x0ac8
  d0:	6501                	.insn	2, 0x6501
  d2:	d404                	.insn	2, 0xd404
  d4:	880a                	.insn	2, 0x880a
  d6:	0465010b          	.insn	4, 0x0465010b
  da:	0bd4                	.insn	2, 0x0bd4
  dc:	0bdc                	.insn	2, 0x0bdc
  de:	6501                	.insn	2, 0x6501
  e0:	9004                	.insn	2, 0x9004
  e2:	e80c                	.insn	2, 0xe80c
  e4:	010c                	.insn	2, 0x010c
  e6:	0065                	.insn	2, 0x0065
  e8:	e004                	.insn	2, 0xe004
  ea:	e402                	.insn	2, 0xe402
  ec:	0302                	.insn	2, 0x0302
  ee:	0011                	.insn	2, 0x0011
  f0:	049f 02f8 058c      	.insn	6, 0x058c02f8049f
  f6:	6401                	.insn	2, 0x6401
  f8:	0400                	.insn	2, 0x0400
  fa:	02f8                	.insn	2, 0x02f8
  fc:	0384                	.insn	2, 0x0384
  fe:	5a01                	.insn	2, 0x5a01
 100:	d404                	.insn	2, 0xd404
 102:	0104ac03          	lw	s8,16(s1)
 106:	045a                	.insn	2, 0x045a
 108:	04c8                	.insn	2, 0x04c8
 10a:	04cc                	.insn	2, 0x04cc
 10c:	5a01                	.insn	2, 0x5a01
 10e:	0400                	.insn	2, 0x0400
 110:	02f8                	.insn	2, 0x02f8
 112:	0384                	.insn	2, 0x0384
 114:	6201                	.insn	2, 0x6201
 116:	9404                	.insn	2, 0x9404
 118:	0104e403          	.insn	4, 0x0104e403
 11c:	0062                	.insn	2, 0x0062
 11e:	bc04                	.insn	2, 0xbc04
 120:	0d03c403          	lbu	s0,208(t2) # d0 <start-0x3fff30>
 124:	007a                	.insn	2, 0x007a
 126:	aba8                	.insn	2, 0xaba8
 128:	8080                	.insn	2, 0x8080
 12a:	a800                	.insn	2, 0xa800
 12c:	008080af          	.insn	4, 0x008080af
 130:	009f ec04 8c04      	.insn	6, 0x8c04ec04009f
 136:	0105                	.insn	2, 0x0105
 138:	045a                	.insn	2, 0x045a
 13a:	0594                	.insn	2, 0x0594
 13c:	05cc                	.insn	2, 0x05cc
 13e:	5b01                	.insn	2, 0x5b01
 140:	cc04                	.insn	2, 0xcc04
 142:	d405                	.insn	2, 0xd405
 144:	0305                	.insn	2, 0x0305
 146:	009f017b          	.insn	4, 0x009f017b
 14a:	a404                	.insn	2, 0xa404
 14c:	f409                	.insn	2, 0xf409
 14e:	0609                	.insn	2, 0x0609
 150:	8010                	.insn	2, 0x8010
 152:	8080                	.insn	2, 0x8080
 154:	9f01                	.insn	2, 0x9f01
 156:	9c04                	.insn	2, 0x9c04
 158:	bc0a                	.insn	2, 0xbc0a
 15a:	060a                	.insn	2, 0x060a
 15c:	8010                	.insn	2, 0x8010
 15e:	8080                	.insn	2, 0x8080
 160:	9f01                	.insn	2, 0x9f01
 162:	bc04                	.insn	2, 0xbc04
 164:	d00a                	.insn	2, 0xd00a
 166:	010a                	.insn	2, 0x010a
 168:	045a                	.insn	2, 0x045a
 16a:	0ad4                	.insn	2, 0x0ad4
 16c:	0b98                	.insn	2, 0x0b98
 16e:	5a01                	.insn	2, 0x5a01
 170:	d404                	.insn	2, 0xd404
 172:	010be80b          	.insn	4, 0x010be80b
 176:	045a                	.insn	2, 0x045a
 178:	0c98                	.insn	2, 0x0c98
 17a:	0ce0                	.insn	2, 0x0ce0
 17c:	1006                	.insn	2, 0x1006
 17e:	8080                	.insn	2, 0x8080
 180:	0180                	.insn	2, 0x0180
 182:	049f 0dcc 0e94      	.insn	6, 0x0e940dcc049f
 188:	5a01                	.insn	2, 0x5a01
 18a:	0400                	.insn	2, 0x0400
 18c:	09a4                	.insn	2, 0x09a4
 18e:	09f4                	.insn	2, 0x09f4
 190:	1004                	.insn	2, 0x1004
 192:	0280                	.insn	2, 0x0280
 194:	049f 0aa4 0aac      	.insn	6, 0x0aac0aa4049f
 19a:	5b01                	.insn	2, 0x5b01
 19c:	b004                	.insn	2, 0xb004
 19e:	c80a                	.insn	2, 0xc80a
 1a0:	040a                	.insn	2, 0x040a
 1a2:	8010                	.insn	2, 0x8010
 1a4:	9f02                	.insn	2, 0x9f02
 1a6:	c804                	.insn	2, 0xc804
 1a8:	d00a                	.insn	2, 0xd00a
 1aa:	010a                	.insn	2, 0x010a
 1ac:	0ad4045b          	.insn	4, 0x0ad4045b
 1b0:	0b98                	.insn	2, 0x0b98
 1b2:	1004                	.insn	2, 0x1004
 1b4:	0280                	.insn	2, 0x0280
 1b6:	049f 0bd4 0be0      	.insn	6, 0x0be00bd4049f
 1bc:	1004                	.insn	2, 0x1004
 1be:	0280                	.insn	2, 0x0280
 1c0:	049f 0be0 0be8      	.insn	6, 0x0be80be0049f
 1c6:	5b01                	.insn	2, 0x5b01
 1c8:	9804                	.insn	2, 0x9804
 1ca:	e00c                	.insn	2, 0xe00c
 1cc:	040c                	.insn	2, 0x040c
 1ce:	8010                	.insn	2, 0x8010
 1d0:	9f02                	.insn	2, 0x9f02
 1d2:	cc04                	.insn	2, 0xcc04
 1d4:	940d                	.insn	2, 0x940d
 1d6:	040e                	.insn	2, 0x040e
 1d8:	8010                	.insn	2, 0x8010
 1da:	9f02                	.insn	2, 0x9f02
 1dc:	0400                	.insn	2, 0x0400
 1de:	09b0                	.insn	2, 0x09b0
 1e0:	09b4                	.insn	2, 0x09b4
 1e2:	5d01                	.insn	2, 0x5d01
 1e4:	c004                	.insn	2, 0xc004
 1e6:	c409                	.insn	2, 0xc409
 1e8:	0309                	.insn	2, 0x0309
 1ea:	7f7d                	.insn	2, 0x7f7d
 1ec:	049f 09c4 09e8      	.insn	6, 0x09e809c4049f
 1f2:	9f7e7d03          	.insn	4, 0x9f7e7d03
 1f6:	ec04                	.insn	2, 0xec04
 1f8:	f409                	.insn	2, 0xf409
 1fa:	0109                	.insn	2, 0x0109
 1fc:	045d                	.insn	2, 0x045d
 1fe:	0ab4                	.insn	2, 0x0ab4
 200:	0ab8                	.insn	2, 0x0ab8
 202:	5d01                	.insn	2, 0x5d01
 204:	a404                	.insn	2, 0xa404
 206:	bc0c                	.insn	2, 0xbc0c
 208:	010c                	.insn	2, 0x010c
 20a:	045d                	.insn	2, 0x045d
 20c:	0cc0                	.insn	2, 0x0cc0
 20e:	0ce0                	.insn	2, 0x0ce0
 210:	5d01                	.insn	2, 0x5d01
 212:	0400                	.insn	2, 0x0400
 214:	09b0                	.insn	2, 0x09b0
 216:	09f4                	.insn	2, 0x09f4
 218:	3002                	.insn	2, 0x3002
 21a:	049f 0ab0 0ab8      	.insn	6, 0x0ab80ab0049f
 220:	3002                	.insn	2, 0x3002
 222:	049f 0c98 0ca4      	.insn	6, 0x0ca40c98049f
 228:	3002                	.insn	2, 0x3002
 22a:	049f 0ca4 0cb4      	.insn	6, 0x0cb40ca4049f
 230:	5a01                	.insn	2, 0x5a01
 232:	b804                	.insn	2, 0xb804
 234:	e00c                	.insn	2, 0xe00c
 236:	010c                	.insn	2, 0x010c
 238:	005a                	.insn	2, 0x005a
 23a:	f404                	.insn	2, 0xf404
 23c:	8809                	.insn	2, 0x8809
 23e:	040a                	.insn	2, 0x040a
 240:	e810                	.insn	2, 0xe810
 242:	88049f07          	.insn	4, 0x88049f07
 246:	9c0a                	.insn	2, 0x9c0a
 248:	010a                	.insn	2, 0x010a
 24a:	0bc4045b          	.insn	4, 0x0bc4045b
 24e:	0bd0                	.insn	2, 0x0bd0
 250:	5b01                	.insn	2, 0x5b01
 252:	0400                	.insn	2, 0x0400
 254:	0ad8                	.insn	2, 0x0ad8
 256:	0adc                	.insn	2, 0x0adc
 258:	5d01                	.insn	2, 0x5d01
 25a:	e004                	.insn	2, 0xe004
 25c:	e40a                	.insn	2, 0xe40a
 25e:	030a                	.insn	2, 0x030a
 260:	7f7d                	.insn	2, 0x7f7d
 262:	049f 0ae4 0b8c      	.insn	6, 0x0b8c0ae4049f
 268:	9f7e7d03          	.insn	4, 0x9f7e7d03
 26c:	9004                	.insn	2, 0x9004
 26e:	010b980b          	.insn	4, 0x010b980b
 272:	045d                	.insn	2, 0x045d
 274:	0bdc                	.insn	2, 0x0bdc
 276:	0be0                	.insn	2, 0x0be0
 278:	5d01                	.insn	2, 0x5d01
 27a:	d804                	.insn	2, 0xd804
 27c:	f00d                	.insn	2, 0xf00d
 27e:	010d                	.insn	2, 0x010d
 280:	045d                	.insn	2, 0x045d
 282:	0df4                	.insn	2, 0x0df4
 284:	0e94                	.insn	2, 0x0e94
 286:	5d01                	.insn	2, 0x5d01
 288:	0400                	.insn	2, 0x0400
 28a:	0ad8                	.insn	2, 0x0ad8
 28c:	0b98                	.insn	2, 0x0b98
 28e:	3002                	.insn	2, 0x3002
 290:	049f 0bd4 0be0      	.insn	6, 0x0be00bd4049f
 296:	3002                	.insn	2, 0x3002
 298:	049f 0dcc 0dd8      	.insn	6, 0x0dd80dcc049f
 29e:	3002                	.insn	2, 0x3002
 2a0:	049f 0dd8 0de8      	.insn	6, 0x0de80dd8049f
 2a6:	5b01                	.insn	2, 0x5b01
 2a8:	ec04                	.insn	2, 0xec04
 2aa:	940d                	.insn	2, 0x940d
 2ac:	010e                	.insn	2, 0x010e
 2ae:	9804005b          	.insn	4, 0x9804005b
 2b2:	020bac0b          	.insn	4, 0x020bac0b
 2b6:	9f34                	.insn	2, 0x9f34
 2b8:	ac04                	.insn	2, 0xac04
 2ba:	010bc00b          	.insn	4, 0x010bc00b
 2be:	0d90045b          	.insn	4, 0x0d90045b
 2c2:	0d9c                	.insn	2, 0x0d9c
 2c4:	5b01                	.insn	2, 0x5b01
 2c6:	0400                	.insn	2, 0x0400
 2c8:	0c84                	.insn	2, 0x0c84
 2ca:	0c8c                	.insn	2, 0x0c8c
 2cc:	5a01                	.insn	2, 0x5a01
 2ce:	0400                	.insn	2, 0x0400
 2d0:	0ca4                	.insn	2, 0x0ca4
 2d2:	0cb0                	.insn	2, 0x0cb0
 2d4:	5c01                	.insn	2, 0x5c01
 2d6:	c004                	.insn	2, 0xc004
 2d8:	e00c                	.insn	2, 0xe00c
 2da:	010c                	.insn	2, 0x010c
 2dc:	005c                	.insn	2, 0x005c
 2de:	ac04                	.insn	2, 0xac04
 2e0:	c00c                	.insn	2, 0xc00c
 2e2:	010c                	.insn	2, 0x010c
 2e4:	005e                	.insn	2, 0x005e
 2e6:	8004                	.insn	2, 0x8004
 2e8:	880d                	.insn	2, 0x880d
 2ea:	010d                	.insn	2, 0x010d
 2ec:	005a                	.insn	2, 0x005a
 2ee:	b804                	.insn	2, 0xb804
 2f0:	c00d                	.insn	2, 0xc00d
 2f2:	010d                	.insn	2, 0x010d
 2f4:	005a                	.insn	2, 0x005a
 2f6:	d804                	.insn	2, 0xd804
 2f8:	e40d                	.insn	2, 0xe40d
 2fa:	010d                	.insn	2, 0x010d
 2fc:	045c                	.insn	2, 0x045c
 2fe:	0df4                	.insn	2, 0x0df4
 300:	0e94                	.insn	2, 0x0e94
 302:	5c01                	.insn	2, 0x5c01
 304:	0400                	.insn	2, 0x0400
 306:	0de0                	.insn	2, 0x0de0
 308:	0df4                	.insn	2, 0x0df4
 30a:	5e01                	.insn	2, 0x5e01
 30c:	0400                	.insn	2, 0x0400
 30e:	0eb8                	.insn	2, 0x0eb8
 310:	0ed8                	.insn	2, 0x0ed8
 312:	5b01                	.insn	2, 0x5b01
 314:	0400                	.insn	2, 0x0400
 316:	10e4                	.insn	2, 0x10e4
 318:	10f4                	.insn	2, 0x10f4
 31a:	5a01                	.insn	2, 0x5a01
 31c:	f404                	.insn	2, 0xf404
 31e:	f810                	.insn	2, 0xf810
 320:	0310                	.insn	2, 0x0310
 322:	7f7d                	.insn	2, 0x7f7d
 324:	049f 10f8 119c      	.insn	6, 0x119c10f8049f
 32a:	9f7e7d03          	.insn	4, 0x9f7e7d03
 32e:	a004                	.insn	2, 0xa004
 330:	a811                	.insn	2, 0xa811
 332:	0111                	.insn	2, 0x0111
 334:	045d                	.insn	2, 0x045d
 336:	11a8                	.insn	2, 0x11a8
 338:	11ac                	.insn	2, 0x11ac
 33a:	9f7e7d03          	.insn	4, 0x9f7e7d03
 33e:	ac04                	.insn	2, 0xac04
 340:	b811                	.insn	2, 0xb811
 342:	0111                	.insn	2, 0x0111
 344:	045d                	.insn	2, 0x045d
 346:	11b8                	.insn	2, 0x11b8
 348:	11bc                	.insn	2, 0x11bc
 34a:	9f7e7d03          	.insn	4, 0x9f7e7d03
 34e:	d804                	.insn	2, 0xd804
 350:	f011                	.insn	2, 0xf011
 352:	0111                	.insn	2, 0x0111
 354:	045d                	.insn	2, 0x045d
 356:	11f4                	.insn	2, 0x11f4
 358:	129c                	.insn	2, 0x129c
 35a:	5d01                	.insn	2, 0x5d01
 35c:	0400                	.insn	2, 0x0400
 35e:	10e4                	.insn	2, 0x10e4
 360:	11d8                	.insn	2, 0x11d8
 362:	3002                	.insn	2, 0x3002
 364:	049f 11d8 11e8      	.insn	6, 0x11e811d8049f
 36a:	5c01                	.insn	2, 0x5c01
 36c:	ec04                	.insn	2, 0xec04
 36e:	a811                	.insn	2, 0xa811
 370:	0112                	.insn	2, 0x0112
 372:	005c                	.insn	2, 0x005c
 374:	d804                	.insn	2, 0xd804
 376:	e411                	.insn	2, 0xe411
 378:	0111                	.insn	2, 0x0111
 37a:	045a                	.insn	2, 0x045a
 37c:	11f4                	.insn	2, 0x11f4
 37e:	1294                	.insn	2, 0x1294
 380:	5a01                	.insn	2, 0x5a01
 382:	0400                	.insn	2, 0x0400
 384:	11e0                	.insn	2, 0x11e0
 386:	11f4                	.insn	2, 0x11f4
 388:	6101                	.insn	2, 0x6101
 38a:	0400                	.insn	2, 0x0400
 38c:	12a8                	.insn	2, 0x12a8
 38e:	12c8                	.insn	2, 0x12c8
 390:	5a01                	.insn	2, 0x5a01
 392:	c804                	.insn	2, 0xc804
 394:	cc12                	.insn	2, 0xcc12
 396:	00580113          	addi	sp,a6,5 # 61393005 <USER_MAX+0x60e93005>
 39a:	c804                	.insn	2, 0xc804
 39c:	dc12                	.insn	2, 0xdc12
 39e:	0312                	.insn	2, 0x0312
 3a0:	0011                	.insn	2, 0x0011
 3a2:	049f 12dc 13b4      	.insn	6, 0x13b412dc049f
 3a8:	5901                	.insn	2, 0x5901
 3aa:	0400                	.insn	2, 0x0400
 3ac:	12c8                	.insn	2, 0x12c8
 3ae:	12dc                	.insn	2, 0x12dc
 3b0:	3202                	.insn	2, 0x3202
 3b2:	049f 12dc 13a0      	.insn	6, 0x13a012dc049f
 3b8:	6201                	.insn	2, 0x6201
 3ba:	d300                	.insn	2, 0xd300
 3bc:	0004                	.insn	2, 0x0004
 3be:	0500                	.insn	2, 0x0500
 3c0:	0400                	.insn	2, 0x0400
 3c2:	3400                	.insn	2, 0x3400
 3c4:	0000                	.insn	2, 0x0000
 3c6:	d000                	.insn	2, 0xd000
 3c8:	0000                	.insn	2, 0x0000
 3ca:	d800                	.insn	2, 0xd800
 3cc:	0000                	.insn	2, 0x0000
 3ce:	e600                	.insn	2, 0xe600
 3d0:	0000                	.insn	2, 0x0000
 3d2:	f500                	.insn	2, 0xf500
 3d4:	0000                	.insn	2, 0x0000
 3d6:	fe00                	.insn	2, 0xfe00
 3d8:	0000                	.insn	2, 0x0000
 3da:	0c00                	.insn	2, 0x0c00
 3dc:	0001                	.insn	2, 0x0001
 3de:	1a00                	.insn	2, 0x1a00
 3e0:	0001                	.insn	2, 0x0001
 3e2:	2600                	.insn	2, 0x2600
 3e4:	0001                	.insn	2, 0x0001
 3e6:	3900                	.insn	2, 0x3900
 3e8:	0001                	.insn	2, 0x0001
 3ea:	4a00                	.insn	2, 0x4a00
 3ec:	0001                	.insn	2, 0x0001
 3ee:	5f00                	.insn	2, 0x5f00
 3f0:	0001                	.insn	2, 0x0001
 3f2:	7200                	.insn	2, 0x7200
 3f4:	0001                	.insn	2, 0x0001
 3f6:	7c00                	.insn	2, 0x7c00
 3f8:	0001                	.insn	2, 0x0001
 3fa:	8700                	.insn	2, 0x8700
 3fc:	0001                	.insn	2, 0x0001
 3fe:	9900                	.insn	2, 0x9900
 400:	0001                	.insn	2, 0x0001
 402:	a400                	.insn	2, 0xa400
 404:	0001                	.insn	2, 0x0001
 406:	b700                	.insn	2, 0xb700
 408:	0001                	.insn	2, 0x0001
 40a:	cc00                	.insn	2, 0xcc00
 40c:	0001                	.insn	2, 0x0001
 40e:	df00                	.insn	2, 0xdf00
 410:	0001                	.insn	2, 0x0001
 412:	f100                	.insn	2, 0xf100
 414:	0001                	.insn	2, 0x0001
 416:	fc00                	.insn	2, 0xfc00
 418:	0001                	.insn	2, 0x0001
 41a:	0d00                	.insn	2, 0x0d00
 41c:	0002                	.insn	2, 0x0002
 41e:	1e00                	.insn	2, 0x1e00
 420:	0002                	.insn	2, 0x0002
 422:	2800                	.insn	2, 0x2800
 424:	0002                	.insn	2, 0x0002
 426:	4000                	.insn	2, 0x4000
 428:	0002                	.insn	2, 0x0002
 42a:	4a00                	.insn	2, 0x4a00
 42c:	0002                	.insn	2, 0x0002
 42e:	5b00                	.insn	2, 0x5b00
 430:	0002                	.insn	2, 0x0002
 432:	6c00                	.insn	2, 0x6c00
 434:	0002                	.insn	2, 0x0002
 436:	7d00                	.insn	2, 0x7d00
 438:	0002                	.insn	2, 0x0002
 43a:	9c00                	.insn	2, 0x9c00
 43c:	0002                	.insn	2, 0x0002
 43e:	bf00                	.insn	2, 0xbf00
 440:	0002                	.insn	2, 0x0002
 442:	c900                	.insn	2, 0xc900
 444:	0002                	.insn	2, 0x0002
 446:	1d00                	.insn	2, 0x1d00
 448:	58000003          	lb	zero,1408(zero) # 580 <start-0x3ffa80>
 44c:	72000003          	lb	zero,1824(zero) # 720 <start-0x3ff8e0>
 450:	7c000003          	lb	zero,1984(zero) # 7c0 <start-0x3ff840>
 454:	86000003          	lb	zero,-1952(zero) # fffff860 <USER_MAX+0xffaff860>
 458:	90000003          	lb	zero,-1792(zero) # fffff900 <USER_MAX+0xffaff900>
 45c:	9a000003          	lb	zero,-1632(zero) # fffff9a0 <USER_MAX+0xffaff9a0>
 460:	ab000003          	lb	zero,-1360(zero) # fffffab0 <USER_MAX+0xffaffab0>
 464:	c3000003          	lb	zero,-976(zero) # fffffc30 <USER_MAX+0xffaffc30>
 468:	dd000003          	lb	zero,-560(zero) # fffffdd0 <USER_MAX+0xffaffdd0>
 46c:	f5000003          	lb	zero,-176(zero) # ffffff50 <USER_MAX+0xffafff50>
 470:	26000003          	lb	zero,608(zero) # 260 <start-0x3ffda0>
 474:	0004                	.insn	2, 0x0004
 476:	4700                	.insn	2, 0x4700
 478:	0004                	.insn	2, 0x0004
 47a:	5100                	.insn	2, 0x5100
 47c:	0004                	.insn	2, 0x0004
 47e:	6900                	.insn	2, 0x6900
 480:	0004                	.insn	2, 0x0004
 482:	8100                	.insn	2, 0x8100
 484:	0004                	.insn	2, 0x0004
 486:	a300                	.insn	2, 0xa300
 488:	0004                	.insn	2, 0x0004
 48a:	ad00                	.insn	2, 0xad00
 48c:	0004                	.insn	2, 0x0004
 48e:	b700                	.insn	2, 0xb700
 490:	0004                	.insn	2, 0x0004
 492:	c100                	.insn	2, 0xc100
 494:	0004                	.insn	2, 0x0004
 496:	0300                	.insn	2, 0x0300
 498:	1405                	.insn	2, 0x1405
 49a:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 49e:	0100                	.insn	2, 0x0100
 4a0:	0405                	.insn	2, 0x0405
 4a2:	2818                	.insn	2, 0x2818
 4a4:	5a01                	.insn	2, 0x5a01
 4a6:	2804                	.insn	2, 0x2804
 4a8:	06c0                	.insn	2, 0x06c0
 4aa:	5f01                	.insn	2, 0x5f01
 4ac:	0100                	.insn	2, 0x0100
 4ae:	0405                	.insn	2, 0x0405
 4b0:	5828                	.insn	2, 0x5828
 4b2:	3002                	.insn	2, 0x3002
 4b4:	049f b064 0101      	.insn	6, 0x0101b064049f
 4ba:	0501005b          	.insn	4, 0x0501005b
 4be:	6404                	.insn	2, 0x6404
 4c0:	0274                	.insn	2, 0x0274
 4c2:	9f30                	.insn	2, 0x9f30
 4c4:	0100                	.insn	2, 0x0100
 4c6:	0405                	.insn	2, 0x0405
 4c8:	01d8                	.insn	2, 0x01d8
 4ca:	029c                	.insn	2, 0x029c
 4cc:	7205                	.insn	2, 0x7205
 4ce:	a090                	.insn	2, 0xa090
 4d0:	9f01                	.insn	2, 0x9f01
 4d2:	0100                	.insn	2, 0x0100
 4d4:	0405                	.insn	2, 0x0405
 4d6:	01d8                	.insn	2, 0x01d8
 4d8:	029c                	.insn	2, 0x029c
 4da:	7205                	.insn	2, 0x7205
 4dc:	8090                	.insn	2, 0x8090
 4de:	9f01                	.insn	2, 0x9f01
 4e0:	0100                	.insn	2, 0x0100
 4e2:	0405                	.insn	2, 0x0405
 4e4:	01d8                	.insn	2, 0x01d8
 4e6:	029c                	.insn	2, 0x029c
 4e8:	9f107203          	.insn	4, 0x9f107203
 4ec:	0100                	.insn	2, 0x0100
 4ee:	0405                	.insn	2, 0x0405
 4f0:	01d8                	.insn	2, 0x01d8
 4f2:	029c                	.insn	2, 0x029c
 4f4:	3a02                	.insn	2, 0x3a02
 4f6:	049f 0390 03c4      	.insn	6, 0x03c40390049f
 4fc:	3a02                	.insn	2, 0x3a02
 4fe:	009f 0501 d804      	.insn	6, 0xd8040501009f
 504:	9c01                	.insn	2, 0x9c01
 506:	0102                	.insn	2, 0x0102
 508:	045f 0390 03c4      	.insn	6, 0x03c40390045f
 50e:	5f01                	.insn	2, 0x5f01
 510:	0100                	.insn	2, 0x0100
 512:	0405                	.insn	2, 0x0405
 514:	01f4                	.insn	2, 0x01f4
 516:	029c                	.insn	2, 0x029c
 518:	9f411003          	lh	zero,-1548(sp)
 51c:	ac04                	.insn	2, 0xac04
 51e:	0303c403          	lbu	s0,48(t2)
 522:	4110                	.insn	2, 0x4110
 524:	009f 0501 8004      	.insn	6, 0x80040501009f
 52a:	9c02                	.insn	2, 0x9c02
 52c:	0202                	.insn	2, 0x0202
 52e:	9f3a                	.insn	2, 0x9f3a
 530:	b804                	.insn	2, 0xb804
 532:	0203c403          	lbu	s0,32(t2)
 536:	9f3a                	.insn	2, 0x9f3a
 538:	0100                	.insn	2, 0x0100
 53a:	0405                	.insn	2, 0x0405
 53c:	02a8                	.insn	2, 0x02a8
 53e:	02ec                	.insn	2, 0x02ec
 540:	6001                	.insn	2, 0x6001
 542:	0100                	.insn	2, 0x0100
 544:	0405                	.insn	2, 0x0405
 546:	02a8                	.insn	2, 0x02a8
 548:	02ac                	.insn	2, 0x02ac
 54a:	3002                	.insn	2, 0x3002
 54c:	009f 0501 f004      	.insn	6, 0xf0040501009f
 552:	02049803          	lh	a6,32(s1)
 556:	9f30                	.insn	2, 0x9f30
 558:	a404                	.insn	2, 0xa404
 55a:	e404                	.insn	2, 0xe404
 55c:	0104                	.insn	2, 0x0104
 55e:	0501005b          	.insn	4, 0x0501005b
 562:	a404                	.insn	2, 0xa404
 564:	a804                	.insn	2, 0xa804
 566:	0204                	.insn	2, 0x0204
 568:	9f30                	.insn	2, 0x9f30
 56a:	0100                	.insn	2, 0x0100
 56c:	0405                	.insn	2, 0x0405
 56e:	04f0                	.insn	2, 0x04f0
 570:	05a4                	.insn	2, 0x05a4
 572:	3a02                	.insn	2, 0x3a02
 574:	049f 05fc 06a0      	.insn	6, 0x06a005fc049f
 57a:	3a02                	.insn	2, 0x3a02
 57c:	009f 0501 fc04      	.insn	6, 0xfc040501009f
 582:	a404                	.insn	2, 0xa404
 584:	0305                	.insn	2, 0x0305
 586:	4310                	.insn	2, 0x4310
 588:	049f 0688 06a0      	.insn	6, 0x06a00688049f
 58e:	9f431003          	lh	zero,-1548(t1)
 592:	0100                	.insn	2, 0x0100
 594:	0405                	.insn	2, 0x0405
 596:	0588                	.insn	2, 0x0588
 598:	05a4                	.insn	2, 0x05a4
 59a:	3a02                	.insn	2, 0x3a02
 59c:	049f 0694 06a0      	.insn	6, 0x06a00694049f
 5a2:	3a02                	.insn	2, 0x3a02
 5a4:	009f 0501 9404      	.insn	6, 0x94040501009f
 5aa:	a405                	.insn	2, 0xa405
 5ac:	0205                	.insn	2, 0x0205
 5ae:	9f30                	.insn	2, 0x9f30
 5b0:	b004                	.insn	2, 0xb004
 5b2:	f405                	.insn	2, 0xf405
 5b4:	0105                	.insn	2, 0x0105
 5b6:	0501005b          	.insn	4, 0x0501005b
 5ba:	b004                	.insn	2, 0xb004
 5bc:	b405                	.insn	2, 0xb405
 5be:	0205                	.insn	2, 0x0205
 5c0:	9f30                	.insn	2, 0x9f30
 5c2:	0100                	.insn	2, 0x0100
 5c4:	0405                	.insn	2, 0x0405
 5c6:	06c0                	.insn	2, 0x06c0
 5c8:	06c4                	.insn	2, 0x06c4
 5ca:	5a01                	.insn	2, 0x5a01
 5cc:	c404                	.insn	2, 0xc404
 5ce:	d406                	.insn	2, 0xd406
 5d0:	0106                	.insn	2, 0x0106
 5d2:	0501005b          	.insn	4, 0x0501005b
 5d6:	d404                	.insn	2, 0xd404
 5d8:	d806                	.insn	2, 0xd806
 5da:	0106                	.insn	2, 0x0106
 5dc:	045a                	.insn	2, 0x045a
 5de:	06d8                	.insn	2, 0x06d8
 5e0:	06e8                	.insn	2, 0x06e8
 5e2:	5b01                	.insn	2, 0x5b01
 5e4:	0100                	.insn	2, 0x0100
 5e6:	0405                	.insn	2, 0x0405
 5e8:	06e8                	.insn	2, 0x06e8
 5ea:	06f0                	.insn	2, 0x06f0
 5ec:	5a01                	.insn	2, 0x5a01
 5ee:	0100                	.insn	2, 0x0100
 5f0:	0405                	.insn	2, 0x0405
 5f2:	06f4                	.insn	2, 0x06f4
 5f4:	0788                	.insn	2, 0x0788
 5f6:	5a01                	.insn	2, 0x5a01
 5f8:	8804                	.insn	2, 0x8804
 5fa:	0107d807          	.insn	4, 0x0107d807
 5fe:	0458                	.insn	2, 0x0458
 600:	07e4                	.insn	2, 0x07e4
 602:	08a0                	.insn	2, 0x08a0
 604:	5801                	.insn	2, 0x5801
 606:	0100                	.insn	2, 0x0100
 608:	0405                	.insn	2, 0x0405
 60a:	07f8                	.insn	2, 0x07f8
 60c:	08a0                	.insn	2, 0x08a0
 60e:	5901                	.insn	2, 0x5901
 610:	0100                	.insn	2, 0x0100
 612:	0405                	.insn	2, 0x0405
 614:	088c                	.insn	2, 0x088c
 616:	089c                	.insn	2, 0x089c
 618:	5801                	.insn	2, 0x5801
 61a:	9c04                	.insn	2, 0x9c04
 61c:	a008                	.insn	2, 0xa008
 61e:	0108                	.insn	2, 0x0108
 620:	005a                	.insn	2, 0x005a
 622:	0501                	.insn	2, 0x0501
 624:	a004                	.insn	2, 0xa004
 626:	b808                	.insn	2, 0xb808
 628:	0108                	.insn	2, 0x0108
 62a:	045a                	.insn	2, 0x045a
 62c:	08b8                	.insn	2, 0x08b8
 62e:	0dd8                	.insn	2, 0x0dd8
 630:	5501                	.insn	2, 0x5501
 632:	0100                	.insn	2, 0x0100
 634:	0405                	.insn	2, 0x0405
 636:	09e4                	.insn	2, 0x09e4
 638:	0a80                	.insn	2, 0x0a80
 63a:	5901                	.insn	2, 0x5901
 63c:	c404                	.insn	2, 0xc404
 63e:	d40c                	.insn	2, 0xd40c
 640:	010c                	.insn	2, 0x010c
 642:	0059                	.insn	2, 0x0059
 644:	0501                	.insn	2, 0x0501
 646:	e804                	.insn	2, 0xe804
 648:	8009                	.insn	2, 0x8009
 64a:	010a                	.insn	2, 0x010a
 64c:	0459                	.insn	2, 0x0459
 64e:	0cd4                	.insn	2, 0x0cd4
 650:	0ce0                	.insn	2, 0x0ce0
 652:	5901                	.insn	2, 0x5901
 654:	e004                	.insn	2, 0xe004
 656:	ec0c                	.insn	2, 0xec0c
 658:	010c                	.insn	2, 0x010c
 65a:	045d                	.insn	2, 0x045d
 65c:	0cec                	.insn	2, 0x0cec
 65e:	0d8c                	.insn	2, 0x0d8c
 660:	5901                	.insn	2, 0x5901
 662:	0100                	.insn	2, 0x0100
 664:	0405                	.insn	2, 0x0405
 666:	09e8                	.insn	2, 0x09e8
 668:	0a80                	.insn	2, 0x0a80
 66a:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 66e:	d404                	.insn	2, 0xd404
 670:	d80c                	.insn	2, 0xd80c
 672:	030c                	.insn	2, 0x030c
 674:	0011                	.insn	2, 0x0011
 676:	049f 0ce0 0ce8      	.insn	6, 0x0ce80ce0049f
 67c:	5801                	.insn	2, 0x5801
 67e:	e804                	.insn	2, 0xe804
 680:	8c0c                	.insn	2, 0x8c0c
 682:	010d                	.insn	2, 0x010d
 684:	005a                	.insn	2, 0x005a
 686:	0501                	.insn	2, 0x0501
 688:	9804                	.insn	2, 0x9804
 68a:	d00a                	.insn	2, 0xd00a
 68c:	0058010b          	.insn	4, 0x0058010b
 690:	0501                	.insn	2, 0x0501
 692:	9804                	.insn	2, 0x9804
 694:	bc0a                	.insn	2, 0xbc0a
 696:	030a                	.insn	2, 0x030a
 698:	0711                	.insn	2, 0x0711
 69a:	049f 0abc 0ad8      	.insn	6, 0x0ad80abc049f
 6a0:	9f061103          	lh	sp,-1552(a2)
 6a4:	d804                	.insn	2, 0xd804
 6a6:	f40a                	.insn	2, 0xf40a
 6a8:	030a                	.insn	2, 0x030a
 6aa:	0511                	.insn	2, 0x0511
 6ac:	049f 0af4 0b90      	.insn	6, 0x0b900af4049f
 6b2:	9f041103          	lh	sp,-1552(s0)
 6b6:	9004                	.insn	2, 0x9004
 6b8:	030bac0b          	.insn	4, 0x030bac0b
 6bc:	0311                	.insn	2, 0x0311
 6be:	049f 0bac 0bc8      	.insn	6, 0x0bc80bac049f
 6c4:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 6c8:	c804                	.insn	2, 0xc804
 6ca:	030be00b          	.insn	4, 0x030be00b
 6ce:	0111                	.insn	2, 0x0111
 6d0:	049f 0be0 0bf0      	.insn	6, 0x0bf00be0049f
 6d6:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 6da:	f004                	.insn	2, 0xf004
 6dc:	030bf80b          	.insn	4, 0x030bf80b
 6e0:	7f11                	.insn	2, 0x7f11
 6e2:	009f 0501 9c04      	.insn	6, 0x9c040501009f
 6e8:	a00a                	.insn	2, 0xa00a
 6ea:	010a                	.insn	2, 0x010a
 6ec:	045a                	.insn	2, 0x045a
 6ee:	0aac                	.insn	2, 0x0aac
 6f0:	0abc                	.insn	2, 0x0abc
 6f2:	5a01                	.insn	2, 0x5a01
 6f4:	c804                	.insn	2, 0xc804
 6f6:	d80a                	.insn	2, 0xd80a
 6f8:	010a                	.insn	2, 0x010a
 6fa:	045a                	.insn	2, 0x045a
 6fc:	0ae4                	.insn	2, 0x0ae4
 6fe:	0af4                	.insn	2, 0x0af4
 700:	5a01                	.insn	2, 0x5a01
 702:	8004                	.insn	2, 0x8004
 704:	010b900b          	.insn	4, 0x010b900b
 708:	045a                	.insn	2, 0x045a
 70a:	0b9c                	.insn	2, 0x0b9c
 70c:	0bac                	.insn	2, 0x0bac
 70e:	5a01                	.insn	2, 0x5a01
 710:	b804                	.insn	2, 0xb804
 712:	010bc80b          	.insn	4, 0x010bc80b
 716:	045a                	.insn	2, 0x045a
 718:	0bd0                	.insn	2, 0x0bd0
 71a:	0bd4                	.insn	2, 0x0bd4
 71c:	5801                	.insn	2, 0x5801
 71e:	0100                	.insn	2, 0x0100
 720:	0405                	.insn	2, 0x0405
 722:	0c9c                	.insn	2, 0x0c9c
 724:	0ca8                	.insn	2, 0x0ca8
 726:	5901                	.insn	2, 0x5901
 728:	a804                	.insn	2, 0xa804
 72a:	b40c                	.insn	2, 0xb40c
 72c:	030c                	.insn	2, 0x030c
 72e:	7f79                	.insn	2, 0x7f79
 730:	049f 0cb4 0cbc      	.insn	6, 0x0cbc0cb4049f
 736:	5901                	.insn	2, 0x5901
 738:	0100                	.insn	2, 0x0100
 73a:	0405                	.insn	2, 0x0405
 73c:	0dd8                	.insn	2, 0x0dd8
 73e:	0de0                	.insn	2, 0x0de0
 740:	5a01                	.insn	2, 0x5a01
 742:	0100                	.insn	2, 0x0100
 744:	0405                	.insn	2, 0x0405
 746:	0de4                	.insn	2, 0x0de4
 748:	0dec                	.insn	2, 0x0dec
 74a:	5a01                	.insn	2, 0x5a01
 74c:	0100                	.insn	2, 0x0100
 74e:	0405                	.insn	2, 0x0405
 750:	0df0                	.insn	2, 0x0df0
 752:	0df8                	.insn	2, 0x0df8
 754:	5a01                	.insn	2, 0x5a01
 756:	0100                	.insn	2, 0x0100
 758:	0405                	.insn	2, 0x0405
 75a:	0dfc                	.insn	2, 0x0dfc
 75c:	0e84                	.insn	2, 0x0e84
 75e:	5a01                	.insn	2, 0x5a01
 760:	0100                	.insn	2, 0x0100
 762:	0405                	.insn	2, 0x0405
 764:	0e94                	.insn	2, 0x0e94
 766:	0ea4                	.insn	2, 0x0ea4
 768:	5b01                	.insn	2, 0x5b01
 76a:	a804                	.insn	2, 0xa804
 76c:	b80e                	.insn	2, 0xb80e
 76e:	010e                	.insn	2, 0x010e
 770:	0501005b          	.insn	4, 0x0501005b
 774:	9404                	.insn	2, 0x9404
 776:	a80e                	.insn	2, 0xa80e
 778:	010e                	.insn	2, 0x010e
 77a:	045a                	.insn	2, 0x045a
 77c:	0ea8                	.insn	2, 0x0ea8
 77e:	0eb4                	.insn	2, 0x0eb4
 780:	5e01                	.insn	2, 0x5e01
 782:	b404                	.insn	2, 0xb404
 784:	c00e                	.insn	2, 0xc00e
 786:	010e                	.insn	2, 0x010e
 788:	005d                	.insn	2, 0x005d
 78a:	0501                	.insn	2, 0x0501
 78c:	c804                	.insn	2, 0xc804
 78e:	d40e                	.insn	2, 0xd40e
 790:	010e                	.insn	2, 0x010e
 792:	045a                	.insn	2, 0x045a
 794:	0ed4                	.insn	2, 0x0ed4
 796:	0edc                	.insn	2, 0x0edc
 798:	9f7f7a03          	.insn	4, 0x9f7f7a03
 79c:	dc04                	.insn	2, 0xdc04
 79e:	e80e                	.insn	2, 0xe80e
 7a0:	010e                	.insn	2, 0x010e
 7a2:	005a                	.insn	2, 0x005a
 7a4:	0501                	.insn	2, 0x0501
 7a6:	f804                	.insn	2, 0xf804
 7a8:	fc0e                	.insn	2, 0xfc0e
 7aa:	010e                	.insn	2, 0x010e
 7ac:	045a                	.insn	2, 0x045a
 7ae:	0efc                	.insn	2, 0x0efc
 7b0:	0fcc                	.insn	2, 0x0fcc
 7b2:	5b01                	.insn	2, 0x5b01
 7b4:	d804                	.insn	2, 0xd804
 7b6:	0110ac0f          	.insn	4, 0x0110ac0f
 7ba:	0501005b          	.insn	4, 0x0501005b
 7be:	fc04                	.insn	2, 0xfc04
 7c0:	980e                	.insn	2, 0x980e
 7c2:	9f3a020f          	.insn	4, 0x9f3a020f
 7c6:	9804                	.insn	2, 0x9804
 7c8:	020fa40f          	.insn	4, 0x020fa40f
 7cc:	9f40                	.insn	2, 0x9f40
 7ce:	a404                	.insn	2, 0xa404
 7d0:	010fb00f          	.insn	4, 0x010fb00f
 7d4:	045c                	.insn	2, 0x045c
 7d6:	0fb0                	.insn	2, 0x0fb0
 7d8:	0fb4                	.insn	2, 0x0fb4
 7da:	3a02                	.insn	2, 0x3a02
 7dc:	049f 0fb4 0fc0      	.insn	6, 0x0fc00fb4049f
 7e2:	5c01                	.insn	2, 0x5c01
 7e4:	c004                	.insn	2, 0xc004
 7e6:	020fc40f          	.insn	4, 0x020fc40f
 7ea:	9f3a                	.insn	2, 0x9f3a
 7ec:	0100                	.insn	2, 0x0100
 7ee:	0405                	.insn	2, 0x0405
 7f0:	0fa4                	.insn	2, 0x0fa4
 7f2:	0fb0                	.insn	2, 0x0fb0
 7f4:	3002                	.insn	2, 0x3002
 7f6:	049f 0fb4 0fc0      	.insn	6, 0x0fc00fb4049f
 7fc:	3002                	.insn	2, 0x3002
 7fe:	049f 0fd8 10a4      	.insn	6, 0x10a40fd8049f
 804:	5a01                	.insn	2, 0x5a01
 806:	a804                	.insn	2, 0xa804
 808:	b410                	.insn	2, 0xb410
 80a:	0110                	.insn	2, 0x0110
 80c:	005a                	.insn	2, 0x005a
 80e:	0501                	.insn	2, 0x0501
 810:	d804                	.insn	2, 0xd804
 812:	01109c0f          	.insn	4, 0x01109c0f
 816:	005d                	.insn	2, 0x005d
 818:	0501                	.insn	2, 0x0501
 81a:	e804                	.insn	2, 0xe804
 81c:	010ff00f          	.insn	4, 0x010ff00f
 820:	0461                	.insn	2, 0x0461
 822:	1080                	.insn	2, 0x1080
 824:	1088                	.insn	2, 0x1088
 826:	6101                	.insn	2, 0x6101
 828:	9804                	.insn	2, 0x9804
 82a:	b010                	.insn	2, 0xb010
 82c:	0110                	.insn	2, 0x0110
 82e:	0061                	.insn	2, 0x0061
 830:	0501                	.insn	2, 0x0501
 832:	b404                	.insn	2, 0xb404
 834:	bc10                	.insn	2, 0xbc10
 836:	0110                	.insn	2, 0x0110
 838:	045a                	.insn	2, 0x045a
 83a:	10c4                	.insn	2, 0x10c4
 83c:	10c8                	.insn	2, 0x10c8
 83e:	5a01                	.insn	2, 0x5a01
 840:	c804                	.insn	2, 0xc804
 842:	f010                	.insn	2, 0xf010
 844:	0110                	.insn	2, 0x0110
 846:	0501005b          	.insn	4, 0x0501005b
 84a:	c804                	.insn	2, 0xc804
 84c:	d810                	.insn	2, 0xd810
 84e:	0210                	.insn	2, 0x0210
 850:	9f32                	.insn	2, 0x9f32
 852:	d804                	.insn	2, 0xd804
 854:	dc10                	.insn	2, 0xdc10
 856:	0110                	.insn	2, 0x0110
 858:	045c                	.insn	2, 0x045c
 85a:	10dc                	.insn	2, 0x10dc
 85c:	10e4                	.insn	2, 0x10e4
 85e:	9f017c03          	.insn	4, 0x9f017c03
 862:	e404                	.insn	2, 0xe404
 864:	ec10                	.insn	2, 0xec10
 866:	0110                	.insn	2, 0x0110
 868:	005c                	.insn	2, 0x005c
 86a:	0501                	.insn	2, 0x0501
 86c:	fc04                	.insn	2, 0xfc04
 86e:	8410                	.insn	2, 0x8410
 870:	0111                	.insn	2, 0x0111
 872:	0501005b          	.insn	4, 0x0501005b
 876:	9004                	.insn	2, 0x9004
 878:	9811                	.insn	2, 0x9811
 87a:	0111                	.insn	2, 0x0111
 87c:	0501005b          	.insn	4, 0x0501005b
 880:	9804                	.insn	2, 0x9804
 882:	a011                	.insn	2, 0xa011
 884:	0111                	.insn	2, 0x0111
 886:	005a                	.insn	2, 0x005a
 888:	0501                	.insn	2, 0x0501
 88a:	ac04                	.insn	2, 0xac04
 88c:	b011                	.insn	2, 0xb011
 88e:	0111                	.insn	2, 0x0111
 890:	005a                	.insn	2, 0x005a
 892:	00000603          	lb	a2,0(zero) # 0 <start-0x400000>
 896:	0005                	.insn	2, 0x0005
 898:	0004                	.insn	2, 0x0004
 89a:	0024                	.insn	2, 0x0024
 89c:	0000                	.insn	2, 0x0000
 89e:	0090                	.insn	2, 0x0090
 8a0:	0000                	.insn	2, 0x0000
 8a2:	009c                	.insn	2, 0x009c
 8a4:	0000                	.insn	2, 0x0000
 8a6:	00a2                	.insn	2, 0x00a2
 8a8:	0000                	.insn	2, 0x0000
 8aa:	00a9                	.insn	2, 0x00a9
 8ac:	0000                	.insn	2, 0x0000
 8ae:	00b2                	.insn	2, 0x00b2
 8b0:	0000                	.insn	2, 0x0000
 8b2:	00ba                	.insn	2, 0x00ba
 8b4:	0000                	.insn	2, 0x0000
 8b6:	00c2                	.insn	2, 0x00c2
 8b8:	0000                	.insn	2, 0x0000
 8ba:	00ca                	.insn	2, 0x00ca
 8bc:	0000                	.insn	2, 0x0000
 8be:	00d2                	.insn	2, 0x00d2
 8c0:	0000                	.insn	2, 0x0000
 8c2:	00e8                	.insn	2, 0x00e8
 8c4:	0000                	.insn	2, 0x0000
 8c6:	00fe                	.insn	2, 0x00fe
 8c8:	0000                	.insn	2, 0x0000
 8ca:	0114                	.insn	2, 0x0114
 8cc:	0000                	.insn	2, 0x0000
 8ce:	011c                	.insn	2, 0x011c
 8d0:	0000                	.insn	2, 0x0000
 8d2:	0124                	.insn	2, 0x0124
 8d4:	0000                	.insn	2, 0x0000
 8d6:	0149                	.insn	2, 0x0149
 8d8:	0000                	.insn	2, 0x0000
 8da:	0196                	.insn	2, 0x0196
 8dc:	0000                	.insn	2, 0x0000
 8de:	000001c7          	.insn	4, 0x01c7
 8e2:	0261                	.insn	2, 0x0261
 8e4:	0000                	.insn	2, 0x0000
 8e6:	0269                	.insn	2, 0x0269
 8e8:	0000                	.insn	2, 0x0000
 8ea:	0271                	.insn	2, 0x0271
 8ec:	0000                	.insn	2, 0x0000
 8ee:	0279                	.insn	2, 0x0279
 8f0:	0000                	.insn	2, 0x0000
 8f2:	0291                	.insn	2, 0x0291
 8f4:	0000                	.insn	2, 0x0000
 8f6:	02a0                	.insn	2, 0x02a0
 8f8:	0000                	.insn	2, 0x0000
 8fa:	02d1                	.insn	2, 0x02d1
 8fc:	0000                	.insn	2, 0x0000
 8fe:	02d9                	.insn	2, 0x02d9
 900:	0000                	.insn	2, 0x0000
 902:	00000373          	.insn	4, 0x0373
 906:	03aa                	.insn	2, 0x03aa
 908:	0000                	.insn	2, 0x0000
 90a:	03b9                	.insn	2, 0x03b9
 90c:	0000                	.insn	2, 0x0000
 90e:	03c1                	.insn	2, 0x03c1
 910:	0000                	.insn	2, 0x0000
 912:	03c9                	.insn	2, 0x03c9
 914:	0000                	.insn	2, 0x0000
 916:	03d1                	.insn	2, 0x03d1
 918:	0000                	.insn	2, 0x0000
 91a:	043e                	.insn	2, 0x043e
 91c:	0000                	.insn	2, 0x0000
 91e:	0478                	.insn	2, 0x0478
 920:	0000                	.insn	2, 0x0000
 922:	0509                	.insn	2, 0x0509
 924:	0000                	.insn	2, 0x0000
 926:	0518                	.insn	2, 0x0518
 928:	0000                	.insn	2, 0x0000
 92a:	058e                	.insn	2, 0x058e
 92c:	0000                	.insn	2, 0x0000
 92e:	0004                	.insn	2, 0x0004
 930:	0114                	.insn	2, 0x0114
 932:	045a                	.insn	2, 0x045a
 934:	ac14                	.insn	2, 0xac14
 936:	0101                	.insn	2, 0x0101
 938:	0058                	.insn	2, 0x0058
 93a:	5c04                	.insn	2, 0x5c04
 93c:	0170                	.insn	2, 0x0170
 93e:	005a                	.insn	2, 0x005a
 940:	7804                	.insn	2, 0x7804
 942:	0184                	.insn	2, 0x0184
 944:	5a01                	.insn	2, 0x5a01
 946:	0400                	.insn	2, 0x0400
 948:	0194                	.insn	2, 0x0194
 94a:	01b4                	.insn	2, 0x01b4
 94c:	3002                	.insn	2, 0x3002
 94e:	009f 8804 9402      	.insn	6, 0x94028804009f
 954:	0102                	.insn	2, 0x0102
 956:	e004005b          	.insn	4, 0xe004005b
 95a:	f402                	.insn	2, 0xf402
 95c:	0102                	.insn	2, 0x0102
 95e:	e404005b          	.insn	4, 0xe404005b
 962:	f802                	.insn	2, 0xf802
 964:	0102                	.insn	2, 0x0102
 966:	005c                	.insn	2, 0x005c
 968:	e804                	.insn	2, 0xe804
 96a:	8c02                	.insn	2, 0x8c02
 96c:	005d0103          	lb	sp,5(s10)
 970:	a804                	.insn	2, 0xa804
 972:	0103e803          	.insn	4, 0x0103e803
 976:	045a                	.insn	2, 0x045a
 978:	03e8                	.insn	2, 0x03e8
 97a:	04c0                	.insn	2, 0x04c0
 97c:	6301                	.insn	2, 0x6301
 97e:	e404                	.insn	2, 0xe404
 980:	c804                	.insn	2, 0xc804
 982:	0108                	.insn	2, 0x0108
 984:	a8040063          	beqz	s0,fffffc04 <USER_MAX+0xffaffc04>
 988:	0103e403          	.insn	4, 0x0103e403
 98c:	03e4045b          	.insn	4, 0x03e4045b
 990:	04bc                	.insn	2, 0x04bc
 992:	6201                	.insn	2, 0x6201
 994:	e404                	.insn	2, 0xe404
 996:	c804                	.insn	2, 0xc804
 998:	0108                	.insn	2, 0x0108
 99a:	0062                	.insn	2, 0x0062
 99c:	a804                	.insn	2, 0xa804
 99e:	0103e003          	.insn	4, 0x0103e003
 9a2:	045c                	.insn	2, 0x045c
 9a4:	03e0                	.insn	2, 0x03e0
 9a6:	04b8                	.insn	2, 0x04b8
 9a8:	5901                	.insn	2, 0x5901
 9aa:	e404                	.insn	2, 0xe404
 9ac:	c804                	.insn	2, 0xc804
 9ae:	0108                	.insn	2, 0x0108
 9b0:	0059                	.insn	2, 0x0059
 9b2:	8404                	.insn	2, 0x8404
 9b4:	9004                	.insn	2, 0x9004
 9b6:	0104                	.insn	2, 0x0104
 9b8:	005a                	.insn	2, 0x005a
 9ba:	9804                	.insn	2, 0x9804
 9bc:	a404                	.insn	2, 0xa404
 9be:	0104                	.insn	2, 0x0104
 9c0:	005a                	.insn	2, 0x005a
 9c2:	8404                	.insn	2, 0x8404
 9c4:	9005                	.insn	2, 0x9005
 9c6:	0305                	.insn	2, 0x0305
 9c8:	0a11                	.insn	2, 0x0a11
 9ca:	049f 07bc 07c0      	.insn	6, 0x07c007bc049f
 9d0:	9f081103          	lh	sp,-1552(a6)
 9d4:	c004                	.insn	2, 0xc004
 9d6:	0307d807          	.insn	4, 0x0307d807
 9da:	0911                	.insn	2, 0x0911
 9dc:	049f 07d8 07e8      	.insn	6, 0x07e807d8049f
 9e2:	9f0a1103          	lh	sp,-1552(s4)
 9e6:	0400                	.insn	2, 0x0400
 9e8:	0584                	.insn	2, 0x0584
 9ea:	0588                	.insn	2, 0x0588
 9ec:	5b01                	.insn	2, 0x5b01
 9ee:	8804                	.insn	2, 0x8804
 9f0:	9405                	.insn	2, 0x9405
 9f2:	0105                	.insn	2, 0x0105
 9f4:	045a                	.insn	2, 0x045a
 9f6:	05cc                	.insn	2, 0x05cc
 9f8:	05d4                	.insn	2, 0x05d4
 9fa:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 9fe:	d404                	.insn	2, 0xd404
 a00:	e005                	.insn	2, 0xe005
 a02:	0105                	.insn	2, 0x0105
 a04:	045a                	.insn	2, 0x045a
 a06:	05e0                	.insn	2, 0x05e0
 a08:	05e8                	.insn	2, 0x05e8
 a0a:	9f011103          	lh	sp,-1552(sp)
 a0e:	e804                	.insn	2, 0xe804
 a10:	b005                	.insn	2, 0xb005
 a12:	045a0107          	.insn	4, 0x045a0107
 a16:	07b0                	.insn	2, 0x07b0
 a18:	07bc                	.insn	2, 0x07bc
 a1a:	9f017a03          	.insn	4, 0x9f017a03
 a1e:	c404                	.insn	2, 0xc404
 a20:	0107cc07          	.insn	4, 0x0107cc07
 a24:	07d0045b          	.insn	4, 0x07d0045b
 a28:	07d8                	.insn	2, 0x07d8
 a2a:	5a01                	.insn	2, 0x5a01
 a2c:	d804                	.insn	2, 0xd804
 a2e:	0107e807          	.insn	4, 0x0107e807
 a32:	8404005b          	.insn	4, 0x8404005b
 a36:	ac05                	.insn	2, 0xac05
 a38:	0905                	.insn	2, 0x0905
 a3a:	0085                	.insn	2, 0x0085
 a3c:	1011                	.insn	2, 0x1011
 a3e:	111c                	.insn	2, 0x111c
 a40:	049f1b7f 05b005ac 	.insn	12, 0x1100850c05b005ac049f1b7f
 a48:	1100850c 
 a4c:	1c10                	.insn	2, 0x1c10
 a4e:	7f11                	.insn	2, 0x7f11
 a50:	2201111b          	.insn	4, 0x2201111b
 a54:	049f 05b8 08c8      	.insn	6, 0x08c805b8049f
 a5a:	8509                	.insn	2, 0x8509
 a5c:	1100                	.insn	2, 0x1100
 a5e:	1c10                	.insn	2, 0x1c10
 a60:	7f11                	.insn	2, 0x7f11
 a62:	04009f1b          	.insn	4, 0x04009f1b
 a66:	05cc                	.insn	2, 0x05cc
 a68:	05d4                	.insn	2, 0x05d4
 a6a:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 a6e:	d404                	.insn	2, 0xd404
 a70:	e005                	.insn	2, 0xe005
 a72:	0305                	.insn	2, 0x0305
 a74:	0111                	.insn	2, 0x0111
 a76:	049f 05e0 05e8      	.insn	6, 0x05e805e0049f
 a7c:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 a80:	e804                	.insn	2, 0xe804
 a82:	fc05                	.insn	2, 0xfc05
 a84:	0305                	.insn	2, 0x0305
 a86:	0111                	.insn	2, 0x0111
 a88:	049f 05fc 0684      	.insn	6, 0x068405fc049f
 a8e:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 a92:	8404                	.insn	2, 0x8404
 a94:	8c06                	.insn	2, 0x8c06
 a96:	0306                	.insn	2, 0x0306
 a98:	0311                	.insn	2, 0x0311
 a9a:	049f 068c 0694      	.insn	6, 0x0694068c049f
 aa0:	9f041103          	lh	sp,-1552(s0)
 aa4:	9404                	.insn	2, 0x9404
 aa6:	9c06                	.insn	2, 0x9c06
 aa8:	0306                	.insn	2, 0x0306
 aaa:	0511                	.insn	2, 0x0511
 aac:	049f 069c 06a4      	.insn	6, 0x06a4069c049f
 ab2:	9f061103          	lh	sp,-1552(a2)
 ab6:	a404                	.insn	2, 0xa404
 ab8:	ac06                	.insn	2, 0xac06
 aba:	0306                	.insn	2, 0x0306
 abc:	0711                	.insn	2, 0x0711
 abe:	049f 06b8 06c4      	.insn	6, 0x06c406b8049f
 ac4:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 ac8:	c404                	.insn	2, 0xc404
 aca:	d806                	.insn	2, 0xd806
 acc:	0306                	.insn	2, 0x0306
 ace:	0311                	.insn	2, 0x0311
 ad0:	049f 06d8 06ec      	.insn	6, 0x06ec06d8049f
 ad6:	9f041103          	lh	sp,-1552(s0)
 ada:	ec04                	.insn	2, 0xec04
 adc:	8006                	.insn	2, 0x8006
 ade:	05110307          	.insn	4, 0x05110307
 ae2:	049f 0780 0794      	.insn	6, 0x07940780049f
 ae8:	9f061103          	lh	sp,-1552(a2)
 aec:	9404                	.insn	2, 0x9404
 aee:	0307a807          	.insn	4, 0x0307a807
 af2:	0711                	.insn	2, 0x0711
 af4:	049f 07a8 07b0      	.insn	6, 0x07b007a8049f
 afa:	9f081103          	lh	sp,-1552(a6)
 afe:	0400                	.insn	2, 0x0400
 b00:	08c8                	.insn	2, 0x08c8
 b02:	08dc                	.insn	2, 0x08dc
 b04:	5a01                	.insn	2, 0x5a01
 b06:	0400                	.insn	2, 0x0400
 b08:	09ac                	.insn	2, 0x09ac
 b0a:	09b8                	.insn	2, 0x09b8
 b0c:	5a01                	.insn	2, 0x5a01
 b0e:	0400                	.insn	2, 0x0400
 b10:	09c0                	.insn	2, 0x09c0
 b12:	09cc                	.insn	2, 0x09cc
 b14:	5a01                	.insn	2, 0x5a01
 b16:	0400                	.insn	2, 0x0400
 b18:	0aac                	.insn	2, 0x0aac
 b1a:	0ac0                	.insn	2, 0x0ac0
 b1c:	3002                	.insn	2, 0x3002
 b1e:	049f 0ac0 0af4      	.insn	6, 0x0af40ac0049f
 b24:	5c01                	.insn	2, 0x5c01
 b26:	c004                	.insn	2, 0xc004
 b28:	cc0d                	.insn	2, 0xcc0d
 b2a:	020d                	.insn	2, 0x020d
 b2c:	9f30                	.insn	2, 0x9f30
 b2e:	0400                	.insn	2, 0x0400
 b30:	0aac                	.insn	2, 0x0aac
 b32:	0af4                	.insn	2, 0x0af4
 b34:	5b01                	.insn	2, 0x5b01
 b36:	c004                	.insn	2, 0xc004
 b38:	cc0d                	.insn	2, 0xcc0d
 b3a:	010d                	.insn	2, 0x010d
 b3c:	ac04005b          	.insn	4, 0xac04005b
 b40:	f40a                	.insn	2, 0xf40a
 b42:	090a                	.insn	2, 0x090a
 b44:	0084                	.insn	2, 0x0084
 b46:	1011                	.insn	2, 0x1011
 b48:	111c                	.insn	2, 0x111c
 b4a:	049f1b7f 0af80af4 	.insn	12, 0x1100840c0af80af4049f1b7f
 b52:	1100840c 
 b56:	1c10                	.insn	2, 0x1c10
 b58:	7f11                	.insn	2, 0x7f11
 b5a:	2201111b          	.insn	4, 0x2201111b
 b5e:	049f 0b80 0df0      	.insn	6, 0x0df00b80049f
 b64:	8409                	.insn	2, 0x8409
 b66:	1100                	.insn	2, 0x1100
 b68:	1c10                	.insn	2, 0x1c10
 b6a:	7f11                	.insn	2, 0x7f11
 b6c:	04009f1b          	.insn	4, 0x04009f1b
 b70:	0ae8                	.insn	2, 0x0ae8
 b72:	0af4                	.insn	2, 0x0af4
 b74:	5d01                	.insn	2, 0x5d01
 b76:	0400                	.insn	2, 0x0400
 b78:	0b94                	.insn	2, 0x0b94
 b7a:	0b98                	.insn	2, 0x0b98
 b7c:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 b80:	9804                	.insn	2, 0x9804
 b82:	030ba00b          	.insn	4, 0x030ba00b
 b86:	0111                	.insn	2, 0x0111
 b88:	049f 0ba0 0ba8      	.insn	6, 0x0ba80ba0049f
 b8e:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 b92:	a804                	.insn	2, 0xa804
 b94:	030bb00b          	.insn	4, 0x030bb00b
 b98:	0311                	.insn	2, 0x0311
 b9a:	049f 0bb0 0bb8      	.insn	6, 0x0bb80bb0049f
 ba0:	9f041103          	lh	sp,-1552(s0)
 ba4:	b804                	.insn	2, 0xb804
 ba6:	030bc00b          	.insn	4, 0x030bc00b
 baa:	0511                	.insn	2, 0x0511
 bac:	049f 0bc0 0bc8      	.insn	6, 0x0bc80bc0049f
 bb2:	9f061103          	lh	sp,-1552(a2)
 bb6:	c804                	.insn	2, 0xc804
 bb8:	030bd00b          	.insn	4, 0x030bd00b
 bbc:	0711                	.insn	2, 0x0711
 bbe:	049f 0bdc 0be4      	.insn	6, 0x0be40bdc049f
 bc4:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 bc8:	e404                	.insn	2, 0xe404
 bca:	030bf40b          	.insn	4, 0x030bf40b
 bce:	0111                	.insn	2, 0x0111
 bd0:	049f 0bf4 0c84      	.insn	6, 0x0c840bf4049f
 bd6:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 bda:	8404                	.insn	2, 0x8404
 bdc:	940c                	.insn	2, 0x940c
 bde:	030c                	.insn	2, 0x030c
 be0:	0311                	.insn	2, 0x0311
 be2:	049f 0c94 0ca4      	.insn	6, 0x0ca40c94049f
 be8:	9f041103          	lh	sp,-1552(s0)
 bec:	a404                	.insn	2, 0xa404
 bee:	b40c                	.insn	2, 0xb40c
 bf0:	030c                	.insn	2, 0x030c
 bf2:	0511                	.insn	2, 0x0511
 bf4:	049f 0cb4 0cc4      	.insn	6, 0x0cc40cb4049f
 bfa:	9f061103          	lh	sp,-1552(a2)
 bfe:	c404                	.insn	2, 0xc404
 c00:	d40c                	.insn	2, 0xd40c
 c02:	030c                	.insn	2, 0x030c
 c04:	0711                	.insn	2, 0x0711
 c06:	049f 0cd4 0cdc      	.insn	6, 0x0cdc0cd4049f
 c0c:	9f081103          	lh	sp,-1552(a6)
 c10:	0400                	.insn	2, 0x0400
 c12:	0ce8                	.insn	2, 0x0ce8
 c14:	0cf0                	.insn	2, 0x0cf0
 c16:	9f081103          	lh	sp,-1552(a6)
 c1a:	f004                	.insn	2, 0xf004
 c1c:	f80c                	.insn	2, 0xf80c
 c1e:	030c                	.insn	2, 0x030c
 c20:	0911                	.insn	2, 0x0911
 c22:	049f 0cf8 0d88      	.insn	6, 0x0d880cf8049f
 c28:	9f0a1103          	lh	sp,-1552(s4)
 c2c:	cc04                	.insn	2, 0xcc04
 c2e:	d40d                	.insn	2, 0xd40d
 c30:	030d                	.insn	2, 0x030d
 c32:	0811                	.insn	2, 0x0811
 c34:	049f 0dd4 0de4      	.insn	6, 0x0de40dd4049f
 c3a:	9f091103          	lh	sp,-1552(s2)
 c3e:	e404                	.insn	2, 0xe404
 c40:	f00d                	.insn	2, 0xf00d
 c42:	030d                	.insn	2, 0x030d
 c44:	0a11                	.insn	2, 0x0a11
 c46:	009f f004 900d      	.insn	6, 0x900df004009f
 c4c:	010e                	.insn	2, 0x010e
 c4e:	045a                	.insn	2, 0x045a
 c50:	0e90                	.insn	2, 0x0e90
 c52:	1588                	.insn	2, 0x1588
 c54:	5801                	.insn	2, 0x5801
 c56:	0400                	.insn	2, 0x0400
 c58:	0eac                	.insn	2, 0x0eac
 c5a:	0eb8                	.insn	2, 0x0eb8
 c5c:	5a01                	.insn	2, 0x5a01
 c5e:	0400                	.insn	2, 0x0400
 c60:	0ec0                	.insn	2, 0x0ec0
 c62:	14fc                	.insn	2, 0x14fc
 c64:	5901                	.insn	2, 0x5901
 c66:	0400                	.insn	2, 0x0400
 c68:	0edc                	.insn	2, 0x0edc
 c6a:	0fe0                	.insn	2, 0x0fe0
 c6c:	5801                	.insn	2, 0x5801
 c6e:	0400                	.insn	2, 0x0400
 c70:	0edc                	.insn	2, 0x0edc
 c72:	0ee4                	.insn	2, 0x0ee4
 c74:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 c78:	e404                	.insn	2, 0xe404
 c7a:	e80e                	.insn	2, 0xe80e
 c7c:	030e                	.insn	2, 0x030e
 c7e:	0111                	.insn	2, 0x0111
 c80:	049f 0ee8 0eec      	.insn	6, 0x0eec0ee8049f
 c86:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 c8a:	ec04                	.insn	2, 0xec04
 c8c:	f00e                	.insn	2, 0xf00e
 c8e:	030e                	.insn	2, 0x030e
 c90:	0311                	.insn	2, 0x0311
 c92:	049f 0ef0 0ef4      	.insn	6, 0x0ef40ef0049f
 c98:	9f041103          	lh	sp,-1552(s0)
 c9c:	f404                	.insn	2, 0xf404
 c9e:	f80e                	.insn	2, 0xf80e
 ca0:	030e                	.insn	2, 0x030e
 ca2:	0511                	.insn	2, 0x0511
 ca4:	049f 0ef8 0efc      	.insn	6, 0x0efc0ef8049f
 caa:	9f061103          	lh	sp,-1552(a2)
 cae:	fc04                	.insn	2, 0xfc04
 cb0:	800e                	.insn	2, 0x800e
 cb2:	0711030f          	.insn	4, 0x0711030f
 cb6:	049f 0f80 0f84      	.insn	6, 0x0f840f80049f
 cbc:	9f081103          	lh	sp,-1552(a6)
 cc0:	8404                	.insn	2, 0x8404
 cc2:	030f880f          	.insn	4, 0x030f880f
 cc6:	0911                	.insn	2, 0x0911
 cc8:	049f 0f88 0f8c      	.insn	6, 0x0f8c0f88049f
 cce:	9f0a1103          	lh	sp,-1552(s4)
 cd2:	8c04                	.insn	2, 0x8c04
 cd4:	0310b40f          	.insn	4, 0x0310b40f
 cd8:	0b11                	.insn	2, 0x0b11
 cda:	009f 8c04 a00f      	.insn	6, 0xa00f8c04009f
 ce0:	0011030f          	.insn	4, 0x0011030f
 ce4:	049f 0fa0 0fbc      	.insn	6, 0x0fbc0fa0049f
 cea:	5b01                	.insn	2, 0x5b01
 cec:	bc04                	.insn	2, 0xbc04
 cee:	010fcc0f          	.insn	4, 0x010fcc0f
 cf2:	045f 0fcc 0fd4      	.insn	6, 0x0fd40fcc045f
 cf8:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 cfc:	d404                	.insn	2, 0xd404
 cfe:	010fd80f          	.insn	4, 0x010fd80f
 d02:	0ffc045b          	.insn	4, 0x0ffc045b
 d06:	1094                	.insn	2, 0x1094
 d08:	9f081103          	lh	sp,-1552(a6)
 d0c:	9404                	.insn	2, 0x9404
 d0e:	b010                	.insn	2, 0xb010
 d10:	0310                	.insn	2, 0x0310
 d12:	097c                	.insn	2, 0x097c
 d14:	009f b404 cc10      	.insn	6, 0xcc10b404009f
 d1a:	0310                	.insn	2, 0x0310
 d1c:	0011                	.insn	2, 0x0011
 d1e:	049f 10cc 10e0      	.insn	6, 0x10e010cc049f
 d24:	9f011103          	lh	sp,-1552(sp)
 d28:	e004                	.insn	2, 0xe004
 d2a:	f410                	.insn	2, 0xf410
 d2c:	0310                	.insn	2, 0x0310
 d2e:	0211                	.insn	2, 0x0211
 d30:	049f 10f4 1188      	.insn	6, 0x118810f4049f
 d36:	9f031103          	lh	sp,-1552(t1)
 d3a:	8804                	.insn	2, 0x8804
 d3c:	9c11                	.insn	2, 0x9c11
 d3e:	0311                	.insn	2, 0x0311
 d40:	0411                	.insn	2, 0x0411
 d42:	049f 119c 11b0      	.insn	6, 0x11b0119c049f
 d48:	9f051103          	lh	sp,-1552(a0)
 d4c:	b004                	.insn	2, 0xb004
 d4e:	c411                	.insn	2, 0xc411
 d50:	0311                	.insn	2, 0x0311
 d52:	0611                	.insn	2, 0x0611
 d54:	049f 11c4 11d8      	.insn	6, 0x11d811c4049f
 d5a:	9f071103          	lh	sp,-1552(a4)
 d5e:	d804                	.insn	2, 0xd804
 d60:	ec11                	.insn	2, 0xec11
 d62:	0311                	.insn	2, 0x0311
 d64:	0811                	.insn	2, 0x0811
 d66:	049f 11ec 1280      	.insn	6, 0x128011ec049f
 d6c:	9f091103          	lh	sp,-1552(s2)
 d70:	8004                	.insn	2, 0x8004
 d72:	9412                	.insn	2, 0x9412
 d74:	0312                	.insn	2, 0x0312
 d76:	0a11                	.insn	2, 0x0a11
 d78:	049f 1294 12a8      	.insn	6, 0x12a81294049f
 d7e:	9f0b1103          	lh	sp,-1552(s6)
 d82:	a804                	.insn	2, 0xa804
 d84:	bc12                	.insn	2, 0xbc12
 d86:	0312                	.insn	2, 0x0312
 d88:	0c11                	.insn	2, 0x0c11
 d8a:	049f 12bc 12d0      	.insn	6, 0x12d012bc049f
 d90:	9f0d1103          	lh	sp,-1552(s10)
 d94:	d004                	.insn	2, 0xd004
 d96:	e412                	.insn	2, 0xe412
 d98:	0312                	.insn	2, 0x0312
 d9a:	0e11                	.insn	2, 0x0e11
 d9c:	049f 12e4 12f8      	.insn	6, 0x12f812e4049f
 da2:	9f0f1103          	lh	sp,-1552(t5)
 da6:	0400                	.insn	2, 0x0400
 da8:	10b4                	.insn	2, 0x10b4
 daa:	10d4                	.insn	2, 0x10d4
 dac:	6201                	.insn	2, 0x6201
 dae:	d404                	.insn	2, 0xd404
 db0:	f810                	.insn	2, 0xf810
 db2:	0112                	.insn	2, 0x0112
 db4:	005a                	.insn	2, 0x005a
 db6:	f804                	.insn	2, 0xf804
 db8:	fc12                	.insn	2, 0xfc12
 dba:	0312                	.insn	2, 0x0312
 dbc:	0c11                	.insn	2, 0x0c11
 dbe:	049f 12fc 1380      	.insn	6, 0x138012fc049f
 dc4:	9f0d1103          	lh	sp,-1552(s10)
 dc8:	8004                	.insn	2, 0x8004
 dca:	03138413          	addi	s0,t2,49
 dce:	0e11                	.insn	2, 0x0e11
 dd0:	049f 1384 1388      	.insn	6, 0x13881384049f
 dd6:	9f0f1103          	lh	sp,-1552(t5)
 dda:	8804                	.insn	2, 0x8804
 ddc:	03138c13          	addi	s8,t2,49
 de0:	1011                	.insn	2, 0x1011
 de2:	049f 138c 1390      	.insn	6, 0x1390138c049f
 de8:	9f111103          	lh	sp,-1551(sp)
 dec:	9004                	.insn	2, 0x9004
 dee:	03139413          	slli	s0,t2,0x31
 df2:	1211                	.insn	2, 0x1211
 df4:	049f 1394 1398      	.insn	6, 0x13981394049f
 dfa:	9f131103          	lh	sp,-1551(t1)
 dfe:	9804                	.insn	2, 0x9804
 e00:	0313a413          	slti	s0,t2,49
 e04:	1611                	.insn	2, 0x1611
 e06:	049f 13a4 13a8      	.insn	6, 0x13a813a4049f
 e0c:	9f171103          	lh	sp,-1551(a4)
 e10:	a804                	.insn	2, 0xa804
 e12:	0313fc13          	andi	s8,t2,49
 e16:	1811                	.insn	2, 0x1811
 e18:	049f 13fc 1480      	.insn	6, 0x148013fc049f
 e1e:	9f191103          	lh	sp,-1551(s2)
 e22:	8004                	.insn	2, 0x8004
 e24:	dc14                	.insn	2, 0xdc14
 e26:	0314                	.insn	2, 0x0314
 e28:	2011                	.insn	2, 0x2011
 e2a:	009f cc04 d013      	.insn	6, 0xd013cc04009f
 e30:	01110313          	addi	t1,sp,17
 e34:	049f 13d0 13d4      	.insn	6, 0x13d413d0049f
 e3a:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <USER_MAX+0xffaff9f0>
 e3e:	d404                	.insn	2, 0xd404
 e40:	0313d813          	srli	a6,t2,0x31
 e44:	0311                	.insn	2, 0x0311
 e46:	049f 13d8 13e8      	.insn	6, 0x13e813d8049f
 e4c:	9f041103          	lh	sp,-1552(s0)
 e50:	e804                	.insn	2, 0xe804
 e52:	0313ec13          	ori	s8,t2,49
 e56:	0511                	.insn	2, 0x0511
 e58:	049f 13ec 13f0      	.insn	6, 0x13f013ec049f
 e5e:	9f061103          	lh	sp,-1552(a2)
 e62:	f004                	.insn	2, 0xf004
 e64:	0313f413          	andi	s0,t2,49
 e68:	0711                	.insn	2, 0x0711
 e6a:	049f 13f4 13f8      	.insn	6, 0x13f813f4049f
 e70:	9f081103          	lh	sp,-1552(a6)
 e74:	f804                	.insn	2, 0xf804
 e76:	03148013          	addi	zero,s1,49
 e7a:	0b11                	.insn	2, 0x0b11
 e7c:	049f 1480 148c      	.insn	6, 0x148c1480049f
 e82:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <USER_MAX+0xffaff9f0>
 e86:	8c04                	.insn	2, 0x8c04
 e88:	9014                	.insn	2, 0x9014
 e8a:	0314                	.insn	2, 0x0314
 e8c:	0911                	.insn	2, 0x0911
 e8e:	049f 1490 14dc      	.insn	6, 0x14dc1490049f
 e94:	9f0a1103          	lh	sp,-1552(s4)
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
 37c:	011d                	.insn	2, 0x011d
 37e:	1331                	.insn	2, 0x1331
 380:	2355                	.insn	2, 0x2355
 382:	0b58                	.insn	2, 0x0b58
 384:	0b59                	.insn	2, 0x0b59
 386:	00000b57          	.insn	4, 0x0b57
 38a:	051d                	.insn	2, 0x051d
 38c:	0200                	.insn	2, 0x0200
 38e:	3122                	.insn	2, 0x3122
 390:	1e000013          	li	zero,480
 394:	0005                	.insn	2, 0x0005
 396:	1802                	.insn	2, 0x1802
 398:	1331                	.insn	2, 0x1331
 39a:	0000                	.insn	2, 0x0000
 39c:	051f 1c00 310f      	.insn	6, 0x310f1c00051f
 3a2:	20000013          	li	zero,512
 3a6:	012e                	.insn	2, 0x012e
 3a8:	1b11                	.insn	2, 0x1b11
 3aa:	0612                	.insn	2, 0x0612
 3ac:	1840                	.insn	2, 0x1840
 3ae:	197a                	.insn	2, 0x197a
 3b0:	1331                	.insn	2, 0x1331
 3b2:	0000                	.insn	2, 0x0000
 3b4:	3421                	.insn	2, 0x3421
 3b6:	0200                	.insn	2, 0x0200
 3b8:	3118                	.insn	2, 0x3118
 3ba:	22000013          	li	zero,544
 3be:	0034                	.insn	2, 0x0034
 3c0:	0f1c                	.insn	2, 0x0f1c
 3c2:	1331                	.insn	2, 0x1331
 3c4:	0000                	.insn	2, 0x0000
 3c6:	11012e23          	sw	a6,284(sp)
 3ca:	4006121b          	.insn	4, 0x4006121b
 3ce:	7a18                	.insn	2, 0x7a18
 3d0:	0319                	.insn	2, 0x0319
 3d2:	3a25                	.insn	2, 0x3a25
 3d4:	270b3b0b          	.insn	4, 0x270b3b0b
 3d8:	4919                	.insn	2, 0x4919
 3da:	00193f13          	seqz	t5,s2
 3de:	2400                	.insn	2, 0x2400
 3e0:	011d                	.insn	2, 0x011d
 3e2:	1331                	.insn	2, 0x1331
 3e4:	1b11                	.insn	2, 0x1b11
 3e6:	0612                	.insn	2, 0x0612
 3e8:	0b58                	.insn	2, 0x0b58
 3ea:	0559                	.insn	2, 0x0559
 3ec:	00000b57          	.insn	4, 0x0b57
 3f0:	4825                	.insn	2, 0x4825
 3f2:	7f00                	.insn	2, 0x7f00
 3f4:	001b7d13          	andi	s10,s6,1
 3f8:	2600                	.insn	2, 0x2600
 3fa:	012e                	.insn	2, 0x012e
 3fc:	0b3a2503          	lw	a0,179(s4)
 400:	19270b3b          	.insn	4, 0x19270b3b
 404:	1349                	.insn	2, 0x1349
 406:	193c                	.insn	2, 0x193c
 408:	0000193f 49000527 	.insn	8, 0x490005270000193f
 410:	28000013          	li	zero,640
 414:	0026                	.insn	2, 0x0026
 416:	1349                	.insn	2, 0x1349
 418:	0000                	.insn	2, 0x0000
 41a:	2e29                	.insn	2, 0x2e29
 41c:	1101                	.insn	2, 0x1101
 41e:	4006121b          	.insn	4, 0x4006121b
 422:	7a18                	.insn	2, 0x7a18
 424:	0319                	.insn	2, 0x0319
 426:	3a25                	.insn	2, 0x3a25
 428:	27053b0b          	.insn	4, 0x27053b0b
 42c:	3f19                	.insn	2, 0x3f19
 42e:	0019                	.insn	2, 0x0019
 430:	2a00                	.insn	2, 0x2a00
 432:	0005                	.insn	2, 0x0005
 434:	2202                	.insn	2, 0x2202
 436:	0b3a2503          	lw	a0,179(s4)
 43a:	1349053b          	.insn	4, 0x1349053b
 43e:	0000                	.insn	2, 0x0000
 440:	0200342b          	.insn	4, 0x0200342b
 444:	0318                	.insn	2, 0x0318
 446:	3a25                	.insn	2, 0x3a25
 448:	49053b0b          	.insn	4, 0x49053b0b
 44c:	2c000013          	li	zero,704
 450:	000a                	.insn	2, 0x000a
 452:	0b3a2503          	lw	a0,179(s4)
 456:	0b39053b          	.insn	4, 0x0b39053b
 45a:	1b11                	.insn	2, 0x1b11
 45c:	0000                	.insn	2, 0x0000
 45e:	0b2d                	.insn	2, 0x0b2d
 460:	5501                	.insn	2, 0x5501
 462:	2e000023          	sb	zero,736(zero) # 2e0 <start-0x3ffd20>
 466:	0034                	.insn	2, 0x0034
 468:	2202                	.insn	2, 0x2202
 46a:	0b3a2503          	lw	a0,179(s4)
 46e:	1349053b          	.insn	4, 0x1349053b
 472:	0000                	.insn	2, 0x0000
 474:	31001d2f          	.insn	4, 0x31001d2f
 478:	121b1113          	.insn	4, 0x121b1113
 47c:	5806                	.insn	2, 0x5806
 47e:	5705590b          	.insn	4, 0x5705590b
 482:	3000000b          	.insn	4, 0x3000000b
 486:	001d                	.insn	2, 0x001d
 488:	1331                	.insn	2, 0x1331
 48a:	2355                	.insn	2, 0x2355
 48c:	0b58                	.insn	2, 0x0b58
 48e:	0559                	.insn	2, 0x0559
 490:	00000b57          	.insn	4, 0x0b57
 494:	1831                	.insn	2, 0x1831
 496:	0000                	.insn	2, 0x0000
 498:	3200                	.insn	2, 0x3200
 49a:	012e                	.insn	2, 0x012e
 49c:	1b11                	.insn	2, 0x1b11
 49e:	0612                	.insn	2, 0x0612
 4a0:	1840                	.insn	2, 0x1840
 4a2:	197a                	.insn	2, 0x197a
 4a4:	0b3a2503          	lw	a0,179(s4)
 4a8:	1927053b          	.insn	4, 0x1927053b
 4ac:	1349                	.insn	2, 0x1349
 4ae:	0000193f 02000533 	.insn	8, 0x020005330000193f
 4b6:	0318                	.insn	2, 0x0318
 4b8:	3a25                	.insn	2, 0x3a25
 4ba:	49053b0b          	.insn	4, 0x49053b0b
 4be:	34000013          	li	zero,832
 4c2:	012e                	.insn	2, 0x012e
 4c4:	0b3a2503          	lw	a0,179(s4)
 4c8:	1927053b          	.insn	4, 0x1927053b
 4cc:	2120                	.insn	2, 0x2120
 4ce:	0001                	.insn	2, 0x0001
 4d0:	3500                	.insn	2, 0x3500
 4d2:	0034                	.insn	2, 0x0034
 4d4:	0f1c                	.insn	2, 0x0f1c
 4d6:	0b3a2503          	lw	a0,179(s4)
 4da:	1349053b          	.insn	4, 0x1349053b
 4de:	0000                	.insn	2, 0x0000
 4e0:	2e36                	.insn	2, 0x2e36
 4e2:	1100                	.insn	2, 0x1100
 4e4:	4006121b          	.insn	4, 0x4006121b
 4e8:	7a18                	.insn	2, 0x7a18
 4ea:	0319                	.insn	2, 0x0319
 4ec:	3a25                	.insn	2, 0x3a25
 4ee:	27053b0b          	.insn	4, 0x27053b0b
 4f2:	3f19                	.insn	2, 0x3f19
 4f4:	0019                	.insn	2, 0x0019
 4f6:	3700                	.insn	2, 0x3700
 4f8:	0016                	.insn	2, 0x0016
 4fa:	1349                	.insn	2, 0x1349
 4fc:	00002503          	lw	a0,0(zero) # 0 <start-0x400000>
 500:	0f38                	.insn	2, 0x0f38
 502:	0000                	.insn	2, 0x0000
 504:	0000                	.insn	2, 0x0000
 506:	1101                	.insn	2, 0x1101
 508:	2501                	.insn	2, 0x2501
 50a:	1325                	.insn	2, 0x1325
 50c:	0305                	.insn	2, 0x0305
 50e:	7225                	.insn	2, 0x7225
 510:	1b171017          	auipc	zero,0x1b171
 514:	1125                	.insn	2, 0x1125
 516:	7306121b          	.insn	4, 0x7306121b
 51a:	8c177417          	auipc	s0,0x8c177
 51e:	1701                	.insn	2, 0x1701
 520:	0000                	.insn	2, 0x0000
 522:	3402                	.insn	2, 0x3402
 524:	4900                	.insn	2, 0x4900
 526:	3b0b3a13          	sltiu	s4,s6,944
 52a:	0018020b          	.insn	4, 0x0018020b
 52e:	0300                	.insn	2, 0x0300
 530:	0101                	.insn	2, 0x0101
 532:	1349                	.insn	2, 0x1349
 534:	0000                	.insn	2, 0x0000
 536:	2104                	.insn	2, 0x2104
 538:	4900                	.insn	2, 0x4900
 53a:	000b3713          	sltiu	a4,s6,0
 53e:	0500                	.insn	2, 0x0500
 540:	0024                	.insn	2, 0x0024
 542:	0b3e2503          	lw	a0,179(t3) # 110123e1 <USER_MAX+0x10b123e1>
 546:	00000b0b          	.insn	4, 0x0b0b
 54a:	2406                	.insn	2, 0x2406
 54c:	0300                	.insn	2, 0x0300
 54e:	0b25                	.insn	2, 0x0b25
 550:	000b3e0b          	.insn	4, 0x000b3e0b
 554:	0700                	.insn	2, 0x0700
 556:	0034                	.insn	2, 0x0034
 558:	1349                	.insn	2, 0x1349
 55a:	0b3a                	.insn	2, 0x0b3a
 55c:	1802053b          	.insn	4, 0x1802053b
 560:	0000                	.insn	2, 0x0000
 562:	3408                	.insn	2, 0x3408
 564:	0300                	.insn	2, 0x0300
 566:	4925                	.insn	2, 0x4925
 568:	3b0b3a13          	sltiu	s4,s6,944
 56c:	0018020b          	.insn	4, 0x0018020b
 570:	0900                	.insn	2, 0x0900
 572:	0021                	.insn	2, 0x0021
 574:	1349                	.insn	2, 0x1349
 576:	00000537          	lui	a0,0x0
 57a:	160a                	.insn	2, 0x160a
 57c:	4900                	.insn	2, 0x4900
 57e:	3a250313          	addi	t1,a0,930 # 3a2 <start-0x3ffc5e>
 582:	000b3b0b          	.insn	4, 0x000b3b0b
 586:	0b00                	.insn	2, 0x0b00
 588:	0034                	.insn	2, 0x0034
 58a:	13492503          	lw	a0,308(s2)
 58e:	0b3a193f 18020b3b 	.insn	8, 0x18020b3b0b3a193f
 596:	0000                	.insn	2, 0x0000
 598:	130c                	.insn	2, 0x130c
 59a:	0b01                	.insn	2, 0x0b01
 59c:	3b0b3a0b          	.insn	4, 0x3b0b3a0b
 5a0:	0d00000b          	.insn	4, 0x0d00000b
 5a4:	000d                	.insn	2, 0x000d
 5a6:	13492503          	lw	a0,308(s2)
 5aa:	0b3a                	.insn	2, 0x0b3a
 5ac:	0b380b3b          	.insn	4, 0x0b380b3b
 5b0:	0000                	.insn	2, 0x0000
 5b2:	2e0e                	.insn	2, 0x2e0e
 5b4:	0301                	.insn	2, 0x0301
 5b6:	3a25                	.insn	2, 0x3a25
 5b8:	270b3b0b          	.insn	4, 0x270b3b0b
 5bc:	4919                	.insn	2, 0x4919
 5be:	20193f13          	sltiu	t5,s2,513
 5c2:	0121                	.insn	2, 0x0121
 5c4:	0000                	.insn	2, 0x0000
 5c6:	0300050f          	.insn	4, 0x0300050f
 5ca:	3a25                	.insn	2, 0x3a25
 5cc:	490b3b0b          	.insn	4, 0x490b3b0b
 5d0:	10000013          	li	zero,256
 5d4:	012e                	.insn	2, 0x012e
 5d6:	1b11                	.insn	2, 0x1b11
 5d8:	0612                	.insn	2, 0x0612
 5da:	1840                	.insn	2, 0x1840
 5dc:	197a                	.insn	2, 0x197a
 5de:	0b3a2503          	lw	a0,179(s4)
 5e2:	19270b3b          	.insn	4, 0x19270b3b
 5e6:	1349                	.insn	2, 0x1349
 5e8:	0000193f 02000511 	.insn	8, 0x020005110000193f
 5f0:	0322                	.insn	2, 0x0322
 5f2:	3a25                	.insn	2, 0x3a25
 5f4:	490b3b0b          	.insn	4, 0x490b3b0b
 5f8:	12000013          	li	zero,288
 5fc:	0034                	.insn	2, 0x0034
 5fe:	1802                	.insn	2, 0x1802
 600:	0b3a2503          	lw	a0,179(s4)
 604:	13490b3b          	.insn	4, 0x13490b3b
 608:	0000                	.insn	2, 0x0000
 60a:	02003413          	sltiu	s0,zero,32
 60e:	0322                	.insn	2, 0x0322
 610:	3a25                	.insn	2, 0x3a25
 612:	490b3b0b          	.insn	4, 0x490b3b0b
 616:	14000013          	li	zero,320
 61a:	011d                	.insn	2, 0x011d
 61c:	1331                	.insn	2, 0x1331
 61e:	1b11                	.insn	2, 0x1b11
 620:	0612                	.insn	2, 0x0612
 622:	0b58                	.insn	2, 0x0b58
 624:	0b59                	.insn	2, 0x0b59
 626:	00000b57          	.insn	4, 0x0b57
 62a:	0515                	.insn	2, 0x0515
 62c:	0200                	.insn	2, 0x0200
 62e:	3122                	.insn	2, 0x3122
 630:	16000013          	li	zero,352
 634:	1b11010b          	.insn	4, 0x1b11010b
 638:	0612                	.insn	2, 0x0612
 63a:	0000                	.insn	2, 0x0000
 63c:	7f004817          	auipc	a6,0x7f004
 640:	001b7d13          	andi	s10,s6,1
 644:	1800                	.insn	2, 0x1800
 646:	0034                	.insn	2, 0x0034
 648:	0b3a2503          	lw	a0,179(s4)
 64c:	13490b3b          	.insn	4, 0x13490b3b
 650:	0000                	.insn	2, 0x0000
 652:	0b19                	.insn	2, 0x0b19
 654:	5501                	.insn	2, 0x5501
 656:	1a000023          	sb	zero,416(zero) # 1a0 <start-0x3ffe60>
 65a:	012e                	.insn	2, 0x012e
 65c:	0b3a2503          	lw	a0,179(s4)
 660:	19270b3b          	.insn	4, 0x19270b3b
 664:	193c                	.insn	2, 0x193c
 666:	0000193f 4900051b 	.insn	8, 0x4900051b0000193f
 66e:	1c000013          	li	zero,448
 672:	0018                	.insn	2, 0x0018
 674:	0000                	.insn	2, 0x0000
 676:	0f1d                	.insn	2, 0x0f1d
 678:	4900                	.insn	2, 0x4900
 67a:	1e000013          	li	zero,480
 67e:	0026                	.insn	2, 0x0026
 680:	1349                	.insn	2, 0x1349
 682:	0000                	.insn	2, 0x0000
 684:	2e1f 0301 3a25      	.insn	6, 0x3a2503012e1f
 68a:	270b3b0b          	.insn	4, 0x270b3b0b
 68e:	4919                	.insn	2, 0x4919
 690:	3f193c13          	sltiu	s8,s2,1009
 694:	0019                	.insn	2, 0x0019
 696:	2000                	.insn	2, 0x2000
 698:	0000000f          	fence	unknown,unknown
 69c:	2e21                	.insn	2, 0x2e21
 69e:	1101                	.insn	2, 0x1101
 6a0:	4006121b          	.insn	4, 0x4006121b
 6a4:	7a18                	.insn	2, 0x7a18
 6a6:	3119                	.insn	2, 0x3119
 6a8:	22000013          	li	zero,544
 6ac:	012e                	.insn	2, 0x012e
 6ae:	1b11                	.insn	2, 0x1b11
 6b0:	0612                	.insn	2, 0x0612
 6b2:	1840                	.insn	2, 0x1840
 6b4:	197a                	.insn	2, 0x197a
 6b6:	0b3a2503          	lw	a0,179(s4)
 6ba:	19270b3b          	.insn	4, 0x19270b3b
 6be:	0000193f 02000523 	.insn	8, 0x020005230000193f
 6c6:	3118                	.insn	2, 0x3118
 6c8:	24000013          	li	zero,576
 6cc:	012e                	.insn	2, 0x012e
 6ce:	0b3a2503          	lw	a0,179(s4)
 6d2:	19270b3b          	.insn	4, 0x19270b3b
 6d6:	1349                	.insn	2, 0x1349
 6d8:	2120                	.insn	2, 0x2120
 6da:	0001                	.insn	2, 0x0001
 6dc:	2500                	.insn	2, 0x2500
 6de:	0034                	.insn	2, 0x0034
 6e0:	0b3a2503          	lw	a0,179(s4)
 6e4:	1349053b          	.insn	4, 0x1349053b
 6e8:	0000                	.insn	2, 0x0000
 6ea:	2e26                	.insn	2, 0x2e26
 6ec:	1101                	.insn	2, 0x1101
 6ee:	4006121b          	.insn	4, 0x4006121b
 6f2:	7a18                	.insn	2, 0x7a18
 6f4:	0319                	.insn	2, 0x0319
 6f6:	3a25                	.insn	2, 0x3a25
 6f8:	27053b0b          	.insn	4, 0x27053b0b
 6fc:	4919                	.insn	2, 0x4919
 6fe:	00193f13          	seqz	t5,s2
 702:	2700                	.insn	2, 0x2700
 704:	0005                	.insn	2, 0x0005
 706:	2202                	.insn	2, 0x2202
 708:	0b3a2503          	lw	a0,179(s4)
 70c:	1349053b          	.insn	4, 0x1349053b
 710:	0000                	.insn	2, 0x0000
 712:	3428                	.insn	2, 0x3428
 714:	0200                	.insn	2, 0x0200
 716:	0318                	.insn	2, 0x0318
 718:	3a25                	.insn	2, 0x3a25
 71a:	49053b0b          	.insn	4, 0x49053b0b
 71e:	29000013          	li	zero,656
 722:	0034                	.insn	2, 0x0034
 724:	2202                	.insn	2, 0x2202
 726:	0b3a2503          	lw	a0,179(s4)
 72a:	1349053b          	.insn	4, 0x1349053b
 72e:	0000                	.insn	2, 0x0000
 730:	1d2a                	.insn	2, 0x1d2a
 732:	3101                	.insn	2, 0x3101
 734:	121b1113          	.insn	4, 0x121b1113
 738:	5806                	.insn	2, 0x5806
 73a:	5705590b          	.insn	4, 0x5705590b
 73e:	2b00000b          	.insn	4, 0x2b00000b
 742:	0034                	.insn	2, 0x0034
 744:	2202                	.insn	2, 0x2202
 746:	1331                	.insn	2, 0x1331
 748:	0000                	.insn	2, 0x0000
	...

Disassembly of section .debug_info:

00000000 <.debug_info>:
       0:	0792                	.insn	2, 0x0792
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
      1a:	e429                	.insn	2, 0xe429
      1c:	0009                	.insn	2, 0x0009
      1e:	0800                	.insn	2, 0x0800
      20:	0000                	.insn	2, 0x0000
      22:	0c00                	.insn	2, 0x0c00
      24:	0000                	.insn	2, 0x0000
      26:	0c00                	.insn	2, 0x0c00
      28:	0000                	.insn	2, 0x0000
      2a:	0200                	.insn	2, 0x0200
      2c:	02010723          	sb	zero,46(sp)
      30:	0722                	.insn	2, 0x0722
      32:	0304                	.insn	2, 0x0304
      34:	003d                	.insn	2, 0x003d
      36:	0000                	.insn	2, 0x0000
      38:	0f01                	.insn	2, 0x0f01
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
      56:	3a01                	.insn	2, 0x3a01
      58:	a102                	.insn	2, 0xa102
      5a:	0401                	.insn	2, 0x0401
      5c:	0049                	.insn	2, 0x0049
      5e:	0000                	.insn	2, 0x0000
      60:	4d05                	.insn	2, 0x4d05
      62:	0000                	.insn	2, 0x0000
      64:	0d00                	.insn	2, 0x0d00
      66:	0300                	.insn	2, 0x0300
      68:	0000005b          	.insn	4, 0x005b
      6c:	3f01                	.insn	2, 0x3f01
      6e:	a102                	.insn	2, 0xa102
      70:	0302                	.insn	2, 0x0302
      72:	0000007b          	.insn	4, 0x007b
      76:	9001                	.insn	2, 0x9001
      78:	a102                	.insn	2, 0xa102
      7a:	00490403          	lb	s0,4(s2)
      7e:	0000                	.insn	2, 0x0000
      80:	4d05                	.insn	2, 0x4d05
      82:	0000                	.insn	2, 0x0000
      84:	0600                	.insn	2, 0x0600
      86:	0300                	.insn	2, 0x0300
      88:	0091                	.insn	2, 0x0091
      8a:	0000                	.insn	2, 0x0000
      8c:	9101                	.insn	2, 0x9101
      8e:	a102                	.insn	2, 0xa102
      90:	0404                	.insn	2, 0x0404
      92:	0049                	.insn	2, 0x0049
      94:	0000                	.insn	2, 0x0000
      96:	4d05                	.insn	2, 0x4d05
      98:	0000                	.insn	2, 0x0000
      9a:	1900                	.insn	2, 0x1900
      9c:	0300                	.insn	2, 0x0300
      9e:	000000a7          	.insn	4, 0x00a7
      a2:	9401                	.insn	2, 0x9401
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
      b8:	b101                	.insn	2, 0xb101
      ba:	a102                	.insn	2, 0xa102
      bc:	0406                	.insn	2, 0x0406
      be:	0049                	.insn	2, 0x0049
      c0:	0000                	.insn	2, 0x0000
      c2:	4d05                	.insn	2, 0x4d05
      c4:	0000                	.insn	2, 0x0000
      c6:	0700                	.insn	2, 0x0700
      c8:	0300                	.insn	2, 0x0300
      ca:	000000d3          	.insn	4, 0x00d3
      ce:	b601                	.insn	2, 0xb601
      d0:	a102                	.insn	2, 0xa102
      d2:	00490407          	.insn	4, 0x00490407
      d6:	0000                	.insn	2, 0x0000
      d8:	4d05                	.insn	2, 0x4d05
      da:	0000                	.insn	2, 0x0000
      dc:	1a00                	.insn	2, 0x1a00
      de:	0300                	.insn	2, 0x0300
      e0:	00e9                	.insn	2, 0x00e9
      e2:	0000                	.insn	2, 0x0000
      e4:	bd01                	.insn	2, 0xbd01
      e6:	a102                	.insn	2, 0xa102
      e8:	0408                	.insn	2, 0x0408
      ea:	0049                	.insn	2, 0x0049
      ec:	0000                	.insn	2, 0x0000
      ee:	4d05                	.insn	2, 0x4d05
      f0:	0000                	.insn	2, 0x0000
      f2:	0a00                	.insn	2, 0x0a00
      f4:	0300                	.insn	2, 0x0300
      f6:	00ff 0000 c201 a102 	.insn	10, 0x0409a102c201000000ff
      fe:	0409 
     100:	0049                	.insn	2, 0x0049
     102:	0000                	.insn	2, 0x0000
     104:	4d05                	.insn	2, 0x4d05
     106:	0000                	.insn	2, 0x0000
     108:	0900                	.insn	2, 0x0900
     10a:	0300                	.insn	2, 0x0300
     10c:	0115                	.insn	2, 0x0115
     10e:	0000                	.insn	2, 0x0000
     110:	c701                	.insn	2, 0xc701
     112:	a102                	.insn	2, 0xa102
     114:	040a                	.insn	2, 0x040a
     116:	0049                	.insn	2, 0x0049
     118:	0000                	.insn	2, 0x0000
     11a:	4d05                	.insn	2, 0x4d05
     11c:	0000                	.insn	2, 0x0000
     11e:	1100                	.insn	2, 0x1100
     120:	0300                	.insn	2, 0x0300
     122:	00ff 0000 cf01 a102 	.insn	10, 0x030ba102cf01000000ff
     12a:	030b 
     12c:	0091                	.insn	2, 0x0091
     12e:	0000                	.insn	2, 0x0000
     130:	d101                	.insn	2, 0xd101
     132:	a102                	.insn	2, 0xa102
     134:	030c                	.insn	2, 0x030c
     136:	00e9                	.insn	2, 0x00e9
     138:	0000                	.insn	2, 0x0000
     13a:	d901                	.insn	2, 0xd901
     13c:	a102                	.insn	2, 0xa102
     13e:	030d                	.insn	2, 0x030d
     140:	000000d3          	.insn	4, 0x00d3
     144:	db01                	.insn	2, 0xdb01
     146:	a102                	.insn	2, 0xa102
     148:	030e                	.insn	2, 0x030e
     14a:	00000153          	.insn	4, 0x0153
     14e:	e401                	.insn	2, 0xe401
     150:	a102                	.insn	2, 0xa102
     152:	0049040f          	.insn	4, 0x0049040f
     156:	0000                	.insn	2, 0x0000
     158:	4d05                	.insn	2, 0x4d05
     15a:	0000                	.insn	2, 0x0000
     15c:	0800                	.insn	2, 0x0800
     15e:	0300                	.insn	2, 0x0300
     160:	0091                	.insn	2, 0x0091
     162:	0000                	.insn	2, 0x0000
     164:	e601                	.insn	2, 0xe601
     166:	a102                	.insn	2, 0xa102
     168:	0310                	.insn	2, 0x0310
     16a:	00ff 0000 ee01 a102 	.insn	10, 0x0311a102ee01000000ff
     172:	0311 
     174:	000000d3          	.insn	4, 0x00d3
     178:	f001                	.insn	2, 0xf001
     17a:	a102                	.insn	2, 0xa102
     17c:	0312                	.insn	2, 0x0312
     17e:	00000187          	.insn	4, 0x0187
     182:	f601                	.insn	2, 0xf601
     184:	a102                	.insn	2, 0xa102
     186:	00490413          	addi	s0,s2,4
     18a:	0000                	.insn	2, 0x0000
     18c:	4d05                	.insn	2, 0x4d05
     18e:	0000                	.insn	2, 0x0000
     190:	1f00                	.insn	2, 0x1f00
     192:	0300                	.insn	2, 0x0300
     194:	019d                	.insn	2, 0x019d
     196:	0000                	.insn	2, 0x0000
     198:	fc01                	.insn	2, 0xfc01
     19a:	a102                	.insn	2, 0xa102
     19c:	0414                	.insn	2, 0x0414
     19e:	0049                	.insn	2, 0x0049
     1a0:	0000                	.insn	2, 0x0000
     1a2:	4d05                	.insn	2, 0x4d05
     1a4:	0000                	.insn	2, 0x0000
     1a6:	0b00                	.insn	2, 0x0b00
     1a8:	0300                	.insn	2, 0x0300
     1aa:	000001b3          	add	gp,zero,zero
     1ae:	ff01                	.insn	2, 0xff01
     1b0:	a102                	.insn	2, 0xa102
     1b2:	0415                	.insn	2, 0x0415
     1b4:	0049                	.insn	2, 0x0049
     1b6:	0000                	.insn	2, 0x0000
     1b8:	4d05                	.insn	2, 0x4d05
     1ba:	0000                	.insn	2, 0x0000
     1bc:	1400                	.insn	2, 0x1400
     1be:	0700                	.insn	2, 0x0700
     1c0:	0000005b          	.insn	4, 0x005b
     1c4:	0301                	.insn	2, 0x0301
     1c6:	0201                	.insn	2, 0x0201
     1c8:	16a1                	.insn	2, 0x16a1
     1ca:	00011507          	.insn	4, 0x00011507
     1ce:	0100                	.insn	2, 0x0100
     1d0:	0104                	.insn	2, 0x0104
     1d2:	a102                	.insn	2, 0xa102
     1d4:	01530717          	auipc	a4,0x1530
     1d8:	0000                	.insn	2, 0x0000
     1da:	0501                	.insn	2, 0x0501
     1dc:	0201                	.insn	2, 0x0201
     1de:	18a1                	.insn	2, 0x18a1
     1e0:	00003d07          	.insn	4, 0x3d07
     1e4:	0100                	.insn	2, 0x0100
     1e6:	0106                	.insn	2, 0x0106
     1e8:	a102                	.insn	2, 0xa102
     1ea:	0719                	.insn	2, 0x0719
     1ec:	01f6                	.insn	2, 0x01f6
     1ee:	0000                	.insn	2, 0x0000
     1f0:	0701                	.insn	2, 0x0701
     1f2:	0201                	.insn	2, 0x0201
     1f4:	1aa1                	.insn	2, 0x1aa1
     1f6:	4904                	.insn	2, 0x4904
     1f8:	0000                	.insn	2, 0x0000
     1fa:	0500                	.insn	2, 0x0500
     1fc:	004d                	.insn	2, 0x004d
     1fe:	0000                	.insn	2, 0x0000
     200:	ff07000f          	.insn	4, 0xff07000f
     204:	0000                	.insn	2, 0x0000
     206:	0100                	.insn	2, 0x0100
     208:	010a                	.insn	2, 0x010a
     20a:	a102                	.insn	2, 0xa102
     20c:	00e9071b          	.insn	4, 0x00e9071b
     210:	0000                	.insn	2, 0x0000
     212:	0f01                	.insn	2, 0x0f01
     214:	0201                	.insn	2, 0x0201
     216:	1ca1                	.insn	2, 0x1ca1
     218:	00009107          	.insn	4, 0x9107
     21c:	0100                	.insn	2, 0x0100
     21e:	0112                	.insn	2, 0x0112
     220:	a102                	.insn	2, 0xa102
     222:	071d                	.insn	2, 0x071d
     224:	022e                	.insn	2, 0x022e
     226:	0000                	.insn	2, 0x0000
     228:	1901                	.insn	2, 0x1901
     22a:	0201                	.insn	2, 0x0201
     22c:	1ea1                	.insn	2, 0x1ea1
     22e:	4904                	.insn	2, 0x4904
     230:	0000                	.insn	2, 0x0000
     232:	0500                	.insn	2, 0x0500
     234:	004d                	.insn	2, 0x004d
     236:	0000                	.insn	2, 0x0000
     238:	000c                	.insn	2, 0x000c
     23a:	00024507          	.insn	4, 0x00024507
     23e:	0100                	.insn	2, 0x0100
     240:	011c                	.insn	2, 0x011c
     242:	a102                	.insn	2, 0xa102
     244:	041f 0049 0000      	.insn	6, 0x0049041f
     24a:	4d05                	.insn	2, 0x4d05
     24c:	0000                	.insn	2, 0x0000
     24e:	1b00                	.insn	2, 0x1b00
     250:	0700                	.insn	2, 0x0700
     252:	000001b3          	add	gp,zero,zero
     256:	2101                	.insn	2, 0x2101
     258:	0201                	.insn	2, 0x0201
     25a:	20a1                	.insn	2, 0x20a1
     25c:	0000a707          	.insn	4, 0xa707
     260:	0100                	.insn	2, 0x0100
     262:	0125                	.insn	2, 0x0125
     264:	a102                	.insn	2, 0xa102
     266:	0721                	.insn	2, 0x0721
     268:	019d                	.insn	2, 0x019d
     26a:	0000                	.insn	2, 0x0000
     26c:	2601                	.insn	2, 0x2601
     26e:	0201                	.insn	2, 0x0201
     270:	22a1                	.insn	2, 0x22a1
     272:	0000a707          	.insn	4, 0xa707
     276:	0100                	.insn	2, 0x0100
     278:	0130                	.insn	2, 0x0130
     27a:	a102                	.insn	2, 0xa102
     27c:	00a70723          	sb	a0,14(a4) # 15301e2 <USER_MAX+0x10301e2>
     280:	0000                	.insn	2, 0x0000
     282:	3101                	.insn	2, 0x3101
     284:	0201                	.insn	2, 0x0201
     286:	24a1                	.insn	2, 0x24a1
     288:	00029307          	.insn	4, 0x00029307
     28c:	0100                	.insn	2, 0x0100
     28e:	0132                	.insn	2, 0x0132
     290:	a102                	.insn	2, 0xa102
     292:	0425                	.insn	2, 0x0425
     294:	0049                	.insn	2, 0x0049
     296:	0000                	.insn	2, 0x0000
     298:	4d05                	.insn	2, 0x4d05
     29a:	0000                	.insn	2, 0x0000
     29c:	0200                	.insn	2, 0x0200
     29e:	0700                	.insn	2, 0x0700
     2a0:	02aa                	.insn	2, 0x02aa
     2a2:	0000                	.insn	2, 0x0000
     2a4:	3601                	.insn	2, 0x3601
     2a6:	0201                	.insn	2, 0x0201
     2a8:	26a1                	.insn	2, 0x26a1
     2aa:	4904                	.insn	2, 0x4904
     2ac:	0000                	.insn	2, 0x0000
     2ae:	0500                	.insn	2, 0x0500
     2b0:	004d                	.insn	2, 0x004d
     2b2:	0000                	.insn	2, 0x0000
     2b4:	0015                	.insn	2, 0x0015
     2b6:	0002c107          	.insn	4, 0x0002c107
     2ba:	0100                	.insn	2, 0x0100
     2bc:	0141                	.insn	2, 0x0141
     2be:	a102                	.insn	2, 0xa102
     2c0:	00490427          	.insn	4, 0x00490427
     2c4:	0000                	.insn	2, 0x0000
     2c6:	4d05                	.insn	2, 0x4d05
     2c8:	0000                	.insn	2, 0x0000
     2ca:	0400                	.insn	2, 0x0400
     2cc:	0700                	.insn	2, 0x0700
     2ce:	000000d3          	.insn	4, 0x00d3
     2d2:	4a01                	.insn	2, 0x4a01
     2d4:	0201                	.insn	2, 0x0201
     2d6:	28a1                	.insn	2, 0x28a1
     2d8:	0502                	.insn	2, 0x0502
     2da:	0405                	.insn	2, 0x0405
     2dc:	e408                	.insn	2, 0xe408
     2de:	0002                	.insn	2, 0x0002
     2e0:	0700                	.insn	2, 0x0700
     2e2:	1102                	.insn	2, 0x1102
     2e4:	0602                	.insn	2, 0x0602
     2e6:	08090407          	.insn	4, 0x08090407
     2ea:	4e01                	.insn	2, 0x4e01
     2ec:	d801                	.insn	2, 0xd801
     2ee:	0002                	.insn	2, 0x0002
     2f0:	0a00                	.insn	2, 0x0a00
     2f2:	0109                	.insn	2, 0x0109
     2f4:	014e                	.insn	2, 0x014e
     2f6:	0321                	.insn	2, 0x0321
     2f8:	0000                	.insn	2, 0x0000
     2fa:	0a0a                	.insn	2, 0x0a0a
     2fc:	4e01                	.insn	2, 0x4e01
     2fe:	2b01                	.insn	2, 0x2b01
     300:	0b000003          	lb	zero,176(zero) # b0 <start-0x3fff50>
     304:	010c                	.insn	2, 0x010c
     306:	0330014f          	.insn	4, 0x0330014f
     30a:	0000                	.insn	2, 0x0000
     30c:	0b0c                	.insn	2, 0x0b0c
     30e:	010d                	.insn	2, 0x010d
     310:	0159                	.insn	2, 0x0159
     312:	0049                	.insn	2, 0x0049
     314:	0000                	.insn	2, 0x0000
     316:	5a010e0b          	.insn	4, 0x5a010e0b
     31a:	dc01                	.insn	2, 0xdc01
     31c:	0002                	.insn	2, 0x0002
     31e:	0000                	.insn	2, 0x0000
     320:	0d00                	.insn	2, 0x0d00
     322:	0326                	.insn	2, 0x0326
     324:	0000                	.insn	2, 0x0000
     326:	490e                	.insn	2, 0x490e
     328:	0000                	.insn	2, 0x0000
     32a:	0d00                	.insn	2, 0x0d00
     32c:	0330                	.insn	2, 0x0330
     32e:	0000                	.insn	2, 0x0000
     330:	dc08                	.insn	2, 0xdc08
     332:	0002                	.insn	2, 0x0002
     334:	0b00                	.insn	2, 0x0b00
     336:	1402                	.insn	2, 0x1402
     338:	0864290f          	.insn	4, 0x0864290f
     33c:	0000                	.insn	2, 0x0000
     33e:	5201                	.insn	2, 0x5201
     340:	0124                	.insn	2, 0x0124
     342:	1005                	.insn	2, 0x1005
     344:	2800                	.insn	2, 0x2800
     346:	1401                	.insn	2, 0x1401
     348:	02dc                	.insn	2, 0x02dc
     34a:	0000                	.insn	2, 0x0000
     34c:	2a11                	.insn	2, 0x2a11
     34e:	07dc                	.insn	2, 0x07dc
     350:	0000                	.insn	2, 0x0000
     352:	0212                	.insn	2, 0x0212
     354:	2c91                	.insn	2, 0x2c91
     356:	0126                	.insn	2, 0x0126
     358:	7829                	.insn	2, 0x7829
     35a:	12000007          	.insn	4, 0x12000007
     35e:	9102                	.insn	2, 0x9102
     360:	270c                	.insn	2, 0x270c
     362:	7c01                	.insn	2, 0x7c01
     364:	0784                	.insn	2, 0x0784
     366:	0000                	.insn	2, 0x0000
     368:	0110                	.insn	2, 0x0110
     36a:	0129                	.insn	2, 0x0129
     36c:	d87d                	.insn	2, 0xd87d
     36e:	0002                	.insn	2, 0x0002
     370:	1000                	.insn	2, 0x1000
     372:	2a02                	.insn	2, 0x2a02
     374:	2a01                	.insn	2, 0x2a01
     376:	02d8                	.insn	2, 0x02d8
     378:	0000                	.insn	2, 0x0000
     37a:	0610                	.insn	2, 0x0610
     37c:	012e                	.insn	2, 0x012e
     37e:	9080                	.insn	2, 0x9080
     380:	13000007          	.insn	4, 0x13000007
     384:	0134                	.insn	2, 0x0134
     386:	0118                	.insn	2, 0x0118
     388:	342b117f 10000000 	.insn	12, 0xf401331610000000342b117f
     390:	f4013316 
     394:	02e4                	.insn	2, 0x02e4
     396:	0000                	.insn	2, 0x0000
     398:	1100                	.insn	2, 0x1100
     39a:	182c                	.insn	2, 0x182c
     39c:	0000                	.insn	2, 0x0000
     39e:	1000                	.insn	2, 0x1000
     3a0:	ea013313          	sltiu	t1,sp,-352
     3a4:	02e4                	.insn	2, 0x02e4
     3a6:	0000                	.insn	2, 0x0000
     3a8:	1100                	.insn	2, 0x1100
     3aa:	182d                	.insn	2, 0x182d
     3ac:	0000                	.insn	2, 0x0000
     3ae:	1000                	.insn	2, 0x1000
     3b0:	3212                	.insn	2, 0x3212
     3b2:	df01                	.insn	2, 0xdf01
     3b4:	02e4                	.insn	2, 0x02e4
     3b6:	0000                	.insn	2, 0x0000
     3b8:	1100                	.insn	2, 0x1100
     3ba:	182e                	.insn	2, 0x182e
     3bc:	0000                	.insn	2, 0x0000
     3be:	1000                	.insn	2, 0x1000
     3c0:	d501320f          	.insn	4, 0xd501320f
     3c4:	02e4                	.insn	2, 0x02e4
     3c6:	0000                	.insn	2, 0x0000
     3c8:	1400                	.insn	2, 0x1400
     3ca:	1000                	.insn	2, 0x1000
     3cc:	310e                	.insn	2, 0x310e
     3ce:	c301                	.insn	2, 0xc301
     3d0:	02dc                	.insn	2, 0x02dc
     3d2:	0000                	.insn	2, 0x0000
     3d4:	1400                	.insn	2, 0x1400
     3d6:	1001                	.insn	2, 0x1001
     3d8:	b201300b          	.insn	4, 0xb201300b
     3dc:	02e4                	.insn	2, 0x02e4
     3de:	0000                	.insn	2, 0x0000
     3e0:	1400                	.insn	2, 0x1400
     3e2:	1002                	.insn	2, 0x1002
     3e4:	96012f07          	.insn	4, 0x96012f07
     3e8:	02dc                	.insn	2, 0x02dc
     3ea:	0000                	.insn	2, 0x0000
     3ec:	0810                	.insn	2, 0x0810
     3ee:	012a                	.insn	2, 0x012a
     3f0:	0002dc97          	auipc	s9,0x2d
     3f4:	1500                	.insn	2, 0x1500
     3f6:	0136                	.insn	2, 0x0136
     3f8:	3098                	.insn	2, 0x3098
     3fa:	16000003          	lb	zero,352(zero) # 160 <start-0x3ffea0>
     3fe:	02e8                	.insn	2, 0x02e8
     400:	0000                	.insn	2, 0x0000
     402:	159b0103          	lb	sp,345(s6)
     406:	02f10917          	auipc	s2,0x2f10
     40a:	0000                	.insn	2, 0x0000
     40c:	0a18                	.insn	2, 0x0a18
     40e:	00000303          	lb	t1,0(zero) # 0 <start-0x400000>
     412:	0419                	.insn	2, 0x0419
     414:	030c                	.insn	2, 0x030c
     416:	0000                	.insn	2, 0x0000
     418:	1018                	.insn	2, 0x1018
     41a:	030d                	.insn	2, 0x030d
     41c:	0000                	.insn	2, 0x0000
     41e:	1118                	.insn	2, 0x1118
     420:	0316                	.insn	2, 0x0316
     422:	0000                	.insn	2, 0x0000
     424:	0000                	.insn	2, 0x0000
     426:	e816                	.insn	2, 0xe816
     428:	0002                	.insn	2, 0x0002
     42a:	0500                	.insn	2, 0x0500
     42c:	a101                	.insn	2, 0xa101
     42e:	1715                	.insn	2, 0x1715
     430:	f10c                	.insn	2, 0xf10c
     432:	0002                	.insn	2, 0x0002
     434:	1800                	.insn	2, 0x1800
     436:	030d                	.insn	2, 0x030d
     438:	19000003          	lb	zero,400(zero) # 190 <start-0x3ffe70>
     43c:	0c06                	.insn	2, 0x0c06
     43e:	18000003          	lb	zero,384(zero) # 180 <start-0x3ffe80>
     442:	0d14                	.insn	2, 0x0d14
     444:	18000003          	lb	zero,384(zero) # 180 <start-0x3ffe80>
     448:	1615                	.insn	2, 0x1615
     44a:	00000003          	lb	zero,0(zero) # 0 <start-0x400000>
     44e:	0000                	.insn	2, 0x0000
     450:	0714                	.insn	2, 0x0714
     452:	0310                	.insn	2, 0x0310
     454:	d848012b          	.insn	4, 0xd848012b
     458:	0002                	.insn	2, 0x0002
     45a:	1000                	.insn	2, 0x1000
     45c:	2c04                	.insn	2, 0x2c04
     45e:	3401                	.insn	2, 0x3401
     460:	02dc                	.insn	2, 0x02dc
     462:	0000                	.insn	2, 0x0000
     464:	0510                	.insn	2, 0x0510
     466:	012d                	.insn	2, 0x012d
     468:	00077037          	lui	zero,0x77
     46c:	1500                	.insn	2, 0x1500
     46e:	0135                	.insn	2, 0x0135
     470:	7036                	.insn	2, 0x7036
     472:	00000007          	.insn	4, 0x0007
     476:	1a00                	.insn	2, 0x1a00
     478:	0628                	.insn	2, 0x0628
     47a:	0000                	.insn	2, 0x0000
     47c:	06281a2f          	.insn	4, 0x06281a2f
     480:	0000                	.insn	2, 0x0000
     482:	1a30                	.insn	2, 0x1a30
     484:	00000633          	add	a2,zero,zero
     488:	1a31                	.insn	2, 0x1a31
     48a:	00000633          	add	a2,zero,zero
     48e:	1a32                	.insn	2, 0x1a32
     490:	00000633          	add	a2,zero,zero
     494:	06331a33          	.insn	4, 0x06331a33
     498:	0000                	.insn	2, 0x0000
     49a:	1a34                	.insn	2, 0x1a34
     49c:	00000633          	add	a2,zero,zero
     4a0:	1a35                	.insn	2, 0x1a35
     4a2:	00000633          	add	a2,zero,zero
     4a6:	1a36                	.insn	2, 0x1a36
     4a8:	00000633          	add	a2,zero,zero
     4ac:	06331a37          	lui	s4,0x6331
     4b0:	0000                	.insn	2, 0x0000
     4b2:	1a38                	.insn	2, 0x1a38
     4b4:	00000633          	add	a2,zero,zero
     4b8:	1a39                	.insn	2, 0x1a39
     4ba:	00000633          	add	a2,zero,zero
     4be:	1a3a                	.insn	2, 0x1a3a
     4c0:	00000633          	add	a2,zero,zero
     4c4:	06331a3b          	.insn	4, 0x06331a3b
     4c8:	0000                	.insn	2, 0x0000
     4ca:	1a3c                	.insn	2, 0x1a3c
     4cc:	00000633          	add	a2,zero,zero
     4d0:	1a3d                	.insn	2, 0x1a3d
     4d2:	00000633          	add	a2,zero,zero
     4d6:	1a3e                	.insn	2, 0x1a3e
     4d8:	00000633          	add	a2,zero,zero
     4dc:	06331a3f 1a400000 	.insn	8, 0x1a40000006331a3f
     4e4:	00000633          	add	a2,zero,zero
     4e8:	1a41                	.insn	2, 0x1a41
     4ea:	063d                	.insn	2, 0x063d
     4ec:	0000                	.insn	2, 0x0000
     4ee:	1a42                	.insn	2, 0x1a42
     4f0:	0628                	.insn	2, 0x0628
     4f2:	0000                	.insn	2, 0x0000
     4f4:	06281a43          	.insn	4, 0x06281a43
     4f8:	0000                	.insn	2, 0x0000
     4fa:	1a44                	.insn	2, 0x1a44
     4fc:	0645                	.insn	2, 0x0645
     4fe:	0000                	.insn	2, 0x0000
     500:	1a45                	.insn	2, 0x1a45
     502:	00000633          	add	a2,zero,zero
     506:	1a46                	.insn	2, 0x1a46
     508:	00000633          	add	a2,zero,zero
     50c:	06331a47          	.insn	4, 0x06331a47
     510:	0000                	.insn	2, 0x0000
     512:	1a48                	.insn	2, 0x1a48
     514:	064d                	.insn	2, 0x064d
     516:	0000                	.insn	2, 0x0000
     518:	1a49                	.insn	2, 0x1a49
     51a:	064d                	.insn	2, 0x064d
     51c:	0000                	.insn	2, 0x0000
     51e:	1a4a                	.insn	2, 0x1a4a
     520:	064d                	.insn	2, 0x064d
     522:	0000                	.insn	2, 0x0000
     524:	064d1a4b          	.insn	4, 0x064d1a4b
     528:	0000                	.insn	2, 0x0000
     52a:	1a4c                	.insn	2, 0x1a4c
     52c:	064d                	.insn	2, 0x064d
     52e:	0000                	.insn	2, 0x0000
     530:	1a4d                	.insn	2, 0x1a4d
     532:	064d                	.insn	2, 0x064d
     534:	0000                	.insn	2, 0x0000
     536:	1a4e                	.insn	2, 0x1a4e
     538:	064d                	.insn	2, 0x064d
     53a:	0000                	.insn	2, 0x0000
     53c:	064d1a4f          	.insn	4, 0x064d1a4f
     540:	0000                	.insn	2, 0x0000
     542:	1a50                	.insn	2, 0x1a50
     544:	064d                	.insn	2, 0x064d
     546:	0000                	.insn	2, 0x0000
     548:	1a51                	.insn	2, 0x1a51
     54a:	064d                	.insn	2, 0x064d
     54c:	0000                	.insn	2, 0x0000
     54e:	1a52                	.insn	2, 0x1a52
     550:	064d                	.insn	2, 0x064d
     552:	0000                	.insn	2, 0x0000
     554:	064d1a53          	.insn	4, 0x064d1a53
     558:	0000                	.insn	2, 0x0000
     55a:	1a54                	.insn	2, 0x1a54
     55c:	064d                	.insn	2, 0x064d
     55e:	0000                	.insn	2, 0x0000
     560:	1a55                	.insn	2, 0x1a55
     562:	064d                	.insn	2, 0x064d
     564:	0000                	.insn	2, 0x0000
     566:	1a56                	.insn	2, 0x1a56
     568:	064d                	.insn	2, 0x064d
     56a:	0000                	.insn	2, 0x0000
     56c:	064d1a57          	.insn	4, 0x064d1a57
     570:	0000                	.insn	2, 0x0000
     572:	1a58                	.insn	2, 0x1a58
     574:	064d                	.insn	2, 0x064d
     576:	0000                	.insn	2, 0x0000
     578:	1a59                	.insn	2, 0x1a59
     57a:	0628                	.insn	2, 0x0628
     57c:	0000                	.insn	2, 0x0000
     57e:	1a5a                	.insn	2, 0x1a5a
     580:	0660                	.insn	2, 0x0660
     582:	0000                	.insn	2, 0x0000
     584:	066e1a5b          	.insn	4, 0x066e1a5b
     588:	0000                	.insn	2, 0x0000
     58a:	1a5c                	.insn	2, 0x1a5c
     58c:	066e                	.insn	2, 0x066e
     58e:	0000                	.insn	2, 0x0000
     590:	1a5d                	.insn	2, 0x1a5d
     592:	0660                	.insn	2, 0x0660
     594:	0000                	.insn	2, 0x0000
     596:	1a5e                	.insn	2, 0x1a5e
     598:	067d                	.insn	2, 0x067d
     59a:	0000                	.insn	2, 0x0000
     59c:	1a5f 066e 0000      	.insn	6, 0x066e1a5f
     5a2:	1a60                	.insn	2, 0x1a60
     5a4:	0660                	.insn	2, 0x0660
     5a6:	0000                	.insn	2, 0x0000
     5a8:	1a61                	.insn	2, 0x1a61
     5aa:	06cd                	.insn	2, 0x06cd
     5ac:	0000                	.insn	2, 0x0000
     5ae:	1a62                	.insn	2, 0x1a62
     5b0:	0660                	.insn	2, 0x0660
     5b2:	0000                	.insn	2, 0x0000
     5b4:	06d71a63          	bne	a4,a3,628 <start-0x3ff9d8>
     5b8:	0000                	.insn	2, 0x0000
     5ba:	1a64                	.insn	2, 0x1a64
     5bc:	06e5                	.insn	2, 0x06e5
     5be:	0000                	.insn	2, 0x0000
     5c0:	1a65                	.insn	2, 0x1a65
     5c2:	0660                	.insn	2, 0x0660
     5c4:	0000                	.insn	2, 0x0000
     5c6:	1a66                	.insn	2, 0x1a66
     5c8:	000006ef          	jal	a3,5c8 <start-0x3ffa38>
     5cc:	06601a67          	.insn	4, 0x06601a67
     5d0:	0000                	.insn	2, 0x0000
     5d2:	1a68                	.insn	2, 0x1a68
     5d4:	06f9                	.insn	2, 0x06f9
     5d6:	0000                	.insn	2, 0x0000
     5d8:	1a69                	.insn	2, 0x1a69
     5da:	00000703          	lb	a4,0(zero) # 0 <start-0x400000>
     5de:	1a6a                	.insn	2, 0x1a6a
     5e0:	0628                	.insn	2, 0x0628
     5e2:	0000                	.insn	2, 0x0000
     5e4:	070b1a6b          	.insn	4, 0x070b1a6b
     5e8:	0000                	.insn	2, 0x0000
     5ea:	1a6c                	.insn	2, 0x1a6c
     5ec:	0000070f          	.insn	4, 0x070f
     5f0:	1a6d                	.insn	2, 0x1a6d
     5f2:	0628                	.insn	2, 0x0628
     5f4:	0000                	.insn	2, 0x0000
     5f6:	1a6e                	.insn	2, 0x1a6e
     5f8:	0628                	.insn	2, 0x0628
     5fa:	0000                	.insn	2, 0x0000
     5fc:	06281a6f          	jal	s4,8165e <start-0x37e9a2>
     600:	0000                	.insn	2, 0x0000
     602:	1a70                	.insn	2, 0x1a70
     604:	0628                	.insn	2, 0x0628
     606:	0000                	.insn	2, 0x0000
     608:	1a71                	.insn	2, 0x1a71
     60a:	0628                	.insn	2, 0x0628
     60c:	0000                	.insn	2, 0x0000
     60e:	1a72                	.insn	2, 0x1a72
     610:	071d                	.insn	2, 0x071d
     612:	0000                	.insn	2, 0x0000
     614:	06281a73          	csrrw	s4,0x62,a6
     618:	0000                	.insn	2, 0x0000
     61a:	1a74                	.insn	2, 0x1a74
     61c:	0628                	.insn	2, 0x0628
     61e:	0000                	.insn	2, 0x0000
     620:	1a75                	.insn	2, 0x1a75
     622:	0000072b          	.insn	4, 0x072b
     626:	0076                	.insn	2, 0x0076
     628:	4b020f1b          	.insn	4, 0x4b020f1b
     62c:	211c                	.insn	2, 0x211c
     62e:	1d000003          	lb	zero,464(zero) # 1d0 <start-0x3ffe30>
     632:	1b00                	.insn	2, 0x1b00
     634:	0210                	.insn	2, 0x0210
     636:	1c3a                	.insn	2, 0x1c3a
     638:	0049                	.insn	2, 0x0049
     63a:	0000                	.insn	2, 0x0000
     63c:	1e00                	.insn	2, 0x1e00
     63e:	0211                	.insn	2, 0x0211
     640:	dc4a                	.insn	2, 0xdc4a
     642:	0002                	.insn	2, 0x0002
     644:	1e00                	.insn	2, 0x1e00
     646:	0212                	.insn	2, 0x0212
     648:	d83c                	.insn	2, 0xd83c
     64a:	0002                	.insn	2, 0x0002
     64c:	1f00                	.insn	2, 0x1f00
     64e:	d8470213          	addi	tp,a4,-636
     652:	0002                	.insn	2, 0x0002
     654:	1c00                	.insn	2, 0x1c00
     656:	0321                	.insn	2, 0x0321
     658:	0000                	.insn	2, 0x0000
     65a:	211c                	.insn	2, 0x211c
     65c:	00000003          	lb	zero,0(zero) # 0 <start-0x400000>
     660:	141f 3902 02e4      	.insn	6, 0x02e43902141f
     666:	0000                	.insn	2, 0x0000
     668:	211c                	.insn	2, 0x211c
     66a:	00000003          	lb	zero,0(zero) # 0 <start-0x400000>
     66e:	3402151b          	.insn	4, 0x3402151b
     672:	dc1c                	.insn	2, 0xdc1c
     674:	0002                	.insn	2, 0x0002
     676:	1c00                	.insn	2, 0x1c00
     678:	02dc                	.insn	2, 0x02dc
     67a:	0000                	.insn	2, 0x0000
     67c:	2000                	.insn	2, 0x2000
     67e:	bc78                	.insn	2, 0xbc78
     680:	0000                	.insn	2, 0x0000
     682:	0100                	.insn	2, 0x0100
     684:	2552                	.insn	2, 0x2552
     686:	3c01                	.insn	2, 0x3c01
     688:	2101                	.insn	2, 0x2101
     68a:	3c01301b          	.insn	4, 0x3c01301b
     68e:	e401                	.insn	2, 0xe401
     690:	0002                	.insn	2, 0x0002
     692:	2200                	.insn	2, 0x2200
     694:	321c                	.insn	2, 0x321c
     696:	3e01                	.insn	2, 0x3e01
     698:	d801                	.insn	2, 0xd801
     69a:	0002                	.insn	2, 0x0002
     69c:	1100                	.insn	2, 0x1100
     69e:	5479                	.insn	2, 0x5479
     6a0:	0000                	.insn	2, 0x0000
     6a2:	2200                	.insn	2, 0x2200
     6a4:	371d                	.insn	2, 0x371d
     6a6:	3f01                	.insn	2, 0x3f01
     6a8:	e401                	.insn	2, 0xe401
     6aa:	0002                	.insn	2, 0x0002
     6ac:	0000                	.insn	2, 0x0000
     6ae:	621a                	.insn	2, 0x621a
     6b0:	7a000007          	.insn	4, 0x7a000007
     6b4:	281a                	.insn	2, 0x281a
     6b6:	0006                	.insn	2, 0x0006
     6b8:	7b00                	.insn	2, 0x7b00
     6ba:	331a                	.insn	2, 0x331a
     6bc:	0006                	.insn	2, 0x0006
     6be:	7c00                	.insn	2, 0x7c00
     6c0:	331a                	.insn	2, 0x331a
     6c2:	0006                	.insn	2, 0x0006
     6c4:	7d00                	.insn	2, 0x7d00
     6c6:	00062823          	sw	zero,16(a2)
     6ca:	7e00                	.insn	2, 0x7e00
     6cc:	1b00                	.insn	2, 0x1b00
     6ce:	0216                	.insn	2, 0x0216
     6d0:	02e41c2b          	.insn	4, 0x02e41c2b
     6d4:	0000                	.insn	2, 0x0000
     6d6:	1f00                	.insn	2, 0x1f00
     6d8:	dc2d0217          	auipc	tp,0xdc2d0
     6dc:	0002                	.insn	2, 0x0002
     6de:	1c00                	.insn	2, 0x1c00
     6e0:	02dc                	.insn	2, 0x02dc
     6e2:	0000                	.insn	2, 0x0000
     6e4:	1b00                	.insn	2, 0x1b00
     6e6:	0218                	.insn	2, 0x0218
     6e8:	1c29                	.insn	2, 0x1c29
     6ea:	02dc                	.insn	2, 0x02dc
     6ec:	0000                	.insn	2, 0x0000
     6ee:	1b00                	.insn	2, 0x1b00
     6f0:	0219                	.insn	2, 0x0219
     6f2:	02e41c2f          	.insn	4, 0x02e41c2f
     6f6:	0000                	.insn	2, 0x0000
     6f8:	1b00                	.insn	2, 0x1b00
     6fa:	021a                	.insn	2, 0x021a
     6fc:	1c30                	.insn	2, 0x1c30
     6fe:	02e4                	.insn	2, 0x02e4
     700:	0000                	.insn	2, 0x0000
     702:	1e00                	.insn	2, 0x1e00
     704:	d810031b          	.insn	4, 0xd810031b
     708:	0002                	.insn	2, 0x0002
     70a:	2400                	.insn	2, 0x2400
     70c:	031c                	.insn	2, 0x031c
     70e:	1f11                	.insn	2, 0x1f11
     710:	031d                	.insn	2, 0x031d
     712:	d80e                	.insn	2, 0xd80e
     714:	0002                	.insn	2, 0x0002
     716:	1c00                	.insn	2, 0x1c00
     718:	0321                	.insn	2, 0x0321
     71a:	0000                	.insn	2, 0x0000
     71c:	1f00                	.insn	2, 0x1f00
     71e:	031e                	.insn	2, 0x031e
     720:	d812                	.insn	2, 0xd812
     722:	0002                	.insn	2, 0x0002
     724:	1c00                	.insn	2, 0x1c00
     726:	0321                	.insn	2, 0x0321
     728:	0000                	.insn	2, 0x0000
     72a:	2500                	.insn	2, 0x2500
     72c:	021f 264c c477      	.insn	6, 0xc477264c021f
     732:	0000                	.insn	2, 0x0000
     734:	0100                	.insn	2, 0x0100
     736:	e852                	.insn	2, 0xe852
     738:	0002                	.insn	2, 0x0002
     73a:	1700                	.insn	2, 0x1700
     73c:	0002f117          	auipc	sp,0x2f
     740:	2700                	.insn	2, 0x2700
     742:	5b01                	.insn	2, 0x5b01
     744:	02fa                	.insn	2, 0x02fa
     746:	0000                	.insn	2, 0x0000
     748:	1818                	.insn	2, 0x1818
     74a:	00000303          	lb	t1,0(zero) # 0 <start-0x400000>
     74e:	0819                	.insn	2, 0x0819
     750:	030c                	.insn	2, 0x030c
     752:	0000                	.insn	2, 0x0000
     754:	1918                	.insn	2, 0x1918
     756:	030d                	.insn	2, 0x030d
     758:	0000                	.insn	2, 0x0000
     75a:	1a18                	.insn	2, 0x1a18
     75c:	0316                	.insn	2, 0x0316
     75e:	0000                	.insn	2, 0x0000
     760:	0000                	.insn	2, 0x0000
     762:	201f 3802 0770      	.insn	6, 0x07703802201f
     768:	0000                	.insn	2, 0x0000
     76a:	e41c                	.insn	2, 0xe41c
     76c:	0002                	.insn	2, 0x0002
     76e:	0000                	.insn	2, 0x0000
     770:	d808                	.insn	2, 0xd808
     772:	0002                	.insn	2, 0x0002
     774:	2100                	.insn	2, 0x2100
     776:	0e02                	.insn	2, 0x0e02
     778:	4904                	.insn	2, 0x4904
     77a:	0000                	.insn	2, 0x0000
     77c:	0500                	.insn	2, 0x0500
     77e:	004d                	.insn	2, 0x004d
     780:	0000                	.insn	2, 0x0000
     782:	0020                	.insn	2, 0x0020
     784:	2104                	.insn	2, 0x2104
     786:	05000003          	lb	zero,80(zero) # 50 <start-0x3fffb0>
     78a:	004d                	.insn	2, 0x004d
     78c:	0000                	.insn	2, 0x0000
     78e:	0008                	.insn	2, 0x0008
     790:	490d                	.insn	2, 0x490d
     792:	0000                	.insn	2, 0x0000
     794:	0000                	.insn	2, 0x0000
     796:	0a9a                	.insn	2, 0x0a9a
     798:	0000                	.insn	2, 0x0000
     79a:	0005                	.insn	2, 0x0005
     79c:	0401                	.insn	2, 0x0401
     79e:	0201                	.insn	2, 0x0201
     7a0:	0000                	.insn	2, 0x0000
     7a2:	0001                	.insn	2, 0x0001
     7a4:	001d                	.insn	2, 0x001d
     7a6:	f001                	.insn	2, 0xf001
     7a8:	0000                	.insn	2, 0x0000
     7aa:	e200                	.insn	2, 0xe200
     7ac:	0006                	.insn	2, 0x0006
     7ae:	0200                	.insn	2, 0x0200
     7b0:	0000                	.insn	2, 0x0000
     7b2:	0000                	.insn	2, 0x0000
     7b4:	1009                	.insn	2, 0x1009
     7b6:	0002                	.insn	2, 0x0002
     7b8:	c700                	.insn	2, 0xc700
     7ba:	0000                	.insn	2, 0x0000
     7bc:	c700                	.insn	2, 0xc700
     7be:	02000003          	lb	zero,32(zero) # 20 <start-0x3fffe0>
     7c2:	0035                	.insn	2, 0x0035
     7c4:	0000                	.insn	2, 0x0000
     7c6:	ee01                	.insn	2, 0xee01
     7c8:	a102                	.insn	2, 0xa102
     7ca:	0300                	.insn	2, 0x0300
     7cc:	0041                	.insn	2, 0x0041
     7ce:	0000                	.insn	2, 0x0000
     7d0:	4504                	.insn	2, 0x4504
     7d2:	0000                	.insn	2, 0x0000
     7d4:	0800                	.insn	2, 0x0800
     7d6:	0500                	.insn	2, 0x0500
     7d8:	06010803          	lb	a6,96(sp) # 2f79c <start-0x3d0864>
     7dc:	0804                	.insn	2, 0x0804
     7de:	00530207          	.insn	4, 0x00530207
     7e2:	0000                	.insn	2, 0x0000
     7e4:	f201                	.insn	2, 0xf201
     7e6:	a102                	.insn	2, 0xa102
     7e8:	0301                	.insn	2, 0x0301
     7ea:	0041                	.insn	2, 0x0041
     7ec:	0000                	.insn	2, 0x0000
     7ee:	4504                	.insn	2, 0x4504
     7f0:	0000                	.insn	2, 0x0000
     7f2:	1300                	.insn	2, 0x1300
     7f4:	0200                	.insn	2, 0x0200
     7f6:	0069                	.insn	2, 0x0069
     7f8:	0000                	.insn	2, 0x0000
     7fa:	f701                	.insn	2, 0xf701
     7fc:	a102                	.insn	2, 0xa102
     7fe:	0302                	.insn	2, 0x0302
     800:	0041                	.insn	2, 0x0041
     802:	0000                	.insn	2, 0x0000
     804:	4504                	.insn	2, 0x4504
     806:	0000                	.insn	2, 0x0000
     808:	1800                	.insn	2, 0x1800
     80a:	0200                	.insn	2, 0x0200
     80c:	007f 0000 ff01 a102 	.insn	10, 0x0303a102ff010000007f
     814:	0303 
     816:	0041                	.insn	2, 0x0041
     818:	0000                	.insn	2, 0x0000
     81a:	4504                	.insn	2, 0x4504
     81c:	0000                	.insn	2, 0x0000
     81e:	1e00                	.insn	2, 0x1e00
     820:	0700                	.insn	2, 0x0700
     822:	0096                	.insn	2, 0x0096
     824:	0000                	.insn	2, 0x0000
     826:	9401                	.insn	2, 0x9401
     828:	0201                	.insn	2, 0x0201
     82a:	04a1                	.insn	2, 0x04a1
     82c:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
     830:	0400                	.insn	2, 0x0400
     832:	0045                	.insn	2, 0x0045
     834:	0000                	.insn	2, 0x0000
     836:	0011                	.insn	2, 0x0011
     838:	ab08                	.insn	2, 0xab08
     83a:	0000                	.insn	2, 0x0000
     83c:	0600                	.insn	2, 0x0600
     83e:	0e02                	.insn	2, 0x0e02
     840:	0501                	.insn	2, 0x0501
     842:	0805                	.insn	2, 0x0805
     844:	0901                	.insn	2, 0x0901
     846:	000000b7          	lui	ra,0x0
     84a:	0208                	.insn	2, 0x0208
     84c:	05ca                	.insn	2, 0x05ca
     84e:	05040707          	.insn	4, 0x05040707
     852:	0509                	.insn	2, 0x0509
     854:	0a04                	.insn	2, 0x0a04
     856:	000000ab          	.insn	4, 0x00ab
     85a:	3a010a0b          	.insn	4, 0x3a010a0b
     85e:	000000bb          	.insn	4, 0x00bb
     862:	0b0c                	.insn	2, 0x0b0c
     864:	3a01                	.insn	2, 0x3a01
     866:	000000bb          	.insn	4, 0x00bb
     86a:	0c0c                	.insn	2, 0x0c0c
     86c:	3a01                	.insn	2, 0x3a01
     86e:	000000bb          	.insn	4, 0x00bb
     872:	0d0c                	.insn	2, 0x0d0c
     874:	3a01                	.insn	2, 0x3a01
     876:	000000bb          	.insn	4, 0x00bb
     87a:	0e0c                	.insn	2, 0x0e0c
     87c:	3a01                	.insn	2, 0x3a01
     87e:	000000bb          	.insn	4, 0x00bb
     882:	0f0d                	.insn	2, 0x0f0d
     884:	3c01                	.insn	2, 0x3c01
     886:	000000bb          	.insn	4, 0x00bb
     88a:	100d                	.insn	2, 0x100d
     88c:	3d01                	.insn	2, 0x3d01
     88e:	000000bb          	.insn	4, 0x00bb
     892:	110d                	.insn	2, 0x110d
     894:	3e01                	.insn	2, 0x3e01
     896:	000000bb          	.insn	4, 0x00bb
     89a:	120d                	.insn	2, 0x120d
     89c:	3f01                	.insn	2, 0x3f01
     89e:	000000bb          	.insn	4, 0x00bb
     8a2:	0e00                	.insn	2, 0x0e00
     8a4:	1805                	.insn	2, 0x1805
     8a6:	0000                	.insn	2, 0x0000
     8a8:	0100                	.insn	2, 0x0100
     8aa:	2252                	.insn	2, 0x2252
     8ac:	4e01                	.insn	2, 0x4e01
     8ae:	0000c40f          	.insn	4, 0xc40f
     8b2:	0500                	.insn	2, 0x0500
     8b4:	0014                	.insn	2, 0x0014
     8b6:	0000                	.insn	2, 0x0000
     8b8:	5301                	.insn	2, 0x5301
     8ba:	1005                	.insn	2, 0x1005
     8bc:	00da                	.insn	2, 0x00da
     8be:	00cc                	.insn	2, 0x00cc
     8c0:	0000                	.insn	2, 0x0000
     8c2:	0010                	.insn	2, 0x0010
     8c4:	00d4                	.insn	2, 0x00d4
     8c6:	0000                	.insn	2, 0x0000
     8c8:	0010                	.insn	2, 0x0010
     8ca:	00dc                	.insn	2, 0x00dc
     8cc:	0000                	.insn	2, 0x0000
     8ce:	0010                	.insn	2, 0x0010
     8d0:	00e4                	.insn	2, 0x00e4
     8d2:	0000                	.insn	2, 0x0000
     8d4:	0011                	.insn	2, 0x0011
     8d6:	00ec                	.insn	2, 0x00ec
     8d8:	0000                	.insn	2, 0x0000
     8da:	0012                	.insn	2, 0x0012
     8dc:	00f4                	.insn	2, 0x00f4
     8de:	0000                	.insn	2, 0x0000
     8e0:	0012                	.insn	2, 0x0012
     8e2:	00fc                	.insn	2, 0x00fc
     8e4:	0000                	.insn	2, 0x0000
     8e6:	da12                	.insn	2, 0xda12
     8e8:	0400                	.insn	2, 0x0400
     8ea:	0001                	.insn	2, 0x0001
     8ec:	0000                	.insn	2, 0x0000
     8ee:	1300                	.insn	2, 0x1300
     8f0:	02390113          	addi	sp,s2,35 # 2f10429 <USER_MAX+0x2a10429>
     8f4:	0199                	.insn	2, 0x0199
     8f6:	0000                	.insn	2, 0x0000
     8f8:	1414                	.insn	2, 0x1414
     8fa:	3901                	.insn	2, 0x3901
     8fc:	af02                	.insn	2, 0xaf02
     8fe:	0000                	.insn	2, 0x0000
     900:	1400                	.insn	2, 0x1400
     902:	023a010f          	.insn	4, 0x023a010f
     906:	000000af          	.insn	4, 0x00af
     90a:	1014                	.insn	2, 0x1014
     90c:	3b01                	.insn	2, 0x3b01
     90e:	af02                	.insn	2, 0xaf02
     910:	0000                	.insn	2, 0x0000
     912:	1400                	.insn	2, 0x1400
     914:	0111                	.insn	2, 0x0111
     916:	023c                	.insn	2, 0x023c
     918:	000000af          	.insn	4, 0x00af
     91c:	1514                	.insn	2, 0x1514
     91e:	3d01                	.insn	2, 0x3d01
     920:	af02                	.insn	2, 0xaf02
     922:	0000                	.insn	2, 0x0000
     924:	1500                	.insn	2, 0x1500
     926:	0116                	.insn	2, 0x0116
     928:	00af023f 09000000 	.insn	8, 0x0900000000af023f
     930:	000000b7          	lui	ra,0x0
     934:	0308                	.insn	2, 0x0308
     936:	1611                	.insn	2, 0x1611
     938:	02010117          	auipc	sp,0x2010
     93c:	1814                	.insn	2, 0x1814
     93e:	0101                	.insn	2, 0x0101
     940:	4102                	.insn	2, 0x4102
     942:	0000                	.insn	2, 0x0000
     944:	0000                	.insn	2, 0x0000
     946:	1916                	.insn	2, 0x1916
     948:	2901                	.insn	2, 0x2901
     94a:	1402                	.insn	2, 0x1402
     94c:	011a                	.insn	2, 0x011a
     94e:	0229                	.insn	2, 0x0229
     950:	000000bb          	.insn	4, 0x00bb
     954:	1700                	.insn	2, 0x1700
     956:	2806                	.insn	2, 0x2806
     958:	01000003          	lb	zero,16(zero) # 10 <start-0x3ffff0>
     95c:	2352                	.insn	2, 0x2352
     95e:	7801                	.insn	2, 0x7801
     960:	0118                	.insn	2, 0x0118
     962:	0139                	.insn	2, 0x0139
     964:	af78                	.insn	2, 0xaf78
     966:	0000                	.insn	2, 0x0000
     968:	1900                	.insn	2, 0x1900
     96a:	9104                	.insn	2, 0x9104
     96c:	a090                	.insn	2, 0xa090
     96e:	3601                	.insn	2, 0x3601
     970:	8601                	.insn	2, 0x8601
     972:	0a5c                	.insn	2, 0x0a5c
     974:	0000                	.insn	2, 0x0000
     976:	0419                	.insn	2, 0x0419
     978:	9091                	.insn	2, 0x9091
     97a:	0180                	.insn	2, 0x0180
     97c:	5c870137          	lui	sp,0x5c870
     980:	000a                	.insn	2, 0x000a
     982:	1900                	.insn	2, 0x1900
     984:	9102                	.insn	2, 0x9102
     986:	3810                	.insn	2, 0x3810
     988:	8801                	.insn	2, 0x8801
     98a:	0a6e                	.insn	2, 0x0a6e
     98c:	0000                	.insn	2, 0x0000
     98e:	071a                	.insn	2, 0x071a
     990:	0088                	.insn	2, 0x0088
     992:	0000                	.insn	2, 0x0000
     994:	013a021b          	.insn	4, 0x013a021b
     998:	0000af8b          	.insn	4, 0xaf8b
     99c:	1a00                	.insn	2, 0x1a00
     99e:	4408                	.insn	2, 0x4408
     9a0:	0000                	.insn	2, 0x0000
     9a2:	1b00                	.insn	2, 0x1b00
     9a4:	8c013b03          	.insn	4, 0x8c013b03
     9a8:	000000af          	.insn	4, 0x00af
     9ac:	0000                	.insn	2, 0x0000
     9ae:	591c                	.insn	2, 0x591c
     9b0:	0001                	.insn	2, 0x0001
     9b2:	0000                	.insn	2, 0x0000
     9b4:	9901                	.insn	2, 0x9901
     9b6:	1d05                	.insn	2, 0x1d05
     9b8:	00016207          	.insn	4, 0x00016207
     9bc:	1d00                	.insn	2, 0x1d00
     9be:	6b04                	.insn	2, 0x6b04
     9c0:	0001                	.insn	2, 0x0001
     9c2:	1d00                	.insn	2, 0x1d00
     9c4:	7405                	.insn	2, 0x7405
     9c6:	0001                	.insn	2, 0x0001
     9c8:	1d00                	.insn	2, 0x1d00
     9ca:	7d06                	.insn	2, 0x7d06
     9cc:	0001                	.insn	2, 0x0001
     9ce:	1d00                	.insn	2, 0x1d00
     9d0:	8608                	.insn	2, 0x8608
     9d2:	0001                	.insn	2, 0x0001
     9d4:	0000                	.insn	2, 0x0000
     9d6:	a11c                	.insn	2, 0xa11c
     9d8:	0001                	.insn	2, 0x0001
     9da:	0100                	.insn	2, 0x0100
     9dc:	a201                	.insn	2, 0xa201
     9de:	1d05                	.insn	2, 0x1d05
     9e0:	a609                	.insn	2, 0xa609
     9e2:	0001                	.insn	2, 0x0001
     9e4:	0000                	.insn	2, 0x0000
     9e6:	a11c                	.insn	2, 0xa11c
     9e8:	0001                	.insn	2, 0x0001
     9ea:	0200                	.insn	2, 0x0200
     9ec:	a301                	.insn	2, 0xa301
     9ee:	1d05                	.insn	2, 0x1d05
     9f0:	a60a                	.insn	2, 0xa60a
     9f2:	0001                	.insn	2, 0x0001
     9f4:	0000                	.insn	2, 0x0000
     9f6:	091a                	.insn	2, 0x091a
     9f8:	0050                	.insn	2, 0x0050
     9fa:	0000                	.insn	2, 0x0000
     9fc:	013a0b1b          	.insn	4, 0x013a0b1b
     a00:	afa4                	.insn	2, 0xafa4
     a02:	0000                	.insn	2, 0x0000
     a04:	1a00                	.insn	2, 0x1a00
     a06:	3409                	.insn	2, 0x3409
     a08:	0000                	.insn	2, 0x0000
     a0a:	1b00                	.insn	2, 0x1b00
     a0c:	3b0c                	.insn	2, 0x3b0c
     a0e:	a501                	.insn	2, 0xa501
     a10:	000000af          	.insn	4, 0x00af
     a14:	0001b00f          	.insn	4, 0x0001b00f
     a18:	0a00                	.insn	2, 0x0a00
     a1a:	000c                	.insn	2, 0x000c
     a1c:	0000                	.insn	2, 0x0000
     a1e:	a601                	.insn	2, 0xa601
     a20:	1e0d                	.insn	2, 0x1e0d
     a22:	5701                	.insn	2, 0x5701
     a24:	01b5                	.insn	2, 0x01b5
     a26:	0000                	.insn	2, 0x0000
     a28:	0f00                	.insn	2, 0x0f00
     a2a:	01a1                	.insn	2, 0x01a1
     a2c:	0000                	.insn	2, 0x0000
     a2e:	00000c0b          	.insn	4, 0x0c0b
     a32:	0100                	.insn	2, 0x0100
     a34:	201f0da7          	.insn	4, 0x201f0da7
     a38:	01a6                	.insn	2, 0x01a6
     a3a:	0000                	.insn	2, 0x0000
     a3c:	0000                	.insn	2, 0x0000
     a3e:	0001a10f          	.insn	4, 0x0001a10f
     a42:	0c00                	.insn	2, 0x0c00
     a44:	000c                	.insn	2, 0x000c
     a46:	0000                	.insn	2, 0x0000
     a48:	a901                	.insn	2, 0xa901
     a4a:	1f09                	.insn	2, 0x1f09
     a4c:	a60a                	.insn	2, 0xa60a
     a4e:	0001                	.insn	2, 0x0001
     a50:	0000                	.insn	2, 0x0000
     a52:	0f00                	.insn	2, 0x0f00
     a54:	01a1                	.insn	2, 0x01a1
     a56:	0000                	.insn	2, 0x0000
     a58:	0c0d                	.insn	2, 0x0c0d
     a5a:	0000                	.insn	2, 0x0000
     a5c:	0100                	.insn	2, 0x0100
     a5e:	0a1f05ab          	.insn	4, 0x0a1f05ab
     a62:	01a6                	.insn	2, 0x01a6
     a64:	0000                	.insn	2, 0x0000
     a66:	0f00                	.insn	2, 0x0f00
     a68:	01a1                	.insn	2, 0x01a1
     a6a:	0000                	.insn	2, 0x0000
     a6c:	0c0e                	.insn	2, 0x0c0e
     a6e:	0000                	.insn	2, 0x0000
     a70:	0100                	.insn	2, 0x0100
     a72:	05ae                	.insn	2, 0x05ae
     a74:	421f 01a6 0000      	.insn	6, 0x01a6421f
     a7a:	0f00                	.insn	2, 0x0f00
     a7c:	01a1                	.insn	2, 0x01a1
     a7e:	0000                	.insn	2, 0x0000
     a80:	00000c0f          	.insn	4, 0x0c0f
     a84:	0100                	.insn	2, 0x0100
     a86:	0a1f05af          	.insn	4, 0x0a1f05af
     a8a:	01a6                	.insn	2, 0x01a6
     a8c:	0000                	.insn	2, 0x0000
     a8e:	1a00                	.insn	2, 0x1a00
     a90:	7410                	.insn	2, 0x7410
     a92:	0000                	.insn	2, 0x0000
     a94:	1b00                	.insn	2, 0x1b00
     a96:	3a0d                	.insn	2, 0x3a0d
     a98:	b001                	.insn	2, 0xb001
     a9a:	000000af          	.insn	4, 0x00af
     a9e:	111a                	.insn	2, 0x111a
     aa0:	0034                	.insn	2, 0x0034
     aa2:	0000                	.insn	2, 0x0000
     aa4:	013b0e1b          	.insn	4, 0x013b0e1b
     aa8:	afb1                	.insn	2, 0xafb1
     aaa:	0000                	.insn	2, 0x0000
     aac:	0f00                	.insn	2, 0x0f00
     aae:	01b0                	.insn	2, 0x01b0
     ab0:	0000                	.insn	2, 0x0000
     ab2:	0c12                	.insn	2, 0x0c12
     ab4:	0000                	.insn	2, 0x0000
     ab6:	0100                	.insn	2, 0x0100
     ab8:	0db2                	.insn	2, 0x0db2
     aba:	011e                	.insn	2, 0x011e
     abc:	0001b557          	.insn	4, 0x0001b557
     ac0:	0000                	.insn	2, 0x0000
     ac2:	0001a10f          	.insn	4, 0x0001a10f
     ac6:	1300                	.insn	2, 0x1300
     ac8:	000c                	.insn	2, 0x000c
     aca:	0000                	.insn	2, 0x0000
     acc:	b301                	.insn	2, 0xb301
     ace:	1f0d                	.insn	2, 0x1f0d
     ad0:	a620                	.insn	2, 0xa620
     ad2:	0001                	.insn	2, 0x0001
     ad4:	0000                	.insn	2, 0x0000
     ad6:	0f00                	.insn	2, 0x0f00
     ad8:	01a1                	.insn	2, 0x01a1
     ada:	0000                	.insn	2, 0x0000
     adc:	0c14                	.insn	2, 0x0c14
     ade:	0000                	.insn	2, 0x0000
     ae0:	0100                	.insn	2, 0x0100
     ae2:	09b5                	.insn	2, 0x09b5
     ae4:	0a1f 01a6 0000      	.insn	6, 0x01a60a1f
     aea:	0000                	.insn	2, 0x0000
     aec:	a11c                	.insn	2, 0xa11c
     aee:	0001                	.insn	2, 0x0001
     af0:	0300                	.insn	2, 0x0300
     af2:	b701                	.insn	2, 0xb701
     af4:	1d05                	.insn	2, 0x1d05
     af6:	0001a60f          	.insn	4, 0x0001a60f
     afa:	0000                	.insn	2, 0x0000
     afc:	a11c                	.insn	2, 0xa11c
     afe:	0001                	.insn	2, 0x0001
     b00:	0400                	.insn	2, 0x0400
     b02:	ba01                	.insn	2, 0xba01
     b04:	1d05                	.insn	2, 0x1d05
     b06:	a610                	.insn	2, 0xa610
     b08:	0001                	.insn	2, 0x0001
     b0a:	0000                	.insn	2, 0x0000
     b0c:	a11c                	.insn	2, 0xa11c
     b0e:	0001                	.insn	2, 0x0001
     b10:	0500                	.insn	2, 0x0500
     b12:	bb01                	.insn	2, 0xbb01
     b14:	1d05                	.insn	2, 0x1d05
     b16:	a611                	.insn	2, 0xa611
     b18:	0001                	.insn	2, 0x0001
     b1a:	0000                	.insn	2, 0x0000
     b1c:	151a                	.insn	2, 0x151a
     b1e:	0060                	.insn	2, 0x0060
     b20:	0000                	.insn	2, 0x0000
     b22:	013a121b          	.insn	4, 0x013a121b
     b26:	afbc                	.insn	2, 0xafbc
     b28:	0000                	.insn	2, 0x0000
     b2a:	1a00                	.insn	2, 0x1a00
     b2c:	3416                	.insn	2, 0x3416
     b2e:	0000                	.insn	2, 0x0000
     b30:	1b00                	.insn	2, 0x1b00
     b32:	bd013b13          	sltiu	s6,sp,-1072
     b36:	000000af          	.insn	4, 0x00af
     b3a:	0001b00f          	.insn	4, 0x0001b00f
     b3e:	1700                	.insn	2, 0x1700
     b40:	000c                	.insn	2, 0x000c
     b42:	0000                	.insn	2, 0x0000
     b44:	be01                	.insn	2, 0xbe01
     b46:	1e0d                	.insn	2, 0x1e0d
     b48:	6c01                	.insn	2, 0x6c01
     b4a:	01b5                	.insn	2, 0x01b5
     b4c:	0000                	.insn	2, 0x0000
     b4e:	0f00                	.insn	2, 0x0f00
     b50:	01a1                	.insn	2, 0x01a1
     b52:	0000                	.insn	2, 0x0000
     b54:	0c18                	.insn	2, 0x0c18
     b56:	0000                	.insn	2, 0x0000
     b58:	0100                	.insn	2, 0x0100
     b5a:	201f0dbf 000001a6 	.insn	8, 0x01a6201f0dbf
     b62:	0000                	.insn	2, 0x0000
     b64:	0001a10f          	.insn	4, 0x0001a10f
     b68:	1900                	.insn	2, 0x1900
     b6a:	000c                	.insn	2, 0x000c
     b6c:	0000                	.insn	2, 0x0000
     b6e:	c101                	.insn	2, 0xc101
     b70:	1f09                	.insn	2, 0x1f09
     b72:	a60a                	.insn	2, 0xa60a
     b74:	0001                	.insn	2, 0x0001
     b76:	0000                	.insn	2, 0x0000
     b78:	0f00                	.insn	2, 0x0f00
     b7a:	01a1                	.insn	2, 0x01a1
     b7c:	0000                	.insn	2, 0x0000
     b7e:	0c1a                	.insn	2, 0x0c1a
     b80:	0000                	.insn	2, 0x0000
     b82:	0100                	.insn	2, 0x0100
     b84:	0a1f05c3          	.insn	4, 0x0a1f05c3
     b88:	01a6                	.insn	2, 0x01a6
     b8a:	0000                	.insn	2, 0x0000
     b8c:	0000                	.insn	2, 0x0000
     b8e:	1b20                	.insn	2, 0x1b20
     b90:	0014                	.insn	2, 0x0014
     b92:	0000                	.insn	2, 0x0000
     b94:	5201                	.insn	2, 0x5201
     b96:	01a1                	.insn	2, 0x01a1
     b98:	0000                	.insn	2, 0x0000
     b9a:	141d                	.insn	2, 0x141d
     b9c:	01a6                	.insn	2, 0x01a6
     b9e:	0000                	.insn	2, 0x0000
     ba0:	2000                	.insn	2, 0x2000
     ba2:	141c                	.insn	2, 0x141c
     ba4:	0000                	.insn	2, 0x0000
     ba6:	0100                	.insn	2, 0x0100
     ba8:	b052                	.insn	2, 0xb052
     baa:	0001                	.insn	2, 0x0001
     bac:	1d00                	.insn	2, 0x1d00
     bae:	b515                	.insn	2, 0xb515
     bb0:	0001                	.insn	2, 0x0001
     bb2:	0000                	.insn	2, 0x0000
     bb4:	50011b13          	.insn	4, 0x50011b13
     bb8:	9902                	.insn	2, 0x9902
     bba:	0001                	.insn	2, 0x0001
     bbc:	1400                	.insn	2, 0x1400
     bbe:	0250010b          	.insn	4, 0x0250010b
     bc2:	000000af          	.insn	4, 0x00af
     bc6:	0c14                	.insn	2, 0x0c14
     bc8:	5001                	.insn	2, 0x5001
     bca:	af02                	.insn	2, 0xaf02
     bcc:	0000                	.insn	2, 0x0000
     bce:	1500                	.insn	2, 0x1500
     bd0:	0252010f          	.insn	4, 0x0252010f
     bd4:	000000af          	.insn	4, 0x00af
     bd8:	1215                	.insn	2, 0x1215
     bda:	5301                	.insn	2, 0x5301
     bdc:	af02                	.insn	2, 0xaf02
     bde:	0000                	.insn	2, 0x0000
     be0:	0000                	.insn	2, 0x0000
     be2:	000c1d17          	auipc	s10,0xc1
     be6:	0000                	.insn	2, 0x0000
     be8:	5201                	.insn	2, 0x5201
     bea:	0124                	.insn	2, 0x0124
     bec:	18c8                	.insn	2, 0x18c8
     bee:	3c16                	.insn	2, 0x3c16
     bf0:	c801                	.insn	2, 0xc801
     bf2:	000000b7          	lui	ra,0x0
     bf6:	00041e0f          	.insn	4, 0x00041e0f
     bfa:	1d00                	.insn	2, 0x1d00
     bfc:	0008                	.insn	2, 0x0008
     bfe:	0000                	.insn	2, 0x0000
     c00:	cb01                	.insn	2, 0xcb01
     c02:	1f05                	.insn	2, 0x1f05
     c04:	2714                	.insn	2, 0x2714
     c06:	0004                	.insn	2, 0x0004
     c08:	1e00                	.insn	2, 0x1e00
     c0a:	5a01                	.insn	2, 0x5a01
     c0c:	0430                	.insn	2, 0x0430
     c0e:	0000                	.insn	2, 0x0000
     c10:	0121                	.insn	2, 0x0121
     c12:	395a                	.insn	2, 0x395a
     c14:	0004                	.insn	2, 0x0004
     c16:	2200                	.insn	2, 0x2200
     c18:	4214                	.insn	2, 0x4214
     c1a:	0004                	.insn	2, 0x0004
     c1c:	0000                	.insn	2, 0x0000
     c1e:	0b00                	.insn	2, 0x0b00
     c20:	011c                	.insn	2, 0x011c
     c22:	afd2                	.insn	2, 0xafd2
     c24:	0000                	.insn	2, 0x0000
     c26:	0c00                	.insn	2, 0x0c00
     c28:	afd3010b          	.insn	4, 0xafd3010b
     c2c:	0000                	.insn	2, 0x0000
     c2e:	0c00                	.insn	2, 0x0c00
     c30:	010c                	.insn	2, 0x010c
     c32:	afd4                	.insn	2, 0xafd4
     c34:	0000                	.insn	2, 0x0000
     c36:	0c00                	.insn	2, 0x0c00
     c38:	010d                	.insn	2, 0x010d
     c3a:	afd5                	.insn	2, 0xafd5
     c3c:	0000                	.insn	2, 0x0000
     c3e:	0d00                	.insn	2, 0x0d00
     c40:	0110                	.insn	2, 0x0110
     c42:	afd8                	.insn	2, 0xafd8
     c44:	0000                	.insn	2, 0x0000
     c46:	0d00                	.insn	2, 0x0d00
     c48:	afd7010f          	.insn	4, 0xafd7010f
     c4c:	0000                	.insn	2, 0x0000
     c4e:	0d00                	.insn	2, 0x0d00
     c50:	0112                	.insn	2, 0x0112
     c52:	afd9                	.insn	2, 0xafd9
     c54:	0000                	.insn	2, 0x0000
     c56:	0000                	.insn	2, 0x0000
     c58:	00ac1e23          	sh	a0,28(s8)
     c5c:	0000                	.insn	2, 0x0000
     c5e:	5201                	.insn	2, 0x5201
     c60:	0125                	.insn	2, 0x0125
     c62:	000199e7          	.insn	4, 0x000199e7
     c66:	1800                	.insn	2, 0x1800
     c68:	e8013c17          	auipc	s8,0xe8013
     c6c:	000000af          	.insn	4, 0x00af
     c70:	0219                	.insn	2, 0x0219
     c72:	1091                	.insn	2, 0x1091
     c74:	013d                	.insn	2, 0x013d
     c76:	afea                	.insn	2, 0xafea
     c78:	0000                	.insn	2, 0x0000
     c7a:	1900                	.insn	2, 0x1900
     c7c:	9102                	.insn	2, 0x9102
     c7e:	3e0c                	.insn	2, 0x3e0c
     c80:	eb01                	.insn	2, 0xeb01
     c82:	000000af          	.insn	4, 0x00af
     c86:	013f181b          	.insn	4, 0x013f181b
     c8a:	0000affb          	.insn	4, 0xaffb
     c8e:	2400                	.insn	2, 0x2400
     c90:	0489                	.insn	2, 0x0489
     c92:	0000                	.insn	2, 0x0000
     c94:	141f 0000 0100      	.insn	6, 0x01000000141f
     c9a:	0105                	.insn	2, 0x0105
     c9c:	1f0c                	.insn	2, 0x1f0c
     c9e:	9115                	.insn	2, 0x9115
     ca0:	0004                	.insn	2, 0x0004
     ca2:	1e00                	.insn	2, 0x1e00
     ca4:	5801                	.insn	2, 0x5801
     ca6:	0499                	.insn	2, 0x0499
     ca8:	0000                	.insn	2, 0x0000
     caa:	011e                	.insn	2, 0x011e
     cac:	a159                	.insn	2, 0xa159
     cae:	0004                	.insn	2, 0x0004
     cb0:	2100                	.insn	2, 0x2100
     cb2:	5901                	.insn	2, 0x5901
     cb4:	04a9                	.insn	2, 0x04a9
     cb6:	0000                	.insn	2, 0x0000
     cb8:	1911                	.insn	2, 0x1911
     cba:	04b1                	.insn	2, 0x04b1
     cbc:	0000                	.insn	2, 0x0000
     cbe:	1522                	.insn	2, 0x1522
     cc0:	04b9                	.insn	2, 0x04b9
     cc2:	0000                	.insn	2, 0x0000
     cc4:	2500                	.insn	2, 0x2500
     cc6:	0548                	.insn	2, 0x0548
     cc8:	0000                	.insn	2, 0x0000
     cca:	2520                	.insn	2, 0x2520
     ccc:	00000577          	.insn	4, 0x0577
     cd0:	2521                	.insn	2, 0x2521
     cd2:	000006ab          	.insn	4, 0x06ab
     cd6:	2522                	.insn	2, 0x2522
     cd8:	00000577          	.insn	4, 0x0577
     cdc:	001f 1d26 0f04      	.insn	6, 0x0f041d26001f
     ce2:	000000bb          	.insn	4, 0x00bb
     ce6:	00056027          	.insn	4, 0x00056027
     cea:	2700                	.insn	2, 0x2700
     cec:	056a                	.insn	2, 0x056a
     cee:	0000                	.insn	2, 0x0000
     cf0:	00056a27          	.insn	4, 0x00056a27
     cf4:	0000                	.insn	2, 0x0000
     cf6:	650a                	.insn	2, 0x650a
     cf8:	0005                	.insn	2, 0x0005
     cfa:	2800                	.insn	2, 0x2800
     cfc:	0041                	.insn	2, 0x0041
     cfe:	0000                	.insn	2, 0x0000
     d00:	6f0a                	.insn	2, 0x6f0a
     d02:	0005                	.insn	2, 0x0005
     d04:	0900                	.insn	2, 0x0900
     d06:	000000b7          	lui	ra,0x0
     d0a:	0508                	.insn	2, 0x0508
     d0c:	2921                	.insn	2, 0x2921
     d0e:	0002b823          	.insn	4, 0x0002b823
     d12:	0100                	.insn	2, 0x0100
     d14:	2652                	.insn	2, 0x2652
     d16:	5901                	.insn	2, 0x5901
     d18:	2a01                	.insn	2, 0x2a01
     d1a:	431a                	.insn	2, 0x431a
     d1c:	5901                	.insn	2, 0x5901
     d1e:	6001                	.insn	2, 0x6001
     d20:	0005                	.insn	2, 0x0005
     d22:	2b00                	.insn	2, 0x2b00
     d24:	9102                	.insn	2, 0x9102
     d26:	400c                	.insn	2, 0x400c
     d28:	5a01                	.insn	2, 0x5a01
     d2a:	8001                	.insn	2, 0x8001
     d2c:	000a                	.insn	2, 0x000a
     d2e:	2c00                	.insn	2, 0x2c00
     d30:	0148                	.insn	2, 0x0148
     d32:	019f 3d01 062d      	.insn	6, 0x062d3d01019f
     d38:	0191022b          	.insn	4, 0x0191022b
     d3c:	0142                	.insn	2, 0x0142
     d3e:	017c                	.insn	2, 0x017c
     d40:	00000a87          	.insn	4, 0x0a87
     d44:	1b2e                	.insn	2, 0x1b2e
     d46:	0144                	.insn	2, 0x0144
     d48:	0170                	.insn	2, 0x0170
     d4a:	000000bb          	.insn	4, 0x00bb
     d4e:	1c2e                	.insn	2, 0x1c2e
     d50:	0145                	.insn	2, 0x0145
     d52:	0172                	.insn	2, 0x0172
     d54:	000000b7          	lui	ra,0x0
     d58:	1d2e                	.insn	2, 0x1d2e
     d5a:	013a                	.insn	2, 0x013a
     d5c:	017d                	.insn	2, 0x017d
     d5e:	000000bb          	.insn	4, 0x00bb
     d62:	a124                	.insn	2, 0xa124
     d64:	0001                	.insn	2, 0x0001
     d66:	2400                	.insn	2, 0x2400
     d68:	000c                	.insn	2, 0x000c
     d6a:	0000                	.insn	2, 0x0000
     d6c:	7401                	.insn	2, 0x7401
     d6e:	1901                	.insn	2, 0x1901
     d70:	2d1f 01a6 0000      	.insn	6, 0x01a62d1f
     d76:	2400                	.insn	2, 0x2400
     d78:	01a1                	.insn	2, 0x01a1
     d7a:	0000                	.insn	2, 0x0000
     d7c:	0c25                	.insn	2, 0x0c25
     d7e:	0000                	.insn	2, 0x0000
     d80:	0100                	.insn	2, 0x0100
     d82:	0181                	.insn	2, 0x0181
     d84:	1f19                	.insn	2, 0x1f19
     d86:	a630                	.insn	2, 0xa630
     d88:	0001                	.insn	2, 0x0001
     d8a:	0000                	.insn	2, 0x0000
     d8c:	0001a12f          	.insn	4, 0x0001a12f
     d90:	2600                	.insn	2, 0x2600
     d92:	000c                	.insn	2, 0x000c
     d94:	0000                	.insn	2, 0x0000
     d96:	8c01                	.insn	2, 0x8c01
     d98:	1901                	.insn	2, 0x1901
     d9a:	1a00                	.insn	2, 0x1a00
     d9c:	0000e827          	.insn	4, 0xe827
     da0:	2e00                	.insn	2, 0x2e00
     da2:	441e                	.insn	2, 0x441e
     da4:	9101                	.insn	2, 0x9101
     da6:	b701                	.insn	2, 0xb701
     da8:	0000                	.insn	2, 0x0000
     daa:	1a00                	.insn	2, 0x1a00
     dac:	d828                	.insn	2, 0xd828
     dae:	0000                	.insn	2, 0x0000
     db0:	2e00                	.insn	2, 0x2e00
     db2:	3a1f 9201 bb01      	.insn	6, 0xbb0192013a1f
     db8:	0000                	.insn	2, 0x0000
     dba:	1a00                	.insn	2, 0x1a00
     dbc:	d828                	.insn	2, 0xd828
     dbe:	0000                	.insn	2, 0x0000
     dc0:	2e00                	.insn	2, 0x2e00
     dc2:	4620                	.insn	2, 0x4620
     dc4:	9301                	.insn	2, 0x9301
     dc6:	b701                	.insn	2, 0xb701
     dc8:	0000                	.insn	2, 0x0000
     dca:	3000                	.insn	2, 0x3000
     dcc:	01a1                	.insn	2, 0x01a1
     dce:	0000                	.insn	2, 0x0000
     dd0:	01940107          	.insn	4, 0x01940107
     dd4:	0019                	.insn	2, 0x0019
     dd6:	0000                	.insn	2, 0x0000
     dd8:	a124                	.insn	2, 0xa124
     dda:	0001                	.insn	2, 0x0001
     ddc:	2900                	.insn	2, 0x2900
     dde:	000c                	.insn	2, 0x000c
     de0:	0000                	.insn	2, 0x0000
     de2:	6501                	.insn	2, 0x6501
     de4:	1501                	.insn	2, 0x1501
     de6:	251f 01a6 0000      	.insn	6, 0x01a6251f
     dec:	1a00                	.insn	2, 0x1a00
     dee:	382a                	.insn	2, 0x382a
     df0:	0000                	.insn	2, 0x0000
     df2:	2e00                	.insn	2, 0x2e00
     df4:	4721                	.insn	2, 0x4721
     df6:	6801                	.insn	2, 0x6801
     df8:	6001                	.insn	2, 0x6001
     dfa:	0005                	.insn	2, 0x0005
     dfc:	2400                	.insn	2, 0x2400
     dfe:	01a1                	.insn	2, 0x01a1
     e00:	0000                	.insn	2, 0x0000
     e02:	00000c2b          	.insn	4, 0x0c2b
     e06:	0100                	.insn	2, 0x0100
     e08:	016a                	.insn	2, 0x016a
     e0a:	1e19                	.insn	2, 0x1e19
     e0c:	5801                	.insn	2, 0x5801
     e0e:	01a6                	.insn	2, 0x01a6
     e10:	0000                	.insn	2, 0x0000
     e12:	0000                	.insn	2, 0x0000
     e14:	a124                	.insn	2, 0xa124
     e16:	0001                	.insn	2, 0x0001
     e18:	2c00                	.insn	2, 0x2c00
     e1a:	000c                	.insn	2, 0x000c
     e1c:	0000                	.insn	2, 0x0000
     e1e:	6201                	.insn	2, 0x6201
     e20:	1501                	.insn	2, 0x1501
     e22:	251f 01a6 0000      	.insn	6, 0x01a6251f
     e28:	2400                	.insn	2, 0x2400
     e2a:	01a1                	.insn	2, 0x01a1
     e2c:	0000                	.insn	2, 0x0000
     e2e:	0c2d                	.insn	2, 0x0c2d
     e30:	0000                	.insn	2, 0x0000
     e32:	0100                	.insn	2, 0x0100
     e34:	0199                	.insn	2, 0x0199
     e36:	1e0d                	.insn	2, 0x1e0d
     e38:	5801                	.insn	2, 0x5801
     e3a:	01a6                	.insn	2, 0x01a6
     e3c:	0000                	.insn	2, 0x0000
     e3e:	3100                	.insn	2, 0x3100
     e40:	2600                	.insn	2, 0x2600
     e42:	031e                	.insn	2, 0x031e
     e44:	9925                	.insn	2, 0x9925
     e46:	0001                	.insn	2, 0x0001
     e48:	2700                	.insn	2, 0x2700
     e4a:	0199                	.insn	2, 0x0199
     e4c:	0000                	.insn	2, 0x0000
     e4e:	2900                	.insn	2, 0x2900
     e50:	0c2e                	.insn	2, 0x0c2e
     e52:	0000                	.insn	2, 0x0000
     e54:	0100                	.insn	2, 0x0100
     e56:	2752                	.insn	2, 0x2752
     e58:	0e01                	.insn	2, 0x0e01
     e5a:	2a01                	.insn	2, 0x2a01
     e5c:	3c22                	.insn	2, 0x3c22
     e5e:	0e01                	.insn	2, 0x0e01
     e60:	b701                	.insn	2, 0xb701
     e62:	0000                	.insn	2, 0x0000
     e64:	2400                	.insn	2, 0x2400
     e66:	041e                	.insn	2, 0x041e
     e68:	0000                	.insn	2, 0x0000
     e6a:	082e                	.insn	2, 0x082e
     e6c:	0000                	.insn	2, 0x0000
     e6e:	0100                	.insn	2, 0x0100
     e70:	0111                	.insn	2, 0x0111
     e72:	1f05                	.insn	2, 0x1f05
     e74:	2715                	.insn	2, 0x2715
     e76:	0004                	.insn	2, 0x0004
     e78:	1e00                	.insn	2, 0x1e00
     e7a:	5a01                	.insn	2, 0x5a01
     e7c:	0430                	.insn	2, 0x0430
     e7e:	0000                	.insn	2, 0x0000
     e80:	0121                	.insn	2, 0x0121
     e82:	395a                	.insn	2, 0x395a
     e84:	0004                	.insn	2, 0x0004
     e86:	2200                	.insn	2, 0x2200
     e88:	4215                	.insn	2, 0x4215
     e8a:	0004                	.insn	2, 0x0004
     e8c:	0000                	.insn	2, 0x0000
     e8e:	1300                	.insn	2, 0x1300
     e90:	011f 0260 0199      	.insn	6, 0x01990260011f
     e96:	0000                	.insn	2, 0x0000
     e98:	0b14                	.insn	2, 0x0b14
     e9a:	6001                	.insn	2, 0x6001
     e9c:	af02                	.insn	2, 0xaf02
     e9e:	0000                	.insn	2, 0x0000
     ea0:	1400                	.insn	2, 0x1400
     ea2:	010c                	.insn	2, 0x010c
     ea4:	0260                	.insn	2, 0x0260
     ea6:	000000af          	.insn	4, 0x00af
     eaa:	0f15                	.insn	2, 0x0f15
     eac:	6201                	.insn	2, 0x6201
     eae:	af02                	.insn	2, 0xaf02
     eb0:	0000                	.insn	2, 0x0000
     eb2:	1500                	.insn	2, 0x1500
     eb4:	0112                	.insn	2, 0x0112
     eb6:	00af0263          	beq	t5,a0,eba <start-0x3ff146>
     eba:	0000                	.insn	2, 0x0000
     ebc:	2900                	.insn	2, 0x2900
     ebe:	00000c2f          	.insn	4, 0x0c2f
     ec2:	0100                	.insn	2, 0x0100
     ec4:	2852                	.insn	2, 0x2852
     ec6:	1901                	.insn	2, 0x1901
     ec8:	2a01                	.insn	2, 0x2a01
     eca:	19014923          	.insn	4, 0x19014923
     ece:	b701                	.insn	2, 0xb701
     ed0:	0000                	.insn	2, 0x0000
     ed2:	2400                	.insn	2, 0x2400
     ed4:	06f9                	.insn	2, 0x06f9
     ed6:	0000                	.insn	2, 0x0000
     ed8:	0000082f          	.insn	4, 0x082f
     edc:	0100                	.insn	2, 0x0100
     ede:	011c                	.insn	2, 0x011c
     ee0:	1f05                	.insn	2, 0x1f05
     ee2:	021e                	.insn	2, 0x021e
     ee4:	1e000007          	.insn	4, 0x1e000007
     ee8:	5a01                	.insn	2, 0x5a01
     eea:	0000070b          	.insn	4, 0x070b
     eee:	0121                	.insn	2, 0x0121
     ef0:	145a                	.insn	2, 0x145a
     ef2:	22000007          	.insn	4, 0x22000007
     ef6:	1d1e                	.insn	2, 0x1d1e
     ef8:	00000007          	.insn	4, 0x0007
     efc:	2900                	.insn	2, 0x2900
     efe:	0c30                	.insn	2, 0x0c30
     f00:	0000                	.insn	2, 0x0000
     f02:	0100                	.insn	2, 0x0100
     f04:	2952                	.insn	2, 0x2952
     f06:	2401                	.insn	2, 0x2401
     f08:	2a01                	.insn	2, 0x2a01
     f0a:	4924                	.insn	2, 0x4924
     f0c:	2401                	.insn	2, 0x2401
     f0e:	b701                	.insn	2, 0xb701
     f10:	0000                	.insn	2, 0x0000
     f12:	2400                	.insn	2, 0x2400
     f14:	06f9                	.insn	2, 0x06f9
     f16:	0000                	.insn	2, 0x0000
     f18:	0830                	.insn	2, 0x0830
     f1a:	0000                	.insn	2, 0x0000
     f1c:	0100                	.insn	2, 0x0100
     f1e:	1f050127          	.insn	4, 0x1f050127
     f22:	021f 0007 1e00      	.insn	6, 0x1e000007021f
     f28:	5a01                	.insn	2, 0x5a01
     f2a:	0000070b          	.insn	4, 0x070b
     f2e:	0121                	.insn	2, 0x0121
     f30:	145a                	.insn	2, 0x145a
     f32:	22000007          	.insn	4, 0x22000007
     f36:	1d1f 0007 0000      	.insn	6, 0x00071d1f
     f3c:	1300                	.insn	2, 0x1300
     f3e:	0120                	.insn	2, 0x0120
     f40:	0270                	.insn	2, 0x0270
     f42:	0199                	.insn	2, 0x0199
     f44:	0000                	.insn	2, 0x0000
     f46:	0b14                	.insn	2, 0x0b14
     f48:	7101                	.insn	2, 0x7101
     f4a:	af02                	.insn	2, 0xaf02
     f4c:	0000                	.insn	2, 0x0000
     f4e:	1400                	.insn	2, 0x1400
     f50:	010c                	.insn	2, 0x010c
     f52:	0272                	.insn	2, 0x0272
     f54:	000000af          	.insn	4, 0x00af
     f58:	0d14                	.insn	2, 0x0d14
     f5a:	7301                	.insn	2, 0x7301
     f5c:	af02                	.insn	2, 0xaf02
     f5e:	0000                	.insn	2, 0x0000
     f60:	1500                	.insn	2, 0x1500
     f62:	0275010f          	.insn	4, 0x0275010f
     f66:	000000af          	.insn	4, 0x00af
     f6a:	1015                	.insn	2, 0x1015
     f6c:	7601                	.insn	2, 0x7601
     f6e:	af02                	.insn	2, 0xaf02
     f70:	0000                	.insn	2, 0x0000
     f72:	1500                	.insn	2, 0x1500
     f74:	0112                	.insn	2, 0x0112
     f76:	00af0277          	.insn	4, 0x00af0277
     f7a:	0000                	.insn	2, 0x0000
     f7c:	3200                	.insn	2, 0x3200
     f7e:	0c31                	.insn	2, 0x0c31
     f80:	0000                	.insn	2, 0x0000
     f82:	0100                	.insn	2, 0x0100
     f84:	2a52                	.insn	2, 0x2a52
     f86:	2e01                	.insn	2, 0x2e01
     f88:	9901                	.insn	2, 0x9901
     f8a:	0001                	.insn	2, 0x0001
     f8c:	2a00                	.insn	2, 0x2a00
     f8e:	4925                	.insn	2, 0x4925
     f90:	2f01                	.insn	2, 0x2f01
     f92:	af01                	.insn	2, 0xaf01
     f94:	0000                	.insn	2, 0x0000
     f96:	3300                	.insn	2, 0x3300
     f98:	5b01                	.insn	2, 0x5b01
     f9a:	0142                	.insn	2, 0x0142
     f9c:	0130                	.insn	2, 0x0130
     f9e:	00000a93          	li	s5,0
     fa2:	a724                	.insn	2, 0xa724
     fa4:	31000007          	.insn	4, 0x31000007
     fa8:	0008                	.insn	2, 0x0008
     faa:	0000                	.insn	2, 0x0000
     fac:	3201                	.insn	2, 0x3201
     fae:	0c01                	.insn	2, 0x0c01
     fb0:	201f 07b0 0000      	.insn	6, 0x07b0201f
     fb6:	011e                	.insn	2, 0x011e
     fb8:	b95a                	.insn	2, 0xb95a
     fba:	1e000007          	.insn	4, 0x1e000007
     fbe:	5b01                	.insn	2, 0x5b01
     fc0:	07c2                	.insn	2, 0x07c2
     fc2:	0000                	.insn	2, 0x0000
     fc4:	0121                	.insn	2, 0x0121
     fc6:	cb5a                	.insn	2, 0xcb5a
     fc8:	21000007          	.insn	4, 0x21000007
     fcc:	5b01                	.insn	2, 0x5b01
     fce:	07d4                	.insn	2, 0x07d4
     fd0:	0000                	.insn	2, 0x0000
     fd2:	2022                	.insn	2, 0x2022
     fd4:	07dd                	.insn	2, 0x07dd
     fd6:	0000                	.insn	2, 0x0000
     fd8:	0000                	.insn	2, 0x0000
     fda:	2134                	.insn	2, 0x2134
     fdc:	9601                	.insn	2, 0x9601
     fde:	1402                	.insn	2, 0x1402
     fe0:	0296010b          	.insn	4, 0x0296010b
     fe4:	000000af          	.insn	4, 0x00af
     fe8:	0c14                	.insn	2, 0x0c14
     fea:	9701                	.insn	2, 0x9701
     fec:	af02                	.insn	2, 0xaf02
     fee:	0000                	.insn	2, 0x0000
     ff0:	1400                	.insn	2, 0x1400
     ff2:	010d                	.insn	2, 0x010d
     ff4:	0298                	.insn	2, 0x0298
     ff6:	000000af          	.insn	4, 0x00af
     ffa:	0f15                	.insn	2, 0x0f15
     ffc:	9a01                	.insn	2, 0x9a01
     ffe:	af02                	.insn	2, 0xaf02
    1000:	0000                	.insn	2, 0x0000
    1002:	1500                	.insn	2, 0x1500
    1004:	0110                	.insn	2, 0x0110
    1006:	00af029b          	.insn	4, 0x00af029b
    100a:	0000                	.insn	2, 0x0000
    100c:	1215                	.insn	2, 0x1215
    100e:	9c01                	.insn	2, 0x9c01
    1010:	af02                	.insn	2, 0xaf02
    1012:	0000                	.insn	2, 0x0000
    1014:	0000                	.insn	2, 0x0000
    1016:	3229                	.insn	2, 0x3229
    1018:	000c                	.insn	2, 0x000c
    101a:	0000                	.insn	2, 0x0000
    101c:	5201                	.insn	2, 0x5201
    101e:	013b012b          	.insn	4, 0x013b012b
    1022:	4a5a0133          	.insn	4, 0x4a5a0133
    1026:	3b01                	.insn	2, 0x3b01
    1028:	af01                	.insn	2, 0xaf01
    102a:	0000                	.insn	2, 0x0000
    102c:	3300                	.insn	2, 0x3300
    102e:	5b01                	.insn	2, 0x5b01
    1030:	013b014b          	.insn	4, 0x013b014b
    1034:	000000af          	.insn	4, 0x00af
    1038:	4424                	.insn	2, 0x4424
    103a:	0008                	.insn	2, 0x0008
    103c:	3200                	.insn	2, 0x3200
    103e:	0008                	.insn	2, 0x0008
    1040:	0000                	.insn	2, 0x0000
    1042:	3e01                	.insn	2, 0x3e01
    1044:	0501                	.insn	2, 0x0501
    1046:	281f 0849 0000      	.insn	6, 0x0849281f
    104c:	011e                	.insn	2, 0x011e
    104e:	525a                	.insn	2, 0x525a
    1050:	0008                	.insn	2, 0x0008
    1052:	1e00                	.insn	2, 0x1e00
    1054:	5b01                	.insn	2, 0x5b01
    1056:	0000085b          	.insn	4, 0x085b
    105a:	0121                	.insn	2, 0x0121
    105c:	645a                	.insn	2, 0x645a
    105e:	0008                	.insn	2, 0x0008
    1060:	2100                	.insn	2, 0x2100
    1062:	5b01                	.insn	2, 0x5b01
    1064:	086d                	.insn	2, 0x086d
    1066:	0000                	.insn	2, 0x0000
    1068:	2822                	.insn	2, 0x2822
    106a:	0876                	.insn	2, 0x0876
    106c:	0000                	.insn	2, 0x0000
    106e:	0000                	.insn	2, 0x0000
    1070:	3332                	.insn	2, 0x3332
    1072:	0034                	.insn	2, 0x0034
    1074:	0000                	.insn	2, 0x0000
    1076:	5201                	.insn	2, 0x5201
    1078:	012c                	.insn	2, 0x012c
    107a:	0146                	.insn	2, 0x0146
    107c:	00000a4f          	.insn	4, 0x0a4f
    1080:	4c5a0133          	.insn	4, 0x4c5a0133
    1084:	4601                	.insn	2, 0x4601
    1086:	4f01                	.insn	2, 0x4f01
    1088:	000a                	.insn	2, 0x000a
    108a:	2a00                	.insn	2, 0x2a00
    108c:	4d26                	.insn	2, 0x4d26
    108e:	4601                	.insn	2, 0x4601
    1090:	6001                	.insn	2, 0x6001
    1092:	0005                	.insn	2, 0x0005
    1094:	2e00                	.insn	2, 0x2e00
    1096:	47014e27          	.insn	4, 0x47014e27
    109a:	4f01                	.insn	2, 0x4f01
    109c:	000a                	.insn	2, 0x000a
    109e:	0000                	.insn	2, 0x0000
    10a0:	3432                	.insn	2, 0x3432
    10a2:	0030                	.insn	2, 0x0030
    10a4:	0000                	.insn	2, 0x0000
    10a6:	5201                	.insn	2, 0x5201
    10a8:	012d                	.insn	2, 0x012d
    10aa:	014e                	.insn	2, 0x014e
    10ac:	000000bb          	.insn	4, 0x00bb
    10b0:	282a                	.insn	2, 0x282a
    10b2:	014e014f          	.insn	4, 0x014e014f
    10b6:	0560                	.insn	2, 0x0560
    10b8:	0000                	.insn	2, 0x0000
    10ba:	505b0133          	.insn	4, 0x505b0133
    10be:	4e01                	.insn	2, 0x4e01
    10c0:	6001                	.insn	2, 0x6001
    10c2:	0005                	.insn	2, 0x0005
    10c4:	0000                	.insn	2, 0x0000
    10c6:	3532                	.insn	2, 0x3532
    10c8:	00bc                	.insn	2, 0x00bc
    10ca:	0000                	.insn	2, 0x0000
    10cc:	5201                	.insn	2, 0x5201
    10ce:	012e                	.insn	2, 0x012e
    10d0:	00b701a7          	.insn	4, 0x00b701a7
    10d4:	0000                	.insn	2, 0x0000
    10d6:	292a                	.insn	2, 0x292a
    10d8:	01a70147          	.insn	4, 0x01a70147
    10dc:	0560                	.insn	2, 0x0560
    10de:	0000                	.insn	2, 0x0000
    10e0:	2a2e                	.insn	2, 0x2a2e
    10e2:	0151                	.insn	2, 0x0151
    10e4:	01a8                	.insn	2, 0x01a8
    10e6:	000000b7          	lui	ra,0x0
    10ea:	2b2e                	.insn	2, 0x2b2e
    10ec:	011a                	.insn	2, 0x011a
    10ee:	01ad                	.insn	2, 0x01ad
    10f0:	000000b7          	lui	ra,0x0
    10f4:	082d                	.insn	2, 0x082d
    10f6:	2c2e                	.insn	2, 0x2c2e
    10f8:	0152                	.insn	2, 0x0152
    10fa:	004101af          	.insn	4, 0x004101af
    10fe:	0000                	.insn	2, 0x0000
    1100:	2d2e                	.insn	2, 0x2d2e
    1102:	014e                	.insn	2, 0x014e
    1104:	01b0                	.insn	2, 0x01b0
    1106:	000000b7          	lui	ra,0x0
    110a:	0000                	.insn	2, 0x0000
    110c:	3632                	.insn	2, 0x3632
    110e:	003c                	.insn	2, 0x003c
    1110:	0000                	.insn	2, 0x0000
    1112:	5201                	.insn	2, 0x5201
    1114:	01bc012f          	.insn	4, 0x01bc012f
    1118:	0a54                	.insn	2, 0x0a54
    111a:	0000                	.insn	2, 0x0000
    111c:	2e2a                	.insn	2, 0x2e2a
    111e:	0114                	.insn	2, 0x0114
    1120:	01bc                	.insn	2, 0x01bc
    1122:	000000b7          	lui	ra,0x0
    1126:	371a                	.insn	2, 0x371a
    1128:	001c                	.insn	2, 0x001c
    112a:	0000                	.insn	2, 0x0000
    112c:	2f2e                	.insn	2, 0x2f2e
    112e:	013a                	.insn	2, 0x013a
    1130:	01c0                	.insn	2, 0x01c0
    1132:	000000b7          	lui	ra,0x0
    1136:	0000                	.insn	2, 0x0000
    1138:	3832                	.insn	2, 0x3832
    113a:	0014                	.insn	2, 0x0014
    113c:	0000                	.insn	2, 0x0000
    113e:	5201                	.insn	2, 0x5201
    1140:	0131                	.insn	2, 0x0131
    1142:	020d                	.insn	2, 0x020d
    1144:	000000bb          	.insn	4, 0x00bb
    1148:	302e                	.insn	2, 0x302e
    114a:	0118                	.insn	2, 0x0118
    114c:	00bb020f          	.insn	4, 0x00bb020f
    1150:	0000                	.insn	2, 0x0000
    1152:	3200                	.insn	2, 0x3200
    1154:	1439                	.insn	2, 0x1439
    1156:	0000                	.insn	2, 0x0000
    1158:	0100                	.insn	2, 0x0100
    115a:	3252                	.insn	2, 0x3252
    115c:	1b01                	.insn	2, 0x1b01
    115e:	bb02                	.insn	2, 0xbb02
    1160:	0000                	.insn	2, 0x0000
    1162:	2e00                	.insn	2, 0x2e00
    1164:	1831                	.insn	2, 0x1831
    1166:	1d01                	.insn	2, 0x1d01
    1168:	bb02                	.insn	2, 0xbb02
    116a:	0000                	.insn	2, 0x0000
    116c:	0000                	.insn	2, 0x0000
    116e:	3a32                	.insn	2, 0x3a32
    1170:	000c                	.insn	2, 0x000c
    1172:	0000                	.insn	2, 0x0000
    1174:	5201                	.insn	2, 0x5201
    1176:	02850133          	mul	sp,a0,s0
    117a:	000000bb          	.insn	4, 0x00bb
    117e:	322a                	.insn	2, 0x322a
    1180:	0149                	.insn	2, 0x0149
    1182:	0285                	.insn	2, 0x0285
    1184:	000000af          	.insn	4, 0x00af
    1188:	425b0133          	.insn	4, 0x425b0133
    118c:	8501                	.insn	2, 0x8501
    118e:	8602                	.insn	2, 0x8602
    1190:	000a                	.insn	2, 0x000a
    1192:	2b00                	.insn	2, 0x2b00
    1194:	5a01                	.insn	2, 0x5a01
    1196:	0287010f          	.insn	4, 0x0287010f
    119a:	000000af          	.insn	4, 0x00af
    119e:	105b012b          	.insn	4, 0x105b012b
    11a2:	8801                	.insn	2, 0x8801
    11a4:	af02                	.insn	2, 0xaf02
    11a6:	0000                	.insn	2, 0x0000
    11a8:	3500                	.insn	2, 0x3500
    11aa:	1221                	.insn	2, 0x1221
    11ac:	8901                	.insn	2, 0x8901
    11ae:	af02                	.insn	2, 0xaf02
    11b0:	0000                	.insn	2, 0x0000
    11b2:	0000                	.insn	2, 0x0000
    11b4:	3b32                	.insn	2, 0x3b32
    11b6:	000c                	.insn	2, 0x000c
    11b8:	0000                	.insn	2, 0x0000
    11ba:	5201                	.insn	2, 0x5201
    11bc:	0134                	.insn	2, 0x0134
    11be:	02a9                	.insn	2, 0x02a9
    11c0:	0199                	.insn	2, 0x0199
    11c2:	0000                	.insn	2, 0x0000
    11c4:	3235                	.insn	2, 0x3235
    11c6:	0112                	.insn	2, 0x0112
    11c8:	02ac                	.insn	2, 0x02ac
    11ca:	000000af          	.insn	4, 0x00af
    11ce:	332e                	.insn	2, 0x332e
    11d0:	02ab010f          	.insn	4, 0x02ab010f
    11d4:	000000af          	.insn	4, 0x00af
    11d8:	3600                	.insn	2, 0x3600
    11da:	1c3c                	.insn	2, 0x1c3c
    11dc:	0000                	.insn	2, 0x0000
    11de:	0100                	.insn	2, 0x0100
    11e0:	3552                	.insn	2, 0x3552
    11e2:	bb01                	.insn	2, 0xbb01
    11e4:	0a02                	.insn	2, 0x0a02
    11e6:	0041                	.insn	2, 0x0041
    11e8:	0000                	.insn	2, 0x0000
    11ea:	bb09                	.insn	2, 0xbb09
    11ec:	0000                	.insn	2, 0x0000
    11ee:	3000                	.insn	2, 0x3000
    11f0:	a2030e03          	lb	t3,-1504(t1)
    11f4:	0000                	.insn	2, 0x0000
    11f6:	0400                	.insn	2, 0x0400
    11f8:	0045                	.insn	2, 0x0045
    11fa:	0000                	.insn	2, 0x0000
    11fc:	0440                	.insn	2, 0x0440
    11fe:	0045                	.insn	2, 0x0045
    1200:	0000                	.insn	2, 0x0000
    1202:	0040                	.insn	2, 0x0040
    1204:	0000af03          	lw	t5,0(ra) # 0 <start-0x400000>
    1208:	0400                	.insn	2, 0x0400
    120a:	0045                	.insn	2, 0x0045
    120c:	0000                	.insn	2, 0x0000
    120e:	0440                	.insn	2, 0x0440
    1210:	0045                	.insn	2, 0x0045
    1212:	0000                	.insn	2, 0x0000
    1214:	0040                	.insn	2, 0x0040
    1216:	000a8637          	lui	a2,0xa8
    121a:	4100                	.insn	2, 0x4100
    121c:	0338                	.insn	2, 0x0338
    121e:	0041                	.insn	2, 0x0041
    1220:	0000                	.insn	2, 0x0000
    1222:	4504                	.insn	2, 0x4504
    1224:	0000                	.insn	2, 0x0000
    1226:	0b00                	.insn	2, 0x0b00
    1228:	0a00                	.insn	2, 0x0a00
    122a:	0a98                	.insn	2, 0x0a98
    122c:	0000                	.insn	2, 0x0000
    122e:	a228                	.insn	2, 0xa228
    1230:	0000                	.insn	2, 0x0000
    1232:	0000                	.insn	2, 0x0000
    1234:	0561                	.insn	2, 0x0561
    1236:	0000                	.insn	2, 0x0000
    1238:	0005                	.insn	2, 0x0005
    123a:	0401                	.insn	2, 0x0401
    123c:	0506                	.insn	2, 0x0506
    123e:	0000                	.insn	2, 0x0000
    1240:	0001                	.insn	2, 0x0001
    1242:	001d                	.insn	2, 0x001d
    1244:	4401                	.insn	2, 0x4401
    1246:	0002                	.insn	2, 0x0002
    1248:	1e00                	.insn	2, 0x1e00
    124a:	000d                	.insn	2, 0x000d
    124c:	0200                	.insn	2, 0x0200
    124e:	000aa007          	.insn	4, 0x000aa007
    1252:	1000                	.insn	2, 0x1000
    1254:	96000003          	lb	zero,-1696(zero) # fffff960 <USER_MAX+0xffaff960>
    1258:	0001                	.insn	2, 0x0001
    125a:	9e00                	.insn	2, 0x9e00
    125c:	0008                	.insn	2, 0x0008
    125e:	0200                	.insn	2, 0x0200
    1260:	0035                	.insn	2, 0x0035
    1262:	0000                	.insn	2, 0x0000
    1264:	1301                	.insn	2, 0x1301
    1266:	a102                	.insn	2, 0xa102
    1268:	0300                	.insn	2, 0x0300
    126a:	0041                	.insn	2, 0x0041
    126c:	0000                	.insn	2, 0x0000
    126e:	4504                	.insn	2, 0x4504
    1270:	0000                	.insn	2, 0x0000
    1272:	1000                	.insn	2, 0x1000
    1274:	0500                	.insn	2, 0x0500
    1276:	06010803          	lb	a6,96(sp) # 5c870060 <USER_MAX+0x5c370060>
    127a:	0804                	.insn	2, 0x0804
    127c:	00530207          	.insn	4, 0x00530207
    1280:	0000                	.insn	2, 0x0000
    1282:	d701                	.insn	2, 0xd701
    1284:	a102                	.insn	2, 0xa102
    1286:	0301                	.insn	2, 0x0301
    1288:	0041                	.insn	2, 0x0041
    128a:	0000                	.insn	2, 0x0000
    128c:	4504                	.insn	2, 0x4504
    128e:	0000                	.insn	2, 0x0000
    1290:	0900                	.insn	2, 0x0900
    1292:	0200                	.insn	2, 0x0200
    1294:	0069                	.insn	2, 0x0069
    1296:	0000                	.insn	2, 0x0000
    1298:	f001                	.insn	2, 0xf001
    129a:	a102                	.insn	2, 0xa102
    129c:	0302                	.insn	2, 0x0302
    129e:	0041                	.insn	2, 0x0041
    12a0:	0000                	.insn	2, 0x0000
    12a2:	4504                	.insn	2, 0x4504
    12a4:	0000                	.insn	2, 0x0000
    12a6:	1700                	.insn	2, 0x1700
    12a8:	0700                	.insn	2, 0x0700
    12aa:	0080                	.insn	2, 0x0080
    12ac:	0000                	.insn	2, 0x0000
    12ae:	4c01                	.insn	2, 0x4c01
    12b0:	0201                	.insn	2, 0x0201
    12b2:	03a1                	.insn	2, 0x03a1
    12b4:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
    12b8:	0400                	.insn	2, 0x0400
    12ba:	0045                	.insn	2, 0x0045
    12bc:	0000                	.insn	2, 0x0000
    12be:	9707000b          	.insn	4, 0x9707000b
    12c2:	0000                	.insn	2, 0x0000
    12c4:	0100                	.insn	2, 0x0100
    12c6:	0154                	.insn	2, 0x0154
    12c8:	a102                	.insn	2, 0xa102
    12ca:	0304                	.insn	2, 0x0304
    12cc:	0041                	.insn	2, 0x0041
    12ce:	0000                	.insn	2, 0x0000
    12d0:	4504                	.insn	2, 0x4504
    12d2:	0000                	.insn	2, 0x0000
    12d4:	0200                	.insn	2, 0x0200
    12d6:	0700                	.insn	2, 0x0700
    12d8:	00ae                	.insn	2, 0x00ae
    12da:	0000                	.insn	2, 0x0000
    12dc:	5901                	.insn	2, 0x5901
    12de:	0201                	.insn	2, 0x0201
    12e0:	05a1                	.insn	2, 0x05a1
    12e2:	00004103          	lbu	sp,0(zero) # 0 <start-0x400000>
    12e6:	0400                	.insn	2, 0x0400
    12e8:	0045                	.insn	2, 0x0045
    12ea:	0000                	.insn	2, 0x0000
    12ec:	000d                	.insn	2, 0x000d
    12ee:	0508                	.insn	2, 0x0508
    12f0:	000000c7          	.insn	4, 0x00c7
    12f4:	0401                	.insn	2, 0x0401
    12f6:	a104                	.insn	2, 0xa104
    12f8:	2306                	.insn	2, 0x2306
    12fa:	0314                	.insn	2, 0x0314
    12fc:	00d4                	.insn	2, 0x00d4
    12fe:	0000                	.insn	2, 0x0000
    1300:	4509                	.insn	2, 0x4509
    1302:	0000                	.insn	2, 0x0000
    1304:	0000                	.insn	2, 0x0000
    1306:	0002                	.insn	2, 0x0002
    1308:	dc0a                	.insn	2, 0xdc0a
    130a:	0000                	.insn	2, 0x0000
    130c:	0700                	.insn	2, 0x0700
    130e:	0f02                	.insn	2, 0x0f02
    1310:	0605                	.insn	2, 0x0605
    1312:	0108                	.insn	2, 0x0108
    1314:	00eb080b          	.insn	4, 0x00eb080b
    1318:	0000                	.insn	2, 0x0000
    131a:	0601                	.insn	2, 0x0601
    131c:	a102                	.insn	2, 0xa102
    131e:	0a06                	.insn	2, 0x0a06
    1320:	000000f3          	.insn	4, 0x00f3
    1324:	0310                	.insn	2, 0x0310
    1326:	0c0c                	.insn	2, 0x0c0c
    1328:	0314                	.insn	2, 0x0314
    132a:	0d06                	.insn	2, 0x0d06
    132c:	2509                	.insn	2, 0x2509
    132e:	0001                	.insn	2, 0x0001
    1330:	0300                	.insn	2, 0x0300
    1332:	0c0d0007          	.insn	4, 0x0c0d0007
    1336:	0125                	.insn	2, 0x0125
    1338:	0000                	.insn	2, 0x0000
    133a:	0d040803          	lb	a6,208(s0) # 8c1775ea <USER_MAX+0x8bc775ea>
    133e:	250d                	.insn	2, 0x250d
    1340:	0001                	.insn	2, 0x0001
    1342:	0300                	.insn	2, 0x0300
    1344:	0809                	.insn	2, 0x0809
    1346:	0e0d                	.insn	2, 0x0e0d
    1348:	0125                	.insn	2, 0x0125
    134a:	0000                	.insn	2, 0x0000
    134c:	0d0c0a03          	lb	s4,208(s8) # e8013d38 <USER_MAX+0xe7b13d38>
    1350:	0001250f          	.insn	4, 0x0001250f
    1354:	0300                	.insn	2, 0x0300
    1356:	0a00100b          	.insn	4, 0x0a00100b
    135a:	012d                	.insn	2, 0x012d
    135c:	0000                	.insn	2, 0x0000
    135e:	0511020b          	.insn	4, 0x0511020b
    1362:	070a                	.insn	2, 0x070a
    1364:	0e04                	.insn	2, 0x0e04
    1366:	0111                	.insn	2, 0x0111
    1368:	257a                	.insn	2, 0x257a
    136a:	0001                	.insn	2, 0x0001
    136c:	0f00                	.insn	2, 0x0f00
    136e:	0112                	.insn	2, 0x0112
    1370:	257a                	.insn	2, 0x257a
    1372:	0001                	.insn	2, 0x0001
    1374:	0000                	.insn	2, 0x0000
    1376:	0710                	.insn	2, 0x0710
    1378:	00ec                	.insn	2, 0x00ec
    137a:	0000                	.insn	2, 0x0000
    137c:	5201                	.insn	2, 0x5201
    137e:	011e                	.insn	2, 0x011e
    1380:	f508                	.insn	2, 0xf508
    1382:	0002                	.insn	2, 0x0002
    1384:	1100                	.insn	2, 0x1100
    1386:	1900                	.insn	2, 0x1900
    1388:	0801                	.insn	2, 0x0801
    138a:	02d8                	.insn	2, 0x02d8
    138c:	0000                	.insn	2, 0x0000
    138e:	0212                	.insn	2, 0x0212
    1390:	1491                	.insn	2, 0x1491
    1392:	c70a0123          	sb	a6,-926(s4) # 6330c62 <USER_MAX+0x5e30c62>
    1396:	0000                	.insn	2, 0x0000
    1398:	1200                	.insn	2, 0x1200
    139a:	9102                	.insn	2, 0x9102
    139c:	1210                	.insn	2, 0x1210
    139e:	0c01                	.insn	2, 0x0c01
    13a0:	0125                	.insn	2, 0x0125
    13a2:	0000                	.insn	2, 0x0000
    13a4:	0212                	.insn	2, 0x0212
    13a6:	0c91                	.insn	2, 0x0c91
    13a8:	0124                	.insn	2, 0x0124
    13aa:	250d                	.insn	2, 0x250d
    13ac:	0001                	.insn	2, 0x0001
    13ae:	1300                	.insn	2, 0x1300
    13b0:	2502                	.insn	2, 0x2502
    13b2:	1701                	.insn	2, 0x1701
    13b4:	0125                	.insn	2, 0x0125
    13b6:	0000                	.insn	2, 0x0000
    13b8:	3114                	.insn	2, 0x3114
    13ba:	0001                	.insn	2, 0x0001
    13bc:	0800                	.insn	2, 0x0800
    13be:	001c                	.insn	2, 0x001c
    13c0:	0000                	.insn	2, 0x0000
    13c2:	1801                	.insn	2, 0x1801
    13c4:	1509                	.insn	2, 0x1509
    13c6:	3901                	.insn	2, 0x3901
    13c8:	0001                	.insn	2, 0x0001
    13ca:	0000                	.insn	2, 0x0000
    13cc:	0916                	.insn	2, 0x0916
    13ce:	0034                	.insn	2, 0x0034
    13d0:	0000                	.insn	2, 0x0000
    13d2:	011b0313          	addi	t1,s6,17
    13d6:	251d                	.insn	2, 0x251d
    13d8:	0001                	.insn	2, 0x0001
    13da:	0000                	.insn	2, 0x0000
    13dc:	0001cd17          	auipc	s10,0x1c
    13e0:	0a00                	.insn	2, 0x0a00
    13e2:	00020d17          	auipc	s10,0x20
    13e6:	0b00                	.insn	2, 0x0b00
    13e8:	0002cd17          	auipc	s10,0x2c
    13ec:	0c00                	.insn	2, 0x0c00
    13ee:	0002e217          	auipc	tp,0x2e
    13f2:	0d00                	.insn	2, 0x0d00
    13f4:	0002fa17          	auipc	s4,0x2f
    13f8:	0e00                	.insn	2, 0x0e00
    13fa:	0002fa17          	auipc	s4,0x2f
    13fe:	0f00                	.insn	2, 0x0f00
    1400:	1000                	.insn	2, 0x1000
    1402:	bc10                	.insn	2, 0xbc10
    1404:	0000                	.insn	2, 0x0000
    1406:	0100                	.insn	2, 0x0100
    1408:	1f52                	.insn	2, 0x1f52
    140a:	8101                	.insn	2, 0x8101
    140c:	02f5                	.insn	2, 0x02f5
    140e:	0000                	.insn	2, 0x0000
    1410:	01230413          	addi	s0,t1,18
    1414:	00045883          	lhu	a7,0(s0)
    1418:	1300                	.insn	2, 0x1300
    141a:	2605                	.insn	2, 0x2605
    141c:	9101                	.insn	2, 0x9101
    141e:	0125                	.insn	2, 0x0125
    1420:	0000                	.insn	2, 0x0000
    1422:	01270613          	addi	a2,a4,18
    1426:	2595                	.insn	2, 0x2595
    1428:	0001                	.insn	2, 0x0001
    142a:	1300                	.insn	2, 0x1300
    142c:	98012807          	.insn	4, 0x98012807
    1430:	0125                	.insn	2, 0x0125
    1432:	0000                	.insn	2, 0x0000
    1434:	0002e217          	auipc	tp,0x2e
    1438:	1100                	.insn	2, 0x1100
    143a:	0002e217          	auipc	tp,0x2e
    143e:	1200                	.insn	2, 0x1200
    1440:	1000                	.insn	2, 0x1000
    1442:	0002a013          	slti	zero,t0,0
    1446:	0100                	.insn	2, 0x0100
    1448:	2052                	.insn	2, 0x2052
    144a:	2a01                	.insn	2, 0x2a01
    144c:	02f5                	.insn	2, 0x02f5
    144e:	0000                	.insn	2, 0x0000
    1450:	0811                	.insn	2, 0x0811
    1452:	0119                	.insn	2, 0x0119
    1454:	0002d82b          	.insn	4, 0x0002d82b
    1458:	1100                	.insn	2, 0x1100
    145a:	1209                	.insn	2, 0x1209
    145c:	2c01                	.insn	2, 0x2c01
    145e:	00000553          	.insn	4, 0x0553
    1462:	0a11                	.insn	2, 0x0a11
    1464:	0124                	.insn	2, 0x0124
    1466:	532d                	.insn	2, 0x532d
    1468:	0005                	.insn	2, 0x0005
    146a:	1300                	.insn	2, 0x1300
    146c:	2a0c                	.insn	2, 0x2a0c
    146e:	3401                	.insn	2, 0x3401
    1470:	0125                	.insn	2, 0x0125
    1472:	0000                	.insn	2, 0x0000
    1474:	2318                	.insn	2, 0x2318
    1476:	2f01                	.insn	2, 0x2f01
    1478:	0458                	.insn	2, 0x0458
    147a:	0000                	.insn	2, 0x0000
    147c:	3114                	.insn	2, 0x3114
    147e:	0001                	.insn	2, 0x0001
    1480:	1400                	.insn	2, 0x1400
    1482:	0014                	.insn	2, 0x0014
    1484:	0000                	.insn	2, 0x0000
    1486:	3501                	.insn	2, 0x3501
    1488:	1509                	.insn	2, 0x1509
    148a:	0001390b          	.insn	4, 0x0001390b
    148e:	0000                	.insn	2, 0x0000
    1490:	1516                	.insn	2, 0x1516
    1492:	01c4                	.insn	2, 0x01c4
    1494:	0000                	.insn	2, 0x0000
    1496:	011b0f13          	addi	t5,s6,17
    149a:	f53a                	.insn	2, 0xf53a
    149c:	0002                	.insn	2, 0x0002
    149e:	1900                	.insn	2, 0x1900
    14a0:	1200                	.insn	2, 0x1200
    14a2:	9102                	.insn	2, 0x9102
    14a4:	4a012903          	lw	s2,1184(sp)
    14a8:	00ae                	.insn	2, 0x00ae
    14aa:	0000                	.insn	2, 0x0000
    14ac:	012c0e13          	addi	t3,s8,18
    14b0:	0002f54b          	.insn	4, 0x0002f54b
    14b4:	1800                	.insn	2, 0x1800
    14b6:	012d                	.insn	2, 0x012d
    14b8:	583c                	.insn	2, 0x583c
    14ba:	0004                	.insn	2, 0x0004
    14bc:	1900                	.insn	2, 0x1900
    14be:	1301                	.insn	2, 0x1301
    14c0:	2b0d                	.insn	2, 0x2b0d
    14c2:	5801                	.insn	2, 0x5801
    14c4:	02f5                	.insn	2, 0x02f5
    14c6:	0000                	.insn	2, 0x0000
    14c8:	1600                	.insn	2, 0x1600
    14ca:	5c16                	.insn	2, 0x5c16
    14cc:	0000                	.insn	2, 0x0000
    14ce:	1800                	.insn	2, 0x1800
    14d0:	012e                	.insn	2, 0x012e
    14d2:	2562                	.insn	2, 0x2562
    14d4:	0001                	.insn	2, 0x0001
    14d6:	1800                	.insn	2, 0x1800
    14d8:	2566012f          	.insn	4, 0x2566012f
    14dc:	0001                	.insn	2, 0x0001
    14de:	0000                	.insn	2, 0x0000
    14e0:	0219                	.insn	2, 0x0219
    14e2:	012b1013          	slli	zero,s6,0x12
    14e6:	f54e                	.insn	2, 0xf54e
    14e8:	0002                	.insn	2, 0x0002
    14ea:	0000                	.insn	2, 0x0000
    14ec:	0000                	.insn	2, 0x0000
    14ee:	0001cd17          	auipc	s10,0x1c
    14f2:	1700                	.insn	2, 0x1700
    14f4:	0002e217          	auipc	tp,0x2e
    14f8:	1800                	.insn	2, 0x1800
    14fa:	00030417          	auipc	s0,0x30
    14fe:	1900                	.insn	2, 0x1900
    1500:	1a00                	.insn	2, 0x1a00
    1502:	1b4b0213          	addi	tp,s6,436
    1506:	02d8                	.insn	2, 0x02d8
    1508:	0000                	.insn	2, 0x0000
    150a:	001c                	.insn	2, 0x001c
    150c:	dd1d                	.insn	2, 0xdd1d
    150e:	0002                	.insn	2, 0x0002
    1510:	1e00                	.insn	2, 0x1e00
    1512:	0041                	.insn	2, 0x0041
    1514:	0000                	.insn	2, 0x0000
    1516:	141f 3202 02f5      	.insn	6, 0x02f53202141f
    151c:	0000                	.insn	2, 0x0000
    151e:	0001251b          	.insn	4, 0x0001251b
    1522:	1b00                	.insn	2, 0x1b00
    1524:	02f9                	.insn	2, 0x02f9
    1526:	0000                	.insn	2, 0x0000
    1528:	0500                	.insn	2, 0x0500
    152a:	0515                	.insn	2, 0x0515
    152c:	2004                	.insn	2, 0x2004
    152e:	161a                	.insn	2, 0x161a
    1530:	3a02                	.insn	2, 0x3a02
    1532:	0000411b          	.insn	4, 0x411b
    1536:	0000                	.insn	2, 0x0000
    1538:	171f 4702 02f5      	.insn	6, 0x02f54702171f
    153e:	0000                	.insn	2, 0x0000
    1540:	0002d81b          	.insn	4, 0x0002d81b
    1544:	1b00                	.insn	2, 0x1b00
    1546:	02d8                	.insn	2, 0x02d8
    1548:	0000                	.insn	2, 0x0000
    154a:	2100                	.insn	2, 0x2100
    154c:	201a                	.insn	2, 0x201a
    154e:	0000                	.insn	2, 0x0000
    1550:	0100                	.insn	2, 0x0100
    1552:	3152                	.insn	2, 0x3152
    1554:	0001                	.insn	2, 0x0001
    1556:	1500                	.insn	2, 0x1500
    1558:	3911                	.insn	2, 0x3911
    155a:	0001                	.insn	2, 0x0001
    155c:	0000                	.insn	2, 0x0000
    155e:	1b22                	.insn	2, 0x1b22
    1560:	0288                	.insn	2, 0x0288
    1562:	0000                	.insn	2, 0x0000
    1564:	5201                	.insn	2, 0x5201
    1566:	0121                	.insn	2, 0x0121
    1568:	13b0                	.insn	2, 0x13b0
    156a:	b7012a13          	slti	s4,sp,-1168
    156e:	0125                	.insn	2, 0x0125
    1570:	0000                	.insn	2, 0x0000
    1572:	2318                	.insn	2, 0x2318
    1574:	b201                	.insn	2, 0xb201
    1576:	0458                	.insn	2, 0x0458
    1578:	0000                	.insn	2, 0x0000
    157a:	3114                	.insn	2, 0x3114
    157c:	0001                	.insn	2, 0x0001
    157e:	1c00                	.insn	2, 0x1c00
    1580:	0014                	.insn	2, 0x0014
    1582:	0000                	.insn	2, 0x0000
    1584:	b801                	.insn	2, 0xb801
    1586:	1509                	.insn	2, 0x1509
    1588:	3912                	.insn	2, 0x3912
    158a:	0001                	.insn	2, 0x0001
    158c:	0000                	.insn	2, 0x0000
    158e:	1d16                	.insn	2, 0x1d16
    1590:	01c4                	.insn	2, 0x01c4
    1592:	0000                	.insn	2, 0x0000
    1594:	011b1613          	slli	a2,s6,0x11
    1598:	f5bd                	.insn	2, 0xf5bd
    159a:	0002                	.insn	2, 0x0002
    159c:	1900                	.insn	2, 0x1900
    159e:	25141303          	lh	t1,593(s0) # 3174b <start-0x3ce8b5>
    15a2:	e401                	.insn	2, 0xe401
    15a4:	0125                	.insn	2, 0x0125
    15a6:	0000                	.insn	2, 0x0000
    15a8:	01301513          	slli	a0,zero,0x13
    15ac:	25e1                	.insn	2, 0x25e1
    15ae:	0001                	.insn	2, 0x0001
    15b0:	1300                	.insn	2, 0x1300
    15b2:	e9012417          	auipc	s0,0xe9012
    15b6:	0125                	.insn	2, 0x0125
    15b8:	0000                	.insn	2, 0x0000
    15ba:	2d18                	.insn	2, 0x2d18
    15bc:	bf01                	.insn	2, 0xbf01
    15be:	0458                	.insn	2, 0x0458
    15c0:	0000                	.insn	2, 0x0000
    15c2:	2e18                	.insn	2, 0x2e18
    15c4:	d901                	.insn	2, 0xd901
    15c6:	0125                	.insn	2, 0x0125
    15c8:	0000                	.insn	2, 0x0000
    15ca:	2f18                	.insn	2, 0x2f18
    15cc:	dd01                	.insn	2, 0xdd01
    15ce:	0125                	.insn	2, 0x0125
    15d0:	0000                	.insn	2, 0x0000
    15d2:	3114                	.insn	2, 0x3114
    15d4:	0001                	.insn	2, 0x0001
    15d6:	1d00                	.insn	2, 0x1d00
    15d8:	0014                	.insn	2, 0x0014
    15da:	0000                	.insn	2, 0x0000
    15dc:	e701                	.insn	2, 0xe701
    15de:	5b012313          	slti	t1,sp,1456
    15e2:	0139                	.insn	2, 0x0139
    15e4:	0000                	.insn	2, 0x0000
    15e6:	1900                	.insn	2, 0x1900
    15e8:	1304                	.insn	2, 0x1304
    15ea:	2b18                	.insn	2, 0x2b18
    15ec:	ca01                	.insn	2, 0xca01
    15ee:	02f5                	.insn	2, 0x02f5
    15f0:	0000                	.insn	2, 0x0000
    15f2:	1900                	.insn	2, 0x1900
    15f4:	1305                	.insn	2, 0x1305
    15f6:	2b19                	.insn	2, 0x2b19
    15f8:	d101                	.insn	2, 0xd101
    15fa:	02f5                	.insn	2, 0x02f5
    15fc:	0000                	.insn	2, 0x0000
    15fe:	0000                	.insn	2, 0x0000
    1600:	1700                	.insn	2, 0x1700
    1602:	01cd                	.insn	2, 0x01cd
    1604:	0000                	.insn	2, 0x0000
    1606:	171e                	.insn	2, 0x171e
    1608:	02e2                	.insn	2, 0x02e2
    160a:	0000                	.insn	2, 0x0000
    160c:	171f 02cd 0000      	.insn	6, 0x02cd171f
    1612:	1720                	.insn	2, 0x1720
    1614:	02fa                	.insn	2, 0x02fa
    1616:	0000                	.insn	2, 0x0000
    1618:	1721                	.insn	2, 0x1721
    161a:	02fa                	.insn	2, 0x02fa
    161c:	0000                	.insn	2, 0x0000
    161e:	1722                	.insn	2, 0x1722
    1620:	02fa                	.insn	2, 0x02fa
    1622:	0000                	.insn	2, 0x0000
    1624:	02fa1723          	sh	a5,46(s4) # 30428 <start-0x3cfbd8>
    1628:	0000                	.insn	2, 0x0000
    162a:	1724                	.insn	2, 0x1724
    162c:	02fa                	.insn	2, 0x02fa
    162e:	0000                	.insn	2, 0x0000
    1630:	1725                	.insn	2, 0x1725
    1632:	02fa                	.insn	2, 0x02fa
    1634:	0000                	.insn	2, 0x0000
    1636:	1726                	.insn	2, 0x1726
    1638:	02fa                	.insn	2, 0x02fa
    163a:	0000                	.insn	2, 0x0000
    163c:	02fa1727          	.insn	4, 0x02fa1727
    1640:	0000                	.insn	2, 0x0000
    1642:	1728                	.insn	2, 0x1728
    1644:	02fa                	.insn	2, 0x02fa
    1646:	0000                	.insn	2, 0x0000
    1648:	1729                	.insn	2, 0x1729
    164a:	02fa                	.insn	2, 0x02fa
    164c:	0000                	.insn	2, 0x0000
    164e:	172a                	.insn	2, 0x172a
    1650:	02cd                	.insn	2, 0x02cd
    1652:	0000                	.insn	2, 0x0000
    1654:	02fa172b          	.insn	4, 0x02fa172b
    1658:	0000                	.insn	2, 0x0000
    165a:	172c                	.insn	2, 0x172c
    165c:	02fa                	.insn	2, 0x02fa
    165e:	0000                	.insn	2, 0x0000
    1660:	002d                	.insn	2, 0x002d
    1662:	1824                	.insn	2, 0x1824
    1664:	f701                	.insn	2, 0xf701
    1666:	02f5                	.insn	2, 0x02f5
    1668:	0000                	.insn	2, 0x0000
    166a:	f801190f          	.insn	4, 0xf801190f
    166e:	02d8                	.insn	2, 0x02d8
    1670:	0000                	.insn	2, 0x0000
    1672:	f9011a0f          	.insn	4, 0xf9011a0f
    1676:	0458                	.insn	2, 0x0458
    1678:	0000                	.insn	2, 0x0000
    167a:	1b18                	.insn	2, 0x1b18
    167c:	fb01                	.insn	2, 0xfb01
    167e:	02f5                	.insn	2, 0x02f5
    1680:	0000                	.insn	2, 0x0000
    1682:	1c25                	.insn	2, 0x1c25
    1684:	0101                	.insn	2, 0x0101
    1686:	f501                	.insn	2, 0xf501
    1688:	0002                	.insn	2, 0x0002
    168a:	0000                	.insn	2, 0x0000
    168c:	d41d                	.insn	2, 0xd41d
    168e:	0000                	.insn	2, 0x0000
    1690:	2600                	.insn	2, 0x2600
    1692:	b02e                	.insn	2, 0xb02e
    1694:	01000003          	lb	zero,16(zero) # 10 <start-0x3ffff0>
    1698:	2252                	.insn	2, 0x2252
    169a:	1d01                	.insn	2, 0x1d01
    169c:	f501                	.insn	2, 0xf501
    169e:	0002                	.insn	2, 0x0002
    16a0:	2700                	.insn	2, 0x2700
    16a2:	191a                	.insn	2, 0x191a
    16a4:	1d01                	.insn	2, 0x1d01
    16a6:	d801                	.insn	2, 0xd801
    16a8:	0002                	.insn	2, 0x0002
    16aa:	2800                	.insn	2, 0x2800
    16ac:	9102                	.insn	2, 0x9102
    16ae:	290d                	.insn	2, 0x290d
    16b0:	2a01                	.insn	2, 0x2a01
    16b2:	5801                	.insn	2, 0x5801
    16b4:	0005                	.insn	2, 0x0005
    16b6:	2900                	.insn	2, 0x2900
    16b8:	2a1c                	.insn	2, 0x2a1c
    16ba:	2401                	.insn	2, 0x2401
    16bc:	2501                	.insn	2, 0x2501
    16be:	0001                	.insn	2, 0x0001
    16c0:	2500                	.insn	2, 0x2500
    16c2:	011f0123          	sb	a7,2(t5)
    16c6:	0458                	.insn	2, 0x0458
    16c8:	0000                	.insn	2, 0x0000
    16ca:	312a                	.insn	2, 0x312a
    16cc:	0001                	.insn	2, 0x0001
    16ce:	2f00                	.insn	2, 0x2f00
    16d0:	0014                	.insn	2, 0x0014
    16d2:	0000                	.insn	2, 0x0000
    16d4:	2501                	.insn	2, 0x2501
    16d6:	0901                	.insn	2, 0x0901
    16d8:	1b15                	.insn	2, 0x1b15
    16da:	0139                	.insn	2, 0x0139
    16dc:	0000                	.insn	2, 0x0000
    16de:	2a00                	.insn	2, 0x2a00
    16e0:	042e                	.insn	2, 0x042e
    16e2:	0000                	.insn	2, 0x0000
    16e4:	d830                	.insn	2, 0xd830
    16e6:	0000                	.insn	2, 0x0000
    16e8:	0100                	.insn	2, 0x0100
    16ea:	012c                	.insn	2, 0x012c
    16ec:	1505                	.insn	2, 0x1505
    16ee:	361d                	.insn	2, 0x361d
    16f0:	0004                	.insn	2, 0x0004
    16f2:	2300                	.insn	2, 0x2300
    16f4:	9f0d9103          	lh	sp,-1552(s11)
    16f8:	043e                	.insn	2, 0x043e
    16fa:	0000                	.insn	2, 0x0000
    16fc:	04461e2b          	.insn	4, 0x04461e2b
    1700:	0000                	.insn	2, 0x0000
    1702:	044e1f2b          	.insn	4, 0x044e1f2b
    1706:	0000                	.insn	2, 0x0000
    1708:	1600                	.insn	2, 0x1600
    170a:	4831                	.insn	2, 0x4831
    170c:	0002                	.insn	2, 0x0002
    170e:	2900                	.insn	2, 0x2900
    1710:	1b20                	.insn	2, 0x1b20
    1712:	2e01                	.insn	2, 0x2e01
    1714:	f501                	.insn	2, 0xf501
    1716:	0002                	.insn	2, 0x0002
    1718:	1600                	.insn	2, 0x1600
    171a:	4831                	.insn	2, 0x4831
    171c:	0002                	.insn	2, 0x0002
    171e:	2900                	.insn	2, 0x2900
    1720:	2d21                	.insn	2, 0x2d21
    1722:	3001                	.insn	2, 0x3001
    1724:	5801                	.insn	2, 0x5801
    1726:	0004                	.insn	2, 0x0004
    1728:	1900                	.insn	2, 0x1900
    172a:	2906                	.insn	2, 0x2906
    172c:	2b22                	.insn	2, 0x2b22
    172e:	3601                	.insn	2, 0x3601
    1730:	f501                	.insn	2, 0xf501
    1732:	0002                	.insn	2, 0x0002
    1734:	0000                	.insn	2, 0x0000
    1736:	0719                	.insn	2, 0x0719
    1738:	2329                	.insn	2, 0x2329
    173a:	013a012b          	.insn	4, 0x013a012b
    173e:	02f5                	.insn	2, 0x02f5
    1740:	0000                	.insn	2, 0x0000
    1742:	0000                	.insn	2, 0x0000
    1744:	1700                	.insn	2, 0x1700
    1746:	01cd                	.insn	2, 0x01cd
    1748:	0000                	.insn	2, 0x0000
    174a:	1732                	.insn	2, 0x1732
    174c:	02e2                	.insn	2, 0x02e2
    174e:	0000                	.insn	2, 0x0000
    1750:	02cd1733          	mulh	a4,s10,a2
    1754:	0000                	.insn	2, 0x0000
    1756:	1734                	.insn	2, 0x1734
    1758:	02cd                	.insn	2, 0x02cd
    175a:	0000                	.insn	2, 0x0000
    175c:	1735                	.insn	2, 0x1735
    175e:	0536                	.insn	2, 0x0536
    1760:	0000                	.insn	2, 0x0000
    1762:	1736                	.insn	2, 0x1736
    1764:	02cd                	.insn	2, 0x02cd
    1766:	0000                	.insn	2, 0x0000
    1768:	1d1f0037          	lui	zero,0x1d1f0
    176c:	3102                	.insn	2, 0x3102
    176e:	0125                	.insn	2, 0x0125
    1770:	0000                	.insn	2, 0x0000
    1772:	0001251b          	.insn	4, 0x0001251b
    1776:	1b00                	.insn	2, 0x1b00
    1778:	0549                	.insn	2, 0x0549
    177a:	0000                	.insn	2, 0x0000
    177c:	1d00                	.insn	2, 0x1d00
    177e:	054e                	.insn	2, 0x054e
    1780:	0000                	.insn	2, 0x0000
    1782:	d41e                	.insn	2, 0xd41e
    1784:	0000                	.insn	2, 0x0000
    1786:	1d00                	.insn	2, 0x1d00
    1788:	0125                	.insn	2, 0x0125
    178a:	0000                	.insn	2, 0x0000
    178c:	0000d403          	lhu	s0,0(ra)
    1790:	0400                	.insn	2, 0x0400
    1792:	0045                	.insn	2, 0x0045
    1794:	0000                	.insn	2, 0x0000
    1796:	00000b 	.3byte	0x00000b

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
  2c:	009f 0000 9804      	.insn	6, 0x98040000009f
  32:	040bc00b          	.insn	4, 0x040bc00b
  36:	0d90                	.insn	2, 0x0d90
  38:	0d9c                	.insn	2, 0x0d9c
  3a:	0400                	.insn	2, 0x0400
  3c:	09f4                	.insn	2, 0x09f4
  3e:	0a9c                	.insn	2, 0x0a9c
  40:	c404                	.insn	2, 0xc404
  42:	000bd00b          	.insn	4, 0x000bd00b
  46:	a804                	.insn	2, 0xa804
  48:	f409                	.insn	2, 0xf409
  4a:	0409                	.insn	2, 0x0409
  4c:	0aa4                	.insn	2, 0x0aa4
  4e:	0b98                	.insn	2, 0x0b98
  50:	dc04                	.insn	2, 0xdc04
  52:	040bec0b          	.insn	4, 0x040bec0b
  56:	0c9c                	.insn	2, 0x0c9c
  58:	0ce0                	.insn	2, 0x0ce0
  5a:	d004                	.insn	2, 0xd004
  5c:	940d                	.insn	2, 0x940d
  5e:	000e                	.insn	2, 0x000e
  60:	b004                	.insn	2, 0xb004
  62:	f409                	.insn	2, 0xf409
  64:	0409                	.insn	2, 0x0409
  66:	0ab4                	.insn	2, 0x0ab4
  68:	0ab8                	.insn	2, 0x0ab8
  6a:	9c04                	.insn	2, 0x9c04
  6c:	e00c                	.insn	2, 0xe00c
  6e:	000c                	.insn	2, 0x000c
  70:	9c04                	.insn	2, 0x9c04
  72:	ac0c                	.insn	2, 0xac0c
  74:	040c                	.insn	2, 0x040c
  76:	0cb0                	.insn	2, 0x0cb0
  78:	0cb8                	.insn	2, 0x0cb8
  7a:	c004                	.insn	2, 0xc004
  7c:	e00c                	.insn	2, 0xe00c
  7e:	000c                	.insn	2, 0x000c
  80:	d804                	.insn	2, 0xd804
  82:	980a                	.insn	2, 0x980a
  84:	0bdc040b          	.insn	4, 0x0bdc040b
  88:	0be0                	.insn	2, 0x0be0
  8a:	d004                	.insn	2, 0xd004
  8c:	940d                	.insn	2, 0x940d
  8e:	000e                	.insn	2, 0x000e
  90:	d004                	.insn	2, 0xd004
  92:	e00d                	.insn	2, 0xe00d
  94:	040d                	.insn	2, 0x040d
  96:	0de4                	.insn	2, 0x0de4
  98:	0dec                	.insn	2, 0x0dec
  9a:	f404                	.insn	2, 0xf404
  9c:	940d                	.insn	2, 0x940d
  9e:	000e                	.insn	2, 0x000e
  a0:	f804                	.insn	2, 0xf804
  a2:	a002                	.insn	2, 0xa002
  a4:	0404                	.insn	2, 0x0404
  a6:	04a4                	.insn	2, 0x04a4
  a8:	04e4                	.insn	2, 0x04e4
  aa:	0400                	.insn	2, 0x0400
  ac:	11c4                	.insn	2, 0x11c4
  ae:	11e0                	.insn	2, 0x11e0
  b0:	e404                	.insn	2, 0xe404
  b2:	ec11                	.insn	2, 0xec11
  b4:	0411                	.insn	2, 0x0411
  b6:	11f4                	.insn	2, 0x11f4
  b8:	1294                	.insn	2, 0x1294
  ba:	cb00                	.insn	2, 0xcb00
  bc:	0000                	.insn	2, 0x0000
  be:	0500                	.insn	2, 0x0500
  c0:	0400                	.insn	2, 0x0400
  c2:	0a00                	.insn	2, 0x0a00
  c4:	0000                	.insn	2, 0x0000
  c6:	2800                	.insn	2, 0x2800
  c8:	0000                	.insn	2, 0x0000
  ca:	3500                	.insn	2, 0x3500
  cc:	0000                	.insn	2, 0x0000
  ce:	4200                	.insn	2, 0x4200
  d0:	0000                	.insn	2, 0x0000
  d2:	4f00                	.insn	2, 0x4f00
  d4:	0000                	.insn	2, 0x0000
  d6:	5c00                	.insn	2, 0x5c00
  d8:	0000                	.insn	2, 0x0000
  da:	6900                	.insn	2, 0x6900
  dc:	0000                	.insn	2, 0x0000
  de:	7600                	.insn	2, 0x7600
  e0:	0000                	.insn	2, 0x0000
  e2:	8300                	.insn	2, 0x8300
  e4:	0000                	.insn	2, 0x0000
  e6:	ae00                	.insn	2, 0xae00
  e8:	0000                	.insn	2, 0x0000
  ea:	bb00                	.insn	2, 0xbb00
  ec:	0000                	.insn	2, 0x0000
  ee:	0100                	.insn	2, 0x0100
  f0:	0405                	.insn	2, 0x0405
  f2:	01d8                	.insn	2, 0x01d8
  f4:	01f4                	.insn	2, 0x01f4
  f6:	9004                	.insn	2, 0x9004
  f8:	0003ac03          	lw	s8,0(t2)
  fc:	0501                	.insn	2, 0x0501
  fe:	f404                	.insn	2, 0xf404
 100:	8001                	.insn	2, 0x8001
 102:	0402                	.insn	2, 0x0402
 104:	03ac                	.insn	2, 0x03ac
 106:	03b8                	.insn	2, 0x03b8
 108:	0100                	.insn	2, 0x0100
 10a:	0405                	.insn	2, 0x0405
 10c:	0280                	.insn	2, 0x0280
 10e:	029c                	.insn	2, 0x029c
 110:	b804                	.insn	2, 0xb804
 112:	0003c403          	lbu	s0,0(t2)
 116:	0501                	.insn	2, 0x0501
 118:	f004                	.insn	2, 0xf004
 11a:	fc04                	.insn	2, 0xfc04
 11c:	0404                	.insn	2, 0x0404
 11e:	05fc                	.insn	2, 0x05fc
 120:	0688                	.insn	2, 0x0688
 122:	0100                	.insn	2, 0x0100
 124:	0405                	.insn	2, 0x0405
 126:	04fc                	.insn	2, 0x04fc
 128:	0588                	.insn	2, 0x0588
 12a:	8804                	.insn	2, 0x8804
 12c:	9406                	.insn	2, 0x9406
 12e:	0006                	.insn	2, 0x0006
 130:	0501                	.insn	2, 0x0501
 132:	8804                	.insn	2, 0x8804
 134:	9405                	.insn	2, 0x9405
 136:	0405                	.insn	2, 0x0405
 138:	0694                	.insn	2, 0x0694
 13a:	06a0                	.insn	2, 0x06a0
 13c:	0100                	.insn	2, 0x0100
 13e:	0405                	.insn	2, 0x0405
 140:	09d4                	.insn	2, 0x09d4
 142:	09f8                	.insn	2, 0x09f8
 144:	c404                	.insn	2, 0xc404
 146:	b00c                	.insn	2, 0xb00c
 148:	000d                	.insn	2, 0x000d
 14a:	0501                	.insn	2, 0x0501
 14c:	b004                	.insn	2, 0xb004
 14e:	bc0a                	.insn	2, 0xbc0a
 150:	040a                	.insn	2, 0x040a
 152:	0acc                	.insn	2, 0x0acc
 154:	0ad8                	.insn	2, 0x0ad8
 156:	e804                	.insn	2, 0xe804
 158:	f40a                	.insn	2, 0xf40a
 15a:	040a                	.insn	2, 0x040a
 15c:	0b84                	.insn	2, 0x0b84
 15e:	0b90                	.insn	2, 0x0b90
 160:	a004                	.insn	2, 0xa004
 162:	040bac0b          	.insn	4, 0x040bac0b
 166:	0bbc                	.insn	2, 0x0bbc
 168:	0bc8                	.insn	2, 0x0bc8
 16a:	d404                	.insn	2, 0xd404
 16c:	040be00b          	.insn	4, 0x040be00b
 170:	0be4                	.insn	2, 0x0be4
 172:	0bf0                	.insn	2, 0x0bf0
 174:	0100                	.insn	2, 0x0100
 176:	0405                	.insn	2, 0x0405
 178:	0fc8                	.insn	2, 0x0fc8
 17a:	109c                	.insn	2, 0x109c
 17c:	a004                	.insn	2, 0xa004
 17e:	a810                	.insn	2, 0xa810
 180:	0010                	.insn	2, 0x0010
 182:	11b00503          	lb	a0,283(zero) # 11b <start-0x3ffee5>
 186:	001c3c03          	.insn	4, 0x001c3c03
 18a:	008a                	.insn	2, 0x008a
 18c:	0000                	.insn	2, 0x0000
 18e:	0005                	.insn	2, 0x0005
 190:	0004                	.insn	2, 0x0004
 192:	0008                	.insn	2, 0x0008
 194:	0000                	.insn	2, 0x0000
 196:	0020                	.insn	2, 0x0020
 198:	0000                	.insn	2, 0x0000
 19a:	0000002b          	.insn	4, 0x002b
 19e:	0000003b          	.insn	4, 0x003b
 1a2:	0046                	.insn	2, 0x0046
 1a4:	0000                	.insn	2, 0x0000
 1a6:	0051                	.insn	2, 0x0051
 1a8:	0000                	.insn	2, 0x0000
 1aa:	005c                	.insn	2, 0x005c
 1ac:	0000                	.insn	2, 0x0000
 1ae:	00000067          	jr	zero # 0 <start-0x400000>
 1b2:	00000077          	.insn	4, 0x0077
 1b6:	8404                	.insn	2, 0x8404
 1b8:	ac05                	.insn	2, 0xac05
 1ba:	0405                	.insn	2, 0x0405
 1bc:	05b8                	.insn	2, 0x05b8
 1be:	08c8                	.insn	2, 0x08c8
 1c0:	0400                	.insn	2, 0x0400
 1c2:	0584                	.insn	2, 0x0584
 1c4:	0590                	.insn	2, 0x0590
 1c6:	b004                	.insn	2, 0xb004
 1c8:	0407b407          	.insn	4, 0x0407b407
 1cc:	07bc                	.insn	2, 0x07bc
 1ce:	07e8                	.insn	2, 0x07e8
 1d0:	0400                	.insn	2, 0x0400
 1d2:	05cc                	.insn	2, 0x05cc
 1d4:	06ac                	.insn	2, 0x06ac
 1d6:	b804                	.insn	2, 0xb804
 1d8:	a806                	.insn	2, 0xa806
 1da:	ac040007          	.insn	4, 0xac040007
 1de:	f40a                	.insn	2, 0xf40a
 1e0:	040a                	.insn	2, 0x040a
 1e2:	0b80                	.insn	2, 0x0b80
 1e4:	0df0                	.insn	2, 0x0df0
 1e6:	0400                	.insn	2, 0x0400
 1e8:	0b94                	.insn	2, 0x0b94
 1ea:	0bd0                	.insn	2, 0x0bd0
 1ec:	dc04                	.insn	2, 0xdc04
 1ee:	000cd40b          	.insn	4, 0x000cd40b
 1f2:	e804                	.insn	2, 0xe804
 1f4:	880c                	.insn	2, 0x880c
 1f6:	040d                	.insn	2, 0x040d
 1f8:	0dcc                	.insn	2, 0x0dcc
 1fa:	0df0                	.insn	2, 0x0df0
 1fc:	0400                	.insn	2, 0x0400
 1fe:	12f8                	.insn	2, 0x12f8
 200:	1398                	.insn	2, 0x1398
 202:	a004                	.insn	2, 0xa004
 204:	0413a813          	slti	a6,t2,65
 208:	13f8                	.insn	2, 0x13f8
 20a:	1480                	.insn	2, 0x1480
 20c:	0400                	.insn	2, 0x0400
 20e:	13a8                	.insn	2, 0x13a8
 210:	13f8                	.insn	2, 0x13f8
 212:	8804                	.insn	2, 0x8804
 214:	9414                	.insn	2, 0x9414
 216:	0014                	.insn	2, 0x0014

Disassembly of section .debug_str_offsets:

00000000 <.debug_str_offsets>:
   0:	00e4                	.insn	2, 0x00e4
   2:	0000                	.insn	2, 0x0000
   4:	0005                	.insn	2, 0x0005
   6:	0000                	.insn	2, 0x0000
   8:	0000                	.insn	2, 0x0000
   a:	0000                	.insn	2, 0x0000
   c:	00000027          	.insn	4, 0x0027
  10:	00000033          	add	zero,zero,zero
  14:	0000022b          	.insn	4, 0x022b
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
  2c:	01ba                	.insn	2, 0x01ba
  2e:	0000                	.insn	2, 0x0000
  30:	00d1                	.insn	2, 0x00d1
  32:	0000                	.insn	2, 0x0000
  34:	009c                	.insn	2, 0x009c
  36:	0000                	.insn	2, 0x0000
  38:	000001c7          	.insn	4, 0x01c7
  3c:	0376                	.insn	2, 0x0376
  3e:	0000                	.insn	2, 0x0000
  40:	0211                	.insn	2, 0x0211
  42:	0000                	.insn	2, 0x0000
  44:	00a6                	.insn	2, 0x00a6
  46:	0000                	.insn	2, 0x0000
  48:	00ad                	.insn	2, 0x00ad
  4a:	0000                	.insn	2, 0x0000
  4c:	00b5                	.insn	2, 0x00b5
  4e:	0000                	.insn	2, 0x0000
  50:	00c5                	.insn	2, 0x00c5
  52:	0000                	.insn	2, 0x0000
  54:	00d5                	.insn	2, 0x00d5
  56:	0000                	.insn	2, 0x0000
  58:	00dc                	.insn	2, 0x00dc
  5a:	0000                	.insn	2, 0x0000
  5c:	00e6                	.insn	2, 0x00e6
  5e:	0000                	.insn	2, 0x0000
  60:	00f4                	.insn	2, 0x00f4
  62:	0000                	.insn	2, 0x0000
  64:	0101                	.insn	2, 0x0101
  66:	0000                	.insn	2, 0x0000
  68:	0115                	.insn	2, 0x0115
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
  88:	0179                	.insn	2, 0x0179
  8a:	0000                	.insn	2, 0x0000
  8c:	0182                	.insn	2, 0x0182
  8e:	0000                	.insn	2, 0x0000
  90:	00000187          	.insn	4, 0x0187
  94:	019a                	.insn	2, 0x019a
  96:	0000                	.insn	2, 0x0000
  98:	01ac                	.insn	2, 0x01ac
  9a:	0000                	.insn	2, 0x0000
  9c:	01b1                	.insn	2, 0x01b1
  9e:	0000                	.insn	2, 0x0000
  a0:	01bc                	.insn	2, 0x01bc
  a2:	0000                	.insn	2, 0x0000
  a4:	01c4                	.insn	2, 0x01c4
  a6:	0000                	.insn	2, 0x0000
  a8:	01c9                	.insn	2, 0x01c9
  aa:	0000                	.insn	2, 0x0000
  ac:	01d1                	.insn	2, 0x01d1
  ae:	0000                	.insn	2, 0x0000
  b0:	01d6                	.insn	2, 0x01d6
  b2:	0000                	.insn	2, 0x0000
  b4:	0171                	.insn	2, 0x0171
  b6:	0000                	.insn	2, 0x0000
  b8:	01ce                	.insn	2, 0x01ce
  ba:	0000                	.insn	2, 0x0000
  bc:	01da                	.insn	2, 0x01da
  be:	0000                	.insn	2, 0x0000
  c0:	00da                	.insn	2, 0x00da
  c2:	0000                	.insn	2, 0x0000
  c4:	01e6                	.insn	2, 0x01e6
  c6:	0000                	.insn	2, 0x0000
  c8:	01f2                	.insn	2, 0x01f2
  ca:	0000                	.insn	2, 0x0000
  cc:	000001eb          	.insn	4, 0x01eb
  d0:	03fc                	.insn	2, 0x03fc
  d2:	0000                	.insn	2, 0x0000
  d4:	01f6                	.insn	2, 0x01f6
  d6:	0000                	.insn	2, 0x0000
  d8:	0200                	.insn	2, 0x0200
  da:	0000                	.insn	2, 0x0000
  dc:	00000207          	.insn	4, 0x0207
  e0:	00000213          	li	tp,0
  e4:	01d8                	.insn	2, 0x01d8
  e6:	0000                	.insn	2, 0x0000
  e8:	0150                	.insn	2, 0x0150
  ea:	0000                	.insn	2, 0x0000
  ec:	0005                	.insn	2, 0x0005
  ee:	0000                	.insn	2, 0x0000
  f0:	0000                	.insn	2, 0x0000
  f2:	0000                	.insn	2, 0x0000
  f4:	00000217          	auipc	tp,0x0
  f8:	00000033          	add	zero,zero,zero
  fc:	0000022b          	.insn	4, 0x022b
 100:	0068                	.insn	2, 0x0068
 102:	0000                	.insn	2, 0x0000
 104:	0222                	.insn	2, 0x0222
 106:	0000                	.insn	2, 0x0000
 108:	0230                	.insn	2, 0x0230
 10a:	0000                	.insn	2, 0x0000
 10c:	007c                	.insn	2, 0x007c
 10e:	0000                	.insn	2, 0x0000
 110:	0089                	.insn	2, 0x0089
 112:	0000                	.insn	2, 0x0000
 114:	0085                	.insn	2, 0x0085
 116:	0000                	.insn	2, 0x0000
 118:	0238                	.insn	2, 0x0238
 11a:	0000                	.insn	2, 0x0000
 11c:	0240                	.insn	2, 0x0240
 11e:	0000                	.insn	2, 0x0000
 120:	0246                	.insn	2, 0x0246
 122:	0000                	.insn	2, 0x0000
 124:	0000024b          	.insn	4, 0x024b
 128:	0250                	.insn	2, 0x0250
 12a:	0000                	.insn	2, 0x0000
 12c:	0255                	.insn	2, 0x0255
 12e:	0000                	.insn	2, 0x0000
 130:	0258                	.insn	2, 0x0258
 132:	0000                	.insn	2, 0x0000
 134:	0000025b          	.insn	4, 0x025b
 138:	025e                	.insn	2, 0x025e
 13a:	0000                	.insn	2, 0x0000
 13c:	011a                	.insn	2, 0x011a
 13e:	0000                	.insn	2, 0x0000
 140:	01d8                	.insn	2, 0x01d8
 142:	0000                	.insn	2, 0x0000
 144:	0261                	.insn	2, 0x0261
 146:	0000                	.insn	2, 0x0000
 148:	0264                	.insn	2, 0x0264
 14a:	0000                	.insn	2, 0x0000
 14c:	00ad                	.insn	2, 0x00ad
 14e:	0000                	.insn	2, 0x0000
 150:	0171                	.insn	2, 0x0171
 152:	0000                	.insn	2, 0x0000
 154:	0268                	.insn	2, 0x0268
 156:	0000                	.insn	2, 0x0000
 158:	000001c7          	.insn	4, 0x01c7
 15c:	00f9                	.insn	2, 0x00f9
 15e:	0000                	.insn	2, 0x0000
 160:	0272                	.insn	2, 0x0272
 162:	0000                	.insn	2, 0x0000
 164:	0000027b          	.insn	4, 0x027b
 168:	0286                	.insn	2, 0x0286
 16a:	0000                	.insn	2, 0x0000
 16c:	0295                	.insn	2, 0x0295
 16e:	0000                	.insn	2, 0x0000
 170:	029c                	.insn	2, 0x029c
 172:	0000                	.insn	2, 0x0000
 174:	000000eb          	.insn	4, 0x00eb
 178:	0174                	.insn	2, 0x0174
 17a:	0000                	.insn	2, 0x0000
 17c:	0115                	.insn	2, 0x0115
 17e:	0000                	.insn	2, 0x0000
 180:	00f4                	.insn	2, 0x00f4
 182:	0000                	.insn	2, 0x0000
 184:	0101                	.insn	2, 0x0101
 186:	0000                	.insn	2, 0x0000
 188:	00a6                	.insn	2, 0x00a6
 18a:	0000                	.insn	2, 0x0000
 18c:	02a4                	.insn	2, 0x02a4
 18e:	0000                	.insn	2, 0x0000
 190:	0121                	.insn	2, 0x0121
 192:	0000                	.insn	2, 0x0000
 194:	0132                	.insn	2, 0x0132
 196:	0000                	.insn	2, 0x0000
 198:	000002b7          	lui	t0,0x0
 19c:	00e6                	.insn	2, 0x00e6
 19e:	0000                	.insn	2, 0x0000
 1a0:	02cd                	.insn	2, 0x02cd
 1a2:	0000                	.insn	2, 0x0000
 1a4:	00d5                	.insn	2, 0x00d5
 1a6:	0000                	.insn	2, 0x0000
 1a8:	00dc                	.insn	2, 0x00dc
 1aa:	0000                	.insn	2, 0x0000
 1ac:	0179                	.insn	2, 0x0179
 1ae:	0000                	.insn	2, 0x0000
 1b0:	0182                	.insn	2, 0x0182
 1b2:	0000                	.insn	2, 0x0000
 1b4:	02d4                	.insn	2, 0x02d4
 1b6:	0000                	.insn	2, 0x0000
 1b8:	00c5                	.insn	2, 0x00c5
 1ba:	0000                	.insn	2, 0x0000
 1bc:	02dc                	.insn	2, 0x02dc
 1be:	0000                	.insn	2, 0x0000
 1c0:	00b5                	.insn	2, 0x00b5
 1c2:	0000                	.insn	2, 0x0000
 1c4:	02f1                	.insn	2, 0x02f1
 1c6:	0000                	.insn	2, 0x0000
 1c8:	000002f7          	.insn	4, 0x02f7
 1cc:	0300                	.insn	2, 0x0300
 1ce:	0000                	.insn	2, 0x0000
 1d0:	0309                	.insn	2, 0x0309
 1d2:	0000                	.insn	2, 0x0000
 1d4:	0312                	.insn	2, 0x0312
 1d6:	0000                	.insn	2, 0x0000
 1d8:	041a                	.insn	2, 0x041a
 1da:	0000                	.insn	2, 0x0000
 1dc:	031e                	.insn	2, 0x031e
 1de:	0000                	.insn	2, 0x0000
 1e0:	03fc                	.insn	2, 0x03fc
 1e2:	0000                	.insn	2, 0x0000
 1e4:	03c1                	.insn	2, 0x03c1
 1e6:	0000                	.insn	2, 0x0000
 1e8:	0406                	.insn	2, 0x0406
 1ea:	0000                	.insn	2, 0x0000
 1ec:	0320                	.insn	2, 0x0320
 1ee:	0000                	.insn	2, 0x0000
 1f0:	032a                	.insn	2, 0x032a
 1f2:	0000                	.insn	2, 0x0000
 1f4:	0330                	.insn	2, 0x0330
 1f6:	0000                	.insn	2, 0x0000
 1f8:	037e                	.insn	2, 0x037e
 1fa:	0000                	.insn	2, 0x0000
 1fc:	0342                	.insn	2, 0x0342
 1fe:	0000                	.insn	2, 0x0000
 200:	0346                	.insn	2, 0x0346
 202:	0000                	.insn	2, 0x0000
 204:	034c                	.insn	2, 0x034c
 206:	0000                	.insn	2, 0x0000
 208:	034e                	.insn	2, 0x034e
 20a:	0000                	.insn	2, 0x0000
 20c:	01ba                	.insn	2, 0x01ba
 20e:	0000                	.insn	2, 0x0000
 210:	0355                	.insn	2, 0x0355
 212:	0000                	.insn	2, 0x0000
 214:	01f9                	.insn	2, 0x01f9
 216:	0000                	.insn	2, 0x0000
 218:	01e6                	.insn	2, 0x01e6
 21a:	0000                	.insn	2, 0x0000
 21c:	01d6                	.insn	2, 0x01d6
 21e:	0000                	.insn	2, 0x0000
 220:	0359                	.insn	2, 0x0359
 222:	0000                	.insn	2, 0x0000
 224:	035d                	.insn	2, 0x035d
 226:	0000                	.insn	2, 0x0000
 228:	0211                	.insn	2, 0x0211
 22a:	0000                	.insn	2, 0x0000
 22c:	0361                	.insn	2, 0x0361
 22e:	0000                	.insn	2, 0x0000
 230:	0364                	.insn	2, 0x0364
 232:	0000                	.insn	2, 0x0000
 234:	00000367          	jalr	t1,zero # 0 <start-0x400000>
 238:	0376                	.insn	2, 0x0376
 23a:	0000                	.insn	2, 0x0000
 23c:	00c8                	.insn	2, 0x00c8
 23e:	0000                	.insn	2, 0x0000
 240:	0005                	.insn	2, 0x0005
 242:	0000                	.insn	2, 0x0000
 244:	0000                	.insn	2, 0x0000
 246:	0000                	.insn	2, 0x0000
 248:	036c                	.insn	2, 0x036c
 24a:	0000                	.insn	2, 0x0000
 24c:	00000033          	add	zero,zero,zero
 250:	0000022b          	.insn	4, 0x022b
 254:	0068                	.insn	2, 0x0068
 256:	0000                	.insn	2, 0x0000
 258:	0378                	.insn	2, 0x0378
 25a:	0000                	.insn	2, 0x0000
 25c:	0222                	.insn	2, 0x0222
 25e:	0000                	.insn	2, 0x0000
 260:	0230                	.insn	2, 0x0230
 262:	0000                	.insn	2, 0x0000
 264:	0382                	.insn	2, 0x0382
 266:	0000                	.insn	2, 0x0000
 268:	038a                	.insn	2, 0x038a
 26a:	0000                	.insn	2, 0x0000
 26c:	007c                	.insn	2, 0x007c
 26e:	0000                	.insn	2, 0x0000
 270:	0089                	.insn	2, 0x0089
 272:	0000                	.insn	2, 0x0000
 274:	00000393          	li	t2,0
 278:	039d                	.insn	2, 0x039d
 27a:	0000                	.insn	2, 0x0000
 27c:	03a8                	.insn	2, 0x03a8
 27e:	0000                	.insn	2, 0x0000
 280:	03b5                	.insn	2, 0x03b5
 282:	0000                	.insn	2, 0x0000
 284:	03c9                	.insn	2, 0x03c9
 286:	0000                	.insn	2, 0x0000
 288:	0286                	.insn	2, 0x0286
 28a:	0000                	.insn	2, 0x0000
 28c:	03c1                	.insn	2, 0x03c1
 28e:	0000                	.insn	2, 0x0000
 290:	00a6                	.insn	2, 0x00a6
 292:	0000                	.insn	2, 0x0000
 294:	02dc                	.insn	2, 0x02dc
 296:	0000                	.insn	2, 0x0000
 298:	0085                	.insn	2, 0x0085
 29a:	0000                	.insn	2, 0x0000
 29c:	00ad                	.insn	2, 0x00ad
 29e:	0000                	.insn	2, 0x0000
 2a0:	00d5                	.insn	2, 0x00d5
 2a2:	0000                	.insn	2, 0x0000
 2a4:	03d6                	.insn	2, 0x03d6
 2a6:	0000                	.insn	2, 0x0000
 2a8:	03e6                	.insn	2, 0x03e6
 2aa:	0000                	.insn	2, 0x0000
 2ac:	00d1                	.insn	2, 0x00d1
 2ae:	0000                	.insn	2, 0x0000
 2b0:	041a                	.insn	2, 0x041a
 2b2:	0000                	.insn	2, 0x0000
 2b4:	000003eb          	.insn	4, 0x03eb
 2b8:	000002b7          	lui	t0,0x0
 2bc:	015e                	.insn	2, 0x015e
 2be:	0000                	.insn	2, 0x0000
 2c0:	0149                	.insn	2, 0x0149
 2c2:	0000                	.insn	2, 0x0000
 2c4:	0000027b          	.insn	4, 0x027b
 2c8:	0155                	.insn	2, 0x0155
 2ca:	0000                	.insn	2, 0x0000
 2cc:	0168                	.insn	2, 0x0168
 2ce:	0000                	.insn	2, 0x0000
 2d0:	037e                	.insn	2, 0x037e
 2d2:	0000                	.insn	2, 0x0000
 2d4:	0406                	.insn	2, 0x0406
 2d6:	0000                	.insn	2, 0x0000
 2d8:	0291                	.insn	2, 0x0291
 2da:	0000                	.insn	2, 0x0000
 2dc:	000003ef          	jal	t2,2dc <start-0x3ffd24>
 2e0:	03f8                	.insn	2, 0x03f8
 2e2:	0000                	.insn	2, 0x0000
 2e4:	0402                	.insn	2, 0x0402
 2e6:	0000                	.insn	2, 0x0000
 2e8:	03e1                	.insn	2, 0x03e1
 2ea:	0000                	.insn	2, 0x0000
 2ec:	0000040b          	.insn	4, 0x040b
 2f0:	031e                	.insn	2, 0x031e
 2f2:	0000                	.insn	2, 0x0000
 2f4:	0414                	.insn	2, 0x0414
 2f6:	0000                	.insn	2, 0x0000
 2f8:	00000353          	.insn	4, 0x0353
 2fc:	0416                	.insn	2, 0x0416
 2fe:	0000                	.insn	2, 0x0000
 300:	041c                	.insn	2, 0x041c
 302:	0000                	.insn	2, 0x0000
 304:	0422                	.insn	2, 0x0422
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
  a6:	7270                	.insn	2, 0x7270
  a8:	6e69                	.insn	2, 0x6e69
  aa:	6674                	.insn	2, 0x6674
  ac:	7000                	.insn	2, 0x7000
  ae:	7475                	.insn	2, 0x7475
  b0:	72616863          	bltu	sp,t1,7e0 <start-0x3ff820>
  b4:	7000                	.insn	2, 0x7000
  b6:	5f6c6c6f          	jal	s8,c66ac <start-0x339954>
  ba:	74697773          	csrrci	a4,0x746,18
  be:	615f6863          	bltu	t5,s5,6ce <start-0x3ff932>
  c2:	6970                	.insn	2, 0x6970
  c4:	6700                	.insn	2, 0x6700
  c6:	7465                	.insn	2, 0x7465
  c8:	72616863          	bltu	sp,t1,7f8 <start-0x3ff808>
  cc:	745f 6d69 6f65      	.insn	6, 0x6f656d69745f
  d2:	7475                	.insn	2, 0x7475
  d4:	7300                	.insn	2, 0x7300
  d6:	7274                	.insn	2, 0x7274
  d8:	00706d63          	bltu	zero,t2,f2 <start-0x3fff0e>
  dc:	6170                	.insn	2, 0x6170
  de:	7372                	.insn	2, 0x7372
  e0:	5f65                	.insn	2, 0x5f65
  e2:	3375                	.insn	2, 0x3375
  e4:	0032                	.insn	2, 0x0032
  e6:	6c6c6163          	bltu	s8,t1,7a8 <start-0x3ff858>
  ea:	645f 6d75 5f70      	.insn	6, 0x5f706d75645f
  f0:	7061                	.insn	2, 0x7061
  f2:	0069                	.insn	2, 0x0069
  f4:	6c6c6163          	bltu	s8,t1,7b6 <start-0x3ff84a>
  f8:	6d5f 6369 615f      	.insn	6, 0x615f63696d5f
  fe:	6970                	.insn	2, 0x6970
 100:	6300                	.insn	2, 0x6300
 102:	6c61                	.insn	2, 0x6c61
 104:	5f6c                	.insn	2, 0x5f6c
 106:	696d                	.insn	2, 0x696d
 108:	72775f63          	bge	a4,t2,846 <start-0x3ff7ba>
 10c:	7469                	.insn	2, 0x7469
 10e:	5f65                	.insn	2, 0x5f65
 110:	6966                	.insn	2, 0x6966
 112:	656c                	.insn	2, 0x656c
 114:	6300                	.insn	2, 0x6300
 116:	6c61                	.insn	2, 0x6c61
 118:	5f6c                	.insn	2, 0x5f6c
 11a:	615f6173          	csrrsi	sp,htimedeltah,30
 11e:	6970                	.insn	2, 0x6970
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
 174:	7865                	.insn	2, 0x7865
 176:	7469                	.insn	2, 0x7469
 178:	6900                	.insn	2, 0x6900
 17a:	72705f73          	csrrwi	t5,mhpmevent7h,0
 17e:	6d69                	.insn	2, 0x6d69
 180:	0065                	.insn	2, 0x0065
 182:	6f62                	.insn	2, 0x6f62
 184:	44006c6f          	jal	s8,65c4 <start-0x3f9a3c>
 188:	54415f57          	.insn	4, 0x54415f57
 18c:	5f45                	.insn	2, 0x5f45
 18e:	6e75                	.insn	2, 0x6e75
 190:	6e676973          	csrrsi	s2,0x6e6,14
 194:	6465                	.insn	2, 0x6465
 196:	335f 0032 5744      	.insn	6, 0x57440032335f
 19c:	415f 4554 755f      	.insn	6, 0x755f4554415f
 1a2:	736e                	.insn	2, 0x736e
 1a4:	6769                	.insn	2, 0x6769
 1a6:	656e                	.insn	2, 0x656e
 1a8:	5f64                	.insn	2, 0x5f64
 1aa:	0031                	.insn	2, 0x0031
 1ac:	616d                	.insn	2, 0x616d
 1ae:	6e69                	.insn	2, 0x6e69
 1b0:	6300                	.insn	2, 0x6300
 1b2:	646d                	.insn	2, 0x646d
 1b4:	705f 6972 656d      	.insn	6, 0x656d6972705f
 1ba:	6d630073          	.insn	4, 0x6d630073
 1be:	6c64                	.insn	2, 0x6c64
 1c0:	6e69                	.insn	2, 0x6e69
 1c2:	0065                	.insn	2, 0x0065
 1c4:	7261                	.insn	2, 0x7261
 1c6:	70007667          	.insn	4, 0x70007667
 1ca:	6572                	.insn	2, 0x6572
 1cc:	5f76                	.insn	2, 0x5f76
 1ce:	61007773          	csrrci	a4,0x610,0
 1d2:	6772                	.insn	2, 0x6772
 1d4:	656c0063          	beq	s8,s6,814 <start-0x3ff7ec>
 1d8:	006e                	.insn	2, 0x006e
 1da:	5f327773          	csrrci	a4,0x5f3,4
 1de:	7270                	.insn	2, 0x7270
 1e0:	7365                	.insn	2, 0x7365
 1e2:	00646573          	csrrsi	a0,0x6,8
 1e6:	6461                	.insn	2, 0x6461
 1e8:	7264                	.insn	2, 0x7264
 1ea:	6d00                	.insn	2, 0x6d00
 1ec:	7461                	.insn	2, 0x7461
 1ee:	6972                	.insn	2, 0x6972
 1f0:	5f78                	.insn	2, 0x5f78
 1f2:	616d                	.insn	2, 0x616d
 1f4:	0078                	.insn	2, 0x0078
 1f6:	735f6473          	csrrsi	s0,mhpmevent21h,30
 1fa:	6365                	.insn	2, 0x6365
 1fc:	6f74                	.insn	2, 0x6f74
 1fe:	0072                	.insn	2, 0x0072
 200:	7270                	.insn	2, 0x7270
 202:	74706d6f          	jal	s10,7148 <start-0x3f8eb8>
 206:	7300                	.insn	2, 0x7300
 208:	705f3177          	.insn	4, 0x705f3177
 20c:	6572                	.insn	2, 0x6572
 20e:	64657373          	csrrci	t1,hviprio1,10
 212:	7600                	.insn	2, 0x7600
 214:	6c61                	.insn	2, 0x6c61
 216:	7300                	.insn	2, 0x7300
 218:	6372                	.insn	2, 0x6372
 21a:	6573752f          	.insn	4, 0x6573752f
 21e:	2e72                	.insn	2, 0x2e72
 220:	6e750063          	beq	a0,t2,900 <start-0x3ff700>
 224:	6e676973          	csrrsi	s2,0x6e6,14
 228:	6465                	.insn	2, 0x6465
 22a:	6320                	.insn	2, 0x6320
 22c:	6168                	.insn	2, 0x6168
 22e:	0072                	.insn	2, 0x0072
 230:	6975                	.insn	2, 0x6975
 232:	746e                	.insn	2, 0x746e
 234:	5f38                	.insn	2, 0x5f38
 236:	0074                	.insn	2, 0x0074
 238:	63737973          	csrrci	s2,0x637,6
 23c:	6c61                	.insn	2, 0x6c61
 23e:	006c                	.insn	2, 0x006c
 240:	6e737973          	csrrci	s2,0x6e7,6
 244:	7261006f          	j	1096a <start-0x3ef696>
 248:	61003067          	.insn	4, 0x61003067
 24c:	6772                	.insn	2, 0x6772
 24e:	0031                	.insn	2, 0x0031
 250:	7261                	.insn	2, 0x7261
 252:	61003267          	.insn	4, 0x61003267
 256:	0030                	.insn	2, 0x0030
 258:	3161                	.insn	2, 0x3161
 25a:	6100                	.insn	2, 0x6100
 25c:	0032                	.insn	2, 0x0032
 25e:	3361                	.insn	2, 0x3361
 260:	6100                	.insn	2, 0x6100
 262:	0034                	.insn	2, 0x0034
 264:	6572                	.insn	2, 0x6572
 266:	0074                	.insn	2, 0x0074
 268:	7270                	.insn	2, 0x7270
 26a:	6e69                	.insn	2, 0x6e69
 26c:	5f74                	.insn	2, 0x5f74
 26e:	6e69                	.insn	2, 0x6e69
 270:	0074                	.insn	2, 0x0074
 272:	696d                	.insn	2, 0x696d
 274:	70615f63          	bge	sp,t1,992 <start-0x3ff66e>
 278:	3269                	.insn	2, 0x3269
 27a:	6600                	.insn	2, 0x6600
 27c:	7461                	.insn	2, 0x7461
 27e:	665f3233          	.insn	4, 0x665f3233
 282:	6e69                	.insn	2, 0x6e69
 284:	0064                	.insn	2, 0x0064
 286:	73756c63          	bltu	a0,s7,9be <start-0x3ff642>
 28a:	6574                	.insn	2, 0x6574
 28c:	5f72                	.insn	2, 0x5f72
 28e:	6f74                	.insn	2, 0x6f74
 290:	6c5f 6162 7300      	.insn	6, 0x730061626c5f
 296:	5f64                	.insn	2, 0x5f64
 298:	7061                	.insn	2, 0x7061
 29a:	0069                	.insn	2, 0x0069
 29c:	615f6473          	csrrsi	s0,htimedeltah,30
 2a0:	6970                	.insn	2, 0x6970
 2a2:	0032                	.insn	2, 0x0032
 2a4:	6c6c6163          	bltu	s8,t1,966 <start-0x3ff69a>
 2a8:	6d5f 6369 775f      	.insn	6, 0x775f63696d5f
 2ae:	6972                	.insn	2, 0x6972
 2b0:	6574                	.insn	2, 0x6574
 2b2:	615f 6970 6300      	.insn	6, 0x63006970615f
 2b8:	6c61                	.insn	2, 0x6c61
 2ba:	5f6c                	.insn	2, 0x5f6c
 2bc:	775f6473          	csrrsi	s0,0x775,30
 2c0:	6972                	.insn	2, 0x6972
 2c2:	6574                	.insn	2, 0x6574
 2c4:	625f 6675 615f      	.insn	6, 0x615f6675625f
 2ca:	6970                	.insn	2, 0x6970
 2cc:	7300                	.insn	2, 0x7300
 2ce:	7274                	.insn	2, 0x7274
 2d0:	00797063          	bgeu	s2,t2,2d0 <start-0x3ffd30>
 2d4:	63746567          	.insn	4, 0x63746567
 2d8:	6168                	.insn	2, 0x6168
 2da:	0072                	.insn	2, 0x0072
 2dc:	6c6c6163          	bltu	s8,t1,99e <start-0x3ff662>
 2e0:	735f 5f64 6572      	.insn	6, 0x65725f64735f
 2e6:	6461                	.insn	2, 0x6461
 2e8:	625f 6675 615f      	.insn	6, 0x615f6675625f
 2ee:	6970                	.insn	2, 0x6970
 2f0:	7300                	.insn	2, 0x7300
 2f2:	6174                	.insn	2, 0x6174
 2f4:	7472                	.insn	2, 0x7472
 2f6:	6d00                	.insn	2, 0x6d00
 2f8:	7461                	.insn	2, 0x7461
 2fa:	6972                	.insn	2, 0x6972
 2fc:	5f78                	.insn	2, 0x5f78
 2fe:	0041                	.insn	2, 0x0041
 300:	616d                	.insn	2, 0x616d
 302:	7274                	.insn	2, 0x7274
 304:	7869                	.insn	2, 0x7869
 306:	425f 6d00 7461      	.insn	6, 0x74616d00425f
 30c:	6972                	.insn	2, 0x6972
 30e:	5f78                	.insn	2, 0x5f78
 310:	616d0043          	.insn	4, 0x616d0043
 314:	7274                	.insn	2, 0x7274
 316:	7869                	.insn	2, 0x7869
 318:	735f 7a69 0065      	.insn	6, 0x00657a69735f
 31e:	006a                	.insn	2, 0x006a
 320:	72617473          	csrrci	s0,mhpmevent6h,2
 324:	5f74                	.insn	2, 0x5f74
 326:	626c                	.insn	2, 0x626c
 328:	0061                	.insn	2, 0x0061
 32a:	6176                	.insn	2, 0x6176
 32c:	6772                	.insn	2, 0x6772
 32e:	5f5f0073          	.insn	4, 0x5f5f0073
 332:	7562                	.insn	2, 0x7562
 334:	6c69                	.insn	2, 0x6c69
 336:	6974                	.insn	2, 0x6974
 338:	5f6e                	.insn	2, 0x5f6e
 33a:	6176                	.insn	2, 0x6176
 33c:	6c5f 7369 0074      	.insn	6, 0x007473696c5f
 342:	6d66                	.insn	2, 0x6d66
 344:	0074                	.insn	2, 0x0074
 346:	6176                	.insn	2, 0x6176
 348:	756c                	.insn	2, 0x756c
 34a:	0065                	.insn	2, 0x0065
 34c:	0075                	.insn	2, 0x0075
 34e:	696e                	.insn	2, 0x696e
 350:	6262                	.insn	2, 0x6262
 352:	656c                	.insn	2, 0x656c
 354:	6500                	.insn	2, 0x6500
 356:	646e                	.insn	2, 0x646e
 358:	6400                	.insn	2, 0x6400
 35a:	73007473          	csrrci	s0,mhpmevent16h,0
 35e:	6372                	.insn	2, 0x6372
 360:	7300                	.insn	2, 0x7300
 362:	0031                	.insn	2, 0x0031
 364:	62003273          	csrrc	tp,0x620,zero
 368:	7361                	.insn	2, 0x7361
 36a:	0065                	.insn	2, 0x0065
 36c:	2f637273          	csrrci	tp,0x2f6,6
 370:	6166                	.insn	2, 0x6166
 372:	3374                	.insn	2, 0x3374
 374:	2e32                	.insn	2, 0x2e32
 376:	61660063          	beq	a2,s6,976 <start-0x3ff68a>
 37a:	3374                	.insn	2, 0x3374
 37c:	5f32                	.insn	2, 0x5f32
 37e:	7562                	.insn	2, 0x7562
 380:	0066                	.insn	2, 0x0066
 382:	61665f67          	.insn	4, 0x61665f67
 386:	3374                	.insn	2, 0x3374
 388:	0032                	.insn	2, 0x0032
 38a:	6170                	.insn	2, 0x6170
 38c:	7472                	.insn	2, 0x7472
 38e:	6c5f 6162 6600      	.insn	6, 0x660061626c5f
 394:	7461                	.insn	2, 0x7461
 396:	625f 6765 6e69      	.insn	6, 0x6e696765625f
 39c:	6400                	.insn	2, 0x6400
 39e:	7461                	.insn	2, 0x7461
 3a0:	5f61                	.insn	2, 0x5f61
 3a2:	6562                	.insn	2, 0x6562
 3a4:	006e6967          	.insn	4, 0x006e6967
 3a8:	6f72                	.insn	2, 0x6f72
 3aa:	635f746f          	jal	s0,f81de <start-0x307e22>
 3ae:	756c                	.insn	2, 0x756c
 3b0:	72657473          	csrrci	s0,mhpmevent6h,10
 3b4:	7300                	.insn	2, 0x7300
 3b6:	6365                	.insn	2, 0x6365
 3b8:	6f74                	.insn	2, 0x6f74
 3ba:	7372                	.insn	2, 0x7372
 3bc:	705f 7265 635f      	.insn	6, 0x635f7265705f
 3c2:	756c                	.insn	2, 0x756c
 3c4:	72657473          	csrrci	s0,mhpmevent6h,10
 3c8:	6600                	.insn	2, 0x6600
 3ca:	7461                	.insn	2, 0x7461
 3cc:	695f3233          	.insn	4, 0x695f3233
 3d0:	666e                	.insn	2, 0x666e
 3d2:	00745f6f          	jal	t5,45bd8 <start-0x3ba428>
 3d6:	6166                	.insn	2, 0x6166
 3d8:	3374                	.insn	2, 0x3374
 3da:	5f32                	.insn	2, 0x5f32
 3dc:	616d                	.insn	2, 0x616d
 3de:	735f656b          	.insn	4, 0x735f656b
 3e2:	6f68                	.insn	2, 0x6f68
 3e4:	7472                	.insn	2, 0x7472
 3e6:	616e                	.insn	2, 0x616e
 3e8:	656d                	.insn	2, 0x656d
 3ea:	7000                	.insn	2, 0x7000
 3ec:	7200736f          	jal	t1,7b0c <start-0x3f84f4>
 3f0:	7365                	.insn	2, 0x7365
 3f2:	7265                	.insn	2, 0x7265
 3f4:	6576                	.insn	2, 0x6576
 3f6:	0064                	.insn	2, 0x0064
 3f8:	6166                	.insn	2, 0x6166
 3fa:	5f74                	.insn	2, 0x5f74
 3fc:	6e756f63          	bltu	a0,t2,afa <start-0x3ff506>
 400:	0074                	.insn	2, 0x0074
 402:	6166                	.insn	2, 0x6166
 404:	5f74                	.insn	2, 0x5f74
 406:	657a6973          	csrrsi	s2,hviprio2h,20
 40a:	7200                	.insn	2, 0x7200
 40c:	5f746f6f          	jal	t5,47202 <start-0x3b8dfe>
 410:	626c                	.insn	2, 0x626c
 412:	0061                	.insn	2, 0x0061
 414:	6c63006b          	.insn	4, 0x6c63006b
 418:	685f 0069 6c63      	.insn	6, 0x6c630069685f
 41e:	6c5f 006f 6c63      	.insn	6, 0x6c63006f6c5f
	...

Disassembly of section .debug_addr:

00000000 <.debug_addr>:
   0:	0204                	.insn	2, 0x0204
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
  90:	20dc                	.insn	2, 0x20dc
  92:	0040                	.insn	2, 0x0040
  94:	004020e7          	.insn	4, 0x004020e7
  98:	20ec                	.insn	2, 0x20ec
  9a:	0040                	.insn	2, 0x0040
  9c:	20f1                	.insn	2, 0x20f1
  9e:	0040                	.insn	2, 0x0040
  a0:	004020f3          	csrr	ra,0x4
  a4:	2108                	.insn	2, 0x2108
  a6:	0040                	.insn	2, 0x0040
  a8:	210c                	.insn	2, 0x210c
  aa:	0040                	.insn	2, 0x0040
  ac:	001c                	.insn	2, 0x001c
  ae:	0040                	.insn	2, 0x0040
  b0:	00a4                	.insn	2, 0x00a4
  b2:	0040                	.insn	2, 0x0040
  b4:	0740                	.insn	2, 0x0740
  b6:	0040                	.insn	2, 0x0040
  b8:	06c4                	.insn	2, 0x06c4
  ba:	0040                	.insn	2, 0x0040
  bc:	068c                	.insn	2, 0x068c
  be:	0040                	.insn	2, 0x0040
  c0:	0610                	.insn	2, 0x0610
  c2:	0040                	.insn	2, 0x0040
  c4:	0064                	.insn	2, 0x0064
  c6:	0040                	.insn	2, 0x0040
  c8:	00b4                	.insn	2, 0x00b4
  ca:	0040                	.insn	2, 0x0040
  cc:	00c4                	.insn	2, 0x00c4
  ce:	0040                	.insn	2, 0x0040
  d0:	00d0                	.insn	2, 0x00d0
  d2:	0040                	.insn	2, 0x0040
  d4:	00dc                	.insn	2, 0x00dc
  d6:	0040                	.insn	2, 0x0040
  d8:	00e8                	.insn	2, 0x00e8
  da:	0040                	.insn	2, 0x0040
  dc:	00f4                	.insn	2, 0x00f4
  de:	0040                	.insn	2, 0x0040
  e0:	0100                	.insn	2, 0x0100
  e2:	0040                	.insn	2, 0x0040
  e4:	010c                	.insn	2, 0x010c
  e6:	0040                	.insn	2, 0x0040
  e8:	0118                	.insn	2, 0x0118
  ea:	0040                	.insn	2, 0x0040
  ec:	0124                	.insn	2, 0x0124
  ee:	0040                	.insn	2, 0x0040
  f0:	0130                	.insn	2, 0x0130
  f2:	0040                	.insn	2, 0x0040
  f4:	013c                	.insn	2, 0x013c
  f6:	0040                	.insn	2, 0x0040
  f8:	0148                	.insn	2, 0x0148
  fa:	0040                	.insn	2, 0x0040
  fc:	0154                	.insn	2, 0x0154
  fe:	0040                	.insn	2, 0x0040
 100:	0160                	.insn	2, 0x0160
 102:	0040                	.insn	2, 0x0040
 104:	016c                	.insn	2, 0x016c
 106:	0040                	.insn	2, 0x0040
 108:	0178                	.insn	2, 0x0178
 10a:	0040                	.insn	2, 0x0040
 10c:	018c                	.insn	2, 0x018c
 10e:	0040                	.insn	2, 0x0040
 110:	01a8                	.insn	2, 0x01a8
 112:	0040                	.insn	2, 0x0040
 114:	01c8                	.insn	2, 0x01c8
 116:	0040                	.insn	2, 0x0040
 118:	01e8                	.insn	2, 0x01e8
 11a:	0040                	.insn	2, 0x0040
 11c:	01f0                	.insn	2, 0x01f0
 11e:	0040                	.insn	2, 0x0040
 120:	0250                	.insn	2, 0x0250
 122:	0040                	.insn	2, 0x0040
 124:	025c                	.insn	2, 0x025c
 126:	0040                	.insn	2, 0x0040
 128:	0270                	.insn	2, 0x0270
 12a:	0040                	.insn	2, 0x0040
 12c:	0320                	.insn	2, 0x0320
 12e:	0040                	.insn	2, 0x0040
 130:	0338                	.insn	2, 0x0338
 132:	0040                	.insn	2, 0x0040
 134:	0350                	.insn	2, 0x0350
 136:	0040                	.insn	2, 0x0040
 138:	036c                	.insn	2, 0x036c
 13a:	0040                	.insn	2, 0x0040
 13c:	0384                	.insn	2, 0x0384
 13e:	0040                	.insn	2, 0x0040
 140:	039c                	.insn	2, 0x039c
 142:	0040                	.insn	2, 0x0040
 144:	03b4                	.insn	2, 0x03b4
 146:	0040                	.insn	2, 0x0040
 148:	03cc                	.insn	2, 0x03cc
 14a:	0040                	.insn	2, 0x0040
 14c:	03e4                	.insn	2, 0x03e4
 14e:	0040                	.insn	2, 0x0040
 150:	03fc                	.insn	2, 0x03fc
 152:	0040                	.insn	2, 0x0040
 154:	0414                	.insn	2, 0x0414
 156:	0040                	.insn	2, 0x0040
 158:	042c                	.insn	2, 0x042c
 15a:	0040                	.insn	2, 0x0040
 15c:	0444                	.insn	2, 0x0444
 15e:	0040                	.insn	2, 0x0040
 160:	045c                	.insn	2, 0x045c
 162:	0040                	.insn	2, 0x0040
 164:	0474                	.insn	2, 0x0474
 166:	0040                	.insn	2, 0x0040
 168:	048c                	.insn	2, 0x048c
 16a:	0040                	.insn	2, 0x0040
 16c:	04a4                	.insn	2, 0x04a4
 16e:	0040                	.insn	2, 0x0040
 170:	04bc                	.insn	2, 0x04bc
 172:	0040                	.insn	2, 0x0040
 174:	0520                	.insn	2, 0x0520
 176:	0040                	.insn	2, 0x0040
 178:	0548                	.insn	2, 0x0548
 17a:	0040                	.insn	2, 0x0040
 17c:	056c                	.insn	2, 0x056c
 17e:	0040                	.insn	2, 0x0040
 180:	05c4                	.insn	2, 0x05c4
 182:	0040                	.insn	2, 0x0040
 184:	05ec                	.insn	2, 0x05ec
 186:	0040                	.insn	2, 0x0040
 188:	0604                	.insn	2, 0x0604
 18a:	0040                	.insn	2, 0x0040
 18c:	0620                	.insn	2, 0x0620
 18e:	0040                	.insn	2, 0x0040
 190:	0628                	.insn	2, 0x0628
 192:	0040                	.insn	2, 0x0040
 194:	069c                	.insn	2, 0x069c
 196:	0040                	.insn	2, 0x0040
 198:	06a4                	.insn	2, 0x06a4
 19a:	0040                	.insn	2, 0x0040
 19c:	06b8                	.insn	2, 0x06b8
 19e:	0040                	.insn	2, 0x0040
 1a0:	06d4                	.insn	2, 0x06d4
 1a2:	0040                	.insn	2, 0x0040
 1a4:	06dc                	.insn	2, 0x06dc
 1a6:	0040                	.insn	2, 0x0040
 1a8:	0750                	.insn	2, 0x0750
 1aa:	0040                	.insn	2, 0x0040
 1ac:	0774                	.insn	2, 0x0774
 1ae:	0040                	.insn	2, 0x0040
 1b0:	0780                	.insn	2, 0x0780
 1b2:	0040                	.insn	2, 0x0040
 1b4:	0798                	.insn	2, 0x0798
 1b6:	0040                	.insn	2, 0x0040
 1b8:	07a4                	.insn	2, 0x07a4
 1ba:	0040                	.insn	2, 0x0040
 1bc:	07c0                	.insn	2, 0x07c0
 1be:	0040                	.insn	2, 0x0040
 1c0:	07e0                	.insn	2, 0x07e0
 1c2:	0040                	.insn	2, 0x0040
 1c4:	07f4                	.insn	2, 0x07f4
 1c6:	0040                	.insn	2, 0x0040
 1c8:	0808                	.insn	2, 0x0808
 1ca:	0040                	.insn	2, 0x0040
 1cc:	081c                	.insn	2, 0x081c
 1ce:	0040                	.insn	2, 0x0040
 1d0:	0830                	.insn	2, 0x0830
 1d2:	0040                	.insn	2, 0x0040
 1d4:	084c                	.insn	2, 0x084c
 1d6:	0040                	.insn	2, 0x0040
 1d8:	0860                	.insn	2, 0x0860
 1da:	0040                	.insn	2, 0x0040
 1dc:	0874                	.insn	2, 0x0874
 1de:	0040                	.insn	2, 0x0040
 1e0:	0880                	.insn	2, 0x0880
 1e2:	0040                	.insn	2, 0x0040
 1e4:	0880                	.insn	2, 0x0880
 1e6:	0040                	.insn	2, 0x0040
 1e8:	0944                	.insn	2, 0x0944
 1ea:	0040                	.insn	2, 0x0040
 1ec:	0968                	.insn	2, 0x0968
 1ee:	0040                	.insn	2, 0x0040
 1f0:	098c                	.insn	2, 0x098c
 1f2:	0040                	.insn	2, 0x0040
 1f4:	09a0                	.insn	2, 0x09a0
 1f6:	0040                	.insn	2, 0x0040
 1f8:	09b8                	.insn	2, 0x09b8
 1fa:	0040                	.insn	2, 0x0040
 1fc:	09d0                	.insn	2, 0x09d0
 1fe:	0040                	.insn	2, 0x0040
 200:	09f8                	.insn	2, 0x09f8
 202:	0040                	.insn	2, 0x0040
 204:	00b8                	.insn	2, 0x00b8
 206:	0040                	.insn	2, 0x0040
 208:	00fc                	.insn	2, 0x00fc
 20a:	0000                	.insn	2, 0x0000
 20c:	0005                	.insn	2, 0x0005
 20e:	0004                	.insn	2, 0x0004
 210:	2126                	.insn	2, 0x2126
 212:	0040                	.insn	2, 0x0040
 214:	212e                	.insn	2, 0x212e
 216:	0040                	.insn	2, 0x0040
 218:	2141                	.insn	2, 0x2141
 21a:	0040                	.insn	2, 0x0040
 21c:	2159                	.insn	2, 0x2159
 21e:	0040                	.insn	2, 0x0040
 220:	00402177          	.insn	4, 0x00402177
 224:	0a00                	.insn	2, 0x0a00
 226:	0040                	.insn	2, 0x0040
 228:	0a18                	.insn	2, 0x0a18
 22a:	0040                	.insn	2, 0x0040
 22c:	0a28                	.insn	2, 0x0a28
 22e:	0040                	.insn	2, 0x0040
 230:	0a58                	.insn	2, 0x0a58
 232:	0040                	.insn	2, 0x0040
 234:	0b1c                	.insn	2, 0x0b1c
 236:	0040                	.insn	2, 0x0040
 238:	0b30                	.insn	2, 0x0b30
 23a:	0040                	.insn	2, 0x0040
 23c:	0b3c                	.insn	2, 0x0b3c
 23e:	0040                	.insn	2, 0x0040
 240:	0b50                	.insn	2, 0x0b50
 242:	0040                	.insn	2, 0x0040
 244:	0bcc                	.insn	2, 0x0bcc
 246:	0040                	.insn	2, 0x0040
 248:	0bd8                	.insn	2, 0x0bd8
 24a:	0040                	.insn	2, 0x0040
 24c:	0be4                	.insn	2, 0x0be4
 24e:	0040                	.insn	2, 0x0040
 250:	0bf0                	.insn	2, 0x0bf0
 252:	0040                	.insn	2, 0x0040
 254:	0c18                	.insn	2, 0x0c18
 256:	0040                	.insn	2, 0x0040
 258:	0c2c                	.insn	2, 0x0c2c
 25a:	0040                	.insn	2, 0x0040
 25c:	0c38                	.insn	2, 0x0c38
 25e:	0040                	.insn	2, 0x0040
 260:	0c4c                	.insn	2, 0x0c4c
 262:	0040                	.insn	2, 0x0040
 264:	0c94                	.insn	2, 0x0c94
 266:	0040                	.insn	2, 0x0040
 268:	0ca4                	.insn	2, 0x0ca4
 26a:	0040                	.insn	2, 0x0040
 26c:	0cb8                	.insn	2, 0x0cb8
 26e:	0040                	.insn	2, 0x0040
 270:	0cc4                	.insn	2, 0x0cc4
 272:	0040                	.insn	2, 0x0040
 274:	0cd8                	.insn	2, 0x0cd8
 276:	0040                	.insn	2, 0x0040
 278:	0d24                	.insn	2, 0x0d24
 27a:	0040                	.insn	2, 0x0040
 27c:	0d40                	.insn	2, 0x0d40
 27e:	0040                	.insn	2, 0x0040
 280:	0d54                	.insn	2, 0x0d54
 282:	0040                	.insn	2, 0x0040
 284:	0d68                	.insn	2, 0x0d68
 286:	0040                	.insn	2, 0x0040
 288:	0d74                	.insn	2, 0x0d74
 28a:	0040                	.insn	2, 0x0040
 28c:	0e0c                	.insn	2, 0x0e0c
 28e:	0040                	.insn	2, 0x0040
 290:	0da0                	.insn	2, 0x0da0
 292:	0040                	.insn	2, 0x0040
 294:	0dcc                	.insn	2, 0x0dcc
 296:	0040                	.insn	2, 0x0040
 298:	0dec                	.insn	2, 0x0dec
 29a:	0040                	.insn	2, 0x0040
 29c:	0e20                	.insn	2, 0x0e20
 29e:	0040                	.insn	2, 0x0040
 2a0:	1044                	.insn	2, 0x1044
 2a2:	0040                	.insn	2, 0x0040
 2a4:	0eec                	.insn	2, 0x0eec
 2a6:	0040                	.insn	2, 0x0040
 2a8:	1094                	.insn	2, 0x1094
 2aa:	0040                	.insn	2, 0x0040
 2ac:	0f08                	.insn	2, 0x0f08
 2ae:	0040                	.insn	2, 0x0040
 2b0:	0f18                	.insn	2, 0x0f18
 2b2:	0040                	.insn	2, 0x0040
 2b4:	0ff8                	.insn	2, 0x0ff8
 2b6:	0040                	.insn	2, 0x0040
 2b8:	100c                	.insn	2, 0x100c
 2ba:	0040                	.insn	2, 0x0040
 2bc:	1028                	.insn	2, 0x1028
 2be:	0040                	.insn	2, 0x0040
 2c0:	10b4                	.insn	2, 0x10b4
 2c2:	0040                	.insn	2, 0x0040
 2c4:	0eac                	.insn	2, 0x0eac
 2c6:	0040                	.insn	2, 0x0040
 2c8:	10d8                	.insn	2, 0x10d8
 2ca:	0040                	.insn	2, 0x0040
 2cc:	10e4                	.insn	2, 0x10e4
 2ce:	0040                	.insn	2, 0x0040
 2d0:	10f0                	.insn	2, 0x10f0
 2d2:	0040                	.insn	2, 0x0040
 2d4:	10fc                	.insn	2, 0x10fc
 2d6:	0040                	.insn	2, 0x0040
 2d8:	1108                	.insn	2, 0x1108
 2da:	0040                	.insn	2, 0x0040
 2dc:	1114                	.insn	2, 0x1114
 2de:	0040                	.insn	2, 0x0040
 2e0:	1148                	.insn	2, 0x1148
 2e2:	0040                	.insn	2, 0x0040
 2e4:	1178                	.insn	2, 0x1178
 2e6:	0040                	.insn	2, 0x0040
 2e8:	1234                	.insn	2, 0x1234
 2ea:	0040                	.insn	2, 0x0040
 2ec:	1250                	.insn	2, 0x1250
 2ee:	0040                	.insn	2, 0x0040
 2f0:	1270                	.insn	2, 0x1270
 2f2:	0040                	.insn	2, 0x0040
 2f4:	1284                	.insn	2, 0x1284
 2f6:	0040                	.insn	2, 0x0040
 2f8:	1298                	.insn	2, 0x1298
 2fa:	0040                	.insn	2, 0x0040
 2fc:	12a4                	.insn	2, 0x12a4
 2fe:	0040                	.insn	2, 0x0040
 300:	0000                	.insn	2, 0x0000
 302:	0040                	.insn	2, 0x0040
 304:	10c0                	.insn	2, 0x10c0
 306:	0040                	.insn	2, 0x0040
 308:	00e4                	.insn	2, 0x00e4
 30a:	0000                	.insn	2, 0x0000
 30c:	0005                	.insn	2, 0x0005
 30e:	0004                	.insn	2, 0x0004
 310:	2188                	.insn	2, 0x2188
 312:	0040                	.insn	2, 0x0040
 314:	2198                	.insn	2, 0x2198
 316:	0040                	.insn	2, 0x0040
 318:	2160                	.insn	2, 0x2160
 31a:	0040                	.insn	2, 0x0040
 31c:	21a1                	.insn	2, 0x21a1
 31e:	0040                	.insn	2, 0x0040
 320:	1f19                	.insn	2, 0x1f19
 322:	0040                	.insn	2, 0x0040
 324:	21ac                	.insn	2, 0x21ac
 326:	0040                	.insn	2, 0x0040
 328:	21bc                	.insn	2, 0x21bc
 32a:	0040                	.insn	2, 0x0040
 32c:	12b0                	.insn	2, 0x12b0
 32e:	0040                	.insn	2, 0x0040
 330:	130c                	.insn	2, 0x130c
 332:	0040                	.insn	2, 0x0040
 334:	1344                	.insn	2, 0x1344
 336:	0040                	.insn	2, 0x0040
 338:	12cc                	.insn	2, 0x12cc
 33a:	0040                	.insn	2, 0x0040
 33c:	12ec                	.insn	2, 0x12ec
 33e:	0040                	.insn	2, 0x0040
 340:	1300                	.insn	2, 0x1300
 342:	0040                	.insn	2, 0x0040
 344:	1334                	.insn	2, 0x1334
 346:	0040                	.insn	2, 0x0040
 348:	1370                	.insn	2, 0x1370
 34a:	0040                	.insn	2, 0x0040
 34c:	1384                	.insn	2, 0x1384
 34e:	0040                	.insn	2, 0x0040
 350:	139c                	.insn	2, 0x139c
 352:	0040                	.insn	2, 0x0040
 354:	13c4                	.insn	2, 0x13c4
 356:	0040                	.insn	2, 0x0040
 358:	1400                	.insn	2, 0x1400
 35a:	0040                	.insn	2, 0x0040
 35c:	1458                	.insn	2, 0x1458
 35e:	0040                	.insn	2, 0x0040
 360:	14b4                	.insn	2, 0x14b4
 362:	0040                	.insn	2, 0x0040
 364:	1534                	.insn	2, 0x1534
 366:	0040                	.insn	2, 0x0040
 368:	169c                	.insn	2, 0x169c
 36a:	0040                	.insn	2, 0x0040
 36c:	14a0                	.insn	2, 0x14a0
 36e:	0040                	.insn	2, 0x0040
 370:	14d4                	.insn	2, 0x14d4
 372:	0040                	.insn	2, 0x0040
 374:	1558                	.insn	2, 0x1558
 376:	0040                	.insn	2, 0x0040
 378:	16f8                	.insn	2, 0x16f8
 37a:	0040                	.insn	2, 0x0040
 37c:	1718                	.insn	2, 0x1718
 37e:	0040                	.insn	2, 0x0040
 380:	175c                	.insn	2, 0x175c
 382:	0040                	.insn	2, 0x0040
 384:	17dc                	.insn	2, 0x17dc
 386:	0040                	.insn	2, 0x0040
 388:	174c                	.insn	2, 0x174c
 38a:	0040                	.insn	2, 0x0040
 38c:	177c                	.insn	2, 0x177c
 38e:	0040                	.insn	2, 0x0040
 390:	1824                	.insn	2, 0x1824
 392:	0040                	.insn	2, 0x0040
 394:	1894                	.insn	2, 0x1894
 396:	0040                	.insn	2, 0x0040
 398:	18a4                	.insn	2, 0x18a4
 39a:	0040                	.insn	2, 0x0040
 39c:	18b4                	.insn	2, 0x18b4
 39e:	0040                	.insn	2, 0x0040
 3a0:	18c4                	.insn	2, 0x18c4
 3a2:	0040                	.insn	2, 0x0040
 3a4:	18d4                	.insn	2, 0x18d4
 3a6:	0040                	.insn	2, 0x0040
 3a8:	18e4                	.insn	2, 0x18e4
 3aa:	0040                	.insn	2, 0x0040
 3ac:	18f4                	.insn	2, 0x18f4
 3ae:	0040                	.insn	2, 0x0040
 3b0:	1904                	.insn	2, 0x1904
 3b2:	0040                	.insn	2, 0x0040
 3b4:	1918                	.insn	2, 0x1918
 3b6:	0040                	.insn	2, 0x0040
 3b8:	1938                	.insn	2, 0x1938
 3ba:	0040                	.insn	2, 0x0040
 3bc:	1948                	.insn	2, 0x1948
 3be:	0040                	.insn	2, 0x0040
 3c0:	1984                	.insn	2, 0x1984
 3c2:	0040                	.insn	2, 0x0040
 3c4:	1994                	.insn	2, 0x1994
 3c6:	0040                	.insn	2, 0x0040
 3c8:	19a0                	.insn	2, 0x19a0
 3ca:	0040                	.insn	2, 0x0040
 3cc:	19dc                	.insn	2, 0x19dc
 3ce:	0040                	.insn	2, 0x0040
 3d0:	1a0c                	.insn	2, 0x1a0c
 3d2:	0040                	.insn	2, 0x0040
 3d4:	1ae4                	.insn	2, 0x1ae4
 3d6:	0040                	.insn	2, 0x0040
 3d8:	19c8                	.insn	2, 0x19c8
 3da:	0040                	.insn	2, 0x0040
 3dc:	1a04                	.insn	2, 0x1a04
 3de:	0040                	.insn	2, 0x0040
 3e0:	1ce8                	.insn	2, 0x1ce8
 3e2:	0040                	.insn	2, 0x0040
 3e4:	1cf8                	.insn	2, 0x1cf8
 3e6:	0040                	.insn	2, 0x0040
 3e8:	1d08                	.insn	2, 0x1d08
 3ea:	0040                	.insn	2, 0x0040
 3ec:	1d28                	.insn	2, 0x1d28
 3ee:	0040                	.insn	2, 0x0040

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
  20:	0864                	.insn	2, 0x0864
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
  4c:	0880                	.insn	2, 0x0880
  4e:	0040                	.insn	2, 0x0040
  50:	00c4                	.insn	2, 0x00c4
  52:	0000                	.insn	2, 0x0000
  54:	0024                	.insn	2, 0x0024
  56:	0000                	.insn	2, 0x0000
  58:	0000                	.insn	2, 0x0000
  5a:	0000                	.insn	2, 0x0000
  5c:	0944                	.insn	2, 0x0944
  5e:	0040                	.insn	2, 0x0040
  60:	00bc                	.insn	2, 0x00bc
  62:	0000                	.insn	2, 0x0000
  64:	0e44                	.insn	2, 0x0e44
  66:	5420                	.insn	2, 0x5420
  68:	0181                	.insn	2, 0x0181
  6a:	0288                	.insn	2, 0x0288
  6c:	0389                	.insn	2, 0x0389
  6e:	0492                	.insn	2, 0x0492
  70:	98020593          	addi	a1,tp,-1664 # fffffa74 <USER_MAX+0xffaffa74>
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
  98:	0a00                	.insn	2, 0x0a00
  9a:	0040                	.insn	2, 0x0040
  9c:	0018                	.insn	2, 0x0018
  9e:	0000                	.insn	2, 0x0000
  a0:	0018                	.insn	2, 0x0018
  a2:	0000                	.insn	2, 0x0000
  a4:	007c                	.insn	2, 0x007c
  a6:	0000                	.insn	2, 0x0000
  a8:	0a18                	.insn	2, 0x0a18
  aa:	0040                	.insn	2, 0x0040
  ac:	0328                	.insn	2, 0x0328
  ae:	0000                	.insn	2, 0x0000
  b0:	0e4c                	.insn	2, 0x0e4c
  b2:	c090                	.insn	2, 0xc090
  b4:	0301                	.insn	2, 0x0301
  b6:	0318                	.insn	2, 0x0318
  b8:	000e                	.insn	2, 0x000e
  ba:	0000                	.insn	2, 0x0000
  bc:	000c                	.insn	2, 0x000c
  be:	0000                	.insn	2, 0x0000
  c0:	007c                	.insn	2, 0x007c
  c2:	0000                	.insn	2, 0x0000
  c4:	0d40                	.insn	2, 0x0d40
  c6:	0040                	.insn	2, 0x0040
  c8:	0014                	.insn	2, 0x0014
  ca:	0000                	.insn	2, 0x0000
  cc:	000c                	.insn	2, 0x000c
  ce:	0000                	.insn	2, 0x0000
  d0:	007c                	.insn	2, 0x007c
  d2:	0000                	.insn	2, 0x0000
  d4:	0d54                	.insn	2, 0x0d54
  d6:	0040                	.insn	2, 0x0040
  d8:	0014                	.insn	2, 0x0014
  da:	0000                	.insn	2, 0x0000
  dc:	000c                	.insn	2, 0x000c
  de:	0000                	.insn	2, 0x0000
  e0:	007c                	.insn	2, 0x007c
  e2:	0000                	.insn	2, 0x0000
  e4:	0d68                	.insn	2, 0x0d68
  e6:	0040                	.insn	2, 0x0040
  e8:	000c                	.insn	2, 0x000c
  ea:	0000                	.insn	2, 0x0000
  ec:	0024                	.insn	2, 0x0024
  ee:	0000                	.insn	2, 0x0000
  f0:	007c                	.insn	2, 0x007c
  f2:	0000                	.insn	2, 0x0000
  f4:	0d74                	.insn	2, 0x0d74
  f6:	0040                	.insn	2, 0x0040
  f8:	00ac                	.insn	2, 0x00ac
  fa:	0000                	.insn	2, 0x0000
  fc:	0e44                	.insn	2, 0x0e44
  fe:	4c20                	.insn	2, 0x4c20
 100:	0181                	.insn	2, 0x0181
 102:	0288                	.insn	2, 0x0288
 104:	0389                	.insn	2, 0x0389
 106:	020a                	.insn	2, 0x020a
 108:	c158                	.insn	2, 0xc158
 10a:	c9c8                	.insn	2, 0xc9c8
 10c:	0e44                	.insn	2, 0x0e44
 10e:	4400                	.insn	2, 0x4400
 110:	0000000b          	.insn	4, 0x000b
 114:	0024                	.insn	2, 0x0024
 116:	0000                	.insn	2, 0x0000
 118:	007c                	.insn	2, 0x007c
 11a:	0000                	.insn	2, 0x0000
 11c:	0e20                	.insn	2, 0x0e20
 11e:	0040                	.insn	2, 0x0040
 120:	02b8                	.insn	2, 0x02b8
 122:	0000                	.insn	2, 0x0000
 124:	0e44                	.insn	2, 0x0e44
 126:	5040                	.insn	2, 0x5040
 128:	0988                	.insn	2, 0x0988
 12a:	0a89                	.insn	2, 0x0a89
 12c:	0b92                	.insn	2, 0x0b92
 12e:	9c030c93          	addi	s9,t1,-1600
 132:	c802                	.insn	2, 0xc802
 134:	d2c9                	.insn	2, 0xd2c9
 136:	000e44d3          	.insn	4, 0x000e44d3
 13a:	0000                	.insn	2, 0x0000
 13c:	000c                	.insn	2, 0x000c
 13e:	0000                	.insn	2, 0x0000
 140:	007c                	.insn	2, 0x007c
 142:	0000                	.insn	2, 0x0000
 144:	10d8                	.insn	2, 0x10d8
 146:	0040                	.insn	2, 0x0040
 148:	000c                	.insn	2, 0x000c
 14a:	0000                	.insn	2, 0x0000
 14c:	000c                	.insn	2, 0x000c
 14e:	0000                	.insn	2, 0x0000
 150:	007c                	.insn	2, 0x007c
 152:	0000                	.insn	2, 0x0000
 154:	10e4                	.insn	2, 0x10e4
 156:	0040                	.insn	2, 0x0040
 158:	000c                	.insn	2, 0x000c
 15a:	0000                	.insn	2, 0x0000
 15c:	000c                	.insn	2, 0x000c
 15e:	0000                	.insn	2, 0x0000
 160:	007c                	.insn	2, 0x007c
 162:	0000                	.insn	2, 0x0000
 164:	10f0                	.insn	2, 0x10f0
 166:	0040                	.insn	2, 0x0040
 168:	000c                	.insn	2, 0x000c
 16a:	0000                	.insn	2, 0x0000
 16c:	000c                	.insn	2, 0x000c
 16e:	0000                	.insn	2, 0x0000
 170:	007c                	.insn	2, 0x007c
 172:	0000                	.insn	2, 0x0000
 174:	10fc                	.insn	2, 0x10fc
 176:	0040                	.insn	2, 0x0040
 178:	000c                	.insn	2, 0x000c
 17a:	0000                	.insn	2, 0x0000
 17c:	000c                	.insn	2, 0x000c
 17e:	0000                	.insn	2, 0x0000
 180:	007c                	.insn	2, 0x007c
 182:	0000                	.insn	2, 0x0000
 184:	1108                	.insn	2, 0x1108
 186:	0040                	.insn	2, 0x0040
 188:	000c                	.insn	2, 0x000c
 18a:	0000                	.insn	2, 0x0000
 18c:	000c                	.insn	2, 0x000c
 18e:	0000                	.insn	2, 0x0000
 190:	007c                	.insn	2, 0x007c
 192:	0000                	.insn	2, 0x0000
 194:	1114                	.insn	2, 0x1114
 196:	0040                	.insn	2, 0x0040
 198:	0034                	.insn	2, 0x0034
 19a:	0000                	.insn	2, 0x0000
 19c:	000c                	.insn	2, 0x000c
 19e:	0000                	.insn	2, 0x0000
 1a0:	007c                	.insn	2, 0x007c
 1a2:	0000                	.insn	2, 0x0000
 1a4:	1148                	.insn	2, 0x1148
 1a6:	0040                	.insn	2, 0x0040
 1a8:	0030                	.insn	2, 0x0030
 1aa:	0000                	.insn	2, 0x0000
 1ac:	000c                	.insn	2, 0x000c
 1ae:	0000                	.insn	2, 0x0000
 1b0:	007c                	.insn	2, 0x007c
 1b2:	0000                	.insn	2, 0x0000
 1b4:	1178                	.insn	2, 0x1178
 1b6:	0040                	.insn	2, 0x0040
 1b8:	00bc                	.insn	2, 0x00bc
 1ba:	0000                	.insn	2, 0x0000
 1bc:	000c                	.insn	2, 0x000c
 1be:	0000                	.insn	2, 0x0000
 1c0:	007c                	.insn	2, 0x007c
 1c2:	0000                	.insn	2, 0x0000
 1c4:	1234                	.insn	2, 0x1234
 1c6:	0040                	.insn	2, 0x0040
 1c8:	003c                	.insn	2, 0x003c
 1ca:	0000                	.insn	2, 0x0000
 1cc:	000c                	.insn	2, 0x000c
 1ce:	0000                	.insn	2, 0x0000
 1d0:	007c                	.insn	2, 0x007c
 1d2:	0000                	.insn	2, 0x0000
 1d4:	1270                	.insn	2, 0x1270
 1d6:	0040                	.insn	2, 0x0040
 1d8:	0014                	.insn	2, 0x0014
 1da:	0000                	.insn	2, 0x0000
 1dc:	000c                	.insn	2, 0x000c
 1de:	0000                	.insn	2, 0x0000
 1e0:	007c                	.insn	2, 0x007c
 1e2:	0000                	.insn	2, 0x0000
 1e4:	1284                	.insn	2, 0x1284
 1e6:	0040                	.insn	2, 0x0040
 1e8:	0014                	.insn	2, 0x0014
 1ea:	0000                	.insn	2, 0x0000
 1ec:	000c                	.insn	2, 0x000c
 1ee:	0000                	.insn	2, 0x0000
 1f0:	007c                	.insn	2, 0x007c
 1f2:	0000                	.insn	2, 0x0000
 1f4:	1298                	.insn	2, 0x1298
 1f6:	0040                	.insn	2, 0x0040
 1f8:	000c                	.insn	2, 0x000c
 1fa:	0000                	.insn	2, 0x0000
 1fc:	000c                	.insn	2, 0x000c
 1fe:	0000                	.insn	2, 0x0000
 200:	007c                	.insn	2, 0x007c
 202:	0000                	.insn	2, 0x0000
 204:	12a4                	.insn	2, 0x12a4
 206:	0040                	.insn	2, 0x0040
 208:	000c                	.insn	2, 0x000c
 20a:	0000                	.insn	2, 0x0000
 20c:	000c                	.insn	2, 0x000c
 20e:	0000                	.insn	2, 0x0000
 210:	007c                	.insn	2, 0x007c
 212:	0000                	.insn	2, 0x0000
 214:	0000                	.insn	2, 0x0000
 216:	0040                	.insn	2, 0x0040
 218:	001c                	.insn	2, 0x001c
 21a:	0000                	.insn	2, 0x0000
 21c:	0010                	.insn	2, 0x0010
 21e:	0000                	.insn	2, 0x0000
 220:	ffff                	.insn	2, 0xffff
 222:	ffff                	.insn	2, 0xffff
 224:	0004                	.insn	2, 0x0004
 226:	0004                	.insn	2, 0x0004
 228:	7c01                	.insn	2, 0x7c01
 22a:	0c01                	.insn	2, 0x0c01
 22c:	0002                	.insn	2, 0x0002
 22e:	0000                	.insn	2, 0x0000
 230:	0020                	.insn	2, 0x0020
 232:	0000                	.insn	2, 0x0000
 234:	021c                	.insn	2, 0x021c
 236:	0000                	.insn	2, 0x0000
 238:	12b0                	.insn	2, 0x12b0
 23a:	0040                	.insn	2, 0x0040
 23c:	00ec                	.insn	2, 0x00ec
 23e:	0000                	.insn	2, 0x0000
 240:	0e44                	.insn	2, 0x0e44
 242:	04a0                	.insn	2, 0x04a0
 244:	814c                	.insn	2, 0x814c
 246:	8801                	.insn	2, 0x8801
 248:	8902                	.insn	2, 0x8902
 24a:	c1d40203          	lb	tp,-995(s0) # e90131cf <USER_MAX+0xe8b131cf>
 24e:	c9c8                	.insn	2, 0xc9c8
 250:	0e44                	.insn	2, 0x0e44
 252:	0000                	.insn	2, 0x0000
 254:	0024                	.insn	2, 0x0024
 256:	0000                	.insn	2, 0x0000
 258:	021c                	.insn	2, 0x021c
 25a:	0000                	.insn	2, 0x0000
 25c:	139c                	.insn	2, 0x139c
 25e:	0040                	.insn	2, 0x0040
 260:	00bc                	.insn	2, 0x00bc
 262:	0000                	.insn	2, 0x0000
 264:	0e44                	.insn	2, 0x0e44
 266:	5010                	.insn	2, 0x5010
 268:	0181                	.insn	2, 0x0181
 26a:	0288                	.insn	2, 0x0288
 26c:	0389                	.insn	2, 0x0389
 26e:	0492                	.insn	2, 0x0492
 270:	a002                	.insn	2, 0xa002
 272:	c8c1                	.insn	2, 0xc8c1
 274:	d2c9                	.insn	2, 0xd2c9
 276:	0e44                	.insn	2, 0x0e44
 278:	0000                	.insn	2, 0x0000
 27a:	0000                	.insn	2, 0x0000
 27c:	003c                	.insn	2, 0x003c
 27e:	0000                	.insn	2, 0x0000
 280:	021c                	.insn	2, 0x021c
 282:	0000                	.insn	2, 0x0000
 284:	1458                	.insn	2, 0x1458
 286:	0040                	.insn	2, 0x0040
 288:	02a0                	.insn	2, 0x02a0
 28a:	0000                	.insn	2, 0x0000
 28c:	0e44                	.insn	2, 0x0e44
 28e:	7040                	.insn	2, 0x7040
 290:	0181                	.insn	2, 0x0181
 292:	0288                	.insn	2, 0x0288
 294:	0389                	.insn	2, 0x0389
 296:	0492                	.insn	2, 0x0492
 298:	06940593          	addi	a1,s0,105
 29c:	0795                	.insn	2, 0x0795
 29e:	0896                	.insn	2, 0x0896
 2a0:	0a980997          	auipc	s3,0xa980
 2a4:	0b99                	.insn	2, 0x0b99
 2a6:	0c9a                	.insn	2, 0x0c9a
 2a8:	020a                	.insn	2, 0x020a
 2aa:	c180                	.insn	2, 0xc180
 2ac:	c9c8                	.insn	2, 0xc9c8
 2ae:	d3d2                	.insn	2, 0xd3d2
 2b0:	d5d4                	.insn	2, 0xd5d4
 2b2:	d7d6                	.insn	2, 0xd7d6
 2b4:	d9d8                	.insn	2, 0xd9d8
 2b6:	44da                	.insn	2, 0x44da
 2b8:	000e                	.insn	2, 0x000e
 2ba:	0b44                	.insn	2, 0x0b44
 2bc:	000c                	.insn	2, 0x000c
 2be:	0000                	.insn	2, 0x0000
 2c0:	021c                	.insn	2, 0x021c
 2c2:	0000                	.insn	2, 0x0000
 2c4:	16f8                	.insn	2, 0x16f8
 2c6:	0040                	.insn	2, 0x0040
 2c8:	0020                	.insn	2, 0x0020
 2ca:	0000                	.insn	2, 0x0000
 2cc:	0038                	.insn	2, 0x0038
 2ce:	0000                	.insn	2, 0x0000
 2d0:	021c                	.insn	2, 0x021c
 2d2:	0000                	.insn	2, 0x0000
 2d4:	1718                	.insn	2, 0x1718
 2d6:	0040                	.insn	2, 0x0040
 2d8:	0288                	.insn	2, 0x0288
 2da:	0000                	.insn	2, 0x0000
 2dc:	0e44                	.insn	2, 0x0e44
 2de:	6830                	.insn	2, 0x6830
 2e0:	0181                	.insn	2, 0x0181
 2e2:	0288                	.insn	2, 0x0288
 2e4:	0389                	.insn	2, 0x0389
 2e6:	0492                	.insn	2, 0x0492
 2e8:	06940593          	addi	a1,s0,105
 2ec:	0795                	.insn	2, 0x0795
 2ee:	0896                	.insn	2, 0x0896
 2f0:	0a980997          	auipc	s3,0xa980
 2f4:	020a                	.insn	2, 0x020a
 2f6:	c164                	.insn	2, 0xc164
 2f8:	c9c8                	.insn	2, 0xc9c8
 2fa:	d3d2                	.insn	2, 0xd3d2
 2fc:	d5d4                	.insn	2, 0xd5d4
 2fe:	d7d6                	.insn	2, 0xd7d6
 300:	44d8                	.insn	2, 0x44d8
 302:	000e                	.insn	2, 0x000e
 304:	0b44                	.insn	2, 0x0b44
 306:	0000                	.insn	2, 0x0000
 308:	0028                	.insn	2, 0x0028
 30a:	0000                	.insn	2, 0x0000
 30c:	021c                	.insn	2, 0x021c
 30e:	0000                	.insn	2, 0x0000
 310:	19a0                	.insn	2, 0x19a0
 312:	0040                	.insn	2, 0x0040
 314:	03b0                	.insn	2, 0x03b0
 316:	0000                	.insn	2, 0x0000
 318:	0e44                	.insn	2, 0x0e44
 31a:	5830                	.insn	2, 0x5830
 31c:	0181                	.insn	2, 0x0181
 31e:	0288                	.insn	2, 0x0288
 320:	0389                	.insn	2, 0x0389
 322:	0492                	.insn	2, 0x0492
 324:	06940593          	addi	a1,s0,105
 328:	c1038c03          	lb	s8,-1008(t2)
 32c:	c9c8                	.insn	2, 0xc9c8
 32e:	d3d2                	.insn	2, 0xd3d2
 330:	44d4                	.insn	2, 0x44d4
 332:	000e                	.insn	2, 0x000e

Disassembly of section .debug_line:

00000000 <.debug_line>:
       0:	06de                	.insn	2, 0x06de
       2:	0000                	.insn	2, 0x0000
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
      36:	de00                	.insn	2, 0xde00
      38:	0b56                	.insn	2, 0x0b56
      3a:	e88e                	.insn	2, 0xe88e
      3c:	1104                	.insn	2, 0x1104
      3e:	3b9f 6137 ba99      	.insn	6, 0xba9961373b9f
      44:	5855                	.insn	2, 0x5855
      46:	00003fcf          	.insn	4, 0x3fcf
      4a:	0100                	.insn	2, 0x0100
      4c:	56de                	.insn	2, 0x56de
      4e:	04e88e0b          	.insn	4, 0x04e88e0b
      52:	9f11                	.insn	2, 0x9f11
      54:	9961373b          	.insn	4, 0x9961373b
      58:	55ba                	.insn	2, 0x55ba
      5a:	cf58                	.insn	2, 0xcf58
      5c:	00000047          	.insn	4, 0x0047
      60:	1801                	.insn	2, 0x1801
      62:	f72a                	.insn	2, 0xf72a
      64:	cb68                	.insn	2, 0xcb68
      66:	80c17313          	andi	t1,sp,-2036
      6a:	3fb02d17          	auipc	s10,0x3fb02
      6e:	4e4a7593          	andi	a1,s4,1252
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
      90:	030a                	.insn	2, 0x030a
      92:	020a                	.insn	2, 0x020a
      94:	0138                	.insn	2, 0x0138
      96:	0306                	.insn	2, 0x0306
      98:	f271                	.insn	2, 0xf271
      9a:	0d05                	.insn	2, 0x0d05
      9c:	0306                	.insn	2, 0x0306
      9e:	0191                	.insn	2, 0x0191
      a0:	4002                	.insn	2, 0x4002
      a2:	0601                	.insn	2, 0x0601
      a4:	f27eef03          	.insn	4, 0xf27eef03
      a8:	0905                	.insn	2, 0x0905
      aa:	0306                	.insn	2, 0x0306
      ac:	4a1d                	.insn	2, 0x4a1d
      ae:	1805                	.insn	2, 0x1805
      b0:	ba06                	.insn	2, 0xba06
      b2:	2605                	.insn	2, 0x2605
      b4:	05ba                	.insn	2, 0x05ba
      b6:	ba34                	.insn	2, 0xba34
      b8:	4205                	.insn	2, 0x4205
      ba:	05ba                	.insn	2, 0x05ba
      bc:	0609                	.insn	2, 0x0609
      be:	bbbc                	.insn	2, 0xbbbc
      c0:	bbbbbbbb          	.insn	4, 0xbbbbbbbb
      c4:	05bcbbbb          	.insn	4, 0x05bcbbbb
      c8:	0618                	.insn	2, 0x0618
      ca:	05ba                	.insn	2, 0x05ba
      cc:	ba26                	.insn	2, 0xba26
      ce:	05ba5803          	lhu	a6,91(s4)
      d2:	0619                	.insn	2, 0x0619
      d4:	0800d403          	lhu	s0,128(ra) # 80 <start-0x3fff80>
      d8:	06ac                	.insn	2, 0x06ac
      da:	097fac03          	lw	s8,151(t6)
      de:	0004                	.insn	2, 0x0004
      e0:	0601                	.insn	2, 0x0601
      e2:	4a00d503          	lhu	a0,1184(ra)
      e6:	1b05                	.insn	2, 0x1b05
      e8:	04095f03          	lhu	t5,64(s2)
      ec:	0100                	.insn	2, 0x0100
      ee:	2a05                	.insn	2, 0x2a05
      f0:	0584                	.insn	2, 0x0584
      f2:	1105481b          	.insn	4, 0x1105481b
      f6:	0600054f          	.insn	4, 0x0600054f
      fa:	04094703          	lbu	a4,64(s2)
      fe:	0100                	.insn	2, 0x0100
     100:	1105                	.insn	2, 0x1105
     102:	064a3903          	.insn	4, 0x064a3903
     106:	04090103          	lb	sp,64(s2)
     10a:	0100                	.insn	2, 0x0100
     10c:	0005                	.insn	2, 0x0005
     10e:	0306                	.insn	2, 0x0306
     110:	ba46                	.insn	2, 0xba46
     112:	1105                	.insn	2, 0x1105
     114:	0306                	.insn	2, 0x0306
     116:	f23e                	.insn	2, 0xf23e
     118:	04090103          	lb	sp,64(s2)
     11c:	0100                	.insn	2, 0x0100
     11e:	1605                	.insn	2, 0x1605
     120:	06ba0903          	lb	s2,107(s4)
     124:	827fb803          	.insn	4, 0x827fb803
     128:	1405                	.insn	2, 0x1405
     12a:	0306                	.insn	2, 0x0306
     12c:	00ca                	.insn	2, 0x00ca
     12e:	054a                	.insn	2, 0x054a
     130:	031c                	.insn	2, 0x031c
     132:	0905                	.insn	2, 0x0905
     134:	0004                	.insn	2, 0x0004
     136:	0501                	.insn	2, 0x0501
     138:	0319                	.insn	2, 0x0319
     13a:	0905                	.insn	2, 0x0905
     13c:	0008                	.insn	2, 0x0008
     13e:	0601                	.insn	2, 0x0601
     140:	097fac03          	lw	s8,151(t6)
     144:	0018                	.insn	2, 0x0018
     146:	0501                	.insn	2, 0x0501
     148:	0615                	.insn	2, 0x0615
     14a:	0900ed03          	.insn	4, 0x0900ed03
     14e:	000c                	.insn	2, 0x000c
     150:	0501                	.insn	2, 0x0501
     152:	030d                	.insn	2, 0x030d
     154:	0906                	.insn	2, 0x0906
     156:	0008                	.insn	2, 0x0008
     158:	0501                	.insn	2, 0x0501
     15a:	0618                	.insn	2, 0x0618
     15c:	0582                	.insn	2, 0x0582
     15e:	4a1c                	.insn	2, 0x4a1c
     160:	0905                	.insn	2, 0x0905
     162:	4c06                	.insn	2, 0x4c06
     164:	1805                	.insn	2, 0x1805
     166:	054a6103          	.insn	4, 0x054a6103
     16a:	4d15                	.insn	2, 0x4d15
     16c:	a60306bb          	.insn	4, 0xa60306bb
     170:	1105ba7f 00dc0306 	.insn	16, 0x0382061e05bb514a00dc03061105ba7f
     178:	05bb514a 0382061e 
     180:	7f9c                	.insn	2, 0x7f9c
     182:	0809                	.insn	2, 0x0809
     184:	0100                	.insn	2, 0x0100
     186:	2a05                	.insn	2, 0x2a05
     188:	0306                	.insn	2, 0x0306
     18a:	0181                	.insn	2, 0x0181
     18c:	0582                	.insn	2, 0x0582
     18e:	4a10                	.insn	2, 0x4a10
     190:	0306                	.insn	2, 0x0306
     192:	7eff                	.insn	2, 0x7eff
     194:	0809                	.insn	2, 0x0809
     196:	0100                	.insn	2, 0x0100
     198:	1605                	.insn	2, 0x1605
     19a:	0306                	.insn	2, 0x0306
     19c:	0184                	.insn	2, 0x0184
     19e:	1c09                	.insn	2, 0x1c09
     1a0:	0100                	.insn	2, 0x0100
     1a2:	0d05                	.insn	2, 0x0d05
     1a4:	4a06                	.insn	2, 0x4a06
     1a6:	1a05                	.insn	2, 0x1a05
     1a8:	0582                	.insn	2, 0x0582
     1aa:	060d                	.insn	2, 0x060d
     1ac:	054c                	.insn	2, 0x054c
     1ae:	0614                	.insn	2, 0x0614
     1b0:	054a                	.insn	2, 0x054a
     1b2:	34054a17          	auipc	s4,0x34054
     1b6:	0c090003          	lb	zero,192(s2)
     1ba:	0100                	.insn	2, 0x0100
     1bc:	0d05                	.insn	2, 0x0d05
     1be:	054a                	.insn	2, 0x054a
     1c0:	4a14                	.insn	2, 0x4a14
     1c2:	1705                	.insn	2, 0x1705
     1c4:	054a                	.insn	2, 0x054a
     1c6:	0612                	.insn	2, 0x0612
     1c8:	08090303          	lb	t1,128(s2)
     1cc:	0100                	.insn	2, 0x0100
     1ce:	0005                	.insn	2, 0x0005
     1d0:	0306                	.insn	2, 0x0306
     1d2:	05827ef7          	.insn	4, 0x05827ef7
     1d6:	0614                	.insn	2, 0x0614
     1d8:	4a018a03          	lb	s4,1184(gp)
     1dc:	1e05                	.insn	2, 0x1e05
     1de:	4a06                	.insn	2, 0x4a06
     1e0:	0905                	.insn	2, 0x0905
     1e2:	0306                	.insn	2, 0x0306
     1e4:	0979                	.insn	2, 0x0979
     1e6:	0008                	.insn	2, 0x0008
     1e8:	0501                	.insn	2, 0x0501
     1ea:	0314                	.insn	2, 0x0314
     1ec:	090d                	.insn	2, 0x090d
     1ee:	0008                	.insn	2, 0x0008
     1f0:	0501                	.insn	2, 0x0501
     1f2:	060d                	.insn	2, 0x060d
     1f4:	0582                	.insn	2, 0x0582
     1f6:	f226                	.insn	2, 0xf226
     1f8:	1405                	.insn	2, 0x1405
     1fa:	0306                	.insn	2, 0x0306
     1fc:	0904                	.insn	2, 0x0904
     1fe:	0004                	.insn	2, 0x0004
     200:	0501                	.insn	2, 0x0501
     202:	062c                	.insn	2, 0x062c
     204:	3c08                	.insn	2, 0x3c08
     206:	1405                	.insn	2, 0x1405
     208:	0306                	.insn	2, 0x0306
     20a:	091d                	.insn	2, 0x091d
     20c:	0004                	.insn	2, 0x0004
     20e:	0601                	.insn	2, 0x0601
     210:	087ecf03          	lbu	t5,135(t4)
     214:	053c                	.insn	2, 0x053c
     216:	032e                	.insn	2, 0x032e
     218:	01b1                	.insn	2, 0x01b1
     21a:	054a                	.insn	2, 0x054a
     21c:	0614                	.insn	2, 0x0614
     21e:	04090c03          	lb	s8,64(s2)
     222:	0100                	.insn	2, 0x0100
     224:	3105                	.insn	2, 0x3105
     226:	0806                	.insn	2, 0x0806
     228:	053c                	.insn	2, 0x053c
     22a:	0614                	.insn	2, 0x0614
     22c:	04090503          	lb	a0,64(s2)
     230:	0100                	.insn	2, 0x0100
     232:	3005                	.insn	2, 0x3005
     234:	0806                	.insn	2, 0x0806
     236:	053c                	.insn	2, 0x053c
     238:	0614                	.insn	2, 0x0614
     23a:	04090d03          	lb	s10,64(s2)
     23e:	0100                	.insn	2, 0x0100
     240:	3005                	.insn	2, 0x3005
     242:	0806                	.insn	2, 0x0806
     244:	053c                	.insn	2, 0x053c
     246:	0614                	.insn	2, 0x0614
     248:	04090a03          	lb	s4,64(s2)
     24c:	0100                	.insn	2, 0x0100
     24e:	3105                	.insn	2, 0x3105
     250:	0806                	.insn	2, 0x0806
     252:	053c                	.insn	2, 0x053c
     254:	0614                	.insn	2, 0x0614
     256:	04090b03          	lb	s6,64(s2)
     25a:	0100                	.insn	2, 0x0100
     25c:	2f05                	.insn	2, 0x2f05
     25e:	0806                	.insn	2, 0x0806
     260:	053c                	.insn	2, 0x053c
     262:	0614                	.insn	2, 0x0614
     264:	04090a03          	lb	s4,64(s2)
     268:	0100                	.insn	2, 0x0100
     26a:	3005                	.insn	2, 0x3005
     26c:	0806                	.insn	2, 0x0806
     26e:	053c                	.insn	2, 0x053c
     270:	0614                	.insn	2, 0x0614
     272:	04090e03          	lb	t3,64(s2)
     276:	0100                	.insn	2, 0x0100
     278:	3205                	.insn	2, 0x3205
     27a:	0806                	.insn	2, 0x0806
     27c:	053c                	.insn	2, 0x053c
     27e:	0614                	.insn	2, 0x0614
     280:	04090e03          	lb	t3,64(s2)
     284:	0100                	.insn	2, 0x0100
     286:	3005                	.insn	2, 0x3005
     288:	0806                	.insn	2, 0x0806
     28a:	053c                	.insn	2, 0x053c
     28c:	0614                	.insn	2, 0x0614
     28e:	04090503          	lb	a0,64(s2)
     292:	0100                	.insn	2, 0x0100
     294:	3105                	.insn	2, 0x3105
     296:	0806                	.insn	2, 0x0806
     298:	053c                	.insn	2, 0x053c
     29a:	0614                	.insn	2, 0x0614
     29c:	04090a03          	lb	s4,64(s2)
     2a0:	0100                	.insn	2, 0x0100
     2a2:	3305                	.insn	2, 0x3305
     2a4:	0806                	.insn	2, 0x0806
     2a6:	053c                	.insn	2, 0x053c
     2a8:	0614                	.insn	2, 0x0614
     2aa:	04090c03          	lb	s8,64(s2)
     2ae:	0100                	.insn	2, 0x0100
     2b0:	2c05                	.insn	2, 0x2c05
     2b2:	0806                	.insn	2, 0x0806
     2b4:	053c                	.insn	2, 0x053c
     2b6:	0614                	.insn	2, 0x0614
     2b8:	04090b03          	lb	s6,64(s2)
     2bc:	0100                	.insn	2, 0x0100
     2be:	3105                	.insn	2, 0x3105
     2c0:	0806                	.insn	2, 0x0806
     2c2:	053c                	.insn	2, 0x053c
     2c4:	0614                	.insn	2, 0x0614
     2c6:	04090103          	lb	sp,64(s2)
     2ca:	0100                	.insn	2, 0x0100
     2cc:	3105                	.insn	2, 0x3105
     2ce:	0806                	.insn	2, 0x0806
     2d0:	053c                	.insn	2, 0x053c
     2d2:	0614                	.insn	2, 0x0614
     2d4:	04090103          	lb	sp,64(s2)
     2d8:	0100                	.insn	2, 0x0100
     2da:	3105                	.insn	2, 0x3105
     2dc:	3b08                	.insn	2, 0x3b08
     2de:	0d05                	.insn	2, 0x0d05
     2e0:	04090503          	lb	a0,64(s2)
     2e4:	0100                	.insn	2, 0x0100
     2e6:	0306                	.insn	2, 0x0306
     2e8:	7dca                	.insn	2, 0x7dca
     2ea:	3c08                	.insn	2, 0x3c08
     2ec:	1605                	.insn	2, 0x1605
     2ee:	0306                	.insn	2, 0x0306
     2f0:	019a                	.insn	2, 0x019a
     2f2:	0582                	.insn	2, 0x0582
     2f4:	031f 0901 0004      	.insn	6, 0x00040901031f
     2fa:	0501                	.insn	2, 0x0501
     2fc:	0305                	.insn	2, 0x0305
     2fe:	064a01b7          	lui	gp,0x64a0
     302:	4a7dae03          	lw	t3,1191(s11)
     306:	ba02d203          	lhu	tp,-1120(t0) # fffffba0 <USER_MAX+0xffaffba0>
     30a:	0c05                	.insn	2, 0x0c05
     30c:	054a                	.insn	2, 0x054a
     30e:	4a16                	.insn	2, 0x4a16
     310:	1905                	.insn	2, 0x1905
     312:	0306                	.insn	2, 0x0306
     314:	00100903          	lb	s2,1(zero) # 1 <start-0x3fffff>
     318:	0501                	.insn	2, 0x0501
     31a:	0625                	.insn	2, 0x0625
     31c:	054a                	.insn	2, 0x054a
     31e:	060a                	.insn	2, 0x060a
     320:	0c090103          	lb	sp,192(s2)
     324:	0100                	.insn	2, 0x0100
     326:	0905                	.insn	2, 0x0905
     328:	4a06                	.insn	2, 0x4a06
     32a:	1605                	.insn	2, 0x1605
     32c:	0306                	.insn	2, 0x0306
     32e:	7edd                	.insn	2, 0x7edd
     330:	0809                	.insn	2, 0x0809
     332:	0100                	.insn	2, 0x0100
     334:	2105                	.insn	2, 0x2105
     336:	04090103          	lb	sp,64(s2)
     33a:	0100                	.insn	2, 0x0100
     33c:	1705                	.insn	2, 0x1705
     33e:	4a06                	.insn	2, 0x4a06
     340:	ba7ecc03          	lbu	s8,-1113(t4)
     344:	1905                	.insn	2, 0x1905
     346:	0306                	.insn	2, 0x0306
     348:	01b5                	.insn	2, 0x01b5
     34a:	06ba                	.insn	2, 0x06ba
     34c:	097ecb03          	lbu	s6,151(t4)
     350:	0008                	.insn	2, 0x0008
     352:	0501                	.insn	2, 0x0501
     354:	060d                	.insn	2, 0x060d
     356:	8201a603          	lw	a2,-2016(gp) # 649f820 <USER_MAX+0x5f9f820>
     35a:	0306                	.insn	2, 0x0306
     35c:	7eda                	.insn	2, 0x7eda
     35e:	0582                	.insn	2, 0x0582
     360:	0609                	.insn	2, 0x0609
     362:	8202d603          	lhu	a2,-2016(t0)
     366:	0306                	.insn	2, 0x0306
     368:	7daa                	.insn	2, 0x7daa
     36a:	0409                	.insn	2, 0x0409
     36c:	0100                	.insn	2, 0x0100
     36e:	1605                	.insn	2, 0x1605
     370:	0306                	.insn	2, 0x0306
     372:	01a0                	.insn	2, 0x01a0
     374:	064a                	.insn	2, 0x064a
     376:	097ee003          	.insn	4, 0x097ee003
     37a:	0008                	.insn	2, 0x0008
     37c:	0501                	.insn	2, 0x0501
     37e:	060d                	.insn	2, 0x060d
     380:	4a01a603          	lw	a2,1184(gp)
     384:	0306                	.insn	2, 0x0306
     386:	7eda                	.insn	2, 0x7eda
     388:	0582                	.insn	2, 0x0582
     38a:	061f a103 4a01      	.insn	6, 0x4a01a103061f
     390:	0505                	.insn	2, 0x0505
     392:	4a01b103          	.insn	4, 0x4a01b103
     396:	0306                	.insn	2, 0x0306
     398:	7dae                	.insn	2, 0x7dae
     39a:	034a                	.insn	2, 0x034a
     39c:	02d2                	.insn	2, 0x02d2
     39e:	054a                	.insn	2, 0x054a
     3a0:	4a0c                	.insn	2, 0x4a0c
     3a2:	1605                	.insn	2, 0x1605
     3a4:	054a                	.insn	2, 0x054a
     3a6:	0619                	.insn	2, 0x0619
     3a8:	10090303          	lb	t1,256(s2)
     3ac:	0100                	.insn	2, 0x0100
     3ae:	2505                	.insn	2, 0x2505
     3b0:	4a06                	.insn	2, 0x4a06
     3b2:	0a05                	.insn	2, 0x0a05
     3b4:	0306                	.insn	2, 0x0306
     3b6:	0901                	.insn	2, 0x0901
     3b8:	0010                	.insn	2, 0x0010
     3ba:	0501                	.insn	2, 0x0501
     3bc:	0609                	.insn	2, 0x0609
     3be:	054a                	.insn	2, 0x054a
     3c0:	0616                	.insn	2, 0x0616
     3c2:	097eee03          	.insn	4, 0x097eee03
     3c6:	0008                	.insn	2, 0x0008
     3c8:	0501                	.insn	2, 0x0501
     3ca:	0328                	.insn	2, 0x0328
     3cc:	0901                	.insn	2, 0x0901
     3ce:	0004                	.insn	2, 0x0004
     3d0:	0501                	.insn	2, 0x0501
     3d2:	061e                	.insn	2, 0x061e
     3d4:	034a                	.insn	2, 0x034a
     3d6:	05ba7ebb          	.insn	4, 0x05ba7ebb
     3da:	0620                	.insn	2, 0x0620
     3dc:	8201c603          	lbu	a2,-2016(gp)
     3e0:	0306                	.insn	2, 0x0306
     3e2:	7eba                	.insn	2, 0x7eba
     3e4:	0c09                	.insn	2, 0x0c09
     3e6:	0100                	.insn	2, 0x0100
     3e8:	0d05                	.insn	2, 0x0d05
     3ea:	0306                	.insn	2, 0x0306
     3ec:	01ba                	.insn	2, 0x01ba
     3ee:	054a                	.insn	2, 0x054a
     3f0:	0309                	.insn	2, 0x0309
     3f2:	00f6                	.insn	2, 0x00f6
     3f4:	06ba                	.insn	2, 0x06ba
     3f6:	4a7dd003          	lhu	zero,1191(s11)
     3fa:	0306                	.insn	2, 0x0306
     3fc:	02d6                	.insn	2, 0x02d6
     3fe:	0582                	.insn	2, 0x0582
     400:	030d                	.insn	2, 0x030d
     402:	7ed0                	.insn	2, 0x7ed0
     404:	0409                	.insn	2, 0x0409
     406:	0100                	.insn	2, 0x0100
     408:	0306                	.insn	2, 0x0306
     40a:	7eda                	.insn	2, 0x7eda
     40c:	0582                	.insn	2, 0x0582
     40e:	0616                	.insn	2, 0x0616
     410:	ba01d003          	lhu	zero,-1120(gp)
     414:	2805                	.insn	2, 0x2805
     416:	04090503          	lb	a0,64(s2)
     41a:	0100                	.insn	2, 0x0100
     41c:	1e05                	.insn	2, 0x1e05
     41e:	4a06                	.insn	2, 0x4a06
     420:	0d05                	.insn	2, 0x0d05
     422:	8306                	.insn	2, 0x8306
     424:	0905                	.insn	2, 0x0905
     426:	8200da03          	lhu	s4,-2016(ra)
     42a:	0306                	.insn	2, 0x0306
     42c:	7dd0                	.insn	2, 0x7dd0
     42e:	054a                	.insn	2, 0x054a
     430:	0616                	.insn	2, 0x0616
     432:	ba02db03          	lhu	s6,-1120(t0)
     436:	0306                	.insn	2, 0x0306
     438:	7da5                	.insn	2, 0x7da5
     43a:	0582                	.insn	2, 0x0582
     43c:	060c                	.insn	2, 0x060c
     43e:	8202d803          	lhu	a6,-2016(t0)
     442:	1005                	.insn	2, 0x1005
     444:	0551                	.insn	2, 0x0551
     446:	0616                	.insn	2, 0x0616
     448:	054a                	.insn	2, 0x054a
     44a:	0605                	.insn	2, 0x0605
     44c:	054a7903          	.insn	4, 0x054a7903
     450:	0316                	.insn	2, 0x0316
     452:	00080903          	lb	s2,0(a6) # 7f00463c <USER_MAX+0x7eb0463c>
     456:	0501                	.insn	2, 0x0501
     458:	0901031b          	.insn	4, 0x0901031b
     45c:	0008                	.insn	2, 0x0008
     45e:	0601                	.insn	2, 0x0601
     460:	097da403          	lw	s0,151(s11)
     464:	0008                	.insn	2, 0x0008
     466:	0301                	.insn	2, 0x0301
     468:	02dc                	.insn	2, 0x02dc
     46a:	064a                	.insn	2, 0x064a
     46c:	a303064b          	.insn	4, 0xa303064b
     470:	097d                	.insn	2, 0x097d
     472:	0008                	.insn	2, 0x0008
     474:	0501                	.insn	2, 0x0501
     476:	0616                	.insn	2, 0x0616
     478:	f201da03          	lhu	s4,-224(gp)
     47c:	2805                	.insn	2, 0x2805
     47e:	04090503          	lb	a0,64(s2)
     482:	0100                	.insn	2, 0x0100
     484:	1e05                	.insn	2, 0x1e05
     486:	4a06                	.insn	2, 0x4a06
     488:	0d05                	.insn	2, 0x0d05
     48a:	8406                	.insn	2, 0x8406
     48c:	0905                	.insn	2, 0x0905
     48e:	06823803          	.insn	4, 0x06823803
     492:	4a7de703          	.insn	4, 0x4a7de703
     496:	0d05                	.insn	2, 0x0d05
     498:	0306                	.insn	2, 0x0306
     49a:	01cc                	.insn	2, 0x01cc
     49c:	054a                	.insn	2, 0x054a
     49e:	0309                	.insn	2, 0x0309
     4a0:	00e4                	.insn	2, 0x00e4
     4a2:	06ba                	.insn	2, 0x06ba
     4a4:	4a7dd003          	lhu	zero,1191(s11)
     4a8:	1605                	.insn	2, 0x1605
     4aa:	0306                	.insn	2, 0x0306
     4ac:	01e5                	.insn	2, 0x01e5
     4ae:	0582                	.insn	2, 0x0582
     4b0:	032c                	.insn	2, 0x032c
     4b2:	0905                	.insn	2, 0x0905
     4b4:	0004                	.insn	2, 0x0004
     4b6:	0501                	.insn	2, 0x0501
     4b8:	0622                	.insn	2, 0x0622
     4ba:	054a                	.insn	2, 0x054a
     4bc:	060d                	.insn	2, 0x060d
     4be:	03090583          	lb	a1,48(s2)
     4c2:	00c5                	.insn	2, 0x00c5
     4c4:	0682                	.insn	2, 0x0682
     4c6:	4a7dd003          	lhu	zero,1191(s11)
     4ca:	1605                	.insn	2, 0x1605
     4cc:	0306                	.insn	2, 0x0306
     4ce:	06ba02db          	.insn	4, 0x06ba02db
     4d2:	827da503          	lw	a0,-2009(s11)
     4d6:	0c05                	.insn	2, 0x0c05
     4d8:	0306                	.insn	2, 0x0306
     4da:	02d8                	.insn	2, 0x02d8
     4dc:	0582                	.insn	2, 0x0582
     4de:	5110                	.insn	2, 0x5110
     4e0:	1605                	.insn	2, 0x1605
     4e2:	4a06                	.insn	2, 0x4a06
     4e4:	0505                	.insn	2, 0x0505
     4e6:	0306                	.insn	2, 0x0306
     4e8:	4a79                	.insn	2, 0x4a79
     4ea:	1605                	.insn	2, 0x1605
     4ec:	08090303          	lb	t1,128(s2)
     4f0:	0100                	.insn	2, 0x0100
     4f2:	1b05                	.insn	2, 0x1b05
     4f4:	08090103          	lb	sp,128(s2)
     4f8:	0100                	.insn	2, 0x0100
     4fa:	0306                	.insn	2, 0x0306
     4fc:	7da4                	.insn	2, 0x7da4
     4fe:	0809                	.insn	2, 0x0809
     500:	0100                	.insn	2, 0x0100
     502:	4a02dc03          	lhu	s8,1184(t0)
     506:	4b06                	.insn	2, 0x4b06
     508:	0306                	.insn	2, 0x0306
     50a:	08097da3          	.insn	4, 0x08097da3
     50e:	0100                	.insn	2, 0x0100
     510:	1605                	.insn	2, 0x1605
     512:	0306                	.insn	2, 0x0306
     514:	05f201ef          	jal	gp,20d72 <start-0x3df28e>
     518:	032c                	.insn	2, 0x032c
     51a:	0905                	.insn	2, 0x0905
     51c:	0004                	.insn	2, 0x0004
     51e:	0501                	.insn	2, 0x0501
     520:	0622                	.insn	2, 0x0622
     522:	054a                	.insn	2, 0x054a
     524:	05bb061b          	.insn	4, 0x05bb061b
     528:	030d                	.insn	2, 0x030d
     52a:	0904                	.insn	2, 0x0904
     52c:	0014                	.insn	2, 0x0014
     52e:	0501                	.insn	2, 0x0501
     530:	0309                	.insn	2, 0x0309
     532:	1105ba37          	lui	s4,0x1105b
     536:	054a4e03          	lbu	t3,84(s4) # 1105b054 <USER_MAX+0x10b5b054>
     53a:	061f 3c08 0005      	.insn	6, 0x00053c08061f
     540:	097e8203          	lb	tp,151(t4)
     544:	0004                	.insn	2, 0x0004
     546:	0501                	.insn	2, 0x0501
     548:	0609                	.insn	2, 0x0609
     54a:	8202b003          	.insn	4, 0x8202b003
     54e:	0d05                	.insn	2, 0x0d05
     550:	054a5c03          	lhu	s8,84(s4)
     554:	8509                	.insn	2, 0x8509
     556:	0306                	.insn	2, 0x0306
     558:	7df1                	.insn	2, 0x7df1
     55a:	054a                	.insn	2, 0x054a
     55c:	0616                	.insn	2, 0x0616
     55e:	82029103          	lh	sp,-2016(t0)
     562:	1705                	.insn	2, 0x1705
     564:	04090503          	lb	a0,64(s2)
     568:	0100                	.insn	2, 0x0100
     56a:	0d05                	.insn	2, 0x0d05
     56c:	4a06                	.insn	2, 0x4a06
     56e:	0905                	.insn	2, 0x0905
     570:	8506                	.insn	2, 0x8506
     572:	0306                	.insn	2, 0x0306
     574:	054a7de7          	.insn	4, 0x054a7de7
     578:	0632                	.insn	2, 0x0632
     57a:	4a028303          	lb	t1,1184(t0)
     57e:	0d05                	.insn	2, 0x0d05
     580:	8206                	.insn	2, 0x8206
     582:	3205                	.insn	2, 0x3205
     584:	f306                	.insn	2, 0xf306
     586:	0d05                	.insn	2, 0x0d05
     588:	4a06                	.insn	2, 0x4a06
     58a:	3205                	.insn	2, 0x3205
     58c:	f306                	.insn	2, 0xf306
     58e:	0d05                	.insn	2, 0x0d05
     590:	4a06                	.insn	2, 0x4a06
     592:	3205                	.insn	2, 0x3205
     594:	f306                	.insn	2, 0xf306
     596:	0d05                	.insn	2, 0x0d05
     598:	4a06                	.insn	2, 0x4a06
     59a:	3205                	.insn	2, 0x3205
     59c:	f306                	.insn	2, 0xf306
     59e:	0d05                	.insn	2, 0x0d05
     5a0:	4a06                	.insn	2, 0x4a06
     5a2:	f27df903          	.insn	4, 0xf27df903
     5a6:	1605                	.insn	2, 0x1605
     5a8:	0306                	.insn	2, 0x0306
     5aa:	05ba029b          	.insn	4, 0x05ba029b
     5ae:	031d                	.insn	2, 0x031d
     5b0:	0905                	.insn	2, 0x0905
     5b2:	0004                	.insn	2, 0x0004
     5b4:	0501                	.insn	2, 0x0501
     5b6:	0611                	.insn	2, 0x0611
     5b8:	054a                	.insn	2, 0x054a
     5ba:	8226                	.insn	2, 0x8226
     5bc:	1105                	.insn	2, 0x1105
     5be:	0306                	.insn	2, 0x0306
     5c0:	0901                	.insn	2, 0x0901
     5c2:	0004                	.insn	2, 0x0004
     5c4:	0501                	.insn	2, 0x0501
     5c6:	0309                	.insn	2, 0x0309
     5c8:	0d05f20f          	.insn	4, 0x0d05f20f
     5cc:	054a7603          	.insn	4, 0x054a7603
     5d0:	0309                	.insn	2, 0x0309
     5d2:	f20a                	.insn	2, 0xf20a
     5d4:	0d05                	.insn	2, 0x0d05
     5d6:	054d                	.insn	2, 0x054d
     5d8:	0a05                	.insn	2, 0x0a05
     5da:	08091f03          	lh	t5,128(s2)
     5de:	0100                	.insn	2, 0x0100
     5e0:	0c05                	.insn	2, 0x0c05
     5e2:	0806                	.insn	2, 0x0806
     5e4:	053c                	.insn	2, 0x053c
     5e6:	4a16                	.insn	2, 0x4a16
     5e8:	097dae03          	lw	t3,151(s11)
     5ec:	0008                	.insn	2, 0x0008
     5ee:	0301                	.insn	2, 0x0301
     5f0:	02d2                	.insn	2, 0x02d2
     5f2:	054a                	.insn	2, 0x054a
     5f4:	0619                	.insn	2, 0x0619
     5f6:	04090303          	lb	t1,64(s2)
     5fa:	0100                	.insn	2, 0x0100
     5fc:	2505                	.insn	2, 0x2505
     5fe:	4a06                	.insn	2, 0x4a06
     600:	0a05                	.insn	2, 0x0a05
     602:	0306                	.insn	2, 0x0306
     604:	0901                	.insn	2, 0x0901
     606:	000c                	.insn	2, 0x000c
     608:	0501                	.insn	2, 0x0501
     60a:	0609                	.insn	2, 0x0609
     60c:	054a                	.insn	2, 0x054a
     60e:	060a                	.insn	2, 0x060a
     610:	08090003          	lb	zero,128(s2)
     614:	0100                	.insn	2, 0x0100
     616:	0905                	.insn	2, 0x0905
     618:	4a06                	.insn	2, 0x4a06
     61a:	097daa03          	lw	s4,151(s11)
     61e:	0004                	.insn	2, 0x0004
     620:	0501                	.insn	2, 0x0501
     622:	0601                	.insn	2, 0x0601
     624:	4a02e303          	.insn	4, 0x4a02e303
     628:	0306                	.insn	2, 0x0306
     62a:	7d9d                	.insn	2, 0x7d9d
     62c:	054a                	.insn	2, 0x054a
     62e:	0616                	.insn	2, 0x0616
     630:	ba02db03          	lhu	s6,-1120(t0)
     634:	0306                	.insn	2, 0x0306
     636:	7da5                	.insn	2, 0x7da5
     638:	3c08                	.insn	2, 0x3c08
     63a:	0c05                	.insn	2, 0x0c05
     63c:	0306                	.insn	2, 0x0306
     63e:	02d8                	.insn	2, 0x02d8
     640:	0582                	.insn	2, 0x0582
     642:	5110                	.insn	2, 0x5110
     644:	1605                	.insn	2, 0x1605
     646:	4a06                	.insn	2, 0x4a06
     648:	0505                	.insn	2, 0x0505
     64a:	0306                	.insn	2, 0x0306
     64c:	4a79                	.insn	2, 0x4a79
     64e:	1605                	.insn	2, 0x1605
     650:	08090303          	lb	t1,128(s2)
     654:	0100                	.insn	2, 0x0100
     656:	1b05                	.insn	2, 0x1b05
     658:	08090103          	lb	sp,128(s2)
     65c:	0100                	.insn	2, 0x0100
     65e:	0306                	.insn	2, 0x0306
     660:	7da4                	.insn	2, 0x7da4
     662:	0809                	.insn	2, 0x0809
     664:	0100                	.insn	2, 0x0100
     666:	4a02dc03          	lhu	s8,1184(t0)
     66a:	4b06                	.insn	2, 0x4b06
     66c:	0306                	.insn	2, 0x0306
     66e:	08097da3          	.insn	4, 0x08097da3
     672:	0100                	.insn	2, 0x0100
     674:	0a05                	.insn	2, 0x0a05
     676:	0306                	.insn	2, 0x0306
     678:	02e1                	.insn	2, 0x02e1
     67a:	05ba                	.insn	2, 0x05ba
     67c:	4c01                	.insn	2, 0x4c01
     67e:	0005                	.insn	2, 0x0005
     680:	04095a03          	lhu	s4,64(s2)
     684:	0100                	.insn	2, 0x0100
     686:	0505                	.insn	2, 0x0505
     688:	020a                	.insn	2, 0x020a
     68a:	1424                	.insn	2, 0x1424
     68c:	0306                	.insn	2, 0x0306
     68e:	7dc1                	.insn	2, 0x7dc1
     690:	0409                	.insn	2, 0x0409
     692:	0100                	.insn	2, 0x0100
     694:	2505                	.insn	2, 0x2505
     696:	0306                	.insn	2, 0x0306
     698:	05ba02bf 054a0605 	.insn	8, 0x054a060505ba02bf
     6a0:	060d                	.insn	2, 0x060d
     6a2:	04090103          	lb	sp,64(s2)
     6a6:	0100                	.insn	2, 0x0100
     6a8:	0306                	.insn	2, 0x0306
     6aa:	7dc0                	.insn	2, 0x7dc0
     6ac:	06ba                	.insn	2, 0x06ba
     6ae:	0902c103          	lbu	sp,144(t0)
     6b2:	0004                	.insn	2, 0x0004
     6b4:	0501                	.insn	2, 0x0501
     6b6:	f312                	.insn	2, 0xf312
     6b8:	1d05                	.insn	2, 0x1d05
     6ba:	0311054b          	.insn	4, 0x0311054b
     6be:	0901                	.insn	2, 0x0901
     6c0:	0008                	.insn	2, 0x0008
     6c2:	0601                	.insn	2, 0x0601
     6c4:	ba7dbc03          	.insn	4, 0xba7dbc03
     6c8:	1505                	.insn	2, 0x1505
     6ca:	0306                	.insn	2, 0x0306
     6cc:	054a02c7          	.insn	4, 0x054a02c7
     6d0:	0309                	.insn	2, 0x0309
     6d2:	0901                	.insn	2, 0x0901
     6d4:	0008                	.insn	2, 0x0008
     6d6:	0501                	.insn	2, 0x0501
     6d8:	bc05                	.insn	2, 0xbc05
     6da:	0b06                	.insn	2, 0x0b06
     6dc:	02f2                	.insn	2, 0x02f2
     6de:	0020                	.insn	2, 0x0020
     6e0:	0101                	.insn	2, 0x0101
     6e2:	0638                	.insn	2, 0x0638
     6e4:	0000                	.insn	2, 0x0000
     6e6:	0005                	.insn	2, 0x0005
     6e8:	0004                	.insn	2, 0x0004
     6ea:	00a8                	.insn	2, 0x00a8
     6ec:	0000                	.insn	2, 0x0000
     6ee:	0101                	.insn	2, 0x0101
     6f0:	fb01                	.insn	2, 0xfb01
     6f2:	0d0e                	.insn	2, 0x0d0e
     6f4:	0100                	.insn	2, 0x0100
     6f6:	0101                	.insn	2, 0x0101
     6f8:	0001                	.insn	2, 0x0001
     6fa:	0000                	.insn	2, 0x0000
     6fc:	0001                	.insn	2, 0x0001
     6fe:	0100                	.insn	2, 0x0100
     700:	0101                	.insn	2, 0x0101
     702:	031f 0000 0000      	.insn	6, 0x031f
     708:	0035                	.insn	2, 0x0035
     70a:	0000                	.insn	2, 0x0000
     70c:	0056                	.insn	2, 0x0056
     70e:	0000                	.insn	2, 0x0000
     710:	021f0103          	lb	sp,33(t5)
     714:	061e050f          	.insn	4, 0x061e050f
     718:	007c                	.insn	2, 0x007c
     71a:	0000                	.insn	2, 0x0000
     71c:	6500                	.insn	2, 0x6500
     71e:	0112                	.insn	2, 0x0112
     720:	27fd                	.insn	2, 0x27fd
     722:	dc95                	.insn	2, 0xdc95
     724:	8509                	.insn	2, 0x8509
     726:	123e                	.insn	2, 0x123e
     728:	fb48                	.insn	2, 0xfb48
     72a:	27e1                	.insn	2, 0x27e1
     72c:	806a                	.insn	2, 0x806a
     72e:	0000                	.insn	2, 0x0000
     730:	0100                	.insn	2, 0x0100
     732:	1265                	.insn	2, 0x1265
     734:	fd01                	.insn	2, 0xfd01
     736:	09dc9527          	.insn	4, 0x09dc9527
     73a:	3e85                	.insn	2, 0x3e85
     73c:	4812                	.insn	2, 0x4812
     73e:	6a27e1fb          	.insn	4, 0x6a27e1fb
     742:	00000087          	.insn	4, 0x0087
     746:	a402                	.insn	2, 0xa402
     748:	6a7a                	.insn	2, 0x6a7a
     74a:	7f6c                	.insn	2, 0x7f6c
     74c:	7627c6cb          	.insn	4, 0x7627c6cb
     750:	abe67d23          	.insn	4, 0xabe67d23
     754:	95ac                	.insn	2, 0x95ac
     756:	4749                	.insn	2, 0x4749
     758:	0000                	.insn	2, 0x0000
     75a:	0100                	.insn	2, 0x0100
     75c:	2a18                	.insn	2, 0x2a18
     75e:	13cb68f7          	.insn	4, 0x13cb68f7
     762:	1780c173          	.insn	4, 0x1780c173
     766:	b02d                	.insn	2, 0xb02d
     768:	4a75933f 0000004e 	.insn	8, 0x004e4a75933f
     770:	2501                	.insn	2, 0x2501
     772:	2589                	.insn	2, 0x2589
     774:	d09699ef          	jal	s3,fff6a47c <USER_MAX+0xffa6a47c>
     778:	7184                	.insn	2, 0x7184
     77a:	7c8c                	.insn	2, 0x7c8c
     77c:	1cb1                	.insn	2, 0x1cb1
     77e:	fbb9                	.insn	2, 0xfbb9
     780:	90e2                	.insn	2, 0x90e2
     782:	0000                	.insn	2, 0x0000
     784:	0100                	.insn	2, 0x0100
     786:	6580                	.insn	2, 0x6580
     788:	e0fa                	.insn	2, 0xe0fa
     78a:	031d                	.insn	2, 0x031d
     78c:	495f 5b0c b2cf      	.insn	6, 0xb2cf5b0c495f
     792:	19b2                	.insn	2, 0x19b2
     794:	28a5                	.insn	2, 0x28a5
     796:	0505                	.insn	2, 0x0505
     798:	000a                	.insn	2, 0x000a
     79a:	0205                	.insn	2, 0x0205
     79c:	0a00                	.insn	2, 0x0a00
     79e:	0040                	.insn	2, 0x0040
     7a0:	0100c003          	lbu	zero,16(ra)
     7a4:	3c081303          	lh	t1,960(a6)
     7a8:	0005                	.insn	2, 0x0005
     7aa:	04092503          	lw	a0,64(s2)
     7ae:	0100                	.insn	2, 0x0100
     7b0:	0505                	.insn	2, 0x0505
     7b2:	030a                	.insn	2, 0x030a
     7b4:	f212                	.insn	2, 0xf212
     7b6:	0306                	.insn	2, 0x0306
     7b8:	7ef5                	.insn	2, 0x7ef5
     7ba:	0409                	.insn	2, 0x0409
     7bc:	0100                	.insn	2, 0x0100
     7be:	0905                	.insn	2, 0x0905
     7c0:	0306                	.insn	2, 0x0306
     7c2:	018c                	.insn	2, 0x018c
     7c4:	2c02                	.insn	2, 0x2c02
     7c6:	0601                	.insn	2, 0x0601
     7c8:	ba7ef403          	.insn	4, 0xba7ef403
     7cc:	1e05                	.insn	2, 0x1e05
     7ce:	0306                	.insn	2, 0x0306
     7d0:	0190                	.insn	2, 0x0190
     7d2:	05f2                	.insn	2, 0x05f2
     7d4:	061c                	.insn	2, 0x061c
     7d6:	054a                	.insn	2, 0x054a
     7d8:	061e                	.insn	2, 0x061e
     7da:	0549                	.insn	2, 0x0549
     7dc:	4720                	.insn	2, 0x4720
     7de:	1e05                	.insn	2, 0x1e05
     7e0:	0585                	.insn	2, 0x0585
     7e2:	061c                	.insn	2, 0x061c
     7e4:	054a                	.insn	2, 0x054a
     7e6:	0620                	.insn	2, 0x0620
     7e8:	06090547          	.insn	4, 0x06090547
     7ec:	0582                	.insn	2, 0x0582
     7ee:	062c                	.insn	2, 0x062c
     7f0:	04097f03          	.insn	4, 0x04097f03
     7f4:	0100                	.insn	2, 0x0100
     7f6:	0505                	.insn	2, 0x0505
     7f8:	4a06                	.insn	2, 0x4a06
     7fa:	097ef503          	.insn	4, 0x097ef503
     7fe:	0010                	.insn	2, 0x0010
     800:	0601                	.insn	2, 0x0601
     802:	0204c003          	lbu	zero,32(s1)
     806:	0128                	.insn	2, 0x0128
     808:	ac084303          	lbu	t1,-1344(a6)
     80c:	ba06                	.insn	2, 0xba06
     80e:	0905                	.insn	2, 0x0905
     810:	0306                	.insn	2, 0x0306
     812:	7da2                	.insn	2, 0x7da2
     814:	ac08                	.insn	2, 0xac08
     816:	0306                	.insn	2, 0x0306
     818:	05ba7edb          	.insn	4, 0x05ba7edb
     81c:	061c                	.insn	2, 0x061c
     81e:	4a01a603          	lw	a2,1184(gp)
     822:	0505                	.insn	2, 0x0505
     824:	4a038503          	lb	a0,1184(t2)
     828:	05ba5803          	lhu	a6,91(s4)
     82c:	0320                	.insn	2, 0x0320
     82e:	7da2                	.insn	2, 0x7da2
     830:	05ba                	.insn	2, 0x05ba
     832:	0305                	.insn	2, 0x0305
     834:	02de                	.insn	2, 0x02de
     836:	0809                	.insn	2, 0x0809
     838:	0100                	.insn	2, 0x0100
     83a:	2c05                	.insn	2, 0x2c05
     83c:	ba7da103          	lw	sp,-1113(s11)
     840:	0505                	.insn	2, 0x0505
     842:	4a06                	.insn	2, 0x4a06
     844:	097edc03          	lhu	s8,151(t4)
     848:	000c                	.insn	2, 0x000c
     84a:	0601                	.insn	2, 0x0601
     84c:	0204c003          	lbu	zero,32(s1)
     850:	0124                	.insn	2, 0x0124
     852:	ac084303          	lbu	t1,-1344(a6)
     856:	ba06                	.insn	2, 0xba06
     858:	ba7bfd03          	.insn	4, 0xba7bfd03
     85c:	0306                	.insn	2, 0x0306
     85e:	06820483          	lb	s1,104(tp) # 68 <start-0x3fff98>
     862:	baba                	.insn	2, 0xbaba
     864:	0306                	.insn	2, 0x0306
     866:	7dad                	.insn	2, 0x7dad
     868:	06ba                	.insn	2, 0x06ba
     86a:	097ed003          	lhu	zero,151(t4)
     86e:	0004                	.insn	2, 0x0004
     870:	0501                	.insn	2, 0x0501
     872:	0609                	.insn	2, 0x0609
     874:	0201b103          	.insn	4, 0x0201b103
     878:	0124                	.insn	2, 0x0124
     87a:	0306                	.insn	2, 0x0306
     87c:	05ba7ecf          	.insn	4, 0x05ba7ecf
     880:	061c                	.insn	2, 0x061c
     882:	4a01b203          	.insn	4, 0x4a01b203
     886:	0505                	.insn	2, 0x0505
     888:	4a02f903          	.insn	4, 0x4a02f903
     88c:	05ba5803          	lhu	a6,91(s4)
     890:	0320                	.insn	2, 0x0320
     892:	7dae                	.insn	2, 0x7dae
     894:	05ba                	.insn	2, 0x05ba
     896:	0609                	.insn	2, 0x0609
     898:	054a                	.insn	2, 0x054a
     89a:	0605                	.insn	2, 0x0605
     89c:	0902d203          	lhu	tp,144(t0)
     8a0:	0004                	.insn	2, 0x0004
     8a2:	0501                	.insn	2, 0x0501
     8a4:	032c                	.insn	2, 0x032c
     8a6:	7dad                	.insn	2, 0x7dad
     8a8:	05ba                	.insn	2, 0x05ba
     8aa:	0605                	.insn	2, 0x0605
     8ac:	034a                	.insn	2, 0x034a
     8ae:	7ed0                	.insn	2, 0x7ed0
     8b0:	0809                	.insn	2, 0x0809
     8b2:	0100                	.insn	2, 0x0100
     8b4:	0306                	.insn	2, 0x0306
     8b6:	06ba0483          	lb	s1,107(s4)
     8ba:	baba                	.insn	2, 0xbaba
     8bc:	0306                	.insn	2, 0x0306
     8be:	7db9                	.insn	2, 0x7db9
     8c0:	05ba                	.insn	2, 0x05ba
     8c2:	f309                	.insn	2, 0xf309
     8c4:	0306                	.insn	2, 0x0306
     8c6:	05ba7ec3          	.insn	4, 0x05ba7ec3
     8ca:	061c                	.insn	2, 0x061c
     8cc:	4a01be03          	.insn	4, 0x4a01be03
     8d0:	0505                	.insn	2, 0x0505
     8d2:	4a02ed03          	.insn	4, 0x4a02ed03
     8d6:	05ba5803          	lhu	a6,91(s4)
     8da:	0320                	.insn	2, 0x0320
     8dc:	7dba                	.insn	2, 0x7dba
     8de:	05ba                	.insn	2, 0x05ba
     8e0:	0305                	.insn	2, 0x0305
     8e2:	02c6                	.insn	2, 0x02c6
     8e4:	0809                	.insn	2, 0x0809
     8e6:	0100                	.insn	2, 0x0100
     8e8:	2c05                	.insn	2, 0x2c05
     8ea:	ba7db903          	.insn	4, 0xba7db903
     8ee:	0505                	.insn	2, 0x0505
     8f0:	4a06                	.insn	2, 0x4a06
     8f2:	097ec403          	lbu	s0,151(t4)
     8f6:	000c                	.insn	2, 0x000c
     8f8:	0601                	.insn	2, 0x0601
     8fa:	82048303          	lb	t1,-2016(s1)
     8fe:	ba06                	.insn	2, 0xba06
     900:	03ba                	.insn	2, 0x03ba
     902:	7bfd                	.insn	2, 0x7bfd
     904:	06ba                	.insn	2, 0x06ba
     906:	4a048303          	lb	t1,1184(s1)
     90a:	0105                	.insn	2, 0x0105
     90c:	7dc1030b          	.insn	4, 0x7dc1030b
     910:	05ba                	.insn	2, 0x05ba
     912:	0300                	.insn	2, 0x0300
     914:	02be                	.insn	2, 0x02be
     916:	1009                	.insn	2, 0x1009
     918:	0100                	.insn	2, 0x0100
     91a:	0505                	.insn	2, 0x0505
     91c:	4b0a                	.insn	2, 0x4b0a
     91e:	0105                	.insn	2, 0x0105
     920:	05c2                	.insn	2, 0x05c2
     922:	0300                	.insn	2, 0x0300
     924:	091f 0004 0501      	.insn	6, 0x05010004091f
     92a:	0a05                	.insn	2, 0x0a05
     92c:	c201054b          	.insn	4, 0xc201054b
     930:	0505                	.insn	2, 0x0505
     932:	030a                	.insn	2, 0x030a
     934:	0922                	.insn	2, 0x0922
     936:	0004                	.insn	2, 0x0004
     938:	0501                	.insn	2, 0x0501
     93a:	0301                	.insn	2, 0x0301
     93c:	7cfa                	.insn	2, 0x7cfa
     93e:	0582                	.insn	2, 0x0582
     940:	0300                	.insn	2, 0x0300
     942:	091a                	.insn	2, 0x091a
     944:	0004                	.insn	2, 0x0004
     946:	0501                	.insn	2, 0x0501
     948:	0a09                	.insn	2, 0x0a09
     94a:	4008                	.insn	2, 0x4008
     94c:	1405                	.insn	2, 0x1405
     94e:	7708                	.insn	2, 0x7708
     950:	0905                	.insn	2, 0x0905
     952:	04090203          	lb	tp,64(s2)
     956:	0100                	.insn	2, 0x0100
     958:	05be                	.insn	2, 0x05be
     95a:	0611                	.insn	2, 0x0611
     95c:	0582                	.insn	2, 0x0582
     95e:	0609                	.insn	2, 0x0609
     960:	04090103          	lb	sp,64(s2)
     964:	0100                	.insn	2, 0x0100
     966:	0005                	.insn	2, 0x0005
     968:	0306                	.insn	2, 0x0306
     96a:	7e89                	.insn	2, 0x7e89
     96c:	0582                	.insn	2, 0x0582
     96e:	0601                	.insn	2, 0x0601
     970:	028a030b          	.insn	4, 0x028a030b
     974:	05ba                	.insn	2, 0x05ba
     976:	0309                	.insn	2, 0x0309
     978:	0872                	.insn	2, 0x0872
     97a:	863c                	.insn	2, 0x863c
     97c:	034c                	.insn	2, 0x034c
     97e:	4a7a                	.insn	2, 0x4a7a
     980:	0505                	.insn	2, 0x0505
     982:	034c                	.insn	2, 0x034c
     984:	085d                	.insn	2, 0x085d
     986:	063c                	.insn	2, 0x063c
     988:	f27ea503          	lw	a0,-217(t4)
     98c:	0005                	.insn	2, 0x0005
     98e:	0306                	.insn	2, 0x0306
     990:	02d9                	.insn	2, 0x02d9
     992:	0409                	.insn	2, 0x0409
     994:	0100                	.insn	2, 0x0100
     996:	0505                	.insn	2, 0x0505
     998:	020a                	.insn	2, 0x020a
     99a:	1464                	.insn	2, 0x1464
     99c:	0d05                	.insn	2, 0x0d05
     99e:	4108                	.insn	2, 0x4108
     9a0:	0c05                	.insn	2, 0x0c05
     9a2:	04093c03          	.insn	4, 0x04093c03
     9a6:	0100                	.insn	2, 0x0100
     9a8:	054a4103          	lbu	sp,84(s4)
     9ac:	0605                	.insn	2, 0x0605
     9ae:	064a                	.insn	2, 0x064a
     9b0:	0901a603          	lw	a2,144(gp)
     9b4:	0008                	.insn	2, 0x0008
     9b6:	0501                	.insn	2, 0x0501
     9b8:	030c                	.insn	2, 0x030c
     9ba:	7f99                	.insn	2, 0x7f99
     9bc:	05ba                	.insn	2, 0x05ba
     9be:	0305                	.insn	2, 0x0305
     9c0:	4a41                	.insn	2, 0x4a41
     9c2:	1505                	.insn	2, 0x1505
     9c4:	054d                	.insn	2, 0x054d
     9c6:	4910                	.insn	2, 0x4910
     9c8:	0d05                	.insn	2, 0x0d05
     9ca:	0321054b          	.insn	4, 0x0321054b
     9ce:	0910                	.insn	2, 0x0910
     9d0:	000c                	.insn	2, 0x000c
     9d2:	0501                	.insn	2, 0x0501
     9d4:	f51f 1b05 0d03      	.insn	6, 0x0d031b05f51f
     9da:	0409                	.insn	2, 0x0409
     9dc:	0100                	.insn	2, 0x0100
     9de:	0505                	.insn	2, 0x0505
     9e0:	09018303          	lb	t1,144(gp)
     9e4:	0004                	.insn	2, 0x0004
     9e6:	0501                	.insn	2, 0x0501
     9e8:	030c                	.insn	2, 0x030c
     9ea:	7f99                	.insn	2, 0x7f99
     9ec:	05ba                	.insn	2, 0x05ba
     9ee:	0305                	.insn	2, 0x0305
     9f0:	4a41                	.insn	2, 0x4a41
     9f2:	0d05                	.insn	2, 0x0d05
     9f4:	054d                	.insn	2, 0x054d
     9f6:	0326                	.insn	2, 0x0326
     9f8:	0931                	.insn	2, 0x0931
     9fa:	0008                	.insn	2, 0x0008
     9fc:	0501                	.insn	2, 0x0501
     9fe:	f432                	.insn	2, 0xf432
     a00:	2105                	.insn	2, 0x2105
     a02:	813e054b          	.insn	4, 0x813e054b
     a06:	2105                	.insn	2, 0x2105
     a08:	03050583          	lb	a1,48(a0)
     a0c:	054a00ef          	jal	a0a60 <start-0x35f5a0>
     a10:	0321                	.insn	2, 0x0321
     a12:	7f91                	.insn	2, 0x7f91
     a14:	05ba                	.insn	2, 0x05ba
     a16:	493e                	.insn	2, 0x493e
     a18:	2105                	.insn	2, 0x2105
     a1a:	03050583          	lb	a1,48(a0)
     a1e:	054a00ef          	jal	a0a72 <start-0x35f58e>
     a22:	0321                	.insn	2, 0x0321
     a24:	7f91                	.insn	2, 0x7f91
     a26:	05ba                	.insn	2, 0x05ba
     a28:	493e                	.insn	2, 0x493e
     a2a:	2105                	.insn	2, 0x2105
     a2c:	03050583          	lb	a1,48(a0)
     a30:	054a00ef          	jal	a0a84 <start-0x35f57c>
     a34:	0321                	.insn	2, 0x0321
     a36:	7f91                	.insn	2, 0x7f91
     a38:	05ba                	.insn	2, 0x05ba
     a3a:	493e                	.insn	2, 0x493e
     a3c:	2105                	.insn	2, 0x2105
     a3e:	03050583          	lb	a1,48(a0)
     a42:	054a00ef          	jal	a0a96 <start-0x35f56a>
     a46:	0321                	.insn	2, 0x0321
     a48:	7f91                	.insn	2, 0x7f91
     a4a:	05ba                	.insn	2, 0x05ba
     a4c:	493e                	.insn	2, 0x493e
     a4e:	2105                	.insn	2, 0x2105
     a50:	03050583          	lb	a1,48(a0)
     a54:	054a00ef          	jal	a0aa8 <start-0x35f558>
     a58:	0321                	.insn	2, 0x0321
     a5a:	7f91                	.insn	2, 0x7f91
     a5c:	05ba                	.insn	2, 0x05ba
     a5e:	493e                	.insn	2, 0x493e
     a60:	2105                	.insn	2, 0x2105
     a62:	03050583          	lb	a1,48(a0)
     a66:	054a00ef          	jal	a0aba <start-0x35f546>
     a6a:	0321                	.insn	2, 0x0321
     a6c:	7f91                	.insn	2, 0x7f91
     a6e:	05ba                	.insn	2, 0x05ba
     a70:	493e                	.insn	2, 0x493e
     a72:	2105                	.insn	2, 0x2105
     a74:	0305054b          	.insn	4, 0x0305054b
     a78:	054a00ef          	jal	a0acc <start-0x35f534>
     a7c:	0321                	.insn	2, 0x0321
     a7e:	7f91                	.insn	2, 0x7f91
     a80:	05ba                	.insn	2, 0x05ba
     a82:	0305                	.insn	2, 0x0305
     a84:	054a00ef          	jal	a0ad8 <start-0x35f528>
     a88:	030c                	.insn	2, 0x030c
     a8a:	7f99                	.insn	2, 0x7f99
     a8c:	05ba                	.insn	2, 0x05ba
     a8e:	0305                	.insn	2, 0x0305
     a90:	4a41                	.insn	2, 0x4a41
     a92:	4a01a603          	lw	a2,1184(gp)
     a96:	0c05                	.insn	2, 0x0c05
     a98:	ba7f9903          	lh	s2,-1113(t6)
     a9c:	0505                	.insn	2, 0x0505
     a9e:	054a4103          	lbu	sp,84(s4)
     aa2:	0325                	.insn	2, 0x0325
     aa4:	1c054a0b          	.insn	4, 0x1c054a0b
     aa8:	061505f3          	.insn	4, 0x061505f3
     aac:	054a                	.insn	2, 0x054a
     aae:	0605                	.insn	2, 0x0605
     ab0:	09019a03          	lh	s4,144(gp)
     ab4:	0008                	.insn	2, 0x0008
     ab6:	0501                	.insn	2, 0x0501
     ab8:	031c                	.insn	2, 0x031c
     aba:	7ee6                	.insn	2, 0x7ee6
     abc:	05ba                	.insn	2, 0x05ba
     abe:	0615                	.insn	2, 0x0615
     ac0:	054a                	.insn	2, 0x054a
     ac2:	0605                	.insn	2, 0x0605
     ac4:	09019a03          	lh	s4,144(gp)
     ac8:	000c                	.insn	2, 0x000c
     aca:	0501                	.insn	2, 0x0501
     acc:	033a                	.insn	2, 0x033a
     ace:	06ba7ef3          	csrrci	t4,0x6b,20
     ad2:	4a7d8a03          	lb	s4,1191(s11)
     ad6:	1b05                	.insn	2, 0x1b05
     ad8:	0306                	.insn	2, 0x0306
     ada:	05ba0387          	.insn	4, 0x05ba0387
     ade:	491e                	.insn	2, 0x491e
     ae0:	1b05                	.insn	2, 0x1b05
     ae2:	492d054b          	.insn	4, 0x492d054b
     ae6:	2405                	.insn	2, 0x2405
     ae8:	f206                	.insn	2, 0xf206
     aea:	2205                	.insn	2, 0x2205
     aec:	054a                	.insn	2, 0x054a
     aee:	0615                	.insn	2, 0x0615
     af0:	0581                	.insn	2, 0x0581
     af2:	0321                	.insn	2, 0x0321
     af4:	00040907          	.insn	4, 0x00040907
     af8:	0501                	.insn	2, 0x0501
     afa:	0305                	.insn	2, 0x0305
     afc:	058200f7          	.insn	4, 0x058200f7
     b00:	031e                	.insn	2, 0x031e
     b02:	7f88                	.insn	2, 0x7f88
     b04:	05ba                	.insn	2, 0x05ba
     b06:	0615                	.insn	2, 0x0615
     b08:	0382                	.insn	2, 0x0382
     b0a:	7cf5                	.insn	2, 0x7cf5
     b0c:	0809                	.insn	2, 0x0809
     b0e:	0100                	.insn	2, 0x0100
     b10:	0505                	.insn	2, 0x0505
     b12:	0306                	.insn	2, 0x0306
     b14:	054a0483          	lb	s1,84(s4)
     b18:	0b01                	.insn	2, 0x0b01
     b1a:	ba7f9e03          	lh	t3,-1113(t6)
     b1e:	0505                	.insn	2, 0x0505
     b20:	030a                	.insn	2, 0x030a
     b22:	01b4                	.insn	2, 0x01b4
     b24:	1809                	.insn	2, 0x1809
     b26:	0100                	.insn	2, 0x0100
     b28:	0105                	.insn	2, 0x0105
     b2a:	827dc003          	lbu	zero,-2009(s11)
     b2e:	0505                	.insn	2, 0x0505
     b30:	030a                	.insn	2, 0x030a
     b32:	02d0                	.insn	2, 0x02d0
     b34:	0409                	.insn	2, 0x0409
     b36:	0100                	.insn	2, 0x0100
     b38:	0105                	.insn	2, 0x0105
     b3a:	827dbb03          	.insn	4, 0x827dbb03
     b3e:	0505                	.insn	2, 0x0505
     b40:	030a                	.insn	2, 0x030a
     b42:	02c5                	.insn	2, 0x02c5
     b44:	0409                	.insn	2, 0x0409
     b46:	0100                	.insn	2, 0x0100
     b48:	0105                	.insn	2, 0x0105
     b4a:	827dc603          	lbu	a2,-2009(s11)
     b4e:	0505                	.insn	2, 0x0505
     b50:	030a                	.insn	2, 0x030a
     b52:	02ce                	.insn	2, 0x02ce
     b54:	0409                	.insn	2, 0x0409
     b56:	0100                	.insn	2, 0x0100
     b58:	827db903          	.insn	4, 0x827db903
     b5c:	030a                	.insn	2, 0x030a
     b5e:	02ec                	.insn	2, 0x02ec
     b60:	0409                	.insn	2, 0x0409
     b62:	0100                	.insn	2, 0x0100
     b64:	0105                	.insn	2, 0x0105
     b66:	827da503          	lw	a0,-2009(s11)
     b6a:	0c05                	.insn	2, 0x0c05
     b6c:	030a                	.insn	2, 0x030a
     b6e:	0905                	.insn	2, 0x0905
     b70:	0004                	.insn	2, 0x0004
     b72:	0501                	.insn	2, 0x0501
     b74:	0605                	.insn	2, 0x0605
     b76:	0382                	.insn	2, 0x0382
     b78:	7db8                	.insn	2, 0x7db8
     b7a:	0809                	.insn	2, 0x0809
     b7c:	0100                	.insn	2, 0x0100
     b7e:	0e05                	.insn	2, 0x0e05
     b80:	0306                	.insn	2, 0x0306
     b82:	02c9                	.insn	2, 0x02c9
     b84:	054a                	.insn	2, 0x054a
     b86:	490c                	.insn	2, 0x490c
     b88:	0b05                	.insn	2, 0x0b05
     b8a:	4905054b          	.insn	4, 0x4905054b
     b8e:	0306                	.insn	2, 0x0306
     b90:	7db8                	.insn	2, 0x7db8
     b92:	034a                	.insn	2, 0x034a
     b94:	02c8                	.insn	2, 0x02c8
     b96:	054a                	.insn	2, 0x054a
     b98:	0608                	.insn	2, 0x0608
     b9a:	04090203          	lb	tp,64(s2)
     b9e:	0100                	.insn	2, 0x0100
     ba0:	0505                	.insn	2, 0x0505
     ba2:	0a0c054b          	.insn	4, 0x0a0c054b
     ba6:	04090403          	lb	s0,64(s2)
     baa:	0100                	.insn	2, 0x0100
     bac:	1005                	.insn	2, 0x1005
     bae:	4a06                	.insn	2, 0x4a06
     bb0:	0505                	.insn	2, 0x0505
     bb2:	04090003          	lb	zero,64(s2)
     bb6:	0100                	.insn	2, 0x0100
     bb8:	1305                	.insn	2, 0x1305
     bba:	054a                	.insn	2, 0x054a
     bbc:	4a05                	.insn	2, 0x4a05
     bbe:	0c05                	.insn	2, 0x0c05
     bc0:	04090003          	lb	zero,64(s2)
     bc4:	0100                	.insn	2, 0x0100
     bc6:	0b05                	.insn	2, 0x0b05
     bc8:	4e06                	.insn	2, 0x4e06
     bca:	1005                	.insn	2, 0x1005
     bcc:	0546                	.insn	2, 0x0546
     bce:	09070323          	sb	a6,134(a4)
     bd2:	0008                	.insn	2, 0x0008
     bd4:	0501                	.insn	2, 0x0501
     bd6:	0621                	.insn	2, 0x0621
     bd8:	054a                	.insn	2, 0x054a
     bda:	4a05                	.insn	2, 0x4a05
     bdc:	0005                	.insn	2, 0x0005
     bde:	0306                	.insn	2, 0x0306
     be0:	00d1                	.insn	2, 0x00d1
     be2:	0409                	.insn	2, 0x0409
     be4:	0100                	.insn	2, 0x0100
     be6:	0a05                	.insn	2, 0x0a05
     be8:	4c0a                	.insn	2, 0x4c0a
     bea:	1705                	.insn	2, 0x1705
     bec:	8206                	.insn	2, 0x8206
     bee:	1b05                	.insn	2, 0x1b05
     bf0:	04090003          	lb	zero,64(s2)
     bf4:	0100                	.insn	2, 0x0100
     bf6:	2705                	.insn	2, 0x2705
     bf8:	054a                	.insn	2, 0x054a
     bfa:	060c                	.insn	2, 0x060c
     bfc:	0c090503          	lb	a0,192(s2)
     c00:	0100                	.insn	2, 0x0100
     c02:	0b05                	.insn	2, 0x0b05
     c04:	d5030647          	.insn	4, 0xd5030647
     c08:	4a7c                	.insn	2, 0x4a7c
     c0a:	0505                	.insn	2, 0x0505
     c0c:	0306                	.insn	2, 0x0306
     c0e:	03ae                	.insn	2, 0x03ae
     c10:	0682                	.insn	2, 0x0682
     c12:	097cd203          	lhu	tp,151(s9) # 2d487 <start-0x3d2b79>
     c16:	0008                	.insn	2, 0x0008
     c18:	0601                	.insn	2, 0x0601
     c1a:	8203ae03          	lw	t3,-2016(t2)
     c1e:	0306                	.insn	2, 0x0306
     c20:	7cd2                	.insn	2, 0x7cd2
     c22:	0809                	.insn	2, 0x0809
     c24:	0100                	.insn	2, 0x0100
     c26:	1605                	.insn	2, 0x1605
     c28:	0306                	.insn	2, 0x0306
     c2a:	03b1                	.insn	2, 0x03b1
     c2c:	0682                	.insn	2, 0x0682
     c2e:	4a7ccf03          	lbu	t5,1191(s9)
     c32:	0306                	.insn	2, 0x0306
     c34:	03b1                	.insn	2, 0x03b1
     c36:	06ba                	.insn	2, 0x06ba
     c38:	097ccf03          	lbu	t5,151(s9)
     c3c:	0008                	.insn	2, 0x0008
     c3e:	0501                	.insn	2, 0x0501
     c40:	b503060f          	.insn	4, 0xb503060f
     c44:	1b058203          	lb	tp,432(a1)
     c48:	08097d03          	.insn	4, 0x08097d03
     c4c:	0100                	.insn	2, 0x0100
     c4e:	0306                	.insn	2, 0x0306
     c50:	7cce                	.insn	2, 0x7cce
     c52:	0809                	.insn	2, 0x0809
     c54:	0100                	.insn	2, 0x0100
     c56:	0f05                	.insn	2, 0x0f05
     c58:	0306                	.insn	2, 0x0306
     c5a:	03b5                	.insn	2, 0x03b5
     c5c:	0582                	.insn	2, 0x0582
     c5e:	097e031b          	.insn	4, 0x097e031b
     c62:	0008                	.insn	2, 0x0008
     c64:	0601                	.insn	2, 0x0601
     c66:	097ccd03          	lbu	s10,151(s9)
     c6a:	0008                	.insn	2, 0x0008
     c6c:	0501                	.insn	2, 0x0501
     c6e:	b503060f          	.insn	4, 0xb503060f
     c72:	0c058203          	lb	tp,192(a1)
     c76:	04097903          	.insn	4, 0x04097903
     c7a:	0100                	.insn	2, 0x0100
     c7c:	0f05                	.insn	2, 0x0f05
     c7e:	0552                	.insn	2, 0x0552
     c80:	0616                	.insn	2, 0x0616
     c82:	054a                	.insn	2, 0x054a
     c84:	0605                	.insn	2, 0x0605
     c86:	034a7803          	.insn	4, 0x034a7803
     c8a:	090a                	.insn	2, 0x090a
     c8c:	0008                	.insn	2, 0x0008
     c8e:	0501                	.insn	2, 0x0501
     c90:	0300                	.insn	2, 0x0300
     c92:	0905                	.insn	2, 0x0905
     c94:	0004                	.insn	2, 0x0004
     c96:	0501                	.insn	2, 0x0501
     c98:	064b0a0b          	.insn	4, 0x064b0a0b
     c9c:	097cc203          	lbu	tp,151(s9)
     ca0:	0004                	.insn	2, 0x0004
     ca2:	0501                	.insn	2, 0x0501
     ca4:	0601                	.insn	2, 0x0601
     ca6:	4a03c503          	lbu	a0,1184(t2)
     caa:	0306                	.insn	2, 0x0306
     cac:	054a7cbb          	.insn	4, 0x054a7cbb
     cb0:	0605                	.insn	2, 0x0605
     cb2:	ba03c003          	lbu	zero,-1120(t2)
     cb6:	0306                	.insn	2, 0x0306
     cb8:	7cc0                	.insn	2, 0x7cc0
     cba:	0409                	.insn	2, 0x0409
     cbc:	0100                	.insn	2, 0x0100
     cbe:	0f05                	.insn	2, 0x0f05
     cc0:	0306                	.insn	2, 0x0306
     cc2:	03c1                	.insn	2, 0x03c1
     cc4:	054a                	.insn	2, 0x054a
     cc6:	054a0613          	addi	a2,s4,84
     cca:	7f030627          	.insn	4, 0x7f030627
     cce:	0409                	.insn	2, 0x0409
     cd0:	0100                	.insn	2, 0x0100
     cd2:	1c05                	.insn	2, 0x1c05
     cd4:	4a06                	.insn	2, 0x4a06
     cd6:	0505                	.insn	2, 0x0505
     cd8:	054a                	.insn	2, 0x054a
     cda:	0601                	.insn	2, 0x0601
     cdc:	04090503          	lb	a0,64(s2)
     ce0:	0100                	.insn	2, 0x0100
     ce2:	0505                	.insn	2, 0x0505
     ce4:	030a                	.insn	2, 0x030a
     ce6:	040900cb          	.insn	4, 0x040900cb
     cea:	0100                	.insn	2, 0x0100
     cec:	0ac2                	.insn	2, 0x0ac2
     cee:	08090603          	lb	a2,128(s2)
     cf2:	0100                	.insn	2, 0x0100
     cf4:	0ac2                	.insn	2, 0x0ac2
     cf6:	0900e503          	.insn	4, 0x0900e503
     cfa:	0008                	.insn	2, 0x0008
     cfc:	8901                	.insn	2, 0x8901
     cfe:	030a                	.insn	2, 0x030a
     d00:	091c                	.insn	2, 0x091c
     d02:	0004                	.insn	2, 0x0004
     d04:	8901                	.insn	2, 0x8901
     d06:	0402                	.insn	2, 0x0402
     d08:	0100                	.insn	2, 0x0100
     d0a:	0501                	.insn	2, 0x0501
     d0c:	0a05                	.insn	2, 0x0a05
     d0e:	0500                	.insn	2, 0x0500
     d10:	0002                	.insn	2, 0x0002
     d12:	4000                	.insn	2, 0x4000
     d14:	0300                	.insn	2, 0x0300
     d16:	020105bb          	.insn	4, 0x020105bb
     d1a:	001c                	.insn	2, 0x001c
     d1c:	0101                	.insn	2, 0x0101
     d1e:	0845                	.insn	2, 0x0845
     d20:	0000                	.insn	2, 0x0000
     d22:	0005                	.insn	2, 0x0005
     d24:	0004                	.insn	2, 0x0004
     d26:	007a                	.insn	2, 0x007a
     d28:	0000                	.insn	2, 0x0000
     d2a:	0101                	.insn	2, 0x0101
     d2c:	fb01                	.insn	2, 0xfb01
     d2e:	0d0e                	.insn	2, 0x0d0e
     d30:	0100                	.insn	2, 0x0100
     d32:	0101                	.insn	2, 0x0101
     d34:	0001                	.insn	2, 0x0001
     d36:	0000                	.insn	2, 0x0000
     d38:	0001                	.insn	2, 0x0001
     d3a:	0100                	.insn	2, 0x0100
     d3c:	0101                	.insn	2, 0x0101
     d3e:	021f 0000 0000      	.insn	6, 0x021f
     d44:	0035                	.insn	2, 0x0035
     d46:	0000                	.insn	2, 0x0000
     d48:	021f0103          	lb	sp,33(t5)
     d4c:	041e050f          	.insn	4, 0x041e050f
     d50:	009c                	.insn	2, 0x009c
     d52:	0000                	.insn	2, 0x0000
     d54:	3600                	.insn	2, 0x3600
     d56:	f9e5                	.insn	2, 0xf9e5
     d58:	6905                	.insn	2, 0x6905
     d5a:	2600a817          	auipc	a6,0x2600a
     d5e:	a1e5                	.insn	2, 0xa1e5
     d60:	8d59                	.insn	2, 0x8d59
     d62:	de40                	.insn	2, 0xde40
     d64:	0000a067          	.insn	4, 0xa067
     d68:	0100                	.insn	2, 0x0100
     d6a:	e536                	.insn	2, 0xe536
     d6c:	05f9                	.insn	2, 0x05f9
     d6e:	1769                	.insn	2, 0x1769
     d70:	00a8                	.insn	2, 0x00a8
     d72:	e526                	.insn	2, 0xe526
     d74:	59a1                	.insn	2, 0x59a1
     d76:	408d                	.insn	2, 0x408d
     d78:	67de                	.insn	2, 0x67de
     d7a:	00000047          	.insn	4, 0x0047
     d7e:	1801                	.insn	2, 0x1801
     d80:	f72a                	.insn	2, 0xf72a
     d82:	cb68                	.insn	2, 0xcb68
     d84:	80c17313          	andi	t1,sp,-2036
     d88:	3fb02d17          	auipc	s10,0x3fb02
     d8c:	4e4a7593          	andi	a1,s4,1252
     d90:	0000                	.insn	2, 0x0000
     d92:	0100                	.insn	2, 0x0100
     d94:	8925                	.insn	2, 0x8925
     d96:	ef25                	.insn	2, 0xef25
     d98:	9699                	.insn	2, 0x9699
     d9a:	84d0                	.insn	2, 0x84d0
     d9c:	8c71                	.insn	2, 0x8c71
     d9e:	b17c                	.insn	2, 0xb17c
     da0:	b91c                	.insn	2, 0xb91c
     da2:	0500e2fb          	.insn	4, 0x0500e2fb
     da6:	b002                	.insn	2, 0xb002
     da8:	4012                	.insn	2, 0x4012
     daa:	1a00                	.insn	2, 0x1a00
     dac:	0905                	.insn	2, 0x0905
     dae:	080a                	.insn	2, 0x080a
     db0:	0342                	.insn	2, 0x0342
     db2:	00140903          	lb	s2,1(s0)
     db6:	0301                	.insn	2, 0x0301
     db8:	0901                	.insn	2, 0x0901
     dba:	0018                	.insn	2, 0x0018
     dbc:	0601                	.insn	2, 0x0601
     dbe:	06f26d03          	.insn	4, 0x06f26d03
     dc2:	054a1403          	lh	s0,84(s4)
     dc6:	4e18                	.insn	2, 0x4e18
     dc8:	1405                	.insn	2, 0x1405
     dca:	4a00e403          	.insn	4, 0x4a00e403
     dce:	4884                	.insn	2, 0x4884
     dd0:	1505                	.insn	2, 0x1505
     dd2:	061a054b          	.insn	4, 0x061a054b
     dd6:	054a                	.insn	2, 0x054a
     dd8:	061f 0549 0309      	.insn	6, 0x03090549061f
     dde:	7f9e                	.insn	2, 0x7f9e
     de0:	064a                	.insn	2, 0x064a
     de2:	18096603          	.insn	4, 0x18096603
     de6:	0100                	.insn	2, 0x0100
     de8:	0505                	.insn	2, 0x0505
     dea:	0306                	.insn	2, 0x0306
     dec:	4a1d                	.insn	2, 0x4a1d
     dee:	0306                	.insn	2, 0x0306
     df0:	00100963          	beq	zero,ra,e02 <start-0x3ff1fe>
     df4:	0601                	.insn	2, 0x0601
     df6:	05821d03          	lh	s10,88(tp) # 58 <start-0x3fffa8>
     dfa:	8711                	.insn	2, 0x8711
     dfc:	0905                	.insn	2, 0x0905
     dfe:	4a06                	.insn	2, 0x4a06
     e00:	0505                	.insn	2, 0x0505
     e02:	7d06                	.insn	2, 0x7d06
     e04:	08090803          	lb	a6,128(s2)
     e08:	0100                	.insn	2, 0x0100
     e0a:	0306                	.insn	2, 0x0306
     e0c:	0105ba5b          	.insn	4, 0x0105ba5b
     e10:	0b06                	.insn	2, 0x0b06
     e12:	054a2803          	lw	a6,84(s4)
     e16:	0300                	.insn	2, 0x0300
     e18:	00da                	.insn	2, 0x00da
     e1a:	1409                	.insn	2, 0x1409
     e1c:	0100                	.insn	2, 0x0100
     e1e:	0905                	.insn	2, 0x0905
     e20:	080a                	.insn	2, 0x080a
     e22:	fb03063f 033c087e 	.insn	8, 0x033c087efb03063f
     e2a:	0185                	.insn	2, 0x0185
     e2c:	054a                	.insn	2, 0x054a
     e2e:	0614                	.insn	2, 0x0614
     e30:	04090403          	lb	s0,64(s2)
     e34:	0100                	.insn	2, 0x0100
     e36:	0584                	.insn	2, 0x0584
     e38:	4820                	.insn	2, 0x4820
     e3a:	0a05                	.insn	2, 0x0a05
     e3c:	054d                	.insn	2, 0x054d
     e3e:	491f 2505 0549      	.insn	6, 0x05492505491f
     e44:	4914                	.insn	2, 0x4914
     e46:	1f05                	.insn	2, 0x1f05
     e48:	054d                	.insn	2, 0x054d
     e4a:	4926                	.insn	2, 0x4926
     e4c:	1605                	.insn	2, 0x1605
     e4e:	50090547          	.insn	4, 0x50090547
     e52:	0306                	.insn	2, 0x0306
     e54:	7ef2                	.insn	2, 0x7ef2
     e56:	0c09                	.insn	2, 0x0c09
     e58:	0100                	.insn	2, 0x0100
     e5a:	1105                	.insn	2, 0x1105
     e5c:	0306                	.insn	2, 0x0306
     e5e:	01a8                	.insn	2, 0x01a8
     e60:	054a                	.insn	2, 0x054a
     e62:	031d                	.insn	2, 0x031d
     e64:	4a6a                	.insn	2, 0x4a6a
     e66:	1305                	.insn	2, 0x1305
     e68:	054e                	.insn	2, 0x054e
     e6a:	13054f23          	.insn	4, 0x13054f23
     e6e:	054e                	.insn	2, 0x054e
     e70:	031a                	.insn	2, 0x031a
     e72:	4a09                	.insn	2, 0x4a09
     e74:	2705                	.insn	2, 0x2705
     e76:	054d                	.insn	2, 0x054d
     e78:	4a790323          	sb	t2,1190(s2)
     e7c:	1b05                	.insn	2, 0x1b05
     e7e:	0551                	.insn	2, 0x0551
     e80:	18054617          	auipc	a2,0x18054
     e84:	054d                	.insn	2, 0x054d
     e86:	031a                	.insn	2, 0x031a
     e88:	21054a77          	.insn	4, 0x21054a77
     e8c:	03010547          	.insn	4, 0x03010547
     e90:	4a10                	.insn	2, 0x4a10
     e92:	0b06                	.insn	2, 0x0b06
     e94:	054a                	.insn	2, 0x054a
     e96:	0600                	.insn	2, 0x0600
     e98:	097f8003          	lb	zero,151(t6)
     e9c:	0018                	.insn	2, 0x0018
     e9e:	0501                	.insn	2, 0x0501
     ea0:	0a09                	.insn	2, 0x0a09
     ea2:	4002                	.insn	2, 0x4002
     ea4:	0615                	.insn	2, 0x0615
     ea6:	03824f03          	lbu	t5,56(tp) # 38 <start-0x3fffc8>
     eaa:	4a31                	.insn	2, 0x4a31
     eac:	2005                	.insn	2, 0x2005
     eae:	0306                	.insn	2, 0x0306
     eb0:	0904                	.insn	2, 0x0904
     eb2:	0004                	.insn	2, 0x0004
     eb4:	0501                	.insn	2, 0x0501
     eb6:	0314                	.insn	2, 0x0314
     eb8:	00c9                	.insn	2, 0x00c9
     eba:	48ba                	.insn	2, 0x48ba
     ebc:	1505                	.insn	2, 0x1505
     ebe:	061a054b          	.insn	4, 0x061a054b
     ec2:	054a                	.insn	2, 0x054a
     ec4:	061f 0549 0309      	.insn	6, 0x03090549061f
     eca:	054a7fbb          	.insn	4, 0x054a7fbb
     ece:	0301                	.insn	2, 0x0301
     ed0:	00c1                	.insn	2, 0x00c1
     ed2:	1009                	.insn	2, 0x1009
     ed4:	0100                	.insn	2, 0x0100
     ed6:	0b06                	.insn	2, 0x0b06
     ed8:	034a                	.insn	2, 0x034a
     eda:	7f88                	.insn	2, 0x7f88
     edc:	3802                	.insn	2, 0x3802
     ede:	0501                	.insn	2, 0x0501
     ee0:	0620                	.insn	2, 0x0620
     ee2:	0800da03          	lhu	s4,128(ra)
     ee6:	05e4                	.insn	2, 0x05e4
     ee8:	0615                	.insn	2, 0x0615
     eea:	054a                	.insn	2, 0x054a
     eec:	4a24                	.insn	2, 0x4a24
     eee:	0905                	.insn	2, 0x0905
     ef0:	4e06                	.insn	2, 0x4e06
     ef2:	1605                	.insn	2, 0x1605
     ef4:	4a06                	.insn	2, 0x4a06
     ef6:	0d05                	.insn	2, 0x0d05
     ef8:	4c06                	.insn	2, 0x4c06
     efa:	2505                	.insn	2, 0x2505
     efc:	f206                	.insn	2, 0xf206
     efe:	1705                	.insn	2, 0x1705
     f00:	0306                	.insn	2, 0x0306
     f02:	095a                	.insn	2, 0x095a
     f04:	0004                	.insn	2, 0x0004
     f06:	0501                	.insn	2, 0x0501
     f08:	0605                	.insn	2, 0x0605
     f0a:	0582                	.insn	2, 0x0582
     f0c:	060d                	.insn	2, 0x060d
     f0e:	04090503          	lb	a0,64(s2)
     f12:	0100                	.insn	2, 0x0100
     f14:	1205                	.insn	2, 0x1205
     f16:	4a06                	.insn	2, 0x4a06
     f18:	0d05                	.insn	2, 0x0d05
     f1a:	0306                	.insn	2, 0x0306
     f1c:	0908                	.insn	2, 0x0908
     f1e:	0008                	.insn	2, 0x0008
     f20:	0501                	.insn	2, 0x0501
     f22:	054a0613          	addi	a2,s4,84
     f26:	0616                	.insn	2, 0x0616
     f28:	04090803          	lb	a6,64(s2)
     f2c:	0100                	.insn	2, 0x0100
     f2e:	0306                	.insn	2, 0x0306
     f30:	7fb1                	.insn	2, 0x7fb1
     f32:	0409                	.insn	2, 0x0409
     f34:	0100                	.insn	2, 0x0100
     f36:	1105                	.insn	2, 0x1105
     f38:	4a00cf03          	lbu	t5,1184(ra)
     f3c:	1605                	.insn	2, 0x1605
     f3e:	054a                	.insn	2, 0x054a
     f40:	0620                	.insn	2, 0x0620
     f42:	08090103          	lb	sp,128(s2)
     f46:	0100                	.insn	2, 0x0100
     f48:	1105                	.insn	2, 0x1105
     f4a:	0581                	.insn	2, 0x0581
     f4c:	0616                	.insn	2, 0x0616
     f4e:	054a                	.insn	2, 0x054a
     f50:	0620                	.insn	2, 0x0620
     f52:	04090103          	lb	sp,64(s2)
     f56:	0100                	.insn	2, 0x0100
     f58:	1c05                	.insn	2, 0x1c05
     f5a:	4a06                	.insn	2, 0x4a06
     f5c:	2005                	.insn	2, 0x2005
     f5e:	054a                	.insn	2, 0x054a
     f60:	0611                	.insn	2, 0x0611
     f62:	0549                	.insn	2, 0x0549
     f64:	0616                	.insn	2, 0x0616
     f66:	054a                	.insn	2, 0x054a
     f68:	0311                	.insn	2, 0x0311
     f6a:	0900                	.insn	2, 0x0900
     f6c:	0004                	.insn	2, 0x0004
     f6e:	0501                	.insn	2, 0x0501
     f70:	4a16                	.insn	2, 0x4a16
     f72:	1105                	.insn	2, 0x1105
     f74:	04090003          	lb	zero,64(s2)
     f78:	0100                	.insn	2, 0x0100
     f7a:	1605                	.insn	2, 0x1605
     f7c:	054a                	.insn	2, 0x054a
     f7e:	0311                	.insn	2, 0x0311
     f80:	0900                	.insn	2, 0x0900
     f82:	0004                	.insn	2, 0x0004
     f84:	0501                	.insn	2, 0x0501
     f86:	4a16                	.insn	2, 0x4a16
     f88:	1105                	.insn	2, 0x1105
     f8a:	04090003          	lb	zero,64(s2)
     f8e:	0100                	.insn	2, 0x0100
     f90:	1605                	.insn	2, 0x1605
     f92:	054a                	.insn	2, 0x054a
     f94:	0311                	.insn	2, 0x0311
     f96:	0900                	.insn	2, 0x0900
     f98:	0004                	.insn	2, 0x0004
     f9a:	0501                	.insn	2, 0x0501
     f9c:	4a16                	.insn	2, 0x4a16
     f9e:	0d05                	.insn	2, 0x0d05
     fa0:	0306                	.insn	2, 0x0306
     fa2:	0905                	.insn	2, 0x0905
     fa4:	0004                	.insn	2, 0x0004
     fa6:	0501                	.insn	2, 0x0501
     fa8:	0612                	.insn	2, 0x0612
     faa:	054a                	.insn	2, 0x054a
     fac:	0611                	.insn	2, 0x0611
     fae:	08097c03          	.insn	4, 0x08097c03
     fb2:	0100                	.insn	2, 0x0100
     fb4:	1c05                	.insn	2, 0x1c05
     fb6:	4a06                	.insn	2, 0x4a06
     fb8:	2005                	.insn	2, 0x2005
     fba:	054a                	.insn	2, 0x054a
     fbc:	0611                	.insn	2, 0x0611
     fbe:	0549                	.insn	2, 0x0549
     fc0:	0616                	.insn	2, 0x0616
     fc2:	054a                	.insn	2, 0x054a
     fc4:	0611                	.insn	2, 0x0611
     fc6:	04090103          	lb	sp,64(s2)
     fca:	0100                	.insn	2, 0x0100
     fcc:	1c05                	.insn	2, 0x1c05
     fce:	4a06                	.insn	2, 0x4a06
     fd0:	2005                	.insn	2, 0x2005
     fd2:	054a                	.insn	2, 0x054a
     fd4:	0611                	.insn	2, 0x0611
     fd6:	0549                	.insn	2, 0x0549
     fd8:	0616                	.insn	2, 0x0616
     fda:	054a                	.insn	2, 0x054a
     fdc:	0611                	.insn	2, 0x0611
     fde:	04090103          	lb	sp,64(s2)
     fe2:	0100                	.insn	2, 0x0100
     fe4:	1c05                	.insn	2, 0x1c05
     fe6:	4a06                	.insn	2, 0x4a06
     fe8:	2005                	.insn	2, 0x2005
     fea:	054a                	.insn	2, 0x054a
     fec:	0611                	.insn	2, 0x0611
     fee:	0549                	.insn	2, 0x0549
     ff0:	0616                	.insn	2, 0x0616
     ff2:	054a                	.insn	2, 0x054a
     ff4:	0611                	.insn	2, 0x0611
     ff6:	04090103          	lb	sp,64(s2)
     ffa:	0100                	.insn	2, 0x0100
     ffc:	1c05                	.insn	2, 0x1c05
     ffe:	4a06                	.insn	2, 0x4a06
    1000:	2005                	.insn	2, 0x2005
    1002:	054a                	.insn	2, 0x054a
    1004:	0611                	.insn	2, 0x0611
    1006:	0549                	.insn	2, 0x0549
    1008:	0616                	.insn	2, 0x0616
    100a:	054a                	.insn	2, 0x054a
    100c:	0611                	.insn	2, 0x0611
    100e:	04090103          	lb	sp,64(s2)
    1012:	0100                	.insn	2, 0x0100
    1014:	1c05                	.insn	2, 0x1c05
    1016:	4a06                	.insn	2, 0x4a06
    1018:	2005                	.insn	2, 0x2005
    101a:	054a                	.insn	2, 0x054a
    101c:	0611                	.insn	2, 0x0611
    101e:	0549                	.insn	2, 0x0549
    1020:	0616                	.insn	2, 0x0616
    1022:	054a                	.insn	2, 0x054a
    1024:	0611                	.insn	2, 0x0611
    1026:	04090103          	lb	sp,64(s2)
    102a:	0100                	.insn	2, 0x0100
    102c:	1c05                	.insn	2, 0x1c05
    102e:	4a06                	.insn	2, 0x4a06
    1030:	2005                	.insn	2, 0x2005
    1032:	054a                	.insn	2, 0x054a
    1034:	060d                	.insn	2, 0x060d
    1036:	054e                	.insn	2, 0x054e
    1038:	0612                	.insn	2, 0x0612
    103a:	054a                	.insn	2, 0x054a
    103c:	0615                	.insn	2, 0x0615
    103e:	04090503          	lb	a0,64(s2)
    1042:	0100                	.insn	2, 0x0100
    1044:	0d05                	.insn	2, 0x0d05
    1046:	061c0547          	.insn	4, 0x061c0547
    104a:	054a                	.insn	2, 0x054a
    104c:	0624                	.insn	2, 0x0624
    104e:	054e                	.insn	2, 0x054e
    1050:	0620                	.insn	2, 0x0620
    1052:	054a                	.insn	2, 0x054a
    1054:	061a                	.insn	2, 0x061a
    1056:	0549                	.insn	2, 0x0549
    1058:	0315                	.insn	2, 0x0315
    105a:	0901                	.insn	2, 0x0901
    105c:	0004                	.insn	2, 0x0004
    105e:	0501                	.insn	2, 0x0501
    1060:	0620                	.insn	2, 0x0620
    1062:	054a                	.insn	2, 0x054a
    1064:	4a24                	.insn	2, 0x4a24
    1066:	1505                	.insn	2, 0x1505
    1068:	8106                	.insn	2, 0x8106
    106a:	1a05                	.insn	2, 0x1a05
    106c:	4a06                	.insn	2, 0x4a06
    106e:	097fa703          	lw	a4,151(t6)
    1072:	0004                	.insn	2, 0x0004
    1074:	0301                	.insn	2, 0x0301
    1076:	00d9                	.insn	2, 0x00d9
    1078:	034a                	.insn	2, 0x034a
    107a:	054a7fa7          	.insn	4, 0x054a7fa7
    107e:	0612                	.insn	2, 0x0612
    1080:	4a00e403          	.insn	4, 0x4a00e403
    1084:	1c05                	.insn	2, 0x1c05
    1086:	4e49                	.insn	2, 0x4e49
    1088:	4d18054b          	.insn	4, 0x4d18054b
    108c:	2305                	.insn	2, 0x2305
    108e:	057e                	.insn	2, 0x057e
    1090:	4b22                	.insn	2, 0x4b22
    1092:	1805                	.insn	2, 0x1805
    1094:	054d                	.insn	2, 0x054d
    1096:	061f 054a 0616      	.insn	6, 0x0616054a061f
    109c:	0549                	.insn	2, 0x0549
    109e:	4f1c                	.insn	2, 0x4f1c
    10a0:	4b12054b          	.insn	4, 0x4b12054b
    10a4:	1c05                	.insn	2, 0x1c05
    10a6:	4b220547          	.insn	4, 0x4b220547
    10aa:	23054b4b          	.insn	4, 0x23054b4b
    10ae:	4b280547          	.insn	4, 0x4b280547
    10b2:	2905                	.insn	2, 0x2905
    10b4:	4713054b          	.insn	4, 0x4713054b
    10b8:	1405                	.insn	2, 0x1405
    10ba:	030a                	.insn	2, 0x030a
    10bc:	0008090f          	.insn	4, 0x0008090f
    10c0:	8401                	.insn	2, 0x8401
    10c2:	0548                	.insn	2, 0x0548
    10c4:	4b15                	.insn	2, 0x4b15
    10c6:	1a05                	.insn	2, 0x1a05
    10c8:	4a06                	.insn	2, 0x4a06
    10ca:	1f05                	.insn	2, 0x1f05
    10cc:	4906                	.insn	2, 0x4906
    10ce:	0505                	.insn	2, 0x0505
    10d0:	4a06                	.insn	2, 0x4a06
    10d2:	0005                	.insn	2, 0x0005
    10d4:	0306                	.insn	2, 0x0306
    10d6:	0935                	.insn	2, 0x0935
    10d8:	0004                	.insn	2, 0x0004
    10da:	0501                	.insn	2, 0x0501
    10dc:	0a09                	.insn	2, 0x0a09
    10de:	2c02                	.insn	2, 0x2c02
    10e0:	0515                	.insn	2, 0x0515
    10e2:	0320                	.insn	2, 0x0320
    10e4:	0904                	.insn	2, 0x0904
    10e6:	000c                	.insn	2, 0x000c
    10e8:	0501                	.insn	2, 0x0501
    10ea:	0314                	.insn	2, 0x0314
    10ec:	ba46                	.insn	2, 0xba46
    10ee:	0548                	.insn	2, 0x0548
    10f0:	4b15                	.insn	2, 0x4b15
    10f2:	1a05                	.insn	2, 0x1a05
    10f4:	4a06                	.insn	2, 0x4a06
    10f6:	1f05                	.insn	2, 0x1f05
    10f8:	4906                	.insn	2, 0x4906
    10fa:	0905                	.insn	2, 0x0905
    10fc:	054a3e03          	.insn	4, 0x054a3e03
    1100:	0b01                	.insn	2, 0x0b01
    1102:	10093b03          	.insn	4, 0x10093b03
    1106:	0100                	.insn	2, 0x0100
    1108:	0306                	.insn	2, 0x0306
    110a:	30027e8b          	.insn	4, 0x30027e8b
    110e:	0501                	.insn	2, 0x0501
    1110:	0614                	.insn	2, 0x0614
    1112:	0200fe03          	.insn	4, 0x0200fe03
    1116:	012c                	.insn	2, 0x012c
    1118:	0548                	.insn	2, 0x0548
    111a:	4b15                	.insn	2, 0x4b15
    111c:	1a05                	.insn	2, 0x1a05
    111e:	4a06                	.insn	2, 0x4a06
    1120:	1f05                	.insn	2, 0x1f05
    1122:	4906                	.insn	2, 0x4906
    1124:	1805                	.insn	2, 0x1805
    1126:	4a00ef03          	.insn	4, 0x4a00ef03
    112a:	4c49                	.insn	2, 0x4c49
    112c:	0e05                	.insn	2, 0x0e05
    112e:	481e054b          	.insn	4, 0x481e054b
    1132:	1f05                	.insn	2, 0x1f05
    1134:	0549                	.insn	2, 0x0549
    1136:	4c1e                	.insn	2, 0x4c1e
    1138:	4824054b          	.insn	4, 0x4824054b
    113c:	2505                	.insn	2, 0x2505
    113e:	4e09054b          	.insn	4, 0x4e09054b
    1142:	1705                	.insn	2, 0x1705
    1144:	05ba4d03          	lbu	s10,91(s4)
    1148:	0605                	.insn	2, 0x0605
    114a:	0582                	.insn	2, 0x0582
    114c:	060d                	.insn	2, 0x060d
    114e:	04090403          	lb	s0,64(s2)
    1152:	0100                	.insn	2, 0x0100
    1154:	1205                	.insn	2, 0x1205
    1156:	4a06                	.insn	2, 0x4a06
    1158:	0d05                	.insn	2, 0x0d05
    115a:	0306                	.insn	2, 0x0306
    115c:	0906                	.insn	2, 0x0906
    115e:	0008                	.insn	2, 0x0008
    1160:	0501                	.insn	2, 0x0501
    1162:	054a0613          	addi	a2,s4,84
    1166:	0616                	.insn	2, 0x0616
    1168:	04090403          	lb	s0,64(s2)
    116c:	0100                	.insn	2, 0x0100
    116e:	1105                	.insn	2, 0x1105
    1170:	0306                	.insn	2, 0x0306
    1172:	0900                	.insn	2, 0x0900
    1174:	0004                	.insn	2, 0x0004
    1176:	0501                	.insn	2, 0x0501
    1178:	4a16                	.insn	2, 0x4a16
    117a:	1105                	.insn	2, 0x1105
    117c:	04090003          	lb	zero,64(s2)
    1180:	0100                	.insn	2, 0x0100
    1182:	1605                	.insn	2, 0x1605
    1184:	054a                	.insn	2, 0x054a
    1186:	0311                	.insn	2, 0x0311
    1188:	0900                	.insn	2, 0x0900
    118a:	0004                	.insn	2, 0x0004
    118c:	0501                	.insn	2, 0x0501
    118e:	4a16                	.insn	2, 0x4a16
    1190:	1105                	.insn	2, 0x1105
    1192:	04090003          	lb	zero,64(s2)
    1196:	0100                	.insn	2, 0x0100
    1198:	1605                	.insn	2, 0x1605
    119a:	054a                	.insn	2, 0x054a
    119c:	0311                	.insn	2, 0x0311
    119e:	0900                	.insn	2, 0x0900
    11a0:	0004                	.insn	2, 0x0004
    11a2:	0501                	.insn	2, 0x0501
    11a4:	4a16                	.insn	2, 0x4a16
    11a6:	1105                	.insn	2, 0x1105
    11a8:	04090003          	lb	zero,64(s2)
    11ac:	0100                	.insn	2, 0x0100
    11ae:	1605                	.insn	2, 0x1605
    11b0:	054a                	.insn	2, 0x054a
    11b2:	0311                	.insn	2, 0x0311
    11b4:	0900                	.insn	2, 0x0900
    11b6:	0004                	.insn	2, 0x0004
    11b8:	0501                	.insn	2, 0x0501
    11ba:	4a16                	.insn	2, 0x4a16
    11bc:	0d05                	.insn	2, 0x0d05
    11be:	0306                	.insn	2, 0x0306
    11c0:	0904                	.insn	2, 0x0904
    11c2:	0004                	.insn	2, 0x0004
    11c4:	0501                	.insn	2, 0x0501
    11c6:	0612                	.insn	2, 0x0612
    11c8:	054a                	.insn	2, 0x054a
    11ca:	0611                	.insn	2, 0x0611
    11cc:	08097d03          	.insn	4, 0x08097d03
    11d0:	0100                	.insn	2, 0x0100
    11d2:	0581                	.insn	2, 0x0581
    11d4:	0616                	.insn	2, 0x0616
    11d6:	054a                	.insn	2, 0x054a
    11d8:	0611                	.insn	2, 0x0611
    11da:	04090103          	lb	sp,64(s2)
    11de:	0100                	.insn	2, 0x0100
    11e0:	0581                	.insn	2, 0x0581
    11e2:	0616                	.insn	2, 0x0616
    11e4:	054a                	.insn	2, 0x054a
    11e6:	0611                	.insn	2, 0x0611
    11e8:	04090103          	lb	sp,64(s2)
    11ec:	0100                	.insn	2, 0x0100
    11ee:	0581                	.insn	2, 0x0581
    11f0:	0616                	.insn	2, 0x0616
    11f2:	054a                	.insn	2, 0x054a
    11f4:	0611                	.insn	2, 0x0611
    11f6:	04090103          	lb	sp,64(s2)
    11fa:	0100                	.insn	2, 0x0100
    11fc:	0581                	.insn	2, 0x0581
    11fe:	0616                	.insn	2, 0x0616
    1200:	054a                	.insn	2, 0x054a
    1202:	0611                	.insn	2, 0x0611
    1204:	04090103          	lb	sp,64(s2)
    1208:	0100                	.insn	2, 0x0100
    120a:	0581                	.insn	2, 0x0581
    120c:	0616                	.insn	2, 0x0616
    120e:	054a                	.insn	2, 0x054a
    1210:	0611                	.insn	2, 0x0611
    1212:	04090103          	lb	sp,64(s2)
    1216:	0100                	.insn	2, 0x0100
    1218:	0581                	.insn	2, 0x0581
    121a:	0616                	.insn	2, 0x0616
    121c:	054a                	.insn	2, 0x054a
    121e:	0611                	.insn	2, 0x0611
    1220:	04090103          	lb	sp,64(s2)
    1224:	0100                	.insn	2, 0x0100
    1226:	0581                	.insn	2, 0x0581
    1228:	0616                	.insn	2, 0x0616
    122a:	054a                	.insn	2, 0x054a
    122c:	0611                	.insn	2, 0x0611
    122e:	04090103          	lb	sp,64(s2)
    1232:	0100                	.insn	2, 0x0100
    1234:	0d05                	.insn	2, 0x0d05
    1236:	0585                	.insn	2, 0x0585
    1238:	0612                	.insn	2, 0x0612
    123a:	054a                	.insn	2, 0x054a
    123c:	060d                	.insn	2, 0x060d
    123e:	04090103          	lb	sp,64(s2)
    1242:	0100                	.insn	2, 0x0100
    1244:	1505                	.insn	2, 0x1505
    1246:	05bc                	.insn	2, 0x05bc
    1248:	061a                	.insn	2, 0x061a
    124a:	054a                	.insn	2, 0x054a
    124c:	0315                	.insn	2, 0x0315
    124e:	0900                	.insn	2, 0x0900
    1250:	0004                	.insn	2, 0x0004
    1252:	0501                	.insn	2, 0x0501
    1254:	4a1a                	.insn	2, 0x4a1a
    1256:	1505                	.insn	2, 0x1505
    1258:	04090003          	lb	zero,64(s2)
    125c:	0100                	.insn	2, 0x0100
    125e:	1a05                	.insn	2, 0x1a05
    1260:	054a                	.insn	2, 0x054a
    1262:	0615                	.insn	2, 0x0615
    1264:	04090103          	lb	sp,64(s2)
    1268:	0100                	.insn	2, 0x0100
    126a:	2605                	.insn	2, 0x2605
    126c:	0586                	.insn	2, 0x0586
    126e:	0609                	.insn	2, 0x0609
    1270:	054a                	.insn	2, 0x054a
    1272:	0618                	.insn	2, 0x0618
    1274:	05c2                	.insn	2, 0x05c2
    1276:	460e                	.insn	2, 0x460e
    1278:	1805                	.insn	2, 0x1805
    127a:	4e49                	.insn	2, 0x4e49
    127c:	1e05                	.insn	2, 0x1e05
    127e:	4d14054b          	.insn	4, 0x4d14054b
    1282:	1f05                	.insn	2, 0x1f05
    1284:	057e                	.insn	2, 0x057e
    1286:	4e14                	.insn	2, 0x4e14
    1288:	1b05                	.insn	2, 0x1b05
    128a:	4a06                	.insn	2, 0x4a06
    128c:	1005                	.insn	2, 0x1005
    128e:	4e06                	.insn	2, 0x4e06
    1290:	0306                	.insn	2, 0x0306
    1292:	7e9a                	.insn	2, 0x7e9a
    1294:	0409                	.insn	2, 0x0409
    1296:	0100                	.insn	2, 0x0100
    1298:	4a01e603          	.insn	4, 0x4a01e603
    129c:	1505                	.insn	2, 0x1505
    129e:	0306                	.insn	2, 0x0306
    12a0:	4a6d                	.insn	2, 0x4a6d
    12a2:	0581                	.insn	2, 0x0581
    12a4:	061a                	.insn	2, 0x061a
    12a6:	054a                	.insn	2, 0x054a
    12a8:	0615                	.insn	2, 0x0615
    12aa:	04090103          	lb	sp,64(s2)
    12ae:	0100                	.insn	2, 0x0100
    12b0:	0581                	.insn	2, 0x0581
    12b2:	061a                	.insn	2, 0x061a
    12b4:	054a                	.insn	2, 0x054a
    12b6:	0600                	.insn	2, 0x0600
    12b8:	0900cc03          	lbu	s8,144(ra)
    12bc:	0008                	.insn	2, 0x0008
    12be:	0501                	.insn	2, 0x0501
    12c0:	0a09                	.insn	2, 0x0a09
    12c2:	e708                	.insn	2, 0xe708
    12c4:	0306                	.insn	2, 0x0306
    12c6:	7ddf 0382 02a1      	.insn	6, 0x02a103827ddf
    12cc:	054a                	.insn	2, 0x054a
    12ce:	0620                	.insn	2, 0x0620
    12d0:	04090403          	lb	s0,64(s2)
    12d4:	0100                	.insn	2, 0x0100
    12d6:	1405                	.insn	2, 0x1405
    12d8:	ba7ed903          	lhu	s2,-1113(t4)
    12dc:	0548                	.insn	2, 0x0548
    12de:	4b15                	.insn	2, 0x4b15
    12e0:	1a05                	.insn	2, 0x1a05
    12e2:	4a06                	.insn	2, 0x4a06
    12e4:	1f05                	.insn	2, 0x1f05
    12e6:	4906                	.insn	2, 0x4906
    12e8:	0905                	.insn	2, 0x0905
    12ea:	4a01ab03          	lw	s6,1184(gp)
    12ee:	0306                	.insn	2, 0x0306
    12f0:	7dd9                	.insn	2, 0x7dd9
    12f2:	1809                	.insn	2, 0x1809
    12f4:	0100                	.insn	2, 0x0100
    12f6:	0c05                	.insn	2, 0x0c05
    12f8:	0306                	.insn	2, 0x0306
    12fa:	0284                	.insn	2, 0x0284
    12fc:	054a                	.insn	2, 0x054a
    12fe:	4510                	.insn	2, 0x4510
    1300:	1205                	.insn	2, 0x1205
    1302:	2c02                	.insn	2, 0x2c02
    1304:	fc030617          	auipc	a2,0xfc030
    1308:	097d                	.insn	2, 0x097d
    130a:	0004                	.insn	2, 0x0004
    130c:	0501                	.insn	2, 0x0501
    130e:	0619                	.insn	2, 0x0619
    1310:	f2028503          	lb	a0,-224(t0)
    1314:	0905                	.insn	2, 0x0905
    1316:	08090303          	lb	t1,128(s2)
    131a:	0100                	.insn	2, 0x0100
    131c:	1405                	.insn	2, 0x1405
    131e:	8206                	.insn	2, 0x8206
    1320:	0c05                	.insn	2, 0x0c05
    1322:	4606                	.insn	2, 0x4606
    1324:	1005                	.insn	2, 0x1005
    1326:	064e                	.insn	2, 0x064e
    1328:	4a7df803          	.insn	4, 0x4a7df803
    132c:	1205                	.insn	2, 0x1205
    132e:	0306                	.insn	2, 0x0306
    1330:	0284                	.insn	2, 0x0284
    1332:	054a                	.insn	2, 0x054a
    1334:	0305                	.insn	2, 0x0305
    1336:	0908                	.insn	2, 0x0908
    1338:	0004                	.insn	2, 0x0004
    133a:	0601                	.insn	2, 0x0601
    133c:	827df403          	.insn	4, 0x827df403
    1340:	1205                	.insn	2, 0x1205
    1342:	0306                	.insn	2, 0x0306
    1344:	0284                	.insn	2, 0x0284
    1346:	064a                	.insn	2, 0x064a
    1348:	4a7dfc03          	.insn	4, 0x4a7dfc03
    134c:	0505                	.insn	2, 0x0505
    134e:	0306                	.insn	2, 0x0306
    1350:	028c                	.insn	2, 0x028c
    1352:	054a                	.insn	2, 0x054a
    1354:	0612                	.insn	2, 0x0612
    1356:	0582                	.insn	2, 0x0582
    1358:	030c                	.insn	2, 0x030c
    135a:	0900                	.insn	2, 0x0900
    135c:	0008                	.insn	2, 0x0008
    135e:	0501                	.insn	2, 0x0501
    1360:	4a05                	.insn	2, 0x4a05
    1362:	1205                	.insn	2, 0x1205
    1364:	054a                	.insn	2, 0x054a
    1366:	0403060f          	.insn	4, 0x0403060f
    136a:	0409                	.insn	2, 0x0409
    136c:	0100                	.insn	2, 0x0100
    136e:	0c05                	.insn	2, 0x0c05
    1370:	0588                	.insn	2, 0x0588
    1372:	0605                	.insn	2, 0x0605
    1374:	0382                	.insn	2, 0x0382
    1376:	7dea                	.insn	2, 0x7dea
    1378:	0409                	.insn	2, 0x0409
    137a:	0100                	.insn	2, 0x0100
    137c:	4a029603          	lh	a2,1184(t0)
    1380:	1405                	.insn	2, 0x1405
    1382:	8306                	.insn	2, 0x8306
    1384:	0c05                	.insn	2, 0x0c05
    1386:	05b9                	.insn	2, 0x05b9
    1388:	0605                	.insn	2, 0x0605
    138a:	054a                	.insn	2, 0x054a
    138c:	0300                	.insn	2, 0x0300
    138e:	7dea                	.insn	2, 0x7dea
    1390:	0409                	.insn	2, 0x0409
    1392:	0100                	.insn	2, 0x0100
    1394:	0505                	.insn	2, 0x0505
    1396:	4a029603          	lh	a2,1184(t0)
    139a:	0d05                	.insn	2, 0x0d05
    139c:	0306                	.insn	2, 0x0306
    139e:	091c                	.insn	2, 0x091c
    13a0:	0008                	.insn	2, 0x0008
    13a2:	0501                	.insn	2, 0x0501
    13a4:	061a                	.insn	2, 0x061a
    13a6:	03ba                	.insn	2, 0x03ba
    13a8:	7dce                	.insn	2, 0x7dce
    13aa:	0409                	.insn	2, 0x0409
    13ac:	0100                	.insn	2, 0x0100
    13ae:	4a02b203          	.insn	4, 0x4a02b203
    13b2:	0d05                	.insn	2, 0x0d05
    13b4:	04090003          	lb	zero,64(s2)
    13b8:	0100                	.insn	2, 0x0100
    13ba:	1a05                	.insn	2, 0x1a05
    13bc:	0382                	.insn	2, 0x0382
    13be:	7dce                	.insn	2, 0x7dce
    13c0:	0409                	.insn	2, 0x0409
    13c2:	0100                	.insn	2, 0x0100
    13c4:	4a02b203          	.insn	4, 0x4a02b203
    13c8:	0d05                	.insn	2, 0x0d05
    13ca:	04090003          	lb	zero,64(s2)
    13ce:	0100                	.insn	2, 0x0100
    13d0:	1a05                	.insn	2, 0x1a05
    13d2:	0382                	.insn	2, 0x0382
    13d4:	7dce                	.insn	2, 0x7dce
    13d6:	0409                	.insn	2, 0x0409
    13d8:	0100                	.insn	2, 0x0100
    13da:	4a02b203          	.insn	4, 0x4a02b203
    13de:	0d05                	.insn	2, 0x0d05
    13e0:	04090003          	lb	zero,64(s2)
    13e4:	0100                	.insn	2, 0x0100
    13e6:	1a05                	.insn	2, 0x1a05
    13e8:	0382                	.insn	2, 0x0382
    13ea:	7dce                	.insn	2, 0x7dce
    13ec:	0409                	.insn	2, 0x0409
    13ee:	0100                	.insn	2, 0x0100
    13f0:	4a02b203          	.insn	4, 0x4a02b203
    13f4:	0d05                	.insn	2, 0x0d05
    13f6:	04090003          	lb	zero,64(s2)
    13fa:	0100                	.insn	2, 0x0100
    13fc:	1a05                	.insn	2, 0x1a05
    13fe:	0382                	.insn	2, 0x0382
    1400:	7dce                	.insn	2, 0x7dce
    1402:	0409                	.insn	2, 0x0409
    1404:	0100                	.insn	2, 0x0100
    1406:	4a02b203          	.insn	4, 0x4a02b203
    140a:	0d05                	.insn	2, 0x0d05
    140c:	04090003          	lb	zero,64(s2)
    1410:	0100                	.insn	2, 0x0100
    1412:	1a05                	.insn	2, 0x1a05
    1414:	0382                	.insn	2, 0x0382
    1416:	7dce                	.insn	2, 0x7dce
    1418:	0409                	.insn	2, 0x0409
    141a:	0100                	.insn	2, 0x0100
    141c:	4a02b203          	.insn	4, 0x4a02b203
    1420:	0d05                	.insn	2, 0x0d05
    1422:	04090003          	lb	zero,64(s2)
    1426:	0100                	.insn	2, 0x0100
    1428:	1a05                	.insn	2, 0x1a05
    142a:	0382                	.insn	2, 0x0382
    142c:	7dce                	.insn	2, 0x7dce
    142e:	0409                	.insn	2, 0x0409
    1430:	0100                	.insn	2, 0x0100
    1432:	4a02b203          	.insn	4, 0x4a02b203
    1436:	0d05                	.insn	2, 0x0d05
    1438:	04090003          	lb	zero,64(s2)
    143c:	0100                	.insn	2, 0x0100
    143e:	1a05                	.insn	2, 0x1a05
    1440:	0382                	.insn	2, 0x0382
    1442:	7dce                	.insn	2, 0x7dce
    1444:	0409                	.insn	2, 0x0409
    1446:	0100                	.insn	2, 0x0100
    1448:	4a02b203          	.insn	4, 0x4a02b203
    144c:	0d05                	.insn	2, 0x0d05
    144e:	04090003          	lb	zero,64(s2)
    1452:	0100                	.insn	2, 0x0100
    1454:	1a05                	.insn	2, 0x1a05
    1456:	0382                	.insn	2, 0x0382
    1458:	7dce                	.insn	2, 0x7dce
    145a:	0409                	.insn	2, 0x0409
    145c:	0100                	.insn	2, 0x0100
    145e:	4a02b203          	.insn	4, 0x4a02b203
    1462:	0d05                	.insn	2, 0x0d05
    1464:	04090003          	lb	zero,64(s2)
    1468:	0100                	.insn	2, 0x0100
    146a:	1a05                	.insn	2, 0x1a05
    146c:	0382                	.insn	2, 0x0382
    146e:	7dce                	.insn	2, 0x7dce
    1470:	0409                	.insn	2, 0x0409
    1472:	0100                	.insn	2, 0x0100
    1474:	4a02b203          	.insn	4, 0x4a02b203
    1478:	0d05                	.insn	2, 0x0d05
    147a:	04090003          	lb	zero,64(s2)
    147e:	0100                	.insn	2, 0x0100
    1480:	1a05                	.insn	2, 0x1a05
    1482:	0382                	.insn	2, 0x0382
    1484:	7dce                	.insn	2, 0x7dce
    1486:	0409                	.insn	2, 0x0409
    1488:	0100                	.insn	2, 0x0100
    148a:	4a02b203          	.insn	4, 0x4a02b203
    148e:	0d05                	.insn	2, 0x0d05
    1490:	04090003          	lb	zero,64(s2)
    1494:	0100                	.insn	2, 0x0100
    1496:	1a05                	.insn	2, 0x1a05
    1498:	0382                	.insn	2, 0x0382
    149a:	7dce                	.insn	2, 0x7dce
    149c:	0409                	.insn	2, 0x0409
    149e:	0100                	.insn	2, 0x0100
    14a0:	4a02b203          	.insn	4, 0x4a02b203
    14a4:	0d05                	.insn	2, 0x0d05
    14a6:	04090003          	lb	zero,64(s2)
    14aa:	0100                	.insn	2, 0x0100
    14ac:	1a05                	.insn	2, 0x1a05
    14ae:	0382                	.insn	2, 0x0382
    14b0:	7dce                	.insn	2, 0x7dce
    14b2:	0409                	.insn	2, 0x0409
    14b4:	0100                	.insn	2, 0x0100
    14b6:	4a02b203          	.insn	4, 0x4a02b203
    14ba:	0d05                	.insn	2, 0x0d05
    14bc:	04090003          	lb	zero,64(s2)
    14c0:	0100                	.insn	2, 0x0100
    14c2:	1a05                	.insn	2, 0x1a05
    14c4:	0382                	.insn	2, 0x0382
    14c6:	7dce                	.insn	2, 0x7dce
    14c8:	0409                	.insn	2, 0x0409
    14ca:	0100                	.insn	2, 0x0100
    14cc:	4a02b203          	.insn	4, 0x4a02b203
    14d0:	0d05                	.insn	2, 0x0d05
    14d2:	04090003          	lb	zero,64(s2)
    14d6:	0100                	.insn	2, 0x0100
    14d8:	1a05                	.insn	2, 0x1a05
    14da:	0382                	.insn	2, 0x0382
    14dc:	7dce                	.insn	2, 0x7dce
    14de:	0409                	.insn	2, 0x0409
    14e0:	0100                	.insn	2, 0x0100
    14e2:	4a02b203          	.insn	4, 0x4a02b203
    14e6:	0d05                	.insn	2, 0x0d05
    14e8:	04090003          	lb	zero,64(s2)
    14ec:	0100                	.insn	2, 0x0100
    14ee:	1a05                	.insn	2, 0x1a05
    14f0:	0382                	.insn	2, 0x0382
    14f2:	7dce                	.insn	2, 0x7dce
    14f4:	0409                	.insn	2, 0x0409
    14f6:	0100                	.insn	2, 0x0100
    14f8:	4a02b203          	.insn	4, 0x4a02b203
    14fc:	1205                	.insn	2, 0x1205
    14fe:	0306                	.insn	2, 0x0306
    1500:	0905                	.insn	2, 0x0905
    1502:	0004                	.insn	2, 0x0004
    1504:	0501                	.insn	2, 0x0501
    1506:	080a030f          	.insn	4, 0x080a030f
    150a:	4be4                	.insn	2, 0x4be4
    150c:	1205                	.insn	2, 0x1205
    150e:	054a7503          	.insn	4, 0x054a7503
    1512:	8614                	.insn	2, 0x8614
    1514:	1205                	.insn	2, 0x1205
    1516:	0806                	.insn	2, 0x0806
    1518:	05e4                	.insn	2, 0x05e4
    151a:	f214                	.insn	2, 0xf214
    151c:	1205                	.insn	2, 0x1205
    151e:	03ba                	.insn	2, 0x03ba
    1520:	7dc5                	.insn	2, 0x7dc5
    1522:	06f2                	.insn	2, 0x06f2
    1524:	4a02b703          	.insn	4, 0x4a02b703
    1528:	0f05                	.insn	2, 0x0f05
    152a:	4b820c03          	lb	s8,1208(tp) # 4b8 <start-0x3ffb48>
    152e:	1205                	.insn	2, 0x1205
    1530:	054a7703          	.insn	4, 0x054a7703
    1534:	0903bd0f          	.insn	4, 0x0903bd0f
    1538:	4b4a                	.insn	2, 0x4b4a
    153a:	09054b4b          	.insn	4, 0x09054b4b
    153e:	fa4c                	.insn	2, 0xfa4c
    1540:	0d05                	.insn	2, 0x0d05
    1542:	06f4                	.insn	2, 0x06f4
    1544:	097daa03          	lw	s4,151(s11)
    1548:	0014                	.insn	2, 0x0014
    154a:	0501                	.insn	2, 0x0501
    154c:	0609                	.insn	2, 0x0609
    154e:	8202d903          	lhu	s2,-2016(t0)
    1552:	0306                	.insn	2, 0x0306
    1554:	3c087da7          	.insn	4, 0x3c087da7
    1558:	0105                	.insn	2, 0x0105
    155a:	0306                	.insn	2, 0x0306
    155c:	02df 064a 4a0b      	.insn	6, 0x4a0b064a02df
    1562:	2002                	.insn	2, 0x2002
    1564:	0100                	.insn	2, 0x0100
    1566:	01                	.byte	0x01

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
