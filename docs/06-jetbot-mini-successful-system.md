# JetBot MINI 成功系统记录

本文只记录当前运行系统的实际状态，包括版本组合、根文件系统、软件环境、服务、端口和外设验证。硬件身份与存储能力见 [01 硬件实况](01-jetbot-mini-hardware-truth.md)，SPI 烧录过程见 [04 官方引导更新](04-jetbot-mini-official-bootloader-update.md)，RootFS 构建与裁剪见 [03 官方 32.7.6 RootFS 构建](03-jetbot-mini-rootfs-build-32.7.6.md)。

核对方式：通过 SSH 登录运行中的 Jetbot MINI 并执行检查。

## 当前版本组合

| 项目 | 实际版本 |
| --- | --- |
| 主机名 | `jetson-desktop` |
| Ubuntu | 18.04.6 LTS（bionic） |
| L4T RootFS | R32.7.6 |
| JetPack | 4.6.6 |
| Linux 内核 | `4.9.337-tegra` |
| CPU 架构 | `aarch64` |
| 默认用户 | `jetson` |
| 默认密码 | `yahboom` |
| 登录管理器 | LightDM + slick-greeter |
| SPI Bootloader | NVIDIA 官方 L4T 32.7.6，U-Boot `2020.04-g904285e3a7` |

当前 SPI Bootloader 与 U 盘 RootFS 都是 L4T 32.7.6。该组合从目标 U 盘完成实机启动。

## 启动与根文件系统

实际启动设备：

```text
/dev/sda1
```

根文件系统：

```text
FSTYPE：ext4
总容量：约 28.1 GiB
已使用：约 6.2 GiB
可用：约 20.5 GiB
```

核对命令：

```bash
findmnt -no SOURCE,FSTYPE,SIZE,USED,AVAIL /
df -B1 /
```

当前 U 盘的有效启动参数：

```text
usb-storage.quirks=0781:5583:u
```

没有该参数时，UAS 会导致根盘离线。U 盘型号、VID:PID 和序列号见硬件实况。

## 软件环境

| 组件 | 当前版本或状态 |
| --- | --- |
| Python | 3.6.9 |
| pip | 9.0.1 |
| CUDA runtime | 10.2.300 |
| cuDNN | 8.2.1.32 |
| TensorRT | 8.2.1.9 |
| VisionWorks | 1.6.0.501 |
| OpenCV | 4.1.1 |
| VPI | 1.2.3 |
| PyTorch | `1.6.0a0+b31f58d` |
| TorchVision | `0.7.0a0+78ed10c` |
| ROS | 未安装 |

Python 3.6.9 是当前 JetBot 二进制的运行基线。系统没有安装 Python 3.15，也没有替换 Ubuntu 18.04 的系统 Python。

9 个 Ubuntu 软件包的当前版本：

```text
distro-info-data 0.37ubuntu0.21
python3-apport 2.20.9-0ubuntu7.29+esm3
python3-problem-report 2.20.9-0ubuntu7.29+esm3
python3-update-manager 1:18.04.13.1
ubuntu-advantage-tools 38ubuntu0~18.04
ubuntu-pro-client 38ubuntu0~18.04
update-manager-core 1:18.04.13.1
wireless-regdb 2026.05.30-0ubuntu1~18.04.1
wpasupplicant 2:2.6-15ubuntu2.8+esm1
```

NVIDIA L4T、CUDA、cuDNN、TensorRT、VisionWorks、VPI、OpenCV 和 JetBot Python 组件继续锁定，不参与普通升级。

## Python、C++、Vim 与 JetBot 基线

已安装并保留：

```text
python3
python3-dev
libpython3-dev
python3-venv
python3-pip
python3-setuptools
python3-wheel
python3-serial
python3-smbus
jetson-gpio-common
python3-jetson-gpio
build-essential
gcc
g++
make
cmake
git
vim
```

实际版本：

```text
Python 3.6.9
GCC/G++ 7.5.0
GNU Make 4.1
CMake 3.10.2
Git 2.17.1
Vim 8.0
```

JetBot Python 环境导入验证：

```text
numpy            OK
torch            OK
torchvision      OK
torch2trt        OK
jetcam           OK
cv2              OK
tensorrt         OK
flask            OK
jupyter          OK
notebook         OK
ipywidgets       OK
Adafruit_GPIO    OK
Adafruit_SSD1306 OK
smbus            OK
serial           OK
spidev           OK
jetbotmini       OK
```

CUDA 运行验证：

```text
PyTorch CUDA available：True
CUDA device：NVIDIA Tegra X1
```

主要系统目录：

```text
/home/jetson/yahboom-jetbotmini
/home/jetson/Notebooks
```

## 摄像头

`v4l-utils` 已安装，当前识别到：

```text
vi-output, imx219 7-0010
设备节点：/dev/video0
```

## 蓝牙

已安装：

```text
bluez 5.48
bluez-tools
bluetooth
rfkill
```

可用命令：

```text
bluetoothctl
btmgmt
hciconfig
bt-device
```

`bluetooth.service` 当前为：

```text
active (running)
```

内核已包含 `CONFIG_BT`、`CONFIG_BT_RFCOMM`、`CONFIG_BT_HCIBTUSB`、`CONFIG_BT_HCIUART`、`CONFIG_BT_RTL` 和 `CONFIG_BT_BCM`。

当前系统没有枚举到蓝牙 HCI 控制器：`/sys/class/bluetooth` 为空，`rfkill list bluetooth` 无输出。蓝牙软件栈和驱动保留，实际控制器状态见硬件实况。

## 桌面与壁纸

当前桌面为 GNOME（`gnome-shell`，`XDG_CURRENT_DESKTOP=ubuntu:GNOME`），会话文件 `ux-ubuntu.desktop`。登录管理器为 LightDM + slick-greeter，未安装 GDM3。壁纸文件：

```text
/usr/share/backgrounds/jetbot-mini/current-windows-wallpaper.jpg
```

参数：

```text
分辨率：2560x1440
文件大小：254,455 字节
SHA-256：367ac979392681d872f8a7847fdc7eccc17b6c8e8302dcf3550ab54ae8932422
```

`jetson` 用户的桌面背景和锁屏背景均指向该文件。LightDM 配置：

```text
/etc/lightdm/lightdm.conf.d/90-jetbot.conf
/etc/lightdm/slick-greeter.conf
```

slick-greeter 使用同一张 2K 壁纸，主题为 `Ambiance`，图标主题为 `ubuntu-mono-dark`。

`/usr/share/backgrounds` 当前只有：

```text
jetbot-mini/current-windows-wallpaper.jpg
NVIDIA_Login_Logo.png
NVIDIA_Logo.png
```

## 服务验证

| 服务 | 当前状态 |
| --- | --- |
| `jetbotmini_start.service` | `active` |
| `jetbotmini_stats.service` | `active` |
| `nano_jupyter.service` | `active` |
| `ssh.service` | `active` |
| `lightdm.service` | 默认显示管理器，`display-manager.service` 指向该服务 |
| `bluetooth.service` | `active` |

核对命令：

```bash
systemctl is-active \
  jetbotmini_start.service \
  jetbotmini_stats.service \
  nano_jupyter.service \
  ssh.service \
  lightdm.service \
  bluetooth.service
systemctl --failed --no-legend
```

`systemctl --failed` 无输出。

## 服务与端口

| 服务 | 当前监听端口 |
| --- | --- |
| Jetbot Web 控制 | `6001/tcp` |
| JupyterLab | `8888/tcp` |
| SSH | `22/tcp` |

当前没有 VNC 服务监听 `5900/tcp`。

核对命令：

```bash
ss -ltnp
```

## 当前网络地址

当前地址：

```text
eth0：192.168.121.113/24
wlan0：192.168.1.11/24
USB RNDIS：192.168.55.1/24
```

Wi-Fi AP：

```text
SSID：jetbot-mini
密码：12345678
```

地址通过以下命令读取：

```bash
ip -br addr
```

## 包完整性

当前系统有 1998 个处于 `ii` 状态的 Debian 包。

核对命令：

```bash
sudo dpkg --configure -a
sudo apt-get check
sudo dpkg --audit
```

三项检查均没有包数据库错误。CUDA、cuDNN、TensorRT、OpenCV、VPI、VisionWorks、PyTorch 和 JetBot 组件已标记为手工保留，后续执行软件清理时不会被当作孤立依赖自动删除。

## 图形登录与运行状态

LightDM 完成认证后进入 `ux-ubuntu` 会话，`192.168.121.113` 的 SSH 可用。`Failed to start session` 的对应关系：

- 认证返回 `Authentication complete with return value 0: Success`，密码正确。
- 会话名错误时 `lightdm.log` 记录 `Failed to find session configuration ubuntu` 和 `Can't find session 'ubuntu'`。
- 原因：`user-session=ubuntu` 与 RootFS 中的会话文件 `ux-ubuntu.desktop` 不一致；`/usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf` 在加载顺序上后于 `/etc/lightdm/lightdm.conf.d/90-jetbot.conf`，只改后者不生效。

当前登录配置：

```text
/etc/lightdm/lightdm.conf.d/90-jetbot.conf        user-session=ux-ubuntu
/usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf  user-session=ux-ubuntu
/usr/share/xsessions/ubuntu.desktop -> ux-ubuntu.desktop
/home/jetson/.dmrc                                Session=ux-ubuntu
```

登录后 `loginctl` 出现 `seat0` 上的 `jetson` 会话，`gnome-shell` 运行，`slick-greeter` 退出。32G 和 64G 两个镜像包含同一配置。

两个独立问题：启动期间 `soctherm: OC ALARM 0x00000001` 持续刷屏；pstore 中存有 `nvgpu` SError 触发的 `Kernel panic - not syncing: bad mode` 和 PMC 看门狗复位记录，指向供电不足。设备仍会偶发重启，与登录配置无关。

## 结论

系统基线从目标 U 盘成功启动，根文件系统为 `/dev/sda1`。JetBot Web、JupyterLab、SSH、GNOME 桌面和 IMX219 摄像头已实机验证，Python/C++/Vim/JetBot 环境完整。

构建 RootFS 与两个 16 GiB 镜像的登录管理器均为 LightDM + slick-greeter，未安装 GDM3。

蓝牙软件栈和内核驱动完整，但当前硬件没有枚举出蓝牙控制器。
