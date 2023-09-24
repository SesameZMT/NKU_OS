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


### EXERCISE1
`kern/init/entry.S`是一段RISC-V架构的内核启动代码，用于初始化内核并设置堆栈。


`la sp, bootstacktop`：
* `la` 是汇编指令中的伪指令（pseudo-instruction），通常用于将某个地址加载到寄存器中。
* `sp` 是RISC-V架构中的寄存器，表示堆栈指针（Stack Pointer），用于跟踪当前堆栈的顶部。
* `bootstacktop` 是一个标签（label），标识了内核启动堆栈的顶部位置。

指令 `la sp, bootstacktop` 完成了将 `bootstacktop` 的地址加载到 `sp` (栈指针) 寄存器中的操作。目的是为了设置内核栈的起始地址，使得栈指针指向内核栈的顶部。

`tail kern_init`：
* `tail` 是RISC-V汇编中的伪指令，通常用于尾调用（tail call）函数。
* `kern_init` 是一个标签（label），标识了内核初始化代码的起始位置。

指令 `tail kern_init` 完成了跳转到 `kern_init` 函数的操作。目的是开始执行内核的初始化过程。使用 `tail` 指令而不是普通的跳转指令，是为了使得 `kern_init` 函数的返回地址仍然指向 `kern_entry`，以便在初始化完成后能够正确返回到 `kern_entry` 继续执行其他操作。


### EXERCISE2

添加代码如下

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

实现过程：

* `intptr_t cause = (tf->cause << 1) >> 1;`：这行代码从中断帧 tf 中获取中断原因，并将其存储在 cause 变量中。通过左移一位然后再右移一位的方式清除了最高位，确保 cause 中只包含实际的原因值。
* `switch (cause)`：根据中断原因选择不同的处理分支。
* `case IRQ_S_TIMER:`：这个分支处理的是定时器中断（Supervisor Timer Interrupt）。
* `clock_set_next_event();`：调用函数设置下一次的时钟中断事件。它会计算下一个时间片的结束时间，以便在该时间点触发中断。
* `if(ticks++ % TICK_NUM == 0 && num < 10)`：检查是否应该执行打印操作。ticks 是一个全局计数器，用于跟踪时钟中断的数量。TICK_NUM 是一个文件头部的宏定义常数，表示多少个时钟中断触发一次打印操作。num 用于跟踪打印操作的次数。
    * 如果 ticks 能被 TICK_NUM 整除，并且 num 小于 10，那么执行以下操作：
        * num 增加1，表示已经触发了一次打印。
        * 调用 print_ticks() 函数来执行打印操作。

    * 否则，如果 num 达到了10，执行以下操作：
        * 调用 sbi_shutdown() 函数，关闭系统。

运行结果如下：

![Alt text](<picture/LAB1 EXERCISE2运行结果.png>)


### CHALLENGE1
在 ucore 中处理中断异常的流程如下：
1. 异常的产生：当处理器执行指令时，如果遇到异常情况（例如除零错误、非法指令等），或者外部设备发送中断请求时，会触发中断异常。

2. 异常处理程序入口：当中断异常发生时，处理器会跳转到事先定义好的异常处理程序入口，即 `__alltraps`。

3. 保存现场：在 `__alltraps` 中，首先执行 `SAVE_ALL` 宏，将当前中断发生时的寄存器状态保存到栈中。`SAVE_ALL` 宏中的指令会将寄存器依次入栈，以保存现场信息。

4. 处理中断：接下来，根据中断类型，执行相应的中断处理程序。例如，如果是时钟中断，则执行时钟中断处理程序。

5. 恢复现场：在中断处理程序执行完毕后，需要恢复之前保存的现场信息。通过 `RESTORE_ALL` 宏，从栈中依次弹出寄存器值，恢复到中断发生时的状态。

6. 中断返回：最后，执行 `eret` 指令，将控制权返回到中断发生时的位置，继续执行被中断的指令。

在这个流程中，`mov a0, sp` 的目的是将当前栈顶指针值保存到 `a0` 寄存器中。这样做是为了在保存现场和恢复现场时，能够准确地找到栈中保存的寄存器值。

`SAVE_ALL` 中寄存器保存在栈中的位置是由编写异常处理程序时的约定来确定的。在 ucore 中，寄存器的保存顺序是按照 RISC-V 架构的规定，依次保存到栈中。

对于任何中断，`__alltraps` 中都需要保存所有寄存器，因为在中断处理过程中，可能会修改寄存器的值，如果不保存所有寄存器，就无法保证中断处理程序执行完毕后能够正确恢复被中断的代码的寄存器状态。因此，为了保证中断处理的正确性，需要保存所有寄存器的值。


### CHALLENGE2
汇编代码 `csrw sscratch, sp` 和 `csrrw s0, sscratch, x0` 实现了将栈指针 `sp` 的值保存到 `sscratch` 寄存器中，并将 `sscratch` 寄存器的值保存到 `s0` 寄存器中的操作。目的是为了在异常处理程序中能够正确地使用 `sscratch` 寄存器来保存一些临时数据或者状态。

在 `SAVE_ALL` 中，保存了 `stval` 和 `scause` 这些 CSR（Control and Status Registers）。这些 CSR 记录了当前异常的一些相关信息，比如异常的原因和异常发生时的地址。保存这些 CSR 的目的是为了在异常处理程序中能够获取异常的详细信息，以便进行适当的处理。

在 `RESTORE_ALL` 中，没有还原 `stval` 和 `scause` 这些 CSR 的值。这是因为在正常的异常处理过程中，这些 CSR 的值通常是只读的，不需要手动修改或还原。而且，在异常处理程序执行完毕后，处理器会自动根据异常发生时的现场信息将这些 CSR 恢复到正确的值。

尽管在 `RESTORE_ALL` 中没有还原这些 CSR 的值，但在 `SAVE_ALL` 中保存这些 CSR 的操作仍然有意义。这是因为在异常处理程序执行期间，如果需要访问这些 CSR 的值，可以通过读取 `sscratch` 寄存器的值来获取。这样做可以保存这些 CSR 的值，使它们不会因异常处理过程中的修改而被影响，保证了异常处理的正确性。


### CHALLENGE3
添加的代码如下

/kern/trap/trap.c
```c
// tf->cause 寄存器的宏定义见 /libs/riscv.h
// 其实本函数中自上而下的宏定义分别代表了0x0到0xb
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {

        /*
            其他case
        */

        case CAUSE_ILLEGAL_INSTRUCTION:
            // 非法指令异常处理
            /* LAB1 CHALLENGE3   YOUR CODE : 2111454 */
            /*(1)输出指令异常类型（ Illegal instruction）
            *(2)输出异常指令地址
            *(3)更新 tf->epc寄存器
            */

            cprintf("Exception Type:Illegal Instruction\n");

            // tf->epc寄存器保存了触发中断的指令的地址
            // 因此输出该寄存器的值就是中断指令的地址
            // %08x的含义：08表示输出8个字符，x是输出16进制
            cprintf("Illegal Instruction caught at 0x%08x\n", tf->epc);
            
            // 所谓更新tf->epc寄存器，本质上指的是让其记录下一条指令
            // 因此将该寄存器更新的操作就是让其内部地址偏移+4
            tf->epc += 4;

            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB1 CHALLLENGE3   YOUR CODE : 2111454 */
            /*(1)输出指令异常类型（ breakpoint）
            *(2)输出异常指令地址
            *(3)更新 tf->epc寄存器
            */
            
            cprintf("Exception Type:Breakpoint\n");

            // tf->epc寄存器保存了触发中断的指令的地址
            // 因此输出该寄存器的值就是中断指令的地址
            // %08x的含义：08表示输出8个字符，x是输出16进制
            cprintf("Breakpoint caught at 0x%08x\n", tf->epc);
            
            // 所谓更新tf->epc寄存器，本质上指的是让其记录下一条指令
            // 因此将该寄存器更新的操作就是让其内部地址偏移+4
            tf->epc += 4;
            
            break;

        /*
            其他case
        */
       
    }
}   
```

/kern/init/init.c
```c
int kern_init(void) {
    /*
        其他部分
    */
    
    // 指令异常
    /* 
    测试了另外两个特权指令ecall和sret发现并不能触发指令异常
    分析原因是我们本身就处于U态，因此两条指令并不属于异常指令
    而mret需要更高的特权级因此可以触发
    */
    asm("mret");
    // 断点异常
    asm("ebreak"); 

    while (1)
        ;
}
```

运行结果如下：
![Alt text](<picture/LAB1 CHALLENGE3运行结果.png>)



### 练习评分
执行如下命令进行评分
```sh
make grade
```

评分结果如下：
![Alt text](picture/LAB1%E8%AF%84%E5%88%86.png)