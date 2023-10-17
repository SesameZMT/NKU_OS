#include <clock.h>
#include <console.h>
#include <defs.h>
#include <intr.h>
#include <kdebug.h>
#include <kmonitor.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>
#include <trap.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    cons_init();  // init the console
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);

    print_kerninfo();

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table 初始化中断描述符表IDT

    pmm_init();  // init physical memory management 物理内存管理
    /* 
    LAB2 EXERCISE 2: 2110049
    pmm_init()函数需要注册缺页中断处理程序，用于处理页面访问异常。
    当程序试图访问一个不存在的页面时，CPU会触发缺页异常，此时会调用缺页中断处理程序
    该程序会在物理内存中分配一个新的页面，并将其映射到虚拟地址空间中。
    */

    idt_init();  // init interrupt descriptor table

    clock_init();   // init clock interrupt
    /*
    clock_init()函数需要注册时钟中断处理程序，用于定时触发时钟中断。
    当时钟中断被触发时，CPU会跳转到时钟中断处理程序，该程序会更新系统时间，并执行一些周期性的操作，如调度进程等
    */
    //这两个函数都需要使用中断描述符表，所以要在中断描述符表初始化之后再初始化时钟中断

    intr_enable();  // enable irq interrupt 开启中断

    /*
    这些中断的目的是实现操作系统的基本功能和提供服务。具体来说：

    1. 缺页中断处理程序：当程序试图访问一个不存在的页面时，CPU会触发缺页异常，并调用缺页中断处理程序。该程序会在物理内存中分配一个新的页面，并将其映射到虚拟地址空间中，以满足程序对页面的访问需求。这是实现虚拟内存管理的关键。

    2. 时钟中断处理程序：时钟中断定期触发，用于更新系统时间，并执行一些周期性的操作，如调度进程等。时钟中断是操作系统实现时间片轮转调度算法和实现进程切换的重要机制。

    3. IRQ中断使能：中断请求（IRQ）是外部设备向CPU发出的中断信号，用于处理设备的输入和输出。通过使能IRQ中断，操作系统可以响应外部设备的中断请求，并进行相应的处理。

    总之，这些中断的目的是为了实现操作系统的核心功能，如虚拟内存管理、时间管理和设备管理等。
    */

    /* do nothing */
    while (1)
        ;
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
    mon_backtrace(0, NULL, NULL);
}

void __attribute__((noinline)) grade_backtrace1(int arg0, int arg1) {
    grade_backtrace2(arg0, (uintptr_t)&arg0, arg1, (uintptr_t)&arg1);
}

void __attribute__((noinline)) grade_backtrace0(int arg0, int arg1, int arg2) {
    grade_backtrace1(arg0, arg2);
}

void grade_backtrace(void) { grade_backtrace0(0, (uintptr_t)kern_init, 0xffff0000); }

static void lab1_print_cur_status(void) {
    static int round = 0;
    round++;
}

