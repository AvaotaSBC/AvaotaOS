#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# This file is a part of the Avaota Build Framework
# https://github.com/AvaotaSBC/AvaotaOS/

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
  -l, --local LOCAL_SOURCES           Use local kernel,u-boot,syterkit
  -g, --githubmirror GITHUB_MIRROR    Use GitHub mirror.
  -o, --kernelonly                    Only build kernel package.
  -e, --ccache                        If use ccache.
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
    TYPE=none
    SYS_USER=avaota
    SYS_PASSWORD=avaota
    ROOT_PASSWORD=avaota
    KERNEL_MENUCONFIG=none
    MIRROR=none
    GITHUB_MIRROR=none
    LOCAL=no
    KERNEL_ONLY=none
    USE_CCACHE=no
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
        elif [ "x$1" == "x-l" -o "x$1" == "x--local" ]; then
            LOCAL=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-i" -o "x$1" == "x--githubmirror" ]; then
            GITHUB_MIRROR=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-o" -o "x$1" == "x--kernelonly" ]; then
            KERNEL_ONLY=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-e" -o "x$1" == "x--ccache" ]; then
            USE_CCACHE=`echo $2`
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
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" --title "Boards" --menu "select board" 15 60 2 \
            avaota-a1 "Avaota A1" \
            yuzuki-chameleon "Yuzuki Chameleon" \
            2> $temp
        if [ $? == 1 ];then
          exit 2
        fi
        BOARD=$(cat $temp)
        clear
        rm $temp
    fi
    source boards/${BOARD}.conf
    
    if [ "${VERSION}" == "none" ];then
        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" --title "System Distro" --menu "select distro" 15 60 2 \
            jammy "Ubuntu 22.04" \
            noble "Ubuntu 24.04" \
            bookworm "Debian 12" \
            trixie "Debian 13" \
            2> $temp
        if [ $? == 1 ];then
          exit 2
        fi
        VERSION=$(cat $temp)
        clear
        rm $temp
    fi
    
    if [ "${TYPE}" == "none" ];then
        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" --title "System Type" --menu "select desktop" 15 60 2 \
            cli "Console Version" \
            gnome "Gnome Desktop" \
            xfce "XFCE Desktop" \
            kde "Kde Desktop" \
            lxqt "LXQT Desktop" \
            2> $temp
        if [ $? == 1 ];then
          exit 2
        fi
        TYPE=$(cat $temp)
        clear
        rm $temp
    fi
    
    if [ "${KERNEL_MENUCONFIG}" == "none" ];then
        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" --title "Kernel Configure" --menu "select configure" 15 60 2 \
            no "Dont't run kernel menuconfig" \
            yes "Run kernel menuconfig" \
            2> $temp
        if [ $? == 1 ];then
          exit 2
        fi
        KERNEL_MENUCONFIG=$(cat $temp)
        clear
        rm $temp
    fi
    
    if [ "${KERNEL_ONLY}" == "none" ];then
        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" --title "Only Build Kernel" --menu "only kernel" 15 60 2 \
            no "Build all" \
            yes "Only build kernel packages." \
            2> $temp
        if [ $? == 1 ];then
          exit 2
        fi
        KERNEL_ONLY=$(cat $temp)
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
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" \
            --title "Create System Normal User" \
            --inputbox "User Name:" 15 60 "${SYS_USER}" 2> $temp
        if [ $? == 1 ];then
          exit 2
        fi
        SYS_USER=$(cat $temp)
        rm $temp

        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" \
            --title "Create System Normal User Password" \
            --inputbox "User Password:" 15 60 "${SYS_PASSWORD}" 2> $temp
        if [ $? == 1 ];then
          exit 2
        fi
        SYS_PASSWORD=$(cat $temp)
        rm $temp

        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" \
            --title "Change ROOT Password" \
            --inputbox "ROOT Password:" 15 60 "${ROOT_PASSWORD}" 2> $temp
        if [ $? == 1 ];then
          exit 2
        fi
        ROOT_PASSWORD=$(cat $temp)
        rm $temp

        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" \
            --title "Change DEB Mirror" \
            --inputbox "Mirror URL:" 15 60 "${MIRROR}" 2> $temp
        if [ $? == 1 ];then
          exit 2
        fi
        MIRROR=$(cat $temp)
        rm $temp
        
        if [ "${GITHUB_MIRROR}" == "none" ];then
        temp=`mktemp -t test.XXXXXX`
        dialog --clear --shadow --backtitle "AvaotaOS Build Framework" --title "Use GitHub Mirror" --menu "github mirror" 15 60 2 \
            no "Dont't use Github Proxy" \
            yes "Use Github Proxy" \
            2> $temp
        if [ $? == 1 ];then
          exit 2
        fi
        
        IF_GITHUB_MIRROR=$(cat $temp)
        if [ ${IF_GITHUB_MIRROR} == "yes" ];then
            in_temp=`mktemp -t test.XXXXXX`
            dialog --clear --shadow --backtitle "AvaotaOS Build Framework" \
                --title "Setup GitHub Mirror" \
                --inputbox "Github Mirror URL:" 15 60 "https://mirror.ghproxy.com" 2> $in_temp
            if [ $? == 1 ];then
              exit 2
            fi
            GITHUB_MIRROR=$(cat $in_temp)
            rm $in_temp
        elif [ ${IF_GITHUB_MIRROR} == "no" ];then
            GITHUB_MIRROR="no"
        fi
        clear
        rm $temp
        fi
    fi
    clear
}

print_args(){
    echo "+-------[ Config Info ]--------"
    echo "| BOARD=${BOARD}"
    echo "| VERSION=${VERSION}"
    echo "| ARCH=${ARCH}"
    echo "| TYPE=${TYPE}"
    echo "| SYS_USER=${SYS_USER}"
    echo "| SYS_PASSWORD=${SYS_PASSWORD}"
    echo "| ROOT_PASSWORD=${ROOT_PASSWORD}"
    echo "| MIRROR=${MIRROR}"
    echo "| KERNEL_MENUCONFIG=${KERNEL_MENUCONFIG}"
    echo "| LOCAL=${LOCAL}"
    echo "| GITHUB_MIRROR=${GITHUB_MIRROR}"
    echo "| KERNEL_ONLY=${KERNEL_ONLY}"
    echo "| USE_CCACHE=${USE_CCACHE}"
    echo "+-------------------------------"
    echo "You can run the following command at the next time:"
    echo "sudo bash build_all.sh -b ${BOARD} -m ${MIRROR} -v ${VERSION} -t ${TYPE} -u ${SYS_USER} -p ${SYS_PASSWORD} -s ${ROOT_PASSWORD} -k ${KERNEL_MENUCONFIG} -l ${LOCAL} -i ${GITHUB_MIRROR} -o ${KERNEL_ONLY} -e ${USE_CCACHE}"
    echo "--------------------------------"
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

if [ ${LOCAL} == "no" ];then
bash ../scripts/fetch.sh -b ${BOARD} -i ${GITHUB_MIRROR}
fi

if [[ -f ${workspace}/bootloader-${BOARD}/.done && \
    $(cat ${workspace}/bootloader-${BOARD}/.done) == "${BOARD}" ]];then
    echo "found bootloader file, skip build bootloader."
else
    bash ../scripts/mkbootloader.sh -b ${BOARD}
fi

if [[ -f ${workspace}/${LINUX_CONFIG}-kernel-pkgs/.done && \
    $(cat ${workspace}/${LINUX_CONFIG}-kernel-pkgs/.done) == "${LINUX_CONFIG}" ]];then
    echo "found kernel packages, skip build kernel."
else
    bash ../scripts/mklinux.sh -c ${LINUX_CONFIG} -k ${KERNEL_MENUCONFIG} -a ${ARCH} -g ${KERNEL_GCC} -e ${USE_CCACHE}
fi

if [ ${KERNEL_ONLY} == "yes" ];then
    echo "Only build kernel packages."
    exit 0
fi

if [ -f ${workspace}/ubuntu-${VERSION}-${TYPE}/THIS-IS-NOT-YOUR-ROOT ];then
    echo "found rootfs, skip build rootfs."
else
    sudo mkdir ${ROOTFS} && sudo bash ../scripts/mkrootfs.sh -m ${MIRROR} -r ${ROOTFS} -v ${VERSION} -a ${ARCH} -t ${TYPE} -c ${LINUX_CONFIG} -u ${SYS_USER} -p ${SYS_PASSWORD} -s ${ROOT_PASSWORD}
fi
bash ../scripts/pack.sh -t ${TYPE} -v ${VERSION}

if [ -f sdcard.img.xz ];then
    mv sdcard.img.xz AvaotaOS-${VERSION}-${TYPE}-${ARCH}-${BOARD}.img.xz
    echo "build success."
else
    echo "sdcard.img.xz not found, build sdcard image failed!"
    exit 2
fi
