#!/bin/bash

# The device and mount point
DEVICE="/dev/hptblock0n2p"
MOUNT_POINT="/data"
FILESYSTEM="ext4"

# Check if mount point does not exist
if [ ! -d $MOUNT_POINT ]; then
    echo "Mount point does not exist. Creating now..."
    sudo mkdir -p $MOUNT_POINT
fi

# Backup current fstab
echo "Backing up current /etc/fstab to /etc/fstab.bak..."
sudo cp /etc/fstab /etc/fstab.bak

# Prepare the new entry
NEW_ENTRY="$DEVICE    $MOUNT_POINT    $FILESYSTEM    defaults    0    0"

# Check if the entry already exists in /etc/fstab
if grep -Fxq "$NEW_ENTRY" /etc/fstab
then
    echo "The entry already exists in /etc/fstab, no action taken."
else
    echo "Adding new entry to /etc/fstab..."
    echo $NEW_ENTRY | sudo tee -a /etc/fstab
fi

# Mount all filesystems mentioned in fstab
echo "Mounting all filesystems..."
sudo mount -a

echo "Done!"

