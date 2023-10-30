#include <assert.h>
#include <defs.h>
#include <fs.h>
#include <ide.h>
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

// 初始化IDE设备
void ide_init(void) {}

// 定义IDE设备的最大数目和最大扇区数
#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

// 检查IDE设备编号是否有效
bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }

// 获取IDE设备扇区大小
size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }

// 从IDE设备中读取扇区数据
int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    //ideno: 假设挂载了多块磁盘，选择哪一块磁盘 这里我们其实只有一块“磁盘”，这个参数就没用到
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
    return 0;
}

// 将数据写入IDE设备的扇区
int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
    return 0;
}
