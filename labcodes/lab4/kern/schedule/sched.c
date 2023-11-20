#include <list.h>
#include <sync.h>
#include <proc.h>
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
    proc->state = PROC_RUNNABLE;
}

void
schedule(void) {
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
        last = (current == idleproc) ? &proc_list : &(current->list_link);
        le = last;
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
                    break;
                }
            }
        } while (le != last);
        if (next == NULL || next->state != PROC_RUNNABLE) {
            next = idleproc;
        }
        next->runs ++;
        if (next != current) {
            proc_run(next);
        }
    }
    local_intr_restore(intr_flag);
}

在多任务操作系统中选择下一个要运行的进程
1. `local_intr_save(intr_flag);` 和 `local_intr_restore(intr_flag);`
   这些函数调用用于保存和恢复中断状态，可能是为了确保在执行调度算法时不被中断打断，以防止在关键部分被中断干扰。
2. `current->need_resched = 0;`：
   将当前进程的调度标志位（`need_resched`）置为 0，表示当前进程不要被调度，这可能是为了避免当前进程被重复调度。
3. `last = (current == idleproc) ? &proc_list : &(current->list_link);`：
   确定下一个要检查的进程链表节点，根据当前进程是否为闲置进程（`idleproc`）来选择。如果当前进程是闲置进程，则从整个进程链表头开始检查，否则从当前进程的下一个节点开始。
4. `do { ... } while (le != last);`
   通过一个循环，在进程链表中遍历寻找下一个可运行的进程。在循环中，它会检查链表中的每个进程，找到下一个状态为 `PROC_RUNNABLE` 的进程。
5. `if (next == NULL || next->state != PROC_RUNNABLE)`
   如果找不到可运行的进程，或者下一个进程不是可运行状态，将 `next` 设置为 `idleproc`，表示选择闲置进程来运行。
6. `next->runs ++;`
   增加下一个要运行的进程的运行次数计数器。
7. `if (next != current)`：
   如果下一个要运行的进程不是当前正在运行的进程，则执行 `proc_run(next)`，将控制权交给下一个进程。
整体来说，这段代码的作用是选择下一个要执行的进程，它会遍历进程链表，找到一个可运行的进程，并将控制权交给这个进程。如果找不到可运行的进程，或者下一个进程不可运行，则选择闲置进程运行。