#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# This file is a part of the Avaota Build Framework
# https://github.com/AvaotaSBC/AvaotaOS/

is_enabled() {
	grep -q "^$1=y" include/config/auto.conf
}

# gen_md5 <file> <path>
gen_md5(){
pushd $2
find . -type f ! -path './DEBIAN/*' -printf '%P\0' | xargs -r0 md5sum > $1
popd
}

# gen_changelog <file> <dtb\image\headers\libc-dev> <sun55i-t527-bsp> <5.15.153>
gen_changelog(){
cat <<- CHANGELOG > "$1"
linux-PART-BOARD (LINUX_VERSION) global; urgency=low

  * Initial changelog entry for linux-PART-BOARD package.

 -- AvaotaSBC AvaotaOS <info@avaotaos.local>  May, 14 Jun 2024 23:59:59 +0000
CHANGELOG

sed -i "s|PART|${2}|g" ${1}
sed -i "s|BOARD|${3}|g" ${1}
sed -i "s|LINUX_VERSION|${4}|g" ${1}
}

gen_copyright(){
cat <<- COPYRIGHT > "$1"
This is a packaged AvaotaOS patched version of the Linux kernel.

The sources may be found at most Linux archive sites, including:
https://www.kernel.org/pub/linux/kernel

Copyright: 1991 - 2018 Linus Torvalds and others.

The git repository for mainline kernel development is at:
git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; version 2 dated June, 1991.

On Debian GNU/Linux systems, the complete text of the GNU General Public
License version 3 can be found in \`/usr/share/common-licenses/GPL-3\`.
COPYRIGHT
}

# gen_dtb_control <file> <AVA_VERSION> <sun55i-t527-bsp> <arm64> <5.15.153> <SIZE>
gen_dtb_control(){
cat <<- CONTROL > "$1"
Version: AVA_VERSION
Maintainer: AvaotaSBC AvaotaOS <info@avaotaos.local>
Section: kernel
Package: linux-dtb-BOARD
Architecture: ARCH
Priority: optional
Provides: linux-dtb, linux-dtb-avaotaos
Description: AvaotaOS DTBs in /boot/dtb
 This package contains device tree blobs from the Linux kernel, version LINUX_VERSION.
Installed-Size: INS_SIZE
CONTROL

sed -i "s|AVA_VERSION|${2}|g" ${1}
sed -i "s|BOARD|${3}|g" ${1}
sed -i "s|ARCH|${4}|g" ${1}
sed -i "s|LINUX_VERSION|${5}|g" ${1}
sed -i "s|INS_SIZE|${6}|g" ${1}
}

# gen_headers_control <file> <AVA_VERSION> <sun55i-t527-bsp> <arm64> <5.15.153> <SIZE>
gen_headers_control(){
cat <<- CONTROL > "$1"
Version: AVA_VERSION
Maintainer: AvaotaOS <info@avaotaos.local>
Section: devel
Package: linux-headers-BOARD
Architecture: ARCH
Priority: optional
Provides: linux-headers, linux-headers-avaotaos
Depends: make, gcc, libc6-dev, bison, flex, libssl-dev, libelf-dev
Description: AvaotaOS legacy headers LINUX_VERSION
 This package provides kernel header files for LINUX_VERSION
 .
 This is useful for DKMS and building of external modules.
Installed-Size: 68130
CONTROL

sed -i "s|AVA_VERSION|${2}|g" ${1}
sed -i "s|BOARD|${3}|g" ${1}
sed -i "s|ARCH|${4}|g" ${1}
sed -i "s|LINUX_VERSION|${5}|g" ${1}
sed -i "s|INS_SIZE|${6}|g" ${1}
}

# gen_image_control <file> <AVA_VERSION> <sun55i-t527-bsp> <arm64> <5.15.153> <SIZE>
gen_image_control(){
cat <<- CONTROL > "$1"
Package: linux-image-BOARD
Version: AVA_VERSION
Source: linux-LINUX_VERSION
AvaotaOS-Kernel-Version: LINUX_VERSION
AvaotaOS-Kernel-Version-Family: LINUX_VERSION
Architecture: ARCH
Maintainer: AvaotaOS <info@avaotaos.local>
Section: kernel
Priority: optional
Provides: linux-image, linux-image-avaotaos
Description: AvaotaOS kernel image LINUX_VERSION
 This package contains the Linux kernel, modules and corresponding other files.
Installed-Size: INS_SIZE
CONTROL

sed -i "s|AVA_VERSION|${2}|g" ${1}
sed -i "s|BOARD|${3}|g" ${1}
sed -i "s|ARCH|${4}|g" ${1}
sed -i "s|LINUX_VERSION|${5}|g" ${1}
sed -i "s|INS_SIZE|${6}|g" ${1}
}

# gen_libc-dev_control <file> <AVA_VERSION> <sun55i-t527-bsp> <arm64> <5.15.153> <SIZE>
gen_libc-dev_control(){
cat <<- CONTROL > "$1"
Version: AVA_VERSION
Maintainer: AvaotaOS <info@avaotaos.local>
Package: linux-libc-dev-BOARD
Section: devel
Priority: optional
Provides: linux-libc-dev
Conflicts: linux-libc-dev
Architecture: ARCH
Description: AvaotaOS support headers for userspace development
 This package provides userspaces headers from the Linux kernel.  These headers
 are used by the installed headers for GNU glibc and other system libraries.
Multi-Arch: same
Installed-Size: INS_SIZE
CONTROL

sed -i "s|AVA_VERSION|${2}|g" ${1}
sed -i "s|BOARD|${3}|g" ${1}
sed -i "s|ARCH|${4}|g" ${1}
sed -i "s|LINUX_VERSION|${5}|g" ${1}
sed -i "s|INS_SIZE|${6}|g" ${1}
}

# gen_dtb_postinst <file> <sun55i-t527-bsp> <5.15.153>
gen_dtb_postinst(){
cat <<- POSTINST > "$1"
#!/bin/bash
echo "AvaotaOS 'linux-dtb-BOARD' for 'LINUX_VERSION': 'postinst' starting."
set -e # Error control

#set -x # Debugging

cd /boot

echo "AvaotaOS: DTB: FAT32: moving /boot/dtb-LINUX_VERSION to /boot/dtb ..."
mv -v "dtb-LINUX_VERSION" dtb

set +x # Disable debugging
echo "AvaotaOS 'linux-dtb-BOARD' for 'LINUX_VERSION': 'postinst' finishing."
true
POSTINST

sed -i "s|BOARD|${2}|g" ${1}
sed -i "s|LINUX_VERSION|${3}|g" ${1}
chmod +x "$1"
}

# gen_dtb_preinst <file> <sun55i-t527-bsp> <5.15.153>
gen_dtb_preinst(){
cat <<- PREINST > "$1"
#!/bin/bash
echo "AvaotaOS 'linux-dtb-BOARD' for 'LINUX_VERSION': 'preinst' starting."
set -e # Error control

#set -x # Debugging

rm -rf /boot/dtb
rm -rf /boot/dtb-LINUX_VERSION

set +x # Disable debugging
echo "AvaotaOS 'linux-dtb-BOARD' for 'LINUX_VERSION': 'preinst' finishing."
true
PREINST

sed -i "s|BOARD|${2}|g" ${1}
sed -i "s|LINUX_VERSION|${3}|g" ${1}
chmod +x "$1"
}

# gen_headers_postinst <file> <sun55i-t527-bsp> <arm64> <5.15.153>
gen_headers_postinst(){
cat <<- POSTINST > "$1"
#!/bin/bash
echo "AvaotaOS 'linux-headers-BOARD' for 'LINUX_VERSION': 'postinst' starting."
set -e # Error control

#set -x # Debugging
ln -s "/usr/src/linux-headers-LINUX_VERSION" "/lib/modules/LINUX_VERSION/build"
cd "/usr/src/linux-headers-LINUX_VERSION"
NCPU=\$(grep -c 'processor' /proc/cpuinfo)
echo "Compiling kernel-headers tools (LINUX_VERSION) using \$NCPU CPUs - please wait ..."
yes "" | make ARCH="T_ARCH" oldconfig
make ARCH="T_ARCH" -j\$NCPU scripts
make ARCH="T_ARCH" -j\$NCPU M=scripts/mod/
# make ARCH="T_ARCH" -j\$NCPU modules_prepare # depends on too much other stuff.
echo "Done compiling kernel-headers tools (LINUX_VERSION)."
echo "Done compiling kernel-headers tools (LINUX_VERSION)."

set +x # Disable debugging
echo "AvaotaOS 'linux-headers-BOARD' for 'LINUX_VERSION': 'postinst' finishing."
true
POSTINST

sed -i "s|BOARD|${2}|g" ${1}
sed -i "s|T_ARCH|${3}|g" ${1}
sed -i "s|LINUX_VERSION|${4}|g" ${1}
chmod +x "$1"
}

# gen_headers_preinst <file> <sun55i-t527-bsp> <5.15.153>
gen_headers_preinst(){
cat <<- PREINST > "$1"
#!/bin/bash
echo "AvaotaOS 'linux-headers-BOARD' for 'LINUX_VERSION': 'preinst' starting."
set -e # Error control

#set -x # Debugging

if [[ -d "/usr/src/linux-headers-LINUX_VERSION" ]]; then
echo "Cleaning pre-existing directory /usr/src/linux-headers-LINUX_VERSION ..."
rm -rf "/usr/src/linux-headers-LINUX_VERSION"
fi

set +x # Disable debugging
echo "AvaotaOS 'linux-headers-BOARD' for 'LINUX_VERSION': 'preinst' finishing."
true
PREINST

sed -i "s|BOARD|${2}|g" ${1}
sed -i "s|LINUX_VERSION|${3}|g" ${1}
chmod +x "$1"
}

# gen_headers_prerm <file> <sun55i-t527-bsp> <5.15.153>
gen_headers_prerm(){
cat <<- PRERM > "$1"
#!/bin/bash
echo "AvaotaOS 'linux-headers-BOARD' for 'LINUX_VERSION': 'prerm' starting."
set -e # Error control

#set -x # Debugging

if [[ -d "/usr/src/linux-headers-LINUX_VERSION" ]]; then
echo "Cleaning directory /usr/src/linux-headers-LINUX_VERSION ..."
rm -rf "/usr/src/linux-headers-LINUX_VERSION"
fi

set +x # Disable debugging
echo "AvaotaOS 'linux-headers-BOARD' for 'LINUX_VERSION': 'prerm' finishing."
true
PRERM

sed -i "s|BOARD|${2}|g" ${1}
sed -i "s|LINUX_VERSION|${3}|g" ${1}
chmod +x "$1"
}

# gen_image_postinst <file> <sun55i-t527-bsp> <5.15.153>
gen_image_postinst(){
cat <<- POSTINST > "$1"
#!/bin/bash
echo "AvaotaOS 'linux-image-BOARD' for 'LINUX_VERSION': 'postinst' starting."
set -e # Error control

#set -x # Debugging

export DEB_MAINT_PARAMS="\$*" # Pass maintainer script parameters to hook scripts
export INITRD=Yes # Tell initramfs builder whether it's wanted
# Run the same hooks Debian/Ubuntu would for their kernel packages.
test -d /etc/kernel/postinst.d && run-parts --arg="LINUX_VERSION" --arg="/boot/vmlinuz-LINUX_VERSION" /etc/kernel/postinst.d
touch /boot/.next

echo "AvaotaOS: FAT32 /boot: move last-installed kernel to 'Image'..."
mv -v /boot/vmlinuz-LINUX_VERSION /boot/Image

set +x # Disable debugging
echo "AvaotaOS 'linux-image-BOARD' for 'LINUX_VERSION': 'postinst' finishing."
true
POSTINST

sed -i "s|BOARD|${2}|g" ${1}
sed -i "s|LINUX_VERSION|${3}|g" ${1}
chmod +x "$1"
}

# gen_image_postrm <file> <sun55i-t527-bsp> <5.15.153>
gen_image_postrm(){
cat <<- POSTRM > "$1"
#!/bin/bash
echo "AvaotaOS 'linux-image-BOARD' for 'LINUX_VERSION': 'postrm' starting."
set -e # Error control

#set -x # Debugging

export DEB_MAINT_PARAMS="\$*" # Pass maintainer script parameters to hook scripts
export INITRD=Yes # Tell initramfs builder whether it's wanted
# Run the same hooks Debian/Ubuntu would for their kernel packages.
test -d /etc/kernel/postrm.d && run-parts --arg="LINUX_VERSION" --arg="/boot/vmlinuz-LINUX_VERSION" /etc/kernel/postrm.d

set +x # Disable debugging
echo "AvaotaOS 'linux-image-BOARD' for 'LINUX_VERSION': 'postrm' finishing."
true
POSTRM

sed -i "s|BOARD|${2}|g" ${1}
sed -i "s|LINUX_VERSION|${3}|g" ${1}
chmod +x "$1"
}

# gen_image_preinst <file> <sun55i-t527-bsp> <5.15.153>
gen_image_preinst(){
cat <<- PREINST > "$1"
#!/bin/bash
echo "AvaotaOS 'linux-image-BOARD' for 'LINUX_VERSION': 'preinst' starting."
set -e # Error control

#set -x # Debugging

export DEB_MAINT_PARAMS="\$*" # Pass maintainer script parameters to hook scripts
export INITRD=Yes # Tell initramfs builder whether it's wanted
# Run the same hooks Debian/Ubuntu would for their kernel packages.
test -d /etc/kernel/preinst.d && run-parts --arg="LINUX_VERSION" --arg="/boot/vmlinuz-LINUX_VERSION" /etc/kernel/preinst.d

rm -f /boot/System.map* /boot/config* /boot/vmlinuz* /boot/Image /boot/uImage

set +x # Disable debugging
echo "AvaotaOS 'linux-image-BOARD' for 'LINUX_VERSION': 'preinst' finishing."
true
PREINST

sed -i "s|BOARD|${2}|g" ${1}
sed -i "s|LINUX_VERSION|${3}|g" ${1}
chmod +x "$1"
}

# gen_image_prerm <file> <sun55i-t527-bsp> <5.15.153>
gen_image_prerm(){
cat <<- PRERM > "$1"
#!/bin/bash
echo "AvaotaOS 'linux-image-BOARD' for 'LINUX_VERSION': 'prerm' starting."
set -e # Error control

#set -x # Debugging

export DEB_MAINT_PARAMS="\$*" # Pass maintainer script parameters to hook scripts
export INITRD=Yes # Tell initramfs builder whether it's wanted
# Run the same hooks Debian/Ubuntu would for their kernel packages.
test -d /etc/kernel/prerm.d && run-parts --arg="LINUX_VERSION" --arg="/boot/vmlinuz-LINUX_VERSION" /etc/kernel/prerm.d

set +x # Disable debugging
echo "AvaotaOS 'linux-image-BOARD' for 'LINUX_VERSION': 'prerm' finishing."
true
PRERM

sed -i "s|BOARD|${2}|g" ${1}
sed -i "s|LINUX_VERSION|${3}|g" ${1}
chmod +x "$1"
}
