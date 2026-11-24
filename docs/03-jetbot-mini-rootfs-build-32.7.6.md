# Jetbot MINI 官方 L4T 32.7.6 U 盘 RootFS 构建

本文负责使用 NVIDIA 官方 L4T 32.7.6、官方 JetPack 4.6.6 软件仓库、官方 PyTorch/TensorRT 组件和 Yahboom Jetbot MINI 0.4.0 源码构建 U 盘 RootFS 的过程。该 RootFS 从目标 U 盘在 Jetson Nano 实机启动。

U 盘 RootFS 从官方 Sample RootFS 构建，不复制运行盘的 Notebooks、workspace 和缓存。

## 构建结果

| 项目 | 实际结果 |
| --- | --- |
| U 盘 | SanDisk 3.2Gen1 64GB |
| U 盘序列号 | `03028119121425094232` |
| 分区表 | GPT |
| 分区 | `/dev/sda1`，1 MiB 起始，整盘剩余空间 |
| 文件系统 | ext4，卷标 `JETBOT_ROOT` |
| 分区容量 | 约 57 GiB |
| RootFS 已用空间 | 约 6.3 GiB |
| RootFS 可用空间 | 约 47.0 GiB |
| ext4 检查 | `e2fsck` 无错误 |
| Bootloader 启动参数 | `root=/dev/sda1 rw rootwait rootfstype=ext4` |
| USB quirk | `usb-storage.quirks=0781:5581:u` |
| 默认用户 | `jetson` |
| 默认密码 | `yahboom` |
| Hostname | `jetson-desktop` |
| 构建状态 | 构建层修改、软件更新、镜像生成和离线文件系统验证完成 |

## 官方基础输入

### Sample RootFS

文件：

```text
Tegra_Linux_Sample-Root-Filesystem_R32.7.6_aarch64.tbz2
```

来源：

```text
https://developer.nvidia.com/embedded/l4t/r32_release_v7.6/t210/Tegra_Linux_Sample-Root-Filesystem_R32.7.6_aarch64.tbz2
```

校验：

```text
大小：1,527,551,065 字节
SHA-256：c0c25188be529b8e12ce33cda573451d8f63d580810f1e7dfe5406c1b088ca41
```

### L4T BSP

文件：

```text
Jetson-210_Linux_R32.7.6_aarch64.tbz2
```

校验：

```text
大小：279,353,831 字节
SHA-256：865717eed7076babd3c193fc39bc7df41cc457b554059d374c624c42bcde0212
```

RootFS 使用以下流程组装：

```bash
cd /build/L4T-32.7.6/Linux_for_Tegra/rootfs
sudo tar -xpf /build/incoming/Tegra_Linux_Sample-Root-Filesystem_R32.7.6_aarch64.tbz2
cd ..
sudo ./apply_binaries.sh
```

## 已安装的 JetPack 组件

NVIDIA 软件来源：

```text
https://repo.download.nvidia.com/jetson/common r32.7 main
https://repo.download.nvidia.com/jetson/t210 r32.7 main
```

实际组件：

| 组件 | 版本 |
| --- | --- |
| L4T Core | 32.7.6-20241104234540 |
| Linux kernel | `4.9.337-tegra` |
| CUDA runtime | 10.2.300 |
| cuDNN | 8.2.1.32 |
| TensorRT | 8.2.1.9 |
| OpenCV | 4.1.1 |
| VisionWorks | 1.6.0.501 |
| VPI | 1.2.3 |
| 登录管理器 | LightDM 1.26.0 + slick-greeter 1.1.4 |

Python 与应用组件：

| 组件 | 版本或来源 |
| --- | --- |
| Python | `3.6.9` |
| pip | `9.0.1` |
| PyTorch | `1.6.0a0+b31f58d` |
| TorchVision | `0.7.0a0+78ed10c` |
| Torch2TRT | 官方 GitHub `v0.5.0`，针对 TensorRT 8.2 重编译 |
| Jetbotmini | `0.4.0`，针对 TensorRT 8.2 重编译 |
| JetCam | 0.0.0 |
| Jupyter | 1.0.0 |
| JupyterLab | 2.2.9 |
| Notebook | 6.1.4 |
| ipywidgets | 7.5.1 |
| Flask | 1.1.2 |
| Adafruit SSD1306 | 1.6.2 |
| Adafruit MotorHAT | 1.4.0 |

系统保留的 Python、C++、编辑器和硬件接口基线：

| 组件 | 版本或状态 |
| --- | --- |
| Python 开发环境 | `python3-dev`、`libpython3-dev`、`python3-venv` 已安装 |
| Python 硬件接口 | `python3-serial`、`python3-smbus`、`python3-jetson-gpio` 已安装 |
| C/C++ 基础环境 | `build-essential`、GCC/G++ 7.5.0、GNU Make 4.1、CMake 3.10.2 |
| Vim | 8.0 |
| Git | 2.17.1 |
| 摄像头工具 | `v4l-utils`，当前识别 IMX219 为 `/dev/video0` |
| 蓝牙软件栈 | `bluez` 5.48、`bluetooth`、`bluez-tools` |
| 蓝牙内核支持 | `CONFIG_BT`、`CONFIG_BT_HCIBTUSB`、`CONFIG_BT_HCIUART`、`CONFIG_BT_RFCOMM` |

Python 3.6 是 JetPack 4.6.6 和当前二进制组件的 ABI 基线。PyTorch、TensorRT Python 绑定、OpenCV、Jetson.GPIO、JetCam、Torch2TRT 和 Jetbotmini 均在该解释器下完成导入验证。镜像不把系统 Python 升级到 3.15；全局替换会破坏上述组件和 Ubuntu 18.04 的系统工具。

## 软件更新

构建 RootFS 在完成软件裁剪和 LightDM 安装后执行普通更新：

```bash
apt-get update
apt-get upgrade
```

执行升级前 hold NVIDIA L4T、CUDA、cuDNN、TensorRT、VisionWorks、VPI、OpenCV 和 JetBot Python 组件，避免普通升级改动核心运行时。

实际升级 9 个 Ubuntu 软件包：

```text
distro-info-data        0.37ubuntu0.21
python3-apport          2.20.9-0ubuntu7.29+esm3
python3-problem-report  2.20.9-0ubuntu7.29+esm3
python3-update-manager  1:18.04.13.1
ubuntu-advantage-tools  38ubuntu0~18.04
ubuntu-pro-client       38ubuntu0~18.04
update-manager-core     1:18.04.13.1
wireless-regdb          2026.05.30-0ubuntu1~18.04.1
wpasupplicant           2:2.6-15ubuntu2.8+esm1
```

构建 RootFS 与运行盘均有 1998 个 `ii` Debian 包；包名、版本和 APT hold 状态逐项一致。

## 包完整性验证

`dpkg --audit` 没有输出，Debian 包数据库没有半安装或损坏包。

以下 Python 模块在 RootFS 的 ARM64 chroot 中完成导入验证：

```text
numpy
torch
torchvision
torch2trt
torch2trt.plugins
jetcam
cv2
tensorrt
flask
jupyter
notebook
ipywidgets
Adafruit_GPIO
Adafruit_SSD1306
smbus
serial
spidev
```

`libssd_tensorrt.so` 通过 `ctypes.CDLL` 加载验证。动态依赖为：

```text
libnvinfer.so.8
libcublas.so.10
```

## 镜像裁剪内容

镜像不包含以下内容：

- Chromium 浏览器及语言包。
- Thunderbird 邮件客户端。
- LibreOffice 全套组件。
- Docker、containerd、runc、NVIDIA Container Toolkit。
- NVIDIA Nsight Systems。
- CUDA、cuDNN、TensorRT、VisionWorks、VPI 示例和文档。
- CUDA 编译工具、开发头文件和 kernel headers。
- Snapd 与挂载的 Snap 包。
- BlueMan 蓝牙管理器。
- Python 2 版 NumPy、Pillow、VPI。
- 游戏、音乐播放器、视频播放器、图片管理器、Transmission、Remmina、扫描、备份和示例媒体。
- LXDE、Openbox 备用桌面栈及 KWin/KDE 安装器组件。
- GDM3；登录管理器为 LightDM + slick-greeter。
- Ubuntu 安装器、OEM 首次启动向导、桌面软件中心、GUI 更新器和遥测/崩溃收集组件。
- GPS、NFS、RPC、DHCP 服务端、蓝牙 OBEX 工具、打印驱动、传真式 PPP 和 PCMCIA 工具。
- Ubuntu 原配壁纸包内容。
- 运行盘中的 `Notebooks`、`workspace`、JetCam 源码和构建目录。
- APT 包缓存、APT 索引、临时文件和日志。

RootFS 当前约 6.3 GiB（Sample RootFS 约 17 GiB）。当前系统共有 1998 个处于 `ii` 状态的 Debian 包，`apt-get check` 和 `dpkg --audit` 均无错误。

运行所需的 CUDA、cuDNN、TensorRT、OpenCV、VPI、VisionWorks 运行库以及 PyTorch、TorchVision、Torch2TRT 和 Jetbot 原生插件均保留。

## 桌面壁纸

壁纸源文件：

[current-windows-wallpaper.jpg](../05_BUILD_ASSETS/current-windows-wallpaper.jpg)

参数：

```text
分辨率：6016x3384
文件大小：9,726,892 字节
SHA-256：8275e85079a7b00ec61357710d72f6ed473e8fa02a88fc6709388110ce16e64e
```

镜像内使用 2K 版本：

```text
分辨率：2560x1440
文件大小：254,455 字节
SHA-256：367ac979392681d872f8a7847fdc7eccc17b6c8e8302dcf3550ab54ae8932422
```

RootFS 中的位置：

```text
/usr/share/backgrounds/jetbot-mini/current-windows-wallpaper.jpg
```

桌面、锁屏和登录界面通过以下配置层设置：

```text
/usr/share/glib-2.0/schemas/99_jetbot-wallpaper.gschema.override
/usr/share/glib-2.0/schemas/10_ubuntu-settings.gschema.override
/usr/share/glib-2.0/schemas/com.canonical.unity-greeter.gschema.xml
/etc/dconf/db/local.d/00-jetbot-background
/etc/xdg/autostart/nvbackground.sh
/etc/lightdm/slick-greeter.conf
/etc/lightdm/lightdm.conf.d/90-jetbot.conf
```

配置内容：

```text
[org.gnome.desktop.background]
picture-uri='file:///usr/share/backgrounds/jetbot-mini/current-windows-wallpaper.jpg'
picture-options='zoom'
```

`ubuntu-wallpapers` 是本地占位包，版本 `18.04.1-0ubuntu1+yahboom1`，不含壁纸文件；`ubuntu-wallpapers-bionic` 未安装。`/usr/share/backgrounds` 只保留：

```text
/usr/share/backgrounds/jetbot-mini/current-windows-wallpaper.jpg
/usr/share/backgrounds/NVIDIA_Login_Logo.png
/usr/share/backgrounds/NVIDIA_Logo.png
```

## 启动配置

`extlinux.conf`：

```text
LINUX /boot/Image
INITRD /boot/initrd
APPEND ${cbootargs} quiet root=/dev/sda1 rw rootwait rootfstype=ext4 \
  console=ttyS0,115200n8 console=tty0 fbcon=map:0 net.ifnames=0 \
  usb-storage.quirks=0781:5581:u
```

启用的服务：

```text
jetbotmini_start.service
jetbotmini_stats.service
nano_jupyter.service
ssh.service
lightdm.service
bluetooth.service
```

Wi-Fi AP 配置：

```text
SSID：jetbot-mini
密码：12345678
接口地址：192.168.1.11/24
网关：192.168.1.1
IPv4 方法：shared
```

## 生成系统镜像

镜像从 `/build/L4T-32.7.6/Linux_for_Tegra/rootfs` 生成，再按 U 盘 VID:PID 复制出 32G 和 64G 两个版本。布局：

```text
大小：17,179,869,184 字节（16 GiB）
分区表：GPT
分区 1：1 MiB 起始
文件系统：ext4，卷标 JETBOT_ROOT
```

制作方式：

```bash
truncate -s 16G 01_JETBOT_MINI_BASE.img
sgdisk --clear --set-alignment=2048 --new=1:2048:0 \
  --typecode=1:8300 --change-name=1:JETBOT_ROOT \
  01_JETBOT_MINI_BASE.img
losetup --find --show --partscan 01_JETBOT_MINI_BASE.img
mkfs.ext4 -F -L JETBOT_ROOT /dev/loopXp1
mount /dev/loopXp1 /mnt/jetbot-image
rsync -aHAX --numeric-ids --one-file-system \
  --exclude='/proc/*' --exclude='/sys/*' --exclude='/dev/*' \
  --exclude='/run/*' --exclude='/tmp/*' --exclude='/var/tmp/*' \
  rootfs/ /mnt/jetbot-image/
sync
umount /mnt/jetbot-image
e2fsck -f -y /dev/loopXp1
```

验证结果：

```text
JETBOT_ROOT: clean
136827/1048576 inodes
1692192/4194043 blocks
sgdisk -v：No problems found
```

镜像与构建 RootFS 的 `rsync --checksum` 差异为 0。镜像只读挂载后确认 LightDM、slick-greeter、蓝牙工具、Python 开发环境和 2K 壁纸均存在。

两个成品镜像的 SHA-256：

```text
32G  01_JETBOT_MINI_32G_20261124.img
     8c5217791a36f2f6d8565076ad43a30be66070476d0d3981700ff9a6de28c7fb

64G  01_JETBOT_MINI_64G_20261124.img
     21b5ba5554a13ea667099de3c488b8ed3befcf4e0804af37c3fff516bc4284c7
```

完整构建元数据位于 `01_SYSTEM_IMAGE/BUILD_METADATA/`，包含 1998 个软件包及版本、53 个 APT hold、`fstab` 和 `extlinux.conf`。

关键镜像文件校验：

```text
/boot/Image
SHA-256：63fff7ba49e14a445e45fb26b1b48097a6af20320fb5fee014104100751eb42b

/boot/initrd
SHA-256：0a5f86c9507afdc52d5cd335be3a62304a841a263d9de14ccc5062f086432451

current-windows-wallpaper.jpg
SHA-256：367ac979392681d872f8a7847fdc7eccc17b6c8e8302dcf3550ab54ae8932422
```

## 实机启动基线

目标 U 盘接入 Jetson Nano USB 3.0 接口并上电后的实际结果：

```text
U-Boot 找到目标 U 盘
内核加载 /boot/Image 和 /boot/initrd
根文件系统为 /dev/sda1，ext4
Linux 内核为 4.9.337-tegra
Wi-Fi AP jetbot-mini 正常工作
Jetbot Web、JupyterLab、SSH 正常工作
df -B1 /：已用 6,670,188,544 字节
```

镜像已完成 GPT、ext4、RootFS 文件级一致性和关键文件哈希验证。运行盘与构建 RootFS 的登录管理器均为 LightDM + slick-greeter，未安装 GDM3。

系统详情和当前运行验证见 [06 成功系统记录](06-jetbot-mini-successful-system.md)。
