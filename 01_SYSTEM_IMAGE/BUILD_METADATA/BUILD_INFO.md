# 系统镜像构建元数据

记录日期：2026-11-24

构建源：

```text
/build/L4T-32.7.6/Linux_for_Tegra/rootfs
```

镜像按 U 盘 VID:PID 分为两个版本，内容相同，只有 `extlinux.conf` 的 UAS quirk 不同：

```text
01_JETBOT_MINI_32G_20261124.img   0781:5583:u
01_JETBOT_MINI_64G_20261124.img   0781:5581:u
```

```text
大小：17,179,869,184 字节（16 GiB）

32G SHA-256：8c5217791a36f2f6d8565076ad43a30be66070476d0d3981700ff9a6de28c7fb
64G SHA-256：21b5ba5554a13ea667099de3c488b8ed3befcf4e0804af37c3fff516bc4284c7
```

文件系统：

```text
GPT
分区 1：1 MiB 起始
ext4
卷标：JETBOT_ROOT
e2fsck：clean
sgdisk -v：No problems found
```

软件状态：

```text
Debian ii 包：1998
APT hold：53
登录管理器：LightDM 1.26.0 + slick-greeter 1.1.4
桌面会话：ux-ubuntu（gnome-session --session=ubuntu），ubuntu.desktop 为软链
GDM3：未安装
Python：3.6.9
```

lightdm 会话修正：

```text
/etc/lightdm/lightdm.conf.d/90-jetbot.conf        user-session=ux-ubuntu
/usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf  user-session=ux-ubuntu
/usr/share/xsessions/ubuntu.desktop -> ux-ubuntu.desktop
/home/jetson/.dmrc                                Session=ux-ubuntu
```

验证：

```text
构建 RootFS 与镜像 rsync --checksum 差异：0
构建 RootFS 与运行盘软件包名、版本、hold 状态差异：0
镜像只读挂载：通过
LightDM、slick-greeter、BlueZ、v4l-utils、Python 开发环境：存在于镜像
运行实机：32G 盘写入老镜像后，登录界面报 Failed to start session，经上述修正后 GNOME 登录成功
```

## 元数据文件

```text
packages.tsv   镜像内全部 ii 包的包名和版本
apt-holds.txt  镜像内 APT hold 列表
fstab          镜像根文件系统挂载表
extlinux.conf  启动内核、initrd、root 和 UAS quirk（64G 版本，32G 把 quirk 换成 0781:5583:u）
```
