# 使用vmware安装Ubuntu
- 这一步很简单，略



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
    ![Alt text](picture/Lab0Rust%E9%A2%84%E7%BC%96%E8%AF%91%E5%B7%A5%E5%85%B7%E9%93%BE%E9%85%8D%E7%BD%AE%E6%88%90%E5%8A%9F.png)



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
    ![Alt text](picture/Lab0QEMU%E9%85%8D%E7%BD%AE%E6%88%90%E5%8A%9F.png)



# 练习

## 报告要求

* 基于markdown格式来完成，以文本方式为主
* 填写各个基本练习中要求完成的报告内容
* 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
* 列出你认为OS原理中很重要，但在实验中没有对应上的知识点


## 练习1：使用GDB验证启动流程

为了熟悉使用qemu和gdb进行调试工作,使用gdb调试QEMU模拟的RISC-V计算机加电开始运行到执行应用程序的第一条指令（即跳转到0x80200000）这个阶段的执行过程，说明RISC-V硬件加电后的几条指令在哪里？完成了哪些功能？要求在报告中简要写出练习过程和回答。

* ``x/10i 0x80000000`` : 显示 0x80000000 处的10条汇编指令。

* ``x/10i $pc`` : 显示即将执行的10条汇编指令。

* ``x/10xw 0x80000000`` : 显示 0x80000000 处的10条数据，格式为16进制32bit。

* ``info register``: 显示当前所有寄存器信息。

* ``info r t0``: 显示 t0 寄存器的值。

* ``break funcname``: 在目标函数第一条指令处设置断点。

* ``break *0x80200000``: 在 0x80200000 处设置断点。

* ``continue``: 执行直到碰到断点。

* ``si``: 单步执行一条汇编指令。

1. RISC-V硬件加电后的几条指令位置：





