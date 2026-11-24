# Jetbot MINI 官方 L4T 32.7.6 引导烧录

本文负责 NVIDIA L4T 32.7.6 SPI/QSPI Bootloader 的备份、生成、烧录和启动链验证。

硬件身份与存储能力由 [01 硬件实况](01-jetbot-mini-hardware-truth.md) 维护；VirtualBox、USB/IP 和主机软件由 [02 VirtualBox 烧录环境](02-jetbot-mini-virtualbox-flashing.md) 维护；U 盘镜像写入由 [05 U 盘镜像写入](05-jetbot-mini-usb-image-writing.md) 维护；系统服务与软件版本由 [06 成功系统记录](06-jetbot-mini-successful-system.md) 维护。

SPI 烧录只写 4 MiB SPI/QSPI，不重写 U 盘根文件系统，不写入 eMMC。

## 烧录结果

4 MiB SPI/QSPI 由 NVIDIA 官方 L4T R32.7.6 BSP 写入：

```text
板卡目标：jetson-nano-devkit
实际模块：P3448-0000，FAB 402，SKU 0000，PCB revision K.0
实际载板：P3449-0000-400
U-Boot：2020.04-g904285e3a7
构建日期：Nov 04 2024
烧录结果：The target t210ref has been flashed successfully.
```

重启后，U-Boot 从 SPI 正常加载，并继续找到现有 U 盘根文件系统 `/dev/sda1`。完整运行验证见 [06 成功系统记录](06-jetbot-mini-successful-system.md)。

## 官方文件

下载入口：

- NVIDIA JetPack/L4T 归档页：<https://developer.nvidia.com/embedded/jetson-linux-archive>
- 选择版本：Jetson Linux R32.7.6
- BSP 文件：`Jetson-210_Linux_R32.7.6_aarch64.tbz2`

| 项目      | 值                                                                  |
| ------- | ------------------------------------------------------------------ |
| 文件大小    | 279,353,831 字节                                                     |
| SHA-256 | `865717eed7076babd3c193fc39bc7df41cc457b554059d374c624c42bcde0212` |

BSP 从 NVIDIA 官方归档取得。文件身份由文件名、大小和 SHA-256 固定；虚拟机网络状态由 [02 VirtualBox 烧录环境](02-jetbot-mini-virtualbox-flashing.md) 记录。

## 烧录目标和板型前提

烧录 target：

```text
jetson-nano-devkit
```

Flash 期间 Cboot 读取的 EEPROM 参数为：

```text
module: 3448-0000-402
carrier: 3449-0000-400
FAB: 402
SKU: 0000
BOARDREV: K.0
```

这些值决定 DTB 和分区配置，只用于当前模块。完整硬件识别与 TNSPEC 差异由 [01 硬件实况](01-jetbot-mini-hardware-truth.md) 负责。

本操作不能使用：

```text
jetson-nano-devkit-emmc
jetson-nano-2gb-devkit
```

## 烧录前备份

已验证可启动的 SPI 备份：

```text
文件：02_BOOTLOADER/01_spi-backup-32.7.6-working.bin
大小：4,194,304 字节
SHA-256：85ea958e2baf8fa3438fe126a51bf681a24b4ce7eeaa2bda8161a52763d1787d
```

该备份来自 `/dev/mtdblock0` 的完整 4 MiB 读取。恢复方法未在本机实测；备份文件是 4 MiB SPI 原始内容，不是 U 盘磁盘镜像。工作区只有这一份已验证版本。

## 一、确认 Recovery/APX

开发板断电，连接 `FC REC-GND` 后重新上电。Ubuntu 虚拟机中的识别命令：

```bash
lsusb | grep -i 0955
```

输出：

```text
ID 0955:7f21 NVidia Corp.
```

烧录环境为 VirtualBox Ubuntu 18.04、内核 `4.15.0-213-generic`，通过 USB/IP 把 Windows 主机的 APX 设备转发给虚拟机。主机配置、BUSID 读取和重新 attach 步骤由 [02 VirtualBox 烧录环境](02-jetbot-mini-virtualbox-flashing.md) 记录。

## 二、读取真实板卡 EEPROM

在 `Linux_for_Tegra` 目录中执行：

```bash
sudo ./bootloader/tegraflash.py \
  --chip 0x21 \
  --applet ./bootloader/nvtboot_recovery.bin \
  --skipuid \
  --cmd "dump eeprom boardinfo cvm.bin"

sudo ./bootloader/tegraflash.py \
  --chip 0x21 \
  --applet ./bootloader/nvtboot_recovery.bin \
  --skipuid \
  --cmd "dump eeprom baseinfo bbd.bin"
```

读取结果：

```text
Board ID: 3448
FAB: 402
SKU: 0000
Asset ID: 1420123056810
Part Number: 699-13448-0000-402 K.0
Ethernet MAC: 48:b0:2d:d3:dc:84
```

`tegraflash.py` 读取 EEPROM 后会执行 `tegrarcm --reboot recovery`。USB/IP 连接在设备重新枚举时断开。重新 attach 的方法和实际错误日志由 VirtualBox 文档记录。

## 三、生成只含 SPI 分区的配置

官方 `flash_l4t_t210_max-spi_sd_p3448.xml` 同时包含：

```text
spi
sdcard
```

完整 XML 同时覆盖 SPI 和 sdcard。只更新 Bootloader 时，从副本中删除 `sdcard` 设备：

```bash
cd /build/L4T-32.7.6/Linux_for_Tegra

sed '/<device type="sdcard" instance="0">/,/<\/device>/d' \
  bootloader/t210ref/cfg/flash_l4t_t210_max-spi_sd_p3448.xml \
  > bootloader/t210ref/cfg/flash_l4t_t210_max-spi_p3448_spi_only.xml

xmllint --noout \
  bootloader/t210ref/cfg/flash_l4t_t210_max-spi_p3448_spi_only.xml

grep -n '<device' \
  bootloader/t210ref/cfg/flash_l4t_t210_max-spi_p3448_spi_only.xml
```

正确输出只能有一个设备：

```text
6:    <device type="spi" instance="0">
```

生成的 `bootloader/flash.xml` 只包含 SPI 引导分区，没有以下设备或分区：

```text
<device type="sdcard"
partition name="APP"
```

## 四、显式传入板卡参数

不传入 `BOARDID/FAB/BOARDSKU/BOARDREV` 时，`flash.sh` 再次读取 EEPROM 并重启目标板。USB/IP 连接随这次重启断开，烧录过程输出：

```text
BootRom is not running
Cannot open usb device.Check if device is in recovery
Failed flashing t210ref.
```

传入已读取的板卡参数，让 `flash.sh` 跳过 EEPROM 读取：

```bash
BOARDID=3448
FAB=402
BOARDSKU=0000
BOARDREV=K.0
```

这些值只适用于当前这块模块，不能作为其它 Nano、2GB 版或 eMMC 模块的模板。

## 五、先做 no-flash 检查

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

检查：

```bash
grep -n '<device\|<partition name' bootloader/flash.xml
cat bootloader/flashcmd.txt
```

关键结果：

```text
DTB: tegra210-p3448-0000-p3449-0000-b00.dtb
配置设备：只有 spi
SPI 分区数：19
SDCARD/APP 分区：0
--no-systemimg：Skip generating system.img
```

`mmcblk0p1` 是 NVIDIA Nano 配置接口要求的 rootdev 参数。自定义 XML 没有 sdcard/APP 项，该参数不会导致 U 盘被重新分区。U 盘由 `extlinux.conf` 中的 `root=/dev/sda1` 启动。

## 六、执行 SPI 烧录

确认 APX 再次可见：

```bash
lsusb | grep -i 0955
```

执行：

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

关键阶段：

```text
Boot Rom communication completed
Sending BCTs
Sending bootloader and pre-requisite binaries
Retrieving storage information
Flashing the device
Writing partition GPT
Writing partition PT
Writing partition NVC
Writing partition NVC_R
Writing partition TBC
Writing partition RP1
Writing partition EBT
Writing partition WB0
Writing partition BPF
Writing partition TOS
Writing partition DTB
Writing partition LNX
Writing partition EKS
Writing partition BMP
Writing partition RP4
Writing partition VER_b
Writing partition VER
Writing partition BCT
Flashing completed
The target t210ref has been flashed successfully.
```

从 `Flashing target device started` 到成功约 165 秒。USB/IP 下部分小分区耗时明显长于原生 USB；每个分区持续输出进度并在完成后进入下一项。

## 七、启动验证

1. 断开 Jetson 电源。
2. 移除 `FC REC-GND` 跳线。
3. 接上 32GB 或 64GB SanDisk U 盘（对应镜像与 quirk 见 [05 U 盘镜像写入](05-jetbot-mini-usb-image-writing.md)）。
4. 重新上电。

COM3 串口确认的完整启动链路：

```text
U-Boot 2020.04-g904285e3a7 (Nov 04 2024)
DRAM: 4 GiB
SanDisk 3.2Gen1
Capacity: 58655.6 MB
Found /boot/extlinux/extlinux.conf
Retrieving file: /boot/Image
root=/dev/sda1 ... usb-storage.quirks=0781:5581:u
Starting kernel ...
```

SSH 启动后检查：

```bash
findmnt -no SOURCE,FSTYPE /
cat /proc/cmdline
```

结果：

```text
/dev/sda1 ext4
root=/dev/sda1 ... usb-storage.quirks=0781:5581:u
```

系统版本、服务和端口的完整验证由 [06 成功系统记录](06-jetbot-mini-successful-system.md) 负责，本文只确认 Bootloader 已把控制权交给 U 盘根文件系统。

## 八、重要限制

- SPI/QSPI 只承载 Bootloader；L4T 32.7.6 RootFS 位于目标 U 盘。
- SPI 烧录不改变 U 盘 RootFS 中的 CUDA、TensorRT、Jetbot 和 Ubuntu 版本。
- 官方完整分区 XML 同时包含 `sdcard`；SPI-only 操作使用删除该设备的独立 XML。
- 当前硬件没有 eMMC，`jetson-nano-devkit-emmc` 与当前模块不对应。
- `BOARDID=3448 FAB=402 BOARDSKU=0000 BOARDREV=K.0` 是当前模块参数；其它模块使用各自 EEPROM 参数。
- 已验证的启动链依赖当前根盘的 UAS quirk；该盘级参数由 [05 U 盘镜像写入](05-jetbot-mini-usb-image-writing.md) 维护。
- SPI 原始内容只保留 `02_BOOTLOADER/01_spi-backup-32.7.6-working.bin`。
