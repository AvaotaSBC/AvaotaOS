#!/bin/bash

__usage="
Usage: mklinux [OPTIONS]
Build linux.
The target Image & dtb will be generated in the build folder of the directory where the mklinux.sh script is located.

Options: 
  -b, --board BOARD                   The board name.
  -h, --help                          Show command help.
"

help()
{
    echo "$__usage"
    exit $1
}

default_param() {
    BOARD=avaota-a1
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
        else
            echo `date` - ERROR, UNKNOWN params "$@"
            return 2
        fi
    done
}

compile_linux()
{
    cd ${workspace}/linux
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- ${LINUX_CONFIG}
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

    if [ -d ${workspace}/linux_install ];then
        rm -rf ${workspace}/linux_install
    fi
    mkdir -p ${workspace}/linux_install/usr
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules_install INSTALL_MOD_PATH=${workspace}/linux_install
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- headers_install INSTALL_HDR_PATH=${workspace}/linux_install/usr
}

install_linux()
{
    if [ -d ${workspace}/${DEVICE_DTS}.dtb ];then rm -rf ${workspace}/${DEVICE_DTS}.dtb; fi
    if [ -d ${workspace}/Image ];then rm -rf ${workspace}/Image; fi

    cp ${workspace}/linux/arch/arm64/boot/dts/allwinner/${DEVICE_DTS}.dtb ${workspace}/sunxi.dtb
    cp ${workspace}/linux/arch/arm64/boot/Image ${workspace}
}

workspace=$(pwd)
cd ${workspace}

default_param
parseargs "$@" || help $?

source ../boards/${BOARD}.conf
source ../kernel/${KERNEL_USE}.conf

compile_linux
install_linux
