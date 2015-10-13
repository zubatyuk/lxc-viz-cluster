#!/bin/bash

DEVICE=$1
ARCHIVE=$2

if [[ -z $DEVICE || -z $ARCHIVE ]]; then
  echo "Usage script device archive"
  exit 1
fi

set -e
#cleanup disk
dd if=/dev/zero of=/dev/${DEVICE} bs=1M count=100

#partition disk
parted -s /dev/${DEVICE} mktable gpt
parted -s /dev/${DEVICE} mklabel gpt
parted -s /dev/${DEVICE} mkpart primary 1049kB 15.7MB
parted -s /dev/${DEVICE} mkpart primary 15.7MB 16.0GB
parted -s /dev/${DEVICE} mkpart primary 16.0GB 100%
parted -s /dev/${DEVICE} set 1 bios_grub on 

#create btrfs
mkfs.btrfs -f /dev/${DEVICE}3
UUID_BTRFS_ROOT=`blkid -s UUID -o value /dev/${DEVICE}3`
mkswap -f /dev/${DEVICE}2
UUID_SWAP=`blkid -s UUID -o value /dev/${DEVICE}2`

#transfer system image
mkdir /mnt/${DEVICE}3
mount -o compress=lzo /dev/${DEVICE}3 /mnt/${DEVICE}3
btrfs subvolume create /mnt/${DEVICE}3/@
umount /mnt/${DEVICE}3
mount -o subvol=@,compress=lzo /dev/${DEVICE}3 /mnt/${DEVICE}3

d=`pwd`
cd /mnt/${DEVICE}3
tar --acls --xattrs --keep-directory-symlink --numeric-owner --selinux -xzf ${ARCHIVE}

#chroot and configure
mount --bind /dev  /mnt/${DEVICE}3/dev
mount --bind /proc /mnt/${DEVICE}3/proc
mount --bind /sys  /mnt/${DEVICE}3/sys
cat > /mnt/${DEVICE}3/etc/fstab << EOF
UUID=$UUID_BTRFS_ROOT / btrfs defaults,subvol=@,compress=lzo 0 1
UUID=$UUID_SWAP swap swap defaults 0 0
EOF
echo "(hd0)   /dev/${DEVICE}" > /mnt/${DEVICE}3/boot/grub/device.map
chroot /mnt/${DEVICE}3 grub-install /dev/${DEVICE}
chroot /mnt/${DEVICE}3 update-grub
cd $d

###
echo "Success!!"
echo "Run commands to umount image:"
echo umount /mnt/${DEVICE}3/dev
echo umount /mnt/${DEVICE}3/proc
echo umount /mnt/${DEVICE}3/sys
echo umount /mnt/${DEVICE}3
echo rmdir /mnt/${DEVICE}3
