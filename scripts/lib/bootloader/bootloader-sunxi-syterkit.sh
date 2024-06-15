#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# This file is a part of the Avaota Build Framework
# https://github.com/AvaotaSBC/AvaotaOS/

BL_CONF_PATH=../boot/syterkit/syterkit.conf

build_bootloader(){
BOARD=$1
source ${BL_CONF_PATH}
source ../boards/${BOARD}.conf
cd syterkit && mkdir build-${BOARD} && cd build-${BOARD}
cmake -DCMAKE_BOARD_FILE=${BOARD}.cmake -DCMAKE_BUILD_TYPE=Debug ..
make -j$(nproc)

if [ -d ${workspace}/bootloader-${BOARD} ];then rm -rf ${workspace}/bootloader-${BOARD}; fi

mkdir -p ${workspace}/bootloader-${BOARD}/extlinux
cp ${workspace}/../boot/syterkit/uInitrd ${workspace}/bootloader-${BOARD}
cp ${workspace}/../boot/syterkit/extlinux.conf ${workspace}/bootloader-${BOARD}/extlinux
sed -i "s|BOARD_NAME|${DEVICE_DTS}|g" ${workspace}/bootloader-${BOARD}/extlinux/extlinux.conf
cp board/${BOARD}/${SYTERKIT_TYPE}/${SYTERKIT_TYPE}_bin_card.bin ${workspace}/bootloader.bin
cp ../board/${BOARD}/${SYTERKIT_TYPE}/bl31/bl31.bin ${workspace}/bootloader-${BOARD}/bl31.bin
cp ../board/${BOARD}/${SYTERKIT_TYPE}/scp/scp.bin ${workspace}/bootloader-${BOARD}/scp.bin
cp ../board/${BOARD}/${SYTERKIT_TYPE}/splash/splash.bin ${workspace}/bootloader-${BOARD}/splash.bin
echo "${BOARD}" > ${workspace}/bootloader-${BOARD}/.done
}

apply_bootloader(){
echo ""
}
