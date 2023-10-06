#!/bin/bash

# This script must be run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

# Find all attached drives and their sizes
# 1 TB = 1000000000000 bytes, 17TB = 17000000000000 bytes
mapfile -t drives < <(lsblk -dn -o NAME,SIZE -b | awk '$2 >= 17000000000000 {print $1}')

# Exit if no suitable drives found
if [ ${#drives[@]} -eq 0 ]; then
  echo "No drive larger than 17TB found."
  exit 1
fi

# Choose a drive to format
echo "Drives larger than 17TB:"
for i in "${!drives[@]}"; do
  echo "$((i+1)). ${drives[i]}"
done

read -p "Choose a drive to format (enter number): " choice
new_drive="/dev/${drives[$((choice-1))]}"

# Confirm action
read -p "About to format and mount $new_drive, which will erase its contents. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 1
fi

# Unmount the drive if it's already mounted
umount "$new_drive" 2>/dev/null

# Create a single ext4 partition
echo -e "o\nn\np\n1\n\n\nw" | fdisk "$new_drive"

# Let the system know the partition table has been changed
partprobe "$new_drive"

# Format the new partition with ext4
new_partition="${new_drive}1"
mkfs.ext4 "$new_partition"

# Create a mount point
mkdir -p /mnt/new_drive

# Mount the new partition
mount "$new_partition" /mnt/new_drive

# Get the UUID of the new partition
uuid=$(blkid -s UUID -o value "$new_partition")

# Add entry to /etc/fstab
echo "UUID=$uuid /mnt/new_drive ext4 defaults 0 0" >> /etc/fstab

# Reload fstab to mount new entries
mount -a

echo "Drive $new_drive has been formatted with ext4 and mounted to /mnt/new_drive. It will be re-mounted automatically upon boot."

