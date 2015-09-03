#!/bin/bash


#check local ns server
if [[ $(ping -c 1 192.168.1.1) ]]; then
  #configure apt proxy
  if [[ $(ping -c 1 apt-cacher) ]]; then
    echo 'Acquire::http::proxy "http://apt-cacher:3142";' > /apt.conf.d/02proxy
    echo 'Acquire::https::proxy "http://apt-cacher:3142";' >> /apt.conf.d/02proxy
  fi
fi

#install lxc
apt-get update && apt-get -y install lxc

#xorg
apt-add-repository -y ppa:xorg-edgers/ppa
apt-get update && apt-get -y install nvidia-355 bumblebee

#timezone
echo 'US/Central' > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata





