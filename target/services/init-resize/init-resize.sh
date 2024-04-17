#!/bin/bash
# description: init resize root

set -e

resize_root(){
    ROOT_PART="$(findmnt / -o source -n)"
    ROOT_DEV="/dev/$(lsblk -no pkname "$ROOT_PART")"
    PART_NUM="$(echo "$ROOT_PART" | grep -o "[[:digit:]]*$")"

    PART_INFO=$(parted "$ROOT_DEV" -ms unit s p)
    LAST_PART_NUM=$(echo "$PART_INFO" | tail -n 1 | cut -f 1 -d:)  # 3
    PART_START=$(echo "$PART_INFO" | grep "^${PART_NUM}" | cut -f 2 -d: | sed 's/[^0-9]//g')
    PART_END=$(echo "$PART_INFO" | grep "^${PART_NUM}" | cut -f 3 -d: | sed 's/[^0-9]//g')
    ROOT_END=$(echo "$PART_INFO" | grep "^/dev"| cut -f 2 -d: | sed 's/[^0-9]//g')
    ((ROOT_END--))

    if [ $PART_END -lt $ROOT_END ]; then
        fdisk "$ROOT_DEV" <<EOF
p
d
$PART_NUM
n
p
$PART_NUM
$PART_START

p
w
EOF
        resize2fs $ROOT_PART
        echo "Reseize $ROOT_PART finished." >> /var/log/resize-root.log
    else
        echo "Already the largest! Do not need resize any more!" >> /var/log/resize-root.log
    fi
    return 0
}

if resize_root; then
    sudo systemctl disable init-resize.service
else
    echo "Fail to root!" >> /var/log/resize-root.log
fi
