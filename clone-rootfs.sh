#!/bin/bash

DEVICE=$1
ARCHIVE=$2

if [ -z $DEVICE || -z $ARCHIVE ]; then
  echo "Usage script device archive"
  exit 1
fi

set -e
#cleanup disk
dd if=/dev/zero of=/dev/${DEVICE} bs=1M count=100

#partition disk
parted -s /dev/${DEVICE} << EOF
mktable gpt
mkpart primary 1049kB 15.7MB
mkpart primary 15.7MB 16.0GB
mkpart primary 16.0GB 100%
set 1 bios_grub on 
EOF

#create btrfs
mkfs.btrfs -f /dev/${DEVICE}3
UUID_BTRFS_ROOT=`blkid -s UUID -o value ${DEVICE}3`
mkswap -f /dev/${DEVICE}3
UUID_SWAP=`blkid -s UUID -o value ${DEVICE}2`

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
cat > /mnt/${DEVICE}3 << EOF
UUID=$UUID_BTRFS_ROOT / btrfs defaults,subvol=@,compress=lzo 0 1
UUID=$UUID_SWAP swap swap defaults 0 0
EOF
chroot /mnt/${DEVICE}3 grub-mkdevicemap 
chroot /mnt/${DEVICE}3 grub-install ${DEVICE}
chroot /mnt/${DEVICE}3 update-grub
cd $d

umount /mnt/${DEVICE}3/dev
umount /mnt/${DEVICE}3/proc
umount /mnt/${DEVICE}3/sys

###
echo " Success!!"
echo "Edit system files and umount target:"
echo "vi /mnt/${DEVICE}3/@/etc/hostname"
echo "vi /mnt/${DEVICE}3/@/etc/network/interfaces"
echo "umount /mnt/${DEVICE}3/@/"
