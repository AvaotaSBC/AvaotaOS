#!/bin/bash

__usage="
Usage: mklinux [OPTIONS]
Build linux.
The target Image & dtb will be generated in the build folder of the directory where the mklinux.sh script is located.

Options: 
  -c, --config CONFIG                 The linux configure file.
  -k, --kernelmenuconfig              If run kernel menuconfig.
  -h, --help                          Show command help.
"

help()
{
    echo "$__usage"
    exit $1
}

default_param() {
    KERNEL_MENUCONFIG=no
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
        elif [ "x$1" == "x-c" -o "x$1" == "x--config" ]; then
            LINUX_CONFIG=`echo $2`
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

compile_linux_pkg()
{
    cd ${workspace}/linux
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- ${LINUX_CONFIG}
    if [ "${KERNEL_MENUCONFIG}" == "yes" ];then
        make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig
    fi
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- deb-pkg -j$(nproc)
    cd ${workspace}
    rm ${workspace}/*dbg*.deb
}

workspace=$(pwd)
cd ${workspace}

default_param
parseargs "$@" || help $?

set -e
compile_linux_pkg

mkdir ${workspace}/${LINUX_CONFIG}-kernel-pkgs
cp ${workspace}/*.deb ${workspace}/${LINUX_CONFIG}-kernel-pkgs
