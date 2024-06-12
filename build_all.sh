#!/bin/bash

__usage="
Usage: build_all [OPTIONS]
Build bootable image.
The target sdcard.img will be generated in the build folder of the directory where the build_all.sh script is located.

Options: 
  -b, --board BOARD                   The board name.
  -m, --mirror MIRROR_ADDR            The URL/path of debian/ubuntu mirror address.
  -v, --version UBUNTU_VER            The version of ubuntu.
  -a, --arch ARCH                     The arch of ubuntu.
  -t, --type ROOTFS_TYPE              The type of rootfs: cli, xfce, gnome, kde.
  -k, --kernelmenuconfig              If run kernel menuconfig.
  -u, --user SYS_USER                 The normal user of rootfs.
  -p, --password SYS_PASSWORD         The password of user.
  -s, --supassword ROOT_PASSWORD      The password of root.
  -h, --help                          Show command help.
"

help()
{
    echo "$__usage"
    exit $1
}

default_param() {
    BOARD=none
    VERSION=none
    ARCH=aarch64
    TYPE=none
    SYS_USER=avaota
    SYS_PASSWORD=avaota
    ROOT_PASSWORD=avaota
    KERNEL_MENUCONFIG=none
    MIRROR=none
}

parseargs()
{
    if [ "x$#" == "x0" ]; then
        EXTRA_ARGS=yes
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
        elif [ "x$1" == "x-m" -o "x$1" == "x--mirror" ]; then
            MIRROR=`echo $2`
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
        elif [ "x$1" == "x-u" -o "x$1" == "x--user" ]; then
            SYS_USER=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-p" -o "x$1" == "x--password" ]; then
            SYS_PASSWORD=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-s" -o "x$1" == "x--supassword" ]; then
            ROOT_PASSWORD=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-k" -o "x$1" == "x--kernelmenuconfig" ]; then
            KERNEL_MENUCONFIG=`echo $2`
            shift
            shift
        else
            echo `date` - ERROR, UNKNOWN params "$@"
            return 2
        fi
    done
}

input_box(){
    if [ "${BOARD}" == "none" ];then
        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" --title "Boards" --menu "select board" 10 40 2 \
            avaota-a1 "Avaota A1" \
            yuzuki-chameleon "Yuzuki Chameleon" \
            2> $temp
        BOARD=$(cat $temp)
        clear
        rm $temp
    fi
    if [ "${VERSION}" == "none" ];then
        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" --title "System Distro" --menu "select distro" 10 40 4 \
            jammy "Ubuntu 22.04" \
            noble "Ubuntu 24.04" \
            bookworm "Debian 12" \
            trixie "Debian 13" \
            2> $temp
        VERSION=$(cat $temp)
        clear
        rm $temp
    fi
    if [ "${TYPE}" == "none" ];then
        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" --title "System Type" --menu "select desktop" 10 40 5 \
            cli "Console Version" \
            gnome "Gnome Desktop" \
            xfce "XFCE Desktop" \
            kde "Kde Desktop" \
            lxqt "LXQT Desktop" \
            2> $temp
        TYPE=$(cat $temp)
        clear
        rm $temp
    fi
    if [ "${KERNEL_MENUCONFIG}" == "none" ];then
        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" --title "Kernel Configure" --menu "select configure" 10 40 2 \
            no "Dont't run kernel menuconfig" \
            yes "Run kernel menuconfig" \
            2> $temp
        KERNEL_MENUCONFIG=$(cat $temp)
        clear
        rm $temp
    fi
    if [ "${MIRROR}" == "none" ];then
        if [[ "${VERSION}" == "jammy" || "${VERSION}" == "noble" ]];then
            MIRROR=http://ports.ubuntu.com
        elif [[ "${VERSION}" == "bookworm" || "${VERSION}" == "trixie" ]];then
            MIRROR=http://deb.debian.org/debian
        fi
    fi
    if [ "${EXTRA_ARGS}" == "yes" ];then
        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "Create System User" \
            --title "System Normal User" \
            --inputbox "User Name:" 10 40 "${SYS_USER}" 2> $temp
        SYS_USER=$(cat $temp)
        rm $temp

        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "Create System User" \
            --title "System Normal User" \
            --inputbox "User Password:" 10 40 "${SYS_PASSWORD}" 2> $temp
        SYS_PASSWORD=$(cat $temp)
        rm $temp

        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "Change ROOT Password" \
            --title "ROOT User" \
            --inputbox "ROOT Password:" 10 40 "${ROOT_PASSWORD}" 2> $temp
        ROOT_PASSWORD=$(cat $temp)
        rm $temp

        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "Change DEB Mirror" \
            --title "DEB Mirror" \
            --inputbox "Mirror URL:" 10 40 "${MIRROR}" 2> $temp
        MIRROR=$(cat $temp)
        rm $temp
    fi
    clear
}

print_args(){
    echo "------[ Config Info ]------"
    echo "BOARD=${BOARD}"
    echo "VERSION=${VERSION}"
    echo "ARCH=${ARCH}"
    echo "TYPE=${TYPE}"
    echo "SYS_USER=${SYS_USER}"
    echo "SYS_PASSWORD=${SYS_PASSWORD}"
    echo "ROOT_PASSWORD=${ROOT_PASSWORD}"
    echo "MIRROR=${MIRROR}"
    echo "KERNEL_MENUCONFIG=${KERNEL_MENUCONFIG}"
    echo "--------------------------"
    echo "You can run the following command at the next time:"
    echo "sudo bash build_all.sh -b ${BOARD} -m ${MIRROR} -v ${VERSION} -t ${TYPE} -u ${SYS_USER} -p ${SYS_PASSWORD} -s ${ROOT_PASSWORD} -k ${KERNEL_MENUCONFIG}"
}

sudo apt-get install gcc-arm-none-eabi cmake build-essential gcc-aarch64-linux-gnu mtools qemu-user-static bc pkg-config dialog -y
sudo apt install debootstrap ubuntu-keyring debian-keyring automake autoconf gcc make pixz libconfuse2 libconfuse-common libconfuse-dev -y

EXTRA_ARGS=no
default_param
parseargs "$@" || help $?

input_box
print_args

if [ ! -d build_dir ];then
    mkdir build_dir
fi
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
    bash ../scripts/mklinux.sh -c ${LINUX_CONFIG} -k ${KERNEL_MENUCONFIG}
fi

if [ -f ${workspace}/ubuntu-${VERSION}-${TYPE}/THIS-IS-NOT-YOUR-ROOT ];then
    echo "found rootfs, skip build rootfs."
else
    sudo mkdir ${ROOTFS} && sudo bash ../scripts/mkrootfs.sh -m ${MIRROR} -r ${ROOTFS} -v ${VERSION} -a ${ARCH} -t ${TYPE} -c ${LINUX_CONFIG} -u ${SYS_USER} -p ${SYS_PASSWORD} -s ${ROOT_PASSWORD}
fi
bash ../scripts/pack.sh -t ${TYPE} -v ${VERSION}

if [ -f sdcard.img.xz ];then
    mv sdcard.img.xz ubuntu-${VERSION}-${TYPE}-${ARCH}-${BOARD}.img.xz
    echo "build success."
else
    echo "sdcard.img.xz not found, build sdcard image failed!"
    exit 2
fi
