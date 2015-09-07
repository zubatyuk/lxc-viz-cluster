#!/bin/bash

#install lxc
sudo apt-add-repository ppa:ubuntu-lxc/daily
apt-get update && apt-get -y install lxc

#xorg
apt-add-repository -y ppa:xorg-edgers/ppa
apt-get update && apt-get -y install nvidia-355 bumblebee
