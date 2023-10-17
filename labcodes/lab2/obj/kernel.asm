
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址，lui加载高20位进入t0，低12位为页内偏移量我们不需要
    # boot_page_table_sv39 是一个全局符号，它指向系统启动时使用的页表的开始位置
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量，这一步是得到虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号（物理地址右移12位抹除低12位后得到物理页号）
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39 39位虚拟地址模式
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    //一个按位或操作把satp的MODE字段，高1000后面全0，和三级页表的物理页号t1合并到一起
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    // satp放的是最高级页表的物理页号（44位），除此以外还有MODE字段（4位）、备用 ASID（address space identifier）16位
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    #如果不加参数的， sfence.vma 会刷新整个 TLB 。你可以在后面加上一个虚拟地址，这样 sfence.vma 只会刷新这个虚拟地址的映射
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop) // 指向一个预先定义的虚拟地址 bootstacktop，这是内核栈的顶部。
ffffffffc0200028:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	00006517          	auipc	a0,0x6
ffffffffc020003a:	fda50513          	addi	a0,a0,-38 # ffffffffc0206010 <edata>
ffffffffc020003e:	00006617          	auipc	a2,0x6
ffffffffc0200042:	43a60613          	addi	a2,a2,1082 # ffffffffc0206478 <end>
int kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	6d8010ef          	jal	ra,ffffffffc0201726 <memset>
    cons_init();  // init the console
ffffffffc0200052:	3fe000ef          	jal	ra,ffffffffc0200450 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200056:	00001517          	auipc	a0,0x1
ffffffffc020005a:	6e250513          	addi	a0,a0,1762 # ffffffffc0201738 <etext>
ffffffffc020005e:	090000ef          	jal	ra,ffffffffc02000ee <cputs>

    print_kerninfo();
ffffffffc0200062:	0dc000ef          	jal	ra,ffffffffc020013e <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table 初始化中断描述符表IDT
ffffffffc0200066:	404000ef          	jal	ra,ffffffffc020046a <idt_init>

    pmm_init();  // init physical memory management 物理内存管理
ffffffffc020006a:	795000ef          	jal	ra,ffffffffc0200ffe <pmm_init>
    pmm_init()函数需要注册缺页中断处理程序，用于处理页面访问异常。
    当程序试图访问一个不存在的页面时，CPU会触发缺页异常，此时会调用缺页中断处理程序
    该程序会在物理内存中分配一个新的页面，并将其映射到虚拟地址空间中。
    */

    idt_init();  // init interrupt descriptor table
ffffffffc020006e:	3fc000ef          	jal	ra,ffffffffc020046a <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200072:	39a000ef          	jal	ra,ffffffffc020040c <clock_init>
    clock_init()函数需要注册时钟中断处理程序，用于定时触发时钟中断。
    当时钟中断被触发时，CPU会跳转到时钟中断处理程序，该程序会更新系统时间，并执行一些周期性的操作，如调度进程等
    */
    //这两个函数都需要使用中断描述符表，所以要在中断描述符表初始化之后再初始化时钟中断

    intr_enable();  // enable irq interrupt 开启中断
ffffffffc0200076:	3e8000ef          	jal	ra,ffffffffc020045e <intr_enable>



    /* do nothing */
    while (1)
        ;
ffffffffc020007a:	a001                	j	ffffffffc020007a <kern_init+0x44>

ffffffffc020007c <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020007c:	1141                	addi	sp,sp,-16
ffffffffc020007e:	e022                	sd	s0,0(sp)
ffffffffc0200080:	e406                	sd	ra,8(sp)
ffffffffc0200082:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200084:	3ce000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200088:	401c                	lw	a5,0(s0)
}
ffffffffc020008a:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc020008c:	2785                	addiw	a5,a5,1
ffffffffc020008e:	c01c                	sw	a5,0(s0)
}
ffffffffc0200090:	6402                	ld	s0,0(sp)
ffffffffc0200092:	0141                	addi	sp,sp,16
ffffffffc0200094:	8082                	ret

ffffffffc0200096 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200096:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	86ae                	mv	a3,a1
ffffffffc020009a:	862a                	mv	a2,a0
ffffffffc020009c:	006c                	addi	a1,sp,12
ffffffffc020009e:	00000517          	auipc	a0,0x0
ffffffffc02000a2:	fde50513          	addi	a0,a0,-34 # ffffffffc020007c <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a6:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a8:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000aa:	16e010ef          	jal	ra,ffffffffc0201218 <vprintfmt>
    return cnt;
}
ffffffffc02000ae:	60e2                	ld	ra,24(sp)
ffffffffc02000b0:	4532                	lw	a0,12(sp)
ffffffffc02000b2:	6105                	addi	sp,sp,32
ffffffffc02000b4:	8082                	ret

ffffffffc02000b6 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b6:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b8:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000bc:	f42e                	sd	a1,40(sp)
ffffffffc02000be:	f832                	sd	a2,48(sp)
ffffffffc02000c0:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c2:	862a                	mv	a2,a0
ffffffffc02000c4:	004c                	addi	a1,sp,4
ffffffffc02000c6:	00000517          	auipc	a0,0x0
ffffffffc02000ca:	fb650513          	addi	a0,a0,-74 # ffffffffc020007c <cputch>
ffffffffc02000ce:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d0:	ec06                	sd	ra,24(sp)
ffffffffc02000d2:	e0ba                	sd	a4,64(sp)
ffffffffc02000d4:	e4be                	sd	a5,72(sp)
ffffffffc02000d6:	e8c2                	sd	a6,80(sp)
ffffffffc02000d8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000da:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000dc:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000de:	13a010ef          	jal	ra,ffffffffc0201218 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e2:	60e2                	ld	ra,24(sp)
ffffffffc02000e4:	4512                	lw	a0,4(sp)
ffffffffc02000e6:	6125                	addi	sp,sp,96
ffffffffc02000e8:	8082                	ret

ffffffffc02000ea <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000ea:	3680006f          	j	ffffffffc0200452 <cons_putc>

ffffffffc02000ee <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ee:	1101                	addi	sp,sp,-32
ffffffffc02000f0:	e822                	sd	s0,16(sp)
ffffffffc02000f2:	ec06                	sd	ra,24(sp)
ffffffffc02000f4:	e426                	sd	s1,8(sp)
ffffffffc02000f6:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f8:	00054503          	lbu	a0,0(a0)
ffffffffc02000fc:	c51d                	beqz	a0,ffffffffc020012a <cputs+0x3c>
ffffffffc02000fe:	0405                	addi	s0,s0,1
ffffffffc0200100:	4485                	li	s1,1
ffffffffc0200102:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200104:	34e000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0200112:	f96d                	bnez	a0,ffffffffc0200104 <cputs+0x16>
ffffffffc0200114:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200118:	4529                	li	a0,10
ffffffffc020011a:	338000ef          	jal	ra,ffffffffc0200452 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011e:	8522                	mv	a0,s0
ffffffffc0200120:	60e2                	ld	ra,24(sp)
ffffffffc0200122:	6442                	ld	s0,16(sp)
ffffffffc0200124:	64a2                	ld	s1,8(sp)
ffffffffc0200126:	6105                	addi	sp,sp,32
ffffffffc0200128:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	4405                	li	s0,1
ffffffffc020012c:	b7f5                	j	ffffffffc0200118 <cputs+0x2a>

ffffffffc020012e <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012e:	1141                	addi	sp,sp,-16
ffffffffc0200130:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200132:	328000ef          	jal	ra,ffffffffc020045a <cons_getc>
ffffffffc0200136:	dd75                	beqz	a0,ffffffffc0200132 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200138:	60a2                	ld	ra,8(sp)
ffffffffc020013a:	0141                	addi	sp,sp,16
ffffffffc020013c:	8082                	ret

ffffffffc020013e <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013e:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200140:	00001517          	auipc	a0,0x1
ffffffffc0200144:	64850513          	addi	a0,a0,1608 # ffffffffc0201788 <etext+0x50>
void print_kerninfo(void) {
ffffffffc0200148:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020014a:	f6dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014e:	00000597          	auipc	a1,0x0
ffffffffc0200152:	ee858593          	addi	a1,a1,-280 # ffffffffc0200036 <kern_init>
ffffffffc0200156:	00001517          	auipc	a0,0x1
ffffffffc020015a:	65250513          	addi	a0,a0,1618 # ffffffffc02017a8 <etext+0x70>
ffffffffc020015e:	f59ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200162:	00001597          	auipc	a1,0x1
ffffffffc0200166:	5d658593          	addi	a1,a1,1494 # ffffffffc0201738 <etext>
ffffffffc020016a:	00001517          	auipc	a0,0x1
ffffffffc020016e:	65e50513          	addi	a0,a0,1630 # ffffffffc02017c8 <etext+0x90>
ffffffffc0200172:	f45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200176:	00006597          	auipc	a1,0x6
ffffffffc020017a:	e9a58593          	addi	a1,a1,-358 # ffffffffc0206010 <edata>
ffffffffc020017e:	00001517          	auipc	a0,0x1
ffffffffc0200182:	66a50513          	addi	a0,a0,1642 # ffffffffc02017e8 <etext+0xb0>
ffffffffc0200186:	f31ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020018a:	00006597          	auipc	a1,0x6
ffffffffc020018e:	2ee58593          	addi	a1,a1,750 # ffffffffc0206478 <end>
ffffffffc0200192:	00001517          	auipc	a0,0x1
ffffffffc0200196:	67650513          	addi	a0,a0,1654 # ffffffffc0201808 <etext+0xd0>
ffffffffc020019a:	f1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019e:	00006597          	auipc	a1,0x6
ffffffffc02001a2:	6d958593          	addi	a1,a1,1753 # ffffffffc0206877 <end+0x3ff>
ffffffffc02001a6:	00000797          	auipc	a5,0x0
ffffffffc02001aa:	e9078793          	addi	a5,a5,-368 # ffffffffc0200036 <kern_init>
ffffffffc02001ae:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b2:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b6:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b8:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001bc:	95be                	add	a1,a1,a5
ffffffffc02001be:	85a9                	srai	a1,a1,0xa
ffffffffc02001c0:	00001517          	auipc	a0,0x1
ffffffffc02001c4:	66850513          	addi	a0,a0,1640 # ffffffffc0201828 <etext+0xf0>
}
ffffffffc02001c8:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ca:	eedff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02001ce <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ce:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001d0:	00001617          	auipc	a2,0x1
ffffffffc02001d4:	58860613          	addi	a2,a2,1416 # ffffffffc0201758 <etext+0x20>
ffffffffc02001d8:	04e00593          	li	a1,78
ffffffffc02001dc:	00001517          	auipc	a0,0x1
ffffffffc02001e0:	59450513          	addi	a0,a0,1428 # ffffffffc0201770 <etext+0x38>
void print_stackframe(void) {
ffffffffc02001e4:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e6:	1c6000ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02001ea <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001ea:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001ec:	00001617          	auipc	a2,0x1
ffffffffc02001f0:	74c60613          	addi	a2,a2,1868 # ffffffffc0201938 <commands+0xe0>
ffffffffc02001f4:	00001597          	auipc	a1,0x1
ffffffffc02001f8:	76458593          	addi	a1,a1,1892 # ffffffffc0201958 <commands+0x100>
ffffffffc02001fc:	00001517          	auipc	a0,0x1
ffffffffc0200200:	76450513          	addi	a0,a0,1892 # ffffffffc0201960 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200206:	eb1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020020a:	00001617          	auipc	a2,0x1
ffffffffc020020e:	76660613          	addi	a2,a2,1894 # ffffffffc0201970 <commands+0x118>
ffffffffc0200212:	00001597          	auipc	a1,0x1
ffffffffc0200216:	78658593          	addi	a1,a1,1926 # ffffffffc0201998 <commands+0x140>
ffffffffc020021a:	00001517          	auipc	a0,0x1
ffffffffc020021e:	74650513          	addi	a0,a0,1862 # ffffffffc0201960 <commands+0x108>
ffffffffc0200222:	e95ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200226:	00001617          	auipc	a2,0x1
ffffffffc020022a:	78260613          	addi	a2,a2,1922 # ffffffffc02019a8 <commands+0x150>
ffffffffc020022e:	00001597          	auipc	a1,0x1
ffffffffc0200232:	79a58593          	addi	a1,a1,1946 # ffffffffc02019c8 <commands+0x170>
ffffffffc0200236:	00001517          	auipc	a0,0x1
ffffffffc020023a:	72a50513          	addi	a0,a0,1834 # ffffffffc0201960 <commands+0x108>
ffffffffc020023e:	e79ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    }
    return 0;
}
ffffffffc0200242:	60a2                	ld	ra,8(sp)
ffffffffc0200244:	4501                	li	a0,0
ffffffffc0200246:	0141                	addi	sp,sp,16
ffffffffc0200248:	8082                	ret

ffffffffc020024a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024a:	1141                	addi	sp,sp,-16
ffffffffc020024c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020024e:	ef1ff0ef          	jal	ra,ffffffffc020013e <print_kerninfo>
    return 0;
}
ffffffffc0200252:	60a2                	ld	ra,8(sp)
ffffffffc0200254:	4501                	li	a0,0
ffffffffc0200256:	0141                	addi	sp,sp,16
ffffffffc0200258:	8082                	ret

ffffffffc020025a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025a:	1141                	addi	sp,sp,-16
ffffffffc020025c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020025e:	f71ff0ef          	jal	ra,ffffffffc02001ce <print_stackframe>
    return 0;
}
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020026a:	7115                	addi	sp,sp,-224
ffffffffc020026c:	e962                	sd	s8,144(sp)
ffffffffc020026e:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200270:	00001517          	auipc	a0,0x1
ffffffffc0200274:	63050513          	addi	a0,a0,1584 # ffffffffc02018a0 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200278:	ed86                	sd	ra,216(sp)
ffffffffc020027a:	e9a2                	sd	s0,208(sp)
ffffffffc020027c:	e5a6                	sd	s1,200(sp)
ffffffffc020027e:	e1ca                	sd	s2,192(sp)
ffffffffc0200280:	fd4e                	sd	s3,184(sp)
ffffffffc0200282:	f952                	sd	s4,176(sp)
ffffffffc0200284:	f556                	sd	s5,168(sp)
ffffffffc0200286:	f15a                	sd	s6,160(sp)
ffffffffc0200288:	ed5e                	sd	s7,152(sp)
ffffffffc020028a:	e566                	sd	s9,136(sp)
ffffffffc020028c:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020028e:	e29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200292:	00001517          	auipc	a0,0x1
ffffffffc0200296:	63650513          	addi	a0,a0,1590 # ffffffffc02018c8 <commands+0x70>
ffffffffc020029a:	e1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (tf != NULL) {
ffffffffc020029e:	000c0563          	beqz	s8,ffffffffc02002a8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a2:	8562                	mv	a0,s8
ffffffffc02002a4:	3a6000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc02002a8:	00001c97          	auipc	s9,0x1
ffffffffc02002ac:	5b0c8c93          	addi	s9,s9,1456 # ffffffffc0201858 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b0:	00001997          	auipc	s3,0x1
ffffffffc02002b4:	64098993          	addi	s3,s3,1600 # ffffffffc02018f0 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b8:	00001917          	auipc	s2,0x1
ffffffffc02002bc:	64090913          	addi	s2,s2,1600 # ffffffffc02018f8 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002c0:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c2:	00001b17          	auipc	s6,0x1
ffffffffc02002c6:	63eb0b13          	addi	s6,s6,1598 # ffffffffc0201900 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002ca:	00001a97          	auipc	s5,0x1
ffffffffc02002ce:	68ea8a93          	addi	s5,s5,1678 # ffffffffc0201958 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d2:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d4:	854e                	mv	a0,s3
ffffffffc02002d6:	2ce010ef          	jal	ra,ffffffffc02015a4 <readline>
ffffffffc02002da:	842a                	mv	s0,a0
ffffffffc02002dc:	dd65                	beqz	a0,ffffffffc02002d4 <kmonitor+0x6a>
ffffffffc02002de:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e2:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e4:	c999                	beqz	a1,ffffffffc02002fa <kmonitor+0x90>
ffffffffc02002e6:	854a                	mv	a0,s2
ffffffffc02002e8:	420010ef          	jal	ra,ffffffffc0201708 <strchr>
ffffffffc02002ec:	c925                	beqz	a0,ffffffffc020035c <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02002ee:	00144583          	lbu	a1,1(s0)
ffffffffc02002f2:	00040023          	sb	zero,0(s0)
ffffffffc02002f6:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002f8:	f5fd                	bnez	a1,ffffffffc02002e6 <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02002fa:	dce9                	beqz	s1,ffffffffc02002d4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002fc:	6582                	ld	a1,0(sp)
ffffffffc02002fe:	00001d17          	auipc	s10,0x1
ffffffffc0200302:	55ad0d13          	addi	s10,s10,1370 # ffffffffc0201858 <commands>
    if (argc == 0) {
ffffffffc0200306:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200308:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	0d61                	addi	s10,s10,24
ffffffffc020030c:	3d2010ef          	jal	ra,ffffffffc02016de <strcmp>
ffffffffc0200310:	c919                	beqz	a0,ffffffffc0200326 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200312:	2405                	addiw	s0,s0,1
ffffffffc0200314:	09740463          	beq	s0,s7,ffffffffc020039c <kmonitor+0x132>
ffffffffc0200318:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031c:	6582                	ld	a1,0(sp)
ffffffffc020031e:	0d61                	addi	s10,s10,24
ffffffffc0200320:	3be010ef          	jal	ra,ffffffffc02016de <strcmp>
ffffffffc0200324:	f57d                	bnez	a0,ffffffffc0200312 <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200326:	00141793          	slli	a5,s0,0x1
ffffffffc020032a:	97a2                	add	a5,a5,s0
ffffffffc020032c:	078e                	slli	a5,a5,0x3
ffffffffc020032e:	97e6                	add	a5,a5,s9
ffffffffc0200330:	6b9c                	ld	a5,16(a5)
ffffffffc0200332:	8662                	mv	a2,s8
ffffffffc0200334:	002c                	addi	a1,sp,8
ffffffffc0200336:	fff4851b          	addiw	a0,s1,-1
ffffffffc020033a:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020033c:	f8055ce3          	bgez	a0,ffffffffc02002d4 <kmonitor+0x6a>
}
ffffffffc0200340:	60ee                	ld	ra,216(sp)
ffffffffc0200342:	644e                	ld	s0,208(sp)
ffffffffc0200344:	64ae                	ld	s1,200(sp)
ffffffffc0200346:	690e                	ld	s2,192(sp)
ffffffffc0200348:	79ea                	ld	s3,184(sp)
ffffffffc020034a:	7a4a                	ld	s4,176(sp)
ffffffffc020034c:	7aaa                	ld	s5,168(sp)
ffffffffc020034e:	7b0a                	ld	s6,160(sp)
ffffffffc0200350:	6bea                	ld	s7,152(sp)
ffffffffc0200352:	6c4a                	ld	s8,144(sp)
ffffffffc0200354:	6caa                	ld	s9,136(sp)
ffffffffc0200356:	6d0a                	ld	s10,128(sp)
ffffffffc0200358:	612d                	addi	sp,sp,224
ffffffffc020035a:	8082                	ret
        if (*buf == '\0') {
ffffffffc020035c:	00044783          	lbu	a5,0(s0)
ffffffffc0200360:	dfc9                	beqz	a5,ffffffffc02002fa <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc0200362:	03448863          	beq	s1,s4,ffffffffc0200392 <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc0200366:	00349793          	slli	a5,s1,0x3
ffffffffc020036a:	0118                	addi	a4,sp,128
ffffffffc020036c:	97ba                	add	a5,a5,a4
ffffffffc020036e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200372:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200376:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200378:	e591                	bnez	a1,ffffffffc0200384 <kmonitor+0x11a>
ffffffffc020037a:	b749                	j	ffffffffc02002fc <kmonitor+0x92>
            buf ++;
ffffffffc020037c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020037e:	00044583          	lbu	a1,0(s0)
ffffffffc0200382:	ddad                	beqz	a1,ffffffffc02002fc <kmonitor+0x92>
ffffffffc0200384:	854a                	mv	a0,s2
ffffffffc0200386:	382010ef          	jal	ra,ffffffffc0201708 <strchr>
ffffffffc020038a:	d96d                	beqz	a0,ffffffffc020037c <kmonitor+0x112>
ffffffffc020038c:	00044583          	lbu	a1,0(s0)
ffffffffc0200390:	bf91                	j	ffffffffc02002e4 <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	855a                	mv	a0,s6
ffffffffc0200396:	d21ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020039a:	b7f1                	j	ffffffffc0200366 <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039c:	6582                	ld	a1,0(sp)
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	58250513          	addi	a0,a0,1410 # ffffffffc0201920 <commands+0xc8>
ffffffffc02003a6:	d11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    return 0;
ffffffffc02003aa:	b72d                	j	ffffffffc02002d4 <kmonitor+0x6a>

ffffffffc02003ac <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ac:	00006317          	auipc	t1,0x6
ffffffffc02003b0:	06430313          	addi	t1,t1,100 # ffffffffc0206410 <is_panic>
ffffffffc02003b4:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b8:	715d                	addi	sp,sp,-80
ffffffffc02003ba:	ec06                	sd	ra,24(sp)
ffffffffc02003bc:	e822                	sd	s0,16(sp)
ffffffffc02003be:	f436                	sd	a3,40(sp)
ffffffffc02003c0:	f83a                	sd	a4,48(sp)
ffffffffc02003c2:	fc3e                	sd	a5,56(sp)
ffffffffc02003c4:	e0c2                	sd	a6,64(sp)
ffffffffc02003c6:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c8:	02031c63          	bnez	t1,ffffffffc0200400 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003cc:	4785                	li	a5,1
ffffffffc02003ce:	8432                	mv	s0,a2
ffffffffc02003d0:	00006717          	auipc	a4,0x6
ffffffffc02003d4:	04f72023          	sw	a5,64(a4) # ffffffffc0206410 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d8:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02003da:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003dc:	85aa                	mv	a1,a0
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	5fa50513          	addi	a0,a0,1530 # ffffffffc02019d8 <commands+0x180>
    va_start(ap, fmt);
ffffffffc02003e6:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e8:	ccfff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003ec:	65a2                	ld	a1,8(sp)
ffffffffc02003ee:	8522                	mv	a0,s0
ffffffffc02003f0:	ca7ff0ef          	jal	ra,ffffffffc0200096 <vcprintf>
    cprintf("\n");
ffffffffc02003f4:	00001517          	auipc	a0,0x1
ffffffffc02003f8:	45c50513          	addi	a0,a0,1116 # ffffffffc0201850 <etext+0x118>
ffffffffc02003fc:	cbbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200400:	064000ef          	jal	ra,ffffffffc0200464 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200404:	4501                	li	a0,0
ffffffffc0200406:	e65ff0ef          	jal	ra,ffffffffc020026a <kmonitor>
ffffffffc020040a:	bfed                	j	ffffffffc0200404 <__panic+0x58>

ffffffffc020040c <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020040c:	1141                	addi	sp,sp,-16
ffffffffc020040e:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200410:	02000793          	li	a5,32
ffffffffc0200414:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200418:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020041c:	67e1                	lui	a5,0x18
ffffffffc020041e:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc0200422:	953e                	add	a0,a0,a5
ffffffffc0200424:	25a010ef          	jal	ra,ffffffffc020167e <sbi_set_timer>
}
ffffffffc0200428:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042a:	00006797          	auipc	a5,0x6
ffffffffc020042e:	0207b323          	sd	zero,38(a5) # ffffffffc0206450 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200432:	00001517          	auipc	a0,0x1
ffffffffc0200436:	5c650513          	addi	a0,a0,1478 # ffffffffc02019f8 <commands+0x1a0>
}
ffffffffc020043a:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020043c:	c7bff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc0200440 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200440:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200444:	67e1                	lui	a5,0x18
ffffffffc0200446:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc020044a:	953e                	add	a0,a0,a5
ffffffffc020044c:	2320106f          	j	ffffffffc020167e <sbi_set_timer>

ffffffffc0200450 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200450:	8082                	ret

ffffffffc0200452 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200452:	0ff57513          	andi	a0,a0,255
ffffffffc0200456:	20c0106f          	j	ffffffffc0201662 <sbi_console_putchar>

ffffffffc020045a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045a:	2400106f          	j	ffffffffc020169a <sbi_console_getchar>

ffffffffc020045e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200464:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200468:	8082                	ret

ffffffffc020046a <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020046a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020046e:	00000797          	auipc	a5,0x0
ffffffffc0200472:	30678793          	addi	a5,a5,774 # ffffffffc0200774 <__alltraps>
ffffffffc0200476:	10579073          	csrw	stvec,a5
}
ffffffffc020047a:	8082                	ret

ffffffffc020047c <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020047e:	1141                	addi	sp,sp,-16
ffffffffc0200480:	e022                	sd	s0,0(sp)
ffffffffc0200482:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200484:	00001517          	auipc	a0,0x1
ffffffffc0200488:	68c50513          	addi	a0,a0,1676 # ffffffffc0201b10 <commands+0x2b8>
void print_regs(struct pushregs *gpr) {
ffffffffc020048c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020048e:	c29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200492:	640c                	ld	a1,8(s0)
ffffffffc0200494:	00001517          	auipc	a0,0x1
ffffffffc0200498:	69450513          	addi	a0,a0,1684 # ffffffffc0201b28 <commands+0x2d0>
ffffffffc020049c:	c1bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a0:	680c                	ld	a1,16(s0)
ffffffffc02004a2:	00001517          	auipc	a0,0x1
ffffffffc02004a6:	69e50513          	addi	a0,a0,1694 # ffffffffc0201b40 <commands+0x2e8>
ffffffffc02004aa:	c0dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004ae:	6c0c                	ld	a1,24(s0)
ffffffffc02004b0:	00001517          	auipc	a0,0x1
ffffffffc02004b4:	6a850513          	addi	a0,a0,1704 # ffffffffc0201b58 <commands+0x300>
ffffffffc02004b8:	bffff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004bc:	700c                	ld	a1,32(s0)
ffffffffc02004be:	00001517          	auipc	a0,0x1
ffffffffc02004c2:	6b250513          	addi	a0,a0,1714 # ffffffffc0201b70 <commands+0x318>
ffffffffc02004c6:	bf1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004ca:	740c                	ld	a1,40(s0)
ffffffffc02004cc:	00001517          	auipc	a0,0x1
ffffffffc02004d0:	6bc50513          	addi	a0,a0,1724 # ffffffffc0201b88 <commands+0x330>
ffffffffc02004d4:	be3ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d8:	780c                	ld	a1,48(s0)
ffffffffc02004da:	00001517          	auipc	a0,0x1
ffffffffc02004de:	6c650513          	addi	a0,a0,1734 # ffffffffc0201ba0 <commands+0x348>
ffffffffc02004e2:	bd5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e6:	7c0c                	ld	a1,56(s0)
ffffffffc02004e8:	00001517          	auipc	a0,0x1
ffffffffc02004ec:	6d050513          	addi	a0,a0,1744 # ffffffffc0201bb8 <commands+0x360>
ffffffffc02004f0:	bc7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f4:	602c                	ld	a1,64(s0)
ffffffffc02004f6:	00001517          	auipc	a0,0x1
ffffffffc02004fa:	6da50513          	addi	a0,a0,1754 # ffffffffc0201bd0 <commands+0x378>
ffffffffc02004fe:	bb9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200502:	642c                	ld	a1,72(s0)
ffffffffc0200504:	00001517          	auipc	a0,0x1
ffffffffc0200508:	6e450513          	addi	a0,a0,1764 # ffffffffc0201be8 <commands+0x390>
ffffffffc020050c:	babff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200510:	682c                	ld	a1,80(s0)
ffffffffc0200512:	00001517          	auipc	a0,0x1
ffffffffc0200516:	6ee50513          	addi	a0,a0,1774 # ffffffffc0201c00 <commands+0x3a8>
ffffffffc020051a:	b9dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020051e:	6c2c                	ld	a1,88(s0)
ffffffffc0200520:	00001517          	auipc	a0,0x1
ffffffffc0200524:	6f850513          	addi	a0,a0,1784 # ffffffffc0201c18 <commands+0x3c0>
ffffffffc0200528:	b8fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052c:	702c                	ld	a1,96(s0)
ffffffffc020052e:	00001517          	auipc	a0,0x1
ffffffffc0200532:	70250513          	addi	a0,a0,1794 # ffffffffc0201c30 <commands+0x3d8>
ffffffffc0200536:	b81ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053a:	742c                	ld	a1,104(s0)
ffffffffc020053c:	00001517          	auipc	a0,0x1
ffffffffc0200540:	70c50513          	addi	a0,a0,1804 # ffffffffc0201c48 <commands+0x3f0>
ffffffffc0200544:	b73ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200548:	782c                	ld	a1,112(s0)
ffffffffc020054a:	00001517          	auipc	a0,0x1
ffffffffc020054e:	71650513          	addi	a0,a0,1814 # ffffffffc0201c60 <commands+0x408>
ffffffffc0200552:	b65ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200556:	7c2c                	ld	a1,120(s0)
ffffffffc0200558:	00001517          	auipc	a0,0x1
ffffffffc020055c:	72050513          	addi	a0,a0,1824 # ffffffffc0201c78 <commands+0x420>
ffffffffc0200560:	b57ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200564:	604c                	ld	a1,128(s0)
ffffffffc0200566:	00001517          	auipc	a0,0x1
ffffffffc020056a:	72a50513          	addi	a0,a0,1834 # ffffffffc0201c90 <commands+0x438>
ffffffffc020056e:	b49ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200572:	644c                	ld	a1,136(s0)
ffffffffc0200574:	00001517          	auipc	a0,0x1
ffffffffc0200578:	73450513          	addi	a0,a0,1844 # ffffffffc0201ca8 <commands+0x450>
ffffffffc020057c:	b3bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200580:	684c                	ld	a1,144(s0)
ffffffffc0200582:	00001517          	auipc	a0,0x1
ffffffffc0200586:	73e50513          	addi	a0,a0,1854 # ffffffffc0201cc0 <commands+0x468>
ffffffffc020058a:	b2dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020058e:	6c4c                	ld	a1,152(s0)
ffffffffc0200590:	00001517          	auipc	a0,0x1
ffffffffc0200594:	74850513          	addi	a0,a0,1864 # ffffffffc0201cd8 <commands+0x480>
ffffffffc0200598:	b1fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059c:	704c                	ld	a1,160(s0)
ffffffffc020059e:	00001517          	auipc	a0,0x1
ffffffffc02005a2:	75250513          	addi	a0,a0,1874 # ffffffffc0201cf0 <commands+0x498>
ffffffffc02005a6:	b11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005aa:	744c                	ld	a1,168(s0)
ffffffffc02005ac:	00001517          	auipc	a0,0x1
ffffffffc02005b0:	75c50513          	addi	a0,a0,1884 # ffffffffc0201d08 <commands+0x4b0>
ffffffffc02005b4:	b03ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b8:	784c                	ld	a1,176(s0)
ffffffffc02005ba:	00001517          	auipc	a0,0x1
ffffffffc02005be:	76650513          	addi	a0,a0,1894 # ffffffffc0201d20 <commands+0x4c8>
ffffffffc02005c2:	af5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c6:	7c4c                	ld	a1,184(s0)
ffffffffc02005c8:	00001517          	auipc	a0,0x1
ffffffffc02005cc:	77050513          	addi	a0,a0,1904 # ffffffffc0201d38 <commands+0x4e0>
ffffffffc02005d0:	ae7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d4:	606c                	ld	a1,192(s0)
ffffffffc02005d6:	00001517          	auipc	a0,0x1
ffffffffc02005da:	77a50513          	addi	a0,a0,1914 # ffffffffc0201d50 <commands+0x4f8>
ffffffffc02005de:	ad9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e2:	646c                	ld	a1,200(s0)
ffffffffc02005e4:	00001517          	auipc	a0,0x1
ffffffffc02005e8:	78450513          	addi	a0,a0,1924 # ffffffffc0201d68 <commands+0x510>
ffffffffc02005ec:	acbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f0:	686c                	ld	a1,208(s0)
ffffffffc02005f2:	00001517          	auipc	a0,0x1
ffffffffc02005f6:	78e50513          	addi	a0,a0,1934 # ffffffffc0201d80 <commands+0x528>
ffffffffc02005fa:	abdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200600:	00001517          	auipc	a0,0x1
ffffffffc0200604:	79850513          	addi	a0,a0,1944 # ffffffffc0201d98 <commands+0x540>
ffffffffc0200608:	aafff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060c:	706c                	ld	a1,224(s0)
ffffffffc020060e:	00001517          	auipc	a0,0x1
ffffffffc0200612:	7a250513          	addi	a0,a0,1954 # ffffffffc0201db0 <commands+0x558>
ffffffffc0200616:	aa1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061a:	746c                	ld	a1,232(s0)
ffffffffc020061c:	00001517          	auipc	a0,0x1
ffffffffc0200620:	7ac50513          	addi	a0,a0,1964 # ffffffffc0201dc8 <commands+0x570>
ffffffffc0200624:	a93ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200628:	786c                	ld	a1,240(s0)
ffffffffc020062a:	00001517          	auipc	a0,0x1
ffffffffc020062e:	7b650513          	addi	a0,a0,1974 # ffffffffc0201de0 <commands+0x588>
ffffffffc0200632:	a85ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200638:	6402                	ld	s0,0(sp)
ffffffffc020063a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	00001517          	auipc	a0,0x1
ffffffffc0200640:	7bc50513          	addi	a0,a0,1980 # ffffffffc0201df8 <commands+0x5a0>
}
ffffffffc0200644:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200646:	a71ff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc020064a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020064a:	1141                	addi	sp,sp,-16
ffffffffc020064c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020064e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200650:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200652:	00001517          	auipc	a0,0x1
ffffffffc0200656:	7be50513          	addi	a0,a0,1982 # ffffffffc0201e10 <commands+0x5b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc020065a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020065c:	a5bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200660:	8522                	mv	a0,s0
ffffffffc0200662:	e1bff0ef          	jal	ra,ffffffffc020047c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200666:	10043583          	ld	a1,256(s0)
ffffffffc020066a:	00001517          	auipc	a0,0x1
ffffffffc020066e:	7be50513          	addi	a0,a0,1982 # ffffffffc0201e28 <commands+0x5d0>
ffffffffc0200672:	a45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00001517          	auipc	a0,0x1
ffffffffc020067e:	7c650513          	addi	a0,a0,1990 # ffffffffc0201e40 <commands+0x5e8>
ffffffffc0200682:	a35ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00001517          	auipc	a0,0x1
ffffffffc020068e:	7ce50513          	addi	a0,a0,1998 # ffffffffc0201e58 <commands+0x600>
ffffffffc0200692:	a25ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00001517          	auipc	a0,0x1
ffffffffc02006a2:	7d250513          	addi	a0,a0,2002 # ffffffffc0201e70 <commands+0x618>
}
ffffffffc02006a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a8:	a0fff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02006ac <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006ac:	11853783          	ld	a5,280(a0)
ffffffffc02006b0:	577d                	li	a4,-1
ffffffffc02006b2:	8305                	srli	a4,a4,0x1
ffffffffc02006b4:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02006b6:	472d                	li	a4,11
ffffffffc02006b8:	08f76563          	bltu	a4,a5,ffffffffc0200742 <interrupt_handler+0x96>
ffffffffc02006bc:	00001717          	auipc	a4,0x1
ffffffffc02006c0:	35870713          	addi	a4,a4,856 # ffffffffc0201a14 <commands+0x1bc>
ffffffffc02006c4:	078a                	slli	a5,a5,0x2
ffffffffc02006c6:	97ba                	add	a5,a5,a4
ffffffffc02006c8:	439c                	lw	a5,0(a5)
ffffffffc02006ca:	97ba                	add	a5,a5,a4
ffffffffc02006cc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006ce:	00001517          	auipc	a0,0x1
ffffffffc02006d2:	3da50513          	addi	a0,a0,986 # ffffffffc0201aa8 <commands+0x250>
ffffffffc02006d6:	9e1ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006da:	00001517          	auipc	a0,0x1
ffffffffc02006de:	3ae50513          	addi	a0,a0,942 # ffffffffc0201a88 <commands+0x230>
ffffffffc02006e2:	9d5ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006e6:	00001517          	auipc	a0,0x1
ffffffffc02006ea:	36250513          	addi	a0,a0,866 # ffffffffc0201a48 <commands+0x1f0>
ffffffffc02006ee:	9c9ff06f          	j	ffffffffc02000b6 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006f2:	00001517          	auipc	a0,0x1
ffffffffc02006f6:	3d650513          	addi	a0,a0,982 # ffffffffc0201ac8 <commands+0x270>
ffffffffc02006fa:	9bdff06f          	j	ffffffffc02000b6 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006fe:	1141                	addi	sp,sp,-16
ffffffffc0200700:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc0200702:	d3fff0ef          	jal	ra,ffffffffc0200440 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200706:	00006797          	auipc	a5,0x6
ffffffffc020070a:	d4a78793          	addi	a5,a5,-694 # ffffffffc0206450 <ticks>
ffffffffc020070e:	639c                	ld	a5,0(a5)
ffffffffc0200710:	06400713          	li	a4,100
ffffffffc0200714:	0785                	addi	a5,a5,1
ffffffffc0200716:	02e7f733          	remu	a4,a5,a4
ffffffffc020071a:	00006697          	auipc	a3,0x6
ffffffffc020071e:	d2f6bb23          	sd	a5,-714(a3) # ffffffffc0206450 <ticks>
ffffffffc0200722:	c315                	beqz	a4,ffffffffc0200746 <interrupt_handler+0x9a>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200724:	60a2                	ld	ra,8(sp)
ffffffffc0200726:	0141                	addi	sp,sp,16
ffffffffc0200728:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc020072a:	00001517          	auipc	a0,0x1
ffffffffc020072e:	3c650513          	addi	a0,a0,966 # ffffffffc0201af0 <commands+0x298>
ffffffffc0200732:	985ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200736:	00001517          	auipc	a0,0x1
ffffffffc020073a:	33250513          	addi	a0,a0,818 # ffffffffc0201a68 <commands+0x210>
ffffffffc020073e:	979ff06f          	j	ffffffffc02000b6 <cprintf>
            print_trapframe(tf);
ffffffffc0200742:	f09ff06f          	j	ffffffffc020064a <print_trapframe>
}
ffffffffc0200746:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200748:	06400593          	li	a1,100
ffffffffc020074c:	00001517          	auipc	a0,0x1
ffffffffc0200750:	39450513          	addi	a0,a0,916 # ffffffffc0201ae0 <commands+0x288>
}
ffffffffc0200754:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200756:	961ff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc020075a <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc020075a:	11853783          	ld	a5,280(a0)
ffffffffc020075e:	0007c863          	bltz	a5,ffffffffc020076e <trap+0x14>
    switch (tf->cause) {
ffffffffc0200762:	472d                	li	a4,11
ffffffffc0200764:	00f76363          	bltu	a4,a5,ffffffffc020076a <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200768:	8082                	ret
            print_trapframe(tf);
ffffffffc020076a:	ee1ff06f          	j	ffffffffc020064a <print_trapframe>
        interrupt_handler(tf);
ffffffffc020076e:	f3fff06f          	j	ffffffffc02006ac <interrupt_handler>
	...

ffffffffc0200774 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200774:	14011073          	csrw	sscratch,sp
ffffffffc0200778:	712d                	addi	sp,sp,-288
ffffffffc020077a:	e002                	sd	zero,0(sp)
ffffffffc020077c:	e406                	sd	ra,8(sp)
ffffffffc020077e:	ec0e                	sd	gp,24(sp)
ffffffffc0200780:	f012                	sd	tp,32(sp)
ffffffffc0200782:	f416                	sd	t0,40(sp)
ffffffffc0200784:	f81a                	sd	t1,48(sp)
ffffffffc0200786:	fc1e                	sd	t2,56(sp)
ffffffffc0200788:	e0a2                	sd	s0,64(sp)
ffffffffc020078a:	e4a6                	sd	s1,72(sp)
ffffffffc020078c:	e8aa                	sd	a0,80(sp)
ffffffffc020078e:	ecae                	sd	a1,88(sp)
ffffffffc0200790:	f0b2                	sd	a2,96(sp)
ffffffffc0200792:	f4b6                	sd	a3,104(sp)
ffffffffc0200794:	f8ba                	sd	a4,112(sp)
ffffffffc0200796:	fcbe                	sd	a5,120(sp)
ffffffffc0200798:	e142                	sd	a6,128(sp)
ffffffffc020079a:	e546                	sd	a7,136(sp)
ffffffffc020079c:	e94a                	sd	s2,144(sp)
ffffffffc020079e:	ed4e                	sd	s3,152(sp)
ffffffffc02007a0:	f152                	sd	s4,160(sp)
ffffffffc02007a2:	f556                	sd	s5,168(sp)
ffffffffc02007a4:	f95a                	sd	s6,176(sp)
ffffffffc02007a6:	fd5e                	sd	s7,184(sp)
ffffffffc02007a8:	e1e2                	sd	s8,192(sp)
ffffffffc02007aa:	e5e6                	sd	s9,200(sp)
ffffffffc02007ac:	e9ea                	sd	s10,208(sp)
ffffffffc02007ae:	edee                	sd	s11,216(sp)
ffffffffc02007b0:	f1f2                	sd	t3,224(sp)
ffffffffc02007b2:	f5f6                	sd	t4,232(sp)
ffffffffc02007b4:	f9fa                	sd	t5,240(sp)
ffffffffc02007b6:	fdfe                	sd	t6,248(sp)
ffffffffc02007b8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc02007bc:	100024f3          	csrr	s1,sstatus
ffffffffc02007c0:	14102973          	csrr	s2,sepc
ffffffffc02007c4:	143029f3          	csrr	s3,stval
ffffffffc02007c8:	14202a73          	csrr	s4,scause
ffffffffc02007cc:	e822                	sd	s0,16(sp)
ffffffffc02007ce:	e226                	sd	s1,256(sp)
ffffffffc02007d0:	e64a                	sd	s2,264(sp)
ffffffffc02007d2:	ea4e                	sd	s3,272(sp)
ffffffffc02007d4:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007d6:	850a                	mv	a0,sp
    jal trap
ffffffffc02007d8:	f83ff0ef          	jal	ra,ffffffffc020075a <trap>

ffffffffc02007dc <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007dc:	6492                	ld	s1,256(sp)
ffffffffc02007de:	6932                	ld	s2,264(sp)
ffffffffc02007e0:	10049073          	csrw	sstatus,s1
ffffffffc02007e4:	14191073          	csrw	sepc,s2
ffffffffc02007e8:	60a2                	ld	ra,8(sp)
ffffffffc02007ea:	61e2                	ld	gp,24(sp)
ffffffffc02007ec:	7202                	ld	tp,32(sp)
ffffffffc02007ee:	72a2                	ld	t0,40(sp)
ffffffffc02007f0:	7342                	ld	t1,48(sp)
ffffffffc02007f2:	73e2                	ld	t2,56(sp)
ffffffffc02007f4:	6406                	ld	s0,64(sp)
ffffffffc02007f6:	64a6                	ld	s1,72(sp)
ffffffffc02007f8:	6546                	ld	a0,80(sp)
ffffffffc02007fa:	65e6                	ld	a1,88(sp)
ffffffffc02007fc:	7606                	ld	a2,96(sp)
ffffffffc02007fe:	76a6                	ld	a3,104(sp)
ffffffffc0200800:	7746                	ld	a4,112(sp)
ffffffffc0200802:	77e6                	ld	a5,120(sp)
ffffffffc0200804:	680a                	ld	a6,128(sp)
ffffffffc0200806:	68aa                	ld	a7,136(sp)
ffffffffc0200808:	694a                	ld	s2,144(sp)
ffffffffc020080a:	69ea                	ld	s3,152(sp)
ffffffffc020080c:	7a0a                	ld	s4,160(sp)
ffffffffc020080e:	7aaa                	ld	s5,168(sp)
ffffffffc0200810:	7b4a                	ld	s6,176(sp)
ffffffffc0200812:	7bea                	ld	s7,184(sp)
ffffffffc0200814:	6c0e                	ld	s8,192(sp)
ffffffffc0200816:	6cae                	ld	s9,200(sp)
ffffffffc0200818:	6d4e                	ld	s10,208(sp)
ffffffffc020081a:	6dee                	ld	s11,216(sp)
ffffffffc020081c:	7e0e                	ld	t3,224(sp)
ffffffffc020081e:	7eae                	ld	t4,232(sp)
ffffffffc0200820:	7f4e                	ld	t5,240(sp)
ffffffffc0200822:	7fee                	ld	t6,248(sp)
ffffffffc0200824:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200826:	10200073          	sret

ffffffffc020082a <buddy_init>:
static struct Page* useable_page_base;

static void
buddy_init(void) {
    /* do nothing */
}
ffffffffc020082a:	8082                	ret

ffffffffc020082c <buddy_nr_free_pages>:
    }
}

static size_t
buddy_nr_free_pages(void) {
    return buddy_page[1];
ffffffffc020082c:	00006797          	auipc	a5,0x6
ffffffffc0200830:	bec78793          	addi	a5,a5,-1044 # ffffffffc0206418 <buddy_page>
ffffffffc0200834:	639c                	ld	a5,0(a5)
}
ffffffffc0200836:	0047e503          	lwu	a0,4(a5)
ffffffffc020083a:	8082                	ret

ffffffffc020083c <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc020083c:	c56d                	beqz	a0,ffffffffc0200926 <buddy_alloc_pages+0xea>
    if (n > buddy_page[1]){
ffffffffc020083e:	00006597          	auipc	a1,0x6
ffffffffc0200842:	bda58593          	addi	a1,a1,-1062 # ffffffffc0206418 <buddy_page>
ffffffffc0200846:	6190                	ld	a2,0(a1)
ffffffffc0200848:	00466783          	lwu	a5,4(a2)
ffffffffc020084c:	0ca7eb63          	bltu	a5,a0,ffffffffc0200922 <buddy_alloc_pages+0xe6>
    unsigned int index = 1;
ffffffffc0200850:	4705                	li	a4,1
        if (buddy_page[LEFT_CHILD(index)] >= n){
ffffffffc0200852:	86ba                	mv	a3,a4
ffffffffc0200854:	0017171b          	slliw	a4,a4,0x1
ffffffffc0200858:	02071793          	slli	a5,a4,0x20
ffffffffc020085c:	83f9                	srli	a5,a5,0x1e
ffffffffc020085e:	97b2                	add	a5,a5,a2
ffffffffc0200860:	0007e783          	lwu	a5,0(a5)
ffffffffc0200864:	fea7f7e3          	bleu	a0,a5,ffffffffc0200852 <buddy_alloc_pages+0x16>
        else if (buddy_page[RIGHT_CHILD(index)] >= n){
ffffffffc0200868:	2705                	addiw	a4,a4,1
ffffffffc020086a:	02071793          	slli	a5,a4,0x20
ffffffffc020086e:	83f9                	srli	a5,a5,0x1e
ffffffffc0200870:	97b2                	add	a5,a5,a2
ffffffffc0200872:	0007e783          	lwu	a5,0(a5)
ffffffffc0200876:	fca7fee3          	bleu	a0,a5,ffffffffc0200852 <buddy_alloc_pages+0x16>
    unsigned int size = buddy_page[index];
ffffffffc020087a:	02069793          	slli	a5,a3,0x20
ffffffffc020087e:	83f9                	srli	a5,a5,0x1e
ffffffffc0200880:	963e                	add	a2,a2,a5
ffffffffc0200882:	4218                	lw	a4,0(a2)
    struct Page* new_page = &useable_page_base[index * size - useable_page_num];
ffffffffc0200884:	00006797          	auipc	a5,0x6
ffffffffc0200888:	bac78793          	addi	a5,a5,-1108 # ffffffffc0206430 <useable_page_num>
ffffffffc020088c:	0007a883          	lw	a7,0(a5)
ffffffffc0200890:	02e687bb          	mulw	a5,a3,a4
    for (struct Page* p = new_page; p != new_page + size; p++){
ffffffffc0200894:	02071813          	slli	a6,a4,0x20
    struct Page* new_page = &useable_page_base[index * size - useable_page_num];
ffffffffc0200898:	00006717          	auipc	a4,0x6
ffffffffc020089c:	b9070713          	addi	a4,a4,-1136 # ffffffffc0206428 <useable_page_base>
    for (struct Page* p = new_page; p != new_page + size; p++){
ffffffffc02008a0:	02085813          	srli	a6,a6,0x20
    struct Page* new_page = &useable_page_base[index * size - useable_page_num];
ffffffffc02008a4:	6308                	ld	a0,0(a4)
    buddy_page[index] = 0;
ffffffffc02008a6:	00062023          	sw	zero,0(a2)
    for (struct Page* p = new_page; p != new_page + size; p++){
ffffffffc02008aa:	00281713          	slli	a4,a6,0x2
ffffffffc02008ae:	9742                	add	a4,a4,a6
ffffffffc02008b0:	070e                	slli	a4,a4,0x3
    struct Page* new_page = &useable_page_base[index * size - useable_page_num];
ffffffffc02008b2:	411787bb          	subw	a5,a5,a7
ffffffffc02008b6:	1782                	slli	a5,a5,0x20
ffffffffc02008b8:	9381                	srli	a5,a5,0x20
ffffffffc02008ba:	00279613          	slli	a2,a5,0x2
ffffffffc02008be:	97b2                	add	a5,a5,a2
ffffffffc02008c0:	078e                	slli	a5,a5,0x3
ffffffffc02008c2:	953e                	add	a0,a0,a5
    for (struct Page* p = new_page; p != new_page + size; p++){
ffffffffc02008c4:	972a                	add	a4,a4,a0
ffffffffc02008c6:	00e50e63          	beq	a0,a4,ffffffffc02008e2 <buddy_alloc_pages+0xa6>
ffffffffc02008ca:	87aa                	mv	a5,a0
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02008cc:	5675                	li	a2,-3
ffffffffc02008ce:	00878813          	addi	a6,a5,8
ffffffffc02008d2:	60c8302f          	amoand.d	zero,a2,(a6)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02008d6:	0007a023          	sw	zero,0(a5)
ffffffffc02008da:	02878793          	addi	a5,a5,40
ffffffffc02008de:	fee798e3          	bne	a5,a4,ffffffffc02008ce <buddy_alloc_pages+0x92>
    index = PARENT(index);
ffffffffc02008e2:	0016d69b          	srliw	a3,a3,0x1
    while(index > 0){
ffffffffc02008e6:	ce9d                	beqz	a3,ffffffffc0200924 <buddy_alloc_pages+0xe8>
        buddy_page[index] = MAX(buddy_page[LEFT_CHILD(index)], buddy_page[RIGHT_CHILD(index)]);
ffffffffc02008e8:	6190                	ld	a2,0(a1)
ffffffffc02008ea:	0016979b          	slliw	a5,a3,0x1
ffffffffc02008ee:	0017871b          	addiw	a4,a5,1
ffffffffc02008f2:	1702                	slli	a4,a4,0x20
ffffffffc02008f4:	1782                	slli	a5,a5,0x20
ffffffffc02008f6:	9301                	srli	a4,a4,0x20
ffffffffc02008f8:	9381                	srli	a5,a5,0x20
ffffffffc02008fa:	070a                	slli	a4,a4,0x2
ffffffffc02008fc:	078a                	slli	a5,a5,0x2
ffffffffc02008fe:	97b2                	add	a5,a5,a2
ffffffffc0200900:	9732                	add	a4,a4,a2
ffffffffc0200902:	438c                	lw	a1,0(a5)
ffffffffc0200904:	4318                	lw	a4,0(a4)
ffffffffc0200906:	00269793          	slli	a5,a3,0x2
ffffffffc020090a:	0005881b          	sext.w	a6,a1
ffffffffc020090e:	0007089b          	sext.w	a7,a4
ffffffffc0200912:	97b2                	add	a5,a5,a2
ffffffffc0200914:	0108f363          	bleu	a6,a7,ffffffffc020091a <buddy_alloc_pages+0xde>
ffffffffc0200918:	872e                	mv	a4,a1
ffffffffc020091a:	c398                	sw	a4,0(a5)
        index = PARENT(index);
ffffffffc020091c:	8285                	srli	a3,a3,0x1
    while(index > 0){
ffffffffc020091e:	f6f1                	bnez	a3,ffffffffc02008ea <buddy_alloc_pages+0xae>
ffffffffc0200920:	8082                	ret
        return NULL;
ffffffffc0200922:	4501                	li	a0,0
}
ffffffffc0200924:	8082                	ret
Page* buddy_alloc_pages(size_t n) {
ffffffffc0200926:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200928:	00001697          	auipc	a3,0x1
ffffffffc020092c:	56068693          	addi	a3,a3,1376 # ffffffffc0201e88 <commands+0x630>
ffffffffc0200930:	00001617          	auipc	a2,0x1
ffffffffc0200934:	56060613          	addi	a2,a2,1376 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200938:	03a00593          	li	a1,58
ffffffffc020093c:	00001517          	auipc	a0,0x1
ffffffffc0200940:	56c50513          	addi	a0,a0,1388 # ffffffffc0201ea8 <commands+0x650>
Page* buddy_alloc_pages(size_t n) {
ffffffffc0200944:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200946:	a67ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020094a <buddy_check>:

static void
buddy_check(void) {
ffffffffc020094a:	7179                	addi	sp,sp,-48
ffffffffc020094c:	e84a                	sd	s2,16(sp)
ffffffffc020094e:	f406                	sd	ra,40(sp)
ffffffffc0200950:	f022                	sd	s0,32(sp)
ffffffffc0200952:	ec26                	sd	s1,24(sp)
ffffffffc0200954:	e44e                	sd	s3,8(sp)
ffffffffc0200956:	e052                	sd	s4,0(sp)
    int all_pages = nr_free_pages();
ffffffffc0200958:	666000ef          	jal	ra,ffffffffc0200fbe <nr_free_pages>
ffffffffc020095c:	0005091b          	sext.w	s2,a0
    struct Page* p0, *p1, *p2, *p3;
    // 分配过大的页数
    assert(alloc_pages(all_pages + 1) == NULL);
ffffffffc0200960:	0019051b          	addiw	a0,s2,1
ffffffffc0200964:	5d0000ef          	jal	ra,ffffffffc0200f34 <alloc_pages>
ffffffffc0200968:	26051263          	bnez	a0,ffffffffc0200bcc <buddy_check+0x282>
    // 分配两个组页
    p0 = alloc_pages(1);
ffffffffc020096c:	4505                	li	a0,1
ffffffffc020096e:	5c6000ef          	jal	ra,ffffffffc0200f34 <alloc_pages>
ffffffffc0200972:	842a                	mv	s0,a0
    assert(p0 != NULL);
ffffffffc0200974:	22050c63          	beqz	a0,ffffffffc0200bac <buddy_check+0x262>
    p1 = alloc_pages(2);
ffffffffc0200978:	4509                	li	a0,2
ffffffffc020097a:	5ba000ef          	jal	ra,ffffffffc0200f34 <alloc_pages>
    assert(p1 == p0 + 2);
ffffffffc020097e:	05040793          	addi	a5,s0,80
    p1 = alloc_pages(2);
ffffffffc0200982:	84aa                	mv	s1,a0
    assert(p1 == p0 + 2);
ffffffffc0200984:	1af51463          	bne	a0,a5,ffffffffc0200b2c <buddy_check+0x1e2>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200988:	641c                	ld	a5,8(s0)
    assert(!PageReserved(p0) && !PageProperty(p0));
ffffffffc020098a:	8b85                	andi	a5,a5,1
ffffffffc020098c:	12079063          	bnez	a5,ffffffffc0200aac <buddy_check+0x162>
ffffffffc0200990:	641c                	ld	a5,8(s0)
ffffffffc0200992:	8385                	srli	a5,a5,0x1
ffffffffc0200994:	8b85                	andi	a5,a5,1
ffffffffc0200996:	10079b63          	bnez	a5,ffffffffc0200aac <buddy_check+0x162>
ffffffffc020099a:	651c                	ld	a5,8(a0)
    assert(!PageReserved(p1) && !PageProperty(p1));
ffffffffc020099c:	8b85                	andi	a5,a5,1
ffffffffc020099e:	0e079763          	bnez	a5,ffffffffc0200a8c <buddy_check+0x142>
ffffffffc02009a2:	651c                	ld	a5,8(a0)
ffffffffc02009a4:	8385                	srli	a5,a5,0x1
ffffffffc02009a6:	8b85                	andi	a5,a5,1
ffffffffc02009a8:	0e079263          	bnez	a5,ffffffffc0200a8c <buddy_check+0x142>
    // 再分配两个组页
    p2 = alloc_pages(1);
ffffffffc02009ac:	4505                	li	a0,1
ffffffffc02009ae:	586000ef          	jal	ra,ffffffffc0200f34 <alloc_pages>
    assert(p2 == p0 + 1);
ffffffffc02009b2:	02840793          	addi	a5,s0,40
    p2 = alloc_pages(1);
ffffffffc02009b6:	8a2a                	mv	s4,a0
    assert(p2 == p0 + 1);
ffffffffc02009b8:	12f51a63          	bne	a0,a5,ffffffffc0200aec <buddy_check+0x1a2>
    p3 = alloc_pages(8);
ffffffffc02009bc:	4521                	li	a0,8
ffffffffc02009be:	576000ef          	jal	ra,ffffffffc0200f34 <alloc_pages>
    assert(p3 == p0 + 8);
ffffffffc02009c2:	14040793          	addi	a5,s0,320
    p3 = alloc_pages(8);
ffffffffc02009c6:	89aa                	mv	s3,a0
    assert(p3 == p0 + 8);
ffffffffc02009c8:	24f51263          	bne	a0,a5,ffffffffc0200c0c <buddy_check+0x2c2>
ffffffffc02009cc:	651c                	ld	a5,8(a0)
ffffffffc02009ce:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p3) && !PageProperty(p3 + 7) && PageProperty(p3 + 8));
ffffffffc02009d0:	8b85                	andi	a5,a5,1
ffffffffc02009d2:	efc9                	bnez	a5,ffffffffc0200a6c <buddy_check+0x122>
ffffffffc02009d4:	12053783          	ld	a5,288(a0)
ffffffffc02009d8:	8385                	srli	a5,a5,0x1
ffffffffc02009da:	8b85                	andi	a5,a5,1
ffffffffc02009dc:	ebc1                	bnez	a5,ffffffffc0200a6c <buddy_check+0x122>
ffffffffc02009de:	14853783          	ld	a5,328(a0)
ffffffffc02009e2:	8385                	srli	a5,a5,0x1
ffffffffc02009e4:	8b85                	andi	a5,a5,1
ffffffffc02009e6:	c3d9                	beqz	a5,ffffffffc0200a6c <buddy_check+0x122>
    // 回收页
    free_pages(p1, 2);
ffffffffc02009e8:	4589                	li	a1,2
ffffffffc02009ea:	8526                	mv	a0,s1
ffffffffc02009ec:	58c000ef          	jal	ra,ffffffffc0200f78 <free_pages>
ffffffffc02009f0:	649c                	ld	a5,8(s1)
ffffffffc02009f2:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && PageProperty(p1 + 1));
ffffffffc02009f4:	8b85                	andi	a5,a5,1
ffffffffc02009f6:	0c078b63          	beqz	a5,ffffffffc0200acc <buddy_check+0x182>
ffffffffc02009fa:	789c                	ld	a5,48(s1)
ffffffffc02009fc:	8385                	srli	a5,a5,0x1
ffffffffc02009fe:	8b85                	andi	a5,a5,1
ffffffffc0200a00:	c7f1                	beqz	a5,ffffffffc0200acc <buddy_check+0x182>
    assert(p1->ref == 0);
ffffffffc0200a02:	409c                	lw	a5,0(s1)
ffffffffc0200a04:	14079463          	bnez	a5,ffffffffc0200b4c <buddy_check+0x202>
    free_pages(p0, 1);
ffffffffc0200a08:	4585                	li	a1,1
ffffffffc0200a0a:	8522                	mv	a0,s0
ffffffffc0200a0c:	56c000ef          	jal	ra,ffffffffc0200f78 <free_pages>
    free_pages(p2, 1);
ffffffffc0200a10:	8552                	mv	a0,s4
ffffffffc0200a12:	4585                	li	a1,1
ffffffffc0200a14:	564000ef          	jal	ra,ffffffffc0200f78 <free_pages>
    // 回收后再分配
    p2 = alloc_pages(3);
ffffffffc0200a18:	450d                	li	a0,3
ffffffffc0200a1a:	51a000ef          	jal	ra,ffffffffc0200f34 <alloc_pages>
    assert(p2 == p0);
ffffffffc0200a1e:	16a41763          	bne	s0,a0,ffffffffc0200b8c <buddy_check+0x242>
    free_pages(p2, 3);
ffffffffc0200a22:	458d                	li	a1,3
ffffffffc0200a24:	554000ef          	jal	ra,ffffffffc0200f78 <free_pages>
    assert((p2 + 2)->ref == 0);
ffffffffc0200a28:	483c                	lw	a5,80(s0)
ffffffffc0200a2a:	14079163          	bnez	a5,ffffffffc0200b6c <buddy_check+0x222>
    assert(nr_free_pages() == all_pages >> 1);
ffffffffc0200a2e:	590000ef          	jal	ra,ffffffffc0200fbe <nr_free_pages>
ffffffffc0200a32:	40195913          	srai	s2,s2,0x1
ffffffffc0200a36:	0d251b63          	bne	a0,s2,ffffffffc0200b0c <buddy_check+0x1c2>

    p1 = alloc_pages(129);
ffffffffc0200a3a:	08100513          	li	a0,129
ffffffffc0200a3e:	4f6000ef          	jal	ra,ffffffffc0200f34 <alloc_pages>
    assert(p1 == p0 + 256);
ffffffffc0200a42:	678d                	lui	a5,0x3
ffffffffc0200a44:	80078793          	addi	a5,a5,-2048 # 2800 <BASE_ADDRESS-0xffffffffc01fd800>
ffffffffc0200a48:	943e                	add	s0,s0,a5
ffffffffc0200a4a:	1a851163          	bne	a0,s0,ffffffffc0200bec <buddy_check+0x2a2>
    free_pages(p1, 256);
ffffffffc0200a4e:	10000593          	li	a1,256
ffffffffc0200a52:	526000ef          	jal	ra,ffffffffc0200f78 <free_pages>
    free_pages(p3, 8);
}
ffffffffc0200a56:	7402                	ld	s0,32(sp)
ffffffffc0200a58:	70a2                	ld	ra,40(sp)
ffffffffc0200a5a:	64e2                	ld	s1,24(sp)
ffffffffc0200a5c:	6942                	ld	s2,16(sp)
ffffffffc0200a5e:	6a02                	ld	s4,0(sp)
    free_pages(p3, 8);
ffffffffc0200a60:	854e                	mv	a0,s3
}
ffffffffc0200a62:	69a2                	ld	s3,8(sp)
    free_pages(p3, 8);
ffffffffc0200a64:	45a1                	li	a1,8
}
ffffffffc0200a66:	6145                	addi	sp,sp,48
    free_pages(p3, 8);
ffffffffc0200a68:	5100006f          	j	ffffffffc0200f78 <free_pages>
    assert(!PageProperty(p3) && !PageProperty(p3 + 7) && PageProperty(p3 + 8));
ffffffffc0200a6c:	00001697          	auipc	a3,0x1
ffffffffc0200a70:	50c68693          	addi	a3,a3,1292 # ffffffffc0201f78 <commands+0x720>
ffffffffc0200a74:	00001617          	auipc	a2,0x1
ffffffffc0200a78:	41c60613          	addi	a2,a2,1052 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200a7c:	09100593          	li	a1,145
ffffffffc0200a80:	00001517          	auipc	a0,0x1
ffffffffc0200a84:	42850513          	addi	a0,a0,1064 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200a88:	925ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageReserved(p1) && !PageProperty(p1));
ffffffffc0200a8c:	00001697          	auipc	a3,0x1
ffffffffc0200a90:	4a468693          	addi	a3,a3,1188 # ffffffffc0201f30 <commands+0x6d8>
ffffffffc0200a94:	00001617          	auipc	a2,0x1
ffffffffc0200a98:	3fc60613          	addi	a2,a2,1020 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200a9c:	08b00593          	li	a1,139
ffffffffc0200aa0:	00001517          	auipc	a0,0x1
ffffffffc0200aa4:	40850513          	addi	a0,a0,1032 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200aa8:	905ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageReserved(p0) && !PageProperty(p0));
ffffffffc0200aac:	00001697          	auipc	a3,0x1
ffffffffc0200ab0:	45c68693          	addi	a3,a3,1116 # ffffffffc0201f08 <commands+0x6b0>
ffffffffc0200ab4:	00001617          	auipc	a2,0x1
ffffffffc0200ab8:	3dc60613          	addi	a2,a2,988 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200abc:	08a00593          	li	a1,138
ffffffffc0200ac0:	00001517          	auipc	a0,0x1
ffffffffc0200ac4:	3e850513          	addi	a0,a0,1000 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200ac8:	8e5ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(PageProperty(p1) && PageProperty(p1 + 1));
ffffffffc0200acc:	00001697          	auipc	a3,0x1
ffffffffc0200ad0:	4f468693          	addi	a3,a3,1268 # ffffffffc0201fc0 <commands+0x768>
ffffffffc0200ad4:	00001617          	auipc	a2,0x1
ffffffffc0200ad8:	3bc60613          	addi	a2,a2,956 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200adc:	09400593          	li	a1,148
ffffffffc0200ae0:	00001517          	auipc	a0,0x1
ffffffffc0200ae4:	3c850513          	addi	a0,a0,968 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200ae8:	8c5ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p2 == p0 + 1);
ffffffffc0200aec:	00001697          	auipc	a3,0x1
ffffffffc0200af0:	46c68693          	addi	a3,a3,1132 # ffffffffc0201f58 <commands+0x700>
ffffffffc0200af4:	00001617          	auipc	a2,0x1
ffffffffc0200af8:	39c60613          	addi	a2,a2,924 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200afc:	08e00593          	li	a1,142
ffffffffc0200b00:	00001517          	auipc	a0,0x1
ffffffffc0200b04:	3a850513          	addi	a0,a0,936 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200b08:	8a5ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free_pages() == all_pages >> 1);
ffffffffc0200b0c:	00001697          	auipc	a3,0x1
ffffffffc0200b10:	51c68693          	addi	a3,a3,1308 # ffffffffc0202028 <commands+0x7d0>
ffffffffc0200b14:	00001617          	auipc	a2,0x1
ffffffffc0200b18:	37c60613          	addi	a2,a2,892 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200b1c:	09d00593          	li	a1,157
ffffffffc0200b20:	00001517          	auipc	a0,0x1
ffffffffc0200b24:	38850513          	addi	a0,a0,904 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200b28:	885ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p1 == p0 + 2);
ffffffffc0200b2c:	00001697          	auipc	a3,0x1
ffffffffc0200b30:	3cc68693          	addi	a3,a3,972 # ffffffffc0201ef8 <commands+0x6a0>
ffffffffc0200b34:	00001617          	auipc	a2,0x1
ffffffffc0200b38:	35c60613          	addi	a2,a2,860 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200b3c:	08900593          	li	a1,137
ffffffffc0200b40:	00001517          	auipc	a0,0x1
ffffffffc0200b44:	36850513          	addi	a0,a0,872 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200b48:	865ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p1->ref == 0);
ffffffffc0200b4c:	00001697          	auipc	a3,0x1
ffffffffc0200b50:	4a468693          	addi	a3,a3,1188 # ffffffffc0201ff0 <commands+0x798>
ffffffffc0200b54:	00001617          	auipc	a2,0x1
ffffffffc0200b58:	33c60613          	addi	a2,a2,828 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200b5c:	09500593          	li	a1,149
ffffffffc0200b60:	00001517          	auipc	a0,0x1
ffffffffc0200b64:	34850513          	addi	a0,a0,840 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200b68:	845ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 + 2)->ref == 0);
ffffffffc0200b6c:	00001697          	auipc	a3,0x1
ffffffffc0200b70:	4a468693          	addi	a3,a3,1188 # ffffffffc0202010 <commands+0x7b8>
ffffffffc0200b74:	00001617          	auipc	a2,0x1
ffffffffc0200b78:	31c60613          	addi	a2,a2,796 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200b7c:	09c00593          	li	a1,156
ffffffffc0200b80:	00001517          	auipc	a0,0x1
ffffffffc0200b84:	32850513          	addi	a0,a0,808 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200b88:	825ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p2 == p0);
ffffffffc0200b8c:	00001697          	auipc	a3,0x1
ffffffffc0200b90:	47468693          	addi	a3,a3,1140 # ffffffffc0202000 <commands+0x7a8>
ffffffffc0200b94:	00001617          	auipc	a2,0x1
ffffffffc0200b98:	2fc60613          	addi	a2,a2,764 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200b9c:	09a00593          	li	a1,154
ffffffffc0200ba0:	00001517          	auipc	a0,0x1
ffffffffc0200ba4:	30850513          	addi	a0,a0,776 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200ba8:	805ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != NULL);
ffffffffc0200bac:	00001697          	auipc	a3,0x1
ffffffffc0200bb0:	33c68693          	addi	a3,a3,828 # ffffffffc0201ee8 <commands+0x690>
ffffffffc0200bb4:	00001617          	auipc	a2,0x1
ffffffffc0200bb8:	2dc60613          	addi	a2,a2,732 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200bbc:	08700593          	li	a1,135
ffffffffc0200bc0:	00001517          	auipc	a0,0x1
ffffffffc0200bc4:	2e850513          	addi	a0,a0,744 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200bc8:	fe4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_pages(all_pages + 1) == NULL);
ffffffffc0200bcc:	00001697          	auipc	a3,0x1
ffffffffc0200bd0:	2f468693          	addi	a3,a3,756 # ffffffffc0201ec0 <commands+0x668>
ffffffffc0200bd4:	00001617          	auipc	a2,0x1
ffffffffc0200bd8:	2bc60613          	addi	a2,a2,700 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200bdc:	08400593          	li	a1,132
ffffffffc0200be0:	00001517          	auipc	a0,0x1
ffffffffc0200be4:	2c850513          	addi	a0,a0,712 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200be8:	fc4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p1 == p0 + 256);
ffffffffc0200bec:	00001697          	auipc	a3,0x1
ffffffffc0200bf0:	46468693          	addi	a3,a3,1124 # ffffffffc0202050 <commands+0x7f8>
ffffffffc0200bf4:	00001617          	auipc	a2,0x1
ffffffffc0200bf8:	29c60613          	addi	a2,a2,668 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200bfc:	0a000593          	li	a1,160
ffffffffc0200c00:	00001517          	auipc	a0,0x1
ffffffffc0200c04:	2a850513          	addi	a0,a0,680 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200c08:	fa4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p3 == p0 + 8);
ffffffffc0200c0c:	00001697          	auipc	a3,0x1
ffffffffc0200c10:	35c68693          	addi	a3,a3,860 # ffffffffc0201f68 <commands+0x710>
ffffffffc0200c14:	00001617          	auipc	a2,0x1
ffffffffc0200c18:	27c60613          	addi	a2,a2,636 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200c1c:	09000593          	li	a1,144
ffffffffc0200c20:	00001517          	auipc	a0,0x1
ffffffffc0200c24:	28850513          	addi	a0,a0,648 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200c28:	f84ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200c2c <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200c2c:	1141                	addi	sp,sp,-16
ffffffffc0200c2e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200c30:	10058863          	beqz	a1,ffffffffc0200d40 <buddy_free_pages+0x114>
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc0200c34:	00259793          	slli	a5,a1,0x2
ffffffffc0200c38:	00b786b3          	add	a3,a5,a1
ffffffffc0200c3c:	068e                	slli	a3,a3,0x3
ffffffffc0200c3e:	96aa                	add	a3,a3,a0
ffffffffc0200c40:	02d50c63          	beq	a0,a3,ffffffffc0200c78 <buddy_free_pages+0x4c>
ffffffffc0200c44:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200c46:	8b85                	andi	a5,a5,1
ffffffffc0200c48:	efe1                	bnez	a5,ffffffffc0200d20 <buddy_free_pages+0xf4>
ffffffffc0200c4a:	651c                	ld	a5,8(a0)
ffffffffc0200c4c:	8385                	srli	a5,a5,0x1
ffffffffc0200c4e:	8b85                	andi	a5,a5,1
ffffffffc0200c50:	ebe1                	bnez	a5,ffffffffc0200d20 <buddy_free_pages+0xf4>
ffffffffc0200c52:	87aa                	mv	a5,a0
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200c54:	4609                	li	a2,2
ffffffffc0200c56:	a039                	j	ffffffffc0200c64 <buddy_free_pages+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c58:	6798                	ld	a4,8(a5)
ffffffffc0200c5a:	8b05                	andi	a4,a4,1
ffffffffc0200c5c:	e371                	bnez	a4,ffffffffc0200d20 <buddy_free_pages+0xf4>
ffffffffc0200c5e:	6798                	ld	a4,8(a5)
ffffffffc0200c60:	8b09                	andi	a4,a4,2
ffffffffc0200c62:	ef5d                	bnez	a4,ffffffffc0200d20 <buddy_free_pages+0xf4>
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200c64:	00878713          	addi	a4,a5,8
ffffffffc0200c68:	40c7302f          	amoor.d	zero,a2,(a4)
ffffffffc0200c6c:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc0200c70:	02878793          	addi	a5,a5,40
ffffffffc0200c74:	fed792e3          	bne	a5,a3,ffffffffc0200c58 <buddy_free_pages+0x2c>
    unsigned int index = useable_page_num + (unsigned int)(base - useable_page_base), size = 1;
ffffffffc0200c78:	00005797          	auipc	a5,0x5
ffffffffc0200c7c:	7b078793          	addi	a5,a5,1968 # ffffffffc0206428 <useable_page_base>
ffffffffc0200c80:	639c                	ld	a5,0(a5)
ffffffffc0200c82:	00001717          	auipc	a4,0x1
ffffffffc0200c86:	3de70713          	addi	a4,a4,990 # ffffffffc0202060 <commands+0x808>
ffffffffc0200c8a:	6318                	ld	a4,0(a4)
ffffffffc0200c8c:	40f507b3          	sub	a5,a0,a5
ffffffffc0200c90:	878d                	srai	a5,a5,0x3
ffffffffc0200c92:	02e78733          	mul	a4,a5,a4
ffffffffc0200c96:	00005797          	auipc	a5,0x5
ffffffffc0200c9a:	79a78793          	addi	a5,a5,1946 # ffffffffc0206430 <useable_page_num>
ffffffffc0200c9e:	439c                	lw	a5,0(a5)
    while(buddy_page[index] > 0){
ffffffffc0200ca0:	00005697          	auipc	a3,0x5
ffffffffc0200ca4:	77868693          	addi	a3,a3,1912 # ffffffffc0206418 <buddy_page>
ffffffffc0200ca8:	628c                	ld	a1,0(a3)
    unsigned int index = useable_page_num + (unsigned int)(base - useable_page_base), size = 1;
ffffffffc0200caa:	4605                	li	a2,1
ffffffffc0200cac:	9fb9                	addw	a5,a5,a4
    while(buddy_page[index] > 0){
ffffffffc0200cae:	02079713          	slli	a4,a5,0x20
ffffffffc0200cb2:	8379                	srli	a4,a4,0x1e
ffffffffc0200cb4:	972e                	add	a4,a4,a1
ffffffffc0200cb6:	4314                	lw	a3,0(a4)
ffffffffc0200cb8:	ca99                	beqz	a3,ffffffffc0200cce <buddy_free_pages+0xa2>
        index=PARENT(index);
ffffffffc0200cba:	0017d79b          	srliw	a5,a5,0x1
    while(buddy_page[index] > 0){
ffffffffc0200cbe:	02079713          	slli	a4,a5,0x20
ffffffffc0200cc2:	8379                	srli	a4,a4,0x1e
ffffffffc0200cc4:	972e                	add	a4,a4,a1
ffffffffc0200cc6:	4314                	lw	a3,0(a4)
        size <<= 1;
ffffffffc0200cc8:	0016161b          	slliw	a2,a2,0x1
    while(buddy_page[index] > 0){
ffffffffc0200ccc:	f6fd                	bnez	a3,ffffffffc0200cba <buddy_free_pages+0x8e>
    buddy_page[index] = size;
ffffffffc0200cce:	c310                	sw	a2,0(a4)
    while((index = PARENT(index)) > 0){
ffffffffc0200cd0:	a081                	j	ffffffffc0200d10 <buddy_free_pages+0xe4>
        if(buddy_page[LEFT_CHILD(index)] + buddy_page[RIGHT_CHILD(index)] == size){
ffffffffc0200cd2:	9bf9                	andi	a5,a5,-2
ffffffffc0200cd4:	2781                	sext.w	a5,a5
ffffffffc0200cd6:	0017869b          	addiw	a3,a5,1
ffffffffc0200cda:	1682                	slli	a3,a3,0x20
ffffffffc0200cdc:	1782                	slli	a5,a5,0x20
ffffffffc0200cde:	9381                	srli	a5,a5,0x20
ffffffffc0200ce0:	9281                	srli	a3,a3,0x20
ffffffffc0200ce2:	078a                	slli	a5,a5,0x2
ffffffffc0200ce4:	068a                	slli	a3,a3,0x2
ffffffffc0200ce6:	97ae                	add	a5,a5,a1
ffffffffc0200ce8:	96ae                	add	a3,a3,a1
ffffffffc0200cea:	439c                	lw	a5,0(a5)
ffffffffc0200cec:	4294                	lw	a3,0(a3)
ffffffffc0200cee:	1702                	slli	a4,a4,0x20
        size <<= 1;
ffffffffc0200cf0:	0016161b          	slliw	a2,a2,0x1
ffffffffc0200cf4:	8379                	srli	a4,a4,0x1e
        if(buddy_page[LEFT_CHILD(index)] + buddy_page[RIGHT_CHILD(index)] == size){
ffffffffc0200cf6:	00d788bb          	addw	a7,a5,a3
        size <<= 1;
ffffffffc0200cfa:	8832                	mv	a6,a2
ffffffffc0200cfc:	972e                	add	a4,a4,a1
        if(buddy_page[LEFT_CHILD(index)] + buddy_page[RIGHT_CHILD(index)] == size){
ffffffffc0200cfe:	00c88663          	beq	a7,a2,ffffffffc0200d0a <buddy_free_pages+0xde>
            buddy_page[index] = MAX(buddy_page[LEFT_CHILD(index)], buddy_page[RIGHT_CHILD(index)]);
ffffffffc0200d02:	883e                	mv	a6,a5
ffffffffc0200d04:	00d7f363          	bleu	a3,a5,ffffffffc0200d0a <buddy_free_pages+0xde>
ffffffffc0200d08:	8836                	mv	a6,a3
ffffffffc0200d0a:	01072023          	sw	a6,0(a4)
ffffffffc0200d0e:	87aa                	mv	a5,a0
    while((index = PARENT(index)) > 0){
ffffffffc0200d10:	0017d71b          	srliw	a4,a5,0x1
ffffffffc0200d14:	0007051b          	sext.w	a0,a4
ffffffffc0200d18:	fd4d                	bnez	a0,ffffffffc0200cd2 <buddy_free_pages+0xa6>
}
ffffffffc0200d1a:	60a2                	ld	ra,8(sp)
ffffffffc0200d1c:	0141                	addi	sp,sp,16
ffffffffc0200d1e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d20:	00001697          	auipc	a3,0x1
ffffffffc0200d24:	34868693          	addi	a3,a3,840 # ffffffffc0202068 <commands+0x810>
ffffffffc0200d28:	00001617          	auipc	a2,0x1
ffffffffc0200d2c:	16860613          	addi	a2,a2,360 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200d30:	06400593          	li	a1,100
ffffffffc0200d34:	00001517          	auipc	a0,0x1
ffffffffc0200d38:	17450513          	addi	a0,a0,372 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200d3c:	e70ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc0200d40:	00001697          	auipc	a3,0x1
ffffffffc0200d44:	14868693          	addi	a3,a3,328 # ffffffffc0201e88 <commands+0x630>
ffffffffc0200d48:	00001617          	auipc	a2,0x1
ffffffffc0200d4c:	14860613          	addi	a2,a2,328 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200d50:	06100593          	li	a1,97
ffffffffc0200d54:	00001517          	auipc	a0,0x1
ffffffffc0200d58:	15450513          	addi	a0,a0,340 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200d5c:	e50ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200d60 <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200d60:	1141                	addi	sp,sp,-16
ffffffffc0200d62:	e406                	sd	ra,8(sp)
    assert((n > 0));
ffffffffc0200d64:	1a058963          	beqz	a1,ffffffffc0200f16 <buddy_init_memmap+0x1b6>
    useable_page_num = 1;
ffffffffc0200d68:	46f5                	li	a3,29
ffffffffc0200d6a:	4601                	li	a2,0
ffffffffc0200d6c:	4705                	li	a4,1
ffffffffc0200d6e:	a801                	j	ffffffffc0200d7e <buddy_init_memmap+0x1e>
        /* do nothing */;
ffffffffc0200d70:	36fd                	addiw	a3,a3,-1
         i++, useable_page_num <<= 1)
ffffffffc0200d72:	0017179b          	slliw	a5,a4,0x1
ffffffffc0200d76:	4605                	li	a2,1
    for (int i = 1;
ffffffffc0200d78:	16068363          	beqz	a3,ffffffffc0200ede <buddy_init_memmap+0x17e>
         i++, useable_page_num <<= 1)
ffffffffc0200d7c:	873e                	mv	a4,a5
         (i < BUDDY_MAX_DEPTH) && (useable_page_num + (useable_page_num >> 9) < n);
ffffffffc0200d7e:	0097579b          	srliw	a5,a4,0x9
ffffffffc0200d82:	9fb9                	addw	a5,a5,a4
ffffffffc0200d84:	1782                	slli	a5,a5,0x20
ffffffffc0200d86:	9381                	srli	a5,a5,0x20
ffffffffc0200d88:	feb7e4e3          	bltu	a5,a1,ffffffffc0200d70 <buddy_init_memmap+0x10>
ffffffffc0200d8c:	14060463          	beqz	a2,ffffffffc0200ed4 <buddy_init_memmap+0x174>
ffffffffc0200d90:	00a7579b          	srliw	a5,a4,0xa
ffffffffc0200d94:	2785                	addiw	a5,a5,1
ffffffffc0200d96:	02079693          	slli	a3,a5,0x20
ffffffffc0200d9a:	9281                	srli	a3,a3,0x20
ffffffffc0200d9c:	00269613          	slli	a2,a3,0x2
ffffffffc0200da0:	9636                	add	a2,a2,a3
ffffffffc0200da2:	0017571b          	srliw	a4,a4,0x1
ffffffffc0200da6:	060e                	slli	a2,a2,0x3
    useable_page_base = base + buddy_page_num;
ffffffffc0200da8:	962a                	add	a2,a2,a0
    useable_page_num >>= 1;
ffffffffc0200daa:	00005817          	auipc	a6,0x5
ffffffffc0200dae:	68e82323          	sw	a4,1670(a6) # ffffffffc0206430 <useable_page_num>
    buddy_page_num = (useable_page_num >> 9) + 1;
ffffffffc0200db2:	00850693          	addi	a3,a0,8
ffffffffc0200db6:	00005717          	auipc	a4,0x5
ffffffffc0200dba:	66f72523          	sw	a5,1642(a4) # ffffffffc0206420 <buddy_page_num>
    useable_page_base = base + buddy_page_num;
ffffffffc0200dbe:	00005797          	auipc	a5,0x5
ffffffffc0200dc2:	66c7b523          	sd	a2,1642(a5) # ffffffffc0206428 <useable_page_base>
    for (int i = 0; i != buddy_page_num; i++){
ffffffffc0200dc6:	8736                	mv	a4,a3
ffffffffc0200dc8:	4781                	li	a5,0
ffffffffc0200dca:	00005897          	auipc	a7,0x5
ffffffffc0200dce:	65688893          	addi	a7,a7,1622 # ffffffffc0206420 <buddy_page_num>
ffffffffc0200dd2:	4805                	li	a6,1
ffffffffc0200dd4:	4107302f          	amoor.d	zero,a6,(a4)
ffffffffc0200dd8:	0008a603          	lw	a2,0(a7)
ffffffffc0200ddc:	2785                	addiw	a5,a5,1
ffffffffc0200dde:	02870713          	addi	a4,a4,40
ffffffffc0200de2:	fef619e3          	bne	a2,a5,ffffffffc0200dd4 <buddy_init_memmap+0x74>
    for (int i = buddy_page_num; i != n; i++){
ffffffffc0200de6:	02079713          	slli	a4,a5,0x20
ffffffffc0200dea:	9301                	srli	a4,a4,0x20
ffffffffc0200dec:	02e58963          	beq	a1,a4,ffffffffc0200e1e <buddy_init_memmap+0xbe>
ffffffffc0200df0:	00271793          	slli	a5,a4,0x2
ffffffffc0200df4:	97ba                	add	a5,a5,a4
ffffffffc0200df6:	00259713          	slli	a4,a1,0x2
ffffffffc0200dfa:	95ba                	add	a1,a1,a4
ffffffffc0200dfc:	078e                	slli	a5,a5,0x3
ffffffffc0200dfe:	07a1                	addi	a5,a5,8
ffffffffc0200e00:	058e                	slli	a1,a1,0x3
ffffffffc0200e02:	95b6                	add	a1,a1,a3
ffffffffc0200e04:	97aa                	add	a5,a5,a0
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200e06:	56f9                	li	a3,-2
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200e08:	4709                	li	a4,2
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200e0a:	60d7b02f          	amoand.d	zero,a3,(a5)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200e0e:	40e7b02f          	amoor.d	zero,a4,(a5)
ffffffffc0200e12:	fe07ac23          	sw	zero,-8(a5)
ffffffffc0200e16:	02878793          	addi	a5,a5,40
ffffffffc0200e1a:	fef598e3          	bne	a1,a5,ffffffffc0200e0a <buddy_init_memmap+0xaa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e1e:	00005797          	auipc	a5,0x5
ffffffffc0200e22:	65278793          	addi	a5,a5,1618 # ffffffffc0206470 <pages>
ffffffffc0200e26:	639c                	ld	a5,0(a5)
    buddy_page = (unsigned int*)KADDR(page2pa(base));
ffffffffc0200e28:	00005717          	auipc	a4,0x5
ffffffffc0200e2c:	61070713          	addi	a4,a4,1552 # ffffffffc0206438 <npage>
ffffffffc0200e30:	6318                	ld	a4,0(a4)
ffffffffc0200e32:	40f506b3          	sub	a3,a0,a5
ffffffffc0200e36:	00001797          	auipc	a5,0x1
ffffffffc0200e3a:	22a78793          	addi	a5,a5,554 # ffffffffc0202060 <commands+0x808>
ffffffffc0200e3e:	639c                	ld	a5,0(a5)
ffffffffc0200e40:	868d                	srai	a3,a3,0x3
ffffffffc0200e42:	02f686b3          	mul	a3,a3,a5
ffffffffc0200e46:	00001797          	auipc	a5,0x1
ffffffffc0200e4a:	63a78793          	addi	a5,a5,1594 # ffffffffc0202480 <nbase>
ffffffffc0200e4e:	639c                	ld	a5,0(a5)
ffffffffc0200e50:	96be                	add	a3,a3,a5
ffffffffc0200e52:	57fd                	li	a5,-1
ffffffffc0200e54:	83b1                	srli	a5,a5,0xc
ffffffffc0200e56:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e58:	06b2                	slli	a3,a3,0xc
ffffffffc0200e5a:	0ae7f263          	bleu	a4,a5,ffffffffc0200efe <buddy_init_memmap+0x19e>
ffffffffc0200e5e:	00005717          	auipc	a4,0x5
ffffffffc0200e62:	60a70713          	addi	a4,a4,1546 # ffffffffc0206468 <va_pa_offset>
ffffffffc0200e66:	6318                	ld	a4,0(a4)
    for (int i = useable_page_num; i < useable_page_num << 1; i++){
ffffffffc0200e68:	00005797          	auipc	a5,0x5
ffffffffc0200e6c:	5c878793          	addi	a5,a5,1480 # ffffffffc0206430 <useable_page_num>
ffffffffc0200e70:	439c                	lw	a5,0(a5)
    buddy_page = (unsigned int*)KADDR(page2pa(base));
ffffffffc0200e72:	96ba                	add	a3,a3,a4
ffffffffc0200e74:	00005717          	auipc	a4,0x5
ffffffffc0200e78:	5ad73223          	sd	a3,1444(a4) # ffffffffc0206418 <buddy_page>
    for (int i = useable_page_num; i < useable_page_num << 1; i++){
ffffffffc0200e7c:	0017959b          	slliw	a1,a5,0x1
ffffffffc0200e80:	0007871b          	sext.w	a4,a5
ffffffffc0200e84:	02b7f263          	bleu	a1,a5,ffffffffc0200ea8 <buddy_init_memmap+0x148>
ffffffffc0200e88:	40f5863b          	subw	a2,a1,a5
ffffffffc0200e8c:	367d                	addiw	a2,a2,-1
ffffffffc0200e8e:	1602                	slli	a2,a2,0x20
ffffffffc0200e90:	9201                	srli	a2,a2,0x20
ffffffffc0200e92:	963a                	add	a2,a2,a4
ffffffffc0200e94:	0605                	addi	a2,a2,1
ffffffffc0200e96:	070a                	slli	a4,a4,0x2
ffffffffc0200e98:	060a                	slli	a2,a2,0x2
ffffffffc0200e9a:	9736                	add	a4,a4,a3
ffffffffc0200e9c:	9636                	add	a2,a2,a3
        buddy_page[i] = 1;
ffffffffc0200e9e:	4585                	li	a1,1
ffffffffc0200ea0:	c30c                	sw	a1,0(a4)
ffffffffc0200ea2:	0711                	addi	a4,a4,4
    for (int i = useable_page_num; i < useable_page_num << 1; i++){
ffffffffc0200ea4:	fee61ee3          	bne	a2,a4,ffffffffc0200ea0 <buddy_init_memmap+0x140>
    for (int i = useable_page_num - 1; i > 0; i--){
ffffffffc0200ea8:	fff7861b          	addiw	a2,a5,-1
ffffffffc0200eac:	02c05163          	blez	a2,ffffffffc0200ece <buddy_init_memmap+0x16e>
ffffffffc0200eb0:	0017979b          	slliw	a5,a5,0x1
ffffffffc0200eb4:	060a                	slli	a2,a2,0x2
ffffffffc0200eb6:	37f9                	addiw	a5,a5,-2
ffffffffc0200eb8:	9636                	add	a2,a2,a3
        buddy_page[i] = buddy_page[i << 1] << 1;
ffffffffc0200eba:	00279713          	slli	a4,a5,0x2
ffffffffc0200ebe:	9736                	add	a4,a4,a3
ffffffffc0200ec0:	4318                	lw	a4,0(a4)
ffffffffc0200ec2:	1671                	addi	a2,a2,-4
ffffffffc0200ec4:	37f9                	addiw	a5,a5,-2
ffffffffc0200ec6:	0017171b          	slliw	a4,a4,0x1
ffffffffc0200eca:	c258                	sw	a4,4(a2)
    for (int i = useable_page_num - 1; i > 0; i--){
ffffffffc0200ecc:	f7fd                	bnez	a5,ffffffffc0200eba <buddy_init_memmap+0x15a>
}
ffffffffc0200ece:	60a2                	ld	ra,8(sp)
ffffffffc0200ed0:	0141                	addi	sp,sp,16
ffffffffc0200ed2:	8082                	ret
         (i < BUDDY_MAX_DEPTH) && (useable_page_num + (useable_page_num >> 9) < n);
ffffffffc0200ed4:	02800613          	li	a2,40
ffffffffc0200ed8:	4785                	li	a5,1
ffffffffc0200eda:	4701                	li	a4,0
ffffffffc0200edc:	b5f1                	j	ffffffffc0200da8 <buddy_init_memmap+0x48>
ffffffffc0200ede:	00a7d79b          	srliw	a5,a5,0xa
ffffffffc0200ee2:	2785                	addiw	a5,a5,1
ffffffffc0200ee4:	02079693          	slli	a3,a5,0x20
ffffffffc0200ee8:	9281                	srli	a3,a3,0x20
ffffffffc0200eea:	00269613          	slli	a2,a3,0x2
ffffffffc0200eee:	9636                	add	a2,a2,a3
ffffffffc0200ef0:	800006b7          	lui	a3,0x80000
ffffffffc0200ef4:	fff6c693          	not	a3,a3
ffffffffc0200ef8:	8f75                	and	a4,a4,a3
ffffffffc0200efa:	060e                	slli	a2,a2,0x3
ffffffffc0200efc:	b575                	j	ffffffffc0200da8 <buddy_init_memmap+0x48>
    buddy_page = (unsigned int*)KADDR(page2pa(base));
ffffffffc0200efe:	00001617          	auipc	a2,0x1
ffffffffc0200f02:	19a60613          	addi	a2,a2,410 # ffffffffc0202098 <commands+0x840>
ffffffffc0200f06:	02e00593          	li	a1,46
ffffffffc0200f0a:	00001517          	auipc	a0,0x1
ffffffffc0200f0e:	f9e50513          	addi	a0,a0,-98 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200f12:	c9aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((n > 0));
ffffffffc0200f16:	00001697          	auipc	a3,0x1
ffffffffc0200f1a:	17a68693          	addi	a3,a3,378 # ffffffffc0202090 <commands+0x838>
ffffffffc0200f1e:	00001617          	auipc	a2,0x1
ffffffffc0200f22:	f7260613          	addi	a2,a2,-142 # ffffffffc0201e90 <commands+0x638>
ffffffffc0200f26:	45e5                	li	a1,25
ffffffffc0200f28:	00001517          	auipc	a0,0x1
ffffffffc0200f2c:	f8050513          	addi	a0,a0,-128 # ffffffffc0201ea8 <commands+0x650>
ffffffffc0200f30:	c7cff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200f34 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200f34:	100027f3          	csrr	a5,sstatus
ffffffffc0200f38:	8b89                	andi	a5,a5,2
ffffffffc0200f3a:	eb89                	bnez	a5,ffffffffc0200f4c <alloc_pages+0x18>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200f3c:	00005797          	auipc	a5,0x5
ffffffffc0200f40:	52478793          	addi	a5,a5,1316 # ffffffffc0206460 <pmm_manager>
ffffffffc0200f44:	639c                	ld	a5,0(a5)
ffffffffc0200f46:	0187b303          	ld	t1,24(a5)
ffffffffc0200f4a:	8302                	jr	t1
struct Page *alloc_pages(size_t n) {
ffffffffc0200f4c:	1141                	addi	sp,sp,-16
ffffffffc0200f4e:	e406                	sd	ra,8(sp)
ffffffffc0200f50:	e022                	sd	s0,0(sp)
ffffffffc0200f52:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200f54:	d10ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200f58:	00005797          	auipc	a5,0x5
ffffffffc0200f5c:	50878793          	addi	a5,a5,1288 # ffffffffc0206460 <pmm_manager>
ffffffffc0200f60:	639c                	ld	a5,0(a5)
ffffffffc0200f62:	8522                	mv	a0,s0
ffffffffc0200f64:	6f9c                	ld	a5,24(a5)
ffffffffc0200f66:	9782                	jalr	a5
ffffffffc0200f68:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0200f6a:	cf4ff0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200f6e:	8522                	mv	a0,s0
ffffffffc0200f70:	60a2                	ld	ra,8(sp)
ffffffffc0200f72:	6402                	ld	s0,0(sp)
ffffffffc0200f74:	0141                	addi	sp,sp,16
ffffffffc0200f76:	8082                	ret

ffffffffc0200f78 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200f78:	100027f3          	csrr	a5,sstatus
ffffffffc0200f7c:	8b89                	andi	a5,a5,2
ffffffffc0200f7e:	eb89                	bnez	a5,ffffffffc0200f90 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200f80:	00005797          	auipc	a5,0x5
ffffffffc0200f84:	4e078793          	addi	a5,a5,1248 # ffffffffc0206460 <pmm_manager>
ffffffffc0200f88:	639c                	ld	a5,0(a5)
ffffffffc0200f8a:	0207b303          	ld	t1,32(a5)
ffffffffc0200f8e:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc0200f90:	1101                	addi	sp,sp,-32
ffffffffc0200f92:	ec06                	sd	ra,24(sp)
ffffffffc0200f94:	e822                	sd	s0,16(sp)
ffffffffc0200f96:	e426                	sd	s1,8(sp)
ffffffffc0200f98:	842a                	mv	s0,a0
ffffffffc0200f9a:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200f9c:	cc8ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200fa0:	00005797          	auipc	a5,0x5
ffffffffc0200fa4:	4c078793          	addi	a5,a5,1216 # ffffffffc0206460 <pmm_manager>
ffffffffc0200fa8:	639c                	ld	a5,0(a5)
ffffffffc0200faa:	85a6                	mv	a1,s1
ffffffffc0200fac:	8522                	mv	a0,s0
ffffffffc0200fae:	739c                	ld	a5,32(a5)
ffffffffc0200fb0:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200fb2:	6442                	ld	s0,16(sp)
ffffffffc0200fb4:	60e2                	ld	ra,24(sp)
ffffffffc0200fb6:	64a2                	ld	s1,8(sp)
ffffffffc0200fb8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200fba:	ca4ff06f          	j	ffffffffc020045e <intr_enable>

ffffffffc0200fbe <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200fbe:	100027f3          	csrr	a5,sstatus
ffffffffc0200fc2:	8b89                	andi	a5,a5,2
ffffffffc0200fc4:	eb89                	bnez	a5,ffffffffc0200fd6 <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200fc6:	00005797          	auipc	a5,0x5
ffffffffc0200fca:	49a78793          	addi	a5,a5,1178 # ffffffffc0206460 <pmm_manager>
ffffffffc0200fce:	639c                	ld	a5,0(a5)
ffffffffc0200fd0:	0287b303          	ld	t1,40(a5)
ffffffffc0200fd4:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc0200fd6:	1141                	addi	sp,sp,-16
ffffffffc0200fd8:	e406                	sd	ra,8(sp)
ffffffffc0200fda:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200fdc:	c88ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200fe0:	00005797          	auipc	a5,0x5
ffffffffc0200fe4:	48078793          	addi	a5,a5,1152 # ffffffffc0206460 <pmm_manager>
ffffffffc0200fe8:	639c                	ld	a5,0(a5)
ffffffffc0200fea:	779c                	ld	a5,40(a5)
ffffffffc0200fec:	9782                	jalr	a5
ffffffffc0200fee:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200ff0:	c6eff0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200ff4:	8522                	mv	a0,s0
ffffffffc0200ff6:	60a2                	ld	ra,8(sp)
ffffffffc0200ff8:	6402                	ld	s0,0(sp)
ffffffffc0200ffa:	0141                	addi	sp,sp,16
ffffffffc0200ffc:	8082                	ret

ffffffffc0200ffe <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200ffe:	00001797          	auipc	a5,0x1
ffffffffc0201002:	0c278793          	addi	a5,a5,194 # ffffffffc02020c0 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201006:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201008:	1101                	addi	sp,sp,-32
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020100a:	00001517          	auipc	a0,0x1
ffffffffc020100e:	10650513          	addi	a0,a0,262 # ffffffffc0202110 <buddy_pmm_manager+0x50>
void pmm_init(void) {
ffffffffc0201012:	ec06                	sd	ra,24(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0201014:	00005717          	auipc	a4,0x5
ffffffffc0201018:	44f73623          	sd	a5,1100(a4) # ffffffffc0206460 <pmm_manager>
void pmm_init(void) {
ffffffffc020101c:	e822                	sd	s0,16(sp)
ffffffffc020101e:	e426                	sd	s1,8(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0201020:	00005417          	auipc	s0,0x5
ffffffffc0201024:	44040413          	addi	s0,s0,1088 # ffffffffc0206460 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201028:	88eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pmm_manager->init();
ffffffffc020102c:	601c                	ld	a5,0(s0)
ffffffffc020102e:	679c                	ld	a5,8(a5)
ffffffffc0201030:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201032:	57f5                	li	a5,-3
ffffffffc0201034:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201036:	00001517          	auipc	a0,0x1
ffffffffc020103a:	0f250513          	addi	a0,a0,242 # ffffffffc0202128 <buddy_pmm_manager+0x68>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020103e:	00005717          	auipc	a4,0x5
ffffffffc0201042:	42f73523          	sd	a5,1066(a4) # ffffffffc0206468 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc0201046:	870ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020104a:	46c5                	li	a3,17
ffffffffc020104c:	06ee                	slli	a3,a3,0x1b
ffffffffc020104e:	40100613          	li	a2,1025
ffffffffc0201052:	16fd                	addi	a3,a3,-1
ffffffffc0201054:	0656                	slli	a2,a2,0x15
ffffffffc0201056:	07e005b7          	lui	a1,0x7e00
ffffffffc020105a:	00001517          	auipc	a0,0x1
ffffffffc020105e:	0e650513          	addi	a0,a0,230 # ffffffffc0202140 <buddy_pmm_manager+0x80>
ffffffffc0201062:	854ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201066:	777d                	lui	a4,0xfffff
ffffffffc0201068:	00006797          	auipc	a5,0x6
ffffffffc020106c:	40f78793          	addi	a5,a5,1039 # ffffffffc0207477 <end+0xfff>
ffffffffc0201070:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201072:	00088737          	lui	a4,0x88
ffffffffc0201076:	00005697          	auipc	a3,0x5
ffffffffc020107a:	3ce6b123          	sd	a4,962(a3) # ffffffffc0206438 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020107e:	4601                	li	a2,0
ffffffffc0201080:	00005717          	auipc	a4,0x5
ffffffffc0201084:	3ef73823          	sd	a5,1008(a4) # ffffffffc0206470 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201088:	4681                	li	a3,0
ffffffffc020108a:	00005897          	auipc	a7,0x5
ffffffffc020108e:	3ae88893          	addi	a7,a7,942 # ffffffffc0206438 <npage>
ffffffffc0201092:	00005597          	auipc	a1,0x5
ffffffffc0201096:	3de58593          	addi	a1,a1,990 # ffffffffc0206470 <pages>
ffffffffc020109a:	4805                	li	a6,1
ffffffffc020109c:	fff80537          	lui	a0,0xfff80
ffffffffc02010a0:	a011                	j	ffffffffc02010a4 <pmm_init+0xa6>
ffffffffc02010a2:	619c                	ld	a5,0(a1)
        SetPageReserved(pages + i);
ffffffffc02010a4:	97b2                	add	a5,a5,a2
ffffffffc02010a6:	07a1                	addi	a5,a5,8
ffffffffc02010a8:	4107b02f          	amoor.d	zero,a6,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010ac:	0008b703          	ld	a4,0(a7)
ffffffffc02010b0:	0685                	addi	a3,a3,1
ffffffffc02010b2:	02860613          	addi	a2,a2,40
ffffffffc02010b6:	00a707b3          	add	a5,a4,a0
ffffffffc02010ba:	fef6e4e3          	bltu	a3,a5,ffffffffc02010a2 <pmm_init+0xa4>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010be:	6190                	ld	a2,0(a1)
ffffffffc02010c0:	00271793          	slli	a5,a4,0x2
ffffffffc02010c4:	97ba                	add	a5,a5,a4
ffffffffc02010c6:	fec006b7          	lui	a3,0xfec00
ffffffffc02010ca:	078e                	slli	a5,a5,0x3
ffffffffc02010cc:	96b2                	add	a3,a3,a2
ffffffffc02010ce:	96be                	add	a3,a3,a5
ffffffffc02010d0:	c02007b7          	lui	a5,0xc0200
ffffffffc02010d4:	08f6e863          	bltu	a3,a5,ffffffffc0201164 <pmm_init+0x166>
ffffffffc02010d8:	00005497          	auipc	s1,0x5
ffffffffc02010dc:	39048493          	addi	s1,s1,912 # ffffffffc0206468 <va_pa_offset>
ffffffffc02010e0:	609c                	ld	a5,0(s1)
    if (freemem < mem_end) {
ffffffffc02010e2:	45c5                	li	a1,17
ffffffffc02010e4:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010e6:	8e9d                	sub	a3,a3,a5
    if (freemem < mem_end) {
ffffffffc02010e8:	04b6e963          	bltu	a3,a1,ffffffffc020113a <pmm_init+0x13c>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02010ec:	601c                	ld	a5,0(s0)
ffffffffc02010ee:	7b9c                	ld	a5,48(a5)
ffffffffc02010f0:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02010f2:	00001517          	auipc	a0,0x1
ffffffffc02010f6:	0e650513          	addi	a0,a0,230 # ffffffffc02021d8 <buddy_pmm_manager+0x118>
ffffffffc02010fa:	fbdfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02010fe:	00004697          	auipc	a3,0x4
ffffffffc0201102:	f0268693          	addi	a3,a3,-254 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201106:	00005797          	auipc	a5,0x5
ffffffffc020110a:	32d7bd23          	sd	a3,826(a5) # ffffffffc0206440 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020110e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201112:	06f6e563          	bltu	a3,a5,ffffffffc020117c <pmm_init+0x17e>
ffffffffc0201116:	609c                	ld	a5,0(s1)
}
ffffffffc0201118:	6442                	ld	s0,16(sp)
ffffffffc020111a:	60e2                	ld	ra,24(sp)
ffffffffc020111c:	64a2                	ld	s1,8(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020111e:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc0201120:	8e9d                	sub	a3,a3,a5
ffffffffc0201122:	00005797          	auipc	a5,0x5
ffffffffc0201126:	32d7bb23          	sd	a3,822(a5) # ffffffffc0206458 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020112a:	00001517          	auipc	a0,0x1
ffffffffc020112e:	0ce50513          	addi	a0,a0,206 # ffffffffc02021f8 <buddy_pmm_manager+0x138>
ffffffffc0201132:	8636                	mv	a2,a3
}
ffffffffc0201134:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201136:	f81fe06f          	j	ffffffffc02000b6 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020113a:	6785                	lui	a5,0x1
ffffffffc020113c:	17fd                	addi	a5,a5,-1
ffffffffc020113e:	96be                	add	a3,a3,a5
ffffffffc0201140:	77fd                	lui	a5,0xfffff
ffffffffc0201142:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201144:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201148:	04e7f663          	bleu	a4,a5,ffffffffc0201194 <pmm_init+0x196>
    pmm_manager->init_memmap(base, n);
ffffffffc020114c:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020114e:	97aa                	add	a5,a5,a0
ffffffffc0201150:	00279513          	slli	a0,a5,0x2
ffffffffc0201154:	953e                	add	a0,a0,a5
ffffffffc0201156:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201158:	8d95                	sub	a1,a1,a3
ffffffffc020115a:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020115c:	81b1                	srli	a1,a1,0xc
ffffffffc020115e:	9532                	add	a0,a0,a2
ffffffffc0201160:	9782                	jalr	a5
ffffffffc0201162:	b769                	j	ffffffffc02010ec <pmm_init+0xee>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201164:	00001617          	auipc	a2,0x1
ffffffffc0201168:	00c60613          	addi	a2,a2,12 # ffffffffc0202170 <buddy_pmm_manager+0xb0>
ffffffffc020116c:	06f00593          	li	a1,111
ffffffffc0201170:	00001517          	auipc	a0,0x1
ffffffffc0201174:	02850513          	addi	a0,a0,40 # ffffffffc0202198 <buddy_pmm_manager+0xd8>
ffffffffc0201178:	a34ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020117c:	00001617          	auipc	a2,0x1
ffffffffc0201180:	ff460613          	addi	a2,a2,-12 # ffffffffc0202170 <buddy_pmm_manager+0xb0>
ffffffffc0201184:	08a00593          	li	a1,138
ffffffffc0201188:	00001517          	auipc	a0,0x1
ffffffffc020118c:	01050513          	addi	a0,a0,16 # ffffffffc0202198 <buddy_pmm_manager+0xd8>
ffffffffc0201190:	a1cff0ef          	jal	ra,ffffffffc02003ac <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201194:	00001617          	auipc	a2,0x1
ffffffffc0201198:	01460613          	addi	a2,a2,20 # ffffffffc02021a8 <buddy_pmm_manager+0xe8>
ffffffffc020119c:	06b00593          	li	a1,107
ffffffffc02011a0:	00001517          	auipc	a0,0x1
ffffffffc02011a4:	02850513          	addi	a0,a0,40 # ffffffffc02021c8 <buddy_pmm_manager+0x108>
ffffffffc02011a8:	a04ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02011ac <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02011ac:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011b0:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02011b2:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011b6:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02011b8:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011bc:	f022                	sd	s0,32(sp)
ffffffffc02011be:	ec26                	sd	s1,24(sp)
ffffffffc02011c0:	e84a                	sd	s2,16(sp)
ffffffffc02011c2:	f406                	sd	ra,40(sp)
ffffffffc02011c4:	e44e                	sd	s3,8(sp)
ffffffffc02011c6:	84aa                	mv	s1,a0
ffffffffc02011c8:	892e                	mv	s2,a1
ffffffffc02011ca:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02011ce:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc02011d0:	03067e63          	bleu	a6,a2,ffffffffc020120c <printnum+0x60>
ffffffffc02011d4:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02011d6:	00805763          	blez	s0,ffffffffc02011e4 <printnum+0x38>
ffffffffc02011da:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02011dc:	85ca                	mv	a1,s2
ffffffffc02011de:	854e                	mv	a0,s3
ffffffffc02011e0:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02011e2:	fc65                	bnez	s0,ffffffffc02011da <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02011e4:	1a02                	slli	s4,s4,0x20
ffffffffc02011e6:	020a5a13          	srli	s4,s4,0x20
ffffffffc02011ea:	00001797          	auipc	a5,0x1
ffffffffc02011ee:	1de78793          	addi	a5,a5,478 # ffffffffc02023c8 <error_string+0x38>
ffffffffc02011f2:	9a3e                	add	s4,s4,a5
}
ffffffffc02011f4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02011f6:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02011fa:	70a2                	ld	ra,40(sp)
ffffffffc02011fc:	69a2                	ld	s3,8(sp)
ffffffffc02011fe:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201200:	85ca                	mv	a1,s2
ffffffffc0201202:	8326                	mv	t1,s1
}
ffffffffc0201204:	6942                	ld	s2,16(sp)
ffffffffc0201206:	64e2                	ld	s1,24(sp)
ffffffffc0201208:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020120a:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020120c:	03065633          	divu	a2,a2,a6
ffffffffc0201210:	8722                	mv	a4,s0
ffffffffc0201212:	f9bff0ef          	jal	ra,ffffffffc02011ac <printnum>
ffffffffc0201216:	b7f9                	j	ffffffffc02011e4 <printnum+0x38>

ffffffffc0201218 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201218:	7119                	addi	sp,sp,-128
ffffffffc020121a:	f4a6                	sd	s1,104(sp)
ffffffffc020121c:	f0ca                	sd	s2,96(sp)
ffffffffc020121e:	e8d2                	sd	s4,80(sp)
ffffffffc0201220:	e4d6                	sd	s5,72(sp)
ffffffffc0201222:	e0da                	sd	s6,64(sp)
ffffffffc0201224:	fc5e                	sd	s7,56(sp)
ffffffffc0201226:	f862                	sd	s8,48(sp)
ffffffffc0201228:	f06a                	sd	s10,32(sp)
ffffffffc020122a:	fc86                	sd	ra,120(sp)
ffffffffc020122c:	f8a2                	sd	s0,112(sp)
ffffffffc020122e:	ecce                	sd	s3,88(sp)
ffffffffc0201230:	f466                	sd	s9,40(sp)
ffffffffc0201232:	ec6e                	sd	s11,24(sp)
ffffffffc0201234:	892a                	mv	s2,a0
ffffffffc0201236:	84ae                	mv	s1,a1
ffffffffc0201238:	8d32                	mv	s10,a2
ffffffffc020123a:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020123c:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020123e:	00001a17          	auipc	s4,0x1
ffffffffc0201242:	ffaa0a13          	addi	s4,s4,-6 # ffffffffc0202238 <buddy_pmm_manager+0x178>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201246:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020124a:	00001c17          	auipc	s8,0x1
ffffffffc020124e:	146c0c13          	addi	s8,s8,326 # ffffffffc0202390 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201252:	000d4503          	lbu	a0,0(s10)
ffffffffc0201256:	02500793          	li	a5,37
ffffffffc020125a:	001d0413          	addi	s0,s10,1
ffffffffc020125e:	00f50e63          	beq	a0,a5,ffffffffc020127a <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0201262:	c521                	beqz	a0,ffffffffc02012aa <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201264:	02500993          	li	s3,37
ffffffffc0201268:	a011                	j	ffffffffc020126c <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc020126a:	c121                	beqz	a0,ffffffffc02012aa <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc020126c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020126e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201270:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201272:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201276:	ff351ae3          	bne	a0,s3,ffffffffc020126a <vprintfmt+0x52>
ffffffffc020127a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020127e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201282:	4981                	li	s3,0
ffffffffc0201284:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0201286:	5cfd                	li	s9,-1
ffffffffc0201288:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020128a:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc020128e:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201290:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0201294:	0ff6f693          	andi	a3,a3,255
ffffffffc0201298:	00140d13          	addi	s10,s0,1
ffffffffc020129c:	20d5e563          	bltu	a1,a3,ffffffffc02014a6 <vprintfmt+0x28e>
ffffffffc02012a0:	068a                	slli	a3,a3,0x2
ffffffffc02012a2:	96d2                	add	a3,a3,s4
ffffffffc02012a4:	4294                	lw	a3,0(a3)
ffffffffc02012a6:	96d2                	add	a3,a3,s4
ffffffffc02012a8:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02012aa:	70e6                	ld	ra,120(sp)
ffffffffc02012ac:	7446                	ld	s0,112(sp)
ffffffffc02012ae:	74a6                	ld	s1,104(sp)
ffffffffc02012b0:	7906                	ld	s2,96(sp)
ffffffffc02012b2:	69e6                	ld	s3,88(sp)
ffffffffc02012b4:	6a46                	ld	s4,80(sp)
ffffffffc02012b6:	6aa6                	ld	s5,72(sp)
ffffffffc02012b8:	6b06                	ld	s6,64(sp)
ffffffffc02012ba:	7be2                	ld	s7,56(sp)
ffffffffc02012bc:	7c42                	ld	s8,48(sp)
ffffffffc02012be:	7ca2                	ld	s9,40(sp)
ffffffffc02012c0:	7d02                	ld	s10,32(sp)
ffffffffc02012c2:	6de2                	ld	s11,24(sp)
ffffffffc02012c4:	6109                	addi	sp,sp,128
ffffffffc02012c6:	8082                	ret
    if (lflag >= 2) {
ffffffffc02012c8:	4705                	li	a4,1
ffffffffc02012ca:	008a8593          	addi	a1,s5,8
ffffffffc02012ce:	01074463          	blt	a4,a6,ffffffffc02012d6 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc02012d2:	26080363          	beqz	a6,ffffffffc0201538 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc02012d6:	000ab603          	ld	a2,0(s5)
ffffffffc02012da:	46c1                	li	a3,16
ffffffffc02012dc:	8aae                	mv	s5,a1
ffffffffc02012de:	a06d                	j	ffffffffc0201388 <vprintfmt+0x170>
            goto reswitch;
ffffffffc02012e0:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02012e4:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012e6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02012e8:	b765                	j	ffffffffc0201290 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc02012ea:	000aa503          	lw	a0,0(s5)
ffffffffc02012ee:	85a6                	mv	a1,s1
ffffffffc02012f0:	0aa1                	addi	s5,s5,8
ffffffffc02012f2:	9902                	jalr	s2
            break;
ffffffffc02012f4:	bfb9                	j	ffffffffc0201252 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02012f6:	4705                	li	a4,1
ffffffffc02012f8:	008a8993          	addi	s3,s5,8
ffffffffc02012fc:	01074463          	blt	a4,a6,ffffffffc0201304 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0201300:	22080463          	beqz	a6,ffffffffc0201528 <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc0201304:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0201308:	24044463          	bltz	s0,ffffffffc0201550 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc020130c:	8622                	mv	a2,s0
ffffffffc020130e:	8ace                	mv	s5,s3
ffffffffc0201310:	46a9                	li	a3,10
ffffffffc0201312:	a89d                	j	ffffffffc0201388 <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc0201314:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201318:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc020131a:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc020131c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201320:	8fb5                	xor	a5,a5,a3
ffffffffc0201322:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201326:	1ad74363          	blt	a4,a3,ffffffffc02014cc <vprintfmt+0x2b4>
ffffffffc020132a:	00369793          	slli	a5,a3,0x3
ffffffffc020132e:	97e2                	add	a5,a5,s8
ffffffffc0201330:	639c                	ld	a5,0(a5)
ffffffffc0201332:	18078d63          	beqz	a5,ffffffffc02014cc <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201336:	86be                	mv	a3,a5
ffffffffc0201338:	00001617          	auipc	a2,0x1
ffffffffc020133c:	14060613          	addi	a2,a2,320 # ffffffffc0202478 <error_string+0xe8>
ffffffffc0201340:	85a6                	mv	a1,s1
ffffffffc0201342:	854a                	mv	a0,s2
ffffffffc0201344:	240000ef          	jal	ra,ffffffffc0201584 <printfmt>
ffffffffc0201348:	b729                	j	ffffffffc0201252 <vprintfmt+0x3a>
            lflag ++;
ffffffffc020134a:	00144603          	lbu	a2,1(s0)
ffffffffc020134e:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201350:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201352:	bf3d                	j	ffffffffc0201290 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0201354:	4705                	li	a4,1
ffffffffc0201356:	008a8593          	addi	a1,s5,8
ffffffffc020135a:	01074463          	blt	a4,a6,ffffffffc0201362 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc020135e:	1e080263          	beqz	a6,ffffffffc0201542 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc0201362:	000ab603          	ld	a2,0(s5)
ffffffffc0201366:	46a1                	li	a3,8
ffffffffc0201368:	8aae                	mv	s5,a1
ffffffffc020136a:	a839                	j	ffffffffc0201388 <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc020136c:	03000513          	li	a0,48
ffffffffc0201370:	85a6                	mv	a1,s1
ffffffffc0201372:	e03e                	sd	a5,0(sp)
ffffffffc0201374:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201376:	85a6                	mv	a1,s1
ffffffffc0201378:	07800513          	li	a0,120
ffffffffc020137c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020137e:	0aa1                	addi	s5,s5,8
ffffffffc0201380:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0201384:	6782                	ld	a5,0(sp)
ffffffffc0201386:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201388:	876e                	mv	a4,s11
ffffffffc020138a:	85a6                	mv	a1,s1
ffffffffc020138c:	854a                	mv	a0,s2
ffffffffc020138e:	e1fff0ef          	jal	ra,ffffffffc02011ac <printnum>
            break;
ffffffffc0201392:	b5c1                	j	ffffffffc0201252 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201394:	000ab603          	ld	a2,0(s5)
ffffffffc0201398:	0aa1                	addi	s5,s5,8
ffffffffc020139a:	1c060663          	beqz	a2,ffffffffc0201566 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc020139e:	00160413          	addi	s0,a2,1
ffffffffc02013a2:	17b05c63          	blez	s11,ffffffffc020151a <vprintfmt+0x302>
ffffffffc02013a6:	02d00593          	li	a1,45
ffffffffc02013aa:	14b79263          	bne	a5,a1,ffffffffc02014ee <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013ae:	00064783          	lbu	a5,0(a2)
ffffffffc02013b2:	0007851b          	sext.w	a0,a5
ffffffffc02013b6:	c905                	beqz	a0,ffffffffc02013e6 <vprintfmt+0x1ce>
ffffffffc02013b8:	000cc563          	bltz	s9,ffffffffc02013c2 <vprintfmt+0x1aa>
ffffffffc02013bc:	3cfd                	addiw	s9,s9,-1
ffffffffc02013be:	036c8263          	beq	s9,s6,ffffffffc02013e2 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc02013c2:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02013c4:	18098463          	beqz	s3,ffffffffc020154c <vprintfmt+0x334>
ffffffffc02013c8:	3781                	addiw	a5,a5,-32
ffffffffc02013ca:	18fbf163          	bleu	a5,s7,ffffffffc020154c <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc02013ce:	03f00513          	li	a0,63
ffffffffc02013d2:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013d4:	0405                	addi	s0,s0,1
ffffffffc02013d6:	fff44783          	lbu	a5,-1(s0)
ffffffffc02013da:	3dfd                	addiw	s11,s11,-1
ffffffffc02013dc:	0007851b          	sext.w	a0,a5
ffffffffc02013e0:	fd61                	bnez	a0,ffffffffc02013b8 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc02013e2:	e7b058e3          	blez	s11,ffffffffc0201252 <vprintfmt+0x3a>
ffffffffc02013e6:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02013e8:	85a6                	mv	a1,s1
ffffffffc02013ea:	02000513          	li	a0,32
ffffffffc02013ee:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02013f0:	e60d81e3          	beqz	s11,ffffffffc0201252 <vprintfmt+0x3a>
ffffffffc02013f4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02013f6:	85a6                	mv	a1,s1
ffffffffc02013f8:	02000513          	li	a0,32
ffffffffc02013fc:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02013fe:	fe0d94e3          	bnez	s11,ffffffffc02013e6 <vprintfmt+0x1ce>
ffffffffc0201402:	bd81                	j	ffffffffc0201252 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201404:	4705                	li	a4,1
ffffffffc0201406:	008a8593          	addi	a1,s5,8
ffffffffc020140a:	01074463          	blt	a4,a6,ffffffffc0201412 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc020140e:	12080063          	beqz	a6,ffffffffc020152e <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc0201412:	000ab603          	ld	a2,0(s5)
ffffffffc0201416:	46a9                	li	a3,10
ffffffffc0201418:	8aae                	mv	s5,a1
ffffffffc020141a:	b7bd                	j	ffffffffc0201388 <vprintfmt+0x170>
ffffffffc020141c:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc0201420:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201424:	846a                	mv	s0,s10
ffffffffc0201426:	b5ad                	j	ffffffffc0201290 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0201428:	85a6                	mv	a1,s1
ffffffffc020142a:	02500513          	li	a0,37
ffffffffc020142e:	9902                	jalr	s2
            break;
ffffffffc0201430:	b50d                	j	ffffffffc0201252 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc0201432:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0201436:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020143a:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020143c:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc020143e:	e40dd9e3          	bgez	s11,ffffffffc0201290 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0201442:	8de6                	mv	s11,s9
ffffffffc0201444:	5cfd                	li	s9,-1
ffffffffc0201446:	b5a9                	j	ffffffffc0201290 <vprintfmt+0x78>
            goto reswitch;
ffffffffc0201448:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc020144c:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201450:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201452:	bd3d                	j	ffffffffc0201290 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc0201454:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0201458:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020145c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020145e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201462:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201466:	fcd56ce3          	bltu	a0,a3,ffffffffc020143e <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc020146a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020146c:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0201470:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201474:	0196873b          	addw	a4,a3,s9
ffffffffc0201478:	0017171b          	slliw	a4,a4,0x1
ffffffffc020147c:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0201480:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0201484:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201488:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc020148c:	fcd57fe3          	bleu	a3,a0,ffffffffc020146a <vprintfmt+0x252>
ffffffffc0201490:	b77d                	j	ffffffffc020143e <vprintfmt+0x226>
            if (width < 0)
ffffffffc0201492:	fffdc693          	not	a3,s11
ffffffffc0201496:	96fd                	srai	a3,a3,0x3f
ffffffffc0201498:	00ddfdb3          	and	s11,s11,a3
ffffffffc020149c:	00144603          	lbu	a2,1(s0)
ffffffffc02014a0:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014a2:	846a                	mv	s0,s10
ffffffffc02014a4:	b3f5                	j	ffffffffc0201290 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc02014a6:	85a6                	mv	a1,s1
ffffffffc02014a8:	02500513          	li	a0,37
ffffffffc02014ac:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02014ae:	fff44703          	lbu	a4,-1(s0)
ffffffffc02014b2:	02500793          	li	a5,37
ffffffffc02014b6:	8d22                	mv	s10,s0
ffffffffc02014b8:	d8f70de3          	beq	a4,a5,ffffffffc0201252 <vprintfmt+0x3a>
ffffffffc02014bc:	02500713          	li	a4,37
ffffffffc02014c0:	1d7d                	addi	s10,s10,-1
ffffffffc02014c2:	fffd4783          	lbu	a5,-1(s10)
ffffffffc02014c6:	fee79de3          	bne	a5,a4,ffffffffc02014c0 <vprintfmt+0x2a8>
ffffffffc02014ca:	b361                	j	ffffffffc0201252 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02014cc:	00001617          	auipc	a2,0x1
ffffffffc02014d0:	f9c60613          	addi	a2,a2,-100 # ffffffffc0202468 <error_string+0xd8>
ffffffffc02014d4:	85a6                	mv	a1,s1
ffffffffc02014d6:	854a                	mv	a0,s2
ffffffffc02014d8:	0ac000ef          	jal	ra,ffffffffc0201584 <printfmt>
ffffffffc02014dc:	bb9d                	j	ffffffffc0201252 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02014de:	00001617          	auipc	a2,0x1
ffffffffc02014e2:	f8260613          	addi	a2,a2,-126 # ffffffffc0202460 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc02014e6:	00001417          	auipc	s0,0x1
ffffffffc02014ea:	f7b40413          	addi	s0,s0,-133 # ffffffffc0202461 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02014ee:	8532                	mv	a0,a2
ffffffffc02014f0:	85e6                	mv	a1,s9
ffffffffc02014f2:	e032                	sd	a2,0(sp)
ffffffffc02014f4:	e43e                	sd	a5,8(sp)
ffffffffc02014f6:	1c2000ef          	jal	ra,ffffffffc02016b8 <strnlen>
ffffffffc02014fa:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02014fe:	6602                	ld	a2,0(sp)
ffffffffc0201500:	01b05d63          	blez	s11,ffffffffc020151a <vprintfmt+0x302>
ffffffffc0201504:	67a2                	ld	a5,8(sp)
ffffffffc0201506:	2781                	sext.w	a5,a5
ffffffffc0201508:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc020150a:	6522                	ld	a0,8(sp)
ffffffffc020150c:	85a6                	mv	a1,s1
ffffffffc020150e:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201510:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201512:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201514:	6602                	ld	a2,0(sp)
ffffffffc0201516:	fe0d9ae3          	bnez	s11,ffffffffc020150a <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020151a:	00064783          	lbu	a5,0(a2)
ffffffffc020151e:	0007851b          	sext.w	a0,a5
ffffffffc0201522:	e8051be3          	bnez	a0,ffffffffc02013b8 <vprintfmt+0x1a0>
ffffffffc0201526:	b335                	j	ffffffffc0201252 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc0201528:	000aa403          	lw	s0,0(s5)
ffffffffc020152c:	bbf1                	j	ffffffffc0201308 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc020152e:	000ae603          	lwu	a2,0(s5)
ffffffffc0201532:	46a9                	li	a3,10
ffffffffc0201534:	8aae                	mv	s5,a1
ffffffffc0201536:	bd89                	j	ffffffffc0201388 <vprintfmt+0x170>
ffffffffc0201538:	000ae603          	lwu	a2,0(s5)
ffffffffc020153c:	46c1                	li	a3,16
ffffffffc020153e:	8aae                	mv	s5,a1
ffffffffc0201540:	b5a1                	j	ffffffffc0201388 <vprintfmt+0x170>
ffffffffc0201542:	000ae603          	lwu	a2,0(s5)
ffffffffc0201546:	46a1                	li	a3,8
ffffffffc0201548:	8aae                	mv	s5,a1
ffffffffc020154a:	bd3d                	j	ffffffffc0201388 <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc020154c:	9902                	jalr	s2
ffffffffc020154e:	b559                	j	ffffffffc02013d4 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc0201550:	85a6                	mv	a1,s1
ffffffffc0201552:	02d00513          	li	a0,45
ffffffffc0201556:	e03e                	sd	a5,0(sp)
ffffffffc0201558:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020155a:	8ace                	mv	s5,s3
ffffffffc020155c:	40800633          	neg	a2,s0
ffffffffc0201560:	46a9                	li	a3,10
ffffffffc0201562:	6782                	ld	a5,0(sp)
ffffffffc0201564:	b515                	j	ffffffffc0201388 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc0201566:	01b05663          	blez	s11,ffffffffc0201572 <vprintfmt+0x35a>
ffffffffc020156a:	02d00693          	li	a3,45
ffffffffc020156e:	f6d798e3          	bne	a5,a3,ffffffffc02014de <vprintfmt+0x2c6>
ffffffffc0201572:	00001417          	auipc	s0,0x1
ffffffffc0201576:	eef40413          	addi	s0,s0,-273 # ffffffffc0202461 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020157a:	02800513          	li	a0,40
ffffffffc020157e:	02800793          	li	a5,40
ffffffffc0201582:	bd1d                	j	ffffffffc02013b8 <vprintfmt+0x1a0>

ffffffffc0201584 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201584:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201586:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020158a:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020158c:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020158e:	ec06                	sd	ra,24(sp)
ffffffffc0201590:	f83a                	sd	a4,48(sp)
ffffffffc0201592:	fc3e                	sd	a5,56(sp)
ffffffffc0201594:	e0c2                	sd	a6,64(sp)
ffffffffc0201596:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201598:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020159a:	c7fff0ef          	jal	ra,ffffffffc0201218 <vprintfmt>
}
ffffffffc020159e:	60e2                	ld	ra,24(sp)
ffffffffc02015a0:	6161                	addi	sp,sp,80
ffffffffc02015a2:	8082                	ret

ffffffffc02015a4 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02015a4:	715d                	addi	sp,sp,-80
ffffffffc02015a6:	e486                	sd	ra,72(sp)
ffffffffc02015a8:	e0a2                	sd	s0,64(sp)
ffffffffc02015aa:	fc26                	sd	s1,56(sp)
ffffffffc02015ac:	f84a                	sd	s2,48(sp)
ffffffffc02015ae:	f44e                	sd	s3,40(sp)
ffffffffc02015b0:	f052                	sd	s4,32(sp)
ffffffffc02015b2:	ec56                	sd	s5,24(sp)
ffffffffc02015b4:	e85a                	sd	s6,16(sp)
ffffffffc02015b6:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc02015b8:	c901                	beqz	a0,ffffffffc02015c8 <readline+0x24>
        cprintf("%s", prompt);
ffffffffc02015ba:	85aa                	mv	a1,a0
ffffffffc02015bc:	00001517          	auipc	a0,0x1
ffffffffc02015c0:	ebc50513          	addi	a0,a0,-324 # ffffffffc0202478 <error_string+0xe8>
ffffffffc02015c4:	af3fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
readline(const char *prompt) {
ffffffffc02015c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02015ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02015cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02015ce:	4aa9                	li	s5,10
ffffffffc02015d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02015d2:	00005b97          	auipc	s7,0x5
ffffffffc02015d6:	a3eb8b93          	addi	s7,s7,-1474 # ffffffffc0206010 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02015da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02015de:	b51fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc02015e2:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02015e4:	00054b63          	bltz	a0,ffffffffc02015fa <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02015e8:	00a95b63          	ble	a0,s2,ffffffffc02015fe <readline+0x5a>
ffffffffc02015ec:	029a5463          	ble	s1,s4,ffffffffc0201614 <readline+0x70>
        c = getchar();
ffffffffc02015f0:	b3ffe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc02015f4:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02015f6:	fe0559e3          	bgez	a0,ffffffffc02015e8 <readline+0x44>
            return NULL;
ffffffffc02015fa:	4501                	li	a0,0
ffffffffc02015fc:	a099                	j	ffffffffc0201642 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc02015fe:	03341463          	bne	s0,s3,ffffffffc0201626 <readline+0x82>
ffffffffc0201602:	e8b9                	bnez	s1,ffffffffc0201658 <readline+0xb4>
        c = getchar();
ffffffffc0201604:	b2bfe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201608:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc020160a:	fe0548e3          	bltz	a0,ffffffffc02015fa <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020160e:	fea958e3          	ble	a0,s2,ffffffffc02015fe <readline+0x5a>
ffffffffc0201612:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201614:	8522                	mv	a0,s0
ffffffffc0201616:	ad5fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i ++] = c;
ffffffffc020161a:	009b87b3          	add	a5,s7,s1
ffffffffc020161e:	00878023          	sb	s0,0(a5)
ffffffffc0201622:	2485                	addiw	s1,s1,1
ffffffffc0201624:	bf6d                	j	ffffffffc02015de <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0201626:	01540463          	beq	s0,s5,ffffffffc020162e <readline+0x8a>
ffffffffc020162a:	fb641ae3          	bne	s0,s6,ffffffffc02015de <readline+0x3a>
            cputchar(c);
ffffffffc020162e:	8522                	mv	a0,s0
ffffffffc0201630:	abbfe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i] = '\0';
ffffffffc0201634:	00005517          	auipc	a0,0x5
ffffffffc0201638:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0206010 <edata>
ffffffffc020163c:	94aa                	add	s1,s1,a0
ffffffffc020163e:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201642:	60a6                	ld	ra,72(sp)
ffffffffc0201644:	6406                	ld	s0,64(sp)
ffffffffc0201646:	74e2                	ld	s1,56(sp)
ffffffffc0201648:	7942                	ld	s2,48(sp)
ffffffffc020164a:	79a2                	ld	s3,40(sp)
ffffffffc020164c:	7a02                	ld	s4,32(sp)
ffffffffc020164e:	6ae2                	ld	s5,24(sp)
ffffffffc0201650:	6b42                	ld	s6,16(sp)
ffffffffc0201652:	6ba2                	ld	s7,8(sp)
ffffffffc0201654:	6161                	addi	sp,sp,80
ffffffffc0201656:	8082                	ret
            cputchar(c);
ffffffffc0201658:	4521                	li	a0,8
ffffffffc020165a:	a91fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            i --;
ffffffffc020165e:	34fd                	addiw	s1,s1,-1
ffffffffc0201660:	bfbd                	j	ffffffffc02015de <readline+0x3a>

ffffffffc0201662 <sbi_console_putchar>:
    );
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201662:	00005797          	auipc	a5,0x5
ffffffffc0201666:	9a678793          	addi	a5,a5,-1626 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile (
ffffffffc020166a:	6398                	ld	a4,0(a5)
ffffffffc020166c:	4781                	li	a5,0
ffffffffc020166e:	88ba                	mv	a7,a4
ffffffffc0201670:	852a                	mv	a0,a0
ffffffffc0201672:	85be                	mv	a1,a5
ffffffffc0201674:	863e                	mv	a2,a5
ffffffffc0201676:	00000073          	ecall
ffffffffc020167a:	87aa                	mv	a5,a0
}
ffffffffc020167c:	8082                	ret

ffffffffc020167e <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc020167e:	00005797          	auipc	a5,0x5
ffffffffc0201682:	dca78793          	addi	a5,a5,-566 # ffffffffc0206448 <SBI_SET_TIMER>
    __asm__ volatile (
ffffffffc0201686:	6398                	ld	a4,0(a5)
ffffffffc0201688:	4781                	li	a5,0
ffffffffc020168a:	88ba                	mv	a7,a4
ffffffffc020168c:	852a                	mv	a0,a0
ffffffffc020168e:	85be                	mv	a1,a5
ffffffffc0201690:	863e                	mv	a2,a5
ffffffffc0201692:	00000073          	ecall
ffffffffc0201696:	87aa                	mv	a5,a0
}
ffffffffc0201698:	8082                	ret

ffffffffc020169a <sbi_console_getchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc020169a:	00005797          	auipc	a5,0x5
ffffffffc020169e:	96678793          	addi	a5,a5,-1690 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile (
ffffffffc02016a2:	639c                	ld	a5,0(a5)
ffffffffc02016a4:	4501                	li	a0,0
ffffffffc02016a6:	88be                	mv	a7,a5
ffffffffc02016a8:	852a                	mv	a0,a0
ffffffffc02016aa:	85aa                	mv	a1,a0
ffffffffc02016ac:	862a                	mv	a2,a0
ffffffffc02016ae:	00000073          	ecall
ffffffffc02016b2:	852a                	mv	a0,a0
ffffffffc02016b4:	2501                	sext.w	a0,a0
ffffffffc02016b6:	8082                	ret

ffffffffc02016b8 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc02016b8:	c185                	beqz	a1,ffffffffc02016d8 <strnlen+0x20>
ffffffffc02016ba:	00054783          	lbu	a5,0(a0)
ffffffffc02016be:	cf89                	beqz	a5,ffffffffc02016d8 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc02016c0:	4781                	li	a5,0
ffffffffc02016c2:	a021                	j	ffffffffc02016ca <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc02016c4:	00074703          	lbu	a4,0(a4)
ffffffffc02016c8:	c711                	beqz	a4,ffffffffc02016d4 <strnlen+0x1c>
        cnt ++;
ffffffffc02016ca:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02016cc:	00f50733          	add	a4,a0,a5
ffffffffc02016d0:	fef59ae3          	bne	a1,a5,ffffffffc02016c4 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc02016d4:	853e                	mv	a0,a5
ffffffffc02016d6:	8082                	ret
    size_t cnt = 0;
ffffffffc02016d8:	4781                	li	a5,0
}
ffffffffc02016da:	853e                	mv	a0,a5
ffffffffc02016dc:	8082                	ret

ffffffffc02016de <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016de:	00054783          	lbu	a5,0(a0)
ffffffffc02016e2:	0005c703          	lbu	a4,0(a1)
ffffffffc02016e6:	cb91                	beqz	a5,ffffffffc02016fa <strcmp+0x1c>
ffffffffc02016e8:	00e79c63          	bne	a5,a4,ffffffffc0201700 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc02016ec:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016ee:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc02016f2:	0585                	addi	a1,a1,1
ffffffffc02016f4:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016f8:	fbe5                	bnez	a5,ffffffffc02016e8 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016fa:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02016fc:	9d19                	subw	a0,a0,a4
ffffffffc02016fe:	8082                	ret
ffffffffc0201700:	0007851b          	sext.w	a0,a5
ffffffffc0201704:	9d19                	subw	a0,a0,a4
ffffffffc0201706:	8082                	ret

ffffffffc0201708 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201708:	00054783          	lbu	a5,0(a0)
ffffffffc020170c:	cb91                	beqz	a5,ffffffffc0201720 <strchr+0x18>
        if (*s == c) {
ffffffffc020170e:	00b79563          	bne	a5,a1,ffffffffc0201718 <strchr+0x10>
ffffffffc0201712:	a809                	j	ffffffffc0201724 <strchr+0x1c>
ffffffffc0201714:	00b78763          	beq	a5,a1,ffffffffc0201722 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0201718:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020171a:	00054783          	lbu	a5,0(a0)
ffffffffc020171e:	fbfd                	bnez	a5,ffffffffc0201714 <strchr+0xc>
    }
    return NULL;
ffffffffc0201720:	4501                	li	a0,0
}
ffffffffc0201722:	8082                	ret
ffffffffc0201724:	8082                	ret

ffffffffc0201726 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201726:	ca01                	beqz	a2,ffffffffc0201736 <memset+0x10>
ffffffffc0201728:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020172a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020172c:	0785                	addi	a5,a5,1
ffffffffc020172e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201732:	fec79de3          	bne	a5,a2,ffffffffc020172c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201736:	8082                	ret
