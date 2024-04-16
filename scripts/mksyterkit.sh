#!/bin/bash

__usage="
Usage: mksyterkit [OPTIONS]
Build SyterKit bin.
The target bootloader.bin will be generated in the build folder of the directory where the mksyterkit.sh script is located.

Options: 
  -b, --board BOARD                   The target board.
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

workspace=$(pwd)
cd ${workspace}

default_param
parseargs "$@" || help $?

source ../boot/SyterKit/SyterKit.conf
rm ${workspace}/bootloader.bin
cd SyterKit && mkdir build-${BOARD} && cd build-${BOARD}
cmake -DCMAKE_BOARD_FILE=${BOARD}.cmake -DCMAKE_BUILD_TYPE=Debug ..
make -j$(nproc)
cp board/${BOARD}/${SYTERKIT_TYPE}/${SYTERKIT_TYPE}_bin_card.bin ${workspace}/bootloader.bin
