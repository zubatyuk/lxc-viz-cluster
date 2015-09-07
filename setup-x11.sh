#!/bin/bash

apt-get update
apt-get -y install software-properties-common
apt-add-repository -y ppa:xorg-edgers/ppa
apt-get update && apt-get -y install nvidia-355 bumblebee
apt-get -y purge bumblebee
apt-get -y autoremove 

#allow non-interactive xinit
perl -i -pe "s/^allowed_users=console/allowed_users=anbyody/" /etc/X11/Xwrapper.config
#create user 
adduser viz --ingroup users --disabled-password --gecos '' -q
#install openssh
apt-get -y install openssh-server
#setup passwordless ssh
mkdir /home/viz/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDB1LqUEmMgmnhVGlECS+WsjWtG+KpWpVSvGKVWSXHOzWDzJXo4n0q/7IY6avZJeKEaNb58a7ZKzN3CnO/VVArvb5MW3R+JXsCIs57pyAPtVF8yjybhmdnBL2sYvfZf7mUWEUY13sOghC1PuiWkMX3QKohG9mMWkagQn/RZJyHh3zO9Xl2QWMXmShtEmHQEw9udjhk1WE8Ga9yTZ5XLuSn0+yRm3DgQsJ65XFu2wYWmf8ty3WX+CEeBcb73Gdp/iUKHfz+Ijw7cyyHbyPAf4FriL71u0hRXYsqNnfLJSzJcY2rnzMOpAgt8N6Krjjs2bHYlvKSUUb3wQx4C3sNDEJTL' > /home/viz/.ssh/authorized_keys
chown viz:users -R /home/viz/.ssh
chmod go-wrx -R /home/viz/.ssh

