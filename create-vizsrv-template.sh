#!/bin/bash

#this scripts creates lxc-container for cloning to physical server

set -e

apt-get update 
apt-get install lxc

lxc-create -t download -n srvtmpl -- --dist ubuntu --release trusty --arch amd64
lxc-start -n srvtmpl -d

lxc-attach -n srvtmpl -- apt-get update
lxc-attach -n srvtmpl -- apt-get -y dist-upgrade
lxc-attach -n srvtmpl -- apt-get -y install tasksel
lxc-attach -n srvtmpl -- tasksel -y install server openssh-server




