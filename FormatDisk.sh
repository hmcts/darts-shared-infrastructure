#!/bin/bash

# Variables
data_disk="/dev/sdc"
mount_point="/mnt/data"

# Check if the disk is already mounted
if grep -qs "$data_disk" /proc/mounts; then
    echo "Disk $data_disk is already mounted."
    exit 0
fi

# Check if the disk exists
if [ ! -b "$data_disk" ]; then
    echo "Disk $data_disk does not exist."
    exit 1
fi

# Create a partition on the data disk
(echo n; echo p; echo 1; echo; echo; echo w) | fdisk $data_disk

# Format the partition with ext4
mkfs.ext4 "${data_disk}1"

# Create the mount point directory if it doesn't exist
if [ ! -d "$mount_point" ]; then
    mkdir -p "$mount_point"
fi

# Mount the partition
mount "${data_disk}1" "$mount_point"

# Add an entry to /etc/fstab to mount the disk at boot
echo "${data_disk}1 $mount_point ext4 defaults 0 0" >> /etc/fstab

# Check if the disk is successfully mounted
if grep -qs "$data_disk" /proc/mounts; then
    echo "Disk $data_disk is successfully formatted and mounted at $mount_point."
    exit 0
else
    echo "Failed to mount the disk $data_disk."
    exit 1
fi