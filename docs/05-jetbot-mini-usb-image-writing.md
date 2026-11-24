# JetBot MINI U 盘镜像写入方法

本文负责两个系统镜像（32G/64G）的身份、校验、整盘写入、分区扩展和 UAS 兼容处理。硬件见 [01 硬件实况](01-jetbot-mini-hardware-truth.md)，构建过程见 [03 官方 32.7.6 RootFS 构建](03-jetbot-mini-rootfs-build-32.7.6.md)，SPI 引导见 [04 官方 SPI 引导更新](04-jetbot-mini-official-bootloader-update.md)，启动后的运行状态见 [06 成功系统记录](06-jetbot-mini-successful-system.md)。

## 当前镜像身份

两个版本来自同一份 L4T 32.7.6 RootFS，差异只有 `extlinux.conf` 中的 UAS quirk 和对应 U 盘容量。

工作区路径：

```text
01_SYSTEM_IMAGE/
├── 01_JETBOT_MINI_32G_20261124.img
├── 01_JETBOT_MINI_32G_20261124.img.sha256
├── 01_JETBOT_MINI_64G_20261124.img
├── 01_JETBOT_MINI_64G_20261124.img.sha256
└── SHA256SUMS.txt
```

| 版本 | 文件 | 大小 | UAS quirk |
| --- | --- | --- | --- |
| 32G | `01_JETBOT_MINI_32G_20261124.img` | 17,179,869,184 字节（16 GiB） | `usb-storage.quirks=0781:5583:u` |
| 64G | `01_JETBOT_MINI_64G_20261124.img` | 17,179,869,184 字节（16 GiB） | `usb-storage.quirks=0781:5581:u` |

```text
32G SHA-256：8c5217791a36f2f6d8565076ad43a30be66070476d0d3981700ff9a6de28c7fb
64G SHA-256：21b5ba5554a13ea667099de3c488b8ed3befcf4e0804af37c3fff516bc4284c7
```

两个镜像对应的 U 盘：

| 版本 | U 盘型号 | VID:PID | 扇区数 |
| --- | --- | --- | --- |
| 32G | SanDisk 3.2Gen1 | `0781:5583` | 60,125,184 |
| 64G | SanDisk Ultra | `0781:5581` | 124,735,488 |

镜像布局：

```text
GPT
分区 1：1 MiB 起始
分区 1 类型：Linux filesystem
文件系统：ext4
卷标：JETBOT_ROOT
```

两个镜像的 `extlinux.conf` 均设置：

```text
root=/dev/sda1 rw rootwait rootfstype=ext4
```

32G 镜像追加 `usb-storage.quirks=0781:5583:u`，64G 镜像追加 `usb-storage.quirks=0781:5581:u`。

## LightDM 会话设置

两个镜像的 `user-session` 为 `ux-ubuntu`，对应 L4T 32.7.6 RootFS 中的 GNOME 会话文件 `ux-ubuntu.desktop`。`user-session` 写成 `ubuntu` 时，认证通过后登录界面报 `Failed to start session`，无法进入桌面。相关设置：

```text
/etc/lightdm/lightdm.conf.d/90-jetbot.conf        user-session=ux-ubuntu
/usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf  user-session=ux-ubuntu
/usr/share/xsessions/ubuntu.desktop -> ux-ubuntu.desktop
/home/jetson/.dmrc                                Session=ux-ubuntu
```

`50-ubuntu.conf` 在加载顺序上后于 `/etc/lightdm/lightdm.conf.d/`，只改 `90-jetbot.conf` 不会生效，两个文件必须同时改。

## 校验

PowerShell：

```powershell
Get-FileHash .\01_SYSTEM_IMAGE\01_JETBOT_MINI_32G_20261124.img -Algorithm SHA256
Get-FileHash .\01_SYSTEM_IMAGE\01_JETBOT_MINI_64G_20261124.img -Algorithm SHA256
```

Linux：

```bash
sha256sum -c 01_JETBOT_MINI_32G_20261124.img.sha256
sha256sum -c 01_JETBOT_MINI_64G_20261124.img.sha256
```

工作区保留未压缩 `.img`，Win32DiskImager 可以直接使用。

## Windows 写入

### Win32DiskImager

1. 以管理员身份运行 Win32DiskImager。
2. `Image File` 选择与目标 U 盘容量一致的镜像：32G 盘用 `01_JETBOT_MINI_32G_20261124.img`，64G 盘用 `01_JETBOT_MINI_64G_20261124.img`。
3. `Device` 选择目标 U 盘对应盘符。
4. 核对磁盘容量、型号和物理接口。
5. 点击 `Write`，确认覆盖。
6. 等待写入完成。

写入完成后 Windows 会提示格式化 U 盘。选择“取消”。

### balenaEtcher

可直接选择未压缩 `.img`。目标设备是整块 U 盘。

## Linux 写入

识别整盘设备：

```bash
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL,SERIAL,FSTYPE,MOUNTPOINT
```

确认目标整盘为 `/dev/sdX` 后写入：

```bash
sudo umount /dev/sdX? 2>/dev/null || true
sudo dd if=01_JETBOT_MINI_32G_20261124.img \
  of=/dev/sdX bs=16M status=progress conv=fsync
sync
```

写入后检查：

```bash
sudo e2fsck -f -y /dev/sdX1
```

## 扩展到 U 盘全容量

镜像只有 16 GiB。写入 U 盘后，在离线 Linux 环境中扩展 GPT 和 ext4：

```bash
sudo parted -s /dev/sdX unit s print
sudo parted -s /dev/sdX unit s resizepart 1 100%
sudo partprobe /dev/sdX
sudo e2fsck -f -y /dev/sdX1
sudo resize2fs /dev/sdX1
```

当前运行盘为 32G U 盘，`/dev/sda1` 已扩展到整盘：

```text
/dev/sda1 ext4 28.1G 6.2G 20.5G
```

同一镜像写入 64G U 盘后扩展到约 56 GiB。

## UAS 兼容

两个 U 盘的 USB ID：

```text
32G SanDisk 3.2Gen1  0781:5583
64G SanDisk Ultra    0781:5581
```

启用 UAS 时出现 U 盘 I/O 超时、ext4 journal abort 和内核 panic；缺少 quirk 的 32G 盘根分区掉线后反复重启。两个镜像的 `extlinux.conf` 分别固定：

```text
32G：usb-storage.quirks=0781:5583:u
64G：usb-storage.quirks=0781:5581:u
```

写入前用 `lsusb` 核对目标盘 VID:PID 与镜像一致。不一致时先改 `extlinux.conf` 的 quirk 再写入，否则 UAS 会把根盘踢下线。

## 写入后验证

上电后通过串口或 SSH 检查：

```bash
findmnt -no SOURCE,FSTYPE,SIZE,USED,AVAIL /
lsusb -t
systemctl --failed --no-legend
systemctl is-active jetbotmini_start.service jetbotmini_stats.service nano_jupyter.service ssh.service lightdm.service
```

当前根盘应为 `/dev/sda1`，登录管理器应为 LightDM + slick-greeter。
