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

BASE_TOOLS="binutils file tree sudo bash-completion openssh-server network-manager dnsmasq-base libpam-systemd ppp wireless-regdb wpasupplicant libengine-pkcs11-openssl iptables systemd-timesyncd vim usbutils libgles2 parted exfatprogs systemd-sysv mesa-vulkan-drivers"
XFCE_DESKTOP="xorg xfce4 desktop-base lightdm xfce4-terminal tango-icon-theme xfce4-notifyd xfce4-power-manager network-manager-gnome xfce4-goodies pulseaudio alsa-utils dbus-user-session rtkit pavucontrol thunar-volman eject gvfs gvfs-backends udisks2 dosfstools e2fsprogs libblockdev-crypto2 ntfs-3g polkitd blueman"
GNOME_DESKTOP="gnome-core avahi-daemon desktop-base file-roller gnome-tweaks gstreamer1.0-libav gstreamer1.0-plugins-ugly libgsf-bin libproxy1-plugin-networkmanager network-manager-gnome"
KDE_DESKTOP="kde-plasma-desktop"
BENCHMARK_TOOLS="glmark2-es2 mesa-utils vulkan-tools iperf3 stress-ng"
FONTS="fonts-crosextra-caladea fonts-crosextra-carlito fonts-dejavu fonts-liberation fonts-liberation2 fonts-linuxlibertine fonts-noto-core fonts-noto-cjk fonts-noto-extra fonts-noto-mono fonts-noto-ui-core fonts-sil-gentium-basic"
EXTRA_TOOLS="i2c-tools net-tools ethtool"

if [ "${TYPE}" == "cli" ];then
    INCLUDE_PACKAGES="${BASE_TOOLS} ${FONTS} ${EXTRA_TOOLS}"
elif [ "${TYPE}" == "xfce" ];then
    INCLUDE_PACKAGES="${BASE_TOOLS} ${XFCE_DESKTOP} ${BENCHMARK_TOOLS} ${FONTS} ${EXTRA_TOOLS}"
elif [ "${TYPE}" == "gnome" ];then
    INCLUDE_PACKAGES="${BASE_TOOLS} ${GNOME_DESKTOP} ${BENCHMARK_TOOLS} ${FONTS} ${EXTRA_TOOLS}"
elif [ "${TYPE}" == "kde" ];then
    INCLUDE_PACKAGES="${BASE_TOOLS} ${KDE_DESKTOP} ${BENCHMARK_TOOLS} ${FONTS} ${EXTRA_TOOLS}"
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
echo "
# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://ports.ubuntu.com/ubuntu-ports/ jammy main restricted
# deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-updates main restricted
# deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb http://ports.ubuntu.com/ubuntu-ports/ jammy universe
# deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy universe
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-updates universe
# deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy-updates universe

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team, and may not be under a free licence. Please satisfy yourself as to
## your rights to use the software. Also, please note that software in
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb http://ports.ubuntu.com/ubuntu-ports/ jammy multiverse
# deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-updates multiverse
# deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy-updates multiverse

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-backports main restricted universe multiverse
# deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy-backports main restricted universe multiverse

deb http://ports.ubuntu.com/ubuntu-ports/ jammy-security main restricted
# deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy-security main restricted
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-security universe
# deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy-security universe
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-security multiverse
# deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy-security multiverse
" > ${ROOTFS}/etc/apt/sources.list

sed -i "s|jammy|${VERSION}|g" ${ROOTFS}/etc/apt/sources.list
fi
sed -i "s|http://ports.ubuntu.com/ubuntu-ports|${MIRROR}|g" ${ROOTFS}/etc/apt/sources.list

mount --bind /dev ${ROOTFS}/dev
mount -t proc /proc ${ROOTFS}/proc
mount -t sysfs /sys ${ROOTFS}/sys

trap 'UMOUNT_ALL' EXIT

LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get update
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get install -y sudo ssh net-tools ethtool wireless-tools network-manager iputils-ping rsyslog alsa-utils busybox kmod --no-install-recommends
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get install -y ifupdown
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS} apt-get install -y ${INCLUDE_PACKAGES}

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

chroot ${ROOTFS} apt clean

if [ "$HOST_ARCH" != "$ARCH" ];then
sudo rm ${ROOTFS}/usr/bin/qemu-${ARCH}-static
else
echo "You are running this script on a ${ARCH} mechine, progress...."
fi

echo '127.0.0.1	avaota-board' >> ${ROOTFS}/etc/hosts

cat /dev/null > ${ROOTFS}/etc/hostname
echo 'avaota-board' >> ${ROOTFS}/etc/hostname

echo "user ALL=(ALL) NOPASSWD: ALL" >> ${ROOTFS}/etc/sudoers.d/010_user-nopassword

cat /dev/null > ${ROOTFS}/etc/fstab

cat <<EOF >> ${ROOTFS}/etc/fstab
LABEL=boot      /boot           vfat    defaults          0       0
LABEL=rootfs    /               ext4    defaults,noatime  0       1
EOF

UMOUNT_ALL

mv ${ROOTFS} ubuntu-${TYPE}
touch ubuntu-${TYPE}/THIS-IS-NOT-YOUR-ROOT
