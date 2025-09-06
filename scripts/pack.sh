#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# This file is a part of the Avaota Build Framework
# https://github.com/AvaotaSBC/AvaotaOS/

__usage="
Usage: pack [OPTIONS]
Pack bootable image.
The target sdcard.img will be generated in the build folder of the directory where the mklinux.sh script is located.

Options: 
  -b,  -board BOARD                   The target board.
  -t, --type ROOTFS_TYPE              The rootfs type.
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
    TYPE=cli
    VERSION=jammy
    BOARD=avaota-a1
    SYS_USER=avaota
    SYS_PASSWORD=avaota
    ROOT_PASSWORD=avaota
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
        elif [ "x$1" == "x-t" -o "x$1" == "x--type" ]; then
            TYPE=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-v" -o "x$1" == "x--version" ]; then
            VERSION=`echo $2`
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
        else
            echo `date` - ERROR, UNKNOWN params "$@"
            return 2
        fi
    done
}

UMOUNT_ALL(){
    set +e
    
    if grep -q "${workspace}/rootfs_dir/boot " /proc/mounts ; then
        umount ${workspace}/rootfs_dir/boot
    fi
    
    if [ -d ${workspace}/rootfs_dir ]; then
        if grep -q "${workspace}/rootfs_dir " /proc/mounts ; then
            umount ${workspace}/rootfs_dir
        fi
    fi
    
    if [ -d ${workspace}/rootfs_dir ]; then
        rm -rf ${workspace}/rootfs_dir
    fi
    
    if [ "x$device" != "x" ]; then
        kpartx -d ${device}
        losetup -d ${device}
        device=""
    fi
    
    set -e
}

setup_users(){
#SYS_USER=avaota
#SYS_PASSWORD=avaota
#ROOT_PASSWORD=avaota

cat <<EOF | chroot ${workspace}/rootfs_dir adduser ${SYS_USER} && addgroup ${SYS_USER} sudo
${SYS_USER}
${SYS_PASSWORD}
${SYS_PASSWORD}
0
0
0
0
y
EOF

# username：avaota
# password：avaota

cat <<EOF | chroot ${workspace}/rootfs_dir passwd root
${ROOT_PASSWORD}
${ROOT_PASSWORD}
EOF

# username：root
# password：avaota
}

pack_sdcard()
{

    cd ${workspace}
    if [ -f ${workspace}/sdcard.img ];then rm -rf ${workspace}/sdcard.img; fi
    if [ -d ${workspace}/rootfs_dir ];then rm -rf ${workspace}/rootfs_dir; fi
    
    trap 'UMOUNT_ALL' EXIT
    
    img_size=$(($(du -sh --block-size=1MiB ${workspace}/rootfs-${VERSION}-${TYPE} | cut -f 1 | xargs)+${BOOT_SIZE}+$(du -sh --block-size=1MiB ${workspace}/deb-data | cut -f 1 | xargs)+880))
    
    dd if=/dev/zero of=${workspace}/sdcard.img bs=1MiB count=${img_size} status=progress && sync
    
    parted ${workspace}/sdcard.img mklabel ${part_table} mkpart primary fat32 $((${OFFSET}*2048))s $(((${BOOT_SIZE}*2048)-1))s
    parted ${workspace}/sdcard.img -s set 1 boot on
    parted ${workspace}/sdcard.img mkpart primary ext4 $((${BOOT_SIZE}*2048))s 100%

    device=$(losetup -f --show -P ${workspace}/sdcard.img)
    kpartx -va ${device}
    loopX=${device##*\/}
    partprobe ${device}

    bootpart=/dev/mapper/${loopX}p1
    rootpart=/dev/mapper/${loopX}p2
    
    mkfs.vfat -n boot -F 32 ${bootpart}
    mkfs.ext4 -L rootfs ${rootpart}
    
    mkdir ${workspace}/rootfs_dir
    mount ${rootpart} ${workspace}/rootfs_dir
    
    tar -zxvf ${workspace}/rootfs-${VERSION}-${TYPE}.tar.gz -C ${workspace}/rootfs_dir
    
    rm -f ${workspace}/rootfs_dir/root/.bash_history
    
    sync
    sleep 5
    
    if [ ! -d ${workspace}/rootfs_dir/boot ];then mkdir -p ${workspace}/rootfs_dir/boot; fi
    mount ${bootpart} ${workspace}/rootfs_dir/boot
    cp -r ${workspace}/${BOARD}-kernel-pkgs ${workspace}/rootfs_dir/kernel-deb
    
    cat <<EOF | LC_ALL=C LANGUAGE=C LANG=C chroot ${workspace}/rootfs_dir
apt-get remove linux-libc-dev -y
dpkg -i /kernel-deb/linux-libc-dev*.deb
apt-get -f install -y
dpkg -i /kernel-deb/linux-dtb*.deb
dpkg -i /kernel-deb/linux-image*.deb
apt-get -f install -y
EOF
    
    rm -rf ${workspace}/rootfs_dir/kernel-deb
    
    cp -r ${workspace}/bootloader-${BOARD}/* ${workspace}/rootfs_dir/boot
    
    cp -rfp ${workspace}/../target/firmware ${workspace}/rootfs_dir/lib/
    
    setup_users
    
    sync
    sleep 10
    
    UMOUNT_ALL
    
    write_bootloader /dev/mapper/${loopX}
}

xz_image()
{
    cd ${workspace}
    if [ -f sdcard.img ];then
        pixz sdcard.img
        echo "xz success."
    else
        echo "sdcard.img not found, xz sdcard image failed!"
        exit 2
    fi
}

workspace=$(pwd)
cd ${workspace}

default_param
parseargs "$@" || help $?

source ../boards/${BOARD}.conf
source ../scripts/lib/bootloader/bootloader-${BL_CONFIG}.sh

OFFSET=16
BOOT_SIZE=256
part_table=msdos

pack_sdcard
xz_image
