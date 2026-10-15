#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0
#
# Read-only display diagnostics for Avaota A1. Run on the board:
#   sudo bash diagnose-display.sh > avaota-display.txt 2>&1
# Does not install packages, change configuration, or restart services.

set -u
export LC_ALL=C
shopt -s nullglob

section() {
    printf '\n===== %s =====\n' "$1"
}

show_file() {
    local path=$1
    if [[ -r "$path" ]]; then
        printf '\n--- %s ---\n' "$path"
        cat -- "$path"
        printf '\n'
    fi
}

section 'System and boot'
date -u
uname -a
if [[ -r /proc/device-tree/model ]]; then
    tr '\0' '\n' < /proc/device-tree/model
fi
show_file /proc/cmdline
uptime
if [[ $EUID -ne 0 ]]; then
    printf 'Run with sudo to include restricted kernel and display-manager logs.\n'
fi
if command -v free >/dev/null 2>&1; then free -h; fi
df -h / /boot

section 'Boot and display configuration'
show_file /boot/extlinux/extlinux.conf
show_file /etc/gdm3/custom.conf
show_file /etc/X11/default-display-manager
for path in /etc/X11/xorg.conf /etc/X11/xorg.conf.d/*.conf; do
    show_file "$path"
done
for path in /boot/config-"$(uname -r)"; do
    if [[ -r "$path" ]]; then
        grep -E 'CONFIG_(AW_DRM|AW_FB_CONSOLE|DRM_FBDEV|FRAMEBUFFER_CONSOLE|VT_CONSOLE|AVA_FB_TFT)' "$path"
    fi
done

section 'Framebuffers and DRM devices'
show_file /proc/fb
for path in /sys/class/graphics/fb*/name; do show_file "$path"; done
if [[ -d /dev/dri ]]; then ls -l /dev/dri; fi
for card in /sys/class/drm/card[0-9]*; do
    [[ $(basename "$card") =~ ^card[0-9]+$ ]] || continue
    printf '\n--- %s driver ---\n' "$card"
    readlink -f -- "$card/device/driver"
done

section 'DRM connectors (keep HDMI connected and monitor powered on)'
found=0
for connector in /sys/class/drm/card*-*; do
    [[ -f "$connector/status" ]] || continue
    found=1
    for item in status enabled modes; do show_file "$connector/$item"; done
    if [[ -r "$connector/edid" ]]; then
        printf '%s EDID bytes: ' "$connector"
        wc -c < "$connector/edid"
    fi
done
if [[ $found -eq 0 ]]; then printf 'No DRM connector sysfs entries found.\n'; fi

section 'Allwinner BSP HDMI state'
for item in hdmi_source hdmi_sink; do
    show_file "/sys/class/hdmi/hdmi/attr/$item"
done

section 'Display manager'
if command -v systemctl >/dev/null 2>&1; then
    systemctl get-default
    systemctl --no-pager --full status display-manager.service
fi
if command -v journalctl >/dev/null 2>&1; then
    journalctl -b --no-pager -u gdm.service -u gdm3.service -n 160
    journalctl -b --no-pager _COMM=gnome-shell -n 120
    journalctl -b --no-pager _COMM=Xorg -n 100
fi

section 'Kernel display messages'
if command -v dmesg >/dev/null 2>&1; then
    dmesg 2>&1 | grep -Ei 'drm|hdmi|edid|hpd|tcon|panfrost|mali|gpu|frame.?buffer|fb[0-9]|cma|panic|out of memory|killed process|permission denied|not permitted' | tail -n 240
fi

section 'Xorg warnings and errors'
for path in /var/log/Xorg.*.log /var/lib/gdm3/.local/share/xorg/Xorg.*.log /home/*/.local/share/xorg/Xorg.*.log; do
    [[ -r "$path" ]] || continue
    printf '\n--- %s ---\n' "$path"
    grep -Ei '\(EE\)|\(WW\)|modeset|glamor|panfrost|/dev/dri|no screens' "$path" | tail -n 100
done

section 'Installed graphics packages'
if command -v dpkg-query >/dev/null 2>&1; then
    dpkg-query -W -f='${binary:Package}\t${Version}\t${db:Status-Status}\n' \
        gdm3 gnome-shell libmutter-14-0 libegl-mesa0 libgbm1 libgl1-mesa-dri \
        xserver-xorg-core xserver-xorg-video-fbdev linux-image-sun55i-t527-bsp
fi

section 'End of read-only diagnostics'
