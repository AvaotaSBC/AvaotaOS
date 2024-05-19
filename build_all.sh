#!/bin/bash

__usage="
Usage: build_all [OPTIONS]
Build bootable image.
The target sdcard.img will be generated in the build folder of the directory where the build_all.sh script is located.

Options: 
  -b, --board BOARD                   The board name.
  -v, --version UBUNTU_VER            The version of ubuntu.
  -a, --arch ARCH                     The arch of ubuntu.
  -t, --type ROOTFS_TYPE              The type of rootfs: cli, xfce, gnome, kde.
  -h, --help                          Show command help.
"

help()
{
    echo "$__usage"
    exit $1
}

default_param() {
    BOARD=avaota-a1
    VERSION=jammy
    ARCH=aarch64
    TYPE=cli
}

parseargs()
{
    if [ "x$#" == "x0" ]; then
        return 0
    fi

    while [ "x$#" != "x0" ];
    do
        if [ "x$1" == "x-h" -o "x$1" == "x--help" ]; then
            return 1
        elif [ "x$1" == "x" ]; then
            shift
        elif [ "x$1" == "x-b" -o "x$1" == "x--board" ]; then
            BOARD=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-v" -o "x$1" == "x--version" ]; then
            VERSION=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-a" -o "x$1" == "x--arch" ]; then
            ARCH=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-t" -o "x$1" == "x--type" ]; then
            TYPE=`echo $2`
            shift
            shift
        else
            echo `date` - ERROR, UNKNOWN params "$@"
            return 2
        fi
    done
}

default_param
parseargs "$@" || help $?

sudo apt-get install gcc-arm-none-eabi cmake build-essential gcc-aarch64-linux-gnu mtools qemu-user-static bc pkg-config -y
sudo apt install mmdebstrap ubuntu-keyring automake autoconf gcc make pixz libconfuse2 libconfuse-common libconfuse-dev -y

mkdir build_dir 
cd build_dir
workspace=$(pwd)
cd ${workspace}
ROOTFS=${workspace}/rootfs

source ../boards/${BOARD}.conf

bash ../scripts/fetch.sh -b ${BOARD} -v ${VERSION} -a ${ARCH}
bash ../scripts/mksyterkit.sh -b ${BOARD}

if [ -d ${workspace}/${LINUX_CONFIG}-kernel-pkgs ];then
    echo "found kernel packages, skip build kernel."
else
    bash ../scripts/mklinux.sh -c ${LINUX_CONFIG}
fi

if [ -f ${workspace}/ubuntu-${VERSION}-${TYPE}/THIS-IS-NOT-YOUR-ROOT ];then
    echo "found rootfs, skip build rootfs."
else
    sudo mkdir ${ROOTFS} && sudo bash ../scripts/mkubuntu.sh -r ${ROOTFS} -v ${VERSION} -a ${ARCH} -t ${TYPE} -c ${LINUX_CONFIG}
fi
bash ../scripts/pack.sh -t ${TYPE} -v ${VERSION}

if [ -f sdcard.img.xz ];then
    mv sdcard.img.xz ubuntu-${VERSION}-${TYPE}-${ARCH}-${BOARD}.img.xz
    echo "build success."
else
    echo "sdcard.img.xz not found, build sdcard image failed!"
    exit 2
fi
