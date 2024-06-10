# AvaotaOS Build Framwork

## Info

```
username: avaota
password: avaota

username: root
password: avaota
```

## Prebuilt Download

From [releases](https://github.com/AvaotaSBC/AvaotaOS/releases)

UBUNTU_VERSION-SYS_TYPE-ARCH-BOARD.img.xz

## How to build

```
git clone --depth=1 https://github.com/AvaotaSBC/AvaotaOS && cd AvaotaOS

sudo bash build_all.sh -b <BOARD> -m <MIRROR> -v <UBUNTU_VERSION> -a <ARCH> -t <SYS_TYPE> -u <SYS_USER> -p <USER_PASSWORD> -s <ROOT_PASSWORD>
```

## Build Parameters

BOARD: avaota-a1

UBUNTU_VERSION:
1.  Ubuntu-22.04: jammy
2.  Ubuntu-24.04: noble

MIRROR:
such as: `http://ports.ubuntu.com`

ARCH:
1.  arm64: aarch64
2.  armhf: armhf (current unsupported)

SYS_TYPE:
1.  cli
2.  xfce
3.  gnome
4.  kde
5.  lxqt

SYS_USER:

default: avaota

USER_PASSWORD:

default: avaota

ROOT_PASSWORD:

default: avaota

KERNEL_MENUCONFIG:
1.  yes
2.  no

example: `bash build_all.sh -b avaota-a1 -m http://ports.ubuntu.com -v jammy -a aarch64 -t cli -u avaota -p avaota -s avaota -k no`

