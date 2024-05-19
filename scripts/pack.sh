#!/bin/bash

__usage="
Usage: pack [OPTIONS]
Pack bootable image.
The target sdcard.img will be generated in the build folder of the directory where the mklinux.sh script is located.

Options: 
  -t, --type ROOTFS_TYPE              The rootfs type.
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
        elif [ "x$1" == "x-t" -o "x$1" == "x--type" ]; then
            TYPE=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-v" -o "x$1" == "x--version" ]; then
            VERSION=`echo $2`
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
    if [ -d ${workspace}/rootfs_dir ]; then
        if grep -q "${workspace}/rootfs_dir " /proc/mounts ; then
            umount ${workspace}/rootfs_dir
        fi
    fi
    
    if [ -d ${workspace}/boot_dir ]; then
        if grep -q "${workspace}/boot_dir " /proc/mounts ; then
            umount ${workspace}/boot_dir
        fi
    fi
    
    if [ -d ${workspace}/rootfs_dir ]; then
        rm -rf ${workspace}/rootfs_dir
    fi
    
    if [ -d ${workspace}/boot_dir ]; then
        rm -rf ${workspace}/boot_dir
    fi
    
    set -e
}

compile_genimage()
{
    if [ -f ${workspace}/genimage ];then
        echo "found genimage"
    else
        cd ${workspace}/../tools/genimage
        autoreconf -is
        ./configure
        make
        cp genimage ${workspace}
    fi
}

pack_boot()
{
    cd ${workspace}
    if [ -f ${workspace}/boot.vfat ];then rm ${workspace}/boot.vfat; fi
    if [ -d ${workspace}/boot_dir ];then rm -rf ${workspace}/boot_dir; fi
    
    dd if=/dev/zero of=${workspace}/boot.vfat bs=1MiB count=128 status=progress && sync
    mkfs.vfat -n boot -F 32 ${workspace}/boot.vfat
    
    trap 'UMOUNT_ALL' EXIT
    
    mkdir ${workspace}/boot_dir
    mount ${workspace}/boot.vfat ${workspace}/boot_dir
    
    mv ${workspace}/ubuntu-${VERSION}-${TYPE}/boot/* ${workspace}/boot_dir
    mkdir ${workspace}/boot_dir/extlinux
    cp ${workspace}/extlinux.conf ${workspace}/boot_dir/extlinux
    
    cp ${workspace}/bl31.bin ${workspace}/boot_dir
    cp ${workspace}/scp.bin ${workspace}/boot_dir
    cp ${workspace}/splash.bin ${workspace}/boot_dir
    cp ${workspace}/../boot/SyterKit/uInitrd ${workspace}/boot_dir
    
    UMOUNT_ALL
}

pack_rootfs()
{
    cd ${workspace}
    if [ -f ${workspace}/rootfs.ext4 ];then rm ${workspace}/rootfs.ext4; fi
    if [ -d ${workspace}/rootfs_dir ];then rm -rf ${workspace}/rootfs_dir; fi
    
    rootfs_size=`du -sh --block-size=1MiB ${workspace}/ubuntu-${VERSION}-${TYPE} | cut -f 1 | xargs`

    size=$(($rootfs_size+880))
    dd if=/dev/zero of=${workspace}/rootfs.ext4 bs=1MiB count=$size status=progress && sync
    
    mkfs.ext4 -L rootfs ${workspace}/rootfs.ext4
    
    trap 'UMOUNT_ALL' EXIT
    
    mkdir ${workspace}/rootfs_dir
    mount ${workspace}/rootfs.ext4 ${workspace}/rootfs_dir
    rsync -avHAXq ${workspace}/ubuntu-${VERSION}-${TYPE}/* ${workspace}/rootfs_dir
    
    rm ${workspace}/rootfs_dir/THIS-IS-NOT-YOUR-ROOT
    
    cp -rfp ${workspace}/../firmware ${workspace}/rootfs_dir/lib/
    
    sync
    sync
    sleep 10
    
    UMOUNT_ALL
}

pack_sdcard()
{
    cd ${workspace}
    if [ -f ${workspace}/sdcard.img ];then rm -rf ${workspace}/sdcard.img; fi
    bash ${workspace}/../tools/genimage.sh -c ${workspace}/../tools/genimage-sdcard.cfg
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

compile_genimage
pack_boot
pack_rootfs
pack_sdcard
xz_image
