Jetbot MINI 硬件实况

核对依据：登录运行中的 Jetbot MINI，只读检查设备树、模块与载板 EEPROM、内存、USB、PCIe、I2C、摄像头、块设备和 SPI MTD，以及 Cboot/U-Boot 串口启动日志。

本文记录当前这台设备能够由软件、EEPROM 和启动日志确认的硬件事实。电机驱动、电池管理等仅靠 Linux 枚举不能确认的元器件不在本文范围内。

## 一句话结论

当前设备是搭载 **P3448-0000 4GB Jetson Nano 核心板**的 Jetbot MINI。核心板没有 eMMC，载板有 microSD 卡槽；完整系统位于 USB U 盘，4 MiB SPI/QSPI 只保存 Bootloader。

因此，当前硬件不能把完整操作系统存放在核心板内部，必须借助 U 盘、microSD 或更换带 eMMC 的核心板来实现掉电后仍可启动的系统。

## 计算核心

| 项目          | 实测结果                                   |
| ----------- | -------------------------------------- |
| 整机          | Yahboom Jetbot MINI                    |
| 计算平台        | NVIDIA Jetson Nano Developer Kit       |
| SoC         | NVIDIA Tegra X1/T210                   |
| 核心板         | `P3448-0000`                           |
| 模块 EEPROM   | `3448-0000-402`，PCB revision `K.0`     |
| 模块完整部件号     | `699-13448-0000-402 K.0`               |
| 载板          | `P3449-0000-400`                       |
| 设备树型号       | `NVIDIA Jetson Nano Developer Kit`     |
| 设备树兼容串      | `nvidia,p3449-0000-b00+p3448-0000-b00` |
| 内存          | 4GB 级，Linux 可用约 3.9 GiB                |
| CPU 架构      | `aarch64`，ARM Cortex-A57               |
| 模块 Asset ID | `1420123056810`                        |

模块与载板 EEPROM 由 Cboot 实际读取，硬件身份不依赖 RootFS 中的 TNSPEC 元数据。

设备树中的 `b00` 与 EEPROM 的 FAB `402` 对应。RootFS 中的 `jetson-nano-2gb-devkit` 属于元数据错误，不能用于判断真实硬件。

## 存储硬件

| 部位         | 实测情况                   | 能否保存完整系统          |
| ---------- | ---------------------- | ----------------- |
| SPI/QSPI   | 4 MiB，`/dev/mtdblock0` | 不能，只保存 Bootloader |
| 核心板 eMMC   | 不存在                    | 当前硬件不能            |
| 载板 microSD | 有控制器，当前未插卡             | 可以                |
| USB        | USB 3.0 接口             | 可以                |

### SPI/QSPI

实际 MTD 信息：

```text
dev:    size       erasesize  name
mtd0:   00400000   00001000   "spi32766.0"
```

对应：

```text
容量：4 MiB
设备：/dev/mtdblock0
SPI 芯片：Macronix MX25U3235F
```

当前 SPI 中的 Bootloader 为 NVIDIA 官方 L4T 32.7.6：

```text
U-Boot 2020.04-g904285e3a7
Build date: Nov 04 2024
```

SPI 仅包含 BCT、TegraBoot、CBoot、U-Boot、DTB、TOS 等启动组件，不能容纳 Ubuntu RootFS。

### eMMC

当前模块没有 eMMC。实测结果：

```text
/dev/mmcblk* 不存在
/proc/partitions 中没有 eMMC 块设备
/sys/class/mmc_host 只有 mmc0
U-Boot 输出：sdhci@700b0000: 1，sdhci@700b0600: 0
```

其中：

- `sdhci@700b0000` 对应载板 microSD。
- Linux 枚举为 `mmc0`。
- `sdhci@700b0600` 对应 SoC 的第二个 SD/MMC 控制器，U-Boot 报告设备数为 0。

因此不能使用 `jetson-nano-devkit-emmc` 对当前模块烧写所谓“eMMC 系统”。

### microSD

载板存在 microSD 控制器：

```text
/sys/class/mmc_host/mmc0
    -> /sys/devices/sdhci-tegra.0/mmc_host/mmc0
```

当前没有卡，所以系统中没有 `/dev/mmcblk0`。插入已写入有效系统的 microSD 后，根分区为：

```text
/dev/mmcblk0p1
```

该启动路径未在实机验证。

### U 盘（64GB）

| 项目          | 实测结果                   |
| ----------- | ---------------------- |
| 型号          | `SanDisk 3.2Gen1`      |
| USB 标称容量    | 64GB                   |
| Linux 可见容量  | 57.3 GiB               |
| USB VID:PID | `0781:5581`            |
| USB 序列号     | `03028119121425094232` |
| USB 驱动      | `usb-storage`          |
| 根分区         | `/dev/sda1` ext4       |
| 根分区容量       | 约 56.3 GiB             |

文件系统当前已用和可用空间属于运行状态，由 [06 成功系统记录](06-jetbot-mini-successful-system.md) 维护。

当前启动参数：

```text
usb-storage.quirks=0781:5581:u
```

### U 盘（32GB）

| 项目 | 实测结果 |
| --- | --- |
| 型号 | `SanDisk 3.2Gen1` |
| USB 标称容量 | 32GB |
| Linux 可见容量 | 28.7 GiB，60,125,184 扇区 |
| USB VID:PID | `0781:5583` |
| 写入后的分区布局 | p1 约 27G ext4，p2–p14 为 TBC/RP1/EBT/WB0/BPF/BPF-DTB/FX/TOS/DTB/LNX/EKS/BMP/RP4 小分区 |

当前启动参数：

```text
usb-storage.quirks=0781:5583:u
```

## 已确认的外围硬件

### 摄像头

设备树和 V4L2 识别到 Sony IMX219 CSI 摄像头：

```text
I2C 节点：7-0010  imx219
I2C 节点：8-0010  imx219
视频节点：/dev/video0
V4L2 设备：vi-output, imx219 7-0010
```

能够确认摄像头传感器为 IMX219。镜头模组的厂商、视场角和排线版本由实物标签确认。

### 无线网络

当前 Wi-Fi 是 USB 网卡：

```text
USB VID:PID：0bda:b812
Product：Realtek 802.11ac NIC
驱动：rtl88x2bu
接口：wlan0
```

可确认芯片系列为 Realtek RTL8812BU 一类 USB 802.11ac 网卡。外壳或模块品牌由实物确认。

### 蓝牙

当前内核包含常见蓝牙控制器支持：

```text
CONFIG_BT=y
CONFIG_BT_RFCOMM=y
CONFIG_BT_HCIBTUSB=m
CONFIG_BT_HCIUART=m
CONFIG_BT_RTL=m
CONFIG_BT_BCM=m
```

运行系统已安装 `bluez`、`bluetooth` 和 `bluez-tools`，`bluetooth.service` 为 `active (running)`。当前 USB 枚举中没有蓝牙 HCI 控制器，`/sys/class/bluetooth` 为空，`rfkill list bluetooth` 没有输出，`dmesg` 只显示 BNEP 协议层初始化。

结论：蓝牙软件栈和内核驱动保留，但当前接入的硬件没有向系统枚举出可用蓝牙控制器。USB Wi-Fi 网卡 `0bda:b812` 仅枚举为 802.11ac NIC，不能据此认定其包含蓝牙功能。

### 有线网络

载板 PCIe 有线网卡：

```text
Realtek RTL8111/8168/8411 PCI Express Gigabit Ethernet Controller
接口：eth0
```

当前 EEPROM 提供的主网卡 MAC：

```text
48:b0:2d:d3:dc:84
```

### 电源监测与基础器件

当前设备树成功加载：

```text
maxim,max77620 PMIC
ti,ina3221x 电源监测
```

这说明核心板使用 MAX77620 系列 PMIC，且设备树中存在 INA3221 三路电源监测节点。INA3221 的具体电流采样对象由载板原理图确定。

### USB 与 HID

当前 USB 层次中实际识别到：

```text
0bda:5411  Generic USB2.1 Hub
0bda:0411  Generic USB3.2 Hub
0bda:b812  Realtek 802.11ac NIC
391d:1a03  YJX-CHIP Dragonfly 3 Pro
260d:0042  USB 2.4G Receiver
0781:5581  SanDisk 3.2Gen1
```

`Dragonfly 3 Pro` 和 `USB 2.4G Receiver` 当前以 HID 接口枚举。仅凭 USB 描述无法确认它们是键盘、鼠标、遥控器还是机器人控制器。

## 无法由当前系统确认的硬件

以下内容不能仅根据 Jetbot 镜像或设备树中是否存在通用节点来下结论：

- 电机驱动芯片的具体型号。
- 电机数量、减速比和编码器类型。
- 电池电芯容量、串并联结构和保护板型号。
- OLED 的具体控制器型号。
- 扩展板 MCU 的型号和固件版本。
- 舵机、传感器和接口的完整清单。

这些项目由 Yahboom 扩展板丝印、连接器、电池标签或原理图确认。

## 当前实际启动链

```text
Tegra X1 BootROM
    -> 4 MiB SPI/QSPI
       -> BCT / TegraBoot / CBoot / U-Boot
          -> USB U 盘 /dev/sda1
             -> /boot/extlinux/extlinux.conf
             -> /boot/Image
             -> /boot/initrd
             -> Ubuntu + Jetbot MINI RootFS
```

关键启动参数：

```text
root=/dev/sda1 rw rootwait rootfstype=ext4
usb-storage.quirks=0781:5581:u
```

## 从零开始需要烧录什么

### 用 U 盘启动

需要两部分：

1. 向 SPI/QSPI 写入完整 Bootloader。
2. 向 U 盘写入完整 RootFS、`/boot/Image`、`/boot/initrd` 和 `extlinux.conf`。

U 盘根文件系统参数：

```text
root=/dev/sda1
```

这是当前验证成功的方案。

### 用 microSD 启动

需要两部分：

1. 向 SPI/QSPI 写入支持 SD/USB 启动的 Bootloader。
2. 向 microSD 写入完整 RootFS、`/boot/Image`、`/boot/initrd` 和 `extlinux.conf`。

Jetbot 系统迁移到 microSD 时，启动参数应改为：

```text
root=/dev/mmcblk0p1 rw rootwait rootfstype=ext4
```

不需要 U 盘专用的 `0781:5581` UAS quirk。

### 用 eMMC 启动

当前 P3448-0000 模块无法执行此方案。需要：

1. 更换为带 eMMC 的兼容核心板，例如 P3448-0002 系列。
2. 重新读取新模块 EEPROM，确认 Board ID、FAB 和 SKU。
3. 按新模块选择 eMMC 对应的 `flash.sh` target。
4. 写入 Bootloader 和完整 eMMC 系统镜像。

更换核心板涉及载板电气与机械兼容、散热、功耗和 BSP target。当前 P3448-0000 的命令与其它模块的 EEPROM 参数不对应。

## 能否板载系统

### 当前核心板自身存储

不可以。当前核心板没有 eMMC，4 MiB SPI 又不足以保存完整 RootFS。

### 不接 USB，但允许 microSD

可以。载板有 microSD 卡槽，可把系统放入机器内部的 microSD 卡中，不需要外露 U 盘。

这属于“使用载板卡槽”，不属于“操作系统存放在核心板 eMMC”。

### 完全不使用可插拔介质

需要更换带 eMMC 的兼容核心板。当前硬件无法仅靠重新烧录达到这个目标。

## 可复现的核对命令

```bash
uname -a
free -h
tr -d '\0' < /proc/device-tree/model
echo
tr '\0' '\n' < /proc/device-tree/compatible
lsblk -o NAME,MAJ:MIN,RM,SIZE,RO,TYPE,TRAN,FSTYPE,MODEL,SERIAL,MOUNTPOINT
cat /proc/mtd
ls -l /dev/mmcblk* /dev/mtd* /dev/sd* 2>/dev/null
ls -l /sys/class/mmc_host
lsusb
lsusb -t
lspci
ip -br link
v4l2-ctl --list-devices
findmnt -no SOURCE,FSTYPE,SIZE,USED,AVAIL /
```

模块与载板 EEPROM 读取和 SPI Bootloader 烧录细节见：

- [Jetbot MINI 官方 L4T 32.7.6 引导烧录](04-jetbot-mini-official-bootloader-update.md)
- [JetBot MINI 成功系统记录](06-jetbot-mini-successful-system.md)
