#!/bin/bash

#install lxc
apt-add-repository ppa:ubuntu-lxc/stable
apt-get update && apt-get -y install lxc

#xorg
apt-add-repository -y ppa:xorg-edgers/ppa
apt-get update && apt-get -y install nvidia-355 bumblebee
