#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Run script with root privileges!" >&2
    exit 1
fi

if [ $# -lt 3 ]; then
    echo "Usage: $0 <raid_name> <RAID_type> <disk1> [disk2 ... diskN]" >&2
    echo "Available RAID types: 0, 1, 5, 10" >&2
    exit 1
fi

RAID_NAME="$1"
RAID_LEVEL="$2"
shift 2
DISKS=("$@")
DISK_COUNT=${#DISKS[@]}

case "$RAID_LEVEL" in
    0|1|5|10)
        ;;
    *)
        echo "Error: Unavailable RAID type. Use instead: 0, 1, 5, 10" >&2
        exit 1
        ;;
esac

case "$RAID_LEVEL" in
    0)
        MIN_DISKS=2
        ;;
    1)
        MIN_DISKS=2
        ;;
    5)
        MIN_DISKS=3
        ;;
    10)
        MIN_DISKS=4
        ;;
esac

if [ "$DISK_COUNT" -lt "$MIN_DISKS" ]; then
    echo "Error: RAID $RAID_LEVEL requires at least $MIN_DISKS disks, but given $DISK_COUNT" >&2
    exit 1
fi

if grep -q "$RAID_NAME" /proc/mdstat; then
    echo "Error: RAID $RAID_NAME already exists" >&2
    exit 1
fi

echo "Creating RAID $RAID_LEVEL array $RAID_NAME from disks: ${DISKS[*]}"

RAID_OPTIONS="--level=$RAID_LEVEL --raid-devices=$DISK_COUNT"

mdadm --create --verbose "/dev/$RAID_NAME" $RAID_OPTIONS "${DISKS[@]}"

if [ $? -eq 0 ]; then
    echo "RAID $RAID_NAME successfully created"

    echo "Info about created RAID:"
    mdadm --detail "/dev/$RAID_NAME"
else
    echo "Error creating RAID" >&2
    exit 1
fi