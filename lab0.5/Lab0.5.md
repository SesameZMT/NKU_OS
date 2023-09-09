# 使用vmware安装Ubuntu
- 这一步很简单，略



# 配置Rust预编译工具链
1. 进入网址，在 ***Prebuilt RISC‑V GCC Toolchain and Emulator*** 中下载合适的压缩包（理论上来说下载好后的压缩包文件名是`riscv64-unknown-elf-gcc-2018.07.0-x86_64-linux-ubuntu14.tar.gz`）。
    ```sh
    https://d2pn104n81t9m2.cloudfront.net/products/tools/
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
    将打开的界面拖至最后一行，点击`i`键进入编辑模式，在最后一行进行以下插入：
    ```sh
    export RISCV=PATH_TO_INSTALL（你RISCV预编译链下载的路径）
    export PATH=$RISCV/bin:$PATH
    ```
    其中`PATH_TO_INSTALL`可以由解压后的文件拖入命令行得到，其形式为：`/home/sesame/riscv64-unknown-elf-gcc-2018.07.0-x86_64-linux-ubuntu14`。
    
    插入过后点击`esc`键推出编辑，之后输入`:wq`保存并退出。

    最后在命令行中执行
    ```sh
    source ~/.bashrc
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

    检测是否配置成功可以执行以下命令：
    ```sh
    qemu-system-riscv64 --version
    ```
    配置成功可以看到以下界面:
    ![Alt text](picture/Lab0QEMU%E9%85%8D%E7%BD%AE%E6%88%90%E5%8A%9F.png)