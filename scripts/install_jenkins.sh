#!/bin/bash
# This script is only tested in Aarch64 Ubuntu 18.04 LTS(LK4.9) nVIDIA JettPack
# JetPack has pre-installed docker but you need to change permisson for non-root. 
#
# SYNOPSYS:
# Install jenkins infrustructure
# https://pkg.jenkins.io/debian-stable/

#
# If you prefer using Java 8. The latest Jenkins suport Java 11.
#
#sudo apt -y install openjdk-8-jdk
#JAVA8=`update-alternatives --display java | grep java-8-openjdk | grep priority | awk 'NR<2 { print $1 }'`
#echo "You have Java 8 under ${JAVA8}"
#sudo update-alternatives --verbose --install /usr/bin/java java ${JAVA8} 1112
#echo "Switch to Java 8 done."
#update-alternatives --display java

#
# Instal Jenkins
#
sudo apt -y install openjdk-11-jdk
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update -y
sudo apt install -y jenkins
sudo apt clean
sudo apt autoremove -y
echo "Start your browwer(http://localhost:8080) and type your password."
echo "Your password is "
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo "end of script."
