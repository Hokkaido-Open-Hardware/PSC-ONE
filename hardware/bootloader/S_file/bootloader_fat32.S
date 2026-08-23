
./build/bootloader_fat32.elf:     file format elf32-littleriscv


Disassembly of section .text:

00100000 <_start>:
.section .text
.globl _start
_start:
    la sp, _stack_top
  100000:	00008117          	auipc	sp,0x8
  100004:	ba010113          	addi	sp,sp,-1120 # 107ba0 <g_data_begin_lba>
    call bootloader_main
  100008:	00000097          	auipc	ra,0x0
  10000c:	04c080e7          	jalr	76(ra) # 100054 <bootloader_main>
1:
    j 1b
  100010:	0000006f          	j	100010 <_start+0x10>

00100014 <putchar>:
#ifndef USER_LOAD_ADDR
#define USER_LOAD_ADDR      0x00400000u
#endif

void putchar(char ch)
{
  100014:	100005b7          	lui	a1,0x10000

static inline void mmio_w32(uint32_t addr, uint32_t v) {
    *(volatile uint32_t*)addr = v;
}
static inline uint32_t mmio_r32(uint32_t addr) {
    return *(volatile uint32_t*)addr;
  100018:	0085a603          	lw	a2,8(a1) # 10000008 <_stack_top+0xfef4048>
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  10001c:	00167613          	andi	a2,a2,1
  100020:	00060663          	beqz	a2,10002c <putchar+0x18>
        __asm__ __volatile__("nop");
  100024:	00000013          	nop
  100028:	ff1ff06f          	j	100018 <putchar+0x4>
    *(volatile uint32_t*)addr = v;
  10002c:	00a5a023          	sw	a0,0(a1)
    }

    mmio_w32(UART_MMIO_BASE + UART_TX, (uint32_t)(uint8_t)ch);
}
  100030:	00008067          	ret

00100034 <uart_putchar>:

void uart_putchar(char c)
{
  100034:	100005b7          	lui	a1,0x10000
    return *(volatile uint32_t*)addr;
  100038:	0085a603          	lw	a2,8(a1) # 10000008 <_stack_top+0xfef4048>
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  10003c:	00167613          	andi	a2,a2,1
  100040:	00060663          	beqz	a2,10004c <uart_putchar+0x18>
        __asm__ __volatile__("nop");
  100044:	00000013          	nop
  100048:	ff1ff06f          	j	100038 <uart_putchar+0x4>
    *(volatile uint32_t*)addr = v;
  10004c:	00a5a023          	sw	a0,0(a1)
    putchar(c);
}
  100050:	00008067          	ret

00100054 <bootloader_main>:
    void (*entry)(void) = (void (*)(void))addr;
    entry();
}

void bootloader_main(void)
{
  100054:	fe010113          	addi	sp,sp,-32
  100058:	00112e23          	sw	ra,28(sp)
  10005c:	00812c23          	sw	s0,24(sp)
  100060:	00912a23          	sw	s1,20(sp)
  100064:	01212823          	sw	s2,16(sp)
  100068:	00000513          	li	a0,0
  10006c:	10000437          	lui	s0,0x10000
    uint32_t kernel_words = 0;
  100070:	00012623          	sw	zero,12(sp)
    uint32_t user_words = 0;
  100074:	00012423          	sw	zero,8(sp)
  100078:	06200613          	li	a2,98
  10007c:	001035b7          	lui	a1,0x103
  100080:	14c58593          	addi	a1,a1,332 # 10314c <boot_fat32_load_mem_file+0x404>
  100084:	01700693          	li	a3,23
  100088:	0080006f          	j	100090 <bootloader_main+0x3c>
        __asm__ __volatile__("nop");
  10008c:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100090:	00842703          	lw	a4,8(s0) # 10000008 <_stack_top+0xfef4048>
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100094:	00177713          	andi	a4,a4,1
  100098:	fe071ae3          	bnez	a4,10008c <bootloader_main+0x38>
        putchar(*s++);
  10009c:	00150513          	addi	a0,a0,1
  1000a0:	00a58733          	add	a4,a1,a0
    *(volatile uint32_t*)addr = v;
  1000a4:	00c42023          	sw	a2,0(s0)
    while (*s) {
  1000a8:	00074603          	lbu	a2,0(a4)
  1000ac:	fed512e3          	bne	a0,a3,100090 <bootloader_main+0x3c>
  1000b0:	10006537          	lui	a0,0x10006
  1000b4:	00400593          	li	a1,4
    PSC_SD_IF_CTRL = SD_CTRL_FIFO_FLUSH;
  1000b8:	00b52423          	sw	a1,8(a0) # 10006008 <_stack_top+0xfefa048>
  1000bc:	f9c00593          	li	a1,-100
    while (n--) {
  1000c0:	00158593          	addi	a1,a1,1
        __asm__ __volatile__("nop");
  1000c4:	00000013          	nop
    while (n--) {
  1000c8:	fe059ce3          	bnez	a1,1000c0 <bootloader_main+0x6c>
  1000cc:	05300693          	li	a3,83
  1000d0:	00103637          	lui	a2,0x103
  1000d4:	21760613          	addi	a2,a2,535 # 103217 <boot_fat32_load_mem_file+0x4cf>
  1000d8:	10000737          	lui	a4,0x10000
  1000dc:	00e00793          	li	a5,14
  1000e0:	0080006f          	j	1000e8 <bootloader_main+0x94>
        __asm__ __volatile__("nop");
  1000e4:	00000013          	nop
    return *(volatile uint32_t*)addr;
  1000e8:	00842803          	lw	a6,8(s0)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  1000ec:	00187813          	andi	a6,a6,1
  1000f0:	fe081ae3          	bnez	a6,1000e4 <bootloader_main+0x90>
        putchar(*s++);
  1000f4:	00158593          	addi	a1,a1,1
  1000f8:	00b60833          	add	a6,a2,a1
    *(volatile uint32_t*)addr = v;
  1000fc:	00d72023          	sw	a3,0(a4) # 10000000 <_stack_top+0xfef4040>
    while (*s) {
  100100:	00084683          	lbu	a3,0(a6)
  100104:	fef592e3          	bne	a1,a5,1000e8 <bootloader_main+0x94>
  100108:	00100593          	li	a1,1
    PSC_SD_IF_CTRL = SD_CTRL_INIT_TRIG;
  10010c:	00b52423          	sw	a1,8(a0)
  100110:	f9c00593          	li	a1,-100
    while (n--) {
  100114:	00158593          	addi	a1,a1,1
        __asm__ __volatile__("nop");
  100118:	00000013          	nop
    while (n--) {
  10011c:	fe059ce3          	bnez	a1,100114 <bootloader_main+0xc0>
    while (PSC_SD_IF_CTRL & SD_ST_BUSY) {
  100120:	00852583          	lw	a1,8(a0)
  100124:	0025f593          	andi	a1,a1,2
  100128:	02058a63          	beqz	a1,10015c <bootloader_main+0x108>
  10012c:	0000c5b7          	lui	a1,0xc
  100130:	35058593          	addi	a1,a1,848 # c350 <_start-0xf3cb0>
  100134:	f9c00613          	li	a2,-100
    while (n--) {
  100138:	00160613          	addi	a2,a2,1
        __asm__ __volatile__("nop");
  10013c:	00000013          	nop
    while (n--) {
  100140:	fe061ce3          	bnez	a2,100138 <bootloader_main+0xe4>
        if (--timeout == 0u) {
  100144:	fff58593          	addi	a1,a1,-1
  100148:	0c058e63          	beqz	a1,100224 <bootloader_main+0x1d0>
    __asm__ __volatile__("nop");
  10014c:	00000013          	nop
    while (PSC_SD_IF_CTRL & SD_ST_BUSY) {
  100150:	00852603          	lw	a2,8(a0)
  100154:	00267613          	andi	a2,a2,2
  100158:	fc061ee3          	bnez	a2,100134 <bootloader_main+0xe0>
  10015c:	f9c00513          	li	a0,-100
    while (n--) {
  100160:	00150513          	addi	a0,a0,1
        __asm__ __volatile__("nop");
  100164:	00000013          	nop
    while (n--) {
  100168:	fe051ce3          	bnez	a0,100160 <bootloader_main+0x10c>
    if (sd_init_if_needed()) {
        bl_print("SD init failed\n");
        for (;;) {}
    }

    if (boot_fat32_mount(boot_sd_read_sector)) {
  10016c:	00100537          	lui	a0,0x100
  100170:	46c50513          	addi	a0,a0,1132 # 10046c <boot_sd_read_sector>
  100174:	00002097          	auipc	ra,0x2
  100178:	dd4080e7          	jalr	-556(ra) # 101f48 <boot_fat32_mount>
  10017c:	04050463          	beqz	a0,1001c4 <bootloader_main+0x170>
  100180:	00000513          	li	a0,0
  100184:	04600613          	li	a2,70
  100188:	001035b7          	lui	a1,0x103
  10018c:	17458593          	addi	a1,a1,372 # 103174 <boot_fat32_load_mem_file+0x42c>
  100190:	100006b7          	lui	a3,0x10000
  100194:	01300713          	li	a4,19
  100198:	0080006f          	j	1001a0 <bootloader_main+0x14c>
        __asm__ __volatile__("nop");
  10019c:	00000013          	nop
    return *(volatile uint32_t*)addr;
  1001a0:	00842783          	lw	a5,8(s0)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  1001a4:	0017f793          	andi	a5,a5,1
  1001a8:	fe079ae3          	bnez	a5,10019c <bootloader_main+0x148>
        putchar(*s++);
  1001ac:	00150513          	addi	a0,a0,1
  1001b0:	00a587b3          	add	a5,a1,a0
    *(volatile uint32_t*)addr = v;
  1001b4:	00c6a023          	sw	a2,0(a3) # 10000000 <_stack_top+0xfef4040>
    while (*s) {
  1001b8:	0007c603          	lbu	a2,0(a5)
  1001bc:	fee512e3          	bne	a0,a4,1001a0 <bootloader_main+0x14c>
        bl_print("FAT32 mount failed\n");
        for (;;) {}
  1001c0:	0000006f          	j	1001c0 <bootloader_main+0x16c>
    }

    if (boot_fat32_load_mem_file("KERNEL.MEM", KERNEL_LOAD_ADDR, &kernel_words)) {
  1001c4:	00103537          	lui	a0,0x103
  1001c8:	18850513          	addi	a0,a0,392 # 103188 <boot_fat32_load_mem_file+0x440>
  1001cc:	002005b7          	lui	a1,0x200
  1001d0:	00c10613          	addi	a2,sp,12
  1001d4:	00003097          	auipc	ra,0x3
  1001d8:	b74080e7          	jalr	-1164(ra) # 102d48 <boot_fat32_load_mem_file>
  1001dc:	0c050663          	beqz	a0,1002a8 <bootloader_main+0x254>
  1001e0:	00000513          	li	a0,0
  1001e4:	04b00613          	li	a2,75
  1001e8:	001035b7          	lui	a1,0x103
  1001ec:	19358593          	addi	a1,a1,403 # 103193 <boot_fat32_load_mem_file+0x44b>
  1001f0:	100006b7          	lui	a3,0x10000
  1001f4:	01700713          	li	a4,23
  1001f8:	0080006f          	j	100200 <bootloader_main+0x1ac>
        __asm__ __volatile__("nop");
  1001fc:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100200:	00842783          	lw	a5,8(s0)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100204:	0017f793          	andi	a5,a5,1
  100208:	fe079ae3          	bnez	a5,1001fc <bootloader_main+0x1a8>
        putchar(*s++);
  10020c:	00150513          	addi	a0,a0,1
  100210:	00a587b3          	add	a5,a1,a0
    *(volatile uint32_t*)addr = v;
  100214:	00c6a023          	sw	a2,0(a3) # 10000000 <_stack_top+0xfef4040>
    while (*s) {
  100218:	0007c603          	lbu	a2,0(a5)
  10021c:	fee512e3          	bne	a0,a4,100200 <bootloader_main+0x1ac>
        bl_print("KERNEL.MEM load failed\n");
        for (;;) {}
  100220:	0000006f          	j	100220 <bootloader_main+0x1cc>
  100224:	00000513          	li	a0,0
  100228:	05300613          	li	a2,83
  10022c:	001035b7          	lui	a1,0x103
  100230:	22658593          	addi	a1,a1,550 # 103226 <boot_fat32_load_mem_file+0x4de>
  100234:	100006b7          	lui	a3,0x10000
  100238:	01000713          	li	a4,16
  10023c:	0080006f          	j	100244 <bootloader_main+0x1f0>
        __asm__ __volatile__("nop");
  100240:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100244:	00842783          	lw	a5,8(s0)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100248:	0017f793          	andi	a5,a5,1
  10024c:	fe079ae3          	bnez	a5,100240 <bootloader_main+0x1ec>
        putchar(*s++);
  100250:	00150513          	addi	a0,a0,1
  100254:	00a587b3          	add	a5,a1,a0
    *(volatile uint32_t*)addr = v;
  100258:	00c6a023          	sw	a2,0(a3) # 10000000 <_stack_top+0xfef4040>
    while (*s) {
  10025c:	0007c603          	lbu	a2,0(a5)
  100260:	fee512e3          	bne	a0,a4,100244 <bootloader_main+0x1f0>
  100264:	00000513          	li	a0,0
  100268:	05300613          	li	a2,83
  10026c:	001035b7          	lui	a1,0x103
  100270:	16458593          	addi	a1,a1,356 # 103164 <boot_fat32_load_mem_file+0x41c>
  100274:	100006b7          	lui	a3,0x10000
  100278:	00f00713          	li	a4,15
  10027c:	0080006f          	j	100284 <bootloader_main+0x230>
        __asm__ __volatile__("nop");
  100280:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100284:	00842783          	lw	a5,8(s0)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100288:	0017f793          	andi	a5,a5,1
  10028c:	fe079ae3          	bnez	a5,100280 <bootloader_main+0x22c>
        putchar(*s++);
  100290:	00150513          	addi	a0,a0,1
  100294:	00a587b3          	add	a5,a1,a0
    *(volatile uint32_t*)addr = v;
  100298:	00c6a023          	sw	a2,0(a3) # 10000000 <_stack_top+0xfef4040>
    while (*s) {
  10029c:	0007c603          	lbu	a2,0(a5)
  1002a0:	fee512e3          	bne	a0,a4,100284 <bootloader_main+0x230>
        for (;;) {}
  1002a4:	0000006f          	j	1002a4 <bootloader_main+0x250>
    }

    if (boot_fat32_load_mem_file("USER.MEM", USER_LOAD_ADDR, &user_words)) {
  1002a8:	00103537          	lui	a0,0x103
  1002ac:	1ab50513          	addi	a0,a0,427 # 1031ab <boot_fat32_load_mem_file+0x463>
  1002b0:	004005b7          	lui	a1,0x400
  1002b4:	00810613          	addi	a2,sp,8
  1002b8:	004004b7          	lui	s1,0x400
  1002bc:	00003097          	auipc	ra,0x3
  1002c0:	a8c080e7          	jalr	-1396(ra) # 102d48 <boot_fat32_load_mem_file>
  1002c4:	04050463          	beqz	a0,10030c <bootloader_main+0x2b8>
  1002c8:	00000513          	li	a0,0
  1002cc:	05500613          	li	a2,85
  1002d0:	001035b7          	lui	a1,0x103
  1002d4:	1b458593          	addi	a1,a1,436 # 1031b4 <boot_fat32_load_mem_file+0x46c>
  1002d8:	100006b7          	lui	a3,0x10000
  1002dc:	01500713          	li	a4,21
  1002e0:	0080006f          	j	1002e8 <bootloader_main+0x294>
        __asm__ __volatile__("nop");
  1002e4:	00000013          	nop
    return *(volatile uint32_t*)addr;
  1002e8:	00842783          	lw	a5,8(s0)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  1002ec:	0017f793          	andi	a5,a5,1
  1002f0:	fe079ae3          	bnez	a5,1002e4 <bootloader_main+0x290>
        putchar(*s++);
  1002f4:	00150513          	addi	a0,a0,1
  1002f8:	00a587b3          	add	a5,a1,a0
    *(volatile uint32_t*)addr = v;
  1002fc:	00c6a023          	sw	a2,0(a3) # 10000000 <_stack_top+0xfef4040>
    while (*s) {
  100300:	0007c603          	lbu	a2,0(a5)
  100304:	fee512e3          	bne	a0,a4,1002e8 <bootloader_main+0x294>
        bl_print("USER.MEM load failed\n");
        for (;;) {}
  100308:	0000006f          	j	100308 <bootloader_main+0x2b4>
    }

    bl_print("kernel words=");
  10030c:	00103537          	lui	a0,0x103
  100310:	1ca50513          	addi	a0,a0,458 # 1031ca <boot_fat32_load_mem_file+0x482>
  100314:	00000097          	auipc	ra,0x0
  100318:	124080e7          	jalr	292(ra) # 100438 <bl_print>
    bl_print_hex(kernel_words);
  10031c:	00c12503          	lw	a0,12(sp)
  100320:	00001097          	auipc	ra,0x1
  100324:	924080e7          	jalr	-1756(ra) # 100c44 <bl_print_hex>
    bl_print("\n");
  100328:	00103437          	lui	s0,0x103
  10032c:	38a40413          	addi	s0,s0,906 # 10338a <print_hex8.HEX+0x90>
  100330:	00040513          	mv	a0,s0
  100334:	00000097          	auipc	ra,0x0
  100338:	104080e7          	jalr	260(ra) # 100438 <bl_print>

    bl_print("user words=");
  10033c:	00103537          	lui	a0,0x103
  100340:	1d850513          	addi	a0,a0,472 # 1031d8 <boot_fat32_load_mem_file+0x490>
  100344:	00000097          	auipc	ra,0x0
  100348:	0f4080e7          	jalr	244(ra) # 100438 <bl_print>
    bl_print_hex(user_words);
  10034c:	00812503          	lw	a0,8(sp)
  100350:	00001097          	auipc	ra,0x1
  100354:	8f4080e7          	jalr	-1804(ra) # 100c44 <bl_print_hex>
    bl_print("\n");
  100358:	00040513          	mv	a0,s0
  10035c:	00000097          	auipc	ra,0x0
  100360:	0dc080e7          	jalr	220(ra) # 100438 <bl_print>

    bl_print("JUMP TO ");
  100364:	00103537          	lui	a0,0x103
  100368:	1e450513          	addi	a0,a0,484 # 1031e4 <boot_fat32_load_mem_file+0x49c>
  10036c:	00000097          	auipc	ra,0x0
  100370:	0cc080e7          	jalr	204(ra) # 100438 <bl_print>
    bl_print_hex(KERNEL_LOAD_ADDR);
  100374:	00200537          	lui	a0,0x200
  100378:	00200937          	lui	s2,0x200
  10037c:	00001097          	auipc	ra,0x1
  100380:	8c8080e7          	jalr	-1848(ra) # 100c44 <bl_print_hex>
    bl_print("\n");
  100384:	00040513          	mv	a0,s0
  100388:	00000097          	auipc	ra,0x0
  10038c:	0b0080e7          	jalr	176(ra) # 100438 <bl_print>

    bl_print("kernel[0]=");
  100390:	00103537          	lui	a0,0x103
  100394:	1ed50513          	addi	a0,a0,493 # 1031ed <boot_fat32_load_mem_file+0x4a5>
  100398:	00000097          	auipc	ra,0x0
  10039c:	0a0080e7          	jalr	160(ra) # 100438 <bl_print>
    bl_print_hex(*(volatile uint32_t *)0x00200000);
  1003a0:	00092503          	lw	a0,0(s2) # 200000 <_stack_top+0xf4040>
  1003a4:	00001097          	auipc	ra,0x1
  1003a8:	8a0080e7          	jalr	-1888(ra) # 100c44 <bl_print_hex>
    bl_print("\n");
  1003ac:	00040513          	mv	a0,s0
  1003b0:	00000097          	auipc	ra,0x0
  1003b4:	088080e7          	jalr	136(ra) # 100438 <bl_print>

    bl_print("kernel[1]=");
  1003b8:	00103537          	lui	a0,0x103
  1003bc:	1f850513          	addi	a0,a0,504 # 1031f8 <boot_fat32_load_mem_file+0x4b0>
  1003c0:	00000097          	auipc	ra,0x0
  1003c4:	078080e7          	jalr	120(ra) # 100438 <bl_print>
    bl_print_hex(*(volatile uint32_t *)0x00200004);
  1003c8:	00492503          	lw	a0,4(s2)
  1003cc:	00001097          	auipc	ra,0x1
  1003d0:	878080e7          	jalr	-1928(ra) # 100c44 <bl_print_hex>
    bl_print("\n");
  1003d4:	00040513          	mv	a0,s0
  1003d8:	00000097          	auipc	ra,0x0
  1003dc:	060080e7          	jalr	96(ra) # 100438 <bl_print>

    bl_print("kernel[2]=");
  1003e0:	00103537          	lui	a0,0x103
  1003e4:	20350513          	addi	a0,a0,515 # 103203 <boot_fat32_load_mem_file+0x4bb>
  1003e8:	00000097          	auipc	ra,0x0
  1003ec:	050080e7          	jalr	80(ra) # 100438 <bl_print>
    bl_print_hex(*(volatile uint32_t *)0x00200008);
  1003f0:	00892503          	lw	a0,8(s2)
  1003f4:	00001097          	auipc	ra,0x1
  1003f8:	850080e7          	jalr	-1968(ra) # 100c44 <bl_print_hex>
    bl_print("\n");
  1003fc:	00040513          	mv	a0,s0
  100400:	00000097          	auipc	ra,0x0
  100404:	038080e7          	jalr	56(ra) # 100438 <bl_print>

    bl_print("user[0]=");
  100408:	00103537          	lui	a0,0x103
  10040c:	20e50513          	addi	a0,a0,526 # 10320e <boot_fat32_load_mem_file+0x4c6>
  100410:	00000097          	auipc	ra,0x0
  100414:	028080e7          	jalr	40(ra) # 100438 <bl_print>
    bl_print_hex(*(volatile uint32_t *)0x00400000);
  100418:	0004a503          	lw	a0,0(s1) # 400000 <_stack_top+0x2f4040>
  10041c:	00001097          	auipc	ra,0x1
  100420:	828080e7          	jalr	-2008(ra) # 100c44 <bl_print_hex>
    bl_print("\n");
  100424:	00040513          	mv	a0,s0
  100428:	00000097          	auipc	ra,0x0
  10042c:	010080e7          	jalr	16(ra) # 100438 <bl_print>
    entry();
  100430:	000900e7          	jalr	s2

    jump_to_kernel(KERNEL_LOAD_ADDR);

    for (;;) {}
  100434:	0000006f          	j	100434 <bootloader_main+0x3e0>

00100438 <bl_print>:
    while (*s) {
  100438:	00054583          	lbu	a1,0(a0)
  10043c:	02058663          	beqz	a1,100468 <bl_print+0x30>
  100440:	10000637          	lui	a2,0x10000
  100444:	0080006f          	j	10044c <bl_print+0x14>
        __asm__ __volatile__("nop");
  100448:	00000013          	nop
    return *(volatile uint32_t*)addr;
  10044c:	00862683          	lw	a3,8(a2) # 10000008 <_stack_top+0xfef4048>
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100450:	0016f693          	andi	a3,a3,1
  100454:	fe069ae3          	bnez	a3,100448 <bl_print+0x10>
        putchar(*s++);
  100458:	00150513          	addi	a0,a0,1
    *(volatile uint32_t*)addr = v;
  10045c:	00b62023          	sw	a1,0(a2)
    while (*s) {
  100460:	00054583          	lbu	a1,0(a0)
  100464:	fe0594e3          	bnez	a1,10044c <bl_print+0x14>
}
  100468:	00008067          	ret

0010046c <boot_sd_read_sector>:
{
  10046c:	fd010113          	addi	sp,sp,-48
  100470:	02812623          	sw	s0,44(sp)
  100474:	02912423          	sw	s1,40(sp)
  100478:	03212223          	sw	s2,36(sp)
  10047c:	03312023          	sw	s3,32(sp)
  100480:	01412e23          	sw	s4,28(sp)
  100484:	01512c23          	sw	s5,24(sp)
  100488:	01612a23          	sw	s6,20(sp)
  10048c:	01712823          	sw	s7,16(sp)
  100490:	01812623          	sw	s8,12(sp)
  100494:	01912423          	sw	s9,8(sp)
  100498:	01a12223          	sw	s10,4(sp)
  10049c:	01b12023          	sw	s11,0(sp)
  1004a0:	00000693          	li	a3,0
  1004a4:	10006737          	lui	a4,0x10006
  1004a8:	10000637          	lui	a2,0x10000
    for (uint32_t retry = 0; retry < SD_READ_RETRY_MAX; retry++) {
  1004ac:	20058793          	addi	a5,a1,512
  1004b0:	00400813          	li	a6,4
  1004b4:	00200893          	li	a7,2
  1004b8:	ffff42b7          	lui	t0,0xffff4
  1004bc:	20000313          	li	t1,512
  1004c0:	00001a37          	lui	s4,0x1
  1004c4:	001033b7          	lui	t2,0x103
  1004c8:	26438393          	addi	t2,t2,612 # 103264 <boot_fat32_load_mem_file+0x51c>
  1004cc:	00b00e13          	li	t3,11
  1004d0:	00a00e93          	li	t4,10
  1004d4:	02000f13          	li	t5,32
  1004d8:	07300f93          	li	t6,115
  1004dc:	07700413          	li	s0,119
  1004e0:	03d00493          	li	s1,61
  1004e4:	06800913          	li	s2,104
  1004e8:	cb028993          	addi	s3,t0,-848 # ffff3cb0 <_stack_top+0xffee7cf0>
  1004ec:	021a0a13          	addi	s4,s4,33 # 1021 <_start-0xfefdf>
  1004f0:	00300a93          	li	s5,3
        PSC_SD_IF_CTRL = SD_CTRL_FIFO_FLUSH;
  1004f4:	01072423          	sw	a6,8(a4) # 10006008 <_stack_top+0xfefa048>
        __asm__ __volatile__("nop");
  1004f8:	00000013          	nop
  1004fc:	00000013          	nop
  100500:	00000013          	nop
  100504:	00000013          	nop
  100508:	00000013          	nop
  10050c:	00000013          	nop
  100510:	00000013          	nop
  100514:	00000013          	nop
  100518:	00000013          	nop
  10051c:	00000013          	nop
  100520:	00000013          	nop
  100524:	00000013          	nop
  100528:	00000013          	nop
  10052c:	00000013          	nop
  100530:	00000013          	nop
  100534:	00000013          	nop
  100538:	00000013          	nop
  10053c:	00000013          	nop
  100540:	00000013          	nop
  100544:	00000013          	nop
  100548:	00000013          	nop
  10054c:	00000013          	nop
  100550:	00000013          	nop
  100554:	00000013          	nop
  100558:	00000013          	nop
  10055c:	00000013          	nop
  100560:	00000013          	nop
  100564:	00000013          	nop
  100568:	00000013          	nop
  10056c:	00000013          	nop
  100570:	00000013          	nop
  100574:	00000013          	nop
  100578:	00000013          	nop
  10057c:	00000013          	nop
  100580:	00000013          	nop
  100584:	00000013          	nop
  100588:	00000013          	nop
  10058c:	00000013          	nop
  100590:	00000013          	nop
  100594:	00000013          	nop
  100598:	00000013          	nop
  10059c:	00000013          	nop
  1005a0:	00000013          	nop
  1005a4:	00000013          	nop
  1005a8:	00000013          	nop
  1005ac:	00000013          	nop
  1005b0:	00000013          	nop
  1005b4:	00000013          	nop
  1005b8:	00000013          	nop
  1005bc:	00000013          	nop
        PSC_SD_SECTOR = lba;
  1005c0:	00a72223          	sw	a0,4(a4)
        PSC_SD_IF_CTRL = SD_CTRL_READ_TRIG;
  1005c4:	01172423          	sw	a7,8(a4)
        __asm__ __volatile__("nop");
  1005c8:	00000013          	nop
  1005cc:	00000013          	nop
  1005d0:	00000013          	nop
  1005d4:	00000013          	nop
  1005d8:	00000013          	nop
  1005dc:	00000013          	nop
  1005e0:	00000013          	nop
  1005e4:	00000013          	nop
  1005e8:	00000013          	nop
  1005ec:	00000013          	nop
  1005f0:	00000013          	nop
  1005f4:	00000013          	nop
  1005f8:	00000013          	nop
  1005fc:	00000013          	nop
  100600:	00000013          	nop
  100604:	00000013          	nop
  100608:	00000013          	nop
  10060c:	00000013          	nop
  100610:	00000013          	nop
  100614:	00000013          	nop
  100618:	00000013          	nop
  10061c:	00000013          	nop
  100620:	00000013          	nop
  100624:	00000013          	nop
  100628:	00000013          	nop
  10062c:	00000013          	nop
  100630:	00000013          	nop
  100634:	00000013          	nop
  100638:	00000013          	nop
  10063c:	00000013          	nop
  100640:	00000013          	nop
  100644:	00000013          	nop
  100648:	00000013          	nop
  10064c:	00000013          	nop
  100650:	00000013          	nop
  100654:	00000013          	nop
  100658:	00000013          	nop
  10065c:	00000013          	nop
  100660:	00000013          	nop
  100664:	00000013          	nop
  100668:	00000013          	nop
  10066c:	00000013          	nop
  100670:	00000013          	nop
  100674:	00000013          	nop
  100678:	00000013          	nop
  10067c:	00000013          	nop
  100680:	00000013          	nop
  100684:	00000013          	nop
  100688:	00000013          	nop
  10068c:	00000013          	nop
        while ((PSC_SD_IF_CTRL & SD_ST_RW_READY) == 0u) {
  100690:	00872b03          	lw	s6,8(a4)
  100694:	004b7b13          	andi	s6,s6,4
  100698:	020b1063          	bnez	s6,1006b8 <boot_sd_read_sector+0x24c>
  10069c:	00098b13          	mv	s6,s3
            if (--timeout == 0u) {
  1006a0:	001b0b13          	addi	s6,s6,1
  1006a4:	480b0e63          	beqz	s6,100b40 <boot_sd_read_sector+0x6d4>
    __asm__ __volatile__("nop");
  1006a8:	00000013          	nop
        while ((PSC_SD_IF_CTRL & SD_ST_RW_READY) == 0u) {
  1006ac:	00872b83          	lw	s7,8(a4)
  1006b0:	004bfb93          	andi	s7,s7,4
  1006b4:	fe0b86e3          	beqz	s7,1006a0 <boot_sd_read_sector+0x234>
  1006b8:	00000b13          	li	s6,0
        __asm__ __volatile__("nop");
  1006bc:	00000013          	nop
  1006c0:	00000013          	nop
  1006c4:	00000013          	nop
  1006c8:	00000013          	nop
  1006cc:	00000013          	nop
  1006d0:	00000013          	nop
  1006d4:	00000013          	nop
  1006d8:	00000013          	nop
  1006dc:	00000013          	nop
  1006e0:	00000013          	nop
  1006e4:	00000013          	nop
  1006e8:	00000013          	nop
  1006ec:	00000013          	nop
  1006f0:	00000013          	nop
  1006f4:	00000013          	nop
  1006f8:	00000013          	nop
  1006fc:	00000013          	nop
  100700:	00000013          	nop
  100704:	00000013          	nop
  100708:	00000013          	nop
  10070c:	0180006f          	j	100724 <boot_sd_read_sector+0x2b8>
            dst[i] = (uint8_t)(PSC_IF_DATA & 0xFFu);
  100710:	00072b83          	lw	s7,0(a4)
  100714:	01658c33          	add	s8,a1,s6
        for (int i = 0; i < 512; i++) {
  100718:	001b0b13          	addi	s6,s6,1
            dst[i] = (uint8_t)(PSC_IF_DATA & 0xFFu);
  10071c:	017c0023          	sb	s7,0(s8)
        for (int i = 0; i < 512; i++) {
  100720:	026b0863          	beq	s6,t1,100750 <boot_sd_read_sector+0x2e4>
            while (PSC_SD_IF_CTRL & SD_ST_FIFO_EMPTY) {
  100724:	00872b83          	lw	s7,8(a4)
  100728:	008bfb93          	andi	s7,s7,8
  10072c:	fe0b82e3          	beqz	s7,100710 <boot_sd_read_sector+0x2a4>
  100730:	cb028b93          	addi	s7,t0,-848
                if (--timeout == 0u) {
  100734:	001b8b93          	addi	s7,s7,1
  100738:	360b8263          	beqz	s7,100a9c <boot_sd_read_sector+0x630>
    __asm__ __volatile__("nop");
  10073c:	00000013          	nop
            while (PSC_SD_IF_CTRL & SD_ST_FIFO_EMPTY) {
  100740:	00872c03          	lw	s8,8(a4)
  100744:	008c7c13          	andi	s8,s8,8
  100748:	fe0c16e3          	bnez	s8,100734 <boot_sd_read_sector+0x2c8>
  10074c:	fc5ff06f          	j	100710 <boot_sd_read_sector+0x2a4>
  100750:	00000b93          	li	s7,0
  100754:	00058b13          	mv	s6,a1
        crc ^= (uint16_t)((uint16_t)buf[i] << 8);
  100758:	000b4c03          	lbu	s8,0(s6)
    for (int i = 0; i < 512; i++) {
  10075c:	001b0b13          	addi	s6,s6,1
        crc ^= (uint16_t)((uint16_t)buf[i] << 8);
  100760:	008c1c13          	slli	s8,s8,0x8
  100764:	017c4bb3          	xor	s7,s8,s7
  100768:	010b9c13          	slli	s8,s7,0x10
            if (crc & 0x8000u)
  10076c:	011b9c93          	slli	s9,s7,0x11
  100770:	001b9d13          	slli	s10,s7,0x1
  100774:	012b9d93          	slli	s11,s7,0x12
  100778:	013b9b93          	slli	s7,s7,0x13
  10077c:	41fc5c13          	srai	s8,s8,0x1f
  100780:	41fcdc93          	srai	s9,s9,0x1f
  100784:	41fddd93          	srai	s11,s11,0x1f
  100788:	41fbdb93          	srai	s7,s7,0x1f
  10078c:	014c7c33          	and	s8,s8,s4
  100790:	014cfcb3          	and	s9,s9,s4
  100794:	014dfdb3          	and	s11,s11,s4
  100798:	014bfbb3          	and	s7,s7,s4
  10079c:	018d4c33          	xor	s8,s10,s8
  1007a0:	001c1d13          	slli	s10,s8,0x1
  1007a4:	013c1c13          	slli	s8,s8,0x13
  1007a8:	019d4cb3          	xor	s9,s10,s9
  1007ac:	41fc5c13          	srai	s8,s8,0x1f
  1007b0:	001c9d13          	slli	s10,s9,0x1
  1007b4:	013c9c93          	slli	s9,s9,0x13
  1007b8:	014c7c33          	and	s8,s8,s4
  1007bc:	01bd4d33          	xor	s10,s10,s11
  1007c0:	41fcdc93          	srai	s9,s9,0x1f
  1007c4:	003c1c13          	slli	s8,s8,0x3
  1007c8:	001d1d93          	slli	s11,s10,0x1
  1007cc:	013d1d13          	slli	s10,s10,0x13
  1007d0:	014cfcb3          	and	s9,s9,s4
  1007d4:	017dcbb3          	xor	s7,s11,s7
  1007d8:	41fd5d13          	srai	s10,s10,0x1f
  1007dc:	002c9c93          	slli	s9,s9,0x2
  1007e0:	013b9d93          	slli	s11,s7,0x13
  1007e4:	014d7d33          	and	s10,s10,s4
  1007e8:	004b9b93          	slli	s7,s7,0x4
  1007ec:	019c4c33          	xor	s8,s8,s9
  1007f0:	018bcbb3          	xor	s7,s7,s8
  1007f4:	001d1d13          	slli	s10,s10,0x1
  1007f8:	41fddc13          	srai	s8,s11,0x1f
  1007fc:	01abcbb3          	xor	s7,s7,s10
  100800:	014c7c33          	and	s8,s8,s4
  100804:	018bcbb3          	xor	s7,s7,s8
    for (int i = 0; i < 512; i++) {
  100808:	f4fb18e3          	bne	s6,a5,100758 <boot_sd_read_sector+0x2ec>
    uint32_t ctrl = PSC_SD_IF_CTRL;
  10080c:	00872b03          	lw	s6,8(a4)
            if (crc_sw == crc_hw)
  100810:	010b9b93          	slli	s7,s7,0x10
    uint8_t crc2_hw = (uint8_t)((ctrl >> 16) & 0xFFu);
  100814:	010b5b13          	srli	s6,s6,0x10
            if (crc_sw == crc_hw)
  100818:	010bdb93          	srli	s7,s7,0x10
  10081c:	436b8063          	beq	s7,s6,100c3c <boot_sd_read_sector+0x7d0>
  100820:	00000c13          	li	s8,0
  100824:	04300c93          	li	s9,67
  100828:	0080006f          	j	100830 <boot_sd_read_sector+0x3c4>
        __asm__ __volatile__("nop");
  10082c:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100830:	00862d03          	lw	s10,8(a2) # 10000008 <_stack_top+0xfef4048>
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100834:	001d7d13          	andi	s10,s10,1
  100838:	fe0d1ae3          	bnez	s10,10082c <boot_sd_read_sector+0x3c0>
        putchar(*s++);
  10083c:	001c0c13          	addi	s8,s8,1
  100840:	01838d33          	add	s10,t2,s8
    *(volatile uint32_t*)addr = v;
  100844:	01962023          	sw	s9,0(a2)
    while (*s) {
  100848:	000d4c83          	lbu	s9,0(s10)
  10084c:	ffcc12e3          	bne	s8,t3,100830 <boot_sd_read_sector+0x3c4>
  100850:	00700c93          	li	s9,7
  100854:	000c8c13          	mv	s8,s9
        uint8_t n = (uint8_t)((v >> (i * 4)) & 0xFu);
  100858:	002c9c93          	slli	s9,s9,0x2
  10085c:	01955cb3          	srl	s9,a0,s9
  100860:	00fcfc93          	andi	s9,s9,15
        putchar(n < 10 ? (char)('0' + n) : (char)('A' + n - 10));
  100864:	01dce663          	bltu	s9,t4,100870 <boot_sd_read_sector+0x404>
  100868:	037c8c93          	addi	s9,s9,55
  10086c:	0100006f          	j	10087c <boot_sd_read_sector+0x410>
  100870:	030c8c93          	addi	s9,s9,48
  100874:	0080006f          	j	10087c <boot_sd_read_sector+0x410>
        __asm__ __volatile__("nop");
  100878:	00000013          	nop
    return *(volatile uint32_t*)addr;
  10087c:	00862d03          	lw	s10,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100880:	001d7d13          	andi	s10,s10,1
  100884:	fe0d1ae3          	bnez	s10,100878 <boot_sd_read_sector+0x40c>
    *(volatile uint32_t*)addr = v;
  100888:	01962023          	sw	s9,0(a2)
    for (int i = 7; i >= 0; i--) {
  10088c:	fffc0c93          	addi	s9,s8,-1
  100890:	fc0c12e3          	bnez	s8,100854 <boot_sd_read_sector+0x3e8>
  100894:	0080006f          	j	10089c <boot_sd_read_sector+0x430>
        __asm__ __volatile__("nop");
  100898:	00000013          	nop
    return *(volatile uint32_t*)addr;
  10089c:	00862c03          	lw	s8,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  1008a0:	001c7c13          	andi	s8,s8,1
  1008a4:	fe0c1ae3          	bnez	s8,100898 <boot_sd_read_sector+0x42c>
    *(volatile uint32_t*)addr = v;
  1008a8:	01e62023          	sw	t5,0(a2)
    return *(volatile uint32_t*)addr;
  1008ac:	00862c03          	lw	s8,8(a2)
  1008b0:	001c7c13          	andi	s8,s8,1
  1008b4:	000c0663          	beqz	s8,1008c0 <boot_sd_read_sector+0x454>
        __asm__ __volatile__("nop");
  1008b8:	00000013          	nop
  1008bc:	ff1ff06f          	j	1008ac <boot_sd_read_sector+0x440>
    *(volatile uint32_t*)addr = v;
  1008c0:	01f62023          	sw	t6,0(a2)
    return *(volatile uint32_t*)addr;
  1008c4:	00862c03          	lw	s8,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  1008c8:	001c7c13          	andi	s8,s8,1
  1008cc:	000c0663          	beqz	s8,1008d8 <boot_sd_read_sector+0x46c>
        __asm__ __volatile__("nop");
  1008d0:	00000013          	nop
  1008d4:	ff1ff06f          	j	1008c4 <boot_sd_read_sector+0x458>
    *(volatile uint32_t*)addr = v;
  1008d8:	00862023          	sw	s0,0(a2)
    return *(volatile uint32_t*)addr;
  1008dc:	00862c03          	lw	s8,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  1008e0:	001c7c13          	andi	s8,s8,1
  1008e4:	000c0663          	beqz	s8,1008f0 <boot_sd_read_sector+0x484>
        __asm__ __volatile__("nop");
  1008e8:	00000013          	nop
  1008ec:	ff1ff06f          	j	1008dc <boot_sd_read_sector+0x470>
    *(volatile uint32_t*)addr = v;
  1008f0:	00962023          	sw	s1,0(a2)
  1008f4:	00700c93          	li	s9,7
  1008f8:	000c8c13          	mv	s8,s9
        uint8_t n = (uint8_t)((v >> (i * 4)) & 0xFu);
  1008fc:	002c9c93          	slli	s9,s9,0x2
  100900:	019bdcb3          	srl	s9,s7,s9
  100904:	00fcfc93          	andi	s9,s9,15
        putchar(n < 10 ? (char)('0' + n) : (char)('A' + n - 10));
  100908:	01dce663          	bltu	s9,t4,100914 <boot_sd_read_sector+0x4a8>
  10090c:	037c8c93          	addi	s9,s9,55
  100910:	0100006f          	j	100920 <boot_sd_read_sector+0x4b4>
  100914:	030c8c93          	addi	s9,s9,48
  100918:	0080006f          	j	100920 <boot_sd_read_sector+0x4b4>
        __asm__ __volatile__("nop");
  10091c:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100920:	00862d03          	lw	s10,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100924:	001d7d13          	andi	s10,s10,1
  100928:	fe0d1ae3          	bnez	s10,10091c <boot_sd_read_sector+0x4b0>
    *(volatile uint32_t*)addr = v;
  10092c:	01962023          	sw	s9,0(a2)
    for (int i = 7; i >= 0; i--) {
  100930:	fffc0c93          	addi	s9,s8,-1
  100934:	fc0c12e3          	bnez	s8,1008f8 <boot_sd_read_sector+0x48c>
  100938:	0080006f          	j	100940 <boot_sd_read_sector+0x4d4>
        __asm__ __volatile__("nop");
  10093c:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100940:	00862b83          	lw	s7,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100944:	001bfb93          	andi	s7,s7,1
  100948:	fe0b9ae3          	bnez	s7,10093c <boot_sd_read_sector+0x4d0>
    *(volatile uint32_t*)addr = v;
  10094c:	01e62023          	sw	t5,0(a2)
    return *(volatile uint32_t*)addr;
  100950:	00862b83          	lw	s7,8(a2)
  100954:	001bfb93          	andi	s7,s7,1
  100958:	000b8663          	beqz	s7,100964 <boot_sd_read_sector+0x4f8>
        __asm__ __volatile__("nop");
  10095c:	00000013          	nop
  100960:	ff1ff06f          	j	100950 <boot_sd_read_sector+0x4e4>
    *(volatile uint32_t*)addr = v;
  100964:	01262023          	sw	s2,0(a2)
    return *(volatile uint32_t*)addr;
  100968:	00862b83          	lw	s7,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  10096c:	001bfb93          	andi	s7,s7,1
  100970:	000b8663          	beqz	s7,10097c <boot_sd_read_sector+0x510>
        __asm__ __volatile__("nop");
  100974:	00000013          	nop
  100978:	ff1ff06f          	j	100968 <boot_sd_read_sector+0x4fc>
    *(volatile uint32_t*)addr = v;
  10097c:	00862023          	sw	s0,0(a2)
    return *(volatile uint32_t*)addr;
  100980:	00862b83          	lw	s7,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100984:	001bfb93          	andi	s7,s7,1
  100988:	000b8663          	beqz	s7,100994 <boot_sd_read_sector+0x528>
        __asm__ __volatile__("nop");
  10098c:	00000013          	nop
  100990:	ff1ff06f          	j	100980 <boot_sd_read_sector+0x514>
    *(volatile uint32_t*)addr = v;
  100994:	00962023          	sw	s1,0(a2)
  100998:	00700c13          	li	s8,7
  10099c:	000c0b93          	mv	s7,s8
        uint8_t n = (uint8_t)((v >> (i * 4)) & 0xFu);
  1009a0:	002c1c13          	slli	s8,s8,0x2
  1009a4:	018b5c33          	srl	s8,s6,s8
  1009a8:	00fc7c13          	andi	s8,s8,15
        putchar(n < 10 ? (char)('0' + n) : (char)('A' + n - 10));
  1009ac:	01dc6663          	bltu	s8,t4,1009b8 <boot_sd_read_sector+0x54c>
  1009b0:	037c0c13          	addi	s8,s8,55
  1009b4:	0100006f          	j	1009c4 <boot_sd_read_sector+0x558>
  1009b8:	030c0c13          	addi	s8,s8,48
  1009bc:	0080006f          	j	1009c4 <boot_sd_read_sector+0x558>
        __asm__ __volatile__("nop");
  1009c0:	00000013          	nop
    return *(volatile uint32_t*)addr;
  1009c4:	00862c83          	lw	s9,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  1009c8:	001cfc93          	andi	s9,s9,1
  1009cc:	fe0c9ae3          	bnez	s9,1009c0 <boot_sd_read_sector+0x554>
    *(volatile uint32_t*)addr = v;
  1009d0:	01862023          	sw	s8,0(a2)
    for (int i = 7; i >= 0; i--) {
  1009d4:	fffb8c13          	addi	s8,s7,-1
  1009d8:	fc0b92e3          	bnez	s7,10099c <boot_sd_read_sector+0x530>
  1009dc:	0080006f          	j	1009e4 <boot_sd_read_sector+0x578>
        __asm__ __volatile__("nop");
  1009e0:	00000013          	nop
    return *(volatile uint32_t*)addr;
  1009e4:	00862b03          	lw	s6,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  1009e8:	001b7b13          	andi	s6,s6,1
  1009ec:	fe0b1ae3          	bnez	s6,1009e0 <boot_sd_read_sector+0x574>
    *(volatile uint32_t*)addr = v;
  1009f0:	01d62023          	sw	t4,0(a2)
  1009f4:	f9c00b13          	li	s6,-100
    while (n--) {
  1009f8:	001b0b13          	addi	s6,s6,1
        __asm__ __volatile__("nop");
  1009fc:	00000013          	nop
    while (n--) {
  100a00:	fe0b1ce3          	bnez	s6,1009f8 <boot_sd_read_sector+0x58c>
    for (uint32_t retry = 0; retry < SD_READ_RETRY_MAX; retry++) {
  100a04:	00168693          	addi	a3,a3,1
  100a08:	af5696e3          	bne	a3,s5,1004f4 <boot_sd_read_sector+0x88>
  100a0c:	00000593          	li	a1,0
  100a10:	04300713          	li	a4,67
  100a14:	001036b7          	lui	a3,0x103
  100a18:	27068693          	addi	a3,a3,624 # 103270 <boot_fat32_load_mem_file+0x528>
  100a1c:	100007b7          	lui	a5,0x10000
  100a20:	00f00813          	li	a6,15
  100a24:	0080006f          	j	100a2c <boot_sd_read_sector+0x5c0>
        __asm__ __volatile__("nop");
  100a28:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100a2c:	00862883          	lw	a7,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100a30:	0018f893          	andi	a7,a7,1
  100a34:	fe089ae3          	bnez	a7,100a28 <boot_sd_read_sector+0x5bc>
        putchar(*s++);
  100a38:	00158593          	addi	a1,a1,1
  100a3c:	00b688b3          	add	a7,a3,a1
    *(volatile uint32_t*)addr = v;
  100a40:	00e7a023          	sw	a4,0(a5) # 10000000 <_stack_top+0xfef4040>
    while (*s) {
  100a44:	0008c703          	lbu	a4,0(a7)
  100a48:	ff0592e3          	bne	a1,a6,100a2c <boot_sd_read_sector+0x5c0>
  100a4c:	00700793          	li	a5,7
  100a50:	00a00593          	li	a1,10
  100a54:	100006b7          	lui	a3,0x10000
  100a58:	00078713          	mv	a4,a5
        uint8_t n = (uint8_t)((v >> (i * 4)) & 0xFu);
  100a5c:	00279793          	slli	a5,a5,0x2
  100a60:	00f557b3          	srl	a5,a0,a5
  100a64:	00f7f793          	andi	a5,a5,15
        putchar(n < 10 ? (char)('0' + n) : (char)('A' + n - 10));
  100a68:	00b7e663          	bltu	a5,a1,100a74 <boot_sd_read_sector+0x608>
  100a6c:	03778793          	addi	a5,a5,55
  100a70:	0100006f          	j	100a80 <boot_sd_read_sector+0x614>
  100a74:	03078793          	addi	a5,a5,48
  100a78:	0080006f          	j	100a80 <boot_sd_read_sector+0x614>
        __asm__ __volatile__("nop");
  100a7c:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100a80:	00862803          	lw	a6,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100a84:	00187813          	andi	a6,a6,1
  100a88:	fe081ae3          	bnez	a6,100a7c <boot_sd_read_sector+0x610>
    *(volatile uint32_t*)addr = v;
  100a8c:	00f6a023          	sw	a5,0(a3) # 10000000 <_stack_top+0xfef4040>
    for (int i = 7; i >= 0; i--) {
  100a90:	fff70793          	addi	a5,a4,-1
  100a94:	fc0712e3          	bnez	a4,100a58 <boot_sd_read_sector+0x5ec>
  100a98:	1940006f          	j	100c2c <boot_sd_read_sector+0x7c0>
  100a9c:	00000593          	li	a1,0
  100aa0:	04600713          	li	a4,70
  100aa4:	001036b7          	lui	a3,0x103
  100aa8:	24c68693          	addi	a3,a3,588 # 10324c <boot_fat32_load_mem_file+0x504>
  100aac:	100007b7          	lui	a5,0x10000
  100ab0:	01700813          	li	a6,23
  100ab4:	0080006f          	j	100abc <boot_sd_read_sector+0x650>
        __asm__ __volatile__("nop");
  100ab8:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100abc:	00862883          	lw	a7,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100ac0:	0018f893          	andi	a7,a7,1
  100ac4:	fe089ae3          	bnez	a7,100ab8 <boot_sd_read_sector+0x64c>
        putchar(*s++);
  100ac8:	00158593          	addi	a1,a1,1
  100acc:	00b688b3          	add	a7,a3,a1
    *(volatile uint32_t*)addr = v;
  100ad0:	00e7a023          	sw	a4,0(a5) # 10000000 <_stack_top+0xfef4040>
    while (*s) {
  100ad4:	0008c703          	lbu	a4,0(a7)
  100ad8:	ff0592e3          	bne	a1,a6,100abc <boot_sd_read_sector+0x650>
  100adc:	00700793          	li	a5,7
  100ae0:	00a00593          	li	a1,10
  100ae4:	100006b7          	lui	a3,0x10000
  100ae8:	00078713          	mv	a4,a5
        uint8_t n = (uint8_t)((v >> (i * 4)) & 0xFu);
  100aec:	00279793          	slli	a5,a5,0x2
  100af0:	00f557b3          	srl	a5,a0,a5
  100af4:	00f7f793          	andi	a5,a5,15
        putchar(n < 10 ? (char)('0' + n) : (char)('A' + n - 10));
  100af8:	00b7e663          	bltu	a5,a1,100b04 <boot_sd_read_sector+0x698>
  100afc:	03778793          	addi	a5,a5,55
  100b00:	0100006f          	j	100b10 <boot_sd_read_sector+0x6a4>
  100b04:	03078793          	addi	a5,a5,48
  100b08:	0080006f          	j	100b10 <boot_sd_read_sector+0x6a4>
        __asm__ __volatile__("nop");
  100b0c:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100b10:	00862803          	lw	a6,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100b14:	00187813          	andi	a6,a6,1
  100b18:	fe081ae3          	bnez	a6,100b0c <boot_sd_read_sector+0x6a0>
    *(volatile uint32_t*)addr = v;
  100b1c:	00f6a023          	sw	a5,0(a3) # 10000000 <_stack_top+0xfef4040>
    for (int i = 7; i >= 0; i--) {
  100b20:	fff70793          	addi	a5,a4,-1
  100b24:	fc0712e3          	bnez	a4,100ae8 <boot_sd_read_sector+0x67c>
  100b28:	0080006f          	j	100b30 <boot_sd_read_sector+0x6c4>
        __asm__ __volatile__("nop");
  100b2c:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100b30:	00862503          	lw	a0,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100b34:	00157513          	andi	a0,a0,1
  100b38:	fe051ae3          	bnez	a0,100b2c <boot_sd_read_sector+0x6c0>
  100b3c:	0a40006f          	j	100be0 <boot_sd_read_sector+0x774>
  100b40:	00000593          	li	a1,0
  100b44:	05300713          	li	a4,83
  100b48:	001036b7          	lui	a3,0x103
  100b4c:	23768693          	addi	a3,a3,567 # 103237 <boot_fat32_load_mem_file+0x4ef>
  100b50:	100007b7          	lui	a5,0x10000
  100b54:	01400813          	li	a6,20
  100b58:	0080006f          	j	100b60 <boot_sd_read_sector+0x6f4>
        __asm__ __volatile__("nop");
  100b5c:	00000013          	nop
  100b60:	00862883          	lw	a7,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100b64:	0018f893          	andi	a7,a7,1
  100b68:	fe089ae3          	bnez	a7,100b5c <boot_sd_read_sector+0x6f0>
        putchar(*s++);
  100b6c:	00158593          	addi	a1,a1,1
  100b70:	00b688b3          	add	a7,a3,a1
    *(volatile uint32_t*)addr = v;
  100b74:	00e7a023          	sw	a4,0(a5) # 10000000 <_stack_top+0xfef4040>
    while (*s) {
  100b78:	0008c703          	lbu	a4,0(a7)
  100b7c:	ff0592e3          	bne	a1,a6,100b60 <boot_sd_read_sector+0x6f4>
  100b80:	00700793          	li	a5,7
  100b84:	00a00593          	li	a1,10
  100b88:	100006b7          	lui	a3,0x10000
  100b8c:	00078713          	mv	a4,a5
        uint8_t n = (uint8_t)((v >> (i * 4)) & 0xFu);
  100b90:	00279793          	slli	a5,a5,0x2
  100b94:	00f557b3          	srl	a5,a0,a5
  100b98:	00f7f793          	andi	a5,a5,15
        putchar(n < 10 ? (char)('0' + n) : (char)('A' + n - 10));
  100b9c:	00b7e663          	bltu	a5,a1,100ba8 <boot_sd_read_sector+0x73c>
  100ba0:	03778793          	addi	a5,a5,55
  100ba4:	0100006f          	j	100bb4 <boot_sd_read_sector+0x748>
  100ba8:	03078793          	addi	a5,a5,48
  100bac:	0080006f          	j	100bb4 <boot_sd_read_sector+0x748>
        __asm__ __volatile__("nop");
  100bb0:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100bb4:	00862803          	lw	a6,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100bb8:	00187813          	andi	a6,a6,1
  100bbc:	fe081ae3          	bnez	a6,100bb0 <boot_sd_read_sector+0x744>
    *(volatile uint32_t*)addr = v;
  100bc0:	00f6a023          	sw	a5,0(a3) # 10000000 <_stack_top+0xfef4040>
    for (int i = 7; i >= 0; i--) {
  100bc4:	fff70793          	addi	a5,a4,-1
  100bc8:	fc0712e3          	bnez	a4,100b8c <boot_sd_read_sector+0x720>
  100bcc:	0080006f          	j	100bd4 <boot_sd_read_sector+0x768>
        __asm__ __volatile__("nop");
  100bd0:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100bd4:	00862503          	lw	a0,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100bd8:	00157513          	andi	a0,a0,1
  100bdc:	fe051ae3          	bnez	a0,100bd0 <boot_sd_read_sector+0x764>
  100be0:	10000537          	lui	a0,0x10000
  100be4:	00a00593          	li	a1,10
    *(volatile uint32_t*)addr = v;
  100be8:	00b52023          	sw	a1,0(a0) # 10000000 <_stack_top+0xfef4040>
  100bec:	fff00513          	li	a0,-1
}
  100bf0:	02c12403          	lw	s0,44(sp)
  100bf4:	02812483          	lw	s1,40(sp)
  100bf8:	02412903          	lw	s2,36(sp)
  100bfc:	02012983          	lw	s3,32(sp)
  100c00:	01c12a03          	lw	s4,28(sp)
  100c04:	01812a83          	lw	s5,24(sp)
  100c08:	01412b03          	lw	s6,20(sp)
  100c0c:	01012b83          	lw	s7,16(sp)
  100c10:	00c12c03          	lw	s8,12(sp)
  100c14:	00812c83          	lw	s9,8(sp)
  100c18:	00412d03          	lw	s10,4(sp)
  100c1c:	00012d83          	lw	s11,0(sp)
  100c20:	03010113          	addi	sp,sp,48
  100c24:	00008067          	ret
        __asm__ __volatile__("nop");
  100c28:	00000013          	nop
    return *(volatile uint32_t*)addr;
  100c2c:	00862503          	lw	a0,8(a2)
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100c30:	00157513          	andi	a0,a0,1
  100c34:	fe051ae3          	bnez	a0,100c28 <boot_sd_read_sector+0x7bc>
  100c38:	fa9ff06f          	j	100be0 <boot_sd_read_sector+0x774>
  100c3c:	00000513          	li	a0,0
            if (crc_sw == crc_hw)
  100c40:	fb1ff06f          	j	100bf0 <boot_sd_read_sector+0x784>

00100c44 <bl_print_hex>:
{
  100c44:	00700713          	li	a4,7
  100c48:	100005b7          	lui	a1,0x10000
  100c4c:	00a00613          	li	a2,10
  100c50:	00070693          	mv	a3,a4
        uint8_t n = (uint8_t)((v >> (i * 4)) & 0xFu);
  100c54:	00271713          	slli	a4,a4,0x2
  100c58:	00e55733          	srl	a4,a0,a4
  100c5c:	00f77713          	andi	a4,a4,15
        putchar(n < 10 ? (char)('0' + n) : (char)('A' + n - 10));
  100c60:	00c76663          	bltu	a4,a2,100c6c <bl_print_hex+0x28>
  100c64:	03770713          	addi	a4,a4,55
  100c68:	0100006f          	j	100c78 <bl_print_hex+0x34>
  100c6c:	03070713          	addi	a4,a4,48
  100c70:	0080006f          	j	100c78 <bl_print_hex+0x34>
        __asm__ __volatile__("nop");
  100c74:	00000013          	nop
  100c78:	0085a783          	lw	a5,8(a1) # 10000008 <_stack_top+0xfef4048>
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
  100c7c:	0017f793          	andi	a5,a5,1
  100c80:	fe079ae3          	bnez	a5,100c74 <bl_print_hex+0x30>
    *(volatile uint32_t*)addr = v;
  100c84:	00e5a023          	sw	a4,0(a1)
    for (int i = 7; i >= 0; i--) {
  100c88:	fff68713          	addi	a4,a3,-1
  100c8c:	fc0692e3          	bnez	a3,100c50 <bl_print_hex+0xc>
}
  100c90:	00008067          	ret

00100c94 <memcpy>:
#include "common.h"

void *memcpy(void *dst, const void *src, size_t n) {
    uint8_t *d = (uint8_t *) dst;
    const uint8_t *s = (const uint8_t *) src;
    while (n--)
  100c94:	02060263          	beqz	a2,100cb8 <memcpy+0x24>
  100c98:	00c50633          	add	a2,a0,a2
  100c9c:	00050693          	mv	a3,a0
        *d++ = *s++;
  100ca0:	0005c703          	lbu	a4,0(a1)
  100ca4:	00158593          	addi	a1,a1,1
  100ca8:	00168793          	addi	a5,a3,1
  100cac:	00e68023          	sb	a4,0(a3)
  100cb0:	00078693          	mv	a3,a5
    while (n--)
  100cb4:	fec796e3          	bne	a5,a2,100ca0 <memcpy+0xc>
    return dst;
  100cb8:	00008067          	ret

00100cbc <memcmp>:
int memcmp(const void *a, const void *b, size_t n)
{
    const uint8_t *p1 = (const uint8_t *)a;
    const uint8_t *p2 = (const uint8_t *)b;

    while (n--) {
  100cbc:	02060063          	beqz	a2,100cdc <memcmp+0x20>
        if (*p1 != *p2)
  100cc0:	00054683          	lbu	a3,0(a0)
  100cc4:	0005c703          	lbu	a4,0(a1)
  100cc8:	00e69e63          	bne	a3,a4,100ce4 <memcmp+0x28>
    while (n--) {
  100ccc:	fff60613          	addi	a2,a2,-1
            return (int)*p1 - (int)*p2;
        p1++;
  100cd0:	00150513          	addi	a0,a0,1
        p2++;
  100cd4:	00158593          	addi	a1,a1,1
    while (n--) {
  100cd8:	fe0614e3          	bnez	a2,100cc0 <memcmp+0x4>
  100cdc:	00000513          	li	a0,0
    }

    return 0;
}
  100ce0:	00008067          	ret
            return (int)*p1 - (int)*p2;
  100ce4:	40e68533          	sub	a0,a3,a4
}
  100ce8:	00008067          	ret

00100cec <memset>:

#if 1
void *memset(void *buf, char c, size_t n) {
    uint8_t *p = (uint8_t *) buf;
    while (n--)
  100cec:	00060e63          	beqz	a2,100d08 <memset+0x1c>
  100cf0:	00c50633          	add	a2,a0,a2
  100cf4:	00050693          	mv	a3,a0
        *p++ = c;
  100cf8:	00168713          	addi	a4,a3,1
  100cfc:	00b68023          	sb	a1,0(a3)
  100d00:	00070693          	mv	a3,a4
    while (n--)
  100d04:	fec71ae3          	bne	a4,a2,100cf8 <memset+0xc>
    return buf;
  100d08:	00008067          	ret

00100d0c <s_print_int>:
    *rem = r;
    return q;
}

void s_print_int(int v)
{
  100d0c:	fe010113          	addi	sp,sp,-32
  100d10:	00112e23          	sw	ra,28(sp)
  100d14:	00812c23          	sw	s0,24(sp)
  100d18:	00912a23          	sw	s1,20(sp)
  100d1c:	01212823          	sw	s2,16(sp)
    uint32_t u;
    char buf[10];
    int idx = 0;

    if (v < 0) {
  100d20:	02054463          	bltz	a0,100d48 <s_print_int+0x3c>
        u = (uint32_t)(-(v + 1)) + 1u;
    } else {
        u = (uint32_t)v;
    }

    if (u == 0) {
  100d24:	02051c63          	bnez	a0,100d5c <s_print_int+0x50>
        uart_putchar('0');
  100d28:	03000513          	li	a0,48
  100d2c:	01c12083          	lw	ra,28(sp)
  100d30:	01812403          	lw	s0,24(sp)
  100d34:	01412483          	lw	s1,20(sp)
  100d38:	01012903          	lw	s2,16(sp)
  100d3c:	02010113          	addi	sp,sp,32
  100d40:	fffff317          	auipc	t1,0xfffff
  100d44:	2f430067          	jr	756(t1) # 100034 <uart_putchar>
  100d48:	00050413          	mv	s0,a0
        uart_putchar('-');
  100d4c:	02d00513          	li	a0,45
  100d50:	fffff097          	auipc	ra,0xfffff
  100d54:	2e4080e7          	jalr	740(ra) # 100034 <uart_putchar>
        u = (uint32_t)(-(v + 1)) + 1u;
  100d58:	40800533          	neg	a0,s0
  100d5c:	00000793          	li	a5,0
  100d60:	00100593          	li	a1,1
  100d64:	fff00613          	li	a2,-1
  100d68:	00610693          	addi	a3,sp,6
  100d6c:	00000813          	li	a6,0
  100d70:	00000713          	li	a4,0
  100d74:	00078413          	mv	s0,a5
  100d78:	01f00793          	li	a5,31
        r = (r << 1) | ((u >> i) & 1u);
  100d7c:	00181813          	slli	a6,a6,0x1
  100d80:	00f558b3          	srl	a7,a0,a5
        if (r >= 10u) {
  100d84:	00f592b3          	sll	t0,a1,a5
    for (int i = 31; i >= 0; --i) {
  100d88:	fff78793          	addi	a5,a5,-1
        r = (r << 1) | ((u >> i) & 1u);
  100d8c:	0018f893          	andi	a7,a7,1
  100d90:	0108e8b3          	or	a7,a7,a6
        if (r >= 10u) {
  100d94:	00a83813          	sltiu	a6,a6,10
  100d98:	fff80813          	addi	a6,a6,-1
  100d9c:	005872b3          	and	t0,a6,t0
  100da0:	ff687813          	andi	a6,a6,-10
  100da4:	00e2e733          	or	a4,t0,a4
  100da8:	01088833          	add	a6,a7,a6
    for (int i = 31; i >= 0; --i) {
  100dac:	fcc798e3          	bne	a5,a2,100d7c <s_print_int+0x70>
    }

    while (u != 0) {
        uint32_t rem;
        u = divmod10(u, &rem);
        buf[idx++] = (char)('0' + rem);
  100db0:	03080513          	addi	a0,a6,48
  100db4:	00140793          	addi	a5,s0,1
  100db8:	00868833          	add	a6,a3,s0
  100dbc:	00a80023          	sb	a0,0(a6)
  100dc0:	00070513          	mv	a0,a4
    while (u != 0) {
  100dc4:	fa0714e3          	bnez	a4,100d6c <s_print_int+0x60>
  100dc8:	00610493          	addi	s1,sp,6
  100dcc:	00100913          	li	s2,1
    }

    while (idx > 0) {
        uart_putchar(buf[--idx]);
  100dd0:	00848533          	add	a0,s1,s0
  100dd4:	00054503          	lbu	a0,0(a0)
  100dd8:	fffff097          	auipc	ra,0xfffff
  100ddc:	25c080e7          	jalr	604(ra) # 100034 <uart_putchar>
    while (idx > 0) {
  100de0:	00140513          	addi	a0,s0,1
  100de4:	fff40413          	addi	s0,s0,-1
  100de8:	fea944e3          	blt	s2,a0,100dd0 <s_print_int+0xc4>
    }
}
  100dec:	01c12083          	lw	ra,28(sp)
  100df0:	01812403          	lw	s0,24(sp)
  100df4:	01412483          	lw	s1,20(sp)
  100df8:	01012903          	lw	s2,16(sp)
  100dfc:	02010113          	addi	sp,sp,32
  100e00:	00008067          	ret

00100e04 <s_printf>:

/* ================================================================
 * s_printf
 * ================================================================ */
void s_printf(const char *fmt, ...) {
  100e04:	f9010113          	addi	sp,sp,-112
  100e08:	04112623          	sw	ra,76(sp)
  100e0c:	04812423          	sw	s0,72(sp)
  100e10:	04912223          	sw	s1,68(sp)
  100e14:	05212023          	sw	s2,64(sp)
  100e18:	03312e23          	sw	s3,60(sp)
  100e1c:	03412c23          	sw	s4,56(sp)
  100e20:	03512a23          	sw	s5,52(sp)
  100e24:	03612823          	sw	s6,48(sp)
  100e28:	03712623          	sw	s7,44(sp)
  100e2c:	03812423          	sw	s8,40(sp)
  100e30:	03912223          	sw	s9,36(sp)
  100e34:	03a12023          	sw	s10,32(sp)
  100e38:	01b12e23          	sw	s11,28(sp)
  100e3c:	00050413          	mv	s0,a0
  100e40:	06f12223          	sw	a5,100(sp)
  100e44:	07012423          	sw	a6,104(sp)
  100e48:	07112623          	sw	a7,108(sp)
  100e4c:	04b12a23          	sw	a1,84(sp)
  100e50:	04c12c23          	sw	a2,88(sp)
  100e54:	04d12e23          	sw	a3,92(sp)
  100e58:	06e12023          	sw	a4,96(sp)
  100e5c:	05410513          	addi	a0,sp,84
  100e60:	02500493          	li	s1,37
  100e64:	07200913          	li	s2,114
  100e68:	ccccd5b7          	lui	a1,0xccccd
  100e6c:	00d10a13          	addi	s4,sp,13
  100e70:	00900a93          	li	s5,9
  100e74:	00100b13          	li	s6,1
  100e78:	07300b93          	li	s7,115
  100e7c:	07800c13          	li	s8,120
    va_list vargs;
    va_start(vargs, fmt);
  100e80:	00a12c23          	sw	a0,24(sp)
  100e84:	ccd58c93          	addi	s9,a1,-819 # cccccccd <_stack_top+0xccbc0d0d>
  100e88:	00103d37          	lui	s10,0x103
  100e8c:	2fad0d13          	addi	s10,s10,762 # 1032fa <print_hex8.HEX>
  100e90:	00c0006f          	j	100e9c <s_printf+0x98>

    while (*fmt) {
        if (*fmt == '%') {
            fmt++;
            switch (*fmt) {
  100e94:	1e050a63          	beqz	a0,101088 <s_printf+0x284>
            }
        } else {
            uart_putchar(*fmt);
        }

        fmt++;
  100e98:	00140413          	addi	s0,s0,1
    while (*fmt) {
  100e9c:	00044503          	lbu	a0,0(s0)
  100ea0:	00950c63          	beq	a0,s1,100eb8 <s_printf+0xb4>
  100ea4:	1e050863          	beqz	a0,101094 <s_printf+0x290>
  100ea8:	fffff097          	auipc	ra,0xfffff
  100eac:	18c080e7          	jalr	396(ra) # 100034 <uart_putchar>
        fmt++;
  100eb0:	00140413          	addi	s0,s0,1
    while (*fmt) {
  100eb4:	fe9ff06f          	j	100e9c <s_printf+0x98>
            switch (*fmt) {
  100eb8:	00144503          	lbu	a0,1(s0)
            fmt++;
  100ebc:	00140413          	addi	s0,s0,1
            switch (*fmt) {
  100ec0:	02a94e63          	blt	s2,a0,100efc <s_printf+0xf8>
  100ec4:	10950863          	beq	a0,s1,100fd4 <s_printf+0x1d0>
  100ec8:	06400593          	li	a1,100
  100ecc:	fcb514e3          	bne	a0,a1,100e94 <s_printf+0x90>
                    int value = va_arg(vargs, int);
  100ed0:	01812503          	lw	a0,24(sp)
  100ed4:	00450593          	addi	a1,a0,4
  100ed8:	00b12c23          	sw	a1,24(sp)
  100edc:	00052d83          	lw	s11,0(a0)
                    if (value < 0) {
  100ee0:	140dc063          	bltz	s11,101020 <s_printf+0x21c>
                    if (u == 0) {
  100ee4:	140d9663          	bnez	s11,101030 <s_printf+0x22c>
                        uart_putchar('0');
  100ee8:	03000513          	li	a0,48
  100eec:	fffff097          	auipc	ra,0xfffff
  100ef0:	148080e7          	jalr	328(ra) # 100034 <uart_putchar>
        fmt++;
  100ef4:	00140413          	addi	s0,s0,1
    while (*fmt) {
  100ef8:	fa5ff06f          	j	100e9c <s_printf+0x98>
            switch (*fmt) {
  100efc:	0f750663          	beq	a0,s7,100fe8 <s_printf+0x1e4>
  100f00:	f9851ce3          	bne	a0,s8,100e98 <s_printf+0x94>
                    unsigned value = va_arg(vargs, unsigned);
  100f04:	01812503          	lw	a0,24(sp)
  100f08:	00450593          	addi	a1,a0,4
  100f0c:	00b12c23          	sw	a1,24(sp)
  100f10:	00052983          	lw	s3,0(a0)
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  100f14:	01c9d513          	srli	a0,s3,0x1c
                        uart_putchar("0123456789abcdef"[nibble]);
  100f18:	00ad0533          	add	a0,s10,a0
  100f1c:	00054503          	lbu	a0,0(a0)
  100f20:	fffff097          	auipc	ra,0xfffff
  100f24:	114080e7          	jalr	276(ra) # 100034 <uart_putchar>
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  100f28:	00499513          	slli	a0,s3,0x4
  100f2c:	01c55513          	srli	a0,a0,0x1c
                        uart_putchar("0123456789abcdef"[nibble]);
  100f30:	00ad0533          	add	a0,s10,a0
  100f34:	00054503          	lbu	a0,0(a0)
  100f38:	fffff097          	auipc	ra,0xfffff
  100f3c:	0fc080e7          	jalr	252(ra) # 100034 <uart_putchar>
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  100f40:	00899513          	slli	a0,s3,0x8
  100f44:	01c55513          	srli	a0,a0,0x1c
                        uart_putchar("0123456789abcdef"[nibble]);
  100f48:	00ad0533          	add	a0,s10,a0
  100f4c:	00054503          	lbu	a0,0(a0)
  100f50:	fffff097          	auipc	ra,0xfffff
  100f54:	0e4080e7          	jalr	228(ra) # 100034 <uart_putchar>
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  100f58:	00c99513          	slli	a0,s3,0xc
  100f5c:	01c55513          	srli	a0,a0,0x1c
                        uart_putchar("0123456789abcdef"[nibble]);
  100f60:	00ad0533          	add	a0,s10,a0
  100f64:	00054503          	lbu	a0,0(a0)
  100f68:	fffff097          	auipc	ra,0xfffff
  100f6c:	0cc080e7          	jalr	204(ra) # 100034 <uart_putchar>
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  100f70:	01099513          	slli	a0,s3,0x10
  100f74:	01c55513          	srli	a0,a0,0x1c
                        uart_putchar("0123456789abcdef"[nibble]);
  100f78:	00ad0533          	add	a0,s10,a0
  100f7c:	00054503          	lbu	a0,0(a0)
  100f80:	fffff097          	auipc	ra,0xfffff
  100f84:	0b4080e7          	jalr	180(ra) # 100034 <uart_putchar>
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  100f88:	01499513          	slli	a0,s3,0x14
  100f8c:	01c55513          	srli	a0,a0,0x1c
                        uart_putchar("0123456789abcdef"[nibble]);
  100f90:	00ad0533          	add	a0,s10,a0
  100f94:	00054503          	lbu	a0,0(a0)
  100f98:	fffff097          	auipc	ra,0xfffff
  100f9c:	09c080e7          	jalr	156(ra) # 100034 <uart_putchar>
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  100fa0:	01899513          	slli	a0,s3,0x18
  100fa4:	01c55513          	srli	a0,a0,0x1c
                        uart_putchar("0123456789abcdef"[nibble]);
  100fa8:	00ad0533          	add	a0,s10,a0
  100fac:	00054503          	lbu	a0,0(a0)
  100fb0:	fffff097          	auipc	ra,0xfffff
  100fb4:	084080e7          	jalr	132(ra) # 100034 <uart_putchar>
                        unsigned nibble = (value >> (i * 4)) & 0xf;
  100fb8:	00f9f513          	andi	a0,s3,15
                        uart_putchar("0123456789abcdef"[nibble]);
  100fbc:	00ad0533          	add	a0,s10,a0
  100fc0:	00054503          	lbu	a0,0(a0)
  100fc4:	fffff097          	auipc	ra,0xfffff
  100fc8:	070080e7          	jalr	112(ra) # 100034 <uart_putchar>
        fmt++;
  100fcc:	00140413          	addi	s0,s0,1
    while (*fmt) {
  100fd0:	ecdff06f          	j	100e9c <s_printf+0x98>
                    uart_putchar('%');
  100fd4:	02500513          	li	a0,37
  100fd8:	fffff097          	auipc	ra,0xfffff
  100fdc:	05c080e7          	jalr	92(ra) # 100034 <uart_putchar>
        fmt++;
  100fe0:	00140413          	addi	s0,s0,1
    while (*fmt) {
  100fe4:	eb9ff06f          	j	100e9c <s_printf+0x98>
                    const char *s = va_arg(vargs, const char *);
  100fe8:	01812503          	lw	a0,24(sp)
  100fec:	00450593          	addi	a1,a0,4
  100ff0:	00b12c23          	sw	a1,24(sp)
  100ff4:	00052983          	lw	s3,0(a0)
                    while (*s) {
  100ff8:	0009c503          	lbu	a0,0(s3)
  100ffc:	e8050ee3          	beqz	a0,100e98 <s_printf+0x94>
  101000:	00198993          	addi	s3,s3,1
                        uart_putchar(*s);
  101004:	0ff57513          	zext.b	a0,a0
  101008:	fffff097          	auipc	ra,0xfffff
  10100c:	02c080e7          	jalr	44(ra) # 100034 <uart_putchar>
                    while (*s) {
  101010:	0009c503          	lbu	a0,0(s3)
  101014:	00198993          	addi	s3,s3,1
  101018:	fe0516e3          	bnez	a0,101004 <s_printf+0x200>
  10101c:	e7dff06f          	j	100e98 <s_printf+0x94>
                        uart_putchar('-');
  101020:	02d00513          	li	a0,45
  101024:	fffff097          	auipc	ra,0xfffff
  101028:	010080e7          	jalr	16(ra) # 100034 <uart_putchar>
                        u = (unsigned int)(-(value + 1)) + 1;
  10102c:	41b00db3          	neg	s11,s11
  101030:	00000513          	li	a0,0
  101034:	000d8593          	mv	a1,s11
  101038:	00050993          	mv	s3,a0
                        u /= 10;
  10103c:	039db633          	mulhu	a2,s11,s9
                        buf[i++] = '0' + (u % 10);
  101040:	00150513          	addi	a0,a0,1
                        u /= 10;
  101044:	00365d93          	srli	s11,a2,0x3
                        buf[i++] = '0' + (u % 10);
  101048:	0f867613          	andi	a2,a2,248
  10104c:	001d9693          	slli	a3,s11,0x1
  101050:	40c58633          	sub	a2,a1,a2
  101054:	40d60633          	sub	a2,a2,a3
  101058:	03066613          	ori	a2,a2,48
  10105c:	013a06b3          	add	a3,s4,s3
  101060:	00c68023          	sb	a2,0(a3)
                    while (u > 0) {
  101064:	fcbae8e3          	bltu	s5,a1,101034 <s_printf+0x230>
                        uart_putchar(buf[--i]);
  101068:	013a0533          	add	a0,s4,s3
  10106c:	00054503          	lbu	a0,0(a0)
  101070:	fffff097          	auipc	ra,0xfffff
  101074:	fc4080e7          	jalr	-60(ra) # 100034 <uart_putchar>
                    while (i > 0) {
  101078:	00198513          	addi	a0,s3,1
  10107c:	fff98993          	addi	s3,s3,-1
  101080:	feab44e3          	blt	s6,a0,101068 <s_printf+0x264>
  101084:	e15ff06f          	j	100e98 <s_printf+0x94>
                    uart_putchar('%');
  101088:	02500513          	li	a0,37
  10108c:	fffff097          	auipc	ra,0xfffff
  101090:	fa8080e7          	jalr	-88(ra) # 100034 <uart_putchar>
    }

end:
    va_end(vargs);
}
  101094:	04c12083          	lw	ra,76(sp)
  101098:	04812403          	lw	s0,72(sp)
  10109c:	04412483          	lw	s1,68(sp)
  1010a0:	04012903          	lw	s2,64(sp)
  1010a4:	03c12983          	lw	s3,60(sp)
  1010a8:	03812a03          	lw	s4,56(sp)
  1010ac:	03412a83          	lw	s5,52(sp)
  1010b0:	03012b03          	lw	s6,48(sp)
  1010b4:	02c12b83          	lw	s7,44(sp)
  1010b8:	02812c03          	lw	s8,40(sp)
  1010bc:	02412c83          	lw	s9,36(sp)
  1010c0:	02012d03          	lw	s10,32(sp)
  1010c4:	01c12d83          	lw	s11,28(sp)
  1010c8:	07010113          	addi	sp,sp,112
  1010cc:	00008067          	ret

001010d0 <parse_hex>:
/* 簡易16進パーサ（"  0x1234" / "1234" 形式どちらも可） */
int parse_hex(const char *s, uintptr_t *out) {
    uintptr_t v = 0;

    /* skip leading spaces */
    while (*s == ' ' || *s == '\t') s++;
  1010d0:	00250693          	addi	a3,a0,2
  1010d4:	00900613          	li	a2,9
  1010d8:	02000713          	li	a4,32
  1010dc:	0080006f          	j	1010e4 <parse_hex+0x14>
  1010e0:	00168693          	addi	a3,a3,1
  1010e4:	ffe6c503          	lbu	a0,-2(a3)
  1010e8:	fec50ce3          	beq	a0,a2,1010e0 <parse_hex+0x10>
  1010ec:	fee50ae3          	beq	a0,a4,1010e0 <parse_hex+0x10>
  1010f0:	03000613          	li	a2,48
  1010f4:	02c51063          	bne	a0,a2,101114 <parse_hex+0x44>

    /* optional 0x / 0X */
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s += 2;
  1010f8:	fff6c503          	lbu	a0,-1(a3)
  1010fc:	02056513          	ori	a0,a0,32
  101100:	07800613          	li	a2,120
  101104:	02c51063          	bne	a0,a2,101124 <parse_hex+0x54>
    if (!*s) return -1;
  101108:	0006c503          	lbu	a0,0(a3)
  10110c:	02051063          	bnez	a0,10112c <parse_hex+0x5c>
  101110:	00c0006f          	j	10111c <parse_hex+0x4c>
  101114:	ffe68693          	addi	a3,a3,-2
  101118:	00051a63          	bnez	a0,10112c <parse_hex+0x5c>
  10111c:	fff00513          	li	a0,-1
        else break;
        v = (v << 4) | d;
    }
    *out = v;
    return 0;
}
  101120:	00008067          	ret
  101124:	ffe68693          	addi	a3,a3,-2
  101128:	03000513          	li	a0,48
  10112c:	00000613          	li	a2,0
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  101130:	00168693          	addi	a3,a3,1
  101134:	00a00713          	li	a4,10
  101138:	00600793          	li	a5,6
  10113c:	00500813          	li	a6,5
  101140:	0200006f          	j	101160 <parse_hex+0x90>
  101144:	fd000893          	li	a7,-48
  101148:	00a888b3          	add	a7,a7,a0
    while (*s) {
  10114c:	0006c503          	lbu	a0,0(a3)
        v = (v << 4) | d;
  101150:	00461613          	slli	a2,a2,0x4
  101154:	00c8e633          	or	a2,a7,a2
    while (*s) {
  101158:	00168693          	addi	a3,a3,1
  10115c:	02050663          	beqz	a0,101188 <parse_hex+0xb8>
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  101160:	fd050893          	addi	a7,a0,-48
  101164:	fee8e0e3          	bltu	a7,a4,101144 <parse_hex+0x74>
        else if (c >= 'a' && c <= 'f') d = 10u + (uint32_t)(c - 'a');
  101168:	f9f50893          	addi	a7,a0,-97
  10116c:	00f8f663          	bgeu	a7,a5,101178 <parse_hex+0xa8>
  101170:	fa900893          	li	a7,-87
  101174:	fd5ff06f          	j	101148 <parse_hex+0x78>
        else if (c >= 'A' && c <= 'F') d = 10u + (uint32_t)(c - 'A');
  101178:	fbf50893          	addi	a7,a0,-65
  10117c:	01186663          	bltu	a6,a7,101188 <parse_hex+0xb8>
  101180:	fc900893          	li	a7,-55
  101184:	fc5ff06f          	j	101148 <parse_hex+0x78>
  101188:	00000513          	li	a0,0
    *out = v;
  10118c:	00c5a023          	sw	a2,0(a1)
}
  101190:	00008067          	ret

00101194 <hexdump>:
 */
void hexdump(const void *addr, size_t len, uintptr_t base_addr_label) {
    const uint8_t *p = (const uint8_t *)addr;
    size_t off = 0;

    while (off < len) {
  101194:	26058663          	beqz	a1,101400 <hexdump+0x26c>
  101198:	fc010113          	addi	sp,sp,-64
  10119c:	02112e23          	sw	ra,60(sp)
  1011a0:	02812c23          	sw	s0,56(sp)
  1011a4:	02912a23          	sw	s1,52(sp)
  1011a8:	03212823          	sw	s2,48(sp)
  1011ac:	03312623          	sw	s3,44(sp)
  1011b0:	03412423          	sw	s4,40(sp)
  1011b4:	03512223          	sw	s5,36(sp)
  1011b8:	03612023          	sw	s6,32(sp)
  1011bc:	01712e23          	sw	s7,28(sp)
  1011c0:	01812c23          	sw	s8,24(sp)
  1011c4:	01912a23          	sw	s9,20(sp)
  1011c8:	01a12823          	sw	s10,16(sp)
  1011cc:	01b12623          	sw	s11,12(sp)
  1011d0:	00060413          	mv	s0,a2
  1011d4:	00058493          	mv	s1,a1
  1011d8:	00050913          	mv	s2,a0
  1011dc:	00000a93          	li	s5,0
  1011e0:	00103b37          	lui	s6,0x103
  1011e4:	2fab0b13          	addi	s6,s6,762 # 1032fa <print_hex8.HEX>
  1011e8:	00700b93          	li	s7,7
  1011ec:	01000c13          	li	s8,16
  1011f0:	05f00c93          	li	s9,95
  1011f4:	0240006f          	j	101218 <hexdump+0x84>
        uart_putchar('|');
        for (size_t i = 0; i < line; i++) {
            uint8_t c = p[off + i];
            uart_putchar((c >= 0x20 && c <= 0x7e) ? (char)c : '.');
        }
        uart_putchar('|');
  1011f8:	07c00513          	li	a0,124
  1011fc:	fffff097          	auipc	ra,0xfffff
  101200:	e38080e7          	jalr	-456(ra) # 100034 <uart_putchar>
        uart_putchar('\n');
  101204:	00a00513          	li	a0,10
  101208:	fffff097          	auipc	ra,0xfffff
  10120c:	e2c080e7          	jalr	-468(ra) # 100034 <uart_putchar>

        off += line;
  101210:	015d0ab3          	add	s5,s10,s5
    while (off < len) {
  101214:	1a9afa63          	bgeu	s5,s1,1013c8 <hexdump+0x234>
        print_hex32((uint32_t)(base_addr_label + off));
  101218:	008a8a33          	add	s4,s5,s0
        uint8_t nib = (v >> (i * 4)) & 0x0F;
  10121c:	01ca5513          	srli	a0,s4,0x1c
        uart_putchar(HEX[nib]);
  101220:	00ab0533          	add	a0,s6,a0
  101224:	00054503          	lbu	a0,0(a0)
        size_t line = (len - off > 16) ? 16 : (len - off);
  101228:	41548d33          	sub	s10,s1,s5
        uart_putchar(HEX[nib]);
  10122c:	fffff097          	auipc	ra,0xfffff
  101230:	e08080e7          	jalr	-504(ra) # 100034 <uart_putchar>
        uint8_t nib = (v >> (i * 4)) & 0x0F;
  101234:	004a1513          	slli	a0,s4,0x4
  101238:	01c55513          	srli	a0,a0,0x1c
        uart_putchar(HEX[nib]);
  10123c:	00ab0533          	add	a0,s6,a0
  101240:	00054503          	lbu	a0,0(a0)
  101244:	fffff097          	auipc	ra,0xfffff
  101248:	df0080e7          	jalr	-528(ra) # 100034 <uart_putchar>
        uint8_t nib = (v >> (i * 4)) & 0x0F;
  10124c:	008a1513          	slli	a0,s4,0x8
  101250:	01c55513          	srli	a0,a0,0x1c
        uart_putchar(HEX[nib]);
  101254:	00ab0533          	add	a0,s6,a0
  101258:	00054503          	lbu	a0,0(a0)
  10125c:	fffff097          	auipc	ra,0xfffff
  101260:	dd8080e7          	jalr	-552(ra) # 100034 <uart_putchar>
        uint8_t nib = (v >> (i * 4)) & 0x0F;
  101264:	00ca1513          	slli	a0,s4,0xc
  101268:	01c55513          	srli	a0,a0,0x1c
        uart_putchar(HEX[nib]);
  10126c:	00ab0533          	add	a0,s6,a0
  101270:	00054503          	lbu	a0,0(a0)
  101274:	fffff097          	auipc	ra,0xfffff
  101278:	dc0080e7          	jalr	-576(ra) # 100034 <uart_putchar>
        uint8_t nib = (v >> (i * 4)) & 0x0F;
  10127c:	010a1513          	slli	a0,s4,0x10
  101280:	01c55513          	srli	a0,a0,0x1c
        uart_putchar(HEX[nib]);
  101284:	00ab0533          	add	a0,s6,a0
  101288:	00054503          	lbu	a0,0(a0)
  10128c:	fffff097          	auipc	ra,0xfffff
  101290:	da8080e7          	jalr	-600(ra) # 100034 <uart_putchar>
        uint8_t nib = (v >> (i * 4)) & 0x0F;
  101294:	014a1513          	slli	a0,s4,0x14
  101298:	01c55513          	srli	a0,a0,0x1c
        uart_putchar(HEX[nib]);
  10129c:	00ab0533          	add	a0,s6,a0
  1012a0:	00054503          	lbu	a0,0(a0)
  1012a4:	fffff097          	auipc	ra,0xfffff
  1012a8:	d90080e7          	jalr	-624(ra) # 100034 <uart_putchar>
        uint8_t nib = (v >> (i * 4)) & 0x0F;
  1012ac:	018a1513          	slli	a0,s4,0x18
  1012b0:	01c55513          	srli	a0,a0,0x1c
        uart_putchar(HEX[nib]);
  1012b4:	00ab0533          	add	a0,s6,a0
  1012b8:	00054503          	lbu	a0,0(a0)
  1012bc:	fffff097          	auipc	ra,0xfffff
  1012c0:	d78080e7          	jalr	-648(ra) # 100034 <uart_putchar>
        uint8_t nib = (v >> (i * 4)) & 0x0F;
  1012c4:	00fa7513          	andi	a0,s4,15
        uart_putchar(HEX[nib]);
  1012c8:	00ab0533          	add	a0,s6,a0
  1012cc:	00054503          	lbu	a0,0(a0)
  1012d0:	fffff097          	auipc	ra,0xfffff
  1012d4:	d64080e7          	jalr	-668(ra) # 100034 <uart_putchar>
        s_printf(": ");
  1012d8:	00103537          	lui	a0,0x103
  1012dc:	28050513          	addi	a0,a0,640 # 103280 <boot_fat32_load_mem_file+0x538>
  1012e0:	00000097          	auipc	ra,0x0
  1012e4:	b24080e7          	jalr	-1244(ra) # 100e04 <s_printf>
  1012e8:	00000993          	li	s3,0
  1012ec:	01590db3          	add	s11,s2,s5
  1012f0:	00c0006f          	j	1012fc <hexdump+0x168>
        for (size_t i = 0; i < 16; i++) {
  1012f4:	00198993          	addi	s3,s3,1
  1012f8:	07898863          	beq	s3,s8,101368 <hexdump+0x1d4>
  1012fc:	03a9f863          	bgeu	s3,s10,10132c <hexdump+0x198>
                print_hex8(p[off + i]);
  101300:	013d8533          	add	a0,s11,s3
  101304:	00054a03          	lbu	s4,0(a0)
    uart_putchar(HEX[v >> 4]);
  101308:	004a5513          	srli	a0,s4,0x4
  10130c:	00ab0533          	add	a0,s6,a0
  101310:	00054503          	lbu	a0,0(a0)
  101314:	fffff097          	auipc	ra,0xfffff
  101318:	d20080e7          	jalr	-736(ra) # 100034 <uart_putchar>
    uart_putchar(HEX[v & 0x0F]);
  10131c:	00fa7513          	andi	a0,s4,15
  101320:	00ab0533          	add	a0,s6,a0
  101324:	00054a03          	lbu	s4,0(a0)
            } else {
  101328:	0140006f          	j	10133c <hexdump+0x1a8>
                uart_putchar(' ');
  10132c:	02000513          	li	a0,32
  101330:	02000a13          	li	s4,32
  101334:	fffff097          	auipc	ra,0xfffff
  101338:	d00080e7          	jalr	-768(ra) # 100034 <uart_putchar>
  10133c:	000a0513          	mv	a0,s4
  101340:	fffff097          	auipc	ra,0xfffff
  101344:	cf4080e7          	jalr	-780(ra) # 100034 <uart_putchar>
            uart_putchar(' ');
  101348:	02000513          	li	a0,32
  10134c:	fffff097          	auipc	ra,0xfffff
  101350:	ce8080e7          	jalr	-792(ra) # 100034 <uart_putchar>
            if (i == 7) uart_putchar(' '); /* 8バイト境界でスペース追加 */
  101354:	fb7990e3          	bne	s3,s7,1012f4 <hexdump+0x160>
  101358:	02000513          	li	a0,32
  10135c:	fffff097          	auipc	ra,0xfffff
  101360:	cd8080e7          	jalr	-808(ra) # 100034 <uart_putchar>
  101364:	f91ff06f          	j	1012f4 <hexdump+0x160>
  101368:	01000513          	li	a0,16
        size_t line = (len - off > 16) ? 16 : (len - off);
  10136c:	00ad6463          	bltu	s10,a0,101374 <hexdump+0x1e0>
  101370:	01000d13          	li	s10,16
        uart_putchar(' ');
  101374:	02000513          	li	a0,32
  101378:	fffff097          	auipc	ra,0xfffff
  10137c:	cbc080e7          	jalr	-836(ra) # 100034 <uart_putchar>
        uart_putchar('|');
  101380:	07c00513          	li	a0,124
  101384:	fffff097          	auipc	ra,0xfffff
  101388:	cb0080e7          	jalr	-848(ra) # 100034 <uart_putchar>
        for (size_t i = 0; i < line; i++) {
  10138c:	e75486e3          	beq	s1,s5,1011f8 <hexdump+0x64>
  101390:	01aa89b3          	add	s3,s5,s10
  101394:	013909b3          	add	s3,s2,s3
  101398:	0180006f          	j	1013b0 <hexdump+0x21c>
            uart_putchar((c >= 0x20 && c <= 0x7e) ? (char)c : '.');
  10139c:	0ff57513          	zext.b	a0,a0
  1013a0:	fffff097          	auipc	ra,0xfffff
  1013a4:	c94080e7          	jalr	-876(ra) # 100034 <uart_putchar>
        for (size_t i = 0; i < line; i++) {
  1013a8:	001d8d93          	addi	s11,s11,1
  1013ac:	e53d86e3          	beq	s11,s3,1011f8 <hexdump+0x64>
            uint8_t c = p[off + i];
  1013b0:	000dc503          	lbu	a0,0(s11)
            uart_putchar((c >= 0x20 && c <= 0x7e) ? (char)c : '.');
  1013b4:	fe050593          	addi	a1,a0,-32
  1013b8:	0ff5f593          	zext.b	a1,a1
  1013bc:	ff95e0e3          	bltu	a1,s9,10139c <hexdump+0x208>
  1013c0:	02e00513          	li	a0,46
  1013c4:	fd9ff06f          	j	10139c <hexdump+0x208>
  1013c8:	03c12083          	lw	ra,60(sp)
  1013cc:	03812403          	lw	s0,56(sp)
  1013d0:	03412483          	lw	s1,52(sp)
  1013d4:	03012903          	lw	s2,48(sp)
  1013d8:	02c12983          	lw	s3,44(sp)
  1013dc:	02812a03          	lw	s4,40(sp)
  1013e0:	02412a83          	lw	s5,36(sp)
  1013e4:	02012b03          	lw	s6,32(sp)
  1013e8:	01c12b83          	lw	s7,28(sp)
  1013ec:	01812c03          	lw	s8,24(sp)
  1013f0:	01412c83          	lw	s9,20(sp)
  1013f4:	01012d03          	lw	s10,16(sp)
  1013f8:	00c12d83          	lw	s11,12(sp)
  1013fc:	04010113          	addi	sp,sp,64
    }
}
  101400:	00008067          	ret

00101404 <cmd_dump>:

void cmd_dump(int argc, const char **argv) {
  101404:	ff010113          	addi	sp,sp,-16
  101408:	00112623          	sw	ra,12(sp)
  10140c:	00812423          	sw	s0,8(sp)
  101410:	00000413          	li	s0,0
    const size_t    MAX_LEN      = 0x1000u;      /* 誤爆防止の上限 */

    uintptr_t addr = DEFAULT_BASE;
    size_t    len  = DEFAULT_LEN;

    if (argc >= 1 && argv && argv[0] && argv[0][0]) {
  101414:	06a05063          	blez	a0,101474 <cmd_dump+0x70>
  101418:	04058e63          	beqz	a1,101474 <cmd_dump+0x70>
  10141c:	0005a683          	lw	a3,0(a1)
  101420:	04068863          	beqz	a3,101470 <cmd_dump+0x6c>
  101424:	0006c603          	lbu	a2,0(a3)
  101428:	04060463          	beqz	a2,101470 <cmd_dump+0x6c>
    while (*s == ' ' || *s == '\t') s++;
  10142c:	00268693          	addi	a3,a3,2
  101430:	00900713          	li	a4,9
  101434:	02000793          	li	a5,32
  101438:	00c0006f          	j	101444 <cmd_dump+0x40>
  10143c:	fff6c603          	lbu	a2,-1(a3)
  101440:	00168693          	addi	a3,a3,1
  101444:	fee60ce3          	beq	a2,a4,10143c <cmd_dump+0x38>
  101448:	fef60ae3          	beq	a2,a5,10143c <cmd_dump+0x38>
  10144c:	03000713          	li	a4,48
  101450:	08e61463          	bne	a2,a4,1014d8 <cmd_dump+0xd4>
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s += 2;
  101454:	fff6c603          	lbu	a2,-1(a3)
  101458:	02066613          	ori	a2,a2,32
  10145c:	07800713          	li	a4,120
  101460:	0ae61863          	bne	a2,a4,101510 <cmd_dump+0x10c>
    if (!*s) return -1;
  101464:	0006c603          	lbu	a2,0(a3)
  101468:	0a061863          	bnez	a2,101518 <cmd_dump+0x114>
  10146c:	0740006f          	j	1014e0 <cmd_dump+0xdc>
  101470:	00000413          	li	s0,0
  101474:	00200693          	li	a3,2
  101478:	10000613          	li	a2,256
  10147c:	18d54663          	blt	a0,a3,101608 <cmd_dump+0x204>
  101480:	18058463          	beqz	a1,101608 <cmd_dump+0x204>
            s_printf("usage: dmp [offset_hex] [len_hex]\n");
            return;
        }
        addr = DEFAULT_BASE + offset;
    }
    if (argc >= 2 && argv && argv[1] && argv[1][0]) {
  101484:	0045a683          	lw	a3,4(a1)
  101488:	18068063          	beqz	a3,101608 <cmd_dump+0x204>
  10148c:	0006c503          	lbu	a0,0(a3)
  101490:	16050c63          	beqz	a0,101608 <cmd_dump+0x204>
    while (*s == ' ' || *s == '\t') s++;
  101494:	00268693          	addi	a3,a3,2
  101498:	00900593          	li	a1,9
  10149c:	02000713          	li	a4,32
  1014a0:	00c0006f          	j	1014ac <cmd_dump+0xa8>
  1014a4:	fff6c503          	lbu	a0,-1(a3)
  1014a8:	00168693          	addi	a3,a3,1
  1014ac:	feb50ce3          	beq	a0,a1,1014a4 <cmd_dump+0xa0>
  1014b0:	fee50ae3          	beq	a0,a4,1014a4 <cmd_dump+0xa0>
  1014b4:	03000593          	li	a1,48
  1014b8:	02b51a63          	bne	a0,a1,1014ec <cmd_dump+0xe8>
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s += 2;
  1014bc:	fff6c503          	lbu	a0,-1(a3)
  1014c0:	02056513          	ori	a0,a0,32
  1014c4:	07800593          	li	a1,120
  1014c8:	0ab51663          	bne	a0,a1,101574 <cmd_dump+0x170>
    if (!*s) return -1;
  1014cc:	0006c503          	lbu	a0,0(a3)
  1014d0:	0a051663          	bnez	a0,10157c <cmd_dump+0x178>
  1014d4:	0200006f          	j	1014f4 <cmd_dump+0xf0>
  1014d8:	ffe68693          	addi	a3,a3,-2
  1014dc:	02061e63          	bnez	a2,101518 <cmd_dump+0x114>
            s_printf("usage: dmp [offset_hex] [len_hex]\n");
  1014e0:	00103537          	lui	a0,0x103
  1014e4:	28350513          	addi	a0,a0,643 # 103283 <boot_fat32_load_mem_file+0x53b>
  1014e8:	0140006f          	j	1014fc <cmd_dump+0xf8>
    if (!*s) return -1;
  1014ec:	ffe68693          	addi	a3,a3,-2
  1014f0:	08051663          	bnez	a0,10157c <cmd_dump+0x178>
        uintptr_t lhex = 0;
        if (parse_hex(argv[1], &lhex) != 0) {
            s_printf("usage: dump [offset_hex] [len_hex]\n");
  1014f4:	00103537          	lui	a0,0x103
  1014f8:	2a650513          	addi	a0,a0,678 # 1032a6 <boot_fat32_load_mem_file+0x55e>
  1014fc:	00c12083          	lw	ra,12(sp)
  101500:	00812403          	lw	s0,8(sp)
  101504:	01010113          	addi	sp,sp,16
  101508:	00000317          	auipc	t1,0x0
  10150c:	8fc30067          	jr	-1796(t1) # 100e04 <s_printf>
  101510:	ffe68693          	addi	a3,a3,-2
  101514:	03000613          	li	a2,48
  101518:	00000413          	li	s0,0
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  10151c:	00168693          	addi	a3,a3,1
  101520:	00a00713          	li	a4,10
  101524:	00600793          	li	a5,6
  101528:	00500813          	li	a6,5
  10152c:	0200006f          	j	10154c <cmd_dump+0x148>
  101530:	fd000893          	li	a7,-48
  101534:	00c888b3          	add	a7,a7,a2
    while (*s) {
  101538:	0006c603          	lbu	a2,0(a3)
        v = (v << 4) | d;
  10153c:	00441413          	slli	s0,s0,0x4
  101540:	0088e433          	or	s0,a7,s0
    while (*s) {
  101544:	00168693          	addi	a3,a3,1
  101548:	f20606e3          	beqz	a2,101474 <cmd_dump+0x70>
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  10154c:	fd060893          	addi	a7,a2,-48
  101550:	fee8e0e3          	bltu	a7,a4,101530 <cmd_dump+0x12c>
        else if (c >= 'a' && c <= 'f') d = 10u + (uint32_t)(c - 'a');
  101554:	f9f60893          	addi	a7,a2,-97
  101558:	00f8f663          	bgeu	a7,a5,101564 <cmd_dump+0x160>
  10155c:	fa900893          	li	a7,-87
  101560:	fd5ff06f          	j	101534 <cmd_dump+0x130>
        else if (c >= 'A' && c <= 'F') d = 10u + (uint32_t)(c - 'A');
  101564:	fbf60893          	addi	a7,a2,-65
  101568:	f11866e3          	bltu	a6,a7,101474 <cmd_dump+0x70>
  10156c:	fc900893          	li	a7,-55
  101570:	fc5ff06f          	j	101534 <cmd_dump+0x130>
  101574:	ffe68693          	addi	a3,a3,-2
  101578:	03000513          	li	a0,48
  10157c:	00000593          	li	a1,0
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  101580:	00168693          	addi	a3,a3,1
  101584:	00a00713          	li	a4,10
  101588:	00600793          	li	a5,6
  10158c:	00500813          	li	a6,5
  101590:	0200006f          	j	1015b0 <cmd_dump+0x1ac>
  101594:	fd000893          	li	a7,-48
  101598:	00a888b3          	add	a7,a7,a0
    while (*s) {
  10159c:	0006c503          	lbu	a0,0(a3)
        v = (v << 4) | d;
  1015a0:	00459593          	slli	a1,a1,0x4
  1015a4:	00b8e5b3          	or	a1,a7,a1
    while (*s) {
  1015a8:	00168693          	addi	a3,a3,1
  1015ac:	02050663          	beqz	a0,1015d8 <cmd_dump+0x1d4>
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
  1015b0:	fd050893          	addi	a7,a0,-48
  1015b4:	fee8e0e3          	bltu	a7,a4,101594 <cmd_dump+0x190>
        else if (c >= 'a' && c <= 'f') d = 10u + (uint32_t)(c - 'a');
  1015b8:	f9f50893          	addi	a7,a0,-97
  1015bc:	00f8f663          	bgeu	a7,a5,1015c8 <cmd_dump+0x1c4>
  1015c0:	fa900893          	li	a7,-87
  1015c4:	fd5ff06f          	j	101598 <cmd_dump+0x194>
        else if (c >= 'A' && c <= 'F') d = 10u + (uint32_t)(c - 'A');
  1015c8:	fbf50893          	addi	a7,a0,-65
  1015cc:	01186663          	bltu	a6,a7,1015d8 <cmd_dump+0x1d4>
  1015d0:	fc900893          	li	a7,-55
  1015d4:	fc5ff06f          	j	101598 <cmd_dump+0x194>
            return;
        }
        len = (size_t)lhex;
    }

    if (len == 0) {
  1015d8:	02058863          	beqz	a1,101608 <cmd_dump+0x204>
  1015dc:	00001537          	lui	a0,0x1
  1015e0:	00150513          	addi	a0,a0,1 # 1001 <_start-0xfefff>
  1015e4:	00058613          	mv	a2,a1
        len = DEFAULT_LEN;
    } else if (len > MAX_LEN) {
  1015e8:	02a5e063          	bltu	a1,a0,101608 <cmd_dump+0x204>
        s_printf("[info] len too big (>0x%X), round down to 0x%X\n",
  1015ec:	00103537          	lui	a0,0x103
  1015f0:	2ca50513          	addi	a0,a0,714 # 1032ca <boot_fat32_load_mem_file+0x582>
  1015f4:	000015b7          	lui	a1,0x1
  1015f8:	00001637          	lui	a2,0x1
  1015fc:	00000097          	auipc	ra,0x0
  101600:	808080e7          	jalr	-2040(ra) # 100e04 <s_printf>
  101604:	00001637          	lui	a2,0x1
               (unsigned)MAX_LEN, (unsigned)MAX_LEN);
        len = MAX_LEN;
    }

    hexdump((const void *)addr, len, addr);
  101608:	00040513          	mv	a0,s0
  10160c:	00060593          	mv	a1,a2
  101610:	00040613          	mv	a2,s0
  101614:	00c12083          	lw	ra,12(sp)
  101618:	00812403          	lw	s0,8(sp)
  10161c:	01010113          	addi	sp,sp,16
  101620:	00000317          	auipc	t1,0x0
  101624:	b7430067          	jr	-1164(t1) # 101194 <hexdump>

00101628 <sd_read_sector>:
}

// -------------------------------------------------------
int sd_read_sector(uint32_t sector, uint8_t *buf)
{
    return sd_read_once(sector, buf);
  101628:	00000317          	auipc	t1,0x0
  10162c:	00830067          	jr	8(t1) # 101630 <sd_read_once>

00101630 <sd_read_once>:
{
  101630:	10006637          	lui	a2,0x10006
  101634:	00400693          	li	a3,4
    PSC_SD_IF_CTRL = 0x04;
  101638:	00d62423          	sw	a3,8(a2) # 10006008 <_stack_top+0xfefa048>
  10163c:	f9c00693          	li	a3,-100
    while (n--) {
  101640:	00168693          	addi	a3,a3,1
        __asm__ __volatile__("nop");
  101644:	00000013          	nop
    while (n--) {
  101648:	fe069ce3          	bnez	a3,101640 <sd_read_once+0x10>
    if ((PSC_SD_IF_CTRL & 0x04) == 0x00) {
  10164c:	00862683          	lw	a3,8(a2)
  101650:	0046f693          	andi	a3,a3,4
  101654:	00069663          	bnez	a3,101660 <sd_read_once+0x30>
  101658:	00100693          	li	a3,1
        PSC_SD_IF_CTRL = 0x01;
  10165c:	00d62423          	sw	a3,8(a2)
  101660:	ffff46b7          	lui	a3,0xffff4
  101664:	cb068693          	addi	a3,a3,-848 # ffff3cb0 <_stack_top+0xffee7cf0>
    while (PSC_SD_IF_CTRL & 0x02) {
  101668:	00862703          	lw	a4,8(a2)
  10166c:	00277713          	andi	a4,a4,2
  101670:	00070a63          	beqz	a4,101684 <sd_read_once+0x54>
        if (--timeout == 0) return -1;
  101674:	00168693          	addi	a3,a3,1
  101678:	fe0698e3          	bnez	a3,101668 <sd_read_once+0x38>
  10167c:	fff00513          	li	a0,-1
}
  101680:	00008067          	ret
  101684:	f9c00693          	li	a3,-100
    while (n--) {
  101688:	00168693          	addi	a3,a3,1
        __asm__ __volatile__("nop");
  10168c:	00000013          	nop
  101690:	fe069ce3          	bnez	a3,101688 <sd_read_once+0x58>
    PSC_SD_SECTOR = sd_sector_address;
  101694:	00a62223          	sw	a0,4(a2)
  101698:	00200513          	li	a0,2
    PSC_SD_IF_CTRL = 0x02;
  10169c:	00a62423          	sw	a0,8(a2)
  1016a0:	f9c00513          	li	a0,-100
    while (n--) {
  1016a4:	00150513          	addi	a0,a0,1
        __asm__ __volatile__("nop");
  1016a8:	00000013          	nop
  1016ac:	fe051ce3          	bnez	a0,1016a4 <sd_read_once+0x74>
  1016b0:	ffff4537          	lui	a0,0xffff4
  1016b4:	cb050513          	addi	a0,a0,-848 # ffff3cb0 <_stack_top+0xffee7cf0>
    while ((PSC_SD_IF_CTRL & 0x04) == 0) {
  1016b8:	00862683          	lw	a3,8(a2)
  1016bc:	0046f693          	andi	a3,a3,4
  1016c0:	00069a63          	bnez	a3,1016d4 <sd_read_once+0xa4>
        if (--timeout == 0) return -2;
  1016c4:	00150513          	addi	a0,a0,1
  1016c8:	fe0518e3          	bnez	a0,1016b8 <sd_read_once+0x88>
  1016cc:	ffe00513          	li	a0,-2
}
  1016d0:	00008067          	ret
  1016d4:	00000693          	li	a3,0
        __asm__ __volatile__("nop");
  1016d8:	00000013          	nop
  1016dc:	00000013          	nop
  1016e0:	00000013          	nop
  1016e4:	00000013          	nop
  1016e8:	00000013          	nop
  1016ec:	00000013          	nop
  1016f0:	00000013          	nop
  1016f4:	00000013          	nop
  1016f8:	00000013          	nop
  1016fc:	00000013          	nop
  101700:	00000013          	nop
  101704:	00000013          	nop
  101708:	00000013          	nop
  10170c:	00000013          	nop
  101710:	00000013          	nop
  101714:	00000013          	nop
  101718:	00000013          	nop
  10171c:	00000013          	nop
  101720:	00000013          	nop
  101724:	00000013          	nop
  101728:	00000013          	nop
  10172c:	00000013          	nop
  101730:	00000013          	nop
  101734:	00000013          	nop
  101738:	00000013          	nop
  10173c:	00000013          	nop
  101740:	00000013          	nop
  101744:	00000013          	nop
  101748:	00000013          	nop
  10174c:	00000013          	nop
  101750:	00000013          	nop
  101754:	00000013          	nop
  101758:	00000013          	nop
  10175c:	00000013          	nop
  101760:	00000013          	nop
  101764:	00000013          	nop
  101768:	00000013          	nop
  10176c:	00000013          	nop
  101770:	00000013          	nop
  101774:	00000013          	nop
  101778:	00000013          	nop
  10177c:	00000013          	nop
  101780:	00000013          	nop
  101784:	00000013          	nop
  101788:	00000013          	nop
  10178c:	00000013          	nop
  101790:	00000013          	nop
  101794:	00000013          	nop
  101798:	00000013          	nop
  10179c:	00000013          	nop
  1017a0:	ffff4537          	lui	a0,0xffff4
  1017a4:	10006737          	lui	a4,0x10006
  1017a8:	cb050793          	addi	a5,a0,-848 # ffff3cb0 <_stack_top+0xffee7cf0>
  1017ac:	20000813          	li	a6,512
  1017b0:	00078513          	mv	a0,a5
        while (PSC_SD_IF_CTRL & (1 << 3)) {
  1017b4:	00862883          	lw	a7,8(a2)
  1017b8:	0088f893          	andi	a7,a7,8
  1017bc:	00088863          	beqz	a7,1017cc <sd_read_once+0x19c>
            if (--timeout == 0) return -3;
  1017c0:	00150513          	addi	a0,a0,1
  1017c4:	fe0518e3          	bnez	a0,1017b4 <sd_read_once+0x184>
  1017c8:	0200006f          	j	1017e8 <sd_read_once+0x1b8>
  1017cc:	00000513          	li	a0,0
        buf[i] = (unsigned char)(PSC_IF_DATA & 0xFF);
  1017d0:	00072883          	lw	a7,0(a4) # 10006000 <_stack_top+0xfefa040>
  1017d4:	00d582b3          	add	t0,a1,a3
    for (int i = 0; i < 512; i++) {
  1017d8:	00168693          	addi	a3,a3,1
        buf[i] = (unsigned char)(PSC_IF_DATA & 0xFF);
  1017dc:	01128023          	sb	a7,0(t0)
    for (int i = 0; i < 512; i++) {
  1017e0:	fd0698e3          	bne	a3,a6,1017b0 <sd_read_once+0x180>
}
  1017e4:	00008067          	ret
  1017e8:	ffd00513          	li	a0,-3
  1017ec:	00008067          	ret

001017f0 <sd_write_sector>:
}

// -------------------------------------------------------
int sd_write_sector(uint32_t sector, uint8_t *buf)
{
  1017f0:	de010113          	addi	sp,sp,-544
  1017f4:	20112e23          	sw	ra,540(sp)
  1017f8:	20812c23          	sw	s0,536(sp)
  1017fc:	20912a23          	sw	s1,532(sp)
  101800:	21212823          	sw	s2,528(sp)
  101804:	21312623          	sw	s3,524(sp)
  101808:	21412423          	sw	s4,520(sp)
  10180c:	00058413          	mv	s0,a1
  101810:	00050493          	mv	s1,a0
    const int retry_max = 3;

    for (int retry = 0; retry < retry_max; retry++) {

        if (sd_write_once(sector, buf) != 0) {
  101814:	00000097          	auipc	ra,0x0
  101818:	22c080e7          	jalr	556(ra) # 101a40 <sd_write_once>
  10181c:	00050e63          	beqz	a0,101838 <sd_write_sector+0x48>
            s_printf("WRITE FAIL retry=%d\n", retry);
  101820:	00103537          	lui	a0,0x103
  101824:	30b50513          	addi	a0,a0,779 # 10330b <print_hex8.HEX+0x11>
  101828:	00000593          	li	a1,0
  10182c:	fffff097          	auipc	ra,0xfffff
  101830:	5d8080e7          	jalr	1496(ra) # 100e04 <s_printf>
            continue;
  101834:	0880006f          	j	1018bc <sd_write_sector+0xcc>
    return sd_read_once(sector, buf);
  101838:	00810593          	addi	a1,sp,8
  10183c:	00810993          	addi	s3,sp,8
  101840:	00048513          	mv	a0,s1
  101844:	00000097          	auipc	ra,0x0
  101848:	dec080e7          	jalr	-532(ra) # 101630 <sd_read_once>
        }

        uint8_t verify[512];

        if (sd_read_sector(sector, verify) != 0) {
  10184c:	00050c63          	beqz	a0,101864 <sd_write_sector+0x74>
            s_printf("VERIFY READ ERROR\n");
  101850:	00103537          	lui	a0,0x103
  101854:	32050513          	addi	a0,a0,800 # 103320 <print_hex8.HEX+0x26>
  101858:	fffff097          	auipc	ra,0xfffff
  10185c:	5ac080e7          	jalr	1452(ra) # 100e04 <s_printf>
  101860:	05c0006f          	j	1018bc <sd_write_sector+0xcc>
  101864:	e0000593          	li	a1,-512
  101868:	00040a13          	mv	s4,s0
        }

        bool ok = true;

        for (int i = 0; i < 512; i++) {
            if (verify[i] != buf[i]) {
  10186c:	0009c903          	lbu	s2,0(s3)
  101870:	000a4603          	lbu	a2,0(s4)
  101874:	00c91c63          	bne	s2,a2,10188c <sd_write_sector+0x9c>
        for (int i = 0; i < 512; i++) {
  101878:	fff50513          	addi	a0,a0,-1
  10187c:	001a0a13          	addi	s4,s4,1
  101880:	00198993          	addi	s3,s3,1
  101884:	feb514e3          	bne	a0,a1,10186c <sd_write_sector+0x7c>
  101888:	15c0006f          	j	1019e4 <sd_write_sector+0x1f4>
                s_printf("VERIFY ERROR sector=%x byte=%d\n", sector, i);
  10188c:	40a00633          	neg	a2,a0
  101890:	00103537          	lui	a0,0x103
  101894:	33350513          	addi	a0,a0,819 # 103333 <print_hex8.HEX+0x39>
  101898:	00048593          	mv	a1,s1
  10189c:	fffff097          	auipc	ra,0xfffff
  1018a0:	568080e7          	jalr	1384(ra) # 100e04 <s_printf>
                s_printf("WRITE=%x READ=%x\n", buf[i], verify[i]);
  1018a4:	000a4583          	lbu	a1,0(s4)
  1018a8:	00103537          	lui	a0,0x103
  1018ac:	35350513          	addi	a0,a0,851 # 103353 <print_hex8.HEX+0x59>
  1018b0:	00090613          	mv	a2,s2
  1018b4:	fffff097          	auipc	ra,0xfffff
  1018b8:	550080e7          	jalr	1360(ra) # 100e04 <s_printf>
        if (sd_write_once(sector, buf) != 0) {
  1018bc:	00048513          	mv	a0,s1
  1018c0:	00040593          	mv	a1,s0
  1018c4:	00000097          	auipc	ra,0x0
  1018c8:	17c080e7          	jalr	380(ra) # 101a40 <sd_write_once>
  1018cc:	00050e63          	beqz	a0,1018e8 <sd_write_sector+0xf8>
            s_printf("WRITE FAIL retry=%d\n", retry);
  1018d0:	00103537          	lui	a0,0x103
  1018d4:	30b50513          	addi	a0,a0,779 # 10330b <print_hex8.HEX+0x11>
  1018d8:	00100593          	li	a1,1
  1018dc:	fffff097          	auipc	ra,0xfffff
  1018e0:	528080e7          	jalr	1320(ra) # 100e04 <s_printf>
            continue;
  1018e4:	0880006f          	j	10196c <sd_write_sector+0x17c>
    return sd_read_once(sector, buf);
  1018e8:	00810593          	addi	a1,sp,8
  1018ec:	00810993          	addi	s3,sp,8
  1018f0:	00048513          	mv	a0,s1
  1018f4:	00000097          	auipc	ra,0x0
  1018f8:	d3c080e7          	jalr	-708(ra) # 101630 <sd_read_once>
        if (sd_read_sector(sector, verify) != 0) {
  1018fc:	00050c63          	beqz	a0,101914 <sd_write_sector+0x124>
            s_printf("VERIFY READ ERROR\n");
  101900:	00103537          	lui	a0,0x103
  101904:	32050513          	addi	a0,a0,800 # 103320 <print_hex8.HEX+0x26>
  101908:	fffff097          	auipc	ra,0xfffff
  10190c:	4fc080e7          	jalr	1276(ra) # 100e04 <s_printf>
            continue;
  101910:	05c0006f          	j	10196c <sd_write_sector+0x17c>
  101914:	e0000593          	li	a1,-512
  101918:	00040a13          	mv	s4,s0
            if (verify[i] != buf[i]) {
  10191c:	0009c903          	lbu	s2,0(s3)
  101920:	000a4603          	lbu	a2,0(s4)
  101924:	00c91c63          	bne	s2,a2,10193c <sd_write_sector+0x14c>
        for (int i = 0; i < 512; i++) {
  101928:	fff50513          	addi	a0,a0,-1
  10192c:	001a0a13          	addi	s4,s4,1
  101930:	00198993          	addi	s3,s3,1
  101934:	feb514e3          	bne	a0,a1,10191c <sd_write_sector+0x12c>
  101938:	0ac0006f          	j	1019e4 <sd_write_sector+0x1f4>
                s_printf("VERIFY ERROR sector=%x byte=%d\n", sector, i);
  10193c:	40a00633          	neg	a2,a0
  101940:	00103537          	lui	a0,0x103
  101944:	33350513          	addi	a0,a0,819 # 103333 <print_hex8.HEX+0x39>
  101948:	00048593          	mv	a1,s1
  10194c:	fffff097          	auipc	ra,0xfffff
  101950:	4b8080e7          	jalr	1208(ra) # 100e04 <s_printf>
                s_printf("WRITE=%x READ=%x\n", buf[i], verify[i]);
  101954:	000a4583          	lbu	a1,0(s4)
  101958:	00103537          	lui	a0,0x103
  10195c:	35350513          	addi	a0,a0,851 # 103353 <print_hex8.HEX+0x59>
  101960:	00090613          	mv	a2,s2
  101964:	fffff097          	auipc	ra,0xfffff
  101968:	4a0080e7          	jalr	1184(ra) # 100e04 <s_printf>
        if (sd_write_once(sector, buf) != 0) {
  10196c:	00048513          	mv	a0,s1
  101970:	00040593          	mv	a1,s0
  101974:	00000097          	auipc	ra,0x0
  101978:	0cc080e7          	jalr	204(ra) # 101a40 <sd_write_once>
  10197c:	00050e63          	beqz	a0,101998 <sd_write_sector+0x1a8>
            s_printf("WRITE FAIL retry=%d\n", retry);
  101980:	00103537          	lui	a0,0x103
  101984:	30b50513          	addi	a0,a0,779 # 10330b <print_hex8.HEX+0x11>
  101988:	00200593          	li	a1,2
  10198c:	fffff097          	auipc	ra,0xfffff
  101990:	478080e7          	jalr	1144(ra) # 100e04 <s_printf>
  101994:	0880006f          	j	101a1c <sd_write_sector+0x22c>
    return sd_read_once(sector, buf);
  101998:	00810593          	addi	a1,sp,8
  10199c:	00810993          	addi	s3,sp,8
  1019a0:	00048513          	mv	a0,s1
  1019a4:	00000097          	auipc	ra,0x0
  1019a8:	c8c080e7          	jalr	-884(ra) # 101630 <sd_read_once>
        if (sd_read_sector(sector, verify) != 0) {
  1019ac:	00050c63          	beqz	a0,1019c4 <sd_write_sector+0x1d4>
            s_printf("VERIFY READ ERROR\n");
  1019b0:	00103537          	lui	a0,0x103
  1019b4:	32050513          	addi	a0,a0,800 # 103320 <print_hex8.HEX+0x26>
  1019b8:	fffff097          	auipc	ra,0xfffff
  1019bc:	44c080e7          	jalr	1100(ra) # 100e04 <s_printf>
  1019c0:	05c0006f          	j	101a1c <sd_write_sector+0x22c>
  1019c4:	e0000593          	li	a1,-512
            if (verify[i] != buf[i]) {
  1019c8:	0009c903          	lbu	s2,0(s3)
  1019cc:	00044603          	lbu	a2,0(s0)
  1019d0:	00c91e63          	bne	s2,a2,1019ec <sd_write_sector+0x1fc>
        for (int i = 0; i < 512; i++) {
  1019d4:	fff50513          	addi	a0,a0,-1
  1019d8:	00140413          	addi	s0,s0,1
  1019dc:	00198993          	addi	s3,s3,1
  1019e0:	feb514e3          	bne	a0,a1,1019c8 <sd_write_sector+0x1d8>
  1019e4:	00000513          	li	a0,0
  1019e8:	0380006f          	j	101a20 <sd_write_sector+0x230>
                s_printf("VERIFY ERROR sector=%x byte=%d\n", sector, i);
  1019ec:	40a00633          	neg	a2,a0
  1019f0:	00103537          	lui	a0,0x103
  1019f4:	33350513          	addi	a0,a0,819 # 103333 <print_hex8.HEX+0x39>
  1019f8:	00048593          	mv	a1,s1
  1019fc:	fffff097          	auipc	ra,0xfffff
  101a00:	408080e7          	jalr	1032(ra) # 100e04 <s_printf>
                s_printf("WRITE=%x READ=%x\n", buf[i], verify[i]);
  101a04:	00044583          	lbu	a1,0(s0)
  101a08:	00103537          	lui	a0,0x103
  101a0c:	35350513          	addi	a0,a0,851 # 103353 <print_hex8.HEX+0x59>
  101a10:	00090613          	mv	a2,s2
  101a14:	fffff097          	auipc	ra,0xfffff
  101a18:	3f0080e7          	jalr	1008(ra) # 100e04 <s_printf>
  101a1c:	fff00513          	li	a0,-1
        if (ok)
            return 0;
    }

    return -1;
}
  101a20:	21c12083          	lw	ra,540(sp)
  101a24:	21812403          	lw	s0,536(sp)
  101a28:	21412483          	lw	s1,532(sp)
  101a2c:	21012903          	lw	s2,528(sp)
  101a30:	20c12983          	lw	s3,524(sp)
  101a34:	20812a03          	lw	s4,520(sp)
  101a38:	22010113          	addi	sp,sp,544
  101a3c:	00008067          	ret

00101a40 <sd_write_once>:
{
  101a40:	10006637          	lui	a2,0x10006
  101a44:	00400693          	li	a3,4
    PSC_SD_IF_CTRL = 0x04;
  101a48:	00d62423          	sw	a3,8(a2) # 10006008 <_stack_top+0xfefa048>
  101a4c:	f9c00693          	li	a3,-100
    while (n--) {
  101a50:	00168693          	addi	a3,a3,1
        __asm__ __volatile__("nop");
  101a54:	00000013          	nop
    while (n--) {
  101a58:	fe069ce3          	bnez	a3,101a50 <sd_write_once+0x10>
    for (int i = 0; i < 512; i++) {
  101a5c:	20058693          	addi	a3,a1,512 # 1200 <_start-0xfee00>
  101a60:	10006737          	lui	a4,0x10006
        PSC_IF_DATA = buf[i] & 0xFF;
  101a64:	0005c783          	lbu	a5,0(a1)
    for (int i = 0; i < 512; i++) {
  101a68:	00158593          	addi	a1,a1,1
        PSC_IF_DATA = buf[i] & 0xFF;
  101a6c:	00f72023          	sw	a5,0(a4) # 10006000 <_stack_top+0xfefa040>
    for (int i = 0; i < 512; i++) {
  101a70:	fed59ae3          	bne	a1,a3,101a64 <sd_write_once+0x24>
    if ((PSC_SD_IF_CTRL & 0x04) == 0x00) {
  101a74:	00862583          	lw	a1,8(a2)
  101a78:	0045f593          	andi	a1,a1,4
  101a7c:	00059663          	bnez	a1,101a88 <sd_write_once+0x48>
  101a80:	00100593          	li	a1,1
        PSC_SD_IF_CTRL = 0x01;
  101a84:	00b62423          	sw	a1,8(a2)
  101a88:	ffff45b7          	lui	a1,0xffff4
  101a8c:	cb058593          	addi	a1,a1,-848 # ffff3cb0 <_stack_top+0xffee7cf0>
    while (PSC_SD_IF_CTRL & 0x02) {
  101a90:	00862683          	lw	a3,8(a2)
  101a94:	0026f693          	andi	a3,a3,2
  101a98:	00068a63          	beqz	a3,101aac <sd_write_once+0x6c>
        if (--timeout == 0) return -1;
  101a9c:	00158593          	addi	a1,a1,1
  101aa0:	fe0598e3          	bnez	a1,101a90 <sd_write_once+0x50>
  101aa4:	fff00513          	li	a0,-1
}
  101aa8:	00008067          	ret
  101aac:	f9c00593          	li	a1,-100
    while (n--) {
  101ab0:	00158593          	addi	a1,a1,1
        __asm__ __volatile__("nop");
  101ab4:	00000013          	nop
  101ab8:	fe059ce3          	bnez	a1,101ab0 <sd_write_once+0x70>
    PSC_SD_SECTOR = sd_sector_address;
  101abc:	00a62223          	sw	a0,4(a2)
  101ac0:	01000513          	li	a0,16
    PSC_SD_IF_CTRL = 0x10;
  101ac4:	00a62423          	sw	a0,8(a2)
  101ac8:	f9c00513          	li	a0,-100
    while (n--) {
  101acc:	00150513          	addi	a0,a0,1
        __asm__ __volatile__("nop");
  101ad0:	00000013          	nop
  101ad4:	fe051ce3          	bnez	a0,101acc <sd_write_once+0x8c>
  101ad8:	ffff4537          	lui	a0,0xffff4
  101adc:	cb050513          	addi	a0,a0,-848 # ffff3cb0 <_stack_top+0xffee7cf0>
    while ((PSC_SD_IF_CTRL & 0x04) == 0) {
  101ae0:	00862583          	lw	a1,8(a2)
  101ae4:	0045f593          	andi	a1,a1,4
  101ae8:	00059a63          	bnez	a1,101afc <sd_write_once+0xbc>
        if (--timeout == 0) return -2;
  101aec:	00150513          	addi	a0,a0,1
  101af0:	fe0518e3          	bnez	a0,101ae0 <sd_write_once+0xa0>
  101af4:	ffe00513          	li	a0,-2
}
  101af8:	00008067          	ret
  101afc:	00000513          	li	a0,0
        __asm__ __volatile__("nop");
  101b00:	00000013          	nop
  101b04:	00000013          	nop
  101b08:	00000013          	nop
  101b0c:	00000013          	nop
  101b10:	00000013          	nop
  101b14:	00000013          	nop
  101b18:	00000013          	nop
  101b1c:	00000013          	nop
  101b20:	00000013          	nop
  101b24:	00000013          	nop
  101b28:	00000013          	nop
  101b2c:	00000013          	nop
  101b30:	00000013          	nop
  101b34:	00000013          	nop
  101b38:	00000013          	nop
  101b3c:	00000013          	nop
  101b40:	00000013          	nop
  101b44:	00000013          	nop
  101b48:	00000013          	nop
  101b4c:	00000013          	nop
  101b50:	00000013          	nop
  101b54:	00000013          	nop
  101b58:	00000013          	nop
  101b5c:	00000013          	nop
  101b60:	00000013          	nop
  101b64:	00000013          	nop
  101b68:	00000013          	nop
  101b6c:	00000013          	nop
  101b70:	00000013          	nop
  101b74:	00000013          	nop
  101b78:	00000013          	nop
  101b7c:	00000013          	nop
  101b80:	00000013          	nop
  101b84:	00000013          	nop
  101b88:	00000013          	nop
  101b8c:	00000013          	nop
  101b90:	00000013          	nop
  101b94:	00000013          	nop
  101b98:	00000013          	nop
  101b9c:	00000013          	nop
  101ba0:	00000013          	nop
  101ba4:	00000013          	nop
  101ba8:	00000013          	nop
  101bac:	00000013          	nop
  101bb0:	00000013          	nop
  101bb4:	00000013          	nop
  101bb8:	00000013          	nop
  101bbc:	00000013          	nop
  101bc0:	00000013          	nop
  101bc4:	00000013          	nop
}
  101bc8:	00008067          	ret

00101bcc <s_call_sdcard_read_api>:

// -------------------------------------------------------
// SDカードREAD実行関数
void s_call_sdcard_read_api(uint32_t sd_sector_address)
{
  101bcc:	dd010113          	addi	sp,sp,-560
  101bd0:	22112623          	sw	ra,556(sp)
  101bd4:	22812423          	sw	s0,552(sp)
  101bd8:	22912223          	sw	s1,548(sp)
  101bdc:	23212023          	sw	s2,544(sp)
  101be0:	21312e23          	sw	s3,540(sp)
  101be4:	21412c23          	sw	s4,536(sp)
  101be8:	21512a23          	sw	s5,532(sp)
  101bec:	21612823          	sw	s6,528(sp)
  101bf0:	21712623          	sw	s7,524(sp)
  101bf4:	00050493          	mv	s1,a0
  101bf8:	00000413          	li	s0,0
  101bfc:	00001537          	lui	a0,0x1
    unsigned char buf[512];

    int retry_max = 3;
    int success = 0;

    for (int retry = 0; retry < retry_max; retry++) {
  101c00:	20c10a13          	addi	s4,sp,524
  101c04:	10006ab7          	lui	s5,0x10006
  101c08:	00103937          	lui	s2,0x103
  101c0c:	38c90913          	addi	s2,s2,908 # 10338c <print_hex8.HEX+0x92>
  101c10:	00300b13          	li	s6,3
  101c14:	02150b93          	addi	s7,a0,33 # 1021 <_start-0xfefdf>
  101c18:	001039b7          	lui	s3,0x103
  101c1c:	36598993          	addi	s3,s3,869 # 103365 <print_hex8.HEX+0x6b>
  101c20:	01c0006f          	j	101c3c <s_call_sdcard_read_api+0x70>

        if (sd_read_once(sd_sector_address, buf) != 0) {
            s_printf("READ FAIL retry=%d\n", retry);
  101c24:	00098513          	mv	a0,s3
  101c28:	00040593          	mv	a1,s0
  101c2c:	fffff097          	auipc	ra,0xfffff
  101c30:	1d8080e7          	jalr	472(ra) # 100e04 <s_printf>
    for (int retry = 0; retry < retry_max; retry++) {
  101c34:	00140413          	addi	s0,s0,1
  101c38:	11640063          	beq	s0,s6,101d38 <s_call_sdcard_read_api+0x16c>
        if (sd_read_once(sd_sector_address, buf) != 0) {
  101c3c:	00c10593          	addi	a1,sp,12
  101c40:	00048513          	mv	a0,s1
  101c44:	00000097          	auipc	ra,0x0
  101c48:	9ec080e7          	jalr	-1556(ra) # 101630 <sd_read_once>
  101c4c:	fc051ce3          	bnez	a0,101c24 <s_call_sdcard_read_api+0x58>
  101c50:	00000593          	li	a1,0
            continue;
        }

        // CRC HW
        uint32_t ctrl = PSC_SD_IF_CTRL;
  101c54:	008aa683          	lw	a3,8(s5) # 10006008 <_stack_top+0xfefa048>
  101c58:	00c10513          	addi	a0,sp,12
        crc ^= (uint16_t)buf[i] << 8;
  101c5c:	00054603          	lbu	a2,0(a0)
    for (int i = 0; i < 512; i++) {
  101c60:	00150513          	addi	a0,a0,1
        crc ^= (uint16_t)buf[i] << 8;
  101c64:	00861613          	slli	a2,a2,0x8
  101c68:	00b645b3          	xor	a1,a2,a1
  101c6c:	01059613          	slli	a2,a1,0x10
            crc = (crc & 0x8000) ? (crc << 1) ^ 0x1021 : (crc << 1);
  101c70:	01159713          	slli	a4,a1,0x11
  101c74:	00159793          	slli	a5,a1,0x1
  101c78:	01259813          	slli	a6,a1,0x12
  101c7c:	01359593          	slli	a1,a1,0x13
  101c80:	41f65613          	srai	a2,a2,0x1f
  101c84:	41f75713          	srai	a4,a4,0x1f
  101c88:	41f85813          	srai	a6,a6,0x1f
  101c8c:	41f5d593          	srai	a1,a1,0x1f
  101c90:	01767633          	and	a2,a2,s7
  101c94:	01777733          	and	a4,a4,s7
  101c98:	01787833          	and	a6,a6,s7
  101c9c:	0175f5b3          	and	a1,a1,s7
  101ca0:	00c7c633          	xor	a2,a5,a2
  101ca4:	00161793          	slli	a5,a2,0x1
  101ca8:	01361613          	slli	a2,a2,0x13
  101cac:	00e7c733          	xor	a4,a5,a4
  101cb0:	41f65613          	srai	a2,a2,0x1f
  101cb4:	00171793          	slli	a5,a4,0x1
  101cb8:	01371713          	slli	a4,a4,0x13
  101cbc:	01767633          	and	a2,a2,s7
  101cc0:	0107c7b3          	xor	a5,a5,a6
  101cc4:	41f75713          	srai	a4,a4,0x1f
  101cc8:	00361613          	slli	a2,a2,0x3
  101ccc:	00179813          	slli	a6,a5,0x1
  101cd0:	01379793          	slli	a5,a5,0x13
  101cd4:	01777733          	and	a4,a4,s7
  101cd8:	00b845b3          	xor	a1,a6,a1
  101cdc:	41f7d793          	srai	a5,a5,0x1f
  101ce0:	00271713          	slli	a4,a4,0x2
  101ce4:	01359813          	slli	a6,a1,0x13
  101ce8:	0177f7b3          	and	a5,a5,s7
  101cec:	00459593          	slli	a1,a1,0x4
  101cf0:	00e64633          	xor	a2,a2,a4
  101cf4:	00c5c5b3          	xor	a1,a1,a2
  101cf8:	00179793          	slli	a5,a5,0x1
  101cfc:	41f85613          	srai	a2,a6,0x1f
  101d00:	00f5c5b3          	xor	a1,a1,a5
  101d04:	01767633          	and	a2,a2,s7
  101d08:	00c5c5b3          	xor	a1,a1,a2
    for (int i = 0; i < 512; i++) {
  101d0c:	f54518e3          	bne	a0,s4,101c5c <s_call_sdcard_read_api+0x90>
        uint16_t crc_hw = ((ctrl >> 24) & 0xFF) << 8 |
  101d10:	0106d693          	srli	a3,a3,0x10
                          ((ctrl >> 16) & 0xFF);

        // CRC SW
        uint16_t crc = sd_crc16(buf);

        if (crc == crc_hw) {
  101d14:	01059593          	slli	a1,a1,0x10
  101d18:	0105d613          	srli	a2,a1,0x10
  101d1c:	02c68863          	beq	a3,a2,101d4c <s_call_sdcard_read_api+0x180>
            s_printf("CRC OK (retry=%d)\n", retry);
            success = 1;
            break;
        } else {
            s_printf("CRC NG retry=%d (calc=%x hw=%x)\n",
  101d20:	00090513          	mv	a0,s2
  101d24:	00040593          	mv	a1,s0
  101d28:	fffff097          	auipc	ra,0xfffff
  101d2c:	0dc080e7          	jalr	220(ra) # 100e04 <s_printf>
    for (int retry = 0; retry < retry_max; retry++) {
  101d30:	00140413          	addi	s0,s0,1
  101d34:	f16414e3          	bne	s0,s6,101c3c <s_call_sdcard_read_api+0x70>
                     retry, crc, crc_hw);
        }
    }

    if (!success) {
        s_printf("CRC FAILED (final)\n");
  101d38:	00103537          	lui	a0,0x103
  101d3c:	3ad50513          	addi	a0,a0,941 # 1033ad <print_hex8.HEX+0xb3>
  101d40:	fffff097          	auipc	ra,0xfffff
  101d44:	0c4080e7          	jalr	196(ra) # 100e04 <s_printf>
  101d48:	0180006f          	j	101d60 <s_call_sdcard_read_api+0x194>
            s_printf("CRC OK (retry=%d)\n", retry);
  101d4c:	00103537          	lui	a0,0x103
  101d50:	37950513          	addi	a0,a0,889 # 103379 <print_hex8.HEX+0x7f>
  101d54:	00040593          	mv	a1,s0
  101d58:	fffff097          	auipc	ra,0xfffff
  101d5c:	0ac080e7          	jalr	172(ra) # 100e04 <s_printf>
  101d60:	00000413          	li	s0,0
  101d64:	00c10493          	addi	s1,sp,12
  101d68:	00103937          	lui	s2,0x103
  101d6c:	3c190913          	addi	s2,s2,961 # 1033c1 <print_hex8.HEX+0xc7>
  101d70:	00f00993          	li	s3,15
  101d74:	20000a13          	li	s4,512
  101d78:	00c0006f          	j	101d84 <s_call_sdcard_read_api+0x1b8>
    }

    // ---- dump（常に実行）----
    const char hex[] = "0123456789ABCDEF";

    for (int i = 0; i < 512; i++) {
  101d7c:	00140413          	addi	s0,s0,1
  101d80:	05440c63          	beq	s0,s4,101dd8 <s_call_sdcard_read_api+0x20c>
        unsigned char d = buf[i];
  101d84:	00848533          	add	a0,s1,s0
  101d88:	00054a83          	lbu	s5,0(a0)
        putchar(hex[(d >> 4) & 0xF]);
  101d8c:	004ad513          	srli	a0,s5,0x4
  101d90:	00a90533          	add	a0,s2,a0
  101d94:	00054503          	lbu	a0,0(a0)
  101d98:	ffffe097          	auipc	ra,0xffffe
  101d9c:	27c080e7          	jalr	636(ra) # 100014 <putchar>
        putchar(hex[d & 0xF]);
  101da0:	00faf513          	andi	a0,s5,15
  101da4:	00a90533          	add	a0,s2,a0
  101da8:	00054503          	lbu	a0,0(a0)
  101dac:	ffffe097          	auipc	ra,0xffffe
  101db0:	268080e7          	jalr	616(ra) # 100014 <putchar>
        putchar(' ');
  101db4:	02000513          	li	a0,32
  101db8:	ffffe097          	auipc	ra,0xffffe
  101dbc:	25c080e7          	jalr	604(ra) # 100014 <putchar>
        if ((i & 15) == 15) putchar('\n');
  101dc0:	00f47513          	andi	a0,s0,15
  101dc4:	fb351ce3          	bne	a0,s3,101d7c <s_call_sdcard_read_api+0x1b0>
  101dc8:	00a00513          	li	a0,10
  101dcc:	ffffe097          	auipc	ra,0xffffe
  101dd0:	248080e7          	jalr	584(ra) # 100014 <putchar>
  101dd4:	fa9ff06f          	j	101d7c <s_call_sdcard_read_api+0x1b0>
    }
}
  101dd8:	22c12083          	lw	ra,556(sp)
  101ddc:	22812403          	lw	s0,552(sp)
  101de0:	22412483          	lw	s1,548(sp)
  101de4:	22012903          	lw	s2,544(sp)
  101de8:	21c12983          	lw	s3,540(sp)
  101dec:	21812a03          	lw	s4,536(sp)
  101df0:	21412a83          	lw	s5,532(sp)
  101df4:	21012b03          	lw	s6,528(sp)
  101df8:	20c12b83          	lw	s7,524(sp)
  101dfc:	23010113          	addi	sp,sp,560
  101e00:	00008067          	ret

00101e04 <s_call_sdcard_write_api>:
// SDカードWRITE実行関数
// -------------------------------------------------------
int s_call_sdcard_write_api(
    uint32_t sd_sector_address,
    const uint8_t *buf)
{
  101e04:	ff010113          	addi	sp,sp,-16
  101e08:	00112623          	sw	ra,12(sp)
  101e0c:	00812423          	sw	s0,8(sp)
  101e10:	00912223          	sw	s1,4(sp)
  101e14:	01212023          	sw	s2,0(sp)
  101e18:	00058493          	mv	s1,a1
  101e1c:	00050913          	mv	s2,a0
    s_printf("WRITE START\n");
  101e20:	00103537          	lui	a0,0x103
  101e24:	3d250513          	addi	a0,a0,978 # 1033d2 <print_hex8.HEX+0xd8>
  101e28:	fffff097          	auipc	ra,0xfffff
  101e2c:	fdc080e7          	jalr	-36(ra) # 100e04 <s_printf>

    const int retry_max = 3;

    for (int retry = 0; retry < retry_max; retry++) {

        if (sd_write_once(sd_sector_address, buf) == 0) {
  101e30:	00090513          	mv	a0,s2
  101e34:	00048593          	mv	a1,s1
  101e38:	00000097          	auipc	ra,0x0
  101e3c:	c08080e7          	jalr	-1016(ra) # 101a40 <sd_write_once>
  101e40:	00103437          	lui	s0,0x103
  101e44:	3df40413          	addi	s0,s0,991 # 1033df <print_hex8.HEX+0xe5>
  101e48:	06050c63          	beqz	a0,101ec0 <s_call_sdcard_write_api+0xbc>
            s_printf("WRITE END\n");
            return 0;
        }

        s_printf("WRITE FAIL retry=%d\n", retry);
  101e4c:	00103537          	lui	a0,0x103
  101e50:	30b50513          	addi	a0,a0,779 # 10330b <print_hex8.HEX+0x11>
  101e54:	00000593          	li	a1,0
  101e58:	fffff097          	auipc	ra,0xfffff
  101e5c:	fac080e7          	jalr	-84(ra) # 100e04 <s_printf>
        if (sd_write_once(sd_sector_address, buf) == 0) {
  101e60:	00090513          	mv	a0,s2
  101e64:	00048593          	mv	a1,s1
  101e68:	00000097          	auipc	ra,0x0
  101e6c:	bd8080e7          	jalr	-1064(ra) # 101a40 <sd_write_once>
  101e70:	04050863          	beqz	a0,101ec0 <s_call_sdcard_write_api+0xbc>
        s_printf("WRITE FAIL retry=%d\n", retry);
  101e74:	00103537          	lui	a0,0x103
  101e78:	30b50513          	addi	a0,a0,779 # 10330b <print_hex8.HEX+0x11>
  101e7c:	00100593          	li	a1,1
  101e80:	fffff097          	auipc	ra,0xfffff
  101e84:	f84080e7          	jalr	-124(ra) # 100e04 <s_printf>
        if (sd_write_once(sd_sector_address, buf) == 0) {
  101e88:	00090513          	mv	a0,s2
  101e8c:	00048593          	mv	a1,s1
  101e90:	00000097          	auipc	ra,0x0
  101e94:	bb0080e7          	jalr	-1104(ra) # 101a40 <sd_write_once>
  101e98:	02050463          	beqz	a0,101ec0 <s_call_sdcard_write_api+0xbc>
        s_printf("WRITE FAIL retry=%d\n", retry);
  101e9c:	00103537          	lui	a0,0x103
  101ea0:	30b50513          	addi	a0,a0,779 # 10330b <print_hex8.HEX+0x11>
  101ea4:	00200593          	li	a1,2
  101ea8:	fffff097          	auipc	ra,0xfffff
  101eac:	f5c080e7          	jalr	-164(ra) # 100e04 <s_printf>
  101eb0:	fff00493          	li	s1,-1
  101eb4:	00103437          	lui	s0,0x103
  101eb8:	3ea40413          	addi	s0,s0,1002 # 1033ea <print_hex8.HEX+0xf0>
  101ebc:	0080006f          	j	101ec4 <s_call_sdcard_write_api+0xc0>
  101ec0:	00000493          	li	s1,0
  101ec4:	00040513          	mv	a0,s0
  101ec8:	fffff097          	auipc	ra,0xfffff
  101ecc:	f3c080e7          	jalr	-196(ra) # 100e04 <s_printf>
    }

    s_printf("WRITE ERROR\n");

    return -1;
  101ed0:	00048513          	mv	a0,s1
  101ed4:	00c12083          	lw	ra,12(sp)
  101ed8:	00812403          	lw	s0,8(sp)
  101edc:	00412483          	lw	s1,4(sp)
  101ee0:	00012903          	lw	s2,0(sp)
  101ee4:	01010113          	addi	sp,sp,16
  101ee8:	00008067          	ret

00101eec <boot_fat32_cluster_to_lba>:

    return 1;
}

uint32_t boot_fat32_cluster_to_lba(uint32_t cluster)
{
  101eec:	ff010113          	addi	sp,sp,-16
  101ef0:	00112623          	sw	ra,12(sp)
  101ef4:	00812423          	sw	s0,8(sp)
    uint32_t lba;
    uint32_t n;

    //s_printf("FAT32: c2l enter\n");

    lba = g_data_begin_lba;
  101ef8:	001085b7          	lui	a1,0x108
  101efc:	ba05a403          	lw	s0,-1120(a1) # 107ba0 <g_data_begin_lba>
  101f00:	00100593          	li	a1,1

    if (cluster < 2u) {
  101f04:	00a5ec63          	bltu	a1,a0,101f1c <boot_fat32_cluster_to_lba+0x30>
        s_printf("FAT32: c2l bad\n");
  101f08:	00103537          	lui	a0,0x103
  101f0c:	3f750513          	addi	a0,a0,1015 # 1033f7 <print_hex8.HEX+0xfd>
  101f10:	fffff097          	auipc	ra,0xfffff
  101f14:	ef4080e7          	jalr	-268(ra) # 100e04 <s_printf>
        return lba;
  101f18:	01c0006f          	j	101f34 <boot_fat32_cluster_to_lba+0x48>
    }

    //s_printf("FAT32: c2l sub\n");

    n = cluster - 2u;
  101f1c:	ffe50513          	addi	a0,a0,-2

    //s_printf("FAT32: c2l loop\n");

    while (n > 0u) {
  101f20:	00050a63          	beqz	a0,101f34 <boot_fat32_cluster_to_lba+0x48>
  101f24:	001085b7          	lui	a1,0x108
  101f28:	ba45a583          	lw	a1,-1116(a1) # 107ba4 <g_sectors_per_cluster>
  101f2c:	02a58533          	mul	a0,a1,a0
  101f30:	00a40433          	add	s0,s0,a0
    }

    //s_printf("FAT32: c2l done\n");

    return lba;
}
  101f34:	00040513          	mv	a0,s0
  101f38:	00c12083          	lw	ra,12(sp)
  101f3c:	00812403          	lw	s0,8(sp)
  101f40:	01010113          	addi	sp,sp,16
  101f44:	00008067          	ret

00101f48 <boot_fat32_mount>:

int boot_fat32_mount(boot_sd_read_sector_fn read_sector)
{
  101f48:	fe010113          	addi	sp,sp,-32
  101f4c:	00112e23          	sw	ra,28(sp)
  101f50:	00812c23          	sw	s0,24(sp)
  101f54:	00912a23          	sw	s1,20(sp)
  101f58:	01212823          	sw	s2,16(sp)
  101f5c:	01312623          	sw	s3,12(sp)
  101f60:	01412423          	sw	s4,8(sp)
  101f64:	01512223          	sw	s5,4(sp)
  101f68:	00050493          	mv	s1,a0
    uint32_t bytes_per_sector;
    uint32_t reserved_sector_count;
    uint32_t fat_count;
    uint32_t fat_size;

    s_printf("FAT32: mount enter\n");
  101f6c:	00103537          	lui	a0,0x103
  101f70:	40750513          	addi	a0,a0,1031 # 103407 <print_hex8.HEX+0x10d>
  101f74:	fffff097          	auipc	ra,0xfffff
  101f78:	e90080e7          	jalr	-368(ra) # 100e04 <s_printf>

    g_read_sector = read_sector;
  101f7c:	00108937          	lui	s2,0x108
  101f80:	ba090913          	addi	s2,s2,-1120 # 107ba0 <g_data_begin_lba>
  101f84:	00992423          	sw	s1,8(s2)
  101f88:	fff00413          	li	s0,-1

    if (g_read_sector == 0) {
  101f8c:	02048c63          	beqz	s1,101fc4 <boot_fat32_mount+0x7c>
        s_printf("FAT32: read_sector null\n");
        return -1;
    }

    s_printf("FAT32: read LBA0\n");
  101f90:	00103537          	lui	a0,0x103
  101f94:	43450513          	addi	a0,a0,1076 # 103434 <print_hex8.HEX+0x13a>
  101f98:	fffff097          	auipc	ra,0xfffff
  101f9c:	e6c080e7          	jalr	-404(ra) # 100e04 <s_printf>

    if (g_read_sector(0, buf)) {
  101fa0:	00892603          	lw	a2,8(s2)
  101fa4:	01890493          	addi	s1,s2,24
  101fa8:	00000513          	li	a0,0
  101fac:	00048593          	mv	a1,s1
  101fb0:	000600e7          	jalr	a2
  101fb4:	04050463          	beqz	a0,101ffc <boot_fat32_mount+0xb4>
  101fb8:	00103537          	lui	a0,0x103
  101fbc:	44650513          	addi	a0,a0,1094 # 103446 <print_hex8.HEX+0x14c>
    if (fat_size == 0u) {
        s_printf("FAT32: bad fat_size\n");
        return -1;
    }

    if (g_root_cluster < 2u) {
  101fc0:	00c0006f          	j	101fcc <boot_fat32_mount+0x84>
  101fc4:	00103537          	lui	a0,0x103
  101fc8:	41b50513          	addi	a0,a0,1051 # 10341b <print_hex8.HEX+0x121>
  101fcc:	fffff097          	auipc	ra,0xfffff
  101fd0:	e38080e7          	jalr	-456(ra) # 100e04 <s_printf>
    }

    s_printf("FAT32: mount ok\n");

    return 0;
}
  101fd4:	00040513          	mv	a0,s0
  101fd8:	01c12083          	lw	ra,28(sp)
  101fdc:	01812403          	lw	s0,24(sp)
  101fe0:	01412483          	lw	s1,20(sp)
  101fe4:	01012903          	lw	s2,16(sp)
  101fe8:	00c12983          	lw	s3,12(sp)
  101fec:	00812a03          	lw	s4,8(sp)
  101ff0:	00412a83          	lw	s5,4(sp)
  101ff4:	02010113          	addi	sp,sp,32
  101ff8:	00008067          	ret
    s_printf("FAT32: read LBA0 ok\n");
  101ffc:	00103537          	lui	a0,0x103
  102000:	45f50513          	addi	a0,a0,1119 # 10345f <print_hex8.HEX+0x165>
  102004:	fffff097          	auipc	ra,0xfffff
  102008:	e00080e7          	jalr	-512(ra) # 100e04 <s_printf>
    if (b[510] != 0x55 || b[511] != 0xAA)
  10200c:	21694583          	lbu	a1,534(s2)
  102010:	05500613          	li	a2,85
  102014:	00103537          	lui	a0,0x103
  102018:	48950513          	addi	a0,a0,1161 # 103489 <print_hex8.HEX+0x18f>
  10201c:	fac598e3          	bne	a1,a2,101fcc <boot_fat32_mount+0x84>
  102020:	21794583          	lbu	a1,535(s2)
  102024:	0aa00613          	li	a2,170
  102028:	fac592e3          	bne	a1,a2,101fcc <boot_fat32_mount+0x84>
           ((uint16_t)p[1] << 8);
  10202c:	02494503          	lbu	a0,36(s2)
    return (uint16_t)p[0] |
  102030:	02394583          	lbu	a1,35(s2)
           ((uint16_t)p[1] << 8);
  102034:	00851513          	slli	a0,a0,0x8
    return (uint16_t)p[0] |
  102038:	00b56533          	or	a0,a0,a1
  10203c:	20000593          	li	a1,512
    if (rd16(&b[11]) != 512u)
  102040:	04b51863          	bne	a0,a1,102090 <boot_fat32_mount+0x148>
  102044:	02594503          	lbu	a0,37(s2)
  102048:	04050463          	beqz	a0,102090 <boot_fat32_mount+0x148>
    return (uint16_t)p[0] |
  10204c:	02694503          	lbu	a0,38(s2)
           ((uint16_t)p[1] << 8);
  102050:	02794583          	lbu	a1,39(s2)
    if (rd16(&b[14]) == 0)
  102054:	00a5e533          	or	a0,a1,a0
  102058:	02050c63          	beqz	a0,102090 <boot_fat32_mount+0x148>
  10205c:	02894503          	lbu	a0,40(s2)
  102060:	02050863          	beqz	a0,102090 <boot_fat32_mount+0x148>
    return ((uint32_t)p[0]) |
  102064:	03c94503          	lbu	a0,60(s2)
           ((uint32_t)p[1] << 8) |
  102068:	03d94583          	lbu	a1,61(s2)
           ((uint32_t)p[2] << 16) |
  10206c:	03e94603          	lbu	a2,62(s2)
           ((uint32_t)p[3] << 24);
  102070:	03f94683          	lbu	a3,63(s2)
    if (rd32(&b[36]) == 0)
  102074:	00a5e533          	or	a0,a1,a0
  102078:	00d66633          	or	a2,a2,a3
  10207c:	00c56533          	or	a0,a0,a2
  102080:	00050863          	beqz	a0,102090 <boot_fat32_mount+0x148>
           ((uint32_t)p[2] << 16) |
  102084:	04492503          	lw	a0,68(s2)
  102088:	00200593          	li	a1,2
    if (is_fat32_boot_sector(buf)) {
  10208c:	0ab57663          	bgeu	a0,a1,102138 <boot_fat32_mount+0x1f0>
           ((uint32_t)p[2] << 16) |
  102090:	1e094503          	lbu	a0,480(s2)
    return ((uint32_t)p[0]) |
  102094:	1de95583          	lhu	a1,478(s2)
           ((uint32_t)p[3] << 24);
  102098:	1e194603          	lbu	a2,481(s2)
           ((uint32_t)p[2] << 16) |
  10209c:	01051513          	slli	a0,a0,0x10
           ((uint32_t)p[1] << 8) |
  1020a0:	00a5e533          	or	a0,a1,a0
           ((uint32_t)p[3] << 24);
  1020a4:	01861613          	slli	a2,a2,0x18
           ((uint32_t)p[2] << 16) |
  1020a8:	00c56533          	or	a0,a0,a2
        g_part_lba = rd32(&buf[0x1C6]);
  1020ac:	00a92623          	sw	a0,12(s2)
        s_printf("FAT32: part ok\n");
  1020b0:	00103537          	lui	a0,0x103
  1020b4:	49d50513          	addi	a0,a0,1181 # 10349d <print_hex8.HEX+0x1a3>
  1020b8:	fffff097          	auipc	ra,0xfffff
  1020bc:	d4c080e7          	jalr	-692(ra) # 100e04 <s_printf>
        if (g_part_lba == 0u) {
  1020c0:	00c92503          	lw	a0,12(s2)
  1020c4:	02050a63          	beqz	a0,1020f8 <boot_fat32_mount+0x1b0>
        s_printf("FAT32: read BPB\n");
  1020c8:	00103537          	lui	a0,0x103
  1020cc:	4c350513          	addi	a0,a0,1219 # 1034c3 <print_hex8.HEX+0x1c9>
  1020d0:	fffff097          	auipc	ra,0xfffff
  1020d4:	d34080e7          	jalr	-716(ra) # 100e04 <s_printf>
        if (g_read_sector(g_part_lba, buf)) {
  1020d8:	00892603          	lw	a2,8(s2)
  1020dc:	00c92503          	lw	a0,12(s2)
  1020e0:	00048593          	mv	a1,s1
  1020e4:	000600e7          	jalr	a2
  1020e8:	00050e63          	beqz	a0,102104 <boot_fat32_mount+0x1bc>
  1020ec:	00103537          	lui	a0,0x103
  1020f0:	4d450513          	addi	a0,a0,1236 # 1034d4 <print_hex8.HEX+0x1da>
    if (g_root_cluster < 2u) {
  1020f4:	ed9ff06f          	j	101fcc <boot_fat32_mount+0x84>
  1020f8:	00103537          	lui	a0,0x103
  1020fc:	4ad50513          	addi	a0,a0,1197 # 1034ad <print_hex8.HEX+0x1b3>
  102100:	ecdff06f          	j	101fcc <boot_fat32_mount+0x84>
        s_printf("FAT32: read BPB ok\n");
  102104:	00103537          	lui	a0,0x103
  102108:	4ec50513          	addi	a0,a0,1260 # 1034ec <print_hex8.HEX+0x1f2>
  10210c:	fffff097          	auipc	ra,0xfffff
  102110:	cf8080e7          	jalr	-776(ra) # 100e04 <s_printf>
        if (!is_fat32_boot_sector(buf)) {
  102114:	00000097          	auipc	ra,0x0
  102118:	270080e7          	jalr	624(ra) # 102384 <is_fat32_boot_sector>
  10211c:	00050863          	beqz	a0,10212c <boot_fat32_mount+0x1e4>
  102120:	00103537          	lui	a0,0x103
  102124:	51450513          	addi	a0,a0,1300 # 103514 <print_hex8.HEX+0x21a>
  102128:	01c0006f          	j	102144 <boot_fat32_mount+0x1fc>
  10212c:	00103537          	lui	a0,0x103
  102130:	50050513          	addi	a0,a0,1280 # 103500 <print_hex8.HEX+0x206>
    if (g_root_cluster < 2u) {
  102134:	e99ff06f          	j	101fcc <boot_fat32_mount+0x84>
        g_part_lba = 0;
  102138:	00092623          	sw	zero,12(s2)
  10213c:	00103537          	lui	a0,0x103
  102140:	47450513          	addi	a0,a0,1140 # 103474 <print_hex8.HEX+0x17a>
  102144:	fffff097          	auipc	ra,0xfffff
  102148:	cc0080e7          	jalr	-832(ra) # 100e04 <s_printf>
    s_printf("FAT32: parse 1\n");
  10214c:	00103537          	lui	a0,0x103
  102150:	52650513          	addi	a0,a0,1318 # 103526 <print_hex8.HEX+0x22c>
  102154:	fffff097          	auipc	ra,0xfffff
  102158:	cb0080e7          	jalr	-848(ra) # 100e04 <s_printf>
           ((uint16_t)p[1] << 8);
  10215c:	02494503          	lbu	a0,36(s2)
    return (uint16_t)p[0] |
  102160:	02394583          	lbu	a1,35(s2)
           ((uint16_t)p[1] << 8);
  102164:	00851513          	slli	a0,a0,0x8
    return (uint16_t)p[0] |
  102168:	00b56ab3          	or	s5,a0,a1
    s_printf("FAT32: parse 2\n");
  10216c:	00103537          	lui	a0,0x103
  102170:	53650513          	addi	a0,a0,1334 # 103536 <print_hex8.HEX+0x23c>
  102174:	fffff097          	auipc	ra,0xfffff
  102178:	c90080e7          	jalr	-880(ra) # 100e04 <s_printf>
    g_sectors_per_cluster = buf[13];
  10217c:	02594503          	lbu	a0,37(s2)
  102180:	00a92223          	sw	a0,4(s2)
    s_printf("FAT32: parse 3\n");
  102184:	00103537          	lui	a0,0x103
  102188:	54650513          	addi	a0,a0,1350 # 103546 <print_hex8.HEX+0x24c>
  10218c:	fffff097          	auipc	ra,0xfffff
  102190:	c78080e7          	jalr	-904(ra) # 100e04 <s_printf>
    return (uint16_t)p[0] |
  102194:	02695a03          	lhu	s4,38(s2)
    s_printf("FAT32: parse 4\n");
  102198:	00103537          	lui	a0,0x103
  10219c:	55650513          	addi	a0,a0,1366 # 103556 <print_hex8.HEX+0x25c>
  1021a0:	fffff097          	auipc	ra,0xfffff
  1021a4:	c64080e7          	jalr	-924(ra) # 100e04 <s_printf>
    fat_count = buf[16];
  1021a8:	02894983          	lbu	s3,40(s2)
    s_printf("FAT32: parse 5\n");
  1021ac:	00103537          	lui	a0,0x103
  1021b0:	56650513          	addi	a0,a0,1382 # 103566 <print_hex8.HEX+0x26c>
  1021b4:	fffff097          	auipc	ra,0xfffff
  1021b8:	c50080e7          	jalr	-944(ra) # 100e04 <s_printf>
           ((uint32_t)p[2] << 16) |
  1021bc:	03c92483          	lw	s1,60(s2)
    s_printf("FAT32: parse 6\n");
  1021c0:	00103537          	lui	a0,0x103
  1021c4:	57650513          	addi	a0,a0,1398 # 103576 <print_hex8.HEX+0x27c>
  1021c8:	fffff097          	auipc	ra,0xfffff
  1021cc:	c3c080e7          	jalr	-964(ra) # 100e04 <s_printf>
           ((uint32_t)p[2] << 16) |
  1021d0:	04492503          	lw	a0,68(s2)
    g_root_cluster = rd32(&buf[44]);
  1021d4:	00a92823          	sw	a0,16(s2)
    s_printf("FAT32: validate\n");
  1021d8:	00103537          	lui	a0,0x103
  1021dc:	58650513          	addi	a0,a0,1414 # 103586 <print_hex8.HEX+0x28c>
  1021e0:	fffff097          	auipc	ra,0xfffff
  1021e4:	c24080e7          	jalr	-988(ra) # 100e04 <s_printf>
  1021e8:	20000513          	li	a0,512
    if (bytes_per_sector != 512u) {
  1021ec:	02aa9463          	bne	s5,a0,102214 <boot_fat32_mount+0x2cc>
    if (g_sectors_per_cluster == 0u) {
  1021f0:	00492503          	lw	a0,4(s2)
  1021f4:	02050663          	beqz	a0,102220 <boot_fat32_mount+0x2d8>
    if (reserved_sector_count == 0u) {
  1021f8:	020a0a63          	beqz	s4,10222c <boot_fat32_mount+0x2e4>
    if (fat_count == 0u || fat_count > 4u) {
  1021fc:	ffb98513          	addi	a0,s3,-5
  102200:	ffc00593          	li	a1,-4
  102204:	02b57a63          	bgeu	a0,a1,102238 <boot_fat32_mount+0x2f0>
  102208:	00103537          	lui	a0,0x103
  10220c:	5cc50513          	addi	a0,a0,1484 # 1035cc <print_hex8.HEX+0x2d2>
    if (g_root_cluster < 2u) {
  102210:	dbdff06f          	j	101fcc <boot_fat32_mount+0x84>
  102214:	00103537          	lui	a0,0x103
  102218:	59750513          	addi	a0,a0,1431 # 103597 <print_hex8.HEX+0x29d>
  10221c:	db1ff06f          	j	101fcc <boot_fat32_mount+0x84>
  102220:	00103537          	lui	a0,0x103
  102224:	5a750513          	addi	a0,a0,1447 # 1035a7 <print_hex8.HEX+0x2ad>
  102228:	da5ff06f          	j	101fcc <boot_fat32_mount+0x84>
  10222c:	00103537          	lui	a0,0x103
  102230:	5b750513          	addi	a0,a0,1463 # 1035b7 <print_hex8.HEX+0x2bd>
  102234:	d99ff06f          	j	101fcc <boot_fat32_mount+0x84>
    if (fat_size == 0u) {
  102238:	00048e63          	beqz	s1,102254 <boot_fat32_mount+0x30c>
    if (g_root_cluster < 2u) {
  10223c:	01092503          	lw	a0,16(s2)
  102240:	00200913          	li	s2,2
  102244:	01257e63          	bgeu	a0,s2,102260 <boot_fat32_mount+0x318>
  102248:	00103537          	lui	a0,0x103
  10224c:	5f750513          	addi	a0,a0,1527 # 1035f7 <print_hex8.HEX+0x2fd>
  102250:	d7dff06f          	j	101fcc <boot_fat32_mount+0x84>
  102254:	00103537          	lui	a0,0x103
  102258:	5e250513          	addi	a0,a0,1506 # 1035e2 <print_hex8.HEX+0x2e8>
  10225c:	d71ff06f          	j	101fcc <boot_fat32_mount+0x84>
    s_printf("FAT32: root check\n");
  102260:	00103537          	lui	a0,0x103
  102264:	61050513          	addi	a0,a0,1552 # 103610 <print_hex8.HEX+0x316>
  102268:	fffff097          	auipc	ra,0xfffff
  10226c:	b9c080e7          	jalr	-1124(ra) # 100e04 <s_printf>
    if (g_root_cluster == 2u)
  102270:	00108437          	lui	s0,0x108
  102274:	ba040a93          	addi	s5,s0,-1120 # 107ba0 <g_data_begin_lba>
  102278:	010aa503          	lw	a0,16(s5)
  10227c:	01250863          	beq	a0,s2,10228c <boot_fat32_mount+0x344>
  102280:	00103537          	lui	a0,0x103
  102284:	63550513          	addi	a0,a0,1589 # 103635 <print_hex8.HEX+0x33b>
  102288:	00c0006f          	j	102294 <boot_fat32_mount+0x34c>
  10228c:	00103537          	lui	a0,0x103
  102290:	62350513          	addi	a0,a0,1571 # 103623 <print_hex8.HEX+0x329>
  102294:	fffff097          	auipc	ra,0xfffff
  102298:	b70080e7          	jalr	-1168(ra) # 100e04 <s_printf>
    s_printf("FAT32: calc fat\n");
  10229c:	00103537          	lui	a0,0x103
  1022a0:	64850513          	addi	a0,a0,1608 # 103648 <print_hex8.HEX+0x34e>
  1022a4:	fffff097          	auipc	ra,0xfffff
  1022a8:	b60080e7          	jalr	-1184(ra) # 100e04 <s_printf>
    g_fat_begin_lba = g_part_lba + reserved_sector_count;
  1022ac:	00caa503          	lw	a0,12(s5)
  1022b0:	01450533          	add	a0,a0,s4
  1022b4:	00aaaa23          	sw	a0,20(s5)
    s_printf("FAT32: calc data\n");
  1022b8:	00103537          	lui	a0,0x103
  1022bc:	65950513          	addi	a0,a0,1625 # 103659 <print_hex8.HEX+0x35f>
  1022c0:	fffff097          	auipc	ra,0xfffff
  1022c4:	b44080e7          	jalr	-1212(ra) # 100e04 <s_printf>
    g_data_begin_lba = g_fat_begin_lba;
  1022c8:	014aa503          	lw	a0,20(s5)
  1022cc:	baa42023          	sw	a0,-1120(s0)
        s_printf("FAT32: add fat1\n");
  1022d0:	00103537          	lui	a0,0x103
  1022d4:	66b50513          	addi	a0,a0,1643 # 10366b <print_hex8.HEX+0x371>
  1022d8:	fffff097          	auipc	ra,0xfffff
  1022dc:	b2c080e7          	jalr	-1236(ra) # 100e04 <s_printf>
        g_data_begin_lba += fat_size;
  1022e0:	ba042503          	lw	a0,-1120(s0)
  1022e4:	00950533          	add	a0,a0,s1
  1022e8:	baa42023          	sw	a0,-1120(s0)
  1022ec:	00103537          	lui	a0,0x103
  1022f0:	6af50513          	addi	a0,a0,1711 # 1036af <print_hex8.HEX+0x3b5>
    if (fat_count >= 2u) {
  1022f4:	0729ee63          	bltu	s3,s2,102370 <boot_fat32_mount+0x428>
  1022f8:	00050913          	mv	s2,a0
        s_printf("FAT32: add fat2\n");
  1022fc:	00103537          	lui	a0,0x103
  102300:	67c50513          	addi	a0,a0,1660 # 10367c <print_hex8.HEX+0x382>
  102304:	fffff097          	auipc	ra,0xfffff
  102308:	b00080e7          	jalr	-1280(ra) # 100e04 <s_printf>
        g_data_begin_lba += fat_size;
  10230c:	00108437          	lui	s0,0x108
  102310:	ba042503          	lw	a0,-1120(s0) # 107ba0 <g_data_begin_lba>
  102314:	00950533          	add	a0,a0,s1
  102318:	00200593          	li	a1,2
  10231c:	baa42023          	sw	a0,-1120(s0)
    if (fat_count >= 3u) {
  102320:	04b98c63          	beq	s3,a1,102378 <boot_fat32_mount+0x430>
        s_printf("FAT32: add fat3\n");
  102324:	00103537          	lui	a0,0x103
  102328:	68d50513          	addi	a0,a0,1677 # 10368d <print_hex8.HEX+0x393>
  10232c:	fffff097          	auipc	ra,0xfffff
  102330:	ad8080e7          	jalr	-1320(ra) # 100e04 <s_printf>
        g_data_begin_lba += fat_size;
  102334:	ba042503          	lw	a0,-1120(s0)
  102338:	00950533          	add	a0,a0,s1
  10233c:	00400593          	li	a1,4
  102340:	baa42023          	sw	a0,-1120(s0)
    if (fat_count >= 4u) {
  102344:	02b9ea63          	bltu	s3,a1,102378 <boot_fat32_mount+0x430>
        s_printf("FAT32: add fat4\n");
  102348:	00103537          	lui	a0,0x103
  10234c:	69e50513          	addi	a0,a0,1694 # 10369e <print_hex8.HEX+0x3a4>
  102350:	fffff097          	auipc	ra,0xfffff
  102354:	ab4080e7          	jalr	-1356(ra) # 100e04 <s_printf>
  102358:	00000413          	li	s0,0
        g_data_begin_lba += fat_size;
  10235c:	00108537          	lui	a0,0x108
  102360:	ba052583          	lw	a1,-1120(a0) # 107ba0 <g_data_begin_lba>
  102364:	009585b3          	add	a1,a1,s1
  102368:	bab52023          	sw	a1,-1120(a0)
  10236c:	0100006f          	j	10237c <boot_fat32_mount+0x434>
  102370:	00000413          	li	s0,0
    if (fat_count >= 2u) {
  102374:	c59ff06f          	j	101fcc <boot_fat32_mount+0x84>
  102378:	00000413          	li	s0,0
  10237c:	00090513          	mv	a0,s2
  102380:	c4dff06f          	j	101fcc <boot_fat32_mount+0x84>

00102384 <is_fat32_boot_sector>:
    if (b[510] != 0x55 || b[511] != 0xAA)
  102384:	001085b7          	lui	a1,0x108
  102388:	ba058593          	addi	a1,a1,-1120 # 107ba0 <g_data_begin_lba>
  10238c:	2165c603          	lbu	a2,534(a1)
  102390:	05500693          	li	a3,85
  102394:	00000513          	li	a0,0
  102398:	06d61e63          	bne	a2,a3,102414 <is_fat32_boot_sector+0x90>
  10239c:	2175c603          	lbu	a2,535(a1)
  1023a0:	0aa00693          	li	a3,170
  1023a4:	06d61863          	bne	a2,a3,102414 <is_fat32_boot_sector+0x90>
           ((uint16_t)p[1] << 8);
  1023a8:	0245c503          	lbu	a0,36(a1)
    return (uint16_t)p[0] |
  1023ac:	0235c603          	lbu	a2,35(a1)
           ((uint16_t)p[1] << 8);
  1023b0:	00851513          	slli	a0,a0,0x8
    return (uint16_t)p[0] |
  1023b4:	00c56633          	or	a2,a0,a2
  1023b8:	20000693          	li	a3,512
  1023bc:	00000513          	li	a0,0
    if (rd16(&b[11]) != 512u)
  1023c0:	04d61a63          	bne	a2,a3,102414 <is_fat32_boot_sector+0x90>
  1023c4:	0255c603          	lbu	a2,37(a1)
  1023c8:	04060663          	beqz	a2,102414 <is_fat32_boot_sector+0x90>
    return (uint16_t)p[0] |
  1023cc:	0265c503          	lbu	a0,38(a1)
           ((uint16_t)p[1] << 8);
  1023d0:	0275c603          	lbu	a2,39(a1)
    if (rd16(&b[14]) == 0)
  1023d4:	00a66633          	or	a2,a2,a0
  1023d8:	00000513          	li	a0,0
  1023dc:	02060c63          	beqz	a2,102414 <is_fat32_boot_sector+0x90>
  1023e0:	0285c603          	lbu	a2,40(a1)
  1023e4:	02060863          	beqz	a2,102414 <is_fat32_boot_sector+0x90>
    return ((uint32_t)p[0]) |
  1023e8:	03c5c503          	lbu	a0,60(a1)
           ((uint32_t)p[1] << 8) |
  1023ec:	03d5c603          	lbu	a2,61(a1)
           ((uint32_t)p[2] << 16) |
  1023f0:	03e5c683          	lbu	a3,62(a1)
           ((uint32_t)p[3] << 24);
  1023f4:	03f5c703          	lbu	a4,63(a1)
    if (rd32(&b[36]) == 0)
  1023f8:	00a66533          	or	a0,a2,a0
  1023fc:	00e6e6b3          	or	a3,a3,a4
  102400:	00d56533          	or	a0,a0,a3
  102404:	00050863          	beqz	a0,102414 <is_fat32_boot_sector+0x90>
           ((uint32_t)p[2] << 16) |
  102408:	0445a503          	lw	a0,68(a1)
    if (rd32(&b[44]) < 2)
  10240c:	00253513          	sltiu	a0,a0,2
  102410:	00154513          	xori	a0,a0,1
}
  102414:	00008067          	ret

00102418 <boot_fat32_next_cluster>:

uint32_t boot_fat32_next_cluster(uint32_t cluster)
{
  102418:	ff010113          	addi	sp,sp,-16
  10241c:	00112623          	sw	ra,12(sp)
  102420:	00812423          	sw	s0,8(sp)
  102424:	00912223          	sw	s1,4(sp)
  102428:	01212023          	sw	s2,0(sp)
  10242c:	10000437          	lui	s0,0x10000
  102430:	00200593          	li	a1,2
  102434:	ff840413          	addi	s0,s0,-8 # ffffff8 <_stack_top+0xfef4038>
    uint32_t fat_offset = cluster * 4u;
    uint32_t fat_lba    = g_fat_begin_lba + (fat_offset / 512u);
    uint32_t ent_off    = fat_offset & 0x1FFu;
    uint32_t next;

    if (cluster < 2u)
  102438:	06b56063          	bltu	a0,a1,102498 <boot_fat32_next_cluster+0x80>
    uint32_t fat_lba    = g_fat_begin_lba + (fat_offset / 512u);
  10243c:	001084b7          	lui	s1,0x108
  102440:	ba048493          	addi	s1,s1,-1120 # 107ba0 <g_data_begin_lba>
  102444:	0144a583          	lw	a1,20(s1)
        return FAT32_EOC_MIN;

    if (g_read_sector(fat_lba, fat32_buf))
  102448:	0084a603          	lw	a2,8(s1)
  10244c:	00251913          	slli	s2,a0,0x2
    uint32_t fat_lba    = g_fat_begin_lba + (fat_offset / 512u);
  102450:	00995513          	srli	a0,s2,0x9
  102454:	00a58533          	add	a0,a1,a0
    if (g_read_sector(fat_lba, fat32_buf))
  102458:	01848593          	addi	a1,s1,24
  10245c:	000600e7          	jalr	a2
  102460:	02051c63          	bnez	a0,102498 <boot_fat32_next_cluster+0x80>
  102464:	1fc97513          	andi	a0,s2,508
        return FAT32_EOC_MIN;

    next = rd32(&fat32_buf[ent_off]);
  102468:	00a48533          	add	a0,s1,a0
           ((uint32_t)p[1] << 8) |
  10246c:	01954583          	lbu	a1,25(a0)
    return ((uint32_t)p[0]) |
  102470:	01854603          	lbu	a2,24(a0)
           ((uint32_t)p[2] << 16) |
  102474:	01a54683          	lbu	a3,26(a0)
           ((uint32_t)p[3] << 24);
  102478:	01b54503          	lbu	a0,27(a0)
           ((uint32_t)p[1] << 8) |
  10247c:	00859593          	slli	a1,a1,0x8
    return ((uint32_t)p[0]) |
  102480:	00c5e5b3          	or	a1,a1,a2
           ((uint32_t)p[2] << 16) |
  102484:	01069693          	slli	a3,a3,0x10
    next &= 0x0FFFFFFFu;
  102488:	01c51513          	slli	a0,a0,0x1c
           ((uint32_t)p[1] << 8) |
  10248c:	00d5e5b3          	or	a1,a1,a3
    next &= 0x0FFFFFFFu;
  102490:	00455513          	srli	a0,a0,0x4
  102494:	00a5e433          	or	s0,a1,a0

    return next;
}
  102498:	00040513          	mv	a0,s0
  10249c:	00c12083          	lw	ra,12(sp)
  1024a0:	00812403          	lw	s0,8(sp)
  1024a4:	00412483          	lw	s1,4(sp)
  1024a8:	00012903          	lw	s2,0(sp)
  1024ac:	01010113          	addi	sp,sp,16
  1024b0:	00008067          	ret

001024b4 <boot_fat32_find>:
int boot_fat32_find(
    const char *name,
    uint32_t *cluster,
    uint32_t *size
)
{
  1024b4:	f8010113          	addi	sp,sp,-128
  1024b8:	06112e23          	sw	ra,124(sp)
  1024bc:	06812c23          	sw	s0,120(sp)
  1024c0:	06912a23          	sw	s1,116(sp)
  1024c4:	07212823          	sw	s2,112(sp)
  1024c8:	07312623          	sw	s3,108(sp)
  1024cc:	07412423          	sw	s4,104(sp)
  1024d0:	07512223          	sw	s5,100(sp)
  1024d4:	07612023          	sw	s6,96(sp)
  1024d8:	05712e23          	sw	s7,92(sp)
  1024dc:	05812c23          	sw	s8,88(sp)
  1024e0:	05912a23          	sw	s9,84(sp)
  1024e4:	05a12823          	sw	s10,80(sp)
  1024e8:	05b12623          	sw	s11,76(sp)
  1024ec:	02c12823          	sw	a2,48(sp)
  1024f0:	02b12623          	sw	a1,44(sp)
  1024f4:	00050913          	mv	s2,a0
    uint32_t dir_cluster;
    char target[11];

    s_printf("FAT32: find enter\n");
  1024f8:	00103537          	lui	a0,0x103
  1024fc:	6c050513          	addi	a0,a0,1728 # 1036c0 <print_hex8.HEX+0x3c6>
  102500:	fffff097          	auipc	ra,0xfffff
  102504:	904080e7          	jalr	-1788(ra) # 100e04 <s_printf>
  102508:	02000593          	li	a1,32

    {
        int i = 0;
        int j = 0;

        while (name[i] != '\0' && name[i] != '.' && j < 8) {
  10250c:	00094503          	lbu	a0,0(s2)
        target[i] = ' ';
  102510:	04b100a3          	sb	a1,65(sp)
  102514:	04b10123          	sb	a1,66(sp)
  102518:	04b101a3          	sb	a1,67(sp)
  10251c:	04b10223          	sb	a1,68(sp)
  102520:	04b102a3          	sb	a1,69(sp)
  102524:	04b10323          	sb	a1,70(sp)
  102528:	04b103a3          	sb	a1,71(sp)
  10252c:	04b10423          	sb	a1,72(sp)
  102530:	04b104a3          	sb	a1,73(sp)
  102534:	04b10523          	sb	a1,74(sp)
  102538:	04b105a3          	sb	a1,75(sp)
        while (name[i] != '\0' && name[i] != '.' && j < 8) {
  10253c:	04050c63          	beqz	a0,102594 <boot_fat32_find+0xe0>
  102540:	00000593          	li	a1,0
  102544:	02e00613          	li	a2,46
  102548:	00700693          	li	a3,7
  10254c:	04110713          	addi	a4,sp,65
  102550:	0ff57793          	zext.b	a5,a0
  102554:	04c78463          	beq	a5,a2,10259c <boot_fat32_find+0xe8>
  102558:	04b6e263          	bltu	a3,a1,10259c <boot_fat32_find+0xe8>
    if (c >= 'a' && c <= 'z')
  10255c:	f9f50793          	addi	a5,a0,-97
        while (name[i] != '\0' && name[i] != '.' && j < 8) {
  102560:	00b90833          	add	a6,s2,a1
    if (c >= 'a' && c <= 'z')
  102564:	0ff7f793          	zext.b	a5,a5
  102568:	01a7b793          	sltiu	a5,a5,26
  10256c:	40f007b3          	neg	a5,a5
  102570:	0e07f793          	andi	a5,a5,224
  102574:	00f508b3          	add	a7,a0,a5
        while (name[i] != '\0' && name[i] != '.' && j < 8) {
  102578:	00184503          	lbu	a0,1(a6)
            target[j++] = upper_char(name[i]);
            i++;
  10257c:	00158793          	addi	a5,a1,1
            target[j++] = upper_char(name[i]);
  102580:	00b705b3          	add	a1,a4,a1
  102584:	01158023          	sb	a7,0(a1)
  102588:	00078593          	mv	a1,a5
        while (name[i] != '\0' && name[i] != '.' && j < 8) {
  10258c:	fc0512e3          	bnez	a0,102550 <boot_fat32_find+0x9c>
  102590:	0100006f          	j	1025a0 <boot_fat32_find+0xec>
  102594:	00000793          	li	a5,0
  102598:	0180006f          	j	1025b0 <boot_fat32_find+0xfc>
  10259c:	00058793          	mv	a5,a1
        }

        if (name[i] == '.')
  1025a0:	0ff57513          	zext.b	a0,a0
  1025a4:	fd250513          	addi	a0,a0,-46
  1025a8:	00153513          	seqz	a0,a0
  1025ac:	00a787b3          	add	a5,a5,a0
            i++;

        j = 8;

        while (name[i] != '\0' && j < 11) {
  1025b0:	00f905b3          	add	a1,s2,a5
  1025b4:	0005c503          	lbu	a0,0(a1)
  1025b8:	04050663          	beqz	a0,102604 <boot_fat32_find+0x150>
  1025bc:	00158593          	addi	a1,a1,1
  1025c0:	00800713          	li	a4,8
  1025c4:	04110613          	addi	a2,sp,65
  1025c8:	00a00693          	li	a3,10
    if (c >= 'a' && c <= 'z')
  1025cc:	f9f50793          	addi	a5,a0,-97
  1025d0:	0ff7f793          	zext.b	a5,a5
  1025d4:	01a7b793          	sltiu	a5,a5,26
  1025d8:	40f007b3          	neg	a5,a5
  1025dc:	0e07f793          	andi	a5,a5,224
  1025e0:	00f50833          	add	a6,a0,a5
        while (name[i] != '\0' && j < 11) {
  1025e4:	0005c503          	lbu	a0,0(a1)
  1025e8:	00070793          	mv	a5,a4
            target[j++] = upper_char(name[i]);
  1025ec:	00e60733          	add	a4,a2,a4
  1025f0:	01070023          	sb	a6,0(a4)
        while (name[i] != '\0' && j < 11) {
  1025f4:	00050863          	beqz	a0,102604 <boot_fat32_find+0x150>
  1025f8:	00178713          	addi	a4,a5,1
  1025fc:	00158593          	addi	a1,a1,1
  102600:	fcd7e6e3          	bltu	a5,a3,1025cc <boot_fat32_find+0x118>
            i++;
        }
    }

    dir_cluster = g_root_cluster;
  102604:	00108c37          	lui	s8,0x108
  102608:	ba0c0c13          	addi	s8,s8,-1120 # 107ba0 <g_data_begin_lba>
  10260c:	010c2483          	lw	s1,16(s8)

    s_printf("FAT32: root loop\n");
  102610:	00103537          	lui	a0,0x103
  102614:	6d350513          	addi	a0,a0,1747 # 1036d3 <print_hex8.HEX+0x3d9>
  102618:	ffffe097          	auipc	ra,0xffffe
  10261c:	7ec080e7          	jalr	2028(ra) # 100e04 <s_printf>

    while (dir_cluster >= 2u &&
  102620:	ffe48593          	addi	a1,s1,-2
  102624:	10000537          	lui	a0,0x10000
  102628:	ff450613          	addi	a2,a0,-12 # ffffff4 <_stack_top+0xfef4034>
  10262c:	22b66463          	bltu	a2,a1,102854 <boot_fat32_find+0x3a0>
  102630:	04114c83          	lbu	s9,65(sp)
  102634:	04214d03          	lbu	s10,66(sp)
  102638:	04314583          	lbu	a1,67(sp)
  10263c:	02b12e23          	sw	a1,60(sp)
  102640:	04414583          	lbu	a1,68(sp)
  102644:	02b12a23          	sw	a1,52(sp)
  102648:	04514583          	lbu	a1,69(sp)
  10264c:	02b12423          	sw	a1,40(sp)
  102650:	04614583          	lbu	a1,70(sp)
  102654:	02b12023          	sw	a1,32(sp)
  102658:	04714583          	lbu	a1,71(sp)
  10265c:	00b12e23          	sw	a1,28(sp)
  102660:	04814583          	lbu	a1,72(sp)
  102664:	00b12c23          	sw	a1,24(sp)
  102668:	04914583          	lbu	a1,73(sp)
  10266c:	00b12a23          	sw	a1,20(sp)
  102670:	04a14583          	lbu	a1,74(sp)
  102674:	00b12823          	sw	a1,16(sp)
  102678:	04b14583          	lbu	a1,75(sp)
  10267c:	00b12623          	sw	a1,12(sp)
  102680:	00103437          	lui	s0,0x103
  102684:	6e540413          	addi	s0,s0,1765 # 1036e5 <print_hex8.HEX+0x3eb>
  102688:	001085b7          	lui	a1,0x108
  10268c:	018c0a93          	addi	s5,s8,24
  102690:	ff550513          	addi	a0,a0,-11
  102694:	02a12223          	sw	a0,36(sp)
  102698:	ba058513          	addi	a0,a1,-1120 # 107ba0 <g_data_begin_lba>
  10269c:	02a12c23          	sw	a0,56(sp)
  1026a0:	01bc0a13          	addi	s4,s8,27
  1026a4:	0e500913          	li	s2,229
  1026a8:	00103bb7          	lui	s7,0x103
  1026ac:	73eb8b93          	addi	s7,s7,1854 # 10373e <print_hex8.HEX+0x444>
           dir_cluster < FAT32_EOC_MIN &&
           dir_cluster != FAT32_BAD_CLUSTER) {

        uint32_t dir_lba;

        s_printf("FAT32: calc lba\n");
  1026b0:	00040513          	mv	a0,s0
  1026b4:	ffffe097          	auipc	ra,0xffffe
  1026b8:	750080e7          	jalr	1872(ra) # 100e04 <s_printf>
  1026bc:	00108537          	lui	a0,0x108

        /* root cluster = 2 固定で検証 */
        dir_lba = g_data_begin_lba;
  1026c0:	ba052b03          	lw	s6,-1120(a0) # 107ba0 <g_data_begin_lba>

        s_printf("FAT32: read dir\n");
  1026c4:	00103537          	lui	a0,0x103
  1026c8:	6f650513          	addi	a0,a0,1782 # 1036f6 <print_hex8.HEX+0x3fc>
  1026cc:	ffffe097          	auipc	ra,0xffffe
  1026d0:	738080e7          	jalr	1848(ra) # 100e04 <s_printf>
  1026d4:	03812503          	lw	a0,56(sp)

        for (uint32_t s = 0; s < g_sectors_per_cluster; s++) {
  1026d8:	00452503          	lw	a0,4(a0)
  1026dc:	0e050c63          	beqz	a0,1027d4 <boot_fat32_find+0x320>
  1026e0:	00000413          	li	s0,0
  1026e4:	0100006f          	j	1026f4 <boot_fat32_find+0x240>
  1026e8:	004c2503          	lw	a0,4(s8)
  1026ec:	00140413          	addi	s0,s0,1
  1026f0:	0ea47263          	bgeu	s0,a0,1027d4 <boot_fat32_find+0x320>

            uint8_t *e;

            if (g_read_sector(dir_lba + s, fat32_buf)) {
  1026f4:	008c2603          	lw	a2,8(s8)
  1026f8:	01640533          	add	a0,s0,s6
  1026fc:	000a8593          	mv	a1,s5
  102700:	000600e7          	jalr	a2
  102704:	1a051663          	bnez	a0,1028b0 <boot_fat32_find+0x3fc>
                s_printf("FAT32: read dir failed\n");
                return -1;
            }

            s_printf("FAT32: dir ok\n");
  102708:	00103537          	lui	a0,0x103
  10270c:	71f50513          	addi	a0,a0,1823 # 10371f <print_hex8.HEX+0x425>
  102710:	ffffe097          	auipc	ra,0xffffe
  102714:	6f4080e7          	jalr	1780(ra) # 100e04 <s_printf>
  102718:	01000d93          	li	s11,16
  10271c:	000a0993          	mv	s3,s4
  102720:	0100006f          	j	102730 <boot_fat32_find+0x27c>

            e = fat32_buf;

            for (int i = 0; i < 16; i++) {
  102724:	fffd8d93          	addi	s11,s11,-1
  102728:	02098993          	addi	s3,s3,32
  10272c:	fa0d8ee3          	beqz	s11,1026e8 <boot_fat32_find+0x234>
                uint8_t attr;
                int match;

                if (e[0] == 0x00) {
  102730:	ffd9c503          	lbu	a0,-3(s3)
  102734:	ff2508e3          	beq	a0,s2,102724 <boot_fat32_find+0x270>
  102738:	12050463          	beqz	a0,102860 <boot_fat32_find+0x3ac>
                if (e[0] == 0xE5) {
                    e += 32;
                    continue;
                }

                attr = e[11];
  10273c:	0089c503          	lbu	a0,8(s3)

                if (attr == 0x0F) {
  102740:	01857513          	andi	a0,a0,24
  102744:	fe0510e3          	bnez	a0,102724 <boot_fat32_find+0x270>
                if (attr & 0x10) {
                    e += 32;
                    continue;
                }

                s_printf("FAT32: entry\n");
  102748:	000b8513          	mv	a0,s7
  10274c:	ffffe097          	auipc	ra,0xffffe
  102750:	6b8080e7          	jalr	1720(ra) # 100e04 <s_printf>

                match = 1;

                for (int k = 0; k < 11; k++) {
                    if ((char)e[k] != target[k]) {
  102754:	ffd9c503          	lbu	a0,-3(s3)
  102758:	fd9516e3          	bne	a0,s9,102724 <boot_fat32_find+0x270>
  10275c:	ffe9c503          	lbu	a0,-2(s3)
  102760:	fda512e3          	bne	a0,s10,102724 <boot_fat32_find+0x270>
  102764:	fff9c503          	lbu	a0,-1(s3)
  102768:	03c12583          	lw	a1,60(sp)
  10276c:	fab51ce3          	bne	a0,a1,102724 <boot_fat32_find+0x270>
  102770:	0009c503          	lbu	a0,0(s3)
  102774:	03412583          	lw	a1,52(sp)
  102778:	fab516e3          	bne	a0,a1,102724 <boot_fat32_find+0x270>
  10277c:	0019c503          	lbu	a0,1(s3)
  102780:	02812583          	lw	a1,40(sp)
  102784:	fab510e3          	bne	a0,a1,102724 <boot_fat32_find+0x270>
  102788:	0029c503          	lbu	a0,2(s3)
  10278c:	02012583          	lw	a1,32(sp)
  102790:	f8b51ae3          	bne	a0,a1,102724 <boot_fat32_find+0x270>
  102794:	0039c503          	lbu	a0,3(s3)
  102798:	01c12583          	lw	a1,28(sp)
  10279c:	f8b514e3          	bne	a0,a1,102724 <boot_fat32_find+0x270>
  1027a0:	0049c503          	lbu	a0,4(s3)
  1027a4:	01812583          	lw	a1,24(sp)
  1027a8:	f6b51ee3          	bne	a0,a1,102724 <boot_fat32_find+0x270>
  1027ac:	0059c503          	lbu	a0,5(s3)
  1027b0:	01412583          	lw	a1,20(sp)
  1027b4:	f6b518e3          	bne	a0,a1,102724 <boot_fat32_find+0x270>
  1027b8:	0069c503          	lbu	a0,6(s3)
  1027bc:	01012583          	lw	a1,16(sp)
  1027c0:	f6b512e3          	bne	a0,a1,102724 <boot_fat32_find+0x270>
  1027c4:	0079c503          	lbu	a0,7(s3)
  1027c8:	00c12583          	lw	a1,12(sp)
  1027cc:	f4b51ce3          	bne	a0,a1,102724 <boot_fat32_find+0x270>
  1027d0:	0ec0006f          	j	1028bc <boot_fat32_find+0x408>

                e += 32;
            }
        }

        s_printf("FAT32: next\n");
  1027d4:	00103537          	lui	a0,0x103
  1027d8:	75a50513          	addi	a0,a0,1882 # 10375a <print_hex8.HEX+0x460>
  1027dc:	ffffe097          	auipc	ra,0xffffe
  1027e0:	628080e7          	jalr	1576(ra) # 100e04 <s_printf>
  1027e4:	00103437          	lui	s0,0x103
  1027e8:	6e540413          	addi	s0,s0,1765 # 1036e5 <print_hex8.HEX+0x3eb>
    if (cluster < 2u)
  1027ec:	00200513          	li	a0,2
  1027f0:	06a4e263          	bltu	s1,a0,102854 <boot_fat32_find+0x3a0>
    uint32_t fat_lba    = g_fat_begin_lba + (fat_offset / 512u);
  1027f4:	014c2503          	lw	a0,20(s8)
    if (g_read_sector(fat_lba, fat32_buf))
  1027f8:	008c2603          	lw	a2,8(s8)
    uint32_t fat_lba    = g_fat_begin_lba + (fat_offset / 512u);
  1027fc:	0074d593          	srli	a1,s1,0x7
  102800:	00b50533          	add	a0,a0,a1
    if (g_read_sector(fat_lba, fat32_buf))
  102804:	000a8593          	mv	a1,s5
  102808:	000600e7          	jalr	a2
  10280c:	04051463          	bnez	a0,102854 <boot_fat32_find+0x3a0>
  102810:	01949493          	slli	s1,s1,0x19
  102814:	0174d493          	srli	s1,s1,0x17
    next = rd32(&fat32_buf[ent_off]);
  102818:	009c04b3          	add	s1,s8,s1
           ((uint32_t)p[1] << 8) |
  10281c:	0194c503          	lbu	a0,25(s1)
    return ((uint32_t)p[0]) |
  102820:	0184c583          	lbu	a1,24(s1)
           ((uint32_t)p[2] << 16) |
  102824:	01a4c603          	lbu	a2,26(s1)
           ((uint32_t)p[3] << 24);
  102828:	01b4c683          	lbu	a3,27(s1)
           ((uint32_t)p[1] << 8) |
  10282c:	00851513          	slli	a0,a0,0x8
    return ((uint32_t)p[0]) |
  102830:	00b56533          	or	a0,a0,a1
           ((uint32_t)p[2] << 16) |
  102834:	01061613          	slli	a2,a2,0x10
    next &= 0x0FFFFFFFu;
  102838:	01c69693          	slli	a3,a3,0x1c
           ((uint32_t)p[1] << 8) |
  10283c:	00c56533          	or	a0,a0,a2
    next &= 0x0FFFFFFFu;
  102840:	0046d693          	srli	a3,a3,0x4
  102844:	00d564b3          	or	s1,a0,a3
    while (dir_cluster >= 2u &&
  102848:	ffe48513          	addi	a0,s1,-2
  10284c:	02412583          	lw	a1,36(sp)
  102850:	e6b560e3          	bltu	a0,a1,1026b0 <boot_fat32_find+0x1fc>

        dir_cluster = boot_fat32_next_cluster(dir_cluster);
    }

    s_printf("FAT32: not found\n");
  102854:	00103537          	lui	a0,0x103
  102858:	76750513          	addi	a0,a0,1895 # 103767 <print_hex8.HEX+0x46d>
  10285c:	00c0006f          	j	102868 <boot_fat32_find+0x3b4>
                    s_printf("FAT32: dir end\n");
  102860:	00103537          	lui	a0,0x103
  102864:	72e50513          	addi	a0,a0,1838 # 10372e <print_hex8.HEX+0x434>
  102868:	ffffe097          	auipc	ra,0xffffe
  10286c:	59c080e7          	jalr	1436(ra) # 100e04 <s_printf>
  102870:	fff00513          	li	a0,-1

    return -1;
}
  102874:	07c12083          	lw	ra,124(sp)
  102878:	07812403          	lw	s0,120(sp)
  10287c:	07412483          	lw	s1,116(sp)
  102880:	07012903          	lw	s2,112(sp)
  102884:	06c12983          	lw	s3,108(sp)
  102888:	06812a03          	lw	s4,104(sp)
  10288c:	06412a83          	lw	s5,100(sp)
  102890:	06012b03          	lw	s6,96(sp)
  102894:	05c12b83          	lw	s7,92(sp)
  102898:	05812c03          	lw	s8,88(sp)
  10289c:	05412c83          	lw	s9,84(sp)
  1028a0:	05012d03          	lw	s10,80(sp)
  1028a4:	04c12d83          	lw	s11,76(sp)
  1028a8:	08010113          	addi	sp,sp,128
  1028ac:	00008067          	ret
                s_printf("FAT32: read dir failed\n");
  1028b0:	00103537          	lui	a0,0x103
  1028b4:	70750513          	addi	a0,a0,1799 # 103707 <print_hex8.HEX+0x40d>
  1028b8:	fb1ff06f          	j	102868 <boot_fat32_find+0x3b4>
                    s_printf("FAT32: found\n");
  1028bc:	00103537          	lui	a0,0x103
  1028c0:	74c50513          	addi	a0,a0,1868 # 10374c <print_hex8.HEX+0x452>
  1028c4:	ffffe097          	auipc	ra,0xffffe
  1028c8:	540080e7          	jalr	1344(ra) # 100e04 <s_printf>
  1028cc:	00000513          	li	a0,0
           ((uint16_t)p[1] << 8);
  1028d0:	0129c583          	lbu	a1,18(s3)
    return (uint16_t)p[0] |
  1028d4:	0119c603          	lbu	a2,17(s3)
  1028d8:	0179c683          	lbu	a3,23(s3)
           ((uint16_t)p[1] << 8);
  1028dc:	0189c703          	lbu	a4,24(s3)
                    *cluster = (cl_hi << 16) | cl_lo;
  1028e0:	01859593          	slli	a1,a1,0x18
  1028e4:	01061613          	slli	a2,a2,0x10
    return (uint16_t)p[0] |
  1028e8:	00c5e5b3          	or	a1,a1,a2
           ((uint16_t)p[1] << 8);
  1028ec:	00871713          	slli	a4,a4,0x8
                    *cluster = (cl_hi << 16) | cl_lo;
  1028f0:	00e6e6b3          	or	a3,a3,a4
  1028f4:	00d5e5b3          	or	a1,a1,a3
  1028f8:	02c12603          	lw	a2,44(sp)
  1028fc:	00b62023          	sw	a1,0(a2)
           ((uint32_t)p[1] << 8) |
  102900:	01a9c583          	lbu	a1,26(s3)
           ((uint32_t)p[2] << 16) |
  102904:	01b9c603          	lbu	a2,27(s3)
           ((uint32_t)p[3] << 24);
  102908:	01c9c683          	lbu	a3,28(s3)
    return ((uint32_t)p[0]) |
  10290c:	0199c703          	lbu	a4,25(s3)
           ((uint32_t)p[1] << 8) |
  102910:	00859593          	slli	a1,a1,0x8
           ((uint32_t)p[2] << 16) |
  102914:	01061613          	slli	a2,a2,0x10
           ((uint32_t)p[3] << 24);
  102918:	01869693          	slli	a3,a3,0x18
    return ((uint32_t)p[0]) |
  10291c:	00e5e5b3          	or	a1,a1,a4
           ((uint32_t)p[1] << 8) |
  102920:	00d66633          	or	a2,a2,a3
           ((uint32_t)p[2] << 16) |
  102924:	00c5e5b3          	or	a1,a1,a2
  102928:	03012603          	lw	a2,48(sp)
                    *size    = rd32(&e[28]);
  10292c:	00b62023          	sw	a1,0(a2)
  102930:	f45ff06f          	j	102874 <boot_fat32_find+0x3c0>

00102934 <boot_fat32_load_file>:
int boot_fat32_load_file(
    const char *name,
    uint32_t dst_addr,
    uint32_t *loaded_size
)
{
  102934:	fb010113          	addi	sp,sp,-80
  102938:	04112623          	sw	ra,76(sp)
  10293c:	04812423          	sw	s0,72(sp)
  102940:	04912223          	sw	s1,68(sp)
  102944:	05212023          	sw	s2,64(sp)
  102948:	03312e23          	sw	s3,60(sp)
  10294c:	03412c23          	sw	s4,56(sp)
  102950:	03512a23          	sw	s5,52(sp)
  102954:	03612823          	sw	s6,48(sp)
  102958:	03712623          	sw	s7,44(sp)
  10295c:	03812423          	sw	s8,40(sp)
  102960:	03912223          	sw	s9,36(sp)
  102964:	03a12023          	sw	s10,32(sp)
  102968:	01b12e23          	sw	s11,28(sp)
  10296c:	00060913          	mv	s2,a2
  102970:	00058493          	mv	s1,a1
  102974:	00050413          	mv	s0,a0
    uint32_t cluster;
    uint32_t size;
    uint32_t remain;
    volatile uint8_t *dst;

    s_printf("FAT32: load enter\n");
  102978:	00103537          	lui	a0,0x103
  10297c:	77950513          	addi	a0,a0,1913 # 103779 <print_hex8.HEX+0x47f>
  102980:	ffffe097          	auipc	ra,0xffffe
  102984:	484080e7          	jalr	1156(ra) # 100e04 <s_printf>

    if (boot_fat32_find(name, &cluster, &size)) {
  102988:	01810593          	addi	a1,sp,24
  10298c:	01410613          	addi	a2,sp,20
  102990:	00040513          	mv	a0,s0
  102994:	00000097          	auipc	ra,0x0
  102998:	b20080e7          	jalr	-1248(ra) # 1024b4 <boot_fat32_find>
  10299c:	fff00413          	li	s0,-1
  1029a0:	04050a63          	beqz	a0,1029f4 <boot_fat32_load_file+0xc0>
  1029a4:	00103537          	lui	a0,0x103
  1029a8:	78c50513          	addi	a0,a0,1932 # 10378c <print_hex8.HEX+0x492>
  1029ac:	ffffe097          	auipc	ra,0xffffe
  1029b0:	458080e7          	jalr	1112(ra) # 100e04 <s_printf>
        *loaded_size = size;

    s_printf("FAT32: load done\n");

    return 0;
}
  1029b4:	00040513          	mv	a0,s0
  1029b8:	04c12083          	lw	ra,76(sp)
  1029bc:	04812403          	lw	s0,72(sp)
  1029c0:	04412483          	lw	s1,68(sp)
  1029c4:	04012903          	lw	s2,64(sp)
  1029c8:	03c12983          	lw	s3,60(sp)
  1029cc:	03812a03          	lw	s4,56(sp)
  1029d0:	03412a83          	lw	s5,52(sp)
  1029d4:	03012b03          	lw	s6,48(sp)
  1029d8:	02c12b83          	lw	s7,44(sp)
  1029dc:	02812c03          	lw	s8,40(sp)
  1029e0:	02412c83          	lw	s9,36(sp)
  1029e4:	02012d03          	lw	s10,32(sp)
  1029e8:	01c12d83          	lw	s11,28(sp)
  1029ec:	05010113          	addi	sp,sp,80
  1029f0:	00008067          	ret
    s_printf("FAT32: find ok\n");
  1029f4:	00103537          	lui	a0,0x103
  1029f8:	7a050513          	addi	a0,a0,1952 # 1037a0 <print_hex8.HEX+0x4a6>
  1029fc:	ffffe097          	auipc	ra,0xffffe
  102a00:	408080e7          	jalr	1032(ra) # 100e04 <s_printf>
    s_printf("FAT32: cluster=");
  102a04:	00103537          	lui	a0,0x103
  102a08:	7b050513          	addi	a0,a0,1968 # 1037b0 <print_hex8.HEX+0x4b6>
  102a0c:	ffffe097          	auipc	ra,0xffffe
  102a10:	3f8080e7          	jalr	1016(ra) # 100e04 <s_printf>
    s_print_int((int)cluster);
  102a14:	01812c03          	lw	s8,24(sp)
  102a18:	000c0513          	mv	a0,s8
  102a1c:	ffffe097          	auipc	ra,0xffffe
  102a20:	2f0080e7          	jalr	752(ra) # 100d0c <s_print_int>
    s_printf("\n");
  102a24:	00103a37          	lui	s4,0x103
  102a28:	38aa0a13          	addi	s4,s4,906 # 10338a <print_hex8.HEX+0x90>
  102a2c:	000a0513          	mv	a0,s4
  102a30:	ffffe097          	auipc	ra,0xffffe
  102a34:	3d4080e7          	jalr	980(ra) # 100e04 <s_printf>
    s_printf("FAT32: size=");
  102a38:	00103537          	lui	a0,0x103
  102a3c:	7c050513          	addi	a0,a0,1984 # 1037c0 <print_hex8.HEX+0x4c6>
  102a40:	ffffe097          	auipc	ra,0xffffe
  102a44:	3c4080e7          	jalr	964(ra) # 100e04 <s_printf>
    s_print_int((int)size);
  102a48:	01412983          	lw	s3,20(sp)
  102a4c:	00098513          	mv	a0,s3
  102a50:	ffffe097          	auipc	ra,0xffffe
  102a54:	2bc080e7          	jalr	700(ra) # 100d0c <s_print_int>
    s_printf("\n");
  102a58:	000a0513          	mv	a0,s4
  102a5c:	ffffe097          	auipc	ra,0xffffe
  102a60:	3a8080e7          	jalr	936(ra) # 100e04 <s_printf>
    if (size == 0u) {
  102a64:	00098c63          	beqz	s3,102a7c <boot_fat32_load_file+0x148>
  102a68:	00200513          	li	a0,2
    if (cluster < 2u) {
  102a6c:	00ac7e63          	bgeu	s8,a0,102a88 <boot_fat32_load_file+0x154>
  102a70:	00103537          	lui	a0,0x103
  102a74:	7df50513          	addi	a0,a0,2015 # 1037df <print_hex8.HEX+0x4e5>
        if (cluster < 2u) {
  102a78:	f35ff06f          	j	1029ac <boot_fat32_load_file+0x78>
  102a7c:	00103537          	lui	a0,0x103
  102a80:	7cd50513          	addi	a0,a0,1997 # 1037cd <print_hex8.HEX+0x4d3>
  102a84:	f29ff06f          	j	1029ac <boot_fat32_load_file+0x78>
  102a88:	01212423          	sw	s2,8(sp)
    s_printf("FAT32: remain set\n");
  102a8c:	00103537          	lui	a0,0x103
  102a90:	7fd50513          	addi	a0,a0,2045 # 1037fd <print_hex8.HEX+0x503>
  102a94:	ffffe097          	auipc	ra,0xffffe
  102a98:	370080e7          	jalr	880(ra) # 100e04 <s_printf>
        s_printf("FAT32: loop enter\n");
  102a9c:	00104537          	lui	a0,0x104
  102aa0:	81050513          	addi	a0,a0,-2032 # 103810 <print_hex8.HEX+0x516>
  102aa4:	ffffe097          	auipc	ra,0xffffe
  102aa8:	360080e7          	jalr	864(ra) # 100e04 <s_printf>
  102aac:	00104537          	lui	a0,0x104
  102ab0:	83650513          	addi	a0,a0,-1994 # 103836 <print_hex8.HEX+0x53c>
  102ab4:	100005b7          	lui	a1,0x10000
  102ab8:	00108bb7          	lui	s7,0x108
  102abc:	ba0b8b93          	addi	s7,s7,-1120 # 107ba0 <g_data_begin_lba>
  102ac0:	00104cb7          	lui	s9,0x104
  102ac4:	875c8c93          	addi	s9,s9,-1931 # 103875 <print_hex8.HEX+0x57b>
  102ac8:	00104d37          	lui	s10,0x104
  102acc:	8a7d0d13          	addi	s10,s10,-1881 # 1038a7 <print_hex8.HEX+0x5ad>
  102ad0:	00104db7          	lui	s11,0x104
  102ad4:	8bed8d93          	addi	s11,s11,-1858 # 1038be <print_hex8.HEX+0x5c4>
  102ad8:	ff758a13          	addi	s4,a1,-9 # ffffff7 <_stack_top+0xfef4037>
  102adc:	ff858593          	addi	a1,a1,-8
  102ae0:	00b12823          	sw	a1,16(sp)
  102ae4:	018b8593          	addi	a1,s7,24
  102ae8:	00b12623          	sw	a1,12(sp)
  102aec:	0340006f          	j	102b20 <boot_fat32_load_file+0x1ec>
        cluster = boot_fat32_next_cluster(cluster);
  102af0:	01812c23          	sw	s8,24(sp)
        s_printf("FAT32: next cluster ok\n");
  102af4:	00104537          	lui	a0,0x104
  102af8:	8f950513          	addi	a0,a0,-1799 # 1038f9 <print_hex8.HEX+0x5ff>
  102afc:	ffffe097          	auipc	ra,0xffffe
  102b00:	308080e7          	jalr	776(ra) # 100e04 <s_printf>
        s_printf("FAT32: loop enter\n");
  102b04:	00104537          	lui	a0,0x104
  102b08:	81050513          	addi	a0,a0,-2032 # 103810 <print_hex8.HEX+0x516>
  102b0c:	ffffe097          	auipc	ra,0xffffe
  102b10:	2f8080e7          	jalr	760(ra) # 100e04 <s_printf>
  102b14:	00104537          	lui	a0,0x104
  102b18:	83650513          	addi	a0,a0,-1994 # 103836 <print_hex8.HEX+0x53c>
        if (cluster < 2u) {
  102b1c:	235c6063          	bltu	s8,s5,102d3c <boot_fat32_load_file+0x408>
        if (cluster == FAT32_BAD_CLUSTER) {
  102b20:	e94c06e3          	beq	s8,s4,1029ac <boot_fat32_load_file+0x78>
        if (cluster >= FAT32_EOC_MIN) {
  102b24:	218a6663          	bltu	s4,s8,102d30 <boot_fat32_load_file+0x3fc>
        s_printf("FAT32: calc lba\n");
  102b28:	00103537          	lui	a0,0x103
  102b2c:	6e550513          	addi	a0,a0,1765 # 1036e5 <print_hex8.HEX+0x3eb>
  102b30:	ffffe097          	auipc	ra,0xffffe
  102b34:	2d4080e7          	jalr	724(ra) # 100e04 <s_printf>
    if (g_sectors_per_cluster == 1u)   return 0u;
  102b38:	004ba583          	lw	a1,4(s7)
  102b3c:	fff58513          	addi	a0,a1,-1
  102b40:	03f00613          	li	a2,63
  102b44:	02a66463          	bltu	a2,a0,102b6c <boot_fat32_load_file+0x238>
  102b48:	00251513          	slli	a0,a0,0x2
  102b4c:	001045b7          	lui	a1,0x104
  102b50:	99458593          	addi	a1,a1,-1644 # 103994 <print_hex8.HEX+0x69a>
  102b54:	00a58533          	add	a0,a1,a0
  102b58:	00052583          	lw	a1,0(a0)
  102b5c:	00000513          	li	a0,0
  102b60:	00058067          	jr	a1
  102b64:	00100513          	li	a0,1
  102b68:	0540006f          	j	102bbc <boot_fat32_load_file+0x288>
  102b6c:	08000513          	li	a0,128
  102b70:	00a59663          	bne	a1,a0,102b7c <boot_fat32_load_file+0x248>
  102b74:	00700513          	li	a0,7
    if (g_sectors_per_cluster == 128u) return 7u;
  102b78:	0440006f          	j	102bbc <boot_fat32_load_file+0x288>
        s_printf("FAT32: bad spc shift\n");
  102b7c:	00104537          	lui	a0,0x104
  102b80:	97e50513          	addi	a0,a0,-1666 # 10397e <print_hex8.HEX+0x684>
  102b84:	ffffe097          	auipc	ra,0xffffe
  102b88:	280080e7          	jalr	640(ra) # 100e04 <s_printf>
        return g_data_begin_lba;
  102b8c:	00108537          	lui	a0,0x108
  102b90:	ba052a83          	lw	s5,-1120(a0) # 107ba0 <g_data_begin_lba>
  102b94:	03c0006f          	j	102bd0 <boot_fat32_load_file+0x29c>
  102b98:	00600513          	li	a0,6
    if (g_sectors_per_cluster == 64u)  return 6u;
  102b9c:	0200006f          	j	102bbc <boot_fat32_load_file+0x288>
  102ba0:	00200513          	li	a0,2
    if (g_sectors_per_cluster == 4u)   return 2u;
  102ba4:	0180006f          	j	102bbc <boot_fat32_load_file+0x288>
  102ba8:	00300513          	li	a0,3
    if (g_sectors_per_cluster == 8u)   return 3u;
  102bac:	0100006f          	j	102bbc <boot_fat32_load_file+0x288>
  102bb0:	00400513          	li	a0,4
    if (g_sectors_per_cluster == 16u)  return 4u;
  102bb4:	0080006f          	j	102bbc <boot_fat32_load_file+0x288>
  102bb8:	00500513          	li	a0,5
    return g_data_begin_lba + ((cluster - 2u) << shift);
  102bbc:	001085b7          	lui	a1,0x108
  102bc0:	ba05aa83          	lw	s5,-1120(a1) # 107ba0 <g_data_begin_lba>
  102bc4:	ffec0c13          	addi	s8,s8,-2
  102bc8:	00ac1533          	sll	a0,s8,a0
  102bcc:	00aa8ab3          	add	s5,s5,a0
        s_printf("FAT32: lba ok\n");
  102bd0:	00104537          	lui	a0,0x104
  102bd4:	86650513          	addi	a0,a0,-1946 # 103866 <print_hex8.HEX+0x56c>
  102bd8:	ffffe097          	auipc	ra,0xffffe
  102bdc:	22c080e7          	jalr	556(ra) # 100e04 <s_printf>
        for (uint32_t s = 0; s < g_sectors_per_cluster; s++) {
  102be0:	004ba503          	lw	a0,4(s7)
  102be4:	08050663          	beqz	a0,102c70 <boot_fat32_load_file+0x33c>
  102be8:	00000b13          	li	s6,0
  102bec:	00048913          	mv	s2,s1
            if (remain == 0u)
  102bf0:	0e098e63          	beqz	s3,102cec <boot_fat32_load_file+0x3b8>
            s_printf("FAT32: read file sector\n");
  102bf4:	000c8513          	mv	a0,s9
  102bf8:	ffffe097          	auipc	ra,0xffffe
  102bfc:	20c080e7          	jalr	524(ra) # 100e04 <s_printf>
            if (g_read_sector(lba + s, file_buf)) {
  102c00:	008ba603          	lw	a2,8(s7)
  102c04:	015b0533          	add	a0,s6,s5
  102c08:	218b8c13          	addi	s8,s7,536
  102c0c:	000c0593          	mv	a1,s8
  102c10:	000600e7          	jalr	a2
  102c14:	10051463          	bnez	a0,102d1c <boot_fat32_load_file+0x3e8>
            s_printf("FAT32: file sector ok\n");
  102c18:	000d0513          	mv	a0,s10
  102c1c:	ffffe097          	auipc	ra,0xffffe
  102c20:	1e8080e7          	jalr	488(ra) # 100e04 <s_printf>
  102c24:	20000593          	li	a1,512
  102c28:	00098513          	mv	a0,s3
            copy_size = (remain > 512u) ? 512u : remain;
  102c2c:	00b9e463          	bltu	s3,a1,102c34 <boot_fat32_load_file+0x300>
  102c30:	20000513          	li	a0,512
            for (uint32_t i = 0; i < copy_size; i++)
  102c34:	00a904b3          	add	s1,s2,a0
                dst[i] = file_buf[i];
  102c38:	000c4583          	lbu	a1,0(s8)
  102c3c:	00b90023          	sb	a1,0(s2)
            for (uint32_t i = 0; i < copy_size; i++)
  102c40:	00190913          	addi	s2,s2,1
  102c44:	001c0c13          	addi	s8,s8,1
  102c48:	fe9918e3          	bne	s2,s1,102c38 <boot_fat32_load_file+0x304>
            remain -= copy_size;
  102c4c:	40a989b3          	sub	s3,s3,a0
            s_printf("FAT32: copy ok\n");
  102c50:	000d8513          	mv	a0,s11
  102c54:	ffffe097          	auipc	ra,0xffffe
  102c58:	1b0080e7          	jalr	432(ra) # 100e04 <s_printf>
        for (uint32_t s = 0; s < g_sectors_per_cluster; s++) {
  102c5c:	004ba503          	lw	a0,4(s7)
  102c60:	001b0b13          	addi	s6,s6,1
  102c64:	00048913          	mv	s2,s1
  102c68:	f8ab64e3          	bltu	s6,a0,102bf0 <boot_fat32_load_file+0x2bc>
        if (remain == 0u) {
  102c6c:	08098063          	beqz	s3,102cec <boot_fat32_load_file+0x3b8>
        s_printf("FAT32: next cluster\n");
  102c70:	00104537          	lui	a0,0x104
  102c74:	8e450513          	addi	a0,a0,-1820 # 1038e4 <print_hex8.HEX+0x5ea>
  102c78:	ffffe097          	auipc	ra,0xffffe
  102c7c:	18c080e7          	jalr	396(ra) # 100e04 <s_printf>
        cluster = boot_fat32_next_cluster(cluster);
  102c80:	01812903          	lw	s2,24(sp)
  102c84:	01012c03          	lw	s8,16(sp)
  102c88:	00200a93          	li	s5,2
    if (cluster < 2u)
  102c8c:	e75962e3          	bltu	s2,s5,102af0 <boot_fat32_load_file+0x1bc>
    uint32_t fat_lba    = g_fat_begin_lba + (fat_offset / 512u);
  102c90:	014ba503          	lw	a0,20(s7)
    if (g_read_sector(fat_lba, fat32_buf))
  102c94:	008ba603          	lw	a2,8(s7)
  102c98:	00291913          	slli	s2,s2,0x2
    uint32_t fat_lba    = g_fat_begin_lba + (fat_offset / 512u);
  102c9c:	00995593          	srli	a1,s2,0x9
  102ca0:	00b50533          	add	a0,a0,a1
  102ca4:	00c12583          	lw	a1,12(sp)
    if (g_read_sector(fat_lba, fat32_buf))
  102ca8:	000600e7          	jalr	a2
  102cac:	01012c03          	lw	s8,16(sp)
  102cb0:	e40510e3          	bnez	a0,102af0 <boot_fat32_load_file+0x1bc>
  102cb4:	1fc97513          	andi	a0,s2,508
    next = rd32(&fat32_buf[ent_off]);
  102cb8:	00ab8533          	add	a0,s7,a0
           ((uint32_t)p[1] << 8) |
  102cbc:	01954583          	lbu	a1,25(a0)
    return ((uint32_t)p[0]) |
  102cc0:	01854603          	lbu	a2,24(a0)
           ((uint32_t)p[2] << 16) |
  102cc4:	01a54683          	lbu	a3,26(a0)
           ((uint32_t)p[3] << 24);
  102cc8:	01b54503          	lbu	a0,27(a0)
           ((uint32_t)p[1] << 8) |
  102ccc:	00859593          	slli	a1,a1,0x8
    return ((uint32_t)p[0]) |
  102cd0:	00c5e5b3          	or	a1,a1,a2
           ((uint32_t)p[2] << 16) |
  102cd4:	01069693          	slli	a3,a3,0x10
    next &= 0x0FFFFFFFu;
  102cd8:	01c51513          	slli	a0,a0,0x1c
           ((uint32_t)p[1] << 8) |
  102cdc:	00d5e5b3          	or	a1,a1,a3
    next &= 0x0FFFFFFFu;
  102ce0:	00455513          	srli	a0,a0,0x4
  102ce4:	00a5ec33          	or	s8,a1,a0
  102ce8:	e09ff06f          	j	102af0 <boot_fat32_load_file+0x1bc>
            s_printf("FAT32: file complete\n");
  102cec:	00104537          	lui	a0,0x104
  102cf0:	8ce50513          	addi	a0,a0,-1842 # 1038ce <print_hex8.HEX+0x5d4>
  102cf4:	ffffe097          	auipc	ra,0xffffe
  102cf8:	110080e7          	jalr	272(ra) # 100e04 <s_printf>
  102cfc:	00104537          	lui	a0,0x104
  102d00:	91150513          	addi	a0,a0,-1775 # 103911 <print_hex8.HEX+0x617>
  102d04:	00812603          	lw	a2,8(sp)
    if (loaded_size)
  102d08:	02060063          	beqz	a2,102d28 <boot_fat32_load_file+0x3f4>
  102d0c:	00000413          	li	s0,0
        *loaded_size = size;
  102d10:	01412583          	lw	a1,20(sp)
  102d14:	00b62023          	sw	a1,0(a2)
  102d18:	c95ff06f          	j	1029ac <boot_fat32_load_file+0x78>
  102d1c:	00104537          	lui	a0,0x104
  102d20:	88e50513          	addi	a0,a0,-1906 # 10388e <print_hex8.HEX+0x594>
        if (cluster < 2u) {
  102d24:	c89ff06f          	j	1029ac <boot_fat32_load_file+0x78>
  102d28:	00000413          	li	s0,0
    if (loaded_size)
  102d2c:	c81ff06f          	j	1029ac <boot_fat32_load_file+0x78>
  102d30:	00104537          	lui	a0,0x104
  102d34:	84a50513          	addi	a0,a0,-1974 # 10384a <print_hex8.HEX+0x550>
        if (cluster < 2u) {
  102d38:	c75ff06f          	j	1029ac <boot_fat32_load_file+0x78>
  102d3c:	00104537          	lui	a0,0x104
  102d40:	82350513          	addi	a0,a0,-2013 # 103823 <print_hex8.HEX+0x529>
  102d44:	c69ff06f          	j	1029ac <boot_fat32_load_file+0x78>

00102d48 <boot_fat32_load_mem_file>:
int boot_fat32_load_mem_file(
    const char *name,
    uint32_t dst_addr,
    uint32_t *loaded_words
)
{
  102d48:	fb010113          	addi	sp,sp,-80
  102d4c:	04112623          	sw	ra,76(sp)
  102d50:	04812423          	sw	s0,72(sp)
  102d54:	04912223          	sw	s1,68(sp)
  102d58:	05212023          	sw	s2,64(sp)
  102d5c:	03312e23          	sw	s3,60(sp)
  102d60:	03412c23          	sw	s4,56(sp)
  102d64:	03512a23          	sw	s5,52(sp)
  102d68:	03612823          	sw	s6,48(sp)
  102d6c:	03712623          	sw	s7,44(sp)
  102d70:	03812423          	sw	s8,40(sp)
  102d74:	03912223          	sw	s9,36(sp)
  102d78:	03a12023          	sw	s10,32(sp)
  102d7c:	01b12e23          	sw	s11,28(sp)
  102d80:	00060493          	mv	s1,a2
  102d84:	00058913          	mv	s2,a1
  102d88:	00050413          	mv	s0,a0
    volatile uint32_t *dst;
    uint32_t words;
    uint32_t hex_count;
    uint32_t word;

    s_printf("FAT32: load mem enter\n");
  102d8c:	00104537          	lui	a0,0x104
  102d90:	92350513          	addi	a0,a0,-1757 # 103923 <print_hex8.HEX+0x629>
  102d94:	ffffe097          	auipc	ra,0xffffe
  102d98:	070080e7          	jalr	112(ra) # 100e04 <s_printf>

    if (boot_fat32_find(name, &cluster, &size)) {
  102d9c:	01810593          	addi	a1,sp,24
  102da0:	01410613          	addi	a2,sp,20
  102da4:	00040513          	mv	a0,s0
  102da8:	fffff097          	auipc	ra,0xfffff
  102dac:	70c080e7          	jalr	1804(ra) # 1024b4 <boot_fat32_find>
  102db0:	fff00413          	li	s0,-1
  102db4:	04050c63          	beqz	a0,102e0c <boot_fat32_load_mem_file+0xc4>
  102db8:	00103937          	lui	s2,0x103
  102dbc:	78c90913          	addi	s2,s2,1932 # 10378c <print_hex8.HEX+0x492>
  102dc0:	00090513          	mv	a0,s2
  102dc4:	ffffe097          	auipc	ra,0xffffe
  102dc8:	040080e7          	jalr	64(ra) # 100e04 <s_printf>
        *loaded_words = words;

    s_printf("FAT32: load mem done\n");

    return 0;
  102dcc:	00040513          	mv	a0,s0
  102dd0:	04c12083          	lw	ra,76(sp)
  102dd4:	04812403          	lw	s0,72(sp)
  102dd8:	04412483          	lw	s1,68(sp)
  102ddc:	04012903          	lw	s2,64(sp)
  102de0:	03c12983          	lw	s3,60(sp)
  102de4:	03812a03          	lw	s4,56(sp)
  102de8:	03412a83          	lw	s5,52(sp)
  102dec:	03012b03          	lw	s6,48(sp)
  102df0:	02c12b83          	lw	s7,44(sp)
  102df4:	02812c03          	lw	s8,40(sp)
  102df8:	02412c83          	lw	s9,36(sp)
  102dfc:	02012d03          	lw	s10,32(sp)
  102e00:	01c12d83          	lw	s11,28(sp)
  102e04:	05010113          	addi	sp,sp,80
  102e08:	00008067          	ret
  102e0c:	01212823          	sw	s2,16(sp)
    s_printf("FAT32: find ok\n");
  102e10:	00103537          	lui	a0,0x103
  102e14:	7a050513          	addi	a0,a0,1952 # 1037a0 <print_hex8.HEX+0x4a6>
  102e18:	ffffe097          	auipc	ra,0xffffe
  102e1c:	fec080e7          	jalr	-20(ra) # 100e04 <s_printf>
    if (size == 0u) {
  102e20:	01412b83          	lw	s7,20(sp)
  102e24:	000b8e63          	beqz	s7,102e40 <boot_fat32_load_mem_file+0xf8>
    if (cluster < 2u) {
  102e28:	01812803          	lw	a6,24(sp)
  102e2c:	00200513          	li	a0,2
  102e30:	00a87e63          	bgeu	a6,a0,102e4c <boot_fat32_load_mem_file+0x104>
  102e34:	00103937          	lui	s2,0x103
  102e38:	7df90913          	addi	s2,s2,2015 # 1037df <print_hex8.HEX+0x4e5>
        if (cluster == FAT32_BAD_CLUSTER) {
  102e3c:	f85ff06f          	j	102dc0 <boot_fat32_load_mem_file+0x78>
  102e40:	00103937          	lui	s2,0x103
  102e44:	7cd90913          	addi	s2,s2,1997 # 1037cd <print_hex8.HEX+0x4d3>
  102e48:	f79ff06f          	j	102dc0 <boot_fat32_load_mem_file+0x78>
  102e4c:	00912023          	sw	s1,0(sp)
  102e50:	00000b13          	li	s6,0
  102e54:	00000c13          	li	s8,0
  102e58:	00000d13          	li	s10,0
  102e5c:	10000537          	lui	a0,0x10000
  102e60:	001086b7          	lui	a3,0x108
  102e64:	ba068693          	addi	a3,a3,-1120 # 107ba0 <g_data_begin_lba>
  102e68:	03f00613          	li	a2,63
  102e6c:	00108737          	lui	a4,0x108
  102e70:	00900a13          	li	s4,9
  102e74:	00800d93          	li	s11,8
  102e78:	01700493          	li	s1,23
  102e7c:	00800ab7          	lui	s5,0x800
  102e80:	00500c93          	li	s9,5
  102e84:	ff750793          	addi	a5,a0,-9 # ffffff7 <_stack_top+0xfef4037>
  102e88:	21868593          	addi	a1,a3,536
  102e8c:	013a8a93          	addi	s5,s5,19 # 800013 <_stack_top+0x6f4053>
  102e90:	001048b7          	lui	a7,0x104
  102e94:	a9488893          	addi	a7,a7,-1388 # 103a94 <print_hex8.HEX+0x79a>
  102e98:	00f12223          	sw	a5,4(sp)
  102e9c:	28f80663          	beq	a6,a5,103128 <boot_fat32_load_mem_file+0x3e0>
        if (cluster >= FAT32_EOC_MIN) {
  102ea0:	2907ec63          	bltu	a5,a6,103138 <boot_fat32_load_mem_file+0x3f0>
  102ea4:	01012423          	sw	a6,8(sp)
    if (g_sectors_per_cluster == 1u)   return 0u;
  102ea8:	0046a803          	lw	a6,4(a3)
  102eac:	fff80513          	addi	a0,a6,-1
  102eb0:	02a66063          	bltu	a2,a0,102ed0 <boot_fat32_load_mem_file+0x188>
  102eb4:	00251513          	slli	a0,a0,0x2
  102eb8:	00a88533          	add	a0,a7,a0
  102ebc:	00052603          	lw	a2,0(a0)
  102ec0:	00000513          	li	a0,0
  102ec4:	00060067          	jr	a2
  102ec8:	00100513          	li	a0,1
    if (g_sectors_per_cluster == 2u)   return 1u;
  102ecc:	0740006f          	j	102f40 <boot_fat32_load_mem_file+0x1f8>
    if (g_sectors_per_cluster == 1u)   return 0u;
  102ed0:	08000513          	li	a0,128
  102ed4:	00a81663          	bne	a6,a0,102ee0 <boot_fat32_load_mem_file+0x198>
  102ed8:	00700513          	li	a0,7
  102edc:	0640006f          	j	102f40 <boot_fat32_load_mem_file+0x1f8>
  102ee0:	00058993          	mv	s3,a1
  102ee4:	00108937          	lui	s2,0x108
  102ee8:	00068413          	mv	s0,a3
        s_printf("FAT32: bad spc shift\n");
  102eec:	00104537          	lui	a0,0x104
  102ef0:	97e50513          	addi	a0,a0,-1666 # 10397e <print_hex8.HEX+0x684>
  102ef4:	ffffe097          	auipc	ra,0xffffe
  102ef8:	f10080e7          	jalr	-240(ra) # 100e04 <s_printf>
        return g_data_begin_lba;
  102efc:	ba090513          	addi	a0,s2,-1120 # 107ba0 <g_data_begin_lba>
        for (uint32_t s = 0; s < g_sectors_per_cluster; s++) {
  102f00:	00452503          	lw	a0,4(a0)
  102f04:	12050c63          	beqz	a0,10303c <boot_fat32_load_mem_file+0x2f4>
  102f08:	ba092503          	lw	a0,-1120(s2)
  102f0c:	00a12623          	sw	a0,12(sp)
  102f10:	00040693          	mv	a3,s0
  102f14:	00098593          	mv	a1,s3
  102f18:	0400006f          	j	102f58 <boot_fat32_load_mem_file+0x210>
  102f1c:	00600513          	li	a0,6
  102f20:	0200006f          	j	102f40 <boot_fat32_load_mem_file+0x1f8>
  102f24:	00200513          	li	a0,2
    if (g_sectors_per_cluster == 4u)   return 2u;
  102f28:	0180006f          	j	102f40 <boot_fat32_load_mem_file+0x1f8>
  102f2c:	00300513          	li	a0,3
    if (g_sectors_per_cluster == 8u)   return 3u;
  102f30:	0100006f          	j	102f40 <boot_fat32_load_mem_file+0x1f8>
  102f34:	00400513          	li	a0,4
    if (g_sectors_per_cluster == 16u)  return 4u;
  102f38:	0080006f          	j	102f40 <boot_fat32_load_mem_file+0x1f8>
  102f3c:	00500513          	li	a0,5
    return g_data_begin_lba + ((cluster - 2u) << shift);
  102f40:	ba072703          	lw	a4,-1120(a4) # 107ba0 <g_data_begin_lba>
  102f44:	00812603          	lw	a2,8(sp)
  102f48:	ffe60613          	addi	a2,a2,-2
  102f4c:	00a61533          	sll	a0,a2,a0
  102f50:	00a70533          	add	a0,a4,a0
  102f54:	00a12623          	sw	a0,12(sp)
  102f58:	00000413          	li	s0,0
  102f5c:	0180006f          	j	102f74 <boot_fat32_load_mem_file+0x22c>
  102f60:	00090693          	mv	a3,s2
        for (uint32_t s = 0; s < g_sectors_per_cluster; s++) {
  102f64:	00492603          	lw	a2,4(s2)
  102f68:	00140413          	addi	s0,s0,1
  102f6c:	40ab8bb3          	sub	s7,s7,a0
  102f70:	0cc47263          	bgeu	s0,a2,103034 <boot_fat32_load_mem_file+0x2ec>
            if (remain == 0u)
  102f74:	160b8c63          	beqz	s7,1030ec <boot_fat32_load_mem_file+0x3a4>
  102f78:	00068913          	mv	s2,a3
            if (g_read_sector(lba + s, file_buf)) {
  102f7c:	0086a603          	lw	a2,8(a3)
  102f80:	00c12503          	lw	a0,12(sp)
  102f84:	00a40533          	add	a0,s0,a0
  102f88:	00058993          	mv	s3,a1
  102f8c:	000600e7          	jalr	a2
  102f90:	16051663          	bnez	a0,1030fc <boot_fat32_load_mem_file+0x3b4>
  102f94:	20000593          	li	a1,512
  102f98:	000b8513          	mv	a0,s7
            sector_bytes = (remain > 512u) ? 512u : remain;
  102f9c:	00bbe463          	bltu	s7,a1,102fa4 <boot_fat32_load_mem_file+0x25c>
  102fa0:	20000513          	li	a0,512
  102fa4:	00098593          	mv	a1,s3
  102fa8:	00098793          	mv	a5,s3
  102fac:	00050613          	mv	a2,a0
  102fb0:	01012803          	lw	a6,16(sp)
  102fb4:	0100006f          	j	102fc4 <boot_fat32_load_mem_file+0x27c>
            for (uint32_t i = 0; i < sector_bytes; i++) {
  102fb8:	fff60613          	addi	a2,a2,-1
  102fbc:	00178793          	addi	a5,a5,1
  102fc0:	fa0600e3          	beqz	a2,102f60 <boot_fat32_load_mem_file+0x218>
                char c = (char)file_buf[i];
  102fc4:	0007c683          	lbu	a3,0(a5)
    if (c >= '0' && c <= '9')
  102fc8:	fd068713          	addi	a4,a3,-48
  102fcc:	00ea7863          	bgeu	s4,a4,102fdc <boot_fat32_load_mem_file+0x294>
    if (c >= 'a' && c <= 'f')
  102fd0:	f9f68713          	addi	a4,a3,-97
  102fd4:	02ecec63          	bltu	s9,a4,10300c <boot_fat32_load_mem_file+0x2c4>
        return c - 'a' + 10;
  102fd8:	fa968713          	addi	a4,a3,-87
                if (h >= 0) {
  102fdc:	04074063          	bltz	a4,10301c <boot_fat32_load_mem_file+0x2d4>
                    word = (word << 4) | (uint32_t)h;
  102fe0:	004d1d13          	slli	s10,s10,0x4
                    hex_count++;
  102fe4:	001c0c13          	addi	s8,s8,1
                    word = (word << 4) | (uint32_t)h;
  102fe8:	01a76d33          	or	s10,a4,s10
                    if (hex_count == 8u) {
  102fec:	fdbc16e3          	bne	s8,s11,102fb8 <boot_fat32_load_mem_file+0x270>
  102ff0:	00000c13          	li	s8,0
                        dst[words] = word;
  102ff4:	002b1693          	slli	a3,s6,0x2
  102ff8:	00d806b3          	add	a3,a6,a3
  102ffc:	01a6a023          	sw	s10,0(a3)
                        words++;
  103000:	001b0b13          	addi	s6,s6,1
  103004:	00000d13          	li	s10,0
                    }
  103008:	fb1ff06f          	j	102fb8 <boot_fat32_load_mem_file+0x270>
    if (c >= 'A' && c <= 'F')
  10300c:	fbf68713          	addi	a4,a3,-65
  103010:	00ece663          	bltu	s9,a4,10301c <boot_fat32_load_mem_file+0x2d4>
  103014:	fc968713          	addi	a4,a3,-55
                if (h >= 0) {
  103018:	fc0754e3          	bgez	a4,102fe0 <boot_fat32_load_mem_file+0x298>
                    if (c == '\r' || c == '\n' || c == ' ' || c == '\t') {
  10301c:	ff768693          	addi	a3,a3,-9
  103020:	0cd4e063          	bltu	s1,a3,1030e0 <boot_fat32_load_mem_file+0x398>
  103024:	00dad6b3          	srl	a3,s5,a3
  103028:	0016f693          	andi	a3,a3,1
  10302c:	f80696e3          	bnez	a3,102fb8 <boot_fat32_load_mem_file+0x270>
  103030:	0b00006f          	j	1030e0 <boot_fat32_load_mem_file+0x398>
        if (remain == 0u)
  103034:	000b9663          	bnez	s7,103040 <boot_fat32_load_mem_file+0x2f8>
  103038:	0b40006f          	j	1030ec <boot_fat32_load_mem_file+0x3a4>
  10303c:	00040693          	mv	a3,s0
    uint32_t fat_lba    = g_fat_begin_lba + (fat_offset / 512u);
  103040:	0146a503          	lw	a0,20(a3)
    if (g_read_sector(fat_lba, fat32_buf))
  103044:	0086a603          	lw	a2,8(a3)
  103048:	00812903          	lw	s2,8(sp)
    uint32_t fat_lba    = g_fat_begin_lba + (fat_offset / 512u);
  10304c:	00795593          	srli	a1,s2,0x7
  103050:	00b50533          	add	a0,a0,a1
    if (g_read_sector(fat_lba, fat32_buf))
  103054:	01868593          	addi	a1,a3,24
  103058:	00068413          	mv	s0,a3
  10305c:	000600e7          	jalr	a2
  103060:	00050a63          	beqz	a0,103074 <boot_fat32_load_mem_file+0x32c>
  103064:	00040713          	mv	a4,s0
  103068:	10000537          	lui	a0,0x10000
  10306c:	ff850813          	addi	a6,a0,-8 # ffffff8 <_stack_top+0xfef4038>
  103070:	0400006f          	j	1030b0 <boot_fat32_load_mem_file+0x368>
    uint32_t ent_off    = fat_offset & 0x1FFu;
  103074:	01991513          	slli	a0,s2,0x19
  103078:	01755513          	srli	a0,a0,0x17
  10307c:	00040713          	mv	a4,s0
    next = rd32(&fat32_buf[ent_off]);
  103080:	00a40533          	add	a0,s0,a0
           ((uint32_t)p[1] << 8) |
  103084:	01954583          	lbu	a1,25(a0)
    return ((uint32_t)p[0]) |
  103088:	01854603          	lbu	a2,24(a0)
           ((uint32_t)p[2] << 16) |
  10308c:	01a54683          	lbu	a3,26(a0)
           ((uint32_t)p[3] << 24);
  103090:	01b54503          	lbu	a0,27(a0)
           ((uint32_t)p[1] << 8) |
  103094:	00859593          	slli	a1,a1,0x8
    return ((uint32_t)p[0]) |
  103098:	00c5e5b3          	or	a1,a1,a2
           ((uint32_t)p[2] << 16) |
  10309c:	01069693          	slli	a3,a3,0x10
    next &= 0x0FFFFFFFu;
  1030a0:	01c51513          	slli	a0,a0,0x1c
           ((uint32_t)p[1] << 8) |
  1030a4:	00d5e5b3          	or	a1,a1,a3
    next &= 0x0FFFFFFFu;
  1030a8:	00455513          	srli	a0,a0,0x4
  1030ac:	00a5e833          	or	a6,a1,a0
  1030b0:	00098593          	mv	a1,s3
  1030b4:	00200513          	li	a0,2
  1030b8:	00070693          	mv	a3,a4
  1030bc:	03f00613          	li	a2,63
  1030c0:	00108737          	lui	a4,0x108
  1030c4:	00412783          	lw	a5,4(sp)
  1030c8:	001048b7          	lui	a7,0x104
  1030cc:	a9488893          	addi	a7,a7,-1388 # 103a94 <print_hex8.HEX+0x79a>
        if (cluster < 2u) {
  1030d0:	dca876e3          	bgeu	a6,a0,102e9c <boot_fat32_load_mem_file+0x154>
  1030d4:	00104937          	lui	s2,0x104
  1030d8:	82390913          	addi	s2,s2,-2013 # 103823 <print_hex8.HEX+0x529>
  1030dc:	0280006f          	j	103104 <boot_fat32_load_mem_file+0x3bc>
  1030e0:	00104937          	lui	s2,0x104
  1030e4:	93a90913          	addi	s2,s2,-1734 # 10393a <print_hex8.HEX+0x640>
  1030e8:	01c0006f          	j	103104 <boot_fat32_load_mem_file+0x3bc>
    if (hex_count != 0u) {
  1030ec:	020c0063          	beqz	s8,10310c <boot_fat32_load_mem_file+0x3c4>
  1030f0:	00104937          	lui	s2,0x104
  1030f4:	94f90913          	addi	s2,s2,-1713 # 10394f <print_hex8.HEX+0x655>
  1030f8:	00c0006f          	j	103104 <boot_fat32_load_mem_file+0x3bc>
  1030fc:	00104937          	lui	s2,0x104
  103100:	88e90913          	addi	s2,s2,-1906 # 10388e <print_hex8.HEX+0x594>
  103104:	fff00413          	li	s0,-1
  103108:	cb9ff06f          	j	102dc0 <boot_fat32_load_mem_file+0x78>
  10310c:	00104937          	lui	s2,0x104
  103110:	96890913          	addi	s2,s2,-1688 # 103968 <print_hex8.HEX+0x66e>
  103114:	00012503          	lw	a0,0(sp)
    if (loaded_words)
  103118:	02050663          	beqz	a0,103144 <boot_fat32_load_mem_file+0x3fc>
  10311c:	00000413          	li	s0,0
        *loaded_words = words;
  103120:	01652023          	sw	s6,0(a0)
  103124:	c9dff06f          	j	102dc0 <boot_fat32_load_mem_file+0x78>
  103128:	fff00413          	li	s0,-1
  10312c:	00104937          	lui	s2,0x104
  103130:	83690913          	addi	s2,s2,-1994 # 103836 <print_hex8.HEX+0x53c>
        if (cluster == FAT32_BAD_CLUSTER) {
  103134:	c8dff06f          	j	102dc0 <boot_fat32_load_mem_file+0x78>
  103138:	00104937          	lui	s2,0x104
  10313c:	84a90913          	addi	s2,s2,-1974 # 10384a <print_hex8.HEX+0x550>
  103140:	fc5ff06f          	j	103104 <boot_fat32_load_mem_file+0x3bc>
  103144:	00000413          	li	s0,0
    if (loaded_words)
  103148:	c79ff06f          	j	102dc0 <boot_fat32_load_mem_file+0x78>

Disassembly of section .rodata:

0010314c <print_hex8.HEX-0x1ae>:
  10314c:	6f62                	.insn	2, 0x6f62
  10314e:	6f6c746f          	jal	s0,1ca844 <_stack_top+0xbe884>
  103152:	6461                	.insn	2, 0x6461
  103154:	7265                	.insn	2, 0x7265
  103156:	4620                	.insn	2, 0x4620
  103158:	5441                	.insn	2, 0x5441
  10315a:	73203233          	.insn	4, 0x73203233
  10315e:	6174                	.insn	2, 0x6174
  103160:	7472                	.insn	2, 0x7472
  103162:	000a                	.insn	2, 0x000a
  103164:	69204453          	.insn	4, 0x69204453
  103168:	696e                	.insn	2, 0x696e
  10316a:	2074                	.insn	2, 0x2074
  10316c:	6166                	.insn	2, 0x6166
  10316e:	6c69                	.insn	2, 0x6c69
  103170:	6465                	.insn	2, 0x6465
  103172:	000a                	.insn	2, 0x000a
  103174:	4146                	.insn	2, 0x4146
  103176:	3354                	.insn	2, 0x3354
  103178:	2032                	.insn	2, 0x2032
  10317a:	6f6d                	.insn	2, 0x6f6d
  10317c:	6e75                	.insn	2, 0x6e75
  10317e:	2074                	.insn	2, 0x2074
  103180:	6166                	.insn	2, 0x6166
  103182:	6c69                	.insn	2, 0x6c69
  103184:	6465                	.insn	2, 0x6465
  103186:	000a                	.insn	2, 0x000a
  103188:	4e52454b          	.insn	4, 0x4e52454b
  10318c:	4c45                	.insn	2, 0x4c45
  10318e:	4d2e                	.insn	2, 0x4d2e
  103190:	4d45                	.insn	2, 0x4d45
  103192:	4b00                	.insn	2, 0x4b00
  103194:	5245                	.insn	2, 0x5245
  103196:	454e                	.insn	2, 0x454e
  103198:	2e4c                	.insn	2, 0x2e4c
  10319a:	454d                	.insn	2, 0x454d
  10319c:	204d                	.insn	2, 0x204d
  10319e:	6f6c                	.insn	2, 0x6f6c
  1031a0:	6461                	.insn	2, 0x6461
  1031a2:	6620                	.insn	2, 0x6620
  1031a4:	6961                	.insn	2, 0x6961
  1031a6:	656c                	.insn	2, 0x656c
  1031a8:	0a64                	.insn	2, 0x0a64
  1031aa:	5500                	.insn	2, 0x5500
  1031ac:	2e524553          	.insn	4, 0x2e524553
  1031b0:	454d                	.insn	2, 0x454d
  1031b2:	004d                	.insn	2, 0x004d
  1031b4:	5355                	.insn	2, 0x5355
  1031b6:	5245                	.insn	2, 0x5245
  1031b8:	4d2e                	.insn	2, 0x4d2e
  1031ba:	4d45                	.insn	2, 0x4d45
  1031bc:	6c20                	.insn	2, 0x6c20
  1031be:	2064616f          	jal	sp,1493c4 <_stack_top+0x3d404>
  1031c2:	6166                	.insn	2, 0x6166
  1031c4:	6c69                	.insn	2, 0x6c69
  1031c6:	6465                	.insn	2, 0x6465
  1031c8:	000a                	.insn	2, 0x000a
  1031ca:	6e72656b          	.insn	4, 0x6e72656b
  1031ce:	6c65                	.insn	2, 0x6c65
  1031d0:	7720                	.insn	2, 0x7720
  1031d2:	7364726f          	jal	tp,14a908 <_stack_top+0x3e948>
  1031d6:	003d                	.insn	2, 0x003d
  1031d8:	7375                	.insn	2, 0x7375
  1031da:	7265                	.insn	2, 0x7265
  1031dc:	7720                	.insn	2, 0x7720
  1031de:	7364726f          	jal	tp,14a914 <_stack_top+0x3e954>
  1031e2:	003d                	.insn	2, 0x003d
  1031e4:	554a                	.insn	2, 0x554a
  1031e6:	504d                	.insn	2, 0x504d
  1031e8:	5420                	.insn	2, 0x5420
  1031ea:	6b00204f          	.insn	4, 0x6b00204f
  1031ee:	7265                	.insn	2, 0x7265
  1031f0:	656e                	.insn	2, 0x656e
  1031f2:	5b6c                	.insn	2, 0x5b6c
  1031f4:	5d30                	.insn	2, 0x5d30
  1031f6:	003d                	.insn	2, 0x003d
  1031f8:	6e72656b          	.insn	4, 0x6e72656b
  1031fc:	6c65                	.insn	2, 0x6c65
  1031fe:	3d5d315b          	.insn	4, 0x3d5d315b
  103202:	6b00                	.insn	2, 0x6b00
  103204:	7265                	.insn	2, 0x7265
  103206:	656e                	.insn	2, 0x656e
  103208:	5b6c                	.insn	2, 0x5b6c
  10320a:	5d32                	.insn	2, 0x5d32
  10320c:	003d                	.insn	2, 0x003d
  10320e:	7375                	.insn	2, 0x7375
  103210:	7265                	.insn	2, 0x7265
  103212:	3d5d305b          	.insn	4, 0x3d5d305b
  103216:	5300                	.insn	2, 0x5300
  103218:	2044                	.insn	2, 0x2044
  10321a:	4e49                	.insn	2, 0x4e49
  10321c:	5449                	.insn	2, 0x5449
  10321e:	7320                	.insn	2, 0x7320
  103220:	6174                	.insn	2, 0x6174
  103222:	7472                	.insn	2, 0x7472
  103224:	000a                	.insn	2, 0x000a
  103226:	49204453          	.insn	4, 0x49204453
  10322a:	494e                	.insn	2, 0x494e
  10322c:	2054                	.insn	2, 0x2054
  10322e:	4954                	.insn	2, 0x4954
  103230:	454d                	.insn	2, 0x454d
  103232:	0a54554f          	.insn	4, 0x0a54554f
  103236:	5300                	.insn	2, 0x5300
  103238:	2044                	.insn	2, 0x2044
  10323a:	4552                	.insn	2, 0x4552
  10323c:	4441                	.insn	2, 0x4441
  10323e:	5420                	.insn	2, 0x5420
  103240:	4d49                	.insn	2, 0x4d49
  103242:	4f45                	.insn	2, 0x4f45
  103244:	5455                	.insn	2, 0x5455
  103246:	6c20                	.insn	2, 0x6c20
  103248:	6162                	.insn	2, 0x6162
  10324a:	003d                	.insn	2, 0x003d
  10324c:	4946                	.insn	2, 0x4946
  10324e:	4f46                	.insn	2, 0x4f46
  103250:	4520                	.insn	2, 0x4520
  103252:	504d                	.insn	2, 0x504d
  103254:	5954                	.insn	2, 0x5954
  103256:	5420                	.insn	2, 0x5420
  103258:	4d49                	.insn	2, 0x4d49
  10325a:	4f45                	.insn	2, 0x4f45
  10325c:	5455                	.insn	2, 0x5455
  10325e:	6c20                	.insn	2, 0x6c20
  103260:	6162                	.insn	2, 0x6162
  103262:	003d                	.insn	2, 0x003d
  103264:	20435243          	.insn	4, 0x20435243
  103268:	474e                	.insn	2, 0x474e
  10326a:	6c20                	.insn	2, 0x6c20
  10326c:	6162                	.insn	2, 0x6162
  10326e:	003d                	.insn	2, 0x003d
  103270:	20435243          	.insn	4, 0x20435243
  103274:	4146                	.insn	2, 0x4146
  103276:	4c49                	.insn	2, 0x4c49
  103278:	4445                	.insn	2, 0x4445
  10327a:	6c20                	.insn	2, 0x6c20
  10327c:	6162                	.insn	2, 0x6162
  10327e:	003d                	.insn	2, 0x003d
  103280:	203a                	.insn	2, 0x203a
  103282:	7500                	.insn	2, 0x7500
  103284:	65676173          	csrrsi	sp,hviprio1h,14
  103288:	203a                	.insn	2, 0x203a
  10328a:	6d64                	.insn	2, 0x6d64
  10328c:	2070                	.insn	2, 0x2070
  10328e:	66666f5b          	.insn	4, 0x66666f5b
  103292:	5f746573          	csrrsi	a0,0x5f7,8
  103296:	6568                	.insn	2, 0x6568
  103298:	5d78                	.insn	2, 0x5d78
  10329a:	5b20                	.insn	2, 0x5b20
  10329c:	656c                	.insn	2, 0x656c
  10329e:	5f6e                	.insn	2, 0x5f6e
  1032a0:	6568                	.insn	2, 0x6568
  1032a2:	5d78                	.insn	2, 0x5d78
  1032a4:	000a                	.insn	2, 0x000a
  1032a6:	7375                	.insn	2, 0x7375
  1032a8:	6761                	.insn	2, 0x6761
  1032aa:	3a65                	.insn	2, 0x3a65
  1032ac:	6420                	.insn	2, 0x6420
  1032ae:	6d75                	.insn	2, 0x6d75
  1032b0:	2070                	.insn	2, 0x2070
  1032b2:	66666f5b          	.insn	4, 0x66666f5b
  1032b6:	5f746573          	csrrsi	a0,0x5f7,8
  1032ba:	6568                	.insn	2, 0x6568
  1032bc:	5d78                	.insn	2, 0x5d78
  1032be:	5b20                	.insn	2, 0x5b20
  1032c0:	656c                	.insn	2, 0x656c
  1032c2:	5f6e                	.insn	2, 0x5f6e
  1032c4:	6568                	.insn	2, 0x6568
  1032c6:	5d78                	.insn	2, 0x5d78
  1032c8:	000a                	.insn	2, 0x000a
  1032ca:	666e695b          	.insn	4, 0x666e695b
  1032ce:	6c205d6f          	jal	s10,108990 <_stack_start+0x9d0>
  1032d2:	6e65                	.insn	2, 0x6e65
  1032d4:	7420                	.insn	2, 0x7420
  1032d6:	62206f6f          	jal	t5,1098f8 <_stack_start+0x1938>
  1032da:	6769                	.insn	2, 0x6769
  1032dc:	2820                	.insn	2, 0x2820
  1032de:	303e                	.insn	2, 0x303e
  1032e0:	2578                	.insn	2, 0x2578
  1032e2:	2958                	.insn	2, 0x2958
  1032e4:	202c                	.insn	2, 0x202c
  1032e6:	6f72                	.insn	2, 0x6f72
  1032e8:	6e75                	.insn	2, 0x6e75
  1032ea:	2064                	.insn	2, 0x2064
  1032ec:	6f64                	.insn	2, 0x6f64
  1032ee:	74206e77          	.insn	4, 0x74206e77
  1032f2:	7830206f          	j	106274 <_stack+0x26d4>
  1032f6:	5825                	.insn	2, 0x5825
  1032f8:	000a                	.insn	2, 0x000a

001032fa <print_hex8.HEX>:
  1032fa:	3130                	.insn	2, 0x3130
  1032fc:	3332                	.insn	2, 0x3332
  1032fe:	3534                	.insn	2, 0x3534
  103300:	3736                	.insn	2, 0x3736
  103302:	3938                	.insn	2, 0x3938
  103304:	6261                	.insn	2, 0x6261
  103306:	66656463          	bltu	a0,t1,10396e <print_hex8.HEX+0x674>
  10330a:	5700                	.insn	2, 0x5700
  10330c:	4952                	.insn	2, 0x4952
  10330e:	4554                	.insn	2, 0x4554
  103310:	4620                	.insn	2, 0x4620
  103312:	4941                	.insn	2, 0x4941
  103314:	204c                	.insn	2, 0x204c
  103316:	6572                	.insn	2, 0x6572
  103318:	7274                	.insn	2, 0x7274
  10331a:	3d79                	.insn	2, 0x3d79
  10331c:	6425                	.insn	2, 0x6425
  10331e:	000a                	.insn	2, 0x000a
  103320:	4556                	.insn	2, 0x4556
  103322:	4952                	.insn	2, 0x4952
  103324:	5946                	.insn	2, 0x5946
  103326:	5220                	.insn	2, 0x5220
  103328:	4145                	.insn	2, 0x4145
  10332a:	2044                	.insn	2, 0x2044
  10332c:	5245                	.insn	2, 0x5245
  10332e:	4f52                	.insn	2, 0x4f52
  103330:	0a52                	.insn	2, 0x0a52
  103332:	5600                	.insn	2, 0x5600
  103334:	5245                	.insn	2, 0x5245
  103336:	4649                	.insn	2, 0x4649
  103338:	2059                	.insn	2, 0x2059
  10333a:	5245                	.insn	2, 0x5245
  10333c:	4f52                	.insn	2, 0x4f52
  10333e:	2052                	.insn	2, 0x2052
  103340:	74636573          	csrrsi	a0,0x746,6
  103344:	253d726f          	jal	tp,1dad96 <_stack_top+0xcedd6>
  103348:	2078                	.insn	2, 0x2078
  10334a:	7962                	.insn	2, 0x7962
  10334c:	6574                	.insn	2, 0x6574
  10334e:	253d                	.insn	2, 0x253d
  103350:	0a64                	.insn	2, 0x0a64
  103352:	5700                	.insn	2, 0x5700
  103354:	4952                	.insn	2, 0x4952
  103356:	4554                	.insn	2, 0x4554
  103358:	253d                	.insn	2, 0x253d
  10335a:	2078                	.insn	2, 0x2078
  10335c:	4552                	.insn	2, 0x4552
  10335e:	4441                	.insn	2, 0x4441
  103360:	253d                	.insn	2, 0x253d
  103362:	0a78                	.insn	2, 0x0a78
  103364:	5200                	.insn	2, 0x5200
  103366:	4145                	.insn	2, 0x4145
  103368:	2044                	.insn	2, 0x2044
  10336a:	4146                	.insn	2, 0x4146
  10336c:	4c49                	.insn	2, 0x4c49
  10336e:	7220                	.insn	2, 0x7220
  103370:	7465                	.insn	2, 0x7465
  103372:	7972                	.insn	2, 0x7972
  103374:	253d                	.insn	2, 0x253d
  103376:	0a64                	.insn	2, 0x0a64
  103378:	4300                	.insn	2, 0x4300
  10337a:	4352                	.insn	2, 0x4352
  10337c:	4f20                	.insn	2, 0x4f20
  10337e:	7228204b          	.insn	4, 0x7228204b
  103382:	7465                	.insn	2, 0x7465
  103384:	7972                	.insn	2, 0x7972
  103386:	253d                	.insn	2, 0x253d
  103388:	2964                	.insn	2, 0x2964
  10338a:	000a                	.insn	2, 0x000a
  10338c:	20435243          	.insn	4, 0x20435243
  103390:	474e                	.insn	2, 0x474e
  103392:	7220                	.insn	2, 0x7220
  103394:	7465                	.insn	2, 0x7465
  103396:	7972                	.insn	2, 0x7972
  103398:	253d                	.insn	2, 0x253d
  10339a:	2064                	.insn	2, 0x2064
  10339c:	6328                	.insn	2, 0x6328
  10339e:	6c61                	.insn	2, 0x6c61
  1033a0:	78253d63          	.insn	4, 0x78253d63
  1033a4:	6820                	.insn	2, 0x6820
  1033a6:	78253d77          	.insn	4, 0x78253d77
  1033aa:	0a29                	.insn	2, 0x0a29
  1033ac:	4300                	.insn	2, 0x4300
  1033ae:	4352                	.insn	2, 0x4352
  1033b0:	4620                	.insn	2, 0x4620
  1033b2:	4941                	.insn	2, 0x4941
  1033b4:	454c                	.insn	2, 0x454c
  1033b6:	2044                	.insn	2, 0x2044
  1033b8:	6628                	.insn	2, 0x6628
  1033ba:	6e69                	.insn	2, 0x6e69
  1033bc:	6c61                	.insn	2, 0x6c61
  1033be:	0a29                	.insn	2, 0x0a29
  1033c0:	3000                	.insn	2, 0x3000
  1033c2:	3231                	.insn	2, 0x3231
  1033c4:	36353433          	.insn	4, 0x36353433
  1033c8:	41393837          	lui	a6,0x41393
  1033cc:	4342                	.insn	2, 0x4342
  1033ce:	4544                	.insn	2, 0x4544
  1033d0:	0046                	.insn	2, 0x0046
  1033d2:	54495257          	.insn	4, 0x54495257
  1033d6:	2045                	.insn	2, 0x2045
  1033d8:	52415453          	.insn	4, 0x52415453
  1033dc:	0a54                	.insn	2, 0x0a54
  1033de:	5700                	.insn	2, 0x5700
  1033e0:	4952                	.insn	2, 0x4952
  1033e2:	4554                	.insn	2, 0x4554
  1033e4:	4520                	.insn	2, 0x4520
  1033e6:	444e                	.insn	2, 0x444e
  1033e8:	000a                	.insn	2, 0x000a
  1033ea:	54495257          	.insn	4, 0x54495257
  1033ee:	2045                	.insn	2, 0x2045
  1033f0:	5245                	.insn	2, 0x5245
  1033f2:	4f52                	.insn	2, 0x4f52
  1033f4:	0a52                	.insn	2, 0x0a52
  1033f6:	4600                	.insn	2, 0x4600
  1033f8:	5441                	.insn	2, 0x5441
  1033fa:	203a3233          	.insn	4, 0x203a3233
  1033fe:	206c3263          	.insn	4, 0x206c3263
  103402:	6162                	.insn	2, 0x6162
  103404:	0a64                	.insn	2, 0x0a64
  103406:	4600                	.insn	2, 0x4600
  103408:	5441                	.insn	2, 0x5441
  10340a:	203a3233          	.insn	4, 0x203a3233
  10340e:	6f6d                	.insn	2, 0x6f6d
  103410:	6e75                	.insn	2, 0x6e75
  103412:	2074                	.insn	2, 0x2074
  103414:	6e65                	.insn	2, 0x6e65
  103416:	6574                	.insn	2, 0x6574
  103418:	0a72                	.insn	2, 0x0a72
  10341a:	4600                	.insn	2, 0x4600
  10341c:	5441                	.insn	2, 0x5441
  10341e:	203a3233          	.insn	4, 0x203a3233
  103422:	6572                	.insn	2, 0x6572
  103424:	6461                	.insn	2, 0x6461
  103426:	735f 6365 6f74      	.insn	6, 0x6f746365735f
  10342c:	2072                	.insn	2, 0x2072
  10342e:	756e                	.insn	2, 0x756e
  103430:	6c6c                	.insn	2, 0x6c6c
  103432:	000a                	.insn	2, 0x000a
  103434:	4146                	.insn	2, 0x4146
  103436:	3354                	.insn	2, 0x3354
  103438:	3a32                	.insn	2, 0x3a32
  10343a:	7220                	.insn	2, 0x7220
  10343c:	6165                	.insn	2, 0x6165
  10343e:	2064                	.insn	2, 0x2064
  103440:	424c                	.insn	2, 0x424c
  103442:	3041                	.insn	2, 0x3041
  103444:	000a                	.insn	2, 0x000a
  103446:	4146                	.insn	2, 0x4146
  103448:	3354                	.insn	2, 0x3354
  10344a:	3a32                	.insn	2, 0x3a32
  10344c:	7220                	.insn	2, 0x7220
  10344e:	6165                	.insn	2, 0x6165
  103450:	2064                	.insn	2, 0x2064
  103452:	424c                	.insn	2, 0x424c
  103454:	3041                	.insn	2, 0x3041
  103456:	6620                	.insn	2, 0x6620
  103458:	6961                	.insn	2, 0x6961
  10345a:	656c                	.insn	2, 0x656c
  10345c:	0a64                	.insn	2, 0x0a64
  10345e:	4600                	.insn	2, 0x4600
  103460:	5441                	.insn	2, 0x5441
  103462:	203a3233          	.insn	4, 0x203a3233
  103466:	6572                	.insn	2, 0x6572
  103468:	6461                	.insn	2, 0x6461
  10346a:	4c20                	.insn	2, 0x4c20
  10346c:	4142                	.insn	2, 0x4142
  10346e:	2030                	.insn	2, 0x2030
  103470:	000a6b6f          	jal	s6,1a9470 <_stack_top+0x9d4b0>
  103474:	4146                	.insn	2, 0x4146
  103476:	3354                	.insn	2, 0x3354
  103478:	3a32                	.insn	2, 0x3a32
  10347a:	7320                	.insn	2, 0x7320
  10347c:	7075                	.insn	2, 0x7075
  10347e:	7265                	.insn	2, 0x7265
  103480:	6620                	.insn	2, 0x6620
  103482:	6f6c                	.insn	2, 0x6f6c
  103484:	7070                	.insn	2, 0x7070
  103486:	0a79                	.insn	2, 0x0a79
  103488:	4600                	.insn	2, 0x4600
  10348a:	5441                	.insn	2, 0x5441
  10348c:	203a3233          	.insn	4, 0x203a3233
  103490:	424d                	.insn	2, 0x424d
  103492:	2052                	.insn	2, 0x2052
  103494:	20676973          	csrrsi	s2,0x206,14
  103498:	6162                	.insn	2, 0x6162
  10349a:	0a64                	.insn	2, 0x0a64
  10349c:	4600                	.insn	2, 0x4600
  10349e:	5441                	.insn	2, 0x5441
  1034a0:	203a3233          	.insn	4, 0x203a3233
  1034a4:	6170                	.insn	2, 0x6170
  1034a6:	7472                	.insn	2, 0x7472
  1034a8:	6f20                	.insn	2, 0x6f20
  1034aa:	46000a6b          	.insn	4, 0x46000a6b
  1034ae:	5441                	.insn	2, 0x5441
  1034b0:	203a3233          	.insn	4, 0x203a3233
  1034b4:	6170                	.insn	2, 0x6170
  1034b6:	7472                	.insn	2, 0x7472
  1034b8:	6c5f 6162 7a20      	.insn	6, 0x7a2061626c5f
  1034be:	7265                	.insn	2, 0x7265
  1034c0:	46000a6f          	jal	s4,103920 <print_hex8.HEX+0x626>
  1034c4:	5441                	.insn	2, 0x5441
  1034c6:	203a3233          	.insn	4, 0x203a3233
  1034ca:	6572                	.insn	2, 0x6572
  1034cc:	6461                	.insn	2, 0x6461
  1034ce:	4220                	.insn	2, 0x4220
  1034d0:	4250                	.insn	2, 0x4250
  1034d2:	000a                	.insn	2, 0x000a
  1034d4:	4146                	.insn	2, 0x4146
  1034d6:	3354                	.insn	2, 0x3354
  1034d8:	3a32                	.insn	2, 0x3a32
  1034da:	7220                	.insn	2, 0x7220
  1034dc:	6165                	.insn	2, 0x6165
  1034de:	2064                	.insn	2, 0x2064
  1034e0:	5042                	.insn	2, 0x5042
  1034e2:	2042                	.insn	2, 0x2042
  1034e4:	6166                	.insn	2, 0x6166
  1034e6:	6c69                	.insn	2, 0x6c69
  1034e8:	6465                	.insn	2, 0x6465
  1034ea:	000a                	.insn	2, 0x000a
  1034ec:	4146                	.insn	2, 0x4146
  1034ee:	3354                	.insn	2, 0x3354
  1034f0:	3a32                	.insn	2, 0x3a32
  1034f2:	7220                	.insn	2, 0x7220
  1034f4:	6165                	.insn	2, 0x6165
  1034f6:	2064                	.insn	2, 0x2064
  1034f8:	5042                	.insn	2, 0x5042
  1034fa:	2042                	.insn	2, 0x2042
  1034fc:	000a6b6f          	jal	s6,1a94fc <_stack_top+0x9d53c>
  103500:	4146                	.insn	2, 0x4146
  103502:	3354                	.insn	2, 0x3354
  103504:	3a32                	.insn	2, 0x3a32
  103506:	4220                	.insn	2, 0x4220
  103508:	4250                	.insn	2, 0x4250
  10350a:	6920                	.insn	2, 0x6920
  10350c:	766e                	.insn	2, 0x766e
  10350e:	6c61                	.insn	2, 0x6c61
  103510:	6469                	.insn	2, 0x6469
  103512:	000a                	.insn	2, 0x000a
  103514:	4146                	.insn	2, 0x4146
  103516:	3354                	.insn	2, 0x3354
  103518:	3a32                	.insn	2, 0x3a32
  10351a:	4220                	.insn	2, 0x4220
  10351c:	4250                	.insn	2, 0x4250
  10351e:	7620                	.insn	2, 0x7620
  103520:	6c61                	.insn	2, 0x6c61
  103522:	6469                	.insn	2, 0x6469
  103524:	000a                	.insn	2, 0x000a
  103526:	4146                	.insn	2, 0x4146
  103528:	3354                	.insn	2, 0x3354
  10352a:	3a32                	.insn	2, 0x3a32
  10352c:	7020                	.insn	2, 0x7020
  10352e:	7261                	.insn	2, 0x7261
  103530:	31206573          	csrrsi	a0,medelegh,0
  103534:	000a                	.insn	2, 0x000a
  103536:	4146                	.insn	2, 0x4146
  103538:	3354                	.insn	2, 0x3354
  10353a:	3a32                	.insn	2, 0x3a32
  10353c:	7020                	.insn	2, 0x7020
  10353e:	7261                	.insn	2, 0x7261
  103540:	32206573          	csrrsi	a0,minstretcfg,0
  103544:	000a                	.insn	2, 0x000a
  103546:	4146                	.insn	2, 0x4146
  103548:	3354                	.insn	2, 0x3354
  10354a:	3a32                	.insn	2, 0x3a32
  10354c:	7020                	.insn	2, 0x7020
  10354e:	7261                	.insn	2, 0x7261
  103550:	33206573          	csrrsi	a0,mhpmevent18,0
  103554:	000a                	.insn	2, 0x000a
  103556:	4146                	.insn	2, 0x4146
  103558:	3354                	.insn	2, 0x3354
  10355a:	3a32                	.insn	2, 0x3a32
  10355c:	7020                	.insn	2, 0x7020
  10355e:	7261                	.insn	2, 0x7261
  103560:	34206573          	csrrsi	a0,mcause,0
  103564:	000a                	.insn	2, 0x000a
  103566:	4146                	.insn	2, 0x4146
  103568:	3354                	.insn	2, 0x3354
  10356a:	3a32                	.insn	2, 0x3a32
  10356c:	7020                	.insn	2, 0x7020
  10356e:	7261                	.insn	2, 0x7261
  103570:	35206573          	csrrsi	a0,mireg2,0
  103574:	000a                	.insn	2, 0x000a
  103576:	4146                	.insn	2, 0x4146
  103578:	3354                	.insn	2, 0x3354
  10357a:	3a32                	.insn	2, 0x3a32
  10357c:	7020                	.insn	2, 0x7020
  10357e:	7261                	.insn	2, 0x7261
  103580:	36206573          	csrrsi	a0,0x362,0
  103584:	000a                	.insn	2, 0x000a
  103586:	4146                	.insn	2, 0x4146
  103588:	3354                	.insn	2, 0x3354
  10358a:	3a32                	.insn	2, 0x3a32
  10358c:	7620                	.insn	2, 0x7620
  10358e:	6c61                	.insn	2, 0x6c61
  103590:	6469                	.insn	2, 0x6469
  103592:	7461                	.insn	2, 0x7461
  103594:	0a65                	.insn	2, 0x0a65
  103596:	4600                	.insn	2, 0x4600
  103598:	5441                	.insn	2, 0x5441
  10359a:	203a3233          	.insn	4, 0x203a3233
  10359e:	6162                	.insn	2, 0x6162
  1035a0:	2064                	.insn	2, 0x2064
  1035a2:	7062                	.insn	2, 0x7062
  1035a4:	46000a73          	.insn	4, 0x46000a73
  1035a8:	5441                	.insn	2, 0x5441
  1035aa:	203a3233          	.insn	4, 0x203a3233
  1035ae:	6162                	.insn	2, 0x6162
  1035b0:	2064                	.insn	2, 0x2064
  1035b2:	0a637073          	csrci	0xa6,6
  1035b6:	4600                	.insn	2, 0x4600
  1035b8:	5441                	.insn	2, 0x5441
  1035ba:	203a3233          	.insn	4, 0x203a3233
  1035be:	6162                	.insn	2, 0x6162
  1035c0:	2064                	.insn	2, 0x2064
  1035c2:	6572                	.insn	2, 0x6572
  1035c4:	76726573          	csrrsi	a0,0x767,4
  1035c8:	6465                	.insn	2, 0x6465
  1035ca:	000a                	.insn	2, 0x000a
  1035cc:	4146                	.insn	2, 0x4146
  1035ce:	3354                	.insn	2, 0x3354
  1035d0:	3a32                	.insn	2, 0x3a32
  1035d2:	6220                	.insn	2, 0x6220
  1035d4:	6461                	.insn	2, 0x6461
  1035d6:	6620                	.insn	2, 0x6620
  1035d8:	7461                	.insn	2, 0x7461
  1035da:	635f 756f 746e      	.insn	6, 0x746e756f635f
  1035e0:	000a                	.insn	2, 0x000a
  1035e2:	4146                	.insn	2, 0x4146
  1035e4:	3354                	.insn	2, 0x3354
  1035e6:	3a32                	.insn	2, 0x3a32
  1035e8:	6220                	.insn	2, 0x6220
  1035ea:	6461                	.insn	2, 0x6461
  1035ec:	6620                	.insn	2, 0x6620
  1035ee:	7461                	.insn	2, 0x7461
  1035f0:	735f 7a69 0a65      	.insn	6, 0x0a657a69735f
  1035f6:	4600                	.insn	2, 0x4600
  1035f8:	5441                	.insn	2, 0x5441
  1035fa:	203a3233          	.insn	4, 0x203a3233
  1035fe:	6162                	.insn	2, 0x6162
  103600:	2064                	.insn	2, 0x2064
  103602:	6f72                	.insn	2, 0x6f72
  103604:	635f746f          	jal	s0,1fb438 <_stack_top+0xef478>
  103608:	756c                	.insn	2, 0x756c
  10360a:	72657473          	csrrci	s0,mhpmevent6h,10
  10360e:	000a                	.insn	2, 0x000a
  103610:	4146                	.insn	2, 0x4146
  103612:	3354                	.insn	2, 0x3354
  103614:	3a32                	.insn	2, 0x3a32
  103616:	7220                	.insn	2, 0x7220
  103618:	20746f6f          	jal	t5,14a01e <_stack_top+0x3e05e>
  10361c:	63656863          	bltu	a0,s6,103c4c <_stack+0xac>
  103620:	46000a6b          	.insn	4, 0x46000a6b
  103624:	5441                	.insn	2, 0x5441
  103626:	203a3233          	.insn	4, 0x203a3233
  10362a:	6f72                	.insn	2, 0x6f72
  10362c:	6920746f          	jal	s0,10acbe <_stack_start+0x2cfe>
  103630:	0a322073          	csrs	0xa3,tp
  103634:	4600                	.insn	2, 0x4600
  103636:	5441                	.insn	2, 0x5441
  103638:	203a3233          	.insn	4, 0x203a3233
  10363c:	6f72                	.insn	2, 0x6f72
  10363e:	4e20746f          	jal	s0,10ab20 <_stack_start+0x2b60>
  103642:	3220544f          	.insn	4, 0x3220544f
  103646:	000a                	.insn	2, 0x000a
  103648:	4146                	.insn	2, 0x4146
  10364a:	3354                	.insn	2, 0x3354
  10364c:	3a32                	.insn	2, 0x3a32
  10364e:	6320                	.insn	2, 0x6320
  103650:	6c61                	.insn	2, 0x6c61
  103652:	61662063          	.insn	4, 0x61662063
  103656:	0a74                	.insn	2, 0x0a74
  103658:	4600                	.insn	2, 0x4600
  10365a:	5441                	.insn	2, 0x5441
  10365c:	203a3233          	.insn	4, 0x203a3233
  103660:	636c6163          	bltu	s8,s6,103c82 <_stack+0xe2>
  103664:	6420                	.insn	2, 0x6420
  103666:	7461                	.insn	2, 0x7461
  103668:	0a61                	.insn	2, 0x0a61
  10366a:	4600                	.insn	2, 0x4600
  10366c:	5441                	.insn	2, 0x5441
  10366e:	203a3233          	.insn	4, 0x203a3233
  103672:	6461                	.insn	2, 0x6461
  103674:	2064                	.insn	2, 0x2064
  103676:	6166                	.insn	2, 0x6166
  103678:	3174                	.insn	2, 0x3174
  10367a:	000a                	.insn	2, 0x000a
  10367c:	4146                	.insn	2, 0x4146
  10367e:	3354                	.insn	2, 0x3354
  103680:	3a32                	.insn	2, 0x3a32
  103682:	6120                	.insn	2, 0x6120
  103684:	6464                	.insn	2, 0x6464
  103686:	6620                	.insn	2, 0x6620
  103688:	7461                	.insn	2, 0x7461
  10368a:	0a32                	.insn	2, 0x0a32
  10368c:	4600                	.insn	2, 0x4600
  10368e:	5441                	.insn	2, 0x5441
  103690:	203a3233          	.insn	4, 0x203a3233
  103694:	6461                	.insn	2, 0x6461
  103696:	2064                	.insn	2, 0x2064
  103698:	6166                	.insn	2, 0x6166
  10369a:	3374                	.insn	2, 0x3374
  10369c:	000a                	.insn	2, 0x000a
  10369e:	4146                	.insn	2, 0x4146
  1036a0:	3354                	.insn	2, 0x3354
  1036a2:	3a32                	.insn	2, 0x3a32
  1036a4:	6120                	.insn	2, 0x6120
  1036a6:	6464                	.insn	2, 0x6464
  1036a8:	6620                	.insn	2, 0x6620
  1036aa:	7461                	.insn	2, 0x7461
  1036ac:	0a34                	.insn	2, 0x0a34
  1036ae:	4600                	.insn	2, 0x4600
  1036b0:	5441                	.insn	2, 0x5441
  1036b2:	203a3233          	.insn	4, 0x203a3233
  1036b6:	6f6d                	.insn	2, 0x6f6d
  1036b8:	6e75                	.insn	2, 0x6e75
  1036ba:	2074                	.insn	2, 0x2074
  1036bc:	000a6b6f          	jal	s6,1a96bc <_stack_top+0x9d6fc>
  1036c0:	4146                	.insn	2, 0x4146
  1036c2:	3354                	.insn	2, 0x3354
  1036c4:	3a32                	.insn	2, 0x3a32
  1036c6:	6620                	.insn	2, 0x6620
  1036c8:	6e69                	.insn	2, 0x6e69
  1036ca:	2064                	.insn	2, 0x2064
  1036cc:	6e65                	.insn	2, 0x6e65
  1036ce:	6574                	.insn	2, 0x6574
  1036d0:	0a72                	.insn	2, 0x0a72
  1036d2:	4600                	.insn	2, 0x4600
  1036d4:	5441                	.insn	2, 0x5441
  1036d6:	203a3233          	.insn	4, 0x203a3233
  1036da:	6f72                	.insn	2, 0x6f72
  1036dc:	6c20746f          	jal	s0,10ad9e <_stack_start+0x2dde>
  1036e0:	0a706f6f          	jal	t5,109f86 <_stack_start+0x1fc6>
  1036e4:	4600                	.insn	2, 0x4600
  1036e6:	5441                	.insn	2, 0x5441
  1036e8:	203a3233          	.insn	4, 0x203a3233
  1036ec:	636c6163          	bltu	s8,s6,103d0e <_stack+0x16e>
  1036f0:	6c20                	.insn	2, 0x6c20
  1036f2:	6162                	.insn	2, 0x6162
  1036f4:	000a                	.insn	2, 0x000a
  1036f6:	4146                	.insn	2, 0x4146
  1036f8:	3354                	.insn	2, 0x3354
  1036fa:	3a32                	.insn	2, 0x3a32
  1036fc:	7220                	.insn	2, 0x7220
  1036fe:	6165                	.insn	2, 0x6165
  103700:	2064                	.insn	2, 0x2064
  103702:	6964                	.insn	2, 0x6964
  103704:	0a72                	.insn	2, 0x0a72
  103706:	4600                	.insn	2, 0x4600
  103708:	5441                	.insn	2, 0x5441
  10370a:	203a3233          	.insn	4, 0x203a3233
  10370e:	6572                	.insn	2, 0x6572
  103710:	6461                	.insn	2, 0x6461
  103712:	6420                	.insn	2, 0x6420
  103714:	7269                	.insn	2, 0x7269
  103716:	6620                	.insn	2, 0x6620
  103718:	6961                	.insn	2, 0x6961
  10371a:	656c                	.insn	2, 0x656c
  10371c:	0a64                	.insn	2, 0x0a64
  10371e:	4600                	.insn	2, 0x4600
  103720:	5441                	.insn	2, 0x5441
  103722:	203a3233          	.insn	4, 0x203a3233
  103726:	6964                	.insn	2, 0x6964
  103728:	2072                	.insn	2, 0x2072
  10372a:	000a6b6f          	jal	s6,1a972a <_stack_top+0x9d76a>
  10372e:	4146                	.insn	2, 0x4146
  103730:	3354                	.insn	2, 0x3354
  103732:	3a32                	.insn	2, 0x3a32
  103734:	6420                	.insn	2, 0x6420
  103736:	7269                	.insn	2, 0x7269
  103738:	6520                	.insn	2, 0x6520
  10373a:	646e                	.insn	2, 0x646e
  10373c:	000a                	.insn	2, 0x000a
  10373e:	4146                	.insn	2, 0x4146
  103740:	3354                	.insn	2, 0x3354
  103742:	3a32                	.insn	2, 0x3a32
  103744:	6520                	.insn	2, 0x6520
  103746:	746e                	.insn	2, 0x746e
  103748:	7972                	.insn	2, 0x7972
  10374a:	000a                	.insn	2, 0x000a
  10374c:	4146                	.insn	2, 0x4146
  10374e:	3354                	.insn	2, 0x3354
  103750:	3a32                	.insn	2, 0x3a32
  103752:	6620                	.insn	2, 0x6620
  103754:	646e756f          	jal	a0,1ead9a <_stack_top+0xdedda>
  103758:	000a                	.insn	2, 0x000a
  10375a:	4146                	.insn	2, 0x4146
  10375c:	3354                	.insn	2, 0x3354
  10375e:	3a32                	.insn	2, 0x3a32
  103760:	6e20                	.insn	2, 0x6e20
  103762:	7865                	.insn	2, 0x7865
  103764:	0a74                	.insn	2, 0x0a74
  103766:	4600                	.insn	2, 0x4600
  103768:	5441                	.insn	2, 0x5441
  10376a:	203a3233          	.insn	4, 0x203a3233
  10376e:	6f6e                	.insn	2, 0x6f6e
  103770:	2074                	.insn	2, 0x2074
  103772:	6f66                	.insn	2, 0x6f66
  103774:	6e75                	.insn	2, 0x6e75
  103776:	0a64                	.insn	2, 0x0a64
  103778:	4600                	.insn	2, 0x4600
  10377a:	5441                	.insn	2, 0x5441
  10377c:	203a3233          	.insn	4, 0x203a3233
  103780:	6f6c                	.insn	2, 0x6f6c
  103782:	6461                	.insn	2, 0x6461
  103784:	6520                	.insn	2, 0x6520
  103786:	746e                	.insn	2, 0x746e
  103788:	7265                	.insn	2, 0x7265
  10378a:	000a                	.insn	2, 0x000a
  10378c:	4146                	.insn	2, 0x4146
  10378e:	3354                	.insn	2, 0x3354
  103790:	3a32                	.insn	2, 0x3a32
  103792:	6620                	.insn	2, 0x6620
  103794:	6e69                	.insn	2, 0x6e69
  103796:	2064                	.insn	2, 0x2064
  103798:	6166                	.insn	2, 0x6166
  10379a:	6c69                	.insn	2, 0x6c69
  10379c:	6465                	.insn	2, 0x6465
  10379e:	000a                	.insn	2, 0x000a
  1037a0:	4146                	.insn	2, 0x4146
  1037a2:	3354                	.insn	2, 0x3354
  1037a4:	3a32                	.insn	2, 0x3a32
  1037a6:	6620                	.insn	2, 0x6620
  1037a8:	6e69                	.insn	2, 0x6e69
  1037aa:	2064                	.insn	2, 0x2064
  1037ac:	000a6b6f          	jal	s6,1a97ac <_stack_top+0x9d7ec>
  1037b0:	4146                	.insn	2, 0x4146
  1037b2:	3354                	.insn	2, 0x3354
  1037b4:	3a32                	.insn	2, 0x3a32
  1037b6:	6320                	.insn	2, 0x6320
  1037b8:	756c                	.insn	2, 0x756c
  1037ba:	72657473          	csrrci	s0,mhpmevent6h,10
  1037be:	003d                	.insn	2, 0x003d
  1037c0:	4146                	.insn	2, 0x4146
  1037c2:	3354                	.insn	2, 0x3354
  1037c4:	3a32                	.insn	2, 0x3a32
  1037c6:	7320                	.insn	2, 0x7320
  1037c8:	7a69                	.insn	2, 0x7a69
  1037ca:	3d65                	.insn	2, 0x3d65
  1037cc:	4600                	.insn	2, 0x4600
  1037ce:	5441                	.insn	2, 0x5441
  1037d0:	203a3233          	.insn	4, 0x203a3233
  1037d4:	657a6973          	csrrsi	s2,hviprio2h,20
  1037d8:	7a20                	.insn	2, 0x7a20
  1037da:	7265                	.insn	2, 0x7265
  1037dc:	46000a6f          	jal	s4,103c3c <_stack+0x9c>
  1037e0:	5441                	.insn	2, 0x5441
  1037e2:	203a3233          	.insn	4, 0x203a3233
  1037e6:	6e69                	.insn	2, 0x6e69
  1037e8:	6176                	.insn	2, 0x6176
  1037ea:	696c                	.insn	2, 0x696c
  1037ec:	2064                	.insn	2, 0x2064
  1037ee:	72617473          	csrrci	s0,mhpmevent6h,2
  1037f2:	2074                	.insn	2, 0x2074
  1037f4:	73756c63          	bltu	a0,s7,103f2c <_stack+0x38c>
  1037f8:	6574                	.insn	2, 0x6574
  1037fa:	0a72                	.insn	2, 0x0a72
  1037fc:	4600                	.insn	2, 0x4600
  1037fe:	5441                	.insn	2, 0x5441
  103800:	203a3233          	.insn	4, 0x203a3233
  103804:	6572                	.insn	2, 0x6572
  103806:	616d                	.insn	2, 0x616d
  103808:	6e69                	.insn	2, 0x6e69
  10380a:	7320                	.insn	2, 0x7320
  10380c:	7465                	.insn	2, 0x7465
  10380e:	000a                	.insn	2, 0x000a
  103810:	4146                	.insn	2, 0x4146
  103812:	3354                	.insn	2, 0x3354
  103814:	3a32                	.insn	2, 0x3a32
  103816:	6c20                	.insn	2, 0x6c20
  103818:	20706f6f          	jal	t5,10a21e <_stack_start+0x225e>
  10381c:	6e65                	.insn	2, 0x6e65
  10381e:	6574                	.insn	2, 0x6574
  103820:	0a72                	.insn	2, 0x0a72
  103822:	4600                	.insn	2, 0x4600
  103824:	5441                	.insn	2, 0x5441
  103826:	203a3233          	.insn	4, 0x203a3233
  10382a:	73756c63          	bltu	a0,s7,103f62 <_stack+0x3c2>
  10382e:	6574                	.insn	2, 0x6574
  103830:	2072                	.insn	2, 0x2072
  103832:	323c                	.insn	2, 0x323c
  103834:	000a                	.insn	2, 0x000a
  103836:	4146                	.insn	2, 0x4146
  103838:	3354                	.insn	2, 0x3354
  10383a:	3a32                	.insn	2, 0x3a32
  10383c:	6220                	.insn	2, 0x6220
  10383e:	6461                	.insn	2, 0x6461
  103840:	6320                	.insn	2, 0x6320
  103842:	756c                	.insn	2, 0x756c
  103844:	72657473          	csrrci	s0,mhpmevent6h,10
  103848:	000a                	.insn	2, 0x000a
  10384a:	4146                	.insn	2, 0x4146
  10384c:	3354                	.insn	2, 0x3354
  10384e:	3a32                	.insn	2, 0x3a32
  103850:	4520                	.insn	2, 0x4520
  103852:	6220434f          	.insn	4, 0x6220434f
  103856:	6665                	.insn	2, 0x6665
  103858:	2065726f          	jal	tp,15aa5e <_stack_top+0x4ea9e>
  10385c:	706d6f63          	bltu	s10,t1,103f7a <_stack+0x3da>
  103860:	656c                	.insn	2, 0x656c
  103862:	6574                	.insn	2, 0x6574
  103864:	000a                	.insn	2, 0x000a
  103866:	4146                	.insn	2, 0x4146
  103868:	3354                	.insn	2, 0x3354
  10386a:	3a32                	.insn	2, 0x3a32
  10386c:	6c20                	.insn	2, 0x6c20
  10386e:	6162                	.insn	2, 0x6162
  103870:	6f20                	.insn	2, 0x6f20
  103872:	46000a6b          	.insn	4, 0x46000a6b
  103876:	5441                	.insn	2, 0x5441
  103878:	203a3233          	.insn	4, 0x203a3233
  10387c:	6572                	.insn	2, 0x6572
  10387e:	6461                	.insn	2, 0x6461
  103880:	6620                	.insn	2, 0x6620
  103882:	6c69                	.insn	2, 0x6c69
  103884:	2065                	.insn	2, 0x2065
  103886:	74636573          	csrrsi	a0,0x746,6
  10388a:	000a726f          	jal	tp,1aa88a <_stack_top+0x9e8ca>
  10388e:	4146                	.insn	2, 0x4146
  103890:	3354                	.insn	2, 0x3354
  103892:	3a32                	.insn	2, 0x3a32
  103894:	7220                	.insn	2, 0x7220
  103896:	6165                	.insn	2, 0x6165
  103898:	2064                	.insn	2, 0x2064
  10389a:	6966                	.insn	2, 0x6966
  10389c:	656c                	.insn	2, 0x656c
  10389e:	6620                	.insn	2, 0x6620
  1038a0:	6961                	.insn	2, 0x6961
  1038a2:	656c                	.insn	2, 0x656c
  1038a4:	0a64                	.insn	2, 0x0a64
  1038a6:	4600                	.insn	2, 0x4600
  1038a8:	5441                	.insn	2, 0x5441
  1038aa:	203a3233          	.insn	4, 0x203a3233
  1038ae:	6966                	.insn	2, 0x6966
  1038b0:	656c                	.insn	2, 0x656c
  1038b2:	7320                	.insn	2, 0x7320
  1038b4:	6365                	.insn	2, 0x6365
  1038b6:	6f74                	.insn	2, 0x6f74
  1038b8:	2072                	.insn	2, 0x2072
  1038ba:	000a6b6f          	jal	s6,1a98ba <_stack_top+0x9d8fa>
  1038be:	4146                	.insn	2, 0x4146
  1038c0:	3354                	.insn	2, 0x3354
  1038c2:	3a32                	.insn	2, 0x3a32
  1038c4:	6320                	.insn	2, 0x6320
  1038c6:	2079706f          	j	19b2cc <_stack_top+0x8f30c>
  1038ca:	000a6b6f          	jal	s6,1a98ca <_stack_top+0x9d90a>
  1038ce:	4146                	.insn	2, 0x4146
  1038d0:	3354                	.insn	2, 0x3354
  1038d2:	3a32                	.insn	2, 0x3a32
  1038d4:	6620                	.insn	2, 0x6620
  1038d6:	6c69                	.insn	2, 0x6c69
  1038d8:	2065                	.insn	2, 0x2065
  1038da:	706d6f63          	bltu	s10,t1,103ff8 <_stack+0x458>
  1038de:	656c                	.insn	2, 0x656c
  1038e0:	6574                	.insn	2, 0x6574
  1038e2:	000a                	.insn	2, 0x000a
  1038e4:	4146                	.insn	2, 0x4146
  1038e6:	3354                	.insn	2, 0x3354
  1038e8:	3a32                	.insn	2, 0x3a32
  1038ea:	6e20                	.insn	2, 0x6e20
  1038ec:	7865                	.insn	2, 0x7865
  1038ee:	2074                	.insn	2, 0x2074
  1038f0:	73756c63          	bltu	a0,s7,104028 <_stack+0x488>
  1038f4:	6574                	.insn	2, 0x6574
  1038f6:	0a72                	.insn	2, 0x0a72
  1038f8:	4600                	.insn	2, 0x4600
  1038fa:	5441                	.insn	2, 0x5441
  1038fc:	203a3233          	.insn	4, 0x203a3233
  103900:	656e                	.insn	2, 0x656e
  103902:	7478                	.insn	2, 0x7478
  103904:	6320                	.insn	2, 0x6320
  103906:	756c                	.insn	2, 0x756c
  103908:	72657473          	csrrci	s0,mhpmevent6h,10
  10390c:	6f20                	.insn	2, 0x6f20
  10390e:	46000a6b          	.insn	4, 0x46000a6b
  103912:	5441                	.insn	2, 0x5441
  103914:	203a3233          	.insn	4, 0x203a3233
  103918:	6f6c                	.insn	2, 0x6f6c
  10391a:	6461                	.insn	2, 0x6461
  10391c:	6420                	.insn	2, 0x6420
  10391e:	0a656e6f          	jal	t3,1599c4 <_stack_top+0x4da04>
  103922:	4600                	.insn	2, 0x4600
  103924:	5441                	.insn	2, 0x5441
  103926:	203a3233          	.insn	4, 0x203a3233
  10392a:	6f6c                	.insn	2, 0x6f6c
  10392c:	6461                	.insn	2, 0x6461
  10392e:	6d20                	.insn	2, 0x6d20
  103930:	6d65                	.insn	2, 0x6d65
  103932:	6520                	.insn	2, 0x6520
  103934:	746e                	.insn	2, 0x746e
  103936:	7265                	.insn	2, 0x7265
  103938:	000a                	.insn	2, 0x000a
  10393a:	4146                	.insn	2, 0x4146
  10393c:	3354                	.insn	2, 0x3354
  10393e:	3a32                	.insn	2, 0x3a32
  103940:	6220                	.insn	2, 0x6220
  103942:	6461                	.insn	2, 0x6461
  103944:	6d20                	.insn	2, 0x6d20
  103946:	6d65                	.insn	2, 0x6d65
  103948:	6320                	.insn	2, 0x6320
  10394a:	6168                	.insn	2, 0x6168
  10394c:	0a72                	.insn	2, 0x0a72
  10394e:	4600                	.insn	2, 0x4600
  103950:	5441                	.insn	2, 0x5441
  103952:	203a3233          	.insn	4, 0x203a3233
  103956:	6170                	.insn	2, 0x6170
  103958:	7472                	.insn	2, 0x7472
  10395a:	6169                	.insn	2, 0x6169
  10395c:	206c                	.insn	2, 0x206c
  10395e:	6568                	.insn	2, 0x6568
  103960:	2078                	.insn	2, 0x2078
  103962:	64726f77          	.insn	4, 0x64726f77
  103966:	000a                	.insn	2, 0x000a
  103968:	4146                	.insn	2, 0x4146
  10396a:	3354                	.insn	2, 0x3354
  10396c:	3a32                	.insn	2, 0x3a32
  10396e:	6c20                	.insn	2, 0x6c20
  103970:	2064616f          	jal	sp,149b76 <_stack_top+0x3dbb6>
  103974:	656d                	.insn	2, 0x656d
  103976:	206d                	.insn	2, 0x206d
  103978:	6f64                	.insn	2, 0x6f64
  10397a:	656e                	.insn	2, 0x656e
  10397c:	000a                	.insn	2, 0x000a
  10397e:	4146                	.insn	2, 0x4146
  103980:	3354                	.insn	2, 0x3354
  103982:	3a32                	.insn	2, 0x3a32
  103984:	6220                	.insn	2, 0x6220
  103986:	6461                	.insn	2, 0x6461
  103988:	7320                	.insn	2, 0x7320
  10398a:	6370                	.insn	2, 0x6370
  10398c:	7320                	.insn	2, 0x7320
  10398e:	6968                	.insn	2, 0x6968
  103990:	7466                	.insn	2, 0x7466
  103992:	000a                	.insn	2, 0x000a
  103994:	2bbc                	.insn	2, 0x2bbc
  103996:	0010                	.insn	2, 0x0010
  103998:	2b64                	.insn	2, 0x2b64
  10399a:	0010                	.insn	2, 0x0010
  10399c:	2b7c                	.insn	2, 0x2b7c
  10399e:	0010                	.insn	2, 0x0010
  1039a0:	2ba0                	.insn	2, 0x2ba0
  1039a2:	0010                	.insn	2, 0x0010
  1039a4:	2b7c                	.insn	2, 0x2b7c
  1039a6:	0010                	.insn	2, 0x0010
  1039a8:	2b7c                	.insn	2, 0x2b7c
  1039aa:	0010                	.insn	2, 0x0010
  1039ac:	2b7c                	.insn	2, 0x2b7c
  1039ae:	0010                	.insn	2, 0x0010
  1039b0:	2ba8                	.insn	2, 0x2ba8
  1039b2:	0010                	.insn	2, 0x0010
  1039b4:	2b7c                	.insn	2, 0x2b7c
  1039b6:	0010                	.insn	2, 0x0010
  1039b8:	2b7c                	.insn	2, 0x2b7c
  1039ba:	0010                	.insn	2, 0x0010
  1039bc:	2b7c                	.insn	2, 0x2b7c
  1039be:	0010                	.insn	2, 0x0010
  1039c0:	2b7c                	.insn	2, 0x2b7c
  1039c2:	0010                	.insn	2, 0x0010
  1039c4:	2b7c                	.insn	2, 0x2b7c
  1039c6:	0010                	.insn	2, 0x0010
  1039c8:	2b7c                	.insn	2, 0x2b7c
  1039ca:	0010                	.insn	2, 0x0010
  1039cc:	2b7c                	.insn	2, 0x2b7c
  1039ce:	0010                	.insn	2, 0x0010
  1039d0:	2bb0                	.insn	2, 0x2bb0
  1039d2:	0010                	.insn	2, 0x0010
  1039d4:	2b7c                	.insn	2, 0x2b7c
  1039d6:	0010                	.insn	2, 0x0010
  1039d8:	2b7c                	.insn	2, 0x2b7c
  1039da:	0010                	.insn	2, 0x0010
  1039dc:	2b7c                	.insn	2, 0x2b7c
  1039de:	0010                	.insn	2, 0x0010
  1039e0:	2b7c                	.insn	2, 0x2b7c
  1039e2:	0010                	.insn	2, 0x0010
  1039e4:	2b7c                	.insn	2, 0x2b7c
  1039e6:	0010                	.insn	2, 0x0010
  1039e8:	2b7c                	.insn	2, 0x2b7c
  1039ea:	0010                	.insn	2, 0x0010
  1039ec:	2b7c                	.insn	2, 0x2b7c
  1039ee:	0010                	.insn	2, 0x0010
  1039f0:	2b7c                	.insn	2, 0x2b7c
  1039f2:	0010                	.insn	2, 0x0010
  1039f4:	2b7c                	.insn	2, 0x2b7c
  1039f6:	0010                	.insn	2, 0x0010
  1039f8:	2b7c                	.insn	2, 0x2b7c
  1039fa:	0010                	.insn	2, 0x0010
  1039fc:	2b7c                	.insn	2, 0x2b7c
  1039fe:	0010                	.insn	2, 0x0010
  103a00:	2b7c                	.insn	2, 0x2b7c
  103a02:	0010                	.insn	2, 0x0010
  103a04:	2b7c                	.insn	2, 0x2b7c
  103a06:	0010                	.insn	2, 0x0010
  103a08:	2b7c                	.insn	2, 0x2b7c
  103a0a:	0010                	.insn	2, 0x0010
  103a0c:	2b7c                	.insn	2, 0x2b7c
  103a0e:	0010                	.insn	2, 0x0010
  103a10:	2bb8                	.insn	2, 0x2bb8
  103a12:	0010                	.insn	2, 0x0010
  103a14:	2b7c                	.insn	2, 0x2b7c
  103a16:	0010                	.insn	2, 0x0010
  103a18:	2b7c                	.insn	2, 0x2b7c
  103a1a:	0010                	.insn	2, 0x0010
  103a1c:	2b7c                	.insn	2, 0x2b7c
  103a1e:	0010                	.insn	2, 0x0010
  103a20:	2b7c                	.insn	2, 0x2b7c
  103a22:	0010                	.insn	2, 0x0010
  103a24:	2b7c                	.insn	2, 0x2b7c
  103a26:	0010                	.insn	2, 0x0010
  103a28:	2b7c                	.insn	2, 0x2b7c
  103a2a:	0010                	.insn	2, 0x0010
  103a2c:	2b7c                	.insn	2, 0x2b7c
  103a2e:	0010                	.insn	2, 0x0010
  103a30:	2b7c                	.insn	2, 0x2b7c
  103a32:	0010                	.insn	2, 0x0010
  103a34:	2b7c                	.insn	2, 0x2b7c
  103a36:	0010                	.insn	2, 0x0010
  103a38:	2b7c                	.insn	2, 0x2b7c
  103a3a:	0010                	.insn	2, 0x0010
  103a3c:	2b7c                	.insn	2, 0x2b7c
  103a3e:	0010                	.insn	2, 0x0010
  103a40:	2b7c                	.insn	2, 0x2b7c
  103a42:	0010                	.insn	2, 0x0010
  103a44:	2b7c                	.insn	2, 0x2b7c
  103a46:	0010                	.insn	2, 0x0010
  103a48:	2b7c                	.insn	2, 0x2b7c
  103a4a:	0010                	.insn	2, 0x0010
  103a4c:	2b7c                	.insn	2, 0x2b7c
  103a4e:	0010                	.insn	2, 0x0010
  103a50:	2b7c                	.insn	2, 0x2b7c
  103a52:	0010                	.insn	2, 0x0010
  103a54:	2b7c                	.insn	2, 0x2b7c
  103a56:	0010                	.insn	2, 0x0010
  103a58:	2b7c                	.insn	2, 0x2b7c
  103a5a:	0010                	.insn	2, 0x0010
  103a5c:	2b7c                	.insn	2, 0x2b7c
  103a5e:	0010                	.insn	2, 0x0010
  103a60:	2b7c                	.insn	2, 0x2b7c
  103a62:	0010                	.insn	2, 0x0010
  103a64:	2b7c                	.insn	2, 0x2b7c
  103a66:	0010                	.insn	2, 0x0010
  103a68:	2b7c                	.insn	2, 0x2b7c
  103a6a:	0010                	.insn	2, 0x0010
  103a6c:	2b7c                	.insn	2, 0x2b7c
  103a6e:	0010                	.insn	2, 0x0010
  103a70:	2b7c                	.insn	2, 0x2b7c
  103a72:	0010                	.insn	2, 0x0010
  103a74:	2b7c                	.insn	2, 0x2b7c
  103a76:	0010                	.insn	2, 0x0010
  103a78:	2b7c                	.insn	2, 0x2b7c
  103a7a:	0010                	.insn	2, 0x0010
  103a7c:	2b7c                	.insn	2, 0x2b7c
  103a7e:	0010                	.insn	2, 0x0010
  103a80:	2b7c                	.insn	2, 0x2b7c
  103a82:	0010                	.insn	2, 0x0010
  103a84:	2b7c                	.insn	2, 0x2b7c
  103a86:	0010                	.insn	2, 0x0010
  103a88:	2b7c                	.insn	2, 0x2b7c
  103a8a:	0010                	.insn	2, 0x0010
  103a8c:	2b7c                	.insn	2, 0x2b7c
  103a8e:	0010                	.insn	2, 0x0010
  103a90:	2b98                	.insn	2, 0x2b98
  103a92:	0010                	.insn	2, 0x0010
  103a94:	2f40                	.insn	2, 0x2f40
  103a96:	0010                	.insn	2, 0x0010
  103a98:	2ec8                	.insn	2, 0x2ec8
  103a9a:	0010                	.insn	2, 0x0010
  103a9c:	2ee0                	.insn	2, 0x2ee0
  103a9e:	0010                	.insn	2, 0x0010
  103aa0:	2f24                	.insn	2, 0x2f24
  103aa2:	0010                	.insn	2, 0x0010
  103aa4:	2ee0                	.insn	2, 0x2ee0
  103aa6:	0010                	.insn	2, 0x0010
  103aa8:	2ee0                	.insn	2, 0x2ee0
  103aaa:	0010                	.insn	2, 0x0010
  103aac:	2ee0                	.insn	2, 0x2ee0
  103aae:	0010                	.insn	2, 0x0010
  103ab0:	2f2c                	.insn	2, 0x2f2c
  103ab2:	0010                	.insn	2, 0x0010
  103ab4:	2ee0                	.insn	2, 0x2ee0
  103ab6:	0010                	.insn	2, 0x0010
  103ab8:	2ee0                	.insn	2, 0x2ee0
  103aba:	0010                	.insn	2, 0x0010
  103abc:	2ee0                	.insn	2, 0x2ee0
  103abe:	0010                	.insn	2, 0x0010
  103ac0:	2ee0                	.insn	2, 0x2ee0
  103ac2:	0010                	.insn	2, 0x0010
  103ac4:	2ee0                	.insn	2, 0x2ee0
  103ac6:	0010                	.insn	2, 0x0010
  103ac8:	2ee0                	.insn	2, 0x2ee0
  103aca:	0010                	.insn	2, 0x0010
  103acc:	2ee0                	.insn	2, 0x2ee0
  103ace:	0010                	.insn	2, 0x0010
  103ad0:	2f34                	.insn	2, 0x2f34
  103ad2:	0010                	.insn	2, 0x0010
  103ad4:	2ee0                	.insn	2, 0x2ee0
  103ad6:	0010                	.insn	2, 0x0010
  103ad8:	2ee0                	.insn	2, 0x2ee0
  103ada:	0010                	.insn	2, 0x0010
  103adc:	2ee0                	.insn	2, 0x2ee0
  103ade:	0010                	.insn	2, 0x0010
  103ae0:	2ee0                	.insn	2, 0x2ee0
  103ae2:	0010                	.insn	2, 0x0010
  103ae4:	2ee0                	.insn	2, 0x2ee0
  103ae6:	0010                	.insn	2, 0x0010
  103ae8:	2ee0                	.insn	2, 0x2ee0
  103aea:	0010                	.insn	2, 0x0010
  103aec:	2ee0                	.insn	2, 0x2ee0
  103aee:	0010                	.insn	2, 0x0010
  103af0:	2ee0                	.insn	2, 0x2ee0
  103af2:	0010                	.insn	2, 0x0010
  103af4:	2ee0                	.insn	2, 0x2ee0
  103af6:	0010                	.insn	2, 0x0010
  103af8:	2ee0                	.insn	2, 0x2ee0
  103afa:	0010                	.insn	2, 0x0010
  103afc:	2ee0                	.insn	2, 0x2ee0
  103afe:	0010                	.insn	2, 0x0010
  103b00:	2ee0                	.insn	2, 0x2ee0
  103b02:	0010                	.insn	2, 0x0010
  103b04:	2ee0                	.insn	2, 0x2ee0
  103b06:	0010                	.insn	2, 0x0010
  103b08:	2ee0                	.insn	2, 0x2ee0
  103b0a:	0010                	.insn	2, 0x0010
  103b0c:	2ee0                	.insn	2, 0x2ee0
  103b0e:	0010                	.insn	2, 0x0010
  103b10:	2f3c                	.insn	2, 0x2f3c
  103b12:	0010                	.insn	2, 0x0010
  103b14:	2ee0                	.insn	2, 0x2ee0
  103b16:	0010                	.insn	2, 0x0010
  103b18:	2ee0                	.insn	2, 0x2ee0
  103b1a:	0010                	.insn	2, 0x0010
  103b1c:	2ee0                	.insn	2, 0x2ee0
  103b1e:	0010                	.insn	2, 0x0010
  103b20:	2ee0                	.insn	2, 0x2ee0
  103b22:	0010                	.insn	2, 0x0010
  103b24:	2ee0                	.insn	2, 0x2ee0
  103b26:	0010                	.insn	2, 0x0010
  103b28:	2ee0                	.insn	2, 0x2ee0
  103b2a:	0010                	.insn	2, 0x0010
  103b2c:	2ee0                	.insn	2, 0x2ee0
  103b2e:	0010                	.insn	2, 0x0010
  103b30:	2ee0                	.insn	2, 0x2ee0
  103b32:	0010                	.insn	2, 0x0010
  103b34:	2ee0                	.insn	2, 0x2ee0
  103b36:	0010                	.insn	2, 0x0010
  103b38:	2ee0                	.insn	2, 0x2ee0
  103b3a:	0010                	.insn	2, 0x0010
  103b3c:	2ee0                	.insn	2, 0x2ee0
  103b3e:	0010                	.insn	2, 0x0010
  103b40:	2ee0                	.insn	2, 0x2ee0
  103b42:	0010                	.insn	2, 0x0010
  103b44:	2ee0                	.insn	2, 0x2ee0
  103b46:	0010                	.insn	2, 0x0010
  103b48:	2ee0                	.insn	2, 0x2ee0
  103b4a:	0010                	.insn	2, 0x0010
  103b4c:	2ee0                	.insn	2, 0x2ee0
  103b4e:	0010                	.insn	2, 0x0010
  103b50:	2ee0                	.insn	2, 0x2ee0
  103b52:	0010                	.insn	2, 0x0010
  103b54:	2ee0                	.insn	2, 0x2ee0
  103b56:	0010                	.insn	2, 0x0010
  103b58:	2ee0                	.insn	2, 0x2ee0
  103b5a:	0010                	.insn	2, 0x0010
  103b5c:	2ee0                	.insn	2, 0x2ee0
  103b5e:	0010                	.insn	2, 0x0010
  103b60:	2ee0                	.insn	2, 0x2ee0
  103b62:	0010                	.insn	2, 0x0010
  103b64:	2ee0                	.insn	2, 0x2ee0
  103b66:	0010                	.insn	2, 0x0010
  103b68:	2ee0                	.insn	2, 0x2ee0
  103b6a:	0010                	.insn	2, 0x0010
  103b6c:	2ee0                	.insn	2, 0x2ee0
  103b6e:	0010                	.insn	2, 0x0010
  103b70:	2ee0                	.insn	2, 0x2ee0
  103b72:	0010                	.insn	2, 0x0010
  103b74:	2ee0                	.insn	2, 0x2ee0
  103b76:	0010                	.insn	2, 0x0010
  103b78:	2ee0                	.insn	2, 0x2ee0
  103b7a:	0010                	.insn	2, 0x0010
  103b7c:	2ee0                	.insn	2, 0x2ee0
  103b7e:	0010                	.insn	2, 0x0010
  103b80:	2ee0                	.insn	2, 0x2ee0
  103b82:	0010                	.insn	2, 0x0010
  103b84:	2ee0                	.insn	2, 0x2ee0
  103b86:	0010                	.insn	2, 0x0010
  103b88:	2ee0                	.insn	2, 0x2ee0
  103b8a:	0010                	.insn	2, 0x0010
  103b8c:	2ee0                	.insn	2, 0x2ee0
  103b8e:	0010                	.insn	2, 0x0010
  103b90:	2f1c                	.insn	2, 0x2f1c
  103b92:	0010                	.insn	2, 0x0010

Disassembly of section .riscv.attributes:

00000000 <.riscv.attributes>:
   0:	3e41                	.insn	2, 0x3e41
   2:	0000                	.insn	2, 0x0000
   4:	7200                	.insn	2, 0x7200
   6:	7369                	.insn	2, 0x7369
   8:	01007663          	bgeu	zero,a6,14 <_start-0xfffec>
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

Disassembly of section .debug_info:

00000000 <.debug_info>:
       0:	00a0                	.insn	2, 0x00a0
       2:	0000                	.insn	2, 0x0000
       4:	0005                	.insn	2, 0x0005
       6:	0401                	.insn	2, 0x0401
       8:	0000                	.insn	2, 0x0000
       a:	0000                	.insn	2, 0x0000
       c:	0001                	.insn	2, 0x0001
       e:	0000                	.insn	2, 0x0000
      10:	0000                	.insn	2, 0x0000
      12:	1000                	.insn	2, 0x1000
      14:	1400                	.insn	2, 0x1400
      16:	1000                	.insn	2, 0x1000
      18:	2e00                	.insn	2, 0x2e00
      1a:	6372732f          	.insn	4, 0x6372732f
      1e:	6f6f622f          	.insn	4, 0x6f6f622f
      22:	6c74                	.insn	2, 0x6c74
      24:	6564616f          	jal	sp,4667a <_start-0xb9986>
      28:	5f72                	.insn	2, 0x5f72
      2a:	6e65                	.insn	2, 0x6e65
      2c:	7274                	.insn	2, 0x7274
      2e:	2e79                	.insn	2, 0x2e79
      30:	682f0053          	.insn	4, 0x682f0053
      34:	2f656d6f          	jal	s10,5632a <_start-0xa9cd6>
      38:	6168                	.insn	2, 0x6168
      3a:	7572                	.insn	2, 0x7572
      3c:	6968                	.insn	2, 0x6968
      3e:	502f6f6b          	.insn	4, 0x502f6f6b
      42:	6f72                	.insn	2, 0x6f72
      44:	6d617267          	.insn	4, 0x6d617267
      48:	4353502f          	.insn	4, 0x4353502f
      4c:	525f 3356 4932      	.insn	6, 0x49323356525f
      52:	4353502f          	.insn	4, 0x4353502f
      56:	4f2d                	.insn	2, 0x4f2d
      58:	454e                	.insn	2, 0x454e
      5a:	666f732f          	.insn	4, 0x666f732f
      5e:	7774                	.insn	2, 0x7774
      60:	7261                	.insn	2, 0x7261
      62:	2f65                	.insn	2, 0x2f65
      64:	5500736f          	jal	t1,75b4 <_start-0xf8a4c>
      68:	7562                	.insn	2, 0x7562
      6a:	746e                	.insn	2, 0x746e
      6c:	2075                	.insn	2, 0x2075
      6e:	6e616c63          	bltu	sp,t1,766 <_start-0xff89a>
      72:	65762067          	.insn	4, 0x65762067
      76:	7372                	.insn	2, 0x7372
      78:	6f69                	.insn	2, 0x6f69
      7a:	206e                	.insn	2, 0x206e
      7c:	3132                	.insn	2, 0x3132
      7e:	312e                	.insn	2, 0x312e
      80:	382e                	.insn	2, 0x382e
      82:	2820                	.insn	2, 0x2820
      84:	7536                	.insn	2, 0x7536
      86:	7562                	.insn	2, 0x7562
      88:	746e                	.insn	2, 0x746e
      8a:	3175                	.insn	2, 0x3175
      8c:	0029                	.insn	2, 0x0029
      8e:	8001                	.insn	2, 0x8001
      90:	7302                	.insn	2, 0x7302
      92:	6174                	.insn	2, 0x6174
      94:	7472                	.insn	2, 0x7472
      96:	0000                	.insn	2, 0x0000
      98:	0000                	.insn	2, 0x0000
      9a:	0a00                	.insn	2, 0x0a00
      9c:	0000                	.insn	2, 0x0000
      9e:	0000                	.insn	2, 0x0000
      a0:	1000                	.insn	2, 0x1000
      a2:	0000                	.insn	2, 0x0000
      a4:	0df6                	.insn	2, 0x0df6
      a6:	0000                	.insn	2, 0x0000
      a8:	0005                	.insn	2, 0x0005
      aa:	0401                	.insn	2, 0x0401
      ac:	0021                	.insn	2, 0x0021
      ae:	0000                	.insn	2, 0x0000
      b0:	0001                	.insn	2, 0x0001
      b2:	001d                	.insn	2, 0x001d
      b4:	0801                	.insn	2, 0x0801
      b6:	0000                	.insn	2, 0x0000
      b8:	4200                	.insn	2, 0x4200
      ba:	0000                	.insn	2, 0x0000
      bc:	0200                	.insn	2, 0x0200
      be:	8015                	.insn	2, 0x8015
      c0:	000c                	.insn	2, 0x000c
      c2:	0800                	.insn	2, 0x0800
      c4:	0000                	.insn	2, 0x0000
      c6:	0c00                	.insn	2, 0x0c00
      c8:	0000                	.insn	2, 0x0000
      ca:	0c00                	.insn	2, 0x0c00
      cc:	0000                	.insn	2, 0x0000
      ce:	0200                	.insn	2, 0x0200
      d0:	0729                	.insn	2, 0x0729
      d2:	0204                	.insn	2, 0x0204
      d4:	0728                	.insn	2, 0x0728
      d6:	0301                	.insn	2, 0x0301
      d8:	003d                	.insn	2, 0x003d
      da:	0000                	.insn	2, 0x0000
      dc:	de01                	.insn	2, 0xde01
      de:	a102                	.insn	2, 0xa102
      e0:	0400                	.insn	2, 0x0400
      e2:	0049                	.insn	2, 0x0049
      e4:	0000                	.insn	2, 0x0000
      e6:	4d05                	.insn	2, 0x4d05
      e8:	0000                	.insn	2, 0x0000
      ea:	1800                	.insn	2, 0x1800
      ec:	0200                	.insn	2, 0x0200
      ee:	06010803          	lb	a6,96(sp)
      f2:	0804                	.insn	2, 0x0804
      f4:	005b0307          	.insn	4, 0x005b0307
      f8:	0000                	.insn	2, 0x0000
      fa:	e101                	.insn	2, 0xe101
      fc:	a102                	.insn	2, 0xa102
      fe:	0401                	.insn	2, 0x0401
     100:	0049                	.insn	2, 0x0049
     102:	0000                	.insn	2, 0x0000
     104:	4d05                	.insn	2, 0x4d05
     106:	0000                	.insn	2, 0x0000
     108:	1000                	.insn	2, 0x1000
     10a:	0300                	.insn	2, 0x0300
     10c:	0071                	.insn	2, 0x0071
     10e:	0000                	.insn	2, 0x0000
     110:	e601                	.insn	2, 0xe601
     112:	a102                	.insn	2, 0xa102
     114:	0402                	.insn	2, 0x0402
     116:	0049                	.insn	2, 0x0049
     118:	0000                	.insn	2, 0x0000
     11a:	4d05                	.insn	2, 0x4d05
     11c:	0000                	.insn	2, 0x0000
     11e:	1400                	.insn	2, 0x1400
     120:	0300                	.insn	2, 0x0300
     122:	00000087          	.insn	4, 0x0087
     126:	ea01                	.insn	2, 0xea01
     128:	a102                	.insn	2, 0xa102
     12a:	00490403          	lb	s0,4(s2)
     12e:	0000                	.insn	2, 0x0000
     130:	4d05                	.insn	2, 0x4d05
     132:	0000                	.insn	2, 0x0000
     134:	0b00                	.insn	2, 0x0b00
     136:	0300                	.insn	2, 0x0300
     138:	003d                	.insn	2, 0x003d
     13a:	0000                	.insn	2, 0x0000
     13c:	eb01                	.insn	2, 0xeb01
     13e:	a102                	.insn	2, 0xa102
     140:	0304                	.insn	2, 0x0304
     142:	000000a7          	.insn	4, 0x00a7
     146:	ef01                	.insn	2, 0xef01
     148:	a102                	.insn	2, 0xa102
     14a:	0405                	.insn	2, 0x0405
     14c:	0049                	.insn	2, 0x0049
     14e:	0000                	.insn	2, 0x0000
     150:	4d05                	.insn	2, 0x4d05
     152:	0000                	.insn	2, 0x0000
     154:	0900                	.insn	2, 0x0900
     156:	0300                	.insn	2, 0x0300
     158:	00bd                	.insn	2, 0x00bd
     15a:	0000                	.insn	2, 0x0000
     15c:	f001                	.insn	2, 0xf001
     15e:	a102                	.insn	2, 0xa102
     160:	0406                	.insn	2, 0x0406
     162:	0049                	.insn	2, 0x0049
     164:	0000                	.insn	2, 0x0000
     166:	4d05                	.insn	2, 0x4d05
     168:	0000                	.insn	2, 0x0000
     16a:	1600                	.insn	2, 0x1600
     16c:	0300                	.insn	2, 0x0300
     16e:	000000d3          	.insn	4, 0x00d3
     172:	f401                	.insn	2, 0xf401
     174:	a102                	.insn	2, 0xa102
     176:	00490407          	.insn	4, 0x00490407
     17a:	0000                	.insn	2, 0x0000
     17c:	4d05                	.insn	2, 0x4d05
     17e:	0000                	.insn	2, 0x0000
     180:	0e00                	.insn	2, 0x0e00
     182:	0300                	.insn	2, 0x0300
     184:	00e9                	.insn	2, 0x00e9
     186:	0000                	.insn	2, 0x0000
     188:	f601                	.insn	2, 0xf601
     18a:	a102                	.insn	2, 0xa102
     18c:	0408                	.insn	2, 0x0408
     18e:	0049                	.insn	2, 0x0049
     190:	0000                	.insn	2, 0x0000
     192:	4d05                	.insn	2, 0x4d05
     194:	0000                	.insn	2, 0x0000
     196:	0200                	.insn	2, 0x0200
     198:	0300                	.insn	2, 0x0300
     19a:	00ff 0000 f801 a102 	.insn	10, 0x0409a102f801000000ff
     1a2:	0409 
     1a4:	0049                	.insn	2, 0x0049
     1a6:	0000                	.insn	2, 0x0000
     1a8:	4d05                	.insn	2, 0x4d05
     1aa:	0000                	.insn	2, 0x0000
     1ac:	0c00                	.insn	2, 0x0c00
     1ae:	0300                	.insn	2, 0x0300
     1b0:	000000a7          	.insn	4, 0x00a7
     1b4:	fc01                	.insn	2, 0xfc01
     1b6:	a102                	.insn	2, 0xa102
     1b8:	070a                	.insn	2, 0x070a
     1ba:	00000087          	.insn	4, 0x0087
     1be:	0001                	.insn	2, 0x0001
     1c0:	0201                	.insn	2, 0x0201
     1c2:	0ba1                	.insn	2, 0x0ba1
     1c4:	00008707          	.insn	4, 0x8707
     1c8:	0100                	.insn	2, 0x0100
     1ca:	0104                	.insn	2, 0x0104
     1cc:	a102                	.insn	2, 0xa102
     1ce:	070c                	.insn	2, 0x070c
     1d0:	00000087          	.insn	4, 0x0087
     1d4:	0801                	.insn	2, 0x0801
     1d6:	0201                	.insn	2, 0x0201
     1d8:	0da1                	.insn	2, 0x0da1
     1da:	0000a707          	.insn	4, 0xa707
     1de:	0100                	.insn	2, 0x0100
     1e0:	010c                	.insn	2, 0x010c
     1e2:	a102                	.insn	2, 0xa102
     1e4:	030e                	.insn	2, 0x030e
     1e6:	0000014b          	.insn	4, 0x014b
     1ea:	7701                	.insn	2, 0x7701
     1ec:	a102                	.insn	2, 0xa102
     1ee:	0049040f          	.insn	4, 0x0049040f
     1f2:	0000                	.insn	2, 0x0000
     1f4:	4d05                	.insn	2, 0x4d05
     1f6:	0000                	.insn	2, 0x0000
     1f8:	0f00                	.insn	2, 0x0f00
     1fa:	0300                	.insn	2, 0x0300
     1fc:	0161                	.insn	2, 0x0161
     1fe:	0000                	.insn	2, 0x0000
     200:	8101                	.insn	2, 0x8101
     202:	a102                	.insn	2, 0xa102
     204:	0410                	.insn	2, 0x0410
     206:	0049                	.insn	2, 0x0049
     208:	0000                	.insn	2, 0x0000
     20a:	4d05                	.insn	2, 0x4d05
     20c:	0000                	.insn	2, 0x0000
     20e:	1100                	.insn	2, 0x1100
     210:	0300                	.insn	2, 0x0300
     212:	00000177          	.insn	4, 0x0177
     216:	9d01                	.insn	2, 0x9d01
     218:	a102                	.insn	2, 0xa102
     21a:	0411                	.insn	2, 0x0411
     21c:	0049                	.insn	2, 0x0049
     21e:	0000                	.insn	2, 0x0000
     220:	4d05                	.insn	2, 0x4d05
     222:	0000                	.insn	2, 0x0000
     224:	1500                	.insn	2, 0x1500
     226:	0300                	.insn	2, 0x0300
     228:	003d                	.insn	2, 0x003d
     22a:	0000                	.insn	2, 0x0000
     22c:	ad01                	.insn	2, 0xad01
     22e:	a102                	.insn	2, 0xa102
     230:	0312                	.insn	2, 0x0312
     232:	00ff 0000 c001 a102 	.insn	10, 0x0813a102c001000000ff
     23a:	0813 
     23c:	019e                	.insn	2, 0x019e
     23e:	0000                	.insn	2, 0x0000
     240:	c201                	.insn	2, 0xc201
     242:	4904                	.insn	2, 0x4904
     244:	0000                	.insn	2, 0x0000
     246:	0500                	.insn	2, 0x0500
     248:	004d                	.insn	2, 0x004d
     24a:	0000                	.insn	2, 0x0000
     24c:	0005                	.insn	2, 0x0005
     24e:	9e08                	.insn	2, 0x9e08
     250:	0001                	.insn	2, 0x0001
     252:	0100                	.insn	2, 0x0100
     254:	03c4                	.insn	2, 0x03c4
     256:	0000005b          	.insn	4, 0x005b
     25a:	cc01                	.insn	2, 0xcc01
     25c:	a102                	.insn	2, 0xa102
     25e:	0914                	.insn	2, 0x0914
     260:	000001c3          	.insn	4, 0x01c3
     264:	0206                	.insn	2, 0x0206
     266:	0209                	.insn	2, 0x0209
     268:	0705                	.insn	2, 0x0705
     26a:	0904                	.insn	2, 0x0904
     26c:	000001cf          	.insn	4, 0x01cf
     270:	0208                	.insn	2, 0x0208
     272:	08070207          	.insn	4, 0x08070207
     276:	0a01                	.insn	2, 0x0a01
     278:	01d8                	.insn	2, 0x01d8
     27a:	0000                	.insn	2, 0x0000
     27c:	0001bb0b          	.insn	4, 0x0001bb0b
     280:	0900                	.insn	2, 0x0900
     282:	01e5                	.insn	2, 0x01e5
     284:	0000                	.insn	2, 0x0000
     286:	020a                	.insn	2, 0x020a
     288:	0208                	.insn	2, 0x0208
     28a:	0709                	.insn	2, 0x0709
     28c:	0a02                	.insn	2, 0x0a02
     28e:	01ee                	.insn	2, 0x01ee
     290:	0000                	.insn	2, 0x0000
     292:	0d0c                	.insn	2, 0x0d0c
     294:	bb20020b          	.insn	4, 0xbb20020b
     298:	0001                	.insn	2, 0x0001
     29a:	0e00                	.insn	2, 0x0e00
     29c:	020c                	.insn	2, 0x020c
     29e:	bb20                	.insn	2, 0xbb20
     2a0:	0001                	.insn	2, 0x0001
     2a2:	0000                	.insn	2, 0x0000
     2a4:	1d020d0f          	.insn	4, 0x1d020d0f
     2a8:	0c0e                	.insn	2, 0x0c0e
     2aa:	1d02                	.insn	2, 0x1d02
     2ac:	000001bb          	.insn	4, 0x01bb
     2b0:	0e0e                	.insn	2, 0x0e0e
     2b2:	1d02                	.insn	2, 0x1d02
     2b4:	000001bb          	.insn	4, 0x01bb
     2b8:	1000                	.insn	2, 0x1000
     2ba:	2015                	.insn	2, 0x2015
     2bc:	0000                	.insn	2, 0x0000
     2be:	0100                	.insn	2, 0x0100
     2c0:	6052                	.insn	2, 0x6052
     2c2:	0002                	.insn	2, 0x0002
     2c4:	1100                	.insn	2, 0x1100
     2c6:	5a01                	.insn	2, 0x5a01
     2c8:	0264                	.insn	2, 0x0264
     2ca:	0000                	.insn	2, 0x0000
     2cc:	ef12                	.insn	2, 0xef12
     2ce:	0001                	.insn	2, 0x0001
     2d0:	1600                	.insn	2, 0x1600
     2d2:	0004                	.insn	2, 0x0004
     2d4:	0000                	.insn	2, 0x0000
     2d6:	2d01                	.insn	2, 0x2d01
     2d8:	130c                	.insn	2, 0x130c
     2da:	8088                	.insn	2, 0x8088
     2dc:	8080                	.insn	2, 0x8080
     2de:	f701                	.insn	2, 0xf701
     2e0:	0001                	.insn	2, 0x0001
     2e2:	0000                	.insn	2, 0x0000
     2e4:	0012                	.insn	2, 0x0012
     2e6:	0002                	.insn	2, 0x0002
     2e8:	1700                	.insn	2, 0x1700
     2ea:	0004                	.insn	2, 0x0004
     2ec:	0000                	.insn	2, 0x0000
     2ee:	3101                	.insn	2, 0x3101
     2f0:	1305                	.insn	2, 0x1305
     2f2:	8080                	.insn	2, 0x8080
     2f4:	8080                	.insn	2, 0x8080
     2f6:	0401                	.insn	2, 0x0401
     2f8:	0002                	.insn	2, 0x0002
     2fa:	1100                	.insn	2, 0x1100
     2fc:	5a01                	.insn	2, 0x5a01
     2fe:	020c                	.insn	2, 0x020c
     300:	0000                	.insn	2, 0x0000
     302:	0000                	.insn	2, 0x0000
     304:	0f14                	.insn	2, 0x0f14
     306:	2b01                	.insn	2, 0x2b01
     308:	100e                	.insn	2, 0x100e
     30a:	2b01                	.insn	2, 0x2b01
     30c:	0049                	.insn	2, 0x0049
     30e:	0000                	.insn	2, 0x0000
     310:	1500                	.insn	2, 0x1500
     312:	2018                	.insn	2, 0x2018
     314:	0000                	.insn	2, 0x0000
     316:	0100                	.insn	2, 0x0100
     318:	2a52                	.insn	2, 0x2a52
     31a:	3401                	.insn	2, 0x3401
     31c:	0116                	.insn	2, 0x0116
     31e:	2d5a                	.insn	2, 0x2d5a
     320:	3401                	.insn	2, 0x3401
     322:	0049                	.insn	2, 0x0049
     324:	0000                	.insn	2, 0x0000
     326:	6012                	.insn	2, 0x6012
     328:	0002                	.insn	2, 0x0002
     32a:	1900                	.insn	2, 0x1900
     32c:	0018                	.insn	2, 0x0018
     32e:	0000                	.insn	2, 0x0000
     330:	3601                	.insn	2, 0x3601
     332:	1205                	.insn	2, 0x1205
     334:	000001ef          	jal	gp,334 <_start-0xffccc>
     338:	0419                	.insn	2, 0x0419
     33a:	0000                	.insn	2, 0x0000
     33c:	0100                	.insn	2, 0x0100
     33e:	0c2d                	.insn	2, 0x0c2d
     340:	80808813          	addi	a6,ra,-2040
     344:	0180                	.insn	2, 0x0180
     346:	000001f7          	.insn	4, 0x01f7
     34a:	1200                	.insn	2, 0x1200
     34c:	0200                	.insn	2, 0x0200
     34e:	0000                	.insn	2, 0x0000
     350:	041a                	.insn	2, 0x041a
     352:	0000                	.insn	2, 0x0000
     354:	0100                	.insn	2, 0x0100
     356:	0531                	.insn	2, 0x0531
     358:	80808013          	addi	zero,ra,-2040
     35c:	0180                	.insn	2, 0x0180
     35e:	0204                	.insn	2, 0x0204
     360:	0000                	.insn	2, 0x0000
     362:	0111                	.insn	2, 0x0111
     364:	0c5a                	.insn	2, 0x0c5a
     366:	0002                	.insn	2, 0x0002
     368:	0000                	.insn	2, 0x0000
     36a:	0000                	.insn	2, 0x0000
     36c:	3901110f          	.insn	4, 0x3901110f
     370:	120e                	.insn	2, 0x120e
     372:	3901                	.insn	2, 0x3901
     374:	02d5                	.insn	2, 0x02d5
     376:	0000                	.insn	2, 0x0000
     378:	0a00                	.insn	2, 0x0a00
     37a:	02da                	.insn	2, 0x02da
     37c:	0000                	.insn	2, 0x0000
     37e:	00004917          	auipc	s2,0x4
     382:	0d00                	.insn	2, 0x0d00
     384:	f0700113          	li	sp,-249
     388:	0002                	.insn	2, 0x0002
     38a:	1800                	.insn	2, 0x1800
     38c:	0115                	.insn	2, 0x0115
     38e:	bb72                	.insn	2, 0xbb72
     390:	0001                	.insn	2, 0x0001
     392:	0000                	.insn	2, 0x0000
     394:	1402                	.insn	2, 0x1402
     396:	0405                	.insn	2, 0x0405
     398:	4801160f          	.insn	4, 0x4801160f
     39c:	170e                	.insn	2, 0x170e
     39e:	4801                	.insn	2, 0x4801
     3a0:	000001c3          	.insn	4, 0x01c3
     3a4:	1900                	.insn	2, 0x1900
     3a6:	0118                	.insn	2, 0x0118
     3a8:	01190f4f          	.insn	4, 0x01190f4f
     3ac:	010c0ed3          	.insn	4, 0x010c0ed3
     3b0:	0001bbd3          	.insn	4, 0x0001bbd3
     3b4:	1800                	.insn	2, 0x1800
     3b6:	011a                	.insn	2, 0x011a
     3b8:	e9d5                	.insn	2, 0xe9d5
     3ba:	0001                	.insn	2, 0x0001
     3bc:	0000                	.insn	2, 0x0000
     3be:	1b15                	.insn	2, 0x1b15
     3c0:	03e4                	.insn	2, 0x03e4
     3c2:	0000                	.insn	2, 0x0000
     3c4:	5201                	.insn	2, 0x5201
     3c6:	1ad9012b          	.insn	4, 0x1ad9012b
     3ca:	9102                	.insn	2, 0x9102
     3cc:	2e0c                	.insn	2, 0x2e0c
     3ce:	db01                	.insn	2, 0xdb01
     3d0:	000001bb          	.insn	4, 0x01bb
     3d4:	021a                	.insn	2, 0x021a
     3d6:	0891                	.insn	2, 0x0891
     3d8:	bbdc012f          	.insn	4, 0xbbdc012f
     3dc:	0001                	.insn	2, 0x0001
     3de:	1200                	.insn	2, 0x1200
     3e0:	02c8                	.insn	2, 0x02c8
     3e2:	0000                	.insn	2, 0x0000
     3e4:	241c                	.insn	2, 0x241c
     3e6:	0000                	.insn	2, 0x0000
     3e8:	0100                	.insn	2, 0x0100
     3ea:	05de                	.insn	2, 0x05de
     3ec:	02cc001b          	.insn	4, 0x02cc001b
     3f0:	0000                	.insn	2, 0x0000
     3f2:	601c                	.insn	2, 0x601c
     3f4:	0002                	.insn	2, 0x0002
     3f6:	0000                	.insn	2, 0x0000
     3f8:	3c01                	.insn	2, 0x3c01
     3fa:	1d09                	.insn	2, 0x1d09
     3fc:	000001ef          	jal	gp,3fc <_start-0xffc04>
     400:	041d                	.insn	2, 0x041d
     402:	0000                	.insn	2, 0x0000
     404:	0100                	.insn	2, 0x0100
     406:	0c2d                	.insn	2, 0x0c2d
     408:	0012                	.insn	2, 0x0012
     40a:	0002                	.insn	2, 0x0002
     40c:	1e00                	.insn	2, 0x1e00
     40e:	0004                	.insn	2, 0x0004
     410:	0000                	.insn	2, 0x0000
     412:	3101                	.insn	2, 0x3101
     414:	1305                	.insn	2, 0x1305
     416:	8080                	.insn	2, 0x8080
     418:	8080                	.insn	2, 0x8080
     41a:	0401                	.insn	2, 0x0401
     41c:	0002                	.insn	2, 0x0002
     41e:	0000                	.insn	2, 0x0000
     420:	0000                	.insn	2, 0x0000
     422:	df1c                	.insn	2, 0xdf1c
     424:	0002                	.insn	2, 0x0002
     426:	0100                	.insn	2, 0x0100
     428:	e001                	.insn	2, 0xe001
     42a:	1e09                	.insn	2, 0x1e09
     42c:	e704                	.insn	2, 0xe704
     42e:	0002                	.insn	2, 0x0002
     430:	1200                	.insn	2, 0x1200
     432:	02f4                	.insn	2, 0x02f4
     434:	0000                	.insn	2, 0x0000
     436:	0c1f 0000 0100      	.insn	6, 0x010000000c1f
     43c:	0575                	.insn	2, 0x0575
     43e:	02f8011b          	.insn	4, 0x02f8011b
     442:	0000                	.insn	2, 0x0000
     444:	1200                	.insn	2, 0x1200
     446:	02c8                	.insn	2, 0x02c8
     448:	0000                	.insn	2, 0x0000
     44a:	2420                	.insn	2, 0x2420
     44c:	0000                	.insn	2, 0x0000
     44e:	0100                	.insn	2, 0x0100
     450:	021b0577          	.insn	4, 0x021b0577
     454:	02cc                	.insn	2, 0x02cc
     456:	0000                	.insn	2, 0x0000
     458:	601c                	.insn	2, 0x601c
     45a:	0002                	.insn	2, 0x0002
     45c:	0200                	.insn	2, 0x0200
     45e:	3c01                	.insn	2, 0x3c01
     460:	1d09                	.insn	2, 0x1d09
     462:	000001ef          	jal	gp,462 <_start-0xffb9e>
     466:	0421                	.insn	2, 0x0421
     468:	0000                	.insn	2, 0x0000
     46a:	0100                	.insn	2, 0x0100
     46c:	0c2d                	.insn	2, 0x0c2d
     46e:	0012                	.insn	2, 0x0012
     470:	0002                	.insn	2, 0x0002
     472:	2200                	.insn	2, 0x2200
     474:	0004                	.insn	2, 0x0004
     476:	0000                	.insn	2, 0x0000
     478:	3101                	.insn	2, 0x3101
     47a:	1305                	.insn	2, 0x1305
     47c:	8080                	.insn	2, 0x8080
     47e:	8080                	.insn	2, 0x8080
     480:	0401                	.insn	2, 0x0401
     482:	0002                	.insn	2, 0x0002
     484:	0000                	.insn	2, 0x0000
     486:	0000                	.insn	2, 0x0000
     488:	f412                	.insn	2, 0xf412
     48a:	0002                	.insn	2, 0x0002
     48c:	2300                	.insn	2, 0x2300
     48e:	000c                	.insn	2, 0x000c
     490:	0000                	.insn	2, 0x0000
     492:	7a01                	.insn	2, 0x7a01
     494:	1b05                	.insn	2, 0x1b05
     496:	0002f803          	.insn	4, 0x0002f803
     49a:	0000                	.insn	2, 0x0000
     49c:	f412                	.insn	2, 0xf412
     49e:	0002                	.insn	2, 0x0002
     4a0:	2400                	.insn	2, 0x2400
     4a2:	000c                	.insn	2, 0x000c
     4a4:	0000                	.insn	2, 0x0000
     4a6:	7f01                	.insn	2, 0x7f01
     4a8:	1b09                	.insn	2, 0x1b09
     4aa:	f805                	.insn	2, 0xf805
     4ac:	0002                	.insn	2, 0x0002
     4ae:	0000                	.insn	2, 0x0000
     4b0:	c812                	.insn	2, 0xc812
     4b2:	0002                	.insn	2, 0x0002
     4b4:	2500                	.insn	2, 0x2500
     4b6:	0024                	.insn	2, 0x0024
     4b8:	0000                	.insn	2, 0x0000
     4ba:	8101                	.insn	2, 0x8101
     4bc:	1b0d                	.insn	2, 0x1b0d
     4be:	cc09                	.insn	2, 0xcc09
     4c0:	0002                	.insn	2, 0x0002
     4c2:	1c00                	.insn	2, 0x1c00
     4c4:	0260                	.insn	2, 0x0260
     4c6:	0000                	.insn	2, 0x0000
     4c8:	093c0103          	lb	sp,147(s8)
     4cc:	ef1d                	.insn	2, 0xef1d
     4ce:	0001                	.insn	2, 0x0001
     4d0:	2600                	.insn	2, 0x2600
     4d2:	0004                	.insn	2, 0x0004
     4d4:	0000                	.insn	2, 0x0000
     4d6:	2d01                	.insn	2, 0x2d01
     4d8:	120c                	.insn	2, 0x120c
     4da:	0200                	.insn	2, 0x0200
     4dc:	0000                	.insn	2, 0x0000
     4de:	00000427          	.insn	4, 0x0427
     4e2:	0100                	.insn	2, 0x0100
     4e4:	0531                	.insn	2, 0x0531
     4e6:	80808013          	addi	zero,ra,-2040
     4ea:	0180                	.insn	2, 0x0180
     4ec:	0204                	.insn	2, 0x0204
     4ee:	0000                	.insn	2, 0x0000
     4f0:	0000                	.insn	2, 0x0000
     4f2:	1d00                	.insn	2, 0x1d00
     4f4:	0301                	.insn	2, 0x0301
     4f6:	0000                	.insn	2, 0x0000
     4f8:	0428                	.insn	2, 0x0428
     4fa:	0000                	.insn	2, 0x0000
     4fc:	0100                	.insn	2, 0x0100
     4fe:	0985                	.insn	2, 0x0985
     500:	f412                	.insn	2, 0xf412
     502:	0002                	.insn	2, 0x0002
     504:	2900                	.insn	2, 0x2900
     506:	000c                	.insn	2, 0x000c
     508:	0000                	.insn	2, 0x0000
     50a:	8801                	.insn	2, 0x8801
     50c:	1b05                	.insn	2, 0x1b05
     50e:	f806                	.insn	2, 0xf806
     510:	0002                	.insn	2, 0x0002
     512:	0000                	.insn	2, 0x0000
     514:	1200                	.insn	2, 0x1200
     516:	02c8                	.insn	2, 0x02c8
     518:	0000                	.insn	2, 0x0000
     51a:	242a                	.insn	2, 0x242a
     51c:	0000                	.insn	2, 0x0000
     51e:	0100                	.insn	2, 0x0100
     520:	09e1                	.insn	2, 0x09e1
     522:	02cc0a1b          	.insn	4, 0x02cc0a1b
     526:	0000                	.insn	2, 0x0000
     528:	601c                	.insn	2, 0x601c
     52a:	0002                	.insn	2, 0x0002
     52c:	0400                	.insn	2, 0x0400
     52e:	3c01                	.insn	2, 0x3c01
     530:	1d09                	.insn	2, 0x1d09
     532:	000001ef          	jal	gp,532 <_start-0xfface>
     536:	0000042b          	.insn	4, 0x042b
     53a:	0100                	.insn	2, 0x0100
     53c:	0c2d                	.insn	2, 0x0c2d
     53e:	0012                	.insn	2, 0x0012
     540:	0002                	.insn	2, 0x0002
     542:	2c00                	.insn	2, 0x2c00
     544:	0004                	.insn	2, 0x0004
     546:	0000                	.insn	2, 0x0000
     548:	3101                	.insn	2, 0x3101
     54a:	1305                	.insn	2, 0x1305
     54c:	8080                	.insn	2, 0x8080
     54e:	8080                	.insn	2, 0x8080
     550:	0401                	.insn	2, 0x0401
     552:	0002                	.insn	2, 0x0002
     554:	0000                	.insn	2, 0x0000
     556:	0000                	.insn	2, 0x0000
     558:	c812                	.insn	2, 0xc812
     55a:	0002                	.insn	2, 0x0002
     55c:	2d00                	.insn	2, 0x2d00
     55e:	0024                	.insn	2, 0x0024
     560:	0000                	.insn	2, 0x0000
     562:	e601                	.insn	2, 0xe601
     564:	1b09                	.insn	2, 0x1b09
     566:	0002cc07          	.insn	4, 0x0002cc07
     56a:	1c00                	.insn	2, 0x1c00
     56c:	0260                	.insn	2, 0x0260
     56e:	0000                	.insn	2, 0x0000
     570:	0105                	.insn	2, 0x0105
     572:	093c                	.insn	2, 0x093c
     574:	ef1d                	.insn	2, 0xef1d
     576:	0001                	.insn	2, 0x0001
     578:	2e00                	.insn	2, 0x2e00
     57a:	0004                	.insn	2, 0x0004
     57c:	0000                	.insn	2, 0x0000
     57e:	2d01                	.insn	2, 0x2d01
     580:	120c                	.insn	2, 0x120c
     582:	0200                	.insn	2, 0x0200
     584:	0000                	.insn	2, 0x0000
     586:	0000042f          	.insn	4, 0x042f
     58a:	0100                	.insn	2, 0x0100
     58c:	0531                	.insn	2, 0x0531
     58e:	80808013          	addi	zero,ra,-2040
     592:	0180                	.insn	2, 0x0180
     594:	0204                	.insn	2, 0x0204
     596:	0000                	.insn	2, 0x0000
     598:	0000                	.insn	2, 0x0000
     59a:	1200                	.insn	2, 0x1200
     59c:	02c8                	.insn	2, 0x02c8
     59e:	0000                	.insn	2, 0x0000
     5a0:	2430                	.insn	2, 0x2430
     5a2:	0000                	.insn	2, 0x0000
     5a4:	0100                	.insn	2, 0x0100
     5a6:	081b09eb          	.insn	4, 0x081b09eb
     5aa:	02cc                	.insn	2, 0x02cc
     5ac:	0000                	.insn	2, 0x0000
     5ae:	601c                	.insn	2, 0x601c
     5b0:	0002                	.insn	2, 0x0002
     5b2:	0600                	.insn	2, 0x0600
     5b4:	3c01                	.insn	2, 0x3c01
     5b6:	1d09                	.insn	2, 0x1d09
     5b8:	000001ef          	jal	gp,5b8 <_start-0xffa48>
     5bc:	0431                	.insn	2, 0x0431
     5be:	0000                	.insn	2, 0x0000
     5c0:	0100                	.insn	2, 0x0100
     5c2:	0c2d                	.insn	2, 0x0c2d
     5c4:	0012                	.insn	2, 0x0012
     5c6:	0002                	.insn	2, 0x0002
     5c8:	3200                	.insn	2, 0x3200
     5ca:	0004                	.insn	2, 0x0004
     5cc:	0000                	.insn	2, 0x0000
     5ce:	3101                	.insn	2, 0x3101
     5d0:	1305                	.insn	2, 0x1305
     5d2:	8080                	.insn	2, 0x8080
     5d4:	8080                	.insn	2, 0x8080
     5d6:	0401                	.insn	2, 0x0401
     5d8:	0002                	.insn	2, 0x0002
     5da:	0000                	.insn	2, 0x0000
     5dc:	0000                	.insn	2, 0x0000
     5de:	c812                	.insn	2, 0xc812
     5e0:	0002                	.insn	2, 0x0002
     5e2:	3300                	.insn	2, 0x3300
     5e4:	0024                	.insn	2, 0x0024
     5e6:	0000                	.insn	2, 0x0000
     5e8:	f001                	.insn	2, 0xf001
     5ea:	1b09                	.insn	2, 0x1b09
     5ec:	0002cc0b          	.insn	4, 0x0002cc0b
     5f0:	1c00                	.insn	2, 0x1c00
     5f2:	0260                	.insn	2, 0x0260
     5f4:	0000                	.insn	2, 0x0000
     5f6:	093c0107          	.insn	4, 0x093c0107
     5fa:	ef1d                	.insn	2, 0xef1d
     5fc:	0001                	.insn	2, 0x0001
     5fe:	3400                	.insn	2, 0x3400
     600:	0004                	.insn	2, 0x0004
     602:	0000                	.insn	2, 0x0000
     604:	2d01                	.insn	2, 0x2d01
     606:	120c                	.insn	2, 0x120c
     608:	0200                	.insn	2, 0x0200
     60a:	0000                	.insn	2, 0x0000
     60c:	0435                	.insn	2, 0x0435
     60e:	0000                	.insn	2, 0x0000
     610:	0100                	.insn	2, 0x0100
     612:	0531                	.insn	2, 0x0531
     614:	80808013          	addi	zero,ra,-2040
     618:	0180                	.insn	2, 0x0180
     61a:	0204                	.insn	2, 0x0204
     61c:	0000                	.insn	2, 0x0000
     61e:	0000                	.insn	2, 0x0000
     620:	1f00                	.insn	2, 0x1f00
     622:	0305                	.insn	2, 0x0305
     624:	0000                	.insn	2, 0x0000
     626:	0436                	.insn	2, 0x0436
     628:	0000                	.insn	2, 0x0000
     62a:	0100                	.insn	2, 0x0100
     62c:	0110                	.insn	2, 0x0110
     62e:	1305                	.insn	2, 0x1305
     630:	8080                	.insn	2, 0x8080
     632:	0180                	.insn	2, 0x0180
     634:	0309                	.insn	2, 0x0309
     636:	0000                	.insn	2, 0x0000
     638:	8020                	.insn	2, 0x8020
     63a:	8080                	.insn	2, 0x8080
     63c:	1101                	.insn	2, 0x1101
     63e:	00000003          	lb	zero,0(zero) # 0 <_start-0x100000>
     642:	3321                	.insn	2, 0x3321
     644:	0006                	.insn	2, 0x0006
     646:	3700                	.insn	2, 0x3700
     648:	7421                	.insn	2, 0x7421
     64a:	0006                	.insn	2, 0x0006
     64c:	3800                	.insn	2, 0x3800
     64e:	7421                	.insn	2, 0x7421
     650:	0006                	.insn	2, 0x0006
     652:	3900                	.insn	2, 0x3900
     654:	9121                	.insn	2, 0x9121
     656:	0006                	.insn	2, 0x0006
     658:	3a00                	.insn	2, 0x3a00
     65a:	d421                	.insn	2, 0xd421
     65c:	0006                	.insn	2, 0x0006
     65e:	3b00                	.insn	2, 0x3b00
     660:	9121                	.insn	2, 0x9121
     662:	0006                	.insn	2, 0x0006
     664:	3c00                	.insn	2, 0x3c00
     666:	9121                	.insn	2, 0x9121
     668:	0006                	.insn	2, 0x0006
     66a:	3d00                	.insn	2, 0x3d00
     66c:	d421                	.insn	2, 0xd421
     66e:	0006                	.insn	2, 0x0006
     670:	3e00                	.insn	2, 0x3e00
     672:	9121                	.insn	2, 0x9121
     674:	0006                	.insn	2, 0x0006
     676:	3f00                	.insn	2, 0x3f00
     678:	9121                	.insn	2, 0x9121
     67a:	0006                	.insn	2, 0x0006
     67c:	4000                	.insn	2, 0x4000
     67e:	d421                	.insn	2, 0xd421
     680:	0006                	.insn	2, 0x0006
     682:	4100                	.insn	2, 0x4100
     684:	9121                	.insn	2, 0x9121
     686:	0006                	.insn	2, 0x0006
     688:	4200                	.insn	2, 0x4200
     68a:	9121                	.insn	2, 0x9121
     68c:	0006                	.insn	2, 0x0006
     68e:	4300                	.insn	2, 0x4300
     690:	d421                	.insn	2, 0xd421
     692:	0006                	.insn	2, 0x0006
     694:	4400                	.insn	2, 0x4400
     696:	9121                	.insn	2, 0x9121
     698:	0006                	.insn	2, 0x0006
     69a:	4500                	.insn	2, 0x4500
     69c:	9121                	.insn	2, 0x9121
     69e:	0006                	.insn	2, 0x0006
     6a0:	4600                	.insn	2, 0x4600
     6a2:	d421                	.insn	2, 0xd421
     6a4:	0006                	.insn	2, 0x0006
     6a6:	4700                	.insn	2, 0x4700
     6a8:	9121                	.insn	2, 0x9121
     6aa:	0006                	.insn	2, 0x0006
     6ac:	4800                	.insn	2, 0x4800
     6ae:	9121                	.insn	2, 0x9121
     6b0:	0006                	.insn	2, 0x0006
     6b2:	4900                	.insn	2, 0x4900
     6b4:	d421                	.insn	2, 0xd421
     6b6:	0006                	.insn	2, 0x0006
     6b8:	4a00                	.insn	2, 0x4a00
     6ba:	9121                	.insn	2, 0x9121
     6bc:	0006                	.insn	2, 0x0006
     6be:	4b00                	.insn	2, 0x4b00
     6c0:	9121                	.insn	2, 0x9121
     6c2:	0006                	.insn	2, 0x0006
     6c4:	4c00                	.insn	2, 0x4c00
     6c6:	d421                	.insn	2, 0xd421
     6c8:	0006                	.insn	2, 0x0006
     6ca:	4d00                	.insn	2, 0x4d00
     6cc:	9121                	.insn	2, 0x9121
     6ce:	0006                	.insn	2, 0x0006
     6d0:	3600                	.insn	2, 0x3600
     6d2:	0122                	.insn	2, 0x0122
     6d4:	4e62                	.insn	2, 0x4e62
     6d6:	2300                	.insn	2, 0x2300
     6d8:	f019031b          	.insn	4, 0xf019031b
     6dc:	0002                	.insn	2, 0x0002
     6de:	2400                	.insn	2, 0x2400
     6e0:	0641                	.insn	2, 0x0641
     6e2:	0000                	.insn	2, 0x0000
     6e4:	0900                	.insn	2, 0x0900
     6e6:	0649                	.insn	2, 0x0649
     6e8:	0000                	.insn	2, 0x0000
     6ea:	031c                	.insn	2, 0x031c
     6ec:	0a14                	.insn	2, 0x0a14
     6ee:	064e                	.insn	2, 0x064e
     6f0:	0000                	.insn	2, 0x0000
     6f2:	f025                	.insn	2, 0xf025
     6f4:	0002                	.insn	2, 0x0002
     6f6:	2400                	.insn	2, 0x2400
     6f8:	065e                	.insn	2, 0x065e
     6fa:	0000                	.insn	2, 0x0000
     6fc:	6624                	.insn	2, 0x6624
     6fe:	0006                	.insn	2, 0x0006
     700:	0000                	.insn	2, 0x0000
     702:	c309                	.insn	2, 0xc309
     704:	0001                	.insn	2, 0x0001
     706:	0600                	.insn	2, 0x0600
     708:	ca04                	.insn	2, 0xca04
     70a:	6b0a                	.insn	2, 0x6b0a
     70c:	0006                	.insn	2, 0x0006
     70e:	2600                	.insn	2, 0x2600
     710:	000001cf          	.insn	4, 0x01cf
     714:	0408                	.insn	2, 0x0408
     716:	010e                	.insn	2, 0x010e
     718:	31031d23          	sh	a6,794(t1)
     71c:	02f0                	.insn	2, 0x02f0
     71e:	0000                	.insn	2, 0x0000
     720:	d524                	.insn	2, 0xd524
     722:	0002                	.insn	2, 0x0002
     724:	2400                	.insn	2, 0x2400
     726:	065e                	.insn	2, 0x065e
     728:	0000                	.insn	2, 0x0000
     72a:	8c24                	.insn	2, 0x8c24
     72c:	0006                	.insn	2, 0x0006
     72e:	0000                	.insn	2, 0x0000
     730:	5e0a                	.insn	2, 0x5e0a
     732:	0006                	.insn	2, 0x0006
     734:	1000                	.insn	2, 0x1000
     736:	0000344f          	.insn	4, 0x344f
     73a:	0100                	.insn	2, 0x0100
     73c:	c852                	.insn	2, 0xc852
     73e:	0002                	.insn	2, 0x0002
     740:	1100                	.insn	2, 0x1100
     742:	5a01                	.insn	2, 0x5a01
     744:	02cc                	.insn	2, 0x02cc
     746:	0000                	.insn	2, 0x0000
     748:	601c                	.insn	2, 0x601c
     74a:	0002                	.insn	2, 0x0002
     74c:	0800                	.insn	2, 0x0800
     74e:	3c01                	.insn	2, 0x3c01
     750:	1d09                	.insn	2, 0x1d09
     752:	000001ef          	jal	gp,752 <_start-0xff8ae>
     756:	0450                	.insn	2, 0x0450
     758:	0000                	.insn	2, 0x0000
     75a:	0100                	.insn	2, 0x0100
     75c:	0c2d                	.insn	2, 0x0c2d
     75e:	0012                	.insn	2, 0x0012
     760:	0002                	.insn	2, 0x0002
     762:	5100                	.insn	2, 0x5100
     764:	0004                	.insn	2, 0x0004
     766:	0000                	.insn	2, 0x0000
     768:	3101                	.insn	2, 0x3101
     76a:	1305                	.insn	2, 0x1305
     76c:	8080                	.insn	2, 0x8080
     76e:	8080                	.insn	2, 0x8080
     770:	0401                	.insn	2, 0x0401
     772:	0002                	.insn	2, 0x0002
     774:	0000                	.insn	2, 0x0000
     776:	0000                	.insn	2, 0x0000
     778:	8b10                	.insn	2, 0x8b10
     77a:	5001                	.insn	2, 0x5001
     77c:	0000                	.insn	2, 0x0000
     77e:	0100                	.insn	2, 0x0100
     780:	a252                	.insn	2, 0xa252
     782:	11000007          	.insn	4, 0x11000007
     786:	5a01                	.insn	2, 0x5a01
     788:	07a6                	.insn	2, 0x07a6
     78a:	0000                	.insn	2, 0x0000
     78c:	3c018c27          	.insn	4, 0x3c018c27
     790:	0000                	.insn	2, 0x0000
     792:	ae00                	.insn	2, 0xae00
     794:	1e000007          	.insn	4, 0x1e000007
     798:	0007af33          	sltz	t5,a5
     79c:	2700                	.insn	2, 0x2700
     79e:	018c                	.insn	2, 0x018c
     7a0:	0034                	.insn	2, 0x0034
     7a2:	0000                	.insn	2, 0x0000
     7a4:	000007b7          	lui	a5,0x0
     7a8:	341e                	.insn	2, 0x341e
     7aa:	07b8                	.insn	2, 0x07b8
     7ac:	0000                	.insn	2, 0x0000
     7ae:	6012                	.insn	2, 0x6012
     7b0:	0002                	.insn	2, 0x0002
     7b2:	8d00                	.insn	2, 0x8d00
     7b4:	1401                	.insn	2, 0x1401
     7b6:	0000                	.insn	2, 0x0000
     7b8:	0100                	.insn	2, 0x0100
     7ba:	0944                	.insn	2, 0x0944
     7bc:	ef1d                	.insn	2, 0xef1d
     7be:	0001                	.insn	2, 0x0001
     7c0:	8e00                	.insn	2, 0x8e00
     7c2:	0401                	.insn	2, 0x0401
     7c4:	0000                	.insn	2, 0x0000
     7c6:	0100                	.insn	2, 0x0100
     7c8:	0c2d                	.insn	2, 0x0c2d
     7ca:	0012                	.insn	2, 0x0012
     7cc:	0002                	.insn	2, 0x0002
     7ce:	8f00                	.insn	2, 0x8f00
     7d0:	0401                	.insn	2, 0x0401
     7d2:	0000                	.insn	2, 0x0000
     7d4:	0100                	.insn	2, 0x0100
     7d6:	0531                	.insn	2, 0x0531
     7d8:	80808013          	addi	zero,ra,-2040
     7dc:	0180                	.insn	2, 0x0180
     7de:	0204                	.insn	2, 0x0204
     7e0:	0000                	.insn	2, 0x0000
     7e2:	0111                	.insn	2, 0x0111
     7e4:	0c5e                	.insn	2, 0x0c5e
     7e6:	0002                	.insn	2, 0x0002
     7e8:	0000                	.insn	2, 0x0000
     7ea:	0000                	.insn	2, 0x0000
     7ec:	0000                	.insn	2, 0x0000
     7ee:	1e0d                	.insn	2, 0x1e0d
     7f0:	5401                	.insn	2, 0x5401
     7f2:	01dd                	.insn	2, 0x01dd
     7f4:	0000                	.insn	2, 0x0000
     7f6:	1f0e                	.insn	2, 0x1f0e
     7f8:	5401                	.insn	2, 0x5401
     7fa:	00000777          	.insn	4, 0x0777
     7fe:	2018                	.insn	2, 0x2018
     800:	5601                	.insn	2, 0x5601
     802:	01dd                	.insn	2, 0x01dd
     804:	0000                	.insn	2, 0x0000
     806:	1828                	.insn	2, 0x1828
     808:	0121                	.insn	2, 0x0121
     80a:	f058                	.insn	2, 0xf058
     80c:	0002                	.insn	2, 0x0002
     80e:	2800                	.insn	2, 0x2800
     810:	2218                	.insn	2, 0x2218
     812:	5b01                	.insn	2, 0x5b01
     814:	02f0                	.insn	2, 0x02f0
     816:	0000                	.insn	2, 0x0000
     818:	0000                	.insn	2, 0x0000
     81a:	0a00                	.insn	2, 0x0a00
     81c:	077c                	.insn	2, 0x077c
     81e:	0000                	.insn	2, 0x0000
     820:	0001c717          	auipc	a4,0x1c
     824:	0d00                	.insn	2, 0x0d00
     826:	dd660123          	sb	s6,-574(a2)
     82a:	0001                	.insn	2, 0x0001
     82c:	1800                	.insn	2, 0x1800
     82e:	0124                	.insn	2, 0x0124
     830:	bb68                	.insn	2, 0xbb68
     832:	0001                	.insn	2, 0x0001
     834:	1800                	.insn	2, 0x1800
     836:	0125                	.insn	2, 0x0125
     838:	c76a                	.insn	2, 0xc76a
     83a:	0001                	.insn	2, 0x0001
     83c:	1800                	.insn	2, 0x1800
     83e:	0126                	.insn	2, 0x0126
     840:	0001c76b          	.insn	4, 0x0001c76b
     844:	0000                	.insn	2, 0x0000
     846:	4001270f          	.insn	4, 0x4001270f
     84a:	0e0e                	.insn	2, 0x0e0e
     84c:	4001                	.insn	2, 0x4001
     84e:	000001bb          	.insn	4, 0x01bb
     852:	1828                	.insn	2, 0x1828
     854:	0121                	.insn	2, 0x0121
     856:	f042                	.insn	2, 0xf042
     858:	0002                	.insn	2, 0x0002
     85a:	2800                	.insn	2, 0x2800
     85c:	1718                	.insn	2, 0x1718
     85e:	4301                	.insn	2, 0x4301
     860:	000001c7          	.insn	4, 0x01c7
     864:	0000                	.insn	2, 0x0000
     866:	2900                	.insn	2, 0x2900
     868:	d852                	.insn	2, 0xd852
     86a:	01000007          	.insn	4, 0x01000007
     86e:	2c52                	.insn	2, 0x2c52
     870:	8c01                	.insn	2, 0x8c01
     872:	02f0                	.insn	2, 0x02f0
     874:	0000                	.insn	2, 0x0000
     876:	0c2a                	.insn	2, 0x0c2a
     878:	0130                	.insn	2, 0x0130
     87a:	bb8c                	.insn	2, 0xbb8c
     87c:	0001                	.insn	2, 0x0001
     87e:	2a00                	.insn	2, 0x2a00
     880:	310d                	.insn	2, 0x310d
     882:	8c01                	.insn	2, 0x8c01
     884:	0df4                	.insn	2, 0x0df4
     886:	0000                	.insn	2, 0x0000
     888:	0115112b          	.insn	4, 0x0115112b
     88c:	bb8e                	.insn	2, 0xbb8e
     88e:	0001                	.insn	2, 0x0001
     890:	2c00                	.insn	2, 0x2c00
     892:	2b09                	.insn	2, 0x2b09
     894:	320e                	.insn	2, 0x320e
     896:	9001                	.insn	2, 0x9001
     898:	000001bb          	.insn	4, 0x01bb
     89c:	f412                	.insn	2, 0xf412
     89e:	0002                	.insn	2, 0x0002
     8a0:	5300                	.insn	2, 0x5300
     8a2:	00c8                	.insn	2, 0x00c8
     8a4:	0000                	.insn	2, 0x0000
     8a6:	9201                	.insn	2, 0x9201
     8a8:	1b09                	.insn	2, 0x1b09
     8aa:	0002f80f          	.insn	4, 0x0002f80f
     8ae:	0000                	.insn	2, 0x0000
     8b0:	f412                	.insn	2, 0xf412
     8b2:	0002                	.insn	2, 0x0002
     8b4:	5400                	.insn	2, 0x5400
     8b6:	00c8                	.insn	2, 0x00c8
     8b8:	0000                	.insn	2, 0x0000
     8ba:	9701                	.insn	2, 0x9701
     8bc:	1b09                	.insn	2, 0x1b09
     8be:	f810                	.insn	2, 0xf810
     8c0:	0002                	.insn	2, 0x0002
     8c2:	0000                	.insn	2, 0x0000
     8c4:	c812                	.insn	2, 0xc812
     8c6:	0002                	.insn	2, 0x0002
     8c8:	5500                	.insn	2, 0x5500
     8ca:	0024                	.insn	2, 0x0024
     8cc:	0000                	.insn	2, 0x0000
     8ce:	9d01                	.insn	2, 0x9d01
     8d0:	1b11                	.insn	2, 0x1b11
     8d2:	cc30                	.insn	2, 0xcc30
     8d4:	0002                	.insn	2, 0x0002
     8d6:	1c00                	.insn	2, 0x1c00
     8d8:	0260                	.insn	2, 0x0260
     8da:	0000                	.insn	2, 0x0000
     8dc:	010a                	.insn	2, 0x010a
     8de:	093c                	.insn	2, 0x093c
     8e0:	ef1d                	.insn	2, 0xef1d
     8e2:	0001                	.insn	2, 0x0001
     8e4:	5600                	.insn	2, 0x5600
     8e6:	0004                	.insn	2, 0x0004
     8e8:	0000                	.insn	2, 0x0000
     8ea:	2d01                	.insn	2, 0x2d01
     8ec:	120c                	.insn	2, 0x120c
     8ee:	0200                	.insn	2, 0x0200
     8f0:	0000                	.insn	2, 0x0000
     8f2:	00000457          	.insn	4, 0x0457
     8f6:	0100                	.insn	2, 0x0100
     8f8:	0531                	.insn	2, 0x0531
     8fa:	80808013          	addi	zero,ra,-2040
     8fe:	0180                	.insn	2, 0x0180
     900:	0204                	.insn	2, 0x0204
     902:	0000                	.insn	2, 0x0000
     904:	0000                	.insn	2, 0x0000
     906:	1200                	.insn	2, 0x1200
     908:	07a2                	.insn	2, 0x07a2
     90a:	0000                	.insn	2, 0x0000
     90c:	4058                	.insn	2, 0x4058
     90e:	0000                	.insn	2, 0x0000
     910:	0100                	.insn	2, 0x0100
     912:	119e                	.insn	2, 0x119e
     914:	00405827          	.insn	4, 0x00405827
     918:	0000                	.insn	2, 0x0000
     91a:	07ae                	.insn	2, 0x07ae
     91c:	0000                	.insn	2, 0x0000
     91e:	311e                	.insn	2, 0x311e
     920:	000007af          	.insn	4, 0x07af
     924:	00345827          	.insn	4, 0x00345827
     928:	0000                	.insn	2, 0x0000
     92a:	000007b7          	lui	a5,0x0
     92e:	321e                	.insn	2, 0x321e
     930:	07b8                	.insn	2, 0x07b8
     932:	0000                	.insn	2, 0x0000
     934:	6012                	.insn	2, 0x6012
     936:	0002                	.insn	2, 0x0002
     938:	5900                	.insn	2, 0x5900
     93a:	0014                	.insn	2, 0x0014
     93c:	0000                	.insn	2, 0x0000
     93e:	4401                	.insn	2, 0x4401
     940:	1d09                	.insn	2, 0x1d09
     942:	000001ef          	jal	gp,942 <_start-0xff6be>
     946:	045a                	.insn	2, 0x045a
     948:	0000                	.insn	2, 0x0000
     94a:	0100                	.insn	2, 0x0100
     94c:	0c2d                	.insn	2, 0x0c2d
     94e:	0012                	.insn	2, 0x0012
     950:	0002                	.insn	2, 0x0002
     952:	5b00                	.insn	2, 0x5b00
     954:	0004                	.insn	2, 0x0004
     956:	0000                	.insn	2, 0x0000
     958:	3101                	.insn	2, 0x3101
     95a:	1305                	.insn	2, 0x1305
     95c:	8080                	.insn	2, 0x8080
     95e:	8080                	.insn	2, 0x8080
     960:	0401                	.insn	2, 0x0401
     962:	0002                	.insn	2, 0x0002
     964:	1100                	.insn	2, 0x1100
     966:	5f01                	.insn	2, 0x5f01
     968:	020c                	.insn	2, 0x020c
     96a:	0000                	.insn	2, 0x0000
     96c:	0000                	.insn	2, 0x0000
     96e:	0000                	.insn	2, 0x0000
     970:	1200                	.insn	2, 0x1200
     972:	02c8                	.insn	2, 0x02c8
     974:	0000                	.insn	2, 0x0000
     976:	105c                	.insn	2, 0x105c
     978:	0000                	.insn	2, 0x0000
     97a:	0100                	.insn	2, 0x0100
     97c:	119f 6012 0002      	.insn	6, 0x00026012119f
     982:	5c00                	.insn	2, 0x5c00
     984:	0010                	.insn	2, 0x0010
     986:	0000                	.insn	2, 0x0000
     988:	3c01                	.insn	2, 0x3c01
     98a:	1309                	.insn	2, 0x1309
     98c:	640a                	.insn	2, 0x640a
     98e:	0002                	.insn	2, 0x0002
     990:	1200                	.insn	2, 0x1200
     992:	000001ef          	jal	gp,992 <_start-0xff66e>
     996:	045d                	.insn	2, 0x045d
     998:	0000                	.insn	2, 0x0000
     99a:	0100                	.insn	2, 0x0100
     99c:	0c2d                	.insn	2, 0x0c2d
     99e:	80808813          	addi	a6,ra,-2040
     9a2:	0180                	.insn	2, 0x0180
     9a4:	000001f7          	.insn	4, 0x01f7
     9a8:	0000                	.insn	2, 0x0000
     9aa:	1d00                	.insn	2, 0x1d00
     9ac:	0301                	.insn	2, 0x0301
     9ae:	0000                	.insn	2, 0x0000
     9b0:	045e                	.insn	2, 0x045e
     9b2:	0000                	.insn	2, 0x0000
     9b4:	0100                	.insn	2, 0x0100
     9b6:	f4120da3          	sb	ra,-165(tp) # ffffff5b <_stack_top+0xffef3f9b>
     9ba:	0002                	.insn	2, 0x0002
     9bc:	5f00                	.insn	2, 0x5f00
     9be:	0054                	.insn	2, 0x0054
     9c0:	0000                	.insn	2, 0x0000
     9c2:	a601                	.insn	2, 0xa601
     9c4:	1b09                	.insn	2, 0x1b09
     9c6:	f812                	.insn	2, 0xf812
     9c8:	0002                	.insn	2, 0x0002
     9ca:	0000                	.insn	2, 0x0000
     9cc:	0b2c                	.insn	2, 0x0b2c
     9ce:	0121132b          	.insn	4, 0x0121132b
     9d2:	f0a8                	.insn	2, 0xf0a8
     9d4:	0002                	.insn	2, 0x0002
     9d6:	1200                	.insn	2, 0x1200
     9d8:	02c8                	.insn	2, 0x02c8
     9da:	0000                	.insn	2, 0x0000
     9dc:	2460                	.insn	2, 0x2460
     9de:	0000                	.insn	2, 0x0000
     9e0:	0100                	.insn	2, 0x0100
     9e2:	15ad                	.insn	2, 0x15ad
     9e4:	02cc2d1b          	.insn	4, 0x02cc2d1b
     9e8:	0000                	.insn	2, 0x0000
     9ea:	601c                	.insn	2, 0x601c
     9ec:	0002                	.insn	2, 0x0002
     9ee:	0c00                	.insn	2, 0x0c00
     9f0:	3c01                	.insn	2, 0x3c01
     9f2:	1d09                	.insn	2, 0x1d09
     9f4:	000001ef          	jal	gp,9f4 <_start-0xff60c>
     9f8:	0461                	.insn	2, 0x0461
     9fa:	0000                	.insn	2, 0x0000
     9fc:	0100                	.insn	2, 0x0100
     9fe:	0c2d                	.insn	2, 0x0c2d
     a00:	0012                	.insn	2, 0x0012
     a02:	0002                	.insn	2, 0x0002
     a04:	6200                	.insn	2, 0x6200
     a06:	0004                	.insn	2, 0x0004
     a08:	0000                	.insn	2, 0x0000
     a0a:	3101                	.insn	2, 0x3101
     a0c:	1305                	.insn	2, 0x1305
     a0e:	8080                	.insn	2, 0x8080
     a10:	8080                	.insn	2, 0x8080
     a12:	0401                	.insn	2, 0x0401
     a14:	0002                	.insn	2, 0x0002
     a16:	0000                	.insn	2, 0x0000
     a18:	0000                	.insn	2, 0x0000
     a1a:	a212                	.insn	2, 0xa212
     a1c:	63000007          	.insn	4, 0x63000007
     a20:	0040                	.insn	2, 0x0040
     a22:	0000                	.insn	2, 0x0000
     a24:	ae01                	.insn	2, 0xae01
     a26:	2715                	.insn	2, 0x2715
     a28:	00004063          	bltz	zero,a28 <_start-0xff5d8>
     a2c:	ae00                	.insn	2, 0xae00
     a2e:	1e000007          	.insn	4, 0x1e000007
     a32:	af2e                	.insn	2, 0xaf2e
     a34:	27000007          	.insn	4, 0x27000007
     a38:	00003463          	.insn	4, 0x3463
     a3c:	b700                	.insn	2, 0xb700
     a3e:	1e000007          	.insn	4, 0x1e000007
     a42:	0007b82f          	.insn	4, 0x0007b82f
     a46:	1200                	.insn	2, 0x1200
     a48:	0260                	.insn	2, 0x0260
     a4a:	0000                	.insn	2, 0x0000
     a4c:	1464                	.insn	2, 0x1464
     a4e:	0000                	.insn	2, 0x0000
     a50:	0100                	.insn	2, 0x0100
     a52:	0944                	.insn	2, 0x0944
     a54:	ef1d                	.insn	2, 0xef1d
     a56:	0001                	.insn	2, 0x0001
     a58:	6500                	.insn	2, 0x6500
     a5a:	0004                	.insn	2, 0x0004
     a5c:	0000                	.insn	2, 0x0000
     a5e:	2d01                	.insn	2, 0x2d01
     a60:	120c                	.insn	2, 0x120c
     a62:	0200                	.insn	2, 0x0200
     a64:	0000                	.insn	2, 0x0000
     a66:	0466                	.insn	2, 0x0466
     a68:	0000                	.insn	2, 0x0000
     a6a:	0100                	.insn	2, 0x0100
     a6c:	0531                	.insn	2, 0x0531
     a6e:	80808013          	addi	zero,ra,-2040
     a72:	0180                	.insn	2, 0x0180
     a74:	0204                	.insn	2, 0x0204
     a76:	0000                	.insn	2, 0x0000
     a78:	0111                	.insn	2, 0x0111
     a7a:	0c5f 0002 0000      	.insn	6, 0x00020c5f
     a80:	0000                	.insn	2, 0x0000
     a82:	0000                	.insn	2, 0x0000
     a84:	c812                	.insn	2, 0xc812
     a86:	0002                	.insn	2, 0x0002
     a88:	6700                	.insn	2, 0x6700
     a8a:	0014                	.insn	2, 0x0014
     a8c:	0000                	.insn	2, 0x0000
     a8e:	af01                	.insn	2, 0xaf01
     a90:	1215                	.insn	2, 0x1215
     a92:	0260                	.insn	2, 0x0260
     a94:	0000                	.insn	2, 0x0000
     a96:	00001467          	.insn	4, 0x1467
     a9a:	0100                	.insn	2, 0x0100
     a9c:	093c                	.insn	2, 0x093c
     a9e:	02640a13          	addi	s4,s0,38
     aa2:	0000                	.insn	2, 0x0000
     aa4:	ef12                	.insn	2, 0xef12
     aa6:	0001                	.insn	2, 0x0001
     aa8:	6800                	.insn	2, 0x6800
     aaa:	0004                	.insn	2, 0x0004
     aac:	0000                	.insn	2, 0x0000
     aae:	2d01                	.insn	2, 0x2d01
     ab0:	130c                	.insn	2, 0x130c
     ab2:	8088                	.insn	2, 0x8088
     ab4:	8080                	.insn	2, 0x8080
     ab6:	f701                	.insn	2, 0xf701
     ab8:	0001                	.insn	2, 0x0001
     aba:	0000                	.insn	2, 0x0000
     abc:	0000                	.insn	2, 0x0000
     abe:	011d                	.insn	2, 0x011d
     ac0:	69000003          	lb	zero,1680(zero) # 690 <_start-0xff970>
     ac4:	0004                	.insn	2, 0x0004
     ac6:	0000                	.insn	2, 0x0000
     ac8:	b301                	.insn	2, 0xb301
     aca:	0011                	.insn	2, 0x0011
     acc:	0d2c                	.insn	2, 0x0d2c
     ace:	0133162b          	.insn	4, 0x0133162b
     ad2:	ddba                	.insn	2, 0xddba
     ad4:	0001                	.insn	2, 0x0001
     ad6:	2b00                	.insn	2, 0x2b00
     ad8:	3419                	.insn	2, 0x3419
     ada:	bb01                	.insn	2, 0xbb01
     adc:	01dd                	.insn	2, 0x01dd
     ade:	0000                	.insn	2, 0x0000
     ae0:	4a12                	.insn	2, 0x4a12
     ae2:	6a000007          	.insn	4, 0x6a000007
     ae6:	00b4                	.insn	2, 0x00b4
     ae8:	0000                	.insn	2, 0x0000
     aea:	ba01                	.insn	2, 0xba01
     aec:	1e1f 5a14 0007      	.insn	6, 0x00075a141e1f
     af2:	2700                	.insn	2, 0x2700
     af4:	00009c6b          	.insn	4, 0x9c6b
     af8:	6b00                	.insn	2, 0x6b00
     afa:	1e000007          	.insn	4, 0x1e000007
     afe:	6c15                	.insn	2, 0x6c15
     b00:	00000007          	.insn	4, 0x0007
     b04:	1c00                	.insn	2, 0x1c00
     b06:	0781                	.insn	2, 0x0781
     b08:	0000                	.insn	2, 0x0000
     b0a:	010e                	.insn	2, 0x010e
     b0c:	171e1fbb          	.insn	4, 0x171e1fbb
     b10:	0789                	.insn	2, 0x0789
     b12:	0000                	.insn	2, 0x0000
     b14:	181e                	.insn	2, 0x181e
     b16:	0791                	.insn	2, 0x0791
     b18:	0000                	.insn	2, 0x0000
     b1a:	1200                	.insn	2, 0x1200
     b1c:	02c8                	.insn	2, 0x02c8
     b1e:	0000                	.insn	2, 0x0000
     b20:	246c                	.insn	2, 0x246c
     b22:	0000                	.insn	2, 0x0000
     b24:	0100                	.insn	2, 0x0100
     b26:	0dc0                	.insn	2, 0x0dc0
     b28:	02cc1a1b          	.insn	4, 0x02cc1a1b
     b2c:	0000                	.insn	2, 0x0000
     b2e:	601c                	.insn	2, 0x601c
     b30:	0002                	.insn	2, 0x0002
     b32:	0f00                	.insn	2, 0x0f00
     b34:	3c01                	.insn	2, 0x3c01
     b36:	1d09                	.insn	2, 0x1d09
     b38:	000001ef          	jal	gp,b38 <_start-0xff4c8>
     b3c:	046d                	.insn	2, 0x046d
     b3e:	0000                	.insn	2, 0x0000
     b40:	0100                	.insn	2, 0x0100
     b42:	0c2d                	.insn	2, 0x0c2d
     b44:	0012                	.insn	2, 0x0012
     b46:	0002                	.insn	2, 0x0002
     b48:	6e00                	.insn	2, 0x6e00
     b4a:	0004                	.insn	2, 0x0004
     b4c:	0000                	.insn	2, 0x0000
     b4e:	3101                	.insn	2, 0x3101
     b50:	1305                	.insn	2, 0x1305
     b52:	8080                	.insn	2, 0x8080
     b54:	8080                	.insn	2, 0x8080
     b56:	0401                	.insn	2, 0x0401
     b58:	0002                	.insn	2, 0x0002
     b5a:	0000                	.insn	2, 0x0000
     b5c:	0000                	.insn	2, 0x0000
     b5e:	a212                	.insn	2, 0xa212
     b60:	6f000007          	.insn	4, 0x6f000007
     b64:	0040                	.insn	2, 0x0040
     b66:	0000                	.insn	2, 0x0000
     b68:	c101                	.insn	2, 0xc101
     b6a:	270d                	.insn	2, 0x270d
     b6c:	0000406f          	j	4b6c <_start-0xfb494>
     b70:	ae00                	.insn	2, 0xae00
     b72:	1e000007          	.insn	4, 0x1e000007
     b76:	0007af1b          	.insn	4, 0x0007af1b
     b7a:	2700                	.insn	2, 0x2700
     b7c:	0000346f          	jal	s0,3b7c <_start-0xfc484>
     b80:	b700                	.insn	2, 0xb700
     b82:	1e000007          	.insn	4, 0x1e000007
     b86:	b81c                	.insn	2, 0xb81c
     b88:	12000007          	.insn	4, 0x12000007
     b8c:	0260                	.insn	2, 0x0260
     b8e:	0000                	.insn	2, 0x0000
     b90:	1470                	.insn	2, 0x1470
     b92:	0000                	.insn	2, 0x0000
     b94:	0100                	.insn	2, 0x0100
     b96:	0944                	.insn	2, 0x0944
     b98:	ef1d                	.insn	2, 0xef1d
     b9a:	0001                	.insn	2, 0x0001
     b9c:	7100                	.insn	2, 0x7100
     b9e:	0004                	.insn	2, 0x0004
     ba0:	0000                	.insn	2, 0x0000
     ba2:	2d01                	.insn	2, 0x2d01
     ba4:	120c                	.insn	2, 0x120c
     ba6:	0200                	.insn	2, 0x0200
     ba8:	0000                	.insn	2, 0x0000
     baa:	0472                	.insn	2, 0x0472
     bac:	0000                	.insn	2, 0x0000
     bae:	0100                	.insn	2, 0x0100
     bb0:	0531                	.insn	2, 0x0531
     bb2:	80808013          	addi	zero,ra,-2040
     bb6:	0180                	.insn	2, 0x0180
     bb8:	0204                	.insn	2, 0x0204
     bba:	0000                	.insn	2, 0x0000
     bbc:	0111                	.insn	2, 0x0111
     bbe:	0c69                	.insn	2, 0x0c69
     bc0:	0002                	.insn	2, 0x0002
     bc2:	0000                	.insn	2, 0x0000
     bc4:	0000                	.insn	2, 0x0000
     bc6:	0000                	.insn	2, 0x0000
     bc8:	c812                	.insn	2, 0xc812
     bca:	0002                	.insn	2, 0x0002
     bcc:	7300                	.insn	2, 0x7300
     bce:	0060                	.insn	2, 0x0060
     bd0:	0000                	.insn	2, 0x0000
     bd2:	c201                	.insn	2, 0xc201
     bd4:	120d                	.insn	2, 0x120d
     bd6:	0260                	.insn	2, 0x0260
     bd8:	0000                	.insn	2, 0x0000
     bda:	00006073          	csrsi	0x0,0
     bde:	0100                	.insn	2, 0x0100
     be0:	093c                	.insn	2, 0x093c
     be2:	0264201b          	.insn	4, 0x0264201b
     be6:	0000                	.insn	2, 0x0000
     be8:	ef1c                	.insn	2, 0xef1c
     bea:	0001                	.insn	2, 0x0001
     bec:	1000                	.insn	2, 0x1000
     bee:	2d01                	.insn	2, 0x2d01
     bf0:	1b0c                	.insn	2, 0x1b0c
     bf2:	f71d                	.insn	2, 0xf71d
     bf4:	0001                	.insn	2, 0x0001
     bf6:	0000                	.insn	2, 0x0000
     bf8:	001c                	.insn	2, 0x001c
     bfa:	0002                	.insn	2, 0x0002
     bfc:	1100                	.insn	2, 0x1100
     bfe:	3101                	.insn	2, 0x3101
     c00:	1b05                	.insn	2, 0x1b05
     c02:	041e                	.insn	2, 0x041e
     c04:	0002                	.insn	2, 0x0002
     c06:	1b00                	.insn	2, 0x1b00
     c08:	0c1f 0002 0000      	.insn	6, 0x00020c1f
     c0e:	0000                	.insn	2, 0x0000
     c10:	a212                	.insn	2, 0xa212
     c12:	74000007          	.insn	4, 0x74000007
     c16:	0040                	.insn	2, 0x0040
     c18:	0000                	.insn	2, 0x0000
     c1a:	c301                	.insn	2, 0xc301
     c1c:	270d                	.insn	2, 0x270d
     c1e:	4074                	.insn	2, 0x4074
     c20:	0000                	.insn	2, 0x0000
     c22:	ae00                	.insn	2, 0xae00
     c24:	1e000007          	.insn	4, 0x1e000007
     c28:	af21                	.insn	2, 0xaf21
     c2a:	27000007          	.insn	4, 0x27000007
     c2e:	3474                	.insn	2, 0x3474
     c30:	0000                	.insn	2, 0x0000
     c32:	b700                	.insn	2, 0xb700
     c34:	1e000007          	.insn	4, 0x1e000007
     c38:	b822                	.insn	2, 0xb822
     c3a:	12000007          	.insn	4, 0x12000007
     c3e:	0260                	.insn	2, 0x0260
     c40:	0000                	.insn	2, 0x0000
     c42:	1475                	.insn	2, 0x1475
     c44:	0000                	.insn	2, 0x0000
     c46:	0100                	.insn	2, 0x0100
     c48:	0944                	.insn	2, 0x0944
     c4a:	ef1d                	.insn	2, 0xef1d
     c4c:	0001                	.insn	2, 0x0001
     c4e:	7600                	.insn	2, 0x7600
     c50:	0004                	.insn	2, 0x0004
     c52:	0000                	.insn	2, 0x0000
     c54:	2d01                	.insn	2, 0x2d01
     c56:	120c                	.insn	2, 0x120c
     c58:	0200                	.insn	2, 0x0200
     c5a:	0000                	.insn	2, 0x0000
     c5c:	00000477          	.insn	4, 0x0477
     c60:	0100                	.insn	2, 0x0100
     c62:	0531                	.insn	2, 0x0531
     c64:	80808013          	addi	zero,ra,-2040
     c68:	0180                	.insn	2, 0x0180
     c6a:	0204                	.insn	2, 0x0204
     c6c:	0000                	.insn	2, 0x0000
     c6e:	0111                	.insn	2, 0x0111
     c70:	0c69                	.insn	2, 0x0c69
     c72:	0002                	.insn	2, 0x0002
     c74:	0000                	.insn	2, 0x0000
     c76:	0000                	.insn	2, 0x0000
     c78:	0000                	.insn	2, 0x0000
     c7a:	c812                	.insn	2, 0xc812
     c7c:	0002                	.insn	2, 0x0002
     c7e:	7800                	.insn	2, 0x7800
     c80:	0060                	.insn	2, 0x0060
     c82:	0000                	.insn	2, 0x0000
     c84:	c401                	.insn	2, 0xc401
     c86:	120d                	.insn	2, 0x120d
     c88:	0260                	.insn	2, 0x0260
     c8a:	0000                	.insn	2, 0x0000
     c8c:	6078                	.insn	2, 0x6078
     c8e:	0000                	.insn	2, 0x0000
     c90:	0100                	.insn	2, 0x0100
     c92:	093c                	.insn	2, 0x093c
     c94:	0264261b          	.insn	4, 0x0264261b
     c98:	0000                	.insn	2, 0x0000
     c9a:	ef1c                	.insn	2, 0xef1c
     c9c:	0001                	.insn	2, 0x0001
     c9e:	1200                	.insn	2, 0x1200
     ca0:	2d01                	.insn	2, 0x2d01
     ca2:	1b0c                	.insn	2, 0x1b0c
     ca4:	0001f723          	.insn	4, 0x0001f723
     ca8:	0000                	.insn	2, 0x0000
     caa:	001c                	.insn	2, 0x001c
     cac:	0002                	.insn	2, 0x0002
     cae:	1300                	.insn	2, 0x1300
     cb0:	3101                	.insn	2, 0x3101
     cb2:	1b05                	.insn	2, 0x1b05
     cb4:	0424                	.insn	2, 0x0424
     cb6:	0002                	.insn	2, 0x0002
     cb8:	1b00                	.insn	2, 0x1b00
     cba:	0c25                	.insn	2, 0x0c25
     cbc:	0002                	.insn	2, 0x0002
     cbe:	0000                	.insn	2, 0x0000
     cc0:	0000                	.insn	2, 0x0000
     cc2:	a212                	.insn	2, 0xa212
     cc4:	79000007          	.insn	4, 0x79000007
     cc8:	0040                	.insn	2, 0x0040
     cca:	0000                	.insn	2, 0x0000
     ccc:	c501                	.insn	2, 0xc501
     cce:	270d                	.insn	2, 0x270d
     cd0:	4079                	.insn	2, 0x4079
     cd2:	0000                	.insn	2, 0x0000
     cd4:	ae00                	.insn	2, 0xae00
     cd6:	1e000007          	.insn	4, 0x1e000007
     cda:	0007af27          	.insn	4, 0x0007af27
     cde:	2700                	.insn	2, 0x2700
     ce0:	3479                	.insn	2, 0x3479
     ce2:	0000                	.insn	2, 0x0000
     ce4:	b700                	.insn	2, 0xb700
     ce6:	1e000007          	.insn	4, 0x1e000007
     cea:	b828                	.insn	2, 0xb828
     cec:	12000007          	.insn	4, 0x12000007
     cf0:	0260                	.insn	2, 0x0260
     cf2:	0000                	.insn	2, 0x0000
     cf4:	147a                	.insn	2, 0x147a
     cf6:	0000                	.insn	2, 0x0000
     cf8:	0100                	.insn	2, 0x0100
     cfa:	0944                	.insn	2, 0x0944
     cfc:	ef1d                	.insn	2, 0xef1d
     cfe:	0001                	.insn	2, 0x0001
     d00:	7b00                	.insn	2, 0x7b00
     d02:	0004                	.insn	2, 0x0004
     d04:	0000                	.insn	2, 0x0000
     d06:	2d01                	.insn	2, 0x2d01
     d08:	120c                	.insn	2, 0x120c
     d0a:	0200                	.insn	2, 0x0200
     d0c:	0000                	.insn	2, 0x0000
     d0e:	047c                	.insn	2, 0x047c
     d10:	0000                	.insn	2, 0x0000
     d12:	0100                	.insn	2, 0x0100
     d14:	0531                	.insn	2, 0x0531
     d16:	80808013          	addi	zero,ra,-2040
     d1a:	0180                	.insn	2, 0x0180
     d1c:	0204                	.insn	2, 0x0204
     d1e:	0000                	.insn	2, 0x0000
     d20:	0111                	.insn	2, 0x0111
     d22:	0c68                	.insn	2, 0x0c68
     d24:	0002                	.insn	2, 0x0002
     d26:	0000                	.insn	2, 0x0000
     d28:	0000                	.insn	2, 0x0000
     d2a:	0000                	.insn	2, 0x0000
     d2c:	c812                	.insn	2, 0xc812
     d2e:	0002                	.insn	2, 0x0002
     d30:	7d00                	.insn	2, 0x7d00
     d32:	0018                	.insn	2, 0x0018
     d34:	0000                	.insn	2, 0x0000
     d36:	c601                	.insn	2, 0xc601
     d38:	120d                	.insn	2, 0x120d
     d3a:	0260                	.insn	2, 0x0260
     d3c:	0000                	.insn	2, 0x0000
     d3e:	187d                	.insn	2, 0x187d
     d40:	0000                	.insn	2, 0x0000
     d42:	0100                	.insn	2, 0x0100
     d44:	093c                	.insn	2, 0x093c
     d46:	ef1d                	.insn	2, 0xef1d
     d48:	0001                	.insn	2, 0x0001
     d4a:	7e00                	.insn	2, 0x7e00
     d4c:	0004                	.insn	2, 0x0004
     d4e:	0000                	.insn	2, 0x0000
     d50:	2d01                	.insn	2, 0x2d01
     d52:	120c                	.insn	2, 0x120c
     d54:	0200                	.insn	2, 0x0200
     d56:	0000                	.insn	2, 0x0000
     d58:	087f 0000 0100 0531 	.insn	10, 0x8013053101000000087f
     d60:	8013 
     d62:	8080                	.insn	2, 0x8080
     d64:	0180                	.insn	2, 0x0180
     d66:	0204                	.insn	2, 0x0204
     d68:	0000                	.insn	2, 0x0000
     d6a:	020c0a13          	addi	s4,s8,32
     d6e:	0000                	.insn	2, 0x0000
     d70:	0000                	.insn	2, 0x0000
     d72:	0000                	.insn	2, 0x0000
     d74:	f412                	.insn	2, 0xf412
     d76:	0002                	.insn	2, 0x0002
     d78:	8000                	.insn	2, 0x8000
     d7a:	0c01                	.insn	2, 0x0c01
     d7c:	0000                	.insn	2, 0x0000
     d7e:	0100                	.insn	2, 0x0100
     d80:	09c9                	.insn	2, 0x09c9
     d82:	02f8291b          	.insn	4, 0x02f8291b
     d86:	0000                	.insn	2, 0x0000
     d88:	0000                	.insn	2, 0x0000
     d8a:	c812                	.insn	2, 0xc812
     d8c:	0002                	.insn	2, 0x0002
     d8e:	8100                	.insn	2, 0x8100
     d90:	2401                	.insn	2, 0x2401
     d92:	0000                	.insn	2, 0x0000
     d94:	0100                	.insn	2, 0x0100
     d96:	05cc                	.insn	2, 0x05cc
     d98:	02cc2a1b          	.insn	4, 0x02cc2a1b
     d9c:	0000                	.insn	2, 0x0000
     d9e:	601c                	.insn	2, 0x601c
     da0:	0002                	.insn	2, 0x0002
     da2:	1400                	.insn	2, 0x1400
     da4:	3c01                	.insn	2, 0x3c01
     da6:	1d09                	.insn	2, 0x1d09
     da8:	000001ef          	jal	gp,da8 <_start-0xff258>
     dac:	0182                	.insn	2, 0x0182
     dae:	0004                	.insn	2, 0x0004
     db0:	0000                	.insn	2, 0x0000
     db2:	2d01                	.insn	2, 0x2d01
     db4:	120c                	.insn	2, 0x120c
     db6:	0200                	.insn	2, 0x0200
     db8:	0000                	.insn	2, 0x0000
     dba:	00040183          	lb	gp,0(s0)
     dbe:	0000                	.insn	2, 0x0000
     dc0:	3101                	.insn	2, 0x3101
     dc2:	1305                	.insn	2, 0x1305
     dc4:	8080                	.insn	2, 0x8080
     dc6:	8080                	.insn	2, 0x8080
     dc8:	0401                	.insn	2, 0x0401
     dca:	0002                	.insn	2, 0x0002
     dcc:	0000                	.insn	2, 0x0000
     dce:	0000                	.insn	2, 0x0000
     dd0:	a212                	.insn	2, 0xa212
     dd2:	84000007          	.insn	4, 0x84000007
     dd6:	4001                	.insn	2, 0x4001
     dd8:	0000                	.insn	2, 0x0000
     dda:	0100                	.insn	2, 0x0100
     ddc:	05cd                	.insn	2, 0x05cd
     dde:	40018427          	.insn	4, 0x40018427
     de2:	0000                	.insn	2, 0x0000
     de4:	ae00                	.insn	2, 0xae00
     de6:	1e000007          	.insn	4, 0x1e000007
     dea:	0007af2b          	.insn	4, 0x0007af2b
     dee:	2700                	.insn	2, 0x2700
     df0:	0184                	.insn	2, 0x0184
     df2:	0034                	.insn	2, 0x0034
     df4:	0000                	.insn	2, 0x0000
     df6:	000007b7          	lui	a5,0x0
     dfa:	2c1e                	.insn	2, 0x2c1e
     dfc:	07b8                	.insn	2, 0x07b8
     dfe:	0000                	.insn	2, 0x0000
     e00:	6012                	.insn	2, 0x6012
     e02:	0002                	.insn	2, 0x0002
     e04:	8500                	.insn	2, 0x8500
     e06:	1401                	.insn	2, 0x1401
     e08:	0000                	.insn	2, 0x0000
     e0a:	0100                	.insn	2, 0x0100
     e0c:	0944                	.insn	2, 0x0944
     e0e:	ef1d                	.insn	2, 0xef1d
     e10:	0001                	.insn	2, 0x0001
     e12:	8600                	.insn	2, 0x8600
     e14:	0401                	.insn	2, 0x0401
     e16:	0000                	.insn	2, 0x0000
     e18:	0100                	.insn	2, 0x0100
     e1a:	0c2d                	.insn	2, 0x0c2d
     e1c:	0012                	.insn	2, 0x0012
     e1e:	0002                	.insn	2, 0x0002
     e20:	8700                	.insn	2, 0x8700
     e22:	0401                	.insn	2, 0x0401
     e24:	0000                	.insn	2, 0x0000
     e26:	0100                	.insn	2, 0x0100
     e28:	0531                	.insn	2, 0x0531
     e2a:	80808013          	addi	zero,ra,-2040
     e2e:	0180                	.insn	2, 0x0180
     e30:	0204                	.insn	2, 0x0204
     e32:	0000                	.insn	2, 0x0000
     e34:	0111                	.insn	2, 0x0111
     e36:	0c5f 0002 0000      	.insn	6, 0x00020c5f
     e3c:	0000                	.insn	2, 0x0000
     e3e:	0000                	.insn	2, 0x0000
     e40:	c82d                	.insn	2, 0xc82d
     e42:	0002                	.insn	2, 0x0002
     e44:	8800                	.insn	2, 0x8800
     e46:	0801                	.insn	2, 0x0801
     e48:	0000                	.insn	2, 0x0000
     e4a:	0100                	.insn	2, 0x0100
     e4c:	1200                	.insn	2, 0x1200
     e4e:	0260                	.insn	2, 0x0260
     e50:	0000                	.insn	2, 0x0000
     e52:	0188                	.insn	2, 0x0188
     e54:	0008                	.insn	2, 0x0008
     e56:	0000                	.insn	2, 0x0000
     e58:	3c01                	.insn	2, 0x3c01
     e5a:	1d09                	.insn	2, 0x1d09
     e5c:	0200                	.insn	2, 0x0200
     e5e:	0000                	.insn	2, 0x0000
     e60:	0188                	.insn	2, 0x0188
     e62:	0008                	.insn	2, 0x0008
     e64:	0000                	.insn	2, 0x0000
     e66:	3101                	.insn	2, 0x3101
     e68:	0005                	.insn	2, 0x0005
     e6a:	1200                	.insn	2, 0x1200
     e6c:	02c8                	.insn	2, 0x02c8
     e6e:	0000                	.insn	2, 0x0000
     e70:	0189                	.insn	2, 0x0189
     e72:	0014                	.insn	2, 0x0014
     e74:	0000                	.insn	2, 0x0000
     e76:	ce01                	.insn	2, 0xce01
     e78:	1205                	.insn	2, 0x1205
     e7a:	0260                	.insn	2, 0x0260
     e7c:	0000                	.insn	2, 0x0000
     e7e:	0189                	.insn	2, 0x0189
     e80:	0014                	.insn	2, 0x0014
     e82:	0000                	.insn	2, 0x0000
     e84:	3c01                	.insn	2, 0x3c01
     e86:	1d09                	.insn	2, 0x1d09
     e88:	000001ef          	jal	gp,e88 <_start-0xff178>
     e8c:	018a                	.insn	2, 0x018a
     e8e:	0004                	.insn	2, 0x0004
     e90:	0000                	.insn	2, 0x0000
     e92:	2d01                	.insn	2, 0x2d01
     e94:	000c                	.insn	2, 0x000c
     e96:	0000                	.insn	2, 0x0000
     e98:	c70a                	.insn	2, 0xc70a
     e9a:	0001                	.insn	2, 0x0001
     e9c:	0000                	.insn	2, 0x0000
     e9e:	0636                	.insn	2, 0x0636
     ea0:	0000                	.insn	2, 0x0000
     ea2:	0005                	.insn	2, 0x0005
     ea4:	0401                	.insn	2, 0x0401
     ea6:	0261                	.insn	2, 0x0261
     ea8:	0000                	.insn	2, 0x0000
     eaa:	0001                	.insn	2, 0x0001
     eac:	001d                	.insn	2, 0x001d
     eae:	e401                	.insn	2, 0xe401
     eb0:	0000                	.insn	2, 0x0000
     eb2:	4900                	.insn	2, 0x4900
     eb4:	000a                	.insn	2, 0x000a
     eb6:	0200                	.insn	2, 0x0200
     eb8:	9405                	.insn	2, 0x9405
     eba:	0009                	.insn	2, 0x0009
     ebc:	5000                	.insn	2, 0x5000
     ebe:	0002                	.insn	2, 0x0002
     ec0:	7f00                	.insn	2, 0x7f00
     ec2:	0001                	.insn	2, 0x0001
     ec4:	5500                	.insn	2, 0x5500
     ec6:	0009                	.insn	2, 0x0009
     ec8:	0200                	.insn	2, 0x0200
     eca:	0035                	.insn	2, 0x0035
     ecc:	0000                	.insn	2, 0x0000
     ece:	c201                	.insn	2, 0xc201
     ed0:	a102                	.insn	2, 0xa102
     ed2:	0300                	.insn	2, 0x0300
     ed4:	0041                	.insn	2, 0x0041
     ed6:	0000                	.insn	2, 0x0000
     ed8:	4504                	.insn	2, 0x4504
     eda:	0000                	.insn	2, 0x0000
     edc:	1100                	.insn	2, 0x1100
     ede:	0500                	.insn	2, 0x0500
     ee0:	06010803          	lb	a6,96(sp)
     ee4:	0804                	.insn	2, 0x0804
     ee6:	00540707          	.insn	4, 0x00540707
     eea:	0000                	.insn	2, 0x0000
     eec:	0b01                	.insn	2, 0x0b01
     eee:	0201                	.insn	2, 0x0201
     ef0:	01a1                	.insn	2, 0x01a1
     ef2:	00004103          	lbu	sp,0(zero) # 0 <_start-0x100000>
     ef6:	0400                	.insn	2, 0x0400
     ef8:	0045                	.insn	2, 0x0045
     efa:	0000                	.insn	2, 0x0000
     efc:	6b070003          	lb	zero,1712(a4) # 1ced0 <_start-0xe3130>
     f00:	0000                	.insn	2, 0x0000
     f02:	0100                	.insn	2, 0x0100
     f04:	a1020133          	.insn	4, 0xa1020133
     f08:	0302                	.insn	2, 0x0302
     f0a:	0041                	.insn	2, 0x0041
     f0c:	0000                	.insn	2, 0x0000
     f0e:	4504                	.insn	2, 0x4504
     f10:	0000                	.insn	2, 0x0000
     f12:	2300                	.insn	2, 0x2300
     f14:	0700                	.insn	2, 0x0700
     f16:	0082                	.insn	2, 0x0082
     f18:	0000                	.insn	2, 0x0000
     f1a:	3b01                	.insn	2, 0x3b01
     f1c:	0201                	.insn	2, 0x0201
     f1e:	03a1                	.insn	2, 0x03a1
     f20:	00004103          	lbu	sp,0(zero) # 0 <_start-0x100000>
     f24:	0400                	.insn	2, 0x0400
     f26:	0045                	.insn	2, 0x0045
     f28:	0000                	.insn	2, 0x0000
     f2a:	0024                	.insn	2, 0x0024
     f2c:	00009907          	.insn	4, 0x9907
     f30:	0100                	.insn	2, 0x0100
     f32:	0144                	.insn	2, 0x0144
     f34:	a102                	.insn	2, 0xa102
     f36:	0304                	.insn	2, 0x0304
     f38:	0041                	.insn	2, 0x0041
     f3a:	0000                	.insn	2, 0x0000
     f3c:	4504                	.insn	2, 0x4504
     f3e:	0000                	.insn	2, 0x0000
     f40:	3000                	.insn	2, 0x3000
     f42:	0800                	.insn	2, 0x0800
     f44:	0509                	.insn	2, 0x0509
     f46:	00b2                	.insn	2, 0x00b2
     f48:	0000                	.insn	2, 0x0000
     f4a:	e001                	.insn	2, 0xe001
     f4c:	a102                	.insn	2, 0xa102
     f4e:	0000                	.insn	2, 0x0000
     f50:	0000be03          	.insn	4, 0xbe03
     f54:	0400                	.insn	2, 0x0400
     f56:	0045                	.insn	2, 0x0045
     f58:	0000                	.insn	2, 0x0000
     f5a:	0011                	.insn	2, 0x0011
     f5c:	410a                	.insn	2, 0x410a
     f5e:	0000                	.insn	2, 0x0000
     f60:	0800                	.insn	2, 0x0800
     f62:	0509                	.insn	2, 0x0509
     f64:	00b2                	.insn	2, 0x00b2
     f66:	0000                	.insn	2, 0x0000
     f68:	d701                	.insn	2, 0xd701
     f6a:	a102                	.insn	2, 0xa102
     f6c:	0000                	.insn	2, 0x0000
     f6e:	0000d50b          	.insn	4, 0xd50b
     f72:	0c00                	.insn	2, 0x0c00
     f74:	00dd                	.insn	2, 0x00dd
     f76:	0000                	.insn	2, 0x0000
     f78:	05070207          	.insn	4, 0x05070207
     f7c:	0806                	.insn	2, 0x0806
     f7e:	0b01                	.insn	2, 0x0b01
     f80:	00e6                	.insn	2, 0x00e6
     f82:	0000                	.insn	2, 0x0000
     f84:	d50a                	.insn	2, 0xd50a
     f86:	0000                	.insn	2, 0x0000
     f88:	0500                	.insn	2, 0x0500
     f8a:	0508                	.insn	2, 0x0508
     f8c:	0c04                	.insn	2, 0x0c04
     f8e:	000000f7          	.insn	4, 0x00f7
     f92:	020a                	.insn	2, 0x020a
     f94:	0509                	.insn	2, 0x0509
     f96:	0709                	.insn	2, 0x0709
     f98:	0c04                	.insn	2, 0x0c04
     f9a:	000000ef          	jal	f9a <_start-0xff066>
     f9e:	0b0b020b          	.insn	4, 0x0b0b020b
     fa2:	0108                	.insn	2, 0x0108
     fa4:	0000                	.insn	2, 0x0000
     fa6:	0e0d                	.insn	2, 0x0e0d
     fa8:	2805                	.insn	2, 0x2805
     faa:	0000                	.insn	2, 0x0000
     fac:	0100                	.insn	2, 0x0100
     fae:	1d52                	.insn	2, 0x1d52
     fb0:	0301                	.insn	2, 0x0301
     fb2:	0000060b          	.insn	4, 0x060b
     fb6:	245a010f          	.insn	4, 0x245a010f
     fba:	0301                	.insn	2, 0x0301
     fbc:	0000060b          	.insn	4, 0x060b
     fc0:	0010                	.insn	2, 0x0010
     fc2:	0125                	.insn	2, 0x0125
     fc4:	00010303          	lb	t1,0(sp)
     fc8:	1000                	.insn	2, 0x1000
     fca:	2602                	.insn	2, 0x2602
     fcc:	0301                	.insn	2, 0x0301
     fce:	000000fb          	.insn	4, 0x00fb
     fd2:	0111                	.insn	2, 0x0111
     fd4:	011c                	.insn	2, 0x011c
     fd6:	d004                	.insn	2, 0xd004
     fd8:	0000                	.insn	2, 0x0000
     fda:	1200                	.insn	2, 0x1200
     fdc:	5b01                	.insn	2, 0x5b01
     fde:	0118                	.insn	2, 0x0118
     fe0:	e105                	.insn	2, 0xe105
     fe2:	0000                	.insn	2, 0x0000
     fe4:	0000                	.insn	2, 0x0000
     fe6:	060e                	.insn	2, 0x060e
     fe8:	0030                	.insn	2, 0x0030
     fea:	0000                	.insn	2, 0x0000
     fec:	5201                	.insn	2, 0x5201
     fee:	011e                	.insn	2, 0x011e
     ff0:	0000eb0b          	.insn	4, 0xeb0b
     ff4:	1000                	.insn	2, 0x1000
     ff6:	0b012703          	lw	a4,176(sp)
     ffa:	00000103          	lb	sp,0(zero) # 0 <_start-0x100000>
     ffe:	0410                	.insn	2, 0x0410
    1000:	0128                	.insn	2, 0x0128
    1002:	0001030b          	.insn	4, 0x0001030b
    1006:	1000                	.insn	2, 0x1000
    1008:	2605                	.insn	2, 0x2605
    100a:	0b01                	.insn	2, 0x0b01
    100c:	000000fb          	.insn	4, 0x00fb
    1010:	0611                	.insn	2, 0x0611
    1012:	0129                	.insn	2, 0x0129
    1014:	e10d                	.insn	2, 0xe10d
    1016:	0000                	.insn	2, 0x0000
    1018:	1200                	.insn	2, 0x1200
    101a:	5b01                	.insn	2, 0x5b01
    101c:	012a                	.insn	2, 0x012a
    101e:	e10e                	.insn	2, 0xe10e
    1020:	0000                	.insn	2, 0x0000
    1022:	0000                	.insn	2, 0x0000
    1024:	070e                	.insn	2, 0x070e
    1026:	0020                	.insn	2, 0x0020
    1028:	0000                	.insn	2, 0x0000
    102a:	5201                	.insn	2, 0x5201
    102c:	011f 0b1b 0006      	.insn	6, 0x00060b1b011f
    1032:	0f00                	.insn	2, 0x0f00
    1034:	5a01                	.insn	2, 0x5a01
    1036:	0b1b012b          	.insn	4, 0x0b1b012b
    103a:	0006                	.insn	2, 0x0006
    103c:	0f00                	.insn	2, 0x0f00
    103e:	5b01                	.insn	2, 0x5b01
    1040:	411b011b          	.insn	4, 0x411b011b
    1044:	0000                	.insn	2, 0x0000
    1046:	1000                	.insn	2, 0x1000
    1048:	2608                	.insn	2, 0x2608
    104a:	1b01                	.insn	2, 0x1b01
    104c:	000000fb          	.insn	4, 0x00fb
    1050:	0711                	.insn	2, 0x0711
    1052:	012c                	.insn	2, 0x012c
    1054:	d01c                	.insn	2, 0xd01c
    1056:	0000                	.insn	2, 0x0000
    1058:	0000                	.insn	2, 0x0000
    105a:	56010c13          	addi	s8,sp,1376
    105e:	000000ef          	jal	105e <_start-0xfefa2>
    1062:	0d14                	.insn	2, 0x0d14
    1064:	5601                	.insn	2, 0x5601
    1066:	000000ef          	jal	1066 <_start-0xfef9a>
    106a:	0e14                	.insn	2, 0x0e14
    106c:	5601                	.insn	2, 0x5601
    106e:	000001ef          	jal	gp,106e <_start-0xfef92>
    1072:	0f15                	.insn	2, 0x0f15
    1074:	5901                	.insn	2, 0x5901
    1076:	000000ef          	jal	1076 <_start-0xfef8a>
    107a:	1015                	.insn	2, 0x1015
    107c:	5801                	.insn	2, 0x5801
    107e:	000000ef          	jal	107e <_start-0xfef82>
    1082:	1516                	.insn	2, 0x1516
    1084:	0111                	.insn	2, 0x0111
    1086:	0000eb5b          	.insn	4, 0xeb5b
    108a:	0000                	.insn	2, 0x0000
    108c:	0b00                	.insn	2, 0x0b00
    108e:	000000ef          	jal	108e <_start-0xfef72>
    1092:	00f80817          	auipc	a6,0xf80
    1096:	0000                	.insn	2, 0x0000
    1098:	5201                	.insn	2, 0x5201
    109a:	0120                	.insn	2, 0x0120
    109c:	14091067          	.insn	4, 0x14091067
    10a0:	6701                	.insn	2, 0x6701
    10a2:	000000eb          	.insn	4, 0x00eb
    10a6:	0212                	.insn	2, 0x0212
    10a8:	0691                	.insn	2, 0x0691
    10aa:	0c6a012b          	.insn	4, 0x0c6a012b
    10ae:	0006                	.insn	2, 0x0006
    10b0:	1100                	.insn	2, 0x1100
    10b2:	2d0a                	.insn	2, 0x2d0a
    10b4:	6b01                	.insn	2, 0x6b01
    10b6:	000000eb          	.insn	4, 0x00eb
    10ba:	0b11                	.insn	2, 0x0b11
    10bc:	010d                	.insn	2, 0x010d
    10be:	ef69                	.insn	2, 0xef69
    10c0:	0000                	.insn	2, 0x0000
    10c2:	1800                	.insn	2, 0x1800
    10c4:	4809                	.insn	2, 0x4809
    10c6:	0000                	.insn	2, 0x0000
    10c8:	1100                	.insn	2, 0x1100
    10ca:	0e0e                	.insn	2, 0x0e0e
    10cc:	7a01                	.insn	2, 0x7a01
    10ce:	000000ef          	jal	10ce <_start-0xfef32>
    10d2:	bc19                	.insn	2, 0xbc19
    10d4:	0001                	.insn	2, 0x0001
    10d6:	0900                	.insn	2, 0x0900
    10d8:	0034                	.insn	2, 0x0034
    10da:	0000                	.insn	2, 0x0000
    10dc:	7b01                	.insn	2, 0x7b01
    10de:	1a0d                	.insn	2, 0x1a0d
    10e0:	d40c                	.insn	2, 0xd40c
    10e2:	0001                	.insn	2, 0x0001
    10e4:	1a00                	.insn	2, 0x1a00
    10e6:	dc0d                	.insn	2, 0xdc0d
    10e8:	0001                	.insn	2, 0x0001
    10ea:	1b00                	.insn	2, 0x1b00
    10ec:	3409                	.insn	2, 0x3409
    10ee:	0000                	.insn	2, 0x0000
    10f0:	e400                	.insn	2, 0xe400
    10f2:	0001                	.insn	2, 0x0001
    10f4:	1c00                	.insn	2, 0x1c00
    10f6:	5f01                	.insn	2, 0x5f01
    10f8:	01e5                	.insn	2, 0x01e5
    10fa:	0000                	.insn	2, 0x0000
    10fc:	0000                	.insn	2, 0x0000
    10fe:	1d00                	.insn	2, 0x1d00
    1100:	0274                	.insn	2, 0x0274
    1102:	0000                	.insn	2, 0x0000
    1104:	1e0a                	.insn	2, 0x1e0a
    1106:	0274                	.insn	2, 0x0274
    1108:	0000                	.insn	2, 0x0000
    110a:	02741e0b          	.insn	4, 0x02741e0b
    110e:	0000                	.insn	2, 0x0000
    1110:	000c                	.insn	2, 0x000c
    1112:	121f 5301 4120      	.insn	6, 0x41205301121f
    1118:	0000                	.insn	2, 0x0000
    111a:	0000                	.insn	2, 0x0000
    111c:	02cc0d17          	auipc	s10,0x2cc0
    1120:	0000                	.insn	2, 0x0000
    1122:	5201                	.insn	2, 0x5201
    1124:	0121                	.insn	2, 0x0121
    1126:	300f1087          	.insn	4, 0x300f1087
    112a:	8701                	.insn	2, 0x8701
    112c:	0524                	.insn	2, 0x0524
    112e:	0000                	.insn	2, 0x0000
    1130:	0212                	.insn	2, 0x0212
    1132:	1891                	.insn	2, 0x1891
    1134:	012e                	.insn	2, 0x012e
    1136:	1888                	.insn	2, 0x1888
    1138:	0006                	.insn	2, 0x0006
    113a:	2100                	.insn	2, 0x2100
    113c:	01cd0133          	add	sp,s10,t3
    1140:	221f 1200 9102      	.insn	6, 0x91021200221f
    1146:	2b0d                	.insn	2, 0x2b0d
    1148:	aa01                	.insn	2, 0xaa01
    114a:	061e                	.insn	2, 0x061e
    114c:	0000                	.insn	2, 0x0000
    114e:	1011                	.insn	2, 0x1011
    1150:	0131                	.insn	2, 0x0131
    1152:	eb9e                	.insn	2, 0xeb9e
    1154:	0000                	.insn	2, 0x0000
    1156:	1100                	.insn	2, 0x1100
    1158:	0d11                	.insn	2, 0x0d11
    115a:	a001                	.insn	2, 0xa001
    115c:	000000f7          	.insn	4, 0x00f7
    1160:	1211                	.insn	2, 0x1211
    1162:	0111                	.insn	2, 0x0111
    1164:	0000ebab          	.insn	4, 0xebab
    1168:	0000                	.insn	2, 0x0000
    116a:	0e18                	.insn	2, 0x0e18
    116c:	00c0                	.insn	2, 0x00c0
    116e:	0000                	.insn	2, 0x0000
    1170:	1311                	.insn	2, 0x1311
    1172:	0131                	.insn	2, 0x0131
    1174:	0000f7bf b00f1800 	.insn	8, 0xb00f18000000f7bf
    117c:	0000                	.insn	2, 0x0000
    117e:	1100                	.insn	2, 0x1100
    1180:	1114                	.insn	2, 0x1114
    1182:	c001                	.insn	2, 0xc001
    1184:	000000eb          	.insn	4, 0x00eb
    1188:	0f18                	.insn	2, 0x0f18
    118a:	00b0                	.insn	2, 0x00b0
    118c:	0000                	.insn	2, 0x0000
    118e:	1511                	.insn	2, 0x1511
    1190:	0132                	.insn	2, 0x0132
    1192:	f7c1                	.insn	2, 0xf7c1
    1194:	0000                	.insn	2, 0x0000
    1196:	0000                	.insn	2, 0x0000
    1198:	0000                	.insn	2, 0x0000
    119a:	1018                	.insn	2, 0x1018
    119c:	0038                	.insn	2, 0x0038
    119e:	0000                	.insn	2, 0x0000
    11a0:	1611                	.insn	2, 0x1611
    11a2:	0118                	.insn	2, 0x0118
    11a4:	2496                	.insn	2, 0x2496
    11a6:	0005                	.insn	2, 0x0005
    11a8:	0000                	.insn	2, 0x0000
    11aa:	02741e23          	sh	t2,60(s0)
    11ae:	0000                	.insn	2, 0x0000
    11b0:	1e11                	.insn	2, 0x1e11
    11b2:	0274                	.insn	2, 0x0274
    11b4:	0000                	.insn	2, 0x0000
    11b6:	1e12                	.insn	2, 0x1e12
    11b8:	0274                	.insn	2, 0x0274
    11ba:	0000                	.insn	2, 0x0000
    11bc:	02741e13          	slli	t3,s0,0x27
    11c0:	0000                	.insn	2, 0x0000
    11c2:	1e14                	.insn	2, 0x1e14
    11c4:	0274                	.insn	2, 0x0274
    11c6:	0000                	.insn	2, 0x0000
    11c8:	1e15                	.insn	2, 0x1e15
    11ca:	0274                	.insn	2, 0x0274
    11cc:	0000                	.insn	2, 0x0000
    11ce:	1e16                	.insn	2, 0x1e16
    11d0:	0274                	.insn	2, 0x0274
    11d2:	0000                	.insn	2, 0x0000
    11d4:	02741e17          	auipc	t3,0x2741
    11d8:	0000                	.insn	2, 0x0000
    11da:	1e18                	.insn	2, 0x1e18
    11dc:	0274                	.insn	2, 0x0274
    11de:	0000                	.insn	2, 0x0000
    11e0:	1e19                	.insn	2, 0x1e19
    11e2:	0274                	.insn	2, 0x0274
    11e4:	0000                	.insn	2, 0x0000
    11e6:	1e1a                	.insn	2, 0x1e1a
    11e8:	0274                	.insn	2, 0x0274
    11ea:	0000                	.insn	2, 0x0000
    11ec:	02741e1b          	.insn	4, 0x02741e1b
    11f0:	0000                	.insn	2, 0x0000
    11f2:	1e1c                	.insn	2, 0x1e1c
    11f4:	0274                	.insn	2, 0x0274
    11f6:	0000                	.insn	2, 0x0000
    11f8:	1e1d                	.insn	2, 0x1e1d
    11fa:	0274                	.insn	2, 0x0274
    11fc:	0000                	.insn	2, 0x0000
    11fe:	1e1e                	.insn	2, 0x1e1e
    1200:	0274                	.insn	2, 0x0274
    1202:	0000                	.insn	2, 0x0000
    1204:	001f 2024 00c4      	.insn	6, 0x00c42024001f
    120a:	0000                	.insn	2, 0x0000
    120c:	5201                	.insn	2, 0x5201
    120e:	04f1                	.insn	2, 0x04f1
    1210:	0000                	.insn	2, 0x0000
    1212:	1725                	.insn	2, 0x1725
    1214:	04f9                	.insn	2, 0x04f9
    1216:	0000                	.insn	2, 0x0000
    1218:	0126                	.insn	2, 0x0126
    121a:	0005015b          	.insn	4, 0x0005015b
    121e:	1a00                	.insn	2, 0x1a00
    1220:	0918                	.insn	2, 0x0918
    1222:	0005                	.insn	2, 0x0005
    1224:	2700                	.insn	2, 0x2700
    1226:	1101                	.insn	2, 0x1101
    1228:	0005                	.insn	2, 0x0005
    122a:	1a00                	.insn	2, 0x1a00
    122c:	1219                	.insn	2, 0x1219
    122e:	0005                	.insn	2, 0x0005
    1230:	1a00                	.insn	2, 0x1a00
    1232:	1a1a                	.insn	2, 0x1a1a
    1234:	0005                	.insn	2, 0x0005
    1236:	0000                	.insn	2, 0x0000
    1238:	2800                	.insn	2, 0x2800
    123a:	14dd0113          	addi	sp,s10,333 # 2cc1269 <_stack_top+0x2bb52a9>
    123e:	0114                	.insn	2, 0x0114
    1240:	efdd                	.insn	2, 0xefdd
    1242:	0000                	.insn	2, 0x0000
    1244:	1600                	.insn	2, 0x1600
    1246:	1115                	.insn	2, 0x1115
    1248:	de01                	.insn	2, 0xde01
    124a:	000000eb          	.insn	4, 0x00eb
    124e:	1516                	.insn	2, 0x1516
    1250:	0115                	.insn	2, 0x0115
    1252:	d5df 0000 0000      	.insn	6, 0xd5df
    1258:	0000                	.insn	2, 0x0000
    125a:	1628                	.insn	2, 0x1628
    125c:	d601                	.insn	2, 0xd601
    125e:	1414                	.insn	2, 0x1414
    1260:	d601                	.insn	2, 0xd601
    1262:	00d5                	.insn	2, 0x00d5
    1264:	0000                	.insn	2, 0x0000
    1266:	2900                	.insn	2, 0x2900
    1268:	7021                	.insn	2, 0x7021
    126a:	0002                	.insn	2, 0x0002
    126c:	0100                	.insn	2, 0x0100
    126e:	2252                	.insn	2, 0x2252
    1270:	0201                	.insn	2, 0x0201
    1272:	2a01                	.insn	2, 0x2a01
    1274:	0201341b          	.insn	4, 0x0201341b
    1278:	0301                	.insn	2, 0x0301
    127a:	0001                	.insn	2, 0x0001
    127c:	2a00                	.insn	2, 0x2a00
    127e:	351c                	.insn	2, 0x351c
    1280:	0201                	.insn	2, 0x0201
    1282:	fb01                	.insn	2, 0xfb01
    1284:	0000                	.insn	2, 0x0000
    1286:	2a00                	.insn	2, 0x2a00
    1288:	361d                	.insn	2, 0x361d
    128a:	0201                	.insn	2, 0x0201
    128c:	2e01                	.insn	2, 0x2e01
    128e:	0005                	.insn	2, 0x0005
    1290:	2b00                	.insn	2, 0x2b00
    1292:	2c1e                	.insn	2, 0x2c1e
    1294:	0301                	.insn	2, 0x0301
    1296:	e101                	.insn	2, 0xe101
    1298:	0000                	.insn	2, 0x0000
    129a:	2b00                	.insn	2, 0x2b00
    129c:	371f 0401 fb01      	.insn	6, 0xfb010401371f
    12a2:	0000                	.insn	2, 0x0000
    12a4:	2200                	.insn	2, 0x2200
    12a6:	2b02                	.insn	2, 0x2b02
    12a8:	3820                	.insn	2, 0x3820
    12aa:	0701                	.insn	2, 0x0701
    12ac:	fb01                	.insn	2, 0xfb01
    12ae:	0000                	.insn	2, 0x0000
    12b0:	2c00                	.insn	2, 0x2c00
    12b2:	0000039b          	.insn	4, 0x039b
    12b6:	010a0103          	lb	sp,16(s4)
    12ba:	2609                	.insn	2, 0x2609
    12bc:	6401                	.insn	2, 0x6401
    12be:	039f 0000 0327      	.insn	6, 0x03270000039f
    12c4:	000003a7          	.insn	4, 0x03a7
    12c8:	211a                	.insn	2, 0x211a
    12ca:	03a8                	.insn	2, 0x03a8
    12cc:	0000                	.insn	2, 0x0000
    12ce:	03b00327          	.insn	4, 0x03b00327
    12d2:	0000                	.insn	2, 0x0000
    12d4:	221a                	.insn	2, 0x221a
    12d6:	03b1                	.insn	2, 0x03b1
    12d8:	0000                	.insn	2, 0x0000
    12da:	0000                	.insn	2, 0x0000
    12dc:	1800                	.insn	2, 0x1800
    12de:	7422                	.insn	2, 0x7422
    12e0:	0000                	.insn	2, 0x0000
    12e2:	2d00                	.insn	2, 0x2d00
    12e4:	6301                	.insn	2, 0x6301
    12e6:	0111                	.insn	2, 0x0111
    12e8:	010e                	.insn	2, 0x010e
    12ea:	000000fb          	.insn	4, 0x00fb
    12ee:	bc2e                	.insn	2, 0xbc2e
    12f0:	23000003          	lb	zero,560(zero) # 230 <_start-0xffdd0>
    12f4:	0020                	.insn	2, 0x0020
    12f6:	0000                	.insn	2, 0x0000
    12f8:	1001                	.insn	2, 0x1001
    12fa:	1101                	.insn	2, 0x1101
    12fc:	1800                	.insn	2, 0x1800
    12fe:	3424                	.insn	2, 0x3424
    1300:	0000                	.insn	2, 0x0000
    1302:	2b00                	.insn	2, 0x2b00
    1304:	1d011123          	sh	a6,450(sp)
    1308:	fb01                	.insn	2, 0xfb01
    130a:	0000                	.insn	2, 0x0000
    130c:	2200                	.insn	2, 0x2200
    130e:	2b04                	.insn	2, 0x2b04
    1310:	1b24                	.insn	2, 0x1b24
    1312:	1e01                	.insn	2, 0x1e01
    1314:	d501                	.insn	2, 0xd501
    1316:	0000                	.insn	2, 0x0000
    1318:	0000                	.insn	2, 0x0000
    131a:	0000                	.insn	2, 0x0000
    131c:	741e                	.insn	2, 0x741e
    131e:	0002                	.insn	2, 0x0002
    1320:	2500                	.insn	2, 0x2500
    1322:	741e                	.insn	2, 0x741e
    1324:	0002                	.insn	2, 0x0002
    1326:	2600                	.insn	2, 0x2600
    1328:	741e                	.insn	2, 0x741e
    132a:	0002                	.insn	2, 0x0002
    132c:	2700                	.insn	2, 0x2700
    132e:	741e                	.insn	2, 0x741e
    1330:	0002                	.insn	2, 0x0002
    1332:	2800                	.insn	2, 0x2800
    1334:	741e                	.insn	2, 0x741e
    1336:	0002                	.insn	2, 0x0002
    1338:	2900                	.insn	2, 0x2900
    133a:	741e                	.insn	2, 0x741e
    133c:	0002                	.insn	2, 0x0002
    133e:	2a00                	.insn	2, 0x2a00
    1340:	741e                	.insn	2, 0x741e
    1342:	0002                	.insn	2, 0x0002
    1344:	2b00                	.insn	2, 0x2b00
    1346:	741e                	.insn	2, 0x741e
    1348:	0002                	.insn	2, 0x0002
    134a:	2c00                	.insn	2, 0x2c00
    134c:	741e                	.insn	2, 0x741e
    134e:	0002                	.insn	2, 0x0002
    1350:	2d00                	.insn	2, 0x2d00
    1352:	741e                	.insn	2, 0x741e
    1354:	0002                	.insn	2, 0x0002
    1356:	2e00                	.insn	2, 0x2e00
    1358:	7e1e                	.insn	2, 0x7e1e
    135a:	0002                	.insn	2, 0x0002
    135c:	2f00                	.insn	2, 0x2f00
    135e:	741e                	.insn	2, 0x741e
    1360:	0002                	.insn	2, 0x0002
    1362:	3000                	.insn	2, 0x3000
    1364:	741e                	.insn	2, 0x741e
    1366:	0002                	.insn	2, 0x0002
    1368:	3100                	.insn	2, 0x3100
    136a:	741e                	.insn	2, 0x741e
    136c:	0002                	.insn	2, 0x0002
    136e:	3200                	.insn	2, 0x3200
    1370:	741e                	.insn	2, 0x741e
    1372:	0002                	.insn	2, 0x0002
    1374:	3300                	.insn	2, 0x3300
    1376:	741e                	.insn	2, 0x741e
    1378:	0002                	.insn	2, 0x0002
    137a:	3400                	.insn	2, 0x3400
    137c:	741e                	.insn	2, 0x741e
    137e:	0002                	.insn	2, 0x0002
    1380:	3500                	.insn	2, 0x3500
    1382:	741e                	.insn	2, 0x741e
    1384:	0002                	.insn	2, 0x0002
    1386:	2400                	.insn	2, 0x2400
    1388:	741e                	.insn	2, 0x741e
    138a:	0002                	.insn	2, 0x0002
    138c:	3600                	.insn	2, 0x3600
    138e:	2f00                	.insn	2, 0x2f00
    1390:	ebe60117          	auipc	sp,0xebe60
    1394:	0000                	.insn	2, 0x0000
    1396:	1400                	.insn	2, 0x1400
    1398:	0118                	.insn	2, 0x0118
    139a:	24e6                	.insn	2, 0x24e6
    139c:	0005                	.insn	2, 0x0005
    139e:	1400                	.insn	2, 0x1400
    13a0:	0119                	.insn	2, 0x0119
    13a2:	29e6                	.insn	2, 0x29e6
    13a4:	0005                	.insn	2, 0x0005
    13a6:	1500                	.insn	2, 0x1500
    13a8:	0114                	.insn	2, 0x0114
    13aa:	00052ee7          	.insn	4, 0x00052ee7
    13ae:	1600                	.insn	2, 0x1600
    13b0:	1b15                	.insn	2, 0x1b15
    13b2:	f101                	.insn	2, 0xf101
    13b4:	0041                	.insn	2, 0x0041
    13b6:	0000                	.insn	2, 0x0000
    13b8:	1c15                	.insn	2, 0x1c15
    13ba:	f201                	.insn	2, 0xf201
    13bc:	000000ef          	jal	13bc <_start-0xfec44>
    13c0:	0000                	.insn	2, 0x0000
    13c2:	0000be0b          	.insn	4, 0xbe0b
    13c6:	0b00                	.insn	2, 0x0b00
    13c8:	052e                	.insn	2, 0x052e
    13ca:	0000                	.insn	2, 0x0000
    13cc:	ef0c                	.insn	2, 0xef0c
    13ce:	0000                	.insn	2, 0x0000
    13d0:	1a00                	.insn	2, 0x1a00
    13d2:	0c02                	.insn	2, 0x0c02
    13d4:	3729                	.insn	2, 0x3729
    13d6:	0224                	.insn	2, 0x0224
    13d8:	0000                	.insn	2, 0x0000
    13da:	5201                	.insn	2, 0x5201
    13dc:	01280123          	sb	s2,2(a6) # f81094 <_stack_top+0xe750d4>
    13e0:	252a                	.insn	2, 0x252a
    13e2:	0139                	.insn	2, 0x0139
    13e4:	0128                	.insn	2, 0x0128
    13e6:	000000eb          	.insn	4, 0x00eb
    13ea:	262a                	.insn	2, 0x262a
    13ec:	013a                	.insn	2, 0x013a
    13ee:	0128                	.insn	2, 0x0128
    13f0:	062a                	.insn	2, 0x062a
    13f2:	0000                	.insn	2, 0x0000
    13f4:	0030                	.insn	2, 0x0030
    13f6:	0129013b          	.insn	4, 0x0129013b
    13fa:	0000062f          	.insn	4, 0x062f
    13fe:	8030                	.insn	2, 0x8030
    1400:	3c02                	.insn	2, 0x3c02
    1402:	2a01                	.insn	2, 0x2a01
    1404:	3401                	.insn	2, 0x3401
    1406:	0006                	.insn	2, 0x0006
    1408:	3000                	.insn	2, 0x3000
    140a:	2080                	.insn	2, 0x2080
    140c:	013d                	.insn	2, 0x013d
    140e:	0634012b          	.insn	4, 0x0634012b
    1412:	0000                	.insn	2, 0x0000
    1414:	0134272b          	.insn	4, 0x0134272b
    1418:	012d                	.insn	2, 0x012d
    141a:	052e                	.insn	2, 0x052e
    141c:	0000                	.insn	2, 0x0000
    141e:	0135282b          	.insn	4, 0x0135282b
    1422:	012e                	.insn	2, 0x012e
    1424:	000000fb          	.insn	4, 0x00fb
    1428:	0522                	.insn	2, 0x0522
    142a:	013e2b2b          	.insn	4, 0x013e2b2b
    142e:	0131                	.insn	2, 0x0131
    1430:	052e                	.insn	2, 0x052e
    1432:	0000                	.insn	2, 0x0000
    1434:	f12c                	.insn	2, 0xf12c
    1436:	0004                	.insn	2, 0x0004
    1438:	0600                	.insn	2, 0x0600
    143a:	3201                	.insn	2, 0x3201
    143c:	0d01                	.insn	2, 0x0d01
    143e:	2925                	.insn	2, 0x2925
    1440:	04f9                	.insn	2, 0x04f9
    1442:	0000                	.insn	2, 0x0000
    1444:	2e1a                	.insn	2, 0x2e1a
    1446:	0509                	.insn	2, 0x0509
    1448:	0000                	.insn	2, 0x0000
    144a:	05110727          	.insn	4, 0x05110727
    144e:	0000                	.insn	2, 0x0000
    1450:	2d1a                	.insn	2, 0x2d1a
    1452:	0512                	.insn	2, 0x0512
    1454:	0000                	.insn	2, 0x0000
    1456:	2f1a                	.insn	2, 0x2f1a
    1458:	051a                	.insn	2, 0x051a
    145a:	0000                	.insn	2, 0x0000
    145c:	0000                	.insn	2, 0x0000
    145e:	2200                	.insn	2, 0x2200
    1460:	2b08                	.insn	2, 0x2b08
    1462:	3f2c                	.insn	2, 0x3f2c
    1464:	3901                	.insn	2, 0x3901
    1466:	2e01                	.insn	2, 0x2e01
    1468:	0005                	.insn	2, 0x0005
    146a:	2c00                	.insn	2, 0x2c00
    146c:	04f1                	.insn	2, 0x04f1
    146e:	0000                	.insn	2, 0x0000
    1470:	0109                	.insn	2, 0x0109
    1472:	013a                	.insn	2, 0x013a
    1474:	250d                	.insn	2, 0x250d
    1476:	f92a                	.insn	2, 0xf92a
    1478:	0004                	.insn	2, 0x0004
    147a:	1a00                	.insn	2, 0x1a00
    147c:	0931                	.insn	2, 0x0931
    147e:	0005                	.insn	2, 0x0005
    1480:	2700                	.insn	2, 0x2700
    1482:	110a                	.insn	2, 0x110a
    1484:	0005                	.insn	2, 0x0005
    1486:	1a00                	.insn	2, 0x1a00
    1488:	1230                	.insn	2, 0x1230
    148a:	0005                	.insn	2, 0x0005
    148c:	1a00                	.insn	2, 0x1a00
    148e:	1a32                	.insn	2, 0x1a32
    1490:	0005                	.insn	2, 0x0005
    1492:	0000                	.insn	2, 0x0000
    1494:	0000                	.insn	2, 0x0000
    1496:	7e1d                	.insn	2, 0x7e1d
    1498:	0002                	.insn	2, 0x0002
    149a:	3800                	.insn	2, 0x3800
    149c:	7e1e                	.insn	2, 0x7e1e
    149e:	0002                	.insn	2, 0x0002
    14a0:	3900                	.insn	2, 0x3900
    14a2:	c91d                	.insn	2, 0xc91d
    14a4:	3a000003          	lb	zero,928(zero) # 3a0 <_start-0xffc60>
    14a8:	3100                	.insn	2, 0x3100
    14aa:	00004103          	lbu	sp,0(zero) # 0 <_start-0x100000>
    14ae:	0400                	.insn	2, 0x0400
    14b0:	0045                	.insn	2, 0x0045
    14b2:	0000                	.insn	2, 0x0000
    14b4:	000a                	.insn	2, 0x000a
    14b6:	0b32                	.insn	2, 0x0b32
    14b8:	0006                	.insn	2, 0x0006
    14ba:	2f00                	.insn	2, 0x2f00
    14bc:	00004103          	lbu	sp,0(zero) # 0 <_start-0x100000>
    14c0:	0400                	.insn	2, 0x0400
    14c2:	0045                	.insn	2, 0x0045
    14c4:	0000                	.insn	2, 0x0000
    14c6:	240b000b          	.insn	4, 0x240b000b
    14ca:	0005                	.insn	2, 0x0005
    14cc:	0a00                	.insn	2, 0x0a00
    14ce:	052e                	.insn	2, 0x052e
    14d0:	0000                	.insn	2, 0x0000
    14d2:	fb0a                	.insn	2, 0xfb0a
    14d4:	0000                	.insn	2, 0x0000
    14d6:	0000                	.insn	2, 0x0000
    14d8:	0569                	.insn	2, 0x0569
    14da:	0000                	.insn	2, 0x0000
    14dc:	0005                	.insn	2, 0x0005
    14de:	0401                	.insn	2, 0x0401
    14e0:	04de                	.insn	2, 0x04de
    14e2:	0000                	.insn	2, 0x0000
    14e4:	0001                	.insn	2, 0x0001
    14e6:	001d                	.insn	2, 0x001d
    14e8:	ec01                	.insn	2, 0xec01
    14ea:	0001                	.insn	2, 0x0001
    14ec:	a500                	.insn	2, 0xa500
    14ee:	0010                	.insn	2, 0x0010
    14f0:	0200                	.insn	2, 0x0200
    14f2:	0008c40b          	.insn	4, 0x0008c40b
    14f6:	4400                	.insn	2, 0x4400
    14f8:	53000003          	lb	zero,1328(zero) # 530 <_start-0xffad0>
    14fc:	0002                	.insn	2, 0x0002
    14fe:	b700                	.insn	2, 0xb700
    1500:	000e                	.insn	2, 0x000e
    1502:	0200                	.insn	2, 0x0200
    1504:	0718                	.insn	2, 0x0718
    1506:	0204                	.insn	2, 0x0204
    1508:	03020717          	auipc	a4,0x3020
    150c:	003d                	.insn	2, 0x003d
    150e:	0000                	.insn	2, 0x0000
    1510:	9a01                	.insn	2, 0x9a01
    1512:	a102                	.insn	2, 0xa102
    1514:	0400                	.insn	2, 0x0400
    1516:	0049                	.insn	2, 0x0049
    1518:	0000                	.insn	2, 0x0000
    151a:	4d05                	.insn	2, 0x4d05
    151c:	0000                	.insn	2, 0x0000
    151e:	1500                	.insn	2, 0x1500
    1520:	0200                	.insn	2, 0x0200
    1522:	06010803          	lb	a6,96(sp) # ebe613f0 <_stack_top+0xebd55430>
    1526:	0804                	.insn	2, 0x0804
    1528:	005b0307          	.insn	4, 0x005b0307
    152c:	0000                	.insn	2, 0x0000
    152e:	a101                	.insn	2, 0xa101
    1530:	a102                	.insn	2, 0xa102
    1532:	0401                	.insn	2, 0x0401
    1534:	0049                	.insn	2, 0x0049
    1536:	0000                	.insn	2, 0x0000
    1538:	4d05                	.insn	2, 0x4d05
    153a:	0000                	.insn	2, 0x0000
    153c:	1300                	.insn	2, 0x1300
    153e:	0300                	.insn	2, 0x0300
    1540:	0071                	.insn	2, 0x0071
    1542:	0000                	.insn	2, 0x0000
    1544:	a901                	.insn	2, 0xa901
    1546:	a102                	.insn	2, 0xa102
    1548:	0402                	.insn	2, 0x0402
    154a:	0049                	.insn	2, 0x0049
    154c:	0000                	.insn	2, 0x0000
    154e:	4d05                	.insn	2, 0x4d05
    1550:	0000                	.insn	2, 0x0000
    1552:	2000                	.insn	2, 0x2000
    1554:	0300                	.insn	2, 0x0300
    1556:	00000087          	.insn	4, 0x0087
    155a:	aa01                	.insn	2, 0xaa01
    155c:	a102                	.insn	2, 0xa102
    155e:	00490403          	lb	s0,4(s2) # 4382 <_start-0xfbc7e>
    1562:	0000                	.insn	2, 0x0000
    1564:	4d05                	.insn	2, 0x4d05
    1566:	0000                	.insn	2, 0x0000
    1568:	1200                	.insn	2, 0x1200
    156a:	0300                	.insn	2, 0x0300
    156c:	009d                	.insn	2, 0x009d
    156e:	0000                	.insn	2, 0x0000
    1570:	c301                	.insn	2, 0xc301
    1572:	a102                	.insn	2, 0xa102
    1574:	0404                	.insn	2, 0x0404
    1576:	0049                	.insn	2, 0x0049
    1578:	0000                	.insn	2, 0x0000
    157a:	4d05                	.insn	2, 0x4d05
    157c:	0000                	.insn	2, 0x0000
    157e:	1400                	.insn	2, 0x1400
    1580:	0300                	.insn	2, 0x0300
    1582:	0000005b          	.insn	4, 0x005b
    1586:	d001                	.insn	2, 0xd001
    1588:	a102                	.insn	2, 0xa102
    158a:	0305                	.insn	2, 0x0305
    158c:	00bd                	.insn	2, 0x00bd
    158e:	0000                	.insn	2, 0x0000
    1590:	d401                	.insn	2, 0xd401
    1592:	a102                	.insn	2, 0xa102
    1594:	0406                	.insn	2, 0x0406
    1596:	0049                	.insn	2, 0x0049
    1598:	0000                	.insn	2, 0x0000
    159a:	4d05                	.insn	2, 0x4d05
    159c:	0000                	.insn	2, 0x0000
    159e:	2100                	.insn	2, 0x2100
    15a0:	0300                	.insn	2, 0x0300
    15a2:	009d                	.insn	2, 0x009d
    15a4:	0000                	.insn	2, 0x0000
    15a6:	da01                	.insn	2, 0xda01
    15a8:	a102                	.insn	2, 0xa102
    15aa:	00dd0307          	.insn	4, 0x00dd0307
    15ae:	0000                	.insn	2, 0x0000
    15b0:	ef01                	.insn	2, 0xef01
    15b2:	a102                	.insn	2, 0xa102
    15b4:	0408                	.insn	2, 0x0408
    15b6:	0049                	.insn	2, 0x0049
    15b8:	0000                	.insn	2, 0x0000
    15ba:	4d05                	.insn	2, 0x4d05
    15bc:	0000                	.insn	2, 0x0000
    15be:	0d00                	.insn	2, 0x0d00
    15c0:	0300                	.insn	2, 0x0300
    15c2:	000000f3          	.insn	4, 0x00f3
    15c6:	f601                	.insn	2, 0xf601
    15c8:	a102                	.insn	2, 0xa102
    15ca:	0409                	.insn	2, 0x0409
    15cc:	0049                	.insn	2, 0x0049
    15ce:	0000                	.insn	2, 0x0000
    15d0:	4d05                	.insn	2, 0x4d05
    15d2:	0000                	.insn	2, 0x0000
    15d4:	0b00                	.insn	2, 0x0b00
    15d6:	0300                	.insn	2, 0x0300
    15d8:	00dd                	.insn	2, 0x00dd
    15da:	0000                	.insn	2, 0x0000
    15dc:	fd01                	.insn	2, 0xfd01
    15de:	a102                	.insn	2, 0xa102
    15e0:	070a                	.insn	2, 0x070a
    15e2:	010e                	.insn	2, 0x010e
    15e4:	0000                	.insn	2, 0x0000
    15e6:	1308                	.insn	2, 0x1308
    15e8:	0001                	.insn	2, 0x0001
    15ea:	0900                	.insn	2, 0x0900
    15ec:	0000011b          	.insn	4, 0x011b
    15f0:	0206                	.insn	2, 0x0206
    15f2:	0209                	.insn	2, 0x0209
    15f4:	0705                	.insn	2, 0x0705
    15f6:	0204                	.insn	2, 0x0204
    15f8:	09010807          	.insn	4, 0x09010807
    15fc:	0000012b          	.insn	4, 0x012b
    1600:	0209                	.insn	2, 0x0209
    1602:	0208                	.insn	2, 0x0208
    1604:	0708                	.insn	2, 0x0708
    1606:	0a02                	.insn	2, 0x0a02
    1608:	0000080b          	.insn	4, 0x080b
    160c:	0100                	.insn	2, 0x0100
    160e:	ea52                	.insn	2, 0xea52
    1610:	0001                	.insn	2, 0x0001
    1612:	0b00                	.insn	2, 0x0b00
    1614:	5a01                	.insn	2, 0x5a01
    1616:	01f2                	.insn	2, 0x01f2
    1618:	0000                	.insn	2, 0x0000
    161a:	fa5b010b          	.insn	4, 0xfa5b010b
    161e:	0001                	.insn	2, 0x0001
    1620:	0c00                	.insn	2, 0x0c00
    1622:	0150                	.insn	2, 0x0150
    1624:	0000                	.insn	2, 0x0000
    1626:	0c0d000b          	.insn	4, 0x0c0d000b
    162a:	01c0                	.insn	2, 0x01c0
    162c:	0000                	.insn	2, 0x0000
    162e:	5201                	.insn	2, 0x5201
    1630:	0119                	.insn	2, 0x0119
    1632:	0312                	.insn	2, 0x0312
    1634:	0002                	.insn	2, 0x0002
    1636:	0e00                	.insn	2, 0x0e00
    1638:	1e00                	.insn	2, 0x1e00
    163a:	1201                	.insn	2, 0x1201
    163c:	00000113          	li	sp,0
    1640:	0f5b010f          	.insn	4, 0x0f5b010f
    1644:	1201                	.insn	2, 0x1201
    1646:	052a                	.insn	2, 0x052a
    1648:	0000                	.insn	2, 0x0000
    164a:	0210                	.insn	2, 0x0210
    164c:	011f 1314 0001      	.insn	6, 0x00011314011f
    1652:	1100                	.insn	2, 0x1100
    1654:	01dd                	.insn	2, 0x01dd
    1656:	0000                	.insn	2, 0x0000
    1658:	0c0d                	.insn	2, 0x0c0d
    165a:	0000                	.insn	2, 0x0000
    165c:	0100                	.insn	2, 0x0100
    165e:	0519                	.insn	2, 0x0519
    1660:	0112                	.insn	2, 0x0112
    1662:	01e1                	.insn	2, 0x01e1
    1664:	0000                	.insn	2, 0x0000
    1666:	1100                	.insn	2, 0x1100
    1668:	01dd                	.insn	2, 0x01dd
    166a:	0000                	.insn	2, 0x0000
    166c:	0c0e                	.insn	2, 0x0c0e
    166e:	0000                	.insn	2, 0x0000
    1670:	0100                	.insn	2, 0x0100
    1672:	03120527          	.insn	4, 0x03120527
    1676:	01e1                	.insn	2, 0x01e1
    1678:	0000                	.insn	2, 0x0000
    167a:	1100                	.insn	2, 0x1100
    167c:	01dd                	.insn	2, 0x01dd
    167e:	0000                	.insn	2, 0x0000
    1680:	00000c0f          	.insn	4, 0x0c0f
    1684:	0100                	.insn	2, 0x0100
    1686:	052e                	.insn	2, 0x052e
    1688:	0412                	.insn	2, 0x0412
    168a:	01e1                	.insn	2, 0x01e1
    168c:	0000                	.insn	2, 0x0000
    168e:	1100                	.insn	2, 0x1100
    1690:	01dd                	.insn	2, 0x01dd
    1692:	0000                	.insn	2, 0x0000
    1694:	d810                	.insn	2, 0xd810
    1696:	0000                	.insn	2, 0x0000
    1698:	0100                	.insn	2, 0x0100
    169a:	0536                	.insn	2, 0x0536
    169c:	0512                	.insn	2, 0x0512
    169e:	01e1                	.insn	2, 0x01e1
    16a0:	0000                	.insn	2, 0x0000
    16a2:	1300                	.insn	2, 0x1300
    16a4:	3011                	.insn	2, 0x3011
    16a6:	0000                	.insn	2, 0x0000
    16a8:	1400                	.insn	2, 0x1400
    16aa:	5d01                	.insn	2, 0x5d01
    16ac:	0114                	.insn	2, 0x0114
    16ae:	0339                	.insn	2, 0x0339
    16b0:	0002                	.insn	2, 0x0002
    16b2:	0000                	.insn	2, 0x0000
    16b4:	1500                	.insn	2, 0x1500
    16b6:	010a                	.insn	2, 0x010a
    16b8:	160c                	.insn	2, 0x160c
    16ba:	1b0c010b          	.insn	4, 0x1b0c010b
    16be:	0001                	.insn	2, 0x0001
    16c0:	0000                	.insn	2, 0x0000
    16c2:	8d010c17          	auipc	s8,0x8d010
    16c6:	00000203          	lb	tp,0(zero) # 0 <_start-0x100000>
    16ca:	0e16                	.insn	2, 0x0e16
    16cc:	8d01                	.insn	2, 0x8d01
    16ce:	00000113          	li	sp,0
    16d2:	0f16                	.insn	2, 0x0f16
    16d4:	8d01                	.insn	2, 0x8d01
    16d6:	00000207          	.insn	4, 0x0207
    16da:	0200                	.insn	2, 0x0200
    16dc:	050d                	.insn	2, 0x050d
    16de:	0704                	.insn	2, 0x0704
    16e0:	020c                	.insn	2, 0x020c
    16e2:	0000                	.insn	2, 0x0000
    16e4:	1f09                	.insn	2, 0x1f09
    16e6:	0001                	.insn	2, 0x0001
    16e8:	1000                	.insn	2, 0x1000
    16ea:	0702                	.insn	2, 0x0702
    16ec:	1218                	.insn	2, 0x1218
    16ee:	0250                	.insn	2, 0x0250
    16f0:	0000                	.insn	2, 0x0000
    16f2:	5201                	.insn	2, 0x5201
    16f4:	011a                	.insn	2, 0x011a
    16f6:	00020393          	mv	t2,tp
    16fa:	0e00                	.insn	2, 0x0e00
    16fc:	0e06                	.insn	2, 0x0e06
    16fe:	9301                	.insn	2, 0x9301
    1700:	00000113          	li	sp,0
    1704:	070e                	.insn	2, 0x070e
    1706:	0793010f          	.insn	4, 0x0793010f
    170a:	0002                	.insn	2, 0x0002
    170c:	1900                	.insn	2, 0x1900
    170e:	95012103          	lw	sp,-1712(sp)
    1712:	053c                	.insn	2, 0x053c
    1714:	0000                	.insn	2, 0x0000
    1716:	02081313          	slli	t1,a6,0x20
    171a:	0000                	.insn	2, 0x0000
    171c:	0810                	.insn	2, 0x0810
    171e:	0122                	.insn	2, 0x0122
    1720:	00020397          	auipc	t2,0x20
    1724:	1300                	.insn	2, 0x1300
    1726:	00020813          	mv	a6,tp
    172a:	1400                	.insn	2, 0x1400
    172c:	9102                	.insn	2, 0x9102
    172e:	2008                	.insn	2, 0x2008
    1730:	9e01                	.insn	2, 0x9e01
    1732:	0000052f          	.insn	4, 0x052f
    1736:	231a                	.insn	2, 0x231a
    1738:	a501                	.insn	2, 0xa501
    173a:	0541                	.insn	2, 0x0541
    173c:	0000                	.insn	2, 0x0000
    173e:	0001ea1b          	.insn	4, 0x0001ea1b
    1742:	0000                	.insn	2, 0x0000
    1744:	a001                	.insn	2, 0xa001
    1746:	120d                	.insn	2, 0x120d
    1748:	f209                	.insn	2, 0xf209
    174a:	0001                	.insn	2, 0x0001
    174c:	1200                	.insn	2, 0x1200
    174e:	fa0a                	.insn	2, 0xfa0a
    1750:	0001                	.insn	2, 0x0001
    1752:	0000                	.insn	2, 0x0000
    1754:	011c                	.insn	2, 0x011c
    1756:	0b10                	.insn	2, 0x0b10
    1758:	0114                	.insn	2, 0x0114
    175a:	000203a7          	.insn	4, 0x000203a7
    175e:	0000                	.insn	2, 0x0000
    1760:	0000                	.insn	2, 0x0000
    1762:	f71d                	.insn	2, 0xf71d
    1764:	0002                	.insn	2, 0x0002
    1766:	1400                	.insn	2, 0x1400
    1768:	811d                	.insn	2, 0x811d
    176a:	15000003          	lb	zero,336(zero) # 150 <_start-0xffeb0>
    176e:	501d                	.insn	2, 0x501d
    1770:	0001                	.insn	2, 0x0001
    1772:	1600                	.insn	2, 0x1600
    1774:	811d                	.insn	2, 0x811d
    1776:	17000003          	lb	zero,368(zero) # 170 <_start-0xffe90>
    177a:	811d                	.insn	2, 0x811d
    177c:	18000003          	lb	zero,384(zero) # 180 <_start-0xffe80>
    1780:	811d                	.insn	2, 0x811d
    1782:	19000003          	lb	zero,400(zero) # 190 <_start-0xffe70>
    1786:	f71d                	.insn	2, 0xf71d
    1788:	0002                	.insn	2, 0x0002
    178a:	1a00                	.insn	2, 0x1a00
    178c:	811d                	.insn	2, 0x811d
    178e:	1b000003          	lb	zero,432(zero) # 1b0 <_start-0xffe50>
    1792:	501d                	.insn	2, 0x501d
    1794:	0001                	.insn	2, 0x0001
    1796:	1c00                	.insn	2, 0x1c00
    1798:	811d                	.insn	2, 0x811d
    179a:	1d000003          	lb	zero,464(zero) # 1d0 <_start-0xffe30>
    179e:	811d                	.insn	2, 0x811d
    17a0:	1e000003          	lb	zero,480(zero) # 1e0 <_start-0xffe20>
    17a4:	811d                	.insn	2, 0x811d
    17a6:	1f000003          	lb	zero,496(zero) # 1f0 <_start-0xffe10>
    17aa:	f71d                	.insn	2, 0xf71d
    17ac:	0002                	.insn	2, 0x0002
    17ae:	2000                	.insn	2, 0x2000
    17b0:	811d                	.insn	2, 0x811d
    17b2:	21000003          	lb	zero,528(zero) # 210 <_start-0xffdf0>
    17b6:	501d                	.insn	2, 0x501d
    17b8:	0001                	.insn	2, 0x0001
    17ba:	2200                	.insn	2, 0x2200
    17bc:	811d                	.insn	2, 0x811d
    17be:	23000003          	lb	zero,560(zero) # 230 <_start-0xffdd0>
    17c2:	811d                	.insn	2, 0x811d
    17c4:	24000003          	lb	zero,576(zero) # 240 <_start-0xffdc0>
    17c8:	811d                	.insn	2, 0x811d
    17ca:	25000003          	lb	zero,592(zero) # 250 <_start-0xffdb0>
    17ce:	0d00                	.insn	2, 0x0d00
    17d0:	8c26                	.insn	2, 0x8c26
    17d2:	0001                	.insn	2, 0x0001
    17d4:	0100                	.insn	2, 0x0100
    17d6:	1b52                	.insn	2, 0x1b52
    17d8:	4401                	.insn	2, 0x4401
    17da:	00000203          	lb	tp,0(zero) # 0 <_start-0x100000>
    17de:	0c0e                	.insn	2, 0x0c0e
    17e0:	011e                	.insn	2, 0x011e
    17e2:	1344                	.insn	2, 0x1344
    17e4:	0001                	.insn	2, 0x0001
    17e6:	0e00                	.insn	2, 0x0e00
    17e8:	0f0d                	.insn	2, 0x0f0d
    17ea:	4401                	.insn	2, 0x4401
    17ec:	0549                	.insn	2, 0x0549
    17ee:	0000                	.insn	2, 0x0000
    17f0:	0f10                	.insn	2, 0x0f10
    17f2:	011f 1346 0001      	.insn	6, 0x00011346011f
    17f8:	1100                	.insn	2, 0x1100
    17fa:	01dd                	.insn	2, 0x01dd
    17fc:	0000                	.insn	2, 0x0000
    17fe:	00000c27          	.insn	4, 0x0c27
    1802:	0100                	.insn	2, 0x0100
    1804:	0e12054b          	.insn	4, 0x0e12054b
    1808:	01e1                	.insn	2, 0x01e1
    180a:	0000                	.insn	2, 0x0000
    180c:	1300                	.insn	2, 0x1300
    180e:	1828                	.insn	2, 0x1828
    1810:	0000                	.insn	2, 0x0000
    1812:	1a00                	.insn	2, 0x1a00
    1814:	0114                	.insn	2, 0x0114
    1816:	034e                	.insn	2, 0x034e
    1818:	0002                	.insn	2, 0x0002
    181a:	0000                	.insn	2, 0x0000
    181c:	dd11                	.insn	2, 0xdd11
    181e:	0001                	.insn	2, 0x0001
    1820:	2900                	.insn	2, 0x2900
    1822:	000c                	.insn	2, 0x000c
    1824:	0000                	.insn	2, 0x0000
    1826:	5f01                	.insn	2, 0x5f01
    1828:	1205                	.insn	2, 0x1205
    182a:	e110                	.insn	2, 0xe110
    182c:	0001                	.insn	2, 0x0001
    182e:	0000                	.insn	2, 0x0000
    1830:	dd11                	.insn	2, 0xdd11
    1832:	0001                	.insn	2, 0x0001
    1834:	2a00                	.insn	2, 0x2a00
    1836:	000c                	.insn	2, 0x000c
    1838:	0000                	.insn	2, 0x0000
    183a:	6601                	.insn	2, 0x6601
    183c:	1205                	.insn	2, 0x1205
    183e:	e111                	.insn	2, 0xe111
    1840:	0001                	.insn	2, 0x0001
    1842:	0000                	.insn	2, 0x0000
    1844:	dd11                	.insn	2, 0xdd11
    1846:	0001                	.insn	2, 0x0001
    1848:	2b00                	.insn	2, 0x2b00
    184a:	00c8                	.insn	2, 0x00c8
    184c:	0000                	.insn	2, 0x0000
    184e:	6e01                	.insn	2, 0x6e01
    1850:	1205                	.insn	2, 0x1205
    1852:	e112                	.insn	2, 0xe112
    1854:	0001                	.insn	2, 0x0001
    1856:	0000                	.insn	2, 0x0000
    1858:	1e00                	.insn	2, 0x1e00
    185a:	0211                	.insn	2, 0x0211
    185c:	1f29                	.insn	2, 0x1f29
    185e:	038c                	.insn	2, 0x038c
    1860:	0000                	.insn	2, 0x0000
    1862:	0020                	.insn	2, 0x0020
    1864:	00039107          	.insn	4, 0x00039107
    1868:	2100                	.insn	2, 0x2100
    186a:	0049                	.insn	2, 0x0049
    186c:	0000                	.insn	2, 0x0000
    186e:	1222                	.insn	2, 0x1222
    1870:	7f01                	.insn	2, 0x7f01
    1872:	00000123          	sb	zero,2(zero) # 2 <_start-0xffffe>
    1876:	0f16                	.insn	2, 0x0f16
    1878:	7f01                	.insn	2, 0x7f01
    187a:	000003c3          	.insn	4, 0x03c3
    187e:	131a                	.insn	2, 0x131a
    1880:	8101                	.insn	2, 0x8101
    1882:	00000123          	sb	zero,2(zero) # 2 <_start-0xffffe>
    1886:	01141a23          	sh	a7,20(s0)
    188a:	00020383          	lb	t2,0(tp) # 0 <_start-0x100000>
    188e:	2300                	.insn	2, 0x2300
    1890:	151a                	.insn	2, 0x151a
    1892:	8501                	.insn	2, 0x8501
    1894:	00000203          	lb	tp,0(zero) # 0 <_start-0x100000>
    1898:	0000                	.insn	2, 0x0000
    189a:	0700                	.insn	2, 0x0700
    189c:	03c8                	.insn	2, 0x03c8
    189e:	0000                	.insn	2, 0x0000
    18a0:	1f21                	.insn	2, 0x1f21
    18a2:	0001                	.insn	2, 0x0001
    18a4:	2400                	.insn	2, 0x2400
    18a6:	382c                	.insn	2, 0x382c
    18a8:	0002                	.insn	2, 0x0002
    18aa:	0100                	.insn	2, 0x0100
    18ac:	1c52                	.insn	2, 0x1c52
    18ae:	b901                	.insn	2, 0xb901
    18b0:	130e                	.insn	2, 0x130e
    18b2:	011e                	.insn	2, 0x011e
    18b4:	13b9                	.insn	2, 0x13b9
    18b6:	0001                	.insn	2, 0x0001
    18b8:	1400                	.insn	2, 0x1400
    18ba:	9102                	.insn	2, 0x9102
    18bc:	0f0c                	.insn	2, 0x0f0c
    18be:	bb01                	.insn	2, 0xbb01
    18c0:	00000553          	.insn	4, 0x0553
    18c4:	1410                	.insn	2, 0x1410
    18c6:	0121                	.insn	2, 0x0121
    18c8:	03bd                	.insn	2, 0x03bd
    18ca:	0002                	.insn	2, 0x0002
    18cc:	1000                	.insn	2, 0x1000
    18ce:	2515                	.insn	2, 0x2515
    18d0:	be01                	.insn	2, 0xbe01
    18d2:	00000203          	lb	tp,0(zero) # 0 <_start-0x100000>
    18d6:	281a                	.insn	2, 0x281a
    18d8:	de01                	.insn	2, 0xde01
    18da:	0560                	.insn	2, 0x0560
    18dc:	0000                	.insn	2, 0x0000
    18de:	021c                	.insn	2, 0x021c
    18e0:	1610                	.insn	2, 0x1610
    18e2:	0122                	.insn	2, 0x0122
    18e4:	03c0                	.insn	2, 0x03c0
    18e6:	0002                	.insn	2, 0x0002
    18e8:	1c00                	.insn	2, 0x1c00
    18ea:	26171003          	lh	zero,609(a4) # 3021769 <_stack_top+0x2f157a9>
    18ee:	c801                	.insn	2, 0xc801
    18f0:	00000113          	li	sp,0
    18f4:	1a10                	.insn	2, 0x1a10
    18f6:	23c90127          	.insn	4, 0x23c90127
    18fa:	0001                	.insn	2, 0x0001
    18fc:	1000                	.insn	2, 0x1000
    18fe:	cd01131b          	.insn	4, 0xcd01131b
    1902:	00000123          	sb	zero,2(zero) # 2 <_start-0xffffe>
    1906:	9611                	.insn	2, 0x9611
    1908:	2d000003          	lb	zero,720(zero) # 2d0 <_start-0xffd30>
    190c:	00b4                	.insn	2, 0x00b4
    190e:	0000                	.insn	2, 0x0000
    1910:	cd01                	.insn	2, 0xcd01
    1912:	0b18                	.insn	2, 0x0b18
    1914:	9f0c9103          	lh	sp,-1552(s9)
    1918:	039e                	.insn	2, 0x039e
    191a:	0000                	.insn	2, 0x0000
    191c:	1825                	.insn	2, 0x1825
    191e:	03a6                	.insn	2, 0x03a6
    1920:	0000                	.insn	2, 0x0000
    1922:	2e26                	.insn	2, 0x2e26
    1924:	009c                	.insn	2, 0x009c
    1926:	0000                	.insn	2, 0x0000
    1928:	000003b7          	lui	t2,0x0
    192c:	1925                	.insn	2, 0x1925
    192e:	03b8                	.insn	2, 0x03b8
    1930:	0000                	.insn	2, 0x0000
    1932:	0000                	.insn	2, 0x0000
    1934:	0000                	.insn	2, 0x0000
    1936:	005c2f13          	slti	t5,s8,5
    193a:	0000                	.insn	2, 0x0000
    193c:	0114                	.insn	2, 0x0114
    193e:	1458                	.insn	2, 0x1458
    1940:	e001                	.insn	2, 0xe001
    1942:	00000203          	lb	tp,0(zero) # 0 <_start-0x100000>
    1946:	00543013          	sltiu	zero,s0,5
    194a:	0000                	.insn	2, 0x0000
    194c:	291a                	.insn	2, 0x291a
    194e:	e101                	.insn	2, 0xe101
    1950:	011f 0000 0000      	.insn	6, 0x011f
    1956:	811d                	.insn	2, 0x811d
    1958:	31000003          	lb	zero,784(zero) # 310 <_start-0xffcf0>
    195c:	501d                	.insn	2, 0x501d
    195e:	0001                	.insn	2, 0x0001
    1960:	3200                	.insn	2, 0x3200
    1962:	811d                	.insn	2, 0x811d
    1964:	33000003          	lb	zero,816(zero) # 330 <_start-0xffcd0>
    1968:	811d                	.insn	2, 0x811d
    196a:	34000003          	lb	zero,832(zero) # 340 <_start-0xffcc0>
    196e:	811d                	.insn	2, 0x811d
    1970:	35000003          	lb	zero,848(zero) # 350 <_start-0xffcb0>
    1974:	b51d                	.insn	2, 0xb51d
    1976:	0004                	.insn	2, 0x0004
    1978:	3600                	.insn	2, 0x3600
    197a:	b51d                	.insn	2, 0xb51d
    197c:	0004                	.insn	2, 0x0004
    197e:	3700                	.insn	2, 0x3700
    1980:	b51d                	.insn	2, 0xb51d
    1982:	0004                	.insn	2, 0x0004
    1984:	3800                	.insn	2, 0x3800
    1986:	b51d                	.insn	2, 0xb51d
    1988:	0004                	.insn	2, 0x0004
    198a:	3900                	.insn	2, 0x3900
    198c:	1e00                	.insn	2, 0x1e00
    198e:	0316                	.insn	2, 0x0316
    1990:	1f4c                	.insn	2, 0x1f4c
    1992:	0049                	.insn	2, 0x0049
    1994:	0000                	.insn	2, 0x0000
    1996:	1800                	.insn	2, 0x1800
    1998:	e83a                	.insn	2, 0xe83a
    199a:	0000                	.insn	2, 0x0000
    199c:	0100                	.insn	2, 0x0100
    199e:	1d52                	.insn	2, 0x1d52
    19a0:	eb01                	.insn	2, 0xeb01
    19a2:	00000203          	lb	tp,0(zero) # 0 <_start-0x100000>
    19a6:	1c0e                	.insn	2, 0x1c0e
    19a8:	011e                	.insn	2, 0x011e
    19aa:	13ec                	.insn	2, 0x13ec
    19ac:	0001                	.insn	2, 0x0001
    19ae:	0e00                	.insn	2, 0x0e00
    19b0:	0f1d                	.insn	2, 0x0f1d
    19b2:	ed01                	.insn	2, 0xed01
    19b4:	0549                	.insn	2, 0x0549
    19b6:	0000                	.insn	2, 0x0000
    19b8:	1e10                	.insn	2, 0x1e10
    19ba:	0121                	.insn	2, 0x0121
    19bc:	3cf1                	.insn	2, 0x3cf1
    19be:	0005                	.insn	2, 0x0005
    19c0:	1300                	.insn	2, 0x1300
    19c2:	0000903b          	.insn	4, 0x903b
    19c6:	1000                	.insn	2, 0x1000
    19c8:	221f f301 0203      	.insn	6, 0x0203f301221f
    19ce:	0000                	.insn	2, 0x0000
    19d0:	1d00                	.insn	2, 0x1d00
    19d2:	0381                	.insn	2, 0x0381
    19d4:	0000                	.insn	2, 0x0000
    19d6:	02f71d3b          	.insn	4, 0x02f71d3b
    19da:	0000                	.insn	2, 0x0000
    19dc:	1d3c                	.insn	2, 0x1d3c
    19de:	0381                	.insn	2, 0x0381
    19e0:	0000                	.insn	2, 0x0000
    19e2:	1d3d                	.insn	2, 0x1d3d
    19e4:	000002f7          	.insn	4, 0x02f7
    19e8:	1d3e                	.insn	2, 0x1d3e
    19ea:	0381                	.insn	2, 0x0381
    19ec:	0000                	.insn	2, 0x0000
    19ee:	02f71d3f 1d400000 	.insn	8, 0x1d40000002f71d3f
    19f6:	0381                	.insn	2, 0x0381
    19f8:	0000                	.insn	2, 0x0000
    19fa:	1d41                	.insn	2, 0x1d41
    19fc:	0381                	.insn	2, 0x0381
    19fe:	0000                	.insn	2, 0x0000
    1a00:	0042                	.insn	2, 0x0042
    1a02:	00011f07          	.insn	4, 0x00011f07
    1a06:	0400                	.insn	2, 0x0400
    1a08:	020c                	.insn	2, 0x020c
    1a0a:	0000                	.insn	2, 0x0000
    1a0c:	00004d27          	.insn	4, 0x4d27
    1a10:	0000                	.insn	2, 0x0000
    1a12:	0002                	.insn	2, 0x0002
    1a14:	0321                	.insn	2, 0x0321
    1a16:	0002                	.insn	2, 0x0002
    1a18:	0900                	.insn	2, 0x0900
    1a1a:	00000203          	lb	tp,0(zero) # 0 <_start-0x100000>
    1a1e:	0224                	.insn	2, 0x0224
    1a20:	0706                	.insn	2, 0x0706
    1a22:	054e                	.insn	2, 0x054e
    1a24:	0000                	.insn	2, 0x0000
    1a26:	0c21                	.insn	2, 0x0c21
    1a28:	0002                	.insn	2, 0x0002
    1a2a:	0400                	.insn	2, 0x0400
    1a2c:	011f 0000 4d27      	.insn	6, 0x4d270000011f
    1a32:	0000                	.insn	2, 0x0000
    1a34:	0000                	.insn	2, 0x0000
    1a36:	0002                	.insn	2, 0x0002
    1a38:	9104                	.insn	2, 0x9104
    1a3a:	05000003          	lb	zero,80(zero) # 50 <_start-0xfffb0>
    1a3e:	004d                	.insn	2, 0x004d
    1a40:	0000                	.insn	2, 0x0000
    1a42:	0011                	.insn	2, 0x0011
    1a44:	3600                	.insn	2, 0x3600
    1a46:	000d                	.insn	2, 0x000d
    1a48:	0500                	.insn	2, 0x0500
    1a4a:	0100                	.insn	2, 0x0100
    1a4c:	d804                	.insn	2, 0xd804
    1a4e:	0006                	.insn	2, 0x0006
    1a50:	0100                	.insn	2, 0x0100
    1a52:	1d00                	.insn	2, 0x1d00
    1a54:	0100                	.insn	2, 0x0100
    1a56:	029c                	.insn	2, 0x029c
    1a58:	0000                	.insn	2, 0x0000
    1a5a:	1572                	.insn	2, 0x1572
    1a5c:	0000                	.insn	2, 0x0000
    1a5e:	4d02                	.insn	2, 0x4d02
    1a60:	1260                	.insn	2, 0x1260
    1a62:	0000                	.insn	2, 0x0000
    1a64:	0458                	.insn	2, 0x0458
    1a66:	0000                	.insn	2, 0x0000
    1a68:	02aa                	.insn	2, 0x02aa
    1a6a:	0000                	.insn	2, 0x0000
    1a6c:	16dd                	.insn	2, 0x16dd
    1a6e:	0000                	.insn	2, 0x0000
    1a70:	2902                	.insn	2, 0x2902
    1a72:	28020207          	.insn	4, 0x28020207
    1a76:	3d030407          	.insn	4, 0x3d030407
    1a7a:	0000                	.insn	2, 0x0000
    1a7c:	0100                	.insn	2, 0x0100
    1a7e:	024c                	.insn	2, 0x024c
    1a80:	00a1                	.insn	2, 0x00a1
    1a82:	4904                	.insn	2, 0x4904
    1a84:	0000                	.insn	2, 0x0000
    1a86:	0500                	.insn	2, 0x0500
    1a88:	004d                	.insn	2, 0x004d
    1a8a:	0000                	.insn	2, 0x0000
    1a8c:	0010                	.insn	2, 0x0010
    1a8e:	0302                	.insn	2, 0x0302
    1a90:	0108                	.insn	2, 0x0108
    1a92:	0406                	.insn	2, 0x0406
    1a94:	0708                	.insn	2, 0x0708
    1a96:	00005b03          	lhu	s6,0(zero) # 0 <_start-0x100000>
    1a9a:	0100                	.insn	2, 0x0100
    1a9c:	0269                	.insn	2, 0x0269
    1a9e:	01a1                	.insn	2, 0x01a1
    1aa0:	4904                	.insn	2, 0x4904
    1aa2:	0000                	.insn	2, 0x0000
    1aa4:	0500                	.insn	2, 0x0500
    1aa6:	004d                	.insn	2, 0x004d
    1aa8:	0000                	.insn	2, 0x0000
    1aaa:	0014                	.insn	2, 0x0014
    1aac:	00007103          	.insn	4, 0x7103
    1ab0:	0100                	.insn	2, 0x0100
    1ab2:	026e                	.insn	2, 0x026e
    1ab4:	02a1                	.insn	2, 0x02a1
    1ab6:	4904                	.insn	2, 0x4904
    1ab8:	0000                	.insn	2, 0x0000
    1aba:	0500                	.insn	2, 0x0500
    1abc:	004d                	.insn	2, 0x004d
    1abe:	0000                	.insn	2, 0x0000
    1ac0:	0019                	.insn	2, 0x0019
    1ac2:	00008703          	lb	a4,0(ra)
    1ac6:	0100                	.insn	2, 0x0100
    1ac8:	0272                	.insn	2, 0x0272
    1aca:	03a1                	.insn	2, 0x03a1
    1acc:	4904                	.insn	2, 0x4904
    1ace:	0000                	.insn	2, 0x0000
    1ad0:	0500                	.insn	2, 0x0500
    1ad2:	004d                	.insn	2, 0x004d
    1ad4:	0000                	.insn	2, 0x0000
    1ad6:	0012                	.insn	2, 0x0012
    1ad8:	00007103          	.insn	4, 0x7103
    1adc:	0100                	.insn	2, 0x0100
    1ade:	0275                	.insn	2, 0x0275
    1ae0:	04a1                	.insn	2, 0x04a1
    1ae2:	0000a703          	lw	a4,0(ra)
    1ae6:	0100                	.insn	2, 0x0100
    1ae8:	0279                	.insn	2, 0x0279
    1aea:	05a1                	.insn	2, 0x05a1
    1aec:	4904                	.insn	2, 0x4904
    1aee:	0000                	.insn	2, 0x0000
    1af0:	0500                	.insn	2, 0x0500
    1af2:	004d                	.insn	2, 0x004d
    1af4:	0000                	.insn	2, 0x0000
    1af6:	0015                	.insn	2, 0x0015
    1af8:	0000a703          	lw	a4,0(ra)
    1afc:	0100                	.insn	2, 0x0100
    1afe:	027d                	.insn	2, 0x027d
    1b00:	06a1                	.insn	2, 0x06a1
    1b02:	00005b03          	lhu	s6,0(zero) # 0 <_start-0x100000>
    1b06:	0100                	.insn	2, 0x0100
    1b08:	0280                	.insn	2, 0x0280
    1b0a:	07a1                	.insn	2, 0x07a1
    1b0c:	00003d03          	.insn	4, 0x3d03
    1b10:	0100                	.insn	2, 0x0100
    1b12:	0286                	.insn	2, 0x0286
    1b14:	08a1                	.insn	2, 0x08a1
    1b16:	0000db03          	lhu	s6,0(ra)
    1b1a:	0100                	.insn	2, 0x0100
    1b1c:	0289                	.insn	2, 0x0289
    1b1e:	09a1                	.insn	2, 0x09a1
    1b20:	4904                	.insn	2, 0x4904
    1b22:	0000                	.insn	2, 0x0000
    1b24:	0500                	.insn	2, 0x0500
    1b26:	004d                	.insn	2, 0x004d
    1b28:	0000                	.insn	2, 0x0000
    1b2a:	0016                	.insn	2, 0x0016
    1b2c:	0000f103          	.insn	4, 0xf103
    1b30:	0100                	.insn	2, 0x0100
    1b32:	028d                	.insn	2, 0x028d
    1b34:	0aa1                	.insn	2, 0x0aa1
    1b36:	4904                	.insn	2, 0x4904
    1b38:	0000                	.insn	2, 0x0000
    1b3a:	0500                	.insn	2, 0x0500
    1b3c:	004d                	.insn	2, 0x004d
    1b3e:	0000                	.insn	2, 0x0000
    1b40:	0011                	.insn	2, 0x0011
    1b42:	00010703          	lb	a4,0(sp)
    1b46:	0100                	.insn	2, 0x0100
    1b48:	0290                	.insn	2, 0x0290
    1b4a:	0ba1                	.insn	2, 0x0ba1
    1b4c:	4904                	.insn	2, 0x4904
    1b4e:	0000                	.insn	2, 0x0000
    1b50:	0500                	.insn	2, 0x0500
    1b52:	004d                	.insn	2, 0x004d
    1b54:	0000                	.insn	2, 0x0000
    1b56:	0018                	.insn	2, 0x0018
    1b58:	00005b03          	lhu	s6,0(zero) # 0 <_start-0x100000>
    1b5c:	0100                	.insn	2, 0x0100
    1b5e:	0294                	.insn	2, 0x0294
    1b60:	0ca1                	.insn	2, 0x0ca1
    1b62:	00005b03          	lhu	s6,0(zero) # 0 <_start-0x100000>
    1b66:	0100                	.insn	2, 0x0100
    1b68:	0da10297          	auipc	t0,0xda10
    1b6c:	00008703          	lb	a4,0(ra)
    1b70:	0100                	.insn	2, 0x0100
    1b72:	0ea1029b          	.insn	4, 0x0ea1029b
    1b76:	00003d03          	.insn	4, 0x3d03
    1b7a:	0100                	.insn	2, 0x0100
    1b7c:	029e                	.insn	2, 0x029e
    1b7e:	0fa1                	.insn	2, 0x0fa1
    1b80:	00003d03          	.insn	4, 0x3d03
    1b84:	0100                	.insn	2, 0x0100
    1b86:	02a1                	.insn	2, 0x02a1
    1b88:	10a1                	.insn	2, 0x10a1
    1b8a:	00003d03          	.insn	4, 0x3d03
    1b8e:	0100                	.insn	2, 0x0100
    1b90:	02a4                	.insn	2, 0x02a4
    1b92:	11a1                	.insn	2, 0x11a1
    1b94:	00003d03          	.insn	4, 0x3d03
    1b98:	0100                	.insn	2, 0x0100
    1b9a:	12a102a7          	.insn	4, 0x12a102a7
    1b9e:	00003d03          	.insn	4, 0x3d03
    1ba2:	0100                	.insn	2, 0x0100
    1ba4:	02aa                	.insn	2, 0x02aa
    1ba6:	13a1                	.insn	2, 0x13a1
    1ba8:	00003d03          	.insn	4, 0x3d03
    1bac:	0100                	.insn	2, 0x0100
    1bae:	02ad                	.insn	2, 0x02ad
    1bb0:	14a1                	.insn	2, 0x14a1
    1bb2:	0000f103          	.insn	4, 0xf103
    1bb6:	0100                	.insn	2, 0x0100
    1bb8:	02b0                	.insn	2, 0x02b0
    1bba:	15a1                	.insn	2, 0x15a1
    1bbc:	00003d03          	.insn	4, 0x3d03
    1bc0:	0100                	.insn	2, 0x0100
    1bc2:	16a102b3          	.insn	4, 0x16a102b3
    1bc6:	00003d03          	.insn	4, 0x3d03
    1bca:	0100                	.insn	2, 0x0100
    1bcc:	02b8                	.insn	2, 0x02b8
    1bce:	17a1                	.insn	2, 0x17a1
    1bd0:	0000a703          	lw	a4,0(ra)
    1bd4:	0100                	.insn	2, 0x0100
    1bd6:	02bd                	.insn	2, 0x02bd
    1bd8:	18a1                	.insn	2, 0x18a1
    1bda:	0000db03          	lhu	s6,0(ra)
    1bde:	0100                	.insn	2, 0x0100
    1be0:	02c2                	.insn	2, 0x02c2
    1be2:	19a1                	.insn	2, 0x19a1
    1be4:	0000a703          	lw	a4,0(ra)
    1be8:	0100                	.insn	2, 0x0100
    1bea:	1aa102c7          	.insn	4, 0x1aa102c7
    1bee:	00007103          	.insn	4, 0x7103
    1bf2:	0100                	.insn	2, 0x0100
    1bf4:	02cc                	.insn	2, 0x02cc
    1bf6:	1ba1                	.insn	2, 0x1ba1
    1bf8:	0001bd03          	.insn	4, 0x0001bd03
    1bfc:	0100                	.insn	2, 0x0100
    1bfe:	02d0                	.insn	2, 0x02d0
    1c00:	1ca1                	.insn	2, 0x1ca1
    1c02:	4904                	.insn	2, 0x4904
    1c04:	0000                	.insn	2, 0x0000
    1c06:	0500                	.insn	2, 0x0500
    1c08:	004d                	.insn	2, 0x004d
    1c0a:	0000                	.insn	2, 0x0000
    1c0c:	87030013          	addi	zero,t1,-1936
    1c10:	0000                	.insn	2, 0x0000
    1c12:	0100                	.insn	2, 0x0100
    1c14:	1da102d3          	.insn	4, 0x1da102d3
    1c18:	0001bd03          	.insn	4, 0x0001bd03
    1c1c:	0100                	.insn	2, 0x0100
    1c1e:	02d5                	.insn	2, 0x02d5
    1c20:	1ea1                	.insn	2, 0x1ea1
    1c22:	0000f103          	.insn	4, 0xf103
    1c26:	0100                	.insn	2, 0x0100
    1c28:	1fa102d7          	.insn	4, 0x1fa102d7
    1c2c:	00008703          	lb	a4,0(ra)
    1c30:	0100                	.insn	2, 0x0100
    1c32:	20a102db          	.insn	4, 0x20a102db
    1c36:	0000f103          	.insn	4, 0xf103
    1c3a:	0100                	.insn	2, 0x0100
    1c3c:	02e0                	.insn	2, 0x02e0
    1c3e:	21a1                	.insn	2, 0x21a1
    1c40:	0000f103          	.insn	4, 0xf103
    1c44:	0100                	.insn	2, 0x0100
    1c46:	02e5                	.insn	2, 0x02e5
    1c48:	22a1                	.insn	2, 0x22a1
    1c4a:	0000f103          	.insn	4, 0xf103
    1c4e:	0100                	.insn	2, 0x0100
    1c50:	02ea                	.insn	2, 0x02ea
    1c52:	23a1                	.insn	2, 0x23a1
    1c54:	0000f103          	.insn	4, 0xf103
    1c58:	0100                	.insn	2, 0x0100
    1c5a:	24a102ef          	jal	t0,11ea4 <_start-0xee15c>
    1c5e:	0000f103          	.insn	4, 0xf103
    1c62:	0100                	.insn	2, 0x0100
    1c64:	25a102f3          	.insn	4, 0x25a102f3
    1c68:	0001bd07          	.insn	4, 0x0001bd07
    1c6c:	0100                	.insn	2, 0x0100
    1c6e:	0114                	.insn	2, 0x0114
    1c70:	a102                	.insn	2, 0xa102
    1c72:	0726                	.insn	2, 0x0726
    1c74:	00000087          	.insn	4, 0x0087
    1c78:	2f01                	.insn	2, 0x2f01
    1c7a:	0201                	.insn	2, 0x0201
    1c7c:	27a1                	.insn	2, 0x27a1
    1c7e:	0000f107          	.insn	4, 0xf107
    1c82:	0100                	.insn	2, 0x0100
    1c84:	a1020137          	lui	sp,0xa1020
    1c88:	0728                	.insn	2, 0x0728
    1c8a:	00f1                	.insn	2, 0x00f1
    1c8c:	0000                	.insn	2, 0x0000
    1c8e:	3c01                	.insn	2, 0x3c01
    1c90:	0201                	.insn	2, 0x0201
    1c92:	29a1                	.insn	2, 0x29a1
    1c94:	00010707          	.insn	4, 0x00010707
    1c98:	0100                	.insn	2, 0x0100
    1c9a:	a1020143          	.insn	4, 0xa1020143
    1c9e:	072a                	.insn	2, 0x072a
    1ca0:	0265                	.insn	2, 0x0265
    1ca2:	0000                	.insn	2, 0x0000
    1ca4:	4701                	.insn	2, 0x4701
    1ca6:	0201                	.insn	2, 0x0201
    1ca8:	2ba1                	.insn	2, 0x2ba1
    1caa:	4904                	.insn	2, 0x4904
    1cac:	0000                	.insn	2, 0x0000
    1cae:	0500                	.insn	2, 0x0500
    1cb0:	004d                	.insn	2, 0x004d
    1cb2:	0000                	.insn	2, 0x0000
    1cb4:	3d07000f          	.insn	4, 0x3d07000f
    1cb8:	0000                	.insn	2, 0x0000
    1cba:	0100                	.insn	2, 0x0100
    1cbc:	0150                	.insn	2, 0x0150
    1cbe:	a102                	.insn	2, 0xa102
    1cc0:	072c                	.insn	2, 0x072c
    1cc2:	00000287          	.insn	4, 0x0287
    1cc6:	6a01                	.insn	2, 0x6a01
    1cc8:	0201                	.insn	2, 0x0201
    1cca:	2da1                	.insn	2, 0x2da1
    1ccc:	4904                	.insn	2, 0x4904
    1cce:	0000                	.insn	2, 0x0000
    1cd0:	0500                	.insn	2, 0x0500
    1cd2:	004d                	.insn	2, 0x004d
    1cd4:	0000                	.insn	2, 0x0000
    1cd6:	000e                	.insn	2, 0x000e
    1cd8:	00028707          	.insn	4, 0x00028707
    1cdc:	0100                	.insn	2, 0x0100
    1cde:	0179                	.insn	2, 0x0179
    1ce0:	a102                	.insn	2, 0xa102
    1ce2:	072e                	.insn	2, 0x072e
    1ce4:	02a9                	.insn	2, 0x02a9
    1ce6:	0000                	.insn	2, 0x0000
    1ce8:	8801                	.insn	2, 0x8801
    1cea:	0201                	.insn	2, 0x0201
    1cec:	2fa1                	.insn	2, 0x2fa1
    1cee:	4904                	.insn	2, 0x4904
    1cf0:	0000                	.insn	2, 0x0000
    1cf2:	0500                	.insn	2, 0x0500
    1cf4:	004d                	.insn	2, 0x004d
    1cf6:	0000                	.insn	2, 0x0000
    1cf8:	000d                	.insn	2, 0x000d
    1cfa:	00008707          	.insn	4, 0x8707
    1cfe:	0100                	.insn	2, 0x0100
    1d00:	018d                	.insn	2, 0x018d
    1d02:	a102                	.insn	2, 0xa102
    1d04:	0730                	.insn	2, 0x0730
    1d06:	01bd                	.insn	2, 0x01bd
    1d08:	0000                	.insn	2, 0x0000
    1d0a:	b901                	.insn	2, 0xb901
    1d0c:	0201                	.insn	2, 0x0201
    1d0e:	31a1                	.insn	2, 0x31a1
    1d10:	00005b07          	.insn	4, 0x5b07
    1d14:	0100                	.insn	2, 0x0100
    1d16:	01bc                	.insn	2, 0x01bc
    1d18:	a102                	.insn	2, 0xa102
    1d1a:	0732                	.insn	2, 0x0732
    1d1c:	003d                	.insn	2, 0x003d
    1d1e:	0000                	.insn	2, 0x0000
    1d20:	c001                	.insn	2, 0xc001
    1d22:	0201                	.insn	2, 0x0201
    1d24:	33a1                	.insn	2, 0x33a1
    1d26:	00003d07          	.insn	4, 0x3d07
    1d2a:	0100                	.insn	2, 0x0100
    1d2c:	01c2                	.insn	2, 0x01c2
    1d2e:	a102                	.insn	2, 0xa102
    1d30:	0734                	.insn	2, 0x0734
    1d32:	000002f7          	.insn	4, 0x02f7
    1d36:	c401                	.insn	2, 0xc401
    1d38:	0201                	.insn	2, 0x0201
    1d3a:	35a1                	.insn	2, 0x35a1
    1d3c:	4904                	.insn	2, 0x4904
    1d3e:	0000                	.insn	2, 0x0000
    1d40:	0500                	.insn	2, 0x0500
    1d42:	004d                	.insn	2, 0x004d
    1d44:	0000                	.insn	2, 0x0000
    1d46:	0002                	.insn	2, 0x0002
    1d48:	0002a907          	.insn	4, 0x0002a907
    1d4c:	0100                	.insn	2, 0x0100
    1d4e:	01c6                	.insn	2, 0x01c6
    1d50:	a102                	.insn	2, 0xa102
    1d52:	0736                	.insn	2, 0x0736
    1d54:	00000087          	.insn	4, 0x0087
    1d58:	cb01                	.insn	2, 0xcb01
    1d5a:	0201                	.insn	2, 0x0201
    1d5c:	37a1                	.insn	2, 0x37a1
    1d5e:	00032407          	.insn	4, 0x00032407
    1d62:	0100                	.insn	2, 0x0100
    1d64:	01d0                	.insn	2, 0x01d0
    1d66:	a102                	.insn	2, 0xa102
    1d68:	0438                	.insn	2, 0x0438
    1d6a:	0049                	.insn	2, 0x0049
    1d6c:	0000                	.insn	2, 0x0000
    1d6e:	4d05                	.insn	2, 0x4d05
    1d70:	0000                	.insn	2, 0x0000
    1d72:	1e00                	.insn	2, 0x1e00
    1d74:	0700                	.insn	2, 0x0700
    1d76:	01bd                	.insn	2, 0x01bd
    1d78:	0000                	.insn	2, 0x0000
    1d7a:	d701                	.insn	2, 0xd701
    1d7c:	0201                	.insn	2, 0x0201
    1d7e:	39a1                	.insn	2, 0x39a1
    1d80:	0001bd07          	.insn	4, 0x0001bd07
    1d84:	0100                	.insn	2, 0x0100
    1d86:	01dc                	.insn	2, 0x01dc
    1d88:	a102                	.insn	2, 0xa102
    1d8a:	073a                	.insn	2, 0x073a
    1d8c:	01bd                	.insn	2, 0x01bd
    1d8e:	0000                	.insn	2, 0x0000
    1d90:	df01                	.insn	2, 0xdf01
    1d92:	0201                	.insn	2, 0x0201
    1d94:	3ba1                	.insn	2, 0x3ba1
    1d96:	00005b07          	.insn	4, 0x5b07
    1d9a:	0100                	.insn	2, 0x0100
    1d9c:	01e4                	.insn	2, 0x01e4
    1d9e:	a102                	.insn	2, 0xa102
    1da0:	073c                	.insn	2, 0x073c
    1da2:	00000367          	jalr	t1,zero # 0 <_start-0x100000>
    1da6:	e901                	.insn	2, 0xe901
    1da8:	0201                	.insn	2, 0x0201
    1daa:	3da1                	.insn	2, 0x3da1
    1dac:	4904                	.insn	2, 0x4904
    1dae:	0000                	.insn	2, 0x0000
    1db0:	0500                	.insn	2, 0x0500
    1db2:	004d                	.insn	2, 0x004d
    1db4:	0000                	.insn	2, 0x0000
    1db6:	001c                	.insn	2, 0x001c
    1db8:	00026507          	.insn	4, 0x00026507
    1dbc:	0100                	.insn	2, 0x0100
    1dbe:	01f1                	.insn	2, 0x01f1
    1dc0:	a102                	.insn	2, 0xa102
    1dc2:	073e                	.insn	2, 0x073e
    1dc4:	0071                	.insn	2, 0x0071
    1dc6:	0000                	.insn	2, 0x0000
    1dc8:	f901                	.insn	2, 0xf901
    1dca:	0201                	.insn	2, 0x0201
    1dcc:	3fa1                	.insn	2, 0x3fa1
    1dce:	00007107          	.insn	4, 0x7107
    1dd2:	0100                	.insn	2, 0x0100
    1dd4:	01fc                	.insn	2, 0x01fc
    1dd6:	a102                	.insn	2, 0xa102
    1dd8:	0740                	.insn	2, 0x0740
    1dda:	039f 0000 0001      	.insn	6, 0x00010000039f
    1de0:	0202                	.insn	2, 0x0202
    1de2:	41a1                	.insn	2, 0x41a1
    1de4:	4904                	.insn	2, 0x4904
    1de6:	0000                	.insn	2, 0x0000
    1de8:	0500                	.insn	2, 0x0500
    1dea:	004d                	.insn	2, 0x004d
    1dec:	0000                	.insn	2, 0x0000
    1dee:	3d070017          	auipc	zero,0x3d070
    1df2:	0000                	.insn	2, 0x0000
    1df4:	0100                	.insn	2, 0x0100
    1df6:	020a                	.insn	2, 0x020a
    1df8:	a102                	.insn	2, 0xa102
    1dfa:	0742                	.insn	2, 0x0742
    1dfc:	000000db          	.insn	4, 0x00db
    1e00:	0e01                	.insn	2, 0x0e01
    1e02:	0202                	.insn	2, 0x0202
    1e04:	43a1                	.insn	2, 0x43a1
    1e06:	0000a707          	.insn	4, 0xa707
    1e0a:	0100                	.insn	2, 0x0100
    1e0c:	0212                	.insn	2, 0x0212
    1e0e:	a102                	.insn	2, 0xa102
    1e10:	0744                	.insn	2, 0x0744
    1e12:	00000107          	.insn	4, 0x0107
    1e16:	1601                	.insn	2, 0x1601
    1e18:	0202                	.insn	2, 0x0202
    1e1a:	45a1                	.insn	2, 0x45a1
    1e1c:	00008707          	.insn	4, 0x8707
    1e20:	0100                	.insn	2, 0x0100
    1e22:	021c                	.insn	2, 0x021c
    1e24:	a102                	.insn	2, 0xa102
    1e26:	0746                	.insn	2, 0x0746
    1e28:	039f 0000 3d01      	.insn	6, 0x3d010000039f
    1e2e:	0202                	.insn	2, 0x0202
    1e30:	47a1                	.insn	2, 0x47a1
    1e32:	0000a707          	.insn	4, 0xa707
    1e36:	0100                	.insn	2, 0x0100
    1e38:	028d                	.insn	2, 0x028d
    1e3a:	a102                	.insn	2, 0xa102
    1e3c:	0748                	.insn	2, 0x0748
    1e3e:	0071                	.insn	2, 0x0071
    1e40:	0000                	.insn	2, 0x0000
    1e42:	9c01                	.insn	2, 0x9c01
    1e44:	0202                	.insn	2, 0x0202
    1e46:	49a1                	.insn	2, 0x49a1
    1e48:	0000db07          	.insn	4, 0xdb07
    1e4c:	0100                	.insn	2, 0x0100
    1e4e:	a10202a3          	sb	a6,-1531(tp) # fffffa05 <_stack_top+0xffef3a45>
    1e52:	084a                	.insn	2, 0x084a
    1e54:	1b05                	.insn	2, 0x1b05
    1e56:	0004                	.insn	2, 0x0004
    1e58:	0100                	.insn	2, 0x0100
    1e5a:	4ba10407          	.insn	4, 0x4ba10407
    1e5e:	28041823          	sh	zero,656(s0)
    1e62:	0004                	.insn	2, 0x0004
    1e64:	0900                	.insn	2, 0x0900
    1e66:	004d                	.insn	2, 0x004d
    1e68:	0000                	.insn	2, 0x0000
    1e6a:	0200                	.insn	2, 0x0200
    1e6c:	0a00                	.insn	2, 0x0a00
    1e6e:	0430                	.insn	2, 0x0430
    1e70:	0000                	.insn	2, 0x0000
    1e72:	02070207          	.insn	4, 0x02070207
    1e76:	0806                	.insn	2, 0x0806
    1e78:	0801                	.insn	2, 0x0801
    1e7a:	1b08                	.insn	2, 0x1b08
    1e7c:	0004                	.insn	2, 0x0004
    1e7e:	0100                	.insn	2, 0x0100
    1e80:	0508                	.insn	2, 0x0508
    1e82:	4ba1                	.insn	2, 0x4ba1
    1e84:	08049823          	sh	zero,144(s1)
    1e88:	4f09                	.insn	2, 0x4f09
    1e8a:	0004                	.insn	2, 0x0004
    1e8c:	0100                	.insn	2, 0x0100
    1e8e:	040a                	.insn	2, 0x040a
    1e90:	4ba1                	.insn	2, 0x4ba1
    1e92:	570a0823          	sb	a6,1392(s4)
    1e96:	0004                	.insn	2, 0x0004
    1e98:	0d00                	.insn	2, 0x0d00
    1e9a:	1404                	.insn	2, 0x1404
    1e9c:	00045c0b          	.insn	4, 0x00045c0b
    1ea0:	0c00                	.insn	2, 0x0c00
    1ea2:	046c                	.insn	2, 0x046c
    1ea4:	0000                	.insn	2, 0x0000
    1ea6:	700d                	.insn	2, 0x700d
    1ea8:	0004                	.insn	2, 0x0004
    1eaa:	0d00                	.insn	2, 0x0d00
    1eac:	047c                	.insn	2, 0x047c
    1eae:	0000                	.insn	2, 0x0000
    1eb0:	0200                	.insn	2, 0x0200
    1eb2:	050a                	.insn	2, 0x050a
    1eb4:	0a04                	.insn	2, 0x0a04
    1eb6:	0478                	.insn	2, 0x0478
    1eb8:	0000                	.insn	2, 0x0000
    1eba:	030c                	.insn	2, 0x030c
    1ebc:	02ca                	.insn	2, 0x02ca
    1ebe:	0b04070b          	.insn	4, 0x0b04070b
    1ec2:	0481                	.insn	2, 0x0481
    1ec4:	0000                	.insn	2, 0x0000
    1ec6:	300e                	.insn	2, 0x300e
    1ec8:	0004                	.insn	2, 0x0004
    1eca:	0700                	.insn	2, 0x0700
    1ecc:	08010e03          	lb	t3,128(sp) # a1020080 <_stack_top+0xa0f140c0>
    1ed0:	970e                	.insn	2, 0x970e
    1ed2:	0004                	.insn	2, 0x0004
    1ed4:	0100                	.insn	2, 0x0100
    1ed6:	040c                	.insn	2, 0x040c
    1ed8:	4ba1                	.insn	2, 0x4ba1
    1eda:	780a0c23          	sb	zero,1944(s4)
    1ede:	0004                	.insn	2, 0x0004
    1ee0:	0c00                	.insn	2, 0x0c00
    1ee2:	0902                	.insn	2, 0x0902
    1ee4:	0f08                	.insn	2, 0x0f08
    1ee6:	00000497          	auipc	s1,0x0
    1eea:	0d01                	.insn	2, 0x0d01
    1eec:	a104                	.insn	2, 0xa104
    1eee:	0814234b          	.insn	4, 0x0814234b
    1ef2:	9710                	.insn	2, 0x9710
    1ef4:	0004                	.insn	2, 0x0004
    1ef6:	0100                	.insn	2, 0x0100
    1ef8:	020e                	.insn	2, 0x020e
    1efa:	4ba1                	.insn	2, 0x4ba1
    1efc:	1108                	.insn	2, 0x1108
    1efe:	00000497          	auipc	s1,0x0
    1f02:	0f01                	.insn	2, 0x0f01
    1f04:	a104                	.insn	2, 0xa104
    1f06:	0804234b          	.insn	4, 0x0804234b
    1f0a:	9712                	.insn	2, 0x9712
    1f0c:	0004                	.insn	2, 0x0004
    1f0e:	0100                	.insn	2, 0x0100
    1f10:	0410                	.insn	2, 0x0410
    1f12:	4ba1                	.insn	2, 0x4ba1
    1f14:	db071023          	sh	a6,-608(a4)
    1f18:	0000                	.insn	2, 0x0000
    1f1a:	0100                	.insn	2, 0x0100
    1f1c:	a10201a7          	.insn	4, 0xa10201a7
    1f20:	0b4c                	.insn	2, 0x0b4c
    1f22:	04e1                	.insn	2, 0x04e1
    1f24:	0000                	.insn	2, 0x0000
    1f26:	0004280f          	.insn	4, 0x0004280f
    1f2a:	0b00                	.insn	2, 0x0b00
    1f2c:	000004eb          	.insn	4, 0x04eb
    1f30:	0004970f          	.insn	4, 0x0004970f
    1f34:	0a00                	.insn	2, 0x0a00
    1f36:	04f8                	.insn	2, 0x04f8
    1f38:	0000                	.insn	2, 0x0000
    1f3a:	0214                	.insn	2, 0x0214
    1f3c:	0208                	.insn	2, 0x0208
    1f3e:	10020713          	addi	a4,tp,256 # 100 <_start-0xfff00>
    1f42:	5c4d                	.insn	2, 0x5c4d
    1f44:	0000                	.insn	2, 0x0000
    1f46:	0100                	.insn	2, 0x0100
    1f48:	2a52                	.insn	2, 0x2a52
    1f4a:	4201                	.insn	2, 0x4201
    1f4c:	0470                	.insn	2, 0x0470
    1f4e:	0000                	.insn	2, 0x0000
    1f50:	0011                	.insn	2, 0x0011
    1f52:	011e                	.insn	2, 0x011e
    1f54:	9742                	.insn	2, 0x9742
    1f56:	0004                	.insn	2, 0x0004
    1f58:	1200                	.insn	2, 0x1200
    1f5a:	2f01                	.insn	2, 0x2f01
    1f5c:	4401                	.insn	2, 0x4401
    1f5e:	00000497          	auipc	s1,0x0
    1f62:	0212                	.insn	2, 0x0212
    1f64:	0130                	.insn	2, 0x0130
    1f66:	9745                	.insn	2, 0x9745
    1f68:	0004                	.insn	2, 0x0004
    1f6a:	1300                	.insn	2, 0x1300
    1f6c:	052d                	.insn	2, 0x052d
    1f6e:	0000                	.insn	2, 0x0000
    1f70:	004e                	.insn	2, 0x004e
    1f72:	1514                	.insn	2, 0x1514
    1f74:	2902                	.insn	2, 0x2902
    1f76:	380d                	.insn	2, 0x380d
    1f78:	0005                	.insn	2, 0x0005
    1f7a:	1500                	.insn	2, 0x1500
    1f7c:	0b00                	.insn	2, 0x0b00
    1f7e:	053d                	.insn	2, 0x053d
    1f80:	0000                	.insn	2, 0x0000
    1f82:	4916                	.insn	2, 0x4916
    1f84:	0000                	.insn	2, 0x0000
    1f86:	1700                	.insn	2, 0x1700
    1f88:	0116                	.insn	2, 0x0116
    1f8a:	0328                	.insn	2, 0x0328
    1f8c:	046c                	.insn	2, 0x046c
    1f8e:	0000                	.insn	2, 0x0000
    1f90:	1718                	.insn	2, 0x1718
    1f92:	2801                	.insn	2, 0x2801
    1f94:	0554                	.insn	2, 0x0554
    1f96:	0000                	.insn	2, 0x0000
    1f98:	0b00                	.insn	2, 0x0b00
    1f9a:	0559                	.insn	2, 0x0559
    1f9c:	0000                	.insn	2, 0x0000
    1f9e:	2816                	.insn	2, 0x2816
    1fa0:	0004                	.insn	2, 0x0004
    1fa2:	1900                	.insn	2, 0x1900
    1fa4:	0118                	.insn	2, 0x0118
    1fa6:	f012                	.insn	2, 0xf012
    1fa8:	0004                	.insn	2, 0x0004
    1faa:	1800                	.insn	2, 0x1800
    1fac:	0119                	.insn	2, 0x0119
    1fae:	5412                	.insn	2, 0x5412
    1fb0:	0005                	.insn	2, 0x0005
    1fb2:	0000                	.insn	2, 0x0000
    1fb4:	1a19                	.insn	2, 0x1a19
    1fb6:	1801                	.insn	2, 0x1801
    1fb8:	00000497          	auipc	s1,0x0
    1fbc:	1918                	.insn	2, 0x1918
    1fbe:	1801                	.insn	2, 0x1801
    1fc0:	0554                	.insn	2, 0x0554
    1fc2:	0000                	.insn	2, 0x0000
    1fc4:	1000                	.insn	2, 0x1000
    1fc6:	00043c4f          	.insn	4, 0x00043c4f
    1fca:	0100                	.insn	2, 0x0100
    1fcc:	2b52                	.insn	2, 0x2b52
    1fce:	6001                	.insn	2, 0x6001
    1fd0:	046c                	.insn	2, 0x046c
    1fd2:	0000                	.insn	2, 0x0000
    1fd4:	0311                	.insn	2, 0x0311
    1fd6:	0131                	.insn	2, 0x0131
    1fd8:	4f60                	.insn	2, 0x4f60
    1fda:	0004                	.insn	2, 0x0004
    1fdc:	1200                	.insn	2, 0x1200
    1fde:	3204                	.insn	2, 0x3204
    1fe0:	6401                	.insn	2, 0x6401
    1fe2:	00000497          	auipc	s1,0x0
    1fe6:	0512                	.insn	2, 0x0512
    1fe8:	97670133          	.insn	4, 0x97670133
    1fec:	0004                	.insn	2, 0x0004
    1fee:	1a00                	.insn	2, 0x1a00
    1ff0:	0134                	.insn	2, 0x0134
    1ff2:	2362                	.insn	2, 0x2362
    1ff4:	000d                	.insn	2, 0x000d
    1ff6:	1a00                	.insn	2, 0x1a00
    1ff8:	0135                	.insn	2, 0x0135
    1ffa:	9765                	.insn	2, 0x9765
    1ffc:	0004                	.insn	2, 0x0004
    1ffe:	1a00                	.insn	2, 0x1a00
    2000:	0136                	.insn	2, 0x0136
    2002:	9766                	.insn	2, 0x9766
    2004:	0004                	.insn	2, 0x0004
    2006:	1b00                	.insn	2, 0x1b00
    2008:	0542                	.insn	2, 0x0542
    200a:	0000                	.insn	2, 0x0000
    200c:	8050                	.insn	2, 0x8050
    200e:	0000                	.insn	2, 0x0000
    2010:	0100                	.insn	2, 0x0100
    2012:	5e1b097b          	.insn	4, 0x5e1b097b
    2016:	0005                	.insn	2, 0x0005
    2018:	5100                	.insn	2, 0x5100
    201a:	0014                	.insn	2, 0x0014
    201c:	0000                	.insn	2, 0x0000
    201e:	2d01                	.insn	2, 0x2d01
    2020:	1c09                	.insn	2, 0x1c09
    2022:	9f238203          	lb	tp,-1550(t2) # fffff9f2 <_stack_top+0xffef3a32>
    2026:	0566                	.insn	2, 0x0566
    2028:	0000                	.insn	2, 0x0000
    202a:	1b00                	.insn	2, 0x1b00
    202c:	055e                	.insn	2, 0x055e
    202e:	0000                	.insn	2, 0x0000
    2030:	0852                	.insn	2, 0x0852
    2032:	0000                	.insn	2, 0x0000
    2034:	0100                	.insn	2, 0x0100
    2036:	031c0933          	mul	s2,s8,a7
    203a:	2682                	.insn	2, 0x2682
    203c:	669f 0005 0000      	.insn	6, 0x0005669f
    2042:	00056f1b          	.insn	4, 0x00056f1b
    2046:	5300                	.insn	2, 0x5300
    2048:	0010                	.insn	2, 0x0010
    204a:	0000                	.insn	2, 0x0000
    204c:	3901                	.insn	2, 0x3901
    204e:	1c09                	.insn	2, 0x1c09
    2050:	9f3c8203          	lb	tp,-1549(s9)
    2054:	00000577          	.insn	4, 0x0577
    2058:	1b00                	.insn	2, 0x1b00
    205a:	0000056f          	jal	a0,205a <_start-0xfdfa6>
    205e:	0854                	.insn	2, 0x0854
    2060:	0000                	.insn	2, 0x0000
    2062:	0100                	.insn	2, 0x0100
    2064:	093c                	.insn	2, 0x093c
    2066:	041c                	.insn	2, 0x041c
    2068:	c482                	.insn	2, 0xc482
    206a:	9f00                	.insn	2, 0x9f00
    206c:	00000577          	.insn	4, 0x0577
    2070:	0000                	.insn	2, 0x0000
    2072:	00056f1b          	.insn	4, 0x00056f1b
    2076:	5500                	.insn	2, 0x5500
    2078:	001c                	.insn	2, 0x001c
    207a:	0000                	.insn	2, 0x0000
    207c:	8401                	.insn	2, 0x8401
    207e:	1c16                	.insn	2, 0x1c16
    2080:	8204                	.insn	2, 0x8204
    2082:	03de                	.insn	2, 0x03de
    2084:	779f 0005 0000      	.insn	6, 0x0005779f
    208a:	00055e1b          	.insn	4, 0x00055e1b
    208e:	5600                	.insn	2, 0x5600
    2090:	0010                	.insn	2, 0x0010
    2092:	0000                	.insn	2, 0x0000
    2094:	9f01                	.insn	2, 0x9f01
    2096:	1c18                	.insn	2, 0x1c18
    2098:	9f238203          	lb	tp,-1550(t2)
    209c:	0566                	.insn	2, 0x0566
    209e:	0000                	.insn	2, 0x0000
    20a0:	1b00                	.insn	2, 0x1b00
    20a2:	055e                	.insn	2, 0x055e
    20a4:	0000                	.insn	2, 0x0000
    20a6:	00000457          	.insn	4, 0x0457
    20aa:	0100                	.insn	2, 0x0100
    20ac:	1da5                	.insn	2, 0x1da5
    20ae:	031c                	.insn	2, 0x031c
    20b0:	2682                	.insn	2, 0x2682
    20b2:	669f 0005 0000      	.insn	6, 0x0005669f
    20b8:	00056f1b          	.insn	4, 0x00056f1b
    20bc:	5800                	.insn	2, 0x5800
    20be:	0004                	.insn	2, 0x0004
    20c0:	0000                	.insn	2, 0x0000
    20c2:	ab01                	.insn	2, 0xab01
    20c4:	1c10                	.insn	2, 0x1c10
    20c6:	9f3c8203          	lb	tp,-1549(s9)
    20ca:	00000577          	.insn	4, 0x0577
    20ce:	1b00                	.insn	2, 0x1b00
    20d0:	0000056f          	jal	a0,20d0 <_start-0xfdf30>
    20d4:	0459                	.insn	2, 0x0459
    20d6:	0000                	.insn	2, 0x0000
    20d8:	0100                	.insn	2, 0x0100
    20da:	16ae                	.insn	2, 0x16ae
    20dc:	041c                	.insn	2, 0x041c
    20de:	c482                	.insn	2, 0xc482
    20e0:	9f00                	.insn	2, 0x9f00
    20e2:	00000577          	.insn	4, 0x0577
    20e6:	1300                	.insn	2, 0x1300
    20e8:	052d                	.insn	2, 0x052d
    20ea:	0000                	.insn	2, 0x0000
    20ec:	135a                	.insn	2, 0x135a
    20ee:	052d                	.insn	2, 0x052d
    20f0:	0000                	.insn	2, 0x0000
    20f2:	5c011d5b          	.insn	4, 0x5c011d5b
    20f6:	135c                	.insn	2, 0x135c
    20f8:	052d                	.insn	2, 0x052d
    20fa:	0000                	.insn	2, 0x0000
    20fc:	135d                	.insn	2, 0x135d
    20fe:	052d                	.insn	2, 0x052d
    2100:	0000                	.insn	2, 0x0000
    2102:	1350                	.insn	2, 0x1350
    2104:	052d                	.insn	2, 0x052d
    2106:	0000                	.insn	2, 0x0000
    2108:	135e                	.insn	2, 0x135e
    210a:	052d                	.insn	2, 0x052d
    210c:	0000                	.insn	2, 0x0000
    210e:	1d5f 5c01 1360      	.insn	6, 0x13605c011d5f
    2114:	052d                	.insn	2, 0x052d
    2116:	0000                	.insn	2, 0x0000
    2118:	1361                	.insn	2, 0x1361
    211a:	0000073b          	.insn	4, 0x073b
    211e:	1362                	.insn	2, 0x1362
    2120:	052d                	.insn	2, 0x052d
    2122:	0000                	.insn	2, 0x0000
    2124:	052d1363          	bne	s10,s2,216a <_start-0xfde96>
    2128:	0000                	.insn	2, 0x0000
    212a:	1356                	.insn	2, 0x1356
    212c:	052d                	.insn	2, 0x052d
    212e:	0000                	.insn	2, 0x0000
    2130:	1364                	.insn	2, 0x1364
    2132:	052d                	.insn	2, 0x052d
    2134:	0000                	.insn	2, 0x0000
    2136:	052d1357          	.insn	4, 0x052d1357
    213a:	0000                	.insn	2, 0x0000
    213c:	1365                	.insn	2, 0x1365
    213e:	052d                	.insn	2, 0x052d
    2140:	0000                	.insn	2, 0x0000
    2142:	1358                	.insn	2, 0x1358
    2144:	052d                	.insn	2, 0x052d
    2146:	0000                	.insn	2, 0x0000
    2148:	1359                	.insn	2, 0x1359
    214a:	052d                	.insn	2, 0x052d
    214c:	0000                	.insn	2, 0x0000
    214e:	1366                	.insn	2, 0x1366
    2150:	052d                	.insn	2, 0x052d
    2152:	0000                	.insn	2, 0x0000
    2154:	052d1367          	.insn	4, 0x052d1367
    2158:	0000                	.insn	2, 0x0000
    215a:	1368                	.insn	2, 0x1368
    215c:	052d                	.insn	2, 0x052d
    215e:	0000                	.insn	2, 0x0000
    2160:	1369                	.insn	2, 0x1369
    2162:	052d                	.insn	2, 0x052d
    2164:	0000                	.insn	2, 0x0000
    2166:	136a                	.insn	2, 0x136a
    2168:	052d                	.insn	2, 0x052d
    216a:	0000                	.insn	2, 0x0000
    216c:	052d136b          	.insn	4, 0x052d136b
    2170:	0000                	.insn	2, 0x0000
    2172:	136c                	.insn	2, 0x136c
    2174:	052d                	.insn	2, 0x052d
    2176:	0000                	.insn	2, 0x0000
    2178:	136d                	.insn	2, 0x136d
    217a:	052d                	.insn	2, 0x052d
    217c:	0000                	.insn	2, 0x0000
    217e:	006e                	.insn	2, 0x006e
    2180:	6f1e                	.insn	2, 0x6f1e
    2182:	0094                	.insn	2, 0x0094
    2184:	0000                	.insn	2, 0x0000
    2186:	5201                	.insn	2, 0x5201
    2188:	0542                	.insn	2, 0x0542
    218a:	0000                	.insn	2, 0x0000
    218c:	4b1f 0005 1b00      	.insn	6, 0x1b0000054b1f
    2192:	055e                	.insn	2, 0x055e
    2194:	0000                	.insn	2, 0x0000
    2196:	1870                	.insn	2, 0x1870
    2198:	0000                	.insn	2, 0x0000
    219a:	0100                	.insn	2, 0x0100
    219c:	092d                	.insn	2, 0x092d
    219e:	031c                	.insn	2, 0x031c
    21a0:	669f237b          	.insn	4, 0x669f237b
    21a4:	0005                	.insn	2, 0x0005
    21a6:	0000                	.insn	2, 0x0000
    21a8:	00055e1b          	.insn	4, 0x00055e1b
    21ac:	7100                	.insn	2, 0x7100
    21ae:	0008                	.insn	2, 0x0008
    21b0:	0000                	.insn	2, 0x0000
    21b2:	3301                	.insn	2, 0x3301
    21b4:	1c09                	.insn	2, 0x1c09
    21b6:	9f267b03          	.insn	4, 0x9f267b03
    21ba:	0566                	.insn	2, 0x0566
    21bc:	0000                	.insn	2, 0x0000
    21be:	1b00                	.insn	2, 0x1b00
    21c0:	0000056f          	jal	a0,21c0 <_start-0xfde40>
    21c4:	1072                	.insn	2, 0x1072
    21c6:	0000                	.insn	2, 0x0000
    21c8:	0100                	.insn	2, 0x0100
    21ca:	0939                	.insn	2, 0x0939
    21cc:	031c                	.insn	2, 0x031c
    21ce:	779f3c7b          	.insn	4, 0x779f3c7b
    21d2:	0005                	.insn	2, 0x0005
    21d4:	0000                	.insn	2, 0x0000
    21d6:	00056f1b          	.insn	4, 0x00056f1b
    21da:	7300                	.insn	2, 0x7300
    21dc:	0004                	.insn	2, 0x0004
    21de:	0000                	.insn	2, 0x0000
    21e0:	3c01                	.insn	2, 0x3c01
    21e2:	1c09                	.insn	2, 0x1c09
    21e4:	7b04                	.insn	2, 0x7b04
    21e6:	00c4                	.insn	2, 0x00c4
    21e8:	779f 0005 0000      	.insn	6, 0x0005779f
    21ee:	1e00                	.insn	2, 0x1e00
    21f0:	9c74                	.insn	2, 0x9c74
    21f2:	0000                	.insn	2, 0x0000
    21f4:	0100                	.insn	2, 0x0100
    21f6:	fa52                	.insn	2, 0xfa52
    21f8:	20000007          	.insn	4, 0x20000007
    21fc:	0206                	.insn	2, 0x0206
    21fe:	0008                	.insn	2, 0x0008
    2200:	2100                	.insn	2, 0x2100
    2202:	00082207          	.insn	4, 0x00082207
    2206:	2100                	.insn	2, 0x2100
    2208:	1208                	.insn	2, 0x1208
    220a:	0008                	.insn	2, 0x0008
    220c:	2100                	.insn	2, 0x2100
    220e:	0a09                	.insn	2, 0x0a09
    2210:	0008                	.insn	2, 0x0008
    2212:	2200                	.insn	2, 0x2200
    2214:	081a                	.insn	2, 0x081a
    2216:	0000                	.insn	2, 0x0000
    2218:	00056f23          	.insn	4, 0x00056f23
    221c:	0000                	.insn	2, 0x0000
    221e:	0501                	.insn	2, 0x0501
    2220:	0c01                	.insn	2, 0x0c01
    2222:	0a20                	.insn	2, 0x0a20
    2224:	00000577          	.insn	4, 0x0577
    2228:	1d00                	.insn	2, 0x1d00
    222a:	5c01                	.insn	2, 0x5c01
    222c:	0075                	.insn	2, 0x0075
    222e:	1b19                	.insn	2, 0x1b19
    2230:	2001                	.insn	2, 0x2001
    2232:	0049                	.insn	2, 0x0049
    2234:	0000                	.insn	2, 0x0000
    2236:	1c18                	.insn	2, 0x1c18
    2238:	2001                	.insn	2, 0x2001
    223a:	0049                	.insn	2, 0x0049
    223c:	0000                	.insn	2, 0x0000
    223e:	2400                	.insn	2, 0x2400
    2240:	011d                	.insn	2, 0x011d
    2242:	70f8                	.insn	2, 0x70f8
    2244:	0004                	.insn	2, 0x0004
    2246:	1800                	.insn	2, 0x1800
    2248:	011e                	.insn	2, 0x011e
    224a:	97f8                	.insn	2, 0x97f8
    224c:	0004                	.insn	2, 0x0004
    224e:	1a00                	.insn	2, 0x1a00
    2250:	011f 97fb 0004      	.insn	6, 0x000497fb011f
    2256:	1a00                	.insn	2, 0x1a00
    2258:	0120                	.insn	2, 0x0120
    225a:	97fc                	.insn	2, 0x97fc
    225c:	0004                	.insn	2, 0x0004
    225e:	1a00                	.insn	2, 0x1a00
    2260:	0121                	.insn	2, 0x0121
    2262:	97fd                	.insn	2, 0x97fd
    2264:	0004                	.insn	2, 0x0004
    2266:	1a00                	.insn	2, 0x1a00
    2268:	0122                	.insn	2, 0x0122
    226a:	97fa                	.insn	2, 0x97fa
    226c:	0004                	.insn	2, 0x0004
    226e:	0000                	.insn	2, 0x0000
    2270:	7625                	.insn	2, 0x7625
    2272:	0480                	.insn	2, 0x0480
    2274:	0000                	.insn	2, 0x0000
    2276:	5201                	.insn	2, 0x5201
    2278:	012c                	.insn	2, 0x012c
    227a:	046c010b          	.insn	4, 0x046c010b
    227e:	0000                	.insn	2, 0x0000
    2280:	0b26                	.insn	2, 0x0b26
    2282:	0138                	.insn	2, 0x0138
    2284:	010c                	.insn	2, 0x010c
    2286:	0538                	.insn	2, 0x0538
    2288:	0000                	.insn	2, 0x0000
    228a:	0c26                	.insn	2, 0x0c26
    228c:	011e                	.insn	2, 0x011e
    228e:	010d                	.insn	2, 0x010d
    2290:	0d34                	.insn	2, 0x0d34
    2292:	0000                	.insn	2, 0x0000
    2294:	0d26                	.insn	2, 0x0d26
    2296:	0139                	.insn	2, 0x0139
    2298:	010e                	.insn	2, 0x010e
    229a:	0d34                	.insn	2, 0x0d34
    229c:	0000                	.insn	2, 0x0000
    229e:	c1910327          	.insn	4, 0xc1910327
    22a2:	3700                	.insn	2, 0x3700
    22a4:	1201                	.insn	2, 0x1201
    22a6:	2801                	.insn	2, 0x2801
    22a8:	000d                	.insn	2, 0x000d
    22aa:	2800                	.insn	2, 0x2800
    22ac:	3c11                	.insn	2, 0x3c11
    22ae:	1101                	.insn	2, 0x1101
    22b0:	9701                	.insn	2, 0x9701
    22b2:	0004                	.insn	2, 0x0004
    22b4:	2900                	.insn	2, 0x2900
    22b6:	2801                	.insn	2, 0x2801
    22b8:	1a013a0f          	.insn	4, 0x1a013a0f
    22bc:	6c01                	.insn	2, 0x6c01
    22be:	0004                	.insn	2, 0x0004
    22c0:	2800                	.insn	2, 0x2800
    22c2:	3b10                	.insn	2, 0x3b10
    22c4:	1b01                	.insn	2, 0x1b01
    22c6:	6c01                	.insn	2, 0x6c01
    22c8:	0004                	.insn	2, 0x0004
    22ca:	2300                	.insn	2, 0x2300
    22cc:	07e9                	.insn	2, 0x07e9
    22ce:	0000                	.insn	2, 0x0000
    22d0:	0102                	.insn	2, 0x0102
    22d2:	011e                	.insn	2, 0x011e
    22d4:	5a011c1b          	.insn	4, 0x5a011c1b
    22d8:	07f1                	.insn	2, 0x07f1
    22da:	0000                	.insn	2, 0x0000
    22dc:	2a00                	.insn	2, 0x2a00
    22de:	07e9                	.insn	2, 0x07e9
    22e0:	0000                	.insn	2, 0x0000
    22e2:	00001877          	.insn	4, 0x1877
    22e6:	0100                	.insn	2, 0x0100
    22e8:	0128                	.insn	2, 0x0128
    22ea:	782b001b          	.insn	4, 0x782b001b
    22ee:	002c                	.insn	2, 0x002c
    22f0:	0000                	.insn	2, 0x0000
    22f2:	0e28                	.insn	2, 0x0e28
    22f4:	013a                	.insn	2, 0x013a
    22f6:	0116                	.insn	2, 0x0116
    22f8:	046c                	.insn	2, 0x046c
    22fa:	0000                	.insn	2, 0x0000
    22fc:	2900                	.insn	2, 0x2900
    22fe:	3d122803          	lw	a6,977(tp) # 3d1 <_start-0xffc2f>
    2302:	3501                	.insn	2, 0x3501
    2304:	9701                	.insn	2, 0x9701
    2306:	0004                	.insn	2, 0x0004
    2308:	2900                	.insn	2, 0x2900
    230a:	2804                	.insn	2, 0x2804
    230c:	3e013e13          	sltiu	t3,sp,992
    2310:	9701                	.insn	2, 0x9701
    2312:	0004                	.insn	2, 0x0004
    2314:	2900                	.insn	2, 0x2900
    2316:	2c05                	.insn	2, 0x2c05
    2318:	0141                	.insn	2, 0x0141
    231a:	0140                	.insn	2, 0x0140
    231c:	00000d23          	sb	zero,26(zero) # 1a <_start-0xfffe6>
    2320:	0629                	.insn	2, 0x0629
    2322:	1428                	.insn	2, 0x1428
    2324:	013a                	.insn	2, 0x013a
    2326:	046c014b          	.insn	4, 0x046c014b
    232a:	0000                	.insn	2, 0x0000
    232c:	0729                	.insn	2, 0x0729
    232e:	1528                	.insn	2, 0x1528
    2330:	014d013f 0000046c 	.insn	8, 0x046c014d013f
    2338:	422c                	.insn	2, 0x422c
    233a:	4c01                	.insn	2, 0x4c01
    233c:	2801                	.insn	2, 0x2801
    233e:	0004                	.insn	2, 0x0004
    2340:	2b00                	.insn	2, 0x2b00
    2342:	8079                	.insn	2, 0x8079
    2344:	0000                	.insn	2, 0x0000
    2346:	2800                	.insn	2, 0x2800
    2348:	4016                	.insn	2, 0x4016
    234a:	6e01                	.insn	2, 0x6e01
    234c:	6c01                	.insn	2, 0x6c01
    234e:	0004                	.insn	2, 0x0004
    2350:	0000                	.insn	2, 0x0000
    2352:	00787a2b          	.insn	4, 0x00787a2b
    2356:	0000                	.insn	2, 0x0000
    2358:	432c                	.insn	2, 0x432c
    235a:	7601                	.insn	2, 0x7601
    235c:	9701                	.insn	2, 0x9701
    235e:	0004                	.insn	2, 0x0004
    2360:	2c00                	.insn	2, 0x2c00
    2362:	0144                	.insn	2, 0x0144
    2364:	04970177          	.insn	4, 0x04970177
    2368:	0000                	.insn	2, 0x0000
    236a:	5e2a                	.insn	2, 0x5e2a
    236c:	0005                	.insn	2, 0x0005
    236e:	7b00                	.insn	2, 0x7b00
    2370:	0008                	.insn	2, 0x0008
    2372:	0000                	.insn	2, 0x0000
    2374:	7b01                	.insn	2, 0x7b01
    2376:	1d01                	.insn	2, 0x1d01
    2378:	5e2d                	.insn	2, 0x5e2d
    237a:	0005                	.insn	2, 0x0005
    237c:	0800                	.insn	2, 0x0800
    237e:	7c01                	.insn	2, 0x7c01
    2380:	1d01                	.insn	2, 0x1d01
    2382:	6f2a                	.insn	2, 0x6f2a
    2384:	0005                	.insn	2, 0x0005
    2386:	7c00                	.insn	2, 0x7c00
    2388:	002c                	.insn	2, 0x002c
    238a:	0000                	.insn	2, 0x0000
    238c:	7f01                	.insn	2, 0x7f01
    238e:	2001                	.insn	2, 0x2001
    2390:	0000                	.insn	2, 0x0000
    2392:	0000                	.insn	2, 0x0000
    2394:	2e00                	.insn	2, 0x2e00
    2396:	07fa                	.insn	2, 0x07fa
    2398:	0000                	.insn	2, 0x0000
    239a:	5c7d                	.insn	2, 0x5c7d
    239c:	0000                	.insn	2, 0x0000
    239e:	0100                	.insn	2, 0x0100
    23a0:	018a                	.insn	2, 0x018a
    23a2:	02192017          	auipc	zero,0x2192
    23a6:	0008                	.insn	2, 0x0008
    23a8:	2100                	.insn	2, 0x2100
    23aa:	00080a17          	auipc	s4,0x80
    23ae:	2100                	.insn	2, 0x2100
    23b0:	1218                	.insn	2, 0x1218
    23b2:	0008                	.insn	2, 0x0008
    23b4:	2100                	.insn	2, 0x2100
    23b6:	1a1a                	.insn	2, 0x1a1a
    23b8:	0008                	.insn	2, 0x0008
    23ba:	2300                	.insn	2, 0x2300
    23bc:	0000056f          	jal	a0,23bc <_start-0xfdc44>
    23c0:	0109                	.insn	2, 0x0109
    23c2:	0105                	.insn	2, 0x0105
    23c4:	1c0c                	.insn	2, 0x1c0c
    23c6:	9f187903          	.insn	4, 0x9f187903
    23ca:	00000577          	.insn	4, 0x0577
    23ce:	0000                	.insn	2, 0x0000
    23d0:	1300                	.insn	2, 0x1300
    23d2:	052d                	.insn	2, 0x052d
    23d4:	0000                	.insn	2, 0x0000
    23d6:	137e                	.insn	2, 0x137e
    23d8:	052d                	.insn	2, 0x052d
    23da:	0000                	.insn	2, 0x0000
    23dc:	052d137f 01800000 	.insn	12, 0x00052d1301800000052d137f
    23e4:	00052d13 
    23e8:	8100                	.insn	2, 0x8100
    23ea:	1d01                	.insn	2, 0x1d01
    23ec:	5c01                	.insn	2, 0x5c01
    23ee:	0182                	.insn	2, 0x0182
    23f0:	00052d13          	slti	s10,a0,0
    23f4:	8300                	.insn	2, 0x8300
    23f6:	1301                	.insn	2, 0x1301
    23f8:	052d                	.insn	2, 0x052d
    23fa:	0000                	.insn	2, 0x0000
    23fc:	1379                	.insn	2, 0x1379
    23fe:	052d                	.insn	2, 0x052d
    2400:	0000                	.insn	2, 0x0000
    2402:	0184                	.insn	2, 0x0184
    2404:	011d                	.insn	2, 0x011d
    2406:	855c                	.insn	2, 0x855c
    2408:	1301                	.insn	2, 0x1301
    240a:	052d                	.insn	2, 0x052d
    240c:	0000                	.insn	2, 0x0000
    240e:	0186                	.insn	2, 0x0186
    2410:	00052d13          	slti	s10,a0,0
    2414:	8700                	.insn	2, 0x8700
    2416:	0001                	.insn	2, 0x0001
    2418:	9201232f          	.insn	4, 0x9201232f
    241c:	9701                	.insn	2, 0x9701
    241e:	0004                	.insn	2, 0x0004
    2420:	3000                	.insn	2, 0x3000
    2422:	0124                	.insn	2, 0x0124
    2424:	01a0                	.insn	2, 0x01a0
    2426:	00000497          	auipc	s1,0x0
    242a:	1e31                	.insn	2, 0x1e31
    242c:	a001                	.insn	2, 0xa001
    242e:	9701                	.insn	2, 0x9701
    2430:	0004                	.insn	2, 0x0004
    2432:	2c00                	.insn	2, 0x2c00
    2434:	0125                	.insn	2, 0x0125
    2436:	01a2                	.insn	2, 0x01a2
    2438:	00000497          	auipc	s1,0x0
    243c:	2500                	.insn	2, 0x2500
    243e:	0188                	.insn	2, 0x0188
    2440:	0414                	.insn	2, 0x0414
    2442:	0000                	.insn	2, 0x0000
    2444:	5201                	.insn	2, 0x5201
    2446:	012d                	.insn	2, 0x012d
    2448:	01ae                	.insn	2, 0x01ae
    244a:	046c                	.insn	2, 0x046c
    244c:	0000                	.insn	2, 0x0000
    244e:	1b26                	.insn	2, 0x1b26
    2450:	0138                	.insn	2, 0x0138
    2452:	053801af          	.insn	4, 0x053801af
    2456:	0000                	.insn	2, 0x0000
    2458:	1c26                	.insn	2, 0x1c26
    245a:	0145                	.insn	2, 0x0145
    245c:	01b0                	.insn	2, 0x01b0
    245e:	00000497          	auipc	s1,0x0
    2462:	1d26                	.insn	2, 0x1d26
    2464:	0146                	.insn	2, 0x0146
    2466:	01b1                	.insn	2, 0x01b1
    2468:	0d34                	.insn	2, 0x0d34
    246a:	0000                	.insn	2, 0x0000
    246c:	18910227          	.insn	4, 0x18910227
    2470:	011e                	.insn	2, 0x011e
    2472:	01b4                	.insn	2, 0x01b4
    2474:	00000497          	auipc	s1,0x0
    2478:	14910227          	.insn	4, 0x14910227
    247c:	0139                	.insn	2, 0x0139
    247e:	01b5                	.insn	2, 0x01b5
    2480:	00000497          	auipc	s1,0x0
    2484:	1e28                	.insn	2, 0x1e28
    2486:	01b70147          	.insn	4, 0x01b70147
    248a:	04dc                	.insn	2, 0x04dc
    248c:	0000                	.insn	2, 0x0000
    248e:	1f28                	.insn	2, 0x1f28
    2490:	0148                	.insn	2, 0x0148
    2492:	01b6                	.insn	2, 0x01b6
    2494:	00000497          	auipc	s1,0x0
    2498:	0a29                	.insn	2, 0x0a29
    249a:	2228                	.insn	2, 0x2228
    249c:	01da012f          	.insn	4, 0x01da012f
    24a0:	00000497          	auipc	s1,0x0
    24a4:	dc2e                	.insn	2, 0xdc2e
    24a6:	0009                	.insn	2, 0x0009
    24a8:	8900                	.insn	2, 0x8900
    24aa:	9801                	.insn	2, 0x9801
    24ac:	0000                	.insn	2, 0x0000
    24ae:	0100                	.insn	2, 0x0100
    24b0:	200f01ef          	jal	gp,f26b0 <_start-0xd950>
    24b4:	e520                	.insn	2, 0xe520
    24b6:	0009                	.insn	2, 0x0009
    24b8:	2100                	.insn	2, 0x2100
    24ba:	ee21                	.insn	2, 0xee21
    24bc:	0009                	.insn	2, 0x0009
    24be:	2d00                	.insn	2, 0x2d00
    24c0:	000009d3          	.insn	4, 0x09d3
    24c4:	01a4010b          	.insn	4, 0x01a4010b
    24c8:	000d                	.insn	2, 0x000d
    24ca:	8c018a2b          	.insn	4, 0x8c018a2b
    24ce:	0000                	.insn	2, 0x0000
    24d0:	2800                	.insn	2, 0x2800
    24d2:	f3013e23          	.insn	4, 0xf3013e23
    24d6:	9701                	.insn	2, 0x9701
    24d8:	0004                	.insn	2, 0x0004
    24da:	2b00                	.insn	2, 0x2b00
    24dc:	006c018b          	.insn	4, 0x006c018b
    24e0:	0000                	.insn	2, 0x0000
    24e2:	2428                	.insn	2, 0x2428
    24e4:	0149                	.insn	2, 0x0149
    24e6:	01f4                	.insn	2, 0x01f4
    24e8:	00000497          	auipc	s1,0x0
    24ec:	18018c2b          	.insn	4, 0x18018c2b
    24f0:	0000                	.insn	2, 0x0000
    24f2:	2800                	.insn	2, 0x2800
    24f4:	3a25                	.insn	2, 0x3a25
    24f6:	0401                	.insn	2, 0x0401
    24f8:	9702                	.insn	2, 0x9702
    24fa:	0004                	.insn	2, 0x0004
    24fc:	0000                	.insn	2, 0x0000
    24fe:	0000                	.insn	2, 0x0000
    2500:	fa2e                	.insn	2, 0xfa2e
    2502:	8d000007          	.insn	4, 0x8d000007
    2506:	6001                	.insn	2, 0x6001
    2508:	0000                	.insn	2, 0x0000
    250a:	0100                	.insn	2, 0x0100
    250c:	0214                	.insn	2, 0x0214
    250e:	02292013          	slti	zero,s2,34
    2512:	0008                	.insn	2, 0x0008
    2514:	2100                	.insn	2, 0x2100
    2516:	2226                	.insn	2, 0x2226
    2518:	0008                	.insn	2, 0x0008
    251a:	2100                	.insn	2, 0x2100
    251c:	00080a27          	.insn	4, 0x00080a27
    2520:	2100                	.insn	2, 0x2100
    2522:	1228                	.insn	2, 0x1228
    2524:	0008                	.insn	2, 0x0008
    2526:	2100                	.insn	2, 0x2100
    2528:	00081a2b          	.insn	4, 0x00081a2b
    252c:	2300                	.insn	2, 0x2300
    252e:	0000056f          	jal	a0,252e <_start-0xfdad2>
    2532:	010c                	.insn	2, 0x010c
    2534:	0105                	.insn	2, 0x0105
    2536:	200c                	.insn	2, 0x200c
    2538:	772a                	.insn	2, 0x772a
    253a:	0005                	.insn	2, 0x0005
    253c:	0000                	.insn	2, 0x0000
    253e:	0000                	.insn	2, 0x0000
    2540:	00052d13          	slti	s10,a0,0
    2544:	8e00                	.insn	2, 0x8e00
    2546:	1301                	.insn	2, 0x1301
    2548:	0000082b          	.insn	4, 0x082b
    254c:	2d13018f          	.insn	4, 0x2d13018f
    2550:	0005                	.insn	2, 0x0005
    2552:	9000                	.insn	2, 0x9000
    2554:	1301                	.insn	2, 0x1301
    2556:	052d                	.insn	2, 0x052d
    2558:	0000                	.insn	2, 0x0000
    255a:	0191                	.insn	2, 0x0191
    255c:	00052d13          	slti	s10,a0,0
    2560:	9200                	.insn	2, 0x9200
    2562:	1301                	.insn	2, 0x1301
    2564:	0ba0                	.insn	2, 0x0ba0
    2566:	0000                	.insn	2, 0x0000
    2568:	2d130193          	addi	gp,t1,721
    256c:	0005                	.insn	2, 0x0005
    256e:	9400                	.insn	2, 0x9400
    2570:	1301                	.insn	2, 0x1301
    2572:	052d                	.insn	2, 0x052d
    2574:	0000                	.insn	2, 0x0000
    2576:	0195                	.insn	2, 0x0195
    2578:	000ba013          	slti	zero,s7,0
    257c:	9600                	.insn	2, 0x9600
    257e:	1301                	.insn	2, 0x1301
    2580:	052d                	.insn	2, 0x052d
    2582:	0000                	.insn	2, 0x0000
    2584:	2d130197          	auipc	gp,0x2d130
    2588:	0005                	.insn	2, 0x0005
    258a:	9800                	.insn	2, 0x9800
    258c:	1301                	.insn	2, 0x1301
    258e:	052d                	.insn	2, 0x052d
    2590:	0000                	.insn	2, 0x0000
    2592:	0199                	.insn	2, 0x0199
    2594:	00052d13          	slti	s10,a0,0
    2598:	9a00                	.insn	2, 0x9a00
    259a:	1301                	.insn	2, 0x1301
    259c:	052d                	.insn	2, 0x052d
    259e:	0000                	.insn	2, 0x0000
    25a0:	2d13019b          	.insn	4, 0x2d13019b
    25a4:	0005                	.insn	2, 0x0005
    25a6:	8900                	.insn	2, 0x8900
    25a8:	1301                	.insn	2, 0x1301
    25aa:	052d                	.insn	2, 0x052d
    25ac:	0000                	.insn	2, 0x0000
    25ae:	019c                	.insn	2, 0x019c
    25b0:	00052d13          	slti	s10,a0,0
    25b4:	8a00                	.insn	2, 0x8a00
    25b6:	1301                	.insn	2, 0x1301
    25b8:	052d                	.insn	2, 0x052d
    25ba:	0000                	.insn	2, 0x0000
    25bc:	019d                	.insn	2, 0x019d
    25be:	011d                	.insn	2, 0x011d
    25c0:	9e5c                	.insn	2, 0x9e5c
    25c2:	1301                	.insn	2, 0x1301
    25c4:	052d                	.insn	2, 0x052d
    25c6:	0000                	.insn	2, 0x0000
    25c8:	019f 2d13 0005      	.insn	6, 0x00052d13019f
    25ce:	a000                	.insn	2, 0xa000
    25d0:	1301                	.insn	2, 0x1301
    25d2:	052d                	.insn	2, 0x052d
    25d4:	0000                	.insn	2, 0x0000
    25d6:	01a1                	.insn	2, 0x01a1
    25d8:	011d                	.insn	2, 0x011d
    25da:	a25c                	.insn	2, 0xa25c
    25dc:	1301                	.insn	2, 0x1301
    25de:	052d                	.insn	2, 0x052d
    25e0:	0000                	.insn	2, 0x0000
    25e2:	140001a3          	sb	zero,323(zero) # 143 <_start-0xffebd>
    25e6:	0226                	.insn	2, 0x0226
    25e8:	0d28                	.insn	2, 0x0d28
    25ea:	046c                	.insn	2, 0x046c
    25ec:	0000                	.insn	2, 0x0000
    25ee:	3000                	.insn	2, 0x3000
    25f0:	02210127          	.insn	4, 0x02210127
    25f4:	046c                	.insn	2, 0x046c
    25f6:	0000                	.insn	2, 0x0000
    25f8:	1c31                	.insn	2, 0x1c31
    25fa:	2101                	.insn	2, 0x2101
    25fc:	4902                	.insn	2, 0x4902
    25fe:	0000                	.insn	2, 0x0000
    2600:	0000                	.insn	2, 0x0000
    2602:	a425                	.insn	2, 0xa425
    2604:	0401                	.insn	2, 0x0401
    2606:	0004                	.insn	2, 0x0004
    2608:	0100                	.insn	2, 0x0100
    260a:	2e52                	.insn	2, 0x2e52
    260c:	2f01                	.insn	2, 0x2f01
    260e:	6c02                	.insn	2, 0x6c02
    2610:	0004                	.insn	2, 0x0004
    2612:	2600                	.insn	2, 0x2600
    2614:	382c                	.insn	2, 0x382c
    2616:	3001                	.insn	2, 0x3001
    2618:	3802                	.insn	2, 0x3802
    261a:	0005                	.insn	2, 0x0005
    261c:	2600                	.insn	2, 0x2600
    261e:	452d                	.insn	2, 0x452d
    2620:	3101                	.insn	2, 0x3101
    2622:	9702                	.insn	2, 0x9702
    2624:	0004                	.insn	2, 0x0004
    2626:	2600                	.insn	2, 0x2600
    2628:	4a2e                	.insn	2, 0x4a2e
    262a:	3201                	.insn	2, 0x3201
    262c:	3402                	.insn	2, 0x3402
    262e:	000d                	.insn	2, 0x000d
    2630:	2700                	.insn	2, 0x2700
    2632:	9102                	.insn	2, 0x9102
    2634:	3914                	.insn	2, 0x3914
    2636:	3601                	.insn	2, 0x3601
    2638:	9702                	.insn	2, 0x9702
    263a:	0004                	.insn	2, 0x0004
    263c:	2800                	.insn	2, 0x2800
    263e:	35011e2f          	.insn	4, 0x35011e2f
    2642:	9702                	.insn	2, 0x9702
    2644:	0004                	.insn	2, 0x0004
    2646:	2800                	.insn	2, 0x2800
    2648:	4730                	.insn	2, 0x4730
    264a:	3801                	.insn	2, 0x3801
    264c:	e602                	.insn	2, 0xe602
    264e:	0004                	.insn	2, 0x0004
    2650:	2800                	.insn	2, 0x2800
    2652:	4831                	.insn	2, 0x4831
    2654:	3701                	.insn	2, 0x3701
    2656:	9702                	.insn	2, 0x9702
    2658:	0004                	.insn	2, 0x0004
    265a:	2800                	.insn	2, 0x2800
    265c:	4b32                	.insn	2, 0x4b32
    265e:	3901                	.insn	2, 0x3901
    2660:	9702                	.insn	2, 0x9702
    2662:	0004                	.insn	2, 0x0004
    2664:	2800                	.insn	2, 0x2800
    2666:	3a014c33          	.insn	4, 0x3a014c33
    266a:	9702                	.insn	2, 0x9702
    266c:	0004                	.insn	2, 0x0004
    266e:	2800                	.insn	2, 0x2800
    2670:	4d34                	.insn	2, 0x4d34
    2672:	3b01                	.insn	2, 0x3b01
    2674:	9702                	.insn	2, 0x9702
    2676:	0004                	.insn	2, 0x0004
    2678:	2900                	.insn	2, 0x2900
    267a:	280d                	.insn	2, 0x280d
    267c:	57012f37          	lui	t5,0x57012
    2680:	9702                	.insn	2, 0x9702
    2682:	0004                	.insn	2, 0x0004
    2684:	2300                	.insn	2, 0x2300
    2686:	09dc                	.insn	2, 0x09dc
    2688:	0000                	.insn	2, 0x0000
    268a:	010e                	.insn	2, 0x010e
    268c:	0268                	.insn	2, 0x0268
    268e:	e535200f          	.insn	4, 0xe535200f
    2692:	0009                	.insn	2, 0x0009
    2694:	2100                	.insn	2, 0x2100
    2696:	ee36                	.insn	2, 0xee36
    2698:	0009                	.insn	2, 0x0009
    269a:	2d00                	.insn	2, 0x2d00
    269c:	000009d3          	.insn	4, 0x09d3
    26a0:	01a4010f          	.insn	4, 0x01a4010f
    26a4:	000d                	.insn	2, 0x000d
    26a6:	1029                	.insn	2, 0x1029
    26a8:	3828                	.insn	2, 0x3828
    26aa:	013e                	.insn	2, 0x013e
    26ac:	026a                	.insn	2, 0x026a
    26ae:	00000497          	auipc	s1,0x0
    26b2:	b001a52b          	.insn	4, 0xb001a52b
    26b6:	0000                	.insn	2, 0x0000
    26b8:	2800                	.insn	2, 0x2800
    26ba:	4e39                	.insn	2, 0x4e39
    26bc:	6b01                	.insn	2, 0x6b01
    26be:	9702                	.insn	2, 0x9702
    26c0:	0004                	.insn	2, 0x0004
    26c2:	2b00                	.insn	2, 0x2b00
    26c4:	01a6                	.insn	2, 0x01a6
    26c6:	006c                	.insn	2, 0x006c
    26c8:	0000                	.insn	2, 0x0000
    26ca:	3a2c                	.insn	2, 0x3a2c
    26cc:	7701                	.insn	2, 0x7701
    26ce:	9702                	.insn	2, 0x9702
    26d0:	0004                	.insn	2, 0x0004
    26d2:	2b00                	.insn	2, 0x2b00
    26d4:	006001a7          	.insn	4, 0x006001a7
    26d8:	0000                	.insn	2, 0x0000
    26da:	3a28                	.insn	2, 0x3a28
    26dc:	0279014f          	.insn	4, 0x0279014f
    26e0:	046c                	.insn	2, 0x046c
    26e2:	0000                	.insn	2, 0x0000
    26e4:	1c2c                	.insn	2, 0x1c2c
    26e6:	7801                	.insn	2, 0x7801
    26e8:	4902                	.insn	2, 0x4902
    26ea:	0000                	.insn	2, 0x0000
    26ec:	2d00                	.insn	2, 0x2d00
    26ee:	0baa                	.insn	2, 0x0baa
    26f0:	0000                	.insn	2, 0x0000
    26f2:	0111                	.insn	2, 0x0111
    26f4:	0015027b          	.insn	4, 0x0015027b
    26f8:	0000                	.insn	2, 0x0000
    26fa:	2e00                	.insn	2, 0x2e00
    26fc:	07fa                	.insn	2, 0x07fa
    26fe:	0000                	.insn	2, 0x0000
    2700:	01a8                	.insn	2, 0x01a8
    2702:	0070                	.insn	2, 0x0070
    2704:	0000                	.insn	2, 0x0000
    2706:	9801                	.insn	2, 0x9801
    2708:	1302                	.insn	2, 0x1302
    270a:	3b20                	.insn	2, 0x3b20
    270c:	0802                	.insn	2, 0x0802
    270e:	0000                	.insn	2, 0x0000
    2710:	3c21                	.insn	2, 0x3c21
    2712:	0822                	.insn	2, 0x0822
    2714:	0000                	.insn	2, 0x0000
    2716:	3d21                	.insn	2, 0x3d21
    2718:	080a                	.insn	2, 0x080a
    271a:	0000                	.insn	2, 0x0000
    271c:	3e21                	.insn	2, 0x3e21
    271e:	0812                	.insn	2, 0x0812
    2720:	0000                	.insn	2, 0x0000
    2722:	1a22                	.insn	2, 0x1a22
    2724:	0008                	.insn	2, 0x0008
    2726:	2300                	.insn	2, 0x2300
    2728:	0000056f          	jal	a0,2728 <_start-0xfd8d8>
    272c:	0112                	.insn	2, 0x0112
    272e:	0105                	.insn	2, 0x0105
    2730:	200c                	.insn	2, 0x200c
    2732:	0005773f 00000000 	.insn	8, 0x0005773f
    273a:	00052d13          	slti	s10,a0,0
    273e:	a900                	.insn	2, 0xa900
    2740:	1301                	.insn	2, 0x1301
    2742:	0000082b          	.insn	4, 0x082b
    2746:	01aa                	.insn	2, 0x01aa
    2748:	00052d13          	slti	s10,a0,0
    274c:	ab00                	.insn	2, 0xab00
    274e:	1301                	.insn	2, 0x1301
    2750:	052d                	.insn	2, 0x052d
    2752:	0000                	.insn	2, 0x0000
    2754:	01ac                	.insn	2, 0x01ac
    2756:	00052d13          	slti	s10,a0,0
    275a:	ad00                	.insn	2, 0xad00
    275c:	1d01                	.insn	2, 0x1d01
    275e:	5c01                	.insn	2, 0x5c01
    2760:	01ae                	.insn	2, 0x01ae
    2762:	011d                	.insn	2, 0x011d
    2764:	af5c                	.insn	2, 0xaf5c
    2766:	0001                	.insn	2, 0x0001
    2768:	0004280b          	.insn	4, 0x0004280b
    276c:	0400                	.insn	2, 0x0400
    276e:	0049                	.insn	2, 0x0049
    2770:	0000                	.insn	2, 0x0000
    2772:	4d05                	.insn	2, 0x4d05
    2774:	0000                	.insn	2, 0x0000
    2776:	0b00                	.insn	2, 0x0b00
    2778:	0b00                	.insn	2, 0x0b00
    277a:	00000497          	auipc	s1,0x0
	...

Disassembly of section .debug_abbrev:

00000000 <.debug_abbrev>:
   0:	1101                	.insn	2, 0x1101
   2:	1001                	.insn	2, 0x1001
   4:	12011117          	auipc	sp,0x12011
   8:	0301                	.insn	2, 0x0301
   a:	1b08                	.insn	2, 0x1b08
   c:	2508                	.insn	2, 0x2508
   e:	1308                	.insn	2, 0x1308
  10:	0005                	.insn	2, 0x0005
  12:	0200                	.insn	2, 0x0200
  14:	000a                	.insn	2, 0x000a
  16:	063a0803          	lb	a6,99(s4) # 8240d <_start-0x7dbf3>
  1a:	0111063b          	.insn	4, 0x0111063b
  1e:	0000                	.insn	2, 0x0000
  20:	0100                	.insn	2, 0x0100
  22:	0111                	.insn	2, 0x0111
  24:	2525                	.insn	2, 0x2525
  26:	25030513          	addi	a0,t1,592
  2a:	1772                	.insn	2, 0x1772
  2c:	1710                	.insn	2, 0x1710
  2e:	1b11251b          	.insn	4, 0x1b11251b
  32:	0612                	.insn	2, 0x0612
  34:	17741773          	csrrw	a4,0x177,s0
  38:	018c                	.insn	2, 0x018c
  3a:	02000017          	auipc	zero,0x2000
  3e:	0024                	.insn	2, 0x0024
  40:	0b3e2503          	lw	a0,179(t3) # 2742287 <_stack_top+0x26362c7>
  44:	00000b0b          	.insn	4, 0x0b0b
  48:	49003403          	.insn	4, 0x49003403
  4c:	3b0b3a13          	sltiu	s4,s6,944
  50:	0018020b          	.insn	4, 0x0018020b
  54:	0400                	.insn	2, 0x0400
  56:	0101                	.insn	2, 0x0101
  58:	1349                	.insn	2, 0x1349
  5a:	0000                	.insn	2, 0x0000
  5c:	2105                	.insn	2, 0x2105
  5e:	4900                	.insn	2, 0x4900
  60:	000b3713          	sltiu	a4,s6,0
  64:	0600                	.insn	2, 0x0600
  66:	0024                	.insn	2, 0x0024
  68:	0b0b2503          	lw	a0,176(s6)
  6c:	0b3e                	.insn	2, 0x0b3e
  6e:	0000                	.insn	2, 0x0000
  70:	49003407          	.insn	4, 0x49003407
  74:	3b0b3a13          	sltiu	s4,s6,944
  78:	0205                	.insn	2, 0x0205
  7a:	0018                	.insn	2, 0x0018
  7c:	0800                	.insn	2, 0x0800
  7e:	0034                	.insn	2, 0x0034
  80:	1349                	.insn	2, 0x1349
  82:	0b3a                	.insn	2, 0x0b3a
  84:	00000b3b          	.insn	4, 0x0b3b
  88:	1609                	.insn	2, 0x1609
  8a:	4900                	.insn	2, 0x4900
  8c:	3a250313          	addi	t1,a0,930
  90:	000b3b0b          	.insn	4, 0x000b3b0b
  94:	0a00                	.insn	2, 0x0a00
  96:	1349000f          	.insn	4, 0x1349000f
  9a:	0000                	.insn	2, 0x0000
  9c:	4900350b          	.insn	4, 0x4900350b
  a0:	0c000013          	li	zero,192
  a4:	0015                	.insn	2, 0x0015
  a6:	00001927          	.insn	4, 0x1927
  aa:	2e0d                	.insn	2, 0x2e0d
  ac:	0301                	.insn	2, 0x0301
  ae:	3a25                	.insn	2, 0x3a25
  b0:	270b3b0b          	.insn	4, 0x270b3b0b
  b4:	4919                	.insn	2, 0x4919
  b6:	01212013          	slti	zero,sp,18
  ba:	0000                	.insn	2, 0x0000
  bc:	050e                	.insn	2, 0x050e
  be:	0300                	.insn	2, 0x0300
  c0:	3a25                	.insn	2, 0x3a25
  c2:	490b3b0b          	.insn	4, 0x490b3b0b
  c6:	0f000013          	li	zero,240
  ca:	012e                	.insn	2, 0x012e
  cc:	0b3a2503          	lw	a0,179(s4)
  d0:	19270b3b          	.insn	4, 0x19270b3b
  d4:	2120                	.insn	2, 0x2120
  d6:	0001                	.insn	2, 0x0001
  d8:	1000                	.insn	2, 0x1000
  da:	012e                	.insn	2, 0x012e
  dc:	1b11                	.insn	2, 0x1b11
  de:	0612                	.insn	2, 0x0612
  e0:	1840                	.insn	2, 0x1840
  e2:	197a                	.insn	2, 0x197a
  e4:	1331                	.insn	2, 0x1331
  e6:	0000                	.insn	2, 0x0000
  e8:	0511                	.insn	2, 0x0511
  ea:	0200                	.insn	2, 0x0200
  ec:	3118                	.insn	2, 0x3118
  ee:	12000013          	li	zero,288
  f2:	011d                	.insn	2, 0x011d
  f4:	1331                	.insn	2, 0x1331
  f6:	1b11                	.insn	2, 0x1b11
  f8:	0612                	.insn	2, 0x0612
  fa:	0b58                	.insn	2, 0x0b58
  fc:	0b59                	.insn	2, 0x0b59
  fe:	00000b57          	.insn	4, 0x0b57
 102:	1c000513          	li	a0,448
 106:	0013310f          	.insn	4, 0x0013310f
 10a:	1400                	.insn	2, 0x1400
 10c:	012e                	.insn	2, 0x012e
 10e:	0b3a2503          	lw	a0,179(s4)
 112:	19270b3b          	.insn	4, 0x19270b3b
 116:	2120193f 15000001 	.insn	8, 0x150000012120193f
 11e:	012e                	.insn	2, 0x012e
 120:	1b11                	.insn	2, 0x1b11
 122:	0612                	.insn	2, 0x0612
 124:	1840                	.insn	2, 0x1840
 126:	197a                	.insn	2, 0x197a
 128:	0b3a2503          	lw	a0,179(s4)
 12c:	19270b3b          	.insn	4, 0x19270b3b
 130:	0000193f 02000516 	.insn	8, 0x020005160000193f
 138:	0318                	.insn	2, 0x0318
 13a:	3a25                	.insn	2, 0x3a25
 13c:	490b3b0b          	.insn	4, 0x490b3b0b
 140:	17000013          	li	zero,368
 144:	0026                	.insn	2, 0x0026
 146:	1349                	.insn	2, 0x1349
 148:	0000                	.insn	2, 0x0000
 14a:	3418                	.insn	2, 0x3418
 14c:	0300                	.insn	2, 0x0300
 14e:	3a25                	.insn	2, 0x3a25
 150:	490b3b0b          	.insn	4, 0x490b3b0b
 154:	19000013          	li	zero,400
 158:	002e                	.insn	2, 0x002e
 15a:	0b3a2503          	lw	a0,179(s4)
 15e:	19270b3b          	.insn	4, 0x19270b3b
 162:	2120                	.insn	2, 0x2120
 164:	0001                	.insn	2, 0x0001
 166:	1a00                	.insn	2, 0x1a00
 168:	0034                	.insn	2, 0x0034
 16a:	1802                	.insn	2, 0x1802
 16c:	0b3a2503          	lw	a0,179(s4)
 170:	13490b3b          	.insn	4, 0x13490b3b
 174:	0000                	.insn	2, 0x0000
 176:	0200051b          	.insn	4, 0x0200051b
 17a:	3122                	.insn	2, 0x3122
 17c:	1c000013          	li	zero,448
 180:	011d                	.insn	2, 0x011d
 182:	1331                	.insn	2, 0x1331
 184:	2355                	.insn	2, 0x2355
 186:	0b58                	.insn	2, 0x0b58
 188:	0b59                	.insn	2, 0x0b59
 18a:	00000b57          	.insn	4, 0x0b57
 18e:	1d1d                	.insn	2, 0x1d1d
 190:	3100                	.insn	2, 0x3100
 192:	121b1113          	.insn	4, 0x121b1113
 196:	5806                	.insn	2, 0x5806
 198:	570b590b          	.insn	4, 0x570b590b
 19c:	1e00000b          	.insn	4, 0x1e00000b
 1a0:	0034                	.insn	2, 0x0034
 1a2:	2202                	.insn	2, 0x2202
 1a4:	1331                	.insn	2, 0x1331
 1a6:	0000                	.insn	2, 0x0000
 1a8:	1d1f 3101 1113      	.insn	6, 0x111331011d1f
 1ae:	5806121b          	.insn	4, 0x5806121b
 1b2:	5705590b          	.insn	4, 0x5705590b
 1b6:	2000000b          	.insn	4, 0x2000000b
 1ba:	0034                	.insn	2, 0x0034
 1bc:	0f1c                	.insn	2, 0x0f1c
 1be:	1331                	.insn	2, 0x1331
 1c0:	0000                	.insn	2, 0x0000
 1c2:	4821                	.insn	2, 0x4821
 1c4:	7f00                	.insn	2, 0x7f00
 1c6:	001b7d13          	andi	s10,s6,1
 1ca:	2200                	.insn	2, 0x2200
 1cc:	0048                	.insn	2, 0x0048
 1ce:	7d180183          	lb	gp,2001(a6)
 1d2:	2300001b          	.insn	4, 0x2300001b
 1d6:	012e                	.insn	2, 0x012e
 1d8:	0b3a2503          	lw	a0,179(s4)
 1dc:	19270b3b          	.insn	4, 0x19270b3b
 1e0:	1349                	.insn	2, 0x1349
 1e2:	193c                	.insn	2, 0x193c
 1e4:	0000193f 49000524 	.insn	8, 0x490005240000193f
 1ec:	25000013          	li	zero,592
 1f0:	0115                	.insn	2, 0x0115
 1f2:	1349                	.insn	2, 0x1349
 1f4:	00001927          	.insn	4, 0x1927
 1f8:	1626                	.insn	2, 0x1626
 1fa:	4900                	.insn	2, 0x4900
 1fc:	3a250313          	addi	t1,a0,930
 200:	00053b0b          	.insn	4, 0x00053b0b
 204:	2700                	.insn	2, 0x2700
 206:	1b11010b          	.insn	4, 0x1b11010b
 20a:	0612                	.insn	2, 0x0612
 20c:	1331                	.insn	2, 0x1331
 20e:	0000                	.insn	2, 0x0000
 210:	0b28                	.insn	2, 0x0b28
 212:	0001                	.insn	2, 0x0001
 214:	2900                	.insn	2, 0x2900
 216:	012e                	.insn	2, 0x012e
 218:	1b11                	.insn	2, 0x1b11
 21a:	0612                	.insn	2, 0x0612
 21c:	1840                	.insn	2, 0x1840
 21e:	197a                	.insn	2, 0x197a
 220:	0b3a2503          	lw	a0,179(s4)
 224:	19270b3b          	.insn	4, 0x19270b3b
 228:	1349                	.insn	2, 0x1349
 22a:	0000                	.insn	2, 0x0000
 22c:	052a                	.insn	2, 0x052a
 22e:	0200                	.insn	2, 0x0200
 230:	0322                	.insn	2, 0x0322
 232:	3a25                	.insn	2, 0x3a25
 234:	490b3b0b          	.insn	4, 0x490b3b0b
 238:	2b000013          	li	zero,688
 23c:	0034                	.insn	2, 0x0034
 23e:	2202                	.insn	2, 0x2202
 240:	0b3a2503          	lw	a0,179(s4)
 244:	13490b3b          	.insn	4, 0x13490b3b
 248:	0000                	.insn	2, 0x0000
 24a:	0b2c                	.insn	2, 0x0b2c
 24c:	5501                	.insn	2, 0x5501
 24e:	2d000023          	sb	a6,704(zero) # 2c0 <_start-0xffd40>
 252:	011d                	.insn	2, 0x011d
 254:	1331                	.insn	2, 0x1331
 256:	1b11                	.insn	2, 0x1b11
 258:	0612                	.insn	2, 0x0612
 25a:	0b58                	.insn	2, 0x0b58
 25c:	0b59                	.insn	2, 0x0b59
 25e:	0000                	.insn	2, 0x0000
 260:	0100                	.insn	2, 0x0100
 262:	0111                	.insn	2, 0x0111
 264:	2525                	.insn	2, 0x2525
 266:	25030513          	addi	a0,t1,592
 26a:	1772                	.insn	2, 0x1772
 26c:	1710                	.insn	2, 0x1710
 26e:	1b11251b          	.insn	4, 0x1b11251b
 272:	0612                	.insn	2, 0x0612
 274:	17741773          	csrrw	a4,0x177,s0
 278:	018c                	.insn	2, 0x018c
 27a:	02000017          	auipc	zero,0x2000
 27e:	0034                	.insn	2, 0x0034
 280:	1349                	.insn	2, 0x1349
 282:	0b3a                	.insn	2, 0x0b3a
 284:	18020b3b          	.insn	4, 0x18020b3b
 288:	0000                	.insn	2, 0x0000
 28a:	49010103          	lb	sp,1168(sp) # 12011494 <_stack_top+0x11f054d4>
 28e:	04000013          	li	zero,64
 292:	0021                	.insn	2, 0x0021
 294:	1349                	.insn	2, 0x1349
 296:	00000b37          	lui	s6,0x0
 29a:	2405                	.insn	2, 0x2405
 29c:	0300                	.insn	2, 0x0300
 29e:	3e25                	.insn	2, 0x3e25
 2a0:	000b0b0b          	.insn	4, 0x000b0b0b
 2a4:	0600                	.insn	2, 0x0600
 2a6:	0024                	.insn	2, 0x0024
 2a8:	0b0b2503          	lw	a0,176(s6) # b0 <_start-0xfff50>
 2ac:	0b3e                	.insn	2, 0x0b3e
 2ae:	0000                	.insn	2, 0x0000
 2b0:	49003407          	.insn	4, 0x49003407
 2b4:	3b0b3a13          	sltiu	s4,s6,944
 2b8:	0205                	.insn	2, 0x0205
 2ba:	0018                	.insn	2, 0x0018
 2bc:	0800                	.insn	2, 0x0800
 2be:	012e                	.insn	2, 0x012e
 2c0:	0000                	.insn	2, 0x0000
 2c2:	3409                	.insn	2, 0x3409
 2c4:	0300                	.insn	2, 0x0300
 2c6:	4925                	.insn	2, 0x4925
 2c8:	3b0b3a13          	sltiu	s4,s6,944
 2cc:	0018020b          	.insn	4, 0x0018020b
 2d0:	0a00                	.insn	2, 0x0a00
 2d2:	0026                	.insn	2, 0x0026
 2d4:	1349                	.insn	2, 0x1349
 2d6:	0000                	.insn	2, 0x0000
 2d8:	49000f0b          	.insn	4, 0x49000f0b
 2dc:	0c000013          	li	zero,192
 2e0:	0016                	.insn	2, 0x0016
 2e2:	1349                	.insn	2, 0x1349
 2e4:	0b3a2503          	lw	a0,179(s4)
 2e8:	00000b3b          	.insn	4, 0x0b3b
 2ec:	260d                	.insn	2, 0x260d
 2ee:	0000                	.insn	2, 0x0000
 2f0:	0e00                	.insn	2, 0x0e00
 2f2:	012e                	.insn	2, 0x012e
 2f4:	1b11                	.insn	2, 0x1b11
 2f6:	0612                	.insn	2, 0x0612
 2f8:	1840                	.insn	2, 0x1840
 2fa:	197a                	.insn	2, 0x197a
 2fc:	0b3a2503          	lw	a0,179(s4)
 300:	19270b3b          	.insn	4, 0x19270b3b
 304:	1349                	.insn	2, 0x1349
 306:	0000193f 0200050f 	.insn	8, 0x0200050f0000193f
 30e:	0318                	.insn	2, 0x0318
 310:	3a25                	.insn	2, 0x3a25
 312:	490b3b0b          	.insn	4, 0x490b3b0b
 316:	10000013          	li	zero,256
 31a:	0005                	.insn	2, 0x0005
 31c:	2202                	.insn	2, 0x2202
 31e:	0b3a2503          	lw	a0,179(s4)
 322:	13490b3b          	.insn	4, 0x13490b3b
 326:	0000                	.insn	2, 0x0000
 328:	3411                	.insn	2, 0x3411
 32a:	0200                	.insn	2, 0x0200
 32c:	0322                	.insn	2, 0x0322
 32e:	3a25                	.insn	2, 0x3a25
 330:	490b3b0b          	.insn	4, 0x490b3b0b
 334:	12000013          	li	zero,288
 338:	0034                	.insn	2, 0x0034
 33a:	1802                	.insn	2, 0x1802
 33c:	0b3a2503          	lw	a0,179(s4)
 340:	13490b3b          	.insn	4, 0x13490b3b
 344:	0000                	.insn	2, 0x0000
 346:	03012e13          	slti	t3,sp,48
 34a:	3a25                	.insn	2, 0x3a25
 34c:	270b3b0b          	.insn	4, 0x270b3b0b
 350:	4919                	.insn	2, 0x4919
 352:	01212013          	slti	zero,sp,18
 356:	0000                	.insn	2, 0x0000
 358:	0514                	.insn	2, 0x0514
 35a:	0300                	.insn	2, 0x0300
 35c:	3a25                	.insn	2, 0x3a25
 35e:	490b3b0b          	.insn	4, 0x490b3b0b
 362:	15000013          	li	zero,336
 366:	0034                	.insn	2, 0x0034
 368:	0b3a2503          	lw	a0,179(s4)
 36c:	13490b3b          	.insn	4, 0x13490b3b
 370:	0000                	.insn	2, 0x0000
 372:	0b16                	.insn	2, 0x0b16
 374:	0001                	.insn	2, 0x0001
 376:	1700                	.insn	2, 0x1700
 378:	012e                	.insn	2, 0x012e
 37a:	1b11                	.insn	2, 0x1b11
 37c:	0612                	.insn	2, 0x0612
 37e:	1840                	.insn	2, 0x1840
 380:	197a                	.insn	2, 0x197a
 382:	0b3a2503          	lw	a0,179(s4)
 386:	19270b3b          	.insn	4, 0x19270b3b
 38a:	0000193f 11010b18 	.insn	8, 0x11010b180000193f
 392:	0006121b          	.insn	4, 0x0006121b
 396:	1900                	.insn	2, 0x1900
 398:	011d                	.insn	2, 0x011d
 39a:	1331                	.insn	2, 0x1331
 39c:	1b11                	.insn	2, 0x1b11
 39e:	0612                	.insn	2, 0x0612
 3a0:	0b58                	.insn	2, 0x0b58
 3a2:	0b59                	.insn	2, 0x0b59
 3a4:	00000b57          	.insn	4, 0x0b57
 3a8:	341a                	.insn	2, 0x341a
 3aa:	0200                	.insn	2, 0x0200
 3ac:	3122                	.insn	2, 0x3122
 3ae:	1b000013          	li	zero,432
 3b2:	1b11010b          	.insn	4, 0x1b11010b
 3b6:	0612                	.insn	2, 0x0612
 3b8:	1331                	.insn	2, 0x1331
 3ba:	0000                	.insn	2, 0x0000
 3bc:	341c                	.insn	2, 0x341c
 3be:	0200                	.insn	2, 0x0200
 3c0:	3118                	.insn	2, 0x3118
 3c2:	1d000013          	li	zero,464
 3c6:	0048                	.insn	2, 0x0048
 3c8:	0182137f 1b018119 	.insn	12, 0x481e00001b0181190182137f
 3d0:	481e0000 
 3d4:	7f00                	.insn	2, 0x7f00
 3d6:	001b7d13          	andi	s10,s6,1
 3da:	1f00                	.insn	2, 0x1f00
 3dc:	012e                	.insn	2, 0x012e
 3de:	0b3a2503          	lw	a0,179(s4)
 3e2:	19270b3b          	.insn	4, 0x19270b3b
 3e6:	193c                	.insn	2, 0x193c
 3e8:	0000193f 49000520 	.insn	8, 0x490005200000193f
 3f0:	21000013          	li	zero,528
 3f4:	000a                	.insn	2, 0x000a
 3f6:	0b3a2503          	lw	a0,179(s4)
 3fa:	0b390b3b          	.insn	4, 0x0b390b3b
 3fe:	1b11                	.insn	2, 0x1b11
 400:	0000                	.insn	2, 0x0000
 402:	0b22                	.insn	2, 0x0b22
 404:	5501                	.insn	2, 0x5501
 406:	23000023          	sb	a6,544(zero) # 220 <_start-0xffde0>
 40a:	0018                	.insn	2, 0x0018
 40c:	0000                	.insn	2, 0x0000
 40e:	2e24                	.insn	2, 0x2e24
 410:	1101                	.insn	2, 0x1101
 412:	4006121b          	.insn	4, 0x4006121b
 416:	7a18                	.insn	2, 0x7a18
 418:	3119                	.insn	2, 0x3119
 41a:	25000013          	li	zero,592
 41e:	0005                	.insn	2, 0x0005
 420:	2202                	.insn	2, 0x2202
 422:	1331                	.insn	2, 0x1331
 424:	0000                	.insn	2, 0x0000
 426:	0526                	.insn	2, 0x0526
 428:	0200                	.insn	2, 0x0200
 42a:	3118                	.insn	2, 0x3118
 42c:	27000013          	li	zero,624
 430:	2355010b          	.insn	4, 0x2355010b
 434:	1331                	.insn	2, 0x1331
 436:	0000                	.insn	2, 0x0000
 438:	2e28                	.insn	2, 0x2e28
 43a:	0301                	.insn	2, 0x0301
 43c:	3a25                	.insn	2, 0x3a25
 43e:	270b3b0b          	.insn	4, 0x270b3b0b
 442:	2019                	.insn	2, 0x2019
 444:	0121                	.insn	2, 0x0121
 446:	0000                	.insn	2, 0x0000
 448:	2e29                	.insn	2, 0x2e29
 44a:	1101                	.insn	2, 0x1101
 44c:	4006121b          	.insn	4, 0x4006121b
 450:	7a18                	.insn	2, 0x7a18
 452:	0319                	.insn	2, 0x0319
 454:	3a25                	.insn	2, 0x3a25
 456:	27053b0b          	.insn	4, 0x27053b0b
 45a:	3f19                	.insn	2, 0x3f19
 45c:	0019                	.insn	2, 0x0019
 45e:	2a00                	.insn	2, 0x2a00
 460:	0005                	.insn	2, 0x0005
 462:	2202                	.insn	2, 0x2202
 464:	0b3a2503          	lw	a0,179(s4)
 468:	1349053b          	.insn	4, 0x1349053b
 46c:	0000                	.insn	2, 0x0000
 46e:	0200342b          	.insn	4, 0x0200342b
 472:	0322                	.insn	2, 0x0322
 474:	3a25                	.insn	2, 0x3a25
 476:	49053b0b          	.insn	4, 0x49053b0b
 47a:	2c000013          	li	zero,704
 47e:	011d                	.insn	2, 0x011d
 480:	1331                	.insn	2, 0x1331
 482:	2355                	.insn	2, 0x2355
 484:	0b58                	.insn	2, 0x0b58
 486:	0559                	.insn	2, 0x0559
 488:	00000b57          	.insn	4, 0x0b57
 48c:	342d                	.insn	2, 0x342d
 48e:	0200                	.insn	2, 0x0200
 490:	0318                	.insn	2, 0x0318
 492:	3a25                	.insn	2, 0x3a25
 494:	49053b0b          	.insn	4, 0x49053b0b
 498:	2e000013          	li	zero,736
 49c:	001d                	.insn	2, 0x001d
 49e:	1331                	.insn	2, 0x1331
 4a0:	1b11                	.insn	2, 0x1b11
 4a2:	0612                	.insn	2, 0x0612
 4a4:	0b58                	.insn	2, 0x0b58
 4a6:	0559                	.insn	2, 0x0559
 4a8:	00000b57          	.insn	4, 0x0b57
 4ac:	03012e2f          	.insn	4, 0x03012e2f
 4b0:	3a25                	.insn	2, 0x3a25
 4b2:	270b3b0b          	.insn	4, 0x270b3b0b
 4b6:	4919                	.insn	2, 0x4919
 4b8:	20193f13          	sltiu	t5,s2,513
 4bc:	0121                	.insn	2, 0x0121
 4be:	0000                	.insn	2, 0x0000
 4c0:	3430                	.insn	2, 0x3430
 4c2:	1c00                	.insn	2, 0x1c00
 4c4:	3a25030f          	.insn	4, 0x3a25030f
 4c8:	49053b0b          	.insn	4, 0x49053b0b
 4cc:	31000013          	li	zero,784
 4d0:	0000000f          	fence	unknown,unknown
 4d4:	1632                	.insn	2, 0x1632
 4d6:	4900                	.insn	2, 0x4900
 4d8:	00250313          	addi	t1,a0,2
 4dc:	0000                	.insn	2, 0x0000
 4de:	1101                	.insn	2, 0x1101
 4e0:	2501                	.insn	2, 0x2501
 4e2:	1325                	.insn	2, 0x1325
 4e4:	0305                	.insn	2, 0x0305
 4e6:	7225                	.insn	2, 0x7225
 4e8:	1b171017          	auipc	zero,0x1b171
 4ec:	1125                	.insn	2, 0x1125
 4ee:	7306121b          	.insn	4, 0x7306121b
 4f2:	8c177417          	auipc	s0,0x8c177
 4f6:	1701                	.insn	2, 0x1701
 4f8:	0000                	.insn	2, 0x0000
 4fa:	2402                	.insn	2, 0x2402
 4fc:	0300                	.insn	2, 0x0300
 4fe:	3e25                	.insn	2, 0x3e25
 500:	000b0b0b          	.insn	4, 0x000b0b0b
 504:	0300                	.insn	2, 0x0300
 506:	0034                	.insn	2, 0x0034
 508:	1349                	.insn	2, 0x1349
 50a:	0b3a                	.insn	2, 0x0b3a
 50c:	18020b3b          	.insn	4, 0x18020b3b
 510:	0000                	.insn	2, 0x0000
 512:	0104                	.insn	2, 0x0104
 514:	4901                	.insn	2, 0x4901
 516:	05000013          	li	zero,80
 51a:	0021                	.insn	2, 0x0021
 51c:	1349                	.insn	2, 0x1349
 51e:	00000b37          	lui	s6,0x0
 522:	2406                	.insn	2, 0x2406
 524:	0300                	.insn	2, 0x0300
 526:	0b25                	.insn	2, 0x0b25
 528:	000b3e0b          	.insn	4, 0x000b3e0b
 52c:	0700                	.insn	2, 0x0700
 52e:	1349000f          	.insn	4, 0x1349000f
 532:	0000                	.insn	2, 0x0000
 534:	3508                	.insn	2, 0x3508
 536:	4900                	.insn	2, 0x4900
 538:	09000013          	li	zero,144
 53c:	0016                	.insn	2, 0x0016
 53e:	1349                	.insn	2, 0x1349
 540:	0b3a2503          	lw	a0,179(s4)
 544:	00000b3b          	.insn	4, 0x0b3b
 548:	2e0a                	.insn	2, 0x2e0a
 54a:	1101                	.insn	2, 0x1101
 54c:	4006121b          	.insn	4, 0x4006121b
 550:	7a18                	.insn	2, 0x7a18
 552:	3119                	.insn	2, 0x3119
 554:	0b000013          	li	zero,176
 558:	0005                	.insn	2, 0x0005
 55a:	1802                	.insn	2, 0x1802
 55c:	1331                	.insn	2, 0x1331
 55e:	0000                	.insn	2, 0x0000
 560:	480c                	.insn	2, 0x480c
 562:	7f00                	.insn	2, 0x7f00
 564:	19018213          	addi	tp,gp,400 # 2d132714 <_stack_top+0x2d026754>
 568:	0181                	.insn	2, 0x0181
 56a:	0d00001b          	.insn	4, 0x0d00001b
 56e:	012e                	.insn	2, 0x012e
 570:	1b11                	.insn	2, 0x1b11
 572:	0612                	.insn	2, 0x0612
 574:	1840                	.insn	2, 0x1840
 576:	197a                	.insn	2, 0x197a
 578:	0b3a2503          	lw	a0,179(s4)
 57c:	19270b3b          	.insn	4, 0x19270b3b
 580:	1349                	.insn	2, 0x1349
 582:	0000                	.insn	2, 0x0000
 584:	050e                	.insn	2, 0x050e
 586:	0200                	.insn	2, 0x0200
 588:	0322                	.insn	2, 0x0322
 58a:	3a25                	.insn	2, 0x3a25
 58c:	490b3b0b          	.insn	4, 0x490b3b0b
 590:	0f000013          	li	zero,240
 594:	0005                	.insn	2, 0x0005
 596:	1802                	.insn	2, 0x1802
 598:	0b3a2503          	lw	a0,179(s4)
 59c:	13490b3b          	.insn	4, 0x13490b3b
 5a0:	0000                	.insn	2, 0x0000
 5a2:	3410                	.insn	2, 0x3410
 5a4:	0200                	.insn	2, 0x0200
 5a6:	0322                	.insn	2, 0x0322
 5a8:	3a25                	.insn	2, 0x3a25
 5aa:	490b3b0b          	.insn	4, 0x490b3b0b
 5ae:	11000013          	li	zero,272
 5b2:	011d                	.insn	2, 0x011d
 5b4:	1331                	.insn	2, 0x1331
 5b6:	1b11                	.insn	2, 0x1b11
 5b8:	0612                	.insn	2, 0x0612
 5ba:	0b58                	.insn	2, 0x0b58
 5bc:	0b59                	.insn	2, 0x0b59
 5be:	00000b57          	.insn	4, 0x0b57
 5c2:	0512                	.insn	2, 0x0512
 5c4:	0200                	.insn	2, 0x0200
 5c6:	3122                	.insn	2, 0x3122
 5c8:	13000013          	li	zero,304
 5cc:	1b11010b          	.insn	4, 0x1b11010b
 5d0:	0612                	.insn	2, 0x0612
 5d2:	0000                	.insn	2, 0x0000
 5d4:	3414                	.insn	2, 0x3414
 5d6:	0200                	.insn	2, 0x0200
 5d8:	0318                	.insn	2, 0x0318
 5da:	3a25                	.insn	2, 0x3a25
 5dc:	490b3b0b          	.insn	4, 0x490b3b0b
 5e0:	15000013          	li	zero,336
 5e4:	012e                	.insn	2, 0x012e
 5e6:	0b3a2503          	lw	a0,179(s4)
 5ea:	19270b3b          	.insn	4, 0x19270b3b
 5ee:	2120                	.insn	2, 0x2120
 5f0:	0001                	.insn	2, 0x0001
 5f2:	1600                	.insn	2, 0x1600
 5f4:	0005                	.insn	2, 0x0005
 5f6:	0b3a2503          	lw	a0,179(s4)
 5fa:	13490b3b          	.insn	4, 0x13490b3b
 5fe:	0000                	.insn	2, 0x0000
 600:	03012e17          	auipc	t3,0x3012
 604:	3a25                	.insn	2, 0x3a25
 606:	270b3b0b          	.insn	4, 0x270b3b0b
 60a:	4919                	.insn	2, 0x4919
 60c:	20193f13          	sltiu	t5,s2,513
 610:	0121                	.insn	2, 0x0121
 612:	0000                	.insn	2, 0x0000
 614:	2e18                	.insn	2, 0x2e18
 616:	1101                	.insn	2, 0x1101
 618:	4006121b          	.insn	4, 0x4006121b
 61c:	7a18                	.insn	2, 0x7a18
 61e:	0319                	.insn	2, 0x0319
 620:	3a25                	.insn	2, 0x3a25
 622:	270b3b0b          	.insn	4, 0x270b3b0b
 626:	4919                	.insn	2, 0x4919
 628:	00193f13          	seqz	t5,s2
 62c:	1900                	.insn	2, 0x1900
 62e:	0034                	.insn	2, 0x0034
 630:	0d1c                	.insn	2, 0x0d1c
 632:	0b3a2503          	lw	a0,179(s4)
 636:	13490b3b          	.insn	4, 0x13490b3b
 63a:	0000                	.insn	2, 0x0000
 63c:	341a                	.insn	2, 0x341a
 63e:	0300                	.insn	2, 0x0300
 640:	3a25                	.insn	2, 0x3a25
 642:	490b3b0b          	.insn	4, 0x490b3b0b
 646:	1b000013          	li	zero,432
 64a:	011d                	.insn	2, 0x011d
 64c:	1331                	.insn	2, 0x1331
 64e:	2355                	.insn	2, 0x2355
 650:	0b58                	.insn	2, 0x0b58
 652:	0b59                	.insn	2, 0x0b59
 654:	00000b57          	.insn	4, 0x0b57
 658:	0b1c                	.insn	2, 0x0b1c
 65a:	5501                	.insn	2, 0x5501
 65c:	1d000023          	sb	a6,448(zero) # 1c0 <_start-0xffe40>
 660:	0048                	.insn	2, 0x0048
 662:	1b7d137f 2e1e0000 	.insn	12, 0x3a2503012e1e00001b7d137f
 66a:	3a250301 
 66e:	270b3b0b          	.insn	4, 0x270b3b0b
 672:	3c19                	.insn	2, 0x3c19
 674:	3f19                	.insn	2, 0x3f19
 676:	0019                	.insn	2, 0x0019
 678:	1f00                	.insn	2, 0x1f00
 67a:	0005                	.insn	2, 0x0005
 67c:	1349                	.insn	2, 0x1349
 67e:	0000                	.insn	2, 0x0000
 680:	1820                	.insn	2, 0x1820
 682:	0000                	.insn	2, 0x0000
 684:	2100                	.insn	2, 0x2100
 686:	0026                	.insn	2, 0x0026
 688:	1349                	.insn	2, 0x1349
 68a:	0000                	.insn	2, 0x0000
 68c:	2e22                	.insn	2, 0x2e22
 68e:	0301                	.insn	2, 0x0301
 690:	3a25                	.insn	2, 0x3a25
 692:	270b3b0b          	.insn	4, 0x270b3b0b
 696:	4919                	.insn	2, 0x4919
 698:	01212013          	slti	zero,sp,18
 69c:	0000                	.insn	2, 0x0000
 69e:	00010b23          	sb	zero,22(sp)
 6a2:	2400                	.insn	2, 0x2400
 6a4:	012e                	.insn	2, 0x012e
 6a6:	1b11                	.insn	2, 0x1b11
 6a8:	0612                	.insn	2, 0x0612
 6aa:	1840                	.insn	2, 0x1840
 6ac:	197a                	.insn	2, 0x197a
 6ae:	0b3a2503          	lw	a0,179(s4)
 6b2:	19270b3b          	.insn	4, 0x19270b3b
 6b6:	0000193f 02003425 	.insn	8, 0x020034250000193f
 6be:	3122                	.insn	2, 0x3122
 6c0:	26000013          	li	zero,608
 6c4:	1b11010b          	.insn	4, 0x1b11010b
 6c8:	0612                	.insn	2, 0x0612
 6ca:	1331                	.insn	2, 0x1331
 6cc:	0000                	.insn	2, 0x0000
 6ce:	49002127          	.insn	4, 0x49002127
 6d2:	00053713          	sltiu	a4,a0,0
 6d6:	0000                	.insn	2, 0x0000
 6d8:	1101                	.insn	2, 0x1101
 6da:	2501                	.insn	2, 0x2501
 6dc:	1325                	.insn	2, 0x1325
 6de:	0305                	.insn	2, 0x0305
 6e0:	7225                	.insn	2, 0x7225
 6e2:	1b171017          	auipc	zero,0x1b171
 6e6:	1125                	.insn	2, 0x1125
 6e8:	7306121b          	.insn	4, 0x7306121b
 6ec:	8c177417          	auipc	s0,0x8c177
 6f0:	1701                	.insn	2, 0x1701
 6f2:	0000                	.insn	2, 0x0000
 6f4:	2402                	.insn	2, 0x2402
 6f6:	0300                	.insn	2, 0x0300
 6f8:	3e25                	.insn	2, 0x3e25
 6fa:	000b0b0b          	.insn	4, 0x000b0b0b
 6fe:	0300                	.insn	2, 0x0300
 700:	0034                	.insn	2, 0x0034
 702:	1349                	.insn	2, 0x1349
 704:	0b3a                	.insn	2, 0x0b3a
 706:	18020b3b          	.insn	4, 0x18020b3b
 70a:	0000                	.insn	2, 0x0000
 70c:	0104                	.insn	2, 0x0104
 70e:	4901                	.insn	2, 0x4901
 710:	05000013          	li	zero,80
 714:	0021                	.insn	2, 0x0021
 716:	1349                	.insn	2, 0x1349
 718:	00000b37          	lui	s6,0x0
 71c:	2406                	.insn	2, 0x2406
 71e:	0300                	.insn	2, 0x0300
 720:	0b25                	.insn	2, 0x0b25
 722:	000b3e0b          	.insn	4, 0x000b3e0b
 726:	0700                	.insn	2, 0x0700
 728:	0034                	.insn	2, 0x0034
 72a:	1349                	.insn	2, 0x1349
 72c:	0b3a                	.insn	2, 0x0b3a
 72e:	1802053b          	.insn	4, 0x1802053b
 732:	0000                	.insn	2, 0x0000
 734:	3408                	.insn	2, 0x3408
 736:	0300                	.insn	2, 0x0300
 738:	4925                	.insn	2, 0x4925
 73a:	3b0b3a13          	sltiu	s4,s6,944
 73e:	0018020b          	.insn	4, 0x0018020b
 742:	0900                	.insn	2, 0x0900
 744:	0021                	.insn	2, 0x0021
 746:	1349                	.insn	2, 0x1349
 748:	00000537          	lui	a0,0x0
 74c:	160a                	.insn	2, 0x160a
 74e:	4900                	.insn	2, 0x4900
 750:	3a250313          	addi	t1,a0,930 # 3a2 <_start-0xffc5e>
 754:	000b3b0b          	.insn	4, 0x000b3b0b
 758:	0b00                	.insn	2, 0x0b00
 75a:	1349000f          	.insn	4, 0x1349000f
 75e:	0000                	.insn	2, 0x0000
 760:	150c                	.insn	2, 0x150c
 762:	4901                	.insn	2, 0x4901
 764:	00192713          	slti	a4,s2,1
 768:	0d00                	.insn	2, 0x0d00
 76a:	0005                	.insn	2, 0x0005
 76c:	1349                	.insn	2, 0x1349
 76e:	0000                	.insn	2, 0x0000
 770:	160e                	.insn	2, 0x160e
 772:	4900                	.insn	2, 0x4900
 774:	3a250313          	addi	t1,a0,930
 778:	00053b0b          	.insn	4, 0x00053b0b
 77c:	0f00                	.insn	2, 0x0f00
 77e:	0035                	.insn	2, 0x0035
 780:	1349                	.insn	2, 0x1349
 782:	0000                	.insn	2, 0x0000
 784:	2e10                	.insn	2, 0x2e10
 786:	1101                	.insn	2, 0x1101
 788:	4006121b          	.insn	4, 0x4006121b
 78c:	7a18                	.insn	2, 0x7a18
 78e:	0319                	.insn	2, 0x0319
 790:	3a25                	.insn	2, 0x3a25
 792:	270b3b0b          	.insn	4, 0x270b3b0b
 796:	4919                	.insn	2, 0x4919
 798:	00193f13          	seqz	t5,s2
 79c:	1100                	.insn	2, 0x1100
 79e:	0005                	.insn	2, 0x0005
 7a0:	2202                	.insn	2, 0x2202
 7a2:	0b3a2503          	lw	a0,179(s4)
 7a6:	13490b3b          	.insn	4, 0x13490b3b
 7aa:	0000                	.insn	2, 0x0000
 7ac:	3412                	.insn	2, 0x3412
 7ae:	0200                	.insn	2, 0x0200
 7b0:	0322                	.insn	2, 0x0322
 7b2:	3a25                	.insn	2, 0x3a25
 7b4:	490b3b0b          	.insn	4, 0x490b3b0b
 7b8:	13000013          	li	zero,304
 7bc:	0048                	.insn	2, 0x0048
 7be:	1b7d137f 2e140000 	.insn	12, 0x3a2503012e1400001b7d137f
 7c6:	3a250301 
 7ca:	270b3b0b          	.insn	4, 0x270b3b0b
 7ce:	3c19                	.insn	2, 0x3c19
 7d0:	3f19                	.insn	2, 0x3f19
 7d2:	0019                	.insn	2, 0x0019
 7d4:	1500                	.insn	2, 0x1500
 7d6:	0018                	.insn	2, 0x0018
 7d8:	0000                	.insn	2, 0x0000
 7da:	2616                	.insn	2, 0x2616
 7dc:	4900                	.insn	2, 0x4900
 7de:	17000013          	li	zero,368
 7e2:	012e                	.insn	2, 0x012e
 7e4:	0b3a2503          	lw	a0,179(s4)
 7e8:	19270b3b          	.insn	4, 0x19270b3b
 7ec:	0b36                	.insn	2, 0x0b36
 7ee:	1349                	.insn	2, 0x1349
 7f0:	2120                	.insn	2, 0x2120
 7f2:	0001                	.insn	2, 0x0001
 7f4:	1800                	.insn	2, 0x1800
 7f6:	0005                	.insn	2, 0x0005
 7f8:	0b3a2503          	lw	a0,179(s4)
 7fc:	13490b3b          	.insn	4, 0x13490b3b
 800:	0000                	.insn	2, 0x0000
 802:	2e19                	.insn	2, 0x2e19
 804:	0301                	.insn	2, 0x0301
 806:	3a25                	.insn	2, 0x3a25
 808:	270b3b0b          	.insn	4, 0x270b3b0b
 80c:	4919                	.insn	2, 0x4919
 80e:	01212013          	slti	zero,sp,18
 812:	0000                	.insn	2, 0x0000
 814:	341a                	.insn	2, 0x341a
 816:	0300                	.insn	2, 0x0300
 818:	3a25                	.insn	2, 0x3a25
 81a:	490b3b0b          	.insn	4, 0x490b3b0b
 81e:	1b000013          	li	zero,432
 822:	011d                	.insn	2, 0x011d
 824:	1331                	.insn	2, 0x1331
 826:	1b11                	.insn	2, 0x1b11
 828:	0612                	.insn	2, 0x0612
 82a:	0b58                	.insn	2, 0x0b58
 82c:	0b59                	.insn	2, 0x0b59
 82e:	00000b57          	.insn	4, 0x0b57
 832:	051c                	.insn	2, 0x051c
 834:	0200                	.insn	2, 0x0200
 836:	3118                	.insn	2, 0x3118
 838:	1d000013          	li	zero,464
 83c:	0048                	.insn	2, 0x0048
 83e:	7d180183          	lb	gp,2001(a6)
 842:	1e00001b          	.insn	4, 0x1e00001b
 846:	012e                	.insn	2, 0x012e
 848:	1b11                	.insn	2, 0x1b11
 84a:	0612                	.insn	2, 0x0612
 84c:	1840                	.insn	2, 0x1840
 84e:	197a                	.insn	2, 0x197a
 850:	1331                	.insn	2, 0x1331
 852:	0000                	.insn	2, 0x0000
 854:	051f 3100 0013      	.insn	6, 0x00133100051f
 85a:	2000                	.insn	2, 0x2000
 85c:	0005                	.insn	2, 0x0005
 85e:	2202                	.insn	2, 0x2202
 860:	1331                	.insn	2, 0x1331
 862:	0000                	.insn	2, 0x0000
 864:	3421                	.insn	2, 0x3421
 866:	0200                	.insn	2, 0x0200
 868:	3122                	.insn	2, 0x3122
 86a:	22000013          	li	zero,544
 86e:	0034                	.insn	2, 0x0034
 870:	1331                	.insn	2, 0x1331
 872:	0000                	.insn	2, 0x0000
 874:	31011d23          	sh	a6,794(sp)
 878:	58235513          	.insn	4, 0x58235513
 87c:	5705590b          	.insn	4, 0x5705590b
 880:	2400000b          	.insn	4, 0x2400000b
 884:	012e                	.insn	2, 0x012e
 886:	0b3a2503          	lw	a0,179(s4)
 88a:	19270b3b          	.insn	4, 0x19270b3b
 88e:	1349                	.insn	2, 0x1349
 890:	2120193f 25000001 	.insn	8, 0x250000012120193f
 898:	012e                	.insn	2, 0x012e
 89a:	1b11                	.insn	2, 0x1b11
 89c:	0612                	.insn	2, 0x0612
 89e:	1840                	.insn	2, 0x1840
 8a0:	197a                	.insn	2, 0x197a
 8a2:	0b3a2503          	lw	a0,179(s4)
 8a6:	1927053b          	.insn	4, 0x1927053b
 8aa:	1349                	.insn	2, 0x1349
 8ac:	0000193f 02000526 	.insn	8, 0x020005260000193f
 8b4:	0322                	.insn	2, 0x0322
 8b6:	3a25                	.insn	2, 0x3a25
 8b8:	49053b0b          	.insn	4, 0x49053b0b
 8bc:	27000013          	li	zero,624
 8c0:	0034                	.insn	2, 0x0034
 8c2:	1802                	.insn	2, 0x1802
 8c4:	0b3a2503          	lw	a0,179(s4)
 8c8:	1349053b          	.insn	4, 0x1349053b
 8cc:	0000                	.insn	2, 0x0000
 8ce:	3428                	.insn	2, 0x3428
 8d0:	0200                	.insn	2, 0x0200
 8d2:	0322                	.insn	2, 0x0322
 8d4:	3a25                	.insn	2, 0x3a25
 8d6:	49053b0b          	.insn	4, 0x49053b0b
 8da:	29000013          	li	zero,656
 8de:	2355010b          	.insn	4, 0x2355010b
 8e2:	0000                	.insn	2, 0x0000
 8e4:	1d2a                	.insn	2, 0x1d2a
 8e6:	3100                	.insn	2, 0x3100
 8e8:	121b1113          	.insn	4, 0x121b1113
 8ec:	5806                	.insn	2, 0x5806
 8ee:	5705590b          	.insn	4, 0x5705590b
 8f2:	2b00000b          	.insn	4, 0x2b00000b
 8f6:	1b11010b          	.insn	4, 0x1b11010b
 8fa:	0612                	.insn	2, 0x0612
 8fc:	0000                	.insn	2, 0x0000
 8fe:	342c                	.insn	2, 0x342c
 900:	0300                	.insn	2, 0x0300
 902:	3a25                	.insn	2, 0x3a25
 904:	49053b0b          	.insn	4, 0x49053b0b
 908:	2d000013          	li	zero,720
 90c:	001d                	.insn	2, 0x001d
 90e:	1331                	.insn	2, 0x1331
 910:	2355                	.insn	2, 0x2355
 912:	0b58                	.insn	2, 0x0b58
 914:	0559                	.insn	2, 0x0559
 916:	00000b57          	.insn	4, 0x0b57
 91a:	1d2e                	.insn	2, 0x1d2e
 91c:	3101                	.insn	2, 0x3101
 91e:	121b1113          	.insn	4, 0x121b1113
 922:	5806                	.insn	2, 0x5806
 924:	5705590b          	.insn	4, 0x5705590b
 928:	2f00000b          	.insn	4, 0x2f00000b
 92c:	002e                	.insn	2, 0x002e
 92e:	0b3a2503          	lw	a0,179(s4)
 932:	1927053b          	.insn	4, 0x1927053b
 936:	1349                	.insn	2, 0x1349
 938:	2120                	.insn	2, 0x2120
 93a:	0001                	.insn	2, 0x0001
 93c:	3000                	.insn	2, 0x3000
 93e:	012e                	.insn	2, 0x012e
 940:	0b3a2503          	lw	a0,179(s4)
 944:	1927053b          	.insn	4, 0x1927053b
 948:	1349                	.insn	2, 0x1349
 94a:	2120                	.insn	2, 0x2120
 94c:	0001                	.insn	2, 0x0001
 94e:	3100                	.insn	2, 0x3100
 950:	0005                	.insn	2, 0x0005
 952:	0b3a2503          	lw	a0,179(s4)
 956:	1349053b          	.insn	4, 0x1349053b
 95a:	0000                	.insn	2, 0x0000
	...

Disassembly of section .debug_aranges:

00000000 <.debug_aranges>:
   0:	001c                	.insn	2, 0x001c
   2:	0000                	.insn	2, 0x0000
   4:	0002                	.insn	2, 0x0002
   6:	0000                	.insn	2, 0x0000
   8:	0000                	.insn	2, 0x0000
   a:	0004                	.insn	2, 0x0004
   c:	0000                	.insn	2, 0x0000
   e:	0000                	.insn	2, 0x0000
  10:	0000                	.insn	2, 0x0000
  12:	0010                	.insn	2, 0x0010
  14:	0014                	.insn	2, 0x0014
	...

Disassembly of section .debug_line:

00000000 <.debug_line>:
       0:	003e                	.insn	2, 0x003e
       2:	0000                	.insn	2, 0x0000
       4:	0005                	.insn	2, 0x0005
       6:	0004                	.insn	2, 0x0004
       8:	0025                	.insn	2, 0x0025
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
      20:	011f 0000 0000      	.insn	6, 0x011f
      26:	0102                	.insn	2, 0x0102
      28:	021f 010f 0035      	.insn	6, 0x0035010f021f
      2e:	0000                	.insn	2, 0x0000
      30:	0400                	.insn	2, 0x0400
      32:	0000                	.insn	2, 0x0000
      34:	0205                	.insn	2, 0x0205
      36:	0000                	.insn	2, 0x0000
      38:	0010                	.insn	2, 0x0010
      3a:	8315                	.insn	2, 0x8315
      3c:	0284                	.insn	2, 0x0284
      3e:	0004                	.insn	2, 0x0004
      40:	0101                	.insn	2, 0x0101
      42:	00000a03          	lb	s4,0(zero) # 0 <_start-0x100000>
      46:	0005                	.insn	2, 0x0005
      48:	0004                	.insn	2, 0x0004
      4a:	00000093          	li	ra,0
      4e:	0101                	.insn	2, 0x0101
      50:	fb01                	.insn	2, 0xfb01
      52:	0d0e                	.insn	2, 0x0d0e
      54:	0100                	.insn	2, 0x0100
      56:	0101                	.insn	2, 0x0101
      58:	0001                	.insn	2, 0x0001
      5a:	0000                	.insn	2, 0x0000
      5c:	0001                	.insn	2, 0x0001
      5e:	0100                	.insn	2, 0x0100
      60:	0101                	.insn	2, 0x0101
      62:	031f 0000 0000      	.insn	6, 0x031f
      68:	004e                	.insn	2, 0x004e
      6a:	0000                	.insn	2, 0x0000
      6c:	0054                	.insn	2, 0x0054
      6e:	0000                	.insn	2, 0x0000
      70:	021f0103          	lb	sp,33(t5) # 57012021 <_stack_top+0x56f06061>
      74:	051e050f          	.insn	4, 0x051e050f
      78:	007a                	.insn	2, 0x007a
      7a:	0000                	.insn	2, 0x0000
      7c:	a900                	.insn	2, 0xa900
      7e:	7768                	.insn	2, 0x7768
      80:	2dee                	.insn	2, 0x2dee
      82:	851c                	.insn	2, 0x851c
      84:	37fc                	.insn	2, 0x37fc
      86:	69c2                	.insn	2, 0x69c2
      88:	5751                	.insn	2, 0x5751
      8a:	b800                	.insn	2, 0xb800
      8c:	00007e63          	bgeu	zero,zero,a8 <_start-0xfff58>
      90:	0100                	.insn	2, 0x0100
      92:	68a9                	.insn	2, 0x68a9
      94:	1c2dee77          	.insn	4, 0x1c2dee77
      98:	fc85                	.insn	2, 0xfc85
      9a:	5169c237          	lui	tp,0x5169c
      9e:	63b80057          	.insn	4, 0x63b80057
      a2:	0091                	.insn	2, 0x0091
      a4:	0000                	.insn	2, 0x0000
      a6:	9201                	.insn	2, 0x9201
      a8:	a24e8183          	lb	gp,-1500(t4)
      ac:	e545                	.insn	2, 0xe545
      ae:	0c81                	.insn	2, 0x0c81
      b0:	e180                	.insn	2, 0xe180
      b2:	4ae1                	.insn	2, 0x4ae1
      b4:	96f6                	.insn	2, 0x96f6
      b6:	9a79                	.insn	2, 0x9a79
      b8:	0000                	.insn	2, 0x0000
      ba:	0100                	.insn	2, 0x0100
      bc:	cbe6                	.insn	2, 0xcbe6
      be:	9885                	.insn	2, 0x9885
      c0:	deba                	.insn	2, 0xdeba
      c2:	dbb9                	.insn	2, 0xdbb9
      c4:	a4a0dc77          	.insn	4, 0xa4a0dc77
      c8:	4520                	.insn	2, 0x4520
      ca:	00a75323          	.insn	4, 0x00a75323
      ce:	0000                	.insn	2, 0x0000
      d0:	a402                	.insn	2, 0xa402
      d2:	6a7a                	.insn	2, 0x6a7a
      d4:	7f6c                	.insn	2, 0x7f6c
      d6:	7627c6cb          	.insn	4, 0x7627c6cb
      da:	abe67d23          	.insn	4, 0xabe67d23
      de:	95ac                	.insn	2, 0x95ac
      e0:	0049                	.insn	2, 0x0049
      e2:	0205                	.insn	2, 0x0205
      e4:	0014                	.insn	2, 0x0014
      e6:	0010                	.insn	2, 0x0010
      e8:	04012b03          	lw	s6,64(sp)
      ec:	0502                	.insn	2, 0x0502
      ee:	0a0c                	.insn	2, 0x0a0c
      f0:	044a7503          	.insn	4, 0x044a7503
      f4:	0501                	.insn	2, 0x0501
      f6:	0300                	.insn	2, 0x0300
      f8:	4a0c                	.insn	2, 0x4a0c
      fa:	0505                	.insn	2, 0x0505
      fc:	4a06                	.insn	2, 0x4a06
      fe:	0905                	.insn	2, 0x0905
     100:	0306                	.insn	2, 0x0306
     102:	0901                	.insn	2, 0x0901
     104:	0004                	.insn	2, 0x0004
     106:	0401                	.insn	2, 0x0401
     108:	0502                	.insn	2, 0x0502
     10a:	031f 8270 0104      	.insn	6, 0x01048270031f
     110:	0105                	.insn	2, 0x0105
     112:	054a1403          	lh	s0,84(s4)
     116:	0300                	.insn	2, 0x0300
     118:	00040903          	lb	s2,0(s0) # 8c1776ec <_stack_top+0x8c06b72c>
     11c:	0401                	.insn	2, 0x0401
     11e:	0502                	.insn	2, 0x0502
     120:	0a0c                	.insn	2, 0x0a0c
     122:	044a6c03          	.insn	4, 0x044a6c03
     126:	0501                	.insn	2, 0x0501
     128:	0300                	.insn	2, 0x0300
     12a:	4a0c                	.insn	2, 0x4a0c
     12c:	0505                	.insn	2, 0x0505
     12e:	4a06                	.insn	2, 0x4a06
     130:	0905                	.insn	2, 0x0905
     132:	0306                	.insn	2, 0x0306
     134:	0901                	.insn	2, 0x0901
     136:	0004                	.insn	2, 0x0004
     138:	0401                	.insn	2, 0x0401
     13a:	0502                	.insn	2, 0x0502
     13c:	031f 8270 0104      	.insn	6, 0x01048270031f
     142:	0105                	.insn	2, 0x0105
     144:	054a1903          	lh	s2,84(s4)
     148:	0300                	.insn	2, 0x0300
     14a:	040901a3          	sb	zero,67(s2)
     14e:	0100                	.insn	2, 0x0100
     150:	0e05                	.insn	2, 0x0e05
     152:	080a                	.insn	2, 0x080a
     154:	4bad                	.insn	2, 0x4bad
     156:	0905                	.insn	2, 0x0905
     158:	087ed203          	lhu	tp,135(t4)
     15c:	0474                	.insn	2, 0x0474
     15e:	0502                	.insn	2, 0x0502
     160:	030c                	.insn	2, 0x030c
     162:	01044a73          	.insn	4, 0x01044a73
     166:	0005                	.insn	2, 0x0005
     168:	054a0c03          	lb	s8,84(s4)
     16c:	0605                	.insn	2, 0x0605
     16e:	054a                	.insn	2, 0x054a
     170:	0600                	.insn	2, 0x0600
     172:	04090f03          	lb	t5,64(s2)
     176:	0100                	.insn	2, 0x0100
     178:	0306                	.insn	2, 0x0306
     17a:	4a44                	.insn	2, 0x4a44
     17c:	0204                	.insn	2, 0x0204
     17e:	1f05                	.insn	2, 0x1f05
     180:	0306                	.insn	2, 0x0306
     182:	4a1e                	.insn	2, 0x4a1e
     184:	0104                	.insn	2, 0x0104
     186:	0c05                	.insn	2, 0x0c05
     188:	054a1d03          	lh	s10,84(s4)
     18c:	0605                	.insn	2, 0x0605
     18e:	034a                	.insn	2, 0x034a
     190:	0945                	.insn	2, 0x0945
     192:	0004                	.insn	2, 0x0004
     194:	0501                	.insn	2, 0x0501
     196:	0614                	.insn	2, 0x0614
     198:	8200f403          	.insn	4, 0x8200f403
     19c:	0505                	.insn	2, 0x0505
     19e:	05825603          	lhu	a2,88(tp) # 5169c058 <_stack_top+0x51590098>
     1a2:	4b09                	.insn	2, 0x4b09
     1a4:	0505                	.insn	2, 0x0505
     1a6:	0649                	.insn	2, 0x0649
     1a8:	097fb603          	.insn	4, 0x097fb603
     1ac:	0004                	.insn	2, 0x0004
     1ae:	0501                	.insn	2, 0x0501
     1b0:	0609                	.insn	2, 0x0609
     1b2:	74082e03          	lw	t3,1856(a6)
     1b6:	0204                	.insn	2, 0x0204
     1b8:	0c05                	.insn	2, 0x0c05
     1ba:	044a7303          	.insn	4, 0x044a7303
     1be:	0501                	.insn	2, 0x0501
     1c0:	0300                	.insn	2, 0x0300
     1c2:	4a0c                	.insn	2, 0x4a0c
     1c4:	0505                	.insn	2, 0x0505
     1c6:	4a06                	.insn	2, 0x4a06
     1c8:	0005                	.insn	2, 0x0005
     1ca:	0306                	.insn	2, 0x0306
     1cc:	0004090f          	.insn	4, 0x0004090f
     1d0:	0601                	.insn	2, 0x0601
     1d2:	044a4403          	lbu	s0,68(s4)
     1d6:	0502                	.insn	2, 0x0502
     1d8:	061f 1e03 044a      	.insn	6, 0x044a1e03061f
     1de:	0501                	.insn	2, 0x0501
     1e0:	030c                	.insn	2, 0x030c
     1e2:	4a1d                	.insn	2, 0x4a1d
     1e4:	0505                	.insn	2, 0x0505
     1e6:	4a06                	.insn	2, 0x4a06
     1e8:	04094503          	lbu	a0,64(s2)
     1ec:	0100                	.insn	2, 0x0100
     1ee:	1405                	.insn	2, 0x1405
     1f0:	0306                	.insn	2, 0x0306
     1f2:	00f9                	.insn	2, 0x00f9
     1f4:	054a                	.insn	2, 0x054a
     1f6:	0305                	.insn	2, 0x0305
     1f8:	8251                	.insn	2, 0x8251
     1fa:	0905                	.insn	2, 0x0905
     1fc:	4905054b          	.insn	4, 0x4905054b
     200:	0c05                	.insn	2, 0x0c05
     202:	04093403          	.insn	4, 0x04093403
     206:	0100                	.insn	2, 0x0100
     208:	1b05                	.insn	2, 0x1b05
     20a:	4a06                	.insn	2, 0x4a06
     20c:	0505                	.insn	2, 0x0505
     20e:	034a                	.insn	2, 0x034a
     210:	7f82                	.insn	2, 0x7f82
     212:	0409                	.insn	2, 0x0409
     214:	0100                	.insn	2, 0x0100
     216:	0306                	.insn	2, 0x0306
     218:	00ca                	.insn	2, 0x00ca
     21a:	05ba                	.insn	2, 0x05ba
     21c:	4b09                	.insn	2, 0x4b09
     21e:	0505                	.insn	2, 0x0505
     220:	0549                	.insn	2, 0x0549
     222:	030d                	.insn	2, 0x030d
     224:	0936                	.insn	2, 0x0936
     226:	0004                	.insn	2, 0x0004
     228:	0501                	.insn	2, 0x0501
     22a:	054a0617          	auipc	a2,0x54a0
     22e:	0605                	.insn	2, 0x0605
     230:	04095103          	lhu	sp,64(s2)
     234:	0100                	.insn	2, 0x0100
     236:	0c05                	.insn	2, 0x0c05
     238:	054a2d03          	lw	s10,84(s4)
     23c:	054a061b          	.insn	4, 0x054a061b
     240:	4a05                	.insn	2, 0x4a05
     242:	097f8203          	lb	tp,151(t6)
     246:	0004                	.insn	2, 0x0004
     248:	0601                	.insn	2, 0x0601
     24a:	4a00ca03          	lbu	s4,1184(ra)
     24e:	0905                	.insn	2, 0x0905
     250:	4905054b          	.insn	4, 0x4905054b
     254:	0905                	.insn	2, 0x0905
     256:	09019b03          	lh	s6,144(gp)
     25a:	0004                	.insn	2, 0x0004
     25c:	0601                	.insn	2, 0x0601
     25e:	097e9b03          	lh	s6,151(t4)
     262:	0014                	.insn	2, 0x0014
     264:	0601                	.insn	2, 0x0601
     266:	ac082e03          	lw	t3,-1344(a6)
     26a:	0204                	.insn	2, 0x0204
     26c:	0c05                	.insn	2, 0x0c05
     26e:	044a7303          	.insn	4, 0x044a7303
     272:	0501                	.insn	2, 0x0501
     274:	0300                	.insn	2, 0x0300
     276:	4a0c                	.insn	2, 0x4a0c
     278:	0505                	.insn	2, 0x0505
     27a:	4a06                	.insn	2, 0x4a06
     27c:	0005                	.insn	2, 0x0005
     27e:	0306                	.insn	2, 0x0306
     280:	0004090f          	.insn	4, 0x0004090f
     284:	0601                	.insn	2, 0x0601
     286:	044a4403          	lbu	s0,68(s4)
     28a:	0502                	.insn	2, 0x0502
     28c:	061f 1e03 044a      	.insn	6, 0x044a1e03061f
     292:	0501                	.insn	2, 0x0501
     294:	030c                	.insn	2, 0x030c
     296:	4a1d                	.insn	2, 0x4a1d
     298:	0505                	.insn	2, 0x0505
     29a:	4a06                	.insn	2, 0x4a06
     29c:	0905                	.insn	2, 0x0905
     29e:	0306                	.insn	2, 0x0306
     2a0:	01ac                	.insn	2, 0x01ac
     2a2:	0409                	.insn	2, 0x0409
     2a4:	0100                	.insn	2, 0x0100
     2a6:	064d                	.insn	2, 0x064d
     2a8:	097e9603          	lh	a2,151(t4)
     2ac:	001c                	.insn	2, 0x001c
     2ae:	0601                	.insn	2, 0x0601
     2b0:	ac082e03          	lw	t3,-1344(a6)
     2b4:	0204                	.insn	2, 0x0204
     2b6:	0c05                	.insn	2, 0x0c05
     2b8:	044a7303          	.insn	4, 0x044a7303
     2bc:	0501                	.insn	2, 0x0501
     2be:	0300                	.insn	2, 0x0300
     2c0:	4a0c                	.insn	2, 0x4a0c
     2c2:	0505                	.insn	2, 0x0505
     2c4:	4a06                	.insn	2, 0x4a06
     2c6:	0005                	.insn	2, 0x0005
     2c8:	0306                	.insn	2, 0x0306
     2ca:	0004090f          	.insn	4, 0x0004090f
     2ce:	0601                	.insn	2, 0x0601
     2d0:	044a4403          	lbu	s0,68(s4)
     2d4:	0502                	.insn	2, 0x0502
     2d6:	061f 1e03 044a      	.insn	6, 0x044a1e03061f
     2dc:	0501                	.insn	2, 0x0501
     2de:	030c                	.insn	2, 0x030c
     2e0:	4a1d                	.insn	2, 0x4a1d
     2e2:	0505                	.insn	2, 0x0505
     2e4:	4a06                	.insn	2, 0x4a06
     2e6:	0905                	.insn	2, 0x0905
     2e8:	0306                	.insn	2, 0x0306
     2ea:	01b1                	.insn	2, 0x01b1
     2ec:	0409                	.insn	2, 0x0409
     2ee:	0100                	.insn	2, 0x0100
     2f0:	0306                	.insn	2, 0x0306
     2f2:	7e94                	.insn	2, 0x7e94
     2f4:	064a                	.insn	2, 0x064a
     2f6:	ac082e03          	lw	t3,-1344(a6)
     2fa:	0204                	.insn	2, 0x0204
     2fc:	0c05                	.insn	2, 0x0c05
     2fe:	044a7303          	.insn	4, 0x044a7303
     302:	0501                	.insn	2, 0x0501
     304:	0300                	.insn	2, 0x0300
     306:	4a0c                	.insn	2, 0x4a0c
     308:	0505                	.insn	2, 0x0505
     30a:	4a06                	.insn	2, 0x4a06
     30c:	0005                	.insn	2, 0x0005
     30e:	0306                	.insn	2, 0x0306
     310:	0004090f          	.insn	4, 0x0004090f
     314:	0601                	.insn	2, 0x0601
     316:	044a4403          	lbu	s0,68(s4)
     31a:	0502                	.insn	2, 0x0502
     31c:	061f 1e03 044a      	.insn	6, 0x044a1e03061f
     322:	0501                	.insn	2, 0x0501
     324:	030c                	.insn	2, 0x030c
     326:	4a1d                	.insn	2, 0x4a1d
     328:	0505                	.insn	2, 0x0505
     32a:	4a06                	.insn	2, 0x4a06
     32c:	04094503          	lbu	a0,64(s2)
     330:	0100                	.insn	2, 0x0100
     332:	0905                	.insn	2, 0x0905
     334:	0306                	.insn	2, 0x0306
     336:	082e                	.insn	2, 0x082e
     338:	04ac                	.insn	2, 0x04ac
     33a:	0502                	.insn	2, 0x0502
     33c:	030c                	.insn	2, 0x030c
     33e:	01044a73          	.insn	4, 0x01044a73
     342:	0005                	.insn	2, 0x0005
     344:	034a0c03          	lb	s8,52(s4)
     348:	0008090f          	.insn	4, 0x0008090f
     34c:	0601                	.insn	2, 0x0601
     34e:	044a4403          	lbu	s0,68(s4)
     352:	0502                	.insn	2, 0x0502
     354:	061f 1e03 044a      	.insn	6, 0x044a1e03061f
     35a:	0501                	.insn	2, 0x0501
     35c:	030c                	.insn	2, 0x030c
     35e:	4a1d                	.insn	2, 0x4a1d
     360:	0905                	.insn	2, 0x0905
     362:	0901a703          	lw	a4,144(gp)
     366:	0008                	.insn	2, 0x0008
     368:	0301                	.insn	2, 0x0301
     36a:	4a0d                	.insn	2, 0x4a0d
     36c:	0306                	.insn	2, 0x0306
     36e:	7e91                	.insn	2, 0x7e91
     370:	2009                	.insn	2, 0x2009
     372:	0100                	.insn	2, 0x0100
     374:	0306                	.insn	2, 0x0306
     376:	082e                	.insn	2, 0x082e
     378:	04ac                	.insn	2, 0x04ac
     37a:	0502                	.insn	2, 0x0502
     37c:	030c                	.insn	2, 0x030c
     37e:	01044a73          	.insn	4, 0x01044a73
     382:	0005                	.insn	2, 0x0005
     384:	054a0c03          	lb	s8,84(s4)
     388:	0605                	.insn	2, 0x0605
     38a:	054a                	.insn	2, 0x054a
     38c:	0600                	.insn	2, 0x0600
     38e:	04090f03          	lb	t5,64(s2)
     392:	0100                	.insn	2, 0x0100
     394:	0306                	.insn	2, 0x0306
     396:	4a44                	.insn	2, 0x4a44
     398:	0204                	.insn	2, 0x0204
     39a:	1f05                	.insn	2, 0x1f05
     39c:	0306                	.insn	2, 0x0306
     39e:	4a1e                	.insn	2, 0x4a1e
     3a0:	0104                	.insn	2, 0x0104
     3a2:	0c05                	.insn	2, 0x0c05
     3a4:	054a1d03          	lh	s10,84(s4)
     3a8:	0605                	.insn	2, 0x0605
     3aa:	054a                	.insn	2, 0x054a
     3ac:	0609                	.insn	2, 0x0609
     3ae:	0901b603          	.insn	4, 0x0901b603
     3b2:	0004                	.insn	2, 0x0004
     3b4:	0501                	.insn	2, 0x0501
     3b6:	4d05                	.insn	2, 0x4d05
     3b8:	1205                	.insn	2, 0x1205
     3ba:	060505f3          	.insn	4, 0x060505f3
     3be:	064a                	.insn	2, 0x064a
     3c0:	053e0883          	lb	a7,83(t3) # 3012653 <_stack_top+0x2f06693>
     3c4:	f312                	.insn	2, 0xf312
     3c6:	0505                	.insn	2, 0x0505
     3c8:	4a06                	.insn	2, 0x4a06
     3ca:	8306                	.insn	2, 0x8306
     3cc:	f3bc                	.insn	2, 0xf3bc
     3ce:	1205bcf3          	csrrc	s9,scountinhibit,a1
     3d2:	060505f3          	.insn	4, 0x060505f3
     3d6:	064a                	.insn	2, 0x064a
     3d8:	1205bc83          	.insn	4, 0x1205bc83
     3dc:	060505f3          	.insn	4, 0x060505f3
     3e0:	064a                	.insn	2, 0x064a
     3e2:	1205bc83          	.insn	4, 0x1205bc83
     3e6:	060505f3          	.insn	4, 0x060505f3
     3ea:	064a                	.insn	2, 0x064a
     3ec:	1205bc83          	.insn	4, 0x1205bc83
     3f0:	060505f3          	.insn	4, 0x060505f3
     3f4:	064a                	.insn	2, 0x064a
     3f6:	ba480383          	lb	t2,-1116(a6)
     3fa:	054a3c03          	.insn	4, 0x054a3c03
     3fe:	0a0c                	.insn	2, 0x0a0c
     400:	097ea903          	lw	s2,151(t4)
     404:	0004                	.insn	2, 0x0004
     406:	0501                	.insn	2, 0x0501
     408:	0605                	.insn	2, 0x0605
     40a:	034a                	.insn	2, 0x034a
     40c:	0945                	.insn	2, 0x0945
     40e:	0004                	.insn	2, 0x0004
     410:	0501                	.insn	2, 0x0501
     412:	0609                	.insn	2, 0x0609
     414:	04822e03          	lw	t3,72(tp) # 48 <_start-0xfffb8>
     418:	0502                	.insn	2, 0x0502
     41a:	030c                	.insn	2, 0x030c
     41c:	01044a73          	.insn	4, 0x01044a73
     420:	0005                	.insn	2, 0x0005
     422:	054a0c03          	lb	s8,84(s4)
     426:	0605                	.insn	2, 0x0605
     428:	054a                	.insn	2, 0x054a
     42a:	0600                	.insn	2, 0x0600
     42c:	04090f03          	lb	t5,64(s2)
     430:	0100                	.insn	2, 0x0100
     432:	0204                	.insn	2, 0x0204
     434:	1f05                	.insn	2, 0x1f05
     436:	044a6203          	.insn	4, 0x044a6203
     43a:	0501                	.insn	2, 0x0501
     43c:	030c                	.insn	2, 0x030c
     43e:	4a1d                	.insn	2, 0x4a1d
     440:	0505                	.insn	2, 0x0505
     442:	4a06                	.insn	2, 0x4a06
     444:	0105                	.insn	2, 0x0105
     446:	0306                	.insn	2, 0x0306
     448:	00040903          	lb	s2,0(s0)
     44c:	0501                	.insn	2, 0x0501
     44e:	0300                	.insn	2, 0x0300
     450:	040900cf          	.insn	4, 0x040900cf
     454:	0100                	.insn	2, 0x0100
     456:	0505                	.insn	2, 0x0505
     458:	020a                	.insn	2, 0x020a
     45a:	1540                	.insn	2, 0x1540
     45c:	1805                	.insn	2, 0x1805
     45e:	4802                	.insn	2, 0x4802
     460:	03090513          	addi	a0,s2,48
     464:	7fba                	.insn	2, 0x7fba
     466:	054a                	.insn	2, 0x054a
     468:	00c90317          	auipc	t1,0xc90
     46c:	c802                	.insn	2, 0xc802
     46e:	0101                	.insn	2, 0x0101
     470:	1805                	.insn	2, 0x1805
     472:	054c                	.insn	2, 0x054c
     474:	0309                	.insn	2, 0x0309
     476:	7fb5                	.insn	2, 0x7fb5
     478:	054a                	.insn	2, 0x054a
     47a:	0311                	.insn	2, 0x0311
     47c:	00d0                	.insn	2, 0x00d0
     47e:	c802                	.insn	2, 0xc802
     480:	0101                	.insn	2, 0x0101
     482:	2005                	.insn	2, 0x2005
     484:	4a06                	.insn	2, 0x4a06
     486:	0905                	.insn	2, 0x0905
     488:	034a                	.insn	2, 0x034a
     48a:	7ee5                	.insn	2, 0x7ee5
     48c:	0409                	.insn	2, 0x0409
     48e:	0100                	.insn	2, 0x0100
     490:	1b05                	.insn	2, 0x1b05
     492:	0306                	.insn	2, 0x0306
     494:	019c                	.insn	2, 0x019c
     496:	054a                	.insn	2, 0x054a
     498:	0305                	.insn	2, 0x0305
     49a:	7fb5                	.insn	2, 0x7fb5
     49c:	0809                	.insn	2, 0x0809
     49e:	0100                	.insn	2, 0x0100
     4a0:	1105                	.insn	2, 0x1105
     4a2:	4a00ca03          	lbu	s4,1184(ra)
     4a6:	2005                	.insn	2, 0x2005
     4a8:	4a06                	.insn	2, 0x4a06
     4aa:	0905                	.insn	2, 0x0905
     4ac:	034a                	.insn	2, 0x034a
     4ae:	7ee5                	.insn	2, 0x7ee5
     4b0:	0409                	.insn	2, 0x0409
     4b2:	0100                	.insn	2, 0x0100
     4b4:	0306                	.insn	2, 0x0306
     4b6:	064a00cb          	.insn	4, 0x064a00cb
     4ba:	027fb503          	.insn	4, 0x027fb503
     4be:	0150                	.insn	2, 0x0150
     4c0:	2005                	.insn	2, 0x2005
     4c2:	0306                	.insn	2, 0x0306
     4c4:	01b6                	.insn	2, 0x01b6
     4c6:	054a                	.insn	2, 0x054a
     4c8:	060d                	.insn	2, 0x060d
     4ca:	054a                	.insn	2, 0x054a
     4cc:	72030623          	sb	zero,1836(t1) # c90b94 <_stack_top+0xb84bd4>
     4d0:	054a                	.insn	2, 0x054a
     4d2:	0314                	.insn	2, 0x0314
     4d4:	4a0e                	.insn	2, 0x4a0e
     4d6:	0905                	.insn	2, 0x0905
     4d8:	054a7203          	.insn	4, 0x054a7203
     4dc:	0314                	.insn	2, 0x0314
     4de:	00040903          	lb	s2,0(s0)
     4e2:	0501                	.insn	2, 0x0501
     4e4:	054a0623          	sb	s4,76(s4)
     4e8:	4a0d                	.insn	2, 0x4a0d
     4ea:	097ed503          	lhu	a0,151(t4)
     4ee:	0004                	.insn	2, 0x0004
     4f0:	0501                	.insn	2, 0x0501
     4f2:	061f ac03 4a01      	.insn	6, 0x4a01ac03061f
     4f8:	0505                	.insn	2, 0x0505
     4fa:	097fa503          	lw	a0,151(t6)
     4fe:	0008                	.insn	2, 0x0008
     500:	0501                	.insn	2, 0x0501
     502:	0314                	.insn	2, 0x0314
     504:	00da                	.insn	2, 0x00da
     506:	054a                	.insn	2, 0x054a
     508:	054a0623          	sb	s4,76(s4)
     50c:	4a0d                	.insn	2, 0x4a0d
     50e:	097ed503          	lhu	a0,151(t4)
     512:	0008                	.insn	2, 0x0008
     514:	0501                	.insn	2, 0x0501
     516:	d903061b          	.insn	4, 0xd903061b
     51a:	8200                	.insn	2, 0x8200
     51c:	1705                	.insn	2, 0x1705
     51e:	0549                	.insn	2, 0x0549
     520:	4b2c                	.insn	2, 0x4b2c
     522:	0d05                	.insn	2, 0x0d05
     524:	4a06                	.insn	2, 0x4a06
     526:	1505                	.insn	2, 0x1505
     528:	8506                	.insn	2, 0x8506
     52a:	0505                	.insn	2, 0x0505
     52c:	9c02                	.insn	2, 0x9c02
     52e:	0e01                	.insn	2, 0x0e01
     530:	1505                	.insn	2, 0x1505
     532:	04091003          	lh	zero,64(s2)
     536:	0100                	.insn	2, 0x0100
     538:	1805                	.insn	2, 0x1805
     53a:	4a00d503          	lhu	a0,1184(ra)
     53e:	2705                	.insn	2, 0x2705
     540:	4a7fae03          	lw	t3,1191(t6)
     544:	1805                	.insn	2, 0x1805
     546:	4a00d203          	lhu	tp,1184(ra)
     54a:	0306                	.insn	2, 0x0306
     54c:	08097ec3          	.insn	4, 0x08097ec3
     550:	0100                	.insn	2, 0x0100
     552:	0905                	.insn	2, 0x0905
     554:	0306                	.insn	2, 0x0306
     556:	ba2e                	.insn	2, 0xba2e
     558:	0204                	.insn	2, 0x0204
     55a:	0c05                	.insn	2, 0x0c05
     55c:	044a7303          	.insn	4, 0x044a7303
     560:	0501                	.insn	2, 0x0501
     562:	0300                	.insn	2, 0x0300
     564:	4a0c                	.insn	2, 0x4a0c
     566:	0505                	.insn	2, 0x0505
     568:	4a06                	.insn	2, 0x4a06
     56a:	0005                	.insn	2, 0x0005
     56c:	0306                	.insn	2, 0x0306
     56e:	0004090f          	.insn	4, 0x0004090f
     572:	0601                	.insn	2, 0x0601
     574:	044a4403          	lbu	s0,68(s4)
     578:	0502                	.insn	2, 0x0502
     57a:	061f 1e03 044a      	.insn	6, 0x044a1e03061f
     580:	0501                	.insn	2, 0x0501
     582:	030c                	.insn	2, 0x030c
     584:	4a1d                	.insn	2, 0x4a1d
     586:	0505                	.insn	2, 0x0505
     588:	4a06                	.insn	2, 0x4a06
     58a:	04094503          	lbu	a0,64(s2)
     58e:	0100                	.insn	2, 0x0100
     590:	2805                	.insn	2, 0x2805
     592:	0306                	.insn	2, 0x0306
     594:	058200c3          	.insn	4, 0x058200c3
     598:	0622                	.insn	2, 0x0622
     59a:	054a                	.insn	2, 0x054a
     59c:	4a15                	.insn	2, 0x4a15
     59e:	1105                	.insn	2, 0x1105
     5a0:	4b06                	.insn	2, 0x4b06
     5a2:	0306                	.insn	2, 0x0306
     5a4:	7fbc                	.insn	2, 0x7fbc
     5a6:	0409                	.insn	2, 0x0409
     5a8:	0100                	.insn	2, 0x0100
     5aa:	8200c403          	lbu	s0,-2016(ra)
     5ae:	0905                	.insn	2, 0x0905
     5b0:	0306                	.insn	2, 0x0306
     5b2:	826a                	.insn	2, 0x826a
     5b4:	0204                	.insn	2, 0x0204
     5b6:	0c05                	.insn	2, 0x0c05
     5b8:	044a7303          	.insn	4, 0x044a7303
     5bc:	0501                	.insn	2, 0x0501
     5be:	0300                	.insn	2, 0x0300
     5c0:	4a0c                	.insn	2, 0x4a0c
     5c2:	0505                	.insn	2, 0x0505
     5c4:	4a06                	.insn	2, 0x4a06
     5c6:	0204                	.insn	2, 0x0204
     5c8:	1f05                	.insn	2, 0x1f05
     5ca:	0306                	.insn	2, 0x0306
     5cc:	0971                	.insn	2, 0x0971
     5ce:	0004                	.insn	2, 0x0004
     5d0:	0401                	.insn	2, 0x0401
     5d2:	0501                	.insn	2, 0x0501
     5d4:	031e                	.insn	2, 0x031e
     5d6:	4a24                	.insn	2, 0x4a24
     5d8:	0505                	.insn	2, 0x0505
     5da:	4a06                	.insn	2, 0x4a06
     5dc:	0905                	.insn	2, 0x0905
     5de:	0306                	.insn	2, 0x0306
     5e0:	096c                	.insn	2, 0x096c
     5e2:	0008                	.insn	2, 0x0008
     5e4:	0401                	.insn	2, 0x0401
     5e6:	0502                	.insn	2, 0x0502
     5e8:	030c                	.insn	2, 0x030c
     5ea:	01044a73          	.insn	4, 0x01044a73
     5ee:	0005                	.insn	2, 0x0005
     5f0:	054a0c03          	lb	s8,84(s4)
     5f4:	0605                	.insn	2, 0x0605
     5f6:	044a                	.insn	2, 0x044a
     5f8:	0502                	.insn	2, 0x0502
     5fa:	061f 7103 0409      	.insn	6, 0x04097103061f
     600:	0100                	.insn	2, 0x0100
     602:	0c05                	.insn	2, 0x0c05
     604:	044d                	.insn	2, 0x044d
     606:	0501                	.insn	2, 0x0501
     608:	0300                	.insn	2, 0x0300
     60a:	4a0c                	.insn	2, 0x4a0c
     60c:	0505                	.insn	2, 0x0505
     60e:	4a06                	.insn	2, 0x4a06
     610:	0905                	.insn	2, 0x0905
     612:	0306                	.insn	2, 0x0306
     614:	0901                	.insn	2, 0x0901
     616:	0004                	.insn	2, 0x0004
     618:	0401                	.insn	2, 0x0401
     61a:	0502                	.insn	2, 0x0502
     61c:	031f 8270 0c05      	.insn	6, 0x0c058270031f
     622:	044d                	.insn	2, 0x044d
     624:	0501                	.insn	2, 0x0501
     626:	0300                	.insn	2, 0x0300
     628:	4a0c                	.insn	2, 0x4a0c
     62a:	0505                	.insn	2, 0x0505
     62c:	4a06                	.insn	2, 0x4a06
     62e:	0905                	.insn	2, 0x0905
     630:	0306                	.insn	2, 0x0306
     632:	0901                	.insn	2, 0x0901
     634:	0004                	.insn	2, 0x0004
     636:	0401                	.insn	2, 0x0401
     638:	0502                	.insn	2, 0x0502
     63a:	031f 8270 0c05      	.insn	6, 0x0c058270031f
     640:	044d                	.insn	2, 0x044d
     642:	0501                	.insn	2, 0x0501
     644:	0300                	.insn	2, 0x0300
     646:	4a0c                	.insn	2, 0x4a0c
     648:	0505                	.insn	2, 0x0505
     64a:	4a06                	.insn	2, 0x4a06
     64c:	0905                	.insn	2, 0x0905
     64e:	0306                	.insn	2, 0x0306
     650:	0901                	.insn	2, 0x0901
     652:	0004                	.insn	2, 0x0004
     654:	0401                	.insn	2, 0x0401
     656:	0502                	.insn	2, 0x0502
     658:	031f 8270 0306      	.insn	6, 0x03068270031f
     65e:	4a62                	.insn	2, 0x4a62
     660:	0104                	.insn	2, 0x0104
     662:	2805                	.insn	2, 0x2805
     664:	0306                	.insn	2, 0x0306
     666:	058200c3          	.insn	4, 0x058200c3
     66a:	0622                	.insn	2, 0x0622
     66c:	054a                	.insn	2, 0x054a
     66e:	4a15                	.insn	2, 0x4a15
     670:	1105                	.insn	2, 0x1105
     672:	4b06                	.insn	2, 0x4b06
     674:	0306                	.insn	2, 0x0306
     676:	7fbc                	.insn	2, 0x7fbc
     678:	0409                	.insn	2, 0x0409
     67a:	0100                	.insn	2, 0x0100
     67c:	8200c403          	lbu	s0,-2016(ra)
     680:	0905                	.insn	2, 0x0905
     682:	0306                	.insn	2, 0x0306
     684:	826a                	.insn	2, 0x826a
     686:	0204                	.insn	2, 0x0204
     688:	0c05                	.insn	2, 0x0c05
     68a:	044a7303          	.insn	4, 0x044a7303
     68e:	0501                	.insn	2, 0x0501
     690:	0300                	.insn	2, 0x0300
     692:	4a0c                	.insn	2, 0x4a0c
     694:	0505                	.insn	2, 0x0505
     696:	4a06                	.insn	2, 0x4a06
     698:	0204                	.insn	2, 0x0204
     69a:	1f05                	.insn	2, 0x1f05
     69c:	0306                	.insn	2, 0x0306
     69e:	0971                	.insn	2, 0x0971
     6a0:	0004                	.insn	2, 0x0004
     6a2:	0401                	.insn	2, 0x0401
     6a4:	0501                	.insn	2, 0x0501
     6a6:	031e                	.insn	2, 0x031e
     6a8:	4a24                	.insn	2, 0x4a24
     6aa:	0505                	.insn	2, 0x0505
     6ac:	4a06                	.insn	2, 0x4a06
     6ae:	0905                	.insn	2, 0x0905
     6b0:	0306                	.insn	2, 0x0306
     6b2:	096c                	.insn	2, 0x096c
     6b4:	0008                	.insn	2, 0x0008
     6b6:	0401                	.insn	2, 0x0401
     6b8:	0502                	.insn	2, 0x0502
     6ba:	030c                	.insn	2, 0x030c
     6bc:	01044a73          	.insn	4, 0x01044a73
     6c0:	0005                	.insn	2, 0x0005
     6c2:	054a0c03          	lb	s8,84(s4)
     6c6:	0605                	.insn	2, 0x0605
     6c8:	044a                	.insn	2, 0x044a
     6ca:	0502                	.insn	2, 0x0502
     6cc:	061f 7103 0409      	.insn	6, 0x04097103061f
     6d2:	0100                	.insn	2, 0x0100
     6d4:	0c05                	.insn	2, 0x0c05
     6d6:	044d                	.insn	2, 0x044d
     6d8:	0501                	.insn	2, 0x0501
     6da:	0300                	.insn	2, 0x0300
     6dc:	4a0c                	.insn	2, 0x4a0c
     6de:	0505                	.insn	2, 0x0505
     6e0:	4a06                	.insn	2, 0x4a06
     6e2:	0905                	.insn	2, 0x0905
     6e4:	0306                	.insn	2, 0x0306
     6e6:	0901                	.insn	2, 0x0901
     6e8:	0004                	.insn	2, 0x0004
     6ea:	0401                	.insn	2, 0x0401
     6ec:	0502                	.insn	2, 0x0502
     6ee:	031f 8270 0c05      	.insn	6, 0x0c058270031f
     6f4:	044d                	.insn	2, 0x044d
     6f6:	0501                	.insn	2, 0x0501
     6f8:	0300                	.insn	2, 0x0300
     6fa:	4a0c                	.insn	2, 0x4a0c
     6fc:	0505                	.insn	2, 0x0505
     6fe:	4a06                	.insn	2, 0x4a06
     700:	0905                	.insn	2, 0x0905
     702:	0306                	.insn	2, 0x0306
     704:	0901                	.insn	2, 0x0901
     706:	0004                	.insn	2, 0x0004
     708:	0401                	.insn	2, 0x0401
     70a:	0502                	.insn	2, 0x0502
     70c:	031f 8270 0c05      	.insn	6, 0x0c058270031f
     712:	044d                	.insn	2, 0x044d
     714:	0501                	.insn	2, 0x0501
     716:	0300                	.insn	2, 0x0300
     718:	4a0c                	.insn	2, 0x4a0c
     71a:	0505                	.insn	2, 0x0505
     71c:	4a06                	.insn	2, 0x4a06
     71e:	0905                	.insn	2, 0x0905
     720:	0306                	.insn	2, 0x0306
     722:	0901                	.insn	2, 0x0901
     724:	0004                	.insn	2, 0x0004
     726:	0401                	.insn	2, 0x0401
     728:	0502                	.insn	2, 0x0502
     72a:	031f 8270 0306      	.insn	6, 0x03068270031f
     730:	8262                	.insn	2, 0x8262
     732:	0104                	.insn	2, 0x0104
     734:	2805                	.insn	2, 0x2805
     736:	0306                	.insn	2, 0x0306
     738:	054a00c3          	.insn	4, 0x054a00c3
     73c:	0622                	.insn	2, 0x0622
     73e:	054a                	.insn	2, 0x054a
     740:	4a15                	.insn	2, 0x4a15
     742:	1105                	.insn	2, 0x1105
     744:	4b06                	.insn	2, 0x4b06
     746:	0306                	.insn	2, 0x0306
     748:	7fbc                	.insn	2, 0x7fbc
     74a:	0409                	.insn	2, 0x0409
     74c:	0100                	.insn	2, 0x0100
     74e:	8200c403          	lbu	s0,-2016(ra)
     752:	0905                	.insn	2, 0x0905
     754:	0306                	.insn	2, 0x0306
     756:	826a                	.insn	2, 0x826a
     758:	0204                	.insn	2, 0x0204
     75a:	0c05                	.insn	2, 0x0c05
     75c:	044a7303          	.insn	4, 0x044a7303
     760:	0501                	.insn	2, 0x0501
     762:	0300                	.insn	2, 0x0300
     764:	4a0c                	.insn	2, 0x4a0c
     766:	0505                	.insn	2, 0x0505
     768:	4a06                	.insn	2, 0x4a06
     76a:	0204                	.insn	2, 0x0204
     76c:	1f05                	.insn	2, 0x1f05
     76e:	0306                	.insn	2, 0x0306
     770:	0971                	.insn	2, 0x0971
     772:	0004                	.insn	2, 0x0004
     774:	0401                	.insn	2, 0x0401
     776:	0501                	.insn	2, 0x0501
     778:	031e                	.insn	2, 0x031e
     77a:	4a24                	.insn	2, 0x4a24
     77c:	0505                	.insn	2, 0x0505
     77e:	4a06                	.insn	2, 0x4a06
     780:	0905                	.insn	2, 0x0905
     782:	0306                	.insn	2, 0x0306
     784:	096c                	.insn	2, 0x096c
     786:	0008                	.insn	2, 0x0008
     788:	0401                	.insn	2, 0x0401
     78a:	0502                	.insn	2, 0x0502
     78c:	030c                	.insn	2, 0x030c
     78e:	01044a73          	.insn	4, 0x01044a73
     792:	0005                	.insn	2, 0x0005
     794:	054a0c03          	lb	s8,84(s4)
     798:	0605                	.insn	2, 0x0605
     79a:	044a                	.insn	2, 0x044a
     79c:	0502                	.insn	2, 0x0502
     79e:	061f 7103 0409      	.insn	6, 0x04097103061f
     7a4:	0100                	.insn	2, 0x0100
     7a6:	0104                	.insn	2, 0x0104
     7a8:	0505                	.insn	2, 0x0505
     7aa:	05822c03          	lw	s8,88(tp) # 58 <_start-0xfffa8>
     7ae:	4b09                	.insn	2, 0x4b09
     7b0:	0505                	.insn	2, 0x0505
     7b2:	0549                	.insn	2, 0x0549
     7b4:	033e                	.insn	2, 0x033e
     7b6:	00c6                	.insn	2, 0x00c6
     7b8:	0409                	.insn	2, 0x0409
     7ba:	0100                	.insn	2, 0x0100
     7bc:	0505                	.insn	2, 0x0505
     7be:	4a06                	.insn	2, 0x4a06
     7c0:	097ef003          	.insn	4, 0x097ef003
     7c4:	0004                	.insn	2, 0x0004
     7c6:	0501                	.insn	2, 0x0501
     7c8:	0609                	.insn	2, 0x0609
     7ca:	ac082e03          	lw	t3,-1344(a6)
     7ce:	0204                	.insn	2, 0x0204
     7d0:	0c05                	.insn	2, 0x0c05
     7d2:	044a7303          	.insn	4, 0x044a7303
     7d6:	0501                	.insn	2, 0x0501
     7d8:	0300                	.insn	2, 0x0300
     7da:	4a0c                	.insn	2, 0x4a0c
     7dc:	0505                	.insn	2, 0x0505
     7de:	4a06                	.insn	2, 0x4a06
     7e0:	0005                	.insn	2, 0x0005
     7e2:	0306                	.insn	2, 0x0306
     7e4:	0004090f          	.insn	4, 0x0004090f
     7e8:	0601                	.insn	2, 0x0601
     7ea:	044a4403          	lbu	s0,68(s4)
     7ee:	0502                	.insn	2, 0x0502
     7f0:	061f 1e03 044a      	.insn	6, 0x044a1e03061f
     7f6:	0501                	.insn	2, 0x0501
     7f8:	030c                	.insn	2, 0x030c
     7fa:	4a1d                	.insn	2, 0x4a1d
     7fc:	0505                	.insn	2, 0x0505
     7fe:	4a06                	.insn	2, 0x4a06
     800:	04094503          	lbu	a0,64(s2)
     804:	0100                	.insn	2, 0x0100
     806:	2805                	.insn	2, 0x2805
     808:	0306                	.insn	2, 0x0306
     80a:	05f200c3          	.insn	4, 0x05f200c3
     80e:	0622                	.insn	2, 0x0622
     810:	054a                	.insn	2, 0x054a
     812:	4a15                	.insn	2, 0x4a15
     814:	1105                	.insn	2, 0x1105
     816:	4b06                	.insn	2, 0x4b06
     818:	0306                	.insn	2, 0x0306
     81a:	7fbc                	.insn	2, 0x7fbc
     81c:	0409                	.insn	2, 0x0409
     81e:	0100                	.insn	2, 0x0100
     820:	8200c403          	lbu	s0,-2016(ra)
     824:	0905                	.insn	2, 0x0905
     826:	0306                	.insn	2, 0x0306
     828:	826a                	.insn	2, 0x826a
     82a:	0204                	.insn	2, 0x0204
     82c:	0c05                	.insn	2, 0x0c05
     82e:	044a7303          	.insn	4, 0x044a7303
     832:	0501                	.insn	2, 0x0501
     834:	0300                	.insn	2, 0x0300
     836:	4a0c                	.insn	2, 0x4a0c
     838:	0505                	.insn	2, 0x0505
     83a:	4a06                	.insn	2, 0x4a06
     83c:	0204                	.insn	2, 0x0204
     83e:	1f05                	.insn	2, 0x1f05
     840:	0306                	.insn	2, 0x0306
     842:	0971                	.insn	2, 0x0971
     844:	0004                	.insn	2, 0x0004
     846:	0401                	.insn	2, 0x0401
     848:	0501                	.insn	2, 0x0501
     84a:	031e                	.insn	2, 0x031e
     84c:	4a24                	.insn	2, 0x4a24
     84e:	0505                	.insn	2, 0x0505
     850:	4a06                	.insn	2, 0x4a06
     852:	097fbe03          	.insn	4, 0x097fbe03
     856:	0008                	.insn	2, 0x0008
     858:	0501                	.insn	2, 0x0501
     85a:	0609                	.insn	2, 0x0609
     85c:	ac082e03          	lw	t3,-1344(a6)
     860:	0204                	.insn	2, 0x0204
     862:	0c05                	.insn	2, 0x0c05
     864:	044a7303          	.insn	4, 0x044a7303
     868:	0501                	.insn	2, 0x0501
     86a:	0300                	.insn	2, 0x0300
     86c:	4a0c                	.insn	2, 0x4a0c
     86e:	0505                	.insn	2, 0x0505
     870:	4a06                	.insn	2, 0x4a06
     872:	0005                	.insn	2, 0x0005
     874:	0306                	.insn	2, 0x0306
     876:	0004090f          	.insn	4, 0x0004090f
     87a:	0601                	.insn	2, 0x0601
     87c:	044a4403          	lbu	s0,68(s4)
     880:	0502                	.insn	2, 0x0502
     882:	061f 1e03 044a      	.insn	6, 0x044a1e03061f
     888:	0501                	.insn	2, 0x0501
     88a:	030c                	.insn	2, 0x030c
     88c:	4a1d                	.insn	2, 0x4a1d
     88e:	0505                	.insn	2, 0x0505
     890:	4a06                	.insn	2, 0x4a06
     892:	04094503          	lbu	a0,64(s2)
     896:	0100                	.insn	2, 0x0100
     898:	2805                	.insn	2, 0x2805
     89a:	0306                	.insn	2, 0x0306
     89c:	05f200c3          	.insn	4, 0x05f200c3
     8a0:	0622                	.insn	2, 0x0622
     8a2:	054a                	.insn	2, 0x054a
     8a4:	4a15                	.insn	2, 0x4a15
     8a6:	1105                	.insn	2, 0x1105
     8a8:	4b06                	.insn	2, 0x4b06
     8aa:	0306                	.insn	2, 0x0306
     8ac:	7fbc                	.insn	2, 0x7fbc
     8ae:	0409                	.insn	2, 0x0409
     8b0:	0100                	.insn	2, 0x0100
     8b2:	8200c403          	lbu	s0,-2016(ra)
     8b6:	0905                	.insn	2, 0x0905
     8b8:	0306                	.insn	2, 0x0306
     8ba:	826a                	.insn	2, 0x826a
     8bc:	0204                	.insn	2, 0x0204
     8be:	0c05                	.insn	2, 0x0c05
     8c0:	044a7303          	.insn	4, 0x044a7303
     8c4:	0501                	.insn	2, 0x0501
     8c6:	0300                	.insn	2, 0x0300
     8c8:	4a0c                	.insn	2, 0x4a0c
     8ca:	0505                	.insn	2, 0x0505
     8cc:	4a06                	.insn	2, 0x4a06
     8ce:	0204                	.insn	2, 0x0204
     8d0:	1f05                	.insn	2, 0x1f05
     8d2:	0306                	.insn	2, 0x0306
     8d4:	0971                	.insn	2, 0x0971
     8d6:	0004                	.insn	2, 0x0004
     8d8:	0401                	.insn	2, 0x0401
     8da:	0501                	.insn	2, 0x0501
     8dc:	031e                	.insn	2, 0x031e
     8de:	4a24                	.insn	2, 0x4a24
     8e0:	0505                	.insn	2, 0x0505
     8e2:	4a06                	.insn	2, 0x4a06
     8e4:	0905                	.insn	2, 0x0905
     8e6:	0306                	.insn	2, 0x0306
     8e8:	096c                	.insn	2, 0x096c
     8ea:	0008                	.insn	2, 0x0008
     8ec:	0401                	.insn	2, 0x0401
     8ee:	0502                	.insn	2, 0x0502
     8f0:	030c                	.insn	2, 0x030c
     8f2:	01044a73          	.insn	4, 0x01044a73
     8f6:	2f05                	.insn	2, 0x2f05
     8f8:	054a0c03          	lb	s8,84(s4)
     8fc:	0605                	.insn	2, 0x0605
     8fe:	034a                	.insn	2, 0x034a
     900:	00080953          	.insn	4, 0x00080953
     904:	0501                	.insn	2, 0x0501
     906:	0609                	.insn	2, 0x0609
     908:	ac082e03          	lw	t3,-1344(a6)
     90c:	0204                	.insn	2, 0x0204
     90e:	0c05                	.insn	2, 0x0c05
     910:	044a7303          	.insn	4, 0x044a7303
     914:	0501                	.insn	2, 0x0501
     916:	0300                	.insn	2, 0x0300
     918:	4a0c                	.insn	2, 0x4a0c
     91a:	0505                	.insn	2, 0x0505
     91c:	4a06                	.insn	2, 0x4a06
     91e:	0005                	.insn	2, 0x0005
     920:	0306                	.insn	2, 0x0306
     922:	0004090f          	.insn	4, 0x0004090f
     926:	0601                	.insn	2, 0x0601
     928:	044a4403          	lbu	s0,68(s4)
     92c:	0502                	.insn	2, 0x0502
     92e:	061f 1e03 044a      	.insn	6, 0x044a1e03061f
     934:	0501                	.insn	2, 0x0501
     936:	030c                	.insn	2, 0x030c
     938:	4a1d                	.insn	2, 0x4a1d
     93a:	0505                	.insn	2, 0x0505
     93c:	4a06                	.insn	2, 0x4a06
     93e:	04094503          	lbu	a0,64(s2)
     942:	0100                	.insn	2, 0x0100
     944:	2805                	.insn	2, 0x2805
     946:	0306                	.insn	2, 0x0306
     948:	05f200c3          	.insn	4, 0x05f200c3
     94c:	0622                	.insn	2, 0x0622
     94e:	054a                	.insn	2, 0x054a
     950:	4a15                	.insn	2, 0x4a15
     952:	1105                	.insn	2, 0x1105
     954:	4b06                	.insn	2, 0x4b06
     956:	0306                	.insn	2, 0x0306
     958:	7fbc                	.insn	2, 0x7fbc
     95a:	0409                	.insn	2, 0x0409
     95c:	0100                	.insn	2, 0x0100
     95e:	8200c403          	lbu	s0,-2016(ra)
     962:	0905                	.insn	2, 0x0905
     964:	0306                	.insn	2, 0x0306
     966:	826a                	.insn	2, 0x826a
     968:	0204                	.insn	2, 0x0204
     96a:	0c05                	.insn	2, 0x0c05
     96c:	044a7303          	.insn	4, 0x044a7303
     970:	0501                	.insn	2, 0x0501
     972:	0300                	.insn	2, 0x0300
     974:	4a0c                	.insn	2, 0x4a0c
     976:	0505                	.insn	2, 0x0505
     978:	4a06                	.insn	2, 0x4a06
     97a:	0204                	.insn	2, 0x0204
     97c:	1f05                	.insn	2, 0x1f05
     97e:	0306                	.insn	2, 0x0306
     980:	0971                	.insn	2, 0x0971
     982:	0004                	.insn	2, 0x0004
     984:	0401                	.insn	2, 0x0401
     986:	0501                	.insn	2, 0x0501
     988:	031e                	.insn	2, 0x031e
     98a:	4a24                	.insn	2, 0x4a24
     98c:	0505                	.insn	2, 0x0505
     98e:	4a06                	.insn	2, 0x4a06
     990:	0905                	.insn	2, 0x0905
     992:	0306                	.insn	2, 0x0306
     994:	096c                	.insn	2, 0x096c
     996:	0008                	.insn	2, 0x0008
     998:	0401                	.insn	2, 0x0401
     99a:	0502                	.insn	2, 0x0502
     99c:	030c                	.insn	2, 0x030c
     99e:	01044a73          	.insn	4, 0x01044a73
     9a2:	2f05                	.insn	2, 0x2f05
     9a4:	054a0c03          	lb	s8,84(s4)
     9a8:	0605                	.insn	2, 0x0605
     9aa:	034a                	.insn	2, 0x034a
     9ac:	00040953          	.insn	4, 0x00040953
     9b0:	0401                	.insn	2, 0x0401
     9b2:	0502                	.insn	2, 0x0502
     9b4:	061f 1e03 0482      	.insn	6, 0x04821e03061f
     9ba:	0501                	.insn	2, 0x0501
     9bc:	0b01                	.insn	2, 0x0b01
     9be:	8201b303          	.insn	4, 0x8201b303
     9c2:	0905                	.insn	2, 0x0905
     9c4:	027edd03          	lhu	s10,39(t4)
     9c8:	0138                	.insn	2, 0x0138
     9ca:	0204                	.insn	2, 0x0204
     9cc:	0c05                	.insn	2, 0x0c05
     9ce:	044a7303          	.insn	4, 0x044a7303
     9d2:	0501                	.insn	2, 0x0501
     9d4:	0300                	.insn	2, 0x0300
     9d6:	4a0c                	.insn	2, 0x4a0c
     9d8:	0505                	.insn	2, 0x0505
     9da:	4a06                	.insn	2, 0x4a06
     9dc:	08095303          	lhu	t1,128(s2)
     9e0:	0100                	.insn	2, 0x0100
     9e2:	1805                	.insn	2, 0x1805
     9e4:	0306                	.insn	2, 0x0306
     9e6:	01bd                	.insn	2, 0x01bd
     9e8:	054a                	.insn	2, 0x054a
     9ea:	0300                	.insn	2, 0x0300
     9ec:	7f84                	.insn	2, 0x7f84
     9ee:	0409                	.insn	2, 0x0409
     9f0:	0100                	.insn	2, 0x0100
     9f2:	2805                	.insn	2, 0x2805
     9f4:	f40a                	.insn	2, 0xf40a
     9f6:	2205                	.insn	2, 0x2205
     9f8:	4a06                	.insn	2, 0x4a06
     9fa:	1505                	.insn	2, 0x1505
     9fc:	054a                	.insn	2, 0x054a
     9fe:	0611                	.insn	2, 0x0611
     a00:	bc03064b          	.insn	4, 0xbc03064b
     a04:	097f 0004 0301 00c4 	.insn	10, 0x058200c403010004097f
     a0c:	0582 
     a0e:	0609                	.insn	2, 0x0609
     a10:	04826a03          	.insn	4, 0x04826a03
     a14:	0502                	.insn	2, 0x0502
     a16:	030c                	.insn	2, 0x030c
     a18:	01044a73          	.insn	4, 0x01044a73
     a1c:	0005                	.insn	2, 0x0005
     a1e:	054a0c03          	lb	s8,84(s4)
     a22:	0605                	.insn	2, 0x0605
     a24:	044a                	.insn	2, 0x044a
     a26:	0502                	.insn	2, 0x0502
     a28:	061f 7103 0409      	.insn	6, 0x04097103061f
     a2e:	0100                	.insn	2, 0x0100
     a30:	0104                	.insn	2, 0x0104
     a32:	1e05                	.insn	2, 0x1e05
     a34:	054a2403          	lw	s0,84(s4)
     a38:	0605                	.insn	2, 0x0605
     a3a:	054a                	.insn	2, 0x054a
     a3c:	0601                	.insn	2, 0x0601
     a3e:	04090403          	lb	s0,64(s2)
     a42:	0100                	.insn	2, 0x0100
     a44:	0402                	.insn	2, 0x0402
     a46:	0100                	.insn	2, 0x0100
     a48:	5801                	.insn	2, 0x5801
     a4a:	0006                	.insn	2, 0x0006
     a4c:	0500                	.insn	2, 0x0500
     a4e:	0400                	.insn	2, 0x0400
     a50:	6500                	.insn	2, 0x6500
     a52:	0000                	.insn	2, 0x0000
     a54:	0100                	.insn	2, 0x0100
     a56:	0101                	.insn	2, 0x0101
     a58:	000d0efb          	.insn	4, 0x000d0efb
     a5c:	0101                	.insn	2, 0x0101
     a5e:	0101                	.insn	2, 0x0101
     a60:	0000                	.insn	2, 0x0000
     a62:	0100                	.insn	2, 0x0100
     a64:	0000                	.insn	2, 0x0000
     a66:	0101                	.insn	2, 0x0101
     a68:	1f01                	.insn	2, 0x1f01
     a6a:	0002                	.insn	2, 0x0002
     a6c:	0000                	.insn	2, 0x0000
     a6e:	4e00                	.insn	2, 0x4e00
     a70:	0000                	.insn	2, 0x0000
     a72:	0300                	.insn	2, 0x0300
     a74:	1f01                	.insn	2, 0x1f01
     a76:	0f02                	.insn	2, 0x0f02
     a78:	1e05                	.insn	2, 0x1e05
     a7a:	0000b003          	.insn	4, 0xb003
     a7e:	0000                	.insn	2, 0x0000
     a80:	a840                	.insn	2, 0xa840
     a82:	44da                	.insn	2, 0x44da
     a84:	b466                	.insn	2, 0xb466
     a86:	63e1                	.insn	2, 0x63e1
     a88:	12838677          	.insn	4, 0x12838677
     a8c:	7005                	.insn	2, 0x7005
     a8e:	00b40257          	.insn	4, 0x00b40257
     a92:	0000                	.insn	2, 0x0000
     a94:	4001                	.insn	2, 0x4001
     a96:	daa8                	.insn	2, 0xdaa8
     a98:	6644                	.insn	2, 0x6644
     a9a:	e1b4                	.insn	2, 0xe1b4
     a9c:	83867763          	bgeu	a2,s8,fffffaca <_stack_top+0xffef3b0a>
     aa0:	0512                	.insn	2, 0x0512
     aa2:	5770                	.insn	2, 0x5770
     aa4:	9102                	.insn	2, 0x9102
     aa6:	0000                	.insn	2, 0x0000
     aa8:	0100                	.insn	2, 0x0100
     aaa:	8392                	.insn	2, 0x8392
     aac:	4e81                	.insn	2, 0x4e81
     aae:	45a2                	.insn	2, 0x45a2
     ab0:	81e5                	.insn	2, 0x81e5
     ab2:	800c                	.insn	2, 0x800c
     ab4:	e1e1                	.insn	2, 0xe1e1
     ab6:	f64a                	.insn	2, 0xf64a
     ab8:	7996                	.insn	2, 0x7996
     aba:	0505                	.insn	2, 0x0505
     abc:	000a                	.insn	2, 0x000a
     abe:	0205                	.insn	2, 0x0205
     ac0:	0c94                	.insn	2, 0x0c94
     ac2:	0010                	.insn	2, 0x0010
     ac4:	7a030617          	auipc	a2,0x7a030
     ac8:	0809                	.insn	2, 0x0809
     aca:	0100                	.insn	2, 0x0100
     acc:	1005                	.insn	2, 0x1005
     ace:	5106                	.insn	2, 0x5106
     ad0:	1205                	.insn	2, 0x1205
     ad2:	4a06                	.insn	2, 0x4a06
     ad4:	0b05                	.insn	2, 0x0b05
     ad6:	054a                	.insn	2, 0x054a
     ad8:	4a0e                	.insn	2, 0x4a0e
     ada:	0505                	.insn	2, 0x0505
     adc:	8106                	.insn	2, 0x8106
     ade:	04090203          	lb	tp,64(s2)
     ae2:	0100                	.insn	2, 0x0100
     ae4:	030a                	.insn	2, 0x030a
     ae6:	0908                	.insn	2, 0x0908
     ae8:	0004                	.insn	2, 0x0004
     aea:	0501                	.insn	2, 0x0501
     aec:	030d                	.insn	2, 0x030d
     aee:	0901                	.insn	2, 0x0901
     af0:	0004                	.insn	2, 0x0004
     af2:	0501                	.insn	2, 0x0501
     af4:	0614                	.insn	2, 0x0614
     af6:	054a                	.insn	2, 0x054a
     af8:	4a11                	.insn	2, 0x4a11
     afa:	0d05                	.insn	2, 0x0d05
     afc:	0306                	.insn	2, 0x0306
     afe:	097f 0004 0501 4d0b 	.insn	10, 0x054b4d0b05010004097f
     b06:	054b 
     b08:	4605                	.insn	2, 0x4605
     b0a:	0306                	.insn	2, 0x0306
     b0c:	0970                	.insn	2, 0x0970
     b0e:	0004                	.insn	2, 0x0004
     b10:	0501                	.insn	2, 0x0501
     b12:	0601                	.insn	2, 0x0601
     b14:	054a1803          	lh	a6,84(s4)
     b18:	031d                	.insn	2, 0x031d
     b1a:	4a7a                	.insn	2, 0x4a7a
     b1c:	0105                	.insn	2, 0x0105
     b1e:	0550                	.insn	2, 0x0550
     b20:	0a05                	.insn	2, 0x0a05
     b22:	04090503          	lb	a0,64(s2)
     b26:	0100                	.insn	2, 0x0100
     b28:	0306                	.insn	2, 0x0306
     b2a:	00080963          	beqz	a6,b3c <_start-0xff4c4>
     b2e:	0501                	.insn	2, 0x0501
     b30:	1e03060b          	.insn	4, 0x1e03060b
     b34:	054a                	.insn	2, 0x054a
     b36:	060e                	.insn	2, 0x060e
     b38:	054a                	.insn	2, 0x054a
     b3a:	0605                	.insn	2, 0x0605
     b3c:	0381                	.insn	2, 0x0381
     b3e:	0902                	.insn	2, 0x0902
     b40:	0004                	.insn	2, 0x0004
     b42:	0501                	.insn	2, 0x0501
     b44:	0300                	.insn	2, 0x0300
     b46:	00c9                	.insn	2, 0x00c9
     b48:	0409                	.insn	2, 0x0409
     b4a:	0100                	.insn	2, 0x0100
     b4c:	0b05                	.insn	2, 0x0b05
     b4e:	080a                	.insn	2, 0x080a
     b50:	0341                	.insn	2, 0x0341
     b52:	00040907          	.insn	4, 0x00040907
     b56:	0501                	.insn	2, 0x0501
     b58:	0309                	.insn	2, 0x0309
     b5a:	0901                	.insn	2, 0x0901
     b5c:	0004                	.insn	2, 0x0004
     b5e:	0601                	.insn	2, 0x0601
     b60:	8b034a0b          	.insn	4, 0x8b034a0b
     b64:	087f 06ac ee03 4a00 	.insn	10, 0x22054a00ee0306ac087f
     b6c:	2205 
     b6e:	910306bb          	.insn	4, 0x910306bb
     b72:	4a7f 1005 0306 00dc 	.insn	18, 0x4b060f054a061c05e40800dc030610054a7f
     b7a:	e408 1c05 4a06 0f05 
     b82:	4b06 
     b84:	1e05                	.insn	2, 0x1e05
     b86:	0548                	.insn	2, 0x0548
     b88:	4b22                	.insn	2, 0x4b22
     b8a:	1605                	.insn	2, 0x1605
     b8c:	4a06                	.insn	2, 0x4a06
     b8e:	0f05                	.insn	2, 0x0f05
     b90:	4b06                	.insn	2, 0x4b06
     b92:	0505                	.insn	2, 0x0505
     b94:	7208                	.insn	2, 0x7208
     b96:	1605                	.insn	2, 0x1605
     b98:	04092103          	lw	sp,64(s2)
     b9c:	0100                	.insn	2, 0x0100
     b9e:	1005                	.insn	2, 0x1005
     ba0:	4a06                	.insn	2, 0x4a06
     ba2:	0905                	.insn	2, 0x0905
     ba4:	054a                	.insn	2, 0x054a
     ba6:	4a14                	.insn	2, 0x4a14
     ba8:	0505                	.insn	2, 0x0505
     baa:	7f06                	.insn	2, 0x7f06
     bac:	0306                	.insn	2, 0x0306
     bae:	04097f87          	.insn	4, 0x04097f87
     bb2:	0100                	.insn	2, 0x0100
     bb4:	1605                	.insn	2, 0x1605
     bb6:	0306                	.insn	2, 0x0306
     bb8:	0180                	.insn	2, 0x0180
     bba:	0582                	.insn	2, 0x0582
     bbc:	0609                	.insn	2, 0x0609
     bbe:	0582                	.insn	2, 0x0582
     bc0:	0610                	.insn	2, 0x0610
     bc2:	0581                	.insn	2, 0x0581
     bc4:	0605                	.insn	2, 0x0605
     bc6:	0582                	.insn	2, 0x0582
     bc8:	0601                	.insn	2, 0x0601
     bca:	0903030b          	.insn	4, 0x0903030b
     bce:	0004                	.insn	2, 0x0004
     bd0:	0501                	.insn	2, 0x0501
     bd2:	0300                	.insn	2, 0x0300
     bd4:	0905                	.insn	2, 0x0905
     bd6:	0018                	.insn	2, 0x0018
     bd8:	0501                	.insn	2, 0x0501
     bda:	0a05                	.insn	2, 0x0a05
     bdc:	7c02                	.insn	2, 0x7c02
     bde:	0514                	.insn	2, 0x0514
     be0:	080d                	.insn	2, 0x080d
     be2:	0541                	.insn	2, 0x0541
     be4:	030c                	.insn	2, 0x030c
     be6:	093c                	.insn	2, 0x093c
     be8:	0004                	.insn	2, 0x0004
     bea:	0301                	.insn	2, 0x0301
     bec:	4a41                	.insn	2, 0x4a41
     bee:	0505                	.insn	2, 0x0505
     bf0:	4a06                	.insn	2, 0x4a06
     bf2:	0005                	.insn	2, 0x0005
     bf4:	097ef503          	.insn	4, 0x097ef503
     bf8:	0008                	.insn	2, 0x0008
     bfa:	0501                	.insn	2, 0x0501
     bfc:	060c                	.insn	2, 0x060c
     bfe:	8201ca03          	lbu	s4,-2016(gp)
     c02:	0505                	.insn	2, 0x0505
     c04:	054a4103          	lbu	sp,84(s4)
     c08:	4d15                	.insn	2, 0x4d15
     c0a:	1005                	.insn	2, 0x1005
     c0c:	0549                	.insn	2, 0x0549
     c0e:	4b0d                	.insn	2, 0x4b0d
     c10:	2105                	.insn	2, 0x2105
     c12:	10091003          	lh	zero,256(s2)
     c16:	0100                	.insn	2, 0x0100
     c18:	1f05                	.insn	2, 0x1f05
     c1a:	05f5                	.insn	2, 0x05f5
     c1c:	090d031b          	.insn	4, 0x090d031b
     c20:	0004                	.insn	2, 0x0004
     c22:	0501                	.insn	2, 0x0501
     c24:	0319                	.insn	2, 0x0319
     c26:	0901                	.insn	2, 0x0901
     c28:	0004                	.insn	2, 0x0004
     c2a:	0501                	.insn	2, 0x0501
     c2c:	030c                	.insn	2, 0x030c
     c2e:	0505ba1b          	.insn	4, 0x0505ba1b
     c32:	054a4103          	lbu	sp,84(s4)
     c36:	4d0d                	.insn	2, 0x4d0d
     c38:	2605                	.insn	2, 0x2605
     c3a:	08093103          	.insn	4, 0x08093103
     c3e:	0100                	.insn	2, 0x0100
     c40:	3205                	.insn	2, 0x3205
     c42:	05f4                	.insn	2, 0x05f4
     c44:	4b26                	.insn	2, 0x4b26
     c46:	1905                	.insn	2, 0x1905
     c48:	8206                	.insn	2, 0x8206
     c4a:	3e05                	.insn	2, 0x3e05
     c4c:	8106                	.insn	2, 0x8106
     c4e:	2605                	.insn	2, 0x2605
     c50:	06190583          	lb	a1,97(s2)
     c54:	0582                	.insn	2, 0x0582
     c56:	063e                	.insn	2, 0x063e
     c58:	0581                	.insn	2, 0x0581
     c5a:	8326                	.insn	2, 0x8326
     c5c:	1905                	.insn	2, 0x1905
     c5e:	8206                	.insn	2, 0x8206
     c60:	3e05                	.insn	2, 0x3e05
     c62:	8106                	.insn	2, 0x8106
     c64:	2605                	.insn	2, 0x2605
     c66:	06190583          	lb	a1,97(s2)
     c6a:	0582                	.insn	2, 0x0582
     c6c:	063e                	.insn	2, 0x063e
     c6e:	0581                	.insn	2, 0x0581
     c70:	8326                	.insn	2, 0x8326
     c72:	1905                	.insn	2, 0x1905
     c74:	8206                	.insn	2, 0x8206
     c76:	3e05                	.insn	2, 0x3e05
     c78:	8106                	.insn	2, 0x8106
     c7a:	2605                	.insn	2, 0x2605
     c7c:	06190583          	lb	a1,97(s2)
     c80:	0582                	.insn	2, 0x0582
     c82:	063e                	.insn	2, 0x063e
     c84:	0581                	.insn	2, 0x0581
     c86:	8326                	.insn	2, 0x8326
     c88:	1905                	.insn	2, 0x1905
     c8a:	8206                	.insn	2, 0x8206
     c8c:	3e05                	.insn	2, 0x3e05
     c8e:	8106                	.insn	2, 0x8106
     c90:	2605                	.insn	2, 0x2605
     c92:	0600054b          	.insn	4, 0x0600054b
     c96:	827ebe03          	.insn	4, 0x827ebe03
     c9a:	0c05                	.insn	2, 0x0c05
     c9c:	0306                	.insn	2, 0x0306
     c9e:	01ca                	.insn	2, 0x01ca
     ca0:	0582                	.insn	2, 0x0582
     ca2:	0305                	.insn	2, 0x0305
     ca4:	4a41                	.insn	2, 0x4a41
     ca6:	1505                	.insn	2, 0x1505
     ca8:	0552                	.insn	2, 0x0552
     caa:	0600                	.insn	2, 0x0600
     cac:	4a7eed03          	.insn	4, 0x4a7eed03
     cb0:	0c05                	.insn	2, 0x0c05
     cb2:	0306                	.insn	2, 0x0306
     cb4:	01ca                	.insn	2, 0x01ca
     cb6:	0582                	.insn	2, 0x0582
     cb8:	0305                	.insn	2, 0x0305
     cba:	4a41                	.insn	2, 0x4a41
     cbc:	2505                	.insn	2, 0x2505
     cbe:	054a0b03          	lb	s6,84(s4)
     cc2:	f31c                	.insn	2, 0xf31c
     cc4:	1505                	.insn	2, 0x1505
     cc6:	4a06                	.insn	2, 0x4a06
     cc8:	1905                	.insn	2, 0x1905
     cca:	0306                	.insn	2, 0x0306
     ccc:	0901                	.insn	2, 0x0901
     cce:	0008                	.insn	2, 0x0008
     cd0:	0501                	.insn	2, 0x0501
     cd2:	b91c                	.insn	2, 0xb91c
     cd4:	1505                	.insn	2, 0x1505
     cd6:	4a06                	.insn	2, 0x4a06
     cd8:	1905                	.insn	2, 0x1905
     cda:	0306                	.insn	2, 0x0306
     cdc:	000c090b          	.insn	4, 0x000c090b
     ce0:	0501                	.insn	2, 0x0501
     ce2:	bc3a                	.insn	2, 0xbc3a
     ce4:	0306                	.insn	2, 0x0306
     ce6:	7edc                	.insn	2, 0x7edc
     ce8:	054a                	.insn	2, 0x054a
     cea:	b503061b          	.insn	4, 0xb503061b
     cee:	ba01                	.insn	2, 0xba01
     cf0:	1e05                	.insn	2, 0x1e05
     cf2:	0549                	.insn	2, 0x0549
     cf4:	2d054b1b          	.insn	4, 0x2d054b1b
     cf8:	0549                	.insn	2, 0x0549
     cfa:	0624                	.insn	2, 0x0624
     cfc:	05f2                	.insn	2, 0x05f2
     cfe:	4a22                	.insn	2, 0x4a22
     d00:	1505                	.insn	2, 0x1505
     d02:	8106                	.insn	2, 0x8106
     d04:	2605                	.insn	2, 0x2605
     d06:	04090703          	lb	a4,64(s2)
     d0a:	0100                	.insn	2, 0x0100
     d0c:	1905                	.insn	2, 0x1905
     d0e:	8206                	.insn	2, 0x8206
     d10:	1e05                	.insn	2, 0x1e05
     d12:	8106                	.insn	2, 0x8106
     d14:	1505                	.insn	2, 0x1505
     d16:	8206                	.insn	2, 0x8206
     d18:	0306                	.insn	2, 0x0306
     d1a:	00080957          	.insn	4, 0x00080957
     d1e:	0501                	.insn	2, 0x0501
     d20:	0b01                	.insn	2, 0x0b01
     d22:	05ba3f03          	.insn	4, 0x05ba3f03
     d26:	0a05                	.insn	2, 0x0a05
     d28:	3c091b03          	lh	s6,960(s2)
     d2c:	0100                	.insn	2, 0x0100
     d2e:	0c05                	.insn	2, 0x0c05
     d30:	0806                	.insn	2, 0x0806
     d32:	053c                	.insn	2, 0x053c
     d34:	4a16                	.insn	2, 0x4a16
     d36:	097e9603          	lh	a2,151(t4)
     d3a:	0008                	.insn	2, 0x0008
     d3c:	0301                	.insn	2, 0x0301
     d3e:	01ea                	.insn	2, 0x01ea
     d40:	054a                	.insn	2, 0x054a
     d42:	0619                	.insn	2, 0x0619
     d44:	04090303          	lb	t1,64(s2)
     d48:	0100                	.insn	2, 0x0100
     d4a:	2505                	.insn	2, 0x2505
     d4c:	4a06                	.insn	2, 0x4a06
     d4e:	0a05                	.insn	2, 0x0a05
     d50:	0306                	.insn	2, 0x0306
     d52:	0901                	.insn	2, 0x0901
     d54:	000c                	.insn	2, 0x000c
     d56:	0501                	.insn	2, 0x0501
     d58:	0609                	.insn	2, 0x0609
     d5a:	054a                	.insn	2, 0x054a
     d5c:	060a                	.insn	2, 0x060a
     d5e:	08090003          	lb	zero,128(s2)
     d62:	0100                	.insn	2, 0x0100
     d64:	0905                	.insn	2, 0x0905
     d66:	4a06                	.insn	2, 0x4a06
     d68:	097e9203          	lh	tp,151(t4)
     d6c:	0004                	.insn	2, 0x0004
     d6e:	0501                	.insn	2, 0x0501
     d70:	0601                	.insn	2, 0x0601
     d72:	4a01fb03          	.insn	4, 0x4a01fb03
     d76:	0306                	.insn	2, 0x0306
     d78:	7e85                	.insn	2, 0x7e85
     d7a:	054a                	.insn	2, 0x054a
     d7c:	0616                	.insn	2, 0x0616
     d7e:	ba01f303          	.insn	4, 0xba01f303
     d82:	0306                	.insn	2, 0x0306
     d84:	7e8d                	.insn	2, 0x7e8d
     d86:	3c08                	.insn	2, 0x3c08
     d88:	0c05                	.insn	2, 0x0c05
     d8a:	0306                	.insn	2, 0x0306
     d8c:	01f0                	.insn	2, 0x01f0
     d8e:	0582                	.insn	2, 0x0582
     d90:	5110                	.insn	2, 0x5110
     d92:	1605                	.insn	2, 0x1605
     d94:	4a06                	.insn	2, 0x4a06
     d96:	0505                	.insn	2, 0x0505
     d98:	0306                	.insn	2, 0x0306
     d9a:	4a79                	.insn	2, 0x4a79
     d9c:	1605                	.insn	2, 0x1605
     d9e:	08090303          	lb	t1,128(s2)
     da2:	0100                	.insn	2, 0x0100
     da4:	1b05                	.insn	2, 0x1b05
     da6:	08090103          	lb	sp,128(s2)
     daa:	0100                	.insn	2, 0x0100
     dac:	0306                	.insn	2, 0x0306
     dae:	7e8c                	.insn	2, 0x7e8c
     db0:	0809                	.insn	2, 0x0809
     db2:	0100                	.insn	2, 0x0100
     db4:	4a01f403          	.insn	4, 0x4a01f403
     db8:	4b06                	.insn	2, 0x4b06
     dba:	0306                	.insn	2, 0x0306
     dbc:	08097e8b          	.insn	4, 0x08097e8b
     dc0:	0100                	.insn	2, 0x0100
     dc2:	0a05                	.insn	2, 0x0a05
     dc4:	0306                	.insn	2, 0x0306
     dc6:	01f9                	.insn	2, 0x01f9
     dc8:	05ba                	.insn	2, 0x05ba
     dca:	4c01                	.insn	2, 0x4c01
     dcc:	0505                	.insn	2, 0x0505
     dce:	030a                	.insn	2, 0x030a
     dd0:	0004090b          	.insn	4, 0x0004090b
     dd4:	0601                	.insn	2, 0x0601
     dd6:	097dfa03          	.insn	4, 0x097dfa03
     dda:	0040                	.insn	2, 0x0040
     ddc:	0501                	.insn	2, 0x0501
     dde:	0609                	.insn	2, 0x0609
     de0:	0202a103          	lw	sp,32(t0) # da11b88 <_stack_top+0xd905bc8>
     de4:	0124                	.insn	2, 0x0124
     de6:	bc0d05bb          	.insn	4, 0xbc0d05bb
     dea:	0505                	.insn	2, 0x0505
     dec:	054a6203          	.insn	4, 0x054a6203
     df0:	0330                	.insn	2, 0x0330
     df2:	0904                	.insn	2, 0x0904
     df4:	0004                	.insn	2, 0x0004
     df6:	0501                	.insn	2, 0x0501
     df8:	031a                	.insn	2, 0x031a
     dfa:	4a55                	.insn	2, 0x4a55
     dfc:	1605                	.insn	2, 0x1605
     dfe:	054c                	.insn	2, 0x054c
     e00:	031c                	.insn	2, 0x031c
     e02:	8226                	.insn	2, 0x8226
     e04:	0905                	.insn	2, 0x0905
     e06:	054a5a03          	lhu	s4,84(s4)
     e0a:	16058017          	auipc	zero,0x16058
     e0e:	0584                	.insn	2, 0x0584
     e10:	0609                	.insn	2, 0x0609
     e12:	0582                	.insn	2, 0x0582
     e14:	05800617          	auipc	a2,0x5800
     e18:	8416                	.insn	2, 0x8416
     e1a:	0905                	.insn	2, 0x0905
     e1c:	8206                	.insn	2, 0x8206
     e1e:	1705                	.insn	2, 0x1705
     e20:	8006                	.insn	2, 0x8006
     e22:	1605                	.insn	2, 0x1605
     e24:	0584                	.insn	2, 0x0584
     e26:	0609                	.insn	2, 0x0609
     e28:	0582                	.insn	2, 0x0582
     e2a:	05800617          	auipc	a2,0x5800
     e2e:	8416                	.insn	2, 0x8416
     e30:	0905                	.insn	2, 0x0905
     e32:	8206                	.insn	2, 0x8206
     e34:	1705                	.insn	2, 0x1705
     e36:	8006                	.insn	2, 0x8006
     e38:	1605                	.insn	2, 0x1605
     e3a:	0584                	.insn	2, 0x0584
     e3c:	0609                	.insn	2, 0x0609
     e3e:	0582                	.insn	2, 0x0582
     e40:	05800617          	auipc	a2,0x5800
     e44:	8416                	.insn	2, 0x8416
     e46:	0905                	.insn	2, 0x0905
     e48:	8206                	.insn	2, 0x8206
     e4a:	1705                	.insn	2, 0x1705
     e4c:	8006                	.insn	2, 0x8006
     e4e:	1605                	.insn	2, 0x1605
     e50:	054c                	.insn	2, 0x054c
     e52:	0609                	.insn	2, 0x0609
     e54:	0682                	.insn	2, 0x0682
     e56:	06822a03          	lw	s4,104(tp) # 68 <_start-0xfff98>
     e5a:	f27df503          	.insn	4, 0xf27df503
     e5e:	2505                	.insn	2, 0x2505
     e60:	0306                	.insn	2, 0x0306
     e62:	028e                	.insn	2, 0x028e
     e64:	05ba                	.insn	2, 0x05ba
     e66:	0609                	.insn	2, 0x0609
     e68:	034a                	.insn	2, 0x034a
     e6a:	7df2                	.insn	2, 0x7df2
     e6c:	0409                	.insn	2, 0x0409
     e6e:	0100                	.insn	2, 0x0100
     e70:	1c05                	.insn	2, 0x1c05
     e72:	0306                	.insn	2, 0x0306
     e74:	0290                	.insn	2, 0x0290
     e76:	0409                	.insn	2, 0x0409
     e78:	0100                	.insn	2, 0x0100
     e7a:	1805                	.insn	2, 0x1805
     e7c:	05824803          	lbu	a6,88(tp) # 58 <_start-0xfffa8>
     e80:	0612                	.insn	2, 0x0612
     e82:	054a                	.insn	2, 0x054a
     e84:	8205                	.insn	2, 0x8205
     e86:	1805                	.insn	2, 0x1805
     e88:	8306                	.insn	2, 0x8306
     e8a:	1205                	.insn	2, 0x1205
     e8c:	4a06                	.insn	2, 0x4a06
     e8e:	0d05                	.insn	2, 0x0d05
     e90:	0306                	.insn	2, 0x0306
     e92:	8238                	.insn	2, 0x8238
     e94:	1105                	.insn	2, 0x1105
     e96:	054c                	.insn	2, 0x054c
     e98:	0600                	.insn	2, 0x0600
     e9a:	f27ded03          	.insn	4, 0xf27ded03
     e9e:	0d05                	.insn	2, 0x0d05
     ea0:	0306                	.insn	2, 0x0306
     ea2:	0296                	.insn	2, 0x0296
     ea4:	05ba                	.insn	2, 0x05ba
     ea6:	1905bb13          	sltiu	s6,a1,400
     eaa:	0306                	.insn	2, 0x0306
     eac:	0900                	.insn	2, 0x0900
     eae:	0004                	.insn	2, 0x0004
     eb0:	0301                	.insn	2, 0x0301
     eb2:	7de9                	.insn	2, 0x7de9
     eb4:	05ba                	.insn	2, 0x05ba
     eb6:	87030617          	auipc	a2,0x87030
     eba:	8202                	.insn	2, 0x8202
     ebc:	0306                	.insn	2, 0x0306
     ebe:	7df9                	.insn	2, 0x7df9
     ec0:	0409                	.insn	2, 0x0409
     ec2:	0100                	.insn	2, 0x0100
     ec4:	0905                	.insn	2, 0x0905
     ec6:	0306                	.insn	2, 0x0306
     ec8:	bb4a029b          	.insn	4, 0xbb4a029b
     ecc:	030d05bb          	.insn	4, 0x030d05bb
     ed0:	0902                	.insn	2, 0x0902
     ed2:	0010                	.insn	2, 0x0010
     ed4:	0501                	.insn	2, 0x0501
     ed6:	b81e                	.insn	2, 0xb81e
     ed8:	1905                	.insn	2, 0x1905
     eda:	08090103          	lb	sp,128(s2)
     ede:	0100                	.insn	2, 0x0100
     ee0:	2505                	.insn	2, 0x2505
     ee2:	e103064b          	.insn	4, 0xe103064b
     ee6:	097d                	.insn	2, 0x097d
     ee8:	000c                	.insn	2, 0x000c
     eea:	0501                	.insn	2, 0x0501
     eec:	0601                	.insn	2, 0x0601
     eee:	0202a603          	lw	a2,32(t0)
     ef2:	0140                	.insn	2, 0x0140
     ef4:	0005                	.insn	2, 0x0005
     ef6:	04090203          	lb	tp,64(s2)
     efa:	0100                	.insn	2, 0x0100
     efc:	1305                	.insn	2, 0x1305
     efe:	fa0a                	.insn	2, 0xfa0a
     f00:	1e05                	.insn	2, 0x1e05
     f02:	0306                	.insn	2, 0x0306
     f04:	0900                	.insn	2, 0x0900
     f06:	0008                	.insn	2, 0x0008
     f08:	0501                	.insn	2, 0x0501
     f0a:	4a26                	.insn	2, 0x4a26
     f0c:	2905                	.insn	2, 0x2905
     f0e:	04090003          	lb	zero,64(s2)
     f12:	0100                	.insn	2, 0x0100
     f14:	2605                	.insn	2, 0x2605
     f16:	054a                	.insn	2, 0x054a
     f18:	0605                	.insn	2, 0x0605
     f1a:	097fba03          	.insn	4, 0x097fba03
     f1e:	0004                	.insn	2, 0x0004
     f20:	0501                	.insn	2, 0x0501
     f22:	060c                	.insn	2, 0x060c
     f24:	05f2                	.insn	2, 0x05f2
     f26:	4a05                	.insn	2, 0x4a05
     f28:	1605                	.insn	2, 0x1605
     f2a:	034a                	.insn	2, 0x034a
     f2c:	7e96                	.insn	2, 0x7e96
     f2e:	0809                	.insn	2, 0x0809
     f30:	0100                	.insn	2, 0x0100
     f32:	4a01ea03          	.insn	4, 0x4a01ea03
     f36:	1905                	.insn	2, 0x1905
     f38:	0306                	.insn	2, 0x0306
     f3a:	00040903          	lb	s2,0(s0)
     f3e:	0501                	.insn	2, 0x0501
     f40:	0625                	.insn	2, 0x0625
     f42:	054a                	.insn	2, 0x054a
     f44:	060a                	.insn	2, 0x060a
     f46:	0c090103          	lb	sp,192(s2)
     f4a:	0100                	.insn	2, 0x0100
     f4c:	0905                	.insn	2, 0x0905
     f4e:	4a06                	.insn	2, 0x4a06
     f50:	097e9203          	lh	tp,151(t4)
     f54:	0008                	.insn	2, 0x0008
     f56:	0501                	.insn	2, 0x0501
     f58:	061e                	.insn	2, 0x061e
     f5a:	0902b803          	.insn	4, 0x0902b803
     f5e:	0014                	.insn	2, 0x0014
     f60:	0501                	.insn	2, 0x0501
     f62:	0629                	.insn	2, 0x0629
     f64:	08090003          	lb	zero,128(s2)
     f68:	0100                	.insn	2, 0x0100
     f6a:	4a7dc803          	lbu	a6,1191(s11)
     f6e:	0505                	.insn	2, 0x0505
     f70:	0306                	.insn	2, 0x0306
     f72:	01ea                	.insn	2, 0x01ea
     f74:	0409                	.insn	2, 0x0409
     f76:	0100                	.insn	2, 0x0100
     f78:	0306                	.insn	2, 0x0306
     f7a:	7e96                	.insn	2, 0x7e96
     f7c:	0582                	.insn	2, 0x0582
     f7e:	060c                	.insn	2, 0x060c
     f80:	8201ea03          	.insn	4, 0x8201ea03
     f84:	0505                	.insn	2, 0x0505
     f86:	4a06                	.insn	2, 0x4a06
     f88:	4a7e9603          	lh	a2,1191(t4)
     f8c:	1605                	.insn	2, 0x1605
     f8e:	0306                	.insn	2, 0x0306
     f90:	01ea                	.insn	2, 0x01ea
     f92:	0c09                	.insn	2, 0x0c09
     f94:	0100                	.insn	2, 0x0100
     f96:	1905                	.insn	2, 0x1905
     f98:	04090303          	lb	t1,64(s2)
     f9c:	0100                	.insn	2, 0x0100
     f9e:	2505                	.insn	2, 0x2505
     fa0:	4a06                	.insn	2, 0x4a06
     fa2:	0a05                	.insn	2, 0x0a05
     fa4:	0306                	.insn	2, 0x0306
     fa6:	0901                	.insn	2, 0x0901
     fa8:	000c                	.insn	2, 0x000c
     faa:	0501                	.insn	2, 0x0501
     fac:	0609                	.insn	2, 0x0609
     fae:	054a                	.insn	2, 0x054a
     fb0:	060a                	.insn	2, 0x060a
     fb2:	08090003          	lb	zero,128(s2)
     fb6:	0100                	.insn	2, 0x0100
     fb8:	0905                	.insn	2, 0x0905
     fba:	4a06                	.insn	2, 0x4a06
     fbc:	0d05                	.insn	2, 0x0d05
     fbe:	0306                	.insn	2, 0x0306
     fc0:	00c5                	.insn	2, 0x00c5
     fc2:	0409                	.insn	2, 0x0409
     fc4:	0100                	.insn	2, 0x0100
     fc6:	0a05                	.insn	2, 0x0a05
     fc8:	ba7fbb03          	.insn	4, 0xba7fbb03
     fcc:	0905                	.insn	2, 0x0905
     fce:	4a06                	.insn	2, 0x4a06
     fd0:	0d05                	.insn	2, 0x0d05
     fd2:	0306                	.insn	2, 0x0306
     fd4:	00cd                	.insn	2, 0x00cd
     fd6:	0409                	.insn	2, 0x0409
     fd8:	0100                	.insn	2, 0x0100
     fda:	0005                	.insn	2, 0x0005
     fdc:	0b06                	.insn	2, 0x0b06
     fde:	827dc503          	lbu	a0,-2009(s11)
     fe2:	1605                	.insn	2, 0x1605
     fe4:	0306                	.insn	2, 0x0306
     fe6:	e40801f3          	.insn	4, 0xe40801f3
     fea:	0306                	.insn	2, 0x0306
     fec:	7e8d                	.insn	2, 0x7e8d
     fee:	3c08                	.insn	2, 0x3c08
     ff0:	0c05                	.insn	2, 0x0c05
     ff2:	0306                	.insn	2, 0x0306
     ff4:	01f0                	.insn	2, 0x01f0
     ff6:	0582                	.insn	2, 0x0582
     ff8:	5110                	.insn	2, 0x5110
     ffa:	1605                	.insn	2, 0x1605
     ffc:	4a06                	.insn	2, 0x4a06
     ffe:	0505                	.insn	2, 0x0505
    1000:	0306                	.insn	2, 0x0306
    1002:	4a79                	.insn	2, 0x4a79
    1004:	1605                	.insn	2, 0x1605
    1006:	08090303          	lb	t1,128(s2)
    100a:	0100                	.insn	2, 0x0100
    100c:	1b05                	.insn	2, 0x1b05
    100e:	08090103          	lb	sp,128(s2)
    1012:	0100                	.insn	2, 0x0100
    1014:	0306                	.insn	2, 0x0306
    1016:	7e8c                	.insn	2, 0x7e8c
    1018:	0809                	.insn	2, 0x0809
    101a:	0100                	.insn	2, 0x0100
    101c:	4a01f403          	.insn	4, 0x4a01f403
    1020:	4b06                	.insn	2, 0x4b06
    1022:	0306                	.insn	2, 0x0306
    1024:	08097e8b          	.insn	4, 0x08097e8b
    1028:	0100                	.insn	2, 0x0100
    102a:	1605                	.insn	2, 0x1605
    102c:	0306                	.insn	2, 0x0306
    102e:	3c0801f3          	.insn	4, 0x3c0801f3
    1032:	0306                	.insn	2, 0x0306
    1034:	7e8d                	.insn	2, 0x7e8d
    1036:	3c08                	.insn	2, 0x3c08
    1038:	0c05                	.insn	2, 0x0c05
    103a:	0306                	.insn	2, 0x0306
    103c:	01f0                	.insn	2, 0x01f0
    103e:	0582                	.insn	2, 0x0582
    1040:	5110                	.insn	2, 0x5110
    1042:	1605                	.insn	2, 0x1605
    1044:	4a06                	.insn	2, 0x4a06
    1046:	0505                	.insn	2, 0x0505
    1048:	0306                	.insn	2, 0x0306
    104a:	4a79                	.insn	2, 0x4a79
    104c:	1605                	.insn	2, 0x1605
    104e:	08090303          	lb	t1,128(s2)
    1052:	0100                	.insn	2, 0x0100
    1054:	1b05                	.insn	2, 0x1b05
    1056:	08090103          	lb	sp,128(s2)
    105a:	0100                	.insn	2, 0x0100
    105c:	0306                	.insn	2, 0x0306
    105e:	7e8c                	.insn	2, 0x7e8c
    1060:	0809                	.insn	2, 0x0809
    1062:	0100                	.insn	2, 0x0100
    1064:	4a01f403          	.insn	4, 0x4a01f403
    1068:	4b06                	.insn	2, 0x4b06
    106a:	0306                	.insn	2, 0x0306
    106c:	08097e8b          	.insn	4, 0x08097e8b
    1070:	0100                	.insn	2, 0x0100
    1072:	0d05                	.insn	2, 0x0d05
    1074:	0306                	.insn	2, 0x0306
    1076:	02c1                	.insn	2, 0x02c1
    1078:	0682                	.insn	2, 0x0682
    107a:	097dbf03          	.insn	4, 0x097dbf03
    107e:	0004                	.insn	2, 0x0004
    1080:	0501                	.insn	2, 0x0501
    1082:	0614                	.insn	2, 0x0614
    1084:	ba02c303          	lbu	t1,-1120(t0)
    1088:	0905                	.insn	2, 0x0905
    108a:	04090103          	lb	sp,64(s2)
    108e:	0100                	.insn	2, 0x0100
    1090:	0306                	.insn	2, 0x0306
    1092:	7dbc                	.insn	2, 0x7dbc
    1094:	7408                	.insn	2, 0x7408
    1096:	0505                	.insn	2, 0x0505
    1098:	0306                	.insn	2, 0x0306
    109a:	02c9                	.insn	2, 0x02c9
    109c:	064a                	.insn	2, 0x064a
    109e:	1402ba0b          	.insn	4, 0x1402ba0b
    10a2:	0100                	.insn	2, 0x0100
    10a4:	c901                	.insn	2, 0xc901
    10a6:	0004                	.insn	2, 0x0004
    10a8:	0500                	.insn	2, 0x0500
    10aa:	0400                	.insn	2, 0x0400
    10ac:	7a00                	.insn	2, 0x7a00
    10ae:	0000                	.insn	2, 0x0000
    10b0:	0100                	.insn	2, 0x0100
    10b2:	0101                	.insn	2, 0x0101
    10b4:	000d0efb          	.insn	4, 0x000d0efb
    10b8:	0101                	.insn	2, 0x0101
    10ba:	0101                	.insn	2, 0x0101
    10bc:	0000                	.insn	2, 0x0000
    10be:	0100                	.insn	2, 0x0100
    10c0:	0000                	.insn	2, 0x0000
    10c2:	0101                	.insn	2, 0x0101
    10c4:	1f01                	.insn	2, 0x1f01
    10c6:	0002                	.insn	2, 0x0002
    10c8:	0000                	.insn	2, 0x0000
    10ca:	4e00                	.insn	2, 0x4e00
    10cc:	0000                	.insn	2, 0x0000
    10ce:	0300                	.insn	2, 0x0300
    10d0:	1f01                	.insn	2, 0x1f01
    10d2:	0f02                	.insn	2, 0x0f02
    10d4:	1e05                	.insn	2, 0x1e05
    10d6:	bd04                	.insn	2, 0xbd04
    10d8:	0000                	.insn	2, 0x0000
    10da:	0000                	.insn	2, 0x0000
    10dc:	10c6                	.insn	2, 0x10c6
    10de:	1718                	.insn	2, 0x1718
    10e0:	b0f4                	.insn	2, 0xb0f4
    10e2:	03ac                	.insn	2, 0x03ac
    10e4:	66b2                	.insn	2, 0x66b2
    10e6:	3a9a                	.insn	2, 0x3a9a
    10e8:	14b8                	.insn	2, 0x14b8
    10ea:	00c1303f c6010000 	.insn	8, 0xc601000000c1303f
    10f2:	1810                	.insn	2, 0x1810
    10f4:	acb0f417          	auipc	s0,0xacb0f
    10f8:	9a66b203          	.insn	4, 0x9a66b203
    10fc:	b83a                	.insn	2, 0xb83a
    10fe:	3f14                	.insn	2, 0x3f14
    1100:	9130                	.insn	2, 0x9130
    1102:	0000                	.insn	2, 0x0000
    1104:	0100                	.insn	2, 0x0100
    1106:	8392                	.insn	2, 0x8392
    1108:	4e81                	.insn	2, 0x4e81
    110a:	45a2                	.insn	2, 0x45a2
    110c:	81e5                	.insn	2, 0x81e5
    110e:	800c                	.insn	2, 0x800c
    1110:	e1e1                	.insn	2, 0xe1e1
    1112:	f64a                	.insn	2, 0xf64a
    1114:	7996                	.insn	2, 0x7996
    1116:	00ce                	.insn	2, 0x00ce
    1118:	0000                	.insn	2, 0x0000
    111a:	4701                	.insn	2, 0x4701
    111c:	ea9a                	.insn	2, 0xea9a
    111e:	bd8a                	.insn	2, 0xbd8a
    1120:	3256                	.insn	2, 0x3256
    1122:	f4fc                	.insn	2, 0xf4fc
    1124:	0de5                	.insn	2, 0x0de5
    1126:	ab97d9a3          	.insn	4, 0xab97d9a3
    112a:	0532                	.insn	2, 0x0532
    112c:	0a0c                	.insn	2, 0x0a0c
    112e:	0500                	.insn	2, 0x0500
    1130:	2802                	.insn	2, 0x2802
    1132:	1016                	.insn	2, 0x1016
    1134:	0300                	.insn	2, 0x0300
    1136:	018e                	.insn	2, 0x018e
    1138:	0501                	.insn	2, 0x0501
    113a:	0300                	.insn	2, 0x0300
    113c:	7f84                	.insn	2, 0x7f84
    113e:	0809                	.insn	2, 0x0809
    1140:	0100                	.insn	2, 0x0100
    1142:	1405                	.insn	2, 0x1405
    1144:	870a                	.insn	2, 0x870a
    1146:	0505                	.insn	2, 0x0505
    1148:	05827503          	.insn	4, 0x05827503
    114c:	4b09                	.insn	2, 0x4b09
    114e:	0505                	.insn	2, 0x0505
    1150:	0549                	.insn	2, 0x0549
    1152:	030a                	.insn	2, 0x030a
    1154:	0004090f          	.insn	4, 0x0004090f
    1158:	0501                	.insn	2, 0x0501
    115a:	0619                	.insn	2, 0x0619
    115c:	054a                	.insn	2, 0x054a
    115e:	4a21                	.insn	2, 0x4a21
    1160:	04096403          	.insn	4, 0x04096403
    1164:	0100                	.insn	2, 0x0100
    1166:	1805                	.insn	2, 0x1805
    1168:	0306                	.insn	2, 0x0306
    116a:	4a1e                	.insn	2, 0x4a1e
    116c:	0306                	.insn	2, 0x0306
    116e:	4a62                	.insn	2, 0x4a62
    1170:	0c05                	.insn	2, 0x0c05
    1172:	0306                	.insn	2, 0x0306
    1174:	8222                	.insn	2, 0x8222
    1176:	1b05                	.insn	2, 0x1b05
    1178:	4a06                	.insn	2, 0x4a06
    117a:	0505                	.insn	2, 0x0505
    117c:	054a                	.insn	2, 0x054a
    117e:	01030617          	auipc	a2,0x1030
    1182:	0409                	.insn	2, 0x0409
    1184:	0100                	.insn	2, 0x0100
    1186:	0306                	.insn	2, 0x0306
    1188:	095d                	.insn	2, 0x095d
    118a:	0008                	.insn	2, 0x0008
    118c:	0501                	.insn	2, 0x0501
    118e:	0601                	.insn	2, 0x0601
    1190:	4a00c203          	lbu	tp,1184(ra)
    1194:	0306                	.insn	2, 0x0306
    1196:	7fbe                	.insn	2, 0x7fbe
    1198:	054a                	.insn	2, 0x054a
    119a:	0605                	.insn	2, 0x0605
    119c:	054a0d03          	lb	s10,84(s4)
    11a0:	4b09                	.insn	2, 0x4b09
    11a2:	0306                	.insn	2, 0x0306
    11a4:	4a72                	.insn	2, 0x4a72
    11a6:	1305                	.insn	2, 0x1305
    11a8:	0306                	.insn	2, 0x0306
    11aa:	092a                	.insn	2, 0x092a
    11ac:	0004                	.insn	2, 0x0004
    11ae:	0501                	.insn	2, 0x0501
    11b0:	8314                	.insn	2, 0x8314
    11b2:	0505                	.insn	2, 0x0505
    11b4:	05826203          	.insn	4, 0x05826203
    11b8:	4b09                	.insn	2, 0x4b09
    11ba:	0306                	.insn	2, 0x0306
    11bc:	4a72                	.insn	2, 0x4a72
    11be:	0d05                	.insn	2, 0x0d05
    11c0:	0306                	.insn	2, 0x0306
    11c2:	0931                	.insn	2, 0x0931
    11c4:	000c                	.insn	2, 0x000c
    11c6:	0501                	.insn	2, 0x0501
    11c8:	061c                	.insn	2, 0x061c
    11ca:	054a                	.insn	2, 0x054a
    11cc:	01030617          	auipc	a2,0x1030
    11d0:	0809                	.insn	2, 0x0809
    11d2:	0100                	.insn	2, 0x0100
    11d4:	0306                	.insn	2, 0x0306
    11d6:	094e                	.insn	2, 0x094e
    11d8:	0008                	.insn	2, 0x0008
    11da:	0501                	.insn	2, 0x0501
    11dc:	0601                	.insn	2, 0x0601
    11de:	4a00c203          	lbu	tp,1184(ra)
    11e2:	0306                	.insn	2, 0x0306
    11e4:	7fbe                	.insn	2, 0x7fbe
    11e6:	054a                	.insn	2, 0x054a
    11e8:	0609                	.insn	2, 0x0609
    11ea:	064a0e03          	lb	t3,100(s4)
    11ee:	c8027203          	.insn	4, 0xc8027203
    11f2:	0101                	.insn	2, 0x0101
    11f4:	1005                	.insn	2, 0x1005
    11f6:	0306                	.insn	2, 0x0306
    11f8:	053c083b          	.insn	4, 0x053c083b
    11fc:	061f 054a 061b      	.insn	6, 0x061b054a061f
    1202:	08090103          	lb	sp,128(s2)
    1206:	0100                	.insn	2, 0x0100
    1208:	0306                	.insn	2, 0x0306
    120a:	4a44                	.insn	2, 0x4a44
    120c:	2205                	.insn	2, 0x2205
    120e:	0306                	.insn	2, 0x0306
    1210:	093e                	.insn	2, 0x093e
    1212:	000c                	.insn	2, 0x000c
    1214:	0501                	.insn	2, 0x0501
    1216:	0609                	.insn	2, 0x0609
    1218:	054a                	.insn	2, 0x054a
    121a:	061f 0545 4f10      	.insn	6, 0x4f100545061f
    1220:	0505                	.insn	2, 0x0505
    1222:	0545                	.insn	2, 0x0545
    1224:	0301                	.insn	2, 0x0301
    1226:	0909                	.insn	2, 0x0909
    1228:	0004                	.insn	2, 0x0004
    122a:	0601                	.insn	2, 0x0601
    122c:	4a7fbe03          	.insn	4, 0x4a7fbe03
    1230:	0306                	.insn	2, 0x0306
    1232:	00c2                	.insn	2, 0x00c2
    1234:	054a                	.insn	2, 0x054a
    1236:	0300                	.insn	2, 0x0300
    1238:	00d2                	.insn	2, 0x00d2
    123a:	0409                	.insn	2, 0x0409
    123c:	0100                	.insn	2, 0x0100
    123e:	0d05                	.insn	2, 0x0d05
    1240:	020a                	.insn	2, 0x020a
    1242:	1724                	.insn	2, 0x1724
    1244:	2805                	.insn	2, 0x2805
    1246:	8206                	.insn	2, 0x8206
    1248:	0d05                	.insn	2, 0x0d05
    124a:	0306                	.insn	2, 0x0306
    124c:	0901                	.insn	2, 0x0901
    124e:	0004                	.insn	2, 0x0004
    1250:	0801                	.insn	2, 0x0801
    1252:	053d                	.insn	2, 0x053d
    1254:	030c                	.insn	2, 0x030c
    1256:	4a74                	.insn	2, 0x4a74
    1258:	2c05                	.insn	2, 0x2c05
    125a:	3c081103          	lh	sp,960(a6)
    125e:	0d05                	.insn	2, 0x0d05
    1260:	04090103          	lb	sp,64(s2)
    1264:	0100                	.insn	2, 0x0100
    1266:	0306                	.insn	2, 0x0306
    1268:	7edf 05f2 0611      	.insn	6, 0x061105f27edf
    126e:	ba01a803          	lw	a6,-1120(gp)
    1272:	1e05                	.insn	2, 0x1e05
    1274:	4a06                	.insn	2, 0x4a06
    1276:	1b05                	.insn	2, 0x1b05
    1278:	064a                	.insn	2, 0x064a
    127a:	04097f03          	.insn	4, 0x04097f03
    127e:	0100                	.insn	2, 0x0100
    1280:	0905                	.insn	2, 0x0905
    1282:	ba06                	.insn	2, 0xba06
    1284:	1105                	.insn	2, 0x1105
    1286:	0306                	.insn	2, 0x0306
    1288:	0902                	.insn	2, 0x0902
    128a:	0008                	.insn	2, 0x0008
    128c:	0501                	.insn	2, 0x0501
    128e:	0830                	.insn	2, 0x0830
    1290:	0575                	.insn	2, 0x0575
    1292:	0611                	.insn	2, 0x0611
    1294:	054a                	.insn	2, 0x054a
    1296:	060d                	.insn	2, 0x060d
    1298:	3c086f03          	.insn	4, 0x3c086f03
    129c:	2805                	.insn	2, 0x2805
    129e:	f206                	.insn	2, 0xf206
    12a0:	0d05                	.insn	2, 0x0d05
    12a2:	0306                	.insn	2, 0x0306
    12a4:	0901                	.insn	2, 0x0901
    12a6:	0004                	.insn	2, 0x0004
    12a8:	0801                	.insn	2, 0x0801
    12aa:	053d                	.insn	2, 0x053d
    12ac:	030c                	.insn	2, 0x030c
    12ae:	4a74                	.insn	2, 0x4a74
    12b0:	2c05                	.insn	2, 0x2c05
    12b2:	3c081103          	lh	sp,960(a6)
    12b6:	0d05                	.insn	2, 0x0d05
    12b8:	04090103          	lb	sp,64(s2)
    12bc:	0100                	.insn	2, 0x0100
    12be:	de0306f3          	.insn	4, 0xde0306f3
    12c2:	4a7e                	.insn	2, 0x4a7e
    12c4:	1105                	.insn	2, 0x1105
    12c6:	0306                	.insn	2, 0x0306
    12c8:	01a8                	.insn	2, 0x01a8
    12ca:	0582                	.insn	2, 0x0582
    12cc:	061e                	.insn	2, 0x061e
    12ce:	054a                	.insn	2, 0x054a
    12d0:	03064a1b          	.insn	4, 0x03064a1b
    12d4:	097f 0004 0501 0609 	.insn	10, 0x05ba060905010004097f
    12dc:	05ba 
    12de:	0611                	.insn	2, 0x0611
    12e0:	08090203          	lb	tp,128(s2)
    12e4:	0100                	.insn	2, 0x0100
    12e6:	3005                	.insn	2, 0x3005
    12e8:	7508                	.insn	2, 0x7508
    12ea:	1105                	.insn	2, 0x1105
    12ec:	4a06                	.insn	2, 0x4a06
    12ee:	0d05                	.insn	2, 0x0d05
    12f0:	0306                	.insn	2, 0x0306
    12f2:	053c086f          	jal	a6,c1b44 <_start-0x3e4bc>
    12f6:	0628                	.insn	2, 0x0628
    12f8:	05f2                	.insn	2, 0x05f2
    12fa:	060d                	.insn	2, 0x060d
    12fc:	04090103          	lb	sp,64(s2)
    1300:	0100                	.insn	2, 0x0100
    1302:	0306                	.insn	2, 0x0306
    1304:	7ee6                	.insn	2, 0x7ee6
    1306:	3c08                	.insn	2, 0x3c08
    1308:	0c05                	.insn	2, 0x0c05
    130a:	0306                	.insn	2, 0x0306
    130c:	054a018f          	.insn	4, 0x054a018f
    1310:	032c                	.insn	2, 0x032c
    1312:	0811                	.insn	2, 0x0811
    1314:	053c                	.insn	2, 0x053c
    1316:	030d                	.insn	2, 0x030d
    1318:	0901                	.insn	2, 0x0901
    131a:	0004                	.insn	2, 0x0004
    131c:	0601                	.insn	2, 0x0601
    131e:	f27edf03          	lhu	t5,-217(t4)
    1322:	1105                	.insn	2, 0x1105
    1324:	0306                	.insn	2, 0x0306
    1326:	01a8                	.insn	2, 0x01a8
    1328:	0582                	.insn	2, 0x0582
    132a:	061e                	.insn	2, 0x061e
    132c:	054a                	.insn	2, 0x054a
    132e:	03064a1b          	.insn	4, 0x03064a1b
    1332:	097f 0004 0501 0609 	.insn	10, 0x03ba060905010004097f
    133a:	03ba 
    133c:	7ed9                	.insn	2, 0x7ed9
    133e:	0409                	.insn	2, 0x0409
    1340:	0100                	.insn	2, 0x0100
    1342:	1105                	.insn	2, 0x1105
    1344:	0306                	.insn	2, 0x0306
    1346:	01a9                	.insn	2, 0x01a9
    1348:	0582                	.insn	2, 0x0582
    134a:	0830                	.insn	2, 0x0830
    134c:	0575                	.insn	2, 0x0575
    134e:	0611                	.insn	2, 0x0611
    1350:	034a                	.insn	2, 0x034a
    1352:	7ed6                	.insn	2, 0x7ed6
    1354:	3c08                	.insn	2, 0x3c08
    1356:	0105                	.insn	2, 0x0105
    1358:	0b06                	.insn	2, 0x0b06
    135a:	4a01b503          	.insn	4, 0x4a01b503
    135e:	0005                	.insn	2, 0x0005
    1360:	097f9003          	lh	zero,151(t6)
    1364:	0020                	.insn	2, 0x0020
    1366:	0501                	.insn	2, 0x0501
    1368:	0a14                	.insn	2, 0x0a14
    136a:	03050587          	.insn	4, 0x03050587
    136e:	09058243          	.insn	4, 0x09058243
    1372:	4905054b          	.insn	4, 0x4905054b
    1376:	0900c103          	lbu	sp,144(ra)
    137a:	0004                	.insn	2, 0x0004
    137c:	0501                	.insn	2, 0x0501
    137e:	05498317          	auipc	t1,0x5498
    1382:	4b15                	.insn	2, 0x4b15
    1384:	0505                	.insn	2, 0x0505
    1386:	0549                	.insn	2, 0x0549
    1388:	030a                	.insn	2, 0x030a
    138a:	0906                	.insn	2, 0x0906
    138c:	0004                	.insn	2, 0x0004
    138e:	0501                	.insn	2, 0x0501
    1390:	0619                	.insn	2, 0x0619
    1392:	054a                	.insn	2, 0x054a
    1394:	4a21                	.insn	2, 0x4a21
    1396:	097fac03          	lw	s8,151(t6)
    139a:	0004                	.insn	2, 0x0004
    139c:	0501                	.insn	2, 0x0501
    139e:	0618                	.insn	2, 0x0618
    13a0:	4a00d603          	lhu	a2,1184(ra)
    13a4:	0306                	.insn	2, 0x0306
    13a6:	7faa                	.insn	2, 0x7faa
    13a8:	054a                	.insn	2, 0x054a
    13aa:	060c                	.insn	2, 0x060c
    13ac:	8200da03          	lhu	s4,-2016(ra)
    13b0:	1b05                	.insn	2, 0x1b05
    13b2:	4a06                	.insn	2, 0x4a06
    13b4:	0505                	.insn	2, 0x0505
    13b6:	054a                	.insn	2, 0x054a
    13b8:	01030617          	auipc	a2,0x1030
    13bc:	0409                	.insn	2, 0x0409
    13be:	0100                	.insn	2, 0x0100
    13c0:	0306                	.insn	2, 0x0306
    13c2:	7fa5                	.insn	2, 0x7fa5
    13c4:	0809                	.insn	2, 0x0809
    13c6:	0100                	.insn	2, 0x0100
    13c8:	0105                	.insn	2, 0x0105
    13ca:	0306                	.insn	2, 0x0306
    13cc:	00fc                	.insn	2, 0x00fc
    13ce:	064a                	.insn	2, 0x064a
    13d0:	4a7f8403          	lb	s0,1191(t6)
    13d4:	0505                	.insn	2, 0x0505
    13d6:	0306                	.insn	2, 0x0306
    13d8:	4a0d                	.insn	2, 0x4a0d
    13da:	0905                	.insn	2, 0x0905
    13dc:	7203064b          	.insn	4, 0x7203064b
    13e0:	054a                	.insn	2, 0x054a
    13e2:	e2030613          	addi	a2,t1,-480 # 549919e <_stack_top+0x538d1de>
    13e6:	0900                	.insn	2, 0x0900
    13e8:	0004                	.insn	2, 0x0004
    13ea:	0501                	.insn	2, 0x0501
    13ec:	8314                	.insn	2, 0x8314
    13ee:	0505                	.insn	2, 0x0505
    13f0:	827faa03          	lw	s4,-2009(t6)
    13f4:	0905                	.insn	2, 0x0905
    13f6:	7203064b          	.insn	4, 0x7203064b
    13fa:	054a                	.insn	2, 0x054a
    13fc:	060d                	.insn	2, 0x060d
    13fe:	0900e903          	.insn	4, 0x0900e903
    1402:	000c                	.insn	2, 0x000c
    1404:	0501                	.insn	2, 0x0501
    1406:	061c                	.insn	2, 0x061c
    1408:	054a                	.insn	2, 0x054a
    140a:	01030617          	auipc	a2,0x1030
    140e:	0809                	.insn	2, 0x0809
    1410:	0100                	.insn	2, 0x0100
    1412:	0306                	.insn	2, 0x0306
    1414:	7f96                	.insn	2, 0x7f96
    1416:	0809                	.insn	2, 0x0809
    1418:	0100                	.insn	2, 0x0100
    141a:	0105                	.insn	2, 0x0105
    141c:	0306                	.insn	2, 0x0306
    141e:	00fc                	.insn	2, 0x00fc
    1420:	064a                	.insn	2, 0x064a
    1422:	4a7f8403          	lb	s0,1191(t6)
    1426:	0905                	.insn	2, 0x0905
    1428:	0306                	.insn	2, 0x0306
    142a:	4a0e                	.insn	2, 0x4a0e
    142c:	0105                	.insn	2, 0x0105
    142e:	0200ee03          	.insn	4, 0x0200ee03
    1432:	01c8                	.insn	2, 0x01c8
    1434:	0501                	.insn	2, 0x0501
    1436:	0300                	.insn	2, 0x0300
    1438:	093e                	.insn	2, 0x093e
    143a:	0004                	.insn	2, 0x0004
    143c:	0501                	.insn	2, 0x0501
    143e:	0a05                	.insn	2, 0x0a05
    1440:	3402                	.insn	2, 0x3402
    1442:	0618                	.insn	2, 0x0618
    1444:	087ec003          	lbu	zero,135(t4)
    1448:	0574                	.insn	2, 0x0574
    144a:	060d                	.insn	2, 0x060d
    144c:	ba01c303          	lbu	t1,-1120(gp)
    1450:	3105                	.insn	2, 0x3105
    1452:	060505ef          	jal	a1,514b2 <_start-0xaeb4e>
    1456:	054a                	.insn	2, 0x054a
    1458:	060d                	.insn	2, 0x060d
    145a:	04090203          	lb	tp,64(s2)
    145e:	0100                	.insn	2, 0x0100
    1460:	3205                	.insn	2, 0x3205
    1462:	f206                	.insn	2, 0xf206
    1464:	097ebe03          	.insn	4, 0x097ebe03
    1468:	0004                	.insn	2, 0x0004
    146a:	0501                	.insn	2, 0x0501
    146c:	0619                	.insn	2, 0x0619
    146e:	4a01c803          	lbu	a6,1184(gp)
    1472:	0306                	.insn	2, 0x0306
    1474:	7eb8                	.insn	2, 0x7eb8
    1476:	054a                	.insn	2, 0x054a
    1478:	0610                	.insn	2, 0x0610
    147a:	4a018403          	lb	s0,1184(gp)
    147e:	1705                	.insn	2, 0x1705
    1480:	0549                	.insn	2, 0x0549
    1482:	4b21                	.insn	2, 0x4b21
    1484:	0d05                	.insn	2, 0x0d05
    1486:	4a06                	.insn	2, 0x4a06
    1488:	1305                	.insn	2, 0x1305
    148a:	8406                	.insn	2, 0x8406
    148c:	0505                	.insn	2, 0x0505
    148e:	9c02                	.insn	2, 0x9c02
    1490:	0f01                	.insn	2, 0x0f01
    1492:	3105                	.insn	2, 0x3105
    1494:	0900c603          	lbu	a2,144(ra)
    1498:	0004                	.insn	2, 0x0004
    149a:	0501                	.insn	2, 0x0501
    149c:	500d                	.insn	2, 0x500d
    149e:	1105                	.insn	2, 0x1105
    14a0:	8206                	.insn	2, 0x8206
    14a2:	0d05                	.insn	2, 0x0d05
    14a4:	0306                	.insn	2, 0x0306
    14a6:	0905                	.insn	2, 0x0905
    14a8:	0004                	.insn	2, 0x0004
    14aa:	0501                	.insn	2, 0x0501
    14ac:	0331                	.insn	2, 0x0331
    14ae:	f26c                	.insn	2, 0xf26c
    14b0:	0505                	.insn	2, 0x0505
    14b2:	4a06                	.insn	2, 0x4a06
    14b4:	0905                	.insn	2, 0x0905
    14b6:	0306                	.insn	2, 0x0306
    14b8:	091a                	.insn	2, 0x091a
    14ba:	0004                	.insn	2, 0x0004
    14bc:	0601                	.insn	2, 0x0601
    14be:	f27ea603          	lw	a2,-217(t4)
    14c2:	0d05                	.insn	2, 0x0d05
    14c4:	0306                	.insn	2, 0x0306
    14c6:	01d0                	.insn	2, 0x01d0
    14c8:	064a                	.insn	2, 0x064a
    14ca:	087eb003          	.insn	4, 0x087eb003
    14ce:	053c                	.insn	2, 0x053c
    14d0:	061f e003 0801      	.insn	6, 0x0801e003061f
    14d6:	05ac                	.insn	2, 0x05ac
    14d8:	0605                	.insn	2, 0x0605
    14da:	054a                	.insn	2, 0x054a
    14dc:	0103061b          	.insn	4, 0x0103061b
    14e0:	0409                	.insn	2, 0x0409
    14e2:	0100                	.insn	2, 0x0100
    14e4:	1805                	.insn	2, 0x1805
    14e6:	06110583          	lb	a1,97(sp)
    14ea:	054a                	.insn	2, 0x054a
    14ec:	8209                	.insn	2, 0x8209
    14ee:	1705                	.insn	2, 0x1705
    14f0:	8306                	.insn	2, 0x8306
    14f2:	1105                	.insn	2, 0x1105
    14f4:	4a06                	.insn	2, 0x4a06
    14f6:	0905                	.insn	2, 0x0905
    14f8:	0682                	.insn	2, 0x0682
    14fa:	bb100583          	lb	a1,-1103(zero) # fffffbb1 <_stack_top+0xffef3bf1>
    14fe:	1605                	.insn	2, 0x1605
    1500:	4a06                	.insn	2, 0x4a06
    1502:	1d05                	.insn	2, 0x1d05
    1504:	04090003          	lb	zero,64(s2)
    1508:	0100                	.insn	2, 0x0100
    150a:	ba7e9b03          	lh	s6,-1113(t4)
    150e:	0105                	.insn	2, 0x0105
    1510:	0b06                	.insn	2, 0x0b06
    1512:	4a01e703          	.insn	4, 0x4a01e703
    1516:	0005                	.insn	2, 0x0005
    1518:	2c090703          	lb	a4,704(s2)
    151c:	0100                	.insn	2, 0x0100
    151e:	0505                	.insn	2, 0x0505
    1520:	080a                	.insn	2, 0x080a
    1522:	05ad                	.insn	2, 0x05ad
    1524:	f80d                	.insn	2, 0xf80d
    1526:	0306                	.insn	2, 0x0306
    1528:	05f27e8b          	.insn	4, 0x05f27e8b
    152c:	01f50333          	add	t1,a0,t6
    1530:	0582                	.insn	2, 0x0582
    1532:	0609                	.insn	2, 0x0609
    1534:	04090503          	lb	a0,64(s2)
    1538:	0100                	.insn	2, 0x0100
    153a:	0d05                	.insn	2, 0x0d05
    153c:	3708                	.insn	2, 0x3708
    153e:	3305                	.insn	2, 0x3305
    1540:	f206                	.insn	2, 0xf206
    1542:	0905                	.insn	2, 0x0905
    1544:	0306                	.insn	2, 0x0306
    1546:	0905                	.insn	2, 0x0905
    1548:	0004                	.insn	2, 0x0004
    154a:	0501                	.insn	2, 0x0501
    154c:	080d                	.insn	2, 0x080d
    154e:	06330537          	lui	a0,0x6330
    1552:	05f2                	.insn	2, 0x05f2
    1554:	0609                	.insn	2, 0x0609
    1556:	04090503          	lb	a0,64(s2)
    155a:	0100                	.insn	2, 0x0100
    155c:	0306                	.insn	2, 0x0306
    155e:	7e86                	.insn	2, 0x7e86
    1560:	3c08                	.insn	2, 0x3c08
    1562:	0105                	.insn	2, 0x0105
    1564:	0306                	.insn	2, 0x0306
    1566:	0280                	.insn	2, 0x0280
    1568:	e408                	.insn	2, 0xe408
    156a:	0b06                	.insn	2, 0x0b06
    156c:	024a                	.insn	2, 0x024a
    156e:	0018                	.insn	2, 0x0018
    1570:	0101                	.insn	2, 0x0101
    1572:	0c31                	.insn	2, 0x0c31
    1574:	0000                	.insn	2, 0x0000
    1576:	0005                	.insn	2, 0x0005
    1578:	0004                	.insn	2, 0x0004
    157a:	00000093          	li	ra,0
    157e:	0101                	.insn	2, 0x0101
    1580:	fb01                	.insn	2, 0xfb01
    1582:	0d0e                	.insn	2, 0x0d0e
    1584:	0100                	.insn	2, 0x0100
    1586:	0101                	.insn	2, 0x0101
    1588:	0001                	.insn	2, 0x0001
    158a:	0000                	.insn	2, 0x0000
    158c:	0001                	.insn	2, 0x0001
    158e:	0100                	.insn	2, 0x0100
    1590:	0101                	.insn	2, 0x0101
    1592:	031f 0000 0000      	.insn	6, 0x031f
    1598:	004e                	.insn	2, 0x004e
    159a:	0000                	.insn	2, 0x0000
    159c:	0054                	.insn	2, 0x0054
    159e:	0000                	.insn	2, 0x0000
    15a0:	021f0103          	lb	sp,33(t5)
    15a4:	051e050f          	.insn	4, 0x051e050f
    15a8:	000000d7          	.insn	4, 0x00d7
    15ac:	0800                	.insn	2, 0x0800
    15ae:	312a                	.insn	2, 0x312a
    15b0:	2eac                	.insn	2, 0x2eac
    15b2:	a7ff 718b 787a 5020 	.insn	14, 0xdb77db915020787a718ba7ff
    15ba:	db91 db77 0000 
    15c0:	0100                	.insn	2, 0x0100
    15c2:	2a08                	.insn	2, 0x2a08
    15c4:	ac31                	.insn	2, 0xac31
    15c6:	ff2e                	.insn	2, 0xff2e
    15c8:	7a718ba7          	.insn	4, 0x7a718ba7
    15cc:	2078                	.insn	2, 0x2078
    15ce:	9150                	.insn	2, 0x9150
    15d0:	009177db          	.insn	4, 0x009177db
    15d4:	0000                	.insn	2, 0x0000
    15d6:	9201                	.insn	2, 0x9201
    15d8:	a24e8183          	lb	gp,-1500(t4)
    15dc:	e545                	.insn	2, 0xe545
    15de:	0c81                	.insn	2, 0x0c81
    15e0:	e180                	.insn	2, 0xe180
    15e2:	4ae1                	.insn	2, 0x4ae1
    15e4:	96f6                	.insn	2, 0x96f6
    15e6:	a779                	.insn	2, 0xa779
    15e8:	0000                	.insn	2, 0x0000
    15ea:	0200                	.insn	2, 0x0200
    15ec:	7aa4                	.insn	2, 0x7aa4
    15ee:	6c6a                	.insn	2, 0x6c6a
    15f0:	cb7f 27c6 2376 e67d 	.insn	18, 0xe6010000009a4995acabe67d237627c6cb7f
    15f8:	acab 4995 009a 0000 
    1600:	e601 
    1602:	ba9885cb          	.insn	4, 0xba9885cb
    1606:	b9de                	.insn	2, 0xb9de
    1608:	a0dc77db          	.insn	4, 0xa0dc77db
    160c:	20a4                	.insn	2, 0x20a4
    160e:	2345                	.insn	2, 0x2345
    1610:	02050053          	.insn	4, 0x02050053
    1614:	1eec                	.insn	2, 0x1eec
    1616:	0010                	.insn	2, 0x0010
    1618:	0100c203          	lbu	tp,16(ra)
    161c:	0b05                	.insn	2, 0x0b05
    161e:	c00a                	.insn	2, 0xc00a
    1620:	0306                	.insn	2, 0x0306
    1622:	05827fb7          	lui	t6,0x5827
    1626:	0611                	.insn	2, 0x0611
    1628:	4a00cb03          	lbu	s6,1184(ra)
    162c:	0905                	.insn	2, 0x0905
    162e:	04090103          	lb	sp,64(s2)
    1632:	0100                	.insn	2, 0x0100
    1634:	4f1105f3          	.insn	4, 0x4f1105f3
    1638:	0505                	.insn	2, 0x0505
    163a:	064e                	.insn	2, 0x064e
    163c:	097faa03          	lw	s4,151(t6) # 5827097 <_stack_top+0x571b0d7>
    1640:	0004                	.insn	2, 0x0004
    1642:	0301                	.insn	2, 0x0301
    1644:	00d6                	.insn	2, 0x00d6
    1646:	0582                	.insn	2, 0x0582
    1648:	0601                	.insn	2, 0x0601
    164a:	068a                	.insn	2, 0x068a
    164c:	00054a0b          	.insn	4, 0x00054a0b
    1650:	0306                	.insn	2, 0x0306
    1652:	00100903          	lb	s2,1(zero) # 1 <_start-0xfffff>
    1656:	0501                	.insn	2, 0x0501
    1658:	0a05                	.insn	2, 0x0a05
    165a:	2402                	.insn	2, 0x2402
    165c:	051a                	.insn	2, 0x051a
    165e:	1705f413          	andi	s0,a1,368
    1662:	05f4                	.insn	2, 0x05f4
    1664:	0305                	.insn	2, 0x0305
    1666:	0905                	.insn	2, 0x0905
    1668:	0004                	.insn	2, 0x0004
    166a:	0501                	.insn	2, 0x0501
    166c:	f409                	.insn	2, 0xf409
    166e:	0306                	.insn	2, 0x0306
    1670:	7f8c                	.insn	2, 0x7f8c
    1672:	1809                	.insn	2, 0x1809
    1674:	0100                	.insn	2, 0x0100
    1676:	1805                	.insn	2, 0x1805
    1678:	0306                	.insn	2, 0x0306
    167a:	068201cb          	.insn	4, 0x068201cb
    167e:	4a7eb503          	.insn	4, 0x4a7eb503
    1682:	0105                	.insn	2, 0x0105
    1684:	0306                	.insn	2, 0x0306
    1686:	01f6                	.insn	2, 0x01f6
    1688:	06f2                	.insn	2, 0x06f2
    168a:	05054a0b          	.insn	4, 0x05054a0b
    168e:	0306                	.insn	2, 0x0306
    1690:	24027f83          	.insn	4, 0x24027f83
    1694:	0501                	.insn	2, 0x0501
    1696:	0309                	.insn	2, 0x0309
    1698:	7fb1                	.insn	2, 0x7fb1
    169a:	06f2                	.insn	2, 0x06f2
    169c:	054a5603          	lhu	a2,84(s4)
    16a0:	0318                	.insn	2, 0x0318
    16a2:	ba2a                	.insn	2, 0xba2a
    16a4:	04095603          	lhu	a2,64(s2)
    16a8:	0100                	.insn	2, 0x0100
    16aa:	05822a03          	lw	s4,88(tp) # 58 <_start-0xfffa8>
    16ae:	6b030617          	auipc	a2,0x6b030
    16b2:	0409                	.insn	2, 0x0409
    16b4:	0100                	.insn	2, 0x0100
    16b6:	1605                	.insn	2, 0x1605
    16b8:	0549                	.insn	2, 0x0549
    16ba:	4b1c                	.insn	2, 0x4b1c
    16bc:	1b05                	.insn	2, 0x1b05
    16be:	0549                	.insn	2, 0x0549
    16c0:	0316                	.insn	2, 0x0316
    16c2:	8219                	.insn	2, 0x8219
    16c4:	0306                	.insn	2, 0x0306
    16c6:	00040953          	.insn	4, 0x00040953
    16ca:	0301                	.insn	2, 0x0301
    16cc:	4a2d                	.insn	2, 0x4a2d
    16ce:	0306                	.insn	2, 0x0306
    16d0:	00040967          	jalr	s2,s0 # acb100f4 <_stack_top+0xaca04134>
    16d4:	0501                	.insn	2, 0x0501
    16d6:	16054b17          	auipc	s6,0x16054
    16da:	064a1e03          	lh	t3,100(s4)
    16de:	08094d03          	lbu	s10,128(s2)
    16e2:	0100                	.insn	2, 0x0100
    16e4:	054a3303          	.insn	4, 0x054a3303
    16e8:	67030617          	auipc	a2,0x67030
    16ec:	0409                	.insn	2, 0x0409
    16ee:	0100                	.insn	2, 0x0100
    16f0:	054b4b4b          	.insn	4, 0x054b4b4b
    16f4:	0316                	.insn	2, 0x0316
    16f6:	4a1c                	.insn	2, 0x4a1c
    16f8:	2305                	.insn	2, 0x2305
    16fa:	10096303          	.insn	4, 0x10096303
    16fe:	0100                	.insn	2, 0x0100
    1700:	0905                	.insn	2, 0x0905
    1702:	8200df03          	lhu	t5,-2016(ra)
    1706:	1705                	.insn	2, 0x1705
    1708:	097fa103          	lw	sp,151(t6)
    170c:	0004                	.insn	2, 0x0004
    170e:	0501                	.insn	2, 0x0501
    1710:	481d                	.insn	2, 0x481d
    1712:	0d05                	.insn	2, 0x0d05
    1714:	054d                	.insn	2, 0x054d
    1716:	491c                	.insn	2, 0x491c
    1718:	2205                	.insn	2, 0x2205
    171a:	0549                	.insn	2, 0x0549
    171c:	4c1c                	.insn	2, 0x4c1c
    171e:	2305                	.insn	2, 0x2305
    1720:	0549                	.insn	2, 0x0549
    1722:	0314                	.insn	2, 0x0314
    1724:	00e8                	.insn	2, 0x00e8
    1726:	054a                	.insn	2, 0x054a
    1728:	4c09                	.insn	2, 0x4c09
    172a:	0d05                	.insn	2, 0x0d05
    172c:	05f4                	.insn	2, 0x05f4
    172e:	0618                	.insn	2, 0x0618
    1730:	054a                	.insn	2, 0x054a
    1732:	0609                	.insn	2, 0x0609
    1734:	04090503          	lb	a0,64(s2)
    1738:	0100                	.insn	2, 0x0100
    173a:	0d05                	.insn	2, 0x0d05
    173c:	05f4                	.insn	2, 0x05f4
    173e:	054a061b          	.insn	4, 0x054a061b
    1742:	4a0d                	.insn	2, 0x4a0d
    1744:	097ef103          	.insn	4, 0x097ef103
    1748:	000c                	.insn	2, 0x000c
    174a:	0501                	.insn	2, 0x0501
    174c:	0618                	.insn	2, 0x0618
    174e:	8201cb03          	lbu	s6,-2016(gp)
    1752:	0306                	.insn	2, 0x0306
    1754:	7eb5                	.insn	2, 0x7eb5
    1756:	064a                	.insn	2, 0x064a
    1758:	8201cb03          	lbu	s6,-2016(gp)
    175c:	0905                	.insn	2, 0x0905
    175e:	054a4903          	lbu	s2,84(s4)
    1762:	f40e                	.insn	2, 0xf40e
    1764:	0d05                	.insn	2, 0x0d05
    1766:	8206                	.insn	2, 0x8206
    1768:	097eea03          	.insn	4, 0x097eea03
    176c:	0004                	.insn	2, 0x0004
    176e:	0501                	.insn	2, 0x0501
    1770:	0618                	.insn	2, 0x0618
    1772:	0801cb03          	lbu	s6,128(gp)
    1776:	053c                	.insn	2, 0x053c
    1778:	0314                	.insn	2, 0x0314
    177a:	7fb1                	.insn	2, 0x7fb1
    177c:	054a                	.insn	2, 0x054a
    177e:	0600                	.insn	2, 0x0600
    1780:	ba7f8403          	lb	s0,-1113(t6)
    1784:	0505                	.insn	2, 0x0505
    1786:	0306                	.insn	2, 0x0306
    1788:	019e                	.insn	2, 0x019e
    178a:	0582                	.insn	2, 0x0582
    178c:	7ef70317          	auipc	t1,0x7ef70
    1790:	05f2                	.insn	2, 0x05f2
    1792:	4916                	.insn	2, 0x4916
    1794:	1c05                	.insn	2, 0x1c05
    1796:	491b054b          	.insn	4, 0x491b054b
    179a:	0505                	.insn	2, 0x0505
    179c:	4a018d03          	lb	s10,1184(gp)
    17a0:	1d05                	.insn	2, 0x1d05
    17a2:	061b05f3          	.insn	4, 0x061b05f3
    17a6:	054a                	.insn	2, 0x054a
    17a8:	0605                	.insn	2, 0x0605
    17aa:	054c                	.insn	2, 0x054c
    17ac:	7ef0031b          	.insn	4, 0x7ef0031b
    17b0:	05f2                	.insn	2, 0x05f2
    17b2:	0305                	.insn	2, 0x0305
    17b4:	054a0193          	addi	gp,s4,84
    17b8:	f311                	.insn	2, 0xf311
    17ba:	0505                	.insn	2, 0x0505
    17bc:	054c                	.insn	2, 0x054c
    17be:	7ef20323          	sb	a5,2022(tp) # 7e6 <_start-0xff81a>
    17c2:	05f2                	.insn	2, 0x05f2
    17c4:	0305                	.insn	2, 0x0305
    17c6:	0191                	.insn	2, 0x0191
    17c8:	054a                	.insn	2, 0x054a
    17ca:	7eef0323          	sb	a4,2022(t5)
    17ce:	05f2                	.insn	2, 0x05f2
    17d0:	0314                	.insn	2, 0x0314
    17d2:	0192                	.insn	2, 0x0192
    17d4:	054a                	.insn	2, 0x054a
    17d6:	4c05                	.insn	2, 0x4c05
    17d8:	0306                	.insn	2, 0x0306
    17da:	7ed0                	.insn	2, 0x7ed0
    17dc:	05f2                	.insn	2, 0x05f2
    17de:	061a                	.insn	2, 0x061a
    17e0:	4a01b203          	.insn	4, 0x4a01b203
    17e4:	0905                	.insn	2, 0x0905
    17e6:	04090503          	lb	a0,64(s2)
    17ea:	0100                	.insn	2, 0x0100
    17ec:	1f05                	.insn	2, 0x1f05
    17ee:	4a06                	.insn	2, 0x4a06
    17f0:	0306                	.insn	2, 0x0306
    17f2:	0905                	.insn	2, 0x0905
    17f4:	0004                	.insn	2, 0x0004
    17f6:	0501                	.insn	2, 0x0501
    17f8:	0319                	.insn	2, 0x0319
    17fa:	0905                	.insn	2, 0x0905
    17fc:	0004                	.insn	2, 0x0004
    17fe:	0601                	.insn	2, 0x0601
    1800:	097ebf03          	.insn	4, 0x097ebf03
    1804:	000c                	.insn	2, 0x000c
    1806:	0501                	.insn	2, 0x0501
    1808:	0618                	.insn	2, 0x0618
    180a:	8201cb03          	lbu	s6,-2016(gp)
    180e:	0306                	.insn	2, 0x0306
    1810:	7eb5                	.insn	2, 0x7eb5
    1812:	064a                	.insn	2, 0x064a
    1814:	8201cb03          	lbu	s6,-2016(gp)
    1818:	0306                	.insn	2, 0x0306
    181a:	7eb5                	.insn	2, 0x7eb5
    181c:	064a                	.insn	2, 0x064a
    181e:	8201cb03          	lbu	s6,-2016(gp)
    1822:	0306                	.insn	2, 0x0306
    1824:	7eb5                	.insn	2, 0x7eb5
    1826:	064a                	.insn	2, 0x064a
    1828:	8201cb03          	lbu	s6,-2016(gp)
    182c:	1205                	.insn	2, 0x1205
    182e:	0545                	.insn	2, 0x0545
    1830:	0309                	.insn	2, 0x0309
    1832:	0905                	.insn	2, 0x0905
    1834:	0004                	.insn	2, 0x0004
    1836:	0501                	.insn	2, 0x0501
    1838:	0618                	.insn	2, 0x0618
    183a:	0382                	.insn	2, 0x0382
    183c:	7eb5                	.insn	2, 0x7eb5
    183e:	0409                	.insn	2, 0x0409
    1840:	0100                	.insn	2, 0x0100
    1842:	8201cb03          	lbu	s6,-2016(gp)
    1846:	4a7eb503          	.insn	4, 0x4a7eb503
    184a:	0306                	.insn	2, 0x0306
    184c:	058201cb          	.insn	4, 0x058201cb
    1850:	4f05                	.insn	2, 0x4f05
    1852:	0905                	.insn	2, 0x0905
    1854:	06f4                	.insn	2, 0x06f4
    1856:	097eae03          	lw	t3,151(t4)
    185a:	0010                	.insn	2, 0x0010
    185c:	0501                	.insn	2, 0x0501
    185e:	0605                	.insn	2, 0x0605
    1860:	0801d703          	lhu	a4,128(gp)
    1864:	05ac                	.insn	2, 0x05ac
    1866:	2205f417          	auipc	s0,0x2205f
    186a:	4a06                	.insn	2, 0x4a06
    186c:	1505                	.insn	2, 0x1505
    186e:	054a                	.insn	2, 0x054a
    1870:	0605                	.insn	2, 0x0605
    1872:	054c                	.insn	2, 0x054c
    1874:	f418                	.insn	2, 0xf418
    1876:	1605                	.insn	2, 0x1605
    1878:	4a06                	.insn	2, 0x4a06
    187a:	0905                	.insn	2, 0x0905
    187c:	4d06                	.insn	2, 0x4d06
    187e:	1a05                	.insn	2, 0x1a05
    1880:	081305f3          	.insn	4, 0x081305f3
    1884:	9c03063f 0004097e 	.insn	8, 0x0004097e9c03063f
    188c:	0501                	.insn	2, 0x0501
    188e:	0609                	.insn	2, 0x0609
    1890:	4a01e503          	.insn	4, 0x4a01e503
    1894:	1a05                	.insn	2, 0x1a05
    1896:	081305f3          	.insn	4, 0x081305f3
    189a:	0309053f 00040901 	.insn	8, 0x000409010309053f
    18a2:	0501                	.insn	2, 0x0501
    18a4:	f31a                	.insn	2, 0xf31a
    18a6:	1305                	.insn	2, 0x1305
    18a8:	05f5                	.insn	2, 0x05f5
    18aa:	0309                	.insn	2, 0x0309
    18ac:	0901                	.insn	2, 0x0901
    18ae:	0004                	.insn	2, 0x0004
    18b0:	0601                	.insn	2, 0x0601
    18b2:	f27e9103          	lh	sp,-217(t4)
    18b6:	1a05                	.insn	2, 0x1a05
    18b8:	0306                	.insn	2, 0x0306
    18ba:	01f0                	.insn	2, 0x01f0
    18bc:	064a                	.insn	2, 0x064a
    18be:	087e9003          	lh	zero,135(t4)
    18c2:	053c                	.insn	2, 0x053c
    18c4:	e4030613          	addi	a2,t1,-448 # 7ef715cc <_stack_top+0x7ee6560c>
    18c8:	4a01                	.insn	2, 0x4a01
    18ca:	0306                	.insn	2, 0x0306
    18cc:	7e9c                	.insn	2, 0x7e9c
    18ce:	054a                	.insn	2, 0x054a
    18d0:	0609                	.insn	2, 0x0609
    18d2:	030a                	.insn	2, 0x030a
    18d4:	092a                	.insn	2, 0x092a
    18d6:	000c                	.insn	2, 0x000c
    18d8:	0501                	.insn	2, 0x0501
    18da:	0618                	.insn	2, 0x0618
    18dc:	3c08                	.insn	2, 0x3c08
    18de:	04095603          	lhu	a2,64(s2)
    18e2:	0100                	.insn	2, 0x0100
    18e4:	05822a03          	lw	s4,88(tp) # 58 <_start-0xfffa8>
    18e8:	6b030617          	auipc	a2,0x6b030
    18ec:	0409                	.insn	2, 0x0409
    18ee:	0100                	.insn	2, 0x0100
    18f0:	1605                	.insn	2, 0x1605
    18f2:	0549                	.insn	2, 0x0549
    18f4:	4b1c                	.insn	2, 0x4b1c
    18f6:	1b05                	.insn	2, 0x1b05
    18f8:	0549                	.insn	2, 0x0549
    18fa:	0316                	.insn	2, 0x0316
    18fc:	ba19                	.insn	2, 0xba19
    18fe:	0306                	.insn	2, 0x0306
    1900:	00040953          	.insn	4, 0x00040953
    1904:	0301                	.insn	2, 0x0301
    1906:	4a2d                	.insn	2, 0x4a2d
    1908:	0306                	.insn	2, 0x0306
    190a:	00040967          	jalr	s2,s0 # 22060866 <_stack_top+0x21f548a6>
    190e:	0501                	.insn	2, 0x0501
    1910:	16054b17          	auipc	s6,0x16054
    1914:	064a1e03          	lh	t3,100(s4)
    1918:	0c094d03          	lbu	s10,192(s2)
    191c:	0100                	.insn	2, 0x0100
    191e:	054a3303          	.insn	4, 0x054a3303
    1922:	67030617          	auipc	a2,0x67030
    1926:	0409                	.insn	2, 0x0409
    1928:	0100                	.insn	2, 0x0100
    192a:	054b4b4b          	.insn	4, 0x054b4b4b
    192e:	0316                	.insn	2, 0x0316
    1930:	4a1c                	.insn	2, 0x4a1c
    1932:	2305                	.insn	2, 0x2305
    1934:	10096303          	.insn	4, 0x10096303
    1938:	0100                	.insn	2, 0x0100
    193a:	1605                	.insn	2, 0x1605
    193c:	054a2003          	lw	zero,84(s4)
    1940:	8601                	.insn	2, 0x8601
    1942:	0005                	.insn	2, 0x0005
    1944:	0901b903          	.insn	4, 0x0901b903
    1948:	0004                	.insn	2, 0x0004
    194a:	0501                	.insn	2, 0x0501
    194c:	0a11                	.insn	2, 0x0a11
    194e:	ea08                	.insn	2, 0xea08
    1950:	1b05                	.insn	2, 0x1b05
    1952:	04097c03          	.insn	4, 0x04097c03
    1956:	0100                	.insn	2, 0x0100
    1958:	0905                	.insn	2, 0x0905
    195a:	05c1                	.insn	2, 0x05c1
    195c:	0600                	.insn	2, 0x0600
    195e:	4a7dfe03          	.insn	4, 0x4a7dfe03
    1962:	3905                	.insn	2, 0x3905
    1964:	0306                	.insn	2, 0x0306
    1966:	054a01fb          	.insn	4, 0x054a01fb
    196a:	054a062b          	.insn	4, 0x054a062b
    196e:	0609                	.insn	2, 0x0609
    1970:	0551                	.insn	2, 0x0551
    1972:	0600                	.insn	2, 0x0600
    1974:	097dfe03          	.insn	4, 0x097dfe03
    1978:	000c                	.insn	2, 0x000c
    197a:	0501                	.insn	2, 0x0501
    197c:	0612                	.insn	2, 0x0612
    197e:	4a028503          	lb	a0,1184(t0)
    1982:	1705                	.insn	2, 0x1705
    1984:	4a7e9603          	lh	a2,1191(t4)
    1988:	4c49                	.insn	2, 0x4c49
    198a:	0d05                	.insn	2, 0x0d05
    198c:	481c054b          	.insn	4, 0x481c054b
    1990:	1d05                	.insn	2, 0x1d05
    1992:	0549                	.insn	2, 0x0549
    1994:	4c1c                	.insn	2, 0x4c1c
    1996:	0a05                	.insn	2, 0x0a05
    1998:	4a01ea03          	.insn	4, 0x4a01ea03
    199c:	2205                	.insn	2, 0x2205
    199e:	4a7e9503          	lh	a0,1191(t4)
    19a2:	0a05                	.insn	2, 0x0a05
    19a4:	4a01eb03          	.insn	4, 0x4a01eb03
    19a8:	0105                	.insn	2, 0x0105
    19aa:	0685                	.insn	2, 0x0685
    19ac:	00054a0b          	.insn	4, 0x00054a0b
    19b0:	0306                	.insn	2, 0x0306
    19b2:	00180907          	.insn	4, 0x00180907
    19b6:	0501                	.insn	2, 0x0501
    19b8:	0a05                	.insn	2, 0x0a05
    19ba:	4402                	.insn	2, 0x4402
    19bc:	0616                	.insn	2, 0x0616
    19be:	f27dec03          	.insn	4, 0xf27dec03
    19c2:	1005                	.insn	2, 0x1005
    19c4:	0306                	.insn	2, 0x0306
    19c6:	029d                	.insn	2, 0x029d
    19c8:	054a                	.insn	2, 0x054a
    19ca:	4a7a0313          	addi	t1,s4,1191
    19ce:	2005                	.insn	2, 0x2005
    19d0:	2c02                	.insn	2, 0x2c02
    19d2:	0618                	.insn	2, 0x0618
    19d4:	097de303          	.insn	4, 0x097de303
    19d8:	0004                	.insn	2, 0x0004
    19da:	0501                	.insn	2, 0x0501
    19dc:	9d03062b          	.insn	4, 0x9d03062b
    19e0:	f202                	.insn	2, 0xf202
    19e2:	3205                	.insn	2, 0x3205
    19e4:	4a06                	.insn	2, 0x4a06
    19e6:	1205                	.insn	2, 0x1205
    19e8:	0306                	.insn	2, 0x0306
    19ea:	7e85                	.insn	2, 0x7e85
    19ec:	0809                	.insn	2, 0x0809
    19ee:	0100                	.insn	2, 0x0100
    19f0:	1005                	.insn	2, 0x1005
    19f2:	4a01fb03          	.insn	4, 0x4a01fb03
    19f6:	1205                	.insn	2, 0x1205
    19f8:	4a7e8503          	lb	a0,1191(t4)
    19fc:	1005                	.insn	2, 0x1005
    19fe:	0801fb03          	.insn	4, 0x0801fb03
    1a02:	053c                	.insn	2, 0x053c
    1a04:	4c0e                	.insn	2, 0x4c0e
    1a06:	1905                	.insn	2, 0x1905
    1a08:	0649                	.insn	2, 0x0649
    1a0a:	827de203          	.insn	4, 0x827de203
    1a0e:	2005                	.insn	2, 0x2005
    1a10:	0306                	.insn	2, 0x0306
    1a12:	029d                	.insn	2, 0x029d
    1a14:	064a                	.insn	2, 0x064a
    1a16:	097de303          	.insn	4, 0x097de303
    1a1a:	0008                	.insn	2, 0x0008
    1a1c:	0301                	.insn	2, 0x0301
    1a1e:	029d                	.insn	2, 0x029d
    1a20:	034a                	.insn	2, 0x034a
    1a22:	054a7de3          	bgeu	s4,s4,227c <_start-0xfdd84>
    1a26:	0615                	.insn	2, 0x0615
    1a28:	4a02a203          	lw	tp,1184(t0)
    1a2c:	1005                	.insn	2, 0x1005
    1a2e:	060905f7          	.insn	4, 0x060905f7
    1a32:	0582                	.insn	2, 0x0582
    1a34:	0612                	.insn	2, 0x0612
    1a36:	097dfb03          	.insn	4, 0x097dfb03
    1a3a:	0014                	.insn	2, 0x0014
    1a3c:	0501                	.insn	2, 0x0501
    1a3e:	0310                	.insn	2, 0x0310
    1a40:	0285                	.insn	2, 0x0285
    1a42:	7408                	.insn	2, 0x7408
    1a44:	1905                	.insn	2, 0x1905
    1a46:	81090583          	lb	a1,-2032(s2)
    1a4a:	0005                	.insn	2, 0x0005
    1a4c:	0306                	.insn	2, 0x0306
    1a4e:	7dd9                	.insn	2, 0x7dd9
    1a50:	0409                	.insn	2, 0x0409
    1a52:	0100                	.insn	2, 0x0100
    1a54:	0905                	.insn	2, 0x0905
    1a56:	4a02a703          	lw	a4,1184(t0)
    1a5a:	1305                	.insn	2, 0x1305
    1a5c:	0306                	.insn	2, 0x0306
    1a5e:	0906                	.insn	2, 0x0906
    1a60:	0008                	.insn	2, 0x0008
    1a62:	0501                	.insn	2, 0x0501
    1a64:	bc05                	.insn	2, 0xbc05
    1a66:	1e05                	.insn	2, 0x1e05
    1a68:	06f4                	.insn	2, 0x06f4
    1a6a:	097dcf03          	lbu	t5,151(s11)
    1a6e:	0010                	.insn	2, 0x0010
    1a70:	0501                	.insn	2, 0x0501
    1a72:	0609                	.insn	2, 0x0609
    1a74:	0202b703          	.insn	4, 0x0202b703
    1a78:	0180                	.insn	2, 0x0180
    1a7a:	0601                	.insn	2, 0x0601
    1a7c:	ba7dc903          	lbu	s2,-1113(s11)
    1a80:	1305                	.insn	2, 0x1305
    1a82:	0306                	.insn	2, 0x0306
    1a84:	02ba                	.insn	2, 0x02ba
    1a86:	054a                	.insn	2, 0x054a
    1a88:	4c09                	.insn	2, 0x4c09
    1a8a:	0306                	.insn	2, 0x0306
    1a8c:	7dc4                	.insn	2, 0x7dc4
    1a8e:	05f2                	.insn	2, 0x05f2
    1a90:	0622                	.insn	2, 0x0622
    1a92:	4a02be03          	.insn	4, 0x4a02be03
    1a96:	0905                	.insn	2, 0x0905
    1a98:	4a06                	.insn	2, 0x4a06
    1a9a:	097dc203          	lbu	tp,151(s11)
    1a9e:	0004                	.insn	2, 0x0004
    1aa0:	0501                	.insn	2, 0x0501
    1aa2:	0622                	.insn	2, 0x0622
    1aa4:	8202be03          	.insn	4, 0x8202be03
    1aa8:	3a05                	.insn	2, 0x3a05
    1aaa:	4a06                	.insn	2, 0x4a06
    1aac:	0905                	.insn	2, 0x0905
    1aae:	054a                	.insn	2, 0x054a
    1ab0:	0611                	.insn	2, 0x0611
    1ab2:	04090403          	lb	s0,64(s2)
    1ab6:	0100                	.insn	2, 0x0100
    1ab8:	2705                	.insn	2, 0x2705
    1aba:	4a06                	.insn	2, 0x4a06
    1abc:	1105                	.insn	2, 0x1105
    1abe:	054a                	.insn	2, 0x054a
    1ac0:	060d                	.insn	2, 0x060d
    1ac2:	0c090503          	lb	a0,192(s2)
    1ac6:	0100                	.insn	2, 0x0100
    1ac8:	0306                	.insn	2, 0x0306
    1aca:	7db9                	.insn	2, 0x7db9
    1acc:	05f2                	.insn	2, 0x05f2
    1ace:	061f cb03 ba02      	.insn	6, 0xba02cb03061f
    1ad4:	0d05                	.insn	2, 0x0d05
    1ad6:	8206                	.insn	2, 0x8206
    1ad8:	1505                	.insn	2, 0x1505
    1ada:	0306                	.insn	2, 0x0306
    1adc:	0904                	.insn	2, 0x0904
    1ade:	0004                	.insn	2, 0x0004
    1ae0:	0501                	.insn	2, 0x0501
    1ae2:	061a                	.insn	2, 0x061a
    1ae4:	054a                	.insn	2, 0x054a
    1ae6:	0618                	.insn	2, 0x0618
    1ae8:	08090a03          	lb	s4,128(s2)
    1aec:	0100                	.insn	2, 0x0100
    1aee:	1a05                	.insn	2, 0x1a05
    1af0:	054c                	.insn	2, 0x054c
    1af2:	0311                	.insn	2, 0x0311
    1af4:	0008090f          	.insn	4, 0x0008090f
    1af8:	0501                	.insn	2, 0x0501
    1afa:	bf1f 2405 4a06      	.insn	6, 0x4a062405bf1f
    1b00:	1f05                	.insn	2, 0x1f05
    1b02:	04090003          	lb	zero,64(s2)
    1b06:	0100                	.insn	2, 0x0100
    1b08:	2405                	.insn	2, 0x2405
    1b0a:	054a                	.insn	2, 0x054a
    1b0c:	031f 0900 0004      	.insn	6, 0x00040900031f
    1b12:	0301                	.insn	2, 0x0301
    1b14:	7d91                	.insn	2, 0x7d91
    1b16:	054a                	.insn	2, 0x054a
    1b18:	0324                	.insn	2, 0x0324
    1b1a:	054a02ef          	jal	t0,a1b6e <_start-0x5e492>
    1b1e:	031f 0900 0004      	.insn	6, 0x00040900031f
    1b24:	0301                	.insn	2, 0x0301
    1b26:	7d91                	.insn	2, 0x7d91
    1b28:	054a                	.insn	2, 0x054a
    1b2a:	0324                	.insn	2, 0x0324
    1b2c:	054a02ef          	jal	t0,a1b80 <_start-0x5e480>
    1b30:	031f 0900 0004      	.insn	6, 0x00040900031f
    1b36:	0301                	.insn	2, 0x0301
    1b38:	7d91                	.insn	2, 0x7d91
    1b3a:	054a                	.insn	2, 0x054a
    1b3c:	0324                	.insn	2, 0x0324
    1b3e:	054a02ef          	jal	t0,a1b92 <_start-0x5e46e>
    1b42:	031f 0900 0004      	.insn	6, 0x00040900031f
    1b48:	0301                	.insn	2, 0x0301
    1b4a:	7d91                	.insn	2, 0x7d91
    1b4c:	054a                	.insn	2, 0x054a
    1b4e:	0324                	.insn	2, 0x0324
    1b50:	054a02ef          	jal	t0,a1ba4 <_start-0x5e45c>
    1b54:	031f 0900 0004      	.insn	6, 0x00040900031f
    1b5a:	0301                	.insn	2, 0x0301
    1b5c:	7d91                	.insn	2, 0x7d91
    1b5e:	054a                	.insn	2, 0x054a
    1b60:	0324                	.insn	2, 0x0324
    1b62:	054a02ef          	jal	t0,a1bb6 <_start-0x5e44a>
    1b66:	031f 0900 0004      	.insn	6, 0x00040900031f
    1b6c:	0301                	.insn	2, 0x0301
    1b6e:	7d91                	.insn	2, 0x7d91
    1b70:	054a                	.insn	2, 0x054a
    1b72:	0324                	.insn	2, 0x0324
    1b74:	054a02ef          	jal	t0,a1bc8 <_start-0x5e438>
    1b78:	031f 0900 0004      	.insn	6, 0x00040900031f
    1b7e:	0301                	.insn	2, 0x0301
    1b80:	7d91                	.insn	2, 0x7d91
    1b82:	054a                	.insn	2, 0x054a
    1b84:	0324                	.insn	2, 0x0324
    1b86:	054a02ef          	jal	t0,a1bda <_start-0x5e426>
    1b8a:	031f 0900 0004      	.insn	6, 0x00040900031f
    1b90:	0301                	.insn	2, 0x0301
    1b92:	7d91                	.insn	2, 0x7d91
    1b94:	054a                	.insn	2, 0x054a
    1b96:	0324                	.insn	2, 0x0324
    1b98:	054a02ef          	jal	t0,a1bec <_start-0x5e414>
    1b9c:	031f 0900 0004      	.insn	6, 0x00040900031f
    1ba2:	0301                	.insn	2, 0x0301
    1ba4:	7d91                	.insn	2, 0x7d91
    1ba6:	054a                	.insn	2, 0x054a
    1ba8:	0324                	.insn	2, 0x0324
    1baa:	054a02ef          	jal	t0,a1bfe <_start-0x5e402>
    1bae:	0609                	.insn	2, 0x0609
    1bb0:	08091903          	lh	s2,128(s2)
    1bb4:	0100                	.insn	2, 0x0100
    1bb6:	0306                	.insn	2, 0x0306
    1bb8:	7cf8                	.insn	2, 0x7cf8
    1bba:	05f2                	.insn	2, 0x05f2
    1bbc:	0611                	.insn	2, 0x0611
    1bbe:	8201ff03          	.insn	4, 0x8201ff03
    1bc2:	1b05                	.insn	2, 0x1b05
    1bc4:	08097c03          	.insn	4, 0x08097c03
    1bc8:	0100                	.insn	2, 0x0100
    1bca:	0905                	.insn	2, 0x0905
    1bcc:	0551                	.insn	2, 0x0551
    1bce:	0339                	.insn	2, 0x0339
    1bd0:	4a79                	.insn	2, 0x4a79
    1bd2:	2b05                	.insn	2, 0x2b05
    1bd4:	4a06                	.insn	2, 0x4a06
    1bd6:	0905                	.insn	2, 0x0905
    1bd8:	5106                	.insn	2, 0x5106
    1bda:	0005                	.insn	2, 0x0005
    1bdc:	0306                	.insn	2, 0x0306
    1bde:	7dfe                	.insn	2, 0x7dfe
    1be0:	0c09                	.insn	2, 0x0c09
    1be2:	0100                	.insn	2, 0x0100
    1be4:	1205                	.insn	2, 0x1205
    1be6:	0306                	.insn	2, 0x0306
    1be8:	0285                	.insn	2, 0x0285
    1bea:	0582                	.insn	2, 0x0582
    1bec:	7e960317          	auipc	t1,0x7e960
    1bf0:	494a                	.insn	2, 0x494a
    1bf2:	054c                	.insn	2, 0x054c
    1bf4:	4b0d                	.insn	2, 0x4b0d
    1bf6:	1c05                	.insn	2, 0x1c05
    1bf8:	0548                	.insn	2, 0x0548
    1bfa:	491d                	.insn	2, 0x491d
    1bfc:	1c05                	.insn	2, 0x1c05
    1bfe:	054c                	.insn	2, 0x054c
    1c00:	030a                	.insn	2, 0x030a
    1c02:	01ea                	.insn	2, 0x01ea
    1c04:	054a                	.insn	2, 0x054a
    1c06:	0322                	.insn	2, 0x0322
    1c08:	7e95                	.insn	2, 0x7e95
    1c0a:	054a                	.insn	2, 0x054a
    1c0c:	030a                	.insn	2, 0x030a
    1c0e:	054a01eb          	.insn	4, 0x054a01eb
    1c12:	031e                	.insn	2, 0x031e
    1c14:	0505822b          	.insn	4, 0x0505822b
    1c18:	0900dc03          	lhu	s8,144(ra)
    1c1c:	000c                	.insn	2, 0x000c
    1c1e:	0501                	.insn	2, 0x0501
    1c20:	0315                	.insn	2, 0x0315
    1c22:	0005ba43          	.insn	4, 0x0005ba43
    1c26:	0306                	.insn	2, 0x0306
    1c28:	7db0                	.insn	2, 0x7db0
    1c2a:	0582                	.insn	2, 0x0582
    1c2c:	0601                	.insn	2, 0x0601
    1c2e:	0390030b          	.insn	4, 0x0390030b
    1c32:	05ba                	.insn	2, 0x05ba
    1c34:	0311                	.insn	2, 0x0311
    1c36:	3c027fb3          	.insn	4, 0x3c027fb3
    1c3a:	0501                	.insn	2, 0x0501
    1c3c:	0315                	.insn	2, 0x0315
    1c3e:	ba36                	.insn	2, 0xba36
    1c40:	0306                	.insn	2, 0x0306
    1c42:	05f27d87          	.insn	4, 0x05f27d87
    1c46:	060d                	.insn	2, 0x060d
    1c48:	054a1503          	lh	a0,84(s4)
    1c4c:	4916                	.insn	2, 0x4916
    1c4e:	4a06                	.insn	2, 0x4a06
    1c50:	1705                	.insn	2, 0x1705
    1c52:	4b06                	.insn	2, 0x4b06
    1c54:	2705                	.insn	2, 0x2705
    1c56:	4a02e903          	.insn	4, 0x4a02e903
    1c5a:	1b05                	.insn	2, 0x1b05
    1c5c:	827d9603          	lh	a2,-2009(s11)
    1c60:	1c05                	.insn	2, 0x1c05
    1c62:	0327054b          	.insn	4, 0x0327054b
    1c66:	02e9                	.insn	2, 0x02e9
    1c68:	054a                	.insn	2, 0x054a
    1c6a:	062e                	.insn	2, 0x062e
    1c6c:	054a                	.insn	2, 0x054a
    1c6e:	821e                	.insn	2, 0x821e
    1c70:	1705                	.insn	2, 0x1705
    1c72:	0306                	.insn	2, 0x0306
    1c74:	7d9d                	.insn	2, 0x7d9d
    1c76:	4b4a                	.insn	2, 0x4b4a
    1c78:	0d05                	.insn	2, 0x0d05
    1c7a:	4717054b          	.insn	4, 0x4717054b
    1c7e:	1c05                	.insn	2, 0x1c05
    1c80:	054b4b4b          	.insn	4, 0x054b4b4b
    1c84:	471d                	.insn	2, 0x471d
    1c86:	2205                	.insn	2, 0x2205
    1c88:	4b23054b          	.insn	4, 0x4b23054b
    1c8c:	1e05                	.insn	2, 0x1e05
    1c8e:	8202e303          	.insn	4, 0x8202e303
    1c92:	0005                	.insn	2, 0x0005
    1c94:	08093403          	.insn	4, 0x08093403
    1c98:	0100                	.insn	2, 0x0100
    1c9a:	0505                	.insn	2, 0x0505
    1c9c:	020a                	.insn	2, 0x020a
    1c9e:	1844                	.insn	2, 0x1844
    1ca0:	0905                	.insn	2, 0x0905
    1ca2:	06f4                	.insn	2, 0x06f4
    1ca4:	087cc503          	lbu	a0,135(s9)
    1ca8:	033c                	.insn	2, 0x033c
    1caa:	034a03bb          	.insn	4, 0x034a03bb
    1cae:	7cc5                	.insn	2, 0x7cc5
    1cb0:	0409                	.insn	2, 0x0409
    1cb2:	0100                	.insn	2, 0x0100
    1cb4:	0105                	.insn	2, 0x0105
    1cb6:	0306                	.insn	2, 0x0306
    1cb8:	049f 06f2 4a0b      	.insn	6, 0x4a0b06f2049f
    1cbe:	0505                	.insn	2, 0x0505
    1cc0:	0306                	.insn	2, 0x0306
    1cc2:	7fa1                	.insn	2, 0x7fa1
    1cc4:	3c02                	.insn	2, 0x3c02
    1cc6:	f401                	.insn	2, 0xf401
    1cc8:	1605                	.insn	2, 0x1605
    1cca:	060505f3          	.insn	4, 0x060505f3
    1cce:	064a                	.insn	2, 0x064a
    1cd0:	053e08bb          	.insn	4, 0x053e08bb
    1cd4:	f316                	.insn	2, 0xf316
    1cd6:	0505                	.insn	2, 0x0505
    1cd8:	4a06                	.insn	2, 0x4a06
    1cda:	bb06                	.insn	2, 0xbb06
    1cdc:	0e05                	.insn	2, 0x0e05
    1cde:	06bc                	.insn	2, 0x06bc
    1ce0:	097cb603          	.insn	4, 0x097cb603
    1ce4:	0004                	.insn	2, 0x0004
    1ce6:	0501                	.insn	2, 0x0501
    1ce8:	0611                	.insn	2, 0x0611
    1cea:	4a03cf03          	lbu	t5,1184(t2)
    1cee:	0306                	.insn	2, 0x0306
    1cf0:	7cb1                	.insn	2, 0x7cb1
    1cf2:	0409                	.insn	2, 0x0409
    1cf4:	0100                	.insn	2, 0x0100
    1cf6:	1505                	.insn	2, 0x1505
    1cf8:	0306                	.insn	2, 0x0306
    1cfa:	03de                	.insn	2, 0x03de
    1cfc:	0682                	.insn	2, 0x0682
    1cfe:	4a7ca203          	lw	tp,1191(s9)
    1d02:	0306                	.insn	2, 0x0306
    1d04:	03de                	.insn	2, 0x03de
    1d06:	0682                	.insn	2, 0x0682
    1d08:	4a7ca203          	lw	tp,1191(s9)
    1d0c:	0505                	.insn	2, 0x0505
    1d0e:	0306                	.insn	2, 0x0306
    1d10:	054a03d7          	.insn	4, 0x054a03d7
    1d14:	f709                	.insn	2, 0xf709
    1d16:	0306                	.insn	2, 0x0306
    1d18:	7ca4                	.insn	2, 0x7ca4
    1d1a:	05f2                	.insn	2, 0x05f2
    1d1c:	0611                	.insn	2, 0x0611
    1d1e:	02049403          	lh	s0,32(s1) # 279a <_start-0xfd866>
    1d22:	0144                	.insn	2, 0x0144
    1d24:	0905                	.insn	2, 0x0905
    1d26:	034c                	.insn	2, 0x034c
    1d28:	f246                	.insn	2, 0xf246
    1d2a:	0306                	.insn	2, 0x0306
    1d2c:	7ca4                	.insn	2, 0x7ca4
    1d2e:	05f2                	.insn	2, 0x05f2
    1d30:	0615                	.insn	2, 0x0615
    1d32:	8203de03          	lhu	t3,-2016(t2)
    1d36:	04090503          	lb	a0,64(s2)
    1d3a:	0100                	.insn	2, 0x0100
    1d3c:	04090503          	lb	a0,64(s2)
    1d40:	0100                	.insn	2, 0x0100
    1d42:	0905                	.insn	2, 0x0905
    1d44:	04090503          	lb	a0,64(s2)
    1d48:	0100                	.insn	2, 0x0100
    1d4a:	f27fa703          	lw	a4,-217(t6)
    1d4e:	1f05                	.insn	2, 0x1f05
    1d50:	4a06                	.insn	2, 0x4a06
    1d52:	097cec03          	.insn	4, 0x097cec03
    1d56:	0028                	.insn	2, 0x0028
    1d58:	0301                	.insn	2, 0x0301
    1d5a:	0394                	.insn	2, 0x0394
    1d5c:	0382                	.insn	2, 0x0382
    1d5e:	7cec                	.insn	2, 0x7cec
    1d60:	0809                	.insn	2, 0x0809
    1d62:	0100                	.insn	2, 0x0100
    1d64:	2805                	.insn	2, 0x2805
    1d66:	0306                	.insn	2, 0x0306
    1d68:	054a039b          	.insn	4, 0x054a039b
    1d6c:	0309                	.insn	2, 0x0309
    1d6e:	4a0c                	.insn	2, 0x4a0c
    1d70:	1005                	.insn	2, 0x1005
    1d72:	060905f3          	.insn	4, 0x060905f3
    1d76:	0382                	.insn	2, 0x0382
    1d78:	7cd8                	.insn	2, 0x7cd8
    1d7a:	054a                	.insn	2, 0x054a
    1d7c:	0628                	.insn	2, 0x0628
    1d7e:	4a039a03          	lh	s4,1184(t2)
    1d82:	0306                	.insn	2, 0x0306
    1d84:	7ce6                	.insn	2, 0x7ce6
    1d86:	064a                	.insn	2, 0x064a
    1d88:	4a039603          	lh	a2,1184(t2)
    1d8c:	0306                	.insn	2, 0x0306
    1d8e:	7cea                	.insn	2, 0x7cea
    1d90:	064a                	.insn	2, 0x064a
    1d92:	4a039703          	lh	a4,1184(t2)
    1d96:	0306                	.insn	2, 0x0306
    1d98:	7ce9                	.insn	2, 0x7ce9
    1d9a:	064a                	.insn	2, 0x064a
    1d9c:	4a039803          	lh	a6,1184(t2)
    1da0:	0306                	.insn	2, 0x0306
    1da2:	7ce8                	.insn	2, 0x7ce8
    1da4:	054a                	.insn	2, 0x054a
    1da6:	060c                	.insn	2, 0x060c
    1da8:	4a03ab03          	lw	s6,1184(t2)
    1dac:	2905                	.insn	2, 0x2905
    1dae:	8206                	.insn	2, 0x8206
    1db0:	2f05                	.insn	2, 0x2f05
    1db2:	054a                	.insn	2, 0x054a
    1db4:	4a1d                	.insn	2, 0x4a1d
    1db6:	0905                	.insn	2, 0x0905
    1db8:	0306                	.insn	2, 0x0306
    1dba:	00c6                	.insn	2, 0x00c6
    1dbc:	054a                	.insn	2, 0x054a
    1dbe:	f422                	.insn	2, 0xf422
    1dc0:	0905                	.insn	2, 0x0905
    1dc2:	4a06                	.insn	2, 0x4a06
    1dc4:	097c8d03          	lb	s10,151(s9)
    1dc8:	0004                	.insn	2, 0x0004
    1dca:	0501                	.insn	2, 0x0501
    1dcc:	0618                	.insn	2, 0x0618
    1dce:	8203f603          	.insn	4, 0x8203f603
    1dd2:	0d05                	.insn	2, 0x0d05
    1dd4:	04090303          	lb	t1,64(s2)
    1dd8:	0100                	.insn	2, 0x0100
    1dda:	1105                	.insn	2, 0x1105
    1ddc:	05bc                	.insn	2, 0x05bc
    1dde:	054a0623          	sb	s4,76(s4)
    1de2:	4a11                	.insn	2, 0x4a11
    1de4:	0d05                	.insn	2, 0x0d05
    1de6:	0306                	.insn	2, 0x0306
    1de8:	0905                	.insn	2, 0x0905
    1dea:	0010                	.insn	2, 0x0010
    1dec:	0601                	.insn	2, 0x0601
    1dee:	ba7c8003          	lb	zero,-1113(s9)
    1df2:	1905                	.insn	2, 0x1905
    1df4:	0306                	.insn	2, 0x0306
    1df6:	0482                	.insn	2, 0x0482
    1df8:	0682                	.insn	2, 0x0682
    1dfa:	097bfe03          	.insn	4, 0x097bfe03
    1dfe:	0004                	.insn	2, 0x0004
    1e00:	0501                	.insn	2, 0x0501
    1e02:	060d                	.insn	2, 0x060d
    1e04:	4a048403          	lb	s0,1184(s1)
    1e08:	1a05                	.insn	2, 0x1a05
    1e0a:	0618054b          	.insn	4, 0x0618054b
    1e0e:	054a                	.insn	2, 0x054a
    1e10:	0624                	.insn	2, 0x0624
    1e12:	0549                	.insn	2, 0x0549
    1e14:	060d                	.insn	2, 0x060d
    1e16:	0582                	.insn	2, 0x0582
    1e18:	0614                	.insn	2, 0x0614
    1e1a:	04090403          	lb	s0,64(s2)
    1e1e:	0100                	.insn	2, 0x0100
    1e20:	0d05                	.insn	2, 0x0d05
    1e22:	054c                	.insn	2, 0x054c
    1e24:	0322                	.insn	2, 0x0322
    1e26:	ba69                	.insn	2, 0xba69
    1e28:	3a05                	.insn	2, 0x3a05
    1e2a:	4a06                	.insn	2, 0x4a06
    1e2c:	4a7c8d03          	lb	s10,1191(s9)
    1e30:	0905                	.insn	2, 0x0905
    1e32:	4a03f303          	.insn	4, 0x4a03f303
    1e36:	1405                	.insn	2, 0x1405
    1e38:	0306                	.insn	2, 0x0306
    1e3a:	091a                	.insn	2, 0x091a
    1e3c:	0004                	.insn	2, 0x0004
    1e3e:	0501                	.insn	2, 0x0501
    1e40:	0309                	.insn	2, 0x0309
    1e42:	0905                	.insn	2, 0x0905
    1e44:	0004                	.insn	2, 0x0004
    1e46:	0501                	.insn	2, 0x0501
    1e48:	0306f42b          	.insn	4, 0x0306f42b
    1e4c:	7bec                	.insn	2, 0x7bec
    1e4e:	054a                	.insn	2, 0x054a
    1e50:	0611                	.insn	2, 0x0611
    1e52:	8201ff03          	.insn	4, 0x8201ff03
    1e56:	1b05                	.insn	2, 0x1b05
    1e58:	04097c03          	.insn	4, 0x04097c03
    1e5c:	0100                	.insn	2, 0x0100
    1e5e:	0905                	.insn	2, 0x0905
    1e60:	0551                	.insn	2, 0x0551
    1e62:	0600                	.insn	2, 0x0600
    1e64:	4a7dfe03          	.insn	4, 0x4a7dfe03
    1e68:	3905                	.insn	2, 0x3905
    1e6a:	0306                	.insn	2, 0x0306
    1e6c:	054a01fb          	.insn	4, 0x054a01fb
    1e70:	034a062b          	.insn	4, 0x034a062b
    1e74:	7e85                	.insn	2, 0x7e85
    1e76:	054a                	.insn	2, 0x054a
    1e78:	0609                	.insn	2, 0x0609
    1e7a:	4a028203          	lb	tp,1184(t0)
    1e7e:	0306                	.insn	2, 0x0306
    1e80:	7dfe                	.insn	2, 0x7dfe
    1e82:	034a                	.insn	2, 0x034a
    1e84:	0282                	.insn	2, 0x0282
    1e86:	054a                	.insn	2, 0x054a
    1e88:	0300                	.insn	2, 0x0300
    1e8a:	7dfe                	.insn	2, 0x7dfe
    1e8c:	0409                	.insn	2, 0x0409
    1e8e:	0100                	.insn	2, 0x0100
    1e90:	1205                	.insn	2, 0x1205
    1e92:	0306                	.insn	2, 0x0306
    1e94:	0285                	.insn	2, 0x0285
    1e96:	054a                	.insn	2, 0x054a
    1e98:	7e960317          	auipc	t1,0x7e960
    1e9c:	494a                	.insn	2, 0x494a
    1e9e:	054c                	.insn	2, 0x054c
    1ea0:	4b0d                	.insn	2, 0x4b0d
    1ea2:	1c05                	.insn	2, 0x1c05
    1ea4:	0548                	.insn	2, 0x0548
    1ea6:	491d                	.insn	2, 0x491d
    1ea8:	1c05                	.insn	2, 0x1c05
    1eaa:	054c                	.insn	2, 0x054c
    1eac:	030a                	.insn	2, 0x030a
    1eae:	01ea                	.insn	2, 0x01ea
    1eb0:	054a                	.insn	2, 0x054a
    1eb2:	0322                	.insn	2, 0x0322
    1eb4:	7e95                	.insn	2, 0x7e95
    1eb6:	054a                	.insn	2, 0x054a
    1eb8:	030a                	.insn	2, 0x030a
    1eba:	064a01eb          	.insn	4, 0x064a01eb
    1ebe:	827dfa03          	.insn	4, 0x827dfa03
    1ec2:	0d05                	.insn	2, 0x0d05
    1ec4:	0306                	.insn	2, 0x0306
    1ec6:	048e                	.insn	2, 0x048e
    1ec8:	064a                	.insn	2, 0x064a
    1eca:	f27bf203          	.insn	4, 0xf27bf203
    1ece:	0905                	.insn	2, 0x0905
    1ed0:	0306                	.insn	2, 0x0306
    1ed2:	0499                	.insn	2, 0x0499
    1ed4:	06ba                	.insn	2, 0x06ba
    1ed6:	097be703          	.insn	4, 0x097be703
    1eda:	0004                	.insn	2, 0x0004
    1edc:	0501                	.insn	2, 0x0501
    1ede:	0618                	.insn	2, 0x0618
    1ee0:	4a049a03          	lh	s4,1184(s1)
    1ee4:	1605                	.insn	2, 0x1605
    1ee6:	4a06                	.insn	2, 0x4a06
    1ee8:	827be603          	.insn	4, 0x827be603
    1eec:	1505                	.insn	2, 0x1505
    1eee:	0306                	.insn	2, 0x0306
    1ef0:	03de                	.insn	2, 0x03de
    1ef2:	0682                	.insn	2, 0x0682
    1ef4:	4a7ca203          	lw	tp,1191(s9)
    1ef8:	0905                	.insn	2, 0x0905
    1efa:	0306                	.insn	2, 0x0306
    1efc:	0499                	.insn	2, 0x0499
    1efe:	064a                	.insn	2, 0x064a
    1f00:	4a7be703          	.insn	4, 0x4a7be703
    1f04:	1505                	.insn	2, 0x1505
    1f06:	0306                	.insn	2, 0x0306
    1f08:	03de                	.insn	2, 0x03de
    1f0a:	0682                	.insn	2, 0x0682
    1f0c:	4a7ca203          	lw	tp,1191(s9)
    1f10:	8203de03          	lhu	t3,-2016(t2)
    1f14:	0005                	.insn	2, 0x0005
    1f16:	0306                	.insn	2, 0x0306
    1f18:	00d6                	.insn	2, 0x00d6
    1f1a:	0409                	.insn	2, 0x0409
    1f1c:	0100                	.insn	2, 0x0100
    1f1e:	0505                	.insn	2, 0x0505
    1f20:	030a                	.insn	2, 0x030a
    1f22:	0209                	.insn	2, 0x0209
    1f24:	0144                	.insn	2, 0x0144
    1f26:	0905                	.insn	2, 0x0905
    1f28:	06f4                	.insn	2, 0x06f4
    1f2a:	087bc103          	lbu	sp,135(s7)
    1f2e:	033c                	.insn	2, 0x033c
    1f30:	034a04bf 04097bc1 	.insn	8, 0x04097bc1034a04bf
    1f38:	0100                	.insn	2, 0x0100
    1f3a:	0105                	.insn	2, 0x0105
    1f3c:	0306                	.insn	2, 0x0306
    1f3e:	05a6                	.insn	2, 0x05a6
    1f40:	3c08                	.insn	2, 0x3c08
    1f42:	0b06                	.insn	2, 0x0b06
    1f44:	034a                	.insn	2, 0x034a
    1f46:	7ada                	.insn	2, 0x7ada
    1f48:	3c02                	.insn	2, 0x3c02
    1f4a:	0501                	.insn	2, 0x0501
    1f4c:	0605                	.insn	2, 0x0605
    1f4e:	4a04c403          	lbu	s0,1184(s1)
    1f52:	0905                	.insn	2, 0x0905
    1f54:	05f4                	.insn	2, 0x05f4
    1f56:	060e                	.insn	2, 0x060e
    1f58:	054a                	.insn	2, 0x054a
    1f5a:	0609                	.insn	2, 0x0609
    1f5c:	04090503          	lb	a0,64(s2)
    1f60:	0100                	.insn	2, 0x0100
    1f62:	1105                	.insn	2, 0x1105
    1f64:	8206                	.insn	2, 0x8206
    1f66:	097bb503          	.insn	4, 0x097bb503
    1f6a:	0004                	.insn	2, 0x0004
    1f6c:	0501                	.insn	2, 0x0501
    1f6e:	0615                	.insn	2, 0x0615
    1f70:	8204de03          	lhu	t3,-2016(s1)
    1f74:	0306                	.insn	2, 0x0306
    1f76:	7ba2                	.insn	2, 0x7ba2
    1f78:	064a                	.insn	2, 0x064a
    1f7a:	8204de03          	lhu	t3,-2016(s1)
    1f7e:	0306                	.insn	2, 0x0306
    1f80:	7ba2                	.insn	2, 0x7ba2
    1f82:	064a                	.insn	2, 0x064a
    1f84:	0204de03          	lhu	t3,32(s1)
    1f88:	0150                	.insn	2, 0x0150
    1f8a:	04090503          	lb	a0,64(s2)
    1f8e:	0100                	.insn	2, 0x0100
    1f90:	0306                	.insn	2, 0x0306
    1f92:	7b9d                	.insn	2, 0x7b9d
    1f94:	0409                	.insn	2, 0x0409
    1f96:	0100                	.insn	2, 0x0100
    1f98:	0905                	.insn	2, 0x0905
    1f9a:	0306                	.insn	2, 0x0306
    1f9c:	0394                	.insn	2, 0x0394
    1f9e:	054a                	.insn	2, 0x054a
    1fa0:	061f 034a 7cec      	.insn	6, 0x7cec034a061f
    1fa6:	1c09                	.insn	2, 0x1c09
    1fa8:	0100                	.insn	2, 0x0100
    1faa:	2805                	.insn	2, 0x2805
    1fac:	0306                	.insn	2, 0x0306
    1fae:	0395                	.insn	2, 0x0395
    1fb0:	054a                	.insn	2, 0x054a
    1fb2:	491f 0306 7cec      	.insn	6, 0x7cec0306491f
    1fb8:	0809                	.insn	2, 0x0809
    1fba:	0100                	.insn	2, 0x0100
    1fbc:	0905                	.insn	2, 0x0905
    1fbe:	0306                	.insn	2, 0x0306
    1fc0:	3c0803a7          	.insn	4, 0x3c0803a7
    1fc4:	1005                	.insn	2, 0x1005
    1fc6:	032205f3          	.insn	4, 0x032205f3
    1fca:	01c2                	.insn	2, 0x01c2
    1fcc:	054a                	.insn	2, 0x054a
    1fce:	0609                	.insn	2, 0x0609
    1fd0:	034a                	.insn	2, 0x034a
    1fd2:	7b96                	.insn	2, 0x7b96
    1fd4:	0409                	.insn	2, 0x0409
    1fd6:	0100                	.insn	2, 0x0100
    1fd8:	2805                	.insn	2, 0x2805
    1fda:	0306                	.insn	2, 0x0306
    1fdc:	0396                	.insn	2, 0x0396
    1fde:	e408                	.insn	2, 0xe408
    1fe0:	0306                	.insn	2, 0x0306
    1fe2:	7cea                	.insn	2, 0x7cea
    1fe4:	064a                	.insn	2, 0x064a
    1fe6:	4a039703          	lh	a4,1184(t2)
    1fea:	0306                	.insn	2, 0x0306
    1fec:	7ce9                	.insn	2, 0x7ce9
    1fee:	064a                	.insn	2, 0x064a
    1ff0:	4a039803          	lh	a6,1184(t2)
    1ff4:	0306                	.insn	2, 0x0306
    1ff6:	7ce8                	.insn	2, 0x7ce8
    1ff8:	054a                	.insn	2, 0x054a
    1ffa:	060c                	.insn	2, 0x060c
    1ffc:	4a03ab03          	lw	s6,1184(t2)
    2000:	2905                	.insn	2, 0x2905
    2002:	8206                	.insn	2, 0x8206
    2004:	2f05                	.insn	2, 0x2f05
    2006:	054a                	.insn	2, 0x054a
    2008:	4a1d                	.insn	2, 0x4a1d
    200a:	4a7cd503          	lhu	a0,1191(s9)
    200e:	2205                	.insn	2, 0x2205
    2010:	0306                	.insn	2, 0x0306
    2012:	04ea                	.insn	2, 0x04ea
    2014:	05f2                	.insn	2, 0x05f2
    2016:	063a                	.insn	2, 0x063a
    2018:	034a                	.insn	2, 0x034a
    201a:	7b96                	.insn	2, 0x7b96
    201c:	054a                	.insn	2, 0x054a
    201e:	0309                	.insn	2, 0x0309
    2020:	04ea                	.insn	2, 0x04ea
    2022:	054a                	.insn	2, 0x054a
    2024:	0618                	.insn	2, 0x0618
    2026:	04090303          	lb	t1,64(s2)
    202a:	0100                	.insn	2, 0x0100
    202c:	0306                	.insn	2, 0x0306
    202e:	04097b93          	andi	s7,s2,64
    2032:	0100                	.insn	2, 0x0100
    2034:	1105                	.insn	2, 0x1105
    2036:	0306                	.insn	2, 0x0306
    2038:	04f0                	.insn	2, 0x04f0
    203a:	054a                	.insn	2, 0x054a
    203c:	05820623          	sb	s8,76(tp) # 4c <_start-0xfffb4>
    2040:	8211                	.insn	2, 0x8211
    2042:	097b9003          	lh	zero,151(s7)
    2046:	0008                	.insn	2, 0x0008
    2048:	0501                	.insn	2, 0x0501
    204a:	061c                	.insn	2, 0x061c
    204c:	8204f503          	.insn	4, 0x8204f503
    2050:	0306                	.insn	2, 0x0306
    2052:	04097b8b          	.insn	4, 0x04097b8b
    2056:	0100                	.insn	2, 0x0100
    2058:	2405                	.insn	2, 0x2405
    205a:	0306                	.insn	2, 0x0306
    205c:	740804f7          	.insn	4, 0x740804f7
    2060:	0d05                	.insn	2, 0x0d05
    2062:	8206                	.insn	2, 0x8206
    2064:	2005                	.insn	2, 0x2005
    2066:	0306                	.insn	2, 0x0306
    2068:	0901                	.insn	2, 0x0901
    206a:	0004                	.insn	2, 0x0004
    206c:	0501                	.insn	2, 0x0501
    206e:	0312                	.insn	2, 0x0312
    2070:	034a7fab          	.insn	4, 0x034a7fab
    2074:	00080903          	lb	s2,0(a6)
    2078:	0501                	.insn	2, 0x0501
    207a:	0318                	.insn	2, 0x0318
    207c:	0901                	.insn	2, 0x0901
    207e:	0008                	.insn	2, 0x0008
    2080:	0501                	.insn	2, 0x0501
    2082:	00d60317          	auipc	t1,0xd60
    2086:	054a                	.insn	2, 0x054a
    2088:	0322                	.insn	2, 0x0322
    208a:	0901                	.insn	2, 0x0901
    208c:	0004                	.insn	2, 0x0004
    208e:	0501                	.insn	2, 0x0501
    2090:	4b1e                	.insn	2, 0x4b1e
    2092:	2805                	.insn	2, 0x2805
    2094:	0549                	.insn	2, 0x0549
    2096:	03064d23          	.insn	4, 0x03064d23
    209a:	7aff                	.insn	2, 0x7aff
    209c:	0409                	.insn	2, 0x0409
    209e:	0100                	.insn	2, 0x0100
    20a0:	1905                	.insn	2, 0x1905
    20a2:	0306                	.insn	2, 0x0306
    20a4:	0582                	.insn	2, 0x0582
    20a6:	054a                	.insn	2, 0x054a
    20a8:	0624                	.insn	2, 0x0624
    20aa:	0582                	.insn	2, 0x0582
    20ac:	061e                	.insn	2, 0x061e
    20ae:	fd03064b          	.insn	4, 0xfd03064b
    20b2:	4a7a                	.insn	2, 0x4a7a
    20b4:	1505                	.insn	2, 0x1505
    20b6:	0306                	.insn	2, 0x0306
    20b8:	054a0587          	.insn	4, 0x054a0587
    20bc:	0312                	.insn	2, 0x0312
    20be:	7fa2                	.insn	2, 0x7fa2
    20c0:	064a                	.insn	2, 0x064a
    20c2:	097bd703          	lhu	a4,151(s7)
    20c6:	0008                	.insn	2, 0x0008
    20c8:	0501                	.insn	2, 0x0501
    20ca:	fd030617          	auipc	a2,0xfd030
    20ce:	4a04                	.insn	2, 0x4a04
    20d0:	2305                	.insn	2, 0x2305
    20d2:	04090c03          	lb	s8,64(s2)
    20d6:	0100                	.insn	2, 0x0100
    20d8:	0306                	.insn	2, 0x0306
    20da:	08097af7          	.insn	4, 0x08097af7
    20de:	0100                	.insn	2, 0x0100
    20e0:	1405                	.insn	2, 0x1405
    20e2:	0306                	.insn	2, 0x0306
    20e4:	0595                	.insn	2, 0x0595
    20e6:	1009                	.insn	2, 0x1009
    20e8:	0100                	.insn	2, 0x0100
    20ea:	0306                	.insn	2, 0x0306
    20ec:	08097aeb          	.insn	4, 0x08097aeb
    20f0:	0100                	.insn	2, 0x0100
    20f2:	1b05                	.insn	2, 0x1b05
    20f4:	0306                	.insn	2, 0x0306
    20f6:	054a01fb          	.insn	4, 0x054a01fb
    20fa:	5109                	.insn	2, 0x5109
    20fc:	3905                	.insn	2, 0x3905
    20fe:	05827903          	.insn	4, 0x05827903
    2102:	054a062b          	.insn	4, 0x054a062b
    2106:	0609                	.insn	2, 0x0609
    2108:	0651                	.insn	2, 0x0651
    210a:	097dfe03          	.insn	4, 0x097dfe03
    210e:	0010                	.insn	2, 0x0010
    2110:	0501                	.insn	2, 0x0501
    2112:	0626                	.insn	2, 0x0626
    2114:	f201fc03          	.insn	4, 0xf201fc03
    2118:	0306                	.insn	2, 0x0306
    211a:	7e84                	.insn	2, 0x7e84
    211c:	0582                	.insn	2, 0x0582
    211e:	0612                	.insn	2, 0x0612
    2120:	4a028503          	lb	a0,1184(t0)
    2124:	1705                	.insn	2, 0x1705
    2126:	4a7e9603          	lh	a2,1191(t4)
    212a:	4c49                	.insn	2, 0x4c49
    212c:	0d05                	.insn	2, 0x0d05
    212e:	481c054b          	.insn	4, 0x481c054b
    2132:	1d05                	.insn	2, 0x1d05
    2134:	0549                	.insn	2, 0x0549
    2136:	4c1c                	.insn	2, 0x4c1c
    2138:	0a05                	.insn	2, 0x0a05
    213a:	4a01ea03          	.insn	4, 0x4a01ea03
    213e:	2205                	.insn	2, 0x2205
    2140:	4a7e9503          	lh	a0,1191(t4)
    2144:	0a05                	.insn	2, 0x0a05
    2146:	4a01eb03          	.insn	4, 0x4a01eb03
    214a:	0306                	.insn	2, 0x0306
    214c:	7dfa                	.insn	2, 0x7dfa
    214e:	0582                	.insn	2, 0x0582
    2150:	0615                	.insn	2, 0x0615
    2152:	0804d903          	lhu	s2,128(s1)
    2156:	06e4                	.insn	2, 0x06e4
    2158:	097ba703          	lw	a4,151(s7)
    215c:	0004                	.insn	2, 0x0004
    215e:	0501                	.insn	2, 0x0501
    2160:	9b030613          	addi	a2,t1,-1616 # d61a32 <_stack_top+0xc55a72>
    2164:	0805                	.insn	2, 0x0805
    2166:	0674                	.insn	2, 0x0674
    2168:	097ae503          	.insn	4, 0x097ae503
    216c:	0004                	.insn	2, 0x0004
    216e:	0501                	.insn	2, 0x0501
    2170:	0609                	.insn	2, 0x0609
    2172:	0205a003          	lw	zero,32(a1)
    2176:	0128                	.insn	2, 0x0128
    2178:	0306                	.insn	2, 0x0306
    217a:	7ae0                	.insn	2, 0x7ae0
    217c:	0409                	.insn	2, 0x0409
    217e:	0100                	.insn	2, 0x0100
    2180:	1705                	.insn	2, 0x1705
    2182:	0306                	.insn	2, 0x0306
    2184:	05a1                	.insn	2, 0x05a1
    2186:	054a                	.insn	2, 0x054a
    2188:	0609                	.insn	2, 0x0609
    218a:	034a                	.insn	2, 0x034a
    218c:	7adf 054a 0615      	.insn	6, 0x0615054a7adf
    2192:	ba04de03          	lhu	t3,-1120(s1)
    2196:	0306                	.insn	2, 0x0306
    2198:	7ba2                	.insn	2, 0x7ba2
    219a:	054a                	.insn	2, 0x054a
    219c:	0609                	.insn	2, 0x0609
    219e:	f205a003          	lw	zero,-224(a1)
    21a2:	0402                	.insn	2, 0x0402
    21a4:	0100                	.insn	2, 0x0100
    21a6:	01                	.byte	0x01

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
  32:	2e00736f          	jal	t1,7312 <_start-0xf8cee>
  36:	6372732f          	.insn	4, 0x6372732f
  3a:	6f6f622f          	.insn	4, 0x6f6f622f
  3e:	6c74                	.insn	2, 0x6c74
  40:	6564616f          	jal	sp,46696 <_start-0xb996a>
  44:	5f72                	.insn	2, 0x5f72
  46:	6e65                	.insn	2, 0x6e65
  48:	7274                	.insn	2, 0x7274
  4a:	2e79                	.insn	2, 0x2e79
  4c:	2f2e0053          	.insn	4, 0x2f2e0053
  50:	00637273          	csrrci	tp,0x6,6
  54:	7273752f          	.insn	4, 0x7273752f
  58:	62696c2f          	.insn	4, 0x62696c2f
  5c:	766c6c2f          	.insn	4, 0x766c6c2f
  60:	2d6d                	.insn	2, 0x2d6d
  62:	3132                	.insn	2, 0x3132
  64:	62696c2f          	.insn	4, 0x62696c2f
  68:	616c632f          	.insn	4, 0x616c632f
  6c:	676e                	.insn	2, 0x676e
  6e:	2f31322f          	.insn	4, 0x2f31322f
  72:	6e69                	.insn	2, 0x6e69
  74:	64756c63          	bltu	a0,t2,6cc <_start-0xff934>
  78:	0065                	.insn	2, 0x0065
  7a:	2f637273          	csrrci	tp,0x2f6,6
  7e:	6f62                	.insn	2, 0x6f62
  80:	6f6c746f          	jal	s0,c7776 <_start-0x3888a>
  84:	6461                	.insn	2, 0x6461
  86:	7265                	.insn	2, 0x7265
  88:	665f 7461 3233      	.insn	6, 0x32337461665f
  8e:	632e                	.insn	2, 0x632e
  90:	6300                	.insn	2, 0x6300
  92:	6f6d6d6f          	jal	s10,d6788 <_start-0x29878>
  96:	2e6e                	.insn	2, 0x2e6e
  98:	0068                	.insn	2, 0x0068
  9a:	6f62                	.insn	2, 0x6f62
  9c:	665f746f          	jal	s0,f7f00 <_start-0x8100>
  a0:	7461                	.insn	2, 0x7461
  a2:	682e3233          	.insn	4, 0x682e3233
  a6:	7300                	.insn	2, 0x7300
  a8:	6474                	.insn	2, 0x6474
  aa:	6e69                	.insn	2, 0x6e69
  ac:	2e74                	.insn	2, 0x2e74
  ae:	0068                	.insn	2, 0x0068
  b0:	2f637273          	csrrci	tp,0x2f6,6
  b4:	6d6d6f63          	bltu	s10,s6,792 <_start-0xff86e>
  b8:	632e6e6f          	jal	t3,e66ea <_start-0x19916>
  bc:	7300                	.insn	2, 0x7300
  be:	6372                	.insn	2, 0x6372
  c0:	6364732f          	.insn	4, 0x6364732f
  c4:	7261                	.insn	2, 0x7261
  c6:	5f64                	.insn	2, 0x5f64
  c8:	7061                	.insn	2, 0x7061
  ca:	2e69                	.insn	2, 0x2e69
  cc:	656b0063          	beq	s6,s6,70c <_start-0xff8f4>
  d0:	6e72                	.insn	2, 0x6e72
  d2:	6c65                	.insn	2, 0x6c65
  d4:	682e                	.insn	2, 0x682e
  d6:	7300                	.insn	2, 0x7300
  d8:	6372                	.insn	2, 0x6372
  da:	6f6f622f          	.insn	4, 0x6f6f622f
  de:	5f74                	.insn	2, 0x5f74
  e0:	6166                	.insn	2, 0x6166
  e2:	3374                	.insn	2, 0x3374
  e4:	2e32                	.insn	2, 0x2e32
  e6:	0063                	.short	0x0063

Disassembly of section .debug_loclists:

00000000 <.debug_loclists>:
       0:	0945                	.insn	2, 0x0945
       2:	0000                	.insn	2, 0x0000
       4:	0005                	.insn	2, 0x0005
       6:	0004                	.insn	2, 0x0004
       8:	0035                	.insn	2, 0x0035
       a:	0000                	.insn	2, 0x0000
       c:	00d4                	.insn	2, 0x00d4
       e:	0000                	.insn	2, 0x0000
      10:	00dc                	.insn	2, 0x00dc
      12:	0000                	.insn	2, 0x0000
      14:	00fa                	.insn	2, 0x00fa
      16:	0000                	.insn	2, 0x0000
      18:	0102                	.insn	2, 0x0102
      1a:	0000                	.insn	2, 0x0000
      1c:	0120                	.insn	2, 0x0120
      1e:	0000                	.insn	2, 0x0000
      20:	00000133          	add	sp,zero,zero
      24:	0151                	.insn	2, 0x0151
      26:	0000                	.insn	2, 0x0000
      28:	0000016f          	jal	sp,28 <_start-0xfffd8>
      2c:	00000177          	.insn	4, 0x0177
      30:	017f 0000 0187 0000 	.insn	10, 0x018f000001870000017f
      38:	018f 
      3a:	0000                	.insn	2, 0x0000
      3c:	00000197          	auipc	gp,0x0
      40:	01ad                	.insn	2, 0x01ad
      42:	0000                	.insn	2, 0x0000
      44:	01ca                	.insn	2, 0x01ca
      46:	0000                	.insn	2, 0x0000
      48:	01e8                	.insn	2, 0x01e8
      4a:	0000                	.insn	2, 0x0000
      4c:	0395                	.insn	2, 0x0395
      4e:	0000                	.insn	2, 0x0000
      50:	0542                	.insn	2, 0x0542
      52:	0000                	.insn	2, 0x0000
      54:	0585                	.insn	2, 0x0585
      56:	0000                	.insn	2, 0x0000
      58:	0630                	.insn	2, 0x0630
      5a:	0000                	.insn	2, 0x0000
      5c:	0000063f 0000066a 	.insn	8, 0x066a0000063f
      64:	06bc                	.insn	2, 0x06bc
      66:	0000                	.insn	2, 0x0000
      68:	06c4                	.insn	2, 0x06c4
      6a:	0000                	.insn	2, 0x0000
      6c:	06cc                	.insn	2, 0x06cc
      6e:	0000                	.insn	2, 0x0000
      70:	06e2                	.insn	2, 0x06e2
      72:	0000                	.insn	2, 0x0000
      74:	06f1                	.insn	2, 0x06f1
      76:	0000                	.insn	2, 0x0000
      78:	06f9                	.insn	2, 0x06f9
      7a:	0000                	.insn	2, 0x0000
      7c:	0708                	.insn	2, 0x0708
      7e:	0000                	.insn	2, 0x0000
      80:	00000717          	auipc	a4,0x0
      84:	0000073f 00000774 	.insn	8, 0x07740000073f
      8c:	0799                	.insn	2, 0x0799
      8e:	0000                	.insn	2, 0x0000
      90:	07b5                	.insn	2, 0x07b5
      92:	0000                	.insn	2, 0x0000
      94:	07c4                	.insn	2, 0x07c4
      96:	0000                	.insn	2, 0x0000
      98:	000007d3          	.insn	4, 0x07d3
      9c:	000007fb          	.insn	4, 0x07fb
      a0:	0830                	.insn	2, 0x0830
      a2:	0000                	.insn	2, 0x0000
      a4:	0855                	.insn	2, 0x0855
      a6:	0000                	.insn	2, 0x0000
      a8:	0871                	.insn	2, 0x0871
      aa:	0000                	.insn	2, 0x0000
      ac:	0880                	.insn	2, 0x0880
      ae:	0000                	.insn	2, 0x0000
      b0:	0000088f          	.insn	4, 0x088f
      b4:	08ad                	.insn	2, 0x08ad
      b6:	0000                	.insn	2, 0x0000
      b8:	08b5                	.insn	2, 0x08b5
      ba:	0000                	.insn	2, 0x0000
      bc:	08c4                	.insn	2, 0x08c4
      be:	0000                	.insn	2, 0x0000
      c0:	000008d3          	.insn	4, 0x08d3
      c4:	000008db          	.insn	4, 0x08db
      c8:	08ea                	.insn	2, 0x08ea
      ca:	0000                	.insn	2, 0x0000
      cc:	08f9                	.insn	2, 0x08f9
      ce:	0000                	.insn	2, 0x0000
      d0:	0901                	.insn	2, 0x0901
      d2:	0000                	.insn	2, 0x0000
      d4:	0910                	.insn	2, 0x0910
      d6:	0000                	.insn	2, 0x0000
      d8:	091f 0000 092e      	.insn	6, 0x092e0000091f
      de:	0000                	.insn	2, 0x0000
      e0:	9004                	.insn	2, 0x9004
      e2:	9c01                	.insn	2, 0x9c01
      e4:	0101                	.insn	2, 0x0101
      e6:	005e                	.insn	2, 0x005e
      e8:	ac04                	.insn	2, 0xac04
      ea:	b001                	.insn	2, 0xb001
      ec:	0e01                	.insn	2, 0x0e01
      ee:	9c11007b          	.insn	4, 0x9c11007b
      f2:	7f111c7f 00e3111e 	.insn	12, 0xb4049f2200e3111e7f111c7f
      fa:	b4049f22 
      fe:	b801                	.insn	2, 0xb801
     100:	0301                	.insn	2, 0x0301
     102:	009f7f7b          	.insn	4, 0x009f7f7b
     106:	e804                	.insn	2, 0xe804
     108:	f401                	.insn	2, 0xf401
     10a:	0101                	.insn	2, 0x0101
     10c:	0060                	.insn	2, 0x0060
     10e:	8004                	.insn	2, 0x8004
     110:	8402                	.insn	2, 0x8402
     112:	0e02                	.insn	2, 0x0e02
     114:	9c11007b          	.insn	4, 0x9c11007b
     118:	7f111c7f 00e3111e 	.insn	12, 0x88049f2200e3111e7f111c7f
     120:	88049f22 
     124:	8c02                	.insn	2, 0x8c02
     126:	0302                	.insn	2, 0x0302
     128:	009f7f7b          	.insn	4, 0x009f7f7b
     12c:	8c04                	.insn	2, 0x8c04
     12e:	a002                	.insn	2, 0xa002
     130:	0502                	.insn	2, 0x0502
     132:	d010                	.insn	2, 0xd010
     134:	0386                	.insn	2, 0x0386
     136:	049f 02a4 02c8      	.insn	6, 0x02c802a4049f
     13c:	5b01                	.insn	2, 0x5b01
     13e:	0400                	.insn	2, 0x0400
     140:	02a4                	.insn	2, 0x02a4
     142:	02a8                	.insn	2, 0x02a8
     144:	7c0e                	.insn	2, 0x7c0e
     146:	1100                	.insn	2, 0x1100
     148:	7f9c                	.insn	2, 0x7f9c
     14a:	111c                	.insn	2, 0x111c
     14c:	e3111e7f 049f2200 	.insn	12, 0x02b002ac049f2200e3111e7f
     154:	02b002ac 
     158:	9f7f7c03          	.insn	4, 0x9f7f7c03
     15c:	0400                	.insn	2, 0x0400
     15e:	02cc                	.insn	2, 0x02cc
     160:	02d0                	.insn	2, 0x02d0
     162:	7a0e                	.insn	2, 0x7a0e
     164:	1100                	.insn	2, 0x1100
     166:	7f9c                	.insn	2, 0x7f9c
     168:	111c                	.insn	2, 0x111c
     16a:	e3111e7f 049f2200 	.insn	12, 0x02d802d4049f2200e3111e7f
     172:	02d802d4 
     176:	9f7f7a03          	.insn	4, 0x9f7f7a03
     17a:	0400                	.insn	2, 0x0400
     17c:	03a0                	.insn	2, 0x03a0
     17e:	03ac                	.insn	2, 0x03ac
     180:	5f01                	.insn	2, 0x5f01
     182:	0400                	.insn	2, 0x0400
     184:	0480                	.insn	2, 0x0480
     186:	048c                	.insn	2, 0x048c
     188:	5f01                	.insn	2, 0x5f01
     18a:	0400                	.insn	2, 0x0400
     18c:	04c4                	.insn	2, 0x04c4
     18e:	04d0                	.insn	2, 0x04d0
     190:	5f01                	.insn	2, 0x5f01
     192:	0400                	.insn	2, 0x0400
     194:	0584                	.insn	2, 0x0584
     196:	0590                	.insn	2, 0x0590
     198:	5f01                	.insn	2, 0x5f01
     19a:	0400                	.insn	2, 0x0400
     19c:	05e8                	.insn	2, 0x05e8
     19e:	05f4                	.insn	2, 0x05f4
     1a0:	5f01                	.insn	2, 0x5f01
     1a2:	0400                	.insn	2, 0x0400
     1a4:	08d8                	.insn	2, 0x08d8
     1a6:	1698                	.insn	2, 0x1698
     1a8:	5a01                	.insn	2, 0x5a01
     1aa:	ac04                	.insn	2, 0xac04
     1ac:	bc16                	.insn	2, 0xbc16
     1ae:	045a0117          	auipc	sp,0x45a0
     1b2:	18a8                	.insn	2, 0x18a8
     1b4:	18ac                	.insn	2, 0x18ac
     1b6:	5a01                	.insn	2, 0x5a01
     1b8:	0400                	.insn	2, 0x0400
     1ba:	08d8                	.insn	2, 0x08d8
     1bc:	13fc                	.insn	2, 0x13fc
     1be:	5b01                	.insn	2, 0x5b01
     1c0:	8804                	.insn	2, 0x8804
     1c2:	8c15                	.insn	2, 0x8c15
     1c4:	0115                	.insn	2, 0x0115
     1c6:	16ac045b          	.insn	4, 0x16ac045b
     1ca:	16b0                	.insn	2, 0x16b0
     1cc:	5b01                	.insn	2, 0x5b01
     1ce:	a804                	.insn	2, 0xa804
     1d0:	b018                	.insn	2, 0xb018
     1d2:	0118                	.insn	2, 0x0118
     1d4:	8c04005b          	.insn	4, 0x8c04005b
     1d8:	e009                	.insn	2, 0xe009
     1da:	0209                	.insn	2, 0x0209
     1dc:	9f30                	.insn	2, 0x9f30
     1de:	e004                	.insn	2, 0xe004
     1e0:	f809                	.insn	2, 0xf809
     1e2:	045d0113          	addi	sp,s10,69
     1e6:	16ac                	.insn	2, 0x16ac
     1e8:	16b8                	.insn	2, 0x16b8
     1ea:	5d01                	.insn	2, 0x5d01
     1ec:	a804                	.insn	2, 0xa804
     1ee:	b018                	.insn	2, 0xb018
     1f0:	0118                	.insn	2, 0x0118
     1f2:	005d                	.insn	2, 0x005d
     1f4:	e404                	.insn	2, 0xe404
     1f6:	e809                	.insn	2, 0xe809
     1f8:	0309                	.insn	2, 0x0309
     1fa:	3110                	.insn	2, 0x3110
     1fc:	049f 09e8 09ec      	.insn	6, 0x09ec09e8049f
     202:	9f301003          	lh	zero,-1549(zero) # fffff9f3 <_stack_top+0xffef3a33>
     206:	ec04                	.insn	2, 0xec04
     208:	f009                	.insn	2, 0xf009
     20a:	0309                	.insn	2, 0x0309
     20c:	2f10                	.insn	2, 0x2f10
     20e:	049f 09f0 09f4      	.insn	6, 0x09f409f0049f
     214:	9f2e1003          	lh	zero,-1550(t3)
     218:	f404                	.insn	2, 0xf404
     21a:	f809                	.insn	2, 0xf809
     21c:	0309                	.insn	2, 0x0309
     21e:	2d10                	.insn	2, 0x2d10
     220:	049f 09f8 09fc      	.insn	6, 0x09fc09f8049f
     226:	9f2c1003          	lh	zero,-1550(s8) # 8d0110b4 <_stack_top+0x8cf050f4>
     22a:	fc04                	.insn	2, 0xfc04
     22c:	8009                	.insn	2, 0x8009
     22e:	030a                	.insn	2, 0x030a
     230:	2b10                	.insn	2, 0x2b10
     232:	049f 0a80 0a84      	.insn	6, 0x0a840a80049f
     238:	9f2a1003          	lh	zero,-1550(s4)
     23c:	8404                	.insn	2, 0x8404
     23e:	880a                	.insn	2, 0x880a
     240:	030a                	.insn	2, 0x030a
     242:	2910                	.insn	2, 0x2910
     244:	049f 0a88 0a8c      	.insn	6, 0x0a8c0a88049f
     24a:	9f281003          	lh	zero,-1550(a6)
     24e:	8c04                	.insn	2, 0x8c04
     250:	900a                	.insn	2, 0x900a
     252:	030a                	.insn	2, 0x030a
     254:	2710                	.insn	2, 0x2710
     256:	049f 0a90 0a94      	.insn	6, 0x0a940a90049f
     25c:	9f261003          	lh	zero,-1550(a2) # fd031abc <_stack_top+0xfcf25afc>
     260:	9404                	.insn	2, 0x9404
     262:	980a                	.insn	2, 0x980a
     264:	030a                	.insn	2, 0x030a
     266:	2510                	.insn	2, 0x2510
     268:	049f 0a98 0a9c      	.insn	6, 0x0a9c0a98049f
     26e:	9f241003          	lh	zero,-1550(s0)
     272:	9c04                	.insn	2, 0x9c04
     274:	a00a                	.insn	2, 0xa00a
     276:	030a                	.insn	2, 0x030a
     278:	2310                	.insn	2, 0x2310
     27a:	049f 0aa0 0aa4      	.insn	6, 0x0aa40aa0049f
     280:	9f221003          	lh	zero,-1550(tp) # fffff9f2 <_stack_top+0xffef3a32>
     284:	a404                	.insn	2, 0xa404
     286:	a80a                	.insn	2, 0xa80a
     288:	030a                	.insn	2, 0x030a
     28a:	2110                	.insn	2, 0x2110
     28c:	049f 0aa8 0aac      	.insn	6, 0x0aac0aa8049f
     292:	9f201003          	lh	zero,-1550(zero) # fffff9f2 <_stack_top+0xffef3a32>
     296:	ac04                	.insn	2, 0xac04
     298:	b00a                	.insn	2, 0xb00a
     29a:	020a                	.insn	2, 0x020a
     29c:	b0049f4f          	.insn	4, 0xb0049f4f
     2a0:	b40a                	.insn	2, 0xb40a
     2a2:	020a                	.insn	2, 0x020a
     2a4:	9f4e                	.insn	2, 0x9f4e
     2a6:	b404                	.insn	2, 0xb404
     2a8:	b80a                	.insn	2, 0xb80a
     2aa:	020a                	.insn	2, 0x020a
     2ac:	9f4d                	.insn	2, 0x9f4d
     2ae:	b804                	.insn	2, 0xb804
     2b0:	bc0a                	.insn	2, 0xbc0a
     2b2:	020a                	.insn	2, 0x020a
     2b4:	9f4c                	.insn	2, 0x9f4c
     2b6:	bc04                	.insn	2, 0xbc04
     2b8:	c00a                	.insn	2, 0xc00a
     2ba:	020a                	.insn	2, 0x020a
     2bc:	c0049f4b          	.insn	4, 0xc0049f4b
     2c0:	c40a                	.insn	2, 0xc40a
     2c2:	020a                	.insn	2, 0x020a
     2c4:	9f4a                	.insn	2, 0x9f4a
     2c6:	c404                	.insn	2, 0xc404
     2c8:	c80a                	.insn	2, 0xc80a
     2ca:	020a                	.insn	2, 0x020a
     2cc:	9f49                	.insn	2, 0x9f49
     2ce:	c804                	.insn	2, 0xc804
     2d0:	cc0a                	.insn	2, 0xcc0a
     2d2:	020a                	.insn	2, 0x020a
     2d4:	9f48                	.insn	2, 0x9f48
     2d6:	cc04                	.insn	2, 0xcc04
     2d8:	d00a                	.insn	2, 0xd00a
     2da:	020a                	.insn	2, 0x020a
     2dc:	d0049f47          	.insn	4, 0xd0049f47
     2e0:	d40a                	.insn	2, 0xd40a
     2e2:	020a                	.insn	2, 0x020a
     2e4:	9f46                	.insn	2, 0x9f46
     2e6:	d404                	.insn	2, 0xd404
     2e8:	d80a                	.insn	2, 0xd80a
     2ea:	020a                	.insn	2, 0x020a
     2ec:	9f45                	.insn	2, 0x9f45
     2ee:	d804                	.insn	2, 0xd804
     2f0:	dc0a                	.insn	2, 0xdc0a
     2f2:	020a                	.insn	2, 0x020a
     2f4:	9f44                	.insn	2, 0x9f44
     2f6:	dc04                	.insn	2, 0xdc04
     2f8:	e00a                	.insn	2, 0xe00a
     2fa:	020a                	.insn	2, 0x020a
     2fc:	e0049f43          	.insn	4, 0xe0049f43
     300:	e40a                	.insn	2, 0xe40a
     302:	020a                	.insn	2, 0x020a
     304:	9f42                	.insn	2, 0x9f42
     306:	e404                	.insn	2, 0xe404
     308:	e80a                	.insn	2, 0xe80a
     30a:	020a                	.insn	2, 0x020a
     30c:	9f41                	.insn	2, 0x9f41
     30e:	e804                	.insn	2, 0xe804
     310:	ec0a                	.insn	2, 0xec0a
     312:	020a                	.insn	2, 0x020a
     314:	9f40                	.insn	2, 0x9f40
     316:	ec04                	.insn	2, 0xec04
     318:	f00a                	.insn	2, 0xf00a
     31a:	020a                	.insn	2, 0x020a
     31c:	f0049f3f 020af40a 	.insn	8, 0x020af40af0049f3f
     324:	9f3e                	.insn	2, 0x9f3e
     326:	f404                	.insn	2, 0xf404
     328:	f80a                	.insn	2, 0xf80a
     32a:	020a                	.insn	2, 0x020a
     32c:	9f3d                	.insn	2, 0x9f3d
     32e:	f804                	.insn	2, 0xf804
     330:	fc0a                	.insn	2, 0xfc0a
     332:	020a                	.insn	2, 0x020a
     334:	9f3c                	.insn	2, 0x9f3c
     336:	fc04                	.insn	2, 0xfc04
     338:	800a                	.insn	2, 0x800a
     33a:	9f3b020b          	.insn	4, 0x9f3b020b
     33e:	8004                	.insn	2, 0x8004
     340:	020b840b          	.insn	4, 0x020b840b
     344:	9f3a                	.insn	2, 0x9f3a
     346:	8404                	.insn	2, 0x8404
     348:	020b880b          	.insn	4, 0x020b880b
     34c:	9f39                	.insn	2, 0x9f39
     34e:	8804                	.insn	2, 0x8804
     350:	020b8c0b          	.insn	4, 0x020b8c0b
     354:	9f38                	.insn	2, 0x9f38
     356:	8c04                	.insn	2, 0x8c04
     358:	020b900b          	.insn	4, 0x020b900b
     35c:	90049f37          	lui	t5,0x90049
     360:	020b940b          	.insn	4, 0x020b940b
     364:	9f36                	.insn	2, 0x9f36
     366:	9404                	.insn	2, 0x9404
     368:	020b980b          	.insn	4, 0x020b980b
     36c:	9f35                	.insn	2, 0x9f35
     36e:	9804                	.insn	2, 0x9804
     370:	020b9c0b          	.insn	4, 0x020b9c0b
     374:	9f34                	.insn	2, 0x9f34
     376:	9c04                	.insn	2, 0x9c04
     378:	020ba00b          	.insn	4, 0x020ba00b
     37c:	a0049f33          	.insn	4, 0xa0049f33
     380:	020ba40b          	.insn	4, 0x020ba40b
     384:	9f32                	.insn	2, 0x9f32
     386:	a404                	.insn	2, 0xa404
     388:	020ba80b          	.insn	4, 0x020ba80b
     38c:	9f31                	.insn	2, 0x9f31
     38e:	a804                	.insn	2, 0xa804
     390:	020bac0b          	.insn	4, 0x020bac0b
     394:	9f30                	.insn	2, 0x9f30
     396:	ac04                	.insn	2, 0xac04
     398:	040d880b          	.insn	4, 0x040d880b
     39c:	3130                	.insn	2, 0x3130
     39e:	9f1c                	.insn	2, 0x9f1c
     3a0:	0400                	.insn	2, 0x0400
     3a2:	0bb4                	.insn	2, 0x0bb4
     3a4:	0bb8                	.insn	2, 0x0bb8
     3a6:	9f311003          	lh	zero,-1549(sp) # 459fba1 <_stack_top+0x4493be1>
     3aa:	b804                	.insn	2, 0xb804
     3ac:	030bbc0b          	.insn	4, 0x030bbc0b
     3b0:	3010                	.insn	2, 0x3010
     3b2:	049f 0bbc 0bc0      	.insn	6, 0x0bc00bbc049f
     3b8:	9f2f1003          	lh	zero,-1550(t5) # 900489f2 <_stack_top+0x8ff3ca32>
     3bc:	c004                	.insn	2, 0xc004
     3be:	030bc40b          	.insn	4, 0x030bc40b
     3c2:	2e10                	.insn	2, 0x2e10
     3c4:	049f 0bc4 0bc8      	.insn	6, 0x0bc80bc4049f
     3ca:	9f2d1003          	lh	zero,-1550(s10)
     3ce:	c804                	.insn	2, 0xc804
     3d0:	030bcc0b          	.insn	4, 0x030bcc0b
     3d4:	2c10                	.insn	2, 0x2c10
     3d6:	049f 0bcc 0bd0      	.insn	6, 0x0bd00bcc049f
     3dc:	9f2b1003          	lh	zero,-1550(s6) # 16055302 <_stack_top+0x15f49342>
     3e0:	d004                	.insn	2, 0xd004
     3e2:	030bd40b          	.insn	4, 0x030bd40b
     3e6:	2a10                	.insn	2, 0x2a10
     3e8:	049f 0bd4 0bd8      	.insn	6, 0x0bd80bd4049f
     3ee:	9f291003          	lh	zero,-1550(s2)
     3f2:	d804                	.insn	2, 0xd804
     3f4:	030bdc0b          	.insn	4, 0x030bdc0b
     3f8:	2810                	.insn	2, 0x2810
     3fa:	049f 0bdc 0be0      	.insn	6, 0x0be00bdc049f
     400:	9f271003          	lh	zero,-1550(a4) # fffffa72 <_stack_top+0xffef3ab2>
     404:	e004                	.insn	2, 0xe004
     406:	030be40b          	.insn	4, 0x030be40b
     40a:	2610                	.insn	2, 0x2610
     40c:	049f 0be4 0be8      	.insn	6, 0x0be80be4049f
     412:	9f251003          	lh	zero,-1550(a0) # 632f9f2 <_stack_top+0x6223a32>
     416:	e804                	.insn	2, 0xe804
     418:	030bec0b          	.insn	4, 0x030bec0b
     41c:	2410                	.insn	2, 0x2410
     41e:	049f 0bec 0bf0      	.insn	6, 0x0bf00bec049f
     424:	9f231003          	lh	zero,-1550(t1)
     428:	f004                	.insn	2, 0xf004
     42a:	030bf40b          	.insn	4, 0x030bf40b
     42e:	2210                	.insn	2, 0x2210
     430:	049f 0bf4 0bf8      	.insn	6, 0x0bf80bf4049f
     436:	9f211003          	lh	zero,-1550(sp)
     43a:	f804                	.insn	2, 0xf804
     43c:	030bfc0b          	.insn	4, 0x030bfc0b
     440:	2010                	.insn	2, 0x2010
     442:	049f 0bfc 0c80      	.insn	6, 0x0c800bfc049f
     448:	4f02                	.insn	2, 0x4f02
     44a:	049f 0c80 0c84      	.insn	6, 0x0c840c80049f
     450:	4e02                	.insn	2, 0x4e02
     452:	049f 0c84 0c88      	.insn	6, 0x0c880c84049f
     458:	4d02                	.insn	2, 0x4d02
     45a:	049f 0c88 0c8c      	.insn	6, 0x0c8c0c88049f
     460:	4c02                	.insn	2, 0x4c02
     462:	049f 0c8c 0c90      	.insn	6, 0x0c900c8c049f
     468:	4b02                	.insn	2, 0x4b02
     46a:	049f 0c90 0c94      	.insn	6, 0x0c940c90049f
     470:	4a02                	.insn	2, 0x4a02
     472:	049f 0c94 0c98      	.insn	6, 0x0c980c94049f
     478:	4902                	.insn	2, 0x4902
     47a:	049f 0c98 0c9c      	.insn	6, 0x0c9c0c98049f
     480:	4802                	.insn	2, 0x4802
     482:	049f 0c9c 0ca0      	.insn	6, 0x0ca00c9c049f
     488:	4702                	.insn	2, 0x4702
     48a:	049f 0ca0 0ca4      	.insn	6, 0x0ca40ca0049f
     490:	4602                	.insn	2, 0x4602
     492:	049f 0ca4 0ca8      	.insn	6, 0x0ca80ca4049f
     498:	4502                	.insn	2, 0x4502
     49a:	049f 0ca8 0cac      	.insn	6, 0x0cac0ca8049f
     4a0:	4402                	.insn	2, 0x4402
     4a2:	049f 0cac 0cb0      	.insn	6, 0x0cb00cac049f
     4a8:	4302                	.insn	2, 0x4302
     4aa:	049f 0cb0 0cb4      	.insn	6, 0x0cb40cb0049f
     4b0:	4202                	.insn	2, 0x4202
     4b2:	049f 0cb4 0cb8      	.insn	6, 0x0cb80cb4049f
     4b8:	4102                	.insn	2, 0x4102
     4ba:	049f 0cb8 0cbc      	.insn	6, 0x0cbc0cb8049f
     4c0:	4002                	.insn	2, 0x4002
     4c2:	049f 0cbc 0cc0      	.insn	6, 0x0cc00cbc049f
     4c8:	3f02                	.insn	2, 0x3f02
     4ca:	049f 0cc0 0cc4      	.insn	6, 0x0cc40cc0049f
     4d0:	3e02                	.insn	2, 0x3e02
     4d2:	049f 0cc4 0cc8      	.insn	6, 0x0cc80cc4049f
     4d8:	3d02                	.insn	2, 0x3d02
     4da:	049f 0cc8 0ccc      	.insn	6, 0x0ccc0cc8049f
     4e0:	3c02                	.insn	2, 0x3c02
     4e2:	049f 0ccc 0cd0      	.insn	6, 0x0cd00ccc049f
     4e8:	3b02                	.insn	2, 0x3b02
     4ea:	049f 0cd0 0cd4      	.insn	6, 0x0cd40cd0049f
     4f0:	3a02                	.insn	2, 0x3a02
     4f2:	049f 0cd4 0cd8      	.insn	6, 0x0cd80cd4049f
     4f8:	3902                	.insn	2, 0x3902
     4fa:	049f 0cd8 0cdc      	.insn	6, 0x0cdc0cd8049f
     500:	3802                	.insn	2, 0x3802
     502:	049f 0cdc 0ce0      	.insn	6, 0x0ce00cdc049f
     508:	3702                	.insn	2, 0x3702
     50a:	049f 0ce0 0ce4      	.insn	6, 0x0ce40ce0049f
     510:	3602                	.insn	2, 0x3602
     512:	049f 0ce4 0ce8      	.insn	6, 0x0ce80ce4049f
     518:	3502                	.insn	2, 0x3502
     51a:	049f 0ce8 0cec      	.insn	6, 0x0cec0ce8049f
     520:	3402                	.insn	2, 0x3402
     522:	049f 0cec 0cf0      	.insn	6, 0x0cf00cec049f
     528:	3302                	.insn	2, 0x3302
     52a:	049f 0cf0 0cf4      	.insn	6, 0x0cf40cf0049f
     530:	3202                	.insn	2, 0x3202
     532:	049f 0cf4 0cf8      	.insn	6, 0x0cf80cf4049f
     538:	3102                	.insn	2, 0x3102
     53a:	049f 0cf8 0cfc      	.insn	6, 0x0cfc0cf8049f
     540:	3002                	.insn	2, 0x3002
     542:	049f 0cfc 0d88      	.insn	6, 0x0d880cfc049f
     548:	3004                	.insn	2, 0x3004
     54a:	1c31                	.insn	2, 0x1c31
     54c:	009f fc04 8c0c      	.insn	6, 0x8c0cfc04009f
     552:	050d                	.insn	2, 0x050d
     554:	d010                	.insn	2, 0xd010
     556:	0386                	.insn	2, 0x0386
     558:	049f 0d8c 0d90      	.insn	6, 0x0d900d8c049f
     55e:	8610                	.insn	2, 0x8610
     560:	1100                	.insn	2, 0x1100
     562:	f9b0                	.insn	2, 0xf9b0
     564:	1c7c                	.insn	2, 0x1c7c
     566:	7f11                	.insn	2, 0x7f11
     568:	111e                	.insn	2, 0x111e
     56a:	220386cf          	.insn	4, 0x220386cf
     56e:	049f 0e90 0ea0      	.insn	6, 0x0ea00e90049f
     574:	1005                	.insn	2, 0x1005
     576:	86d0                	.insn	2, 0x86d0
     578:	a0049f03          	lh	t5,-1536(s1)
     57c:	a40e                	.insn	2, 0xa40e
     57e:	100e                	.insn	2, 0x100e
     580:	b0110087          	.insn	4, 0xb0110087
     584:	7cf9                	.insn	2, 0x7cf9
     586:	111c                	.insn	2, 0x111c
     588:	cf111e7f 9f220386 	.insn	12, 0x0da804009f220386cf111e7f
     590:	0da80400 
     594:	0dac                	.insn	2, 0x0dac
     596:	4302                	.insn	2, 0x4302
     598:	049f 0dac 0db0      	.insn	6, 0x0db00dac049f
     59e:	4202                	.insn	2, 0x4202
     5a0:	049f 0db0 0db4      	.insn	6, 0x0db40db0049f
     5a6:	4102                	.insn	2, 0x4102
     5a8:	049f 0db4 0db8      	.insn	6, 0x0db80db4049f
     5ae:	4002                	.insn	2, 0x4002
     5b0:	049f 0db8 0dbc      	.insn	6, 0x0dbc0db8049f
     5b6:	3f02                	.insn	2, 0x3f02
     5b8:	049f 0dbc 0dc0      	.insn	6, 0x0dc00dbc049f
     5be:	3e02                	.insn	2, 0x3e02
     5c0:	049f 0dc0 0dc4      	.insn	6, 0x0dc40dc0049f
     5c6:	3d02                	.insn	2, 0x3d02
     5c8:	049f 0dc4 0dc8      	.insn	6, 0x0dc80dc4049f
     5ce:	3c02                	.insn	2, 0x3c02
     5d0:	049f 0dc8 0dcc      	.insn	6, 0x0dcc0dc8049f
     5d6:	3b02                	.insn	2, 0x3b02
     5d8:	049f 0dcc 0dd0      	.insn	6, 0x0dd00dcc049f
     5de:	3a02                	.insn	2, 0x3a02
     5e0:	049f 0dd0 0dd4      	.insn	6, 0x0dd40dd0049f
     5e6:	3902                	.insn	2, 0x3902
     5e8:	049f 0dd4 0dd8      	.insn	6, 0x0dd80dd4049f
     5ee:	3802                	.insn	2, 0x3802
     5f0:	049f 0dd8 0ddc      	.insn	6, 0x0ddc0dd8049f
     5f6:	3702                	.insn	2, 0x3702
     5f8:	049f 0ddc 0de0      	.insn	6, 0x0de00ddc049f
     5fe:	3602                	.insn	2, 0x3602
     600:	049f 0de0 0de4      	.insn	6, 0x0de40de0049f
     606:	3502                	.insn	2, 0x3502
     608:	049f 0de4 0de8      	.insn	6, 0x0de80de4049f
     60e:	3402                	.insn	2, 0x3402
     610:	049f 0de8 0dec      	.insn	6, 0x0dec0de8049f
     616:	3302                	.insn	2, 0x3302
     618:	049f 0dec 0df0      	.insn	6, 0x0df00dec049f
     61e:	3202                	.insn	2, 0x3202
     620:	049f 0df0 0df4      	.insn	6, 0x0df40df0049f
     626:	3102                	.insn	2, 0x3102
     628:	049f 0df4 0df8      	.insn	6, 0x0df80df4049f
     62e:	3002                	.insn	2, 0x3002
     630:	049f 0df8 0dfc      	.insn	6, 0x0dfc0df8049f
     636:	3004                	.insn	2, 0x3004
     638:	1c31                	.insn	2, 0x1c31
     63a:	009f fc04 bc0d      	.insn	6, 0xbc0dfc04009f
     640:	010e                	.insn	2, 0x010e
     642:	0466                	.insn	2, 0x0466
     644:	15a4                	.insn	2, 0x15a4
     646:	16ac                	.insn	2, 0x16ac
     648:	6601                	.insn	2, 0x6601
     64a:	0400                	.insn	2, 0x0400
     64c:	0ec4                	.insn	2, 0x0ec4
     64e:	0ee8                	.insn	2, 0x0ee8
     650:	6701                	.insn	2, 0x6701
     652:	8c04                	.insn	2, 0x8c04
     654:	010f940f          	.insn	4, 0x010f940f
     658:	0468                	.insn	2, 0x0468
     65a:	0f98                	.insn	2, 0x0f98
     65c:	0fa4                	.insn	2, 0x0fa4
     65e:	6901                	.insn	2, 0x6901
     660:	ac04                	.insn	2, 0xac04
     662:	010fbc0f          	.insn	4, 0x010fbc0f
     666:	046a                	.insn	2, 0x046a
     668:	0fc4                	.insn	2, 0x0fc4
     66a:	0fd4                	.insn	2, 0x0fd4
     66c:	6701                	.insn	2, 0x6701
     66e:	f404                	.insn	2, 0xf404
     670:	010ff80f          	.insn	4, 0x010ff80f
     674:	d8040067          	jr	-640(s0)
     678:	8c0e                	.insn	2, 0x8c0e
     67a:	0011030f          	.insn	4, 0x0011030f
     67e:	049f 0f8c 0f98      	.insn	6, 0x0f980f8c049f
     684:	9f011103          	lh	sp,-1552(sp)
     688:	9804                	.insn	2, 0x9804
     68a:	030fa80f          	.insn	4, 0x030fa80f
     68e:	0211                	.insn	2, 0x0211
     690:	049f 0fa8 0fac      	.insn	6, 0x0fac0fa8049f
     696:	9f051103          	lh	sp,-1552(a0)
     69a:	ac04                	.insn	2, 0xac04
     69c:	030fc00f          	.insn	4, 0x030fc00f
     6a0:	0311                	.insn	2, 0x0311
     6a2:	049f 0fc0 0fc4      	.insn	6, 0x0fc40fc0049f
     6a8:	9f061103          	lh	sp,-1552(a2)
     6ac:	c404                	.insn	2, 0xc404
     6ae:	030fd40f          	.insn	4, 0x030fd40f
     6b2:	0411                	.insn	2, 0x0411
     6b4:	049f 0fd4 0ff4      	.insn	6, 0x0ff40fd4049f
     6ba:	9f071103          	lh	sp,-1552(a4)
     6be:	f404                	.insn	2, 0xf404
     6c0:	030ff80f          	.insn	4, 0x030ff80f
     6c4:	0811                	.insn	2, 0x0811
     6c6:	009f f804 800f      	.insn	6, 0x800ff804009f
     6cc:	0110                	.insn	2, 0x0110
     6ce:	fc040067          	jr	-64(s0)
     6d2:	0110840f          	.insn	4, 0x0110840f
     6d6:	0066                	.insn	2, 0x0066
     6d8:	fc04                	.insn	2, 0xfc04
     6da:	0f10840f          	.insn	4, 0x0f10840f
     6de:	0086                	.insn	2, 0x0086
     6e0:	2548                	.insn	2, 0x2548
     6e2:	aba8                	.insn	2, 0xaba8
     6e4:	8080                	.insn	2, 0x8080
     6e6:	a800                	.insn	2, 0xa800
     6e8:	008080af          	.insn	4, 0x008080af
     6ec:	009f 8404 cc10      	.insn	6, 0xcc108404009f
     6f2:	04660113          	addi	sp,a2,70
     6f6:	18a8                	.insn	2, 0x18a8
     6f8:	18b0                	.insn	2, 0x18b0
     6fa:	6601                	.insn	2, 0x6601
     6fc:	0400                	.insn	2, 0x0400
     6fe:	10b0                	.insn	2, 0x10b0
     700:	10bc                	.insn	2, 0x10bc
     702:	6a01                	.insn	2, 0x6a01
     704:	0400                	.insn	2, 0x0400
     706:	10c4                	.insn	2, 0x10c4
     708:	10fc                	.insn	2, 0x10fc
     70a:	6801                	.insn	2, 0x6801
     70c:	fc04                	.insn	2, 0xfc04
     70e:	8410                	.insn	2, 0x8410
     710:	0111                	.insn	2, 0x0111
     712:	0069                	.insn	2, 0x0069
     714:	d004                	.insn	2, 0xd004
     716:	d810                	.insn	2, 0xd810
     718:	0110                	.insn	2, 0x0110
     71a:	0469                	.insn	2, 0x0469
     71c:	10dc                	.insn	2, 0x10dc
     71e:	10e0                	.insn	2, 0x10e0
     720:	6901                	.insn	2, 0x6901
     722:	0400                	.insn	2, 0x0400
     724:	1198                	.insn	2, 0x1198
     726:	11a4                	.insn	2, 0x11a4
     728:	80881007          	.insn	4, 0x80881007
     72c:	8080                	.insn	2, 0x8080
     72e:	9f01                	.insn	2, 0x9f01
     730:	b004                	.insn	2, 0xb004
     732:	bc11                	.insn	2, 0xbc11
     734:	0711                	.insn	2, 0x0711
     736:	8810                	.insn	2, 0x8810
     738:	8080                	.insn	2, 0x8080
     73a:	0180                	.insn	2, 0x0180
     73c:	049f 11c8 11d4      	.insn	6, 0x11d411c8049f
     742:	80881007          	.insn	4, 0x80881007
     746:	8080                	.insn	2, 0x8080
     748:	9f01                	.insn	2, 0x9f01
     74a:	0400                	.insn	2, 0x0400
     74c:	1194                	.insn	2, 0x1194
     74e:	1198                	.insn	2, 0x1198
     750:	80801007          	.insn	4, 0x80801007
     754:	8080                	.insn	2, 0x8080
     756:	9f01                	.insn	2, 0x9f01
     758:	ac04                	.insn	2, 0xac04
     75a:	b011                	.insn	2, 0xb011
     75c:	0711                	.insn	2, 0x0711
     75e:	8010                	.insn	2, 0x8010
     760:	8080                	.insn	2, 0x8080
     762:	0180                	.insn	2, 0x0180
     764:	049f 11c4 11c8      	.insn	6, 0x11c811c4049f
     76a:	80801007          	.insn	4, 0x80801007
     76e:	8080                	.insn	2, 0x8080
     770:	9f01                	.insn	2, 0x9f01
     772:	dc04                	.insn	2, 0xdc04
     774:	e411                	.insn	2, 0xe411
     776:	0711                	.insn	2, 0x0711
     778:	8010                	.insn	2, 0x8010
     77a:	8080                	.insn	2, 0x8080
     77c:	0180                	.insn	2, 0x0180
     77e:	009f 9404 9811      	.insn	6, 0x98119404009f
     784:	0311                	.insn	2, 0x0311
     786:	2010                	.insn	2, 0x2010
     788:	049f 11ac 11b0      	.insn	6, 0x11b011ac049f
     78e:	9f731003          	lh	zero,-1545(t1)
     792:	c404                	.insn	2, 0xc404
     794:	c811                	.insn	2, 0xc811
     796:	0311                	.insn	2, 0x0311
     798:	7710                	.insn	2, 0x7710
     79a:	049f 11dc 11e4      	.insn	6, 0x11e411dc049f
     7a0:	9f3d1003          	lh	zero,-1549(s10)
     7a4:	0400                	.insn	2, 0x0400
     7a6:	1198                	.insn	2, 0x1198
     7a8:	11b0                	.insn	2, 0x11b0
     7aa:	9f731003          	lh	zero,-1545(t1)
     7ae:	b004                	.insn	2, 0xb004
     7b0:	c811                	.insn	2, 0xc811
     7b2:	0311                	.insn	2, 0x0311
     7b4:	7710                	.insn	2, 0x7710
     7b6:	049f 11c8 11e4      	.insn	6, 0x11e411c8049f
     7bc:	9f3d1003          	lh	zero,-1549(s10)
     7c0:	0400                	.insn	2, 0x0400
     7c2:	11e8                	.insn	2, 0x11e8
     7c4:	12a0                	.insn	2, 0x12a0
     7c6:	6801                	.insn	2, 0x6801
     7c8:	a004                	.insn	2, 0xa004
     7ca:	a812                	.insn	2, 0xa812
     7cc:	0112                	.insn	2, 0x0112
     7ce:	0069                	.insn	2, 0x0069
     7d0:	f404                	.insn	2, 0xf404
     7d2:	fc11                	.insn	2, 0xfc11
     7d4:	0111                	.insn	2, 0x0111
     7d6:	0469                	.insn	2, 0x0469
     7d8:	1280                	.insn	2, 0x1280
     7da:	1284                	.insn	2, 0x1284
     7dc:	6901                	.insn	2, 0x6901
     7de:	0400                	.insn	2, 0x0400
     7e0:	12bc                	.insn	2, 0x12bc
     7e2:	12c8                	.insn	2, 0x12c8
     7e4:	80881007          	.insn	4, 0x80881007
     7e8:	8080                	.insn	2, 0x8080
     7ea:	9f01                	.insn	2, 0x9f01
     7ec:	d404                	.insn	2, 0xd404
     7ee:	e012                	.insn	2, 0xe012
     7f0:	0712                	.insn	2, 0x0712
     7f2:	8810                	.insn	2, 0x8810
     7f4:	8080                	.insn	2, 0x8080
     7f6:	0180                	.insn	2, 0x0180
     7f8:	049f 12ec 12f8      	.insn	6, 0x12f812ec049f
     7fe:	80881007          	.insn	4, 0x80881007
     802:	8080                	.insn	2, 0x8080
     804:	9f01                	.insn	2, 0x9f01
     806:	0400                	.insn	2, 0x0400
     808:	12b8                	.insn	2, 0x12b8
     80a:	12bc                	.insn	2, 0x12bc
     80c:	80801007          	.insn	4, 0x80801007
     810:	8080                	.insn	2, 0x8080
     812:	9f01                	.insn	2, 0x9f01
     814:	d004                	.insn	2, 0xd004
     816:	d412                	.insn	2, 0xd412
     818:	0712                	.insn	2, 0x0712
     81a:	8010                	.insn	2, 0x8010
     81c:	8080                	.insn	2, 0x8080
     81e:	0180                	.insn	2, 0x0180
     820:	049f 12e8 12ec      	.insn	6, 0x12ec12e8049f
     826:	80801007          	.insn	4, 0x80801007
     82a:	8080                	.insn	2, 0x8080
     82c:	9f01                	.insn	2, 0x9f01
     82e:	8004                	.insn	2, 0x8004
     830:	07138813          	addi	a6,t2,113
     834:	8010                	.insn	2, 0x8010
     836:	8080                	.insn	2, 0x8080
     838:	0180                	.insn	2, 0x0180
     83a:	009f b804 bc12      	.insn	6, 0xbc12b804009f
     840:	0312                	.insn	2, 0x0312
     842:	2010                	.insn	2, 0x2010
     844:	049f 12d0 12d4      	.insn	6, 0x12d412d0049f
     84a:	9f681003          	lh	zero,-1546(a6)
     84e:	e804                	.insn	2, 0xe804
     850:	ec12                	.insn	2, 0xec12
     852:	0312                	.insn	2, 0x0312
     854:	7710                	.insn	2, 0x7710
     856:	049f 1380 1388      	.insn	6, 0x13881380049f
     85c:	9f3d1003          	lh	zero,-1549(s10)
     860:	0400                	.insn	2, 0x0400
     862:	12bc                	.insn	2, 0x12bc
     864:	12d4                	.insn	2, 0x12d4
     866:	9f681003          	lh	zero,-1546(a6)
     86a:	d404                	.insn	2, 0xd404
     86c:	ec12                	.insn	2, 0xec12
     86e:	0312                	.insn	2, 0x0312
     870:	7710                	.insn	2, 0x7710
     872:	049f 12ec 1388      	.insn	6, 0x138812ec049f
     878:	9f3d1003          	lh	zero,-1549(s10)
     87c:	0400                	.insn	2, 0x0400
     87e:	138c                	.insn	2, 0x138c
     880:	13c4                	.insn	2, 0x13c4
     882:	6701                	.insn	2, 0x6701
     884:	c404                	.insn	2, 0xc404
     886:	0113cc13          	xori	s8,t2,17
     88a:	0068                	.insn	2, 0x0068
     88c:	9804                	.insn	2, 0x9804
     88e:	0113a013          	slti	zero,t2,17
     892:	0468                	.insn	2, 0x0468
     894:	13a4                	.insn	2, 0x13a4
     896:	13a8                	.insn	2, 0x13a8
     898:	6801                	.insn	2, 0x6801
     89a:	0400                	.insn	2, 0x0400
     89c:	13e4                	.insn	2, 0x13e4
     89e:	13e8                	.insn	2, 0x13e8
     8a0:	860e                	.insn	2, 0x860e
     8a2:	1100                	.insn	2, 0x1100
     8a4:	7f9c                	.insn	2, 0x7f9c
     8a6:	111c                	.insn	2, 0x111c
     8a8:	e3111e7f 049f2200 	.insn	12, 0x13f013ec049f2200e3111e7f
     8b0:	13f013ec 
     8b4:	9f7f8603          	lb	a2,-1545(t6)
     8b8:	0400                	.insn	2, 0x0400
     8ba:	14ac                	.insn	2, 0x14ac
     8bc:	14b8                	.insn	2, 0x14b8
     8be:	6101                	.insn	2, 0x6101
     8c0:	0400                	.insn	2, 0x0400
     8c2:	14c8                	.insn	2, 0x14c8
     8c4:	1580                	.insn	2, 0x1580
     8c6:	5e01                	.insn	2, 0x5e01
     8c8:	8004                	.insn	2, 0x8004
     8ca:	8815                	.insn	2, 0x8815
     8cc:	0115                	.insn	2, 0x0115
     8ce:	005f d404 dc14      	.insn	6, 0xdc14d404005f
     8d4:	0114                	.insn	2, 0x0114
     8d6:	045f 14e0 14e4      	.insn	6, 0x14e414e0045f
     8dc:	5f01                	.insn	2, 0x5f01
     8de:	0400                	.insn	2, 0x0400
     8e0:	15bc                	.insn	2, 0x15bc
     8e2:	15c8                	.insn	2, 0x15c8
     8e4:	6101                	.insn	2, 0x6101
     8e6:	0400                	.insn	2, 0x0400
     8e8:	15d8                	.insn	2, 0x15d8
     8ea:	1690                	.insn	2, 0x1690
     8ec:	5e01                	.insn	2, 0x5e01
     8ee:	9004                	.insn	2, 0x9004
     8f0:	9816                	.insn	2, 0x9816
     8f2:	0116                	.insn	2, 0x0116
     8f4:	005f e404 ec15      	.insn	6, 0xec15e404005f
     8fa:	0115                	.insn	2, 0x0115
     8fc:	045f 15f0 15f4      	.insn	6, 0x15f415f0045f
     902:	5f01                	.insn	2, 0x5f01
     904:	0400                	.insn	2, 0x0400
     906:	16e0                	.insn	2, 0x16e0
     908:	16ec                	.insn	2, 0x16ec
     90a:	6101                	.insn	2, 0x6101
     90c:	0400                	.insn	2, 0x0400
     90e:	16fc                	.insn	2, 0x16fc
     910:	17b4                	.insn	2, 0x17b4
     912:	5e01                	.insn	2, 0x5e01
     914:	b404                	.insn	2, 0xb404
     916:	0117bc17          	auipc	s8,0x117b
     91a:	005f 8804 9017      	.insn	6, 0x90178804005f
     920:	045f0117          	auipc	sp,0x45f0
     924:	1794                	.insn	2, 0x1794
     926:	1798                	.insn	2, 0x1798
     928:	5f01                	.insn	2, 0x5f01
     92a:	0400                	.insn	2, 0x0400
     92c:	18c0                	.insn	2, 0x18c0
     92e:	18f8                	.insn	2, 0x18f8
     930:	5d01                	.insn	2, 0x5d01
     932:	f804                	.insn	2, 0xf804
     934:	fc18                	.insn	2, 0xfc18
     936:	0118                	.insn	2, 0x0118
     938:	005e                	.insn	2, 0x005e
     93a:	cc04                	.insn	2, 0xcc04
     93c:	d418                	.insn	2, 0xd418
     93e:	0118                	.insn	2, 0x0118
     940:	045e                	.insn	2, 0x045e
     942:	18d8                	.insn	2, 0x18d8
     944:	18dc                	.insn	2, 0x18dc
     946:	5e01                	.insn	2, 0x5e01
     948:	5e00                	.insn	2, 0x5e00
     94a:	0005                	.insn	2, 0x0005
     94c:	0500                	.insn	2, 0x0500
     94e:	0400                	.insn	2, 0x0400
     950:	3300                	.insn	2, 0x3300
     952:	0000                	.insn	2, 0x0000
     954:	cc00                	.insn	2, 0xcc00
     956:	0000                	.insn	2, 0x0000
     958:	d200                	.insn	2, 0xd200
     95a:	0000                	.insn	2, 0x0000
     95c:	e700                	.insn	2, 0xe700
     95e:	0000                	.insn	2, 0x0000
     960:	ef00                	.insn	2, 0xef00
     962:	0000                	.insn	2, 0x0000
     964:	f500                	.insn	2, 0xf500
     966:	0000                	.insn	2, 0x0000
     968:	fb00                	.insn	2, 0xfb00
     96a:	0000                	.insn	2, 0x0000
     96c:	0800                	.insn	2, 0x0800
     96e:	0001                	.insn	2, 0x0001
     970:	1300                	.insn	2, 0x1300
     972:	0001                	.insn	2, 0x0001
     974:	2800                	.insn	2, 0x2800
     976:	0001                	.insn	2, 0x0001
     978:	3000                	.insn	2, 0x3000
     97a:	0001                	.insn	2, 0x0001
     97c:	4500                	.insn	2, 0x4500
     97e:	0001                	.insn	2, 0x0001
     980:	5d00                	.insn	2, 0x5d00
     982:	0001                	.insn	2, 0x0001
     984:	7a00                	.insn	2, 0x7a00
     986:	0001                	.insn	2, 0x0001
     988:	8900                	.insn	2, 0x8900
     98a:	0001                	.insn	2, 0x0001
     98c:	9800                	.insn	2, 0x9800
     98e:	0001                	.insn	2, 0x0001
     990:	a000                	.insn	2, 0xa000
     992:	0001                	.insn	2, 0x0001
     994:	af00                	.insn	2, 0xaf00
     996:	0001                	.insn	2, 0x0001
     998:	be00                	.insn	2, 0xbe00
     99a:	0001                	.insn	2, 0x0001
     99c:	db00                	.insn	2, 0xdb00
     99e:	0001                	.insn	2, 0x0001
     9a0:	fc00                	.insn	2, 0xfc00
     9a2:	0001                	.insn	2, 0x0001
     9a4:	0400                	.insn	2, 0x0400
     9a6:	0002                	.insn	2, 0x0002
     9a8:	4d00                	.insn	2, 0x4d00
     9aa:	0002                	.insn	2, 0x0002
     9ac:	8600                	.insn	2, 0x8600
     9ae:	0002                	.insn	2, 0x0002
     9b0:	9e00                	.insn	2, 0x9e00
     9b2:	0002                	.insn	2, 0x0002
     9b4:	e600                	.insn	2, 0xe600
     9b6:	0002                	.insn	2, 0x0002
     9b8:	fd00                	.insn	2, 0xfd00
     9ba:	0002                	.insn	2, 0x0002
     9bc:	0c00                	.insn	2, 0x0c00
     9be:	14000003          	lb	zero,320(zero) # 140 <_start-0xffec0>
     9c2:	23000003          	lb	zero,560(zero) # 230 <_start-0xffdd0>
     9c6:	32000003          	lb	zero,800(zero) # 320 <_start-0xffce0>
     9ca:	41000003          	lb	zero,1040(zero) # 410 <_start-0xffbf0>
     9ce:	50000003          	lb	zero,1280(zero) # 500 <_start-0xffb00>
     9d2:	60000003          	lb	zero,1536(zero) # 600 <_start-0xffa00>
     9d6:	6f000003          	lb	zero,1776(zero) # 6f0 <_start-0xff910>
     9da:	c1000003          	lb	zero,-1008(zero) # fffffc10 <_stack_top+0xffef3c50>
     9de:	fa000003          	lb	zero,-96(zero) # ffffffa0 <_stack_top+0xffef3fe0>
     9e2:	03000003          	lb	zero,48(zero) # 30 <_start-0xfffd0>
     9e6:	0004                	.insn	2, 0x0004
     9e8:	0b00                	.insn	2, 0x0b00
     9ea:	0004                	.insn	2, 0x0004
     9ec:	2100                	.insn	2, 0x2100
     9ee:	0004                	.insn	2, 0x0004
     9f0:	3700                	.insn	2, 0x3700
     9f2:	0004                	.insn	2, 0x0004
     9f4:	6500                	.insn	2, 0x6500
     9f6:	0004                	.insn	2, 0x0004
     9f8:	8800                	.insn	2, 0x8800
     9fa:	0004                	.insn	2, 0x0004
     9fc:	c000                	.insn	2, 0xc000
     9fe:	0004                	.insn	2, 0x0004
     a00:	f800                	.insn	2, 0xf800
     a02:	0004                	.insn	2, 0x0004
     a04:	0100                	.insn	2, 0x0100
     a06:	0005                	.insn	2, 0x0005
     a08:	0a00                	.insn	2, 0x0a00
     a0a:	0005                	.insn	2, 0x0005
     a0c:	1900                	.insn	2, 0x1900
     a0e:	0005                	.insn	2, 0x0005
     a10:	2800                	.insn	2, 0x2800
     a12:	0005                	.insn	2, 0x0005
     a14:	3000                	.insn	2, 0x3000
     a16:	0005                	.insn	2, 0x0005
     a18:	3f00                	.insn	2, 0x3f00
     a1a:	0005                	.insn	2, 0x0005
     a1c:	4e00                	.insn	2, 0x4e00
     a1e:	0005                	.insn	2, 0x0005
     a20:	0400                	.insn	2, 0x0400
     a22:	0c00                	.insn	2, 0x0c00
     a24:	5b01                	.insn	2, 0x5b01
     a26:	0400                	.insn	2, 0x0400
     a28:	0c00                	.insn	2, 0x0c00
     a2a:	5a01                	.insn	2, 0x5a01
     a2c:	0c04                	.insn	2, 0x0c04
     a2e:	0118                	.insn	2, 0x0118
     a30:	045d                	.insn	2, 0x045d
     a32:	2018                	.insn	2, 0x2018
     a34:	5f01                	.insn	2, 0x5f01
     a36:	2004                	.insn	2, 0x2004
     a38:	0124                	.insn	2, 0x0124
     a3a:	005d                	.insn	2, 0x005d
     a3c:	0004                	.insn	2, 0x0004
     a3e:	0308                	.insn	2, 0x0308
     a40:	7f7c                	.insn	2, 0x7f7c
     a42:	009f 2804 012c      	.insn	6, 0x012c2804009f
     a48:	005a                	.insn	2, 0x005a
     a4a:	2804                	.insn	2, 0x2804
     a4c:	012c                	.insn	2, 0x012c
     a4e:	2804005b          	.insn	4, 0x2804005b
     a52:	012c                	.insn	2, 0x012c
     a54:	045c                	.insn	2, 0x045c
     a56:	4844                	.insn	2, 0x4844
     a58:	9f7f7c03          	.insn	4, 0x9f7f7c03
     a5c:	0400                	.insn	2, 0x0400
     a5e:	4c28                	.insn	2, 0x4c28
     a60:	5a01                	.insn	2, 0x5a01
     a62:	5004                	.insn	2, 0x5004
     a64:	0154                	.insn	2, 0x0154
     a66:	005a                	.insn	2, 0x005a
     a68:	5804                	.insn	2, 0x5804
     a6a:	0164                	.insn	2, 0x0164
     a6c:	045a                	.insn	2, 0x045a
     a6e:	6864                	.insn	2, 0x6864
     a70:	5d01                	.insn	2, 0x5d01
     a72:	6804                	.insn	2, 0x6804
     a74:	0170                	.insn	2, 0x0170
     a76:	045e                	.insn	2, 0x045e
     a78:	7470                	.insn	2, 0x7470
     a7a:	5d01                	.insn	2, 0x5d01
     a7c:	0400                	.insn	2, 0x0400
     a7e:	6058                	.insn	2, 0x6058
     a80:	9f7f7c03          	.insn	4, 0x9f7f7c03
     a84:	0400                	.insn	2, 0x0400
     a86:	9878                	.insn	2, 0x9878
     a88:	0101                	.insn	2, 0x0101
     a8a:	045a                	.insn	2, 0x045a
     a8c:	01b4                	.insn	2, 0x01b4
     a8e:	01b8                	.insn	2, 0x01b8
     a90:	5a01                	.insn	2, 0x5a01
     a92:	b804                	.insn	2, 0xb804
     a94:	c801                	.insn	2, 0xc801
     a96:	0101                	.insn	2, 0x0101
     a98:	0058                	.insn	2, 0x0058
     a9a:	8c04                	.insn	2, 0x8c04
     a9c:	d801                	.insn	2, 0xd801
     a9e:	0301                	.insn	2, 0x0301
     aa0:	0011                	.insn	2, 0x0011
     aa2:	049f 01e8 02a4      	.insn	6, 0x02a401e8049f
     aa8:	5801                	.insn	2, 0x5801
     aaa:	a404                	.insn	2, 0xa404
     aac:	bc02                	.insn	2, 0xbc02
     aae:	0102                	.insn	2, 0x0102
     ab0:	005f 9004 9801      	.insn	6, 0x98019004005f
     ab6:	0101                	.insn	2, 0x0101
     ab8:	045a                	.insn	2, 0x045a
     aba:	01c8                	.insn	2, 0x01c8
     abc:	029c                	.insn	2, 0x029c
     abe:	5a01                	.insn	2, 0x5a01
     ac0:	9c04                	.insn	2, 0x9c04
     ac2:	b002                	.insn	2, 0xb002
     ac4:	0102                	.insn	2, 0x0102
     ac6:	045e                	.insn	2, 0x045e
     ac8:	02b0                	.insn	2, 0x02b0
     aca:	02bc                	.insn	2, 0x02bc
     acc:	5a01                	.insn	2, 0x5a01
     ace:	0400                	.insn	2, 0x0400
     ad0:	01e8                	.insn	2, 0x01e8
     ad2:	01ec                	.insn	2, 0x01ec
     ad4:	6001                	.insn	2, 0x6001
     ad6:	9804                	.insn	2, 0x9804
     ad8:	9c02                	.insn	2, 0x9c02
     ada:	0102                	.insn	2, 0x0102
     adc:	0060                	.insn	2, 0x0060
     ade:	e804                	.insn	2, 0xe804
     ae0:	9401                	.insn	2, 0x9401
     ae2:	0102                	.insn	2, 0x0102
     ae4:	045e                	.insn	2, 0x045e
     ae6:	0298                	.insn	2, 0x0298
     ae8:	029c                	.insn	2, 0x029c
     aea:	5e01                	.insn	2, 0x5e01
     aec:	0400                	.insn	2, 0x0400
     aee:	029c                	.insn	2, 0x029c
     af0:	02a8                	.insn	2, 0x02a8
     af2:	6001                	.insn	2, 0x6001
     af4:	0400                	.insn	2, 0x0400
     af6:	02f0                	.insn	2, 0x02f0
     af8:	03ac                	.insn	2, 0x03ac
     afa:	5a01                	.insn	2, 0x5a01
     afc:	ac04                	.insn	2, 0xac04
     afe:	01088803          	lb	a6,16(a7)
     b02:	0058                	.insn	2, 0x0058
     b04:	cc04                	.insn	2, 0xcc04
     b06:	e804                	.insn	2, 0xe804
     b08:	0104                	.insn	2, 0x0104
     b0a:	078c046b          	.insn	4, 0x078c046b
     b0e:	079c                	.insn	2, 0x079c
     b10:	6b01                	.insn	2, 0x6b01
     b12:	0400                	.insn	2, 0x0400
     b14:	04d0                	.insn	2, 0x04d0
     b16:	04e8                	.insn	2, 0x04e8
     b18:	6b01                	.insn	2, 0x6b01
     b1a:	9c04                	.insn	2, 0x9c04
     b1c:	0107a807          	.insn	4, 0x0107a807
     b20:	07a8046b          	.insn	4, 0x07a8046b
     b24:	07b4                	.insn	2, 0x07b4
     b26:	5b01                	.insn	2, 0x5b01
     b28:	b404                	.insn	2, 0xb404
     b2a:	0107f407          	.insn	4, 0x0107f407
     b2e:	d004006b          	.insn	4, 0xd004006b
     b32:	e804                	.insn	2, 0xe804
     b34:	0304                	.insn	2, 0x0304
     b36:	0011                	.insn	2, 0x0011
     b38:	049f 079c 07a0      	.insn	6, 0x07a0079c049f
     b3e:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <_stack_top+0xffef3a30>
     b42:	a804                	.insn	2, 0xa804
     b44:	0107b007          	.insn	4, 0x0107b007
     b48:	07b00463          	beq	zero,s11,bb0 <_start-0xff450>
     b4c:	07d4                	.insn	2, 0x07d4
     b4e:	5a01                	.insn	2, 0x5a01
     b50:	0400                	.insn	2, 0x0400
     b52:	0580                	.insn	2, 0x0580
     b54:	06c0                	.insn	2, 0x06c0
     b56:	6301                	.insn	2, 0x6301
     b58:	0400                	.insn	2, 0x0400
     b5a:	0580                	.insn	2, 0x0580
     b5c:	0594                	.insn	2, 0x0594
     b5e:	9f071103          	lh	sp,-1552(a4)
     b62:	9404                	.insn	2, 0x9404
     b64:	ac05                	.insn	2, 0xac05
     b66:	0305                	.insn	2, 0x0305
     b68:	0611                	.insn	2, 0x0611
     b6a:	049f 05ac 05c4      	.insn	6, 0x05c405ac049f
     b70:	9f051103          	lh	sp,-1552(a0)
     b74:	c404                	.insn	2, 0xc404
     b76:	dc05                	.insn	2, 0xdc05
     b78:	0305                	.insn	2, 0x0305
     b7a:	0411                	.insn	2, 0x0411
     b7c:	049f 05dc 05f4      	.insn	6, 0x05f405dc049f
     b82:	9f031103          	lh	sp,-1552(t1)
     b86:	f404                	.insn	2, 0xf404
     b88:	8c05                	.insn	2, 0x8c05
     b8a:	0306                	.insn	2, 0x0306
     b8c:	0211                	.insn	2, 0x0211
     b8e:	049f 068c 06a4      	.insn	6, 0x06a4068c049f
     b94:	9f011103          	lh	sp,-1552(sp) # 45f0310 <_stack_top+0x44e4350>
     b98:	a404                	.insn	2, 0xa404
     b9a:	c006                	.insn	2, 0xc006
     b9c:	0306                	.insn	2, 0x0306
     b9e:	0011                	.insn	2, 0x0011
     ba0:	009f 8404 8805      	.insn	6, 0x88058404009f
     ba6:	0105                	.insn	2, 0x0105
     ba8:	045a                	.insn	2, 0x045a
     baa:	059c                	.insn	2, 0x059c
     bac:	05a0                	.insn	2, 0x05a0
     bae:	5a01                	.insn	2, 0x5a01
     bb0:	b404                	.insn	2, 0xb404
     bb2:	b805                	.insn	2, 0xb805
     bb4:	0105                	.insn	2, 0x0105
     bb6:	045a                	.insn	2, 0x045a
     bb8:	05cc                	.insn	2, 0x05cc
     bba:	05d0                	.insn	2, 0x05d0
     bbc:	5a01                	.insn	2, 0x5a01
     bbe:	e404                	.insn	2, 0xe404
     bc0:	e805                	.insn	2, 0xe805
     bc2:	0105                	.insn	2, 0x0105
     bc4:	045a                	.insn	2, 0x045a
     bc6:	05fc                	.insn	2, 0x05fc
     bc8:	0680                	.insn	2, 0x0680
     bca:	5a01                	.insn	2, 0x5a01
     bcc:	9404                	.insn	2, 0x9404
     bce:	9806                	.insn	2, 0x9806
     bd0:	0106                	.insn	2, 0x0106
     bd2:	045a                	.insn	2, 0x045a
     bd4:	06a8                	.insn	2, 0x06a8
     bd6:	06ac                	.insn	2, 0x06ac
     bd8:	5a01                	.insn	2, 0x5a01
     bda:	0400                	.insn	2, 0x0400
     bdc:	06e4                	.insn	2, 0x06e4
     bde:	06f0                	.insn	2, 0x06f0
     be0:	6301                	.insn	2, 0x6301
     be2:	f004                	.insn	2, 0xf004
     be4:	fc06                	.insn	2, 0xfc06
     be6:	0306                	.insn	2, 0x0306
     be8:	049f7f83          	.insn	4, 0x049f7f83
     bec:	06fc                	.insn	2, 0x06fc
     bee:	0784                	.insn	2, 0x0784
     bf0:	6301                	.insn	2, 0x6301
     bf2:	0400                	.insn	2, 0x0400
     bf4:	08bc                	.insn	2, 0x08bc
     bf6:	08cc                	.insn	2, 0x08cc
     bf8:	5a01                	.insn	2, 0x5a01
     bfa:	cc04                	.insn	2, 0xcc04
     bfc:	d008                	.insn	2, 0xd008
     bfe:	0308                	.insn	2, 0x0308
     c00:	7f7d                	.insn	2, 0x7f7d
     c02:	049f 08d0 08f4      	.insn	6, 0x08f408d0049f
     c08:	9f7e7d03          	.insn	4, 0x9f7e7d03
     c0c:	f804                	.insn	2, 0xf804
     c0e:	8008                	.insn	2, 0x8008
     c10:	0109                	.insn	2, 0x0109
     c12:	045d                	.insn	2, 0x045d
     c14:	0980                	.insn	2, 0x0980
     c16:	0984                	.insn	2, 0x0984
     c18:	9f7e7d03          	.insn	4, 0x9f7e7d03
     c1c:	8404                	.insn	2, 0x8404
     c1e:	9009                	.insn	2, 0x9009
     c20:	0109                	.insn	2, 0x0109
     c22:	045d                	.insn	2, 0x045d
     c24:	0990                	.insn	2, 0x0990
     c26:	0994                	.insn	2, 0x0994
     c28:	9f7e7d03          	.insn	4, 0x9f7e7d03
     c2c:	b004                	.insn	2, 0xb004
     c2e:	c809                	.insn	2, 0xc809
     c30:	0109                	.insn	2, 0x0109
     c32:	045d                	.insn	2, 0x045d
     c34:	09cc                	.insn	2, 0x09cc
     c36:	09f4                	.insn	2, 0x09f4
     c38:	5d01                	.insn	2, 0x5d01
     c3a:	0400                	.insn	2, 0x0400
     c3c:	08bc                	.insn	2, 0x08bc
     c3e:	09b0                	.insn	2, 0x09b0
     c40:	3002                	.insn	2, 0x3002
     c42:	049f 09b0 09c0      	.insn	6, 0x09c009b0049f
     c48:	5c01                	.insn	2, 0x5c01
     c4a:	c404                	.insn	2, 0xc404
     c4c:	8009                	.insn	2, 0x8009
     c4e:	010a                	.insn	2, 0x010a
     c50:	005c                	.insn	2, 0x005c
     c52:	b004                	.insn	2, 0xb004
     c54:	bc09                	.insn	2, 0xbc09
     c56:	0109                	.insn	2, 0x0109
     c58:	045a                	.insn	2, 0x045a
     c5a:	09cc                	.insn	2, 0x09cc
     c5c:	09ec                	.insn	2, 0x09ec
     c5e:	5a01                	.insn	2, 0x5a01
     c60:	0400                	.insn	2, 0x0400
     c62:	09b8                	.insn	2, 0x09b8
     c64:	09cc                	.insn	2, 0x09cc
     c66:	6101                	.insn	2, 0x6101
     c68:	0400                	.insn	2, 0x0400
     c6a:	0a80                	.insn	2, 0x0a80
     c6c:	0ac8                	.insn	2, 0x0ac8
     c6e:	5a01                	.insn	2, 0x5a01
     c70:	c804                	.insn	2, 0xc804
     c72:	c40a                	.insn	2, 0xc40a
     c74:	010e                	.insn	2, 0x010e
     c76:	0062                	.insn	2, 0x0062
     c78:	8004                	.insn	2, 0x8004
     c7a:	c40a                	.insn	2, 0xc40a
     c7c:	010a                	.insn	2, 0x010a
     c7e:	0ac4045b          	.insn	4, 0x0ac4045b
     c82:	0ec0                	.insn	2, 0x0ec0
     c84:	5901                	.insn	2, 0x5901
     c86:	0400                	.insn	2, 0x0400
     c88:	0a80                	.insn	2, 0x0a80
     c8a:	0ac0                	.insn	2, 0x0ac0
     c8c:	5c01                	.insn	2, 0x5c01
     c8e:	c004                	.insn	2, 0xc004
     c90:	bc0a                	.insn	2, 0xbc0a
     c92:	010e                	.insn	2, 0x010e
     c94:	0058                	.insn	2, 0x0058
     c96:	8004                	.insn	2, 0x8004
     c98:	c80a                	.insn	2, 0xc80a
     c9a:	010a                	.insn	2, 0x010a
     c9c:	045a                	.insn	2, 0x045a
     c9e:	0ac8                	.insn	2, 0x0ac8
     ca0:	0ec4                	.insn	2, 0x0ec4
     ca2:	6201                	.insn	2, 0x6201
     ca4:	0400                	.insn	2, 0x0400
     ca6:	0a80                	.insn	2, 0x0a80
     ca8:	0ae4                	.insn	2, 0x0ae4
     caa:	3002                	.insn	2, 0x3002
     cac:	049f 0ae4 0ed0      	.insn	6, 0x0ed00ae4049f
     cb2:	6501                	.insn	2, 0x6501
     cb4:	0400                	.insn	2, 0x0400
     cb6:	0ae4                	.insn	2, 0x0ae4
     cb8:	0b84                	.insn	2, 0x0b84
     cba:	6a01                	.insn	2, 0x6a01
     cbc:	e004                	.insn	2, 0xe004
     cbe:	ac0d                	.insn	2, 0xac0d
     cc0:	010e                	.insn	2, 0x010e
     cc2:	006a                	.insn	2, 0x006a
     cc4:	8804                	.insn	2, 0x8804
     cc6:	030ba00b          	.insn	4, 0x030ba00b
     cca:	0711                	.insn	2, 0x0711
     ccc:	049f 0ba0 0bb8      	.insn	6, 0x0bb80ba0049f
     cd2:	9f061103          	lh	sp,-1552(a2)
     cd6:	b804                	.insn	2, 0xb804
     cd8:	030bd00b          	.insn	4, 0x030bd00b
     cdc:	0511                	.insn	2, 0x0511
     cde:	049f 0bd0 0be8      	.insn	6, 0x0be80bd0049f
     ce4:	9f041103          	lh	sp,-1552(s0)
     ce8:	e804                	.insn	2, 0xe804
     cea:	030c800b          	.insn	4, 0x030c800b
     cee:	0311                	.insn	2, 0x0311
     cf0:	049f 0c80 0c98      	.insn	6, 0x0c980c80049f
     cf6:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <_stack_top+0xffef3a30>
     cfa:	9804                	.insn	2, 0x9804
     cfc:	b00c                	.insn	2, 0xb00c
     cfe:	030c                	.insn	2, 0x030c
     d00:	0111                	.insn	2, 0x0111
     d02:	049f 0cb0 0cc4      	.insn	6, 0x0cc40cb0049f
     d08:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <_stack_top+0xffef3a30>
     d0c:	c404                	.insn	2, 0xc404
     d0e:	e00c                	.insn	2, 0xe00c
     d10:	030c                	.insn	2, 0x030c
     d12:	7f11                	.insn	2, 0x7f11
     d14:	009f 8c04 900b      	.insn	6, 0x900b8c04009f
     d1a:	045a010b          	.insn	4, 0x045a010b
     d1e:	0ba8                	.insn	2, 0x0ba8
     d20:	0bac                	.insn	2, 0x0bac
     d22:	5a01                	.insn	2, 0x5a01
     d24:	c004                	.insn	2, 0xc004
     d26:	010bc40b          	.insn	4, 0x010bc40b
     d2a:	045a                	.insn	2, 0x045a
     d2c:	0bd8                	.insn	2, 0x0bd8
     d2e:	0bdc                	.insn	2, 0x0bdc
     d30:	5a01                	.insn	2, 0x5a01
     d32:	f004                	.insn	2, 0xf004
     d34:	010bf40b          	.insn	4, 0x010bf40b
     d38:	045a                	.insn	2, 0x045a
     d3a:	0c88                	.insn	2, 0x0c88
     d3c:	0c8c                	.insn	2, 0x0c8c
     d3e:	5a01                	.insn	2, 0x5a01
     d40:	a004                	.insn	2, 0xa004
     d42:	a40c                	.insn	2, 0xa40c
     d44:	010c                	.insn	2, 0x010c
     d46:	045a                	.insn	2, 0x045a
     d48:	0cb4                	.insn	2, 0x0cb4
     d4a:	0cb8                	.insn	2, 0x0cb8
     d4c:	5a01                	.insn	2, 0x5a01
     d4e:	0400                	.insn	2, 0x0400
     d50:	0df8                	.insn	2, 0x0df8
     d52:	0e88                	.insn	2, 0x0e88
     d54:	3002                	.insn	2, 0x3002
     d56:	009f a004 ac0e      	.insn	6, 0xac0ea004009f
     d5c:	010e                	.insn	2, 0x010e
     d5e:	005a                	.insn	2, 0x005a
     d60:	f004                	.insn	2, 0xf004
     d62:	fc0e                	.insn	2, 0xfc0e
     d64:	045a010f          	.insn	4, 0x045a010f
     d68:	10c4                	.insn	2, 0x10c4
     d6a:	10d0                	.insn	2, 0x10d0
     d6c:	5a01                	.insn	2, 0x5a01
     d6e:	fc04                	.insn	2, 0xfc04
     d70:	e010                	.insn	2, 0xe010
     d72:	0111                	.insn	2, 0x0111
     d74:	005a                	.insn	2, 0x005a
     d76:	f004                	.insn	2, 0xf004
     d78:	880e                	.insn	2, 0x880e
     d7a:	0110                	.insn	2, 0x0110
     d7c:	10c4045b          	.insn	4, 0x10c4045b
     d80:	10d8                	.insn	2, 0x10d8
     d82:	5b01                	.insn	2, 0x5b01
     d84:	fc04                	.insn	2, 0xfc04
     d86:	e010                	.insn	2, 0xe010
     d88:	0111                	.insn	2, 0x0111
     d8a:	fc04005b          	.insn	4, 0xfc04005b
     d8e:	e00e                	.insn	2, 0xe00e
     d90:	9f30020f          	.insn	4, 0x9f30020f
     d94:	e004                	.insn	2, 0xe004
     d96:	0110c40f          	.insn	4, 0x0110c40f
     d9a:	0458                	.insn	2, 0x0458
     d9c:	10c4                	.insn	2, 0x10c4
     d9e:	10d8                	.insn	2, 0x10d8
     da0:	3002                	.insn	2, 0x3002
     da2:	049f 10d8 10e8      	.insn	6, 0x10e810d8049f
     da8:	5801                	.insn	2, 0x5801
     daa:	fc04                	.insn	2, 0xfc04
     dac:	e010                	.insn	2, 0xe010
     dae:	0211                	.insn	2, 0x0211
     db0:	9f30                	.insn	2, 0x9f30
     db2:	e004                	.insn	2, 0xe004
     db4:	8811                	.insn	2, 0x8811
     db6:	00580113          	addi	sp,a6,5
     dba:	fc04                	.insn	2, 0xfc04
     dbc:	c40e                	.insn	2, 0xc40e
     dbe:	0412                	.insn	2, 0x0412
     dc0:	8010                	.insn	2, 0x8010
     dc2:	9f02                	.insn	2, 0x9f02
     dc4:	c404                	.insn	2, 0xc404
     dc6:	e412                	.insn	2, 0xe412
     dc8:	0112                	.insn	2, 0x0112
     dca:	12f0045b          	.insn	4, 0x12f0045b
     dce:	12f4                	.insn	2, 0x12f4
     dd0:	1004                	.insn	2, 0x1004
     dd2:	2080                	.insn	2, 0x2080
     dd4:	049f 12f4 1380      	.insn	6, 0x138012f4049f
     dda:	5c01                	.insn	2, 0x5c01
     ddc:	0400                	.insn	2, 0x0400
     dde:	0fa8                	.insn	2, 0x0fa8
     de0:	0fb0                	.insn	2, 0x0fb0
     de2:	9f7f7d03          	.insn	4, 0x9f7f7d03
     de6:	b004                	.insn	2, 0xb004
     de8:	030fd00f          	.insn	4, 0x030fd00f
     dec:	7e7d                	.insn	2, 0x7e7d
     dee:	049f 0fd4 0fdc      	.insn	6, 0x0fdc0fd4049f
     df4:	5d01                	.insn	2, 0x5d01
     df6:	c404                	.insn	2, 0xc404
     df8:	c810                	.insn	2, 0xc810
     dfa:	0310                	.insn	2, 0x0310
     dfc:	7e7d                	.insn	2, 0x7e7d
     dfe:	049f 10c8 10cc      	.insn	6, 0x10cc10c8049f
     e04:	5d01                	.insn	2, 0x5d01
     e06:	9c04                	.insn	2, 0x9c04
     e08:	b411                	.insn	2, 0xb411
     e0a:	0111                	.insn	2, 0x0111
     e0c:	045d                	.insn	2, 0x045d
     e0e:	11b8                	.insn	2, 0x11b8
     e10:	11d8                	.insn	2, 0x11d8
     e12:	5d01                	.insn	2, 0x5d01
     e14:	0400                	.insn	2, 0x0400
     e16:	1090                	.insn	2, 0x1090
     e18:	1098                	.insn	2, 0x1098
     e1a:	9f7f7d03          	.insn	4, 0x9f7f7d03
     e1e:	9804                	.insn	2, 0x9804
     e20:	b810                	.insn	2, 0xb810
     e22:	0310                	.insn	2, 0x0310
     e24:	7e7d                	.insn	2, 0x7e7d
     e26:	049f 10bc 10c4      	.insn	6, 0x10c410bc049f
     e2c:	5d01                	.insn	2, 0x5d01
     e2e:	d804                	.insn	2, 0xd804
     e30:	dc10                	.insn	2, 0xdc10
     e32:	0310                	.insn	2, 0x0310
     e34:	7e7d                	.insn	2, 0x7e7d
     e36:	049f 10dc 10e0      	.insn	6, 0x10e010dc049f
     e3c:	5d01                	.insn	2, 0x5d01
     e3e:	8004                	.insn	2, 0x8004
     e40:	9812                	.insn	2, 0x9812
     e42:	0112                	.insn	2, 0x0112
     e44:	045d                	.insn	2, 0x045d
     e46:	129c                	.insn	2, 0x129c
     e48:	12bc                	.insn	2, 0x12bc
     e4a:	5d01                	.insn	2, 0x5d01
     e4c:	0400                	.insn	2, 0x0400
     e4e:	10cc                	.insn	2, 0x10cc
     e50:	10d8                	.insn	2, 0x10d8
     e52:	3002                	.insn	2, 0x3002
     e54:	009f e004 e810      	.insn	6, 0xe810e004009f
     e5a:	0210                	.insn	2, 0x0210
     e5c:	9f30                	.insn	2, 0x9f30
     e5e:	0400                	.insn	2, 0x0400
     e60:	119c                	.insn	2, 0x119c
     e62:	11a8                	.insn	2, 0x11a8
     e64:	5c01                	.insn	2, 0x5c01
     e66:	b804                	.insn	2, 0xb804
     e68:	d811                	.insn	2, 0xd811
     e6a:	0111                	.insn	2, 0x0111
     e6c:	005c                	.insn	2, 0x005c
     e6e:	9c04                	.insn	2, 0x9c04
     e70:	ac11                	.insn	2, 0xac11
     e72:	0111                	.insn	2, 0x0111
     e74:	0458                	.insn	2, 0x0458
     e76:	11b0                	.insn	2, 0x11b0
     e78:	11d8                	.insn	2, 0x11d8
     e7a:	5801                	.insn	2, 0x5801
     e7c:	0400                	.insn	2, 0x0400
     e7e:	11a4                	.insn	2, 0x11a4
     e80:	11b8                	.insn	2, 0x11b8
     e82:	6101                	.insn	2, 0x6101
     e84:	0400                	.insn	2, 0x0400
     e86:	1280                	.insn	2, 0x1280
     e88:	128c                	.insn	2, 0x128c
     e8a:	5a01                	.insn	2, 0x5a01
     e8c:	9c04                	.insn	2, 0x9c04
     e8e:	bc12                	.insn	2, 0xbc12
     e90:	0112                	.insn	2, 0x0112
     e92:	005a                	.insn	2, 0x005a
     e94:	8004                	.insn	2, 0x8004
     e96:	9012                	.insn	2, 0x9012
     e98:	0112                	.insn	2, 0x0112
     e9a:	1294045b          	.insn	4, 0x1294045b
     e9e:	12bc                	.insn	2, 0x12bc
     ea0:	5b01                	.insn	2, 0x5b01
     ea2:	0400                	.insn	2, 0x0400
     ea4:	1288                	.insn	2, 0x1288
     ea6:	129c                	.insn	2, 0x129c
     ea8:	6101                	.insn	2, 0x6101
     eaa:	2200                	.insn	2, 0x2200
     eac:	0008                	.insn	2, 0x0008
     eae:	0500                	.insn	2, 0x0500
     eb0:	0400                	.insn	2, 0x0400
     eb2:	2000                	.insn	2, 0x2000
     eb4:	0000                	.insn	2, 0x0000
     eb6:	8000                	.insn	2, 0x8000
     eb8:	0000                	.insn	2, 0x0000
     eba:	8b00                	.insn	2, 0x8b00
     ebc:	0000                	.insn	2, 0x0000
     ebe:	a500                	.insn	2, 0xa500
     ec0:	0000                	.insn	2, 0x0000
     ec2:	6600                	.insn	2, 0x6600
     ec4:	0001                	.insn	2, 0x0001
     ec6:	8000                	.insn	2, 0x8000
     ec8:	0001                	.insn	2, 0x0001
     eca:	9d00                	.insn	2, 0x9d00
     ecc:	0001                	.insn	2, 0x0001
     ece:	4a00                	.insn	2, 0x4a00
     ed0:	59000003          	lb	zero,1424(zero) # 590 <_start-0xffa70>
     ed4:	68000003          	lb	zero,1664(zero) # 680 <_start-0xff980>
     ed8:	8d000003          	lb	zero,-1840(zero) # fffff8d0 <_stack_top+0xffef3910>
     edc:	a3000003          	lb	zero,-1488(zero) # fffffa30 <_stack_top+0xffef3a70>
     ee0:	bf000003          	lb	zero,-1040(zero) # fffffbf0 <_stack_top+0xffef3c30>
     ee4:	35000003          	lb	zero,848(zero) # 350 <_start-0xffcb0>
     ee8:	0004                	.insn	2, 0x0004
     eea:	4400                	.insn	2, 0x4400
     eec:	0004                	.insn	2, 0x0004
     eee:	4c00                	.insn	2, 0x4c00
     ef0:	0004                	.insn	2, 0x0004
     ef2:	6a00                	.insn	2, 0x6a00
     ef4:	0004                	.insn	2, 0x0004
     ef6:	ef00                	.insn	2, 0xef00
     ef8:	0004                	.insn	2, 0x0004
     efa:	0d00                	.insn	2, 0x0d00
     efc:	0005                	.insn	2, 0x0005
     efe:	2b00                	.insn	2, 0x2b00
     f00:	0005                	.insn	2, 0x0005
     f02:	d800                	.insn	2, 0xd800
     f04:	0006                	.insn	2, 0x0006
     f06:	e700                	.insn	2, 0xe700
     f08:	0006                	.insn	2, 0x0006
     f0a:	f100                	.insn	2, 0xf100
     f0c:	0006                	.insn	2, 0x0006
     f0e:	fb00                	.insn	2, 0xfb00
     f10:	0006                	.insn	2, 0x0006
     f12:	1300                	.insn	2, 0x1300
     f14:	1b000007          	.insn	4, 0x1b000007
     f18:	46000007          	.insn	4, 0x46000007
     f1c:	98000007          	.insn	4, 0x98000007
     f20:	bf000007          	.insn	4, 0xbf000007
     f24:	c7000007          	.insn	4, 0xc7000007
     f28:	d6000007          	.insn	4, 0xd6000007
     f2c:	ec000007          	.insn	4, 0xec000007
     f30:	f5000007          	.insn	4, 0xf5000007
     f34:	04000007          	.insn	4, 0x04000007
     f38:	5808                	.insn	2, 0x5808
     f3a:	5a01                	.insn	2, 0x5a01
     f3c:	5c04                	.insn	2, 0x5c04
     f3e:	0174                	.insn	2, 0x0174
     f40:	005a                	.insn	2, 0x005a
     f42:	1804                	.insn	2, 0x1804
     f44:	0e1c                	.insn	2, 0x0e1c
     f46:	007d                	.insn	2, 0x007d
     f48:	9c11                	.insn	2, 0x9c11
     f4a:	7f111c7f 00e3111e 	.insn	12, 0x20049f2200e3111e7f111c7f
     f52:	20049f22 
     f56:	0324                	.insn	2, 0x0324
     f58:	7f7d                	.insn	2, 0x7f7d
     f5a:	009f 4004 104c      	.insn	6, 0x104c4004009f
     f60:	007d                	.insn	2, 0x007d
     f62:	b011                	.insn	2, 0xb011
     f64:	7cf9                	.insn	2, 0x7cf9
     f66:	111c                	.insn	2, 0x111c
     f68:	d0111e7f 9f220386 	.insn	12, 0x10504c049f220386d0111e7f
     f70:	10504c04 
     f74:	007d                	.insn	2, 0x007d
     f76:	b011                	.insn	2, 0xb011
     f78:	7cf9                	.insn	2, 0x7cf9
     f7a:	111c                	.insn	2, 0x111c
     f7c:	cf111e7f 9f220386 	.insn	12, 0x10605c049f220386cf111e7f
     f84:	10605c04 
     f88:	007d                	.insn	2, 0x007d
     f8a:	b011                	.insn	2, 0xb011
     f8c:	7cf9                	.insn	2, 0x7cf9
     f8e:	111c                	.insn	2, 0x111c
     f90:	d0111e7f 9f220386 	.insn	12, 0x9c0190049f220386d0111e7f
     f98:	9c019004 
     f9c:	1001                	.insn	2, 0x1001
     f9e:	007a                	.insn	2, 0x007a
     fa0:	b011                	.insn	2, 0xb011
     fa2:	7cf9                	.insn	2, 0x7cf9
     fa4:	111c                	.insn	2, 0x111c
     fa6:	d0111e7f 9f220386 	.insn	12, 0xa0019c049f220386d0111e7f
     fae:	a0019c04 
     fb2:	1001                	.insn	2, 0x1001
     fb4:	007a                	.insn	2, 0x007a
     fb6:	b011                	.insn	2, 0xb011
     fb8:	7cf9                	.insn	2, 0x7cf9
     fba:	111c                	.insn	2, 0x111c
     fbc:	cf111e7f 9f220386 	.insn	12, 0xfc01ac049f220386cf111e7f
     fc4:	fc01ac04 
     fc8:	1002                	.insn	2, 0x1002
     fca:	007a                	.insn	2, 0x007a
     fcc:	b011                	.insn	2, 0xb011
     fce:	7cf9                	.insn	2, 0x7cf9
     fd0:	111c                	.insn	2, 0x111c
     fd2:	d0111e7f 9f220386 	.insn	12, 0x98038c049f220386d0111e7f
     fda:	98038c04 
     fde:	007a1003          	lh	zero,7(s4)
     fe2:	b011                	.insn	2, 0xb011
     fe4:	7cf9                	.insn	2, 0x7cf9
     fe6:	111c                	.insn	2, 0x111c
     fe8:	d0111e7f 9f220386 	.insn	12, 0x9c0398049f220386d0111e7f
     ff0:	9c039804 
     ff4:	007a1003          	lh	zero,7(s4)
     ff8:	b011                	.insn	2, 0xb011
     ffa:	7cf9                	.insn	2, 0x7cf9
     ffc:	111c                	.insn	2, 0x111c
     ffe:	cf111e7f 9f220386 	.insn	12, 0xa803a4049f220386cf111e7f
    1006:	a803a404 
    100a:	007a1003          	lh	zero,7(s4)
    100e:	b011                	.insn	2, 0xb011
    1010:	7cf9                	.insn	2, 0x7cf9
    1012:	111c                	.insn	2, 0x111c
    1014:	d0111e7f 9f220386 	.insn	12, 0x646004009f220386d0111e7f
    101c:	64600400 
    1020:	7d0e                	.insn	2, 0x7d0e
    1022:	1100                	.insn	2, 0x1100
    1024:	7f9c                	.insn	2, 0x7f9c
    1026:	111c                	.insn	2, 0x111c
    1028:	e3111e7f 049f2200 	.insn	12, 0x7d036c68049f2200e3111e7f
    1030:	7d036c68 
    1034:	04009f7f 0e01807c 	.insn	12, 0x9c11007a0e01807c04009f7f
    103c:	9c11007a 
    1040:	7f111c7f 00e3111e 	.insn	12, 0x84049f2200e3111e7f111c7f
    1048:	84049f22 
    104c:	8801                	.insn	2, 0x8801
    104e:	0301                	.insn	2, 0x0301
    1050:	7f7a                	.insn	2, 0x7f7a
    1052:	009f b004 b401      	.insn	6, 0xb401b004009f
    1058:	0301                	.insn	2, 0x0301
    105a:	3110                	.insn	2, 0x3110
    105c:	049f 01b4 01b8      	.insn	6, 0x01b801b4049f
    1062:	9f301003          	lh	zero,-1549(zero) # fffff9f3 <_stack_top+0xffef3a33>
    1066:	b804                	.insn	2, 0xb804
    1068:	bc01                	.insn	2, 0xbc01
    106a:	0301                	.insn	2, 0x0301
    106c:	2f10                	.insn	2, 0x2f10
    106e:	049f 01bc 01c0      	.insn	6, 0x01c001bc049f
    1074:	9f2e1003          	lh	zero,-1550(t3)
    1078:	c004                	.insn	2, 0xc004
    107a:	c401                	.insn	2, 0xc401
    107c:	0301                	.insn	2, 0x0301
    107e:	2d10                	.insn	2, 0x2d10
    1080:	049f 01c4 01c8      	.insn	6, 0x01c801c4049f
    1086:	9f2c1003          	lh	zero,-1550(s8) # 117b308 <_stack_top+0x106f348>
    108a:	c804                	.insn	2, 0xc804
    108c:	cc01                	.insn	2, 0xcc01
    108e:	0301                	.insn	2, 0x0301
    1090:	2b10                	.insn	2, 0x2b10
    1092:	049f 01cc 01d0      	.insn	6, 0x01d001cc049f
    1098:	9f2a1003          	lh	zero,-1550(s4)
    109c:	d004                	.insn	2, 0xd004
    109e:	d401                	.insn	2, 0xd401
    10a0:	0301                	.insn	2, 0x0301
    10a2:	2910                	.insn	2, 0x2910
    10a4:	049f 01d4 01d8      	.insn	6, 0x01d801d4049f
    10aa:	9f281003          	lh	zero,-1550(a6)
    10ae:	d804                	.insn	2, 0xd804
    10b0:	dc01                	.insn	2, 0xdc01
    10b2:	0301                	.insn	2, 0x0301
    10b4:	2710                	.insn	2, 0x2710
    10b6:	049f 01dc 01e0      	.insn	6, 0x01e001dc049f
    10bc:	9f261003          	lh	zero,-1550(a2)
    10c0:	e004                	.insn	2, 0xe004
    10c2:	e401                	.insn	2, 0xe401
    10c4:	0301                	.insn	2, 0x0301
    10c6:	2510                	.insn	2, 0x2510
    10c8:	049f 01e4 01e8      	.insn	6, 0x01e801e4049f
    10ce:	9f241003          	lh	zero,-1550(s0)
    10d2:	e804                	.insn	2, 0xe804
    10d4:	ec01                	.insn	2, 0xec01
    10d6:	0301                	.insn	2, 0x0301
    10d8:	2310                	.insn	2, 0x2310
    10da:	049f 01ec 01f0      	.insn	6, 0x01f001ec049f
    10e0:	9f221003          	lh	zero,-1550(tp) # fffff9f2 <_stack_top+0xffef3a32>
    10e4:	f004                	.insn	2, 0xf004
    10e6:	f401                	.insn	2, 0xf401
    10e8:	0301                	.insn	2, 0x0301
    10ea:	2110                	.insn	2, 0x2110
    10ec:	049f 01f4 01f8      	.insn	6, 0x01f801f4049f
    10f2:	9f201003          	lh	zero,-1550(zero) # fffff9f2 <_stack_top+0xffef3a32>
    10f6:	f804                	.insn	2, 0xf804
    10f8:	fc01                	.insn	2, 0xfc01
    10fa:	0201                	.insn	2, 0x0201
    10fc:	fc049f4f          	.insn	4, 0xfc049f4f
    1100:	8001                	.insn	2, 0x8001
    1102:	0202                	.insn	2, 0x0202
    1104:	9f4e                	.insn	2, 0x9f4e
    1106:	8004                	.insn	2, 0x8004
    1108:	8402                	.insn	2, 0x8402
    110a:	0202                	.insn	2, 0x0202
    110c:	9f4d                	.insn	2, 0x9f4d
    110e:	8404                	.insn	2, 0x8404
    1110:	8802                	.insn	2, 0x8802
    1112:	0202                	.insn	2, 0x0202
    1114:	9f4c                	.insn	2, 0x9f4c
    1116:	8804                	.insn	2, 0x8804
    1118:	8c02                	.insn	2, 0x8c02
    111a:	0202                	.insn	2, 0x0202
    111c:	8c049f4b          	.insn	4, 0x8c049f4b
    1120:	9002                	.insn	2, 0x9002
    1122:	0202                	.insn	2, 0x0202
    1124:	9f4a                	.insn	2, 0x9f4a
    1126:	9004                	.insn	2, 0x9004
    1128:	9402                	.insn	2, 0x9402
    112a:	0202                	.insn	2, 0x0202
    112c:	9f49                	.insn	2, 0x9f49
    112e:	9404                	.insn	2, 0x9404
    1130:	9802                	.insn	2, 0x9802
    1132:	0202                	.insn	2, 0x0202
    1134:	9f48                	.insn	2, 0x9f48
    1136:	9804                	.insn	2, 0x9804
    1138:	9c02                	.insn	2, 0x9c02
    113a:	0202                	.insn	2, 0x0202
    113c:	9c049f47          	.insn	4, 0x9c049f47
    1140:	a002                	.insn	2, 0xa002
    1142:	0202                	.insn	2, 0x0202
    1144:	9f46                	.insn	2, 0x9f46
    1146:	a004                	.insn	2, 0xa004
    1148:	a402                	.insn	2, 0xa402
    114a:	0202                	.insn	2, 0x0202
    114c:	9f45                	.insn	2, 0x9f45
    114e:	a404                	.insn	2, 0xa404
    1150:	a802                	.insn	2, 0xa802
    1152:	0202                	.insn	2, 0x0202
    1154:	9f44                	.insn	2, 0x9f44
    1156:	a804                	.insn	2, 0xa804
    1158:	ac02                	.insn	2, 0xac02
    115a:	0202                	.insn	2, 0x0202
    115c:	ac049f43          	.insn	4, 0xac049f43
    1160:	b002                	.insn	2, 0xb002
    1162:	0202                	.insn	2, 0x0202
    1164:	9f42                	.insn	2, 0x9f42
    1166:	b004                	.insn	2, 0xb004
    1168:	b402                	.insn	2, 0xb402
    116a:	0202                	.insn	2, 0x0202
    116c:	9f41                	.insn	2, 0x9f41
    116e:	b404                	.insn	2, 0xb404
    1170:	b802                	.insn	2, 0xb802
    1172:	0202                	.insn	2, 0x0202
    1174:	9f40                	.insn	2, 0x9f40
    1176:	b804                	.insn	2, 0xb804
    1178:	bc02                	.insn	2, 0xbc02
    117a:	0202                	.insn	2, 0x0202
    117c:	bc049f3f 0202c002 	.insn	8, 0x0202c002bc049f3f
    1184:	9f3e                	.insn	2, 0x9f3e
    1186:	c004                	.insn	2, 0xc004
    1188:	c402                	.insn	2, 0xc402
    118a:	0202                	.insn	2, 0x0202
    118c:	9f3d                	.insn	2, 0x9f3d
    118e:	c404                	.insn	2, 0xc404
    1190:	c802                	.insn	2, 0xc802
    1192:	0202                	.insn	2, 0x0202
    1194:	9f3c                	.insn	2, 0x9f3c
    1196:	c804                	.insn	2, 0xc804
    1198:	cc02                	.insn	2, 0xcc02
    119a:	0202                	.insn	2, 0x0202
    119c:	cc049f3b          	.insn	4, 0xcc049f3b
    11a0:	d002                	.insn	2, 0xd002
    11a2:	0202                	.insn	2, 0x0202
    11a4:	9f3a                	.insn	2, 0x9f3a
    11a6:	d004                	.insn	2, 0xd004
    11a8:	d402                	.insn	2, 0xd402
    11aa:	0202                	.insn	2, 0x0202
    11ac:	9f39                	.insn	2, 0x9f39
    11ae:	d404                	.insn	2, 0xd404
    11b0:	d802                	.insn	2, 0xd802
    11b2:	0202                	.insn	2, 0x0202
    11b4:	9f38                	.insn	2, 0x9f38
    11b6:	d804                	.insn	2, 0xd804
    11b8:	dc02                	.insn	2, 0xdc02
    11ba:	0202                	.insn	2, 0x0202
    11bc:	dc049f37          	lui	t5,0xdc049
    11c0:	e002                	.insn	2, 0xe002
    11c2:	0202                	.insn	2, 0x0202
    11c4:	9f36                	.insn	2, 0x9f36
    11c6:	e004                	.insn	2, 0xe004
    11c8:	e402                	.insn	2, 0xe402
    11ca:	0202                	.insn	2, 0x0202
    11cc:	9f35                	.insn	2, 0x9f35
    11ce:	e404                	.insn	2, 0xe404
    11d0:	e802                	.insn	2, 0xe802
    11d2:	0202                	.insn	2, 0x0202
    11d4:	9f34                	.insn	2, 0x9f34
    11d6:	e804                	.insn	2, 0xe804
    11d8:	ec02                	.insn	2, 0xec02
    11da:	0202                	.insn	2, 0x0202
    11dc:	ec049f33          	.insn	4, 0xec049f33
    11e0:	f002                	.insn	2, 0xf002
    11e2:	0202                	.insn	2, 0x0202
    11e4:	9f32                	.insn	2, 0x9f32
    11e6:	f004                	.insn	2, 0xf004
    11e8:	f402                	.insn	2, 0xf402
    11ea:	0202                	.insn	2, 0x0202
    11ec:	9f31                	.insn	2, 0x9f31
    11ee:	f404                	.insn	2, 0xf404
    11f0:	f802                	.insn	2, 0xf802
    11f2:	0202                	.insn	2, 0x0202
    11f4:	9f30                	.insn	2, 0x9f30
    11f6:	f804                	.insn	2, 0xf804
    11f8:	8802                	.insn	2, 0x8802
    11fa:	31300403          	lb	s0,787(zero) # 313 <_start-0xffced>
    11fe:	9f1c                	.insn	2, 0x9f1c
    1200:	0400                	.insn	2, 0x0400
    1202:	03c8                	.insn	2, 0x03c8
    1204:	03ec                	.insn	2, 0x03ec
    1206:	5a01                	.insn	2, 0x5a01
    1208:	ec04                	.insn	2, 0xec04
    120a:	01088403          	lb	s0,16(a7)
    120e:	0059                	.insn	2, 0x0059
    1210:	c804                	.insn	2, 0xc804
    1212:	0103e803          	.insn	4, 0x0103e803
    1216:	03e8045b          	.insn	4, 0x03e8045b
    121a:	07a0                	.insn	2, 0x07a0
    121c:	5801                	.insn	2, 0x5801
    121e:	0400                	.insn	2, 0x0400
    1220:	03ec                	.insn	2, 0x03ec
    1222:	0594                	.insn	2, 0x0594
    1224:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <_stack_top+0xffef3a30>
    1228:	9404                	.insn	2, 0x9404
    122a:	c405                	.insn	2, 0xc405
    122c:	0306                	.insn	2, 0x0306
    122e:	0111                	.insn	2, 0x0111
    1230:	049f 06c4 07bc      	.insn	6, 0x07bc06c4049f
    1236:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <_stack_top+0xffef3a30>
    123a:	c404                	.insn	2, 0xc404
    123c:	0307f407          	.insn	4, 0x0307f407
    1240:	0211                	.insn	2, 0x0211
    1242:	009f 9004 a804      	.insn	6, 0xa8049004009f
    1248:	0104                	.insn	2, 0x0104
    124a:	0459                	.insn	2, 0x0459
    124c:	05c0                	.insn	2, 0x05c0
    124e:	05d8                	.insn	2, 0x05d8
    1250:	5901                	.insn	2, 0x5901
    1252:	f004                	.insn	2, 0xf004
    1254:	8806                	.insn	2, 0x8806
    1256:	00590107          	.insn	4, 0x00590107
    125a:	9004                	.insn	2, 0x9004
    125c:	a804                	.insn	2, 0xa804
    125e:	0304                	.insn	2, 0x0304
    1260:	0872                	.insn	2, 0x0872
    1262:	049f 05c0 05d8      	.insn	6, 0x05d805c0049f
    1268:	9f087203          	.insn	4, 0x9f087203
    126c:	f004                	.insn	2, 0xf004
    126e:	8806                	.insn	2, 0x8806
    1270:	08720307          	.insn	4, 0x08720307
    1274:	009f c404 d004      	.insn	6, 0xd004c404009f
    127a:	0604                	.insn	2, 0x0604
    127c:	007a                	.insn	2, 0x007a
    127e:	7f11                	.insn	2, 0x7f11
    1280:	d0049f1b          	.insn	4, 0xd0049f1b
    1284:	d404                	.insn	2, 0xd404
    1286:	0904                	.insn	2, 0x0904
    1288:	007a                	.insn	2, 0x007a
    128a:	7f11                	.insn	2, 0x7f11
    128c:	2201111b          	.insn	4, 0x2201111b
    1290:	049f 04e4 04ec      	.insn	6, 0x04ec04e4049f
    1296:	7a06                	.insn	2, 0x7a06
    1298:	1100                	.insn	2, 0x1100
    129a:	049f1b7f 068005f4 	.insn	12, 0x11007a06068005f4049f1b7f
    12a2:	11007a06 
    12a6:	049f1b7f 06840680 	.insn	12, 0x11007a0906840680049f1b7f
    12ae:	11007a09 
    12b2:	01111b7f 94049f22 	.insn	12, 0x06069c0694049f2201111b7f
    12ba:	06069c06 
    12be:	007a                	.insn	2, 0x007a
    12c0:	7f11                	.insn	2, 0x7f11
    12c2:	a0049f1b          	.insn	4, 0xa0049f1b
    12c6:	0607ac07          	.insn	4, 0x0607ac07
    12ca:	007a                	.insn	2, 0x007a
    12cc:	7f11                	.insn	2, 0x7f11
    12ce:	ac049f1b          	.insn	4, 0xac049f1b
    12d2:	0907b007          	.insn	4, 0x0907b007
    12d6:	007a                	.insn	2, 0x007a
    12d8:	7f11                	.insn	2, 0x7f11
    12da:	2201111b          	.insn	4, 0x2201111b
    12de:	049f 07c4 07cc      	.insn	6, 0x07cc07c4049f
    12e4:	7a06                	.insn	2, 0x7a06
    12e6:	1100                	.insn	2, 0x1100
    12e8:	009f1b7f 80089804 	.insn	12, 0x045a010980089804009f1b7f
    12f0:	045a0109 
    12f4:	0984                	.insn	2, 0x0984
    12f6:	099c                	.insn	2, 0x099c
    12f8:	5a01                	.insn	2, 0x5a01
    12fa:	0400                	.insn	2, 0x0400
    12fc:	0898                	.insn	2, 0x0898
    12fe:	08bc                	.insn	2, 0x08bc
    1300:	5b01                	.insn	2, 0x5b01
    1302:	0400                	.insn	2, 0x0400
    1304:	08a8                	.insn	2, 0x08a8
    1306:	08ac                	.insn	2, 0x08ac
    1308:	7d0e                	.insn	2, 0x7d0e
    130a:	1100                	.insn	2, 0x1100
    130c:	7f9c                	.insn	2, 0x7f9c
    130e:	111c                	.insn	2, 0x111c
    1310:	e3111e7f 049f2200 	.insn	12, 0x08b408b0049f2200e3111e7f
    1318:	08b408b0 
    131c:	9f7f7d03          	.insn	4, 0x9f7f7d03
    1320:	0400                	.insn	2, 0x0400
    1322:	08e8                	.insn	2, 0x08e8
    1324:	08f4                	.insn	2, 0x08f4
    1326:	7b10                	.insn	2, 0x7b10
    1328:	1100                	.insn	2, 0x1100
    132a:	f9b0                	.insn	2, 0xf9b0
    132c:	1c7c                	.insn	2, 0x1c7c
    132e:	7f11                	.insn	2, 0x7f11
    1330:	111e                	.insn	2, 0x111e
    1332:	86d0                	.insn	2, 0x86d0
    1334:	049f2203          	lw	tp,73(t5) # dc049049 <_stack_top+0xdbf3d089>
    1338:	08f4                	.insn	2, 0x08f4
    133a:	08f8                	.insn	2, 0x08f8
    133c:	7b10                	.insn	2, 0x7b10
    133e:	1100                	.insn	2, 0x1100
    1340:	f9b0                	.insn	2, 0xf9b0
    1342:	1c7c                	.insn	2, 0x1c7c
    1344:	7f11                	.insn	2, 0x7f11
    1346:	111e                	.insn	2, 0x111e
    1348:	220386cf          	.insn	4, 0x220386cf
    134c:	049f 0984 0988      	.insn	6, 0x09880984049f
    1352:	7b10                	.insn	2, 0x7b10
    1354:	1100                	.insn	2, 0x1100
    1356:	f9b0                	.insn	2, 0xf9b0
    1358:	1c7c                	.insn	2, 0x1c7c
    135a:	7f11                	.insn	2, 0x7f11
    135c:	111e                	.insn	2, 0x111e
    135e:	86d0                	.insn	2, 0x86d0
    1360:	049f2203          	lw	tp,73(t5)
    1364:	09b8                	.insn	2, 0x09b8
    1366:	09c4                	.insn	2, 0x09c4
    1368:	7a10                	.insn	2, 0x7a10
    136a:	1100                	.insn	2, 0x1100
    136c:	f9b0                	.insn	2, 0xf9b0
    136e:	1c7c                	.insn	2, 0x1c7c
    1370:	7f11                	.insn	2, 0x7f11
    1372:	111e                	.insn	2, 0x111e
    1374:	86d0                	.insn	2, 0x86d0
    1376:	049f2203          	lw	tp,73(t5)
    137a:	09c4                	.insn	2, 0x09c4
    137c:	09c8                	.insn	2, 0x09c8
    137e:	7a10                	.insn	2, 0x7a10
    1380:	1100                	.insn	2, 0x1100
    1382:	f9b0                	.insn	2, 0xf9b0
    1384:	1c7c                	.insn	2, 0x1c7c
    1386:	7f11                	.insn	2, 0x7f11
    1388:	111e                	.insn	2, 0x111e
    138a:	220386cf          	.insn	4, 0x220386cf
    138e:	049f 09d4 09d8      	.insn	6, 0x09d809d4049f
    1394:	7a10                	.insn	2, 0x7a10
    1396:	1100                	.insn	2, 0x1100
    1398:	f9b0                	.insn	2, 0xf9b0
    139a:	1c7c                	.insn	2, 0x1c7c
    139c:	7f11                	.insn	2, 0x7f11
    139e:	111e                	.insn	2, 0x111e
    13a0:	86d0                	.insn	2, 0x86d0
    13a2:	009f2203          	lw	tp,9(t5)
    13a6:	8804                	.insn	2, 0x8804
    13a8:	8c09                	.insn	2, 0x8c09
    13aa:	0e09                	.insn	2, 0x0e09
    13ac:	9c11007b          	.insn	4, 0x9c11007b
    13b0:	7f111c7f 00e3111e 	.insn	12, 0x90049f2200e3111e7f111c7f
    13b8:	90049f22 
    13bc:	9409                	.insn	2, 0x9409
    13be:	0309                	.insn	2, 0x0309
    13c0:	009f7f7b          	.insn	4, 0x009f7f7b
    13c4:	a404                	.insn	2, 0xa404
    13c6:	a809                	.insn	2, 0xa809
    13c8:	0e09                	.insn	2, 0x0e09
    13ca:	007a                	.insn	2, 0x007a
    13cc:	9c11                	.insn	2, 0x9c11
    13ce:	7f111c7f 00e3111e 	.insn	12, 0xac049f2200e3111e7f111c7f
    13d6:	ac049f22 
    13da:	b009                	.insn	2, 0xb009
    13dc:	0309                	.insn	2, 0x0309
    13de:	7f7a                	.insn	2, 0x7f7a
    13e0:	009f d804 dc09      	.insn	6, 0xdc09d804009f
    13e6:	0309                	.insn	2, 0x0309
    13e8:	3110                	.insn	2, 0x3110
    13ea:	049f 09dc 09e0      	.insn	6, 0x09e009dc049f
    13f0:	9f301003          	lh	zero,-1549(zero) # fffff9f3 <_stack_top+0xffef3a33>
    13f4:	e004                	.insn	2, 0xe004
    13f6:	e409                	.insn	2, 0xe409
    13f8:	0309                	.insn	2, 0x0309
    13fa:	2f10                	.insn	2, 0x2f10
    13fc:	049f 09e4 09e8      	.insn	6, 0x09e809e4049f
    1402:	9f2e1003          	lh	zero,-1550(t3)
    1406:	e804                	.insn	2, 0xe804
    1408:	ec09                	.insn	2, 0xec09
    140a:	0309                	.insn	2, 0x0309
    140c:	2d10                	.insn	2, 0x2d10
    140e:	049f 09ec 09f0      	.insn	6, 0x09f009ec049f
    1414:	9f2c1003          	lh	zero,-1550(s8)
    1418:	f004                	.insn	2, 0xf004
    141a:	f409                	.insn	2, 0xf409
    141c:	0309                	.insn	2, 0x0309
    141e:	2b10                	.insn	2, 0x2b10
    1420:	049f 09f4 09f8      	.insn	6, 0x09f809f4049f
    1426:	9f2a1003          	lh	zero,-1550(s4)
    142a:	f804                	.insn	2, 0xf804
    142c:	fc09                	.insn	2, 0xfc09
    142e:	0309                	.insn	2, 0x0309
    1430:	2910                	.insn	2, 0x2910
    1432:	049f 09fc 0a80      	.insn	6, 0x0a8009fc049f
    1438:	9f281003          	lh	zero,-1550(a6)
    143c:	8004                	.insn	2, 0x8004
    143e:	840a                	.insn	2, 0x840a
    1440:	030a                	.insn	2, 0x030a
    1442:	2710                	.insn	2, 0x2710
    1444:	049f 0a84 0a88      	.insn	6, 0x0a880a84049f
    144a:	9f261003          	lh	zero,-1550(a2)
    144e:	8804                	.insn	2, 0x8804
    1450:	8c0a                	.insn	2, 0x8c0a
    1452:	030a                	.insn	2, 0x030a
    1454:	2510                	.insn	2, 0x2510
    1456:	049f 0a8c 0a90      	.insn	6, 0x0a900a8c049f
    145c:	9f241003          	lh	zero,-1550(s0)
    1460:	9004                	.insn	2, 0x9004
    1462:	940a                	.insn	2, 0x940a
    1464:	030a                	.insn	2, 0x030a
    1466:	2310                	.insn	2, 0x2310
    1468:	049f 0a94 0a98      	.insn	6, 0x0a980a94049f
    146e:	9f221003          	lh	zero,-1550(tp) # fffff9f2 <_stack_top+0xffef3a32>
    1472:	9804                	.insn	2, 0x9804
    1474:	9c0a                	.insn	2, 0x9c0a
    1476:	030a                	.insn	2, 0x030a
    1478:	2110                	.insn	2, 0x2110
    147a:	049f 0a9c 0aa0      	.insn	6, 0x0aa00a9c049f
    1480:	9f201003          	lh	zero,-1550(zero) # fffff9f2 <_stack_top+0xffef3a32>
    1484:	a004                	.insn	2, 0xa004
    1486:	a40a                	.insn	2, 0xa40a
    1488:	020a                	.insn	2, 0x020a
    148a:	a4049f4f          	.insn	4, 0xa4049f4f
    148e:	a80a                	.insn	2, 0xa80a
    1490:	020a                	.insn	2, 0x020a
    1492:	9f4e                	.insn	2, 0x9f4e
    1494:	a804                	.insn	2, 0xa804
    1496:	ac0a                	.insn	2, 0xac0a
    1498:	020a                	.insn	2, 0x020a
    149a:	9f4d                	.insn	2, 0x9f4d
    149c:	ac04                	.insn	2, 0xac04
    149e:	b00a                	.insn	2, 0xb00a
    14a0:	020a                	.insn	2, 0x020a
    14a2:	9f4c                	.insn	2, 0x9f4c
    14a4:	b004                	.insn	2, 0xb004
    14a6:	b40a                	.insn	2, 0xb40a
    14a8:	020a                	.insn	2, 0x020a
    14aa:	b4049f4b          	.insn	4, 0xb4049f4b
    14ae:	b80a                	.insn	2, 0xb80a
    14b0:	020a                	.insn	2, 0x020a
    14b2:	9f4a                	.insn	2, 0x9f4a
    14b4:	b804                	.insn	2, 0xb804
    14b6:	bc0a                	.insn	2, 0xbc0a
    14b8:	020a                	.insn	2, 0x020a
    14ba:	9f49                	.insn	2, 0x9f49
    14bc:	bc04                	.insn	2, 0xbc04
    14be:	c00a                	.insn	2, 0xc00a
    14c0:	020a                	.insn	2, 0x020a
    14c2:	9f48                	.insn	2, 0x9f48
    14c4:	c004                	.insn	2, 0xc004
    14c6:	c40a                	.insn	2, 0xc40a
    14c8:	020a                	.insn	2, 0x020a
    14ca:	c4049f47          	.insn	4, 0xc4049f47
    14ce:	c80a                	.insn	2, 0xc80a
    14d0:	020a                	.insn	2, 0x020a
    14d2:	9f46                	.insn	2, 0x9f46
    14d4:	c804                	.insn	2, 0xc804
    14d6:	cc0a                	.insn	2, 0xcc0a
    14d8:	020a                	.insn	2, 0x020a
    14da:	9f45                	.insn	2, 0x9f45
    14dc:	cc04                	.insn	2, 0xcc04
    14de:	d00a                	.insn	2, 0xd00a
    14e0:	020a                	.insn	2, 0x020a
    14e2:	9f44                	.insn	2, 0x9f44
    14e4:	d004                	.insn	2, 0xd004
    14e6:	d40a                	.insn	2, 0xd40a
    14e8:	020a                	.insn	2, 0x020a
    14ea:	d4049f43          	.insn	4, 0xd4049f43
    14ee:	d80a                	.insn	2, 0xd80a
    14f0:	020a                	.insn	2, 0x020a
    14f2:	9f42                	.insn	2, 0x9f42
    14f4:	d804                	.insn	2, 0xd804
    14f6:	dc0a                	.insn	2, 0xdc0a
    14f8:	020a                	.insn	2, 0x020a
    14fa:	9f41                	.insn	2, 0x9f41
    14fc:	dc04                	.insn	2, 0xdc04
    14fe:	e00a                	.insn	2, 0xe00a
    1500:	020a                	.insn	2, 0x020a
    1502:	9f40                	.insn	2, 0x9f40
    1504:	e004                	.insn	2, 0xe004
    1506:	e40a                	.insn	2, 0xe40a
    1508:	020a                	.insn	2, 0x020a
    150a:	e4049f3f 020ae80a 	.insn	8, 0x020ae80ae4049f3f
    1512:	9f3e                	.insn	2, 0x9f3e
    1514:	e804                	.insn	2, 0xe804
    1516:	ec0a                	.insn	2, 0xec0a
    1518:	020a                	.insn	2, 0x020a
    151a:	9f3d                	.insn	2, 0x9f3d
    151c:	ec04                	.insn	2, 0xec04
    151e:	f00a                	.insn	2, 0xf00a
    1520:	020a                	.insn	2, 0x020a
    1522:	9f3c                	.insn	2, 0x9f3c
    1524:	f004                	.insn	2, 0xf004
    1526:	f40a                	.insn	2, 0xf40a
    1528:	020a                	.insn	2, 0x020a
    152a:	f4049f3b          	.insn	4, 0xf4049f3b
    152e:	f80a                	.insn	2, 0xf80a
    1530:	020a                	.insn	2, 0x020a
    1532:	9f3a                	.insn	2, 0x9f3a
    1534:	f804                	.insn	2, 0xf804
    1536:	fc0a                	.insn	2, 0xfc0a
    1538:	020a                	.insn	2, 0x020a
    153a:	9f39                	.insn	2, 0x9f39
    153c:	fc04                	.insn	2, 0xfc04
    153e:	800a                	.insn	2, 0x800a
    1540:	9f38020b          	.insn	4, 0x9f38020b
    1544:	8004                	.insn	2, 0x8004
    1546:	020b840b          	.insn	4, 0x020b840b
    154a:	84049f37          	lui	t5,0x84049
    154e:	020b880b          	.insn	4, 0x020b880b
    1552:	9f36                	.insn	2, 0x9f36
    1554:	8804                	.insn	2, 0x8804
    1556:	020b8c0b          	.insn	4, 0x020b8c0b
    155a:	9f35                	.insn	2, 0x9f35
    155c:	8c04                	.insn	2, 0x8c04
    155e:	020b900b          	.insn	4, 0x020b900b
    1562:	9f34                	.insn	2, 0x9f34
    1564:	9004                	.insn	2, 0x9004
    1566:	020b940b          	.insn	4, 0x020b940b
    156a:	94049f33          	.insn	4, 0x94049f33
    156e:	020b980b          	.insn	4, 0x020b980b
    1572:	9f32                	.insn	2, 0x9f32
    1574:	9804                	.insn	2, 0x9804
    1576:	020b9c0b          	.insn	4, 0x020b9c0b
    157a:	9f31                	.insn	2, 0x9f31
    157c:	9c04                	.insn	2, 0x9c04
    157e:	020ba00b          	.insn	4, 0x020ba00b
    1582:	9f30                	.insn	2, 0x9f30
    1584:	a004                	.insn	2, 0xa004
    1586:	040ba40b          	.insn	4, 0x040ba40b
    158a:	3130                	.insn	2, 0x3130
    158c:	9f1c                	.insn	2, 0x9f1c
    158e:	0400                	.insn	2, 0x0400
    1590:	0ba4                	.insn	2, 0x0ba4
    1592:	0bd0                	.insn	2, 0x0bd0
    1594:	5a01                	.insn	2, 0x5a01
    1596:	d004                	.insn	2, 0xd004
    1598:	010ec00b          	.insn	4, 0x010ec00b
    159c:	0059                	.insn	2, 0x0059
    159e:	f004                	.insn	2, 0xf004
    15a0:	030fdc0b          	.insn	4, 0x030fdc0b
    15a4:	0311                	.insn	2, 0x0311
    15a6:	009f f004 b80b      	.insn	6, 0xb80bf004009f
    15ac:	030e                	.insn	2, 0x030e
    15ae:	0011                	.insn	2, 0x0011
    15b0:	009f f004 fc0b      	.insn	6, 0xfc0bf004009f
    15b6:	0011030b          	.insn	4, 0x0011030b
    15ba:	049f 0bfc 0e90      	.insn	6, 0x0e900bfc049f
    15c0:	5801                	.insn	2, 0x5801
    15c2:	a404                	.insn	2, 0xa404
    15c4:	b80e                	.insn	2, 0xb80e
    15c6:	010e                	.insn	2, 0x010e
    15c8:	0058                	.insn	2, 0x0058
    15ca:	b004                	.insn	2, 0xb004
    15cc:	ec0c                	.insn	2, 0xec0c
    15ce:	010d                	.insn	2, 0x010d
    15d0:	005d                	.insn	2, 0x005d
    15d2:	b404                	.insn	2, 0xb404
    15d4:	d80c                	.insn	2, 0xd80c
    15d6:	010c                	.insn	2, 0x010c
    15d8:	0cfc045b          	.insn	4, 0x0cfc045b
    15dc:	0d84                	.insn	2, 0x0d84
    15de:	5c01                	.insn	2, 0x5c01
    15e0:	8804                	.insn	2, 0x8804
    15e2:	940d                	.insn	2, 0x940d
    15e4:	010d                	.insn	2, 0x010d
    15e6:	045e                	.insn	2, 0x045e
    15e8:	0d9c                	.insn	2, 0x0d9c
    15ea:	0dac                	.insn	2, 0x0dac
    15ec:	5f01                	.insn	2, 0x5f01
    15ee:	b404                	.insn	2, 0xb404
    15f0:	c40d                	.insn	2, 0xc40d
    15f2:	010d                	.insn	2, 0x010d
    15f4:	0de4045b          	.insn	4, 0x0de4045b
    15f8:	0de8                	.insn	2, 0x0de8
    15fa:	5b01                	.insn	2, 0x5b01
    15fc:	0400                	.insn	2, 0x0400
    15fe:	0cc8                	.insn	2, 0x0cc8
    1600:	0cfc                	.insn	2, 0x0cfc
    1602:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <_stack_top+0xffef3a30>
    1606:	fc04                	.insn	2, 0xfc04
    1608:	880c                	.insn	2, 0x880c
    160a:	030d                	.insn	2, 0x030d
    160c:	0111                	.insn	2, 0x0111
    160e:	049f 0d88 0d98      	.insn	6, 0x0d980d88049f
    1614:	9f021103          	lh	sp,-1552(tp) # fffff9f0 <_stack_top+0xffef3a30>
    1618:	9804                	.insn	2, 0x9804
    161a:	9c0d                	.insn	2, 0x9c0d
    161c:	030d                	.insn	2, 0x030d
    161e:	0511                	.insn	2, 0x0511
    1620:	049f 0d9c 0db0      	.insn	6, 0x0db00d9c049f
    1626:	9f031103          	lh	sp,-1552(t1)
    162a:	b004                	.insn	2, 0xb004
    162c:	b40d                	.insn	2, 0xb40d
    162e:	030d                	.insn	2, 0x030d
    1630:	0611                	.insn	2, 0x0611
    1632:	049f 0db4 0dc4      	.insn	6, 0x0dc40db4049f
    1638:	9f041103          	lh	sp,-1552(s0)
    163c:	c404                	.insn	2, 0xc404
    163e:	e40d                	.insn	2, 0xe40d
    1640:	030d                	.insn	2, 0x030d
    1642:	0711                	.insn	2, 0x0711
    1644:	049f 0de4 0de8      	.insn	6, 0x0de80de4049f
    164a:	9f081103          	lh	sp,-1552(a6)
    164e:	0400                	.insn	2, 0x0400
    1650:	0dec                	.insn	2, 0x0dec
    1652:	0e88                	.insn	2, 0x0e88
    1654:	7d0d                	.insn	2, 0x7d0d
    1656:	a800                	.insn	2, 0xa800
    1658:	008080ab          	.insn	4, 0x008080ab
    165c:	afa8                	.insn	2, 0xafa8
    165e:	8080                	.insn	2, 0x8080
    1660:	9f00                	.insn	2, 0x9f00
    1662:	a404                	.insn	2, 0xa404
    1664:	b80e                	.insn	2, 0xb80e
    1666:	0d0e                	.insn	2, 0x0d0e
    1668:	007d                	.insn	2, 0x007d
    166a:	aba8                	.insn	2, 0xaba8
    166c:	8080                	.insn	2, 0x8080
    166e:	a800                	.insn	2, 0xa800
    1670:	008080af          	.insn	4, 0x008080af
    1674:	009f ec04 f00d      	.insn	6, 0xf00dec04009f
    167a:	010d                	.insn	2, 0x010d
    167c:	dc04005b          	.insn	4, 0xdc04005b
    1680:	010ff80f          	.insn	4, 0x010ff80f
    1684:	045a                	.insn	2, 0x045a
    1686:	0ff8                	.insn	2, 0x0ff8
    1688:	11bc                	.insn	2, 0x11bc
    168a:	6201                	.insn	2, 0x6201
    168c:	0400                	.insn	2, 0x0400
    168e:	0fdc                	.insn	2, 0x0fdc
    1690:	0ff4                	.insn	2, 0x0ff4
    1692:	5b01                	.insn	2, 0x5b01
    1694:	f404                	.insn	2, 0xf404
    1696:	01118c0f          	.insn	4, 0x01118c0f
    169a:	0459                	.insn	2, 0x0459
    169c:	1198                	.insn	2, 0x1198
    169e:	119c                	.insn	2, 0x119c
    16a0:	5901                	.insn	2, 0x5901
    16a2:	0400                	.insn	2, 0x0400
    16a4:	1088                	.insn	2, 0x1088
    16a6:	11c4                	.insn	2, 0x11c4
    16a8:	3302                	.insn	2, 0x3302
    16aa:	009f 8804 b810      	.insn	6, 0xb8108804009f
    16b0:	0310                	.insn	2, 0x0310
    16b2:	0011                	.insn	2, 0x0011
    16b4:	049f 10b8 10e0      	.insn	6, 0x10e010b8049f
    16ba:	9f011103          	lh	sp,-1552(sp)
    16be:	e004                	.insn	2, 0xe004
    16c0:	9410                	.insn	2, 0x9410
    16c2:	0311                	.insn	2, 0x0311
    16c4:	0211                	.insn	2, 0x0211
    16c6:	049f 1194 1198      	.insn	6, 0x11981194049f
    16cc:	9f031103          	lh	sp,-1552(t1)
    16d0:	1000                	.insn	2, 0x1000
    16d2:	05000007          	.insn	4, 0x05000007
    16d6:	0400                	.insn	2, 0x0400
    16d8:	4000                	.insn	2, 0x4000
    16da:	0000                	.insn	2, 0x0000
    16dc:	0000                	.insn	2, 0x0000
    16de:	0001                	.insn	2, 0x0001
    16e0:	0b00                	.insn	2, 0x0b00
    16e2:	0001                	.insn	2, 0x0001
    16e4:	1100                	.insn	2, 0x1100
    16e6:	0001                	.insn	2, 0x0001
    16e8:	1700                	.insn	2, 0x1700
    16ea:	0001                	.insn	2, 0x0001
    16ec:	2c00                	.insn	2, 0x2c00
    16ee:	0001                	.insn	2, 0x0001
    16f0:	4000                	.insn	2, 0x4000
    16f2:	0001                	.insn	2, 0x0001
    16f4:	4800                	.insn	2, 0x4800
    16f6:	0001                	.insn	2, 0x0001
    16f8:	5000                	.insn	2, 0x5000
    16fa:	0001                	.insn	2, 0x0001
    16fc:	5800                	.insn	2, 0x5800
    16fe:	0001                	.insn	2, 0x0001
    1700:	6000                	.insn	2, 0x6000
    1702:	0001                	.insn	2, 0x0001
    1704:	7400                	.insn	2, 0x7400
    1706:	0001                	.insn	2, 0x0001
    1708:	7e00                	.insn	2, 0x7e00
    170a:	0001                	.insn	2, 0x0001
    170c:	8d00                	.insn	2, 0x8d00
    170e:	0001                	.insn	2, 0x0001
    1710:	9d00                	.insn	2, 0x9d00
    1712:	0001                	.insn	2, 0x0001
    1714:	ad00                	.insn	2, 0xad00
    1716:	0001                	.insn	2, 0x0001
    1718:	1a00                	.insn	2, 0x1a00
    171a:	0002                	.insn	2, 0x0002
    171c:	4900                	.insn	2, 0x4900
    171e:	0002                	.insn	2, 0x0002
    1720:	8800                	.insn	2, 0x8800
    1722:	0002                	.insn	2, 0x0002
    1724:	9e00                	.insn	2, 0x9e00
    1726:	0002                	.insn	2, 0x0002
    1728:	b400                	.insn	2, 0xb400
    172a:	0002                	.insn	2, 0x0002
    172c:	d200                	.insn	2, 0xd200
    172e:	0002                	.insn	2, 0x0002
    1730:	1200                	.insn	2, 0x1200
    1732:	25000003          	lb	zero,592(zero) # 250 <_start-0xffdb0>
    1736:	02000003          	lb	zero,32(zero) # 20 <_start-0xfffe0>
    173a:	0004                	.insn	2, 0x0004
    173c:	1600                	.insn	2, 0x1600
    173e:	0004                	.insn	2, 0x0004
    1740:	1e00                	.insn	2, 0x1e00
    1742:	0004                	.insn	2, 0x0004
    1744:	2600                	.insn	2, 0x2600
    1746:	0004                	.insn	2, 0x0004
    1748:	2e00                	.insn	2, 0x2e00
    174a:	0004                	.insn	2, 0x0004
    174c:	4400                	.insn	2, 0x4400
    174e:	0004                	.insn	2, 0x0004
    1750:	5a00                	.insn	2, 0x5a00
    1752:	0004                	.insn	2, 0x0004
    1754:	7800                	.insn	2, 0x7800
    1756:	0004                	.insn	2, 0x0004
    1758:	9c00                	.insn	2, 0x9c00
    175a:	0004                	.insn	2, 0x0004
    175c:	b200                	.insn	2, 0xb200
    175e:	0004                	.insn	2, 0x0004
    1760:	ba00                	.insn	2, 0xba00
    1762:	0004                	.insn	2, 0x0004
    1764:	cb00                	.insn	2, 0xcb00
    1766:	0004                	.insn	2, 0x0004
    1768:	e100                	.insn	2, 0xe100
    176a:	0004                	.insn	2, 0x0004
    176c:	f100                	.insn	2, 0xf100
    176e:	0004                	.insn	2, 0x0004
    1770:	f900                	.insn	2, 0xf900
    1772:	0004                	.insn	2, 0x0004
    1774:	0200                	.insn	2, 0x0200
    1776:	0005                	.insn	2, 0x0005
    1778:	0a00                	.insn	2, 0x0a00
    177a:	0005                	.insn	2, 0x0005
    177c:	1e00                	.insn	2, 0x1e00
    177e:	0005                	.insn	2, 0x0005
    1780:	2600                	.insn	2, 0x2600
    1782:	0005                	.insn	2, 0x0005
    1784:	2e00                	.insn	2, 0x2e00
    1786:	0005                	.insn	2, 0x0005
    1788:	3800                	.insn	2, 0x3800
    178a:	0005                	.insn	2, 0x0005
    178c:	4000                	.insn	2, 0x4000
    178e:	0005                	.insn	2, 0x0005
    1790:	5600                	.insn	2, 0x5600
    1792:	0005                	.insn	2, 0x0005
    1794:	7400                	.insn	2, 0x7400
    1796:	0005                	.insn	2, 0x0005
    1798:	9200                	.insn	2, 0x9200
    179a:	0005                	.insn	2, 0x0005
    179c:	aa00                	.insn	2, 0xaa00
    179e:	0005                	.insn	2, 0x0005
    17a0:	b300                	.insn	2, 0xb300
    17a2:	0005                	.insn	2, 0x0005
    17a4:	bb00                	.insn	2, 0xbb00
    17a6:	0005                	.insn	2, 0x0005
    17a8:	cb00                	.insn	2, 0xcb00
    17aa:	0005                	.insn	2, 0x0005
    17ac:	ea00                	.insn	2, 0xea00
    17ae:	0005                	.insn	2, 0x0005
    17b0:	1000                	.insn	2, 0x1000
    17b2:	0006                	.insn	2, 0x0006
    17b4:	2100                	.insn	2, 0x2100
    17b6:	0006                	.insn	2, 0x0006
    17b8:	3200                	.insn	2, 0x3200
    17ba:	0006                	.insn	2, 0x0006
    17bc:	5100                	.insn	2, 0x5100
    17be:	0006                	.insn	2, 0x0006
    17c0:	6100                	.insn	2, 0x6100
    17c2:	0006                	.insn	2, 0x0006
    17c4:	6900                	.insn	2, 0x6900
    17c6:	0006                	.insn	2, 0x0006
    17c8:	7800                	.insn	2, 0x7800
    17ca:	0006                	.insn	2, 0x0006
    17cc:	8800                	.insn	2, 0x8800
    17ce:	0006                	.insn	2, 0x0006
    17d0:	a100                	.insn	2, 0xa100
    17d2:	0006                	.insn	2, 0x0006
    17d4:	d600                	.insn	2, 0xd600
    17d6:	0006                	.insn	2, 0x0006
    17d8:	fe00                	.insn	2, 0xfe00
    17da:	0006                	.insn	2, 0x0006
    17dc:	0400                	.insn	2, 0x0400
    17de:	2000                	.insn	2, 0x2000
    17e0:	5a01                	.insn	2, 0x5a01
    17e2:	3004                	.insn	2, 0x3004
    17e4:	0134                	.insn	2, 0x0134
    17e6:	005a                	.insn	2, 0x005a
    17e8:	1404                	.insn	2, 0x1404
    17ea:	0140                	.insn	2, 0x0140
    17ec:	0058                	.insn	2, 0x0058
    17ee:	3404                	.insn	2, 0x3404
    17f0:	0140                	.insn	2, 0x0140
    17f2:	005a                	.insn	2, 0x005a
    17f4:	5c04                	.insn	2, 0x5c04
    17f6:	0180                	.insn	2, 0x0180
    17f8:	5a01                	.insn	2, 0x5a01
    17fa:	8004                	.insn	2, 0x8004
    17fc:	bc01                	.insn	2, 0xbc01
    17fe:	0101                	.insn	2, 0x0101
    1800:	0459                	.insn	2, 0x0459
    1802:	01d8                	.insn	2, 0x01d8
    1804:	01e0                	.insn	2, 0x01e0
    1806:	5901                	.insn	2, 0x5901
    1808:	0400                	.insn	2, 0x0400
    180a:	0580                	.insn	2, 0x0580
    180c:	078c                	.insn	2, 0x078c
    180e:	850d                	.insn	2, 0x850d
    1810:	a800                	.insn	2, 0xa800
    1812:	008080ab          	.insn	4, 0x008080ab
    1816:	afa8                	.insn	2, 0xafa8
    1818:	8080                	.insn	2, 0x8080
    181a:	9f00                	.insn	2, 0x9f00
    181c:	0400                	.insn	2, 0x0400
    181e:	05d4                	.insn	2, 0x05d4
    1820:	0998                	.insn	2, 0x0998
    1822:	5901                	.insn	2, 0x5901
    1824:	0400                	.insn	2, 0x0400
    1826:	0aac                	.insn	2, 0x0aac
    1828:	0ae8                	.insn	2, 0x0ae8
    182a:	5a01                	.insn	2, 0x5a01
    182c:	0400                	.insn	2, 0x0400
    182e:	0ae4                	.insn	2, 0x0ae4
    1830:	0bac                	.insn	2, 0x0bac
    1832:	6201                	.insn	2, 0x6201
    1834:	0400                	.insn	2, 0x0400
    1836:	0afc                	.insn	2, 0x0afc
    1838:	0b80                	.insn	2, 0x0b80
    183a:	5a01                	.insn	2, 0x5a01
    183c:	0400                	.insn	2, 0x0400
    183e:	0ae8                	.insn	2, 0x0ae8
    1840:	0aec                	.insn	2, 0x0aec
    1842:	7b06                	.insn	2, 0x7b06
    1844:	7a00                	.insn	2, 0x7a00
    1846:	2200                	.insn	2, 0x2200
    1848:	049f 0aec 0af4      	.insn	6, 0x0af40aec049f
    184e:	5a01                	.insn	2, 0x5a01
    1850:	0400                	.insn	2, 0x0400
    1852:	0b80                	.insn	2, 0x0b80
    1854:	0b90                	.insn	2, 0x0b90
    1856:	9f187a03          	.insn	4, 0x9f187a03
    185a:	0400                	.insn	2, 0x0400
    185c:	0bc8                	.insn	2, 0x0bc8
    185e:	0c8c                	.insn	2, 0x0c8c
    1860:	5a01                	.insn	2, 0x5a01
    1862:	8c04                	.insn	2, 0x8c04
    1864:	bc0c                	.insn	2, 0xbc0c
    1866:	0062010f          	.insn	4, 0x0062010f
    186a:	c804                	.insn	2, 0xc804
    186c:	010c880b          	.insn	4, 0x010c880b
    1870:	0c88045b          	.insn	4, 0x0c88045b
    1874:	14c8                	.insn	2, 0x14c8
    1876:	7202                	.insn	2, 0x7202
    1878:	002c                	.insn	2, 0x002c
    187a:	c804                	.insn	2, 0xc804
    187c:	010c840b          	.insn	4, 0x010c840b
    1880:	045c                	.insn	2, 0x045c
    1882:	0c84                	.insn	2, 0x0c84
    1884:	14c8                	.insn	2, 0x14c8
    1886:	7202                	.insn	2, 0x7202
    1888:	0030                	.insn	2, 0x0030
    188a:	a004                	.insn	2, 0xa004
    188c:	a80c                	.insn	2, 0xa80c
    188e:	030c                	.insn	2, 0x030c
    1890:	0011                	.insn	2, 0x0011
    1892:	049f 0ca8 0cac      	.insn	6, 0x0cac0ca8049f
    1898:	9f011103          	lh	sp,-1552(sp)
    189c:	ac04                	.insn	2, 0xac04
    189e:	b00c                	.insn	2, 0xb00c
    18a0:	030c                	.insn	2, 0x030c
    18a2:	0211                	.insn	2, 0x0211
    18a4:	049f 0cb0 0cb4      	.insn	6, 0x0cb40cb0049f
    18aa:	9f031103          	lh	sp,-1552(t1)
    18ae:	b404                	.insn	2, 0xb404
    18b0:	b80c                	.insn	2, 0xb80c
    18b2:	030c                	.insn	2, 0x030c
    18b4:	0411                	.insn	2, 0x0411
    18b6:	049f 0cb8 0cbc      	.insn	6, 0x0cbc0cb8049f
    18bc:	9f051103          	lh	sp,-1552(a0)
    18c0:	bc04                	.insn	2, 0xbc04
    18c2:	c00c                	.insn	2, 0xc00c
    18c4:	030c                	.insn	2, 0x030c
    18c6:	0611                	.insn	2, 0x0611
    18c8:	049f 0cc0 0cc4      	.insn	6, 0x0cc40cc0049f
    18ce:	9f071103          	lh	sp,-1552(a4)
    18d2:	c404                	.insn	2, 0xc404
    18d4:	c80c                	.insn	2, 0xc80c
    18d6:	030c                	.insn	2, 0x030c
    18d8:	0811                	.insn	2, 0x0811
    18da:	049f 0cc8 0ccc      	.insn	6, 0x0ccc0cc8049f
    18e0:	9f091103          	lh	sp,-1552(s2)
    18e4:	cc04                	.insn	2, 0xcc04
    18e6:	d00c                	.insn	2, 0xd00c
    18e8:	030c                	.insn	2, 0x030c
    18ea:	0a11                	.insn	2, 0x0a11
    18ec:	049f 0cd0 0cd4      	.insn	6, 0x0cd40cd0049f
    18f2:	9f0b1103          	lh	sp,-1552(s6)
    18f6:	0400                	.insn	2, 0x0400
    18f8:	0cd0                	.insn	2, 0x0cd0
    18fa:	0ce4                	.insn	2, 0x0ce4
    18fc:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <_stack_top+0xffef3a30>
    1900:	e404                	.insn	2, 0xe404
    1902:	980c                	.insn	2, 0x980c
    1904:	010d                	.insn	2, 0x010d
    1906:	0d9c045b          	.insn	4, 0x0d9c045b
    190a:	0da8                	.insn	2, 0x0da8
    190c:	5f01                	.insn	2, 0x5f01
    190e:	a804                	.insn	2, 0xa804
    1910:	b00d                	.insn	2, 0xb00d
    1912:	030d                	.insn	2, 0x030d
    1914:	0011                	.insn	2, 0x0011
    1916:	049f 0db0 0db4      	.insn	6, 0x0db40db0049f
    191c:	5b01                	.insn	2, 0x5b01
    191e:	c404                	.insn	2, 0xc404
    1920:	e00d                	.insn	2, 0xe00d
    1922:	010d                	.insn	2, 0x010d
    1924:	005f d004 e40c      	.insn	6, 0xe40cd004005f
    192a:	030c                	.insn	2, 0x030c
    192c:	0011                	.insn	2, 0x0011
    192e:	049f 0ce4 0d94      	.insn	6, 0x0d940ce4049f
    1934:	5b01                	.insn	2, 0x5b01
    1936:	9404                	.insn	2, 0x9404
    1938:	a80d                	.insn	2, 0xa80d
    193a:	010d                	.insn	2, 0x010d
    193c:	045f 0da8 0db0      	.insn	6, 0x0db00da8045f
    1942:	9f001103          	lh	sp,-1552(zero) # fffff9f0 <_stack_top+0xffef3a30>
    1946:	b004                	.insn	2, 0xb004
    1948:	b40d                	.insn	2, 0xb40d
    194a:	010d                	.insn	2, 0x010d
    194c:	0dc4045b          	.insn	4, 0x0dc4045b
    1950:	0de0                	.insn	2, 0x0de0
    1952:	9f081103          	lh	sp,-1552(a6)
    1956:	8004                	.insn	2, 0x8004
    1958:	900e                	.insn	2, 0x900e
    195a:	010e                	.insn	2, 0x010e
    195c:	045f 0e90 0e98      	.insn	6, 0x0e980e90045f
    1962:	5e01                	.insn	2, 0x5e01
    1964:	0400                	.insn	2, 0x0400
    1966:	0ea4                	.insn	2, 0x0ea4
    1968:	12a8                	.insn	2, 0x12a8
    196a:	5901                	.insn	2, 0x5901
    196c:	dc04                	.insn	2, 0xdc04
    196e:	9412                	.insn	2, 0x9412
    1970:	04590113          	addi	sp,s2,69
    1974:	13c4                	.insn	2, 0x13c4
    1976:	14c8                	.insn	2, 0x14c8
    1978:	5901                	.insn	2, 0x5901
    197a:	0400                	.insn	2, 0x0400
    197c:	0fd8                	.insn	2, 0x0fd8
    197e:	12e8                	.insn	2, 0x12e8
    1980:	6601                	.insn	2, 0x6601
    1982:	f404                	.insn	2, 0xf404
    1984:	fc12                	.insn	2, 0xfc12
    1986:	0112                	.insn	2, 0x0112
    1988:	0466                	.insn	2, 0x0466
    198a:	13c4                	.insn	2, 0x13c4
    198c:	14c8                	.insn	2, 0x14c8
    198e:	6601                	.insn	2, 0x6601
    1990:	0400                	.insn	2, 0x0400
    1992:	0fe8                	.insn	2, 0x0fe8
    1994:	0ffc                	.insn	2, 0x0ffc
    1996:	3002                	.insn	2, 0x3002
    1998:	049f 0ffc 11e8      	.insn	6, 0x11e80ffc049f
    199e:	5801                	.insn	2, 0x5801
    19a0:	f404                	.insn	2, 0xf404
    19a2:	fc12                	.insn	2, 0xfc12
    19a4:	0112                	.insn	2, 0x0112
    19a6:	0458                	.insn	2, 0x0458
    19a8:	13c4                	.insn	2, 0x13c4
    19aa:	14c8                	.insn	2, 0x14c8
    19ac:	5801                	.insn	2, 0x5801
    19ae:	0400                	.insn	2, 0x0400
    19b0:	10b8                	.insn	2, 0x10b8
    19b2:	10bc                	.insn	2, 0x10bc
    19b4:	8b0c                	.insn	2, 0x8b0c
    19b6:	1100                	.insn	2, 0x1100
    19b8:	1c10                	.insn	2, 0x1c10
    19ba:	7f11                	.insn	2, 0x7f11
    19bc:	2201111b          	.insn	4, 0x2201111b
    19c0:	049f 10c4 11e8      	.insn	6, 0x11e810c4049f
    19c6:	8b09                	.insn	2, 0x8b09
    19c8:	1100                	.insn	2, 0x1100
    19ca:	1c10                	.insn	2, 0x1c10
    19cc:	7f11                	.insn	2, 0x7f11
    19ce:	f4049f1b          	.insn	4, 0xf4049f1b
    19d2:	fc12                	.insn	2, 0xfc12
    19d4:	0912                	.insn	2, 0x0912
    19d6:	1011008b          	.insn	4, 0x1011008b
    19da:	111c                	.insn	2, 0x111c
    19dc:	049f1b7f 14c813d0 	.insn	12, 0x11008b0914c813d0049f1b7f
    19e4:	11008b09 
    19e8:	1c10                	.insn	2, 0x1c10
    19ea:	7f11                	.insn	2, 0x7f11
    19ec:	04009f1b          	.insn	4, 0x04009f1b
    19f0:	10e8                	.insn	2, 0x10e8
    19f2:	11e8                	.insn	2, 0x11e8
    19f4:	9f011103          	lh	sp,-1552(sp)
    19f8:	d004                	.insn	2, 0xd004
    19fa:	0314c813          	xori	a6,s1,49
    19fe:	0111                	.insn	2, 0x0111
    1a00:	009f e804 ec10      	.insn	6, 0xec10e804009f
    1a06:	0310                	.insn	2, 0x0310
    1a08:	0011                	.insn	2, 0x0011
    1a0a:	049f 10ec 10f0      	.insn	6, 0x10f010ec049f
    1a10:	1105                	.insn	2, 0x1105
    1a12:	2300                	.insn	2, 0x2300
    1a14:	9f01                	.insn	2, 0x9f01
    1a16:	f004                	.insn	2, 0xf004
    1a18:	f410                	.insn	2, 0xf410
    1a1a:	0310                	.insn	2, 0x0310
    1a1c:	0111                	.insn	2, 0x0111
    1a1e:	049f 10f4 10f8      	.insn	6, 0x10f810f4049f
    1a24:	1105                	.insn	2, 0x1105
    1a26:	2301                	.insn	2, 0x2301
    1a28:	9f01                	.insn	2, 0x9f01
    1a2a:	f804                	.insn	2, 0xf804
    1a2c:	fc10                	.insn	2, 0xfc10
    1a2e:	0310                	.insn	2, 0x0310
    1a30:	0211                	.insn	2, 0x0211
    1a32:	049f 10fc 1184      	.insn	6, 0x118410fc049f
    1a38:	1105                	.insn	2, 0x1105
    1a3a:	2302                	.insn	2, 0x2302
    1a3c:	9f01                	.insn	2, 0x9f01
    1a3e:	8404                	.insn	2, 0x8404
    1a40:	8811                	.insn	2, 0x8811
    1a42:	0311                	.insn	2, 0x0311
    1a44:	0311                	.insn	2, 0x0311
    1a46:	049f 1188 1190      	.insn	6, 0x11901188049f
    1a4c:	1105                	.insn	2, 0x1105
    1a4e:	9f012303          	lw	t1,-1552(sp)
    1a52:	9004                	.insn	2, 0x9004
    1a54:	9411                	.insn	2, 0x9411
    1a56:	0311                	.insn	2, 0x0311
    1a58:	0411                	.insn	2, 0x0411
    1a5a:	049f 1194 119c      	.insn	6, 0x119c1194049f
    1a60:	1105                	.insn	2, 0x1105
    1a62:	2304                	.insn	2, 0x2304
    1a64:	9f01                	.insn	2, 0x9f01
    1a66:	9c04                	.insn	2, 0x9c04
    1a68:	a011                	.insn	2, 0xa011
    1a6a:	0311                	.insn	2, 0x0311
    1a6c:	0511                	.insn	2, 0x0511
    1a6e:	049f 11a0 11a8      	.insn	6, 0x11a811a0049f
    1a74:	1105                	.insn	2, 0x1105
    1a76:	2305                	.insn	2, 0x2305
    1a78:	9f01                	.insn	2, 0x9f01
    1a7a:	a804                	.insn	2, 0xa804
    1a7c:	ac11                	.insn	2, 0xac11
    1a7e:	0311                	.insn	2, 0x0311
    1a80:	0611                	.insn	2, 0x0611
    1a82:	049f 11ac 11b4      	.insn	6, 0x11b411ac049f
    1a88:	1105                	.insn	2, 0x1105
    1a8a:	2306                	.insn	2, 0x2306
    1a8c:	9f01                	.insn	2, 0x9f01
    1a8e:	b404                	.insn	2, 0xb404
    1a90:	b811                	.insn	2, 0xb811
    1a92:	0311                	.insn	2, 0x0311
    1a94:	0711                	.insn	2, 0x0711
    1a96:	049f 11b8 11c0      	.insn	6, 0x11c011b8049f
    1a9c:	1105                	.insn	2, 0x1105
    1a9e:	9f012307          	.insn	4, 0x9f012307
    1aa2:	c004                	.insn	2, 0xc004
    1aa4:	c411                	.insn	2, 0xc411
    1aa6:	0311                	.insn	2, 0x0311
    1aa8:	0811                	.insn	2, 0x0811
    1aaa:	049f 11c4 11cc      	.insn	6, 0x11cc11c4049f
    1ab0:	1105                	.insn	2, 0x1105
    1ab2:	2308                	.insn	2, 0x2308
    1ab4:	9f01                	.insn	2, 0x9f01
    1ab6:	cc04                	.insn	2, 0xcc04
    1ab8:	d011                	.insn	2, 0xd011
    1aba:	0311                	.insn	2, 0x0311
    1abc:	0911                	.insn	2, 0x0911
    1abe:	049f 11d0 11d8      	.insn	6, 0x11d811d0049f
    1ac4:	1105                	.insn	2, 0x1105
    1ac6:	2309                	.insn	2, 0x2309
    1ac8:	9f01                	.insn	2, 0x9f01
    1aca:	d804                	.insn	2, 0xd804
    1acc:	dc11                	.insn	2, 0xdc11
    1ace:	0311                	.insn	2, 0x0311
    1ad0:	0a11                	.insn	2, 0x0a11
    1ad2:	049f 11dc 11e8      	.insn	6, 0x11e811dc049f
    1ad8:	1105                	.insn	2, 0x1105
    1ada:	230a                	.insn	2, 0x230a
    1adc:	9f01                	.insn	2, 0x9f01
    1ade:	0400                	.insn	2, 0x0400
    1ae0:	1294                	.insn	2, 0x1294
    1ae2:	1298                	.insn	2, 0x1298
    1ae4:	7a06                	.insn	2, 0x7a06
    1ae6:	7b00                	.insn	2, 0x7b00
    1ae8:	2200                	.insn	2, 0x2200
    1aea:	049f 1298 12a0      	.insn	6, 0x12a01298049f
    1af0:	5a01                	.insn	2, 0x5a01
    1af2:	0400                	.insn	2, 0x0400
    1af4:	12ac                	.insn	2, 0x12ac
    1af6:	12b0                	.insn	2, 0x12b0
    1af8:	5901                	.insn	2, 0x5901
    1afa:	0400                	.insn	2, 0x0400
    1afc:	1284                	.insn	2, 0x1284
    1afe:	12a8                	.insn	2, 0x12a8
    1b00:	5901                	.insn	2, 0x5901
    1b02:	0400                	.insn	2, 0x0400
    1b04:	12dc                	.insn	2, 0x12dc
    1b06:	12e8                	.insn	2, 0x12e8
    1b08:	5901                	.insn	2, 0x5901
    1b0a:	0400                	.insn	2, 0x0400
    1b0c:	14c8                	.insn	2, 0x14c8
    1b0e:	158c                	.insn	2, 0x158c
    1b10:	5a01                	.insn	2, 0x5a01
    1b12:	8c04                	.insn	2, 0x8c04
    1b14:	a815                	.insn	2, 0xa815
    1b16:	0115                	.insn	2, 0x0115
    1b18:	0458                	.insn	2, 0x0458
    1b1a:	15a8                	.insn	2, 0x15a8
    1b1c:	15b0                	.insn	2, 0x15b0
    1b1e:	5a01                	.insn	2, 0x5a01
    1b20:	0400                	.insn	2, 0x0400
    1b22:	14c8                	.insn	2, 0x14c8
    1b24:	1588                	.insn	2, 0x1588
    1b26:	5b01                	.insn	2, 0x5b01
    1b28:	8804                	.insn	2, 0x8804
    1b2a:	c015                	.insn	2, 0xc015
    1b2c:	0115                	.insn	2, 0x0115
    1b2e:	0459                	.insn	2, 0x0459
    1b30:	1688                	.insn	2, 0x1688
    1b32:	1884                	.insn	2, 0x1884
    1b34:	5901                	.insn	2, 0x5901
    1b36:	0400                	.insn	2, 0x0400
    1b38:	14c8                	.insn	2, 0x14c8
    1b3a:	1584                	.insn	2, 0x1584
    1b3c:	5c01                	.insn	2, 0x5c01
    1b3e:	8404                	.insn	2, 0x8404
    1b40:	c015                	.insn	2, 0xc015
    1b42:	0115                	.insn	2, 0x0115
    1b44:	0462                	.insn	2, 0x0462
    1b46:	1688                	.insn	2, 0x1688
    1b48:	17a0                	.insn	2, 0x17a0
    1b4a:	6201                	.insn	2, 0x6201
    1b4c:	a004                	.insn	2, 0xa004
    1b4e:	021cdc17          	auipc	s8,0x21cd
    1b52:	0872                	.insn	2, 0x0872
    1b54:	0400                	.insn	2, 0x0400
    1b56:	179c                	.insn	2, 0x179c
    1b58:	1a84                	.insn	2, 0x1a84
    1b5a:	5901                	.insn	2, 0x5901
    1b5c:	8404                	.insn	2, 0x8404
    1b5e:	cc1a                	.insn	2, 0xcc1a
    1b60:	011a                	.insn	2, 0x011a
    1b62:	0462                	.insn	2, 0x0462
    1b64:	1ae0                	.insn	2, 0x1ae0
    1b66:	1c80                	.insn	2, 0x1c80
    1b68:	5901                	.insn	2, 0x5901
    1b6a:	b004                	.insn	2, 0xb004
    1b6c:	bc1c                	.insn	2, 0xbc1c
    1b6e:	011c                	.insn	2, 0x011c
    1b70:	0462                	.insn	2, 0x0462
    1b72:	1cc4                	.insn	2, 0x1cc4
    1b74:	1cdc                	.insn	2, 0x1cdc
    1b76:	5901                	.insn	2, 0x5901
    1b78:	0400                	.insn	2, 0x0400
    1b7a:	179c                	.insn	2, 0x179c
    1b7c:	1c90                	.insn	2, 0x1c90
    1b7e:	6301                	.insn	2, 0x6301
    1b80:	b004                	.insn	2, 0xb004
    1b82:	bc1c                	.insn	2, 0xbc1c
    1b84:	011c                	.insn	2, 0x011c
    1b86:	1cc40463          	beq	s0,a2,1d4e <_start-0xfe2b2>
    1b8a:	1cdc                	.insn	2, 0x1cdc
    1b8c:	6301                	.insn	2, 0x6301
    1b8e:	0400                	.insn	2, 0x0400
    1b90:	18cc                	.insn	2, 0x18cc
    1b92:	19dc                	.insn	2, 0x19dc
    1b94:	6801                	.insn	2, 0x6801
    1b96:	0400                	.insn	2, 0x0400
    1b98:	1990                	.insn	2, 0x1990
    1b9a:	19ac                	.insn	2, 0x19ac
    1b9c:	9f203003          	.insn	4, 0x9f203003
    1ba0:	d004                	.insn	2, 0xd004
    1ba2:	e019                	.insn	2, 0xe019
    1ba4:	0119                	.insn	2, 0x0119
    1ba6:	005a                	.insn	2, 0x005a
    1ba8:	e404                	.insn	2, 0xe404
    1baa:	a019                	.insn	2, 0xa019
    1bac:	0465011b          	.insn	4, 0x0465011b
    1bb0:	1c80                	.insn	2, 0x1c80
    1bb2:	1ca0                	.insn	2, 0x1ca0
    1bb4:	6501                	.insn	2, 0x6501
    1bb6:	b004                	.insn	2, 0xb004
    1bb8:	bc1c                	.insn	2, 0xbc1c
    1bba:	011c                	.insn	2, 0x011c
    1bbc:	0065                	.insn	2, 0x0065
    1bbe:	f404                	.insn	2, 0xf404
    1bc0:	8419                	.insn	2, 0x8419
    1bc2:	021a                	.insn	2, 0x021a
    1bc4:	9f30                	.insn	2, 0x9f30
    1bc6:	8404                	.insn	2, 0x8404
    1bc8:	801a                	.insn	2, 0x801a
    1bca:	0066011b          	.insn	4, 0x0066011b
    1bce:	c804                	.insn	2, 0xc804
    1bd0:	e81a                	.insn	2, 0xe81a
    1bd2:	011a                	.insn	2, 0x011a
    1bd4:	005a                	.insn	2, 0x005a
    1bd6:	c804                	.insn	2, 0xc804
    1bd8:	cc1a                	.insn	2, 0xcc1a
    1bda:	021a                	.insn	2, 0x021a
    1bdc:	9f30                	.insn	2, 0x9f30
    1bde:	0400                	.insn	2, 0x0400
    1be0:	1bb0                	.insn	2, 0x1bb0
    1be2:	1c80                	.insn	2, 0x1c80
    1be4:	6201                	.insn	2, 0x6201
    1be6:	0400                	.insn	2, 0x0400
    1be8:	1bb4                	.insn	2, 0x1bb4
    1bea:	1bb8                	.insn	2, 0x1bb8
    1bec:	7a06                	.insn	2, 0x7a06
    1bee:	7b00                	.insn	2, 0x7b00
    1bf0:	2200                	.insn	2, 0x2200
    1bf2:	049f 1bb8 1bc0      	.insn	6, 0x1bc01bb8049f
    1bf8:	5a01                	.insn	2, 0x5a01
    1bfa:	0400                	.insn	2, 0x0400
    1bfc:	1bcc                	.insn	2, 0x1bcc
    1bfe:	1bd0                	.insn	2, 0x1bd0
    1c00:	5a01                	.insn	2, 0x5a01
    1c02:	0400                	.insn	2, 0x0400
    1c04:	1ba0                	.insn	2, 0x1ba0
    1c06:	1bb0                	.insn	2, 0x1bb0
    1c08:	6201                	.insn	2, 0x6201
    1c0a:	0400                	.insn	2, 0x0400
    1c0c:	1bd0                	.insn	2, 0x1bd0
    1c0e:	1be0                	.insn	2, 0x1be0
    1c10:	9f187a03          	.insn	4, 0x9f187a03
    1c14:	0400                	.insn	2, 0x0400
    1c16:	1bfc                	.insn	2, 0x1bfc
    1c18:	1c80                	.insn	2, 0x1c80
    1c1a:	6801                	.insn	2, 0x6801
    1c1c:	0400                	.insn	2, 0x0400
    1c1e:	1cdc                	.insn	2, 0x1cdc
    1c20:	1da0                	.insn	2, 0x1da0
    1c22:	5a01                	.insn	2, 0x5a01
    1c24:	a004                	.insn	2, 0xa004
    1c26:	bc1d                	.insn	2, 0xbc1d
    1c28:	011d                	.insn	2, 0x011d
    1c2a:	0458                	.insn	2, 0x0458
    1c2c:	1dbc                	.insn	2, 0x1dbc
    1c2e:	1dc4                	.insn	2, 0x1dc4
    1c30:	5a01                	.insn	2, 0x5a01
    1c32:	0400                	.insn	2, 0x0400
    1c34:	1cdc                	.insn	2, 0x1cdc
    1c36:	1d9c                	.insn	2, 0x1d9c
    1c38:	5b01                	.insn	2, 0x5b01
    1c3a:	9c04                	.insn	2, 0x9c04
    1c3c:	d01d                	.insn	2, 0xd01d
    1c3e:	011d                	.insn	2, 0x011d
    1c40:	0462                	.insn	2, 0x0462
    1c42:	1ea0                	.insn	2, 0x1ea0
    1c44:	1ea4                	.insn	2, 0x1ea4
    1c46:	6201                	.insn	2, 0x6201
    1c48:	a404                	.insn	2, 0xa404
    1c4a:	e01e                	.insn	2, 0xe01e
    1c4c:	0224                	.insn	2, 0x0224
    1c4e:	1072                	.insn	2, 0x1072
    1c50:	0400                	.insn	2, 0x0400
    1c52:	1cdc                	.insn	2, 0x1cdc
    1c54:	1d98                	.insn	2, 0x1d98
    1c56:	5c01                	.insn	2, 0x5c01
    1c58:	9804                	.insn	2, 0x9804
    1c5a:	d41d                	.insn	2, 0xd41d
    1c5c:	011d                	.insn	2, 0x011d
    1c5e:	0459                	.insn	2, 0x0459
    1c60:	1ea0                	.insn	2, 0x1ea0
    1c62:	1ee4                	.insn	2, 0x1ee4
    1c64:	5901                	.insn	2, 0x5901
    1c66:	e404                	.insn	2, 0xe404
    1c68:	e01e                	.insn	2, 0xe01e
    1c6a:	0224                	.insn	2, 0x0224
    1c6c:	0072                	.insn	2, 0x0072
    1c6e:	0400                	.insn	2, 0x0400
    1c70:	1da0                	.insn	2, 0x1da0
    1c72:	1dd4                	.insn	2, 0x1dd4
    1c74:	7202                	.insn	2, 0x7202
    1c76:	0418                	.insn	2, 0x0418
    1c78:	1ea0                	.insn	2, 0x1ea0
    1c7a:	1fb0                	.insn	2, 0x1fb0
    1c7c:	7202                	.insn	2, 0x7202
    1c7e:	0418                	.insn	2, 0x0418
    1c80:	23c8                	.insn	2, 0x23c8
    1c82:	23f4                	.insn	2, 0x23f4
    1c84:	6001                	.insn	2, 0x6001
    1c86:	0400                	.insn	2, 0x0400
    1c88:	1ee0                	.insn	2, 0x1ee0
    1c8a:	24e0                	.insn	2, 0x24e0
    1c8c:	7202                	.insn	2, 0x7202
    1c8e:	0010                	.insn	2, 0x0010
    1c90:	e004                	.insn	2, 0xe004
    1c92:	e01e                	.insn	2, 0xe01e
    1c94:	0124                	.insn	2, 0x0124
    1c96:	e0040067          	jr	-512(s0)
    1c9a:	b01e                	.insn	2, 0xb01e
    1c9c:	021f 9f30 b004      	.insn	6, 0xb0049f30021f
    1ca2:	e01f 0124 0066      	.insn	6, 0x00660124e01f
    1ca8:	e004                	.insn	2, 0xe004
    1caa:	b01e                	.insn	2, 0xb01e
    1cac:	021f 9f30 b004      	.insn	6, 0xb0049f30021f
    1cb2:	881f 0122 0468      	.insn	6, 0x04680122881f
    1cb8:	2298                	.insn	2, 0x2298
    1cba:	22a0                	.insn	2, 0x22a0
    1cbc:	3002                	.insn	2, 0x3002
    1cbe:	049f 22a0 24e0      	.insn	6, 0x24e022a0049f
    1cc4:	6801                	.insn	2, 0x6801
    1cc6:	0400                	.insn	2, 0x0400
    1cc8:	1ee0                	.insn	2, 0x1ee0
    1cca:	1fb0                	.insn	2, 0x1fb0
    1ccc:	3002                	.insn	2, 0x3002
    1cce:	049f 1fb0 21f8      	.insn	6, 0x21f81fb0049f
    1cd4:	6a01                	.insn	2, 0x6a01
    1cd6:	8004                	.insn	2, 0x8004
    1cd8:	9822                	.insn	2, 0x9822
    1cda:	0122                	.insn	2, 0x0122
    1cdc:	046a                	.insn	2, 0x046a
    1cde:	2298                	.insn	2, 0x2298
    1ce0:	22a0                	.insn	2, 0x22a0
    1ce2:	3002                	.insn	2, 0x3002
    1ce4:	049f 22a0 24e0      	.insn	6, 0x24e022a0049f
    1cea:	6a01                	.insn	2, 0x6a01
    1cec:	0400                	.insn	2, 0x0400
    1cee:	1fbc                	.insn	2, 0x1fbc
    1cf0:	209c                	.insn	2, 0x209c
    1cf2:	7202                	.insn	2, 0x7202
    1cf4:	0408                	.insn	2, 0x0408
    1cf6:	20b8                	.insn	2, 0x20b8
    1cf8:	20ec                	.insn	2, 0x20ec
    1cfa:	7202                	.insn	2, 0x7202
    1cfc:	0008                	.insn	2, 0x0008
    1cfe:	f404                	.insn	2, 0xf404
    1d00:	9c1f 0320 2030      	.insn	6, 0x203003209c1f
    1d06:	049f 20d4 20e4      	.insn	6, 0x20e420d4049f
    1d0c:	5a01                	.insn	2, 0x5a01
    1d0e:	0400                	.insn	2, 0x0400
    1d10:	20a0                	.insn	2, 0x20a0
    1d12:	20a4                	.insn	2, 0x20a4
    1d14:	5a01                	.insn	2, 0x5a01
    1d16:	a404                	.insn	2, 0xa404
    1d18:	b020                	.insn	2, 0xb020
    1d1a:	0220                	.insn	2, 0x0220
    1d1c:	0c72                	.insn	2, 0x0c72
    1d1e:	e804                	.insn	2, 0xe804
    1d20:	ec20                	.insn	2, 0xec20
    1d22:	0120                	.insn	2, 0x0120
    1d24:	045a                	.insn	2, 0x045a
    1d26:	20ec                	.insn	2, 0x20ec
    1d28:	22d0                	.insn	2, 0x22d0
    1d2a:	7202                	.insn	2, 0x7202
    1d2c:	000c                	.insn	2, 0x000c
    1d2e:	9804                	.insn	2, 0x9804
    1d30:	9c20                	.insn	2, 0x9c20
    1d32:	0220                	.insn	2, 0x0220
    1d34:	9f30                	.insn	2, 0x9f30
    1d36:	f404                	.insn	2, 0xf404
    1d38:	b820                	.insn	2, 0xb820
    1d3a:	0122                	.insn	2, 0x0122
    1d3c:	0058                	.insn	2, 0x0058
    1d3e:	b804                	.insn	2, 0xb804
    1d40:	b821                	.insn	2, 0xb821
    1d42:	0122                	.insn	2, 0x0122
    1d44:	005a                	.insn	2, 0x005a
    1d46:	f004                	.insn	2, 0xf004
    1d48:	a021                	.insn	2, 0xa021
    1d4a:	0122                	.insn	2, 0x0122
    1d4c:	045e                	.insn	2, 0x045e
    1d4e:	22ac                	.insn	2, 0x22ac
    1d50:	22b0                	.insn	2, 0x22b0
    1d52:	5e01                	.insn	2, 0x5e01
    1d54:	0400                	.insn	2, 0x0400
    1d56:	22d4                	.insn	2, 0x22d4
    1d58:	22e0                	.insn	2, 0x22e0
    1d5a:	7202                	.insn	2, 0x7202
    1d5c:	0408                	.insn	2, 0x0408
    1d5e:	22e0                	.insn	2, 0x22e0
    1d60:	23c4                	.insn	2, 0x23c4
    1d62:	6201                	.insn	2, 0x6201
    1d64:	0400                	.insn	2, 0x0400
    1d66:	22d4                	.insn	2, 0x22d4
    1d68:	22e0                	.insn	2, 0x22e0
    1d6a:	94087207          	.insn	4, 0x94087207
    1d6e:	3204                	.insn	2, 0x3204
    1d70:	9f24                	.insn	2, 0x9f24
    1d72:	e004                	.insn	2, 0xe004
    1d74:	8822                	.insn	2, 0x8822
    1d76:	00820523          	sb	s0,10(tp) # a <_start-0xffff6>
    1d7a:	2432                	.insn	2, 0x2432
    1d7c:	009f d804 e022      	.insn	6, 0xe022d804009f
    1d82:	0b22                	.insn	2, 0x0b22
    1d84:	007a                	.insn	2, 0x007a
    1d86:	0872                	.insn	2, 0x0872
    1d88:	3206                	.insn	2, 0x3206
    1d8a:	3924                	.insn	2, 0x3924
    1d8c:	2225                	.insn	2, 0x2225
    1d8e:	049f 22e0 22e4      	.insn	6, 0x22e422e0049f
    1d94:	7a0a                	.insn	2, 0x7a0a
    1d96:	8200                	.insn	2, 0x8200
    1d98:	3200                	.insn	2, 0x3200
    1d9a:	3924                	.insn	2, 0x3924
    1d9c:	2225                	.insn	2, 0x2225
    1d9e:	049f 22e4 22e8      	.insn	6, 0x22e822e4049f
    1da4:	7a06                	.insn	2, 0x7a06
    1da6:	7b00                	.insn	2, 0x7b00
    1da8:	2200                	.insn	2, 0x2200
    1daa:	049f 22e8 22f4      	.insn	6, 0x22f422e8049f
    1db0:	5a01                	.insn	2, 0x5a01
    1db2:	0400                	.insn	2, 0x0400
    1db4:	22d4                	.insn	2, 0x22d4
    1db6:	22e0                	.insn	2, 0x22e0
    1db8:	9408720b          	.insn	4, 0x9408720b
    1dbc:	3204                	.insn	2, 0x3204
    1dbe:	1024                	.insn	2, 0x1024
    1dc0:	03fc                	.insn	2, 0x03fc
    1dc2:	9f1a                	.insn	2, 0x9f1a
    1dc4:	e004                	.insn	2, 0xe004
    1dc6:	8822                	.insn	2, 0x8822
    1dc8:	00820923          	sb	s0,18(tp) # 12 <_start-0xfffee>
    1dcc:	2432                	.insn	2, 0x2432
    1dce:	fc10                	.insn	2, 0xfc10
    1dd0:	049f1a03          	lh	s4,73(t5) # 84049049 <_stack_top+0x83f3d089>
    1dd4:	2390                	.insn	2, 0x2390
    1dd6:	2398                	.insn	2, 0x2398
    1dd8:	5a01                	.insn	2, 0x5a01
    1dda:	0400                	.insn	2, 0x0400
    1ddc:	2398                	.insn	2, 0x2398
    1dde:	23a8                	.insn	2, 0x23a8
    1de0:	9f187a03          	.insn	4, 0x9f187a03
	...

Disassembly of section .debug_rnglists:

00000000 <.debug_rnglists>:
   0:	0000016f          	jal	sp,0 <_start-0x100000>
   4:	0005                	.insn	2, 0x0005
   6:	0004                	.insn	2, 0x0004
   8:	0015                	.insn	2, 0x0015
   a:	0000                	.insn	2, 0x0000
   c:	0054                	.insn	2, 0x0054
   e:	0000                	.insn	2, 0x0000
  10:	005e                	.insn	2, 0x005e
  12:	0000                	.insn	2, 0x0000
  14:	0069                	.insn	2, 0x0069
  16:	0000                	.insn	2, 0x0000
  18:	0074                	.insn	2, 0x0074
  1a:	0000                	.insn	2, 0x0000
  1c:	007f 0000 008a 0000 	.insn	10, 0x00950000008a0000007f
  24:	0095 
  26:	0000                	.insn	2, 0x0000
  28:	00a0                	.insn	2, 0x00a0
  2a:	0000                	.insn	2, 0x0000
  2c:	000000ab          	.insn	4, 0x00ab
  30:	00b6                	.insn	2, 0x00b6
  32:	0000                	.insn	2, 0x0000
  34:	00c6                	.insn	2, 0x00c6
  36:	0000                	.insn	2, 0x0000
  38:	00d1                	.insn	2, 0x00d1
  3a:	0000                	.insn	2, 0x0000
  3c:	00dc                	.insn	2, 0x00dc
  3e:	0000                	.insn	2, 0x0000
  40:	000000e7          	jalr	zero # 0 <_start-0x100000>
  44:	00f2                	.insn	2, 0x00f2
  46:	0000                	.insn	2, 0x0000
  48:	00fd                	.insn	2, 0x00fd
  4a:	0000                	.insn	2, 0x0000
  4c:	0108                	.insn	2, 0x0108
  4e:	0000                	.insn	2, 0x0000
  50:	011d                	.insn	2, 0x011d
  52:	0000                	.insn	2, 0x0000
  54:	0132                	.insn	2, 0x0132
  56:	0000                	.insn	2, 0x0000
  58:	00000147          	.insn	4, 0x0147
  5c:	015c                	.insn	2, 0x015c
  5e:	0000                	.insn	2, 0x0000
  60:	7804                	.insn	2, 0x7804
  62:	0188                	.insn	2, 0x0188
  64:	8c04                	.insn	2, 0x8c04
  66:	9401                	.insn	2, 0x9401
  68:	0001                	.insn	2, 0x0001
  6a:	a404                	.insn	2, 0xa404
  6c:	d801                	.insn	2, 0xd801
  6e:	0402                	.insn	2, 0x0402
  70:	04ac                	.insn	2, 0x04ac
  72:	04d0                	.insn	2, 0x04d0
  74:	0400                	.insn	2, 0x0400
  76:	01d0                	.insn	2, 0x01d0
  78:	01e0                	.insn	2, 0x01e0
  7a:	e404                	.insn	2, 0xe404
  7c:	ec01                	.insn	2, 0xec01
  7e:	0001                	.insn	2, 0x0001
  80:	ac04                	.insn	2, 0xac04
  82:	bc04                	.insn	2, 0xbc04
  84:	0404                	.insn	2, 0x0404
  86:	04c0                	.insn	2, 0x04c0
  88:	04c8                	.insn	2, 0x04c8
  8a:	0400                	.insn	2, 0x0400
  8c:	04ec                	.insn	2, 0x04ec
  8e:	04fc                	.insn	2, 0x04fc
  90:	8004                	.insn	2, 0x8004
  92:	8805                	.insn	2, 0x8805
  94:	0005                	.insn	2, 0x0005
  96:	8804                	.insn	2, 0x8804
  98:	04039803          	lh	a6,64(t2)
  9c:	039c                	.insn	2, 0x039c
  9e:	03a4                	.insn	2, 0x03a4
  a0:	0400                	.insn	2, 0x0400
  a2:	03e8                	.insn	2, 0x03e8
  a4:	03f8                	.insn	2, 0x03f8
  a6:	fc04                	.insn	2, 0xfc04
  a8:	00048403          	lb	s0,0(s1)
  ac:	d004                	.insn	2, 0xd004
  ae:	e005                	.insn	2, 0xe005
  b0:	0405                	.insn	2, 0x0405
  b2:	05e4                	.insn	2, 0x05e4
  b4:	05ec                	.insn	2, 0x05ec
  b6:	0400                	.insn	2, 0x0400
  b8:	08b4                	.insn	2, 0x08b4
  ba:	08c4                	.insn	2, 0x08c4
  bc:	c804                	.insn	2, 0xc804
  be:	cc08                	.insn	2, 0xcc08
  c0:	0008                	.insn	2, 0x0008
  c2:	9804                	.insn	2, 0x9804
  c4:	f809                	.insn	2, 0xf809
  c6:	15a40413          	addi	s0,s0,346
  ca:	17cc                	.insn	2, 0x17cc
  cc:	ac04                	.insn	2, 0xac04
  ce:	b018                	.insn	2, 0xb018
  d0:	0018                	.insn	2, 0x0018
  d2:	c804                	.insn	2, 0xc804
  d4:	d816                	.insn	2, 0xd816
  d6:	0416                	.insn	2, 0x0416
  d8:	16dc                	.insn	2, 0x16dc
  da:	16e4                	.insn	2, 0x16e4
  dc:	0400                	.insn	2, 0x0400
  de:	0dfc                	.insn	2, 0x0dfc
  e0:	0ebc                	.insn	2, 0x0ebc
  e2:	a404                	.insn	2, 0xa404
  e4:	ac15                	.insn	2, 0xac15
  e6:	0016                	.insn	2, 0x0016
  e8:	a404                	.insn	2, 0xa404
  ea:	b415                	.insn	2, 0xb415
  ec:	0415                	.insn	2, 0x0415
  ee:	15b8                	.insn	2, 0x15b8
  f0:	15c0                	.insn	2, 0x15c0
  f2:	0400                	.insn	2, 0x0400
  f4:	0ec4                	.insn	2, 0x0ec4
  f6:	13e4                	.insn	2, 0x13e4
  f8:	ac04                	.insn	2, 0xac04
  fa:	b018                	.insn	2, 0xb018
  fc:	0018                	.insn	2, 0x0018
  fe:	f804                	.insn	2, 0xf804
 100:	040ffc0f          	.insn	4, 0x040ffc0f
 104:	1080                	.insn	2, 0x1080
 106:	1084                	.insn	2, 0x1084
 108:	0400                	.insn	2, 0x0400
 10a:	1098                	.insn	2, 0x1098
 10c:	10a8                	.insn	2, 0x10a8
 10e:	ac04                	.insn	2, 0xac04
 110:	b410                	.insn	2, 0xb410
 112:	0010                	.insn	2, 0x0010
 114:	8804                	.insn	2, 0x8804
 116:	8c11                	.insn	2, 0x8c11
 118:	0411                	.insn	2, 0x0411
 11a:	1198                	.insn	2, 0x1198
 11c:	119c                	.insn	2, 0x119c
 11e:	b004                	.insn	2, 0xb004
 120:	b411                	.insn	2, 0xb411
 122:	0411                	.insn	2, 0x0411
 124:	11c8                	.insn	2, 0x11c8
 126:	11cc                	.insn	2, 0x11cc
 128:	0400                	.insn	2, 0x0400
 12a:	1194                	.insn	2, 0x1194
 12c:	1198                	.insn	2, 0x1198
 12e:	ac04                	.insn	2, 0xac04
 130:	b011                	.insn	2, 0xb011
 132:	0411                	.insn	2, 0x0411
 134:	11c4                	.insn	2, 0x11c4
 136:	11c8                	.insn	2, 0x11c8
 138:	dc04                	.insn	2, 0xdc04
 13a:	e411                	.insn	2, 0xe411
 13c:	0011                	.insn	2, 0x0011
 13e:	ac04                	.insn	2, 0xac04
 140:	b012                	.insn	2, 0xb012
 142:	0412                	.insn	2, 0x0412
 144:	12bc                	.insn	2, 0x12bc
 146:	12c0                	.insn	2, 0x12c0
 148:	d404                	.insn	2, 0xd404
 14a:	d812                	.insn	2, 0xd812
 14c:	0412                	.insn	2, 0x0412
 14e:	12ec                	.insn	2, 0x12ec
 150:	12f0                	.insn	2, 0x12f0
 152:	0400                	.insn	2, 0x0400
 154:	12b8                	.insn	2, 0x12b8
 156:	12bc                	.insn	2, 0x12bc
 158:	d004                	.insn	2, 0xd004
 15a:	d412                	.insn	2, 0xd412
 15c:	0412                	.insn	2, 0x0412
 15e:	12e8                	.insn	2, 0x12e8
 160:	12ec                	.insn	2, 0x12ec
 162:	8004                	.insn	2, 0x8004
 164:	00138813          	addi	a6,t2,1
 168:	9404                	.insn	2, 0x9404
 16a:	a414                	.insn	2, 0xa414
 16c:	0414                	.insn	2, 0x0414
 16e:	14a8                	.insn	2, 0x14a8
 170:	14b0                	.insn	2, 0x14b0
 172:	d000                	.insn	2, 0xd000
 174:	0000                	.insn	2, 0x0000
 176:	0500                	.insn	2, 0x0500
 178:	0400                	.insn	2, 0x0400
 17a:	0b00                	.insn	2, 0x0b00
 17c:	0000                	.insn	2, 0x0000
 17e:	2c00                	.insn	2, 0x2c00
 180:	0000                	.insn	2, 0x0000
 182:	3700                	.insn	2, 0x3700
 184:	0000                	.insn	2, 0x0000
 186:	4700                	.insn	2, 0x4700
 188:	0000                	.insn	2, 0x0000
 18a:	5200                	.insn	2, 0x5200
 18c:	0000                	.insn	2, 0x0000
 18e:	5d00                	.insn	2, 0x5d00
 190:	0000                	.insn	2, 0x0000
 192:	6800                	.insn	2, 0x6800
 194:	0000                	.insn	2, 0x0000
 196:	7800                	.insn	2, 0x7800
 198:	0000                	.insn	2, 0x0000
 19a:	8800                	.insn	2, 0x8800
 19c:	0000                	.insn	2, 0x0000
 19e:	9800                	.insn	2, 0x9800
 1a0:	0000                	.insn	2, 0x0000
 1a2:	a800                	.insn	2, 0xa800
 1a4:	0000                	.insn	2, 0x0000
 1a6:	b800                	.insn	2, 0xb800
 1a8:	0000                	.insn	2, 0x0000
 1aa:	0400                	.insn	2, 0x0400
 1ac:	04bc                	.insn	2, 0x04bc
 1ae:	04e0                	.insn	2, 0x04e0
 1b0:	8c04                	.insn	2, 0x8c04
 1b2:	0007f407          	.insn	4, 0x0007f407
 1b6:	9c04                	.insn	2, 0x9c04
 1b8:	b809                	.insn	2, 0xb809
 1ba:	0409                	.insn	2, 0x0409
 1bc:	09bc                	.insn	2, 0x09bc
 1be:	09c4                	.insn	2, 0x09c4
 1c0:	cc04                	.insn	2, 0xcc04
 1c2:	ec09                	.insn	2, 0xec09
 1c4:	0009                	.insn	2, 0x0009
 1c6:	e404                	.insn	2, 0xe404
 1c8:	800a                	.insn	2, 0x800a
 1ca:	0b84040b          	.insn	4, 0x0b84040b
 1ce:	0eac                	.insn	2, 0x0eac
 1d0:	0400                	.insn	2, 0x0400
 1d2:	0b88                	.insn	2, 0x0b88
 1d4:	0b94                	.insn	2, 0x0b94
 1d6:	9804                	.insn	2, 0x9804
 1d8:	000cc40b          	.insn	4, 0x000cc40b
 1dc:	8804                	.insn	2, 0x8804
 1de:	940e                	.insn	2, 0x940e
 1e0:	040e                	.insn	2, 0x040e
 1e2:	0e9c                	.insn	2, 0x0e9c
 1e4:	0eac                	.insn	2, 0x0eac
 1e6:	0400                	.insn	2, 0x0400
 1e8:	0f98                	.insn	2, 0x0f98
 1ea:	0fdc                	.insn	2, 0x0fdc
 1ec:	c404                	.insn	2, 0xc404
 1ee:	d810                	.insn	2, 0xd810
 1f0:	0410                	.insn	2, 0x0410
 1f2:	1188                	.insn	2, 0x1188
 1f4:	11d8                	.insn	2, 0x11d8
 1f6:	0400                	.insn	2, 0x0400
 1f8:	0f98                	.insn	2, 0x0f98
 1fa:	0fdc                	.insn	2, 0x0fdc
 1fc:	c404                	.insn	2, 0xc404
 1fe:	cc10                	.insn	2, 0xcc10
 200:	0410                	.insn	2, 0x0410
 202:	1188                	.insn	2, 0x1188
 204:	11d8                	.insn	2, 0x11d8
 206:	0400                	.insn	2, 0x0400
 208:	1188                	.insn	2, 0x1188
 20a:	11a4                	.insn	2, 0x11a4
 20c:	a804                	.insn	2, 0xa804
 20e:	b011                	.insn	2, 0xb011
 210:	0411                	.insn	2, 0x0411
 212:	11b8                	.insn	2, 0x11b8
 214:	11d8                	.insn	2, 0x11d8
 216:	0400                	.insn	2, 0x0400
 218:	1080                	.insn	2, 0x1080
 21a:	10c4                	.insn	2, 0x10c4
 21c:	d804                	.insn	2, 0xd804
 21e:	e810                	.insn	2, 0xe810
 220:	0410                	.insn	2, 0x0410
 222:	11ec                	.insn	2, 0x11ec
 224:	12bc                	.insn	2, 0x12bc
 226:	0400                	.insn	2, 0x0400
 228:	1080                	.insn	2, 0x1080
 22a:	10c4                	.insn	2, 0x10c4
 22c:	d804                	.insn	2, 0xd804
 22e:	e010                	.insn	2, 0xe010
 230:	0410                	.insn	2, 0x0410
 232:	11ec                	.insn	2, 0x11ec
 234:	12bc                	.insn	2, 0x12bc
 236:	0400                	.insn	2, 0x0400
 238:	11ec                	.insn	2, 0x11ec
 23a:	1288                	.insn	2, 0x1288
 23c:	8c04                	.insn	2, 0x8c04
 23e:	9412                	.insn	2, 0x9412
 240:	0412                	.insn	2, 0x0412
 242:	129c                	.insn	2, 0x129c
 244:	12bc                	.insn	2, 0x12bc
 246:	5300                	.insn	2, 0x5300
 248:	0000                	.insn	2, 0x0000
 24a:	0500                	.insn	2, 0x0500
 24c:	0400                	.insn	2, 0x0400
 24e:	0400                	.insn	2, 0x0400
 250:	0000                	.insn	2, 0x0000
 252:	1000                	.insn	2, 0x1000
 254:	0000                	.insn	2, 0x0000
 256:	2000                	.insn	2, 0x2000
 258:	0000                	.insn	2, 0x0000
 25a:	3000                	.insn	2, 0x3000
 25c:	0000                	.insn	2, 0x0000
 25e:	3b00                	.insn	2, 0x3b00
 260:	0000                	.insn	2, 0x0000
 262:	0400                	.insn	2, 0x0400
 264:	0490                	.insn	2, 0x0490
 266:	04a4                	.insn	2, 0x04a4
 268:	c004                	.insn	2, 0xc004
 26a:	d405                	.insn	2, 0xd405
 26c:	0405                	.insn	2, 0x0405
 26e:	06f0                	.insn	2, 0x06f0
 270:	0784                	.insn	2, 0x0784
 272:	0400                	.insn	2, 0x0400
 274:	04c4                	.insn	2, 0x04c4
 276:	0594                	.insn	2, 0x0594
 278:	f404                	.insn	2, 0xf404
 27a:	c405                	.insn	2, 0xc405
 27c:	0406                	.insn	2, 0x0406
 27e:	07a0                	.insn	2, 0x07a0
 280:	07f4                	.insn	2, 0x07f4
 282:	0400                	.insn	2, 0x0400
 284:	0bd8                	.insn	2, 0x0bd8
 286:	0e90                	.insn	2, 0x0e90
 288:	a404                	.insn	2, 0xa404
 28a:	b80e                	.insn	2, 0xb80e
 28c:	000e                	.insn	2, 0x000e
 28e:	fc04                	.insn	2, 0xfc04
 290:	040c8c0b          	.insn	4, 0x040c8c0b
 294:	0c94                	.insn	2, 0x0c94
 296:	0e88                	.insn	2, 0x0e88
 298:	a404                	.insn	2, 0xa404
 29a:	b80e                	.insn	2, 0xb80e
 29c:	000e                	.insn	2, 0x000e
 29e:	0148                	.insn	2, 0x0148
 2a0:	0000                	.insn	2, 0x0000
 2a2:	0005                	.insn	2, 0x0005
 2a4:	0004                	.insn	2, 0x0004
 2a6:	00000013          	nop
 2aa:	004c                	.insn	2, 0x004c
 2ac:	0000                	.insn	2, 0x0000
 2ae:	00000057          	.insn	4, 0x0057
 2b2:	0062                	.insn	2, 0x0062
 2b4:	0000                	.insn	2, 0x0000
 2b6:	006d                	.insn	2, 0x006d
 2b8:	0000                	.insn	2, 0x0000
 2ba:	007d                	.insn	2, 0x007d
 2bc:	0000                	.insn	2, 0x0000
 2be:	008d                	.insn	2, 0x008d
 2c0:	0000                	.insn	2, 0x0000
 2c2:	009d                	.insn	2, 0x009d
 2c4:	0000                	.insn	2, 0x0000
 2c6:	00ad                	.insn	2, 0x00ad
 2c8:	0000                	.insn	2, 0x0000
 2ca:	00bd                	.insn	2, 0x00bd
 2cc:	0000                	.insn	2, 0x0000
 2ce:	00c8                	.insn	2, 0x00c8
 2d0:	0000                	.insn	2, 0x0000
 2d2:	000000d3          	.insn	4, 0x00d3
 2d6:	00e8                	.insn	2, 0x00e8
 2d8:	0000                	.insn	2, 0x0000
 2da:	000000f3          	.insn	4, 0x00f3
 2de:	00fe                	.insn	2, 0x00fe
 2e0:	0000                	.insn	2, 0x0000
 2e2:	0109                	.insn	2, 0x0109
 2e4:	0000                	.insn	2, 0x0000
 2e6:	0114                	.insn	2, 0x0114
 2e8:	0000                	.insn	2, 0x0000
 2ea:	011f 0000 012a      	.insn	6, 0x012a0000011f
 2f0:	0000                	.insn	2, 0x0000
 2f2:	0135                	.insn	2, 0x0135
 2f4:	0000                	.insn	2, 0x0000
 2f6:	8004                	.insn	2, 0x8004
 2f8:	040b9c0b          	.insn	4, 0x040b9c0b
 2fc:	0ba0                	.insn	2, 0x0ba0
 2fe:	0ba4                	.insn	2, 0x0ba4
 300:	0400                	.insn	2, 0x0400
 302:	0ca0                	.insn	2, 0x0ca0
 304:	0ca4                	.insn	2, 0x0ca4
 306:	d004                	.insn	2, 0xd004
 308:	980c                	.insn	2, 0x980c
 30a:	000e                	.insn	2, 0x000e
 30c:	f004                	.insn	2, 0xf004
 30e:	f40c                	.insn	2, 0xf40c
 310:	040c                	.insn	2, 0x040c
 312:	0cf8                	.insn	2, 0x0cf8
 314:	0d8c                	.insn	2, 0x0d8c
 316:	0400                	.insn	2, 0x0400
 318:	0fc4                	.insn	2, 0x0fc4
 31a:	12dc                	.insn	2, 0x12dc
 31c:	f404                	.insn	2, 0xf404
 31e:	fc12                	.insn	2, 0xfc12
 320:	0412                	.insn	2, 0x0412
 322:	13c4                	.insn	2, 0x13c4
 324:	14c8                	.insn	2, 0x14c8
 326:	0400                	.insn	2, 0x0400
 328:	0fec                	.insn	2, 0x0fec
 32a:	11e8                	.insn	2, 0x11e8
 32c:	f404                	.insn	2, 0xf404
 32e:	fc12                	.insn	2, 0xfc12
 330:	0412                	.insn	2, 0x0412
 332:	13c4                	.insn	2, 0x13c4
 334:	14c8                	.insn	2, 0x14c8
 336:	0400                	.insn	2, 0x0400
 338:	1088                	.insn	2, 0x1088
 33a:	11e8                	.insn	2, 0x11e8
 33c:	f404                	.insn	2, 0xf404
 33e:	fc12                	.insn	2, 0xfc12
 340:	0412                	.insn	2, 0x0412
 342:	13c4                	.insn	2, 0x13c4
 344:	14c8                	.insn	2, 0x14c8
 346:	0400                	.insn	2, 0x0400
 348:	10b8                	.insn	2, 0x10b8
 34a:	11e8                	.insn	2, 0x11e8
 34c:	f404                	.insn	2, 0xf404
 34e:	fc12                	.insn	2, 0xfc12
 350:	0412                	.insn	2, 0x0412
 352:	13d0                	.insn	2, 0x13d0
 354:	14c8                	.insn	2, 0x14c8
 356:	0400                	.insn	2, 0x0400
 358:	10c4                	.insn	2, 0x10c4
 35a:	11e8                	.insn	2, 0x11e8
 35c:	f404                	.insn	2, 0xf404
 35e:	fc12                	.insn	2, 0xfc12
 360:	0412                	.insn	2, 0x0412
 362:	13d0                	.insn	2, 0x13d0
 364:	14c8                	.insn	2, 0x14c8
 366:	0400                	.insn	2, 0x0400
 368:	13ec                	.insn	2, 0x13ec
 36a:	13f4                	.insn	2, 0x13f4
 36c:	fc04                	.insn	2, 0xfc04
 36e:	00148413          	addi	s0,s1,1
 372:	b004                	.insn	2, 0xb004
 374:	cc12                	.insn	2, 0xcc12
 376:	0412                	.insn	2, 0x0412
 378:	12d0                	.insn	2, 0x12d0
 37a:	12d4                	.insn	2, 0x12d4
 37c:	0400                	.insn	2, 0x0400
 37e:	178c                	.insn	2, 0x178c
 380:	179c                	.insn	2, 0x179c
 382:	b004                	.insn	2, 0xb004
 384:	041c9c17          	auipc	s8,0x41c9
 388:	1cb8                	.insn	2, 0x1cb8
 38a:	1cbc                	.insn	2, 0x1cbc
 38c:	cc04                	.insn	2, 0xcc04
 38e:	dc1c                	.insn	2, 0xdc1c
 390:	001c                	.insn	2, 0x001c
 392:	cc04                	.insn	2, 0xcc04
 394:	9018                	.insn	2, 0x9018
 396:	0419                	.insn	2, 0x0419
 398:	19b0                	.insn	2, 0x19b0
 39a:	19cc                	.insn	2, 0x19cc
 39c:	0400                	.insn	2, 0x0400
 39e:	1bd0                	.insn	2, 0x1bd0
 3a0:	1bec                	.insn	2, 0x1bec
 3a2:	f004                	.insn	2, 0xf004
 3a4:	001bf41b          	.insn	4, 0x001bf41b
 3a8:	d004                	.insn	2, 0xd004
 3aa:	e81e                	.insn	2, 0xe81e
 3ac:	24c80423          	sb	a2,584(a6)
 3b0:	24cc                	.insn	2, 0x24cc
 3b2:	0400                	.insn	2, 0x0400
 3b4:	1fbc                	.insn	2, 0x1fbc
 3b6:	2094                	.insn	2, 0x2094
 3b8:	bc04                	.insn	2, 0xbc04
 3ba:	ec20                	.insn	2, 0xec20
 3bc:	0020                	.insn	2, 0x0020
 3be:	bc04                	.insn	2, 0xbc04
 3c0:	ec1f 041f 20bc      	.insn	6, 0x20bc041fec1f
 3c6:	20d0                	.insn	2, 0x20d0
 3c8:	0400                	.insn	2, 0x0400
 3ca:	2094                	.insn	2, 0x2094
 3cc:	209c                	.insn	2, 0x209c
 3ce:	f804                	.insn	2, 0xf804
 3d0:	b820                	.insn	2, 0xb820
 3d2:	0022                	.insn	2, 0x0022
 3d4:	dc04                	.insn	2, 0xdc04
 3d6:	f021                	.insn	2, 0xf021
 3d8:	0421                	.insn	2, 0x0421
 3da:	22a0                	.insn	2, 0x22a0
 3dc:	22a8                	.insn	2, 0x22a8
 3de:	0400                	.insn	2, 0x0400
 3e0:	2398                	.insn	2, 0x2398
 3e2:	23b4                	.insn	2, 0x23b4
 3e4:	b804                	.insn	2, 0xb804
 3e6:	0023bc23          	.insn	4, 0x0023bc23

Disassembly of section .debug_str_offsets:

00000000 <.debug_str_offsets>:
   0:	00d8                	.insn	2, 0x00d8
   2:	0000                	.insn	2, 0x0000
   4:	0005                	.insn	2, 0x0005
   6:	0000                	.insn	2, 0x0000
   8:	0000                	.insn	2, 0x0000
   a:	0000                	.insn	2, 0x0000
   c:	00000027          	.insn	4, 0x0027
  10:	003e                	.insn	2, 0x003e
  12:	0000                	.insn	2, 0x0000
  14:	00a6                	.insn	2, 0x00a6
  16:	0000                	.insn	2, 0x0000
  18:	00000073          	ecall
  1c:	00000087          	.insn	4, 0x0087
  20:	0094                	.insn	2, 0x0094
  22:	0000                	.insn	2, 0x0000
  24:	009d                	.insn	2, 0x009d
  26:	0000                	.insn	2, 0x0000
  28:	000000ab          	.insn	4, 0x00ab
  2c:	000000b3          	add	ra,zero,zero
  30:	00c2                	.insn	2, 0x00c2
  32:	0000                	.insn	2, 0x0000
  34:	000000cb          	.insn	4, 0x00cb
  38:	000005d3          	.insn	4, 0x05d3
  3c:	00d4                	.insn	2, 0x00d4
  3e:	0000                	.insn	2, 0x0000
  40:	031f 0000 01d4      	.insn	6, 0x01d40000031f
  46:	0000                	.insn	2, 0x0000
  48:	000005bb          	.insn	4, 0x05bb
  4c:	00dd                	.insn	2, 0x00dd
  4e:	0000                	.insn	2, 0x0000
  50:	0600                	.insn	2, 0x0600
  52:	0000                	.insn	2, 0x0000
  54:	00e6                	.insn	2, 0x00e6
  56:	0000                	.insn	2, 0x0000
  58:	0090                	.insn	2, 0x0090
  5a:	0000                	.insn	2, 0x0000
  5c:	00f8                	.insn	2, 0x00f8
  5e:	0000                	.insn	2, 0x0000
  60:	0100                	.insn	2, 0x0100
  62:	0000                	.insn	2, 0x0000
  64:	0300                	.insn	2, 0x0300
  66:	0000                	.insn	2, 0x0000
  68:	0000010b          	.insn	4, 0x010b
  6c:	0115                	.insn	2, 0x0115
  6e:	0000                	.insn	2, 0x0000
  70:	0124                	.insn	2, 0x0124
  72:	0000                	.insn	2, 0x0000
  74:	012a                	.insn	2, 0x012a
  76:	0000                	.insn	2, 0x0000
  78:	0000013b          	.insn	4, 0x013b
  7c:	0152                	.insn	2, 0x0152
  7e:	0000                	.insn	2, 0x0000
  80:	0000016b          	.insn	4, 0x016b
  84:	0418                	.insn	2, 0x0418
  86:	0000                	.insn	2, 0x0000
  88:	0184                	.insn	2, 0x0184
  8a:	0000                	.insn	2, 0x0000
  8c:	000005c7          	.insn	4, 0x05c7
  90:	0178                	.insn	2, 0x0178
  92:	0000                	.insn	2, 0x0000
  94:	017a                	.insn	2, 0x017a
  96:	0000                	.insn	2, 0x0000
  98:	0188                	.insn	2, 0x0188
  9a:	0000                	.insn	2, 0x0000
  9c:	018d                	.insn	2, 0x018d
  9e:	0000                	.insn	2, 0x0000
  a0:	0195                	.insn	2, 0x0195
  a2:	0000                	.insn	2, 0x0000
  a4:	019d                	.insn	2, 0x019d
  a6:	0000                	.insn	2, 0x0000
  a8:	01aa                	.insn	2, 0x01aa
  aa:	0000                	.insn	2, 0x0000
  ac:	01bc                	.insn	2, 0x01bc
  ae:	0000                	.insn	2, 0x0000
  b0:	000001cf          	.insn	4, 0x01cf
  b4:	01dc                	.insn	2, 0x01dc
  b6:	0000                	.insn	2, 0x0000
  b8:	01ec                	.insn	2, 0x01ec
  ba:	0000                	.insn	2, 0x0000
  bc:	003c                	.insn	2, 0x003c
  be:	0000                	.insn	2, 0x0000
  c0:	0200                	.insn	2, 0x0200
  c2:	0000                	.insn	2, 0x0000
  c4:	020d                	.insn	2, 0x020d
  c6:	0000                	.insn	2, 0x0000
  c8:	0000045b          	.insn	4, 0x045b
  cc:	0218                	.insn	2, 0x0218
  ce:	0000                	.insn	2, 0x0000
  d0:	021c                	.insn	2, 0x021c
  d2:	0000                	.insn	2, 0x0000
  d4:	0222                	.insn	2, 0x0222
  d6:	0000                	.insn	2, 0x0000
  d8:	0229                	.insn	2, 0x0229
  da:	0000                	.insn	2, 0x0000
  dc:	0104                	.insn	2, 0x0104
  de:	0000                	.insn	2, 0x0000
  e0:	0005                	.insn	2, 0x0005
  e2:	0000                	.insn	2, 0x0000
  e4:	0000                	.insn	2, 0x0000
  e6:	0000                	.insn	2, 0x0000
  e8:	0230                	.insn	2, 0x0230
  ea:	0000                	.insn	2, 0x0000
  ec:	003e                	.insn	2, 0x003e
  ee:	0000                	.insn	2, 0x0000
  f0:	00a6                	.insn	2, 0x00a6
  f2:	0000                	.insn	2, 0x0000
  f4:	00000073          	ecall
  f8:	023d                	.insn	2, 0x023d
  fa:	0000                	.insn	2, 0x0000
  fc:	009d                	.insn	2, 0x009d
  fe:	0000                	.insn	2, 0x0000
 100:	000000ab          	.insn	4, 0x00ab
 104:	0090                	.insn	2, 0x0090
 106:	0000                	.insn	2, 0x0000
 108:	00000087          	.insn	4, 0x0087
 10c:	0094                	.insn	2, 0x0094
 10e:	0000                	.insn	2, 0x0000
 110:	0241                	.insn	2, 0x0241
 112:	0000                	.insn	2, 0x0000
 114:	0248                	.insn	2, 0x0248
 116:	0000                	.insn	2, 0x0000
 118:	0251                	.insn	2, 0x0251
 11a:	0000                	.insn	2, 0x0000
 11c:	00000253          	.insn	4, 0x0253
 120:	00a9                	.insn	2, 0x00a9
 122:	0000                	.insn	2, 0x0000
 124:	00000257          	.insn	4, 0x0257
 128:	000005c7          	.insn	4, 0x05c7
 12c:	000001cf          	.insn	4, 0x01cf
 130:	0259                	.insn	2, 0x0259
 132:	0000                	.insn	2, 0x0000
 134:	031f 0000 0265      	.insn	6, 0x02650000031f
 13a:	0000                	.insn	2, 0x0000
 13c:	0269                	.insn	2, 0x0269
 13e:	0000                	.insn	2, 0x0000
 140:	0274                	.insn	2, 0x0274
 142:	0000                	.insn	2, 0x0000
 144:	0600                	.insn	2, 0x0600
 146:	0000                	.insn	2, 0x0000
 148:	00fc                	.insn	2, 0x00fc
 14a:	0000                	.insn	2, 0x0000
 14c:	027e                	.insn	2, 0x027e
 14e:	0000                	.insn	2, 0x0000
 150:	003c                	.insn	2, 0x003c
 152:	0000                	.insn	2, 0x0000
 154:	00f6                	.insn	2, 0x00f6
 156:	0000                	.insn	2, 0x0000
 158:	0288                	.insn	2, 0x0288
 15a:	0000                	.insn	2, 0x0000
 15c:	0000028f          	.insn	4, 0x028f
 160:	0296                	.insn	2, 0x0296
 162:	0000                	.insn	2, 0x0000
 164:	029d                	.insn	2, 0x029d
 166:	0000                	.insn	2, 0x0000
 168:	02a9                	.insn	2, 0x02a9
 16a:	0000                	.insn	2, 0x0000
 16c:	02b2                	.insn	2, 0x02b2
 16e:	0000                	.insn	2, 0x0000
 170:	02ba                	.insn	2, 0x02ba
 172:	0000                	.insn	2, 0x0000
 174:	0218                	.insn	2, 0x0218
 176:	0000                	.insn	2, 0x0000
 178:	000002c3          	.insn	4, 0x02c3
 17c:	0300                	.insn	2, 0x0300
 17e:	0000                	.insn	2, 0x0000
 180:	045d                	.insn	2, 0x045d
 182:	0000                	.insn	2, 0x0000
 184:	00000267          	jalr	tp,zero # 0 <_start-0x100000>
 188:	000002c7          	.insn	4, 0x02c7
 18c:	02ca                	.insn	2, 0x02ca
 18e:	0000                	.insn	2, 0x0000
 190:	0418                	.insn	2, 0x0418
 192:	0000                	.insn	2, 0x0000
 194:	0294                	.insn	2, 0x0294
 196:	0000                	.insn	2, 0x0000
 198:	02cd                	.insn	2, 0x02cd
 19a:	0000                	.insn	2, 0x0000
 19c:	02d1                	.insn	2, 0x02d1
 19e:	0000                	.insn	2, 0x0000
 1a0:	000002d7          	.insn	4, 0x02d7
 1a4:	02e9                	.insn	2, 0x02e9
 1a6:	0000                	.insn	2, 0x0000
 1a8:	02ed                	.insn	2, 0x02ed
 1aa:	0000                	.insn	2, 0x0000
 1ac:	000002f3          	.insn	4, 0x02f3
 1b0:	02fa                	.insn	2, 0x02fa
 1b2:	0000                	.insn	2, 0x0000
 1b4:	000005d3          	.insn	4, 0x05d3
 1b8:	02fe                	.insn	2, 0x02fe
 1ba:	0000                	.insn	2, 0x0000
 1bc:	0302                	.insn	2, 0x0302
 1be:	0000                	.insn	2, 0x0000
 1c0:	04d2                	.insn	2, 0x04d2
 1c2:	0000                	.insn	2, 0x0000
 1c4:	0312                	.insn	2, 0x0312
 1c6:	0000                	.insn	2, 0x0000
 1c8:	00000317          	auipc	t1,0x0
 1cc:	031c                	.insn	2, 0x031c
 1ce:	0000                	.insn	2, 0x0000
 1d0:	0321                	.insn	2, 0x0321
 1d2:	0000                	.insn	2, 0x0000
 1d4:	032e                	.insn	2, 0x032e
 1d6:	0000                	.insn	2, 0x0000
 1d8:	033a                	.insn	2, 0x033a
 1da:	0000                	.insn	2, 0x0000
 1dc:	04df 0000 0342      	.insn	6, 0x0342000004df
 1e2:	0000                	.insn	2, 0x0000
 1e4:	00ac                	.insn	2, 0x00ac
 1e6:	0000                	.insn	2, 0x0000
 1e8:	0005                	.insn	2, 0x0005
 1ea:	0000                	.insn	2, 0x0000
 1ec:	0000                	.insn	2, 0x0000
 1ee:	0000                	.insn	2, 0x0000
 1f0:	00000347          	.insn	4, 0x0347
 1f4:	003e                	.insn	2, 0x003e
 1f6:	0000                	.insn	2, 0x0000
 1f8:	00a6                	.insn	2, 0x00a6
 1fa:	0000                	.insn	2, 0x0000
 1fc:	00000073          	ecall
 200:	00000087          	.insn	4, 0x0087
 204:	0094                	.insn	2, 0x0094
 206:	0000                	.insn	2, 0x0000
 208:	009d                	.insn	2, 0x009d
 20a:	0000                	.insn	2, 0x0000
 20c:	000000b3          	add	ra,zero,zero
 210:	00c2                	.insn	2, 0x00c2
 212:	0000                	.insn	2, 0x0000
 214:	0100                	.insn	2, 0x0100
 216:	0000                	.insn	2, 0x0000
 218:	0300                	.insn	2, 0x0300
 21a:	0000                	.insn	2, 0x0000
 21c:	01f1                	.insn	2, 0x01f1
 21e:	0000                	.insn	2, 0x0000
 220:	0090                	.insn	2, 0x0090
 222:	0000                	.insn	2, 0x0000
 224:	01f9                	.insn	2, 0x01f9
 226:	0000                	.insn	2, 0x0000
 228:	0418                	.insn	2, 0x0418
 22a:	0000                	.insn	2, 0x0000
 22c:	000000ab          	.insn	4, 0x00ab
 230:	02a9                	.insn	2, 0x02a9
 232:	0000                	.insn	2, 0x0000
 234:	0358                	.insn	2, 0x0358
 236:	0000                	.insn	2, 0x0000
 238:	0184                	.insn	2, 0x0184
 23a:	0000                	.insn	2, 0x0000
 23c:	000005c7          	.insn	4, 0x05c7
 240:	0178                	.insn	2, 0x0178
 242:	0000                	.insn	2, 0x0000
 244:	01d4                	.insn	2, 0x01d4
 246:	0000                	.insn	2, 0x0000
 248:	0361                	.insn	2, 0x0361
 24a:	0000                	.insn	2, 0x0000
 24c:	01bc                	.insn	2, 0x01bc
 24e:	0000                	.insn	2, 0x0000
 250:	0374                	.insn	2, 0x0374
 252:	0000                	.insn	2, 0x0000
 254:	0381                	.insn	2, 0x0381
 256:	0000                	.insn	2, 0x0000
 258:	0391                	.insn	2, 0x0391
 25a:	0000                	.insn	2, 0x0000
 25c:	039f 0000 03b6      	.insn	6, 0x03b60000039f
 262:	0000                	.insn	2, 0x0000
 264:	03ce                	.insn	2, 0x03ce
 266:	0000                	.insn	2, 0x0000
 268:	00f8                	.insn	2, 0x00f8
 26a:	0000                	.insn	2, 0x0000
 26c:	03e0                	.insn	2, 0x03e0
 26e:	0000                	.insn	2, 0x0000
 270:	000003e7          	jalr	t2,zero # 0 <_start-0x100000>
 274:	021c                	.insn	2, 0x021c
 276:	0000                	.insn	2, 0x0000
 278:	03f1                	.insn	2, 0x03f1
 27a:	0000                	.insn	2, 0x0000
 27c:	03f4                	.insn	2, 0x03f4
 27e:	0000                	.insn	2, 0x0000
 280:	03f9                	.insn	2, 0x03f9
 282:	0000                	.insn	2, 0x0000
 284:	0188                	.insn	2, 0x0188
 286:	0000                	.insn	2, 0x0000
 288:	0229                	.insn	2, 0x0229
 28a:	0000                	.insn	2, 0x0000
 28c:	027a                	.insn	2, 0x027a
 28e:	0000                	.insn	2, 0x0000
 290:	00f6                	.insn	2, 0x00f6
 292:	0000                	.insn	2, 0x0000
 294:	0144                	.insn	2, 0x0144
 296:	0000                	.insn	2, 0x0000
 298:	0005                	.insn	2, 0x0005
 29a:	0000                	.insn	2, 0x0000
 29c:	0000                	.insn	2, 0x0000
 29e:	0000                	.insn	2, 0x0000
 2a0:	0401                	.insn	2, 0x0401
 2a2:	0000                	.insn	2, 0x0000
 2a4:	003e                	.insn	2, 0x003e
 2a6:	0000                	.insn	2, 0x0000
 2a8:	00a6                	.insn	2, 0x00a6
 2aa:	0000                	.insn	2, 0x0000
 2ac:	00000073          	ecall
 2b0:	0412                	.insn	2, 0x0412
 2b2:	0000                	.insn	2, 0x0000
 2b4:	009d                	.insn	2, 0x009d
 2b6:	0000                	.insn	2, 0x0000
 2b8:	000000ab          	.insn	4, 0x00ab
 2bc:	041c                	.insn	2, 0x041c
 2be:	0000                	.insn	2, 0x0000
 2c0:	0425                	.insn	2, 0x0425
 2c2:	0000                	.insn	2, 0x0000
 2c4:	0090                	.insn	2, 0x0090
 2c6:	0000                	.insn	2, 0x0000
 2c8:	00000087          	.insn	4, 0x0087
 2cc:	0094                	.insn	2, 0x0094
 2ce:	0000                	.insn	2, 0x0000
 2d0:	0000013b          	.insn	4, 0x013b
 2d4:	00000433          	add	s0,zero,zero
 2d8:	043e                	.insn	2, 0x043e
 2da:	0000                	.insn	2, 0x0000
 2dc:	044e                	.insn	2, 0x044e
 2de:	0000                	.insn	2, 0x0000
 2e0:	045f 0000 0475      	.insn	6, 0x04750000045f
 2e6:	0000                	.insn	2, 0x0000
 2e8:	000000b3          	add	ra,zero,zero
 2ec:	00c2                	.insn	2, 0x00c2
 2ee:	0000                	.insn	2, 0x0000
 2f0:	02a9                	.insn	2, 0x02a9
 2f2:	0000                	.insn	2, 0x0000
 2f4:	0484                	.insn	2, 0x0484
 2f6:	0000                	.insn	2, 0x0000
 2f8:	00000267          	jalr	tp,zero # 0 <_start-0x100000>
 2fc:	0499                	.insn	2, 0x0499
 2fe:	0000                	.insn	2, 0x0000
 300:	0294                	.insn	2, 0x0294
 302:	0000                	.insn	2, 0x0000
 304:	049e                	.insn	2, 0x049e
 306:	0000                	.insn	2, 0x0000
 308:	000004a3          	sb	zero,9(zero) # 9 <_start-0xffff7>
 30c:	003c                	.insn	2, 0x003c
 30e:	0000                	.insn	2, 0x0000
 310:	04ae                	.insn	2, 0x04ae
 312:	0000                	.insn	2, 0x0000
 314:	046d                	.insn	2, 0x046d
 316:	0000                	.insn	2, 0x0000
 318:	04c6                	.insn	2, 0x04c6
 31a:	0000                	.insn	2, 0x0000
 31c:	04ce                	.insn	2, 0x04ce
 31e:	0000                	.insn	2, 0x0000
 320:	04d6                	.insn	2, 0x04d6
 322:	0000                	.insn	2, 0x0000
 324:	000004db          	.insn	4, 0x04db
 328:	04e6                	.insn	2, 0x04e6
 32a:	0000                	.insn	2, 0x0000
 32c:	000004fb          	.insn	4, 0x04fb
 330:	04f5                	.insn	2, 0x04f5
 332:	0000                	.insn	2, 0x0000
 334:	029d                	.insn	2, 0x029d
 336:	0000                	.insn	2, 0x0000
 338:	00000517          	auipc	a0,0x0
 33c:	01bc                	.insn	2, 0x01bc
 33e:	0000                	.insn	2, 0x0000
 340:	0361                	.insn	2, 0x0361
 342:	0000                	.insn	2, 0x0000
 344:	051f 0000 012a      	.insn	6, 0x012a0000051f
 34a:	0000                	.insn	2, 0x0000
 34c:	0539                	.insn	2, 0x0539
 34e:	0000                	.insn	2, 0x0000
 350:	0549                	.insn	2, 0x0549
 352:	0000                	.insn	2, 0x0000
 354:	0152                	.insn	2, 0x0152
 356:	0000                	.insn	2, 0x0000
 358:	0000045b          	.insn	4, 0x045b
 35c:	0300                	.insn	2, 0x0300
 35e:	0000                	.insn	2, 0x0000
 360:	01f4                	.insn	2, 0x01f4
 362:	0000                	.insn	2, 0x0000
 364:	055e                	.insn	2, 0x055e
 366:	0000                	.insn	2, 0x0000
 368:	0000056f          	jal	a0,368 <_start-0xffc98>
 36c:	0418                	.insn	2, 0x0418
 36e:	0000                	.insn	2, 0x0000
 370:	0578                	.insn	2, 0x0578
 372:	0000                	.insn	2, 0x0000
 374:	058e                	.insn	2, 0x058e
 376:	0000                	.insn	2, 0x0000
 378:	0598                	.insn	2, 0x0598
 37a:	0000                	.insn	2, 0x0000
 37c:	059f 0000 05df      	.insn	6, 0x05df0000059f
 382:	0000                	.insn	2, 0x0000
 384:	000005c7          	.insn	4, 0x05c7
 388:	0178                	.insn	2, 0x0178
 38a:	0000                	.insn	2, 0x0000
 38c:	05a4                	.insn	2, 0x05a4
 38e:	0000                	.insn	2, 0x0000
 390:	05b0                	.insn	2, 0x05b0
 392:	0000                	.insn	2, 0x0000
 394:	0600                	.insn	2, 0x0600
 396:	0000                	.insn	2, 0x0000
 398:	05b8                	.insn	2, 0x05b8
 39a:	0000                	.insn	2, 0x0000
 39c:	03f2                	.insn	2, 0x03f2
 39e:	0000                	.insn	2, 0x0000
 3a0:	037f 0000 05be 0000 	.insn	10, 0x05c3000005be0000037f
 3a8:	05c3 
 3aa:	0000                	.insn	2, 0x0000
 3ac:	05c9                	.insn	2, 0x05c9
 3ae:	0000                	.insn	2, 0x0000
 3b0:	000005cf          	.insn	4, 0x05cf
 3b4:	05d8                	.insn	2, 0x05d8
 3b6:	0000                	.insn	2, 0x0000
 3b8:	0218                	.insn	2, 0x0218
 3ba:	0000                	.insn	2, 0x0000
 3bc:	05e4                	.insn	2, 0x05e4
 3be:	0000                	.insn	2, 0x0000
 3c0:	000005eb          	.insn	4, 0x05eb
 3c4:	05f5                	.insn	2, 0x05f5
 3c6:	0000                	.insn	2, 0x0000
 3c8:	05fc                	.insn	2, 0x05fc
 3ca:	0000                	.insn	2, 0x0000
 3cc:	0602                	.insn	2, 0x0602
 3ce:	0000                	.insn	2, 0x0000
 3d0:	060c                	.insn	2, 0x060c
 3d2:	0000                	.insn	2, 0x0000
 3d4:	0611                	.insn	2, 0x0611
 3d6:	0000                	.insn	2, 0x0000
 3d8:	05bc                	.insn	2, 0x05bc
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
  2a:	6f6f622f          	.insn	4, 0x6f6f622f
  2e:	6c74                	.insn	2, 0x6c74
  30:	6564616f          	jal	sp,46686 <_start-0xb997a>
  34:	5f72                	.insn	2, 0x5f72
  36:	6166                	.insn	2, 0x6166
  38:	3374                	.insn	2, 0x3374
  3a:	2e32                	.insn	2, 0x2e32
  3c:	682f0063          	beq	t5,sp,6bc <_start-0xff944>
  40:	2f656d6f          	jal	s10,56336 <_start-0xa9cca>
  44:	6168                	.insn	2, 0x6168
  46:	7572                	.insn	2, 0x7572
  48:	6968                	.insn	2, 0x6968
  4a:	502f6f6b          	.insn	4, 0x502f6f6b
  4e:	6f72                	.insn	2, 0x6f72
  50:	6d617267          	.insn	4, 0x6d617267
  54:	4353502f          	.insn	4, 0x4353502f
  58:	525f 3356 4932      	.insn	6, 0x49323356525f
  5e:	4353502f          	.insn	4, 0x4353502f
  62:	4f2d                	.insn	2, 0x4f2d
  64:	454e                	.insn	2, 0x454e
  66:	666f732f          	.insn	4, 0x666f732f
  6a:	7774                	.insn	2, 0x7774
  6c:	7261                	.insn	2, 0x7261
  6e:	2f65                	.insn	2, 0x2f65
  70:	5f00736f          	jal	t1,7660 <_start-0xf89a0>
  74:	415f 5252 5941      	.insn	6, 0x59415252415f
  7a:	535f 5a49 5f45      	.insn	6, 0x5f455a49535f
  80:	5954                	.insn	2, 0x5954
  82:	4550                	.insn	2, 0x4550
  84:	5f5f 7500 736e      	.insn	6, 0x736e75005f5f
  8a:	6769                	.insn	2, 0x6769
  8c:	656e                	.insn	2, 0x656e
  8e:	2064                	.insn	2, 0x2064
  90:	6e69                	.insn	2, 0x6e69
  92:	0074                	.insn	2, 0x0074
  94:	6975                	.insn	2, 0x6975
  96:	746e                	.insn	2, 0x746e
  98:	745f3233          	.insn	4, 0x745f3233
  9c:	7500                	.insn	2, 0x7500
  9e:	736e                	.insn	2, 0x736e
  a0:	6769                	.insn	2, 0x6769
  a2:	656e                	.insn	2, 0x656e
  a4:	2064                	.insn	2, 0x2064
  a6:	72616863          	bltu	sp,t1,7d6 <_start-0xff82a>
  aa:	7500                	.insn	2, 0x7500
  ac:	6e69                	.insn	2, 0x6e69
  ae:	3874                	.insn	2, 0x3874
  b0:	745f 7500 736e      	.insn	6, 0x736e7500745f
  b6:	6769                	.insn	2, 0x6769
  b8:	656e                	.insn	2, 0x656e
  ba:	2064                	.insn	2, 0x2064
  bc:	726f6873          	csrrsi	a6,mhpmevent6h,30
  c0:	0074                	.insn	2, 0x0074
  c2:	6975                	.insn	2, 0x6975
  c4:	746e                	.insn	2, 0x746e
  c6:	3631                	.insn	2, 0x3631
  c8:	745f 6d00 696d      	.insn	6, 0x696d6d00745f
  ce:	33725f6f          	jal	t5,25c04 <_start-0xda3fc>
  d2:	0032                	.insn	2, 0x0032
  d4:	6d6d                	.insn	2, 0x6d6d
  d6:	6f69                	.insn	2, 0x6f69
  d8:	775f 3233 6200      	.insn	6, 0x62003233775f
  de:	5f6c                	.insn	2, 0x5f6c
  e0:	7270                	.insn	2, 0x7270
  e2:	6e69                	.insn	2, 0x6e69
  e4:	0074                	.insn	2, 0x0074
  e6:	695f6473          	csrrsi	s0,0x695,30
  ea:	696e                	.insn	2, 0x696e
  ec:	5f74                	.insn	2, 0x5f74
  ee:	6669                	.insn	2, 0x6669
  f0:	6e5f 6565 6564      	.insn	6, 0x656465656e5f
  f6:	0064                	.insn	2, 0x0064
  f8:	6974                	.insn	2, 0x6974
  fa:	656d                	.insn	2, 0x656d
  fc:	0074756f          	jal	a0,47902 <_start-0xb86fe>
 100:	6974                	.insn	2, 0x6974
 102:	796e                	.insn	2, 0x796e
 104:	645f 6c65 7961      	.insn	6, 0x79616c65645f
 10a:	6300                	.insn	2, 0x6300
 10c:	7570                	.insn	2, 0x7570
 10e:	725f 6c65 7861      	.insn	6, 0x78616c65725f
 114:	6a00                	.insn	2, 0x6a00
 116:	6d75                	.insn	2, 0x6d75
 118:	5f70                	.insn	2, 0x5f70
 11a:	6f74                	.insn	2, 0x6f74
 11c:	6b5f 7265 656e      	.insn	6, 0x656e72656b5f
 122:	006c                	.insn	2, 0x006c
 124:	6e65                	.insn	2, 0x6e65
 126:	7274                	.insn	2, 0x7274
 128:	0079                	.insn	2, 0x0079
 12a:	6f62                	.insn	2, 0x6f62
 12c:	665f746f          	jal	s0,f7f90 <_start-0x8070>
 130:	7461                	.insn	2, 0x7461
 132:	6d5f3233          	.insn	4, 0x6d5f3233
 136:	746e756f          	jal	a0,e787c <_start-0x18784>
 13a:	6200                	.insn	2, 0x6200
 13c:	5f746f6f          	jal	t5,46f32 <_start-0xb90ce>
 140:	725f6473          	csrrsi	s0,mhpmevent5h,30
 144:	6165                	.insn	2, 0x6165
 146:	5f64                	.insn	2, 0x5f64
 148:	74636573          	csrrsi	a0,0x746,6
 14c:	665f726f          	jal	tp,f7fb0 <_start-0x8050>
 150:	006e                	.insn	2, 0x006e
 152:	6f62                	.insn	2, 0x6f62
 154:	665f746f          	jal	s0,f7fb8 <_start-0x8048>
 158:	7461                	.insn	2, 0x7461
 15a:	6c5f3233          	.insn	4, 0x6c5f3233
 15e:	5f64616f          	jal	sp,46754 <_start-0xb98ac>
 162:	656d                	.insn	2, 0x656d
 164:	5f6d                	.insn	2, 0x5f6d
 166:	6966                	.insn	2, 0x6966
 168:	656c                	.insn	2, 0x656c
 16a:	7300                	.insn	2, 0x7300
 16c:	5f64                	.insn	2, 0x5f64
 16e:	31637263          	bgeu	t1,s6,472 <_start-0xffb8e>
 172:	5f36                	.insn	2, 0x5f36
 174:	3135                	.insn	2, 0x3135
 176:	0032                	.insn	2, 0x0032
 178:	006a                	.insn	2, 0x006a
 17a:	675f6473          	csrrsi	s0,0x675,30
 17e:	7465                	.insn	2, 0x7465
 180:	685f 5f77 7263      	.insn	6, 0x72635f77685f
 186:	74630063          	beq	t1,t1,8c6 <_start-0xff73a>
 18a:	6c72                	.insn	2, 0x6c72
 18c:	6300                	.insn	2, 0x6300
 18e:	6372                	.insn	2, 0x6372
 190:	5f31                	.insn	2, 0x5f31
 192:	7768                	.insn	2, 0x7768
 194:	6300                	.insn	2, 0x6300
 196:	6372                	.insn	2, 0x6372
 198:	5f32                	.insn	2, 0x5f32
 19a:	7768                	.insn	2, 0x7768
 19c:	6200                	.insn	2, 0x6200
 19e:	5f6c                	.insn	2, 0x5f6c
 1a0:	7270                	.insn	2, 0x7270
 1a2:	6e69                	.insn	2, 0x6e69
 1a4:	5f74                	.insn	2, 0x5f74
 1a6:	6568                	.insn	2, 0x6568
 1a8:	0078                	.insn	2, 0x0078
 1aa:	5744                	.insn	2, 0x5744
 1ac:	415f 4554 755f      	.insn	6, 0x755f4554415f
 1b2:	736e                	.insn	2, 0x736e
 1b4:	6769                	.insn	2, 0x6769
 1b6:	656e                	.insn	2, 0x656e
 1b8:	5f64                	.insn	2, 0x5f64
 1ba:	0038                	.insn	2, 0x0038
 1bc:	5744                	.insn	2, 0x5744
 1be:	415f 4554 755f      	.insn	6, 0x755f4554415f
 1c4:	736e                	.insn	2, 0x736e
 1c6:	6769                	.insn	2, 0x6769
 1c8:	656e                	.insn	2, 0x656e
 1ca:	5f64                	.insn	2, 0x5f64
 1cc:	75003233          	.insn	4, 0x75003233
 1d0:	7261                	.insn	2, 0x7261
 1d2:	5f74                	.insn	2, 0x5f74
 1d4:	7570                	.insn	2, 0x7570
 1d6:	6374                	.insn	2, 0x6374
 1d8:	6168                	.insn	2, 0x6168
 1da:	0072                	.insn	2, 0x0072
 1dc:	6f62                	.insn	2, 0x6f62
 1de:	6f6c746f          	jal	s0,c78d4 <_start-0x3872c>
 1e2:	6461                	.insn	2, 0x6461
 1e4:	7265                	.insn	2, 0x7265
 1e6:	6d5f 6961 006e      	.insn	6, 0x006e69616d5f
 1ec:	6f62                	.insn	2, 0x6f62
 1ee:	735f746f          	jal	s0,f8122 <_start-0x7ede>
 1f2:	5f64                	.insn	2, 0x5f64
 1f4:	6572                	.insn	2, 0x6572
 1f6:	6461                	.insn	2, 0x6461
 1f8:	735f 6365 6f74      	.insn	6, 0x6f746365735f
 1fe:	0072                	.insn	2, 0x0072
 200:	6e72656b          	.insn	4, 0x6e72656b
 204:	6c65                	.insn	2, 0x6c65
 206:	775f 726f 7364      	.insn	6, 0x7364726f775f
 20c:	7500                	.insn	2, 0x7500
 20e:	5f726573          	csrrsi	a0,0x5f7,4
 212:	64726f77          	.insn	4, 0x64726f77
 216:	73640073          	.insn	4, 0x73640073
 21a:	0074                	.insn	2, 0x0074
 21c:	6572                	.insn	2, 0x6572
 21e:	7274                	.insn	2, 0x7274
 220:	0079                	.insn	2, 0x0079
 222:	5f637263          	bgeu	t1,s6,806 <_start-0xff7fa>
 226:	63007773          	csrrci	a4,0x630,0
 22a:	6372                	.insn	2, 0x6372
 22c:	685f 0077 7273      	.insn	6, 0x72730077685f
 232:	6f632f63          	.insn	4, 0x6f632f63
 236:	6d6d                	.insn	2, 0x6d6d
 238:	632e6e6f          	jal	t3,e686a <_start-0x19796>
 23c:	4800                	.insn	2, 0x4800
 23e:	5845                	.insn	2, 0x5845
 240:	7300                	.insn	2, 0x7300
 242:	7a69                	.insn	2, 0x7a69
 244:	5f65                	.insn	2, 0x5f65
 246:	0074                	.insn	2, 0x0074
 248:	6964                	.insn	2, 0x6964
 24a:	6d76                	.insn	2, 0x6d76
 24c:	3031646f          	jal	s0,16d4e <_start-0xe92b2>
 250:	7500                	.insn	2, 0x7500
 252:	7200                	.insn	2, 0x7200
 254:	6d65                	.insn	2, 0x6d65
 256:	7100                	.insn	2, 0x7100
 258:	7000                	.insn	2, 0x7000
 25a:	6972                	.insn	2, 0x6972
 25c:	746e                	.insn	2, 0x746e
 25e:	685f 7865 3233      	.insn	6, 0x32337865685f
 264:	6e00                	.insn	2, 0x6e00
 266:	6269                	.insn	2, 0x6269
 268:	7000                	.insn	2, 0x7000
 26a:	6972                	.insn	2, 0x6972
 26c:	746e                	.insn	2, 0x746e
 26e:	685f 7865 0038      	.insn	6, 0x00387865685f
 274:	6170                	.insn	2, 0x6170
 276:	7372                	.insn	2, 0x7372
 278:	5f65                	.insn	2, 0x5f65
 27a:	6568                	.insn	2, 0x6568
 27c:	0078                	.insn	2, 0x0078
 27e:	6975                	.insn	2, 0x6975
 280:	746e                	.insn	2, 0x746e
 282:	7470                	.insn	2, 0x7470
 284:	5f72                	.insn	2, 0x5f72
 286:	0074                	.insn	2, 0x0074
 288:	656d                	.insn	2, 0x656d
 28a:	636d                	.insn	2, 0x636d
 28c:	7970                	.insn	2, 0x7970
 28e:	6d00                	.insn	2, 0x6d00
 290:	6d65                	.insn	2, 0x6d65
 292:	00706d63          	bltu	zero,t2,2ac <_start-0xffd54>
 296:	656d                	.insn	2, 0x656d
 298:	736d                	.insn	2, 0x736d
 29a:	7465                	.insn	2, 0x7465
 29c:	7300                	.insn	2, 0x7300
 29e:	705f 6972 746e      	.insn	6, 0x746e6972705f
 2a4:	695f 746e 7300      	.insn	6, 0x7300746e695f
 2aa:	705f 6972 746e      	.insn	6, 0x746e6972705f
 2b0:	0066                	.insn	2, 0x0066
 2b2:	6568                	.insn	2, 0x6568
 2b4:	6478                	.insn	2, 0x6478
 2b6:	6d75                	.insn	2, 0x6d75
 2b8:	0070                	.insn	2, 0x0070
 2ba:	5f646d63          	bltu	s0,s6,8b4 <_start-0xff74c>
 2be:	7564                	.insn	2, 0x7564
 2c0:	706d                	.insn	2, 0x706d
 2c2:	7300                	.insn	2, 0x7300
 2c4:	6372                	.insn	2, 0x6372
 2c6:	7000                	.insn	2, 0x7000
 2c8:	0031                	.insn	2, 0x0031
 2ca:	3270                	.insn	2, 0x3270
 2cc:	6900                	.insn	2, 0x6900
 2ce:	7864                	.insn	2, 0x7864
 2d0:	7600                	.insn	2, 0x7600
 2d2:	7261                	.insn	2, 0x7261
 2d4:	5f007367          	.insn	4, 0x5f007367
 2d8:	625f 6975 746c      	.insn	6, 0x746c6975625f
 2de:	6e69                	.insn	2, 0x6e69
 2e0:	765f 5f61 696c      	.insn	6, 0x696c5f61765f
 2e6:	66007473          	csrrci	s0,0x660,0
 2ea:	746d                	.insn	2, 0x746d
 2ec:	7600                	.insn	2, 0x7600
 2ee:	6c61                	.insn	2, 0x6c61
 2f0:	6575                	.insn	2, 0x6575
 2f2:	6e00                	.insn	2, 0x6e00
 2f4:	6269                	.insn	2, 0x6269
 2f6:	6c62                	.insn	2, 0x6c62
 2f8:	0065                	.insn	2, 0x0065
 2fa:	6e65                	.insn	2, 0x6e65
 2fc:	0064                	.insn	2, 0x0064
 2fe:	656c                	.insn	2, 0x656c
 300:	006e                	.insn	2, 0x006e
 302:	6162                	.insn	2, 0x6162
 304:	615f6573          	csrrsi	a0,htimedeltah,30
 308:	6464                	.insn	2, 0x6464
 30a:	5f72                	.insn	2, 0x5f72
 30c:	616c                	.insn	2, 0x616c
 30e:	6562                	.insn	2, 0x6562
 310:	006c                	.insn	2, 0x006c
 312:	696c                	.insn	2, 0x696c
 314:	656e                	.insn	2, 0x656e
 316:	6100                	.insn	2, 0x6100
 318:	6772                	.insn	2, 0x6772
 31a:	72610063          	beq	sp,t1,a3a <_start-0xff5c6>
 31e:	44007667          	.insn	4, 0x44007667
 322:	4645                	.insn	2, 0x4645
 324:	5541                	.insn	2, 0x5541
 326:	544c                	.insn	2, 0x544c
 328:	425f 5341 0045      	.insn	6, 0x00455341425f
 32e:	4544                	.insn	2, 0x4544
 330:	4146                	.insn	2, 0x4146
 332:	4c55                	.insn	2, 0x4c55
 334:	5f54                	.insn	2, 0x5f54
 336:	454c                	.insn	2, 0x454c
 338:	004e                	.insn	2, 0x004e
 33a:	414d                	.insn	2, 0x414d
 33c:	5f58                	.insn	2, 0x5f58
 33e:	454c                	.insn	2, 0x454c
 340:	004e                	.insn	2, 0x004e
 342:	686c                	.insn	2, 0x686c
 344:	7865                	.insn	2, 0x7865
 346:	7300                	.insn	2, 0x7300
 348:	6372                	.insn	2, 0x6372
 34a:	6364732f          	.insn	4, 0x6364732f
 34e:	7261                	.insn	2, 0x7261
 350:	5f64                	.insn	2, 0x5f64
 352:	7061                	.insn	2, 0x7061
 354:	2e69                	.insn	2, 0x2e69
 356:	64730063          	beq	t1,t2,996 <_start-0xff66a>
 35a:	635f 6372 3631      	.insn	6, 0x36316372635f
 360:	4400                	.insn	2, 0x4400
 362:	54415f57          	.insn	4, 0x54415f57
 366:	5f45                	.insn	2, 0x5f45
 368:	6e75                	.insn	2, 0x6e75
 36a:	6e676973          	csrrsi	s2,0x6e6,14
 36e:	6465                	.insn	2, 0x6465
 370:	315f 0036 6473      	.insn	6, 0x64730036315f
 376:	725f 6165 5f64      	.insn	6, 0x5f646165725f
 37c:	65636e6f          	jal	t3,369d2 <_start-0xc962e>
 380:	7300                	.insn	2, 0x7300
 382:	5f64                	.insn	2, 0x5f64
 384:	74697277          	.insn	4, 0x74697277
 388:	5f65                	.insn	2, 0x5f65
 38a:	74636573          	csrrsi	a0,0x746,6
 38e:	7300726f          	jal	tp,7abe <_start-0xf8542>
 392:	5f64                	.insn	2, 0x5f64
 394:	74697277          	.insn	4, 0x74697277
 398:	5f65                	.insn	2, 0x5f65
 39a:	65636e6f          	jal	t3,369f0 <_start-0xc9610>
 39e:	7300                	.insn	2, 0x7300
 3a0:	635f 6c61 5f6c      	.insn	6, 0x5f6c6c61635f
 3a6:	61636473          	csrrsi	s0,0x616,6
 3aa:	6472                	.insn	2, 0x6472
 3ac:	725f 6165 5f64      	.insn	6, 0x5f646165725f
 3b2:	7061                	.insn	2, 0x7061
 3b4:	0069                	.insn	2, 0x0069
 3b6:	61635f73          	csrrwi	t5,0x616,6
 3ba:	6c6c                	.insn	2, 0x6c6c
 3bc:	735f 6364 7261      	.insn	6, 0x72616364735f
 3c2:	5f64                	.insn	2, 0x5f64
 3c4:	74697277          	.insn	4, 0x74697277
 3c8:	5f65                	.insn	2, 0x5f65
 3ca:	7061                	.insn	2, 0x7061
 3cc:	0069                	.insn	2, 0x0069
 3ce:	735f6473          	csrrsi	s0,mhpmevent21h,30
 3d2:	6365                	.insn	2, 0x6365
 3d4:	6f74                	.insn	2, 0x6f74
 3d6:	5f72                	.insn	2, 0x5f72
 3d8:	6461                	.insn	2, 0x6461
 3da:	7264                	.insn	2, 0x7264
 3dc:	7365                	.insn	2, 0x7365
 3de:	65760073          	.insn	4, 0x65760073
 3e2:	6972                	.insn	2, 0x6972
 3e4:	7966                	.insn	2, 0x7966
 3e6:	7200                	.insn	2, 0x7200
 3e8:	7465                	.insn	2, 0x7465
 3ea:	7972                	.insn	2, 0x7972
 3ec:	6d5f 7861 6f00      	.insn	6, 0x6f0078616d5f
 3f2:	6f62006b          	.insn	4, 0x6f62006b
 3f6:	73006c6f          	jal	s8,6b26 <_start-0xf94da>
 3fa:	6375                	.insn	2, 0x6375
 3fc:	73736563          	bltu	t1,s7,b26 <_start-0xff4da>
 400:	7300                	.insn	2, 0x7300
 402:	6372                	.insn	2, 0x6372
 404:	6f6f622f          	.insn	4, 0x6f6f622f
 408:	5f74                	.insn	2, 0x5f74
 40a:	6166                	.insn	2, 0x6166
 40c:	3374                	.insn	2, 0x3374
 40e:	2e32                	.insn	2, 0x2e32
 410:	61660063          	beq	a2,s6,a10 <_start-0xff5f0>
 414:	3374                	.insn	2, 0x3374
 416:	5f32                	.insn	2, 0x5f32
 418:	7562                	.insn	2, 0x7562
 41a:	0066                	.insn	2, 0x0066
 41c:	6966                	.insn	2, 0x6966
 41e:	656c                	.insn	2, 0x656c
 420:	625f 6675 6700      	.insn	6, 0x67006675625f
 426:	725f 6165 5f64      	.insn	6, 0x5f646165725f
 42c:	74636573          	csrrsi	a0,0x746,6
 430:	6700726f          	jal	tp,7aa0 <_start-0xf8560>
 434:	705f 7261 5f74      	.insn	6, 0x5f747261705f
 43a:	626c                	.insn	2, 0x626c
 43c:	0061                	.insn	2, 0x0061
 43e:	61665f67          	.insn	4, 0x61665f67
 442:	5f74                	.insn	2, 0x5f74
 444:	6562                	.insn	2, 0x6562
 446:	5f6e6967          	.insn	4, 0x5f6e6967
 44a:	626c                	.insn	2, 0x626c
 44c:	0061                	.insn	2, 0x0061
 44e:	61645f67          	.insn	4, 0x61645f67
 452:	6174                	.insn	2, 0x6174
 454:	625f 6765 6e69      	.insn	6, 0x6e696765625f
 45a:	6c5f 6162 6700      	.insn	6, 0x670061626c5f
 460:	735f 6365 6f74      	.insn	6, 0x6f746365735f
 466:	7372                	.insn	2, 0x7372
 468:	705f 7265 635f      	.insn	6, 0x635f7265705f
 46e:	756c                	.insn	2, 0x756c
 470:	72657473          	csrrci	s0,mhpmevent6h,10
 474:	6700                	.insn	2, 0x6700
 476:	725f 6f6f 5f74      	.insn	6, 0x5f746f6f725f
 47c:	73756c63          	bltu	a0,s7,bb4 <_start-0xff44c>
 480:	6574                	.insn	2, 0x6574
 482:	0072                	.insn	2, 0x0072
 484:	7369                	.insn	2, 0x7369
 486:	665f 7461 3233      	.insn	6, 0x32337461665f
 48c:	625f 6f6f 5f74      	.insn	6, 0x5f746f6f625f
 492:	74636573          	csrrsi	a0,0x746,6
 496:	7200726f          	jal	tp,7bb6 <_start-0xf844a>
 49a:	3164                	.insn	2, 0x3164
 49c:	0036                	.insn	2, 0x0036
 49e:	6472                	.insn	2, 0x6472
 4a0:	75003233          	.insn	4, 0x75003233
 4a4:	7070                	.insn	2, 0x7070
 4a6:	7265                	.insn	2, 0x7265
 4a8:	635f 6168 0072      	.insn	6, 0x00726168635f
 4ae:	6f62                	.insn	2, 0x6f62
 4b0:	665f746f          	jal	s0,f8314 <_start-0x7cec>
 4b4:	7461                	.insn	2, 0x7461
 4b6:	6e5f3233          	.insn	4, 0x6e5f3233
 4ba:	7865                	.insn	2, 0x7865
 4bc:	5f74                	.insn	2, 0x5f74
 4be:	73756c63          	bltu	a0,s7,bf6 <_start-0xff40a>
 4c2:	6574                	.insn	2, 0x6574
 4c4:	0072                	.insn	2, 0x0072
 4c6:	6166                	.insn	2, 0x6166
 4c8:	5f74                	.insn	2, 0x5f74
 4ca:	626c                	.insn	2, 0x626c
 4cc:	0061                	.insn	2, 0x0061
 4ce:	6e65                	.insn	2, 0x6e65
 4d0:	5f74                	.insn	2, 0x5f74
 4d2:	0066666f          	jal	a2,664d8 <_start-0x99b28>
 4d6:	656e                	.insn	2, 0x656e
 4d8:	7478                	.insn	2, 0x7478
 4da:	6600                	.insn	2, 0x6600
 4dc:	7461                	.insn	2, 0x7461
 4de:	6f5f 6666 6573      	.insn	6, 0x657366666f5f
 4e4:	0074                	.insn	2, 0x0074
 4e6:	6f62                	.insn	2, 0x6f62
 4e8:	665f746f          	jal	s0,f834c <_start-0x7cb4>
 4ec:	7461                	.insn	2, 0x7461
 4ee:	735f3233          	.insn	4, 0x735f3233
 4f2:	6370                	.insn	2, 0x6370
 4f4:	735f 6968 7466      	.insn	6, 0x74666968735f
 4fa:	6200                	.insn	2, 0x6200
 4fc:	5f746f6f          	jal	t5,472f2 <_start-0xb8d0e>
 500:	6166                	.insn	2, 0x6166
 502:	3374                	.insn	2, 0x3374
 504:	5f32                	.insn	2, 0x5f32
 506:	636c6163          	bltu	s8,s6,b28 <_start-0xff4d8>
 50a:	6c5f 6162 6e5f      	.insn	6, 0x6e5f61626c5f
 510:	6f6c5f6f          	jal	t5,c5c06 <_start-0x3a3fa>
 514:	6800706f          	j	7b94 <_start-0xf846c>
 518:	7865                	.insn	2, 0x7865
 51a:	765f 6c61 6200      	.insn	6, 0x62006c61765f
 520:	5f746f6f          	jal	t5,47316 <_start-0xb8cea>
 524:	6166                	.insn	2, 0x6166
 526:	3374                	.insn	2, 0x3374
 528:	5f32                	.insn	2, 0x5f32
 52a:	73756c63          	bltu	a0,s7,c62 <_start-0xff39e>
 52e:	6574                	.insn	2, 0x6574
 530:	5f72                	.insn	2, 0x5f72
 532:	6f74                	.insn	2, 0x6f74
 534:	6c5f 6162 6200      	.insn	6, 0x620061626c5f
 53a:	5f746f6f          	jal	t5,47330 <_start-0xb8cd0>
 53e:	6166                	.insn	2, 0x6166
 540:	3374                	.insn	2, 0x3374
 542:	5f32                	.insn	2, 0x5f32
 544:	6966                	.insn	2, 0x6966
 546:	646e                	.insn	2, 0x646e
 548:	6200                	.insn	2, 0x6200
 54a:	5f746f6f          	jal	t5,47340 <_start-0xb8cc0>
 54e:	6166                	.insn	2, 0x6166
 550:	3374                	.insn	2, 0x3374
 552:	5f32                	.insn	2, 0x5f32
 554:	6f6c                	.insn	2, 0x6f6c
 556:	6461                	.insn	2, 0x6461
 558:	665f 6c69 0065      	.insn	6, 0x00656c69665f
 55e:	7962                	.insn	2, 0x7962
 560:	6574                	.insn	2, 0x6574
 562:	65705f73          	csrrwi	t5,hviprio2h,0
 566:	5f72                	.insn	2, 0x5f72
 568:	74636573          	csrrsi	a0,0x746,6
 56c:	6600726f          	jal	tp,7bcc <_start-0xf8434>
 570:	7461                	.insn	2, 0x7461
 572:	735f 7a69 0065      	.insn	6, 0x00657a69735f
 578:	6572                	.insn	2, 0x6572
 57a:	76726573          	csrrsi	a0,0x767,4
 57e:	6465                	.insn	2, 0x6465
 580:	735f 6365 6f74      	.insn	6, 0x6f746365735f
 586:	5f72                	.insn	2, 0x5f72
 588:	6e756f63          	bltu	a0,t2,c86 <_start-0xff37a>
 58c:	0074                	.insn	2, 0x0074
 58e:	6166                	.insn	2, 0x6166
 590:	5f74                	.insn	2, 0x5f74
 592:	6e756f63          	bltu	a0,t2,c90 <_start-0xff370>
 596:	0074                	.insn	2, 0x0074
 598:	6174                	.insn	2, 0x6174
 59a:	6772                	.insn	2, 0x6772
 59c:	7465                	.insn	2, 0x7465
 59e:	6e00                	.insn	2, 0x6e00
 5a0:	6d61                	.insn	2, 0x6d61
 5a2:	0065                	.insn	2, 0x0065
 5a4:	6964                	.insn	2, 0x6964
 5a6:	5f72                	.insn	2, 0x5f72
 5a8:	73756c63          	bltu	a0,s7,ce0 <_start-0xff320>
 5ac:	6574                	.insn	2, 0x6574
 5ae:	0072                	.insn	2, 0x0072
 5b0:	6964                	.insn	2, 0x6964
 5b2:	5f72                	.insn	2, 0x5f72
 5b4:	626c                	.insn	2, 0x626c
 5b6:	0061                	.insn	2, 0x0061
 5b8:	616d                	.insn	2, 0x616d
 5ba:	6374                	.insn	2, 0x6374
 5bc:	0068                	.insn	2, 0x0068
 5be:	7461                	.insn	2, 0x7461
 5c0:	7274                	.insn	2, 0x7274
 5c2:	6300                	.insn	2, 0x6300
 5c4:	5f6c                	.insn	2, 0x5f6c
 5c6:	6968                	.insn	2, 0x6968
 5c8:	6300                	.insn	2, 0x6300
 5ca:	5f6c                	.insn	2, 0x5f6c
 5cc:	6f6c                	.insn	2, 0x6f6c
 5ce:	6400                	.insn	2, 0x6400
 5d0:	615f7473          	csrrci	s0,htimedeltah,30
 5d4:	6464                	.insn	2, 0x6464
 5d6:	0072                	.insn	2, 0x0072
 5d8:	6f6c                	.insn	2, 0x6f6c
 5da:	6461                	.insn	2, 0x6461
 5dc:	6465                	.insn	2, 0x6465
 5de:	735f 7a69 0065      	.insn	6, 0x00657a69735f
 5e4:	6572                	.insn	2, 0x6572
 5e6:	616d                	.insn	2, 0x616d
 5e8:	6e69                	.insn	2, 0x6e69
 5ea:	6300                	.insn	2, 0x6300
 5ec:	5f79706f          	j	983e2 <_start-0x67c1e>
 5f0:	657a6973          	csrrsi	s2,hviprio2h,20
 5f4:	6c00                	.insn	2, 0x6c00
 5f6:	6564616f          	jal	sp,46c4c <_start-0xb93b4>
 5fa:	5f64                	.insn	2, 0x5f64
 5fc:	64726f77          	.insn	4, 0x64726f77
 600:	65680073          	.insn	4, 0x65680073
 604:	5f78                	.insn	2, 0x5f78
 606:	6e756f63          	bltu	a0,t2,d04 <_start-0xff2fc>
 60a:	0074                	.insn	2, 0x0074
 60c:	64726f77          	.insn	4, 0x64726f77
 610:	7300                	.insn	2, 0x7300
 612:	6365                	.insn	2, 0x6365
 614:	6f74                	.insn	2, 0x6f74
 616:	5f72                	.insn	2, 0x5f72
 618:	7962                	.insn	2, 0x7962
 61a:	6574                	.insn	2, 0x6574
 61c:	0073                	.short	0x0073

Disassembly of section .debug_addr:

00000000 <.debug_addr>:
   0:	0244                	.insn	2, 0x0244
   2:	0000                	.insn	2, 0x0000
   4:	0005                	.insn	2, 0x0005
   6:	0004                	.insn	2, 0x0004
   8:	314c                	.insn	2, 0x314c
   a:	0010                	.insn	2, 0x0010
   c:	3164                	.insn	2, 0x3164
   e:	0010                	.insn	2, 0x0010
  10:	3174                	.insn	2, 0x3174
  12:	0010                	.insn	2, 0x0010
  14:	3188                	.insn	2, 0x3188
  16:	0010                	.insn	2, 0x0010
  18:	00103193          	seqz	gp,zero
  1c:	001031ab          	.insn	4, 0x001031ab
  20:	31b4                	.insn	2, 0x31b4
  22:	0010                	.insn	2, 0x0010
  24:	31ca                	.insn	2, 0x31ca
  26:	0010                	.insn	2, 0x0010
  28:	338a                	.insn	2, 0x338a
  2a:	0010                	.insn	2, 0x0010
  2c:	31d8                	.insn	2, 0x31d8
  2e:	0010                	.insn	2, 0x0010
  30:	31e4                	.insn	2, 0x31e4
  32:	0010                	.insn	2, 0x0010
  34:	31ed                	.insn	2, 0x31ed
  36:	0010                	.insn	2, 0x0010
  38:	31f8                	.insn	2, 0x31f8
  3a:	0010                	.insn	2, 0x0010
  3c:	00103203          	.insn	4, 0x00103203
  40:	320e                	.insn	2, 0x320e
  42:	0010                	.insn	2, 0x0010
  44:	00103217          	auipc	tp,0x103
  48:	3226                	.insn	2, 0x3226
  4a:	0010                	.insn	2, 0x0010
  4c:	00103237          	lui	tp,0x103
  50:	324c                	.insn	2, 0x324c
  52:	0010                	.insn	2, 0x0010
  54:	3264                	.insn	2, 0x3264
  56:	0010                	.insn	2, 0x0010
  58:	3270                	.insn	2, 0x3270
  5a:	0010                	.insn	2, 0x0010
  5c:	0014                	.insn	2, 0x0014
  5e:	0010                	.insn	2, 0x0010
  60:	0018                	.insn	2, 0x0018
  62:	0010                	.insn	2, 0x0010
  64:	002c                	.insn	2, 0x002c
  66:	0010                	.insn	2, 0x0010
  68:	0034                	.insn	2, 0x0034
  6a:	0010                	.insn	2, 0x0010
  6c:	0038                	.insn	2, 0x0038
  6e:	0010                	.insn	2, 0x0010
  70:	004c                	.insn	2, 0x004c
  72:	0010                	.insn	2, 0x0010
  74:	0054                	.insn	2, 0x0054
  76:	0010                	.insn	2, 0x0010
  78:	008c                	.insn	2, 0x008c
  7a:	0010                	.insn	2, 0x0010
  7c:	0090                	.insn	2, 0x0090
  7e:	0010                	.insn	2, 0x0010
  80:	00a4                	.insn	2, 0x00a4
  82:	0010                	.insn	2, 0x0010
  84:	00c0                	.insn	2, 0x00c0
  86:	0010                	.insn	2, 0x0010
  88:	00e4                	.insn	2, 0x00e4
  8a:	0010                	.insn	2, 0x0010
  8c:	00e8                	.insn	2, 0x00e8
  8e:	0010                	.insn	2, 0x0010
  90:	00fc                	.insn	2, 0x00fc
  92:	0010                	.insn	2, 0x0010
  94:	0114                	.insn	2, 0x0114
  96:	0010                	.insn	2, 0x0010
  98:	0138                	.insn	2, 0x0138
  9a:	0010                	.insn	2, 0x0010
  9c:	0240                	.insn	2, 0x0240
  9e:	0010                	.insn	2, 0x0010
  a0:	0244                	.insn	2, 0x0244
  a2:	0010                	.insn	2, 0x0010
  a4:	0258                	.insn	2, 0x0258
  a6:	0010                	.insn	2, 0x0010
  a8:	014c                	.insn	2, 0x014c
  aa:	0010                	.insn	2, 0x0010
  ac:	0160                	.insn	2, 0x0160
  ae:	0010                	.insn	2, 0x0010
  b0:	0280                	.insn	2, 0x0280
  b2:	0010                	.insn	2, 0x0010
  b4:	0284                	.insn	2, 0x0284
  b6:	0010                	.insn	2, 0x0010
  b8:	0298                	.insn	2, 0x0298
  ba:	0010                	.insn	2, 0x0010
  bc:	019c                	.insn	2, 0x019c
  be:	0010                	.insn	2, 0x0010
  c0:	01a0                	.insn	2, 0x01a0
  c2:	0010                	.insn	2, 0x0010
  c4:	01b4                	.insn	2, 0x01b4
  c6:	0010                	.insn	2, 0x0010
  c8:	01fc                	.insn	2, 0x01fc
  ca:	0010                	.insn	2, 0x0010
  cc:	0200                	.insn	2, 0x0200
  ce:	0010                	.insn	2, 0x0010
  d0:	0214                	.insn	2, 0x0214
  d2:	0010                	.insn	2, 0x0010
  d4:	02e4                	.insn	2, 0x02e4
  d6:	0010                	.insn	2, 0x0010
  d8:	02e8                	.insn	2, 0x02e8
  da:	0010                	.insn	2, 0x0010
  dc:	02fc                	.insn	2, 0x02fc
  de:	0010                	.insn	2, 0x0010
  e0:	0430                	.insn	2, 0x0430
  e2:	0010                	.insn	2, 0x0010
  e4:	017c                	.insn	2, 0x017c
  e6:	0010                	.insn	2, 0x0010
  e8:	01dc                	.insn	2, 0x01dc
  ea:	0010                	.insn	2, 0x0010
  ec:	02c4                	.insn	2, 0x02c4
  ee:	0010                	.insn	2, 0x0010
  f0:	031c                	.insn	2, 0x031c
  f2:	0010                	.insn	2, 0x0010
  f4:	0328                	.insn	2, 0x0328
  f6:	0010                	.insn	2, 0x0010
  f8:	033c                	.insn	2, 0x033c
  fa:	0010                	.insn	2, 0x0010
  fc:	034c                	.insn	2, 0x034c
  fe:	0010                	.insn	2, 0x0010
 100:	0358                	.insn	2, 0x0358
 102:	0010                	.insn	2, 0x0010
 104:	0364                	.insn	2, 0x0364
 106:	0010                	.insn	2, 0x0010
 108:	0374                	.insn	2, 0x0374
 10a:	0010                	.insn	2, 0x0010
 10c:	0384                	.insn	2, 0x0384
 10e:	0010                	.insn	2, 0x0010
 110:	0390                	.insn	2, 0x0390
 112:	0010                	.insn	2, 0x0010
 114:	03a0                	.insn	2, 0x03a0
 116:	0010                	.insn	2, 0x0010
 118:	03ac                	.insn	2, 0x03ac
 11a:	0010                	.insn	2, 0x0010
 11c:	03b8                	.insn	2, 0x03b8
 11e:	0010                	.insn	2, 0x0010
 120:	03c8                	.insn	2, 0x03c8
 122:	0010                	.insn	2, 0x0010
 124:	03d4                	.insn	2, 0x03d4
 126:	0010                	.insn	2, 0x0010
 128:	03e0                	.insn	2, 0x03e0
 12a:	0010                	.insn	2, 0x0010
 12c:	03f0                	.insn	2, 0x03f0
 12e:	0010                	.insn	2, 0x0010
 130:	03fc                	.insn	2, 0x03fc
 132:	0010                	.insn	2, 0x0010
 134:	0408                	.insn	2, 0x0408
 136:	0010                	.insn	2, 0x0010
 138:	0418                	.insn	2, 0x0418
 13a:	0010                	.insn	2, 0x0010
 13c:	0424                	.insn	2, 0x0424
 13e:	0010                	.insn	2, 0x0010
 140:	0434                	.insn	2, 0x0434
 142:	0010                	.insn	2, 0x0010
 144:	0438                	.insn	2, 0x0438
 146:	0010                	.insn	2, 0x0010
 148:	044c                	.insn	2, 0x044c
 14a:	0010                	.insn	2, 0x0010
 14c:	045c                	.insn	2, 0x045c
 14e:	0010                	.insn	2, 0x0010
 150:	046c                	.insn	2, 0x046c
 152:	0010                	.insn	2, 0x0010
 154:	04f8                	.insn	2, 0x04f8
 156:	0010                	.insn	2, 0x0010
 158:	05c8                	.insn	2, 0x05c8
 15a:	0010                	.insn	2, 0x0010
 15c:	0b5c                	.insn	2, 0x0b5c
 15e:	0010                	.insn	2, 0x0010
 160:	0b60                	.insn	2, 0x0b60
 162:	0010                	.insn	2, 0x0010
 164:	0b74                	.insn	2, 0x0b74
 166:	0010                	.insn	2, 0x0010
 168:	0b90                	.insn	2, 0x0b90
 16a:	0010                	.insn	2, 0x0010
 16c:	0bb0                	.insn	2, 0x0bb0
 16e:	0010                	.insn	2, 0x0010
 170:	0bb4                	.insn	2, 0x0bb4
 172:	0010                	.insn	2, 0x0010
 174:	0bc0                	.insn	2, 0x0bc0
 176:	0010                	.insn	2, 0x0010
 178:	0bd0                	.insn	2, 0x0bd0
 17a:	0010                	.insn	2, 0x0010
 17c:	0bd4                	.insn	2, 0x0bd4
 17e:	0010                	.insn	2, 0x0010
 180:	06a8                	.insn	2, 0x06a8
 182:	0010                	.insn	2, 0x0010
 184:	06bc                	.insn	2, 0x06bc
 186:	0010                	.insn	2, 0x0010
 188:	0ab8                	.insn	2, 0x0ab8
 18a:	0010                	.insn	2, 0x0010
 18c:	0abc                	.insn	2, 0x0abc
 18e:	0010                	.insn	2, 0x0010
 190:	0ad0                	.insn	2, 0x0ad0
 192:	0010                	.insn	2, 0x0010
 194:	0aec                	.insn	2, 0x0aec
 196:	0010                	.insn	2, 0x0010
 198:	0b0c                	.insn	2, 0x0b0c
 19a:	0010                	.insn	2, 0x0010
 19c:	0b10                	.insn	2, 0x0b10
 19e:	0010                	.insn	2, 0x0010
 1a0:	0b1c                	.insn	2, 0x0b1c
 1a2:	0010                	.insn	2, 0x0010
 1a4:	0b2c                	.insn	2, 0x0b2c
 1a6:	0010                	.insn	2, 0x0010
 1a8:	0b30                	.insn	2, 0x0b30
 1aa:	0010                	.insn	2, 0x0010
 1ac:	073c                	.insn	2, 0x073c
 1ae:	0010                	.insn	2, 0x0010
 1b0:	0758                	.insn	2, 0x0758
 1b2:	0010                	.insn	2, 0x0010
 1b4:	076c                	.insn	2, 0x076c
 1b6:	0010                	.insn	2, 0x0010
 1b8:	082c                	.insn	2, 0x082c
 1ba:	0010                	.insn	2, 0x0010
 1bc:	0830                	.insn	2, 0x0830
 1be:	0010                	.insn	2, 0x0010
 1c0:	0844                	.insn	2, 0x0844
 1c2:	0010                	.insn	2, 0x0010
 1c4:	0858                	.insn	2, 0x0858
 1c6:	0010                	.insn	2, 0x0010
 1c8:	0878                	.insn	2, 0x0878
 1ca:	0010                	.insn	2, 0x0010
 1cc:	087c                	.insn	2, 0x087c
 1ce:	0010                	.insn	2, 0x0010
 1d0:	0888                	.insn	2, 0x0888
 1d2:	0010                	.insn	2, 0x0010
 1d4:	0898                	.insn	2, 0x0898
 1d6:	0010                	.insn	2, 0x0010
 1d8:	08fc                	.insn	2, 0x08fc
 1da:	0010                	.insn	2, 0x0010
 1dc:	091c                	.insn	2, 0x091c
 1de:	0010                	.insn	2, 0x0010
 1e0:	0920                	.insn	2, 0x0920
 1e2:	0010                	.insn	2, 0x0010
 1e4:	092c                	.insn	2, 0x092c
 1e6:	0010                	.insn	2, 0x0010
 1e8:	093c                	.insn	2, 0x093c
 1ea:	0010                	.insn	2, 0x0010
 1ec:	09a0                	.insn	2, 0x09a0
 1ee:	0010                	.insn	2, 0x0010
 1f0:	09c0                	.insn	2, 0x09c0
 1f2:	0010                	.insn	2, 0x0010
 1f4:	09c4                	.insn	2, 0x09c4
 1f6:	0010                	.insn	2, 0x0010
 1f8:	09d0                	.insn	2, 0x09d0
 1fa:	0010                	.insn	2, 0x0010
 1fc:	09e0                	.insn	2, 0x09e0
 1fe:	0010                	.insn	2, 0x0010
 200:	09e4                	.insn	2, 0x09e4
 202:	0010                	.insn	2, 0x0010
 204:	09f0                	.insn	2, 0x09f0
 206:	0010                	.insn	2, 0x0010
 208:	09f8                	.insn	2, 0x09f8
 20a:	0010                	.insn	2, 0x0010
 20c:	0a28                	.insn	2, 0x0a28
 20e:	0010                	.insn	2, 0x0010
 210:	0a2c                	.insn	2, 0x0a2c
 212:	0010                	.insn	2, 0x0010
 214:	0a40                	.insn	2, 0x0a40
 216:	0010                	.insn	2, 0x0010
 218:	0a5c                	.insn	2, 0x0a5c
 21a:	0010                	.insn	2, 0x0010
 21c:	0a7c                	.insn	2, 0x0a7c
 21e:	0010                	.insn	2, 0x0010
 220:	0a80                	.insn	2, 0x0a80
 222:	0010                	.insn	2, 0x0010
 224:	0a8c                	.insn	2, 0x0a8c
 226:	0010                	.insn	2, 0x0010
 228:	0be8                	.insn	2, 0x0be8
 22a:	0010                	.insn	2, 0x0010
 22c:	0c28                	.insn	2, 0x0c28
 22e:	0010                	.insn	2, 0x0010
 230:	0c2c                	.insn	2, 0x0c2c
 232:	0010                	.insn	2, 0x0010
 234:	0c44                	.insn	2, 0x0c44
 236:	0010                	.insn	2, 0x0010
 238:	0c54                	.insn	2, 0x0c54
 23a:	0010                	.insn	2, 0x0010
 23c:	0c74                	.insn	2, 0x0c74
 23e:	0010                	.insn	2, 0x0010
 240:	0c78                	.insn	2, 0x0c78
 242:	0010                	.insn	2, 0x0010
 244:	0c84                	.insn	2, 0x0c84
 246:	0010                	.insn	2, 0x0010
 248:	00f0                	.insn	2, 0x00f0
 24a:	0000                	.insn	2, 0x0000
 24c:	0005                	.insn	2, 0x0005
 24e:	0004                	.insn	2, 0x0004
 250:	32fa                	.insn	2, 0x32fa
 252:	0010                	.insn	2, 0x0010
 254:	3280                	.insn	2, 0x3280
 256:	0010                	.insn	2, 0x0010
 258:	00103283          	.insn	4, 0x00103283
 25c:	32a6                	.insn	2, 0x32a6
 25e:	0010                	.insn	2, 0x0010
 260:	32ca                	.insn	2, 0x32ca
 262:	0010                	.insn	2, 0x0010
 264:	0c94                	.insn	2, 0x0c94
 266:	0010                	.insn	2, 0x0010
 268:	0cbc                	.insn	2, 0x0cbc
 26a:	0010                	.insn	2, 0x0010
 26c:	0cec                	.insn	2, 0x0cec
 26e:	0010                	.insn	2, 0x0010
 270:	0d0c                	.insn	2, 0x0d0c
 272:	0010                	.insn	2, 0x0010
 274:	0d7c                	.insn	2, 0x0d7c
 276:	0010                	.insn	2, 0x0010
 278:	0d40                	.insn	2, 0x0d40
 27a:	0010                	.insn	2, 0x0010
 27c:	0d58                	.insn	2, 0x0d58
 27e:	0010                	.insn	2, 0x0010
 280:	0de0                	.insn	2, 0x0de0
 282:	0010                	.insn	2, 0x0010
 284:	0e04                	.insn	2, 0x0e04
 286:	0010                	.insn	2, 0x0010
 288:	0f04                	.insn	2, 0x0f04
 28a:	0010                	.insn	2, 0x0010
 28c:	0f14                	.insn	2, 0x0f14
 28e:	0010                	.insn	2, 0x0010
 290:	0fe8                	.insn	2, 0x0fe8
 292:	0010                	.insn	2, 0x0010
 294:	0eb0                	.insn	2, 0x0eb0
 296:	0010                	.insn	2, 0x0010
 298:	0ef4                	.insn	2, 0x0ef4
 29a:	0010                	.insn	2, 0x0010
 29c:	0f28                	.insn	2, 0x0f28
 29e:	0010                	.insn	2, 0x0010
 2a0:	0f40                	.insn	2, 0x0f40
 2a2:	0010                	.insn	2, 0x0010
 2a4:	0f58                	.insn	2, 0x0f58
 2a6:	0010                	.insn	2, 0x0010
 2a8:	0f70                	.insn	2, 0x0f70
 2aa:	0010                	.insn	2, 0x0010
 2ac:	0f88                	.insn	2, 0x0f88
 2ae:	0010                	.insn	2, 0x0010
 2b0:	0fa0                	.insn	2, 0x0fa0
 2b2:	0010                	.insn	2, 0x0010
 2b4:	0fb8                	.insn	2, 0x0fb8
 2b6:	0010                	.insn	2, 0x0010
 2b8:	0fcc                	.insn	2, 0x0fcc
 2ba:	0010                	.insn	2, 0x0010
 2bc:	0fe0                	.insn	2, 0x0fe0
 2be:	0010                	.insn	2, 0x0010
 2c0:	1010                	.insn	2, 0x1010
 2c2:	0010                	.insn	2, 0x0010
 2c4:	102c                	.insn	2, 0x102c
 2c6:	0010                	.insn	2, 0x0010
 2c8:	1078                	.insn	2, 0x1078
 2ca:	0010                	.insn	2, 0x0010
 2cc:	1094                	.insn	2, 0x1094
 2ce:	0010                	.insn	2, 0x0010
 2d0:	10d0                	.insn	2, 0x10d0
 2d2:	0010                	.insn	2, 0x0010
 2d4:	1194                	.insn	2, 0x1194
 2d6:	0010                	.insn	2, 0x0010
 2d8:	12f4                	.insn	2, 0x12f4
 2da:	0010                	.insn	2, 0x0010
 2dc:	1308                	.insn	2, 0x1308
 2de:	0010                	.insn	2, 0x0010
 2e0:	138c                	.insn	2, 0x138c
 2e2:	0010                	.insn	2, 0x0010
 2e4:	1204                	.insn	2, 0x1204
 2e6:	0010                	.insn	2, 0x0010
 2e8:	1210                	.insn	2, 0x1210
 2ea:	0010                	.insn	2, 0x0010
 2ec:	1234                	.insn	2, 0x1234
 2ee:	0010                	.insn	2, 0x0010
 2f0:	124c                	.insn	2, 0x124c
 2f2:	0010                	.insn	2, 0x0010
 2f4:	1264                	.insn	2, 0x1264
 2f6:	0010                	.insn	2, 0x0010
 2f8:	127c                	.insn	2, 0x127c
 2fa:	0010                	.insn	2, 0x0010
 2fc:	1294                	.insn	2, 0x1294
 2fe:	0010                	.insn	2, 0x0010
 300:	12ac                	.insn	2, 0x12ac
 302:	0010                	.insn	2, 0x0010
 304:	12c4                	.insn	2, 0x12c4
 306:	0010                	.insn	2, 0x0010
 308:	12d8                	.insn	2, 0x12d8
 30a:	0010                	.insn	2, 0x0010
 30c:	12e8                	.insn	2, 0x12e8
 30e:	0010                	.insn	2, 0x0010
 310:	131c                	.insn	2, 0x131c
 312:	0010                	.insn	2, 0x0010
 314:	133c                	.insn	2, 0x133c
 316:	0010                	.insn	2, 0x0010
 318:	1348                	.insn	2, 0x1348
 31a:	0010                	.insn	2, 0x0010
 31c:	1354                	.insn	2, 0x1354
 31e:	0010                	.insn	2, 0x0010
 320:	1364                	.insn	2, 0x1364
 322:	0010                	.insn	2, 0x0010
 324:	1380                	.insn	2, 0x1380
 326:	0010                	.insn	2, 0x0010
 328:	13a8                	.insn	2, 0x13a8
 32a:	0010                	.insn	2, 0x0010
 32c:	1404                	.insn	2, 0x1404
 32e:	0010                	.insn	2, 0x0010
 330:	1508                	.insn	2, 0x1508
 332:	0010                	.insn	2, 0x0010
 334:	1604                	.insn	2, 0x1604
 336:	0010                	.insn	2, 0x0010
 338:	1620                	.insn	2, 0x1620
 33a:	0010                	.insn	2, 0x0010
 33c:	0110                	.insn	2, 0x0110
 33e:	0000                	.insn	2, 0x0000
 340:	0005                	.insn	2, 0x0005
 342:	0004                	.insn	2, 0x0004
 344:	0010330b          	.insn	4, 0x0010330b
 348:	3320                	.insn	2, 0x3320
 34a:	0010                	.insn	2, 0x0010
 34c:	00103333          	snez	t1,ra
 350:	00103353          	.insn	4, 0x00103353
 354:	3365                	.insn	2, 0x3365
 356:	0010                	.insn	2, 0x0010
 358:	3379                	.insn	2, 0x3379
 35a:	0010                	.insn	2, 0x0010
 35c:	338c                	.insn	2, 0x338c
 35e:	0010                	.insn	2, 0x0010
 360:	33ad                	.insn	2, 0x33ad
 362:	0010                	.insn	2, 0x0010
 364:	33d2                	.insn	2, 0x33d2
 366:	0010                	.insn	2, 0x0010
 368:	33df 0010 33ea      	.insn	6, 0x33ea001033df
 36e:	0010                	.insn	2, 0x0010
 370:	1628                	.insn	2, 0x1628
 372:	0010                	.insn	2, 0x0010
 374:	1630                	.insn	2, 0x1630
 376:	0010                	.insn	2, 0x0010
 378:	1640                	.insn	2, 0x1640
 37a:	0010                	.insn	2, 0x0010
 37c:	1688                	.insn	2, 0x1688
 37e:	0010                	.insn	2, 0x0010
 380:	16a4                	.insn	2, 0x16a4
 382:	0010                	.insn	2, 0x0010
 384:	16d8                	.insn	2, 0x16d8
 386:	0010                	.insn	2, 0x0010
 388:	17b4                	.insn	2, 0x17b4
 38a:	0010                	.insn	2, 0x0010
 38c:	17f0                	.insn	2, 0x17f0
 38e:	0010                	.insn	2, 0x0010
 390:	1814                	.insn	2, 0x1814
 392:	0010                	.insn	2, 0x0010
 394:	181c                	.insn	2, 0x181c
 396:	0010                	.insn	2, 0x0010
 398:	1834                	.insn	2, 0x1834
 39a:	0010                	.insn	2, 0x0010
 39c:	184c                	.insn	2, 0x184c
 39e:	0010                	.insn	2, 0x0010
 3a0:	1860                	.insn	2, 0x1860
 3a2:	0010                	.insn	2, 0x0010
 3a4:	18a4                	.insn	2, 0x18a4
 3a6:	0010                	.insn	2, 0x0010
 3a8:	18bc                	.insn	2, 0x18bc
 3aa:	0010                	.insn	2, 0x0010
 3ac:	18cc                	.insn	2, 0x18cc
 3ae:	0010                	.insn	2, 0x0010
 3b0:	18e4                	.insn	2, 0x18e4
 3b2:	0010                	.insn	2, 0x0010
 3b4:	18fc                	.insn	2, 0x18fc
 3b6:	0010                	.insn	2, 0x0010
 3b8:	1910                	.insn	2, 0x1910
 3ba:	0010                	.insn	2, 0x0010
 3bc:	1954                	.insn	2, 0x1954
 3be:	0010                	.insn	2, 0x0010
 3c0:	196c                	.insn	2, 0x196c
 3c2:	0010                	.insn	2, 0x0010
 3c4:	197c                	.insn	2, 0x197c
 3c6:	0010                	.insn	2, 0x0010
 3c8:	1994                	.insn	2, 0x1994
 3ca:	0010                	.insn	2, 0x0010
 3cc:	19ac                	.insn	2, 0x19ac
 3ce:	0010                	.insn	2, 0x0010
 3d0:	19c0                	.insn	2, 0x19c0
 3d2:	0010                	.insn	2, 0x0010
 3d4:	1a04                	.insn	2, 0x1a04
 3d6:	0010                	.insn	2, 0x0010
 3d8:	1a1c                	.insn	2, 0x1a1c
 3da:	0010                	.insn	2, 0x0010
 3dc:	1a40                	.insn	2, 0x1a40
 3de:	0010                	.insn	2, 0x0010
 3e0:	1a50                	.insn	2, 0x1a50
 3e2:	0010                	.insn	2, 0x0010
 3e4:	1a5c                	.insn	2, 0x1a5c
 3e6:	0010                	.insn	2, 0x0010
 3e8:	1ab0                	.insn	2, 0x1ab0
 3ea:	0010                	.insn	2, 0x0010
 3ec:	1acc                	.insn	2, 0x1acc
 3ee:	0010                	.insn	2, 0x0010
 3f0:	1b00                	.insn	2, 0x1b00
 3f2:	0010                	.insn	2, 0x0010
 3f4:	1bcc                	.insn	2, 0x1bcc
 3f6:	0010                	.insn	2, 0x0010
 3f8:	1c5c                	.insn	2, 0x1c5c
 3fa:	0010                	.insn	2, 0x0010
 3fc:	1c70                	.insn	2, 0x1c70
 3fe:	0010                	.insn	2, 0x0010
 400:	1d7c                	.insn	2, 0x1d7c
 402:	0010                	.insn	2, 0x0010
 404:	1d84                	.insn	2, 0x1d84
 406:	0010                	.insn	2, 0x0010
 408:	1c34                	.insn	2, 0x1c34
 40a:	0010                	.insn	2, 0x0010
 40c:	1c4c                	.insn	2, 0x1c4c
 40e:	0010                	.insn	2, 0x0010
 410:	1d30                	.insn	2, 0x1d30
 412:	0010                	.insn	2, 0x0010
 414:	1d48                	.insn	2, 0x1d48
 416:	0010                	.insn	2, 0x0010
 418:	1d60                	.insn	2, 0x1d60
 41a:	0010                	.insn	2, 0x0010
 41c:	1da0                	.insn	2, 0x1da0
 41e:	0010                	.insn	2, 0x0010
 420:	1db4                	.insn	2, 0x1db4
 422:	0010                	.insn	2, 0x0010
 424:	1dc0                	.insn	2, 0x1dc0
 426:	0010                	.insn	2, 0x0010
 428:	1dd4                	.insn	2, 0x1dd4
 42a:	0010                	.insn	2, 0x0010
 42c:	1e04                	.insn	2, 0x1e04
 42e:	0010                	.insn	2, 0x0010
 430:	1e30                	.insn	2, 0x1e30
 432:	0010                	.insn	2, 0x0010
 434:	1e40                	.insn	2, 0x1e40
 436:	0010                	.insn	2, 0x0010
 438:	1e60                	.insn	2, 0x1e60
 43a:	0010                	.insn	2, 0x0010
 43c:	1e70                	.insn	2, 0x1e70
 43e:	0010                	.insn	2, 0x0010
 440:	1e88                	.insn	2, 0x1e88
 442:	0010                	.insn	2, 0x0010
 444:	1e98                	.insn	2, 0x1e98
 446:	0010                	.insn	2, 0x0010
 448:	1eb0                	.insn	2, 0x1eb0
 44a:	0010                	.insn	2, 0x0010
 44c:	1ed0                	.insn	2, 0x1ed0
 44e:	0010                	.insn	2, 0x0010
 450:	02c4                	.insn	2, 0x02c4
 452:	0000                	.insn	2, 0x0000
 454:	0005                	.insn	2, 0x0005
 456:	0004                	.insn	2, 0x0004
 458:	001033f7          	.insn	4, 0x001033f7
 45c:	00103407          	.insn	4, 0x00103407
 460:	0010341b          	.insn	4, 0x0010341b
 464:	3434                	.insn	2, 0x3434
 466:	0010                	.insn	2, 0x0010
 468:	3446                	.insn	2, 0x3446
 46a:	0010                	.insn	2, 0x0010
 46c:	345f 0010 3474      	.insn	6, 0x34740010345f
 472:	0010                	.insn	2, 0x0010
 474:	3489                	.insn	2, 0x3489
 476:	0010                	.insn	2, 0x0010
 478:	349d                	.insn	2, 0x349d
 47a:	0010                	.insn	2, 0x0010
 47c:	34ad                	.insn	2, 0x34ad
 47e:	0010                	.insn	2, 0x0010
 480:	001034c3          	.insn	4, 0x001034c3
 484:	34d4                	.insn	2, 0x34d4
 486:	0010                	.insn	2, 0x0010
 488:	34ec                	.insn	2, 0x34ec
 48a:	0010                	.insn	2, 0x0010
 48c:	3500                	.insn	2, 0x3500
 48e:	0010                	.insn	2, 0x0010
 490:	3514                	.insn	2, 0x3514
 492:	0010                	.insn	2, 0x0010
 494:	3526                	.insn	2, 0x3526
 496:	0010                	.insn	2, 0x0010
 498:	3536                	.insn	2, 0x3536
 49a:	0010                	.insn	2, 0x0010
 49c:	3546                	.insn	2, 0x3546
 49e:	0010                	.insn	2, 0x0010
 4a0:	3556                	.insn	2, 0x3556
 4a2:	0010                	.insn	2, 0x0010
 4a4:	3566                	.insn	2, 0x3566
 4a6:	0010                	.insn	2, 0x0010
 4a8:	3576                	.insn	2, 0x3576
 4aa:	0010                	.insn	2, 0x0010
 4ac:	3586                	.insn	2, 0x3586
 4ae:	0010                	.insn	2, 0x0010
 4b0:	00103597          	auipc	a1,0x103
 4b4:	001035a7          	.insn	4, 0x001035a7
 4b8:	001035b7          	lui	a1,0x103
 4bc:	35cc                	.insn	2, 0x35cc
 4be:	0010                	.insn	2, 0x0010
 4c0:	35e2                	.insn	2, 0x35e2
 4c2:	0010                	.insn	2, 0x0010
 4c4:	001035f7          	.insn	4, 0x001035f7
 4c8:	3610                	.insn	2, 0x3610
 4ca:	0010                	.insn	2, 0x0010
 4cc:	00103623          	.insn	4, 0x00103623
 4d0:	3635                	.insn	2, 0x3635
 4d2:	0010                	.insn	2, 0x0010
 4d4:	3648                	.insn	2, 0x3648
 4d6:	0010                	.insn	2, 0x0010
 4d8:	3659                	.insn	2, 0x3659
 4da:	0010                	.insn	2, 0x0010
 4dc:	0010366b          	.insn	4, 0x0010366b
 4e0:	367c                	.insn	2, 0x367c
 4e2:	0010                	.insn	2, 0x0010
 4e4:	368d                	.insn	2, 0x368d
 4e6:	0010                	.insn	2, 0x0010
 4e8:	369e                	.insn	2, 0x369e
 4ea:	0010                	.insn	2, 0x0010
 4ec:	001036af          	.insn	4, 0x001036af
 4f0:	36c0                	.insn	2, 0x36c0
 4f2:	0010                	.insn	2, 0x0010
 4f4:	001036d3          	.insn	4, 0x001036d3
 4f8:	36e5                	.insn	2, 0x36e5
 4fa:	0010                	.insn	2, 0x0010
 4fc:	36f6                	.insn	2, 0x36f6
 4fe:	0010                	.insn	2, 0x0010
 500:	00103707          	.insn	4, 0x00103707
 504:	371f 0010 372e      	.insn	6, 0x372e0010371f
 50a:	0010                	.insn	2, 0x0010
 50c:	373e                	.insn	2, 0x373e
 50e:	0010                	.insn	2, 0x0010
 510:	374c                	.insn	2, 0x374c
 512:	0010                	.insn	2, 0x0010
 514:	375a                	.insn	2, 0x375a
 516:	0010                	.insn	2, 0x0010
 518:	00103767          	.insn	4, 0x00103767
 51c:	3779                	.insn	2, 0x3779
 51e:	0010                	.insn	2, 0x0010
 520:	378c                	.insn	2, 0x378c
 522:	0010                	.insn	2, 0x0010
 524:	37a0                	.insn	2, 0x37a0
 526:	0010                	.insn	2, 0x0010
 528:	37b0                	.insn	2, 0x37b0
 52a:	0010                	.insn	2, 0x0010
 52c:	338a                	.insn	2, 0x338a
 52e:	0010                	.insn	2, 0x0010
 530:	37c0                	.insn	2, 0x37c0
 532:	0010                	.insn	2, 0x0010
 534:	37cd                	.insn	2, 0x37cd
 536:	0010                	.insn	2, 0x0010
 538:	37df 0010 37fd      	.insn	6, 0x37fd001037df
 53e:	0010                	.insn	2, 0x0010
 540:	3810                	.insn	2, 0x3810
 542:	0010                	.insn	2, 0x0010
 544:	00103823          	.insn	4, 0x00103823
 548:	3836                	.insn	2, 0x3836
 54a:	0010                	.insn	2, 0x0010
 54c:	384a                	.insn	2, 0x384a
 54e:	0010                	.insn	2, 0x0010
 550:	3866                	.insn	2, 0x3866
 552:	0010                	.insn	2, 0x0010
 554:	3875                	.insn	2, 0x3875
 556:	0010                	.insn	2, 0x0010
 558:	388e                	.insn	2, 0x388e
 55a:	0010                	.insn	2, 0x0010
 55c:	001038a7          	.insn	4, 0x001038a7
 560:	38be                	.insn	2, 0x38be
 562:	0010                	.insn	2, 0x0010
 564:	38ce                	.insn	2, 0x38ce
 566:	0010                	.insn	2, 0x0010
 568:	38e4                	.insn	2, 0x38e4
 56a:	0010                	.insn	2, 0x0010
 56c:	38f9                	.insn	2, 0x38f9
 56e:	0010                	.insn	2, 0x0010
 570:	3911                	.insn	2, 0x3911
 572:	0010                	.insn	2, 0x0010
 574:	00103923          	.insn	4, 0x00103923
 578:	393a                	.insn	2, 0x393a
 57a:	0010                	.insn	2, 0x0010
 57c:	0010394f          	.insn	4, 0x0010394f
 580:	3968                	.insn	2, 0x3968
 582:	0010                	.insn	2, 0x0010
 584:	7ba0                	.insn	2, 0x7ba0
 586:	0010                	.insn	2, 0x0010
 588:	397e                	.insn	2, 0x397e
 58a:	0010                	.insn	2, 0x0010
 58c:	1eec                	.insn	2, 0x1eec
 58e:	0010                	.insn	2, 0x0010
 590:	1f18                	.insn	2, 0x1f18
 592:	0010                	.insn	2, 0x0010
 594:	1f48                	.insn	2, 0x1f48
 596:	0010                	.insn	2, 0x0010
 598:	200c                	.insn	2, 0x200c
 59a:	0010                	.insn	2, 0x0010
 59c:	202c                	.insn	2, 0x202c
 59e:	0010                	.insn	2, 0x0010
 5a0:	204c                	.insn	2, 0x204c
 5a2:	0010                	.insn	2, 0x0010
 5a4:	2064                	.insn	2, 0x2064
 5a6:	0010                	.insn	2, 0x0010
 5a8:	2084                	.insn	2, 0x2084
 5aa:	0010                	.insn	2, 0x0010
 5ac:	2090                	.insn	2, 0x2090
 5ae:	0010                	.insn	2, 0x0010
 5b0:	215c                	.insn	2, 0x215c
 5b2:	0010                	.insn	2, 0x0010
 5b4:	2194                	.insn	2, 0x2194
 5b6:	0010                	.insn	2, 0x0010
 5b8:	21bc                	.insn	2, 0x21bc
 5ba:	0010                	.insn	2, 0x0010
 5bc:	21d0                	.insn	2, 0x21d0
 5be:	0010                	.insn	2, 0x0010
 5c0:	1f7c                	.insn	2, 0x1f7c
 5c2:	0010                	.insn	2, 0x0010
 5c4:	1fa0                	.insn	2, 0x1fa0
 5c6:	0010                	.insn	2, 0x0010
 5c8:	1fb4                	.insn	2, 0x1fb4
 5ca:	0010                	.insn	2, 0x0010
 5cc:	1fd4                	.insn	2, 0x1fd4
 5ce:	0010                	.insn	2, 0x0010
 5d0:	20c0                	.insn	2, 0x20c0
 5d2:	0010                	.insn	2, 0x0010
 5d4:	20d8                	.insn	2, 0x20d8
 5d6:	0010                	.insn	2, 0x0010
 5d8:	20e8                	.insn	2, 0x20e8
 5da:	0010                	.insn	2, 0x0010
 5dc:	2114                	.insn	2, 0x2114
 5de:	0010                	.insn	2, 0x0010
 5e0:	211c                	.insn	2, 0x211c
 5e2:	0010                	.insn	2, 0x0010
 5e4:	214c                	.insn	2, 0x214c
 5e6:	0010                	.insn	2, 0x0010
 5e8:	217c                	.insn	2, 0x217c
 5ea:	0010                	.insn	2, 0x0010
 5ec:	21a8                	.insn	2, 0x21a8
 5ee:	0010                	.insn	2, 0x0010
 5f0:	21e8                	.insn	2, 0x21e8
 5f2:	0010                	.insn	2, 0x0010
 5f4:	2270                	.insn	2, 0x2270
 5f6:	0010                	.insn	2, 0x0010
 5f8:	229c                	.insn	2, 0x229c
 5fa:	0010                	.insn	2, 0x0010
 5fc:	22ac                	.insn	2, 0x22ac
 5fe:	0010                	.insn	2, 0x0010
 600:	22c8                	.insn	2, 0x22c8
 602:	0010                	.insn	2, 0x0010
 604:	22e0                	.insn	2, 0x22e0
 606:	0010                	.insn	2, 0x0010
 608:	230c                	.insn	2, 0x230c
 60a:	0010                	.insn	2, 0x0010
 60c:	2334                	.insn	2, 0x2334
 60e:	0010                	.insn	2, 0x0010
 610:	2358                	.insn	2, 0x2358
 612:	0010                	.insn	2, 0x0010
 614:	2384                	.insn	2, 0x2384
 616:	0010                	.insn	2, 0x0010
 618:	23a8                	.insn	2, 0x23a8
 61a:	0010                	.insn	2, 0x0010
 61c:	23cc                	.insn	2, 0x23cc
 61e:	0010                	.insn	2, 0x0010
 620:	23e8                	.insn	2, 0x23e8
 622:	0010                	.insn	2, 0x0010
 624:	2408                	.insn	2, 0x2408
 626:	0010                	.insn	2, 0x0010
 628:	2418                	.insn	2, 0x2418
 62a:	0010                	.insn	2, 0x0010
 62c:	2460                	.insn	2, 0x2460
 62e:	0010                	.insn	2, 0x0010
 630:	24b4                	.insn	2, 0x24b4
 632:	0010                	.insn	2, 0x0010
 634:	25cc                	.insn	2, 0x25cc
 636:	0010                	.insn	2, 0x0010
 638:	2510                	.insn	2, 0x2510
 63a:	0010                	.insn	2, 0x0010
 63c:	2754                	.insn	2, 0x2754
 63e:	0010                	.insn	2, 0x0010
 640:	28bc                	.insn	2, 0x28bc
 642:	0010                	.insn	2, 0x0010
 644:	28d0                	.insn	2, 0x28d0
 646:	0010                	.insn	2, 0x0010
 648:	2900                	.insn	2, 0x2900
 64a:	0010                	.insn	2, 0x0010
 64c:	27ec                	.insn	2, 0x27ec
 64e:	0010                	.insn	2, 0x0010
 650:	2508                	.insn	2, 0x2508
 652:	0010                	.insn	2, 0x0010
 654:	2620                	.insn	2, 0x2620
 656:	0010                	.insn	2, 0x0010
 658:	26bc                	.insn	2, 0x26bc
 65a:	0010                	.insn	2, 0x0010
 65c:	26d4                	.insn	2, 0x26d4
 65e:	0010                	.insn	2, 0x0010
 660:	2704                	.insn	2, 0x2704
 662:	0010                	.insn	2, 0x0010
 664:	2718                	.insn	2, 0x2718
 666:	0010                	.insn	2, 0x0010
 668:	27e4                	.insn	2, 0x27e4
 66a:	0010                	.insn	2, 0x0010
 66c:	280c                	.insn	2, 0x280c
 66e:	0010                	.insn	2, 0x0010
 670:	2870                	.insn	2, 0x2870
 672:	0010                	.insn	2, 0x0010
 674:	28cc                	.insn	2, 0x28cc
 676:	0010                	.insn	2, 0x0010
 678:	2934                	.insn	2, 0x2934
 67a:	0010                	.insn	2, 0x0010
 67c:	2b38                	.insn	2, 0x2b38
 67e:	0010                	.insn	2, 0x0010
 680:	2be0                	.insn	2, 0x2be0
 682:	0010                	.insn	2, 0x0010
 684:	2bf0                	.insn	2, 0x2bf0
 686:	0010                	.insn	2, 0x0010
 688:	2c34                	.insn	2, 0x2c34
 68a:	0010                	.insn	2, 0x0010
 68c:	2c8c                	.insn	2, 0x2c8c
 68e:	0010                	.insn	2, 0x0010
 690:	2988                	.insn	2, 0x2988
 692:	0010                	.insn	2, 0x0010
 694:	299c                	.insn	2, 0x299c
 696:	0010                	.insn	2, 0x0010
 698:	29b4                	.insn	2, 0x29b4
 69a:	0010                	.insn	2, 0x0010
 69c:	2a04                	.insn	2, 0x2a04
 69e:	0010                	.insn	2, 0x0010
 6a0:	2a14                	.insn	2, 0x2a14
 6a2:	0010                	.insn	2, 0x0010
 6a4:	2a24                	.insn	2, 0x2a24
 6a6:	0010                	.insn	2, 0x0010
 6a8:	2a38                	.insn	2, 0x2a38
 6aa:	0010                	.insn	2, 0x0010
 6ac:	2a48                	.insn	2, 0x2a48
 6ae:	0010                	.insn	2, 0x0010
 6b0:	2a58                	.insn	2, 0x2a58
 6b2:	0010                	.insn	2, 0x0010
 6b4:	2a64                	.insn	2, 0x2a64
 6b6:	0010                	.insn	2, 0x0010
 6b8:	2a9c                	.insn	2, 0x2a9c
 6ba:	0010                	.insn	2, 0x0010
 6bc:	2aac                	.insn	2, 0x2aac
 6be:	0010                	.insn	2, 0x0010
 6c0:	2b04                	.insn	2, 0x2b04
 6c2:	0010                	.insn	2, 0x0010
 6c4:	2b14                	.insn	2, 0x2b14
 6c6:	0010                	.insn	2, 0x0010
 6c8:	2b8c                	.insn	2, 0x2b8c
 6ca:	0010                	.insn	2, 0x0010
 6cc:	2c00                	.insn	2, 0x2c00
 6ce:	0010                	.insn	2, 0x0010
 6d0:	2c14                	.insn	2, 0x2c14
 6d2:	0010                	.insn	2, 0x0010
 6d4:	2c24                	.insn	2, 0x2c24
 6d6:	0010                	.insn	2, 0x0010
 6d8:	2c5c                	.insn	2, 0x2c5c
 6da:	0010                	.insn	2, 0x0010
 6dc:	2c80                	.insn	2, 0x2c80
 6de:	0010                	.insn	2, 0x0010
 6e0:	2cac                	.insn	2, 0x2cac
 6e2:	0010                	.insn	2, 0x0010
 6e4:	2cfc                	.insn	2, 0x2cfc
 6e6:	0010                	.insn	2, 0x0010
 6e8:	2d48                	.insn	2, 0x2d48
 6ea:	0010                	.insn	2, 0x0010
 6ec:	2f74                	.insn	2, 0x2f74
 6ee:	0010                	.insn	2, 0x0010
 6f0:	2fb8                	.insn	2, 0x2fb8
 6f2:	0010                	.insn	2, 0x0010
 6f4:	2fc4                	.insn	2, 0x2fc4
 6f6:	0010                	.insn	2, 0x0010
 6f8:	3040                	.insn	2, 0x3040
 6fa:	0010                	.insn	2, 0x0010
 6fc:	2d9c                	.insn	2, 0x2d9c
 6fe:	0010                	.insn	2, 0x0010
 700:	2db0                	.insn	2, 0x2db0
 702:	0010                	.insn	2, 0x0010
 704:	2dcc                	.insn	2, 0x2dcc
 706:	0010                	.insn	2, 0x0010
 708:	2e20                	.insn	2, 0x2e20
 70a:	0010                	.insn	2, 0x0010
 70c:	2efc                	.insn	2, 0x2efc
 70e:	0010                	.insn	2, 0x0010
 710:	2f90                	.insn	2, 0x2f90
 712:	0010                	.insn	2, 0x0010
 714:	3060                	.insn	2, 0x3060
 716:	0010                	.insn	2, 0x0010

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
  14:	000c                	.insn	2, 0x000c
  16:	0000                	.insn	2, 0x0000
  18:	0000                	.insn	2, 0x0000
  1a:	0000                	.insn	2, 0x0000
  1c:	0014                	.insn	2, 0x0014
  1e:	0010                	.insn	2, 0x0010
  20:	0020                	.insn	2, 0x0020
  22:	0000                	.insn	2, 0x0000
  24:	000c                	.insn	2, 0x000c
  26:	0000                	.insn	2, 0x0000
  28:	0000                	.insn	2, 0x0000
  2a:	0000                	.insn	2, 0x0000
  2c:	0034                	.insn	2, 0x0034
  2e:	0010                	.insn	2, 0x0010
  30:	0020                	.insn	2, 0x0020
  32:	0000                	.insn	2, 0x0000
  34:	0018                	.insn	2, 0x0018
  36:	0000                	.insn	2, 0x0000
  38:	0000                	.insn	2, 0x0000
  3a:	0000                	.insn	2, 0x0000
  3c:	0054                	.insn	2, 0x0054
  3e:	0010                	.insn	2, 0x0010
  40:	03e4                	.insn	2, 0x03e4
  42:	0000                	.insn	2, 0x0000
  44:	0e44                	.insn	2, 0x0e44
  46:	5020                	.insn	2, 0x5020
  48:	0181                	.insn	2, 0x0181
  4a:	0288                	.insn	2, 0x0288
  4c:	0389                	.insn	2, 0x0389
  4e:	0492                	.insn	2, 0x0492
  50:	000c                	.insn	2, 0x000c
  52:	0000                	.insn	2, 0x0000
  54:	0000                	.insn	2, 0x0000
  56:	0000                	.insn	2, 0x0000
  58:	0438                	.insn	2, 0x0438
  5a:	0010                	.insn	2, 0x0010
  5c:	0034                	.insn	2, 0x0034
  5e:	0000                	.insn	2, 0x0000
  60:	0040                	.insn	2, 0x0040
  62:	0000                	.insn	2, 0x0000
  64:	0000                	.insn	2, 0x0000
  66:	0000                	.insn	2, 0x0000
  68:	046c                	.insn	2, 0x046c
  6a:	0010                	.insn	2, 0x0010
  6c:	07d8                	.insn	2, 0x07d8
  6e:	0000                	.insn	2, 0x0000
  70:	0e44                	.insn	2, 0x0e44
  72:	7030                	.insn	2, 0x7030
  74:	0188                	.insn	2, 0x0188
  76:	0289                	.insn	2, 0x0289
  78:	0392                	.insn	2, 0x0392
  7a:	05940493          	addi	s1,s0,89
  7e:	0695                	.insn	2, 0x0695
  80:	0796                	.insn	2, 0x0796
  82:	09980897          	auipc	a7,0x9980
  86:	0a99                	.insn	2, 0x0a99
  88:	0b9a                	.insn	2, 0x0b9a
  8a:	030a0c9b          	.insn	4, 0x030a0c9b
  8e:	0780                	.insn	2, 0x0780
  90:	c9c8                	.insn	2, 0xc9c8
  92:	d3d2                	.insn	2, 0xd3d2
  94:	d5d4                	.insn	2, 0xd5d4
  96:	d7d6                	.insn	2, 0xd7d6
  98:	d9d8                	.insn	2, 0xd9d8
  9a:	dbda                	.insn	2, 0xdbda
  9c:	0e44                	.insn	2, 0x0e44
  9e:	4400                	.insn	2, 0x4400
  a0:	0000000b          	.insn	4, 0x000b
  a4:	000c                	.insn	2, 0x000c
  a6:	0000                	.insn	2, 0x0000
  a8:	0000                	.insn	2, 0x0000
  aa:	0000                	.insn	2, 0x0000
  ac:	0c44                	.insn	2, 0x0c44
  ae:	0010                	.insn	2, 0x0010
  b0:	0050                	.insn	2, 0x0050
  b2:	0000                	.insn	2, 0x0000
  b4:	0010                	.insn	2, 0x0010
  b6:	0000                	.insn	2, 0x0000
  b8:	ffff                	.insn	2, 0xffff
  ba:	ffff                	.insn	2, 0xffff
  bc:	0004                	.insn	2, 0x0004
  be:	0004                	.insn	2, 0x0004
  c0:	7c01                	.insn	2, 0x7c01
  c2:	0c01                	.insn	2, 0x0c01
  c4:	0002                	.insn	2, 0x0002
  c6:	0000                	.insn	2, 0x0000
  c8:	000c                	.insn	2, 0x000c
  ca:	0000                	.insn	2, 0x0000
  cc:	00b4                	.insn	2, 0x00b4
  ce:	0000                	.insn	2, 0x0000
  d0:	0c94                	.insn	2, 0x0c94
  d2:	0010                	.insn	2, 0x0010
  d4:	0028                	.insn	2, 0x0028
  d6:	0000                	.insn	2, 0x0000
  d8:	000c                	.insn	2, 0x000c
  da:	0000                	.insn	2, 0x0000
  dc:	00b4                	.insn	2, 0x00b4
  de:	0000                	.insn	2, 0x0000
  e0:	0cbc                	.insn	2, 0x0cbc
  e2:	0010                	.insn	2, 0x0010
  e4:	0030                	.insn	2, 0x0030
  e6:	0000                	.insn	2, 0x0000
  e8:	000c                	.insn	2, 0x000c
  ea:	0000                	.insn	2, 0x0000
  ec:	00b4                	.insn	2, 0x00b4
  ee:	0000                	.insn	2, 0x0000
  f0:	0cec                	.insn	2, 0x0cec
  f2:	0010                	.insn	2, 0x0010
  f4:	0020                	.insn	2, 0x0020
  f6:	0000                	.insn	2, 0x0000
  f8:	002c                	.insn	2, 0x002c
  fa:	0000                	.insn	2, 0x0000
  fc:	00b4                	.insn	2, 0x00b4
  fe:	0000                	.insn	2, 0x0000
 100:	0d0c                	.insn	2, 0x0d0c
 102:	0010                	.insn	2, 0x0010
 104:	00f8                	.insn	2, 0x00f8
 106:	0000                	.insn	2, 0x0000
 108:	0e44                	.insn	2, 0x0e44
 10a:	5020                	.insn	2, 0x5020
 10c:	0181                	.insn	2, 0x0181
 10e:	0288                	.insn	2, 0x0288
 110:	0389                	.insn	2, 0x0389
 112:	0492                	.insn	2, 0x0492
 114:	5c0a                	.insn	2, 0x5c0a
 116:	c8c1                	.insn	2, 0xc8c1
 118:	d2c9                	.insn	2, 0xd2c9
 11a:	0e44                	.insn	2, 0x0e44
 11c:	4800                	.insn	2, 0x4800
 11e:	c1b4020b          	.insn	4, 0xc1b4020b
 122:	c9c8                	.insn	2, 0xc9c8
 124:	44d2                	.insn	2, 0x44d2
 126:	000e                	.insn	2, 0x000e
 128:	0040                	.insn	2, 0x0040
 12a:	0000                	.insn	2, 0x0000
 12c:	00b4                	.insn	2, 0x00b4
 12e:	0000                	.insn	2, 0x0000
 130:	0e04                	.insn	2, 0x0e04
 132:	0010                	.insn	2, 0x0010
 134:	02cc                	.insn	2, 0x02cc
 136:	0000                	.insn	2, 0x0000
 138:	0e44                	.insn	2, 0x0e44
 13a:	7470                	.insn	2, 0x7470
 13c:	0981                	.insn	2, 0x0981
 13e:	0a88                	.insn	2, 0x0a88
 140:	0b89                	.insn	2, 0x0b89
 142:	0c92                	.insn	2, 0x0c92
 144:	0e940d93          	addi	s11,s0,233
 148:	0f95                	.insn	2, 0x0f95
 14a:	1096                	.insn	2, 0x1096
 14c:	12981197          	auipc	gp,0x12981
 150:	1399                	.insn	2, 0x1399
 152:	149a                	.insn	2, 0x149a
 154:	8c03159b          	.insn	4, 0x8c03159b
 158:	c102                	.insn	2, 0xc102
 15a:	c9c8                	.insn	2, 0xc9c8
 15c:	d3d2                	.insn	2, 0xd3d2
 15e:	d5d4                	.insn	2, 0xd5d4
 160:	d7d6                	.insn	2, 0xd7d6
 162:	d9d8                	.insn	2, 0xd9d8
 164:	dbda                	.insn	2, 0xdbda
 166:	0e44                	.insn	2, 0x0e44
 168:	0000                	.insn	2, 0x0000
 16a:	0000                	.insn	2, 0x0000
 16c:	000c                	.insn	2, 0x000c
 16e:	0000                	.insn	2, 0x0000
 170:	00b4                	.insn	2, 0x00b4
 172:	0000                	.insn	2, 0x0000
 174:	10d0                	.insn	2, 0x10d0
 176:	0010                	.insn	2, 0x0010
 178:	00c4                	.insn	2, 0x00c4
 17a:	0000                	.insn	2, 0x0000
 17c:	0040                	.insn	2, 0x0040
 17e:	0000                	.insn	2, 0x0000
 180:	00b4                	.insn	2, 0x00b4
 182:	0000                	.insn	2, 0x0000
 184:	1194                	.insn	2, 0x1194
 186:	0010                	.insn	2, 0x0010
 188:	0270                	.insn	2, 0x0270
 18a:	0000                	.insn	2, 0x0000
 18c:	0e48                	.insn	2, 0x0e48
 18e:	7440                	.insn	2, 0x7440
 190:	0181                	.insn	2, 0x0181
 192:	0288                	.insn	2, 0x0288
 194:	0389                	.insn	2, 0x0389
 196:	0492                	.insn	2, 0x0492
 198:	06940593          	addi	a1,s0,105
 19c:	0795                	.insn	2, 0x0795
 19e:	0896                	.insn	2, 0x0896
 1a0:	0a980997          	auipc	s3,0xa980
 1a4:	0b99                	.insn	2, 0x0b99
 1a6:	0c9a                	.insn	2, 0x0c9a
 1a8:	2c030d9b          	.insn	4, 0x2c030d9b
 1ac:	c102                	.insn	2, 0xc102
 1ae:	c9c8                	.insn	2, 0xc9c8
 1b0:	d3d2                	.insn	2, 0xd3d2
 1b2:	d5d4                	.insn	2, 0xd5d4
 1b4:	d7d6                	.insn	2, 0xd7d6
 1b6:	d9d8                	.insn	2, 0xd9d8
 1b8:	dbda                	.insn	2, 0xdbda
 1ba:	0e44                	.insn	2, 0x0e44
 1bc:	0000                	.insn	2, 0x0000
 1be:	0000                	.insn	2, 0x0000
 1c0:	0028                	.insn	2, 0x0028
 1c2:	0000                	.insn	2, 0x0000
 1c4:	00b4                	.insn	2, 0x00b4
 1c6:	0000                	.insn	2, 0x0000
 1c8:	1404                	.insn	2, 0x1404
 1ca:	0010                	.insn	2, 0x0010
 1cc:	0224                	.insn	2, 0x0224
 1ce:	0000                	.insn	2, 0x0000
 1d0:	0e44                	.insn	2, 0x0e44
 1d2:	4810                	.insn	2, 0x4810
 1d4:	0181                	.insn	2, 0x0181
 1d6:	0288                	.insn	2, 0x0288
 1d8:	020a                	.insn	2, 0x020a
 1da:	c1f4                	.insn	2, 0xc1f4
 1dc:	44c8                	.insn	2, 0x44c8
 1de:	000e                	.insn	2, 0x000e
 1e0:	0b48                	.insn	2, 0x0b48
 1e2:	c1010c03          	lb	s8,-1008(sp)
 1e6:	44c8                	.insn	2, 0x44c8
 1e8:	000e                	.insn	2, 0x000e
 1ea:	0000                	.insn	2, 0x0000
 1ec:	0010                	.insn	2, 0x0010
 1ee:	0000                	.insn	2, 0x0000
 1f0:	ffff                	.insn	2, 0xffff
 1f2:	ffff                	.insn	2, 0xffff
 1f4:	0004                	.insn	2, 0x0004
 1f6:	0004                	.insn	2, 0x0004
 1f8:	7c01                	.insn	2, 0x7c01
 1fa:	0c01                	.insn	2, 0x0c01
 1fc:	0002                	.insn	2, 0x0002
 1fe:	0000                	.insn	2, 0x0000
 200:	000c                	.insn	2, 0x000c
 202:	0000                	.insn	2, 0x0000
 204:	01ec                	.insn	2, 0x01ec
 206:	0000                	.insn	2, 0x0000
 208:	1628                	.insn	2, 0x1628
 20a:	0010                	.insn	2, 0x0010
 20c:	0008                	.insn	2, 0x0008
 20e:	0000                	.insn	2, 0x0000
 210:	000c                	.insn	2, 0x000c
 212:	0000                	.insn	2, 0x0000
 214:	01ec                	.insn	2, 0x01ec
 216:	0000                	.insn	2, 0x0000
 218:	1630                	.insn	2, 0x1630
 21a:	0010                	.insn	2, 0x0010
 21c:	01c0                	.insn	2, 0x01c0
 21e:	0000                	.insn	2, 0x0000
 220:	002c                	.insn	2, 0x002c
 222:	0000                	.insn	2, 0x0000
 224:	01ec                	.insn	2, 0x01ec
 226:	0000                	.insn	2, 0x0000
 228:	17f0                	.insn	2, 0x17f0
 22a:	0010                	.insn	2, 0x0010
 22c:	0250                	.insn	2, 0x0250
 22e:	0000                	.insn	2, 0x0000
 230:	0e44                	.insn	2, 0x0e44
 232:	04a0                	.insn	2, 0x04a0
 234:	8158                	.insn	2, 0x8158
 236:	8801                	.insn	2, 0x8801
 238:	8902                	.insn	2, 0x8902
 23a:	93049203          	lh	tp,-1744(s1)
 23e:	9405                	.insn	2, 0x9405
 240:	0306                	.insn	2, 0x0306
 242:	022c                	.insn	2, 0x022c
 244:	c8c1                	.insn	2, 0xc8c1
 246:	d2c9                	.insn	2, 0xd2c9
 248:	0e44d4d3          	.insn	4, 0x0e44d4d3
 24c:	0000                	.insn	2, 0x0000
 24e:	0000                	.insn	2, 0x0000
 250:	000c                	.insn	2, 0x000c
 252:	0000                	.insn	2, 0x0000
 254:	01ec                	.insn	2, 0x01ec
 256:	0000                	.insn	2, 0x0000
 258:	1a40                	.insn	2, 0x1a40
 25a:	0010                	.insn	2, 0x0010
 25c:	018c                	.insn	2, 0x018c
 25e:	0000                	.insn	2, 0x0000
 260:	0034                	.insn	2, 0x0034
 262:	0000                	.insn	2, 0x0000
 264:	01ec                	.insn	2, 0x01ec
 266:	0000                	.insn	2, 0x0000
 268:	1bcc                	.insn	2, 0x1bcc
 26a:	0010                	.insn	2, 0x0010
 26c:	0238                	.insn	2, 0x0238
 26e:	0000                	.insn	2, 0x0000
 270:	0e44                	.insn	2, 0x0e44
 272:	04b0                	.insn	2, 0x04b0
 274:	8164                	.insn	2, 0x8164
 276:	8801                	.insn	2, 0x8801
 278:	8902                	.insn	2, 0x8902
 27a:	93049203          	lh	tp,-1744(s1)
 27e:	9405                	.insn	2, 0x9405
 280:	9506                	.insn	2, 0x9506
 282:	97089607          	.insn	4, 0x97089607
 286:	0309                	.insn	2, 0x0309
 288:	0208                	.insn	2, 0x0208
 28a:	c8c1                	.insn	2, 0xc8c1
 28c:	d2c9                	.insn	2, 0xd2c9
 28e:	d6d5d4d3          	.insn	4, 0xd6d5d4d3
 292:	000e44d7          	.insn	4, 0x000e44d7
 296:	0000                	.insn	2, 0x0000
 298:	0024                	.insn	2, 0x0024
 29a:	0000                	.insn	2, 0x0000
 29c:	01ec                	.insn	2, 0x01ec
 29e:	0000                	.insn	2, 0x0000
 2a0:	1e04                	.insn	2, 0x1e04
 2a2:	0010                	.insn	2, 0x0010
 2a4:	00e8                	.insn	2, 0x00e8
 2a6:	0000                	.insn	2, 0x0000
 2a8:	0e44                	.insn	2, 0x0e44
 2aa:	5010                	.insn	2, 0x5010
 2ac:	0181                	.insn	2, 0x0181
 2ae:	0288                	.insn	2, 0x0288
 2b0:	0389                	.insn	2, 0x0389
 2b2:	0492                	.insn	2, 0x0492
 2b4:	cc02                	.insn	2, 0xcc02
 2b6:	c8c1                	.insn	2, 0xc8c1
 2b8:	d2c9                	.insn	2, 0xd2c9
 2ba:	0e44                	.insn	2, 0x0e44
 2bc:	0000                	.insn	2, 0x0000
 2be:	0000                	.insn	2, 0x0000
 2c0:	0010                	.insn	2, 0x0010
 2c2:	0000                	.insn	2, 0x0000
 2c4:	ffff                	.insn	2, 0xffff
 2c6:	ffff                	.insn	2, 0xffff
 2c8:	0004                	.insn	2, 0x0004
 2ca:	0004                	.insn	2, 0x0004
 2cc:	7c01                	.insn	2, 0x7c01
 2ce:	0c01                	.insn	2, 0x0c01
 2d0:	0002                	.insn	2, 0x0002
 2d2:	0000                	.insn	2, 0x0000
 2d4:	001c                	.insn	2, 0x001c
 2d6:	0000                	.insn	2, 0x0000
 2d8:	02c0                	.insn	2, 0x02c0
 2da:	0000                	.insn	2, 0x0000
 2dc:	1eec                	.insn	2, 0x1eec
 2de:	0010                	.insn	2, 0x0010
 2e0:	005c                	.insn	2, 0x005c
 2e2:	0000                	.insn	2, 0x0000
 2e4:	0e44                	.insn	2, 0x0e44
 2e6:	4810                	.insn	2, 0x4810
 2e8:	0181                	.insn	2, 0x0181
 2ea:	0288                	.insn	2, 0x0288
 2ec:	4802                	.insn	2, 0x4802
 2ee:	c8c1                	.insn	2, 0xc8c1
 2f0:	0e44                	.insn	2, 0x0e44
 2f2:	0000                	.insn	2, 0x0000
 2f4:	0030                	.insn	2, 0x0030
 2f6:	0000                	.insn	2, 0x0000
 2f8:	02c0                	.insn	2, 0x02c0
 2fa:	0000                	.insn	2, 0x0000
 2fc:	1f48                	.insn	2, 0x1f48
 2fe:	0010                	.insn	2, 0x0010
 300:	043c                	.insn	2, 0x043c
 302:	0000                	.insn	2, 0x0000
 304:	0e44                	.insn	2, 0x0e44
 306:	5c20                	.insn	2, 0x5c20
 308:	0181                	.insn	2, 0x0181
 30a:	0288                	.insn	2, 0x0288
 30c:	0389                	.insn	2, 0x0389
 30e:	0492                	.insn	2, 0x0492
 310:	06940593          	addi	a1,s0,105
 314:	0795                	.insn	2, 0x0795
 316:	020a                	.insn	2, 0x020a
 318:	c18c                	.insn	2, 0xc18c
 31a:	c9c8                	.insn	2, 0xc9c8
 31c:	d3d2                	.insn	2, 0xd3d2
 31e:	d5d4                	.insn	2, 0xd5d4
 320:	0e44                	.insn	2, 0x0e44
 322:	4400                	.insn	2, 0x4400
 324:	0000000b          	.insn	4, 0x000b
 328:	000c                	.insn	2, 0x000c
 32a:	0000                	.insn	2, 0x0000
 32c:	02c0                	.insn	2, 0x02c0
 32e:	0000                	.insn	2, 0x0000
 330:	2384                	.insn	2, 0x2384
 332:	0010                	.insn	2, 0x0010
 334:	0094                	.insn	2, 0x0094
 336:	0000                	.insn	2, 0x0000
 338:	0024                	.insn	2, 0x0024
 33a:	0000                	.insn	2, 0x0000
 33c:	02c0                	.insn	2, 0x02c0
 33e:	0000                	.insn	2, 0x0000
 340:	2418                	.insn	2, 0x2418
 342:	0010                	.insn	2, 0x0010
 344:	009c                	.insn	2, 0x009c
 346:	0000                	.insn	2, 0x0000
 348:	0e44                	.insn	2, 0x0e44
 34a:	5010                	.insn	2, 0x5010
 34c:	0181                	.insn	2, 0x0181
 34e:	0288                	.insn	2, 0x0288
 350:	0389                	.insn	2, 0x0389
 352:	0492                	.insn	2, 0x0492
 354:	8002                	.insn	2, 0x8002
 356:	c8c1                	.insn	2, 0xc8c1
 358:	d2c9                	.insn	2, 0xd2c9
 35a:	0e44                	.insn	2, 0x0e44
 35c:	0000                	.insn	2, 0x0000
 35e:	0000                	.insn	2, 0x0000
 360:	0044                	.insn	2, 0x0044
 362:	0000                	.insn	2, 0x0000
 364:	02c0                	.insn	2, 0x02c0
 366:	0000                	.insn	2, 0x0000
 368:	24b4                	.insn	2, 0x24b4
 36a:	0010                	.insn	2, 0x0010
 36c:	0480                	.insn	2, 0x0480
 36e:	0000                	.insn	2, 0x0000
 370:	0e44                	.insn	2, 0x0e44
 372:	0180                	.insn	2, 0x0180
 374:	8174                	.insn	2, 0x8174
 376:	8801                	.insn	2, 0x8801
 378:	8902                	.insn	2, 0x8902
 37a:	93049203          	lh	tp,-1744(s1)
 37e:	9405                	.insn	2, 0x9405
 380:	9506                	.insn	2, 0x9506
 382:	97089607          	.insn	4, 0x97089607
 386:	9809                	.insn	2, 0x9809
 388:	990a                	.insn	2, 0x990a
 38a:	9b0c9a0b          	.insn	4, 0x9b0c9a0b
 38e:	0a0d                	.insn	2, 0x0a0d
 390:	c103bc03          	.insn	4, 0xc103bc03
 394:	c9c8                	.insn	2, 0xc9c8
 396:	d3d2                	.insn	2, 0xd3d2
 398:	d5d4                	.insn	2, 0xd5d4
 39a:	d7d6                	.insn	2, 0xd7d6
 39c:	d9d8                	.insn	2, 0xd9d8
 39e:	dbda                	.insn	2, 0xdbda
 3a0:	0e44                	.insn	2, 0x0e44
 3a2:	4400                	.insn	2, 0x4400
 3a4:	0000000b          	.insn	4, 0x000b
 3a8:	0040                	.insn	2, 0x0040
 3aa:	0000                	.insn	2, 0x0000
 3ac:	02c0                	.insn	2, 0x02c0
 3ae:	0000                	.insn	2, 0x0000
 3b0:	2934                	.insn	2, 0x2934
 3b2:	0010                	.insn	2, 0x0010
 3b4:	0414                	.insn	2, 0x0414
 3b6:	0000                	.insn	2, 0x0000
 3b8:	0e44                	.insn	2, 0x0e44
 3ba:	7450                	.insn	2, 0x7450
 3bc:	0181                	.insn	2, 0x0181
 3be:	0288                	.insn	2, 0x0288
 3c0:	0389                	.insn	2, 0x0389
 3c2:	0492                	.insn	2, 0x0492
 3c4:	06940593          	addi	a1,s0,105
 3c8:	0795                	.insn	2, 0x0795
 3ca:	0896                	.insn	2, 0x0896
 3cc:	0a980997          	auipc	s3,0xa980
 3d0:	0b99                	.insn	2, 0x0b99
 3d2:	0c9a                	.insn	2, 0x0c9a
 3d4:	020a0d9b          	.insn	4, 0x020a0d9b
 3d8:	c180                	.insn	2, 0xc180
 3da:	c9c8                	.insn	2, 0xc9c8
 3dc:	d3d2                	.insn	2, 0xd3d2
 3de:	d5d4                	.insn	2, 0xd5d4
 3e0:	d7d6                	.insn	2, 0xd7d6
 3e2:	d9d8                	.insn	2, 0xd9d8
 3e4:	dbda                	.insn	2, 0xdbda
 3e6:	0e44                	.insn	2, 0x0e44
 3e8:	4400                	.insn	2, 0x4400
 3ea:	0040000b          	.insn	4, 0x0040000b
 3ee:	0000                	.insn	2, 0x0000
 3f0:	02c0                	.insn	2, 0x02c0
 3f2:	0000                	.insn	2, 0x0000
 3f4:	2d48                	.insn	2, 0x2d48
 3f6:	0010                	.insn	2, 0x0010
 3f8:	0404                	.insn	2, 0x0404
 3fa:	0000                	.insn	2, 0x0000
 3fc:	0e44                	.insn	2, 0x0e44
 3fe:	7450                	.insn	2, 0x7450
 400:	0181                	.insn	2, 0x0181
 402:	0288                	.insn	2, 0x0288
 404:	0389                	.insn	2, 0x0389
 406:	0492                	.insn	2, 0x0492
 408:	06940593          	addi	a1,s0,105
 40c:	0795                	.insn	2, 0x0795
 40e:	0896                	.insn	2, 0x0896
 410:	0a980997          	auipc	s3,0xa980
 414:	0b99                	.insn	2, 0x0b99
 416:	0c9a                	.insn	2, 0x0c9a
 418:	020a0d9b          	.insn	4, 0x020a0d9b
 41c:	c184                	.insn	2, 0xc184
 41e:	c9c8                	.insn	2, 0xc9c8
 420:	d3d2                	.insn	2, 0xd3d2
 422:	d5d4                	.insn	2, 0xd5d4
 424:	d7d6                	.insn	2, 0xd7d6
 426:	d9d8                	.insn	2, 0xd9d8
 428:	dbda                	.insn	2, 0xdbda
 42a:	0e44                	.insn	2, 0x0e44
 42c:	4400                	.insn	2, 0x4400
 42e:	000b                	.short	0x000b
