# 操作系统的中断



## 基础

### 概念
* CPU 收到中断指令后保存当前状态，开始处理其他事情。

### 功能
1. 增加CPU效率
2. 防止程序无限运行

### 进行中断处理支持的方法
* 编写相应的中断处理代码
* 在启动中正确设置控制寄存器
* CPU捕获异常
* 控制转交给相应中断处理代码进行处理
* 返回正在运行的程序



## 分类
1. 异常(Exception)：在执行一条指令的过程中发生了错误，此时通过中断来处理错误
2. 陷入(Trap)：主动通过一条指令停下来，并跳转到处理函数
3. 外部中断(Interrupt)： CPU 的执行过程被外设发来的信
号打断，此时必须先停下来对该外设进行处理



## riscv64 权限模式
1. M mode（机器模式）
    * 最高权限模式
    * 运行的 hart 对内存,I/O和一些对于启动和配置系统来说必要的底层功能有着完全的使用权
    * 发生异常控制权都会被移交到 M 模式的异常处理程序
    * 唯一所有标准 RISC-V 处理器都必须实现的权限模式

2. S mode（监督则模式）
    * 支持现代类 Unix 操作系统的权限模式
    * 核心：支持基于页面的虚拟内存机制



## 特权指令
* ecall：S态下执行进入 M 模式中的中断处理流程；U态下执行进入 S 模式中的中断处理流程
* sret：S 态中断返回到 U 态
* ebreak：触发一个断点中断从而进入中断处理流程
* mret：M 态中断返回到 S 态或 U 态



## 中断入口点
* 需求：把原先的寄存器保存下来，做完其他事情后把寄存器恢复
    
    将需要保存和回复的寄存器称为 ***上下文（context）*** 
* 实现上下文切换的步骤
    1. 保存 CPU 的上下文到内存中（栈上）
    2. 从内存中（栈上）恢复 CPU 的上下文

    定义结构体进行上下文数据管理



## 练习

### EXERCISE2
* 添加代码如下
```c
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
        /*
            其他case
        */

        case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
             /* LAB1 EXERCISE2   YOUR CODE : 2111454 */
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
            if(ticks++ % TICK_NUM == 0 && num < 10)
            {
                num++; //每打印一次计数器加一
                print_ticks(); //执行打印
            }
            else if(num == 10){
                sbi_shutdown(); //打印10次后调用<sbi.h>中的关机函数关机
            }
            break;

        /*
            其他case
        */
    }
}
```