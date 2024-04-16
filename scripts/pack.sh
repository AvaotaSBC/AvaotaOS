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
    
    if [ -d ${workspace}/rootfs_dir ]; then
        rm -rf ${workspace}/rootfs_dir
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
    
    bash ${workspace}/../tools/genimage.sh -c ${workspace}/../tools/genimage-boot.cfg
    mcopy -i boot.vfat -s ${workspace}/../boot/SyterKit/extlinux ::/
}

pack_rootfs()
{
    cd ${workspace}
    if [ -f ${workspace}/rootfs.ext4 ];then rm ${workspace}/rootfs.ext4; fi
    if [ -d ${workspace}/rootfs_pack ];then rm -rf ${workspace}/rootfs_pack; fi
    cp -rfp ubuntu-${TYPE} rootfs_pack
    cp -rfp ${workspace}/linux_install/lib/* ${workspace}/rootfs_pack/lib
    cp -rfp ${workspace}/linux_install/usr/* ${workspace}/rootfs_pack/usr
    cp -rfp ${workspace}/../firmware ${workspace}/rootfs_pack/lib/
    
    size=`du -sh --block-size=1MiB ${workspace}/rootfs_pack | cut -f 1 | xargs`
    size=$(($size+500))
    dd if=/dev/zero of=${workspace}/rootfs.ext4 bs=1MiB count=$size status=progress && sync
    
    mkfs.ext4 -L rootfs ${workspace}/rootfs.ext4
    
    trap 'UMOUNT_ALL' EXIT
    
    mkdir ${workspace}/rootfs_dir
    mount ${workspace}/rootfs.ext4 ${workspace}/rootfs_dir
    rsync -avHAXq ${workspace}/rootfs_pack/* ${workspace}/rootfs_dir
    
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
    pixz sdcard.img
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
