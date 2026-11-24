# Jetbot MINI VirtualBox 烧录环境

本文负责 Jetbot MINI SPI/QSPI 烧录所用的 Windows、VirtualBox、Ubuntu、USB/IP、BSP、串口和文件传输环境。

硬件事实见 [01 硬件实况](01-jetbot-mini-hardware-truth.md)，Bootloader 命令与日志见 [04 官方 SPI 引导更新](04-jetbot-mini-official-bootloader-update.md)，U 盘镜像写入见 [05 U 盘镜像写入](05-jetbot-mini-usb-image-writing.md)，运行系统状态见 [06 成功系统记录](06-jetbot-mini-successful-system.md)。

## 当前环境

### Windows 主机

| 项目 | 实际版本或状态 |
| --- | --- |
| VirtualBox | `7.2.22r175245` |
| usbipd-win | `5.3.0` |
| USB/IP 服务 | `usbipd`，运行中，启动类型 Automatic |
| USB/IP 防火墙规则 | 入站允许 |
| 网络 | 桥接网卡 `Realtek Gaming 2.5GbE Family Controller` |
| 当前主机地址 | `192.168.121.136/24` |
| 串口设备 | CH340，`USB\VID_1A86&PID_7523`，COM3 |

### VirtualBox 虚拟机

| 项目 | 实际配置 |
| --- | --- |
| 虚拟机名称 | `ubuntu1804` |
| UUID | `27f355c0-9108-480e-831b-b722efd44b64` |
| 客户系统 | Ubuntu (64-bit) |
| 虚拟机状态 | running |
| 内存 | 8192 MB |
| vCPU | 1 |
| 网卡模式 | 桥接 `82540EM` |
| USB 控制器 | EHCI 开启，XHCI 关闭 |
| VirtualBox USB 过滤器 | `NVIDIA-APX 0955:7f21`，当前 Active off |
| Guest Additions | `7.2.22r175245` |

### Ubuntu 虚拟机

| 项目 | 实际版本或状态 |
| --- | --- |
| 系统 | Ubuntu 18.04.6 LTS |
| 内核 | `4.15.0-213-generic` |
| 架构 | x86_64 |
| 内存 | 7.8 GiB |
| 当前地址 | `192.168.121.124/24` |
| 用户 | `ss` |
| 根分区 | `/dev/sda1`，25 GB，剩余约 3.2 GB |
| OpenSSH Client | `1:7.6p1-4ubuntu0.7` |
| OpenSSH Server | `openssh-server`，`ssh` 服务已启用并监听 22 |
| usbip | usbip-utils 2.0 |
| XML 工具 | libxml2-utils `2.9.4+dfsg1-6.1ubuntu1.9` |

### Ubuntu 18.04 安装镜像

虚拟机安装的是 `ubuntu-18.04.6-desktop-amd64.iso`。国内镜像站地址：

| 镜像站 | 下载地址 |
| --- | --- |
| 清华 TUNA | <https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/18.04/ubuntu-18.04.6-desktop-amd64.iso> |
| 中科大 USTC | <https://mirrors.ustc.edu.cn/ubuntu-releases/18.04/ubuntu-18.04.6-desktop-amd64.iso> |
| 华为云 | <https://mirrors.huaweicloud.com/ubuntu-releases/18.04/ubuntu-18.04.6-desktop-amd64.iso> |

服务器版：

<https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/18.04/ubuntu-18.04.6-live-server-amd64.iso>

各镜像站 18.04 目录同时提供 `SHA256SUMS`，用 `sha256sum -c SHA256SUMS --ignore-missing` 校验 ISO。

地址由 DHCP 分配。主机和虚拟机地址通过以下命令读取：

```powershell
Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object { $_.IPAddress -notlike '127.*' } |
  Select-Object InterfaceAlias,IPAddress,PrefixLength
```

```bash
ip -br addr
```

## 关键软件

### SSH 服务

虚拟机必须开启 SSH 服务，主机才能远程执行烧录命令、上传 BSP 和读取日志。

安装并启用：

```bash
sudo apt-get install -y openssh-server
sudo systemctl enable --now ssh
```

核对监听：

```bash
systemctl is-enabled ssh
systemctl is-active ssh
ss -ltn | grep ':22'
```

主机侧连接：

```powershell
ssh ss@192.168.121.124
```

### VirtualBox 和 Guest Additions

VirtualBox 与虚拟机 Guest Additions 同为 `7.2.22r175245`：

```bash
VBoxService --version
VBoxControl --version
```

输出：

```text
7.2.22r175245
7.2.22r175245
```

### usbipd-win 和 usbip

Windows 端服务：

```powershell
Get-Service usbipd
```

当前状态：

```text
Status   StartType    Name
Running  Automatic    usbipd
```

Ubuntu 端版本：

```bash
usbip version
```

输出：

```text
usbip (usbip-utils 2.0)
```

`usbip` 命令来自：

```text
linux-tools-common: /usr/bin/usbip
```

`usbipd list` 同时报告 USB 过滤器：

```text
Unknown USB filter 'hrdevmon'
USB filter 'USBPcap'
```

APX 绑定使用：

```powershell
usbipd bind --force --busid 4-4
```

### APX 与串口驱动的区别

两个不同类型、不同 VID:PID 的 USB 设备：

| 用途 | 设备 | VID:PID | Windows 类型 |
| --- | --- | --- | --- |
| NVIDIA Recovery 烧录 | APX | `0955:7f21` | USB 设备，接口类 `ff/ff/ff` |
| Jetson 串口日志 | CH340 | `1a86:7523` | USB-SERIAL，COM3 |

APX 是 NVIDIA RCM/Recovery Bulk USB 设备，不是 COM 串口。Windows 设备管理器中的 APX 驱动检查对应 `0955:7f21`；COM3 只负责 U-Boot 和 Linux 串口输出。

烧录环境是手工 L4T BSP：

```text
/build/L4T-32.7.6/Linux_for_Tegra
```

BSP 文件通过 SCP 传入虚拟机，解包命令：

```bash
sudo mkdir -p /build/L4T-32.7.6
sudo tar -xjf /build/incoming/Jetson-210_Linux_R32.7.6_aarch64.tbz2 \
  -C /build/L4T-32.7.6
cd /build/L4T-32.7.6/Linux_for_Tegra
```

BSP 文件大小和 SHA-256 由 [04 官方 SPI 引导更新](04-jetbot-mini-official-bootloader-update.md) 记录。

其中已生成：

```text
bootloader/flash.xml
bootloader/flashcmd.txt
```

### XML 校验依赖

`flash.sh` 调用 `xmllint`。虚拟机安装：

```bash
sudo apt-get install -y libxml2-utils
```

验证：

```bash
xmllint --version
```

### 串口工具

Windows 主机连接 CH340 USB-UART：

```text
端口：COM3
波特率：115200
数据位：8
校验：None
停止位：1
DTR：False
RTS：False
```

仓库中的只读串口脚本：

```text
E:\share\Jetson\.read_com10.ps1
```

该脚本单次采集 15 秒。烧录阶段使用相同的 115200 8N1 参数持续监听 10 分钟。

COM3 用于捕获 RCM、Cboot、U-Boot、Linux 内核和登录提示。

## 烧录步骤

### 1. 启动虚拟机并确认系统

主机执行：

```powershell
Test-NetConnection <虚拟机IP> -Port 22
ssh ss@<虚拟机IP>
```

虚拟机执行：

```bash
lsb_release -a
uname -a
df -h /
```

输出：

```text
Ubuntu 18.04.6 LTS
Linux 4.15.0-213-generic x86_64
/dev/sda1 25G 21G 3.2G 87% /
```

### 2. 将开发板接入 Recovery/APX

开发板断电，连接 `FC REC-GND`，再上电。

Windows 主机：

```powershell
usbipd list
```

目标设备：

```text
VID:PID  0955:7f21
DEVICE   APX
```

USB/IP 使用前，设备状态为 `Shared`。BUSID 为 `4-4`。

```powershell
usbipd bind --force --busid 4-4
```

### 3. 在 Ubuntu 中挂载 APX

虚拟机执行：

```bash
usbip list -r <Windows主机IP>
sudo modprobe vhci_hcd
sudo usbip attach -r <Windows主机IP> -b 4-4
lsusb | grep -i 0955
```

输出：

```text
Bus 003 Device 0xx: ID 0955:7f21 NVidia Corp.
```

直接执行 `usbip attach` 返回：

```text
usbip: error: recv op_common
usbip: error: query
```

先执行 `usbip list -r <Windows主机IP>`，再执行 `usbip attach`，设备进入虚拟机。

设备重新枚举期间，`usbip attach` 返回后存在短暂无 APX 的枚举窗口。枚举完成后读到：

```text
Bus 003 Device 009: ID 0955:7f21 NVidia Corp.
```

### 4. 读取 EEPROM 并识别板卡

EEPROM 读取命令和实际返回由 [04 官方 SPI 引导更新](04-jetbot-mini-official-bootloader-update.md) 记录。

读取过程调用：

```text
tegrarcm --reboot recovery
```

目标板因此重新枚举，USB/IP 中的 APX 设备随旧连接断开。烧录前重新执行：

```bash
usbip list -r <Windows主机IP>
sudo usbip attach -r <Windows主机IP> -b 4-4
lsusb | grep -i 0955
```

### 5. 生成 SPI-only 配置

在虚拟机 BSP 目录中生成只含 SPI 的分区 XML，并执行：

```bash
sudo env \
  BOARDID=3448 \
  FAB=402 \
  BOARDSKU=0000 \
  BOARDREV=K.0 \
  ./flash.sh \
    --no-flash \
    --no-systemimg \
    -c bootloader/t210ref/cfg/flash_l4t_t210_max-spi_p3448_spi_only.xml \
    jetson-nano-devkit \
    mmcblk0p1
```

生成结果：

```text
bootloader/flash.xml        只有 spi 设备
bootloader/flashcmd.txt     flash; reboot
system.img                  未生成
```

完整命令与分区输出见 Bootloader 文档。

### 6. 执行 SPI 烧录

从虚拟机执行：

```bash
sudo env \
  BOARDID=3448 \
  FAB=402 \
  BOARDSKU=0000 \
  BOARDREV=K.0 \
  ./flash.sh \
    --no-systemimg \
    -c bootloader/t210ref/cfg/flash_l4t_t210_max-spi_p3448_spi_only.xml \
    jetson-nano-devkit \
    mmcblk0p1
```

烧录约 165 秒，结束状态：

```text
The target t210ref has been flashed successfully.
```

### 7. 断开 Recovery 并启动

操作顺序：

```text
切断开发板电源
移除 FC REC-GND
保留有效 U 盘
重新上电
```

COM3 日志确认：

```text
U-Boot 2020.04-g904285e3a7
SanDisk 3.2Gen1
root=/dev/sda1
Starting kernel ...
```

系统进入 Ubuntu 后，通过 SSH 和串口完成运行验证。

## 已知问题与处理

| 现象 | 原因 | 实际处理 |
| --- | --- | --- |
| 按“Jetbot USB Serial”查找 APX 无结果 | APX 的接口类是 `ff/ff/ff`，不是 CDC/UART 串口 | 按 `0955:7f21` USB Recovery 设备处理，串口继续使用 CH340 COM3 |
| VirtualBox 自动捕获 APX 后烧录卡住 | 32 位 `tegrarcm` 在 VirtualBox USB 直通下卡在 Bulk I/O | 关闭 APX 自动捕获，改用 USB/IP |
| USB/IP 直接 attach 返回 `recv op_common` | usbipd 已共享设备，客户端连接未建立 | 先执行 `usbip list -r`，再执行 `usbip attach` |
| `lsusb` 中 APX 消失 | 目标执行 `--reboot recovery`，USB 设备重新枚举 | 主机重新识别后再次 attach |
| `flash.sh` 返回 `BootRom is not running` | EEPROM 读取后的 APX 重启使 USB/IP 连接断开 | 传入已读取的 Board ID/FAB/SKU/REV，跳过再次读取 EEPROM |
| `flash.sh` 报 `xmllint not found` | 虚拟机未安装 XML 工具 | 安装 `libxml2-utils` |
| `/media/sf_JetsonShare` 只读 | vboxsf 共享目录由 root 管理并挂载为只读 | 使用 SCP 传输文件 |
| 虚拟机系统盘空间紧张 | 25GB 根盘只剩约 3.2GB | 用 `/dev/sdb1` 的 `/build` 分区保存 RootFS、构建输入和镜像 |
| 烧录过程和 U-Boot 黑盒 | 仅凭 SSH 看不到 RCM/U-Boot 阶段 | 使用 CH340 COM3 以 115200 8N1 捕获串口 |

## VirtualBox 共享目录

vboxsf 共享目录的权限：

```text
/media/sf_JetsonShare
drwxr-x--- root root
```

执行：

```bash
sudo chmod u+x /media/sf_JetsonShare/
```

返回：

```text
chmod: changing permissions of '/media/sf_JetsonShare/': Read-only file system
```

该目录由 vboxsf 管理，`chmod` 不改变目录权限。

文件传输使用 SCP：

```powershell
scp .\03_BUILD_INPUTS\01_Jetson-210_Linux_R32.7.6_aarch64.tbz2 ss@192.168.121.124:/build/incoming/
```

## 磁盘容量影响

虚拟机根盘为 25GB。安装 BSP 和生成镜像后：

```text
已用：21GB
可用：3.2GB
使用率：87%
```

`/build` 位于第二块虚拟盘 `/dev/sdb1`，容量 49GB。当前已保存 32.7.6 RootFS、构建输入和 32G、64G 两个镜像。

## 串口与 SSH 分工

SSH 用于：

```text
虚拟机命令
BSP 文件上传
flash.sh 执行与日志
系统启动后的版本、服务和根盘检查
```

COM3 用于：

```text
RCM 与 TegraBoot
Cboot
U-Boot
内核启动
TTY 登录提示
```

烧录过程同时保留 SSH 输出和 COM3 输出。成功判定来自 `flash.sh` 的明确结束行，启动判定来自 U-Boot 加载 U 盘 `/boot/Image` 以及系统 SSH 恢复。
