#!/bin/bash
#
# This script is tested on Aarch64 Ubuntu218.04 LTS LK4.9 Xavier NX only. 
#
# How to use:
# To set beast
# $> ./install_east_mode.sh beast
# To restore default
# $> ./install_east_mode.sh default
#

if [ $# -gt 2 ]; then
  echo "Bad argument."
  echo "Number of args should be 1, but $#."
  exit 1
fi

if [ $# = 0 ] || [ $1 == "beast" ]; then
  echo "Setting beast mode."
  sudo /usr/bin/jetson_clocks --show
  cd /sys/devices/gpu.0/devfreq/17000000.gv11b
  cat available_frequencies
  sudo sh -c "echo 114750000 > max_freq"
  cd /sys/devices/17000000.gv11b/devfreq/17000000.gv11b
  cat available_frequencies
  sudo sh -c "echo 114750000 > max_freq"
  sudo /usr/bin/jetson_clocks
  sudo /usr/sbin/nvpmodel -d cool
  sudo /usr/sbin/nvpmodel -q
else
  if [ $1 == "restore" ]; then
    echo "Restore"
    sudo /usr/bin/jetson_clocks --restore
    cd /sys/devices/gpu.0/devfreq/17000000.gv11b
    sudo sh -c "echo 1109250000 > max_freq"
    cd /sys/devices/17000000.gv11b/devfreq/17000000.gv11b
    sudo sh -c "echo 1109250000 > max_freq"
    sudo /usr/bin/jetson_clocks.sh --show
  else
    echo "Bad argument."
    echo "Arg should be either beast or default, but $1."
    exit 1
  fi
fi