#!/bin/bash
# This script is only tested in Aarch64 Ubuntu 18.04 LTS(LK4.9) nVIDIA JettPack
# JetPack has pre-installed docker but you need to change permisson for non-root. 
#
# SYNOPSYS:
# Install docker infrastructure to run x86 container on aarch64
#

pushd ${PWD}

sudo gpasswd -a $USER docker
sudo chmod 666 /var/run/docker.sock
docker images -aq | xargs docker rmi
docker images 
docker run hello-world

# -------------------------------------
# Docker multiarch/qemu-user-static
# https://hub.docker.com/r/multiarch/qemu-user-static
#
# Known issue: 
# Segmentation Fault at libc-bin installation at 
# Ubuntu 18.04 and 20.04 on x86_64.
# To avoid errors, use DBHI qus instead.             
# -------------------------------------
#sudo apt install -y qemu-user-static
#docker run --rm --privileged multiarch/qemu-user-static:register --reset
#docker run --rm --privileged multiarch/qemu-user-static:register

# -------------------------------------
# Dynamic Binary Hardware Injection (DBHI) qemu-user-static (qus)
# https://github.com/dbhi/qus
#
# This is alternative way to emulate x86_64 on aarch64. 
# If docker multiarch does not work properly, use this instead. 
# -------------------------------------
sudo apt install -y qemu-user-static
docker run --rm --privileged aptman/qus -- -r
docker run --rm --privileged aptman/qus -s -- -p x86_64

# pull images
# Ubuntu 16.04 LTS
docker pull multiarch/ubuntu-core:amd64-xenial
docker pull multiarch/ubuntu-core:arm64-xenial
# Ubuntu 18.04 LTS
docker pull multiarch/ubuntu-core:amd64-bionic
docker pull multiarch/ubuntu-core:arm64-bionic
# Ubuntu 20.04 LTS
docker pull multiarch/ubuntu-core:amd64-focal
docker pull multiarch/ubuntu-core:arm64-focal
# test
docker system prune -f
docker run --rm -t multiarch/ubuntu-core:amd64-bionic uname -m
sleep 10
docker run --rm -t multiarch/ubuntu-core:arm64-bionic uname -m
sleep 10


# -------------------------------------
# build x86_64 docker container on aarch64 linux 
# -------------------------------------
docker system prune -f
sudo apt install subversion -y
if [ -d ${HOME}/work/tensorflow-lite-micro-rtos-fvp ]; then
  echo "tensorflow-lite-micro-rtos-fvp already exists."
else
  cd ${HOME}/work && svn export  https://github.com/ARM-software/Tool-Solutions/trunk/docker/tensorflow-lite-micro-rtos-fvp
fi
# use Ubuntu 16.04 LTS(xenial) if you face libc-bin issue
sed -i 's/FROM ubuntu:18.04/FROM multiarch\/ubuntu-core:amd64-bionic/' ${HOME}/work/tensorflow-lite-micro-rtos-fvp/docker/*.Dockerfile
sed -i 's/apt-get -y update/apt-get -y update \&\& apt-get install -y software-properties-common/' ${HOME}/work/tensorflow-lite-micro-rtos-fvp/docker/*.Dockerfile 
chmod +x -R ${HOME}/work/tensorflow-lite-micro-rtos-fvp/*
cd ${HOME}/work/tensorflow-lite-micro-rtos-fvp && ./docker_build.sh -c gcc

