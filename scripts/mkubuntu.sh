#!/bin/bash

__usage="
Usage: mkubuntu [OPTIONS]
Build Ubuntu rootfs.
Run in root user.
The target rootfs will be generated in the build folder of the directory where the mkubuntu.sh script is located.

Options: 
  -m, --mirror MIRROR_ADDR      The URL/path of target mirror address.
  -r, --rootfs ROOTFS_DIR       The directory name of ubuntu rootfs.
  -v, --version UBUNTU_VER      The version of ubuntu.
  -a, --arch ARCH               The arch of ubuntu.
  -t, --type ROOTFS_TYPE        The type of rootfs: cli, xfce, gnome, kde.
  -h, --help                    Show command help.
"

help()
{
    echo "$__usage"
    exit $1
}

default_param() {
    ARCH=aarch64
    ROOTFS=rootfs
    VERSION=jammy
    TYPE=cli
    MIRROR=http://mirrors.ustc.edu.cn/ubuntu-ports
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

HOST_ARCH=$(arch)

default_param
parseargs "$@" || help $?

BASE_PKGS="sudo ssh net-tools ethtool wireless-tools network-manager iputils-ping rsyslog alsa-utils busybox kmod fdisk"
BASE_TOOLS="binutils file tree sudo bash-completion openssh-server network-manager dnsmasq-base libpam-systemd ppp wireless-regdb wpasupplicant iptables systemd-timesyncd vim usbutils parted exfatprogs systemd-sysv net-tools ethtool"
XFCE_DESKTOP="xubuntu-desktop"
GNOME_DESKTOP="ubuntu-desktop"
KDE_DESKTOP="kubuntu-desktop"
LXQT_DESKTOP="lubuntu-desktop"
FONTS="fonts-crosextra-caladea fonts-crosextra-carlito fonts-dejavu fonts-liberation fonts-liberation2 fonts-linuxlibertine fonts-noto-core fonts-noto-cjk fonts-noto-extra fonts-noto-mono fonts-noto-ui-core fonts-sil-gentium-basic"

if [ "${TYPE}" == "cli" ];then
    INCLUDE_PACKAGES="${BASE_TOOLS} ${FONTS}"
elif [ "${TYPE}" == "xfce" ];then
    INCLUDE_PACKAGES="${BASE_TOOLS} ${XFCE_DESKTOP} ${FONTS}"
elif [ "${TYPE}" == "gnome" ];then
    INCLUDE_PACKAGES="${BASE_TOOLS} ${GNOME_DESKTOP} ${FONTS}"
elif [ "${TYPE}" == "kde" ];then
    INCLUDE_PACKAGES="${BASE_TOOLS} ${KDE_DESKTOP} ${FONTS}"
elif [ "${TYPE}" == "lxqt" ];then
    INCLUDE_PACKAGES="${BASE_TOOLS} ${LXQT_DESKTOP} ${FONTS}"
else
    echo "unsupported rootfs type."
    exit 2
fi


echo You are running this scipt on a ${HOST_ARCH} mechine....

if [ -d ${ROOTFS} ];then rm -rf ${ROOTFS}; fi
mkdir ${ROOTFS}

if [ -f ubuntu-${TYPE}.tar.gz ];then rm ubuntu-${TYPE}.tar.gz; fi

if [ "${ARCH}" == "aarch64" ];then
sudo mmdebstrap --architectures=arm64 \
    --include="ca-certificates locales dosfstools sudo bash-completion network-manager openssh-server systemd-timesyncd apt" \
    ${VERSION} "${ROOTFS}" \
    ${MIRROR}
elif [ "${ARCH}" == "armhf" ];then
sudo mmdebstrap --architectures=armhf \
    --include="ca-certificates locales dosfstools sudo bash-completion network-manager openssh-server systemd-timesyncd apt" \
    ${VERSION} "${ROOTFS}" \
    ${MIRROR}
else
echo "unsupported arch."
exit 2
fi

if [ "${HOST_ARCH}" != "${ARCH}" ];then
sudo cp /usr/bin/qemu-${ARCH}-static ${ROOTFS}/usr/bin
else
echo "You are running this script on a ${ARCH} mechine, progress...."
fi

LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} dpkg --configure -a

if [ "${VERSION}" != "noble" ];then
cat ../target/conf/sources.list > ${ROOTFS}/etc/apt/sources.list
sed -i "s|jammy|${VERSION}|g" ${ROOTFS}/etc/apt/sources.list
fi
sed -i "s|http://ports.ubuntu.com/ubuntu-ports|${MIRROR}|g" ${ROOTFS}/etc/apt/sources.list

mount --bind /dev ${ROOTFS}/dev
mount -t proc /proc ${ROOTFS}/proc
mount -t sysfs /sys ${ROOTFS}/sys

trap 'UMOUNT_ALL' EXIT

LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get update
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get install -y ${BASE_PKGS} --no-install-recommends
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get install -y ifupdown
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get install -y ${INCLUDE_PACKAGES}

mkdir ${ROOTFS}/kernel-deb && cp *.deb ${ROOTFS}/kernel-deb

cat <<EOF | LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS}
dpkg -i /kernel-deb/*.deb
EOF

rm -rf ${ROOTFS}/kernel-deb

cat <<EOF | chroot ${ROOTFS} adduser avaota && addgroup avaota sudo
avaota
avaota
avaota
0
0
0
0
y
EOF

# username：avaota
# password：avaota

if [ "${ARCH}" == "aarch64" ];then
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} dpkg --add-architecture armhf
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get update
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get install libc6:armhf libstdc++6:armhf -y
fi

LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get update
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get upgrade -y

chroot ${ROOTFS} apt clean

cp ../target/services/init-resize/init-resize.sh ${ROOTFS}/usr/local/bin
cp ../target/services/init-resize/init-resize.service ${ROOTFS}/etc/systemd/system/

chmod +x ${ROOTFS}/usr/local/bin/init-resize.sh

chroot ${ROOTFS} sudo systemctl enable init-resize.service

if [ "$HOST_ARCH" != "$ARCH" ];then
sudo rm ${ROOTFS}/usr/bin/qemu-${ARCH}-static
else
echo "You are running this script on a ${ARCH} mechine, progress...."
fi

echo '127.0.0.1	avaota-sbc' >> ${ROOTFS}/etc/hosts

cat /dev/null > ${ROOTFS}/etc/hostname
echo 'avaota-sbc' >> ${ROOTFS}/etc/hostname

echo "avaota ALL=(ALL) NOPASSWD: ALL" >> ${ROOTFS}/etc/sudoers.d/010_avaota-nopassword

cat /dev/null > ${ROOTFS}/etc/fstab

cat <<EOF >> ${ROOTFS}/etc/fstab
LABEL=boot      /boot           vfat    defaults          0       0
LABEL=rootfs    /               ext4    defaults,noatime  0       1
EOF

UMOUNT_ALL

mv ${ROOTFS} ubuntu-${TYPE}
touch ubuntu-${TYPE}/THIS-IS-NOT-YOUR-ROOT
