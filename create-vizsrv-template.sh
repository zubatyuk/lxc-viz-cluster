#!/bin/bash

#this scripts creates lxc-container for cloning to physical server

set -e

archive=$1
if [ -z $archive ]; then
  echo "Usage: script archive.tar.gz"
  exit 1
fi

apt-get update 
apt-get -y install lxc

lxc-create -t download -n srvtmpl -- --dist ubuntu --release trusty --arch amd64
lcxroot=/var/lib/lxc/srvtmpl/rootfs
echo "lxc.aa_profile = unconfined" >> /var/lib/lxc/srvtmpl/config
lxc-start -n srvtmpl -d
sleep 5

lxc-attach -n srvtmpl << EOF
apt-get update
apt-get -y install lxc tasksel linux-generic-lts-vivid
tasksel install server openssh-server
tasksel install openssh-server
apt-add-repository -y ppa:xorg-edgers/ppa
apt-get update
apt-get -y install nvidia-355 bumblebee
apt-get -y grub2
apt-get clean
echo 'US/Central' > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
rm /etc/ssh/ssh_host_*
perl -i -pe "s/^PermitRootLogin without-password/PermitRootLogin yes/" /etc/ssh/sshd_config
usermod --pass='$1$eXo/XRoW$sED.Q4FS5e6kbbtJyQFBY.' root
EOF

cat > $lxcroot/etc/rc.local << EOF
#!/bin/bash
if [ -f /firstboot ]; then
  dpkg-reconfigure openssh-server
fi
exit 0
EOF
chmod +x $lxcroot/etc/rc.local

lxc-stop -n srvtmpl
sleep 5

cd $lxcroot
tar --acls --xattrs --keep-directory-symlink --numeric-owner --selinux -czf $archive * 
