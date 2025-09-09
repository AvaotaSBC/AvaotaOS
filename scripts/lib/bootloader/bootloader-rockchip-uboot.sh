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
  
  #patch_u-boot ${BL_PATCHDIR} ${workspace}/${BL_CONFIG}
  cd ${BL_CONFIG}
  cp ${workspace}/rkbin/${BL31_PATH} bl31.elf
  cp ${workspace}/rkbin/${TEE_PATH} tee.bin
  if [ ${USE_PREBUILT_UBOOT} == 1 ];then
      cp ${workspace}/../target/boot/${BOARD}-u-boot-bin/* .
  else
      make CROSS_COMPILE=${KERNEL_GCC} ARCH=arm ${BL_CONF}
      make ARCH=arm CROSS_COMPILE=${KERNEL_GCC} spl/u-boot-spl.bin u-boot.dtb u-boot.itb -j$(nproc)
      
      tools/mkimage -n rk3576 -T rksd -d ${workspace}/rkbin/${DDRBIN_PATH}:spl/u-boot-spl.bin idbloader.img
  fi
  cd ..
}

apply_bootloader(){
  BOARD=$1
  source ../boards/${BOARD}.conf
  if [ -d ${workspace}/bootloader-${BOARD} ];then rm -rf ${workspace}/bootloader-${BOARD}; fi
  
  cp ${workspace}/${BL_CONFIG}/idbloader.img ${workspace}
  cp ${workspace}/${BL_CONFIG}/u-boot.itb ${workspace}
  
  mkdir -p ${workspace}/bootloader-${BOARD}/extlinux
  cp ${workspace}/../target/boot/uInitrd ${workspace}/bootloader-${BOARD}
  cp ${workspace}/../target/boot/extlinux.conf ${workspace}/bootloader-${BOARD}/extlinux
  sed -i "s|DTB_NAME|${DEVICE_DTS}|g" ${workspace}/bootloader-${BOARD}/extlinux/extlinux.conf
  sed -i "s|BOOTARGS|${BOOTARGS}|g" ${workspace}/bootloader-${BOARD}/extlinux/extlinux.conf
  echo "${BOARD}" > ${workspace}/bootloader-${BOARD}/.done
}

write_bootloader(){
    echo "write bootloader"
    dd if=${workspace}/idbloader.img of=$1 seek=64 conv=notrunc status=none
    dd if=${workspace}/u-boot.itb of=$1 seek=16384 conv=notrunc status=none
}
