#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# This file is a part of the Avaota Build Framework
# https://github.com/AvaotaSBC/AvaotaOS/

patch_u-boot()
{
    if [ ! -d ${workspace}/${BL_CONFIG} ];then
        echo "The u-boot source path not exist, exit..."
        exit 2
    fi
    patchdev=$1
    targetdir=$2
    for pth in $(ls ${workspace}/../patches/u-boot/${patchdev})
    do
        cp ${workspace}/../patches/u-boot/${patchdev}/${pth} ${targetdir}
        pushd ${targetdir}
        patch -p1 < ${pth}
        rm ${pth}
        popd
    done
}

build_bootloader(){
  BOARD=$1
  source ../boards/${BOARD}.conf
  
  cd atf
  make CROSS_COMPILE=${KERNEL_GCC} PLAT=sun50i_h616 DEBUG=1 bl31
  cd ..
  
  patch_u-boot ${BL_PATCHDIR} ${workspace}/${BL_CONFIG}
  cd ${BL_CONFIG}
  make CROSS_COMPILE=${KERNEL_GCC} BL31=${workspace}/atf/build/sun50i_h616/debug/bl31.bin ${BL_CONF}
  make CROSS_COMPILE=${KERNEL_GCC} BL31=${workspace}/atf/build/sun50i_h616/debug/bl31.bin -j$(nproc)
  cd ..
}

apply_bootloader(){
  BOARD=$1
  source ../boards/${BOARD}.conf
  if [ -d ${workspace}/bootloader-${BOARD} ];then rm -rf ${workspace}/bootloader-${BOARD}; fi
  
  cp ${workspace}/${BL_CONFIG}/u-boot-sunxi-with-spl.bin ${workspace}/bootloader.bin
  
  mkdir -p ${workspace}/bootloader-${BOARD}/extlinux
  cp ${workspace}/../target/boot/uInitrd ${workspace}/bootloader-${BOARD}
  cp ${workspace}/../target/boot/extlinux.conf ${workspace}/bootloader-${BOARD}/extlinux
  sed -i "s|BOARD_NAME|${DEVICE_DTS}|g" ${workspace}/bootloader-${BOARD}/extlinux/extlinux.conf
  sed -i "s|BOOTARGS|${BOOTARGS}|g" ${workspace}/bootloader-${BOARD}/extlinux/extlinux.conf
  echo "${BOARD}" > ${workspace}/bootloader-${BOARD}/.done
}
