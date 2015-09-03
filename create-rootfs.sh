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

cat > $lxcroot/etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet manual

auto br-lan
iface br-lan inet static
  bridge_stp off
  bridge_fd 0
  address 192.168.0.2
  netmask 192.268.240.0
  gateway 192.168.0.1
  dns-nameservers 192.168.1.1 192.168.0.1
  
##auto mveth0
##iface mveth0 inet manual
##  pre-up "ip link add dev mveth0 link eth0 type macvlan"
##  post-down "ip link delete mveth0"
#
##auto eth0.2
##iface eth0.2 inet manual
#
#auto br-wan
#iface br-wan inet dhcp
#  bridge_stp off
#  bridge_fd 0
##  bridge-ports mveth0
##  bridge-ports eth0.2

##auto eth1
##iface eth1 inet manual
#
#auto br-hp
#iface br-hpn inet static
#  bridge_stp off
#  bridge_fd 0
#  bridge-ports eth1
#  address 192.168.16.1
#  netmask 192.168.240.0
EOF

lxc-stop -n srvtmpl
sleep 5

cd $lxcroot
tar --acls --xattrs --keep-directory-symlink --numeric-owner --selinux -czf $archive * 