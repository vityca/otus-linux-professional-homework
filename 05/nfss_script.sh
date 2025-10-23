#!/bin/bash

SHARE_PATH=$1
CHNG_SHARE_PATH=$(dirname $SHARE_PATH)

if [ "$(id -u)" -eq 0 ]; then
    echo "The script is running with root privileges."
else
    echo "The script is NOT running with root privileges."
    echo "Please run this script as root or using sudo."
    exit 1
fi

sudo apt update && sudo apt install nfs-kernel-server -y

sudo mkdir -p $SHARE_PATH
sudo chown -R nobody:nogroup $CHNG_SHARE_PATH
sudo chmod 0777 $CHNG_SHARE_PATH

echo "$CHNG_SHARE_PATH 192.168.1.0/24(rw,sync,root_squash)" | sudo tee -a /etc/exports

sudo exportfs -r
sudo exportfs -s

echo "NFS server side configuration is done."