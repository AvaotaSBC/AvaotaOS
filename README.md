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

```

Just run: `./build_all.sh`


Or, give build Parameters:

```
sudo bash build_all.sh \
    -b <BOARD> \
    -m <MIRROR> \
    -v <SYSTEM_DISTRO> \
    -t <SYS_TYPE> \
    -u <SYS_USER> \
    -p <USER_PASSWORD> \
    -s <ROOT_PASSWORD> \
    -k <IF_MENUCONFIG> \
    -i <GITHUB_MIRROR>
```

## Build Parameters

BOARD: avaota-a1

SYSTEM_DISTRO:
1.  Ubuntu-22.04: jammy
2.  Ubuntu-24.04: noble
3.  Debian-12: bookworm
4.  Debian-13: trixie

MIRROR:
such as: 

`http://ports.ubuntu.com`

`http://deb.debian.org/debian`

`https://mirrors.ustc.edu.cn/ubuntu-ports`

`https://mirrors.ustc.edu.cn/debian`

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

LOCAL:

Don't fetch and update kernel,u-boot/syterkit from git sources.
Do not set to "yes" at first run!

1.  yes
2.  no

GITHUB_MIRROR:

such as: `https://mirror.ghproxy.com`

example: 

`sudo bash build_all.sh -b avaota-a1 -m http://ports.ubuntu.com -v jammy -t cli -u avaota -p avaota -s avaota -k no -i none`

