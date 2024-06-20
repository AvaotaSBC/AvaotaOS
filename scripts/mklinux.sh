#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# This file is a part of the Avaota Build Framework
# https://github.com/AvaotaSBC/AvaotaOS/

__usage="
Usage: mklinux [OPTIONS]
Build linux.
The target Image & dtb will be generated in the build folder of the directory where the mklinux.sh script is located.

Options: 
  -b, --board BOARD                   The target board.
  -k, --kernelmenuconfig              If run kernel menuconfig.
  -e, --ccache                        If use ccache.
  -h, --help                          Show command help.
"

help()
{
    echo "$__usage"
    exit $1
}

default_param() {
    BOARD=avaota-a1
    KERNEL_MENUCONFIG=no
    USE_CCACHE=no
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
        elif [ "x$1" == "x-k" -o "x$1" == "x--kernelmenuconfig" ]; then
            KERNEL_MENUCONFIG=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-e" -o "x$1" == "x--ccache" ]; then
            USE_CCACHE=`echo $2`
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
    if [ ! -d ${workspace}/linux ];then
        echo "The linux source path not exist, exit..."
        exit 2
    fi
    cd ${workspace}/linux
    if [ -f ${workspace}/user_defconfig ];then
        cp ${workspace}/user_defconfig .config
        ${MAKE} ARCH=${ARCH} CROSS_COMPILE=${KERNEL_GCC} olddefconfig
    else
        ${MAKE} ARCH=${ARCH} CROSS_COMPILE=${KERNEL_GCC} ${LINUX_CONFIG}
    fi
    
    if [ "${KERNEL_MENUCONFIG}" == "yes" ];then
        ${MAKE} ARCH=${ARCH} CROSS_COMPILE=${KERNEL_GCC} menuconfig
        cat .config > ${workspace}/user_defconfig
    fi
    ${MAKE} ARCH=${ARCH} CROSS_COMPILE=${KERNEL_GCC} -j$(nproc)
    if [ -d ${workspace}/deb-data ];then
        rm -rf ${workspace}/deb-data
        mkdir -p ${workspace}/deb-data
    else
        mkdir -p ${workspace}/deb-data
    fi
}

install_dtb(){
    cd ${workspace}/linux
    mkdir -p ${workspace}/deb-data/dtb/boot
    ${MAKE} ARCH=${ARCH} \
        CROSS_COMPILE=${KERNEL_GCC} \
        dtbs_install \
        INSTALL_PATH=${workspace}/deb-data/dtb/boot
    KERNEL_VER=$(ls ${workspace}/deb-data/dtb/boot/dtbs/)
    mv ${workspace}/deb-data/dtb/boot/dtbs/* \
        ${workspace}/deb-data/dtb/boot/dtb-${KERNEL_VER}
    rm -rf ${workspace}/deb-data/dtb/boot/dtbs
}

install_image_modules(){
    cd ${workspace}/linux
    mkdir -p ${workspace}/deb-data/image/boot
    mkdir -p ${workspace}/deb-data/image/etc/kernel/postinst.d
    mkdir -p ${workspace}/deb-data/image/etc/kernel/postrm.d
    mkdir -p ${workspace}/deb-data/image/etc/kernel/preinst.d
    mkdir -p ${workspace}/deb-data/image/etc/kernel/prerm.d
    
    ${MAKE} ARCH=${ARCH} \
        CROSS_COMPILE=${KERNEL_GCC} \
        modules_install \
        INSTALL_MOD_PATH=${workspace}/deb-data/image
    ${MAKE} ARCH=${ARCH} \
        CROSS_COMPILE=${KERNEL_GCC} \
        install \
        INSTALL_PATH=${workspace}/deb-data/image/boot
}

install_headers(){
    SRC_ARCH=${ARCH}
    temp_file_list=`mktemp -t test.XXXXXX`

    (
    find . -name Makefile\* -o -name Kconfig\* -o -name \*.pl

    find arch/*/include include scripts -type f -o -type l

    find security/*/include -type f
    [[ -d "arch/${SRC_ARCH}" ]] && {
    find "arch/${SRC_ARCH}" -name module.lds -o -name Kbuild.platforms -o -name Platform

    find $(find "arch/${SRC_ARCH}" -name include -o -name scripts -type d) -type f
    find arch/${SRC_ARCH}/include -type f
    }
    find Module.symvers include scripts -type f
    find . -name "bitsperlong.h" -type f

    find tools -type f       # all tools; will trim a bit later
    find arch/x86/lib/insn.c # required by objtool stuff...

    if is_enabled CONFIG_GCC_PLUGINS; then
    find scripts/gcc-plugins -name gcc-common.h # @TODO something else here too?
    fi
    ) > "${temp_file_list}"

    cd ${workspace}/linux
    KERNEL_VER=$(ls ${workspace}/deb-data/image/lib/modules/)
    hdr_path=${workspace}/deb-data/headers/usr/src/linux-headers-${KERNEL_VER}
    mkdir -p ${hdr_path}
    mkdir -p ${workspace}/deb-data/headers/lib/modules/${KERNEL_VER}
    echo "Gen kernel headers, please wait..."

    set -e
    for item in $(cat "${temp_file_list}")
    do
        dir_name=$(dirname ${item})
        if [ ${dir_name:0:2} == "./" ];then
        target_dir=${hdr_path}/${dir_name:2}
        else
        target_dir=${hdr_path}/${dir_name}
        fi
        if [ ! -d ${target_dir} ];then
            mkdir -p ${target_dir}
        fi
        cp -r ${item} ${target_dir}
    done

    rm "${temp_file_list}"
    set +e
}

install_libc-dev(){
    cd ${workspace}/linux
    mkdir -p ${workspace}/deb-data/libc-dev/usr
    ${MAKE} ARCH=${ARCH} \
        CROSS_COMPILE=${KERNEL_GCC} \
        headers_install \
        INSTALL_HDR_PATH=${workspace}/deb-data/libc-dev/usr
}

gen_debian_file(){
    KERNEL_VER=$(ls ${workspace}/deb-data/image/lib/modules/)
    DEB_DATA_PATH=${workspace}/deb-data

    DTB_PATH=${DEB_DATA_PATH}/dtb
    mkdir -p ${DTB_PATH}/DEBIAN
    gen_dtb_control ${DTB_PATH}/DEBIAN/control \
        ${AVA_VERSION} \
        ${PKG_NAME} \
        ${ARCH} \
        ${KERNEL_VER} \
        $(du -sk ${DTB_PATH})
    gen_dtb_postinst ${DTB_PATH}/DEBIAN/postinst \
        ${PKG_NAME} \
        ${KERNEL_VER}
    gen_dtb_preinst \
        ${DTB_PATH}/DEBIAN/preinst \
        ${PKG_NAME} \
        ${KERNEL_VER}
    gen_changelog \
        ${DTB_PATH}/DEBIAN/changelog \
        dtb \
        ${PKG_NAME} \
        ${KERNEL_VER}
    gen_md5 \
        ${DTB_PATH}/DEBIAN/md5sums \
        ${DTB_PATH}

    IMAGE_PATH=${DEB_DATA_PATH}/image
    mkdir -p ${IMAGE_PATH}/DEBIAN
    gen_image_control ${IMAGE_PATH}/DEBIAN/control \
        ${AVA_VERSION} \
        ${PKG_NAME} \
        ${ARCH} \
        ${KERNEL_VER} \
        $(du -sk ${IMAGE_PATH})
    gen_image_postinst \
        ${IMAGE_PATH}/DEBIAN/postinst \
        ${PKG_NAME} \
        ${KERNEL_VER}
    gen_image_postrm \
        ${IMAGE_PATH}/DEBIAN/postrm \
        ${PKG_NAME} \
        ${KERNEL_VER}
    gen_image_preinst \
        ${IMAGE_PATH}/DEBIAN/preinst \
        ${PKG_NAME} \
        ${KERNEL_VER}
    gen_image_prerm \
        ${IMAGE_PATH}/DEBIAN/prerm \
        ${PKG_NAME} \
        ${KERNEL_VER}
    gen_changelog \
        ${IMAGE_PATH}/DEBIAN/changelog \
        image \
        ${PKG_NAME} \
        ${KERNEL_VER}
    gen_md5 \
        ${IMAGE_PATH}/DEBIAN/md5sums \
        ${IMAGE_PATH}

    HEADERS_PATH=${DEB_DATA_PATH}/headers
    mkdir -p ${HEADERS_PATH}/DEBIAN
    gen_headers_control \
        ${HEADERS_PATH}/DEBIAN/control \
        ${AVA_VERSION} \
        ${PKG_NAME} \
        ${ARCH} \
        ${KERNEL_VER} \
        $(du -sk ${HEADERS_PATH})
    gen_headers_postinst \
        ${HEADERS_PATH}/DEBIAN/postinst \
        ${PKG_NAME} \
        ${ARCH} \
        ${KERNEL_VER}
    gen_headers_preinst \
        ${HEADERS_PATH}/DEBIAN/preinst \
        ${PKG_NAME} \
        ${KERNEL_VER}
    gen_headers_prerm \
        ${HEADERS_PATH}/DEBIAN/prerm \
        ${PKG_NAME} \
        ${KERNEL_VER}
    gen_changelog \
        ${HEADERS_PATH}/DEBIAN/changelog \
        headers \
        ${PKG_NAME} \
        ${KERNEL_VER}
    gen_md5 \
        ${HEADERS_PATH}/DEBIAN/md5sums \
        ${HEADERS_PATH}

    LIBC_DEV_PATH=${DEB_DATA_PATH}/libc-dev
    mkdir -p ${LIBC_DEV_PATH}/DEBIAN
    gen_libc-dev_control \
        ${LIBC_DEV_PATH}/DEBIAN/control \
        ${AVA_VERSION} \
        ${PKG_NAME} \
        ${ARCH} \
        ${KERNEL_VER} \
        $(du -sk ${LIBC_DEV_PATH})
    gen_changelog \
        ${LIBC_DEV_PATH}/DEBIAN/changelog \
        libc-dev \
        ${PKG_NAME} \
        ${KERNEL_VER}
    gen_md5 \
        ${LIBC_DEV_PATH}/DEBIAN/md5sums \
        ${LIBC_DEV_PATH}

}

gen_package_doc(){
    DEB_DATA_PATH=${workspace}/deb-data
    DTB_PATH=${DEB_DATA_PATH}/dtb
    IMAGE_PATH=${DEB_DATA_PATH}/image
    HEADERS_PATH=${DEB_DATA_PATH}/headers
    LIBC_DEV_PATH=${DEB_DATA_PATH}/libc-dev
    PKG_DOC_DTB_PATH=usr/share/doc/linux-dtb-${PKG_NAME}
    PKG_DOC_IMAGE_PATH=usr/share/doc/linux-image-${PKG_NAME}
    PKG_DOC_HEADERS_PATH=usr/share/doc/linux-headers-${PKG_NAME}
    PKG_DOC_LIBC_DEV_PATH=usr/share/doc/linux-libc-dev-${PKG_NAME}
    
    mkdir -p ${DTB_PATH}/${PKG_DOC_DTB_PATH}
    mkdir -p ${IMAGE_PATH}/${PKG_DOC_IMAGE_PATH}
    mkdir -p ${HEADERS_PATH}/${PKG_DOC_HEADERS_PATH}
    mkdir -p ${LIBC_DEV_PATH}/${PKG_DOC_LIBC_DEV_PATH}

    gen_copyright ${DTB_PATH}/${PKG_DOC_DTB_PATH}/copyright
    gen_copyright ${IMAGE_PATH}/${PKG_DOC_IMAGE_PATH}/copyright
    gen_copyright ${HEADERS_PATH}/${PKG_DOC_HEADERS_PATH}/copyright
    gen_copyright ${LIBC_DEV_PATH}/${PKG_DOC_LIBC_DEV_PATH}/copyright

    gen_changelog_gz(){
        cp $2 $1
        gzip $1/changelog
    }

    gen_changelog_gz \
        ${DTB_PATH}/${PKG_DOC_DTB_PATH} \
        ${DTB_PATH}/DEBIAN/changelog
    gen_changelog_gz \
        ${IMAGE_PATH}/${PKG_DOC_IMAGE_PATH} \
        ${IMAGE_PATH}/DEBIAN/changelog
    gen_changelog_gz \
        ${HEADERS_PATH}/${PKG_DOC_HEADERS_PATH} \
        ${HEADERS_PATH}/DEBIAN/changelog
    gen_changelog_gz \
        ${LIBC_DEV_PATH}/${PKG_DOC_LIBC_DEV_PATH} \
        ${LIBC_DEV_PATH}/DEBIAN/changelog

}

pack_kernel_packages(){
    echo "packing kernel packages..."
    DEB_DATA_PATH=${workspace}/deb-data
    DTB_PATH=${DEB_DATA_PATH}/dtb
    IMAGE_PATH=${DEB_DATA_PATH}/image
    HEADERS_PATH=${DEB_DATA_PATH}/headers
    LIBC_DEV_PATH=${DEB_DATA_PATH}/libc-dev

    if [ ! -d ${PACKAGES_OUTPUT_PATH} ];then
        rm -rf ${PACKAGES_OUTPUT_PATH}
        mkdir -p ${PACKAGES_OUTPUT_PATH}
    else
        mkdir -p ${PACKAGES_OUTPUT_PATH}
    fi
    
    dpkg-deb -b \
        ${DTB_PATH}/ \
        ${PACKAGES_OUTPUT_PATH}
    dpkg-deb -b \
        ${IMAGE_PATH}/ \
        ${PACKAGES_OUTPUT_PATH}
    dpkg-deb -b \
        ${HEADERS_PATH}/ \
        ${PACKAGES_OUTPUT_PATH}
    dpkg-deb -b \
        ${LIBC_DEV_PATH}/ \
        ${PACKAGES_OUTPUT_PATH}

}

workspace=$(pwd)
cd ${workspace}

default_param
parseargs "$@" || help $?

source ../boards/${BOARD}.conf

AVA_VERSION=$(cat ../VERSION)
kconfig_name=${LINUX_CONFIG:0:-10}
PKG_NAME=${kconfig_name//_/-}
PACKAGES_OUTPUT_PATH=${workspace}/${BOARD}-kernel-pkgs

MAKE="make"
if [ ${USE_CCACHE} == "yes" ];then
    MAKE="ccache ${MAKE}"
fi

source ../scripts/lib/packages/kernel-deb.sh

set -e
compile_linux
install_dtb
install_image_modules
install_headers
install_libc-dev
gen_debian_file
gen_package_doc
pack_kernel_packages

echo "${LINUX_CONFIG}" > ${workspace}/${BOARD}-kernel-pkgs/.done
