#!/bin/bash

#this scripts creates lxc-container for cloning to physical server

set -e

archive=$1
if [ -z $archive ]; then
  echo "Usage: script archive.tar.gz"
  exit 1
fi

apt-get update 
apt-get -y install lxc lxc-templates

lxc-create -t download -n srvtmpl -- --dist ubuntu --release trusty --arch amd64
lxcroot=/var/lib/lxc/srvtmpl/rootfs
#echo "lxc.aa_profile = unconfined" >> /var/lib/lxc/srvtmpl/config

mkdir $lxcroot/root/scripts
cat > $lxcroot/root/scripts/init.sh << EOF
#!/bin/bash
apt-get update
apt-get -y install linux-generic-lts-vivid vlan bridge-utils tasksel grub2 acpid
tasksel install server
tasksel install openssh-server
apt-get clean
rm /etc/ssh/ssh_host_*
perl -i -pe "s/^PermitRootLogin without-password/PermitRootLogin yes/" /etc/ssh/sshd_config
usermod --pass='\$1\$eXo/XRoW\$sED.Q4FS5e6kbbtJyQFBY.' root
EOF

lxc-start -n srvtmpl -d && lxc-wait -n srvtmpl -s RUNNING
sleep 20
lxc-attach -n srvtmpl -- bash /root/scripts/init.sh
lxc-stop -n srvtmpl && lxc-wait -n srvtmpl -s STOPPED
sleep 5

cat > $lxcroot/etc/rc.local << EOF
#!/bin/bash
if [ -f /firstboot ]; then
  dpkg-reconfigure openssh-server
fi
exit 0
EOF
chmod +x $lxcroot/etc/rc.local

curl https://raw.githubusercontent.com/zubatyuk/lxc-viz-cluster/master/conf/ns-viz1-interfaces > $lxcroot/etc/network/interfaces 

cd $lxcroot
tar --acls --xattrs --keep-directory-symlink --numeric-owner --selinux -czf $archive * 
