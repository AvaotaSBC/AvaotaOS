#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# This file is a part of the Avaota Build Framework
# https://github.com/AvaotaSBC/AvaotaOS/

build_bootloader(){
  BOARD=$1
  source ../boards/${BOARD}.conf
  cd ${BL_CONFIG} && mkdir build-${BOARD} && cd build-${BOARD}
  cmake -DCMAKE_BOARD_FILE=${BOARD}.cmake -DCMAKE_BUILD_TYPE=Release ..
  make -j$(nproc)
  cd ${workspace}
}

apply_bootloader(){
  BOARD=$1
  cd ${workspace}
  source ../boards/${BOARD}.conf
  if [ -d ${workspace}/bootloader-${BOARD} ];then rm -rf ${workspace}/bootloader-${BOARD}; fi

  mkdir -p ${workspace}/bootloader-${BOARD}/extlinux
  cp ${workspace}/../target/boot/uInitrd ${workspace}/bootloader-${BOARD}
  cp ${workspace}/../target/boot/extlinux.conf ${workspace}/bootloader-${BOARD}/extlinux
  sed -i "s|BOARD_NAME|${DEVICE_DTS}|g" ${workspace}/bootloader-${BOARD}/extlinux/extlinux.conf
  sed -i "s|BOOTARGS|${BOOTARGS}|g" ${workspace}/bootloader-${BOARD}/extlinux/extlinux.conf
  
  cp ${workspace}/${BL_CONFIG}/build-${BOARD}/board/${BOARD}/${SYTERKIT_TYPE}/${SYTERKIT_TYPE}_bin_card.bin \
  	${workspace}/bootloader.bin
  cp ${workspace}/${BL_CONFIG}/board/${BOARD}/${SYTERKIT_TYPE}/bl31/bl31.bin \
  	${workspace}/bootloader-${BOARD}/bl31.bin
  cp ${workspace}/${BL_CONFIG}/board/${BOARD}/${SYTERKIT_TYPE}/scp/scp.bin \
  	${workspace}/bootloader-${BOARD}/scp.bin
  cp ${workspace}/${BL_CONFIG}/board/${BOARD}/${SYTERKIT_TYPE}/splash/splash.bin \
  	${workspace}/bootloader-${BOARD}/splash.bin
  	
  echo "${BOARD}" > ${workspace}/bootloader-${BOARD}/.done
}
