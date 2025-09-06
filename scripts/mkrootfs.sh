#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# This file is a part of the Avaota Build Framework
# https://github.com/AvaotaSBC/AvaotaOS/

__usage="
Usage: mkrootfs [OPTIONS]
Build Rootfs rootfs.
Run in root user.
The target rootfs will be generated in the build folder of the directory where the mkrootfs.sh script is located.

Options: 
  -m, --mirror MIRROR_ADDR         The URL/path of target mirror address.
  -r, --rootfs ROOTFS_DIR          The directory name of rootfs rootfs.
  -v, --version ROOTFS_VER         The version of ubuntu/debian.
  -b, --board BOARD                The target board.
  -t, --type ROOTFS_TYPE           The type of rootfs: cli, xfce, gnome, kde.
  -h, --help                       Show command help.
"

help()
{
    echo "$__usage"
    exit $1
}

default_param() {
    BOARD=avaota-a1
    ROOTFS=rootfs
    VERSION=jammy
    TYPE=cli
    if [[ "${VERSION}" == "jammy" || "${VERSION}" == "noble" ]];then
        MIRROR=http://ports.ubuntu.com
    elif [[ "${VERSION}" == "bookworm" || "${VERSION}" == "trixie" ]];then
        MIRROR=http://deb.debian.org/debian
    fi
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
        elif [ "x$1" == "x-m" -o "x$1" == "x--mirror" ]; then
            MIRROR=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-r" -o "x$1" == "x--rootfs" ]; then
            ROOTFS=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-v" -o "x$1" == "x--version" ]; then
            VERSION=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-b" -o "x$1" == "x--BOARD" ]; then
            BOARD=`echo $2`
            shift
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
    if grep -q "${ROOTFS}/dev " /proc/mounts ; then
        umount -l ${ROOTFS}/dev
    fi
    if grep -q "${ROOTFS}/proc " /proc/mounts ; then
        umount -l ${ROOTFS}/proc
    fi
    if grep -q "${ROOTFS}/sys " /proc/mounts ; then
        umount -l ${ROOTFS}/sys
    fi
    set -e
}

run_debootstrap(){
    if [[ "${VERSION}" == "jammy" || "${VERSION}" == "focal" || "${VERSION}" == "noble" ]];then
        LIST="main multiverse restricted universe"
        SRC_LIST="'deb ${MIRROR} ${VERSION} main multiverse restricted universe' \
                  'deb ${MIRROR} ${VERSION}-updates main multiverse restricted universe'"
    elif [[ "${VERSION}" == "bullseye" || "${VERSION}" == "bookworm" || "${VERSION}" == "trixie" ]];then
        SRC_LIST="'deb ${MIRROR} ${VERSION} main contrib non-free non-free-firmware' \
                  'deb ${MIRROR} ${VERSION}-updates main contrib non-free non-free-firmware'"
    fi
    
    BASE_PKGS=$(cat ../os/${VERSION}/base-packages.list)
    EXT_PKGS=""
    
    if [ "${TYPE}" != "cli" ];then
        echo "Build desktop image."
        EXT_PKGS=$(cat ../os/${VERSION}/${TYPE}-packages.list)
    fi
    
    PACKAGES="${BASE_PKGS} ${EXT_PKGS}"

    echo You are running this scipt on a ${HOST_ARCH} mechine....

    if [ -d ${ROOTFS} ];then rm -rf ${ROOTFS}; fi
    mkdir ${ROOTFS}

    if [ "${ARCH}" == "arm64" ];then
        sudo mmdebstrap --architectures=arm64 \
        --include="${PACKAGES}" \
        ${VERSION} ${ROOTFS} \
        "deb ${MIRROR} ${VERSION} ${LIST}" \
        "deb ${MIRROR} ${VERSION}-updates ${LIST}"
    elif [ "${ARCH}" == "arm" ];then
        sudo mmdebstrap --architectures=armhf \
        --include="${PACKAGES}" \
        ${VERSION} ${ROOTFS} \
        "deb ${MIRROR} ${VERSION} ${LIST}" \
        "deb ${MIRROR} ${VERSION}-updates ${LIST}"
    else
        echo "unsupported arch."
        exit 2
    fi
}

prepare_apt-list(){
if [[ "${VERSION}" == "jammy" || "${VERSION}" == "focal" ]];then
    cat ../os/${VERSION}/apt-list/sources.list > ${ROOTFS}/etc/apt/sources.list
    sed -i "s|http://ports.ubuntu.com/ubuntu-ports|${MIRROR}|g" ${ROOTFS}/etc/apt/sources.list
elif [ "${VERSION}" == "noble" ];then
    echo "# Ubuntu sources have moved to /etc/apt/sources.list.d/ubuntu.sources" > ${ROOTFS}/etc/apt/sources.list
    cat ../os/${VERSION}/apt-list/ubuntu.sources > ${ROOTFS}/etc/apt/sources.list.d/ubuntu.sources
    sed -i "s|http://ports.ubuntu.com/ubuntu-ports|${MIRROR}|g" ${ROOTFS}/etc/apt/sources.list.d/ubuntu.sources
elif [ "${VERSION}" == "bullseye" ];then
    cat ../os/${VERSION}/apt-list/sources.list > ${ROOTFS}/etc/apt/sources.list
    sed -i "s|http://deb.debian.org|${MIRROR}|g" ${ROOTFS}/etc/apt/sources.list
elif [[ "${VERSION}" == "bookworm" || "${VERSION}" == "trixie" ]];then
    rm ${ROOTFS}/etc/apt/sources.list
    cat ../os/${VERSION}/apt-list/debian.sources > ${ROOTFS}/etc/apt/sources.list.d/debian.sources
    sed -i "s|http://deb.debian.org/debian|${MIRROR}|g" ${ROOTFS}/etc/apt/sources.list.d/debian.sources
    sed -i "s|VERSION|${VERSION}|g" ${ROOTFS}/etc/apt/sources.list.d/debian.sources
fi
}

setup_mount_resolv(){
mount --bind /dev ${ROOTFS}/dev
mount -t proc /proc ${ROOTFS}/proc
mount -t sysfs /sys ${ROOTFS}/sys

cp -b /etc/resolv.conf ${ROOTFS}/etc/resolv.conf
}

setup_dhcp(){
    echo "will overwriten by board.conf"
}

setup_armhf_compate(){
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} dpkg --add-architecture armhf
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get update
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get install libc6:armhf libstdc++6:armhf -y
}

setup_firstrun(){
cp ../target/services/init-resize/init-resize.sh ${ROOTFS}/usr/local/bin
cp ../target/services/init-resize/init-resize.service ${ROOTFS}/etc/systemd/system/

chmod +x ${ROOTFS}/usr/local/bin/init-resize.sh

chroot ${ROOTFS} sudo systemctl enable init-resize.service

sed -i "s|#PermitRootLogin prohibit-password|PermitRootLogin yes|g" ${ROOTFS}/etc/ssh/sshd_config

# Allow root ssh login
}

clean_rootfs(){
chroot ${ROOTFS} apt clean
if [ "$HOST_ARCH" != "$ARCH" ];then
    if [ ${ARCH} == "arm64" ];then
        sudo rm ${ROOTFS}/usr/bin/qemu-aarch64-static
    elif [ ${ARCH} == "arm" ];then
        sudo rm ${ROOTFS}/usr/bin/qemu-arm-static
    fi
else
echo "You are running this script on a ${ARCH} mechine, progress...."
fi
}

setup_hostname_fstab(){
echo '127.0.0.1	${BOARD_NAME}' >> ${ROOTFS}/etc/hosts

cat /dev/null > ${ROOTFS}/etc/hostname
echo '${BOARD_NAME}' >> ${ROOTFS}/etc/hostname

echo "avaota ALL=(ALL) NOPASSWD: ALL" >> ${ROOTFS}/etc/sudoers.d/010_avaota-nopassword

cat /dev/null > ${ROOTFS}/etc/fstab

cat <<EOF >> ${ROOTFS}/etc/fstab
LABEL=boot      /boot           vfat    defaults          0       0
LABEL=rootfs    /               ext4    defaults,noatime  0       1
EOF
}

pack_target_pcakages(){
    if [ -d target_packages ];then
        rm -rf target_packages
    fi
    mkdir target_packages
    for pkg in $(ls ${workspace}/../target/packages)
    do
        gen_md5 \
            ${workspace}/../target/packages/${pkg}/DEBIAN/md5sums \
            ${workspace}/../target/packages/${pkg}
        dpkg-deb -b \
            ${workspace}/../target/packages/${pkg} \
            target_packages
        if [ $? == 0 ]; then
            echo "packaged $pkg."
        else
            echo "can not package $pkg."
        fi
        rm ${workspace}/../target/packages/${pkg}/DEBIAN/md5sums
    done
}

HOST_ARCH=$(arch)

workspace=$(pwd)
cd ${workspace}

default_param
parseargs "$@" || help $?

source ../boards/${BOARD}.conf
source ${workspace}/../scripts/lib/packages/useroverlay-deb.sh

# TODO: download rootfs from Syter's server

run_debootstrap
prepare_apt-list
setup_mount_resolv

trap 'UMOUNT_ALL' EXIT

setup_dhcp

#if [ "${ARCH}" == "arm64" ];then
#setup_armhf_compate
#fi

setup_firstrun
clean_rootfs
setup_hostname_fstab
#pack_target_pcakages

UMOUNT_ALL

mv ${ROOTFS} rootfs-${VERSION}-${TYPE}

pushd rootfs-${VERSION}-${TYPE}
tar -zcvf ${workspace}/rootfs-${VERSION}-${TYPE}.tar.gz *
popd

rm -rf rootfs-${VERSION}-${TYPE}
