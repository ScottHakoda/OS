
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
    80000004:	07813103          	ld	sp,120(sp) # 80001078 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000028:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <cons+0xffffffff7fff575f>
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
    8000008c:	088000ef          	jal	ra,80000114 <consoleinit>
    // printfinit();
    printf("\n");
    80000090:	00001517          	auipc	a0,0x1
    80000094:	f9850513          	addi	a0,a0,-104 # 80001028 <strlen+0x976>
    80000098:	1d0000ef          	jal	ra,80000268 <printf>
    printf("xv6 kernel is booting\n");
    8000009c:	00001517          	auipc	a0,0x1
    800000a0:	f6450513          	addi	a0,a0,-156 # 80001000 <strlen+0x94e>
    800000a4:	1c4000ef          	jal	ra,80000268 <printf>
    printf("in minimal mode!\n");
    800000a8:	00001517          	auipc	a0,0x1
    800000ac:	f7050513          	addi	a0,a0,-144 # 80001018 <strlen+0x966>
    800000b0:	1b8000ef          	jal	ra,80000268 <printf>
    printf("\n");
    800000b4:	00001517          	auipc	a0,0x1
    800000b8:	f7450513          	addi	a0,a0,-140 # 80001028 <strlen+0x976>
    800000bc:	1ac000ef          	jal	ra,80000268 <printf>
    // binit();         // buffer cache
    // iinit();         // inode table
    // fileinit();      // file table
    // virtio_disk_init(); // emulated hard disk
    // userinit();      // first user process
    __sync_synchronize();
    800000c0:	0ff0000f          	fence
    started = 1;
    800000c4:	4785                	li	a5,1
    800000c6:	00001717          	auipc	a4,0x1
    800000ca:	fcf72523          	sw	a5,-54(a4) # 80001090 <started>
    // kvminithart();    // turn on paging
    // trapinithart();   // install kernel trap vector
    // plicinithart();   // ask PLIC for device interrupts
  }

  printf("Hello World!\n");
    800000ce:	00001517          	auipc	a0,0x1
    800000d2:	f6250513          	addi	a0,a0,-158 # 80001030 <strlen+0x97e>
    800000d6:	192000ef          	jal	ra,80000268 <printf>

}
    800000da:	60a2                	ld	ra,8(sp)
    800000dc:	6402                	ld	s0,0(sp)
    800000de:	0141                	addi	sp,sp,16
    800000e0:	8082                	ret

00000000800000e2 <consputc>:
// called by printf(), and to echo input characters,
// but not from write().
//
void
consputc(int c)
{
    800000e2:	1141                	addi	sp,sp,-16
    800000e4:	e406                	sd	ra,8(sp)
    800000e6:	e022                	sd	s0,0(sp)
    800000e8:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    800000ea:	10000793          	li	a5,256
    800000ee:	00f50863          	beq	a0,a5,800000fe <consputc+0x1c>
    // if the user typed backspace, overwrite with a space.
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    uartputc_sync(c);
    800000f2:	09a000ef          	jal	ra,8000018c <uartputc_sync>
  }
}
    800000f6:	60a2                	ld	ra,8(sp)
    800000f8:	6402                	ld	s0,0(sp)
    800000fa:	0141                	addi	sp,sp,16
    800000fc:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800000fe:	4521                	li	a0,8
    80000100:	08c000ef          	jal	ra,8000018c <uartputc_sync>
    80000104:	02000513          	li	a0,32
    80000108:	084000ef          	jal	ra,8000018c <uartputc_sync>
    8000010c:	4521                	li	a0,8
    8000010e:	07e000ef          	jal	ra,8000018c <uartputc_sync>
    80000112:	b7d5                	j	800000f6 <consputc+0x14>

0000000080000114 <consoleinit>:
//   release(&cons.lock);
// }

void
consoleinit(void)
{
    80000114:	1141                	addi	sp,sp,-16
    80000116:	e406                	sd	ra,8(sp)
    80000118:	e022                	sd	s0,0(sp)
    8000011a:	0800                	addi	s0,sp,16
  // initlock(&cons.lock, "cons");

  uartinit();
    8000011c:	00c000ef          	jal	ra,80000128 <uartinit>

  // // connect read and write system calls
  // // to consoleread and consolewrite.
  // devsw[CONSOLE].read = consoleread;
  // devsw[CONSOLE].write = consolewrite;
}
    80000120:	60a2                	ld	ra,8(sp)
    80000122:	6402                	ld	s0,0(sp)
    80000124:	0141                	addi	sp,sp,16
    80000126:	8082                	ret

0000000080000128 <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    80000128:	1141                	addi	sp,sp,-16
    8000012a:	e422                	sd	s0,8(sp)
    8000012c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000012e:	100007b7          	lui	a5,0x10000
    80000132:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000136:	f8000713          	li	a4,-128
    8000013a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000013e:	470d                	li	a4,3
    80000140:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000144:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000148:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000014c:	469d                	li	a3,7
    8000014e:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000152:	00e780a3          	sb	a4,1(a5)

  // initlock(&tx_lock, "uart");
}
    80000156:	6422                	ld	s0,8(sp)
    80000158:	0141                	addi	sp,sp,16
    8000015a:	8082                	ret

000000008000015c <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    8000015c:	1141                	addi	sp,sp,-16
    8000015e:	e422                	sd	s0,8(sp)
    80000160:	0800                	addi	s0,sp,16
  // acquire(&tx_lock);

  int i = 0;
  while(i < n){ 
    80000162:	02b05263          	blez	a1,80000186 <uartwrite+0x2a>
    80000166:	87aa                	mv	a5,a0
    80000168:	0505                	addi	a0,a0,1
    8000016a:	35fd                	addiw	a1,a1,-1
    8000016c:	1582                	slli	a1,a1,0x20
    8000016e:	9181                	srli	a1,a1,0x20
    80000170:	00b506b3          	add	a3,a0,a1
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      // sleep(&tx_chan, &tx_lock);
    // }   
      
    WriteReg(THR, buf[i]);
    80000174:	10000637          	lui	a2,0x10000
    80000178:	0007c703          	lbu	a4,0(a5)
    8000017c:	00e60023          	sb	a4,0(a2) # 10000000 <_entry-0x70000000>
  while(i < n){ 
    80000180:	0785                	addi	a5,a5,1
    80000182:	fed79be3          	bne	a5,a3,80000178 <uartwrite+0x1c>
    i += 1;
    // tx_busy = 1;
  }

  // release(&tx_lock);
}
    80000186:	6422                	ld	s0,8(sp)
    80000188:	0141                	addi	sp,sp,16
    8000018a:	8082                	ret

000000008000018c <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000018c:	1141                	addi	sp,sp,-16
    8000018e:	e422                	sd	s0,8(sp)
    80000190:	0800                	addi	s0,sp,16
  //   for(;;)
  //     ;
  // }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000192:	10000737          	lui	a4,0x10000
    80000196:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000019a:	0207f793          	andi	a5,a5,32
    8000019e:	dfe5                	beqz	a5,80000196 <uartputc_sync+0xa>
    ;
  WriteReg(THR, c);
    800001a0:	0ff57513          	zext.b	a0,a0
    800001a4:	100007b7          	lui	a5,0x10000
    800001a8:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  // if(panicking == 0)
  //   pop_off();
}
    800001ac:	6422                	ld	s0,8(sp)
    800001ae:	0141                	addi	sp,sp,16
    800001b0:	8082                	ret

00000000800001b2 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800001b2:	1141                	addi	sp,sp,-16
    800001b4:	e422                	sd	s0,8(sp)
    800001b6:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    800001b8:	100007b7          	lui	a5,0x10000
    800001bc:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800001c0:	8b85                	andi	a5,a5,1
    800001c2:	cb81                	beqz	a5,800001d2 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800001c4:	100007b7          	lui	a5,0x10000
    800001c8:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800001cc:	6422                	ld	s0,8(sp)
    800001ce:	0141                	addi	sp,sp,16
    800001d0:	8082                	ret
    return -1;
    800001d2:	557d                	li	a0,-1
    800001d4:	bfe5                	j	800001cc <uartgetc+0x1a>

00000000800001d6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    800001d6:	7139                	addi	sp,sp,-64
    800001d8:	fc06                	sd	ra,56(sp)
    800001da:	f822                	sd	s0,48(sp)
    800001dc:	f426                	sd	s1,40(sp)
    800001de:	f04a                	sd	s2,32(sp)
    800001e0:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    800001e2:	c219                	beqz	a2,800001e8 <printint+0x12>
    800001e4:	06054e63          	bltz	a0,80000260 <printint+0x8a>
    x = -xx;
  else
    x = xx;
    800001e8:	4881                	li	a7,0
    800001ea:	fc840693          	addi	a3,s0,-56

  i = 0;
    800001ee:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    800001f0:	00001617          	auipc	a2,0x1
    800001f4:	e6860613          	addi	a2,a2,-408 # 80001058 <digits>
    800001f8:	883e                	mv	a6,a5
    800001fa:	2785                	addiw	a5,a5,1
    800001fc:	02b57733          	remu	a4,a0,a1
    80000200:	9732                	add	a4,a4,a2
    80000202:	00074703          	lbu	a4,0(a4)
    80000206:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    8000020a:	872a                	mv	a4,a0
    8000020c:	02b55533          	divu	a0,a0,a1
    80000210:	0685                	addi	a3,a3,1
    80000212:	feb773e3          	bgeu	a4,a1,800001f8 <printint+0x22>

  if(sign)
    80000216:	00088a63          	beqz	a7,8000022a <printint+0x54>
    buf[i++] = '-';
    8000021a:	1781                	addi	a5,a5,-32
    8000021c:	97a2                	add	a5,a5,s0
    8000021e:	02d00713          	li	a4,45
    80000222:	fee78423          	sb	a4,-24(a5)
    80000226:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    8000022a:	02f05563          	blez	a5,80000254 <printint+0x7e>
    8000022e:	fc840713          	addi	a4,s0,-56
    80000232:	00f704b3          	add	s1,a4,a5
    80000236:	fff70913          	addi	s2,a4,-1
    8000023a:	993e                	add	s2,s2,a5
    8000023c:	37fd                	addiw	a5,a5,-1
    8000023e:	1782                	slli	a5,a5,0x20
    80000240:	9381                	srli	a5,a5,0x20
    80000242:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    80000246:	fff4c503          	lbu	a0,-1(s1)
    8000024a:	e99ff0ef          	jal	ra,800000e2 <consputc>
  while(--i >= 0)
    8000024e:	14fd                	addi	s1,s1,-1
    80000250:	ff249be3          	bne	s1,s2,80000246 <printint+0x70>
}
    80000254:	70e2                	ld	ra,56(sp)
    80000256:	7442                	ld	s0,48(sp)
    80000258:	74a2                	ld	s1,40(sp)
    8000025a:	7902                	ld	s2,32(sp)
    8000025c:	6121                	addi	sp,sp,64
    8000025e:	8082                	ret
    x = -xx;
    80000260:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    80000264:	4885                	li	a7,1
    x = -xx;
    80000266:	b751                	j	800001ea <printint+0x14>

0000000080000268 <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    80000268:	7131                	addi	sp,sp,-192
    8000026a:	fc86                	sd	ra,120(sp)
    8000026c:	f8a2                	sd	s0,112(sp)
    8000026e:	f4a6                	sd	s1,104(sp)
    80000270:	f0ca                	sd	s2,96(sp)
    80000272:	ecce                	sd	s3,88(sp)
    80000274:	e8d2                	sd	s4,80(sp)
    80000276:	e4d6                	sd	s5,72(sp)
    80000278:	e0da                	sd	s6,64(sp)
    8000027a:	fc5e                	sd	s7,56(sp)
    8000027c:	f862                	sd	s8,48(sp)
    8000027e:	f466                	sd	s9,40(sp)
    80000280:	f06a                	sd	s10,32(sp)
    80000282:	ec6e                	sd	s11,24(sp)
    80000284:	0100                	addi	s0,sp,128
    80000286:	8a2a                	mv	s4,a0
    80000288:	e40c                	sd	a1,8(s0)
    8000028a:	e810                	sd	a2,16(s0)
    8000028c:	ec14                	sd	a3,24(s0)
    8000028e:	f018                	sd	a4,32(s0)
    80000290:	f41c                	sd	a5,40(s0)
    80000292:	03043823          	sd	a6,48(s0)
    80000296:	03143c23          	sd	a7,56(s0)
  char *s;

  // if(panicking == 0)
  //   acquire(&pr.lock);

  va_start(ap, fmt);
    8000029a:	00840793          	addi	a5,s0,8
    8000029e:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    800002a2:	00054503          	lbu	a0,0(a0)
    800002a6:	22050c63          	beqz	a0,800004de <printf+0x276>
    800002aa:	4981                	li	s3,0
    if(cx != '%'){
    800002ac:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    800002b0:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    800002b4:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    800002b8:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    800002bc:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    800002c0:	07000d93          	li	s11,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800002c4:	00001b97          	auipc	s7,0x1
    800002c8:	d94b8b93          	addi	s7,s7,-620 # 80001058 <digits>
    800002cc:	a821                	j	800002e4 <printf+0x7c>
      consputc(cx);
    800002ce:	e15ff0ef          	jal	ra,800000e2 <consputc>
      continue;
    800002d2:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    800002d4:	0014899b          	addiw	s3,s1,1
    800002d8:	013a07b3          	add	a5,s4,s3
    800002dc:	0007c503          	lbu	a0,0(a5)
    800002e0:	1e050f63          	beqz	a0,800004de <printf+0x276>
    if(cx != '%'){
    800002e4:	ff5515e3          	bne	a0,s5,800002ce <printf+0x66>
    i++;
    800002e8:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    800002ec:	009a07b3          	add	a5,s4,s1
    800002f0:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    800002f4:	1e090563          	beqz	s2,800004de <printf+0x276>
    800002f8:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    800002fc:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    800002fe:	c789                	beqz	a5,80000308 <printf+0xa0>
    80000300:	009a0733          	add	a4,s4,s1
    80000304:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    80000308:	03690863          	beq	s2,s6,80000338 <printf+0xd0>
    } else if(c0 == 'l' && c1 == 'd'){
    8000030c:	05890263          	beq	s2,s8,80000350 <printf+0xe8>
    } else if(c0 == 'u'){
    80000310:	0d990163          	beq	s2,s9,800003d2 <printf+0x16a>
    } else if(c0 == 'x'){
    80000314:	11a90863          	beq	s2,s10,80000424 <printf+0x1bc>
    } else if(c0 == 'p'){
    80000318:	15b90163          	beq	s2,s11,8000045a <printf+0x1f2>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    8000031c:	06300793          	li	a5,99
    80000320:	16f90963          	beq	s2,a5,80000492 <printf+0x22a>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    80000324:	07300793          	li	a5,115
    80000328:	16f90f63          	beq	s2,a5,800004a6 <printf+0x23e>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    8000032c:	03591c63          	bne	s2,s5,80000364 <printf+0xfc>
      consputc('%');
    80000330:	8556                	mv	a0,s5
    80000332:	db1ff0ef          	jal	ra,800000e2 <consputc>
    80000336:	bf79                	j	800002d4 <printf+0x6c>
      printint(va_arg(ap, int), 10, 1);
    80000338:	f8843783          	ld	a5,-120(s0)
    8000033c:	00878713          	addi	a4,a5,8
    80000340:	f8e43423          	sd	a4,-120(s0)
    80000344:	4605                	li	a2,1
    80000346:	45a9                	li	a1,10
    80000348:	4388                	lw	a0,0(a5)
    8000034a:	e8dff0ef          	jal	ra,800001d6 <printint>
    8000034e:	b759                	j	800002d4 <printf+0x6c>
    } else if(c0 == 'l' && c1 == 'd'){
    80000350:	03678163          	beq	a5,s6,80000372 <printf+0x10a>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    80000354:	03878d63          	beq	a5,s8,8000038e <printf+0x126>
    } else if(c0 == 'l' && c1 == 'u'){
    80000358:	09978a63          	beq	a5,s9,800003ec <printf+0x184>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    8000035c:	03878b63          	beq	a5,s8,80000392 <printf+0x12a>
    } else if(c0 == 'l' && c1 == 'x'){
    80000360:	0da78f63          	beq	a5,s10,8000043e <printf+0x1d6>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    80000364:	8556                	mv	a0,s5
    80000366:	d7dff0ef          	jal	ra,800000e2 <consputc>
      consputc(c0);
    8000036a:	854a                	mv	a0,s2
    8000036c:	d77ff0ef          	jal	ra,800000e2 <consputc>
    80000370:	b795                	j	800002d4 <printf+0x6c>
      printint(va_arg(ap, uint64), 10, 1);
    80000372:	f8843783          	ld	a5,-120(s0)
    80000376:	00878713          	addi	a4,a5,8
    8000037a:	f8e43423          	sd	a4,-120(s0)
    8000037e:	4605                	li	a2,1
    80000380:	45a9                	li	a1,10
    80000382:	6388                	ld	a0,0(a5)
    80000384:	e53ff0ef          	jal	ra,800001d6 <printint>
      i += 1;
    80000388:	0029849b          	addiw	s1,s3,2
    8000038c:	b7a1                	j	800002d4 <printf+0x6c>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    8000038e:	03668463          	beq	a3,s6,800003b6 <printf+0x14e>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000392:	07968b63          	beq	a3,s9,80000408 <printf+0x1a0>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    80000396:	fda697e3          	bne	a3,s10,80000364 <printf+0xfc>
      printint(va_arg(ap, uint64), 16, 0);
    8000039a:	f8843783          	ld	a5,-120(s0)
    8000039e:	00878713          	addi	a4,a5,8
    800003a2:	f8e43423          	sd	a4,-120(s0)
    800003a6:	4601                	li	a2,0
    800003a8:	45c1                	li	a1,16
    800003aa:	6388                	ld	a0,0(a5)
    800003ac:	e2bff0ef          	jal	ra,800001d6 <printint>
      i += 2;
    800003b0:	0039849b          	addiw	s1,s3,3
    800003b4:	b705                	j	800002d4 <printf+0x6c>
      printint(va_arg(ap, uint64), 10, 1);
    800003b6:	f8843783          	ld	a5,-120(s0)
    800003ba:	00878713          	addi	a4,a5,8
    800003be:	f8e43423          	sd	a4,-120(s0)
    800003c2:	4605                	li	a2,1
    800003c4:	45a9                	li	a1,10
    800003c6:	6388                	ld	a0,0(a5)
    800003c8:	e0fff0ef          	jal	ra,800001d6 <printint>
      i += 2;
    800003cc:	0039849b          	addiw	s1,s3,3
    800003d0:	b711                	j	800002d4 <printf+0x6c>
      printint(va_arg(ap, uint32), 10, 0);
    800003d2:	f8843783          	ld	a5,-120(s0)
    800003d6:	00878713          	addi	a4,a5,8
    800003da:	f8e43423          	sd	a4,-120(s0)
    800003de:	4601                	li	a2,0
    800003e0:	45a9                	li	a1,10
    800003e2:	0007e503          	lwu	a0,0(a5)
    800003e6:	df1ff0ef          	jal	ra,800001d6 <printint>
    800003ea:	b5ed                	j	800002d4 <printf+0x6c>
      printint(va_arg(ap, uint64), 10, 0);
    800003ec:	f8843783          	ld	a5,-120(s0)
    800003f0:	00878713          	addi	a4,a5,8
    800003f4:	f8e43423          	sd	a4,-120(s0)
    800003f8:	4601                	li	a2,0
    800003fa:	45a9                	li	a1,10
    800003fc:	6388                	ld	a0,0(a5)
    800003fe:	dd9ff0ef          	jal	ra,800001d6 <printint>
      i += 1;
    80000402:	0029849b          	addiw	s1,s3,2
    80000406:	b5f9                	j	800002d4 <printf+0x6c>
      printint(va_arg(ap, uint64), 10, 0);
    80000408:	f8843783          	ld	a5,-120(s0)
    8000040c:	00878713          	addi	a4,a5,8
    80000410:	f8e43423          	sd	a4,-120(s0)
    80000414:	4601                	li	a2,0
    80000416:	45a9                	li	a1,10
    80000418:	6388                	ld	a0,0(a5)
    8000041a:	dbdff0ef          	jal	ra,800001d6 <printint>
      i += 2;
    8000041e:	0039849b          	addiw	s1,s3,3
    80000422:	bd4d                	j	800002d4 <printf+0x6c>
      printint(va_arg(ap, uint32), 16, 0);
    80000424:	f8843783          	ld	a5,-120(s0)
    80000428:	00878713          	addi	a4,a5,8
    8000042c:	f8e43423          	sd	a4,-120(s0)
    80000430:	4601                	li	a2,0
    80000432:	45c1                	li	a1,16
    80000434:	0007e503          	lwu	a0,0(a5)
    80000438:	d9fff0ef          	jal	ra,800001d6 <printint>
    8000043c:	bd61                	j	800002d4 <printf+0x6c>
      printint(va_arg(ap, uint64), 16, 0);
    8000043e:	f8843783          	ld	a5,-120(s0)
    80000442:	00878713          	addi	a4,a5,8
    80000446:	f8e43423          	sd	a4,-120(s0)
    8000044a:	4601                	li	a2,0
    8000044c:	45c1                	li	a1,16
    8000044e:	6388                	ld	a0,0(a5)
    80000450:	d87ff0ef          	jal	ra,800001d6 <printint>
      i += 1;
    80000454:	0029849b          	addiw	s1,s3,2
    80000458:	bdb5                	j	800002d4 <printf+0x6c>
      printptr(va_arg(ap, uint64));
    8000045a:	f8843783          	ld	a5,-120(s0)
    8000045e:	00878713          	addi	a4,a5,8
    80000462:	f8e43423          	sd	a4,-120(s0)
    80000466:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000046a:	03000513          	li	a0,48
    8000046e:	c75ff0ef          	jal	ra,800000e2 <consputc>
  consputc('x');
    80000472:	856a                	mv	a0,s10
    80000474:	c6fff0ef          	jal	ra,800000e2 <consputc>
    80000478:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000047a:	03c9d793          	srli	a5,s3,0x3c
    8000047e:	97de                	add	a5,a5,s7
    80000480:	0007c503          	lbu	a0,0(a5)
    80000484:	c5fff0ef          	jal	ra,800000e2 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000488:	0992                	slli	s3,s3,0x4
    8000048a:	397d                	addiw	s2,s2,-1
    8000048c:	fe0917e3          	bnez	s2,8000047a <printf+0x212>
    80000490:	b591                	j	800002d4 <printf+0x6c>
      consputc(va_arg(ap, uint));
    80000492:	f8843783          	ld	a5,-120(s0)
    80000496:	00878713          	addi	a4,a5,8
    8000049a:	f8e43423          	sd	a4,-120(s0)
    8000049e:	4388                	lw	a0,0(a5)
    800004a0:	c43ff0ef          	jal	ra,800000e2 <consputc>
    800004a4:	bd05                	j	800002d4 <printf+0x6c>
      if((s = va_arg(ap, char*)) == 0)
    800004a6:	f8843783          	ld	a5,-120(s0)
    800004aa:	00878713          	addi	a4,a5,8
    800004ae:	f8e43423          	sd	a4,-120(s0)
    800004b2:	0007b903          	ld	s2,0(a5)
    800004b6:	00090d63          	beqz	s2,800004d0 <printf+0x268>
      for(; *s; s++)
    800004ba:	00094503          	lbu	a0,0(s2)
    800004be:	e0050be3          	beqz	a0,800002d4 <printf+0x6c>
        consputc(*s);
    800004c2:	c21ff0ef          	jal	ra,800000e2 <consputc>
      for(; *s; s++)
    800004c6:	0905                	addi	s2,s2,1
    800004c8:	00094503          	lbu	a0,0(s2)
    800004cc:	f97d                	bnez	a0,800004c2 <printf+0x25a>
    800004ce:	b519                	j	800002d4 <printf+0x6c>
        s = "(null)";
    800004d0:	00001917          	auipc	s2,0x1
    800004d4:	b7090913          	addi	s2,s2,-1168 # 80001040 <strlen+0x98e>
      for(; *s; s++)
    800004d8:	02800513          	li	a0,40
    800004dc:	b7dd                	j	800004c2 <printf+0x25a>

  // if(panicking == 0)
  //   release(&pr.lock);

  return 0;
}
    800004de:	4501                	li	a0,0
    800004e0:	70e6                	ld	ra,120(sp)
    800004e2:	7446                	ld	s0,112(sp)
    800004e4:	74a6                	ld	s1,104(sp)
    800004e6:	7906                	ld	s2,96(sp)
    800004e8:	69e6                	ld	s3,88(sp)
    800004ea:	6a46                	ld	s4,80(sp)
    800004ec:	6aa6                	ld	s5,72(sp)
    800004ee:	6b06                	ld	s6,64(sp)
    800004f0:	7be2                	ld	s7,56(sp)
    800004f2:	7c42                	ld	s8,48(sp)
    800004f4:	7ca2                	ld	s9,40(sp)
    800004f6:	7d02                	ld	s10,32(sp)
    800004f8:	6de2                	ld	s11,24(sp)
    800004fa:	6129                	addi	sp,sp,192
    800004fc:	8082                	ret

00000000800004fe <panic>:

void
panic(char *s)
{
    800004fe:	1101                	addi	sp,sp,-32
    80000500:	ec06                	sd	ra,24(sp)
    80000502:	e822                	sd	s0,16(sp)
    80000504:	e426                	sd	s1,8(sp)
    80000506:	e04a                	sd	s2,0(sp)
    80000508:	1000                	addi	s0,sp,32
    8000050a:	84aa                	mv	s1,a0
  panicking = 1;
    8000050c:	4905                	li	s2,1
    8000050e:	00001797          	auipc	a5,0x1
    80000512:	b927a523          	sw	s2,-1142(a5) # 80001098 <panicking>
  printf("panic: ");
    80000516:	00001517          	auipc	a0,0x1
    8000051a:	b3250513          	addi	a0,a0,-1230 # 80001048 <strlen+0x996>
    8000051e:	d4bff0ef          	jal	ra,80000268 <printf>
  printf("%s\n", s);
    80000522:	85a6                	mv	a1,s1
    80000524:	00001517          	auipc	a0,0x1
    80000528:	b2c50513          	addi	a0,a0,-1236 # 80001050 <strlen+0x99e>
    8000052c:	d3dff0ef          	jal	ra,80000268 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000530:	00001797          	auipc	a5,0x1
    80000534:	b727a223          	sw	s2,-1180(a5) # 80001094 <panicked>
  for(;;)
    80000538:	a001                	j	80000538 <panic+0x3a>

000000008000053a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    8000053a:	1141                	addi	sp,sp,-16
    8000053c:	e422                	sd	s0,8(sp)
    8000053e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000540:	ca19                	beqz	a2,80000556 <memset+0x1c>
    80000542:	87aa                	mv	a5,a0
    80000544:	1602                	slli	a2,a2,0x20
    80000546:	9201                	srli	a2,a2,0x20
    80000548:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    8000054c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000550:	0785                	addi	a5,a5,1
    80000552:	fee79de3          	bne	a5,a4,8000054c <memset+0x12>
  }
  return dst;
}
    80000556:	6422                	ld	s0,8(sp)
    80000558:	0141                	addi	sp,sp,16
    8000055a:	8082                	ret

000000008000055c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    8000055c:	1141                	addi	sp,sp,-16
    8000055e:	e422                	sd	s0,8(sp)
    80000560:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000562:	ca05                	beqz	a2,80000592 <memcmp+0x36>
    80000564:	fff6069b          	addiw	a3,a2,-1
    80000568:	1682                	slli	a3,a3,0x20
    8000056a:	9281                	srli	a3,a3,0x20
    8000056c:	0685                	addi	a3,a3,1
    8000056e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000570:	00054783          	lbu	a5,0(a0)
    80000574:	0005c703          	lbu	a4,0(a1)
    80000578:	00e79863          	bne	a5,a4,80000588 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    8000057c:	0505                	addi	a0,a0,1
    8000057e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000580:	fed518e3          	bne	a0,a3,80000570 <memcmp+0x14>
  }

  return 0;
    80000584:	4501                	li	a0,0
    80000586:	a019                	j	8000058c <memcmp+0x30>
      return *s1 - *s2;
    80000588:	40e7853b          	subw	a0,a5,a4
}
    8000058c:	6422                	ld	s0,8(sp)
    8000058e:	0141                	addi	sp,sp,16
    80000590:	8082                	ret
  return 0;
    80000592:	4501                	li	a0,0
    80000594:	bfe5                	j	8000058c <memcmp+0x30>

0000000080000596 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000596:	1141                	addi	sp,sp,-16
    80000598:	e422                	sd	s0,8(sp)
    8000059a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    8000059c:	c205                	beqz	a2,800005bc <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    8000059e:	02a5e263          	bltu	a1,a0,800005c2 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    800005a2:	1602                	slli	a2,a2,0x20
    800005a4:	9201                	srli	a2,a2,0x20
    800005a6:	00c587b3          	add	a5,a1,a2
{
    800005aa:	872a                	mv	a4,a0
      *d++ = *s++;
    800005ac:	0585                	addi	a1,a1,1
    800005ae:	0705                	addi	a4,a4,1
    800005b0:	fff5c683          	lbu	a3,-1(a1)
    800005b4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    800005b8:	fef59ae3          	bne	a1,a5,800005ac <memmove+0x16>

  return dst;
}
    800005bc:	6422                	ld	s0,8(sp)
    800005be:	0141                	addi	sp,sp,16
    800005c0:	8082                	ret
  if(s < d && s + n > d){
    800005c2:	02061693          	slli	a3,a2,0x20
    800005c6:	9281                	srli	a3,a3,0x20
    800005c8:	00d58733          	add	a4,a1,a3
    800005cc:	fce57be3          	bgeu	a0,a4,800005a2 <memmove+0xc>
    d += n;
    800005d0:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    800005d2:	fff6079b          	addiw	a5,a2,-1
    800005d6:	1782                	slli	a5,a5,0x20
    800005d8:	9381                	srli	a5,a5,0x20
    800005da:	fff7c793          	not	a5,a5
    800005de:	97ba                	add	a5,a5,a4
      *--d = *--s;
    800005e0:	177d                	addi	a4,a4,-1
    800005e2:	16fd                	addi	a3,a3,-1
    800005e4:	00074603          	lbu	a2,0(a4)
    800005e8:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    800005ec:	fee79ae3          	bne	a5,a4,800005e0 <memmove+0x4a>
    800005f0:	b7f1                	j	800005bc <memmove+0x26>

00000000800005f2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    800005f2:	1141                	addi	sp,sp,-16
    800005f4:	e406                	sd	ra,8(sp)
    800005f6:	e022                	sd	s0,0(sp)
    800005f8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    800005fa:	f9dff0ef          	jal	ra,80000596 <memmove>
}
    800005fe:	60a2                	ld	ra,8(sp)
    80000600:	6402                	ld	s0,0(sp)
    80000602:	0141                	addi	sp,sp,16
    80000604:	8082                	ret

0000000080000606 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000606:	1141                	addi	sp,sp,-16
    80000608:	e422                	sd	s0,8(sp)
    8000060a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    8000060c:	ce11                	beqz	a2,80000628 <strncmp+0x22>
    8000060e:	00054783          	lbu	a5,0(a0)
    80000612:	cf89                	beqz	a5,8000062c <strncmp+0x26>
    80000614:	0005c703          	lbu	a4,0(a1)
    80000618:	00f71a63          	bne	a4,a5,8000062c <strncmp+0x26>
    n--, p++, q++;
    8000061c:	367d                	addiw	a2,a2,-1
    8000061e:	0505                	addi	a0,a0,1
    80000620:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000622:	f675                	bnez	a2,8000060e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000624:	4501                	li	a0,0
    80000626:	a809                	j	80000638 <strncmp+0x32>
    80000628:	4501                	li	a0,0
    8000062a:	a039                	j	80000638 <strncmp+0x32>
  if(n == 0)
    8000062c:	ca09                	beqz	a2,8000063e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    8000062e:	00054503          	lbu	a0,0(a0)
    80000632:	0005c783          	lbu	a5,0(a1)
    80000636:	9d1d                	subw	a0,a0,a5
}
    80000638:	6422                	ld	s0,8(sp)
    8000063a:	0141                	addi	sp,sp,16
    8000063c:	8082                	ret
    return 0;
    8000063e:	4501                	li	a0,0
    80000640:	bfe5                	j	80000638 <strncmp+0x32>

0000000080000642 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000642:	1141                	addi	sp,sp,-16
    80000644:	e422                	sd	s0,8(sp)
    80000646:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000648:	872a                	mv	a4,a0
    8000064a:	8832                	mv	a6,a2
    8000064c:	367d                	addiw	a2,a2,-1
    8000064e:	01005963          	blez	a6,80000660 <strncpy+0x1e>
    80000652:	0705                	addi	a4,a4,1
    80000654:	0005c783          	lbu	a5,0(a1)
    80000658:	fef70fa3          	sb	a5,-1(a4)
    8000065c:	0585                	addi	a1,a1,1
    8000065e:	f7f5                	bnez	a5,8000064a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000660:	86ba                	mv	a3,a4
    80000662:	00c05c63          	blez	a2,8000067a <strncpy+0x38>
    *s++ = 0;
    80000666:	0685                	addi	a3,a3,1
    80000668:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    8000066c:	40d707bb          	subw	a5,a4,a3
    80000670:	37fd                	addiw	a5,a5,-1
    80000672:	010787bb          	addw	a5,a5,a6
    80000676:	fef048e3          	bgtz	a5,80000666 <strncpy+0x24>
  return os;
}
    8000067a:	6422                	ld	s0,8(sp)
    8000067c:	0141                	addi	sp,sp,16
    8000067e:	8082                	ret

0000000080000680 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000680:	1141                	addi	sp,sp,-16
    80000682:	e422                	sd	s0,8(sp)
    80000684:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000686:	02c05363          	blez	a2,800006ac <safestrcpy+0x2c>
    8000068a:	fff6069b          	addiw	a3,a2,-1
    8000068e:	1682                	slli	a3,a3,0x20
    80000690:	9281                	srli	a3,a3,0x20
    80000692:	96ae                	add	a3,a3,a1
    80000694:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000696:	00d58963          	beq	a1,a3,800006a8 <safestrcpy+0x28>
    8000069a:	0585                	addi	a1,a1,1
    8000069c:	0785                	addi	a5,a5,1
    8000069e:	fff5c703          	lbu	a4,-1(a1)
    800006a2:	fee78fa3          	sb	a4,-1(a5)
    800006a6:	fb65                	bnez	a4,80000696 <safestrcpy+0x16>
    ;
  *s = 0;
    800006a8:	00078023          	sb	zero,0(a5)
  return os;
}
    800006ac:	6422                	ld	s0,8(sp)
    800006ae:	0141                	addi	sp,sp,16
    800006b0:	8082                	ret

00000000800006b2 <strlen>:

int
strlen(const char *s)
{
    800006b2:	1141                	addi	sp,sp,-16
    800006b4:	e422                	sd	s0,8(sp)
    800006b6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    800006b8:	00054783          	lbu	a5,0(a0)
    800006bc:	cf91                	beqz	a5,800006d8 <strlen+0x26>
    800006be:	0505                	addi	a0,a0,1
    800006c0:	87aa                	mv	a5,a0
    800006c2:	4685                	li	a3,1
    800006c4:	9e89                	subw	a3,a3,a0
    800006c6:	00f6853b          	addw	a0,a3,a5
    800006ca:	0785                	addi	a5,a5,1
    800006cc:	fff7c703          	lbu	a4,-1(a5)
    800006d0:	fb7d                	bnez	a4,800006c6 <strlen+0x14>
    ;
  return n;
}
    800006d2:	6422                	ld	s0,8(sp)
    800006d4:	0141                	addi	sp,sp,16
    800006d6:	8082                	ret
  for(n = 0; s[n]; n++)
    800006d8:	4501                	li	a0,0
    800006da:	bfe5                	j	800006d2 <strlen+0x20>
	...
