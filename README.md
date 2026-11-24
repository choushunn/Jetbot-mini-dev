# Jetbot MINI 项目说明

本目录记录当前 Jetbot MINI 的硬件事实、系统运行状态、VirtualBox/USB-IP 烧录环境、SPI 引导烧录、构建输入、系统镜像和 U 盘写入方法。

官方资料页：<https://www.yahboom.com/study/JETBOT-mini>

资料页提取码：`z2me`

## 系统组成

| 项目 | 说明 |
| --- | --- |
| 计算核心 | P3448-0000 4GB Jetson Nano 核心板，无 eMMC |
| 系统引导 | 4 MiB SPI/QSPI，NVIDIA 官方 L4T 32.7.6 U-Boot |
| RootFS | Ubuntu 18.04.6、L4T 32.7.6、JetPack 4.6.6、Linux 4.9.337，位于 U 盘 `/dev/sda1` |
| 系统盘 | U 盘 32GB（`0781:5583`）与 64GB（`0781:5581`），两个容量各有一份镜像 |
| 登录管理器 | LightDM 1.26 + slick-greeter 1.1.4，未安装 GDM3 |
| Python | 3.6.9，含 `python3-dev`、`python3-venv` 和 JetBot 全套 Python 组件 |
| 开发环境 | GCC/G++ 7.5、GNU Make、CMake、Git、Vim 8.0 |
| 蓝牙 | BlueZ 5.48、`bluetooth`、`bluez-tools` 和内核驱动 |
| 系统镜像 | `01_SYSTEM_IMAGE/01_JETBOT_MINI_32G_20261124.img` 与 `01_JETBOT_MINI_64G_20261124.img`，各 16 GiB，按 U 盘 VID:PID 分别带 UAS quirk |

启动验证、服务状态和软件版本见 [06 成功系统记录](docs/06-jetbot-mini-successful-system.md)。

当前核心板没有 eMMC，系统运行在 U 盘上。载板带 microSD 卡槽，该启动路径尚未实机验证。

## 默认连接信息

当前镜像的默认值：

| 项目 | 默认值 |
| --- | --- |
| Wi-Fi 名称 | `jetbot-mini` |
| Wi-Fi 密码 | `12345678` |
| 系统用户名 | `jetson` |
| 系统密码 | `yahboom` |

`z2me` 是雅博资料网页的下载提取码，不是 Wi-Fi 或系统密码。

## 工作区结构

| 目录 | 内容 |
| --- | --- |
| `01_SYSTEM_IMAGE` | 32G/64G 未压缩 `.img`、SHA-256 和构建元数据 |
| `02_BOOTLOADER` | 已验证的 L4T 32.7.6 SPI 原始备份 |
| `03_BUILD_INPUTS` | BSP/Sample RootFS 下载地址、用户覆盖层和系统覆盖层 |
| `04_TOOLS` | usbipd 与 tegrarcm 下载地址、绑定和安装脚本 |
| `05_BUILD_ASSETS` | 壁纸、LightDM、dconf、启动脚本和本地占位包源 |
| `docs` | 编号文档，入口见 `docs/00-INDEX.md` |

关键文件清单和校验见 [00 关键文件清单](00_KEY_FILES.md)。

## 文档职责

| 文档 | 只负责 |
| --- | --- |
| [00 文档索引](docs/00-INDEX.md) | 文档编号、阅读顺序和职责 |
| [01 硬件实况](docs/01-jetbot-mini-hardware-truth.md) | 实际硬件、存储能力、启动介质选择和外围设备识别 |
| [02 VirtualBox 烧录环境](docs/02-jetbot-mini-virtualbox-flashing.md) | Windows、虚拟机、USB/IP、关键软件、串口和已复现问题 |
| [03 官方 32.7.6 RootFS 构建](docs/03-jetbot-mini-rootfs-build-32.7.6.md) | 官方 RootFS、JetPack、软件裁剪、更新、LightDM、Python/C++/Vim/蓝牙基线、2K 壁纸和镜像制作 |
| [04 官方 SPI 引导更新](docs/04-jetbot-mini-official-bootloader-update.md) | L4T 32.7.6 Bootloader 备份、SPI-only 烧录和恢复信息 |
| [05 U 盘镜像写入](docs/05-jetbot-mini-usb-image-writing.md) | 镜像身份、整盘写入、GPT/分区扩容、extlinux 和 UAS 兼容 |
| [06 成功系统记录](docs/06-jetbot-mini-successful-system.md) | 当前系统版本、实机运行验证、软件环境、服务和端口 |

每项操作及其事实证据位于对应文档。Bootloader、U 盘镜像和运行系统是三个独立对象。
