#!/bin/bash

SHARE_PATH=$1
MOUNT_PATH=$2

if [ "$(id -u)" -eq 0 ]; then
    echo "The script is running with root privileges."
else
    echo "The script is NOT running with root privileges."
    echo "Please run this script as root or using sudo."
    exit 1
fi

echo "192.168.1.109:$SHARE_PATH $MOUNT_PATH nfs vers=3,noauto,x-systemd.automount 0 0"  | sudo tee -a /etc/fstab

sudo systemctl daemon-reload
sudo systemctl restart remote-fs.target

echo "Mount info:"
echo "$(sudo mount | grep nfs)"

echo "NFS client side configuration is done."