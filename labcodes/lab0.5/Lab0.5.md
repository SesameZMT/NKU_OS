# 使用vmware安装Ubuntu
- 这一步很简单，略



# 安装python2.7
1. 执行以下命令
    ```sh
    wget http://www.python.org/ftp/python/2.7.5/Python-2.7.5.tar.bz2
    tar -xvjf Python-2.7.5.tar.bz2
    cd Python-2.7.5
    ./configure --prefix=/usr/local/python2.7 --with-threads --enable-shared --enable-unicode=ucs4
    make
    make install altinstall
    ln -s /usr/local/python2.7/lib/libpython2.7.so /usr/lib
    ln -s /usr/local/python2.7/lib/libpython2.7.so.1.0 /usr/lib
    ln -s /usr/local/python2.7/bin/python2.7 /usr/local/bin
    /sbin/ldconfig -v
    ```



# 配置Rust预编译工具链
1. 进入网址，在 ***Prebuilt RISC‑V GCC Toolchain and Emulator*** 中下载合适的压缩包（理论上来说下载好后的压缩包文件名是`riscv64-unknown-elf-gcc-2018.07.0-x86_64-linux-ubuntu14.tar.gz`）。
    ```sh
    https://d2pn104n81t9m2.cloudfront.net/products/tools/
    ```
    也可以在ubuntu终端中使用以下命令直接下载对应的版本：
    ```sh
    wget https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-2018.07.0-x86_64-linux-ubuntu14.tar.gz
    ```
2. 将文件拖拽入Ubuntu，并进行解压。
    ```sh
    tar -zxvf riscv64-unknown-elf-gcc-2018.07.0-x86_64-linux-ubuntu14.tar.gz
    ```
    解压后的名称理论上应该为`riscv64-unknown-elf-gcc-2018.07.0-x86_64-linux-ubuntu14`
3. 将解压好的文件添加到路径中。


    执行命令
    ```sh
    vim ~/.bashrc
    ```
    **注**：如果ubuntu中的终端默认程序是zsh,则需要更改以上命令为
    ```sh
    vim ~/.zshrc
    ```
    如果未下载vim，则可以通过以下命令下载：
    ```sh
    sudo apt install vim
    ```
    将打开的界面拖至最后一行，点击`i`键进入编辑模式，在最后一行进行以下插入：
    ```sh
    export RISCV=PATH_TO_INSTALL（你RISCV预编译链下载的路径）
    export PATH=$RISCV/bin:$PATH
    ```
    其中`PATH_TO_INSTALL`可以由解压后的文件拖入命令行得到，
    也可以在文件所在文件夹打开终端输入`pwd`命令获得文件路径，获取当前路径其形式为：`/home/sesame/riscv64-unknown-elf-gcc-2018.07.0-x86_64-linux-ubuntu14`。
    
    插入过后点击`esc`键推出编辑，之后输入`:wq`保存并退出。

    最后在命令行中执行
    ```sh
    source ~/.bashrc
    ```
    同样，如果安装了zsh，则需要更改以上命令为
    ```sh
    source ~/.zshrc
    ```
    即可完成配置。

    检测是否配置成功可以执行以下命令：
    ```sh
    riscv64-unknown-elf-gcc -v
    ```
    配置成功可以看到以下界面:
    ![Alt text](picture/Lab0.5Rust%E9%A2%84%E7%BC%96%E8%AF%91%E5%B7%A5%E5%85%B7%E9%93%BE%E9%85%8D%E7%BD%AE%E6%88%90%E5%8A%9F.png)



# 配置QEMU
1. 为防止后续安装报错，首先需执行以下命令：
    ```sh
    sudo apt-get install pkg-config
    sudo apt-get install libglib2.0-dev
    sudo apt-get install libpixman-1-dev
    sudo apt-get install libsdl2-2.0
    sudo apt-get install libsdl2-dev
    sudo apt-get install python2.7-dev
    ```
2. 在命令行中执行命令：
    ```sh
    wget https://download.qemu.org/qemu-4.1.1.tar.xz
    tar xvJf qemu-4.1.1.tar.xz
    cd qemu-4.1.1
    ./configure --target-list=riscv32-softmmu,riscv64-softmmu
    make
    export PATH=$PWD/riscv32-softmmu:$PWD/riscv64-softmmu:$PATH
    ```
    中间可能会由于网络问题出现报错，多尝试几次就好。或者还有一种解决方式：在物理机中打开`https://download.qemu.org/qemu-4.1.1.tar.xz`并对压缩包进行下载，之后拖到虚拟机中进行后续的解压等操作。
3. 将文件添加到路径中。


    执行命令
    ```sh
    vim ~/.bashrc
    ```
    将打开的界面拖至最后一行，点击`i`键进入编辑模式，在最后一行进行以下插入：
    ```sh
    export PATH=PATH_TO_INSTALL
    ```
    其中`PATH_TO_INSTALL`为绝对路径，可以由解压后的文件拖入命令行得到，其形式为：`~/qemu-4.1.1/riscv32-softmmu:~/qemu-4.1.1/riscv64-softmmu:$PATH`。
    
    插入过后点击`esc`键推出编辑，之后输入`:wq`保存并退出。

    最后在命令行中执行
    ```sh
    source ~/.bashrc
    ```
    即可完成配置。

    检测是否配置成功可以执行以下命令：
    ```sh
    qemu-system-riscv64 --version
    ```
    配置成功可以看到以下界面:
    ![Alt text](picture/Lab0.5QEMU%E9%85%8D%E7%BD%AE%E6%88%90%E5%8A%9F.png)



# 安装riscv64-unknown-elf-gdb
1. 为防止报错，建议在安装之前执行以下命令
    ```sh
    sudo apt install apt-file
    sudo apt-file update
    sudo apt-file find libncurses.so.5
    sudo apt install libncurses5
    ```
2. 在命令行中执行以下命令
    ```sh
    sudo apt-get install libncurses5-dev python2 python2-dev texinfo libreadline-dev
    wget https://mirrors.tuna.tsinghua.edu.cn/gnu/gdb/gdb-13.1.tar.xz
    tar -xvf gdb-13.1.tar.xz
    cd gdb-13.1
    mkdir build && cd build
    ../configure --prefix=/usr/local --target=riscv64-unknown-elf --enable-tui=yes
    make
    sudo make install
    ```

    检测是否配置成功可以执行以下命令：
    ```sh
    riscv64-unknown-elf-gdb -v
    ```
    配置成功可以看到以下界面:
    ![Alt text](picture/Lab0.5riscv64-unknown-elf-gdb%E5%AE%89%E8%A3%85%E6%88%90%E5%8A%9F.png)



# 练习

## 报告要求

* 基于markdown格式来完成，以文本方式为主
* 填写各个基本练习中要求完成的报告内容
* 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
* 列出你认为OS原理中很重要，但在实验中没有对应上的知识点


## 练习1：使用GDB验证启动流程

为了熟悉使用qemu和gdb进行调试工作,使用gdb调试QEMU模拟的RISC-V计算机加电开始运行到执行应用程序的第一条指令（即跳转到0x80200000）这个阶段的执行过程，说明RISC-V硬件加电后的几条指令在哪里？完成了哪些功能？要求在报告中简要写出练习过程和回答。

RISC-V 硬件加电后的一般执行过程如下：
* **复位向量表（Reset Vector Table）**： 当 RISC-V 处理器上电时，它会加载复位向量表的地址，通常位于物理地址 0x0 处。这个表包含了处理器在不同复位条件下要执行的指令。

* **跳转到复位地址**： 处理器会根据复位向量表中的条目，跳转到特定的复位地址。通常，这个地址是 0x80000000，也就是内存中的程序代码的起始地址。

* **执行初始化代码**： 处理器会开始执行位于复位地址处的初始化代码。这些代码通常包括处理器的基本设置，例如设置堆栈指针、设置寄存器、禁用或启用中断等等。

* **加载和执行应用程序**： 一旦初始化完成，处理器会加载并执行应用程序代码。这通常涉及到从存储设备（例如 Flash 存储器、SD 卡等）中加载应用程序二进制文件到内存中，并跳转到应用程序的入口点。

* ``x/10i 0x80000000`` : 显示 0x80000000 处的10条汇编指令。

* ``x/10i $pc`` : 显示即将执行的10条汇编指令。

* ``x/10xw 0x80000000`` : 显示 0x80000000 处的10条数据，格式为16进制32bit。

* ``info register``: 显示当前所有寄存器信息。

* ``info r t0``: 显示 t0 寄存器的值。

* ``break funcname``: 在目标函数第一条指令处设置断点。

* ``break *0x80200000``: 在 0x80200000 处设置断点。

* ``continue``: 执行直到碰到断点。

* ``si``: 单步执行一条汇编指令。

1. 内核运行成功截图


    opensbi运行成功
    ![Alt text](picture/%E5%9B%BA%E4%BB%B6opensbi%E8%BF%90%E8%A1%8C%E6%88%90%E5%8A%9F.png)


    makefile运行成功
    ![make file运行成功](picture/makefile%E8%BF%90%E8%A1%8C%E6%88%90%E5%8A%9F.png)

2. RISC-V硬件加电后的几条指令位置及其功能：

加电后第一条指令的作用是给寄存器`t0`赋值：

![Alt text](picture/%E5%8A%A0%E7%94%B5%E5%90%8E%E6%89%A7%E8%A1%8C%E7%AC%AC%E4%B8%80%E6%9D%A1%E6%8C%87%E4%BB%A4.png)

第一条指令的位置为`0x0000000000001000`

```sh
(gdb) si
0x0000000000001004 in ?? ()
(gdb) x/i 0x0000000000001004
=> 0x1004:	addi	a1,t0,32
(gdb) x/i 0x0000000000001000
   0x1000:	auipc	t0,0x0
(gdb) 

```

因此，以下便是加电后的几条指令：

```sh
(gdb) x/10i 0x0000000000001000
   0x1000:	auipc	t0,0x0
=> 0x1004:	addi	a1,t0,32
   0x1008:	csrr	a0,mhartid
   0x100c:	ld	t0,24(t0)
   0x1010:	jr	t0
```

`0x1000: auipc t0, 0x0`：用于将当前 PC 的值加上立即数 0x0 并将结果存储在寄存器 t0 中。用于生成全局地址。在这里，它将 t0 设置为 0。

`0x1004: addi a1, t0, 32`：将寄存器 t0 中的值 0 与立即数 32 相加，并将结果存储在寄存器 a1 中。

`0x1008: csrr a0, mhartid`：用于从 CSR（Control and Status Register） mhartid 中读取值，并将结果存储在寄存器 a0 中。这通常用于获取硬件线程 ID。

`0x100c: ld t0, 24(t0)`：用于从存储器中加载一个双字（64 位）的数据，并将结果存储在寄存器 t0 中。地址计算是将寄存器 t0 的值加上立即数 24。

`0x1010: jr t0`：用于跳转到寄存器 t0 中存储的地址，实现无条件跳转。


一旦初始化完成，处理器会加载应用程序二进制文件到内存中，这些指令会实现跳转到应用程序的入口点`t0`

通过`si`指令执行代码到`0x1010`的位置，再使用`info register`查看此时的寄存器`t0`的值。

![Alt text](picture/%E8%B7%B3%E8%BD%AC%E5%89%8Dt0%E7%9A%84%E5%80%BC.png)


可以知道，程序将会跳转到`2147483648`的位置，即`0x80000000`,`0x80000000`处的10条汇编指令如下：

```sh
(gdb) x/10i 0x80000000
   0x80000000:	csrr	a6,mhartid
   0x80000004:	bgtz	a6,0x80000108
   0x80000008:	auipc	t0,0x0
   0x8000000c:	addi	t0,t0,1032
   0x80000010:	auipc	t1,0x0
   0x80000014:	addi	t1,t1,-16
   0x80000018:	sd	t1,0(t0)
   0x8000001c:	auipc	t0,0x0
   0x80000020:	addi	t0,t0,1020
   0x80000024:	ld	t0,0(t0)
```

`0x80000000: csrr a6, mhartid`：用于从 CSR（Control and Status Register） mhartid 中读取值，并将结果存储在寄存器 a6 中。用于获取硬件线程 ID。

`0x80000004: bgtz a6, 0x80000108`：检查寄存器 a6 的值是否大于零，如果是，则跳转到地址 0x80000108 处执行。

`0x80000008: auipc t0, 0x0`：用于将当前 PC 的值加上立即数 0x0 并将结果存储在寄存器 t0 中。这通常用于生成全局地址。在这里，它将 t0 设置为 0。

`0x8000000c: addi t0, t0, 1032`：将寄存器 t0 中的值与立即数 1032 相加，并将结果存储在寄存器 t0 中。

`0x80000010: auipc t1, 0x0`：类似于第 3 条指令，它将 t1 设置为 0。

`0x80000014: addi t1, t1, -16`：将寄存器 t1 中的值与立即数 -16 相加，并将结果存储在寄存器 t1 中。

`0x80000018: sd t1, 0(t0)`：用于将寄存器 t1 中的值存储到地址为 t0 的内存中。它执行一个双字（64 位）的存储操作。

`0x8000001c: auipc t0, 0x0`：类似于第 3 条指令，它将 t0 设置为 0。

`0x80000020: addi t0, t0, 1020`：将寄存器 t0 中的值与立即数 1020 相加，并将结果存储在寄存器 t0 中。

`0x80000024: ld t0, 0(t0)`：用于从地址为 t0 的内存中加载一个双字（64 位）的数据，并将结果存储在寄存器 t0 中。


这段指令代码用于获取硬件线程 ID，进行地址计算，加载和存储数据。
