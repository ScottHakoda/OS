
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	00001117          	auipc	sp,0x1
    80000004:	06813103          	ld	sp,104(sp) # 80001068 <_GLOBAL_OFFSET_TABLE_+0x8>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
        csrr a1, mhartid
    8000000a:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    8000000e:	0585                	addi	a1,a1,1
        mul a0, a0, a1
    80000010:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000014:	912a                	add	sp,sp,a0
        # jump to start() in start.c
        call start
    80000016:	006000ef          	jal	ra,8000001c <start>

000000008000001a <spin>:
spin:
        j spin
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <start>:
__attribute__ ((aligned (16))) char stack0[4096 * NCPU];

// entry.S jumps here in machine mode on stack0.
void
start()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16

static inline uint64
r_mstatus()
{
  uint64 x;
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000022:	300027f3          	csrr	a5,mstatus
  // set M Previous Privilege mode to Supervisor, for mret.
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
    80000026:	7779                	lui	a4,0xffffe
    80000028:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <cons+0xffffffff7fff576f>
    8000002c:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000002e:	6705                	lui	a4,0x1
    80000030:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80000034:	8fd9                	or	a5,a5,a4
}

static inline void 
w_mstatus(uint64 x)
{
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000036:	30079073          	csrw	mstatus,a5
// instruction address to which a return from
// exception will go.
static inline void 
w_mepc(uint64 x)
{
  asm volatile("csrw mepc, %0" : : "r" (x));
    8000003a:	00000797          	auipc	a5,0x0
    8000003e:	04a78793          	addi	a5,a5,74 # 80000084 <main>
    80000042:	34179073          	csrw	mepc,a5
// supervisor address translation and protection;
// holds the address of the page table.
static inline void 
w_satp(uint64 x)
{
  asm volatile("csrw satp, %0" : : "r" (x));
    80000046:	4781                	li	a5,0
    80000048:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    8000004c:	67c1                	lui	a5,0x10
    8000004e:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    80000050:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    80000054:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000058:	104027f3          	csrr	a5,sie
  w_satp(0);

  // delegate all interrupts and exceptions to supervisor mode.
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    8000005c:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    80000060:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    80000064:	57fd                	li	a5,-1
    80000066:	83a9                	srli	a5,a5,0xa
    80000068:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    8000006c:	47bd                	li	a5,15
    8000006e:	3a079073          	csrw	pmpcfg0,a5
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000072:	f14027f3          	csrr	a5,mhartid
  // // ask for clock interrupts.
  // timerinit();

  // keep each CPU's hartid in its tp register, for cpuid().
  int id = r_mhartid();
  w_tp(id);
    80000076:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    80000078:	823e                	mv	tp,a5

  // switch to supervisor mode and jump to main().
  asm volatile("mret");
    8000007a:	30200073          	mret
}
    8000007e:	6422                	ld	s0,8(sp)
    80000080:	0141                	addi	sp,sp,16
    80000082:	8082                	ret

0000000080000084 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000084:	1141                	addi	sp,sp,-16
    80000086:	e406                	sd	ra,8(sp)
    80000088:	e022                	sd	s0,0(sp)
    8000008a:	0800                	addi	s0,sp,16
  if(0 == 0){
    consoleinit();
    8000008c:	07c000ef          	jal	ra,80000108 <consoleinit>
    // printfinit();
    printf("\n");
    80000090:	00001517          	auipc	a0,0x1
    80000094:	f7050513          	addi	a0,a0,-144 # 80001000 <strlen+0x95a>
    80000098:	1c4000ef          	jal	ra,8000025c <printf>
    printf("xv6 kernel is booting\n");
    8000009c:	00001517          	auipc	a0,0x1
    800000a0:	f6c50513          	addi	a0,a0,-148 # 80001008 <strlen+0x962>
    800000a4:	1b8000ef          	jal	ra,8000025c <printf>
    printf("\n");
    800000a8:	00001517          	auipc	a0,0x1
    800000ac:	f5850513          	addi	a0,a0,-168 # 80001000 <strlen+0x95a>
    800000b0:	1ac000ef          	jal	ra,8000025c <printf>
    // binit();         // buffer cache
    // iinit();         // inode table
    // fileinit();      // file table
    // virtio_disk_init(); // emulated hard disk
    // userinit();      // first user process
    __sync_synchronize();
    800000b4:	0ff0000f          	fence
    started = 1;
    800000b8:	4785                	li	a5,1
    800000ba:	00001717          	auipc	a4,0x1
    800000be:	fcf72323          	sw	a5,-58(a4) # 80001080 <started>
    // kvminithart();    // turn on paging
    // trapinithart();   // install kernel trap vector
    // plicinithart();   // ask PLIC for device interrupts
  }

  printf("Hello World!\n");
    800000c2:	00001517          	auipc	a0,0x1
    800000c6:	f5e50513          	addi	a0,a0,-162 # 80001020 <strlen+0x97a>
    800000ca:	192000ef          	jal	ra,8000025c <printf>

}
    800000ce:	60a2                	ld	ra,8(sp)
    800000d0:	6402                	ld	s0,0(sp)
    800000d2:	0141                	addi	sp,sp,16
    800000d4:	8082                	ret

00000000800000d6 <consputc>:
// called by printf(), and to echo input characters,
// but not from write().
//
void
consputc(int c)
{
    800000d6:	1141                	addi	sp,sp,-16
    800000d8:	e406                	sd	ra,8(sp)
    800000da:	e022                	sd	s0,0(sp)
    800000dc:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    800000de:	10000793          	li	a5,256
    800000e2:	00f50863          	beq	a0,a5,800000f2 <consputc+0x1c>
    // if the user typed backspace, overwrite with a space.
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    uartputc_sync(c);
    800000e6:	09a000ef          	jal	ra,80000180 <uartputc_sync>
  }
}
    800000ea:	60a2                	ld	ra,8(sp)
    800000ec:	6402                	ld	s0,0(sp)
    800000ee:	0141                	addi	sp,sp,16
    800000f0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800000f2:	4521                	li	a0,8
    800000f4:	08c000ef          	jal	ra,80000180 <uartputc_sync>
    800000f8:	02000513          	li	a0,32
    800000fc:	084000ef          	jal	ra,80000180 <uartputc_sync>
    80000100:	4521                	li	a0,8
    80000102:	07e000ef          	jal	ra,80000180 <uartputc_sync>
    80000106:	b7d5                	j	800000ea <consputc+0x14>

0000000080000108 <consoleinit>:
//   release(&cons.lock);
// }

void
consoleinit(void)
{
    80000108:	1141                	addi	sp,sp,-16
    8000010a:	e406                	sd	ra,8(sp)
    8000010c:	e022                	sd	s0,0(sp)
    8000010e:	0800                	addi	s0,sp,16
  // initlock(&cons.lock, "cons");

  uartinit();
    80000110:	00c000ef          	jal	ra,8000011c <uartinit>

  // // connect read and write system calls
  // // to consoleread and consolewrite.
  // devsw[CONSOLE].read = consoleread;
  // devsw[CONSOLE].write = consolewrite;
}
    80000114:	60a2                	ld	ra,8(sp)
    80000116:	6402                	ld	s0,0(sp)
    80000118:	0141                	addi	sp,sp,16
    8000011a:	8082                	ret

000000008000011c <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    8000011c:	1141                	addi	sp,sp,-16
    8000011e:	e422                	sd	s0,8(sp)
    80000120:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000122:	100007b7          	lui	a5,0x10000
    80000126:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000012a:	f8000713          	li	a4,-128
    8000012e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000132:	470d                	li	a4,3
    80000134:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000138:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000013c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000140:	469d                	li	a3,7
    80000142:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000146:	00e780a3          	sb	a4,1(a5)

  // initlock(&tx_lock, "uart");
}
    8000014a:	6422                	ld	s0,8(sp)
    8000014c:	0141                	addi	sp,sp,16
    8000014e:	8082                	ret

0000000080000150 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000150:	1141                	addi	sp,sp,-16
    80000152:	e422                	sd	s0,8(sp)
    80000154:	0800                	addi	s0,sp,16
  // acquire(&tx_lock);

  int i = 0;
  while(i < n){ 
    80000156:	02b05263          	blez	a1,8000017a <uartwrite+0x2a>
    8000015a:	87aa                	mv	a5,a0
    8000015c:	0505                	addi	a0,a0,1
    8000015e:	35fd                	addiw	a1,a1,-1
    80000160:	1582                	slli	a1,a1,0x20
    80000162:	9181                	srli	a1,a1,0x20
    80000164:	00b506b3          	add	a3,a0,a1
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      // sleep(&tx_chan, &tx_lock);
    // }   
      
    WriteReg(THR, buf[i]);
    80000168:	10000637          	lui	a2,0x10000
    8000016c:	0007c703          	lbu	a4,0(a5)
    80000170:	00e60023          	sb	a4,0(a2) # 10000000 <_entry-0x70000000>
  while(i < n){ 
    80000174:	0785                	addi	a5,a5,1
    80000176:	fed79be3          	bne	a5,a3,8000016c <uartwrite+0x1c>
    i += 1;
    // tx_busy = 1;
  }

  // release(&tx_lock);
}
    8000017a:	6422                	ld	s0,8(sp)
    8000017c:	0141                	addi	sp,sp,16
    8000017e:	8082                	ret

0000000080000180 <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000180:	1141                	addi	sp,sp,-16
    80000182:	e422                	sd	s0,8(sp)
    80000184:	0800                	addi	s0,sp,16
  //   for(;;)
  //     ;
  // }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000186:	10000737          	lui	a4,0x10000
    8000018a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000018e:	0207f793          	andi	a5,a5,32
    80000192:	dfe5                	beqz	a5,8000018a <uartputc_sync+0xa>
    ;
  WriteReg(THR, c);
    80000194:	0ff57513          	zext.b	a0,a0
    80000198:	100007b7          	lui	a5,0x10000
    8000019c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  // if(panicking == 0)
  //   pop_off();
}
    800001a0:	6422                	ld	s0,8(sp)
    800001a2:	0141                	addi	sp,sp,16
    800001a4:	8082                	ret

00000000800001a6 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800001a6:	1141                	addi	sp,sp,-16
    800001a8:	e422                	sd	s0,8(sp)
    800001aa:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    800001ac:	100007b7          	lui	a5,0x10000
    800001b0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800001b4:	8b85                	andi	a5,a5,1
    800001b6:	cb81                	beqz	a5,800001c6 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800001b8:	100007b7          	lui	a5,0x10000
    800001bc:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800001c0:	6422                	ld	s0,8(sp)
    800001c2:	0141                	addi	sp,sp,16
    800001c4:	8082                	ret
    return -1;
    800001c6:	557d                	li	a0,-1
    800001c8:	bfe5                	j	800001c0 <uartgetc+0x1a>

00000000800001ca <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    800001ca:	7139                	addi	sp,sp,-64
    800001cc:	fc06                	sd	ra,56(sp)
    800001ce:	f822                	sd	s0,48(sp)
    800001d0:	f426                	sd	s1,40(sp)
    800001d2:	f04a                	sd	s2,32(sp)
    800001d4:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    800001d6:	c219                	beqz	a2,800001dc <printint+0x12>
    800001d8:	06054e63          	bltz	a0,80000254 <printint+0x8a>
    x = -xx;
  else
    x = xx;
    800001dc:	4881                	li	a7,0
    800001de:	fc840693          	addi	a3,s0,-56

  i = 0;
    800001e2:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    800001e4:	00001617          	auipc	a2,0x1
    800001e8:	e6460613          	addi	a2,a2,-412 # 80001048 <digits>
    800001ec:	883e                	mv	a6,a5
    800001ee:	2785                	addiw	a5,a5,1
    800001f0:	02b57733          	remu	a4,a0,a1
    800001f4:	9732                	add	a4,a4,a2
    800001f6:	00074703          	lbu	a4,0(a4)
    800001fa:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    800001fe:	872a                	mv	a4,a0
    80000200:	02b55533          	divu	a0,a0,a1
    80000204:	0685                	addi	a3,a3,1
    80000206:	feb773e3          	bgeu	a4,a1,800001ec <printint+0x22>

  if(sign)
    8000020a:	00088a63          	beqz	a7,8000021e <printint+0x54>
    buf[i++] = '-';
    8000020e:	1781                	addi	a5,a5,-32
    80000210:	97a2                	add	a5,a5,s0
    80000212:	02d00713          	li	a4,45
    80000216:	fee78423          	sb	a4,-24(a5)
    8000021a:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    8000021e:	02f05563          	blez	a5,80000248 <printint+0x7e>
    80000222:	fc840713          	addi	a4,s0,-56
    80000226:	00f704b3          	add	s1,a4,a5
    8000022a:	fff70913          	addi	s2,a4,-1
    8000022e:	993e                	add	s2,s2,a5
    80000230:	37fd                	addiw	a5,a5,-1
    80000232:	1782                	slli	a5,a5,0x20
    80000234:	9381                	srli	a5,a5,0x20
    80000236:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    8000023a:	fff4c503          	lbu	a0,-1(s1)
    8000023e:	e99ff0ef          	jal	ra,800000d6 <consputc>
  while(--i >= 0)
    80000242:	14fd                	addi	s1,s1,-1
    80000244:	ff249be3          	bne	s1,s2,8000023a <printint+0x70>
}
    80000248:	70e2                	ld	ra,56(sp)
    8000024a:	7442                	ld	s0,48(sp)
    8000024c:	74a2                	ld	s1,40(sp)
    8000024e:	7902                	ld	s2,32(sp)
    80000250:	6121                	addi	sp,sp,64
    80000252:	8082                	ret
    x = -xx;
    80000254:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    80000258:	4885                	li	a7,1
    x = -xx;
    8000025a:	b751                	j	800001de <printint+0x14>

000000008000025c <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    8000025c:	7131                	addi	sp,sp,-192
    8000025e:	fc86                	sd	ra,120(sp)
    80000260:	f8a2                	sd	s0,112(sp)
    80000262:	f4a6                	sd	s1,104(sp)
    80000264:	f0ca                	sd	s2,96(sp)
    80000266:	ecce                	sd	s3,88(sp)
    80000268:	e8d2                	sd	s4,80(sp)
    8000026a:	e4d6                	sd	s5,72(sp)
    8000026c:	e0da                	sd	s6,64(sp)
    8000026e:	fc5e                	sd	s7,56(sp)
    80000270:	f862                	sd	s8,48(sp)
    80000272:	f466                	sd	s9,40(sp)
    80000274:	f06a                	sd	s10,32(sp)
    80000276:	ec6e                	sd	s11,24(sp)
    80000278:	0100                	addi	s0,sp,128
    8000027a:	8a2a                	mv	s4,a0
    8000027c:	e40c                	sd	a1,8(s0)
    8000027e:	e810                	sd	a2,16(s0)
    80000280:	ec14                	sd	a3,24(s0)
    80000282:	f018                	sd	a4,32(s0)
    80000284:	f41c                	sd	a5,40(s0)
    80000286:	03043823          	sd	a6,48(s0)
    8000028a:	03143c23          	sd	a7,56(s0)
  char *s;

  // if(panicking == 0)
  //   acquire(&pr.lock);

  va_start(ap, fmt);
    8000028e:	00840793          	addi	a5,s0,8
    80000292:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000296:	00054503          	lbu	a0,0(a0)
    8000029a:	22050c63          	beqz	a0,800004d2 <printf+0x276>
    8000029e:	4981                	li	s3,0
    if(cx != '%'){
    800002a0:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    800002a4:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    800002a8:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    800002ac:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    800002b0:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    800002b4:	07000d93          	li	s11,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800002b8:	00001b97          	auipc	s7,0x1
    800002bc:	d90b8b93          	addi	s7,s7,-624 # 80001048 <digits>
    800002c0:	a821                	j	800002d8 <printf+0x7c>
      consputc(cx);
    800002c2:	e15ff0ef          	jal	ra,800000d6 <consputc>
      continue;
    800002c6:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    800002c8:	0014899b          	addiw	s3,s1,1
    800002cc:	013a07b3          	add	a5,s4,s3
    800002d0:	0007c503          	lbu	a0,0(a5)
    800002d4:	1e050f63          	beqz	a0,800004d2 <printf+0x276>
    if(cx != '%'){
    800002d8:	ff5515e3          	bne	a0,s5,800002c2 <printf+0x66>
    i++;
    800002dc:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    800002e0:	009a07b3          	add	a5,s4,s1
    800002e4:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    800002e8:	1e090563          	beqz	s2,800004d2 <printf+0x276>
    800002ec:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    800002f0:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    800002f2:	c789                	beqz	a5,800002fc <printf+0xa0>
    800002f4:	009a0733          	add	a4,s4,s1
    800002f8:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    800002fc:	03690863          	beq	s2,s6,8000032c <printf+0xd0>
    } else if(c0 == 'l' && c1 == 'd'){
    80000300:	05890263          	beq	s2,s8,80000344 <printf+0xe8>
    } else if(c0 == 'u'){
    80000304:	0d990163          	beq	s2,s9,800003c6 <printf+0x16a>
    } else if(c0 == 'x'){
    80000308:	11a90863          	beq	s2,s10,80000418 <printf+0x1bc>
    } else if(c0 == 'p'){
    8000030c:	15b90163          	beq	s2,s11,8000044e <printf+0x1f2>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    80000310:	06300793          	li	a5,99
    80000314:	16f90963          	beq	s2,a5,80000486 <printf+0x22a>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    80000318:	07300793          	li	a5,115
    8000031c:	16f90f63          	beq	s2,a5,8000049a <printf+0x23e>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    80000320:	03591c63          	bne	s2,s5,80000358 <printf+0xfc>
      consputc('%');
    80000324:	8556                	mv	a0,s5
    80000326:	db1ff0ef          	jal	ra,800000d6 <consputc>
    8000032a:	bf79                	j	800002c8 <printf+0x6c>
      printint(va_arg(ap, int), 10, 1);
    8000032c:	f8843783          	ld	a5,-120(s0)
    80000330:	00878713          	addi	a4,a5,8
    80000334:	f8e43423          	sd	a4,-120(s0)
    80000338:	4605                	li	a2,1
    8000033a:	45a9                	li	a1,10
    8000033c:	4388                	lw	a0,0(a5)
    8000033e:	e8dff0ef          	jal	ra,800001ca <printint>
    80000342:	b759                	j	800002c8 <printf+0x6c>
    } else if(c0 == 'l' && c1 == 'd'){
    80000344:	03678163          	beq	a5,s6,80000366 <printf+0x10a>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    80000348:	03878d63          	beq	a5,s8,80000382 <printf+0x126>
    } else if(c0 == 'l' && c1 == 'u'){
    8000034c:	09978a63          	beq	a5,s9,800003e0 <printf+0x184>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000350:	03878b63          	beq	a5,s8,80000386 <printf+0x12a>
    } else if(c0 == 'l' && c1 == 'x'){
    80000354:	0da78f63          	beq	a5,s10,80000432 <printf+0x1d6>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    80000358:	8556                	mv	a0,s5
    8000035a:	d7dff0ef          	jal	ra,800000d6 <consputc>
      consputc(c0);
    8000035e:	854a                	mv	a0,s2
    80000360:	d77ff0ef          	jal	ra,800000d6 <consputc>
    80000364:	b795                	j	800002c8 <printf+0x6c>
      printint(va_arg(ap, uint64), 10, 1);
    80000366:	f8843783          	ld	a5,-120(s0)
    8000036a:	00878713          	addi	a4,a5,8
    8000036e:	f8e43423          	sd	a4,-120(s0)
    80000372:	4605                	li	a2,1
    80000374:	45a9                	li	a1,10
    80000376:	6388                	ld	a0,0(a5)
    80000378:	e53ff0ef          	jal	ra,800001ca <printint>
      i += 1;
    8000037c:	0029849b          	addiw	s1,s3,2
    80000380:	b7a1                	j	800002c8 <printf+0x6c>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    80000382:	03668463          	beq	a3,s6,800003aa <printf+0x14e>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000386:	07968b63          	beq	a3,s9,800003fc <printf+0x1a0>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000038a:	fda697e3          	bne	a3,s10,80000358 <printf+0xfc>
      printint(va_arg(ap, uint64), 16, 0);
    8000038e:	f8843783          	ld	a5,-120(s0)
    80000392:	00878713          	addi	a4,a5,8
    80000396:	f8e43423          	sd	a4,-120(s0)
    8000039a:	4601                	li	a2,0
    8000039c:	45c1                	li	a1,16
    8000039e:	6388                	ld	a0,0(a5)
    800003a0:	e2bff0ef          	jal	ra,800001ca <printint>
      i += 2;
    800003a4:	0039849b          	addiw	s1,s3,3
    800003a8:	b705                	j	800002c8 <printf+0x6c>
      printint(va_arg(ap, uint64), 10, 1);
    800003aa:	f8843783          	ld	a5,-120(s0)
    800003ae:	00878713          	addi	a4,a5,8
    800003b2:	f8e43423          	sd	a4,-120(s0)
    800003b6:	4605                	li	a2,1
    800003b8:	45a9                	li	a1,10
    800003ba:	6388                	ld	a0,0(a5)
    800003bc:	e0fff0ef          	jal	ra,800001ca <printint>
      i += 2;
    800003c0:	0039849b          	addiw	s1,s3,3
    800003c4:	b711                	j	800002c8 <printf+0x6c>
      printint(va_arg(ap, uint32), 10, 0);
    800003c6:	f8843783          	ld	a5,-120(s0)
    800003ca:	00878713          	addi	a4,a5,8
    800003ce:	f8e43423          	sd	a4,-120(s0)
    800003d2:	4601                	li	a2,0
    800003d4:	45a9                	li	a1,10
    800003d6:	0007e503          	lwu	a0,0(a5)
    800003da:	df1ff0ef          	jal	ra,800001ca <printint>
    800003de:	b5ed                	j	800002c8 <printf+0x6c>
      printint(va_arg(ap, uint64), 10, 0);
    800003e0:	f8843783          	ld	a5,-120(s0)
    800003e4:	00878713          	addi	a4,a5,8
    800003e8:	f8e43423          	sd	a4,-120(s0)
    800003ec:	4601                	li	a2,0
    800003ee:	45a9                	li	a1,10
    800003f0:	6388                	ld	a0,0(a5)
    800003f2:	dd9ff0ef          	jal	ra,800001ca <printint>
      i += 1;
    800003f6:	0029849b          	addiw	s1,s3,2
    800003fa:	b5f9                	j	800002c8 <printf+0x6c>
      printint(va_arg(ap, uint64), 10, 0);
    800003fc:	f8843783          	ld	a5,-120(s0)
    80000400:	00878713          	addi	a4,a5,8
    80000404:	f8e43423          	sd	a4,-120(s0)
    80000408:	4601                	li	a2,0
    8000040a:	45a9                	li	a1,10
    8000040c:	6388                	ld	a0,0(a5)
    8000040e:	dbdff0ef          	jal	ra,800001ca <printint>
      i += 2;
    80000412:	0039849b          	addiw	s1,s3,3
    80000416:	bd4d                	j	800002c8 <printf+0x6c>
      printint(va_arg(ap, uint32), 16, 0);
    80000418:	f8843783          	ld	a5,-120(s0)
    8000041c:	00878713          	addi	a4,a5,8
    80000420:	f8e43423          	sd	a4,-120(s0)
    80000424:	4601                	li	a2,0
    80000426:	45c1                	li	a1,16
    80000428:	0007e503          	lwu	a0,0(a5)
    8000042c:	d9fff0ef          	jal	ra,800001ca <printint>
    80000430:	bd61                	j	800002c8 <printf+0x6c>
      printint(va_arg(ap, uint64), 16, 0);
    80000432:	f8843783          	ld	a5,-120(s0)
    80000436:	00878713          	addi	a4,a5,8
    8000043a:	f8e43423          	sd	a4,-120(s0)
    8000043e:	4601                	li	a2,0
    80000440:	45c1                	li	a1,16
    80000442:	6388                	ld	a0,0(a5)
    80000444:	d87ff0ef          	jal	ra,800001ca <printint>
      i += 1;
    80000448:	0029849b          	addiw	s1,s3,2
    8000044c:	bdb5                	j	800002c8 <printf+0x6c>
      printptr(va_arg(ap, uint64));
    8000044e:	f8843783          	ld	a5,-120(s0)
    80000452:	00878713          	addi	a4,a5,8
    80000456:	f8e43423          	sd	a4,-120(s0)
    8000045a:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000045e:	03000513          	li	a0,48
    80000462:	c75ff0ef          	jal	ra,800000d6 <consputc>
  consputc('x');
    80000466:	856a                	mv	a0,s10
    80000468:	c6fff0ef          	jal	ra,800000d6 <consputc>
    8000046c:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000046e:	03c9d793          	srli	a5,s3,0x3c
    80000472:	97de                	add	a5,a5,s7
    80000474:	0007c503          	lbu	a0,0(a5)
    80000478:	c5fff0ef          	jal	ra,800000d6 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000047c:	0992                	slli	s3,s3,0x4
    8000047e:	397d                	addiw	s2,s2,-1
    80000480:	fe0917e3          	bnez	s2,8000046e <printf+0x212>
    80000484:	b591                	j	800002c8 <printf+0x6c>
      consputc(va_arg(ap, uint));
    80000486:	f8843783          	ld	a5,-120(s0)
    8000048a:	00878713          	addi	a4,a5,8
    8000048e:	f8e43423          	sd	a4,-120(s0)
    80000492:	4388                	lw	a0,0(a5)
    80000494:	c43ff0ef          	jal	ra,800000d6 <consputc>
    80000498:	bd05                	j	800002c8 <printf+0x6c>
      if((s = va_arg(ap, char*)) == 0)
    8000049a:	f8843783          	ld	a5,-120(s0)
    8000049e:	00878713          	addi	a4,a5,8
    800004a2:	f8e43423          	sd	a4,-120(s0)
    800004a6:	0007b903          	ld	s2,0(a5)
    800004aa:	00090d63          	beqz	s2,800004c4 <printf+0x268>
      for(; *s; s++)
    800004ae:	00094503          	lbu	a0,0(s2)
    800004b2:	e0050be3          	beqz	a0,800002c8 <printf+0x6c>
        consputc(*s);
    800004b6:	c21ff0ef          	jal	ra,800000d6 <consputc>
      for(; *s; s++)
    800004ba:	0905                	addi	s2,s2,1
    800004bc:	00094503          	lbu	a0,0(s2)
    800004c0:	f97d                	bnez	a0,800004b6 <printf+0x25a>
    800004c2:	b519                	j	800002c8 <printf+0x6c>
        s = "(null)";
    800004c4:	00001917          	auipc	s2,0x1
    800004c8:	b6c90913          	addi	s2,s2,-1172 # 80001030 <strlen+0x98a>
      for(; *s; s++)
    800004cc:	02800513          	li	a0,40
    800004d0:	b7dd                	j	800004b6 <printf+0x25a>

  // if(panicking == 0)
  //   release(&pr.lock);

  return 0;
}
    800004d2:	4501                	li	a0,0
    800004d4:	70e6                	ld	ra,120(sp)
    800004d6:	7446                	ld	s0,112(sp)
    800004d8:	74a6                	ld	s1,104(sp)
    800004da:	7906                	ld	s2,96(sp)
    800004dc:	69e6                	ld	s3,88(sp)
    800004de:	6a46                	ld	s4,80(sp)
    800004e0:	6aa6                	ld	s5,72(sp)
    800004e2:	6b06                	ld	s6,64(sp)
    800004e4:	7be2                	ld	s7,56(sp)
    800004e6:	7c42                	ld	s8,48(sp)
    800004e8:	7ca2                	ld	s9,40(sp)
    800004ea:	7d02                	ld	s10,32(sp)
    800004ec:	6de2                	ld	s11,24(sp)
    800004ee:	6129                	addi	sp,sp,192
    800004f0:	8082                	ret

00000000800004f2 <panic>:

void
panic(char *s)
{
    800004f2:	1101                	addi	sp,sp,-32
    800004f4:	ec06                	sd	ra,24(sp)
    800004f6:	e822                	sd	s0,16(sp)
    800004f8:	e426                	sd	s1,8(sp)
    800004fa:	e04a                	sd	s2,0(sp)
    800004fc:	1000                	addi	s0,sp,32
    800004fe:	84aa                	mv	s1,a0
  panicking = 1;
    80000500:	4905                	li	s2,1
    80000502:	00001797          	auipc	a5,0x1
    80000506:	b927a323          	sw	s2,-1146(a5) # 80001088 <panicking>
  printf("panic: ");
    8000050a:	00001517          	auipc	a0,0x1
    8000050e:	b2e50513          	addi	a0,a0,-1234 # 80001038 <strlen+0x992>
    80000512:	d4bff0ef          	jal	ra,8000025c <printf>
  printf("%s\n", s);
    80000516:	85a6                	mv	a1,s1
    80000518:	00001517          	auipc	a0,0x1
    8000051c:	b2850513          	addi	a0,a0,-1240 # 80001040 <strlen+0x99a>
    80000520:	d3dff0ef          	jal	ra,8000025c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000524:	00001797          	auipc	a5,0x1
    80000528:	b727a023          	sw	s2,-1184(a5) # 80001084 <panicked>
  for(;;)
    8000052c:	a001                	j	8000052c <panic+0x3a>

000000008000052e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    8000052e:	1141                	addi	sp,sp,-16
    80000530:	e422                	sd	s0,8(sp)
    80000532:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000534:	ca19                	beqz	a2,8000054a <memset+0x1c>
    80000536:	87aa                	mv	a5,a0
    80000538:	1602                	slli	a2,a2,0x20
    8000053a:	9201                	srli	a2,a2,0x20
    8000053c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000540:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000544:	0785                	addi	a5,a5,1
    80000546:	fee79de3          	bne	a5,a4,80000540 <memset+0x12>
  }
  return dst;
}
    8000054a:	6422                	ld	s0,8(sp)
    8000054c:	0141                	addi	sp,sp,16
    8000054e:	8082                	ret

0000000080000550 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000550:	1141                	addi	sp,sp,-16
    80000552:	e422                	sd	s0,8(sp)
    80000554:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000556:	ca05                	beqz	a2,80000586 <memcmp+0x36>
    80000558:	fff6069b          	addiw	a3,a2,-1
    8000055c:	1682                	slli	a3,a3,0x20
    8000055e:	9281                	srli	a3,a3,0x20
    80000560:	0685                	addi	a3,a3,1
    80000562:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000564:	00054783          	lbu	a5,0(a0)
    80000568:	0005c703          	lbu	a4,0(a1)
    8000056c:	00e79863          	bne	a5,a4,8000057c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000570:	0505                	addi	a0,a0,1
    80000572:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000574:	fed518e3          	bne	a0,a3,80000564 <memcmp+0x14>
  }

  return 0;
    80000578:	4501                	li	a0,0
    8000057a:	a019                	j	80000580 <memcmp+0x30>
      return *s1 - *s2;
    8000057c:	40e7853b          	subw	a0,a5,a4
}
    80000580:	6422                	ld	s0,8(sp)
    80000582:	0141                	addi	sp,sp,16
    80000584:	8082                	ret
  return 0;
    80000586:	4501                	li	a0,0
    80000588:	bfe5                	j	80000580 <memcmp+0x30>

000000008000058a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    8000058a:	1141                	addi	sp,sp,-16
    8000058c:	e422                	sd	s0,8(sp)
    8000058e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000590:	c205                	beqz	a2,800005b0 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000592:	02a5e263          	bltu	a1,a0,800005b6 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000596:	1602                	slli	a2,a2,0x20
    80000598:	9201                	srli	a2,a2,0x20
    8000059a:	00c587b3          	add	a5,a1,a2
{
    8000059e:	872a                	mv	a4,a0
      *d++ = *s++;
    800005a0:	0585                	addi	a1,a1,1
    800005a2:	0705                	addi	a4,a4,1
    800005a4:	fff5c683          	lbu	a3,-1(a1)
    800005a8:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    800005ac:	fef59ae3          	bne	a1,a5,800005a0 <memmove+0x16>

  return dst;
}
    800005b0:	6422                	ld	s0,8(sp)
    800005b2:	0141                	addi	sp,sp,16
    800005b4:	8082                	ret
  if(s < d && s + n > d){
    800005b6:	02061693          	slli	a3,a2,0x20
    800005ba:	9281                	srli	a3,a3,0x20
    800005bc:	00d58733          	add	a4,a1,a3
    800005c0:	fce57be3          	bgeu	a0,a4,80000596 <memmove+0xc>
    d += n;
    800005c4:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    800005c6:	fff6079b          	addiw	a5,a2,-1
    800005ca:	1782                	slli	a5,a5,0x20
    800005cc:	9381                	srli	a5,a5,0x20
    800005ce:	fff7c793          	not	a5,a5
    800005d2:	97ba                	add	a5,a5,a4
      *--d = *--s;
    800005d4:	177d                	addi	a4,a4,-1
    800005d6:	16fd                	addi	a3,a3,-1
    800005d8:	00074603          	lbu	a2,0(a4)
    800005dc:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    800005e0:	fee79ae3          	bne	a5,a4,800005d4 <memmove+0x4a>
    800005e4:	b7f1                	j	800005b0 <memmove+0x26>

00000000800005e6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    800005e6:	1141                	addi	sp,sp,-16
    800005e8:	e406                	sd	ra,8(sp)
    800005ea:	e022                	sd	s0,0(sp)
    800005ec:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    800005ee:	f9dff0ef          	jal	ra,8000058a <memmove>
}
    800005f2:	60a2                	ld	ra,8(sp)
    800005f4:	6402                	ld	s0,0(sp)
    800005f6:	0141                	addi	sp,sp,16
    800005f8:	8082                	ret

00000000800005fa <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    800005fa:	1141                	addi	sp,sp,-16
    800005fc:	e422                	sd	s0,8(sp)
    800005fe:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000600:	ce11                	beqz	a2,8000061c <strncmp+0x22>
    80000602:	00054783          	lbu	a5,0(a0)
    80000606:	cf89                	beqz	a5,80000620 <strncmp+0x26>
    80000608:	0005c703          	lbu	a4,0(a1)
    8000060c:	00f71a63          	bne	a4,a5,80000620 <strncmp+0x26>
    n--, p++, q++;
    80000610:	367d                	addiw	a2,a2,-1
    80000612:	0505                	addi	a0,a0,1
    80000614:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000616:	f675                	bnez	a2,80000602 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000618:	4501                	li	a0,0
    8000061a:	a809                	j	8000062c <strncmp+0x32>
    8000061c:	4501                	li	a0,0
    8000061e:	a039                	j	8000062c <strncmp+0x32>
  if(n == 0)
    80000620:	ca09                	beqz	a2,80000632 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000622:	00054503          	lbu	a0,0(a0)
    80000626:	0005c783          	lbu	a5,0(a1)
    8000062a:	9d1d                	subw	a0,a0,a5
}
    8000062c:	6422                	ld	s0,8(sp)
    8000062e:	0141                	addi	sp,sp,16
    80000630:	8082                	ret
    return 0;
    80000632:	4501                	li	a0,0
    80000634:	bfe5                	j	8000062c <strncmp+0x32>

0000000080000636 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000636:	1141                	addi	sp,sp,-16
    80000638:	e422                	sd	s0,8(sp)
    8000063a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    8000063c:	872a                	mv	a4,a0
    8000063e:	8832                	mv	a6,a2
    80000640:	367d                	addiw	a2,a2,-1
    80000642:	01005963          	blez	a6,80000654 <strncpy+0x1e>
    80000646:	0705                	addi	a4,a4,1
    80000648:	0005c783          	lbu	a5,0(a1)
    8000064c:	fef70fa3          	sb	a5,-1(a4)
    80000650:	0585                	addi	a1,a1,1
    80000652:	f7f5                	bnez	a5,8000063e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000654:	86ba                	mv	a3,a4
    80000656:	00c05c63          	blez	a2,8000066e <strncpy+0x38>
    *s++ = 0;
    8000065a:	0685                	addi	a3,a3,1
    8000065c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000660:	40d707bb          	subw	a5,a4,a3
    80000664:	37fd                	addiw	a5,a5,-1
    80000666:	010787bb          	addw	a5,a5,a6
    8000066a:	fef048e3          	bgtz	a5,8000065a <strncpy+0x24>
  return os;
}
    8000066e:	6422                	ld	s0,8(sp)
    80000670:	0141                	addi	sp,sp,16
    80000672:	8082                	ret

0000000080000674 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000674:	1141                	addi	sp,sp,-16
    80000676:	e422                	sd	s0,8(sp)
    80000678:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    8000067a:	02c05363          	blez	a2,800006a0 <safestrcpy+0x2c>
    8000067e:	fff6069b          	addiw	a3,a2,-1
    80000682:	1682                	slli	a3,a3,0x20
    80000684:	9281                	srli	a3,a3,0x20
    80000686:	96ae                	add	a3,a3,a1
    80000688:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    8000068a:	00d58963          	beq	a1,a3,8000069c <safestrcpy+0x28>
    8000068e:	0585                	addi	a1,a1,1
    80000690:	0785                	addi	a5,a5,1
    80000692:	fff5c703          	lbu	a4,-1(a1)
    80000696:	fee78fa3          	sb	a4,-1(a5)
    8000069a:	fb65                	bnez	a4,8000068a <safestrcpy+0x16>
    ;
  *s = 0;
    8000069c:	00078023          	sb	zero,0(a5)
  return os;
}
    800006a0:	6422                	ld	s0,8(sp)
    800006a2:	0141                	addi	sp,sp,16
    800006a4:	8082                	ret

00000000800006a6 <strlen>:

int
strlen(const char *s)
{
    800006a6:	1141                	addi	sp,sp,-16
    800006a8:	e422                	sd	s0,8(sp)
    800006aa:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    800006ac:	00054783          	lbu	a5,0(a0)
    800006b0:	cf91                	beqz	a5,800006cc <strlen+0x26>
    800006b2:	0505                	addi	a0,a0,1
    800006b4:	87aa                	mv	a5,a0
    800006b6:	4685                	li	a3,1
    800006b8:	9e89                	subw	a3,a3,a0
    800006ba:	00f6853b          	addw	a0,a3,a5
    800006be:	0785                	addi	a5,a5,1
    800006c0:	fff7c703          	lbu	a4,-1(a5)
    800006c4:	fb7d                	bnez	a4,800006ba <strlen+0x14>
    ;
  return n;
}
    800006c6:	6422                	ld	s0,8(sp)
    800006c8:	0141                	addi	sp,sp,16
    800006ca:	8082                	ret
  for(n = 0; s[n]; n++)
    800006cc:	4501                	li	a0,0
    800006ce:	bfe5                	j	800006c6 <strlen+0x20>
	...
