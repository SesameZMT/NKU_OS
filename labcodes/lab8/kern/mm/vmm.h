#ifndef __KERN_MM_VMM_H__
#define __KERN_MM_VMM_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <sync.h>
#include <sem.h>
#include <proc.h>
//pre define
struct mm_struct;

// the virtual continuous memory area(vma), [vm_start, vm_end), 
// addr belong to a vma means  vma.vm_start<= addr <vma.vm_end 
struct vma_struct {
    struct mm_struct *vm_mm; // the set of vma using the same PDT   使用相同页目录表（PDT）的一组vma结构
    uintptr_t vm_start;      // start addr of vma      vma的起始地址
    uintptr_t vm_end;        // end addr of vma, not include the vm_end itself  vma的结束地址，不包括vm_end本身
    uint32_t vm_flags;       // flags of vma    vma的标志
    list_entry_t list_link;  // linear list link which sorted by start addr of vma   由vma的起始地址排序的线性链表链接
};

#define le2vma(le, member)                  \
    to_struct((le), struct vma_struct, member)

#define VM_READ                 0x00000001
#define VM_WRITE                0x00000002
#define VM_EXEC                 0x00000004
#define VM_STACK                0x00000008

// the control struct for a set of vma using the same PDT   一组使用相同页目录表（PDT）的虚拟内存区域的控制结构
struct mm_struct {
    list_entry_t mmap_list;        // linear list link which sorted by start addr of vma    按 vma（虚拟内存区域） 起始地址排序的线性链表链接
    struct vma_struct *mmap_cache; // current accessed vma, used for speed purpose  当前访问的 vma，用于加快访问速度
    pde_t *pgdir;                  // the PDT of these vma  这些 vma 所使用的页目录表（PDT）
    int map_count;                 // the count of these vma    这些 vma 的数量
    void *sm_priv;                 // the private data for swap manager 交换管理器的私有数据
    int mm_count;                  // the number ofprocess which shared the mm  共享该 mm 的进程数量
    semaphore_t mm_sem; // mutex for using dup_mmap fun to duplicat the mm  用于 dup_mmap 函数的互斥锁，用于复制 mm
    int locked_by;  // 上锁者
};

struct vma_struct *find_vma(struct mm_struct *mm, uintptr_t addr);
struct vma_struct *vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags);
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma);

struct mm_struct *mm_create(void);
void mm_destroy(struct mm_struct *mm);

void vmm_init(void);
int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store);
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr);

int mm_unmap(struct mm_struct *mm, uintptr_t addr, size_t len);
int dup_mmap(struct mm_struct *to, struct mm_struct *from);
void exit_mmap(struct mm_struct *mm);
uintptr_t get_unmapped_area(struct mm_struct *mm, size_t len);
int mm_brk(struct mm_struct *mm, uintptr_t addr, size_t len);

extern volatile unsigned int pgfault_num;
extern struct mm_struct *check_mm_struct;

bool user_mem_check(struct mm_struct *mm, uintptr_t start, size_t len, bool write);
bool copy_from_user(struct mm_struct *mm, void *dst, const void *src, size_t len, bool writable);
bool copy_to_user(struct mm_struct *mm, void *dst, const void *src, size_t len);
bool copy_string(struct mm_struct *mm, char *dst, const char *src, size_t maxn);

static inline int
mm_count(struct mm_struct *mm) {
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
    return mm->mm_count;
}

static inline int
mm_count_dec(struct mm_struct *mm) {
    mm->mm_count -= 1;
    return mm->mm_count;
}

static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        down(&(mm->mm_sem));
        if (current != NULL) {
            mm->locked_by = current->pid;
        }
    }
}

static inline void
unlock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        up(&(mm->mm_sem));
        mm->locked_by = 0;
    }
}

#endif /* !__KERN_MM_VMM_H__ */

