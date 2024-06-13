#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# This file is a part of the Avaota Build Framework
# https://github.com/AvaotaSBC/AvaotaOS/

default_param() {
    BOARD=avaota-a1
}

workspace=$(pwd)
cd ${workspace}

default_param
BOARD=$1

source ../boot/SyterKit/SyterKit.conf
source ../boards/${BOARD}.conf

build_bootloader(){
cd SyterKit && mkdir build-${BOARD} && cd build-${BOARD}
cmake -DCMAKE_BOARD_FILE=${BOARD}.cmake -DCMAKE_BUILD_TYPE=Debug ..
make -j$(nproc)

if [ -f ${workspace}/bootloader.bin ];then rm ${workspace}/bootloader.bin; fi
if [ -f ${workspace}/bl31.bin ];then rm ${workspace}/bl31.bin; fi
if [ -f ${workspace}/scp.bin ];then rm ${workspace}/scp.bin; fi
if [ -f ${workspace}/splash.bin ];then rm ${workspace}/splash.bin; fi
if [ -f ${workspace}/exlinux.conf ];then rm ${workspace}/exlinux.conf; fi
cp ${workspace}/../boot/SyterKit/extlinux.conf ${workspace}
sed -i "s|BOARD_NAME|${DEVICE_DTS}|g" ${workspace}/extlinux.conf
cp board/${BOARD}/${SYTERKIT_TYPE}/${SYTERKIT_TYPE}_bin_card.bin ${workspace}/bootloader.bin
cp ../board/${BOARD}/${SYTERKIT_TYPE}/bl31/bl31.bin ${workspace}/bl31.bin
cp ../board/${BOARD}/${SYTERKIT_TYPE}/scp/scp.bin ${workspace}/scp.bin
cp ../board/${BOARD}/${SYTERKIT_TYPE}/splash/splash.bin ${workspace}/splash.bin
}

apply_bootloader(){

}
