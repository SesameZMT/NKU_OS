### 练习

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点
 
#### 练习0：填写已有实验
本实验依赖实验 1/2/3。请把你做的实验 1/2/3 的代码填入本实验中代码中有“LAB1”,“LAB2”,“LAB3”的注释相应部分。

#### 练习 1：分配并初始化一个进程控制块（需要编码）
alloc_proc 函数（位于 kern/process/proc.c 中）负责分配并返回一个新的struct proc_struct 结构，用于存储新建立的内核线程的管理信息。ucore 需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。
【提示】在 alloc_proc 函数的实现中，需要初始化的 proc_struct 结构中的成员变量至少包括：
state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
• 请说明 proc_struct 中 struct context context 和 struct trapframe *tf 成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

在ucore中，`struct proc_struct` 结构体是用于存储进程或线程的管理信息的。在 `alloc_proc` 函数中，对 `struct proc_struct` 结构体进行初始化。

```c
struct proc_struct *alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
        // 初始化proc_struct中的各个成员变量
        proc->state = PROC_UNINIT; // 进程状态，未初始化
        proc->pid = -1; // 进程ID，初始化为-1
        proc->runs = 0; // 进程运行次数
        proc->kstack = 0; // 进程内核栈
        proc->need_resched = 0; // 是否需要调度
        proc->parent = NULL; // 父进程指针
        proc->mm = NULL; // 内存空间管理指针
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文
        proc->tf = NULL; // 中断帧指针
        proc->cr3 = boot_cr3; // 页表基址寄存器
        proc->flags = 0; // 进程标志位
        memset(proc->name, 0, PROC_NAME_LEN); // 进程名称
    }
    return proc;
}
```

在上述代码中，`struct context` 和 `struct trapframe *tf` 是 `proc_struct` 中的两个重要成员变量：
`struct context context`: 这个结构体用于保存进程在内核态运行时的上下文信息，包括寄存器的值等。通过保存和恢复这个上下文，可以实现进程的上下文切换。
`struct trapframe *tf`: 这是一个指向中断帧的指针，用于保存进程在发生中断或异常时的现场信息。中断帧中包含了中断发生时处理器的状态，如寄存器值、指令指针等。在进程切换或中断处理时，需要保存和恢复这个中断帧。

设计实现过程：这段代码实现了一个 `alloc_proc` 函数，用于分配并初始化一个进程控制块 (`struct proc_struct`)。
1. 分配内存空间： 首先通过 `kmalloc(sizeof(struct proc_struct))` 分配了一个存储进程控制信息的内存空间。
2. 检查分配情况： 然后检查是否成功分配内存，如果成功则进行初始化。
3. 初始化进程控制块成员变量： 对进程控制块中的各个成员变量进行初始化操作：
   `state`: 设置进程状态为未初始化状态 (`PROC_UNINIT`)。
   `pid`: 初始化进程ID为-1，表示未分配。
   `runs`: 运行次数初始化为0，记录进程被调度执行的次数。
   `kstack`: 进程内核栈初始化为0，表示未分配内核栈。
   `need_resched`: 是否需要调度初始化为0，表示不需要调度。
   `parent`: 父进程指针初始化为空，表示没有父进程。
   `mm`: 内存空间管理指针初始化为空，表示未分配内存空间。
   `context`: 使用 `memset` 将进程的上下文信息清零，确保初始化为0值。
   `tf`: 中断帧指针初始化为空，表示没有中断帧信息。
   `cr3`: 页表基址寄存器初始化为 `boot_cr3`，可能是指向启动时的页表基址。
   `flags`: 进程标志位初始化为0。
   `name`: 进程名称通过 `memset` 初始化为空，长度为 `PROC_NAME_LEN`。
4. 返回进程控制块指针： 最后返回已经初始化的进程控制块指针。
这个函数主要是为了提供一个新的进程控制块，为一个新建立的内核线程提供管理信息，并将其基本成员变量初始化为合适的初始值。

#### 练习 2：为新创建的内核线程分配资源（需要编码）
创建一个内核线程需要分配和设置好很多资源。kernel_thread 函数通过调用 do_fork 函数完成具体内核线程
的创建工作。do_kernel 函数会调用 alloc_proc 函数来分配并初始化一个进程控制块，但 alloc_proc 只是找到
了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore 一般通过 do_fork 实际创建新的内
核线程。do_fork 的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存
储位置不同。因此，我们实际需要”fork”的东西就是 stack 和 trapframe。在这个过程中，需要给新内核线
程分配资源，并且复制原进程的状态。你需要完成在 kern/process/proc.c 中的 do_fork 函数中的处理过程。它
的大致执行步骤包括：
• 调用 alloc_proc，首先获得一块用户信息块。
• 为进程分配一个内核栈。
• 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
• 复制原进程上下文到新进程
• 将新进程添加到进程列表
• 唤醒新进程
• 返回新进程号
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
• 请说明 ucore 是否做到给每个新 fork 的线程一个唯一的 id？请说明你的分析和理由。






#### 练习 3：编写 proc_run 函数（需要编码）
proc_run 用于将指定的进程切换到 CPU 上运行。它的大致执行步骤包括：
• 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
• 禁 用 中 断。 你 可 以 使 用/kern/sync/sync.h 中 定 义 好 的 宏 local_intr_save(x) 和
local_intr_restore(x) 来实现关、开中断。
• 切换当前进程为要运行的进程。
• 切换页表，以便使用新进程的地址空间。/libs/riscv.h 中提供了 lcr3(unsigned int cr3)
函数，可实现修改 CR3 寄存器值的功能。
• 实现上下文切换。/kern/process 中已经预先编写好了 switch.S，其中定义了 switch_to() 函
数。可实现两个进程的 context 切换。
• 允许中断。
请回答如下问题：
• 在本实验的执行过程中，创建且运行了几个内核线程？
完成代码编写后，编译并运行代码：make qemu
如果可以得到如附录 A 所示的显示内容（仅供参考，不是标准答案输出），则基本正确。




#### 扩展练习 Challenge：
• 说明语句 local_intr_save(intr_flag);....local_intr_restore(intr_flag); 是如何实现开关中断的？
在 `local_intr_save` 宏中，`x = __intr_save();` 会调用 `__intr_save()` 函数来禁用中断、保存当前中断状态并将其存储在 `intr_flag` 变量中。而在 `local_intr_restore` 宏中，`__intr_restore(x);` 会使用之前保存的中断状态来恢复中断。
这种实现方式的核心思想是使用函数来禁用和恢复中断，并通过变量传递来保存和恢复中断状态。