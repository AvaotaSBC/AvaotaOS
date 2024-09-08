# AvaotaOS Build Framework

<a href="#avaota-build"><img src="./doc/pics/main.png" alt="main.png" width="100%"></a>

## Info

```plaintext
username: avaota
password: avaota

username: root
password: avaota
```

## Prebuilt Download

You can download prebuilt images from the [releases](https://github.com/AvaotaSBC/AvaotaOS/releases) section.

The format of the prebuilt image file is `UBUNTU_VERSION-SYS_TYPE-ARCH-BOARD.img.xz`.

## How to Build

1. Clone the AvaotaOS repository:

```plaintext
git clone --depth=1 https://github.com/AvaotaSBC/AvaotaOS && cd AvaotaOS
```

2. Run the build script:

```plaintext
sudo ./build_all.sh
```

Alternatively, you can provide build parameters:

```plaintext
sudo ./build_all.sh \
    -b <BOARD> \
    -m <MIRROR> \
    -v <SYSTEM_DISTRO> \
    -t <SYS_TYPE> \
    -u <SYS_USER> \
    -p <USER_PASSWORD> \
    -s <ROOT_PASSWORD> \
    -k <IF_MENUCONFIG> \
    -g <KERNEL_TARGET> \
    -i <GITHUB_MIRROR> \
    -o <KERNEL_ONLY> \
    -e <USE_CCACHE>
```

## Build Parameters

- `BOARD`: avaota-a1

- `SYSTEM_DISTRO`:
  1. Ubuntu-20.04: focal
  2. Ubuntu-22.04: jammy
  3. Ubuntu-24.04: noble
  4. Debian-11: bullseye
  5. Debian-12: bookworm
  6. Debian-13: trixie
  7. Debian-13: trixie

- `MIRROR`:
  - Example: `http://ports.ubuntu.com`
  - Example: `http://deb.debian.org/debian`
  - Example: `https://mirrors.ustc.edu.cn/ubuntu-ports`
  - Example: `https://mirrors.ustc.edu.cn/debian`

- `SYS_TYPE`:
  1. cli
  2. xfce
  3. gnome
  4. kde
  5. lxqt

- `SYS_USER`: (default: avaota)

- `USER_PASSWORD`: (default: avaota)

- `ROOT_PASSWORD`: (default: avaota)

- `KERNEL_MENUCONFIG`:
  1. yes
  2. no
  
- `KERNEL_TARGET`:
  1. bsp
  2. mainline-lts
  3. mainline-latest

- `LOCAL`:
  - Don't fetch and update kernel, u-boot/syterkit from git sources.
  - Do not set to "yes" on the first run!
  1. yes
  2. no

- `GITHUB_MIRROR`:
  - Example: `https://mirror.ghproxy.com`

- `KERNEL_ONLY`: (Only build kernel packages)
  - 1. yes
  - 2. no
  
- `USE_CCACHE`:
  - 1. yes
  - 2. no

Example:

```plaintext
sudo bash build_all.sh \
    -b avaota-a1 \
    -m https://mirrors.ustc.edu.cn/ubuntu-ports \
    -v jammy \
    -t cli \
    -u avaota \
    -p avaota \
    -s avaota \
    -k no \
    -i no \
    -o no \
    -e no
```

