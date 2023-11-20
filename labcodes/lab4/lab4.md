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

```cpp
// do_fork - 用来创建一个新的进程（子进程）
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    //LAB4:EXERCISE2 YOUR CODE
    /*
     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
     *                 setup the kernel entry point and stack of process
     *   hash_proc:    add proc into proc hash_list
     *   get_pid:      alloc a unique pid for process
     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
     * VARIABLES:
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */
    
    //    1. call alloc_proc to allocate a proc_struct
    //    2. call setup_kstack to allocate a kernel stack for child process
    //    3. call copy_mm to dup OR share mm according clone_flag
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid

    proc = alloc_proc();    // 调用alloc_proc函数分配一个proc_struct结构体
    
    if (proc == NULL) { // 如果分配失败，返回错误码
        goto fork_out;
    }

    proc->parent = current; // 设置父进程为当前进程

    if (setup_kstack(proc) != 0) {  // 调用setup_kstack函数为子进程分配内核栈
        goto bad_fork_cleanup_kstack;
    }

    if (copy_mm(clone_flags, proc) != 0) {  // 调用copy_mm函数复制父进程的内存管理信息
        goto bad_fork_cleanup_proc;
    }

    copy_thread(proc, stack, tf);   // 调用copy_thread函数复制父进程的trapframe信息

    bool intr_flag;
    local_intr_save(intr_flag); // 关闭中断
    
    proc->pid = get_pid();  // 为子进程分配pid
    hash_proc(proc);    // 将子进程添加到hash_list中
    list_add(&proc_list, &(proc->list_link));   // 将子进程添加到proc_list中
    nr_process++;

    local_intr_restore(intr_flag);  // 开启中断

    wakeup_proc(proc);  // 唤醒子进程

    ret = proc->pid;    // 设置返回值为子进程的pid

fork_out:   // 返回
    return ret;

bad_fork_cleanup_kstack:    // 释放内核栈
    put_kstack(proc);
bad_fork_cleanup_proc:  // 释放进程
    kfree(proc);
    goto fork_out;
}
```

``do_fork``这段代码实现创建一个新进程（子进程）的功能。在这段代码中，我们首先定义了一个返回值变量 `ret` 并初始化为 `-E_NO_FREE_PROC`，表示没有空闲的进程；接着声明了一个指向 `struct proc_struct` 类型的指针 `proc`，用于指向新创建的进程；然后检查当前进程数量是否已达到最大进程数 `MAX_PROCESS`，如果是，则跳转到 `fork_out` 标签处，表示创建新进程失败；如果未达到最大进程数，则会接着执行后面的代码；将 `ret` 的值设置为 `-E_NO_MEM`，表示内存不足；调用 `alloc_proc()` 函数分配一个 `proc_struct` 结构体，用于表示新进程，如果分配失败，跳转到 `fork_out` 标签处，表示创建失败；将新进程的父进程指针 `parent` 设置为当前进程；调用 `setup_kstack(proc)` 函数为子进程分配内核栈，如果分配失败，跳转到 `bad_fork_cleanup_kstack` 标签处，释放内核栈并返回错误；调用 `copy_mm(clone_flags, proc)` 函数复制父进程的内存管理信息到子进程，如果复制失败，跳转到 `bad_fork_cleanup_proc` 标签处，释放进程并返回错误；调用 `copy_thread(proc, stack, tf)` 函数复制父进程的上下文信息到子进程；关闭中断，以确保在修改全局数据结构时不会被中断；为子进程分配一个唯一的进程 ID（PID），将子进程添加到进程哈希表中，将子进程添加到进程列表中，增加进程数量计数器，再开启中断，然后唤醒子进程，使其变为可运行状态，将子进程的 PID 赋值给 `ret`，返回 `ret`。

注：如果在上述过程中出现错误，会跳转到相应的标签处进行清理操作，并返回错误码。

在此代码中，``do_fork``函数通过调用``get_pid()``函数为新进程分配一个唯一的进程ID（PID）。这个函数会从全局的PID池中获取一个未分配使用的PID分配给新的进程，因此，ucore 做到了给每个新 ``fork`` 的线程一个唯一的 ``id``.


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


```cpp
// proc_run - 用来切换到一个新的进程（线程）
void
proc_run(struct proc_struct *proc) {
    // 首先判断要切换到的进程是不是当前进程，若是则不需进行任何处理。
    if (proc != current) {
        // LAB4:EXERCISE3 YOUR CODE
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */
       // 调用local_intr_save和local_intr_restore函数避免在进程切换过程中出现中断。
        bool intr_flag;
        local_intr_save(intr_flag); // 关闭中断

        struct proc_struct *prev = current; // 保存当前进程
        struct proc_struct *next = proc;    // 保存下一个进程

        current = proc; // 将当前进程设置为下一个进程
        lcr3(proc->cr3);    // 切换到下一个进程的页表
        switch_to(&(prev->context), &(next->context));  // 进行上下文切换

        local_intr_restore(intr_flag);  // 开启中断
    }
}
```

``pron_run``实现了切换到一个新的进程（线程）的功能。在这段代码中，首先，需要判断切换到的进程（线程）是否是当前进程（线程），如果是，则无需进行任何处理；如果要切换的进程（线程）不是当前进程（线程），则进行进程切换操作；调用 `local_intr_save(intr_flag)` 函数关闭中断，以确保在进程切换过程中不会被中断；接着声明两个指向 `struct proc_struct` 类型的指针 `prev` 和 `next`，分别用于保存当前进程和要切换到的下一个进程，将当前进程指针 `current` 设置为要切换到的下一个进程；调用 `lcr3(proc->cr3)` 函数切换到下一个进程的页表，即将页表寄存器 CR3 的值设置为下一个进程的页表基址；调用 `switch_to(&(prev->context), &(next->context))` 函数进行上下文切换，将当前进程的上下文保存到 `prev->context` 中，将下一个进程的上下文恢复到 `next->context` 中；最后再调用 `local_intr_restore(intr_flag)` 函数开启中断，恢复中断状态。至此，进程切换完成，当前进程被切换为要切换到的下一个进程（线程）。

在本实验中，一共创建了两个内核线程，一个为 `idle` 另外一个为执行 `init_main` 的 `init` 线程。 




#### 扩展练习 Challenge：
• 说明语句 local_intr_save(intr_flag);....local_intr_restore(intr_flag); 是如何实现开关中断的？
在 `local_intr_save` 宏中，`x = __intr_save();` 会调用 `__intr_save()` 函数来禁用中断、保存当前中断状态并将其存储在 `intr_flag` 变量中。而在 `local_intr_restore` 宏中，`__intr_restore(x);` 会使用之前保存的中断状态来恢复中断。
这种实现方式的核心思想是使用函数来禁用和恢复中断，并通过变量传递来保存和恢复中断状态。