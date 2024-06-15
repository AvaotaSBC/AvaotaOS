#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# This file is a part of the Avaota Build Framework
# https://github.com/AvaotaSBC/AvaotaOS/

__usage="
Usage: mkubuntu [OPTIONS]
Build Ubuntu rootfs.
Run in root user.
The target rootfs will be generated in the build folder of the directory where the mkubuntu.sh script is located.

Options: 
  -m, --mirror MIRROR_ADDR         The URL/path of target mirror address.
  -r, --rootfs ROOTFS_DIR          The directory name of ubuntu rootfs.
  -v, --version UBUNTU_VER         The version of ubuntu/debian.
  -a, --arch ARCH                  The arch of ubuntu/debian.
  -t, --type ROOTFS_TYPE           The type of rootfs: cli, xfce, gnome, kde.
  -u, --user SYS_USER              The normal user of rootfs.
  -p, --password SYS_PASSWORD      The password of user.
  -s, --supassword ROOT_PASSWORD   The password of root.
  -h, --help                       Show command help.
"

help()
{
    echo "$__usage"
    exit $1
}

default_param() {
    ARCH=arm64
    ROOTFS=rootfs
    VERSION=jammy
    TYPE=cli
    if [[ "${VERSION}" == "jammy" || "${VERSION}" == "noble" ]];then
        MIRROR=http://ports.ubuntu.com
    elif [[ "${VERSION}" == "bookworm" || "${VERSION}" == "trixie" ]];then
        MIRROR=http://deb.debian.org/debian
    fi
    SYS_USER=avaota
    SYS_PASSWORD=avaota
    ROOT_PASSWORD=avaota
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
        elif [ "x$1" == "x-a" -o "x$1" == "x--arch" ]; then
            ARCH=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-t" -o "x$1" == "x--type" ]; then
            TYPE=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-c" -o "x$1" == "x--config" ]; then
            LINUX_CONFIG=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-u" -o "x$1" == "x--user" ]; then
            SYS_USER=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-p" -o "x$1" == "x--password" ]; then
            SYS_PASSWORD=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-s" -o "x$1" == "x--supassword" ]; then
            ROOT_PASSWORD=`echo $2`
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

INSTALL_PACKAGES(){
    for item in $(cat $1)
    do
        LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get install -y ${item}
        if [ $? == 0 ]; then
            echo "installed $item."
        else
            echo "can not install $item."
        fi
    done
}

run_debootstrap(){

echo You are running this scipt on a ${HOST_ARCH} mechine....

    if [ -d ${ROOTFS} ];then rm -rf ${ROOTFS}; fi
    mkdir ${ROOTFS}

    if [ "${ARCH}" == "arm64" ];then
        sudo debootstrap --foreign --no-check-gpg --arch=arm64 ${VERSION} ${ROOTFS} ${MIRROR}
    elif [ "${ARCH}" == "arm" ];then
        sudo debootstrap --foreign --no-check-gpg --arch=armhf ${VERSION} ${ROOTFS} ${MIRROR}
    else
        echo "unsupported arch."
        exit 2
    fi

    if [ "${HOST_ARCH}" != "${ARCH}" ];then
        if [ ${ARCH} == "arm64" ];then
            sudo cp /usr/bin/qemu-aarch64-static ${ROOTFS}/usr/bin
        elif [ ${ARCH} == "arm" ];then
            sudo cp /usr/bin/qemu-arm-static ${ROOTFS}/usr/bin
        fi
    else
        echo "You are running this script on a ${ARCH} mechine, progress...."
    fi

    sudo LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} /debootstrap/debootstrap --second-stage
    sudo LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} dpkg --configure -a

}

prepare_apt-list(){
if [ "${VERSION}" == "jammy" ];then
    cat ../os/${VERSION}/apt-list/sources.list > ${ROOTFS}/etc/apt/sources.list
    sed -i "s|http://ports.ubuntu.com/ubuntu-ports|${MIRROR}|g" ${ROOTFS}/etc/apt/sources.list
elif [ "${VERSION}" == "noble" ];then
     "# Ubuntu sources have moved to /etc/apt/sources.list.d/ubuntu.sources" > ${ROOTFS}/etc/apt/sources.list
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

install_base_packages(){
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get update

INSTALL_PACKAGES ../os/${VERSION}/base-packages.list

if [ "${TYPE}" != "cli" ];then
    echo "Build desktop image."
    INSTALL_PACKAGES ../os/${VERSION}/${TYPE}-packages.list
fi
}

install_kernel_packages(){
cp -r ${LINUX_CONFIG}-kernel-pkgs ${ROOTFS}/kernel-deb

LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get update
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get upgrade -y

cat <<EOF | LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS}
dpkg -i /kernel-deb/linux-libc-dev*.deb
apt-get -f install -y
dpkg -i /kernel-deb/linux-dtb*.deb
dpkg -i /kernel-deb/linux-image*.deb
apt-get -f install -y
EOF

rm -rf ${ROOTFS}/kernel-deb
}

setup_users(){
#SYS_USER=avaota
#SYS_PASSWORD=avaota
#ROOT_PASSWORD=avaota

cat <<EOF | chroot ${ROOTFS} adduser ${SYS_USER} && addgroup ${SYS_USER} sudo
${SYS_USER}
${SYS_PASSWORD}
${SYS_PASSWORD}
0
0
0
0
y
EOF

# username：avaota
# password：avaota

cat <<EOF | chroot ${ROOTFS} passwd root
${ROOT_PASSWORD}
${ROOT_PASSWORD}
EOF

# username：root
# password：avaota

sed -i "s|#PermitRootLogin prohibit-password|PermitRootLogin yes|g" ${ROOTFS}/etc/ssh/sshd_config

# Allow root ssh login
}

setup_dhcp(){
if [[ "${VERSION}" == "jammy" || "${VERSION}" == "noble" ]];then
    LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} netplan set ethernets.eth0.dhcp4=true
    LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} netplan set ethernets.eth0.dhcp6=true
    LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} netplan set ethernets.eth1.dhcp4=true
    LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} netplan set ethernets.eth1.dhcp6=true
    LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} sudo chmod 600 /etc/netplan/*.yaml
elif [[ "${VERSION}" == "bookworm" || "${VERSION}" == "trixie" || "${VERSION}" == "bullseye" ]];then
    LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get update
    LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get install ifupdown
fi
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
echo '127.0.0.1	avaota-sbc' >> ${ROOTFS}/etc/hosts

cat /dev/null > ${ROOTFS}/etc/hostname
echo 'avaota-sbc' >> ${ROOTFS}/etc/hostname

echo "avaota ALL=(ALL) NOPASSWD: ALL" >> ${ROOTFS}/etc/sudoers.d/010_avaota-nopassword

cat /dev/null > ${ROOTFS}/etc/fstab

cat <<EOF >> ${ROOTFS}/etc/fstab
LABEL=boot      /boot           vfat    defaults          0       0
LABEL=rootfs    /               ext4    defaults,noatime  0       1
EOF
}

HOST_ARCH=$(arch)

default_param
parseargs "$@" || help $?

run_debootstrap
prepare_apt-list
setup_mount_resolv

trap 'UMOUNT_ALL' EXIT

install_kernel_packages
install_base_packages
setup_users
setup_dhcp

if [ "${ARCH}" == "arm64" ];then
setup_armhf_compate
fi

setup_firstrun
clean_rootfs
setup_hostname_fstab

UMOUNT_ALL

mv ${ROOTFS} ubuntu-${VERSION}-${TYPE}
touch ubuntu-${VERSION}-${TYPE}/THIS-IS-NOT-YOUR-ROOT
