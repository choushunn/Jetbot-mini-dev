# 关键文件清单

记录日期：2026-11-24

## 系统镜像

工作区保留 32GB 和 64GB 两个 U 盘版本，差异只在 `extlinux.conf` 的 UAS quirk：

| 版本 | 文件 | SHA-256 |
| --- | --- | --- |
| 32G | `01_SYSTEM_IMAGE/01_JETBOT_MINI_32G_20261124.img` | `8c5217791a36f2f6d8565076ad43a30be66070476d0d3981700ff9a6de28c7fb` |
| 64G | `01_SYSTEM_IMAGE/01_JETBOT_MINI_64G_20261124.img` | `21b5ba5554a13ea667099de3c488b8ed3befcf4e0804af37c3fff516bc4284c7` |

两个镜像均为 17,179,869,184 字节，GPT + 单个 ext4 分区（卷标 `JETBOT_ROOT`，1 MiB 起始），并已包含 lightdm `user-session=ux-ubuntu` 修正。

```text
32G quirk：usb-storage.quirks=0781:5583:u
64G quirk：usb-storage.quirks=0781:5581:u
```

构建元数据位于：

```text
01_SYSTEM_IMAGE/BUILD_METADATA/
```

## 引导备份

```text
02_BOOTLOADER/01_spi-backup-32.7.6-working.bin
SHA-256：85ea958e2baf8fa3438fe126a51bf681a24b4ce7eeaa2bda8161a52763d1787d
```

## 构建输入

```text
03_BUILD_INPUTS/01_Jetson-210_Linux_R32.7.6_aarch64.download.txt
SHA-256：865717eed7076babd3c193fc39bc7df41cc457b554059d374c624c42bcde0212

03_BUILD_INPUTS/02_Tegra_Linux_Sample-Root-Filesystem_R32.7.6_aarch64.download.txt
SHA-256：c0c25188be529b8e12ce33cda573451d8f63d580810f1e7dfe5406c1b088ca41

03_BUILD_INPUTS/03_jetbot-user-overlay-32.7.6.tar
SHA-256：a761af9252dd4547b8a5c8465996fdd7bd8b50eada31959277d63a69bc9b13b1

03_BUILD_INPUTS/04_jetbot-system-overlay-32.7.6.tar
SHA-256：08a503bce1fd6f89ea434e784787a5b356bf63fc3b79c2734e501168bb6a59dd
```

## 工具

```text
04_TOOLS/03_usbipd-win_5.3.0_x64.download.txt
04_TOOLS/04_tegrarcm-master.download.txt
04_TOOLS/05_tegrarcm_usbip_wrapper
04_TOOLS/06_bind_usbipd_3_3.ps1
04_TOOLS/07_install_usbipd.ps1
```

每个目录的完整校验清单位于该目录的 `SHA256SUMS.txt`。

镜像包清单、APT hold、`fstab` 和 `extlinux.conf` 位于：

```text
01_SYSTEM_IMAGE/BUILD_METADATA/
```
