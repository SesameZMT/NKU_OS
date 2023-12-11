### 练习

对实验报告的要求：
• 基于 markdown 格式来完成，以文本方式为主
• 填写各个基本练习中要求完成的报告内容
• 完成实验后，请分析 ucore_lab 中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
• 列出你认为本实验中重要的知识点，以及与对应的 OS 原理中的知识点，并简要说明你对二者的含义，
关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
• 列出你认为 OS 原理中很重要，但在实验中没有对应上的知识点
 

#### 练习0：填写已有实验
本实验依赖实验 1/2/3/4。请把你做的实验 1/2/3/4 的代码填入本实验中代码中有“LAB1”/“LAB2”/“LAB3”
/“LAB4”的注释相应部分。注意：为了能够正确执行 lab5 的测试应用程序，可能需对已完成的实验 1/2/3/4
的代码进行进一步改进。


#### 练习 1: 加载应用程序并执行（需要编码）
do_execv 函数调用 load_icode（位于 kern/process/proc.c 中）来加载并解析一个处于内存中的 ELF 执行文
件格式的应用程序。你需要补充 load_icode 的第 6 步，建立相应的用户内存空间来放置应用程序的代码
段、数据段等，且要设置好 proc_struct 结构中的成员变量 trapframe 中的内容，确保在执行此进程后，
能够从应用程序设定的起始执行地址开始执行。需设置正确的 trapframe 内容。
请在实验报告中简要说明你的设计实现过程。
• 请简要描述这个用户态进程被 ucore 选择占用 CPU 执行（RUNNING 态）到具体执行应用程序第一条
指令的整个经过。

```cpp
//(6) setup trapframe for user environment
    struct trapframe *tf = current->tf;
    // Keep sstatus
    uintptr_t sstatus = tf->status;
    memset(tf, 0, sizeof(struct trapframe));
    /* LAB5:EXERCISE1 YOUR CODE
     * should set tf->gpr.sp, tf->epc, tf->status
     * NOTICE: If we set trapframe correctly, then the user level process can return to USER MODE from kernel. So
     *          tf->gpr.sp should be user stack top (the value of sp)
     *          tf->epc should be entry point of user program (the value of sepc)
     *          tf->status should be appropriate for user program (the value of sstatus)
     *          hint: check meaning of SPP, SPIE in SSTATUS, use them by SSTATUS_SPP, SSTATUS_SPIE(defined in risv.h)
     */
    tf->gpr.sp = USTACKTOP;
    tf->epc = elf->e_entry;
    // Set SPP to 0 so that we return to user mode
    // Set SPIE to 1 so that we can handle interrupts
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
```
这段代码是在 ucore 中的进程管理模块中的 load_icode 函数中的一部分。这个函数的作用是加载并解析一个处于内存中的 ELF 执行文件格式的应用程序。在第 6 步中，需要建立相应的用户内存空间来放置应用程序的代码段、数据段等，并设置好 proc_struct 结构中的成员变量 trapframe 中的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。具体来说，需要设置正确的 trapframe 内容，包括 tf->gpr.sp、tf->epc 和 tf->status。其中，tf->gpr.sp 应该是用户栈顶（即 sp 的值），tf->epc 应该是用户程序的入口地址（即 sepc 的值），tf->status 应该是适合用户程序的状态（即 sstatus 的值）。需要注意的是，如果我们正确设置了 trapframe，那么用户级进程就可以从内核返回到用户模式。因此，我们需要设置 SPP 为 0，以便返回到用户模式，同时设置 SPIE 为 1，以便处理中断.

当这个用户态进程被 ucore 选择占用 CPU 执行（RUNNING 态）时，首先会执行进程的内核态代码，即 trap 函数。在 trap 函数中，会根据当前的中断类型和错误码，调用不同的中断处理函数。如果是系统调用，会进入 syscall 函数，然后根据系统调用号，调用相应的系统调用处理函数。在这个过程中，会将进程的 trapframe 中的内容保存到内核栈中，然后进入内核态执行相应的代码。当系统调用处理函数返回时，会将进程的 trapframe 中的内容恢复，然后返回到用户态，继续执行用户态代码。当执行到应用程序的第一条指令时，就会开始执行应用程序的代码.


#### 练习 2: 父进程复制自己的内存空间给子进程（需要编码）
创建子进程的函数 do_fork 在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新
进程中（子进程），完成内存资源的复制。具体是通过 copy_range 函数（位于 kern/mm/pmm.c 中）实现
的，请补充 copy_range 的实现，确保能够正确执行。
请在实验报告中简要说明你的设计实现过程。
• 如何设计实现 Copy on Write 机制？给出概要设计，鼓励给出详细设计。
Copy-on-write（简称 COW）的基本概念是指如果有多个使用者对一个资源 A（比如内存块）进行
读操作，则每个使用者只需获得一个指向同一个资源 A 的指针，就可以该资源了。若某使用者需
要对这个资源 A 进行写操作，系统会对该资源进行拷贝操作，从而使得该“写操作”使用者获得
一个该资源 A 的“私有”拷贝—资源 B，可对资源 B 进行写操作。该“写操作”使用者对资源 B
的改变对于其他的使用者而言是不可见的，因为其他使用者看到的还是资源 A。

```cpp
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end,
               bool share) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));
    // copy content by page unit.
    do {
        // call get_pte to find process A's pte according to the addr start
        pte_t *ptep = get_pte(from, start, 0), *nptep;
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE); 
            continue;
        }
        // call get_pte to find process B's pte according to the addr start. If
        // pte is NULL, just alloc a PT
        if (*ptep & PTE_V) {
            if ((nptep = get_pte(to, start, 1)) == NULL) {
                return -E_NO_MEM;
            }
            uint32_t perm = (*ptep & PTE_USER);
            // get page from ptep
            struct Page *page = pte2page(*ptep);
            // alloc a page for process B
            struct Page *npage = alloc_page();
            assert(page != NULL);
            assert(npage != NULL);
            int ret = 0;
            /* LAB5:EXERCISE2 YOUR CODE
             * replicate content of page to npage, build the map of phy addr of
             * nage with the linear addr start
             *
             * Some Useful MACROs and DEFINEs, you can use them in below
             * implementation.
             * MACROs or Functions:
             *    page2kva(struct Page *page): return the kernel vritual addr of
             * memory which page managed (SEE pmm.h)
             *    page_insert: build the map of phy addr of an Page with the
             * linear addr la
             *    memcpy: typical memory copy function
             *
             * (1) find src_kvaddr: the kernel virtual address of page
             * (2) find dst_kvaddr: the kernel virtual address of npage
             * (3) memory copy from src_kvaddr to dst_kvaddr, size is PGSIZE
             * (4) build the map of phy addr of  nage with the linear addr start
             */
            void *src_kvaddr = page2kva(page);
            void *dst_kvaddr = page2kva(npage);
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
            ret = page_insert(to, npage, start, perm);
            
            assert(ret == 0);
        }
        start += PGSIZE;
    } while (start != 0 && start < end);
    return 0;
}
```
1.首先，我们确保开始和结束地址都是页对齐的，并且这些地址在用户空间内。

2.然后，我们开始按页单位复制内容。对于每个开始地址，我们首先获取源进程的页表项（PTE）。如果 PTE 不存在，我们就跳过这个地址，并继续处理下一个地址。

3.如果源 PTE 存在并且有效（即，对应的页在内存中），我们就获取目标进程的 PTE。如果目标 PTE 不存在，我们就分配一个新的页表。

4.接着，我们获取源 PTE 对应的页，并为目标进程分配一个新的页。

5.然后，我们找到源页和目标页的内核虚拟地址，并将源页的内容复制到目标页。

6.最后，我们将目标页插入到目标进程的页表中。

关于 Copy-on-Write (COW) 机制的设计，基本思想是当多个进程共享同一资源（例如，内存页）时，只有当某个进程试图修改该资源时，系统才会创建该资源的副本，以供该进程单独使用。这样，大部分时间内，资源可以被多个进程共享，从而节省内存。具体实现时，可以在页表项中设置一个标志，表示该页是否可以共享。当发生写操作时，如果发现该页被共享，则触发一个页面错误，由错误处理程序负责复制该页，并更新页表，使得发起写操作的进程看到的是新复制出的页。这样，对其他共享该页的进程是透明的，它们仍然看到的是原来的页。这就是 COW 机制的基本设计思想。具体的实现可能会根据操作系统的具体设计有所不同。例如，Linux 就有一套成熟的 COW 机制的实现。



#### 练习 3: 阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现（不
需要编码）
请在实验报告中简要说明你对 fork/exec/wait/exit 函数的分析。并回答如下问题：
• 请分析 fork/exec/wait/exit 的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核
态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？
• 请给出 ucore 中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系，以及
产生变换的事件或函数调用）。（字符方式画即可）
执行：make grade。如果所显示的应用程序检测都输出 ok，则基本正确。（使用的是 qemu-1.0.1）

1. fork函数：fork 函数在用户态开始执行，当一个进程调用 fork 时，操作系统会创建一个新的进程。新进程是原进程的一个副本，包括代码、堆栈、寄存器、打开的文件等。fork 在内核态完成实际的进程复制工作，然后将控制权返回给用户态。在父进程中，fork 返回新创建的子进程的 PID，在子进程中，fork 返回 0。

2. exec函数：exec 函数也在用户态开始执行，它会替换当前进程的映像（包括代码和数据）为一个新的程序的映像，然后开始执行新程序。exec 在内核态完成实际的映像替换工作，然后将控制权返回给用户态，开始执行新程序。

3. wait函数：wait 函数在用户态开始执行，它会使父进程暂停，直到一个子进程结束。如果子进程已经结束，wait 会立即返回。wait 在内核态检查子进程的状态，如果所有子进程都还在运行，wait 会使父进程进入睡眠状态，直到有一个子进程结束。当子进程结束时，内核会唤醒父进程，wait 返回结束的子进程的 PID。

4. exit函数：exit 函数在用户态开始执行，它会结束当前进程，并释放其所有资源。exit 在内核态完成实际的资源释放工作，然后将控制权交给操作系统，选择另一个进程运行。

内核态与用户态程序是交错执行的。当一个用户态程序需要操作系统服务时，比如调用一个系统调用，它会切换到内核态。内核完成服务后，再切换回用户态，返回到用户程序。内核态执行结果通常通过系统调用的返回值返回给用户程序。

以下是 ucore 中一个用户态进程的执行状态生命周期图：

```
新建 (new) --调度--> 就绪 (ready)
   ^                      |
   |                      v
退出 (exit) <--运行-- 运行 (running)
```

- 新建：进程被创建。
- 就绪：进程获得除 CPU 外的所有必要资源，等待 CPU 资源。
- 运行：进程获得 CPU 资源，正在执行。
- 退出：进程结束，等待父进程回收资源。

产生状态变换的事件或函数调用：
- 新建到就绪：进程被创建后，进入就绪状态，等待调度。
- 就绪到运行：进程调度程序选择一个就绪状态的进程，分配 CPU 资源，进程开始执行。
- 运行到就绪：进程的时间片用完，操作系统剥夺其 CPU 资源，进程回到就绪状态。
- 运行到退出：进程执行完毕，或者调用 exit 函数，进程进入退出状态。进程的资源还没有被回收。
- 退出到新建：父进程调用 wait 或 waitpid 函数，回收进程的资源，进程彻底结束。如果父进程创建了新的进程，新进程进入新建状态。如果父进程没有创建新的进程，那么这个转换不会发生。


#### 扩展练习 Challenge：
1. 实现 Copy on Write （COW）机制
给出实现源码, 测试用例和设计报告（包括在 cow 情况下的各种状态转换（类似有限状态自动机）的说
明）。
这个扩展练习涉及到本实验和上一个实验“虚拟内存管理”。在 ucore 操作系统中，当一个用户父进程
创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内
存空间中的页面（这就是一个共享的资源）。当其中任何一个进程修改此用户内存空间中的某页面时，
ucore 会通过 page fault 异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面。这
样一个进程所做的修改不会被另外一个进程可见了。请在 ucore 中实现这样的 COW 机制。
由于 COW 实现比较复杂，容易引入 bug，请参考 https://dirtycow.ninja/ 看看能否在 ucore 的 COW 实现
中模拟这个错误和解决方案。需要有解释。
这是一个 big challenge.
2. 说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？

